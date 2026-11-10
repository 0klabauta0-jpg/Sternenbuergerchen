extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1028_release_first_decision_loop_two_player_loop_scenario_delivery_review.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_delivery_review.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_delivery_review.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_delivery_review.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.v1"
const NEXT_TASK := "TASK_1029 - Release First Decision Loop Two Player Loop Scenario Handoff Packet"
const POLISH_TASK := "TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Polish"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1028 Release First Decision Loop Two Player Loop Scenario Delivery Review ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_unpassed_visible_smoke_blocks()
	_test_passed_source_without_review_needs_delivery_review()
	_test_incomplete_review_routes_to_completion()
	_test_issue_flags_route_to_delivery_polish()
	_test_clean_review_marks_delivery_ready()
	_test_controller_exports_delivery_review()
	_test_delivery_review_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1028_release_first_decision_loop_two_player_loop_scenario_delivery_review: FAILED")
		quit(1)
		return
	print("TASK_1028_release_first_decision_loop_two_player_loop_scenario_delivery_review: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1028 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1028 delivery-review service exists")
	_assert(task_text.contains("TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review"), "Task names TASK_1028")
	_assert(task_text.contains(NEXT_TASK), "Task names handoff-packet follow-up")
	_assert(status_text.contains("TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review"), "Implementation status tracks TASK_1028")
	_assert(roadmap_text.contains("TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review (implementiert"), "Roadmap marks TASK_1028 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Delivery Review (TASK_1028)"), "Mission feedback contract documents TASK_1028")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Delivery Review (TASK_1028)"), "Decision clarity contract documents TASK_1028")
	_assert(service_text.contains(SCHEMA), "Delivery-review service exposes stable TASK_1028 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1028\""), "Delivery-review service writes TASK_1028 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1027\""), "Delivery-review service links TASK_1027")
	_assert(service_text.contains("REQUIRED_DELIVERY_REVIEW_CHECKS"), "Delivery-review service defines required checks")
	_assert(service_text.contains("\"delivery_review_ready\""), "Delivery-review service exposes ready flag")
	_assert(service_text.contains("\"ready_for_handoff_packet\""), "Delivery-review exposes handoff readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Delivery-review creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Delivery-review creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Delivery-review creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_DELIVERY_REVIEW_SCRIPT"), "Controller preloads TASK_1028 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_delivery_review_snapshot"), "Controller exposes TASK_1028 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_delivery_review_line"), "Command feedback exports TASK_1028 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_delivery_review_status"), "Command feedback exports TASK_1028 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_visible_ship_smoke", "Missing source blocks TASK_1028")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_visible_smoke_not_passed"), "Missing source reports visible-smoke mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked delivery-review snapshot remains read-only")


func _test_unpassed_visible_smoke_blocks() -> void:
	var source: Dictionary = _visible_smoke_passed()
	source["status"] = "needs_visible_ship_smoke"
	source["visible_ship_smoke_passed"] = false
	source["ready_for_delivery_review"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked_until_visible_ship_smoke", "Unpassed TASK_1027 source blocks")
	_assert(blocker_ids.has("source_visible_smoke_not_passed"), "Unpassed source reports visible-smoke mismatch")
	_assert(not bool(snapshot.get("delivery_review_ready", true)), "Unpassed source is not delivery-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unpassed-source delivery review remains read-only")


func _test_passed_source_without_review_needs_delivery_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_visible_smoke_passed(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1028")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1028", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1027", "Snapshot links TASK_1027")
	_assert(String(snapshot.get("source_status", "")) == "visible_ship_smoke_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_delivery_review", "Passed source without review needs delivery review")
	_assert(String(snapshot.get("gate", "")) == "needs_delivery_review", "Gate asks for delivery review")
	_assert(issue_ids.has("delivery_review_notes_missing"), "Missing delivery notes are explicit")
	_assert(not bool(snapshot.get("delivery_review_ready", true)), "Missing notes do not mark delivery ready")
	_assert(_snapshot_is_read_only(snapshot), "Delivery-needed snapshot remains read-only")


func _test_incomplete_review_routes_to_completion() -> void:
	var snapshot: Dictionary = _build_snapshot(_visible_smoke_passed(), _incomplete_review())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_delivery_review_checks", []))
	_assert(String(snapshot.get("status", "")) == "needs_delivery_review_completion", "Incomplete review reports completion need")
	_assert(String(snapshot.get("gate", "")) == "needs_delivery_review_completion", "Incomplete review gate names completion")
	_assert(missing_checks.has("known_risks_accepted"), "Incomplete review records missing risk acceptance")
	_assert(missing_checks.has("shortcut_warning_written"), "Incomplete review records missing shortcut warning")
	_assert(issue_ids.has("delivery_review_checks_missing"), "Missing delivery checks issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review", "Incomplete review loops on TASK_1028")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete review snapshot remains read-only")


func _test_issue_flags_route_to_delivery_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_visible_smoke_passed(), _review(true, _all_check_ids(), ["stale_delivery_package", "visible_polish_needed"]))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "delivery_review_regression_found", "Issue flags report delivery regression")
	_assert(String(snapshot.get("gate", "")) == "delivery_review_regression_found", "Issue gate reports delivery regression")
	_assert(issue_ids.has("delivery_review_issue_stale_delivery_package"), "Stale delivery issue is explicit")
	_assert(issue_ids.has("delivery_review_issue_visible_polish_needed"), "Visible polish issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue flags route to delivery polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue review remains read-only")


func _test_clean_review_marks_delivery_ready() -> void:
	var snapshot: Dictionary = _build_snapshot(_visible_smoke_passed(), _review(true, _all_check_ids(), []))
	var line: String = String(snapshot.get("delivery_review_line", ""))
	_assert(String(snapshot.get("status", "")) == "delivery_review_ready", "Clean review marks delivery ready")
	_assert(String(snapshot.get("gate", "")) == "delivery_review_ready", "Clean review gate ready")
	_assert(bool(snapshot.get("delivery_review_ready", false)), "Clean review sets delivery-ready flag")
	_assert(bool(snapshot.get("ready_for_handoff_packet", false)), "Clean review is ready for handoff packet")
	_assert(line.contains("DELIVERY READY"), "Delivery line names ready")
	_assert(line.contains("EXE"), "Delivery line names EXE")
	_assert(line.contains("FOB"), "Delivery line names FOB")
	_assert(line.contains("NEXT"), "Delivery line names NEXT")
	_assert(line.contains("GO"), "Delivery line names GO")
	_assert(line.contains("FEEDBACK"), "Delivery line names feedback")
	_assert(String(snapshot.get("release_build_path", "")).ends_with(".exe"), "Clean review carries release exe path")
	_assert(Dictionary(snapshot.get("delivery_notes", {})).has("start_instruction"), "Clean review carries start instruction")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Clean review recommends handoff packet")
	_assert(_snapshot_is_read_only(snapshot), "Clean review remains read-only")


func _test_controller_exports_delivery_review() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_delivery_review_snapshot"):
		_assert(false, "Controller exposes TASK_1028 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_delivery_review_snapshot(_visible_smoke_passed(), _review(true, _all_check_ids(), []))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1028 schema matches")
	_assert(String(snapshot.get("status", "")) == "delivery_review_ready", "Controller TASK_1028 ready with review")
	_assert(String(snapshot.get("delivery_review_line", "")).contains("NEXT"), "Controller TASK_1028 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1028 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_delivery_review"), "Command feedback embeds TASK_1028")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_delivery_review_line"), "Command feedback exports TASK_1028 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_delivery_review_status"), "Command feedback exports TASK_1028 status")
	controller.queue_free()


func _test_delivery_review_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_visible_smoke_passed(), _review(true, _all_check_ids(), []))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1028 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1028", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1027", "Roundtrip keeps TASK_1027 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_visible_smoke: Dictionary, review_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1028 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1028 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_visible_smoke, review_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1028 service returns dictionary")
	return _read_only_fallback()


func _visible_smoke_passed() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1027",
		"source_task_id": "TASK_1026",
		"status": "visible_ship_smoke_passed",
		"gate": "visible_ship_smoke_passed",
		"visible_ship_smoke_line": "VISIBLE SHIP EXE: FOB | NEXT | GO | FEEDBACK | sichtbar",
		"visible_ship_smoke_passed": true,
		"ready_for_delivery_review": true,
		"release_build_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.exe",
		"pck_path": "C:/dev/SternenBuergerchen/builds/Sternenbuergerchen.pck",
		"scenario_id": "release_first_decision_loop_two_player_loop",
		"tester_instructions": "Starte Singleplayer, pruefe FOB, NEXT, GO und FEEDBACK.",
		"operator_goal": "FOB/NEXT/GO/FEEDBACK als kleinen Spielmoment sichtbar spielen.",
		"known_risks": ["Manueller Sichttest bleibt noetig."],
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


func _incomplete_review() -> Dictionary:
	return _review(true, ["visible_ship_smoke_passed", "release_files_named", "start_instruction_written"], [])


func _review(done: bool, completed_checks: Array, issue_ids: Array) -> Dictionary:
	return {
		"review_available": true,
		"delivery_review_done": done,
		"completed_delivery_review_checks": completed_checks,
		"issue_flags": issue_ids,
		"start_instruction": "Starte die frische EXE, klicke Einzelspieler, pruefe FOB/NEXT/GO/FEEDBACK.",
		"shortcut_warning": "Nicht die alte Taskleisten-Verknuepfung nutzen.",
		"risk_note": "Restrisiken fuer manuellen Sichttest akzeptiert.",
		"handoff_note": "Naechster Schritt ist ein kleines Handoff-Paket.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _all_check_ids() -> Array:
	return [
		"visible_ship_smoke_passed",
		"release_files_named",
		"start_instruction_written",
		"known_risks_reviewed",
		"known_risks_accepted",
		"shortcut_warning_written",
		"multiplayer_boundary_preserved",
		"hud_truth_boundary_preserved",
		"next_handoff_task_chosen",
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
