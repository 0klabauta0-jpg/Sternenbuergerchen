extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1022_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_integrated_playtest.v1"
const POLISH_TASK := "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Player Feel Polish"
const ACCEPTANCE_TASK := "TASK_1023 - Release First Decision Loop Two Player Loop Scenario Small Game Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1022 Release First Decision Loop Two Player Loop Scenario Integrated Player Feel Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_integrated_playtest_without_notes_needs_review()
	_test_issue_notes_route_to_player_feel_polish()
	_test_clean_notes_accept_small_game_feel()
	_test_controller_exports_integrated_player_feel_findings()
	_test_integrated_player_feel_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1022_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings: FAILED")
		quit(1)
		return
	print("TASK_1022_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1022 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1022 integrated player-feel findings service exists")
	_assert(task_text.contains("TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"), "Task names TASK_1022")
	_assert(task_text.contains(POLISH_TASK), "Task names player-feel polish follow-up")
	_assert(task_text.contains(ACCEPTANCE_TASK), "Task names small-game acceptance follow-up")
	_assert(status_text.contains("TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"), "Implementation status tracks TASK_1022")
	_assert(roadmap_text.contains("TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings (implementiert"), "Roadmap marks TASK_1022 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Player Feel Findings (TASK_1022)"), "Mission feedback contract documents TASK_1022")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Player Feel Findings (TASK_1022)"), "Decision clarity contract documents TASK_1022")
	_assert(service_text.contains(SCHEMA), "Integrated player-feel findings service exposes stable TASK_1022 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1022\""), "Integrated player-feel findings service writes TASK_1022 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1021\""), "Integrated player-feel findings service links TASK_1021")
	_assert(service_text.contains("PLAYER_FEEL_CHECK_KEYS"), "Integrated player-feel findings service defines review keys")
	_assert(service_text.contains("\"positive_findings\""), "Integrated player-feel findings exposes positive findings")
	_assert(service_text.contains("\"ready_for_small_game_acceptance_slice\""), "Integrated player-feel findings exposes small-game readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Integrated player-feel findings creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Integrated player-feel findings creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Integrated player-feel findings creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_INTEGRATED_PLAYER_FEEL_FINDINGS_SCRIPT"), "Controller preloads TASK_1022 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_snapshot"), "Controller exposes TASK_1022 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_status"), "Command feedback exports TASK_1022 status")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_issue_count"), "Command feedback exports TASK_1022 issue count")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1022")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked integrated player-feel snapshot remains read-only")


func _test_passed_integrated_playtest_without_notes_needs_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1022")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1022", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1021", "Snapshot links TASK_1021")
	_assert(String(snapshot.get("source_status", "")) == "scenario_integrated_playtest_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_scenario_integrated_player_feel_review", "Passed integrated playtest without notes needs review")
	_assert(String(snapshot.get("gate", "")) == "needs_scenario_integrated_player_feel_review", "Gate asks for integrated player-feel review")
	_assert(issue_ids.has("scenario_integrated_player_feel_review_missing"), "Missing integrated player-feel review is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1022 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings", "Open review loops on TASK_1022")
	_assert(_snapshot_is_read_only(snapshot), "Review-needed integrated player-feel snapshot remains read-only")


func _test_issue_notes_route_to_player_feel_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), _issue_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_findings: Array = Array(snapshot.get("positive_findings", []))
	_assert(String(snapshot.get("status", "")) == "scenario_integrated_player_feel_rework_needed", "Issue notes require player-feel rework")
	_assert(String(snapshot.get("gate", "")) == "scenario_integrated_player_feel_rework_needed", "Issue notes gate routes to rework")
	_assert(issue_ids.has("integrated_entry_feels_unclear"), "Integrated entry issue is named")
	_assert(issue_ids.has("fob_grip_not_round"), "FOB grip issue is named")
	_assert(issue_ids.has("post_go_feedback_feels_dry"), "Post-GO feedback issue is named")
	_assert(issue_ids.has("small_game_not_round_yet"), "Small-game roundness issue is named")
	_assert(positive_findings.has("scenario_integrated_playtest_passed"), "Issue notes keep positive source finding")
	_assert(not bool(snapshot.get("ready_for_small_game_acceptance_slice", true)), "Issue notes are not accepted")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue notes recommend player-feel polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_notes_accept_small_game_feel() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), _clean_notes())
	var positive_findings: Array = Array(snapshot.get("positive_findings", []))
	_assert(String(snapshot.get("status", "")) == "accepted_for_small_game_acceptance_slice", "Clean notes accept small-game feel")
	_assert(String(snapshot.get("gate", "")) == "scenario_integrated_player_feel_accepted", "Clean notes gate accepts")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(bool(snapshot.get("ready_for_small_game_acceptance_slice", false)), "Clean notes set small-game acceptance readiness")
	_assert(positive_findings.has("integrated_entry_feels_clear"), "Clean notes keep integrated entry finding")
	_assert(positive_findings.has("fob_grip_feels_round"), "Clean notes keep FOB grip finding")
	_assert(positive_findings.has("post_go_feedback_invites_next_grip"), "Clean notes keep post-GO feedback finding")
	_assert(positive_findings.has("small_game_feels_round"), "Clean notes keep small-game roundness finding")
	_assert(String(snapshot.get("scenario_integrated_player_feel_summary_line", "")).contains("FOB"), "Summary names FOB")
	_assert(String(snapshot.get("scenario_integrated_player_feel_summary_line", "")).contains("NEXT"), "Summary names NEXT")
	_assert(String(snapshot.get("scenario_integrated_player_feel_summary_line", "")).contains("GO"), "Summary names GO")
	_assert(String(snapshot.get("recommended_next_task", "")) == ACCEPTANCE_TASK, "Clean notes recommend small-game acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_controller_exports_integrated_player_feel_findings() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_snapshot"):
		_assert(false, "Controller exposes TASK_1022 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_snapshot(_source_integrated_playtest(), _clean_notes())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1022 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted_for_small_game_acceptance_slice", "Controller TASK_1022 accepts with clean notes")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1022 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings"), "Command feedback embeds TASK_1022")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_status"), "Command feedback exports TASK_1022 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_issue_count"), "Command feedback exports TASK_1022 issue count")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_integrated_player_feel_findings_summary_line"), "Command feedback exports TASK_1022 summary")
	controller.queue_free()


func _test_integrated_player_feel_findings_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), _clean_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1022 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1022", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1021", "Roundtrip keeps TASK_1021 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == ACCEPTANCE_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_integrated_playtest: Dictionary, player_feel_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1022 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1022 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_integrated_playtest, player_feel_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1022 service returns dictionary")
	return _read_only_fallback()


func _source_integrated_playtest() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1021",
		"source_task_id": "TASK_1020",
		"status": "scenario_integrated_playtest_passed",
		"gate": "scenario_integrated_playtest_passed",
		"scenario_integrated_playtest_passed": true,
		"ready_for_player_feel_findings": true,
		"integrated_playtest_line": "ENTRY Release Mission | SCENARIO PASS: FOB rund | NEXT bereit | GO separat | FEEDBACK gelesen",
		"entry_line": "ENTRY Release Mission erreicht, FOB-Griff sichtbar.",
		"post_go_line": "FEEDBACK nach GO sichtbar, NEXT wieder bereit.",
		"observed_frame_budget_ms": 16.0,
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


func _clean_notes() -> Dictionary:
	return {
		"review_available": true,
		"integrated_entry_feels_clear": true,
		"fob_grip_feels_round": true,
		"next_confirm_go_feels_clear": true,
		"post_go_feedback_invites_next_grip": true,
		"loop_returns_without_confusion": true,
		"hud_feels_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_feels_clear": true,
		"two_player_context_feels_clear": true,
		"small_game_feels_round": true,
		"summary": "FOB, NEXT, GO und FEEDBACK fuehlen sich im integrierten Griff wie ein kleines rundes Spiel an.",
	}


func _issue_notes() -> Dictionary:
	var notes: Dictionary = _clean_notes()
	notes["integrated_entry_feels_clear"] = false
	notes["fob_grip_feels_round"] = false
	notes["post_go_feedback_invites_next_grip"] = false
	notes["small_game_feels_round"] = false
	notes["summary"] = "FOB-Start und Feedback fuehlen sich noch trocken an; der Griff ist noch nicht rund."
	return notes


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
