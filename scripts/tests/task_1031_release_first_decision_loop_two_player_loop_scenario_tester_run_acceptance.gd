extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1031_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run.v1"
const NEXT_TASK := "TASK_1032 - Release First Decision Loop Two Player Loop Scenario Next Playable Slice Plan"
const REVIEW_TASK := "TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance"
const POLISH_TASK := "TASK_1031 - Release First Decision Loop Two Player Loop Scenario Acceptance Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1031 Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance ===")
	_test_docs_and_static_hooks()
	_test_missing_tester_run_blocks()
	_test_unready_tester_run_blocks()
	_test_ready_tester_run_without_acceptance_review_needs_review()
	_test_incomplete_acceptance_routes_to_completion()
	_test_issue_flags_route_to_acceptance_polish()
	_test_clean_acceptance_marks_ready_for_next_slice()
	_test_controller_exports_tester_run_acceptance()
	_test_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1031_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance: FAILED")
		quit(1)
		return
	print("TASK_1031_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1031 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1031 acceptance service exists")
	_assert(task_text.contains("TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance"), "Task names TASK_1031")
	_assert(task_text.contains(NEXT_TASK), "Task names next playable slice follow-up")
	_assert(status_text.contains("TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance"), "Implementation status tracks TASK_1031")
	_assert(roadmap_text.contains("TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance (implementiert"), "Roadmap marks TASK_1031 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance (TASK_1031)"), "Mission feedback contract documents TASK_1031")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance (TASK_1031)"), "Decision clarity contract documents TASK_1031")
	_assert(service_text.contains(SCHEMA), "Acceptance service exposes stable TASK_1031 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1031\""), "Acceptance service writes TASK_1031 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1030\""), "Acceptance service links TASK_1030")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Acceptance service defines required checks")
	_assert(service_text.contains("\"tester_run_accepted\""), "Acceptance service exposes accepted flag")
	_assert(service_text.contains("\"ready_for_next_playable_slice\""), "Acceptance service exposes next-slice readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Acceptance creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Acceptance creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Acceptance creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_TESTER_RUN_ACCEPTANCE_SCRIPT"), "Controller preloads TASK_1031 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_snapshot"), "Controller exposes TASK_1031 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_line"), "Command feedback exports TASK_1031 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_status"), "Command feedback exports TASK_1031 status")


func _test_missing_tester_run_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_tester_run", "Missing source blocks TASK_1031")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_tester_run_not_ready"), "Missing source reports tester-run mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked acceptance snapshot remains read-only")


func _test_unready_tester_run_blocks() -> void:
	var source: Dictionary = _tester_run_ready()
	source["status"] = "needs_tester_run_completion"
	source["tester_run_ready"] = false
	source["ready_for_acceptance_review"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_tester_run", "Unready TASK_1030 source blocks")
	_assert(blocker_ids.has("source_tester_run_not_ready"), "Unready source reports tester-run mismatch")
	_assert(not bool(snapshot.get("tester_run_accepted", true)), "Unready source is not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source acceptance remains read-only")


func _test_ready_tester_run_without_acceptance_review_needs_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_tester_run_ready(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_acceptance_checks", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1031")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1031", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1030", "Snapshot links TASK_1030")
	_assert(String(snapshot.get("source_status", "")) == "tester_run_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_acceptance_review", "Ready tester-run without review needs acceptance review")
	_assert(String(snapshot.get("gate", "")) == "needs_acceptance_review", "Gate asks for acceptance review")
	_assert(issue_ids.has("acceptance_review_missing"), "Missing acceptance review is explicit")
	_assert(missing_checks.has("known_risks_accepted"), "Missing review exposes risk acceptance check")
	_assert(not bool(snapshot.get("tester_run_accepted", true)), "Missing review does not accept tester run")
	_assert(_snapshot_is_read_only(snapshot), "Acceptance-needed snapshot remains read-only")


func _test_incomplete_acceptance_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_tester_run_ready(), _incomplete_acceptance())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_acceptance_checks", []))
	_assert(String(snapshot.get("status", "")) == "needs_acceptance_review_completion", "Incomplete acceptance reports completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_acceptance_review_completion", "Incomplete acceptance gate names completion")
	_assert(missing_checks.has("known_risks_accepted"), "Incomplete acceptance records missing risk check")
	_assert(missing_checks.has("next_slice_chosen"), "Incomplete acceptance records missing next-slice check")
	_assert(issue_ids.has("acceptance_checks_missing"), "Missing acceptance checks issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == REVIEW_TASK, "Incomplete acceptance loops on TASK_1031")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete acceptance snapshot remains read-only")


func _test_issue_flags_route_to_acceptance_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_tester_run_ready(), _acceptance_review(true, _all_check_ids(), ["performance_not_accepted", "needs_visible_polish"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "tester_run_acceptance_regression_found", "Issue flags report acceptance regression")
	_assert(String(snapshot.get("gate", "")) == "tester_run_acceptance_regression_found", "Issue gate reports acceptance regression")
	_assert(issue_ids.has("acceptance_issue_performance_not_accepted"), "Performance acceptance issue is explicit")
	_assert(issue_ids.has("acceptance_issue_needs_visible_polish"), "Visible-polish issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to acceptance polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue acceptance remains read-only")


func _test_clean_acceptance_marks_ready_for_next_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_tester_run_ready(), _acceptance_review(true, _all_check_ids(), []))
	var line: String = String(snapshot.get("acceptance_line", ""))
	var notes: Dictionary = Dictionary(snapshot.get("acceptance_notes", {}))
	_assert(String(snapshot.get("status", "")) == "tester_run_accepted", "Clean review accepts tester run")
	_assert(String(snapshot.get("gate", "")) == "tester_run_accepted", "Clean review gate accepted")
	_assert(bool(snapshot.get("tester_run_accepted", false)), "Clean review sets accepted flag")
	_assert(bool(snapshot.get("ready_for_next_playable_slice", false)), "Clean review is ready for next playable slice")
	_assert(line.contains("ACCEPTED"), "Acceptance line names accepted")
	_assert(line.contains("EXE"), "Acceptance line names EXE")
	_assert(line.contains("FOB"), "Acceptance line names FOB")
	_assert(line.contains("NEXT"), "Acceptance line names NEXT")
	_assert(line.contains("GO"), "Acceptance line names GO")
	_assert(line.contains("FEEDBACK"), "Acceptance line names FEEDBACK")
	_assert(String(snapshot.get("release_build_path", "")).ends_with(".exe"), "Acceptance carries release exe path")
	_assert(String(notes.get("next_slice", "")).contains("naechster spielbarer Slice"), "Acceptance notes carry next slice")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean acceptance recommends next playable slice plan")
	_assert(_snapshot_is_read_only(snapshot), "Clean acceptance remains read-only")


func _test_controller_exports_tester_run_acceptance() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_snapshot"):
		_assert(false, "Controller exposes TASK_1031 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_snapshot(_tester_run_ready(), _acceptance_review(true, _all_check_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1031 schema matches")
	_assert(String(snapshot.get("status", "")) == "tester_run_accepted", "Controller TASK_1031 accepted with review")
	_assert(String(snapshot.get("acceptance_line", "")).contains("NEXT"), "Controller TASK_1031 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1031 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance"), "Command feedback embeds TASK_1031")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_line"), "Command feedback exports TASK_1031 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_tester_run_acceptance_status"), "Command feedback exports TASK_1031 status")
	controller.queue_free()


func _test_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_tester_run_ready(), _acceptance_review(true, _all_check_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1031 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1031", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1030", "Roundtrip keeps TASK_1030 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_tester_run: Dictionary, acceptance_review: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1031 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1031 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_tester_run, acceptance_review)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1031 service returns dictionary")
	return _read_only_fallback()


func _tester_run_ready() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1030",
		"source_task_id": "TASK_1029",
		"status": "tester_run_ready",
		"gate": "tester_run_ready",
		"tester_run_line": "TESTER RUN READY: EXE | FOB | NEXT | GO | FEEDBACK | alles reagiert.",
		"tester_run_ready": true,
		"ready_for_acceptance_review": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
		"scenario_id": "release_first_decision_loop_two_player_loop",
		"tester_instructions": "Starte Singleplayer, pruefe FOB, NEXT, GO und FEEDBACK.",
		"operator_goal": "FOB/NEXT/GO/FEEDBACK als kleinen Spielmoment sichtbar spielen.",
		"known_risks": ["Manueller Sichttest bleibt noetig."],
		"tester_notes": {
			"tester_summary": "Frische EXE gestartet, FOB/NEXT/GO/FEEDBACK geprueft.",
			"singleplayer_note": "Homebase und FOB sind erreichbar.",
			"mission_note": "NEXT/GO/FEEDBACK reagieren im kleinen Spielmoment.",
			"performance_note": "Fuehlt sich fuer diesen Slice schnell genug an.",
			"next_note": "TASK_1031 Acceptance Review schneiden.",
		},
		"test_result_summary": "Tester Run abgeschlossen.",
		"required_tester_run_checks": [
			"handoff_packet_used",
			"fresh_release_exe_started",
			"singleplayer_homebase_actionable",
			"fob_next_go_feedback_seen",
			"first_loop_reacts",
			"no_input_dead_end",
			"performance_feels_fast",
			"hud_does_not_block",
			"multiplayer_boundary_preserved",
			"tester_notes_exported",
		],
		"completed_tester_run_checks": [
			"handoff_packet_used",
			"fresh_release_exe_started",
			"singleplayer_homebase_actionable",
			"fob_next_go_feedback_seen",
			"first_loop_reacts",
			"no_input_dead_end",
			"performance_feels_fast",
			"hud_does_not_block",
			"multiplayer_boundary_preserved",
			"tester_notes_exported",
		],
		"missing_tester_run_checks": [],
		"issue_flags": [],
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


func _incomplete_acceptance() -> Dictionary:
	return _acceptance_review(true, [
		"tester_run_ready",
		"release_files_accepted",
		"singleplayer_path_accepted",
		"fob_next_go_feedback_accepted",
		"performance_accepted",
	], [])


func _acceptance_review(done: bool, completed_checks: Array, issue_ids: Array) -> Dictionary:
	return {
		"acceptance_review_available": true,
		"acceptance_review_done": done,
		"completed_acceptance_checks": completed_checks,
		"issue_flags": issue_ids,
		"acceptance_summary": "Tester Run als kleiner FOB/NEXT/GO/FEEDBACK-Spielmoment akzeptiert.",
		"risk_note": "Bekannte Risiken sind fuer den naechsten Slice akzeptiert.",
		"polish_note": "Keine blockernde Sichtpolitur fuer diesen Acceptance-Schnitt.",
		"next_slice": "naechster spielbarer Slice: erster Kampfkontakt mit lesbarer Entscheidung.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_check_ids() -> Array:
	return [
		"tester_run_ready",
		"release_files_accepted",
		"singleplayer_path_accepted",
		"fob_next_go_feedback_accepted",
		"performance_accepted",
		"hud_boundary_accepted",
		"multiplayer_boundary_accepted",
		"known_risks_accepted",
		"next_slice_chosen",
	]


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
