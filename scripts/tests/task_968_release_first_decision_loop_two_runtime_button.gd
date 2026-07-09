extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_968_release_first_decision_loop_two_runtime_button.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_runtime_button.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_runtime_button_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_runtime_button.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_go_smoke.v1"
const HOOK_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_execution_hook.v1"
const NEXT_TASK := "TASK_969 - Release First Decision Loop Two Real Window Capture"

var _passed: int = 0
var _failed: int = 0
var _service: Resource


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_968 Release First Decision Loop Two Runtime Button ===")
	_service = ResourceLoader.load(SERVICE_PATH)
	_test_docs_and_static_hooks()
	_test_missing_go_smoke_blocks_runtime_button()
	_test_needs_smoke_run_source_arms_manual_runtime_button()
	_test_passed_go_smoke_source_marks_button_ready()
	_test_review_source_blocks_button()
	await _test_controller_exports_runtime_button()
	_test_runtime_button_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_968_release_first_decision_loop_two_runtime_button: FAILED")
		quit(1)
		return
	print("TASK_968_release_first_decision_loop_two_runtime_button: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_968 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_968 runtime button service exists")
	_assert(task_text.contains("TASK_968 - Release First Decision Loop Two Runtime Button"), "Task names TASK_968")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_969 follow-up")
	_assert(status_text.contains("TASK_968 - Release First Decision Loop Two Runtime Button"), "Implementation status tracks TASK_968")
	_assert(roadmap_text.contains("TASK_968 - Release First Decision Loop Two Runtime Button (implementiert"), "Roadmap marks TASK_968 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Runtime Button (TASK_968)"), "Mission feedback contract documents TASK_968")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Runtime Button (TASK_968)"), "Decision clarity contract documents TASK_968")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_RUNTIME_BUTTON_SCRIPT"), "Controller preloads TASK_968 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_runtime_button_snapshot"), "Controller exposes TASK_968 snapshot")
	_assert(controller_text.contains("confirm_release_first_decision_loop_two_runtime_button"), "Controller exposes TASK_968 confirm method")
	_assert(controller_text.contains("_on_release_first_decision_loop_two_button_pressed"), "Controller exposes TASK_968 button callback")
	_assert(controller_text.contains("CommandSlot07"), "Controller uses existing command matrix slot 07")
	_assert(controller_text.contains("release_first_decision_loop_two_runtime_button"), "Command feedback exports TASK_968")
	_assert(service_text.contains(SCHEMA), "Runtime button service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_968\""), "Runtime button service writes TASK_968 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_967\""), "Runtime button service links TASK_967")
	_assert(service_text.contains("NEXT_TASK"), "Runtime button service declares TASK_969")
	_assert(service_text.contains("\"button_text\": \"2ND\""), "Runtime button service names 2ND button")
	_assert(service_text.contains("\"auto_executes_go\": false"), "Runtime button service does not auto-GO")
	_assert(service_text.contains("\"read_only\": true"), "Runtime button service declares read-only snapshot")


func _test_missing_go_smoke_blocks_runtime_button() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", {}, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_967 source blocks TASK_968")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source schema is named")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source task is named")
	_assert(not bool(snapshot.get("button_enabled", true)), "Blocked runtime button is disabled")
	_assert(_snapshot_is_read_only(snapshot), "Blocked runtime button remains read-only")


func _test_needs_smoke_run_source_arms_manual_runtime_button() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _go_smoke("needs_go_smoke_run"), _execution_hook()))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Runtime button schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_968", "Runtime button task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_967", "Runtime button links TASK_967")
	_assert(String(snapshot.get("gate", "")) == "runtime_button_ready_for_manual_smoke", "Needs-smoke source arms manual runtime button")
	_assert(String(snapshot.get("status", "")) == "runtime_button_ready_for_manual_confirm", "Status asks for manual confirm")
	_assert(bool(snapshot.get("active", false)), "Manual runtime button is active")
	_assert(bool(snapshot.get("button_enabled", false)), "Manual runtime button is enabled")
	_assert(String(snapshot.get("button_text", "")) == "2ND", "Button text is 2ND")
	_assert(String(snapshot.get("button_slot_path", "")).ends_with("CommandSlot07"), "Button uses command slot 07")
	_assert(String(snapshot.get("press_action", "")) == "confirm_release_first_decision_loop_two_runtime_button", "Press action names confirm method")
	_assert(String(snapshot.get("confirm_action", "")) == "_issue_command", "Runtime button keeps confirm action")
	_assert(String(snapshot.get("execute_action", "")) == "execute_selected_fireteam_orders", "Runtime button keeps GO action separate")
	_assert(bool(snapshot.get("separate_go_required", false)), "Runtime button requires separate GO")
	_assert(not bool(snapshot.get("auto_executes_go", true)), "Runtime button does not auto-GO")
	_assert(_snapshot_is_read_only(snapshot), "Manual runtime button snapshot remains read-only")


func _test_passed_go_smoke_source_marks_button_ready() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _go_smoke("loop_two_go_smoke_passed"), _execution_hook()))
	_assert(String(snapshot.get("gate", "")) == "runtime_button_ready", "Passed GO smoke marks runtime button ready")
	_assert(String(snapshot.get("status", "")) == "ready_for_real_window_capture", "Passed runtime button routes to real window capture")
	_assert(String(snapshot.get("runtime_line", "")).contains("2ND HOLD"), "Runtime line names second choice")
	_assert(String(snapshot.get("runtime_line", "")).contains("GO bleibt separat"), "Runtime line keeps GO separate")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Passed runtime button recommends TASK_969")
	_assert(_snapshot_is_read_only(snapshot), "Passed runtime button snapshot remains read-only")


func _test_review_source_blocks_button() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _go_smoke("go_smoke_review"), _execution_hook()))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "runtime_button_blocked", "Review source blocks runtime button")
	_assert(blocker_ids.has("source_gate_not_usable"), "Unusable source gate is named")
	_assert(not bool(snapshot.get("button_enabled", true)), "Review runtime button is disabled")
	_assert(_snapshot_is_read_only(snapshot), "Review runtime button remains read-only")


func _test_controller_exports_runtime_button() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_release_first_decision_loop_two_runtime_button_snapshot"), "Controller has TASK_968 public snapshot")
	_assert(controller.has_method("confirm_release_first_decision_loop_two_runtime_button"), "Controller has TASK_968 confirm method")
	if not controller.has_method("get_release_first_decision_loop_two_runtime_button_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_runtime_button_snapshot",
		_go_smoke("needs_go_smoke_run"),
		_execution_hook()
	))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_968 schema matches")
	_assert(bool(snapshot.get("button_enabled", false)), "Controller TASK_968 enables manual button from hook")
	_assert(String(snapshot.get("runtime_line", "")).contains("GO"), "Controller TASK_968 line keeps GO visible")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_968 snapshot remains read-only")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(command_feedback.get("release_first_decision_loop_two_runtime_button", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_968")
	_assert(String(command_feedback.get("release_first_decision_loop_two_runtime_button_line", "")).contains("2ND"), "Command feedback exports TASK_968 line")
	controller.queue_free()


func _test_runtime_button_roundtrip() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _go_smoke("loop_two_go_smoke_passed"), _execution_hook()))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_968 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_968", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_967", "Roundtrip keeps TASK_967 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _go_smoke(gate: String) -> Dictionary:
	var active: bool = gate in ["needs_go_smoke_run", "loop_two_go_smoke_passed"]
	var status: String = "needs_loop_two_go_smoke"
	if gate == "loop_two_go_smoke_passed":
		status = "ready_for_runtime_button"
	elif gate == "go_smoke_review":
		status = "needs_go_smoke_review"
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_967",
		"source_task_id": "TASK_966",
		"gate": gate,
		"status": status,
		"active": active,
		"selected_choice_id": "hold_angle",
		"selected_command_type": "defend",
		"confirm_action": "_issue_command",
		"execute_action": "execute_selected_fireteam_orders",
		"smoke_line": "GO-SMOKE PENDING | CONFIRM _issue_command | GO execute_selected_fireteam_orders",
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


func _execution_hook() -> Dictionary:
	return {
		"schema": HOOK_SCHEMA,
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


func _service_available() -> bool:
	if _service != null:
		return true
	_assert(false, "TASK_968 service can be loaded")
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
