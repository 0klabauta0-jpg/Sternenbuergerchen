extends SceneTree

const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const MAP_PATH: String = "res://maps/Ground_Mission02_128x128.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/ground_mission02_128x128.json"
const MAP_SIZE: Vector2i = Vector2i(128, 128)
const THEME_ID: String = "ground_mission_mixed_v1"

const GRID_SPAWN_ALPHA: Vector2i = Vector2i(16, 104)
const GRID_SPAWN_BRAVO: Vector2i = Vector2i(109, 34)
const GRID_OBJECTIVE: Vector2i = Vector2i(84, 82)
const GRID_ENEMY_PATROL: Vector2i = Vector2i(96, 64)
const GRID_ENEMY_DEFENSE: Vector2i = Vector2i(84, 76)
const GRID_ENEMY_AIR_DEFENSE: Vector2i = Vector2i(92, 88)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "GM02_128", MAP_SIZE, Vector2.ZERO, 64.0, 32.0, 48)
	map_data.call("set_terrain_visual_theme_id", THEME_ID)
	_paint_base_terrain(map_data)
	_paint_height_regions(map_data)
	_paint_road_network(map_data)
	_paint_objective_site(map_data, catalog)
	_place_cover_and_objects(map_data, catalog)
	_place_markers_and_routes(map_data)
	_place_enemy_authoring_configs(map_data)

	var map_error: Error = map_data.call("save_to_file", MAP_PATH)
	if map_error != OK:
		push_error("Could not save map %s: %s" % [MAP_PATH, error_string(map_error)])
		quit(1)
		return

	var scenario = _build_scenario()
	var scenario_error: Error = scenario.call("save_to_file", SCENARIO_PATH)
	if scenario_error != OK:
		push_error("Could not save scenario %s: %s" % [SCENARIO_PATH, error_string(scenario_error)])
		quit(1)
		return

	print("Generated %s and %s" % [MAP_PATH, SCENARIO_PATH])
	quit(0)


func _paint_base_terrain(map_data) -> void:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		tile_data.type_id = "ground_flat"
		tile_data.object_type_id = ""
		tile_data.object_rotation_degrees = 0.0
		tile_data.walkable = true
		tile_data.blocks_los = false
		tile_data.cover_value = 0
		tile_data.object_height = 0
		tile_data.height_level = 0
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
		if _is_sand_wash(grid):
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
			tile_data.type_id = "nature_ground_sand_dirt"
		elif _is_rock_field(grid):
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
			tile_data.type_id = "nature_ground_rock_dirt"
		elif posmod((grid.x * 17) + (grid.y * 11), 29) == 0:
			tile_data.type_id = "nature_ground_grass_patch"


func _paint_height_regions(map_data) -> void:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		var height_level: int = 0
		var edge_type: String = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		var objective_dist: float = Vector2(grid).distance_to(Vector2(GRID_OBJECTIVE))
		var north_ridge_dist: float = Vector2(grid).distance_to(Vector2(43, 45))
		var south_ridge_dist: float = Vector2(grid).distance_to(Vector2(96, 104))
		var west_knoll_dist: float = Vector2(grid).distance_to(Vector2(31, 86))
		if objective_dist <= 7.0:
			height_level = 1
			edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE if objective_dist >= 5.2 else TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		elif north_ridge_dist <= 13.0 or south_ridge_dist <= 12.0 or west_knoll_dist <= 8.0:
			height_level = 1
			edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE if posmod(grid.x + grid.y, 5) <= 1 else TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
		if north_ridge_dist <= 5.8 or south_ridge_dist <= 5.2:
			height_level = 2
			edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
		tile_data.height_level = height_level
		tile_data.edge_type = edge_type if height_level > 0 else TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		if height_level > 0 and tile_data.surface_type == TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND and posmod(grid.x * 3 + grid.y * 7, 4) == 0:
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
			tile_data.type_id = "nature_ground_rock_dirt"


func _paint_road_network(map_data) -> void:
	var road_points: Array[Vector2i] = [
		GRID_SPAWN_ALPHA,
		Vector2i(30, 96),
		Vector2i(48, 86),
		Vector2i(65, 82),
		GRID_OBJECTIVE,
		Vector2i(98, 62),
		GRID_SPAWN_BRAVO,
	]
	for index in range(road_points.size() - 1):
		_paint_corridor(map_data, road_points[index], road_points[index + 1], 3.2)
	_paint_corridor(map_data, Vector2i(78, 89), GRID_ENEMY_AIR_DEFENSE, 2.2)
	_paint_corridor(map_data, Vector2i(90, 72), GRID_ENEMY_PATROL, 2.0)


func _paint_corridor(map_data, start_grid: Vector2i, end_grid: Vector2i, radius: float) -> void:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		if _grid_distance_to_segment(Vector2(grid), Vector2(start_grid), Vector2(end_grid)) > radius:
			continue
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
		tile_data.type_id = "ground_flat"
		tile_data.walkable = true
		tile_data.blocks_los = false
		tile_data.cover_value = 0
		tile_data.object_height = 0
		if int(tile_data.height_level) > 0:
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE


func _paint_objective_site(map_data, catalog) -> void:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		var local: Vector2i = grid - GRID_OBJECTIVE
		if abs(local.x) <= 6 and abs(local.y) <= 6:
			var floor_type: String = "station_set_floor_panel"
			if abs(local.x) == 6 or abs(local.y) == 6:
				floor_type = "station_set_floor_panel_straight"
			elif abs(local.x) <= 2 and abs(local.y) <= 2:
				floor_type = "modular_floor_raised"
			elif posmod(local.x + local.y, 3) == 0:
				floor_type = "station_set_floor_detail"
			catalog.call("apply_type_to_tile", tile_data, floor_type)
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD
			tile_data.height_level = 1
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE if abs(local.x) == 6 or abs(local.y) == 6 else TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
			tile_data.object_type_id = ""
			tile_data.walkable = true
			tile_data.blocks_los = false
			tile_data.cover_value = 0
			tile_data.object_height = 0


func _place_cover_and_objects(map_data, catalog) -> void:
	var protected_grids: Dictionary = _build_protected_grid_lookup()
	var object_plan: Dictionary = {
		Vector2i(80, 77): "station_set_container_wide",
		Vector2i(89, 77): "station_set_computer_wide",
		Vector2i(77, 82): "station_set_structure_barrier",
		Vector2i(91, 82): "station_set_structure_barrier",
		Vector2i(82, 88): "station_set_table_display",
		Vector2i(88, 88): "station_set_container_flat",
		Vector2i(88, 92): "spacekit_turret_single",
		Vector2i(94, 86): "spacekit_turret_double",
		Vector2i(70, 92): "spacekit_turret_single",
	}
	for grid_variant in object_plan.keys():
		_apply_object(map_data, catalog, Vector2i(grid_variant), String(object_plan.get(grid_variant)))

	var prop_types: Array[String] = [
		"nature_tree_blocker",
		"nature_rock_cover",
		"nature_bush_cover",
		"nature_cactus_cover",
		"nature_deco_logs",
	]
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		if protected_grids.has(_grid_key(grid)) or String(tile_data.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			continue
		if not String(tile_data.object_type_id).is_empty():
			continue
		var selector: int = posmod((grid.x * 31) + (grid.y * 19), 53)
		if selector > 3:
			continue
		var prop_type: String = prop_types[selector]
		if prop_type == "nature_cactus_cover" and String(tile_data.surface_type) != TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			prop_type = "nature_bush_cover"
		_apply_object(map_data, catalog, grid, prop_type)


func _build_protected_grid_lookup() -> Dictionary:
	var result: Dictionary = {}
	for center in [GRID_SPAWN_ALPHA, GRID_SPAWN_BRAVO, GRID_OBJECTIVE, GRID_ENEMY_PATROL, GRID_ENEMY_DEFENSE, GRID_ENEMY_AIR_DEFENSE]:
		for x in range(center.x - 4, center.x + 5):
			for y in range(center.y - 4, center.y + 5):
				result[_grid_key(Vector2i(x, y))] = true
	return result


func _apply_object(map_data, catalog, grid: Vector2i, object_type_id: String) -> void:
	if grid.x < 0 or grid.y < 0 or grid.x >= MAP_SIZE.x or grid.y >= MAP_SIZE.y:
		return
	var tile_data = map_data.call("get_tile_at_grid", grid)
	if tile_data == null:
		return
	catalog.call("apply_type_to_tile", tile_data, object_type_id)
	tile_data.object_rotation_degrees = float(posmod((grid.x * 90) + (grid.y * 45), 360))


func _place_markers_and_routes(map_data) -> void:
	_set_marker(map_data, "spawn_alpha", "spawn_alpha", GRID_SPAWN_ALPHA, {"name": "Spawn Alpha"})
	_set_marker(map_data, "spawn_bravo", "spawn_bravo", GRID_SPAWN_BRAVO, {"name": "Spawn Bravo"})
	_set_marker(map_data, "objective_point", "objective_point", GRID_OBJECTIVE, {"name": "Objective Relay"})
	_set_marker(map_data, "spawn_enemy_patrol", "custom", GRID_ENEMY_PATROL, {"name": "Enemy Patrol Team", "symbol": "chevron"})
	_set_marker(map_data, "spawn_enemy_defense", "custom", GRID_ENEMY_DEFENSE, {"name": "Enemy Defense Team", "symbol": "shield"})
	_set_marker(map_data, "spawn_enemy_air_defense", "custom", GRID_ENEMY_AIR_DEFENSE, {"name": "Enemy Air Defense", "symbol": "tower"})
	_set_marker(map_data, "objective_ridge_aa", "custom", GRID_ENEMY_AIR_DEFENSE, {"name": "Objective Ridge AA Zone", "symbol": "warning"})
	map_data.call("set_patrol_path", "ground_patrol_route", [
		_world_at(map_data, GRID_ENEMY_PATROL),
		_world_at(map_data, Vector2i(92, 72)),
		_world_at(map_data, Vector2i(76, 82)),
		_world_at(map_data, Vector2i(96, 94)),
		_world_at(map_data, GRID_ENEMY_AIR_DEFENSE),
	])
	map_data.call("set_patrol_path", "outer_probe_route", [
		_world_at(map_data, Vector2i(46, 72)),
		_world_at(map_data, Vector2i(55, 92)),
		_world_at(map_data, Vector2i(72, 96)),
		_world_at(map_data, Vector2i(84, 82)),
	])


func _set_marker(map_data, marker_id: String, marker_type_id: String, grid: Vector2i, overrides: Dictionary = {}) -> void:
	map_data.call("set_marker", marker_id, marker_type_id, _world_at(map_data, grid), overrides)


func _place_enemy_authoring_configs(map_data) -> void:
	map_data.call("set_enemy_team_config", "ground_patrol_team", _patrol_tactics())
	map_data.call("set_enemy_team_config", "ground_objective_defense", _defense_tactics())
	map_data.call("set_enemy_team_config", "ground_air_defense", _air_defense_tactics())


func _build_scenario():
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.new()
	scenario.scenario_id = "ground_mission02_128x128"
	scenario.display_name = "Ground Mission 02: Relay Ridge"
	scenario.map_file_path = MAP_PATH
	scenario.time_limit_seconds = 1800.0
	scenario.mission_slot_count_override = 12
	scenario.objective = {
		"marker_id": "objective_point",
		"capture_radius": 128.0,
	}
	scenario.enemy_groups = [
		{
			"group_id": "red_patrol_team",
			"display_name": "Red Patrol Fireteam",
			"team_id": "team_bravo",
			"spawn_marker_id": "spawn_enemy_patrol",
			"enemy_ids": ["gm02_patrol_01", "gm02_patrol_02", "gm02_patrol_03", "gm02_patrol_04"],
			"tactics": _patrol_tactics(),
		},
		{
			"group_id": "red_objective_defense",
			"display_name": "Red Objective Fireteam",
			"team_id": "team_bravo",
			"spawn_marker_id": "spawn_enemy_defense",
			"enemy_ids": ["gm02_defense_01", "gm02_defense_02", "gm02_defense_03", "gm02_defense_04"],
			"tactics": _defense_tactics(),
		},
		{
			"group_id": "red_air_defense",
			"display_name": "Red Air Defense Team",
			"team_id": "team_bravo",
			"spawn_marker_id": "spawn_enemy_air_defense",
			"enemy_ids": ["gm02_airdef_01", "gm02_airdef_02", "gm02_airdef_03", "gm02_airdef_04"],
			"tactics": _air_defense_tactics(),
		},
	]
	scenario.wave_config = {
		"wave_count": 1,
		"units_per_wave": 12,
		"first_wave_delay_seconds": 0.0,
		"wave_delay_seconds": 150.0,
	}
	scenario.patrol_bindings = [
		{
			"binding_id": "red_patrol_team_route",
			"target_id": "spawn_enemy_patrol",
			"patrol_path_id": "ground_patrol_route",
			"mode": "pre_contact",
		},
		{
			"binding_id": "red_air_defense_probe_route",
			"target_id": "spawn_enemy_air_defense",
			"patrol_path_id": "outer_probe_route",
			"mode": "pre_contact",
		},
	]
	scenario.tactical_authoring = {
		"communication_intensity": "normal",
		"fireteam_defaults": {
			"advance_style": "bounding",
			"security_mode": "360",
		},
		"air_asset_risk": {
			"profile_id": "watch_warning",
			"enemy_group_id": "red_air_defense",
			"lz_threat_zone_id": "objective_ridge_aa",
			"warning_required_before_damage": true,
			"loss_consequence": "replacement_recovery",
		},
	}
	scenario.notes = PackedStringArray([
		"128x128 Ground Mission variant derived from Ground_Mission01_32x32 authoring shape.",
		"Uses terrain_visual_theme_id ground_mission_mixed_v1 for visual-only Nature/Station/Modular ground variety.",
	])
	return scenario


func _patrol_tactics() -> Dictionary:
	return {
		"profile_id": "patrol_probe",
		"stance": "patrol",
		"cover_behavior": "break_to_cover_on_contact",
		"security_mode": "patrol",
		"facing": "west",
		"advance_style": "probe",
		"allowed_weapon_roles": ["rifle", "smg", "sidearm"],
		"sight_behavior": "scan_waypoints",
		"contact_behavior": "pin_then_report",
		"weapon_profile": "standard_close",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "travel_until_threat",
		"ready_distance_world": 760.0,
		"travel_speed_factor": 0.55,
		"ready_speed_factor": 0.30,
		"aim_move_speed_factor": 0.18,
		"heavy_weapon_role": "none",
		"anti_armor_threat": false,
		"air_asset_risk_profile": "none",
		"communication_intensity": "normal",
	}


func _defense_tactics() -> Dictionary:
	return {
		"profile_id": "defensive_cover",
		"stance": "defend",
		"cover_behavior": "hold_best_cover",
		"security_mode": "cover_arc",
		"facing": "west",
		"advance_style": "hold",
		"allowed_weapon_roles": ["rifle", "smg", "heavy"],
		"sight_behavior": "cover_arc",
		"contact_behavior": "suppress_from_cover",
		"weapon_profile": "defensive_mid",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "hold_ready",
		"ready_distance_world": 760.0,
		"travel_speed_factor": 0.35,
		"ready_speed_factor": 0.24,
		"aim_move_speed_factor": 0.18,
		"heavy_weapon_role": "none",
		"anti_armor_threat": false,
		"air_asset_risk_profile": "none",
		"communication_intensity": "normal",
	}


func _air_defense_tactics() -> Dictionary:
	return {
		"profile_id": "sniper_watch",
		"stance": "defend",
		"cover_behavior": "hold_best_cover",
		"security_mode": "overwatch",
		"facing": "south_west",
		"advance_style": "hold",
		"allowed_weapon_roles": ["rifle", "heavy"],
		"sight_behavior": "cover_arc",
		"contact_behavior": "suppress_from_cover",
		"weapon_profile": "anti_armor",
		"weapon_id": "rocket_launcher",
		"visual_archetype": "enemy_space_suit_orange",
		"movement_posture_policy": "hold_ready",
		"ready_distance_world": 840.0,
		"travel_speed_factor": 0.30,
		"ready_speed_factor": 0.20,
		"aim_move_speed_factor": 0.12,
		"heavy_weapon_role": "anti_armor",
		"anti_armor_threat": true,
		"air_asset_risk_profile": "watch_warning",
		"lz_threat_zone_id": "objective_ridge_aa",
		"communication_intensity": "normal",
	}


func _world_at(map_data, grid: Vector2i) -> Vector2:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return Vector2(tile_data.world_position) if tile_data != null else Vector2.ZERO


func _grid_distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment: Vector2 = segment_end - segment_start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.001:
		return point.distance_to(segment_start)
	var t: float = clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(segment_start + (segment * t))


func _is_sand_wash(grid: Vector2i) -> bool:
	return grid.y > 91 and grid.x < 58 and posmod((grid.x * 7) + grid.y, 9) <= 5


func _is_rock_field(grid: Vector2i) -> bool:
	return grid.x > 72 and grid.y < 38 and posmod(grid.x + (grid.y * 5), 7) <= 3


func _grid_key(grid: Vector2i) -> String:
	return "%d:%d" % [grid.x, grid.y]
