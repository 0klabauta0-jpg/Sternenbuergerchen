extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1001_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_playability_slice.v1"
const NEXT_TASK := "TASK_1002 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Playtest Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1001 Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_round_trip_smoke()
	_test_controller_exports_round_trip_smoke()
	_test_round_trip_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1001_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke: FAILED")
		quit(1)
		return
	print("TASK_1001_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1001 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1001 round-trip smoke service exists")
	_assert(task_text.contains("TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke"), "Task names TASK_1001")
	_assert(task_text.contains(NEXT_TASK), "Task names round-loop playtest follow-up")
	_assert(status_text.contains("TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke"), "Implementation status tracks TASK_1001")
	_assert(roadmap_text.contains("TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke (implementiert"), "Roadmap marks TASK_1001 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke (TASK_1001)"), "Mission feedback contract documents TASK_1001")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke (TASK_1001)"), "Decision clarity contract documents TASK_1001")
	_assert(service_text.contains(SCHEMA), "Round-trip smoke service exposes stable TASK_1001 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1001\""), "Round-trip smoke service writes TASK_1001 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1000\""), "Round-trip smoke service links TASK_1000")
	_assert(service_text.contains("REQUIRED_ROUND_TRIP_CHECKS"), "Round-trip smoke service defines required checks")
	_assert(service_text.contains("\"micro_objective_round_trip_smoke_passed\""), "Round-trip smoke service exposes pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "Round-trip smoke creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-trip smoke creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_TRIP_SMOKE_SCRIPT"), "Controller preloads TASK_1001 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_snapshot"), "Controller exposes TASK_1001 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_line"), "Command feedback exports TASK_1001 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_gate"), "Command feedback exports TASK_1001 gate")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1001")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked round-trip smoke snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_playability_slice(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1001")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1001", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1000", "Snapshot links TASK_1000")
	_assert(String(snapshot.get("source_status", "")) == "micro_objective_playability_slice_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_micro_objective_round_trip_trace", "Ready source without trace needs trace")
	_assert(String(snapshot.get("gate", "")) == "needs_micro_objective_round_trip_trace", "Gate asks for trace")
	_assert(issue_ids.has("micro_objective_round_trip_trace_missing"), "Missing trace is explicit")
	_assert(not bool(snapshot.get("micro_objective_round_trip_smoke_passed", true)), "Missing trace does not pass smoke")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_playability_slice(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_round_trip_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_trip_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_round_trip_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("go_still_separate"), "Failed trace records missing GO separation")
	_assert(missing_checks.has("round_trip_returns_to_decision_state"), "Failed trace records missing decision return")
	_assert(issue_ids.has("go_still_separate_missing"), "Missing GO separation issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1000 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice", "Regression routes back to playability slice")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_round_trip_smoke() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_playability_slice(), _good_trace())
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_trip_smoke_passed", "Good trace passes round-trip smoke")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_round_trip_smoke_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("micro_objective_round_trip_smoke_passed", false)), "Pass flag is true")
	_assert(String(snapshot.get("round_trip_line", "")).contains("NEXT"), "Round-trip line names NEXT")
	_assert(String(snapshot.get("round_trip_line", "")).contains("CONFIRM"), "Round-trip line names CONFIRM")
	_assert(String(snapshot.get("round_trip_line", "")).contains("GO"), "Round-trip line names GO")
	_assert(String(snapshot.get("round_trip_line", "")).contains("FEEDBACK"), "Round-trip line names FEEDBACK")
	_assert(bool(snapshot.get("round_trip_returns_to_decision_state", false)), "Round trip returns to decision state")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed smoke recommends round-loop playtest")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_round_trip_smoke() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_snapshot(_source_playability_slice(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1001 schema matches")
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_trip_smoke_passed", "Controller TASK_1001 passes with trace")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1001 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke"), "Command feedback embeds TASK_1001")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_line"), "Command feedback exports TASK_1001 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_status"), "Command feedback exports TASK_1001 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_trip_smoke_gate"), "Command feedback exports TASK_1001 gate")
	controller.queue_free()


func _test_round_trip_smoke_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_playability_slice(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1001 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1001", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1000", "Roundtrip keeps TASK_1000 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_playability: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1001 service is loadable")
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
		_assert(false, "TASK_1001 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_playability, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1001 service returns dictionary")
	return {}


func _source_playability_slice() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1000",
		"source_task_id": "TASK_999",
		"status": "micro_objective_playability_slice_passed",
		"gate": "micro_objective_playability_slice_passed",
		"micro_objective_playability_slice_passed": true,
		"micro_objective_playability_line": "MICRO PASS: OUTCOME SICHERN | OBJ Gelaende gesichert | NEXT zweite Entscheidung",
		"answered_player_questions": ["what_happened", "what_changed", "what_next", "who_owns_truth", "what_requires_go"],
		"recommended_next_task": "TASK_1001 - Release First Decision Loop Two Player Loop Micro Objective Round Trip Smoke",
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
		"selected_micro_objective_id": "push_next",
		"next_micro_objective_options_visible": true,
		"selected_next_micro_objective_confirmed": true,
		"confirm_feedback_visible": true,
		"go_still_separate": true,
		"no_auto_go_after_confirm": true,
		"go_executed_after_confirm": true,
		"post_round_trip_feedback_visible": true,
		"round_trip_returns_to_decision_state": true,
		"command_path_reused": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"post_round_trip_feedback_line": "FEEDBACK: naechster Griff bestaetigt, GO separat ausgefuehrt.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["go_still_separate"] = false
	trace["round_trip_returns_to_decision_state"] = false
	trace["post_round_trip_feedback_visible"] = false
	trace["post_round_trip_feedback_line"] = ""
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
