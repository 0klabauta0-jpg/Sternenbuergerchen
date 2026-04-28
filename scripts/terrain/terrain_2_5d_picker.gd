class_name Terrain25DPicker
extends RefCounted

const DEFAULT_FLOOR_INDEX: int = 0

var cell_size: float = 2.0
var height_step: float = 0.35


func configure_grid(next_cell_size: float = 2.0, next_height_step: float = 0.35) -> void:
	cell_size = maxf(next_cell_size, 0.001)
	height_step = maxf(next_height_step, 0.001)


func grid_to_world_3d(grid_position: Vector2i, floor_height: float = 0.0) -> Vector3:
	return Vector3(float(grid_position.x) * cell_size, floor_height * height_step, float(grid_position.y) * cell_size)


func world_3d_to_grid(world_position: Vector3) -> Vector2i:
	return Vector2i(roundi(world_position.x / cell_size), roundi(world_position.z / cell_size))


func pick_screen(camera: Camera3D, screen_position: Vector2, terrain_registry = null, options: Dictionary = {}) -> Dictionary:
	if camera == null:
		return _failed_pick("camera_missing")
	var ray_origin: Vector3 = camera.project_ray_origin(screen_position)
	var ray_direction: Vector3 = camera.project_ray_normal(screen_position)
	return pick_ray(ray_origin, ray_direction, terrain_registry, options)


func pick_ray(ray_origin: Vector3, ray_direction: Vector3, terrain_registry = null, options: Dictionary = {}) -> Dictionary:
	if ray_direction.length() <= 0.001:
		return _failed_pick("ray_direction_missing")
	var normalized_direction: Vector3 = ray_direction.normalized()
	var requested_floor_index: int = int(options.get("floor_index", -1))
	if requested_floor_index >= 0:
		return _pick_explicit_floor(ray_origin, normalized_direction, terrain_registry, requested_floor_index)

	var ground_hit: Variant = _intersect_ray_with_floor_height(ray_origin, normalized_direction, 0.0)
	if typeof(ground_hit) != TYPE_VECTOR3:
		return _failed_pick("ray_misses_floor_plane")
	var base_grid: Vector2i = world_3d_to_grid(Vector3(ground_hit))
	var slots: Array = _get_floor_slots(terrain_registry, base_grid)
	if slots.is_empty():
		return _build_pick_snapshot(base_grid, DEFAULT_FLOOR_INDEX, 0.0, Vector3(ground_hit), ray_origin, normalized_direction, terrain_registry, "missing_floor_slot")

	var floor_mode: String = String(options.get("floor_mode", "default")).strip_edges().to_lower()
	var selected_slot = _select_floor_slot(slots, floor_mode, ray_origin)
	if selected_slot == null:
		selected_slot = slots[0]
	return _pick_explicit_floor(ray_origin, normalized_direction, terrain_registry, int(selected_slot.floor_index))


func _pick_explicit_floor(ray_origin: Vector3, ray_direction: Vector3, terrain_registry, floor_index: int) -> Dictionary:
	var approximate_hit: Variant = _intersect_ray_with_floor_height(ray_origin, ray_direction, float(floor_index))
	if typeof(approximate_hit) != TYPE_VECTOR3:
		return _failed_pick("ray_misses_floor_plane")
	var grid_position: Vector2i = world_3d_to_grid(Vector3(approximate_hit))
	var floor_height: float = _get_floor_height(terrain_registry, grid_position, floor_index)
	var exact_hit: Variant = _intersect_ray_with_floor_height(ray_origin, ray_direction, floor_height)
	if typeof(exact_hit) != TYPE_VECTOR3:
		return _failed_pick("ray_misses_floor_plane")
	grid_position = world_3d_to_grid(Vector3(exact_hit))
	floor_height = _get_floor_height(terrain_registry, grid_position, floor_index)
	exact_hit = _intersect_ray_with_floor_height(ray_origin, ray_direction, floor_height)
	if typeof(exact_hit) != TYPE_VECTOR3:
		return _failed_pick("ray_misses_floor_plane")
	grid_position = world_3d_to_grid(Vector3(exact_hit))
	return _build_pick_snapshot(grid_position, floor_index, floor_height, Vector3(exact_hit), ray_origin, ray_direction, terrain_registry, "ok")


func _intersect_ray_with_floor_height(ray_origin: Vector3, ray_direction: Vector3, floor_height: float) -> Variant:
	var plane_y: float = floor_height * height_step
	if absf(ray_direction.y) <= 0.0001:
		return null
	var t: float = (plane_y - ray_origin.y) / ray_direction.y
	if t < 0.0:
		return null
	return ray_origin + (ray_direction * t)


func _select_floor_slot(slots: Array, floor_mode: String, ray_origin: Vector3):
	var selected = slots[0]
	if floor_mode == "highest":
		for slot in slots:
			if float(slot.floor_height) > float(selected.floor_height):
				selected = slot
		return selected
	if floor_mode == "lowest":
		for slot in slots:
			if float(slot.floor_height) < float(selected.floor_height):
				selected = slot
		return selected
	if floor_mode == "nearest_camera":
		var best_distance: float = INF
		for slot in slots:
			var slot_world: Vector3 = grid_to_world_3d(Vector2i(slot.grid_position), float(slot.floor_height))
			var distance: float = ray_origin.distance_squared_to(slot_world)
			if distance < best_distance:
				best_distance = distance
				selected = slot
		return selected
	for slot in slots:
		if int(slot.floor_index) == DEFAULT_FLOOR_INDEX:
			return slot
	return selected


func _get_floor_slots(terrain_registry, grid_position: Vector2i) -> Array:
	if terrain_registry != null and terrain_registry.has_method("get_floor_slots_at_grid"):
		return Array(terrain_registry.call("get_floor_slots_at_grid", grid_position))
	return []


func _get_floor_height(terrain_registry, grid_position: Vector2i, floor_index: int) -> float:
	if terrain_registry != null and terrain_registry.has_method("get_floor_height_at_floor"):
		return float(terrain_registry.call("get_floor_height_at_floor", grid_position, floor_index))
	return float(floor_index)


func _is_walkable(terrain_registry, grid_position: Vector2i, floor_index: int) -> bool:
	if terrain_registry != null and terrain_registry.has_method("is_walkable_floor"):
		return bool(terrain_registry.call("is_walkable_floor", grid_position, floor_index))
	if terrain_registry != null and terrain_registry.has_method("is_walkable"):
		return bool(terrain_registry.call("is_walkable", grid_position))
	return false


func _get_target_position(terrain_registry, grid_position: Vector2i) -> Vector2:
	if terrain_registry != null and terrain_registry.has_method("grid_to_world"):
		return Vector2(terrain_registry.call("grid_to_world", grid_position))
	return Vector2(float(grid_position.x), float(grid_position.y))


func _build_pick_snapshot(
	grid_position: Vector2i,
	floor_index: int,
	floor_height: float,
	world_position_3d: Vector3,
	ray_origin: Vector3,
	ray_direction: Vector3,
	terrain_registry,
	reason: String
) -> Dictionary:
	return {
		"valid": reason == "ok",
		"reason": reason,
		"grid_position": grid_position,
		"floor_index": floor_index,
		"floor_height": floor_height,
		"target_position": _get_target_position(terrain_registry, grid_position),
		"target_floor_index": floor_index,
		"world_position_3d": world_position_3d,
		"ray_origin": ray_origin,
		"ray_direction": ray_direction,
		"walkable": _is_walkable(terrain_registry, grid_position, floor_index),
	}


func _failed_pick(reason: String) -> Dictionary:
	return {
		"valid": false,
		"reason": reason,
		"grid_position": Vector2i.ZERO,
		"floor_index": DEFAULT_FLOOR_INDEX,
		"floor_height": 0.0,
		"target_position": Vector2.ZERO,
		"target_floor_index": DEFAULT_FLOOR_INDEX,
		"world_position_3d": Vector3.ZERO,
		"ray_origin": Vector3.ZERO,
		"ray_direction": Vector3.ZERO,
		"walkable": false,
	}
