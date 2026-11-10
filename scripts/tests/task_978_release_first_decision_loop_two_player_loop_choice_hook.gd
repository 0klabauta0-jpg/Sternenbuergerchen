extends SceneTree

const ChoiceHook := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_choice_hook.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_978_release_first_decision_loop_two_player_loop_choice_hook.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_choice_hook.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_choice_hook_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_hook.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_hud_wiring.v1"
const NEXT_TASK := "TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_978 Release First Decision Loop Two Player Loop Choice Hook ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_default_recommended_choice_builds_command_draft()
	_test_each_choice_maps_to_existing_command_path()
	_test_unknown_choice_blocks_without_mutation()
	_test_controller_exports_choice_hook()
	_test_choice_hook_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_978_release_first_decision_loop_two_player_loop_choice_hook: FAILED")
		quit(1)
		return
	print("TASK_978_release_first_decision_loop_two_player_loop_choice_hook: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_978 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_978 choice hook service exists")
	_assert(task_text.contains("TASK_978 - Release First Decision Loop Two Player Loop Choice Hook"), "Task names TASK_978")
	_assert(task_text.contains(NEXT_TASK), "Task names runtime choice buttons follow-up")
	_assert(status_text.contains("TASK_978 - Release First Decision Loop Two Player Loop Choice Hook"), "Implementation status tracks TASK_978")
	_assert(roadmap_text.contains("TASK_978 - Release First Decision Loop Two Player Loop Choice Hook (implementiert"), "Roadmap marks TASK_978 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Choice Hook (TASK_978)"), "Mission feedback contract documents TASK_978")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Choice Hook (TASK_978)"), "Decision clarity contract documents TASK_978")
	_assert(service_text.contains(SCHEMA), "Choice hook service exposes stable TASK_978 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_978\""), "Choice hook service writes TASK_978 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_977\""), "Choice hook service links TASK_977")
	_assert(service_text.contains("\"command_draft\""), "Choice hook exposes command draft")
	_assert(service_text.contains("\"confirm_action\": \"_issue_command\""), "Choice hook uses existing issue-command path")
	_assert(service_text.contains("\"execute_action\": \"execute_selected_fireteam_orders\""), "Choice hook keeps existing GO path")
	_assert(service_text.contains("\"auto_confirms\": false"), "Choice hook does not auto-confirm")
	_assert(service_text.contains("\"auto_executes_go\": false"), "Choice hook does not auto-GO")
	_assert(service_text.contains("\"creates_command\": false"), "Choice hook creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Choice hook creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Choice hook creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_CHOICE_HOOK_SCRIPT"), "Controller preloads TASK_978 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_choice_hook_snapshot"), "Controller exposes TASK_978 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_choice_hook_line"), "Command feedback exports TASK_978 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = ChoiceHook.build_snapshot({}, "")
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_978")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_default_recommended_choice_builds_command_draft() -> void:
	var snapshot: Dictionary = ChoiceHook.build_snapshot(_hud_wiring_source(), "")
	var draft: Dictionary = Dictionary(snapshot.get("command_draft", {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_978")
	_assert(String(snapshot.get("task_id", "")) == "TASK_978", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_977", "Snapshot links TASK_977")
	_assert(String(snapshot.get("status", "")) == "choice_hook_ready", "Ready HUD wiring builds choice hook")
	_assert(String(snapshot.get("gate", "")) == "choice_hook_ready", "Ready HUD wiring passes choice hook gate")
	_assert(String(snapshot.get("selected_choice_id", "")) == "secure_area", "Default choice uses recommended secure_area")
	_assert(String(snapshot.get("selected_command_type", "")) == "defend", "Secure maps to defend")
	_assert(String(draft.get("confirm_action", "")) == "_issue_command", "Draft confirms through issue-command")
	_assert(String(draft.get("execute_action", "")) == "execute_selected_fireteam_orders", "Draft keeps GO path")
	_assert(String(snapshot.get("choice_hook_line", "")).contains("SECURE"), "Hook line names selected choice")
	_assert(String(snapshot.get("choice_hook_line", "")).contains("GO separat"), "Hook line keeps GO separate")
	_assert(bool(snapshot.get("requires_existing_go_path", false)), "Hook requires existing GO path")
	_assert(not bool(snapshot.get("auto_confirms", true)), "Hook does not auto-confirm")
	_assert(not bool(snapshot.get("auto_executes_go", true)), "Hook does not auto-GO")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Hook recommends runtime choice buttons")
	_assert(_snapshot_is_read_only(snapshot), "Choice hook snapshot remains read-only")


func _test_each_choice_maps_to_existing_command_path() -> void:
	var expected := {
		"secure_area": "defend",
		"push_objective": "move",
		"flank_pressure": "flank",
		"reset_spacing": "move",
	}
	for choice_id in expected.keys():
		var snapshot: Dictionary = ChoiceHook.build_snapshot(_hud_wiring_source(), String(choice_id))
		_assert(String(snapshot.get("selected_choice_id", "")) == String(choice_id), "%s selected" % choice_id)
		_assert(String(snapshot.get("selected_command_type", "")) == String(expected[choice_id]), "%s maps to command" % choice_id)
		_assert(String(snapshot.get("confirm_action", "")) == "_issue_command", "%s keeps confirm action" % choice_id)
		_assert(String(snapshot.get("execute_action", "")) == "execute_selected_fireteam_orders", "%s keeps GO action" % choice_id)
		_assert(_snapshot_is_read_only(snapshot), "%s remains read-only" % choice_id)


func _test_unknown_choice_blocks_without_mutation() -> void:
	var snapshot: Dictionary = ChoiceHook.build_snapshot(_hud_wiring_source(), "invalid_choice")
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Unknown choice blocks TASK_978")
	_assert(blocker_ids.has("selected_choice_missing"), "Unknown choice reports missing selected choice")
	_assert(Dictionary(snapshot.get("command_draft", {})).is_empty(), "Unknown choice creates no draft")
	_assert(_snapshot_is_read_only(snapshot), "Unknown choice snapshot remains read-only")


func _test_controller_exports_choice_hook() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_choice_hook_snapshot(_hud_wiring_source(), "flank_pressure")
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_978 schema matches")
	_assert(String(snapshot.get("selected_choice_id", "")) == "flank_pressure", "Controller can select flank choice")
	_assert(String(snapshot.get("selected_command_type", "")) == "flank", "Controller flank choice maps to flank")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_978 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_choice_hook"), "Command feedback embeds TASK_978")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_choice_hook_line"), "Command feedback exports TASK_978 line")
	controller.queue_free()


func _test_choice_hook_roundtrip() -> void:
	var snapshot: Dictionary = ChoiceHook.build_snapshot(_hud_wiring_source(), "push_objective")
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_978 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_978", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_977", "Roundtrip keeps TASK_977 link")
	_assert(String(roundtrip.get("selected_choice_id", "")) == "push_objective", "Roundtrip keeps selected choice")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _hud_wiring_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_977",
		"source_task_id": "TASK_976",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_extension.v1",
		"status": "player_loop_hud_wiring_ready",
		"gate": "player_loop_hud_wiring_ready",
		"active": true,
		"source_recommended_choice_id": "secure_area",
		"selected_fireteam_line": "NEXT SECURE -> SECURE / PUSH / FLANK / RESET",
		"mission_control_line": "WHY SECURE | OBJ MEDIUM | CONTACT MEDIUM",
		"command_feedback_line": "NEXT SECURE -> SECURE / PUSH / FLANK / RESET | CHOICES SECURE / PUSH / FLANK / RESET",
		"hud_choice_chips": [
			_chip("secure_area", "SECURE", "SECURE Bereich sichern", "Defend"),
			_chip("push_objective", "PUSH", "PUSH Ziel druecken", "Move/Take"),
			_chip("flank_pressure", "FLANK", "FLANK Druck drehen", "Flank"),
			_chip("reset_spacing", "RESET", "RESET neu sammeln", "Move/Defend"),
		],
		"hud_choice_chip_count": 4,
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


func _chip(choice_id: String, token: String, label: String, command_hint: String) -> Dictionary:
	return {
		"choice_id": choice_id,
		"token": token,
		"label": label,
		"command_hint": command_hint,
		"risk_label": "test",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
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
