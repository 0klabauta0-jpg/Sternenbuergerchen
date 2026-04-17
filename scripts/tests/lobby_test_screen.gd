extends Control

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MAX_PLAYERS: int = 2
const DEFAULT_PORT: int = 7777
const HOST_TEAM_ID: String = "team_alpha"
const CLIENT_TEAM_ID: String = "team_bravo"

var _active_mission = null
var _last_mission_result: Dictionary = {}


func _ready() -> void:
	_connect_ui_signals()
	_connect_multiplayer_signals()
	_refresh_lobby_controls()
	_set_status_text("Ready. Host or join a local test session.")
	_get_debrief_screen().visible = false


func host_game(port: int = DEFAULT_PORT) -> bool:
	_release_active_mission()
	_hide_debrief()

	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(port, MAX_PLAYERS)
	if error != OK:
		_set_status_text("Host failed: %s" % error_string(error))
		return false

	multiplayer.multiplayer_peer = peer
	_refresh_lobby_controls()
	_refresh_host_status(true)
	return true


func join_game(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	_release_active_mission()
	_hide_debrief()

	var peer := ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, port)
	if error != OK:
		_set_status_text("Join failed: %s" % error_string(error))
		return false

	multiplayer.multiplayer_peer = peer
	_refresh_lobby_controls()
	_set_status_text("Connecting to %s:%d..." % [address, port])
	return true


func start_mission() -> bool:
	if not _can_host_start_mission():
		return false

	var assignments: Dictionary = _build_peer_team_assignments()
	_launch_mission(assignments)
	_receive_start_mission.rpc(assignments)
	_refresh_host_status(true)
	return true


func has_active_mission() -> bool:
	return _active_mission != null


func get_status_text() -> String:
	var status_label := get_node_or_null("Panel/Margin/VBox/StatusLabel") as Label
	if status_label == null:
		return ""

	return status_label.text


func get_last_mission_result() -> Dictionary:
	return _last_mission_result.duplicate(true)


@rpc("authority", "reliable")
func _receive_lobby_status(status_text: String, can_start: bool) -> void:
	if multiplayer.is_server():
		return

	_set_status_text(status_text)
	_refresh_lobby_controls(can_start)


@rpc("authority", "reliable")
func _receive_start_mission(assignments: Dictionary) -> void:
	if multiplayer.is_server():
		return

	_launch_mission(assignments)


func _connect_ui_signals() -> void:
	var host_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/HostButton") as Button
	var join_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/JoinButton") as Button
	var start_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/StartMissionButton") as Button
	var debrief_screen = _get_debrief_screen()
	if host_button != null and not host_button.pressed.is_connected(_on_host_pressed):
		host_button.pressed.connect(_on_host_pressed)
	if join_button != null and not join_button.pressed.is_connected(_on_join_pressed):
		join_button.pressed.connect(_on_join_pressed)
	if start_button != null and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if debrief_screen != null and not debrief_screen.return_to_fob_requested.is_connected(_on_debrief_return_requested):
		debrief_screen.return_to_fob_requested.connect(_on_debrief_return_requested)
	if debrief_screen != null and not debrief_screen.return_to_homebase_requested.is_connected(_on_debrief_return_requested):
		debrief_screen.return_to_homebase_requested.connect(_on_debrief_return_requested)


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_host_pressed() -> void:
	host_game()


func _on_join_pressed() -> void:
	join_game()


func _on_start_pressed() -> void:
	start_mission()


func _on_debrief_return_requested() -> void:
	_hide_debrief()
	_set_lobby_visible(true)
	_refresh_local_status()
	_refresh_lobby_controls()


func _on_peer_connected(_peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	_refresh_host_status(true)


func _on_peer_disconnected(_peer_id: int) -> void:
	_handle_disconnect("Peer disconnected. Returning to lobby.")


func _on_connected_to_server() -> void:
	_set_status_text("Connected to host. Waiting for start...")
	_refresh_lobby_controls(false)


func _on_connection_failed() -> void:
	_handle_disconnect("Connection failed. Back in lobby.")


func _on_server_disconnected() -> void:
	_handle_disconnect("Disconnected from host. Back in lobby.")


func _launch_mission(assignments: Dictionary) -> void:
	_release_active_mission()
	_hide_debrief()

	var mission_host = _get_mission_host()
	if mission_host == null:
		_set_status_text("Mission host node missing.")
		return

	var mission_instance = MISSION_TEST_SCENE.instantiate()
	var simulation_root = mission_instance.get_node_or_null("SimulationRoot")
	if simulation_root != null:
		simulation_root.set("is_server_authoritative", true)
		if simulation_root.has_method("set_peer_team_assignments"):
			simulation_root.call("set_peer_team_assignments", assignments)

	mission_host.add_child(mission_instance)
	_active_mission = mission_instance
	_connect_mission_signals(mission_instance)
	_set_lobby_visible(false)
	_set_status_text("Mission running...")


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
	_show_debrief(mission_result)
	_refresh_local_status()
	_refresh_lobby_controls()


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


func _handle_disconnect(message: String) -> void:
	_release_active_mission()
	_hide_debrief()
	_shutdown_multiplayer_peer()
	_set_lobby_visible(true)
	_set_status_text(message)
	_refresh_lobby_controls()


func _shutdown_multiplayer_peer() -> void:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null:
		return

	multiplayer.multiplayer_peer = null


func _refresh_local_status() -> void:
	if multiplayer.multiplayer_peer == null:
		_set_status_text("Ready. Host or join a local test session.")
		return

	if multiplayer.is_server():
		_refresh_host_status(true)
		return

	_set_status_text("Connected (2/2)")


func _refresh_host_status(propagate_to_clients: bool) -> void:
	var connected_players: int = 1 + multiplayer.get_peers().size()
	var can_start: bool = connected_players >= MAX_PLAYERS and _active_mission == null
	var status_text: String = "Waiting for players... (%d/%d)" % [connected_players, MAX_PLAYERS]
	if connected_players >= MAX_PLAYERS:
		status_text = "Connected (%d/%d)" % [connected_players, MAX_PLAYERS]

	_set_status_text(status_text)
	_refresh_lobby_controls(can_start)
	if propagate_to_clients and multiplayer.is_server() and multiplayer.multiplayer_peer != null:
		_receive_lobby_status.rpc(status_text, can_start)


func _refresh_lobby_controls(can_start_override: bool = false) -> void:
	var host_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/HostButton") as Button
	var join_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/JoinButton") as Button
	var start_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/StartMissionButton") as Button
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	var has_active_peer: bool = peer != null and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED
	var is_host: bool = has_active_peer and multiplayer.is_server()
	var can_start: bool = can_start_override or _can_host_start_mission()

	if host_button != null:
		host_button.disabled = has_active_peer
	if join_button != null:
		join_button.disabled = has_active_peer
	if start_button != null:
		start_button.visible = is_host
		start_button.disabled = not can_start


func _can_host_start_mission() -> bool:
	var peer: MultiplayerPeer = multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false

	return multiplayer.is_server() and multiplayer.get_peers().size() >= (MAX_PLAYERS - 1) and _active_mission == null


func _build_peer_team_assignments() -> Dictionary:
	var assignments: Dictionary = {
		1: HOST_TEAM_ID,
	}
	for peer_id in multiplayer.get_peers():
		assignments[int(peer_id)] = CLIENT_TEAM_ID

	return assignments


func _set_status_text(status_text: String) -> void:
	var status_label := get_node_or_null("Panel/Margin/VBox/StatusLabel") as Label
	if status_label == null:
		return

	status_label.text = status_text


func _set_lobby_visible(is_visible: bool) -> void:
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = is_visible


func _get_mission_host():
	return get_node_or_null("MissionHost")


func _get_debrief_screen():
	return get_node_or_null("DebriefScreen")
