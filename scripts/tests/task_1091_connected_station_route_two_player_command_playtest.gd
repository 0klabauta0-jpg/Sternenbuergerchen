extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const DOOR_AUTHORITY_SCRIPT := preload("res://scripts/mission/mission_interaction_door_multiplayer_authority.gd")
const SCENARIO_PATH := "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const ENET_PORT_START := 19439
const ENET_PORT_END := 19449

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1091 Connected Station Route Two-Player Command Playtest ===")
	await _test_connected_station_route_replication()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_connected_station_route_replication() -> void:
	print("TASK_1091 phase: connect")
	var pair := await _create_multiplayer_api_pair()
	_assert(bool(pair.get("connected", false)), "Local ENet pair connects")
	if not bool(pair.get("connected", false)):
		return
	var host_api: MultiplayerAPI = pair["host_api"]
	var client_api: MultiplayerAPI = pair["client_api"]
	var host_peer: ENetMultiplayerPeer = pair["host_peer"]
	var client_peer: ENetMultiplayerPeer = pair["client_peer"]
	var client_peer_id := client_api.get_unique_id()

	var host_root := Node.new()
	host_root.name = "Task1091Host"
	root.add_child(host_root)
	var client_root := Node.new()
	client_root.name = "Task1091Client"
	root.add_child(client_root)
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(client_api, client_root.get_path())

	print("TASK_1091 phase: instantiate host")
	var host_scene := _build_mission_scene("Mission")
	print("TASK_1091 phase: instantiate client")
	var client_scene := _build_mission_scene("Mission")
	print("TASK_1091 phase: attach missions")
	host_root.add_child(host_scene)
	print("TASK_1091 phase: host attached")
	client_root.add_child(client_scene)
	print("TASK_1091 phase: client attached")
	await _poll_pair(host_api, client_api, 24)

	var host_sim := host_scene.get_node_or_null("SimulationRoot")
	var client_sim := client_scene.get_node_or_null("SimulationRoot")
	var host_driver := host_scene.get_node_or_null("CombatLoopDriver")
	var client_driver := client_scene.get_node_or_null("CombatLoopDriver")
	var host_controller := host_scene.get_node_or_null("TacticalController")
	var client_controller := client_scene.get_node_or_null("TacticalController")
	_assert(host_sim != null and client_sim != null and host_driver != null and client_driver != null and host_controller != null and client_controller != null, "Both connected missions expose authority, runtime and controller")
	if host_sim == null or client_sim == null or host_driver == null or client_driver == null or host_controller == null or client_controller == null:
		_close_pair(host_peer, client_peer)
		return
	_assert(bool(host_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Host loads the real Station Route gate contract")
	_assert(bool(client_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Client loads the real Station Route gate contract")

	var fireteams: PackedStringArray = PackedStringArray(host_controller.call("_get_available_fireteam_ids"))
	_assert(fireteams.size() >= 2, "Station mission exposes two Alpha Fireteams for coop ownership")
	if fireteams.size() < 2:
		_close_pair(host_peer, client_peer)
		return
	var host_fireteam := String(fireteams[0])
	var client_fireteam := String(fireteams[1])
	_configure_authority(host_sim, client_peer_id, host_fireteam, client_fireteam)
	_configure_authority(client_sim, client_peer_id, host_fireteam, client_fireteam)
	host_controller.call("_set_selected_fireteams", PackedStringArray([host_fireteam]), false)
	client_controller.call("_set_selected_fireteams", PackedStringArray([client_fireteam]), false)
	var client_unit_id := _first_unit_id_for_fireteam(client_scene, client_fireteam)
	_assert(not client_unit_id.is_empty(), "Client owns a concrete Alpha unit in its Fireteam")

	var target_position: Vector2 = Vector2(host_scene.get_node("MapRoot/objective_point").global_position)
	var door_hook: Dictionary = {
		"accepted": true,
		"interaction_id": "station_route_drill_door",
		"interaction_type": "door",
		"fireteam_id": client_fireteam,
		"command_type": "take",
		"required_order": "breach",
		"requires_go": true,
		"duration_seconds": 2.0,
	}
	var door_command: Dictionary = Dictionary(DOOR_AUTHORITY_SCRIPT.build_network_command_from_hook(door_hook, client_unit_id, "team_alpha", target_position))
	_assert(not door_command.is_empty(), "Client projects the Door intent into a network command")
	var host_accept_before := int(Dictionary(host_sim.call("get_network_command_contract_snapshot")).get("accepted_count", 0))
	client_sim.rpc_id(1, "request_command", door_command)
	_assert(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).is_empty(), "Client request does not mutate host Interaction runtime before authority processing")
	_assert(Dictionary(client_driver.call("get_mission_interaction_runtime_states")).is_empty(), "Client request does not mutate local Interaction runtime")
	await _poll_pair(host_api, client_api, 20)
	var host_accept_after := int(Dictionary(host_sim.call("get_network_command_contract_snapshot")).get("accepted_count", 0))
	_assert(host_accept_after > host_accept_before, "Client Door command reaches host validation over RPC")
	host_sim.call("_physics_process", 0.016)
	await _poll_pair(host_api, client_api, 16)

	_complete_interaction(host_driver, "aa_shutdown_zone", "disable_air_defense", "aa_disabled", "hold_zone", "take", client_fireteam, 0.0)
	_complete_interaction(host_driver, "station_route_drill_door", "open_station_door", "door_open", "door", "breach", client_fireteam, 2.0)
	_complete_interaction(host_driver, "station_computer", "occupy_station_computer", "computer_controlled", "computer", "take", client_fireteam, 18.0)
	_complete_interaction(host_driver, "cargo_landing_hold", "cargo_touchdown_extract", "cargo_departed", "hold_zone", "defend", client_fireteam, 12.0)
	var host_gate: Dictionary = Dictionary(host_controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(host_gate.get("all_gates_complete", false)), "Host completes Door, Computer and Cargo authoritatively")

	host_sim.call("_physics_process", 0.016)
	await _poll_pair(host_api, client_api, 36)
	var client_state: Dictionary = Dictionary(client_sim.call("get_last_server_state"))
	var client_runtime_states: Dictionary = Dictionary(client_driver.call("get_mission_interaction_runtime_states"))
	var client_gate: Dictionary = Dictionary(client_controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(client_state.has("mission_interactions"), "Authoritative snapshot carries Station Interaction state")
	_assert(_interaction_complete(client_runtime_states, "station_route_drill_door"), "Client mirrors Door Open from host snapshot")
	_assert(_interaction_complete(client_runtime_states, "station_computer"), "Client mirrors Computer Controlled from host snapshot")
	_assert(_interaction_complete(client_runtime_states, "cargo_landing_hold"), "Client mirrors Cargo Departed from host snapshot")
	_assert(bool(client_gate.get("all_gates_complete", false)), "Client reads the completed Station Route")
	_assert(Array(client_sim.get("command_queue")).is_empty(), "Snapshot apply creates no client Gameplay command")

	host_root.queue_free()
	client_root.queue_free()
	_close_pair(host_peer, client_peer)
	await process_frame


func _build_mission_scene(node_name: String) -> Node:
	var scene := MISSION_SCENE.instantiate()
	scene.name = node_name
	var driver := scene.get_node_or_null("CombatLoopDriver")
	if driver != null:
		driver.set("enemy_advance_enabled", false)
		driver.set("enemy_reposition_enabled", false)
		driver.set("base_hit_chance", 0.0)
		driver.set("damage_per_hit", 0)
	return scene


func _configure_authority(simulation_root: Node, client_peer_id: int, host_fireteam: String, client_fireteam: String) -> void:
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team_assignments", {1: "team_alpha", client_peer_id: "team_alpha"})
	simulation_root.call("set_peer_role", 1, "host")
	simulation_root.call("set_peer_role", client_peer_id, "commander")
	simulation_root.call("set_peer_fireteam_assignments", {1: [host_fireteam], client_peer_id: [client_fireteam]})


func _complete_interaction(driver: Node, interaction_id: String, step_id: String, required_state: String, interaction_type: String, command_type: String, fireteam_id: String, duration: float) -> void:
	driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": interaction_id,
		"state": "operating",
		"complete": true,
		"hold_seconds": duration,
		"duration_seconds": duration,
		"can_complete_zero_duration": duration <= 0.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": step_id,
		"gate_id": step_id,
		"required_state": required_state,
		"interaction_type": interaction_type,
		"command_type": command_type,
	})


func _first_unit_id_for_fireteam(scene: Node, fireteam_id: String) -> String:
	for child in scene.get_children():
		if child.has_method("get_fireteam_id") and child.has_method("get_unit_id") and String(child.call("get_fireteam_id")) == fireteam_id:
			return String(child.call("get_unit_id"))
	return ""


func _interaction_complete(states: Dictionary, interaction_id: String) -> bool:
	return bool(Dictionary(states.get(interaction_id, {})).get("complete", false))


func _create_multiplayer_api_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 2) != OK:
			host_peer.close()
			continue
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
			client_peer.close()
			host_peer.close()
			continue
		var host_api := MultiplayerAPI.create_default_interface()
		var client_api := MultiplayerAPI.create_default_interface()
		host_api.multiplayer_peer = host_peer
		client_api.multiplayer_peer = client_peer
		for _index in range(180):
			host_api.poll()
			client_api.poll()
			if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {"connected": true, "host_api": host_api, "client_api": client_api, "host_peer": host_peer, "client_peer": client_peer}
			await process_frame
		client_peer.close()
		host_peer.close()
	return {"connected": false}


func _poll_pair(host_api: MultiplayerAPI, client_api: MultiplayerAPI, frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		host_api.poll()
		client_api.poll()
		await process_frame


func _close_pair(host_peer: ENetMultiplayerPeer, client_peer: ENetMultiplayerPeer) -> void:
	client_peer.close()
	host_peer.close()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
