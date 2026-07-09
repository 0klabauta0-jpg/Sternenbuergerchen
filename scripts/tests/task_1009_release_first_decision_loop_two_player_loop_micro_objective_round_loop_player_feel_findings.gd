extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1009_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_integrated_playtest.v1"
const POLISH_TASK := "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish"
const ACCEPTANCE_TASK := "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1009 Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_notes_needs_review()
	_test_issue_notes_route_to_player_feel_polish()
	_test_clean_notes_accept_round_loop_feel()
	_test_controller_exports_round_loop_player_feel_findings()
	_test_round_loop_player_feel_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1009_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings: FAILED")
		quit(1)
		return
	print("TASK_1009_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1009 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1009 player-feel findings service exists")
	_assert(task_text.contains("TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings"), "Task names TASK_1009")
	_assert(task_text.contains(POLISH_TASK), "Task names player-feel polish follow-up")
	_assert(task_text.contains(ACCEPTANCE_TASK), "Task names acceptance follow-up")
	_assert(status_text.contains("TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings"), "Implementation status tracks TASK_1009")
	_assert(roadmap_text.contains("TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings (implementiert"), "Roadmap marks TASK_1009 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings (TASK_1009)"), "Mission feedback contract documents TASK_1009")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings (TASK_1009)"), "Decision clarity contract documents TASK_1009")
	_assert(service_text.contains(SCHEMA), "Round-loop player-feel findings service exposes stable TASK_1009 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1009\""), "Round-loop player-feel findings service writes TASK_1009 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1008\""), "Round-loop player-feel findings service links TASK_1008")
	_assert(service_text.contains("PLAYER_FEEL_CHECK_KEYS"), "Round-loop player-feel findings service defines review keys")
	_assert(service_text.contains("\"positive_findings\""), "Round-loop player-feel findings service exposes positive findings")
	_assert(service_text.contains("\"ready_for_round_loop_acceptance_slice\""), "Round-loop player-feel findings service exposes acceptance readiness")
	_assert(service_text.contains("\"creates_command\": false"), "Round-loop player-feel findings creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-loop player-feel findings creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_PLAYER_FEEL_FINDINGS_SCRIPT"), "Controller preloads TASK_1009 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_snapshot"), "Controller exposes TASK_1009 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_status"), "Command feedback exports TASK_1009 status")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_issue_count"), "Command feedback exports TASK_1009 issue count")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1009")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked player-feel findings snapshot remains read-only")


func _test_ready_source_without_notes_needs_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1009")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1009", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1008", "Snapshot links TASK_1008")
	_assert(String(snapshot.get("source_status", "")) == "round_loop_integrated_playtest_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_player_feel_review", "Ready source without notes needs review")
	_assert(String(snapshot.get("gate", "")) == "needs_player_feel_review", "Gate asks for player-feel review")
	_assert(issue_ids.has("player_feel_review_missing"), "Missing player-feel review is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1009 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Findings", "Open review loops on TASK_1009")
	_assert(_snapshot_is_read_only(snapshot), "Review-needed snapshot remains read-only")


func _test_issue_notes_route_to_player_feel_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), _issue_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_findings: Array = Array(snapshot.get("positive_findings", []))
	_assert(String(snapshot.get("status", "")) == "round_loop_player_feel_rework_needed", "Issue notes require player-feel rework")
	_assert(String(snapshot.get("gate", "")) == "round_loop_player_feel_rework_needed", "Issue notes gate routes to rework")
	_assert(issue_ids.has("entry_feels_unclear"), "Entry issue is named")
	_assert(issue_ids.has("go_boundary_not_felt"), "GO-boundary issue is named")
	_assert(issue_ids.has("feedback_feels_dry"), "Feedback issue is named")
	_assert(issue_ids.has("performance_feels_sluggish"), "Performance feel issue is named")
	_assert(positive_findings.has("round_loop_integrated_path_present"), "Issue notes keep positive source finding")
	_assert(not bool(snapshot.get("ready_for_round_loop_acceptance_slice", true)), "Issue notes are not accepted")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue notes recommend player-feel polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue snapshot remains read-only")


func _test_clean_notes_accept_round_loop_feel() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), _clean_notes())
	var positive_findings: Array = Array(snapshot.get("positive_findings", []))
	_assert(String(snapshot.get("status", "")) == "accepted_for_round_loop_acceptance_slice", "Clean notes accept player feel")
	_assert(String(snapshot.get("gate", "")) == "round_loop_player_feel_accepted", "Clean notes gate accepts")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(bool(snapshot.get("ready_for_round_loop_acceptance_slice", false)), "Clean notes set acceptance readiness")
	_assert(positive_findings.has("entry_feels_clear"), "Clean notes keep entry finding")
	_assert(positive_findings.has("round_next_go_rhythm_feels_clear"), "Clean notes keep rhythm finding")
	_assert(positive_findings.has("feedback_invites_next_grip"), "Clean notes keep feedback finding")
	_assert(positive_findings.has("hud_feels_calm"), "Clean notes keep HUD finding")
	_assert(String(snapshot.get("player_feel_summary_line", "")).contains("ROUND"), "Summary names ROUND")
	_assert(String(snapshot.get("player_feel_summary_line", "")).contains("NEXT"), "Summary names NEXT")
	_assert(String(snapshot.get("recommended_next_task", "")) == ACCEPTANCE_TASK, "Clean notes recommend acceptance slice")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_controller_exports_round_loop_player_feel_findings() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_snapshot"):
		_assert(false, "Controller exposes TASK_1009 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_snapshot(_source_integrated_playtest(), _clean_notes())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1009 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted_for_round_loop_acceptance_slice", "Controller TASK_1009 accepts with clean notes")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1009 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings"), "Command feedback embeds TASK_1009")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_status"), "Command feedback exports TASK_1009 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings_issue_count"), "Command feedback exports TASK_1009 issue count")
	controller.queue_free()


func _test_round_loop_player_feel_findings_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_integrated_playtest(), _clean_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1009 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1009", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1008", "Roundtrip keeps TASK_1008 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == ACCEPTANCE_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_integrated_playtest: Dictionary, player_feel_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1009 service is loadable")
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
		_assert(false, "TASK_1009 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_integrated_playtest, player_feel_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1009 service returns dictionary")
	return {}


func _source_integrated_playtest() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1008",
		"source_task_id": "TASK_1007",
		"status": "round_loop_integrated_playtest_passed",
		"gate": "round_loop_integrated_playtest_passed",
		"round_loop_integrated_playtest_passed": true,
		"ready_for_player_feel_findings": true,
		"integrated_playtest_line": "ENTRY Mission | ROUND LOOP PASS: ROUND gelesen | NEXT bereit | GO separat | FEEDBACK NEXT bereit",
		"observed_frame_budget_ms": 16.0,
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


func _clean_notes() -> Dictionary:
	return {
		"review_available": true,
		"entry_feels_clear": true,
		"round_next_go_rhythm_feels_clear": true,
		"feedback_invites_next_grip": true,
		"go_boundary_feels_clear": true,
		"hud_feels_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_feels_clear": true,
		"summary": "ROUND/NEXT/GO/FEEDBACK fuehlt sich rund und ruhig an.",
	}


func _issue_notes() -> Dictionary:
	var notes: Dictionary = _clean_notes()
	notes["entry_feels_clear"] = false
	notes["go_boundary_feels_clear"] = false
	notes["feedback_invites_next_grip"] = false
	notes["performance_feels_responsive"] = false
	notes["summary"] = "Start und Feedback fuehlen sich noch trocken an; GO wirkt nicht getrennt genug."
	return notes


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
