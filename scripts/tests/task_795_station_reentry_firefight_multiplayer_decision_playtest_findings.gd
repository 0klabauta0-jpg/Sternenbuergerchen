extends SceneTree

const FINDINGS_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_decision_playtest_findings.gd")
const ACCEPTANCE_SCRIPT: GDScript = preload("res://scripts/mission/station_reentry_firefight_multiplayer_decision_acceptance.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_795_station_reentry_firefight_multiplayer_decision_playtest_findings.md"
const TASK_794_PATH: String = "res://docs/tasks/TASK_794_station_reentry_firefight_multiplayer_decision_playtest_packet.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_reentry_2026_07_01.html"
const PACKET_TOOL_PATH: String = "res://scripts/tools/prepare_station_reentry_firefight_multiplayer_decision_playtest_packet.ps1"
const ACCEPTANCE_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_decision_acceptance.json"
const PACKET_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_decision_playtest_packet.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_reentry_firefight_multiplayer_decision_playtest_findings.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_795 Station Reentry Firefight Multiplayer Decision Playtest Findings ===")
	_test_docs_contract_and_report()
	_test_missing_packet_blocks()
	_test_open_visible_review_routes_back_to_task_794()
	_test_incomplete_checks_are_reported()
	_test_issue_flags_route_to_targeted_tasks()
	_test_clean_review_routes_forward_to_task_796()
	_test_actual_manifest_write()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_795: FAILED")
		quit(1)
		return
	print("TASK_795: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_795 task file exists")
	_assert(FileAccess.file_exists(TASK_794_PATH), "TASK_794 task remains available")
	_assert(task_text.contains("Station Reentry Firefight Multiplayer Decision Playtest Findings"), "TASK_795 task names findings")
	_assert(status_text.contains("TASK_795 - Station Reentry Firefight Multiplayer Decision Playtest Findings"), "Implementation status tracks TASK_795")
	_assert(roadmap_text.contains("TASK_795 - Station Reentry Firefight Multiplayer Decision Playtest Findings (implementiert)"), "Roadmap marks TASK_795 implemented")
	_assert(roadmap_text.contains("TASK_796 - Station Reentry Firefight Multiplayer Decision Playtest Acceptance"), "Roadmap advances to TASK_796")
	_assert(contract_text.contains("Station-Reentry-Firefight-Multiplayer-Decision-Playtest-Findings"), "Mission command feedback contract documents TASK_795")
	_assert(report_text.contains("Aktueller Griff: TASK_795"), "Reentry handbook marks TASK_795 current")
	_assert(report_text.contains("station_reentry_firefight_multiplayer_decision_playtest_findings.json"), "Reentry handbook names TASK_795 manifest")
	_assert(report_text.contains('data-export-key="reentry_firefight_multiplayer_decision_playtest_findings.manual_review_done"'), "Reentry handbook exports TASK_795 manual review check")
	_assert(report_text.contains('data-export-key="reentry_firefight_multiplayer_decision_playtest_findings.issues.decision_line_mismatch"'), "Reentry handbook exports TASK_795 issue flags")


func _test_missing_packet_blocks() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", {}, {}, {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_findings.v1", "TASK_795 schema is stable")
	_assert(String(snapshot.get("status", "")) == "blocked", "Missing TASK_794 packet blocks")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_794"), "Missing packet recommends TASK_794")
	_assert(int(snapshot.get("blocking_issue_count", 0)) >= 1, "Missing packet creates blocker")
	_assert(_snapshot_is_read_only(snapshot), "Missing-packet findings remain read-only")


func _test_open_visible_review_routes_back_to_task_794() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), {}, {}))
	_assert(String(snapshot.get("status", "")) == "needs_visible_multiplayer_decision_playtest_review", "Open visible review routes back to TASK_794")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_794"), "Open review recommends TASK_794 run")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Open review does not claim manual done")
	_assert(not bool(snapshot.get("visible_review_done", true)), "Open review does not claim visible review done")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("host_window_open"), "Open review reports missing host window")
	_assert(_snapshot_is_read_only(snapshot), "Open findings remain read-only")


func _test_incomplete_checks_are_reported() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _partial_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "needs_multiplayer_decision_playtest_completion", "Partial review requires completion")
	_assert(int(snapshot.get("completed_check_count", 0)) == 6, "Partial review counts completed checks")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("host_client_same_guard_line"), "Missing checks include guard-line sync")
	_assert(Array(snapshot.get("missing_check_ids", [])).has("workbench_json_exported"), "Missing checks include workbench export")
	_assert(_snapshot_is_read_only(snapshot), "Partial findings remain read-only")


func _test_issue_flags_route_to_targeted_tasks() -> void:
	var notes: Dictionary = _complete_notes()
	notes["reentry_firefight_multiplayer_decision_playtest_findings"]["issues"] = {
		"decision_line_mismatch": true,
		"peer_team_context_mixed": true,
	}
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), notes, {}))
	_assert(String(snapshot.get("status", "")) == "needs_targeted_multiplayer_decision_polish", "Issue notes route to targeted polish")
	_assert(int(snapshot.get("active_issue_count", 0)) == 2, "Two active issues are counted")
	_assert(int(snapshot.get("action_item_count", 0)) == 2, "Two action items are created")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_770"), "Decision-line mismatch routes to TASK_770")
	_assert(_snapshot_is_read_only(snapshot), "Issue findings remain read-only")


func _test_clean_review_routes_forward_to_task_796() -> void:
	var snapshot: Dictionary = Dictionary(FINDINGS_SCRIPT.call("build_snapshot", _build_packet(), _complete_notes(), {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_multiplayer_decision_playtest_acceptance", "Complete clean review routes forward")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_796"), "Clean review recommends TASK_796")
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
		"packet_manifest_path": "tmp/station_reentry_firefight_multiplayer_decision_playtest_packet.json",
		"manifest_path": "tmp/station_reentry_firefight_multiplayer_decision_playtest_findings.json",
	}))
	manifest["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_795 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_795 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_795", "Manifest records TASK_795")
	_assert(String(parsed.get("source_task_id", "")) == "TASK_794", "Manifest records TASK_794 source")
	_assert(String(parsed.get("status", "")) == "needs_visible_multiplayer_decision_playtest_review", "Manifest preserves open multiplayer playtest status")
	_assert(String(parsed.get("expected_decision_line", "")).contains("NEXT HOLD"), "Manifest carries expected decision line")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")


func _run_packet_tool() -> void:
	_write_acceptance_manifest()
	var output: Array = []
	var exit_code: int = OS.execute("powershell", ["-ExecutionPolicy", "Bypass", "-File", ProjectSettings.globalize_path(PACKET_TOOL_PATH)], output, true, false)
	_assert(exit_code == 0, "TASK_794 packet tool exits 0 for TASK_795")


func _write_acceptance_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var acceptance: Dictionary = Dictionary(ACCEPTANCE_SCRIPT.call("build_snapshot", _findings(), {
		"manifest_path": "tmp/station_reentry_firefight_multiplayer_decision_acceptance.json",
	}))
	var file := FileAccess.open(ACCEPTANCE_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_793 acceptance manifest for TASK_795 setup")
		return
	file.store_string(JSON.stringify(acceptance, "\t"))
	file.close()
	_assert(FileAccess.file_exists(ACCEPTANCE_MANIFEST_PATH), "TASK_793 acceptance manifest is prepared for TASK_795")


func _build_packet() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_multiplayer_decision_playtest_packet.v1",
		"task_id": "TASK_794",
		"source_task_id": "TASK_793",
		"target_id": "station_reentry_firefight_multiplayer_decision_playtest",
		"status": "ready_to_playtest_firefight_multiplayer_decision",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"scenario_path": "res://scenes/tests/station_reentry_firefight_decision_playtest.tscn",
		"workbench_path": "docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"workbench_file_uri": "file:///C:/dev/SternenBuergerchen/docs/reports/project_current_state_handbook_reentry_2026_07_01.html",
		"acceptance_status": "accepted_for_multiplayer_firefight_decision_slice",
		"accepted_for_multiplayer_firefight_decision_slice": true,
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_reason_line": "WHY FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_confirm_control": "existing command buttons / GO",
		"expected_no_auto_command_commit": true,
		"expected_existing_commands_only": true,
		"expected_host_client_context_visible": true,
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
		"manual_two_window_playtest_required": true,
		"manual_two_window_playtest_done": false,
	}


func _partial_notes() -> Dictionary:
	return {
		"reentry_firefight_multiplayer_decision_playtest_findings": {
			"manual_review_done": true,
			"visible_review_done": true,
			"host_window_open": true,
			"client_window_open": true,
			"host_decision_card_visible": true,
			"client_decision_card_visible": true,
			"host_client_same_decision_line": true,
			"host_client_same_primary_action": true,
		},
	}


func _complete_notes() -> Dictionary:
	var findings: Dictionary = {
		"manual_review_done": true,
		"visible_review_done": true,
	}
	for id in [
		"host_window_open",
		"client_window_open",
		"host_decision_card_visible",
		"client_decision_card_visible",
		"host_client_same_decision_line",
		"host_client_same_primary_action",
		"host_client_same_quick_actions",
		"host_client_same_reason_line",
		"host_client_same_guard_line",
		"host_client_same_confirm_control",
		"no_auto_command_commit_visible",
		"existing_buttons_visible",
		"peer_team_context_distinct",
		"decision_choice_feels_actionable",
		"firefight_response_stays_fast",
		"screenshot_saved",
		"workbench_json_exported",
	]:
		findings[id] = true
	findings["issues"] = {}
	return {"reentry_firefight_multiplayer_decision_playtest_findings": findings}


func _findings() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_reentry_firefight_decision_host_client_findings.v1",
		"task_id": "TASK_792",
		"source_task_id": "TASK_791",
		"status": "ready_for_firefight_multiplayer_decision_acceptance",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"manual_review_done": true,
		"visible_review_done": true,
		"missing_check_ids": [],
		"active_issue_count": 0,
		"action_items": [],
		"expected_decision_line": "NEXT HOLD | ALT FLANK / HOLD FIRE / SUP / MOVE",
		"expected_primary_action_label": "HOLD",
		"expected_quick_action_labels": ["HOLD", "FLANK", "HOLD FIRE", "SUP", "MOVE"],
		"expected_reason_line": "WHY FF HIT | WOUNDED_PRESSURE | S3/H1/FF1 | NEXT HOLD / FLANK / HOLD FIRE / SUP",
		"expected_guard_line": "NO AUTO CMD | EXISTING BUTTONS",
		"expected_confirm_control": "existing command buttons / GO",
		"expected_no_auto_command_commit": true,
		"expected_existing_commands_only": true,
		"expected_host_client_context_visible": true,
		"expected_host_role": "HOST P1 ALPHA",
		"expected_client_role": "CLIENT P2 BRAVO",
	}


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
