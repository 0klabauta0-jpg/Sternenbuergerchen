extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_choice_hook.v1"
const HUD_WIRING_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.v1"
const NEXT_TASK := "TASK_994 - Release First Decision Loop Two Player Loop Micro Objective Confirm Smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_993 Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_choice_hook_builds_three_button_specs()
	_test_button_slots_are_stable_and_go_separate()
	_test_controller_exports_micro_objective_runtime_buttons()
	_test_micro_objective_runtime_buttons_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons: FAILED")
		quit(1)
		return
	print("TASK_993_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_993 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_993 runtime buttons service exists")
	_assert(task_text.contains("TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons"), "Task names TASK_993")
	_assert(task_text.contains(NEXT_TASK), "Task names confirm-smoke follow-up")
	_assert(status_text.contains("TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons"), "Implementation status tracks TASK_993")
	_assert(roadmap_text.contains("TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons (implementiert"), "Roadmap marks TASK_993 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons (TASK_993)"), "Mission feedback contract documents TASK_993")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons (TASK_993)"), "Decision clarity contract documents TASK_993")
	_assert(service_text.contains(SCHEMA), "Runtime buttons service exposes stable TASK_993 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_993\""), "Runtime buttons service writes TASK_993 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_992\""), "Runtime buttons service links TASK_992")
	_assert(service_text.contains("\"micro_objective_button_specs\""), "Runtime buttons service exposes button specs")
	_assert(service_text.contains("\"CommandSlot08\""), "Runtime buttons use CommandSlot08")
	_assert(service_text.contains("\"CommandSlot10\""), "Runtime buttons use CommandSlot10")
	_assert(service_text.contains("\"press_action\": \"confirm_release_first_decision_loop_two_player_loop_micro_objective_button\""), "Runtime buttons expose micro-objective confirm action")
	_assert(service_text.contains("\"auto_executes_go\": false"), "Runtime buttons do not auto-GO")
	_assert(service_text.contains("\"creates_command\": false"), "Runtime buttons snapshot creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Runtime buttons create no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_RUNTIME_BUTTONS_SCRIPT"), "Controller preloads TASK_993 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_snapshot"), "Controller exposes TASK_993 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_line"), "Command feedback exports TASK_993 line")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_runtime_button_specs"), "Command feedback exports TASK_993 specs")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_993")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_choice_hook_builds_three_button_specs() -> void:
	var snapshot: Dictionary = _build_snapshot(_choice_hook_source(), _hud_wiring_source())
	var specs: Array = Array(snapshot.get("micro_objective_button_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_993")
	_assert(String(snapshot.get("task_id", "")) == "TASK_993", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_992", "Snapshot links TASK_992")
	_assert(String(snapshot.get("status", "")) == "micro_objective_runtime_buttons_ready", "Ready choice hook builds runtime buttons")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_runtime_buttons_ready", "Ready choice hook passes runtime button gate")
	_assert(bool(snapshot.get("active", false)), "Runtime buttons are active")
	_assert(int(snapshot.get("micro_objective_button_count", 0)) == 3, "Runtime buttons expose three micro objective buttons")
	_assert(String(snapshot.get("runtime_buttons_line", "")).contains("SICHERN"), "Runtime line names SICHERN")
	_assert(String(snapshot.get("runtime_buttons_line", "")).contains("SAMMELN"), "Runtime line names SAMMELN")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Runtime buttons recommend confirm smoke")
	_assert(_button_specs_are_read_only(specs), "Button specs remain read-only")
	_assert(_snapshot_is_read_only(snapshot), "Runtime buttons snapshot remains read-only")


func _test_button_slots_are_stable_and_go_separate() -> void:
	var snapshot: Dictionary = _build_snapshot(_choice_hook_source(), _hud_wiring_source())
	var specs: Array = Array(snapshot.get("micro_objective_button_specs", []))
	var expected_slots := ["CommandSlot08", "CommandSlot09", "CommandSlot10"]
	var expected_labels := ["SICHERN", "DRUECKEN", "SAMMELN"]
	if specs.size() < expected_slots.size():
		_assert(false, "Button specs exist before slot checks")
		return
	for i in range(expected_slots.size()):
		var spec := Dictionary(specs[i])
		_assert(String(spec.get("slot_name", "")) == expected_slots[i], "%s slot is stable" % expected_labels[i])
		_assert(String(spec.get("button_text", "")) == expected_labels[i], "%s button text is compact" % expected_labels[i])
		_assert(String(spec.get("press_action", "")) == "confirm_release_first_decision_loop_two_player_loop_micro_objective_button", "%s uses micro-objective confirm action" % expected_labels[i])
		_assert(String(spec.get("execute_action", "")) == "execute_selected_fireteam_orders", "%s keeps GO action" % expected_labels[i])
		_assert(bool(spec.get("separate_go_required", false)), "%s keeps GO separate" % expected_labels[i])
		_assert(not bool(spec.get("auto_executes_go", true)), "%s does not auto-GO" % expected_labels[i])


func _test_controller_exports_micro_objective_runtime_buttons() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_snapshot"):
		_assert(false, "Controller exposes TASK_993 method")
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_snapshot",
		_choice_hook_source(),
		_hud_wiring_source()
	))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_993 schema matches")
	_assert(int(snapshot.get("micro_objective_button_count", 0)) == 3, "Controller TASK_993 has three buttons")
	_assert(String(snapshot.get("runtime_buttons_line", "")).contains("DRUECKEN"), "Controller TASK_993 line names buttons")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_993 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons"), "Command feedback embeds TASK_993")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_runtime_buttons_line"), "Command feedback exports TASK_993 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_runtime_button_specs"), "Command feedback exports TASK_993 specs")
	controller.queue_free()


func _test_micro_objective_runtime_buttons_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_choice_hook_source(), _hud_wiring_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_993 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_993", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_992", "Roundtrip keeps TASK_992 link")
	_assert(int(roundtrip.get("micro_objective_button_count", 0)) == 3, "Roundtrip keeps button count")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_choice_hook: Dictionary, source_hud_wiring: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_993 service is loadable")
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
		_assert(false, "TASK_993 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_choice_hook, source_hud_wiring)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_993 service returns dictionary")
	return {}


func _choice_hook_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_992",
		"source_task_id": "TASK_991",
		"status": "micro_objective_choice_hook_ready",
		"gate": "micro_objective_choice_hook_ready",
		"active": true,
		"selected_micro_objective_id": "secure_gained_ground",
		"selected_command_type": "defend",
		"micro_objective_command_draft": {
			"micro_objective_id": "secure_gained_ground",
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


func _hud_wiring_source() -> Dictionary:
	return {
		"schema": HUD_WIRING_SCHEMA,
		"task_id": "TASK_991",
		"source_task_id": "TASK_990",
		"status": "micro_objective_hud_wiring_ready",
		"gate": "micro_objective_hud_wiring_ready",
		"active": true,
		"hud_wiring_ready": true,
		"hud_micro_objective_chips": [
			_chip("secure_gained_ground", "SICHERN", "defend"),
			_chip("press_next_contact", "DRUECKEN", "move"),
			_chip("regroup_fireteam", "SAMMELN", "hold"),
		],
		"hud_micro_objective_chip_count": 3,
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


func _chip(objective_id: String, label: String, command_intent: String) -> Dictionary:
	return {
		"objective_id": objective_id,
		"label": label,
		"command_intent": command_intent,
		"player_line": "OBJ %s: vorbereiten." % label,
		"why_line": "%s haelt den Loop lesbar." % label,
		"confirm_action": "_issue_command",
		"execute_action": "execute_selected_fireteam_orders",
		"requires_existing_go_path": true,
		"separate_go_required": true,
		"auto_confirms": false,
		"auto_executes_go": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _button_specs_are_read_only(specs: Array) -> bool:
	if specs.size() != 3:
		return false
	for spec_variant in specs:
		if typeof(spec_variant) != TYPE_DICTIONARY:
			return false
		var spec := Dictionary(spec_variant)
		if not bool(spec.get("read_only", false)):
			return false
		if bool(spec.get("creates_command", true)):
			return false
		if bool(spec.get("auto_executes_go", true)):
			return false
	return true


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
