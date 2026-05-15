extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_422 GO Continue Fireteam HUD Cleanup ===")
	await _test_go_continues_reached_move_waypoint()
	await _test_fireteam_hud_cleanup_and_mini_suppression_bar()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_go_continues_reached_move_waypoint() -> void:
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
	_assert(anchor is Node2D, "Drill fireteam exposes runtime anchor")
	if not (anchor is Node2D):
		scene.queue_free()
		await _wait_frames(2)
		return
	var anchor_position: Vector2 = (anchor as Node2D).global_position
	var plan = _make_plan("drill", 1, anchor_position, anchor_position + Vector2(128.0, -32.0))
	var plan_key: String = String(controller.call("_build_order_plan_key", "drill", 1))
	controller.set("_selected_fireteam_ids", PackedStringArray(["drill"]))
	controller.set("_order_plans_by_key", {plan_key: plan})
	controller.set("_phase_execution_by_fireteam", {
		"drill": {
			"phase": 1,
			"waypoint_index": 0,
			"hold_elapsed": 0.0,
			"resolved_target_position": anchor_position,
		},
	})

	var continued: bool = bool(controller.call("execute_selected_fireteam_orders"))
	await _wait_frames(4)
	var stored_plans: Dictionary = Dictionary(controller.get("_order_plans_by_key"))
	var stored_plan = stored_plans.get(plan_key, null)
	var phase_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam"))
	var execution_state: Dictionary = Dictionary(phase_execution.get("drill", {}))
	var movement_state: Dictionary = Dictionary(controller.call("get_fireteam_movement_state", "drill"))

	_assert(continued, "GO accepts reached active Move waypoint as a continue action")
	_assert(stored_plan != null and stored_plan.waypoints.size() == 1, "GO removes the reached Move waypoint from the plan")
	if stored_plan != null and stored_plan.waypoints.size() == 1:
		_assert(String(stored_plan.waypoints[0].waypoint_id) == "wp_next", "GO keeps the next waypoint as the active remaining plan entry")
		_assert(String(stored_plan.waypoints[0].status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE, "GO activates the next waypoint")
	_assert(int(execution_state.get("waypoint_index", -1)) == 0, "Phase execution now tracks the shifted next waypoint index")
	_assert(not movement_state.is_empty(), "GO starts movement execution for the next waypoint")
	scene.queue_free()
	await _wait_frames(2)


func _test_fireteam_hud_cleanup_and_mini_suppression_bar() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var controller := scene.get_node_or_null("TacticalController")
	var command_grid := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid") as GridContainer
	var status_panel := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/FireteamStatusPanel") as Control
	var stance_panel := scene.get_node_or_null("TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox/TacticalStancePanel") as Control
	_assert(controller != null and command_grid != null, "Drill scene exposes controller and command grid")
	if controller == null or command_grid == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var plan_button := command_grid.get_node_or_null("PlanCommandMatrixButton") as Button
	var waypoint_erase_button := command_grid.get_node_or_null("WaypointEraseButton") as Button
	_assert(plan_button == null, "Command matrix no longer exposes a visible Plan button")
	_assert(waypoint_erase_button != null and String(waypoint_erase_button.text) == "WP-" and String(waypoint_erase_button.get_meta("command_matrix_slot_id", "")) == "16.20", "Command slot 16.20 exposes fixed WP erase action")
	_assert(status_panel == null, "#17 no longer creates the Ready/Plan/SUPP status panel")
	_assert(stance_panel != null and stance_panel.visible, "#17 keeps the tactical stance controls")

	controller.set("_suppression_state_by_fireteam", {
		"drill": {
			"value": 1.5,
			"threshold": 2.0,
			"is_suppressed": false,
			"is_heavily_suppressed": false,
			"applied_level": 0,
			"hold_until_msec": 0,
		},
	})
	controller.call("_refresh_fireteam_mini_cards")
	var card_list := scene.get_node_or_null("TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox")
	var drill_card: Control = null
	if card_list != null:
		drill_card = card_list.get_node_or_null("FireteamMiniCard_Drill") as Control
	var supp_bar: ProgressBar = null
	if drill_card != null:
		supp_bar = drill_card.find_child("MiniSuppressionBar", true, false) as ProgressBar
	_assert(supp_bar != null and bool(supp_bar.get_meta("mission_fireteam_mini_suppression_bar", false)), "Fireteam mini-card owns a suppression bar")
	_assert(supp_bar != null and supp_bar.visible and supp_bar.custom_minimum_size.y >= 6.0, "Suppression is rendered as a visible mini-card bar")
	_assert(supp_bar != null and is_equal_approx(float(supp_bar.value), 1.5) and is_equal_approx(float(supp_bar.max_value), 2.0), "Mini-card suppression bar follows suppression value and threshold")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(task_text.contains("TASK_422 - GO Continue Fireteam HUD Cleanup"), "TASK_422 task file exists")
	_assert(status_text.contains("TASK_422 - GO Continue Fireteam HUD Cleanup"), "Implementation status documents TASK_422")
	_assert(roadmap_text.contains("TASK_422 - GO Continue Fireteam HUD Cleanup"), "Roadmap lists TASK_422")
	_assert(controller_text.contains("_is_active_waypoint_ready_for_go_continue"), "Controller has explicit GO continue helper")
	_assert(controller_text.contains("slot_index == 20") and controller_text.contains("WaypointEraseButton"), "Controller replaces old Plan slot 16.20 with WP erase")


func _make_plan(fireteam_id: String, phase: int, first_target: Vector2, second_target: Vector2):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p%d" % [fireteam_id, phase]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_ACTIVE
	plan.active_waypoint_index = 0
	var first = FIRETEAM_WAYPOINT_SCRIPT.new()
	first.waypoint_id = "wp_reached"
	first.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	first.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	first.target_position = first_target
	plan.waypoints.append(first)
	var second = FIRETEAM_WAYPOINT_SCRIPT.new()
	second.waypoint_id = "wp_next"
	second.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	second.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	second.target_position = second_target
	plan.waypoints.append(second)
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
