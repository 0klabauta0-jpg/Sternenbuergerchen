class_name MetaUnitProfileBuilder
extends RefCounted

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const UNIT_SKILLS_SCRIPT: GDScript = preload("res://scripts/npc/unit_skills.gd")
const UNIT_TRAIT_SCRIPT: GDScript = preload("res://scripts/npc/unit_trait.gd")


static func build_from_identity_config(identity_config: Dictionary, options: Dictionary = {}):
	var unit_id: String = String(identity_config.get("unit_id", "")).strip_edges()
	var display_name: String = _resolve_display_name(identity_config, unit_id)
	var fireteam_id: String = String(identity_config.get("fireteam_id", "")).strip_edges().to_lower()
	var skills = _build_effective_skills(identity_config)
	var trait_ids: PackedStringArray = _coerce_trait_ids(identity_config.get("trait_ids", []))
	var trait_tags: PackedStringArray = _build_trait_tags(trait_ids)

	return META_UNIT_PROFILE_SCRIPT.new(
		{
			"unit_id": unit_id,
			"display_name": display_name,
			"portrait_path": String(identity_config.get("portrait_path", "")).strip_edges(),
			"callsign": String(identity_config.get("callsign", "")).strip_edges(),
			"role_name": String(identity_config.get("role_name", "")).strip_edges(),
			"specialty_text": String(identity_config.get("specialty_text", "")).strip_edges(),
			"homeworld": String(identity_config.get("homeworld", "")).strip_edges(),
			"age_years": int(identity_config.get("age_years", 0)),
			"biography_text": String(identity_config.get("biography_text", "")).strip_edges(),
			"loadout_summary": String(identity_config.get("loadout_summary", "")).strip_edges(),
			"team_id": String(identity_config.get("team_id", "")).strip_edges(),
			"fireteam_id": fireteam_id,
			"skill_values": skills.to_dict(),
			"skill_summary_text": _build_skill_summary_text(skills),
			"trait_ids": trait_ids,
			"trait_tags": trait_tags,
			"trait_summary_text": " ".join(trait_tags),
			"status_text": String(options.get("status_text", identity_config.get("status_text", ""))).strip_edges(),
			"secondary_text": String(options.get("secondary_text", identity_config.get("secondary_text", ""))).strip_edges(),
		}
	)


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

	var trait_ids: PackedStringArray = []
	if test_unit.has_method("get_trait_ids"):
		trait_ids = _coerce_trait_ids(test_unit.call("get_trait_ids"))

	var trait_tags: PackedStringArray = []
	if test_unit.has_method("get_trait_tags"):
		trait_tags = _coerce_trait_ids(test_unit.call("get_trait_tags"))

	var trait_summary_text: String = ""
	if test_unit.has_method("get_trait_summary_text"):
		trait_summary_text = String(test_unit.call("get_trait_summary_text"))

	return META_UNIT_PROFILE_SCRIPT.new(
		{
			"unit_id": unit_id,
			"display_name": display_name,
			"portrait_path": _read_string_value(test_unit, "get_portrait_path", "portrait_path"),
			"callsign": _read_string_value(test_unit, "get_callsign", "callsign"),
			"role_name": _read_string_value(test_unit, "get_role_name", "role_name"),
			"specialty_text": _read_string_value(test_unit, "get_specialty_text", "specialty_text"),
			"homeworld": _read_string_value(test_unit, "get_homeworld", "homeworld"),
			"age_years": int(test_unit.get("age_years")) if test_unit.get("age_years") != null else 0,
			"biography_text": _read_string_value(test_unit, "get_biography_text", "biography_text"),
			"loadout_summary": _read_string_value(test_unit, "get_loadout_summary", "loadout_summary"),
			"team_id": _read_string_value(test_unit, "get_team_id", "team_id"),
			"fireteam_id": fireteam_id,
			"skill_values": skill_values,
			"skill_summary_text": skill_summary_text,
			"trait_ids": trait_ids,
			"trait_tags": trait_tags,
			"trait_summary_text": trait_summary_text,
			"status_text": String(options.get("status_text", "")).strip_edges(),
			"secondary_text": String(options.get("secondary_text", "")).strip_edges(),
		}
	)


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
		return String(target.call(method_name)).strip_edges()

	return String(target.get(property_name)).strip_edges()