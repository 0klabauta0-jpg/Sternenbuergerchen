extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1020_release_first_decision_loop_two_player_loop_scenario_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_acceptance_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_acceptance_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visual_findings.v1"
const NEXT_TASK := "TASK_1021 - Release First Decision Loop Two Player Loop Scenario Integrated Playtest"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1020 Release First Decision Loop Two Player Loop Scenario Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_accepted_findings_without_trace_needs_acceptance_trace()
	_test_failed_trace_reports_scenario_acceptance_regression()
	_test_good_trace_accepts_scenario_slice()
	_test_controller_exports_scenario_acceptance_slice()
	_test_scenario_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1020_release_first_decision_loop_two_player_loop_scenario_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_1020_release_first_decision_loop_two_player_loop_scenario_acceptance_slice: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1020 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1020 scenario acceptance service exists")
	_assert(task_text.contains("TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice"), "Task names TASK_1020")
	_assert(task_text.contains(NEXT_TASK), "Task names integrated playtest follow-up")
	_assert(status_text.contains("TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice"), "Implementation status tracks TASK_1020")
	_assert(roadmap_text.contains("TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice (implementiert"), "Roadmap marks TASK_1020 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Acceptance Slice (TASK_1020)"), "Mission feedback contract documents TASK_1020")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Acceptance Slice (TASK_1020)"), "Decision clarity contract documents TASK_1020")
	_assert(service_text.contains(SCHEMA), "Scenario acceptance service exposes stable TASK_1020 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1020\""), "Scenario acceptance service writes TASK_1020 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1019\""), "Scenario acceptance service links TASK_1019")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Scenario acceptance service defines required checks")
	_assert(service_text.contains("\"scenario_acceptance_slice_passed\""), "Scenario acceptance exposes pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "Scenario acceptance creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Scenario acceptance creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Scenario acceptance creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_ACCEPTANCE_SLICE_SCRIPT"), "Controller preloads TASK_1020 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_acceptance_slice_snapshot"), "Controller exposes TASK_1020 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_acceptance_slice_line"), "Command feedback exports TASK_1020 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_acceptance_slice_status"), "Command feedback exports TASK_1020 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1020")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_accepted_for_scenario_acceptance"), "Missing source reports not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Blocked scenario acceptance snapshot remains read-only")


func _test_accepted_findings_without_trace_needs_acceptance_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_visual_findings(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1020")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1020", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1019", "Snapshot links TASK_1019")
	_assert(String(snapshot.get("source_status", "")) == "accepted_for_scenario_acceptance_slice", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_scenario_acceptance_trace", "Accepted findings without trace need acceptance trace")
	_assert(String(snapshot.get("gate", "")) == "needs_scenario_acceptance_trace", "Gate asks for scenario acceptance trace")
	_assert(issue_ids.has("scenario_acceptance_trace_missing"), "Missing scenario acceptance trace is explicit")
	_assert(not bool(snapshot.get("scenario_acceptance_slice_passed", true)), "Missing trace does not pass acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_scenario_acceptance_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_visual_findings(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_acceptance_checks", []))
	_assert(String(snapshot.get("status", "")) == "scenario_acceptance_regression_found", "Failed trace reports scenario acceptance regression")
	_assert(String(snapshot.get("gate", "")) == "scenario_acceptance_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-NEXT")
	_assert(missing_checks.has("multiplayer_boundary_preserved"), "Failed trace records missing multiplayer boundary")
	_assert(issue_ids.has("feedback_does_not_return_to_next"), "Missing feedback-to-NEXT issue is explicit")
	_assert(issue_ids.has("multiplayer_boundary_risk"), "Missing multiplayer boundary issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Visual Polish", "Regression routes to TASK_1020 polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_accepts_scenario_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_visual_findings(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "scenario_acceptance_slice_passed", "Good trace passes scenario acceptance")
	_assert(String(snapshot.get("gate", "")) == "scenario_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("scenario_acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("scenario_acceptance_line", "")).contains("FOB"), "Acceptance line names FOB")
	_assert(String(snapshot.get("scenario_acceptance_line", "")).contains("NEXT"), "Acceptance line names NEXT")
	_assert(String(snapshot.get("scenario_acceptance_line", "")).contains("GO"), "Acceptance line names GO")
	_assert(String(snapshot.get("scenario_acceptance_line", "")).contains("FEEDBACK"), "Acceptance line names FEEDBACK")
	_assert(answered_questions.has("where_am_i"), "Acceptance answers FOB location")
	_assert(answered_questions.has("what_is_objective"), "Acceptance answers objective")
	_assert(answered_questions.has("what_do_alpha_bravo_do"), "Acceptance answers roles")
	_assert(answered_questions.has("what_happens_only_after_go"), "Acceptance answers GO boundary")
	_assert(answered_questions.has("what_is_next_after_feedback"), "Acceptance answers next grip after feedback")
	_assert(answered_questions.has("who_owns_truth"), "Acceptance answers ownership")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 7, "Acceptance covers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed acceptance recommends integrated playtest")
	_assert(_snapshot_is_read_only(snapshot), "Passed acceptance remains read-only")


func _test_controller_exports_scenario_acceptance_slice() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_acceptance_slice_snapshot"):
		_assert(false, "Controller exposes TASK_1020 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_acceptance_slice_snapshot(_accepted_visual_findings(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1020 schema matches")
	_assert(String(snapshot.get("status", "")) == "scenario_acceptance_slice_passed", "Controller TASK_1020 passes with trace")
	_assert(String(snapshot.get("scenario_acceptance_line", "")).contains("NEXT"), "Controller TASK_1020 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1020 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_acceptance_slice"), "Command feedback embeds TASK_1020")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_acceptance_slice_line"), "Command feedback exports TASK_1020 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_acceptance_slice_status"), "Command feedback exports TASK_1020 status")
	controller.queue_free()


func _test_scenario_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_accepted_visual_findings(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1020 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1020", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1019", "Roundtrip keeps TASK_1019 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_findings: Dictionary, acceptance_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1020 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1020 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_findings, acceptance_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1020 service returns dictionary")
	return _read_only_fallback()


func _accepted_visual_findings() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1019",
		"source_task_id": "TASK_1018",
		"status": "accepted_for_scenario_acceptance_slice",
		"recommended_next_task": "TASK_1020 - Release First Decision Loop Two Player Loop Scenario Acceptance Slice",
		"accepted": true,
		"manual_review_done": true,
		"issue_count": 0,
		"positive_finding_count": 17,
		"source_scenario_playability_line": "SCENARIO PASS: FOB rund | Rollen klar | NEXT bereit | GO separat | FEEDBACK gelesen",
		"source_scenario_playability_slice_passed": true,
		"source_review_ready": true,
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"review_notes": {
			"fob_entry_surface_visible": true,
			"fob_entry_surface_readable": true,
			"objective_surface_visible": true,
			"objective_surface_readable": true,
			"roles_surface_visible": true,
			"roles_surface_readable": true,
			"next_confirm_go_flow_visible": true,
			"next_confirm_go_flow_readable": true,
			"go_boundary_visible": true,
			"feedback_line_visible": true,
			"feedback_line_readable": true,
			"calm_hud_guidance_visible": true,
			"scenario_playability_line_visible": true,
			"no_new_hud_gameplay_truth": true,
			"multiplayer_boundary_preserved": true,
			"player_readability_ok": true,
		},
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
		"fob_entry_readable",
		"objective_readable",
		"roles_readable",
		"next_confirm_go_loop_clear",
		"feedback_returns_to_next",
		"go_boundary_clear",
		"hud_calm",
		"performance_feels_responsive",
		"multiplayer_boundary_preserved",
		"no_new_hud_gameplay_truth",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"fob_entry_readable": true,
		"objective_readable": true,
		"roles_readable": true,
		"next_confirm_go_loop_clear": true,
		"feedback_returns_to_next": true,
		"go_boundary_clear": true,
		"hud_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_preserved": true,
		"no_new_hud_gameplay_truth": true,
		"answered_player_questions": [
			"where_am_i",
			"what_is_objective",
			"what_do_alpha_bravo_do",
			"what_is_next",
			"what_happens_only_after_go",
			"what_is_next_after_feedback",
			"who_owns_truth",
		],
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["fob_entry_readable", "objective_readable", "go_boundary_clear"]
	trace["feedback_returns_to_next"] = false
	trace["multiplayer_boundary_preserved"] = false
	trace["answered_player_questions"] = ["where_am_i", "what_happens_only_after_go"]
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
