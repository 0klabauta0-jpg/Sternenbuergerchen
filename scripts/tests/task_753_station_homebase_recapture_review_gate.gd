extends SceneTree

const PLAYTEST_NOTES_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_f6_host_client_playtest_notes.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_753_station_homebase_recapture_review_gate.md"
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
	print("=== TASK_753 Station Homebase Recapture Review Gate ===")
	_test_docs_contract_and_reports()
	_test_open_homebase_review_gate()
	_test_incomplete_homebase_review_gate()
	_test_complete_homebase_review_gate()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_753: FAILED")
		quit(1)
		return
	print("TASK_753: ALL PASSED")
	quit(0)


func _test_docs_contract_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var workbench_text: String = _read_text(WORKBENCH_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_753 task file exists")
	_assert(task_text.contains("Station Homebase Recapture Review Gate"), "Task documents homebase recapture review gate")
	_assert(contract_text.contains("Station-Homebase-Recapture-Review-Gate (TASK_753)"), "Command feedback contract documents TASK_753")
	_assert(status_text.contains("TASK_753 - Station Homebase Recapture Review Gate"), "Implementation status tracks TASK_753")
	_assert(roadmap_text.contains("TASK_753 - Station Homebase Recapture Review Gate (implementiert)"), "Roadmap marks TASK_753 implemented")
	_assert(handbook_text.contains("TASK_753 - Station Homebase Recapture Review Gate"), "Current handbook references TASK_753")
	_assert(handbook_text.contains("station_homebase_recapture_review_gate"), "Current handbook exports TASK_753 fields")
	_assert(workbench_text.contains("Gate: TASK_753"), "TASK_727 workbench shows TASK_753 gate badge")
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.homebase_recapture.manual_review_done"'), "Workbench exports manual homebase review checkbox")
	for id in HOMEBASE_CHECK_IDS:
		_assert(workbench_text.contains('data-export-key="station_scenario_playtest.homebase_recapture.%s"' % id), "Workbench exports homebase check %s" % id)
	_assert(workbench_text.contains('data-export-key="station_scenario_playtest.notes.homebase_recapture"'), "Workbench exports homebase recapture notes")
	_assert(workbench_text.contains("TASK_754 - Station Homebase Recapture Findings"), "Workbench routes completed review to TASK_754")


func _test_open_homebase_review_gate() -> void:
	var snapshot: Dictionary = _build_snapshot({})
	var review: Dictionary = Dictionary(snapshot.get("homebase_recapture_review", {}))
	_assert(_snapshot_is_read_only(review), "Open homebase review remains read-only")
	_assert(String(snapshot.get("homebase_recapture_review_status", "")) == "needs_homebase_recapture_review", "Top-level homebase review status is open")
	_assert(String(review.get("status", "")) == "needs_homebase_recapture_review", "Review gate waits for manual review")
	_assert(bool(review.get("evidence_ready", false)), "Review gate sees TASK_752 evidence")
	_assert(not bool(review.get("manual_review_done", true)), "Open review does not claim manual review done")
	_assert(int(review.get("completed_check_count", -1)) == 0, "Open review has no completed checks")
	_assert(int(review.get("required_check_count", 0)) == HOMEBASE_CHECK_IDS.size(), "Open review exposes all required checks")
	_assert(String(review.get("recommended_next_task", "")) == "TASK_753 - run Station Homebase Recapture Workbench review", "Open review recommends running TASK_753")


func _test_incomplete_homebase_review_gate() -> void:
	var notes: Dictionary = _homebase_notes({
		"manual_review_done": true,
		"cargo_end_reached": true,
		"debrief_visible_after_cargo": true,
	})
	var snapshot: Dictionary = _build_snapshot(notes)
	var review: Dictionary = Dictionary(snapshot.get("homebase_recapture_review", {}))
	_assert(String(review.get("status", "")) == "needs_homebase_recapture_completion", "Incomplete review reports completion gap")
	_assert(bool(review.get("manual_review_done", false)), "Incomplete review records manual review done")
	_assert(int(review.get("completed_check_count", -1)) == 2, "Incomplete review counts completed checks")
	_assert(_array_contains(review.get("missing_check_ids", []), "return_homebase_clicked"), "Incomplete review lists missing return-homebase check")
	_assert(_array_contains(review.get("missing_check_ids", []), "homebase_next_sortie_line_matches_task_749"), "Incomplete review lists missing TASK_749 line check")
	_assert(not bool(review.get("ready_for_findings", true)), "Incomplete review is not ready for findings")
	_assert(String(review.get("recommended_next_task", "")) == "TASK_753 - complete missing Homebase recapture checks", "Incomplete review recommends completing checks")


func _test_complete_homebase_review_gate() -> void:
	var notes: Dictionary = _complete_homebase_notes()
	var snapshot: Dictionary = _build_snapshot(notes)
	var review: Dictionary = Dictionary(snapshot.get("homebase_recapture_review", {}))
	_assert(String(review.get("status", "")) == "ready_for_homebase_findings", "Complete review is ready for findings")
	_assert(bool(review.get("manual_review_done", false)), "Complete review records manual review done")
	_assert(int(review.get("completed_check_count", -1)) == HOMEBASE_CHECK_IDS.size(), "Complete review counts all checks")
	_assert(Array(review.get("missing_check_ids", [])).is_empty(), "Complete review has no missing checks")
	_assert(bool(review.get("ready_for_findings", false)), "Complete review marks ready for findings")
	_assert(String(review.get("recommended_next_task", "")) == "TASK_754 - Station Homebase Recapture Findings", "Complete review routes to TASK_754")
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
