extends SceneTree

const STATION_ROUTE_POST_POLISH_RECHECK_SCRIPT: GDScript = preload("res://scripts/mission/station_route_post_polish_recheck.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_719_station_route_post_polish_recheck.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const POLISH_MANIFEST_PATH: String = "res://tmp/station_route_door_go_reject_visual_polish.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_post_polish_recheck.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_719 Station Route Post-Polish Recheck Guard ===")
	_test_docs()
	_test_missing_polish_blocks()
	_test_stale_capture_requests_refresh()
	_test_fresh_capture_waits_for_window_recheck()
	_test_actual_manifest_snapshot()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_719: FAILED")
		quit(1)
		return
	print("TASK_719: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_719 task file exists")
	_assert(task_text.contains("Station Route Post-Polish Recheck Guard"), "Task documents post-polish recheck guard")
	_assert(contract_text.contains("Station Route Post-Polish Recheck Guard"), "Interaction contract documents TASK_719")
	_assert(status_text.contains("TASK_719 - Station Route Post-Polish Recheck Guard"), "Implementation status tracks TASK_719")
	_assert(roadmap_text.contains("TASK_719 - Station Route Post-Polish Recheck Guard (implementiert)"), "Roadmap marks TASK_719 implemented")
	_assert(report_text.contains("TASK_719 - Station Route Post-Polish Recheck Guard"), "Current report references TASK_719")
	_assert(report_text.contains('data-export-key="station_route_post_polish_recheck.manifest_path"'), "Current report exports TASK_719 manifest path")


func _test_missing_polish_blocks() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POST_POLISH_RECHECK_SCRIPT.call("build_snapshot", _fresh_capture(false), {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing polish snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_post_polish_recheck.v1", "Recheck schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_718 polish blocks")
	_assert(int(snapshot.get("blocking_issue_count", 0)) > 0, "Missing TASK_718 polish produces blocker")


func _test_stale_capture_requests_refresh() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POST_POLISH_RECHECK_SCRIPT.call("build_snapshot", _stale_capture(), _polish_manifest()))
	_assert(String(snapshot.get("status", "")) == "needs_capture_refresh", "Stale capture requests capture refresh")
	_assert(int(snapshot.get("stale_count", 0)) >= 3, "Stale capture records stale issues")
	_assert(not bool(snapshot.get("capture_fresh", true)), "Stale capture is not fresh")
	_assert(bool(snapshot.get("polish_ready", false)), "TASK_718 polish remains ready")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("refresh"), "Stale capture recommends refresh")


func _test_fresh_capture_waits_for_window_recheck() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POST_POLISH_RECHECK_SCRIPT.call("build_snapshot", _fresh_capture(false), _polish_manifest()))
	_assert(String(snapshot.get("status", "")) == "ready_for_real_window_recheck", "Fresh capture waits for real window recheck")
	_assert(bool(snapshot.get("capture_fresh", false)), "Fresh capture is fresh")
	_assert(bool(snapshot.get("real_run_done", false)), "Fresh capture records real run")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Fresh capture keeps manual review open")
	_assert(_snapshot_is_read_only(snapshot), "Fresh recheck snapshot is read-only")


func _test_actual_manifest_snapshot() -> void:
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var polish_manifest: Dictionary = _read_json(POLISH_MANIFEST_PATH)
	if capture_manifest.is_empty() or polish_manifest.is_empty():
		_assert(true, "Actual tmp manifests not both present; fake coverage remains authoritative")
		return
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POST_POLISH_RECHECK_SCRIPT.call("build_snapshot", capture_manifest, polish_manifest))
	_assert(_snapshot_is_read_only(snapshot), "Actual recheck snapshot is read-only")
	_assert(["needs_capture_refresh", "ready_for_real_window_recheck", "accepted"].has(String(snapshot.get("status", ""))), "Actual recheck status is actionable")
	_assert(bool(snapshot.get("polish_ready", false)), "Actual TASK_718 polish manifest is ready")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	if capture_manifest.is_empty():
		capture_manifest = _stale_capture()
	var polish_manifest: Dictionary = _read_json(POLISH_MANIFEST_PATH)
	if polish_manifest.is_empty():
		polish_manifest = _polish_manifest()
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_POST_POLISH_RECHECK_SCRIPT.call("build_snapshot", capture_manifest, polish_manifest, {
		"capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"polish_manifest_path": "tmp/station_route_door_go_reject_visual_polish.json",
	}))
	snapshot["task_id"] = "TASK_719"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_719 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_719", "Manifest records TASK_719")
	_assert(["needs_capture_refresh", "ready_for_real_window_recheck", "accepted"].has(String(parsed.get("status", ""))), "Manifest records actionable status")
	_assert(_snapshot_is_read_only(parsed), "Manifest stays read-only")


func _polish_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_door_go_reject_visual_polish.v1",
		"task_id": "TASK_718",
		"compact_line": "DOOR COM B->GO",
		"button_text": "B->GO",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _fresh_capture(review_done: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
		"station_route_host_client_acceptance_task_id": "TASK_712",
		"door_real_click_expected_ready_line": "DOOR B->GO",
		"door_real_click_expected_open_line": "DOOR OPEN",
		"station_route_expected_door_line": "DOOR OPEN",
		"real_run_done": true,
		"screenshot_written": true,
		"host_screenshot_written": true,
		"client_screenshot_written": true,
		"station_route_host_client_acceptance_review_done": review_done,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _stale_capture() -> Dictionary:
	var capture: Dictionary = _fresh_capture(false)
	capture["door_real_click_expected_ready_line"] = "DOOR DOOR B->GO"
	capture["door_real_click_expected_open_line"] = "DOOR DOOR OPEN"
	capture["station_route_expected_door_line"] = "DOOR DOOR OPEN"
	return capture


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_719 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
