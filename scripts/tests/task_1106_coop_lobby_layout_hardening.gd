extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")
const TARGET_VIEWPORT := Vector2(1280.0, 720.0)
const TARGET_PANEL_SIZE := Vector2(720.0, 560.0)

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1106 Coop Lobby Layout Hardening ===")
	var lobby_viewport := SubViewport.new()
	lobby_viewport.size = Vector2i(TARGET_VIEWPORT)
	lobby_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(lobby_viewport)
	var lobby: Control = LOBBY_SCENE.instantiate()
	lobby_viewport.add_child(lobby)
	await _wait_frames(3)
	var panel := lobby.get_node("Panel") as Control
	var scroll := lobby.get_node("Panel/Margin/VBox/LobbyBodyScroll") as ScrollContainer
	var peer_label := scroll.get_node("Content/PeerLabel") as Label
	var assignment_label := scroll.get_node("Content/AssignmentLabel") as Label
	_assert(_rect_inside(panel.get_global_rect(), TARGET_VIEWPORT), "Idle lobby panel stays inside 1280x720")
	_assert(_near_vec(panel.size, TARGET_PANEL_SIZE), "Idle lobby panel keeps 720x560 size")
	_assert(panel.get_global_rect().encloses(scroll.get_global_rect()) and scroll.size.y < TARGET_PANEL_SIZE.y, "Idle setup scroll stays inside the fixed panel and leaves room for actions")

	lobby.call("_apply_session_snapshot", _build_three_peer_snapshot())
	await _wait_frames(3)
	print("DIAG panel=%s min=%s scroll=%s scroll_min=%s vscroll=%s peer_min=%s assignment_min=%s" % [
		panel.get_global_rect(), panel.get_combined_minimum_size(), scroll.size, scroll.get_combined_minimum_size(),
		scroll.get_v_scroll_bar().visible, peer_label.get_combined_minimum_size(), assignment_label.get_combined_minimum_size(),
	])
	_assert(_rect_inside(panel.get_global_rect(), TARGET_VIEWPORT), "Three-peer lobby panel stays inside 1280x720")
	_assert(_near_vec(panel.size, TARGET_PANEL_SIZE), "Three-peer content cannot enlarge the fixed panel")
	_assert(panel.get_global_rect().encloses(scroll.get_global_rect()) and scroll.size.y < TARGET_PANEL_SIZE.y, "Three-peer setup scroll stays clipped to panel with fixed actions outside it")
	_assert(scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "Lobby keeps automatic vertical scrolling")
	_assert(scroll.get_v_scroll_bar().visible, "Long three-peer lobby content exposes vertical scrolling")
	_assert(peer_label.size.x <= scroll.size.x + 0.5 and assignment_label.size.x <= scroll.size.x + 0.5, "Role labels cannot force horizontal panel growth")
	_assert(String(lobby.call("get_lobby_ui_snapshot").get("peer_text", "")).contains("ZUSCHAUER"), "Layout hardening preserves spectator readability")

	lobby_viewport.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _build_three_peer_snapshot() -> Dictionary:
	return {
		"status_text": "Connected (3/3). Ready 2/3.",
		"local_peer_id": 2,
		"has_active_peer": true,
		"can_toggle_ready": true,
		"can_disconnect": true,
		"is_host": false,
		"local_ready": true,
		"mission_started": false,
		"peers": [
			_peer(1, "Commander Host With A Deliberately Long Callsign", "host", ["blue"], true),
			_peer(2, "Mara Gold", "commander", ["gold"], true),
			_peer(3, "Waiting Observer With Another Long Callsign", "spectator", [], false),
		],
		"assignments": {
			"team_play_mode": "coop",
			"peer_teams": {1: "team_alpha", 2: "team_alpha", 3: "team_alpha"},
			"peer_roles": {1: "host", 2: "commander", 3: "spectator"},
			"peer_fireteams": {1: PackedStringArray(["blue"]), 2: PackedStringArray(["gold"]), 3: PackedStringArray()},
		},
	}


func _peer(peer_id: int, display_name: String, role_id: String, fireteams: Array, ready: bool) -> Dictionary:
	return {
		"peer_id": peer_id,
		"display_name": display_name,
		"team_id": "team_alpha",
		"role_id": role_id,
		"fireteam_ids": fireteams,
		"ready": ready,
	}


func _rect_inside(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= viewport_size.x + 0.5 and rect.end.y <= viewport_size.y + 0.5


func _near_vec(actual: Vector2, expected: Vector2) -> bool:
	return actual.distance_to(expected) <= 0.5


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
