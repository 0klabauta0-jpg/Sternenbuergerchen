extends SceneTree

const HANDOFF_PACKET_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_release_candidate_handoff_packet.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_806_station_reentry_firefight_release_candidate_handoff_packet.md"
const TASK_805_PATH: String = "res://docs/tasks/TASK_805_station_reentry_firefight_release_candidate_delivery_review.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_release_candidate_handoff_packet.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_806 Station Reentry Firefight Release Candidate Handoff Packet ===")
	_test_docs_contract_and_report()
	_test_missing_delivery_review_blocks()
	_test_invalid_delivery_review_blocks()
	_test_unready_delivery_review_blocks()
	_test_open_handoff_routes_to_task_806()
	_test_incomplete_items_route_to_completion()
	_test_issue_flags_route_to_action_items()
	_test_clean_handoff_routes_to_tester_run()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_806: FAILED")
		quit(1)
		return
	print("TASK_806: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_806 task file exists")
	_assert(FileAccess.file_exists(TASK_805_PATH), "TASK_805 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Release Candidate Handoff Packet"), "TASK_806 task names handoff packet")
	_assert(status_text.contains("TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet"), "Implementation status tracks TASK_806")
	_assert(roadmap_text.contains("TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet (implementiert)"), "Roadmap marks TASK_806 implemented")
	_assert(roadmap_text.contains("TASK_807 - Station Reentry Firefight Release Candidate Tester Run"), "Roadmap advances to TASK_807")
	_assert(contract_text.contains("Station-Reentry-Firefight-Release-Candidate-Handoff-Packet"), "Mission command feedback contract documents TASK_806")
	_assert(report_text.contains("Aktueller Griff: TASK_806"), "Reentry handbook marks TASK_806 current")
	_assert(report_text.contains("station_reentry_firefight_release_candidate_handoff_packet.json"), "Reentry handbook names TASK_806 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_release_candidate_handoff_packet.handoff_packet_done"'), "Reentry handbook exports TASK_806 done check")


func _test_missing_delivery_review_blocks() -> void:
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_release_candidate_handoff_packet.v1", "TASK_806 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked_until_delivery_review", "Missing TASK_805 delivery review blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_805"), "Missing delivery review recommends TASK_805")
	_assert(not bool(snapshot.get("release_candidate_handoff_ready", true)), "Missing source is not handoff-ready")
	_assert(_snapshot_is_read_only(snapshot), "Missing-source handoff packet remains read-only")


func _test_invalid_delivery_review_blocks() -> void:
	var source: Dictionary = _delivery_review(true)
	source["schema"] = "wrong"
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", source, _notes(false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_delivery_review", "Invalid TASK_805 schema blocks")
	_assert(not bool(snapshot.get("source_valid", true)), "Invalid delivery review source is reported")
	_assert(_snapshot_is_read_only(snapshot), "Invalid-source handoff packet remains read-only")


func _test_unready_delivery_review_blocks() -> void:
	var source: Dictionary = _delivery_review(false)
	source["status"] = "needs_delivery_review"
	source["recommended_next_task"] = "TASK_805 - complete release candidate delivery review"
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", source, _notes(false, false, [], []), {}))
	_assert(String(snapshot.get("status", "")) == "blocked_until_delivery_review_ready", "Unready TASK_805 source blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_805"), "Unready source keeps TASK_805 recommendation")
	_assert(not bool(snapshot.get("release_candidate_handoff_ready", true)), "Unready source is not handoff-ready")
	_assert(_snapshot_is_read_only(snapshot), "Unready-source handoff packet remains read-only")


func _test_open_handoff_routes_to_task_806() -> void:
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", _delivery_review(true), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_handoff_packet", "Open handoff routes to TASK_806")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_806"), "Open handoff recommends TASK_806")
	_assert(not bool(snapshot.get("handoff_packet_done", true)), "Open handoff does not claim done")
	_assert(not bool(snapshot.get("handoff_reviewed", true)), "Open handoff does not claim reviewed")
	_assert(Array(snapshot.get("missing_item_ids", [])).has("singleplayer_start_step_written"), "Open handoff reports missing singleplayer step")
	_assert(_snapshot_is_read_only(snapshot), "Open handoff remains read-only")


func _test_incomplete_items_route_to_completion() -> void:
	var notes: Dictionary = _notes(true, true, ["singleplayer_start_step_written", "host_client_start_step_written"], [])
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", _delivery_review(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_handoff_packet_completion", "Incomplete handoff items route to completion")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_806"), "Incomplete items recommend TASK_806 completion")
	_assert(int(snapshot.get("completed_handoff_item_count", 0)) == 7, "Completed handoff items are counted")
	_assert(Array(snapshot.get("missing_item_ids", [])).has("risk_summary_written"), "Missing items include risk summary")
	_assert(_snapshot_is_read_only(snapshot), "Incomplete handoff remains read-only")


func _test_issue_flags_route_to_action_items() -> void:
	var notes: Dictionary = _notes(true, true, _all_item_ids(), ["stale_handoff_package", "roles_unclear"])
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", _delivery_review(true), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_handoff_polish", "Issue flags route to targeted handoff polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active handoff issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two handoff action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("Refresh release export"), "First issue routes to stale handoff refresh")
	_assert(_snapshot_is_read_only(snapshot), "Issue handoff remains read-only")


func _test_clean_handoff_routes_to_tester_run() -> void:
	var snapshot: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("build_snapshot", _delivery_review(true), _notes(true, true, _all_item_ids(), []), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_release_candidate_tester_run", "Clean handoff routes to tester run")
	_assert(bool(snapshot.get("release_candidate_handoff_ready", false)), "Handoff ready flag is true")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_807"), "Clean handoff recommends TASK_807")
	_assert(Array(snapshot.get("missing_item_ids", [])).is_empty(), "Clean handoff has no missing items")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean handoff has no active issues")
	_assert(String(snapshot.get("exe_path", "")).ends_with("Sternenbuergerchen_rel.exe"), "Handoff packet carries release EXE")
	_assert(_snapshot_is_read_only(snapshot), "Clean handoff remains read-only")


func _test_actual_manifest_write() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var manifest: Dictionary = Dictionary(HANDOFF_PACKET_SCRIPT.call("write_manifest", OUTPUT_MANIFEST_PATH, _delivery_review(true), _notes(true, true, _all_item_ids(), []), {}))
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_806 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_806", "Manifest records TASK_806")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_805", "Manifest records TASK_805 source")
	_assert(String(parsed.get("status", "")) == "ready_for_release_candidate_tester_run", "Manifest preserves handoff status")
	_assert(String(manifest.get("manifest_path", "")) == OUTPUT_MANIFEST_PATH, "write_manifest returns requested manifest path")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _delivery_review(ready: bool) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_release_candidate_delivery_review.v1",
		"task_id": "TASK_805",
		"source_task_id": "TASK_804",
		"status": "ready_for_release_candidate_handoff_packet" if ready else "needs_delivery_review",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"release_candidate_delivery_ready": ready,
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
		"delivery_notes": {
			"start_instruction": "Start fresh EXE, click Einzelspieler, verify Homebase is actionable.",
			"host_client_instruction": "Launch Host/Client and verify HOST P1 ALPHA / CLIENT P2 BRAVO.",
			"shortcut_warning": "Use the fresh release folder, not an old taskbar link.",
			"risk_note": "Known screenshot automation risk accepted for this handoff.",
			"handoff_note": "Prepare the handoff packet next.",
		},
		"recommended_next_task": "TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet",
	}


func _notes(handoff_done: bool, handoff_reviewed: bool, checked_ids: Array, issue_ids: Array) -> Dictionary:
	var values: Dictionary = {
		"handoff_packet_done": handoff_done,
		"handoff_reviewed": handoff_reviewed,
		"singleplayer_start_step": "Start fresh EXE, click Einzelspieler, verify Homebase is actionable.",
		"host_client_start_step": "Launch Host/Client review helper and compare both windows.",
		"role_expectations": "HOST P1 ALPHA / CLIENT P2 BRAVO.",
		"shortcut_warning": "Use the fresh release folder, not an old taskbar link.",
		"smoke_gate_summary": "TASK_804 smoke and TASK_805 delivery review green.",
		"risk_summary": "Manual screenshot judgement remains a known risk.",
		"next_tester_action": "Run TASK_807 tester run from this packet.",
	}
	for id in checked_ids:
		values[String(id)] = true
	var issues: Dictionary = {}
	for id in issue_ids:
		issues[String(id)] = true
	values["issues"] = issues
	return {"reentry_firefight_release_candidate_handoff_packet": values}


func _all_item_ids() -> Array:
	return [
		"delivery_review_ready",
		"release_dir_named",
		"release_exe_named",
		"release_pck_named",
		"singleplayer_start_step_written",
		"host_client_start_step_written",
		"role_expectations_written",
		"fresh_shortcut_warning_written",
		"smoke_gate_summary_written",
		"risk_summary_written",
		"workbench_report_named",
		"next_tester_action_written",
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
