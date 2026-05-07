class_name CharacterGameplayResolver
extends RefCounted

const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")
const ROSTER_RELATIONSHIP_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/roster_relationship_model.gd")

const SOURCE_ID: String = "character_gameplay_resolver"
const MIN_MODIFIER: float = -0.05
const MAX_MODIFIER: float = 0.05


static func build_unit_character_state(unit, context: Dictionary = {}) -> Dictionary:
	var unit_id: String = _resolve_unit_id(unit, context)
	var context_state: Dictionary = _lookup_context_unit_state(unit_id, context)
	var progression: Dictionary = _read_dictionary(unit, "progression", Dictionary(context_state.get("progression", {})))
	var skill_values: Dictionary = _read_skill_values(unit, context_state)
	var communication_values: Dictionary = _read_dictionary(unit, "communication_values", Dictionary(context_state.get("communication_values", {})))
	var morale: float = clampf(float(progression.get("morale", context_state.get("morale", 0.50))), 0.0, 1.0)
	var frustration: float = clampf(float(progression.get("frustration", context_state.get("frustration", 0.0))), 0.0, 1.0)
	var leadership: float = clampf(float(skill_values.get("leadership", context_state.get("leadership", 0.0))), 0.0, 1.0)
	var communication: float = _resolve_communication_value(unit, communication_values, context_state, leadership)
	var relationship_summary: Dictionary = _summarize_relationships(unit, context_state)
	return {
		"source": SOURCE_ID,
		"unit_id": unit_id,
		"display_name": _resolve_display_name(unit, context_state, unit_id),
		"fireteam_id": _resolve_fireteam_id(unit, context_state),
		"role_id": _resolve_role_id(unit, context_state),
		"leadership": leadership,
		"communication": communication,
		"skill_tier": _resolve_skill_tier(leadership, communication, morale, frustration),
		"morale_state": _state_from_value(morale, 0.32, 0.68, "low", "steady", "high"),
		"frustration_state": _state_from_value(frustration, 0.30, 0.70, "low", "managed", "high"),
		"morale": morale,
		"frustration": frustration,
		"relationship_hint": String(relationship_summary.get("hint", "")),
		"relationship_target_name": String(relationship_summary.get("target_name", "")),
		"relationship_affinity": float(relationship_summary.get("affinity", 0.0)),
	}


static func build_fireteam_character_context(fireteam_id: String, units: Array, options: Dictionary = {}) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var members: Array = _normalize_member_units(units, normalized_fireteam_id, options)
	var member_states: Array = []
	for unit_variant in members:
		member_states.append(build_unit_character_state(unit_variant, options))
	var leader_state: Dictionary = _resolve_leader_state(member_states)
	var cohesion_snapshot: Dictionary = _build_cohesion_snapshot(normalized_fireteam_id, members, String(leader_state.get("unit_id", "")))
	var morale_average: float = _average_state_value(member_states, "morale", 0.50)
	var frustration_average: float = _average_state_value(member_states, "frustration", 0.0)
	var leadership: float = float(leader_state.get("leadership", 0.0))
	var communication: float = float(leader_state.get("communication", leadership))
	var cohesion: float = float(cohesion_snapshot.get("cohesion", 0.46))
	var cohesion_modifiers: Dictionary = Dictionary(cohesion_snapshot.get("gameplay_modifiers", {}))
	var communication_modifier: float = clampf(
		float(cohesion_modifiers.get("communication_modifier", 0.0))
		+ (communication - 0.50) * 0.035
		+ (morale_average - 0.50) * 0.020
		- frustration_average * 0.018,
		MIN_MODIFIER,
		MAX_MODIFIER
	)
	var coordination_modifier: float = clampf(
		float(cohesion_modifiers.get("coordination_modifier", 0.0))
		+ (leadership - 0.50) * 0.030
		- frustration_average * 0.014,
		MIN_MODIFIER,
		MAX_MODIFIER
	)
	var advance_readability_modifier: float = clampf(
		float(cohesion_modifiers.get("advance_readability_modifier", 0.0))
		+ (communication - 0.50) * 0.020,
		-0.04,
		0.04
	)
	return {
		"source": SOURCE_ID,
		"fireteam_id": normalized_fireteam_id,
		"member_count": member_states.size(),
		"leader_unit_id": String(leader_state.get("unit_id", "")),
		"leadership": leadership,
		"communication": communication,
		"morale_state": _state_from_value(morale_average, 0.32, 0.68, "low", "steady", "high"),
		"frustration_state": _state_from_value(frustration_average, 0.30, 0.70, "low", "managed", "high"),
		"cohesion": cohesion,
		"cohesion_percent": int(cohesion_snapshot.get("cohesion_percent", int(round(cohesion * 100.0)))),
		"cohesion_label": String(cohesion_snapshot.get("label", "new")),
		"teamfit_summary_text": String(cohesion_snapshot.get("summary_text", "")),
		"relationship_pair_scan_count": int(cohesion_snapshot.get("pair_count", 0)),
		"scan_policy": "summarized_context_not_per_frame",
		"gameplay_modifiers": {
			"communication_modifier": communication_modifier,
			"coordination_modifier": coordination_modifier,
			"advance_readability_modifier": advance_readability_modifier,
			"ftl_clarity_modifier": clampf((leadership - 0.50) * 0.045 + communication_modifier, MIN_MODIFIER, MAX_MODIFIER),
			"feedback_duration_multiplier": clampf(1.0 - communication_modifier, 0.94, 1.06),
		},
		"member_states": member_states,
	}


static func build_mission_character_context(units: Array, options: Dictionary = {}) -> Dictionary:
	var grouped: Dictionary = {}
	for unit_variant in units:
		var fireteam_id: String = _resolve_fireteam_id(unit_variant, {})
		if fireteam_id.is_empty():
			fireteam_id = "unassigned"
		var members: Array = Array(grouped.get(fireteam_id, []))
		members.append(unit_variant)
		grouped[fireteam_id] = members
	var fireteam_contexts: Dictionary = {}
	var fireteam_ids: Array = grouped.keys()
	fireteam_ids.sort()
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant)
		fireteam_contexts[fireteam_id] = build_fireteam_character_context(fireteam_id, Array(grouped.get(fireteam_id, [])), options)
	return {
		"source": SOURCE_ID,
		"fireteams": fireteam_contexts,
		"public_snapshot": build_public_snapshot({"fireteams": fireteam_contexts}),
	}


static func resolve_ftl_context(leader, fireteam_units: Array = [], context: Dictionary = {}) -> Dictionary:
	var explicit_context: Dictionary = _read_explicit_character_context(context)
	if not explicit_context.is_empty():
		return explicit_context
	if not _has_character_signal(leader, context) and fireteam_units.is_empty() and not context.has("fireteam_units"):
		return {}
	var fireteam_id: String = _resolve_fireteam_id(leader, context)
	var units: Array = fireteam_units.duplicate()
	if units.is_empty() and context.has("fireteam_units"):
		units = _to_array(context.get("fireteam_units", []))
	if units.is_empty() and leader != null:
		units.append(leader)
	var fireteam_context: Dictionary = build_fireteam_character_context(fireteam_id, units, context)
	var modifiers: Dictionary = Dictionary(fireteam_context.get("gameplay_modifiers", {}))
	var skill_tier: String = _resolve_ftl_skill_tier(float(fireteam_context.get("leadership", 0.0)), float(fireteam_context.get("communication", 0.0)), float(modifiers.get("ftl_clarity_modifier", 0.0)))
	fireteam_context["skill_tier"] = skill_tier
	fireteam_context["ftl_clarity_label"] = _label_for_modifier(float(modifiers.get("ftl_clarity_modifier", 0.0)))
	return fireteam_context


static func resolve_thought_context(unit, context: Dictionary = {}) -> Dictionary:
	if not _has_character_signal(unit, context):
		return {}
	var state: Dictionary = build_unit_character_state(unit, context)
	var fireteam_context: Dictionary = _lookup_fireteam_context(String(state.get("fireteam_id", "")), context)
	state["teamfit_label"] = String(fireteam_context.get("cohesion_label", context.get("cohesion_label", ""))).strip_edges()
	state["teamfit_summary_text"] = String(fireteam_context.get("teamfit_summary_text", context.get("teamfit_summary_text", ""))).strip_edges()
	state["thought_key"] = _resolve_thought_key(state)
	state["thought_text"] = _resolve_thought_text(state)
	state["thought_priority_bonus"] = _resolve_thought_priority_bonus(state)
	state["public_display_state"] = _build_public_unit_display_state(state)
	return state


static func build_public_snapshot(character_context: Dictionary) -> Array:
	var fireteams: Dictionary = Dictionary(character_context.get("fireteams", character_context))
	var result: Array = []
	var fireteam_ids: Array = fireteams.keys()
	fireteam_ids.sort()
	for fireteam_id_variant in fireteam_ids:
		if typeof(fireteams.get(fireteam_id_variant, {})) != TYPE_DICTIONARY:
			continue
		var fireteam_context: Dictionary = Dictionary(fireteams.get(fireteam_id_variant, {}))
		var fireteam_id: String = String(fireteam_context.get("fireteam_id", fireteam_id_variant)).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		result.append({
			"source": SOURCE_ID,
			"fireteam_id": fireteam_id,
			"cohesion_label": String(fireteam_context.get("cohesion_label", "")),
			"cohesion_percent": clampi(int(fireteam_context.get("cohesion_percent", 0)), 0, 100),
			"morale_state": String(fireteam_context.get("morale_state", "")),
			"frustration_state": String(fireteam_context.get("frustration_state", "")),
			"communication_label": _label_for_value(float(fireteam_context.get("communication", 0.0))),
			"member_count": maxi(int(fireteam_context.get("member_count", 0)), 0),
		})
	return result


static func snapshot_has_private_fields(snapshot_entries: Array) -> bool:
	for entry_variant in snapshot_entries:
		if _variant_has_private_fields(entry_variant):
			return true
	return false


static func _build_cohesion_snapshot(fireteam_id: String, members: Array, leader_unit_id: String) -> Dictionary:
	if members.is_empty():
		return FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", fireteam_id, [], leader_unit_id)
	var dictionaries: Array = []
	for unit_variant in members:
		dictionaries.append(_unit_to_dictionary(unit_variant))
	return FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", fireteam_id, dictionaries, leader_unit_id)


static func _normalize_member_units(units: Array, fireteam_id: String, options: Dictionary) -> Array:
	var result: Array = []
	for unit_variant in units:
		var unit_fireteam_id: String = _resolve_fireteam_id(unit_variant, options)
		if not fireteam_id.is_empty() and not unit_fireteam_id.is_empty() and unit_fireteam_id != fireteam_id:
			continue
		result.append(unit_variant)
	return result


static func _resolve_leader_state(member_states: Array) -> Dictionary:
	var best_state: Dictionary = Dictionary(member_states[0]).duplicate(true) if not member_states.is_empty() else {}
	var best_score: float = -1.0
	for state_variant in member_states:
		var state: Dictionary = Dictionary(state_variant)
		var score: float = float(state.get("leadership", 0.0))
		if String(state.get("role_id", "")).to_lower().contains("leader"):
			score += 0.10
		if score > best_score:
			best_score = score
			best_state = state.duplicate(true)
	return best_state


static func _read_skill_values(unit, context_state: Dictionary) -> Dictionary:
	var skill_values: Dictionary = _read_dictionary(unit, "skill_values", Dictionary(context_state.get("skill_values", {})))
	if skill_values.is_empty() and _has_method(unit, "get_character_profile_bundle"):
		var bundle: Dictionary = Dictionary(unit.call("get_character_profile_bundle"))
		skill_values = Dictionary(bundle.get("core_values", {}))
	for pair in [
		{"key": "accuracy", "method": "get_accuracy_skill", "property": "skill_accuracy"},
		{"key": "speed", "method": "get_speed_skill", "property": "skill_speed"},
		{"key": "leadership", "method": "get_leadership_skill", "property": "skill_leadership"},
		{"key": "toughness", "method": "get_toughness_skill", "property": "skill_toughness"},
		{"key": "awareness", "method": "get_awareness", "property": "awareness"},
		{"key": "discipline", "method": "get_discipline", "property": "discipline"},
	]:
		var key: String = String(pair["key"])
		if skill_values.has(key):
			continue
		skill_values[key] = _read_float(unit, String(pair["method"]), String(pair["property"]), float(context_state.get(key, 0.0)))
	return skill_values


static func _resolve_communication_value(unit, communication_values: Dictionary, context_state: Dictionary, leadership: float) -> float:
	var direct_value: float = float(context_state.get("communication", -1.0))
	if direct_value >= 0.0:
		return clampf(direct_value, 0.0, 1.0)
	var values: Array = []
	for key in ["speech_quality", "discipline", "awareness"]:
		if communication_values.has(key):
			values.append(float(communication_values.get(key, 0.0)))
	var speech_quality: float = _read_float(unit, "", "speech_quality", -1.0)
	if speech_quality >= 0.0:
		values.append(speech_quality)
	var discipline: float = _read_float(unit, "get_discipline", "discipline", -1.0)
	if discipline >= 0.0:
		values.append(discipline)
	if values.is_empty():
		return clampf(leadership, 0.0, 1.0)
	var total: float = 0.0
	for value_variant in values:
		total += float(value_variant)
	return clampf(total / float(values.size()), 0.0, 1.0)


static func _summarize_relationships(unit, context_state: Dictionary) -> Dictionary:
	var links: Array = []
	if context_state.has("relationship_links"):
		links = _to_array(context_state.get("relationship_links", []))
	else:
		links = _to_array(_read_property(unit, "relationship_links", []))
	var best: Dictionary = {}
	var worst: Dictionary = {}
	for link_variant in links:
		if typeof(link_variant) != TYPE_DICTIONARY:
			continue
		var link: Dictionary = Dictionary(link_variant)
		var affinity: float = float(link.get("affinity", link.get("affinity_score", 0.0)))
		if absf(affinity) > 1.0:
			affinity /= 100.0
		if affinity > 0.0 and (best.is_empty() or affinity > float(best.get("affinity", -1.0))):
			best = link.duplicate(true)
			best["affinity"] = affinity
		if affinity < 0.0 and (worst.is_empty() or affinity < float(worst.get("affinity", 1.0))):
			worst = link.duplicate(true)
			worst["affinity"] = affinity
	if not worst.is_empty() and float(worst.get("affinity", 0.0)) <= -0.18:
		return {"hint": "tension", "target_name": String(worst.get("target_name", "")), "affinity": float(worst.get("affinity", 0.0))}
	if not best.is_empty() and float(best.get("affinity", 0.0)) >= 0.18:
		return {"hint": "trust", "target_name": String(best.get("target_name", "")), "affinity": float(best.get("affinity", 0.0))}
	return {"hint": "", "target_name": "", "affinity": 0.0}


static func _resolve_thought_key(state: Dictionary) -> String:
	if String(state.get("frustration_state", "")) == "high":
		return "frustration"
	if String(state.get("morale_state", "")) == "low":
		return "low_morale"
	if String(state.get("relationship_hint", "")) == "tension":
		return "teamfit_tension"
	if String(state.get("relationship_hint", "")) == "trust" or String(state.get("teamfit_label", "")) == "strong":
		return "teamfit_trust"
	return ""


static func _resolve_thought_text(state: Dictionary) -> String:
	match String(state.get("thought_key", "")):
		"frustration":
			return "Das passt mir\nnoch nicht."
		"low_morale":
			return "Nicht mein\nbester Tag."
		"teamfit_tension":
			return "Teamfit wackelt.\nIch bleibe wach."
		"teamfit_trust":
			return "Team sitzt.\nWeiter."
		_:
			return ""


static func _resolve_thought_priority_bonus(state: Dictionary) -> int:
	match String(state.get("thought_key", "")):
		"frustration":
			return 34
		"low_morale":
			return 24
		"teamfit_tension":
			return 18
		"teamfit_trust":
			return 8
		_:
			return 0


static func _build_public_unit_display_state(state: Dictionary) -> Dictionary:
	return {
		"unit_id": String(state.get("unit_id", "")),
		"fireteam_id": String(state.get("fireteam_id", "")),
		"morale_state": String(state.get("morale_state", "")),
		"frustration_state": String(state.get("frustration_state", "")),
		"teamfit_label": String(state.get("teamfit_label", "")),
	}


static func _lookup_context_unit_state(unit_id: String, context: Dictionary) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	if context.has("character_state") and typeof(context.get("character_state")) == TYPE_DICTIONARY:
		return Dictionary(context.get("character_state", {})).duplicate(true)
	if context.has("unit_character_state_by_id") and typeof(context.get("unit_character_state_by_id")) == TYPE_DICTIONARY:
		var by_id: Dictionary = Dictionary(context.get("unit_character_state_by_id", {}))
		if by_id.has(normalized_unit_id) and typeof(by_id.get(normalized_unit_id)) == TYPE_DICTIONARY:
			return Dictionary(by_id.get(normalized_unit_id, {})).duplicate(true)
	return {}


static func _lookup_fireteam_context(fireteam_id: String, context: Dictionary) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if context.has("fireteam_character_context") and typeof(context.get("fireteam_character_context")) == TYPE_DICTIONARY:
		return Dictionary(context.get("fireteam_character_context", {})).duplicate(true)
	if context.has("fireteam_character_context_by_id") and typeof(context.get("fireteam_character_context_by_id")) == TYPE_DICTIONARY:
		var by_id: Dictionary = Dictionary(context.get("fireteam_character_context_by_id", {}))
		if by_id.has(normalized_fireteam_id) and typeof(by_id.get(normalized_fireteam_id)) == TYPE_DICTIONARY:
			return Dictionary(by_id.get(normalized_fireteam_id, {})).duplicate(true)
	return {}


static func _read_explicit_character_context(context: Dictionary) -> Dictionary:
	for key in ["character_gameplay_context", "fireteam_character_context"]:
		if context.has(key) and typeof(context.get(key)) == TYPE_DICTIONARY:
			var value: Dictionary = Dictionary(context.get(key)).duplicate(true)
			if String(value.get("source", "")) == SOURCE_ID:
				return value
	return {}


static func _has_character_signal(unit, context: Dictionary) -> bool:
	if context.has("character_state") or context.has("unit_character_state_by_id") or context.has("fireteam_character_context") or context.has("character_gameplay_context"):
		return true
	if typeof(unit) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(unit)
		return dict.has("unit_id") or dict.has("progression") or dict.has("skill_values") or dict.has("relationship_links")
	if _has_method(unit, "get_unit_id") or _has_method(unit, "get_leadership_skill") or _has_method(unit, "get_character_profile_bundle"):
		return true
	return false


static func _unit_to_dictionary(unit) -> Dictionary:
	if typeof(unit) == TYPE_DICTIONARY:
		return Dictionary(unit).duplicate(true)
	var result: Dictionary = {}
	for key in [
		"unit_id",
		"display_name",
		"fireteam_id",
		"role_id",
		"skill_values",
		"communication_values",
		"progression",
		"relationship_links",
	]:
		var value: Variant = _read_property(unit, key, null)
		if value != null:
			result[key] = value
	if _has_method(unit, "get_unit_id"):
		result["unit_id"] = String(unit.call("get_unit_id"))
	if _has_method(unit, "get_display_name"):
		result["display_name"] = String(unit.call("get_display_name"))
	if _has_method(unit, "get_fireteam_id"):
		result["fireteam_id"] = String(unit.call("get_fireteam_id"))
	result["skill_values"] = _read_skill_values(unit, result)
	return result


static func _resolve_unit_id(unit, context: Dictionary) -> String:
	if context.has("unit_id"):
		var context_id: String = String(context.get("unit_id", "")).strip_edges().to_lower()
		if not context_id.is_empty():
			return context_id
	if typeof(unit) == TYPE_DICTIONARY:
		return String(Dictionary(unit).get("unit_id", "")).strip_edges().to_lower()
	if _has_method(unit, "get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges().to_lower()
	return ""


static func _resolve_display_name(unit, context_state: Dictionary, unit_id: String) -> String:
	var display_name: String = String(context_state.get("display_name", "")).strip_edges()
	if not display_name.is_empty():
		return display_name
	if typeof(unit) == TYPE_DICTIONARY:
		display_name = String(Dictionary(unit).get("display_name", "")).strip_edges()
	elif _has_method(unit, "get_display_name"):
		display_name = String(unit.call("get_display_name")).strip_edges()
	return display_name if not display_name.is_empty() else unit_id


static func _resolve_fireteam_id(unit, context_state: Dictionary) -> String:
	var fireteam_id: String = String(context_state.get("fireteam_id", "")).strip_edges().to_lower()
	if not fireteam_id.is_empty():
		return fireteam_id
	if typeof(unit) == TYPE_DICTIONARY:
		return String(Dictionary(unit).get("fireteam_id", "")).strip_edges().to_lower()
	if _has_method(unit, "get_fireteam_id"):
		return String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	return ""


static func _resolve_role_id(unit, context_state: Dictionary) -> String:
	var role_id: String = String(context_state.get("role_id", context_state.get("roster_role_category", ""))).strip_edges().to_lower()
	if not role_id.is_empty():
		return role_id
	if typeof(unit) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(unit)
		return String(dict.get("role_id", dict.get("roster_role_category", ""))).strip_edges().to_lower()
	if _has_method(unit, "get_role_id"):
		return String(unit.call("get_role_id")).strip_edges().to_lower()
	return ""


static func _read_dictionary(unit, property_name: String, fallback: Dictionary) -> Dictionary:
	var value: Variant = _read_property(unit, property_name, null)
	if typeof(value) == TYPE_DICTIONARY:
		return Dictionary(value).duplicate(true)
	return fallback.duplicate(true)


static func _read_float(unit, method_name: String, property_name: String, fallback: float) -> float:
	if not method_name.is_empty() and _has_method(unit, method_name):
		return clampf(float(unit.call(method_name)), 0.0, 1.0)
	var value: Variant = _read_property(unit, property_name, null)
	if value != null:
		return clampf(float(value), 0.0, 1.0)
	return fallback


static func _read_property(unit, property_name: String, fallback: Variant) -> Variant:
	if property_name.is_empty():
		return fallback
	if typeof(unit) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(unit)
		return dict.get(property_name, fallback)
	if unit != null and unit.has_method("get"):
		var value: Variant = unit.call("get", property_name)
		if value != null:
			return value
	return fallback


static func _has_method(unit, method_name: String) -> bool:
	return unit != null and typeof(unit) == TYPE_OBJECT and unit.has_method(method_name)


static func _to_array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return Array(value)
	if value is PackedStringArray:
		var result: Array = []
		for entry in PackedStringArray(value):
			result.append(String(entry))
		return result
	return []


static func _average_state_value(states: Array, key: String, fallback: float) -> float:
	if states.is_empty():
		return fallback
	var total: float = 0.0
	for state_variant in states:
		total += float(Dictionary(state_variant).get(key, fallback))
	return clampf(total / float(states.size()), 0.0, 1.0)


static func _resolve_skill_tier(leadership: float, communication: float, morale: float, frustration: float) -> String:
	var score: float = clampf(maxf(leadership, communication) + (morale - 0.50) * 0.10 - frustration * 0.08, 0.0, 1.0)
	if score >= 0.65:
		return "high"
	if score <= 0.38:
		return "low"
	return "neutral"


static func _resolve_ftl_skill_tier(leadership: float, communication: float, clarity_modifier: float) -> String:
	var score: float = clampf(maxf(leadership, communication) + clarity_modifier, 0.0, 1.0)
	if score >= 0.65:
		return "high"
	if score <= 0.38:
		return "low"
	return "neutral"


static func _state_from_value(value: float, low_threshold: float, high_threshold: float, low_label: String, mid_label: String, high_label: String) -> String:
	if value <= low_threshold:
		return low_label
	if value >= high_threshold:
		return high_label
	return mid_label


static func _label_for_modifier(value: float) -> String:
	if value >= 0.025:
		return "clear"
	if value <= -0.025:
		return "muddy"
	return "normal"


static func _label_for_value(value: float) -> String:
	if value >= 0.66:
		return "clear"
	if value <= 0.38:
		return "low"
	return "normal"


static func _variant_has_private_fields(value: Variant) -> bool:
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		for key_variant in dict.keys():
			var key: String = String(key_variant).strip_edges().to_lower()
			if ["relationship_links", "relationship_pairs", "progression", "morale", "frustration", "display_name", "relationship_affinity"].has(key):
				return true
			if _variant_has_private_fields(dict.get(key_variant)):
				return true
	elif value is Array:
		for entry_variant in Array(value):
			if _variant_has_private_fields(entry_variant):
				return true
	return false
