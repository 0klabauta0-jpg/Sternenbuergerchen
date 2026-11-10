extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1021_release_first_decision_loop_two_player_loop_scenario_integrated_playtest.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_integrated_playtest.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_integrated_playtest_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_playtest.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_acceptance_slice.v1"
const NEXT_TASK := "TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1021 Release First Decision Loop Two Player Loop Scenario Integrated Playtest ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_scenario_integrated_playtest()
	_test_controller_exports_scenario_integrated_playtest()
	_test_scenario_integrated_playtest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1021_release_first_decision_loop_two_player_loop_scenario_integrated_playtest: FAILED")
		quit(1)
		return
	print("TASK_1021_release_first_decision_loop_two_player_loop_scenario_integrated_playtest: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1021 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1021 scenario integrated playtest service exists")
	_assert(task_text.contains("TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest"), "Task names TASK_1021")
	_assert(task_text.contains(NEXT_TASK), "Task names player-feel findings follow-up")
	_assert(status_text.contains("TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest"), "Implementation status tracks TASK_1021")
	_assert(roadmap_text.contains("TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest (implementiert"), "Roadmap marks TASK_1021 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Integrated Playtest (TASK_1021)"), "Mission feedback contract documents TASK_1021")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Integrated Playtest (TASK_1021)"), "Decision clarity contract documents TASK_1021")
	_assert(service_text.contains(SCHEMA), "Scenario integrated playtest service exposes stable TASK_1021 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1021\""), "Scenario integrated playtest service writes TASK_1021 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1020\""), "Scenario integrated playtest service links TASK_1020")
	_assert(service_text.contains("REQUIRED_INTEGRATED_CHECKS"), "Scenario integrated playtest service defines required checks")
	_assert(service_text.contains("\"scenario_integrated_playtest_passed\""), "Scenario integrated playtest exposes pass flag")
	_assert(service_text.contains("\"ready_for_player_feel_findings\""), "Scenario integrated playtest exposes player-feel readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Scenario integrated playtest creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Scenario integrated playtest creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Scenario integrated playtest creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_INTEGRATED_PLAYTEST_SCRIPT"), "Controller preloads TASK_1021 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_integrated_playtest_snapshot"), "Controller exposes TASK_1021 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_integrated_playtest_line"), "Command feedback exports TASK_1021 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_integrated_playtest_status"), "Command feedback exports TASK_1021 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1021")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked scenario integrated playtest snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1021")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1021", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1020", "Snapshot links TASK_1020")
	_assert(String(snapshot.get("source_status", "")) == "scenario_acceptance_slice_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_scenario_integrated_playtest_trace", "Ready source without trace needs trace")
	_assert(String(snapshot.get("gate", "")) == "needs_scenario_integrated_playtest_trace", "Gate asks for trace")
	_assert(issue_ids.has("scenario_integrated_playtest_trace_missing"), "Missing integrated trace is explicit")
	_assert(not bool(snapshot.get("scenario_integrated_playtest_passed", true)), "Missing trace does not pass integrated playtest")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_integrated_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "scenario_integrated_playtest_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "scenario_integrated_playtest_regression", "Failed trace gate reports regression")
	_assert(missing_checks.has("release_mission_context_reached"), "Failed trace records missing entry context")
	_assert(missing_checks.has("post_go_feedback_observed"), "Failed trace records missing post-GO feedback")
	_assert(missing_checks.has("performance_budget_ok"), "Failed trace records missing performance budget")
	_assert(issue_ids.has("release_mission_context_missing"), "Missing entry issue is explicit")
	_assert(issue_ids.has("post_go_feedback_missing"), "Missing post-GO feedback issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice", "Regression routes back to acceptance slice")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_scenario_integrated_playtest() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "scenario_integrated_playtest_passed", "Good trace passes scenario integrated playtest")
	_assert(String(snapshot.get("gate", "")) == "scenario_integrated_playtest_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("scenario_integrated_playtest_passed", false)), "Pass flag is true")
	_assert(bool(snapshot.get("ready_for_player_feel_findings", false)), "Passed integrated playtest is ready for player-feel findings")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("ENTRY"), "Integrated line names ENTRY")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("FOB"), "Integrated line names FOB")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("NEXT"), "Integrated line names NEXT")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("GO"), "Integrated line names GO")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("FEEDBACK"), "Integrated line names FEEDBACK")
	_assert(answered_questions.has("where_did_player_start"), "Slice answers entry point")
	_assert(answered_questions.has("what_was_confirmed"), "Slice answers confirm")
	_assert(answered_questions.has("what_happened_after_go"), "Slice answers post-GO")
	_assert(answered_questions.has("did_it_return_to_next"), "Slice answers loop return")
	_assert(answered_questions.has("were_boundaries_preserved"), "Slice answers boundaries")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed slice recommends player-feel findings")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_scenario_integrated_playtest() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_integrated_playtest_snapshot"):
		_assert(false, "Controller exposes TASK_1021 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_integrated_playtest_snapshot(_source_acceptance_slice(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1021 schema matches")
	_assert(String(snapshot.get("status", "")) == "scenario_integrated_playtest_passed", "Controller TASK_1021 passes with trace")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("FEEDBACK"), "Controller TASK_1021 line names feedback")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1021 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_playtest"), "Command feedback embeds TASK_1021")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_playtest_line"), "Command feedback exports TASK_1021 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_playtest_status"), "Command feedback exports TASK_1021 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_playtest_gate"), "Command feedback exports TASK_1021 gate")
	controller.queue_free()


func _test_scenario_integrated_playtest_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1021 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1021", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1020", "Roundtrip keeps TASK_1020 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_acceptance_slice: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1021 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1021 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_acceptance_slice, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1021 service returns dictionary")
	return _read_only_fallback()


func _source_acceptance_slice() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1020",
		"source_task_id": "TASK_1019",
		"status": "scenario_acceptance_slice_passed",
		"gate": "scenario_acceptance_slice_passed",
		"scenario_acceptance_slice_passed": true,
		"ready_for_integrated_playtest": true,
		"scenario_acceptance_line": "SCENARIO PASS: FOB rund | Rollen klar | NEXT bereit | GO separat | FEEDBACK gelesen | PASS",
		"source_scenario_playability_line": "SCENARIO PASS: FOB rund | Rollen klar | NEXT bereit | GO separat | FEEDBACK gelesen",
		"answered_player_questions": [
			"where_am_i",
			"what_is_objective",
			"what_do_alpha_bravo_do",
			"what_is_next",
			"what_happens_only_after_go",
			"what_is_next_after_feedback",
			"who_owns_truth",
		],
		"read_only": true,
		"read_only_capture": true,
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
		"trace_id": "scenario_integrated_fixture",
		"release_mission_context_reached": true,
		"command_feedback_embeds_acceptance_slice": true,
		"fob_entry_read_in_context": true,
		"objective_read_in_context": true,
		"roles_read_in_context": true,
		"next_confirm_go_loop_run_in_context": true,
		"confirm_path_reused": true,
		"go_path_reused": true,
		"go_separation_observed": true,
		"post_go_feedback_observed": true,
		"feedback_returns_to_next": true,
		"no_command_before_confirm": true,
		"no_auto_go": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"performance_budget_ok": true,
		"entry_line": "ENTRY Release Mission erreicht, FOB-Griff sichtbar.",
		"post_go_line": "FEEDBACK nach GO sichtbar, NEXT wieder bereit.",
		"observed_frame_budget_ms": 16.0,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["release_mission_context_reached"] = false
	trace["post_go_feedback_observed"] = false
	trace["performance_budget_ok"] = false
	trace["entry_line"] = ""
	trace["post_go_line"] = ""
	trace["observed_frame_budget_ms"] = 44.0
	return trace


func _read_only_fallback() -> Dictionary:
	return {
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


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
