extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1027_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.v1"
const NEXT_TASK := "TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review"
const POLISH_TASK := "TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1027 Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_notes_needs_visible_smoke()
	_test_incomplete_notes_routes_to_completion()
	_test_issue_flags_route_to_polish()
	_test_clean_smoke_marks_visible_passed()
	_test_controller_exports_visible_ship_smoke()
	_test_visible_ship_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1027_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke: FAILED")
		quit(1)
		return
	print("TASK_1027_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1027 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1027 visible-ship-smoke service exists")
	_assert(task_text.contains("TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke"), "Task names TASK_1027")
	_assert(task_text.contains(NEXT_TASK), "Task names delivery-review follow-up")
	_assert(status_text.contains("TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke"), "Implementation status tracks TASK_1027")
	_assert(roadmap_text.contains("TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke (implementiert"), "Roadmap marks TASK_1027 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke (TASK_1027)"), "Mission feedback contract documents TASK_1027")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke (TASK_1027)"), "Decision clarity contract documents TASK_1027")
	_assert(service_text.contains(SCHEMA), "Visible-smoke service exposes stable TASK_1027 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1027\""), "Visible-smoke service writes TASK_1027 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1026\""), "Visible-smoke service links TASK_1026")
	_assert(service_text.contains("REQUIRED_VISIBLE_SHIP_SMOKE_CHECKS"), "Visible-smoke service defines required checks")
	_assert(service_text.contains("\"visible_ship_smoke_passed\""), "Visible-smoke service exposes pass flag")
	_assert(service_text.contains("\"ready_for_delivery_review\""), "Visible-smoke service exposes delivery readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Visible-smoke creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Visible-smoke creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Visible-smoke creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_VISIBLE_SHIP_SMOKE_SCRIPT"), "Controller preloads TASK_1027 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_snapshot"), "Controller exposes TASK_1027 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_line"), "Command feedback exports TASK_1027 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_status"), "Command feedback exports TASK_1027 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_ship_readiness", "Missing source blocks TASK_1027")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_ship_readiness_not_ready"), "Missing source reports ship-readiness mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked visible-smoke snapshot remains read-only")


func _test_ready_source_without_notes_needs_visible_smoke() -> void:
	var snapshot: Dictionary = _build_snapshot(_ship_readiness_ready(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1027")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1027", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1026", "Snapshot links TASK_1026")
	_assert(String(snapshot.get("source_status", "")) == "ship_readiness_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_visible_ship_smoke", "Ready source without notes needs visible ship smoke")
	_assert(String(snapshot.get("gate", "")) == "needs_visible_ship_smoke", "Gate asks for visible ship smoke")
	_assert(issue_ids.has("visible_ship_smoke_notes_missing"), "Missing smoke notes are explicit")
	_assert(not bool(snapshot.get("visible_ship_smoke_passed", true)), "Missing notes do not pass visible smoke")
	_assert(_snapshot_is_read_only(snapshot), "Visible-smoke-needed snapshot remains read-only")


func _test_incomplete_notes_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_ship_readiness_ready(), _incomplete_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_visible_ship_smoke_checks", []))
	_assert(String(snapshot.get("status", "")) == "needs_visible_ship_smoke_completion", "Incomplete notes report completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_visible_ship_smoke_completion", "Incomplete notes gate names completion")
	_assert(missing_checks.has("fob_visible"), "Incomplete notes record missing FOB visibility")
	_assert(missing_checks.has("feedback_visible"), "Incomplete notes record missing feedback visibility")
	_assert(issue_ids.has("visible_ship_smoke_checks_missing"), "Missing smoke checks issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke", "Incomplete notes route to TASK_1027 rerun")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete notes snapshot remains read-only")


func _test_issue_flags_route_to_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_ship_readiness_ready(), _notes(true, _all_check_ids(), ["stale_export_or_link", "input_dead_end"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "visible_ship_smoke_regression_found", "Issue flags report visible-smoke regression")
	_assert(String(snapshot.get("gate", "")) == "visible_ship_smoke_regression_found", "Issue gate reports visible-smoke regression")
	_assert(issue_ids.has("visible_smoke_issue_stale_export_or_link"), "Stale export/link issue is explicit")
	_assert(issue_ids.has("visible_smoke_issue_input_dead_end"), "Input dead-end issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to TASK_1027 polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_smoke_marks_visible_passed() -> void:
	var snapshot: Dictionary = _build_snapshot(_ship_readiness_ready(), _notes(true, _all_check_ids(), []))
	var line: String = String(snapshot.get("visible_ship_smoke_line", ""))
	_assert(String(snapshot.get("status", "")) == "visible_ship_smoke_passed", "Clean smoke marks visible smoke passed")
	_assert(String(snapshot.get("gate", "")) == "visible_ship_smoke_passed", "Clean smoke gate passed")
	_assert(bool(snapshot.get("visible_ship_smoke_passed", false)), "Clean smoke sets pass flag")
	_assert(bool(snapshot.get("ready_for_delivery_review", false)), "Clean smoke is ready for delivery review")
	_assert(line.contains("VISIBLE SHIP"), "Visible-smoke line names visible ship")
	_assert(line.contains("EXE"), "Visible-smoke line names EXE")
	_assert(line.contains("FOB"), "Visible-smoke line names FOB")
	_assert(line.contains("NEXT"), "Visible-smoke line names NEXT")
	_assert(line.contains("GO"), "Visible-smoke line names GO")
	_assert(line.contains("FEEDBACK"), "Visible-smoke line names feedback")
	_assert(String(snapshot.get("release_build_path", "")).ends_with(".exe"), "Clean smoke carries release exe path")
	_assert(Array(snapshot.get("completed_visible_ship_smoke_checks", [])).size() == _all_check_ids().size(), "Clean smoke records all completed checks")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean smoke recommends delivery review")
	_assert(_snapshot_is_read_only(snapshot), "Clean smoke remains read-only")


func _test_controller_exports_visible_ship_smoke() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_snapshot"):
		_assert(false, "Controller exposes TASK_1027 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_snapshot(_ship_readiness_ready(), _notes(true, _all_check_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1027 schema matches")
	_assert(String(snapshot.get("status", "")) == "visible_ship_smoke_passed", "Controller TASK_1027 passes with notes")
	_assert(String(snapshot.get("visible_ship_smoke_line", "")).contains("NEXT"), "Controller TASK_1027 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1027 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke"), "Command feedback embeds TASK_1027")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_line"), "Command feedback exports TASK_1027 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke_status"), "Command feedback exports TASK_1027 status")
	controller.queue_free()


func _test_visible_ship_smoke_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_ship_readiness_ready(), _notes(true, _all_check_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1027 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1027", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1026", "Roundtrip keeps TASK_1026 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_readiness: Dictionary, notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1027 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1027 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_readiness, notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1027 service returns dictionary")
	return _read_only_fallback()


func _ship_readiness_ready() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1026",
		"source_task_id": "TASK_1025",
		"status": "ship_readiness_ready",
		"gate": "ship_readiness_ready",
		"ship_readiness_line": "SHIP READY: FOB | NEXT | GO | FEEDBACK | kleiner Spielmoment",
		"ship_readiness_ready": true,
		"ready_for_visible_ship_smoke": true,
		"source_release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"ship_readiness_items": {
			"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
			"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
			"scenario_id": "release_first_decision_loop_two_player_loop",
			"tester_instructions": "Starte Singleplayer, pruefe FOB, NEXT, GO und FEEDBACK.",
			"operator_goal": "FOB/NEXT/GO/FEEDBACK als kleinen Spielmoment sichtbar spielen.",
			"known_risks": ["Manueller Sichttest bleibt noetig."],
			"handoff_items": ["release_build_path", "tester_instructions", "known_risks"],
			"multiplayer_boundary_note": "Smoke setzt keine Multiplayer-Wahrheit.",
			"hud_truth_note": "HUD liest nur Snapshots.",
			"ship_readiness_reviewed": true,
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


func _incomplete_notes() -> Dictionary:
	return _notes(true, ["fresh_release_folder_used", "release_exe_started", "singleplayer_clicked", "next_visible", "go_visible"], [])


func _notes(manual_done: bool, completed_checks: Array, issue_ids: Array) -> Dictionary:
	return {
		"notes_available": true,
		"manual_smoke_done": manual_done,
		"completed_visible_ship_smoke_checks": completed_checks,
		"issue_flags": issue_ids,
		"visible_smoke_notes": "Release-EXE gestartet; FOB/NEXT/GO/FEEDBACK sichtbar geprueft.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_check_ids() -> Array:
	return [
		"fresh_release_folder_used",
		"release_exe_started",
		"singleplayer_clicked",
		"fob_visible",
		"next_visible",
		"go_visible",
		"feedback_visible",
		"no_input_dead_end",
		"performance_feels_responsive",
		"no_stale_taskbar_link",
		"smoke_notes_exported",
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
