extends SceneTree

const LIVE_MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_fireteam_dev_test.tscn")
const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const SMOKE_MAP_PATH: String = "res://maps/task_144_2_5d_smoke.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_144 Editor-to-Mission 2.5D Smoke Verifier ===")
	_test_smoke_map_roundtrip_keeps_2_5d_fields()
	await _test_mission_loads_smoke_map_and_renders_2_5d_visuals()
	await _test_mission_navigation_los_and_cover_use_smoke_map_data()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_smoke_map_roundtrip_keeps_2_5d_fields() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", SMOKE_MAP_PATH)
	var generator_tile = map_data.call("get_tile_at_grid", Vector2i(2, 0)) if map_data != null else null
	var ramp_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1)) if map_data != null else null
	var platform_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2)) if map_data != null else null
	var temp_path: String = "user://task_144_2_5d_smoke_roundtrip.json"
	var save_error: Error = map_data.call("save_to_file", temp_path) if map_data != null else ERR_CANT_CREATE
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", temp_path)
	var reloaded_generator = reloaded.call("get_tile_at_grid", Vector2i(2, 0)) if reloaded != null else null
	var reloaded_ramp = reloaded.call("get_tile_at_grid", Vector2i(1, 1)) if reloaded != null else null
	_assert(map_data != null and String(map_data.call("get_map_name")) == "task_144_2_5d_smoke", "Smoke map loads from saved JSON")
	_assert(Array(map_data.call("get_tiles")).size() == 15, "Smoke map contains the curated 5x3 tile set")
	_assert(generator_tile != null and String(generator_tile.object_type_id) == "technik_generator_se", "Smoke map has an object-layer LOS/Cover asset")
	_assert(generator_tile != null and bool(generator_tile.blocks_los) and float(generator_tile.blocks_los_height) >= 3.0 and float(generator_tile.cover_height) >= 1.5, "Smoke map stores cover and LOS height data")
	_assert(ramp_tile != null and String(ramp_tile.height_transition_type) == "ramp" and is_equal_approx(float(ramp_tile.floor_height), 1.0), "Smoke map stores ramp and elevated floor data")
	_assert(platform_tile != null and String(platform_tile.object_type_id) == "plattform_center_sw", "Smoke map includes a second object-layer asset on elevated ground")
	_assert(save_error == OK and reloaded_generator != null and String(reloaded_generator.object_type_id) == "technik_generator_se", "Map save/load roundtrip preserves object-layer asset")
	_assert(reloaded_ramp != null and String(reloaded_ramp.height_transition_type) == "ramp" and is_equal_approx(float(reloaded_ramp.floor_height), 1.0), "Map save/load roundtrip preserves ramp height data")


func _test_mission_loads_smoke_map_and_renders_2_5d_visuals() -> void:
	var scene := _instantiate_smoke_mission()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var setup = scene.get_node_or_null("MissionSetup")
	var terrain_registry = scene.get_node_or_null("TerrainRegistry")
	var bridge = scene.get_node_or_null("Mission25DVisualBridge")
	if bridge != null and bridge.has_method("refresh_bridge"):
		bridge.call("refresh_bridge")
	var map_data = setup.call("get_loaded_terrain_map_data") if setup != null and setup.has_method("get_loaded_terrain_map_data") else null
	var bridge_snapshot: Dictionary = Dictionary(bridge.call("get_bridge_snapshot")) if bridge != null and bridge.has_method("get_bridge_snapshot") else {}
	var render_result: Dictionary = Dictionary(bridge.call("get_render_result")) if bridge != null and bridge.has_method("get_render_result") else {}
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var target_marker := scene.get_node_or_null("TargetMarker") as Node2D
	var objective_marker := scene.get_node_or_null("MapRoot/objective_point") as Node2D
	_assert(setup != null and String(setup.get("map_file_path")) == SMOKE_MAP_PATH, "MissionSetup points at the smoke map file")
	_assert(map_data != null and String(map_data.call("get_map_name")) == "task_144_2_5d_smoke", "MissionSetup loaded the smoke TerrainMapData")
	_assert(terrain_registry != null and Array(terrain_registry.call("get_all_tiles")).size() == Array(map_data.call("get_tiles")).size(), "TerrainRegistry registers the same smoke map tiles")
	_assert(is_equal_approx(float(terrain_registry.call("get_floor_height_at", Vector2i(1, 1))), 1.0), "Mission registry exposes saved ramp floor height")
	_assert(int(terrain_registry.call("get_cover_at", Vector2i(2, 0))) == 55 and is_equal_approx(float(terrain_registry.call("get_los_blocker_height_at", Vector2i(2, 0))), 3.2), "Mission registry exposes saved cover and LOS object values")
	_assert(bool(bridge_snapshot.get("valid", false)) and int(bridge_snapshot.get("terrain_count", 0)) == 15, "2.5D bridge renders terrain from the smoke map")
	_assert(int(stats.get("object_count", 0)) >= 2 and Array(stats.get("missing_models", [])).is_empty(), "2.5D bridge renders object-layer assets from the smoke map")
	_assert(target_marker != null and objective_marker != null and target_marker.global_position == objective_marker.global_position, "Mission markers are positioned from the loaded smoke map")
	scene.queue_free()
	await process_frame


func _test_mission_navigation_los_and_cover_use_smoke_map_data() -> void:
	var scene := _instantiate_smoke_mission()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	var terrain_registry = scene.get_node_or_null("TerrainRegistry")
	var simulation_root = scene.get_node_or_null("SimulationRoot")
	var unit_registry = scene.get_node_or_null("UnitRegistry")
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var ramp_step: Dictionary = Dictionary(pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 1), Vector2i(1, 1), terrain_registry))
	var blocked_step: Dictionary = Dictionary(pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 2), Vector2i(1, 2), terrain_registry))
	var path: Array = pathfinder.call("find_path", Vector2i(0, 1), Vector2i(3, 1), terrain_registry)
	var los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var los_snapshot: Dictionary = Dictionary(los_system.call(
		"get_line_of_sight_snapshot",
		terrain_registry.call("grid_to_world", Vector2i(0, 0)),
		terrain_registry.call("grid_to_world", Vector2i(4, 0)),
		terrain_registry,
		999.0
	))
	var unit = unit_registry.call("get_unit", "unit_alpha") if unit_registry != null else null
	var target_unit = unit_registry.call("get_unit", "enemy_delta") if unit_registry != null else null
	if unit != null:
		unit.global_position = terrain_registry.call("grid_to_world", Vector2i(0, 1))
	if target_unit != null:
		target_unit.global_position = terrain_registry.call("grid_to_world", Vector2i(2, 0))
	var cover_profile: Dictionary = Dictionary(simulation_root.call("_build_terrain_cover_height_profile", target_unit, unit)) if simulation_root != null and target_unit != null else {}
	var move_reached: bool = _run_smoke_move(simulation_root, unit, terrain_registry)
	_assert(bool(ramp_step.get("traversable", false)) and String(ramp_step.get("height_transition_type", "")) == "ramp", "Ground movement can traverse the saved ramp height step")
	_assert(not bool(blocked_step.get("traversable", true)) and String(blocked_step.get("reason", "")) == "height_transition_missing", "Ground movement blocks an equal height step without ramp/stairs")
	_assert(path.has(Vector2i(1, 1)) and path.has(Vector2i(3, 1)), "Pathfinder routes through the saved ramp toward the elevated objective")
	_assert(not bool(los_snapshot.get("has_line_of_sight", true)) and Vector2i(los_snapshot.get("blocking_grid", Vector2i.ZERO)) == Vector2i(2, 0), "LOS snapshot is blocked by the saved LOS object")
	_assert(is_equal_approx(float(cover_profile.get("cover_height", 0.0)), 1.6) and float(cover_profile.get("effective_cover_score", 0.0)) > 0.0, "Cover snapshot uses saved cover height")
	_assert(move_reached, "Mission SimulationRoot can move a unit across the smoke ramp path")
	scene.queue_free()
	await process_frame


func _run_smoke_move(simulation_root: Node, unit: Node, terrain_registry) -> bool:
	if simulation_root == null or unit == null or not (unit is Node2D):
		return false
	var unit_node := unit as Node2D
	var target_position: Vector2 = terrain_registry.call("grid_to_world", Vector2i(3, 1))
	simulation_root.set("command_queue", [])
	simulation_root.set("navigation_budget_enabled", false)
	simulation_root.set("local_avoidance_enabled", false)
	simulation_root.call("enqueue_command", {
		"command_type": "move_to_position",
		"unit_id": String(unit.call("get_unit_id")),
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 12.0,
		"requeue_until_target": true,
	})
	for _tick in range(24):
		simulation_root.call("_physics_process", 0.1)
		if unit_node.global_position.distance_to(target_position) <= 1.0:
			return true
	return unit_node.global_position.distance_to(target_position) <= 1.0


func _instantiate_smoke_mission() -> Node:
	var scene := LIVE_MISSION_SCENE.instantiate()
	var setup = scene.get_node_or_null("MissionSetup")
	if setup != null:
		setup.set("map_file_path", SMOKE_MAP_PATH)
	return scene


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
