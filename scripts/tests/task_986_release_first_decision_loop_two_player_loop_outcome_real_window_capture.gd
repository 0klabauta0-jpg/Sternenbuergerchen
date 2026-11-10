extends SceneTree

const RealWindowCapture := preload("res://scripts/mission/release_first_decision_loop_two_player_loop_outcome_real_window_capture.gd")
const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_outcome_real_window_capture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_decision_loop_two_player_loop_outcome_real_window.ps1"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_outcome_real_window_capture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_outcome_real_window_capture.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_scenario_outcome_slice.v1"
const NEXT_TASK := "TASK_987 - Release First Decision Loop Two Player Loop Outcome Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_986 Release First Decision Loop Two Player Loop Outcome Real Window Capture ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_outcome_without_manifest_needs_capture()
	_test_good_manifest_is_review_ready()
	_test_completed_manual_checks_accept()
	_test_controller_exports_outcome_real_window_capture()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture: FAILED")
		quit(1)
		return
	print("TASK_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var feedback_source_text: String = _read_text("res://scripts/mission/diagnostics/mission_command_feedback_diagnostics.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_986 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_986 real-window analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_986 real-window capture tool exists")
	_assert(task_text.contains("TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture"), "Task names TASK_986")
	_assert(task_text.contains(NEXT_TASK), "Task names visual findings follow-up")
	_assert(status_text.contains("TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture"), "Implementation status tracks TASK_986")
	_assert(roadmap_text.contains("TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture (implementiert"), "Roadmap marks TASK_986 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Outcome Real Window Capture (TASK_986)"), "Mission feedback contract documents TASK_986")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Outcome Real Window Capture (TASK_986)"), "Decision clarity contract documents TASK_986")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_986 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_986\""), "Analyzer writes TASK_986 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_985\""), "Analyzer links TASK_985")
	_assert(service_text.contains("REQUIRED_CAPTURE_CHECKS"), "Analyzer defines required checks")
	_assert(service_text.contains("\"read_only_capture\": true"), "Analyzer declares read-only capture")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")
	_assert(tool_text.contains("release_first_decision_loop_two_player_loop_outcome_real_window_capture.json"), "Capture tool writes TASK_986 manifest")
	_assert(tool_text.contains("--release-singleplayer-lz-drop-preview"), "Capture tool uses release first decision deep-link")
	_assert(tool_text.contains("outcome_line_visible"), "Capture tool requires outcome line")
	_assert(tool_text.contains("mini_objective_state_visible"), "Capture tool requires mini objective")
	_assert(tool_text.contains("manual_review_done = $false"), "Capture tool does not auto-pass manual review")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Capture tool updates no shortcuts")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_OUTCOME_REAL_WINDOW_CAPTURE_SCRIPT"), "Controller preloads TASK_986 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_outcome_real_window_capture_snapshot"), "Controller exposes TASK_986 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_outcome_real_window_capture_status"), "Command feedback exports TASK_986 status")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = RealWindowCapture.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_986")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_outcome_not_ready"), "Missing source reports outcome not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_ready_outcome_without_manifest_needs_capture() -> void:
	var snapshot: Dictionary = RealWindowCapture.build_snapshot(_scenario_outcome(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_outcome_real_window_capture", "Ready outcome without manifest needs capture")
	_assert(String(snapshot.get("gate", "")) == "needs_outcome_real_window_capture_run", "Missing manifest gates capture run")
	_assert(issue_ids.has("outcome_real_window_capture_manifest_missing"), "Missing manifest is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture", "Missing manifest loops on TASK_986")
	_assert(_snapshot_is_read_only(snapshot), "Needs-run snapshot remains read-only")


func _test_good_manifest_is_review_ready() -> void:
	var snapshot: Dictionary = RealWindowCapture.build_snapshot(_scenario_outcome(), _good_manifest(false))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_986")
	_assert(String(snapshot.get("task_id", "")) == "TASK_986", "Snapshot task id matches TASK_986")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_985", "Snapshot links TASK_985")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_985 schema")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Good manifest is review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot marks review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Snapshot does not auto-accept")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) > 0, "Manual checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_987")
	_assert(_snapshot_is_read_only(snapshot), "Good snapshot remains read-only")


func _test_completed_manual_checks_accept() -> void:
	var snapshot: Dictionary = RealWindowCapture.build_snapshot(_scenario_outcome(), _good_manifest(true))
	_assert(String(snapshot.get("status", "")) == "accepted", "Completed manual checks accept TASK_986")
	_assert(bool(snapshot.get("accepted", false)), "Accepted snapshot sets accepted flag")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) == 0, "No manual checks missing")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Accepted snapshot has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Accepted snapshot has no issues")


func _test_controller_exports_outcome_real_window_capture() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_outcome_real_window_capture_snapshot(_scenario_outcome(), _good_manifest(false))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_986 schema matches")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Controller TASK_986 can become review-ready")
	_assert(String(snapshot.get("source_outcome_line", "")).contains("PUSH"), "Controller TASK_986 source line names PUSH")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_986 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_outcome_real_window_capture"), "Command feedback embeds TASK_986")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_outcome_real_window_capture_status"), "Command feedback exports TASK_986 status")
	controller.queue_free()


func _test_manifest_roundtrip() -> void:
	var snapshot: Dictionary = RealWindowCapture.build_snapshot(_scenario_outcome(), _good_manifest(false))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_986 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_986", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_985", "Roundtrip keeps TASK_985 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _scenario_outcome() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_985",
		"source_task_id": "TASK_984",
		"status": "player_loop_scenario_outcome_ready",
		"gate": "player_loop_scenario_outcome_ready",
		"scenario_outcome_ready": true,
		"selected_choice_id": "push_objective",
		"selected_choice_label": "PUSH",
		"outcome_line": "PUSH: Ziel unter Druck, naechster Abschnitt offen.",
		"result_tag": "objective_pressure",
		"mini_objective_state": "Ziel 1/2 unter Druck",
		"next_step_line": "Naechster Griff: sichern oder weiter druecken.",
		"recommended_next_task": "TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture",
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


func _good_manifest(accepted: bool) -> Dictionary:
	var required: Array = [
		"real_window_launched",
		"correct_window_content_confirmed",
		"window_capture_trusted",
		"window_screenshot_written",
		"outcome_line_visible",
		"mini_objective_state_visible",
		"next_step_line_visible",
		"player_result_readable",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
		"manual_visual_review_done",
	]
	return {
		"schema": SCHEMA,
		"task_id": "TASK_986",
		"source_task_id": "TASK_985",
		"gate": "accepted" if accepted else "review_ready",
		"branch": "task/release-first-decision-loop-two-player-loop-scenario-outcome-slice",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"source_schema": SOURCE_SCHEMA,
		"source_gate": "player_loop_scenario_outcome_ready",
		"source_status": "player_loop_scenario_outcome_ready",
		"selected_process_id": 986,
		"capture_process_id": 986,
		"capture_after_scenario_outcome_ready": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_outcome_real_window_capture.png",
		"desktop_screenshot_path": "tmp/release_first_decision_loop_two_player_loop_outcome_real_window_capture_desktop.png",
		"hard_failures": [],
		"source_scenario_outcome_snapshot": _scenario_outcome(),
		"manual_review_required": true,
		"manual_review_done": accepted,
		"required_checks": required,
		"completed_manual_checks": required if accepted else [],
		"read_only": true,
		"read_only_capture": true,
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
		and bool(snapshot.get("read_only_capture", false)) \
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
