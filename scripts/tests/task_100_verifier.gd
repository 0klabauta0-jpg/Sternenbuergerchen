extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_100 Phase Controller Verifier ===")
	await _test_global_phase_creation_and_selection()
	await _test_next_phase_starts_all_fireteam_plans()
	await _test_waypoints_execute_sequentially_per_fireteam()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_global_phase_creation_and_selection() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var phase_before: Dictionary = controller.call("get_phase_state_snapshot")
	var created_phase: int = controller.call("add_global_phase")
	var phase_after: Dictionary = controller.call("get_phase_state_snapshot")
	_assert(int(phase_before.get("phase_count", 0)) == 2, "Phase controller starts with pre-mission plus phase 1")
	_assert(created_phase == 2, "Adding a phase returns the new global phase index")
	_assert(int(phase_after.get("selected_phase_index", -1)) == 2, "Newly added phase becomes the edit context")
	_assert(int(phase_after.get("phase_count", 0)) == 3, "Global phase count grows after + Phase")
	scene.queue_free()
	await process_frame


func _test_next_phase_starts_all_fireteam_plans() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(220.0, 160.0))
	var started: bool = controller.call("advance_to_next_phase")
	var phase_state: Dictionary = controller.call("get_phase_state_snapshot")
	var alpha_driver = scene.get_node("AlphaFlowDriver")
	var charlie_driver = scene.get_node("CharlieFlowDriver")
	_assert(started, "Next Phase advances from pre-mission into phase 1")
	_assert(int(phase_state.get("active_phase_index", -1)) == 1, "Phase 1 becomes globally active after Next Phase")
	_assert(int(Dictionary(alpha_driver.get("last_issued_order")).get("phase", -1)) == 1, "Blue fireteam command is issued through the existing flow driver in phase 1")
	_assert(int(Dictionary(charlie_driver.get("last_issued_order")).get("phase", -1)) == 1, "Gold fireteam command is issued through the existing flow driver in phase 1")
	scene.queue_free()
	await process_frame


func _test_waypoints_execute_sequentially_per_fireteam() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	var blue_anchor = controller.call("_get_selection_anchor_for_fireteam", "blue") as Node2D
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var first_target: Vector2 = blue_anchor.global_position + Vector2(18.0, 0.0)
	var second_target: Vector2 = blue_anchor.global_position + Vector2(42.0, 16.0)
	controller.call("_create_waypoints_for_selected_fireteams", first_target)
	controller.call("_create_waypoints_for_selected_fireteams", second_target)
	var started: bool = controller.call("advance_to_next_phase")
	_assert(started, "Single-fireteam plan starts on Next Phase")
	blue_anchor.global_position = first_target
	for _index in range(4):
		await process_frame
	blue_anchor.global_position = second_target
	for _index in range(4):
		await process_frame
	var plans: Array = controller.call("get_order_plans_snapshot")
	var blue_plan: Dictionary = {}
	for plan_dict in plans:
		if String(Dictionary(plan_dict).get("fireteam_id", "")) == "blue":
			blue_plan = Dictionary(plan_dict)
			break
	var waypoints: Array = Array(blue_plan.get("waypoints", []))
	_assert(String(blue_plan.get("status", "")) == "completed", "Blue phase plan completes after both waypoints finish")
	_assert(int(blue_plan.get("active_waypoint_index", -1)) == 1, "Plan active waypoint index ends on the last waypoint")
	_assert(String(Dictionary(waypoints[0]).get("status", "")) == "completed", "First waypoint is completed before phase end")
	_assert(String(Dictionary(waypoints[1]).get("status", "")) == "completed", "Second waypoint is completed after sequential execution")
	scene.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)