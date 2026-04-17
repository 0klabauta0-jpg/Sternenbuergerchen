class_name TerrainMapData
extends RefCounted

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _map_name: String = ""
var _grid_size: Vector2i = Vector2i.ZERO
var _tile_half_width: float = 64.0
var _tile_half_height: float = 32.0
var _grid_origin: Vector2 = Vector2.ZERO
var _tiles: Array = []


static func load_from_file(path: String) -> TerrainMapData:
	var terrain_map_data := TerrainMapData.new()
	if path.is_empty() or not FileAccess.file_exists(path):
		return terrain_map_data

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("TerrainMapData could not open map file for reading: %s" % path)
		return terrain_map_data

	var parsed_json: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_json) != TYPE_DICTIONARY:
		push_warning("TerrainMapData expected a Dictionary JSON root in: %s" % path)
		return terrain_map_data

	var root_dict: Dictionary = parsed_json
	terrain_map_data._map_name = String(root_dict.get("map_name", path.get_file().get_basename()))
	terrain_map_data._grid_size = _coerce_vector2i(root_dict.get("grid_size", Vector2i.ZERO))

	var tile_size_dict: Dictionary = root_dict.get("tile_size", {})
	terrain_map_data._tile_half_width = maxf(float(tile_size_dict.get("half_width", 64.0)), 0.001)
	terrain_map_data._tile_half_height = maxf(float(tile_size_dict.get("half_height", 32.0)), 0.001)
	terrain_map_data._grid_origin = _coerce_vector2(root_dict.get("grid_origin", Vector2.ZERO))

	var tiles_variant: Variant = root_dict.get("tiles", [])
	if tiles_variant is Array:
		for tile_entry in tiles_variant:
			if typeof(tile_entry) != TYPE_DICTIONARY:
				continue

			var normalized_tile_entry: Dictionary = tile_entry.duplicate(true)
			var grid_position: Vector2i = _coerce_vector2i(normalized_tile_entry.get("grid_position", Vector2i.ZERO))
			normalized_tile_entry["grid_position"] = grid_position
			normalized_tile_entry["tile_id"] = "tile_%d_%d" % [grid_position.x, grid_position.y]
			normalized_tile_entry["world_position"] = terrain_map_data._grid_to_world(grid_position)

			var tile_data = TERRAIN_TILE_DATA_SCRIPT.call("from_dict", normalized_tile_entry)
			if tile_data == null or not tile_data.has_method("is_valid") or not bool(tile_data.call("is_valid")):
				continue

			terrain_map_data._tiles.append(tile_data)

	return terrain_map_data


static func create_empty(
	map_name: String,
	grid_size: Vector2i,
	grid_origin: Vector2,
	half_tile_width: float = 64.0,
	half_tile_height: float = 32.0
) -> TerrainMapData:
	var terrain_map_data := TerrainMapData.new()
	terrain_map_data._map_name = map_name
	terrain_map_data._grid_size = grid_size
	terrain_map_data._grid_origin = grid_origin
	terrain_map_data._tile_half_width = maxf(half_tile_width, 0.001)
	terrain_map_data._tile_half_height = maxf(half_tile_height, 0.001)

	for x in range(maxi(grid_size.x, 0)):
		for y in range(maxi(grid_size.y, 0)):
			var grid_position := Vector2i(x, y)
			var tile_data = TERRAIN_TILE_DATA_SCRIPT.call(
				"from_dict",
				{
					"tile_id": "tile_%d_%d" % [x, y],
					"grid_position": grid_position,
					"world_position": terrain_map_data._grid_to_world(grid_position),
					"walkable": TERRAIN_TILE_DATA_SCRIPT.DEFAULT_WALKABLE,
					"blocks_los": TERRAIN_TILE_DATA_SCRIPT.DEFAULT_BLOCKS_LOS,
					"cover_value": TERRAIN_TILE_DATA_SCRIPT.DEFAULT_COVER_VALUE,
					"height_level": TERRAIN_TILE_DATA_SCRIPT.DEFAULT_HEIGHT_LEVEL,
					"surface_type": TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE,
				}
			)
			terrain_map_data._tiles.append(tile_data)

	return terrain_map_data


func save_to_file(path: String) -> Error:
	if path.is_empty():
		return ERR_INVALID_PARAMETER

	var directory_path: String = path.get_base_dir()
	if not directory_path.is_empty():
		var make_dir_error: Error = DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory_path))
		if make_dir_error != OK:
			return make_dir_error

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()

	var json_root: Dictionary = {
		"map_name": _map_name,
		"grid_size": {
			"x": _grid_size.x,
			"y": _grid_size.y,
		},
		"tile_size": {
			"half_width": int(round(_tile_half_width)),
			"half_height": int(round(_tile_half_height)),
		},
		"grid_origin": {
			"x": int(round(_grid_origin.x)),
			"y": int(round(_grid_origin.y)),
		},
		"tiles": [],
	}

	for tile_data in _get_sorted_tiles():
		var tile_dict: Dictionary = tile_data.call("to_dict")
		var grid_position: Vector2i = tile_dict.get("grid_position", Vector2i.ZERO)
		json_root["tiles"].append(
			{
				"grid_position": {
					"x": grid_position.x,
					"y": grid_position.y,
				},
				"walkable": bool(tile_dict.get("walkable", true)),
				"blocks_los": bool(tile_dict.get("blocks_los", false)),
				"cover_value": int(tile_dict.get("cover_value", 0)),
				"height_level": int(tile_dict.get("height_level", 0)),
				"surface_type": String(tile_dict.get("surface_type", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE)),
			}
		)

	file.store_string(JSON.stringify(json_root, "\t") + "\n")
	return OK


func get_tiles() -> Array:
	return _tiles.duplicate()


func get_tile_at_grid(grid_position: Vector2i):
	for tile_data in _tiles:
		if tile_data == null:
			continue

		if tile_data.grid_position == grid_position:
			return tile_data

	return null


func get_map_name() -> String:
	return _map_name


func set_map_name(map_name: String) -> void:
	_map_name = map_name.strip_edges()


func get_grid_size() -> Vector2i:
	return _grid_size


func get_tile_size() -> Dictionary:
	return {
		"half_width": _tile_half_width,
		"half_height": _tile_half_height,
	}


func get_grid_origin() -> Vector2:
	return _grid_origin


func _grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(
		_grid_origin.x + (float(grid_position.x - grid_position.y) * _tile_half_width),
		_grid_origin.y + (float(grid_position.x + grid_position.y) * _tile_half_height)
	)


func _get_sorted_tiles() -> Array:
	var sortable_tiles: Array = []
	for tile_data in _tiles:
		if tile_data == null:
			continue

		sortable_tiles.append(
			{
				"grid_position": tile_data.grid_position,
				"tile": tile_data,
			}
		)

	sortable_tiles.sort_custom(_sort_tile_entries)

	var sorted_tiles: Array = []
	for entry in sortable_tiles:
		sorted_tiles.append(entry["tile"])

	return sorted_tiles


func _sort_tile_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_grid: Vector2i = a.get("grid_position", Vector2i.ZERO)
	var b_grid: Vector2i = b.get("grid_position", Vector2i.ZERO)
	if a_grid.x == b_grid.x:
		return a_grid.y < b_grid.y

	return a_grid.x < b_grid.x


static func _coerce_vector2i(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value

	if value is Vector2:
		return Vector2i(roundi((value as Vector2).x), roundi((value as Vector2).y))

	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2i(int(value_dict.get("x", 0)), int(value_dict.get("y", 0)))

	return Vector2i.ZERO


static func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", 0.0)), float(value_dict.get("y", 0.0)))

	return Vector2.ZERO
