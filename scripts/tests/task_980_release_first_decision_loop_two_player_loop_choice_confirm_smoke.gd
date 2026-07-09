extends SceneTree

const ChoiceConfirmSmoke := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_choice_confirm_smoke.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_choice_confirm_smoke.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_choice_confirm_smoke_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_confirm_smoke.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_runtime_choice_buttons.v1"
const NEXT_TASK := "TASK_981 - Release First Decision Loop Two Player Loop Real Window Capture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_980 Release First Decision Loop Two Player Loop Choice Confirm Smoke ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_trace_requests_smoke()
	_test_good_trace_passes_confirm_smoke()
	_test_regression_trace_flags_auto_go()
	_test_controller_exports_choice_confirm_smoke()
	_test_choice_confirm_smoke_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke: FAILED")
		quit(1)
		return
	print("TASK_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_980 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_980 choice confirm smoke service exists")
	_assert(task_text.contains("TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke"), "Task names TASK_980")
	_assert(task_text.contains(NEXT_TASK), "Task names real-window follow-up")
	_assert(status_text.contains("TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke"), "Implementation status tracks TASK_980")
	_assert(roadmap_text.contains("TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke (implementiert"), "Roadmap marks TASK_980 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Choice Confirm Smoke (TASK_980)"), "Mission feedback contract documents TASK_980")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Choice Confirm Smoke (TASK_980)"), "Decision clarity contract documents TASK_980")
	_assert(service_text.contains(SCHEMA), "Choice confirm smoke service exposes stable TASK_980 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_980\""), "Choice confirm smoke service writes TASK_980 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_979\""), "Choice confirm smoke service links TASK_979")
	_assert(service_text.contains("\"choice_confirm_smoke_passed\""), "Choice confirm smoke reports pass flag")
	_assert(service_text.contains("\"go_executed_during_choice_confirm\""), "Choice confirm smoke catches auto-GO")
	_assert(service_text.contains("\"creates_movement\": false"), "Choice confirm smoke creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Choice confirm smoke creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_CHOICE_CONFIRM_SMOKE_SCRIPT"), "Controller preloads TASK_980 service")
	_assert(controller_text.contains("confirm_release_first_decision_loop_two_player_loop_choice_button"), "Controller exposes TASK_980 confirm callback")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_choice_confirm_smoke_snapshot"), "Controller exposes TASK_980 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_choice_confirm_smoke_line"), "Command feedback exports TASK_980 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = ChoiceConfirmSmoke.build_snapshot({}, {}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_980")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("runtime_buttons_not_ready"), "Missing source reports runtime buttons not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked TASK_980 snapshot remains read-only")


func _test_ready_source_without_trace_requests_smoke() -> void:
	var snapshot: Dictionary = ChoiceConfirmSmoke.build_snapshot(_runtime_buttons_source(), _choice_hook_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_980")
	_assert(String(snapshot.get("status", "")) == "needs_choice_confirm_smoke", "Ready source without trace asks for smoke")
	_assert(String(snapshot.get("gate", "")) == "needs_choice_confirm_smoke_run", "Ready source without trace keeps smoke gate open")
	_assert(not bool(snapshot.get("choice_confirm_smoke_passed", true)), "No trace does not pass smoke")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke", "No trace recommends same smoke")
	_assert(_snapshot_is_read_only(snapshot), "No-trace snapshot remains read-only")


func _test_good_trace_passes_confirm_smoke() -> void:
	var snapshot: Dictionary = ChoiceConfirmSmoke.build_snapshot(_runtime_buttons_source(), _choice_hook_source(), _good_trace())
	var completed: Array = Array(snapshot.get("completed_checks", []))
	_assert(String(snapshot.get("status", "")) == "choice_confirm_smoke_passed", "Good trace passes TASK_980")
	_assert(String(snapshot.get("gate", "")) == "choice_confirm_smoke_passed", "Good trace passes gate")
	_assert(bool(snapshot.get("choice_confirm_smoke_passed", false)), "Good trace sets pass flag")
	_assert(String(snapshot.get("selected_choice_id", "")) == "secure_area", "Good trace keeps selected choice")
	_assert(String(snapshot.get("smoke_line", "")).contains("SECURE"), "Good trace line names selected choice")
	_assert(String(snapshot.get("smoke_line", "")).contains("GO separat"), "Good trace line names GO boundary")
	_assert(completed.has("choice_button_pressed"), "Good trace records button press")
	_assert(completed.has("confirm_action_called"), "Good trace records confirm")
	_assert(completed.has("go_button_still_separate"), "Good trace records separate GO")
	_assert(completed.has("post_confirm_feedback_visible"), "Good trace records feedback")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Good trace recommends real-window capture")
	_assert(_snapshot_is_read_only(snapshot), "Passed TASK_980 snapshot remains read-only")


func _test_regression_trace_flags_auto_go() -> void:
	var trace: Dictionary = _good_trace()
	trace["go_executed"] = true
	trace["post_confirm_feedback_visible"] = false
	var snapshot: Dictionary = ChoiceConfirmSmoke.build_snapshot(_runtime_buttons_source(), _choice_hook_source(), trace)
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "choice_confirm_smoke_regression_found", "Auto-GO trace fails TASK_980")
	_assert(issue_ids.has("go_executed_during_choice_confirm"), "Auto-GO trace reports GO regression")
	_assert(issue_ids.has("post_confirm_feedback_missing"), "Bad trace reports missing feedback")
	_assert(not bool(snapshot.get("choice_confirm_smoke_passed", true)), "Regression trace does not pass")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_controller_exports_choice_confirm_smoke() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_choice_confirm_smoke_snapshot(
		_runtime_buttons_source(),
		_choice_hook_source(),
		_good_trace()
	)
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_980 schema matches")
	_assert(String(snapshot.get("status", "")) == "choice_confirm_smoke_passed", "Controller TASK_980 can pass with trace")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_980 snapshot remains read-only")
	_assert(controller.has_method("confirm_release_first_decision_loop_two_player_loop_choice_button"), "Controller exposes choice confirm method")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_choice_confirm_smoke"), "Command feedback embeds TASK_980")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_choice_confirm_smoke_line"), "Command feedback exports TASK_980 line")
	controller.queue_free()


func _test_choice_confirm_smoke_roundtrip() -> void:
	var snapshot: Dictionary = ChoiceConfirmSmoke.build_snapshot(_runtime_buttons_source(), _choice_hook_source(), _good_trace())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_980 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_980", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_979", "Roundtrip keeps TASK_979 link")
	_assert(bool(roundtrip.get("choice_confirm_smoke_passed", false)), "Roundtrip keeps pass flag")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _runtime_buttons_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_979",
		"source_task_id": "TASK_978",
		"status": "runtime_choice_buttons_ready",
		"gate": "runtime_choice_buttons_ready",
		"active": true,
		"button_specs": [
			_spec("secure_area", "SECURE", "CommandSlot08", "defend"),
			_spec("push_objective", "PUSH", "CommandSlot09", "move"),
			_spec("flank_pressure", "FLANK", "CommandSlot10", "flank"),
			_spec("reset_spacing", "RESET", "CommandSlot11", "move"),
		],
		"button_count": 4,
		"runtime_buttons_line": "CHOICE BUTTONS SECURE / PUSH / FLANK / RESET | GO separat",
		"press_action": "confirm_release_first_decision_loop_two_player_loop_choice_button",
		"execute_action": "execute_selected_fireteam_orders",
		"separate_go_required": true,
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


func _choice_hook_source() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_hook.v1",
		"task_id": "TASK_978",
		"status": "choice_hook_ready",
		"gate": "choice_hook_ready",
		"active": true,
		"selected_choice_id": "secure_area",
		"selected_command_type": "defend",
		"command_draft": {
			"choice_id": "secure_area",
			"command_type": "defend",
			"confirm_action": "_issue_command",
			"execute_action": "execute_selected_fireteam_orders",
			"separate_go_required": true,
			"auto_executes_go": false,
			"read_only": true,
		},
		"confirm_action": "_issue_command",
		"execute_action": "execute_selected_fireteam_orders",
		"requires_existing_go_path": true,
		"separate_go_required": true,
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


func _spec(choice_id: String, text: String, slot_name: String, command_type: String) -> Dictionary:
	return {
		"choice_id": choice_id,
		"button_text": text,
		"slot_name": slot_name,
		"slot_path": "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/%s" % slot_name,
		"command_type": command_type,
		"press_action": "confirm_release_first_decision_loop_two_player_loop_choice_button",
		"execute_action": "execute_selected_fireteam_orders",
		"button_enabled": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _good_trace() -> Dictionary:
	return {
		"trace_available": true,
		"selected_choice_id": "secure_area",
		"pressed_button_slot": "CommandSlot08",
		"press_action_exists": true,
		"confirm_action_exists": true,
		"execute_action_exists": true,
		"choice_button_pressed": true,
		"confirm_action_called": true,
		"confirm_action_result": true,
		"go_executed": false,
		"go_button_still_separate": true,
		"post_confirm_feedback_visible": true,
		"post_confirm_feedback_line": "SECURE DEFEND -> GO",
		"command_queue_lifecycle_observed": true,
		"runtime_mutation_owner": "MissionTacticalSandboxController -> SimulationRoot.enqueue_command",
		"ui_sets_gameplay_truth": false,
		"creates_movement": false,
		"sets_multiplayer_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", false)) \
		and not bool(snapshot.get("creates_navigation", false)) \
		and not bool(snapshot.get("creates_fire_event", false)) \
		and not bool(snapshot.get("creates_damage_event", false)) \
		and not bool(snapshot.get("creates_movement", false)) \
		and not bool(snapshot.get("sets_multiplayer_truth", false)) \
		and not bool(snapshot.get("updates_shortcuts", false))


func _issue_ids(issues: Array) -> Array:
	var ids: Array = []
	for issue_variant in issues:
		ids.append(String(Dictionary(issue_variant).get("id", "")))
	return ids


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _read_json_dict(path: String) -> Dictionary:
	var text: String = _read_text(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
		return
	_failed += 1
	push_error("[FAIL] %s" % message)
