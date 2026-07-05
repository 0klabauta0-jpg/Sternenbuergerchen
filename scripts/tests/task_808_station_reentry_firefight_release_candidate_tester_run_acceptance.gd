extends SceneTree

const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_tester_run_acceptance.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_808_station_reentry_firefight_release_candidate_tester_run_acceptance.md"
const TASK_807_PATH: String = "res://docs/tasks/TASK_807_station_reentry_firefight_release_candidate_tester_run.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_tester_run_acceptance.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_808 Station Reentry Firefight Release Candidate Tester Run Acceptance ===")
	_test_docs_contract_and_report()
	_test_missing_tester_run_blocks()
	_test_invalid_tester_run_blocks()
	_test_open_tester_run_routes_back_to_task_807()
	_test_incomplete_checks_route_to_completion()
	_test_issue_flags_route_to_first_action_item()
	_test_clean_tester_run_is_accepted()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_808: FAILED")
		quit(1)
		return
	print("TASK_808: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_808 task file exists")
	_assert(FileAccess.file_exists(TASK_807_PATH), "TASK_807 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Tester Run Acceptance"), "TASK_808 task names tester-run acceptance")
	_assert(status_text.contains("TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance"), "Implementation status tracks TASK_808")
	_assert(roadmap_text.contains("TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance (implementiert)"), "Roadmap marks TASK_808 implemented")
	_assert(roadmap_text.contains("TASK_809 - Station Reentry Release Candidate Playability Polish Backlog"), "Roadmap advances to TASK_809")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Tester-Run-Acceptance"), "Mission command feedback contract documents TASK_808")
	_assert(report_text.contains("Aktueller Griff: TASK_808"), "Reentry handbook marks TASK_808 current")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_tester_run_acceptance.json"), "Reentry handbook names TASK_808 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_tester_run_acceptance.accepted_for_release_candidate_tester_run"'), "Reentry handbook exports TASK_808 accepted check")


func _test_missing_tester_run_blocks() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_tester_run_acceptance.v1", "TASK_808 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_tester_run", "Missing TASK_807 tester run blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_807"), "Missing tester run recommends TASK_807")
	_assert(not bool(snapshot.get("accepted_for_release_candidate_tester_run", true)), "Missing tester run is not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Missing-source acceptance remains read-only")


func _test_invalid_tester_run_blocks() -> void:
	var source: Dictionary = _tester_run("ready_for_release_candidate_tester_run_acceptance", true, true, true, [], 0, [])
	source["schema"] = "wrong"
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", source, {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_tester_run", "Invalid TASK_807 schema blocks")
	_assert(not bool(snapshot.get("source_valid", true)), "Invalid tester-run source is reported")
	_assert(_failed_ids(snapshot).has("source_read_only") == false, "Invalid but read-only source does not invent source-read-only failure")
	_assert(_snapshot_is_read_only(snapshot), "Invalid-source acceptance remains read-only")


func _test_open_tester_run_routes_back_to_task_807() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _tester_run("needs_release_candidate_tester_run", false, false, false, ["singleplayer_homebase_actionable"], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "needs_release_candidate_tester_run", "Open tester run routes back to TASK_807")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_807"), "Open tester run recommends TASK_807")
	_assert(_failed_ids(snapshot).has("tester_run_ready"), "Open tester run fails ready gate")
	_assert(_failed_ids(snapshot).has("tester_run_done"), "Open tester run fails done gate")
	_assert(_snapshot_is_read_only(snapshot), "Open tester-run acceptance remains read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _tester_run("needs_tester_run_completion", true, true, true, ["first_preview_readable"], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "needs_tester_run_completion", "Incomplete checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_807"), "Incomplete checks recommend TASK_807 completion")
	_assert(Array(snapshot.get("source_missing_check_ids", [])).has("first_preview_readable"), "Source missing checks are preserved")
	_assert(_failed_ids(snapshot).has("no_missing_checks"), "Incomplete checks fail no-missing gate")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete acceptance remains read-only")


func _test_issue_flags_route_to_first_action_item() -> void:
	var action_items: Array = [
		{
			"id": "performance_slow",
			"label": "Performance fuehlt sich zu langsam an",
			"recommended_task": "TASK_769 - Station Reentry Performance Feel Pass",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		}
	]
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _tester_run("needs_targeted_tester_run_polish", true, true, true, [], 1, action_items), {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_tester_run_polish", "Active issues route to targeted polish")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_769"), "First action item controls targeted route")
	_assert(int(snapshot.get("source_active_issue_count", 0)) == 1, "Source active issues are preserved")
	_assert(_failed_ids(snapshot).has("no_active_issues"), "Active issues fail no-active gate")
	_assert(_snapshot_is_read_only(snapshot), "Issue acceptance remains read-only")


func _test_clean_tester_run_is_accepted() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _tester_run("ready_for_release_candidate_tester_run_acceptance", true, true, true, [], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "accepted_for_release_candidate_tester_run", "Clean tester run is accepted")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_809"), "Accepted tester run recommends TASK_809")
	_assert(bool(snapshot.get("accepted_for_release_candidate_tester_run", false)), "Accepted flag is true")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "Accepted tester run has no failed gates")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Acceptance preserves release EXE path")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("write_manifest", OUTPUT_MANIFEST_PATH, _tester_run("ready_for_release_candidate_tester_run_acceptance", true, true, true, [], 0, []), {}))
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_808 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_808", "Manifest records TASK_808")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_807", "Manifest records TASK_807 source")
	_assert(String(parsed.get("status", "")) == "accepted_for_release_candidate_tester_run", "Manifest preserves accepted status")
	_assert(String(manifest.get("manifest_path", "")) == OUTPUT_MANIFEST_PATH, "write_manifest returns requested manifest path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _tester_run(status: String, done: bool, reviewed: bool, exe_started: bool, missing_checks: Array, active_issues: int, action_items: Array) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_release_candidate_tester_run.v1",
		"task_id": "TASK_807",
		"source_task_id": "TASK_806",
		"status": status,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"release_candidate_tester_run_ready": status == "ready_for_release_candidate_tester_run_acceptance",
		"tester_run_done": done,
		"tester_run_reviewed": reviewed,
		"fresh_release_exe_started": exe_started,
		"missing_check_ids": missing_checks.duplicate(true),
		"active_issue_count": active_issues,
		"action_items": action_items.duplicate(true),
		"release_dir": "C:/dev/Sternenbuergerchen_rel",
		"exe_path": "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe",
		"pck_path": "C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.pck",
		"scenario_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"commands": {
			"run_release_exe": "\"C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe\"",
			"runtime_release_export": "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1",
			"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch",
			"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14",
		},
		"tester_notes": {
			"tester_summary": "Tester run completed from handoff packet.",
			"singleplayer_note": "Homebase actionable.",
			"host_client_note": "Host/Client roles readable.",
			"mission_note": "Mission, first preview, GO and firefight reacted.",
			"performance_note": "Fast enough for this release-candidate pass.",
			"next_note": "Proceed to TASK_808 acceptance.",
		},
		"open_risks": ["Manual screenshot judgement remains a known risk."],
	}


func _failed_ids(snapshot: Dictionary) -> Array:
	return Array(snapshot.get("failed_gate_ids", []))


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


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
