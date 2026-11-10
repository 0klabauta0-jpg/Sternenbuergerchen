extends SceneTree

const Acceptance := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_acceptance_slice.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_984_release_first_decision_loop_two_player_loop_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_acceptance_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_acceptance_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_visual_polish.v1"
const NEXT_TASK := "TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_984 Release First Decision Loop Two Player Loop Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_visual_polish_without_trace_needs_acceptance_trace()
	_test_failed_trace_routes_to_visual_polish()
	_test_good_trace_accepts_player_loop_slice()
	_test_controller_exports_player_loop_acceptance_slice()
	_test_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_984_release_first_decision_loop_two_player_loop_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_984_release_first_decision_loop_two_player_loop_acceptance_slice: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_984 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_984 acceptance service exists")
	_assert(task_text.contains("TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice"), "Task names TASK_984")
	_assert(task_text.contains(NEXT_TASK), "Task names scenario follow-up")
	_assert(status_text.contains("TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice"), "Implementation status tracks TASK_984")
	_assert(roadmap_text.contains("TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice (implementiert"), "Roadmap marks TASK_984 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Acceptance Slice (TASK_984)"), "Mission feedback contract documents TASK_984")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Acceptance Slice (TASK_984)"), "Decision clarity contract documents TASK_984")
	_assert(service_text.contains(SCHEMA), "Acceptance service exposes stable TASK_984 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_984\""), "Acceptance service writes TASK_984 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_983\""), "Acceptance service links TASK_983")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Acceptance service defines required checks")
	_assert(service_text.contains("\"read_only\": true"), "Acceptance service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Acceptance service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Acceptance service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Acceptance service creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_ACCEPTANCE_SLICE_SCRIPT"), "Controller preloads TASK_984 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_acceptance_slice_snapshot"), "Controller exposes TASK_984 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_acceptance_slice_line"), "Command feedback exports TASK_984 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_984")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready_for_acceptance_slice"), "Missing source reports readiness mismatch")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_ready_visual_polish_without_trace_needs_acceptance_trace() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_ready_visual_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_player_loop_acceptance_trace", "Ready source without trace needs acceptance trace")
	_assert(String(snapshot.get("gate", "")) == "needs_player_loop_acceptance_trace", "Missing trace gates acceptance run")
	_assert(issue_ids.has("player_loop_acceptance_trace_missing"), "Missing trace issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice", "Missing trace loops on TASK_984")
	_assert(_snapshot_is_read_only(snapshot), "Needs-trace snapshot remains read-only")


func _test_failed_trace_routes_to_visual_polish() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_ready_visual_polish(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "player_loop_acceptance_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "player_loop_acceptance_regression_found", "Failed trace gate names regression")
	_assert(issue_ids.has("choice_confirm_feedback_missing"), "Failed trace names missing confirm feedback")
	_assert(issue_ids.has("player_readability_not_answered"), "Failed trace names weak readability")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_983 - Release First Decision Loop Two Player Loop Visual Polish", "Failed trace routes to visual polish")
	_assert(_snapshot_is_read_only(snapshot), "Failed trace remains read-only")


func _test_good_trace_accepts_player_loop_slice() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_ready_visual_polish(), _good_trace())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_984")
	_assert(String(snapshot.get("task_id", "")) == "TASK_984", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_983", "Snapshot links TASK_983")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_983 schema")
	_assert(String(snapshot.get("status", "")) == "player_loop_acceptance_slice_passed", "Good trace passes acceptance slice")
	_assert(String(snapshot.get("gate", "")) == "player_loop_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("acceptance_line", "")).contains("SECURE"), "Acceptance line names SECURE")
	_assert(String(snapshot.get("acceptance_line", "")).contains("RESET"), "Acceptance line names RESET")
	_assert(String(snapshot.get("acceptance_line", "")).contains("GO separat"), "Acceptance line names GO boundary")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 6, "Acceptance answers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Good trace recommends scenario outcome slice")
	_assert(_snapshot_is_read_only(snapshot), "Good trace remains read-only")


func _test_controller_exports_player_loop_acceptance_slice() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_acceptance_slice_snapshot(_ready_visual_polish(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_984 schema matches")
	_assert(String(snapshot.get("status", "")) == "player_loop_acceptance_slice_passed", "Controller TASK_984 can pass with trace")
	_assert(String(snapshot.get("acceptance_line", "")).contains("PUSH"), "Controller TASK_984 line names PUSH")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_984 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_acceptance_slice"), "Command feedback embeds TASK_984")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_acceptance_slice_line"), "Command feedback exports TASK_984 line")
	controller.queue_free()


func _test_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = Acceptance.build_snapshot(_ready_visual_polish(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_984 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_984", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_983", "Roundtrip keeps TASK_983 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _ready_visual_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_983",
		"source_task_id": "TASK_982",
		"status": "player_loop_visual_polish_ready",
		"active": true,
		"button_visual_specs": [
			_visual_spec("secure_area", "SECURE", "defend"),
			_visual_spec("push_objective", "PUSH", "move"),
			_visual_spec("flank_pressure", "FLANK", "flank"),
			_visual_spec("reset_spacing", "RESET", "move"),
		],
		"button_visual_spec_count": 4,
		"choice_group_line": "CHOICE BUTTONS SECURE / PUSH / FLANK / RESET | Confirm -> GO separat",
		"choice_feedback_line": "Choice Confirm: Befehl vorbereitet | danach GO druecken",
		"go_separation_line": "GO bleibt separat: Choice bestaetigt nur die naechste Order.",
		"recommended_next_task": "TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice",
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


func _visual_spec(choice_id: String, button_text: String, command_type: String) -> Dictionary:
	return {
		"choice_id": choice_id,
		"button_text": button_text,
		"command_type": command_type,
		"button_min_width": 78.0,
		"button_min_height": 46.0,
		"button_tooltip": "%s: vorbereitet; GO separat druecken." % button_text,
		"visual_style_id": "choice_%s" % button_text.to_lower(),
		"separate_go_required": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _good_trace() -> Dictionary:
	var checks: Array = [
		"four_choices_visible",
		"four_choices_readable",
		"choice_tooltips_explain_go",
		"choice_confirm_feedback_visible",
		"go_button_still_separate",
		"choice_does_not_auto_execute_go",
		"selected_choice_prepares_order",
		"player_readability_answered",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"four_choices_visible": true,
		"four_choices_readable": true,
		"choice_tooltips_explain_go": true,
		"choice_confirm_feedback_visible": true,
		"go_button_still_separate": true,
		"choice_does_not_auto_execute_go": true,
		"selected_choice_prepares_order": true,
		"selected_choice_id": "push_objective",
		"player_readability_answered": true,
		"answered_player_questions": [
			"which_choices_are_available",
			"what_does_secure_do",
			"what_does_push_do",
			"what_does_flank_do",
			"what_does_reset_do",
			"why_is_go_separate",
		],
		"no_new_hud_gameplay_truth": true,
		"multiplayer_boundary_preserved": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["completed_checks"] = ["four_choices_visible", "four_choices_readable", "go_button_still_separate"]
	trace["choice_confirm_feedback_visible"] = false
	trace["player_readability_answered"] = false
	trace["answered_player_questions"] = ["which_choices_are_available"]
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
