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


func find_path(from_grid: Vector2i, to_grid: Vector2i, registry) -> Array:
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

			var tentative_g_score: float = float(g_score.get(current, INF)) + _get_step_cost(current, neighbor, registry)
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

	if not bool(neighbor_tile.walkable):
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
		return height_difference <= 1  # cliffs only allow 1 level difference


func _get_step_cost(current_grid: Vector2i, neighbor_grid: Vector2i, registry) -> float:
	var current_tile = registry.call("get_tile_at_grid", current_grid)
	var neighbor_tile = registry.call("get_tile_at_grid", neighbor_grid)
	if current_tile == null or neighbor_tile == null:
		return INF

	var height_difference: int = abs(int(neighbor_tile.height_level) - int(current_tile.height_level))
	var surface_cost: float = TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(String(neighbor_tile.surface_type))

	# Slopes cost more per height level than flat terrain
	var base_cost: float = surface_cost + (float(height_difference) * 0.5)
	if height_difference > 0:
		var higher_tile = neighbor_tile if int(neighbor_tile.height_level) > int(current_tile.height_level) else current_tile
		var edge_type: String = String(higher_tile.edge_type)
		if edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
			base_cost = surface_cost + (float(height_difference) * 1.0)

	var delta: Vector2i = neighbor_grid - current_grid
	if abs(delta.x) == 1 and abs(delta.y) == 1:
		return base_cost * DIAGONAL_COST_MULTIPLIER
	return base_cost
