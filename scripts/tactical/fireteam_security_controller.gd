class_name FireteamSecurityController
extends RefCounted

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const SECURITY_MODE_360: String = "360"
const SECURITY_MODE_DIRECTIONAL: String = "directional"
const DIRECTIONAL_ARC_WIDTH: float = PI * 0.7
const DEFENSE_SCAN_HALF_ANGLE: float = 0.27925268
const DEFENSE_SCAN_CYCLE_MSEC: int = 2600
const DIRECTIONAL_FRONT_PAIR_OFFSET: float = 0.13962634
const DIRECTIONAL_FLANK_OFFSET: float = 1.04719755
const MIN_SHIFT_DELAY_MSEC: int = 250
const MAX_SHIFT_DELAY_MSEC: int = 1200

var _state_by_fireteam: Dictionary = {}


func reset_fireteam(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	_state_by_fireteam.erase(normalized_fireteam_id)


func reset_all() -> void:
	_state_by_fireteam.clear()


func get_fireteam_state(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	return _build_public_state(Dictionary(_state_by_fireteam.get(normalized_fireteam_id, {})))


func get_state_snapshot() -> Array:
	var result: Array = []
	var fireteam_ids: Array = _state_by_fireteam.keys()
	fireteam_ids.sort()
	for fireteam_id in fireteam_ids:
		var state: Dictionary = get_fireteam_state(String(fireteam_id))
		if state.is_empty():
			continue
		result.append(state)
	return result


static func normalize_enemy_security_mode(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if normalized_value == SECURITY_MODE_360:
		return SECURITY_MODE_360
	return SECURITY_MODE_DIRECTIONAL


static func resolve_facing_angle(facing: String, fallback_angle: float = 0.0) -> float:
	match facing.strip_edges().to_lower():
		"east":
			return 0.0
		"south_east":
			return PI * 0.25
		"south":
			return PI * 0.5
		"south_west":
			return PI * 0.75
		"west":
			return PI
		"north_west":
			return -PI * 0.75
		"north":
			return -PI * 0.5
		"north_east":
			return -PI * 0.25
		_:
			return fallback_angle


static func build_enemy_member_assignments(units: Array, security_mode: String, direction_angle: float, terrain_registry = null) -> Array:
	var assignments: Array = []
	var normalized_mode: String = normalize_enemy_security_mode(security_mode)
	var fit_units: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		fit_units.append(unit)
	if fit_units.is_empty():
		return assignments
	if normalized_mode == SECURITY_MODE_360:
		var sector_width: float = TAU / float(fit_units.size())
		for index in range(fit_units.size()):
			var unit = fit_units[index]
			assignments.append(_build_enemy_assignment(unit, wrapf(direction_angle + (sector_width * float(index)), -PI, PI), sector_width, terrain_registry))
		return assignments
	for unit in fit_units:
		assignments.append(_build_enemy_assignment(unit, direction_angle, DIRECTIONAL_ARC_WIDTH, terrain_registry))
	return assignments


func update_fireteam_state(
	fireteam_id: String,
	units: Array,
	leader,
	behavior_profile_dict: Dictionary,
	movement_state: Dictionary,
	suppression_state: Dictionary,
	ad_hoc_order: Dictionary,
	threat_inputs: Array,
	area_context: Dictionary = {}
) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var fit_members: Array = _build_fit_members(units)
	if fit_members.is_empty():
		_state_by_fireteam.erase(normalized_fireteam_id)
		return {}
	var anchor_position: Vector2 = _resolve_anchor_position(fit_members, leader)
	if typeof(area_context.get("center_position", null)) == TYPE_VECTOR2:
		anchor_position = Vector2(area_context.get("center_position"))
	var previous_state: Dictionary = Dictionary(_state_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	var threat_info: Dictionary = _resolve_main_threat(anchor_position, threat_inputs)
	var threat_position: Variant = threat_info.get("position", null)
	var threat_distance: float = float(threat_info.get("distance", INF))
	var leadership: float = _read_skill_value(leader, "get_leadership_skill", 0.0)
	var trait_ids: PackedStringArray = PackedStringArray(leader.call("get_trait_ids")) if leader != null and leader.has_method("get_trait_ids") else PackedStringArray()
	var command_type: String = _extract_command_type(behavior_profile_dict, area_context)
	var mode_override: String = _resolve_security_mode_override(behavior_profile_dict, area_context)
	var mode: String = mode_override if not mode_override.is_empty() else _resolve_security_mode(leadership, trait_ids, threat_position)
	var security_radius_world: float = _extract_security_radius_world(behavior_profile_dict, area_context)
	var security_radius_tiles: int = _extract_security_radius_tiles(behavior_profile_dict, area_context)
	var direction_angle: float = float(previous_state.get("direction_angle", _extract_security_direction_angle(behavior_profile_dict, area_context)))
	var now_msec: int = Time.get_ticks_msec()
	if previous_state.is_empty() and typeof(threat_position) == TYPE_VECTOR2:
		direction_angle = (Vector2(threat_position) - anchor_position).angle()
	var pending_angle: Variant = previous_state.get("pending_direction_angle", null)
	var pending_ready_at_msec: int = int(previous_state.get("pending_shift_ready_at_msec", 0))
	if mode == SECURITY_MODE_DIRECTIONAL and typeof(threat_position) == TYPE_VECTOR2:
		var desired_angle: float = (Vector2(threat_position) - anchor_position).angle()
		if _angle_within_sector(desired_angle, direction_angle, DIRECTIONAL_ARC_WIDTH):
			direction_angle = desired_angle
			pending_angle = null
			pending_ready_at_msec = 0
		else:
			if leadership > 0.7:
				direction_angle = desired_angle
				pending_angle = null
				pending_ready_at_msec = 0
			elif leadership >= 0.4:
				if typeof(pending_angle) != TYPE_FLOAT or absf(float(pending_angle) - desired_angle) > 0.01:
					pending_angle = desired_angle
					pending_ready_at_msec = now_msec + _build_shift_delay_msec(leadership)
				elif now_msec >= pending_ready_at_msec:
					direction_angle = desired_angle
					pending_angle = null
					pending_ready_at_msec = 0
	else:
		pending_angle = null
		pending_ready_at_msec = 0
		if typeof(threat_position) == TYPE_VECTOR2:
			direction_angle = (Vector2(threat_position) - anchor_position).angle()
	var member_assignments: Array = _build_member_assignments(fit_members, mode, direction_angle, security_radius_world, now_msec)
	var defense_ready: bool = _is_defense_ready(command_type, movement_state, suppression_state, ad_hoc_order, fit_members)
	var overwatch_ready: bool = _is_overwatch_ready(command_type, movement_state, suppression_state, ad_hoc_order, fit_members)
	var state: Dictionary = {
		"fireteam_id": normalized_fireteam_id,
		"security_mode": mode,
		"anchor_position": anchor_position,
		"direction_angle": direction_angle,
		"pending_direction_angle": pending_angle,
		"pending_shift_ready_at_msec": pending_ready_at_msec,
		"leader_unit_id": String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else "",
		"command_type": command_type,
		"main_threat_position": Vector2(threat_position) if typeof(threat_position) == TYPE_VECTOR2 else null,
		"main_threat_distance": threat_distance,
		"member_assignments": member_assignments,
		"overwatch_unit_ids": _build_overwatch_unit_ids(member_assignments) if overwatch_ready else PackedStringArray(),
		"security_radius_world": security_radius_world,
		"security_radius_tiles": security_radius_tiles,
		"defense_ready": defense_ready,
		"overwatch_ready": overwatch_ready,
		"is_active": _is_security_active(command_type, fit_members),
		"area_order_id": String(area_context.get("area_order_id", "")),
		"area_center_position": Vector2(area_context.get("center_position", anchor_position)) if typeof(area_context.get("center_position", null)) == TYPE_VECTOR2 else null,
		"area_status": String(area_context.get("status", "")),
	}
	_state_by_fireteam[normalized_fireteam_id] = state
	return _build_public_state(state)


func _build_fit_members(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		result.append({
			"unit": unit,
			"unit_id": String(unit.call("get_unit_id")),
			"accuracy": _read_skill_value(unit, "get_accuracy_skill", 0.5),
			"is_leader": bool(unit.get("is_fireteam_lead")) if unit.has_method("get") else false,
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("is_leader", false)) != bool(b.get("is_leader", false)):
			return bool(a.get("is_leader", false))
		var accuracy_a: float = float(a.get("accuracy", 0.0))
		var accuracy_b: float = float(b.get("accuracy", 0.0))
		if absf(accuracy_a - accuracy_b) > 0.0001:
			return accuracy_a > accuracy_b
		return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
	)
	return result


static func _build_enemy_assignment(unit, center_angle: float, arc_width: float, terrain_registry = null) -> Dictionary:
	var weapon_id: String = ""
	if unit != null and unit.has_method("get_active_weapon_id"):
		weapon_id = String(unit.call("get_active_weapon_id")).strip_edges()
	if not bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", weapon_id)):
		weapon_id = String(WEAPON_DATA_SCRIPT.DEFAULT_WEAPON_ID)
	return {
		"unit_id": String(unit.call("get_unit_id")) if unit != null and unit.has_method("get_unit_id") else "",
		"center_angle": center_angle,
		"arc_width": arc_width,
		"weapon_id": String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", weapon_id)),
		"weapon_tile_range": int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id)),
		"weapon_range_world": float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", weapon_id, terrain_registry)),
	}


func _resolve_anchor_position(fit_members: Array, leader) -> Vector2:
	if leader is Node2D:
		return (leader as Node2D).global_position
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for member in fit_members:
		var unit = member.get("unit", null)
		if not (unit is Node2D):
			continue
		sum += (unit as Node2D).global_position
		count += 1
	if count <= 0:
		return Vector2.ZERO
	return sum / float(count)


func _resolve_main_threat(anchor_position: Vector2, threat_inputs: Array) -> Dictionary:
	var best_threat: Dictionary = {}
	var best_rank: int = -1
	var best_distance: float = INF
	for threat_input in threat_inputs:
		var threat_info: Dictionary = _coerce_threat_info(threat_input, anchor_position)
		if threat_info.is_empty():
			continue
		var threat_rank: int = _contact_state_rank(String(threat_info.get("detection_state", "confirmed")))
		var threat_distance: float = float(threat_info.get("distance", INF))
		if threat_rank < best_rank:
			continue
		if threat_rank == best_rank and threat_distance >= best_distance:
			continue
		best_rank = threat_rank
		best_distance = threat_distance
		best_threat = threat_info
	return best_threat


func _coerce_threat_info(threat_input, anchor_position: Vector2) -> Dictionary:
	if typeof(threat_input) == TYPE_DICTIONARY:
		var threat_dict: Dictionary = Dictionary(threat_input)
		var threat_state: String = String(threat_dict.get("detection_state", "")).strip_edges().to_lower()
		if threat_state == "unknown":
			return {}
		var threat_position: Vector2 = _coerce_vector2(threat_dict.get("last_known_position", threat_dict.get("position", Vector2.ZERO)), Vector2.ZERO)
		return {
			"unit_id": String(threat_dict.get("unit_id", "")),
			"position": threat_position,
			"distance": anchor_position.distance_to(threat_position),
			"detection_state": threat_state if not threat_state.is_empty() else "confirmed",
		}
	if threat_input == null or not (threat_input is Node2D) or not threat_input.has_method("get_vital_state"):
		return {}
	if String(threat_input.call("get_vital_state")) != "fit":
		return {}
	if threat_input is CanvasItem and not (threat_input as CanvasItem).visible:
		return {}
	var threat_node: Node2D = threat_input
	return {
		"unit_id": String(threat_input.call("get_unit_id")) if threat_input.has_method("get_unit_id") else "",
		"position": threat_node.global_position,
		"distance": anchor_position.distance_to(threat_node.global_position),
		"detection_state": "confirmed",
	}


func _contact_state_rank(detection_state: String) -> int:
	match detection_state.strip_edges().to_lower():
		"confirmed":
			return 4
		"spotted":
			return 3
		"lost":
			return 2
		"suspected":
			return 1
		_:
			return 0


func _resolve_security_mode(leadership: float, trait_ids: PackedStringArray, threat_position) -> String:
	if leadership < 0.55:
		return SECURITY_MODE_DIRECTIONAL
	if typeof(threat_position) == TYPE_VECTOR2 and trait_ids.has("aggressive"):
		return SECURITY_MODE_DIRECTIONAL
	return SECURITY_MODE_360


func _resolve_security_mode_override(behavior_profile_dict: Dictionary, area_context: Dictionary = {}) -> String:
	var area_mode: String = _normalize_security_mode(area_context.get("security_mode", ""))
	if not area_mode.is_empty():
		return area_mode
	var metadata: Dictionary = Dictionary(behavior_profile_dict.get("metadata", {}))
	for key in ["security_mode_override", "security_mode"]:
		var metadata_mode: String = _normalize_security_mode(metadata.get(key, ""))
		if not metadata_mode.is_empty():
			return metadata_mode
	return ""


func _normalize_security_mode(value: Variant) -> String:
	var normalized_value: String = String(value).strip_edges().to_lower()
	normalized_value = normalized_value.replace("_", "-").replace(" ", "-")
	match normalized_value:
		"360", "360-security", "360-degree", "all-round", "allround", "all-around", "omni", "omnidirectional":
			return SECURITY_MODE_360
		"directional", "sector", "sector-security", "facing", "front", "forward", "arc":
			return SECURITY_MODE_DIRECTIONAL
		_:
			return ""


func _build_member_assignments(fit_members: Array, security_mode: String, direction_angle: float, security_radius_world: float = 0.0, now_msec: int = 0) -> Array:
	var assignments: Array = []
	if fit_members.is_empty():
		return assignments
	if security_mode == SECURITY_MODE_360:
		var sector_width: float = TAU / float(fit_members.size())
		for index in range(fit_members.size()):
			var member: Dictionary = fit_members[index]
			var base_angle: float = _resolve_360_member_angle(index, fit_members.size(), direction_angle, sector_width)
			var scan_offset: float = _build_defense_scan_offset(index, now_msec)
			assignments.append({
				"unit_id": String(member.get("unit_id", "")),
				"base_angle": base_angle,
				"scan_offset_angle": scan_offset,
				"center_angle": wrapf(base_angle + scan_offset, -PI, PI),
				"arc_width": sector_width,
				"coverage_role": _resolve_360_coverage_role(index),
				"security_radius_world": security_radius_world,
			})
		return assignments
	var member_count: int = fit_members.size()
	for index in range(member_count):
		var member: Dictionary = fit_members[index]
		var assignment_offset: Dictionary = _resolve_directional_assignment_offset(index, member_count)
		var base_angle: float = wrapf(direction_angle + float(assignment_offset.get("offset", 0.0)), -PI, PI)
		var scan_offset: float = _build_defense_scan_offset(index, now_msec)
		assignments.append({
			"unit_id": String(member.get("unit_id", "")),
			"base_angle": base_angle,
			"scan_offset_angle": scan_offset,
			"center_angle": wrapf(base_angle + scan_offset, -PI, PI),
			"arc_width": DIRECTIONAL_ARC_WIDTH,
			"coverage_role": String(assignment_offset.get("coverage_role", "front")),
			"security_radius_world": security_radius_world,
		})
	return assignments


func _resolve_360_member_angle(index: int, member_count: int, direction_angle: float, sector_width: float) -> float:
	if member_count <= 1:
		return direction_angle
	var cardinal_angles: Array[float] = [-PI * 0.5, 0.0, PI * 0.5, PI]
	if index < cardinal_angles.size():
		return float(cardinal_angles[index])
	return wrapf(direction_angle + (sector_width * float(index)), -PI, PI)


func _resolve_360_coverage_role(index: int) -> String:
	match index:
		0:
			return "north"
		1:
			return "east"
		2:
			return "south"
		3:
			return "west"
		_:
			return "360_extra"


func _resolve_directional_assignment_offset(index: int, member_count: int) -> Dictionary:
	if member_count <= 1:
		return {"offset": 0.0, "coverage_role": "front"}
	if member_count == 2:
		return {
			"offset": -DIRECTIONAL_FRONT_PAIR_OFFSET if index == 0 else DIRECTIONAL_FRONT_PAIR_OFFSET,
			"coverage_role": "front_left" if index == 0 else "front_right",
		}
	if member_count == 3:
		match index:
			0:
				return {"offset": 0.0, "coverage_role": "front"}
			1:
				return {"offset": -DIRECTIONAL_FLANK_OFFSET, "coverage_role": "left_flank"}
			_:
				return {"offset": DIRECTIONAL_FLANK_OFFSET, "coverage_role": "right_flank"}
	match index:
		0:
			return {"offset": -DIRECTIONAL_FRONT_PAIR_OFFSET, "coverage_role": "front_left"}
		1:
			return {"offset": DIRECTIONAL_FRONT_PAIR_OFFSET, "coverage_role": "front_right"}
		2:
			return {"offset": -DIRECTIONAL_FLANK_OFFSET, "coverage_role": "left_flank"}
		3:
			return {"offset": DIRECTIONAL_FLANK_OFFSET, "coverage_role": "right_flank"}
		_:
			var side: float = -1.0 if index % 2 == 0 else 1.0
			return {"offset": side * DIRECTIONAL_FLANK_OFFSET, "coverage_role": "flank_extra"}


func _build_defense_scan_offset(index: int, now_msec: int) -> float:
	if DEFENSE_SCAN_CYCLE_MSEC <= 0:
		return 0.0
	var phase: float = fposmod(float(now_msec + (index * 419)), float(DEFENSE_SCAN_CYCLE_MSEC)) / float(DEFENSE_SCAN_CYCLE_MSEC)
	return sin(phase * TAU) * DEFENSE_SCAN_HALF_ANGLE


func _is_security_active(command_type: String, fit_members: Array) -> bool:
	if fit_members.is_empty():
		return false
	match command_type:
		"defend", "defend_area", "take", "engage", "hold_position":
			return true
		_:
			return false


func _is_defense_ready(command_type: String, movement_state: Dictionary, suppression_state: Dictionary, ad_hoc_order: Dictionary, fit_members: Array) -> bool:
	if not _is_security_active(command_type, fit_members):
		return false
	if not movement_state.is_empty():
		return false
	if bool(suppression_state.get("is_suppressed", false)):
		return false
	var ad_hoc_type: String = String(ad_hoc_order.get("order_type", "")).strip_edges().to_lower()
	return ad_hoc_type != "disengage" and ad_hoc_type != "fall_back"


func _is_overwatch_ready(_command_type: String, _movement_state: Dictionary, _suppression_state: Dictionary, _ad_hoc_order: Dictionary, _fit_members: Array) -> bool:
	return false


func _extract_command_type(behavior_profile_dict: Dictionary, area_context: Dictionary = {}) -> String:
	var area_command_type: String = String(area_context.get("command_type", "")).strip_edges().to_lower()
	if not area_command_type.is_empty():
		return area_command_type
	var metadata: Dictionary = Dictionary(behavior_profile_dict.get("metadata", {}))
	var command_type: String = String(metadata.get("origin_command_type", "")).strip_edges().to_lower()
	if command_type.is_empty():
		command_type = "defend"
	return command_type


func _extract_security_radius_world(behavior_profile_dict: Dictionary, area_context: Dictionary = {}) -> float:
	var area_radius: float = float(area_context.get("security_radius_world", 0.0))
	if area_radius > 0.0:
		return area_radius
	var metadata: Dictionary = Dictionary(behavior_profile_dict.get("metadata", {}))
	return maxf(float(metadata.get("security_radius_world", 0.0)), 0.0)


func _extract_security_radius_tiles(behavior_profile_dict: Dictionary, area_context: Dictionary = {}) -> int:
	var area_radius_tiles: int = int(area_context.get("security_radius_tiles", 0))
	if area_radius_tiles > 0:
		return area_radius_tiles
	var metadata: Dictionary = Dictionary(behavior_profile_dict.get("metadata", {}))
	return maxi(int(metadata.get("security_radius_tiles", 0)), 0)


func _extract_security_direction_angle(behavior_profile_dict: Dictionary, area_context: Dictionary = {}) -> float:
	if area_context.has("security_direction_angle"):
		return float(area_context.get("security_direction_angle", 0.0))
	var metadata: Dictionary = Dictionary(behavior_profile_dict.get("metadata", {}))
	return float(metadata.get("security_direction_angle", 0.0))


func _build_shift_delay_msec(leadership: float) -> int:
	var t: float = clampf((leadership - 0.4) / 0.3, 0.0, 1.0)
	return int(roundi(lerpf(float(MAX_SHIFT_DELAY_MSEC), float(MIN_SHIFT_DELAY_MSEC), t)))


func _angle_within_sector(target_angle: float, center_angle: float, arc_width: float) -> bool:
	return absf(wrapf(target_angle - center_angle, -PI, PI)) <= arc_width * 0.5


func _read_skill_value(unit, method_name: String, fallback: float) -> float:
	if unit == null or not unit.has_method(method_name):
		return fallback
	return clampf(float(unit.call(method_name)), 0.0, 1.0)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


func _build_public_state(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return {}
	return {
		"fireteam_id": String(state.get("fireteam_id", "")),
		"security_mode": String(state.get("security_mode", SECURITY_MODE_DIRECTIONAL)),
		"anchor_position": Vector2(state.get("anchor_position", Vector2.ZERO)),
		"direction_angle": float(state.get("direction_angle", 0.0)),
		"leader_unit_id": String(state.get("leader_unit_id", "")),
		"command_type": String(state.get("command_type", "")),
		"main_threat_position": state.get("main_threat_position", null),
		"main_threat_distance": float(state.get("main_threat_distance", INF)),
		"member_assignments": Array(state.get("member_assignments", [])).duplicate(true),
		"overwatch_unit_ids": PackedStringArray(state.get("overwatch_unit_ids", PackedStringArray())),
		"security_radius_world": float(state.get("security_radius_world", 0.0)),
		"security_radius_tiles": int(state.get("security_radius_tiles", 0)),
		"defense_ready": bool(state.get("defense_ready", false)),
		"overwatch_ready": bool(state.get("overwatch_ready", false)),
		"is_active": bool(state.get("is_active", false)),
		"area_order_id": String(state.get("area_order_id", "")),
		"area_center_position": state.get("area_center_position", null),
		"area_status": String(state.get("area_status", "")),
	}


func _build_overwatch_unit_ids(member_assignments: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for assignment_variant in member_assignments:
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(assignment_variant).get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or result.has(unit_id):
			continue
		result.append(unit_id)
	return result
