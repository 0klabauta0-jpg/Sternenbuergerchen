class_name CharacterSheetFormatter
extends RefCounted

const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
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
const PLATFORM_ORDER: Array = [
	["ground_vehicle_handling", "Ground"],
	["dropship_piloting", "Dropship"],
	["freighter_piloting", "Freighter"],
	["fighter_piloting", "Fighter"],
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


static func _optional_text(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		return fallback
	return normalized