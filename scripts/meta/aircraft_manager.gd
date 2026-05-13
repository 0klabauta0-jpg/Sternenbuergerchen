class_name AircraftManager
extends RefCounted

const DEFAULT_DROPSHIP_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png"
const DEFAULT_CARGO_TEXTURE_PATH := "res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png"

var _aircraft_definitions: Array = []
var _assigned_pilot_by_craft: Dictionary = {}
var _aircraft_location_by_craft: Dictionary = {}
var _selected_cargo_by_craft: Dictionary = {}
var _loaded_cargo_by_craft: Dictionary = {}
var _pilot_transfer_entries: Array = []
var _cargo_load_entries: Array = []
var _selected_aircraft_id: String = ""


func set_transport_state(
	aircraft_definitions: Array,
	assigned_pilot_by_craft: Dictionary,
	pilot_transfer_entries: Array,
	aircraft_location_by_craft: Dictionary = {},
	selected_cargo_by_craft: Dictionary = {},
	loaded_cargo_by_craft: Dictionary = {},
	cargo_load_entries: Array = []
) -> void:
	_aircraft_definitions = aircraft_definitions.duplicate(true)
	_assigned_pilot_by_craft = assigned_pilot_by_craft.duplicate(true)
	_pilot_transfer_entries = pilot_transfer_entries.duplicate(true)
	_aircraft_location_by_craft = aircraft_location_by_craft.duplicate(true)
	_selected_cargo_by_craft = selected_cargo_by_craft.duplicate(true)
	_loaded_cargo_by_craft = loaded_cargo_by_craft.duplicate(true)
	_cargo_load_entries = cargo_load_entries.duplicate(true)
	ensure_selected_aircraft_id()


func build_default_aircraft_definitions() -> Array:
	return [
		{
			"craft_id": "dropship_template",
			"craft_type": "dropship",
			"display_name": "Dropship",
			"summary": "Single-pilot shuttle for the FOB corridor.",
			"texture_path": DEFAULT_DROPSHIP_TEXTURE_PATH,
			"supports_cargo": false,
			"cargo_options": [],
		},
		{
			"craft_id": "craft_cargoB_template",
			"craft_type": "craft_cargoB",
			"display_name": "Frachter",
			"summary": "Cargo freighter for Rover-sized payloads.",
			"texture_path": DEFAULT_CARGO_TEXTURE_PATH,
			"supports_cargo": true,
			"cargo_options": [
				{"cargo_id": "", "display_name": "No Cargo"},
				{"cargo_id": "rover", "display_name": "Rover"},
			],
		},
	]


func get_aircraft_definitions() -> Array:
	return _aircraft_definitions.duplicate(true)


func get_assigned_pilot_map() -> Dictionary:
	return _assigned_pilot_by_craft.duplicate(true)


func get_selected_aircraft_id() -> String:
	return _selected_aircraft_id


func set_selected_aircraft_id(craft_id: String) -> void:
	_selected_aircraft_id = craft_id.strip_edges()


func get_selected_aircraft_definition() -> Dictionary:
	for entry_variant in get_visible_homebase_aircraft_definitions():
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == _selected_aircraft_id:
			return entry
	return {}


func get_aircraft_definition_by_id(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _aircraft_definitions:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return entry
	return {}


func ensure_selected_aircraft_id() -> void:
	var visible_aircraft_definitions: Array = get_visible_homebase_aircraft_definitions()
	if not _selected_aircraft_id.is_empty():
		for entry_variant in visible_aircraft_definitions:
			var entry: Dictionary = Dictionary(entry_variant)
			if String(entry.get("craft_id", "")).strip_edges() == _selected_aircraft_id:
				return
	if visible_aircraft_definitions.is_empty():
		_selected_aircraft_id = ""
		return
	_selected_aircraft_id = String(Dictionary(visible_aircraft_definitions[0]).get("craft_id", "")).strip_edges()


func get_visible_homebase_aircraft_definitions() -> Array:
	var visible_definitions: Array = []
	for entry_variant in _aircraft_definitions:
		var entry: Dictionary = Dictionary(entry_variant)
		var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
		if craft_id.is_empty() or not is_craft_visible_in_homebase(craft_id):
			continue
		visible_definitions.append(entry)
	return visible_definitions


func get_aircraft_location(craft_id: String) -> String:
	return String(_aircraft_location_by_craft.get(craft_id, "homebase")).strip_edges().to_lower()


func is_craft_visible_in_homebase(craft_id: String) -> bool:
	var craft_location: String = get_aircraft_location(craft_id)
	if craft_location == "homebase":
		return true
	if craft_location == "transit" and has_active_pilot_transfer_for_craft(craft_id):
		return true
	return false


func is_craft_in_transit(craft_id: String) -> bool:
	return get_aircraft_location(craft_id) == "transit" or has_active_pilot_transfer_for_craft(craft_id)


func has_active_pilot_transfer_for_craft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return true
	return false


func has_active_cargo_load_for_craft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _cargo_load_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return true
	return false


func get_visible_pilot_transfer_entries(craft_id: String) -> Array:
	var entries: Array = []
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			entries.append(entry)
	return entries


func get_visible_cargo_load_entries(craft_id: String) -> Array:
	var entries: Array = []
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _cargo_load_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			entries.append(entry)
	return entries


func find_cargo_load_entry_for_craft(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _cargo_load_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return entry
	return {}


func find_transfer_entry_for_craft(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return entry
	return {}


func find_pilot_transfer_entry_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("pilot_unit_id", "")).strip_edges() == normalized_unit_id:
			return entry
	return {}


func get_assigned_pilot_id(craft_id: String) -> String:
	return String(_assigned_pilot_by_craft.get(craft_id, "")).strip_edges()


func assign_pilot(craft_id: String, unit_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_unit_id.is_empty():
		return
	clear_pilot_assignment_for_unit(normalized_unit_id)
	_assigned_pilot_by_craft[normalized_craft_id] = normalized_unit_id


func clear_assigned_pilot(craft_id: String) -> String:
	var normalized_craft_id: String = craft_id.strip_edges()
	var pilot_id: String = get_assigned_pilot_id(normalized_craft_id)
	_assigned_pilot_by_craft.erase(normalized_craft_id)
	return pilot_id


func clear_pilot_assignment_for_unit(unit_id: String) -> String:
	var assigned_craft_id: String = find_assigned_craft_for_unit(unit_id)
	if not assigned_craft_id.is_empty():
		_assigned_pilot_by_craft.erase(assigned_craft_id)
	return assigned_craft_id


func is_unit_assigned_to_aircraft(unit_id: String) -> bool:
	return not find_assigned_craft_for_unit(unit_id).is_empty()


func find_assigned_craft_for_unit(unit_id: String) -> String:
	var normalized_unit_id: String = unit_id.strip_edges()
	for craft_id_variant in _assigned_pilot_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if String(_assigned_pilot_by_craft.get(craft_id, "")).strip_edges() == normalized_unit_id:
			return craft_id
	return ""


func count_assigned_pilots() -> int:
	var unique_pilot_ids: Dictionary = {}
	for pilot_id_variant in _assigned_pilot_by_craft.values():
		var pilot_id: String = String(pilot_id_variant).strip_edges()
		if not pilot_id.is_empty():
			unique_pilot_ids[pilot_id] = true
	return unique_pilot_ids.size()


func set_selected_cargo_id(craft_id: String, cargo_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_cargo_id.is_empty():
		_selected_cargo_by_craft.erase(normalized_craft_id)
	else:
		_selected_cargo_by_craft[normalized_craft_id] = normalized_cargo_id


func get_selected_cargo_id(craft_id: String) -> String:
	return String(_selected_cargo_by_craft.get(craft_id, "")).strip_edges()


func get_loaded_cargo_id(craft_id: String) -> String:
	return String(_loaded_cargo_by_craft.get(craft_id, "")).strip_edges()


func craft_supports_cargo(craft_def: Dictionary) -> bool:
	return bool(craft_def.get("supports_cargo", false))


func get_cargo_options_for_craft(craft_def: Dictionary) -> Array:
	return Array(craft_def.get("cargo_options", []))


func build_cargo_display_name(craft_def: Dictionary, cargo_id: String) -> String:
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_cargo_id.is_empty():
		return ""
	for cargo_option_variant in get_cargo_options_for_craft(craft_def):
		var cargo_option: Dictionary = Dictionary(cargo_option_variant)
		if String(cargo_option.get("cargo_id", "")).strip_edges() == normalized_cargo_id:
			return String(cargo_option.get("display_name", normalized_cargo_id)).strip_edges()
	return normalized_cargo_id.capitalize()


func build_craft_display_name(craft_id: String) -> String:
	var craft_def: Dictionary = get_aircraft_definition_by_id(craft_id)
	if craft_def.is_empty():
		return craft_id
	return String(craft_def.get("display_name", craft_id)).strip_edges()


func can_remove_selected_aircraft() -> bool:
	return can_remove_aircraft(_selected_aircraft_id)


func can_remove_aircraft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return false
	var craft_def: Dictionary = get_aircraft_definition_by_id(normalized_craft_id)
	if craft_def.is_empty() or get_aircraft_location(normalized_craft_id) != "homebase":
		return false
	if bool(craft_def.get("air_asset_unavailable", false)):
		return false
	if not get_assigned_pilot_id(normalized_craft_id).is_empty():
		return false
	if has_active_pilot_transfer_for_craft(normalized_craft_id):
		return false
	if has_active_cargo_load_for_craft(normalized_craft_id):
		return false
	if not get_loaded_cargo_id(normalized_craft_id).is_empty():
		return false
	return true


func can_load_selected_cargo(craft_def: Dictionary, craft_id: String) -> bool:
	if craft_def.is_empty() or not craft_supports_cargo(craft_def):
		return false
	if bool(craft_def.get("air_asset_unavailable", false)):
		return false
	if has_active_cargo_load_for_craft(craft_id) or has_active_pilot_transfer_for_craft(craft_id):
		return false
	if not get_loaded_cargo_id(craft_id).is_empty():
		return false
	return not get_selected_cargo_id(craft_id).is_empty()


func can_send_craft(craft_def: Dictionary, craft_id: String) -> bool:
	if craft_def.is_empty() or bool(craft_def.get("air_asset_unavailable", false)):
		return false
	if has_active_pilot_transfer_for_craft(craft_id) or has_active_cargo_load_for_craft(craft_id):
		return false
	if craft_supports_cargo(craft_def):
		var selected_cargo_id: String = get_selected_cargo_id(craft_id)
		var loaded_cargo_id: String = get_loaded_cargo_id(craft_id)
		if not selected_cargo_id.is_empty() and loaded_cargo_id.is_empty():
			return false
	return true


func build_homebase_direct_staging_craft_gate() -> Dictionary:
	var craft_def: Dictionary = get_selected_aircraft_definition()
	var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
	var block_reason: String = get_homebase_direct_staging_craft_block_reason(craft_def, craft_id)
	return {
		"craft": craft_def,
		"can_stage": block_reason.is_empty(),
		"block_reason": block_reason,
		"block_text": build_homebase_direct_staging_block_text(block_reason, craft_def, craft_id),
		"manager_contract": "aircraft_manager_state_validation",
	}


func get_homebase_direct_staging_craft_block_reason(craft_def: Dictionary, craft_id: String) -> String:
	if craft_def.is_empty() or craft_id.is_empty():
		return "no_homebase_craft"
	if String(craft_def.get("craft_type", "dropship")).strip_edges() != "dropship":
		return "not_dropship"
	if bool(craft_def.get("air_asset_unavailable", false)):
		return "air_asset_unavailable"
	if has_active_pilot_transfer_for_craft(craft_id) or is_craft_in_transit(craft_id):
		return "craft_in_transit"
	if has_active_cargo_load_for_craft(craft_id):
		return "craft_busy"
	if get_aircraft_location(craft_id) != "homebase":
		return "not_at_homebase"
	return ""


func build_homebase_direct_staging_block_text(block_reason: String, craft_def: Dictionary, craft_id: String) -> String:
	match block_reason:
		"":
			return ""
		"no_homebase_craft":
			return "Add a dropship shipcard to the Homebase Flightdeck."
		"not_dropship":
			return "%s cannot board fireteams. Select a dropship." % String(craft_def.get("display_name", craft_id)).strip_edges()
		"air_asset_unavailable":
			return "%s is unavailable for recovery." % String(craft_def.get("display_name", craft_id)).strip_edges()
		"craft_in_transit":
			return "%s is already in transit." % String(craft_def.get("display_name", craft_id)).strip_edges()
		"craft_busy":
			return "%s is busy on the Flightdeck." % String(craft_def.get("display_name", craft_id)).strip_edges()
		"not_at_homebase":
			return "%s is not parked at Homebase." % String(craft_def.get("display_name", craft_id)).strip_edges()
	return "Selected craft cannot stage a direct mission payload."


func build_aircraft_status_text(
	craft_def: Dictionary,
	craft_name: String,
	assigned_pilot_id: String,
	assigned_pilot_display_name: String,
	feedback_text: String = ""
) -> String:
	if not feedback_text.strip_edges().is_empty():
		return feedback_text.strip_edges()
	var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
	if bool(craft_def.get("air_asset_unavailable", false)):
		var meta_state: String = String(craft_def.get("air_asset_meta_status", "")).strip_edges()
		var label: String = "replacement pending" if meta_state == "destroyed_replacement_pending" else "repairing"
		return "%s %s. ETA %ds. Pilot state: %s." % [craft_name, label, int(craft_def.get("air_asset_recovery_eta_seconds", 0)), String(craft_def.get("pilot_recovery_state", "pilot_safe_homebase"))]
	if is_craft_in_transit(craft_id):
		return "%s is currently in transit between Homebase and FOB." % craft_name
	if has_active_cargo_load_for_craft(craft_id):
		return "%s is currently loading %s at Homebase." % [craft_name, build_cargo_display_name(craft_def, get_selected_cargo_id(craft_id))]
	if has_active_pilot_transfer_for_craft(craft_id):
		return "%s is currently inbound to FOB." % craft_name
	var loaded_cargo_id: String = get_loaded_cargo_id(craft_id)
	if not loaded_cargo_id.is_empty():
		return "%s ready with %s onboard." % [craft_name, build_cargo_display_name(craft_def, loaded_cargo_id)]
	if not assigned_pilot_id.strip_edges().is_empty():
		return "%s ready. Pilot %s can launch the ship immediately." % [craft_name, assigned_pilot_display_name]
	if craft_supports_cargo(craft_def):
		var selected_cargo_id: String = get_selected_cargo_id(craft_id)
		if not selected_cargo_id.is_empty():
			return "%s idle at Homebase. Selected cargo: %s." % [craft_name, build_cargo_display_name(craft_def, selected_cargo_id)]
	return "%s idle at Homebase. Assign a pilot to start a solo transfer." % craft_name


func get_contract_snapshot() -> Dictionary:
	return {
		"manager_class": "AircraftManager",
		"owns_aircraft_state": true,
		"owns_validation": true,
		"ui_rendering_owned": false,
		"aircraft_count": _aircraft_definitions.size(),
		"visible_aircraft_count": get_visible_homebase_aircraft_definitions().size(),
		"selected_aircraft_id": _selected_aircraft_id,
		"assigned_pilot_count": count_assigned_pilots(),
		"pilot_transfer_count": _pilot_transfer_entries.size(),
		"cargo_load_count": _cargo_load_entries.size(),
		"homebase_direct_gate": build_homebase_direct_staging_craft_gate(),
	}
