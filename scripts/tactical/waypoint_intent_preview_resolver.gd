class_name WaypointIntentPreviewResolver
extends RefCounted

const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const DEFAULT_SPEED_WORLD_PER_SECOND: float = 96.0


func build_preview_entries(plan_dicts: Array, fireteam_anchor_dicts: Array, options: Dictionary = {}) -> Array:
	var phase_index: int = maxi(int(options.get("phase_index", 0)), 0)
	var selected_fireteam_ids: PackedStringArray = _coerce_string_array(options.get("selected_fireteam_ids", PackedStringArray()))
	var speed_by_fireteam: Dictionary = Dictionary(options.get("speed_world_per_second_by_fireteam", {}))
	var threat_analyzer = options.get("threat_analyzer", null)
	var threat_context_by_fireteam: Dictionary = Dictionary(options.get("threat_context_by_fireteam", {}))
	var anchor_by_fireteam: Dictionary = _build_anchor_lookup(fireteam_anchor_dicts)
	var entries: Array = []
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", Dictionary(plan_variant))
		if plan == null or not plan.is_valid() or int(plan.phase) != phase_index:
			continue
		var fireteam_id: String = String(plan.fireteam_id).strip_edges().to_lower()
		if fireteam_id.is_empty() or not _is_selected(fireteam_id, selected_fireteam_ids):
			continue
		if not _is_pending_plan(plan):
			continue
		var anchor_position: Variant = anchor_by_fireteam.get(fireteam_id, null)
		if typeof(anchor_position) != TYPE_VECTOR2:
			continue
		var entry: Dictionary = _build_entry_for_plan(plan, Vector2(anchor_position), float(speed_by_fireteam.get(fireteam_id, DEFAULT_SPEED_WORLD_PER_SECOND)))
		if entry.is_empty():
			continue
		_apply_threat_analysis(entry, threat_analyzer, Dictionary(threat_context_by_fireteam.get(fireteam_id, {})))
		entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("fireteam_id", "")) < String(b.get("fireteam_id", ""))
	)
	return entries


func _build_entry_for_plan(plan, anchor_position: Vector2, speed_world_per_second: float) -> Dictionary:
	var points: Array = [anchor_position]
	var segments: Array = []
	var total_distance: float = 0.0
	var pending_waypoint_count: int = 0
	var previous_position: Vector2 = anchor_position
	for waypoint_index in range(plan.waypoints.size()):
		var waypoint = _coerce_waypoint(plan.waypoints[waypoint_index])
		if waypoint == null or not _is_pending_waypoint(waypoint):
			continue
		if typeof(waypoint.target_position) != TYPE_VECTOR2:
			continue
		var target_position: Vector2 = Vector2(waypoint.target_position)
		var segment_distance: float = previous_position.distance_to(target_position)
		total_distance += segment_distance
		points.append(target_position)
		segments.append({
			"waypoint_id": String(waypoint.waypoint_id),
			"index": waypoint_index,
			"command_type": String(waypoint.command_type),
			"from_position": previous_position,
			"to_position": target_position,
			"distance_world": segment_distance,
		})
		previous_position = target_position
		pending_waypoint_count += 1
	if pending_waypoint_count <= 0 or points.size() < 2:
		return {}
	var first_direction: Vector2 = Vector2(points[1]) - anchor_position
	var heading_direction: Vector2 = first_direction.normalized() if first_direction.length_squared() > 0.0001 else Vector2.ZERO
	var normalized_speed: float = maxf(speed_world_per_second, 1.0)
	return {
		"fireteam_id": String(plan.fireteam_id).strip_edges().to_lower(),
		"plan_id": String(plan.plan_id),
		"phase": int(plan.phase),
		"preview_state": "pending",
		"visible_before_go": true,
		"ghost_path_points": points,
		"ghost_path_segment_count": segments.size(),
		"segments": segments,
		"ghost_ftl_position": Vector2(points[points.size() - 1]),
		"heading_direction": heading_direction,
		"heading_angle": heading_direction.angle() if heading_direction.length_squared() > 0.0001 else 0.0,
		"distance_world": total_distance,
		"eta_seconds_estimate": total_distance / normalized_speed,
		"eta_state": "estimated",
		"speed_world_per_second_estimate": normalized_speed,
		"risk_state": "unknown",
		"expected_exposure": "unknown",
		"risk_reason": "no_threat_context",
		"threat_analysis": {},
		"line_of_fire_entries": [],
		"pending_waypoint_count": pending_waypoint_count,
		"source": "WaypointIntentPreviewResolver",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _apply_threat_analysis(entry: Dictionary, threat_analyzer, threat_context: Dictionary) -> void:
	if threat_analyzer == null or not threat_analyzer.has_method("analyze_position"):
		return
	var ghost_position_variant = entry.get("ghost_ftl_position", null)
	if typeof(ghost_position_variant) != TYPE_VECTOR2:
		return
	var analysis_options: Dictionary = threat_context.duplicate(true)
	analysis_options["fireteam_id"] = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
	analysis_options["path_points"] = Array(entry.get("ghost_path_points", [])).duplicate(true)
	var analysis: Dictionary = Dictionary(threat_analyzer.call("analyze_position", Vector2(ghost_position_variant), analysis_options))
	if analysis.is_empty():
		return
	entry["risk_state"] = String(analysis.get("risk_state", entry.get("risk_state", "unknown"))).strip_edges().to_lower()
	entry["expected_exposure"] = String(analysis.get("expected_exposure", entry.get("expected_exposure", "unknown"))).strip_edges().to_lower()
	entry["risk_reason"] = String(analysis.get("risk_reason", entry.get("risk_reason", ""))).strip_edges()
	entry["threat_analysis"] = analysis.duplicate(true)
	entry["line_of_fire_entries"] = Array(analysis.get("line_of_fire_entries", [])).duplicate(true)
	entry["cover_value"] = int(analysis.get("cover_value", 0))
	entry["cover_state"] = String(analysis.get("cover_state", "unknown")).strip_edges().to_lower()
	entry["enemy_exposure_count"] = int(analysis.get("enemy_exposure_count", 0))
	entry["enemy_overwatch_count"] = int(analysis.get("enemy_overwatch_count", 0))
	entry["friendly_fire_risk_count"] = int(analysis.get("friendly_fire_risk_count", 0))
	entry["clear_friendly_shot_count"] = int(analysis.get("clear_friendly_shot_count", 0))


func _build_anchor_lookup(fireteam_anchor_dicts: Array) -> Dictionary:
	var result: Dictionary = {}
	for anchor_variant in fireteam_anchor_dicts:
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor: Dictionary = Dictionary(anchor_variant)
		var fireteam_id: String = String(anchor.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or typeof(anchor.get("position", null)) != TYPE_VECTOR2:
			continue
		result[fireteam_id] = Vector2(anchor.get("position", Vector2.ZERO))
	return result


func _is_selected(fireteam_id: String, selected_fireteam_ids: PackedStringArray) -> bool:
	return selected_fireteam_ids.is_empty() or selected_fireteam_ids.has(fireteam_id)


func _is_pending_plan(plan) -> bool:
	var status: String = String(plan.status).strip_edges().to_lower()
	if status != FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT and status != FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING:
		return false
	if int(plan.active_waypoint_index) >= 0:
		return false
	for waypoint in plan.waypoints:
		var coerced_waypoint = _coerce_waypoint(waypoint)
		if coerced_waypoint != null and String(coerced_waypoint.status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE:
			return false
	return true


func _is_pending_waypoint(waypoint) -> bool:
	var status: String = String(waypoint.status).strip_edges().to_lower()
	return status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED


func _coerce_waypoint(waypoint_variant):
	if waypoint_variant == null:
		return null
	if waypoint_variant is RefCounted and waypoint_variant.has_method("is_valid"):
		return waypoint_variant
	if typeof(waypoint_variant) == TYPE_DICTIONARY:
		return FIRETEAM_WAYPOINT_SCRIPT.call("from_dict", waypoint_variant)
	return null


func _coerce_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for item in Array(value):
		var text: String = String(item).strip_edges().to_lower()
		if text.is_empty() or result.has(text):
			continue
		result.append(text)
	return result
