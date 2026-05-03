class_name FireteamSelectionAdapter
extends RefCounted


func build_unit_click_selection(current_selection: PackedStringArray, fireteam_id: String, ctrl_pressed: bool) -> PackedStringArray:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return current_selection.duplicate()
	if not ctrl_pressed:
		return PackedStringArray([normalized_fireteam_id])
	var next_selection: PackedStringArray = current_selection.duplicate()
	if not next_selection.has(normalized_fireteam_id):
		next_selection.append(normalized_fireteam_id)
	return next_selection


func merge_lasso_selection(current_selection: PackedStringArray, lasso_fireteam_ids: PackedStringArray, ctrl_pressed: bool) -> PackedStringArray:
	if not ctrl_pressed:
		return lasso_fireteam_ids.duplicate()
	var merged_fireteam_ids: PackedStringArray = current_selection.duplicate()
	for fireteam_id in lasso_fireteam_ids:
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		if normalized_fireteam_id.is_empty() or merged_fireteam_ids.has(normalized_fireteam_id):
			continue
		merged_fireteam_ids.append(normalized_fireteam_id)
	return merged_fireteam_ids


func apply_unit_selection(units: Array, selected_fireteam_ids: PackedStringArray) -> void:
	for unit in units:
		if unit == null or not unit.has_method("set_tactical_selected") or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		unit.call("set_tactical_selected", selected_fireteam_ids.has(fireteam_id))
