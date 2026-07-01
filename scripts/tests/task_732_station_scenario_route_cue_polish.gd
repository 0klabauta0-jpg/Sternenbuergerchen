extends SceneTree

const ROUTE_CUE_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_route_cue_polish.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_732_station_scenario_route_cue_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_732 Station Scenario Route Cue Polish ===")
	_test_docs_contract_and_report()
	_test_direct_cue_cases()
	await _test_mission_scene_exports_route_cue()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_732: FAILED")
		quit(1)
		return
	print("TASK_732: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text("res://scripts/tests/mission_tactical_sandbox_controller.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_732 task file exists")
	_assert(task_text.contains("Station Scenario Route Cue Polish"), "Task documents route cue polish")
	_assert(contract_text.contains("Station Scenario Route Cue Polish"), "Interaction contract documents TASK_732")
	_assert(status_text.contains("TASK_732 - Station Scenario Route Cue Polish"), "Implementation status tracks TASK_732")
	_assert(roadmap_text.contains("TASK_732 - Station Scenario Route Cue Polish (implementiert)"), "Roadmap marks TASK_732 implemented")
	_assert(report_text.contains("TASK_732 - Station Scenario Route Cue Polish"), "Current handbook references TASK_732")
	_assert(report_text.contains('data-export-key="station_scenario_route_cue_polish.cue_line"'), "Current handbook exports TASK_732 cue line")
	_assert(controller_text.contains("get_station_scenario_route_cue_polish_snapshot"), "Controller exposes route cue snapshot")
	_assert(controller_text.contains("station_scenario_route_cue_line"), "Command feedback exports route cue line")


func _test_direct_cue_cases() -> void:
	var usable: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "DOOR", "read_only": true, "ui_sets_gameplay_truth": false},
		{
			"schema": "gate",
			"next_step_id": "open_station_door",
			"next_runtime_use_status": "usable",
			"next_action_label": "BREACH",
			"next_interaction": {"nearest_fireteam_id": "ft1", "distance_world": 32.0},
			"read_only": true,
			"ui_sets_gameplay_truth": false,
		},
		{"schema": "feedback", "primary_feedback": {"status": "usable"}},
		{}
	))
	_assert(_snapshot_is_read_only(usable), "Usable cue is read-only")
	_assert(String(usable.get("cue_line", "")).contains("CUE DOOR"), "Usable cue names Door token")
	_assert(String(usable.get("cue_line", "")).contains("BREACH + GO"), "Usable cue tells player to confirm GO")
	_assert(String(usable.get("cue_line", "")).contains("FT1"), "Usable cue names fireteam token")
	_assert(bool(usable.get("line_within_limit", false)), "Usable cue stays within line limit")

	var out_of_range: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "AA"},
		{
			"schema": "gate",
			"next_step_id": "disable_air_defense",
			"next_runtime_use_status": "out_of_range",
			"next_interaction": {"nearest_fireteam_id": "ft2", "distance_world": 220.0},
		},
		{},
		{}
	))
	_assert(String(out_of_range.get("cue_line", "")).contains("CUE AA"), "Out-of-range cue names AA")
	_assert(String(out_of_range.get("cue_line", "")).contains("220m"), "Out-of-range cue exposes distance")

	var in_progress: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "COM"},
		{
			"schema": "gate",
			"next_step_id": "occupy_station_computer",
			"next_runtime_use_status": "in_progress",
			"next_interaction": {"nearest_fireteam_id": "ft1", "distance_world": 20.0},
		},
		{},
		{"schema": "progress", "compact_line": "COM 50% 9/18s FT1"}
	))
	_assert(String(in_progress.get("cue_line", "")).contains("COM 50% 9/18s FT1"), "In-progress cue reuses progress readability")
	_assert(String(in_progress.get("detail_line", "")).contains("Fireteam im Radius"), "In-progress cue explains hold behavior")

	var done: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
		"build_snapshot",
		{"schema": "route", "next_token": "DONE", "all_gates_complete": true},
		{"schema": "gate", "all_gates_complete": true},
		{},
		{}
	))
	_assert(String(done.get("cue_line", "")).contains("Debrief"), "Done cue points toward extraction/debrief")


func _test_mission_scene_exports_route_cue() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(controller != null and combat_driver != null, "Mission scene exposes controller and driver")
	if controller == null or combat_driver == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures station scenario")
	controller.call("_update_ui")
	await _wait_frames(2)
	var cue: Dictionary = Dictionary(controller.call("get_station_scenario_route_cue_polish_snapshot"))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var density: Dictionary = Dictionary(command_feedback.get("mission_hud_interaction_density", {}))
	var cue_line: String = String(command_feedback.get("station_scenario_route_cue_line", ""))
	_assert(_snapshot_is_read_only(cue), "Scene route cue stays read-only")
	_assert(String(cue.get("schema", "")) == "sternenbuergerchen.station_scenario_route_cue_polish.v1", "Scene cue schema is stable")
	_assert(cue_line.begins_with("CUE "), "Command feedback exports visible cue line")
	_assert(String(command_feedback.get("station_scenario_route_cue_next_token", "")).length() > 0, "Command feedback exports next token")
	_assert(bool(command_feedback.get("station_scenario_route_cue_line_within_limit", false)), "Command feedback cue stays within limit")
	_assert(String(density.get("station_route_cue_line", "")) == cue_line, "Mission HUD density mirrors route cue")
	_assert(bool(density.get("contains_station_route_cue", false)), "Mission HUD density contains route cue")
	_assert(not bool(Dictionary(command_feedback.get("station_scenario_route_cue_polish", {})).get("ui_sets_gameplay_truth", true)), "Command feedback cue does not set gameplay truth")
	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
