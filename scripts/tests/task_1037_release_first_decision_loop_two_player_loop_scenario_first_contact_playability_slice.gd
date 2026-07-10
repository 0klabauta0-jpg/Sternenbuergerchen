extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1037_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.v1"
const NEXT_TASK := "TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1037 Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_trace()
	_test_failed_trace_reports_first_contact_regression()
	_test_good_trace_passes_first_contact_playability_slice()
	_test_controller_exports_first_contact_playability_slice()
	_test_first_contact_playability_slice_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1037_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice: FAILED")
		quit(1)
		return
	print("TASK_1037_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1037 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1037 first-contact playability service exists")
	_assert(task_text.contains("TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"), "Task names TASK_1037")
	_assert(task_text.contains(NEXT_TASK), "Task names first-contact real-window follow-up")
	_assert(status_text.contains("TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice"), "Implementation status tracks TASK_1037")
	_assert(roadmap_text.contains("TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice (implementiert"), "Roadmap marks TASK_1037 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice (TASK_1037)"), "Mission feedback contract documents TASK_1037")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice (TASK_1037)"), "Decision clarity contract documents TASK_1037")
	_assert(service_text.contains(SCHEMA), "First-contact playability service exposes stable TASK_1037 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1037\""), "First-contact playability service writes TASK_1037 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1036\""), "First-contact playability service links TASK_1036")
	_assert(service_text.contains("REQUIRED_FIRST_CONTACT_PLAYABILITY_CHECKS"), "First-contact playability service defines required checks")
	_assert(service_text.contains("\"first_contact_playability_slice_passed\""), "First-contact playability exposes pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "First-contact playability creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "First-contact playability creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_FIRST_CONTACT_PLAYABILITY_SLICE_SCRIPT"), "Controller preloads TASK_1037 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_snapshot"), "Controller exposes TASK_1037 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_line"), "Command feedback exports TASK_1037 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_status"), "Command feedback exports TASK_1037 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1037")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked first-contact playability snapshot remains read-only")


func _test_ready_source_without_trace_needs_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_first_contact_player_feel_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1037")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1037", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1036", "Snapshot links TASK_1036")
	_assert(String(snapshot.get("source_status", "")) == "first_contact_player_feel_polish_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_first_contact_playability_trace", "Ready source without trace needs trace")
	_assert(String(snapshot.get("gate", "")) == "needs_first_contact_playability_trace", "Gate asks for trace")
	_assert(issue_ids.has("first_contact_playability_trace_missing"), "Missing trace is explicit")
	_assert(not bool(snapshot.get("first_contact_playability_slice_passed", true)), "Missing trace does not pass slice")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice", "Missing trace keeps TASK_1037 as next work")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed first-contact snapshot remains read-only")


func _test_failed_trace_reports_first_contact_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_first_contact_player_feel_polish(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_playability_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "first_contact_playability_regression_found", "Failed trace reports first-contact regression")
	_assert(String(snapshot.get("gate", "")) == "first_contact_playability_regression", "Failed trace gate reports regression")
	_assert(missing_checks.has("fire_wait_choice_readable"), "Failed trace records missing FIRE/WAIT choice")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-next")
	_assert(missing_checks.has("go_stays_separate"), "Failed trace records missing GO boundary")
	_assert(issue_ids.has("fire_wait_choice_missing"), "Missing FIRE/WAIT issue is explicit")
	_assert(issue_ids.has("feedback_does_not_return_to_next"), "Missing feedback issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish", "Regression routes back to first-contact polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_passes_first_contact_playability_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_first_contact_player_feel_polish(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "first_contact_playability_slice_passed", "Good trace passes first-contact playability")
	_assert(String(snapshot.get("gate", "")) == "first_contact_playability_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("first_contact_playability_slice_passed", false)), "Pass flag is true")
	_assert(bool(snapshot.get("ready_for_first_contact_real_window_capture", false)), "Passed slice is ready for real-window capture")
	_assert(String(snapshot.get("first_contact_playability_line", "")).contains("CONTACT"), "Playability line names CONTACT")
	_assert(String(snapshot.get("first_contact_playability_line", "")).contains("WHY"), "Playability line names WHY")
	_assert(String(snapshot.get("first_contact_playability_line", "")).contains("NEXT"), "Playability line names NEXT")
	_assert(String(snapshot.get("first_contact_playability_line", "")).contains("GO"), "Playability line names GO")
	_assert(String(snapshot.get("first_contact_playability_line", "")).contains("FIRE/WAIT"), "Playability line names FIRE/WAIT")
	_assert(String(snapshot.get("first_contact_feedback_line", "")).contains("FEEDBACK"), "Feedback line is recorded")
	_assert(answered_questions.has("who_has_contact"), "Slice answers who has contact")
	_assert(answered_questions.has("why_this_move_matters"), "Slice answers why move matters")
	_assert(answered_questions.has("fire_or_wait_choice"), "Slice answers fire/wait choice")
	_assert(answered_questions.has("what_happens_only_after_go"), "Slice answers GO boundary")
	_assert(answered_questions.has("what_is_next_after_feedback"), "Slice answers next grip after feedback")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed slice recommends real-window capture")
	_assert(_snapshot_is_read_only(snapshot), "Passed snapshot remains read-only")


func _test_controller_exports_first_contact_playability_slice() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_snapshot"):
		_assert(false, "Controller exposes TASK_1037 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_snapshot(_source_first_contact_player_feel_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1037 schema matches")
	_assert(String(snapshot.get("status", "")) == "first_contact_playability_slice_passed", "Controller TASK_1037 passes with trace")
	_assert(String(snapshot.get("first_contact_playability_line", "")).contains("FIRE/WAIT"), "Controller TASK_1037 line names fire/wait")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1037 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice"), "Command feedback embeds TASK_1037")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_line"), "Command feedback exports TASK_1037 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_status"), "Command feedback exports TASK_1037 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice_gate"), "Command feedback exports TASK_1037 gate")
	controller.queue_free()


func _test_first_contact_playability_slice_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_first_contact_player_feel_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1037 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1037", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1036", "Roundtrip keeps TASK_1036 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_player_feel_polish: Dictionary, trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1037 service is loadable")
		return _read_only_fallback()
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1037 service script loads")
		return _read_only_fallback()
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_player_feel_polish, trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1037 service returns dictionary")
	return _read_only_fallback()


func _source_first_contact_player_feel_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1036",
		"source_task_id": "TASK_1035",
		"status": "first_contact_player_feel_polish_ready",
		"active": true,
		"first_contact_player_feel_surface_specs": [
			_surface_spec("contact_surface", "contact_line", "CONTACT", "CONTACT rund: Kontakt, Distanz und Gefahr sofort lesbar."),
			_surface_spec("why_surface", "why_actionable", "WHY", "WHY klar: die Lage erklaert, warum der naechste Griff sinnvoll ist."),
			_surface_spec("next_surface", "next_grip", "NEXT", "NEXT bereit: nach Kontakt bleibt der naechste taktische Griff sichtbar."),
			_surface_spec("feedback_surface", "feedback_next", "FEEDBACK", "Feedback bestaetigt Wirkung und fuehrt ruhig zur naechsten Entscheidung."),
			_surface_spec("go_boundary_surface", "go_boundary", "GO", "GO separat: Preview bleibt Preview, Ausfuehrung erst mit GO."),
			_surface_spec("hud_multiplayer_surface", "hud_multiplayer_boundary", "HUD/MP", "HUD/MP klar: Preview und Feedback setzen keine Gameplay-Wahrheit."),
		],
		"first_contact_player_feel_surface_spec_count": 6,
		"first_contact_player_feel_polish_line": "CONTACT rund | WHY klar | NEXT bereit | GO separat",
		"first_contact_next_grip_line": "NEXT: Naechste First-Contact-Entscheidung bleibt direkt sichtbar.",
		"first_contact_go_boundary_microcopy": "GO separat: Preview bleibt Preview, Ausfuehrung erst mit GO.",
		"first_contact_calm_hud_guidance": "HUD ruhig: wenige starke Tokens, keine wandernde Wahrheit.",
		"first_contact_performance_feedback_hint": "Responsiveness bleibt schnell: Snapshot lesen, gezielt refreshen.",
		"ready_for_first_contact_playability_review": true,
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


func _surface_spec(surface_id: String, role: String, label: String, text: String) -> Dictionary:
	return {
		"surface_id": surface_id,
		"role": role,
		"label": label,
		"text": text,
		"display_text": "%s: %s" % [label, text],
		"style_id": "first_contact_%s" % role,
		"accent": "gold" if role == "why_actionable" or role == "next_grip" else "mint",
		"min_height": 30.0,
		"max_lines": 2,
		"line_budget": 82,
		"autowrap": true,
		"clip_text": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _good_trace() -> Dictionary:
	return {
		"trace_available": true,
		"trace_id": "first_contact_playability_fixture",
		"contact_line_readable": true,
		"why_actionable": true,
		"next_grip_readable": true,
		"fire_wait_choice_readable": true,
		"go_stays_separate": true,
		"feedback_returns_to_next": true,
		"hud_stays_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_preserved": true,
		"no_gameplay_truth_mutation": true,
		"first_contact_feels_tactical": true,
		"first_contact_feedback_line": "FEEDBACK: Kontakt gelesen, NEXT wieder bereit.",
		"player_next_grip_line": "Naechster Griff: FIRE/WAIT waehlen, WHY lesen, GO separat.",
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["fire_wait_choice_readable"] = false
	trace["feedback_returns_to_next"] = false
	trace["go_stays_separate"] = false
	trace["first_contact_feedback_line"] = ""
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
