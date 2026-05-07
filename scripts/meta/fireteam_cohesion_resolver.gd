class_name FireteamCohesionResolver
extends RefCounted

const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")

const SOLO_COHESION: float = 0.46
const MIN_MODIFIER: float = -0.05
const MAX_MODIFIER: float = 0.05


static func build_fireteam_snapshot(fireteam_id: String, member_units: Array, lead_unit_id: String = "") -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var units: Array = _normalize_member_units(member_units)
	var member_unit_ids: PackedStringArray = _build_member_unit_ids(units)
	if member_unit_ids.size() < 2:
		return {
			"fireteam_id": normalized_fireteam_id,
			"member_unit_ids": member_unit_ids,
			"member_count": member_unit_ids.size(),
			"lead_unit_id": lead_unit_id.strip_edges().to_lower(),
			"cohesion": SOLO_COHESION,
			"cohesion_percent": int(round(SOLO_COHESION * 100.0)),
			"label": "solo",
			"summary_text": "Teamfit %d%% | solo" % int(round(SOLO_COHESION * 100.0)),
			"average_affinity": 0.0,
			"known_relationship_count": 0,
			"pair_count": 0,
			"positive_pair_count": 0,
			"tension_pair_count": 0,
			"stability_score": 0.0,
			"leadership_score": _resolve_leadership_score(units, lead_unit_id),
			"gameplay_modifiers": _build_gameplay_modifiers(SOLO_COHESION, 0.0, 0),
		}

	var relationship_stats: Dictionary = _build_relationship_stats(units)
	var stability_score: float = _build_stability_score(units, normalized_fireteam_id)
	var leadership_score: float = _resolve_leadership_score(units, lead_unit_id)
	var known_ratio: float = 0.0
	var pair_count: int = int(relationship_stats.get("pair_count", 0))
	if pair_count > 0:
		known_ratio = float(relationship_stats.get("known_relationship_count", 0)) / float(pair_count)
	var average_affinity: float = float(relationship_stats.get("average_affinity", 0.0))
	var tension_pair_count: int = int(relationship_stats.get("tension_pair_count", 0))
	var cohesion: float = clampf(
		0.45
		+ average_affinity * 0.20
		+ known_ratio * 0.08
		+ stability_score * 0.15
		+ (leadership_score - 0.50) * 0.12
		- float(tension_pair_count) * 0.015,
		0.20,
		0.92
	)
	var label: String = _label_for_cohesion(cohesion, tension_pair_count)
	return {
		"fireteam_id": normalized_fireteam_id,
		"member_unit_ids": member_unit_ids,
		"member_count": member_unit_ids.size(),
		"lead_unit_id": _resolve_lead_unit_id(units, lead_unit_id),
		"cohesion": cohesion,
		"cohesion_percent": int(round(cohesion * 100.0)),
		"label": label,
		"summary_text": _build_summary_text(cohesion, label, average_affinity, int(relationship_stats.get("known_relationship_count", 0)), tension_pair_count),
		"average_affinity": average_affinity,
		"known_relationship_count": int(relationship_stats.get("known_relationship_count", 0)),
		"pair_count": pair_count,
		"positive_pair_count": int(relationship_stats.get("positive_pair_count", 0)),
		"tension_pair_count": tension_pair_count,
		"stability_score": stability_score,
		"leadership_score": leadership_score,
		"gameplay_modifiers": _build_gameplay_modifiers(cohesion, average_affinity, tension_pair_count),
	}


static func build_fireteam_snapshot_from_ids(fireteam_id: String, units: Array, member_unit_ids: PackedStringArray, lead_unit_id: String = "") -> Dictionary:
	var units_by_id: Dictionary = _build_units_by_id(units)
	var member_units: Array = []
	for member_unit_id in member_unit_ids:
		var normalized_member_id: String = String(member_unit_id).strip_edges().to_lower()
		if units_by_id.has(normalized_member_id):
			member_units.append(Dictionary(units_by_id.get(normalized_member_id, {})).duplicate(true))
	return build_fireteam_snapshot(fireteam_id, member_units, lead_unit_id)


static func annotate_fireteams(fireteam_suggestions: Array, units: Array) -> Array:
	var result: Array = []
	for fireteam_variant in fireteam_suggestions:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(fireteam_variant).duplicate(true)
		var fireteam_id: String = String(definition.get("fireteam_id", definition.get("id", ""))).strip_edges().to_lower()
		var member_ids: PackedStringArray = PackedStringArray(definition.get("unit_ids", PackedStringArray()))
		var lead_unit_id: String = String(definition.get("leader_unit_id", definition.get("lead_unit_id", ""))).strip_edges().to_lower()
		var snapshot: Dictionary = build_fireteam_snapshot_from_ids(fireteam_id, units, member_ids, lead_unit_id)
		definition["cohesion_snapshot"] = snapshot
		definition["teamfit_summary_text"] = String(snapshot.get("summary_text", ""))
		result.append(definition)
	return result


static func resolve_gameplay_modifiers(fireteam_id: String, member_units: Array, lead_unit_id: String = "") -> Dictionary:
	var snapshot: Dictionary = build_fireteam_snapshot(fireteam_id, member_units, lead_unit_id)
	return Dictionary(snapshot.get("gameplay_modifiers", {})).duplicate(true)


static func _build_relationship_stats(units: Array) -> Dictionary:
	var pair_count: int = 0
	var known_relationship_count: int = 0
	var positive_pair_count: int = 0
	var tension_pair_count: int = 0
	var affinity_sum: float = 0.0
	for first_index in range(units.size()):
		for second_index in range(first_index + 1, units.size()):
			var first_unit: Dictionary = Dictionary(units[first_index])
			var second_unit: Dictionary = Dictionary(units[second_index])
			var first_id: String = String(first_unit.get("unit_id", "")).strip_edges().to_lower()
			var second_id: String = String(second_unit.get("unit_id", "")).strip_edges().to_lower()
			if first_id.is_empty() or second_id.is_empty():
				continue
			pair_count += 1
			var affinity_result: Dictionary = Dictionary(ROSTER_RELATIONSHIP_MODEL_SCRIPT.call("get_affinity_between", units, first_id, second_id, true))
			if not bool(affinity_result.get("known", false)):
				continue
			known_relationship_count += 1
			var affinity: float = float(affinity_result.get("affinity", 0.0))
			affinity_sum += affinity
			if affinity > 0.0:
				positive_pair_count += 1
			elif affinity < -0.08:
				tension_pair_count += 1
	var average_affinity: float = 0.0
	if known_relationship_count > 0:
		average_affinity = affinity_sum / float(known_relationship_count)
	return {
		"pair_count": pair_count,
		"known_relationship_count": known_relationship_count,
		"positive_pair_count": positive_pair_count,
		"tension_pair_count": tension_pair_count,
		"average_affinity": clampf(average_affinity, -1.0, 1.0),
	}


static func _build_stability_score(units: Array, fireteam_id: String) -> float:
	if units.is_empty():
		return 0.0
	var score_sum: float = 0.0
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_score: float = 0.0
		if String(unit.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id and not fireteam_id.is_empty():
			unit_score += 0.30
		for history_variant in Array(unit.get("fireteam_history", [])):
			if typeof(history_variant) != TYPE_DICTIONARY:
				continue
			var history: Dictionary = Dictionary(history_variant)
			if String(history.get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
				unit_score += 0.20
		score_sum += clampf(unit_score, 0.0, 1.0)
	return clampf(score_sum / float(units.size()), 0.0, 1.0)


static func _resolve_leadership_score(units: Array, lead_unit_id: String) -> float:
	var lead: Dictionary = {}
	var normalized_lead_id: String = lead_unit_id.strip_edges().to_lower()
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		if not normalized_lead_id.is_empty() and String(unit.get("unit_id", "")).strip_edges().to_lower() == normalized_lead_id:
			lead = unit
			break
		if bool(unit.get("is_fireteam_lead", false)) and lead.is_empty():
			lead = unit
	if lead.is_empty() and not units.is_empty():
		lead = Dictionary(units[0])
	var skill_values: Dictionary = Dictionary(lead.get("skill_values", {}))
	return clampf(float(skill_values.get("leadership", 0.50)), 0.0, 1.0)


static func _resolve_lead_unit_id(units: Array, lead_unit_id: String) -> String:
	var normalized_lead_id: String = lead_unit_id.strip_edges().to_lower()
	if not normalized_lead_id.is_empty():
		return normalized_lead_id
	for unit_variant in units:
		var unit: Dictionary = Dictionary(unit_variant)
		if bool(unit.get("is_fireteam_lead", false)):
			return String(unit.get("unit_id", "")).strip_edges().to_lower()
	return String(Dictionary(units[0]).get("unit_id", "")).strip_edges().to_lower() if not units.is_empty() else ""


static func _build_gameplay_modifiers(cohesion: float, average_affinity: float, tension_pair_count: int) -> Dictionary:
	var centered: float = cohesion - 0.50
	var tension_penalty: float = float(tension_pair_count) * 0.006
	return {
		"morale_delta": clampf(centered * 0.08 + average_affinity * 0.015 - tension_penalty, MIN_MODIFIER, MAX_MODIFIER),
		"communication_modifier": clampf(centered * 0.09 + average_affinity * 0.020 - tension_penalty, MIN_MODIFIER, MAX_MODIFIER),
		"coordination_modifier": clampf(centered * 0.10 + average_affinity * 0.025 - tension_penalty, MIN_MODIFIER, MAX_MODIFIER),
		"advance_readability_modifier": clampf(centered * 0.06 + average_affinity * 0.015 - tension_penalty, -0.04, 0.04),
	}


static func _label_for_cohesion(cohesion: float, tension_pair_count: int) -> String:
	if tension_pair_count > 0 and cohesion < 0.55:
		return "tense"
	if cohesion >= 0.70:
		return "strong"
	if cohesion >= 0.55:
		return "steady"
	if cohesion >= 0.42:
		return "new"
	return "strained"


static func _build_summary_text(cohesion: float, label: String, average_affinity: float, known_relationship_count: int, tension_pair_count: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("Teamfit %d%%" % int(round(cohesion * 100.0)))
	parts.append(label)
	if known_relationship_count > 0:
		parts.append("affinity %+.2f" % average_affinity)
	else:
		parts.append("no links")
	if tension_pair_count > 0:
		parts.append("%d tension" % tension_pair_count)
	return " | ".join(parts)


static func _normalize_member_units(member_units: Array) -> Array:
	var result: Array = []
	for unit_variant in member_units:
		var unit: Dictionary = _unit_to_dict(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges().to_lower()
		if unit_id.is_empty():
			continue
		unit["unit_id"] = unit_id
		result.append(unit)
	return result


static func _build_member_unit_ids(units: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for unit_variant in units:
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges().to_lower()
		if not unit_id.is_empty():
			result.append(unit_id)
	return result


static func _build_units_by_id(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in units:
		var unit: Dictionary = _unit_to_dict(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges().to_lower()
		if not unit_id.is_empty():
			result[unit_id] = unit
	return result


static func _unit_to_dict(unit_variant: Variant) -> Dictionary:
	if typeof(unit_variant) == TYPE_DICTIONARY:
		return Dictionary(unit_variant).duplicate(true)
	if unit_variant != null and unit_variant.has_method("to_dict"):
		return Dictionary(unit_variant.call("to_dict")).duplicate(true)
	return {}
