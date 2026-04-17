class_name UnitTrait
extends RefCounted

const TRAIT_LIBRARY: Dictionary = {
	"aggressive": {
		"display_name": "Aggressiv",
		"short_tag": "AGG",
		"skill_modifiers": {
			"accuracy": 0.1,
			"toughness": -0.1,
		},
	},
	"cautious": {
		"display_name": "Vorsichtig",
		"short_tag": "CAUT",
		"skill_modifiers": {
			"accuracy": -0.05,
			"toughness": 0.1,
			"speed": -0.1,
		},
	},
	"steady": {
		"display_name": "Ruhig",
		"short_tag": "STDY",
		"skill_modifiers": {
			"accuracy": 0.05,
			"speed": 0.05,
		},
	},
	"reckless": {
		"display_name": "Waghalsig",
		"short_tag": "RCKL",
		"skill_modifiers": {
			"speed": 0.15,
			"toughness": -0.15,
		},
	},
	"calm": {
		"display_name": "Gelassen",
		"short_tag": "CALM",
		"skill_modifiers": {
			"leadership": 0.15,
			"accuracy": 0.05,
		},
	},
}

var trait_id: String = ""
var display_name: String = ""
var short_tag: String = ""
var skill_modifiers: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_id(next_trait_id: String):
	var normalized_trait_id: String = next_trait_id.strip_edges().to_lower()
	if not TRAIT_LIBRARY.has(normalized_trait_id):
		return null

	var trait_data: Dictionary = TRAIT_LIBRARY[normalized_trait_id]
	var script_ref: GDScript = load("res://scripts/npc/unit_trait.gd")
	var unit_trait = script_ref.new()
	unit_trait.trait_id = normalized_trait_id
	unit_trait.display_name = String(trait_data.get("display_name", normalized_trait_id.capitalize()))
	unit_trait.short_tag = String(trait_data.get("short_tag", normalized_trait_id.to_upper()))
	unit_trait.skill_modifiers = Dictionary(trait_data.get("skill_modifiers", {})).duplicate(true)
	return unit_trait


func is_valid() -> bool:
	return not trait_id.is_empty() and not display_name.is_empty()


func to_dict() -> Dictionary:
	return {
		"trait_id": trait_id,
		"display_name": display_name,
		"short_tag": short_tag,
		"skill_modifiers": skill_modifiers.duplicate(true),
	}


func apply_to_skills(skills) -> void:
	if skills == null or not skills.has_method("apply_modifier"):
		return

	for skill_name in skill_modifiers.keys():
		var modifier: Variant = skill_modifiers[skill_name]
		if typeof(modifier) != TYPE_INT and typeof(modifier) != TYPE_FLOAT:
			continue

		skills.call("apply_modifier", String(skill_name), float(modifier))


func _apply_dict(data: Dictionary) -> void:
	trait_id = String(data.get("trait_id", ""))
	display_name = String(data.get("display_name", ""))
	short_tag = String(data.get("short_tag", ""))
	skill_modifiers = Dictionary(data.get("skill_modifiers", {})).duplicate(true)
