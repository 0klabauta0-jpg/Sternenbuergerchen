extends SceneTree

const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const LOBBY_TEST_SCENE: PackedScene = preload("res://scenes/tests/lobby_test.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_167 Multiplayer Session Verifier ===")
	await _test_host_session_tracks_peers_and_ready_state()
	await _test_start_is_authority_only()
	await _test_session_assignments_feed_simulation_root_contract()
	await _test_disconnect_resets_session_state()
	await _test_lobby_screen_uses_session_adapter()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_host_session_tracks_peers_and_ready_state() -> void:
	var session: Node = _make_session()
	session.call("configure_host_state_for_test", [2])
	var snapshot: Dictionary = session.call("get_session_snapshot")
	_assert(bool(snapshot.get("is_host", false)), "Host session marks the local authority")
	_assert(int(snapshot.get("connected_count", 0)) == 2, "Host session tracks the host and one joined peer")
	_assert(not bool(snapshot.get("can_start_mission", true)), "Mission cannot start before ready states are complete")

	session.call("set_peer_ready_for_test", 1, true)
	session.call("set_peer_ready_for_test", 2, true)
	snapshot = session.call("get_session_snapshot")
	_assert(int(snapshot.get("ready_count", 0)) == 2, "Ready state is tracked per connected peer")
	_assert(bool(snapshot.get("can_start_mission", false)), "Host can start once all peers are ready")
	await _cleanup_session(session)


func _test_start_is_authority_only() -> void:
	var host_session: Node = _make_session()
	host_session.call("configure_host_state_for_test", [2])
	host_session.call("set_peer_ready_for_test", 1, true)
	host_session.call("set_peer_ready_for_test", 2, true)
	var started_assignment_events: Array = []
	host_session.mission_start_requested.connect(func(assignments: Dictionary) -> void:
		started_assignment_events.append(assignments.duplicate(true))
	)
	var host_started: bool = bool(host_session.call("request_start_mission"))
	var host_snapshot: Dictionary = host_session.call("get_session_snapshot")
	_assert(host_started, "Host can request mission start after readiness")
	_assert(bool(host_snapshot.get("mission_started", false)), "Host session records mission started")
	_assert(not started_assignment_events.is_empty(), "Host mission start emits assignments")
	await _cleanup_session(host_session)

	var client_session: Node = _make_session()
	client_session.call("configure_client_state_for_test", [1, 2])
	client_session.call("set_peer_ready_for_test", 1, true)
	client_session.call("set_peer_ready_for_test", 2, true)
	var client_started: bool = bool(client_session.call("request_start_mission"))
	_assert(not client_started, "Client-side session cannot authoritatively start the mission")
	await _cleanup_session(client_session)


func _test_session_assignments_feed_simulation_root_contract() -> void:
	var session: Node = _make_session()
	session.call("configure_host_state_for_test", [2])
	var assignments: Dictionary = session.call("build_session_assignments")
	var peer_teams: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	var peer_roles: Dictionary = Dictionary(assignments.get("peer_roles", {}))
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	_assert(String(peer_teams.get(1, "")) == "team_alpha", "Host receives team_alpha")
	_assert(String(peer_teams.get(2, "")) == "team_bravo", "Joined peer receives team_bravo")
	_assert(String(peer_roles.get(1, "")) == "host", "Host receives host command role")
	_assert(String(peer_roles.get(2, "")) == "commander", "Joined peer receives commander role in the multiplayer smoke setup")
	_assert(PackedStringArray(peer_fireteams.get(1, PackedStringArray())).has("blue"), "Host fireteam assignment includes blue")

	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.call("set_peer_team_assignments", peer_teams)
	for peer_id_variant in peer_roles.keys():
		simulation_root.call("set_peer_role", int(peer_id_variant), String(peer_roles[peer_id_variant]))
	simulation_root.call("set_peer_fireteam_assignments", peer_fireteams)
	var contract_snapshot: Dictionary = simulation_root.call("get_network_command_contract_snapshot")
	_assert(String(Dictionary(contract_snapshot.get("peer_teams", {})).get(2, "")) == "team_bravo", "SimulationRoot accepts session team assignments")
	_assert(String(Dictionary(contract_snapshot.get("peer_roles", {})).get(2, "")) == "commander", "SimulationRoot accepts session role assignments")
	simulation_root.free()
	await _cleanup_session(session)


func _test_disconnect_resets_session_state() -> void:
	var session: Node = _make_session()
	session.call("configure_host_state_for_test", [2])
	session.call("disconnect_session", "Manual disconnect.")
	var snapshot: Dictionary = session.call("get_session_snapshot")
	_assert(String(snapshot.get("connection_state", "")) == "idle", "Disconnect resets the session state")
	_assert(int(snapshot.get("connected_count", 99)) == 0, "Disconnect clears peer state")
	_assert(String(snapshot.get("status_text", "")) == "Manual disconnect.", "Disconnect keeps the visible status reason")
	await _cleanup_session(session)


func _test_lobby_screen_uses_session_adapter() -> void:
	var lobby := LOBBY_TEST_SCENE.instantiate()
	get_root().add_child(lobby)
	await process_frame
	_assert(lobby.get_node_or_null("MultiplayerSession") != null, "Lobby screen creates the productive MultiplayerSession adapter")
	_assert(lobby.get_node_or_null("Panel/Margin/VBox/SessionRow/ReadyButton") != null, "Lobby screen exposes a ready control")
	_assert(String(lobby.call("get_status_text")).contains("Ready"), "Lobby screen reads its status from the session")
	lobby.queue_free()
	await process_frame


func _make_session() -> Node:
	var session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	session.name = "MultiplayerSessionUnderTest"
	get_root().add_child(session)
	return session


func _cleanup_session(session: Node) -> void:
	if session != null:
		session.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
