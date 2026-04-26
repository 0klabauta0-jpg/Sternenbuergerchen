class_name AreaOrderResolver
extends RefCounted

const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")

const FALLBACK_SPACING: float = 42.0


static func resolve_defend_area(area_order_data, units: Array, leader = null, terrain_registry = null) -> Dictionary:
	var area_order = _coerce_area_order(area_order_data)
	if area_order == null or not area_order.is_valid():
		return {}
	if String(area_order.command_type) != AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
		return {}
	var members: Array = _build_fit_members(units, leader)
	if members.is_empty():
		return {}
	var center_position: Vector2 = Vector2(area_order.center_position)
	var candidates: Array = _build_candidates(area_order, center_position, terrain_registry, members.size())
	if candidates.is_empty():
		return {}
	var assignments: Array = _assign_members_to_candidates(members, candidates, center_position)
	if assignments.is_empty():
		return {}
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": String(area_order.command_type),
		"center_position": center_position,
		"leader_unit_id": String(members[0].get("unit_id", "")),
		"assignments": assignments,
	}


static func _coerce_area_order(area_order_data):
	if area_order_data == null:
		return null
	if area_order_data is RefCounted and area_order_data.has_method("is_valid") and area_order_data.has_method("to_dict"):
		return area_order_data
	if typeof(area_order_data) == TYPE_DICTIONARY:
		return AREA_ORDER_SCRIPT.call("from_dict", Dictionary(area_order_data))
	return null


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


static func _assign_members_to_candidates(members: Array, candidates: Array, center_position: Vector2) -> Array:
	var assignments: Array = []
	var used_indices: Dictionary = {}
	for member_index in range(members.size()):
		var member: Dictionary = Dictionary(members[member_index])
		var candidate_index: int = _pick_candidate_index(member_index, candidates, used_indices, center_position)
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


static func _pick_candidate_index(member_index: int, candidates: Array, used_indices: Dictionary, center_position: Vector2) -> int:
	if candidates.is_empty():
		return -1
	if member_index == 0:
		var best_leader_index: int = -1
		var best_leader_score: float = -INF
		for index in range(candidates.size()):
			var candidate: Dictionary = Dictionary(candidates[index])
			var score: float = (float(candidate.get("cover_score", 0.0)) * 40.0) - Vector2(candidate.get("target_position", center_position)).distance_to(center_position)
			if score <= best_leader_score:
				continue
			best_leader_score = score
			best_leader_index = index
		return best_leader_index
	for index in range(candidates.size()):
		if not used_indices.has(index):
			return index
	return member_index % candidates.size()


static func _read_skill_value(unit, method_name: String, fallback: float) -> float:
	if unit == null or not unit.has_method(method_name):
		return fallback
	return clampf(float(unit.call(method_name)), 0.0, 1.0)
