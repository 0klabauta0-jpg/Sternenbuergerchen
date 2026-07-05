extends SceneTree

const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_playable_candidate_acceptance.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.md"
const TASK_798_PATH: String = "res://docs/tasks/TASK_798_station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_playable_candidate_acceptance.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_799 Station Reentry Firefight Multiplayer Playable Candidate Acceptance ===")
	_test_docs_contract_and_report()
	_test_missing_findings_blocks()
	_test_open_real_run_routes_back_to_task_797()
	_test_incomplete_checks_route_to_completion()
	_test_issue_findings_route_to_first_action_item()
	_test_clean_findings_are_accepted()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_799: FAILED")
		quit(1)
		return
	print("TASK_799: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_799 task file exists")
	_assert(FileAccess.file_exists(TASK_798_PATH), "TASK_798 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Multiplayer Playable Candidate Acceptance"), "TASK_799 task names playable candidate acceptance")
	_assert(status_text.contains("TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance"), "Implementation status tracks TASK_799")
	_assert(roadmap_text.contains("TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance (implementiert)"), "Roadmap marks TASK_799 implemented")
	_assert(roadmap_text.contains("TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet"), "Roadmap advances to TASK_800")
	_assert(contract_text.contains("Station-Reentry-Firefight-Multiplayer-Playable-Candidate-Acceptance"), "Mission command feedback contract documents TASK_799")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_multiplayer_playable_candidate_acceptance.json"), "Reentry handbook names TASK_799 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_multiplayer_playable_candidate_acceptance.accepted_for_multiplayer_candidate"'), "Reentry handbook exports TASK_799 acceptance check")


func _test_missing_findings_blocks() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_acceptance.v1", "TASK_799 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_multiplayer_playable_candidate_findings", "Missing TASK_798 findings block")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_798"), "Missing findings recommend TASK_798")
	_assert(not bool(snapshot.get("accepted_for_multiplayer_playable_candidate", true)), "Missing findings are not accepted")
	_assert(_snapshot_is_read_only(snapshot), "Missing-findings acceptance remains read-only")


func _test_open_real_run_routes_back_to_task_797() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("needs_visible_multiplayer_playable_candidate_real_run", false, false, ["host_client_windows_open"], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_multiplayer_playable_candidate_real_run", "Open real-run routes back to TASK_797")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_797"), "Open real-run recommends TASK_797 run")
	_assert(_failed_ids(snapshot).has("findings_ready"), "Open real-run fails findings-ready gate")
	_assert(_failed_ids(snapshot).has("real_run_done"), "Open real-run fails real-run gate")
	_assert(_snapshot_is_read_only(snapshot), "Open acceptance remains read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("needs_multiplayer_playable_candidate_completion", true, true, ["dropship_payload_not_mixed", "workbench_json_exported"], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "needs_multiplayer_playable_candidate_completion", "Incomplete checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_797"), "Incomplete checks recommend TASK_797 completion")
	_assert(Array(snapshot.get("source_missing_check_ids", [])).has("dropship_payload_not_mixed"), "Source missing checks are preserved")
	_assert(_failed_ids(snapshot).has("no_missing_checks"), "Incomplete checks fail no-missing gate")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete acceptance remains read-only")


func _test_issue_findings_route_to_first_action_item() -> void:
	var action_items: Array = [
		{
			"id": "firefight_response_stutter",
			"label": "Erster Feuerwechsel stottert oder fuehlt sich zaeh an",
			"recommended_task": "TASK_769 - Station Reentry Performance Feel Pass",
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		}
	]
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("needs_targeted_multiplayer_playable_candidate_polish", true, true, [], 1, action_items), {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_multiplayer_playable_candidate_polish", "Active issues route to targeted polish")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_769"), "First action item controls targeted route")
	_assert(int(snapshot.get("source_active_issue_count", 0)) == 1, "Source active issues are preserved")
	_assert(_failed_ids(snapshot).has("no_active_issues"), "Active issues fail no-active gate")
	_assert(_snapshot_is_read_only(snapshot), "Issue acceptance remains read-only")


func _test_clean_findings_are_accepted() -> void:
	var snapshot: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("ready_for_multiplayer_playable_candidate_acceptance", true, true, [], 0, []), {}))
	_assert(String(snapshot.get("status", "")) == "accepted_for_multiplayer_playable_candidate", "Clean findings are accepted")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_800"), "Accepted findings recommend TASK_800")
	_assert(bool(snapshot.get("accepted_for_multiplayer_playable_candidate", false)), "Accepted flag is true")
	_assert(Array(snapshot.get("failed_gate_ids", [])).is_empty(), "Accepted findings have no failed gates")
	_assert(_snapshot_is_read_only(snapshot), "Accepted snapshot remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings("ready_for_multiplayer_playable_candidate_acceptance", true, true, [], 0, []), {
		"manifest_path": "tmp/station_reentry_firefight_multiplayer_playable_candidate_acceptance.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_799 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_799 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_799", "Manifest records TASK_799")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_798", "Manifest records TASK_798 source")
	_assert(String(parsed.get("status", "")) == "accepted_for_multiplayer_playable_candidate", "Manifest preserves accepted status")
	_assert(String(parsed.get("expected_host_role", "")) != String(parsed.get("expected_client_role", "")), "Manifest preserves distinct host/client roles")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _findings(status: String, manual_done: bool, real_run_done: bool, missing_checks: Array, active_issues: int, action_items: Array) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.v1",
		"task_id": "TASK_798",
		"source_task_id": "TASK_797",
		"status": status,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"manual_review_done": manual_done,
		"real_run_done": real_run_done,
		"missing_check_ids": missing_checks.duplicate(true),
		"active_issue_count": active_issues,
		"action_items": action_items.duplicate(true),
		"candidate_ready": true,
		"scenario_path": "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"real_run_manifest_path": "tmp/host_client_two_window_real_run_review.json",
		"host_screenshot_path": "tmp/host_client_two_window_host_review.png",
		"client_screenshot_path": "tmp/host_client_two_window_client_review.png",
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"commands": {
			"launch_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1 -Launch",
			"capture_windows": "powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 14",
			"runtime_release_export": "powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1",
		},
	}


func _failed_ids(snapshot: Dictionary) -> Array:
	return Array(snapshot.get("failed_gate_ids", []))


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
