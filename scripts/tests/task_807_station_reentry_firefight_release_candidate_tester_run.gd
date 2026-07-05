extends SceneTree

const TESTER_RUN_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_tester_run.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_807_station_reentry_firefight_release_candidate_tester_run.md"
const TASK_806_PATH: String = "res://docs/tasks/TASK_806_station_reentry_firefight_release_candidate_handoff_packet.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_tester_run.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_807 Station Reentry Firefight Release Candidate Tester Run ===")
	_test_docs_contract_and_report()
	_test_missing_handoff_blocks()
	_test_invalid_handoff_blocks()
	_test_unready_handoff_blocks()
	_test_open_tester_run_routes_to_task_807()
	_test_incomplete_checks_route_to_completion()
	_test_issue_flags_route_to_action_items()
	_test_clean_tester_run_routes_to_acceptance()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_807: FAILED")
		quit(1)
		return
	print("TASK_807: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_807 task file exists")
	_assert(FileAccess.file_exists(TASK_806_PATH), "TASK_806 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Tester Run"), "TASK_807 task names tester run")
	_assert(status_text.contains("TASK_807 - Station Reentry Firefight Release Candidate Tester Run"), "Implementation status tracks TASK_807")
	_assert(roadmap_text.contains("TASK_807 - Station Reentry Firefight Release Candidate Tester Run (implementiert)"), "Roadmap marks TASK_807 implemented")
	_assert(roadmap_text.contains("TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance"), "Roadmap advances to TASK_808")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Tester-Run"), "Mission command feedback contract documents TASK_807")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_tester_run.json"), "Reentry handbook names TASK_807 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_tester_run.tester_run_done"'), "Reentry handbook exports TASK_807 done check")


func _test_missing_handoff_blocks() -> void:
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_tester_run.v1", "TASK_807 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_handoff_packet", "Missing TASK_806 handoff blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_806"), "Missing handoff recommends TASK_806")
	_assert(not bool(snapshot.get("release_candidate_tester_run_ready", true)), "Missing source is not tester-run-ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-source tester run remains read-only")


func _test_invalid_handoff_blocks() -> void:
	var source: Dictionary = _handoff(true)
	source["schema"] = "wrong"
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", source, _notes(false, false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_handoff_packet", "Invalid TASK_806 schema blocks")
	_assert(not bool(snapshot.get("source_valid", true)), "Invalid handoff source is reported")
	_assert(_snapshot_is_read_only(snapshot), "Invalid-source tester run remains read-only")


func _test_unready_handoff_blocks() -> void:
	var source: Dictionary = _handoff(false)
	source["status"] = "needs_handoff_packet"
	source["recommended_next_task"] = "TASK_806 - complete release candidate handoff packet"
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", source, _notes(false, false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_handoff_packet_ready", "Unready TASK_806 source blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_806"), "Unready source keeps TASK_806 recommendation")
	_assert(not bool(snapshot.get("release_candidate_tester_run_ready", true)), "Unready source is not tester-run-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source tester run remains read-only")


func _test_open_tester_run_routes_to_task_807() -> void:
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", _handoff(true), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_release_candidate_tester_run", "Open tester run routes to TASK_807")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_807"), "Open tester run recommends TASK_807")
	_assert(not bool(snapshot.get("tester_run_done", true)), "Open tester run does not claim done")
	_assert(not bool(snapshot.get("fresh_release_exe_started", true)), "Open tester run does not claim EXE started")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("singleplayer_homebase_actionable"), "Open tester run reports missing singleplayer check")
	_assert(_snapshot_is_read_only(snapshot), "Open tester run remains read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var notes: Dictionary = _notes(true, true, true, ["handoff_packet_used", "fresh_release_exe_started"], [])
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", _handoff(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_tester_run_completion", "Incomplete tester checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_807"), "Incomplete checks recommend TASK_807 completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 2, "Completed tester checks are counted")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("first_preview_readable"), "Missing checks include first preview")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete tester run remains read-only")


func _test_issue_flags_route_to_action_items() -> void:
	var notes: Dictionary = _notes(true, true, true, _all_check_ids(), ["performance_slow", "roles_confusing"])
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", _handoff(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_tester_run_polish", "Issue flags route to targeted tester-run polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active tester issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two tester action items are created")
	_assert(_action_items_contain_task(Array(snapshot.get("action_items", [])), "TASK_769"), "Performance issue routes to performance feel pass")
	_assert(_snapshot_is_read_only(snapshot), "Issue tester run remains read-only")


func _test_clean_tester_run_routes_to_acceptance() -> void:
	var snapshot: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("build_snapshot", _handoff(true), _notes(true, true, true, _all_check_ids(), []), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_candidate_tester_run_acceptance", "Clean tester run routes to acceptance")
	_assert(bool(snapshot.get("release_candidate_tester_run_ready", false)), "Tester-run ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_808"), "Clean tester run recommends TASK_808")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "Clean tester run has no missing checks")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean tester run has no active issues")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Tester run carries release EXE")
	_assert(_snapshot_is_read_only(snapshot), "Clean tester run remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(TESTER_RUN_SCRIPT.call("write_manifest", OUTPUT_MANIFEST_PATH, _handoff(true), _notes(true, true, true, _all_check_ids(), []), {}))
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_807 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_807", "Manifest records TASK_807")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_806", "Manifest records TASK_806 source")
	_assert(String(parsed.get("status", "")) == "ready_for_release_candidate_tester_run_acceptance", "Manifest preserves tester-run status")
	_assert(String(manifest.get("manifest_path", "")) == OUTPUT_MANIFEST_PATH, "write_manifest returns requested manifest path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _handoff(ready: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_release_candidate_handoff_packet.v1",
		"task_id": "TASK_806",
		"source_task_id": "TASK_805",
		"status": "ready_for_release_candidate_tester_run" if ready else "needs_handoff_packet",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"release_candidate_handoff_ready": ready,
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
		"open_risks": ["Kein automatischer Screenshot-Entscheid."],
		"handoff_notes": {
			"singleplayer_start_step": "Start fresh EXE, click Einzelspieler, verify Homebase is actionable.",
			"host_client_start_step": "Launch Host/Client review helper and compare both windows.",
			"role_expectations": "HOST P1 ALPHA / CLIENT P2 BRAVO.",
			"shortcut_warning": "Use the fresh release folder, not an old taskbar link.",
			"smoke_gate_summary": "TASK_804 smoke and TASK_805 delivery review green.",
			"risk_summary": "Manual screenshot judgement remains a known risk.",
			"next_tester_action": "Run TASK_807 tester run from this packet.",
		},
		"recommended_next_task": "TASK_807 - Station Reentry Firefight Release Candidate Tester Run",
	}


func _notes(done: bool, reviewed: bool, exe_started: bool, checked_ids: Array, issue_ids: Array) -> Dictionary:
	var values: Dictionary = {
		"tester_run_done": done,
		"tester_run_reviewed": reviewed,
		"fresh_release_exe_started": exe_started,
		"tester_summary": "Tester run completed from handoff packet.",
		"singleplayer_note": "Homebase actionable.",
		"host_client_note": "Host/Client roles readable.",
		"mission_note": "Mission, first preview, GO and firefight reacted.",
		"performance_note": "Fast enough for this release-candidate pass.",
		"next_note": "Proceed to TASK_808 acceptance.",
	}
	for id in checked_ids:
		values[String(id)] = true
	var issues: Dictionary = {}
	for id in issue_ids:
		issues[String(id)] = true
	values["issues"] = issues
	return {"reentry_firefight_release_candidate_tester_run": values}


func _all_check_ids() -> Array:
	return [
		"handoff_packet_used",
		"fresh_release_exe_started",
		"singleplayer_homebase_actionable",
		"dropship_payload_visible",
		"mission_start_reachable",
		"host_client_started",
		"host_client_roles_readable",
		"first_preview_readable",
		"first_go_firefight_reacts",
		"exit_or_debrief_visible",
		"performance_feels_fast",
		"hud_does_not_block",
		"tester_notes_exported",
	]


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


func _action_items_contain_task(action_items: Array, task_id: String) -> bool:
	for item_variant in action_items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		if String(Dictionary(item_variant).get("recommended_task", "")).contains(task_id):
			return true
	return false


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
