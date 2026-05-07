extends SceneTree

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_227 Main Menu Multiplayer Host Join Lobby Flow ===")
	await _test_main_menu_routes_to_multiplayer_lobby()
	await _test_lobby_controls_and_session_boundaries()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_main_menu_routes_to_multiplayer_lobby() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	var route_snapshot: Dictionary = Dictionary(main_menu.call("get_route_snapshot"))
	_assert(String(route_snapshot.get("multiplayer", "")) == MULTIPLAYER_LOBBY_SCENE_PATH, "Main menu Multiplayer route points to the product lobby")
	_assert(bool(route_snapshot.get("multiplayer_lobby", false)), "Main menu route snapshot marks Multiplayer as lobby flow")
	var multiplayer_button := main_menu.get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons/MultiplayerButton") as Button
	_assert(multiplayer_button != null and String(multiplayer_button.get_meta("route", "")) == MULTIPLAYER_LOBBY_SCENE_PATH, "Multiplayer button carries lobby route metadata")
	_assert(ResourceLoader.exists(MULTIPLAYER_LOBBY_SCENE_PATH), "Multiplayer lobby scene exists")
	_assert(ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) is PackedScene, "Multiplayer lobby scene loads as PackedScene")
	main_menu.queue_free()
	await process_frame


func _test_lobby_controls_and_session_boundaries() -> void:
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate()
	root.add_child(lobby)
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(bool(ui_snapshot.get("has_multiplayer_session", false)), "Lobby owns a MultiplayerSession node")
	_assert(bool(ui_snapshot.get("host_controls_visible", false)), "Lobby exposes Host controls")
	_assert(bool(ui_snapshot.get("join_controls_visible", false)), "Lobby exposes Join controls")
	_assert(bool(ui_snapshot.get("back_visible", false)), "Lobby exposes Back control")
	_assert(not bool(Dictionary(ui_snapshot.get("session", {})).get("has_active_peer", false)), "Lobby starts idle without active peer")
	_assert(lobby.find_child("SimulationRoot", true, false) == null, "Lobby opening does not create gameplay simulation state")

	lobby.call("configure_host_state_for_test", [1, 2])
	await process_frame
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var session: Dictionary = Dictionary(ui_snapshot.get("session", {}))
	_assert(bool(session.get("is_host", false)), "Test host state marks lobby as host")
	_assert(bool(ui_snapshot.get("start_visible", false)), "Host sees Start control")
	_assert(bool(ui_snapshot.get("start_disabled", false)), "Start stays disabled until all peers are ready")
	_assert(not bool(lobby.call("start_mission")), "Host cannot start before ready state")
	_assert(int(Dictionary(lobby.call("get_lobby_ui_snapshot")).get("mission_start_request_count", 0)) == 0, "Rejected start does not emit mission request")

	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	await process_frame
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(not bool(ui_snapshot.get("start_disabled", true)), "Host Start enables once all connected peers are ready")
	_assert(bool(lobby.call("start_mission")), "Host starts mission through MultiplayerSession")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(int(ui_snapshot.get("mission_start_request_count", 0)) == 1, "Lobby records a single session mission-start request")
	var assignments: Dictionary = Dictionary(ui_snapshot.get("last_start_assignments", {}))
	_assert(Dictionary(assignments.get("peer_teams", {})).has(1) and Dictionary(assignments.get("peer_teams", {})).has(2), "Mission start assignments include both peers")

	lobby.call("configure_client_state_for_test", [1, 2])
	await process_frame
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(not bool(Dictionary(ui_snapshot.get("session", {})).get("is_host", true)), "Client test state is not host")
	_assert(not bool(ui_snapshot.get("start_visible", true)), "Client does not see host-only Start control")
	_assert(not bool(lobby.call("start_mission")), "Client cannot start mission")
	lobby.call("disconnect_game")
	await process_frame
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(String(Dictionary(ui_snapshot.get("session", {})).get("connection_state", "")) == "idle", "Disconnect returns lobby to idle state")
	_assert(String(ui_snapshot.get("status_text", "")).contains("Disconnected"), "Disconnect status is visible in UI")
	lobby.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
