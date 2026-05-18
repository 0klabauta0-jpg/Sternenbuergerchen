class_name TerrainMapRenderer
extends RefCounted

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TEXTURE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_texture_catalog.gd")
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)

var _tile_catalog = null


func _init(tile_catalog = null) -> void:
	_tile_catalog = tile_catalog


func set_tile_catalog(tile_catalog) -> void:
	_tile_catalog = tile_catalog


func _get_default_tile_texture() -> Texture2D:
	return TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_common_texture", "tile_default") as Texture2D


func _get_common_texture(texture_key: String) -> Texture2D:
	return TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_common_texture", texture_key) as Texture2D


func render_map(terrain_map_data, map_root: Node) -> Dictionary:
	var empty_result: Dictionary = {
		"tiles": {},
		"cliffs": {},
		"walls": {},
		"objects": {},
	}
	if terrain_map_data == null or map_root == null:
		return empty_result

	var tile_container := _ensure_container(map_root, "Terrain")
	var cliff_container := _ensure_container(map_root, "CliffContainer")
	var wall_container := _ensure_container(map_root, "WallContainer")
	var object_container := _ensure_container(map_root, "ObjectContainer")
	wall_container.y_sort_enabled = true
	wall_container.z_index = -13
	object_container.y_sort_enabled = true
	object_container.z_index = -12

	_clear_children(tile_container)
	_clear_children(cliff_container)
	_clear_children(wall_container)
	_clear_children(object_container)

	var tile_sprites_by_grid: Dictionary = {}
	for tile_data in terrain_map_data.call("get_tiles"):
		var tile_sprite := Sprite2D.new()
		tile_sprite.texture = resolve_tile_texture(tile_data)
		tile_sprite.centered = false
		tile_sprite.z_index = -20
		tile_sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
		tile_sprite.modulate = build_tile_modulate(tile_data)
		tile_container.add_child(tile_sprite)
		tile_sprites_by_grid[tile_data.grid_position] = tile_sprite

	var cliff_sprites_by_grid: Dictionary = _build_cliff_overlays(terrain_map_data, cliff_container)
	var wall_sprites_by_grid: Dictionary = _build_wall_overlays(terrain_map_data, wall_container)
	var object_sprites_by_grid: Dictionary = _build_object_overlays(terrain_map_data, object_container)
	return {
		"tiles": tile_sprites_by_grid,
		"cliffs": cliff_sprites_by_grid,
		"walls": wall_sprites_by_grid,
		"objects": object_sprites_by_grid,
	}


func resolve_tile_texture(tile_data) -> Texture2D:
	if tile_data == null:
		return _get_default_tile_texture()

	var tile_catalog = _get_or_load_tile_catalog()
	if tile_catalog == null:
		return _get_default_tile_texture()

	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	if type_id.is_empty():
		return _get_default_tile_texture()

	if tile_catalog.has_method("is_object_layer_type") and bool(tile_catalog.call("is_object_layer_type", type_id)):
		return _get_default_tile_texture()

	var type_texture: Texture2D = tile_catalog.get_texture(type_id)
	if type_texture != null:
		return type_texture

	return _get_default_tile_texture()


func build_tile_modulate(tile_data) -> Color:
	if tile_data == null:
		return Color(1.0, 1.0, 1.0, 1.0)

	var tile_color := Color(1.0, 1.0, 1.0, 1.0)
	var tile_catalog = _get_or_load_tile_catalog()
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	var has_catalog_texture: bool = false
	if not type_id.is_empty() and tile_catalog != null:
		var type_texture: Texture2D = tile_catalog.get_texture(type_id)
		has_catalog_texture = type_texture != null
		if tile_catalog.has_method("is_texture_cached"):
			has_catalog_texture = bool(tile_catalog.call("is_texture_cached", type_id))

	if not has_catalog_texture:
		match String(tile_data.surface_type):
			TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
				tile_color = Color(0.82, 0.82, 0.84, 1.0)
			TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
				tile_color = Color(1.0, 0.95, 0.72, 1.0)
			TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
				tile_color = Color(0.88, 0.78, 0.66, 1.0)

		var height_level: int = int(tile_data.height_level)
		if height_level == 1:
			tile_color = tile_color.lightened(0.08)
		elif height_level >= 2:
			tile_color = tile_color.lightened(0.16)

		if bool(tile_data.blocks_los):
			tile_color = tile_color.darkened(0.1)

		if not bool(tile_data.walkable):
			tile_color = tile_color.darkened(0.14)

	var gp: Vector2i = tile_data.grid_position
	if (gp.x + gp.y) % 2 == 0:
		tile_color = tile_color.darkened(0.08)

	return tile_color


func is_object_type(tile_data) -> bool:
	if tile_data == null:
		return false
	var object_type_id: String = get_tile_object_type_id(tile_data)
	if not object_type_id.is_empty():
		return true
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	return _is_structure_type_id(type_id)


func get_tile_object_type_id(tile_data) -> String:
	if tile_data == null:
		return ""

	var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	if not object_type_id.is_empty():
		return object_type_id

	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	var tile_catalog = _get_or_load_tile_catalog()
	if type_id.is_empty() or tile_catalog == null or not tile_catalog.has_method("is_object_layer_type"):
		return ""
	if bool(tile_catalog.call("is_object_layer_type", type_id)):
		return type_id
	return ""


func resolve_object_texture(tile_data) -> Texture2D:
	var object_type_id: String = get_tile_object_type_id(tile_data)
	if object_type_id.is_empty():
		return null
	var tile_catalog = _get_or_load_tile_catalog()
	if tile_catalog == null:
		return null
	return tile_catalog.get_texture(object_type_id)


func _get_or_load_tile_catalog():
	if _tile_catalog != null:
		return _tile_catalog
	_tile_catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	return _tile_catalog


func _ensure_container(map_root: Node, node_name: String) -> Node2D:
	var container := map_root.get_node_or_null(node_name) as Node2D
	if container != null:
		return container

	container = Node2D.new()
	container.name = node_name
	map_root.add_child(container)
	return container


func _clear_children(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()


func _build_cliff_overlays(terrain_map_data, cliff_container: Node2D) -> Dictionary:
	var cliff_sprites_by_grid: Dictionary = {}
	for tile_data in terrain_map_data.call("get_tiles"):
		if int(tile_data.height_level) <= 0:
			continue

		var overlays: Array[Sprite2D] = []
		var my_height: int = int(tile_data.height_level)
		var grid_pos: Vector2i = tile_data.grid_position
		var current_edge_type: String = String(tile_data.edge_type)
		var is_slope: bool = current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE

		var cliff_edge_dirs: Array[Vector2i] = []
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var neighbor = terrain_map_data.call("get_tile_at_grid", grid_pos + offset)
			var neighbor_height: int = int(neighbor.height_level) if neighbor != null else 0
			if neighbor_height < my_height:
				cliff_edge_dirs.append(offset)
		if cliff_edge_dirs.is_empty() or current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
			continue

		var corner_map: Array = [
			[Vector2i(1, 0), Vector2i(0, 1), _get_common_texture("cliff_corner_ne")],
			[Vector2i(1, 0), Vector2i(0, -1), _get_common_texture("cliff_corner_nw")],
			[Vector2i(-1, 0), Vector2i(0, 1), _get_common_texture("cliff_corner_se")],
			[Vector2i(-1, 0), Vector2i(0, -1), _get_common_texture("cliff_corner_sw")],
		]
		var edges_consumed_by_corners: Array[Vector2i] = []

		if not is_slope:
			for corner_entry in corner_map:
				var dir_a: Vector2i = corner_entry[0]
				var dir_b: Vector2i = corner_entry[1]
				var corner_texture: Texture2D = corner_entry[2]
				if cliff_edge_dirs.has(dir_a) and cliff_edge_dirs.has(dir_b):
					var corner_sprite := Sprite2D.new()
					corner_sprite.texture = corner_texture
					corner_sprite.centered = false
					corner_sprite.z_index = -14
					var corner_anchor_grid: Vector2i = grid_pos + dir_a + dir_b
					corner_sprite.position = _get_edge_anchor_world_position(terrain_map_data, corner_anchor_grid, tile_data.world_position) - KENNEY_DIAMOND_CENTER
					cliff_container.add_child(corner_sprite)
					_register_cliff_overlay(cliff_sprites_by_grid, corner_anchor_grid, corner_sprite)
					if not edges_consumed_by_corners.has(dir_a):
						edges_consumed_by_corners.append(dir_a)
					if not edges_consumed_by_corners.has(dir_b):
						edges_consumed_by_corners.append(dir_b)

		var edge_texture_map: Dictionary
		if is_slope:
			edge_texture_map = {
				Vector2i(1, 0): _get_common_texture("slope_se"),
				Vector2i(-1, 0): _get_common_texture("slope_nw"),
				Vector2i(0, 1): _get_common_texture("slope_sw"),
				Vector2i(0, -1): _get_common_texture("slope_ne"),
			}
		else:
			edge_texture_map = {
				Vector2i(1, 0): _get_common_texture("cliff_se"),
				Vector2i(-1, 0): _get_common_texture("cliff_nw"),
				Vector2i(0, 1): _get_common_texture("cliff_sw"),
				Vector2i(0, -1): _get_common_texture("cliff_ne"),
			}

		for edge_dir in cliff_edge_dirs:
			if edges_consumed_by_corners.has(edge_dir):
				continue
			var edge_sprite := Sprite2D.new()
			edge_sprite.texture = edge_texture_map[edge_dir]
			edge_sprite.centered = false
			edge_sprite.z_index = -15
			var edge_anchor_grid: Vector2i = grid_pos + edge_dir
			edge_sprite.position = _get_edge_anchor_world_position(terrain_map_data, edge_anchor_grid, tile_data.world_position) - KENNEY_DIAMOND_CENTER
			cliff_container.add_child(edge_sprite)
			_register_cliff_overlay(cliff_sprites_by_grid, edge_anchor_grid, edge_sprite)

	return cliff_sprites_by_grid


func _register_cliff_overlay(cliff_sprites_by_grid: Dictionary, anchor_grid: Vector2i, overlay: Sprite2D) -> void:
	if overlay == null:
		return
	var overlays: Array = Array(cliff_sprites_by_grid.get(anchor_grid, []))
	overlays.append(overlay)
	cliff_sprites_by_grid[anchor_grid] = overlays


func _get_edge_anchor_world_position(terrain_map_data, anchor_grid: Vector2i, fallback_world_position: Vector2) -> Vector2:
	if terrain_map_data == null:
		return fallback_world_position
	var anchor_tile = terrain_map_data.call("get_tile_at_grid", anchor_grid)
	if anchor_tile != null:
		return Vector2(anchor_tile.world_position)
	if terrain_map_data.has_method("_grid_to_world"):
		return Vector2(terrain_map_data.call("_grid_to_world", anchor_grid))
	return fallback_world_position


func _build_wall_overlays(terrain_map_data, wall_container: Node2D) -> Dictionary:
	var wall_sprites_by_grid: Dictionary = {}
	for tile_data in terrain_map_data.call("get_tiles"):
		var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
		if not _is_structure_type_id(type_id):
			continue

		var texture: Texture2D = null
		var pos_offset := Vector2.ZERO

		match type_id:
			"wall_straight_se":
				texture = _get_common_texture("wall_ne")
			"wall_straight_sw":
				texture = _get_common_texture("wall_se")
			"wall_straight_ne":
				texture = _get_common_texture("wall_nw")
			"wall_straight_nw":
				texture = _get_common_texture("wall_sw")
			"wall_corner_se":
				texture = _get_common_texture("wall_corner_nw")
			"wall_corner_sw":
				texture = _get_common_texture("wall_corner_ne")
			"wall_corner_ne":
				texture = _get_common_texture("wall_corner_sw")
			"wall_corner_nw":
				texture = _get_common_texture("wall_corner_se")
			"cliff_straight_se":
				texture = _get_common_texture("cliff_se")
				pos_offset = Vector2(33, 24)
			"cliff_straight_sw":
				texture = _get_common_texture("cliff_sw")
				pos_offset = Vector2(33, 56)
			"cliff_straight_ne":
				texture = _get_common_texture("cliff_ne")
				pos_offset = Vector2(-31, 23)
			"cliff_straight_nw":
				texture = _get_common_texture("cliff_nw")
				pos_offset = Vector2(-32, 56)
			"cliff_corner_se":
				texture = _get_common_texture("cliff_corner_ne")
				pos_offset = Vector2(-64, 40)
			"cliff_corner_sw":
				texture = _get_common_texture("cliff_corner_se")
				pos_offset = Vector2(1, 7)
			"cliff_corner_ne":
				texture = _get_common_texture("cliff_corner_nw")
				pos_offset = Vector2(0, 73)
			"cliff_corner_nw":
				texture = _get_common_texture("cliff_corner_sw")
				pos_offset = Vector2(65, 40)
			"slope_se":
				texture = _get_common_texture("ramp_se")
				pos_offset = Vector2(0, 32)
			"slope_sw":
				texture = _get_common_texture("ramp_sw")
				pos_offset = Vector2(0, 32)
			"slope_ne":
				texture = _get_common_texture("ramp_ne")
				pos_offset = Vector2(0, 32)
			"slope_nw":
				texture = _get_common_texture("ramp_nw")
				pos_offset = Vector2(0, 32)
			"rock_small":
				texture = _get_common_texture("rock_small")
			"rock_large":
				texture = _get_common_texture("rock_large")
			_:
				if type_id.begins_with("station_wall"):
					texture = _get_common_texture("wall_sw")
				else:
					continue

		if texture == null:
			continue

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.z_index = 0
		var object_scale: float = _get_tile_object_scale(tile_data)
		sprite.scale = Vector2.ONE * object_scale
		sprite.position = tile_data.world_position - (KENNEY_DIAMOND_CENTER * object_scale) + (pos_offset * object_scale)
		wall_container.add_child(sprite)
		wall_sprites_by_grid[tile_data.grid_position] = [sprite]

	return wall_sprites_by_grid


func _build_object_overlays(terrain_map_data, object_container: Node2D) -> Dictionary:
	var object_sprites_by_grid: Dictionary = {}
	for tile_data in terrain_map_data.call("get_tiles"):
		var texture: Texture2D = resolve_object_texture(tile_data)
		if texture == null:
			continue

		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.centered = false
		sprite.z_index = 0
		var object_scale: float = _get_tile_object_scale(tile_data)
		sprite.scale = Vector2.ONE * object_scale
		sprite.position = tile_data.world_position - (KENNEY_DIAMOND_CENTER * object_scale)
		object_container.add_child(sprite)
		object_sprites_by_grid[tile_data.grid_position] = [sprite]

	return object_sprites_by_grid


func _is_structure_type_id(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return false
	var tile_catalog = _get_or_load_tile_catalog()
	if tile_catalog != null and tile_catalog.has_method("is_structure_layer_type") and bool(tile_catalog.call("is_structure_layer_type", normalized_type_id)):
		return true
	return normalized_type_id.begins_with("wall_") or normalized_type_id.begins_with("cliff_") or normalized_type_id.begins_with("slope_") or normalized_type_id.begins_with("rock_")


func _get_tile_object_scale(tile_data) -> float:
	if tile_data == null:
		return 1.0
	return clampf(float(tile_data.object_scale), 0.25, 2.5)
