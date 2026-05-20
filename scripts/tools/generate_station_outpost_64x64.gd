extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const MAP_PATH: String = "res://maps/station_outpost_64x64.json"
const MAP_NAME: String = "station_outpost_64x64"
const MAP_SIZE: Vector2i = Vector2i(64, 64)
const GRID_ORIGIN: Vector2 = Vector2(4608.0, 96.0)
const THEME_ID: String = "ground_mission_mixed_v1"

const GRID_SPAWN_ALPHA: Vector2i = Vector2i(8, 55)
const GRID_SPAWN_BRAVO: Vector2i = Vector2i(56, 11)
const GRID_OBJECTIVE: Vector2i = Vector2i(32, 31)
const GRID_RALLY: Vector2i = Vector2i(15, 49)
const GRID_DANGER: Vector2i = Vector2i(50, 38)
const GRID_RECON: Vector2i = Vector2i(47, 27)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	if catalog == null:
		push_error("Terrain tile catalog could not be loaded.")
		quit(1)
		return
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", MAP_NAME, MAP_SIZE, GRID_ORIGIN, 64.0, 32.0, 8)
	map_data.call("set_terrain_visual_theme_id", THEME_ID)
	_paint_base_terrain(map_data)
	_paint_height_regions(map_data)
	_paint_cliff_rims(map_data, catalog)
	_paint_station_complex(map_data, catalog)
	_paint_factory_yard(map_data, catalog)
	_paint_pipe_runs(map_data, catalog)
	_place_cover_and_nature(map_data, catalog)
	_place_markers_and_routes(map_data)
	if not _validate_catalog_usage(map_data, catalog):
		quit(1)
		return
	var save_error: Error = map_data.call("save_to_file", MAP_PATH)
	if save_error != OK:
		push_error("Could not save map %s: %s" % [MAP_PATH, error_string(save_error)])
		quit(1)
		return
	print("Generated %s" % MAP_PATH)
	quit(0)


func _paint_base_terrain(map_data) -> void:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		tile_data.type_id = "ground_flat"
		tile_data.object_type_id = ""
		tile_data.object_rotation_degrees = 0.0
		tile_data.object_scale = 1.0
		tile_data.walkable = true
		tile_data.blocks_los = false
		tile_data.cover_value = 0
		tile_data.object_height = 0
		tile_data.height_level = 0
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
		if _is_wash(grid):
			tile_data.type_id = "nature_ground_sand_dirt"
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
		elif _is_rock_field(grid):
			tile_data.type_id = "nature_ground_rock_dirt"
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
		elif posmod(grid.x * 13 + grid.y * 17, 31) == 0:
			tile_data.type_id = "nature_ground_grass_patch"


func _paint_height_regions(map_data) -> void:
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		var height_level: int = 0
		var edge_type: String = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		var ridge_nw: float = _ellipse_distance(grid, Vector2(13.5, 15.0), Vector2(9.5, 6.0))
		var ridge_east: float = _ellipse_distance(grid, Vector2(51.0, 21.0), Vector2(8.0, 10.5))
		var ridge_south: float = _ellipse_distance(grid, Vector2(44.0, 52.0), Vector2(13.0, 7.0))
		var station_plateau: float = _ellipse_distance(grid, Vector2(GRID_OBJECTIVE), Vector2(13.5, 12.5))
		if ridge_nw <= 1.0 or ridge_east <= 1.0 or ridge_south <= 1.0 or station_plateau <= 1.0:
			height_level = 1
			edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
		if ridge_nw <= 0.45 or ridge_east <= 0.55 or ridge_south <= 0.45:
			height_level = 2
			edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
		if height_level > 0:
			tile_data.height_level = height_level
			tile_data.edge_type = edge_type
			if String(tile_data.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND:
				tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
				tile_data.type_id = "nature_ground_rock_dirt"


func _paint_cliff_rims(map_data, catalog) -> void:
	for x in range(7, 22):
		_apply_type(map_data, catalog, Vector2i(x, 20 + int(sin(float(x)) * 2.0)), "cliff_straight_se")
	for y in range(14, 29):
		_apply_type(map_data, catalog, Vector2i(57, y), "cliff_straight_sw")
	for x in range(33, 55):
		_apply_type(map_data, catalog, Vector2i(x, 58 + int(cos(float(x)) * 2.0)), "cliff_straight_ne")
	for grid in [Vector2i(7, 20), Vector2i(21, 19), Vector2i(57, 14), Vector2i(57, 28), Vector2i(33, 57), Vector2i(54, 57)]:
		_apply_type(map_data, catalog, grid, "cliff_corner_se")


func _paint_station_complex(map_data, catalog) -> void:
	for x in range(22, 42):
		for y in range(23, 41):
			var local: Vector2i = Vector2i(x, y) - GRID_OBJECTIVE
			var floor_type: String = "station_set_floor_panel"
			if abs(local.x) >= 8 or abs(local.y) >= 7:
				floor_type = "station_set_floor_panel_straight"
			elif posmod(local.x * 5 + local.y * 7, 6) == 0:
				floor_type = "station_set_floor_detail"
			_apply_type(map_data, catalog, Vector2i(x, y), floor_type)
			var tile_data = map_data.call("get_tile_at_grid", Vector2i(x, y))
			if tile_data != null:
				tile_data.height_level = 1
				tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
				tile_data.walkable = true
				tile_data.blocks_los = false
				tile_data.cover_value = 0

	_place_station_perimeter(map_data, catalog, Rect2i(24, 25, 16, 14))
	_place_station_internal_walls(map_data, catalog)
	_place_station_rooms(map_data, catalog)
	_paint_landing_pad(map_data, catalog, Vector2i(15, 48))
	_paint_landing_pad(map_data, catalog, Vector2i(52, 14))


func _place_station_perimeter(map_data, catalog, rect: Rect2i) -> void:
	var left: int = rect.position.x
	var top: int = rect.position.y
	var right: int = rect.position.x + rect.size.x - 1
	var bottom: int = rect.position.y + rect.size.y - 1
	for x in range(left, right + 1):
		var north_type: String = "station_set_wall"
		var south_type: String = "station_set_wall"
		if x == left or x == right:
			north_type = "station_set_wall_corner"
			south_type = "station_set_wall_corner"
		elif x == 31:
			north_type = "station_set_wall_door"
			south_type = "station_set_wall_door_wide"
		elif posmod(x, 4) == 0:
			north_type = "station_set_wall_window"
		_place_object(map_data, catalog, Vector2i(x, top), north_type, 0.0)
		_place_object(map_data, catalog, Vector2i(x, bottom), south_type, 180.0)
	for y in range(top + 1, bottom):
		var west_type: String = "station_set_wall"
		var east_type: String = "station_set_wall"
		if y == 31:
			west_type = "station_set_wall_door"
			east_type = "station_set_wall_door_center"
		elif posmod(y, 5) == 0:
			east_type = "station_set_wall_window"
		_place_object(map_data, catalog, Vector2i(left, y), west_type, 270.0)
		_place_object(map_data, catalog, Vector2i(right, y), east_type, 90.0)

	for door_plan in [
		[Vector2i(31, top - 1), "station_set_door_single_closed", 0.0],
		[Vector2i(31, bottom + 1), "station_set_door_single", 180.0],
		[Vector2i(left - 1, 31), "station_set_door_single_half", 270.0],
		[Vector2i(right + 1, 31), "station_set_door_double_closed", 90.0],
	]:
		_apply_type(map_data, catalog, Vector2i(door_plan[0]), "station_set_floor_panel")
		_place_object(map_data, catalog, Vector2i(door_plan[0]), String(door_plan[1]), float(door_plan[2]))


func _place_station_internal_walls(map_data, catalog) -> void:
	for y in range(27, 37):
		if y == 31:
			_place_object(map_data, catalog, Vector2i(31, y), "station_set_wall_door_center", 90.0)
		else:
			_place_object(map_data, catalog, Vector2i(31, y), "station_set_wall_detail", 90.0)
	for x in range(26, 38):
		if x == 31:
			continue
		if x == 36:
			_place_object(map_data, catalog, Vector2i(x, 32), "station_set_wall_door_edge", 0.0)
		else:
			_place_object(map_data, catalog, Vector2i(x, 32), "station_set_wall", 0.0)


func _place_station_rooms(map_data, catalog) -> void:
	var object_plan: Array = [
		[Vector2i(27, 28), "station_set_computer_wide", 180.0],
		[Vector2i(28, 29), "station_set_computer_screen", 180.0],
		[Vector2i(29, 28), "station_set_chair_cushion", 0.0],
		[Vector2i(35, 28), "station_set_table_display", 90.0],
		[Vector2i(36, 29), "station_set_chair_armrest", 270.0],
		[Vector2i(34, 30), "station_set_computer_system", 90.0],
		[Vector2i(27, 35), "station_set_container_wide", 0.0],
		[Vector2i(28, 36), "station_set_container_flat_open", 0.0],
		[Vector2i(35, 35), "station_set_table_display_planet", 180.0],
		[Vector2i(36, 36), "station_set_container_tall", 90.0],
		[Vector2i(38, 33), "station_set_wall_switch", 90.0],
	]
	for entry in object_plan:
		_place_object(map_data, catalog, Vector2i(entry[0]), String(entry[1]), float(entry[2]))


func _paint_landing_pad(map_data, catalog, center: Vector2i) -> void:
	for x in range(center.x - 3, center.x + 4):
		for y in range(center.y - 3, center.y + 4):
			if not _inside_map(Vector2i(x, y)):
				continue
			var floor_type: String = "station_set_floor_panel"
			if abs(x - center.x) == 3 or abs(y - center.y) == 3:
				floor_type = "station_set_floor_panel_end"
			_apply_type(map_data, catalog, Vector2i(x, y), floor_type)
			var tile_data = map_data.call("get_tile_at_grid", Vector2i(x, y))
			if tile_data != null:
				tile_data.height_level = 0
				tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE


func _paint_factory_yard(map_data, catalog) -> void:
	for x in range(44, 56):
		for y in range(35, 47):
			var tile_data = map_data.call("get_tile_at_grid", Vector2i(x, y))
			if tile_data == null:
				continue
			tile_data.type_id = "nature_ground_dirt"
			tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
			tile_data.height_level = 0
			tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	var object_plan: Array = [
		[Vector2i(47, 37), "factory_building_a", 180.0, 0.85],
		[Vector2i(52, 37), "factory_building_d", 180.0, 0.85],
		[Vector2i(46, 43), "factory_detail_tank", 90.0, 1.0],
		[Vector2i(50, 43), "factory_chimney_medium", 0.0, 1.0],
		[Vector2i(54, 42), "factory_crane", 270.0, 0.9],
		[Vector2i(49, 45), "factory_box_large", 0.0, 1.0],
		[Vector2i(53, 45), "factory_conveyor", 90.0, 1.0],
	]
	for entry in object_plan:
		_place_object(map_data, catalog, Vector2i(entry[0]), String(entry[1]), float(entry[2]), float(entry[3]))


func _paint_pipe_runs(map_data, catalog) -> void:
	var pipe_path: Array[Vector2i] = []
	for x in range(39, 55):
		pipe_path.append(Vector2i(x, 40))
	for y in range(33, 41):
		pipe_path.append(Vector2i(39, y))
	_place_pipe_path(map_data, catalog, pipe_path)
	var branch_path: Array[Vector2i] = []
	for y in range(40, 47):
		branch_path.append(Vector2i(51, y))
	_place_pipe_path(map_data, catalog, branch_path)


func _place_pipe_path(map_data, catalog, path: Array[Vector2i]) -> void:
	for index in range(path.size()):
		var grid: Vector2i = path[index]
		var type_id: String = "spacekit_pipe_straight"
		var rotation: float = 0.0
		if index == 0 or index == path.size() - 1:
			type_id = "spacekit_pipe_end"
			rotation = _direction_to_rotation(_neighbor_direction(path, index))
		elif _is_pipe_corner(path, index):
			type_id = "spacekit_pipe_corner"
			rotation = 90.0
		else:
			rotation = _pipe_straight_rotation(path, index)
		_place_object(map_data, catalog, grid, type_id, rotation, 1.0)
	for grid in [Vector2i(39, 40), Vector2i(51, 40)]:
		_place_object(map_data, catalog, grid, "spacekit_pipe_split", 0.0, 1.0)


func _place_cover_and_nature(map_data, catalog) -> void:
	var protected: Dictionary = _build_protected_lookup()
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		if protected.has(grid) or not String(tile_data.object_type_id).is_empty():
			continue
		var selector: int = posmod(grid.x * 29 + grid.y * 37, 67)
		if selector == 0 and int(tile_data.height_level) == 0:
			_place_object(map_data, catalog, grid, "nature_tree_blocker", _rotation_from_grid(grid))
		elif selector == 1:
			_place_object(map_data, catalog, grid, "nature_rock_cover", _rotation_from_grid(grid))
		elif selector == 2:
			_place_object(map_data, catalog, grid, "nature_bush_cover", _rotation_from_grid(grid))
		elif selector == 3 and String(tile_data.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			_place_object(map_data, catalog, grid, "nature_cactus_cover", _rotation_from_grid(grid))
	for grid in [Vector2i(9, 53), Vector2i(10, 52), Vector2i(17, 47), Vector2i(43, 30), Vector2i(45, 29), Vector2i(49, 34)]:
		_place_object(map_data, catalog, grid, "nature_rock_cover", _rotation_from_grid(grid))


func _place_markers_and_routes(map_data) -> void:
	_set_marker(map_data, "spawn_alpha", "spawn_alpha", GRID_SPAWN_ALPHA, {"name": "Alpha LZ"})
	_set_marker(map_data, "spawn_bravo", "spawn_bravo", GRID_SPAWN_BRAVO, {"name": "Bravo Ridge Entry"})
	_set_marker(map_data, "objective_point", "objective_point", GRID_OBJECTIVE, {"name": "Station Core"})
	_set_marker(map_data, "rally_southwest", "rally_point", GRID_RALLY, {"name": "Southwest Rally"})
	_set_marker(map_data, "factory_danger_zone", "danger_zone", GRID_DANGER, {"name": "Factory Pipe Yard"})
	_set_marker(map_data, "ridge_recon_note", "recon_note", GRID_RECON, {"name": "Ridge Overwatch"})
	map_data.call("set_patrol_path", "factory_watch_route", [
		_tile_world(map_data, Vector2i(46, 36)),
		_tile_world(map_data, Vector2i(54, 37)),
		_tile_world(map_data, Vector2i(53, 45)),
		_tile_world(map_data, Vector2i(45, 43)),
	])
	map_data.call("set_patrol_path", "station_loop_route", [
		_tile_world(map_data, Vector2i(24, 24)),
		_tile_world(map_data, Vector2i(40, 24)),
		_tile_world(map_data, Vector2i(41, 39)),
		_tile_world(map_data, Vector2i(23, 39)),
	])


func _apply_type(map_data, catalog, grid: Vector2i, type_id: String) -> void:
	if not _inside_map(grid):
		return
	var tile_data = map_data.call("get_tile_at_grid", grid)
	if tile_data == null:
		return
	catalog.call("apply_type_to_tile", tile_data, type_id)


func _place_object(map_data, catalog, grid: Vector2i, type_id: String, rotation_degrees: float = 0.0, object_scale: float = 1.0) -> void:
	if not _inside_map(grid):
		return
	var tile_data = map_data.call("get_tile_at_grid", grid)
	if tile_data == null:
		return
	catalog.call("apply_type_to_tile", tile_data, type_id)
	tile_data.object_rotation_degrees = fposmod(rotation_degrees, 360.0)
	tile_data.object_scale = object_scale


func _set_marker(map_data, marker_id: String, marker_type_id: String, grid: Vector2i, overrides: Dictionary) -> void:
	map_data.call("set_marker", marker_id, marker_type_id, _tile_world(map_data, grid), overrides)


func _tile_world(map_data, grid: Vector2i) -> Vector2:
	var tile_data = map_data.call("get_tile_at_grid", grid)
	return Vector2(tile_data.world_position) if tile_data != null else Vector2.ZERO


func _validate_catalog_usage(map_data, catalog) -> bool:
	var ok: bool = true
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var type_id: String = String(tile_data.type_id).strip_edges().to_lower()
		var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower()
		if type_id.is_empty() or not catalog.call("has_type", type_id):
			push_error("Missing terrain type_id in generated map: %s" % type_id)
			ok = false
		if not object_type_id.is_empty() and not catalog.call("has_type", object_type_id):
			push_error("Missing object_type_id in generated map: %s" % object_type_id)
			ok = false
	return ok


func _build_protected_lookup() -> Dictionary:
	var result: Dictionary = {}
	for center in [GRID_SPAWN_ALPHA, GRID_SPAWN_BRAVO, GRID_OBJECTIVE, GRID_RALLY, GRID_DANGER, GRID_RECON, Vector2i(32, 32), Vector2i(50, 40)]:
		for x in range(center.x - 5, center.x + 6):
			for y in range(center.y - 5, center.y + 6):
				if _inside_map(Vector2i(x, y)):
					result[Vector2i(x, y)] = true
	return result


func _is_wash(grid: Vector2i) -> bool:
	return _grid_distance_to_segment(Vector2(grid), Vector2(4, 55), Vector2(60, 9)) <= 3.2


func _is_rock_field(grid: Vector2i) -> bool:
	return _ellipse_distance(grid, Vector2(13.5, 15.0), Vector2(12.0, 8.0)) <= 1.2 or _ellipse_distance(grid, Vector2(51.0, 21.0), Vector2(10.0, 12.0)) <= 1.2


func _ellipse_distance(grid: Vector2i, center: Vector2, radius: Vector2) -> float:
	var delta: Vector2 = (Vector2(grid) - center) / radius
	return sqrt((delta.x * delta.x) + (delta.y * delta.y))


func _grid_distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _neighbor_direction(path: Array[Vector2i], index: int) -> Vector2i:
	if path.size() <= 1:
		return Vector2i(0, -1)
	if index == 0:
		return path[1] - path[0]
	return path[index] - path[index - 1]


func _is_pipe_corner(path: Array[Vector2i], index: int) -> bool:
	if index <= 0 or index >= path.size() - 1:
		return false
	return path[index] - path[index - 1] != path[index + 1] - path[index]


func _pipe_straight_rotation(path: Array[Vector2i], index: int) -> float:
	var direction: Vector2i = path[index] - path[index - 1]
	return _direction_to_rotation(direction)


func _direction_to_rotation(direction: Vector2i) -> float:
	if abs(direction.x) > 0:
		return 90.0
	if direction.y > 0:
		return 180.0
	return 0.0


func _rotation_from_grid(grid: Vector2i) -> float:
	return float(posmod((grid.x * 90) + (grid.y * 45), 360))


func _inside_map(grid: Vector2i) -> bool:
	return grid.x >= 0 and grid.y >= 0 and grid.x < MAP_SIZE.x and grid.y < MAP_SIZE.y
