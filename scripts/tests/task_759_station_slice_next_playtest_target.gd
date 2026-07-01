extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_759_station_slice_next_playtest_target.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const SCENARIO_PATH: String = "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"

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
	print("=== TASK_759 Station Slice Next Playtest Target ===")
	_test_docs_contract_and_reports()
	_test_target_blocks_without_acceptance()
	_test_target_ready_after_acceptance()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_759: FAILED")
		quit(1)
		return
	print("TASK_759: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_759 task file exists")
	_assert(task_text.contains("Station Slice Next Playtest Target"), "TASK_759 task names next playtest target")
	_assert(contract_text.contains("Station-Slice-Next-Playtest-Target (TASK_759)"), "Contract documents TASK_759")
	_assert(status_text.contains("TASK_759 - Station Slice Next Playtest Target"), "Implementation status tracks TASK_759")
	_assert(roadmap_text.contains("TASK_759 - Station Slice Next Playtest Target (implementiert)"), "Roadmap marks TASK_759 implemented")
	_assert(roadmap_text.contains("TASK_760 - Station Reentry Playtest Run Packet"), "Roadmap routes to TASK_760")
	_assert(handbook_text.contains("TASK_759 - Station Slice Next Playtest Target"), "Current handbook references TASK_759")
	_assert(handbook_text.contains('data-export-key="status.task_759_done"'), "Current handbook exports TASK_759 checkbox")
	_assert(handbook_text.contains("station_next_playtest_target"), "Current handbook exports TASK_759 fields")
	_assert(workbench_text.contains("Next Target: TASK_759"), "Workbench shows TASK_759 badge")
	_assert(workbench_text.contains("station_scenario_playtest.next_target.task_id"), "Workbench exports TASK_759 task id")
	_assert(workbench_text.contains("station_reentry_playtest"), "Reports name station reentry target")


func _test_target_blocks_without_acceptance() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var target: Dictionary = Dictionary(snapshot.get("station_next_playtest_target", {}))
	_assert(String(snapshot.get("station_next_playtest_target_status", "")) == "blocked_until_homebase_return_accepted", "Top-level target blocks without acceptance")
	_assert(String(target.get("status", "")) == "blocked_until_homebase_return_accepted", "Target blocks without acceptance")
	_assert(String(target.get("source_task_id", "")) == "TASK_758", "Target records TASK_758 source")
	_assert(String(target.get("target_id", "")) == "station_reentry_playtest", "Target id is stable")
	_assert(not bool(target.get("ready_for_run_packet", true)), "Blocked target is not ready for run packet")
	_assert(String(target.get("recommended_next_task", "")) == "TASK_758 - run Homebase Return acceptance from real Workbench export", "Blocked target routes to acceptance")
	_assert(_snapshot_is_read_only(target), "Blocked target remains read-only")


func _test_target_ready_after_acceptance() -> void:
	var snapshot: Dictionary = _build_snapshot(_complete_homebase_notes())
	var target: Dictionary = Dictionary(snapshot.get("station_next_playtest_target", {}))
	_assert(String(target.get("status", "")) == "ready_for_station_reentry_playtest", "Accepted target is ready for station reentry playtest")
	_assert(String(target.get("source_acceptance_status", "")) == "accepted_for_next_station_slice", "Target records accepted source")
	_assert(String(target.get("target_title", "")) == "Homebase -> naechste Station-Sortie", "Target title is player-facing")
	_assert(String(target.get("scenario_path", "")) == SCENARIO_PATH, "Target uses station drill scenario")
	_assert(bool(target.get("ready_for_run_packet", false)), "Accepted target is ready for run packet")
	_assert(String(target.get("recommended_next_task", "")) == "TASK_760 - Station Reentry Playtest Run Packet", "Accepted target routes to TASK_760")
	_assert(_array_contains(target.get("runbook_steps", []), "Fireteam bereitstellen"), "Runbook includes stage fireteam")
	_assert(_array_contains(target.get("runbook_steps", []), "Loadout pruefen"), "Runbook includes loadout check")
	_assert(_array_contains(target.get("runbook_steps", []), "Dropship beladen"), "Runbook includes dropship load")
	_assert(_array_contains(target.get("runbook_steps", []), "Start freigeben"), "Runbook includes launch release")
	_assert(_array_contains(target.get("runbook_steps", []), "erste Mission-Entscheidung mit Preview treffen"), "Runbook includes first mission decision")
	_assert(_array_contains(target.get("multiplayer_checks", []), "Fireteam-Zuordnung bleibt im Dropship konsistent"), "MP checks include dropship/fireteam consistency")
	_assert(_array_contains(target.get("non_goals", []), "keine Gesamtspiel-Abnahme"), "Non-goals keep scope narrow")
	_assert(_snapshot_is_read_only(snapshot), "Accepted target snapshot remains read-only")


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
