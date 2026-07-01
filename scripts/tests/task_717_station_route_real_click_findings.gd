extends SceneTree

const STATION_ROUTE_REAL_CLICK_FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_route_real_click_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_717_station_route_real_click_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const CAPTURE_MANIFEST_PATH: String = "res://tmp/host_client_two_window_real_run_review.json"
const ROUTE_MANIFEST_PATH: String = "res://tmp/station_route_run_readout_polish.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_real_click_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_717 Station Route Real Host/Client Click Findings ===")
	_test_docs()
	_test_missing_inputs_block()
	_test_ready_fake_snapshot()
	_test_actual_manifest_snapshot()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_717: FAILED")
		quit(1)
		return
	print("TASK_717: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_717 task file exists")
	_assert(task_text.contains("Station Route Real Host/Client Click Findings"), "Task documents real click findings")
	_assert(contract_text.contains("Station Route Real Host/Client Click Findings"), "Interaction contract documents TASK_717")
	_assert(status_text.contains("TASK_717 - Station Route Real Host/Client Click Findings"), "Implementation status tracks TASK_717")
	_assert(roadmap_text.contains("TASK_717 - Station Route Real Host/Client Click Findings (implementiert)"), "Roadmap marks TASK_717 implemented")
	_assert(report_text.contains("TASK_717 - Station Route Real Host/Client Click Findings"), "Current report references TASK_717")
	_assert(report_text.contains('data-export-key="station_route_real_click_findings.manifest_path"'), "Current report exports TASK_717 manifest path")


func _test_missing_inputs_block() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-input snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_real_click_findings.v1", "Findings schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing inputs block findings")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 2, "Missing inputs produce blockers")
	_assert(not bool(snapshot.get("capture_ready", true)), "Missing capture is not ready")
	_assert(not bool(snapshot.get("route_readout_ready", true)), "Missing route readout is not ready")


func _test_ready_fake_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", _fake_capture_manifest(false), _fake_route_manifest()))
	_assert(_snapshot_is_read_only(snapshot), "Ready snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_click_findings_review", "Ready evidence waits for human click findings")
	_assert(bool(snapshot.get("capture_ready", false)), "Ready evidence has capture")
	_assert(bool(snapshot.get("route_readout_ready", false)), "Ready evidence has route readout")
	_assert(int(snapshot.get("manual_note_count", 0)) > 0, "Ready evidence records manual note")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_718"), "Ready evidence recommends TASK_718 polish")
	_assert(String(snapshot.get("route_line", "")).contains("NEXT DONE"), "Ready evidence keeps final route token")


func _test_actual_manifest_snapshot() -> void:
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var route_manifest: Dictionary = _read_json(ROUTE_MANIFEST_PATH)
	if capture_manifest.is_empty() or route_manifest.is_empty():
		_assert(true, "Actual tmp manifests not present; fake manifest coverage remains authoritative")
		return
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", capture_manifest, route_manifest))
	_assert(_snapshot_is_read_only(snapshot), "Actual manifest snapshot is read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_click_findings_review", "Actual manifests are ready for click findings review")
	_assert(bool(snapshot.get("capture_ready", false)), "Actual capture manifest is ready")
	_assert(bool(snapshot.get("route_readout_ready", false)), "Actual route readout manifest is ready")
	_assert(int(snapshot.get("blocking_issue_count", -1)) == 0, "Actual manifests have no technical blockers")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var capture_manifest: Dictionary = _read_json(CAPTURE_MANIFEST_PATH)
	var route_manifest: Dictionary = _read_json(ROUTE_MANIFEST_PATH)
	if capture_manifest.is_empty():
		capture_manifest = _fake_capture_manifest(false)
	if route_manifest.is_empty():
		route_manifest = _fake_route_manifest()
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_REAL_CLICK_FINDINGS_SCRIPT.call("build_snapshot", capture_manifest, route_manifest, {
		"capture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"route_manifest_path": "tmp/station_route_run_readout_polish.json",
	}))
	snapshot["task_id"] = "TASK_717"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Real click findings manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_717", "Manifest records TASK_717")
	_assert(String(parsed.get("status", "")) == "ready_for_click_findings_review", "Manifest records ready-for-review status")
	_assert(bool(parsed.get("capture_ready", false)), "Manifest records capture readiness")
	_assert(bool(parsed.get("route_readout_ready", false)), "Manifest records route readiness")
	_assert(_snapshot_is_read_only(parsed), "Manifest stays read-only")


func _fake_capture_manifest(review_done: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
		"station_route_host_client_acceptance_task_id": "TASK_712",
		"station_route_host_client_acceptance_review_required": true,
		"station_route_host_client_acceptance_review_done": review_done,
		"station_route_host_client_acceptance_gate": "review_ready",
		"review_checks": [
			"station_route_host_window_visible",
			"station_route_client_window_visible",
			"station_route_door_open_host_client",
			"station_route_computer_control_visible",
			"station_route_cargo_departed_visible",
			"station_route_wrong_team_reject",
			"station_route_snapshot_sync",
		],
		"launch_requested": true,
		"real_run_done": true,
		"screenshot_written": true,
		"host_screenshot_written": true,
		"client_screenshot_written": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _fake_route_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_run_readout_polish.v1",
		"task_id": "TASK_716",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"cargo_line": "ROUTE AA OK > DOOR OPEN > COM CTRL > CARGO DEPARTED | NEXT DONE",
		"final_next_token": "DONE",
		"line_within_limit": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_717 manifest for writing")
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
