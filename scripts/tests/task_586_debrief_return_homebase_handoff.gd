extends SceneTree

const META_LAYER_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_586_debrief_return_homebase_handoff.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const META_LAYER_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_586 Debrief Return To Homebase Handoff ===")
	_test_docs_and_wiring()
	await _test_debrief_return_homebase_handoff()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_586: FAILED")
		quit(1)
		return
	print("TASK_586: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var meta_layer_text: String = _read_text(META_LAYER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_586 task file exists")
	_assert(task_text.contains("Debrief Return To Homebase Handoff"), "TASK_586 task file names the task")
	_assert(status_text.contains("TASK_586 - Debrief Return To Homebase Handoff"), "Implementation status tracks TASK_586")
	_assert(status_text.contains("TASK_585 - Mini AAR Debrief Screen Stub"), "Implementation status still tracks TASK_585")
	_assert(roadmap_text.contains("TASK_586 - Debrief Return To Homebase Handoff (implementiert)"), "Roadmap marks TASK_586 implemented")
	_assert(roadmap_text.contains("TASK_587 - Debrief Visual Polish Pass"), "Roadmap names TASK_587 follow-up")
	_assert(report_text.contains("TASK_586 - Debrief Return To Homebase Handoff"), "Review workbench tracks TASK_586")
	_assert(report_text.contains("TASK_587 - Debrief Visual Polish Pass"), "Review workbench names TASK_587 follow-up")
	_assert(contract_text.contains("Debrief-Return-Homebase-Handoff"), "Mission feedback contract documents TASK_586")
	_assert(meta_layer_text.contains("get_debrief_return_homebase_handoff_snapshot"), "MetaLayerFlow exposes TASK_586 snapshot")
	_assert(meta_layer_text.contains("request_debrief_return_homebase_for_test"), "MetaLayerFlow exposes test return helper")


func _test_debrief_return_homebase_handoff() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = META_LAYER_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)

	var debrief_screen: Node = scene.get_node_or_null("DebriefScreen")
	var homebase_screen: Node = scene.get_node_or_null("HomebaseScreen")
	_assert(debrief_screen != null, "Meta fixture exposes DebriefScreen")
	_assert(homebase_screen != null, "Meta fixture exposes HomebaseScreen")
	if debrief_screen == null or homebase_screen == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var mission_result: Dictionary = _build_test_mission_result()
	scene.set("_last_mission_result", mission_result.duplicate(true))
	debrief_screen.call("set_mission_result", mission_result.duplicate(true))
	scene.call("_show_debrief")
	await _wait_frames(6)

	var before_snapshot: Dictionary = Dictionary(scene.call("get_debrief_return_homebase_handoff_snapshot"))
	_assert(String(before_snapshot.get("schema", "")) == "sternenbuergerchen.debrief_return_homebase_handoff.v1", "Debrief return handoff reports stable schema")
	_assert(String(before_snapshot.get("gate", "")) == "pass", "Debrief return handoff gate passes before return")
	_assert(bool(before_snapshot.get("read_only", false)), "Debrief return snapshot is read-only")
	_assert(not bool(before_snapshot.get("ui_sets_gameplay_truth", true)), "Debrief return snapshot does not set gameplay truth")
	_assert(String(before_snapshot.get("current_meta_view", "")) == "debrief", "Before return current view is Debrief")
	_assert(String(before_snapshot.get("target_meta_view", "")) == "homebase", "Debrief return target is Homebase")
	_assert(bool(before_snapshot.get("return_action_available", false)), "Return action is available")
	_assert(bool(before_snapshot.get("return_signal_connected", false)), "Return signal is connected")
	_assert(bool(before_snapshot.get("debrief_visible", false)), "Debrief is visible before return")
	_assert(not bool(before_snapshot.get("homebase_visible", true)), "Homebase is hidden before return")
	_assert(bool(before_snapshot.get("debrief_has_mission_result", false)), "Debrief carries mission result before return")
	_assert(bool(before_snapshot.get("mission_result_preserved", false)), "Mission result matches before return")
	_assert(bool(before_snapshot.get("active_mission_released", false)), "No active mission is registered before return")
	_assert(_check_passed(before_snapshot, "return_action_connected"), "Return connection check passes")
	_assert(_check_passed(before_snapshot, "mission_result_preserved"), "Mission result preservation check passes")

	var after_snapshot: Dictionary = Dictionary(scene.call("request_debrief_return_homebase_for_test"))
	await _wait_frames(6)
	after_snapshot = Dictionary(scene.call("get_debrief_return_homebase_handoff_snapshot"))
	_assert(String(after_snapshot.get("gate", "")) == "pass", "Debrief return handoff gate passes after return")
	_assert(String(after_snapshot.get("current_meta_view", "")) == "homebase", "After return current view is Homebase")
	_assert(bool(after_snapshot.get("homebase_visible", false)), "Homebase is visible after return")
	_assert(not bool(after_snapshot.get("debrief_visible", true)), "Debrief is hidden after return")
	_assert(bool(after_snapshot.get("navigation_visible", false)), "Meta navigation is visible after return")
	_assert(bool(after_snapshot.get("debrief_has_mission_result", false)), "Debrief keeps mission result after return")
	_assert(bool(after_snapshot.get("mission_result_preserved", false)), "Mission result still matches after return")
	_assert(bool(after_snapshot.get("active_mission_released", false)), "No active mission is registered after return")
	_assert(String(Dictionary(after_snapshot.get("last_mission_result", {})).get("result", "")) == "victory", "Last mission result remains unchanged")

	scene.queue_free()
	await _wait_frames(2)


func _build_test_mission_result() -> Dictionary:
	return {
		"winning_team_id": "team_alpha",
		"mission_outcome": "completed",
		"result": "victory",
		"win_condition_type": "objective_capture",
		"objective_captured": true,
		"duration_seconds": 184.5,
		"selected_unit_ids": PackedStringArray(["lead_alpha", "rifle_alpha", "medic_alpha"]),
		"selected_fireteam_ids": PackedStringArray(["ft_alpha"]),
		"team_states": [
			{"unit_id": "lead_alpha", "display_name": "Lead Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 100},
			{"unit_id": "rifle_alpha", "display_name": "Rifle Alpha", "fireteam_id": "ft_alpha", "vital_state": "fit", "health_points": 88},
			{"unit_id": "medic_alpha", "display_name": "Medic Alpha", "fireteam_id": "ft_alpha", "vital_state": "wounded", "health_points": 42},
		],
		"fireteam_tactical_debrief": [
			{"fireteam_id": "ft_alpha", "summary_text": "FTL kept the team moving under contact."},
		],
	}


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame
