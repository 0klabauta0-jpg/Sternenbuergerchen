extends SceneTree

const LOBBY := preload("res://scenes/ui/multiplayer_lobby.tscn")
const BASE := "Panel/Margin/VBox/"
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
		await _test_actions(size)
	print("RESULTS: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("PASS: native R2 lobby actions")
	quit(1 if _failed > 0 else 0)


func _test_actions(size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(viewport)
	var lobby := LOBBY.instantiate() as Control
	viewport.add_child(lobby)
	await _wait(5)
	var bounds := Rect2(Vector2.ZERO, Vector2(size))
	for path in ["HostJoinGrid/HostButton", "HostJoinGrid/HostPortSpinBox", "HostJoinGrid/JoinButton", "HostJoinGrid/JoinAddressLineEdit", "HostJoinGrid/JoinPortSpinBox", "SessionRow/BackButton"]:
		var control := lobby.get_node(BASE + path) as Control
		_check(_reachable(control, bounds), "%s idle %s is visible within every clipping ancestor" % [size, path])
	var body := lobby.find_child("LobbyBodyScroll", true, false) as ScrollContainer
	_check(body != null and body.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "%s setup has a separate native scroll body" % size)
	var ownership_label := lobby.get_node_or_null(BASE + "LobbyBodyScroll/Content/RosterModeRow/RosterModeLabel") as Label
	_check(ownership_label != null and String(ownership_label.get_meta("help_id", "")) == "multiplayer.roster_ownership", "%s moved roster ownership label retains contextual help" % size)
	lobby.call("configure_host_state_for_test", [1, 2])
	await _wait(5)
	var start := lobby.get_node(BASE + "SessionRow/StartMissionButton") as Button
	_check(start.disabled and not bool(lobby.call("start_mission")), "%s original not-ready start gate is retained" % size)
	for name in ["ReadyButton", "StartMissionButton", "DisconnectButton", "BackButton"]:
		var button := lobby.get_node(BASE + "SessionRow/" + name) as Button
		_check(_reachable(button, bounds) and not button.pressed.get_connections().is_empty(), "%s existing %s remains reachable with its callback" % [size, name])
	var footer := lobby.get_node(BASE + "SessionRow") as Control
	var host_join := lobby.get_node(BASE + "HostJoinGrid") as Control
	var footer_before := footer.get_global_rect()
	var host_before := host_join.get_global_rect()
	if body != null:
		_check(body.get_v_scroll_bar().visible, "%s long setup exposes actual scrolling" % size)
		body.scroll_vertical = int(body.get_v_scroll_bar().max_value)
		await _wait(3)
		_check(body.scroll_vertical > 0, "%s setup can actually scroll" % size)
		_check(footer.get_global_rect().is_equal_approx(footer_before) and host_join.get_global_rect().is_equal_approx(host_before), "%s scrolling leaves connection/session actions fixed" % size)
		_check(_reachable(start, bounds), "%s host start remains reachable after setup scrolling" % size)
	var badges := lobby.get_node(BASE + "TeamBadgeRow") as HBoxContainer
	_check(badges.get_child_count() >= 2, "%s actual session supplies both side badges" % size)
	for child in badges.get_children():
		var badge := child as Label
		if badge != null:
			_check(not badge.clip_text and _reachable(badge, bounds), "%s complete side badge is not horizontally clipped" % size)
	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	await _wait(2)
	_check(not start.disabled, "%s existing ready consensus enables host start" % size)
	lobby.call("configure_client_state_for_test", [1, 2])
	await _wait(2)
	_check(not start.visible and not bool(lobby.call("start_mission")), "%s client cannot expose or trigger host-only start" % size)
	viewport.queue_free()
	await _wait(2)


func _reachable(control: Control, bounds: Rect2) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	if not bounds.encloses(rect):
		print("LOBBY R2 OUTSIDE %s rect=%s bounds=%s" % [control.name, rect, bounds])
		return false
	var parent := control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents and not parent.get_global_rect().encloses(rect):
			print("LOBBY R2 CLIPPED %s rect=%s ancestor=%s bounds=%s" % [control.name, rect, parent.name, parent.get_global_rect()])
			return false
		parent = parent.get_parent()
	return true


func _wait(count: int) -> void:
	for _frame in range(count):
		await process_frame


func _check(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		push_error("FAIL: " + message)
