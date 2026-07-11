extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const DOOR_AUTHORITY_SCRIPT := preload("res://scripts/mission/mission_interaction_door_multiplayer_authority.gd")
const SCENARIO_PATH := "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const ENET_PORT_START := 19450
const ENET_PORT_END := 19460

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1092 Connected Station Route Runtime Arrival Hold ===")
	await _test_network_arrival_and_hold_complete_door()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_network_arrival_and_hold_complete_door() -> void:
	var pair: Dictionary = await _create_multiplayer_api_pair()
	_assert(bool(pair.get("connected", false)), "Local ENet pair connects")
	if not bool(pair.get("connected", false)):
		return
	var host_api: MultiplayerAPI = pair["host_api"]
	var client_api: MultiplayerAPI = pair["client_api"]
	var host_peer: ENetMultiplayerPeer = pair["host_peer"]
	var client_peer: ENetMultiplayerPeer = pair["client_peer"]
	var client_peer_id := client_api.get_unique_id()
	var host_root := Node.new()
	var client_root := Node.new()
	host_root.name = "Task1092Host"
	client_root.name = "Task1092Client"
	root.add_child(host_root)
	root.add_child(client_root)
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(client_api, client_root.get_path())
	var host_scene := MISSION_SCENE.instantiate()
	var client_scene := MISSION_SCENE.instantiate()
	host_scene.name = "Mission"
	client_scene.name = "Mission"
	host_root.add_child(host_scene)
	client_root.add_child(client_scene)
	await _poll_pair(host_api, client_api, 16)

	var host_sim := host_scene.get_node("SimulationRoot")
	var client_sim := client_scene.get_node("SimulationRoot")
	var host_driver := host_scene.get_node("CombatLoopDriver")
	var client_driver := client_scene.get_node("CombatLoopDriver")
	var host_controller := host_scene.get_node("TacticalController")
	_assert(bool(host_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Host loads Station Route gates")
	_assert(bool(client_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Client loads Station Route gates")
	var fireteams := PackedStringArray(host_controller.call("_get_available_fireteam_ids"))
	var client_fireteam := String(fireteams[0])
	var unit_id := _first_unit_id_for_fireteam(host_scene, client_fireteam)
	_configure_authority(host_sim, client_peer_id, client_fireteam)
	_configure_authority(client_sim, client_peer_id, client_fireteam)
	var target_position := Vector2(host_scene.get_node("MapRoot/objective_point").global_position)
	var hook := {
		"accepted": true,
		"interaction_id": "station_route_drill_door",
		"interaction_type": "door",
		"fireteam_id": client_fireteam,
		"command_type": "take",
		"required_order": "breach",
		"step_id": "open_station_door",
		"gate_id": "open_station_door",
		"required_state": "door_open",
		"requires_go": true,
		"duration_seconds": 2.0,
		"interaction_radius_world": 72.0,
	}
	var command: Dictionary = DOOR_AUTHORITY_SCRIPT.build_network_command_from_hook(hook, unit_id, "team_alpha", target_position)
	client_sim.rpc_id(1, "request_command", command)
	await _poll_pair(host_api, client_api, 20)
	_assert(int(Dictionary(host_sim.call("get_network_command_contract_snapshot")).get("accepted_count", 0)) == 1, "Host accepts client Door command")
	_assert(not bool(Dictionary(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).get("station_route_drill_door", {})).get("complete", false)), "Door is not complete before arrival")
	var host_unit := _find_unit(host_scene, unit_id)
	_assert(host_unit != null, "Host resolves the commanded unit")
	if host_unit != null:
		host_unit.global_position = target_position + Vector2(160.0, 0.0)
	host_sim.call("_physics_process", 0.1)
	if host_unit != null:
		host_unit.global_position = target_position
	host_sim.call("_physics_process", 0.75)
	var partial_state := Dictionary(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).get("station_route_drill_door", {}))
	print("TASK_1092 partial Door state: %s" % JSON.stringify(partial_state))
	_assert(not bool(partial_state.get("complete", false)) and float(partial_state.get("hold_seconds", 0.0)) > 0.0, "Door Hold starts only after arrival")
	if host_unit != null:
		host_unit.global_position = target_position + Vector2(160.0, 0.0)
	host_sim.call("_physics_process", 0.1)
	var reset_state := Dictionary(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).get("station_route_drill_door", {}))
	print("TASK_1092 reset Door state: %s" % JSON.stringify(reset_state))
	_assert(not bool(reset_state.get("complete", false)) and float(reset_state.get("hold_seconds", -1.0)) == 0.0, "Leaving the Door radius resets visible Hold progress")
	if host_unit != null:
		host_unit.global_position = target_position
	for _index in range(3):
		host_sim.call("_physics_process", 0.75)
	host_sim.call("_physics_process", 0.016)
	await _poll_pair(host_api, client_api, 10)
	var host_state := Dictionary(Dictionary(host_driver.call("get_mission_interaction_runtime_states")).get("station_route_drill_door", {}))
	var client_state := Dictionary(Dictionary(client_driver.call("get_mission_interaction_runtime_states")).get("station_route_drill_door", {}))
	print("TASK_1092 host Door state: %s" % JSON.stringify(host_state))
	_assert(bool(host_state.get("complete", false)), "Authoritative arrival and Hold complete Door")
	_assert(float(host_state.get("hold_seconds", 0.0)) + 0.001 >= 2.0, "Host accumulated the required Hold duration")
	_assert(String(host_state.get("required_state", "")) == "door_open", "Host applies the authored Door state")
	_assert(bool(client_state.get("complete", false)), "Client mirrors runtime-completed Door")
	_assert(Array(client_sim.get("command_queue")).is_empty(), "Client snapshot apply creates no command")
	var rejected_command: Dictionary = command.duplicate(true)
	rejected_command["interaction_id"] = "rejected_foreign_door"
	rejected_command["team_id"] = "team_bravo"
	client_sim.rpc_id(1, "request_command", rejected_command)
	await _poll_pair(host_api, client_api, 16)
	var network_contract := Dictionary(host_sim.call("get_network_command_contract_snapshot"))
	var pending_contract := Dictionary(host_driver.call("get_pending_network_mission_interaction_snapshot"))
	_assert(int(network_contract.get("rejected_count", 0)) >= 1, "Host rejects foreign-team Interaction command")
	_assert(int(pending_contract.get("pending_count", -1)) == 0, "Rejected command creates no pending Interaction")
	host_root.queue_free()
	client_root.queue_free()
	_close_pair(host_peer, client_peer)
	await process_frame


func _configure_authority(simulation_root: Node, client_peer_id: int, fireteam_id: String) -> void:
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team_assignments", {1: "team_alpha", client_peer_id: "team_alpha"})
	simulation_root.call("set_peer_role", 1, "host")
	simulation_root.call("set_peer_role", client_peer_id, "commander")
	simulation_root.call("set_peer_fireteam_assignments", {1: [fireteam_id], client_peer_id: [fireteam_id]})


func _first_unit_id_for_fireteam(scene: Node, fireteam_id: String) -> String:
	for child in scene.get_children():
		if child.has_method("get_fireteam_id") and child.has_method("get_unit_id") and String(child.call("get_fireteam_id")) == fireteam_id:
			return String(child.call("get_unit_id"))
	return ""


func _find_unit(scene: Node, unit_id: String) -> Node2D:
	for child in scene.get_children():
		if child is Node2D and child.has_method("get_unit_id") and String(child.call("get_unit_id")) == unit_id:
			return child as Node2D
	return null


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
