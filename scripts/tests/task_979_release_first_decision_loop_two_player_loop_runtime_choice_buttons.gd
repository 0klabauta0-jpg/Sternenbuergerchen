extends SceneTree

const RuntimeButtons := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_runtime_choice_buttons.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_runtime_choice_buttons.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_runtime_choice_buttons_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_runtime_choice_buttons.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_choice_hook.v1"
const NEXT_TASK := "TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_979 Release First Decision Loop Two Player Loop Runtime Choice Buttons ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_choice_hook_builds_four_button_specs()
	_test_button_slots_are_stable_and_go_separate()
	_test_controller_exports_runtime_choice_buttons()
	_test_runtime_choice_buttons_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons: FAILED")
		quit(1)
		return
	print("TASK_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_979 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_979 runtime choice buttons service exists")
	_assert(task_text.contains("TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons"), "Task names TASK_979")
	_assert(task_text.contains(NEXT_TASK), "Task names choice confirm smoke follow-up")
	_assert(status_text.contains("TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons"), "Implementation status tracks TASK_979")
	_assert(roadmap_text.contains("TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons (implementiert"), "Roadmap marks TASK_979 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Runtime Choice Buttons (TASK_979)"), "Mission feedback contract documents TASK_979")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Runtime Choice Buttons (TASK_979)"), "Decision clarity contract documents TASK_979")
	_assert(service_text.contains(SCHEMA), "Runtime buttons service exposes stable TASK_979 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_979\""), "Runtime buttons service writes TASK_979 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_978\""), "Runtime buttons service links TASK_978")
	_assert(service_text.contains("\"button_specs\""), "Runtime buttons service exposes button specs")
	_assert(service_text.contains("\"CommandSlot08\""), "Runtime buttons use CommandSlot08")
	_assert(service_text.contains("\"CommandSlot11\""), "Runtime buttons use CommandSlot11")
	_assert(service_text.contains("\"press_action\": \"confirm_release_first_decision_loop_two_player_loop_choice_button\""), "Runtime buttons expose confirm action")
	_assert(service_text.contains("\"auto_executes_go\": false"), "Runtime buttons do not auto-GO")
	_assert(service_text.contains("\"creates_command\": false"), "Runtime buttons snapshot creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Runtime buttons create no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_RUNTIME_CHOICE_BUTTONS_SCRIPT"), "Controller preloads TASK_979 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_runtime_choice_buttons_snapshot"), "Controller exposes TASK_979 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_runtime_choice_buttons_line"), "Command feedback exports TASK_979 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = RuntimeButtons.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_979")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_choice_hook_builds_four_button_specs() -> void:
	var snapshot: Dictionary = RuntimeButtons.build_snapshot(_choice_hook_source(), _hud_wiring_source())
	var specs: Array = Array(snapshot.get("button_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_979")
	_assert(String(snapshot.get("task_id", "")) == "TASK_979", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_978", "Snapshot links TASK_978")
	_assert(String(snapshot.get("status", "")) == "runtime_choice_buttons_ready", "Ready choice hook builds runtime buttons")
	_assert(String(snapshot.get("gate", "")) == "runtime_choice_buttons_ready", "Ready choice hook passes runtime button gate")
	_assert(bool(snapshot.get("active", false)), "Runtime choice buttons are active")
	_assert(int(snapshot.get("button_count", 0)) == 4, "Runtime choice buttons expose four buttons")
	_assert(String(snapshot.get("runtime_buttons_line", "")).contains("SECURE"), "Runtime line names SECURE")
	_assert(String(snapshot.get("runtime_buttons_line", "")).contains("RESET"), "Runtime line names RESET")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Runtime buttons recommend confirm smoke")
	_assert(_button_specs_are_read_only(specs), "Button specs remain read-only")
	_assert(_snapshot_is_read_only(snapshot), "Runtime buttons snapshot remains read-only")


func _test_button_slots_are_stable_and_go_separate() -> void:
	var snapshot: Dictionary = RuntimeButtons.build_snapshot(_choice_hook_source(), _hud_wiring_source())
	var specs: Array = Array(snapshot.get("button_specs", []))
	var expected_slots := ["CommandSlot08", "CommandSlot09", "CommandSlot10", "CommandSlot11"]
	var expected_tokens := ["SECURE", "PUSH", "FLANK", "RESET"]
	for i in range(expected_slots.size()):
		var spec := Dictionary(specs[i])
		_assert(String(spec.get("slot_name", "")) == expected_slots[i], "%s slot is stable" % expected_tokens[i])
		_assert(String(spec.get("button_text", "")) == expected_tokens[i], "%s button text is compact" % expected_tokens[i])
		_assert(String(spec.get("press_action", "")) == "confirm_release_first_decision_loop_two_player_loop_choice_button", "%s uses choice confirm action" % expected_tokens[i])
		_assert(bool(spec.get("separate_go_required", false)), "%s keeps GO separate" % expected_tokens[i])
		_assert(not bool(spec.get("auto_executes_go", true)), "%s does not auto-GO" % expected_tokens[i])


func _test_controller_exports_runtime_choice_buttons() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_runtime_choice_buttons_snapshot(_choice_hook_source(), _hud_wiring_source())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_979 schema matches")
	_assert(int(snapshot.get("button_count", 0)) == 4, "Controller TASK_979 has four buttons")
	_assert(String(snapshot.get("runtime_buttons_line", "")).contains("PUSH"), "Controller TASK_979 line names choices")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_979 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_runtime_choice_buttons"), "Command feedback embeds TASK_979")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_runtime_choice_buttons_line"), "Command feedback exports TASK_979 line")
	controller.queue_free()


func _test_runtime_choice_buttons_roundtrip() -> void:
	var snapshot: Dictionary = RuntimeButtons.build_snapshot(_choice_hook_source(), _hud_wiring_source())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_979 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_979", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_978", "Roundtrip keeps TASK_978 link")
	_assert(int(roundtrip.get("button_count", 0)) == 4, "Roundtrip keeps button count")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _choice_hook_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_978",
		"source_task_id": "TASK_977",
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


func _hud_wiring_source() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.release_first_decision_loop_two_player_loop_hud_wiring.v1",
		"task_id": "TASK_977",
		"status": "player_loop_hud_wiring_ready",
		"gate": "player_loop_hud_wiring_ready",
		"active": true,
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
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _button_specs_are_read_only(specs: Array) -> bool:
	if specs.size() != 4:
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
