class_name LoadoutContract
extends RefCounted

const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")

const DEFAULT_ARMOR_ID := "medium"
const DEFAULT_PRIMARY_WEAPON_ID := "rifle"
const DEFAULT_SECONDARY_WEAPON_ID := "none"
const DEFAULT_FOB_WEAPON_ID := "smg"

const ARMOR_IDS: Array = ["light", "medium", "heavy"]
const HOMEBASE_PRIMARY_WEAPON_IDS: Array = ["smg", "rifle", "sniper", "rail_gun", "rocket_launcher", "medictool"]
const HOMEBASE_SECONDARY_WEAPON_IDS: Array = ["none", "smg", "rifle", "sniper", "rail_gun", "rocket_launcher", "medictool"]
const FOB_WEAPON_IDS: Array = ["smg", "rifle", "sniper", "rail_gun", "rocket_launcher", "medictool", "none"]

const ARMOR_LABELS: Dictionary = {
	"light": "Light",
	"medium": "Medium",
	"heavy": "Heavy",
}

const COMPACT_ARMOR_LABELS: Dictionary = {
	"light": "L",
	"medium": "M",
	"heavy": "H",
}

const WEAPON_LABELS: Dictionary = {
	"none": "None",
	"smg": "SMG",
	"rifle": "Rifle",
	"sniper": "Sniper",
	"rail_gun": "Railgun",
	"rocket_launcher": "Rocket",
	"medictool": "Medictool",
}

const COMPACT_WEAPON_LABELS: Dictionary = {
	"none": "-",
	"smg": "SMG",
	"rifle": "Rifle",
	"sniper": "Snip",
	"rail_gun": "Rail",
	"rocket_launcher": "Rkt",
	"medictool": "Med",
}


static func normalize_armor_id(value: String, fallback: String = DEFAULT_ARMOR_ID) -> String:
	var fallback_id: String = _normalize_armor_fallback(fallback)
	var normalized_value: String = value.strip_edges().to_lower()
	match normalized_value:
		"standard", "std", "default":
			return fallback_id
		"light", "medium", "heavy":
			return normalized_value
		_:
			return fallback_id


static func normalize_weapon_id(value: String, fallback: String = DEFAULT_PRIMARY_WEAPON_ID) -> String:
	var fallback_id: String = String(WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", fallback, DEFAULT_PRIMARY_WEAPON_ID))
	var normalized_value: String = value.strip_edges()
	if normalized_value.is_empty():
		return fallback_id
	return String(WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", normalized_value, fallback_id))


static func normalize_balance_weapon_id(value: String, fallback: String = DEFAULT_PRIMARY_WEAPON_ID) -> String:
	var canonical_id: String = normalize_weapon_id(value, fallback)
	# The resolver still owns a legacy balance formula called "special"; the public loadout contract stays on WeaponData's canonical "rail_gun".
	if canonical_id == "rail_gun":
		return "special"
	return canonical_id


static func make_member_loadout(
	armor_id: String,
	weapon_1_id: String,
	weapon_2_id: String,
	default_armor_id: String = DEFAULT_ARMOR_ID,
	default_weapon_1_id: String = DEFAULT_PRIMARY_WEAPON_ID,
	default_weapon_2_id: String = DEFAULT_SECONDARY_WEAPON_ID
) -> Dictionary:
	return {
		"armor": normalize_armor_id(armor_id, default_armor_id),
		"weapon_1": normalize_weapon_id(weapon_1_id, default_weapon_1_id),
		"weapon_2": normalize_weapon_id(weapon_2_id, default_weapon_2_id),
	}


static func normalize_member_loadout(
	loadout_variant: Variant,
	default_armor_id: String = DEFAULT_ARMOR_ID,
	default_weapon_1_id: String = DEFAULT_PRIMARY_WEAPON_ID,
	default_weapon_2_id: String = DEFAULT_SECONDARY_WEAPON_ID
) -> Dictionary:
	var loadout: Dictionary = loadout_variant if typeof(loadout_variant) == TYPE_DICTIONARY else {}
	return make_member_loadout(
		String(loadout.get("armor", loadout.get("armor_id", loadout.get("kit", loadout.get("loadout", default_armor_id))))),
		String(loadout.get("weapon_1", loadout.get("weapon_1_id", loadout.get("primary", loadout.get("weapon", default_weapon_1_id))))),
		String(loadout.get("weapon_2", loadout.get("weapon_2_id", loadout.get("secondary", loadout.get("sidearm", default_weapon_2_id)))))
	)


static func get_armor_ids() -> Array:
	return ARMOR_IDS.duplicate()


static func get_homebase_primary_weapon_ids() -> Array:
	return HOMEBASE_PRIMARY_WEAPON_IDS.duplicate()


static func get_homebase_secondary_weapon_ids() -> Array:
	return HOMEBASE_SECONDARY_WEAPON_IDS.duplicate()


static func get_fob_weapon_ids() -> Array:
	return FOB_WEAPON_IDS.duplicate()


static func get_compact_armor_options() -> Array:
	var result: Array = []
	for armor_id in ARMOR_IDS:
		result.append({"id": armor_id, "label": get_compact_armor_label(String(armor_id))})
	return result


static func get_fob_weapon_options() -> Array:
	return _build_weapon_options(FOB_WEAPON_IDS)


static func get_homebase_primary_weapon_options() -> Array:
	return _build_weapon_options(HOMEBASE_PRIMARY_WEAPON_IDS)


static func get_homebase_secondary_weapon_options() -> Array:
	return _build_weapon_options(HOMEBASE_SECONDARY_WEAPON_IDS)


static func get_armor_label(armor_id: String) -> String:
	var normalized_id: String = normalize_armor_id(armor_id)
	return String(ARMOR_LABELS.get(normalized_id, normalized_id.capitalize()))


static func get_compact_armor_label(armor_id: String) -> String:
	var normalized_id: String = normalize_armor_id(armor_id)
	return String(COMPACT_ARMOR_LABELS.get(normalized_id, normalized_id.capitalize()))


static func get_weapon_label(weapon_id: String) -> String:
	var normalized_id: String = normalize_weapon_id(weapon_id)
	return String(WEAPON_LABELS.get(normalized_id, String(WEAPON_DATA_SCRIPT.call("get_display_name", normalized_id))))


static func get_compact_weapon_label(weapon_id: String) -> String:
	var normalized_id: String = normalize_weapon_id(weapon_id)
	return String(COMPACT_WEAPON_LABELS.get(normalized_id, get_weapon_label(normalized_id)))


static func _build_weapon_options(weapon_ids: Array) -> Array:
	var result: Array = []
	for weapon_id_variant in weapon_ids:
		var weapon_id: String = normalize_weapon_id(String(weapon_id_variant))
		result.append({"id": weapon_id, "label": get_weapon_label(weapon_id)})
	return result


static func _normalize_armor_fallback(fallback: String) -> String:
	var normalized_fallback: String = fallback.strip_edges().to_lower()
	if ARMOR_IDS.has(normalized_fallback):
		return normalized_fallback
	return DEFAULT_ARMOR_ID
