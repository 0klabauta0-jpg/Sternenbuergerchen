extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_754_station_homebase_recapture_findings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const WORKBENCH_PATH: String = "res://docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html"
const EXPECTED_HOMEBASE_LINE: String = "Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben"
const EXPECTED_PACKET_PATH: String = "tmp/station_homebase_host_client_recapture_packet.json"
const EXPECTED_CAPTURE_MANIFEST_PATH: String = "tmp/host_client_two_window_real_run_review.json"

const HOMEBASE_CHECK_IDS: Array[String] = [
	"cargo_end_reached",
	"debrief_visible_after_cargo",
	"return_homebase_clicked",
	"homebase_summary_mentions_station_drill",
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
	print("=== TASK_754 Station Homebase Recapture Findings ===")
	_test_docs_contract_and_reports()
	_test_missing_real_review_blocks_findings()
	_test_incomplete_review_findings()
	_test_complete_review_routes_to_polish()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_754: FAILED")
		quit(1)
		return
	print("TASK_754: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_754 task file exists")
	_assert(task_text.contains("Station Homebase Recapture Findings"), "Task documents homebase recapture findings")
	_assert(contract_text.contains("Station-Homebase-Recapture-Findings (TASK_754)"), "Command feedback contract documents TASK_754")
	_assert(status_text.contains("TASK_754 - Station Homebase Recapture Findings"), "Implementation status tracks TASK_754")
	_assert(roadmap_text.contains("TASK_754 - Station Homebase Recapture Findings (implementiert)"), "Roadmap marks TASK_754 implemented")
	_assert(handbook_text.contains("TASK_754 - Station Homebase Recapture Findings"), "Current handbook references TASK_754")
	_assert(handbook_text.contains("station_homebase_recapture_findings"), "Current handbook exports TASK_754 fields")
	_assert(workbench_text.contains("Findings: TASK_754"), "TASK_727 workbench shows TASK_754 findings badge")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.findings.homebase_recapture_task_id"'), "Workbench exports homebase findings task id")
	_assert(workbench_text.contains("ready_for_homebase_panel_polish"), "Workbench contains findings ready status")
	_assert(workbench_text.contains("TASK_755 - Station Homebase Return Panel Polish"), "Workbench routes ready findings to TASK_755")


func _test_missing_real_review_blocks_findings() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var findings: Dictionary = Dictionary(snapshot.get("homebase_recapture_findings", {}))
	_assert(_snapshot_is_read_only(findings), "Missing-review findings remain read-only")
	_assert(String(snapshot.get("homebase_recapture_findings_status", "")) == "blocked_missing_real_homebase_review", "Top-level findings block without real review")
	_assert(String(findings.get("status", "")) == "blocked_missing_real_homebase_review", "Findings block without real review")
	_assert(String(findings.get("source_review_status", "")) == "needs_homebase_recapture_review", "Findings records open review status")
	_assert(not bool(findings.get("ready_for_runtime_polish", true)), "Missing-review findings are not ready for runtime polish")
	_assert(String(findings.get("recommended_next_task", "")) == "TASK_753 - run Station Homebase Recapture Workbench review", "Missing review routes back to TASK_753")
	_assert(_finding_exists(findings, "real_homebase_recapture_review_missing"), "Missing review finding is present")


func _test_incomplete_review_findings() -> void:
	var snapshot: Dictionary = _build_snapshot(_homebase_notes({
		"manual_review_done": true,
		"cargo_end_reached": true,
		"debrief_visible_after_cargo": true,
	}))
	var findings: Dictionary = Dictionary(snapshot.get("homebase_recapture_findings", {}))
	_assert(String(findings.get("status", "")) == "needs_review_completion", "Incomplete review findings request completion")
	_assert(String(findings.get("source_review_status", "")) == "needs_homebase_recapture_completion", "Incomplete findings record source status")
	_assert(_array_contains(findings.get("missing_check_ids", []), "return_homebase_clicked"), "Incomplete findings include missing return-homebase check")
	_assert(_array_contains(findings.get("missing_check_ids", []), "homebase_next_sortie_line_matches_task_749"), "Incomplete findings include missing TASK_749 line check")
	_assert(not bool(findings.get("ready_for_runtime_polish", true)), "Incomplete findings are not ready for runtime polish")
	_assert(String(findings.get("recommended_next_task", "")) == "TASK_753 - complete missing Homebase recapture checks", "Incomplete findings route back to TASK_753")
	_assert(_finding_exists(findings, "missing_homebase_recapture_checks"), "Incomplete check finding is present")


func _test_complete_review_routes_to_polish() -> void:
	var snapshot: Dictionary = _build_snapshot(_complete_homebase_notes())
	var findings: Dictionary = Dictionary(snapshot.get("homebase_recapture_findings", {}))
	_assert(String(findings.get("status", "")) == "ready_for_homebase_panel_polish", "Complete review findings are ready for panel polish")
	_assert(String(findings.get("source_review_status", "")) == "ready_for_homebase_findings", "Complete findings record source status")
	_assert(Array(findings.get("missing_check_ids", [])).is_empty(), "Complete findings have no missing checks")
	_assert(bool(findings.get("ready_for_runtime_polish", false)), "Complete findings mark runtime polish ready")
	_assert(String(findings.get("recommended_next_task", "")) == "TASK_755 - Station Homebase Return Panel Polish", "Complete findings route to TASK_755")
	_assert(_finding_exists(findings, "homebase_return_panel_polish_ready"), "Panel polish finding is present")
	_assert(_snapshot_is_read_only(snapshot), "Complete snapshot remains read-only")


func _build_snapshot(notes: Dictionary) -> Dictionary:
	return Dictionary(PLAYTEST_NOTES_SCRIPT.call("build_snapshot", _fake_task_726_manifest(), notes, {
		"recapture_findings": _fake_task_751_capture_manifest(),
		"recapture_manifest_path": EXPECTED_CAPTURE_MANIFEST_PATH,
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
