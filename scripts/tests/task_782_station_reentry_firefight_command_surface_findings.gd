extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_command_surface_findings.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_782_station_reentry_firefight_command_surface_findings.md"
const TASK_781_PATH: String = "res://docs/tasks/TASK_781_station_reentry_firefight_command_surface_recapture.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const PACKET_TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_command_surface_recapture.ps1"
const PACKET_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_recapture.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_command_surface_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_782 Station Reentry Firefight Command Surface Findings ===")
	_test_docs_contract_and_report()
	_test_missing_packet_blocks()
	_test_open_command_surface_review_routes_back_to_task_781()
	_test_incomplete_checks_are_reported()
	_test_issue_flags_route_to_targeted_tasks()
	_test_clean_command_surface_review_routes_forward()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_782: FAILED")
		quit(1)
		return
	print("TASK_782: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_782 task file exists")
	_assert(FileAccess.file_exists(TASK_781_PATH), "TASK_781 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Command Surface Findings"), "TASK_782 task names command surface findings")
	_assert(status_text.contains("TASK_782 - Station Reentry Firefight Command Surface Findings"), "Implementation status tracks TASK_782")
	_assert(roadmap_text.contains("TASK_782 - Station Reentry Firefight Command Surface Findings (implementiert)"), "Roadmap marks TASK_782 implemented")
	_assert(contract_text.contains("Station-Reentry-Firefight-Command-Surface-Findings"), "Mission command feedback contract documents TASK_782")
	_assert(report_text.contains("Aktueller Griff: TASK_782"), "Reentry handbook marks TASK_782 current")
	_assert(report_text.contains("station_reentry_firefight_command_surface_findings.json"), "Reentry handbook names TASK_782 findings manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface_findings.manual_review_done"'), "Reentry handbook exports TASK_782 manual review check")
	_assert(report_text.contains('data-export-key="reentry_firefight_command_surface_findings.issues.quick_actions_hidden"'), "Reentry handbook exports TASK_782 issue flags")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_command_surface_findings.v1", "TASK_782 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_781 packet blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_781"), "Missing packet recommends TASK_781")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing packet creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Missing-packet findings remain read-only")


func _test_open_command_surface_review_routes_back_to_task_781() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_command_surface_review", "Open command-surface review routes back to TASK_781")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_781"), "Open review recommends TASK_781 run")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open review does not claim manual done")
	_assert(not bool(snapshot.get("visible_recapture_done", true)), "Open review does not claim recapture done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("interaction_line_visible"), "Open review reports missing interaction line")
	_assert(_snapshot_is_read_only(snapshot), "Open findings remain read-only")


func _test_incomplete_checks_are_reported() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _partial_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "needs_command_surface_review_completion", "Partial review requires completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 4, "Partial review counts completed checks")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("hold_fire_visible_when_ff_risk"), "Missing checks include Hold Fire")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("workbench_json_exported"), "Missing checks include workbench export")
	_assert(_snapshot_is_read_only(snapshot), "Partial findings remain read-only")


func _test_issue_flags_route_to_targeted_tasks() -> void:
	var notes: Dictionary = _complete_notes()
	notes["reentry_firefight_command_surface_findings"]["issues"] = {
		"quick_actions_hidden": true,
		"host_client_surface_mismatch": true,
	}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_command_surface_polish", "Issue notes route to targeted command-surface polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_780"), "Quick-action issue routes to TASK_780")
	_assert(_snapshot_is_read_only(snapshot), "Issue findings remain read-only")


func _test_clean_command_surface_review_routes_forward() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _complete_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_next_station_firefight_iteration", "Complete clean review routes forward")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_783"), "Clean review recommends TASK_783")
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
		"packet_manifest_path": "tmp/station_reentry_firefight_command_surface_recapture.json",
		"manifest_path": "tmp/station_reentry_firefight_command_surface_findings.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_782 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_782 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_782", "Manifest records TASK_782")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_781", "Manifest records TASK_781 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_command_surface_review", "Manifest preserves open command-surface review status")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _run_packet_tool() -> void:
	_write_interaction_manifest()
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(PACKET_TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_781 packet tool exits 0 for TASK_782")


func _write_interaction_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.station_reentry_firefight_interaction_polish.v1",
		"task_id": "TASK_780",
		"status": "ready_for_firefight_interaction_playtest",
		"interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"primary_action": {"id": "hold_cover", "label": "HOLD"},
		"quick_actions": [
			{"id": "hold_cover", "label": "HOLD"},
			{"id": "flank", "label": "FLANK"},
			{"id": "hold_fire", "label": "HOLD FIRE"},
			{"id": "suppress", "label": "SUP"},
			{"id": "move_cover", "label": "MOVE"},
		],
		"uses_existing_commands_only": true,
		"no_auto_command_commit": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
	}
	var file := FileAccess.open("res://tmp/station_reentry_firefight_interaction_polish.json", FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_780 manifest for TASK_782 setup")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists("res://tmp/station_reentry_firefight_interaction_polish.json"), "TASK_780 interaction manifest is prepared for TASK_782")


func _build_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_command_surface_recapture.v1",
		"task_id": "TASK_781",
		"source_task_id": "TASK_780",
		"target_id": "station_reentry_firefight_command_surface_recapture",
		"status": "ready_to_capture_firefight_command_surface",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"expected_interaction_line": "FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_no_auto_command_commit": true,
		"expected_uses_existing_commands_only": true,
	}


func _partial_notes() -> Dictionary:
	return {
		"reentry_firefight_command_surface_findings": {
			"manual_review_done": true,
			"visible_recapture_done": true,
			"f6_window_open": true,
			"interaction_line_visible": true,
			"primary_action_visible": true,
			"quick_actions_visible": true,
		},
	}


func _complete_notes() -> Dictionary:
	var findings: Dictionary = {
		"manual_review_done": true,
		"visible_recapture_done": true,
	}
	for id in [
		"f6_window_open",
		"interaction_line_visible",
		"primary_action_visible",
		"quick_actions_visible",
		"hold_flank_sup_visible",
		"hold_fire_visible_when_ff_risk",
		"no_auto_command_commit_visible",
		"selected_fireteam_panel_consistent",
		"command_matrix_buttons_reachable",
		"host_client_same_surface_visible",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		findings[id] = true
	findings["issues"] = {}
	return {"reentry_firefight_command_surface_findings": findings}


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
