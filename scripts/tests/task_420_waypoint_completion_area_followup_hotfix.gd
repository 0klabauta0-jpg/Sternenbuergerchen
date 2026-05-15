extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const MISSION_TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_420 Waypoint Completion Area Followup Hotfix ===")
	_test_last_waypoint_removes_empty_plan()
	await _test_move_completion_starts_pending_defend_area()
	_test_docs_capture_hotfix()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_last_waypoint_removes_empty_plan() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	var plan = _make_plan("drill", 1, ["wp_last"], 0)
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})

	var next_index: int = int(controller.call("_complete_and_remove_waypoint_from_plan", plan, 0))
	var stored_plans: Dictionary = Dictionary(controller.get("_order_plans_by_key"))
	var serialized_plans: Array = Array(controller.call("_serialize_order_plans"))

	_assert(next_index == -1, "Completing the last waypoint returns no follow-up waypoint")
	_assert(plan.waypoints.is_empty(), "Last waypoint is removed from the plan object")
	_assert(String(plan.status) == FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED, "Empty plan is marked completed")
	_assert(not stored_plans.has(plan_key), "Empty completed plan is removed from the plan registry")
	_assert(serialized_plans.is_empty(), "Empty completed plan is absent from order visual serialization")
	controller.free()


func _test_move_completion_starts_pending_defend_area() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes TacticalController")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var anchor = controller.call("_get_selection_anchor_for_fireteam", "drill")
	_assert(anchor is Node2D, "Drill fireteam exposes an anchor")
	if not (anchor is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	var anchor_position: Vector2 = (anchor as Node2D).global_position
	var plan = _make_plan("drill", 1, ["wp_move"], 0)
	plan.waypoints[0].target_position = anchor_position
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	controller.set("_phase_execution_by_fireteam", {
		"drill": {
			"phase": 1,
			"waypoint_index": 0,
			"hold_elapsed": 0.0,
			"resolved_target_position": anchor_position,
		},
	})
	var area_targets: Array = Array(controller.call(
		"create_area_order_for_fireteams_from_world_rect",
		PackedStringArray(["drill"]),
		anchor_position + Vector2(80.0, -40.0),
		anchor_position + Vector2(176.0, 56.0),
		AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND
	))
	_assert(area_targets.size() == 1, "Pending defend area is created for drill")

	controller.call("_update_active_phase_execution", 0.25)
	await _wait_frames(4)

	var stored_plans: Dictionary = Dictionary(controller.get("_order_plans_by_key"))
	var phase_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam"))
	var defense_execution: Dictionary = Dictionary(controller.get("_area_defense_execution_by_fireteam"))
	var area_orders: Dictionary = Dictionary(controller.get("_area_orders_by_id"))
	var area_order_id: String = String(Dictionary(area_targets[0]).get("area_order_id", ""))
	var area_order = area_orders.get(area_order_id, null)

	_assert(not stored_plans.has(plan_key), "Move completion removes the empty plan before area follow-up")
	_assert(not phase_execution.has("drill"), "Completed move no longer keeps phase execution active")
	_assert(defense_execution.has("drill"), "Pending defend area starts after move completion")
	_assert(area_order != null and String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_ACTIVE, "Defend area order becomes active")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_hotfix() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("TASK_420 - Waypoint Completion Area Followup Hotfix"), "TASK_420 task file exists")
	_assert(status_text.contains("TASK_420 - Waypoint Completion Area Followup Hotfix"), "Implementation status documents TASK_420")
	_assert(roadmap_text.contains("TASK_420 - Waypoint Completion Area Followup Hotfix"), "Roadmap lists TASK_420")
	_assert(controller_text.contains("_activate_next_area_order_or_default"), "Controller has explicit area-order follow-up helper")
	_assert(controller_text.contains("_remove_empty_completed_order_plan"), "Controller removes empty completed plans")


func _make_plan(fireteam_id: String, phase: int, waypoint_ids: Array, active_index: int):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p%d" % [fireteam_id, phase]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_ACTIVE
	plan.active_waypoint_index = active_index
	for waypoint_index in range(waypoint_ids.size()):
		var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
		waypoint.waypoint_id = String(waypoint_ids[waypoint_index])
		waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
		waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE if waypoint_index == active_index else FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		waypoint.target_position = Vector2(waypoint_index * 32.0, 24.0)
		plan.waypoints.append(waypoint)
	return plan


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
