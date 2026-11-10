extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1002_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.v1"
const NEXT_TASK := "TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1002 Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_round_loop_playtest_slice()
	_test_controller_exports_round_loop_playtest_slice()
	_test_round_loop_playtest_slice_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1002_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice: FAILED")
		quit(1)
		return
	print("TASK_1002_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1002 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1002 round-loop playtest service exists")
	_assert(task_text.contains("TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice"), "Task names TASK_1002")
	_assert(task_text.contains(NEXT_TASK), "Task names runtime polish follow-up")
	_assert(status_text.contains("TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice"), "Implementation status tracks TASK_1002")
	_assert(roadmap_text.contains("TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice (implementiert"), "Roadmap marks TASK_1002 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice (TASK_1002)"), "Mission feedback contract documents TASK_1002")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice (TASK_1002)"), "Decision clarity contract documents TASK_1002")
	_assert(service_text.contains(SCHEMA), "Round-loop playtest service exposes stable TASK_1002 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1002\""), "Round-loop playtest service writes TASK_1002 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1001\""), "Round-loop playtest service links TASK_1001")
	_assert(service_text.contains("REQUIRED_ROUND_LOOP_CHECKS"), "Round-loop playtest service defines required checks")
	_assert(service_text.contains("\"micro_objective_round_loop_playtest_slice_passed\""), "Round-loop playtest service exposes pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "Round-loop playtest creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-loop playtest creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_PLAYTEST_SLICE_SCRIPT"), "Controller preloads TASK_1002 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_snapshot"), "Controller exposes TASK_1002 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_line"), "Command feedback exports TASK_1002 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_gate"), "Command feedback exports TASK_1002 gate")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1002")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked round-loop snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_round_trip_smoke(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1002")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1002", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1001", "Snapshot links TASK_1001")
	_assert(String(snapshot.get("source_status", "")) == "micro_objective_round_trip_smoke_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_micro_objective_round_loop_playtest_trace", "Ready source without trace needs trace")
	_assert(String(snapshot.get("gate", "")) == "needs_micro_objective_round_loop_playtest_trace", "Gate asks for playtest trace")
	_assert(issue_ids.has("micro_objective_round_loop_playtest_trace_missing"), "Missing playtest trace is explicit")
	_assert(not bool(snapshot.get("micro_objective_round_loop_playtest_slice_passed", true)), "Missing trace does not pass slice")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_round_trip_smoke(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_round_loop_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_loop_playtest_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_round_loop_playtest_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("second_round_next_options_visible"), "Failed trace records missing second-round NEXT")
	_assert(missing_checks.has("no_feedback_dead_end"), "Failed trace records feedback dead end")
	_assert(issue_ids.has("second_round_next_options_visible_missing"), "Missing second-round NEXT issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke", "Regression routes back to round-trip smoke")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_round_loop_playtest_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_round_trip_smoke(), _good_trace())
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_loop_playtest_slice_passed", "Good trace passes round-loop playtest")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_round_loop_playtest_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("micro_objective_round_loop_playtest_slice_passed", false)), "Pass flag is true")
	_assert(int(snapshot.get("completed_round_count", 0)) >= 2, "Round-loop playtest records two completed rounds")
	_assert(String(snapshot.get("round_loop_line", "")).contains("ROUND 1"), "Round-loop line names round 1")
	_assert(String(snapshot.get("round_loop_line", "")).contains("ROUND 2"), "Round-loop line names round 2")
	_assert(String(snapshot.get("round_loop_line", "")).contains("NEXT"), "Round-loop line names NEXT")
	_assert(String(snapshot.get("round_loop_line", "")).contains("GO"), "Round-loop line names GO")
	_assert(bool(snapshot.get("no_feedback_dead_end", false)), "Round-loop avoids feedback dead end")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed slice recommends runtime polish")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_round_loop_playtest_slice() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_snapshot(_source_round_trip_smoke(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1002 schema matches")
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_loop_playtest_slice_passed", "Controller TASK_1002 passes with trace")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1002 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice"), "Command feedback embeds TASK_1002")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_line"), "Command feedback exports TASK_1002 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_status"), "Command feedback exports TASK_1002 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice_gate"), "Command feedback exports TASK_1002 gate")
	controller.queue_free()


func _test_round_loop_playtest_slice_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_round_trip_smoke(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1002 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1002", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1001", "Roundtrip keeps TASK_1001 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_round_trip: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1002 service is loadable")
		return {
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		}
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1002 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_round_trip, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1002 service returns dictionary")
	return {}


func _source_round_trip_smoke() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1001",
		"source_task_id": "TASK_1000",
		"status": "micro_objective_round_trip_smoke_passed",
		"gate": "micro_objective_round_trip_smoke_passed",
		"micro_objective_round_trip_smoke_passed": true,
		"round_trip_line": "NEXT -> CONFIRM -> GO -> FEEDBACK PASS | FEEDBACK: naechster Griff bestaetigt.",
		"round_trip_returns_to_decision_state": true,
		"recommended_next_task": "TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice",
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
	return {
		"trace_available": true,
		"completed_round_count": 2,
		"first_round_completed": true,
		"first_round_feedback_visible": true,
		"second_round_next_options_visible": true,
		"second_round_choice_confirmed": true,
		"second_round_go_still_separate": true,
		"second_round_no_auto_go": true,
		"second_round_go_executed": true,
		"second_round_feedback_visible": true,
		"next_decision_after_second_round_visible": true,
		"no_feedback_dead_end": true,
		"hud_surfaces_stable": true,
		"command_path_reused": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"round_loop_feedback_line": "ROUND 1 Feedback gelesen | ROUND 2 NEXT bestaetigt | GO separat | NEXT wieder sichtbar.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["second_round_next_options_visible"] = false
	trace["no_feedback_dead_end"] = false
	trace["next_decision_after_second_round_visible"] = false
	trace["round_loop_feedback_line"] = ""
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
