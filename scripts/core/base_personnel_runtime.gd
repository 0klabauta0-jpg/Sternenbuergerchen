extends Node
## SimulationRoot-bound owner of base positions and intentions only.
## Transport membership, pilot assignment, equipment and medical state stay
## with the existing owners; this owner never creates a transport payload.
signal terminal_ready(unit_id: String, terminal_id: String)
signal state_changed
const ACTOR = preload("res://scripts/core/base_personnel_actor.gd")
const HEX_ADMISSION=preload("res://scripts/mission/hex_ground_admission.gd")
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
var _source_layout: Dictionary = {}
var _building_blockers: Dictionary = {}
var _hex_required:=false
var _hex_admission_waiting:=false
const BUILDING_BOUNDS := {
	"habitat": Rect2(7.0, 2.0, 10.0, 6.3),
	"workshop": Rect2(22.0, 2.0, 11.0, 6.5),
}
const CAPACITY_LAYOUT = preload("res://scripts/meta/base_capacity_layout.gd")

func configure(flow: Node, screen: Node, simulation: Node, checkpoint: Dictionary = {}) -> void:
	_flow = flow
	_screen = screen
	_sim = simulation
	var navigation = load(NAV_PATH)
	var base_path := "res://maps/campaign_intro_base.json"
	var map_data = navigation.load_map(base_path)
	_layout = navigation.layout(base_path)
	_source_layout = _layout.duplicate(true)
	_terrain = load("res://scripts/terrain/terrain_registry.gd").new()
	_terrain.name = "BaseTerrainRegistry"
	_sim.get_parent().add_child(_terrain)
	var tile_size: Dictionary = map_data.get_tile_size()
	_terrain.configure_iso_grid(map_data.get_grid_origin(), tile_size.half_width, tile_size.half_height, map_data.get_grid_topology())
	for tile in map_data.get_tiles():
		_terrain.register_tile(tile)
	if bool(Dictionary(_flow.get_meta("skirmish_infrastructure", {})).get("paid", false)):
		for building: String in BUILDING_BOUNDS:
			_building_blockers[building] = []
		for tile in _terrain.get_all_tiles():
			if tile.walkable: continue
			var plane: Vector3 = navigation.plane_at_grid(tile.grid_position)
			for building: String in BUILDING_BOUNDS:
				if BUILDING_BOUNDS[building].has_point(Vector2(plane.x, plane.z)):
					_building_blockers[building].append({"tile": tile, "blocks_los": tile.blocks_los,
						"cover_value": tile.cover_value, "object_height": tile.object_height})
					if int(_flow.get_meta("skirmish_infrastructure").get(building, 0)) == 0:
						tile.walkable = true
						tile.blocks_los = false
						tile.cover_value = 0.0
						tile.object_height = 0
		_terrain.notify_tile_data_changed()
	_navigation_graph = navigation.new()
	_navigation_graph.call("configure_graph", _terrain)
	_refresh_capacity()
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
		actor.configure_equipment_source(_sim)
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
	_hex_required=not String(map_data.get_tactical_grid_rules()).is_empty()
	var configured:Dictionary=_sim.configure_hex_ground_runtime(map_data,_terrain)
	if configured.ok:_sync_hex_ground_presence()
	_sim.tick_processed.connect(_on_tick)
	_sim.set_physics_process(true)

func _refresh_capacity() -> void:
	if _flow == null or _terrain == null or _navigation_graph == null: return
	_layout = CAPACITY_LAYOUT.expand(_source_layout, _terrain, _navigation_graph, Array(_flow.get("_all_team_units")).size(), Dictionary(_flow.get_meta("skirmish_infrastructure", {})))
	if _flow.call("is_campaign_start") and Array(_layout.get("landing_pads",[])).size()>1:
		_layout.landing_pads[1]["built"]=bool(_flow.get_meta("campaign_pad2_built",false))

func sync_roster() -> void:
	# Recruitment does not recreate existing actors, cancel paths or wake sleepers.
	_refresh_capacity()
	for profile: Dictionary in Array(_flow.get("_all_team_units")):
		var id := String(profile.get("unit_id", ""))
		if id.is_empty(): continue
		if _states.has(id):
			_states[id].name = String(profile.get("display_name", id))
			_states[id].role = String(profile.get("role_name", ""))
			continue
		var actor: Node2D = ACTOR.new()
		actor.unit_id = id
		actor.configure_equipment_source(_sim)
		actor.name = id.validate_node_name()
		add_child(actor)
		var raw: Array = _layout.get("avatar_spawn_grid", [36,40])
		var spawn := Vector2i(int(raw[0]),int(raw[1]))
		var index := _states.size()
		var target := spawn + Vector2i((index % 8) * 2, (index / 8) * 2)
		actor.position = _terrain.grid_to_world(target if _terrain.is_walkable(target) else spawn)
		_registry.register_unit(id, actor)
		_sim.register_known_unit(id, actor)
		_states[id] = {"unit_id":id,"name":String(profile.get("display_name",id)),"role":String(profile.get("role_name","")),"status":"outside","craft_id":"","bed_id":"","action":{},"last_result":{}}
	_sync_hex_ground_presence()
	state_changed.emit()


func _requires_hex_ground()->bool:
	return _hex_required or _sim.is_hex_ground_runtime_required()


## Called only after existing roster/restore metadata is complete. Aboard and
## remote identities remain transport people and never receive a base cell.
func _sync_hex_ground_presence()->Dictionary:
	_hex_admission_waiting=false
	if not _requires_hex_ground():return {"ok":true,"legacy":true}
	if not _sim.is_hex_ground_runtime_active():return {"ok":false,"reason":"hex_ground_unavailable"}
	var candidates:Array[Dictionary]=[]
	for id in _states:
		var state:Dictionary=_states[id]
		if String(state.status)=="aboard" or not _unit_is_home(String(id)):continue
		if not _sim.get_hex_unit_state(String(id)).is_empty():continue
		var actor:Node2D=get_actor(String(id))
		if not is_instance_valid(actor) or not actor.global_position.is_finite():return {"ok":false,"reason":"invalid_base_position"}
		candidates.append({"unit_id":String(id),"grid":_terrain.world_to_grid(actor.global_position)})
	if candidates.is_empty():return {"ok":true}
	_hex_admission_waiting=true
	var plan:Dictionary=HEX_ADMISSION.new().plan_anchored_group(candidates,_terrain,_sim.get_hex_ground_planning_snapshot())
	if not plan.ok:return plan
	var placements:Array[Dictionary]=[]
	placements.assign(plan.placements)
	var admitted:Dictionary=_sim.admit_base_ground_people(self,placements)
	if not admitted.ok:return admitted
	_hex_admission_waiting=false
	for placement in placements:
		var state:Dictionary=_states[placement.unit_id]
		if String(state.status)=="sleeping":
			var bed:Dictionary=_find_layout("beds",String(state.bed_id))
			if bed.is_empty() or _terrain.world_to_grid(_world(bed.grid))!=placement.grid:
				_beds.erase(String(state.bed_id))
				state.bed_id=""
				state.status="outside"
				state.rest_automatic=false
	return admitted


func validate_dismiss(unit_id: String) -> Dictionary:
	if not _states.has(unit_id) or not _unit_is_home(unit_id):
		return _reject("person_away", "Person muss an der Basis sein")
	if String(_states[unit_id].status) in ["aboard", "boarding"]:
		return _reject("person_aboard", "Person zuerst aussteigen lassen")
	return {"ok": true}


func remove_person(unit_id: String) -> void:
	_cancel(unit_id)
	var actor := get_actor(unit_id)
	_states.erase(unit_id)
	_registry.unregister_unit(unit_id)
	_sim.unregister_known_unit(unit_id)
	actor.queue_free()
	state_changed.emit()


func build_infrastructure(item_id: String, infrastructure: Dictionary) -> Dictionary:
	if BUILDING_BOUNDS.has(item_id):
		for id: String in _states:
			var plane: Vector3 = load(NAV_PATH).plane_at_grid(_terrain.world_to_grid(get_actor(id).position))
			if _unit_is_home(id) and BUILDING_BOUNDS[item_id].has_point(Vector2(plane.x, plane.z)):
				return _reject("construction_occupied", "Personen zuerst aus dem Bauplatz bewegen")
		for command: Dictionary in _sim.command_queue:
			for point: Vector2 in command.get("path", []):
				var plane: Vector3 = load(NAV_PATH).plane_at_grid(_terrain.world_to_grid(point))
				if BUILDING_BOUNDS[item_id].has_point(Vector2(plane.x, plane.z)):
					return _reject("construction_path_occupied", "Den laufenden Weg über den Bauplatz zuerst abschließen oder abbrechen")
	_flow.set_meta("skirmish_infrastructure", infrastructure.duplicate(true))
	if _building_blockers.has(item_id):
		var changed: Array = []
		for original: Dictionary in _building_blockers[item_id]:
			var tile = original.tile
			tile.walkable = false
			tile.blocks_los = bool(original.blocks_los)
			tile.cover_value = float(original.cover_value)
			tile.object_height = int(original.object_height)
			changed.append(tile.grid_position)
		_terrain.notify_tile_data_changed(changed)
	_refresh_capacity()
	state_changed.emit()
	return {"ok": true, "message": "Bauvorhaben fertiggestellt"}

func mark_recruit_remote(unit_id: String, craft_id: String) -> Dictionary:
	# Trusted recruitment lifecycle: the local encounter/trader has already
	# verified pickup. Represent arrival aboard the actual ship, not a second
	# visible person teleported to the home pad; no fireteam payload is invented.
	if not _states.has(unit_id) or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty():
		return _reject("invalid_recruit_craft", "Rekrut oder Aufnahmeschiff fehlt")
	_cancel(unit_id)
	if _requires_hex_ground():
		var released:Dictionary=_sim.release_base_ground_people(self,PackedStringArray([unit_id]),"remote_transport_binding")
		if not released.ok:return released
	_states[unit_id].status = "aboard"
	_states[unit_id].craft_id = craft_id
	state_changed.emit()
	return {"ok":true,"unit_id":unit_id,"craft_id":craft_id}

func validate_remote_craft_handoff(unit_ids: PackedStringArray, source_craft_id: String, target_craft_id: String) -> Dictionary:
	# This changes only the existing remote transport binding. The local mission
	# owns actual deployed/embarked presence and validates it before committing.
	if source_craft_id.is_empty() or source_craft_id == target_craft_id or unit_ids.is_empty() or _flow == null:
		return _reject("invalid_transport_handoff", "Besatzungswechsel ist ungueltig")
	var locations: Dictionary = _flow.get("_aircraft_location_by_craft")
	for craft_id in [source_craft_id,target_craft_id]:
		if String(locations.get(craft_id, "")) != "mission" or Dictionary(_flow.call("_find_homebase_aircraft_definition", craft_id)).is_empty():
			return _reject("invalid_transport_handoff", "Beide Schiffe muessen am entfernten Ort anwesend sein")
	var unique := {}
	for id in unit_ids:
		if unique.has(id) or not _states.has(id) or String(_states[id].get("status", "")) != "aboard" or String(_states[id].get("craft_id", "")) != source_craft_id:
			return _reject("invalid_transport_membership", "Person ist nicht diesem Ausflugsschiff zugeordnet")
		unique[id] = true
	return {"ok":true}

func commit_remote_craft_handoff(unit_ids: PackedStringArray, source_craft_id: String, target_craft_id: String) -> Dictionary:
	var checked := validate_remote_craft_handoff(unit_ids, source_craft_id, target_craft_id)
	if not checked.get("ok", false): return checked
	# Synchronous, no signals/await or fallible work after the validated loop.
	for id in unit_ids: _states[id].craft_id = target_craft_id
	return {"ok":true}

func finalize_remote_craft_handoff() -> void:
	state_changed.emit()

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
func get_payload_presence(craft_id: String) -> Dictionary:
	var members:Dictionary={}
	for team in _screen.call("_get_homebase_direct_payload_fireteam_ids_for_craft_raw",craft_id):
		for id in _screen.call("_get_member_unit_ids_for_fireteam",String(team)):members[String(id)]=true
	var aboard:=0
	for id in members:
		if _states.has(id) and String(_states[id].status)=="aboard" and String(_states[id].craft_id)==craft_id:aboard+=1
	return {"member_count":members.size(),"aboard_count":aboard,"all_aboard":not members.is_empty() and aboard==members.size()}

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
	if operation == "base_board" and _board_groups.has(craft) and Array(_board_groups[craft].ids).has(id):
		# A repeated pilot/crew click preserves the group's accepted walk.
		return {"ok": true, "pending": state.status != "aboard", "unchanged": true}
	if operation == "base_rename":
		var next_name:=String(payload.get("display_name","")).strip_edges()
		if next_name.is_empty() or next_name.length()>48 or next_name.contains("\n") or next_name.contains("\r"): return _reject("invalid_name","Name muss 1 bis 48 Zeichen lang sein")
		var renamed: Dictionary=_flow.call("rename_campaign_person",id,next_name)
		if bool(renamed.get("ok",false)): state.name=next_name; state_changed.emit()
		return renamed
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
	if not target.is_finite():return _reject("invalid_target", "Ungueltiges Bewegungsziel")
	if _requires_hex_ground():return _walk_hex(id,target,action)
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


func _walk_hex(id:String,target:Vector2,action:Dictionary)->Dictionary:
	var token:String="base:%d"%(_sequence+1)
	var checked:Dictionary=_sim.call("_validate_base_ground_move",self,id,target,token)
	if not checked.ok:return checked
	var resolved:Vector2=_terrain.grid_to_world(_terrain.world_to_grid(target))
	_cancel(id)
	var accepted:Dictionary=_sim.request_base_ground_move(self,id,resolved,token)
	if not accepted.ok:return accepted
	_sequence+=1
	_states[id].status="moving"
	_states[id].action=action.duplicate(true)
	_states[id].action.target=resolved
	_states[id].action.command_token=token
	state_changed.emit()
	return {"ok":true,"pending":true}

func _cancel(id: String,publish_state:bool=true) -> void:
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
	if publish_state:state_changed.emit()
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
	var walking:=PackedStringArray()
	for id in ids:
		if not _unit_is_home(String(id)): return _reject("unit_away","Person ist nicht an der Basis")
		if _states[id].status == "aboard":
			if _states[id].craft_id != craft:
				return _reject("unit_aboard_other_craft", "Person ist bereits in einem anderen Schiff")
			previously_aboard[id] = _states[id].duplicate(true)
		else:walking.append(String(id))
	var approaches:Dictionary={}
	if _requires_hex_ground() and not walking.is_empty():
		var planned:Dictionary=_sim.plan_base_ground_approaches(self,walking,_terrain.world_to_grid(_pad_world(craft)))
		if not planned.ok:return planned
		for entry in planned.placements:approaches[entry.unit_id]=_terrain.grid_to_world(entry.grid)
	# Preflight every actor before mutating any movement intent.
	for id in ids:
		if _states[id].status == "aboard" and _states[id].craft_id == craft:
			continue
		var target := _pad_world(craft)
		if _requires_hex_ground():
			target=approaches[String(id)]
			var checked:Dictionary=_sim.call("_validate_base_ground_move",self,String(id),target,"base_board_preflight")
			if not checked.ok:return checked
		else:
			var path: Array = _navigation_graph.call("find_world_path", get_actor(id).position, target)
			if (path.is_empty() and get_actor(id).position.distance_to(target) > 0.5) or (not path.is_empty() and Vector2(path[-1]).distance_to(target) > 0.5):
				return _reject("target_unreachable", "Kein begehbarer Weg zum Schiff")
	for id in ids:
		if _states[id].status == "aboard" and _states[id].craft_id == craft:
			continue
		var result := _walk(id, approaches.get(String(id),_pad_world(craft)), {"type":"crew_board","craft_id":craft})
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
	if _requires_hex_ground():return _unboard_hex(id,craft,payload)
	if String(_screen.call("_get_assigned_pilot_id", craft)) != id and not String(_screen.call("_operations_payload_craft_for_team", String(_screen.call("_get_fireteam_id_for_unit", id)))).is_empty():
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


func _unboard_hex(id:String,craft:String,payload:Dictionary)->Dictionary:
	if not _sim.is_hex_ground_runtime_active():return _reject("hex_ground_unavailable","Bodenplaetze sind noch nicht bereit")
	var owner_lifetime:WeakRef=weakref(self)
	var screen_lifetime:WeakRef=weakref(_screen)
	var team:String=String(_screen.call("_get_fireteam_id_for_unit",id))
	var pilot:String=String(_screen.call("_get_assigned_pilot_id",craft))
	var whole:bool=bool(payload.get("whole_fireteam",false)) and not team.is_empty()
	var members:PackedStringArray=PackedStringArray([id]) if team.is_empty() or (pilot==id and not whole) else _screen.call("_get_member_unit_ids_for_fireteam",team)
	var leaving:=PackedStringArray()
	for member in members:
		if _states.has(member) and String(_states[member].get("craft_id",""))==craft and String(_states[member].status) in ["aboard","boarding"]:leaving.append(member)
	if not leaving.has(id):return _reject("craft_mismatch","Person ist nicht an Bord dieses Heimschiffs")
	var aboard:=PackedStringArray()
	for member in leaving:
		if not _states.has(member) or String(_states[member].craft_id)!=craft or not _unit_is_home(member):return _reject("craft_mismatch","Person ist nicht an Bord dieses Heimschiffs")
		var physical:bool=not _sim.get_hex_unit_state(member).is_empty()
		if String(_states[member].status)=="aboard":
			if physical:return _reject("inconsistent_base_ground_presence","Bordperson hat noch eine Bodenbelegung")
			aboard.append(member)
		elif String(_states[member].status)!="boarding" or not physical:return _reject("inconsistent_base_ground_presence","Person ist nicht am Schiff verfuegbar")
	var admission_id:=""
	var payload_prepared:RefCounted
	var payload_validation:Dictionary={}
	if not aboard.is_empty():
		var ticket:Dictionary=_sim.prepare_base_ground_deployment(self,aboard,_terrain.world_to_grid(_pad_world(craft)))
		if not ticket.ok:return ticket
		admission_id=String(ticket.admission_id)
	if (pilot!=id or whole) and not String(_screen.call("_operations_payload_craft_for_team",team)).is_empty():
		for method in ["prepare_base_unboard","validate_prepared_base_unboard","_publish_prepared_base_unboard","finalize_base_unboard"]:
			if not _screen.has_method(method):
				if not admission_id.is_empty():_sim.cancel_hex_ground_deployment(admission_id,"base_transport_prepare_unavailable")
				return _reject("base_transport_prepare_unavailable","Aussteigen ist noch nicht vorbereitet")
		var result:Dictionary=_screen.call("prepare_base_unboard",craft,team)
		if not result.get("ok",false):
			if not admission_id.is_empty():_sim.cancel_hex_ground_deployment(admission_id,"base_transport_denied")
			return result
		payload_prepared=result.prepared
		payload_validation=_screen.call("validate_prepared_base_unboard",payload_prepared)
		if not payload_validation.ok:
			if not admission_id.is_empty():_sim.cancel_hex_ground_deployment(admission_id,"base_transport_changed")
			return payload_validation
	if not admission_id.is_empty():
		var committed:Dictionary=_sim.commit_base_ground_deployment(self,admission_id,false)
		if not committed.ok:
			_sim.cancel_hex_ground_deployment(admission_id,"base_deployment_changed")
			return committed
	# No fallible owner work or public callbacks between these model tails. The
	# Screen prepared contract publishes only already-validated value assignments.
	if payload_prepared!=null:_screen.call("_publish_prepared_base_unboard",payload_prepared,payload_validation)
	for member in leaving:_cancel(member,false)
	_board_groups.erase(craft)
	_sim.call("_publish_base_ground_actors",leaving)
	var publishing_owner:Node=owner_lifetime.get_ref()
	if is_instance_valid(publishing_owner) and not publishing_owner.is_queued_for_deletion():publishing_owner.emit_signal("state_changed")
	# Public observers may free/replace either projection owner. The model is
	# already committed; never send this historical handle to a replacement.
	var live_owner:Node=owner_lifetime.get_ref()
	var live_screen:Node=screen_lifetime.get_ref()
	if payload_prepared!=null and is_instance_valid(live_owner) and not live_owner.is_queued_for_deletion() and is_instance_valid(live_screen) and not live_screen.is_queued_for_deletion() and live_owner.get("_screen")==live_screen:
		live_screen.call("finalize_base_unboard",payload_prepared)
	return {"ok":true}


func _on_tick(_tick: int) -> void:
	_rest_elapsed+=maxf(float(_sim.call("get_last_tick_delta")),0.0)
	for id in _states:
		if not _unit_is_home(String(id)): continue
		var state: Dictionary = _states[id]
		if state.status != "moving":
			continue
		var action: Dictionary = state.action
		if _requires_hex_ground():
			var readout:Dictionary=_sim.get_hex_movement_readout(String(id))
			var failed_navigation:bool=readout.get("status","")=="blocked" and readout.get("reason","")=="unreachable_target"
			if readout.get("source_command_id","")==action.get("command_token","") and (readout.get("status","")=="canceled" or failed_navigation):
				_cancel(String(id))
				state.last_result={"ok":false,"reason":String(readout.get("reason","base_move_aborted"))}
				continue
			if not _sim.has_hex_position_arrived(String(id),action.target,String(action.get("command_token",""))):continue
		elif get_actor(id).position.distance_to(action.target) > 0.5:continue
		state.status = "outside"
		state.action = {}
		match String(action.type):
			"sleep":
				state.status = "sleeping"
				state.rest_automatic=bool(action.get("automatic",false))
			"terminal":
				terminal_ready.emit(id, String(action.terminal_id))
			"pilot_board":
				if _requires_hex_ground() and not _sim.release_base_ground_people(self,PackedStringArray([String(id)]),"embarked").ok:continue
				state.status = "aboard"
				state.craft_id = action.craft_id
			"crew_board":
				state.status = "boarding"
				state.craft_id = action.craft_id
		state_changed.emit()
	# Known base actors; owner polling throttled, no SceneTree search.
	_poll_seconds += maxf(float(_sim.call("get_last_tick_delta")),0.0)
	if _poll_seconds < 0.2:
		return
	_poll_seconds = 0.0
	if _hex_admission_waiting:_sync_hex_ground_presence()
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
			if _requires_hex_ground():
				var physical:=PackedStringArray()
				for id in group.ids:
					if not _sim.get_hex_unit_state(String(id)).is_empty():physical.append(String(id))
				if not _sim.release_base_ground_people(self,physical,"embarked").ok:continue
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


func build_campaign_landing_pad(count: int) -> Dictionary:
	if _flow == null or not _flow.call("is_campaign_start") or count < 3 or count > 6:
		return _reject("invalid_pad_construction", "Kampagnenbauplatz ungueltig")
	var infrastructure := {"pads":count}
	var candidate: Dictionary = CAPACITY_LAYOUT.expand(_source_layout, _terrain, _navigation_graph, Array(_flow.get("_all_team_units")).size(), infrastructure)
	if Array(candidate.get("landing_pads", [])).size() != count:
		return _reject("pad_site_blocked", "Heimatbauplatz ist nicht begehbar angebunden")
	var pad: Dictionary = candidate.landing_pads[count - 1]
	var plane: Array = pad.plane
	var bounds := Rect2(Vector2(float(plane[0])-4.5, float(plane[1])-3.5), Vector2(9,7))
	var center := Vector2i(int(pad.grid[0]), int(pad.grid[1]))
	for row in range(center.y - 18, center.y + 19):
		for column in range(center.x - 28, center.x + 29):
			var grid := Vector2i(column, row)
			var cell_plane: Vector3 = load(NAV_PATH).plane_at_grid(grid)
			if bounds.has_point(Vector2(cell_plane.x, cell_plane.z)) and not _terrain.is_walkable(grid): return _reject("pad_site_blocked", "Heimatlandeplatz braucht eine vollstaendig freie Bodenflaeche")
	for id: String in _states:
		if not _unit_is_home(id): continue
		var actor_plane: Vector3 = load(NAV_PATH).plane_at_grid(_terrain.world_to_grid(get_actor(id).position))
		if bounds.has_point(Vector2(actor_plane.x, actor_plane.z)): return _reject("construction_occupied", "Personen zuerst vom Landeplatzbauplatz bewegen")
	for command: Dictionary in _sim.command_queue:
		for point: Vector2 in command.get("path", []):
			var path_plane: Vector3 = load(NAV_PATH).plane_at_grid(_terrain.world_to_grid(point))
			if bounds.has_point(Vector2(path_plane.x, path_plane.z)): return _reject("construction_path_occupied", "Laufenden Weg ueber den Bauplatz abschliessen")
	return build_infrastructure("landing_pad", infrastructure)


# AP7 host checkpoint V2. Existing export_state/configure remain legacy V1.
class PreparedBaseCheckpoint extends RefCounted:
	pass
var _checkpoint_prepared:Dictionary={}
var _checkpoint_epoch:=0

func export_checkpoint_state()->Dictionary:
	var issue:=_checkpoint_issue()
	if not issue.is_empty():return _checkpoint_reject(issue)
	var ground=_sim._hex_ground_runtime
	var movement:Dictionary=_sim._hex_movement_runtime.export_state()
	if movement.get("schema")!="hex_movement_v1":return _checkpoint_reject("base_checkpoint_movement_unavailable")
	var units:Dictionary={};var ids:Array=_states.keys();ids.sort()
	for id in ids:
		var current:Dictionary=_states[id]
		var action:Dictionary=Dictionary(current.action).duplicate(true)
		if not action.is_empty():
			if typeof(action.get("target"))!=TYPE_VECTOR2:return _checkpoint_reject("base_checkpoint_invalid_action")
			action.target=[action.target.x,action.target.y]
			if action.get("type")=="sleep":action.automatic=bool(action.get("automatic",false))
		units[id]={"status":current.status,"craft_id":current.craft_id,"bed_id":current.bed_id,"action":action,"auto_rest_enabled":current.get("auto_rest_enabled",true),"rest_automatic":current.get("rest_automatic",false),"idle_seconds":current.get("idle_seconds",0.0),"manual_priority_seconds":current.get("manual_priority_seconds",0.0)}
	var snapshot:Dictionary=ground.build_planning_snapshot()
	var state:Dictionary={"version":2,"map_id":snapshot.map_id,"topology":_terrain.get_grid_topology(),"grid_frame":_checkpoint_grid_frame(),"sequence":_sequence,"poll_seconds":_poll_seconds,"rest_elapsed":_rest_elapsed,"units":units}
	var checked:Dictionary=_checkpoint_candidate(state,ground,movement)
	if not checked.ok:return checked
	if checked.beds!=_beds:return _checkpoint_reject("base_checkpoint_beds_inconsistent")
	return state

func prepare_restore_state(state:Dictionary,ground_prepared:RefCounted,movement_prepared:RefCounted)->Dictionary:
	var issue:=_checkpoint_issue()
	if not issue.is_empty():return _checkpoint_reject(issue)
	var target=_sim._hex_ground_runtime.get_prepared_restore_ground(ground_prepared)
	var movement:Dictionary=_sim._hex_movement_runtime.get_prepared_restore_state(movement_prepared)
	if target==null or movement.is_empty():return _checkpoint_reject("base_checkpoint_prepared_context")
	var checked:Dictionary=_checkpoint_candidate(state,target,movement)
	if not checked.ok:return checked
	for key in _checkpoint_prepared.keys():
		var old:Dictionary=_checkpoint_prepared[key]
		if old.handle.get_ref()==null or old.epoch!=_checkpoint_epoch:_checkpoint_prepared.erase(key)
	if _checkpoint_prepared.size()>=32:return _checkpoint_reject("base_checkpoint_prepare_capacity")
	var handle:=PreparedBaseCheckpoint.new()
	var patch:Dictionary={"states":checked.states,"beds":checked.beds,"sequence":int(state.sequence),"poll_seconds":float(state.poll_seconds),"rest_elapsed":float(state.rest_elapsed)}
	_checkpoint_prepared[handle.get_instance_id()]={"handle":weakref(handle),"epoch":_checkpoint_epoch,"phase":"prepared","source":_checkpoint_binding(),"ground_prepared":ground_prepared,"movement_prepared":movement_prepared,"target":target,"movement":movement,"transport":_checkpoint_transport_context(state),"state":state.duplicate(true),"patch":patch,"post_models":patch.duplicate(true),"context":_sim.get_hex_ground_context_revision(),"sim_id":_sim.get_instance_id(),"registry_id":_registry.get_instance_id(),"terrain_id":_terrain.get_instance_id()}
	return {"ok":true,"prepared":handle}

func validate_prepared_restore(prepared:RefCounted)->Dictionary:
	var record:Dictionary=_checkpoint_record(prepared)
	if record.is_empty():return _checkpoint_reject("unknown_base_checkpoint")
	if record.phase!="prepared" or record.epoch!=_checkpoint_epoch:return _checkpoint_reject("base_checkpoint_consumed")
	var issue:=_checkpoint_issue()
	if not issue.is_empty():return _checkpoint_reject(issue)
	if record.source!=_checkpoint_binding() or record.transport!=_checkpoint_transport_context(record.state):return _checkpoint_reject("base_checkpoint_context_changed")
	var target=_sim._hex_ground_runtime.get_prepared_restore_ground(record.ground_prepared)
	var movement:Dictionary=_sim._hex_movement_runtime.get_prepared_restore_state(record.movement_prepared)
	if target==null or target!=record.target or movement!=record.movement:return _checkpoint_reject("base_checkpoint_prepared_context")
	var checked:Dictionary=_checkpoint_candidate(record.state,target,movement)
	if not checked.ok:return checked
	return {"ok":true,"prepared_id":prepared.get_instance_id()}

# Root validates every participant, then Ground/Movement/Base tails, then projects.
func _publish_prepared_restore(prepared:RefCounted,_validation:Dictionary,target_root_context:int=-1)->Dictionary:
	var record:Dictionary=_checkpoint_prepared[prepared.get_instance_id()]
	_states=record.patch.states
	_beds=record.patch.beds
	_sequence=record.patch.sequence
	_poll_seconds=record.patch.poll_seconds
	_rest_elapsed=record.patch.rest_elapsed
	record.phase="published"
	if target_root_context>=0:record.context=target_root_context
	_checkpoint_epoch+=1
	return {"ok":true}

func finalize_prepared_restore(prepared:RefCounted)->Dictionary:
	var record:Dictionary=_checkpoint_record(prepared)
	if record.is_empty():return _checkpoint_reject("unknown_base_checkpoint")
	if record.phase=="finalized":return {"ok":true,"replayed":true}
	if record.phase!="published":return _checkpoint_reject("base_checkpoint_not_published")
	record.phase="finalized"
	# Actor projection is explicitly SourceRoot-owned and must precede this signal.
	if not _checkpoint_owner_bound() or _flow.get_instance_id()!=record.source.flow_id or _screen.get_instance_id()!=record.source.screen_id or _flow.is_inside_tree()!=record.source.flow_in_tree or _screen.is_inside_tree()!=record.source.screen_in_tree or _sim.get_instance_id()!=record.sim_id or _registry.get_instance_id()!=record.registry_id or _terrain.get_instance_id()!=record.terrain_id or _sim.get_hex_ground_context_revision()!=record.context or _checkpoint_models()!=record.post_models or _checkpoint_actor_ids()!=record.source.actors or record.transport!=_checkpoint_transport_context(record.state):return {"ok":true,"context_changed":true}
	state_changed.emit()
	return {"ok":true,"replayed":false}

func _checkpoint_record(prepared:RefCounted)->Dictionary:
	if prepared==null or not _checkpoint_prepared.has(prepared.get_instance_id()):return {}
	var record:Dictionary=_checkpoint_prepared[prepared.get_instance_id()]
	return record if record.handle.get_ref()==prepared else {}

func _checkpoint_owner_bound()->bool:
	for node in [self,_sim,_registry,_terrain,_flow,_screen]:
		if not is_instance_valid(node) or node.is_queued_for_deletion():return false
	if not is_inside_tree() or not _sim.is_inside_tree() or not _registry.is_inside_tree() or not _terrain.is_inside_tree():return false
	return _sim.get("_base_personnel_owner")==self and get_parent()==_sim.get_parent() and _sim.get_unit_registry()==_registry and _sim.get("_hex_ground_registry")==_terrain and _sim.is_hex_ground_runtime_active()

func _checkpoint_issue()->String:
	if not _checkpoint_owner_bound():return "base_checkpoint_owner_unbound"
	if _states.is_empty() or _states.size()>64:return "base_checkpoint_unit_budget"
	if _committing_transport or not _board_groups.is_empty():return "base_checkpoint_transport_pending"
	if _hex_admission_waiting:return "base_checkpoint_admission_pending"
	var ground_issue:String=_sim._hex_ground_runtime._save_context_issue()
	if not ground_issue.is_empty():return "base_checkpoint_"+ground_issue
	for current in _states.values():
		if typeof(current)!=TYPE_DICTIONARY:return "base_checkpoint_invalid_unit"
		if current.get("status")=="boarding" or Dictionary(current.get("action",{})).get("type") in ["crew_board","pilot_board"]:return "base_checkpoint_transport_pending"
	return ""

func _checkpoint_models()->Dictionary:
	return {"states":_states.duplicate(true),"beds":_beds.duplicate(true),"sequence":_sequence,"poll_seconds":_poll_seconds,"rest_elapsed":_rest_elapsed}

func _checkpoint_live_actor(id:String)->Node2D:
	var actor:Node2D=get_actor(id)
	if not is_instance_valid(actor) or actor.is_queued_for_deletion() or not actor.is_inside_tree() or actor.get_script()!=ACTOR or actor.get_parent()!=self or actor.get_unit_id()!=id or _sim._resolve_known_unit_for_contract(id)!=actor:return null
	return actor

func _checkpoint_actor_ids()->Dictionary:
	var actors:Dictionary={}
	for id in _states:
		var actor:Node2D=_checkpoint_live_actor(id)
		actors[id]=actor.get_instance_id() if actor!=null else 0
	return actors

func _checkpoint_binding()->Dictionary:
	var actors:Dictionary=_checkpoint_actor_ids()
	return {"owner_id":get_instance_id(),"epoch":_checkpoint_epoch,"sim_id":_sim.get_instance_id(),"flow_id":_flow.get_instance_id(),"screen_id":_screen.get_instance_id(),"flow_in_tree":_flow.is_inside_tree(),"screen_in_tree":_screen.is_inside_tree(),"registry_id":_registry.get_instance_id(),"terrain_id":_terrain.get_instance_id(),"context":_sim.get_hex_ground_context_revision(),"ground_revision":_sim._hex_ground_runtime.build_planning_snapshot().revision,"terrain_revision":_terrain.get_revision(),"actors":actors,"layout":_layout.duplicate(true),"models":_checkpoint_models()}

func _checkpoint_grid_frame()->Dictionary:
	var origin:Vector2=_terrain.grid_to_world(Vector2i.ZERO)
	var q:Vector2=_terrain.grid_to_world(Vector2i.RIGHT)-origin
	var r:Vector2=_terrain.grid_to_world(Vector2i.DOWN)-origin
	return {"origin":[origin.x,origin.y],"q":[q.x,q.y],"r":[r.x,r.y]}

func _checkpoint_candidate(state:Dictionary,target,movement:Dictionary)->Dictionary:
	if not _checkpoint_keys(state,["version","map_id","topology","grid_frame","sequence","poll_seconds","rest_elapsed","units"]) or not _checkpoint_int(state.version,2,2):return _checkpoint_reject("base_checkpoint_invalid_version")
	if target==null or target.get_script()!=_sim._hex_ground_runtime.get_script() or target._registry.get_script()!=_terrain.get_script() or target._registry.get_checkpoint_grid_frame()!=_terrain.get_checkpoint_grid_frame():return _checkpoint_reject("base_checkpoint_target_ground")
	var ground:Dictionary=target.build_planning_snapshot()
	if typeof(state.map_id)!=TYPE_STRING or state.map_id!=ground.map_id or state.topology!="hex_axial_v1" or state.topology!=_terrain.get_grid_topology() or movement.get("schema")!="hex_movement_v1" or movement.get("map_id")!=ground.map_id or movement.get("terrain_revision")!=ground.terrain_revision or movement.get("tick")!=ground.current_tick:return _checkpoint_reject("base_checkpoint_map_context")
	if not _checkpoint_keys(state.grid_frame,["origin","q","r"]):return _checkpoint_reject("base_checkpoint_grid_frame")
	for key in ["origin","q","r"]:
		if not _checkpoint_pair(state.grid_frame[key]):return _checkpoint_reject("base_checkpoint_grid_frame")
	var current_frame:Dictionary=_checkpoint_grid_frame()
	for key in ["origin","q","r"]:
		if Vector2(float(state.grid_frame[key][0]),float(state.grid_frame[key][1]))!=Vector2(float(current_frame[key][0]),float(current_frame[key][1])):return _checkpoint_reject("base_checkpoint_grid_frame")
	if not _checkpoint_int(state.sequence,0,1000000000000) or not _checkpoint_number(state.poll_seconds) or not _checkpoint_number(state.rest_elapsed):return _checkpoint_reject("base_checkpoint_invalid_clock")
	if typeof(state.units)!=TYPE_DICTIONARY or state.units.size()!=_states.size() or state.units.size()>64:return _checkpoint_reject("base_checkpoint_unit_set")
	var movement_proof:Dictionary=_sim._hex_movement_runtime._save_validate(movement,target,target._registry)
	if not movement_proof.ok:return _checkpoint_reject("base_checkpoint_movement_target")
	var intents:Dictionary={};var max_sequence:=0
	for intent in movement.accepted_intents:
		intents[intent.unit_id]=intent
		if String(intent.source_command_id).begins_with("base:"):
			var serial:=_checkpoint_token_sequence(intent.source_command_id)
			if serial<0:return _checkpoint_reject("base_checkpoint_invalid_token")
			max_sequence=maxi(max_sequence,serial)
	if int(state.sequence)<max_sequence:return _checkpoint_reject("base_checkpoint_sequence_reuse")
	var states:Dictionary={};var beds:Dictionary={};var tokens:Dictionary={}
	for id in state.units:
		if not _checkpoint_id(id) or not _states.has(id):return _checkpoint_reject("base_checkpoint_unit_set")
		var actor:Node2D=_checkpoint_live_actor(id)
		if actor==null:return _checkpoint_reject("base_checkpoint_actor_unbound")
		var value:Variant=state.units[id]
		if not _checkpoint_keys(value,["status","craft_id","bed_id","action","auto_rest_enabled","rest_automatic","idle_seconds","manual_priority_seconds"]) or value.status not in ["outside","moving","sleeping","aboard"] or typeof(value.auto_rest_enabled)!=TYPE_BOOL or typeof(value.rest_automatic)!=TYPE_BOOL or not _checkpoint_number(value.idle_seconds) or not _checkpoint_number(value.manual_priority_seconds) or typeof(value.craft_id)!=TYPE_STRING or typeof(value.bed_id)!=TYPE_STRING or typeof(value.action)!=TYPE_DICTIONARY:return _checkpoint_reject("base_checkpoint_invalid_unit")
		var action:Dictionary={}
		if value.status=="aboard":
			if not _checkpoint_home_craft(value.craft_id) or not _checkpoint_craft_member(id,value.craft_id) or target.has_unit(id) or intents.has(id) or not value.action.is_empty() or not value.bed_id.is_empty():return _checkpoint_reject("base_checkpoint_aboard_context")
		else:
			if not value.craft_id.is_empty() or not target.has_unit(id):return _checkpoint_reject("base_checkpoint_ground_presence")
		if value.status=="moving":
			var kind:Variant=value.action.get("type")
			var keys:Array=["type","target","command_token"]
			if kind=="sleep":keys.append_array(["bed_id","automatic"])
			elif kind=="terminal":keys.append("terminal_id")
			elif kind!="move":return _checkpoint_reject("base_checkpoint_invalid_action")
			if not _checkpoint_keys(value.action,keys) or not _checkpoint_pair(value.action.target) or not _checkpoint_id(value.action.command_token) or _checkpoint_token_sequence(value.action.command_token)<1 or _checkpoint_token_sequence(value.action.command_token)>int(state.sequence) or tokens.has(value.action.command_token) or not intents.has(id):return _checkpoint_reject("base_checkpoint_action_token")
			tokens[value.action.command_token]=true
			var intent:Dictionary=intents[id];var fields:Dictionary={}
			for field in intent.command_intent:fields[field.key]=field.value
			var point:=Vector2(float(value.action.target[0]),float(value.action.target[1]))
			if intent.source_command_id!=value.action.command_token or fields.get("source_command_type")!="base_personnel" or fields.get("command_type",fields.get("type"))!="move_to_position" or fields.get("unit_id")!=id or not _checkpoint_pair(fields.get("target_position")) or point!=Vector2(float(fields.target_position[0]),float(fields.target_position[1])):return _checkpoint_reject("base_checkpoint_action_mismatch")
			var axial:Vector2=_terrain.world_to_grid_float(point)
			if not axial.is_finite() or absf(axial.x)>2147470000.0 or absf(axial.y)>2147470000.0:return _checkpoint_reject("base_checkpoint_action_mismatch")
			var goal:Vector2i=_terrain.world_to_grid(point)
			if not _checkpoint_pair(intent.goal_grid) or not _checkpoint_int(intent.goal_grid[0],-2147480000,2147480000) or not _checkpoint_int(intent.goal_grid[1],-2147480000,2147480000) or Vector2i(int(intent.goal_grid[0]),int(intent.goal_grid[1]))!=goal:return _checkpoint_reject("base_checkpoint_action_mismatch")
			action={"type":String(kind),"target":point,"command_token":String(value.action.command_token)}
			if kind=="sleep":
				if typeof(value.action.automatic)!=TYPE_BOOL or value.action.bed_id!=value.bed_id:return _checkpoint_reject("base_checkpoint_bed_mismatch")
				action.bed_id=value.bed_id;action.automatic=value.action.automatic
			elif kind=="terminal":
				var terminal:Dictionary=_find_layout("terminals",String(value.action.terminal_id))
				if not _checkpoint_id(value.action.terminal_id) or terminal.is_empty() or not bool(terminal.get("enabled",true)) or _world(terminal.grid)!=point:return _checkpoint_reject("base_checkpoint_terminal_mismatch")
				action.terminal_id=String(value.action.terminal_id)
		elif not value.action.is_empty():return _checkpoint_reject("base_checkpoint_action_status")
		if value.status=="sleeping" or action.get("type")=="sleep":
			var bed:Dictionary=_find_layout("beds",value.bed_id)
			if not _checkpoint_id(value.bed_id) or bed.is_empty() or beds.has(value.bed_id):return _checkpoint_reject("base_checkpoint_bed_mismatch")
			if value.status=="sleeping":
				var pose:Dictionary=target.read_unit(id)
				if pose.grid!=_terrain.world_to_grid(_world(bed.grid)) or pose.route_state.has_commitments or pose.movement_state.moving:return _checkpoint_reject("base_checkpoint_bed_pose")
			elif action.target!=_world(bed.grid):return _checkpoint_reject("base_checkpoint_bed_mismatch")
			beds[value.bed_id]=id
		elif not value.bed_id.is_empty():return _checkpoint_reject("base_checkpoint_bed_mismatch")
		if intents.has(id):
			var intent:Dictionary=intents[id]
			if intent.status not in ["arrived","canceled"] and value.status!="moving":return _checkpoint_reject("base_checkpoint_missing_action")
		var restored:Dictionary=_states[id].duplicate(true)
		for key in ["status","craft_id","bed_id","auto_rest_enabled","rest_automatic"]:restored[key]=value[key]
		restored.action=action;restored.idle_seconds=float(value.idle_seconds);restored.manual_priority_seconds=float(value.manual_priority_seconds);restored.last_result={}
		states[id]=restored
	for id in target.get_unit_ids():
		if not states.has(id) or states[id].status=="aboard":return _checkpoint_reject("base_checkpoint_ground_presence")
	return {"ok":true,"states":states,"beds":beds}

func _checkpoint_craft_member(id:String,craft_id:String)->bool:
	if not _screen.has_method("_get_assigned_pilot_id") or not _screen.has_method("_get_homebase_direct_payload_fireteam_ids_for_craft_raw") or not _screen.has_method("_get_member_unit_ids_for_fireteam"):return false
	if _screen.call("_get_assigned_pilot_id",craft_id)==id:return true
	for team in _screen.call("_get_homebase_direct_payload_fireteam_ids_for_craft_raw",craft_id):
		if PackedStringArray(_screen.call("_get_member_unit_ids_for_fireteam",String(team))).has(id):return true
	return false

func _checkpoint_transport_context(state:Dictionary)->Dictionary:
	var result:Dictionary={}
	for value in state.units.values():
		if not value is Dictionary or String(value.get("craft_id","")).is_empty():continue
		var craft:String=String(value.craft_id)
		if result.has(craft):continue
		var teams:Dictionary={}
		if _screen.has_method("_get_homebase_direct_payload_fireteam_ids_for_craft_raw"):
			for team in _screen.call("_get_homebase_direct_payload_fireteam_ids_for_craft_raw",craft):teams[String(team)]=PackedStringArray(_screen.call("_get_member_unit_ids_for_fireteam",String(team))).duplicate()
		result[craft]={"pilot":_screen.call("_get_assigned_pilot_id",craft) if _screen.has_method("_get_assigned_pilot_id") else "","teams":teams,"home":_checkpoint_home_craft(craft)}
	return result

func _checkpoint_home_craft(craft_id:String)->bool:
	if not _checkpoint_id(craft_id) or not _flow.has_method("_find_homebase_aircraft_definition") or Dictionary(_flow.call("_find_homebase_aircraft_definition",craft_id)).is_empty() or String(Dictionary(_flow.get("_aircraft_location_by_craft")).get(craft_id,"")) not in ["homebase","waiting_pad"] or not Dictionary(_flow.call("_find_pending_mission_craft_transfer",craft_id)).is_empty() or not get_parent().has_method("get_space_travel_snapshot"):return false
	return Dictionary(get_parent().call("get_space_travel_snapshot",craft_id)).get("phase")=="grounded"
func _checkpoint_token_sequence(token:Variant)->int:
	if not _checkpoint_id(token) or not String(token).begins_with("base:"):return -1
	var suffix:String=String(token).substr(5)
	if not suffix.is_valid_int() or suffix.length()>13:return -1
	var serial:=int(suffix)
	return serial if serial>=1 and serial<=1000000000000 and token=="base:%d"%serial else -1
func _checkpoint_keys(value:Variant,keys:Array)->bool:
	if typeof(value)!=TYPE_DICTIONARY or value.size()!=keys.size():return false
	for key in keys:
		if not value.has(key):return false
	return true
func _checkpoint_id(value:Variant)->bool:return typeof(value)==TYPE_STRING and not String(value).is_empty() and value==String(value).strip_edges() and String(value).length()<=256
func _checkpoint_int(value:Variant,minimum:int,maximum:int)->bool:return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)==floorf(float(value)) and float(value)>=minimum and float(value)<=maximum
func _checkpoint_number(value:Variant)->bool:return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)>=0.0 and float(value)<=1000000000000.0
func _checkpoint_pair(value:Variant)->bool:
	if typeof(value)!=TYPE_ARRAY or value.size()!=2:return false
	for number in value:
		if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)) or absf(float(number))>1000000000000.0:return false
	return true
func _checkpoint_reject(reason:String)->Dictionary:return {"ok":false,"reason":reason}
