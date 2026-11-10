extends Node
## SimulationRoot-bound owner of base positions and intentions only.
## Transport membership, pilot assignment, equipment and medical state stay
## with the existing owners; this owner never creates a transport payload.
signal terminal_ready(unit_id: String, terminal_id: String)
signal state_changed
const ACTOR = preload("res://scripts/core/base_personnel_actor.gd")
const NAV_PATH := "res://scripts/meta/base_interior_navigation.gd"
var _flow: Node
var _screen: Node
var _sim: Node
var _terrain: Node
var _registry: Node
var _layout: Dictionary = {}
var _states: Dictionary = {}
var _beds: Dictionary = {}
var _sequence: int = 0
var _board_groups: Dictionary = {}
var _poll_seconds: float = 0.0
var _navigation_graph: RefCounted
var _committing_transport: bool = false
var _rest_elapsed := 0.0
const AUTOMATIC_REST_IDLE_SECONDS := 20.0
const MANUAL_PRIORITY_SECONDS := 30.0

func configure(flow: Node, screen: Node, simulation: Node, checkpoint: Dictionary = {}) -> void:
	_flow = flow
	_screen = screen
	_sim = simulation
	var navigation = load(NAV_PATH)
	var base_path := "res://maps/campaign_intro_base.json"
	var map_data = navigation.load_map(base_path)
	_layout = navigation.layout(base_path)
	_terrain = load("res://scripts/terrain/terrain_registry.gd").new()
	_terrain.name = "BaseTerrainRegistry"
	_sim.get_parent().add_child(_terrain)
	var tile_size: Dictionary = map_data.get_tile_size()
	_terrain.configure_iso_grid(map_data.get_grid_origin(), tile_size.half_width, tile_size.half_height, map_data.get_grid_topology())
	for tile in map_data.get_tiles():
		_terrain.register_tile(tile)
	_navigation_graph = navigation.new()
	_navigation_graph.call("configure_graph", _terrain)
	_registry = load("res://scripts/registries/unit_registry.gd").new()
	_registry.name = "BaseUnitRegistry"
	_sim.get_parent().add_child(_registry)
	_sim.unit_registry_path = _sim.get_path_to(_registry)
	_sim.terrain_registry_path = _sim.get_path_to(_terrain)
	_sim.unit_minimum_spacing_enabled = false
	_sim.configure_base_personnel(self)
	var saved: Dictionary = Dictionary(checkpoint.get("base_personnel", {})).get("units", {})
	var roster: Array = flow.get("_all_team_units")
	for index in range(roster.size()):
		var profile: Dictionary = roster[index]
		var id := String(profile.unit_id)
		var actor: Node2D = ACTOR.new()
		actor.unit_id = id
		actor.name = id.validate_node_name()
		add_child(actor)
		var spawn: Vector2 = _world(_layout.get("avatar_spawn_grid", [28,44]))
		actor.position = spawn + Vector2(index * 24.0, index * 12.0)
		_registry.register_unit(id, actor)
		_sim.register_known_unit(id, actor)
		_states[id] = {"unit_id":id,"name":String(profile.get("display_name", id)),"role":String(profile.get("role_name", "")),"status":"outside","craft_id":"","bed_id":"","action":{},"last_result":{},"auto_rest_enabled":true,"idle_seconds":0.0,"manual_priority_seconds":0.0,"rest_automatic":false}
		var restore: Dictionary = saved.get(id, {})
		_states[id].auto_rest_enabled=bool(restore.get("auto_rest_enabled",true))
		_states[id].rest_automatic=bool(restore.get("rest_automatic",false))
		var point: Array = restore.get("position", [])
		if point.size() == 2:
			var candidate := Vector2(float(point[0]), float(point[1]))
			if _terrain.is_walkable(_terrain.world_to_grid(candidate)):
				actor.position = candidate
		if String(restore.get("status", "")) == "aboard":
			_states[id].status = "aboard"
			_states[id].craft_id = String(restore.get("craft_id", ""))
		elif String(restore.get("status", "")) == "sleeping":
			var bed := _find_layout("beds", String(restore.get("bed_id", "")))
			if not bed.is_empty() and not _beds.has(bed.id) and actor.position.distance_to(_world(bed.grid)) < 1.0:
				_states[id].status = "sleeping"
				_states[id].bed_id = String(bed.id)
				_beds[bed.id] = id
	_sim.tick_processed.connect(_on_tick)
	_sim.set_physics_process(true)

func get_unit_registry() -> Node:
	return _registry
func get_terrain_registry() -> Node:
	return _terrain
func get_simulation_root() -> Node:
	return _sim
func get_actor(id: String) -> Node2D:
	return _registry.get_unit(id) if _registry != null else null
func get_snapshot() -> Dictionary:
	var units: Array = []
	for id in _states:
		var entry: Dictionary = _states[id].duplicate(true)
		entry.world_position = get_actor(id).position
		if not _unit_is_home(String(id)): entry.status="away"
		units.append(entry)
	return {"units":units,"layout":_layout,"bed_occupants":_beds.duplicate(),"runtime_authority":"SimulationRoot"}
func export_state() -> Dictionary:
	var units: Dictionary = {}
	for id in _states:
		var state: Dictionary = _states[id]
		var pos := get_actor(id).position
		# Midwalk saves resume safely at actual position without stale commands.
		units[id] = {"position":[pos.x,pos.y],"status":state.status if state.status in ["sleeping","aboard"] else "outside","craft_id":state.craft_id if state.status == "aboard" else "","bed_id":state.bed_id if state.status == "sleeping" else "","auto_rest_enabled":bool(state.get("auto_rest_enabled",true)),"rest_automatic":bool(state.get("rest_automatic",false))}
	return {"version":1,"units":units}
func is_pilot_aboard(craft_id: String) -> bool:
	var id := String(_screen.call("_get_assigned_pilot_id", craft_id))
	return _states.has(id) and _states[id].status == "aboard" and _states[id].craft_id == craft_id
func request_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
	return _sim.request_base_personnel_command(operation, payload)
func apply_operation(operation: String, payload: Dictionary) -> Dictionary:
	var id := String(payload.get("unit_id", ""))
	var craft := String(payload.get("craft_id", ""))
	if operation=="base_auto_rest":
		if not _states.has(id) or typeof(payload.get("enabled"))!=TYPE_BOOL: return _reject("invalid_rest_setting","Person und Schalterzustand erforderlich")
		_states[id].auto_rest_enabled=bool(payload.enabled)
		if not payload.enabled and _unit_is_home(id) and (bool(_states[id].get("rest_automatic",false)) or bool(Dictionary(_states[id].action).get("automatic",false))): _cancel(id)
		state_changed.emit()
		return {"ok":true,"message":"Automatisches Ruhen eingeschaltet" if payload.enabled else "Automatisches Ruhen ausgeschaltet"}
	if not _at_home() or (_states.has(id) and not _unit_is_home(id)): return _reject("away_from_base","Person ist nicht an der Basis")
	if operation == "base_unboard" and bool(payload.get("whole_fireteam", false)):
		var result: Dictionary = _reject("not_aboard", "Trupp ist nicht an Bord")
		for member in _screen.call("_get_member_unit_ids_for_fireteam", String(payload.get("fireteam_id", "ft1"))):
			if _states.has(member) and _states[member].status == "aboard":
				result = _unboard(String(member), craft, payload)
		return result
	if operation == "base_board" and (id.is_empty() or bool(payload.get("whole_fireteam", false))):
		return _board_team(craft, payload)
	if not _states.has(id):
		return _reject("unknown_unit", "Person nicht verfuegbar")
	var state: Dictionary = _states[id]
	if operation == "base_wake":
		if state.status != "sleeping":
			return _reject("not_sleeping", "Person schlaeft nicht")
		_cancel(id)
		return {"ok":true}
	if state.status == "sleeping" and operation not in ["base_move","base_board","base_terminal","base_cancel"]:
		return _reject("unit_sleeping", "Person zuerst aufwecken")
	if operation == "base_unboard":
		return _unboard(id, craft, payload)
	if state.status == "boarding" and _board_groups.has(String(state.craft_id)) and bool(_board_groups[state.craft_id].committed):
		return _reject("boarding_in_progress", "Boarding abschliessen oder aussteigen lassen")
	if state.status == "aboard":
		return _reject("unit_aboard", "Person zuerst aussteigen lassen")
	match operation:
		"base_cancel":
			_cancel(id)
			return {"ok":true}
		"base_move":
			var target: Variant = payload.get("target_position", payload.get("world_position"))
			if typeof(target) != TYPE_VECTOR2:
				return _reject("invalid_target", "Ungueltiges Bewegungsziel")
			return _walk(id, target, {"type":"move"})
		"base_terminal":
			var terminal := _find_layout("terminals", String(payload.get("terminal_id", "")))
			if terminal.is_empty() or not bool(terminal.get("enabled", true)):
				return _reject("unknown_terminal", "Arbeitsplatz nicht verfuegbar")
			return _walk(id, _world(terminal.grid), {"type":"terminal","terminal_id":terminal.id})
		"base_sleep":
			var bed_id := String(payload.get("bed_id", ""))
			if bed_id.is_empty():
				for bed in _layout.get("beds", []):
					if not _beds.has(bed.id):
						bed_id = String(bed.id)
						break
			var bed := _find_layout("beds", bed_id)
			if bed.is_empty():
				return _reject("no_free_bed", "Kein freies Bett")
			if _beds.has(bed_id) and _beds[bed_id] != id:
				return _reject("bed_occupied", "Bett ist belegt oder reserviert")
			var result := _walk(id, _world(bed.grid), {"type":"sleep","bed_id":bed_id})
			if result.ok:
				_beds[bed_id] = id
				state.bed_id = bed_id
			return result
		"base_board":
			if bool(_screen.call("_operations_craft_busy", craft)) or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft)).is_empty():
				return _reject("craft_busy", "Schiff nicht verfuegbar")
			if craft.is_empty():
				return _reject("unknown_craft", "Schiff auswaehlen")
			if String(_screen.call("_get_assigned_pilot_id", craft)) != id:
				return _board_team(craft, payload)
			return _walk(id, _pad_world(craft), {"type":"pilot_board","craft_id":craft})
	return _reject("unknown_operation", "Basisaktion nicht verfuegbar")

func _walk(id: String, target: Vector2, action: Dictionary) -> Dictionary:
	var grid: Vector2i = _terrain.world_to_grid(target)
	if not _terrain.is_walkable(grid):
		return _reject("target_blocked", "Ziel ist nicht begehbar")
	var resolved: Vector2 = _terrain.grid_to_world(grid)
	var path: Array = _navigation_graph.call("find_world_path", get_actor(id).position, resolved)
	if (path.is_empty() and get_actor(id).position.distance_to(resolved) > 0.5) or (not path.is_empty() and Vector2(path[-1]).distance_to(resolved) > 0.5):
		return _reject("target_unreachable", "Kein begehbarer Weg zum Ziel")
	_cancel(id)
	_states[id].status = "moving"
	_states[id].action = action.duplicate(true)
	_states[id].action.target = resolved
	_sequence += 1
	_sim.enqueue_command({"type":"move_to_position","unit_id":id,"target_position":resolved,"command_token":"base:%d" % _sequence,"requeue_until_target":true,"path":path})
	state_changed.emit()
	return {"ok":true,"pending":true}
func _cancel(id: String) -> void:
	for craft in _board_groups.keys():
		if Array(_board_groups[craft].ids).has(id):
			var group: Dictionary = _board_groups[craft]
			_board_groups.erase(craft)
			for other in group.ids:
				if other != id and _states[other].status != "aboard":
					_states[other].status = "outside"
					_states[other].action = {}
					_states[other].craft_id = ""
					_sim.call("_discard_pending_move_commands_for_unit", String(other))
	var state: Dictionary = _states[id]
	_beds.erase(String(state.bed_id))
	state.bed_id = ""
	state.action = {}
	state.status = "outside"
	state.craft_id = ""
	state.rest_automatic=false
	state.idle_seconds=0.0
	state.manual_priority_seconds=MANUAL_PRIORITY_SECONDS
	_sim.call("_discard_pending_move_commands_for_unit", id)
	state_changed.emit()
func _unit_is_home(id: String) -> bool:
	if not _states.has(id): return false
	var craft:=String(_states[id].get("craft_id",""))
	if craft.is_empty(): return true
	return String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft,""))=="homebase" and Dictionary(_flow.call("_find_pending_mission_craft_transfer",craft)).is_empty() and String(get_parent().call("get_space_travel_snapshot",craft).get("phase","grounded"))=="grounded"
func _at_home() -> bool:
	for id in _states:
		if _unit_is_home(String(id)): return true
	return false
func _world(raw: Variant) -> Vector2:
	return _terrain.grid_to_world(Vector2i(int(raw[0]),int(raw[1])))
func _find_layout(field: String, id: String) -> Dictionary:
	for value in _layout.get(field, []):
		if String(value.get("id", "")) == id:
			return value
	return {}
func _pad_world(craft_id: String = "") -> Vector2:
	var pads: Array = _layout.get("landing_pads", [])
	var pad_id := String(get_parent().call("_home_pad_for", craft_id)) if not craft_id.is_empty() else ""
	for pad in pads:
		if String(pad.id) == pad_id:
			return _world(pad.get("interaction_grid", pad.grid))
	return _world(pads[0].get("interaction_grid", pads[0].grid)) if not pads.is_empty() else _world(_layout.avatar_spawn_grid)
func _board_team(craft: String, payload: Dictionary) -> Dictionary:
	if not _at_home() or craft.is_empty() or bool(_screen.call("_operations_craft_busy", craft)):
		return _reject("craft_busy", "Schiff nicht an der Basis verfuegbar")
	var team := String(payload.get("fireteam_id", "ft1"))
	if _board_groups.has(craft):
		if String(_board_groups[craft].payload.fireteam_id) == team:
			return {"ok":true,"pending":true,"unchanged":true}
		return _reject("boarding_in_progress", "Dieses Schiff nimmt bereits einen Trupp auf")
	var payload_craft: String = _screen.call("_operations_payload_craft_for_team", team)
	if not payload_craft.is_empty() and payload_craft != craft:
		return _reject("team_aboard_other_craft", "Trupp ist bereits in einem anderen Schiff")
	var members: PackedStringArray = _screen.call("_get_member_unit_ids_for_fireteam", team)
	if members.is_empty():
		return _reject("empty_team", "Trupp ist leer")
	var ids: Array = Array(members)
	var pilot := String(_screen.call("_get_assigned_pilot_id", craft))
	if pilot.is_empty():
		return _reject("pilot_missing", "Pilot zuweisen")
	if not ids.has(pilot):
		ids.append(pilot)
	var previously_aboard: Dictionary = {}
	for id in ids:
		if not _unit_is_home(String(id)): return _reject("unit_away","Person ist nicht an der Basis")
		if _states[id].status == "aboard":
			if _states[id].craft_id != craft:
				return _reject("unit_aboard_other_craft", "Person ist bereits in einem anderen Schiff")
			previously_aboard[id] = _states[id].duplicate(true)
	# Preflight every actor before mutating any movement intent.
	for id in ids:
		if _states[id].status == "aboard" and _states[id].craft_id == craft:
			continue
		var target := _pad_world(craft)
		var path: Array = _navigation_graph.call("find_world_path", get_actor(id).position, target)
		if (path.is_empty() and get_actor(id).position.distance_to(target) > 0.5) or (not path.is_empty() and Vector2(path[-1]).distance_to(target) > 0.5):
			return _reject("target_unreachable", "Kein begehbarer Weg zum Schiff")
	for id in ids:
		if _states[id].status == "aboard" and _states[id].craft_id == craft:
			continue
		var result := _walk(id, _pad_world(craft), {"type":"crew_board","craft_id":craft})
		if not result.ok:
			_board_groups.erase(craft)
			return result
	_board_groups[craft] = {"ids":ids,"payload":{"craft_id":craft,"fireteam_id":team},"committed":payload_craft == craft,"previously_aboard":previously_aboard}
	return {"ok":true,"pending":true}
func _unboard(id: String, craft: String, payload: Dictionary) -> Dictionary:
	var state: Dictionary = _states[id]
	if state.status not in ["aboard","boarding"]:
		return _reject("not_aboard", "Person ist nicht an Bord")
	if craft.is_empty():
		craft = state.craft_id
	if craft != state.craft_id:
		return _reject("craft_mismatch", "Person ist in einem anderen Schiff")
	if bool(_screen.call("_operations_craft_busy", craft)):
		return _reject("craft_busy", "Schiff ist unterwegs")
	if not String(_screen.call("_operations_payload_craft_for_team", String(_screen.call("_get_fireteam_id_for_unit", id)))).is_empty():
		var data: Dictionary = payload.duplicate(true)
		data.fireteam_id = String(_screen.call("_get_fireteam_id_for_unit", id))
		data.craft_id = craft
		var result: Dictionary = _screen.call("_request_operation_from_base", "unboard", data)
		if not result.get("ok", false):
			return result
	var team := String(_screen.call("_get_fireteam_id_for_unit", id))
	var leaving: Array = [id]
	if not team.is_empty() and String(_screen.call("_get_assigned_pilot_id", craft)) != id:
		leaving = Array(_screen.call("_get_member_unit_ids_for_fireteam", team))
	for member in leaving:
		if _states.has(member):
			_cancel(String(member))
			get_actor(String(member)).position = _pad_world(craft)
	_board_groups.erase(craft)
	return {"ok":true}
func _on_tick(_tick: int) -> void:
	_rest_elapsed+=maxf(float(_sim.call("get_last_tick_delta")),0.0)
	for id in _states:
		if not _unit_is_home(String(id)): continue
		var state: Dictionary = _states[id]
		if state.status != "moving":
			continue
		var action: Dictionary = state.action
		if get_actor(id).position.distance_to(action.target) > 0.5:
			continue
		state.status = "outside"
		state.action = {}
		match String(action.type):
			"sleep":
				state.status = "sleeping"
				state.rest_automatic=bool(action.get("automatic",false))
			"terminal":
				terminal_ready.emit(id, String(action.terminal_id))
			"pilot_board":
				state.status = "aboard"
				state.craft_id = action.craft_id
			"crew_board":
				state.status = "boarding"
				state.craft_id = action.craft_id
		state_changed.emit()
	# Only two base actors; owner polling throttled, no SceneTree search.
	_poll_seconds += maxf(float(_sim.call("get_last_tick_delta")),0.0)
	if _poll_seconds < 0.2:
		return
	_poll_seconds = 0.0
	advance_automatic_rest(_rest_elapsed)
	_rest_elapsed=0.0
	for craft in _board_groups.keys():
		var group: Dictionary = _board_groups[craft]
		var arrived := true
		for id in group.ids:
			arrived = arrived and _states[id].status in ["boarding","aboard"] and _states[id].craft_id == craft
		if not arrived:
			continue
		if not group.committed:
			_committing_transport = true
			var result: Dictionary = _screen.call("_request_operation_from_base", "board", group.payload)
			_committing_transport = false
			if not result.get("ok", false):
				_board_groups.erase(craft)
				for id in group.ids:
					if Dictionary(group.get("previously_aboard", {})).has(id):
						_states[id] = group.previously_aboard[id]
					else:
						_cancel(id)
					_states[id].last_result = result
				continue
			group.committed = true
		var teams := PackedStringArray([String(group.payload.fireteam_id)])
		if bool(_screen.call("_are_homebase_payload_fireteams_boarded", teams)):
			for id in group.ids:
				_states[id].status = "aboard"
				_states[id].craft_id = craft
			_board_groups.erase(craft)
			state_changed.emit()
func _reject(reason: String, message: String) -> Dictionary:
	return {"ok":false,"reason":reason,"message":message}

func validate_operation(operation: String, payload: Dictionary) -> Dictionary:
	if operation == "board" and _committing_transport:
		return {"ok":true}
	var id := String(payload.get("unit_id", ""))
	if _states.has(id) and operation in ["assign","remove","loadout","pilot","board","start"]:
		var state: Dictionary = _states[id]
		if state.status == "sleeping" or (state.status=="moving" and String(Dictionary(state.action).get("type",""))=="sleep"): return {"ok":true}
		if state.status in ["moving","boarding"]:
			return _reject("base_action_in_progress", "Basisaktion zuerst abschliessen oder abbrechen")
	return {"ok":true}

func claim_manual_control(id: String) -> void:
	if not _states.has(id) or not _unit_is_home(id): return
	var state: Dictionary=_states[id]
	if state.status=="sleeping" or (state.status=="moving" and String(Dictionary(state.action).get("type",""))=="sleep"): _cancel(id)
	state.idle_seconds=0.0; state.manual_priority_seconds=MANUAL_PRIORITY_SECONDS

func advance_automatic_rest(delta: float) -> void:
	if not is_finite(delta) or delta<=0.0: return
	for id in _states:
		var state: Dictionary=_states[id]
		if not _unit_is_home(String(id)) or not bool(state.get("auto_rest_enabled",true)) or state.status!="outside" or not Dictionary(state.action).is_empty(): continue
		var priority: float=float(state.get("manual_priority_seconds",0.0))
		if priority>0.0:
			state.manual_priority_seconds=maxf(priority-delta,0.0)
			continue
		state.idle_seconds=float(state.get("idle_seconds",0.0))+delta
		if state.idle_seconds<AUTOMATIC_REST_IDLE_SECONDS: continue
		for bed: Dictionary in Array(_layout.get("beds",[])):
			if _beds.has(bed.id): continue
			var result:=_walk(String(id),_world(bed.grid),{"type":"sleep","bed_id":String(bed.id),"automatic":true})
			if bool(result.get("ok",false)):
				_beds[bed.id]=id; state.bed_id=String(bed.id); state.rest_automatic=true
				break
