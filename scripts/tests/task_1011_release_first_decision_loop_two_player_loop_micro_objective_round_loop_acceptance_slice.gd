extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1011_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.v1"
const NEXT_TASK := "TASK_1012 - Release First Decision Loop Two Player Loop Scenario Stitch"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1011 Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_needs_acceptance_trace()
	_test_failed_trace_reports_round_loop_acceptance_regression()
	_test_good_trace_accepts_round_loop_slice()
	_test_controller_exports_round_loop_acceptance_slice()
	_test_round_loop_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1011_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_1011_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1011 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1011 round-loop acceptance service exists")
	_assert(task_text.contains("TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"), "Task names TASK_1011")
	_assert(task_text.contains(NEXT_TASK), "Task names scenario stitch follow-up")
	_assert(status_text.contains("TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice"), "Implementation status tracks TASK_1011")
	_assert(roadmap_text.contains("TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice (implementiert"), "Roadmap marks TASK_1011 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice (TASK_1011)"), "Mission feedback contract documents TASK_1011")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice (TASK_1011)"), "Decision clarity contract documents TASK_1011")
	_assert(service_text.contains(SCHEMA), "Round-loop acceptance service exposes stable TASK_1011 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1011\""), "Round-loop acceptance service writes TASK_1011 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1010\""), "Round-loop acceptance service links TASK_1010")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Round-loop acceptance service defines required checks")
	_assert(service_text.contains("\"round_loop_acceptance_slice_passed\""), "Round-loop acceptance exposes pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "Round-loop acceptance creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Round-loop acceptance creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_ACCEPTANCE_SLICE_SCRIPT"), "Controller preloads TASK_1011 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_snapshot"), "Controller exposes TASK_1011 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_line"), "Command feedback exports TASK_1011 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_status"), "Command feedback exports TASK_1011 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1011")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready_for_acceptance"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked round-loop acceptance snapshot remains read-only")


func _test_ready_source_without_trace_needs_acceptance_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1011")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1011", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1010", "Snapshot links TASK_1010")
	_assert(String(snapshot.get("source_status", "")) == "round_loop_player_feel_polish_ready", "Source status recorded")
	_assert(String(snapshot.get("status", "")) == "needs_round_loop_acceptance_trace", "Ready source without trace needs acceptance trace")
	_assert(String(snapshot.get("gate", "")) == "needs_round_loop_acceptance_trace", "Gate asks for acceptance trace")
	_assert(issue_ids.has("round_loop_acceptance_trace_missing"), "Missing acceptance trace is explicit")
	_assert(not bool(snapshot.get("round_loop_acceptance_slice_passed", true)), "Missing trace does not pass acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed snapshot remains read-only")


func _test_failed_trace_reports_round_loop_acceptance_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_polish(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	var missing_checks: Array = Array(snapshot.get("missing_acceptance_checks", []))
	_assert(String(snapshot.get("status", "")) == "round_loop_acceptance_regression_found", "Failed trace reports acceptance regression")
	_assert(String(snapshot.get("gate", "")) == "round_loop_acceptance_regression_found", "Failed trace gate reports regression")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-NEXT")
	_assert(missing_checks.has("multiplayer_boundary_preserved"), "Failed trace records missing multiplayer boundary")
	_assert(issue_ids.has("feedback_does_not_return_to_next"), "Missing feedback-to-NEXT issue is explicit")
	_assert(issue_ids.has("multiplayer_boundary_risk"), "Missing multiplayer boundary issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish", "Regression routes back to TASK_1010 polish")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_good_trace_accepts_round_loop_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_polish(), _good_trace())
	var answered_questions: Array = Array(snapshot.get("answered_player_questions", []))
	_assert(String(snapshot.get("status", "")) == "round_loop_acceptance_slice_passed", "Good trace passes round-loop acceptance")
	_assert(String(snapshot.get("gate", "")) == "round_loop_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("round_loop_acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("round_loop_acceptance_line", "")).contains("FEEL"), "Acceptance line names FEEL")
	_assert(String(snapshot.get("round_loop_acceptance_line", "")).contains("NEXT"), "Acceptance line names NEXT")
	_assert(String(snapshot.get("round_loop_acceptance_line", "")).contains("GO separat"), "Acceptance line names GO boundary")
	_assert(answered_questions.has("what_is_the_round_state"), "Acceptance answers round state")
	_assert(answered_questions.has("what_is_next"), "Acceptance answers next grip")
	_assert(answered_questions.has("what_requires_go"), "Acceptance answers GO boundary")
	_assert(answered_questions.has("who_owns_truth"), "Acceptance answers ownership")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 6, "Acceptance covers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed acceptance recommends scenario stitch")
	_assert(_snapshot_is_read_only(snapshot), "Passed acceptance remains read-only")


func _test_controller_exports_round_loop_acceptance_slice() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_snapshot"):
		_assert(false, "Controller exposes TASK_1011 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_snapshot(_source_player_feel_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1011 schema matches")
	_assert(String(snapshot.get("status", "")) == "round_loop_acceptance_slice_passed", "Controller TASK_1011 passes with trace")
	_assert(String(snapshot.get("round_loop_acceptance_line", "")).contains("NEXT"), "Controller TASK_1011 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1011 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice"), "Command feedback embeds TASK_1011")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_line"), "Command feedback exports TASK_1011 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_acceptance_slice_status"), "Command feedback exports TASK_1011 status")
	controller.queue_free()


func _test_round_loop_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_player_feel_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1011 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1011", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1010", "Roundtrip keeps TASK_1010 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_polish: Dictionary, acceptance_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1011 service is loadable")
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
		_assert(false, "TASK_1011 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_polish, acceptance_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1011 service returns dictionary")
	return {}


func _source_player_feel_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1010",
		"source_task_id": "TASK_1009",
		"status": "round_loop_player_feel_polish_ready",
		"source_status": "round_loop_player_feel_rework_needed",
		"player_feel_surface_specs": [
			_surface_spec("entry_surface", "entry_clarity", "START", "Start klar: Mission, ROUND und erster NEXT-Griff."),
			_surface_spec("rhythm_surface", "round_next_go_rhythm", "RHYTHM", "ROUND gelesen -> NEXT waehlen -> GO separat."),
			_surface_spec("feedback_surface", "feedback_next_grip", "FEEDBACK", "Feedback nennt Ergebnis und sofort NEXT."),
			_surface_spec("go_boundary_surface", "go_boundary", "GO", "GO bleibt bewusst separat."),
			_surface_spec("hud_surface", "hud_calm", "HUD", "HUD ruhig: wenige starke Tokens."),
			_surface_spec("multiplayer_surface", "multiplayer_boundary", "MP", "MP-Grenze klar: Preview liest, Runtime besitzt Wahrheit."),
		],
		"player_feel_surface_spec_count": 6,
		"player_feel_polish_line": "FEEL ruhiger | NEXT klarer | GO separat | Feedback fuehrt weiter",
		"next_grip_line": "NEXT: Nach Feedback wieder einen klaren Griff anbieten.",
		"go_boundary_microcopy": "GO bleibt bewusst separat: erst planen, dann ausfuehren.",
		"calm_hud_guidance": "HUD ruhig halten: nur ROUND, NEXT, GO und Feedback akzentuieren.",
		"performance_feedback_hint": "Feedback getaktet halten; keine UI-Baeume pro Frame neu bauen.",
		"ready_for_acceptance_review": true,
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
		"style_id": "task_1011_%s" % role,
		"accent": "gold",
		"min_height": 28.0,
		"max_lines": 2,
		"line_budget": 72,
		"autowrap": true,
		"clip_text": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"feel_next_go_visible",
		"start_context_clear",
		"round_next_go_rhythm_clear",
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
		"feel_next_go_visible": true,
		"start_context_clear": true,
		"round_next_go_rhythm_clear": true,
		"feedback_returns_to_next": true,
		"go_boundary_clear": true,
		"hud_calm": true,
		"performance_feels_responsive": true,
		"multiplayer_boundary_preserved": true,
		"no_new_hud_gameplay_truth": true,
		"answered_player_questions": [
			"what_is_the_round_state",
			"what_is_next",
			"what_requires_go",
			"what_feedback_means",
			"why_the_hud_is_quiet",
			"who_owns_truth",
		],
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["feel_next_go_visible", "go_boundary_clear"]
	trace["feedback_returns_to_next"] = false
	trace["multiplayer_boundary_preserved"] = false
	trace["answered_player_questions"] = ["what_requires_go"]
	return trace


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
