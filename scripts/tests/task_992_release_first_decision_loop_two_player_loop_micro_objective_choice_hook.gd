extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_choice_hook.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_choice_hook_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_choice_hook.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.v1"
const NEXT_TASK := "TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_992 Release First Decision Loop Two Player Loop Micro Objective Choice Hook ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_builds_focused_command_draft()
	_test_each_micro_objective_maps_to_existing_command_path()
	_test_unknown_objective_blocks_without_mutation()
	_test_controller_exports_micro_objective_choice_hook()
	_test_micro_objective_choice_hook_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook: FAILED")
		quit(1)
		return
	print("TASK_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_992 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_992 choice hook service exists")
	_assert(task_text.contains("TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook"), "Task names TASK_992")
	_assert(task_text.contains(NEXT_TASK), "Task names runtime buttons follow-up")
	_assert(status_text.contains("TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook"), "Implementation status tracks TASK_992")
	_assert(roadmap_text.contains("TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook (implementiert"), "Roadmap marks TASK_992 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Choice Hook (TASK_992)"), "Mission feedback contract documents TASK_992")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Choice Hook (TASK_992)"), "Decision clarity contract documents TASK_992")
	_assert(service_text.contains(SCHEMA), "Choice hook service exposes stable TASK_992 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_992\""), "Choice hook service writes TASK_992 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_991\""), "Choice hook service links TASK_991")
	_assert(service_text.contains("\"micro_objective_command_draft\""), "Choice hook exposes micro objective command draft")
	_assert(service_text.contains("\"confirm_action\": \"_issue_command\""), "Choice hook uses existing issue-command path")
	_assert(service_text.contains("\"execute_action\": \"execute_selected_fireteam_orders\""), "Choice hook keeps existing GO path")
	_assert(service_text.contains("\"auto_confirms\": false"), "Choice hook does not auto-confirm")
	_assert(service_text.contains("\"auto_executes_go\": false"), "Choice hook does not auto-GO")
	_assert(service_text.contains("\"creates_command\": false"), "Choice hook creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Choice hook creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Choice hook creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_CHOICE_HOOK_SCRIPT"), "Controller preloads TASK_992 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_choice_hook_snapshot"), "Controller exposes TASK_992 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_choice_hook_line"), "Command feedback exports TASK_992 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_choice_hook_command_draft"), "Command feedback exports TASK_992 draft")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, "")
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_992")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked choice hook snapshot remains read-only")


func _test_ready_source_builds_focused_command_draft() -> void:
	var snapshot: Dictionary = _build_snapshot(_hud_wiring_source(), "")
	var draft: Dictionary = Dictionary(snapshot.get("micro_objective_command_draft", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_992")
	_assert(String(snapshot.get("task_id", "")) == "TASK_992", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_991", "Snapshot links TASK_991")
	_assert(String(snapshot.get("status", "")) == "micro_objective_choice_hook_ready", "Ready HUD wiring builds choice hook")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_choice_hook_ready", "Ready HUD wiring passes choice hook gate")
	_assert(String(snapshot.get("selected_micro_objective_id", "")) == "secure_gained_ground", "Default selected objective uses focused objective")
	_assert(String(snapshot.get("selected_command_type", "")) == "defend", "Secure objective maps to defend")
	_assert(String(draft.get("confirm_action", "")) == "_issue_command", "Draft confirms through issue-command")
	_assert(String(draft.get("execute_action", "")) == "execute_selected_fireteam_orders", "Draft keeps GO path")
	_assert(String(snapshot.get("micro_objective_choice_hook_line", "")).contains("SICHERN"), "Hook line names selected micro objective")
	_assert(String(snapshot.get("micro_objective_choice_hook_line", "")).contains("GO separat"), "Hook line keeps GO separate")
	_assert(bool(snapshot.get("requires_existing_go_path", false)), "Hook requires existing GO path")
	_assert(not bool(snapshot.get("auto_confirms", true)), "Hook does not auto-confirm")
	_assert(not bool(snapshot.get("auto_executes_go", true)), "Hook does not auto-GO")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Hook recommends runtime buttons")
	_assert(_snapshot_is_read_only(snapshot), "Choice hook snapshot remains read-only")


func _test_each_micro_objective_maps_to_existing_command_path() -> void:
	var expected := {
		"secure_gained_ground": "defend",
		"press_next_contact": "move",
		"regroup_fireteam": "hold",
	}
	for objective_id in expected.keys():
		var snapshot: Dictionary = _build_snapshot(_hud_wiring_source(), String(objective_id))
		_assert(String(snapshot.get("selected_micro_objective_id", "")) == String(objective_id), "%s selected" % objective_id)
		_assert(String(snapshot.get("selected_command_type", "")) == String(expected[objective_id]), "%s maps to command" % objective_id)
		_assert(String(snapshot.get("confirm_action", "")) == "_issue_command", "%s keeps confirm action" % objective_id)
		_assert(String(snapshot.get("execute_action", "")) == "execute_selected_fireteam_orders", "%s keeps GO action" % objective_id)
		_assert(_snapshot_is_read_only(snapshot), "%s remains read-only" % objective_id)


func _test_unknown_objective_blocks_without_mutation() -> void:
	var snapshot: Dictionary = _build_snapshot(_hud_wiring_source(), "invalid_objective")
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Unknown objective blocks TASK_992")
	_assert(blocker_ids.has("selected_micro_objective_missing"), "Unknown objective reports missing selected micro objective")
	_assert(Dictionary(snapshot.get("micro_objective_command_draft", {})).is_empty(), "Unknown objective creates no draft")
	_assert(_snapshot_is_read_only(snapshot), "Unknown objective snapshot remains read-only")


func _test_controller_exports_micro_objective_choice_hook() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_choice_hook_snapshot"):
		_assert(false, "Controller exposes TASK_992 method")
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_player_loop_micro_objective_choice_hook_snapshot",
		_hud_wiring_source(),
		"press_next_contact"
	))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_992 schema matches")
	_assert(String(snapshot.get("selected_micro_objective_id", "")) == "press_next_contact", "Controller can select pressure objective")
	_assert(String(snapshot.get("selected_command_type", "")) == "move", "Controller pressure objective maps to move")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_992 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_choice_hook"), "Command feedback embeds TASK_992")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_choice_hook_line"), "Command feedback exports TASK_992 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_choice_hook_command_draft"), "Command feedback exports TASK_992 draft")
	controller.queue_free()


func _test_micro_objective_choice_hook_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_hud_wiring_source(), "regroup_fireteam")
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_992 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_992", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_991", "Roundtrip keeps TASK_991 link")
	_assert(String(roundtrip.get("selected_micro_objective_id", "")) == "regroup_fireteam", "Roundtrip keeps selected objective")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_hud_wiring: Dictionary, selected_objective_id: String) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_992 service is loadable")
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
		_assert(false, "TASK_992 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_hud_wiring, selected_objective_id)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_992 service returns dictionary")
	return {}


func _hud_wiring_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_991",
		"source_task_id": "TASK_990",
		"status": "micro_objective_hud_wiring_ready",
		"gate": "micro_objective_hud_wiring_ready",
		"active": true,
		"hud_wiring_ready": true,
		"focused_micro_objective_id": "secure_gained_ground",
		"recommended_micro_objective_id": "secure_gained_ground",
		"selected_fireteam_line": "NEXT OBJ SICHERN | OBJ SICHERN: Zielstand halten | GO separat",
		"mission_control_line": "OBJ SICHERN / DRUECKEN / SAMMELN | Empfehlung SICHERN",
		"command_feedback_line": "MICRO OBJ: SICHERN fokussiert | GO separat",
		"hud_micro_objective_chips": [
			_chip("secure_gained_ground", "SICHERN", "defend"),
			_chip("press_next_contact", "DRUECKEN", "move"),
			_chip("regroup_fireteam", "SAMMELN", "hold"),
		],
		"hud_micro_objective_chip_count": 3,
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


func _chip(objective_id: String, label: String, command_intent: String) -> Dictionary:
	return {
		"chip_id": "chip_%s" % objective_id,
		"slot_id": "slot_%s" % objective_id,
		"objective_id": objective_id,
		"label": label,
		"command_intent": command_intent,
		"display_text": "%s | %s" % [label, command_intent.to_upper()],
		"tooltip_text": "%s | GO separat" % label,
		"player_line": "OBJ %s: naechsten Griff vorbereiten." % label,
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
