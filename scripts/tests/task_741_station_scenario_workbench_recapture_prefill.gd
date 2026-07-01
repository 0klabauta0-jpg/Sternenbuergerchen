extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_741_station_scenario_workbench_recapture_prefill.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const EXPECTED_CUE_LINE: String = "CUE AA: BLUE naeher ran | 3.9km"
const EXPECTED_DISPLAY_ROUTE_LINE: String = "ROUTE AA > DOOR > COM > CARGO | NEXT AA"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_741 Station Scenario Workbench Recapture Prefill ===")
	_test_docs_contract_and_reports()
	_test_analyzer_recapture_prefill_snapshot()
	_test_clean_export_still_ready_for_findings()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_741: FAILED")
		quit(1)
		return
	print("TASK_741: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_741 task file exists")
	_assert(task_text.contains("Station Scenario Workbench Recapture Prefill"), "Task documents workbench recapture prefill")
	_assert(contract_text.contains("Station Scenario Workbench Recapture Prefill"), "Interaction contract documents TASK_741")
	_assert(status_text.contains("TASK_741 - Station Scenario Workbench Recapture Prefill"), "Implementation status tracks TASK_741")
	_assert(roadmap_text.contains("TASK_741 - Station Scenario Workbench Recapture Prefill (implementiert)"), "Roadmap marks TASK_741 implemented")
	_assert(roadmap_text.contains("TASK_740 - Scenario Harness Modernization (geparkt"), "Roadmap parks TASK_740 unless proven")
	_assert(handbook_text.contains("TASK_741 - Station Scenario Workbench Recapture Prefill"), "Current handbook references TASK_741")
	_assert(handbook_text.contains("station_scenario_workbench_recapture_prefill"), "Current handbook exports TASK_741 fields")
	_assert(workbench_text.contains("Prefill: TASK_741"), "TASK_727 workbench shows TASK_741 prefill badge")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.source_recapture_manifest_path"'), "Workbench exports recapture manifest path")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.host_crop_path"'), "Workbench exports host crop path")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.client_crop_path"'), "Workbench exports client crop path")
	_assert(workbench_text.contains(EXPECTED_CUE_LINE), "Workbench contains expected cue line")
	_assert(workbench_text.contains(EXPECTED_DISPLAY_ROUTE_LINE), "Workbench contains neutral display route")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.playtest_done">'), "Workbench keeps playtest done as manual checkbox")


func _test_analyzer_recapture_prefill_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), {}, {
		"recapture_findings": _fake_recapture_findings(),
		"recapture_manifest_path": "tmp/station_scenario_identity_cue_recapture_findings.json",
	}))
	var evidence: Dictionary = Dictionary(snapshot.get("recapture_evidence", {}))
	_assert(_snapshot_is_read_only(snapshot), "Open snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visible_playtest", "Prefill does not complete visible playtest")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Prefill does not claim manual review done")
	_assert(bool(snapshot.get("recapture_ready_for_workbench", false)), "Snapshot marks recapture ready for workbench")
	_assert(_snapshot_is_read_only(evidence), "Recapture evidence stays read-only")
	_assert(String(snapshot.get("source_recapture_manifest_path", "")) == "tmp/station_scenario_identity_cue_recapture_findings.json", "Snapshot records recapture manifest path")
	_assert(String(evidence.get("host_crop_path", "")) == "tmp/host_client_two_window_host_review.png", "Snapshot records host crop path")
	_assert(String(evidence.get("client_crop_path", "")) == "tmp/host_client_two_window_client_review.png", "Snapshot records client crop path")
	_assert(String(evidence.get("display_route_line", "")) == EXPECTED_DISPLAY_ROUTE_LINE, "Snapshot records neutral display route")
	_assert(String(evidence.get("identity_text", "")).contains(EXPECTED_CUE_LINE), "Snapshot records identity cue text")
	_assert(bool(evidence.get("future_blocker_hidden_in_display", false)), "Snapshot records future blocker display guard")


func _test_clean_export_still_ready_for_findings() -> void:
	var snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), _clean_notes(), {
		"recapture_findings": _fake_recapture_findings(),
	}))
	_assert(String(snapshot.get("status", "")) == "ready_for_findings", "Clean manual export stays ready for findings")
	_assert(bool(snapshot.get("manual_review_done", false)), "Clean manual export marks review done")
	_assert(bool(snapshot.get("recapture_ready_for_workbench", false)), "Clean export keeps recapture prefill evidence")
	_assert(String(snapshot.get("recommended_next_task", "")).contains("TASK_728"), "Clean export still routes to TASK_728")


func _fake_task_726_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_one_screen_scenario_drill.v1",
		"task_id": "TASK_726",
		"status": "ready_for_f6_host_client_playtest",
		"scenario_path": "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _fake_recapture_findings() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_scenario_identity_cue_recapture_findings.v1",
		"task_id": "TASK_739",
		"status": "ready_for_task_727_workbench_export",
		"real_run_done": true,
		"host_crop_ready": true,
		"client_crop_ready": true,
		"host_crop_path": "tmp/host_client_two_window_host_review.png",
		"client_crop_path": "tmp/host_client_two_window_client_review.png",
		"cue_visible": true,
		"identity_text": "%s\n%s" % [EXPECTED_CUE_LINE, EXPECTED_DISPLAY_ROUTE_LINE],
		"display_route_line": EXPECTED_DISPLAY_ROUTE_LINE,
		"future_blocker_hidden_in_display": true,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _clean_notes() -> Dictionary:
	var playtest: Dictionary = {}
	for id in [
		"playtest_done",
		"real_f6_window_reviewed",
		"host_client_two_window_reviewed",
		"aa_door_com_cargo_route_readable",
		"door_computer_cargo_cues_obvious",
		"fireteam_orders_feel_fast",
		"performance_feels_fast",
		"no_hud_overlap_blocks_map",
		"wrong_team_or_bravo_context_clear",
	]:
		playtest[id] = true
	playtest["issues"] = {
		"needs_route_readability_polish": false,
		"needs_hud_overlap_polish": false,
		"needs_performance_pass": false,
		"needs_host_client_sync_fix": false,
		"needs_command_feedback_polish": false,
		"needs_old_harness_modernization": false,
	}
	return {
		"controls": {
			"station_scenario_playtest": playtest,
		},
		"active_choices": {
			"station_scenario_playtest": {
				"rating": "good_enough",
			},
		},
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


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
