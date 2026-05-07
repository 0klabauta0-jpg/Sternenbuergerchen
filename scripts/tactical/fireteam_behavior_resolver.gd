class_name FireteamBehaviorResolver
extends RefCounted

const FIRETEAM_BEHAVIOR_PROFILE_SCRIPT: GDScript = preload("res://scripts/command/fireteam_behavior_profile.gd")
const TRAIT_MODE_CAUTIOUS: String = "cautious"
const TRAIT_MODE_AGGRESSIVE: String = "aggressive"
const TRAIT_MODE_RECKLESS: String = "reckless"
const TRAIT_MODE_NEUTRAL: String = "neutral"
const FLANK_COVER_SEARCH_RADIUS: float = 96.0
const FTL_TACTICAL_SCHEMA_VERSION: int = 1
const MIN_FAIR_PLAN_QUALITY: float = 0.22
const MAX_FAIR_PLAN_QUALITY: float = 0.88
const MIN_REACTION_DELAY_SECONDS: float = 0.08
const MAX_REACTION_DELAY_SECONDS: float = 0.72


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
	profile.advance_style = _apply_command_to_advance_style(profile.advance_style, normalized_command_type, normalized_tactical_stance)
	profile.cover_priority = _apply_tactical_stance_to_cover_priority(profile.cover_priority, normalized_tactical_stance, trait_mode)
	profile.suppression_threshold = _apply_tactical_stance_to_suppression_threshold(profile.suppression_threshold, normalized_tactical_stance, trait_mode)
	var execution_profile: Dictionary = _derive_execution_profile(units, leader, leadership, trait_mode)
	profile.order_fidelity = float(execution_profile.get("order_fidelity", profile.order_fidelity))
	profile.reaction_delay_seconds = float(execution_profile.get("reaction_delay_seconds", profile.reaction_delay_seconds))
	profile.execution_cohesion = float(execution_profile.get("execution_cohesion", profile.execution_cohesion))
	profile.execution_fire_discipline = float(execution_profile.get("execution_fire_discipline", profile.execution_fire_discipline))
	profile.contact_stability = float(execution_profile.get("contact_stability", profile.contact_stability))
	profile.initiative = float(execution_profile.get("initiative", profile.initiative))
	profile.execution_label = String(execution_profile.get("execution_label", profile.execution_label))
	var leader_tactical_data: Dictionary = _build_leader_tactical_data(leader, profile.fireteam_id)
	var team_tactical_context: Dictionary = _build_team_tactical_context(units, leader, profile.fireteam_id, execution_profile)
	var ftl_tactical_snapshot: Dictionary = build_leader_tactical_skill_snapshot(leader_tactical_data, team_tactical_context)
	_apply_ftl_tactical_snapshot_to_profile(profile, ftl_tactical_snapshot)

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
		"execution_profile": execution_profile.duplicate(true),
		"ftl_tactical_skill": ftl_tactical_snapshot.duplicate(true),
		"ftl_public_snapshot": build_public_leader_tactical_snapshot(ftl_tactical_snapshot),
	}
	return profile


static func build_leader_tactical_skill_snapshot(leader_data: Dictionary, team_context: Dictionary = {}) -> Dictionary:
	var skill_values: Dictionary = Dictionary(leader_data.get("skill_values", {}))
	var communication_values: Dictionary = Dictionary(leader_data.get("communication_values", {}))
	var behavior_axes: Dictionary = Dictionary(leader_data.get("behavior_axes", {}))
	var progression: Dictionary = Dictionary(leader_data.get("progression", {}))
	var ftl_progression: Dictionary = Dictionary(progression.get("ftl_tactical", leader_data.get("ftl_tactical_progression", {})))
	var fireteam_id: String = String(team_context.get("fireteam_id", leader_data.get("fireteam_id", ""))).strip_edges().to_lower()
	var leadership: float = _read_score_from_sources(skill_values, leader_data, "leadership", 0.35)
	var discipline: float = _read_score_from_sources(skill_values, leader_data, "discipline", float(behavior_axes.get("order_fidelity", leadership)))
	var awareness: float = _read_score_from_sources(skill_values, leader_data, "awareness", leadership)
	var recognition: float = _read_score_from_sources(skill_values, leader_data, "recognition", awareness)
	var initiative: float = clampf(float(ftl_progression.get("initiative", behavior_axes.get("initiative", leader_data.get("initiative", leadership)))), 0.0, 1.0)
	var contact_stability: float = clampf(float(behavior_axes.get("contact_stability", leader_data.get("contact_stability", discipline))), 0.0, 1.0)
	var tactical_sense: float = clampf(float(ftl_progression.get("tactical_sense", (leadership * 0.34) + (recognition * 0.26) + (awareness * 0.20) + (discipline * 0.20))), 0.0, 1.0)
	var communication: float = clampf(float(ftl_progression.get("communication", (float(communication_values.get("speech_quality", leadership)) * 0.56) + (leadership * 0.26) + (discipline * 0.18))), 0.0, 1.0)
	var team_cohesion: float = _resolve_team_cohesion(team_context, progression, fireteam_id)
	if ftl_progression.has("team_cohesion"):
		team_cohesion = clampf(float(ftl_progression.get("team_cohesion", team_cohesion)), 0.0, 1.0)
	var morale: float = clampf(float(team_context.get("morale", progression.get("morale", 0.50))), 0.0, 1.0)
	var frustration: float = clampf(float(team_context.get("frustration", progression.get("frustration", 0.0))), 0.0, 1.0)
	var contact_pressure: float = clampf(float(team_context.get("contact_pressure", 0.0)), 0.0, 1.0)
	var missions_led: int = maxi(int(ftl_progression.get("missions_led", progression.get("missions_led", 0))), 0)
	var experience_factor: float = clampf((float(missions_led) * 0.035) + (float(progression.get("xp", 0)) * 0.0025), 0.0, 0.18)
	var pressure_penalty: float = contact_pressure * maxf(0.0, 0.58 - contact_stability) * 0.16
	var morale_modifier: float = (morale - 0.50) * 0.08 - frustration * 0.08
	var plan_quality: float = clampf(
		(leadership * 0.24)
		+ (tactical_sense * 0.24)
		+ (communication * 0.15)
		+ (discipline * 0.13)
		+ (team_cohesion * 0.14)
		+ experience_factor
		+ morale_modifier
		- pressure_penalty,
		MIN_FAIR_PLAN_QUALITY,
		MAX_FAIR_PLAN_QUALITY
	)
	var communication_clarity: float = clampf((communication * 0.38) + (leadership * 0.20) + (team_cohesion * 0.20) + (discipline * 0.16) + (morale * 0.06) - (frustration * 0.08), 0.20, 0.90)
	var breakout_judgement: float = clampf((tactical_sense * 0.30) + (discipline * 0.22) + (contact_stability * 0.20) + (initiative * 0.16) + (leadership * 0.12) - pressure_penalty, 0.18, 0.90)
	var spacing_quality: float = clampf((team_cohesion * 0.34) + (leadership * 0.22) + (discipline * 0.22) + (tactical_sense * 0.22), 0.24, 0.90)
	var contact_report_quality: float = clampf((communication * 0.34) + (recognition * 0.24) + (awareness * 0.16) + (tactical_sense * 0.16) + (discipline * 0.10), 0.20, 0.92)
	var reaction_quality: float = clampf((plan_quality * 0.48) + (initiative * 0.22) + (communication_clarity * 0.18) + (contact_stability * 0.12), 0.0, 1.0)
	var reaction_delay_seconds: float = clampf(lerpf(MAX_REACTION_DELAY_SECONDS, MIN_REACTION_DELAY_SECONDS, reaction_quality), MIN_REACTION_DELAY_SECONDS, MAX_REACTION_DELAY_SECONDS)
	var tempo_modifier: float = clampf(0.90 + (initiative * 0.11) + ((plan_quality - 0.50) * 0.16) - (frustration * 0.08), 0.86, 1.14)
	var progression_rate_modifier: float = clampf(0.64 + (plan_quality * 0.48) + ((team_cohesion - 0.50) * 0.22) - (frustration * 0.20), 0.50, 1.20)
	var effect_label: String = _derive_ftl_tactical_label(plan_quality, communication_clarity, breakout_judgement)
	var snapshot: Dictionary = {
		"schema_version": FTL_TACTICAL_SCHEMA_VERSION,
		"unit_id": String(leader_data.get("unit_id", "")).strip_edges(),
		"fireteam_id": fireteam_id,
		"leadership": leadership,
		"tactical_sense": tactical_sense,
		"communication": communication,
		"discipline": discipline,
		"initiative": initiative,
		"team_cohesion": team_cohesion,
		"missions_led": missions_led,
		"plan_quality": plan_quality,
		"communication_clarity": communication_clarity,
		"breakout_judgement": breakout_judgement,
		"spacing_quality": spacing_quality,
		"spacing_modifier": lerpf(1.12, 0.88, spacing_quality),
		"contact_report_quality": contact_report_quality,
		"reaction_delay_seconds": reaction_delay_seconds,
		"tempo_modifier": tempo_modifier,
		"progression_rate_modifier": progression_rate_modifier,
		"effect_label": effect_label,
	}
	snapshot["effect_text"] = build_tactical_effect_text(snapshot)
	return snapshot


static func build_skill_factors_from_snapshot(snapshot: Dictionary) -> Dictionary:
	return {
		"leadership": clampf(float(snapshot.get("leadership", snapshot.get("plan_quality", 0.5))), 0.0, 1.0),
		"discipline": clampf(float(snapshot.get("discipline", 0.5)), 0.0, 1.0),
		"cohesion": clampf(float(snapshot.get("team_cohesion", 0.5)), 0.0, 1.0),
		"communication": clampf(float(snapshot.get("communication_clarity", snapshot.get("communication", 0.5))), 0.0, 1.0),
		"initiative": clampf(float(snapshot.get("initiative", 0.5)), 0.0, 1.0),
		"planning_quality": clampf(float(snapshot.get("plan_quality", 0.5)), 0.0, 1.0),
		"reaction_delay_seconds": clampf(float(snapshot.get("reaction_delay_seconds", 0.35)), MIN_REACTION_DELAY_SECONDS, MAX_REACTION_DELAY_SECONDS),
		"breakout_judgement": clampf(float(snapshot.get("breakout_judgement", 0.5)), 0.0, 1.0),
		"spacing_quality": clampf(float(snapshot.get("spacing_quality", 0.5)), 0.0, 1.0),
		"contact_report_quality": clampf(float(snapshot.get("contact_report_quality", 0.5)), 0.0, 1.0),
		"tempo_modifier": clampf(float(snapshot.get("tempo_modifier", 1.0)), 0.86, 1.14),
	}


static func build_public_leader_tactical_snapshot(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty():
		return {}
	var result: Dictionary = {
		"schema_version": FTL_TACTICAL_SCHEMA_VERSION,
		"unit_id": String(snapshot.get("unit_id", "")).strip_edges(),
		"fireteam_id": String(snapshot.get("fireteam_id", "")).strip_edges().to_lower(),
		"plan_quality": clampf(float(snapshot.get("plan_quality", 0.5)), 0.0, 1.0),
		"communication_clarity": clampf(float(snapshot.get("communication_clarity", 0.5)), 0.0, 1.0),
		"breakout_judgement": clampf(float(snapshot.get("breakout_judgement", 0.5)), 0.0, 1.0),
		"spacing_quality": clampf(float(snapshot.get("spacing_quality", 0.5)), 0.0, 1.0),
		"contact_report_quality": clampf(float(snapshot.get("contact_report_quality", 0.5)), 0.0, 1.0),
		"reaction_delay_seconds": clampf(float(snapshot.get("reaction_delay_seconds", 0.35)), MIN_REACTION_DELAY_SECONDS, MAX_REACTION_DELAY_SECONDS),
		"tempo_modifier": clampf(float(snapshot.get("tempo_modifier", 1.0)), 0.86, 1.14),
		"effect_label": String(snapshot.get("effect_label", "developing_ftl")).strip_edges().to_lower(),
	}
	return result


static func build_tactical_effect_text(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return "No FTL impact recorded"
	return "Plan %d | Comms %d | Breakout %d | Tempo %+d%%" % [
		int(round(clampf(float(snapshot.get("plan_quality", 0.0)), 0.0, 1.0) * 100.0)),
		int(round(clampf(float(snapshot.get("communication_clarity", 0.0)), 0.0, 1.0) * 100.0)),
		int(round(clampf(float(snapshot.get("breakout_judgement", 0.0)), 0.0, 1.0) * 100.0)),
		int(round((clampf(float(snapshot.get("tempo_modifier", 1.0)), 0.0, 2.0) - 1.0) * 100.0)),
	]


static func _apply_ftl_tactical_snapshot_to_profile(profile, snapshot: Dictionary) -> void:
	if profile == null or snapshot.is_empty():
		return
	var plan_quality: float = float(snapshot.get("plan_quality", 0.5))
	var communication_clarity: float = float(snapshot.get("communication_clarity", 0.5))
	var breakout_judgement: float = float(snapshot.get("breakout_judgement", 0.5))
	var spacing_quality: float = float(snapshot.get("spacing_quality", 0.5))
	profile.order_fidelity = clampf((profile.order_fidelity * 0.70) + (plan_quality * 0.30), 0.0, 1.0)
	profile.reaction_delay_seconds = clampf((profile.reaction_delay_seconds * 0.62) + (float(snapshot.get("reaction_delay_seconds", profile.reaction_delay_seconds)) * 0.38), MIN_REACTION_DELAY_SECONDS, 0.85)
	profile.execution_cohesion = clampf((profile.execution_cohesion * 0.68) + (spacing_quality * 0.32), 0.0, 1.0)
	profile.execution_fire_discipline = clampf((profile.execution_fire_discipline * 0.72) + (float(snapshot.get("discipline", profile.execution_fire_discipline)) * 0.28), 0.0, 1.0)
	profile.contact_stability = clampf((profile.contact_stability * 0.70) + (breakout_judgement * 0.30), 0.0, 1.0)
	profile.initiative = clampf((profile.initiative * 0.75) + (float(snapshot.get("initiative", profile.initiative)) * 0.25), 0.0, 1.0)
	profile.cohesion_threshold = clampf(profile.cohesion_threshold * lerpf(1.08, 0.88, spacing_quality), 45.0, 190.0)
	profile.execution_label = _derive_execution_label(profile.order_fidelity, profile.reaction_delay_seconds, profile.execution_cohesion, profile.execution_fire_discipline)
	if communication_clarity < 0.34 and profile.execution_label == "STEADY":
		profile.execution_label = "COMMS LOW"


static func _build_leader_tactical_data(leader, fireteam_id: String) -> Dictionary:
	var data: Dictionary = {}
	if leader == null:
		return data
	if leader.has_method("to_dict"):
		data = Dictionary(leader.call("to_dict")).duplicate(true)
	var bundle: Dictionary = {}
	if leader.has_method("get_character_profile_bundle"):
		bundle = Dictionary(leader.call("get_character_profile_bundle")).duplicate(true)
	if data.is_empty():
		data = {
			"unit_id": _read_string(leader, "get_unit_id"),
			"fireteam_id": _read_string(leader, "get_fireteam_id"),
			"skill_values": {},
			"communication_values": {},
			"behavior_axes": {},
			"progression": _read_dictionary_property(leader, "progression"),
		}
	if String(data.get("fireteam_id", "")).strip_edges().is_empty():
		data["fireteam_id"] = fireteam_id
	var skill_values: Dictionary = Dictionary(data.get("skill_values", bundle.get("core_values", {}))).duplicate(true)
	if skill_values.is_empty():
		skill_values = {
			"leadership": _read_skill_value(leader, "get_leadership_skill", 0.35),
			"toughness": _read_skill_value(leader, "get_toughness_skill", 0.50),
			"accuracy": _read_skill_value(leader, "get_accuracy_skill", 0.50),
			"speed": _read_skill_value(leader, "get_speed_skill", 0.50),
		}
	if not skill_values.has("discipline") and leader.has_method("get_discipline"):
		skill_values["discipline"] = _read_skill_value(leader, "get_discipline", float(skill_values.get("leadership", 0.35)))
	if not skill_values.has("recognition") and leader.has_method("get_recognition"):
		skill_values["recognition"] = _read_skill_value(leader, "get_recognition", float(skill_values.get("leadership", 0.35)))
	data["skill_values"] = skill_values
	data["communication_values"] = Dictionary(data.get("communication_values", bundle.get("communication_values", {}))).duplicate(true)
	data["behavior_axes"] = Dictionary(data.get("behavior_axes", bundle.get("behavior_axes", {}))).duplicate(true)
	if not data.has("progression"):
		data["progression"] = _read_dictionary_property(leader, "progression")
	if String(data.get("unit_id", "")).strip_edges().is_empty():
		data["unit_id"] = _read_string(leader, "get_unit_id")
	return data


static func _build_team_tactical_context(units: Array, leader, fireteam_id: String, execution_profile: Dictionary) -> Dictionary:
	var context: Dictionary = {
		"fireteam_id": fireteam_id,
		"team_cohesion": float(execution_profile.get("execution_cohesion", 0.50)),
		"contact_pressure": 0.0,
	}
	var morale_total: float = 0.0
	var frustration_total: float = 0.0
	var count: int = 0
	for unit in units:
		if unit == null:
			continue
		var progression: Dictionary = _read_dictionary_property(unit, "progression")
		if progression.is_empty() and unit == leader:
			progression = _read_dictionary_property(leader, "progression")
		if progression.is_empty():
			continue
		morale_total += clampf(float(progression.get("morale", 0.50)), 0.0, 1.0)
		frustration_total += clampf(float(progression.get("frustration", 0.0)), 0.0, 1.0)
		count += 1
	if count > 0:
		context["morale"] = morale_total / float(count)
		context["frustration"] = frustration_total / float(count)
	return context


static func _read_dictionary_property(target, property_name: String) -> Dictionary:
	if target == null:
		return {}
	if target.has_method("get_%s" % property_name):
		var method_value: Variant = target.call("get_%s" % property_name)
		return Dictionary(method_value).duplicate(true) if typeof(method_value) == TYPE_DICTIONARY else {}
	var property_value: Variant = target.get(property_name)
	if typeof(property_value) == TYPE_DICTIONARY:
		return Dictionary(property_value).duplicate(true)
	return {}


static func _read_score_from_sources(primary: Dictionary, fallback: Dictionary, key: String, default_value: float) -> float:
	return clampf(float(primary.get(key, fallback.get(key, default_value))), 0.0, 1.0)


static func _resolve_team_cohesion(team_context: Dictionary, progression: Dictionary, fireteam_id: String) -> float:
	if team_context.has("team_cohesion"):
		return clampf(float(team_context.get("team_cohesion", 0.50)), 0.0, 1.0)
	if team_context.has("cohesion"):
		return clampf(float(team_context.get("cohesion", 0.50)), 0.0, 1.0)
	var cohesion_by_fireteam: Dictionary = Dictionary(progression.get("fireteam_cohesion_by_id", {}))
	if not fireteam_id.is_empty() and cohesion_by_fireteam.has(fireteam_id):
		return clampf(float(cohesion_by_fireteam.get(fireteam_id, 0.50)), 0.0, 1.0)
	return clampf(float(progression.get("team_cohesion", 0.50)), 0.0, 1.0)


static func _derive_ftl_tactical_label(plan_quality: float, communication_clarity: float, breakout_judgement: float) -> String:
	var combined: float = (plan_quality * 0.45) + (communication_clarity * 0.28) + (breakout_judgement * 0.27)
	if combined >= 0.78:
		return "seasoned_ftl"
	if combined >= 0.60:
		return "reliable_ftl"
	if combined >= 0.42:
		return "developing_ftl"
	return "raw_ftl"


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


static func _derive_execution_profile(units: Array, leader, leader_leadership: float, leader_trait_mode: String) -> Dictionary:
	var fit_units: Array = _filter_fit_units(units)
	if fit_units.is_empty() and leader != null:
		fit_units.append(leader)
	var average_accuracy: float = _average_skill_value(fit_units, "get_accuracy_skill", 0.5)
	var average_speed: float = _average_skill_value(fit_units, "get_speed_skill", 0.5)
	var average_toughness: float = _average_skill_value(fit_units, "get_toughness_skill", 0.5)
	var average_discipline: float = _average_skill_value(fit_units, "get_discipline", 0.5)
	var average_recognition: float = _average_skill_value(fit_units, "get_recognition", 0.5)
	var trait_adjustments: Dictionary = _derive_team_trait_adjustments(fit_units, leader_trait_mode)
	var trait_fidelity: float = float(trait_adjustments.get("fidelity", 0.0))
	var trait_cohesion: float = float(trait_adjustments.get("cohesion", 0.0))
	var trait_discipline: float = float(trait_adjustments.get("discipline", 0.0))
	var trait_contact: float = float(trait_adjustments.get("contact", 0.0))
	var trait_initiative: float = float(trait_adjustments.get("initiative", 0.0))
	var order_fidelity: float = clampf((leader_leadership * 0.36) + (average_discipline * 0.22) + (average_recognition * 0.18) + (average_toughness * 0.14) + (average_accuracy * 0.10) + trait_fidelity, 0.0, 1.0)
	var execution_cohesion: float = clampf((leader_leadership * 0.40) + (average_discipline * 0.22) + (average_toughness * 0.20) + (average_speed * 0.18) + trait_cohesion, 0.0, 1.0)
	var execution_fire_discipline: float = clampf((average_discipline * 0.55) + (leader_leadership * 0.25) + (average_recognition * 0.20) + trait_discipline, 0.0, 1.0)
	var contact_stability: float = clampf((average_recognition * 0.42) + (leader_leadership * 0.26) + (average_accuracy * 0.18) + (average_discipline * 0.14) + trait_contact, 0.0, 1.0)
	var initiative: float = clampf((leader_leadership * 0.36) + (average_speed * 0.30) + (average_accuracy * 0.18) + (average_discipline * 0.10) + (average_toughness * 0.06) + trait_initiative, 0.0, 1.0)
	var reaction_quality: float = clampf((leader_leadership * 0.58) + (initiative * 0.42), 0.0, 1.0)
	var reaction_delay_seconds: float = lerpf(0.85, 0.05, reaction_quality)
	return {
		"order_fidelity": order_fidelity,
		"reaction_delay_seconds": reaction_delay_seconds,
		"execution_cohesion": execution_cohesion,
		"execution_fire_discipline": execution_fire_discipline,
		"contact_stability": contact_stability,
		"initiative": initiative,
		"execution_label": _derive_execution_label(order_fidelity, reaction_delay_seconds, execution_cohesion, execution_fire_discipline),
	}


static func _filter_fit_units(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit == null:
			continue
		if unit.has_method("get_vital_state") and _read_string(unit, "get_vital_state") != "fit":
			continue
		result.append(unit)
	return result


static func _average_skill_value(units: Array, method_name: String, fallback: float) -> float:
	if units.is_empty():
		return fallback
	var total: float = 0.0
	var count: int = 0
	for unit in units:
		total += _read_skill_value(unit, method_name, fallback)
		count += 1
	return total / float(maxi(count, 1))


static func _derive_team_trait_adjustments(units: Array, leader_trait_mode: String) -> Dictionary:
	var adjustments: Dictionary = {
		"fidelity": 0.0,
		"cohesion": 0.0,
		"discipline": 0.0,
		"contact": 0.0,
		"initiative": 0.0,
	}
	if units.is_empty():
		return adjustments
	for unit in units:
		if unit == null or not unit.has_method("get_trait_ids"):
			continue
		for trait_id in PackedStringArray(unit.call("get_trait_ids")):
			match String(trait_id).strip_edges().to_lower():
				"calm":
					adjustments["fidelity"] = float(adjustments["fidelity"]) + 0.035
					adjustments["discipline"] = float(adjustments["discipline"]) + 0.045
					adjustments["contact"] = float(adjustments["contact"]) + 0.035
				"steady":
					adjustments["fidelity"] = float(adjustments["fidelity"]) + 0.025
					adjustments["cohesion"] = float(adjustments["cohesion"]) + 0.025
					adjustments["contact"] = float(adjustments["contact"]) + 0.025
				"cautious":
					adjustments["discipline"] = float(adjustments["discipline"]) + 0.035
					adjustments["contact"] = float(adjustments["contact"]) + 0.025
					adjustments["initiative"] = float(adjustments["initiative"]) - 0.035
				"aggressive":
					adjustments["initiative"] = float(adjustments["initiative"]) + 0.04
					adjustments["discipline"] = float(adjustments["discipline"]) - 0.035
				"reckless":
					adjustments["initiative"] = float(adjustments["initiative"]) + 0.06
					adjustments["fidelity"] = float(adjustments["fidelity"]) - 0.06
					adjustments["cohesion"] = float(adjustments["cohesion"]) - 0.05
					adjustments["discipline"] = float(adjustments["discipline"]) - 0.06
	if leader_trait_mode == TRAIT_MODE_CAUTIOUS:
		adjustments["fidelity"] = float(adjustments["fidelity"]) + 0.025
		adjustments["initiative"] = float(adjustments["initiative"]) - 0.025
	elif leader_trait_mode == TRAIT_MODE_AGGRESSIVE:
		adjustments["initiative"] = float(adjustments["initiative"]) + 0.025
	elif leader_trait_mode == TRAIT_MODE_RECKLESS:
		adjustments["fidelity"] = float(adjustments["fidelity"]) - 0.035
		adjustments["cohesion"] = float(adjustments["cohesion"]) - 0.035
	for key in adjustments.keys():
		adjustments[key] = clampf(float(adjustments[key]) / float(maxi(units.size(), 1)), -0.12, 0.12)
	return adjustments


static func _derive_execution_label(order_fidelity: float, reaction_delay_seconds: float, execution_cohesion: float, execution_fire_discipline: float) -> String:
	if order_fidelity >= 0.74 and execution_cohesion >= 0.68 and reaction_delay_seconds <= 0.28:
		return "CLEAN EXEC"
	if execution_fire_discipline < 0.42:
		return "LOW DISC"
	if execution_cohesion < 0.46:
		return "SCATTER"
	if reaction_delay_seconds >= 0.52:
		return "DELAY"
	return "STEADY"


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


static func _apply_command_to_advance_style(base_style: String, command_type: String, tactical_stance: String) -> String:
	if command_type != "move":
		return base_style
	if tactical_stance == FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.TACTICAL_STANCE_CAUTIOUS:
		return base_style
	return FIRETEAM_BEHAVIOR_PROFILE_SCRIPT.ADVANCE_STYLE_RUSH


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
