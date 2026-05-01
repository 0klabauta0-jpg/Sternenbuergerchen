extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_102 Ad-Hoc Order Controller Verifier ===")
	await _test_ad_hoc_requires_combat_contact()
	await _test_ad_hoc_does_not_mutate_planned_waypoint_count()
	await _test_manual_return_to_plan_clears_active_ad_hoc()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_ad_hoc_requires_combat_contact() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var issued_without_contact: bool = controller.call("issue_ad_hoc_order", "focus_fire", Vector2(240.0, 180.0))
	_assert(not issued_without_contact, "Ad-hoc order is blocked when the selected fireteam has no active contact")
	var alpha = scene.get_node("UnitAlpha")
	if alpha != null and alpha.has_method("set_contact_state"):
		alpha.call("set_contact_state", true, "enemy_01")
	var issued_with_contact: bool = controller.call("issue_ad_hoc_order", "focus_fire", Vector2(240.0, 180.0))
	_assert(issued_with_contact, "Ad-hoc order can be issued once contact is active")
	scene.queue_free()
	await process_frame


func _test_ad_hoc_does_not_mutate_planned_waypoint_count() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(220.0, 160.0))
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(260.0, 180.0))
	var plans_before: Array = controller.call("get_order_plans_snapshot")
	var waypoint_count_before: int = _count_waypoints_for_fireteam(plans_before, "blue")
	var started: bool = controller.call("advance_to_next_phase")
	_assert(started, "Planned phase starts before injecting ad-hoc order")
	var alpha = scene.get_node("UnitAlpha")
	if alpha != null and alpha.has_method("set_contact_state"):
		alpha.call("set_contact_state", true, "enemy_01")
	var issued: bool = controller.call("issue_ad_hoc_order", "flank", Vector2(280.0, 170.0))
	_assert(issued, "Ad-hoc flank can be issued during an active phase")
	var plans_after: Array = controller.call("get_order_plans_snapshot")
	var waypoint_count_after: int = _count_waypoints_for_fireteam(plans_after, "blue")
	_assert(waypoint_count_after == waypoint_count_before, "Ad-hoc order does not get appended into the fireteam planning waypoints")
	scene.queue_free()
	await process_frame


func _test_manual_return_to_plan_clears_active_ad_hoc() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(220.0, 160.0))
	controller.call("advance_to_next_phase")
	var alpha = scene.get_node("UnitAlpha")
	if alpha != null and alpha.has_method("set_contact_state"):
		alpha.call("set_contact_state", true, "enemy_01")
	controller.call("issue_ad_hoc_order", "hold_till_last_man", Vector2(220.0, 160.0))
	var active_before: Array = controller.call("get_active_ad_hoc_orders_snapshot")
	_assert(active_before.size() == 1, "Hold-till-last-man remains active after issuing the ad-hoc order")
	var returned: bool = controller.call("return_selected_fireteams_to_plan")
	_assert(returned, "Manual Return to Plan is available and succeeds")
	var active_after: Array = controller.call("get_active_ad_hoc_orders_snapshot")
	_assert(active_after.is_empty(), "Manual Return to Plan clears active ad-hoc orders immediately")
	scene.queue_free()
	await process_frame


func _count_waypoints_for_fireteam(plan_dicts: Array, fireteam_id: String) -> int:
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan_dict: Dictionary = Dictionary(plan_variant)
		if String(plan_dict.get("fireteam_id", "")) != fireteam_id:
			continue
		return Array(plan_dict.get("waypoints", [])).size()
	return 0


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
