extends RefCounted

## Weapon stats registry.
## Maps weapon IDs (smg, rifle, rail_gun, medictool) to combat parameters.
## Asset paths reference kenney_space-kit isometric weapon sprites.

const WEAPON_CATALOG: Dictionary = {
	"smg": {
		"id": "smg",
		"display_name": "Maschinenpistole",
		"damage_per_hit": 25,
		"base_hit_chance": 0.40,
		"ticks_between_attacks": 6,
		"effective_range": 140.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_gun",
		"sprite_scale": Vector2(1.0, 1.0),
	},
	"rifle": {
		"id": "rifle",
		"display_name": "Sturmgewehr",
		"damage_per_hit": 40,
		"base_hit_chance": 0.45,
		"ticks_between_attacks": 10,
		"effective_range": 180.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_rifle",
		"sprite_scale": Vector2(1.0, 1.0),
	},
	"rail_gun": {
		"id": "rail_gun",
		"display_name": "Schienenkanone",
		"damage_per_hit": 70,
		"base_hit_chance": 0.35,
		"ticks_between_attacks": 18,
		"effective_range": 260.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_rifle",
		"sprite_scale": Vector2(2.0, 2.0),
	},
	"medictool": {
		"id": "medictool",
		"display_name": "Medictool",
		"damage_per_hit": 0,
		"base_hit_chance": 0.0,
		"ticks_between_attacks": 0,
		"effective_range": 0.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_gun",
		"sprite_scale": Vector2(1.0, 1.0),
		"sprite_modulate": Color(1.0, 0.2, 0.2, 1.0),
	},
}

const DEFAULT_WEAPON_ID: String = "rifle"
const SUPPORT_WEAPON_IDS: Array = ["medictool"]


static func get_weapon(weapon_id: String) -> Dictionary:
	var normalized_id: String = _normalize_weapon_id(weapon_id)
	if WEAPON_CATALOG.has(normalized_id):
		return WEAPON_CATALOG[normalized_id].duplicate(true)
	return WEAPON_CATALOG[DEFAULT_WEAPON_ID].duplicate(true)


static func get_damage_per_hit(weapon_id: String) -> int:
	return int(get_weapon(weapon_id).get("damage_per_hit", 40))


static func get_base_hit_chance(weapon_id: String) -> float:
	return float(get_weapon(weapon_id).get("base_hit_chance", 0.45))


static func get_ticks_between_attacks(weapon_id: String) -> int:
	return int(get_weapon(weapon_id).get("ticks_between_attacks", 10))


static func get_effective_range(weapon_id: String) -> float:
	return float(get_weapon(weapon_id).get("effective_range", 180.0))


static func get_display_name(weapon_id: String) -> String:
	return String(get_weapon(weapon_id).get("display_name", "Sturmgewehr"))


static func get_asset_path(weapon_id: String, direction: String) -> String:
	var weapon: Dictionary = get_weapon(weapon_id)
	var asset_prefix: String = String(weapon.get("asset_prefix", "")).strip_edges()
	if asset_prefix.is_empty():
		return ""
	return "%s_%s.png" % [asset_prefix, direction]


static func get_sprite_scale(weapon_id: String) -> Vector2:
	return Vector2(get_weapon(weapon_id).get("sprite_scale", Vector2(1.0, 1.0)))


static func get_sprite_modulate(weapon_id: String) -> Color:
	return Color(get_weapon(weapon_id).get("sprite_modulate", Color(1.0, 1.0, 1.0, 1.0)))


static func is_valid_weapon_id(weapon_id: String) -> bool:
	return WEAPON_CATALOG.has(_normalize_weapon_id(weapon_id))


static func get_all_weapon_ids() -> PackedStringArray:
	return PackedStringArray(WEAPON_CATALOG.keys())


static func normalize_weapon_id(weapon_id: String) -> String:
	return _normalize_weapon_id(weapon_id)


static func sanitize_weapon_id(weapon_id: String, fallback_weapon_id: String = DEFAULT_WEAPON_ID) -> String:
	var normalized: String = _normalize_weapon_id(weapon_id)
	if WEAPON_CATALOG.has(normalized):
		return normalized
	var fallback_id: String = _normalize_weapon_id(fallback_weapon_id)
	if WEAPON_CATALOG.has(fallback_id):
		return fallback_id
	return DEFAULT_WEAPON_ID


static func is_support_weapon_id(weapon_id: String) -> bool:
	return SUPPORT_WEAPON_IDS.has(_normalize_weapon_id(weapon_id))


static func is_attack_weapon_id(weapon_id: String) -> bool:
	var normalized: String = _normalize_weapon_id(weapon_id)
	return WEAPON_CATALOG.has(normalized) and not is_support_weapon_id(normalized)


static func is_medic_tool_id(weapon_id: String) -> bool:
	return _normalize_weapon_id(weapon_id) == "medictool"


static func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized: String = weapon_id.strip_edges().to_lower()
	match normalized:
		"special", "sonderwaffe", "schienenkanone":
			return "rail_gun"
		"medic_tool", "medic-tool", "medic tool":
			return "medictool"
		"assault_rifle", "sturmgewehr":
			return "rifle"
		"maschinenpistole", "mp":
			return "smg"
	return normalized
