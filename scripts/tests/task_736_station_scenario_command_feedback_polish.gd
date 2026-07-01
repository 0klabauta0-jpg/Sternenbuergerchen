extends SceneTree

const ROUTE_CUE_SCRIPT: GDScript = preload("res://scripts/mission/station_scenario_route_cue_polish.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_736_station_scenario_command_feedback_polish.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_scenario_command_feedback_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_736 Station Scenario Command Feedback Polish ===")
	_test_docs_contract_and_report()
	_test_direct_cue_language()
	await _test_scene_command_feedback_language()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_736: FAILED")
		quit(1)
		return
	print("TASK_736: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var presenter_text: String = _read_text("res://scripts/mission/station_scenario_route_cue_polish.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_736 task file exists")
	_assert(task_text.contains("Station Scenario Command Feedback Polish"), "Task documents command feedback polish")
	_assert(contract_text.contains("Station Scenario Command Feedback Polish"), "Interaction contract documents TASK_736")
	_assert(status_text.contains("TASK_736 - Station Scenario Command Feedback Polish"), "Implementation status tracks TASK_736")
	_assert(roadmap_text.contains("TASK_736 - Station Scenario Command Feedback Polish (implementiert)"), "Roadmap marks TASK_736 implemented")
	_assert(report_text.contains("TASK_736 - Station Scenario Command Feedback Polish"), "Current handbook references TASK_736")
	_assert(report_text.contains('data-export-key="station_scenario_command_feedback_polish.manifest_path"'), "Current handbook exports TASK_736 manifest")
	_assert(presenter_text.contains("station_route_player_action_cue_v2"), "Presenter exposes polished style id")


func _test_direct_cue_language() -> void:
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
	_assert(_snapshot_is_read_only(far_aa), "Far AA cue is read-only")
	_assert(String(far_aa.get("cue_line", "")) == "CUE AA: BLUE naeher ran | 3.9km", "Far AA cue uses player-action language and km distance")
	_assert(String(far_aa.get("distance_text", "")) == "3.9km", "Far AA cue exports formatted km distance")
	_assert(bool(far_aa.get("contains_distance_text", false)), "Far AA cue confirms distance text")
	_assert(bool(far_aa.get("uses_player_action_language", false)), "Far AA cue confirms player-action language")
	_assert(String(far_aa.get("feedback_style_id", "")) == "station_route_player_action_cue_v2", "Far AA cue exposes style id")

	var near_aa: Dictionary = Dictionary(ROUTE_CUE_SCRIPT.call(
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
	_assert(String(near_aa.get("cue_line", "")).contains("220m"), "Near AA cue keeps meter distance")
	_assert(String(near_aa.get("cue_line", "")).contains("FT2 naeher ran"), "Near AA cue tells the fireteam what to do")

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
	_assert(String(usable_door.get("cue_line", "")) == "CUE DOOR: FT1 BREACH + GO", "Usable Door cue fronts fireteam and GO")
	_assert(bool(usable_door.get("uses_player_action_language", false)), "Usable Door cue confirms player-action language")
	_assert(bool(usable_door.get("line_within_limit", false)), "Usable Door cue stays within line limit")


func _test_scene_command_feedback_language() -> void:
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
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var cue: Dictionary = Dictionary(command_feedback.get("station_scenario_route_cue_polish", {}))
	var density: Dictionary = Dictionary(command_feedback.get("mission_hud_interaction_density", {}))
	var cue_line: String = String(command_feedback.get("station_scenario_route_cue_line", ""))
	_write_manifest({
		"schema": "sternenbuergerchen.station_scenario_command_feedback_polish.v1",
		"task_id": "TASK_736",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"cue_line": cue_line,
		"distance_text": String(cue.get("distance_text", "")),
		"feedback_style_id": String(cue.get("feedback_style_id", "")),
		"mission_control_line": String(density.get("mission_control_line", "")),
		"interaction_progress_deferred_to_route_cue": bool(density.get("interaction_progress_deferred_to_route_cue", false)),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(_snapshot_is_read_only(cue), "Scene polished cue is read-only")
	_assert(String(cue.get("feedback_style_id", "")) == "station_route_player_action_cue_v2", "Scene cue exposes polished style id")
	_assert(bool(cue.get("uses_player_action_language", false)), "Scene cue uses player-action language")
	_assert(bool(cue.get("contains_distance_text", false)), "Scene cue contains formatted distance")
	_assert(cue_line.contains("naeher ran") or cue_line.contains("+ GO"), "Command feedback line contains action language")
	_assert(not cue_line.contains("3859m"), "Command feedback line avoids raw long meter distance")
	_assert(String(density.get("station_route_cue_line", "")) == cue_line, "Mission HUD density mirrors polished cue")
	_assert(String(density.get("mission_control_line", "")).contains(cue_line), "Mission Control ACT line contains polished cue")
	_assert(bool(density.get("interaction_progress_deferred_to_route_cue", false)), "Mission Control defers future progress line to cue/source")
	_assert(not String(density.get("mission_control_line", "")).contains("CARGO blockiert"), "Mission Control ACT line omits future cargo blocker while AA cue is active")
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_736 manifest is written")
	scene.queue_free()
	await _wait_frames(2)


func _write_manifest(manifest: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_736 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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
