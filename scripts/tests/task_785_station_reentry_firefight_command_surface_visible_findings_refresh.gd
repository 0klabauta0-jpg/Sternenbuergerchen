extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_command_surface_visible_findings_refresh.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_785_station_reentry_firefight_command_surface_visible_findings_refresh.md"
const TASK_784_PATH: String = "res://docs/tasks/TASK_784_station_reentry_firefight_command_surface_playtest_packet_refresh.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const PACKET_TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_command_surface_playtest_packet_refresh.ps1"
const POLISH_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_polish.json"
const PACKET_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_playtest_packet_refresh.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_visible_findings_refresh.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_785 Station Reentry Firefight Command Surface Visible Findings Refresh ===")
	_test_docs_contract_and_report()
	_test_missing_packet_blocks()
	_test_open_visible_review_routes_back_to_task_784()
	_test_incomplete_checks_are_reported()
	_test_issue_flags_route_to_targeted_tasks()
	_test_clean_review_routes_forward_to_task_786()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_785: FAILED")
		quit(1)
		return
	print("TASK_785: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_785 task file exists")
	_assert(FileAccess.file_exists(TASK_784_PATH), "TASK_784 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Command Surface Visible Findings Refresh"), "TASK_785 task names visible findings refresh")
	_assert(status_text.contains("TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh"), "Implementation status tracks TASK_785")
	_assert(roadmap_text.contains("TASK_785 - Station Reentry Firefight Command Surface Visible Findings Refresh (implementiert)"), "Roadmap marks TASK_785 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Command-Surface-Visible-Findings-Refresh"), "Mission command feedback contract documents TASK_785")
	_assert(report_text.contains("Aktueller Griff: TASK_792"), "Reentry handbook marks TASK_792 current")
	_assert(report_text.contains("station_reentry_firefight_command_surface_visible_findings_refresh.json"), "Reentry handbook names TASK_785 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface_visible_findings.manual_review_done"'), "Reentry handbook exports TASK_785 manual review check")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface_visible_findings.issues.quick_action_rail_hidden"'), "Reentry handbook exports TASK_785 issue flags")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_command_surface_visible_findings_refresh.v1", "TASK_785 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_784 packet blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_784"), "Missing packet recommends TASK_784")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing packet creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Missing-packet findings remain read-only")


func _test_open_visible_review_routes_back_to_task_784() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_polished_command_surface_review", "Open visible review routes back to TASK_784")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_784"), "Open review recommends TASK_784 run")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open review does not claim manual done")
	_assert(not bool(snapshot.get("visible_playtest_done", true)), "Open review does not claim visible playtest done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("quick_action_rail_visible"), "Open review reports missing quick action rail")
	_assert(_snapshot_is_read_only(snapshot), "Open findings remain read-only")


func _test_incomplete_checks_are_reported() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _partial_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "needs_polished_command_surface_review_completion", "Partial review requires completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 5, "Partial review counts completed checks")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("guard_line_visible"), "Missing checks include guard line")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("workbench_json_exported"), "Missing checks include workbench export")
	_assert(_snapshot_is_read_only(snapshot), "Partial findings remain read-only")


func _test_issue_flags_route_to_targeted_tasks() -> void:
	var notes: Dictionary = _complete_notes()
	notes["reentry_firefight_command_surface_visible_findings"]["issues"] = {
		"quick_action_rail_hidden": true,
		"host_client_surface_mismatch": true,
	}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_polished_command_surface_polish", "Issue notes route to targeted polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_783"), "Quick-action rail issue routes to TASK_783")
	_assert(_snapshot_is_read_only(snapshot), "Issue findings remain read-only")


func _test_clean_review_routes_forward_to_task_786() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _complete_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_next_station_firefight_iteration", "Complete clean review routes forward")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_786"), "Clean review recommends TASK_786")
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
		"packet_manifest_path": "tmp/station_reentry_firefight_command_surface_playtest_packet_refresh.json",
		"manifest_path": "tmp/station_reentry_firefight_command_surface_visible_findings_refresh.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_785 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_785 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_785", "Manifest records TASK_785")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_784", "Manifest records TASK_784 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_polished_command_surface_review", "Manifest preserves open polished review status")
	_assert(String(parsed.get("expected_command_surface_style_id", "")) == "task_783_firefight_command_surface_v1", "Manifest carries expected style id")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _run_packet_tool() -> void:
	_write_polish_manifest()
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(PACKET_TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_784 packet tool exits 0 for TASK_785")


func _write_polish_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_reentry_firefight_command_surface_polish.v1",
		"task_id": "TASK_783",
		"source_task_ids": ["TASK_782", "TASK_780", "TASK_570", "TASK_736"],
		"status": "ready_for_command_surface_polish_review",
		"ready_for_command_surface_polish_review": true,
		"command_surface_style_id": "task_783_firefight_command_surface_v1",
		"surface_priority_order": ["interaction_line", "primary_action", "quick_action_rail", "guard_line"],
		"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"primary_action": {"id": "hold_cover", "label": "HOLD"},
		"quick_action_rail": [
			{"id": "hold_cover", "display_label": "HOLD"},
			{"id": "flank", "display_label": "FLANK"},
			{"id": "hold_fire", "display_label": "HOLD FIRE"},
			{"id": "suppress", "display_label": "SUP"},
			{"id": "move_cover", "display_label": "MOVE"},
		],
		"guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"summary_line": "NEXT HOLD | QUICK FLANK / HOLD FIRE / SUP / MOVE",
		"uses_existing_commands_only": true,
		"no_auto_command_commit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}
	var file := FileAccess.open(POLISH_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_783 manifest for TASK_785 setup")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(POLISH_MANIFEST_PATH), "TASK_783 polish manifest is prepared for TASK_785")


func _build_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_command_surface_playtest_packet_refresh.v1",
		"task_id": "TASK_784",
		"source_task_id": "TASK_783",
		"target_id": "station_reentry_firefight_command_surface_playtest_packet_refresh",
		"status": "ready_to_capture_polished_command_surface",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"expected_command_surface_style_id": "task_783_firefight_command_surface_v1",
		"expected_surface_priority_order": ["interaction_line", "primary_action", "quick_action_rail", "guard_line"],
		"expected_interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_summary_line": "NEXT HOLD | QUICK FLANK / HOLD FIRE / SUP / MOVE",
		"expected_no_auto_command_commit": true,
		"expected_uses_existing_commands_only": true,
	}


func _partial_notes() -> Dictionary:
	return {
		"reentry_firefight_command_surface_visible_findings": {
			"manual_review_done": true,
			"visible_playtest_done": true,
			"f6_window_open": true,
			"polished_surface_visible": true,
			"interaction_line_visible": true,
			"primary_action_lane_visible": true,
			"quick_action_rail_visible": true,
		},
	}


func _complete_notes() -> Dictionary:
	var findings: Dictionary = {
		"manual_review_done": true,
		"visible_playtest_done": true,
	}
	for id in [
		"f6_window_open",
		"polished_surface_visible",
		"interaction_line_visible",
		"primary_action_lane_visible",
		"quick_action_rail_visible",
		"guard_line_visible",
		"no_auto_command_commit_visible",
		"existing_buttons_visible",
		"selected_fireteam_panel_consistent",
		"host_client_same_surface_visible",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		findings[id] = true
	findings["issues"] = {}
	return {"reentry_firefight_command_surface_visible_findings": findings}


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
