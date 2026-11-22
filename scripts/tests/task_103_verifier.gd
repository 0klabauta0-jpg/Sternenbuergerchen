extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_103 Suppression + Return-to-Plan Verifier ===")
	await _test_suppression_builds_on_hits_and_interrupts_waypoint()
	await _test_auto_resume_after_stabilization()
	await _test_manual_return_to_plan_without_active_ad_hoc()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit(1 if _failed > 0 else 0)
func _test_suppression_builds_on_hits_and_interrupts_waypoint() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(240.0, 170.0))
	controller.call("advance_to_next_phase")
	var unit_alpha = scene.get_node("UnitAlpha")
	if unit_alpha != null and unit_alpha.has_method("set_contact_state"):
		unit_alpha.call("set_contact_state", true, "enemy_01")
	# FT-0b: Unterdrueckung kommt nicht mehr aus Lebenspunkt-Differenzen, sondern aus aufgeloesten Schuessen auf die
	# Gruppe (Fahrer) und laeuft in Spiel-Ticks. Der Test fuettert Treffer und taktet den Fahrer selbst.
	var driver = scene.get_node("CombatLoopDriver")
	scene.get_node("SimulationRoot").set_physics_process(false)
	scene.get_node("SimulationRoot").set_process(false)
	var tick: int = 30000
	for _i in range(60):
		driver.call("note_suppression_shot", unit_alpha, 18, true)
		tick += 30
		driver.call("_advance_suppression", tick)
		controller.call("_update_fireteam_suppression", 0.016)
		if int(driver.call("get_suppression_level_for_unit", unit_alpha)) >= 3:
			break
	var suppression: Dictionary = controller.call("get_fireteam_suppression_snapshot", "blue")
	_assert(bool(suppression.get("is_suppressed", false)), "Blue fireteam enters suppressed state after taking resolved shots in contact")
	var plan_status: String = _get_first_waypoint_status(controller.call("get_order_plans_snapshot"), "blue")
	_assert(plan_status == "interrupted", "Active waypoint is marked interrupted while fireteam is suppressed")
	scene.queue_free()
	await process_frame


func _test_auto_resume_after_stabilization() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(220.0, 160.0))
	controller.call("advance_to_next_phase")
	var unit_alpha = scene.get_node("UnitAlpha")
	if unit_alpha != null and unit_alpha.has_method("set_contact_state"):
		unit_alpha.call("set_contact_state", true, "enemy_01")
	if unit_alpha != null and unit_alpha.has_method("apply_damage"):
		unit_alpha.call("apply_damage", 10, {"effect_type": "damage"})
	for _i in range(8):
		await process_frame
	if unit_alpha != null and unit_alpha.has_method("set_contact_state"):
		unit_alpha.call("set_contact_state", false, "")
	for _i in range(120):
		await process_frame
	var suppression: Dictionary = controller.call("get_fireteam_suppression_snapshot", "blue")
	_assert(not bool(suppression.get("is_suppressed", false)), "Suppression decays automatically after contact stops")
	var plan_status: String = _get_blue_plan_status(controller.call("get_order_plans_snapshot"))
	_assert(plan_status == "active" or plan_status == "pending" or plan_status == "completed", "Fireteam auto-resumes into the phase plan after stabilization")
	scene.queue_free()
	await process_frame


func _test_manual_return_to_plan_without_active_ad_hoc() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", Vector2(220.0, 160.0))
	controller.call("advance_to_next_phase")
	var unit_alpha = scene.get_node("UnitAlpha")
	if unit_alpha != null and unit_alpha.has_method("set_contact_state"):
		unit_alpha.call("set_contact_state", true, "enemy_01")
	if unit_alpha != null and unit_alpha.has_method("apply_damage"):
		unit_alpha.call("apply_damage", 12, {"effect_type": "damage"})
	for _i in range(8):
		await process_frame
	var returned: bool = controller.call("return_selected_fireteams_to_plan")
	_assert(returned, "Manual Return to Plan also works while no ad-hoc order is active")
	scene.queue_free()
	await process_frame


func _get_first_waypoint_status(plan_dicts: Array, fireteam_id: String) -> String:
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan_dict: Dictionary = Dictionary(plan_variant)
		if String(plan_dict.get("fireteam_id", "")) != fireteam_id:
			continue
		var waypoints: Array = Array(plan_dict.get("waypoints", []))
		if waypoints.is_empty():
			return ""
		return String(Dictionary(waypoints[0]).get("status", ""))
	return ""


func _get_blue_plan_status(plan_dicts: Array) -> String:
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan_dict: Dictionary = Dictionary(plan_variant)
		if String(plan_dict.get("fireteam_id", "")) == "blue":
			return String(plan_dict.get("status", ""))
	return ""


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
