extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_visual_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_779_station_reentry_firefight_visual_findings.md"
const TASK_778_PATH: String = "res://docs/tasks/TASK_778_station_reentry_firefight_visual_playtest_packet.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const PACKET_TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_visual_playtest_packet.ps1"
const PACKET_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_visual_playtest_packet.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_visual_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_779 Station Reentry Firefight Visual Findings ===")
	_test_docs_contract_and_report()
	_test_missing_packet_blocks()
	_test_open_visual_review_routes_back_to_task_778()
	_test_incomplete_checks_are_reported()
	_test_issue_flags_route_to_targeted_tasks()
	_test_clean_visual_review_routes_forward()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_779: FAILED")
		quit(1)
		return
	print("TASK_779: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_779 task file exists")
	_assert(FileAccess.file_exists(TASK_778_PATH), "TASK_778 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Visual Findings"), "TASK_779 task names visual findings")
	_assert(status_text.contains("TASK_779 - Station Reentry Firefight Visual Findings"), "Implementation status tracks TASK_779")
	_assert(roadmap_text.contains("TASK_779 - Station Reentry Firefight Visual Findings (implementiert)"), "Roadmap marks TASK_779 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Visual-Findings"), "Mission command feedback contract documents TASK_779")
	_assert(report_text.contains("Aktueller Griff: TASK_784"), "Reentry handbook marks TASK_784 current")
	_assert(report_text.contains("station_reentry_firefight_visual_findings.json"), "Reentry handbook names TASK_779 findings manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_visual_findings.manual_review_done"'), "Reentry handbook exports TASK_779 manual review check")
	_assert(report_text.contains('data-export-key="reentry_firefight_visual_findings.issues.trace_too_subtle"'), "Reentry handbook exports TASK_779 issue flags")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_visual_findings.v1", "TASK_779 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_778 packet blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_778"), "Missing packet recommends TASK_778")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing packet creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Missing-packet findings remain read-only")


func _test_open_visual_review_routes_back_to_task_778() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_firefight_review", "Open visual review routes back to TASK_778")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_778"), "Open review recommends TASK_778 run")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open review does not claim manual done")
	_assert(not bool(snapshot.get("visible_playtest_done", true)), "Open review does not claim visible playtest done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("f6_window_open"), "Open review reports missing F6 window")
	_assert(_snapshot_is_read_only(snapshot), "Open findings remain read-only")


func _test_incomplete_checks_are_reported() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _partial_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "needs_firefight_review_completion", "Partial review requires completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 3, "Partial review counts completed checks")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("impact_focus_visible"), "Missing checks include impact focus")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("workbench_json_exported"), "Missing checks include workbench export")
	_assert(_snapshot_is_read_only(snapshot), "Partial findings remain read-only")


func _test_issue_flags_route_to_targeted_tasks() -> void:
	var notes: Dictionary = _complete_notes()
	notes["reentry_firefight_visual_findings"]["issues"] = {
		"trace_too_subtle": true,
		"metrics_mismatch": true,
	}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_firefight_visual_polish", "Issue notes route to targeted visual polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_544"), "Trace issue routes to TASK_544")
	_assert(_snapshot_is_read_only(snapshot), "Issue findings remain read-only")


func _test_clean_visual_review_routes_forward() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _complete_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_next_station_firefight_iteration", "Complete clean review routes forward")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_780"), "Clean review recommends TASK_780")
	_assert(Array(snapshot.get("missing_check_ids", [])).is_empty(), "Clean review has no missing checks")
	_assert(int(snapshot.get("active_issue_count", -1)) == 0, "Clean review has no active issues")
	_assert(_snapshot_is_read_only(snapshot), "Clean findings remain read-only")


func _test_actual_manifest_write() -> void:
	_run_packet_tool()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var packet: Dictionary = _read_json(PACKET_MANIFEST_PATH)
	if packet.is_empty():
		packet = _build_packet()
	var manifest: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", packet, {}, {
		"packet_manifest_path": "tmp/station_reentry_firefight_visual_playtest_packet.json",
		"manifest_path": "tmp/station_reentry_firefight_visual_findings.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_779 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_779 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_779", "Manifest records TASK_779")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_778", "Manifest records TASK_778 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_firefight_review", "Manifest preserves open visual review status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _run_packet_tool() -> void:
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(PACKET_TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_778 packet tool exits 0 for TASK_779")


func _build_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_visual_playtest_packet.v1",
		"task_id": "TASK_778",
		"source_task_id": "TASK_777",
		"target_id": "station_reentry_firefight_visual_playtest",
		"status": "ready_to_capture_station_reentry_firefight_visual",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"expected_firefight_readability": {
			"required_visible_fragments": ["FIRE", "HIT", "LOS", "COVER", "next:"],
			"required_visuals": ["fire_trace", "impact_focus", "unit_status_badge"],
			"required_metrics": ["shots_fired", "hit_count", "friendly_fire_risk_count"],
		},
	}


func _partial_notes() -> Dictionary:
	return {
		"reentry_firefight_visual_findings": {
			"manual_review_done": true,
			"visible_playtest_done": true,
			"f6_window_open": true,
			"firefight_triggered": true,
			"fire_trace_visible": true,
		},
	}


func _complete_notes() -> Dictionary:
	var findings: Dictionary = {
		"manual_review_done": true,
		"visible_playtest_done": true,
	}
	for id in [
		"f6_window_open",
		"firefight_triggered",
		"fire_trace_visible",
		"impact_focus_visible",
		"unit_badge_visible",
		"combat_hud_next_decision_visible",
		"combat_metrics_match_hud",
		"friendly_fire_risk_readable",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		findings[id] = true
	findings["issues"] = {}
	return {"reentry_firefight_visual_findings": findings}


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
