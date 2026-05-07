class_name UnitLoadoutModifiers
extends RefCounted

const RANGE_CLASS_SHORT: String = "short"
const RANGE_CLASS_MEDIUM: String = "medium"
const RANGE_CLASS_LONG: String = "long"
const RANGE_CLASS_HEAVY: String = "heavy"
const RANGE_CLASS_ANY: String = "any"
const RANGE_CLASS_NONE: String = "none"
const ALLOWED_RANGE_CLASSES: PackedStringArray = [
	RANGE_CLASS_SHORT,
	RANGE_CLASS_MEDIUM,
	RANGE_CLASS_LONG,
	RANGE_CLASS_HEAVY,
	RANGE_CLASS_ANY,
	RANGE_CLASS_NONE,
]

var unit_id: String = ""
var armor_id: String = "medium"
var weapon_1_id: String = "rifle"
var weapon_2_id: String = "rifle"
var loadout_weight: float = 0.0
var accuracy_mod: float = 0.0
var speed_mod: float = 0.0
var toughness_mod: float = 0.0
var cover_mod: float = 0.0
var range_class: String = RANGE_CLASS_MEDIUM
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> UnitLoadoutModifiers:
	var script_ref: GDScript = load("res://scripts/command/unit_loadout_modifiers.gd")
	return script_ref.new(data)


static func is_allowed_range_class(value: String) -> bool:
	return ALLOWED_RANGE_CLASSES.has(value)


func is_valid() -> bool:
	if unit_id.is_empty():
		return false

	return is_allowed_range_class(range_class)


func to_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"armor_id": armor_id,
		"weapon_1_id": weapon_1_id,
		"weapon_2_id": weapon_2_id,
		"loadout_weight": loadout_weight,
		"accuracy_mod": accuracy_mod,
		"speed_mod": speed_mod,
		"toughness_mod": toughness_mod,
		"cover_mod": cover_mod,
		"range_class": range_class,
		"metadata": metadata.duplicate(true),
	}


func _apply_dict(data: Dictionary) -> void:
	unit_id = String(data.get("unit_id", "")).strip_edges()
	armor_id = String(data.get("armor_id", "medium")).strip_edges().to_lower()
	weapon_1_id = String(data.get("weapon_1_id", "rifle")).strip_edges().to_lower()
	weapon_2_id = String(data.get("weapon_2_id", "rifle")).strip_edges().to_lower()
	loadout_weight = maxf(float(data.get("loadout_weight", 0.0)), 0.0)
	accuracy_mod = float(data.get("accuracy_mod", 0.0))
	speed_mod = float(data.get("speed_mod", 0.0))
	toughness_mod = float(data.get("toughness_mod", 0.0))
	cover_mod = float(data.get("cover_mod", 0.0))
	range_class = String(data.get("range_class", RANGE_CLASS_MEDIUM)).strip_edges().to_lower()
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)
