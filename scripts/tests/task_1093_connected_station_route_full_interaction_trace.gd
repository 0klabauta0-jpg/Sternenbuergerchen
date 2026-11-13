extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const INTERACTION_BINDINGS := preload("res://scripts/mission/mission_interaction_point_binding.gd")
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
		var target: Vector2 = map_data.get_marker_position(String(binding.marker_id), Vector2.ZERO)
		step.merge({"accepted":true,"fireteam_id":fireteam_id,"target_position":target,"gate_id":binding.gate_id,"interaction_radius_world":float(binding.radius_world)}, true)
		var command: Dictionary = Dictionary(client_controller.call("build_mission_interaction_multiplayer_network_command", step, unit_id, "team_alpha", target))
		_assert(not command.is_empty() and String(command.get("source_context", "")) == "mission_interaction_use_intent_command", "%s projects to a neutral network command" % step.interaction_id)
		client_sim.rpc_id(1, "request_command", command)
		await _poll(host_api, client_api, 18)
		if host_unit != null:
			host_unit.global_position = target
		host_sim.call("_physics_process", maxf(float(step.duration_seconds), 0.0) + 0.5)
		host_sim.call("_physics_process", 0.016)
		await _poll(host_api, client_api, 12)
		var host_state := Dictionary(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).get(step.interaction_id, {}))
		var client_state := Dictionary(Dictionary(client_driver.call("get_mission_interaction_runtime_states")).get(step.interaction_id, {}))
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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1; print("PASS: %s" % message)
	else:
		_failed += 1; push_error("FAIL: %s" % message)
