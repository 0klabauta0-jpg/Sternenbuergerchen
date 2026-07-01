extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_752_station_homebase_recapture_workbench_prefill.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const EXPECTED_HOMEBASE_LINE: String = "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben"
const EXPECTED_PACKET_PATH: String = "tmp/station_homebase_host_client_recapture_packet.json"
const EXPECTED_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_752 Station Homebase Recapture Workbench Prefill ===")
	_test_docs_contract_and_reports()
	_test_analyzer_homebase_recapture_prefill_snapshot()
	_test_clean_export_still_manual_review_bound()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_752: FAILED")
		quit(1)
		return
	print("TASK_752: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_752 task file exists")
	_assert(task_text.contains("Station Homebase Recapture Workbench Prefill"), "Task documents homebase recapture workbench prefill")
	_assert(contract_text.contains("Station-Homebase-Recapture-Workbench-Prefill (TASK_752)"), "Command feedback contract documents TASK_752")
	_assert(status_text.contains("TASK_752 - Station Homebase Recapture Workbench Prefill"), "Implementation status tracks TASK_752")
	_assert(roadmap_text.contains("TASK_752 - Station Homebase Recapture Workbench Prefill (implementiert)"), "Roadmap marks TASK_752 implemented")
	_assert(handbook_text.contains("TASK_752 - Station Homebase Recapture Workbench Prefill"), "Current handbook references TASK_752")
	_assert(handbook_text.contains("station_homebase_recapture_workbench_prefill"), "Current handbook exports TASK_752 fields")
	_assert(workbench_text.contains("Prefill: TASK_752"), "TASK_727 workbench shows TASK_752 prefill badge")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.homebase_recapture_metadata_ready"'), "Workbench exports homebase metadata-ready flag")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.homebase_recapture_packet_path"'), "Workbench exports homebase recapture packet path")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.capture_manifest_path"'), "Workbench exports capture manifest path")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.expected_homebase_readiness_line"'), "Workbench exports expected homebase readiness line")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.forbidden_homebase_debug_markers"'), "Workbench exports forbidden old debug markers")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.prefill.homebase_recapture_manual_checks"'), "Workbench exports homebase manual checks")
	_assert(workbench_text.contains(EXPECTED_HOMEBASE_LINE), "Workbench contains expected TASK_749 homebase line")
	_assert(workbench_text.contains(EXPECTED_PACKET_PATH), "Workbench contains TASK_750 packet path")
	_assert(workbench_text.contains(EXPECTED_CAPTURE_MANIFEST_PATH), "Workbench contains TASK_751 capture manifest path")


func _test_analyzer_homebase_recapture_prefill_snapshot() -> void:
	var snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), {}, {
		"recapture_findings": _fake_task_751_capture_manifest(),
		"recapture_manifest_path": EXPECTED_CAPTURE_MANIFEST_PATH,
	}))
	var evidence: Dictionary = Dictionary(snapshot.get("recapture_evidence", {}))
	_assert(_snapshot_is_read_only(snapshot), "Open snapshot remains read-only")
	_assert(String(snapshot.get("status", "")) == "needs_visible_playtest", "Homebase prefill does not complete visible playtest")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Homebase prefill does not claim manual review done")
	_assert(String(snapshot.get("source_recapture_manifest_path", "")) == EXPECTED_CAPTURE_MANIFEST_PATH, "Snapshot records TASK_751 capture manifest path")
	_assert(_snapshot_is_read_only(evidence), "Homebase recapture evidence stays read-only")
	_assert(String(evidence.get("homebase_recapture_task_id", "")) == "TASK_750", "Snapshot records TASK_750 homebase recapture task id")
	_assert(String(evidence.get("homebase_recapture_packet_path", "")) == EXPECTED_PACKET_PATH, "Snapshot records TASK_750 packet path")
	_assert(String(evidence.get("homebase_expected_readiness_line", "")) == EXPECTED_HOMEBASE_LINE, "Snapshot records expected homebase readiness line")
	_assert(String(evidence.get("homebase_expected_summary_fragment", "")) == "Station Drill", "Snapshot records expected summary fragment")
	_assert(bool(evidence.get("homebase_recapture_review_required", false)), "Snapshot records review-required flag")
	_assert(not bool(evidence.get("homebase_recapture_review_done", true)), "Snapshot records review-done as false")
	_assert(bool(evidence.get("homebase_recapture_ready_for_workbench", false)), "Snapshot marks homebase recapture ready for workbench")
	_assert(_array_contains(Dictionary(evidence).get("homebase_forbidden_debug_fragments", []), "Next sortie"), "Snapshot records forbidden old English debug marker")
	_assert(_array_contains(Dictionary(evidence).get("homebase_recapture_manual_checks", []), "homebase_next_sortie_line_matches_task_749"), "Snapshot records manual TASK_749 line check")
	_assert(_array_contains(Dictionary(evidence).get("homebase_recapture_manual_checks", []), "old_debug_next_sortie_markers_absent"), "Snapshot records old-debug absence check")


func _test_clean_export_still_manual_review_bound() -> void:
	var snapshot: Dictionary = Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), _clean_notes(), {
		"recapture_findings": _fake_task_751_capture_manifest(),
		"recapture_manifest_path": EXPECTED_CAPTURE_MANIFEST_PATH,
	}))
	var evidence: Dictionary = Dictionary(snapshot.get("recapture_evidence", {}))
	_assert(String(snapshot.get("status", "")) == "ready_for_findings", "Clean manual export can still reach findings")
	_assert(bool(snapshot.get("manual_review_done", false)), "Clean manual export marks review done")
	_assert(bool(evidence.get("homebase_recapture_ready_for_workbench", false)), "Clean export keeps homebase recapture prefill evidence")
	_assert(not bool(evidence.get("homebase_recapture_review_done", true)), "Prefill evidence does not fabricate homebase review completion")
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


func _fake_task_751_capture_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
		"task_id": "manual_host_client_two_window_real_run",
		"status": "ready_for_manual_review",
		"real_run_done": true,
		"host_crop_ready": true,
		"client_crop_ready": true,
		"host_crop_path": "tmp/host_client_two_window_host_review.png",
		"client_crop_path": "tmp/host_client_two_window_client_review.png",
		"cue_visible": true,
		"identity_text": "CUE AA: BLUE naeher ran | 3.9km\nROUTE AA > DOOR > COM > CARGO | NEXT AA",
		"display_route_line": "ROUTE AA > DOOR > COM > CARGO | NEXT AA",
		"future_blocker_hidden_in_display": true,
		"station_homebase_host_client_recapture_task_id": "TASK_750",
		"station_homebase_host_client_recapture_packet_path": EXPECTED_PACKET_PATH,
		"station_homebase_expected_summary_fragment": "Station Drill",
		"station_homebase_expected_readiness_line": EXPECTED_HOMEBASE_LINE,
		"station_homebase_forbidden_debug_fragments": ["Next sortie", "Review gains", "Stage fireteam", "Assign loadout", "Load dropship", "Start next sortie"],
		"station_homebase_recapture_review_required": true,
		"station_homebase_recapture_review_done": false,
		"station_homebase_recapture_manual_checks": ["cargo_end_reached", "debrief_visible_after_cargo", "return_homebase_clicked", "homebase_summary_mentions_station_drill", "homebase_next_sortie_line_matches_task_749", "old_debug_next_sortie_markers_absent", "performance_feels_fast", "workbench_notes_exported"],
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": false,
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


func _array_contains(value: Variant, expected: String) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for entry in Array(value):
		if String(entry) == expected:
			return true
	return false


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
