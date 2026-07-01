extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const TASK_726_MANIFEST_PATH: String = "res://tmp/station_route_one_screen_multiplayer_drill.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_f6_host_client_playtest_notes.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_727 Station Scenario F6/Host Client Playtest Notes ===")
	_test_docs_and_workbench()
	_test_snapshot_status_logic()
	_test_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_727: FAILED")
		quit(1)
		return
	print("TASK_727: ALL PASSED")
	quit(0)


func _test_docs_and_workbench() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_727 task file exists")
	_assert(task_text.contains("Station Scenario F6/Host Client Playtest Notes"), "Task documents station scenario playtest notes")
	_assert(contract_text.contains("Station Scenario F6/Host Client Playtest Notes"), "Interaction contract documents TASK_727")
	_assert(status_text.contains("TASK_727 - Station Scenario F6/Host Client Playtest Notes"), "Implementation status tracks TASK_727")
	_assert(roadmap_text.contains("TASK_727 - Station Scenario F6/Host Client Playtest Notes (implementiert)"), "Roadmap marks TASK_727 implemented")
	_assert(roadmap_text.contains("TASK_728 - Station Scenario Playtest Findings"), "Roadmap names TASK_728 followup")
	_assert(handbook_text.contains("TASK_727 - Station Scenario F6/Host Client Playtest Notes"), "Current handbook references TASK_727")
	_assert(handbook_text.contains('data-export-key="station_scenario_playtest.manifest_path"'), "Current handbook exports TASK_727 manifest path")
	_assert(FileAccess.file_exists(WORKBENCH_PATH), "TASK_727 workbench exists")
	_assert(workbench_text.contains("JSON exportieren"), "Workbench exposes JSON export button")
	_assert(workbench_text.contains('data-report-schema="sternenbuergerchen.html_workbench.v1"'), "Workbench uses HTML workbench schema")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.playtest_done"'), "Workbench exports playtest done check")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.host_client_two_window_reviewed"'), "Workbench exports host/client review check")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.issues.needs_performance_pass"'), "Workbench exports performance issue flag")


func _test_snapshot_status_logic() -> void:
	var missing_snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", {}, {}))
	_assert(_snapshot_is_read_only(missing_snapshot), "Missing-source snapshot remains read-only")
	_assert(String(missing_snapshot.get("status", "")) == "blocked", "Missing TASK_726 manifest blocks TASK_727")

	var open_snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), {}))
	_assert(String(open_snapshot.get("status", "")) == "needs_visible_playtest", "Open notes require visible playtest")
	_assert(not bool(open_snapshot.get("manual_review_done", true)), "Open notes do not claim manual review done")
	_assert(int(open_snapshot.get("required_check_count", 0)) >= 9, "Snapshot defines required playtest checks")
	_assert(String(open_snapshot.get("recommended_next_task", "")).contains("TASK_727"), "Open snapshot recommends continuing TASK_727")

	var issue_snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), _issue_notes()))
	_assert(String(issue_snapshot.get("status", "")) == "needs_followup_polish", "Issue notes request followup polish")
	_assert(int(issue_snapshot.get("active_issue_count", 0)) >= 1, "Issue snapshot counts active flags")
	_assert(String(issue_snapshot.get("recommended_next_task", "")).contains("TASK_728"), "Issue snapshot recommends findings followup")

	var clean_snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), _clean_notes()))
	_assert(String(clean_snapshot.get("status", "")) == "ready_for_findings", "Clean completed notes are ready for findings")
	_assert(bool(clean_snapshot.get("manual_review_done", false)), "Clean notes mark manual review done")
	_assert(int(clean_snapshot.get("active_issue_count", -1)) == 0, "Clean notes have no active issue flags")


func _test_manifest_write() -> void:
	_ensure_output_dir()
	var task_726_manifest: Dictionary = _read_json(TASK_726_MANIFEST_PATH)
	if task_726_manifest.is_empty():
		task_726_manifest = _fake_task_726_manifest()
	var snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", task_726_manifest, {}, {
		"drill_manifest_path": "tmp/station_route_one_screen_multiplayer_drill.json",
		"manifest_path": "tmp/station_scenario_f6_host_client_playtest_notes.json",
	}))
	snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_727 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_727", "Manifest records TASK_727")
	_assert(String(parsed.get("status", "")) == "needs_visible_playtest", "Manifest records open visible-playtest status")
	_assert(not bool(parsed.get("manual_review_done", true)), "Manifest does not claim visible playtest done")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _fake_task_726_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_one_screen_scenario_drill.v1",
		"task_id": "TASK_726",
		"status": "ready_for_f6_host_client_playtest",
		"scenario_path": "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _issue_notes() -> Dictionary:
	var notes: Dictionary = _clean_notes()
	notes["controls"]["station_scenario_playtest"]["issues"]["needs_performance_pass"] = true
	return notes


func _clean_notes() -> Dictionary:
	var playtest: Dictionary = {}
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
		playtest[id] = true
	playtest["issues"] = {
		"needs_route_readability_polish": false,
		"needs_hud_overlap_polish": false,
		"needs_performance_pass": false,
		"needs_host_client_sync_fix": false,
		"needs_command_feedback_polish": false,
		"needs_old_harness_modernization": false,
	}
	return {
		"controls": {
			"station_scenario_playtest": playtest,
		},
		"active_choices": {
			"station_scenario_playtest": {
				"rating": "good_enough",
			},
		},
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_727 manifest for writing")
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
