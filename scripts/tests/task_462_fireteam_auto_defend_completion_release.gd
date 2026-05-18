extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_462_fireteam_auto_defend_completion_release.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_462 Fireteam Auto Defend Completion Release ===")
	await _test_soft_reached_last_waypoint_falls_to_def_360()
	await _test_go_continues_soft_reached_active_waypoint()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_soft_reached_last_waypoint_falls_to_def_360() -> void:
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
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(leader is Node2D, "Drill fireteam exposes a leader")
	if not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	var plan = _make_plan("drill", 1, [(leader as Node2D).global_position + Vector2(180.0, -64.0)])
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	var activated: bool = bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0))
	_assert(activated, "Last Move waypoint starts movement execution")
	_move_units_near_current_targets(controller, "drill", 34.0)
	controller.call("_update_active_phase_execution", 0.25)
	await _wait_frames(4)

	var stored_plans: Dictionary = Dictionary(controller.get("_order_plans_by_key"))
	var phase_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam"))
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	var security_state: Dictionary = Dictionary(controller.call("get_fireteam_security_state", "drill"))
	var units: Array = Array(controller.call("_get_fireteam_units", "drill", true))
	_assert(not stored_plans.has(plan_key), "Soft-reached last waypoint removes the empty plan")
	_assert(not phase_execution.has("drill"), "Soft-reached last waypoint clears active phase execution")
	_assert(movement_state.is_empty(), "Soft-reached last waypoint resets movement execution")
	_assert(_all_units_hold_auto_defend(units), "No follow-up order issues auto_defend hold commands")
	_assert(String(security_state.get("security_mode", "")) == "360", "Default follow-up security state is DEF 360")
	_assert(_count_distinct_map_facing_angles(units) >= 3, "Default DEF 360 distributes visible facing angles")
	scene.queue_free()
	await _wait_frames(2)


func _test_go_continues_soft_reached_active_waypoint() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes controller for GO continue")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)
	var leader = controller.call("_resolve_fireteam_leader_for_behavior", "drill")
	_assert(leader is Node2D, "GO continue test has a leader")
	if not (leader is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return

	var first_target: Vector2 = (leader as Node2D).global_position + Vector2(164.0, -48.0)
	var second_target: Vector2 = first_target + Vector2(140.0, 32.0)
	var plan = _make_plan("drill", 1, [first_target, second_target])
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	var activated: bool = bool(controller.call("_activate_next_waypoint_for_plan", plan, "drill", 0))
	_assert(activated, "First Move waypoint starts before GO continue")
	_move_units_near_current_targets(controller, "drill", 34.0)
	var continued: bool = bool(controller.call("execute_selected_fireteam_orders"))
	await _wait_frames(4)

	var stored_plan = Dictionary(controller.get("_order_plans_by_key")).get(plan_key, null)
	var phase_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam"))
	var execution_state: Dictionary = Dictionary(phase_execution.get("drill", {}))
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))
	_assert(continued, "GO accepts soft-reached active waypoint as continue action")
	_assert(stored_plan != null and stored_plan.waypoints.size() == 1, "GO removes the soft-reached first waypoint")
	if stored_plan != null and stored_plan.waypoints.size() == 1:
		_assert(String(stored_plan.waypoints[0].waypoint_id) == "wp_1", "GO keeps the second waypoint as the remaining plan")
		_assert(String(stored_plan.waypoints[0].status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE, "GO activates the second waypoint")
	_assert(int(execution_state.get("waypoint_index", -1)) == 0, "GO tracks the shifted active waypoint index")
	_assert(not movement_state.is_empty(), "GO starts movement execution for the shifted waypoint")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_462 - Fireteam Auto Defend Completion Release"), "TASK_462 task file exists")
	_assert(status_text.contains("TASK_462 - Fireteam Auto Defend Completion Release"), "Implementation status documents TASK_462")
	_assert(roadmap_text.contains("TASK_462 - Fireteam Auto Defend Completion Release"), "Roadmap lists TASK_462")
	_assert(contract_text.contains("TASK_462 Auto-Defend nach Zielabschluss"), "Behavior contract documents TASK_462")


func _make_plan(fireteam_id: String, phase: int, targets: Array):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "task462_%s_p%d" % [fireteam_id, phase]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
	plan.active_waypoint_index = -1
	for index in range(targets.size()):
		var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
		waypoint.waypoint_id = "wp_%d" % index
		waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
		waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		waypoint.target_position = Vector2(targets[index])
		plan.waypoints.append(waypoint)
	return plan


func _move_units_near_current_targets(controller: Node, fireteam_id: String, offset: float) -> void:
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", fireteam_id))
	var targets: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if not targets.has(unit_id):
			continue
		(unit as Node2D).global_position = Vector2(targets.get(unit_id)) + Vector2(offset, 0.0)


func _all_units_hold_auto_defend(units: Array) -> bool:
	var checked_count: int = 0
	for unit in units:
		if unit == null or not unit.has_method("get_current_unit_command"):
			continue
		var command = unit.call("get_current_unit_command")
		if command == null:
			return false
		checked_count += 1
		if String(command.get("command_type")) != UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION:
			return false
		if String(command.get("source_command_type")) != "defend":
			return false
		if String(command.get("source_task_type")) != "auto_defend":
			return false
		if String(command.get("fire_status")) != UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL:
			return false
	return checked_count > 0


func _count_distinct_map_facing_angles(units: Array) -> int:
	var keys: Dictionary = {}
	for unit in units:
		if unit == null or not (unit is Node) or not (unit as Node).has_meta("map_facing_angle"):
			continue
		var angle: float = float((unit as Node).get_meta("map_facing_angle", 0.0))
		keys[int(round(rad_to_deg(angle) / 20.0))] = true
	return keys.size()


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
	push_error("  FAIL: %s" % message)
