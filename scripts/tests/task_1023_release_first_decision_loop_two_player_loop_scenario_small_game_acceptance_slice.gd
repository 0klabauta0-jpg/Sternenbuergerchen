extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1023_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.v1"
const NEXT_TASK := "TASK_1024 - Release First Decision Loop Two Player Loop Scenario Release Candidate Playtest"
const POLISH_TASK := "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1023 Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_acceptance_trace()
	_test_failed_trace_reports_small_game_acceptance_regression()
	_test_good_trace_accepts_small_game_slice()
	_test_controller_exports_small_game_acceptance_slice()
	_test_small_game_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1023_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_1023_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1023 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1023 small-game acceptance service exists")
	_assert(task_text.contains("TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice"), "Task names TASK_1023")
	_assert(task_text.contains(NEXT_TASK), "Task names release-candidate playtest follow-up")
	_assert(status_text.contains("TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice"), "Implementation status tracks TASK_1023")
	_assert(roadmap_text.contains("TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice (implementiert"), "Roadmap marks TASK_1023 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice (TASK_1023)"), "Mission feedback contract documents TASK_1023")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice (TASK_1023)"), "Decision clarity contract documents TASK_1023")
	_assert(service_text.contains(SCHEMA), "Small-game acceptance service exposes stable TASK_1023 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1023\""), "Small-game acceptance service writes TASK_1023 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1022\""), "Small-game acceptance service links TASK_1022")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Small-game acceptance service defines required checks")
	_assert(service_text.contains("\"small_game_acceptance_slice_passed\""), "Small-game acceptance exposes pass flag")
	_assert(service_text.contains("\"ready_for_release_candidate_playtest\""), "Small-game acceptance exposes release-candidate readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Small-game acceptance creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Small-game acceptance creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Small-game acceptance creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_SMALL_GAME_ACCEPTANCE_SLICE_SCRIPT"), "Controller preloads TASK_1023 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_snapshot"), "Controller exposes TASK_1023 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_line"), "Command feedback exports TASK_1023 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_status"), "Command feedback exports TASK_1023 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1023")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_accepted_for_small_game"), "Missing source reports acceptance mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked small-game acceptance snapshot remains read-only")


func _test_ready_source_without_trace_needs_acceptance_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_findings(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1023")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1023", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1022", "Snapshot links TASK_1022")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_small_game_acceptance_slice", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_small_game_acceptance_trace", "Ready source without trace needs acceptance trace")
	_assert(String(snapshot.get("gate", "")) == "needs_small_game_acceptance_trace", "Gate asks for small-game acceptance trace")
	_assert(issue_ids.has("small_game_acceptance_trace_missing"), "Missing small-game acceptance trace is explicit")
	_assert(not bool(snapshot.get("small_game_acceptance_slice_passed", true)), "Missing trace does not pass acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_small_game_acceptance_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_findings(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_acceptance_checks", []))
	_assert(String(snapshot.get("status", "")) == "small_game_acceptance_regression_found", "Failed trace reports small-game acceptance regression")
	_assert(String(snapshot.get("gate", "")) == "small_game_acceptance_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("post_go_feedback_returns_to_next"), "Failed trace records missing feedback-to-NEXT")
	_assert(missing_checks.has("two_player_context_clear"), "Failed trace records missing two-player context")
	_assert(missing_checks.has("multiplayer_boundary_preserved"), "Failed trace records missing multiplayer boundary")
	_assert(issue_ids.has("post_go_feedback_does_not_return_to_next"), "Missing feedback-to-NEXT issue is explicit")
	_assert(issue_ids.has("two_player_context_unclear"), "Missing two-player context issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Regression routes back to TASK_1023 polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_accepts_small_game_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_findings(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "small_game_acceptance_slice_passed", "Good trace passes small-game acceptance")
	_assert(String(snapshot.get("gate", "")) == "small_game_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("small_game_acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(bool(snapshot.get("ready_for_release_candidate_playtest", false)), "Good trace is ready for release-candidate playtest")
	_assert(String(snapshot.get("small_game_acceptance_line", "")).contains("FOB"), "Acceptance line names FOB")
	_assert(String(snapshot.get("small_game_acceptance_line", "")).contains("NEXT"), "Acceptance line names NEXT")
	_assert(String(snapshot.get("small_game_acceptance_line", "")).contains("GO separat"), "Acceptance line names GO boundary")
	_assert(String(snapshot.get("small_game_acceptance_line", "")).contains("FEEDBACK"), "Acceptance line names feedback")
	_assert(answered_questions.has("where_do_i_start"), "Acceptance answers start")
	_assert(answered_questions.has("what_is_next"), "Acceptance answers next grip")
	_assert(answered_questions.has("what_requires_go"), "Acceptance answers GO boundary")
	_assert(answered_questions.has("what_happens_after_go"), "Acceptance answers post-GO")
	_assert(answered_questions.has("who_owns_truth"), "Acceptance answers ownership")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 7, "Acceptance covers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed acceptance recommends release-candidate playtest")
	_assert(_snapshot_is_read_only(snapshot), "Passed acceptance remains read-only")


func _test_controller_exports_small_game_acceptance_slice() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_snapshot"):
		_assert(false, "Controller exposes TASK_1023 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_snapshot(_source_player_feel_findings(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1023 schema matches")
	_assert(String(snapshot.get("status", "")) == "small_game_acceptance_slice_passed", "Controller TASK_1023 passes with trace")
	_assert(String(snapshot.get("small_game_acceptance_line", "")).contains("NEXT"), "Controller TASK_1023 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1023 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice"), "Command feedback embeds TASK_1023")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_line"), "Command feedback exports TASK_1023 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_small_game_acceptance_slice_status"), "Command feedback exports TASK_1023 status")
	controller.queue_free()


func _test_small_game_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_findings(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1023 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1023", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1022", "Roundtrip keeps TASK_1022 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_findings: Dictionary, acceptance_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1023 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1023 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_findings, acceptance_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1023 service returns dictionary")
	return _read_only_fallback()


func _source_player_feel_findings() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1022",
		"source_task_id": "TASK_1021",
		"status": "accepted_for_small_game_acceptance_slice",
		"gate": "scenario_integrated_player_feel_accepted",
		"ready_for_small_game_acceptance_slice": true,
		"scenario_integrated_player_feel_summary_line": "SCENARIO INTEGRATED FEEL PASS: FOB, NEXT, GO und FEEDBACK fuehlen sich rund an.",
		"positive_findings": [
			"scenario_integrated_playtest_passed",
			"integrated_entry_feels_clear",
			"fob_grip_feels_round",
			"next_confirm_go_feels_clear",
			"post_go_feedback_invites_next_grip",
			"loop_returns_without_confusion",
			"hud_feels_calm",
			"performance_feels_responsive",
			"multiplayer_boundary_feels_clear",
			"two_player_context_feels_clear",
			"small_game_feels_round",
		],
		"positive_finding_count": 11,
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
	var checks: Array = [
		"entry_fob_next_visible",
		"objective_and_roles_clear",
		"next_confirm_go_boundary_clear",
		"go_stays_separate",
		"post_go_feedback_returns_to_next",
		"hud_calm",
		"performance_feels_responsive",
		"two_player_context_clear",
		"multiplayer_boundary_preserved",
		"no_new_hud_gameplay_truth",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"entry_fob_next_visible": true,
		"objective_and_roles_clear": true,
		"next_confirm_go_boundary_clear": true,
		"go_stays_separate": true,
		"post_go_feedback_returns_to_next": true,
		"hud_calm": true,
		"performance_feels_responsive": true,
		"two_player_context_clear": true,
		"multiplayer_boundary_preserved": true,
		"no_new_hud_gameplay_truth": true,
		"answered_player_questions": [
			"where_do_i_start",
			"what_is_the_objective",
			"what_do_alpha_bravo_do",
			"what_is_next",
			"what_requires_go",
			"what_happens_after_go",
			"who_owns_truth",
		],
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["entry_fob_next_visible", "go_stays_separate"]
	trace["post_go_feedback_returns_to_next"] = false
	trace["two_player_context_clear"] = false
	trace["multiplayer_boundary_preserved"] = false
	trace["answered_player_questions"] = ["what_requires_go"]
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
