extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_966_release_first_decision_loop_two_execution_hook.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_execution_hook.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_execution_hook_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_execution_hook.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_polish.v1"
const NEXT_TASK := "TASK_967 - Release First Decision Loop Two GO Smoke"

var _passed: int = 0
var _failed: int = 0
var _service: Resource


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_966 Release First Decision Loop Two Execution Hook ===")
	_service = ResourceLoader.load(SERVICE_PATH)
	_test_docs_and_static_hooks()
	_test_missing_polish_blocks_execution_hook()
	_test_passed_polish_builds_hold_execution_hook()
	_test_advance_and_fallback_hooks_use_existing_paths()
	await _test_controller_exports_execution_hook()
	_test_execution_hook_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_966_release_first_decision_loop_two_execution_hook: FAILED")
		quit(1)
		return
	print("TASK_966_release_first_decision_loop_two_execution_hook: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_966 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_966 execution hook service exists")
	_assert(task_text.contains("TASK_966 - Release First Decision Loop Two Execution Hook"), "Task names TASK_966")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_967 follow-up")
	_assert(status_text.contains("TASK_966 - Release First Decision Loop Two Execution Hook"), "Implementation status tracks TASK_966")
	_assert(roadmap_text.contains("TASK_966 - Release First Decision Loop Two Execution Hook (implementiert"), "Roadmap marks TASK_966 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Execution Hook (TASK_966)"), "Mission feedback contract documents TASK_966")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Execution Hook (TASK_966)"), "Decision clarity contract documents TASK_966")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_EXECUTION_HOOK_SCRIPT"), "Controller preloads TASK_966 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_execution_hook_snapshot"), "Controller exposes TASK_966 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_execution_hook"), "Command feedback exports TASK_966")
	_assert(service_text.contains(SCHEMA), "Execution hook service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_966\""), "Execution hook service writes TASK_966 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_965\""), "Execution hook service links TASK_965")
	_assert(service_text.contains("NEXT_TASK"), "Execution hook service declares TASK_967")
	_assert(service_text.contains("\"read_only\": true"), "Execution hook service declares read-only")
	_assert(service_text.contains("\"auto_confirms\": false"), "Execution hook service does not auto-confirm")
	_assert(service_text.contains("\"auto_executes_go\": false"), "Execution hook service does not auto-GO")
	_assert(service_text.contains("\"creates_command\": false"), "Execution hook service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Execution hook service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Execution hook service creates no multiplayer truth")


func _test_missing_polish_blocks_execution_hook() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", {}, {"selected_choice_id": "hold_angle"}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_965 source blocks TASK_966")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source schema is named")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source task is named")
	_assert(not bool(snapshot.get("active", true)), "Blocked execution hook is not active")
	_assert(_snapshot_is_read_only(snapshot), "Blocked execution hook remains read-only")


func _test_passed_polish_builds_hold_execution_hook() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _polish(), {"selected_choice_id": "hold_angle", "fireteam_id": "ft1"}))
	var draft: Dictionary = Dictionary(snapshot.get("command_draft", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Execution hook schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_966", "Execution hook task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_965", "Execution hook links TASK_965")
	_assert(String(snapshot.get("gate", "")) == "execution_hook_ready", "Passed polish enables execution hook")
	_assert(String(snapshot.get("status", "")) == "ready_for_loop_two_go_smoke", "Execution hook routes to GO smoke")
	_assert(bool(snapshot.get("active", false)), "Execution hook is active")
	_assert(String(snapshot.get("selected_choice_id", "")) == "hold_angle", "Selected choice is hold")
	_assert(String(snapshot.get("selected_command_type", "")) == "defend", "Hold maps to defend command")
	_assert(String(draft.get("confirm_action", "")) == "_issue_command", "Hold uses existing issue-command path")
	_assert(String(draft.get("execute_action", "")) == "execute_selected_fireteam_orders", "Hold keeps existing GO path")
	_assert(bool(draft.get("requires_selected_tile", false)), "Hold/defend requires selected tile")
	_assert(String(snapshot.get("execution_line", "")).contains("HOLD Defend"), "Execution line explains hold")
	_assert(_hook_does_not_auto_execute(snapshot), "Hook does not auto-confirm or auto-GO")
	_assert(_snapshot_is_read_only(snapshot), "Hold execution hook remains read-only")


func _test_advance_and_fallback_hooks_use_existing_paths() -> void:
	if not _service_available():
		return
	var advance: Dictionary = Dictionary(_service.call("build_snapshot", _polish(), {"selected_choice_id": "advance_cover", "fireteam_id": "ft1"}))
	var advance_draft: Dictionary = Dictionary(advance.get("command_draft", {}))
	_assert(String(advance.get("selected_command_type", "")) == "move", "ADV maps to move command")
	_assert(String(advance_draft.get("confirm_action", "")) == "_issue_command", "ADV uses existing issue-command path")
	_assert(bool(advance_draft.get("requires_selected_tile", false)), "ADV requires selected tile")
	_assert(_hook_does_not_auto_execute(advance), "ADV hook does not auto-execute")
	var fallback: Dictionary = Dictionary(_service.call("build_snapshot", _polish(), {"selected_choice_id": "fallback_regroup", "fireteam_id": "ft1"}))
	var fallback_draft: Dictionary = Dictionary(fallback.get("command_draft", {}))
	_assert(String(fallback.get("selected_command_type", "")) == "return", "BACK maps to return command")
	_assert(String(fallback_draft.get("confirm_action", "")) == "return_selected_fireteams_to_plan", "BACK uses existing return path")
	_assert(not bool(fallback_draft.get("requires_selected_tile", true)), "BACK does not require selected tile")
	_assert(_hook_does_not_auto_execute(fallback), "BACK hook does not auto-execute")


func _test_controller_exports_execution_hook() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_release_first_decision_loop_two_execution_hook_snapshot"), "Controller has TASK_966 public snapshot")
	if not controller.has_method("get_release_first_decision_loop_two_execution_hook_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_execution_hook_snapshot",
		_polish(),
		"hold_angle"
	))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_966 schema matches")
	_assert(String(snapshot.get("gate", "")) == "execution_hook_ready", "Controller TASK_966 gate passes")
	_assert(String(snapshot.get("execution_line", "")).contains("GO"), "Controller TASK_966 line keeps GO visible")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_966 remains read-only")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(command_feedback.get("release_first_decision_loop_two_execution_hook", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_966")
	_assert(String(command_feedback.get("release_first_decision_loop_two_execution_line", "")).contains("GO"), "Command feedback exports TASK_966 line")
	controller.queue_free()


func _test_execution_hook_roundtrip() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _polish(), {"selected_choice_id": "hold_angle", "fireteam_id": "ft1"}))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_966 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_966", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_965", "Roundtrip keeps TASK_965 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_965",
		"source_task_id": "TASK_964",
		"next_loop_task_id": "TASK_963",
		"gate": "loop_two_polish_passed",
		"status": "ready_for_second_decision_execution_hook",
		"active": true,
		"recommended_choice_id": "hold_angle",
		"compact_line": "2ND HOLD Defend | ADV Move | BACK Return | GO bestaetigt",
		"second_decision_intents": [
			{"choice_id": "hold_angle", "label": "HOLD", "command_type": "defend", "command_label": "Defend", "execution_boundary": "requires_go", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "creates_fire_event": false, "creates_damage_event": false, "sets_multiplayer_truth": false},
			{"choice_id": "advance_cover", "label": "ADV", "command_type": "move", "command_label": "Move", "execution_boundary": "requires_go", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "creates_fire_event": false, "creates_damage_event": false, "sets_multiplayer_truth": false},
			{"choice_id": "fallback_regroup", "label": "BACK", "command_type": "return", "command_label": "Return", "execution_boundary": "requires_go", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false, "creates_fire_event": false, "creates_damage_event": false, "sets_multiplayer_truth": false},
		],
		"second_decision_intent_count": 3,
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


func _hook_does_not_auto_execute(snapshot: Dictionary) -> bool:
	return not bool(snapshot.get("auto_confirms", true)) \
		and not bool(snapshot.get("auto_executes_go", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_movement", true)) \
		and not bool(Dictionary(snapshot.get("command_draft", {})).get("auto_execute", true))


func _service_available() -> bool:
	if _service != null:
		return true
	_assert(false, "TASK_966 service can be loaded")
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
