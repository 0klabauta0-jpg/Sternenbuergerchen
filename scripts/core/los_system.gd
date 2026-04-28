class_name LineOfSightSystem
extends RefCounted

const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const DEFAULT_MAX_RANGE: float = 320.0
const DEFAULT_SOURCE_EYE_HEIGHT: float = 1.5
const DEFAULT_TARGET_FOCUS_HEIGHT: float = 1.2
const LOS_HEIGHT_CLEARANCE: float = 0.05


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

	return bool(get_line_of_sight_snapshot(source_position, target_position, terrain_registry, max_range).get("has_line_of_sight", false))


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
	return bool(get_line_of_sight_snapshot(source_position, target_position, terrain_registry, max_range).get("has_line_of_sight", false))


func has_layered_line_of_sight(
	source_position: Vector2,
	target_position: Vector2,
	source_movement_layer: String = "ground",
	target_movement_layer: String = "ground",
	terrain_registry = null,
	max_range: float = DEFAULT_MAX_RANGE,
	source_altitude_band: int = 0,
	target_altitude_band: int = 0
) -> bool:
	return bool(get_layered_line_of_sight_snapshot(
		source_position,
		target_position,
		source_movement_layer,
		target_movement_layer,
		terrain_registry,
		max_range,
		source_altitude_band,
		target_altitude_band
	).get("has_line_of_sight", false))


func get_layered_line_of_sight_snapshot(
	source_position: Vector2,
	target_position: Vector2,
	source_movement_layer: String = "ground",
	target_movement_layer: String = "ground",
	terrain_registry = null,
	max_range: float = DEFAULT_MAX_RANGE,
	source_altitude_band: int = 0,
	target_altitude_band: int = 0
) -> Dictionary:
	var source_layer: String = MOVEMENT_LAYER_SCRIPT.normalize_layer(source_movement_layer)
	var target_layer: String = MOVEMENT_LAYER_SCRIPT.normalize_layer(target_movement_layer)
	var distance: float = source_position.distance_to(target_position)
	var is_air_context: bool = source_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR or target_layer == MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_AIR
	if is_air_context:
		var blocked_by_range: bool = max_range >= 0.0 and distance > max_range
		return {
			"has_line_of_sight": not blocked_by_range,
			"blocked_by_range": blocked_by_range,
			"blocking_grid": null,
			"source_position": source_position,
			"target_position": target_position,
			"distance": distance,
			"max_range": max_range,
			"source_movement_layer": source_layer,
			"target_movement_layer": target_layer,
			"source_altitude_band": MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(source_altitude_band),
			"target_altitude_band": MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(target_altitude_band),
			"los_mode": "air" if source_layer == target_layer else "air_ground",
			"terrain_blockers_ignored": true,
		}

	var ground_snapshot: Dictionary = get_line_of_sight_snapshot(source_position, target_position, terrain_registry, max_range)
	ground_snapshot["source_movement_layer"] = source_layer
	ground_snapshot["target_movement_layer"] = target_layer
	ground_snapshot["source_altitude_band"] = MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(source_altitude_band)
	ground_snapshot["target_altitude_band"] = MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(target_altitude_band)
	ground_snapshot["los_mode"] = "ground"
	ground_snapshot["terrain_blockers_ignored"] = false
	return ground_snapshot


func get_line_of_sight_snapshot(
	source_position: Vector2,
	target_position: Vector2,
	terrain_registry,
	max_range: float = DEFAULT_MAX_RANGE
) -> Dictionary:
	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		return {
			"has_line_of_sight": false,
			"blocked_by_range": true,
			"blocking_grid": null,
			"source_position": source_position,
			"target_position": target_position,
			"distance": source_position.distance_to(target_position),
			"max_range": max_range,
		}

	if terrain_registry == null:
		return {
			"has_line_of_sight": true,
			"blocked_by_range": false,
			"blocking_grid": null,
			"source_position": source_position,
			"target_position": target_position,
			"distance": source_position.distance_to(target_position),
			"max_range": max_range,
		}

	var source_grid: Vector2i = terrain_registry.call("world_to_grid", source_position)
	var target_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var source_eye_height: float = _get_eye_height_at_world(source_position, terrain_registry)
	var target_focus_height: float = _get_target_focus_height_at_world(target_position, terrain_registry)
	var stepped_grids: Array[Vector2i] = _build_grid_line(source_grid, target_grid)
	var sample_records: Array = []
	var step_count: int = maxi(stepped_grids.size() - 1, 1)
	for index in range(stepped_grids.size()):
		var stepped_grid: Vector2i = stepped_grids[index]
		if stepped_grid == source_grid or stepped_grid == target_grid:
			continue

		var tile_data = terrain_registry.call("get_tile_at_grid", stepped_grid)
		if tile_data == null:
			continue

		var t: float = clampf(float(index) / float(step_count), 0.0, 1.0)
		var sight_height: float = lerpf(source_eye_height, target_focus_height, t)
		var blocker_height: float = _get_los_blocker_height(tile_data)
		var sample_record: Dictionary = {
			"grid_position": stepped_grid,
			"sight_height": sight_height,
			"blocks_los_height": blocker_height,
			"blocks_los": bool(tile_data.blocks_los),
		}
		sample_records.append(sample_record)
		if blocker_height <= 0.0:
			continue

		if blocker_height + LOS_HEIGHT_CLEARANCE >= sight_height:
			sample_record["blocked"] = true
			return {
				"has_line_of_sight": false,
				"blocked_by_range": false,
				"blocking_grid": stepped_grid,
				"blocking_height": blocker_height,
				"sight_height_at_blocker": sight_height,
				"source_grid": source_grid,
				"target_grid": target_grid,
				"source_eye_height": source_eye_height,
				"target_focus_height": target_focus_height,
				"samples": sample_records,
			}

	return {
		"has_line_of_sight": true,
		"blocked_by_range": false,
		"blocking_grid": null,
		"source_grid": source_grid,
		"target_grid": target_grid,
		"source_eye_height": source_eye_height,
		"target_focus_height": target_focus_height,
		"samples": sample_records,
	}


func get_line_of_sight_floor_snapshot(
	source_grid: Vector2i,
	source_floor_index: int,
	target_grid: Vector2i,
	target_floor_index: int,
	terrain_registry,
	max_range: float = DEFAULT_MAX_RANGE
) -> Dictionary:
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return {
			"has_line_of_sight": false,
			"blocked_by_range": false,
			"blocking_grid": null,
			"source_grid": source_grid,
			"target_grid": target_grid,
			"source_floor_index": source_floor_index,
			"target_floor_index": target_floor_index,
			"reason": "terrain_registry_missing",
		}
	var source_position: Vector2 = terrain_registry.call("grid_to_world", source_grid)
	var target_position: Vector2 = terrain_registry.call("grid_to_world", target_grid)
	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		return {
			"has_line_of_sight": false,
			"blocked_by_range": true,
			"blocking_grid": null,
			"source_grid": source_grid,
			"target_grid": target_grid,
			"source_floor_index": source_floor_index,
			"target_floor_index": target_floor_index,
			"distance": source_position.distance_to(target_position),
			"max_range": max_range,
		}

	var source_eye_height: float = _get_eye_height_at_grid_floor(source_grid, source_floor_index, terrain_registry)
	var target_focus_height: float = _get_target_focus_height_at_grid_floor(target_grid, target_floor_index, terrain_registry)
	var stepped_grids: Array[Vector2i] = _build_grid_line(source_grid, target_grid)
	var sample_records: Array = []
	var step_count: int = maxi(stepped_grids.size() - 1, 1)
	for index in range(stepped_grids.size()):
		var stepped_grid: Vector2i = stepped_grids[index]
		if stepped_grid == source_grid or stepped_grid == target_grid:
			continue
		var tile_data = terrain_registry.call("get_tile_at_grid", stepped_grid)
		if tile_data == null:
			continue
		var t: float = clampf(float(index) / float(step_count), 0.0, 1.0)
		var sight_height: float = lerpf(source_eye_height, target_focus_height, t)
		var blocker_height: float = _get_los_blocker_height(tile_data)
		var sample_record: Dictionary = {
			"grid_position": stepped_grid,
			"sight_height": sight_height,
			"blocks_los_height": blocker_height,
			"blocks_los": bool(tile_data.blocks_los),
		}
		sample_records.append(sample_record)
		if blocker_height > 0.0 and blocker_height + LOS_HEIGHT_CLEARANCE >= sight_height:
			sample_record["blocked"] = true
			return {
				"has_line_of_sight": false,
				"blocked_by_range": false,
				"blocking_grid": stepped_grid,
				"blocking_height": blocker_height,
				"sight_height_at_blocker": sight_height,
				"source_grid": source_grid,
				"target_grid": target_grid,
				"source_floor_index": source_floor_index,
				"target_floor_index": target_floor_index,
				"source_eye_height": source_eye_height,
				"target_focus_height": target_focus_height,
				"samples": sample_records,
			}
	return {
		"has_line_of_sight": true,
		"blocked_by_range": false,
		"blocking_grid": null,
		"source_grid": source_grid,
		"target_grid": target_grid,
		"source_floor_index": source_floor_index,
		"target_floor_index": target_floor_index,
		"source_eye_height": source_eye_height,
		"target_focus_height": target_focus_height,
		"samples": sample_records,
	}


func _get_eye_height_at_world(world_position: Vector2, terrain_registry) -> float:
	var floor_height: float = 0.0
	var eye_bonus: float = 0.0
	if terrain_registry != null and terrain_registry.has_method("get_floor_height_at_world"):
		floor_height = float(terrain_registry.call("get_floor_height_at_world", world_position))
	if terrain_registry != null and terrain_registry.has_method("get_unit_eye_height_bonus_at"):
		eye_bonus = float(terrain_registry.call("get_unit_eye_height_bonus_at", terrain_registry.call("world_to_grid", world_position)))
	return floor_height + DEFAULT_SOURCE_EYE_HEIGHT + eye_bonus


func _get_eye_height_at_grid_floor(grid_position: Vector2i, floor_index: int, terrain_registry) -> float:
	var floor_height: float = 0.0
	var eye_bonus: float = 0.0
	if terrain_registry != null and terrain_registry.has_method("get_floor_height_at_floor"):
		floor_height = float(terrain_registry.call("get_floor_height_at_floor", grid_position, floor_index))
	if terrain_registry != null and terrain_registry.has_method("get_unit_eye_height_bonus_at_floor"):
		eye_bonus = float(terrain_registry.call("get_unit_eye_height_bonus_at_floor", grid_position, floor_index))
	return floor_height + DEFAULT_SOURCE_EYE_HEIGHT + eye_bonus


func _get_target_focus_height_at_world(world_position: Vector2, terrain_registry) -> float:
	var floor_height: float = 0.0
	var eye_bonus: float = 0.0
	if terrain_registry != null and terrain_registry.has_method("get_floor_height_at_world"):
		floor_height = float(terrain_registry.call("get_floor_height_at_world", world_position))
	if terrain_registry != null and terrain_registry.has_method("get_unit_eye_height_bonus_at"):
		eye_bonus = float(terrain_registry.call("get_unit_eye_height_bonus_at", terrain_registry.call("world_to_grid", world_position)))
	return floor_height + DEFAULT_TARGET_FOCUS_HEIGHT + eye_bonus


func _get_target_focus_height_at_grid_floor(grid_position: Vector2i, floor_index: int, terrain_registry) -> float:
	var floor_height: float = 0.0
	var eye_bonus: float = 0.0
	if terrain_registry != null and terrain_registry.has_method("get_floor_height_at_floor"):
		floor_height = float(terrain_registry.call("get_floor_height_at_floor", grid_position, floor_index))
	if terrain_registry != null and terrain_registry.has_method("get_unit_eye_height_bonus_at_floor"):
		eye_bonus = float(terrain_registry.call("get_unit_eye_height_bonus_at_floor", grid_position, floor_index))
	return floor_height + DEFAULT_TARGET_FOCUS_HEIGHT + eye_bonus


func _get_los_blocker_height(tile_data) -> float:
	if tile_data == null:
		return 0.0
	var blocker_height: float = float(tile_data.blocks_los_height)
	if blocker_height <= 0.0 and bool(tile_data.blocks_los):
		blocker_height = maxf(float(tile_data.height_level), float(tile_data.object_height))
	return blocker_height


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
