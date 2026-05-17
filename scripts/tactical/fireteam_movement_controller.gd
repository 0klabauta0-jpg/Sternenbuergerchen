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
const MOVE_RUSH_MIN_SPEED_FACTOR: float = 0.92
const MOVE_RUSH_MAX_SPEED_FACTOR: float = 1.22
const MOVE_STANCE_POLICY_ID: String = "move_stance"
const MOVE_STANCE_CAUTIOUS_SPEED_MULTIPLIER: float = 0.65
const MOVE_STANCE_NORMAL_SPEED_MULTIPLIER: float = 1.0
const MOVE_STANCE_AGGRESSIVE_SPEED_MULTIPLIER: float = 1.2
const MOVE_STANCE_CAUTIOUS_SIGHT_FACTOR: float = 1.2
const MOVE_STANCE_NORMAL_SIGHT_FACTOR: float = 1.0
const MOVE_STANCE_AGGRESSIVE_SIGHT_FACTOR: float = 0.65
const BEHAVIOR_STANCE_POLICY_ID: String = "fireteam_behavior"
const WORKBENCH_RUNTIME_SOURCE_ID: String = "fireteam_formation_tuning_2026-05-17T08-46-56-746Z_05"
const STANCE_CAUTIOUS_SPEED_MULTIPLIER: float = 0.35
const STANCE_NORMAL_SPEED_MULTIPLIER: float = 0.65
const STANCE_AGGRESSIVE_SPEED_MULTIPLIER: float = 1.0
const STANCE_CAUTIOUS_SIGHT_FACTOR: float = 1.0
const STANCE_NORMAL_SIGHT_FACTOR: float = 0.8
const STANCE_AGGRESSIVE_SIGHT_FACTOR: float = 0.5
const STANCE_CAUTIOUS_COVER_PRIORITY_PERCENT: float = 75.0
const STANCE_NORMAL_COVER_PRIORITY_PERCENT: float = 45.0
const STANCE_AGGRESSIVE_COVER_PRIORITY_PERCENT: float = 20.0
const STANCE_CAUTIOUS_AIM_READINESS_PERCENT: float = 75.0
const STANCE_NORMAL_AIM_READINESS_PERCENT: float = 30.0
const STANCE_AGGRESSIVE_AIM_READINESS_PERCENT: float = 35.0
const STANCE_CAUTIOUS_CONTACT_INITIATIVE_SECONDS: float = -0.3
const STANCE_NORMAL_CONTACT_INITIATIVE_SECONDS: float = 0.3
const STANCE_AGGRESSIVE_CONTACT_INITIATIVE_SECONDS: float = 0.0
const STANCE_CAUTIOUS_TEAM_TARGET_SUPPORT_PERCENT: float = 5.0
const STANCE_NORMAL_TEAM_TARGET_SUPPORT_PERCENT: float = 0.0
const STANCE_AGGRESSIVE_TEAM_TARGET_SUPPORT_PERCENT: float = -3.0
const DEFEND_STANCE_CAUTIOUS_SPEED_MULTIPLIER: float = 0.8
const DEFEND_STANCE_NORMAL_SPEED_MULTIPLIER: float = 1.0
const DEFEND_STANCE_AGGRESSIVE_SPEED_MULTIPLIER: float = 1.1
const DEFEND_STANCE_CAUTIOUS_SIGHT_FACTOR: float = 1.2
const DEFEND_STANCE_NORMAL_SIGHT_FACTOR: float = 1.0
const DEFEND_STANCE_AGGRESSIVE_SIGHT_FACTOR: float = 0.85
const DEFEND_STANCE_CAUTIOUS_COVER_BONUS: float = 15.0
const DEFEND_STANCE_NORMAL_COVER_BONUS: float = 0.0
const DEFEND_STANCE_AGGRESSIVE_COVER_BONUS: float = -10.0
const DEFEND_STANCE_CAUTIOUS_ATTACK_BONUS: float = -0.03
const DEFEND_STANCE_NORMAL_ATTACK_BONUS: float = 0.0
const DEFEND_STANCE_AGGRESSIVE_ATTACK_BONUS: float = 0.04
const TAKE_STANCE_CAUTIOUS_SPEED_MULTIPLIER: float = 0.7
const TAKE_STANCE_NORMAL_SPEED_MULTIPLIER: float = 1.0
const TAKE_STANCE_AGGRESSIVE_SPEED_MULTIPLIER: float = 1.2
const TAKE_STANCE_CAUTIOUS_SIGHT_FACTOR: float = 1.15
const TAKE_STANCE_NORMAL_SIGHT_FACTOR: float = 1.0
const TAKE_STANCE_AGGRESSIVE_SIGHT_FACTOR: float = 0.75
const TAKE_STANCE_CAUTIOUS_COVER_BONUS: float = 10.0
const TAKE_STANCE_NORMAL_COVER_BONUS: float = 0.0
const TAKE_STANCE_AGGRESSIVE_COVER_BONUS: float = -12.0
const TAKE_STANCE_CAUTIOUS_ATTACK_BONUS: float = 0.0
const TAKE_STANCE_NORMAL_ATTACK_BONUS: float = 0.0
const TAKE_STANCE_AGGRESSIVE_ATTACK_BONUS: float = 0.06
const TAKE_DOCTRINE_ID: String = "take_control_v1"
const TAKE_TARGET_POLICY_OPTIMAL_RANGE_AREA_CONTROL: String = "optimal_range_area_control"
const TAKE_CAUTIOUS_ADVANCE_MODE: String = "cautious_buddy_entry"
const TAKE_NORMAL_ADVANCE_MODE: String = "normal_bounding_clear"
const TAKE_AGGRESSIVE_ADVANCE_MODE: String = "aggressive_assault_line"
const TAKE_CAUTIOUS_ENGAGEMENT_RANGE_FACTOR: float = 0.6
const TAKE_NORMAL_ENGAGEMENT_RANGE_FACTOR: float = 0.7
const TAKE_AGGRESSIVE_ENGAGEMENT_RANGE_FACTOR: float = 0.85
const TAKE_CAUTIOUS_STEP_MULTIPLIER: float = 0.78
const TAKE_CAUTIOUS_FORMATION_SCATTER_FACTOR: float = 0.82
const TAKE_NORMAL_FORMATION_SCATTER_FACTOR: float = 0.96
const TAKE_AGGRESSIVE_FORMATION_SCATTER_FACTOR: float = 1.08
const ENGAGE_STANCE_CAUTIOUS_SPEED_MULTIPLIER: float = 0.75
const ENGAGE_STANCE_NORMAL_SPEED_MULTIPLIER: float = 1.0
const ENGAGE_STANCE_AGGRESSIVE_SPEED_MULTIPLIER: float = 1.15
const ENGAGE_STANCE_CAUTIOUS_SIGHT_FACTOR: float = 1.15
const ENGAGE_STANCE_NORMAL_SIGHT_FACTOR: float = 1.0
const ENGAGE_STANCE_AGGRESSIVE_SIGHT_FACTOR: float = 0.8
const ENGAGE_STANCE_CAUTIOUS_COVER_BONUS: float = 10.0
const ENGAGE_STANCE_NORMAL_COVER_BONUS: float = 0.0
const ENGAGE_STANCE_AGGRESSIVE_COVER_BONUS: float = -8.0
const ENGAGE_STANCE_CAUTIOUS_ATTACK_BONUS: float = 0.02
const ENGAGE_STANCE_NORMAL_ATTACK_BONUS: float = 0.0
const ENGAGE_STANCE_AGGRESSIVE_ATTACK_BONUS: float = 0.08
const ENGAGE_DOCTRINE_ID: String = "engage_control_v1"
const ENGAGE_TARGET_POLICY_WEAPON_RANGE_AREA_PRIORITY: String = "weapon_range_area_priority"
const ENGAGE_CAUTIOUS_ADVANCE_MODE: String = "cautious_buddy_bounds"
const ENGAGE_NORMAL_ADVANCE_MODE: String = "normal_bounding"
const ENGAGE_AGGRESSIVE_ADVANCE_MODE: String = "aggressive_fireline"
const ENGAGE_CAUTIOUS_STEP_MULTIPLIER: float = 0.72
const ENGAGE_CAUTIOUS_FORMATION_SCATTER_FACTOR: float = 0.82
const ENGAGE_NORMAL_FORMATION_SCATTER_FACTOR: float = 0.95
const ENGAGE_AGGRESSIVE_FORMATION_SCATTER_FACTOR: float = 1.05
const BOUNDING_MIN_SPEED_FACTOR: float = 0.52
const BOUNDING_MAX_SPEED_FACTOR: float = 0.92
const CATERPILLAR_MIN_SPEED_FACTOR: float = 0.38
const CATERPILLAR_MAX_SPEED_FACTOR: float = 0.68
const MOVE_TRAVEL_FORMATION_SCATTER_FACTOR: float = 0.85
const MOVE_MAX_FORMATION_SCATTER_FACTOR: float = 1.0
const BASELINE_DIRECT_FORMATION_SCATTER_FACTOR: float = 0.9
const BOUNDING_MIN_STEP_DISTANCE: float = 84.0
const BOUNDING_MAX_STEP_DISTANCE: float = 176.0
const CATERPILLAR_MIN_STEP_DISTANCE: float = 56.0
const CATERPILLAR_MAX_STEP_DISTANCE: float = 104.0
const READABILITY_MULTI_TILE_DISTANCE: float = 48.0
const FORMATION_SLOT_SPACING: float = 64.0
const FORMATION_BUDDY_SLOT_SEPARATION: float = 0.44
const FORMATION_BUDDY_PAIR_STEP: float = 0.72
const FORMATION_BUDDY_PAIR_FORWARD_STEP: float = 0.65
const FORMATION_TRAVEL_COMPACT_SLOT_SCALE: float = 0.72
const MOVE_TRAVEL_MIN_TARGET_SPACING: float = 56.0
const MOVE_CAUTIOUS_PARALLEL_TARGET_SPACING: float = 80.0
const MOVE_NORMAL_PARALLEL_TARGET_SPACING: float = 80.0
const MOVE_AGGRESSIVE_PARALLEL_TARGET_SPACING: float = 112.0
const ENGAGE_CAUTIOUS_FORMATION_SLOT_SPACING: float = 92.0
const ENGAGE_NORMAL_FORMATION_SLOT_SPACING: float = 80.0
const ENGAGE_AGGRESSIVE_PARALLEL_TARGET_SPACING: float = 121.0
const TAKE_CAUTIOUS_FORMATION_SLOT_SPACING: float = 88.0
const TAKE_NORMAL_FORMATION_SLOT_SPACING: float = 82.0
const TAKE_AGGRESSIVE_PARALLEL_TARGET_SPACING: float = 104.0
const FORMATION_MAX_DISTANCE_BASE_FACTOR: float = 1.0
const FORMATION_MAX_DISTANCE_PAIR_FACTOR: float = 0.75
const FORMATION_MAX_DISTANCE_CAP_FACTOR: float = 2.8

var _execution_by_fireteam: Dictionary = {}
var _execution_sequence: int = 0


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
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var raw_style: String = _extract_advance_style(behavior_profile)
	var tactical_stance: String = _extract_tactical_stance(behavior_profile)
	var doctrine_style: String = _resolve_command_advance_style(normalized_command_type, raw_style, tactical_stance)
	var effective_style: String = _resolve_effective_style(doctrine_style, units, member_records)
	var cover_priority: float = _extract_cover_priority(behavior_profile)
	var cohesion_threshold: float = _extract_cohesion_threshold(behavior_profile)
	var execution_profile: Dictionary = _extract_execution_profile(behavior_profile)
	var leader_unit_id: String = _extract_leader_unit_id(leader, member_records)
	var origin_anchor: Vector2 = _resolve_origin_anchor(member_records, leader)
	var resolved_target_position: Vector2 = target_position
	if _uses_execution_target_offset(normalized_command_type):
		resolved_target_position = _apply_execution_target_offset(
			normalized_fireteam_id,
			origin_anchor,
			target_position,
			float(execution_profile.get("order_fidelity", 0.65))
		)
	var formation_scatter_factor: float = lerpf(1.36, 0.88, float(execution_profile.get("execution_cohesion", 0.65)))
	formation_scatter_factor = _resolve_command_formation_scatter_factor(normalized_command_type, tactical_stance, formation_scatter_factor)
	if _uses_baseline_direct_team_movement(normalized_command_type):
		formation_scatter_factor = minf(formation_scatter_factor, MOVE_MAX_FORMATION_SCATTER_FACTOR)
	var formation_preset_key: String = _resolve_workbench_formation_preset_key(normalized_command_type, tactical_stance)
	var formation_preset: Dictionary = _get_workbench_formation_preset(normalized_command_type, tactical_stance)
	var state: Dictionary = {
		"fireteam_id": normalized_fireteam_id,
		"execution_id": _next_execution_id(normalized_fireteam_id),
		"phase": phase_index,
		"command_type": normalized_command_type,
		"raw_style": raw_style,
		"doctrine_style": doctrine_style,
		"effective_style": effective_style,
		"tactical_stance": tactical_stance,
		"leader_unit_id": leader_unit_id,
		"requested_target_position": target_position,
		"final_target_position": resolved_target_position,
		"origin_anchor_position": origin_anchor,
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
		"execution_reason": String(execution_profile.get("execution_reason", "")),
		"execution_hint": String(execution_profile.get("execution_hint", "")),
		"formation_scatter_factor": formation_scatter_factor,
		"formation_slot_spacing_world": _resolve_command_formation_slot_spacing(normalized_command_type, tactical_stance),
		"formation_parallel_spacing_world": _resolve_command_parallel_spacing(normalized_command_type, tactical_stance),
		"formation_preset_key": formation_preset_key,
		"formation_slot_source": WORKBENCH_RUNTIME_SOURCE_ID if not formation_preset.is_empty() else "runtime_fallback",
		"formation_leader_slot": String(formation_preset.get("leader_slot", "")),
		"move_speed_multiplier": lerpf(0.84, 1.08, float(execution_profile.get("initiative", 0.5))),
		"order_target_offset": resolved_target_position - target_position,
		"stage_index": 0,
		"completed_stage_count": 0,
		"current_anchor_origin_position": origin_anchor,
		"current_anchor_target_position": resolved_target_position,
		"current_target_positions": {},
		"current_moving_unit_ids": PackedStringArray(),
		"current_covering_unit_ids": PackedStringArray(),
		"command_revision": 0,
		"groups_issued_for_anchor": 0,
		"group_count_for_anchor": 1,
		"movement_sequence": PackedStringArray(),
		"group_cycle": [],
		"next_group_index": 0,
		"simplified_due_to_losses": (not _uses_baseline_direct_team_movement(normalized_command_type)) and effective_style != doctrine_style,
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
	_reissue_current_stage(state, member_records, simulation_root)
	_execution_by_fireteam[normalized_fireteam_id] = state
	return {"movement_state": _build_public_state(state)}


func update_tactical_stance(fireteam_id: String, tactical_stance: String, units: Array, leader, simulation_root) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {"updated": false, "reason": "empty_fireteam_id"}
	var state: Dictionary = Dictionary(_execution_by_fireteam.get(normalized_fireteam_id, {}))
	if state.is_empty():
		return {"updated": false, "reason": "no_active_execution"}
	if simulation_root == null:
		return {"updated": false, "reason": "missing_simulation_root", "movement_state": _build_public_state(state)}
	var member_records: Array = _build_member_records(units, leader)
	if member_records.is_empty():
		_execution_by_fireteam.erase(normalized_fireteam_id)
		return {"updated": false, "reason": "no_members", "finished": true, "movement_state": {}}
	var normalized_stance: String = _normalize_tactical_stance(tactical_stance)
	var previous_stance: String = _normalize_tactical_stance(String(state.get("tactical_stance", "")))
	state["tactical_stance"] = normalized_stance
	state["command_revision"] = int(state.get("command_revision", 0)) + 1
	_reissue_current_stage(state, member_records, simulation_root)
	_execution_by_fireteam[normalized_fireteam_id] = state
	return {
		"updated": true,
		"changed": normalized_stance != previous_stance,
		"tactical_stance": normalized_stance,
		"movement_state": _build_public_state(state),
	}


func _issue_stage(state: Dictionary, member_records: Array, simulation_root) -> Dictionary:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH))
	var moving_unit_ids: PackedStringArray = PackedStringArray()
	var covering_unit_ids: PackedStringArray = PackedStringArray()
	var group_count: int = 1
	match style:
		ADVANCE_STYLE_BOUNDING:
			var groups: Array = Array(state.get("group_cycle", []))
			if groups.is_empty():
				return {"started": false}
			group_count = maxi(groups.size(), 1)
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
			group_count = maxi(sequence.size(), 1)
			var sequence_index: int = int(state.get("next_group_index", 0)) % sequence.size()
			var moving_unit_id: String = String(sequence[sequence_index])
			moving_unit_ids = PackedStringArray([moving_unit_id])
			for unit_id in _packed_unit_ids(member_records):
				if unit_id != moving_unit_id:
					covering_unit_ids.append(unit_id)
			state["next_group_index"] = (sequence_index + 1) % sequence.size()
		_:
			moving_unit_ids = _packed_unit_ids(member_records)
	var anchor_origin_position: Vector2 = Vector2(state.get("progress_anchor_position", state.get("current_anchor_target_position", Vector2.ZERO)))
	var next_anchor_target: Vector2 = _resolve_stage_anchor_target(state, member_records, group_count)
	var stage_scatter_factor: float = _resolve_stage_formation_scatter_factor(state, next_anchor_target)
	var formation_targets: Dictionary = _build_formation_targets(
		next_anchor_target,
		member_records,
		String(state.get("leader_unit_id", "")),
		stage_scatter_factor,
		_allow_trailing_slots_for_state(state),
		state
	)
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
				_resolve_stage_cover_score(state, float(state.get("cover_priority", 0.0))),
				_resolve_stage_attack_bonus(state, style, true),
				String(state.get("command_type", "")),
				int(state.get("phase", -1)),
				record.get("unit", null),
				_build_stage_command_token(state, unit_id),
				_resolve_stage_movement_posture(state, style, true),
				_resolve_stage_weapon_posture(state, style, true),
				_resolve_stage_posture_policy_id(state),
				_resolve_stage_sight_range_factor(state),
				_resolve_stage_behavior_modifiers(state)
			):
				issued_count += 1
			continue
		if not moving_unit_ids.has(unit_id):
			continue
		var move_target: Vector2 = Vector2(formation_targets.get(unit_id, next_anchor_target))
		move_target = _avoid_backward_move_target(state, Vector2(current_positions.get(unit_id, move_target)), move_target)
		formation_targets[unit_id] = move_target
		var move_speed_factor: float = _build_move_speed_factor(style, String(state.get("command_type", "")), member_records, moving_unit_ids, current_positions, float(state.get("cohesion_threshold", 100.0)), float(record.get("speed", 0.5)), float(state.get("move_speed_multiplier", 1.0)))
		move_speed_factor *= _resolve_behavior_command_speed_multiplier(state)
		var unit_command_type: String = _map_waypoint_command_to_unit_command(String(state.get("command_type", "")))
		if _enqueue_unit_command(
			simulation_root,
			String(record.get("team_id", "")),
			unit_id,
			unit_command_type,
			move_target,
			move_speed_factor,
			_resolve_stage_cover_score(state, float(state.get("cover_priority", 0.0))),
			_resolve_stage_attack_bonus(state, style, false),
			String(state.get("command_type", "")),
			int(state.get("phase", -1)),
			record.get("unit", null),
			_build_stage_command_token(state, unit_id),
			_resolve_stage_movement_posture(state, style, false),
			_resolve_stage_weapon_posture(state, style, false),
			_resolve_stage_posture_policy_id(state),
			_resolve_stage_sight_range_factor(state),
			_resolve_stage_behavior_modifiers(state)
		):
			issued_count += 1
	state["current_anchor_origin_position"] = anchor_origin_position
	state["current_anchor_target_position"] = next_anchor_target
	state["current_target_positions"] = formation_targets
	state["current_moving_unit_ids"] = moving_unit_ids
	state["current_covering_unit_ids"] = covering_unit_ids
	state["group_count_for_anchor"] = group_count
	state["groups_issued_for_anchor"] = int(state.get("groups_issued_for_anchor", 0)) + 1
	if style == ADVANCE_STYLE_RUSH or int(state.get("groups_issued_for_anchor", 0)) >= group_count:
		state["progress_anchor_position"] = next_anchor_target
	return {
		"started": issued_count > 0,
		"issued_count": issued_count,
		"resolved_target_position": Vector2(state.get("final_target_position", next_anchor_target)),
		"effective_advance_style": String(state.get("effective_style", style)),
	}


func _resolve_stage_anchor_target(state: Dictionary, member_records: Array, group_count: int) -> Vector2:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH))
	if style == ADVANCE_STYLE_RUSH:
		state["groups_issued_for_anchor"] = 0
		return _compute_next_anchor_target(state, member_records)
	var groups_issued_for_anchor: int = int(state.get("groups_issued_for_anchor", 0))
	if groups_issued_for_anchor <= 0 or groups_issued_for_anchor >= maxi(group_count, 1):
		state["groups_issued_for_anchor"] = 0
		return _compute_next_anchor_target(state, member_records)
	return Vector2(state.get("current_anchor_target_position", _compute_next_anchor_target(state, member_records)))


func _resolve_stage_formation_scatter_factor(state: Dictionary, next_anchor_target: Vector2) -> float:
	var scatter_factor: float = float(state.get("formation_scatter_factor", 1.0))
	if not _uses_baseline_direct_team_movement(String(state.get("command_type", ""))):
		return scatter_factor
	var final_target_position: Vector2 = Vector2(state.get("final_target_position", next_anchor_target))
	if next_anchor_target.distance_to(final_target_position) > ANCHOR_REACHED_RADIUS:
		return minf(scatter_factor, MOVE_TRAVEL_FORMATION_SCATTER_FACTOR)
	return minf(scatter_factor, BASELINE_DIRECT_FORMATION_SCATTER_FACTOR)


func _allow_trailing_slots_for_state(state: Dictionary) -> bool:
	var command_type: String = String(state.get("command_type", "")).strip_edges().to_lower()
	if command_type == "move":
		return not _uses_baseline_direct_team_movement(command_type)
	if command_type == "engage":
		return _normalize_tactical_stance(String(state.get("tactical_stance", ""))) != FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE
	if command_type == "take":
		return _normalize_tactical_stance(String(state.get("tactical_stance", ""))) != FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE
	return true


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
	var final_targets: Dictionary = _resolve_completion_targets(state, member_records, final_target_position)
	for record in member_records:
		var unit = record.get("unit", null)
		if not (unit is Node2D):
			return false
		var unit_id: String = String(record.get("unit_id", ""))
		var target_position: Vector2 = Vector2(final_targets.get(unit_id, final_target_position))
		if (unit as Node2D).global_position.distance_to(target_position) > POSITION_REACHED_RADIUS:
			return false
	return true


func _resolve_completion_targets(state: Dictionary, member_records: Array, final_target_position: Vector2) -> Dictionary:
	var current_target_positions: Dictionary = Dictionary(state.get("current_target_positions", {}))
	if _target_positions_cover_member_records(current_target_positions, member_records):
		return current_target_positions
	return _build_formation_targets(
		final_target_position,
		member_records,
		String(state.get("leader_unit_id", "")),
		float(state.get("formation_scatter_factor", 1.0)),
		_allow_trailing_slots_for_state(state),
		state
	)


func _target_positions_cover_member_records(target_positions: Dictionary, member_records: Array) -> bool:
	if target_positions.is_empty():
		return false
	for record in member_records:
		var unit_id: String = String(record.get("unit_id", ""))
		if unit_id.is_empty() or not target_positions.has(unit_id):
			return false
	return true


func _reissue_current_stage(state: Dictionary, member_records: Array, simulation_root) -> void:
	if simulation_root == null:
		return
	var moving_unit_ids: PackedStringArray = PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray()))
	if moving_unit_ids.is_empty():
		return
	var covering_unit_ids: PackedStringArray = PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray()))
	var current_target_positions: Dictionary = Dictionary(state.get("current_target_positions", {}))
	var current_positions: Dictionary = _build_current_positions(member_records)
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH))
	for record in member_records:
		var unit_id: String = String(record.get("unit_id", ""))
		if unit_id.is_empty():
			continue
		if covering_unit_ids.has(unit_id):
			_enqueue_unit_command(
				simulation_root,
				String(record.get("team_id", "")),
				unit_id,
				UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION,
				Vector2(current_positions.get(unit_id, state.get("current_anchor_target_position", Vector2.ZERO))),
				0.0,
				_resolve_stage_cover_score(state, float(state.get("cover_priority", 0.0))),
				_resolve_stage_attack_bonus(state, style, true),
				String(state.get("command_type", "")),
				int(state.get("phase", -1)),
				record.get("unit", null),
				_build_stage_command_token(state, unit_id),
				_resolve_stage_movement_posture(state, style, true),
				_resolve_stage_weapon_posture(state, style, true),
				_resolve_stage_posture_policy_id(state),
				_resolve_stage_sight_range_factor(state),
				_resolve_stage_behavior_modifiers(state)
			)
			continue
		if not moving_unit_ids.has(unit_id) or not current_target_positions.has(unit_id):
			continue
		var move_target: Vector2 = _avoid_backward_move_target(state, Vector2(current_positions.get(unit_id, current_target_positions.get(unit_id))), Vector2(current_target_positions.get(unit_id)))
		current_target_positions[unit_id] = move_target
		var move_speed_factor: float = _build_move_speed_factor(style, String(state.get("command_type", "")), member_records, moving_unit_ids, current_positions, float(state.get("cohesion_threshold", 100.0)), float(record.get("speed", 0.5)), float(state.get("move_speed_multiplier", 1.0)))
		move_speed_factor *= _resolve_behavior_command_speed_multiplier(state)
		_enqueue_unit_command(
			simulation_root,
			String(record.get("team_id", "")),
			unit_id,
			_map_waypoint_command_to_unit_command(String(state.get("command_type", ""))),
			move_target,
			move_speed_factor,
			_resolve_stage_cover_score(state, float(state.get("cover_priority", 0.0))),
			_resolve_stage_attack_bonus(state, style, false),
			String(state.get("command_type", "")),
			int(state.get("phase", -1)),
			record.get("unit", null),
			_build_stage_command_token(state, unit_id),
			_resolve_stage_movement_posture(state, style, false),
			_resolve_stage_weapon_posture(state, style, false),
			_resolve_stage_posture_policy_id(state),
			_resolve_stage_sight_range_factor(state),
			_resolve_stage_behavior_modifiers(state)
		)
	state["current_target_positions"] = current_target_positions


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


func _compute_next_anchor_target(state: Dictionary, _member_records: Array) -> Vector2:
	var final_target_position: Vector2 = Vector2(state.get("final_target_position", Vector2.ZERO))
	var current_anchor_position: Vector2 = Vector2(state.get("progress_anchor_position", final_target_position))
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH))
	if style == ADVANCE_STYLE_RUSH:
		return final_target_position
	var direction: Vector2 = final_target_position - current_anchor_position
	if direction.length() <= ANCHOR_REACHED_RADIUS:
		return final_target_position
	var cohesion_threshold: float = maxf(float(state.get("cohesion_threshold", 100.0)), 1.0)
	var step_distance: float = _resolve_non_rush_step_distance(state, cohesion_threshold, direction.length())
	if direction.length() <= step_distance:
		return final_target_position
	return current_anchor_position + direction.normalized() * step_distance


func _build_formation_targets(anchor_position: Vector2, member_records: Array, leader_unit_id: String, scatter_factor: float = 1.0, allow_trailing_slots: bool = true, state: Dictionary = {}) -> Dictionary:
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
	var workbench_targets: Dictionary = _build_workbench_formation_targets(anchor_position, member_records, leader_unit_id, lateral, forward, state)
	if not workbench_targets.is_empty():
		return workbench_targets
	var slot_spacing: float = _resolve_formation_slot_spacing(state)
	for index in range(ordered_records.size()):
		var record: Dictionary = ordered_records[index]
		var slot: Vector2 = _build_buddy_formation_slot(index, ordered_records.size(), allow_trailing_slots)
		var offset: Vector2 = ((lateral * slot.x) + (forward * slot.y)) * slot_spacing * maxf(scatter_factor, 0.5)
		var max_distance: float = _get_formation_max_distance_from_anchor(ordered_records.size(), scatter_factor, slot_spacing)
		if offset.length() > max_distance:
			offset = offset.normalized() * max_distance
		targets[String(record.get("unit_id", ""))] = anchor_position + offset
	if not allow_trailing_slots:
		_apply_parallel_travel_spacing(targets, ordered_records, anchor_position, lateral, scatter_factor, state)
	return targets


func _build_workbench_formation_targets(anchor_position: Vector2, member_records: Array, leader_unit_id: String, lateral: Vector2, forward: Vector2, state: Dictionary) -> Dictionary:
	var preset: Dictionary = _get_workbench_formation_preset(String(state.get("command_type", "")), String(state.get("tactical_stance", "")))
	if preset.is_empty():
		return {}
	var slots_by_unit_id: Dictionary = Dictionary(preset.get("slots_by_unit_id", {}))
	if slots_by_unit_id.is_empty():
		return {}
	var slot_by_record_id: Dictionary = _assign_workbench_slot_keys(member_records, leader_unit_id, String(preset.get("leader_slot", "auto")))
	var targets: Dictionary = {}
	for record in member_records:
		var unit_id: String = String(record.get("unit_id", ""))
		var slot_key: String = String(slot_by_record_id.get(unit_id, ""))
		if slot_key.is_empty() or not slots_by_unit_id.has(slot_key):
			return {}
		var slot: Dictionary = Dictionary(slots_by_unit_id.get(slot_key, {}))
		var offset: Vector2 = lateral * float(slot.get("lateral", 0.0)) + forward * float(slot.get("forward", 0.0))
		targets[unit_id] = anchor_position + offset
	return targets


func _assign_workbench_slot_keys(member_records: Array, leader_unit_id: String, leader_slot: String) -> Dictionary:
	var member_count: int = member_records.size()
	if member_count <= 0:
		return {}
	var slot_keys: Array = []
	for index in range(member_count):
		slot_keys.append("unit_%d" % [index + 1])
	var normalized_leader_slot: String = leader_slot.strip_edges().to_lower()
	if not slot_keys.has(normalized_leader_slot):
		normalized_leader_slot = ""
	var assignments: Dictionary = {}
	var remaining_slots: Array = slot_keys.duplicate()
	var remaining_records: Array = []
	for record in member_records:
		var unit_id: String = String(Dictionary(record).get("unit_id", ""))
		if unit_id.is_empty():
			continue
		if not normalized_leader_slot.is_empty() and unit_id == leader_unit_id:
			assignments[unit_id] = normalized_leader_slot
			remaining_slots.erase(normalized_leader_slot)
			continue
		remaining_records.append(record)
	for index in range(mini(remaining_records.size(), remaining_slots.size())):
		var record: Dictionary = Dictionary(remaining_records[index])
		assignments[String(record.get("unit_id", ""))] = String(remaining_slots[index])
	return assignments


func _apply_parallel_travel_spacing(targets: Dictionary, ordered_records: Array, anchor_position: Vector2, lateral: Vector2, scatter_factor: float, state: Dictionary = {}) -> void:
	if ordered_records.size() <= 1:
		return
	var safe_lateral: Vector2 = lateral.normalized() if not lateral.is_zero_approx() else Vector2.RIGHT
	var compact_spacing: float = FORMATION_SLOT_SPACING * FORMATION_BUDDY_SLOT_SEPARATION * FORMATION_TRAVEL_COMPACT_SLOT_SCALE * maxf(scatter_factor, 0.5)
	var spacing: float = maxf(maxf(compact_spacing, MOVE_TRAVEL_MIN_TARGET_SPACING), _resolve_parallel_travel_spacing(state))
	for index in range(ordered_records.size()):
		var unit_id: String = String(Dictionary(ordered_records[index]).get("unit_id", ""))
		if unit_id.is_empty():
			continue
		targets[unit_id] = anchor_position + safe_lateral * _build_parallel_travel_slot(index, ordered_records.size()) * spacing


func _build_parallel_travel_slot(slot_index: int, member_count: int) -> float:
	if member_count <= 1:
		return 0.0
	return float(slot_index) - ((float(member_count) - 1.0) * 0.5)


func _build_buddy_formation_slot(slot_index: int, member_count: int, allow_trailing_slots: bool) -> Vector2:
	if slot_index <= 0 or member_count <= 1:
		return Vector2.ZERO if member_count <= 1 else Vector2(_build_parallel_travel_slot(slot_index, member_count), 0.0)
	var pair_index: int = int(slot_index / 2)
	var slot := Vector2(_build_parallel_travel_slot(slot_index, member_count), -FORMATION_BUDDY_PAIR_FORWARD_STEP * float(pair_index))
	if not allow_trailing_slots:
		slot.x *= FORMATION_TRAVEL_COMPACT_SLOT_SCALE
		slot.y = 0.0
	return slot


func _get_formation_max_distance_from_anchor(member_count: int, scatter_factor: float, slot_spacing: float = FORMATION_SLOT_SPACING) -> float:
	var pair_count: int = maxi(ceili(float(member_count) / 2.0), 1)
	var distance_factor: float = FORMATION_MAX_DISTANCE_BASE_FACTOR + (float(pair_count - 1) * FORMATION_MAX_DISTANCE_PAIR_FACTOR)
	var cap: float = slot_spacing * FORMATION_MAX_DISTANCE_CAP_FACTOR
	return minf(slot_spacing * distance_factor * maxf(scatter_factor, 0.5), cap)


func _build_current_positions(member_records: Array) -> Dictionary:
	var positions: Dictionary = {}
	for record in member_records:
		var unit = record.get("unit", null)
		if unit is Node2D:
			positions[String(record.get("unit_id", ""))] = (unit as Node2D).global_position
	return positions


func _avoid_backward_move_target(state: Dictionary, current_position: Vector2, target_position: Vector2) -> Vector2:
	var origin_position: Vector2 = Vector2(state.get("current_anchor_origin_position", state.get("origin_anchor_position", current_position)))
	var anchor_target_position: Vector2 = Vector2(state.get("current_anchor_target_position", state.get("final_target_position", target_position)))
	var travel_direction: Vector2 = anchor_target_position - origin_position
	if travel_direction.length_squared() <= 0.001:
		return target_position
	var forward: Vector2 = travel_direction.normalized()
	var target_delta: Vector2 = target_position - origin_position
	var current_progress: float = forward.dot(current_position - origin_position)
	var target_progress: float = forward.dot(target_delta)
	var final_progress: float = forward.dot(anchor_target_position - origin_position)
	if current_progress > final_progress + POSITION_REACHED_RADIUS:
		return target_position
	if target_progress + POSITION_REACHED_RADIUS >= current_progress:
		return target_position
	var lateral_offset: Vector2 = target_delta - (forward * target_progress)
	return origin_position + (forward * current_progress) + lateral_offset


func _build_move_speed_factor(
	style: String,
	command_type: String,
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
			var min_speed_factor: float = RUSH_MIN_SPEED_FACTOR
			var max_speed_factor: float = RUSH_MAX_SPEED_FACTOR
			if command_type == "move":
				min_speed_factor = MOVE_RUSH_MIN_SPEED_FACTOR
				max_speed_factor = MOVE_RUSH_MAX_SPEED_FACTOR
			var base_factor: float = lerpf(min_speed_factor, max_speed_factor, clampf(speed_skill, 0.0, 1.0))
			var spread: float = _compute_group_spread(moving_unit_ids, current_positions)
			if spread <= cohesion_threshold:
				return base_factor * normalized_multiplier
			var slowest_speed: float = speed_skill
			for record in member_records:
				var unit_id: String = String(record.get("unit_id", ""))
				if not moving_unit_ids.has(unit_id):
					continue
				slowest_speed = minf(slowest_speed, float(record.get("speed", speed_skill)))
			return minf(base_factor, lerpf(min_speed_factor, max_speed_factor, clampf(slowest_speed, 0.0, 1.0))) * normalized_multiplier


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


func _resolve_command_advance_style(command_type: String, raw_style: String, tactical_stance: String) -> String:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	if normalized_command_type == "engage":
		return _resolve_engage_advance_style(tactical_stance)
	if normalized_command_type == "take":
		return _resolve_take_advance_style(tactical_stance)
	if _uses_baseline_direct_team_movement(normalized_command_type):
		return ADVANCE_STYLE_RUSH
	return _normalize_advance_style(raw_style)


func _resolve_engage_advance_style(tactical_stance: String) -> String:
	match _normalize_tactical_stance(tactical_stance):
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return ADVANCE_STYLE_RUSH
		_:
			return ADVANCE_STYLE_BOUNDING


func _resolve_take_advance_style(tactical_stance: String) -> String:
	match _normalize_tactical_stance(tactical_stance):
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return ADVANCE_STYLE_RUSH
		_:
			return ADVANCE_STYLE_BOUNDING


func _resolve_command_formation_scatter_factor(command_type: String, tactical_stance: String, fallback: float) -> float:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var normalized_stance: String = _normalize_tactical_stance(tactical_stance)
	if normalized_command_type == "engage":
		match normalized_stance:
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
				return minf(fallback, ENGAGE_CAUTIOUS_FORMATION_SCATTER_FACTOR)
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
				return maxf(fallback, ENGAGE_AGGRESSIVE_FORMATION_SCATTER_FACTOR)
			_:
				return minf(fallback, ENGAGE_NORMAL_FORMATION_SCATTER_FACTOR)
	if normalized_command_type == "take":
		match normalized_stance:
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
				return minf(fallback, TAKE_CAUTIOUS_FORMATION_SCATTER_FACTOR)
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
				return maxf(fallback, TAKE_AGGRESSIVE_FORMATION_SCATTER_FACTOR)
			_:
				return minf(fallback, TAKE_NORMAL_FORMATION_SCATTER_FACTOR)
	return fallback


static func _resolve_workbench_formation_preset_key(command_type: String, tactical_stance: String) -> String:
	var normalized_command_type: String = normalize_behavior_command_type(command_type)
	var normalized_stance: String = normalize_tactical_stance(tactical_stance)
	return "%s:%s" % [normalized_command_type, normalized_stance]


static func _get_workbench_formation_preset(command_type: String, tactical_stance: String) -> Dictionary:
	var preset_key: String = _resolve_workbench_formation_preset_key(command_type, tactical_stance)
	match preset_key:
		"move:cautious":
			return _build_workbench_formation_preset("move", "cautious", "pair_line", "auto", 80.0, 60.0, 163.0, 216.0, {"unit_1": {"lateral": 47.0, "forward": 173.0}, "unit_2": {"lateral": 54.0, "forward": 93.0}, "unit_3": {"lateral": -33.0, "forward": 3.0}, "unit_4": {"lateral": 14.0, "forward": -63.0}})
		"move:normal":
			return _build_workbench_formation_preset("move", "normal", "pair_line", "auto", 117.0, 48.0, 162.0, 216.0, {"unit_1": {"lateral": 43.0, "forward": 118.0}, "unit_2": {"lateral": -39.0, "forward": 24.0}, "unit_3": {"lateral": 21.0, "forward": -43.0}, "unit_4": {"lateral": -32.0, "forward": -138.0}})
		"move:aggressive":
			return _build_workbench_formation_preset("move", "aggressive", "pair_line", "auto", 117.0, 48.0, 162.0, 216.0, {"unit_1": {"lateral": 43.0, "forward": 118.0}, "unit_2": {"lateral": -39.0, "forward": 24.0}, "unit_3": {"lateral": 21.0, "forward": -43.0}, "unit_4": {"lateral": -32.0, "forward": -138.0}})
		"engage:cautious":
			return _build_workbench_formation_preset("engage", "cautious", "staggered_pairs", "unit_3", 74.0, 74.0, 72.0, 216.0, {"unit_1": {"lateral": 31.0, "forward": 76.0}, "unit_2": {"lateral": 64.0, "forward": 13.0}, "unit_3": {"lateral": -9.0, "forward": 6.0}, "unit_4": {"lateral": -43.0, "forward": -62.0}})
		"engage:normal":
			return _build_workbench_formation_preset("engage", "normal", "staggered_pairs", "unit_4", 139.0, 258.0, 30.0, 216.0, {"unit_1": {"lateral": 169.0, "forward": 102.0}, "unit_2": {"lateral": 98.0, "forward": -24.0}, "unit_3": {"lateral": -167.0, "forward": 61.0}, "unit_4": {"lateral": -82.0, "forward": -42.0}})
		"engage:aggressive":
			return _build_workbench_formation_preset("engage", "aggressive", "staggered_pairs", "unit_4", 93.0, 179.0, 20.0, 248.0, {"unit_1": {"lateral": 118.0, "forward": 12.0}, "unit_2": {"lateral": 26.0, "forward": 27.0}, "unit_3": {"lateral": -61.0, "forward": 36.0}, "unit_4": {"lateral": -154.0, "forward": 43.0}})
		"take:aggressive":
			return _build_workbench_formation_preset("take", "aggressive", "staggered_pairs", "unit_4", 70.0, 139.0, 20.0, 216.0, {"unit_1": {"lateral": 79.0, "forward": 15.0}, "unit_2": {"lateral": 24.0, "forward": 24.0}, "unit_3": {"lateral": -45.0, "forward": 36.0}, "unit_4": {"lateral": -130.0, "forward": 42.0}})
		"take:cautious":
			return _build_workbench_formation_preset("take", "cautious", "cautious_entry_pairs", "unit_3", 78.0, 82.0, 76.0, 216.0, {"unit_1": {"lateral": 36.0, "forward": 88.0}, "unit_2": {"lateral": 76.0, "forward": 26.0}, "unit_3": {"lateral": -12.0, "forward": 8.0}, "unit_4": {"lateral": -50.0, "forward": -70.0}})
		"take:normal":
			return _build_workbench_formation_preset("take", "normal", "bounding_clear_pairs", "unit_4", 110.0, 170.0, 36.0, 216.0, {"unit_1": {"lateral": 118.0, "forward": 86.0}, "unit_2": {"lateral": 56.0, "forward": -14.0}, "unit_3": {"lateral": -96.0, "forward": 48.0}, "unit_4": {"lateral": -42.0, "forward": -36.0}})
		"defend:cautious":
			return _build_workbench_formation_preset("defend", "cautious", "defend_360_close", "auto", 72.0, 72.0, 0.0, 196.0, {"unit_1": {"lateral": 0.0, "forward": 52.0}, "unit_2": {"lateral": 58.0, "forward": 0.0}, "unit_3": {"lateral": 0.0, "forward": -52.0}, "unit_4": {"lateral": -58.0, "forward": 0.0}})
		"defend:normal":
			return _build_workbench_formation_preset("defend", "normal", "defend_360_balanced", "auto", 84.0, 84.0, 0.0, 216.0, {"unit_1": {"lateral": 0.0, "forward": 64.0}, "unit_2": {"lateral": 74.0, "forward": 0.0}, "unit_3": {"lateral": 0.0, "forward": -64.0}, "unit_4": {"lateral": -74.0, "forward": 0.0}})
		"defend:aggressive":
			return _build_workbench_formation_preset("defend", "aggressive", "defend_forward_flanks", "auto", 90.0, 96.0, 0.0, 224.0, {"unit_1": {"lateral": 24.0, "forward": 78.0}, "unit_2": {"lateral": 86.0, "forward": 18.0}, "unit_3": {"lateral": -24.0, "forward": -58.0}, "unit_4": {"lateral": -86.0, "forward": 18.0}})
		_:
			return {}


static func _build_workbench_formation_preset(command_type: String, tactical_stance: String, formation_mode: String, leader_slot: String, buddy_spacing_world: float, buddy_pair_spacing_world: float, row_offset_world: float, cohesion_radius_world: float, slots_by_unit_id: Dictionary) -> Dictionary:
	return {
		"source": WORKBENCH_RUNTIME_SOURCE_ID,
		"command": command_type,
		"stance": tactical_stance,
		"formation_mode": formation_mode,
		"leader_slot": leader_slot,
		"buddy_spacing_world": buddy_spacing_world,
		"buddy_pair_spacing_world": buddy_pair_spacing_world,
		"row_offset_world": row_offset_world,
		"cohesion_radius_world": cohesion_radius_world,
		"slots_by_unit_id": slots_by_unit_id,
	}


func _resolve_command_formation_slot_spacing(command_type: String, tactical_stance: String) -> float:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var normalized_stance: String = _normalize_tactical_stance(tactical_stance)
	var workbench_preset: Dictionary = _get_workbench_formation_preset(normalized_command_type, normalized_stance)
	if not workbench_preset.is_empty():
		return float(workbench_preset.get("buddy_spacing_world", FORMATION_SLOT_SPACING))
	if normalized_command_type == "engage":
		match normalized_stance:
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
				return ENGAGE_CAUTIOUS_FORMATION_SLOT_SPACING
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
				return ENGAGE_AGGRESSIVE_PARALLEL_TARGET_SPACING
			_:
				return ENGAGE_NORMAL_FORMATION_SLOT_SPACING
	if normalized_command_type == "take":
		match normalized_stance:
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
				return TAKE_CAUTIOUS_FORMATION_SLOT_SPACING
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
				return TAKE_AGGRESSIVE_PARALLEL_TARGET_SPACING
			_:
				return TAKE_NORMAL_FORMATION_SLOT_SPACING
	return FORMATION_SLOT_SPACING


func _resolve_command_parallel_spacing(command_type: String, tactical_stance: String) -> float:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var normalized_stance: String = _normalize_tactical_stance(tactical_stance)
	var workbench_preset: Dictionary = _get_workbench_formation_preset(normalized_command_type, normalized_stance)
	if not workbench_preset.is_empty():
		return float(workbench_preset.get("buddy_spacing_world", 0.0))
	if normalized_command_type == "move":
		match normalized_stance:
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
				return MOVE_CAUTIOUS_PARALLEL_TARGET_SPACING
			FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
				return MOVE_AGGRESSIVE_PARALLEL_TARGET_SPACING
			_:
				return MOVE_NORMAL_PARALLEL_TARGET_SPACING
	if normalized_command_type == "engage" and normalized_stance == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
		return ENGAGE_AGGRESSIVE_PARALLEL_TARGET_SPACING
	if normalized_command_type == "take" and normalized_stance == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
		return TAKE_AGGRESSIVE_PARALLEL_TARGET_SPACING
	return 0.0


func _resolve_formation_slot_spacing(state: Dictionary) -> float:
	var stored_spacing: float = float(state.get("formation_slot_spacing_world", 0.0))
	if stored_spacing > 0.0:
		return stored_spacing
	return _resolve_command_formation_slot_spacing(
		String(state.get("command_type", "")),
		String(state.get("tactical_stance", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL))
	)


func _resolve_parallel_travel_spacing(state: Dictionary) -> float:
	var stored_spacing: float = float(state.get("formation_parallel_spacing_world", 0.0))
	if stored_spacing > 0.0:
		return stored_spacing
	return _resolve_command_parallel_spacing(
		String(state.get("command_type", "")),
		String(state.get("tactical_stance", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL))
	)


func _normalize_advance_style(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if normalized_value == ADVANCE_STYLE_CREEP:
		return ADVANCE_STYLE_CATERPILLAR
	if normalized_value == ADVANCE_STYLE_CATERPILLAR:
		return ADVANCE_STYLE_CATERPILLAR
	if normalized_value == ADVANCE_STYLE_BOUNDING:
		return ADVANCE_STYLE_BOUNDING
	return ADVANCE_STYLE_RUSH


func _uses_baseline_direct_team_movement(command_type: String) -> bool:
	match command_type.strip_edges().to_lower():
		"move", "defend", "hold", "hold_position":
			return true
		_:
			return false


func _uses_execution_target_offset(command_type: String) -> bool:
	return command_type.strip_edges().to_lower() == "flank"


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
	phase_index: int,
	unit = null,
	command_token: String = "",
	movement_posture: String = "",
	weapon_posture: String = "",
	posture_policy_id: String = "",
	sight_range_factor: float = 1.0,
	behavior_modifiers: Dictionary = {}
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
	command.command_token = command_token
	command.movement_posture = UNIT_COMMAND_SCRIPT.call("normalize_movement_posture", movement_posture, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_IDLE)
	command.weapon_posture = UNIT_COMMAND_SCRIPT.call("normalize_weapon_posture", weapon_posture, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED)
	command.posture_policy_id = posture_policy_id.strip_edges().to_lower()
	command.sight_range_factor = maxf(sight_range_factor, 0.0)
	command.engagement_range_policy = String(behavior_modifiers.get("engagement_range_policy", "")).strip_edges().to_lower()
	command.engagement_range_factor = maxf(float(behavior_modifiers.get("engagement_range_factor", 1.0)), 0.0)
	command.contact_initiative_seconds = float(behavior_modifiers.get("contact_initiative_seconds", 0.0))
	command.aim_readiness_percent = float(behavior_modifiers.get("aim_readiness_percent", 0.0))
	command.team_target_support_percent = float(behavior_modifiers.get("team_target_support_percent", 0.0))
	command.fire_status = _resolve_unit_command_fire_status(command.command_type, command.source_command_type, command.weapon_posture)
	if not bool(command.call("is_valid")):
		return false
	if unit != null and unit.has_method("assign_unit_command"):
		unit.call("assign_unit_command", command)
	var command_dict: Dictionary = command.to_dict()
	_append_behavior_modifier_fields(command_dict, behavior_modifiers)
	command_dict["requeue_until_target"] = command_type != UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
	simulation_root.call("enqueue_command", command_dict)
	return true


func _resolve_unit_command_fire_status(command_type: String, source_command_type: String, weapon_posture: String) -> String:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var normalized_source: String = source_command_type.strip_edges().to_lower()
	var normalized_weapon_posture: String = weapon_posture.strip_edges().to_lower()
	if normalized_command_type == UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION or normalized_command_type == UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA:
		return UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	if normalized_command_type != UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION:
		return UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE
	if ["move", "engage", "take", "defend", "flank"].has(normalized_source):
		return UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	return UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL if normalized_weapon_posture != UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED else UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE


func _resolve_stage_movement_posture(state: Dictionary, style: String, is_covering: bool) -> String:
	var normalized_command_type: String = String(state.get("command_type", "")).strip_edges().to_lower()
	if normalized_command_type == "move" and style == ADVANCE_STYLE_RUSH:
		return _resolve_move_stance_movement_posture(state)
	if normalized_command_type != "move":
		return String(_resolve_stage_behavior_modifiers(state).get("movement_posture", UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE))
	if is_covering:
		return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_OVERWATCH
	match style:
		ADVANCE_STYLE_CATERPILLAR:
			return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_CROUCH_WALK
		ADVANCE_STYLE_BOUNDING:
			return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE
		_:
			if normalized_command_type == "move":
				return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TRAVEL
			return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE


func _resolve_stage_weapon_posture(state: Dictionary, style: String, is_covering: bool) -> String:
	var normalized_command_type: String = String(state.get("command_type", "")).strip_edges().to_lower()
	if normalized_command_type == "move" and style == ADVANCE_STYLE_RUSH:
		return _resolve_move_stance_weapon_posture(state)
	if normalized_command_type != "move":
		return String(_resolve_stage_behavior_modifiers(state).get("weapon_posture", UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED))
	if is_covering:
		return UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED
	if style == ADVANCE_STYLE_RUSH and normalized_command_type == "move":
		return UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED
	return UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED


func _resolve_behavior_command_speed_multiplier(state: Dictionary) -> float:
	return float(_resolve_stage_behavior_modifiers(state).get("speed_multiplier", 1.0))


func _resolve_move_command_speed_multiplier(state: Dictionary) -> float:
	return _resolve_behavior_command_speed_multiplier(state)


func _resolve_stage_sight_range_factor(state: Dictionary) -> float:
	return float(_resolve_stage_behavior_modifiers(state).get("sight_range_factor", 1.0))


func _resolve_stage_posture_policy_id(state: Dictionary) -> String:
	return String(_resolve_stage_behavior_modifiers(state).get("posture_policy_id", ""))


func _resolve_stage_cover_score(state: Dictionary, base_cover_score: float) -> float:
	var modifiers: Dictionary = _resolve_stage_behavior_modifiers(state)
	return maxf(base_cover_score + float(modifiers.get("cover_score_bonus", 0.0)), 0.0)


func _resolve_stage_attack_bonus(state: Dictionary, style: String, is_covering: bool) -> float:
	var base_attack_bonus: float = 0.08 if is_covering else _attack_bonus_for_style(style)
	var modifiers: Dictionary = _resolve_stage_behavior_modifiers(state)
	return base_attack_bonus + float(modifiers.get("attack_bonus", 0.0))


func _resolve_stage_behavior_modifiers(state: Dictionary) -> Dictionary:
	return get_behavior_stance_modifiers(String(state.get("command_type", "")), String(state.get("tactical_stance", "")))


func _append_behavior_modifier_fields(command_dict: Dictionary, behavior_modifiers: Dictionary) -> void:
	if behavior_modifiers.is_empty():
		return
	command_dict["behavior_command_type"] = String(behavior_modifiers.get("command_type", ""))
	command_dict["behavior_tactical_stance"] = String(behavior_modifiers.get("tactical_stance", ""))
	command_dict["behavior_speed_multiplier"] = float(behavior_modifiers.get("speed_multiplier", 1.0))
	command_dict["behavior_sight_range_factor"] = float(behavior_modifiers.get("sight_range_factor", 1.0))
	command_dict["behavior_cover_score_bonus"] = float(behavior_modifiers.get("cover_score_bonus", 0.0))
	command_dict["behavior_attack_bonus"] = float(behavior_modifiers.get("attack_bonus", 0.0))
	command_dict["behavior_movement_posture"] = String(behavior_modifiers.get("movement_posture", ""))
	command_dict["behavior_weapon_posture"] = String(behavior_modifiers.get("weapon_posture", ""))
	command_dict["behavior_cover_priority_percent"] = float(behavior_modifiers.get("cover_priority_percent", 0.0))
	command_dict["behavior_aim_readiness_percent"] = float(behavior_modifiers.get("aim_readiness_percent", 0.0))
	command_dict["contact_initiative_seconds"] = float(behavior_modifiers.get("contact_initiative_seconds", 0.0))
	command_dict["team_target_support_percent"] = float(behavior_modifiers.get("team_target_support_percent", 0.0))
	var behavior_command_type: String = String(behavior_modifiers.get("command_type", "")).strip_edges().to_lower()
	if behavior_modifiers.has("engagement_range_policy"):
		command_dict["engagement_range_policy"] = String(behavior_modifiers.get("engagement_range_policy", ""))
		command_dict["engagement_range_factor"] = float(behavior_modifiers.get("engagement_range_factor", 1.0))
	if behavior_command_type == "engage":
		command_dict["engage_doctrine_id"] = String(behavior_modifiers.get("engage_doctrine_id", ENGAGE_DOCTRINE_ID))
		command_dict["engage_advance_mode"] = String(behavior_modifiers.get("engage_advance_mode", ""))
		command_dict["engage_target_policy"] = String(behavior_modifiers.get("engage_target_policy", ENGAGE_TARGET_POLICY_WEAPON_RANGE_AREA_PRIORITY))
		command_dict["engage_buddy_teams"] = bool(behavior_modifiers.get("engage_buddy_teams", true))
		command_dict["engage_fire_on_weapon_range"] = bool(behavior_modifiers.get("engage_fire_on_weapon_range", true))
	if behavior_command_type == "take":
		command_dict["take_doctrine_id"] = String(behavior_modifiers.get("take_doctrine_id", TAKE_DOCTRINE_ID))
		command_dict["take_advance_mode"] = String(behavior_modifiers.get("take_advance_mode", ""))
		command_dict["take_target_policy"] = String(behavior_modifiers.get("take_target_policy", TAKE_TARGET_POLICY_OPTIMAL_RANGE_AREA_CONTROL))
		command_dict["take_buddy_teams"] = bool(behavior_modifiers.get("take_buddy_teams", true))
		command_dict["take_area_control_required"] = bool(behavior_modifiers.get("take_area_control_required", true))


static func get_behavior_stance_modifiers(command_type: String, tactical_stance: String) -> Dictionary:
	var normalized_command_type: String = normalize_behavior_command_type(command_type)
	var normalized_stance: String = normalize_tactical_stance(tactical_stance)
	match normalized_command_type:
		"defend":
			return _build_defend_stance_modifiers(normalized_stance)
		"take":
			return _build_take_stance_modifiers(normalized_stance)
		"engage":
			return _build_engage_stance_modifiers(normalized_stance)
		_:
			return _build_move_stance_modifiers(normalized_stance)


static func normalize_behavior_command_type(command_type: String) -> String:
	match command_type.strip_edges().to_lower():
		"hold", "hold_position", "defend", "defend_area", "security":
			return "defend"
		"take", "take_area", "objective", "capture":
			return "take"
		"engage", "engage_area", "attack", "attack_area":
			return "engage"
		_:
			return "move"


static func normalize_tactical_stance(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	match normalized_value:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS, "vorsichtig", "careful":
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE, "aggressiv", "aggressive", "fast":
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE
		_:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL


static func _build_move_stance_modifiers(tactical_stance: String) -> Dictionary:
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return _build_stance_modifier_dict("move", tactical_stance, MOVE_STANCE_CAUTIOUS_SPEED_MULTIPLIER, MOVE_STANCE_CAUTIOUS_SIGHT_FACTOR, 0.0, 0.0, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, MOVE_STANCE_POLICY_ID)
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return _build_stance_modifier_dict("move", tactical_stance, MOVE_STANCE_AGGRESSIVE_SPEED_MULTIPLIER, MOVE_STANCE_AGGRESSIVE_SIGHT_FACTOR, 0.0, 0.0, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_RUN, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED, MOVE_STANCE_POLICY_ID)
		_:
			return _build_stance_modifier_dict("move", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL, MOVE_STANCE_NORMAL_SPEED_MULTIPLIER, MOVE_STANCE_NORMAL_SIGHT_FACTOR, 0.0, 0.0, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TRAVEL, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED, MOVE_STANCE_POLICY_ID)


static func _build_defend_stance_modifiers(tactical_stance: String) -> Dictionary:
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return _build_stance_modifier_dict("defend", tactical_stance, DEFEND_STANCE_CAUTIOUS_SPEED_MULTIPLIER, DEFEND_STANCE_CAUTIOUS_SIGHT_FACTOR, DEFEND_STANCE_CAUTIOUS_COVER_BONUS, DEFEND_STANCE_CAUTIOUS_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID)
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return _build_stance_modifier_dict("defend", tactical_stance, DEFEND_STANCE_AGGRESSIVE_SPEED_MULTIPLIER, DEFEND_STANCE_AGGRESSIVE_SIGHT_FACTOR, DEFEND_STANCE_AGGRESSIVE_COVER_BONUS, DEFEND_STANCE_AGGRESSIVE_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID)
		_:
			return _build_stance_modifier_dict("defend", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL, DEFEND_STANCE_NORMAL_SPEED_MULTIPLIER, DEFEND_STANCE_NORMAL_SIGHT_FACTOR, DEFEND_STANCE_NORMAL_COVER_BONUS, DEFEND_STANCE_NORMAL_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TACTICAL, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_READY, BEHAVIOR_STANCE_POLICY_ID)


static func _build_take_stance_modifiers(tactical_stance: String) -> Dictionary:
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return _with_take_doctrine_fields(_build_stance_modifier_dict("take", tactical_stance, TAKE_STANCE_CAUTIOUS_SPEED_MULTIPLIER, TAKE_STANCE_CAUTIOUS_SIGHT_FACTOR, TAKE_STANCE_CAUTIOUS_COVER_BONUS, TAKE_STANCE_CAUTIOUS_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID), tactical_stance)
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return _with_take_doctrine_fields(_build_stance_modifier_dict("take", tactical_stance, TAKE_STANCE_AGGRESSIVE_SPEED_MULTIPLIER, TAKE_STANCE_AGGRESSIVE_SIGHT_FACTOR, TAKE_STANCE_AGGRESSIVE_COVER_BONUS, TAKE_STANCE_AGGRESSIVE_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_RUN, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID), tactical_stance)
		_:
			return _with_take_doctrine_fields(_build_stance_modifier_dict("take", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL, TAKE_STANCE_NORMAL_SPEED_MULTIPLIER, TAKE_STANCE_NORMAL_SIGHT_FACTOR, TAKE_STANCE_NORMAL_COVER_BONUS, TAKE_STANCE_NORMAL_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID), FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)


static func _with_take_doctrine_fields(modifiers: Dictionary, tactical_stance: String) -> Dictionary:
	modifiers["take_doctrine_id"] = TAKE_DOCTRINE_ID
	modifiers["take_target_policy"] = TAKE_TARGET_POLICY_OPTIMAL_RANGE_AREA_CONTROL
	modifiers["take_buddy_teams"] = true
	modifiers["take_area_control_required"] = true
	modifiers["engagement_range_policy"] = TAKE_TARGET_POLICY_OPTIMAL_RANGE_AREA_CONTROL
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			modifiers["take_advance_mode"] = TAKE_CAUTIOUS_ADVANCE_MODE
			modifiers["engagement_range_factor"] = TAKE_CAUTIOUS_ENGAGEMENT_RANGE_FACTOR
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			modifiers["take_advance_mode"] = TAKE_AGGRESSIVE_ADVANCE_MODE
			modifiers["engagement_range_factor"] = TAKE_AGGRESSIVE_ENGAGEMENT_RANGE_FACTOR
		_:
			modifiers["take_advance_mode"] = TAKE_NORMAL_ADVANCE_MODE
			modifiers["engagement_range_factor"] = TAKE_NORMAL_ENGAGEMENT_RANGE_FACTOR
	return modifiers


static func _build_engage_stance_modifiers(tactical_stance: String) -> Dictionary:
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return _with_engage_doctrine_fields(_build_stance_modifier_dict("engage", tactical_stance, ENGAGE_STANCE_CAUTIOUS_SPEED_MULTIPLIER, ENGAGE_STANCE_CAUTIOUS_SIGHT_FACTOR, ENGAGE_STANCE_CAUTIOUS_COVER_BONUS, ENGAGE_STANCE_CAUTIOUS_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID), tactical_stance)
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return _with_engage_doctrine_fields(_build_stance_modifier_dict("engage", tactical_stance, ENGAGE_STANCE_AGGRESSIVE_SPEED_MULTIPLIER, ENGAGE_STANCE_AGGRESSIVE_SIGHT_FACTOR, ENGAGE_STANCE_AGGRESSIVE_COVER_BONUS, ENGAGE_STANCE_AGGRESSIVE_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_RUN, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID), tactical_stance)
		_:
			return _with_engage_doctrine_fields(_build_stance_modifier_dict("engage", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL, ENGAGE_STANCE_NORMAL_SPEED_MULTIPLIER, ENGAGE_STANCE_NORMAL_SIGHT_FACTOR, ENGAGE_STANCE_NORMAL_COVER_BONUS, ENGAGE_STANCE_NORMAL_ATTACK_BONUS, UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE, UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED, BEHAVIOR_STANCE_POLICY_ID), FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)


static func _with_engage_doctrine_fields(modifiers: Dictionary, tactical_stance: String) -> Dictionary:
	modifiers["engage_doctrine_id"] = ENGAGE_DOCTRINE_ID
	modifiers["engage_target_policy"] = ENGAGE_TARGET_POLICY_WEAPON_RANGE_AREA_PRIORITY
	modifiers["engage_buddy_teams"] = true
	modifiers["engage_fire_on_weapon_range"] = true
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			modifiers["engage_advance_mode"] = ENGAGE_CAUTIOUS_ADVANCE_MODE
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			modifiers["engage_advance_mode"] = ENGAGE_AGGRESSIVE_ADVANCE_MODE
		_:
			modifiers["engage_advance_mode"] = ENGAGE_NORMAL_ADVANCE_MODE
	return modifiers


static func _build_stance_modifier_dict(
	command_type: String,
	tactical_stance: String,
	speed_multiplier: float,
	sight_range_factor: float,
	cover_score_bonus: float,
	attack_bonus: float,
	movement_posture: String,
	weapon_posture: String,
	posture_policy_id: String
) -> Dictionary:
	var stance_profile: Dictionary = _get_workbench_stance_profile(tactical_stance)
	var team_target_support_percent: float = float(stance_profile.get("team_target_support_percent", 0.0))
	return {
		"command_type": command_type,
		"tactical_stance": tactical_stance,
		"speed_multiplier": float(stance_profile.get("speed_multiplier", speed_multiplier)),
		"sight_range_factor": float(stance_profile.get("sight_range_factor", sight_range_factor)),
		"cover_score_bonus": float(stance_profile.get("cover_priority_percent", cover_score_bonus)),
		"attack_bonus": team_target_support_percent / 100.0,
		"movement_posture": movement_posture,
		"weapon_posture": weapon_posture,
		"posture_policy_id": posture_policy_id,
		"cover_priority_percent": float(stance_profile.get("cover_priority_percent", cover_score_bonus)),
		"aim_readiness_percent": float(stance_profile.get("aim_readiness_percent", 0.0)),
		"contact_initiative_seconds": float(stance_profile.get("contact_initiative_seconds", 0.0)),
		"team_target_support_percent": team_target_support_percent,
	}


static func _get_workbench_stance_profile(tactical_stance: String) -> Dictionary:
	match normalize_tactical_stance(tactical_stance):
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return {
				"speed_multiplier": STANCE_CAUTIOUS_SPEED_MULTIPLIER,
				"sight_range_factor": STANCE_CAUTIOUS_SIGHT_FACTOR,
				"cover_priority_percent": STANCE_CAUTIOUS_COVER_PRIORITY_PERCENT,
				"aim_readiness_percent": STANCE_CAUTIOUS_AIM_READINESS_PERCENT,
				"contact_initiative_seconds": STANCE_CAUTIOUS_CONTACT_INITIATIVE_SECONDS,
				"team_target_support_percent": STANCE_CAUTIOUS_TEAM_TARGET_SUPPORT_PERCENT,
			}
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return {
				"speed_multiplier": STANCE_AGGRESSIVE_SPEED_MULTIPLIER,
				"sight_range_factor": STANCE_AGGRESSIVE_SIGHT_FACTOR,
				"cover_priority_percent": STANCE_AGGRESSIVE_COVER_PRIORITY_PERCENT,
				"aim_readiness_percent": STANCE_AGGRESSIVE_AIM_READINESS_PERCENT,
				"contact_initiative_seconds": STANCE_AGGRESSIVE_CONTACT_INITIATIVE_SECONDS,
				"team_target_support_percent": STANCE_AGGRESSIVE_TEAM_TARGET_SUPPORT_PERCENT,
			}
		_:
			return {
				"speed_multiplier": STANCE_NORMAL_SPEED_MULTIPLIER,
				"sight_range_factor": STANCE_NORMAL_SIGHT_FACTOR,
				"cover_priority_percent": STANCE_NORMAL_COVER_PRIORITY_PERCENT,
				"aim_readiness_percent": STANCE_NORMAL_AIM_READINESS_PERCENT,
				"contact_initiative_seconds": STANCE_NORMAL_CONTACT_INITIATIVE_SECONDS,
				"team_target_support_percent": STANCE_NORMAL_TEAM_TARGET_SUPPORT_PERCENT,
			}


func _resolve_move_stance_movement_posture(state: Dictionary) -> String:
	match _normalize_tactical_stance(String(state.get("tactical_stance", ""))):
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_ENGAGE
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_RUN
		_:
			return UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TRAVEL


func _resolve_move_stance_weapon_posture(state: Dictionary) -> String:
	if _normalize_tactical_stance(String(state.get("tactical_stance", ""))) == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
		return UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_AIMED
	return UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_LOWERED


func _next_execution_id(fireteam_id: String) -> String:
	_execution_sequence += 1
	return "%s_%d" % [fireteam_id, _execution_sequence]


func _build_stage_command_token(state: Dictionary, unit_id: String) -> String:
	return "%s:%d:%s:%d:r%d:%s" % [
		String(state.get("execution_id", "")),
		int(state.get("phase", -1)),
		String(state.get("command_type", "")),
		int(state.get("stage_index", 0)),
		int(state.get("command_revision", 0)),
		unit_id,
	]


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


func _extract_tactical_stance(behavior_profile) -> String:
	if behavior_profile == null:
		return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL
	if typeof(behavior_profile) == TYPE_DICTIONARY:
		return _normalize_tactical_stance(String(Dictionary(behavior_profile).get("tactical_stance", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)))
	if behavior_profile.has_method("to_dict"):
		return _normalize_tactical_stance(String(Dictionary(behavior_profile.to_dict()).get("tactical_stance", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)))
	return _normalize_tactical_stance(String(behavior_profile.tactical_stance))


func _normalize_tactical_stance(value: String) -> String:
	return normalize_tactical_stance(value)


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
			"execution_reason": "balanced_execution",
			"execution_hint": "No single execution risk dominates this order.",
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
		"execution_reason": String(source.get("execution_reason", "")).strip_edges().to_lower(),
		"execution_hint": String(source.get("execution_hint", "")).strip_edges(),
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


func _build_readability_snapshot(state: Dictionary) -> Dictionary:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH)).strip_edges().to_lower()
	var moving_unit_ids: PackedStringArray = PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray()))
	var covering_unit_ids: PackedStringArray = PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray()))
	var group_count: int = maxi(int(state.get("group_count_for_anchor", 1)), 1)
	var group_index: int = clampi(int(state.get("groups_issued_for_anchor", 1)), 1, group_count)
	var bound_count: int = _estimate_bound_count(state)
	var bound_index: int = clampi(int(floor(float(int(state.get("stage_index", 0))) / float(group_count))) + 1, 1, bound_count)
	var bound_origin_position: Vector2 = Vector2(state.get("current_anchor_origin_position", state.get("progress_anchor_position", Vector2.ZERO)))
	var bound_target_position: Vector2 = Vector2(state.get("current_anchor_target_position", state.get("final_target_position", Vector2.ZERO)))
	var bound_distance: float = bound_origin_position.distance_to(bound_target_position)
	var status_line: String = _build_readability_status_line(style, bound_index, bound_count, group_index, group_count, moving_unit_ids, covering_unit_ids, bool(state.get("simplified_due_to_losses", false)))
	return {
		"advance_style": style,
		"style_code": _get_readability_style_code(style),
		"moving_unit_ids": moving_unit_ids,
		"covering_unit_ids": covering_unit_ids,
		"bound_index": bound_index,
		"bound_count": bound_count,
		"group_index": group_index,
		"group_count": group_count,
		"bound_origin_position": bound_origin_position,
		"bound_target_position": bound_target_position,
		"bound_distance": bound_distance,
		"multi_tile_bound": bound_distance >= READABILITY_MULTI_TILE_DISTANCE,
		"status_line": status_line,
		"movement_sequence": PackedStringArray(state.get("movement_sequence", PackedStringArray())),
		"group_cycle": _duplicate_group_cycle(Array(state.get("group_cycle", []))),
	}


func _estimate_bound_count(state: Dictionary) -> int:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH)).strip_edges().to_lower()
	if style == ADVANCE_STYLE_RUSH:
		return 1
	var origin_anchor_position: Vector2 = Vector2(state.get("origin_anchor_position", state.get("progress_anchor_position", Vector2.ZERO)))
	var final_target_position: Vector2 = Vector2(state.get("final_target_position", origin_anchor_position))
	var travel_distance: float = origin_anchor_position.distance_to(final_target_position)
	if travel_distance <= ANCHOR_REACHED_RADIUS:
		return 1
	var step_distance: float = _estimate_step_distance(state)
	return maxi(int(ceil(travel_distance / maxf(step_distance, 1.0))), 1)


func _estimate_step_distance(state: Dictionary) -> float:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH)).strip_edges().to_lower()
	var cohesion_threshold: float = maxf(float(state.get("cohesion_threshold", 100.0)), 1.0)
	if style == ADVANCE_STYLE_CATERPILLAR or style == ADVANCE_STYLE_BOUNDING:
		return _resolve_non_rush_step_distance(state, cohesion_threshold, INF)
	var origin_anchor_position: Vector2 = Vector2(state.get("origin_anchor_position", state.get("progress_anchor_position", Vector2.ZERO)))
	var final_target_position: Vector2 = Vector2(state.get("final_target_position", origin_anchor_position))
	return maxf(origin_anchor_position.distance_to(final_target_position), 1.0)


func _resolve_non_rush_step_distance(state: Dictionary, cohesion_threshold: float, fallback_distance: float) -> float:
	var style: String = String(state.get("effective_style", ADVANCE_STYLE_RUSH)).strip_edges().to_lower()
	if style == ADVANCE_STYLE_CATERPILLAR:
		return clampf(cohesion_threshold * 0.62, CATERPILLAR_MIN_STEP_DISTANCE, CATERPILLAR_MAX_STEP_DISTANCE)
	if style == ADVANCE_STYLE_BOUNDING:
		var command_type: String = String(state.get("command_type", "")).strip_edges().to_lower()
		var tactical_stance: String = _normalize_tactical_stance(String(state.get("tactical_stance", "")))
		if command_type == "engage" and tactical_stance == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return clampf(cohesion_threshold * ENGAGE_CAUTIOUS_STEP_MULTIPLIER, CATERPILLAR_MIN_STEP_DISTANCE, CATERPILLAR_MAX_STEP_DISTANCE)
		if command_type == "take" and tactical_stance == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			return clampf(cohesion_threshold * TAKE_CAUTIOUS_STEP_MULTIPLIER, CATERPILLAR_MIN_STEP_DISTANCE, CATERPILLAR_MAX_STEP_DISTANCE)
		return clampf(cohesion_threshold * 1.12, BOUNDING_MIN_STEP_DISTANCE, BOUNDING_MAX_STEP_DISTANCE)
	return maxf(fallback_distance, 1.0)


func _get_readability_style_code(style: String) -> String:
	match style.strip_edges().to_lower():
		ADVANCE_STYLE_BOUNDING:
			return "BND"
		ADVANCE_STYLE_CATERPILLAR, ADVANCE_STYLE_CREEP:
			return "CAT"
		ADVANCE_STYLE_RUSH:
			return "RSH"
		_:
			return "MOV"


func _build_readability_status_line(
	style: String,
	bound_index: int,
	bound_count: int,
	group_index: int,
	group_count: int,
	moving_unit_ids: PackedStringArray,
	covering_unit_ids: PackedStringArray,
	simplified_due_to_losses: bool
) -> String:
	var style_code: String = _get_readability_style_code(style)
	var first_part: String = "%s %d/%d" % [style_code, bound_index, maxi(bound_count, 1)]
	if group_count > 1:
		first_part = "%s G%d/%d" % [first_part, group_index, group_count]
	var parts: PackedStringArray = PackedStringArray([first_part])
	parts.append(_format_readability_actor_part(moving_unit_ids, "moves", "move"))
	if not covering_unit_ids.is_empty():
		parts.append(_format_readability_actor_part(covering_unit_ids, "covers", "cover"))
	if simplified_due_to_losses:
		parts.append("LOSS")
	return " | ".join(parts)


func _format_readability_actor_part(unit_ids: PackedStringArray, singular_label: String, plural_label: String) -> String:
	if unit_ids.is_empty():
		return "0 %s" % plural_label
	if unit_ids.size() == 1:
		return "%s %s" % [_compact_unit_id_label(String(unit_ids[0])), singular_label]
	return "%d %s" % [unit_ids.size(), plural_label]


func _compact_unit_id_label(unit_id: String) -> String:
	var normalized: String = unit_id.strip_edges()
	if normalized.is_empty():
		return "-"
	var parts: PackedStringArray = normalized.split("_", false)
	var value: String = normalized
	if not parts.is_empty():
		value = String(parts[parts.size() - 1])
	value = value.substr(0, mini(value.length(), 10))
	return value.to_upper()


func _duplicate_group_cycle(group_cycle: Array) -> Array:
	var result: Array = []
	for group_variant in group_cycle:
		result.append(PackedStringArray(group_variant))
	return result


func _build_public_state(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return {}
	var moving_unit_ids: PackedStringArray = PackedStringArray(state.get("current_moving_unit_ids", PackedStringArray()))
	var covering_unit_ids: PackedStringArray = PackedStringArray(state.get("current_covering_unit_ids", PackedStringArray()))
	var readability: Dictionary = _build_readability_snapshot(state)
	return {
		"fireteam_id": String(state.get("fireteam_id", "")),
		"phase": int(state.get("phase", -1)),
		"command_type": String(state.get("command_type", "")),
		"raw_style": String(state.get("raw_style", "")),
		"doctrine_style": String(state.get("doctrine_style", "")),
		"effective_style": String(state.get("effective_style", "")),
		"advance_style": String(readability.get("advance_style", "")),
		"tactical_stance": String(state.get("tactical_stance", FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL)),
		"move_stance_speed_multiplier": _resolve_move_command_speed_multiplier(state),
		"move_stance_sight_range_factor": _resolve_stage_sight_range_factor(state),
		"style_code": String(readability.get("style_code", "")),
		"leader_unit_id": String(state.get("leader_unit_id", "")),
		"stage_index": int(state.get("stage_index", 0)),
		"command_revision": int(state.get("command_revision", 0)),
		"completed_stage_count": int(state.get("completed_stage_count", 0)),
		"requested_target_position": Vector2(state.get("requested_target_position", state.get("final_target_position", Vector2.ZERO))),
		"origin_anchor_position": Vector2(state.get("origin_anchor_position", state.get("progress_anchor_position", Vector2.ZERO))),
		"progress_anchor_position": Vector2(state.get("progress_anchor_position", Vector2.ZERO)),
		"current_anchor_origin_position": Vector2(state.get("current_anchor_origin_position", state.get("progress_anchor_position", Vector2.ZERO))),
		"current_anchor_target_position": Vector2(state.get("current_anchor_target_position", Vector2.ZERO)),
		"bound_origin_position": Vector2(readability.get("bound_origin_position", Vector2.ZERO)),
		"bound_target_position": Vector2(readability.get("bound_target_position", Vector2.ZERO)),
		"bound_distance": float(readability.get("bound_distance", 0.0)),
		"multi_tile_bound": bool(readability.get("multi_tile_bound", false)),
		"bound_index": int(readability.get("bound_index", 1)),
		"bound_count": int(readability.get("bound_count", 1)),
		"group_index": int(readability.get("group_index", 1)),
		"group_count": int(readability.get("group_count", 1)),
		"group_count_for_anchor": int(state.get("group_count_for_anchor", 1)),
		"groups_issued_for_anchor": int(state.get("groups_issued_for_anchor", 0)),
		"final_target_position": Vector2(state.get("final_target_position", Vector2.ZERO)),
		"order_target_offset": Vector2(state.get("order_target_offset", Vector2.ZERO)),
		"current_target_positions": Dictionary(state.get("current_target_positions", {})).duplicate(true),
		"current_moving_unit_ids": moving_unit_ids,
		"current_covering_unit_ids": covering_unit_ids,
		"moving_unit_ids": moving_unit_ids,
		"covering_unit_ids": covering_unit_ids,
		"movement_sequence": PackedStringArray(state.get("movement_sequence", PackedStringArray())),
		"group_cycle": _duplicate_group_cycle(Array(state.get("group_cycle", []))),
		"readability_status_line": String(readability.get("status_line", "")),
		"map_readability": readability.duplicate(true),
		"simplified_due_to_losses": bool(state.get("simplified_due_to_losses", false)),
		"order_fidelity": float(state.get("order_fidelity", 0.65)),
		"reaction_delay_seconds": float(state.get("reaction_delay_seconds", 0.25)),
		"execution_cohesion": float(state.get("execution_cohesion", 0.65)),
		"execution_fire_discipline": float(state.get("execution_fire_discipline", 0.65)),
		"contact_stability": float(state.get("contact_stability", 0.65)),
		"initiative": float(state.get("initiative", 0.5)),
		"execution_label": String(state.get("execution_label", "STEADY")),
		"execution_reason": String(state.get("execution_reason", "")),
		"execution_hint": String(state.get("execution_hint", "")),
		"formation_scatter_factor": float(state.get("formation_scatter_factor", 1.0)),
		"formation_slot_spacing_world": _resolve_formation_slot_spacing(state),
		"formation_parallel_spacing_world": _resolve_parallel_travel_spacing(state),
		"formation_preset_key": String(state.get("formation_preset_key", "")),
		"formation_slot_source": String(state.get("formation_slot_source", "runtime_fallback")),
		"formation_leader_slot": String(state.get("formation_leader_slot", "")),
		"move_speed_multiplier": float(state.get("move_speed_multiplier", 1.0)),
		"engage_doctrine": _build_engage_doctrine_snapshot(state),
		"take_doctrine": _build_take_doctrine_snapshot(state),
	}


func _build_engage_doctrine_snapshot(state: Dictionary) -> Dictionary:
	if String(state.get("command_type", "")).strip_edges().to_lower() != "engage":
		return {}
	var modifiers: Dictionary = _resolve_stage_behavior_modifiers(state)
	return {
		"doctrine_id": String(modifiers.get("engage_doctrine_id", ENGAGE_DOCTRINE_ID)),
		"advance_mode": String(modifiers.get("engage_advance_mode", "")),
		"target_policy": String(modifiers.get("engage_target_policy", ENGAGE_TARGET_POLICY_WEAPON_RANGE_AREA_PRIORITY)),
		"buddy_teams": bool(modifiers.get("engage_buddy_teams", true)),
		"fire_on_weapon_range": bool(modifiers.get("engage_fire_on_weapon_range", true)),
	}


func _build_take_doctrine_snapshot(state: Dictionary) -> Dictionary:
	if String(state.get("command_type", "")).strip_edges().to_lower() != "take":
		return {}
	var modifiers: Dictionary = _resolve_stage_behavior_modifiers(state)
	return {
		"doctrine_id": String(modifiers.get("take_doctrine_id", TAKE_DOCTRINE_ID)),
		"advance_mode": String(modifiers.get("take_advance_mode", "")),
		"target_policy": String(modifiers.get("take_target_policy", TAKE_TARGET_POLICY_OPTIMAL_RANGE_AREA_CONTROL)),
		"buddy_teams": bool(modifiers.get("take_buddy_teams", true)),
		"area_control_required": bool(modifiers.get("take_area_control_required", true)),
		"engagement_range_policy": String(modifiers.get("engagement_range_policy", "")),
		"engagement_range_factor": float(modifiers.get("engagement_range_factor", 1.0)),
	}
