extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_375_waypoint_intent_preview.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/waypoint_intent_preview_resolver.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_375 Waypoint Intent Preview ===")
	_test_resolver_builds_estimated_path_eta_and_unknown_risk()
	_test_resolver_hides_active_or_committed_plans()
	await _test_mission_controller_preview_cancel_commit_and_truth_boundary()
	_test_docs_status_and_roadmap()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_resolver_builds_estimated_path_eta_and_unknown_risk() -> void:
	var resolver = WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT.new()
	var plan = _make_plan("blue", 1, [
		_make_waypoint("wp_a", Vector2(100.0, 0.0)),
		_make_waypoint("wp_b", Vector2(100.0, 100.0)),
	])
	var entries: Array = Array(resolver.call("build_preview_entries", [plan.call("to_dict")], [{"fireteam_id": "blue", "position": Vector2.ZERO}], {
		"phase_index": 1,
		"selected_fireteam_ids": PackedStringArray(["blue"]),
		"speed_world_per_second_by_fireteam": {"blue": 100.0},
	}))
	_assert(entries.size() == 1, "Resolver builds one selected pending waypoint preview")
	var entry: Dictionary = Dictionary(entries[0])
	_assert(Array(entry.get("ghost_path_points", [])).size() == 3, "Preview includes anchor plus waypoint chain")
	_assert(int(entry.get("ghost_path_segment_count", 0)) == 2, "Preview reports two ghost path segments")
	_assert(is_equal_approx(float(entry.get("distance_world", 0.0)), 200.0), "Preview reports straight-line chain distance")
	_assert(is_equal_approx(float(entry.get("eta_seconds_estimate", 0.0)), 2.0), "Preview reports ETA estimate from provided speed")
	_assert(String(entry.get("eta_state", "")) == "estimated", "Preview marks ETA as estimate")
	_assert(String(entry.get("risk_state", "")) == "unknown" and String(entry.get("risk_reason", "")).contains("no_morale"), "Preview does not invent morale or fatigue risk")
	_assert(bool(entry.get("read_only", false)) and not bool(entry.get("ui_sets_gameplay_truth", true)), "Preview contract is read-only")


func _test_resolver_hides_active_or_committed_plans() -> void:
	var resolver = WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT.new()
	var active_plan = _make_plan("blue", 1, [_make_waypoint("wp_active", Vector2(100.0, 0.0))])
	active_plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_ACTIVE
	active_plan.active_waypoint_index = 0
	active_plan.waypoints[0].status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	var entries: Array = Array(resolver.call("build_preview_entries", [active_plan.call("to_dict")], [{"fireteam_id": "blue", "position": Vector2.ZERO}], {
		"phase_index": 1,
		"selected_fireteam_ids": PackedStringArray(["blue"]),
	}))
	_assert(entries.is_empty(), "Resolver hides preview after waypoint commit/activation")


func _test_mission_controller_preview_cancel_commit_and_truth_boundary() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(24)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var visualizer: Node = scene.get_node_or_null("FireteamOrderVisualizer")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and visualizer != null and simulation_root != null, "Mission scene exposes controller, visualizer and SimulationRoot")
	if controller == null or visualizer == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	var fireteam_id: String = _get_alpha_driver_fireteam_id(scene, controller)
	_assert(not fireteam_id.is_empty(), "Test resolves active fireteam id")
	controller.call("_set_selected_fireteams", PackedStringArray([fireteam_id]), false)
	var command_count_before: int = simulation_root.command_queue.size()
	var effect_count_before: int = simulation_root.effects_queue.size()
	var objective_position: Vector2 = _get_objective_position(scene)
	var first_targets: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(-96.0, -64.0), true, false))
	var second_targets: Array = Array(controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(64.0, 48.0), false, false))
	await _wait_frames(6)
	var feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var previews: Array = Array(feedback.get("waypoint_intent_preview", []))
	_assert(previews.size() == 1, "Command feedback exposes one waypoint intent preview")
	var preview: Dictionary = Dictionary(previews[0])
	_assert(int(preview.get("pending_waypoint_count", 0)) == 2, "Preview summarizes pending waypoint chain")
	_assert(float(preview.get("distance_world", 0.0)) > 0.0 and float(preview.get("eta_seconds_estimate", 0.0)) > 0.0, "Preview exposes distance and ETA estimate")
	_assert(String(preview.get("risk_state", "")) == "unknown", "Preview keeps unknown risk unknown")
	_assert(String(feedback.get("selected_order_text", "")).contains("ETA~"), "Selected order text shows compact ETA estimate")
	var visualizer_previews: Array = Array(visualizer.call("get_waypoint_intent_preview_snapshot"))
	_assert(visualizer_previews.size() == previews.size(), "FireteamOrderVisualizer receives same preview payload")
	_assert(simulation_root.command_queue.size() == command_count_before, "Preview creation enqueues no SimulationRoot commands")
	_assert(simulation_root.effects_queue.size() == effect_count_before, "Preview creation enqueues no SimulationRoot effects")

	controller.call("_delete_waypoint_targets", first_targets + second_targets)
	await _wait_frames(6)
	var cancelled_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(Array(cancelled_feedback.get("waypoint_intent_preview", [])).is_empty(), "Preview disappears after waypoint cancel/delete")

	controller.call("_create_waypoints_for_selected_fireteams", objective_position + Vector2(96.0, 72.0), true, false)
	await _wait_frames(6)
	_assert(not Array(Dictionary(controller.call("get_command_feedback_snapshot")).get("waypoint_intent_preview", [])).is_empty(), "Preview reappears for new pending waypoint")
	var did_execute: bool = bool(controller.call("execute_selected_fireteam_orders"))
	await _wait_frames(6)
	var committed_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(did_execute, "GO commits selected waypoint order")
	_assert(Array(committed_feedback.get("waypoint_intent_preview", [])).is_empty(), "Preview disappears after GO commit")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_status_and_roadmap() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_375 task file marks implementation complete")
	_assert(not task_text.contains("- [ ]"), "TASK_375 checklist is complete")
	_assert(status_text.contains("### TASK_375 - Waypoint Intent Preview") and status_text.contains("- Status: implementiert"), "Implementation status marks TASK_375 implemented")
	_assert(roadmap_text.contains("TASK_375 - Waypoint Intent Preview (implementiert)"), "Roadmap marks TASK_375 implemented")


func _make_plan(fireteam_id: String, phase: int, waypoints: Array):
	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p%d" % [fireteam_id, phase]
	plan.fireteam_id = fireteam_id
	plan.phase = phase
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT
	plan.waypoints = waypoints
	return plan


func _make_waypoint(waypoint_id: String, target_position: Vector2):
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = waypoint_id
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = target_position
	return waypoint


func _get_alpha_driver_fireteam_id(scene: Node, controller: Node) -> String:
	var alpha_driver := scene.get_node_or_null("AlphaFlowDriver")
	if alpha_driver != null:
		var fireteam_id: String = String(controller.call("_get_fireteam_id_for_flow_driver", alpha_driver)).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			return fireteam_id
	var fireteams: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	return String(fireteams[0]).strip_edges().to_lower() if fireteams.size() > 0 else ""


func _get_objective_position(scene: Node) -> Vector2:
	var objective := scene.get_node_or_null("MapRoot/objective_point") as Node2D
	return objective.global_position if objective != null else Vector2(448.0, 285.0)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
