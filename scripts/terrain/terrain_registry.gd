class_name TerrainRegistry
extends Node

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")
const COVER_RADIUS_BUCKET_WORLD_SIZE: float = 256.0

var _tiles: Dictionary = {}
var _tile_id_lookup: Dictionary = {}
var _sorted_tiles_cache: Array = []
var _sorted_tiles_cache_dirty: bool = true
var _revision: int = 0
var _dirty_grid_lookup: Dictionary = {}
var _runtime_tile_overrides: Dictionary = {}
var _grid_origin_world: Vector2 = Vector2.ZERO
var _half_tile_width: float = 64.0
var _half_tile_height: float = 32.0
var _grid_topology: String = "square8"
var _cover_radius_index_dirty: bool = true
var _cover_radius_index_tiles: Array = []
var _cover_radius_index_buckets: Dictionary = {}
var _cover_radius_index_has_non_finite_positions: bool = false


func configure_iso_grid(grid_origin_world: Vector2, half_tile_width: float, half_tile_height: float, grid_topology: String = "square8") -> void:
	if grid_topology != "square8" and grid_topology != HEX_GRID_SCRIPT.TOPOLOGY_ID:
		push_warning("TerrainRegistry rejects unsupported grid_topology '%s'." % grid_topology)
		return
	var topology_changed: bool = _grid_topology != grid_topology
	_grid_topology = grid_topology
	_grid_origin_world = grid_origin_world
	_half_tile_width = maxf(half_tile_width, 0.001)
	_half_tile_height = maxf(half_tile_height, 0.001)
	if topology_changed:
		_bump_revision()


func get_grid_topology() -> String:
	return _grid_topology


func are_grid_neighbors(a: Vector2i, b: Vector2i) -> bool:
	if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID:
		return HEX_GRID_SCRIPT.are_neighbors(a, b)
	var delta: Vector2i = b - a
	return delta != Vector2i.ZERO and absi(delta.x) <= 1 and absi(delta.y) <= 1


func get_grid_line(from_grid: Vector2i, to_grid: Vector2i) -> Array[Vector2i]:
	if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID:
		return HEX_GRID_SCRIPT.line(from_grid, to_grid)
	var result: Array[Vector2i] = []
	var delta: Vector2i = to_grid - from_grid
	var steps: int = maxi(absi(delta.x), absi(delta.y))
	if steps == 0:
		result.append(from_grid)
		return result
	for index in range(steps + 1):
		var point: Vector2i = Vector2i(Vector2(from_grid).lerp(Vector2(to_grid), float(index) / float(steps)).round())
		if result.is_empty() or result[-1] != point:
			result.append(point)
	return result


func get_movement_distance(from_world: Vector2, to_world: Vector2) -> float:
	if _grid_topology != HEX_GRID_SCRIPT.TOPOLOGY_ID:
		return from_world.distance_to(to_world)
	var from_plane: Vector2 = HEX_GRID_SCRIPT.axial_to_plane(world_to_grid_float(from_world))
	var to_plane: Vector2 = HEX_GRID_SCRIPT.axial_to_plane(world_to_grid_float(to_world))
	return from_plane.distance_to(to_plane) * Vector2(_half_tile_width, _half_tile_height).length()


func clear_tiles() -> void:
	_tiles.clear()
	_tile_id_lookup.clear()
	_sorted_tiles_cache.clear()
	_sorted_tiles_cache_dirty = true
	_dirty_grid_lookup.clear()
	_runtime_tile_overrides.clear()
	_cover_radius_index_tiles.clear()
	_cover_radius_index_buckets.clear()
	_cover_radius_index_dirty = true
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
	_cover_radius_index_dirty = true
	_sorted_tiles_cache_dirty = true
	_mark_dirty_grid(grid_position)
	_bump_revision()


func notify_tile_data_changed(changed_grids: Array = []) -> void:
	_rebuild_tile_id_lookup()
	_cover_radius_index_dirty = true
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


func set_runtime_tile_overrides(overrides: Array) -> void:
	var next_overrides: Dictionary = {}
	for override_variant in overrides:
		if typeof(override_variant) != TYPE_DICTIONARY:
			continue
		var sanitized: Dictionary = _sanitize_runtime_tile_override(Dictionary(override_variant))
		if sanitized.is_empty():
			continue
		next_overrides[Vector2i(sanitized.get("grid_position", Vector2i.ZERO))] = sanitized

	for grid_variant in _runtime_tile_overrides.keys():
		_mark_dirty_grid(Vector2i(grid_variant))
	for grid_variant in next_overrides.keys():
		_mark_dirty_grid(Vector2i(grid_variant))
	_runtime_tile_overrides = next_overrides
	_bump_revision()


func clear_runtime_tile_overrides() -> void:
	if _runtime_tile_overrides.is_empty():
		return
	for grid_variant in _runtime_tile_overrides.keys():
		_mark_dirty_grid(Vector2i(grid_variant))
	_runtime_tile_overrides.clear()
	_bump_revision()


func has_runtime_tile_override(grid_pos: Vector2i) -> bool:
	return _runtime_tile_overrides.has(grid_pos)


func get_runtime_tile_override(grid_pos: Vector2i) -> Dictionary:
	if not _runtime_tile_overrides.has(grid_pos):
		return {}
	return Dictionary(_runtime_tile_overrides.get(grid_pos, {})).duplicate(true)


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


func get_tile_count() -> int:
	return _tiles.size()


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

	var override: Dictionary = _runtime_tile_overrides.get(grid_pos, {})
	if override.has("walkable_override"):
		return bool(override.get("walkable_override", false))
	return bool(tile_data.walkable)


func blocks_los_at_grid(grid_pos: Vector2i) -> bool:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return false

	var override: Dictionary = _runtime_tile_overrides.get(grid_pos, {})
	if override.has("blocks_los_override"):
		return bool(override.get("blocks_los_override", false))
	return bool(tile_data.blocks_los)


func get_object_height_at_grid(grid_pos: Vector2i) -> int:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return 0

	var override: Dictionary = _runtime_tile_overrides.get(grid_pos, {})
	if override.has("object_height_override"):
		return int(override.get("object_height_override", 0))
	return int(tile_data.object_height)


func get_nearest_walkable_grid(world_pos: Vector2) -> Variant:
	var nearest_grid: Variant = null
	var nearest_distance: float = INF
	for tile_data in _tiles.values():
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		if not is_walkable(grid_position):
			continue
		var distance_to_tile: float = world_pos.distance_squared_to(tile_data.world_position)
		if not _is_nearest_candidate_better(distance_to_tile, grid_position, nearest_distance, nearest_grid):
			continue

		nearest_distance = distance_to_tile
		nearest_grid = grid_position

	return nearest_grid


func resolve_walkable_target(world_pos: Vector2) -> Dictionary:
	var target_grid: Vector2i = world_to_grid(world_pos)
	var target_tile = get_tile_at_grid(target_grid)
	if target_tile != null and is_walkable(target_grid):
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

	var override: Dictionary = _runtime_tile_overrides.get(grid_pos, {})
	if override.has("cover_value_override"):
		return int(override.get("cover_value_override", 0))
	return int(tile_data.cover_value)


func get_cover_at_world(world_pos: Vector2) -> int:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return 0

	return get_cover_at(Vector2i(tile_data.grid_position))


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
	for tile_data in _get_cover_radius_candidates(world_center, radius):
		if world_center.distance_squared_to(tile_data.world_position) > radius_sq:
			continue
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		if not is_walkable(grid_position):
			continue
		if get_cover_at(grid_position) <= 0:
			continue
		result.append(tile_data)
	return result


func _get_cover_radius_candidates(world_center: Vector2, radius: float) -> Array:
	if _cover_radius_index_dirty:
		_rebuild_cover_radius_index()
	# Preserve the previous floating-point filter for non-finite authored inputs.
	if not world_center.is_finite() or not is_finite(radius) or _cover_radius_index_has_non_finite_positions:
		return _tiles.values()
	var extent: float = absf(radius)
	# Broad queries are cheaper as one ordered traversal than many empty bucket
	# lookups. This also avoids unbounded loops for extremely large radii.
	if extent > COVER_RADIUS_BUCKET_WORLD_SIZE * float(maxi(_cover_radius_index_buckets.size(), 1)):
		return _tiles.values()
	var minimum: Vector2i = _cover_radius_bucket(world_center - Vector2(extent, extent))
	var maximum: Vector2i = _cover_radius_bucket(world_center + Vector2(extent, extent))
	var bucket_count: int = (maximum.x - minimum.x + 1) * (maximum.y - minimum.y + 1)
	if bucket_count > maxi(_cover_radius_index_buckets.size() * 2, 1):
		return _tiles.values()
	var indices: Array = []
	for bucket_y in range(minimum.y, maximum.y + 1):
		for bucket_x in range(minimum.x, maximum.x + 1):
			indices.append_array(Array(_cover_radius_index_buckets.get(Vector2i(bucket_x, bucket_y), [])))
	# Bucket order must never change the old dictionary-insertion tie breaker.
	indices.sort()
	var candidates: Array = []
	for index in indices:
		candidates.append(_cover_radius_index_tiles[int(index)])
	return candidates


func _rebuild_cover_radius_index() -> void:
	_cover_radius_index_tiles = _tiles.values()
	_cover_radius_index_buckets.clear()
	_cover_radius_index_has_non_finite_positions = false
	for index in range(_cover_radius_index_tiles.size()):
		var tile_data = _cover_radius_index_tiles[index]
		var position: Vector2 = tile_data.world_position
		if not position.is_finite():
			_cover_radius_index_has_non_finite_positions = true
			continue
		var bucket: Vector2i = _cover_radius_bucket(position)
		var indices: Array = Array(_cover_radius_index_buckets.get(bucket, []))
		indices.append(index)
		_cover_radius_index_buckets[bucket] = indices
	_cover_radius_index_dirty = false


func _cover_radius_bucket(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / COVER_RADIUS_BUCKET_WORLD_SIZE), floori(position.y / COVER_RADIUS_BUCKET_WORLD_SIZE))


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var grid_position: Vector2 = world_to_grid_float(world_pos)
	if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID:
		return HEX_GRID_SCRIPT.round_axial(grid_position)
	return Vector2i(roundi(grid_position.x), roundi(grid_position.y))


func world_to_grid_float(world_pos: Vector2) -> Vector2:
	var delta: Vector2 = world_pos - _grid_origin_world
	var grid_x: float = ((delta.y / _half_tile_height) + (delta.x / _half_tile_width)) * 0.5
	var grid_y: float = ((delta.y / _half_tile_height) - (delta.x / _half_tile_width)) * 0.5
	if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID:
		return HEX_GRID_SCRIPT.plane_to_axial(Vector2(grid_x, grid_y))
	return Vector2(grid_x, grid_y)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID:
		var plane: Vector2 = HEX_GRID_SCRIPT.axial_to_plane(Vector2(grid_pos))
		return Vector2(
			_grid_origin_world.x + ((plane.x - plane.y) * _half_tile_width),
			_grid_origin_world.y + ((plane.x + plane.y) * _half_tile_height)
		)
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


func _sanitize_runtime_tile_override(data: Dictionary) -> Dictionary:
	var grid_position: Variant = data.get("grid_position", null)
	if typeof(grid_position) != TYPE_VECTOR2I and typeof(grid_position) != TYPE_VECTOR2:
		return {}
	var normalized_grid: Vector2i = Vector2i(grid_position)
	if not _tiles.has(normalized_grid):
		return {}

	var sanitized: Dictionary = {
		"grid_position": normalized_grid,
	}
	if data.has("walkable_override"):
		sanitized["walkable_override"] = bool(data.get("walkable_override", false))
	if data.has("blocks_los_override"):
		sanitized["blocks_los_override"] = bool(data.get("blocks_los_override", false))
	if data.has("object_height_override"):
		sanitized["object_height_override"] = clampi(int(data.get("object_height_override", 0)), 0, 3)
	if data.has("cover_value_override"):
		sanitized["cover_value_override"] = clampi(int(data.get("cover_value_override", 0)), 0, 100)
	sanitized["source_interaction_id"] = String(data.get("source_interaction_id", "")).strip_edges()
	sanitized["source_runtime_visual_state"] = String(data.get("source_runtime_visual_state", "")).strip_edges().to_lower()
	return sanitized


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
