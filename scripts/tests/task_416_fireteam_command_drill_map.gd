extends SceneTree

const DRILL_SCENE: PackedScene = preload("res://scenes/tests/fireteam_command_drill_map.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_runtime_execution_path_contract.gd")

const MAP_PATH: String = "res://maps/fireteam_command_drill_24x24.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const HTML_PATH: String = "res://docs/reports/fireteam_command_drill_decision_guide.html"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const TASK_PATH: String = "res://docs/tasks/TASK_416_fireteam_command_drill_map.md"
const META_FLOW_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_416 Fireteam Command Drill Map ===")
	_test_map_authoring()
	_test_scenario_authoring()
	await _test_drill_scene()
	_test_docs_and_catalog()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
		return
	print("ALL TESTS PASSED")
	quit(0)


func _test_map_authoring() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Fireteam command drill map loads")
	if map_data == null:
		return
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(24, 24), "Drill map is exactly 24x24")
	_assert(Array(map_data.call("get_tiles")).size() == 576, "Drill map contains 576 tiles")
	_assert(int(map_data.call("get_mission_slot_count")) == 4, "Drill map exposes four friendly mission slots")
	_assert(String(map_data.call("get_terrain_visual_theme_id")) == "ground_mission_mixed_v1", "Drill map uses the mixed ground visual theme")
	for marker_id in [
		"spawn_alpha",
		"spawn_bravo",
		"spawn_enemy_drill",
		"objective_point",
		"drill_move_lane",
		"drill_defend_area",
		"drill_contact_line",
		"drill_flank_north",
		"drill_flank_south",
	]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Drill map has marker %s" % marker_id)
	var patrol_path: Array = Array(map_data.call("get_patrol_path", "enemy_drill_watch_route"))
	_assert(patrol_path.size() == 3, "Drill map keeps a small enemy watch route for editor preview")
	var road_tiles: int = 0
	var cover_tiles: int = 0
	var los_blockers: int = 0
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		if String(tile_data.surface_type) == "road":
			road_tiles += 1
		if int(tile_data.cover_value) >= 20:
			cover_tiles += 1
		if bool(tile_data.blocks_los):
			los_blockers += 1
	_assert(road_tiles >= 70, "Drill map has a readable road/lane network")
	_assert(cover_tiles >= 12, "Drill map has enough cover tiles for bounding checks")
	_assert(los_blockers >= 4, "Drill map has LOS blockers around the contact line")


func _test_scenario_authoring() -> void:
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	_assert(scenario != null, "Fireteam command drill scenario loads")
	if scenario == null:
		return
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	_assert(bool(validation.get("valid", false)), "Drill scenario validates without authoring errors")
	_assert(String(scenario.get("map_file_path")) == MAP_PATH, "Drill scenario points at the drill map")
	_assert(int(scenario.get("mission_slot_count_override")) == 4, "Drill scenario keeps four friendly slots")
	var enemy_groups: Array = Array(scenario.get("enemy_groups"))
	_assert(enemy_groups.size() == 1, "Drill scenario contains exactly one enemy fireteam")
	if enemy_groups.size() == 1:
		var group: Dictionary = Dictionary(enemy_groups[0])
		_assert(String(group.get("group_id", "")) == "red_drill_fireteam", "Enemy group id documents the red drill fireteam")
		_assert(Array(group.get("enemy_ids", [])).size() == 4, "Enemy drill fireteam has four members")
		var tactics: Dictionary = Dictionary(group.get("tactics", {}))
		_assert(String(tactics.get("profile_id", "")) == "defensive_cover", "Enemy drill fireteam uses defensive cover tactics")
	_assert(scenario.call("references_terrain_without_duplication"), "Scenario references terrain without duplicating map data")


func _test_drill_scene() -> void:
	root.size = Vector2i(1920, 1080)
	var scene := DRILL_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(36)

	var setup := scene.get_node_or_null("MissionSetup")
	var controller := scene.get_node_or_null("TacticalController")
	_assert(setup != null and controller != null, "Drill scene exposes MissionSetup and TacticalController")
	if setup == null or controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(String(setup.get("map_file_path")) == MAP_PATH, "Drill scene loads the drill map")
	_assert(String(setup.get("scenario_file_path")) == SCENARIO_PATH, "Drill scene loads the drill scenario")
	_assert(Array(setup.get("selected_team_unit_ids")).size() == 4, "Drill scene selects four friendly unit slots")
	var selected_fireteam_ids: Array = Array(setup.get("selected_team_fireteam_ids"))
	_assert(selected_fireteam_ids.size() == 4 and _all_values_equal(selected_fireteam_ids, "drill"), "Drill scene assigns all selected friendlies to one fireteam")
	var presence: Dictionary = Dictionary(setup.call("get_expected_unit_presence_snapshot"))
	_assert(Array(presence.get("friendly_unit_ids", [])).size() == 4, "Drill scene keeps four active friendly units")
	_assert(Array(presence.get("enemy_unit_ids", [])).size() == 4, "Drill scene spawns four active enemy units from the scenario")
	var path_snapshot: Dictionary = Dictionary(controller.call("get_fireteam_runtime_execution_path_snapshot"))
	_assert(bool(FIRETEAM_RUNTIME_EXECUTION_PATH_CONTRACT_SCRIPT.call("is_valid_snapshot", path_snapshot)), "Drill scene uses the official Mission-Tactical fireteam runtime path")
	scene.queue_free()
	await _wait_frames(2)


func _test_docs_and_catalog() -> void:
	var html_text: String = _read_text(HTML_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var task_text: String = _read_text(TASK_PATH)
	var meta_text: String = _read_text(META_FLOW_PATH)
	for token in ["Move", "Bounding", "Caterpillar", "Defend", "Flank", "Take", "SimulationRoot"]:
		_assert(html_text.contains(token), "Decision guide contains %s" % token)
	_assert(task_text.contains("TASK_416 - Fireteam Command Drill Map"), "TASK_416 task file exists")
	_assert(status_text.contains("TASK_416 - Fireteam Command Drill Map"), "Implementation status documents TASK_416")
	_assert(meta_text.contains("fireteam_command_drill"), "Meta mission catalog exposes the command drill mission")


func _all_values_equal(values: Array, expected: String) -> bool:
	if values.is_empty():
		return false
	for value_variant in values:
		if String(value_variant).strip_edges().to_lower() != expected:
			return false
	return true


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
