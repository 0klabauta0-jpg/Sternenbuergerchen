extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_playtest_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_801_station_reentry_firefight_release_candidate_playtest_findings.md"
const TASK_800_PATH: String = "res://docs/tasks/TASK_800_station_reentry_firefight_multiplayer_release_candidate_packet.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_playtest_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_801 Station Reentry Firefight Release Candidate Playtest Findings ===")
	_test_docs_contract_and_report()
	_test_missing_packet_blocks()
	_test_open_visible_playtest_routes_back_to_task_800()
	_test_incomplete_checks_route_to_completion()
	_test_issue_findings_route_to_first_action_item()
	_test_clean_findings_route_to_acceptance()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_801: FAILED")
		quit(1)
		return
	print("TASK_801: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_801 task file exists")
	_assert(FileAccess.file_exists(TASK_800_PATH), "TASK_800 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Playtest Findings"), "TASK_801 task names release candidate findings")
	_assert(status_text.contains("TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings"), "Implementation status tracks TASK_801")
	_assert(roadmap_text.contains("TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings (implementiert)"), "Roadmap marks TASK_801 implemented")
	_assert(roadmap_text.contains("TASK_802 - Station Reentry Firefight Release Candidate Acceptance"), "Roadmap advances to TASK_802")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Playtest-Findings"), "Mission command feedback contract documents TASK_801")
	_assert(report_text.contains("Aktueller Griff: TASK_801"), "Reentry handbook marks TASK_801 current")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_playtest_findings.json"), "Reentry handbook names TASK_801 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_findings.visible_playtest_done"'), "Reentry handbook exports TASK_801 visible playtest check")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_playtest_findings.v1", "TASK_801 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_800 packet blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_800"), "Missing packet recommends TASK_800")
	_assert(not bool(snapshot.get("packet_ready", true)), "Missing packet is not ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-packet findings remain read-only")


func _test_open_visible_playtest_routes_back_to_task_800() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _packet(), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_release_candidate_playtest", "Open visible playtest routes back to TASK_800")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_800"), "Open visible playtest recommends TASK_800 run")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open review does not claim manual done")
	_assert(not bool(snapshot.get("visible_playtest_done", true)), "Open review does not claim visible playtest done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("singleplayer_homebase_not_blocked"), "Open review reports missing checks")
	_assert(_snapshot_is_read_only(snapshot), "Open findings remain read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var notes: Dictionary = _notes(true, true, true, true, ["singleplayer_homebase_not_blocked", "host_client_windows_open"], [])
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_release_candidate_playtest_completion", "Incomplete checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_800"), "Incomplete checks recommend TASK_800 completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 2, "Completed checks are counted")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("dropship_payload_not_mixed"), "Missing checks include dropship payload consistency")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete findings remain read-only")


func _test_issue_findings_route_to_first_action_item() -> void:
	var notes: Dictionary = _notes(true, true, true, true, _all_check_ids(), ["firefight_response_stutter", "hud_overlap_blocks_action"])
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_release_candidate_polish", "Issue notes route to targeted polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_769"), "First issue routes to performance feel pass")
	_assert(_snapshot_is_read_only(snapshot), "Issue findings remain read-only")


func _test_clean_findings_route_to_acceptance() -> void:
	var notes: Dictionary = _notes(true, true, true, true, _all_check_ids(), [])
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_candidate_acceptance", "Clean review routes to acceptance")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_802"), "Clean review recommends TASK_802")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "Clean review has no missing checks")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean review has no active issues")
	_assert(_snapshot_is_read_only(snapshot), "Clean findings remain read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _packet(), _notes(false, false, false, false, [], []), {
		"manifest_path": "tmp/station_reentry_firefight_release_candidate_playtest_findings.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_801 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_801 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_801", "Manifest records TASK_801")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_800", "Manifest records TASK_800 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_release_candidate_playtest", "Manifest preserves open visible-playtest status")
	_assert(String(parsed.get("exe_path", "")).contains("Sternenbuergerchen_rel.exe"), "Manifest carries release EXE path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_multiplayer_release_candidate_packet.v1",
		"task_id": "TASK_800",
		"source_task_id": "TASK_799",
		"status": "ready_for_release_candidate_playtest",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"release_candidate_packet_ready": true,
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
		"release_playtest_checks": _check_defs(),
		"commands": {
			"run_release_exe": "\"C:/dev/Sternenbuergerchen_rel/Sternenbuergerchen_rel.exe\"",
			"runtime_release_export": "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1",
			"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch",
			"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14",
		},
	}


func _check_defs() -> Array:
	var defs: Array = []
	for id in _all_check_ids():
		defs.append({"id": id, "label": id})
	return defs


func _all_check_ids() -> Array:
	return [
		"singleplayer_homebase_not_blocked",
		"host_client_windows_open",
		"fireteams_visible_and_distinct",
		"dropship_payload_not_mixed",
		"mission_insertion_visible",
		"move_preview_before_go",
		"decision_card_actionable",
		"first_firefight_response_fast",
		"exit_or_debrief_path_visible",
		"no_hud_overlap_blocker",
		"runtime_export_is_fresh",
	]


func _notes(manual_done: bool, visible_done: bool, release_exe_started: bool, host_client_started: bool, checked_ids: Array, issue_ids: Array) -> Dictionary:
	var values: Dictionary = {
		"manual_review_done": manual_done,
		"visible_playtest_done": visible_done,
		"release_exe_started": release_exe_started,
		"host_client_started": host_client_started,
	}
	for id in checked_ids:
		values[String(id)] = true
	var issues: Dictionary = {}
	for id in issue_ids:
		issues[String(id)] = true
	values["issues"] = issues
	return {"reentry_firefight_release_candidate_findings": values}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true))


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
