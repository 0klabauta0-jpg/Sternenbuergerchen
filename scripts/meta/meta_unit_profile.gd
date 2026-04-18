class_name MetaUnitProfile
extends RefCounted

var unit_id: String = ""
var display_name: String = ""
var portrait_path: String = ""
var callsign: String = ""
var role_name: String = ""
var specialty_text: String = ""
var homeworld: String = ""
var age_years: int = 0
var biography_text: String = ""
var loadout_summary: String = ""
var team_id: String = ""
var fireteam_id: String = ""
var skill_values: Dictionary = {}
var skill_summary_text: String = ""
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
		"role_name": role_name,
		"specialty_text": specialty_text,
		"homeworld": homeworld,
		"age_years": age_years,
		"biography_text": biography_text,
		"loadout_summary": loadout_summary,
		"team_id": team_id,
		"fireteam_id": fireteam_id,
		"skill_values": skill_values.duplicate(true),
		"skill_summary_text": skill_summary_text,
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
	role_name = String(data.get("role_name", "")).strip_edges()
	specialty_text = String(data.get("specialty_text", "")).strip_edges()
	homeworld = String(data.get("homeworld", "")).strip_edges()
	age_years = int(data.get("age_years", 0))
	biography_text = String(data.get("biography_text", "")).strip_edges()
	loadout_summary = String(data.get("loadout_summary", "")).strip_edges()
	team_id = String(data.get("team_id", "")).strip_edges()
	fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	skill_values = Dictionary(data.get("skill_values", {})).duplicate(true)
	skill_summary_text = String(data.get("skill_summary_text", "")).strip_edges()
	trait_ids = _coerce_string_array(data.get("trait_ids", []))
	trait_tags = _coerce_string_array(data.get("trait_tags", []))
	trait_summary_text = String(data.get("trait_summary_text", "")).strip_edges()
	status_text = String(data.get("status_text", "")).strip_edges()
	secondary_text = String(data.get("secondary_text", "")).strip_edges()

	if display_name.is_empty():
		display_name = unit_id

	if trait_summary_text.is_empty() and not trait_tags.is_empty():
		trait_summary_text = " ".join(trait_tags)


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