class_name LoadoutModifierResolver
extends RefCounted

const UNIT_LOADOUT_MODIFIERS_SCRIPT: GDScript = preload("res://scripts/command/unit_loadout_modifiers.gd")

const SECONDARY_WEAPON_WEIGHT: float = 0.5

const WEAPON_FORMULAS: Dictionary = {
	"smg": {
		"accuracy_mod": -0.06,
		"speed_mod": 0.12,
		"toughness_mod": 0.0,
		"cover_mod": 0.04,
		"range_class": "short",
	},
	"rifle": {
		"accuracy_mod": 0.04,
		"speed_mod": 0.0,
		"toughness_mod": 0.0,
		"cover_mod": 0.02,
		"range_class": "medium",
	},
	"special": {
		"accuracy_mod": 0.02,
		"speed_mod": -0.05,
		"toughness_mod": 0.06,
		"cover_mod": 0.06,
		"range_class": "any",
	},
	"medictool": {
		"accuracy_mod": -0.03,
		"speed_mod": -0.02,
		"toughness_mod": 0.0,
		"cover_mod": 0.0,
		"range_class": "medium",
	},
}

const ARMOR_FORMULAS: Dictionary = {
	"light": {
		"speed_mod": 0.15,
		"toughness_mod": -0.08,
		"cover_mod": -0.05,
	},
	"medium": {
		"speed_mod": 0.0,
		"toughness_mod": 0.0,
		"cover_mod": 0.0,
	},
	"heavy": {
		"speed_mod": -0.14,
		"toughness_mod": 0.15,
		"cover_mod": 0.10,
	},
}


func resolve_for_member_loadouts(member_loadouts: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in member_loadouts.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var loadout_data: Dictionary = Dictionary(member_loadouts.get(unit_id_variant, {})).duplicate(true)
		var modifiers = resolve_for_unit(unit_id, loadout_data)
		if modifiers != null and modifiers.has_method("is_valid") and bool(modifiers.call("is_valid")):
			result[unit_id] = modifiers.call("to_dict")
	return result


func resolve_for_unit(unit_id: String, loadout_data: Dictionary):
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return null
	var armor_id: String = _normalize_armor_id(String(loadout_data.get("armor", loadout_data.get("armor_id", "medium"))))
	var weapon_1_id: String = _normalize_weapon_id(String(loadout_data.get("weapon_1", loadout_data.get("weapon_1_id", "rifle"))))
	var weapon_2_id: String = _normalize_weapon_id(String(loadout_data.get("weapon_2", loadout_data.get("weapon_2_id", weapon_1_id))))
	var primary_formula: Dictionary = _get_weapon_formula(weapon_1_id)
	var secondary_formula: Dictionary = _get_weapon_formula(weapon_2_id)
	var armor_formula: Dictionary = _get_armor_formula(armor_id)
	return UNIT_LOADOUT_MODIFIERS_SCRIPT.new(
		{
			"unit_id": normalized_unit_id,
			"armor_id": armor_id,
			"weapon_1_id": weapon_1_id,
			"weapon_2_id": weapon_2_id,
			"accuracy_mod": float(primary_formula.get("accuracy_mod", 0.0)) + (float(secondary_formula.get("accuracy_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"speed_mod": float(armor_formula.get("speed_mod", 0.0)) + float(primary_formula.get("speed_mod", 0.0)) + (float(secondary_formula.get("speed_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"toughness_mod": float(armor_formula.get("toughness_mod", 0.0)) + float(primary_formula.get("toughness_mod", 0.0)) + (float(secondary_formula.get("toughness_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"cover_mod": float(armor_formula.get("cover_mod", 0.0)) + float(primary_formula.get("cover_mod", 0.0)) + (float(secondary_formula.get("cover_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"range_class": String(primary_formula.get("range_class", secondary_formula.get("range_class", "medium"))).strip_edges().to_lower(),
			"metadata": {
				"source": "fob_staging",
				"secondary_weapon_weight": SECONDARY_WEAPON_WEIGHT,
			},
		}
	)


func _get_weapon_formula(weapon_id: String) -> Dictionary:
	if WEAPON_FORMULAS.has(weapon_id):
		return Dictionary(WEAPON_FORMULAS[weapon_id]).duplicate(true)
	return Dictionary(WEAPON_FORMULAS["rifle"]).duplicate(true)


func _get_armor_formula(armor_id: String) -> Dictionary:
	if ARMOR_FORMULAS.has(armor_id):
		return Dictionary(ARMOR_FORMULAS[armor_id]).duplicate(true)
	return Dictionary(ARMOR_FORMULAS["medium"]).duplicate(true)


func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized: String = weapon_id.strip_edges().to_lower()
	match normalized:
		"smg":
			return "smg"
		"rifle":
			return "rifle"
		"medictool", "medic_tool", "medic-tool":
			return "medictool"
		"special", "rail_gun", "sonderwaffe":
			return "special"
		_:
			return "rifle"


func _normalize_armor_id(armor_id: String) -> String:
	var normalized: String = armor_id.strip_edges().to_lower()
	match normalized:
		"light", "medium", "heavy":
			return normalized
		_:
			return "medium"
