class_name TerrainRegistry
extends Node

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP_FLOOR_SLOT_SCRIPT: GDScript = preload("res://scripts/terrain/map_floor_slot.gd")

var _tiles: Dictionary = {}
var _floor_tiles: Dictionary = {}
var _grid_origin_world: Vector2 = Vector2.ZERO
var _half_tile_width: float = 64.0
var _half_tile_height: float = 32.0


func configure_iso_grid(grid_origin_world: Vector2, half_tile_width: float, half_tile_height: float) -> void:
	_grid_origin_world = grid_origin_world
	_half_tile_width = maxf(half_tile_width, 0.001)
	_half_tile_height = maxf(half_tile_height, 0.001)


func clear_tiles() -> void:
	_tiles.clear()
	_floor_tiles.clear()


func register_tile(tile_data) -> void:
	if tile_data == null or not tile_data.has_method("is_valid") or not bool(tile_data.call("is_valid")):
		push_warning("TerrainRegistry.register_tile expects a valid TerrainTileData.")
		return

	var grid_position: Vector2i = Vector2i(tile_data.grid_position)
	var floor_index: int = _coerce_floor_index(tile_data.floor_index)
	tile_data.floor_index = floor_index
	_floor_tiles[_build_floor_key(grid_position, floor_index)] = tile_data
	if floor_index == TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX:
		_tiles[grid_position] = tile_data


func get_tile_at_grid(grid_pos: Vector2i):
	if not _tiles.has(grid_pos):
		return null

	return _tiles[grid_pos]


func get_tile_at_grid_floor(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX):
	var key: String = _build_floor_key(grid_pos, _coerce_floor_index(floor_index))
	if not _floor_tiles.has(key):
		return null
	return _floor_tiles[key]


func has_floor_slot(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> bool:
	return get_tile_at_grid_floor(grid_pos, floor_index) != null


func get_floor_slot_at_grid(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX):
	return MAP_FLOOR_SLOT_SCRIPT.call("from_tile_data", get_tile_at_grid_floor(grid_pos, floor_index))


func get_floor_slots_at_grid(grid_pos: Vector2i) -> Array:
	var result: Array = []
	for tile_data in _floor_tiles.values():
		if tile_data == null:
			continue
		if Vector2i(tile_data.grid_position) != grid_pos:
			continue
		var slot = MAP_FLOOR_SLOT_SCRIPT.call("from_tile_data", tile_data)
		if slot != null:
			result.append(slot)
	result.sort_custom(func(a, b) -> bool:
		return int(a.floor_index) < int(b.floor_index)
	)
	return result


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


func get_all_floor_tiles() -> Array:
	var result: Array = _floor_tiles.values()
	result.sort_custom(func(a, b) -> bool:
		var grid_a: Vector2i = Vector2i(a.grid_position)
		var grid_b: Vector2i = Vector2i(b.grid_position)
		if grid_a.x == grid_b.x:
			if grid_a.y == grid_b.y:
				return int(a.floor_index) < int(b.floor_index)
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	return result


func is_walkable(grid_pos: Vector2i) -> bool:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return false

	return bool(tile_data.walkable)


func is_walkable_floor(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> bool:
	var tile_data = get_tile_at_grid_floor(grid_pos, floor_index)
	if tile_data == null:
		return false
	return bool(tile_data.walkable)


func get_nearest_walkable_grid(world_pos: Vector2) -> Variant:
	var nearest_grid: Variant = null
	var nearest_distance: float = INF
	var tiles: Array = _tiles.values()
	tiles.sort_custom(func(a, b) -> bool:
		var distance_a: float = world_pos.distance_squared_to(a.world_position)
		var distance_b: float = world_pos.distance_squared_to(b.world_position)
		if absf(distance_a - distance_b) > 0.001:
			return distance_a < distance_b
		var grid_a: Vector2i = a.grid_position
		var grid_b: Vector2i = b.grid_position
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	for tile_data in tiles:
		if not bool(tile_data.walkable):
			continue
		var distance_to_tile: float = world_pos.distance_squared_to(tile_data.world_position)
		if distance_to_tile >= nearest_distance:
			continue

		nearest_distance = distance_to_tile
		nearest_grid = tile_data.grid_position

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


func get_floor_height_at(grid_pos: Vector2i) -> float:
	return get_floor_height_at_floor(grid_pos, TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX)


func get_floor_height_at_floor(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> float:
	var tile_data = get_tile_at_grid_floor(grid_pos, floor_index)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_HEIGHT

	return float(tile_data.floor_height)


func get_floor_height_at_world(world_pos: Vector2) -> float:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_HEIGHT

	return float(tile_data.floor_height)


func get_floor_height_at_world_floor(world_pos: Vector2, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> float:
	return get_floor_height_at_floor(world_to_grid(world_pos), floor_index)


func get_cover_height_at(grid_pos: Vector2i) -> float:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_COVER_HEIGHT

	return float(tile_data.cover_height)


func get_cover_height_at_world(world_pos: Vector2) -> float:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_COVER_HEIGHT

	return float(tile_data.cover_height)


func get_los_blocker_height_at(grid_pos: Vector2i) -> float:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_BLOCKS_LOS_HEIGHT

	return float(tile_data.blocks_los_height)


func get_los_blocker_height_at_world(world_pos: Vector2) -> float:
	var tile_data = get_tile_at_world(world_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_BLOCKS_LOS_HEIGHT

	return float(tile_data.blocks_los_height)


func get_unit_eye_height_bonus_at(grid_pos: Vector2i) -> float:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_UNIT_EYE_HEIGHT_BONUS

	return float(tile_data.unit_eye_height_bonus)


func get_unit_eye_height_bonus_at_floor(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> float:
	var tile_data = get_tile_at_grid_floor(grid_pos, floor_index)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_UNIT_EYE_HEIGHT_BONUS
	return float(tile_data.unit_eye_height_bonus)


func is_elevated_surface_at(grid_pos: Vector2i) -> bool:
	var tile_data = get_tile_at_grid(grid_pos)
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_IS_ELEVATED_SURFACE

	return bool(tile_data.is_elevated_surface)


func get_height_profile_at_grid(grid_pos: Vector2i) -> Dictionary:
	return get_height_profile_at_grid_floor(grid_pos, TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX)


func get_height_profile_at_grid_floor(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> Dictionary:
	var tile_data = get_tile_at_grid_floor(grid_pos, floor_index)
	if tile_data == null:
		return {}

	return {
		"grid_position": grid_pos,
		"floor_index": int(tile_data.floor_index),
		"height_level": int(tile_data.height_level),
		"object_height": int(tile_data.object_height),
		"floor_height": float(tile_data.floor_height),
		"unit_eye_height_bonus": float(tile_data.unit_eye_height_bonus),
		"cover_height": float(tile_data.cover_height),
		"blocks_los_height": float(tile_data.blocks_los_height),
		"is_elevated_surface": bool(tile_data.is_elevated_surface),
		"height_transition_type": String(tile_data.height_transition_type),
		"floor_links": Array(tile_data.floor_links).duplicate(true),
	}


func get_floor_links_at_grid(grid_pos: Vector2i, floor_index: int = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX) -> Array:
	var tile_data = get_tile_at_grid_floor(grid_pos, floor_index)
	if tile_data == null:
		return []
	return Array(tile_data.floor_links).duplicate(true)


func can_traverse_floor_transition(from_grid: Vector2i, from_floor_index: int, to_grid: Vector2i, to_floor_index: int) -> bool:
	if from_floor_index == to_floor_index:
		return from_grid == to_grid or (is_walkable_floor(from_grid, from_floor_index) and is_walkable_floor(to_grid, to_floor_index))
	var from_tile = get_tile_at_grid_floor(from_grid, from_floor_index)
	var to_tile = get_tile_at_grid_floor(to_grid, to_floor_index)
	if from_tile == null or to_tile == null:
		return false
	if not bool(from_tile.walkable) or not bool(to_tile.walkable):
		return false
	if _has_floor_link(from_tile, to_grid, to_floor_index, false):
		return true
	return _has_floor_link(to_tile, from_grid, from_floor_index, true)


func get_floor_transition_snapshot(from_grid: Vector2i, from_floor_index: int, to_grid: Vector2i, to_floor_index: int) -> Dictionary:
	var from_tile = get_tile_at_grid_floor(from_grid, from_floor_index)
	var to_tile = get_tile_at_grid_floor(to_grid, to_floor_index)
	var traversable: bool = can_traverse_floor_transition(from_grid, from_floor_index, to_grid, to_floor_index)
	var reason: String = "allowed" if traversable else "floor_link_missing"
	if from_tile == null or to_tile == null:
		reason = "floor_slot_missing"
	elif not bool(from_tile.walkable) or not bool(to_tile.walkable):
		reason = "floor_slot_not_walkable"
	elif from_floor_index == to_floor_index:
		reason = "same_floor"
	return {
		"from_grid": from_grid,
		"from_floor_index": _coerce_floor_index(from_floor_index),
		"to_grid": to_grid,
		"to_floor_index": _coerce_floor_index(to_floor_index),
		"traversable": traversable,
		"reason": reason,
		"from_height": float(from_tile.floor_height) if from_tile != null else 0.0,
		"to_height": float(to_tile.floor_height) if to_tile != null else 0.0,
	}


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


func _has_floor_link(tile_data, target_grid: Vector2i, target_floor_index: int, require_bidirectional: bool) -> bool:
	if tile_data == null:
		return false
	for link_variant in Array(tile_data.floor_links):
		var link: Dictionary = TERRAIN_TILE_DATA_SCRIPT.normalize_floor_link(link_variant)
		if link.is_empty():
			continue
		if Vector2i(link.get("target_grid_position", Vector2i.ZERO)) != target_grid:
			continue
		if int(link.get("target_floor_index", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX)) != _coerce_floor_index(target_floor_index):
			continue
		if require_bidirectional and not bool(link.get("bidirectional", true)):
			continue
		return true
	return false


func _build_floor_key(grid_pos: Vector2i, floor_index: int) -> String:
	return "%d,%d:%d" % [grid_pos.x, grid_pos.y, _coerce_floor_index(floor_index)]


func _coerce_floor_index(floor_index: int) -> int:
	return clampi(int(floor_index), 0, TERRAIN_TILE_DATA_SCRIPT.MAX_FLOOR_INDEX)
