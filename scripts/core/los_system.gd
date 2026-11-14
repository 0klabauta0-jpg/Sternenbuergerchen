class_name LineOfSightSystem
extends RefCounted

const TERRAIN_TRUTH_AUDIT_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_truth_audit.gd")
const DEFAULT_MAX_RANGE: float = 320.0
const NO_BLOCKER_GRID := Vector2i(2147483647, 2147483647)
const HEX_GRID_SCRIPT = preload("res://scripts/terrain/hex_grid.gd")

var _los_step_buffer: Array[Vector2i] = []
var _native_visibility_enabled := true
var _native_visibility_checked := false
var _native_visibility: RefCounted
var _native_visibility_calls := 0
var _native_visibility_fallbacks := 0


func set_native_visibility_enabled(enabled: bool) -> void:
	# Developer/reference switch; no terrain or result state is cached here.
	_native_visibility_enabled = enabled


func get_native_visibility_snapshot() -> Dictionary:
	return {"enabled": _native_visibility_enabled, "available": _native_visibility != null,
		"native_calls": _native_visibility_calls, "fallback_calls": _native_visibility_fallbacks,
		"kernel": "stateless_hex_line", "retained_terrain_cells": 0}


func _try_native_hex_line(source: Vector2i, target: Vector2i, out: Array[Vector2i]) -> bool:
	if not _native_visibility_enabled:
		return false
	if not _native_visibility_checked:
		_native_visibility_checked = true
		if ClassDB.class_exists("NativeVisibilityKernel"):
			var candidate = ClassDB.instantiate("NativeVisibilityKernel")
			if candidate is RefCounted and candidate.has_method("build_hex_line"):
				_native_visibility = candidate
	if _native_visibility != null:
		var result: Variant = _native_visibility.call("build_hex_line", source, target)
		if result is Array and not result.is_empty() and result.front() == source and result.back() == target:
			out.assign(result)
			_native_visibility_calls += 1
			return true
	_native_visibility_fallbacks += 1
	return false


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
	var endpoint_heights := Vector2(float(terrain_registry.call("get_height_at_world", source_position)), float(terrain_registry.call("get_height_at_world", target_position)))
	return find_first_blocker_grid(source_grid, target_grid, terrain_registry, source_grid_float, target_grid_float, false, endpoint_heights) == NO_BLOCKER_GRID


## Effective terrain reader shared by runtime LOS and read-only aim previews.
## Runtime excludes the target's own tile; previews may clip at their endpoint.
func find_first_blocker_grid(source_grid: Vector2i, target_grid: Vector2i, terrain_reader,
		source_grid_float: Vector2 = Vector2.INF, target_grid_float: Vector2 = Vector2.INF,
		include_target: bool = false, endpoint_heights: Vector2 = Vector2.INF) -> Vector2i:
	if terrain_reader == null:
		return NO_BLOCKER_GRID
	if not source_grid_float.is_finite(): source_grid_float = Vector2(source_grid)
	if not target_grid_float.is_finite(): target_grid_float = Vector2(target_grid)
	var source_tile = terrain_reader.call("get_tile_at_grid", source_grid)
	var target_tile = terrain_reader.call("get_tile_at_grid", target_grid)
	var source_height: float = float(source_tile.height_level) if source_tile != null else 0.0
	var target_height: float = float(target_tile.height_level) if target_tile != null else 0.0
	if endpoint_heights.is_finite():
		# Explicit Hex ramps stand at half-levels; rounding changes occlusion.
		source_height = endpoint_heights.x
		target_height = endpoint_heights.y
	var hex_grid: bool = _uses_hex_grid(terrain_reader)
	_build_grid_line_into(source_grid, target_grid, _los_step_buffer, terrain_reader)
	for stepped_grid in _los_step_buffer:
		if stepped_grid == source_grid or (stepped_grid == target_grid and not include_target):
			continue
		var tile_data = terrain_reader.call("get_tile_at_grid", stepped_grid)
		if tile_data == null:
			continue
		var blocks_los: bool = bool(tile_data.blocks_los)
		if terrain_reader.has_method("blocks_los_at_grid"):
			blocks_los = bool(terrain_reader.call("blocks_los_at_grid", stepped_grid))
		if not blocks_los:
			continue
		var object_height: int = int(tile_data.object_height)
		if terrain_reader.has_method("get_object_height_at_grid"):
			object_height = int(terrain_reader.call("get_object_height_at_grid", stepped_grid))
		var blocker_height: int = int(tile_data.height_level) + object_height
		if blocker_height >= source_height and blocker_height >= target_height:
			if not hex_grid and _tile_uses_wall_segment_los(tile_data):
				if not bool(TERRAIN_TRUTH_AUDIT_SCRIPT.call("does_tile_wall_block_los", tile_data, source_grid_float, target_grid_float)):
					continue
			return stepped_grid
	return NO_BLOCKER_GRID


func uses_wall_segment_los() -> bool:
	return true


func _build_grid_line(source_grid: Vector2i, target_grid: Vector2i) -> Array[Vector2i]:
	var stepped_grids: Array[Vector2i] = []
	_build_grid_line_into(source_grid, target_grid, stepped_grids)
	return stepped_grids


func _build_grid_line_into(source_grid: Vector2i, target_grid: Vector2i, out: Array[Vector2i], terrain_registry = null) -> void:
	out.clear()
	if _uses_hex_grid(terrain_registry):
		if _try_native_hex_line(source_grid, target_grid, out):
			return
		out.assign(HEX_GRID_SCRIPT.line(source_grid, target_grid))
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
