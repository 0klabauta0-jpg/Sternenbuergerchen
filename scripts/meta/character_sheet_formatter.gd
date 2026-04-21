class_name CharacterSheetFormatter
extends RefCounted

const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
const UNIT_TRAIT_SCRIPT: GDScript = preload("res://scripts/npc/unit_trait.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const CORE_ORDER: Array = [
	["accuracy", "Accuracy"],
	["speed", "Speed"],
	["toughness", "Toughness"],
	["awareness", "Awareness"],
	["recognition", "Recognition"],
	["stealth", "Stealth"],
	["discipline", "Discipline"],
	["leadership", "Leadership"],
]
const BEHAVIOR_ORDER: Array = [
	["initiative", "Initiative"],
	["order_fidelity", "Order Fidelity"],
	["signature_control", "Signature Control"],
	["contact_stability", "Contact Stability"],
	["autonomy", "Autonomy"],
]
const COMMUNICATION_ORDER: Array = [
	["speech_quality", "Speech Quality"],
	["speech_quantity", "Speech Quantity"],
]
const PLATFORM_ORDER: Array = [
	["ground_vehicle_handling", "Ground Vehicle Handling"],
	["dropship_piloting", "Dropship Piloting"],
	["freighter_piloting", "Freighter Piloting"],
	["fighter_piloting", "Fighter Piloting"],
]
const METHOD_ORDER: Array = [
	["silent", "Silent"],
	["rapid", "Rapid"],
	["steady", "Steady"],
	["watchful", "Watchful"],
	["command", "Command"],
]
const FUNCTION_ORDER: Array = [
	["pathfinder", "Pathfinder"],
	["scout", "Scout"],
	["overwatch", "Overwatch"],
	["sentinel", "Sentinel"],
	["coordinator", "Coordinator"],
	["infiltrator", "Infiltrator"],
	["insertion_pilot", "Insertion Pilot"],
	["transport_pilot", "Transport Pilot"],
	["cargo_runner", "Cargo Runner"],
	["route_master", "Route Master"],
	["interceptor", "Interceptor"],
	["strike_pilot", "Strike Pilot"],
	["escort_pilot", "Escort Pilot"],
]


static func build_sheet_blocks(profile, options: Dictionary = {}) -> Dictionary:
	if profile == null:
		return {
			"name": "No operator selected",
			"identity": "No profile loaded",
			"role": "Role: unavailable\nPrimary: unavailable",
			"status": "Status: waiting for selection",
			"skills": "Core: unavailable",
			"traits": "Behavior: unavailable",
			"loadout": "Loadout: unavailable",
			"bio": "Bio: unavailable",
		}

	var status_text: String = String(options.get("status_text", profile.status_text)).strip_edges()
	var loadout_text: String = String(options.get("loadout_text", profile.loadout_summary)).strip_edges()
	var identity_lines: PackedStringArray = []
	if not String(profile.short_description).strip_edges().is_empty():
		identity_lines.append(String(profile.short_description).strip_edges())
	if not String(profile.callsign).strip_edges().is_empty():
		identity_lines.append("Callsign: %s" % String(profile.callsign).strip_edges())
	var origin_bits: PackedStringArray = []
	if not String(profile.homeworld).strip_edges().is_empty():
		origin_bits.append(String(profile.homeworld).strip_edges())
	if int(profile.age_years) > 0:
		origin_bits.append("Age %d" % int(profile.age_years))
	if not origin_bits.is_empty():
		identity_lines.append(" | ".join(origin_bits))
	if identity_lines.is_empty():
		identity_lines.append("No profile notes recorded.")

	var role_lines: PackedStringArray = []
	role_lines.append("Role: %s" % _optional_text(String(profile.role_name), "Operator"))
	role_lines.append("Primary: %s" % _optional_text(String(profile.primary_specialty), _optional_text(String(profile.specialty_text), "Generalist")))
	if not String(profile.secondary_specialty).strip_edges().is_empty():
		role_lines.append("Secondary: %s" % String(profile.secondary_specialty).strip_edges())
	role_lines.append("Methods: %s" % _optional_text(String(profile.method_summary_text), "No method profile"))
	role_lines.append("Functions: %s" % _optional_text(String(profile.function_summary_text), "No role fit"))

	var status_lines: PackedStringArray = []
	status_lines.append("Status: %s" % _optional_text(status_text, "standing by"))
	status_lines.append("Effects: %s" % _optional_text(String(profile.combat_effect_summary_text), "Move +0% | Aim +0% | Conceal +0% | Stability +0%"))

	var skill_parts: PackedStringArray = []
	var skill_values: Dictionary = Dictionary(profile.skill_values)
	for entry in CORE_ORDER:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		var value: float = float(skill_values.get(key, 0.0))
		skill_parts.append("%s %.2f %s" % [label, value, UNIT_PROFILE_MATH_SCRIPT.describe_value(value)])
	var skill_lines: PackedStringArray = ["Core: %s" % " | ".join(skill_parts.slice(0, 4))]
	if skill_parts.size() > 4:
		skill_lines.append("      %s" % " | ".join(skill_parts.slice(4, skill_parts.size())))

	var behavior_parts: PackedStringArray = []
	var behavior_axes: Dictionary = Dictionary(profile.behavior_axes)
	for entry in BEHAVIOR_ORDER:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		behavior_parts.append("%s %.2f" % [label, float(behavior_axes.get(key, 0.0))])
	var trait_lines: PackedStringArray = []
	trait_lines.append("Traits: %s" % _optional_text(String(profile.trait_summary_text), "none"))
	trait_lines.append("Behavior: %s" % " | ".join(behavior_parts))

	var communication_values: Dictionary = Dictionary(profile.communication_values)
	var platform_values: Dictionary = Dictionary(profile.platform_values)
	var support_lines: PackedStringArray = []
	support_lines.append(
		"Comms: Quality %.2f | Volume %.2f" % [
			float(communication_values.get("speech_quality", 0.0)),
			float(communication_values.get("speech_quantity", 0.0)),
		]
	)
	var platform_parts: PackedStringArray = []
	for entry in PLATFORM_ORDER:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		var value: float = float(platform_values.get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
		if value < 0.0:
			platform_parts.append("%s n/a" % label)
		else:
			platform_parts.append("%s %.2f" % [label, value])
	support_lines.append("Platform: %s" % " | ".join(platform_parts))
	support_lines.append("Loadout: %s" % _optional_text(loadout_text, "standard kit"))

	var bio_lines: PackedStringArray = []
	if not String(profile.biography_text).strip_edges().is_empty():
		bio_lines.append(String(profile.biography_text).strip_edges())
	else:
		bio_lines.append("No biography recorded.")
	if not String(profile.secondary_text).strip_edges().is_empty():
		bio_lines.append(String(profile.secondary_text).strip_edges())

	return {
		"name": String(profile.display_name),
		"identity": "\n".join(identity_lines),
		"role": "\n".join(role_lines),
		"status": "\n".join(status_lines),
		"skills": "\n".join(skill_lines),
		"traits": "\n".join(trait_lines),
		"loadout": "\n".join(support_lines),
		"bio": "Bio: %s" % "\n".join(bio_lines),
	}


static func build_sheet_view_model(profile, options: Dictionary = {}) -> Dictionary:
	if profile == null:
		return {
			"name": "No operator selected",
			"trait_text": "Keine Traits verfuegbar.",
			"short_description": "Keine Kurzbeschreibung verfuegbar.",
			"core_rows": _build_scored_rows({}, CORE_ORDER),
			"communication_rows": _build_value_rows({}, COMMUNICATION_ORDER),
			"platform_rows": [],
			"derived_rows": [
				{"label": "Method Tags", "value_text": "n/a"},
				{"label": "Function Scores", "value_text": "n/a"},
				{"label": "Primary Specialty", "value_text": "n/a"},
				{"label": "Secondary Specialty", "value_text": "n/a"},
			],
			"behavior_rows": _build_value_rows({}, BEHAVIOR_ORDER),
		}

	var trait_text: String = _build_expanded_trait_text(profile)

	var short_description: String = String(profile.short_description).strip_edges()
	if short_description.is_empty():
		short_description = _optional_text(String(profile.biography_text), "Keine Kurzbeschreibung hinterlegt.")

	return {
		"name": _optional_text(String(profile.display_name), "Unknown Operator"),
		"trait_text": trait_text,
		"short_description": short_description,
		"core_rows": _build_scored_rows(Dictionary(profile.skill_values), CORE_ORDER),
		"communication_rows": _build_value_rows(Dictionary(profile.communication_values), COMMUNICATION_ORDER),
		"platform_rows": _build_platform_value_rows(Dictionary(profile.platform_values)),
		"derived_rows": [
			{"label": "Method Tags", "value_text": _optional_text(String(profile.method_summary_text), _format_score_summary(Dictionary(profile.method_scores), "n/a"))},
			{"label": "Function Scores", "value_text": _optional_text(String(profile.function_summary_text), _format_score_summary(Dictionary(profile.function_scores), "n/a"))},
			{"label": "Primary Specialty", "value_text": _optional_text(String(profile.primary_specialty), _optional_text(String(profile.specialty_text), "n/a"))},
			{"label": "Secondary Specialty", "value_text": _optional_text(String(profile.secondary_specialty), "n/a")},
		],
		"behavior_rows": _build_value_rows(Dictionary(profile.behavior_axes), BEHAVIOR_ORDER),
	}


static func build_loadout_text_from_member_loadout(member_loadout: Dictionary, fallback: String = "standard kit") -> String:
	if member_loadout.is_empty():
		return fallback
	return build_loadout_text_from_ids(
		String(member_loadout.get("armor", "medium")),
		String(member_loadout.get("weapon_1", member_loadout.get("weapon", "rifle"))),
		String(member_loadout.get("weapon_2", "rifle")),
		fallback
	)


static func build_loadout_text_from_ids(armor_id: String, weapon_1_id: String, weapon_2_id: String, fallback: String = "standard kit") -> String:
	var normalized_armor_id: String = _normalize_armor_id(armor_id)
	var normalized_weapon_1_id: String = _normalize_weapon_id(weapon_1_id)
	var normalized_weapon_2_id: String = _normalize_weapon_id(weapon_2_id)
	if normalized_armor_id.is_empty() and normalized_weapon_1_id.is_empty() and normalized_weapon_2_id.is_empty():
		return fallback
	return "%s Armor | %s | %s" % [
		_normalize_armor_id(normalized_armor_id).capitalize(),
		WEAPON_DATA_SCRIPT.get_display_name(normalized_weapon_1_id),
		WEAPON_DATA_SCRIPT.get_display_name(normalized_weapon_2_id),
	]


static func format_fireteam_label(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges()
	if normalized_fireteam_id.is_empty():
		return "UNASSIGNED"
	return normalized_fireteam_id.replace("_", " ").to_upper()


static func _build_expanded_trait_text(profile) -> String:
	if profile == null:
		return "Keine Traits verfuegbar."

	var trait_names: PackedStringArray = []
	if profile.trait_ids is PackedStringArray:
		for trait_id_variant in profile.trait_ids:
			var unit_trait = UNIT_TRAIT_SCRIPT.from_id(String(trait_id_variant))
			if unit_trait == null:
				continue
			trait_names.append(String(unit_trait.display_name))

	if not trait_names.is_empty():
		return ", ".join(trait_names)

	var trait_text: String = String(profile.trait_summary_text).strip_edges()
	if trait_text.is_empty() and profile.trait_tags is PackedStringArray and not (profile.trait_tags as PackedStringArray).is_empty():
		trait_text = " ".join(profile.trait_tags)
	return _optional_text(trait_text, "Keine markanten Traits hinterlegt.")


static func _build_profile_loadout_text(profile) -> String:
	if profile == null:
		return "standard kit"
	return build_loadout_text_from_ids(
		String(profile.armor_id),
		String(profile.weapon_1_id),
		String(profile.weapon_2_id),
		"standard kit"
	)


static func _normalize_armor_id(armor_id: String) -> String:
	var normalized_armor_id: String = armor_id.strip_edges().to_lower()
	if normalized_armor_id == "light" or normalized_armor_id == "medium" or normalized_armor_id == "heavy":
		return normalized_armor_id
	return "medium"


static func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized_weapon_id: String = weapon_id.strip_edges().to_lower()
	if normalized_weapon_id.is_empty():
		return "rifle"
	return normalized_weapon_id


static func _build_scored_rows(source_values: Dictionary, order: Array) -> Array:
	var rows: Array = []
	for entry in order:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		var value: float = float(source_values.get(key, 0.0))
		rows.append(
			{
				"label": label,
				"value": clampf(value, 0.0, 1.0),
				"value_text": _format_decimal_comma(value),
			}
		)
	return rows


static func _build_platform_rows(platform_values: Dictionary) -> Array:
	var rows: Array = []
	for entry in PLATFORM_ORDER:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		var value: float = float(platform_values.get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
		rows.append(
			{
				"label": label,
				"value_text": "n/a" if value < 0.0 else _format_decimal_comma(value),
			}
		)
	return rows


static func _build_platform_value_rows(platform_values: Dictionary) -> Array:
	var rows: Array = []
	for entry in PLATFORM_ORDER:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		var value: float = float(platform_values.get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
		if value < 0.0:
			continue
		rows.append(
			{
				"label": label,
				"value_text": _format_decimal_comma(value),
			}
		)
	return rows


static func _build_ordered_score_rows(source_values: Dictionary, order: Array) -> Array:
	var rows: Array = []
	for entry in order:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		rows.append(
			{
				"label": label,
				"value": clampf(float(source_values.get(key, 0.0)), 0.0, 1.0),
				"value_text": _format_decimal_comma(float(source_values.get(key, 0.0))),
			}
		)
	return rows


static func _build_value_rows(source_values: Dictionary, order: Array) -> Array:
	var rows: Array = []
	for entry in order:
		var key: String = String(entry[0])
		var label: String = String(entry[1])
		rows.append(
			{
				"label": label,
				"value_text": _format_decimal_comma(float(source_values.get(key, 0.0))),
			}
		)
	return rows


static func _format_score_summary(scores: Dictionary, fallback: String) -> String:
	var normalized_fallback: String = fallback.strip_edges()
	if scores.is_empty():
		return _optional_text(normalized_fallback, "n/a")

	var sorted_keys: Array = scores.keys()
	sorted_keys.sort_custom(func(a, b):
		return float(scores.get(a, 0.0)) > float(scores.get(b, 0.0))
	)
	var summary_parts: PackedStringArray = []
	for key_variant in sorted_keys:
		var key: String = String(key_variant)
		summary_parts.append("%s %s" % [_humanize_key(key), _format_decimal_comma(float(scores.get(key_variant, 0.0)))])
	return " | ".join(summary_parts)


static func _humanize_key(value: String) -> String:
	var normalized: String = value.strip_edges().replace("_", " ")
	if normalized.is_empty():
		return "n/a"
	var parts: PackedStringArray = normalized.split(" ", false)
	for index in range(parts.size()):
		parts[index] = String(parts[index]).capitalize()
	return " ".join(parts)


static func _format_decimal_comma(value: float) -> String:
	return ("%.2f" % clampf(value, 0.0, 1.0)).replace(".", ",")


static func _optional_text(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		return fallback
	return normalized