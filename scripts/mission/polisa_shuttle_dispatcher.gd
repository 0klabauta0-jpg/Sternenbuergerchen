extends RefCounted
## Orchestrates existing authoritative actor, station and travel operations.
## Never advances a stage based on a UI action or elapsed time alone.
var _bridge = preload("res://scripts/mission/polisa_shuttle_station_lifecycle.gd").new()
var _flow: Node
var _base: Node
var _owner: RefCounted
var _other_evidence: Callable
var _place: Node
var _source := ""
var _person := ""
var _craft := ""
var _pilot := ""
var _phase := "unconfigured"
var _last_error := ""
var _retry_seconds := 0.0
var _generation := 0
var _remaining := 0
var _cancel_from := ""

func configure(flow: Node, base: Node, owner: RefCounted, other_evidence: Callable) -> Dictionary:
	if _phase != "unconfigured" or not is_instance_valid(flow) or not is_instance_valid(base) or owner == null or not base.has_method("get_shuttle_person_status"): return _reject("dispatcher_configuration_invalid")
	_flow = flow
	_base = base
	_owner = owner
	_other_evidence = other_evidence
	var result: Dictionary = _owner.configure(Callable(self, "_verify"), Callable(_base, "get_shuttle_person_status"))
	if not result.get("ok", false): return result
	_phase = "idle"
	return {"ok":true}

func request_departure(source_craft_id: String) -> Dictionary:
	if _phase == "complete":
		var ready := rearm()
		if not ready.get("ok", false): return ready
	if _phase != "idle":
		return {"ok":true,"handled":true,"pending":true,"message":_status_message(),"reason":_last_error} if source_craft_id == _source else _reject("shuttle_busy")
	if not _flow.has_method("get_mission_for_craft"): return _reject("station_unavailable")
	var place: Node = _flow.call("get_mission_for_craft", source_craft_id)
	if not is_instance_valid(place) or String(place.get_meta("location_id", "")) != "polisa": return {"ok":true,"handled":false}
	var visits: Dictionary = place.get_meta("singleplayer_visit_identities", {})
	var source: Dictionary = visits.get(source_craft_id, {})
	var controller := place.get_node_or_null("TacticalController")
	var simulation := place.get_node_or_null("SimulationRoot")
	if not is_instance_valid(controller) or not is_instance_valid(simulation) or not simulation.has_method("get_hex_unit_state"): return _reject("station_runtime_unavailable")
	var deployed: Variant = controller.get("_deployed_unit_ids")
	if typeof(deployed) != TYPE_DICTIONARY: return _reject("station_presence_unavailable")
	var candidates: Array[String] = []
	for raw in Array(source.get("unit_ids", [])):
		var id := String(raw)
		if id.begins_with("polisa_recruit_") and deployed.has(id) and not Dictionary(simulation.call("get_hex_unit_state", id)).is_empty(): candidates.append(id)
	if candidates.is_empty(): return {"ok":true,"handled":false}
	var person := candidates[0]
	var ground: Dictionary = simulation.call("get_hex_unit_state", person)
	if not ground.get("grid") is Vector2i or not simulation.has_method("get_hex_ground_terrain_registry") or not simulation.has_method("get_hex_ground_planning_snapshot"): return _reject("station_ground_unavailable")
	var terrain: Node = simulation.call("get_hex_ground_terrain_registry")
	var planning: Dictionary = simulation.call("get_hex_ground_planning_snapshot")
	if not is_instance_valid(terrain) or not terrain.has_method("get_legal_hex_neighbors") or not terrain.has_method("is_walkable") or not planning.get("occupant_by_grid") is Dictionary: return _reject("station_ground_unavailable")
	var spawn := Vector2i.ZERO
	var found := false
	for neighbor: Vector2i in terrain.call("get_legal_hex_neighbors", ground.grid):
		if bool(terrain.call("is_walkable", neighbor)) and not planning.occupant_by_grid.has(neighbor) and not Dictionary(planning.get("external_admission_blocked_grids", {})).has(neighbor):
			spawn = neighbor; found = true; break
	if not found: return _reject("pilot_spawn_unavailable")
	var craft := "polisa_service_shuttle_" + (person + ":" + source_craft_id + ":" + str(_generation)).sha256_text().substr(0, 16)
	var requested: Dictionary = _bridge.request_station_pilot(place, craft, spawn)
	if not requested.get("ok", false): return requested
	_place = place; _source = source_craft_id; _person = person; _craft = craft
	_remaining = candidates.size() - 1
	_pilot = String(requested.get("unit_id", ""))
	if _pilot.is_empty(): return _reject("pilot_identity_missing")
	_phase = "pilot_pending"
	return {"ok":true,"handled":true,"pending":true,"message":"Shuttle-Pilot wird bereitgestellt"}

func advance(delta: float) -> void:
	if not is_finite(delta) or delta < 0.0 or _phase in ["idle", "unconfigured", "complete"]: return
	if _phase == "cancelled": return
	if _phase == "cancelling":
		_retry_seconds = maxf(0.0, _retry_seconds - delta)
		if _retry_seconds <= 0.0:
			_retry_seconds = 0.5
			_attempt_cancel()
		return
	if not is_instance_valid(_place): _last_error = "station_unavailable"; return
	_retry_seconds = maxf(0.0, _retry_seconds - delta)
	if _retry_seconds > 0.0: return
	_retry_seconds = 0.5
	var controller := _place.get_node_or_null("TacticalController")
	if not is_instance_valid(controller): _last_error = "station_controller_missing"; return
	if _phase == "pilot_pending":
		var setup := _place.get_node_or_null("MissionSetup")
		if not is_instance_valid(setup) or not setup.has_method("get_polisa_recruit_admission"): _last_error = "pilot_selection_missing"; return
		var pilot: Dictionary = setup.call("get_polisa_recruit_admission", _pilot)
		if not pilot.get("ok", false): _last_error = String(pilot.get("reason", "pilot_pending")); return
		var admitted: Dictionary = _bridge.admit(_place, _craft, _pilot, _person, _source)
		if not admitted.get("ok", false): _last_error = String(admitted.get("reason", "shuttle_admission_failed")); return
		_phase = "walk_pending"
	if _phase == "walk_pending":
		var walk: Dictionary = _bridge.request_boarding_walk(_place, _craft)
		if not walk.get("ok", false): _last_error = String(walk.get("reason", "boarding_walk_failed")); return
		_phase = "approaching"
	if _phase == "approaching":
		if _bridge.verify_boarded(_place, _person, _craft):
			if not controller.has_method("_apply_selected_mission_dropship_return") or not bool(controller.call("_apply_selected_mission_dropship_return", _craft)): _last_error = "shuttle_takeoff_unavailable"; return
			_phase = "taking_off"
		else:
			var boarding: Dictionary = _bridge.request_boarding(_place, _craft)
			_last_error = String(boarding.get("reason", ""))
		return
	if _phase == "taking_off":
		if not controller.has_method("get_polisa_service_departure"): _last_error = "takeoff_evidence_unavailable"; return
		var receipt: Dictionary = controller.call("get_polisa_service_departure", _craft)
		if receipt.is_empty(): return
		var started: Dictionary = _owner.begin(_person, _craft, receipt)
		if not started.get("ok", false): _last_error = String(started.get("reason", "travel_start_failed")); return
		_phase = "wait_next" if _remaining > 0 else "player_departure_pending"
	if _phase == "wait_next":
		if _owner.get_snapshot().get("phase") != "idle": return
		var next_source := _source
		_phase = "complete"
		var reset := rearm()
		if not reset.get("ok", false): _last_error = String(reset.get("reason", "shuttle_busy")); return
		var next := request_departure(next_source)
		if not next.get("ok", false):
			_source = next_source
			_phase = "next_recruit_pending"
			_last_error = String(next.get("reason", "shuttle_unavailable"))
		elif not next.get("handled", false):
			_source = next_source
			_phase = "player_departure_pending"
		return
	if _phase == "next_recruit_pending":
		var next_source := _source
		_phase = "idle"
		var next := request_departure(next_source)
		if not next.get("ok", false): _source = next_source; _phase = "next_recruit_pending"; _last_error = String(next.get("reason", "shuttle_unavailable"))
		elif not next.get("handled", false): _source = next_source; _phase = "player_departure_pending"
		return
	if _phase == "player_departure_pending":
		var returned: Dictionary = _flow.call("_request_singleplayer_return", _source)
		if not returned.get("ok", false): _last_error = String(returned.get("reason", "player_departure_pending")); return
		_phase = "complete"
		_last_error = ""

func get_snapshot() -> Dictionary:
	return {"phase":_phase,"source_craft_id":_source,"person_id":_person,"craft_id":_craft,"reason":_last_error,"message":_status_message()}

func _status_message() -> String:
	if _phase == "cancelling": return "Shuttle-Abbruch läuft; Besatzung und Landeplatz werden sicher freigegeben."
	if _phase == "cancelled": return "Shuttlefahrt wurde sicher abgebrochen."
	match _last_error:
		"no_free_compatible_station_pad", "station_pad_missing": return "Shuttle wartet auf einen freien, passenden Stationslandeplatz."
		"boarding_approach_unavailable", "pilot_not_at_ship", "crew_not_at_ship": return "Shuttle-Besatzung wartet auf einen freien Weg zum Schiff."
		"selection_capacity": return "Auf der Station ist kein Personenplatz für den Shuttle-Piloten frei."
		"station_unavailable", "station_runtime_unavailable", "station_controller_missing": return "Shuttle wartet darauf, dass die Station verfügbar ist."
		"admission_pending", "pilot_boarding_pending", "":
			return "Shuttle-Service wird vorbereitet."
		_: return "Shuttle kann gerade nicht weiterfahren. Bitte den Stationszustand prüfen."

func rearm() -> Dictionary:
	if _phase != "complete" or _owner == null or not _owner.has_method("get_snapshot"): return _reject("shuttle_not_rearmable")
	var state: Dictionary = _owner.get_snapshot()
	if state.get("phase") != "idle": return _reject("shuttle_busy")
	_generation += 1
	_phase = "idle"
	_place = null
	_source = ""; _person = ""; _craft = ""; _pilot = ""; _last_error = ""; _retry_seconds = 0.0; _remaining = 0
	return {"ok":true}

## Cancellation requires an idle flight owner. After transfer the controller
## additionally requires both real crew to remain grounded and ships parked.
func cancel_before_transfer() -> Dictionary:
	if _phase == "cancelling": return {"ok":true,"pending":true,"message":_status_message()}
	if _phase == "cancelled": return {"ok":true,"pending":false,"craft_id":_craft}
	if _phase not in ["pilot_pending", "walk_pending", "approaching"] or not is_instance_valid(_place): return _reject("service_cancel_requires_crew_recovery")
	if _owner == null or not _owner.has_method("get_snapshot") or _owner.get_snapshot().get("phase") != "idle": return _reject("service_already_in_transit")
	if _phase in ["walk_pending", "approaching"]:
		var controller := _place.get_node_or_null("TacticalController")
		if not is_instance_valid(controller) or not controller.has_method("can_cancel_polisa_service_transfer"): return _reject("service_cancel_requires_crew_recovery")
		var preflight: Dictionary = controller.call("can_cancel_polisa_service_transfer", _source, _craft, _person, _pilot)
		if not preflight.get("ok", false): return preflight
	_cancel_from = _phase
	_phase = "cancelling"
	_retry_seconds = 0.0
	return _attempt_cancel()

func _attempt_cancel() -> Dictionary:
	if _phase != "cancelling" or not is_instance_valid(_place): return _reject("service_cancel_context_unavailable")
	var cleaned: Dictionary
	if _cancel_from == "pilot_pending":
		var setup := _place.get_node_or_null("MissionSetup")
		if not is_instance_valid(setup) or not setup.has_method("retire_polisa_service_actors"):
			_last_error = "pilot_cleanup_unavailable"
			return {"ok":true,"pending":true,"message":_status_message(),"reason":_last_error}
		cleaned = setup.call("retire_polisa_service_actors", PackedStringArray([_pilot]))
	else:
		var controller := _place.get_node_or_null("TacticalController")
		if not is_instance_valid(controller) or not controller.has_method("cancel_polisa_service_transfer"):
			_last_error = "service_cancel_requires_crew_recovery"
			return {"ok":true,"pending":true,"message":_status_message(),"reason":_last_error}
		cleaned = controller.call("cancel_polisa_service_transfer", _source, _craft, _person, _pilot)
	if not cleaned.get("ok", false):
		_last_error = String(cleaned.get("reason", "service_cleanup_pending"))
		return {"ok":true,"pending":true,"message":_status_message(),"reason":_last_error}
	_last_error = ""
	_phase = "cancelled"
	return {"ok":true,"pending":false,"craft_id":_craft,"message":_status_message()}

## Adapter acknowledges only after releasing its matching home-pad reservation.
func ack_cancelled() -> Dictionary:
	if _phase != "cancelled": return _reject("service_cancel_not_complete")
	_phase = "idle"
	_place = null
	_source = ""; _person = ""; _craft = ""; _pilot = ""; _last_error = ""; _retry_seconds = 0.0; _remaining = 0; _cancel_from = ""
	_generation += 1
	return {"ok":true}

func _verify(kind: String, person_id: String, craft_id: String, receipt: Dictionary) -> bool:
	if kind == "boarding_polisa":
		if not is_instance_valid(_place): return false
		var controller := _place.get_node_or_null("TacticalController")
		return is_instance_valid(controller) and controller.has_method("verify_polisa_service_departure") and bool(controller.call("verify_polisa_service_departure", person_id, craft_id, receipt))
	if not _other_evidence.is_valid(): return false
	var value: Variant = _other_evidence.call(kind, person_id, craft_id, receipt)
	return typeof(value) == TYPE_BOOL and value == true

func _reject(reason: String) -> Dictionary:
	return {"ok":false,"reason":reason}
