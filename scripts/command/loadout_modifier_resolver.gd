class_name LoadoutModifierResolver
extends RefCounted

const UNIT_LOADOUT_MODIFIERS_SCRIPT: GDScript = preload("res://scripts/command/unit_loadout_modifiers.gd")

const SECONDARY_WEAPON_WEIGHT: float = 0.5

const WEAPON_FORMULAS: Dictionary = {
	"none": {
		"accuracy_mod": 0.0,
		"speed_mod": 0.0,
		"toughness_mod": 0.0,
		"cover_mod": 0.0,
		"range_class": "none",
		"weight": 0.0,
	},
	"smg": {
		"accuracy_mod": -0.06,
		"speed_mod": 0.12,
		"toughness_mod": 0.0,
		"cover_mod": 0.04,
		"range_class": "short",
		"weight": 2.0,
	},
	"rifle": {
		"accuracy_mod": 0.04,
		"speed_mod": 0.0,
		"toughness_mod": 0.0,
		"cover_mod": 0.02,
		"range_class": "medium",
		"weight": 3.0,
	},
	"sniper": {
		"accuracy_mod": 0.10,
		"speed_mod": -0.06,
		"toughness_mod": -0.02,
		"cover_mod": 0.03,
		"range_class": "long",
		"weight": 4.0,
	},
	"special": {
		"accuracy_mod": 0.02,
		"speed_mod": -0.05,
		"toughness_mod": 0.06,
		"cover_mod": 0.06,
		"range_class": "any",
		"weight": 4.5,
	},
	"rocket_launcher": {
		"accuracy_mod": -0.02,
		"speed_mod": -0.10,
		"toughness_mod": 0.04,
		"cover_mod": 0.05,
		"range_class": "heavy",
		"weight": 5.0,
	},
	"medictool": {
		"accuracy_mod": -0.03,
		"speed_mod": -0.02,
		"toughness_mod": 0.0,
		"cover_mod": 0.0,
		"range_class": "medium",
		"weight": 1.0,
	},
}

const ARMOR_FORMULAS: Dictionary = {
	"light": {
		"speed_mod": 0.15,
		"toughness_mod": -0.08,
		"cover_mod": -0.05,
		"weight": 1.0,
	},
	"medium": {
		"speed_mod": 0.0,
		"toughness_mod": 0.0,
		"cover_mod": 0.0,
		"weight": 2.0,
	},
	"heavy": {
		"speed_mod": -0.14,
		"toughness_mod": 0.15,
		"cover_mod": 0.10,
		"weight": 4.0,
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
	var range_class: String = String(primary_formula.get("range_class", secondary_formula.get("range_class", "medium"))).strip_edges().to_lower()
	if weapon_1_id == "none" and weapon_2_id != "none":
		range_class = String(secondary_formula.get("range_class", "medium")).strip_edges().to_lower()
	return UNIT_LOADOUT_MODIFIERS_SCRIPT.new(
		{
			"unit_id": normalized_unit_id,
			"armor_id": armor_id,
			"weapon_1_id": weapon_1_id,
			"weapon_2_id": weapon_2_id,
			"loadout_weight": _calculate_loadout_weight(armor_formula, primary_formula, secondary_formula),
			"accuracy_mod": float(primary_formula.get("accuracy_mod", 0.0)) + (float(secondary_formula.get("accuracy_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"speed_mod": float(armor_formula.get("speed_mod", 0.0)) + float(primary_formula.get("speed_mod", 0.0)) + (float(secondary_formula.get("speed_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"toughness_mod": float(armor_formula.get("toughness_mod", 0.0)) + float(primary_formula.get("toughness_mod", 0.0)) + (float(secondary_formula.get("toughness_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"cover_mod": float(armor_formula.get("cover_mod", 0.0)) + float(primary_formula.get("cover_mod", 0.0)) + (float(secondary_formula.get("cover_mod", 0.0)) * SECONDARY_WEAPON_WEIGHT),
			"range_class": range_class,
			"metadata": {
				"source": "fob_staging",
				"secondary_weapon_weight": SECONDARY_WEAPON_WEIGHT,
				"weight_breakdown": {
					"armor": float(armor_formula.get("weight", 0.0)),
					"weapon_1": float(primary_formula.get("weight", 0.0)),
					"weapon_2": float(secondary_formula.get("weight", 0.0)),
				},
			},
		}
	)


func calculate_loadout_weight(loadout_data: Dictionary) -> float:
	var armor_id: String = _normalize_armor_id(String(loadout_data.get("armor", loadout_data.get("armor_id", "medium"))))
	var weapon_1_id: String = _normalize_weapon_id(String(loadout_data.get("weapon_1", loadout_data.get("weapon_1_id", "rifle"))))
	var weapon_2_id: String = _normalize_weapon_id(String(loadout_data.get("weapon_2", loadout_data.get("weapon_2_id", weapon_1_id))))
	return _calculate_loadout_weight(_get_armor_formula(armor_id), _get_weapon_formula(weapon_1_id), _get_weapon_formula(weapon_2_id))


func _get_weapon_formula(weapon_id: String) -> Dictionary:
	if WEAPON_FORMULAS.has(weapon_id):
		return Dictionary(WEAPON_FORMULAS[weapon_id]).duplicate(true)
	return Dictionary(WEAPON_FORMULAS["rifle"]).duplicate(true)


func _get_armor_formula(armor_id: String) -> Dictionary:
	if ARMOR_FORMULAS.has(armor_id):
		return Dictionary(ARMOR_FORMULAS[armor_id]).duplicate(true)
	return Dictionary(ARMOR_FORMULAS["medium"]).duplicate(true)


func _calculate_loadout_weight(armor_formula: Dictionary, primary_formula: Dictionary, secondary_formula: Dictionary) -> float:
	return maxf(
		float(armor_formula.get("weight", 0.0)) + float(primary_formula.get("weight", 0.0)) + float(secondary_formula.get("weight", 0.0)),
		0.0
	)


func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized: String = weapon_id.strip_edges().to_lower()
	match normalized:
		"none", "no_weapon", "no-weapon", "no weapon", "unarmed", "keine_waffe", "keine-waffe", "keine waffe":
			return "none"
		"smg":
			return "smg"
		"rifle":
			return "rifle"
		"sniper", "sniper_rifle", "sniper-rifle", "sniper rifle", "scharfschuetzengewehr", "praezisionsgewehr":
			return "sniper"
		"rocket_launcher", "rocket", "rocketlauncher", "rocket-launcher", "rocket launcher", "panzerfaust", "raketenwerfer":
			return "rocket_launcher"
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
