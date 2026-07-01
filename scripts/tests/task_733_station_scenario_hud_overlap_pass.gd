extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_733_station_scenario_hud_overlap_pass.md"
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
	print("=== TASK_733 Station Scenario HUD Overlap Pass ===")
	_test_docs_contract_and_report()
	await _test_scene_density_policy()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_733: FAILED")
		quit(1)
		return
	print("TASK_733: ALL PASSED")
	quit(0)


func _test_docs_contract_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var controller_text: String = _read_text("res://scripts/tests/mission_tactical_sandbox_controller.gd")
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_733 task file exists")
	_assert(task_text.contains("Station Scenario HUD Overlap Pass"), "Task documents HUD overlap pass")
	_assert(contract_text.contains("Station Scenario HUD Overlap Pass"), "Interaction contract documents TASK_733")
	_assert(status_text.contains("TASK_733 - Station Scenario HUD Overlap Pass"), "Implementation status tracks TASK_733")
	_assert(roadmap_text.contains("TASK_733 - Station Scenario HUD Overlap Pass (implementiert)"), "Roadmap marks TASK_733 implemented")
	_assert(report_text.contains("TASK_733 - Station Scenario HUD Overlap Pass"), "Current handbook references TASK_733")
	_assert(report_text.contains('data-export-key="station_scenario_hud_overlap_pass.density_policy_id"'), "Current handbook exports TASK_733 policy")
	_assert(controller_text.contains("get_station_scenario_hud_overlap_pass_snapshot"), "Controller exposes HUD overlap snapshot")
	_assert(controller_text.contains("station_route_line_deferred_to_identity"), "Density snapshot defers route line to identity body")


func _test_scene_density_policy() -> void:
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
	var density: Dictionary = Dictionary(command_feedback.get("mission_hud_interaction_density", {}))
	var overlap: Dictionary = Dictionary(controller.call("get_station_scenario_hud_overlap_pass_snapshot"))
	var identity_body: Dictionary = Dictionary(command_feedback.get("station_scenario_identity_body", {}))
	var route_line: String = String(density.get("station_route_line", ""))
	var cue_line: String = String(density.get("station_route_cue_line", ""))
	var objective_line: String = String(density.get("objective_line", ""))
	var cargo_line: String = String(density.get("cargo_line", ""))
	var mission_control_line: String = String(density.get("mission_control_line", ""))
	_assert(_snapshot_is_read_only(overlap), "HUD overlap snapshot is read-only")
	_assert(String(overlap.get("schema", "")) == "sternenbuergerchen.station_scenario_hud_overlap_pass.v1", "HUD overlap schema is stable")
	_assert(bool(overlap.get("route_in_identity_body", false)), "Full route remains in identity body")
	_assert(String(identity_body.get("route_line", "")) == route_line, "Identity body owns full route line")
	_assert(bool(density.get("station_route_line_deferred_to_identity", false)), "Density defers route line to identity")
	_assert(bool(density.get("objective_cargo_deferred_to_route_cue", false)), "Density defers objective/cargo text to route cue")
	_assert(bool(density.get("station_route_cue_prioritized", false)), "Density prioritizes cue line")
	_assert(not route_line.is_empty(), "Density keeps route source line")
	_assert(not cue_line.is_empty(), "Density keeps cue line")
	_assert(mission_control_line.contains(cue_line), "Mission Control ACT line contains cue")
	_assert(not mission_control_line.contains(route_line), "Mission Control ACT line omits duplicate full route")
	_assert(objective_line.is_empty() or not mission_control_line.contains(objective_line), "Mission Control ACT line omits duplicate objective line")
	_assert(cargo_line.is_empty() or not mission_control_line.contains(cargo_line), "Mission Control ACT line omits duplicate cargo line")
	_assert(bool(density.get("line_within_limit", false)), "Mission Control ACT line stays within limit")
	_assert(int(density.get("visible_line_count", 0)) <= int(density.get("max_visible_line_count", 1)), "Density respects visible line count")
	_assert(bool(overlap.get("line_within_limit", false)), "Overlap snapshot records line budget as green")
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
