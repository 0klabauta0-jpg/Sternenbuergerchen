extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

const MAP_PATH: String = "res://maps/fireteam_command_drill_24x24.json"
const SCENARIO_PATH: String = "res://data/mission_scenarios/fireteam_command_drill_24x24.json"
const MAP_NAME: String = "fireteam_command_drill_24x24"
const GRID_SIZE: Vector2i = Vector2i(24, 24)
const GRID_ORIGIN: Vector2 = Vector2(1472.0, 96.0)
const TILE_HALF_WIDTH: float = 64.0
const TILE_HALF_HEIGHT: float = 32.0

const MARKER_TILES: Dictionary = {
	"spawn_alpha": Vector2i(4, 19),
	"spawn_bravo": Vector2i(6, 20),
	"spawn_enemy_drill": Vector2i(17, 8),
	"objective_point": Vector2i(14, 11),
	"drill_move_lane": Vector2i(8, 16),
	"drill_defend_area": Vector2i(11, 14),
	"drill_contact_line": Vector2i(13, 12),
	"drill_flank_north": Vector2i(10, 10),
	"drill_flank_south": Vector2i(13, 18),
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map_data = _build_map()
	var map_save_error: Error = map_data.call("save_to_file", MAP_PATH)
	if map_save_error != OK:
		push_error("Failed to save drill map: %s" % error_string(map_save_error))
		quit(1)
		return

	var scenario = _build_scenario()
	var scenario_save_error: Error = scenario.call("save_to_file", SCENARIO_PATH)
	if scenario_save_error != OK:
		push_error("Failed to save drill scenario: %s" % error_string(scenario_save_error))
		quit(1)
		return

	if not _validate_outputs():
		quit(1)
		return

	print("Generated %s and %s" % [MAP_PATH, SCENARIO_PATH])
	quit(0)


func _build_map():
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", MAP_NAME, GRID_SIZE, GRID_ORIGIN, TILE_HALF_WIDTH, TILE_HALF_HEIGHT, 4)
	map_data.call("set_terrain_visual_theme_id", "ground_mission_mixed_v1")
	_apply_base_ground(map_data)
	_apply_roads(map_data)
	_apply_cover_and_objective(map_data)
	_apply_markers(map_data)
	_apply_patrol_paths(map_data)
	_apply_enemy_tactics(map_data)
	return map_data


func _apply_base_ground(map_data) -> void:
	for x in range(GRID_SIZE.x):
		for y in range(GRID_SIZE.y):
			var tile = map_data.call("get_tile_at_grid", Vector2i(x, y))
			if tile == null:
				continue
			tile.type_id = "ground_flat"
			tile.object_type_id = ""
			tile.walkable = true
			tile.blocks_los = false
			tile.cover_value = 0
			tile.height_level = 0
			tile.object_height = 0
			tile.object_rotation_degrees = 0.0
			tile.surface_type = "ground"
			tile.edge_type = "none"


func _apply_roads(map_data) -> void:
	var road_tiles: Dictionary = {}
	for y in range(12, 23):
		for x in range(2, 16):
			if abs(x - (y - 10)) <= 3:
				road_tiles[Vector2i(x, y)] = true
	for x in range(4, 19):
		for y in range(14, 18):
			if abs(y - 16) <= 1 or abs(x - 10) <= 2:
				road_tiles[Vector2i(x, y)] = true
	for x in range(10, 19):
		for y in range(8, 13):
			if abs((x - y) - 6) <= 2:
				road_tiles[Vector2i(x, y)] = true
	for position in road_tiles.keys():
		_set_tile(map_data, position, "ground_flat", "road", 0, false, true)


func _apply_cover_and_objective(map_data) -> void:
	for position in [
		Vector2i(9, 15), Vector2i(10, 15), Vector2i(11, 15), Vector2i(12, 15),
		Vector2i(10, 13), Vector2i(12, 13), Vector2i(13, 13), Vector2i(15, 10),
		Vector2i(16, 10), Vector2i(17, 10), Vector2i(15, 12), Vector2i(17, 12),
	]:
		_set_tile(map_data, position, "ground_flat", "ground", 35, true, false, "station_container_wide", 2, _resolve_object_rotation_degrees(position))

	for position in [
		Vector2i(7, 17), Vector2i(8, 17), Vector2i(9, 18), Vector2i(12, 16),
		Vector2i(14, 14), Vector2i(16, 9), Vector2i(18, 8), Vector2i(19, 9),
	]:
		_set_tile(map_data, position, "ground_flat", "ground", 24, false, true, "nature_rock_cover", 1, _resolve_object_rotation_degrees(position))

	for position in [
		Vector2i(3, 16), Vector2i(6, 13), Vector2i(8, 11), Vector2i(12, 9),
		Vector2i(14, 17), Vector2i(17, 15), Vector2i(20, 12), Vector2i(21, 17),
	]:
		_apply_shrub_ground_tile(map_data, position)

	for position in [
		Vector2i(13, 11), Vector2i(14, 11), Vector2i(15, 11),
		Vector2i(13, 12), Vector2i(14, 12), Vector2i(15, 12),
	]:
		_set_tile(map_data, position, "nature_ground_sand_dirt", "sand", 0, false, true)

	for position in [Vector2i(5, 20), Vector2i(6, 20), Vector2i(7, 20), Vector2i(17, 8), Vector2i(18, 8)]:
		_set_tile(map_data, position, "nature_ground_dirt", "ground", 0, false, true)


func _apply_shrub_ground_tile(map_data, position: Vector2i) -> void:
	_set_tile(map_data, position, "ground_flat", "ground", 25, false, true, "nature_bush_cover", 1, _resolve_object_rotation_degrees(position))


func _apply_markers(map_data) -> void:
	map_data.call("set_marker", "spawn_alpha", "spawn_alpha", _tile_world(map_data, MARKER_TILES["spawn_alpha"]), {
		"name": "Friendly Drill Spawn",
		"symbol": "diamond",
	})
	map_data.call("set_marker", "spawn_bravo", "spawn_alpha", _tile_world(map_data, MARKER_TILES["spawn_bravo"]), {
		"name": "Friendly Alternate Spawn",
		"symbol": "diamond",
	})
	map_data.call("set_marker", "spawn_enemy_drill", "spawn_bravo", _tile_world(map_data, MARKER_TILES["spawn_enemy_drill"]), {
		"name": "Red Drill Fireteam",
		"symbol": "diamond",
	})
	map_data.call("set_marker", "objective_point", "objective_point", _tile_world(map_data, MARKER_TILES["objective_point"]), {
		"name": "Objective Capture Point",
		"symbol": "flag",
	})
	map_data.call("set_marker", "drill_move_lane", "move", _tile_world(map_data, MARKER_TILES["drill_move_lane"]), {
		"name": "Move Lane",
		"symbol": "chevron",
	})
	map_data.call("set_marker", "drill_defend_area", "defend", _tile_world(map_data, MARKER_TILES["drill_defend_area"]), {
		"name": "Defend / Rally Area",
		"symbol": "circle",
	})
	map_data.call("set_marker", "drill_contact_line", "recon_note", _tile_world(map_data, MARKER_TILES["drill_contact_line"]), {
		"name": "Likely Contact Line",
		"symbol": "triangle",
	})
	map_data.call("set_marker", "drill_flank_north", "flank", _tile_world(map_data, MARKER_TILES["drill_flank_north"]), {
		"name": "North Flank Option",
		"symbol": "chevron",
	})
	map_data.call("set_marker", "drill_flank_south", "flank", _tile_world(map_data, MARKER_TILES["drill_flank_south"]), {
		"name": "South Flank Option",
		"symbol": "chevron",
	})


func _apply_patrol_paths(map_data) -> void:
	map_data.call("set_patrol_path", "enemy_drill_watch_route", [
		_tile_world(map_data, Vector2i(15, 8)),
		_tile_world(map_data, Vector2i(14, 9)),
		_tile_world(map_data, Vector2i(15, 10)),
	])
	map_data.call("set_patrol_path", "enemy_drill_echo_route", [
		_tile_world(map_data, Vector2i(17, 7)),
		_tile_world(map_data, Vector2i(18, 8)),
		_tile_world(map_data, Vector2i(19, 7)),
	])
	map_data.call("set_patrol_path", "enemy_drill_foxtrot_route", [
		_tile_world(map_data, Vector2i(19, 9)),
		_tile_world(map_data, Vector2i(20, 10)),
		_tile_world(map_data, Vector2i(18, 10)),
	])
	map_data.call("set_patrol_path", "enemy_drill_golf_route", [
		_tile_world(map_data, Vector2i(21, 9)),
		_tile_world(map_data, Vector2i(21, 11)),
		_tile_world(map_data, Vector2i(20, 10)),
	])


func _apply_enemy_tactics(map_data) -> void:
	var default_config: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", GRID_SIZE, {
		"profile_id": "guard_hold",
		"visual_archetype": "enemy_space_suit_orange",
	})
	map_data.call("set_enemy_team_config", "default", default_config)
	var red_config: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", {
		"profile_id": "patrol_probe",
		"security_mode": "patrol",
		"facing": "auto",
		"visual_archetype": "enemy_space_suit_orange",
		"weapon_profile": "standard_close",
		"travel_speed_factor": 0.36,
		"ready_speed_factor": 0.20,
		"aim_move_speed_factor": 0.12,
	}, GRID_SIZE)
	map_data.call("set_enemy_team_config", "red_drill_fireteam", red_config)


func _build_scenario():
	var red_tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", {
		"profile_id": "patrol_probe",
		"security_mode": "patrol",
		"facing": "auto",
		"visual_archetype": "enemy_space_suit_orange",
		"weapon_profile": "standard_close",
		"travel_speed_factor": 0.36,
		"ready_speed_factor": 0.20,
		"aim_move_speed_factor": 0.12,
	}, GRID_SIZE)
	return MISSION_SCENARIO_DATA_SCRIPT.call("from_dict", {
		"version": 1,
		"scenario_id": "fireteam_command_drill",
		"display_name": "Operation: Fireteam Command Drill",
		"map_file_path": MAP_PATH,
		"time_limit_seconds": 0.0,
		"mission_slot_count_override": 4,
		"objective": {
			"marker_id": "objective_point",
			"capture_radius": 96.0,
		},
		"enemy_groups": [
			{
				"group_id": "red_drill_fireteam",
				"display_name": "Red Drill Fireteam",
				"team_id": "team_red",
				"spawn_marker_id": "spawn_enemy_drill",
				"enemy_ids": ["enemy_delta", "enemy_echo", "enemy_foxtrot", "enemy_golf"],
				"tactics": red_tactics,
				"notes": [
					"One visible hostile fireteam for Move, Defend, Take and Engage drills.",
				],
			},
		],
		"wave_config": {
			"wave_count": 1,
			"units_per_wave": 4,
			"first_wave_delay_seconds": 0.0,
			"wave_delay_seconds": 0.0,
		},
		"patrol_bindings": [
			{
				"target_id": "enemy_delta",
				"patrol_path_id": "enemy_drill_watch_route",
				"mode": "pre_contact",
			},
			{
				"target_id": "enemy_echo",
				"patrol_path_id": "enemy_drill_echo_route",
				"mode": "pre_contact",
			},
			{
				"target_id": "enemy_foxtrot",
				"patrol_path_id": "enemy_drill_foxtrot_route",
				"mode": "pre_contact",
			},
			{
				"target_id": "enemy_golf",
				"patrol_path_id": "enemy_drill_golf_route",
				"mode": "pre_contact",
			},
		],
		"tactical_authoring": {
			"communication_intensity": "normal",
			"fireteam_defaults": {
				"advance_style": "bounding",
				"security_mode": "360",
			},
			"air_asset_risk": {
				"profile_id": "none",
				"enemy_group_id": "",
				"lz_threat_zone_id": "",
				"warning_required_before_damage": true,
				"loss_consequence": "replacement_recovery",
			},
		},
		"notes": [
			"Generated drill scenario for focused fireteam behavior playtests.",
		],
	})


func _validate_outputs() -> bool:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	if map_data == null or Vector2i(map_data.call("get_grid_size")) != GRID_SIZE:
		push_error("Generated map failed reload validation.")
		return false
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	if scenario == null:
		push_error("Generated scenario failed reload validation.")
		return false
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	if not bool(validation.get("valid", false)):
		push_error("Generated scenario is invalid: %s" % [PackedStringArray(validation.get("errors", PackedStringArray()))])
		return false
	return true


func _set_tile(map_data, position: Vector2i, type_id: String, surface_type: String, cover_value: int, blocks_los: bool, walkable: bool, object_type_id: String = "", object_height: int = 0, object_rotation_degrees: float = 0.0) -> void:
	if position.x < 0 or position.y < 0 or position.x >= GRID_SIZE.x or position.y >= GRID_SIZE.y:
		return
	var tile = map_data.call("get_tile_at_grid", position)
	if tile == null:
		return
	tile.type_id = type_id
	tile.object_type_id = object_type_id
	tile.surface_type = surface_type
	tile.cover_value = clampi(cover_value, 0, 100)
	tile.blocks_los = blocks_los
	tile.walkable = walkable
	tile.height_level = 0
	tile.object_height = clampi(object_height, 0, 3)
	tile.object_rotation_degrees = object_rotation_degrees
	tile.edge_type = "none"


func _tile_world(map_data, grid_position: Vector2i) -> Vector2:
	var tile = map_data.call("get_tile_at_grid", grid_position)
	if tile != null:
		return tile.world_position
	return GRID_ORIGIN + Vector2(float(grid_position.x - grid_position.y) * TILE_HALF_WIDTH, float(grid_position.x + grid_position.y) * TILE_HALF_HEIGHT)


func _resolve_object_rotation_degrees(position: Vector2i) -> float:
	var variants: Array[float] = [0.0, 90.0, 180.0, 270.0]
	return variants[abs(position.x * 31 + position.y * 17) % variants.size()]
