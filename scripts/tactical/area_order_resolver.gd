class_name AreaOrderResolver
extends RefCounted

const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")

const FALLBACK_SPACING: float = 42.0
const ATTACK_APPROACH_STANDOFF: float = 64.0
const ATTACK_APPROACH_MIN_RADIUS: float = 48.0
const ATTACK_BUDDY_SPACING: float = 24.0
const ATTACK_BUDDY_PAIR_SPACING: float = 46.0
const ATTACK_BUDDY_ROW_SPACING: float = 24.0


static func resolve_defend_area(area_order_data, units: Array, leader = null, terrain_registry = null) -> Dictionary:
	var area_order = _coerce_area_order(area_order_data)
	if area_order == null or not area_order.is_valid():
		return {}
	if String(area_order.command_type) != AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
		return {}
	return _resolve_area_hold_positions(area_order, units, leader, terrain_registry, String(area_order.command_type))


static func resolve_occupy_area(area_order_data, units: Array, leader = null, terrain_registry = null) -> Dictionary:
	var area_order = _coerce_area_order(area_order_data)
	if area_order == null or not area_order.is_valid():
		return {}
	return _resolve_area_hold_positions(area_order, units, leader, terrain_registry, String(area_order.command_type))


static func _resolve_area_hold_positions(area_order, units: Array, leader, terrain_registry, command_type: String) -> Dictionary:
	var members: Array = _build_fit_members(units, leader)
	if members.is_empty():
		return {}
	var center_position: Vector2 = Vector2(area_order.center_position)
	var candidates: Array = _build_candidates(area_order, center_position, terrain_registry, members.size())
	if candidates.is_empty():
		return {}
	var assignments: Array = _assign_members_to_candidates(members, candidates, center_position, terrain_registry)
	if assignments.is_empty():
		return {}
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": command_type,
		"center_position": center_position,
		"leader_unit_id": String(members[0].get("unit_id", "")),
		"assignments": assignments,
	}


static func resolve_attack_area(area_order_data, units: Array, leader = null, terrain_registry = null) -> Dictionary:
	var area_order = _coerce_area_order(area_order_data)
	if area_order == null or not area_order.is_valid():
		return {}
	var command_type: String = String(area_order.command_type)
	if not _is_attack_area_command_type(command_type):
		return {}
	var members: Array = _build_fit_members(units, leader)
	if members.is_empty():
		return {}
	var center_position: Vector2 = Vector2(area_order.center_position)
	var origin_position: Vector2 = _resolve_origin_position(members, leader)
	var area_radius: float = _estimate_area_radius(area_order, center_position)
	var approach_position: Vector2 = _resolve_approach_position(center_position, origin_position, area_radius, terrain_registry)
	var assignments: Array = _build_attack_assignments(members, approach_position, center_position)
	if assignments.is_empty():
		return {}
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": command_type,
		"center_position": center_position,
		"approach_position": approach_position,
		"area_radius": area_radius,
		"leader_unit_id": String(members[0].get("unit_id", "")),
		"assignments": assignments,
		"target_area": _build_area_context(area_order, center_position, area_radius),
	}


static func is_position_in_area_context(area_context: Dictionary, world_position: Vector2) -> bool:
	var polygon: PackedVector2Array = PackedVector2Array(area_context.get("world_polygon", PackedVector2Array()))
	if polygon.size() >= 3:
		return Geometry2D.is_point_in_polygon(world_position, polygon)
	var center_position: Vector2 = Vector2(area_context.get("center_position", Vector2.ZERO))
	var radius: float = maxf(float(area_context.get("area_radius", 0.0)), ATTACK_APPROACH_MIN_RADIUS)
	return world_position.distance_to(center_position) <= radius


static func is_position_in_area_order(area_order_data, world_position: Vector2) -> bool:
	var area_order = _coerce_area_order(area_order_data)
	if area_order == null or not area_order.is_valid():
		return false
	var center_position: Vector2 = Vector2(area_order.center_position)
	return is_position_in_area_context(_build_area_context(area_order, center_position, _estimate_area_radius(area_order, center_position)), world_position)


static func _coerce_area_order(area_order_data):
	if area_order_data == null:
		return null
	if area_order_data is RefCounted and area_order_data.has_method("is_valid") and area_order_data.has_method("to_dict"):
		return area_order_data
	if typeof(area_order_data) == TYPE_DICTIONARY:
		return AREA_ORDER_SCRIPT.call("from_dict", Dictionary(area_order_data))
	return null


static func _is_attack_area_command_type(command_type: String) -> bool:
	match command_type.strip_edges().to_lower():
		AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE, AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE, AREA_ORDER_SCRIPT.COMMAND_TYPE_FLANK:
			return true
		_:
			return false


static func _build_fit_members(units: Array, leader) -> Array:
	var leader_unit_id: String = String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else ""
	var members: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		var is_leader: bool = unit_id == leader_unit_id
		if unit.has_method("get"):
			is_leader = is_leader or bool(unit.get("is_fireteam_lead"))
		members.append({
			"unit": unit,
			"unit_id": unit_id,
			"is_leader": is_leader,
			"accuracy": _read_skill_value(unit, "get_accuracy_skill", 0.5),
		})
	members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("is_leader", false)) != bool(b.get("is_leader", false)):
			return bool(a.get("is_leader", false))
		var accuracy_a: float = float(a.get("accuracy", 0.0))
		var accuracy_b: float = float(b.get("accuracy", 0.0))
		if absf(accuracy_a - accuracy_b) > 0.0001:
			return accuracy_a > accuracy_b
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	return members


static func _resolve_origin_position(members: Array, leader) -> Vector2:
	if leader is Node2D:
		return (leader as Node2D).global_position
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for member_variant in members:
		var member: Dictionary = Dictionary(member_variant)
		var unit = member.get("unit", null)
		if not (unit is Node2D):
			continue
		sum += (unit as Node2D).global_position
		count += 1
	if count <= 0:
		return Vector2.ZERO
	return sum / float(count)


static func _build_candidates(area_order, center_position: Vector2, terrain_registry, required_count: int) -> Array:
	var candidates: Array = []
	var tile_positions: Array = Array(area_order.tile_positions)
	var tile_world_positions: Array = Array(area_order.tile_world_positions)
	for index in range(tile_positions.size()):
		var grid_position: Vector2i = Vector2i(tile_positions[index])
		var tile_data = null
		if terrain_registry != null and terrain_registry.has_method("get_tile_at_grid"):
			tile_data = terrain_registry.call("get_tile_at_grid", grid_position)
		if tile_data != null:
			if tile_data.has_method("get") and not bool(tile_data.get("walkable")):
				continue
			candidates.append(_build_candidate(grid_position, Vector2(tile_data.world_position), int(tile_data.cover_value), center_position))
			continue
		if index < tile_world_positions.size():
			candidates.append(_build_candidate(grid_position, Vector2(tile_world_positions[index]), 0, center_position))
	if candidates.is_empty() and not tile_world_positions.is_empty():
		for index in range(tile_world_positions.size()):
			candidates.append(_build_candidate(Vector2i.ZERO, Vector2(tile_world_positions[index]), 0, center_position))
	if candidates.is_empty():
		candidates = _build_fallback_candidates(center_position, maxi(required_count, 1))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a: float = float(a.get("score", 0.0))
		var score_b: float = float(b.get("score", 0.0))
		if absf(score_a - score_b) > 0.0001:
			return score_a > score_b
		return float(a.get("distance_to_center", 0.0)) < float(b.get("distance_to_center", 0.0))
	)
	return candidates


static func _estimate_area_radius(area_order, center_position: Vector2) -> float:
	var radius: float = 0.0
	for point_variant in Array(area_order.world_polygon):
		radius = maxf(radius, Vector2(point_variant).distance_to(center_position))
	for point_variant in Array(area_order.tile_world_positions):
		radius = maxf(radius, Vector2(point_variant).distance_to(center_position))
	return maxf(radius, ATTACK_APPROACH_MIN_RADIUS)


static func _resolve_approach_position(center_position: Vector2, origin_position: Vector2, area_radius: float, terrain_registry) -> Vector2:
	var direction_to_area: Vector2 = center_position - origin_position
	if direction_to_area.length() < 0.001:
		direction_to_area = Vector2.RIGHT
	else:
		direction_to_area = direction_to_area.normalized()
	var raw_position: Vector2 = center_position - (direction_to_area * (area_radius + ATTACK_APPROACH_STANDOFF))
	return _snap_to_walkable_world(raw_position, terrain_registry)


static func _snap_to_walkable_world(world_position: Vector2, terrain_registry) -> Vector2:
	if terrain_registry == null:
		return world_position
	if terrain_registry.has_method("get_nearest_walkable_grid") and terrain_registry.has_method("grid_to_world"):
		var nearest_grid: Variant = terrain_registry.call("get_nearest_walkable_grid", world_position)
		if typeof(nearest_grid) == TYPE_VECTOR2I:
			return Vector2(terrain_registry.call("grid_to_world", nearest_grid))
	if terrain_registry.has_method("get_tile_at_world"):
		var tile_data = terrain_registry.call("get_tile_at_world", world_position)
		if tile_data != null and tile_data.has_method("get") and bool(tile_data.get("walkable")):
			return Vector2(tile_data.get("world_position"))
	return world_position


static func _build_attack_assignments(members: Array, approach_position: Vector2, center_position: Vector2) -> Array:
	var assignments: Array = []
	var attack_direction: Vector2 = center_position - approach_position
	if attack_direction.length() < 0.001:
		attack_direction = Vector2.RIGHT
	else:
		attack_direction = attack_direction.normalized()
	var lateral: Vector2 = attack_direction.orthogonal().normalized()
	for member_index in range(members.size()):
		var member: Dictionary = Dictionary(members[member_index])
		var buddy_slot: Dictionary = _build_attack_buddy_slot(member_index, members.size())
		var lateral_offset: float = float(buddy_slot.get("lateral_offset", 0.0))
		var row_offset: float = float(buddy_slot.get("row_offset", 0.0))
		assignments.append({
			"unit_id": String(member.get("unit_id", "")),
			"target_position": approach_position + (lateral * lateral_offset) - (attack_direction * row_offset),
			"tile_position": Vector2i.ZERO,
			"cover_score": 0.0,
			"is_leader": bool(member.get("is_leader", false)),
			"buddy_pair_index": int(buddy_slot.get("buddy_pair_index", 0)),
			"buddy_slot_index": int(buddy_slot.get("buddy_slot_index", 0)),
		})
	return assignments


static func _build_attack_buddy_slot(member_index: int, member_count: int) -> Dictionary:
	var pair_index: int = int(member_index / 2)
	var pair_count: int = maxi(ceili(float(member_count) / 2.0), 1)
	var pair_member_count: int = mini(2, maxi(member_count - (pair_index * 2), 0))
	var buddy_slot_index: int = member_index % 2
	var pair_center_lateral: float = (float(pair_index) - (float(pair_count - 1) * 0.5)) * ATTACK_BUDDY_PAIR_SPACING
	var buddy_lateral: float = 0.0
	if pair_member_count > 1:
		buddy_lateral = (-0.5 if buddy_slot_index == 0 else 0.5) * ATTACK_BUDDY_SPACING
	return {
		"buddy_pair_index": pair_index,
		"buddy_slot_index": buddy_slot_index,
		"lateral_offset": pair_center_lateral + buddy_lateral,
		"row_offset": float(pair_index) * ATTACK_BUDDY_ROW_SPACING,
	}


static func _build_area_context(area_order, center_position: Vector2, area_radius: float) -> Dictionary:
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": String(area_order.command_type),
		"center_position": center_position,
		"area_radius": area_radius,
		"tile_positions": Array(area_order.tile_positions).duplicate(true),
		"tile_world_positions": Array(area_order.tile_world_positions).duplicate(true),
		"world_polygon": PackedVector2Array(area_order.world_polygon),
	}


static func _build_candidate(grid_position: Vector2i, world_position: Vector2, cover_value: int, center_position: Vector2) -> Dictionary:
	var distance_to_center: float = world_position.distance_to(center_position)
	var cover_score: float = clampf(float(cover_value) / 100.0, 0.0, 1.0)
	return {
		"grid_position": grid_position,
		"target_position": world_position,
		"cover_score": cover_score,
		"distance_to_center": distance_to_center,
		"score": (cover_score * 120.0) - (distance_to_center * 0.1),
	}


static func _build_fallback_candidates(center_position: Vector2, required_count: int) -> Array:
	var result: Array = [_build_candidate(Vector2i.ZERO, center_position, 0, center_position)]
	var steps: int = maxi(required_count - 1, 0)
	for index in range(steps):
		var angle: float = (TAU / float(maxi(steps, 1))) * float(index)
		result.append(_build_candidate(Vector2i.ZERO, center_position + Vector2.RIGHT.rotated(angle) * FALLBACK_SPACING, 0, center_position))
	return result


static func _assign_members_to_candidates(members: Array, candidates: Array, center_position: Vector2, terrain_registry = null) -> Array:
	var assignments: Array = []
	var used_indices: Dictionary = {}
	for member_index in range(members.size()):
		var member: Dictionary = Dictionary(members[member_index])
		var candidate_index: int = _pick_candidate_index(member_index, candidates, used_indices, center_position, member, terrain_registry)
		if candidate_index < 0:
			continue
		used_indices[candidate_index] = true
		var candidate: Dictionary = Dictionary(candidates[candidate_index])
		assignments.append({
			"unit_id": String(member.get("unit_id", "")),
			"target_position": Vector2(candidate.get("target_position", center_position)),
			"tile_position": Vector2i(candidate.get("grid_position", Vector2i.ZERO)),
			"cover_score": float(candidate.get("cover_score", 0.0)),
			"is_leader": bool(member.get("is_leader", false)),
		})
	return assignments


static func _pick_candidate_index(member_index: int, candidates: Array, used_indices: Dictionary, center_position: Vector2, member: Dictionary = {}, terrain_registry = null) -> int:
	if candidates.is_empty():
		return -1
	if member_index == 0:
		var best_leader_index: int = -1
		var best_leader_score: float = -INF
		for index in range(candidates.size()):
			var candidate: Dictionary = Dictionary(candidates[index])
			if not _is_candidate_reachable_for_member(member, candidate, terrain_registry):
				continue
			var score: float = (float(candidate.get("cover_score", 0.0)) * 40.0) - Vector2(candidate.get("target_position", center_position)).distance_to(center_position)
			if score <= best_leader_score:
				continue
			best_leader_score = score
			best_leader_index = index
		if best_leader_index >= 0:
			return best_leader_index
	for index in range(candidates.size()):
		if not used_indices.has(index) and _is_candidate_reachable_for_member(member, Dictionary(candidates[index]), terrain_registry):
			return index
	for index in range(candidates.size()):
		if not used_indices.has(index):
			return index
	return member_index % candidates.size()


static func _is_candidate_reachable_for_member(member: Dictionary, candidate: Dictionary, terrain_registry) -> bool:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("get_tile_at_grid"):
		return true
	var unit = member.get("unit", null)
	if not (unit is Node2D):
		return true
	var from_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", (unit as Node2D).global_position))
	if terrain_registry.has_method("is_walkable") and not bool(terrain_registry.call("is_walkable", from_grid)):
		var nearest_start_grid: Variant = terrain_registry.call("get_nearest_walkable_grid", (unit as Node2D).global_position) if terrain_registry.has_method("get_nearest_walkable_grid") else null
		if typeof(nearest_start_grid) != TYPE_VECTOR2I:
			return false
		from_grid = Vector2i(nearest_start_grid)
	var target_position: Vector2 = Vector2(candidate.get("target_position", Vector2.ZERO))
	var to_grid: Vector2i = Vector2i(candidate.get("grid_position", terrain_registry.call("world_to_grid", target_position)))
	var target_tile = terrain_registry.call("get_tile_at_grid", to_grid)
	if target_tile == null:
		to_grid = Vector2i(terrain_registry.call("world_to_grid", target_position))
		target_tile = terrain_registry.call("get_tile_at_grid", to_grid)
	if target_tile == null:
		return false
	if target_tile.has_method("get") and not bool(target_tile.get("walkable")):
		return false
	if from_grid == to_grid:
		return true
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	return not Array(pathfinder.call("find_path", from_grid, to_grid, terrain_registry)).is_empty()


static func _read_skill_value(unit, method_name: String, fallback: float) -> float:
	if unit == null or not unit.has_method(method_name):
		return fallback
	return clampf(float(unit.call(method_name)), 0.0, 1.0)
