extends SceneTree

const MISSION_TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_419_go_next_action_and_npc_speed.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HTML_PATH: String = "res://docs/reports/fireteam_mini_card_explainer.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SIMULATION_ROOT_PATH: String = "res://scripts/core/simulation_root.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_419 GO Recovery Action And NPC Speed ===")
	_test_go_recovery_decision_reads_plan_interrupts()
	_test_ad_hoc_execution_is_go_recovery_context()
	_test_speed_constant_and_go_integration()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_go_recovery_decision_reads_plan_interrupts() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	var plan = _make_interrupted_plan("drill")
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_order_plans_by_key", {plan_key: plan})
	controller.set("_suppression_interrupt_pending_by_fireteam", {"drill": true})
	controller.set("_suppression_state_by_fireteam", {
		"drill": {
			"value": 0.25,
			"threshold": 2.0,
			"is_suppressed": false,
			"is_heavily_suppressed": false,
		},
	})

	_assert(bool(controller.call("_is_fireteam_go_recovery_context", "drill")), "Interrupted plan is a GO recovery context")
	_assert(bool(controller.call("_has_go_recovery_action_for_fireteam", "drill")), "GO sees Return-to-Plan as executable recovery")
	_assert(not bool(controller.call("_is_fireteam_go_recovery_blocked", "drill")), "Low suppression does not block GO recovery")

	# FT-0b: drei Stufen. GO-Erholung ist ab Stufe 2 (Niedergehalten) gesperrt, passend zur automatischen Fortsetzung unter
	# Stufe 2; Stufe 1 (Unter Feuer) sperrt nicht. Gleiche Aussage wie task_473.
	controller.set("_suppression_state_by_fireteam", {
		"drill": {
			"value": 1.2,
			"threshold": 2.5,
			"level": 1,
			"is_suppressed": true,
			"is_heavily_suppressed": false,
		},
	})
	_assert(not bool(controller.call("_is_fireteam_go_recovery_blocked", "drill")), "Level 1 (under fire) does not block GO recovery")

	controller.set("_suppression_state_by_fireteam", {
		"drill": {
			"value": 2.6,
			"threshold": 4.0,
			"level": 2,
			"is_suppressed": true,
			"is_heavily_suppressed": false,
		},
	})
	_assert(bool(controller.call("_is_fireteam_go_recovery_blocked", "drill")), "GO recovery blocks from level 2 (pinned down)")

	controller.set("_suppression_state_by_fireteam", {
		"drill": {
			"value": 4.5,
			"threshold": 4.0,
			"level": 3,
			"is_suppressed": true,
			"is_heavily_suppressed": false,
		},
	})
	_assert(bool(controller.call("_is_fireteam_go_recovery_blocked", "drill")), "Level 3 (nailed down) blocks forced GO recovery")
	controller.free()


func _test_ad_hoc_execution_is_go_recovery_context() -> void:
	var controller = MISSION_TACTICAL_CONTROLLER_SCRIPT.new()
	controller.set("_ad_hoc_execution_by_fireteam", {
		"drill": {
			"order_type": "fallback",
			"status": "active",
		},
	})

	_assert(bool(controller.call("_is_fireteam_go_recovery_context", "drill")), "Active ad-hoc execution is a GO recovery context")
	_assert(bool(controller.call("_can_return_fireteam_to_plan", "drill")), "Return-to-Plan availability includes ad-hoc execution state")
	controller.free()


func _test_speed_constant_and_go_integration() -> void:
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var simulation_root_text: String = _read_text(SIMULATION_ROOT_PATH)
	_assert(SIMULATION_ROOT_SCRIPT != null, "SimulationRoot script still compiles")
	_assert(simulation_root_text.contains("const MOVE_SPEED_PER_SECOND: float = 80.0"), "NPC base move speed is one third slower")
	_assert(simulation_root_text.contains("MOVE_SPEED_PER_SECOND * move_speed_factor"), "Move commands still use the authoritative base speed")
	_assert(controller_text.contains("_has_go_recovery_action_for_fireteam(fireteam_id)"), "GO execution path checks recovery before new waypoint activation")
	_assert(controller_text.contains("_return_fireteam_to_plan(fireteam_id, false)"), "GO recovery uses Return-to-Plan without manual Plan press")
	_assert(controller_text.contains("PINNED %s"), "GO reports pinned recovery blocks")


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var html_text: String = _read_text(HTML_PATH)
	_assert(task_text.contains("TASK_419 - GO Recovery Action And NPC Speed"), "TASK_419 task file exists")
	_assert(status_text.contains("TASK_419 - GO Recovery Action And NPC Speed"), "Implementation status documents TASK_419")
	_assert(roadmap_text.contains("TASK_419 - GO Recovery Action And NPC Speed"), "Roadmap lists TASK_419")
	_assert(html_text.contains("GO uebernimmt jetzt auch Return-to-Plan-Recovery"), "Mini-card explainer documents GO recovery behavior")
	_assert(html_text.contains("80.0"), "Mini-card explainer mentions slower base movement")


func _make_interrupted_plan(fireteam_id: String):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p1" % fireteam_id
	plan.fireteam_id = fireteam_id
	plan.phase = 1
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_INTERRUPTED
	plan.active_waypoint_index = 0
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = "wp_recovery"
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED
	waypoint.target_position = Vector2(96.0, 64.0)
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
