class_name LineOfSightSystem
extends RefCounted

const DEFAULT_MAX_RANGE: float = 320.0


func has_line_of_sight_between_points(
	source_position: Vector2,
	target_position: Vector2,
	max_range: float = DEFAULT_MAX_RANGE,
	terrain_registry = null
) -> bool:
	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		return false

	if terrain_registry == null:
		return true

	return has_line_of_sight_with_terrain(source_position, target_position, terrain_registry, max_range)


func has_line_of_sight_to_position(
	source: Node2D,
	target_position: Vector2,
	max_range: float = DEFAULT_MAX_RANGE,
	terrain_registry = null
) -> bool:
	if source == null:
		return false

	return has_line_of_sight_between_points(source.global_position, target_position, max_range, terrain_registry)


func has_line_of_sight_between_nodes(
	source: Node2D,
	target: Node2D,
	max_range: float = DEFAULT_MAX_RANGE,
	terrain_registry = null
) -> bool:
	if source == null or target == null:
		return false

	return has_line_of_sight_between_points(source.global_position, target.global_position, max_range, terrain_registry)


func has_line_of_sight_with_terrain(
	source_position: Vector2,
	target_position: Vector2,
	terrain_registry,
	max_range: float = DEFAULT_MAX_RANGE
) -> bool:
	if terrain_registry == null:
		return has_line_of_sight_between_points(source_position, target_position, max_range, null)

	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		return false

	var source_grid: Vector2i = terrain_registry.call("world_to_grid", source_position)
	var target_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var source_height: int = int(terrain_registry.call("get_height_at_world", source_position))
	var target_height: int = int(terrain_registry.call("get_height_at_world", target_position))
	for stepped_grid in _build_grid_line(source_grid, target_grid):
		if stepped_grid == source_grid or stepped_grid == target_grid:
			continue

		var tile_data = terrain_registry.call("get_tile_at_grid", stepped_grid)
		if tile_data == null or not bool(tile_data.blocks_los):
			continue

		var blocker_height: int = int(tile_data.height_level)
		if blocker_height >= source_height and blocker_height >= target_height:
			return false

	return true


func _build_grid_line(source_grid: Vector2i, target_grid: Vector2i) -> Array[Vector2i]:
	var stepped_grids: Array[Vector2i] = []
	var delta: Vector2i = target_grid - source_grid
	var step_count: int = maxi(abs(delta.x), abs(delta.y))
	if step_count <= 0:
		stepped_grids.append(source_grid)
		return stepped_grids

	var last_grid: Vector2i = Vector2i(2147483647, 2147483647)
	for step_index in range(step_count + 1):
		var t: float = float(step_index) / float(step_count)
		var stepped_grid := Vector2i(
			roundi(lerpf(float(source_grid.x), float(target_grid.x), t)),
			roundi(lerpf(float(source_grid.y), float(target_grid.y), t))
		)
		if stepped_grid == last_grid:
			continue

		stepped_grids.append(stepped_grid)
		last_grid = stepped_grid

	return stepped_grids
