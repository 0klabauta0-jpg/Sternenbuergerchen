extends SceneTree

const MISSION_TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HTML_PATH: String = "res://docs/reports/fireteam_command_drill_decision_guide.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_417 Fireteam Waypoint Completion Cleanup ===")
	_test_completed_first_waypoint_is_removed_and_next_index_shifts()
	_test_completed_middle_waypoint_keeps_followup_index()
	_test_completed_last_waypoint_finishes_plan_and_serializes_empty()
	_test_docs_capture_cleanup_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_completed_first_waypoint_is_removed_and_next_index_shifts() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	var plan = _make_plan(["wp_a", "wp_b", "wp_c"], 0)
	var next_index: int = int(controller.call("_complete_and_remove_waypoint_from_plan", plan, 0))
	_assert(next_index == 0, "Removing the first waypoint shifts the next executable waypoint to index 0")
	_assert(plan.waypoints.size() == 2, "Completed first waypoint is removed from the plan")
	_assert(String(plan.waypoints[0].waypoint_id) == "wp_b", "Old second waypoint becomes the first visible waypoint")
	_assert(int(plan.active_waypoint_index) == -1, "Plan has no stale active index after removal")
	controller.free()


func _test_completed_middle_waypoint_keeps_followup_index() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	var plan = _make_plan(["wp_a", "wp_b", "wp_c"], 1)
	var next_index: int = int(controller.call("_complete_and_remove_waypoint_from_plan", plan, 1))
	_assert(next_index == 1, "Removing a middle waypoint points at the old following waypoint")
	_assert(plan.waypoints.size() == 2, "Completed middle waypoint is removed from the plan")
	_assert(String(plan.waypoints[0].waypoint_id) == "wp_a", "Previous waypoint remains in place")
	_assert(String(plan.waypoints[1].waypoint_id) == "wp_c", "Old following waypoint keeps the shifted index")
	controller.free()


func _test_completed_last_waypoint_finishes_plan_and_serializes_empty() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	var plan = _make_plan(["wp_last"], 0)
	var next_index: int = int(controller.call("_complete_and_remove_waypoint_from_plan", plan, 0))
	_assert(next_index == -1, "Removing the last waypoint returns no follow-up index")
	_assert(plan.waypoints.is_empty(), "Last completed waypoint leaves no stale waypoint entry")
	_assert(String(plan.status) == FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED, "Empty plan is marked completed")
	controller.set("_order_plans_by_key", {"drill|0": plan})
	var serialized_plans: Array = Array(controller.call("_serialize_order_plans"))
	_assert(serialized_plans.is_empty(), "Empty completed plan is not serialized for visuals")
	controller.free()


func _test_docs_capture_cleanup_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var html_text: String = _read_text(HTML_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("TASK_417 - Fireteam Waypoint Completion Cleanup"), "TASK_417 task file exists")
	_assert(status_text.contains("TASK_417 - Fireteam Waypoint Completion Cleanup"), "Implementation status documents TASK_417")
	_assert(roadmap_text.contains("TASK_417 - Fireteam Waypoint Completion Cleanup"), "Roadmap lists TASK_417")
	_assert(html_text.contains("Waypoint-Abarbeitung"), "Decision guide documents waypoint cleanup behavior")
	_assert(controller_text.contains("_complete_and_remove_waypoint_from_plan"), "Mission controller owns completed-waypoint removal")


func _make_plan(waypoint_ids: Array, active_index: int):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_drill_p0"
	plan.fireteam_id = "drill"
	plan.phase = 0
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_ACTIVE
	plan.active_waypoint_index = active_index
	for waypoint_index in range(waypoint_ids.size()):
		var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
		waypoint.waypoint_id = String(waypoint_ids[waypoint_index])
		waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
		waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE if waypoint_index == active_index else FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		waypoint.target_position = Vector2(waypoint_index * 16.0, 32.0)
		plan.waypoints.append(waypoint)
	return plan


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
