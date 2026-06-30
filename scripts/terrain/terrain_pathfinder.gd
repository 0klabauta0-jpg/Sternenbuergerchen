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
const LANE_PENALTY_SCALE: float = 0.35
const BLOCKER_CLEARANCE_PENALTY_SCALE: float = 0.4


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
	var in_open_set: Dictionary = {from_grid: true}
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from_grid: 0.0}
	var f_score: Dictionary = {from_grid: _estimate_cost(from_grid, to_grid)}

	while not open_set.is_empty():
		var current: Vector2i = _pop_lowest_f_score(open_set, f_score)
		in_open_set.erase(current)
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
			if not in_open_set.has(neighbor):
				in_open_set[neighbor] = true
				open_set.append(neighbor)

	return result


func get_neighbor_directions() -> Array:
	return NEIGHBOR_DIRECTIONS.duplicate()


func can_traverse_step(current_grid: Vector2i, neighbor_grid: Vector2i, registry) -> bool:
	return _is_neighbor_walkable(current_grid, neighbor_grid, registry)


func get_step_cost(current_grid: Vector2i, neighbor_grid: Vector2i, registry, options: Dictionary = {}) -> float:
	return _get_step_cost(current_grid, neighbor_grid, registry, options)


func score_path(path_grid_points: Array, registry, options: Dictionary = {}) -> Dictionary:
	var exposure_sum: float = 0.0
	var cover_sum: float = 0.0
	var path_cost: float = 0.0
	var previous_grid: Variant = null
	for grid_variant in path_grid_points:
		var grid_position: Vector2i = Vector2i(grid_variant)
		exposure_sum += get_exposure_score(grid_position, registry, options)
		cover_sum += _get_cover_score(grid_position, registry, options)
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
	_increment_diagnostic_counter(options, "exposure_score_calls")
	var max_distance: float = maxf(float(options.get("exposure_max_grid_distance", DEFAULT_EXPOSURE_MAX_GRID_DISTANCE)), 0.001)
	var exposure: float = 0.0
	for hazard_variant in hazard_grids:
		var hazard_grid: Vector2i = Vector2i(hazard_variant)
		var grid_distance: float = _grid_distance_score(grid_position, hazard_grid)
		if grid_distance > max_distance:
			continue
		_increment_diagnostic_counter(options, "los_check_count")
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
	if current_tile == null or neighbor_tile == null:
		return false

	if registry.has_method("is_walkable"):
		if not bool(registry.call("is_walkable", neighbor_grid)):
			return false
	elif not bool(neighbor_tile.walkable):
		return false

	var height_difference: int = abs(int(neighbor_tile.height_level) - int(current_tile.height_level))
	if height_difference == 0:
		return true

	# Determine edge_type of the higher tile — it controls traversability
	var higher_tile = neighbor_tile if int(neighbor_tile.height_level) > int(current_tile.height_level) else current_tile
	var edge_type: String = String(higher_tile.edge_type)

	if edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		return true  # slopes are always traversable
	else:
		return false


func _get_step_cost(current_grid: Vector2i, neighbor_grid: Vector2i, registry, options: Dictionary = {}) -> float:
	var current_tile = registry.call("get_tile_at_grid", current_grid)
	var neighbor_tile = registry.call("get_tile_at_grid", neighbor_grid)
	if current_tile == null or neighbor_tile == null:
		return INF
	if not _is_neighbor_walkable(current_grid, neighbor_grid, registry):
		return INF

	var height_difference: int = abs(int(neighbor_tile.height_level) - int(current_tile.height_level))
	var surface_cost: float = TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(String(neighbor_tile.surface_type))

	# Slopes cost more per height level than flat terrain
	var base_cost: float = surface_cost
	if height_difference > 0:
		var higher_tile = neighbor_tile if int(neighbor_tile.height_level) > int(current_tile.height_level) else current_tile
		var edge_type: String = String(higher_tile.edge_type)
		if edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
			base_cost = surface_cost + (float(height_difference) * 1.0)

	if bool(options.get("cover_aware_enabled", false)):
		var exposure_weight: float = maxf(float(options.get("exposure_weight", 0.0)), 0.0)
		var cover_weight: float = maxf(float(options.get("cover_weight", 0.0)), 0.0)
		var exposure_score: float = get_exposure_score(neighbor_grid, registry, options)
		var cover_score: float = _get_cover_score(neighbor_grid, registry, options)
		base_cost = maxf(base_cost + (exposure_weight * exposure_score) - (cover_weight * cover_score), MIN_COVER_AWARE_STEP_COST)
	base_cost += _get_corridor_penalty(neighbor_grid, options)
	base_cost += _get_lane_penalty(neighbor_grid, options)
	base_cost += _get_blocker_clearance_penalty(neighbor_grid, registry, options)

	var delta: Vector2i = neighbor_grid - current_grid
	if abs(delta.x) == 1 and abs(delta.y) == 1:
		return base_cost * DIAGONAL_COST_MULTIPLIER
	return base_cost


func _get_cover_score(grid_position: Vector2i, registry, options: Dictionary = {}) -> float:
	_increment_diagnostic_counter(options, "cover_check_count")
	if registry == null or not registry.has_method("get_tile_at_grid"):
		return 0.0
	var tile_data = registry.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return 0.0
	if registry.has_method("get_cover_at"):
		return clampf(float(registry.call("get_cover_at", grid_position)) / 100.0, 0.0, 1.0)
	return clampf(float(tile_data.cover_value) / 100.0, 0.0, 1.0)


func _get_corridor_penalty(grid_position: Vector2i, options: Dictionary) -> float:
	if not bool(options.get("corridor_enabled", false)):
		return 0.0
	var corridor_weight: float = maxf(float(options.get("corridor_weight", 0.0)), 0.0)
	if corridor_weight <= 0.0:
		return 0.0
	var from_grid: Vector2i = Vector2i(options.get("corridor_from_grid", grid_position))
	var to_grid: Vector2i = Vector2i(options.get("corridor_to_grid", grid_position))
	var half_width: float = maxf(float(options.get("corridor_half_width_grid", 0.0)), 0.0)
	var distance: float = absf(_signed_grid_line_distance(grid_position, from_grid, to_grid))
	if distance <= half_width:
		return 0.0
	_increment_diagnostic_counter(options, "corridor_penalty_count")
	return (distance - half_width) * corridor_weight


func _get_lane_penalty(grid_position: Vector2i, options: Dictionary) -> float:
	if not bool(options.get("lane_enabled", false)):
		return 0.0
	var lane_weight: float = maxf(float(options.get("lane_weight", 0.0)), 0.0)
	if lane_weight <= 0.0:
		return 0.0
	var from_grid: Vector2i = Vector2i(options.get("corridor_from_grid", grid_position))
	var to_grid: Vector2i = Vector2i(options.get("corridor_to_grid", grid_position))
	var signed_distance: float = _signed_grid_line_distance(grid_position, from_grid, to_grid)
	var desired_offset: float = float(options.get("lane_offset_grid", 0.0))
	_increment_diagnostic_counter(options, "lane_penalty_count")
	return absf(signed_distance - desired_offset) * lane_weight * LANE_PENALTY_SCALE


func _get_blocker_clearance_penalty(grid_position: Vector2i, registry, options: Dictionary) -> float:
	var blocker_weight: float = maxf(float(options.get("blocker_clearance_weight", 0.0)), 0.0)
	if blocker_weight <= 0.0 or registry == null or not registry.has_method("get_tile_at_grid"):
		return 0.0
	var radius: int = maxi(int(options.get("blocker_clearance_radius", 1)), 1)
	var blocker_score: float = 0.0
	var sample_count: int = 0
	for offset_x in range(-radius, radius + 1):
		for offset_y in range(-radius, radius + 1):
			if offset_x == 0 and offset_y == 0:
				continue
			var probe_grid: Vector2i = grid_position + Vector2i(offset_x, offset_y)
			var tile_data = registry.call("get_tile_at_grid", probe_grid)
			sample_count += 1
			if tile_data == null:
				blocker_score += 1.0
				continue
			var probe_walkable: bool = bool(registry.call("is_walkable", probe_grid)) if registry.has_method("is_walkable") else bool(tile_data.walkable)
			var probe_blocks_los: bool = bool(registry.call("blocks_los_at_grid", probe_grid)) if registry.has_method("blocks_los_at_grid") else bool(tile_data.blocks_los)
			if not probe_walkable:
				blocker_score += 1.0
			elif probe_blocks_los:
				blocker_score += 0.45
	if sample_count <= 0:
		return 0.0
	var normalized_score: float = clampf(blocker_score / float(sample_count), 0.0, 1.0)
	if normalized_score > 0.0:
		_increment_diagnostic_counter(options, "blocker_clearance_penalty_count")
	return normalized_score * blocker_weight * BLOCKER_CLEARANCE_PENALTY_SCALE


func _signed_grid_line_distance(grid_position: Vector2i, from_grid: Vector2i, to_grid: Vector2i) -> float:
	var from_value: Vector2 = Vector2(from_grid)
	var to_value: Vector2 = Vector2(to_grid)
	var point_value: Vector2 = Vector2(grid_position)
	var line: Vector2 = to_value - from_value
	var length: float = line.length()
	if length <= 0.001:
		return 0.0
	var delta: Vector2 = point_value - from_value
	return line.cross(delta) / length


func _grid_distance_score(a: Vector2i, b: Vector2i) -> float:
	var delta: Vector2i = a - b
	return maxf(absf(float(delta.x)), absf(float(delta.y)))


func _has_grid_line_of_sight(source_grid: Vector2i, target_grid: Vector2i, registry) -> bool:
	if registry == null or not registry.has_method("get_tile_at_grid"):
		return true
	var source_tile = registry.call("get_tile_at_grid", source_grid)
	var target_tile = registry.call("get_tile_at_grid", target_grid)
	var source_height: int = int(source_tile.height_level) if source_tile != null else 0
	var target_height: int = int(target_tile.height_level) if target_tile != null else 0
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
		if tile_data == null:
			continue
		var blocks_los: bool = bool(tile_data.blocks_los)
		if registry.has_method("blocks_los_at_grid"):
			blocks_los = bool(registry.call("blocks_los_at_grid", stepped_grid))
		if not blocks_los:
			continue
		var object_height: int = int(tile_data.object_height)
		if registry.has_method("get_object_height_at_grid"):
			object_height = int(registry.call("get_object_height_at_grid", stepped_grid))
		var blocker_height: int = int(tile_data.height_level) + object_height
		if blocker_height >= source_height and blocker_height >= target_height:
			return false
	return true


func _increment_diagnostic_counter(options: Dictionary, key: String, amount: int = 1) -> void:
	var diagnostics_variant: Variant = options.get("diagnostics", null)
	if typeof(diagnostics_variant) != TYPE_DICTIONARY:
		return
	var diagnostics: Dictionary = Dictionary(diagnostics_variant)
	diagnostics[key] = int(diagnostics.get(key, 0)) + amount
