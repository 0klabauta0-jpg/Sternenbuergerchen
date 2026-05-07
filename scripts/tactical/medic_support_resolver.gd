class_name MedicSupportResolver
extends RefCounted

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const DEFAULT_TILE_RANGE: int = 1
const DEFAULT_MOVE_MAX_TILE_DISTANCE: int = 3
const DEFAULT_RANGE_FALLBACK_WORLD: float = 80.0
const DEFAULT_MOVE_MAX_DISTANCE_FALLBACK_WORLD: float = 216.0
const DEFAULT_APPROACH_STANDOFF: float = 28.0
const DEFAULT_WOUNDED_THRESHOLD: float = 0.65
const DEFAULT_REMOTE_WOUNDED_THRESHOLD: float = 0.45
const ORTHOGONAL_NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]


static func build_support_actions(
	medics: Array,
	allies: Array,
	reserved_target_ids: Dictionary,
	cooldown_by_unit_id: Dictionary,
	move_ready_tick_by_unit_id: Dictionary,
	terrain_registry,
	current_tick: int,
	config: Dictionary = {}
) -> Array:
	var actions: Array = []
	for medic in medics:
		if not can_medic_support(medic, cooldown_by_unit_id):
			continue
		var medic_id: String = String(medic.call("get_unit_id")).strip_edges()
		var target = pick_medic_target(medic, allies, reserved_target_ids, terrain_registry, config)
		if target != null and target.has_method("get_unit_id"):
			var target_id: String = String(target.call("get_unit_id")).strip_edges()
			if target_id.is_empty():
				continue
			reserved_target_ids[target_id] = true
			actions.append(
				{
					"action_type": "heal",
					"medic": medic,
					"target": target,
					"medic_id": medic_id,
					"target_id": target_id,
				}
			)
			continue
		var move_target = pick_medic_move_target(medic, allies, reserved_target_ids, terrain_registry, config)
		if move_target == null or not move_target.has_method("get_unit_id"):
			continue
		if int(move_ready_tick_by_unit_id.get(medic_id, -1)) > current_tick:
			continue
		actions.append(
			{
				"action_type": "move",
				"medic": medic,
				"target": move_target,
				"medic_id": medic_id,
				"target_id": String(move_target.call("get_unit_id")).strip_edges(),
				"target_position": build_medic_approach_position(medic, move_target, float(config.get("approach_standoff", DEFAULT_APPROACH_STANDOFF)), terrain_registry, config),
			}
		)
	return actions


static func can_medic_support(unit, cooldown_by_unit_id: Dictionary = {}) -> bool:
	if unit == null or not unit.has_method("get_unit_id") or not unit.has_method("get_vital_state"):
		return false
	if String(unit.call("get_vital_state")) != "fit":
		return false
	if not is_medic_unit(unit):
		return false
	if not has_required_medic_tool(unit):
		return false
	return int(cooldown_by_unit_id.get(String(unit.call("get_unit_id")), 0)) <= 0


static func is_medic_unit(unit) -> bool:
	if unit == null:
		return false
	var role_id: String = String(unit.call("get_role_id")).to_lower() if unit.has_method("get_role_id") else ""
	if role_id == "combat_medic":
		return true
	var role_name: String = String(unit.call("get_role_name")).to_lower() if unit.has_method("get_role_name") else ""
	return role_name.contains("medic") or role_name.contains("sanitaeter")


static func has_required_medic_tool(unit) -> bool:
	if unit == null:
		return false
	if unit.has_method("has_medic_tool"):
		return bool(unit.call("has_medic_tool"))
	var weapon_1_id: String = String(unit.call("get_weapon_1_id")).strip_edges() if unit.has_method("get_weapon_1_id") else ""
	var weapon_2_id: String = String(unit.call("get_weapon_2_id")).strip_edges() if unit.has_method("get_weapon_2_id") else ""
	return WEAPON_DATA_SCRIPT.is_medic_tool_id(weapon_1_id) or WEAPON_DATA_SCRIPT.is_medic_tool_id(weapon_2_id)


static func pick_medic_target(medic, allies: Array, reserved_target_ids: Dictionary, terrain_registry = null, config: Dictionary = {}):
	if medic == null or not (medic is Node2D):
		return null
	return pick_best_medic_target(medic, allies, reserved_target_ids, true, terrain_registry, config)


static func pick_medic_move_target(medic, allies: Array, reserved_target_ids: Dictionary, terrain_registry = null, config: Dictionary = {}):
	if medic == null or not (medic is Node2D):
		return null
	return pick_best_medic_target(medic, allies, reserved_target_ids, false, terrain_registry, config)


static func pick_best_medic_target(medic, allies: Array, reserved_target_ids: Dictionary, require_in_range: bool, terrain_registry = null, config: Dictionary = {}):
	var best_target = null
	var best_score: float = -INF
	for ally in allies:
		var candidate_score: float = score_medic_target(medic, ally, reserved_target_ids, require_in_range, terrain_registry, config)
		if candidate_score > best_score:
			best_score = candidate_score
			best_target = ally
	return best_target


static func score_medic_target(medic, ally, reserved_target_ids: Dictionary, require_in_range: bool, terrain_registry = null, config: Dictionary = {}) -> float:
	if not is_valid_medic_target(medic, ally, reserved_target_ids, require_in_range, terrain_registry, config):
		return -INF
	var distance: float = (medic as Node2D).global_position.distance_to((ally as Node2D).global_position)
	var vital_state: String = String(ally.call("get_vital_state")).strip_edges().to_lower()
	if vital_state == "down":
		return 500.0 - (distance * 0.75)
	if vital_state != "fit":
		return -INF
	if not ally.has_method("get_health") or not ally.has_method("get_max_health_points"):
		return -INF
	var max_health: int = int(ally.call("get_max_health_points"))
	if max_health <= 0:
		return -INF
	var health_ratio: float = float(ally.call("get_health")) / float(max_health)
	var wounded_threshold: float = float(config.get("wounded_threshold", DEFAULT_WOUNDED_THRESHOLD)) if require_in_range else float(config.get("remote_wounded_threshold", DEFAULT_REMOTE_WOUNDED_THRESHOLD))
	if health_ratio >= wounded_threshold:
		return -INF
	return 160.0 + ((1.0 - health_ratio) * 220.0) - (distance * 0.45)


static func is_valid_medic_target(medic, ally, reserved_target_ids: Dictionary, require_in_range: bool = true, terrain_registry = null, config: Dictionary = {}) -> bool:
	if medic == null or not (medic is Node2D):
		return false
	if ally == null or ally == medic or not (ally is Node2D):
		return false
	if not ally.has_method("get_unit_id") or not ally.has_method("get_vital_state"):
		return false
	var target_id: String = String(ally.call("get_unit_id"))
	if target_id.is_empty() or reserved_target_ids.has(target_id):
		return false
	if medic.has_method("get_team_id") and ally.has_method("get_team_id"):
		if String(medic.call("get_team_id")) != String(ally.call("get_team_id")):
			return false
	var distance: float = (medic as Node2D).global_position.distance_to((ally as Node2D).global_position)
	if require_in_range:
		return is_within_medic_support_range(medic, ally, terrain_registry, distance, config)
	return is_within_medic_move_range(medic, ally, terrain_registry, distance, config)


static func build_medic_approach_position(medic, target, approach_standoff: float = DEFAULT_APPROACH_STANDOFF, terrain_registry = null, config: Dictionary = {}) -> Vector2:
	if medic == null or target == null or not (medic is Node2D) or not (target is Node2D):
		return Vector2.ZERO
	var neighbor_position = _resolve_neighbor_approach_position(medic, target, terrain_registry)
	if typeof(neighbor_position) == TYPE_VECTOR2:
		return Vector2(neighbor_position)
	var target_position: Vector2 = (target as Node2D).global_position
	var direction: Vector2 = target_position - (medic as Node2D).global_position
	if direction.length_squared() <= 0.001:
		return target_position
	return target_position - (direction.normalized() * approach_standoff)


static func is_within_medic_support_range(medic, target, terrain_registry = null, fallback_distance: float = -1.0, config: Dictionary = {}) -> bool:
	var tile_distance: int = get_medic_tile_distance(medic, target, terrain_registry)
	if tile_distance >= 0:
		return tile_distance <= int(config.get("tile_range", DEFAULT_TILE_RANGE))
	var resolved_distance: float = fallback_distance
	if resolved_distance < 0.0 and medic is Node2D and target is Node2D:
		resolved_distance = (medic as Node2D).global_position.distance_to((target as Node2D).global_position)
	return resolved_distance <= float(config.get("range_fallback_world", DEFAULT_RANGE_FALLBACK_WORLD))


static func is_within_medic_move_range(medic, target, terrain_registry = null, fallback_distance: float = -1.0, config: Dictionary = {}) -> bool:
	var tile_distance: int = get_medic_tile_distance(medic, target, terrain_registry)
	if tile_distance >= 0:
		return tile_distance <= int(config.get("move_max_tile_distance", DEFAULT_MOVE_MAX_TILE_DISTANCE))
	var resolved_distance: float = fallback_distance
	if resolved_distance < 0.0 and medic is Node2D and target is Node2D:
		resolved_distance = (medic as Node2D).global_position.distance_to((target as Node2D).global_position)
	return resolved_distance <= float(config.get("move_max_distance_fallback_world", DEFAULT_MOVE_MAX_DISTANCE_FALLBACK_WORLD))


static func get_medic_tile_distance(medic, target, terrain_registry = null) -> int:
	if medic == null or target == null or not (medic is Node2D) or not (target is Node2D):
		return -1
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid"):
		return -1
	var medic_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", (medic as Node2D).global_position))
	var target_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", (target as Node2D).global_position))
	var delta: Vector2i = target_grid - medic_grid
	return absi(delta.x) + absi(delta.y)


static func _resolve_neighbor_approach_position(medic, target, terrain_registry = null) -> Variant:
	if terrain_registry == null or not terrain_registry.has_method("world_to_grid") or not terrain_registry.has_method("grid_to_world"):
		return null
	var target_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", (target as Node2D).global_position))
	var medic_position: Vector2 = (medic as Node2D).global_position
	var has_tile_data: bool = terrain_registry.has_method("get_all_tiles") and not Array(terrain_registry.call("get_all_tiles")).is_empty()
	var candidates: Array = []
	for offset in ORTHOGONAL_NEIGHBOR_OFFSETS:
		var candidate_grid: Vector2i = target_grid + offset
		if has_tile_data and terrain_registry.has_method("is_walkable") and not bool(terrain_registry.call("is_walkable", candidate_grid)):
			continue
		var candidate_position: Vector2 = Vector2(terrain_registry.call("grid_to_world", candidate_grid))
		candidates.append({
			"grid": candidate_grid,
			"position": candidate_position,
			"distance": medic_position.distance_squared_to(candidate_position),
		})
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var distance_a: float = float(a.get("distance", 0.0))
		var distance_b: float = float(b.get("distance", 0.0))
		if absf(distance_a - distance_b) > 0.001:
			return distance_a < distance_b
		var grid_a: Vector2i = Vector2i(a.get("grid", Vector2i.ZERO))
		var grid_b: Vector2i = Vector2i(b.get("grid", Vector2i.ZERO))
		if grid_a.x == grid_b.x:
			return grid_a.y < grid_b.y
		return grid_a.x < grid_b.x
	)
	return Vector2(Dictionary(candidates[0]).get("position", (target as Node2D).global_position))
