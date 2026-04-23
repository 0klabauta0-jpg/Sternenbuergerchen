extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_099 Waypoint Planning Verifier ===")
	await _test_waypoints_are_created_without_immediate_execution()
	await _test_waypoint_menu_contains_engage()
	await _test_waypoint_command_and_drag_update()
	await _test_waypoint_delete_and_state_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_waypoints_are_created_without_immediate_execution() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var target_before: Vector2 = scene.get_node("TargetMarker").global_position
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(240.0, 190.0))
	var plans: Array = controller.call("get_order_plans_snapshot")
	var visualized: Array = controller.call("get_visualized_waypoints_snapshot")
	_assert(refs.size() == 2, "Selected fireteams each receive a waypoint on planning input")
	_assert(plans.size() == 2, "One FireteamOrderPlan exists per selected fireteam in the active phase")
	_assert(visualized.size() == 2, "Visualizer exposes planned waypoints for the current phase")
	_assert(scene.get_node("TargetMarker").global_position == target_before, "Planning a waypoint does not immediately execute a command or move the target marker")
	scene.queue_free()
	await process_frame


func _test_waypoint_menu_contains_engage() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(250.0, 210.0))
	controller.call("_open_waypoint_command_menu", Vector2(120.0, 120.0), refs, false)
	var menu := scene.get_node("TacticalUI/WaypointCommandMenu") as PopupMenu
	var labels: PackedStringArray = []
	for index in range(menu.item_count):
		if menu.is_item_separator(index):
			continue
		labels.append(menu.get_item_text(index).to_lower())
	_assert(labels.has("engage"), "Waypoint shortcut menu contains engage")
	scene.queue_free()
	await process_frame


func _test_waypoint_command_and_drag_update() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(260.0, 220.0))
	controller.call("_set_waypoint_command_for_targets", refs, "engage")
	var plans: Array = controller.call("get_order_plans_snapshot")
	var engage_count: int = 0
	for plan_dict in plans:
		for waypoint_dict in Array(Dictionary(plan_dict).get("waypoints", [])):
			if String(Dictionary(waypoint_dict).get("command_type", "")) == "engage":
				engage_count += 1
	_assert(engage_count == 2, "Waypoint command type can be changed to engage for all selected fireteams")
	var snapped_target: Vector2 = controller.call("_snap_planning_position_to_tile_center", Vector2(330.0, 260.0))
	controller.call("_update_waypoint_targets", [refs[0]], Vector2(330.0, 260.0))
	plans = controller.call("get_order_plans_snapshot")
	var moved: bool = false
	for plan_dict in plans:
		if String(Dictionary(plan_dict).get("fireteam_id", "")) != String(Dictionary(refs[0]).get("fireteam_id", "")):
			continue
		var first_waypoint: Dictionary = Dictionary(Array(Dictionary(plan_dict).get("waypoints", []))[0])
		moved = Vector2(first_waypoint.get("target_position", Vector2.ZERO)) == snapped_target
	_assert(moved, "Waypoint positions can be dragged and snap to tile centers")
	scene.queue_free()
	await process_frame


func _test_waypoint_delete_and_state_roundtrip() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var refs: Array = controller.call("_create_waypoints_for_selected_fireteams", Vector2(290.0, 240.0))
	var planning_state: Dictionary = controller.call("get_planning_state")
	_assert(Array(planning_state.get("order_plans", [])).size() == 2, "Planning state serializes order plans")
	var deleted: bool = controller.call("_delete_waypoint_targets", [refs[0]])
	_assert(deleted, "Single waypoint targets can be deleted explicitly")
	var remaining_plans: Array = controller.call("get_order_plans_snapshot")
	var remaining_waypoints: int = 0
	for plan_dict in remaining_plans:
		remaining_waypoints += Array(Dictionary(plan_dict).get("waypoints", [])).size()
	_assert(remaining_waypoints == 1, "Deleting one waypoint keeps the remaining plan data intact")
	var scene_copy = await _load_scene()
	var controller_copy = scene_copy.get_node("TacticalController")
	controller_copy.call("set_planning_state", planning_state)
	var copied_visualized: Array = controller_copy.call("get_visualized_waypoints_snapshot")
	_assert(copied_visualized.size() == 2, "Serialized planning state restores visualized waypoints in a fresh mission controller")
	scene.queue_free()
	scene_copy.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(8):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
