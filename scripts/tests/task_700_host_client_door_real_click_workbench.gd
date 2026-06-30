extends SceneTree

const HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT: GDScript = preload("res://scripts/mission/mission_host_client_door_real_click_workbench.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_700_host_client_door_real_click_workbench.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const WORKBENCH_PATH: String = "res://docs/reports/host_client_door_real_click_workbench_2026_06_30.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/host_client_door_real_click_workbench.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_700 Host/Client Door Real Click Workbench ===")
	_test_docs()
	_test_snapshot_contract()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_700: FAILED")
		quit(1)
		return
	print("TASK_700: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_700 task file exists")
	_assert(task_text.contains("Host/Client Door Real Click Workbench"), "Task documents host/client door real click workbench")
	_assert(contract_text.contains("Host/Client Door Real Click Workbench"), "Interaction contract documents host/client door workbench")
	_assert(status_text.contains("TASK_700 - Host/Client Door Real Click Workbench"), "Implementation status tracks TASK_700")
	_assert(roadmap_text.contains("TASK_700 - Host/Client Door Real Click Workbench (implementiert)"), "Roadmap marks TASK_700 implemented")
	_assert(handbook_text.contains("TASK_700 - Host/Client Door Real Click Workbench"), "Current handbook references TASK_700")
	_assert(handbook_text.contains('data-export-key="host_client_door_real_click_workbench.manifest_path"'), "Current handbook exports TASK_700 manifest path")
	_assert(FileAccess.file_exists(WORKBENCH_PATH), "Host/client door real click workbench exists")
	_assert(workbench_text.contains("JSON exportieren"), "Workbench exposes JSON export button")
	_assert(workbench_text.contains('data-export-key="door_real_click.host_window_launched"'), "Workbench exports host-window check")
	_assert(workbench_text.contains('data-export-key="door_real_click.next_polish_action"'), "Workbench exports next polish action")


func _test_snapshot_contract() -> void:
	var capture_snapshot: Dictionary = _fake_capture()
	var snapshot: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT.call("build_snapshot", capture_snapshot, {}))
	_assert(_snapshot_is_read_only(snapshot), "Host/client door workbench snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.host_client_door_real_click_workbench.v1", "Host/client door workbench schema is stable")
	_assert(bool(snapshot.get("manual_review_required", false)), "Manual review remains required")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Manual review is not auto-completed")
	_assert(String(snapshot.get("status", "")) == "awaiting_real_click_notes", "Snapshot waits for real click notes")
	_assert(int(snapshot.get("required_check_count", 0)) >= 10, "Snapshot defines required host/client checks")
	_assert(int(snapshot.get("note_field_count", 0)) >= 6, "Snapshot defines host/client note fields")
	_assert(String(snapshot.get("source_capture_schema", "")) == "sternenbuergerchen.mission_multiplayer_door_feedback_capture.v1", "Snapshot keeps source capture schema")
	_assert(String(snapshot.get("source_capture_gate", "")) == "pass", "Snapshot keeps source capture gate")
	_assert(String(snapshot.get("report_path", "")) == "docs/reports/host_client_door_real_click_workbench_2026_06_30.html", "Snapshot exposes report path")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_704"), "Snapshot recommends next findings task")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var snapshot: Dictionary = Dictionary(HOST_CLIENT_DOOR_REAL_CLICK_WORKBENCH_SCRIPT.call("build_snapshot", _fake_capture(), {}))
	snapshot["task_id"] = "TASK_700"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Host/client door workbench manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_700", "Manifest records TASK_700")
	_assert(String(parsed.get("status", "")) == "awaiting_real_click_notes", "Manifest records open real click notes status")
	_assert(not bool(parsed.get("manual_review_done", true)), "Manifest does not claim manual review done")


func _fake_capture() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.mission_multiplayer_door_feedback_capture.v1",
		"gate": "pass",
		"summary": "Door feedback capture OK",
		"manifest_path": "tmp/multiplayer_door_feedback_capture.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_700 manifest for writing")
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
