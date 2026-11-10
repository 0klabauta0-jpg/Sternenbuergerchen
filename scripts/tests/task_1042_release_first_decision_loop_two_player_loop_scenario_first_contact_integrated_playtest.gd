extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH := "res://docs/tasks/TASK_1042_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.v1"
const NEXT_TASK := "TASK_1043 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings"
const FALLBACK_TASK := "TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1042 Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_nonempty_trace_with_explicit_false_still_needs_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_integrated_playtest()
	await _test_controller_exports_integrated_playtest()
	_test_integrated_playtest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1042_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest: FAILED")
		quit(1)
		return
	print("TASK_1042_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1042 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1042 integrated playtest service exists")
	_assert(task_text.contains("TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest"), "Task names TASK_1042")
	_assert(task_text.contains(NEXT_TASK), "Task names player-feel findings follow-up")
	_assert(status_text.contains("TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest"), "Implementation status tracks TASK_1042")
	_assert(roadmap_text.contains("TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest (implementiert"), "Roadmap marks TASK_1042 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest (TASK_1042)"), "Mission feedback contract documents TASK_1042")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest (TASK_1042)"), "Decision clarity contract documents TASK_1042")
	_assert(service_text.contains(SCHEMA), "First-contact integrated playtest service exposes stable TASK_1042 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1042\""), "First-contact integrated playtest service writes TASK_1042 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1041\""), "First-contact integrated playtest service links TASK_1041")
	_assert(service_text.contains("REQUIRED_INTEGRATED_CHECKS"), "First-contact integrated playtest service defines required checks")
	_assert(service_text.contains("\"first_contact_integrated_playtest_passed\""), "First-contact integrated playtest exposes pass flag")
	_assert(service_text.contains("\"ready_for_first_contact_player_feel_findings\""), "First-contact integrated playtest exposes player-feel readiness")
	_assert(service_text.contains("\"creates_command\": false"), "First-contact integrated playtest creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "First-contact integrated playtest creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "First-contact integrated playtest creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_INTEGRATED_PLAYTEST_SCRIPT"), "Controller preloads TASK_1042 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_snapshot"), "Controller exposes TASK_1042 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_line"), "Command feedback exports TASK_1042 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_status"), "Command feedback exports TASK_1042 status")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_gate"), "Command feedback exports TASK_1042 gate")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1042")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(blocker_ids.has("source_pass_flag_missing"), "Missing source reports missing pass flag")
	_assert(blocker_ids.has("source_not_ready_for_first_contact_integrated_playtest"), "Missing source reports not ready")
	_assert(blocker_ids.has("source_first_contact_line_missing"), "Missing source reports missing line")
	_assert(_snapshot_is_read_only(snapshot), "Blocked first-contact integrated snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1042")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1042", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1041", "Snapshot links TASK_1041")
	_assert(String(snapshot.get("source_status", "")) == "first_contact_acceptance_slice_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_integrated_playtest_trace", "Ready source without trace needs integrated trace")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_integrated_playtest_trace", "Gate asks for integrated trace")
	_assert(issue_ids.has("first_contact_integrated_playtest_trace_missing"), "Missing integrated trace is explicit")
	_assert(not bool(snapshot.get("first_contact_integrated_playtest_passed", true)), "Missing trace does not pass integrated playtest")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_nonempty_trace_with_explicit_false_still_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _explicit_false_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(not bool(snapshot.get("trace_available", true)), "Explicit false trace stays unavailable")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_integrated_playtest_trace", "Explicit false trace still needs integrated trace")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_integrated_playtest_trace", "Explicit false trace keeps needs-trace gate")
	_assert(issue_ids.has("first_contact_integrated_playtest_trace_missing"), "Explicit false trace reports missing integrated trace")
	_assert(not bool(snapshot.get("first_contact_integrated_playtest_passed", true)), "Explicit false trace does not pass integrated playtest")
	_assert(_snapshot_is_read_only(snapshot), "Explicit false trace snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_integrated_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "first_contact_integrated_playtest_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "first_contact_integrated_playtest_regression", "Failed trace gate reports regression")
	_assert(missing_checks.has("release_mission_context_reached"), "Failed trace records missing release mission context")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-NEXT")
	_assert(missing_checks.has("performance_budget_ok"), "Failed trace records missing performance budget")
	_assert(issue_ids.has("release_mission_context_missing"), "Missing release mission context issue is explicit")
	_assert(issue_ids.has("feedback_returns_to_next_missing"), "Missing feedback-to-NEXT issue is explicit")
	_assert(issue_ids.has("performance_budget_exceeded"), "Missing performance budget issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == FALLBACK_TASK, "Regression routes back to TASK_1041 acceptance slice")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_integrated_playtest() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "first_contact_integrated_playtest_passed", "Good trace passes integrated playtest")
	_assert(String(snapshot.get("gate", "")) == "first_contact_integrated_playtest_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("first_contact_integrated_playtest_passed", false)), "Pass flag is true")
	_assert(bool(snapshot.get("ready_for_first_contact_player_feel_findings", false)), "Passed integrated playtest is ready for player-feel findings")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("ENTRY"), "Integrated line names ENTRY")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("CONTACT"), "Integrated line names CONTACT")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("WHY"), "Integrated line names WHY")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("FIRE/WAIT"), "Integrated line names FIRE/WAIT")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("GO"), "Integrated line names GO")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("FEEDBACK"), "Integrated line names FEEDBACK")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("NEXT"), "Integrated line names NEXT")
	_assert(answered_questions.has("where_did_player_start"), "Slice answers entry point")
	_assert(answered_questions.has("who_has_contact"), "Slice answers contact")
	_assert(answered_questions.has("why_is_it_risky"), "Slice answers why")
	_assert(answered_questions.has("what_is_fire_wait_choice"), "Slice answers FIRE/WAIT")
	_assert(answered_questions.has("what_happened_after_go"), "Slice answers post-GO")
	_assert(answered_questions.has("did_it_return_to_next"), "Slice answers loop return")
	_assert(answered_questions.has("were_boundaries_preserved"), "Slice answers system boundaries")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed slice recommends player-feel findings")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_integrated_playtest() -> void:
	# The complete report reads mission siblings and parent metadata. Use the
	# real scene boundary rather than a detached controller with no owners.
	var scene := MISSION_SCENE.instantiate()
	root.add_child(scene)
	for _frame in range(12):
		await process_frame
	var controller: Node = scene.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_snapshot"):
		_assert(false, "Controller exposes TASK_1042 snapshot")
		scene.queue_free()
		await process_frame
		return
	var trace_needed_snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_snapshot(_source_acceptance_slice(), {})
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_snapshot(_source_acceptance_slice(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	var embedded_snapshot: Dictionary = Dictionary(feedback.get("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest", {}))
	_assert(String(trace_needed_snapshot.get("status", "")) == "needs_first_contact_integrated_playtest_trace", "Controller TASK_1042 {} trace path needs integrated trace")
	_assert(String(trace_needed_snapshot.get("gate", "")) == "needs_first_contact_integrated_playtest_trace", "Controller TASK_1042 {} trace gate needs trace")
	_assert(_issue_ids(Array(trace_needed_snapshot.get("issues", []))).has("first_contact_integrated_playtest_trace_missing"), "Controller TASK_1042 {} trace path reports missing integrated trace")
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1042 schema matches")
	_assert(String(snapshot.get("status", "")) == "first_contact_integrated_playtest_passed", "Controller TASK_1042 passes with trace")
	_assert(String(snapshot.get("integrated_playtest_line", "")).contains("FEEDBACK"), "Controller TASK_1042 line names feedback")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1042 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest"), "Command feedback embeds TASK_1042")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_line"), "Command feedback exports TASK_1042 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_status"), "Command feedback exports TASK_1042 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_gate"), "Command feedback exports TASK_1042 gate")
	_assert(String(embedded_snapshot.get("integrated_playtest_line", "")) == String(feedback.get("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_line", "")), "Command feedback TASK_1042 line matches embedded snapshot")
	_assert(String(embedded_snapshot.get("status", "")) == String(feedback.get("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_status", "")), "Command feedback TASK_1042 status matches embedded snapshot")
	_assert(String(embedded_snapshot.get("gate", "")) == String(feedback.get("release_first_decision_loop_two_player_loop_scenario_first_contact_integrated_playtest_gate", "")), "Command feedback TASK_1042 gate matches embedded snapshot")
	_assert(_snapshot_is_read_only(embedded_snapshot), "Embedded TASK_1042 command feedback snapshot remains read-only")
	scene.queue_free()
	for _frame in range(3):
		await process_frame


func _test_integrated_playtest_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_acceptance_slice(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1042 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1042", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1041", "Roundtrip keeps TASK_1041 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_acceptance_slice: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1042 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1042 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_acceptance_slice, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1042 service returns dictionary")
	return _read_only_fallback()


func _source_acceptance_slice() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1041",
		"source_task_id": "TASK_1040",
		"status": "first_contact_acceptance_slice_passed",
		"gate": "first_contact_acceptance_slice_passed",
		"first_contact_acceptance_slice_passed": true,
		"ready_for_first_contact_integrated_playtest": true,
		"first_contact_acceptance_line": "CONTACT klar | WHY sichtbar | NEXT bereit | FIRE/WAIT lesbar | GO separat | FEEDBACK zurueck zu NEXT | PASS",
		"source_polish_line": "CONTACT rund | WHY klar | NEXT bereit | FIRE/WAIT sichtbar | GO separat",
		"answered_player_questions": [
			"who_has_contact",
			"why_is_it_risky",
			"what_is_next",
			"what_is_fire_wait_choice",
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
		"trace_id": "first_contact_integrated_fixture",
		"release_mission_context_reached": true,
		"command_feedback_embeds_acceptance_slice": true,
		"first_contact_surface_read_in_context": true,
		"why_surface_read_in_context": true,
		"next_decision_visible_in_context": true,
		"fire_wait_choice_run_in_context": true,
		"go_path_reused": true,
		"go_separation_observed": true,
		"post_go_feedback_observed": true,
		"feedback_returns_to_next": true,
		"no_command_before_go": true,
		"no_auto_go": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"performance_budget_ok": true,
		"no_new_hud_gameplay_truth": true,
		"entry_line": "ENTRY Release Mission erreicht, CONTACT und WHY bleiben im Mission-Kontext lesbar.",
		"post_go_line": "FEEDBACK nach GO bestaetigt Wirkung, NEXT ist sofort wieder sichtbar.",
		"observed_frame_budget_ms": 16.0,
		"answered_player_questions": [
			"where_did_player_start",
			"who_has_contact",
			"why_is_it_risky",
			"what_is_fire_wait_choice",
			"what_happened_after_go",
			"did_it_return_to_next",
			"were_boundaries_preserved",
		],
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["release_mission_context_reached"] = false
	trace["feedback_returns_to_next"] = false
	trace["performance_budget_ok"] = false
	trace["entry_line"] = ""
	trace["post_go_line"] = ""
	trace["observed_frame_budget_ms"] = 41.0
	trace["answered_player_questions"] = [
		"where_did_player_start",
		"what_happened_after_go",
	]
	return trace


func _explicit_false_trace() -> Dictionary:
	return {
		"trace_available": false,
		"trace_id": "explicit_false_trace",
		"release_mission_context_reached": true,
	}


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
