class_name MissionFireteamRuntimeState
extends RefCounted


func is_unit_embarked_without_deployment(unit, embarked_unit_ids: Dictionary, deployed_unit_ids: Dictionary) -> bool:
	var unit_id: String = get_unit_id(unit)
	return not unit_id.is_empty() and embarked_unit_ids.has(unit_id) and not deployed_unit_ids.has(unit_id)


func filter_ground_units(units: Array, embarked_unit_ids: Dictionary, deployed_unit_ids: Dictionary) -> Array:
	var result: Array = []
	for unit in units:
		if is_unit_embarked_without_deployment(unit, embarked_unit_ids, deployed_unit_ids):
			continue
		result.append(unit)
	return result


func fireteam_has_embarked_payload(units: Array, embarked_unit_ids: Dictionary, deployed_unit_ids: Dictionary) -> bool:
	for unit in units:
		if is_unit_embarked_without_deployment(unit, embarked_unit_ids, deployed_unit_ids):
			return true
	return false


func is_fireteam_runtime_active(
	fireteam_id: String,
	visible_fireteam_units: Array,
	all_fireteam_units: Array,
	deployed_unit_ids: Dictionary,
	use_visible_units_for_ui: bool,
	preview_mode: bool
) -> bool:
	if preview_mode:
		return false
	var normalized_fireteam_id: String = normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return false
	if not use_visible_units_for_ui:
		for active_unit in visible_fireteam_units:
			if not get_unit_id(active_unit).is_empty():
				return true
		return false
	for unit in all_fireteam_units:
		var unit_id: String = get_unit_id(unit)
		if not unit_id.is_empty() and deployed_unit_ids.has(unit_id):
			return true
	return false


func build_displayable_fireteam_ids(
	available_fireteam_ids: PackedStringArray,
	candidate_units: Array,
	embarked_unit_ids: Dictionary,
	deployed_unit_ids: Dictionary
) -> PackedStringArray:
	var units_by_fireteam: Dictionary = build_units_by_fireteam(candidate_units)
	var displayable_fireteam_ids: PackedStringArray = []
	for fireteam_id_variant in available_fireteam_ids:
		var fireteam_id: String = normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or displayable_fireteam_ids.has(fireteam_id):
			continue
		var units: Array = filter_ground_units(Array(units_by_fireteam.get(fireteam_id, [])), embarked_unit_ids, deployed_unit_ids)
		if units.is_empty():
			continue
		displayable_fireteam_ids.append(fireteam_id)
	return displayable_fireteam_ids


func build_units_by_fireteam(units: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit in units:
		var fireteam_id: String = get_fireteam_id(unit)
		if fireteam_id.is_empty():
			continue
		if not result.has(fireteam_id):
			result[fireteam_id] = []
		result[fireteam_id].append(unit)
	return result


func get_fireteam_id(unit) -> String:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return ""
	return normalize_fireteam_id(String(unit.call("get_fireteam_id")))


func get_unit_id(unit) -> String:
	if unit == null or not unit.has_method("get_unit_id"):
		return ""
	return String(unit.call("get_unit_id")).strip_edges()


func normalize_fireteam_id(fireteam_id: String) -> String:
	return fireteam_id.strip_edges().to_lower()
