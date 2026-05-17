class_name TerrainRegistry
extends Node

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _tiles: Dictionary = {}
var _tile_id_lookup: Dictionary = {}
var _sorted_tiles_cache: Array = []
var _sorted_tiles_cache_dirty: bool = true
var _revision: int = 0
var _dirty_grid_lookup: Dictionary = {}
var _grid_origin_world: Vector2 = Vector2.ZERO
var _half_tile_width: float = 64.0
var _half_tile_height: float = 32.0


func configure_iso_grid(grid_origin_world: Vector2, half_tile_width: float, half_tile_height: float) -> void:
	_grid_origin_world = grid_origin_world
	_half_tile_width = maxf(half_tile_width, 0.001)
	_half_tile_height = maxf(half_tile_height, 0.001)


func clear_tiles() -> void:
	_tiles.clear()
	_tile_id_lookup.clear()
	_sorted_tiles_cache.clear()
	_sorted_tiles_cache_dirty = true
	_dirty_grid_lookup.clear()
	_bump_revision()


func register_tile(tile_data) -> void:
	if tile_data == null or not tile_data.has_method("is_valid") or not bool(tile_data.call("is_valid")):
		push_warning("TerrainRegistry.register_tile expects a valid TerrainTileData.")
		return

	var grid_position: Vector2i = Vector2i(tile_data.grid_position)
	if _tiles.has(grid_position):
		_remove_tile_id_index(_tiles[grid_position])
	_tiles[grid_position] = tile_data
	_index_tile_id(tile_data)
	_sorted_tiles_cache_dirty = true
	_mark_dirty_grid(grid_position)
	_bump_revision()


func notify_tile_data_changed(changed_grids: Array = []) -> void:
	_rebuild_tile_id_lookup()
	_sorted_tiles_cache_dirty = true
	if changed_grids.is_empty():
		for grid_variant in _tiles.keys():
			_mark_dirty_grid(Vector2i(grid_variant))
	else:
		for grid_variant in changed_grids:
			if typeof(grid_variant) == TYPE_VECTOR2I:
				_mark_dirty_grid(Vector2i(grid_variant))
			elif typeof(grid_variant) == TYPE_VECTOR2:
				_mark_dirty_grid(Vector2i(roundi(Vector2(grid_variant).x), roundi(Vector2(grid_variant).y)))
	_bump_revision()


func get_revision() -> int:
	return _revision


func get_dirty_grid_positions() -> Array:
	var grids: Array = _dirty_grid_lookup.keys()
	grids.sort_custom(_is_grid_before)
	return grids


func clear_dirty_grid_positions() -> void:
	_dirty_grid_lookup.clear()


func get_tile_at_grid(grid_pos: Vector2i):
	if not _tiles.has(grid_pos):
		return null

	return _tiles[grid_pos]


func get_tile_by_id(tile_id: String):
	var normalized_id: String = _normalize_tile_id(tile_id)
	if normalized_id.is_empty():
		return null

	var indexed_tile = _tile_id_lookup.get(normalized_id, null)
	if indexed_tile != null:
		if _normalize_tile_id(String(indexed_tile.tile_id)) == normalized_id:
			return indexed_tile
		_tile_id_lookup.erase(normalized_id)

	for tile_data in _tiles.values():
		if _normalize_tile_id(String(tile_data.tile_id)) == normalized_id:
			_tile_id_lookup[normalized_id] = tile_data
			return tile_data
	return null


func get_tile_id_at_grid(grid_pos: Vector2i) -> String:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return ""
	return String(tile_data.tile_id)


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


func get_sorted_tiles() -> Array:
	if _sorted_tiles_cache_dirty:
		_sorted_tiles_cache = _tiles.values()
		_sorted_tiles_cache.sort_custom(func(a, b) -> bool:
			return _is_grid_before(Vector2i(a.grid_position), Vector2i(b.grid_position))
		)
		_sorted_tiles_cache_dirty = false
	return _sorted_tiles_cache.duplicate()


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
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		if not _is_nearest_candidate_better(distance_to_tile, grid_position, nearest_distance, nearest_grid):
			continue

		nearest_distance = distance_to_tile
		nearest_grid = grid_position

	return nearest_grid


func resolve_walkable_target(world_pos: Vector2) -> Dictionary:
	var target_grid: Vector2i = world_to_grid(world_pos)
	var target_tile = get_tile_at_grid(target_grid)
	if target_tile != null and bool(target_tile.walkable):
		return {
			"original_position": world_pos,
			"original_grid": target_grid,
			"target_walkable": true,
			"replacement_grid": target_grid,
			"replacement_position": world_pos,
			"blocked_grid": null,
			"blocked_position": null,
			"blocker_reason": "",
		}
	var replacement_grid: Variant = get_nearest_walkable_grid(world_pos)
	if typeof(replacement_grid) != TYPE_VECTOR2I:
		return {
			"original_position": world_pos,
			"original_grid": target_grid,
			"target_walkable": false,
			"replacement_grid": null,
			"replacement_position": world_pos,
			"blocked_grid": target_grid,
			"blocked_position": target_tile.world_position if target_tile != null else world_pos,
			"blocker_reason": "no_walkable_replacement",
		}
	return {
		"original_position": world_pos,
		"original_grid": target_grid,
		"target_walkable": false,
		"replacement_grid": replacement_grid,
		"replacement_position": grid_to_world(replacement_grid),
		"blocked_grid": target_grid,
		"blocked_position": target_tile.world_position if target_tile != null else world_pos,
		"blocker_reason": "target_not_walkable" if target_tile != null else "target_tile_missing",
	}


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
	var grid_position: Vector2 = world_to_grid_float(world_pos)
	return Vector2i(roundi(grid_position.x), roundi(grid_position.y))


func world_to_grid_float(world_pos: Vector2) -> Vector2:
	var delta: Vector2 = world_pos - _grid_origin_world
	var grid_x: float = ((delta.y / _half_tile_height) + (delta.x / _half_tile_width)) * 0.5
	var grid_y: float = ((delta.y / _half_tile_height) - (delta.x / _half_tile_width)) * 0.5
	return Vector2(grid_x, grid_y)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		_grid_origin_world.x + (float(grid_pos.x - grid_pos.y) * _half_tile_width),
		_grid_origin_world.y + (float(grid_pos.x + grid_pos.y) * _half_tile_height)
	)


func _index_tile_id(tile_data) -> void:
	if tile_data == null:
		return
	var normalized_id: String = _normalize_tile_id(String(tile_data.tile_id))
	if normalized_id.is_empty():
		return
	_tile_id_lookup[normalized_id] = tile_data


func _remove_tile_id_index(tile_data) -> void:
	if tile_data == null:
		return
	var normalized_id: String = _normalize_tile_id(String(tile_data.tile_id))
	if normalized_id.is_empty():
		return
	if _tile_id_lookup.get(normalized_id, null) == tile_data:
		_tile_id_lookup.erase(normalized_id)


func _rebuild_tile_id_lookup() -> void:
	_tile_id_lookup.clear()
	for tile_data in _tiles.values():
		_index_tile_id(tile_data)


func _bump_revision() -> void:
	_revision += 1


func _mark_dirty_grid(grid_position: Vector2i) -> void:
	_dirty_grid_lookup[grid_position] = true


func _normalize_tile_id(value: String) -> String:
	return value.strip_edges()


func _is_grid_before(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y < b.y
	return a.x < b.x


func _is_nearest_candidate_better(distance_to_tile: float, grid_position: Vector2i, nearest_distance: float, nearest_grid: Variant) -> bool:
	if typeof(nearest_grid) != TYPE_VECTOR2I:
		return true
	if distance_to_tile < nearest_distance - 0.001:
		return true
	if absf(distance_to_tile - nearest_distance) <= 0.001:
		return _is_grid_before(grid_position, Vector2i(nearest_grid))
	return false
