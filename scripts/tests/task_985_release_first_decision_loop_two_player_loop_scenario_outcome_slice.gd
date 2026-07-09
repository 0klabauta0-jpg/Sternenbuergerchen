extends SceneTree

const Outcome := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_outcome_slice.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_985_release_first_decision_loop_two_player_loop_scenario_outcome_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_outcome_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_outcome_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_outcome_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_acceptance_slice.v1"
const NEXT_TASK := "TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_985 Release First Decision Loop Two Player Loop Scenario Outcome Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_acceptance_without_outcome_trace_needs_trace()
	_test_failed_outcome_trace_reports_regression()
	_test_good_trace_creates_scenario_outcome()
	_test_controller_exports_scenario_outcome()
	_test_outcome_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_985_release_first_decision_loop_two_player_loop_scenario_outcome_slice: FAILED")
		quit(1)
		return
	print("TASK_985_release_first_decision_loop_two_player_loop_scenario_outcome_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_985 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_985 outcome service exists")
	_assert(task_text.contains("TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice"), "Task names TASK_985")
	_assert(task_text.contains(NEXT_TASK), "Task names real-window follow-up")
	_assert(status_text.contains("TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice"), "Implementation status tracks TASK_985")
	_assert(roadmap_text.contains("TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice (implementiert"), "Roadmap marks TASK_985 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Outcome Slice (TASK_985)"), "Mission feedback contract documents TASK_985")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Outcome Slice (TASK_985)"), "Decision clarity contract documents TASK_985")
	_assert(service_text.contains(SCHEMA), "Outcome service exposes stable TASK_985 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_985\""), "Outcome service writes TASK_985 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_984\""), "Outcome service links TASK_984")
	_assert(service_text.contains("REQUIRED_OUTCOME_CHECKS"), "Outcome service defines required checks")
	_assert(service_text.contains("\"outcome_line\""), "Outcome service exposes outcome line")
	_assert(service_text.contains("\"next_step_line\""), "Outcome service exposes next step line")
	_assert(service_text.contains("\"creates_command\": false"), "Outcome service creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Outcome service creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_OUTCOME_SLICE_SCRIPT"), "Controller preloads TASK_985 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_outcome_slice_snapshot"), "Controller exposes TASK_985 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_outcome_line"), "Command feedback exports TASK_985 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Outcome.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_985")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed_for_outcome"), "Missing source reports pass mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_passed_acceptance_without_outcome_trace_needs_trace() -> void:
	var snapshot: Dictionary = Outcome.build_snapshot(_passed_acceptance(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_player_loop_outcome_trace", "Passed source without trace needs outcome trace")
	_assert(String(snapshot.get("gate", "")) == "needs_player_loop_outcome_trace", "Missing outcome trace gates run")
	_assert(issue_ids.has("player_loop_outcome_trace_missing"), "Missing outcome trace issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice", "Missing trace loops on TASK_985")
	_assert(_snapshot_is_read_only(snapshot), "Needs-trace snapshot remains read-only")


func _test_failed_outcome_trace_reports_regression() -> void:
	var snapshot: Dictionary = Outcome.build_snapshot(_passed_acceptance(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "player_loop_scenario_outcome_regression_found", "Failed trace reports outcome regression")
	_assert(String(snapshot.get("gate", "")) == "player_loop_scenario_outcome_regression_found", "Failed trace gate names regression")
	_assert(issue_ids.has("outcome_line_missing"), "Failed trace names missing outcome line")
	_assert(issue_ids.has("next_step_not_visible"), "Failed trace names missing next step")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice", "Failed trace loops on TASK_985")
	_assert(_snapshot_is_read_only(snapshot), "Failed trace remains read-only")


func _test_good_trace_creates_scenario_outcome() -> void:
	var snapshot: Dictionary = Outcome.build_snapshot(_passed_acceptance(), _good_trace())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_985")
	_assert(String(snapshot.get("task_id", "")) == "TASK_985", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_984", "Snapshot links TASK_984")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_984 schema")
	_assert(String(snapshot.get("status", "")) == "player_loop_scenario_outcome_ready", "Good trace creates scenario outcome")
	_assert(String(snapshot.get("gate", "")) == "player_loop_scenario_outcome_ready", "Good trace gate ready")
	_assert(bool(snapshot.get("scenario_outcome_ready", false)), "Good trace sets ready flag")
	_assert(String(snapshot.get("selected_choice_id", "")) == "push_objective", "Good trace keeps selected choice")
	_assert(String(snapshot.get("outcome_line", "")).contains("PUSH"), "Outcome line names PUSH")
	_assert(String(snapshot.get("outcome_line", "")).contains("Ziel"), "Outcome line names objective")
	_assert(String(snapshot.get("next_step_line", "")).contains("Naechster Griff"), "Next step is readable")
	_assert(String(snapshot.get("result_tag", "")) == "objective_pressure", "Result tag is stable")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Good trace recommends real-window capture")
	_assert(_snapshot_is_read_only(snapshot), "Good trace remains read-only")


func _test_controller_exports_scenario_outcome() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_outcome_slice_snapshot(_passed_acceptance(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_985 schema matches")
	_assert(String(snapshot.get("status", "")) == "player_loop_scenario_outcome_ready", "Controller TASK_985 can pass with trace")
	_assert(String(snapshot.get("outcome_line", "")).contains("PUSH"), "Controller TASK_985 line names PUSH")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_985 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_outcome_slice"), "Command feedback embeds TASK_985")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_outcome_line"), "Command feedback exports TASK_985 line")
	controller.queue_free()


func _test_outcome_roundtrip() -> void:
	var snapshot: Dictionary = Outcome.build_snapshot(_passed_acceptance(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_985 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_985", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_984", "Roundtrip keeps TASK_984 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _passed_acceptance() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_984",
		"source_task_id": "TASK_983",
		"status": "player_loop_acceptance_slice_passed",
		"gate": "player_loop_acceptance_slice_passed",
		"acceptance_slice_passed": true,
		"choice_labels": ["SECURE", "PUSH", "FLANK", "RESET"],
		"choice_label_count": 4,
		"selected_choice_id": "push_objective",
		"acceptance_line": "SECURE / PUSH / FLANK / RESET | PASS | GO separat",
		"answered_player_question_count": 6,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
		"updates_shortcuts": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"selected_choice_has_outcome",
		"outcome_line_visible",
		"mini_objective_state_visible",
		"next_step_visible",
		"player_result_readable",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"selected_choice_id": "push_objective",
		"selected_choice_label": "PUSH",
		"selected_choice_has_outcome": true,
		"outcome_line_visible": true,
		"outcome_line": "PUSH: Ziel unter Druck, naechster Abschnitt offen.",
		"result_tag": "objective_pressure",
		"mini_objective_state_visible": true,
		"mini_objective_state": "Ziel 1/2 unter Druck",
		"next_step_visible": true,
		"next_step_line": "Naechster Griff: sichern oder weiter druecken.",
		"player_result_readable": true,
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["selected_choice_has_outcome"]
	trace["outcome_line_visible"] = false
	trace["outcome_line"] = ""
	trace["next_step_visible"] = false
	trace["next_step_line"] = ""
	trace["player_result_readable"] = false
	return trace


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _read_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return Dictionary(parsed)
	return {}


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
