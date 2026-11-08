class_name LineOfSightSystem
extends RefCounted

const TERRAIN_TRUTH_AUDIT_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_truth_audit.gd")
const DEFAULT_MAX_RANGE: float = 320.0

var _los_step_buffer: Array[Vector2i] = []


func has_line_of_sight_between_points(
	source_position: Vector2,
	target_position: Vector2,
	max_range: float = DEFAULT_MAX_RANGE,
	terrain_registry = null
) -> bool:
	# The terrain entry owns the same range guard. Delegate before computing it
	# here so admitted terrain queries do not repeat the identical calculation.
	if terrain_registry != null:
		return has_line_of_sight_with_terrain(source_position, target_position, terrain_registry, max_range)
	if max_range >= 0.0 and _range_distance(source_position, target_position, terrain_registry) > max_range:
		return false
	return true


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

	if max_range >= 0.0 and _range_distance(source_position, target_position, terrain_registry) > max_range:
		return false

	var source_grid: Vector2i = terrain_registry.call("world_to_grid", source_position)
	var target_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var source_grid_float: Vector2 = _world_to_grid_float(terrain_registry, source_position, source_grid)
	var target_grid_float: Vector2 = _world_to_grid_float(terrain_registry, target_position, target_grid)
	var source_height: int = int(terrain_registry.call("get_height_at_world", source_position))
	var target_height: int = int(terrain_registry.call("get_height_at_world", target_position))
	var hex_grid: bool = _uses_hex_grid(terrain_registry)
	_build_grid_line_into(source_grid, target_grid, _los_step_buffer, terrain_registry)
	for stepped_grid in _los_step_buffer:
		if stepped_grid == source_grid or stepped_grid == target_grid:
			continue

		var tile_data = terrain_registry.call("get_tile_at_grid", stepped_grid)
		if tile_data == null:
			continue
		var blocks_los: bool = bool(tile_data.blocks_los)
		if terrain_registry.has_method("blocks_los_at_grid"):
			blocks_los = bool(terrain_registry.call("blocks_los_at_grid", stepped_grid))
		if not blocks_los:
			continue

		var object_height: int = int(tile_data.object_height)
		if terrain_registry.has_method("get_object_height_at_grid"):
			object_height = int(terrain_registry.call("get_object_height_at_grid", stepped_grid))
		var blocker_height: int = int(tile_data.height_level) + object_height
		if blocker_height >= source_height and blocker_height >= target_height:
			# Legacy wall descriptors contain four square edges. Until hex-edge
			# descriptors are authored, a hex wall's explicit blocker occupies its
			# cell; never reinterpret those square segments as six hex edges.
			if not hex_grid and _tile_uses_wall_segment_los(tile_data):
				var crosses_wall_segment: bool = bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call(
					"does_tile_wall_block_los",
					tile_data,
					source_grid_float,
					target_grid_float
				))
				if not crosses_wall_segment:
					continue
			return false

	return true


func uses_wall_segment_los() -> bool:
	return true


func _build_grid_line(source_grid: Vector2i, target_grid: Vector2i) -> Array[Vector2i]:
	var stepped_grids: Array[Vector2i] = []
	_build_grid_line_into(source_grid, target_grid, stepped_grids)
	return stepped_grids


func _build_grid_line_into(source_grid: Vector2i, target_grid: Vector2i, out: Array[Vector2i], terrain_registry = null) -> void:
	out.clear()
	if _uses_hex_grid(terrain_registry):
		out.assign(terrain_registry.call("get_grid_line", source_grid, target_grid))
		return
	var delta: Vector2i = target_grid - source_grid
	var step_count: int = maxi(abs(delta.x), abs(delta.y))
	if step_count <= 0:
		out.append(source_grid)
		return

	var last_grid: Vector2i = Vector2i(2147483647, 2147483647)
	for step_index in range(step_count + 1):
		var t: float = float(step_index) / float(step_count)
		var stepped_grid := Vector2i(
			roundi(lerpf(float(source_grid.x), float(target_grid.x), t)),
			roundi(lerpf(float(source_grid.y), float(target_grid.y), t))
		)
		if stepped_grid == last_grid:
			continue

		out.append(stepped_grid)
		last_grid = stepped_grid


func _uses_hex_grid(terrain_registry) -> bool:
	return terrain_registry != null and terrain_registry.has_method("get_grid_topology") and String(terrain_registry.call("get_grid_topology")) == "hex_axial_v1"


func _range_distance(source_position: Vector2, target_position: Vector2, terrain_registry) -> float:
	if _uses_hex_grid(terrain_registry):
		return float(terrain_registry.call("get_movement_distance", source_position, target_position))
	return source_position.distance_to(target_position)


func _tile_uses_wall_segment_los(tile_data) -> bool:
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id)
	var object_type_id: String = String(tile_data.object_type_id)
	return bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("is_wall_type_id", type_id)) or bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("is_wall_type_id", object_type_id))


func _world_to_grid_float(terrain_registry, world_position: Vector2, fallback_grid: Vector2i) -> Vector2:
	if terrain_registry != null and terrain_registry.has_method("world_to_grid_float"):
		return Vector2(terrain_registry.call("world_to_grid_float", world_position))
	return Vector2(float(fallback_grid.x), float(fallback_grid.y))
