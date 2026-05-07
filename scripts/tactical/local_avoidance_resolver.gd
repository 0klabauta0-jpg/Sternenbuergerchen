class_name LocalAvoidanceResolver
extends RefCounted

const DEFAULT_AGENT_RADIUS: float = 18.0
const DEFAULT_MINIMUM_SPACING: float = DEFAULT_AGENT_RADIUS * 2.0
const DEFAULT_NEIGHBOR_RADIUS: float = 56.0
const DEFAULT_CELL_SIZE: float = 64.0
const DEFAULT_MAX_NEIGHBORS: int = 8
const SEPARATION_WEIGHT: float = 0.85
const SIDE_STEP_WEIGHT: float = 0.35

var cell_size: float = DEFAULT_CELL_SIZE
var _agents_by_id: Dictionary = {}
var _cell_agents: Dictionary = {}


func clear() -> void:
	_agents_by_id.clear()
	_cell_agents.clear()


static func build_spaced_line_targets(unit_ids: PackedStringArray, anchor_position: Vector2, advance_direction: Vector2, minimum_distance: float = DEFAULT_MINIMUM_SPACING) -> Dictionary:
	var result: Dictionary = {}
	var count: int = unit_ids.size()
	if count <= 0:
		return result
	var direction: Vector2 = advance_direction.normalized() if not advance_direction.is_zero_approx() else Vector2.RIGHT
	var lateral: Vector2 = direction.orthogonal()
	var spacing: float = maxf(minimum_distance, 1.0)
	var centered_offset: float = float(count - 1) * 0.5
	for index in range(count):
		var unit_id: String = String(unit_ids[index]).strip_edges()
		if unit_id.is_empty():
			continue
		result[unit_id] = anchor_position + lateral * ((float(index) - centered_offset) * spacing)
	return result


func build_from_units(units: Array, default_radius: float = DEFAULT_AGENT_RADIUS, next_cell_size: float = DEFAULT_CELL_SIZE) -> void:
	clear()
	cell_size = maxf(next_cell_size, 1.0)
	var sorted_units: Array = units.duplicate()
	sorted_units.sort_custom(_sort_units_by_id)
	for unit in sorted_units:
		if not (unit is Node2D):
			continue
		var unit_id: String = _extract_unit_id(unit)
		if unit_id.is_empty():
			continue
		register_agent(unit_id, (unit as Node2D).global_position, default_radius)


func register_agent(unit_id: String, position: Vector2, radius: float = DEFAULT_AGENT_RADIUS) -> void:
	var normalized_id: String = unit_id.strip_edges()
	if normalized_id.is_empty():
		return
	var agent: Dictionary = {
		"unit_id": normalized_id,
		"position": position,
		"radius": maxf(radius, 0.1),
		"cell": _cell_for_position(position),
	}
	_agents_by_id[normalized_id] = agent
	_append_agent_to_cell(normalized_id, Vector2i(agent["cell"]))


func update_agent_position(unit_id: String, position: Vector2) -> void:
	var normalized_id: String = unit_id.strip_edges()
	if normalized_id.is_empty() or not _agents_by_id.has(normalized_id):
		return
	var agent: Dictionary = Dictionary(_agents_by_id[normalized_id])
	var old_cell: Vector2i = Vector2i(agent.get("cell", _cell_for_position(position)))
	var next_cell: Vector2i = _cell_for_position(position)
	if old_cell != next_cell:
		_remove_agent_from_cell(normalized_id, old_cell)
		_append_agent_to_cell(normalized_id, next_cell)
	agent["position"] = position
	agent["cell"] = next_cell
	_agents_by_id[normalized_id] = agent


func solve_velocity(
	unit_id: String,
	position: Vector2,
	desired_velocity: Vector2,
	max_speed: float,
	neighbor_radius: float = DEFAULT_NEIGHBOR_RADIUS,
	max_neighbors: int = DEFAULT_MAX_NEIGHBORS
) -> Dictionary:
	var normalized_id: String = unit_id.strip_edges()
	var neighbors: Array = get_neighbors(position, neighbor_radius, normalized_id, max_neighbors)
	var safe_velocity: Vector2 = desired_velocity
	var correction: Vector2 = Vector2.ZERO
	var collision_risk_count: int = 0
	var agent_radius: float = _get_agent_radius(normalized_id)

	for neighbor_variant in neighbors:
		var neighbor: Dictionary = Dictionary(neighbor_variant)
		var neighbor_position: Vector2 = Vector2(neighbor.get("position", position))
		var offset: Vector2 = position - neighbor_position
		var distance: float = offset.length()
		if distance <= 0.001:
			offset = _deterministic_axis(normalized_id, String(neighbor.get("unit_id", "")))
			distance = 0.001
		var neighbor_agent_radius: float = float(neighbor.get("radius", agent_radius))
		var combined_radius: float = agent_radius + neighbor_agent_radius
		var influence_radius: float = maxf(combined_radius * 1.75, combined_radius + 1.0)
		if distance > influence_radius:
			continue
		if distance < combined_radius:
			collision_risk_count += 1
		var strength: float = clampf((influence_radius - distance) / influence_radius, 0.0, 1.0)
		var away: Vector2 = offset.normalized()
		var side_step: Vector2 = Vector2.ZERO
		if not desired_velocity.is_zero_approx():
			var side_sign: float = -1.0 if normalized_id < String(neighbor.get("unit_id", "")) else 1.0
			side_step = desired_velocity.normalized().orthogonal() * side_sign
		correction += (away * SEPARATION_WEIGHT + side_step * SIDE_STEP_WEIGHT) * strength * max_speed

	safe_velocity += correction
	if safe_velocity.length() > max_speed:
		safe_velocity = safe_velocity.normalized() * max_speed

	return {
		"unit_id": normalized_id,
		"desired_velocity": desired_velocity,
		"safe_velocity": safe_velocity,
		"correction_velocity": safe_velocity - desired_velocity,
		"neighbor_count": neighbors.size(),
		"collision_risk_count": collision_risk_count,
		"neighbors": neighbors,
	}


func resolve_minimum_spacing_positions(
	units: Array,
	minimum_distance: float = DEFAULT_MINIMUM_SPACING,
	terrain_registry = null,
	max_iterations: int = 4
) -> Dictionary:
	var sorted_units: Array = units.duplicate()
	sorted_units.sort_custom(_sort_units_by_id)
	var positions_by_unit_id: Dictionary = {}
	var initial_positions_by_unit_id: Dictionary = {}
	var active_unit_ids: Array = []
	for unit in sorted_units:
		if not (unit is Node2D):
			continue
		var unit_id: String = _extract_unit_id(unit)
		if unit_id.is_empty():
			continue
		active_unit_ids.append(unit_id)
		positions_by_unit_id[unit_id] = (unit as Node2D).global_position
		initial_positions_by_unit_id[unit_id] = (unit as Node2D).global_position

	var resolved_minimum_distance: float = maxf(minimum_distance, 0.0)
	var blocked_pairs: Array = []
	var resolved_pair_count: int = 0
	var iteration_count: int = maxi(max_iterations, 0)
	for _iteration in range(iteration_count):
		var moved_this_iteration: bool = false
		for index_a in range(active_unit_ids.size()):
			for index_b in range(index_a + 1, active_unit_ids.size()):
				var unit_id_a: String = String(active_unit_ids[index_a])
				var unit_id_b: String = String(active_unit_ids[index_b])
				var position_a: Vector2 = Vector2(positions_by_unit_id.get(unit_id_a, Vector2.ZERO))
				var position_b: Vector2 = Vector2(positions_by_unit_id.get(unit_id_b, Vector2.ZERO))
				var delta: Vector2 = position_b - position_a
				var distance: float = delta.length()
				if distance >= resolved_minimum_distance - 0.001:
					continue
				var axis: Vector2 = delta.normalized() if distance > 0.001 else _deterministic_pair_axis(unit_id_a, unit_id_b)
				var overlap: float = resolved_minimum_distance - distance
				var move_a: Vector2 = -axis * overlap * 0.5
				var move_b: Vector2 = axis * overlap * 0.5
				var candidate_a: Vector2 = position_a + move_a
				var candidate_b: Vector2 = position_b + move_b
				var moved_pair: bool = false
				if _is_position_walkable(candidate_a, terrain_registry) and _is_position_walkable(candidate_b, terrain_registry):
					positions_by_unit_id[unit_id_a] = candidate_a
					positions_by_unit_id[unit_id_b] = candidate_b
					moved_pair = true
				else:
					var candidate_a_full: Vector2 = position_a - axis * overlap
					var candidate_b_full: Vector2 = position_b + axis * overlap
					if _is_position_walkable(candidate_a_full, terrain_registry):
						positions_by_unit_id[unit_id_a] = candidate_a_full
						moved_pair = true
					elif _is_position_walkable(candidate_b_full, terrain_registry):
						positions_by_unit_id[unit_id_b] = candidate_b_full
						moved_pair = true
				if moved_pair:
					moved_this_iteration = true
					resolved_pair_count += 1
				else:
					blocked_pairs.append({
						"unit_id_a": unit_id_a,
						"unit_id_b": unit_id_b,
						"distance": distance,
					})
		if not moved_this_iteration:
			break

	var moved_unit_ids: Array = []
	for unit_id_variant in active_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var initial_position: Vector2 = Vector2(initial_positions_by_unit_id.get(unit_id, Vector2.ZERO))
		var resolved_position: Vector2 = Vector2(positions_by_unit_id.get(unit_id, initial_position))
		if initial_position.distance_to(resolved_position) > 0.001:
			moved_unit_ids.append(unit_id)
	moved_unit_ids.sort()

	return {
		"positions_by_unit_id": positions_by_unit_id.duplicate(true),
		"moved_unit_ids": moved_unit_ids,
		"active_unit_ids": active_unit_ids,
		"minimum_distance": resolved_minimum_distance,
		"minimum_distance_after": _calculate_minimum_distance_between_positions(positions_by_unit_id),
		"resolved_pair_count": resolved_pair_count,
		"blocked_pair_count": blocked_pairs.size(),
		"blocked_pairs": blocked_pairs,
	}


func get_neighbors(position: Vector2, radius: float, exclude_unit_id: String = "", max_neighbors: int = DEFAULT_MAX_NEIGHBORS) -> Array:
	var result: Array = []
	var center_cell: Vector2i = _cell_for_position(position)
	var cell_radius: int = maxi(1, ceili(radius / cell_size))
	for x in range(center_cell.x - cell_radius, center_cell.x + cell_radius + 1):
		for y in range(center_cell.y - cell_radius, center_cell.y + cell_radius + 1):
			var cell := Vector2i(x, y)
			for unit_id_variant in Array(_cell_agents.get(cell, [])):
				var unit_id: String = String(unit_id_variant)
				if unit_id == exclude_unit_id or not _agents_by_id.has(unit_id):
					continue
				var agent: Dictionary = Dictionary(_agents_by_id[unit_id])
				var agent_position: Vector2 = Vector2(agent.get("position", position))
				if agent_position.distance_to(position) > radius:
					continue
				result.append(agent.duplicate(true))
	result.sort_custom(_sort_neighbor_entries)
	if max_neighbors >= 0 and result.size() > max_neighbors:
		result = result.slice(0, max_neighbors)
	return result


func _append_agent_to_cell(unit_id: String, cell: Vector2i) -> void:
	var entries: Array = Array(_cell_agents.get(cell, []))
	if not entries.has(unit_id):
		entries.append(unit_id)
	entries.sort()
	_cell_agents[cell] = entries


func _remove_agent_from_cell(unit_id: String, cell: Vector2i) -> void:
	var entries: Array = Array(_cell_agents.get(cell, []))
	entries.erase(unit_id)
	if entries.is_empty():
		_cell_agents.erase(cell)
	else:
		_cell_agents[cell] = entries


func _cell_for_position(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.y / cell_size))


func _get_agent_radius(unit_id: String) -> float:
	if _agents_by_id.has(unit_id):
		return float(Dictionary(_agents_by_id[unit_id]).get("radius", DEFAULT_AGENT_RADIUS))
	return DEFAULT_AGENT_RADIUS


func _sort_units_by_id(a, b) -> bool:
	return _extract_unit_id(a) < _extract_unit_id(b)


func _sort_neighbor_entries(a: Dictionary, b: Dictionary) -> bool:
	var unit_id_a: String = String(a.get("unit_id", ""))
	var unit_id_b: String = String(b.get("unit_id", ""))
	return unit_id_a < unit_id_b


func _extract_unit_id(unit) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return ""


func _deterministic_axis(unit_id: String, neighbor_id: String) -> Vector2:
	return Vector2.UP if unit_id < neighbor_id else Vector2.DOWN


func _deterministic_pair_axis(unit_id_a: String, unit_id_b: String) -> Vector2:
	var pair_key: String = "%s:%s" % [unit_id_a, unit_id_b]
	var bytes: PackedByteArray = pair_key.to_utf8_buffer()
	var seed: int = 17
	for value in bytes:
		seed = int((seed * 31 + int(value)) % 360)
	var angle: float = deg_to_rad(float(seed))
	var axis := Vector2(cos(angle), sin(angle))
	if axis.is_zero_approx():
		return Vector2.RIGHT
	return axis.normalized()


func _is_position_walkable(position: Vector2, terrain_registry) -> bool:
	if terrain_registry == null:
		return true
	if not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("is_walkable"):
		return true
	return bool(terrain_registry.call("is_walkable", terrain_registry.call("world_to_grid", position)))


func _calculate_minimum_distance_between_positions(positions_by_unit_id: Dictionary) -> float:
	var unit_ids: Array = positions_by_unit_id.keys()
	unit_ids.sort()
	if unit_ids.size() < 2:
		return INF
	var minimum_distance: float = INF
	for index_a in range(unit_ids.size()):
		for index_b in range(index_a + 1, unit_ids.size()):
			var position_a: Vector2 = Vector2(positions_by_unit_id.get(unit_ids[index_a], Vector2.ZERO))
			var position_b: Vector2 = Vector2(positions_by_unit_id.get(unit_ids[index_b], Vector2.ZERO))
			minimum_distance = minf(minimum_distance, position_a.distance_to(position_b))
	return minimum_distance
