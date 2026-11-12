extends RefCounted
## Authoritative travel position and phase. Presentation reads snapshots; only
## SimulationRoot's runtime adapter may confirm lifecycle changes or advance time.

const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const ORBIT_CATALOG = preload("res://scripts/mission/orbit_destination_catalog.gd")
const STATION_DOCK = preload("res://scripts/mission/polisa_station_dock_layout.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const DEFINITION_PATH := "res://data/singleplayer/star_system.json"
const TRUSTED_OPERATIONS := ["initialize_surface", "launch_to_orbit", "advance", "begin_approach", "finish_approach", "enter_orbit", "land_homebase"]
const MAX_ADVANCE_SECONDS: float = 60.0

var _definition: Dictionary = {}
var _phase: String = "grounded"
var _craft_id: String = ""
var _orbit_id: String = ""
var _orbit_marker_id: String = ""
var _flight: RefCounted = FLIGHT.new()
var _position: Vector2:
	get: return Vector2(_flight.get_snapshot().position_plane) / GRID.EXTENT
var _origin_position := Vector2(0.25, 0.62)
var _target_orbit_id: String = ""
var _target_orbit_marker_id: String = ""
var _active_jump_duration_seconds: float = 3.0
var _elapsed_seconds: float = 0.0
var _progress: float = 0.0
var _location_id: String = "homebase"
var _revision: int = 0
var _requests: Dictionary = {}
var _route_hexes: Array[Vector2i] = []
var _route_control := Vector2.ZERO
var _route_destination := Vector2.ZERO
var _heading: float:
	get: return float(_flight.get_snapshot().heading_rad)
# Internal prepared-area transaction integrity, not a separate travel/pose owner.
var _space_area_epoch := 0
var _space_area_seal := ""

func configure(craft_id: String = "") -> Dictionary:
	_space_area_epoch += 1
	_space_area_seal = str(get_instance_id()) + ":" + str(_space_area_epoch) + ":" + str(Time.get_ticks_usec())
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(DEFINITION_PATH))
	_definition.clear()
	if typeof(raw) != TYPE_DICTIONARY or not _valid_definition(raw):
		return _reject("invalid_system", "Sternsystem ist nicht verfuegbar")
	_definition = Dictionary(raw).duplicate(true)
	_active_jump_duration_seconds = float(_definition.jump_duration_seconds)
	_phase = "grounded"
	_craft_id = ""
	_orbit_id = ""
	_orbit_marker_id = ""
	if not _flight.configure(craft_id if not craft_id.is_empty() else "__unassigned__", {"position_plane": _orbit_position("moon_orbit") * GRID.EXTENT}).ok:
		return _reject("invalid_flight", "Flugzustand ungueltig")
	_origin_position = _position
	_target_orbit_id = ""
	_target_orbit_marker_id = ""
	_elapsed_seconds = 0.0
	_progress = 0.0
	_location_id = "homebase"
	_revision = 0
	_requests.clear()
	_route_hexes.clear()
	return {"ok": true}

func get_flight_state() -> RefCounted:
	return _flight

func _set_travel_pose(position: Vector2, heading: float) -> void:
	var committed: bool = _flight.commit_travel_pose(position * GRID.EXTENT, heading)
	assert(committed)

func is_quantum_active() -> bool:
	return _phase == "quantum"

func get_quantum_progress() -> Dictionary:
	return {"phase":_phase, "target_orbit_id":_target_orbit_id, "elapsed_seconds":_elapsed_seconds, "duration_seconds":_active_jump_duration_seconds, "revision":_revision}

func get_snapshot() -> Dictionary:
	return {"system_version": int(_definition.get("version", 1)), "hex": GRID.cell_at(_position),
		"route_hexes": _route_hexes.duplicate(), "heading": _heading, "phase": _phase, "craft_id": _craft_id, "orbit_id": _orbit_id,
		"orbit_marker_id": _orbit_marker_id, "target_orbit_marker_id": _target_orbit_marker_id,
		"position": [_position.x, _position.y], "origin_position": [_origin_position.x, _origin_position.y],
		"route_control": [_route_control.x, _route_control.y], "route_destination": [_route_destination.x, _route_destination.y],
		"target_orbit_id": _target_orbit_id, "progress": _progress, "elapsed_seconds": _elapsed_seconds,
		"duration_seconds": _active_jump_duration_seconds,
		"location_id": _location_id, "revision": _revision,
		"bodies": Dictionary(_definition.get("bodies", {})).duplicate(true),
		"orbits": Dictionary(_definition.get("orbits", {})).duplicate(true),
		"location_orbits": Dictionary(_definition.get("location_orbits", {})).duplicate(true)}

func apply_command(command: Dictionary, authority_context: Dictionary = {}) -> Dictionary:
	if _flight.get_snapshot().get("motion_mode") == "tactical":
		return _reject("combat_active", "Raumkampf blockiert Reiseaktionen")
	if _definition.is_empty() or typeof(command.get("contract_category")) != TYPE_STRING or command.get("contract_category") != "singleplayer_space_travel" or typeof(command.get("operation")) != TYPE_STRING or typeof(command.get("payload")) != TYPE_DICTIONARY or typeof(command.get("request_id", "")) != TYPE_STRING:
		return _reject("invalid_command", "Reiseauftrag ungueltig")
	var operation: String = command.operation
	if operation in TRUSTED_OPERATIONS and (typeof(authority_context.get("runtime_authorized")) != TYPE_BOOL or not bool(authority_context.get("runtime_authorized", false))):
		return _reject("runtime_authority_required", "Reisezustand braucht bestaetigte Laufzeitdaten")
	var payload: Dictionary = command.payload
	if operation == "advance" and not _valid_delta(payload):
		return _reject("invalid_delta", "Reisezeit ausserhalb des erlaubten Bereichs")
	var request_id: String = String(command.get("request_id", "")).strip_edges()
	var signature: String = "" if request_id.is_empty() else JSON.stringify({"operation": operation, "payload": payload}, "", true)
	if not request_id.is_empty() and _requests.has(request_id):
		if String(_requests[request_id].signature) != signature:
			return _reject("request_id_conflict", "Anfrage-ID bereits anders verwendet")
		var replay: Dictionary = Dictionary(_requests[request_id].result).duplicate(true)
		replay["replayed"] = true
		return replay
	if operation != "advance":
		if typeof(payload.get("craft_id")) != TYPE_STRING or String(payload.craft_id).strip_edges().is_empty():
			return _reject("invalid_craft", "Schiff fehlt")
		if operation not in ["launch_to_orbit", "initialize_surface"] and String(payload.craft_id) != _craft_id:
			return _reject("craft_mismatch", "Dieses Schiff ist nicht auf der aktiven Reise")
	var local_flight: Dictionary = _flight.get_snapshot()
	if local_flight.get("coordinate_frame", "strategic") == "local":
		var inactive_finish: bool = operation == "finish_approach" and _phase == "approach" and local_flight.get("motion_mode") == "inactive"
		if not inactive_finish: return _reject("local_area_transition_required", "Lokaler Flug braucht den bestaetigten Rootuebergang")
	var result: Dictionary
	match operation:
		"initialize_surface": result = _initialize_surface(payload)
		"launch_to_orbit": result = _launch(payload)
		"start_quantum": result = _start_quantum(payload, authority_context)
		"abort_quantum": result = _abort_quantum()
		"advance": result = _advance(payload)
		"begin_approach": result = _begin_approach(payload)
		"finish_approach":
			if _phase != "approach":
				return _reject("approach_not_active", "Kein laufender Anflug")
			_phase = "surface"
			_revision += 1
			result = {"ok": true}
		"enter_orbit": result = _enter_orbit()
		"land_homebase": result = _land_homebase()
		_: result = _reject("unknown_operation", "Reiseaktion unbekannt")
	if bool(result.get("ok", false)):
		result["phase"] = _phase
		result["revision"] = _revision
		# Runtime ticks omit request IDs; explicit IDs retain retry semantics.
		if not request_id.is_empty():
			_requests[request_id] = {"signature": signature, "result": result.duplicate(true)}
	return result

func _launch(payload: Dictionary) -> Dictionary:
	if _phase != "grounded":
		return _reject("trip_active", "Ein Schiff ist bereits im Weltraum")
	if not _flight.bind_craft(String(payload.craft_id), true):
		return _reject("craft_mismatch", "Flugzustand gehoert einem anderen Schiff")
	_craft_id = String(payload.craft_id)
	_arrive("moon_orbit")
	return {"ok": true}

func _start_quantum(payload: Dictionary, context: Dictionary = {}) -> Dictionary:
	if _phase not in ["orbit", "stopped"]:
		return _reject("quantum_unavailable", "Sprung erst im Orbit oder nach Abbruch starten")
	if typeof(payload.get("target_orbit_id")) != TYPE_STRING or not Dictionary(_definition.orbits).has(payload.target_orbit_id):
		return _reject("unknown_orbit", "Zielorbit unbekannt")
	var target: String = payload.target_orbit_id
	var requested_marker: Variant = payload.get("target_orbit_marker_id", GRID.ORBIT_MARKER_IDS[0])
	if typeof(requested_marker) != TYPE_STRING:
		return _reject("unknown_orbit_marker", "Orbitmarker unbekannt")
	var marker := GRID.orbit_marker(_definition.orbits[target], requested_marker)
	if marker.is_empty():
		return _reject("unknown_orbit_marker", "Orbitmarker unbekannt")
	if target == _orbit_id and requested_marker == _orbit_marker_id:
		return _reject("already_in_orbit", "Schiff ist bereits an diesem Orbitmarker")
	var multiplier: Variant = context.get("quantum_duration_multiplier", 1.0)
	if typeof(multiplier) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(multiplier)) or float(multiplier) <= 0.0: return _reject("invalid_warp_effect", "Warp-Antriebseffekt ungültig")
	var duration := float(_definition.jump_duration_seconds) * float(multiplier)
	if not is_finite(duration) or duration <= 0.0: return _reject("invalid_warp_effect", "Warp-Reisedauer ungültig")
	_active_jump_duration_seconds = duration
	_origin_position = _position
	_target_orbit_id = target
	_target_orbit_marker_id = requested_marker
	_route_destination = GRID.normalized(GRID.cell_from_record(marker))
	_route_control = GRID.route_control(_origin_position, _route_destination)
	_route_hexes = GRID.route(_origin_position, _route_control, _route_destination)
	_set_travel_pose(_position, GRID.route_heading(_origin_position, _route_control, _route_destination, 0.0))
	_orbit_id = ""
	_orbit_marker_id = ""
	_location_id = ""
	_elapsed_seconds = 0.0
	_progress = 0.0
	_phase = "quantum"
	_revision += 1
	return {"ok": true}

func _abort_quantum() -> Dictionary:
	if _phase != "quantum":
		return _reject("quantum_not_active", "Kein laufender Warp-Sprung")
	_phase = "stopped"
	_orbit_id = ""
	_revision += 1
	return {"ok": true}

func _advance(payload: Dictionary) -> Dictionary:
	var delta: float = float(payload.delta_seconds)
	if _phase != "quantum" or delta == 0.0:
		return {"ok": true, "advanced": false}
	var duration: float = _active_jump_duration_seconds
	_elapsed_seconds = minf(duration, _elapsed_seconds + delta)
	_progress = clampf(_elapsed_seconds / duration, 0.0, 1.0)
	_set_travel_pose(GRID.route_point(_origin_position, _route_control, _route_destination, _progress), GRID.route_heading(_origin_position, _route_control, _route_destination, _progress))
	_revision += 1
	if _progress >= 1.0:
		_arrive(_target_orbit_id, _target_orbit_marker_id)
	return {"ok": true, "advanced": true}

func _valid_delta(payload: Dictionary) -> bool:
	if typeof(payload.get("delta_seconds")) not in [TYPE_FLOAT, TYPE_INT]:
		return false
	var delta: float = float(payload.delta_seconds)
	return is_finite(delta) and delta >= 0.0 and delta <= MAX_ADVANCE_SECONDS

func _begin_approach(payload: Dictionary) -> Dictionary:
	if _phase != "orbit":
		return _reject("orbit_required", "Zuerst den Zielorbit erreichen")
	if typeof(payload.get("location_id")) != TYPE_STRING or not Dictionary(_definition.location_orbits).has(payload.location_id) or payload.location_id == "homebase":
		return _reject("unknown_location", "Zielort unbekannt; Mondbasis separat landen")
	if String(_definition.location_orbits[payload.location_id]) != _orbit_id:
		return _reject("wrong_orbit", "Dieser Ort liegt an einem anderen Himmelskoerper")
	_location_id = String(payload.location_id)
	_phase = "approach"
	_revision += 1
	return {"ok": true}

func _enter_orbit() -> Dictionary:
	if _phase not in ["surface", "approach"]:
		return _reject("surface_exit_required", "Kein bestaetigter Ortsabflug")
	var orbit: String = String(_definition.location_orbits.get(_location_id, ""))
	if orbit.is_empty():
		return _reject("location_unbound", "Ortsorbit fehlt")
	_arrive(orbit, _orbit_marker_id)
	return {"ok": true}

func _land_homebase() -> Dictionary:
	if _phase != "orbit" or _orbit_id != "moon_orbit":
		return _reject("moon_orbit_required", "Zuerst den Mondorbit erreichen")
	_phase = "grounded"
	_location_id = "homebase"
	_orbit_id = ""
	_orbit_marker_id = ""
	_target_orbit_id = ""
	_target_orbit_marker_id = ""
	_origin_position = _position
	_elapsed_seconds = 0.0
	_progress = 0.0
	_route_hexes.clear()
	_revision += 1
	return {"ok": true}

func _arrive(orbit: String, marker_id: String = "orbit_1") -> void:
	_phase = "orbit"
	_orbit_id = orbit
	_orbit_marker_id = marker_id
	_set_travel_pose(GRID.normalized(GRID.cell_from_record(GRID.orbit_marker(_definition.orbits[orbit], marker_id))), _heading)
	_target_orbit_id = ""
	_target_orbit_marker_id = ""
	_route_hexes.clear()
	_location_id = ""
	_revision += 1

func _orbit_position(orbit: String) -> Vector2:
	var point: Array = _definition.orbits[orbit].position
	return Vector2(float(point[0]), float(point[1]))

func _valid_definition(data: Dictionary) -> bool:
	var version: Variant = data.get("version")
	if typeof(version) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(version)):
		return false
	if float(version) == 3.0:
		return bool(ORBIT_CATALOG.validate_v3_product(data).get("ok", false))
	if float(version) != 2.0:
		return false
	if typeof(data.get("bodies")) != TYPE_DICTIONARY or typeof(data.get("orbits")) != TYPE_DICTIONARY or typeof(data.get("location_orbits")) != TYPE_DICTIONARY or typeof(data.get("jump_duration_seconds")) not in [TYPE_FLOAT, TYPE_INT]:
		return false
	var duration: float = float(data.jump_duration_seconds)
	if not is_finite(duration) or duration <= 0.0 or duration > MAX_ADVANCE_SECONDS:
		return false
	if int(data.get("version", 1)) != 2 or Vector2i(GRID.pair(data.get("grid_size", []))) != GRID.SIZE:
		return false
	if data.orbits.size() != GRID.ORBITS.size() or not data.bodies.has("sun"):
		return false
	var used_marker_cells := {}
	for orbit in GRID.ORBITS:
		if typeof(data.orbits.get(orbit)) != TYPE_DICTIONARY or typeof(data.bodies.get(GRID.ORBITS[orbit])) != TYPE_DICTIONARY:
			return false
		if String(data.orbits[orbit].get("body_id", "")) != GRID.ORBITS[orbit]:
			return false
		if not _valid_hex_record(data.orbits[orbit]) or not _valid_hex_record(data.bodies[GRID.ORBITS[orbit]]):
			return false
		var point: Variant = data.orbits[orbit].get("position")
		if typeof(point) != TYPE_ARRAY or point.size() != 2:
			return false
		for value in point:
			if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)) or float(value) < 0.0 or float(value) > 1.0:
				return false
		var body: Dictionary = data.bodies[GRID.ORBITS[orbit]]
		var location := String(data.orbits[orbit].get("location_id", body.get("surface_location_id", "")))
		if not location.is_empty() and String(data.location_orbits.get(location, "")) != orbit:
			return false
		var orbit_data: Dictionary = data.orbits[orbit]
		var markers: Variant = orbit_data.get("markers")
		if not markers is Array or markers.size() != GRID.ORBIT_MARKER_IDS.size():
			return false
		var corners: Array[Vector2i] = []
		var radius := int(body.get("ring_radius", 0))
		for direction in GRID.HEX.DIRECTIONS:
			corners.append(GRID.cell_from_record(body) + direction * radius)
		for i in markers.size():
			if not markers[i] is Dictionary or markers[i].get("id") != GRID.ORBIT_MARKER_IDS[i] or not _valid_cell(markers[i]):
				return false
			var cell := GRID.cell_from_record(markers[i])
			if cell not in corners or used_marker_cells.has(cell):
				return false
			used_marker_cells[cell] = true
		if GRID.cell_from_record(markers[0]) != GRID.cell_from_record(orbit_data):
			return false
	for orbit in data.location_orbits.values():
		if not GRID.ORBITS.has(orbit):
			return false
	return _valid_hex_record(data.bodies.sun) and data.location_orbits.get("homebase") == "moon_orbit"

func _valid_hex_record(record: Dictionary) -> bool:
	return _valid_cell(record) and GRID.normalized(GRID.cell_from_record(record)).is_equal_approx(GRID.pair(record.get("position")))


func _valid_cell(record: Dictionary) -> bool:
	var raw: Variant = record.get("hex")
	if not raw is Array or raw.size() != 2:
		return false
	for value in raw:
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or float(value) != floorf(float(value)):
			return false
	return GRID.contains(GRID.cell_from_record(record))

func _reject(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}


func _initialize_surface(payload: Dictionary) -> Dictionary:
	# Stationary birth, not a fabricated prior launch/approach from home.
	if _phase != "grounded" or not _craft_id.is_empty() or _revision != 0: return _reject("craft_already_initialized", "Schiff besitzt bereits einen Reiseverlauf")
	var location := String(payload.get("location_id", ""))
	if location != "polisa" or not Dictionary(_definition.location_orbits).has(location): return _reject("invalid_surface_origin", "Lokaler Erwerbsort ungültig")
	if not _flight.bind_craft(String(payload.craft_id)):
		return _reject("craft_mismatch", "Flugzustand gehoert einem anderen Schiff")
	_craft_id = String(payload.craft_id)
	_arrive(String(_definition.location_orbits[location]))
	_phase = "surface"
	_location_id = location
	_orbit_id = ""
	_revision += 1
	return {"ok":true,"location_id":location}


# Unwired in-process Fleet delegation. No command router exposes these methods.
func _prepare_space_area_transition_state(expected_revision: int, context: Dictionary) -> Dictionary:
	if _revision != expected_revision: return _reject("travel_revision_changed", "Reisezustand hat sich geaendert")
	if _phase != String(context.get("expected_phase", "")): return _reject("travel_phase_changed", "Reisephase hat sich geaendert")
	var payload: Dictionary = context.get("payload", {})
	var operation := String(context.operation)
	if operation == "launch_to_orbit":
		var id := String(payload.get("craft_id", ""))
		var current_flight: Dictionary = _flight.get_snapshot()
		if _phase != "grounded" or id.is_empty() or current_flight.get("craft_id") != id or current_flight.get("coordinate_frame") != "strategic" or not String(current_flight.get("space_area_id", "")).is_empty() or not String(context.source_area_id).is_empty() or not String(context.target_area_id).is_empty(): return _reject("launch_context_changed", "Startzustand passt nicht")
		if _requests.has(String(context.request_id)): return _reject("request_id_already_used", "Anfrage wurde bereits verwendet")
		var moon: Dictionary = Dictionary(_definition.get("orbits", {})).get("moon_orbit", {})
		var marker: Dictionary = GRID.orbit_marker(moon, GRID.ORBIT_MARKER_IDS[0])
		if marker.is_empty(): return _reject("unknown_orbit_marker", "Heimorbitmarker fehlt")
		var position: Vector2 = GRID.normalized(GRID.cell_from_record(marker)) * GRID.EXTENT
		var launch_candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"launch_pose":{"position":position,"heading":float(current_flight.heading_rad)},"next":{"craft_id":id,"phase":"orbit","orbit_id":"moon_orbit","orbit_marker_id":GRID.ORBIT_MARKER_IDS[0],"target_orbit_id":"","target_orbit_marker_id":"","location_id":"","elapsed_seconds":_elapsed_seconds,"progress":_progress,"revision":_revision + 1}}
		launch_candidate["seal"] = _sign_space_area_state(launch_candidate)
		return launch_candidate
	if operation == "enter_orbit" and _phase == "surface" and _location_id == "polisa" and String(context.source_area_id).is_empty() and String(context.target_area_id).is_empty():
		var current_flight: Dictionary = _flight.get_snapshot()
		if String(payload.get("craft_id", "")) != _craft_id or _craft_id.is_empty() or current_flight.get("coordinate_frame") != "strategic" or current_flight.get("motion_mode") == "tactical" or not String(current_flight.get("space_area_id", "")).is_empty(): return _reject("station_flight_changed", "Stationsflugzustand passt nicht")
		if _requests.has(String(context.request_id)): return _reject("request_id_already_used", "Anfrage wurde bereits verwendet")
		var station_orbit := String(Dictionary(_definition.get("location_orbits", {})).get(_location_id, ""))
		var orbit: Dictionary = Dictionary(_definition.get("orbits", {})).get(station_orbit, {})
		var marker_id := _orbit_marker_id if not _orbit_marker_id.is_empty() else GRID.ORBIT_MARKER_IDS[0]
		var marker: Dictionary = GRID.orbit_marker(orbit, marker_id)
		if marker.is_empty(): return _reject("unknown_orbit_marker", "Stationsorbitmarker fehlt")
		var position: Vector2 = GRID.normalized(GRID.cell_from_record(marker)) * GRID.EXTENT
		var station_candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"launch_pose":{"position":position,"heading":float(current_flight.heading_rad)},"next":{"phase":"orbit","orbit_id":station_orbit,"orbit_marker_id":marker_id,"target_orbit_id":"","target_orbit_marker_id":"","location_id":"","elapsed_seconds":_elapsed_seconds,"progress":_progress,"revision":_revision + 1}}
		station_candidate["seal"] = _sign_space_area_state(station_candidate)
		return station_candidate
	if operation == "land_homebase":
		var current_flight: Dictionary = _flight.get_snapshot()
		if _phase != "orbit" or _orbit_id != "moon_orbit" or String(payload.get("craft_id", "")) != _craft_id or current_flight.get("coordinate_frame") != "local" or current_flight.get("motion_mode") != "tactical" or current_flight.get("space_area_id") != "orbit_approach:moon" or context.source_area_id != "orbit_approach:moon" or not String(context.target_area_id).is_empty(): return _reject("moon_orbit_required", "Heimatlandung braucht den lokalen Mondorbit")
		if _requests.has(String(context.request_id)): return _reject("request_id_already_used", "Anfrage wurde bereits verwendet")
		var moon: Dictionary = Dictionary(_definition.get("bodies", {})).get("moon", {})
		if typeof(moon.get("position")) != TYPE_ARRAY or moon.position.size() != 2: return _reject("invalid_body_position", "Heimatkoerper ungueltig")
		var position: Vector2 = GRID.pair(moon.position) * GRID.EXTENT
		var home_candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"home_pose":{"position":position},"next":{"phase":"grounded","orbit_id":"","orbit_marker_id":"","target_orbit_id":"","target_orbit_marker_id":"","location_id":"homebase","elapsed_seconds":0.0,"progress":0.0,"revision":_revision + 1}}
		home_candidate["seal"] = _sign_space_area_state(home_candidate)
		return home_candidate
	if String(payload.get("craft_id", "")) != _craft_id or _craft_id.is_empty(): return _reject("craft_mismatch", "Schiff passt nicht zur Reise")
	if _requests.has(String(context.request_id)): return _reject("request_id_already_used", "Anfrage wurde bereits ausserhalb dieses Uebergangs verwendet")
	if operation in ["begin_station_landing", "depart_station_landing"]:
		var layout: Dictionary = STATION_DOCK.build()
		var current_flight: Dictionary = _flight.get_snapshot()
		var incoming := operation == "begin_station_landing"
		if not layout.get("ok", false) or payload.get("location_id") != "polisa" or Dictionary(_definition.get("location_orbits", {})).get("polisa") != "polisa_orbit" or (incoming and (_phase != "orbit" or _orbit_id != "polisa_orbit")) or (not incoming and (_phase not in ["surface", "approach"] or _location_id != "polisa")): return _reject("station_phase_changed", "Stationsreise passt nicht")
		if current_flight.get("craft_id") != _craft_id or current_flight.get("coordinate_frame") != "local" or current_flight.get("motion_mode") != ("tactical" if incoming else "inactive") or current_flight.get("space_area_id") != layout.area_id or context.source_area_id != layout.area_id or context.target_area_id != layout.area_id: return _reject("station_flight_changed", "Lokaler Stationsflug passt nicht")
		var candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"next":{"phase":"approach" if incoming else "orbit","orbit_id":"polisa_orbit","orbit_marker_id":_orbit_marker_id if not _orbit_marker_id.is_empty() else GRID.ORBIT_MARKER_IDS[0],"target_orbit_id":"","target_orbit_marker_id":"","location_id":"polisa" if incoming else "","elapsed_seconds":_elapsed_seconds,"progress":_progress,"revision":_revision + 1}}
		candidate["seal"] = _sign_space_area_state(candidate)
		return candidate
	if operation == "depart_station_purchase":
		var layout: Dictionary = STATION_DOCK.build()
		var current_flight: Dictionary = _flight.get_snapshot()
		if not layout.get("ok", false) or payload.get("target_id") != layout.target_id or payload.get("layout_revision") != layout.revision or payload.get("location_id") != layout.station_id: return _reject("station_layout_changed", "Stationsziel passt nicht")
		if _phase != "surface" or _location_id != "polisa" or Dictionary(_definition.get("location_orbits", {})).get("polisa") != "polisa_orbit": return _reject("station_phase_changed", "Stationsreise passt nicht")
		if current_flight.get("craft_id") != _craft_id or current_flight.get("coordinate_frame") != "strategic" or current_flight.get("motion_mode") == "tactical" or not String(current_flight.get("space_area_id", "")).is_empty() or not String(context.source_area_id).is_empty() or context.target_area_id != layout.area_id: return _reject("station_flight_changed", "Stationsflugzustand passt nicht")
		var candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"next":{"phase":"orbit","orbit_id":"polisa_orbit","orbit_marker_id":_orbit_marker_id if not _orbit_marker_id.is_empty() else GRID.ORBIT_MARKER_IDS[0],"target_orbit_id":"","target_orbit_marker_id":"","location_id":"","elapsed_seconds":_elapsed_seconds,"progress":_progress,"revision":_revision + 1}}
		candidate["seal"] = _sign_space_area_state(candidate)
		return candidate
	if operation in ["begin_station_dock", "undock_station"]:
		var layout: Dictionary = STATION_DOCK.build()
		var current_flight: Dictionary = _flight.get_snapshot()
		var docking := operation == "begin_station_dock"
		if not layout.get("ok", false) or payload.get("target_id") != layout.target_id or payload.get("layout_revision") != layout.revision or payload.get("location_id") != layout.station_id: return _reject("station_layout_changed", "Stationsziel passt nicht")
		if current_flight.get("craft_id") != _craft_id or context.source_area_id != layout.area_id or context.target_area_id != layout.area_id or current_flight.get("coordinate_frame") != "local" or current_flight.get("space_area_id") != layout.area_id or current_flight.get("motion_mode") != ("tactical" if docking else "inactive"): return _reject("station_flight_changed", "Lokaler Stationsflug passt nicht")
		var station_orbit := String(Dictionary(_definition.get("location_orbits", {})).get("polisa", ""))
		if station_orbit != "polisa_orbit" or (docking and (_phase != "orbit" or _orbit_id != station_orbit)) or (not docking and (_phase not in ["surface", "approach"] or _location_id != "polisa")): return _reject("station_phase_changed", "Stationsreise passt nicht")
		var candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"next":{"phase":"approach" if docking else "orbit","orbit_id":station_orbit,"orbit_marker_id":_orbit_marker_id if not _orbit_marker_id.is_empty() else GRID.ORBIT_MARKER_IDS[0],"target_orbit_id":"","target_orbit_marker_id":"","location_id":"polisa" if docking else "","elapsed_seconds":_elapsed_seconds,"progress":_progress,"revision":_revision + 1}}
		candidate["seal"] = _sign_space_area_state(candidate)
		return candidate
	if operation == "start_quantum":
		if _phase != "orbit": return _reject("orbit_required", "Lokaler Warpstart braucht den vorhandenen Orbit")
		var current_flight: Dictionary = _flight.get_snapshot()
		if current_flight.get("coordinate_frame") != "local" or current_flight.get("motion_mode") != "tactical" or current_flight.get("space_area_id") != context.source_area_id or not String(context.target_area_id).is_empty(): return _reject("local_flight_required", "Lokaler Flugzustand passt nicht")
		var source_orbit: Dictionary = Dictionary(_definition.get("orbits", {})).get(_orbit_id, {})
		var source_body: Dictionary = Dictionary(_definition.get("bodies", {})).get(String(source_orbit.get("body_id", "")), {})
		var expected_layout: Dictionary = load("res://scripts/mission/orbit_approach_layout.gd").build(String(source_body.get("id", "")))
		if not expected_layout.get("ok", false) or expected_layout.body_map_id != context.source_area_id or source_body.get("position") != context.origin_position: return _reject("area_body_mismatch", "Strategischer Ursprung passt nicht zum lokalen Koerper")
		var target_id := String(payload.get("target_orbit_id", ""))
		var target_orbit: Dictionary = Dictionary(_definition.get("orbits", {})).get(target_id, {})
		var target_marker := String(payload.get("target_orbit_marker_id", GRID.ORBIT_MARKER_IDS[0]))
		var marker: Dictionary = GRID.orbit_marker(target_orbit, target_marker)
		if marker.is_empty(): return _reject("unknown_orbit_marker", "Zielorbit oder Marker unbekannt")
		if String(target_orbit.get("body_id", "")) == String(source_body.get("id", "")): return _reject("already_in_orbit", "Schiff ist bereits an diesem Koerper")
		var duration := float(_definition.jump_duration_seconds) * float(context.warp_multiplier)
		if not is_finite(duration) or duration <= 0.0: return _reject("invalid_warp_effect", "Warp-Reisedauer ungueltig")
		var origin := Vector2(float(context.origin_position[0]), float(context.origin_position[1]))
		var destination: Vector2 = GRID.normalized(GRID.cell_from_record(marker))
		var control: Vector2 = GRID.route_control(origin, destination)
		var warp_candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"next":{"phase":"quantum","orbit_id":"","orbit_marker_id":"","target_orbit_id":target_id,"target_orbit_marker_id":target_marker,"location_id":"","elapsed_seconds":0.0,"progress":0.0,"revision":_revision + 1},"warp":{"origin":origin,"destination":destination,"control":control,"route_hexes":GRID.route(origin, control, destination),"duration":duration,"heading":GRID.route_heading(origin, control, destination, 0.0)}}
		warp_candidate["seal"] = _sign_space_area_state(warp_candidate)
		return warp_candidate
	# Existing strategic approach has no local Flight/index transition. Stage
	# its phase change so departure fuel, campaign and travel publish together.
	if operation == "begin_approach" and String(context.source_area_id).is_empty() and String(context.target_area_id).is_empty():
		var current_flight: Dictionary = _flight.get_snapshot()
		var location: Variant = payload.get("location_id")
		if _phase != "orbit": return _reject("orbit_required", "Zuerst den Zielorbit erreichen")
		if current_flight.get("coordinate_frame") != "strategic" or not String(current_flight.get("space_area_id", "")).is_empty() or current_flight.get("motion_mode") == "tactical": return _reject("strategic_flight_required", "Strategischer Flugzustand erforderlich")
		if typeof(location) != TYPE_STRING or not Dictionary(_definition.location_orbits).has(location) or location == "homebase": return _reject("unknown_location", "Zielort unbekannt; Mondbasis separat landen")
		if String(_definition.location_orbits[location]) != _orbit_id: return _reject("wrong_orbit", "Dieser Ort liegt an einem anderen Himmelskoerper")
		var strategic_candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":_space_area_flight_binding(current_flight),"next":{"phase":"approach","orbit_id":_orbit_id,"orbit_marker_id":_orbit_marker_id,"target_orbit_id":"","target_orbit_marker_id":"","location_id":location,"elapsed_seconds":_elapsed_seconds,"progress":_progress,"revision":_revision + 1}}
		strategic_candidate["seal"] = _sign_space_area_state(strategic_candidate)
		return strategic_candidate
	var orbit := ""
	var marker := ""
	var elapsed := _elapsed_seconds
	var progress := _progress
	var next_revision := _revision + 1
	var next_phase := "orbit"
	var next_location := ""
	if operation == "advance":
		if _phase != "quantum" or not _valid_delta(payload): return _reject("quantum_completion_required", "Nur bestaetigter Warpabschluss kann vorbereitet werden")
		var delta := float(payload.delta_seconds)
		if delta <= 0.0 or _elapsed_seconds + delta < _active_jump_duration_seconds: return _reject("quantum_not_complete", "Warpflug ist noch nicht abgeschlossen")
		orbit = _target_orbit_id
		marker = _target_orbit_marker_id
		elapsed = _active_jump_duration_seconds
		progress = 1.0
		next_revision += 1 # Existing completion: advance revision followed by arrival revision.
	elif operation == "enter_orbit":
		if _phase not in ["surface", "approach"]: return _reject("surface_exit_required", "Kein vorhandener Ortsabflug")
		orbit = String(Dictionary(_definition.get("location_orbits", {})).get(_location_id, ""))
		marker = _orbit_marker_id
	elif operation == "begin_approach":
		if _phase != "orbit": return _reject("orbit_required", "Lokaler Anflug braucht den vorhandenen Zielorbit")
		next_location = String(payload.get("location_id", ""))
		if next_location == "homebase": return _reject("home_landing_separate", "Heimatlandung bleibt ein eigener Pfad")
		var named_body: Dictionary = Dictionary(_definition.get("bodies", {})).get(next_location, {})
		if String(named_body.get("kind", "")) == "station": return _reject("station_not_surface", "Station ist kein Oberflaechenziel")
		orbit = _orbit_id
		if next_location.is_empty() or String(Dictionary(_definition.get("location_orbits", {})).get(next_location, "")) != orbit: return _reject("location_orbit_mismatch", "Zielort liegt nicht am tatsaechlichen Orbit")
		marker = _orbit_marker_id
		next_phase = "approach"
	else: return _reject("unsupported_area_operation", "Operation gehoert nicht zu dieser vorbereiteten Grenze")
	var orbit_definition: Dictionary = Dictionary(_definition.get("orbits", {})).get(orbit, {})
	var body_id := String(orbit_definition.get("body_id", ""))
	var body: Dictionary = Dictionary(_definition.get("bodies", {})).get(body_id, {})
	if body.is_empty() or String(body.get("id", "")) != body_id: return _reject("unbound_target_body", "Zielkoerper ist nicht kanonisch gebunden")
	if operation == "begin_approach" and (String(body.get("kind", "")) == "station" or String(body.get("surface_location_id", "")) != next_location):
		return _reject("body_surface_mismatch", "Koerper weist diesen Ort nicht als Oberflaeche aus")
	if marker.is_empty() and operation == "enter_orbit": marker = GRID.ORBIT_MARKER_IDS[0]
	if GRID.orbit_marker(orbit_definition, marker).is_empty(): return _reject("unknown_orbit_marker", "Vorhandener Orbitmarker fehlt")
	var layout: Dictionary = load("res://scripts/mission/orbit_approach_layout.gd").build(body_id)
	if not layout.get("ok", false) or String(context.target_area_id) != String(layout.body_map_id):
		return _reject("area_body_mismatch", "Bereich passt nicht zum tatsaechlichen Reiseziel")
	var flight_binding := {}
	var flight_snapshot: Dictionary = _flight.get_snapshot()
	if operation == "begin_approach":
		if flight_snapshot.get("coordinate_frame") != "local" or flight_snapshot.get("motion_mode") != "tactical" or String(flight_snapshot.get("space_area_id", "")) != String(context.source_area_id) or String(context.source_area_id) != String(layout.body_map_id):
			return _reject("local_surface_approach_required", "Oberflaechenanflug braucht den echten lokalen taktischen Flight")
		flight_binding = _space_area_flight_binding(flight_snapshot)
	elif flight_snapshot.get("coordinate_frame", "strategic") == "local":
		if operation != "enter_orbit" or flight_snapshot.get("motion_mode") != "inactive" or String(flight_snapshot.get("space_area_id", "")) != String(context.source_area_id) or String(context.source_area_id) != String(layout.body_map_id):
			return _reject("inactive_local_return_required", "Nur passender inaktiver Ortsflight darf lokal reaktiviert werden")
		flight_binding = _space_area_flight_binding(flight_snapshot)
	elif String(context.source_area_id) != "" or String(flight_snapshot.get("space_area_id", "")) != "":
		return _reject("area_body_mismatch", "Strategischer Ausgangsbereich muss leer sein")
	var candidate := {"ok":true,"owner_instance_id":get_instance_id(),"owner_epoch":_space_area_epoch,
		"expected_revision":expected_revision,"context":context.duplicate(true),"flight_binding":flight_binding,
		"next":{"phase":next_phase,"orbit_id":orbit,"orbit_marker_id":marker,"target_orbit_id":"","target_orbit_marker_id":"",
			"location_id":next_location,"elapsed_seconds":elapsed,"progress":progress,"revision":next_revision}}
	candidate["seal"] = _sign_space_area_state(candidate)
	return candidate

func _sign_space_area_state(candidate: Dictionary) -> String:
	var content := candidate.duplicate(true)
	content.erase("seal")
	return (_space_area_seal + JSON.stringify(content, "", true)).sha256_text()

func _validate_prepared_space_area_state(candidate: Dictionary, context: Dictionary) -> Dictionary:
	if not candidate.get("ok", false) or int(candidate.get("owner_instance_id", 0)) != get_instance_id() or int(candidate.get("owner_epoch", -1)) != _space_area_epoch or String(candidate.get("seal", "")) != _sign_space_area_state(candidate):
		return _reject("invalid_area_candidate", "Vorbereitung gehoert nicht zu diesem Reiseowner")
	if JSON.stringify(candidate.get("context", {}), "", true) != JSON.stringify(context, "", true): return _reject("area_context_changed", "Rootkontext hat sich geaendert")
	if _revision != int(candidate.get("expected_revision", -1)): return _reject("travel_revision_changed", "Reisezustand hat sich geaendert")
	if _phase != String(context.get("expected_phase", "")): return _reject("travel_phase_changed", "Reisephase hat sich geaendert")
	var expected_flight: Dictionary = candidate.get("flight_binding", {})
	if not expected_flight.is_empty() and JSON.stringify(expected_flight, "", true) != JSON.stringify(_space_area_flight_binding(_flight.get_snapshot()), "", true):
		return _reject("local_flight_changed", "Lokaler Flightzustand hat sich seit Vorbereitung geaendert")
	# A no-op legacy request may consume this key without changing revision.
	if _requests.has(String(context.request_id)): return _reject("request_id_already_used", "Anfrage wurde zwischenzeitlich verwendet")
	return {"ok":true}

func _publish_prepared_space_area_state(candidate: Dictionary) -> Dictionary:
	# Root-private synchronous tail AFTER validation. No apply_command/_arrive,
	# no signals, callbacks, awaits or strategic/local Flight pose assignments.
	var next: Dictionary = candidate.next
	if next.has("craft_id"): _craft_id = String(next.craft_id)
	_phase = String(next.phase)
	_orbit_id = String(next.orbit_id)
	_orbit_marker_id = String(next.orbit_marker_id)
	_target_orbit_id = String(next.target_orbit_id)
	_target_orbit_marker_id = String(next.target_orbit_marker_id)
	_location_id = String(next.location_id)
	_elapsed_seconds = float(next.elapsed_seconds)
	_progress = float(next.progress)
	_route_hexes.clear()
	if candidate.has("warp"):
		var warp: Dictionary = candidate.warp
		_origin_position = warp.origin
		_route_destination = warp.destination
		_route_control = warp.control
		_route_hexes.assign(warp.route_hexes)
		_active_jump_duration_seconds = float(warp.duration)
	if candidate.has("home_pose"): _origin_position = Vector2(candidate.home_pose.position) / GRID.EXTENT
	_revision = int(next.revision)
	var context: Dictionary = candidate.context
	var result := {"ok":true,"phase":_phase,"revision":_revision,"craft_id":_craft_id,
		"source_area_id":String(context.source_area_id),"target_area_id":String(context.target_area_id)}
	_requests[String(context.request_id)] = {"signature":JSON.stringify({"operation":context.operation,"payload":context.payload}, "", true),"result":result.duplicate(true)}
	return result


func _space_area_flight_binding(snapshot: Dictionary) -> Dictionary:
	return {"owner_instance_id":_flight.get_instance_id(),"craft_id":String(snapshot.get("craft_id", "")),"revision":int(snapshot.get("revision", -1)),
		"coordinate_frame":String(snapshot.get("coordinate_frame", "")),"space_area_id":String(snapshot.get("space_area_id", "")),"motion_mode":String(snapshot.get("motion_mode", ""))}
