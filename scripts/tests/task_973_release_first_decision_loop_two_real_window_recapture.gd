extends SceneTree

const Recapture := preload("res://scripts/mission/release_first_decision_loop_two_real_window_recapture.gd")

const TASK_PATH := "res://docs/tasks/TASK_973_release_first_decision_loop_two_real_window_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CLARITY_CONTRACT_PATH := "res://docs/dev/tactical_decision_clarity_contract.md"
const SERVICE_PATH := "res://scripts/mission/release_first_decision_loop_two_real_window_recapture.gd"
const TOOL_PATH := "res://scripts/tools/capture_release_first_decision_loop_two_real_window_recapture.ps1"
const OUTPUT_PATH := "res://tmp/release_first_decision_loop_two_real_window_recapture_acceptance.json"
const SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_real_window_recapture.v1"
const SOURCE_SCHEMA := "sternenbuergerchen.release_first_decision_loop_two_playability_smoke.v1"
const NEXT_TASK := "TASK_974 - Release First Decision Loop Two Recapture Visual Findings"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_973 Release First Decision Loop Two Real Window Recapture ===")
	_test_docs_and_static_hooks()
	_test_missing_source_blocks()
	_test_passed_smoke_without_manifest_needs_recapture()
	_test_good_manifest_is_review_ready()
	_test_completed_manual_checks_accept()
	_test_manifest_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_973_release_first_decision_loop_two_real_window_recapture: FAILED")
		quit(1)
		return
	print("TASK_973_release_first_decision_loop_two_real_window_recapture: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var command_contract_text: String = _read_text(COMMAND_CONTRACT_PATH)
	var clarity_contract_text: String = _read_text(CLARITY_CONTRACT_PATH)
	var service_text: String = _read_text(SERVICE_PATH)
	var tool_text: String = _read_text(TOOL_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_973 task file exists")
	_assert(FileAccess.file_exists(SERVICE_PATH), "TASK_973 recapture analyzer exists")
	_assert(FileAccess.file_exists(TOOL_PATH), "TASK_973 recapture tool exists")
	_assert(task_text.contains("TASK_973 - Release First Decision Loop Two Real Window Recapture"), "Task names TASK_973")
	_assert(task_text.contains(NEXT_TASK), "Task names TASK_974 follow-up")
	_assert(status_text.contains("TASK_973 - Release First Decision Loop Two Real Window Recapture"), "Implementation status tracks TASK_973")
	_assert(roadmap_text.contains("TASK_973 - Release First Decision Loop Two Real Window Recapture (implementiert"), "Roadmap marks TASK_973 implemented")
	_assert(command_contract_text.contains("Release First Decision Loop Two Real Window Recapture (TASK_973)"), "Mission feedback contract documents TASK_973")
	_assert(clarity_contract_text.contains("Release First Decision Loop Two Real Window Recapture (TASK_973)"), "Decision clarity contract documents TASK_973")
	_assert(service_text.contains(SCHEMA), "Analyzer exposes stable TASK_973 schema")
	_assert(service_text.contains("TASK_ID: String = \"TASK_973\""), "Analyzer writes TASK_973 id")
	_assert(service_text.contains("SOURCE_TASK_ID: String = \"TASK_972\""), "Analyzer links TASK_972")
	_assert(service_text.contains("REQUIRED_RECAPTURE_CHECKS"), "Analyzer defines required recapture checks")
	_assert(service_text.contains("\"read_only\": true"), "Analyzer declares read-only")
	_assert(service_text.contains("\"read_only_capture\": true"), "Analyzer declares read-only capture")
	_assert(service_text.contains("\"creates_command\": false"), "Analyzer creates no command")
	_assert(service_text.contains("\"creates_movement\": false"), "Analyzer creates no movement")
	_assert(service_text.contains("\"sets_multiplayer_truth\": false"), "Analyzer creates no multiplayer truth")
	_assert(tool_text.contains("release_first_decision_loop_two_real_window_recapture.json"), "Recapture tool writes TASK_973 manifest")
	_assert(tool_text.contains("--release-singleplayer-lz-drop-preview"), "Recapture tool uses release first decision deep-link")
	_assert(tool_text.contains("manual_review_done = $false"), "Recapture tool does not auto-pass manual review")
	_assert(tool_text.contains("loop_two_smoke_line_visible"), "Recapture tool requires smoke-line review")
	_assert(tool_text.contains("post_go_feedback_visible"), "Recapture tool requires post-GO feedback review")
	_assert(tool_text.contains("updates_shortcuts = $false"), "Recapture tool updates no shortcuts")


func _test_missing_source_blocks() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot({}, {})
	var blocker_ids: Array = _issue_ids(Array(snapshot.get("blocking_issues", [])))
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing source blocks TASK_973")
	_assert(blocker_ids.has("source_schema_mismatch"), "Missing source reports schema mismatch")
	_assert(blocker_ids.has("source_task_mismatch"), "Missing source reports task mismatch")
	_assert(blocker_ids.has("source_playability_smoke_not_passed"), "Missing source reports smoke not passed")
	_assert(_snapshot_is_read_only(snapshot), "Blocked snapshot remains read-only")


func _test_passed_smoke_without_manifest_needs_recapture() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_playability_smoke(), {})
	var issue_ids: Array = _issue_ids(Array(snapshot.get("issues", [])))
	_assert(String(snapshot.get("status", "")) == "needs_real_window_recapture", "Passed smoke without manifest needs recapture")
	_assert(String(snapshot.get("gate", "")) == "needs_real_window_recapture_run", "Missing manifest gates recapture run")
	_assert(issue_ids.has("real_window_recapture_manifest_missing"), "Missing manifest is named")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_973 - Release First Decision Loop Two Real Window Recapture", "Missing manifest loops on TASK_973")
	_assert(_snapshot_is_read_only(snapshot), "Needs-run snapshot remains read-only")


func _test_good_manifest_is_review_ready() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_playability_smoke(), _good_manifest(false))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema matches TASK_973")
	_assert(String(snapshot.get("task_id", "")) == "TASK_973", "Snapshot task id matches TASK_973")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_972", "Snapshot links TASK_972")
	_assert(String(snapshot.get("source_schema", "")) == SOURCE_SCHEMA, "Snapshot records TASK_972 schema")
	_assert(String(snapshot.get("status", "")) == "review_ready", "Good manifest is review-ready")
	_assert(bool(snapshot.get("review_ready", false)), "Snapshot marks review-ready")
	_assert(not bool(snapshot.get("accepted", true)), "Snapshot does not auto-accept")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) > 0, "Manual checks remain missing")
	_assert(String(snapshot.get("recommended_next_task", "")) == NEXT_TASK, "Snapshot recommends TASK_974")
	_assert(String(snapshot.get("recommended_direction", "")) == "cut_loop_two_recapture_visual_findings", "Snapshot recommends visual findings")
	_assert(_snapshot_is_read_only(snapshot), "Good snapshot remains read-only")


func _test_completed_manual_checks_accept() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_playability_smoke(), _good_manifest(true))
	_assert(String(snapshot.get("status", "")) == "accepted", "Completed manual checks accept TASK_973")
	_assert(bool(snapshot.get("accepted", false)), "Accepted snapshot sets accepted flag")
	_assert(int(snapshot.get("missing_manual_check_count", -1)) == 0, "No manual checks missing")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Accepted snapshot has no blockers")
	_assert(int(snapshot.get("issue_count", -1)) == 0, "Accepted snapshot has no issues")


func _test_manifest_roundtrip() -> void:
	var snapshot: Dictionary = Recapture.build_snapshot(_playability_smoke(), _good_manifest(false))
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can write TASK_973 output manifest")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()
	var roundtrip: Dictionary = _read_json_dict(OUTPUT_PATH)
	_assert(String(roundtrip.get("task_id", "")) == "TASK_973", "Roundtrip keeps task id")
	_assert(String(roundtrip.get("source_task_id", "")) == "TASK_972", "Roundtrip keeps TASK_972 link")
	_assert(String(roundtrip.get("recommended_next_task", "")) == NEXT_TASK, "Roundtrip keeps next task")
	_assert(_snapshot_is_read_only(roundtrip), "Roundtrip keeps read-only boundary")


func _playability_smoke() -> Dictionary:
	var checks: Array = [
		"second_decision_button_visible",
		"second_decision_confirmed",
		"go_button_still_separate",
		"go_executed_after_confirm",
		"post_go_feedback_visible",
		"no_go_before_second_confirm",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
	]
	return {
		"schema": SOURCE_SCHEMA,
		"task_id": "TASK_972",
		"source_task_id": "TASK_971",
		"status": "loop_two_playability_smoke_passed",
		"gate": "loop_two_playability_smoke_passed",
		"trace_available": true,
		"completed_checks": checks,
		"missing_smoke_checks": [],
		"playability_smoke_passed": true,
		"source_button_text": "2ND",
		"smoke_line": "2ND -> GO -> Feedback PASS | 2ND HOLD -> Defend vorbereiten | danach GO separat",
		"post_go_feedback_line": "Feedback: zweiter Griff vorbereitet, GO ausgefuehrt.",
		"recommended_next_task": "TASK_973 - Release First Decision Loop Two Real Window Recapture",
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
		"second_decision_button_visible",
		"second_decision_confirmed",
		"go_button_still_separate",
		"go_executed_after_confirm",
		"post_go_feedback_visible",
		"loop_two_smoke_line_visible",
		"no_new_hud_gameplay_truth",
		"multiplayer_boundary_preserved",
		"manual_visual_review_done",
	]
	return {
		"schema": SCHEMA,
		"task_id": "TASK_973",
		"source_task_id": "TASK_972",
		"gate": "accepted" if accepted else "review_ready",
		"branch": "task/release-first-exchange-player-readability-polish-review",
		"git_head": "test",
		"launch_argument": "--release-singleplayer-lz-drop-preview",
		"source_schema": SOURCE_SCHEMA,
		"source_gate": "loop_two_playability_smoke_passed",
		"source_status": "loop_two_playability_smoke_passed",
		"selected_process_id": 973,
		"capture_process_id": 973,
		"capture_after_playability_smoke_passed": true,
		"window_capture_method": "window_handle_print",
		"window_capture_trusted": true,
		"window_screenshot_written": true,
		"desktop_screenshot_written": true,
		"window_screenshot_path": "tmp/release_first_decision_loop_two_real_window_recapture.png",
		"desktop_screenshot_path": "tmp/release_first_decision_loop_two_real_window_recapture_desktop.png",
		"hard_failures": [],
		"source_playability_smoke_snapshot": _playability_smoke(),
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
