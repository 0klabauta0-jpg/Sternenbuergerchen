class_name TerrainRegistry
extends Node

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _tiles: Dictionary = {}
var _grid_origin_world: Vector2 = Vector2.ZERO
var _half_tile_width: float = 64.0
var _half_tile_height: float = 32.0


func configure_iso_grid(grid_origin_world: Vector2, half_tile_width: float, half_tile_height: float) -> void:
	_grid_origin_world = grid_origin_world
	_half_tile_width = maxf(half_tile_width, 0.001)
	_half_tile_height = maxf(half_tile_height, 0.001)


func clear_tiles() -> void:
	_tiles.clear()


func register_tile(tile_data) -> void:
	if tile_data == null or not tile_data.has_method("is_valid") or not bool(tile_data.call("is_valid")):
		push_warning("TerrainRegistry.register_tile expects a valid TerrainTileData.")
		return

	_tiles[tile_data.grid_position] = tile_data


func get_tile_at_grid(grid_pos: Vector2i):
	if not _tiles.has(grid_pos):
		return null

	return _tiles[grid_pos]


func get_tile_at_world(world_pos: Vector2):
	var exact_grid: Vector2i = world_to_grid(world_pos)
	if _tiles.has(exact_grid):
		return _tiles[exact_grid]

	var nearest_tile = null
	var nearest_distance: float = INF
	for tile_data in _tiles.values():
		var distance_to_tile: float = world_pos.distance_squared_to(tile_data.world_position)
		if distance_to_tile >= nearest_distance:
			continue

		nearest_distance = distance_to_tile
		nearest_tile = tile_data

	return nearest_tile


func get_all_tiles() -> Array:
	return _tiles.values()


func is_walkable(grid_pos: Vector2i) -> bool:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return false

	return bool(tile_data.walkable)


func get_nearest_walkable_grid(world_pos: Vector2) -> Variant:
	var nearest_grid: Variant = null
	var nearest_distance: float = INF
	for tile_data in _tiles.values():
		if not bool(tile_data.walkable):
			continue
		var distance_to_tile: float = world_pos.distance_squared_to(tile_data.world_position)
		if distance_to_tile >= nearest_distance:
			continue

		nearest_distance = distance_to_tile
		nearest_grid = tile_data.grid_position

	return nearest_grid


func get_cover_at(grid_pos: Vector2i) -> int:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return 0

	return int(tile_data.cover_value)


func get_cover_at_world(world_pos: Vector2) -> int:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return 0

	return int(tile_data.cover_value)


func get_height_at(grid_pos: Vector2i) -> int:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return 0

	return int(tile_data.height_level)


func get_height_at_world(world_pos: Vector2) -> int:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return 0

	return int(tile_data.height_level)


func get_surface_type_at_world(world_pos: Vector2) -> String:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE

	return String(tile_data.surface_type)


func get_surface_speed_factor_at_world(world_pos: Vector2) -> float:
	return TERRAIN_TILE_DATA_SCRIPT.get_surface_speed_factor(get_surface_type_at_world(world_pos))


func get_walkable_cover_tiles_in_radius(world_center: Vector2, radius: float) -> Array:
	var radius_sq: float = radius * radius
	var result: Array = []
	for tile_data in _tiles.values():
		if not bool(tile_data.walkable):
			continue
		if int(tile_data.cover_value) <= 0:
			continue
		if world_center.distance_squared_to(tile_data.world_position) > radius_sq:
			continue
		result.append(tile_data)
	return result


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var delta: Vector2 = world_pos - _grid_origin_world
	var grid_x: float = ((delta.y / _half_tile_height) + (delta.x / _half_tile_width)) * 0.5
	var grid_y: float = ((delta.y / _half_tile_height) - (delta.x / _half_tile_width)) * 0.5
	return Vector2i(roundi(grid_x), roundi(grid_y))


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		_grid_origin_world.x + (float(grid_pos.x - grid_pos.y) * _half_tile_width),
		_grid_origin_world.y + (float(grid_pos.x + grid_pos.y) * _half_tile_height)
	)
