extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_967_release_first_decision_loop_two_go_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_go_smoke.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_go_smoke_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_go_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_execution_hook.v1"
const NEXT_TASK := "TASK_968 - Release First Decision Loop Two Runtime Button"

var _passed: int = 0
var _failed: int = 0
var _service: Resource


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_967 Release First Decision Loop Two GO Smoke ===")
	_service = ResourceLoader.load(SERVICE_PATH)
	_test_docs_and_static_hooks()
	_test_missing_execution_hook_blocks_go_smoke()
	_test_ready_hook_without_trace_needs_go_smoke()
	_test_completed_smoke_accepts_existing_confirm_and_go_paths()
	_test_failed_or_combined_trace_is_rejected()
	await _test_controller_exports_go_smoke()
	_test_go_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_967_release_first_decision_loop_two_go_smoke: FAILED")
		quit(1)
		return
	print("TASK_967_release_first_decision_loop_two_go_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_967 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_967 GO-smoke service exists")
	_assert(task_text.contains("TASK_967 - Release First Decision Loop Two GO Smoke"), "Task names TASK_967")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_968 follow-up")
	_assert(status_text.contains("TASK_967 - Release First Decision Loop Two GO Smoke"), "Implementation status tracks TASK_967")
	_assert(roadmap_text.contains("TASK_967 - Release First Decision Loop Two GO Smoke (implementiert"), "Roadmap marks TASK_967 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two GO Smoke (TASK_967)"), "Mission feedback contract documents TASK_967")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two GO Smoke (TASK_967)"), "Decision clarity contract documents TASK_967")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_GO_SMOKE_SCRIPT"), "Controller preloads TASK_967 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_go_smoke_snapshot"), "Controller exposes TASK_967 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_go_smoke"), "Command feedback exports TASK_967")
	_assert(service_text.contains(SCHEMA), "GO-smoke service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_967\""), "GO-smoke service writes TASK_967 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_966\""), "GO-smoke service links TASK_966")
	_assert(service_text.contains("NEXT_TASK"), "GO-smoke service declares TASK_968")
	_assert(service_text.contains("\"read_only\": true"), "GO-smoke service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "GO-smoke service creates no command truth")
	_assert(service_text.contains("\"creates_movement\": false"), "GO-smoke service creates no movement truth")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "GO-smoke service creates no multiplayer truth")


func _test_missing_execution_hook_blocks_go_smoke() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", {}, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_966 source blocks TASK_967")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source schema is named")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source task is named")
	_assert(not bool(snapshot.get("active", true)), "Blocked GO smoke is not active")
	_assert(_snapshot_is_read_only(snapshot), "Blocked GO smoke remains read-only")


func _test_ready_hook_without_trace_needs_go_smoke() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _execution_hook(), {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "GO-smoke schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_967", "GO-smoke task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_966", "GO-smoke links TASK_966")
	_assert(String(snapshot.get("gate", "")) == "needs_go_smoke_run", "Ready hook without trace needs smoke run")
	_assert(String(snapshot.get("status", "")) == "needs_loop_two_go_smoke", "Status asks for GO smoke")
	_assert(blocker_ids.has("confirm_not_run"), "Missing confirm call is named")
	_assert(blocker_ids.has("go_not_run"), "Missing GO call is named")
	_assert(not bool(snapshot.get("active", true)), "Unrun smoke is not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Unrun smoke remains read-only")


func _test_completed_smoke_accepts_existing_confirm_and_go_paths() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _execution_hook(), _passing_trace()))
	var trace: Dictionary = Dictionary(snapshot.get("smoke_trace", {}))
	_assert(String(snapshot.get("gate", "")) == "loop_two_go_smoke_passed", "Completed trace passes GO smoke")
	_assert(String(snapshot.get("status", "")) == "ready_for_runtime_button", "Passed smoke routes to runtime button")
	_assert(bool(snapshot.get("active", false)), "Passed smoke is active")
	_assert(String(snapshot.get("selected_choice_id", "")) == "hold_angle", "Smoke keeps selected choice")
	_assert(String(snapshot.get("selected_command_type", "")) == "defend", "Smoke keeps command type")
	_assert(bool(trace.get("confirm_action_called", false)), "Trace records confirm call")
	_assert(bool(trace.get("execute_action_called", false)), "Trace records GO call")
	_assert(String(snapshot.get("smoke_line", "")).contains("CONFIRM _issue_command"), "Smoke line names confirm path")
	_assert(String(snapshot.get("smoke_line", "")).contains("GO execute_selected_fireteam_orders"), "Smoke line names GO path")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed smoke recommends TASK_968")
	_assert(_snapshot_is_read_only(snapshot), "Passed GO smoke remains read-only")


func _test_failed_or_combined_trace_is_rejected() -> void:
	if not _service_available():
		return
	var failed_trace: Dictionary = _passing_trace()
	failed_trace["execute_action_result"] = false
	var failed: Dictionary = Dictionary(_service.call("build_snapshot", _execution_hook(), failed_trace))
	var failed_ids: Array = _issue_ids(Array(failed.get("blocking_issues", [])))
	_assert(String(failed.get("gate", "")) == "go_smoke_review", "Failed execute trace needs review")
	_assert(failed_ids.has("go_result_failed"), "Failed GO result is named")
	var combined_trace: Dictionary = _passing_trace()
	combined_trace["confirm_and_go_are_separate_steps"] = false
	var combined: Dictionary = Dictionary(_service.call("build_snapshot", _execution_hook(), combined_trace))
	var combined_ids: Array = _issue_ids(Array(combined.get("blocking_issues", [])))
	_assert(String(combined.get("gate", "")) == "go_smoke_review", "Combined confirm/GO trace is rejected")
	_assert(combined_ids.has("confirm_go_not_separate"), "Combined confirm/GO issue is named")
	_assert(_snapshot_is_read_only(combined), "Rejected smoke remains read-only")


func _test_controller_exports_go_smoke() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_release_first_decision_loop_two_go_smoke_snapshot"), "Controller has TASK_967 public snapshot")
	if not controller.has_method("get_release_first_decision_loop_two_go_smoke_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_go_smoke_snapshot",
		_execution_hook(),
		_passing_trace()
	))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_967 schema matches")
	_assert(String(snapshot.get("gate", "")) == "loop_two_go_smoke_passed", "Controller TASK_967 can accept supplied smoke trace")
	_assert(String(snapshot.get("smoke_line", "")).contains("GO"), "Controller TASK_967 line keeps GO visible")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_967 remains read-only")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(command_feedback.get("release_first_decision_loop_two_go_smoke", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_967")
	_assert(String(command_feedback.get("release_first_decision_loop_two_go_smoke_line", "")).contains("GO"), "Command feedback exports TASK_967 line")
	controller.queue_free()


func _test_go_smoke_roundtrip() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _execution_hook(), _passing_trace()))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_967 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_967", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_966", "Roundtrip keeps TASK_966 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _execution_hook() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_966",
		"source_task_id": "TASK_965",
		"gate": "execution_hook_ready",
		"status": "ready_for_loop_two_go_smoke",
		"active": true,
		"selected_choice_id": "hold_angle",
		"selected_command_type": "defend",
		"command_draft": {
			"choice_id": "hold_angle",
			"fireteam_id": "ft1",
			"command_type": "defend",
			"command_label": "Defend",
			"confirm_action": "_issue_command",
			"execute_action": "execute_selected_fireteam_orders",
			"requires_selected_tile": true,
			"requires_go": true,
			"auto_execute": false,
			"read_only": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_movement": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"sets_multiplayer_truth": false,
		},
		"execution_line": "HOOK HOLD Defend | GO bestaetigt",
		"requires_existing_go_path": true,
		"auto_confirms": false,
		"auto_executes_go": false,
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


func _passing_trace() -> Dictionary:
	return {
		"confirm_action_exists": true,
		"execute_action_exists": true,
		"confirm_action_called": true,
		"execute_action_called": true,
		"confirm_action_result": true,
		"execute_action_result": true,
		"confirm_and_go_are_separate_steps": true,
		"post_go_feedback_visible": true,
		"post_go_feedback_line": "GO FT1",
		"command_queue_lifecycle_observed": true,
		"runtime_mutation_owner": "MissionTacticalSandboxController -> SimulationRoot.enqueue_command",
		"ui_sets_gameplay_truth": false,
		"sets_multiplayer_truth": false,
	}


func _service_available() -> bool:
	if _service != null:
		return true
	_assert(false, "TASK_967 service can be loaded")
	return false


func _issue_ids(issues: Array) -> Array:
	var result: Array = []
	for issue_variant in issues:
		if typeof(issue_variant) == TYPE_DICTIONARY:
			result.append(String(Dictionary(issue_variant).get("id", "")))
	return result


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


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
