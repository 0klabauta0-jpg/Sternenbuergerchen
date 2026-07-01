extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_playtest_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_728_station_scenario_playtest_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const NOTES_MANIFEST_PATH: String = "res://tmp/station_scenario_f6_host_client_playtest_notes.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_playtest_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_728 Station Scenario Playtest Findings ===")
	_test_docs()
	_test_missing_notes_block()
	_test_open_notes_need_visible_playtest()
	_test_issue_notes_create_action_items()
	_test_clean_notes_ready_for_next_slice()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_728: FAILED")
		quit(1)
		return
	print("TASK_728: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_728 task file exists")
	_assert(task_text.contains("Station Scenario Playtest Findings"), "Task documents Station Scenario Playtest Findings")
	_assert(contract_text.contains("Station Scenario Playtest Findings"), "Interaction contract documents TASK_728")
	_assert(status_text.contains("TASK_728 - Station Scenario Playtest Findings"), "Implementation status tracks TASK_728")
	_assert(roadmap_text.contains("TASK_728 - Station Scenario Playtest Findings (implementiert)"), "Roadmap marks TASK_728 implemented")
	_assert(roadmap_text.contains("TASK_729 - Station Scenario Visible Playtest Run Packet"), "Roadmap names TASK_729 followup")
	_assert(handbook_text.contains("TASK_728 - Station Scenario Playtest Findings"), "Current handbook references TASK_728")
	_assert(handbook_text.contains('data-export-key="station_scenario_playtest_findings.manifest_path"'), "Current handbook exports TASK_728 manifest path")


func _test_missing_notes_block() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing-notes findings snapshot remains read-only")
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_scenario_playtest_findings.v1", "TASK_728 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_727 notes block TASK_728")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing notes produce blocker")


func _test_open_notes_need_visible_playtest() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _open_notes_manifest()))
	_assert(_snapshot_is_read_only(snapshot), "Open-notes findings snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visible_playtest", "Open TASK_727 notes require visible playtest")
	_assert(int(snapshot.get("manual_note_count", 0)) >= 1, "Open notes produce manual finding")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_727"), "Open notes recommend running TASK_727")


func _test_issue_notes_create_action_items() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _issue_notes_manifest()))
	_assert(_snapshot_is_read_only(snapshot), "Issue-notes findings snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_targeted_polish", "Issue notes request targeted polish")
	_assert(int(snapshot.get("polish_issue_count", 0)) >= 2, "Issue notes count polish findings")
	_assert(int(snapshot.get("action_item_count", 0)) >= 2, "Issue notes create action items")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_729"), "Issue notes recommend TASK_729")


func _test_clean_notes_ready_for_next_slice() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _clean_notes_manifest()))
	_assert(_snapshot_is_read_only(snapshot), "Clean-notes findings snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "ready_for_next_playable_slice", "Clean notes are ready for next playable slice")
	_assert(int(snapshot.get("polish_issue_count", -1)) == 0, "Clean notes have no polish findings")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_729"), "Clean notes recommend next playable slice")


func _test_actual_manifest_write() -> void:
	_ensure_output_dir()
	var notes_manifest: Dictionary = _read_json(NOTES_MANIFEST_PATH)
	if notes_manifest.is_empty():
		notes_manifest = _open_notes_manifest()
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", notes_manifest, {
		"notes_manifest_path": "tmp/station_scenario_f6_host_client_playtest_notes.json",
		"manifest_path": "tmp/station_scenario_playtest_findings.json",
	}))
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_728 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_728", "Manifest records TASK_728")
	_assert(String(parsed.get("status", "")) == "needs_visible_playtest", "Manifest preserves open visible-playtest status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _open_notes_manifest() -> Dictionary:
	var manifest: Dictionary = _base_notes_manifest()
	manifest["status"] = "needs_visible_playtest"
	manifest["manual_review_done"] = false
	manifest["playtest_done"] = false
	manifest["completed_check_count"] = 0
	manifest["active_issue_count"] = 0
	manifest["issue_flags"] = _issue_flags({})
	return manifest


func _issue_notes_manifest() -> Dictionary:
	var manifest: Dictionary = _base_notes_manifest()
	manifest["status"] = "needs_followup_polish"
	manifest["rating"] = "needs_polish"
	manifest["manual_review_done"] = true
	manifest["playtest_done"] = true
	manifest["completed_check_count"] = 9
	manifest["active_issue_count"] = 2
	manifest["issue_flags"] = _issue_flags({
		"needs_hud_overlap_polish": true,
		"needs_performance_pass": true,
	})
	return manifest


func _clean_notes_manifest() -> Dictionary:
	var manifest: Dictionary = _base_notes_manifest()
	manifest["status"] = "ready_for_findings"
	manifest["rating"] = "good_enough"
	manifest["manual_review_done"] = true
	manifest["playtest_done"] = true
	manifest["completed_check_count"] = 9
	manifest["active_issue_count"] = 0
	manifest["issue_flags"] = _issue_flags({})
	return manifest


func _base_notes_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_scenario_f6_host_client_playtest_notes.v1",
		"task_id": "TASK_727",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"required_check_count": 9,
		"source_drill_status": "ready_for_f6_host_client_playtest",
	}


func _issue_flags(active_by_id: Dictionary) -> Array:
	var result: Array = []
	for id in [
		"needs_route_readability_polish",
		"needs_hud_overlap_polish",
		"needs_performance_pass",
		"needs_host_client_sync_fix",
		"needs_command_feedback_polish",
		"needs_old_harness_modernization",
	]:
		result.append({
			"id": id,
			"label": id,
			"active": bool(active_by_id.get(id, false)),
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		})
	return result


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_728 manifest for writing")
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
