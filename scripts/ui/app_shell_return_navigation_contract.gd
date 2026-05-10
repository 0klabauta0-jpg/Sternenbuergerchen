class_name AppShellReturnNavigationContract
extends RefCounted

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const RETURN_LABEL: String = "Main Menu"
const RETURN_ICON_ID: String = "arrow-left"


static func build_return_action(area_id: String, dirty_state: Dictionary = {}) -> Dictionary:
	var normalized_area: String = area_id.strip_edges().to_lower()
	var requires_confirmation: bool = _requires_confirmation(normalized_area, dirty_state)
	return {
		"area_id": normalized_area,
		"label": RETURN_LABEL,
		"icon_id": RETURN_ICON_ID,
		"target_scene": MAIN_MENU_SCENE_PATH,
		"requires_confirmation": requires_confirmation,
		"confirm_reason": _build_confirm_reason(normalized_area, dirty_state) if requires_confirmation else "",
		"does_not_silently_end_multiplayer": normalized_area != "multiplayer" or requires_confirmation,
		"settings_apply_policy": "confirmed_values_only",
	}


static func build_shell_snapshot(area_dirty_states: Dictionary = {}) -> Dictionary:
	var areas: Dictionary = {}
	for area_id in ["singleplayer", "multiplayer", "editor", "settings"]:
		areas[area_id] = build_return_action(area_id, Dictionary(area_dirty_states.get(area_id, {})))
	return {
		"main_menu_scene": MAIN_MENU_SCENE_PATH,
		"button_label": RETURN_LABEL,
		"button_icon_id": RETURN_ICON_ID,
		"areas": areas,
		"all_primary_areas_covered": areas.size() == 4,
	}


static func validate_shell_snapshot(snapshot: Dictionary) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var areas: Dictionary = Dictionary(snapshot.get("areas", {}))
	for area_id in ["singleplayer", "multiplayer", "editor", "settings"]:
		var action: Dictionary = Dictionary(areas.get(area_id, {}))
		if String(action.get("target_scene", "")) != MAIN_MENU_SCENE_PATH:
			errors.append("return_target_invalid:%s" % area_id)
		if String(action.get("label", "")) != RETURN_LABEL:
			errors.append("return_label_invalid:%s" % area_id)
	if not bool(Dictionary(areas.get("multiplayer", {})).get("does_not_silently_end_multiplayer", false)):
		errors.append("multiplayer_silent_end_risk")
	return {"valid": errors.is_empty(), "errors": errors}


static func _requires_confirmation(area_id: String, dirty_state: Dictionary) -> bool:
	if area_id == "editor":
		return bool(dirty_state.get("dirty", false)) or bool(dirty_state.get("scenario_dirty", false))
	if area_id == "settings":
		return bool(dirty_state.get("has_draft_changes", false))
	if area_id == "multiplayer":
		return bool(dirty_state.get("active_session", false))
	return false


static func _build_confirm_reason(area_id: String, dirty_state: Dictionary) -> String:
	if area_id == "editor":
		return "editor_unsaved_changes"
	if area_id == "settings":
		return "settings_draft_changes"
	if area_id == "multiplayer":
		return "multiplayer_session_active"
	return String(dirty_state.get("reason", ""))
