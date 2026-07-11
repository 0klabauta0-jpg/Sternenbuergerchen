extends SceneTree

const LOBBY_SCENE: PackedScene = preload("res://scenes/ui/multiplayer_lobby.tscn")
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const ENET_PORT_START: int = 19670
const ENET_PORT_END: int = 19680

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1101 Connected Interaction Reconnect State Recovery ===")
	var fixture: Dictionary = await _create_lobby_pair()
	_assert(bool(fixture.get("connected", false)), "Lobby host and client connect over ENet")
	if not bool(fixture.get("connected", false)):
		quit(1)
		return
	var host_api: MultiplayerAPI = fixture["host_api"]
	var client_api: MultiplayerAPI = fixture["client_api"]
	var host_lobby: Node = fixture["host_lobby"]
	var client_lobby: Node = fixture["client_lobby"]
	var client_session: Node = client_lobby.get_node("MultiplayerSession")
	var reconnect_token: String = String(client_session.get("_local_reconnect_token"))
	var port: int = int(fixture["port"])
	var public_snapshot_text: String = JSON.stringify(host_lobby.call("get_session_snapshot")) + JSON.stringify(client_lobby.call("get_session_snapshot"))
	_assert(not public_snapshot_text.contains(reconnect_token), "Reconnect secret value is absent from public host/client session snapshots")
	_assert(not public_snapshot_text.contains("reconnect_token"), "Reconnect secret field is absent from public host/client session snapshots")
	_assert(bool(host_lobby.call("set_roster_mode", "player_rosters")), "Host enables private player-roster ownership for reconnect coverage")
	await _poll_pair(host_api, client_api, 16)

	_assert(bool(host_lobby.call("set_ready", true)), "Host marks ready")
	_assert(bool(client_lobby.call("set_ready", true)), "Client sends ready")
	await _poll_pair(host_api, client_api, 32)
	_assert(bool(host_lobby.call("start_mission")), "Host starts the connected mission")
	await _poll_pair(host_api, client_api, 32)
	var initial_missions_active: bool = bool(host_lobby.call("has_active_mission")) and bool(client_lobby.call("has_active_mission"))
	_assert(initial_missions_active, "Product lobby launches host and client mission instances")
	if not initial_missions_active:
		_cleanup_fixture(fixture)
		await process_frame
		print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
		quit(1)
		return

	var host_mission: Node = host_lobby.get("_active_mission")
	var client_mission: Node = client_lobby.get("_active_mission")
	var host_driver: Node = host_mission.get_node("CombatLoopDriver")
	var client_driver: Node = client_mission.get_node("CombatLoopDriver")
	var host_simulation: Node = host_mission.get_node("SimulationRoot")
	_assert(bool(host_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Host loads Station Route gates")
	_assert(bool(client_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Initial client loads Station Route gates")
	_complete_interaction(host_driver, "station_computer", "occupy_station_computer", "computer_controlled", "computer", "take", 18.0)
	host_simulation.call("_physics_process", 0.016)
	await _poll_pair(host_api, client_api, 24)
	_assert(_interaction_complete(Dictionary(client_driver.call("get_mission_interaction_runtime_states")), "station_computer"), "Client receives pre-disconnect Computer completion")

	var old_client_peer_id: int = client_api.get_unique_id()
	client_lobby.call("disconnect_game")
	await _poll_pair(host_api, client_api, 32)
	var host_session_after_disconnect: Dictionary = Dictionary(host_lobby.call("get_session_snapshot"))
	_assert(bool(host_lobby.call("has_active_mission")), "Host mission instance survives client disconnect")
	_assert(bool(host_session_after_disconnect.get("mission_started", false)), "Host session remains in mission state after client disconnect")

	_complete_interaction(host_driver, "cargo_landing_hold", "cargo_touchdown_extract", "cargo_departed", "hold_zone", "defend", 12.0)
	host_simulation.call("_physics_process", 0.016)
	_assert(_interaction_complete(Dictionary(host_driver.call("get_mission_interaction_runtime_states")), "cargo_landing_hold"), "Host completes Cargo while client is disconnected")

	client_session.set("_local_reconnect_token", "malformed")
	_assert(bool(client_lobby.call("join_game", "127.0.0.1", port)), "Client starts a malformed-token rejoin probe")
	await _poll_pair(host_api, client_api, 40)
	_assert(not bool(client_lobby.call("has_active_mission")), "Malformed reconnect token receives no mission handoff")
	_assert(int(Dictionary(host_lobby.call("get_session_snapshot")).get("connected_count", 0)) == 1, "Malformed reconnect token receives no host assignment slot")
	client_session.set("_local_reconnect_token", "a".repeat(64) if reconnect_token != "a".repeat(64) else "b".repeat(64))
	_assert(bool(client_lobby.call("join_game", "127.0.0.1", port)), "Client starts a wrong-token rejoin probe")
	await _poll_pair(host_api, client_api, 40)
	_assert(not bool(client_lobby.call("has_active_mission")), "Wrong reconnect token receives no mission handoff")
	_assert(int(Dictionary(host_lobby.call("get_session_snapshot")).get("connected_count", 0)) == 1, "Wrong reconnect token receives no host assignment slot")
	_assert(Array(Dictionary(host_simulation.call("get_snapshot_transport_debug_snapshot")).get("blocked_peer_ids", [])).is_empty(), "Rejected peers leave no blocked snapshot recipients")
	client_session.set("_local_reconnect_token", reconnect_token)
	_assert(bool(client_lobby.call("join_game", "127.0.0.1", port)), "Disconnected client starts rejoin")
	await _poll_pair(host_api, client_api, 64)
	var new_client_peer_id: int = client_api.get_unique_id()
	_assert(new_client_peer_id > 1 and new_client_peer_id != old_client_peer_id, "Rejoined client receives a new ENet peer ID")
	_assert(bool(client_lobby.call("has_active_mission")), "Rejoined client automatically relaunches the active mission")
	_assert(bool(Dictionary(client_lobby.call("get_session_snapshot")).get("mission_started", false)), "Rejoined client session mirrors active mission state")

	var rejoined_mission: Node = client_lobby.get("_active_mission")
	var rejoined_driver: Node = rejoined_mission.get_node("CombatLoopDriver") if rejoined_mission != null else null
	var rejoined_simulation: Node = rejoined_mission.get_node("SimulationRoot") if rejoined_mission != null else null
	_assert(rejoined_driver != null and rejoined_simulation != null, "Rejoined mission exposes runtime and SimulationRoot")
	if rejoined_driver != null and rejoined_simulation != null:
		_assert(bool(rejoined_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Rejoined client loads Station Route gates")
		host_simulation.call("_physics_process", 0.016)
		await _poll_pair(host_api, client_api, 40)
		var recovered_states: Dictionary = Dictionary(rejoined_driver.call("get_mission_interaction_runtime_states"))
		_assert(_interaction_complete(recovered_states, "station_computer"), "Rejoin full snapshot restores Computer completion")
		_assert(_interaction_complete(recovered_states, "cargo_landing_hold"), "Rejoin full snapshot restores Cargo completion completed while offline")
		_assert(Array(rejoined_simulation.get("command_queue")).is_empty() and Array(rejoined_simulation.get("effects_queue")).is_empty(), "Reconnect state recovery creates no client commands or effects")
		_assert(Array(Dictionary(host_simulation.call("get_snapshot_transport_debug_snapshot")).get("blocked_peer_ids", [])).is_empty(), "Mission-ready ACK unblocks the authenticated snapshot recipient")

	var host_assignments: Dictionary = Dictionary(host_lobby.call("get_session_snapshot")).get("assignments", {})
	var peer_fireteams: Dictionary = Dictionary(host_assignments.get("peer_fireteams", {}))
	var peer_rosters: Dictionary = Dictionary(host_assignments.get("peer_rosters", {}))
	_assert(not peer_fireteams.has(old_client_peer_id) or old_client_peer_id == new_client_peer_id, "Disconnected peer assignment is removed")
	_assert(peer_fireteams.has(new_client_peer_id), "Rejoined peer receives current Fireteam assignment")
	_assert(not peer_rosters.has(old_client_peer_id) or old_client_peer_id == new_client_peer_id, "Disconnected peer roster assignment is removed")
	_assert(int(Dictionary(peer_rosters.get(new_client_peer_id, {})).get("owner_peer_id", 0)) == new_client_peer_id, "Rejoined private roster ownership follows the new peer ID")
	_assert(String(Dictionary(peer_rosters.get(new_client_peer_id, {})).get("roster_public_ref", "")).ends_with(":" + str(new_client_peer_id)), "Rejoined public roster reference follows the new peer ID")
	_assert(String(host_simulation.call("get_peer_team", new_client_peer_id)) == String(Dictionary(host_assignments.get("peer_teams", {})).get(new_client_peer_id, "")), "Rejoined client setup refresh reaches active host SimulationRoot assignment")
	var host_authority: Dictionary = Dictionary(host_simulation.call("get_network_command_contract_snapshot"))
	_assert(not Dictionary(host_authority.get("peer_roles", {})).has(old_client_peer_id), "Disconnected peer role is removed from active host SimulationRoot")
	_assert(String(rejoined_simulation.call("get_peer_team", new_client_peer_id)) == String(Dictionary(host_assignments.get("peer_teams", {})).get(new_client_peer_id, "")), "Rejoined client setup refresh reaches active client SimulationRoot assignment")
	var client_authority: Dictionary = Dictionary(rejoined_simulation.call("get_network_command_contract_snapshot"))
	_assert(not Dictionary(client_authority.get("peer_roles", {})).has(old_client_peer_id), "Disconnected peer role is removed from active client SimulationRoot")
	var assigned_team_before_spoof: String = String(host_simulation.call("get_peer_team", new_client_peer_id))
	client_session.rpc_id(1, "request_update_player_setup", {"player_name": "Reconnect", "team_slot": "team_bravo" if assigned_team_before_spoof != "team_bravo" else "team_alpha", "reconnect_token": reconnect_token})
	await _poll_pair(host_api, client_api, 24)
	_assert(String(host_simulation.call("get_peer_team", new_client_peer_id)) == assigned_team_before_spoof, "Client setup RPC cannot rewrite live mission team authority")
	_assert(String(rejoined_simulation.call("get_peer_team", new_client_peer_id)) == assigned_team_before_spoof, "Spoofed setup cannot rewrite rejoined client authority mirror")
	_assert(String(Dictionary(Dictionary(host_lobby.call("get_session_snapshot")).get("assignments", {})).get("peer_teams", {}).get(new_client_peer_id, "")) == assigned_team_before_spoof, "Spoofed setup cannot rewrite host session assignment truth")

	host_driver.emit_signal("combat_resolved", {"result": "victory", "winning_team_id": "team_alpha"})
	await _poll_pair(host_api, client_api, 32)
	_assert(not bool(host_lobby.call("has_active_mission")) and not bool(client_lobby.call("has_active_mission")), "Completed product mission releases host and client mission instances")
	_assert(not bool(Dictionary(host_lobby.call("get_session_snapshot")).get("mission_started", true)) and not bool(Dictionary(client_lobby.call("get_session_snapshot")).get("mission_started", true)), "Completed product mission returns both sessions to lobby state")
	_assert(bool((host_lobby.get_node("Panel") as Control).visible) and bool((client_lobby.get_node("Panel") as Control).visible), "Completed product mission restores both lobby panels")

	_cleanup_fixture(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _create_lobby_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var host_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var host_root := Node.new()
		var client_root := Node.new()
		host_root.name = "Task1101Host"
		client_root.name = "Task1101Client"
		root.add_child(host_root)
		root.add_child(client_root)
		set_multiplayer(host_api, host_root.get_path())
		set_multiplayer(client_api, client_root.get_path())
		var host_lobby: Node = LOBBY_SCENE.instantiate()
		var client_lobby: Node = LOBBY_SCENE.instantiate()
		host_lobby.name = "Lobby"
		client_lobby.name = "Lobby"
		host_root.add_child(host_lobby)
		client_root.add_child(client_lobby)
		await process_frame
		if not bool(host_lobby.call("host_game", port)):
			host_root.queue_free()
			client_root.queue_free()
			await process_frame
			continue
		if not bool(client_lobby.call("join_game", "127.0.0.1", port)):
			host_root.queue_free()
			client_root.queue_free()
			await process_frame
			continue
		for _index in range(180):
			host_api.poll()
			client_api.poll()
			await process_frame
			if int(Dictionary(host_lobby.call("get_session_snapshot")).get("connected_count", 0)) >= 2:
				return {
					"connected": true,
					"port": port,
					"host_api": host_api,
					"client_api": client_api,
					"host_root": host_root,
					"client_root": client_root,
					"host_lobby": host_lobby,
					"client_lobby": client_lobby,
				}
		host_root.queue_free()
		client_root.queue_free()
		await process_frame
	return {"connected": false}


func _poll_pair(host_api: MultiplayerAPI, client_api: MultiplayerAPI, frames: int) -> void:
	for _index in range(frames):
		host_api.poll()
		client_api.poll()
		await process_frame


func _complete_interaction(driver: Node, interaction_id: String, step_id: String, required_state: String, interaction_type: String, command_type: String, duration: float) -> void:
	driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": interaction_id,
		"state": "complete",
		"complete": true,
		"progress": 1.0,
		"hold_seconds": duration,
		"duration_seconds": duration,
		"fireteam_id": "red",
		"team_id": "team_alpha",
		"step_id": step_id,
		"gate_id": step_id,
		"required_state": required_state,
		"interaction_type": interaction_type,
		"command_type": command_type,
	})


func _interaction_complete(states: Dictionary, interaction_id: String) -> bool:
	return bool(Dictionary(states.get(interaction_id, {})).get("complete", false))


func _cleanup_fixture(fixture: Dictionary) -> void:
	var client_lobby: Node = fixture.get("client_lobby", null)
	var host_lobby: Node = fixture.get("host_lobby", null)
	if client_lobby != null:
		client_lobby.call("disconnect_game")
	if host_lobby != null:
		host_lobby.call("disconnect_game")
	var client_root: Node = fixture.get("client_root", null)
	var host_root: Node = fixture.get("host_root", null)
	if client_root != null:
		client_root.queue_free()
	if host_root != null:
		host_root.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
