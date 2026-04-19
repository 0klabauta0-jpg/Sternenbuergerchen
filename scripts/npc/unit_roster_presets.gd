class_name UnitRosterPresets
extends RefCounted

const HOMEBASE_TEAM_CAPACITY: int = 3
const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")

const FRIENDLY_ROSTER: Array = [
	{
		"unit_id": "unit_alpha",
		"display_name": "Anja Voss",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_22_42.png",
		"callsign": "ROOK",
		"role_name": "Field Captain",
		"specialty_text": "Small-unit command and breach timing",
		"homeworld": "Bastion-7",
		"age_years": 34,
		"biography_text": "Former dock security lead who rebuilt a scattered relief squad into a disciplined boarding cell.",
		"loadout_summary": "Command carbine, breaching charges, uplink slate",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.6,
		"skill_speed": 0.4,
		"skill_leadership": 0.7,
		"skill_toughness": 0.5,
		"trait_ids": ["calm", "steady"],
	},
	{
		"unit_id": "unit_bravo",
		"display_name": "Milo Saren",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_30_03.png",
		"callsign": "PATCH",
		"role_name": "Combat Medic",
		"specialty_text": "Trauma stabilization under fire",
		"homeworld": "Iona Station",
		"age_years": 29,
		"biography_text": "Keeps pressure off the commander by making impossible casualty windows survivable.",
		"loadout_summary": "Medical rig, injector pack, compact SMG",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.4,
		"skill_speed": 0.6,
		"skill_leadership": 0.3,
		"skill_toughness": 0.6,
		"trait_ids": ["cautious", "steady"],
	},
	{
		"unit_id": "unit_charlie",
		"display_name": "Leona Rhee",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_31_30.png",
		"callsign": "QUILL",
		"role_name": "Recon Scout",
		"specialty_text": "Route scouting and silent overwatch",
		"homeworld": "Khepri Belt",
		"age_years": 27,
		"biography_text": "Reads movement lanes faster than nav software and rarely wastes a step.",
		"loadout_summary": "Scout rifle, sensor darts, soft-sole recon kit",
		"team_id": "team_alpha",
		"fireteam_id": "gold",
		"skill_accuracy": 0.5,
		"skill_speed": 0.7,
		"skill_leadership": 0.6,
		"skill_toughness": 0.5,
		"trait_ids": ["calm"],
	},
	{
		"unit_id": "unit_delta",
		"display_name": "Darius Holt",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_33_24.png",
		"callsign": "RAM",
		"role_name": "Breacher",
		"specialty_text": "Close-entry shock actions",
		"homeworld": "Nadir Colony",
		"age_years": 32,
		"biography_text": "First through every pressure hatch, happiest when the plan gets loud and fast.",
		"loadout_summary": "Shotgun, blast wedges, shielded cutter",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.5,
		"skill_speed": 0.6,
		"skill_leadership": 0.2,
		"skill_toughness": 0.7,
		"trait_ids": ["aggressive", "reckless"],
	},
	{
		"unit_id": "unit_echo",
		"display_name": "Talia Mercer",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_34_25.png",
		"callsign": "VOX",
		"role_name": "Comms Specialist",
		"specialty_text": "Encrypted relay and threat calls",
		"homeworld": "Meridian Array",
		"age_years": 30,
		"biography_text": "Keeps fractured teams sounding coherent even when the channel is saturated with panic.",
		"loadout_summary": "Burst carbine, relay pack, spectrum decryptor",
		"team_id": "team_alpha",
		"fireteam_id": "gold",
		"skill_accuracy": 0.4,
		"skill_speed": 0.5,
		"skill_leadership": 0.7,
		"skill_toughness": 0.4,
		"trait_ids": ["calm", "cautious"],
	},
	{
		"unit_id": "unit_foxtrot",
		"display_name": "Kenzo Vale",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_37_07.png",
		"callsign": "NEEDLE",
		"role_name": "Marksman",
		"specialty_text": "Precision picks and lane denial",
		"homeworld": "Rimehold",
		"age_years": 38,
		"biography_text": "A patient trigger on bad ice worlds taught him to treat every shot like a vote.",
		"loadout_summary": "Long rifle, thermal sight, wind-tag rounds",
		"team_id": "team_alpha",
		"fireteam_id": "gold",
		"skill_accuracy": 0.8,
		"skill_speed": 0.4,
		"skill_leadership": 0.3,
		"skill_toughness": 0.4,
		"trait_ids": ["steady", "cautious"],
	},
	{
		"unit_id": "unit_golf",
		"display_name": "Sabine Orlov",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_41_47.png",
		"callsign": "TORCH",
		"role_name": "Combat Engineer",
		"specialty_text": "Field repair and breach routing",
		"homeworld": "Volkov Reach",
		"age_years": 36,
		"biography_text": "Can turn a cargo manifold or broken rover hull into cover before the shooting peaks.",
		"loadout_summary": "Tool harness, cutter drone, compact repeater",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.4,
		"skill_speed": 0.5,
		"skill_leadership": 0.4,
		"skill_toughness": 0.7,
		"trait_ids": ["steady", "calm"],
	},
	{
		"unit_id": "unit_hotel",
		"display_name": "Idris Kane",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_42_41.png",
		"callsign": "MASTIFF",
		"role_name": "Heavy Gunner",
		"specialty_text": "Suppression and anchor fire",
		"homeworld": "Cinder Basin",
		"age_years": 41,
		"biography_text": "Keeps lanes shut long enough for everyone else to make better decisions.",
		"loadout_summary": "Heavy LMG, ammo sled, recoil brace",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.5,
		"skill_speed": 0.3,
		"skill_leadership": 0.4,
		"skill_toughness": 0.8,
		"trait_ids": ["aggressive", "steady"],
	},
	{
		"unit_id": "unit_india",
		"display_name": "Nika Sol",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_43_50.png",
		"callsign": "GLINT",
		"role_name": "Drone Handler",
		"specialty_text": "Remote scout and micro-surveillance",
		"homeworld": "Solaris Verge",
		"age_years": 25,
		"biography_text": "Treats every blind corner like an engineering problem that should already be solved.",
		"loadout_summary": "Observation drone rack, light pistol, signal mesh",
		"team_id": "team_alpha",
		"fireteam_id": "gold",
		"skill_accuracy": 0.4,
		"skill_speed": 0.6,
		"skill_leadership": 0.4,
		"skill_toughness": 0.4,
		"trait_ids": ["calm", "reckless"],
	},
	{
		"unit_id": "unit_juliet",
		"display_name": "Pavel Dorn",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_46_53.png",
		"callsign": "LATCH",
		"role_name": "Quartermaster",
		"specialty_text": "Supply timing and fallback kits",
		"homeworld": "Anchor Nine",
		"age_years": 33,
		"biography_text": "Knows which team collapses first when supplies look fine on paper but wrong in the field.",
		"loadout_summary": "Utility SMG, field caches, sealant packs",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.4,
		"skill_speed": 0.4,
		"skill_leadership": 0.6,
		"skill_toughness": 0.5,
		"trait_ids": ["cautious", "calm"],
	},
	{
		"unit_id": "unit_kilo",
		"display_name": "Yasmin Arendt",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_49_28.png",
		"callsign": "CIPHER",
		"role_name": "Signals Analyst",
		"specialty_text": "Intercept triage and pattern reading",
		"homeworld": "Helios Relay",
		"age_years": 31,
		"biography_text": "Builds confidence by finding the lie in hostile traffic before anyone else hears it.",
		"loadout_summary": "Signal tablet, sidearm, burst antenna pack",
		"team_id": "team_alpha",
		"fireteam_id": "gold",
		"skill_accuracy": 0.5,
		"skill_speed": 0.4,
		"skill_leadership": 0.6,
		"skill_toughness": 0.4,
		"trait_ids": ["steady", "calm"],
	},
	{
		"unit_id": "unit_lima",
		"display_name": "Tomas Ibarra",
		"portrait_path": "res://Assets/Char/Use AI Image Apr 5, 2026, 22_54_19.png",
		"callsign": "WAKE",
		"role_name": "Rover Pilot",
		"specialty_text": "Extraction timing and route collapse",
		"homeworld": "Dustfall",
		"age_years": 37,
		"biography_text": "Measures plans by whether he can still get everyone home when the map starts lying.",
		"loadout_summary": "Vehicle rig, machine pistol, emergency tow kit",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"skill_accuracy": 0.4,
		"skill_speed": 0.7,
		"skill_leadership": 0.5,
		"skill_toughness": 0.5,
		"trait_ids": ["reckless", "steady"],
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
	var roster: Array = []
	for unit_data in FRIENDLY_ROSTER:
		roster.append(_with_extended_identity(unit_data))
	return roster


static func get_homebase_team_capacity() -> int:
	return HOMEBASE_TEAM_CAPACITY


static func get_default_homebase_selection() -> PackedStringArray:
	return PackedStringArray(["unit_alpha", "unit_bravo"])


static func get_preset(unit_id: String, team_id: String = "") -> Dictionary:
	for unit_data in FRIENDLY_ROSTER:
		if String(unit_data.get("unit_id", "")) == unit_id:
			return _with_extended_identity(unit_data)

	if team_id == "team_bravo":
		var enemy_preset: Dictionary = ENEMY_DEFAULT_PRESET.duplicate(true)
		enemy_preset["unit_id"] = unit_id
		enemy_preset["display_name"] = _build_display_name(unit_id)
		return _with_extended_identity(enemy_preset)

	return _with_extended_identity(
		{
		"unit_id": unit_id,
		"display_name": _build_display_name(unit_id),
		"portrait_path": "",
		"callsign": unit_id.to_upper(),
		"role_name": "Operator",
		"specialty_text": "General duty",
		"homeworld": "Unknown",
		"age_years": 0,
		"biography_text": "No biography recorded.",
		"loadout_summary": "Standard kit",
		"team_id": team_id,
		"fireteam_id": "",
		"skill_accuracy": 0.5,
		"skill_speed": 0.5,
		"skill_leadership": 0.3,
		"skill_toughness": 0.5,
		"trait_ids": [],
		}
	)


static func _with_extended_identity(unit_data: Dictionary) -> Dictionary:
	var enriched: Dictionary = unit_data.duplicate(true)
	if not enriched.has("role_id"):
		enriched["role_id"] = UNIT_PROFILE_MATH_SCRIPT.normalize_role_id(String(enriched.get("role_name", "security_guard")))
	if not enriched.has("short_description"):
		var biography_text: String = String(enriched.get("biography_text", "")).strip_edges()
		if not biography_text.is_empty():
			var parts: PackedStringArray = biography_text.split(".", false)
			if not parts.is_empty():
				enriched["short_description"] = "%s." % String(parts[0]).strip_edges()
	if not enriched.has("callsign"):
		enriched["callsign"] = ""
	if not enriched.has("portrait_path"):
		enriched["portrait_path"] = ""
	return enriched


static func _build_display_name(unit_id: String) -> String:
	var normalized_id: String = unit_id.strip_edges()
	if normalized_id.is_empty():
		return "Unknown Unit"

	var parts: PackedStringArray = normalized_id.split("_", false)
	for index in range(parts.size()):
		parts[index] = parts[index].capitalize()

	return " ".join(parts)
