extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1041_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_visual_polish.v1"
const NEXT_TASK := "TASK_1042 - Release First Decision Loop Two Player Loop Scenario First Contact Integrated Playtest"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1041 Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_polish_without_trace_needs_acceptance_trace()
	_test_failed_trace_reports_first_contact_regression()
	_test_good_trace_accepts_first_contact_slice()
	_test_controller_exports_first_contact_acceptance_slice()
	_test_first_contact_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1041_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_1041_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1041 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1041 first-contact acceptance service exists")
	_assert(task_text.contains("TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"), "Task names TASK_1041")
	_assert(task_text.contains(NEXT_TASK), "Task names integrated playtest follow-up")
	_assert(status_text.contains("TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice"), "Implementation status tracks TASK_1041")
	_assert(roadmap_text.contains("TASK_1041 - Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice (implementiert"), "Roadmap marks TASK_1041 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice (TASK_1041)"), "Mission feedback contract documents TASK_1041")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Acceptance Slice (TASK_1041)"), "Decision clarity contract documents TASK_1041")
	_assert(service_text.contains(SCHEMA), "First-contact acceptance service exposes stable TASK_1041 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1041\""), "First-contact acceptance service writes TASK_1041 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1040\""), "First-contact acceptance service links TASK_1040")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "First-contact acceptance service defines required checks")
	_assert(service_text.contains("\"first_contact_acceptance_slice_passed\""), "First-contact acceptance exposes pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "First-contact acceptance creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "First-contact acceptance creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "First-contact acceptance creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_ACCEPTANCE_SLICE_SCRIPT"), "Controller preloads TASK_1041 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_snapshot"), "Controller exposes TASK_1041 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_line"), "Command feedback exports TASK_1041 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_status"), "Command feedback exports TASK_1041 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1041")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready_for_first_contact_acceptance"), "Missing source reports not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked first-contact acceptance snapshot remains read-only")


func _test_polish_without_trace_needs_acceptance_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_visual_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1041")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1041", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1040", "Snapshot links TASK_1040")
	_assert(String(snapshot.get("source_status", "")) == "first_contact_visual_polish_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_acceptance_trace", "Ready polish without trace needs acceptance trace")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_acceptance_trace", "Gate asks for first-contact acceptance trace")
	_assert(issue_ids.has("first_contact_acceptance_trace_missing"), "Missing acceptance trace is explicit")
	_assert(not bool(snapshot.get("first_contact_acceptance_slice_passed", true)), "Missing trace does not pass acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_first_contact_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_visual_polish(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_acceptance_checks", []))
	_assert(String(snapshot.get("status", "")) == "first_contact_acceptance_regression_found", "Failed trace reports first-contact regression")
	_assert(String(snapshot.get("gate", "")) == "first_contact_acceptance_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-NEXT")
	_assert(missing_checks.has("multiplayer_boundary_preserved"), "Failed trace records missing multiplayer boundary")
	_assert(issue_ids.has("feedback_does_not_return_to_next"), "Missing feedback-to-NEXT issue is explicit")
	_assert(issue_ids.has("multiplayer_boundary_risk"), "Missing multiplayer boundary issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1040 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Polish", "Regression routes to TASK_1040 polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_accepts_first_contact_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_visual_polish(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "first_contact_acceptance_slice_passed", "Good trace passes first-contact acceptance")
	_assert(String(snapshot.get("gate", "")) == "first_contact_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("first_contact_acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("first_contact_acceptance_line", "")).contains("CONTACT"), "Acceptance line names CONTACT")
	_assert(String(snapshot.get("first_contact_acceptance_line", "")).contains("WHY"), "Acceptance line names WHY")
	_assert(String(snapshot.get("first_contact_acceptance_line", "")).contains("FIRE/WAIT"), "Acceptance line names FIRE/WAIT")
	_assert(String(snapshot.get("first_contact_acceptance_line", "")).contains("GO"), "Acceptance line names GO")
	_assert(answered_questions.has("who_has_contact"), "Acceptance answers contact")
	_assert(answered_questions.has("why_is_it_risky"), "Acceptance answers why")
	_assert(answered_questions.has("what_is_fire_wait_choice"), "Acceptance answers fire/wait")
	_assert(answered_questions.has("what_happens_only_after_go"), "Acceptance answers GO boundary")
	_assert(answered_questions.has("what_is_next_after_feedback"), "Acceptance answers next grip after feedback")
	_assert(answered_questions.has("who_owns_truth"), "Acceptance answers ownership")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 7, "Acceptance covers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed acceptance recommends integrated playtest")
	_assert(_snapshot_is_read_only(snapshot), "Passed acceptance remains read-only")


func _test_controller_exports_first_contact_acceptance_slice() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_snapshot"):
		_assert(false, "Controller exposes TASK_1041 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_snapshot(_ready_visual_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1041 schema matches")
	_assert(String(snapshot.get("status", "")) == "first_contact_acceptance_slice_passed", "Controller TASK_1041 passes with trace")
	_assert(String(snapshot.get("first_contact_acceptance_line", "")).contains("NEXT"), "Controller TASK_1041 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1041 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice"), "Command feedback embeds TASK_1041")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_line"), "Command feedback exports TASK_1041 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_acceptance_slice_status"), "Command feedback exports TASK_1041 status")
	controller.queue_free()


func _test_first_contact_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_visual_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1041 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1041", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1040", "Roundtrip keeps TASK_1040 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_polish: Dictionary, acceptance_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1041 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1041 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_polish, acceptance_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1041 service returns dictionary")
	return _read_only_fallback()


func _ready_visual_polish() -> Dictionary:
	var specs: Array = [
		_surface("contact_surface", "contact_line", "CONTACT", "CONTACT sichtbar: Kontakt, Risiko und Quelle in einer klaren Zeile."),
		_surface("why_surface", "why_actionable", "WHY", "WHY klar: Lage erklaert, warum FIRE/WAIT oder Move sinnvoll ist."),
		_surface("next_surface", "next_grip", "NEXT", "NEXT bereit: nach CONTACT bleibt die naechste Entscheidung sichtbar."),
		_surface("fire_wait_surface", "fire_wait_choice", "FIRE/WAIT", "FIRE/WAIT lesbar: Spieler sieht Feuerwahl vor GO."),
		_surface("feedback_surface", "feedback_line", "FEEDBACK", "Feedback bestaetigt Wirkung und fuehrt ruhig zur naechsten Entscheidung."),
		_surface("go_boundary_surface", "go_boundary", "GO", "GO separat: Ausfuehrung erst nach bewusstem Commit."),
		_surface("hud_multiplayer_surface", "hud_multiplayer_boundary", "HUD/MP", "HUD/MP ruhig: Anzeige bleibt read-only, Multiplayer-Wahrheit bleibt getrennt."),
	]
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1040",
		"source_task_id": "TASK_1039",
		"status": "first_contact_visual_polish_ready",
		"first_contact_visual_polish_line": "CONTACT rund | WHY klar | NEXT bereit | FIRE/WAIT sichtbar | GO separat",
		"first_contact_next_line": "NEXT: Erste Kontaktentscheidung bleibt direkt anschlussfaehig.",
		"first_contact_fire_wait_microcopy": "FIRE/WAIT lesbar: Spieler sieht Feuerwahl vor GO.",
		"first_contact_go_boundary_microcopy": "GO separat: Ausfuehrung erst nach bewusstem Commit.",
		"first_contact_visual_surface_specs": specs,
		"first_contact_visual_surface_spec_count": specs.size(),
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


func _surface(surface_id: String, role: String, label: String, text: String) -> Dictionary:
	return {
		"surface_id": surface_id,
		"role": role,
		"label": label,
		"text": text,
		"style_id": "test_%s" % surface_id,
		"min_height": 34.0,
		"max_lines": 2,
		"line_budget": 86,
		"autowrap": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"contact_readable",
		"why_actionable",
		"next_visible",
		"fire_wait_choice_clear",
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
		"contact_readable": true,
		"why_actionable": true,
		"next_visible": true,
		"fire_wait_choice_clear": true,
		"feedback_returns_to_next": true,
		"go_boundary_clear": true,
		"hud_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_preserved": true,
		"no_new_hud_gameplay_truth": true,
		"answered_player_questions": [
			"who_has_contact",
			"why_is_it_risky",
			"what_is_next",
			"what_is_fire_wait_choice",
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
	trace["completed_checks"] = ["contact_readable", "why_actionable", "go_boundary_clear"]
	trace["feedback_returns_to_next"] = false
	trace["multiplayer_boundary_preserved"] = false
	trace["answered_player_questions"] = ["who_has_contact", "what_happens_only_after_go"]
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
