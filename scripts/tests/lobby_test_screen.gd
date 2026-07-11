extends Control

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const DEFAULT_PORT: int = 7777
const DEFAULT_ADDRESS: String = "127.0.0.1"

var _active_mission = null
var _last_mission_result: Dictionary = {}
var _session: Node = null


func _ready() -> void:
	_ensure_multiplayer_session()
	_connect_ui_signals()
	_get_debrief_screen().visible = false
	_set_lobby_visible(true)
	_refresh_from_session()


func host_game(port: int = DEFAULT_PORT) -> bool:
	_release_active_mission()
	_hide_debrief()
	_set_lobby_visible(true)
	return bool(_session.call("start_host", port))


func join_game(address: String = DEFAULT_ADDRESS, port: int = DEFAULT_PORT) -> bool:
	_release_active_mission()
	_hide_debrief()
	_set_lobby_visible(true)
	return bool(_session.call("join_session", address, port))


func disconnect_game() -> void:
	_session.call("disconnect_session")


func set_ready(ready: bool) -> bool:
	return bool(_session.call("set_local_ready", ready))


func start_mission() -> bool:
	return bool(_session.call("request_start_mission"))


func has_active_mission() -> bool:
	return _active_mission != null


func get_status_text() -> String:
	var status_label := get_node_or_null("Panel/Margin/VBox/StatusLabel") as Label
	if status_label == null:
		return ""
	return status_label.text


func get_team_readability_text() -> String:
	var label := get_node_or_null("Panel/Margin/VBox/TeamReadabilityLabel") as Label
	if label == null:
		return ""
	return label.text


func get_last_mission_result() -> Dictionary:
	return _last_mission_result.duplicate(true)


func get_session_snapshot() -> Dictionary:
	return Dictionary(_session.call("get_session_snapshot")).duplicate(true)


func _ensure_multiplayer_session() -> void:
	_session = get_node_or_null("MultiplayerSession")
	if _session == null:
		_session = MULTIPLAYER_SESSION_SCRIPT.new()
		_session.name = "MultiplayerSession"
		add_child(_session)

	if not _session.session_snapshot_changed.is_connected(_on_session_snapshot_changed):
		_session.session_snapshot_changed.connect(_on_session_snapshot_changed)
	if not _session.mission_start_requested.is_connected(_on_session_mission_start_requested):
		_session.mission_start_requested.connect(_on_session_mission_start_requested)
	if not _session.mission_assignments_changed.is_connected(_on_session_mission_assignments_changed):
		_session.mission_assignments_changed.connect(_on_session_mission_assignments_changed)
	if not _session.mission_rejoin_peer_block_changed.is_connected(_on_session_rejoin_peer_block_changed):
		_session.mission_rejoin_peer_block_changed.connect(_on_session_rejoin_peer_block_changed)
	if not _session.session_disconnected.is_connected(_on_session_disconnected):
		_session.session_disconnected.connect(_on_session_disconnected)


func _connect_ui_signals() -> void:
	var host_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/HostButton") as Button
	var join_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/JoinButton") as Button
	var start_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/StartMissionButton") as Button
	var ready_button := get_node_or_null("Panel/Margin/VBox/SessionRow/ReadyButton") as Button
	var disconnect_button := get_node_or_null("Panel/Margin/VBox/SessionRow/DisconnectButton") as Button
	var debrief_screen = _get_debrief_screen()
	if host_button != null and not host_button.pressed.is_connected(_on_host_pressed):
		host_button.pressed.connect(_on_host_pressed)
	if join_button != null and not join_button.pressed.is_connected(_on_join_pressed):
		join_button.pressed.connect(_on_join_pressed)
	if start_button != null and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if ready_button != null and not ready_button.pressed.is_connected(_on_ready_pressed):
		ready_button.pressed.connect(_on_ready_pressed)
	if disconnect_button != null and not disconnect_button.pressed.is_connected(_on_disconnect_pressed):
		disconnect_button.pressed.connect(_on_disconnect_pressed)
	if debrief_screen != null and not debrief_screen.return_to_fob_requested.is_connected(_on_debrief_return_requested):
		debrief_screen.return_to_fob_requested.connect(_on_debrief_return_requested)
	if debrief_screen != null and not debrief_screen.return_to_homebase_requested.is_connected(_on_debrief_return_requested):
		debrief_screen.return_to_homebase_requested.connect(_on_debrief_return_requested)


func _on_host_pressed() -> void:
	host_game()


func _on_join_pressed() -> void:
	join_game()


func _on_start_pressed() -> void:
	start_mission()


func _on_ready_pressed() -> void:
	var snapshot: Dictionary = get_session_snapshot()
	set_ready(not bool(snapshot.get("local_ready", false)))


func _on_disconnect_pressed() -> void:
	disconnect_game()


func _on_debrief_return_requested() -> void:
	_hide_debrief()
	_set_lobby_visible(true)
	_session.call("complete_mission")
	_refresh_from_session()


func _on_session_snapshot_changed(snapshot: Dictionary) -> void:
	_apply_session_snapshot(snapshot)


func _on_session_mission_start_requested(assignments: Dictionary) -> void:
	_launch_mission(assignments)


func _on_session_mission_assignments_changed(assignments: Dictionary) -> void:
	if _active_mission == null:
		return
	_apply_session_assignments_to_simulation_root(_active_mission.get_node_or_null("SimulationRoot"), assignments)


func _on_session_rejoin_peer_block_changed(peer_id: int, blocked: bool) -> void:
	if _active_mission == null:
		return
	var simulation_root: Node = _active_mission.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_snapshot_peer_blocked"):
		simulation_root.call("set_snapshot_peer_blocked", peer_id, blocked)


func _on_session_disconnected(_message: String) -> void:
	_release_active_mission()
	_hide_debrief()
	_set_lobby_visible(true)
	_refresh_from_session()


func _launch_mission(assignments: Dictionary) -> void:
	_release_active_mission()
	_hide_debrief()

	var mission_host = _get_mission_host()
	if mission_host == null:
		_set_status_text("Mission host node missing.")
		return

	var mission_instance = MISSION_TEST_SCENE.instantiate()
	var simulation_root = mission_instance.get_node_or_null("SimulationRoot")
	_apply_session_assignments_to_simulation_root(simulation_root, assignments)

	mission_host.add_child(mission_instance)
	_active_mission = mission_instance
	if not bool(get_session_snapshot().get("is_host", false)):
		_session.rpc_id(1, "notify_mission_runtime_ready")
	_connect_mission_signals(mission_instance)
	_set_lobby_visible(false)
	_set_status_text("Mission running...")
	_refresh_lobby_controls()


func _apply_session_assignments_to_simulation_root(simulation_root: Node, assignments: Dictionary) -> void:
	if simulation_root == null:
		return

	simulation_root.set("is_server_authoritative", true)
	var team_assignments: Dictionary = Dictionary(assignments.get("peer_teams", assignments)).duplicate(true)
	if simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", team_assignments)

	if simulation_root.has_method("set_peer_role_assignments"):
		simulation_root.call("set_peer_role_assignments", Dictionary(assignments.get("peer_roles", {})).duplicate(true))
	elif simulation_root.has_method("set_peer_role"):
		var role_assignments: Dictionary = Dictionary(assignments.get("peer_roles", {}))
		for peer_id_variant in role_assignments.keys():
			simulation_root.call("set_peer_role", int(peer_id_variant), String(role_assignments[peer_id_variant]))

	if simulation_root.has_method("set_peer_fireteam_assignments"):
		simulation_root.call("set_peer_fireteam_assignments", Dictionary(assignments.get("peer_fireteams", {})).duplicate(true))


func _connect_mission_signals(mission_instance: Node) -> void:
	if mission_instance == null:
		return

	var combat_driver = mission_instance.get_node_or_null("CombatLoopDriver")
	if combat_driver == null:
		return

	if not combat_driver.combat_resolved.is_connected(_on_mission_combat_resolved):
		combat_driver.combat_resolved.connect(_on_mission_combat_resolved)


func _on_mission_combat_resolved(mission_result: Dictionary) -> void:
	_last_mission_result = mission_result.duplicate(true)
	_release_active_mission()
	_session.call("complete_mission")
	_show_debrief(mission_result)
	_refresh_from_session()


func _show_debrief(mission_result: Dictionary) -> void:
	var debrief_screen = _get_debrief_screen()
	if debrief_screen == null:
		return

	debrief_screen.set_mission_result(mission_result)
	debrief_screen.visible = true


func _hide_debrief() -> void:
	var debrief_screen = _get_debrief_screen()
	if debrief_screen == null:
		return

	debrief_screen.visible = false


func _release_active_mission() -> void:
	if _active_mission == null:
		return

	_active_mission.queue_free()
	_active_mission = null


func _refresh_from_session() -> void:
	_apply_session_snapshot(get_session_snapshot())


func _apply_session_snapshot(snapshot: Dictionary) -> void:
	_set_status_text(String(snapshot.get("status_text", "Ready. Host or join a local test session.")))
	_set_team_readability_text(_build_team_readability_text(snapshot))
	_refresh_lobby_controls(snapshot)


func _refresh_lobby_controls(snapshot: Dictionary = {}) -> void:
	var host_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/HostButton") as Button
	var join_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/JoinButton") as Button
	var start_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/StartMissionButton") as Button
	var ready_button := get_node_or_null("Panel/Margin/VBox/SessionRow/ReadyButton") as Button
	var disconnect_button := get_node_or_null("Panel/Margin/VBox/SessionRow/DisconnectButton") as Button
	var current_snapshot: Dictionary = snapshot if not snapshot.is_empty() else get_session_snapshot()
	var has_active_peer: bool = bool(current_snapshot.get("has_active_peer", false))
	var can_toggle_ready: bool = bool(current_snapshot.get("can_toggle_ready", false))
	var can_disconnect: bool = bool(current_snapshot.get("can_disconnect", false))
	var is_host: bool = bool(current_snapshot.get("is_host", false))
	var can_start: bool = bool(current_snapshot.get("can_start_mission", false))
	var local_ready: bool = bool(current_snapshot.get("local_ready", false))

	if host_button != null:
		host_button.disabled = has_active_peer or has_active_mission()
	if join_button != null:
		join_button.disabled = has_active_peer or has_active_mission()
	if start_button != null:
		start_button.visible = is_host
		start_button.disabled = not can_start
	if ready_button != null:
		ready_button.visible = has_active_peer or can_toggle_ready
		ready_button.disabled = not can_toggle_ready
		ready_button.text = "Unready" if local_ready else "Ready"
	if disconnect_button != null:
		disconnect_button.visible = has_active_peer or can_disconnect
		disconnect_button.disabled = not can_disconnect


func _set_status_text(status_text: String) -> void:
	var status_label := get_node_or_null("Panel/Margin/VBox/StatusLabel") as Label
	if status_label == null:
		return

	status_label.text = status_text


func _build_team_readability_text(snapshot: Dictionary) -> String:
	var direct_summary: String = String(snapshot.get("team_readability_summary", "")).strip_edges()
	if not direct_summary.is_empty():
		return direct_summary
	var team_readability: Dictionary = Dictionary(snapshot.get("team_readability", {}))
	return String(team_readability.get("summary_text", "")).strip_edges()


func _set_team_readability_text(text: String) -> void:
	var label := _get_or_create_team_readability_label()
	if label == null:
		return
	label.text = text
	label.visible = not text.strip_edges().is_empty()


func _get_or_create_team_readability_label() -> Label:
	var vbox := get_node_or_null("Panel/Margin/VBox") as VBoxContainer
	if vbox == null:
		return null
	var label := vbox.get_node_or_null("TeamReadabilityLabel") as Label
	if label != null:
		return label
	label = Label.new()
	label.name = "TeamReadabilityLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.modulate = Color(0.72, 0.88, 1.0, 0.95)
	vbox.add_child(label)
	return label


func _set_lobby_visible(is_visible: bool) -> void:
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = is_visible


func _get_mission_host():
	return get_node_or_null("MissionHost")


func _get_debrief_screen():
	return get_node_or_null("DebriefScreen")
