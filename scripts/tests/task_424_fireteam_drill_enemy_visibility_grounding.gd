extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

const MAP_PATH: String = "res://maps/fireteam_command_drill_24x24.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const TASK_PATH: String = "res://docs/tasks/TASK_424_fireteam_drill_enemy_visibility_grounding.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_424 Fireteam Drill Enemy Visibility Grounding ===")
	_test_map_grounding()
	_test_scenario_enemy_visibility_data()
	await _test_drill_scene_enemy_presence()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_map_grounding() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Drill map loads")
	if map_data == null:
		return
	var shrub_ground_tiles: int = 0
	var station_floor_panels: int = 0
	var raised_tiles: int = 0
	var los_blockers: int = 0
	for tile in Array(map_data.call("get_tiles")):
		if tile == null:
			continue
		if int(tile.height_level) != 0:
			raised_tiles += 1
		if String(tile.type_id).begins_with("station_set_floor_panel"):
			station_floor_panels += 1
		if String(tile.type_id) == "nature_ground_grass_patch":
			shrub_ground_tiles += 1
			_assert(String(tile.surface_type) == "ground", "Shrub ground tile uses ground surface")
			_assert(String(tile.object_type_id).is_empty(), "Shrub cover is not a separate object prop")
		if bool(tile.blocks_los):
			los_blockers += 1
	_assert(shrub_ground_tiles >= 6, "Drill map has several shrub ground tiles")
	_assert(station_floor_panels == 0, "Objective does not use station floor panels")
	_assert(raised_tiles == 0, "Drill map has no authored gameplay elevation")
	_assert(los_blockers >= 4, "Drill map keeps visible LOS blockers around contact")


func _test_scenario_enemy_visibility_data() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Drill scenario loads")
	if scenario == null:
		return
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Drill scenario validates")
	var enemy_groups: Array = Array(scenario.get("enemy_groups"))
	_assert(enemy_groups.size() == 1, "Scenario has exactly one enemy fireteam")
	if enemy_groups.size() != 1:
		return
	var tactics: Dictionary = Dictionary(Dictionary(enemy_groups[0]).get("tactics", {}))
	_assert(String(tactics.get("visual_archetype", "")) == "enemy_space_suit_orange", "Enemy fireteam uses visible orange archetype")
	_assert(String(tactics.get("profile_id", "")) == "defensive_cover", "Enemy fireteam keeps defensive_cover tactics")


func _test_drill_scene_enemy_presence() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)
	var setup := scene.get_node_or_null("MissionSetup")
	_assert(setup != null, "Drill scene exposes MissionSetup")
	if setup != null and setup.has_method("get_expected_unit_presence_snapshot"):
		var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
		_assert(Array(presence.get("enemy_unit_ids", [])).size() == 4, "Drill scene expects four enemy units")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	var status_text: String = _read_text(STATUS_PATH)
	var task_text: String = _read_text(TASK_PATH)
	_assert(status_text.contains("TASK_424 - Fireteam Drill Enemy Visibility Grounding"), "Implementation status documents TASK_424")
	_assert(task_text.contains("Nature-/Pflanzen-Props"), "Task documents nature grounding")


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
