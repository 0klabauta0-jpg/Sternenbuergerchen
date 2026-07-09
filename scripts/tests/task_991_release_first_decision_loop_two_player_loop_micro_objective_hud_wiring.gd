extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_next_micro_objective.v1"
const NEXT_TASK := "TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_991 Release First Decision Loop Two Player Loop Micro Objective HUD Wiring ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_not_ready_source_blocks()
	_test_ready_source_builds_hud_wiring()
	_test_context_can_focus_valid_micro_objective()
	_test_controller_exports_micro_objective_hud_wiring()
	_test_micro_objective_hud_wiring_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring: FAILED")
		quit(1)
		return
	print("TASK_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_991 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_991 HUD wiring service exists")
	_assert(task_text.contains("TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring"), "Task names TASK_991")
	_assert(task_text.contains(NEXT_TASK), "Task names choice-hook follow-up")
	_assert(status_text.contains("TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring"), "Implementation status tracks TASK_991")
	_assert(roadmap_text.contains("TASK_991 - Release First Decision Loop Two Player Loop Micro Objective HUD Wiring (implementiert"), "Roadmap marks TASK_991 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective HUD Wiring (TASK_991)"), "Mission feedback contract documents TASK_991")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective HUD Wiring (TASK_991)"), "Decision clarity contract documents TASK_991")
	_assert(service_text.contains(SCHEMA), "HUD wiring service exposes stable TASK_991 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_991\""), "HUD wiring service writes TASK_991 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_990\""), "HUD wiring service links TASK_990")
	_assert(service_text.contains("\"hud_micro_objective_chips\""), "HUD wiring exposes objective chips")
	_assert(service_text.contains("\"selected_fireteam_line\""), "HUD wiring exposes selected-fireteam line")
	_assert(service_text.contains("\"mission_control_line\""), "HUD wiring exposes mission-control line")
	_assert(service_text.contains("\"command_feedback_line\""), "HUD wiring exposes command-feedback line")
	_assert(service_text.contains("\"requires_existing_go_path\": true"), "HUD wiring keeps GO boundary")
	_assert(service_text.contains("\"creates_command\": false"), "HUD wiring creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "HUD wiring creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_HUD_WIRING_SCRIPT"), "Controller preloads TASK_991 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_snapshot"), "Controller exposes TASK_991 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_line"), "Command feedback exports TASK_991 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_chips"), "Command feedback exports TASK_991 chips")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_991")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked HUD wiring snapshot remains read-only")


func _test_not_ready_source_blocks() -> void:
	var source: Dictionary = _source_next_micro_objective()
	source["status"] = "blocked"
	source["active"] = false
	var snapshot: Dictionary = _build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Not-ready source blocks TASK_991")
	_assert(blocker_ids.has("source_not_ready"), "Not-ready source reports source not ready")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_990 - Release First Decision Loop Two Player Loop Next Micro Objective", "Not-ready source routes back to TASK_990")
	_assert(_snapshot_is_read_only(snapshot), "Not-ready source snapshot remains read-only")


func _test_ready_source_builds_hud_wiring() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_next_micro_objective(), {})
	var chips: Array = Array(snapshot.get("hud_micro_objective_chips", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_991")
	_assert(String(snapshot.get("task_id", "")) == "TASK_991", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_990", "Snapshot links TASK_990")
	_assert(String(snapshot.get("status", "")) == "micro_objective_hud_wiring_ready", "Ready source builds HUD wiring")
	_assert(String(snapshot.get("gate", "")) == "micro_objective_hud_wiring_ready", "Gate marks HUD wiring ready")
	_assert(bool(snapshot.get("hud_wiring_ready", false)), "HUD wiring ready flag is set")
	_assert(int(snapshot.get("hud_micro_objective_chip_count", 0)) == 3, "Three HUD chips exist")
	_assert(String(snapshot.get("focused_micro_objective_id", "")) == "secure_gained_ground", "Default focus follows recommendation")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("SICHERN"), "Selected-fireteam line names secure objective")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("GO separat"), "Selected-fireteam line keeps GO boundary")
	_assert(String(snapshot.get("mission_control_line", "")).contains("SICHERN"), "Mission-control line names recommendation")
	_assert(String(snapshot.get("command_feedback_line", "")).contains("MICRO OBJ"), "Command-feedback line is compact")
	_assert(_hud_chips_are_readable(chips), "HUD chips are readable and read-only")
	_assert(_has_focused_chip(chips, "secure_gained_ground"), "Recommended chip is focused")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Ready HUD wiring recommends choice hook")
	_assert(_snapshot_is_read_only(snapshot), "Ready HUD wiring remains read-only")


func _test_context_can_focus_valid_micro_objective() -> void:
	var context := {
		"focused_objective_id": "press_next_contact",
	}
	var snapshot: Dictionary = _build_snapshot(_source_next_micro_objective(), context)
	var chips: Array = Array(snapshot.get("hud_micro_objective_chips", []))
	_assert(String(snapshot.get("focused_micro_objective_id", "")) == "press_next_contact", "Context can focus pressure objective")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("DRUECKEN"), "Focused selected-fireteam line names pressure objective")
	_assert(_has_focused_chip(chips, "press_next_contact"), "Pressure chip is focused")
	_assert(_snapshot_is_read_only(snapshot), "Focused HUD wiring remains read-only")


func _test_controller_exports_micro_objective_hud_wiring() -> void:
	var controller := ControllerScript.new()
	if not controller.has_method("get_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_snapshot"):
		_assert(false, "Controller exposes TASK_991 method")
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_snapshot",
		_source_next_micro_objective(),
		{}
	))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_991 schema matches")
	_assert(String(snapshot.get("status", "")) == "micro_objective_hud_wiring_ready", "Controller TASK_991 can become ready")
	_assert(String(snapshot.get("command_feedback_line", "")).contains("MICRO OBJ"), "Controller TASK_991 line names micro objective")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_991 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_hud_wiring"), "Command feedback embeds TASK_991")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_line"), "Command feedback exports TASK_991 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_status"), "Command feedback exports TASK_991 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_hud_wiring_chips"), "Command feedback exports TASK_991 chips")
	controller.queue_free()


func _test_micro_objective_hud_wiring_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_next_micro_objective(), {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_991 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_991", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_990", "Roundtrip keeps TASK_990 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_next_micro_objective: Dictionary, context: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_991 service is loadable")
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
		_assert(false, "TASK_991 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_next_micro_objective, context)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_991 service returns dictionary")
	return {}


func _source_next_micro_objective() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_990",
		"source_task_id": "TASK_989",
		"status": "next_micro_objective_ready",
		"gate": "next_micro_objective_ready",
		"active": true,
		"micro_objective_cards": [
			_micro_objective_card("secure_gained_ground", "SICHERN", "defend"),
			_micro_objective_card("press_next_contact", "DRUECKEN", "move"),
			_micro_objective_card("regroup_fireteam", "SAMMELN", "hold"),
		],
		"micro_objective_card_count": 3,
		"recommended_micro_objective_id": "secure_gained_ground",
		"recommended_micro_objective": _micro_objective_card("secure_gained_ground", "SICHERN", "defend"),
		"next_micro_objective_line": "NEXT OBJ SICHERN: OBJ SICHERN: Zielstand halten, Winkel ordnen, Kontaktlage lesen. | GO separat",
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


func _micro_objective_card(objective_id: String, label: String, command_intent: String) -> Dictionary:
	return {
		"objective_id": objective_id,
		"label": label,
		"command_intent": command_intent,
		"player_line": "OBJ %s: Zielzustand lesen und naechsten Griff vorbereiten." % label,
		"why_line": "%s erklaert dem Spieler den naechsten kleinen Schritt." % label,
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


func _hud_chips_are_readable(chips: Array) -> bool:
	if chips.size() != 3:
		return false
	for chip_variant in chips:
		var chip := Dictionary(chip_variant)
		if String(chip.get("chip_id", "")).is_empty():
			return false
		if String(chip.get("objective_id", "")).is_empty():
			return false
		if String(chip.get("label", "")).is_empty():
			return false
		if String(chip.get("display_text", "")).is_empty():
			return false
		if String(chip.get("tooltip_text", "")).is_empty():
			return false
		if not bool(chip.get("requires_existing_go_path", false)):
			return false
		if bool(chip.get("creates_command", true)):
			return false
	return true


func _has_focused_chip(chips: Array, objective_id: String) -> bool:
	for chip_variant in chips:
		var chip := Dictionary(chip_variant)
		if String(chip.get("objective_id", "")) == objective_id:
			return bool(chip.get("focused", false))
	return false


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
