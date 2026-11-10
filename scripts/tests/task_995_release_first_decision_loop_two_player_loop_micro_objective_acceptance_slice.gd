extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_confirm_smoke.v1"
const NEXT_TASK := "TASK_996 - Release First Decision Loop Two Player Loop Micro Objective Outcome Slice"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_995 Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_confirm_without_trace_needs_acceptance_trace()
	_test_failed_trace_routes_to_confirm_smoke()
	_test_good_trace_accepts_micro_objective_slice()
	_test_controller_exports_micro_objective_acceptance_slice()
	_test_micro_objective_acceptance_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice: FAILED")
		quit(1)
		return
	print("TASK_995_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_995 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_995 acceptance service exists")
	_assert(task_text.contains("TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice"), "Task names TASK_995")
	_assert(task_text.contains(NEXT_TASK), "Task names outcome follow-up")
	_assert(status_text.contains("TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice"), "Implementation status tracks TASK_995")
	_assert(roadmap_text.contains("TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice (implementiert"), "Roadmap marks TASK_995 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice (TASK_995)"), "Mission feedback contract documents TASK_995")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice (TASK_995)"), "Decision clarity contract documents TASK_995")
	_assert(service_text.contains(SCHEMA), "Acceptance service exposes stable TASK_995 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_995\""), "Acceptance service writes TASK_995 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_994\""), "Acceptance service links TASK_994")
	_assert(service_text.contains("REQUIRED_ACCEPTANCE_CHECKS"), "Acceptance service defines required checks")
	_assert(service_text.contains("\"micro_objective_acceptance_slice_passed\""), "Acceptance service reports pass flag")
	_assert(service_text.contains("\"creates_command\": false"), "Acceptance service creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Acceptance service creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ACCEPTANCE_SLICE_SCRIPT"), "Controller preloads TASK_995 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_snapshot"), "Controller exposes TASK_995 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_line"), "Command feedback exports TASK_995 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_995")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed_for_acceptance"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_passed_confirm_without_trace_needs_acceptance_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_passed_confirm_smoke(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_micro_objective_acceptance_trace", "Passed source without trace needs acceptance trace")
	_assert(String(snapshot.get("gate", "")) == "needs_micro_objective_acceptance_trace", "Missing trace gates acceptance run")
	_assert(issue_ids.has("micro_objective_acceptance_trace_missing"), "Missing trace issue is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_995 - Release First Decision Loop Two Player Loop Micro Objective Acceptance Slice", "Missing trace loops on TASK_995")
	_assert(_snapshot_is_read_only(snapshot), "Needs-trace snapshot remains read-only")


func _test_failed_trace_routes_to_confirm_smoke() -> void:
	var snapshot: Dictionary = _build_snapshot(_passed_confirm_smoke(), _failed_trace())
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "micro_objective_acceptance_regression_found", "Failed trace reports regression")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_acceptance_regression_found", "Failed trace gate names regression")
	_assert(issue_ids.has("confirm_feedback_missing"), "Failed trace names missing confirm feedback")
	_assert(issue_ids.has("player_readability_not_answered"), "Failed trace names weak readability")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke", "Failed trace routes to confirm smoke")
	_assert(_snapshot_is_read_only(snapshot), "Failed trace remains read-only")


func _test_good_trace_accepts_micro_objective_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_passed_confirm_smoke(), _good_trace())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_995")
	_assert(String(snapshot.get("task_id", "")) == "TASK_995", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_994", "Snapshot links TASK_994")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_994 schema")
	_assert(String(snapshot.get("status", "")) == "micro_objective_acceptance_slice_passed", "Good trace passes acceptance slice")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_acceptance_slice_passed", "Good trace gate passes")
	_assert(bool(snapshot.get("micro_objective_acceptance_slice_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("acceptance_line", "")).contains("SICHERN"), "Acceptance line names SICHERN")
	_assert(String(snapshot.get("acceptance_line", "")).contains("SAMMELN"), "Acceptance line names SAMMELN")
	_assert(String(snapshot.get("acceptance_line", "")).contains("GO separat"), "Acceptance line names GO boundary")
	_assert(String(snapshot.get("selected_micro_objective_id", "")) == "secure_gained_ground", "Acceptance keeps selected micro objective")
	_assert(int(snapshot.get("answered_player_question_count", 0)) >= 6, "Acceptance answers player questions")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Good trace recommends outcome slice")
	_assert(_snapshot_is_read_only(snapshot), "Good trace remains read-only")


func _test_controller_exports_micro_objective_acceptance_slice() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_snapshot"):
		_assert(false, "Controller exposes TASK_995 method")
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_snapshot",
		_passed_confirm_smoke(),
		_good_trace()
	))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_995 schema matches")
	_assert(String(snapshot.get("status", "")) == "micro_objective_acceptance_slice_passed", "Controller TASK_995 can pass with trace")
	_assert(String(snapshot.get("acceptance_line", "")).contains("DRUECKEN"), "Controller TASK_995 line names DRUECKEN")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_995 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice"), "Command feedback embeds TASK_995")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_acceptance_slice_line"), "Command feedback exports TASK_995 line")
	controller.queue_free()


func _test_micro_objective_acceptance_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_passed_confirm_smoke(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_995 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_995", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_994", "Roundtrip keeps TASK_994 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_confirm_smoke: Dictionary, acceptance_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_995 service is loadable")
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
		_assert(false, "TASK_995 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_confirm_smoke, acceptance_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_995 service returns dictionary")
	return {}


func _passed_confirm_smoke() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_994",
		"source_task_id": "TASK_993",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.v1",
		"status": "micro_objective_confirm_smoke_passed",
		"gate": "micro_objective_confirm_smoke_passed",
		"active": true,
		"selected_micro_objective_id": "secure_gained_ground",
		"selected_micro_objective_label": "SICHERN",
		"selected_button_slot": "CommandSlot08",
		"selected_command_type": "defend",
		"confirm_action": "confirm_release_first_decision_loop_two_player_loop_micro_objective_button",
		"draft_confirm_action": "_issue_command",
		"execute_action": "execute_selected_fireteam_orders",
		"micro_objective_labels": ["SICHERN", "DRUECKEN", "SAMMELN"],
		"micro_objective_confirm_line": "MICRO OBJ SICHERN -> confirmed | GO separat",
		"post_confirm_feedback_line": "MICRO OBJ SICHERN DEFEND -> GO",
		"go_button_still_separate": true,
		"go_executed": false,
		"command_queue_lifecycle_observed": true,
		"micro_objective_confirm_smoke_passed": true,
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


func _good_trace() -> Dictionary:
	var checks: Array = [
		"three_micro_objectives_visible",
		"three_micro_objectives_readable",
		"selected_micro_objective_confirmed",
		"confirm_feedback_visible",
		"go_button_still_separate",
		"micro_objective_does_not_auto_execute_go",
		"selected_micro_objective_prepares_order",
		"player_readability_answered",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"trace_available": true,
		"completed_checks": checks,
		"three_micro_objectives_visible": true,
		"three_micro_objectives_readable": true,
		"selected_micro_objective_confirmed": true,
		"confirm_feedback_visible": true,
		"go_button_still_separate": true,
		"micro_objective_does_not_auto_execute_go": true,
		"selected_micro_objective_prepares_order": true,
		"selected_micro_objective_id": "secure_gained_ground",
		"player_readability_answered": true,
		"answered_player_questions": [
			"which_micro_objectives_are_available",
			"what_does_sichern_do",
			"what_does_druecken_do",
			"what_does_sammeln_do",
			"what_happened_after_confirm",
			"why_is_go_still_needed",
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
	trace["completed_checks"] = ["three_micro_objectives_visible", "go_button_still_separate"]
	trace["confirm_feedback_visible"] = false
	trace["player_readability_answered"] = false
	trace["answered_player_questions"] = ["which_micro_objectives_are_available"]
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
