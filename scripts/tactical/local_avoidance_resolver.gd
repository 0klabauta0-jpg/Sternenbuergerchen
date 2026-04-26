class_name LocalAvoidanceResolver
extends RefCounted

const DEFAULT_AGENT_RADIUS: float = 18.0
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
