class_name MetaUnitProfile
extends RefCounted

var unit_id: String = ""
var display_name: String = ""
var portrait_path: String = ""
var callsign: String = ""
var role_id: String = ""
var role_name: String = ""
var specialty_text: String = ""
var primary_specialty: String = ""
var secondary_specialty: String = ""
var short_description: String = ""
var homeworld: String = ""
var age_years: int = 0
var biography_text: String = ""
var loadout_summary: String = ""
var armor_id: String = "medium"
var weapon_1_id: String = "rifle"
var weapon_2_id: String = "rifle"
var team_id: String = ""
var fireteam_id: String = ""
var skill_values: Dictionary = {}
var skill_summary_text: String = ""
var communication_values: Dictionary = {}
var platform_values: Dictionary = {}
var behavior_axes: Dictionary = {}
var method_scores: Dictionary = {}
var function_scores: Dictionary = {}
var method_summary_text: String = ""
var function_summary_text: String = ""
var combat_effect_summary_text: String = ""
var trait_ids: PackedStringArray = []
var trait_tags: PackedStringArray = []
var trait_summary_text: String = ""
var status_text: String = ""
var secondary_text: String = ""


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary):
	var script_ref: GDScript = load("res://scripts/meta/meta_unit_profile.gd")
	return script_ref.new(data)


func is_valid() -> bool:
	return not unit_id.is_empty()


func to_dict() -> Dictionary:
	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"portrait_path": portrait_path,
		"callsign": callsign,
		"role_id": role_id,
		"role_name": role_name,
		"specialty_text": specialty_text,
		"primary_specialty": primary_specialty,
		"secondary_specialty": secondary_specialty,
		"short_description": short_description,
		"homeworld": homeworld,
		"age_years": age_years,
		"biography_text": biography_text,
		"loadout_summary": loadout_summary,
		"armor_id": armor_id,
		"weapon_1_id": weapon_1_id,
		"weapon_2_id": weapon_2_id,
		"team_id": team_id,
		"fireteam_id": fireteam_id,
		"skill_values": skill_values.duplicate(true),
		"skill_summary_text": skill_summary_text,
		"communication_values": communication_values.duplicate(true),
		"platform_values": platform_values.duplicate(true),
		"behavior_axes": behavior_axes.duplicate(true),
		"method_scores": method_scores.duplicate(true),
		"function_scores": function_scores.duplicate(true),
		"method_summary_text": method_summary_text,
		"function_summary_text": function_summary_text,
		"combat_effect_summary_text": combat_effect_summary_text,
		"trait_ids": trait_ids.duplicate(),
		"trait_tags": trait_tags.duplicate(),
		"trait_summary_text": trait_summary_text,
		"status_text": status_text,
		"secondary_text": secondary_text,
	}


func duplicate_profile():
	var script_ref: GDScript = load("res://scripts/meta/meta_unit_profile.gd")
	return script_ref.new(to_dict())


func _apply_dict(data: Dictionary) -> void:
	unit_id = String(data.get("unit_id", "")).strip_edges()
	display_name = String(data.get("display_name", unit_id)).strip_edges()
	portrait_path = String(data.get("portrait_path", "")).strip_edges()
	callsign = String(data.get("callsign", "")).strip_edges()
	role_id = String(data.get("role_id", "")).strip_edges().to_lower()
	role_name = String(data.get("role_name", "")).strip_edges()
	specialty_text = String(data.get("specialty_text", "")).strip_edges()
	primary_specialty = String(data.get("primary_specialty", specialty_text)).strip_edges()
	secondary_specialty = String(data.get("secondary_specialty", "")).strip_edges()
	short_description = String(data.get("short_description", "")).strip_edges()
	homeworld = String(data.get("homeworld", "")).strip_edges()
	age_years = int(data.get("age_years", 0))
	biography_text = String(data.get("biography_text", "")).strip_edges()
	loadout_summary = String(data.get("loadout_summary", "")).strip_edges()
	armor_id = String(data.get("armor_id", "medium")).strip_edges().to_lower()
	weapon_1_id = String(data.get("weapon_1_id", "rifle")).strip_edges().to_lower()
	weapon_2_id = String(data.get("weapon_2_id", "rifle")).strip_edges().to_lower()
	team_id = String(data.get("team_id", "")).strip_edges()
	fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	skill_values = Dictionary(data.get("skill_values", {})).duplicate(true)
	skill_summary_text = String(data.get("skill_summary_text", "")).strip_edges()
	communication_values = Dictionary(data.get("communication_values", {})).duplicate(true)
	platform_values = Dictionary(data.get("platform_values", {})).duplicate(true)
	behavior_axes = Dictionary(data.get("behavior_axes", {})).duplicate(true)
	method_scores = Dictionary(data.get("method_scores", {})).duplicate(true)
	function_scores = Dictionary(data.get("function_scores", {})).duplicate(true)
	method_summary_text = String(data.get("method_summary_text", "")).strip_edges()
	function_summary_text = String(data.get("function_summary_text", "")).strip_edges()
	combat_effect_summary_text = String(data.get("combat_effect_summary_text", "")).strip_edges()
	trait_ids = _coerce_string_array(data.get("trait_ids", []))
	trait_tags = _coerce_string_array(data.get("trait_tags", []))
	trait_summary_text = String(data.get("trait_summary_text", "")).strip_edges()
	status_text = String(data.get("status_text", "")).strip_edges()
	secondary_text = String(data.get("secondary_text", "")).strip_edges()

	if display_name.is_empty():
		display_name = unit_id

	if trait_summary_text.is_empty() and not trait_tags.is_empty():
		trait_summary_text = " ".join(trait_tags)

	if specialty_text.is_empty():
		specialty_text = primary_specialty


func _coerce_string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()

	var result: PackedStringArray = []
	if value is Array:
		for entry in value:
			var text: String = String(entry).strip_edges()
			if text.is_empty():
				continue

			result.append(text)

	return result