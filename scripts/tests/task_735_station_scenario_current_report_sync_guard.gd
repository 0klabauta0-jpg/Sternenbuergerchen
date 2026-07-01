extends SceneTree

const TASK_PATH: String = "res://docs/tasks/TASK_735_station_scenario_current_report_sync_guard.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const OLD_REPORT_PATH_TOKEN: String = "project_current_state_handbook_refresh_2026_06_30.html"
const TASK_707_TEST_PATH: String = "res://scripts/tests/task_707_mission_door_computer_cargo_smoke.gd"
const TASK_714_TEST_PATH: String = "res://scripts/tests/task_714_station_route_multiplayer_scenario_guard.gd"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_current_report_sync_guard.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_735 Station Scenario Current Report Sync Guard ===")
	_test_docs_and_report_links()
	_write_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_735: FAILED")
		quit(1)
		return
	print("TASK_735: ALL PASSED")
	quit(0)


func _test_docs_and_report_links() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var task_707_text: String = _read_text(TASK_707_TEST_PATH)
	var task_714_text: String = _read_text(TASK_714_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_735 task file exists")
	_assert(task_text.contains("Station Scenario Current Report Sync Guard"), "Task documents current report sync guard")
	_assert(contract_text.contains("Station Scenario Current Report Sync Guard"), "Interaction contract documents TASK_735")
	_assert(status_text.contains("TASK_735 - Station Scenario Current Report Sync Guard"), "Implementation status tracks TASK_735")
	_assert(roadmap_text.contains("TASK_735 - Station Scenario Current Report Sync Guard (implementiert)"), "Roadmap marks TASK_735 implemented")
	_assert(report_text.contains("TASK_735 - Station Scenario Current Report Sync Guard"), "Current handbook references TASK_735")
	_assert(report_text.contains('data-export-key="station_scenario_current_report_sync_guard.manifest_path"'), "Current handbook exports TASK_735 manifest")
	_assert(task_707_text.contains("project_current_state_handbook_2026_07_01.html"), "TASK_707 uses current handbook report")
	_assert(task_714_text.contains("project_current_state_handbook_2026_07_01.html"), "TASK_714 uses current handbook report")
	_assert(not task_707_text.contains(OLD_REPORT_PATH_TOKEN), "TASK_707 no longer uses stale report")
	_assert(not task_714_text.contains(OLD_REPORT_PATH_TOKEN), "TASK_714 no longer uses stale report")
	_assert(report_text.contains('data-export-key="playtest.door_computer_cargo_smoke"'), "Current report exports TASK_707 playtest check")
	_assert(report_text.contains('data-export-key="station_route_multiplayer_scenario_guard.manifest_path"'), "Current report exports TASK_714 manifest path")
	_assert(report_text.contains('data-export-key="status.task_707_done"'), "Current report exports TASK_707 status")
	_assert(report_text.contains('data-export-key="status.task_714_done"'), "Current report exports TASK_714 status")


func _write_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_scenario_current_report_sync_guard.v1",
		"task_id": "TASK_735",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"current_report_path": CURRENT_REPORT_PATH,
		"task_707_report_rebased": _read_text(TASK_707_TEST_PATH).contains("project_current_state_handbook_2026_07_01.html"),
		"task_714_report_rebased": _read_text(TASK_714_TEST_PATH).contains("project_current_state_handbook_2026_07_01.html"),
		"task_707_anchor": "playtest.door_computer_cargo_smoke",
		"task_714_anchor": "station_route_multiplayer_scenario_guard.manifest_path",
		"manual_review_required": false,
		"recommended_next_task": "TASK_727 visible playtest export or TASK_736 command feedback polish from real notes",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_735 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_735 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_735", "Manifest records TASK_735")
	_assert(bool(parsed.get("read_only", false)) and not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest remains read-only")


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
