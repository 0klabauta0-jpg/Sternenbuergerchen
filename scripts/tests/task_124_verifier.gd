extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_124 Area Feedback in #17 Verifier ===")
	await _test_planned_defend_area_feedback_includes_size_and_waiting_contact()
	await _test_active_defend_area_feedback_includes_security_and_go_wait()
	await _test_attack_and_take_area_feedback_is_distinct()
	await _test_multi_selection_area_feedback_stays_compact()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_planned_defend_area_feedback_includes_size_and_waiting_contact() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(120.0, 120.0), Vector2(420.0, 300.0), "defend")
	var text: String = String(controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(text.contains("AREA DEFEND"), "Planned defend feedback names the Area command type")
	_assert(text.contains("Felder"), "Planned defend feedback exposes the Area size")
	_assert(text.contains("geplant"), "Planned defend feedback exposes planning state")
	_assert(text.contains("wartet auf Kontakt"), "Planned defend feedback uses a readable no-contact status")
	scene.queue_free()
	await process_frame


func _test_active_defend_area_feedback_includes_security_and_go_wait() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(120.0, 120.0), Vector2(420.0, 300.0), "defend")
	controller.call("execute_selected_fireteam_orders")
	var active_snapshot: Array = controller.call("get_active_area_defense_snapshot")
	var state: Dictionary = Dictionary(active_snapshot[0]) if not active_snapshot.is_empty() else {}
	for assignment_variant in Array(state.get("assignments", [])):
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(controller.call("_get_fireteam_units", "blue", true), String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_defense_execution", 0.25)
	controller.call("refresh_fireteam_security_state")
	await process_frame
	var text: String = String(controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(text.contains("AREA DEFEND"), "Active defend feedback still names the command type")
	_assert(text.contains("SEC 360") or text.contains("SEC DIR"), "Active defend feedback summarizes security mode")
	_assert(text.contains("WARTET AUF GO"), "Active defend feedback exposes GO wait state")
	_assert(not text.contains("Zentrum"), "Area feedback avoids old debug-like center wording")
	scene.queue_free()
	await process_frame


func _test_attack_and_take_area_feedback_is_distinct() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(900.0, 900.0), Vector2(1080.0, 1040.0), "take")
	controller.call("execute_selected_fireteam_orders")
	var active_snapshot: Array = controller.call("get_active_area_attack_snapshot")
	var state: Dictionary = Dictionary(active_snapshot[0]) if not active_snapshot.is_empty() else {}
	var approach_text: String = String(controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(approach_text.contains("AREA TAKE"), "Take Area feedback names take distinctly")
	_assert(approach_text.contains("0/") and approach_text.contains("Felder gesichert"), "Take Area feedback exposes secured field progress")
	_assert(approach_text.contains("nimmt Gebiet"), "Take Area feedback exposes active take mode")
	for assignment_variant in Array(state.get("assignments", [])):
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_unit(controller.call("_get_fireteam_units", "blue", true), String(assignment.get("unit_id", "")))
		if unit is Node2D:
			(unit as Node2D).global_position = Vector2(assignment.get("target_position", (unit as Node2D).global_position))
	controller.call("_update_area_attack_execution", 0.25)
	controller.call("refresh_fireteam_security_state")
	await process_frame
	var secured_text: String = String(controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(secured_text.contains("AREA TAKE"), "Secured take feedback keeps the command label")
	_assert(secured_text.contains("Felder gesichert") and not secured_text.contains("0/"), "Secured take feedback advances field progress")
	_assert(secured_text.contains("WARTET AUF GO"), "Secured take feedback exposes GO wait state")
	scene.queue_free()
	await process_frame

	var attack_scene = await _load_scene()
	var attack_controller = attack_scene.get_node("TacticalController")
	attack_controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	attack_controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(900.0, 900.0), Vector2(1080.0, 1040.0), "engage")
	attack_controller.call("execute_selected_fireteam_orders")
	var attack_text: String = String(attack_controller.call("_build_fireteam_waypoint_info_text", "blue"))
	_assert(attack_text.contains("AREA ATTACK"), "Engage Area feedback is labeled as attack")
	_assert(attack_text.contains("Approach"), "Attack Area feedback exposes approach direction")
	attack_scene.queue_free()
	await process_frame


func _test_multi_selection_area_feedback_stays_compact() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue", "gold"]), false)
	controller.call("create_area_order_for_selected_fireteams_from_world_rect", Vector2(120.0, 120.0), Vector2(420.0, 300.0), "defend")
	var text: String = String(controller.call("_build_selected_waypoint_info_text"))
	var lines: PackedStringArray = text.split("\n", false)
	_assert(lines.size() == 2, "Multi-selection feedback uses one compact line per fireteam")
	_assert(text.contains("BLUE AREA DEFEND") and text.contains("GOLD AREA DEFEND"), "Multi-selection feedback keeps fireteam labels visible")
	_assert(not text.contains("Debug") and not text.contains("Zentrum"), "Multi-selection feedback avoids noisy debug wording")
	scene.queue_free()
	await process_frame


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


func _find_unit(units: Array, unit_id: String):
	for unit in units:
		if unit != null and unit.has_method("get_unit_id") and String(unit.call("get_unit_id")) == unit_id:
			return unit
	return null


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
