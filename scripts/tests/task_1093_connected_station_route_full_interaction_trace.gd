extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const INTERACTION_BINDINGS := preload("res://scripts/mission/mission_interaction_point_binding.gd")
const CONTEXT := preload("res://scripts/tests/review_interaction_fixture_context.gd")
const SCENARIO_PATH := "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const ENET_PORT_START := 19461
const ENET_PORT_END := 19471
const ROUTE := [
	{"interaction_id":"aa_shutdown_zone","interaction_type":"hold_zone","command_type":"take","required_order":"take","duration_seconds":0.0,"step_id":"disable_air_defense","required_state":"aa_disabled"},
	{"interaction_id":"station_route_drill_door","interaction_type":"door","command_type":"take","required_order":"breach","duration_seconds":2.0,"step_id":"open_station_door","required_state":"door_open"},
	{"interaction_id":"station_computer","interaction_type":"computer","command_type":"take","required_order":"take","duration_seconds":18.0,"step_id":"occupy_station_computer","required_state":"computer_controlled"},
	{"interaction_id":"cargo_landing_hold","interaction_type":"hold_zone","command_type":"defend","required_order":"defend","duration_seconds":12.0,"step_id":"cargo_touchdown_extract","required_state":"cargo_departed"},
]

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1093 Connected Station Route Full Interaction Trace ===")
	await _test_full_route()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_full_route() -> void:
	var pair := await _create_pair()
	_assert(bool(pair.get("connected", false)), "Local ENet pair connects")
	if not bool(pair.get("connected", false)):
		return
	var host_api: MultiplayerAPI = pair.host_api
	var client_api: MultiplayerAPI = pair.client_api
	var host_root := Node.new()
	var client_root := Node.new()
	root.add_child(host_root)
	root.add_child(client_root)
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(client_api, client_root.get_path())
	var host_scene := MISSION_SCENE.instantiate()
	var client_scene := MISSION_SCENE.instantiate()
	host_scene.name = "Mission"
	client_scene.name = "Mission"
	_configure_scene(host_scene)
	_configure_scene(client_scene)
	host_root.add_child(host_scene)
	client_root.add_child(client_scene)
	await _poll(host_api, client_api, 16)
	var host_sim := host_scene.get_node("SimulationRoot")
	var client_sim := client_scene.get_node("SimulationRoot")
	var host_driver := host_scene.get_node("CombatLoopDriver")
	var client_driver := client_scene.get_node("CombatLoopDriver")
	var host_controller := host_scene.get_node("TacticalController")
	var client_controller := client_scene.get_node("TacticalController")
	_assert(bool(host_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Host loads Station gates")
	_assert(bool(client_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Client loads Station gates")
	_assert(client_controller.has_method("build_mission_interaction_multiplayer_network_command"), "Controller exposes generic Interaction network projection")
	var fireteam_id := String(PackedStringArray(host_controller.call("_get_available_fireteam_ids"))[0])
	var unit_id := _first_unit_id(host_scene, fireteam_id)
	var peer_id := client_api.get_unique_id()
	_configure(host_sim, peer_id, fireteam_id)
	_configure(client_sim, peer_id, fireteam_id)
	_assert(CONTEXT.bind_pair(host_scene, client_scene, "task1093_station_route"), "Both actual Station scenes bind the verified map session")
	await _poll(host_api, client_api, 12)
	var host_unit := _find_unit(host_scene, unit_id)
	# Use the map already loaded by MissionSetup, not a separately loaded copy.
	var map_data = host_scene.get_node("MissionSetup").get("_loaded_terrain_map_data")
	var bindings: Dictionary = {}
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_PATH))
	for binding: Dictionary in INTERACTION_BINDINGS.normalize_scenario_bindings(scenario):
		bindings[String(binding.interaction_id)] = binding
	for step_variant in ROUTE:
		var step: Dictionary = Dictionary(step_variant).duplicate(true)
		var binding: Dictionary = bindings.get(String(step.interaction_id), {})
		_assert(not binding.is_empty() and map_data != null and map_data.has_marker(String(binding.get("marker_id", ""))), "%s has a real authored Host marker" % step.interaction_id)
		if binding.is_empty() or map_data == null or not map_data.has_marker(String(binding.get("marker_id", ""))):
			continue
		# Door and computer now retain their actual authored positions. Travel
		# crosses the real two-cell entrance after the connected Use opens it.
		# AA/Cargo remain bounded routing probes at the actor's actual Ground cell.
		var physical_step:bool=String(step.interaction_id) in ["station_route_drill_door","station_computer"]
		var terrain:Node=host_scene.get_node("TerrainRegistry")
		if String(step.interaction_id)=="station_route_drill_door":
			_assert(not terrain.call("is_walkable",Vector2i(103,95)) and not terrain.call("is_walkable",Vector2i(104,95)),"Actual eastern frame and leaf are both closed before Use")
			if not await _walk_to_grid(host_scene,host_api,client_api,unit_id,Vector2i(105,95),"door_outside"):break
		elif String(step.interaction_id)=="station_computer":
			_assert(terrain.call("is_walkable",Vector2i(103,95)) and terrain.call("is_walkable",Vector2i(104,95)),"Connected Door Use opens exactly the physical entrance")
			if not await _walk_to_grid(host_scene,host_api,client_api,unit_id,Vector2i(104,95),"door_leaf"):break
			if not await _walk_to_grid(host_scene,host_api,client_api,unit_id,Vector2i(103,95),"door_frame"):break
			if not await _walk_to_grid(host_scene,host_api,client_api,unit_id,Vector2i(96,95),"computer_inside"):break
		var actual_position:=CONTEXT.ground_position(host_scene, unit_id)
		var target:Vector2=map_data.get_marker_position(String(binding.marker_id)) if physical_step else actual_position
		_assert(actual_position.is_finite() and host_unit.global_position.is_equal_approx(actual_position), "%s uses the actual admitted Ground position" % step.interaction_id)
		if not actual_position.is_finite() or not host_unit.global_position.is_equal_approx(actual_position):
			print("STATION_ROUTE_ADMISSION ", {"unit_id":unit_id,"position":host_unit.global_position,"setup":host_scene.get_node("MissionSetup").call("get_hex_setup_status"),"pending":host_scene.get_node("MissionSetup").get("_hex_setup_pending"),"ground":host_sim.call("get_hex_unit_state",unit_id)})
			# Preserve the failed precondition and clean up below. An absent Ground
			# position must never become an infinite marker/rendering transform.
			break
		if not physical_step:
			map_data.set_marker_position(String(binding.marker_id), target)
			client_scene.get_node("MissionSetup").get("_loaded_terrain_map_data").set_marker_position(String(binding.marker_id), target)
		step.merge({"accepted":true,"fireteam_id":fireteam_id,"target_position":target,"gate_id":binding.gate_id,"interaction_radius_world":float(binding.radius_world)}, true)
		var command: Dictionary = Dictionary(client_controller.call("build_mission_interaction_multiplayer_network_command", step, unit_id, "team_alpha", target))
		_assert(not command.is_empty() and String(command.get("source_context", "")) == "mission_interaction_use_intent_command", "%s projects to a neutral network command" % step.interaction_id)
		if String(step.interaction_id)=="station_route_drill_door":
			var forged:=command.duplicate(true)
			forged.door_cells=[{"x":0,"y":0}]
			forged.target_position=Vector2.ZERO;forged.duration_seconds=0.0;forged.interaction_radius_world=9999.0
			var resolved:Dictionary=host_driver.call("_resolve_host_network_interaction",forged)
			var canonical:Dictionary=resolved.get("command",{})
			_assert(resolved.get("accepted",false) and canonical.get("target_position")==target and canonical.get("duration_seconds")==2.0 and canonical.get("interaction_radius_world")==128.0,"Host ignores forged client target, duration and range for actual physical Door")
			var projection:Dictionary=load("res://scripts/mission/mission_interaction_door_runtime_collision_los.gd").build_runtime_snapshot([binding],{"station_route_drill_door":{"complete":true}},map_data,terrain)
			var physical_cells:Array=[]
			for override:Dictionary in projection.overrides:physical_cells.append(override.grid_position)
			_assert(physical_cells.size()==2 and physical_cells.has(Vector2i(103,95)) and physical_cells.has(Vector2i(104,95)) and not physical_cells.has(Vector2i.ZERO),"Forged client footprint never changes the two authoritative Door cells")
		client_sim.call("submit_multiplayer_command", command)
		await _poll(host_api, client_api, 18)
		host_sim.call("_physics_process", maxf(float(step.duration_seconds), 0.0) + 0.5)
		host_sim.call("_physics_process", 0.016)
		await _poll(host_api, client_api, 12)
		var host_state := Dictionary(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).get(step.interaction_id, {}))
		var client_state := Dictionary(Dictionary(client_driver.call("get_mission_interaction_runtime_states")).get(step.interaction_id, {}))
		if not bool(client_state.get("complete", false)):
			var projected: Dictionary = host_sim.call("project_multiplayer_state_for_peer", peer_id)
			print("STATION_ROUTE_INVALID_WIRE_FIELDS ", _invalid_wire_fields(host_sim.call("_build_raw_multiplayer_tick_state")))
			print("STATION_ROUTE_REPLICATION ", {"interaction_id":step.interaction_id,"host":host_state,"client":client_state,"projection_ok":projected.get("ok",false),"projection_reason":projected.get("reason",""),"projected_interactions":Dictionary(projected.get("snapshot",{})).get("mission_interactions",{}),"host_transport":host_sim.call("get_snapshot_transport_debug_snapshot"),"client_transport":client_sim.call("get_snapshot_transport_debug_snapshot"),"client_apply":client_sim.call("get_multiplayer_snapshot_debug_snapshot")})
		_assert(bool(host_state.get("complete", false)) and String(host_state.get("required_state", "")) == String(step.required_state), "%s completes from host Arrival/Hold" % step.interaction_id)
		_assert(bool(client_state.get("complete", false)), "%s replicates to client" % step.interaction_id)
	var host_gate := Dictionary(host_controller.call("get_mission_interaction_objective_gate_snapshot"))
	var client_gate := Dictionary(client_controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(host_gate.get("all_gates_complete", false)), "Host completes AA Door Computer Cargo route")
	_assert(bool(client_gate.get("all_gates_complete", false)), "Client mirrors completed route")
	_assert(Array(client_sim.get("command_queue")).is_empty(), "Client receives no gameplay command from snapshots")
	client_root.queue_free()
	host_root.queue_free()
	pair.client_peer.close()
	pair.host_peer.close()
	await process_frame


func _walk_to_grid(scene:Node,host_api:MultiplayerAPI,client_api:MultiplayerAPI,unit_id:String,grid:Vector2i,label:String)->bool:
	var sim:Node=scene.get_node("SimulationRoot")
	var terrain:Node=scene.get_node("TerrainRegistry")
	var target:Vector2=terrain.call("grid_to_world",grid)
	if not bool(terrain.call("is_walkable",grid)):
		_assert(false,"Actual station approach goal is walkable: "+label)
		return false
	var ids:=PackedStringArray([unit_id])
	var targets:Dictionary={unit_id:target}
	if label=="door_outside":
		# Normal admission surrounds the lead actor with its seven teammates.
		# Move the actual group together; a lone centre actor correctly cannot
		# walk through stationary occupants. No actors or claims are relocated.
		var leader:Node=_find_unit(scene,unit_id)
		for id in sim.call("get_hex_ground_planning_snapshot").get("units_by_id",{}):
			var actor:Node=_find_unit(scene,String(id))
			if String(id)!=unit_id and is_instance_valid(actor) and actor.call("get_team_id")==leader.call("get_team_id"):
				ids.append(String(id))
		var planned:Dictionary=sim.call("plan_hex_ground_actor_approach",ids,target,128.0)
		_assert(planned.get("ok",false),"Actual Root plans distinct legal outer-entrance goals for the full admitted crew")
		if not planned.get("ok",false):print("STATION_GROUP_APPROACH ",planned);return false
		targets=planned.targets
		_assert(targets.get(unit_id)==target,"Original lead actor retains the exact authored exterior approach goal")
		if targets.get(unit_id)!=target:return false
	var tokens:Dictionary={}
	for id in ids:
		tokens[id]="station-physical:"+label+":"+id
		sim.call("enqueue_command",{"type":"move_to_position","unit_id":id,"team_id":"team_alpha","target_position":targets[id],"command_token":tokens[id],"move_speed_factor":1.0,"requeue_until_target":true})
	var arrived:=false
	for tick in range(2400):
		sim.call("_physics_process",0.1)
		arrived=true
		var all_terminal:=true
		var progress:Dictionary={}
		for id in ids:
			var done:bool=sim.call("has_hex_position_arrived",id,targets[id],tokens[id])
			var readout:Dictionary=sim.call("get_hex_movement_readout",id)
			arrived=arrived and done
			all_terminal=all_terminal and (done or (readout.get("status", "")=="blocked" and readout.get("reason", "")=="unreachable_target"))
			if tick%200==0:progress[id]={"ground":sim.call("get_hex_unit_state",id),"movement":readout}
		if tick%200==0:print("STATION_PHYSICAL_PROGRESS ",{"label":label,"tick":tick,"actors":progress})
		if arrived or all_terminal:break
		if tick%4==0:await _poll(host_api,client_api,1)
	if not arrived:print("STATION_PHYSICAL_WALK ",{"label":label,"goal":grid,"ground":sim.call("get_hex_unit_state",unit_id),"movement":sim.call("get_hex_movement_readout",unit_id)})
	_assert(arrived,"Actual Root movement reaches "+label+" with original tokens and no pending movement")
	await _poll(host_api,client_api,4)
	return arrived


func _configure_scene(scene: Node) -> void:
	# Set the actual scenario before _ready so its map, UI bindings and host
	# runtime gates agree. Damage/AI motion are outside this routing regression.
	scene.get_node("MissionSetup").set("scenario_file_path", SCENARIO_PATH)
	scene.get_node("MissionSetup").set("defer_friendly_runtime_activation", false)
	scene.get_node("SimulationRoot").set("is_server_authoritative", true)
	# The existing grace API still runs Arrival/Hold, gates and replication.
	scene.get_node("CombatLoopDriver").call("set_combat_startup_grace_ticks", 100000)


func _configure(sim: Node, peer_id: int, fireteam_id: String) -> void:
	sim.set("is_server_authoritative", true)
	sim.call("set_peer_team_assignments", {1:"team_alpha", peer_id:"team_alpha"})
	sim.call("set_peer_role", 1, "host")
	sim.call("set_peer_role", peer_id, "commander")
	sim.call("set_peer_fireteam_assignments", {1:[fireteam_id], peer_id:[fireteam_id]})


func _first_unit_id(scene: Node, fireteam_id: String) -> String:
	var unit := _find_unit(scene, "", fireteam_id)
	return String(unit.call("get_unit_id")) if unit != null else ""


func _find_unit(scene: Node, unit_id: String = "", fireteam_id: String = "") -> Node2D:
	for child in scene.get_children():
		if child is Node2D and child.has_method("get_unit_id"):
			if not unit_id.is_empty() and String(child.call("get_unit_id")) == unit_id:
				return child
			if not fireteam_id.is_empty() and child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")) == fireteam_id:
				return child
	return null


func _create_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var hp := ENetMultiplayerPeer.new()
		if hp.create_server(port, 2) != OK:
			continue
		var cp := ENetMultiplayerPeer.new()
		if cp.create_client("127.0.0.1", port) != OK:
			hp.close()
			continue
		var ha := MultiplayerAPI.create_default_interface()
		var ca := MultiplayerAPI.create_default_interface()
		ha.multiplayer_peer = hp
		ca.multiplayer_peer = cp
		for _i in range(180):
			ha.poll(); ca.poll()
			if cp.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {"connected":true,"host_api":ha,"client_api":ca,"host_peer":hp,"client_peer":cp}
			await process_frame
		cp.close(); hp.close()
	return {"connected":false}


func _poll(host_api: MultiplayerAPI, client_api: MultiplayerAPI, count: int) -> void:
	for _i in range(count):
		host_api.poll(); client_api.poll(); await process_frame


func _invalid_wire_fields(value: Variant, path: String = "raw", depth: int = 0) -> PackedStringArray:
	var result := PackedStringArray()
	if depth > 16:
		return PackedStringArray([path + ":depth"])
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_VECTOR2I:
			pass
		TYPE_FLOAT:
			if not is_finite(value): result.append(path + ":nonfinite_float")
		TYPE_VECTOR2:
			if not value.is_finite(): result.append(path + ":nonfinite_vector")
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY:
			for i in value.size():
				result.append_array(_invalid_wire_fields(value[i], path + "[%d]" % i, depth + 1))
		TYPE_DICTIONARY:
			for key in value:
				if typeof(key) not in [TYPE_STRING, TYPE_STRING_NAME]: result.append(path + ":nonstring_key")
				else: result.append_array(_invalid_wire_fields(value[key], path + "." + String(key), depth + 1))
		_:
			result.append(path + ":type_%d" % typeof(value))
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1; print("PASS: %s" % message)
	else:
		_failed += 1; push_error("FAIL: %s" % message)
