extends SceneTree

const VISIBLE_SMOKE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_visible_ship_smoke.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_804_station_reentry_firefight_release_candidate_visible_ship_smoke.md"
const TASK_803_PATH: String = "res://docs/tasks/TASK_803_station_reentry_firefight_release_candidate_ship_readiness.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_visible_ship_smoke.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_804 Station Reentry Firefight Release Candidate Visible Ship Smoke ===")
	_test_docs_contract_and_report()
	_test_missing_ship_readiness_blocks()
	_test_invalid_ship_readiness_blocks()
	_test_unready_ship_readiness_blocks()
	_test_open_visible_smoke_routes_to_task_804()
	_test_incomplete_checks_route_to_completion()
	_test_issue_flags_route_to_action_items()
	_test_clean_smoke_routes_to_delivery_review()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_804: FAILED")
		quit(1)
		return
	print("TASK_804: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_804 task file exists")
	_assert(FileAccess.file_exists(TASK_803_PATH), "TASK_803 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Visible Ship Smoke"), "TASK_804 task names visible ship smoke")
	_assert(status_text.contains("TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke"), "Implementation status tracks TASK_804")
	_assert(roadmap_text.contains("TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke (implementiert)"), "Roadmap marks TASK_804 implemented")
	_assert(roadmap_text.contains("TASK_805 - Station Reentry Firefight Release Candidate Delivery Review"), "Roadmap advances to TASK_805")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Visible-Ship-Smoke"), "Mission command feedback contract documents TASK_804")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_visible_ship_smoke.json"), "Reentry handbook names TASK_804 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_visible_ship_smoke.visible_ship_smoke_done"'), "Reentry handbook exports TASK_804 done check")


func _test_missing_ship_readiness_blocks() -> void:
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_visible_ship_smoke.v1", "TASK_804 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_ship_readiness", "Missing TASK_803 ship readiness blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_803"), "Missing ship readiness recommends TASK_803")
	_assert(not bool(snapshot.get("visible_ship_smoke_ready", true)), "Missing source is not visible-smoke-ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-source visible smoke remains read-only")


func _test_invalid_ship_readiness_blocks() -> void:
	var source: Dictionary = _ship_readiness(true)
	source["schema"] = "wrong"
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", source, _notes(false, false, false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_ship_readiness", "Invalid TASK_803 schema blocks")
	_assert(not bool(snapshot.get("source_valid", true)), "Invalid source is reported")
	_assert(_snapshot_is_read_only(snapshot), "Invalid-source visible smoke remains read-only")


func _test_unready_ship_readiness_blocks() -> void:
	var source: Dictionary = _ship_readiness(false)
	source["status"] = "needs_ship_readiness_completion"
	source["recommended_next_task"] = "TASK_803 - complete release candidate ship readiness items"
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", source, _notes(false, false, false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_ship_readiness", "Unready TASK_803 source blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_803"), "Unready source keeps TASK_803 recommendation")
	_assert(not bool(snapshot.get("visible_ship_smoke_ready", true)), "Unready source is not visible-smoke-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source visible smoke remains read-only")


func _test_open_visible_smoke_routes_to_task_804() -> void:
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", _ship_readiness(true), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_ship_smoke", "Open visible smoke routes to TASK_804")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_804"), "Open visible smoke recommends TASK_804 run")
	_assert(not bool(snapshot.get("manual_smoke_done", true)), "Open smoke does not claim manual done")
	_assert(not bool(snapshot.get("visible_ship_smoke_done", true)), "Open smoke does not claim visible done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("fresh_release_folder_used"), "Open smoke reports missing checks")
	_assert(_snapshot_is_read_only(snapshot), "Open visible smoke remains read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var notes: Dictionary = _notes(true, true, true, true, ["fresh_release_folder_used", "release_exe_started"], [])
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", _ship_readiness(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_ship_smoke_completion", "Incomplete visible smoke checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_804"), "Incomplete checks recommend TASK_804 completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 3, "Completed visible smoke checks are counted")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("homebase_not_blocked"), "Missing checks include homebase handoff")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete visible smoke remains read-only")


func _test_issue_flags_route_to_action_items() -> void:
	var notes: Dictionary = _notes(true, true, true, true, _all_check_ids(), ["stale_export_or_link", "singleplayer_homebase_blocked"])
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", _ship_readiness(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_ship_smoke_polish", "Issue flags route to targeted polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Refresh release export"), "First issue routes to stale export/link refresh")
	_assert(_snapshot_is_read_only(snapshot), "Issue visible smoke remains read-only")


func _test_clean_smoke_routes_to_delivery_review() -> void:
	var snapshot: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("build_snapshot", _ship_readiness(true), _notes(true, true, true, true, _all_check_ids(), []), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_candidate_delivery_review", "Clean visible smoke routes to delivery review")
	_assert(bool(snapshot.get("visible_ship_smoke_ready", false)), "Visible ship smoke ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_805"), "Clean visible smoke recommends TASK_805")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "Clean visible smoke has no missing checks")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean visible smoke has no active issues")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Visible smoke carries release EXE")
	_assert(_snapshot_is_read_only(snapshot), "Clean visible smoke remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(VISIBLE_SMOKE_SCRIPT.call("write_manifest", OUTPUT_MANIFEST_PATH, _ship_readiness(true), _notes(true, true, true, true, _all_check_ids(), []), {}))
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_804 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_804", "Manifest records TASK_804")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_803", "Manifest records TASK_803 source")
	_assert(String(parsed.get("status", "")) == "ready_for_release_candidate_delivery_review", "Manifest preserves visible smoke status")
	_assert(String(manifest.get("manifest_path", "")) == OUTPUT_MANIFEST_PATH, "write_manifest returns requested manifest path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _ship_readiness(ready: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_release_candidate_ship_readiness.v1",
		"task_id": "TASK_803",
		"source_task_id": "TASK_802",
		"status": "ready_for_ship_readiness_review" if ready else "needs_ship_readiness_completion",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"ship_readiness_ready": ready,
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
		"ship_readiness_items": [{"id": "release_exe_present", "complete": true}],
		"open_risks": ["Kein automatischer Screenshot-Entscheid."],
		"operator_instruction": "Start the fresh Release EXE, click Einzelspieler, then run the visible Host/Client ship smoke.",
		"recommended_next_task": "TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke",
	}


func _notes(manual_done: bool, visible_done: bool, release_exe_started: bool, host_client_started: bool, checked_ids: Array, issue_ids: Array) -> Dictionary:
	var values: Dictionary = {
		"manual_smoke_done": manual_done,
		"visible_ship_smoke_done": visible_done,
		"release_exe_started": release_exe_started,
		"host_client_windows_open": host_client_started,
	}
	for id in checked_ids:
		values[String(id)] = true
	var issues: Dictionary = {}
	for id in issue_ids:
		issues[String(id)] = true
	values["issues"] = issues
	return {"reentry_firefight_release_candidate_visible_ship_smoke": values}


func _all_check_ids() -> Array:
	return [
		"fresh_release_folder_used",
		"release_exe_started",
		"singleplayer_clicked",
		"homebase_not_blocked",
		"dropship_payload_ready",
		"mission_start_reachable",
		"host_client_windows_open",
		"host_client_roles_distinct",
		"no_stale_taskbar_link",
		"smoke_notes_exported",
	]


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
