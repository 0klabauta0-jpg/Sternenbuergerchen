class_name SimulationRoot
extends Node

signal tick_processed(tick: int)

const MOVE_SPEED_PER_SECOND: float = 120.0
const DAMAGE_MODEL_SCRIPT: GDScript = preload("res://scripts/core/damage_model.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const CAPTURE_PROGRESS_PER_TICK: float = 0.01

@export var unit_registry_path: NodePath
@export var terrain_registry_path: NodePath

var command_queue: Array = []
var effects_queue: Array = []
var tick_counter: int = 0
var is_processing_tick: bool = false
var _objective_status: RefCounted = null
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func enqueue_command(cmd: Dictionary) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_command expects a Dictionary command.")
		return

	command_queue.append(cmd)


func enqueue_effect(effect: Dictionary) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_effect expects a Dictionary effect.")
		return

	effects_queue.append(effect)


func clear_queues() -> void:
	command_queue.clear()
	effects_queue.clear()


func get_tick() -> int:
	return tick_counter


func set_objective_status(objective_status) -> bool:
	if objective_status == null:
		_objective_status = null
		return true

	if not _is_valid_objective_status(objective_status):
		push_warning("SimulationRoot.set_objective_status expects a valid ObjectiveStatus-like object.")
		return false

	_objective_status = objective_status
	return true


func get_objective_status():
	return _objective_status


# Commands are committed before effects on every authoritative physics tick.
func _physics_process(delta: float) -> void:
	tick_counter += 1
	is_processing_tick = true

	var commands: Array = _drain_queue(command_queue)
	_process_commands(commands, delta)

	var effects: Array = _drain_queue(effects_queue)
	_process_effects(effects, delta)
	_update_objective_capture()

	is_processing_tick = false
	tick_processed.emit(tick_counter)


func _process_commands(commands: Array, delta: float) -> void:
	var ordered_commands: Array = _order_payloads(commands)

	for cmd in ordered_commands:
		_apply_command(cmd, delta)


func _process_effects(effects: Array, delta: float) -> void:
	var ordered_effects: Array = _order_payloads(effects)

	for effect in ordered_effects:
		_apply_effect(effect, delta)


func _apply_command(cmd: Dictionary, delta: float) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary commands.")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying a command.")
		return

	match _extract_command_type(cmd):
		"move_to_position":
			_apply_move_command(cmd, delta)
		"engage_area":
			_apply_move_command(cmd, delta)
		_:
			# TODO: Authoritative gameplay state commits belong here once systems exist.
			pass


func _apply_effect(effect: Dictionary, delta: float) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary effects.")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying an effect.")
		return

	match _extract_effect_type(effect):
		"damage":
			_apply_damage_effect(effect)
		"bleedout":
			_apply_bleedout_effect(effect)
		"respawn":
			_apply_respawn_effect(effect)
		_:
			# TODO: Deterministic effect commits belong here once systems exist.
			pass


func _drain_queue(queue: Array) -> Array:
	var drained: Array = queue.duplicate(false)
	queue.clear()
	return drained


func _order_payloads(payloads: Array) -> Array:
	var decorated: Array = []
	var index: int = 0

	for payload in payloads:
		if typeof(payload) != TYPE_DICTIONARY:
			push_warning("SimulationRoot expected queued payloads to be dictionaries.")
			index += 1
			continue

		decorated.append(
			{
				"index": index,
				"priority": _extract_priority(payload),
				"payload": payload,
			}
		)
		index += 1

	decorated.sort_custom(_sort_payload_entries)

	var ordered: Array = []
	for entry in decorated:
		ordered.append(entry["payload"])

	return ordered


func _extract_priority(payload: Dictionary) -> int:
	if not payload.has("priority"):
		return 0

	var priority: Variant = payload["priority"]
	if typeof(priority) == TYPE_INT or typeof(priority) == TYPE_FLOAT:
		return int(priority)

	push_warning("SimulationRoot expected payload priority to be numeric.")
	return 0


func _sort_payload_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = int(a["priority"])
	var b_priority: int = int(b["priority"])

	if a_priority == b_priority:
		return int(a["index"]) < int(b["index"])

	return a_priority > b_priority


func _extract_command_type(cmd: Dictionary) -> String:
	if cmd.has("command_type"):
		return String(cmd["command_type"])

	if cmd.has("type"):
		return String(cmd["type"])

	return ""


func _extract_effect_type(effect: Dictionary) -> String:
	if effect.has("effect_type"):
		return String(effect["effect_type"])

	return ""


func _apply_move_command(cmd: Dictionary, delta: float) -> void:
	var unit_id: String = String(cmd.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot move command expects a non-empty unit_id.")
		return

	var target_position: Variant = cmd.get("target_position", null)
	if typeof(target_position) != TYPE_VECTOR2:
		push_warning("SimulationRoot move command expects a Vector2 target_position.")
		return

	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		push_warning("SimulationRoot requires a direct UnitRegistry reference for move commands.")
		return

	var unit = unit_registry.call("get_unit", unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a move command.")
		return

	if not (unit is Node2D):
		push_warning("SimulationRoot move command expects a Node2D-compatible unit.")
		return

	if unit.has_method("set_target_position"):
		unit.call("set_target_position", target_position)

	var node_2d: Node2D = unit
	var move_speed_factor: float = _extract_move_speed_factor(cmd, unit)
	if move_speed_factor <= 0.0:
		return

	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null:
		_apply_move_command_with_terrain(cmd, node_2d, target_position, move_speed_factor, delta, terrain_registry)
		return

	var current_position: Vector2 = node_2d.position
	var direction: Vector2 = target_position - current_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * delta
	if direction.length() <= step_distance:
		node_2d.position = target_position
		if unit.has_method("refresh_terrain_readability"):
			unit.call("refresh_terrain_readability")
		return

	if direction.is_zero_approx():
		return

	node_2d.position = current_position + direction.normalized() * step_distance
	if unit.has_method("refresh_terrain_readability"):
		unit.call("refresh_terrain_readability")
	if bool(cmd.get("requeue_until_target", true)):
		enqueue_command(cmd.duplicate(true))


func _apply_move_command_with_terrain(
	cmd: Dictionary,
	unit_node: Node2D,
	target_position: Vector2,
	move_speed_factor: float,
	delta: float,
	terrain_registry
) -> void:
	var path_world_points: Array = _extract_or_build_path_world_points(cmd, unit_node.global_position, target_position, terrain_registry)
	if path_world_points.is_empty():
		return

	var current_position: Vector2 = unit_node.global_position
	var step_distance: float = MOVE_SPEED_PER_SECOND * move_speed_factor * _extract_surface_speed_factor(unit_node) * delta
	while step_distance > 0.0 and not path_world_points.is_empty():
		var next_waypoint: Vector2 = _coerce_vector2(path_world_points[0], target_position)
		var direction_to_waypoint: Vector2 = next_waypoint - current_position
		if direction_to_waypoint.is_zero_approx():
			path_world_points.pop_front()
			continue

		var distance_to_waypoint: float = direction_to_waypoint.length()
		if distance_to_waypoint <= step_distance:
			current_position = next_waypoint
			step_distance -= distance_to_waypoint
			path_world_points.pop_front()
			continue

		current_position += direction_to_waypoint.normalized() * step_distance
		step_distance = 0.0

	unit_node.global_position = current_position
	cmd["path"] = path_world_points.duplicate(true)
	if unit_node.has_method("refresh_terrain_readability"):
		unit_node.call("refresh_terrain_readability")

	if bool(cmd.get("requeue_until_target", true)) and (not path_world_points.is_empty() or current_position.distance_to(target_position) > 0.5):
		enqueue_command(cmd.duplicate(true))


func _extract_or_build_path_world_points(
	cmd: Dictionary,
	current_position: Vector2,
	target_position: Vector2,
	terrain_registry
) -> Array:
	var existing_path: Array = []
	var raw_path: Variant = cmd.get("path", [])
	if raw_path is Array:
		existing_path = (raw_path as Array).duplicate(true)

	if not existing_path.is_empty():
		return existing_path

	var path_world_points: Array = _build_path_world_points(current_position, target_position, terrain_registry)
	cmd["path"] = path_world_points.duplicate(true)
	return path_world_points


func _build_path_world_points(current_position: Vector2, target_position: Vector2, terrain_registry) -> Array:
	var path_world_points: Array = []
	if terrain_registry == null or _terrain_pathfinder == null:
		path_world_points.append(target_position)
		return path_world_points

	var from_grid: Vector2i = terrain_registry.call("world_to_grid", current_position)
	var to_grid: Vector2i = terrain_registry.call("world_to_grid", target_position)
	var path_grid_points: Array = _terrain_pathfinder.find_path(from_grid, to_grid, terrain_registry)
	if path_grid_points.is_empty():
		if from_grid == to_grid:
			path_world_points.append(target_position)
			return path_world_points

		push_warning("SimulationRoot could not build a terrain path for move command.")
		return path_world_points

	for index in range(1, path_grid_points.size()):
		path_world_points.append(terrain_registry.call("grid_to_world", path_grid_points[index]))

	if path_world_points.is_empty() or _coerce_vector2(path_world_points[-1], target_position).distance_to(target_position) > 0.5:
		path_world_points.append(target_position)

	return path_world_points


func _apply_damage_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot damage effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a damage effect.")
		return

	if not unit.has_method("apply_damage"):
		push_warning("SimulationRoot damage effect expects a unit with apply_damage().")
		return

	var attacker_team_id: String = String(effect.get("attacker_team_id", ""))
	var attacker_unit_id: String = String(effect.get("attacker_unit_id", ""))
	var target_team_id: String = ""
	if unit.has_method("get_team_id"):
		target_team_id = String(unit.call("get_team_id"))

	var is_friendly_fire: bool = not attacker_team_id.is_empty() and not target_team_id.is_empty() and attacker_team_id == target_team_id
	var allow_friendly_fire: bool = bool(effect.get("allow_friendly_fire", true))
	if is_friendly_fire and not allow_friendly_fire:
		return

	var base_damage: int = _extract_int(effect.get("damage", 0))
	if base_damage <= 0:
		push_warning("SimulationRoot damage effect expects a positive damage value.")
		return

	var attacker_unit = _resolve_attacker_unit(attacker_unit_id)
	var target_cover_score: float = _extract_effective_cover_score(unit)
	var attacker_attack_bonus: float = _extract_unit_attack_bonus(attacker_unit)
	var attacker_cover_score: float = _extract_unit_cover_score(attacker_unit)
	var hit_chance: float = _extract_float(effect.get("hit_chance", 1.0), 1.0)
	hit_chance *= _extract_unit_accuracy_multiplier(attacker_unit)
	hit_chance = clampf(
		hit_chance + attacker_attack_bonus + _extract_height_accuracy_modifier(attacker_unit, unit) + (attacker_cover_score * 0.05) - (target_cover_score * 0.35),
		0.05,
		0.95
	)
	var roll_override: float = _extract_float(effect.get("roll_override", -1.0), -1.0)
	var damage_multiplier: float = _extract_float(effect.get("damage_multiplier", 1.0), 1.0)
	damage_multiplier = maxf(damage_multiplier + attacker_attack_bonus - (target_cover_score * 0.2), 0.1)
	damage_multiplier *= _extract_unit_damage_taken_multiplier(unit)
	var damage_model = DAMAGE_MODEL_SCRIPT.new()
	if not bool(damage_model.call("resolve_hit", hit_chance, roll_override)):
		return

	var resolved_damage: int = int(damage_model.call("resolve_damage", base_damage, damage_multiplier))
	if resolved_damage <= 0:
		return

	var hit_context: Dictionary = {
		"effect_type": "damage",
		"unit_id": unit_id,
		"attacker_unit_id": attacker_unit_id,
		"attacker_team_id": attacker_team_id,
		"attacker_attack_bonus": attacker_attack_bonus,
		"height_accuracy_modifier": _extract_height_accuracy_modifier(attacker_unit, unit),
		"target_cover_score": target_cover_score,
		"friendly_fire": is_friendly_fire,
	}
	unit.call("apply_damage", resolved_damage, hit_context)


func _apply_bleedout_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot bleedout effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a bleedout effect.")
		return

	if not unit.has_method("advance_bleedout"):
		push_warning("SimulationRoot bleedout effect expects a unit with advance_bleedout().")
		return

	unit.call("advance_bleedout")


func _get_unit_registry():
	if unit_registry_path.is_empty():
		return null

	return get_node_or_null(unit_registry_path)


func _get_terrain_registry():
	if terrain_registry_path.is_empty():
		return null

	return get_node_or_null(terrain_registry_path)


func _resolve_unit(unit_id: String):
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_unit"):
		push_warning("SimulationRoot requires a direct UnitRegistry reference for unit lookups.")
		return null

	return unit_registry.call("get_unit", unit_id)


func _resolve_attacker_unit(attacker_unit_id: String):
	if attacker_unit_id.is_empty():
		return null

	return _resolve_unit(attacker_unit_id)


func _extract_unit_cover_score(unit) -> float:
	if unit == null or not unit.has_method("get_cover_score"):
		return 0.0

	return float(unit.call("get_cover_score"))


func _extract_effective_cover_score(unit) -> float:
	var command_cover_score: float = _extract_unit_cover_score(unit)
	var terrain_cover_score: float = _extract_terrain_cover_score(unit)
	return clampf(command_cover_score + terrain_cover_score, 0.0, 80.0)


func _extract_terrain_cover_score(unit) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D):
		return 0.0

	return float(terrain_registry.call("get_cover_at_world", (unit as Node2D).global_position))


func _extract_unit_attack_bonus(unit) -> float:
	if unit == null or not unit.has_method("get_attack_bonus"):
		return 0.0

	return float(unit.call("get_attack_bonus"))


func _extract_height_accuracy_modifier(attacker_unit, target_unit) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or attacker_unit == null or target_unit == null:
		return 0.0

	if not (attacker_unit is Node2D) or not (target_unit is Node2D):
		return 0.0

	var attacker_height: int = int(terrain_registry.call("get_height_at_world", (attacker_unit as Node2D).global_position))
	var target_height: int = int(terrain_registry.call("get_height_at_world", (target_unit as Node2D).global_position))
	var height_difference: int = attacker_height - target_height
	if height_difference > 0:
		return 0.1 * float(height_difference)

	if height_difference < 0:
		return -0.05 * float(abs(height_difference))

	return 0.0


func _extract_surface_speed_factor(unit) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or unit == null or not (unit is Node2D):
		return 1.0

	return float(terrain_registry.call("get_surface_speed_factor_at_world", (unit as Node2D).global_position))


func _extract_move_speed_factor(cmd: Dictionary, unit) -> float:
	var move_speed_factor: float = 1.0
	var raw_factor: Variant = cmd.get("move_speed_factor", null)
	if typeof(raw_factor) == TYPE_INT or typeof(raw_factor) == TYPE_FLOAT:
		move_speed_factor = maxf(float(raw_factor), 0.0)
	elif unit != null and unit.has_method("get_move_speed_factor"):
		move_speed_factor = maxf(float(unit.call("get_move_speed_factor")), 0.0)

	return move_speed_factor * _extract_unit_speed_multiplier(unit)


func _update_objective_capture() -> void:
	if not _is_valid_objective_status(_objective_status):
		return

	var capturing_team_ids: PackedStringArray = _get_objective_team_ids_in_radius(_objective_status)
	_objective_status.call("set_contested", capturing_team_ids.size() > 1)
	if capturing_team_ids.size() != 1:
		return

	var capturing_team_id: String = String(capturing_team_ids[0])
	if capturing_team_id.is_empty():
		return

	if String(_objective_status.owning_team_id) == capturing_team_id:
		_objective_status.capture_progress = 1.0
		_objective_status.capturing_team_id = capturing_team_id
		return

	if String(_objective_status.capturing_team_id) != capturing_team_id:
		_objective_status.capturing_team_id = capturing_team_id
		_objective_status.capture_progress = 0.0

	_objective_status.capture_progress = minf(float(_objective_status.capture_progress) + CAPTURE_PROGRESS_PER_TICK, 1.0)
	if float(_objective_status.capture_progress) < 1.0:
		return

	_objective_status.capture_progress = 1.0
	_objective_status.owning_team_id = capturing_team_id


func _get_objective_team_ids_in_radius(objective_status) -> PackedStringArray:
	var unit_registry = _get_unit_registry()
	if unit_registry == null or not unit_registry.has_method("get_all_units"):
		return []

	var team_ids: PackedStringArray = []
	var objective_position: Vector2 = objective_status.position
	var capture_radius: float = maxf(float(objective_status.capture_radius), 0.0)
	for unit in unit_registry.call("get_all_units"):
		if unit == null or not (unit is Node2D):
			continue

		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue

		if not unit.has_method("get_team_id"):
			continue

		var team_id: String = String(unit.call("get_team_id"))
		if team_id.is_empty() or team_ids.has(team_id):
			continue

		var unit_position: Vector2 = (unit as Node2D).global_position
		if unit_position.distance_to(objective_position) <= capture_radius:
			team_ids.append(team_id)

	return team_ids


func _is_valid_objective_status(objective_status) -> bool:
	return objective_status != null and objective_status is OBJECTIVE_STATUS_SCRIPT


func _extract_int(value: Variant) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return int(value)

	return 0


func _extract_float(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return float(value)

	return fallback


func _extract_unit_accuracy_multiplier(unit) -> float:
	if unit == null or not unit.has_method("get_accuracy_skill"):
		return 1.0

	return 0.5 + clampf(float(unit.call("get_accuracy_skill")), 0.0, 1.0)


func _extract_unit_speed_multiplier(unit) -> float:
	if unit == null or not unit.has_method("get_speed_skill"):
		return 1.0

	return 0.5 + clampf(float(unit.call("get_speed_skill")), 0.0, 1.0)


func _extract_unit_damage_taken_multiplier(unit) -> float:
	if unit == null or not unit.has_method("get_toughness_skill"):
		return 1.0

	var toughness: float = clampf(float(unit.call("get_toughness_skill")), 0.0, 1.0)
	return 1.0 - (toughness * 0.4)


func _apply_respawn_effect(effect: Dictionary) -> void:
	var unit_id: String = String(effect.get("unit_id", ""))
	if unit_id.is_empty():
		push_warning("SimulationRoot respawn effect expects a non-empty unit_id.")
		return

	var unit = _resolve_unit(unit_id)
	if unit == null:
		push_warning("SimulationRoot could not resolve the target unit for a respawn effect.")
		return

	if not unit.has_method("respawn"):
		push_warning("SimulationRoot respawn effect expects a unit with respawn().")
		return

	var spawn_position: Variant = effect.get("spawn_position", null)
	if typeof(spawn_position) != TYPE_VECTOR2:
		push_warning("SimulationRoot respawn effect expects a Vector2 spawn_position.")
		return

	unit.call("respawn", spawn_position)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value

	if value is Vector2i:
		return Vector2(value.x, value.y)

	return fallback
