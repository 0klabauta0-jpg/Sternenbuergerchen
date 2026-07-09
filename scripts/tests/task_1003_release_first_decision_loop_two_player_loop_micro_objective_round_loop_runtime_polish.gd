extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1003_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_playtest_slice.v1"
const NEXT_TASK := "TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1003 Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_good_source_builds_runtime_polish()
	_test_controller_exports_runtime_polish()
	_test_runtime_polish_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1003_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish: FAILED")
		quit(1)
		return
	print("TASK_1003_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1003 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1003 runtime polish service exists")
	_assert(task_text.contains("TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish"), "Task names TASK_1003")
	_assert(task_text.contains(NEXT_TASK), "Task names real-window capture follow-up")
	_assert(status_text.contains("TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish"), "Implementation status tracks TASK_1003")
	_assert(roadmap_text.contains("TASK_1003 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish (implementiert"), "Roadmap marks TASK_1003 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish (TASK_1003)"), "Mission feedback contract documents TASK_1003")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Runtime Polish (TASK_1003)"), "Decision clarity contract documents TASK_1003")
	_assert(service_text.contains(SCHEMA), "Runtime polish service exposes stable TASK_1003 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1003\""), "Runtime polish service writes TASK_1003 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1002\""), "Runtime polish service links TASK_1002")
	_assert(service_text.contains("\"round_loop_runtime_surface_specs\""), "Runtime polish exposes surface specs")
	_assert(service_text.contains("\"selected_fireteam_runtime_line\""), "Runtime polish exposes Selected Fireteam line")
	_assert(service_text.contains("\"mission_control_runtime_line\""), "Runtime polish exposes Mission Control line")
	_assert(service_text.contains("\"creates_command\": false"), "Runtime polish creates no command")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Runtime polish creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_RUNTIME_POLISH_SCRIPT"), "Controller preloads TASK_1003 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_snapshot"), "Controller exposes TASK_1003 snapshot")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_line"), "Command feedback exports TASK_1003 line")
	_assert(controller_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_surface_specs"), "Command feedback exports TASK_1003 surface specs")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1003")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_passed"), "Missing source reports source not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked runtime polish snapshot remains read-only")


func _test_good_source_builds_runtime_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_round_loop_slice())
	var specs: Array = Array(snapshot.get("round_loop_runtime_surface_specs", []))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1003")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1003", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1002", "Snapshot links TASK_1002")
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_loop_runtime_polish_ready", "Good source makes runtime polish ready")
	_assert(specs.size() >= 3, "Runtime polish has at least three surface specs")
	_assert(String(snapshot.get("selected_fireteam_runtime_line", "")).contains("ROUND"), "Selected Fireteam line names ROUND")
	_assert(String(snapshot.get("mission_control_runtime_line", "")).contains("NEXT"), "Mission Control line names NEXT")
	_assert(String(snapshot.get("command_feedback_runtime_line", "")).contains("GO separat"), "Command Feedback line names GO separation")
	_assert(not String(snapshot.get("mission_control_runtime_line", "")).contains("second_round_next_options_visible"), "Runtime line hides raw internal ids")
	_assert(bool(snapshot.get("runtime_lines_within_limit", false)), "Runtime lines fit HUD limit")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Runtime polish recommends real-window capture")
	_assert(_snapshot_is_read_only(snapshot), "Runtime polish remains read-only")


func _test_controller_exports_runtime_polish() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_snapshot(_source_round_loop_slice())
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1003 schema matches")
	_assert(String(snapshot.get("status", "")) == "micro_objective_round_loop_runtime_polish_ready", "Controller TASK_1003 ready with source")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1003 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish"), "Command feedback embeds TASK_1003")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_line"), "Command feedback exports TASK_1003 line")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_status"), "Command feedback exports TASK_1003 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish_surface_specs"), "Command feedback exports TASK_1003 specs")
	controller.queue_free()


func _test_runtime_polish_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_round_loop_slice())
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1003 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1003", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1002", "Roundtrip keeps TASK_1002 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_round_loop: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1003 service is loadable")
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
		_assert(false, "TASK_1003 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_round_loop)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1003 service returns dictionary")
	return {}


func _source_round_loop_slice() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1002",
		"source_task_id": "TASK_1001",
		"status": "micro_objective_round_loop_playtest_slice_passed",
		"gate": "micro_objective_round_loop_playtest_slice_passed",
		"micro_objective_round_loop_playtest_slice_passed": true,
		"completed_round_count": 2,
		"round_loop_line": "ROUND 1 FEEDBACK -> ROUND 2 NEXT -> CONFIRM -> GO -> FEEDBACK -> NEXT PASS (2 Runden)",
		"no_feedback_dead_end": true,
		"hud_surfaces_stable": true,
		"command_path_reused": true,
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
