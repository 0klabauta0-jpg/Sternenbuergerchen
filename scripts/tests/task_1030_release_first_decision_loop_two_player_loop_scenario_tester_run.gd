extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1030_release_first_decision_loop_two_player_loop_scenario_tester_run.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_tester_run.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_tester_run.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_tester_run.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_handoff_packet.v1"
const NEXT_TASK := "TASK_1031 - Release First Decision Loop Two Player Loop Scenario Tester Run Acceptance"
const POLISH_TASK := "TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1030 Release First Decision Loop Two Player Loop Scenario Tester Run ===")
	_test_docs_and_static_hooks()
	_test_missing_handoff_blocks()
	_test_unready_handoff_blocks()
	_test_ready_handoff_without_tester_notes_needs_run()
	_test_incomplete_tester_run_routes_to_completion()
	_test_issue_flags_route_to_tester_polish()
	_test_clean_tester_run_marks_ready_for_acceptance()
	_test_controller_exports_tester_run()
	_test_tester_run_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1030_release_first_decision_loop_two_player_loop_scenario_tester_run: FAILED")
		quit(1)
		return
	print("TASK_1030_release_first_decision_loop_two_player_loop_scenario_tester_run: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1030 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1030 tester-run service exists")
	_assert(task_text.contains("TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run"), "Task names TASK_1030")
	_assert(task_text.contains(NEXT_TASK), "Task names tester-run acceptance follow-up")
	_assert(status_text.contains("TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run"), "Implementation status tracks TASK_1030")
	_assert(roadmap_text.contains("TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run (implementiert"), "Roadmap marks TASK_1030 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Tester Run (TASK_1030)"), "Mission feedback contract documents TASK_1030")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Tester Run (TASK_1030)"), "Decision clarity contract documents TASK_1030")
	_assert(service_text.contains(SCHEMA), "Tester-run service exposes stable TASK_1030 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1030\""), "Tester-run service writes TASK_1030 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1029\""), "Tester-run service links TASK_1029")
	_assert(service_text.contains("REQUIRED_TESTER_RUN_CHECKS"), "Tester-run service defines required checks")
	_assert(service_text.contains("\"tester_run_ready\""), "Tester-run service exposes ready flag")
	_assert(service_text.contains("\"ready_for_acceptance_review\""), "Tester-run exposes acceptance readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Tester run creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Tester run creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Tester run creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_TESTER_RUN_SCRIPT"), "Controller preloads TASK_1030 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_tester_run_snapshot"), "Controller exposes TASK_1030 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_tester_run_line"), "Command feedback exports TASK_1030 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_tester_run_status"), "Command feedback exports TASK_1030 status")


func _test_missing_handoff_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_handoff_packet", "Missing source blocks TASK_1030")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_handoff_packet_not_ready"), "Missing source reports handoff mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked tester-run snapshot remains read-only")


func _test_unready_handoff_blocks() -> void:
	var source: Dictionary = _handoff_packet_ready()
	source["status"] = "needs_handoff_packet"
	source["handoff_packet_ready"] = false
	source["ready_for_tester_run"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_handoff_packet", "Unready TASK_1029 source blocks")
	_assert(blocker_ids.has("source_handoff_packet_not_ready"), "Unready source reports handoff mismatch")
	_assert(not bool(snapshot.get("tester_run_ready", true)), "Unready source is not tester-run-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source tester run remains read-only")


func _test_ready_handoff_without_tester_notes_needs_run() -> void:
	var snapshot: Dictionary = _build_snapshot(_handoff_packet_ready(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_tester_run_checks", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1030")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1030", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1029", "Snapshot links TASK_1029")
	_assert(String(snapshot.get("source_status", "")) == "handoff_packet_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_tester_run", "Ready handoff without tester notes needs tester run")
	_assert(String(snapshot.get("gate", "")) == "needs_tester_run", "Gate asks for tester run")
	_assert(issue_ids.has("tester_run_notes_missing"), "Missing tester notes are explicit")
	_assert(missing_checks.has("fresh_release_exe_started"), "Missing notes expose fresh EXE check")
	_assert(not bool(snapshot.get("tester_run_ready", true)), "Missing notes do not mark tester run ready")
	_assert(_snapshot_is_read_only(snapshot), "Tester-run-needed snapshot remains read-only")


func _test_incomplete_tester_run_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_handoff_packet_ready(), _incomplete_run())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_tester_run_checks", []))
	_assert(String(snapshot.get("status", "")) == "needs_tester_run_completion", "Incomplete run reports completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_tester_run_completion", "Incomplete run gate names completion")
	_assert(missing_checks.has("first_loop_reacts"), "Incomplete run records missing loop reaction")
	_assert(missing_checks.has("performance_feels_fast"), "Incomplete run records missing performance check")
	_assert(issue_ids.has("tester_run_checks_missing"), "Missing tester checks issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1030 - Release First Decision Loop Two Player Loop Scenario Tester Run", "Incomplete run loops on TASK_1030")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete tester run snapshot remains read-only")


func _test_issue_flags_route_to_tester_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_handoff_packet_ready(), _tester_run(true, _all_check_ids(), ["performance_slow", "hud_blocks_action"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "tester_run_regression_found", "Issue flags report tester-run regression")
	_assert(String(snapshot.get("gate", "")) == "tester_run_regression_found", "Issue gate reports tester-run regression")
	_assert(issue_ids.has("tester_run_issue_performance_slow"), "Performance issue is explicit")
	_assert(issue_ids.has("tester_run_issue_hud_blocks_action"), "HUD-block issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to tester-run polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue tester run remains read-only")


func _test_clean_tester_run_marks_ready_for_acceptance() -> void:
	var snapshot: Dictionary = _build_snapshot(_handoff_packet_ready(), _tester_run(true, _all_check_ids(), []))
	var line: String = String(snapshot.get("tester_run_line", ""))
	_assert(String(snapshot.get("status", "")) == "tester_run_ready", "Clean run marks tester run ready")
	_assert(String(snapshot.get("gate", "")) == "tester_run_ready", "Clean run gate ready")
	_assert(bool(snapshot.get("tester_run_ready", false)), "Clean run sets tester-run-ready flag")
	_assert(bool(snapshot.get("ready_for_acceptance_review", false)), "Clean run is ready for acceptance review")
	_assert(line.contains("TESTER RUN READY"), "Tester-run line names ready")
	_assert(line.contains("EXE"), "Tester-run line names EXE")
	_assert(line.contains("FOB"), "Tester-run line names FOB")
	_assert(line.contains("NEXT"), "Tester-run line names NEXT")
	_assert(line.contains("GO"), "Tester-run line names GO")
	_assert(line.contains("FEEDBACK"), "Tester-run line names feedback")
	_assert(String(snapshot.get("release_build_path", "")).ends_with(".exe"), "Clean run carries release exe path")
	_assert(Dictionary(snapshot.get("tester_notes", {})).has("tester_summary"), "Clean run carries tester summary")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean run recommends acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Clean run remains read-only")


func _test_controller_exports_tester_run() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_tester_run_snapshot"):
		_assert(false, "Controller exposes TASK_1030 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_tester_run_snapshot(_handoff_packet_ready(), _tester_run(true, _all_check_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1030 schema matches")
	_assert(String(snapshot.get("status", "")) == "tester_run_ready", "Controller TASK_1030 ready with notes")
	_assert(String(snapshot.get("tester_run_line", "")).contains("NEXT"), "Controller TASK_1030 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1030 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_tester_run"), "Command feedback embeds TASK_1030")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_tester_run_line"), "Command feedback exports TASK_1030 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_tester_run_status"), "Command feedback exports TASK_1030 status")
	controller.queue_free()


func _test_tester_run_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_handoff_packet_ready(), _tester_run(true, _all_check_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1030 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1030", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1029", "Roundtrip keeps TASK_1029 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_handoff_packet: Dictionary, tester_run_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1030 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1030 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_handoff_packet, tester_run_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1030 service returns dictionary")
	return _read_only_fallback()


func _handoff_packet_ready() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1029",
		"source_task_id": "TASK_1028",
		"status": "handoff_packet_ready",
		"gate": "handoff_packet_ready",
		"handoff_packet_line": "HANDOFF READY: EXE | FOB | NEXT | GO | FEEDBACK | TASK_1030 Tester Run ausfuehren.",
		"handoff_packet_ready": true,
		"ready_for_tester_run": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
		"scenario_id": "release_first_decision_loop_two_player_loop",
		"tester_instructions": "Starte Singleplayer, pruefe FOB, NEXT, GO und FEEDBACK.",
		"operator_goal": "FOB/NEXT/GO/FEEDBACK als kleinen Spielmoment sichtbar spielen.",
		"known_risks": ["Manueller Sichttest bleibt noetig."],
		"handoff_notes": {
			"start_instruction": "Starte die frische EXE, klicke Einzelspieler, pruefe FOB/NEXT/GO/FEEDBACK.",
			"shortcut_warning": "Nicht die alte Taskleisten-Verknuepfung nutzen.",
			"risk_summary": "Manueller Sichttest bleibt noetig, ist fuer diesen Handoff akzeptiert.",
			"next_tester_action": "TASK_1030 Tester Run mit frischer EXE ausfuehren.",
			"multiplayer_note": "Zwei-Spieler-Kontext bleibt vorbereitet.",
		},
		"test_steps": [
			{"id": "start_fresh_exe", "text": "Starte die frische EXE.", "read_only": true},
			{"id": "verify_first_loop", "text": "Pruefe FOB/NEXT/GO/FEEDBACK.", "read_only": true},
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


func _incomplete_run() -> Dictionary:
	return _tester_run(true, ["handoff_packet_used", "fresh_release_exe_started", "singleplayer_homebase_actionable", "fob_next_go_feedback_seen"], [])


func _tester_run(done: bool, completed_checks: Array, issue_ids: Array) -> Dictionary:
	return {
		"tester_run_available": true,
		"tester_run_done": done,
		"completed_tester_run_checks": completed_checks,
		"issue_flags": issue_ids,
		"tester_summary": "Frische EXE gestartet, FOB/NEXT/GO/FEEDBACK geprueft.",
		"singleplayer_note": "Homebase und FOB sind erreichbar.",
		"mission_note": "NEXT/GO/FEEDBACK reagieren im kleinen Spielmoment.",
		"performance_note": "Fuehlt sich fuer diesen Slice schnell genug an.",
		"next_note": "TASK_1031 Acceptance Review schneiden.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_check_ids() -> Array:
	return [
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
