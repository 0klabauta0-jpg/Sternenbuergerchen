class_name FireteamBehaviorResolver
extends RefCounted

const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TRAIT_MODE_CAUTIOUS: String = "cautious"
const TRAIT_MODE_AGGRESSIVE: String = "aggressive"
const TRAIT_MODE_RECKLESS: String = "reckless"
const TRAIT_MODE_NEUTRAL: String = "neutral"
const FLANK_COVER_SEARCH_RADIUS: float = 96.0


static func resolve_profile(
	fireteam_id: String,
	units: Array,
	preferred_leader = null,
	command_type: String = "",
	rough_target_position = null,
	terrain_registry = null,
	tactical_stance: String = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL
):
	var profile = FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.new()
	profile.fireteam_id = fireteam_id.strip_edges().to_lower()
	var leader = _resolve_leader(units, preferred_leader)
	if leader == null:
		profile.metadata = {
			"trait_mode": TRAIT_MODE_NEUTRAL,
			"origin_command_type": command_type.strip_edges().to_lower(),
			"tactical_stance": FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL,
		}
		return profile

	var leadership: float = _read_skill_value(leader, "get_leadership_skill", 0.3)
	var toughness: float = _read_skill_value(leader, "get_toughness_skill", 0.5)
	var trait_mode: String = _resolve_trait_mode(leader)
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var normalized_tactical_stance: String = _normalize_tactical_stance(tactical_stance)
	var directness: float = _derive_directness(leadership, trait_mode)

	profile.leader_unit_id = _read_string(leader, "get_unit_id")
	profile.advance_style = _derive_advance_style(toughness, trait_mode)
	profile.cover_priority = clampf(1.0 - toughness, 0.1, 0.9)
	profile.fire_discipline = _derive_fire_discipline(normalized_command_type, leadership)
	profile.cohesion_threshold = clampf(200.0 - (leadership * 150.0), 50.0, 180.0)
	profile.suppression_threshold = _derive_suppression_threshold(toughness, trait_mode)
	profile.tactical_stance = normalized_tactical_stance
	profile.advance_style = _apply_tactical_stance_to_advance_style(profile.advance_style, normalized_tactical_stance, trait_mode)
	profile.cover_priority = _apply_tactical_stance_to_cover_priority(profile.cover_priority, normalized_tactical_stance, trait_mode)
	profile.suppression_threshold = _apply_tactical_stance_to_suppression_threshold(profile.suppression_threshold, normalized_tactical_stance, trait_mode)

	var resolved_target_position = null
	if typeof(rough_target_position) == TYPE_VECTOR2:
		resolved_target_position = rough_target_position
		if normalized_command_type == "flank":
			resolved_target_position = _resolve_flank_target(leader, rough_target_position, directness, profile.cover_priority, terrain_registry)

	profile.metadata = {
		"trait_mode": trait_mode,
		"leader_leadership": leadership,
		"leader_toughness": toughness,
		"origin_command_type": normalized_command_type,
		"prefer_cover_seek": trait_mode == TRAIT_MODE_CAUTIOUS,
		"prefer_exposed_position": trait_mode == TRAIT_MODE_AGGRESSIVE or trait_mode == TRAIT_MODE_RECKLESS,
		"directness": directness,
		"tactical_stance": normalized_tactical_stance,
		"rough_target_position": rough_target_position,
		"resolved_target_position": resolved_target_position,
		"terrain_cover_used": typeof(resolved_target_position) == TYPE_VECTOR2 and typeof(rough_target_position) == TYPE_VECTOR2 and resolved_target_position != rough_target_position,
	}
	return profile


static func _resolve_leader(units: Array, preferred_leader):
	if preferred_leader != null:
		return preferred_leader

	var first_fit = null
	var best_fallback = null
	var best_leadership: float = -1.0
	for unit in units:
		if unit == null:
			continue
		if best_fallback == null:
			best_fallback = unit
		var is_fit: bool = not unit.has_method("get_vital_state") or _read_string(unit, "get_vital_state") == "fit"
		if not is_fit:
			continue
		if first_fit == null:
			first_fit = unit
		if bool(unit.get("is_fireteam_lead")):
			return unit
		var leadership: float = _read_skill_value(unit, "get_leadership_skill", 0.0)
		if leadership > best_leadership:
			best_leadership = leadership
			best_fallback = unit

	if first_fit != null and best_fallback == null:
		return first_fit
	return best_fallback


static func _read_skill_value(unit, method_name: String, fallback: float) -> float:
	if unit == null or not unit.has_method(method_name):
		return fallback
	return clampf(float(unit.call(method_name)), 0.0, 1.0)


static func _read_string(unit, method_name: String) -> String:
	if unit == null or not unit.has_method(method_name):
		return ""
	return String(unit.call(method_name)).strip_edges()


static func _resolve_trait_mode(leader) -> String:
	if leader == null or not leader.has_method("get_trait_ids"):
		return TRAIT_MODE_NEUTRAL
	var trait_ids: PackedStringArray = PackedStringArray(leader.call("get_trait_ids"))
	if trait_ids.has("cautious"):
		return TRAIT_MODE_CAUTIOUS
	if trait_ids.has("reckless"):
		return TRAIT_MODE_RECKLESS
	if trait_ids.has("aggressive"):
		return TRAIT_MODE_AGGRESSIVE
	return TRAIT_MODE_NEUTRAL


static func _derive_advance_style(toughness: float, trait_mode: String) -> String:
	match trait_mode:
		TRAIT_MODE_AGGRESSIVE, TRAIT_MODE_RECKLESS:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
		TRAIT_MODE_CAUTIOUS:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_CREEP
		_:
			if toughness > 0.6:
				return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_CREEP


static func _derive_fire_discipline(command_type: String, leadership: float) -> String:
	match command_type:
		"move":
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.FIRE_DISCIPLINE_HOLD_FIRE
		"defend":
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.FIRE_DISCIPLINE_SEMI_DISCIPLINED
		"engage", "take", "hold_position":
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.FIRE_DISCIPLINE_FIRE_AT_WILL
		"flank":
			if leadership > 0.6:
				return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.FIRE_DISCIPLINE_SEMI_DISCIPLINED
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.FIRE_DISCIPLINE_FIRE_AT_WILL
		_:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.FIRE_DISCIPLINE_FIRE_AT_WILL


static func _derive_suppression_threshold(toughness: float, trait_mode: String) -> int:
	var suppression_value: int = maxi(1, floori(toughness * 5.0))
	match trait_mode:
		TRAIT_MODE_RECKLESS:
			return maxi(1, suppression_value * 3)
		TRAIT_MODE_CAUTIOUS:
			return maxi(1, floori(float(suppression_value) * 0.5))
		_:
			return suppression_value


static func _normalize_tactical_stance(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.is_allowed_tactical_stance(normalized_value):
		return normalized_value
	return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_NORMAL


static func _apply_tactical_stance_to_advance_style(base_style: String, tactical_stance: String, trait_mode: String) -> String:
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			if trait_mode == TRAIT_MODE_RECKLESS:
				return base_style
			return _shift_style_more_cautious(base_style)
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			if trait_mode == TRAIT_MODE_CAUTIOUS:
				return base_style
			return _shift_style_more_aggressive(base_style)
		_:
			return base_style


static func _apply_tactical_stance_to_cover_priority(base_cover_priority: float, tactical_stance: String, trait_mode: String) -> float:
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			if trait_mode == TRAIT_MODE_RECKLESS:
				return clampf(base_cover_priority + 0.05, 0.1, 0.9)
			return clampf(base_cover_priority + 0.2, 0.1, 0.9)
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			if trait_mode == TRAIT_MODE_CAUTIOUS:
				return clampf(base_cover_priority - 0.1, 0.1, 0.9)
			return clampf(base_cover_priority - 0.2, 0.1, 0.9)
		_:
			return clampf(base_cover_priority, 0.1, 0.9)


static func _apply_tactical_stance_to_suppression_threshold(base_threshold: int, tactical_stance: String, trait_mode: String) -> int:
	var base_value: float = maxf(float(base_threshold), 1.0)
	match tactical_stance:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
			if trait_mode == TRAIT_MODE_RECKLESS:
				return maxi(1, int(roundi(base_value)))
			return maxi(1, int(roundi(base_value * 0.7)))
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_AGGRESSIVE:
			if trait_mode == TRAIT_MODE_CAUTIOUS:
				return maxi(1, int(roundi(base_value * 1.2)))
			return maxi(1, int(roundi(base_value * 1.4)))
		_:
			return maxi(1, int(roundi(base_value)))


static func _shift_style_more_aggressive(base_style: String) -> String:
	match base_style:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_CREEP:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH
		_:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH


static func _shift_style_more_cautious(base_style: String) -> String:
	match base_style:
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING
		FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_BOUNDING:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_CREEP
		_:
			return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_CREEP


static func _derive_directness(leadership: float, trait_mode: String) -> float:
	match trait_mode:
		TRAIT_MODE_CAUTIOUS:
			return 0.25
		TRAIT_MODE_RECKLESS:
			return 1.0
		TRAIT_MODE_AGGRESSIVE:
			return 0.8
		_:
			if leadership > 0.6:
				return 0.65
			return 0.4


static func _resolve_flank_target(leader, rough_target_position: Vector2, directness: float, cover_priority: float, terrain_registry):
	if leader == null or not (leader is Node2D):
		return rough_target_position
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		return rough_target_position

	var leader_position: Vector2 = (leader as Node2D).global_position
	var best_position: Vector2 = rough_target_position
	var best_score: float = -INF
	var cover_tiles: Array = terrain_registry.call("get_walkable_cover_tiles_in_radius", rough_target_position, FLANK_COVER_SEARCH_RADIUS)
	for tile in cover_tiles:
		if tile == null:
			continue
		var tile_position: Vector2 = Vector2(tile.world_position)
		var cover_value: float = clampf(float(tile.cover_value) / 100.0, 0.0, 1.0)
		var rough_penalty: float = tile_position.distance_to(rough_target_position) * 0.015
		var directness_penalty: float = leader_position.distance_to(tile_position) * (1.0 - directness) * 0.01
		var score: float = (cover_value * (0.6 + cover_priority)) - rough_penalty - directness_penalty
		if score <= best_score:
			continue
		best_score = score
		best_position = tile_position

	return best_position
