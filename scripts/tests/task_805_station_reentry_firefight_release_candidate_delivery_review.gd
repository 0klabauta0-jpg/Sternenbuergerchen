extends SceneTree

const DELIVERY_REVIEW_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_delivery_review.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_805_station_reentry_firefight_release_candidate_delivery_review.md"
const TASK_804_PATH: String = "res://docs/tasks/TASK_804_station_reentry_firefight_release_candidate_visible_ship_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_delivery_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_805 Station Reentry Firefight Release Candidate Delivery Review ===")
	_test_docs_contract_and_report()
	_test_missing_visible_smoke_blocks()
	_test_invalid_visible_smoke_blocks()
	_test_unready_visible_smoke_blocks()
	_test_open_delivery_review_routes_to_task_805()
	_test_incomplete_checks_route_to_completion()
	_test_issue_flags_route_to_action_items()
	_test_clean_review_routes_to_handoff_packet()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_805: FAILED")
		quit(1)
		return
	print("TASK_805: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_805 task file exists")
	_assert(FileAccess.file_exists(TASK_804_PATH), "TASK_804 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Delivery Review"), "TASK_805 task names delivery review")
	_assert(status_text.contains("TASK_805 - Station Reentry Firefight Release Candidate Delivery Review"), "Implementation status tracks TASK_805")
	_assert(roadmap_text.contains("TASK_805 - Station Reentry Firefight Release Candidate Delivery Review (implementiert)"), "Roadmap marks TASK_805 implemented")
	_assert(roadmap_text.contains("TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet"), "Roadmap advances to TASK_806")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Delivery-Review"), "Mission command feedback contract documents TASK_805")
	_assert(report_text.contains("Aktueller Griff: TASK_"), "Reentry handbook keeps a current task marker")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_delivery_review.json"), "Reentry handbook names TASK_805 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_delivery_review.delivery_review_done"'), "Reentry handbook exports TASK_805 done check")


func _test_missing_visible_smoke_blocks() -> void:
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_delivery_review.v1", "TASK_805 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_visible_ship_smoke", "Missing TASK_804 visible smoke blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_804"), "Missing visible smoke recommends TASK_804")
	_assert(not bool(snapshot.get("release_candidate_delivery_ready", true)), "Missing source is not delivery-ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-source delivery review remains read-only")


func _test_invalid_visible_smoke_blocks() -> void:
	var source: Dictionary = _visible_smoke(true)
	source["schema"] = "wrong"
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", source, _notes(false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_visible_ship_smoke", "Invalid TASK_804 schema blocks")
	_assert(not bool(snapshot.get("source_valid", true)), "Invalid visible smoke source is reported")
	_assert(_snapshot_is_read_only(snapshot), "Invalid-source delivery review remains read-only")


func _test_unready_visible_smoke_blocks() -> void:
	var source: Dictionary = _visible_smoke(false)
	source["status"] = "needs_visible_ship_smoke"
	source["recommended_next_task"] = "TASK_804 - run visible release ship smoke"
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", source, _notes(false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_visible_ship_smoke_ready", "Unready TASK_804 source blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_804"), "Unready source keeps TASK_804 recommendation")
	_assert(not bool(snapshot.get("release_candidate_delivery_ready", true)), "Unready source is not delivery-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source delivery review remains read-only")


func _test_open_delivery_review_routes_to_task_805() -> void:
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", _visible_smoke(true), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_delivery_review", "Open delivery review routes to TASK_805")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_805"), "Open delivery review recommends TASK_805")
	_assert(not bool(snapshot.get("delivery_review_done", true)), "Open review does not claim done")
	_assert(not bool(snapshot.get("delivery_reviewed", true)), "Open review does not claim reviewed")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("start_instruction_written"), "Open review reports missing start instruction")
	_assert(_snapshot_is_read_only(snapshot), "Open delivery review remains read-only")


func _test_incomplete_checks_route_to_completion() -> void:
	var notes: Dictionary = _notes(true, true, ["start_instruction_written", "host_client_instruction_written"], [])
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", _visible_smoke(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_delivery_review_completion", "Incomplete delivery checks route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_805"), "Incomplete checks recommend TASK_805 completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 4, "Completed delivery checks are counted")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("known_risks_accepted"), "Missing checks include risk acceptance")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete delivery review remains read-only")


func _test_issue_flags_route_to_action_items() -> void:
	var notes: Dictionary = _notes(true, true, _all_check_ids(), ["stale_delivery_package", "risks_not_accepted"])
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", _visible_smoke(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_delivery_polish", "Issue flags route to targeted delivery polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active delivery issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two delivery action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Refresh release export"), "First issue routes to stale delivery refresh")
	_assert(_snapshot_is_read_only(snapshot), "Issue delivery review remains read-only")


func _test_clean_review_routes_to_handoff_packet() -> void:
	var snapshot: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("build_snapshot", _visible_smoke(true), _notes(true, true, _all_check_ids(), []), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_candidate_handoff_packet", "Clean delivery review routes to handoff packet")
	_assert(bool(snapshot.get("release_candidate_delivery_ready", false)), "Delivery ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_806"), "Clean delivery review recommends TASK_806")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "Clean delivery review has no missing checks")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean delivery review has no active issues")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Delivery review carries release EXE")
	_assert(_snapshot_is_read_only(snapshot), "Clean delivery review remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(DELIVERY_REVIEW_SCRIPT.call("write_manifest", OUTPUT_MANIFEST_PATH, _visible_smoke(true), _notes(true, true, _all_check_ids(), []), {}))
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_805 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_805", "Manifest records TASK_805")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_804", "Manifest records TASK_804 source")
	_assert(String(parsed.get("status", "")) == "ready_for_release_candidate_handoff_packet", "Manifest preserves delivery review status")
	_assert(String(manifest.get("manifest_path", "")) == OUTPUT_MANIFEST_PATH, "write_manifest returns requested manifest path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _visible_smoke(ready: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_release_candidate_visible_ship_smoke.v1",
		"task_id": "TASK_804",
		"source_task_id": "TASK_803",
		"status": "ready_for_release_candidate_delivery_review" if ready else "needs_visible_ship_smoke",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"visible_ship_smoke_ready": ready,
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
		"operator_instruction": "Start the fresh Release EXE, click Einzelspieler, then run the visible Host/Client ship smoke.",
		"recommended_next_task": "TASK_805 - Station Reentry Firefight Release Candidate Delivery Review",
	}


func _notes(review_done: bool, delivery_reviewed: bool, checked_ids: Array, issue_ids: Array) -> Dictionary:
	var values: Dictionary = {
		"delivery_review_done": review_done,
		"delivery_reviewed": delivery_reviewed,
		"start_instruction": "Start fresh EXE, click Einzelspieler, verify Homebase is actionable.",
		"host_client_instruction": "Launch Host/Client and verify HOST P1 ALPHA / CLIENT P2 BRAVO.",
		"shortcut_warning": "Use the fresh release folder, not an old taskbar link.",
		"risk_note": "Known screenshot automation risk accepted for this handoff.",
		"handoff_note": "Prepare the handoff packet next.",
	}
	for id in checked_ids:
		values[String(id)] = true
	var issues: Dictionary = {}
	for id in issue_ids:
		issues[String(id)] = true
	values["issues"] = issues
	return {"reentry_firefight_release_candidate_delivery_review": values}


func _all_check_ids() -> Array:
	return [
		"visible_ship_smoke_ready",
		"release_files_named",
		"start_instruction_written",
		"host_client_instruction_written",
		"known_risks_reviewed",
		"known_risks_accepted",
		"report_export_saved",
		"shortcut_warning_written",
		"next_handoff_task_chosen",
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
