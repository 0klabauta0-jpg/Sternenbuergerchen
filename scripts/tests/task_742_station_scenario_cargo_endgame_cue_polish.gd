extends SceneTree

const ROUTE_CUE_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_route_cue_polish.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_742_station_scenario_cargo_endgame_cue_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_742 Station Scenario Cargo Endgame Cue Polish ===")
	_test_docs_contract_and_report()
	_test_direct_cargo_cue_language()
	_test_existing_aa_and_door_language_stays_stable()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_742: FAILED")
		quit(1)
		return
	print("TASK_742: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var presenter_text: String = _read_text("res://scripts/mission/station_scenario_route_cue_polish.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_742 task file exists")
	_assert(task_text.contains("Station Scenario Cargo Endgame Cue Polish"), "Task documents cargo endgame cue polish")
	_assert(contract_text.contains("Station Scenario Cargo Endgame Cue Polish"), "Interaction contract documents TASK_742")
	_assert(status_text.contains("TASK_742 - Station Scenario Cargo Endgame Cue Polish"), "Implementation status tracks TASK_742")
	_assert(roadmap_text.contains("TASK_742 - Station Scenario Cargo Endgame Cue Polish (implementiert)"), "Roadmap marks TASK_742 implemented")
	_assert(report_text.contains("TASK_742 - Station Scenario Cargo Endgame Cue Polish"), "Current handbook references TASK_742")
	_assert(report_text.contains("station_scenario_cargo_endgame_cue_polish"), "Current handbook exports TASK_742 fields")
	_assert(presenter_text.contains("halten bis Abflug"), "Presenter contains cargo hold language")
	_assert(presenter_text.contains("Cargo weg | Debrief"), "Presenter contains cargo done language")


func _test_direct_cargo_cue_language() -> void:
	var hold_snapshot: Dictionary = _build_cargo_snapshot("in_progress", "CARGO HOLD 7/12s")
	_assert(_snapshot_is_read_only(hold_snapshot), "Cargo hold cue is read-only")
	_assert(String(hold_snapshot.get("cue_line", "")) == "CUE CARGO: FT1 halten bis Abflug | 7/12s", "Cargo hold cue tells player to hold until departure")
	_assert(String(hold_snapshot.get("detail_line", "")).contains("Cargo-Hold laeuft"), "Cargo hold detail names hold state")
	_assert(bool(hold_snapshot.get("uses_player_action_language", false)), "Cargo hold cue uses player-action language")
	_assert(bool(hold_snapshot.get("line_within_limit", false)), "Cargo hold cue stays within line limit")

	var departing_snapshot: Dictionary = _build_cargo_snapshot("departing", "CARGO DEPARTING 65%")
	_assert(String(departing_snapshot.get("cue_line", "")) == "CUE CARGO: Abflug laeuft | 65%", "Cargo departing cue names active departure")
	_assert(String(departing_snapshot.get("detail_line", "")).contains("hebt ab"), "Cargo departing detail explains liftoff")
	_assert(bool(departing_snapshot.get("uses_player_action_language", false)), "Cargo departing cue uses player-action language")

	var departed_snapshot: Dictionary = _build_cargo_snapshot("complete", "")
	_assert(String(departed_snapshot.get("cue_line", "")) == "CUE CARGO: Cargo weg | Debrief", "Cargo complete cue routes to Debrief")
	_assert(String(departed_snapshot.get("detail_line", "")).contains("Debrief"), "Cargo complete detail mentions Debrief")

	var done_snapshot: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "DONE", "all_gates_complete": true},
		{"schema": "gate", "all_gates_complete": true},
		{},
		{}
	))
	_assert(String(done_snapshot.get("cue_line", "")) == "CUE DONE: Cargo weg | Debrief", "All-complete cue uses Cargo/Debrief language")
	_assert(bool(done_snapshot.get("all_gates_complete", false)), "Done snapshot records all gates complete")


func _test_existing_aa_and_door_language_stays_stable() -> void:
	var far_aa: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "AA"},
		{
			"schema": "gate",
			"next_step_id": "disable_air_defense",
			"next_runtime_use_status": "out_of_range",
			"next_interaction": {"nearest_fireteam_id": "blue", "distance_world": 3859.0},
		},
		{},
		{}
	))
	_assert(String(far_aa.get("cue_line", "")) == "CUE AA: BLUE naeher ran | 3.9km", "Existing far AA cue stays stable")

	var usable_door: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "DOOR"},
		{
			"schema": "gate",
			"next_step_id": "open_station_door",
			"next_runtime_use_status": "usable",
			"next_action_label": "BREACH",
			"next_interaction": {"nearest_fireteam_id": "ft1", "distance_world": 32.0},
		},
		{"schema": "feedback", "primary_feedback": {"status": "usable"}},
		{}
	))
	_assert(String(usable_door.get("cue_line", "")) == "CUE DOOR: FT1 BREACH + GO", "Existing Door cue stays stable")


func _build_cargo_snapshot(runtime_status: String, progress_line: String) -> Dictionary:
	return Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "CARGO"},
		{
			"schema": "gate",
			"next_step_id": "cargo_touchdown_extract",
			"next_runtime_use_status": runtime_status,
			"next_action_label": "DEFEND",
			"next_interaction": {"nearest_fireteam_id": "ft1", "distance_world": 48.0},
		},
		{"schema": "feedback", "primary_feedback": {"status": runtime_status}},
		{"schema": "progress", "compact_line": progress_line}
	))


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
