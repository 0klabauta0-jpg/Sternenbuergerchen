class_name TerrainPathfinder
extends RefCounted

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const CARDINAL_DIRECTIONS: Array = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
]
const NEIGHBOR_DIRECTIONS: Array = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1),
]
const DIAGONAL_COST_MULTIPLIER: float = 1.41421356237
const MIN_SURFACE_PATH_COST: float = 0.7
const DEFAULT_EXPOSURE_MAX_GRID_DISTANCE: float = 8.0
const MIN_COVER_AWARE_STEP_COST: float = 0.05
const MAX_TRAVERSABLE_HEIGHT_STEP: float = 1.01
const RAMP_HEIGHT_COST_FACTOR: float = 0.75
const STAIRS_HEIGHT_COST_FACTOR: float = 1.0


func find_path(from_grid: Vector2i, to_grid: Vector2i, registry) -> Array:
	return find_path_with_options(from_grid, to_grid, registry, {})


func find_path_with_options(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> Array:
	var result: Array = []
	if registry == null or not registry.has_method("get_tile_at_grid"):
		return result

	if registry.call("get_tile_at_grid", from_grid) == null or registry.call("get_tile_at_grid", to_grid) == null:
		return result

	if from_grid == to_grid:
		result.append(from_grid)
		return result

	var open_set: Array = [from_grid]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from_grid: 0.0}
	var f_score: Dictionary = {from_grid: _estimate_cost(from_grid, to_grid)}

	while not open_set.is_empty():
		var current: Vector2i = _pop_lowest_f_score(open_set, f_score)
		if current == to_grid:
			return _reconstruct_path(came_from, current)

		for direction in NEIGHBOR_DIRECTIONS:
			var neighbor: Vector2i = current + direction
			if not _is_neighbor_walkable(current, neighbor, registry):
				continue

			var tentative_g_score: float = float(g_score.get(current, INF)) + _get_step_cost(current, neighbor, registry, options)
			if tentative_g_score >= float(g_score.get(neighbor, INF)):
				continue

			came_from[neighbor] = current
			g_score[neighbor] = tentative_g_score
			f_score[neighbor] = tentative_g_score + _estimate_cost(neighbor, to_grid)
			if not open_set.has(neighbor):
				open_set.append(neighbor)

	return result


func get_neighbor_directions() -> Array:
	return NEIGHBOR_DIRECTIONS.duplicate()


func can_traverse_step(current_grid: Vector2i, neighbor_grid: Vector2i, registry) -> bool:
	return _is_neighbor_walkable(current_grid, neighbor_grid, registry)


func get_step_traversal_snapshot(current_grid: Vector2i, neighbor_grid: Vector2i, registry) -> Dictionary:
	var current_tile = registry.call("get_tile_at_grid", current_grid) if registry != null and registry.has_method("get_tile_at_grid") else null
	var neighbor_tile = registry.call("get_tile_at_grid", neighbor_grid) if registry != null and registry.has_method("get_tile_at_grid") else null
	return _build_step_traversal_snapshot(current_grid, neighbor_grid, current_tile, neighbor_tile)


func get_step_cost(current_grid: Vector2i, neighbor_grid: Vector2i, registry, options: Dictionary = {}) -> float:
	return _get_step_cost(current_grid, neighbor_grid, registry, options)


func can_traverse_floor_step(current_grid: Vector2i, current_floor_index: int, neighbor_grid: Vector2i, neighbor_floor_index: int, registry) -> bool:
	return bool(get_floor_step_traversal_snapshot(current_grid, current_floor_index, neighbor_grid, neighbor_floor_index, registry).get("traversable", false))


func get_floor_step_traversal_snapshot(current_grid: Vector2i, current_floor_index: int, neighbor_grid: Vector2i, neighbor_floor_index: int, registry) -> Dictionary:
	var normalized_current_floor: int = _normalize_floor_index(current_floor_index)
	var normalized_neighbor_floor: int = _normalize_floor_index(neighbor_floor_index)
	var snapshot: Dictionary = {
		"from_grid": current_grid,
		"from_floor_index": normalized_current_floor,
		"to_grid": neighbor_grid,
		"to_floor_index": normalized_neighbor_floor,
		"traversable": false,
		"reason": "",
	}
	if registry == null:
		snapshot["reason"] = "registry_missing"
		return snapshot
	if normalized_current_floor != normalized_neighbor_floor:
		if registry.has_method("get_floor_transition_snapshot"):
			return Dictionary(registry.call("get_floor_transition_snapshot", current_grid, normalized_current_floor, neighbor_grid, normalized_neighbor_floor))
		snapshot["reason"] = "floor_transition_api_missing"
		return snapshot
	if normalized_current_floor == TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX:
		var base_snapshot: Dictionary = get_step_traversal_snapshot(current_grid, neighbor_grid, registry)
		base_snapshot["from_floor_index"] = normalized_current_floor
		base_snapshot["to_floor_index"] = normalized_neighbor_floor
		return base_snapshot
	if not registry.has_method("get_tile_at_grid_floor"):
		snapshot["reason"] = "floor_lookup_api_missing"
		return snapshot
	var current_tile = registry.call("get_tile_at_grid_floor", current_grid, normalized_current_floor)
	var neighbor_tile = registry.call("get_tile_at_grid_floor", neighbor_grid, normalized_neighbor_floor)
	var floor_snapshot: Dictionary = _build_step_traversal_snapshot(current_grid, neighbor_grid, current_tile, neighbor_tile)
	floor_snapshot["from_floor_index"] = normalized_current_floor
	floor_snapshot["to_floor_index"] = normalized_neighbor_floor
	return floor_snapshot


func find_floor_path(from_grid: Vector2i, from_floor_index: int, to_grid: Vector2i, to_floor_index: int, registry) -> Array:
	var result: Array = []
	if registry == null or not registry.has_method("get_tile_at_grid_floor"):
		return result
	var start_floor: int = _normalize_floor_index(from_floor_index)
	var target_floor: int = _normalize_floor_index(to_floor_index)
	if registry.call("get_tile_at_grid_floor", from_grid, start_floor) == null or registry.call("get_tile_at_grid_floor", to_grid, target_floor) == null:
		return result

	var start_key: String = _build_floor_state_key(from_grid, start_floor)
	var target_key: String = _build_floor_state_key(to_grid, target_floor)
	var queue: Array = [_make_floor_state(from_grid, start_floor)]
	var visited: Dictionary = {start_key: true}
	var came_from: Dictionary = {}
	while not queue.is_empty():
		var current: Dictionary = Dictionary(queue.pop_front())
		var current_grid: Vector2i = Vector2i(current.get("grid_position", Vector2i.ZERO))
		var current_floor: int = int(current.get("floor_index", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX))
		var current_key: String = _build_floor_state_key(current_grid, current_floor)
		if current_key == target_key:
			return _reconstruct_floor_path(came_from, current_key)
		for neighbor_state in _get_floor_neighbors(current_grid, current_floor, registry):
			var neighbor_grid: Vector2i = Vector2i(Dictionary(neighbor_state).get("grid_position", Vector2i.ZERO))
			var neighbor_floor: int = int(Dictionary(neighbor_state).get("floor_index", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX))
			var neighbor_key: String = _build_floor_state_key(neighbor_grid, neighbor_floor)
			if visited.has(neighbor_key):
				continue
			if not can_traverse_floor_step(current_grid, current_floor, neighbor_grid, neighbor_floor, registry):
				continue
			visited[neighbor_key] = true
			came_from[neighbor_key] = current_key
			queue.append(neighbor_state)
	return result


func score_path(path_grid_points: Array, registry, options: Dictionary = {}) -> Dictionary:
	var exposure_sum: float = 0.0
	var cover_sum: float = 0.0
	var path_cost: float = 0.0
	var previous_grid: Variant = null
	for grid_variant in path_grid_points:
		var grid_position: Vector2i = Vector2i(grid_variant)
		exposure_sum += get_exposure_score(grid_position, registry, options)
		cover_sum += _get_cover_score(grid_position, registry)
		if previous_grid != null:
			path_cost += _get_step_cost(Vector2i(previous_grid), grid_position, registry, options)
		previous_grid = grid_position
	var count: int = path_grid_points.size()
	return {
		"path_length_grid": count,
		"exposure_sum": exposure_sum,
		"cover_sum": cover_sum,
		"mean_exposure": exposure_sum / float(count) if count > 0 else 0.0,
		"mean_cover": cover_sum / float(count) if count > 0 else 0.0,
		"path_cost": path_cost,
	}


func get_exposure_score(grid_position: Vector2i, registry, options: Dictionary = {}) -> float:
	if not bool(options.get("cover_aware_enabled", false)):
		return 0.0
	var exposure_map: Dictionary = Dictionary(options.get("exposure_by_grid", {}))
	if exposure_map.has(grid_position):
		return clampf(float(exposure_map.get(grid_position, 0.0)), 0.0, 1.0)
	var hazard_grids: Array = Array(options.get("hazard_grids", []))
	if hazard_grids.is_empty():
		return 0.0
	var max_distance: float = maxf(float(options.get("exposure_max_grid_distance", DEFAULT_EXPOSURE_MAX_GRID_DISTANCE)), 0.001)
	var exposure: float = 0.0
	for hazard_variant in hazard_grids:
		var hazard_grid: Vector2i = Vector2i(hazard_variant)
		var grid_distance: float = _grid_distance_score(grid_position, hazard_grid)
		if grid_distance > max_distance:
			continue
		if not _has_grid_line_of_sight(hazard_grid, grid_position, registry):
			continue
		var contribution: float = 1.0 - clampf(grid_distance / max_distance, 0.0, 1.0)
		exposure = maxf(exposure, contribution)
	return clampf(exposure, 0.0, 1.0)


func _pop_lowest_f_score(open_set: Array, f_score: Dictionary) -> Vector2i:
	var best_index: int = 0
	var best_score: float = float(f_score.get(open_set[0], INF))
	for index in range(1, open_set.size()):
		var candidate_score: float = float(f_score.get(open_set[index], INF))
		if candidate_score >= best_score:
			continue

		best_index = index
		best_score = candidate_score

	var best_grid: Vector2i = open_set[best_index]
	open_set.remove_at(best_index)
	return best_grid


func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array:
	var path: Array = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)

	return path


func _estimate_cost(from_grid: Vector2i, to_grid: Vector2i) -> float:
	var delta: Vector2i = to_grid - from_grid
	var distance_x: float = absf(float(delta.x))
	var distance_y: float = absf(float(delta.y))
	var diagonal_steps: float = minf(distance_x, distance_y)
	var straight_steps: float = absf(distance_x - distance_y)
	return (straight_steps + (diagonal_steps * DIAGONAL_COST_MULTIPLIER)) * MIN_SURFACE_PATH_COST


func _is_neighbor_walkable(current_grid: Vector2i, neighbor_grid: Vector2i, registry) -> bool:
	var delta: Vector2i = neighbor_grid - current_grid
	if abs(delta.x) > 1 or abs(delta.y) > 1 or delta == Vector2i.ZERO:
		return false
	if abs(delta.x) == 1 and abs(delta.y) == 1:
		var x_step_grid: Vector2i = current_grid + Vector2i(delta.x, 0)
		var y_step_grid: Vector2i = current_grid + Vector2i(0, delta.y)
		if not _is_grid_step_walkable(current_grid, x_step_grid, registry):
			return false
		if not _is_grid_step_walkable(current_grid, y_step_grid, registry):
			return false
	return _is_grid_step_walkable(current_grid, neighbor_grid, registry)


func _is_grid_step_walkable(current_grid: Vector2i, neighbor_grid: Vector2i, registry) -> bool:
	var current_tile = registry.call("get_tile_at_grid", current_grid)
	var neighbor_tile = registry.call("get_tile_at_grid", neighbor_grid)
	return bool(_build_step_traversal_snapshot(current_grid, neighbor_grid, current_tile, neighbor_tile).get("traversable", false))


func _get_step_cost(current_grid: Vector2i, neighbor_grid: Vector2i, registry, options: Dictionary = {}) -> float:
	var current_tile = registry.call("get_tile_at_grid", current_grid)
	var neighbor_tile = registry.call("get_tile_at_grid", neighbor_grid)
	if current_tile == null or neighbor_tile == null:
		return INF

	var transition_snapshot: Dictionary = _build_step_traversal_snapshot(current_grid, neighbor_grid, current_tile, neighbor_tile)
	var height_difference: float = float(transition_snapshot.get("height_difference", 0.0))
	var transition_type: String = String(transition_snapshot.get("height_transition_type", TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_NONE))
	var surface_cost: float = TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(String(neighbor_tile.surface_type))
	var base_cost: float = surface_cost
	if height_difference > 0.001:
		base_cost += height_difference * _get_height_transition_cost_factor(transition_type)

	if bool(options.get("cover_aware_enabled", false)):
		var exposure_weight: float = maxf(float(options.get("exposure_weight", 0.0)), 0.0)
		var cover_weight: float = maxf(float(options.get("cover_weight", 0.0)), 0.0)
		var exposure_score: float = get_exposure_score(neighbor_grid, registry, options)
		var cover_score: float = _get_cover_score(neighbor_grid, registry)
		base_cost = maxf(base_cost + (exposure_weight * exposure_score) - (cover_weight * cover_score), MIN_COVER_AWARE_STEP_COST)

	var delta: Vector2i = neighbor_grid - current_grid
	if abs(delta.x) == 1 and abs(delta.y) == 1:
		return base_cost * DIAGONAL_COST_MULTIPLIER
	return base_cost


func _build_step_traversal_snapshot(current_grid: Vector2i, neighbor_grid: Vector2i, current_tile, neighbor_tile) -> Dictionary:
	var delta: Vector2i = neighbor_grid - current_grid
	var snapshot: Dictionary = {
		"from_grid": current_grid,
		"to_grid": neighbor_grid,
		"traversable": false,
		"reason": "",
		"height_difference": 0.0,
		"from_height": 0.0,
		"to_height": 0.0,
		"height_transition_type": TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_NONE,
		"transition_grid": null,
	}
	if abs(delta.x) > 1 or abs(delta.y) > 1 or delta == Vector2i.ZERO:
		snapshot["reason"] = "not_adjacent"
		return snapshot
	if current_tile == null or neighbor_tile == null:
		snapshot["reason"] = "tile_missing"
		return snapshot
	if not bool(neighbor_tile.walkable):
		snapshot["reason"] = "target_not_walkable"
		return snapshot

	var current_height: float = _get_navigation_height(current_tile)
	var neighbor_height: float = _get_navigation_height(neighbor_tile)
	var height_difference: float = absf(neighbor_height - current_height)
	snapshot["from_height"] = current_height
	snapshot["to_height"] = neighbor_height
	snapshot["height_difference"] = height_difference
	if height_difference <= 0.001:
		snapshot["traversable"] = true
		snapshot["reason"] = "same_height"
		return snapshot

	var transition_tile = _resolve_transition_tile(current_tile, neighbor_tile)
	var transition_type: String = _get_height_transition_type(transition_tile)
	snapshot["height_transition_type"] = transition_type
	if transition_tile != null:
		snapshot["transition_grid"] = Vector2i(transition_tile.grid_position)
	if height_difference > MAX_TRAVERSABLE_HEIGHT_STEP:
		snapshot["reason"] = "height_step_too_large"
		return snapshot
	if not _is_height_transition_allowed(transition_type):
		snapshot["reason"] = "height_transition_missing"
		return snapshot

	snapshot["traversable"] = true
	snapshot["reason"] = "height_transition_%s" % transition_type
	return snapshot


func _get_navigation_height(tile_data) -> float:
	if tile_data == null:
		return 0.0
	return float(tile_data.floor_height)


func _resolve_transition_tile(current_tile, neighbor_tile):
	var current_type: String = _get_height_transition_type(current_tile)
	var neighbor_type: String = _get_height_transition_type(neighbor_tile)
	if _is_height_transition_allowed(neighbor_type):
		return neighbor_tile
	if _is_height_transition_allowed(current_type):
		return current_tile
	return neighbor_tile if _get_navigation_height(neighbor_tile) >= _get_navigation_height(current_tile) else current_tile


func _get_height_transition_type(tile_data) -> String:
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_NONE
	return TERRAIN_TILE_DATA_SCRIPT.normalize_height_transition_type(String(tile_data.height_transition_type), String(tile_data.edge_type))


func _is_height_transition_allowed(transition_type: String) -> bool:
	match transition_type:
		TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP, TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_STAIRS:
			return true
		_:
			return false


func _get_height_transition_cost_factor(transition_type: String) -> float:
	match transition_type:
		TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_RAMP:
			return RAMP_HEIGHT_COST_FACTOR
		TERRAIN_TILE_DATA_SCRIPT.HEIGHT_TRANSITION_STAIRS:
			return STAIRS_HEIGHT_COST_FACTOR
		_:
			return STAIRS_HEIGHT_COST_FACTOR


func _get_floor_neighbors(current_grid: Vector2i, current_floor_index: int, registry) -> Array:
	var result: Array = []
	for direction in NEIGHBOR_DIRECTIONS:
		var neighbor_grid: Vector2i = current_grid + Vector2i(direction)
		if registry.call("get_tile_at_grid_floor", neighbor_grid, current_floor_index) != null:
			result.append(_make_floor_state(neighbor_grid, current_floor_index))
	if registry.has_method("get_floor_links_at_grid"):
		for link_variant in Array(registry.call("get_floor_links_at_grid", current_grid, current_floor_index)):
			var link: Dictionary = TERRAIN_TILE_DATA_SCRIPT.normalize_floor_link(link_variant)
			if link.is_empty():
				continue
			result.append(_make_floor_state(Vector2i(link.get("target_grid_position", current_grid)), int(link.get("target_floor_index", current_floor_index))))
	if registry.has_method("get_all_floor_tiles"):
		for tile_data in Array(registry.call("get_all_floor_tiles")):
			if tile_data == null:
				continue
			var candidate_grid: Vector2i = Vector2i(tile_data.grid_position)
			var candidate_floor: int = int(tile_data.floor_index)
			if candidate_grid == current_grid and candidate_floor == current_floor_index:
				continue
			for link_variant in Array(tile_data.floor_links):
				var link: Dictionary = TERRAIN_TILE_DATA_SCRIPT.normalize_floor_link(link_variant)
				if link.is_empty() or not bool(link.get("bidirectional", true)):
					continue
				if Vector2i(link.get("target_grid_position", Vector2i.ZERO)) != current_grid:
					continue
				if int(link.get("target_floor_index", TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX)) != current_floor_index:
					continue
				result.append(_make_floor_state(candidate_grid, candidate_floor))
	return result


func _reconstruct_floor_path(came_from: Dictionary, current_key: String) -> Array:
	var path: Array = [_parse_floor_state_key(current_key)]
	while came_from.has(current_key):
		current_key = String(came_from[current_key])
		path.push_front(_parse_floor_state_key(current_key))
	return path


func _make_floor_state(grid_position: Vector2i, floor_index: int) -> Dictionary:
	return {
		"grid_position": grid_position,
		"floor_index": _normalize_floor_index(floor_index),
	}


func _build_floor_state_key(grid_position: Vector2i, floor_index: int) -> String:
	return "%d,%d:%d" % [grid_position.x, grid_position.y, _normalize_floor_index(floor_index)]


func _parse_floor_state_key(state_key: String) -> Dictionary:
	var parts: PackedStringArray = state_key.split(":")
	if parts.size() != 2:
		return _make_floor_state(Vector2i.ZERO, TERRAIN_TILE_DATA_SCRIPT.DEFAULT_FLOOR_INDEX)
	var grid_parts: PackedStringArray = String(parts[0]).split(",")
	if grid_parts.size() != 2:
		return _make_floor_state(Vector2i.ZERO, int(parts[1]))
	return _make_floor_state(Vector2i(int(grid_parts[0]), int(grid_parts[1])), int(parts[1]))


func _normalize_floor_index(floor_index: int) -> int:
	return clampi(int(floor_index), 0, TERRAIN_TILE_DATA_SCRIPT.MAX_FLOOR_INDEX)


func _get_cover_score(grid_position: Vector2i, registry) -> float:
	if registry == null or not registry.has_method("get_tile_at_grid"):
		return 0.0
	var tile_data = registry.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return 0.0
	return clampf(float(tile_data.cover_value) / 100.0, 0.0, 1.0)


func _grid_distance_score(a: Vector2i, b: Vector2i) -> float:
	var delta: Vector2i = a - b
	return maxf(absf(float(delta.x)), absf(float(delta.y)))


func _has_grid_line_of_sight(source_grid: Vector2i, target_grid: Vector2i, registry) -> bool:
	if registry == null or not registry.has_method("get_tile_at_grid"):
		return true
	var delta: Vector2i = target_grid - source_grid
	var step_count: int = maxi(abs(delta.x), abs(delta.y))
	if step_count <= 0:
		return true
	for step_index in range(1, step_count):
		var t: float = float(step_index) / float(step_count)
		var stepped_grid := Vector2i(
			roundi(lerpf(float(source_grid.x), float(target_grid.x), t)),
			roundi(lerpf(float(source_grid.y), float(target_grid.y), t))
		)
		var tile_data = registry.call("get_tile_at_grid", stepped_grid)
		if tile_data != null and bool(tile_data.blocks_los):
			return false
	return true
