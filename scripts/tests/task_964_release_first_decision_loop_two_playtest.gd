extends SceneTree

const TASK_PATH := "res://docs/tasks/TASK_964_release_first_decision_loop_two_playtest.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_playtest.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_playtest_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_playtest.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_next_playable_loop.v1"
const NEXT_TASK := "TASK_965 - Release First Decision Loop Two Polish"

var _passed: int = 0
var _failed: int = 0
var _service: Resource


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_964 Release First Decision Loop Two Playtest ===")
	_service = ResourceLoader.load(SERVICE_PATH)
	_test_docs_and_static_hooks()
	_test_missing_next_loop_blocks_playtest()
	_test_visible_surfaces_pass_loop_two_playtest()
	_test_missing_mission_control_routes_to_polish()
	await _test_controller_exports_loop_two_playtest()
	_test_loop_two_playtest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_964_release_first_decision_loop_two_playtest: FAILED")
		quit(1)
		return
	print("TASK_964_release_first_decision_loop_two_playtest: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_964 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_964 loop-two playtest service exists")
	_assert(task_text.contains("TASK_964 - Release First Decision Loop Two Playtest"), "Task names TASK_964")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_965 follow-up")
	_assert(status_text.contains("TASK_964 - Release First Decision Loop Two Playtest"), "Implementation status tracks TASK_964")
	_assert(roadmap_text.contains("TASK_964 - Release First Decision Loop Two Playtest (implementiert"), "Roadmap marks TASK_964 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Playtest (TASK_964)"), "Mission feedback contract documents TASK_964")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Playtest (TASK_964)"), "Decision clarity contract documents TASK_964")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYTEST_SCRIPT"), "Controller preloads TASK_964 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_playtest_snapshot"), "Controller exposes TASK_964 snapshot")
	_assert(controller_text.contains("_build_release_first_decision_loop_two_hud_line"), "Controller has dedicated HUD line helper")
	_assert(controller_text.contains("release_first_decision_loop_two_playtest"), "Command feedback exports TASK_964")
	_assert(service_text.contains(SCHEMA), "Loop-two playtest service exposes stable schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_964\""), "Loop-two playtest service writes TASK_964 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_963\""), "Loop-two playtest service links TASK_963")
	_assert(service_text.contains("NEXT_TASK"), "Loop-two playtest service declares TASK_965")
	_assert(service_text.contains("\"read_only\": true"), "Loop-two playtest service declares read-only")
	_assert(service_text.contains("\"ui_sets_gameplay_truth\": false"), "Loop-two playtest service creates no UI gameplay truth")
	_assert(service_text.contains("\"creates_command\": false"), "Loop-two playtest service creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Loop-two playtest service creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Loop-two playtest service creates no multiplayer truth")


func _test_missing_next_loop_blocks_playtest() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", {}, _surfaces(_loop_line()), {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_963 source blocks TASK_964")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source schema is named")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source task is named")
	_assert(not bool(snapshot.get("active", true)), "Blocked loop-two playtest is not active")
	_assert(_snapshot_is_read_only(snapshot), "Blocked loop-two playtest remains read-only")


func _test_visible_surfaces_pass_loop_two_playtest() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _next_loop(), _surfaces(_loop_line()), {}))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Loop-two playtest schema matches")
	_assert(String(snapshot.get("task_id", "")) == "TASK_964", "Loop-two playtest task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_963", "Loop-two playtest links TASK_963")
	_assert(String(snapshot.get("status", "")) == "visible_loop_two_ready", "Visible surfaces pass loop-two playtest")
	_assert(String(snapshot.get("gate", "")) == "loop_two_playtest_passed", "Loop-two gate passes")
	_assert(bool(snapshot.get("active", false)), "Loop-two playtest is active")
	_assert(bool(snapshot.get("selected_fireteam_shows_loop_line", false)), "Selected fireteam surface shows TASK_963 line")
	_assert(bool(snapshot.get("mission_control_shows_loop_line", false)), "Mission control surface shows TASK_963 line")
	_assert(bool(snapshot.get("command_feedback_exports_loop_line", false)), "Command feedback exports TASK_963 line")
	_assert(bool(snapshot.get("hold_advance_back_visible", false)), "HOLD/ADV/BACK are visible")
	_assert(bool(snapshot.get("manual_acceptance_state_visible", false)), "Manual/live acceptance state is visible")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Playtest recommends TASK_965 polish")
	_assert(_snapshot_is_read_only(snapshot), "Passed loop-two playtest remains read-only")


func _test_missing_mission_control_routes_to_polish() -> void:
	if not _service_available():
		return
	var surfaces: Dictionary = _surfaces(_loop_line())
	surfaces["mission_control_status_text"] = "LZ offen\nKampf sauber, aber keine zweite Entscheidung."
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _next_loop(), surfaces, {}))
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("gate", "")) == "loop_two_playtest_regression_found", "Missing mission control line fails playtest")
	_assert(blocker_ids.has("mission_control_missing_loop_line"), "Missing mission control surface is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Regression routes to TASK_965")
	_assert(_snapshot_is_read_only(snapshot), "Regression snapshot remains read-only")


func _test_controller_exports_loop_two_playtest() -> void:
	var controller_script: Resource = load(CONTROLLER_PATH)
	if controller_script == null:
		_assert(false, "Controller script can be loaded")
		return
	var controller: Node = controller_script.new()
	get_root().add_child(controller)
	await process_frame
	_assert(controller.has_method("get_release_first_decision_loop_two_playtest_snapshot"), "Controller has TASK_964 public snapshot")
	if not controller.has_method("get_release_first_decision_loop_two_playtest_snapshot"):
		controller.queue_free()
		return
	var next_loop: Dictionary = _next_loop()
	var feedback_override: Dictionary = {
		"release_first_decision_next_loop_line": _loop_line(),
		"release_first_decision_next_loop_status": String(next_loop.get("status", "")),
	}
	var snapshot: Dictionary = Dictionary(controller.call(
		"get_release_first_decision_loop_two_playtest_snapshot",
		next_loop,
		"FT1\n%s" % _loop_line(),
		"Mission\n%s" % _loop_line(),
		feedback_override
	))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_964 schema matches")
	_assert(String(snapshot.get("gate", "")) == "loop_two_playtest_passed", "Controller TASK_964 gate passes with visible surfaces")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_964 remains read-only")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(Dictionary(command_feedback.get("release_first_decision_loop_two_playtest", {})).get("schema", "")) == SCHEMA, "Command feedback embeds TASK_964")
	_assert(String(command_feedback.get("release_first_decision_loop_two_gate", "")).strip_edges().contains("loop_two"), "Command feedback exports TASK_964 gate")
	controller.queue_free()


func _test_loop_two_playtest_roundtrip() -> void:
	if not _service_available():
		return
	var snapshot: Dictionary = Dictionary(_service.call("build_snapshot", _next_loop(), _surfaces(_loop_line()), {}))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_964 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_964", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_963", "Roundtrip keeps TASK_963 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _next_loop() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_963",
		"source_task_id": "TASK_962",
		"status": "preview_available_needs_task_962_acceptance",
		"active": true,
		"manual_acceptance_required": true,
		"accepted_for_next_loop": false,
		"source_live_preview": true,
		"primary_line": "NEXT HIT LESEN / DEFEND -> HOLD / ADV / BACK",
		"why_line": "WHY FEUER | zweite Entscheidung statt Autopilot",
		"visible_loop_line": _loop_line(),
		"second_decision_choices": [
			{"choice_id": "hold_angle", "label": "HOLD Winkel halten"},
			{"choice_id": "advance_cover", "label": "ADV gedeckt vor"},
			{"choice_id": "fallback_regroup", "label": "BACK neu sammeln"},
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


func _surfaces(loop_line: String) -> Dictionary:
	return {
		"selected_fireteam_status_text": "FT1 | Karten 4\n%s\nBefehl Defend" % loop_line,
		"mission_control_status_text": "LZ offen\n%s\nKampf Kontakt" % loop_line,
		"command_feedback_line": loop_line,
		"command_feedback_status": "preview_available_needs_task_962_acceptance",
	}


func _loop_line() -> String:
	return "NEXT HIT LESEN / DEFEND -> HOLD / ADV / BACK | HOLD / ADV / BACK"


func _service_available() -> bool:
	if _service != null:
		return true
	_assert(false, "TASK_964 service can be loaded")
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
