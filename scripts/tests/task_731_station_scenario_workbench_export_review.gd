extends SceneTree

const REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_workbench_export_review.gd")
const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_playtest_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_731_station_scenario_workbench_export_review.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_workbench_export_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_731 Station Scenario Workbench Export Review ===")
	_test_docs_and_static_routing()
	_test_open_export_status()
	_test_issue_export_routes_to_post_730_tasks()
	_test_clean_export_ready_for_next_slice()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_731: FAILED")
		quit(1)
		return
	print("TASK_731: ALL PASSED")
	quit(0)


func _test_docs_and_static_routing() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var findings_text: String = _read_text("res://scripts/mission/station_scenario_playtest_findings.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_731 task file exists")
	_assert(task_text.contains("Station Scenario Workbench Export Review"), "Task documents workbench export review")
	_assert(contract_text.contains("Station Scenario Workbench Export Review"), "Interaction contract documents TASK_731")
	_assert(status_text.contains("TASK_731 - Station Scenario Workbench Export Review"), "Implementation status tracks TASK_731")
	_assert(roadmap_text.contains("TASK_731 - Station Scenario Workbench Export Review (implementiert)"), "Roadmap marks TASK_731 implemented")
	_assert(handbook_text.contains("TASK_731 - Station Scenario Workbench Export Review"), "Current handbook references TASK_731")
	_assert(handbook_text.contains('data-export-key="station_scenario_workbench_export_review.manifest_path"'), "Current handbook exports TASK_731 manifest path")
	_assert(findings_text.contains("TASK_732 - Station Scenario Route Cue Polish"), "TASK_728 route findings no longer point to TASK_729")
	_assert(findings_text.contains("TASK_740 - Scenario Harness Modernization"), "TASK_728 harness findings route beyond TASK_739")


func _test_open_export_status() -> void:
	var snapshot: Dictionary = Dictionary(REVIEW_SCRIPT.call("build_snapshot", {}, {}))
	_assert(_snapshot_is_read_only(snapshot), "Missing export review remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_workbench_export", "Missing export requires workbench export")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_727"), "Missing export recommends TASK_727")
	_assert(int(snapshot.get("manual_issue_count", 0)) >= 1, "Missing export creates manual issue")


func _test_issue_export_routes_to_post_730_tasks() -> void:
	var notes: Dictionary = _issue_notes_manifest()
	var findings: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", notes))
	var snapshot: Dictionary = Dictionary(REVIEW_SCRIPT.call("build_snapshot", notes, findings))
	_assert(String(findings.get("status", "")) == "needs_targeted_polish", "TASK_728 issue notes require targeted polish")
	_assert(String(findings.get("recommended_next_task", "")).contains("TASK_734"), "TASK_728 performance issue routes to TASK_734")
	_assert(String(snapshot.get("status", "")) == "needs_followup_task_selection", "TASK_731 issue export selects followup task")
	_assert(int(snapshot.get("action_item_count", 0)) == 1, "TASK_731 exports one action item")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_734"), "TASK_731 recommends post-TASK_730 performance task")
	_assert(_snapshot_is_read_only(snapshot), "Issue export review is read-only")


func _test_clean_export_ready_for_next_slice() -> void:
	var notes: Dictionary = _clean_notes_manifest()
	var findings: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", notes))
	var snapshot: Dictionary = Dictionary(REVIEW_SCRIPT.call("build_snapshot", notes, findings))
	_assert(String(findings.get("status", "")) == "ready_for_next_playable_slice", "TASK_728 clean notes are ready")
	_assert(String(snapshot.get("status", "")) == "ready_for_next_playable_slice", "TASK_731 clean export is ready for next playable slice")
	_assert(int(snapshot.get("action_item_count", -1)) == 0, "Clean export has no action items")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_732"), "Clean export recommends next playable Station slice")
	_assert(_snapshot_is_read_only(snapshot), "Clean export review is read-only")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var open_notes: Dictionary = _open_notes_manifest()
	var findings: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", open_notes))
	var snapshot: Dictionary = Dictionary(REVIEW_SCRIPT.call("build_snapshot", open_notes, findings, {
		"notes_manifest_path": "tmp/station_scenario_f6_host_client_playtest_notes.json",
		"findings_manifest_path": "tmp/station_scenario_playtest_findings.json",
		"manifest_path": "tmp/station_scenario_workbench_export_review.json",
	}))
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_731 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_731", "Manifest records TASK_731")
	_assert(String(parsed.get("status", "")) == "needs_workbench_export", "Manifest records open export status")
	_assert(_snapshot_is_read_only(parsed), "Manifest stays read-only")


func _open_notes_manifest() -> Dictionary:
	var notes: Dictionary = _clean_notes_manifest()
	notes["manual_review_done"] = false
	notes["playtest_done"] = false
	notes["status"] = "needs_visible_playtest"
	notes["completed_check_count"] = 0
	for check in Array(notes.get("required_checks", [])):
		Dictionary(check)["checked"] = false
	return notes


func _issue_notes_manifest() -> Dictionary:
	var notes: Dictionary = _clean_notes_manifest()
	notes["status"] = "needs_followup_polish"
	notes["active_issue_count"] = 1
	var flags: Array = Array(notes.get("issue_flags", []))
	for index in range(flags.size()):
		var flag: Dictionary = Dictionary(flags[index])
		if String(flag.get("id", "")) == "needs_performance_pass":
			flag["active"] = true
			flags[index] = flag
	notes["issue_flags"] = flags
	return notes


func _clean_notes_manifest() -> Dictionary:
	var checks: Array = []
	for id in [
		"playtest_done",
		"real_f6_window_reviewed",
		"host_client_two_window_reviewed",
		"aa_door_com_cargo_route_readable",
		"door_computer_cargo_cues_obvious",
		"fireteam_orders_feel_fast",
		"performance_feels_fast",
		"no_hud_overlap_blocks_map",
		"wrong_team_or_bravo_context_clear",
	]:
		checks.append({"id": id, "checked": true, "read_only": true, "ui_sets_gameplay_truth": false})
	var flags: Array = []
	for id in [
		"needs_route_readability_polish",
		"needs_hud_overlap_polish",
		"needs_performance_pass",
		"needs_host_client_sync_fix",
		"needs_command_feedback_polish",
		"needs_old_harness_modernization",
	]:
		flags.append({"id": id, "label": id, "active": false, "read_only": true, "ui_sets_gameplay_truth": false})
	return {
		"schema": "sternenbuergerchen.station_scenario_f6_host_client_playtest_notes.v1",
		"task_id": "TASK_727",
		"status": "ready_for_findings",
		"rating": "good_enough",
		"manual_review_required": true,
		"manual_review_done": true,
		"playtest_done": true,
		"completed_check_count": checks.size(),
		"required_check_count": checks.size(),
		"active_issue_count": 0,
		"required_checks": checks,
		"issue_flags": flags,
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
		_assert(false, "Can open TASK_731 manifest for writing")
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
