class_name TerrainMapData
extends RefCounted

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")

var _map_name: String = ""
var _terrain_visual_theme_id: String = ""
var _grid_topology: String = "square8"
var _mission_slot_count: int = 3
var _grid_size: Vector2i = Vector2i.ZERO
var _tile_half_width: float = 64.0
var _tile_half_height: float = 32.0
var _grid_origin: Vector2 = Vector2.ZERO
var _markers: Dictionary = {}
var _patrol_paths: Dictionary = {}
var _enemy_team_configs: Dictionary = {}
var _tiles: Array = []
var _load_issue_message: String = ""


static func load_from_file(path: String) -> TerrainMapData:
	var terrain_map_data := TerrainMapData.new()
	if path.is_empty() or not FileAccess.file_exists(path):
		return terrain_map_data

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("TerrainMapData could not open map file for reading: %s" % path)
		return terrain_map_data

	var file_text: String = file.get_as_text()
	if file_text.strip_edges().is_empty():
		push_warning("TerrainMapData found an empty map file: %s" % path)
		return terrain_map_data
	if _contains_nul_codepoint(file_text):
		push_warning("TerrainMapData found NUL bytes in map file: %s" % path)
		return terrain_map_data

	var parsed_json: Variant = JSON.parse_string(file_text)
	if typeof(parsed_json) != TYPE_DICTIONARY:
		push_warning("TerrainMapData expected a Dictionary JSON root in: %s" % path)
		return terrain_map_data

	var root_dict: Dictionary = parsed_json
	var topology: String = String(root_dict.get("grid_topology", "square8")).strip_edges()
	if topology != "square8" and topology != HEX_GRID_SCRIPT.TOPOLOGY_ID:
		terrain_map_data._load_issue_message = "Unsupported grid_topology '%s' in %s" % [topology, path]
		push_warning(terrain_map_data._load_issue_message)
		return terrain_map_data
	terrain_map_data._grid_topology = topology
	terrain_map_data._map_name = String(root_dict.get("map_name", path.get_file().get_basename()))
	terrain_map_data._terrain_visual_theme_id = _normalize_optional_id(String(root_dict.get("terrain_visual_theme_id", root_dict.get("surface_visual_theme_id", ""))))
	terrain_map_data._mission_slot_count = maxi(int(root_dict.get("mission_slot_count", 3)), 1)
	terrain_map_data._grid_size = _coerce_vector2i(root_dict.get("grid_size", Vector2i.ZERO))

	var tile_size_dict: Dictionary = root_dict.get("tile_size", {})
	terrain_map_data._tile_half_width = maxf(float(tile_size_dict.get("half_width", 64.0)), 0.001)
	terrain_map_data._tile_half_height = maxf(float(tile_size_dict.get("half_height", 32.0)), 0.001)
	terrain_map_data._grid_origin = _coerce_vector2(root_dict.get("grid_origin", Vector2.ZERO))
	terrain_map_data._markers = _coerce_marker_dictionary(root_dict.get("markers", {}))
	terrain_map_data._patrol_paths = _coerce_patrol_dictionary(root_dict.get("patrol_paths", {}))
	terrain_map_data._enemy_team_configs = _coerce_enemy_team_config_dictionary(root_dict.get("enemy_team_configs", {}), terrain_map_data._grid_size)

	var tiles_variant: Variant = root_dict.get("tiles", [])
	if tiles_variant is Array:
		var tile_catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
		var legacy_wall_positions: Array[Vector2i] = []
		for tile_entry in tiles_variant:
			if typeof(tile_entry) != TYPE_DICTIONARY:
				continue
			var tile_dict: Dictionary = tile_entry
			var type_id: String = String(tile_dict.get("type_id", "")).strip_edges().to_lower()
			if type_id != "wall":
				continue
			legacy_wall_positions.append(_coerce_vector2i(tile_dict.get("grid_position", Vector2i.ZERO)))
		if not legacy_wall_positions.is_empty():
			var first_legacy_position: Vector2i = legacy_wall_positions[0]
			terrain_map_data._load_issue_message = "Old map file detected in %s: tile type 'wall' is no longer supported (first at %d,%d; %d total). Please rebuild this map with the current wall types." % [
				path,
				first_legacy_position.x,
				first_legacy_position.y,
				legacy_wall_positions.size(),
			]
			push_warning(terrain_map_data._load_issue_message)
			return terrain_map_data
		for tile_entry in tiles_variant:
			if typeof(tile_entry) != TYPE_DICTIONARY:
				continue

			var normalized_tile_entry: Dictionary = tile_entry.duplicate(true)
			var grid_position: Vector2i = _coerce_vector2i(normalized_tile_entry.get("grid_position", Vector2i.ZERO))
			normalized_tile_entry["grid_position"] = grid_position
			normalized_tile_entry["tile_id"] = "tile_%d_%d" % [grid_position.x, grid_position.y]
			normalized_tile_entry["world_position"] = terrain_map_data._grid_to_world(grid_position)
			_normalize_legacy_object_layer_tile(normalized_tile_entry, tile_catalog)

			var tile_data = TERRAIN_TILE_DATA_SCRIPT.call("from_dict", normalized_tile_entry)
			if tile_data == null or not tile_data.has_method("is_valid") or not bool(tile_data.call("is_valid")):
				continue

			terrain_map_data._tiles.append(tile_data)

	return terrain_map_data


static func _normalize_legacy_object_layer_tile(tile_entry: Dictionary, catalog = null) -> void:
	if tile_entry.is_empty():
		return

	var type_id: String = String(tile_entry.get("type_id", "")).strip_edges()
	var object_type_id: String = String(tile_entry.get("object_type_id", "")).strip_edges()
	if type_id.is_empty() or not object_type_id.is_empty():
		return

	if catalog == null or not catalog.has_method("is_object_layer_type"):
		return
	if not bool(catalog.call("is_object_layer_type", type_id)):
		return

	tile_entry["object_type_id"] = type_id
	tile_entry["type_id"] = "ground_flat"


static func create_empty(
	map_name: String,
	grid_size: Vector2i,
	grid_origin: Vector2,
	half_tile_width: float = 64.0,
	half_tile_height: float = 32.0,
	mission_slot_count: int = 3,
	grid_topology: String = "square8"
) -> TerrainMapData:
	var terrain_map_data := TerrainMapData.new()
	if grid_topology != "square8" and grid_topology != HEX_GRID_SCRIPT.TOPOLOGY_ID:
		terrain_map_data._load_issue_message = "Unsupported grid_topology '%s'" % grid_topology
		push_warning(terrain_map_data._load_issue_message)
		return terrain_map_data
	terrain_map_data._grid_topology = grid_topology
	terrain_map_data._map_name = map_name
	terrain_map_data._mission_slot_count = maxi(mission_slot_count, 1)
	terrain_map_data._grid_size = grid_size
	terrain_map_data._grid_origin = grid_origin
	terrain_map_data._tile_half_width = maxf(half_tile_width, 0.001)
	terrain_map_data._tile_half_height = maxf(half_tile_height, 0.001)
	terrain_map_data._enemy_team_configs["default"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", grid_size), grid_size)

	for x in range(maxi(grid_size.x, 0)):
		for y in range(maxi(grid_size.y, 0)):
			var grid_position := Vector2i(x, y)
			var tile_data = TERRAIN_TILE_DATA_SCRIPT.call(
				"from_dict",
				{
					"tile_id": "tile_%d_%d" % [x, y],
					"type_id": "ground_flat",
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
		"grid_topology": _grid_topology,
		"mission_slot_count": _mission_slot_count,
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
		"markers": _serialize_markers(),
		"patrol_paths": _serialize_patrol_paths(),
		"enemy_team_configs": _serialize_enemy_team_configs(),
		"tiles": [],
	}
	if not _terrain_visual_theme_id.is_empty():
		json_root["terrain_visual_theme_id"] = _terrain_visual_theme_id

	for tile_data in _get_sorted_tiles():
		var tile_dict: Dictionary = tile_data.call("to_dict")
		var grid_position: Vector2i = tile_dict.get("grid_position", Vector2i.ZERO)
		var serialized_tile: Dictionary = {
			"grid_position": {
				"x": grid_position.x,
				"y": grid_position.y,
			},
			"type_id": String(tile_dict.get("type_id", "")),
			"walkable": bool(tile_dict.get("walkable", true)),
			"blocks_los": bool(tile_dict.get("blocks_los", false)),
			"cover_value": int(tile_dict.get("cover_value", 0)),
			"height_level": int(tile_dict.get("height_level", 0)),
			"object_height": int(tile_dict.get("object_height", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_OBJECT_HEIGHT)),
			"surface_type": String(tile_dict.get("surface_type", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE)),
			"edge_type": String(tile_dict.get("edge_type", TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF)),
		}
		var object_type_id: String = String(tile_dict.get("object_type_id", "")).strip_edges()
		if not object_type_id.is_empty():
			serialized_tile["object_type_id"] = object_type_id
		var object_rotation_degrees: float = float(tile_dict.get("object_rotation_degrees", 0.0))
		if absf(object_rotation_degrees) > 0.001:
			serialized_tile["object_rotation_degrees"] = object_rotation_degrees
		var object_scale: float = float(tile_dict.get("object_scale", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_OBJECT_SCALE))
		if absf(object_scale - TERRAIN_TILE_DATA_SCRIPT.DEFAULT_OBJECT_SCALE) > 0.001:
			serialized_tile["object_scale"] = object_scale
		json_root["tiles"].append(serialized_tile)

	file.store_string(JSON.stringify(json_root, "\t") + "\n")
	file.flush()
	return OK


func get_tiles() -> Array:
	return _tiles.duplicate()


func has_load_issue() -> bool:
	return not _load_issue_message.is_empty()


func get_load_issue_message() -> String:
	return _load_issue_message


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


func get_terrain_visual_theme_id() -> String:
	return _terrain_visual_theme_id


func set_terrain_visual_theme_id(theme_id: String) -> void:
	_terrain_visual_theme_id = _normalize_optional_id(theme_id)


func get_mission_slot_count() -> int:
	return maxi(_mission_slot_count, 1)


func set_mission_slot_count(mission_slot_count: int) -> void:
	_mission_slot_count = maxi(mission_slot_count, 1)


func get_grid_size() -> Vector2i:
	return _grid_size


func get_grid_topology() -> String:
	return _grid_topology


func get_tile_size() -> Dictionary:
	return {
		"half_width": _tile_half_width,
		"half_height": _tile_half_height,
	}


func get_grid_origin() -> Vector2:
	return _grid_origin


func get_markers() -> Dictionary:
	return _markers.duplicate(true)


func get_marker_ids() -> PackedStringArray:
	var marker_ids: PackedStringArray = []
	var sorted_ids: Array = _markers.keys()
	sorted_ids.sort()
	for marker_id_variant in sorted_ids:
		marker_ids.append(String(marker_id_variant))
	return marker_ids


func get_marker_record(marker_id: String) -> Dictionary:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty() or not _markers.has(normalized_marker_id):
		return {}
	return Dictionary(_markers.get(normalized_marker_id, {})).duplicate(true)


func get_marker_type_id(marker_id: String) -> String:
	var marker_record: Dictionary = get_marker_record(marker_id)
	return String(marker_record.get("marker_type_id", "")).strip_edges().to_lower()


func get_marker_display_name(marker_id: String) -> String:
	var marker_record: Dictionary = get_marker_record(marker_id)
	if marker_record.is_empty():
		return marker_id.strip_edges()
	return String(marker_record.get("name", marker_id)).strip_edges()


func get_marker_context(marker_id: String) -> String:
	var marker_record: Dictionary = get_marker_record(marker_id)
	if marker_record.is_empty():
		return String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_context", marker_id)).strip_edges().to_lower()
	return String(marker_record.get("placement_context", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_context", marker_id))).strip_edges().to_lower()


func get_marker_symbol(marker_id: String) -> String:
	var marker_record: Dictionary = get_marker_record(marker_id)
	if marker_record.is_empty():
		return String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", marker_id)).strip_edges().to_lower()
	return String(marker_record.get("symbol", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", marker_id))).strip_edges().to_lower()


func get_marker_color(marker_id: String, fallback: Color = Color(0.9, 0.9, 0.9, 1.0)) -> Color:
	var marker_record: Dictionary = get_marker_record(marker_id)
	if marker_record.is_empty():
		return TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_color", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", marker_id), fallback)
	return TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_color", marker_record.get("color", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", marker_id)), fallback)


func get_patrol_paths() -> Dictionary:
	return _patrol_paths.duplicate(true)


func get_patrol_path(spawn_id: String) -> Array:
	var normalized_spawn_id: String = spawn_id.strip_edges()
	if normalized_spawn_id.is_empty() or not _patrol_paths.has(normalized_spawn_id):
		return []
	return _coerce_patrol_waypoints(_patrol_paths.get(normalized_spawn_id, []))


func set_patrol_path(spawn_id: String, waypoints: Array) -> void:
	var normalized_spawn_id: String = spawn_id.strip_edges()
	if normalized_spawn_id.is_empty():
		return
	var normalized_waypoints: Array = _coerce_patrol_waypoints(waypoints)
	if normalized_waypoints.is_empty():
		_patrol_paths.erase(normalized_spawn_id)
		return
	_patrol_paths[normalized_spawn_id] = normalized_waypoints


func get_enemy_team_configs() -> Dictionary:
	return _enemy_team_configs.duplicate(true)


func get_enemy_team_config(team_config_id: String) -> Dictionary:
	var normalized_config_id: String = team_config_id.strip_edges()
	if normalized_config_id.is_empty():
		return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _grid_size)
	if _enemy_team_configs.has(normalized_config_id):
		return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", _enemy_team_configs.get(normalized_config_id, {}), _grid_size)
	return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _grid_size)


func set_enemy_team_config(team_config_id: String, config: Dictionary) -> void:
	var normalized_config_id: String = team_config_id.strip_edges()
	if normalized_config_id.is_empty():
		return
	_enemy_team_configs[normalized_config_id] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", config, _grid_size)


func remove_enemy_team_config(team_config_id: String) -> void:
	var normalized_config_id: String = team_config_id.strip_edges()
	if normalized_config_id.is_empty() or normalized_config_id == "default":
		return
	_enemy_team_configs.erase(normalized_config_id)


func get_marker_position(marker_id: String, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty() or not _markers.has(normalized_marker_id):
		return fallback
	var marker_record: Dictionary = Dictionary(_markers.get(normalized_marker_id, {}))
	return TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_position", marker_record.get("position", fallback))


func has_marker(marker_id: String) -> bool:
	var normalized_marker_id: String = marker_id.strip_edges()
	return not normalized_marker_id.is_empty() and _markers.has(normalized_marker_id)


func set_marker_position(marker_id: String, world_position: Vector2) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		return
	var marker_record: Dictionary = get_marker_record(normalized_marker_id)
	if marker_record.is_empty():
		var inferred_type_id: String = normalized_marker_id.to_lower() if bool(TERRAIN_MARKER_CATALOG_SCRIPT.call("has_type", normalized_marker_id)) else String(TERRAIN_MARKER_CATALOG_SCRIPT.TYPE_CUSTOM)
		marker_record = TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, inferred_type_id, world_position)
	else:
		marker_record["position"] = world_position
	_markers[normalized_marker_id] = marker_record


func set_marker(marker_id: String, marker_type_id: String, world_position: Vector2, overrides: Dictionary = {}) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		return
	_markers[normalized_marker_id] = TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, marker_type_id, world_position, overrides)


func remove_marker(marker_id: String) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		return
	_markers.erase(normalized_marker_id)


func set_marker_display_name(marker_id: String, marker_name: String) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		return
	var marker_record: Dictionary = get_marker_record(normalized_marker_id)
	if marker_record.is_empty():
		marker_record = TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, normalized_marker_id, Vector2.ZERO)
	var sanitized_name: String = marker_name.strip_edges()
	if sanitized_name.is_empty():
		sanitized_name = String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_default_name", String(marker_record.get("marker_type_id", normalized_marker_id)), normalized_marker_id))
	marker_record["name"] = sanitized_name
	_markers[normalized_marker_id] = marker_record


func set_marker_type(marker_id: String, marker_type_id: String) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		return
	var existing_record: Dictionary = get_marker_record(normalized_marker_id)
	var preserved_name: String = String(existing_record.get("name", "")).strip_edges()
	var preserved_color: Variant = existing_record.get("color", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", marker_type_id))
	var position: Vector2 = get_marker_position(normalized_marker_id, Vector2.ZERO)
	var overrides: Dictionary = {
		"color": preserved_color,
	}
	if not preserved_name.is_empty():
		overrides["name"] = preserved_name
	_markers[normalized_marker_id] = TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, marker_type_id, position, overrides)


func set_marker_color(marker_id: String, marker_color: Color) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if normalized_marker_id.is_empty():
		return
	var marker_record: Dictionary = get_marker_record(normalized_marker_id)
	if marker_record.is_empty():
		marker_record = TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, normalized_marker_id, Vector2.ZERO)
	marker_record["color"] = TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_color", marker_color, marker_color)
	_markers[normalized_marker_id] = marker_record


func _grid_to_world(grid_position: Vector2i) -> Vector2:
	if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID:
		var plane: Vector2 = HEX_GRID_SCRIPT.axial_to_plane(Vector2(grid_position))
		return Vector2(
			_grid_origin.x + ((plane.x - plane.y) * _tile_half_width),
			_grid_origin.y + ((plane.x + plane.y) * _tile_half_height)
		)
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


static func _normalize_optional_id(value: String) -> String:
	return value.strip_edges().to_lower()


static func _coerce_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", 0.0)), float(value_dict.get("y", 0.0)))

	return Vector2.ZERO


static func _contains_nul_codepoint(text: String) -> bool:
	for index in range(text.length()):
		if text.unicode_at(index) == 0:
			return true
	return false


static func _coerce_marker_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result

	var marker_dict: Dictionary = value
	for marker_id_variant in marker_dict.keys():
		var marker_id: String = String(marker_id_variant).strip_edges()
		if marker_id.is_empty():
			continue
		result[marker_id] = _coerce_marker_record(marker_id, marker_dict.get(marker_id_variant, Vector2.ZERO))

	return result


func _serialize_markers() -> Dictionary:
	var serialized_markers: Dictionary = {}
	for marker_id_variant in _markers.keys():
		var marker_id: String = String(marker_id_variant).strip_edges()
		if marker_id.is_empty():
			continue
		var marker_record: Dictionary = _coerce_marker_record(marker_id, _markers.get(marker_id_variant, {}))
		var marker_position: Vector2 = TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_position", marker_record.get("position", Vector2.ZERO))
		serialized_markers[marker_id] = {
			"marker_type_id": String(marker_record.get("marker_type_id", marker_id)).strip_edges().to_lower(),
			"name": String(marker_record.get("name", marker_id)).strip_edges(),
			"placement_context": String(marker_record.get("placement_context", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_context", marker_id))).strip_edges().to_lower(),
			"symbol": String(marker_record.get("symbol", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", marker_id))).strip_edges().to_lower(),
			"color": TERRAIN_MARKER_CATALOG_SCRIPT.call("serialize_color", TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_color", marker_record.get("color", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", marker_id)), TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", marker_id))),
			"x": int(round(marker_position.x)),
			"y": int(round(marker_position.y)),
		}

	return serialized_markers


static func _coerce_marker_record(marker_id: String, value: Variant) -> Dictionary:
	var normalized_marker_id: String = marker_id.strip_edges()
	var fallback_type_id: String = normalized_marker_id.to_lower() if bool(TERRAIN_MARKER_CATALOG_SCRIPT.call("has_type", normalized_marker_id)) else String(TERRAIN_MARKER_CATALOG_SCRIPT.TYPE_CUSTOM)
	var fallback_color: Color = TERRAIN_MARKER_CATALOG_SCRIPT.call("get_color", fallback_type_id)
	var overrides: Dictionary = {}
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		var type_id: String = String(value_dict.get("marker_type_id", fallback_type_id)).strip_edges().to_lower()
		if type_id.is_empty():
			type_id = fallback_type_id
		var marker_name: String = String(value_dict.get("name", value_dict.get("label", ""))).strip_edges()
		if not marker_name.is_empty():
			overrides["name"] = marker_name
		var placement_context: String = String(value_dict.get("placement_context", value_dict.get("context", ""))).strip_edges().to_lower()
		if not placement_context.is_empty():
			overrides["placement_context"] = placement_context
		var symbol: String = String(value_dict.get("symbol", "")).strip_edges().to_lower()
		if not symbol.is_empty():
			overrides["symbol"] = symbol
		if value_dict.has("color"):
			overrides["color"] = TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_color", value_dict.get("color"), fallback_color)
		overrides["position"] = TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_position", value_dict)
		return TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, type_id, TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_position", value_dict), overrides)
	var position: Vector2 = TERRAIN_MARKER_CATALOG_SCRIPT.call("normalize_position", value)
	return TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_record", normalized_marker_id, fallback_type_id, position)


static func _coerce_patrol_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) != TYPE_DICTIONARY:
		return result
	var patrol_dict: Dictionary = value
	for spawn_id_variant in patrol_dict.keys():
		var spawn_id: String = String(spawn_id_variant).strip_edges()
		if spawn_id.is_empty():
			continue
		result[spawn_id] = _coerce_patrol_waypoints(patrol_dict.get(spawn_id_variant, []))
	return result


static func _coerce_patrol_waypoints(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for waypoint_variant in value:
		result.append(_coerce_vector2(waypoint_variant))
	return result


static func _coerce_enemy_team_config_dictionary(value: Variant, grid_size: Vector2i) -> Dictionary:
	var result: Dictionary = {}
	if typeof(value) == TYPE_DICTIONARY:
		var config_dict: Dictionary = Dictionary(value)
		for config_id_variant in config_dict.keys():
			var config_id: String = String(config_id_variant).strip_edges()
			if config_id.is_empty():
				continue
			result[config_id] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", config_dict.get(config_id_variant, {}), grid_size)
	if not result.has("default"):
		result["default"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", grid_size), grid_size)
	return result


func _serialize_patrol_paths() -> Dictionary:
	var serialized_paths: Dictionary = {}
	for spawn_id_variant in _patrol_paths.keys():
		var spawn_id: String = String(spawn_id_variant).strip_edges()
		if spawn_id.is_empty():
			continue
		var serialized_waypoints: Array = []
		for waypoint in _coerce_patrol_waypoints(_patrol_paths.get(spawn_id_variant, [])):
			serialized_waypoints.append(
				{
					"x": int(round(waypoint.x)),
					"y": int(round(waypoint.y)),
				}
			)
		serialized_paths[spawn_id] = serialized_waypoints
	return serialized_paths


func _serialize_enemy_team_configs() -> Dictionary:
	var serialized_configs: Dictionary = {}
	for config_id_variant in _enemy_team_configs.keys():
		var config_id: String = String(config_id_variant).strip_edges()
		if config_id.is_empty():
			continue
		serialized_configs[config_id] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", _enemy_team_configs.get(config_id_variant, {}), _grid_size)
	if not serialized_configs.has("default"):
		serialized_configs["default"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _grid_size), _grid_size)
	return serialized_configs
