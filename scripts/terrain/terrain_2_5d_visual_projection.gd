class_name Terrain25DVisualProjection
extends RefCounted

const MOVEMENT_LAYER_SCRIPT: GDScript = preload("res://scripts/core/movement_layer.gd")
const DEFAULT_CELL_SIZE: float = 2.0
const DEFAULT_HEIGHT_STEP: float = 0.35
const AIR_ALTITUDE_HEIGHT_PER_BAND: float = 2.0
const SELECTION_Y_OFFSET: float = 0.04
const MARKER_Y_OFFSET: float = 0.35
const DEBUG_LABEL_Y_OFFSET: float = 0.95

var cell_size: float = DEFAULT_CELL_SIZE
var height_step: float = DEFAULT_HEIGHT_STEP


func configure_grid(new_cell_size: float, new_height_step: float) -> void:
	cell_size = maxf(new_cell_size, 0.001)
	height_step = maxf(new_height_step, 0.001)


func project_node2d(node: Node2D, terrain_registry, options: Dictionary = {}) -> Dictionary:
	if node == null:
		return _invalid_projection("node_missing")
	var resolved_options: Dictionary = options.duplicate(true)
	if not resolved_options.has("floor_index"):
		resolved_options["floor_index"] = _extract_floor_index(node)
	if not resolved_options.has("movement_layer"):
		resolved_options["movement_layer"] = _extract_movement_layer(node)
	if not resolved_options.has("altitude_band"):
		resolved_options["altitude_band"] = _extract_altitude_band(node)
	return project_world_position(node.global_position, terrain_registry, resolved_options)


func project_marker2d(marker: Node2D, terrain_registry, options: Dictionary = {}) -> Dictionary:
	if marker == null:
		return _invalid_projection("marker_missing")
	var resolved_options: Dictionary = options.duplicate(true)
	if not resolved_options.has("movement_layer"):
		resolved_options["movement_layer"] = MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND
	if not resolved_options.has("altitude_band"):
		resolved_options["altitude_band"] = MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND
	return project_world_position(marker.global_position, terrain_registry, resolved_options)


func project_world_position(world_position: Vector2, terrain_registry, options: Dictionary = {}) -> Dictionary:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return _invalid_projection("terrain_registry_missing")

	var grid_position: Vector2i = Vector2i(terrain_registry.call("world_to_grid", world_position))
	var floor_index: int = max(0, int(options.get("floor_index", 0)))
	var movement_layer: String = MOVEMENT_LAYER_SCRIPT.normalize_layer(String(options.get("movement_layer", MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND)))
	var altitude_band: int = MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(options.get("altitude_band", MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND))
	var floor_height: float = _resolve_floor_height(world_position, grid_position, floor_index, terrain_registry)
	var air_height: float = float(altitude_band) * AIR_ALTITUDE_HEIGHT_PER_BAND if MOVEMENT_LAYER_SCRIPT.is_air_layer(movement_layer) else 0.0
	var continuous_grid_position: Vector2 = _resolve_continuous_grid_position(world_position, grid_position, terrain_registry)
	var base_position := Vector3(continuous_grid_position.x * cell_size, floor_height * height_step, continuous_grid_position.y * cell_size)
	var visual_position := base_position + Vector3(0.0, air_height * height_step, 0.0)
	return {
		"valid": true,
		"reason": "",
		"world_position_2d": world_position,
		"grid_position": grid_position,
		"continuous_grid_position": continuous_grid_position,
		"floor_index": floor_index,
		"floor_height": floor_height,
		"movement_layer": movement_layer,
		"altitude_band": altitude_band,
		"air_height": air_height,
		"cell_size": cell_size,
		"height_step": height_step,
		"base_position_3d": base_position,
		"visual_position_3d": visual_position,
		"selection_position_3d": visual_position + Vector3(0.0, SELECTION_Y_OFFSET, 0.0),
		"target_position_3d": visual_position + Vector3(0.0, MARKER_Y_OFFSET, 0.0),
		"marker_position_3d": visual_position + Vector3(0.0, MARKER_Y_OFFSET, 0.0),
		"debug_label_position_3d": visual_position + Vector3(0.0, DEBUG_LABEL_Y_OFFSET, 0.0),
		"shadow_position_3d": base_position + Vector3(0.0, SELECTION_Y_OFFSET * 0.5, 0.0),
	}


func _resolve_floor_height(world_position: Vector2, grid_position: Vector2i, floor_index: int, terrain_registry) -> float:
	if terrain_registry.has_method("get_floor_height_at_world_floor"):
		return float(terrain_registry.call("get_floor_height_at_world_floor", world_position, floor_index))
	if terrain_registry.has_method("get_floor_height_at_floor"):
		return float(terrain_registry.call("get_floor_height_at_floor", grid_position, floor_index))
	if terrain_registry.has_method("get_floor_height_at_world"):
		return float(terrain_registry.call("get_floor_height_at_world", world_position))
	if terrain_registry.has_method("get_floor_height_at"):
		return float(terrain_registry.call("get_floor_height_at", grid_position))
	return 0.0


func _resolve_continuous_grid_position(world_position: Vector2, grid_position: Vector2i, terrain_registry) -> Vector2:
	if terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return Vector2(grid_position)
	var center: Vector2 = Vector2(terrain_registry.call("grid_to_world", grid_position))
	var grid_x_basis: Vector2 = Vector2(terrain_registry.call("grid_to_world", grid_position + Vector2i(1, 0))) - center
	var grid_y_basis: Vector2 = Vector2(terrain_registry.call("grid_to_world", grid_position + Vector2i(0, 1))) - center
	var offset: Vector2 = world_position - center
	var determinant: float = grid_x_basis.x * grid_y_basis.y - grid_y_basis.x * grid_x_basis.y
	if absf(determinant) <= 0.001:
		return Vector2(grid_position)
	var offset_grid_x: float = (offset.x * grid_y_basis.y - grid_y_basis.x * offset.y) / determinant
	var offset_grid_y: float = (grid_x_basis.x * offset.y - offset.x * grid_x_basis.y) / determinant
	return Vector2(float(grid_position.x) + offset_grid_x, float(grid_position.y) + offset_grid_y)


func _extract_floor_index(node: Object) -> int:
	if node != null and node.has_method("get_runtime_status"):
		var runtime_status = node.call("get_runtime_status")
		if runtime_status != null:
			return max(0, int(runtime_status.get("target_floor_index")))
	return 0


func _extract_movement_layer(node: Object) -> String:
	if node != null and node.has_method("get_movement_layer"):
		return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(node.call("get_movement_layer")))
	if node != null and node.has_method("get_runtime_status"):
		var runtime_status = node.call("get_runtime_status")
		if runtime_status != null:
			return MOVEMENT_LAYER_SCRIPT.normalize_layer(String(runtime_status.get("movement_layer")))
	return MOVEMENT_LAYER_SCRIPT.MOVEMENT_LAYER_GROUND


func _extract_altitude_band(node: Object) -> int:
	if node != null and node.has_method("get_altitude_band"):
		return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(node.call("get_altitude_band"))
	if node != null and node.has_method("get_runtime_status"):
		var runtime_status = node.call("get_runtime_status")
		if runtime_status != null:
			return MOVEMENT_LAYER_SCRIPT.normalize_altitude_band(runtime_status.get("altitude_band"))
	return MOVEMENT_LAYER_SCRIPT.DEFAULT_ALTITUDE_BAND


func _invalid_projection(reason: String) -> Dictionary:
	return {
		"valid": false,
		"reason": reason,
	}
