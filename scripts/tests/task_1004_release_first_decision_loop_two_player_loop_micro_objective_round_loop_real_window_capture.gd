extends SceneTree

const ControllerScript := preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")

const TASK_PATH := "res://docs/tasks/TASK_1004_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.gd"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_player_loop_micro_objective_round_loop_runtime_polish.v1"
const LAUNCH_ARGUMENT := "--release-singleplayer-lz-drop-preview"
const NEXT_TASK := "TASK_1005 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1004 Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_ready_source_without_manifest_needs_capture()
	_test_review_ready_manifest_stays_open()
	_test_accepted_manifest_passes_capture()
	_test_controller_exports_real_window_capture()
	_test_real_window_capture_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1004_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture: FAILED")
		quit(1)
		return
	print("TASK_1004_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture: ALL PASSED")
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
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_1004 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_1004 real-window capture service exists")
	_assert(task_text.contains("TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture"), "Task names TASK_1004")
	_assert(task_text.contains(NEXT_TASK), "Task names visual findings follow-up")
	_assert(status_text.contains("TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture"), "Implementation status tracks TASK_1004")
	_assert(roadmap_text.contains("TASK_1004 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture (implementiert"), "Roadmap marks TASK_1004 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture (TASK_1004)"), "Mission feedback contract documents TASK_1004")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Player Loop Micro Objective Round Loop Real Window Capture (TASK_1004)"), "Decision clarity contract documents TASK_1004")
	_assert(service_text.contains(SCHEMA), "Capture service exposes stable TASK_1004 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_1004\""), "Capture service writes TASK_1004 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_1003\""), "Capture service links TASK_1003")
	_assert(service_text.contains("REQUIRED_CAPTURE_CHECKS"), "Capture service defines required checks")
	_assert(service_text.contains("\"manual_review_done\""), "Capture service exposes manual review state")
	_assert(service_text.contains("\"read_only_capture\": true"), "Capture service is read-only capture")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Capture service creates no multiplayer truth")
	_assert(controller_text.contains("RELEASE_FIRST_DECISION_LOOP_TWO_PLAYER_LOOP_MICRO_OBJECTIVE_ROUND_LOOP_REAL_WINDOW_CAPTURE_SCRIPT"), "Controller preloads TASK_1004 service")
	_assert(controller_text.contains("get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_snapshot"), "Controller exposes TASK_1004 snapshot")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_gate"), "Command feedback exports TASK_1004 gate")
	_assert(feedback_source_text.contains("release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_window_screenshot_path"), "Command feedback exports TASK_1004 screenshot path")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = _build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_1004")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_not_ready"), "Missing source reports source not ready")
	_assert(_snapshot_is_read_only(snapshot), "Blocked capture snapshot remains read-only")


func _test_ready_source_without_manifest_needs_capture() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_polish(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_1004")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1004", "Snapshot task id matches")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1003", "Snapshot links TASK_1003")
	_assert(String(snapshot.get("status", "")) == "needs_round_loop_real_window_capture", "Ready source without manifest needs capture")
	_assert(String(snapshot.get("gate", "")) == "needs_round_loop_real_window_capture_run", "Gate asks for capture run")
	_assert(issue_ids.has("round_loop_real_window_capture_manifest_missing"), "Missing manifest is explicit")
	_assert(not bool(snapshot.get("accepted", true)), "Missing manifest is not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Capture-needed snapshot remains read-only")


func _test_review_ready_manifest_stays_open() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_polish(), _review_ready_manifest(false))
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "review_ready", "Trusted manifest is review-ready")
	_assert(String(snapshot.get("gate", "")) == "round_loop_real_window_capture_review_ready", "Gate reports review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Review-ready flag is true")
	_assert(not bool(snapshot.get("accepted", true)), "Review-ready without manual checks is not accepted")
	_assert(issue_ids.has("manual_round_loop_review_open"), "Manual review remains open")
	_assert(Array(snapshot.get("missing_manual_checks", [])).has("manual_visual_review_done"), "Manual visual review check remains missing")
	_assert(_snapshot_is_read_only(snapshot), "Review-ready capture remains read-only")


func _test_accepted_manifest_passes_capture() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_polish(), _review_ready_manifest(true))
	_assert(String(snapshot.get("status", "")) == "accepted", "Accepted manifest passes TASK_1004")
	_assert(String(snapshot.get("gate", "")) == "round_loop_real_window_capture_accepted", "Accepted gate is explicit")
	_assert(bool(snapshot.get("accepted", false)), "Accepted flag is true")
	_assert(String(snapshot.get("launch_argument", "")) == LAUNCH_ARGUMENT, "Launch argument is recorded")
	_assert(String(snapshot.get("window_screenshot_path", "")).ends_with(".png"), "Window screenshot path is exported")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Accepted capture recommends visual findings")
	_assert(_snapshot_is_read_only(snapshot), "Accepted capture remains read-only")


func _test_controller_exports_real_window_capture() -> void:
	var controller := ControllerScript.new()
	var snapshot: Dictionary = controller.get_release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_snapshot(_source_runtime_polish(), _review_ready_manifest(true))
	var feedback: Dictionary = controller.get_command_feedback_snapshot()
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Controller TASK_1004 schema matches")
	_assert(String(snapshot.get("status", "")) == "accepted", "Controller TASK_1004 accepts with manifest")
	_assert(_snapshot_is_read_only(snapshot), "Controller TASK_1004 snapshot remains read-only")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture"), "Command feedback embeds TASK_1004")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_status"), "Command feedback exports TASK_1004 status")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_gate"), "Command feedback exports TASK_1004 gate")
	_assert(feedback.has("release_first_decision_loop_two_player_loop_micro_objective_round_loop_real_window_capture_window_screenshot_path"), "Command feedback exports TASK_1004 screenshot")
	controller.queue_free()


func _test_real_window_capture_roundtrip() -> void:
	var snapshot: Dictionary = _build_snapshot(_source_runtime_polish(), _review_ready_manifest(true))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_1004 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_1004", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_1003", "Roundtrip keeps TASK_1003 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _build_snapshot(source_runtime_polish: Dictionary, manifest: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(SERVICE_PATH):
		_assert(false, "TASK_1004 service is loadable")
		return {
			"read_only": true,
			"read_only_capture": true,
			"ui_sets_gameplay_truth": false,
			"creates_command": false,
			"creates_fire_event": false,
			"creates_damage_event": false,
			"creates_movement": false,
			"sets_multiplayer_truth": false,
		}
	var service_script: GDScript = load(SERVICE_PATH)
	if service_script == null:
		_assert(false, "TASK_1004 service script loads")
		return {}
	var snapshot_variant: Variant = service_script.call("build_snapshot", source_runtime_polish, manifest)
	if typeof(snapshot_variant) == TYPE_DICTIONARY:
		return Dictionary(snapshot_variant)
	_assert(false, "TASK_1004 service returns dictionary")
	return {}


func _source_runtime_polish() -> Dictionary:
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_1003",
		"source_task_id": "TASK_1002",
		"status": "micro_objective_round_loop_runtime_polish_ready",
		"source_status": "micro_objective_round_loop_playtest_slice_passed",
		"round_loop_runtime_surface_spec_count": 3,
		"round_loop_runtime_surface_specs": [
			{"surface_id": "round_loop_status_surface", "token": "ROUND", "text": "ROUND 2 abgeschlossen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
			{"surface_id": "next_decision_surface", "token": "NEXT", "text": "Naechstes Micro-Ziel waehlen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
			{"surface_id": "go_boundary_surface", "token": "GO", "text": "GO separat bestaetigen", "read_only": true, "ui_sets_gameplay_truth": false, "creates_command": false, "creates_movement": false},
		],
		"selected_fireteam_runtime_line": "ROUND 2 stabil | NEXT bereit",
		"mission_control_runtime_line": "NEXT Micro-Ziel waehlen | GO separat",
		"command_feedback_runtime_line": "ROUND LOOP: Feedback gelesen | GO separat bleibt",
		"runtime_lines_within_limit": true,
		"go_separation_visible": true,
		"next_decision_visible": true,
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


func _review_ready_manifest(done: bool) -> Dictionary:
	var required: Array = [
		"real_window_launched",
		"correct_window_content_confirmed",
		"window_capture_trusted",
		"window_screenshot_written",
		"round_surface_visible",
		"next_surface_visible",
		"go_separation_visible",
		"selected_fireteam_runtime_line_visible",
		"mission_control_runtime_line_visible",
		"command_feedback_runtime_line_visible",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
		"manual_visual_review_done",
	]
	var completed: Array = required.duplicate()
	if not done:
		completed.erase("manual_visual_review_done")
	return {
		"schema": SCHEMA,
		"task_id": "TASK_1004",
		"source_task_id": "TASK_1003",
		"source_schema": SOURCE_SCHEMA,
		"source_status": "micro_objective_round_loop_runtime_polish_ready",
		"gate": "review_ready",
		"branch": "task/release-first-decision-loop-two-player-loop-micro-objective-round-loop-real-window-capture",
		"git_head": "test-head",
		"launch_argument": LAUNCH_ARGUMENT,
		"selected_process_id": 4204,
		"capture_process_id": 4204,
		"capture_after_round_loop_runtime_polish_ready": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/round_loop_real_window_capture.png",
		"desktop_screenshot_path": "tmp/round_loop_real_window_capture_desktop.png",
		"source_runtime_polish_snapshot": _source_runtime_polish(),
		"manual_review_required": true,
		"manual_review_done": done,
		"required_checks": required,
		"completed_manual_checks": completed,
		"hard_failures": [],
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
