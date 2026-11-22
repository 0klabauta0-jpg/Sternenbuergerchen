class_name MetaUnitProfileBuilder
extends RefCounted

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const UNIT_SKILLS_SCRIPT: GDScript = preload("res://scripts/npc/unit_skills.gd")
const UNIT_TRAIT_SCRIPT: GDScript = preload("res://scripts/npc/unit_trait.gd")
const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")


static func build_from_identity_config(identity_config: Dictionary, options: Dictionary = {}):
	var unit_id: String = String(identity_config.get("unit_id", "")).strip_edges()
	var display_name: String = _resolve_display_name(identity_config, unit_id)
	var fireteam_id: String = String(identity_config.get("fireteam_id", "")).strip_edges().to_lower()
	var skills = _build_effective_skills(identity_config)
	var trait_ids: PackedStringArray = _coerce_trait_ids(identity_config.get("trait_ids", []))
	var trait_tags: PackedStringArray = _build_trait_tags(trait_ids)
	var bundle: Dictionary = _build_character_bundle(identity_config, skills)

	var profile_data := {
		"unit_id": unit_id,
		"display_name": display_name,
		"portrait_id": String(identity_config.get("portrait_id", "")).strip_edges(),
		"portrait_path": String(identity_config.get("portrait_path", "")).strip_edges(),
		"callsign": String(identity_config.get("callsign", "")).strip_edges(),
		"role_id": String(bundle.get("role_id", String(identity_config.get("role_id", "")).strip_edges().to_lower())).strip_edges(),
		"role_name": String(identity_config.get("role_name", "")).strip_edges(),
		"roster_role_category": String(identity_config.get("roster_role_category", "")).strip_edges().to_lower(),
		"specialty_text": String(bundle.get("primary_specialty", String(identity_config.get("specialty_text", "")).strip_edges())).strip_edges(),
		"primary_specialty": String(bundle.get("primary_specialty", "")).strip_edges(),
		"secondary_specialty": String(bundle.get("secondary_specialty", "")).strip_edges(),
		"short_description": _build_short_description(identity_config),
		"homeworld": String(identity_config.get("homeworld", "")).strip_edges(),
		"age_years": int(identity_config.get("age_years", 0)),
		"biography_text": String(identity_config.get("biography_text", "")).strip_edges(),
		"loadout_summary": String(identity_config.get("loadout_summary", "")).strip_edges(),
		"armor_id": String(identity_config.get("armor", identity_config.get("armor_id", "medium"))).strip_edges().to_lower(),
		"weapon_1_id": String(identity_config.get("weapon_1_id", identity_config.get("weapon_1", "rifle"))).strip_edges().to_lower(),
		"weapon_2_id": String(identity_config.get("weapon_2_id", identity_config.get("weapon_2", "rifle"))).strip_edges().to_lower(),
		"team_id": String(identity_config.get("team_id", "")).strip_edges(),
		"fireteam_id": fireteam_id,
		"is_fireteam_lead": bool(identity_config.get("is_fireteam_lead", false)),
		"skill_values": Dictionary(bundle.get("core_values", skills.to_dict())).duplicate(true),
		"skill_summary_text": _build_skill_summary_text(skills),
		"communication_values": Dictionary(bundle.get("communication_values", {})).duplicate(true),
		"platform_values": Dictionary(bundle.get("platform_values", {})).duplicate(true),
		"behavior_axes": Dictionary(bundle.get("behavior_axes", {})).duplicate(true),
		"method_scores": Dictionary(bundle.get("method_scores", {})).duplicate(true),
		"function_scores": Dictionary(bundle.get("function_scores", {})).duplicate(true),
		"method_summary_text": String(bundle.get("method_summary", "")).strip_edges(),
		"function_summary_text": String(bundle.get("function_summary", "")).strip_edges(),
		"combat_effect_summary_text": String(bundle.get("combat_effect_summary", "")).strip_edges(),
		"trait_ids": trait_ids,
		"trait_tags": trait_tags,
		"trait_summary_text": " ".join(trait_tags),
		"status_text": String(options.get("status_text", identity_config.get("status_text", ""))).strip_edges(),
		"secondary_text": String(options.get("secondary_text", identity_config.get("secondary_text", ""))).strip_edges(),
		"availability_status": String(identity_config.get("availability_status", "active")).strip_edges().to_lower(),
		"recovery_state": Dictionary(identity_config.get("recovery_state", {})).duplicate(true),
		"respawns_used": identity_config.get("respawns_used", 0),
		"relationship_summary_text": String(identity_config.get("relationship_summary_text", "")).strip_edges(),
		"relationship_links": Array(identity_config.get("relationship_links", [])).duplicate(true),
		"fireteam_history": Array(identity_config.get("fireteam_history", [])).duplicate(true),
		"mission_history": Array(identity_config.get("mission_history", [])).duplicate(true),
		"progression": Dictionary(identity_config.get("progression", {})).duplicate(true),
		"ftl_tactical_progression": Dictionary(identity_config.get("ftl_tactical_progression", {})).duplicate(true),
		"ftl_tactical_effect_text": String(identity_config.get("ftl_tactical_effect_text", "")).strip_edges(),
	}
	profile_data["rank_badges"] = NPC_RANK_BADGE_RESOLVER_SCRIPT.call("derive_badges", _build_badge_source(profile_data, identity_config))
	return META_UNIT_PROFILE_SCRIPT.new(profile_data)


static func build_from_test_unit(test_unit, options: Dictionary = {}):
	if test_unit == null:
		return META_UNIT_PROFILE_SCRIPT.new()

	var unit_id: String = _read_string_value(test_unit, "get_unit_id", "unit_id")
	var display_name: String = _read_string_value(test_unit, "get_display_name", "display_name")
	var fireteam_id: String = _read_string_value(test_unit, "get_fireteam_id", "fireteam_id").to_lower()
	var skill_values: Dictionary = {}
	if test_unit.has_method("get_skills"):
		var skills = test_unit.call("get_skills")
		if skills != null and skills.has_method("to_dict"):
			skill_values = Dictionary(skills.call("to_dict")).duplicate(true)

	var skill_summary_text: String = ""
	if test_unit.has_method("get_skill_summary_text"):
		skill_summary_text = String(test_unit.call("get_skill_summary_text"))
	var character_bundle: Dictionary = {}
	if test_unit.has_method("get_character_profile_bundle"):
		character_bundle = Dictionary(test_unit.call("get_character_profile_bundle")).duplicate(true)

	var trait_ids: PackedStringArray = []
	if test_unit.has_method("get_trait_ids"):
		trait_ids = _coerce_trait_ids(test_unit.call("get_trait_ids"))

	var trait_tags: PackedStringArray = []
	if test_unit.has_method("get_trait_tags"):
		trait_tags = _coerce_trait_ids(test_unit.call("get_trait_tags"))

	var trait_summary_text: String = ""
	if test_unit.has_method("get_trait_summary_text"):
		trait_summary_text = String(test_unit.call("get_trait_summary_text"))

	var profile_data := {
		"unit_id": unit_id,
		"display_name": display_name,
		"portrait_id": _read_string_value(test_unit, "get_portrait_id", "portrait_id"),
		"portrait_path": _read_string_value(test_unit, "get_portrait_path", "portrait_path"),
		"callsign": _read_string_value(test_unit, "get_callsign", "callsign"),
		"role_id": _read_string_value(test_unit, "get_role_id", "role_id"),
		"role_name": _read_string_value(test_unit, "get_role_name", "role_name"),
		"roster_role_category": _read_string_value(test_unit, "get_roster_role_category", "roster_role_category"),
		"specialty_text": String(character_bundle.get("primary_specialty", _read_string_value(test_unit, "get_specialty_text", "specialty_text"))).strip_edges(),
		"primary_specialty": String(character_bundle.get("primary_specialty", "")).strip_edges(),
		"secondary_specialty": String(character_bundle.get("secondary_specialty", "")).strip_edges(),
		"short_description": _read_string_value(test_unit, "get_short_description", "short_description"),
		"homeworld": _read_string_value(test_unit, "get_homeworld", "homeworld"),
		"age_years": int(test_unit.get("age_years")) if test_unit.get("age_years") != null else 0,
		"biography_text": _read_string_value(test_unit, "get_biography_text", "biography_text"),
		"loadout_summary": _read_string_value(test_unit, "get_loadout_summary", "loadout_summary"),
		"armor_id": _read_string_value(test_unit, "get_armor_id", "armor_id"),
		"weapon_1_id": _read_string_value(test_unit, "get_weapon_1_id", "weapon_1_id"),
		"weapon_2_id": _read_string_value(test_unit, "get_weapon_2_id", "weapon_2_id"),
		"team_id": _read_string_value(test_unit, "get_team_id", "team_id"),
		"fireteam_id": fireteam_id,
		"is_fireteam_lead": bool(test_unit.get("is_fireteam_lead")) if test_unit.get("is_fireteam_lead") != null else false,
		"skill_values": Dictionary(character_bundle.get("core_values", skill_values)).duplicate(true),
		"skill_summary_text": skill_summary_text,
		"communication_values": Dictionary(character_bundle.get("communication_values", {})).duplicate(true),
		"platform_values": Dictionary(character_bundle.get("platform_values", {})).duplicate(true),
		"behavior_axes": Dictionary(character_bundle.get("behavior_axes", {})).duplicate(true),
		"method_scores": Dictionary(character_bundle.get("method_scores", {})).duplicate(true),
		"function_scores": Dictionary(character_bundle.get("function_scores", {})).duplicate(true),
		"method_summary_text": String(character_bundle.get("method_summary", "")).strip_edges(),
		"function_summary_text": String(character_bundle.get("function_summary", "")).strip_edges(),
		"combat_effect_summary_text": String(character_bundle.get("combat_effect_summary", "")).strip_edges(),
		"trait_ids": trait_ids,
		"trait_tags": trait_tags,
		"trait_summary_text": trait_summary_text,
		"status_text": String(options.get("status_text", "")).strip_edges(),
		"secondary_text": String(options.get("secondary_text", "")).strip_edges(),
		"availability_status": _read_string_value(test_unit, "get_availability_status", "availability_status"),
		"recovery_state": Dictionary(test_unit.get("recovery_state")) if test_unit.get("recovery_state") != null else {},
		"relationship_summary_text": _read_string_value(test_unit, "get_relationship_summary_text", "relationship_summary_text"),
		"relationship_links": Array(test_unit.get("relationship_links")) if test_unit.get("relationship_links") != null else [],
		"fireteam_history": Array(test_unit.get("fireteam_history")) if test_unit.get("fireteam_history") != null else [],
		"mission_history": Array(test_unit.get("mission_history")) if test_unit.get("mission_history") != null else [],
		"progression": Dictionary(test_unit.get("progression")) if test_unit.get("progression") != null else {},
		"ftl_tactical_progression": Dictionary(test_unit.get("ftl_tactical_progression")) if test_unit.get("ftl_tactical_progression") != null else {},
		"ftl_tactical_effect_text": _read_string_value(test_unit, "get_ftl_tactical_effect_text", "ftl_tactical_effect_text"),
	}
	profile_data["rank_badges"] = NPC_RANK_BADGE_RESOLVER_SCRIPT.call("derive_badges", _build_badge_source(profile_data, profile_data))
	return META_UNIT_PROFILE_SCRIPT.new(profile_data)


static func build_profiles_by_unit_id(identity_configs: Array, options_by_unit_id: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {}
	for identity_config in identity_configs:
		if typeof(identity_config) != TYPE_DICTIONARY:
			continue

		var unit_data: Dictionary = identity_config
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue

		var profile_options: Dictionary = {}
		if options_by_unit_id.has(unit_id) and typeof(options_by_unit_id[unit_id]) == TYPE_DICTIONARY:
			profile_options = Dictionary(options_by_unit_id[unit_id]).duplicate(true)

		var profile = build_from_identity_config(unit_data, profile_options)
		if profile != null and profile.is_valid():
			result[unit_id] = profile

	return result


static func _build_badge_source(profile_data: Dictionary, source_data: Dictionary) -> Dictionary:
	var result: Dictionary = profile_data.duplicate(true)
	result["source_role_id"] = String(source_data.get("role_id", result.get("role_id", ""))).strip_edges().to_lower()
	if source_data.has("weapon_1"):
		result["weapon_1"] = String(source_data.get("weapon_1", "")).strip_edges().to_lower()
	if source_data.has("weapon_2"):
		result["weapon_2"] = String(source_data.get("weapon_2", "")).strip_edges().to_lower()
	if source_data.has("is_fireteam_lead"):
		result["is_fireteam_lead"] = bool(source_data.get("is_fireteam_lead", false))
	for key in ["skill_accuracy", "skill_speed", "skill_leadership", "skill_toughness", "dropship_piloting", "freighter_piloting", "fighter_piloting", "ground_vehicle_handling"]:
		if source_data.has(key):
			result[key] = source_data.get(key)
	return result


static func _build_effective_skills(identity_config: Dictionary):
	var skills = UNIT_SKILLS_SCRIPT.new(
		{
			"accuracy": float(identity_config.get("skill_accuracy", UNIT_SKILLS_SCRIPT.DEFAULT_ACCURACY)),
			"speed": float(identity_config.get("skill_speed", UNIT_SKILLS_SCRIPT.DEFAULT_SPEED)),
			"leadership": float(identity_config.get("skill_leadership", UNIT_SKILLS_SCRIPT.DEFAULT_LEADERSHIP)),
			"toughness": float(identity_config.get("skill_toughness", UNIT_SKILLS_SCRIPT.DEFAULT_TOUGHNESS)),
		}
	)

	for trait_id in _coerce_trait_ids(identity_config.get("trait_ids", [])):
		var unit_trait = UNIT_TRAIT_SCRIPT.from_id(String(trait_id))
		if unit_trait == null:
			continue

		unit_trait.apply_to_skills(skills)

	return skills


static func _build_skill_summary_text(skills) -> String:
	if skills == null:
		return ""

	return "A:%.1f S:%.1f L:%.1f T:%.1f" % [
		float(skills.accuracy),
		float(skills.speed),
		float(skills.leadership),
		float(skills.toughness),
	]


static func _build_trait_tags(trait_ids: PackedStringArray) -> PackedStringArray:
	var tags: PackedStringArray = []
	for trait_id in trait_ids:
		var unit_trait = UNIT_TRAIT_SCRIPT.from_id(String(trait_id))
		if unit_trait == null:
			continue

		tags.append("[%s]" % String(unit_trait.short_tag))

	return tags


static func _coerce_trait_ids(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		var packed_value: PackedStringArray = value
		var result_from_packed: PackedStringArray = []
		for entry in packed_value:
			var trait_id: String = String(entry).strip_edges().to_lower()
			if trait_id.is_empty():
				continue

			result_from_packed.append(trait_id)
		return result_from_packed

	var result: PackedStringArray = []
	if value is Array:
		for entry in value:
			var trait_id: String = String(entry).strip_edges().to_lower()
			if trait_id.is_empty():
				continue

			result.append(trait_id)

	return result


static func _build_character_bundle(identity_config: Dictionary, skills) -> Dictionary:
	var metric_input: Dictionary = identity_config.duplicate(true)
	metric_input["accuracy"] = float(skills.accuracy)
	metric_input["speed"] = float(skills.speed)
	metric_input["toughness"] = float(skills.toughness)
	metric_input["leadership"] = float(skills.leadership)
	return UNIT_PROFILE_MATH_SCRIPT.build_character_bundle(metric_input)


static func _build_short_description(identity_config: Dictionary) -> String:
	var explicit_text: String = String(identity_config.get("short_description", "")).strip_edges()
	if not explicit_text.is_empty():
		return explicit_text
	var biography_text: String = String(identity_config.get("biography_text", "")).strip_edges()
	if biography_text.is_empty():
		return ""
	var sentence_parts: PackedStringArray = biography_text.split(".", false)
	if sentence_parts.is_empty():
		return biography_text
	return "%s." % String(sentence_parts[0]).strip_edges()


static func _resolve_display_name(identity_config: Dictionary, unit_id: String) -> String:
	var display_name: String = String(identity_config.get("display_name", unit_id)).strip_edges()
	if not display_name.is_empty():
		return display_name

	if unit_id.is_empty():
		return "Unknown Unit"

	var parts: PackedStringArray = unit_id.split("_", false)
	for index in range(parts.size()):
		parts[index] = parts[index].capitalize()

	return " ".join(parts)


static func _read_string_value(target, method_name: String, property_name: String) -> String:
	if target == null:
		return ""

	if target.has_method(method_name):
		var method_value: Variant = target.call(method_name)
		if method_value == null:
			return ""
		return String(method_value).strip_edges()

	var property_value: Variant = target.get(property_name)
	if property_value == null:
		return ""
	return String(property_value).strip_edges()
