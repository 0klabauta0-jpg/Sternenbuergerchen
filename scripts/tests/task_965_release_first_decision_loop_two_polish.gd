extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_965_release_first_decision_loop_two_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_polish.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_playtest.v1"
const NEXT_LOOP_SCHEMA := "sternenbuergerchen.release_first_decision_next_playable_loop.v1"
const NEXT_TASK := "TASK_966 - Release First Decision Loop Two Execution Hook"

var _passed: int = 0
var _failed: int = 0
var _service: Resource


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_965 Release First Decision Loop Two Polish ===")
	_service = ResourceLoader.load(SERVICE_PATH)
	_test_docs_and_static_hooks()
	_test_missing_playtest_blocks_polish()
	_test_passed_playtest_builds_second_decision_intents()
	_test_missing_choice_routes_to_review()
	await _test_controller_exports_loop_two_polish()
	_test_loop_two_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_965_release_first_decision_loop_two_polish: FAILED")
		quit(1)
		return
	print("TASK_965_release_first_decision_loop_two_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_965 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_965 polish service exists")
	_assert(task_text.contains("TASK_965 - Release First Decision Loop Two Polish"), "Task names TASK_965")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_966 follow-up")
	_assert(status_text.contains("TASK_965 - Release First Decision Loop Two Polish"), "Implementation status tracks TASK_965")
	_assert(roadmap_text.contains("TASK_965 - Release First Decision Loop Two Polish (implementiert"), "Roadmap marks TASK_965 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Polish (TASK_965)"), "Mission feedback contract documents TASK_965")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Polish (TASK_965)"), "Decision clarity contract documents TASK_965")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_POLISH_SCRIPT"), "Controller preloads TASK_965 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_polish_snapshot"), "Controller exposes TASK_965 snapshot")
	_assert(controller_text.contains("_build_release_first_decision_loop_two_polish_hud_line"), "Controller has TASK_965 HUD line helper")
	_assert(controller_text.contains("release_first_decision_loop_two_polish"), "Command feedback exports TASK_965")
	_assert(service_text.contains(SCHEMA), "Loop-two polish service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_965\""), "Loop-two polish service writes TASK_965 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_964\""), "Loop-two polish service links TASK_964")
	_assert(service_text.contains("NEXT_LOOP_TASK_ID: String = \"TASK_963\""), "Loop-two polish service links TASK_963")
	_assert(service_text.contains("NEXT_TASK"), "Loop-two polish service declares TASK_966")
	_assert(service_text.contains("\"read_only\": true"), "Loop-two polish service declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Loop-two polish service creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Loop-two polish service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Loop-two polish service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Loop-two polish service creates no multiplayer truth")


func _test_missing_playtest_blocks_polish() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", {}, _next_loop(), {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_964 source blocks TASK_965")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source schema is named")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source task is named")
	_assert(not bool(snapshot.get("active", true)), "Blocked loop-two polish is not active")
	_assert(_snapshot_is_read_only(snapshot), "Blocked loop-two polish remains read-only")


func _test_passed_playtest_builds_second_decision_intents() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _playtest(), _next_loop(), {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Loop-two polish schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_965", "Loop-two polish task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_964", "Loop-two polish links TASK_964")
	_assert(String(snapshot.get("next_loop_task_id", "")) == "TASK_963", "Loop-two polish links TASK_963")
	_assert(String(snapshot.get("gate", "")) == "loop_two_polish_passed", "Passed playtest passes TASK_965")
	_assert(String(snapshot.get("status", "")) == "ready_for_second_decision_execution_hook", "Passed polish is ready for execution hook")
	_assert(bool(snapshot.get("active", false)), "Loop-two polish is active")
	_assert(_intent_ids(Array(snapshot.get("second_decision_intents", []))) == ["hold_angle", "advance_cover", "fallback_regroup"], "Intent order stays stable")
	_assert(_command_types(Array(snapshot.get("second_decision_intents", []))) == ["defend", "move", "return"], "Intents map to commander command types")
	_assert(_intents_require_go(Array(snapshot.get("second_decision_intents", []))), "Every intent keeps GO boundary")
	_assert(String(snapshot.get("recommended_choice_id", "")) == "hold_angle", "Hold remains recommended choice")
	_assert(String(snapshot.get("compact_line", "")).contains("HOLD Defend"), "Compact line explains HOLD")
	_assert(String(snapshot.get("compact_line", "")).contains("ADV Move"), "Compact line explains ADV")
	_assert(String(snapshot.get("compact_line", "")).contains("BACK Return"), "Compact line explains BACK")
	_assert(not _visible_lines_contain_raw_choice_ids(snapshot), "Visible polish lines hide raw choice ids")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Polish recommends TASK_966")
	_assert(_snapshot_is_read_only(snapshot), "Passed loop-two polish remains read-only")


func _test_missing_choice_routes_to_review() -> void:
	if not _service_available():
		return
	var next_loop: Dictionary = _next_loop()
	var choices: Array = Array(next_loop.get("second_decision_choices", []))
	choices.remove_at(1)
	next_loop["second_decision_choices"] = choices
	next_loop["second_decision_choice_count"] = choices.size()
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _playtest(), next_loop, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "loop_two_polish_review", "Missing choice fails TASK_965 polish")
	_assert(blocker_ids.has("missing_advance_cover_choice"), "Missing advance choice is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_965 - Release First Decision Loop Two Polish", "Review loops on TASK_965")
	_assert(_snapshot_is_read_only(snapshot), "Review snapshot remains read-only")


func _test_controller_exports_loop_two_polish() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_release_first_decision_loop_two_polish_snapshot"), "Controller has TASK_965 public snapshot")
	if not controller.has_method("get_release_first_decision_loop_two_polish_snapshot"):
		controller.queue_free()
		return
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_polish_snapshot",
		_next_loop(),
		_playtest()
	))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_965 schema matches")
	_assert(String(snapshot.get("gate", "")) == "loop_two_polish_passed", "Controller TASK_965 gate passes")
	_assert(String(snapshot.get("selected_fireteam_line", "")).contains("HOLD Defend"), "Controller TASK_965 selected line is readable")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_965 remains read-only")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(command_feedback.get("release_first_decision_loop_two_polish", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_965")
	_assert(String(command_feedback.get("release_first_decision_loop_two_polish_line", "")).contains("HOLD Defend"), "Command feedback exports TASK_965 line")
	controller.queue_free()


func _test_loop_two_polish_roundtrip() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _playtest(), _next_loop(), {}))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_965 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_965", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_964", "Roundtrip keeps TASK_964 link")
	_assert(String(roundtrip.get("next_loop_task_id", "")) == "TASK_963", "Roundtrip keeps TASK_963 link")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _playtest() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_964",
		"source_task_id": "TASK_963",
		"gate": "loop_two_playtest_passed",
		"status": "visible_loop_two_ready",
		"active": true,
		"loop_line": "NEXT HIT LESEN / DEFEND -> HOLD / ADV / BACK | HOLD / ADV / BACK",
		"selected_fireteam_shows_loop_line": true,
		"mission_control_shows_loop_line": true,
		"command_feedback_exports_loop_line": true,
		"hold_advance_back_visible": true,
		"manual_acceptance_state_visible": true,
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


func _next_loop() -> Dictionary:
	return {
		"schema": NEXT_LOOP_SCHEMA,
		"task_id": "TASK_963",
		"source_task_id": "TASK_962",
		"status": "preview_available_needs_task_962_acceptance",
		"active": true,
		"manual_acceptance_required": true,
		"accepted_for_next_loop": false,
		"source_live_preview": true,
		"primary_line": "NEXT HIT LESEN / DEFEND -> HOLD / ADV / BACK",
		"why_line": "WHY FEUER | zweite Entscheidung statt Autopilot",
		"visible_loop_line": "NEXT HIT LESEN / DEFEND -> HOLD / ADV / BACK | HOLD / ADV / BACK",
		"recommended_choice_id": "hold_angle",
		"second_decision_choices": [
			{"choice_id": "hold_angle", "label": "HOLD Winkel halten", "command_hint": "Defend"},
			{"choice_id": "advance_cover", "label": "ADV gedeckt vor", "command_hint": "Move"},
			{"choice_id": "fallback_regroup", "label": "BACK neu sammeln", "command_hint": "Return/Move"},
		],
		"second_decision_choice_count": 3,
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


func _intent_ids(intents: Array) -> Array:
	var ids: Array = []
	for intent_variant in intents:
		ids.append(String(Dictionary(intent_variant).get("choice_id", "")))
	return ids


func _command_types(intents: Array) -> Array:
	var types: Array = []
	for intent_variant in intents:
		types.append(String(Dictionary(intent_variant).get("command_type", "")))
	return types


func _intents_require_go(intents: Array) -> bool:
	if intents.size() != 3:
		return false
	for intent_variant in intents:
		var intent: Dictionary = Dictionary(intent_variant)
		if String(intent.get("execution_boundary", "")) != "requires_go":
			return false
		if bool(intent.get("creates_command", true)) or bool(intent.get("creates_movement", true)):
			return false
	return true


func _visible_lines_contain_raw_choice_ids(snapshot: Dictionary) -> bool:
	var joined: String = "%s\n%s\n%s" % [
		String(snapshot.get("compact_line", "")),
		String(snapshot.get("selected_fireteam_line", "")),
		String(snapshot.get("mission_control_line", "")),
	]
	return joined.contains("hold_angle") or joined.contains("advance_cover") or joined.contains("fallback_regroup")


func _service_available() -> bool:
	if _service != null:
		return true
	_assert(false, "TASK_965 service can be loaded")
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
