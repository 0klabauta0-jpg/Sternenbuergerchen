extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1014_release_first_decision_loop_two_player_loop_scenario_runtime_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_scenario_runtime_smoke.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_scenario_runtime_smoke.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_runtime_hook.v1"
const NEXT_TASK := "TASK_1015 - Release First Decision Loop Two Player Loop Scenario Player Feel Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1014 Release First Decision Loop Two Player Loop Scenario Runtime Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_hook_without_trace_needs_smoke_trace()
	_test_failed_trace_reports_regression()
	_test_good_trace_passes_scenario_runtime_smoke()
	_test_controller_exports_runtime_smoke()
	_test_runtime_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1014_release_first_decision_loop_two_player_loop_scenario_runtime_smoke: FAILED")
		quit(1)
		return
	print("TASK_1014_release_first_decision_loop_two_player_loop_scenario_runtime_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1014 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1014 scenario runtime smoke service exists")
	_assert(task_text.contains("TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke"), "Task names TASK_1014")
	_assert(task_text.contains(NEXT_TASK), "Task names player-feel findings follow-up")
	_assert(status_text.contains("TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke"), "Implementation status tracks TASK_1014")
	_assert(roadmap_text.contains("TASK_1014 - Release First Decision Loop Two Player Loop Scenario Runtime Smoke (implementiert"), "Roadmap marks TASK_1014 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Runtime Smoke (TASK_1014)"), "Mission feedback contract documents TASK_1014")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Scenario Runtime Smoke (TASK_1014)"), "Decision clarity contract documents TASK_1014")
	_assert(service_text.contains(SCHEMA), "Scenario runtime smoke service exposes stable TASK_1014 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1014\""), "Scenario runtime smoke service writes TASK_1014 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1013\""), "Scenario runtime smoke service links TASK_1013")
	_assert(service_text.contains("REQUIRED_SMOKE_CHECKS"), "Scenario runtime smoke defines required checks")
	_assert(service_text.contains("\"scenario_runtime_smoke_passed\""), "Scenario runtime smoke exposes pass flag")
	_assert(service_text.contains("\"smoke_line\""), "Scenario runtime smoke exposes smoke line")
	_assert(service_text.contains("\"creates_command\": false"), "Scenario runtime smoke creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Scenario runtime smoke creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_SCENARIO_RUNTIME_SMOKE_SCRIPT"), "Controller preloads TASK_1014 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_scenario_runtime_smoke_snapshot"), "Controller exposes TASK_1014 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_runtime_smoke_line"), "Command feedback exports TASK_1014 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_scenario_runtime_smoke_status"), "Command feedback exports TASK_1014 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1014")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked runtime smoke snapshot remains read-only")


func _test_ready_hook_without_trace_needs_smoke_trace() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_hook(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1014")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1014", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1013", "Snapshot links TASK_1013")
	_assert(String(snapshot.get("status", "")) == "needs_scenario_runtime_smoke_trace", "Ready source without trace needs smoke trace")
	_assert(String(snapshot.get("gate", "")) == "needs_scenario_runtime_smoke_trace", "Gate asks for smoke trace")
	_assert(issue_ids.has("scenario_runtime_smoke_trace_missing"), "Missing smoke trace is explicit")
	_assert(not bool(snapshot.get("scenario_runtime_smoke_passed", true)), "Missing trace does not pass smoke")
	_assert(_snapshot_is_read_only(snapshot), "Trace-needed smoke snapshot remains read-only")


func _test_failed_trace_reports_regression() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_hook(), _failed_trace())
	var missing_checks: Array = Array(snapshot.get("missing_smoke_checks", []))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "scenario_runtime_smoke_regression_found", "Failed trace reports smoke regression")
	_assert(String(snapshot.get("gate", "")) == "scenario_runtime_smoke_regression_found", "Failed trace gate reports smoke regression")
	_assert(missing_checks.has("go_still_separate"), "Failed trace records missing GO separation")
	_assert(missing_checks.has("feedback_returns_to_next"), "Failed trace records missing feedback-to-NEXT")
	_assert(issue_ids.has("go_still_separate_missing"), "Missing GO separation issue is explicit")
	_assert(issue_ids.has("feedback_returns_to_next_missing"), "Missing feedback-to-NEXT issue is explicit")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_1013 - Release First Decision Loop Two Player Loop Scenario Runtime Hook", "Regression routes back to TASK_1013")
	_assert(_snapshot_is_read_only(snapshot), "Regression smoke snapshot remains read-only")


func _test_good_trace_passes_scenario_runtime_smoke() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_hook(), _good_trace())
	var completed_checks: Array = Array(snapshot.get("completed_checks", []))
	_assert(String(snapshot.get("status", "")) == "scenario_runtime_smoke_passed", "Good trace passes runtime smoke")
	_assert(String(snapshot.get("gate", "")) == "scenario_runtime_smoke_passed", "Good trace gate passes runtime smoke")
	_assert(bool(snapshot.get("scenario_runtime_smoke_passed", false)), "Good trace sets pass flag")
	_assert(completed_checks.size() >= 10, "Good trace completes required checks")
	_assert(String(snapshot.get("smoke_line", "")).contains("ENTRY"), "Smoke line names ENTRY")
	_assert(String(snapshot.get("smoke_line", "")).contains("NEXT"), "Smoke line names NEXT")
	_assert(String(snapshot.get("smoke_line", "")).contains("GO"), "Smoke line names GO")
	_assert(String(snapshot.get("post_smoke_feedback_line", "")).contains("NEXT"), "Post-smoke feedback returns to NEXT")
	_assert(String(snapshot.get("selected_runtime_choice_id", "")) == "secure_relay", "Good trace records selected runtime choice")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed smoke recommends player-feel findings")
	_assert(_snapshot_is_read_only(snapshot), "Passed smoke remains read-only")


func _test_controller_exports_runtime_smoke() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_scenario_runtime_smoke_snapshot"):
		_assert(false, "Controller exposes TASK_1014 snapshot")
		controller.queue_free()
		return
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_scenario_runtime_smoke_snapshot(_ready_hook(), _good_trace())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1014 schema matches")
	_assert(String(snapshot.get("status", "")) == "scenario_runtime_smoke_passed", "Controller TASK_1014 can pass with trace")
	_assert(String(snapshot.get("smoke_line", "")).contains("NEXT"), "Controller TASK_1014 line names NEXT")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1014 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_runtime_smoke"), "Command feedback embeds TASK_1014")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_runtime_smoke_line"), "Command feedback exports TASK_1014 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_scenario_runtime_smoke_status"), "Command feedback exports TASK_1014 status")
	controller.queue_free()


func _test_runtime_smoke_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_ready_hook(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1014 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1014", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1013", "Roundtrip keeps TASK_1013 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_runtime_hook: Dictionary, smoke_trace: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1014 service is loadable")
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
		_assert(false, "TASK_1014 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_runtime_hook, smoke_trace)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1014 service returns dictionary")
	return {}


func _ready_hook() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1013",
		"source_task_id": "TASK_1012",
		"status": "runtime_hook_ready",
		"gate": "runtime_hook_ready",
		"runtime_hook_ready": true,
		"mission_control_runtime_line": "FOB FOB Relay Probe | ENTRY | Relais sichern -> NEXT SICHERN | GO separat",
		"selected_fireteam_runtime_line": "Alpha | ENTRY | Alpha bestaetigt GO und liest Feedback. | Confirm vor GO",
		"current_step_id": "entry",
		"selected_runtime_choice_id": "secure_relay",
		"scenario_runtime_steps": [
			{"step_id": "entry", "label": "ENTRY"},
			{"step_id": "first_contact", "label": "CONTACT"},
			{"step_id": "decision", "label": "DECIDE"},
			{"step_id": "feedback", "label": "FEEDBACK"},
			{"step_id": "exit", "label": "EXIT"},
		],
		"command_matrix_runtime_hooks": [
			{"hook_id": "next", "label": "NEXT", "enabled": true},
			{"hook_id": "confirm", "label": "CONFIRM", "enabled": true, "creates_command": false},
			{"hook_id": "go", "label": "GO", "enabled": true, "auto_executes": false},
		],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
	}


func _good_trace() -> Dictionary:
	return {
		"trace_available": true,
		"entry_visible": true,
		"next_visible": true,
		"runtime_choice_selected": true,
		"confirm_visible": true,
		"confirm_action_result": true,
		"go_still_separate": true,
		"no_auto_go_after_confirm": true,
		"go_executed_after_confirm": true,
		"post_go_feedback_visible": true,
		"feedback_returns_to_next": true,
		"hud_read_only_boundary_ok": true,
		"multiplayer_boundary_preserved": true,
		"selected_runtime_choice_id": "secure_relay",
		"post_smoke_feedback_line": "Feedback gelesen -> NEXT sichern oder Exit.",
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _failed_trace() -> Dictionary:
	var trace: Dictionary = _good_trace()
	trace["go_still_separate"] = false
	trace["feedback_returns_to_next"] = false
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
