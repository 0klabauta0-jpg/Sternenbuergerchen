extends SceneTree

const FOB_TEST_SCENE: PackedScene = preload("res://scenes/meta/fob_test_screen.tscn")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_314 FOB NPC Pool Window Left Of Fireteams ===")
	await _test_pool_window_is_fixed_left_of_fireteams()
	await _test_unassigned_pool_feeds_fireteam_assignment()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_pool_window_is_fixed_left_of_fireteams() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var screen: Control = FOB_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(4)

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout")
	var pool_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AvailablePanel") as Control
	var fireteam_panel := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel") as Control
	var pool_header := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHeaderLabel") as Label
	_assert(pool_panel != null and pool_panel.visible, "#09 NPC pool window is visible in FOB")
	_assert(_node_rect_matches_actual(pool_panel, layout.get("unassigned_pool")), "#09 NPC pool has a fixed FullHD window")
	_assert(_node_rect_matches_actual(fireteam_panel, layout.get("fireteams")), "#10 Fireteams keeps its fixed window")
	_assert(_control_left_of(pool_panel, fireteam_panel), "#09 NPC pool sits left of #10 Fireteams")
	_assert(pool_header != null and pool_header.text == "#09 NPC POOL", "#09 NPC pool has an explicit header")
	_assert(bool(pool_panel.get_meta("drop_light_unassigned_pool_window", false)), "#09 is marked as the FOB unassigned pool window")

	screen.queue_free()
	await _wait_frames(2)


func _test_unassigned_pool_feeds_fireteam_assignment() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var screen: Control = FOB_TEST_SCENE.instantiate()
	screen.visible = true
	root.add_child(screen)
	await _wait_frames(2)

	screen.call("set_available_units", [
		{"unit_id": "unit_a", "display_name": "Anja", "role_name": "Lead"},
		{"unit_id": "unit_b", "display_name": "Milo", "role_name": "Medic"},
		{"unit_id": "unit_c", "display_name": "Talia", "role_name": "Scout"},
	])
	screen.call(
		"configure_transfer",
		PackedStringArray(["unit_a", "unit_b", "unit_c"]),
		PackedStringArray(["", "ft1", ""]),
		[{"id": "ft1", "label": "Blue Team", "lead_unit_id": "unit_b"}]
	)
	await _wait_frames(4)

	var pool_list := screen.get_node_or_null("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableScroll/AvailableList") as VBoxContainer
	_assert(pool_list != null and pool_list.get_child_count() == 2, "Unassigned FOB pool renders only operators not already in a fireteam")
	var board_before: Dictionary = Dictionary(screen.call("get_fireteam_assignment_board_snapshot"))
	_assert(_unassigned_card_count(board_before) == 2, "Board snapshot mirrors two unassigned operators")

	screen.call("assign_unit_to_fireteam_for_test", "unit_a", "ft1")
	await _wait_frames(4)
	var board_assigned: Dictionary = Dictionary(screen.call("get_fireteam_assignment_board_snapshot"))
	_assert(pool_list.get_child_count() == 1, "Assigning from #09 to #10 removes the operator from the pool")
	_assert(_first_frame_member_count(board_assigned) == 2, "Assigning from #09 adds the operator to the fireteam frame")

	screen.call("remove_unit_to_unassigned_for_test", "unit_a")
	await _wait_frames(4)
	var board_removed: Dictionary = Dictionary(screen.call("get_fireteam_assignment_board_snapshot"))
	_assert(pool_list.get_child_count() == 2, "Removing from #10 returns the operator to the #09 pool")
	_assert(_unassigned_card_count(board_removed) == 2, "Board snapshot mirrors the returned unassigned operator")

	screen.queue_free()
	await _wait_frames(2)


func _node_rect_matches_actual(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	return _approximately_equal(control.global_position.x, float(rect.position.x)) \
		and _approximately_equal(control.global_position.y, float(rect.position.y)) \
		and _approximately_equal(control.size.x, float(rect.size.x)) \
		and _approximately_equal(control.size.y, float(rect.size.y))


func _control_left_of(left: Control, right: Control) -> bool:
	if left == null or right == null:
		return false
	return left.global_position.x + left.size.x <= right.global_position.x + 0.5


func _unassigned_card_count(board: Dictionary) -> int:
	return Array(Dictionary(board.get("unassigned", {})).get("cards", [])).size()


func _first_frame_member_count(board: Dictionary) -> int:
	var frames: Array = Array(board.get("frames", []))
	if frames.is_empty():
		return 0
	return Array(Dictionary(frames[0]).get("member_cards", [])).size()


func _approximately_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.5


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
