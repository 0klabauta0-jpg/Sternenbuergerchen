class_name AreaOrderResolver
extends RefCounted

const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const DEFAULT_AREA_RADIUS_TILES: int = 1
const ATTACK_APPROACH_STANDOFF: float = 116.0


static func build_area_order(
	fireteam_id: String,
	command_type: String,
	start_world_position: Vector2,
	end_world_position: Vector2,
	terrain_registry,
	sequence_index: int
):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var tile_positions: Array = build_rect_tile_positions(start_world_position, end_world_position, terrain_registry)
	var center_position: Vector2 = _resolve_center_position(tile_positions, start_world_position.lerp(end_world_position, 0.5), terrain_registry)
	var area_order = AREA_ORDER_SCRIPT.new()
	area_order.area_order_id = "area_%04d" % maxi(sequence_index, 0)
	area_order.fireteam_id = normalized_fireteam_id
	area_order.command_type = _normalize_command_type(command_type)
	area_order.tile_positions = tile_positions
	area_order.center_position = center_position
	area_order.created_at_order_index = maxi(sequence_index, 0)
	area_order.status = AREA_ORDER_SCRIPT.STATUS_PENDING
	area_order.world_polygon = _build_world_polygon(tile_positions, center_position, terrain_registry)
	area_order.metadata = {
		"tile_count": tile_positions.size(),
	}
	return area_order if area_order.is_valid() else null


static func build_rect_tile_positions(start_world_position: Vector2, end_world_position: Vector2, terrain_registry) -> Array:
	var result: Array = []
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return result
	var from_grid: Vector2i = terrain_registry.call("world_to_grid", start_world_position)
	var to_grid: Vector2i = terrain_registry.call("world_to_grid", end_world_position)
	var min_x: int = mini(from_grid.x, to_grid.x)
	var max_x: int = maxi(from_grid.x, to_grid.x)
	var min_y: int = mini(from_grid.y, to_grid.y)
	var max_y: int = maxi(from_grid.y, to_grid.y)
	if from_grid == to_grid:
		min_x -= DEFAULT_AREA_RADIUS_TILES
		max_x += DEFAULT_AREA_RADIUS_TILES
		min_y -= DEFAULT_AREA_RADIUS_TILES
		max_y += DEFAULT_AREA_RADIUS_TILES

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var grid_position := Vector2i(x, y)
			if terrain_registry.has_method("get_tile_at_grid") and terrain_registry.call("get_tile_at_grid", grid_position) == null:
				continue
			result.append(grid_position)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	)
	return result


static func resolve_defend_slots(area_order_dict: Dictionary, units: Array, leader, terrain_registry) -> Dictionary:
	var area_order = AREA_ORDER_SCRIPT.call("from_dict", area_order_dict)
	if area_order == null or not bool(area_order.call("is_valid")):
		return {}
	var member_records: Array = _build_member_records(units, leader)
	if member_records.is_empty():
		return {}
	var candidate_records: Array = _build_area_candidate_records(area_order.tile_positions, terrain_registry)
	if candidate_records.is_empty():
		candidate_records.append({
			"grid_position": Vector2i.ZERO,
			"world_position": area_order.center_position,
			"cover_value": 0,
			"distance_to_center": 0.0,
		})

	var center_position: Vector2 = area_order.center_position
	candidate_records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var cover_a: int = int(a.get("cover_value", 0))
		var cover_b: int = int(b.get("cover_value", 0))
		if cover_a != cover_b:
			return cover_a > cover_b
		var angle_a: float = (Vector2(a.get("world_position", center_position)) - center_position).angle()
		var angle_b: float = (Vector2(b.get("world_position", center_position)) - center_position).angle()
		if absf(angle_a - angle_b) > 0.001:
			return angle_a < angle_b
		return float(a.get("distance_to_center", 0.0)) < float(b.get("distance_to_center", 0.0))
	)

	var assignments: Array = []
	var used_indices: Dictionary = {}
	for member_index in range(member_records.size()):
		var record: Dictionary = member_records[member_index]
		var candidate_index: int = _select_defend_candidate_index(member_index, member_records.size(), candidate_records, used_indices, bool(record.get("is_leader", false)), center_position)
		used_indices[candidate_index] = true
		var candidate: Dictionary = Dictionary(candidate_records[candidate_index])
		assignments.append({
			"unit_id": String(record.get("unit_id", "")),
			"team_id": String(record.get("team_id", "")),
			"is_leader": bool(record.get("is_leader", false)),
			"target_position": Vector2(candidate.get("world_position", center_position)),
			"grid_position": candidate.get("grid_position", Vector2i.ZERO),
			"cover_value": int(candidate.get("cover_value", 0)),
			"role": "anker" if bool(record.get("is_leader", false)) else "sicherung",
		})

	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": String(area_order.command_type),
		"center_position": center_position,
		"tile_count": area_order.tile_positions.size(),
		"assignments": assignments,
		"security_mode": "360",
		"status": "HALTET GEBIET",
	}


static func resolve_attack_approach(area_order_dict: Dictionary, anchor_position: Vector2, terrain_registry, approach_name: String = "") -> Dictionary:
	var area_order = AREA_ORDER_SCRIPT.call("from_dict", area_order_dict)
	if area_order == null or not bool(area_order.call("is_valid")):
		return {}
	var center_position: Vector2 = area_order.center_position
	var approach_direction: Vector2 = anchor_position - center_position
	if approach_direction.length_squared() <= 0.001:
		approach_direction = _direction_from_approach_name(approach_name)
	if approach_direction.length_squared() <= 0.001:
		approach_direction = Vector2(-1.0, -0.5)
	approach_direction = approach_direction.normalized()
	var requested_approach_position: Vector2 = center_position + approach_direction * ATTACK_APPROACH_STANDOFF
	var resolved_approach_position: Vector2 = requested_approach_position
	var resolved_grid: Variant = null
	if terrain_registry != null and terrain_registry.has_method("get_nearest_walkable_grid") and terrain_registry.has_method("grid_to_world"):
		resolved_grid = terrain_registry.call("get_nearest_walkable_grid", requested_approach_position)
		if typeof(resolved_grid) == TYPE_VECTOR2I:
			resolved_approach_position = terrain_registry.call("grid_to_world", resolved_grid)
	var approach_label: String = _build_compass_label(center_position, resolved_approach_position)
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": String(area_order.command_type),
		"center_position": center_position,
		"requested_approach_position": requested_approach_position,
		"approach_position": resolved_approach_position,
		"approach_grid": resolved_grid,
		"approach_label": approach_label,
		"tile_count": area_order.tile_positions.size(),
	}


static func is_world_position_inside_area(area_order_dict: Dictionary, world_position: Vector2, terrain_registry) -> bool:
	var area_order = AREA_ORDER_SCRIPT.call("from_dict", area_order_dict)
	if area_order == null or not bool(area_order.call("is_valid")):
		return false
	if terrain_registry != null and terrain_registry.has_method("world_to_grid"):
		var grid_position: Vector2i = terrain_registry.call("world_to_grid", world_position)
		for tile_position in area_order.tile_positions:
			if Vector2i(tile_position) == grid_position:
				return true
		return false
	var bounds: Rect2 = Rect2(area_order.center_position, Vector2.ZERO)
	for point in area_order.world_polygon:
		bounds = bounds.expand(point)
	return bounds.has_point(world_position)


static func describe_area_order(area_order_dict: Dictionary) -> Dictionary:
	var area_order = AREA_ORDER_SCRIPT.call("from_dict", area_order_dict)
	if area_order == null or not bool(area_order.call("is_valid")):
		return {}
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": String(area_order.command_type),
		"status": String(area_order.status),
		"center_position": area_order.center_position,
		"tile_count": area_order.tile_positions.size(),
		"world_polygon": area_order.world_polygon,
	}


static func _normalize_command_type(command_type: String) -> String:
	var normalized: String = command_type.strip_edges().to_lower()
	if AREA_ORDER_SCRIPT.ALLOWED_COMMAND_TYPES.has(normalized):
		return normalized
	return AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND


static func _resolve_center_position(tile_positions: Array, fallback: Vector2, terrain_registry) -> Vector2:
	if tile_positions.is_empty() or terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return fallback
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for tile_position in tile_positions:
		sum += terrain_registry.call("grid_to_world", Vector2i(tile_position))
		count += 1
	if count <= 0:
		return fallback
	return sum / float(count)


static func _build_world_polygon(tile_positions: Array, center_position: Vector2, terrain_registry) -> PackedVector2Array:
	if tile_positions.is_empty() or terrain_registry == null or not terrain_registry.has_method("grid_to_world"):
		return PackedVector2Array([
			center_position + Vector2(-48.0, -24.0),
			center_position + Vector2(48.0, -24.0),
			center_position + Vector2(48.0, 24.0),
			center_position + Vector2(-48.0, 24.0),
		])
	var min_x: int = 2147483647
	var min_y: int = 2147483647
	var max_x: int = -2147483648
	var max_y: int = -2147483648
	for tile_position in tile_positions:
		var grid_position := Vector2i(tile_position)
		min_x = mini(min_x, grid_position.x)
		min_y = mini(min_y, grid_position.y)
		max_x = maxi(max_x, grid_position.x)
		max_y = maxi(max_y, grid_position.y)
	var corners: Array = [
		terrain_registry.call("grid_to_world", Vector2i(min_x, min_y)),
		terrain_registry.call("grid_to_world", Vector2i(max_x, min_y)),
		terrain_registry.call("grid_to_world", Vector2i(max_x, max_y)),
		terrain_registry.call("grid_to_world", Vector2i(min_x, max_y)),
	]
	return PackedVector2Array(corners)


static func _build_area_candidate_records(tile_positions: Array, terrain_registry) -> Array:
	var result: Array = []
	for tile_position in tile_positions:
		var grid_position := Vector2i(tile_position)
		var tile_data = terrain_registry.call("get_tile_at_grid", grid_position) if terrain_registry != null and terrain_registry.has_method("get_tile_at_grid") else null
		if tile_data != null and not bool(tile_data.walkable):
			continue
		var world_position: Vector2 = terrain_registry.call("grid_to_world", grid_position) if terrain_registry != null and terrain_registry.has_method("grid_to_world") else Vector2(grid_position)
		var cover_value: int = int(tile_data.cover_value) if tile_data != null else 0
		result.append({
			"grid_position": grid_position,
			"world_position": world_position,
			"cover_value": cover_value,
			"distance_to_center": 0.0,
		})
	var center_position: Vector2 = _resolve_center_position(tile_positions, Vector2.ZERO, terrain_registry)
	for index in range(result.size()):
		var record: Dictionary = Dictionary(result[index])
		record["distance_to_center"] = center_position.distance_to(Vector2(record.get("world_position", center_position)))
		result[index] = record
	return result


static func _select_defend_candidate_index(
	member_index: int,
	member_count: int,
	candidate_records: Array,
	used_indices: Dictionary,
	is_leader: bool,
	center_position: Vector2
) -> int:
	if candidate_records.is_empty():
		return 0
	var best_index: int = 0
	if is_leader:
		var best_distance: float = INF
		for index in range(candidate_records.size()):
			if used_indices.has(index):
				continue
			var distance: float = center_position.distance_to(Vector2(Dictionary(candidate_records[index]).get("world_position", center_position)))
			if distance >= best_distance:
				continue
			best_distance = distance
			best_index = index
		return best_index
	var preferred_index: int = int(roundi(float(member_index) * float(maxi(candidate_records.size() - 1, 0)) / float(maxi(member_count - 1, 1))))
	for offset in range(candidate_records.size()):
		var forward_index: int = (preferred_index + offset) % candidate_records.size()
		if not used_indices.has(forward_index):
			return forward_index
	return preferred_index % candidate_records.size()


static func _build_member_records(units: Array, leader) -> Array:
	var leader_unit_id: String = String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else ""
	var result: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		result.append({
			"unit": unit,
			"unit_id": unit_id,
			"team_id": String(unit.call("get_team_id")) if unit.has_method("get_team_id") else "",
			"is_leader": unit_id == leader_unit_id,
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("is_leader", false)) != bool(b.get("is_leader", false)):
			return bool(a.get("is_leader", false))
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	return result


static func _direction_from_approach_name(approach_name: String) -> Vector2:
	match approach_name.strip_edges().to_upper():
		"NE":
			return Vector2(1.0, -0.55)
		"SW":
			return Vector2(-1.0, 0.55)
		"SE":
			return Vector2(1.0, 0.55)
		_:
			return Vector2(-1.0, -0.55)


static func _build_compass_label(center_position: Vector2, approach_position: Vector2) -> String:
	var delta: Vector2 = approach_position - center_position
	if delta.length_squared() <= 0.001:
		return "--"
	var vertical: String = "N" if delta.y < 0.0 else "S"
	var horizontal: String = "W" if delta.x < 0.0 else "E"
	return "%s%s" % [vertical, horizontal]
