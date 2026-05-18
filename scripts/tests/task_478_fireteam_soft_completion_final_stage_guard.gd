extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_478_fireteam_soft_completion_final_stage_guard.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/fireteam_behavior_modes_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_478 Fireteam Soft Completion Final Stage Guard ===")
	await _test_soft_completion_ignores_intermediate_stage_targets()
	_test_docs_capture_task()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_soft_completion_ignores_intermediate_stage_targets() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var controller := scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Drill scene exposes TacticalController for completion guard")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	controller.call("_set_selected_fireteams", PackedStringArray(["drill"]), false)

	var target_positions: Dictionary = _build_current_unit_targets(controller, "drill")
	_assert(not target_positions.is_empty(), "Completion guard has current unit target positions")
	if target_positions.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return

	var final_target := Vector2(1480.0, 760.0)
	var intermediate_anchor := final_target + Vector2(-220.0, -80.0)
	var execution_state: Dictionary = {
		"started_msec": Time.get_ticks_msec() - 5000,
	}
	var movement_state: Dictionary = {
		"current_target_positions": target_positions,
		"current_anchor_target_position": intermediate_anchor,
		"final_target_position": final_target,
	}
	var movement_result: Dictionary = {
		"movement_state": movement_state,
	}

	var intermediate_reached: bool = bool(controller.call(
		"_is_phase_waypoint_target_reached",
		"drill",
		final_target,
		movement_result,
		execution_state,
		true
	))
	_assert(not intermediate_reached, "Soft-reached intermediate bound does not finish the whole waypoint")

	movement_state["current_anchor_target_position"] = final_target
	movement_result["movement_state"] = movement_state
	var final_reached: bool = bool(controller.call(
		"_is_phase_waypoint_target_reached",
		"drill",
		final_target,
		movement_result,
		execution_state,
		true
	))
	_assert(final_reached, "Soft-reached final movement stage can still complete the waypoint")

	scene.queue_free()
	await _wait_frames(2)


func _build_current_unit_targets(controller: Node, fireteam_id: String) -> Dictionary:
	var targets: Dictionary = {}
	for unit in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		if not (unit is Node2D) or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		targets[unit_id] = (unit as Node2D).global_position
	return targets


func _test_docs_capture_task() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(task_text.contains("TASK_478 - Fireteam Soft Completion Final Stage Guard"), "TASK_478 task file exists")
	_assert(status_text.contains("TASK_478 - Fireteam Soft Completion Final Stage Guard"), "Implementation status documents TASK_478")
	_assert(roadmap_text.contains("TASK_478 - Fireteam Soft Completion Final Stage Guard"), "Roadmap lists TASK_478")
	_assert(contract_text.contains("TASK_478 Final-Stage Completion Guard"), "Behavior contract documents TASK_478")


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
