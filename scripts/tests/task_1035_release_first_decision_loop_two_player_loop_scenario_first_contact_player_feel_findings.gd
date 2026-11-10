extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1035_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.v1"
const REVIEW_TASK := "TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings"
const POLISH_TASK := "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish"
const PLAYABILITY_TASK := "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1035 Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_smoke_without_notes_needs_review()
	_test_issue_notes_route_to_first_contact_player_feel_polish()
	_test_clean_notes_accept_first_contact_feel()
	_test_controller_exports_first_contact_player_feel_findings()
	_test_first_contact_player_feel_findings_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1035_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings: FAILED")
		quit(1)
		return
	print("TASK_1035_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1035 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1035 first-contact player-feel findings service exists")
	_assert(task_text.contains(REVIEW_TASK), "Task names TASK_1035")
	_assert(task_text.contains(POLISH_TASK), "Task names first-contact player-feel polish follow-up")
	_assert(task_text.contains(PLAYABILITY_TASK), "Task names first-contact playability follow-up")
	_assert(status_text.contains(REVIEW_TASK), "Implementation status tracks TASK_1035")
	_assert(roadmap_text.contains("TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings (implementiert"), "Roadmap marks TASK_1035 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings (TASK_1035)"), "Mission feedback contract documents TASK_1035")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings (TASK_1035)"), "Decision clarity contract documents TASK_1035")
	_assert(service_text.contains(SCHEMA), "First-contact player-feel findings service exposes stable TASK_1035 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1035\""), "First-contact player-feel findings service writes TASK_1035 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1034\""), "First-contact player-feel findings service links TASK_1034")
	_assert(service_text.contains("PLAYER_FEEL_CHECK_KEYS"), "First-contact player-feel findings service defines review keys")
	_assert(service_text.contains("\"contact_line_feels_clear\""), "First-contact player-feel checks contact readability")
	_assert(service_text.contains("\"why_feels_actionable\""), "First-contact player-feel checks why/actionability")
	_assert(service_text.contains("\"ready_for_first_contact_playability_slice\""), "First-contact player-feel exposes playability readiness")
	_assert(service_text.contains("\"creates_command\": false"), "First-contact player-feel findings creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "First-contact player-feel findings creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_PLAYER_FEEL_FINDINGS_SCRIPT"), "Controller preloads TASK_1035 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_snapshot"), "Controller exposes TASK_1035 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_status"), "Command feedback exports TASK_1035 status")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_issue_count"), "Command feedback exports TASK_1035 issue count")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1035")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked first-contact player-feel snapshot remains read-only")


func _test_passed_smoke_without_notes_needs_review() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_smoke(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1035")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1035", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1034", "Snapshot links TASK_1034")
	_assert(String(snapshot.get("source_status", "")) == "first_contact_runtime_smoke_passed", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_player_feel_review", "Passed smoke without notes needs review")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_player_feel_review", "Gate asks for first-contact player-feel review")
	_assert(issue_ids.has("first_contact_player_feel_review_missing"), "Missing first-contact player-feel review is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == REVIEW_TASK, "Open review loops on TASK_1035")
	_assert(_snapshot_is_read_only(snapshot), "Review-needed first-contact snapshot remains read-only")


func _test_issue_notes_route_to_first_contact_player_feel_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_smoke(), _issue_notes())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var positive_findings: Array = Array(snapshot.get("positive_findings", []))
	_assert(String(snapshot.get("status", "")) == "first_contact_player_feel_rework_needed", "Issue notes require first-contact player-feel rework")
	_assert(String(snapshot.get("gate", "")) == "first_contact_player_feel_rework_needed", "Issue notes gate routes to rework")
	_assert(issue_ids.has("contact_line_feels_unclear"), "Contact-line issue is named")
	_assert(issue_ids.has("why_not_actionable"), "WHY/actionability issue is named")
	_assert(issue_ids.has("go_boundary_not_felt"), "GO-boundary issue is named")
	_assert(issue_ids.has("first_contact_feedback_feels_dry"), "First-contact feedback issue is named")
	_assert(positive_findings.has("first_contact_runtime_smoke_passed"), "Issue notes keep positive source finding")
	_assert(not bool(snapshot.get("ready_for_first_contact_playability_slice", true)), "Issue notes are not accepted")
	_assert(String(snapshot.get("recommended_next_task", "")) == POLISH_TASK, "Issue notes recommend first-contact player-feel polish")
	_assert(_snapshot_is_read_only(snapshot), "Issue first-contact snapshot remains read-only")


func _test_clean_notes_accept_first_contact_feel() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_smoke(), _clean_notes())
	var positive_findings: Array = Array(snapshot.get("positive_findings", []))
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_contact_playability_slice", "Clean notes accept first-contact player feel")
	_assert(String(snapshot.get("gate", "")) == "first_contact_player_feel_accepted", "Clean notes gate accepts")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Clean notes have no issues")
	_assert(bool(snapshot.get("ready_for_first_contact_playability_slice", false)), "Clean notes set first-contact playability readiness")
	_assert(positive_findings.has("contact_line_feels_clear"), "Clean notes keep contact-line finding")
	_assert(positive_findings.has("why_feels_actionable"), "Clean notes keep why/actionability finding")
	_assert(positive_findings.has("next_grip_feels_clear"), "Clean notes keep next-grip finding")
	_assert(positive_findings.has("first_contact_feels_tactical"), "Clean notes keep tactical-feel finding")
	_assert(String(snapshot.get("first_contact_player_feel_summary_line", "")).contains("CONTACT"), "Summary names CONTACT")
	_assert(String(snapshot.get("first_contact_player_feel_summary_line", "")).contains("WHY"), "Summary names WHY")
	_assert(String(snapshot.get("first_contact_player_feel_summary_line", "")).contains("GO"), "Summary names GO")
	_assert(String(snapshot.get("recommended_next_task", "")) == PLAYABILITY_TASK, "Clean notes recommend first-contact playability slice")
	_assert(_snapshot_is_read_only(snapshot), "Accepted first-contact snapshot remains read-only")


func _test_controller_exports_first_contact_player_feel_findings() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_snapshot"):
		_assert(false, "Controller exposes TASK_1035 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_snapshot(_source_runtime_smoke(), _clean_notes())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1035 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted_for_first_contact_playability_slice", "Controller TASK_1035 accepts with clean notes")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1035 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings"), "Command feedback embeds TASK_1035")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_status"), "Command feedback exports TASK_1035 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings_issue_count"), "Command feedback exports TASK_1035 issue count")
	controller.queue_free()


func _test_first_contact_player_feel_findings_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_smoke(), _clean_notes())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1035 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1035", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1034", "Roundtrip keeps TASK_1034 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == PLAYABILITY_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_runtime_smoke: Dictionary, player_feel_notes: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1035 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1035 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_runtime_smoke, player_feel_notes)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1035 service returns dictionary")
	return _read_only_fallback()


func _source_runtime_smoke() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1034",
		"source_task_id": "TASK_1033",
		"status": "first_contact_runtime_smoke_passed",
		"gate": "first_contact_runtime_smoke_passed",
		"first_contact_runtime_smoke_passed": true,
		"ready_for_first_contact_player_feel_findings": true,
		"first_contact_runtime_smoke_line": "CONTACT SMOKE PASS: CONTACT | WHY | NEXT | GO separat | FEEDBACK sichtbar",
		"post_smoke_feedback_line": "FEEDBACK: Kontakt gelesen, WHY sichtbar, NEXT bleibt bereit.",
		"trace_available": true,
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
		"contact_line_feels_clear": true,
		"why_feels_actionable": true,
		"next_grip_feels_clear": true,
		"go_boundary_feels_safe": true,
		"feedback_invites_next_grip": true,
		"hud_feels_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_feels_clear": true,
		"first_contact_feels_tactical": true,
		"summary": "CONTACT, WHY, NEXT, GO und Feedback fuehlen sich als erster taktischer Kontaktgriff rund an.",
	}


func _issue_notes() -> Dictionary:
	var notes: Dictionary = _clean_notes()
	notes["contact_line_feels_clear"] = false
	notes["why_feels_actionable"] = false
	notes["go_boundary_feels_safe"] = false
	notes["feedback_invites_next_grip"] = false
	notes["summary"] = "CONTACT ist sichtbar, aber WHY und GO-Grenze fuehlen sich noch nicht handlungsfaehig an."
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
