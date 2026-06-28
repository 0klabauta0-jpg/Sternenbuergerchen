class_name EnemyBehaviorOrchestrator
extends RefCounted

const COMMAND_MOVE_TO_POSITION: String = "move_to_position"
const COMMAND_HOLD_POSITION: String = "hold_position"

const SOURCE_ENEMY_TEAM_TACTICS: String = "enemy_team_tactics"
const SOURCE_ENEMY_PATROL: String = "enemy_patrol"
const SOURCE_ENEMY_ADVANCE: String = "enemy_advance"
const SOURCE_ENEMY_LIMBO_COVER: String = "enemy_limbo_cover"
const SOURCE_ENEMY_LIMBO_CONTACT_HOLD: String = "enemy_limbo_contact_hold"
const SOURCE_ENEMY_DAMAGE_REPOSITION: String = "enemy_damage_reposition"

const POSTURE_TRAVEL: String = "travel"
const POSTURE_TACTICAL: String = "tactical"
const POSTURE_OVERWATCH: String = "overwatch"
const WEAPON_LOWERED: String = "lowered"
const WEAPON_READY: String = "ready"
const POLICY_TRAVEL_UNTIL_THREAT: String = "travel_until_threat"
const POLICY_AGGRESSIVE_READY: String = "aggressive_ready"
const POLICY_OVERWATCH: String = "overwatch"


func build_team_tactics_decision(enemy: Node, state: Dictionary, unit_id: String, waypoint_reached_distance: float, default_speed_factor: float) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if enemy == null or not (enemy is Node2D) or normalized_unit_id.is_empty():
		return {}
	if state.is_empty() or not bool(state.get("has_explicit_tactics", false)):
		return {}

	var advance_style: String = String(state.get("advance_style", "hold")).strip_edges().to_lower()
	if advance_style == "hold":
		return {
			"handled": true,
			"command": {},
			"reason": "hold_tactic_no_command",
		}

	var moving_unit_ids: PackedStringArray = PackedStringArray(state.get("moving_unit_ids", PackedStringArray()))
	if not moving_unit_ids.has(normalized_unit_id):
		return _build_handled_decision(_build_team_tactics_hold_command(state, normalized_unit_id))

	var target_positions: Dictionary = Dictionary(state.get("target_positions_by_unit_id", {}))
	if not target_positions.has(normalized_unit_id):
		return _build_handled_decision(_build_team_tactics_hold_command(state, normalized_unit_id))

	var target_position: Vector2 = Vector2(target_positions.get(normalized_unit_id, (enemy as Node2D).global_position))
	if (enemy as Node2D).global_position.distance_to(target_position) <= waypoint_reached_distance:
		return _build_handled_decision(_build_team_tactics_hold_command(state, normalized_unit_id))

	var posture_fields: Dictionary = build_posture_command_fields(state, normalized_unit_id, default_speed_factor)
	return _build_handled_decision({
		"command_type": COMMAND_MOVE_TO_POSITION,
		"priority": int(state.get("priority", 8)),
		"unit_id": normalized_unit_id,
		"target_position": target_position,
		"move_speed_factor": float(posture_fields.get("move_speed_factor", state.get("move_speed_factor", default_speed_factor))),
		"movement_posture": String(posture_fields.get("movement_posture", POSTURE_TACTICAL)),
		"weapon_posture": String(posture_fields.get("weapon_posture", WEAPON_READY)),
		"posture_policy_id": String(posture_fields.get("posture_policy_id", state.get("movement_posture_policy", ""))),
		"source_command_type": SOURCE_ENEMY_TEAM_TACTICS,
		"requeue_until_target": false,
		"enemy_tactic_label": String(state.get("tactic_label", "")),
		"enemy_advance_style": advance_style,
	})


func build_patrol_decision(enemy: Node, context: Dictionary) -> Dictionary:
	var unit_id: String = String(context.get("unit_id", "")).strip_edges()
	if enemy == null or not (enemy is Node2D) or unit_id.is_empty():
		return {}
	if bool(context.get("contact_locked", false)):
		return {}
	if bool(context.get("should_hold", false)):
		return {
			"handled": false,
			"contact_locked": true,
			"reason": "contact_hold",
		}

	var patrol_path: Array = Array(context.get("patrol_path", []))
	if patrol_path.is_empty():
		return {}

	var waypoint_index: int = int(context.get("waypoint_index", 0))
	if waypoint_index < 0:
		waypoint_index = 0
	if waypoint_index >= patrol_path.size():
		waypoint_index = 0

	var current_position: Vector2 = (enemy as Node2D).global_position
	var target_position: Vector2 = _coerce_vector2(patrol_path[waypoint_index], current_position)
	var waypoint_reached_distance: float = maxf(float(context.get("waypoint_reached_distance", 18.0)), 0.0)
	if current_position.distance_to(target_position) <= waypoint_reached_distance:
		waypoint_index = (waypoint_index + 1) % patrol_path.size()
		target_position = _coerce_vector2(patrol_path[waypoint_index], target_position)

	var posture_fields: Dictionary = Dictionary(context.get("posture_fields", {}))
	var default_speed_factor: float = float(context.get("default_speed_factor", 0.3))
	return {
		"handled": true,
		"waypoint_index": waypoint_index,
		"command": {
			"command_type": COMMAND_MOVE_TO_POSITION,
			"priority": int(context.get("priority", 7)),
			"unit_id": unit_id,
			"target_position": target_position,
			"move_speed_factor": float(posture_fields.get("move_speed_factor", default_speed_factor)),
			"movement_posture": String(posture_fields.get("movement_posture", POSTURE_TRAVEL)),
			"weapon_posture": String(posture_fields.get("weapon_posture", WEAPON_LOWERED)),
			"posture_policy_id": String(posture_fields.get("posture_policy_id", POLICY_TRAVEL_UNTIL_THREAT)),
			"source_command_type": SOURCE_ENEMY_PATROL,
			"requeue_until_target": false,
		},
	}


func build_fallback_advance_command(unit_id: String, target_position: Vector2, posture_fields: Dictionary, default_speed_factor: float) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	return {
		"command_type": COMMAND_MOVE_TO_POSITION,
		"priority": 8,
		"unit_id": normalized_unit_id,
		"target_position": target_position,
		"move_speed_factor": float(posture_fields.get("move_speed_factor", default_speed_factor)),
		"movement_posture": String(posture_fields.get("movement_posture", POSTURE_TACTICAL)),
		"weapon_posture": String(posture_fields.get("weapon_posture", WEAPON_READY)),
		"posture_policy_id": String(posture_fields.get("posture_policy_id", POLICY_TRAVEL_UNTIL_THREAT)),
		"source_command_type": SOURCE_ENEMY_ADVANCE,
		"requeue_until_target": false,
	}


func build_limbo_cover_command(unit_id: String, target_position: Vector2, move_speed_factor: float, action_id: String, reason: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or target_position == Vector2.INF:
		return {}
	return {
		"command_type": COMMAND_MOVE_TO_POSITION,
		"priority": 11,
		"unit_id": normalized_unit_id,
		"target_position": target_position,
		"move_speed_factor": move_speed_factor,
		"fire_status": "fire_at_will",
		"movement_posture": POSTURE_TACTICAL,
		"weapon_posture": WEAPON_READY,
		"posture_policy_id": POLICY_AGGRESSIVE_READY,
		"source_command_type": SOURCE_ENEMY_LIMBO_COVER,
		"requeue_until_target": false,
		"enemy_bt_action": action_id,
		"enemy_bt_reason": reason,
	}


func build_limbo_contact_hold_command(unit_id: String, action_id: String, reason: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	return {
		"command_type": COMMAND_HOLD_POSITION,
		"priority": 9,
		"unit_id": normalized_unit_id,
		"move_speed_factor": 0.0,
		"fire_status": "fire_at_will",
		"movement_posture": POSTURE_OVERWATCH,
		"weapon_posture": WEAPON_READY,
		"posture_policy_id": POLICY_OVERWATCH,
		"source_command_type": SOURCE_ENEMY_LIMBO_CONTACT_HOLD,
		"enemy_bt_action": action_id,
		"enemy_bt_reason": reason,
	}


func build_damage_reposition_command(unit_id: String, target_position: Vector2, move_speed_factor: float, posture_policy_id: String = POLICY_AGGRESSIVE_READY) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or target_position == Vector2.INF:
		return {}
	return {
		"command_type": COMMAND_MOVE_TO_POSITION,
		"priority": 12,
		"unit_id": normalized_unit_id,
		"target_position": target_position,
		"move_speed_factor": move_speed_factor,
		"movement_posture": POSTURE_TACTICAL,
		"weapon_posture": WEAPON_READY,
		"posture_policy_id": posture_policy_id,
		"source_command_type": SOURCE_ENEMY_DAMAGE_REPOSITION,
		"requeue_until_target": true,
	}


func build_posture_command_fields(state: Dictionary, unit_id: String, default_speed_factor: float) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	var movement_by_unit_id: Dictionary = Dictionary(state.get("movement_posture_by_unit_id", {}))
	var weapon_by_unit_id: Dictionary = Dictionary(state.get("weapon_posture_by_unit_id", {}))
	var policy_by_unit_id: Dictionary = Dictionary(state.get("posture_policy_by_unit_id", {}))
	var speed_by_unit_id: Dictionary = Dictionary(state.get("move_speed_factor_by_unit_id", {}))
	return {
		"movement_posture": String(movement_by_unit_id.get(normalized_unit_id, POSTURE_TACTICAL)),
		"weapon_posture": String(weapon_by_unit_id.get(normalized_unit_id, WEAPON_READY)),
		"posture_policy_id": String(policy_by_unit_id.get(normalized_unit_id, state.get("movement_posture_policy", ""))),
		"move_speed_factor": float(speed_by_unit_id.get(normalized_unit_id, state.get("move_speed_factor", default_speed_factor))),
	}


func _build_team_tactics_hold_command(state: Dictionary, unit_id: String) -> Dictionary:
	var posture_fields: Dictionary = build_posture_command_fields(state, unit_id, 0.0)
	return {
		"command_type": COMMAND_HOLD_POSITION,
		"priority": int(state.get("priority", 6)),
		"unit_id": unit_id,
		"move_speed_factor": float(posture_fields.get("move_speed_factor", 0.0)),
		"movement_posture": String(posture_fields.get("movement_posture", POSTURE_OVERWATCH)),
		"weapon_posture": String(posture_fields.get("weapon_posture", WEAPON_READY)),
		"posture_policy_id": String(posture_fields.get("posture_policy_id", state.get("movement_posture_policy", ""))),
		"source_command_type": SOURCE_ENEMY_TEAM_TACTICS,
		"enemy_tactic_label": String(state.get("tactic_label", "")),
		"enemy_advance_style": String(state.get("advance_style", "hold")),
	}


func _build_handled_decision(command: Dictionary) -> Dictionary:
	if command.is_empty():
		return {}
	return {
		"handled": true,
		"command": command,
	}


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2(value)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = value
		if dict.has("world_position"):
			return _coerce_vector2(dict.get("world_position"), fallback)
		if dict.has("x") and dict.has("y"):
			return Vector2(float(dict.get("x", fallback.x)), float(dict.get("y", fallback.y)))
	if typeof(value) == TYPE_OBJECT and value != null:
		if value.get("world_position") != null:
			return _coerce_vector2(value.get("world_position"), fallback)
	return fallback
