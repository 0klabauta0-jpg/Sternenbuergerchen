extends SceneTree

const STATION_ROUTE_WINDOW_PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_route_window_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_709_station_route_window_playtest_notes.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_refresh_2026_06_30.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_route_window_playtest_notes_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_window_playtest_notes.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_709 Station Route Window Playtest Notes ===")
	_test_docs_and_workbench()
	_test_snapshot_contract()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_709: FAILED")
		quit(1)
		return
	print("TASK_709: ALL PASSED")
	quit(0)


func _test_docs_and_workbench() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_709 task file exists")
	_assert(task_text.contains("Station Route Window Playtest Notes"), "Task documents station route window notes")
	_assert(contract_text.contains("Station Route Window Playtest Notes"), "Interaction contract documents TASK_709 notes")
	_assert(status_text.contains("TASK_709 - Station Route Window Playtest Notes"), "Implementation status tracks TASK_709")
	_assert(roadmap_text.contains("TASK_709 - Station Route Window Playtest Notes (implementiert)"), "Roadmap marks TASK_709 implemented")
	_assert(handbook_text.contains("TASK_709 - Station Route Window Playtest Notes"), "Current handbook references TASK_709")
	_assert(handbook_text.contains('data-export-key="station_route_window_playtest_notes.manifest_path"'), "Current handbook exports TASK_709 manifest path")
	_assert(FileAccess.file_exists(WORKBENCH_PATH), "Station route notes workbench exists")
	_assert(workbench_text.contains("JSON exportieren"), "Workbench exposes JSON export button")
	_assert(workbench_text.contains('data-report-schema="sternenbuergerchen.html_workbench.v1"'), "Workbench uses HTML workbench schema")
	_assert(workbench_text.contains('data-export-key="station_route_window.real_window_launched"'), "Workbench exports real-window check")
	_assert(workbench_text.contains('data-export-key="station_route_window.manual_window_review_done"'), "Workbench exports manual done check")
	_assert(workbench_text.contains('data-export-key="station_route_window.next_polish_action"'), "Workbench exports next polish action")


func _test_snapshot_contract() -> void:
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_WINDOW_PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_evidence(), {}))
	_assert(_snapshot_is_read_only(snapshot), "Window playtest notes snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_route_window_playtest_notes.v1", "Window playtest notes schema is stable")
	_assert(bool(snapshot.get("manual_window_review_required", false)), "Manual window review remains required")
	_assert(not bool(snapshot.get("manual_window_review_done", true)), "Manual window review is not auto-completed")
	_assert(String(snapshot.get("status", "")) == "awaiting_manual_notes", "Snapshot waits for manual notes")
	_assert(int(snapshot.get("required_check_count", 0)) >= 8, "Snapshot defines station route checks")
	_assert(int(snapshot.get("note_field_count", 0)) >= 6, "Snapshot defines note fields")
	_assert(String(snapshot.get("source_evidence_schema", "")) == "sternenbuergerchen.station_route_visual_evidence.v1", "Snapshot keeps source evidence schema")
	_assert(String(snapshot.get("source_evidence_png_path", "")) == "tmp/station_route_visual_evidence.png", "Snapshot keeps evidence png path")
	_assert(bool(snapshot.get("generated_evidence_board", false)), "Snapshot records generated evidence board")
	_assert(not bool(snapshot.get("viewport_readback_available", true)), "Snapshot records missing viewport readback")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_709"), "Snapshot recommends continuing TASK_709 while open")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var snapshot: Dictionary = Dictionary(STATION_ROUTE_WINDOW_PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_evidence(), {}))
	snapshot["task_id"] = "TASK_709"
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Window playtest notes manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_709", "Manifest records TASK_709")
	_assert(String(parsed.get("status", "")) == "awaiting_manual_notes", "Manifest records open manual notes status")
	_assert(not bool(parsed.get("manual_window_review_done", true)), "Manifest does not claim manual window review done")


func _fake_evidence() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_visual_evidence.v1",
		"status": "needs_manual_window_review",
		"png_path": "tmp/station_route_visual_evidence.png",
		"manifest_path": "tmp/station_route_visual_evidence.json",
		"manual_window_review_required": true,
		"manual_window_review_done": false,
		"generated_evidence_board": true,
		"viewport_readback_available": false,
		"door_runtime_visual_state": "open",
		"door_layout_tone": "success",
		"all_gates_complete": true,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_709 manifest for writing")
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
