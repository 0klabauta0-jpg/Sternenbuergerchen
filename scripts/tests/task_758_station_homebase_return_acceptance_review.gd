extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_758_station_homebase_return_acceptance_review.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"

const HOMEBASE_CHECK_IDS: Array[String] = [
	"cargo_end_reached",
	"debrief_visible_after_cargo",
	"return_homebase_clicked",
	"homebase_summary_mentions_station_drill",
	"homebase_return_panel_title_visible",
	"homebase_return_panel_action_visible",
	"homebase_return_panel_chips_visible",
	"homebase_return_panel_matches_task_755",
	"homebase_next_sortie_line_matches_task_749",
	"old_debug_next_sortie_markers_absent",
	"performance_feels_fast",
	"workbench_notes_exported",
]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_758 Station Homebase Return Acceptance Review ===")
	_test_docs_contract_and_reports()
	_test_missing_review_blocks_acceptance()
	_test_incomplete_checks_block_acceptance()
	_test_complete_review_accepts_slice()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_758: FAILED")
		quit(1)
		return
	print("TASK_758: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_758 task file exists")
	_assert(task_text.contains("Station Homebase Return Acceptance Review"), "TASK_758 task names acceptance review")
	_assert(contract_text.contains("Station-Homebase-Return-Acceptance-Review (TASK_758)"), "Contract documents TASK_758")
	_assert(status_text.contains("TASK_758 - Station Homebase Return Acceptance Review"), "Implementation status tracks TASK_758")
	_assert(roadmap_text.contains("TASK_758 - Station Homebase Return Acceptance Review (implementiert)"), "Roadmap marks TASK_758 implemented")
	_assert(roadmap_text.contains("TASK_759 - Station Slice Next Playtest Target"), "Roadmap routes to TASK_759")
	_assert(handbook_text.contains("TASK_758 - Station Homebase Return Acceptance Review"), "Current handbook references TASK_758")
	_assert(handbook_text.contains('data-export-key="status.task_758_done"'), "Current handbook exports TASK_758 checkbox")
	_assert(handbook_text.contains("station_homebase_return_acceptance"), "Current handbook exports TASK_758 fields")
	_assert(workbench_text.contains("Acceptance: TASK_758"), "Workbench shows TASK_758 acceptance badge")
	_assert(workbench_text.contains("station_scenario_playtest.acceptance.homebase_return_task_id"), "Workbench exports TASK_758 task id")
	_assert(workbench_text.contains("accepted_for_next_station_slice"), "Workbench lists accepted status")


func _test_missing_review_blocks_acceptance() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var acceptance: Dictionary = Dictionary(snapshot.get("homebase_return_acceptance_review", {}))
	_assert(String(snapshot.get("homebase_return_acceptance_status", "")) == "blocked_missing_homebase_return_review", "Top-level acceptance blocks without review")
	_assert(String(acceptance.get("status", "")) == "blocked_missing_homebase_return_review", "Acceptance blocks without review")
	_assert(String(acceptance.get("source_task_id", "")) == "TASK_757", "Acceptance records TASK_757 source")
	_assert(String(acceptance.get("source_recapture_task_id", "")) == "TASK_756", "Acceptance records TASK_756 recapture source")
	_assert(String(acceptance.get("source_panel_task_id", "")) == "TASK_755", "Acceptance records TASK_755 panel source")
	_assert(String(acceptance.get("accepted_scope", "")) == "homebase_return_slice_only", "Acceptance scope is narrow")
	_assert(bool(acceptance.get("not_full_game_acceptance", false)), "Acceptance is not full game acceptance")
	_assert(not bool(acceptance.get("accepted_for_next_station_slice", true)), "Missing review is not accepted")
	_assert(_finding_exists(acceptance, "homebase_return_acceptance_review_missing"), "Missing acceptance finding is present")
	_assert(_snapshot_is_read_only(acceptance), "Missing-review acceptance remains read-only")


func _test_incomplete_checks_block_acceptance() -> void:
	var snapshot: Dictionary = _build_snapshot(_homebase_notes({
		"manual_review_done": true,
		"cargo_end_reached": true,
		"debrief_visible_after_cargo": true,
		"return_homebase_clicked": true,
	}))
	var acceptance: Dictionary = Dictionary(snapshot.get("homebase_return_acceptance_review", {}))
	_assert(String(acceptance.get("status", "")) == "needs_task_756_completion", "Incomplete review blocks acceptance")
	_assert(String(acceptance.get("source_refresh_status", "")) == "needs_task_756_panel_check_completion", "Acceptance records incomplete refresh")
	_assert(_array_contains(acceptance.get("missing_check_ids", []), "homebase_return_panel_matches_task_755"), "Acceptance carries missing TASK_755 panel match")
	_assert(_array_contains(acceptance.get("missing_check_ids", []), "workbench_notes_exported"), "Acceptance carries missing notes export")
	_assert(not bool(acceptance.get("accepted_for_next_station_slice", true)), "Incomplete review is not accepted")
	_assert(String(acceptance.get("recommended_next_task", "")) == "TASK_758 - complete TASK_756 checks before acceptance", "Incomplete review routes to check completion")
	_assert(_finding_exists(acceptance, "homebase_return_acceptance_missing_checks"), "Incomplete acceptance finding is present")


func _test_complete_review_accepts_slice() -> void:
	var snapshot: Dictionary = _build_snapshot(_complete_homebase_notes())
	var acceptance: Dictionary = Dictionary(snapshot.get("homebase_return_acceptance_review", {}))
	_assert(String(acceptance.get("status", "")) == "accepted_for_next_station_slice", "Complete review accepts next station slice")
	_assert(String(acceptance.get("source_refresh_status", "")) == "ready_for_homebase_acceptance_review", "Acceptance records ready refresh")
	_assert(Array(acceptance.get("missing_check_ids", [])).is_empty(), "Accepted slice has no missing checks")
	_assert(bool(acceptance.get("accepted_for_next_station_slice", false)), "Acceptance marks next station slice accepted")
	_assert(String(acceptance.get("recommended_next_task", "")) == "TASK_759 - Station Slice Next Playtest Target", "Accepted slice routes to TASK_759")
	_assert(_finding_exists(acceptance, "homebase_return_slice_accepted"), "Accepted finding is present")
	_assert(_snapshot_is_read_only(snapshot), "Complete snapshot remains read-only")


func _build_snapshot(notes: Dictionary) -> Dictionary:
	return Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), notes, {
		"recapture_findings": _fake_task_756_capture_manifest(),
		"recapture_manifest_path": "tmp/host_client_two_window_real_run_review.json",
	}))


func _fake_task_726_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_one_screen_scenario_drill.v1",
		"task_id": "TASK_726",
		"status": "ready_for_f6_host_client_playtest",
		"scenario_path": "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _fake_task_756_capture_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_two_window_real_run_review.v1",
		"task_id": "manual_host_client_two_window_real_run",
		"status": "ready_for_manual_review",
		"real_run_done": true,
		"host_crop_ready": true,
		"client_crop_ready": true,
		"cue_visible": true,
		"future_blocker_hidden_in_display": true,
		"station_homebase_host_client_recapture_task_id": "TASK_750",
		"station_homebase_real_window_recapture_task_id": "TASK_756",
		"station_homebase_host_client_recapture_packet_path": "tmp/station_homebase_host_client_recapture_packet.json",
		"station_homebase_expected_summary_fragment": "Station Drill",
		"station_homebase_expected_readiness_line": "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben",
		"station_homebase_return_panel_polish_task_id": "TASK_755",
		"station_homebase_expected_return_panel_style_id": "task_755_station_homebase_return_panel_v1",
		"station_homebase_expected_return_panel_title": "Rueckkehr abgeschlossen",
		"station_homebase_expected_return_panel_action": "Naechster Auftrag: Fireteam bereitstellen",
		"station_homebase_expected_return_panel_chip_count": 5,
		"station_homebase_expected_return_panel_step_labels": ["Auswertung ansehen", "Fireteam bereitstellen", "Loadout pruefen", "Dropship beladen", "Start freigeben"],
		"station_homebase_forbidden_debug_fragments": ["Next sortie", "Review gains", "Stage fireteam", "Assign loadout", "Load dropship", "Start next sortie"],
		"station_homebase_recapture_review_required": true,
		"station_homebase_recapture_review_done": false,
		"station_homebase_recapture_manual_checks": HOMEBASE_CHECK_IDS,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": false,
	}


func _complete_homebase_notes() -> Dictionary:
	var homebase: Dictionary = {"manual_review_done": true}
	for id in HOMEBASE_CHECK_IDS:
		homebase[id] = true
	return _homebase_notes(homebase)


func _homebase_notes(homebase: Dictionary) -> Dictionary:
	return {
		"controls": {
			"station_scenario_playtest": {
				"homebase_recapture": homebase,
			},
		},
	}


func _finding_exists(findings_snapshot: Dictionary, id: String) -> bool:
	for finding_variant in Array(findings_snapshot.get("findings", [])):
		if typeof(finding_variant) == TYPE_DICTIONARY and String(Dictionary(finding_variant).get("id", "")) == id:
			return true
	return false


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
