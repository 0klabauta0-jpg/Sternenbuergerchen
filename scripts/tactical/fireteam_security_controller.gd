class_name FireteamSecurityController
extends RefCounted

const SECURITY_MODE_360: String = "360"
const SECURITY_MODE_DIRECTIONAL: String = "directional"
const DIRECTIONAL_ARC_WIDTH: float = PI * 0.7
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


func update_fireteam_state(
	fireteam_id: String,
	units: Array,
	leader,
	behavior_profile_dict: Dictionary,
	movement_state: Dictionary,
	suppression_state: Dictionary,
	ad_hoc_order: Dictionary,
	threat_inputs: Array
) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var fit_members: Array = _build_fit_members(units)
	if fit_members.is_empty():
		_state_by_fireteam.erase(normalized_fireteam_id)
		return {}
	var anchor_position: Vector2 = _resolve_anchor_position(fit_members, leader)
	var previous_state: Dictionary = Dictionary(_state_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	var threat_info: Dictionary = _resolve_main_threat(anchor_position, threat_inputs)
	var threat_position: Variant = threat_info.get("position", null)
	var threat_distance: float = float(threat_info.get("distance", INF))
	var leadership: float = _read_skill_value(leader, "get_leadership_skill", 0.0)
	var trait_ids: PackedStringArray = PackedStringArray(leader.call("get_trait_ids")) if leader != null and leader.has_method("get_trait_ids") else PackedStringArray()
	var command_type: String = _extract_command_type(behavior_profile_dict)
	var mode: String = _resolve_security_mode(leadership, trait_ids, threat_position)
	var direction_angle: float = float(previous_state.get("direction_angle", 0.0))
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
	var member_assignments: Array = _build_member_assignments(fit_members, mode, direction_angle)
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
		"overwatch_ready": overwatch_ready,
		"is_active": _is_security_active(command_type, fit_members),
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


func _build_member_assignments(fit_members: Array, security_mode: String, direction_angle: float) -> Array:
	var assignments: Array = []
	if fit_members.is_empty():
		return assignments
	if security_mode == SECURITY_MODE_360:
		var sector_width: float = TAU / float(fit_members.size())
		for index in range(fit_members.size()):
			var member: Dictionary = fit_members[index]
			assignments.append({
				"unit_id": String(member.get("unit_id", "")),
				"center_angle": wrapf(direction_angle + (sector_width * float(index)), -PI, PI),
				"arc_width": sector_width,
			})
		return assignments
	for member in fit_members:
		assignments.append({
			"unit_id": String(member.get("unit_id", "")),
			"center_angle": direction_angle,
			"arc_width": DIRECTIONAL_ARC_WIDTH,
		})
	return assignments


func _is_security_active(command_type: String, fit_members: Array) -> bool:
	if fit_members.is_empty():
		return false
	match command_type:
		"defend", "take", "hold_position":
			return true
		_:
			return false


func _is_overwatch_ready(command_type: String, movement_state: Dictionary, suppression_state: Dictionary, ad_hoc_order: Dictionary, fit_members: Array) -> bool:
	if not _is_security_active(command_type, fit_members):
		return false
	if not movement_state.is_empty():
		return false
	if bool(suppression_state.get("is_suppressed", false)):
		return false
	var ad_hoc_type: String = String(ad_hoc_order.get("order_type", "")).strip_edges().to_lower()
	return ad_hoc_type != "disengage" and ad_hoc_type != "fall_back"


func _extract_command_type(behavior_profile_dict: Dictionary) -> String:
	var metadata: Dictionary = Dictionary(behavior_profile_dict.get("metadata", {}))
	var command_type: String = String(metadata.get("origin_command_type", "")).strip_edges().to_lower()
	if command_type.is_empty():
		command_type = "hold_position"
	if command_type == "defend":
		return "hold_position"
	return command_type


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
		"overwatch_ready": bool(state.get("overwatch_ready", false)),
		"is_active": bool(state.get("is_active", false)),
	}
