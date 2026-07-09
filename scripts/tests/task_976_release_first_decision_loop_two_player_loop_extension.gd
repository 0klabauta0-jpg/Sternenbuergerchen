extends SceneTree

const Extension := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_extension.gd")

const TASK_PATH := "res://docs/tasks/TASK_976_release_first_decision_loop_two_player_loop_extension.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_extension.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_extension_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_extension.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_acceptance_slice.v1"
const NEXT_TASK := "TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_976 Release First Decision Loop Two Player Loop Extension ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_unpassed_acceptance_blocks()
	_test_passed_acceptance_builds_next_player_loop()
	_test_context_can_recommend_push_objective()
	_test_extension_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_976_release_first_decision_loop_two_player_loop_extension: FAILED")
		quit(1)
		return
	print("TASK_976_release_first_decision_loop_two_player_loop_extension: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_976 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_976 extension service exists")
	_assert(task_text.contains("TASK_976 - Release First Decision Loop Two Player Loop Extension"), "Task names TASK_976")
	_assert(task_text.contains(NEXT_TASK), "Task names HUD wiring follow-up")
	_assert(status_text.contains("TASK_976 - Release First Decision Loop Two Player Loop Extension"), "Implementation status tracks TASK_976")
	_assert(roadmap_text.contains("TASK_976 - Release First Decision Loop Two Player Loop Extension (implementiert"), "Roadmap marks TASK_976 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Extension (TASK_976)"), "Mission feedback contract documents TASK_976")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Extension (TASK_976)"), "Decision clarity contract documents TASK_976")
	_assert(service_text.contains(SCHEMA), "Extension service exposes stable TASK_976 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_976\""), "Extension service writes TASK_976 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_975\""), "Extension service links TASK_975")
	_assert(service_text.contains("\"secure_area\""), "Extension service exposes secure choice")
	_assert(service_text.contains("\"push_objective\""), "Extension service exposes push choice")
	_assert(service_text.contains("\"flank_pressure\""), "Extension service exposes flank choice")
	_assert(service_text.contains("\"reset_spacing\""), "Extension service exposes reset choice")
	_assert(service_text.contains("\"read_only\": true"), "Extension service declares read-only")
	_assert(service_text.contains("\"creates_command\": false"), "Extension service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Extension service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Extension service creates no multiplayer truth")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Extension.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_976")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_acceptance_not_passed"), "Missing source reports acceptance not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_unpassed_acceptance_blocks() -> void:
	var source: Dictionary = _accepted_source()
	source["status"] = "needs_acceptance_slice_trace"
	source["gate"] = "needs_loop_two_acceptance_slice_trace"
	source["acceptance_slice_passed"] = false
	var snapshot: Dictionary = Extension.build_snapshot(source, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Unpassed acceptance blocks TASK_976")
	_assert(blocker_ids.has("source_acceptance_not_passed"), "Unpassed source reports acceptance not passed")
	_assert(_snapshot_is_read_only(snapshot), "Unpassed snapshot remains read-only")


func _test_passed_acceptance_builds_next_player_loop() -> void:
	var snapshot: Dictionary = Extension.build_snapshot(_accepted_source(), _default_context())
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_976")
	_assert(String(snapshot.get("task_id", "")) == "TASK_976", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_975", "Snapshot links TASK_975")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_975 schema")
	_assert(String(snapshot.get("status", "")) == "ready_for_player_loop_extension", "Passed acceptance builds player loop")
	_assert(bool(snapshot.get("active", false)), "Player loop extension is active")
	_assert(int(snapshot.get("next_choice_count", 0)) == 4, "Player loop exposes four choices")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("SECURE"), "Visible loop line names SECURE")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("PUSH"), "Visible loop line names PUSH")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("FLANK"), "Visible loop line names FLANK")
	_assert(String(snapshot.get("visible_loop_line", "")).contains("RESET"), "Visible loop line names RESET")
	_assert(String(snapshot.get("recommended_choice_id", "")) == "secure_area", "Default recommendation secures area")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends HUD wiring")
	_assert(_choices_are_read_only(Array(snapshot.get("next_player_choices", []))), "Choices remain read-only")
	_assert(_snapshot_is_read_only(snapshot), "Extension snapshot remains read-only")


func _test_context_can_recommend_push_objective() -> void:
	var context: Dictionary = _default_context()
	context["objective_pressure"] = "high"
	context["known_contact_pressure"] = "medium"
	var snapshot: Dictionary = Extension.build_snapshot(_accepted_source(), context)
	_assert(String(snapshot.get("recommended_choice_id", "")) == "push_objective", "Objective pressure can recommend push")
	_assert(String(snapshot.get("why_line", "")).contains("OBJ"), "Why line names objective pressure")
	_assert(_snapshot_is_read_only(snapshot), "Context snapshot remains read-only")


func _test_extension_roundtrip() -> void:
	var snapshot: Dictionary = Extension.build_snapshot(_accepted_source(), _default_context())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_976 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_976", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_975", "Roundtrip keeps TASK_975 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _accepted_source() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_975",
		"source_task_id": "TASK_974",
		"status": "loop_two_acceptance_slice_passed",
		"gate": "loop_two_acceptance_slice_passed",
		"acceptance_slice_passed": true,
		"acceptance_line": "2ND -> GO -> Feedback PASS | 2ND HOLD -> Defend vorbereiten | danach GO separat",
		"answered_player_question_count": 5,
		"recommended_next_task": "TASK_976 - Release First Decision Loop Two Player Loop Extension",
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


func _default_context() -> Dictionary:
	return {
		"objective_pressure": "medium",
		"known_contact_pressure": "medium",
		"team_condition": "stable",
		"ammo_pressure": "low",
	}


func _choices_are_read_only(choices: Array) -> bool:
	if choices.is_empty():
		return false
	for choice_variant in choices:
		if typeof(choice_variant) != TYPE_DICTIONARY:
			return false
		var choice := Dictionary(choice_variant)
		if not bool(choice.get("read_only", false)):
			return false
		if bool(choice.get("creates_command", true)):
			return false
		if bool(choice.get("creates_movement", true)):
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
