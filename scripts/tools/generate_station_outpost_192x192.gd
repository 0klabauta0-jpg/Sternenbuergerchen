extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const SOURCE_MAP_PATH: String = "res://maps/station_outpost_64x64.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MAP_NAME: String = "station_outpost_192x192"
const SOURCE_SIZE: Vector2i = Vector2i(64, 64)
const MAP_SIZE: Vector2i = Vector2i(192, 192)
const CENTER_SECTOR: Vector2i = Vector2i(1, 1)
const CENTER_OFFSET: Vector2i = Vector2i(64, 64)

const SECTOR_ROTATIONS: Dictionary = {
	Vector2i(0, 0): 180.0,
	Vector2i(1, 0): 90.0,
	Vector2i(2, 0): 0.0,
	Vector2i(0, 1): 270.0,
	Vector2i(1, 1): 0.0,
	Vector2i(2, 1): 90.0,
	Vector2i(0, 2): 0.0,
	Vector2i(1, 2): 270.0,
	Vector2i(2, 2): 180.0,
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	if catalog == null:
		push_error("Terrain tile catalog could not be loaded.")
		quit(1)
		return
	var source_map = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", SOURCE_MAP_PATH)
	if source_map == null or bool(source_map.call("has_load_issue")) or Vector2i(source_map.call("get_grid_size")) != SOURCE_SIZE:
		push_error("Source startmap is missing, invalid, or not 64x64: %s" % SOURCE_MAP_PATH)
		quit(1)
		return

	var tile_size: Dictionary = Dictionary(source_map.call("get_tile_size"))
	var target_map = TERRAIN_MAP_DATA_SCRIPT.call(
		"create_empty",
		MAP_NAME,
		MAP_SIZE,
		source_map.call("get_grid_origin"),
		float(tile_size.get("half_width", 64.0)),
		float(tile_size.get("half_height", 32.0)),
		int(source_map.call("get_mission_slot_count"))
	)
	target_map.call("set_terrain_visual_theme_id", String(source_map.call("get_terrain_visual_theme_id")))

	var source_tiles: Array = Array(source_map.call("get_tiles"))
	var target_lookup: Dictionary = _build_tile_lookup(target_map)
	for sector_x in range(3):
		for sector_y in range(3):
			var sector := Vector2i(sector_x, sector_y)
			var rotation_degrees: float = float(SECTOR_ROTATIONS.get(sector, 0.0))
			_stamp_sector(source_tiles, target_lookup, sector, rotation_degrees)

	_copy_center_markers_and_routes(source_map, target_map, target_lookup)
	if not _validate_catalog_usage(target_map, catalog):
		quit(1)
		return

	var save_error: Error = target_map.call("save_to_file", MAP_PATH)
	if save_error != OK:
		push_error("Could not save map %s: %s" % [MAP_PATH, error_string(save_error)])
		quit(1)
		return
	print("Generated %s" % MAP_PATH)
	quit(0)


func _stamp_sector(source_tiles: Array, target_lookup: Dictionary, sector: Vector2i, rotation_degrees: float) -> void:
	var sector_offset: Vector2i = sector * SOURCE_SIZE
	var is_center: bool = sector == CENTER_SECTOR
	for source_tile in source_tiles:
		if source_tile == null:
			continue
		var source_grid: Vector2i = Vector2i(source_tile.grid_position)
		var target_grid: Vector2i = sector_offset + (_rotate_local_grid(source_grid, rotation_degrees) if not is_center else source_grid)
		var target_tile = target_lookup.get(target_grid, null)
		if target_tile == null:
			continue
		_copy_tile(source_tile, target_tile, target_grid, 0.0 if is_center else rotation_degrees)
		if not is_center:
			_apply_sector_variation(target_tile, target_grid, sector)


func _copy_tile(source_tile, target_tile, target_grid: Vector2i, rotation_degrees: float) -> void:
	target_tile.tile_id = "tile_%d_%d" % [target_grid.x, target_grid.y]
	target_tile.grid_position = target_grid
	target_tile.type_id = _rotate_directional_type_id(String(source_tile.type_id), rotation_degrees)
	target_tile.object_type_id = String(source_tile.object_type_id)
	target_tile.walkable = bool(source_tile.walkable)
	target_tile.blocks_los = bool(source_tile.blocks_los)
	target_tile.cover_value = int(source_tile.cover_value)
	target_tile.height_level = int(source_tile.height_level)
	target_tile.object_height = int(source_tile.object_height)
	target_tile.object_rotation_degrees = fposmod(float(source_tile.object_rotation_degrees) + rotation_degrees, 360.0)
	target_tile.object_scale = float(source_tile.object_scale)
	target_tile.surface_type = String(source_tile.surface_type)
	target_tile.edge_type = String(source_tile.edge_type)


func _apply_sector_variation(tile_data, grid: Vector2i, sector: Vector2i) -> void:
	if tile_data == null:
		return
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower()
	var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower()
	if type_id.begins_with("station_set_") or object_type_id.begins_with("station_set_") or object_type_id.begins_with("factory_"):
		return
	var selector: int = posmod((grid.x * 19) + (grid.y * 23) + (sector.x * 11) + (sector.y * 17), 97)
	if object_type_id.begins_with("nature_") and selector == 0:
		tile_data.object_rotation_degrees = fposmod(float(tile_data.object_rotation_degrees) + 90.0, 360.0)
	if type_id == "ground_flat" and selector == 1:
		tile_data.type_id = "nature_ground_grass_patch"
	elif type_id == "ground_flat" and selector == 2:
		tile_data.type_id = "nature_ground_dirt"
	elif String(tile_data.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND and selector == 3:
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND
		tile_data.type_id = "nature_ground_sand_dirt"
	elif String(tile_data.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND and selector == 4 and int(tile_data.height_level) > 0:
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK
		tile_data.type_id = "nature_ground_rock_dirt"


func _copy_center_markers_and_routes(source_map, target_map, target_lookup: Dictionary) -> void:
	for marker_id in PackedStringArray(source_map.call("get_marker_ids")):
		var source_record: Dictionary = Dictionary(source_map.call("get_marker_record", marker_id))
		var source_position: Vector2 = Vector2(source_record.get("position", source_map.call("get_marker_position", marker_id, Vector2.ZERO)))
		var shifted_grid: Vector2i = _world_to_grid(source_map, source_position) + CENTER_OFFSET
		var target_position: Vector2 = _world_for_grid(target_lookup, shifted_grid)
		var overrides: Dictionary = source_record.duplicate(true)
		overrides.erase("position")
		overrides.erase("marker_type_id")
		target_map.call("set_marker", marker_id, String(source_record.get("marker_type_id", marker_id)), target_position, overrides)

	var patrol_paths: Dictionary = Dictionary(source_map.call("get_patrol_paths"))
	for path_id_variant in patrol_paths.keys():
		var path_id: String = String(path_id_variant)
		var shifted_waypoints: Array = []
		for waypoint_variant in Array(source_map.call("get_patrol_path", path_id)):
			var source_grid: Vector2i = _world_to_grid(source_map, Vector2(waypoint_variant))
			shifted_waypoints.append(_world_for_grid(target_lookup, source_grid + CENTER_OFFSET))
		target_map.call("set_patrol_path", path_id, shifted_waypoints)


func _rotate_local_grid(grid: Vector2i, rotation_degrees: float) -> Vector2i:
	var steps: int = posmod(roundi(rotation_degrees / 90.0), 4)
	match steps:
		1:
			return Vector2i(SOURCE_SIZE.x - 1 - grid.y, grid.x)
		2:
			return Vector2i(SOURCE_SIZE.x - 1 - grid.x, SOURCE_SIZE.y - 1 - grid.y)
		3:
			return Vector2i(grid.y, SOURCE_SIZE.y - 1 - grid.x)
		_:
			return grid


func _rotate_directional_type_id(type_id: String, rotation_degrees: float) -> String:
	var normalized: String = type_id.strip_edges().to_lower()
	var steps: int = posmod(roundi(rotation_degrees / 90.0), 4)
	if steps == 0:
		return normalized
	var suffixes: PackedStringArray = ["ne", "se", "sw", "nw"]
	for index in range(suffixes.size()):
		var suffix: String = "_%s" % suffixes[index]
		if normalized.ends_with(suffix):
			var next_suffix: String = suffixes[posmod(index + steps, suffixes.size())]
			return normalized.substr(0, normalized.length() - suffix.length()) + "_%s" % next_suffix
	return normalized


func _build_tile_lookup(map_data) -> Dictionary:
	var result: Dictionary = {}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		result[Vector2i(tile_data.grid_position)] = tile_data
	return result


func _world_for_grid(tile_lookup: Dictionary, grid: Vector2i) -> Vector2:
	var tile_data = tile_lookup.get(grid, null)
	return Vector2(tile_data.world_position) if tile_data != null else Vector2.ZERO


func _world_to_grid(map_data, world_position: Vector2) -> Vector2i:
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	var half_width: float = maxf(float(tile_size.get("half_width", 64.0)), 0.001)
	var half_height: float = maxf(float(tile_size.get("half_height", 32.0)), 0.001)
	var delta: Vector2 = world_position - Vector2(map_data.call("get_grid_origin"))
	var grid_x: float = ((delta.y / half_height) + (delta.x / half_width)) * 0.5
	var grid_y: float = ((delta.y / half_height) - (delta.x / half_width)) * 0.5
	return Vector2i(roundi(grid_x), roundi(grid_y))


func _validate_catalog_usage(map_data, catalog) -> bool:
	var ok: bool = true
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var type_id: String = String(tile_data.type_id).strip_edges().to_lower()
		var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower()
		if type_id.is_empty() or not bool(catalog.call("has_type", type_id)):
			push_error("Missing terrain type_id in generated map: %s" % type_id)
			ok = false
		if not object_type_id.is_empty() and not bool(catalog.call("has_type", object_type_id)):
			push_error("Missing object_type_id in generated map: %s" % object_type_id)
			ok = false
	return ok
