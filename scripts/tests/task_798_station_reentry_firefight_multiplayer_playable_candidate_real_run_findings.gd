extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_798_station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.md"
const TASK_797_PATH: String = "res://docs/tasks/TASK_797_station_reentry_firefight_multiplayer_playable_slice_candidate.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_798 Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings ===")
	_test_docs_contract_and_report()
	_test_missing_candidate_blocks()
	_test_open_real_run_routes_back_to_task_797()
	_test_incomplete_checks_are_reported()
	_test_issue_flags_route_to_targeted_tasks()
	_test_clean_review_routes_forward_to_task_799()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_798: FAILED")
		quit(1)
		return
	print("TASK_798: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_798 task file exists")
	_assert(FileAccess.file_exists(TASK_797_PATH), "TASK_797 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings"), "TASK_798 task names real-run findings")
	_assert(status_text.contains("TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings"), "Implementation status tracks TASK_798")
	_assert(roadmap_text.contains("TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings (implementiert)"), "Roadmap marks TASK_798 implemented")
	_assert(roadmap_text.contains("TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"), "Roadmap advances to TASK_799")
	_assert(contract_text.contains("Station-Reentry-Firefight-Multiplayer-Playable-Candidate-Real-Run-Findings"), "Mission command feedback contract documents TASK_798")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.json"), "Reentry handbook names TASK_798 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_multiplayer_playable_candidate_findings.real_run_done"'), "Reentry handbook exports TASK_798 real-run check")


func _test_missing_candidate_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.v1", "TASK_798 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_797 candidate blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_797"), "Missing candidate recommends TASK_797")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing candidate creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Missing-candidate findings remain read-only")


func _test_open_real_run_routes_back_to_task_797() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _candidate(), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_multiplayer_playable_candidate_real_run", "Open real-run routes back to TASK_797")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_797"), "Open real-run recommends TASK_797 run")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open real-run does not claim manual done")
	_assert(not bool(snapshot.get("real_run_done", true)), "Open real-run does not claim real run done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("host_client_windows_open"), "Open real-run reports missing host/client windows")
	_assert(_snapshot_is_read_only(snapshot), "Open findings remain read-only")


func _test_incomplete_checks_are_reported() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _candidate(), _partial_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "needs_multiplayer_playable_candidate_completion", "Partial review requires completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 4, "Partial review counts completed checks")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("dropship_payload_not_mixed"), "Missing checks include dropship payload consistency")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("workbench_json_exported"), "Missing checks include workbench export")
	_assert(_snapshot_is_read_only(snapshot), "Partial findings remain read-only")


func _test_issue_flags_route_to_targeted_tasks() -> void:
	var notes: Dictionary = _complete_notes()
	notes["reentry_firefight_multiplayer_playable_candidate_findings"]["issues"] = {
		"dropship_payload_mixed": true,
		"firefight_response_stutter": true,
	}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _candidate(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_multiplayer_playable_candidate_polish", "Issue notes route to targeted polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_765"), "Dropship issue routes to TASK_765")
	_assert(_snapshot_is_read_only(snapshot), "Issue findings remain read-only")


func _test_clean_review_routes_forward_to_task_799() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _candidate(), _complete_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_multiplayer_playable_candidate_acceptance", "Complete clean review routes forward")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_799"), "Clean review recommends TASK_799")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "Clean review has no missing checks")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean review has no active issues")
	_assert(_snapshot_is_read_only(snapshot), "Clean findings remain read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _candidate(), {}, {
		"candidate_manifest_path": "tmp/station_reentry_firefight_multiplayer_playable_slice_candidate.json",
		"manifest_path": "tmp/station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_798 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_798 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_798", "Manifest records TASK_798")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_797", "Manifest records TASK_797 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_multiplayer_playable_candidate_real_run", "Manifest preserves open real-run status")
	_assert(String(parsed.get("scenario_path", "")).contains("station_route_one_screen_multiplayer_drill"), "Manifest carries scenario path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _candidate() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_slice_candidate.v1",
		"task_id": "TASK_797",
		"source_task_id": "TASK_796",
		"status": "ready_for_multiplayer_playable_slice_candidate",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"candidate_ready": true,
		"scenario_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"commands": {
			"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch",
			"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14",
		},
		"player_flow_checkpoints": [
			{"id": "host_client_windows_open"},
			{"id": "dropship_payload_not_mixed"},
		],
	}


func _partial_notes() -> Dictionary:
	return {
		"reentry_firefight_multiplayer_playable_candidate_findings": {
			"manual_review_done": true,
			"real_run_done": true,
			"singleplayer_homebase_not_blocked": true,
			"host_client_windows_open": true,
			"fireteams_visible_and_distinct": true,
			"mission_insertion_visible": true,
		},
	}


func _complete_notes() -> Dictionary:
	var findings: Dictionary = {
		"manual_review_done": true,
		"real_run_done": true,
	}
	for id in [
		"singleplayer_homebase_not_blocked",
		"host_client_windows_open",
		"fireteams_visible_and_distinct",
		"dropship_payload_not_mixed",
		"mission_insertion_visible",
		"move_preview_before_go",
		"decision_card_actionable",
		"first_firefight_response_fast",
		"no_auto_command_commit",
		"exit_or_debrief_path_visible",
		"no_hud_overlap_blocker",
		"screenshots_saved",
		"workbench_json_exported",
	]:
		findings[id] = true
	findings["issues"] = {}
	return {"reentry_firefight_multiplayer_playable_candidate_findings": findings}


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
