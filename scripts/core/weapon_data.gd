extends RefCounted

## Weapon stats registry.
## Maps weapon IDs to combat parameters and visual/loadout metadata.
## Asset paths reference kenney_space-kit isometric weapon sprites.

const DEFAULT_WORLD_UNITS_PER_TILE: float = 72.0

const WEAPON_CATALOG: Dictionary = {
	"none": {
		"id": "none",
		"display_name": "Keine Waffe",
		"damage_per_hit": 0,
		"base_hit_chance": 0.0,
		"ticks_between_attacks": 0,
		"effective_tile_range": 0,
		"effective_range": 0.0,
		"asset_prefix": "",
		"sprite_scale": Vector2(1.0, 1.0),
		"role": "none",
		"preview_path": "",
		"visual_loadout_id": "",
		"weight": 0.0,
	},
	"pistol": {
		"id": "pistol",
		"display_name": "Pistole",
		"damage_per_hit": 18,
		"base_hit_chance": 0.40,
		"ticks_between_attacks": 9,
		"effective_tile_range": 8,
		"effective_range": 140.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_gun",
		"sprite_scale": Vector2(1.0, 1.0),
		"role": "short",
		"preview_path": "res://Assets/used/npc/blaster_kit/previews/blaster-a.png",
		"visual_loadout_id": "standard_rifle",
		"weight": 1.0,
	},
	"smg": {
		"id": "smg",
		"display_name": "Maschinenpistole",
		"damage_per_hit": 25,
		"base_hit_chance": 0.40,
		"ticks_between_attacks": 6,
		"effective_tile_range": 10,
		"effective_range": 140.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_gun",
		"sprite_scale": Vector2(1.0, 1.0),
		"role": "short",
		"preview_path": "res://Assets/used/npc/blaster_kit/previews/blaster-a.png",
		"visual_loadout_id": "standard_rifle",
		"weight": 2.0,
	},
	"rifle": {
		"id": "rifle",
		"display_name": "Sturmgewehr",
		"damage_per_hit": 40,
		"base_hit_chance": 0.45,
		"ticks_between_attacks": 10,
		"effective_tile_range": 25,
		"effective_range": 180.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_rifle",
		"sprite_scale": Vector2(1.0, 1.0),
		"role": "medium",
		"preview_path": "res://Assets/used/npc/blaster_kit/previews/blaster-a.png",
		"visual_loadout_id": "standard_rifle",
		"weight": 3.0,
	},
	"sniper": {
		"id": "sniper",
		"display_name": "Scharfschuetzengewehr",
		"damage_per_hit": 60,
		"base_hit_chance": 0.55,
		"ticks_between_attacks": 18,
		"effective_tile_range": 42,
		"effective_range": 260.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_rifle",
		"sprite_scale": Vector2(1.45, 1.45),
		"role": "long",
		"preview_path": "res://Assets/used/npc/weapon_pack/previews/sniper.png",
		"visual_loadout_id": "sniper_rifle",
		"weight": 4.2,
	},
	"rail_gun": {
		"id": "rail_gun",
		"display_name": "Schienenkanone",
		"damage_per_hit": 70,
		"base_hit_chance": 0.35,
		"ticks_between_attacks": 18,
		"effective_tile_range": 20,
		"effective_range": 260.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_rifle",
		"sprite_scale": Vector2(2.0, 2.0),
		"role": "heavy",
		"preview_path": "res://Assets/used/npc/blaster_kit/previews/blaster-a.png",
		"visual_loadout_id": "heavy_blaster",
		"weight": 4.5,
		"anti_armor": true,
	},
	"rocket_launcher": {
		"id": "rocket_launcher",
		"display_name": "Raketenwerfer",
		"damage_per_hit": 90,
		"base_hit_chance": 0.30,
		"ticks_between_attacks": 26,
		"effective_tile_range": 18,
		"effective_range": 220.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_rifle",
		"sprite_scale": Vector2(1.85, 1.85),
		"role": "heavy",
		"preview_path": "res://Assets/used/npc/weapon_pack/previews/rocketlauncherModern.png",
		"visual_loadout_id": "rocket_launcher",
		"weight": 6.0,
		"anti_armor": true,
	},
	"medictool": {
		"id": "medictool",
		"display_name": "Sanitätswerkzeug",
		"damage_per_hit": 0,
		"base_hit_chance": 0.0,
		"ticks_between_attacks": 0,
		"effective_tile_range": 1,
		"effective_range": 0.0,
		"asset_prefix": "res://Assets/kenney_space-kit/Isometric/weapon_gun",
		"sprite_scale": Vector2(1.0, 1.0),
		"sprite_modulate": Color(1.0, 0.2, 0.2, 1.0),
		"role": "support",
		"preview_path": "res://Assets/used/npc/blaster_kit/previews/blaster-b.png",
		"visual_loadout_id": "medictool_blaster",
		"weight": 1.0,
	},
}

const DEFAULT_WEAPON_ID: String = "rifle"
const SUPPORT_WEAPON_IDS: Array = ["medictool"]
const ANTI_ARMOR_WEAPON_IDS: Array = ["rocket_launcher", "rail_gun"]


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
	return get_effective_world_range(weapon_id)


static func get_effective_tile_range(weapon_id: String) -> int:
	return maxi(int(get_weapon(weapon_id).get("effective_tile_range", 25)), 0)


static func get_effective_world_range(weapon_id: String, terrain_context = null) -> float:
	return float(get_effective_tile_range(weapon_id)) * get_world_units_per_tile(terrain_context)


static func get_world_units_per_tile(terrain_context = null, fallback_world_units_per_tile: float = DEFAULT_WORLD_UNITS_PER_TILE) -> float:
	if terrain_context != null and terrain_context is Object:
		if terrain_context.has_method("grid_to_world"):
			var origin: Vector2 = terrain_context.call("grid_to_world", Vector2i.ZERO)
			var neighbor: Vector2 = terrain_context.call("grid_to_world", Vector2i(1, 0))
			var distance: float = origin.distance_to(neighbor)
			if distance > 0.001:
				return distance
		if terrain_context.has_method("get_tile_size"):
			var tile_size: Dictionary = Dictionary(terrain_context.call("get_tile_size"))
			var half_width: float = maxf(float(tile_size.get("half_width", 0.0)), 0.0)
			var half_height: float = maxf(float(tile_size.get("half_height", 0.0)), 0.0)
			var derived_distance: float = Vector2(half_width, half_height).length()
			if derived_distance > 0.001:
				return derived_distance
	return maxf(fallback_world_units_per_tile, 0.001)


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


static func get_preview_path(weapon_id: String) -> String:
	return String(get_weapon(weapon_id).get("preview_path", "")).strip_edges()


static func get_visual_loadout_id(weapon_id: String) -> String:
	return String(get_weapon(weapon_id).get("visual_loadout_id", "")).strip_edges().to_lower()


static func get_weight(weapon_id: String) -> float:
	return maxf(float(get_weapon(weapon_id).get("weight", 0.0)), 0.0)


static func get_weapon_role(weapon_id: String) -> String:
	return String(get_weapon(weapon_id).get("role", "")).strip_edges().to_lower()


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
	return WEAPON_CATALOG.has(normalized) and not is_support_weapon_id(normalized) and int(WEAPON_CATALOG[normalized].get("damage_per_hit", 0)) > 0


static func is_anti_armor_weapon_id(weapon_id: String) -> bool:
	var normalized: String = _normalize_weapon_id(weapon_id)
	if not WEAPON_CATALOG.has(normalized):
		return false
	return ANTI_ARMOR_WEAPON_IDS.has(normalized) and bool(WEAPON_CATALOG[normalized].get("anti_armor", false)) and is_attack_weapon_id(normalized)


static func get_anti_armor_weapon_ids() -> PackedStringArray:
	return PackedStringArray(ANTI_ARMOR_WEAPON_IDS)


static func is_medic_tool_id(weapon_id: String) -> bool:
	return _normalize_weapon_id(weapon_id) == "medictool"


static func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized: String = weapon_id.strip_edges().to_lower()
	match normalized:
		"none", "no_weapon", "no-weapon", "no weapon", "unarmed", "keine_waffe", "keine-waffe", "keine waffe":
			return "none"
		"special", "sonderwaffe", "schienenkanone":
			return "rail_gun"
		"lmg", "support_lmg", "support-lmg", "support lmg":
			return "rail_gun"
		"medic_tool", "medic-tool", "medic tool":
			return "medictool"
		"assault_rifle", "sturmgewehr":
			return "rifle"
		"sniper_rifle", "sniper-rifle", "sniper rifle", "scharfschuetzengewehr", "praezisionsgewehr":
			return "sniper"
		"rocket", "rocketlauncher", "rocket-launcher", "rocket launcher", "panzerfaust", "raketenwerfer":
			return "rocket_launcher"
		"maschinenpistole", "mp":
			return "smg"
	return normalized
