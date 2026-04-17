class_name UnitRosterPresets
extends RefCounted

const FRIENDLY_ROSTER: Array = [
	{
		"unit_id": "unit_alpha",
		"display_name": "Unit Alpha",
		"team_id": "team_alpha",
		"skill_accuracy": 0.6,
		"skill_speed": 0.4,
		"skill_leadership": 0.2,
		"skill_toughness": 0.5,
		"trait_ids": ["aggressive"],
	},
	{
		"unit_id": "unit_bravo",
		"display_name": "Unit Bravo",
		"team_id": "team_alpha",
		"skill_accuracy": 0.4,
		"skill_speed": 0.6,
		"skill_leadership": 0.3,
		"skill_toughness": 0.4,
		"trait_ids": ["cautious", "steady"],
	},
	{
		"unit_id": "unit_charlie",
		"display_name": "Unit Charlie",
		"team_id": "team_alpha",
		"skill_accuracy": 0.5,
		"skill_speed": 0.5,
		"skill_leadership": 0.6,
		"skill_toughness": 0.6,
		"trait_ids": ["calm"],
	},
]

const ENEMY_DEFAULT_PRESET: Dictionary = {
	"team_id": "team_bravo",
	"skill_accuracy": 0.4,
	"skill_speed": 0.3,
	"skill_leadership": 0.2,
	"skill_toughness": 0.5,
	"trait_ids": [],
}


static func get_homebase_roster() -> Array:
	return FRIENDLY_ROSTER.duplicate(true)


static func get_preset(unit_id: String, team_id: String = "") -> Dictionary:
	for unit_data in FRIENDLY_ROSTER:
		if String(unit_data.get("unit_id", "")) == unit_id:
			return unit_data.duplicate(true)

	if team_id == "team_bravo":
		var enemy_preset: Dictionary = ENEMY_DEFAULT_PRESET.duplicate(true)
		enemy_preset["unit_id"] = unit_id
		enemy_preset["display_name"] = _build_display_name(unit_id)
		return enemy_preset

	return {
		"unit_id": unit_id,
		"display_name": _build_display_name(unit_id),
		"team_id": team_id,
		"skill_accuracy": 0.5,
		"skill_speed": 0.5,
		"skill_leadership": 0.3,
		"skill_toughness": 0.5,
		"trait_ids": [],
	}


static func _build_display_name(unit_id: String) -> String:
	var normalized_id: String = unit_id.strip_edges()
	if normalized_id.is_empty():
		return "Unknown Unit"

	var parts: PackedStringArray = normalized_id.split("_", false)
	for index in range(parts.size()):
		parts[index] = parts[index].capitalize()

	return " ".join(parts)
