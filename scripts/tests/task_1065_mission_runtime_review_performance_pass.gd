extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MINI_CARD_HOST_PATH: String = "TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1065 Mission Runtime Review Performance Pass ===")
	await _test_member_status_row_delta_guard()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_member_status_row_delta_guard() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(16)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var card_host := scene.get_node_or_null(MINI_CARD_HOST_PATH) as Control
	_assert(controller != null and card_host != null, "Mission fixture exposes controller and mini-card host")
	if controller == null or card_host == null:
		await _cleanup(scene)
		return
	_assert(controller.has_method("get_mission_fireteam_card_delta_rendering_snapshot"), "Controller exposes mini-card delta diagnostics")
	if not controller.has_method("get_mission_fireteam_card_delta_rendering_snapshot"):
		await _cleanup(scene)
		return

	var card := _first_mini_card(card_host)
	var fireteam_id: String = String(card.get_meta("fireteam_id", "")).strip_edges().to_lower() if card != null else ""
	_assert(not fireteam_id.is_empty(), "Fixture provides a named Fireteam mini-card")
	if fireteam_id.is_empty():
		await _cleanup(scene)
		return
	controller.set("_suppression_state_by_fireteam", {fireteam_id: _suppression_state(0.0)})
	controller.call("_refresh_fireteam_mini_cards")
	card = _find_mini_card(card_host, fireteam_id)
	var member_row := card.find_child("FireteamMemberStatusRow", true, false) as Control if card != null else null
	var before: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
	_assert(member_row != null, "Mini-card exposes the member-status row")
	if member_row == null:
		await _cleanup(scene)
		return
	var row_id: int = member_row.get_instance_id()
	var row_snapshot: Dictionary = Dictionary(member_row.call("get_row_snapshot"))

	controller.set("_suppression_state_by_fireteam", {fireteam_id: _suppression_state(1.0)})
	controller.call("_refresh_fireteam_mini_cards")
	var after_suppression: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
	var refreshed_card := _find_mini_card(card_host, fireteam_id)
	var refreshed_row := refreshed_card.find_child("FireteamMemberStatusRow", true, false) as Control if refreshed_card != null else null
	var suppression_bar := refreshed_card.find_child("MiniSuppressionBar", true, false) as ProgressBar if refreshed_card != null else null
	_assert(refreshed_row != null and refreshed_row.get_instance_id() == row_id, "Suppression keeps the member-row instance")
	_assert(refreshed_row != null and Dictionary(refreshed_row.call("get_row_snapshot")) == row_snapshot, "Suppression keeps the unchanged member snapshot")
	_assert(suppression_bar != null and is_equal_approx(suppression_bar.value, 1.0), "Suppression still updates its live bar")
	_assert(int(after_suppression.get("member_status_row_skip_count", -1)) > int(before.get("member_status_row_skip_count", -1)), "Unchanged member status skips a redundant redraw")
	_assert(int(after_suppression.get("member_status_row_apply_count", -1)) == int(before.get("member_status_row_apply_count", -2)), "Unchanged member status does not reapply the row")

	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var unit := units[0] as Node if not units.is_empty() else null
	_assert(unit != null, "Fixture provides a Fireteam member for a live status change")
	if unit != null and unit.has_method("apply_damage"):
		unit.call("apply_damage", 1, {"source": "task_1065_member_row_delta"})
		controller.call("_refresh_fireteam_mini_cards")
		var after_member_change: Dictionary = Dictionary(controller.call("get_mission_fireteam_card_delta_rendering_snapshot"))
		_assert(int(after_member_change.get("member_status_row_apply_count", -1)) > int(after_suppression.get("member_status_row_apply_count", 0)), "Changed member status reapplies the row")
		_assert(bool(after_member_change.get("read_only", false)), "Delta diagnostics stay read-only")
		_assert(not bool(after_member_change.get("ui_sets_gameplay_truth", true)), "Delta diagnostics do not own gameplay truth")
	await _cleanup(scene)


func _suppression_state(value: float) -> Dictionary:
	return {"value": value, "threshold": 2.0, "is_suppressed": false, "is_heavily_suppressed": false, "applied_level": 0, "hold_until_msec": 0}


func _first_mini_card(card_host: Control) -> Control:
	if card_host == null:
		return null
	for child_variant in card_host.get_children():
		var child := child_variant as Control
		if child != null and not String(child.get_meta("fireteam_id", "")).strip_edges().is_empty():
			return child
	return null


func _find_mini_card(card_host: Control, fireteam_id: String) -> Control:
	if card_host == null:
		return null
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	for child_variant in card_host.get_children():
		var child := child_variant as Control
		if child != null and String(child.get_meta("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return child
	return null


func _cleanup(scene: Node) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
