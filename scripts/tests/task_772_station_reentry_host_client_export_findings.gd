extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_host_client_export_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_772_station_reentry_host_client_export_findings.md"
const TASK_771_PATH: String = "res://docs/tasks/TASK_771_station_reentry_visible_host_client_playtest_export.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_host_client_export_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_772 Station Reentry Host Client Export Findings ===")
	_test_docs_contract_and_report()
	_test_missing_manual_export_routes_back_to_task_771()
	_test_complete_export_routes_to_task_773()
	_test_issue_flags_route_to_targeted_tasks()
	_write_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_772: FAILED")
		quit(1)
		return
	print("TASK_772: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_772 task file exists")
	_assert(task_text.contains("Station Reentry Host Client Export Findings"), "TASK_772 task names export findings")
	_assert(FileAccess.file_exists(TASK_771_PATH), "TASK_771 task remains available")
	_assert(status_text.contains("TASK_772 - Station Reentry Host Client Export Findings"), "Implementation status tracks TASK_772")
	_assert(roadmap_text.contains("TASK_772 - Station Reentry Host Client Export Findings (implementiert)"), "Roadmap marks TASK_772 implemented")
	_assert(contract_text.contains("Station-Reentry-Host-Client-Export-Findings"), "Mission command feedback contract documents TASK_772")
	_assert(report_text.contains("Aktueller Griff: TASK_780"), "Reentry handbook advances to TASK_780 current")
	_assert(report_text.contains('data-export-key="reentry_host_client_findings.manual_review_done"'), "Reentry handbook exports TASK_772 manual review check")
	_assert(report_text.contains("station_reentry_host_client_export_findings.json"), "Reentry handbook names TASK_772 findings manifest")


func _test_missing_manual_export_routes_back_to_task_771() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_export_packet(), {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Open-export findings snapshot is read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_host_client_export_findings.v1", "TASK_772 schema is stable")
	_assert(String(snapshot.get("status", "")) == "needs_visible_host_client_export", "Open manual export routes to visible export")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_771"), "Open manual export recommends TASK_771")
	_assert(int(snapshot.get("completed_check_count", -1)) == 0, "Open notes have zero completed checks")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("host_window_open"), "Missing checks include host window")


func _test_complete_export_routes_to_task_773() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_export_packet(), _build_complete_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_next_station_iteration", "Complete notes route to next station iteration")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_774"), "Complete notes recommend TASK_774")
	_assert(int(snapshot.get("completed_check_count", 0)) == int(snapshot.get("required_check_count", -1)), "All checks are complete")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "No missing checks remain")
	_assert(_snapshot_is_read_only(snapshot), "Complete findings snapshot remains read-only")


func _test_issue_flags_route_to_targeted_tasks() -> void:
	var notes: Dictionary = _build_complete_notes()
	notes["reentry_host_client_findings"]["issues"] = {"host_client_next_order_mismatch": true}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_export_packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_reentry_host_client_polish", "Issue notes route to targeted polish")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_770"), "Next-order issue routes to TASK_770")
	_assert(int(snapshot.get("active_issue_count", 0)) == 1, "One active issue is counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 1, "One action item is created")


func _write_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_export_packet(), {}, {}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_772 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_772 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_772", "Manifest records TASK_772")
	_assert(String(parsed.get("status", "")) == "needs_visible_host_client_export", "Manifest records open visible export status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _build_export_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_visible_host_client_playtest_export.v1",
		"task_id": "TASK_771",
		"source_task_id": "TASK_770",
		"status": "ready_to_capture_station_reentry_host_client",
		"target_id": "station_reentry_host_client_visible_export",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_command": false,
		"creates_navigation": false,
		"sync_gate": "pass",
		"expected_host_next_order_text": "WP 1/1 MOVE | WARTET AUF GO | Ziel 544,288 | PREVIEW Dist 120m | ETA~2s | RISK ? no intel",
		"expected_client_next_order_text": "WP 1/1 MOVE | WARTET AUF GO | Ziel 544,288 | PREVIEW Dist 120m | ETA~2s | RISK ? no intel",
		"expected_station_route_line": "ROUTE AA > DOOR > COM > CARGO | NEXT AA",
		"expected_station_cue_line": "CUE AA: BLUE naeher ran | 3.9km",
		"expected_same_next_order": true,
		"expected_same_route_line": true,
		"expected_same_cue_line": true,
		"expected_peer_context_distinct": true,
	}


func _build_complete_notes() -> Dictionary:
	var findings: Dictionary = {
		"manual_review_done": true,
		"visible_export_done": true,
	}
	for id in [
		"host_window_open",
		"client_window_open",
		"host_client_same_next_order_visible",
		"host_client_route_cue_same_visible",
		"peer_team_context_distinct_visible",
		"first_mission_preview_visible_before_go",
		"export_json_saved",
	]:
		findings[id] = true
	findings["issues"] = {}
	return {"reentry_host_client_findings": findings}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true))


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
