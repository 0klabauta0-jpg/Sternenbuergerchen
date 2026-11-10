extends SceneTree

const HudWiring := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_hud_wiring.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_977_release_first_decision_loop_two_player_loop_hud_wiring.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_hud_wiring.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_hud_wiring_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_hud_wiring.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_extension.v1"
const NEXT_TASK := "TASK_978 - Release First Decision Loop Two Player Loop Choice Hook"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_977 Release First Decision Loop Two Player Loop HUD Wiring ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_active_extension_builds_hud_lines()
	_test_surface_visibility_flags()
	_test_controller_exports_hud_wiring()
	_test_hud_wiring_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_977_release_first_decision_loop_two_player_loop_hud_wiring: FAILED")
		quit(1)
		return
	print("TASK_977_release_first_decision_loop_two_player_loop_hud_wiring: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_977 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_977 HUD wiring service exists")
	_assert(task_text.contains("TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring"), "Task names TASK_977")
	_assert(task_text.contains(NEXT_TASK), "Task names choice hook follow-up")
	_assert(status_text.contains("TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring"), "Implementation status tracks TASK_977")
	_assert(roadmap_text.contains("TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring (implementiert"), "Roadmap marks TASK_977 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop HUD Wiring (TASK_977)"), "Mission feedback contract documents TASK_977")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop HUD Wiring (TASK_977)"), "Decision clarity contract documents TASK_977")
	_assert(service_text.contains(SCHEMA), "HUD wiring service exposes stable TASK_977 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_977\""), "HUD wiring service writes TASK_977 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_976\""), "HUD wiring service links TASK_976")
	_assert(service_text.contains("\"selected_fireteam_line\""), "HUD wiring exposes selected-fireteam line")
	_assert(service_text.contains("\"mission_control_line\""), "HUD wiring exposes mission-control line")
	_assert(service_text.contains("\"command_feedback_line\""), "HUD wiring exposes command-feedback line")
	_assert(service_text.contains("\"hud_choice_chips\""), "HUD wiring exposes choice chips")
	_assert(service_text.contains("\"read_only\": true"), "HUD wiring declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "HUD wiring creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "HUD wiring creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "HUD wiring creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_EXTENSION_SCRIPT"), "Controller preloads TASK_976 service")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_HUD_WIRING_SCRIPT"), "Controller preloads TASK_977 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_extension_snapshot"), "Controller exposes TASK_976 snapshot")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_hud_wiring_snapshot"), "Controller exposes TASK_977 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_hud_wiring_line"), "Command feedback exports TASK_977 line")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = HudWiring.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_977")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_active"), "Missing source reports inactive player loop")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_active_extension_builds_hud_lines() -> void:
	var snapshot: Dictionary = HudWiring.build_snapshot(_extension_source(), {})
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_977")
	_assert(String(snapshot.get("task_id", "")) == "TASK_977", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_976", "Snapshot links TASK_976")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_976 schema")
	_assert(String(snapshot.get("status", "")) == "player_loop_hud_wiring_ready", "Active extension builds HUD wiring")
	_assert(String(snapshot.get("gate", "")) == "player_loop_hud_wiring_ready", "Active extension passes HUD wiring gate")
	_assert(bool(snapshot.get("active", false)), "HUD wiring is active")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("NEXT"), "Selected line contains NEXT")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("SECURE"), "Selected line contains SECURE")
	_assert(String(snapshot.get("mission_control_line", "")).contains("WHY"), "Mission Control line contains WHY")
	_assert(String(snapshot.get("command_feedback_line", "")).contains("SECURE"), "Command feedback line contains SECURE")
	_assert(String(snapshot.get("choice_chip_line", "")).contains("PUSH"), "Choice chip line contains PUSH")
	_assert(int(snapshot.get("hud_choice_chip_count", 0)) == 4, "HUD wiring exposes four choice chips")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "HUD wiring recommends choice hook")
	_assert(_chips_are_read_only(Array(snapshot.get("hud_choice_chips", []))), "Choice chips remain read-only")
	_assert(_snapshot_is_read_only(snapshot), "HUD wiring snapshot remains read-only")


func _test_surface_visibility_flags() -> void:
	var source: Dictionary = _extension_source()
	var surfaces: Dictionary = {
		"selected_fireteam_status_text": String(source.get("primary_line", "")),
		"mission_control_status_text": String(source.get("why_line", "")),
		"command_feedback_text": String(source.get("visible_loop_line", "")),
	}
	var snapshot: Dictionary = HudWiring.build_snapshot(source, surfaces)
	_assert(bool(snapshot.get("selected_fireteam_shows_player_loop", false)), "Selected surface shows player loop")
	_assert(bool(snapshot.get("mission_control_shows_player_loop", false)), "Mission Control surface shows player loop")
	_assert(bool(snapshot.get("command_feedback_exports_player_loop", false)), "Command feedback exports player loop")
	_assert(_snapshot_is_read_only(snapshot), "Surface visibility snapshot remains read-only")


func _test_controller_exports_hud_wiring() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_hud_wiring_snapshot(_extension_source(), {})
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_977 schema matches")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("SECURE"), "Controller TASK_977 selected line names choices")
	_assert(String(snapshot.get("command_feedback_line", "")).contains("RESET"), "Controller TASK_977 command line names reset")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_977 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_hud_wiring"), "Command feedback embeds TASK_977")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_hud_wiring_line"), "Command feedback exports TASK_977 line")
	controller.queue_free()


func _test_hud_wiring_roundtrip() -> void:
	var snapshot: Dictionary = HudWiring.build_snapshot(_extension_source(), {})
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_977 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_977", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_976", "Roundtrip keeps TASK_976 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _extension_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_976",
		"source_task_id": "TASK_975",
		"source_schema": "sternenbuergerchen.release_first_decision_loop_two_acceptance_slice.v1",
		"status": "ready_for_player_loop_extension",
		"active": true,
		"primary_line": "NEXT SECURE -> SECURE / PUSH / FLANK / RESET",
		"why_line": "WHY SECURE | OBJ MEDIUM | CONTACT MEDIUM | nach 2ND wieder echte Wahl",
		"visible_loop_line": "NEXT SECURE -> SECURE / PUSH / FLANK / RESET | SECURE / PUSH / FLANK / RESET",
		"next_player_choices": [
			_choice("secure_area", "SECURE Bereich sichern", "Defend", "stabil"),
			_choice("push_objective", "PUSH Ziel druecken", "Move/Take", "riskant"),
			_choice("flank_pressure", "FLANK Druck drehen", "Flank", "hoch"),
			_choice("reset_spacing", "RESET neu sammeln", "Move/Defend", "vorsichtig"),
		],
		"next_choice_count": 4,
		"recommended_choice_id": "secure_area",
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


func _choice(choice_id: String, label: String, command_hint: String, risk_label: String) -> Dictionary:
	return {
		"choice_id": choice_id,
		"label": label,
		"command_hint": command_hint,
		"risk_label": risk_label,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_movement": false,
	}


func _chips_are_read_only(chips: Array) -> bool:
	if chips.is_empty():
		return false
	for chip_variant in chips:
		if typeof(chip_variant) != TYPE_DICTIONARY:
			return false
		var chip := Dictionary(chip_variant)
		if not bool(chip.get("read_only", false)):
			return false
		if bool(chip.get("creates_command", true)):
			return false
		if bool(chip.get("creates_movement", true)):
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
