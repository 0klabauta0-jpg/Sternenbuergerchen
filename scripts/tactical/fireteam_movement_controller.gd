class_name FireteamMovementController
extends RefCounted

const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")

const ADVANCE_STYLE_RUSH: String = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
const ADVANCE_STYLE_BOUNDING: String = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING
const ADVANCE_STYLE_CATERPILLAR: String = "caterpillar"
const ADVANCE_STYLE_CREEP: String = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_CREEP
const BOUND_COMPLETE_REASON_STAGE: String = "stage_complete"
const BOUND_COMPLETE_REASON_FINAL: String = "final_stage"
const POSITION_REACHED_RADIUS: float = 18.0
const ANCHOR_REACHED_RADIUS: float = 22.0
const RUSH_MIN_SPEED_FACTOR: float = 0.6
const RUSH_MAX_SPEED_FACTOR: float = 1.15
const BOUNDING_MIN_SPEED_FACTOR: float = 0.52
const BOUNDING_MAX_SPEED_FACTOR: float = 0.92
const CATERPILLAR_MIN_SPEED_FACTOR: float = 0.38
const CATERPILLAR_MAX_SPEED_FACTOR: float = 0.68
const BOUNDING_MIN_STEP_DISTANCE: float = 84.0
const BOUNDING_MAX_STEP_DISTANCE: float = 176.0
const CATERPILLAR_MIN_STEP_DISTANCE: float = 56.0
const CATERPILLAR_MAX_STEP_DISTANCE: float = 104.0
const FORMATION_SLOT_LAYOUT := [
	Vector2.ZERO,
	Vector2(-0.85, 0.65),
	Vector2(0.85, 0.65),
	Vector2(-1.5, 1.3),
	Vector2(1.5, 1.3),
	Vector2(-2.15, 1.95),
	Vector2(2.15, 1.95),
	Vector2(0.0, 2.3),
]
const FORMATION_SLOT_SPACING: float = 28.0

var _execution_by_fireteam: Dictionary = {}


func reset_fireteam(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	_execution_by_fireteam.erase(normalized_fireteam_id)


func reset_all() -> void:
	_execution_by_fireteam.clear()


func has_active_execution(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	return not normalized_fireteam_id.is_empty() and _execution_by_fireteam.has(normalized_fireteam_id)


func get_fireteam_state(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	return _build_public_state(Dictionary(_execution_by_fireteam.get(normalized_fireteam_id, {})))


func get_state_snapshot() -> Array:
	var snapshot: Array = []
	for fireteam_id in _execution_by_fireteam.keys():
		var state: Dictionary = get_fireteam_state(String(fireteam_id))
		if state.is_empty():
			continue
		snapshot.append(state)
	return snapshot


func start_execution(
	fireteam_id: String,
	command_type: String,
	phase_index: int,
	target_position: Vector2,
	behavior_profile,
	units: Array,
	leader,
	simulation_root
) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or simulation_root == null:
		return {"started": false}
	var member_records: Array = _build_member_records(units, leader)
	if member_records.is_empty():
		_execution_by_fireteam.erase(normalized_fireteam_id)
		return {"started": false}
	var raw_style: String = _extract_advance_style(behavior_profile)
	var effective_style: String = _resolve_effective_style(raw_style, units, member_records)
	var cover_priority: float = _extract_cover_priority(behavior_profile)
	var cohesion_threshold: float = _extract_cohesion_threshold(behavior_profile)
	var execution_profile: Dictionary = _extract_execution_profile(behavior_profile)
	var leader_unit_id: String = _extract_leader_unit_id(leader, member_records)
	var origin_anchor: Vector2 = _resolve_origin_anchor(member_records, leader)
	var resolved_target_position: Vector2 = _apply_execution_target_offset(
		normalized_fireteam_id,
		origin_anchor,
		target_position,
		float(execution_profile.get("order_fidelity", 0.65))
	)
	var state: Dictionary = {
		"fireteam_id": normalized_fireteam_id,
		"phase": phase_index,
		"command_type": command_type.strip_edges().to_lower(),
		"raw_style": raw_style,
		"effective_style": effective_style,
		"leader_unit_id": leader_unit_id,
		"requested_target_position": target_position,
		"final_target_position": resolved_target_position,
		"progress_anchor_position": origin_anchor,
		"cover_priority": cover_priority,
		"cohesion_threshold": maxf(cohesion_threshold * lerpf(1.25, 0.88, float(execution_profile.get("execution_cohesion", 0.65))), 1.0),
		"order_fidelity": float(execution_profile.get("order_fidelity", 0.65)),
		"reaction_delay_seconds": float(execution_profile.get("reaction_delay_seconds", 0.25)),
		"execution_cohesion": float(execution_profile.get("execution_cohesion", 0.65)),
		"execution_fire_discipline": float(execution_profile.get("execution_fire_discipline", 0.65)),
		"contact_stability": float(execution_profile.get("contact_stability", 0.65)),
		"initiative": float(execution_profile.get("initiative", 0.5)),
		"execution_label": String(execution_profile.get("execution_label", "STEADY")),
		"formation_scatter_factor": lerpf(1.36, 0.88, float(execution_profile.get("execution_cohesion", 0.65))),
		"move_speed_multiplier": lerpf(0.84, 1.08, float(execution_profile.get("initiative", 0.5))),
		"order_target_offset": resolved_target_position - target_position,
		"stage_index": 0,
		"completed_stage_count": 0,
		"current_anchor_target_position": resolved_target_position,
		"current_target_positions": {},
		"current_moving_unit_ids": PackedStringArray(),
		"current_covering_unit_ids": PackedStringArray(),
		"movement_sequence": PackedStringArray(),
		"group_cycle": [],
		"next_group_index": 0,
		"simplified_due_to_losses": effective_style != _normalize_advance_style(raw_style),
	}
	match effective_style:
		ADVANCE_STYLE_RUSH:
			state["movement_sequence"] = _packed_unit_ids(member_records)
		ADVANCE_STYLE_BOUNDING:
			state.merge(_build_bounding_groups(member_records, leader_unit_id, _leader_pushes_first(member_records, leader_unit_id)), true)
		ADVANCE_STYLE_CATERPILLAR:
			state.merge(_build_caterpillar_groups(member_records, leader_unit_id, _leader_pushes_first(member_records, leader_unit_id)), true)
		_:
			state["movement_sequence"] = _packed_unit_ids(member_records)
	var issue_result: Dictionary = _issue_stage(state, member_records, simulation_root)
	if not bool(issue_result.get("started", false)):
		_execution_by_fireteam.erase(normalized_fireteam_id)
		return issue_result
	_execution_by_fireteam[normalized_fireteam_id] = state
	issue_result["started"] = true
	issue_result["movement_state"] = _build_public_state(state)
	return issue_result


func update_execution(fireteam_id: String, units: Array, leader, simulation_root) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var state: Dictionary = Dictionary(_execution_by_fireteam.get(normalized_fireteam_id, {}))
	if state.is_empty():
		return {}
	var member_records: Array = _build_member_records(units, leader)
	if member_records.is_empty():
		_execution_by_fireteam.erase(normalized_fireteam_id)
		return {"finished": true, "movement_state": {}}
	if _are_current_targets_reached(state, member_records):
		state["completed_stage_count"] = int(state.get("completed_stage_count", 0)) + 1
		var bound_event: Dictionary = {
			"fireteam_id": normalized_fireteam_id,
			"phase": int(state.get("phase", -1)),
			"style": String(state.get("effective_style", "")),
			"stage_index": int(state.get("stage_index", 0)),
			"moving_unit_ids": PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())),
			"covering_unit_ids": PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())),
			"target_position": Vector2(state.get("current_anchor_target_position", state.get("final_target_position", Vector2.ZERO))),
		}
		if _is_execution_complete(state, member_records):
			_execution_by_fireteam.erase(normalized_fireteam_id)
			bound_event["reason"] = BOUND_COMPLETE_REASON_FINAL
			return {
				"finished": true,
				"bound_complete": bound_event,
				"movement_state": {},
			}
		state["stage_index"] = int(state.get("stage_index", 0)) + 1
		var issue_result: Dictionary = _issue_stage(state, member_records, simulation_root)
		_execution_by_fireteam[normalized_fireteam_id] = state
		bound_event["reason"] = BOUND_COMPLETE_REASON_STAGE
		issue_result["bound_complete"] = bound_event
		issue_result["movement_state"] = _build_public_state(state)
		return issue_result
	_execution_by_fireteam[normalized_fireteam_id] = state
	return {"movement_state": _build_public_state(state)}


func _issue_stage(state: Dictionary, member_records: Array, simulation_root) -> Dictionary:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH))
	var moving_unit_ids: PackedStringArray = PackedStringArray()
	var covering_unit_ids: PackedStringArray = PackedStringArray()
	match style:
		ADVANCE_STYLE_BOUNDING:
			var groups: Array = Array(state.get("group_cycle", []))
			if groups.is_empty():
				return {"started": false}
			var group_index: int = int(state.get("next_group_index", 0)) % groups.size()
			moving_unit_ids = PackedStringArray(groups[group_index])
			for index in range(groups.size()):
				if index == group_index:
					continue
				for unit_id in PackedStringArray(groups[index]):
					if not covering_unit_ids.has(unit_id):
						covering_unit_ids.append(unit_id)
			state["next_group_index"] = (group_index + 1) % groups.size()
		ADVANCE_STYLE_CATERPILLAR:
			var sequence: PackedStringArray = PackedStringArray(state.get("movement_sequence", PackedStringArray()))
			if sequence.is_empty():
				return {"started": false}
			var sequence_index: int = int(state.get("next_group_index", 0)) % sequence.size()
			var moving_unit_id: String = String(sequence[sequence_index])
			moving_unit_ids = PackedStringArray([moving_unit_id])
			for unit_id in _packed_unit_ids(member_records):
				if unit_id != moving_unit_id:
					covering_unit_ids.append(unit_id)
			state["next_group_index"] = (sequence_index + 1) % sequence.size()
		_:
			moving_unit_ids = _packed_unit_ids(member_records)
	var next_anchor_target: Vector2 = _compute_next_anchor_target(state, member_records)
	var formation_targets: Dictionary = _build_formation_targets(next_anchor_target, member_records, String(state.get("leader_unit_id", "")), float(state.get("formation_scatter_factor", 1.0)))
	var current_positions: Dictionary = _build_current_positions(member_records)
	var issued_count: int = 0
	for record in member_records:
		var unit_id: String = String(record.get("unit_id", ""))
		if unit_id.is_empty():
			continue
		if covering_unit_ids.has(unit_id):
			var hold_position: Vector2 = Vector2(current_positions.get(unit_id, next_anchor_target))
			if _enqueue_unit_command(
				simulation_root,
				String(record.get("team_id", "")),
				unit_id,
				UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION,
				hold_position,
				0.0,
				float(state.get("cover_priority", 0.0)),
				0.08,
				String(state.get("command_type", "")),
				int(state.get("phase", -1))
			):
				issued_count += 1
			continue
		if not moving_unit_ids.has(unit_id):
			continue
		var move_target: Vector2 = Vector2(formation_targets.get(unit_id, next_anchor_target))
		var move_speed_factor: float = _build_move_speed_factor(style, member_records, moving_unit_ids, current_positions, float(state.get("cohesion_threshold", 100.0)), float(record.get("speed", 0.5)), float(state.get("move_speed_multiplier", 1.0)))
		var unit_command_type: String = _map_waypoint_command_to_unit_command(String(state.get("command_type", "")))
		if _enqueue_unit_command(
			simulation_root,
			String(record.get("team_id", "")),
			unit_id,
			unit_command_type,
			move_target,
			move_speed_factor,
			float(state.get("cover_priority", 0.0)),
			_attack_bonus_for_style(style),
			String(state.get("command_type", "")),
			int(state.get("phase", -1))
		):
			issued_count += 1
	state["current_anchor_target_position"] = next_anchor_target
	state["current_target_positions"] = formation_targets
	state["current_moving_unit_ids"] = moving_unit_ids
	state["current_covering_unit_ids"] = covering_unit_ids
	state["progress_anchor_position"] = next_anchor_target
	return {
		"started": issued_count > 0,
		"issued_count": issued_count,
		"resolved_target_position": Vector2(state.get("final_target_position", next_anchor_target)),
		"effective_advance_style": String(state.get("effective_style", style)),
	}


func _are_current_targets_reached(state: Dictionary, member_records: Array) -> bool:
	var moving_unit_ids: PackedStringArray = PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray()))
	if moving_unit_ids.is_empty():
		return false
	var current_target_positions: Dictionary = Dictionary(state.get("current_target_positions", {}))
	for record in member_records:
		var unit_id: String = String(record.get("unit_id", ""))
		if unit_id.is_empty() or not moving_unit_ids.has(unit_id):
			continue
		var unit = record.get("unit", null)
		if not (unit is Node2D):
			return false
		var target_position: Vector2 = Vector2(current_target_positions.get(unit_id, state.get("current_anchor_target_position", Vector2.ZERO)))
		if (unit as Node2D).global_position.distance_to(target_position) > POSITION_REACHED_RADIUS:
			return false
	return true


func _is_execution_complete(state: Dictionary, member_records: Array) -> bool:
	var final_target_position: Vector2 = Vector2(state.get("final_target_position", Vector2.ZERO))
	var current_anchor_target_position: Vector2 = Vector2(state.get("current_anchor_target_position", final_target_position))
	if current_anchor_target_position.distance_to(final_target_position) > ANCHOR_REACHED_RADIUS:
		return false
	var final_targets: Dictionary = _build_formation_targets(final_target_position, member_records, String(state.get("leader_unit_id", "")), float(state.get("formation_scatter_factor", 1.0)))
	for record in member_records:
		var unit = record.get("unit", null)
		if not (unit is Node2D):
			return false
		var unit_id: String = String(record.get("unit_id", ""))
		var target_position: Vector2 = Vector2(final_targets.get(unit_id, final_target_position))
		if (unit as Node2D).global_position.distance_to(target_position) > POSITION_REACHED_RADIUS:
			return false
	return true


func _build_member_records(units: Array, leader) -> Array:
	var leader_unit_id: String = String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else ""
	var records: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		records.append(
			{
				"unit": unit,
				"unit_id": unit_id,
				"team_id": String(unit.call("get_team_id")) if unit.has_method("get_team_id") else "",
				"speed": _read_skill_value(unit, "get_speed_skill", 0.5),
				"accuracy": _read_skill_value(unit, "get_accuracy_skill", 0.5),
				"is_leader": unit_id == leader_unit_id,
			}
		)
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("is_leader", false)) != bool(b.get("is_leader", false)):
			return bool(a.get("is_leader", false))
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	return records


func _build_bounding_groups(member_records: Array, leader_unit_id: String, leader_pushes_first: bool) -> Dictionary:
	var group_a: PackedStringArray = PackedStringArray()
	var group_b: PackedStringArray = PackedStringArray()
	var remaining_ids: PackedStringArray = _sort_unit_ids_by_speed(member_records)
	if not leader_pushes_first and remaining_ids.has(leader_unit_id):
		remaining_ids.remove_at(remaining_ids.find(leader_unit_id))
		group_b.append(leader_unit_id)
	var fastest_id: String = _take_first_id(remaining_ids)
	if not fastest_id.is_empty():
		group_a.append(fastest_id)
	var highest_accuracy_id: String = _take_best_accuracy_id(remaining_ids, member_records)
	if not highest_accuracy_id.is_empty():
		group_b.append(highest_accuracy_id)
	var fill_a: bool = group_a.size() <= group_b.size()
	while not remaining_ids.is_empty():
		var next_id: String = String(remaining_ids[0])
		remaining_ids.remove_at(0)
		if fill_a:
			group_a.append(next_id)
		else:
			group_b.append(next_id)
		fill_a = not fill_a
	if group_a.is_empty() and not group_b.is_empty():
		group_a.append(String(group_b[0]))
		group_b.remove_at(0)
	if group_b.is_empty() and group_a.size() > 1:
		group_b.append(String(group_a[group_a.size() - 1]))
		group_a.remove_at(group_a.size() - 1)
	if leader_pushes_first and not leader_unit_id.is_empty():
		if group_a.has(leader_unit_id):
			group_a.remove_at(group_a.find(leader_unit_id))
		group_a.insert(0, leader_unit_id)
	elif not leader_pushes_first and not leader_unit_id.is_empty() and not group_b.has(leader_unit_id) and not group_a.has(leader_unit_id):
		group_b.insert(0, leader_unit_id)
	return {"group_cycle": [group_a, group_b]}


func _build_caterpillar_groups(member_records: Array, leader_unit_id: String, leader_pushes_first: bool) -> Dictionary:
	var sequence: PackedStringArray = _sort_unit_ids_by_speed(member_records)
	if not leader_pushes_first and sequence.has(leader_unit_id):
		sequence.remove_at(sequence.find(leader_unit_id))
		sequence.append(leader_unit_id)
	elif leader_pushes_first and sequence.has(leader_unit_id):
		sequence.remove_at(sequence.find(leader_unit_id))
		sequence.insert(0, leader_unit_id)
	return {
		"movement_sequence": sequence,
		"group_cycle": [],
	}


func _compute_next_anchor_target(state: Dictionary, member_records: Array) -> Vector2:
	var final_target_position: Vector2 = Vector2(state.get("final_target_position", Vector2.ZERO))
	var current_anchor_position: Vector2 = Vector2(state.get("progress_anchor_position", final_target_position))
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH))
	if style == ADVANCE_STYLE_RUSH:
		return final_target_position
	var direction: Vector2 = final_target_position - current_anchor_position
	if direction.length() <= ANCHOR_REACHED_RADIUS:
		return final_target_position
	var cohesion_threshold: float = maxf(float(state.get("cohesion_threshold", 100.0)), 1.0)
	var step_distance: float = direction.length()
	if style == ADVANCE_STYLE_CATERPILLAR:
		step_distance = clampf(cohesion_threshold * 0.62, CATERPILLAR_MIN_STEP_DISTANCE, CATERPILLAR_MAX_STEP_DISTANCE)
	else:
		step_distance = clampf(cohesion_threshold * 1.12, BOUNDING_MIN_STEP_DISTANCE, BOUNDING_MAX_STEP_DISTANCE)
	if direction.length() <= step_distance:
		return final_target_position
	return current_anchor_position + direction.normalized() * step_distance


func _build_formation_targets(anchor_position: Vector2, member_records: Array, leader_unit_id: String, scatter_factor: float = 1.0) -> Dictionary:
	var targets: Dictionary = {}
	var ordered_records: Array = member_records.duplicate()
	ordered_records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if String(a.get("unit_id", "")) == leader_unit_id:
			return true
		if String(b.get("unit_id", "")) == leader_unit_id:
			return false
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	var forward: Vector2 = Vector2.DOWN
	if not ordered_records.is_empty():
		var leader_unit = ordered_records[0].get("unit", null)
		if leader_unit is Node2D:
			var direction: Vector2 = anchor_position - (leader_unit as Node2D).global_position
			if not direction.is_zero_approx():
				forward = direction.normalized()
	var lateral: Vector2 = forward.orthogonal()
	for index in range(ordered_records.size()):
		var record: Dictionary = ordered_records[index]
		var slot_index: int = mini(index, FORMATION_SLOT_LAYOUT.size() - 1)
		var slot: Vector2 = FORMATION_SLOT_LAYOUT[slot_index]
		targets[String(record.get("unit_id", ""))] = anchor_position + ((lateral * slot.x) + (forward * slot.y)) * FORMATION_SLOT_SPACING * maxf(scatter_factor, 0.5)
	return targets


func _build_current_positions(member_records: Array) -> Dictionary:
	var positions: Dictionary = {}
	for record in member_records:
		var unit = record.get("unit", null)
		if unit is Node2D:
			positions[String(record.get("unit_id", ""))] = (unit as Node2D).global_position
	return positions


func _build_move_speed_factor(
	style: String,
	member_records: Array,
	moving_unit_ids: PackedStringArray,
	current_positions: Dictionary,
	cohesion_threshold: float,
	speed_skill: float,
	move_speed_multiplier: float = 1.0
) -> float:
	var normalized_multiplier: float = maxf(move_speed_multiplier, 0.1)
	match style:
		ADVANCE_STYLE_BOUNDING:
			return lerpf(BOUNDING_MIN_SPEED_FACTOR, BOUNDING_MAX_SPEED_FACTOR, clampf(speed_skill, 0.0, 1.0)) * normalized_multiplier
		ADVANCE_STYLE_CATERPILLAR:
			return lerpf(CATERPILLAR_MIN_SPEED_FACTOR, CATERPILLAR_MAX_SPEED_FACTOR, clampf(speed_skill, 0.0, 1.0)) * normalized_multiplier
		_:
			var base_factor: float = lerpf(RUSH_MIN_SPEED_FACTOR, RUSH_MAX_SPEED_FACTOR, clampf(speed_skill, 0.0, 1.0))
			var spread: float = _compute_group_spread(moving_unit_ids, current_positions)
			if spread <= cohesion_threshold:
				return base_factor * normalized_multiplier
			var slowest_speed: float = speed_skill
			for record in member_records:
				var unit_id: String = String(record.get("unit_id", ""))
				if not moving_unit_ids.has(unit_id):
					continue
				slowest_speed = minf(slowest_speed, float(record.get("speed", speed_skill)))
			return minf(base_factor, lerpf(RUSH_MIN_SPEED_FACTOR, RUSH_MAX_SPEED_FACTOR, clampf(slowest_speed, 0.0, 1.0))) * normalized_multiplier


func _compute_group_spread(unit_ids: PackedStringArray, current_positions: Dictionary) -> float:
	var positions: Array = []
	for unit_id in unit_ids:
		if not current_positions.has(unit_id):
			continue
		positions.append(Vector2(current_positions.get(unit_id)))
	if positions.size() < 2:
		return 0.0
	var max_distance: float = 0.0
	for position_a in positions:
		for position_b in positions:
			max_distance = maxf(max_distance, Vector2(position_a).distance_to(Vector2(position_b)))
	return max_distance


func _resolve_effective_style(raw_style: String, units: Array, member_records: Array) -> String:
	var normalized_style: String = _normalize_advance_style(raw_style)
	if units.is_empty():
		return normalized_style
	if member_records.size() * 2 > units.size():
		return normalized_style
	return ADVANCE_STYLE_RUSH


func _normalize_advance_style(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if normalized_value == ADVANCE_STYLE_CREEP:
		return ADVANCE_STYLE_CATERPILLAR
	if normalized_value == ADVANCE_STYLE_CATERPILLAR:
		return ADVANCE_STYLE_CATERPILLAR
	if normalized_value == ADVANCE_STYLE_BOUNDING:
		return ADVANCE_STYLE_BOUNDING
	return ADVANCE_STYLE_RUSH


func _map_waypoint_command_to_unit_command(command_type: String) -> String:
	match command_type.strip_edges().to_lower():
		"engage", "take":
			return UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA
		_:
			return UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION


func _attack_bonus_for_style(style: String) -> float:
	match style:
		ADVANCE_STYLE_BOUNDING:
			return 0.05
		ADVANCE_STYLE_CATERPILLAR:
			return 0.08
		_:
			return 0.0


func _enqueue_unit_command(
	simulation_root,
	team_id: String,
	unit_id: String,
	command_type: String,
	target_position: Vector2,
	move_speed_factor: float,
	cover_score: float,
	attack_bonus: float,
	source_command_type: String,
	phase_index: int
) -> bool:
	if simulation_root == null:
		return false
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = command_type
	command.priority = 12
	command.unit_id = unit_id
	command.team_id = team_id
	command.target_position = target_position
	command.move_speed_factor = maxf(move_speed_factor, 0.0)
	command.cover_score = maxf(cover_score, 0.0)
	command.attack_bonus = attack_bonus
	command.source_command_type = source_command_type
	command.phase = phase_index
	if command_type == UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION:
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE
	else:
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	if not bool(command.call("is_valid")):
		return false
	simulation_root.call("enqueue_command", command.to_dict())
	return true


func _resolve_origin_anchor(member_records: Array, leader) -> Vector2:
	if leader is Node2D:
		return (leader as Node2D).global_position
	if member_records.is_empty():
		return Vector2.ZERO
	var sum: Vector2 = Vector2.ZERO
	for record in member_records:
		var unit = record.get("unit", null)
		if unit is Node2D:
			sum += (unit as Node2D).global_position
	return sum / float(maxi(member_records.size(), 1))


func _extract_advance_style(behavior_profile) -> String:
	if behavior_profile == null:
		return ADVANCE_STYLE_RUSH
	if typeof(behavior_profile) == TYPE_DICTIONARY:
		return String(Dictionary(behavior_profile).get("advance_style", ADVANCE_STYLE_RUSH))
	return String(behavior_profile.advance_style)


func _extract_cover_priority(behavior_profile) -> float:
	if behavior_profile == null:
		return 0.4
	if typeof(behavior_profile) == TYPE_DICTIONARY:
		return clampf(float(Dictionary(behavior_profile).get("cover_priority", 0.4)), 0.0, 1.0)
	return clampf(float(behavior_profile.cover_priority), 0.0, 1.0)


func _extract_cohesion_threshold(behavior_profile) -> float:
	if behavior_profile == null:
		return 100.0
	if typeof(behavior_profile) == TYPE_DICTIONARY:
		return maxf(float(Dictionary(behavior_profile).get("cohesion_threshold", 100.0)), 0.0)
	return maxf(float(behavior_profile.cohesion_threshold), 0.0)


func _extract_execution_profile(behavior_profile) -> Dictionary:
	if behavior_profile == null:
		return {
			"order_fidelity": 0.65,
			"reaction_delay_seconds": 0.25,
			"execution_cohesion": 0.65,
			"execution_fire_discipline": 0.65,
			"contact_stability": 0.65,
			"initiative": 0.5,
			"execution_label": "STEADY",
		}
	var source: Dictionary = {}
	if typeof(behavior_profile) == TYPE_DICTIONARY:
		source = Dictionary(behavior_profile)
	else:
		source = behavior_profile.to_dict() if behavior_profile.has_method("to_dict") else {}
	return {
		"order_fidelity": clampf(float(source.get("order_fidelity", 0.65)), 0.0, 1.0),
		"reaction_delay_seconds": maxf(float(source.get("reaction_delay_seconds", 0.25)), 0.0),
		"execution_cohesion": clampf(float(source.get("execution_cohesion", 0.65)), 0.0, 1.0),
		"execution_fire_discipline": clampf(float(source.get("execution_fire_discipline", 0.65)), 0.0, 1.0),
		"contact_stability": clampf(float(source.get("contact_stability", 0.65)), 0.0, 1.0),
		"initiative": clampf(float(source.get("initiative", 0.5)), 0.0, 1.0),
		"execution_label": String(source.get("execution_label", "STEADY")).strip_edges().to_upper(),
	}


func _apply_execution_target_offset(fireteam_id: String, origin_anchor: Vector2, target_position: Vector2, order_fidelity: float) -> Vector2:
	var instability: float = clampf(1.0 - order_fidelity, 0.0, 1.0)
	if instability <= 0.12:
		return target_position
	var direction: Vector2 = target_position - origin_anchor
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	else:
		direction = direction.normalized()
	var lateral: Vector2 = direction.orthogonal()
	var hash_value: int = abs(fireteam_id.hash())
	var lateral_sign: float = -1.0 if hash_value % 2 == 0 else 1.0
	var lateral_offset: float = lerpf(0.0, 42.0, instability)
	var short_offset: float = lerpf(0.0, 24.0, instability)
	return target_position + (lateral * lateral_sign * lateral_offset) - (direction * short_offset)


func _extract_leader_unit_id(leader, member_records: Array) -> String:
	if leader != null and leader.has_method("get_unit_id"):
		return String(leader.call("get_unit_id")).strip_edges()
	if member_records.is_empty():
		return ""
	return String(member_records[0].get("unit_id", ""))


func _leader_pushes_first(member_records: Array, leader_unit_id: String) -> bool:
	if leader_unit_id.is_empty():
		return false
	for record in member_records:
		if String(record.get("unit_id", "")) != leader_unit_id:
			continue
		var unit = record.get("unit", null)
		if unit == null or not unit.has_method("get_trait_ids"):
			return false
		return PackedStringArray(unit.call("get_trait_ids")).has("reckless")
	return false


func _sort_unit_ids_by_speed(member_records: Array) -> PackedStringArray:
	var sorted_records: Array = member_records.duplicate()
	sorted_records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var speed_a: float = float(a.get("speed", 0.0))
		var speed_b: float = float(b.get("speed", 0.0))
		if absf(speed_a - speed_b) > 0.0001:
			return speed_a > speed_b
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	var result: PackedStringArray = []
	for record in sorted_records:
		result.append(String(record.get("unit_id", "")))
	return result


func _take_best_accuracy_id(remaining_ids: PackedStringArray, member_records: Array) -> String:
	var best_id: String = ""
	var best_accuracy: float = -1.0
	for unit_id in remaining_ids:
		for record in member_records:
			if String(record.get("unit_id", "")) != unit_id:
				continue
			var accuracy: float = float(record.get("accuracy", 0.0))
			if accuracy > best_accuracy:
				best_accuracy = accuracy
				best_id = unit_id
			break
	if best_id.is_empty():
		return ""
	remaining_ids.remove_at(remaining_ids.find(best_id))
	return best_id


func _take_first_id(unit_ids: PackedStringArray) -> String:
	if unit_ids.is_empty():
		return ""
	var value: String = String(unit_ids[0])
	unit_ids.remove_at(0)
	return value


func _packed_unit_ids(member_records: Array) -> PackedStringArray:
	var unit_ids: PackedStringArray = []
	for record in member_records:
		var unit_id: String = String(record.get("unit_id", ""))
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	return unit_ids


func _read_skill_value(unit, method_name: String, fallback: float) -> float:
	if unit == null or not unit.has_method(method_name):
		return fallback
	return clampf(float(unit.call(method_name)), 0.0, 1.0)


func _build_public_state(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return {}
	return {
		"fireteam_id": String(state.get("fireteam_id", "")),
		"phase": int(state.get("phase", -1)),
		"command_type": String(state.get("command_type", "")),
		"raw_style": String(state.get("raw_style", "")),
		"effective_style": String(state.get("effective_style", "")),
		"leader_unit_id": String(state.get("leader_unit_id", "")),
		"stage_index": int(state.get("stage_index", 0)),
		"completed_stage_count": int(state.get("completed_stage_count", 0)),
		"requested_target_position": Vector2(state.get("requested_target_position", state.get("final_target_position", Vector2.ZERO))),
		"current_anchor_target_position": Vector2(state.get("current_anchor_target_position", Vector2.ZERO)),
		"final_target_position": Vector2(state.get("final_target_position", Vector2.ZERO)),
		"order_target_offset": Vector2(state.get("order_target_offset", Vector2.ZERO)),
		"current_target_positions": Dictionary(state.get("current_target_positions", {})).duplicate(true),
		"current_moving_unit_ids": PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray())),
		"current_covering_unit_ids": PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray())),
		"simplified_due_to_losses": bool(state.get("simplified_due_to_losses", false)),
		"order_fidelity": float(state.get("order_fidelity", 0.65)),
		"reaction_delay_seconds": float(state.get("reaction_delay_seconds", 0.25)),
		"execution_cohesion": float(state.get("execution_cohesion", 0.65)),
		"execution_fire_discipline": float(state.get("execution_fire_discipline", 0.65)),
		"contact_stability": float(state.get("contact_stability", 0.65)),
		"initiative": float(state.get("initiative", 0.5)),
		"execution_label": String(state.get("execution_label", "STEADY")),
		"formation_scatter_factor": float(state.get("formation_scatter_factor", 1.0)),
		"move_speed_multiplier": float(state.get("move_speed_multiplier", 1.0)),
	}
