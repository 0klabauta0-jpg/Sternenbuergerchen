class_name TacticalDecisionThreatAnalyzer
extends RefCounted

const LINE_OF_SIGHT_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")

const RISK_UNKNOWN: String = "unknown"
const RISK_SAFE: String = "safe"
const RISK_RISKY: String = "risky"
const RISK_SUICIDAL: String = "suicidal"

const DEFAULT_ENEMY_LOS_RANGE_WORLD: float = 560.0
const DEFAULT_FRIENDLY_FIRE_CORRIDOR_RADIUS: float = 18.0
const COVER_PARTIAL_THRESHOLD: int = 25
const COVER_FULL_THRESHOLD: int = 55


func analyze_position(candidate_position: Vector2, options: Dictionary = {}) -> Dictionary:
	var has_enemy_context: bool = options.has("enemy_units") or options.has("contact_entries")
	if not has_enemy_context:
		return _build_unknown_result(candidate_position, "no_threat_context")

	var los_system = options.get("los_system", null)
	if los_system == null:
		los_system = LINE_OF_SIGHT_SYSTEM_SCRIPT.new()
	var terrain_registry = options.get("terrain_registry", null)
	var enemy_entries: Array = _coerce_unit_entries(Array(options.get("enemy_units", options.get("contact_entries", []))), "enemy")
	var friendly_entries: Array = _coerce_unit_entries(Array(options.get("friendly_units", [])), "friendly")
	var enemy_los_range: float = maxf(float(options.get("enemy_los_range_world", DEFAULT_ENEMY_LOS_RANGE_WORLD)), 1.0)
	var friendly_fire_radius: float = maxf(float(options.get("friendly_fire_corridor_radius", DEFAULT_FRIENDLY_FIRE_CORRIDOR_RADIUS)), 0.0)
	var cover_value: int = _resolve_cover_value(candidate_position, terrain_registry, options)

	var line_entries: Array = []
	var exposed_enemy_count: int = 0
	var overwatch_enemy_count: int = 0
	var blocked_enemy_count: int = 0
	var friendly_fire_risk_count: int = 0
	var clear_friendly_shot_count: int = 0
	for enemy in enemy_entries:
		var enemy_position: Vector2 = Vector2(enemy.get("position", candidate_position))
		var enemy_id: String = String(enemy.get("unit_id", enemy.get("enemy_unit_id", ""))).strip_edges()
		if enemy_id.is_empty():
			enemy_id = "enemy_%d" % line_entries.size()
		var max_range: float = maxf(float(enemy.get("max_range", enemy.get("los_range_world", enemy_los_range))), 1.0)
		var has_los: bool = _has_line_of_sight(los_system, enemy_position, candidate_position, max_range, terrain_registry)
		var friendly_fire_units: PackedStringArray = PackedStringArray()
		if has_los:
			exposed_enemy_count += 1
			clear_friendly_shot_count += 1
			if bool(enemy.get("overwatch_ready", enemy.get("overwatch", false))):
				overwatch_enemy_count += 1
			friendly_fire_units = _find_friendly_fire_units(candidate_position, enemy_position, friendly_entries, friendly_fire_radius)
			if friendly_fire_units.size() > 0:
				friendly_fire_risk_count += 1
		else:
			blocked_enemy_count += 1
		line_entries.append({
			"enemy_unit_id": enemy_id,
			"enemy_type": String(enemy.get("enemy_type", enemy.get("type", "unknown"))).strip_edges(),
			"from_position": candidate_position,
			"to_position": enemy_position,
			"distance_world": candidate_position.distance_to(enemy_position),
			"line_state": "clear" if has_los else "blocked",
			"blocked": not has_los,
			"friendly_fire_risk": friendly_fire_units.size() > 0,
			"friendly_fire_unit_ids": friendly_fire_units,
			"overwatch_ready": bool(enemy.get("overwatch_ready", enemy.get("overwatch", false))),
			"visual_role": _resolve_visual_role(has_los, friendly_fire_units.size() > 0, bool(enemy.get("overwatch_ready", enemy.get("overwatch", false)))),
		})

	var risk_state: String = _classify_risk(exposed_enemy_count, overwatch_enemy_count, friendly_fire_risk_count, cover_value)
	var reason: String = _build_risk_reason(risk_state, exposed_enemy_count, overwatch_enemy_count, friendly_fire_risk_count, cover_value)
	return {
		"risk_state": risk_state,
		"expected_exposure": risk_state,
		"risk_reason": reason,
		"candidate_position": candidate_position,
		"cover_value": cover_value,
		"cover_state": _cover_state(cover_value),
		"enemy_context_count": enemy_entries.size(),
		"enemy_exposure_count": exposed_enemy_count,
		"enemy_overwatch_count": overwatch_enemy_count,
		"blocked_enemy_line_count": blocked_enemy_count,
		"clear_friendly_shot_count": clear_friendly_shot_count,
		"friendly_fire_risk_count": friendly_fire_risk_count,
		"line_of_fire_entries": line_entries,
		"source": "TacticalDecisionThreatAnalyzer",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_unknown_result(candidate_position: Vector2, reason: String) -> Dictionary:
	return {
		"risk_state": RISK_UNKNOWN,
		"expected_exposure": RISK_UNKNOWN,
		"risk_reason": reason,
		"candidate_position": candidate_position,
		"cover_value": 0,
		"cover_state": "unknown",
		"enemy_context_count": 0,
		"enemy_exposure_count": 0,
		"enemy_overwatch_count": 0,
		"blocked_enemy_line_count": 0,
		"clear_friendly_shot_count": 0,
		"friendly_fire_risk_count": 0,
		"line_of_fire_entries": [],
		"source": "TacticalDecisionThreatAnalyzer",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _coerce_unit_entries(source_entries: Array, default_team: String) -> Array:
	var result: Array = []
	for entry_variant in source_entries:
		var entry: Dictionary = _coerce_unit_entry(entry_variant, default_team)
		if entry.is_empty():
			continue
		result.append(entry)
	return result


func _coerce_unit_entry(entry_variant: Variant, default_team: String) -> Dictionary:
	if typeof(entry_variant) == TYPE_DICTIONARY:
		var entry: Dictionary = Dictionary(entry_variant)
		var position_variant = entry.get("position", entry.get("last_known_position", null))
		if typeof(position_variant) != TYPE_VECTOR2:
			return {}
		return {
			"unit_id": String(entry.get("unit_id", entry.get("enemy_unit_id", ""))).strip_edges(),
			"enemy_type": String(entry.get("enemy_type", entry.get("type", ""))).strip_edges(),
			"team_id": String(entry.get("team_id", default_team)).strip_edges(),
			"fireteam_id": String(entry.get("fireteam_id", "")).strip_edges().to_lower(),
			"position": Vector2(position_variant),
			"overwatch_ready": bool(entry.get("overwatch_ready", entry.get("overwatch", false))),
			"los_range_world": float(entry.get("los_range_world", entry.get("max_range", DEFAULT_ENEMY_LOS_RANGE_WORLD))),
			"detection_state": String(entry.get("detection_state", "")).strip_edges().to_lower(),
		}
	if entry_variant is Node2D:
		var node: Node2D = entry_variant
		return {
			"unit_id": String(entry_variant.call("get_unit_id")) if entry_variant.has_method("get_unit_id") else String(node.name),
			"team_id": String(entry_variant.call("get_team_id")) if entry_variant.has_method("get_team_id") else default_team,
			"fireteam_id": String(entry_variant.call("get_fireteam_id")).strip_edges().to_lower() if entry_variant.has_method("get_fireteam_id") else "",
			"position": node.global_position,
			"overwatch_ready": bool(entry_variant.get_meta("overwatch_ready", false)),
			"los_range_world": DEFAULT_ENEMY_LOS_RANGE_WORLD,
		}
	return {}


func _has_line_of_sight(los_system, from_position: Vector2, to_position: Vector2, max_range: float, terrain_registry) -> bool:
	if los_system == null or not los_system.has_method("has_line_of_sight_between_points"):
		return from_position.distance_to(to_position) <= max_range
	return bool(los_system.call("has_line_of_sight_between_points", from_position, to_position, max_range, terrain_registry))


func _find_friendly_fire_units(from_position: Vector2, to_position: Vector2, friendly_entries: Array, corridor_radius: float) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if corridor_radius <= 0.0:
		return result
	for friendly in friendly_entries:
		var friendly_position: Vector2 = Vector2(friendly.get("position", Vector2.INF))
		if not friendly_position.is_finite():
			continue
		if friendly_position.distance_to(from_position) <= corridor_radius or friendly_position.distance_to(to_position) <= corridor_radius:
			continue
		if _distance_to_segment(friendly_position, from_position, to_position) <= corridor_radius:
			var unit_id: String = String(friendly.get("unit_id", "")).strip_edges()
			if not unit_id.is_empty() and not result.has(unit_id):
				result.append(unit_id)
	return result


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment: Vector2 = segment_end - segment_start
	var length_sq: float = segment.length_squared()
	if length_sq <= 0.0001:
		return point.distance_to(segment_start)
	var t: float = clampf((point - segment_start).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(segment_start + segment * t)


func _resolve_cover_value(candidate_position: Vector2, terrain_registry, options: Dictionary) -> int:
	if options.has("cover_value_override"):
		return clampi(int(options.get("cover_value_override", 0)), 0, 100)
	if terrain_registry != null and terrain_registry.has_method("get_cover_at_world"):
		return clampi(int(terrain_registry.call("get_cover_at_world", candidate_position)), 0, 100)
	return 0


func _classify_risk(exposed_enemy_count: int, overwatch_enemy_count: int, friendly_fire_risk_count: int, cover_value: int) -> String:
	if exposed_enemy_count <= 0 and friendly_fire_risk_count <= 0:
		return RISK_SAFE
	if exposed_enemy_count >= 3 and cover_value < COVER_FULL_THRESHOLD:
		return RISK_SUICIDAL
	if exposed_enemy_count >= 2 and cover_value < COVER_PARTIAL_THRESHOLD:
		return RISK_SUICIDAL
	if overwatch_enemy_count >= 2 and cover_value < COVER_FULL_THRESHOLD:
		return RISK_SUICIDAL
	if friendly_fire_risk_count > 0 and exposed_enemy_count >= 2:
		return RISK_SUICIDAL
	return RISK_RISKY


func _build_risk_reason(risk_state: String, exposed_enemy_count: int, overwatch_enemy_count: int, friendly_fire_risk_count: int, cover_value: int) -> String:
	if risk_state == RISK_SAFE:
		return "no_clear_enemy_los"
	var parts: PackedStringArray = PackedStringArray()
	if exposed_enemy_count > 0:
		parts.append("%d_enemy_los" % exposed_enemy_count)
	if overwatch_enemy_count > 0:
		parts.append("%d_overwatch" % overwatch_enemy_count)
	if friendly_fire_risk_count > 0:
		parts.append("%d_friendly_fire_risk" % friendly_fire_risk_count)
	parts.append("cover_%d" % cover_value)
	return "_".join(parts)


func _cover_state(cover_value: int) -> String:
	if cover_value >= COVER_FULL_THRESHOLD:
		return "full"
	if cover_value >= COVER_PARTIAL_THRESHOLD:
		return "partial"
	return "none"


func _resolve_visual_role(has_los: bool, friendly_fire_risk: bool, overwatch_ready: bool) -> String:
	if not has_los:
		return "blocked"
	if friendly_fire_risk:
		return "friendly_fire_risk"
	if overwatch_ready:
		return "enemy_overwatch"
	return "clear_friendly_shot"
