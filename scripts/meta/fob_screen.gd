class_name FOBTestScreen
extends Control

const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")
const TRANSPORT_CRAFT_CARD_UI_SCRIPT: GDScript = preload("res://scripts/meta/transport_craft_card_ui.gd")
const FOB_FIRETEAM_CARD_SCRIPT: GDScript = preload("res://scripts/meta/fob_fireteam_card.gd")
const FOB_DROP_PANEL_SCRIPT: GDScript = preload("res://scripts/meta/fob_drop_panel.gd")
const DROPSHIP_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NE.png")
const DROPSHIP_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NW.png")
const DROPSHIP_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png")
const DROPSHIP_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SW.png")
const DROPSHIP_FOB_TEXTURE: Texture2D = DROPSHIP_TEXTURE_SE
const SMG_BLASTER_PREVIEW_TEXTURE: Texture2D = preload("res://Assets/used/npc/blaster_kit/previews/blaster-a.png")
const SMG_BLASTER_PREVIEW_PATH := "res://Assets/used/npc/blaster_kit/previews/blaster-a.png"
const MEDICTOOL_BLASTER_PREVIEW_TEXTURE: Texture2D = preload("res://Assets/used/npc/blaster_kit/previews/blaster-b.png")
const MEDICTOOL_BLASTER_PREVIEW_PATH := "res://Assets/used/npc/blaster_kit/previews/blaster-b.png"

signal mission_start_requested(selected_unit_ids, selected_fireteam_ids)
signal transport_craft_mission_stage_requested(craft_id)

const DEFAULT_DROPSHIP_ETA_SECONDS := 18.0
const DEFAULT_BOARDING_SECONDS := 6.0
const DROPSHIP_NPC_CAPACITY := 6
const DEFAULT_MEMBER_WEAPON := "smg"
const DEFAULT_MISSION_NAME := "Operation: FOB Transfer"
const DEFAULT_MISSION_MAP := "test_mission_32x32_slots8"
const DEFAULT_MISSION_SLOT_COUNT := 8

var _available_units: Array = []
var _selected_unit_ids: PackedStringArray = []
var _selected_fireteam_ids: PackedStringArray = []
var _fireteam_definitions: Array = []
var _last_mission_result: Dictionary = {}
var _profiles_by_id: Dictionary = {}
var _operator_cards_by_unit_id: Dictionary = {}
var _fireteam_cards_by_id: Dictionary = {}
var _member_cards_by_unit_id: Dictionary = {}
var _focused_unit_id: String = ""
var _focused_fireteam_id: String = "ft1"
var _loadout_staged_fireteam_id: String = ""
var _respawn_staged_fireteam_id: String = ""
var _dropship_staged_fireteam_ids: PackedStringArray = []
var _dropship_phase: String = "idle"
var _dropship_eta_seconds: float = 0.0
var _boarding_seconds: float = 0.0
var _boarding_order: PackedStringArray = []
var _boarding_index: int = 0
var _boarding_member_index: int = 0
var _current_boarding_unit_id: String = ""
var _current_boarding_fireteam_id: String = ""
var _boarded_unit_ids: PackedStringArray = []
var _boarded_fireteam_ids: PackedStringArray = []
var _mission_name: String = DEFAULT_MISSION_NAME
var _mission_map_name: String = DEFAULT_MISSION_MAP
var _mission_slot_count: int = DEFAULT_MISSION_SLOT_COUNT
var _character_overlay_open: bool = false
var _transport_craft_states: Array = []
var _dropship_transport_craft_id: String = ""
var _mission_launch_ready_craft_id: String = ""


func _ready() -> void:
	META_UI_SKIN_SCRIPT.apply_fob(self)
	var start_button := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton") as Button
	var add_team_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AddTeamButton") as Button
	var remove_team_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/RemoveTeamButton") as Button
	var assign_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AssignFocusedUnitButton") as Button
	var clear_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/ClearFocusedUnitButton") as Button
	var fireteam_panel := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel")
	var available_panel := get_node("Panel/Margin/VBox/ContentRow/AvailablePanel")
	var respawn_panel := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel")
	var set_respawn_button := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnButtonRow/SetRespawnButton") as Button
	var clear_respawn_button := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnButtonRow/ClearRespawnButton") as Button
	var clear_loadout_button := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/ClearLoadoutButton") as Button
	var loadout_panel := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel")
	var dropship_panel := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel")
	var start_boarding_button := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/StartBoardingButton") as Button
	var remove_dropship_fireteam_button := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/RemoveDropshipFireteamButton") as Button
	var dropship_timer := get_node("DropshipTimer") as Timer
	var close_overlay_button := get_node("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/CloseOverlayButton") as Button
	var mission_info_row := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow") as HBoxContainer

	if not start_button.pressed.is_connected(_on_start_mission_button_pressed):
		start_button.pressed.connect(_on_start_mission_button_pressed)
	if not add_team_button.pressed.is_connected(_on_add_team_button_pressed):
		add_team_button.pressed.connect(_on_add_team_button_pressed)
	if not remove_team_button.pressed.is_connected(_on_remove_team_button_pressed):
		remove_team_button.pressed.connect(_on_remove_team_button_pressed)
	if not assign_button.pressed.is_connected(_on_assign_focused_unit_button_pressed):
		assign_button.pressed.connect(_on_assign_focused_unit_button_pressed)
	if not clear_button.pressed.is_connected(_on_clear_focused_unit_button_pressed):
		clear_button.pressed.connect(_on_clear_focused_unit_button_pressed)
	if not fireteam_panel.fireteam_dropped.is_connected(_on_staging_fireteam_dropped):
		fireteam_panel.fireteam_dropped.connect(_on_staging_fireteam_dropped)
	if not available_panel.unit_dropped.is_connected(_on_available_panel_unit_dropped):
		available_panel.unit_dropped.connect(_on_available_panel_unit_dropped)
	if not set_respawn_button.pressed.is_connected(_on_set_respawn_button_pressed):
		set_respawn_button.pressed.connect(_on_set_respawn_button_pressed)
	if not clear_respawn_button.pressed.is_connected(_on_clear_respawn_button_pressed):
		clear_respawn_button.pressed.connect(_on_clear_respawn_button_pressed)
	if not clear_loadout_button.pressed.is_connected(_on_clear_loadout_button_pressed):
		clear_loadout_button.pressed.connect(_on_clear_loadout_button_pressed)
	if not respawn_panel.fireteam_dropped.is_connected(_on_staging_fireteam_dropped):
		respawn_panel.fireteam_dropped.connect(_on_staging_fireteam_dropped)
	if not respawn_panel.unit_dropped.is_connected(_on_drop_panel_unit_dropped):
		respawn_panel.unit_dropped.connect(_on_drop_panel_unit_dropped)
	if not loadout_panel.fireteam_dropped.is_connected(_on_staging_fireteam_dropped):
		loadout_panel.fireteam_dropped.connect(_on_staging_fireteam_dropped)
	if not loadout_panel.unit_dropped.is_connected(_on_drop_panel_unit_dropped):
		loadout_panel.unit_dropped.connect(_on_drop_panel_unit_dropped)
	if not dropship_panel.fireteam_dropped.is_connected(_on_staging_fireteam_dropped):
		dropship_panel.fireteam_dropped.connect(_on_staging_fireteam_dropped)
	if not dropship_panel.unit_dropped.is_connected(_on_drop_panel_unit_dropped):
		dropship_panel.unit_dropped.connect(_on_drop_panel_unit_dropped)
	if not start_boarding_button.pressed.is_connected(_on_start_boarding_button_pressed):
		start_boarding_button.pressed.connect(_on_start_boarding_button_pressed)
	if not remove_dropship_fireteam_button.pressed.is_connected(_on_remove_dropship_fireteam_button_pressed):
		remove_dropship_fireteam_button.pressed.connect(_on_remove_dropship_fireteam_button_pressed)
	if not dropship_timer.timeout.is_connected(_on_dropship_timer_timeout):
		dropship_timer.timeout.connect(_on_dropship_timer_timeout)
	if not close_overlay_button.pressed.is_connected(_on_close_overlay_button_pressed):
		close_overlay_button.pressed.connect(_on_close_overlay_button_pressed)
	if mission_info_row != null:
		mission_info_row.move_child(start_button, mission_info_row.get_child_count() - 1)
	if start_button != null:
		start_button.visible = false
		start_button.disabled = true

	_fireteam_definitions = _normalize_fireteam_definitions(_fireteam_definitions, _selected_fireteam_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	_sanitize_fireteam_state()
	_sanitize_staging_state()
	_rebuild_profiles()
	_refresh_ui_state()


func set_available_units(available_units: Array) -> void:
	_available_units = available_units.duplicate(true)
	if is_inside_tree():
		_rebuild_profiles()
		_refresh_ui_state()


func set_transport_craft_state(transport_craft_states: Array) -> void:
	var previous_selected_craft_state: Dictionary = _get_transport_craft_state(_dropship_transport_craft_id)
	_transport_craft_states = []
	for craft_state_variant in transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		_transport_craft_states.append((craft_state_variant as Dictionary).duplicate(true))
	_sanitize_transport_craft_state()
	if is_inside_tree():
		var current_selected_craft_state: Dictionary = _get_transport_craft_state(_dropship_transport_craft_id)
		var selected_craft_became_boardable: bool = not bool(previous_selected_craft_state.get("is_boardable", false)) and bool(current_selected_craft_state.get("is_boardable", false))
		if selected_craft_became_boardable and not _dropship_staged_fireteam_ids.is_empty() and (_dropship_phase == "idle" or _dropship_phase == "incoming"):
			_restart_dropship_cycle()
		_refresh_ui_state()


func configure_transfer(selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray = [], fireteam_definitions: Array = []) -> void:
	var previous_transfer_signature: String = _build_transfer_signature(_selected_unit_ids, _selected_fireteam_ids, _fireteam_definitions)
	_selected_unit_ids = selected_unit_ids.duplicate()
	_fireteam_definitions = _normalize_fireteam_definitions(fireteam_definitions, selected_fireteam_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(selected_fireteam_ids)
	_sanitize_fireteam_state()
	_sanitize_staging_state()
	_sanitize_transport_craft_state()
	_ensure_focused_unit_id()
	_ensure_focused_fireteam_id()
	var next_transfer_signature: String = _build_transfer_signature(_selected_unit_ids, _selected_fireteam_ids, _fireteam_definitions)
	if previous_transfer_signature != next_transfer_signature:
		_restart_dropship_cycle()
	if is_inside_tree():
		_rebuild_profiles()
		_refresh_ui_state()


func set_team(selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray = [], fireteam_definitions: Array = []) -> void:
	configure_transfer(selected_unit_ids, selected_fireteam_ids, fireteam_definitions)


func set_mission_context(mission_name: String, mission_map_name: String, mission_slot_count: int) -> void:
	_mission_name = mission_name.strip_edges() if not mission_name.strip_edges().is_empty() else DEFAULT_MISSION_NAME
	_mission_map_name = mission_map_name.strip_edges() if not mission_map_name.strip_edges().is_empty() else DEFAULT_MISSION_MAP
	_mission_slot_count = maxi(mission_slot_count, 1)
	if is_inside_tree():
		_update_brief_panel()


func get_team() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func get_selected_fireteam_ids() -> PackedStringArray:
	return _selected_fireteam_ids.duplicate()


func get_fireteam_definitions() -> Array:
	var definitions: Array = []
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		definitions.append((definition_variant as Dictionary).duplicate(true))
	return definitions


func set_last_mission_result(mission_result: Dictionary) -> void:
	_last_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_rebuild_profiles()
		_refresh_ui_state()


func clear_last_mission_result() -> void:
	_last_mission_result.clear()
	if is_inside_tree():
		_rebuild_profiles()
		_refresh_ui_state()


func request_mission_start() -> void:
	if not can_request_mission_start():
		return

	mission_start_requested.emit(get_team(), get_selected_fireteam_ids())


func can_request_mission_start() -> bool:
	return _can_request_homebase_mission_start(_get_transport_craft_state(_mission_launch_ready_craft_id))


func get_mission_launch_summary() -> String:
	var craft_state: Dictionary = _get_transport_craft_state(_mission_launch_ready_craft_id)
	if can_request_mission_start():
		var ready_craft_name: String = String(craft_state.get("display_name", "Dropship")).strip_edges()
		if ready_craft_name.is_empty():
			ready_craft_name = "Dropship"
		if bool(craft_state.get("mission_transit_to_map", false)):
			return "%s en route to mission map. Start live mission when ready." % ready_craft_name
		return "%s waiting on the mission map. Start from Homebase when ready." % ready_craft_name
	if not craft_state.is_empty() and bool(craft_state.get("mission_transit_to_map", false)):
		return "%s en route to mission map." % _build_optional_text(String(craft_state.get("display_name", "")).strip_edges(), "Dropship")
	var craft_name: String = String(_get_transport_craft_state(_mission_launch_ready_craft_id).get("display_name", "Dropship")).strip_edges()
	if craft_name.is_empty():
		craft_name = "Dropship"
	return "Board complete in FOB, then send %s to the mission map." % craft_name


func mark_transport_craft_launch_ready(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_mission_launch_ready_craft_id = normalized_craft_id
	if is_inside_tree():
		_refresh_ui_state()


func clear_mission_boarded_payload() -> void:
	_boarded_unit_ids = PackedStringArray()
	_boarded_fireteam_ids = PackedStringArray()
	_dropship_staged_fireteam_ids = PackedStringArray()
	_current_boarding_unit_id = ""
	_current_boarding_fireteam_id = ""
	_dropship_phase = "idle"
	if is_inside_tree():
		_refresh_ui_state()


func _is_mission_ready_for_launch() -> bool:
	if _selected_unit_ids.is_empty():
		return false
	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		if not _boarded_unit_ids.has(unit_id):
			return false
	return true


func _has_boarded_mission_payload() -> bool:
	return not _boarded_unit_ids.is_empty()


func build_mission_drop_state() -> Dictionary:
	var mission_craft_state: Dictionary = _get_transport_craft_state(_mission_launch_ready_craft_id)
	if mission_craft_state.is_empty():
		mission_craft_state = _get_meta_mission_craft_state()
	var mission_drop_state: String = "waiting" if bool(mission_craft_state.get("mission_waiting", false)) else ("to_mission" if bool(mission_craft_state.get("mission_transit_to_map", false)) else ("to_fob" if bool(mission_craft_state.get("mission_transit_to_fob", false)) else ""))
	return {
		"transport_craft_id": _dropship_transport_craft_id,
		"dropship_phase": _dropship_phase,
		"queued_fireteam_ids": Array(_dropship_staged_fireteam_ids),
		"boarded_fireteam_ids": Array(_boarded_fireteam_ids),
		"embarked_unit_ids": Array(_boarded_unit_ids),
		"launch_ready_craft_id": _mission_launch_ready_craft_id,
		"drop_ship_staged": can_request_mission_start(),
		"mission_drop_craft_id": String(mission_craft_state.get("craft_id", _mission_launch_ready_craft_id)).strip_edges(),
		"mission_drop_display_name": String(mission_craft_state.get("display_name", "Dropship")).strip_edges(),
		"mission_drop_title_text": UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title(_build_transport_craft_title(mission_craft_state)) if not mission_craft_state.is_empty() else UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title("Dropship"),
		"mission_drop_texture_path": String(mission_craft_state.get("texture_path", "")).strip_edges(),
		"mission_drop_state": mission_drop_state,
		"mission_drop_pilot_text": _build_transport_craft_pilot_text(mission_craft_state) if not mission_craft_state.is_empty() else "Pilot: none",
		"mission_drop_status_line": _build_transport_craft_status_line(mission_craft_state) if not mission_craft_state.is_empty() else "",
		"mission_drop_progress": float(mission_craft_state.get("transfer_progress", 0.0)),
		"mission_drop_eta_seconds": int(mission_craft_state.get("transfer_eta_seconds", 0)),
		"mission_drop_pilot_unit_id": String(mission_craft_state.get("pilot_unit_id", "")).strip_edges(),
		"mission_drop_pilot_display_name": String(mission_craft_state.get("pilot_display_name", "")).strip_edges(),
		"mission_drop_pilot_portrait_path": String(mission_craft_state.get("pilot_portrait_path", "")).strip_edges(),
		"mission_drop_passenger_count": _boarded_unit_ids.size(),
	}


func build_meta_overview() -> Dictionary:
	var fireteams: Array = []
	var pilot_count: int = _count_transport_pilot_slots()
	var mission_craft_state: Dictionary = _get_meta_mission_craft_state()
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue

		var definition: Dictionary = definition_variant
		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		fireteams.append(
			{
				"id": fireteam_id,
				"label": String(definition.get("label", fireteam_id.to_upper())),
				"lead_name": _build_display_name(String(definition.get("lead_unit_id", ""))),
				"member_names": _build_fireteam_member_names(fireteam_id),
				"respawn_enabled": bool(definition.get("respawn_enabled", false)),
				"loadout": String(definition.get("loadout", "medium")),
			}
		)

	return {
		"team_count": _selected_unit_ids.size(),
		"assigned_operator_count": _count_assigned_operators(),
		"pilot_count": pilot_count,
		"slot_usage_count": _build_mission_slot_usage_count(),
		"dropship_status": _build_dropship_status_text(),
		"dropship_queue": _build_boarding_queue_text(),
		"mission_craft": mission_craft_state,
		"fireteams": fireteams,
	}


func _get_meta_mission_craft_state() -> Dictionary:
	for craft_state_variant in _transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = Dictionary(craft_state_variant)
		if not bool(craft_state.get("mission_waiting", false)) and not bool(craft_state.get("mission_transit_to_map", false)) and not bool(craft_state.get("mission_transit_to_fob", false)):
			continue
		return {
			"craft_id": String(craft_state.get("craft_id", "")).strip_edges(),
			"display_name": String(craft_state.get("display_name", "Dropship")).strip_edges(),
			"texture_path": String(craft_state.get("texture_path", "")).strip_edges(),
			"pilot_display_name": String(craft_state.get("pilot_display_name", "")).strip_edges(),
			"pilot_portrait_path": String(craft_state.get("pilot_portrait_path", "")).strip_edges(),
			"passenger_count": _boarded_unit_ids.size(),
			"transfer_progress": float(craft_state.get("transfer_progress", 0.0)),
			"transfer_eta_seconds": int(craft_state.get("transfer_eta_seconds", 0)),
			"mission_waiting": bool(craft_state.get("mission_waiting", false)),
			"mission_transit_to_map": bool(craft_state.get("mission_transit_to_map", false)),
			"mission_transit_to_fob": bool(craft_state.get("mission_transit_to_fob", false)),
		}
	return {}


func _rebuild_profiles() -> void:
	_profiles_by_id = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id(
		_build_selected_unit_configs(),
		_build_profile_options_by_unit_id()
	)
	_ensure_focused_unit_id()


func _build_selected_unit_configs() -> Array:
	var selected_lookup: Dictionary = {}
	for unit_id_variant in _selected_unit_ids:
		selected_lookup[String(unit_id_variant)] = true
	for transit_unit_id in _get_transit_to_fob_unit_ids():
		selected_lookup[transit_unit_id] = true
	for pilot_unit_id in _get_transport_craft_pilot_unit_ids():
		selected_lookup[pilot_unit_id] = true

	var selected_unit_configs: Array = []
	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue

		var unit_data: Dictionary = unit_data_variant
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or not selected_lookup.has(unit_id):
			continue

		var selected_unit_config: Dictionary = unit_data.duplicate(true)
		selected_unit_config["fireteam_id"] = _get_selected_fireteam_id_for_unit(unit_id)
		selected_unit_configs.append(selected_unit_config)
		selected_lookup.erase(unit_id)

	for missing_unit_id in selected_lookup.keys():
		selected_unit_configs.append(_build_fallback_unit_config(String(missing_unit_id)))

	return selected_unit_configs


func _build_fallback_unit_config(unit_id: String) -> Dictionary:
	var team_state: Dictionary = _get_team_state_for_unit(unit_id)
	return {
		"unit_id": unit_id,
		"display_name": String(team_state.get("display_name", unit_id)),
		"team_id": "",
		"fireteam_id": _get_selected_fireteam_id_for_unit(unit_id),
		"skill_accuracy": 0.5,
		"skill_speed": 0.5,
		"skill_leadership": 0.3,
		"skill_toughness": 0.5,
		"trait_ids": [],
	}


func _build_profile_options_by_unit_id() -> Dictionary:
	var options_by_unit_id: Dictionary = {}
	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var team_state: Dictionary = _get_team_state_for_unit(unit_id)
		options_by_unit_id[unit_id] = {
			"status_text": _build_unit_status_text(team_state),
			"secondary_text": _build_unit_secondary_text(team_state, unit_id),
		}
	for pilot_unit_id in _get_transport_craft_pilot_unit_ids():
		options_by_unit_id[pilot_unit_id] = {
			"status_text": "PILOT",
			"secondary_text": _build_unit_location_text(pilot_unit_id),
		}
	for transit_unit_id in _get_transit_to_fob_unit_ids():
		options_by_unit_id[transit_unit_id] = {
			"status_text": "IN TRANSIT",
			"secondary_text": _build_transit_to_fob_secondary_text(transit_unit_id),
		}

	return options_by_unit_id


func _refresh_ui_state() -> void:
	_apply_block_labels()
	_update_brief_panel()
	_render_available_operators()
	_render_fireteam_rows()
	_update_fireteam_toolbar()
	_update_staging_panel()
	_update_dropship_panel()
	_update_character_overlay()
	_update_character_overlay_visibility()


func _refresh_dropship_status_ui() -> void:
	_update_brief_panel()
	_update_dropship_panel()


func _apply_block_labels() -> void:
	var label_text_by_path: Dictionary = {
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_MISSION_BRIEF,
		"Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_AVAILABLE_OPERATORS,
		"Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_FIRETEAMS,
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/StagingHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_LOADOUT_STAGING,
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_RESPAWN,
		"Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/LoadoutHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_LOADOUT,
		"Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/DropshipHeaderLabel": UI_BLOCK_LABELS_SCRIPT.FOB_DROPSHIP_WAIT_ZONE,
		"CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel": UI_BLOCK_LABELS_SCRIPT.CHARACTER_OVERLAY,
	}
	for path_variant in label_text_by_path.keys():
		var label := get_node_or_null(String(path_variant)) as Label
		if label != null:
			label.text = String(label_text_by_path[path_variant])


func _update_brief_panel() -> void:
	var team_status_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/TeamStatusLabel") as Label
	var fireteam_status_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/FireteamStatusLabel") as Label
	var dropship_status_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/DropshipStatusLabel") as Label
	var mission_header_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel") as Label
	var mission_summary_label := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	var start_button := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/StartMissionButton") as Button
	var pilot_count: int = _count_transport_pilot_slots()
	var mission_slot_usage: int = _build_mission_slot_usage_count()

	mission_header_label.text = UI_BLOCK_LABELS_SCRIPT.FOB_MISSION_BRIEF
	team_status_label.text = "Mission slots: %d / %d" % [mini(mission_slot_usage, _mission_slot_count), _mission_slot_count]
	fireteam_status_label.text = "Mission: %s" % _mission_name
	dropship_status_label.text = "Map: %s" % _mission_map_name
	mission_summary_label.text = "Operators: %d | Pilots: %d | Fireteams: %d active | %s" % [_selected_unit_ids.size(), pilot_count, _count_fireteams_with_members(), _build_dropship_status_text()]
	start_button.text = "Start @ Home"
	start_button.disabled = true
	start_button.visible = false


func _render_available_operators() -> void:
	var operator_list := get_node("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableScroll/AvailableList") as VBoxContainer
	_clear_container(operator_list)
	_operator_cards_by_unit_id.clear()

	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_data_variant)
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		if _is_transport_craft_pilot(unit_id):
			continue
		var is_in_transit: bool = bool(unit_data.get("is_transit_to_fob", false))
		if not is_in_transit and not _get_selected_fireteam_id_for_unit(unit_id).is_empty():
			continue
		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue

		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.setup_from_profile(
			profile,
			{
				"source_context": "fob_available",
				"selected": unit_id == _focused_unit_id,
				"disabled": is_in_transit,
				"drag_enabled": not is_in_transit,
				"compact_mode": true,
				"show_progress": is_in_transit,
				"progress_value": float(unit_data.get("transfer_progress", 0.0)),
			}
		)
		if not card.card_pressed.is_connected(_on_operator_card_pressed):
			card.card_pressed.connect(_on_operator_card_pressed)
		if not card.card_open_requested.is_connected(_on_operator_card_open_requested):
			card.card_open_requested.connect(_on_operator_card_open_requested)
		if not card.card_unit_dropped.is_connected(_on_available_card_unit_dropped):
			card.card_unit_dropped.connect(_on_available_card_unit_dropped)
		operator_list.add_child(card)
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		_operator_cards_by_unit_id[unit_id] = card

	var available_help_label := get_node("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHelpLabel") as Label
	available_help_label.text = _build_available_help_text()


func _render_fireteam_rows() -> void:
	var fireteam_list := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer
	_clear_container(fireteam_list)
	_fireteam_cards_by_id.clear()
	_member_cards_by_unit_id.clear()

	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue

		var definition: Dictionary = definition_variant
		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		if _is_fireteam_staged_in_window(fireteam_id):
			continue
		var fireteam_card: FOBFireteamCard = FOB_FIRETEAM_CARD_SCRIPT.new()
		fireteam_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fireteam_card.setup_card(
			fireteam_id,
			String(definition.get("label", fireteam_id.to_upper())),
			fireteam_id == _focused_fireteam_id,
			bool(definition.get("respawn_enabled", false)),
			String(definition.get("loadout", "medium")),
			"Lead: %s | Members: %s" % [_build_display_name(String(definition.get("lead_unit_id", ""))), _format_member_names(_build_fireteam_member_names(fireteam_id))],
			"fireteam_list"
		)
		if not fireteam_card.card_pressed.is_connected(_on_fireteam_card_pressed):
			fireteam_card.card_pressed.connect(_on_fireteam_card_pressed)
		if not fireteam_card.rename_committed.is_connected(_on_fireteam_card_label_committed):
			fireteam_card.rename_committed.connect(_on_fireteam_card_label_committed)
		if not fireteam_card.unit_dropped.is_connected(_on_fireteam_card_unit_dropped):
			fireteam_card.unit_dropped.connect(_on_fireteam_card_unit_dropped)
		fireteam_list.add_child(fireteam_card)
		_fireteam_cards_by_id[fireteam_id] = fireteam_card

		var member_host: VBoxContainer = fireteam_card.get_member_host()
		var lead_unit_id: String = String(definition.get("lead_unit_id", ""))
		for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
			var member_profile = _profiles_by_id.get(member_unit_id, null)
			if member_profile == null:
				continue

			var member_wrapper := VBoxContainer.new()
			member_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			member_wrapper.add_theme_constant_override("separation", 1)
			member_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
			member_host.add_child(member_wrapper)

			var member_card = NPC_COMPACT_CARD_SCENE.instantiate()
			member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			member_card.setup_from_profile(
				member_profile,
				{
					"source_context": "fob_fireteam",
					"selected": member_unit_id == _focused_unit_id,
					"disabled": false,
					"drag_enabled": true,
					"compact_mode": true,
					"show_lead_indicator": true,
					"is_lead": member_unit_id == lead_unit_id,
				}
			)
			if not member_card.card_pressed.is_connected(_on_operator_card_pressed):
				member_card.card_pressed.connect(_on_operator_card_pressed)
			if not member_card.card_open_requested.is_connected(_on_operator_card_open_requested):
				member_card.card_open_requested.connect(_on_operator_card_open_requested)
			if not member_card.card_unit_dropped.is_connected(_on_member_card_unit_dropped.bind(fireteam_id)):
				member_card.card_unit_dropped.connect(_on_member_card_unit_dropped.bind(fireteam_id))
			if not member_card.lead_toggle_requested.is_connected(_on_member_lead_toggle.bind(fireteam_id)):
				member_card.lead_toggle_requested.connect(_on_member_lead_toggle.bind(fireteam_id))
			member_wrapper.add_child(member_card)
			member_card.mouse_filter = Control.MOUSE_FILTER_PASS
			_member_cards_by_unit_id[member_unit_id] = member_card


func _refresh_card_highlights() -> void:
	for unit_id in _operator_cards_by_unit_id.keys():
		var card = _operator_cards_by_unit_id.get(unit_id, null)
		if card != null and is_instance_valid(card):
			card.set_visual_state(String(unit_id) == _focused_unit_id, _is_unit_in_transit_to_fob(String(unit_id)))

	for unit_id in _member_cards_by_unit_id.keys():
		var card = _member_cards_by_unit_id.get(unit_id, null)
		if card != null and is_instance_valid(card):
			card.set_visual_state(String(unit_id) == _focused_unit_id, false)

	for ft_id in _fireteam_cards_by_id.keys():
		var ft_card = _fireteam_cards_by_id.get(ft_id, null)
		if ft_card != null and is_instance_valid(ft_card):
			ft_card.set_selected(String(ft_id) == _focused_fireteam_id)


func _update_fireteam_toolbar() -> void:
	var remove_team_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/RemoveTeamButton") as Button
	var assign_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/AssignFocusedUnitButton") as Button
	var clear_button := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamToolbar/ClearFocusedUnitButton") as Button
	var summary_label := get_node("Panel/Margin/VBox/ContentRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamSummaryLabel") as Label

	remove_team_button.disabled = _focused_fireteam_id == "ft1"
	assign_button.disabled = _focused_unit_id.is_empty() or _focused_fireteam_id.is_empty()
	clear_button.disabled = _focused_unit_id.is_empty() or _get_selected_fireteam_id_for_unit(_focused_unit_id).is_empty()
	summary_label.text = _build_fireteam_panel_summary_text()


func _update_staging_panel() -> void:
	var respawn_status_label := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnStatusLabel") as Label
	var set_respawn_button := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnButtonRow/SetRespawnButton") as Button
	var clear_respawn_button := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnButtonRow/ClearRespawnButton") as Button
	var respawn_fireteam_list := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/RespawnPanel/RespawnMargin/RespawnVBox/RespawnFireteamList") as VBoxContainer
	var clear_loadout_button := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/ClearLoadoutButton") as Button
	var loadout_status_label := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutStatusLabel") as Label
	var loadout_help_label := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHelpLabel") as Label
	var loadout_fireteam_list := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutFireteamList") as VBoxContainer
	var loadout_member_list := get_node("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer

	var loadout_fireteam_id: String = _normalize_fireteam_id(_loadout_staged_fireteam_id)
	var loadout_definition: Dictionary = _get_fireteam_definition(loadout_fireteam_id)
	var has_loadout_fireteam: bool = not loadout_definition.is_empty()
	var loadout_fireteam_label: String = _get_fireteam_label(loadout_fireteam_id)
	var lead_unit_id: String = String(loadout_definition.get("lead_unit_id", "")) if has_loadout_fireteam else ""
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(loadout_fireteam_id)

	var respawn_fireteam_id: String = _normalize_fireteam_id(_respawn_staged_fireteam_id)
	var respawn_definition: Dictionary = _get_fireteam_definition(respawn_fireteam_id)
	var respawn_enabled: bool = bool(respawn_definition.get("respawn_enabled", false)) if not respawn_definition.is_empty() else false
	var respawn_fireteam_label: String = _get_fireteam_label(respawn_fireteam_id)
	var respawn_lead_unit_id: String = String(respawn_definition.get("lead_unit_id", "")) if not respawn_definition.is_empty() else ""
	var respawn_member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(respawn_fireteam_id)

	respawn_status_label.text = "Respawn anchor: %s" % ("FOB active for %s" % respawn_fireteam_label if respawn_enabled else "not set")
	set_respawn_button.disabled = respawn_fireteam_id.is_empty() or respawn_enabled
	clear_respawn_button.disabled = respawn_fireteam_id.is_empty() or not respawn_enabled

	loadout_status_label.text = "Staged fireteam: %s | Lead: %s | Members: %d" % [loadout_fireteam_label, _build_display_name(lead_unit_id), member_ids.size()]
	loadout_help_label.text = "Kein Team-Default mehr: Armor sowie Slot 1 und Slot 2 werden direkt pro Mitglied gepflegt."
	clear_loadout_button.disabled = not has_loadout_fireteam

	_render_staging_fireteam_card(respawn_fireteam_list, respawn_fireteam_id, "Drop fireteam for FOB respawn.", "respawn_staging", respawn_member_ids, respawn_lead_unit_id)
	_render_staging_fireteam_card(loadout_fireteam_list, loadout_fireteam_id, "Drop fireteam for loadout editing.", "loadout_staging")
	_render_loadout_member_rows(loadout_member_list, loadout_fireteam_id, member_ids, lead_unit_id, has_loadout_fireteam)


func _update_dropship_panel() -> void:
	var status_label := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipInfoVBox/DropshipStatusLabel") as Label
	var eta_label := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipInfoVBox/DropshipEtaLabel") as Label
	var queue_label := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipInfoVBox/BoardingQueueLabel") as Label
	var help_label := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHelpLabel") as Label
	var dropship_sprite_rect := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipVisualVBox/DropshipSpriteRect") as TextureRect
	var dropship_arrival_progress := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipVisualVBox/DropshipArrivalProgress") as ProgressBar
	var dropship_arrival_label := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipVisualVBox/DropshipArrivalLabel") as Label
	var start_boarding_button := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/StartBoardingButton") as Button
	var remove_dropship_fireteam_button := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/RemoveDropshipFireteamButton") as Button
	var queue_list := get_node("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll/DropshipQueueList") as VBoxContainer
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()

	status_label.text = _build_dropship_status_text(selected_craft_state)
	eta_label.text = _build_dropship_eta_text(selected_craft_state)
	queue_label.text = _build_boarding_queue_text()
	help_label.text = "Ziehen Sie Fireteam-Karten direkt auf eine FOB-Shipcard. In Transit sichtbare Schiffe bleiben hier ausgegraut, bis sie eintreffen."
	dropship_sprite_rect.texture = _build_dropship_visual_texture(selected_craft_state)
	dropship_arrival_progress.value = _build_dropship_arrival_progress_value(selected_craft_state)
	dropship_arrival_progress.visible = not selected_craft_state.is_empty() and bool(selected_craft_state.get("is_in_transit", false))
	dropship_arrival_label.text = _build_dropship_arrival_visual_text(selected_craft_state)
	start_boarding_button.visible = false
	start_boarding_button.disabled = true
	remove_dropship_fireteam_button.disabled = not _dropship_staged_fireteam_ids.has(_focused_fireteam_id)
	_render_dropship_fireteam_cards(queue_list)


func _open_character_overlay(unit_id: String) -> void:
	if not unit_id.is_empty():
		_focused_unit_id = unit_id
	_character_overlay_open = true
	_update_character_overlay()
	_update_character_overlay_visibility()


func _update_character_overlay() -> void:
	var profile = _profiles_by_id.get(_focused_unit_id, null)
	var overlay_options: Dictionary = {
		"status_text": _build_overlay_status_text(_focused_unit_id),
		"fireteam_text": CHARACTER_SHEET_FORMATTER_SCRIPT.format_fireteam_label(_build_fireteam_display_text(_get_selected_fireteam_id_for_unit(_focused_unit_id))),
	}
	if profile != null:
		overlay_options["loadout_text"] = _build_overlay_loadout_text(_focused_unit_id, profile)
	CHARACTER_SHEET_VIEW_SCRIPT.render(
		_get_character_overlay_content_host(),
		profile,
		overlay_options
	)


func _get_character_overlay_content_host() -> VBoxContainer:
	return get_node("CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox/GeneratedOverlayContent") as VBoxContainer


func _update_character_overlay_visibility() -> void:
	var overlay := get_node("CharacterOverlay") as Control
	overlay.visible = _character_overlay_open


func _build_fob_summary_text() -> String:
	var focused_operator_text := _build_display_name(_focused_unit_id) if not _focused_unit_id.is_empty() else "none"
	var focused_fireteam_text := _get_fireteam_label(_focused_fireteam_id)
	var mission_summary: String = _build_last_mission_summary_text()
	return "Focused operator: %s | Focused fireteam: %s | %s" % [focused_operator_text, focused_fireteam_text, mission_summary]


func _build_last_mission_summary_text() -> String:
	if _last_mission_result.is_empty():
		return "Last mission: none recorded"

	var result_text: String = String(_last_mission_result.get("result", "ended")).strip_edges()
	var duration_seconds: float = float(_last_mission_result.get("duration_seconds", 0.0))
	return "Last mission: %s (%.1fs)" % [result_text.to_upper(), duration_seconds]


func _build_available_help_text() -> String:
	var inbound_count: int = _get_transit_to_fob_unit_ids().size()
	if _focused_unit_id.is_empty():
		if inbound_count > 0:
			return "Links stehen unzugewiesene FOB-Operators. Grau markierte Karten sind noch im Anflug und zeigen ihren Transferfortschritt."
		return "Links stehen nur unzugewiesene FOB-Operators. Ziehe Mitglieder auf Fireteams oder zurueck hierher, um sie zu loesen."

	return "Focused operator: %s | Current fireteam: %s" % [_build_display_name(_focused_unit_id), _build_fireteam_display_text(_get_selected_fireteam_id_for_unit(_focused_unit_id))]


func _build_fireteam_panel_summary_text() -> String:
	if _selected_unit_ids.is_empty():
		return "No transferred operators in FOB."

	return "Focused fireteam: %s | Lead: %s | Assigned operators: %d / %d" % [_get_fireteam_label(_focused_fireteam_id), _build_display_name(_get_fireteam_lead_unit_id(_focused_fireteam_id)), _count_assigned_operators(), _selected_unit_ids.size()]


func _build_dropship_status_text(selected_craft_state: Dictionary = {}) -> String:
	if not selected_craft_state.is_empty():
		var craft_name: String = String(selected_craft_state.get("display_name", "craft")).strip_edges()
		var craft_id: String = String(selected_craft_state.get("craft_id", "")).strip_edges()
		if bool(selected_craft_state.get("mission_waiting", false)):
			return "%s: waiting on mission map" % craft_name
		if bool(selected_craft_state.get("mission_transit_to_map", false)):
			return "%s: outbound to mission map" % craft_name
		if bool(selected_craft_state.get("mission_transit_to_fob", false)):
			return "%s: returning from mission map" % craft_name
		if bool(selected_craft_state.get("is_in_transit", false)):
			return "%s: inbound from Homebase" % craft_name
		if craft_id == _mission_launch_ready_craft_id and _has_boarded_mission_payload():
			return "%s: staged for mission start" % craft_name
		if not bool(selected_craft_state.get("is_boardable", false)):
			return "%s: cargo visible in FOB" % craft_name
		if _dropship_transport_craft_id == String(selected_craft_state.get("craft_id", "")).strip_edges() and not _boarding_order.is_empty():
			match _dropship_phase:
				"ready":
					return "%s: docked, boarding ready" % craft_name
				"boarding":
					return "%s: boarding %s for %s" % [craft_name, _build_display_name(_get_boarding_member_id()), _get_fireteam_label(_get_boarding_fireteam_id())]
				"boarded":
					return "%s: all queued fireteams boarded" % craft_name
		return "%s: docked in FOB" % craft_name
	match _dropship_phase:
		"incoming":
			return "Dropship: inbound"
		"ready":
			return "Dropship: docked, boarding ready"
		"boarding":
			return "Dropship: boarding %s for %s" % [_build_display_name(_get_boarding_member_id()), _get_fireteam_label(_get_boarding_fireteam_id())]
		"boarded":
			return "Dropship: all queued fireteams boarded"
		_:
			return "Dropship: waiting for active fireteams"


func _build_dropship_eta_text(selected_craft_state: Dictionary = {}) -> String:
	if not selected_craft_state.is_empty():
		if bool(selected_craft_state.get("mission_waiting", false)):
			return "Mission ETA: on-station | awaiting Drop"
		if bool(selected_craft_state.get("mission_transit_to_map", false)) or bool(selected_craft_state.get("mission_transit_to_fob", false)):
			return "Mission ETA: %ds" % int(selected_craft_state.get("transfer_eta_seconds", 0))
		if bool(selected_craft_state.get("is_in_transit", false)):
			return "Arrival ETA: %ds" % int(selected_craft_state.get("transfer_eta_seconds", 0))
		if _dropship_transport_craft_id == String(selected_craft_state.get("craft_id", "")).strip_edges() and not _boarding_order.is_empty():
			match _dropship_phase:
				"ready":
					return "Arrival ETA: docked | manual start ready"
				"boarding":
					return "NPC boarding timer: %.0fs" % _boarding_seconds
				"boarded":
					return "Arrival ETA: docked"
		return "Arrival ETA: already docked"
	match _dropship_phase:
		"incoming":
			return "Arrival ETA: %.0fs" % _dropship_eta_seconds
		"ready":
			return "Arrival ETA: docked | manual start ready"
		"boarding":
			return "NPC boarding timer: %.0fs" % _boarding_seconds
		"boarded":
			return "Arrival ETA: docked"
		_:
			return "Arrival ETA: no transport queued"


func _build_boarding_queue_text() -> String:
	if _boarding_order.is_empty():
		return "Boarding queue: no active fireteams"

	var queued_labels: PackedStringArray = []
	for fireteam_id in _boarding_order:
		var normalized_fireteam_id: String = String(fireteam_id)
		var total_members: int = _get_member_unit_ids_for_fireteam(normalized_fireteam_id).size()
		var boarded_members: int = _count_boarded_members_in_fireteam(normalized_fireteam_id)
		var prefix := "[%d/%d] " % [boarded_members, total_members]
		if _boarded_fireteam_ids.has(normalized_fireteam_id):
			prefix = "[boarded %d/%d] " % [boarded_members, total_members]
		elif normalized_fireteam_id == _get_boarding_fireteam_id() and _dropship_phase == "boarding":
			prefix = "[boarding %d/%d] " % [boarded_members, total_members]
		elif _dropship_phase == "ready":
			prefix = "[ready %d/%d] " % [boarded_members, total_members]
		queued_labels.append("%s%s" % [prefix, _get_fireteam_label(normalized_fireteam_id)])

	return "Boarding queue: %s" % " | ".join(queued_labels)


func _on_operator_card_pressed(unit_id: String, _profile, _source_context: String) -> void:
	_focused_unit_id = unit_id
	_refresh_card_highlights()
	_update_brief_panel()
	_update_fireteam_toolbar()
	_update_staging_panel()
	if _character_overlay_open:
		_update_character_overlay()
	var available_help_label := get_node_or_null("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHelpLabel") as Label
	if available_help_label != null:
		available_help_label.text = _build_available_help_text()


func _on_operator_card_open_requested(unit_id: String, _profile, _source_context: String) -> void:
	_focused_unit_id = unit_id
	_refresh_card_highlights()
	_open_character_overlay(unit_id)


func _on_select_fireteam_pressed(fireteam_id: String) -> void:
	_focused_fireteam_id = fireteam_id
	_refresh_card_highlights()
	_update_brief_panel()
	_update_fireteam_toolbar()
	_update_staging_panel()


func _on_fireteam_card_pressed(fireteam_id: String) -> void:
	_focused_fireteam_id = fireteam_id
	_refresh_card_highlights()
	_update_brief_panel()
	_update_fireteam_toolbar()
	_update_staging_panel()


func _on_fireteam_card_label_committed(fireteam_id: String, next_text: String) -> void:
	_commit_fireteam_label(fireteam_id, next_text)


func _on_fireteam_card_unit_dropped(unit_id: String, fireteam_id: String) -> void:
	if unit_id.is_empty() or fireteam_id.is_empty():
		return
	_focused_unit_id = unit_id
	_focused_fireteam_id = fireteam_id
	_set_selected_fireteam_for_unit(unit_id, fireteam_id)


func _on_member_card_unit_dropped(dropped_unit_id: String, _source_context: String, fireteam_id: String) -> void:
	if dropped_unit_id.is_empty() or fireteam_id.is_empty():
		return
	_focused_unit_id = dropped_unit_id
	_focused_fireteam_id = fireteam_id
	_set_selected_fireteam_for_unit(dropped_unit_id, fireteam_id)


func _on_available_card_unit_dropped(dropped_unit_id: String, _source_context: String) -> void:
	_on_available_panel_unit_dropped(dropped_unit_id)


func _on_drop_panel_unit_dropped(unit_id: String, drop_kind: String) -> void:
	if unit_id.is_empty():
		return
	var fireteam_id: String = _get_selected_fireteam_id_for_unit(unit_id)
	if fireteam_id.is_empty():
		return
	_focused_fireteam_id = fireteam_id
	if drop_kind == "respawn":
		_set_focused_fireteam_respawn_enabled(true)
		return
	_refresh_ui_state()


func _on_fireteam_label_submitted(next_text: String, fireteam_id: String) -> void:
	_commit_fireteam_label(fireteam_id, next_text)


func _on_fireteam_label_focus_exited(rename_edit: LineEdit, fireteam_id: String) -> void:
	if rename_edit == null:
		return

	_commit_fireteam_label(fireteam_id, rename_edit.text)


func _commit_fireteam_label(fireteam_id: String, next_text: String) -> void:
	var definition_index: int = _find_fireteam_definition_index(fireteam_id)
	if definition_index < 0:
		return

	var definition: Dictionary = _fireteam_definitions[definition_index]
	var fallback_label: String = fireteam_id.to_upper()
	var normalized_label: String = next_text.strip_edges()
	if normalized_label.is_empty():
		normalized_label = fallback_label
	definition["label"] = normalized_label
	_fireteam_definitions[definition_index] = definition
	_refresh_ui_state()


func _on_add_team_button_pressed() -> void:
	var next_id: String = _build_next_fireteam_id()
	_fireteam_definitions.append(_make_fireteam_definition(next_id, next_id.to_upper()))
	_focused_fireteam_id = next_id
	_sanitize_fireteam_state()
	_restart_dropship_cycle()
	_rebuild_profiles()
	_refresh_ui_state()


func _on_remove_team_button_pressed() -> void:
	if _focused_fireteam_id == "ft1":
		return

	var definition_index: int = _find_fireteam_definition_index(_focused_fireteam_id)
	if definition_index < 0:
		return

	for unit_index in range(_selected_fireteam_ids.size()):
		if String(_selected_fireteam_ids[unit_index]).strip_edges().to_lower() == _focused_fireteam_id:
			_selected_fireteam_ids[unit_index] = ""

	_fireteam_definitions.remove_at(definition_index)
	_focused_fireteam_id = "ft1"
	_sanitize_fireteam_state()
	_restart_dropship_cycle()
	_rebuild_profiles()
	_refresh_ui_state()


func _on_assign_focused_unit_button_pressed() -> void:
	if _focused_unit_id.is_empty() or _focused_fireteam_id.is_empty():
		return

	_set_selected_fireteam_for_unit(_focused_unit_id, _focused_fireteam_id)


func _on_clear_focused_unit_button_pressed() -> void:
	if _focused_unit_id.is_empty():
		return

	_set_selected_fireteam_for_unit(_focused_unit_id, "")


func _on_available_panel_unit_dropped(unit_id: String) -> void:
	if unit_id.is_empty():
		return
	_focused_unit_id = unit_id
	_set_selected_fireteam_for_unit(unit_id, "")


func _on_set_respawn_button_pressed() -> void:
	if _respawn_staged_fireteam_id.is_empty():
		return
	_set_fireteam_respawn_enabled(_respawn_staged_fireteam_id, true)


func _on_clear_respawn_button_pressed() -> void:
	if _respawn_staged_fireteam_id.is_empty():
		return
	_set_fireteam_respawn_enabled(_respawn_staged_fireteam_id, false)
	_respawn_staged_fireteam_id = ""
	_refresh_ui_state()


func _on_clear_loadout_button_pressed() -> void:
	if _loadout_staged_fireteam_id.is_empty():
		return
	_loadout_staged_fireteam_id = ""
	_refresh_ui_state()


func _on_remove_dropship_fireteam_button_pressed() -> void:
	if not _dropship_staged_fireteam_ids.has(_focused_fireteam_id):
		return
	var next_queue: PackedStringArray = []
	for fireteam_id_variant in _dropship_staged_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant)
		if fireteam_id == _focused_fireteam_id:
			continue
		next_queue.append(fireteam_id)
	_dropship_staged_fireteam_ids = next_queue
	if _dropship_staged_fireteam_ids.is_empty():
		_dropship_transport_craft_id = ""
	_restart_dropship_cycle()
	_refresh_ui_state()


func _on_start_boarding_button_pressed() -> void:
	if _dropship_phase != "ready" or _boarding_order.is_empty():
		return
	_boarding_index = 0
	_boarding_member_index = 0
	_current_boarding_unit_id = ""
	_boarded_unit_ids = PackedStringArray()
	_boarded_fireteam_ids = PackedStringArray()
	_start_next_boarding_step()
	_refresh_dropship_status_ui()


func _on_staging_fireteam_dropped(fireteam_id: String, drop_kind: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	var normalized_drop_kind: String = drop_kind
	var target_craft_id: String = ""
	if normalized_drop_kind.begins_with("dropship|"):
		target_craft_id = normalized_drop_kind.trim_prefix("dropship|")
		normalized_drop_kind = "dropship"

	_focused_fireteam_id = normalized_fireteam_id
	var dropship_queue_changed: bool = _remove_fireteam_from_other_staging(normalized_fireteam_id, normalized_drop_kind)
	if normalized_drop_kind == "respawn":
		_respawn_staged_fireteam_id = normalized_fireteam_id
		_set_fireteam_respawn_enabled(normalized_fireteam_id, true)
		if dropship_queue_changed:
			_restart_dropship_cycle()
		return
	if normalized_drop_kind == "loadout":
		_loadout_staged_fireteam_id = normalized_fireteam_id
		if dropship_queue_changed:
			_restart_dropship_cycle()
		_refresh_ui_state()
		return
	if normalized_drop_kind == "dropship":
		_queue_fireteam_for_dropship(normalized_fireteam_id, target_craft_id)
		return
	if dropship_queue_changed:
		_restart_dropship_cycle()
	_refresh_ui_state()


func _on_set_fireteam_lead_pressed(fireteam_id: String, unit_id: String) -> void:
	var definition_index: int = _find_fireteam_definition_index(fireteam_id)
	if definition_index < 0:
		return

	var definition: Dictionary = _fireteam_definitions[definition_index]
	definition["lead_unit_id"] = unit_id
	_fireteam_definitions[definition_index] = definition
	_focused_fireteam_id = fireteam_id
	_focused_unit_id = unit_id
	_sanitize_fireteam_state()
	_refresh_ui_state()


func _on_member_lead_toggle(unit_id: String, fireteam_id: String) -> void:
	_on_set_fireteam_lead_pressed(fireteam_id, unit_id)


func _on_member_armor_selected(index: int, fireteam_id: String, unit_id: String) -> void:
	_set_member_loadout(fireteam_id, unit_id, _armor_id_from_index(index), "", "")


func _on_member_weapon_1_selected(index: int, fireteam_id: String, unit_id: String) -> void:
	_set_member_loadout(fireteam_id, unit_id, "", _weapon_id_from_index(index), "")


func _on_member_weapon_2_selected(index: int, fireteam_id: String, unit_id: String) -> void:
	_set_member_loadout(fireteam_id, unit_id, "", "", _weapon_id_from_index(index))


func _on_start_mission_button_pressed() -> void:
	request_mission_start()


func _on_dropship_timer_timeout() -> void:
	match _dropship_phase:
		"incoming":
			_dropship_eta_seconds = maxf(_dropship_eta_seconds - 1.0, 0.0)
			if _dropship_eta_seconds <= 0.0:
				_dropship_eta_seconds = 0.0
				_dropship_phase = "ready"
				var ready_timer := get_node("DropshipTimer") as Timer
				ready_timer.stop()
		"boarding":
			_boarding_seconds = maxf(_boarding_seconds - 1.0, 0.0)
			if _boarding_seconds <= 0.0:
				_complete_current_boarding_member()
				_start_next_boarding_step()
		_:
			var dropship_timer := get_node("DropshipTimer") as Timer
			dropship_timer.stop()

	_refresh_dropship_status_ui()


func _start_next_boarding_step() -> void:
	var dropship_timer := get_node_or_null("DropshipTimer") as Timer
	while _boarding_index < _boarding_order.size():
		var candidate_fireteam_id: String = String(_boarding_order[_boarding_index])
		var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(candidate_fireteam_id)
		if member_ids.is_empty():
			_boarding_index += 1
			_boarding_member_index = 0
			continue
		while _boarding_member_index < member_ids.size():
			var candidate_unit_id: String = String(member_ids[_boarding_member_index])
			if _boarded_unit_ids.has(candidate_unit_id):
				_boarding_member_index += 1
				continue
			_current_boarding_unit_id = candidate_unit_id
			_dropship_phase = "boarding"
			_boarding_seconds = DEFAULT_BOARDING_SECONDS
			if dropship_timer != null:
				dropship_timer.start()
			return
		if _is_fireteam_fully_boarded(candidate_fireteam_id) and not _boarded_fireteam_ids.has(candidate_fireteam_id):
			_boarded_fireteam_ids.append(candidate_fireteam_id)
		_boarding_index += 1
		_boarding_member_index = 0

	_dropship_phase = "boarded"
	_boarding_seconds = 0.0
	_current_boarding_unit_id = ""
	if dropship_timer != null:
		dropship_timer.stop()


func _restart_dropship_cycle() -> void:
	var dropship_timer := get_node_or_null("DropshipTimer") as Timer
	if dropship_timer != null:
		dropship_timer.stop()

	_boarded_unit_ids = PackedStringArray()
	_boarded_fireteam_ids = PackedStringArray()
	_boarding_order = _build_boarding_order()
	_boarding_index = 0
	_boarding_member_index = 0
	_current_boarding_unit_id = ""
	_boarding_seconds = 0.0
	_mission_launch_ready_craft_id = ""

	if _selected_unit_ids.is_empty() or _boarding_order.is_empty():
		_dropship_phase = "idle"
		_dropship_eta_seconds = 0.0
		if _dropship_staged_fireteam_ids.is_empty():
			_dropship_transport_craft_id = ""
		if is_inside_tree():
			_refresh_dropship_status_ui()
		return

	var selected_craft_state: Dictionary = _get_transport_craft_state(_dropship_transport_craft_id)
	if not selected_craft_state.is_empty() and _can_stage_fireteam_into_craft(selected_craft_state):
		_dropship_phase = "ready"
		_dropship_eta_seconds = 0.0
		if is_inside_tree():
			_refresh_dropship_status_ui()
		return

	_dropship_phase = "incoming"
	_dropship_eta_seconds = DEFAULT_DROPSHIP_ETA_SECONDS
	if dropship_timer != null:
		dropship_timer.start()
	if is_inside_tree():
		_refresh_dropship_status_ui()


func _count_assigned_operators() -> int:
	var assigned_count: int = 0
	for fireteam_id in _selected_fireteam_ids:
		if not String(fireteam_id).strip_edges().is_empty():
			assigned_count += 1
	return assigned_count


func _count_transport_pilot_slots() -> int:
	return _get_transport_craft_pilot_unit_ids().size()


func _build_mission_slot_usage_count() -> int:
	return _selected_unit_ids.size() + _count_transport_pilot_slots()


func _count_fireteams_with_members() -> int:
	var active_count: int = 0
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var fireteam_id: String = String((definition_variant as Dictionary).get("id", "")).strip_edges().to_lower()
		if not _build_fireteam_member_names(fireteam_id).is_empty():
			active_count += 1
	return active_count


func _build_boarding_order() -> PackedStringArray:
	var order: PackedStringArray = []
	for fireteam_id_variant in _dropship_staged_fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty():
			continue
		if _build_fireteam_member_names(fireteam_id).is_empty():
			continue
		order.append(fireteam_id)
	return order


func _get_boarding_fireteam_id() -> String:
	if _dropship_phase != "boarding" or _boarding_index < 0 or _boarding_index >= _boarding_order.size():
		return ""
	return String(_boarding_order[_boarding_index])


func _get_boarding_member_id() -> String:
	if _dropship_phase != "boarding":
		return ""
	return _current_boarding_unit_id


func _complete_current_boarding_member() -> void:
	if _current_boarding_unit_id.is_empty():
		return
	if not _boarded_unit_ids.has(_current_boarding_unit_id):
		_boarded_unit_ids.append(_current_boarding_unit_id)
	var current_fireteam_id: String = _get_boarding_fireteam_id()
	if not current_fireteam_id.is_empty() and _is_fireteam_fully_boarded(current_fireteam_id) and not _boarded_fireteam_ids.has(current_fireteam_id):
		_boarded_fireteam_ids.append(current_fireteam_id)
	_boarding_member_index += 1
	_current_boarding_unit_id = ""


func _is_fireteam_fully_boarded(fireteam_id: String) -> bool:
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
	if member_ids.is_empty():
		return false
	for member_unit_id in member_ids:
		if not _boarded_unit_ids.has(String(member_unit_id)):
			return false
	return true


func _count_boarded_members_in_fireteam(fireteam_id: String) -> int:
	var boarded_count: int = 0
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		if _boarded_unit_ids.has(String(member_unit_id)):
			boarded_count += 1
	return boarded_count


func _set_focused_fireteam_respawn_enabled(enabled: bool) -> void:
	_set_fireteam_respawn_enabled(_focused_fireteam_id, enabled)


func _set_fireteam_respawn_enabled(fireteam_id: String, enabled: bool) -> void:
	var definition_index: int = _find_fireteam_definition_index(fireteam_id)
	if definition_index < 0:
		return

	var definition: Dictionary = _fireteam_definitions[definition_index]
	definition["respawn_enabled"] = enabled
	_fireteam_definitions[definition_index] = definition
	if enabled:
		_respawn_staged_fireteam_id = fireteam_id
	elif _respawn_staged_fireteam_id == fireteam_id:
		_respawn_staged_fireteam_id = ""
	_refresh_ui_state()


func _queue_fireteam_for_dropship(fireteam_id: String, craft_id: String = "") -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	var target_craft_id: String = craft_id.strip_edges()
	if target_craft_id.is_empty():
		target_craft_id = _dropship_transport_craft_id
	if target_craft_id.is_empty():
		var fallback_craft_state: Dictionary = _get_selected_transport_craft_state()
		target_craft_id = String(fallback_craft_state.get("craft_id", "")).strip_edges()
	var target_craft_state: Dictionary = _get_transport_craft_state(target_craft_id)
	if not target_craft_state.is_empty() and not _can_stage_fireteam_into_craft(target_craft_state, normalized_fireteam_id):
		return
	if not target_craft_id.is_empty():
		_dropship_transport_craft_id = target_craft_id
	if not _dropship_staged_fireteam_ids.has(normalized_fireteam_id):
		_dropship_staged_fireteam_ids.append(normalized_fireteam_id)
	_restart_dropship_cycle()
	_refresh_ui_state()


func _remove_fireteam_from_other_staging(fireteam_id: String, target_drop_kind: String) -> bool:
	var dropship_queue_changed: bool = false
	if target_drop_kind != "loadout" and _loadout_staged_fireteam_id == fireteam_id:
		_loadout_staged_fireteam_id = ""
	if target_drop_kind != "respawn" and _respawn_staged_fireteam_id == fireteam_id:
		_set_fireteam_respawn_enabled(fireteam_id, false)
		_respawn_staged_fireteam_id = ""
	if target_drop_kind != "dropship" and _dropship_staged_fireteam_ids.has(fireteam_id):
		var next_queue: PackedStringArray = []
		for queued_fireteam_id in _dropship_staged_fireteam_ids:
			if String(queued_fireteam_id) == fireteam_id:
				continue
			next_queue.append(String(queued_fireteam_id))
		_dropship_staged_fireteam_ids = next_queue
		dropship_queue_changed = true
	return dropship_queue_changed


func _is_fireteam_staged_in_window(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return false
	if _loadout_staged_fireteam_id == normalized_fireteam_id:
		return true
	if _respawn_staged_fireteam_id == normalized_fireteam_id:
		return true
	return _dropship_staged_fireteam_ids.has(normalized_fireteam_id)


func _render_loadout_member_rows(
	container: VBoxContainer,
	fireteam_id: String,
	member_ids: PackedStringArray,
	lead_unit_id: String,
	has_focus_fireteam: bool
) -> void:
	_clear_container(container)
	if not has_focus_fireteam:
		var empty_focus_label := Label.new()
		empty_focus_label.text = "No fireteam focused."
		empty_focus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(empty_focus_label)
		return

	if member_ids.is_empty():
		var empty_members_label := Label.new()
		empty_members_label.text = "No members assigned to %s yet." % _get_fireteam_label(fireteam_id)
		empty_members_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(empty_members_label)
		return

	for member_unit_id in member_ids:
		var member_row := _build_member_loadout_row(fireteam_id, member_unit_id, lead_unit_id, false)
		if member_row != null:
			container.add_child(member_row)


func _build_member_loadout_row(fireteam_id: String, member_unit_id: String, lead_unit_id: String, drag_enabled: bool) -> Control:
	var member_profile = _profiles_by_id.get(member_unit_id, null)
	if member_profile == null:
		return null

	var row_panel := PanelContainer.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_loadout_member_row_style(row_panel, member_unit_id == lead_unit_id)

	var row_margin := MarginContainer.new()
	row_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_margin.add_theme_constant_override("margin_left", 6)
	row_margin.add_theme_constant_override("margin_top", 6)
	row_margin.add_theme_constant_override("margin_right", 6)
	row_margin.add_theme_constant_override("margin_bottom", 6)
	row_panel.add_child(row_margin)

	var content_row := HBoxContainer.new()
	content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_row.add_theme_constant_override("separation", 8)
	row_margin.add_child(content_row)

	var member_card = NPC_COMPACT_CARD_SCENE.instantiate()
	member_card.custom_minimum_size = Vector2(208.0, 58.0)
	member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_card.setup_from_profile(
		member_profile,
		{
			"source_context": "respawn_staging" if drag_enabled else "loadout_staging",
			"selected": member_unit_id == _focused_unit_id,
			"disabled": false,
			"drag_enabled": drag_enabled,
			"compact_mode": true,
			"show_lead_indicator": true,
			"is_lead": member_unit_id == lead_unit_id,
		}
	)
	if not member_card.card_pressed.is_connected(_on_operator_card_pressed):
		member_card.card_pressed.connect(_on_operator_card_pressed)
	if not member_card.card_open_requested.is_connected(_on_operator_card_open_requested):
		member_card.card_open_requested.connect(_on_operator_card_open_requested)
	if not member_card.lead_toggle_requested.is_connected(_on_member_lead_toggle.bind(fireteam_id)):
		member_card.lead_toggle_requested.connect(_on_member_lead_toggle.bind(fireteam_id))
	content_row.add_child(member_card)

	var controls_vbox := VBoxContainer.new()
	controls_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls_vbox.add_theme_constant_override("separation", 4)
	content_row.add_child(controls_vbox)

	var selectors_label_row := HBoxContainer.new()
	selectors_label_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selectors_label_row.add_theme_constant_override("separation", 4)
	controls_vbox.add_child(selectors_label_row)

	for label_text in ["Armor", "Slot 1", "Slot 2"]:
		var selector_label := Label.new()
		selector_label.text = label_text
		selector_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector_label.add_theme_font_size_override("font_size", 9)
		selectors_label_row.add_child(selector_label)

	var selectors_row := HBoxContainer.new()
	selectors_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selectors_row.add_theme_constant_override("separation", 4)
	controls_vbox.add_child(selectors_row)

	var member_loadout: Dictionary = _get_member_loadout(fireteam_id, member_unit_id)

	var armor_select := OptionButton.new()
	armor_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	armor_select.custom_minimum_size = Vector2(54.0, 0.0)
	armor_select.add_theme_font_size_override("font_size", 9)
	_populate_armor_option_button(armor_select, String(member_loadout.get("armor", "medium")))
	META_UI_SKIN_SCRIPT.style_secondary_button(armor_select)
	if not armor_select.item_selected.is_connected(_on_member_armor_selected.bind(fireteam_id, member_unit_id)):
		armor_select.item_selected.connect(_on_member_armor_selected.bind(fireteam_id, member_unit_id))
	selectors_row.add_child(armor_select)

	selectors_row.add_child(_build_weapon_slot_control(
		"Weapon1",
		String(member_loadout.get("weapon_1", member_loadout.get("weapon", DEFAULT_MEMBER_WEAPON))),
		fireteam_id,
		member_unit_id,
		1
	))
	selectors_row.add_child(_build_weapon_slot_control(
		"Weapon2",
		String(member_loadout.get("weapon_2", DEFAULT_MEMBER_WEAPON)),
		fireteam_id,
		member_unit_id,
		2
	))

	return row_panel


func _render_fireteam_card_member_loadout_rows(container: VBoxContainer, fireteam_id: String, member_ids: PackedStringArray, lead_unit_id: String) -> void:
	for member_unit_id in member_ids:
		var member_row := _build_member_loadout_row(fireteam_id, member_unit_id, lead_unit_id, true)
		if member_row != null:
			container.add_child(member_row)


func _render_dropship_member_rows(container: VBoxContainer, fireteam_id: String, member_ids: PackedStringArray) -> void:
	var status_label := Label.new()
	status_label.text = _build_boarding_progress_text(fireteam_id)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(status_label)

	for member_unit_id in member_ids:
		var member_profile = _profiles_by_id.get(member_unit_id, null)
		if member_profile == null:
			continue

		var member_vbox := VBoxContainer.new()
		member_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		member_vbox.add_theme_constant_override("separation", 2)
		member_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(member_vbox)

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		member_vbox.add_child(row)

		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(24.0, 24.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = _load_portrait_texture(String(member_profile.portrait_path))
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = _build_display_name(member_unit_id)
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(name_label)

		var member_status_label := Label.new()
		member_status_label.text = _build_member_boarding_status_text(fireteam_id, member_unit_id)
		member_status_label.add_theme_font_size_override("font_size", 9)
		member_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(member_status_label)

		var progress_bar := ProgressBar.new()
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = _build_member_boarding_progress_value(fireteam_id, member_unit_id)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
		progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		member_vbox.add_child(progress_bar)


func _on_close_overlay_button_pressed() -> void:
	_character_overlay_open = false
	_update_character_overlay_visibility()


func _build_fireteam_member_names(fireteam_id: String) -> PackedStringArray:
	var member_names: PackedStringArray = []
	for unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		member_names.append(_build_display_name(unit_id))

	return member_names


func _get_member_unit_ids_for_fireteam(fireteam_id: String) -> PackedStringArray:
	var member_ids: PackedStringArray = []
	for unit_index in range(_selected_unit_ids.size()):
		var assigned_fireteam_id: String = ""
		if unit_index < _selected_fireteam_ids.size():
			assigned_fireteam_id = String(_selected_fireteam_ids[unit_index]).strip_edges().to_lower()
		if assigned_fireteam_id != fireteam_id:
			continue
		member_ids.append(String(_selected_unit_ids[unit_index]))
	return member_ids


func _format_member_names(member_names: PackedStringArray) -> String:
	if member_names.is_empty():
		return "none"
	return ", ".join(member_names)


func _get_selected_fireteam_id_for_unit(unit_id: String) -> String:
	var unit_index: int = _selected_unit_ids.find(unit_id)
	if unit_index < 0 or unit_index >= _selected_fireteam_ids.size():
		return ""
	return String(_selected_fireteam_ids[unit_index]).strip_edges().to_lower()


func _set_selected_fireteam_for_unit(unit_id: String, next_fireteam_id: String) -> void:
	var unit_index: int = _selected_unit_ids.find(unit_id)
	if unit_index < 0:
		return

	var normalized_fireteam_id: String = _normalize_fireteam_id(next_fireteam_id)
	if unit_index >= _selected_fireteam_ids.size():
		_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)

	if String(_selected_fireteam_ids[unit_index]).strip_edges().to_lower() == normalized_fireteam_id:
		return

	_selected_fireteam_ids[unit_index] = normalized_fireteam_id
	_sanitize_fireteam_state()
	_restart_dropship_cycle()
	_rebuild_profiles()
	_refresh_ui_state()


func _normalize_selected_fireteam_ids(selected_fireteam_ids: PackedStringArray) -> PackedStringArray:
	var normalized_fireteam_ids: PackedStringArray = []
	for unit_index in range(_selected_unit_ids.size()):
		var fireteam_id: String = ""
		if unit_index < selected_fireteam_ids.size():
			fireteam_id = _normalize_fireteam_id(String(selected_fireteam_ids[unit_index]))
		normalized_fireteam_ids.append(fireteam_id)
	return normalized_fireteam_ids


func _normalize_fireteam_definitions(source_definitions: Array, selected_fireteam_ids: PackedStringArray) -> Array:
	var normalized_definitions: Array = []
	var seen_ids: Dictionary = {}

	var ft1_definition := _make_fireteam_definition("ft1", "FT1")
	for definition_variant in source_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = definition_variant
		if _normalize_fireteam_id(String(definition.get("id", ""))) != "ft1":
			continue
		ft1_definition = _coerce_fireteam_definition(definition)
		break
	normalized_definitions.append(ft1_definition)
	seen_ids["ft1"] = true

	for definition_variant in source_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var coerced_definition: Dictionary = _coerce_fireteam_definition(definition_variant)
		var fireteam_id: String = String(coerced_definition.get("id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or seen_ids.has(fireteam_id):
			continue
		normalized_definitions.append(coerced_definition)
		seen_ids[fireteam_id] = true

	for fireteam_id_variant in selected_fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or seen_ids.has(fireteam_id):
			continue
		normalized_definitions.append(_make_fireteam_definition(fireteam_id, fireteam_id.to_upper()))
		seen_ids[fireteam_id] = true

	return normalized_definitions


func _build_transfer_signature(selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, fireteam_definitions: Array) -> String:
	var serialized_definitions: Array = []
	for definition_variant in fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		serialized_definitions.append(Dictionary(definition_variant).duplicate(true))
	return JSON.stringify(
		{
			"selected_unit_ids": Array(selected_unit_ids),
			"selected_fireteam_ids": Array(selected_fireteam_ids),
			"fireteam_definitions": serialized_definitions,
		},
		"",
		false,
		true
	)


func _coerce_fireteam_definition(definition_variant) -> Dictionary:
	var definition: Dictionary = definition_variant if typeof(definition_variant) == TYPE_DICTIONARY else {}
	var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
	if fireteam_id.is_empty():
		return {}

	return _make_fireteam_definition(
		fireteam_id,
		String(definition.get("label", fireteam_id.to_upper())),
		bool(definition.get("respawn_enabled", false)),
		String(definition.get("loadout", "medium")),
		String(definition.get("lead_unit_id", "")),
		definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
	)


func _make_fireteam_definition(
	fireteam_id: String,
	label: String,
	respawn_enabled: bool = false,
	loadout: String = "medium",
	lead_unit_id: String = "",
	member_loadouts: Dictionary = {}
) -> Dictionary:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	return {
		"id": normalized_fireteam_id,
		"label": label.strip_edges() if not label.strip_edges().is_empty() else normalized_fireteam_id.to_upper(),
		"respawn_enabled": respawn_enabled,
		"loadout": _normalize_loadout_id(loadout),
		"lead_unit_id": lead_unit_id.strip_edges(),
		"member_loadouts": member_loadouts.duplicate(true),
	}


func _normalize_fireteam_id(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if normalized_value.begins_with("ft") and normalized_value.length() > 2:
		var suffix: String = normalized_value.substr(2)
		if suffix.is_valid_int() and int(suffix) >= 1:
			return "ft%d" % int(suffix)
	return ""


func _normalize_loadout_id(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if normalized_value == "standard":
		return "medium"
	if normalized_value == "light" or normalized_value == "medium" or normalized_value == "heavy":
		return normalized_value
	return "medium"


func _normalize_weapon_id(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	match normalized_value:
		"smg":
			return normalized_value
		"medic_tool", "medic-tool", "medic tool":
			return "medictool"
		"medictool":
			return normalized_value
		_:
			return DEFAULT_MEMBER_WEAPON


func _make_member_loadout(armor_id: String, weapon_1_id: String, weapon_2_id: String) -> Dictionary:
	return {
		"armor": _normalize_loadout_id(armor_id),
		"weapon_1": _normalize_weapon_id(weapon_1_id),
		"weapon_2": _normalize_weapon_id(weapon_2_id),
	}


func _sanitize_fireteam_state() -> void:
	var sanitized_definitions: Array = []
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue

		var definition: Dictionary = _coerce_fireteam_definition(definition_variant)
		if definition.is_empty():
			continue

		var fireteam_id: String = String(definition.get("id", "")).strip_edges().to_lower()
		var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
		var default_armor_id: String = _normalize_loadout_id(String(definition.get("loadout", "medium")))
		var existing_member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
		var sanitized_member_loadouts: Dictionary = {}
		for member_unit_id in member_ids:
			var existing_loadout: Dictionary = existing_member_loadouts.get(member_unit_id, {}) if typeof(existing_member_loadouts.get(member_unit_id, {})) == TYPE_DICTIONARY else {}
			sanitized_member_loadouts[member_unit_id] = _make_member_loadout(
				String(existing_loadout.get("armor", default_armor_id)),
				String(existing_loadout.get("weapon_1", existing_loadout.get("weapon", DEFAULT_MEMBER_WEAPON))),
				String(existing_loadout.get("weapon_2", DEFAULT_MEMBER_WEAPON))
			)

		var lead_unit_id: String = String(definition.get("lead_unit_id", "")).strip_edges()
		if lead_unit_id.is_empty() or not member_ids.has(lead_unit_id):
			lead_unit_id = String(member_ids[0]) if not member_ids.is_empty() else ""

		definition["loadout"] = default_armor_id
		definition["lead_unit_id"] = lead_unit_id
		definition["member_loadouts"] = sanitized_member_loadouts
		sanitized_definitions.append(definition)

	_fireteam_definitions = sanitized_definitions
	_sanitize_staging_state()


func _get_fireteam_lead_unit_id(fireteam_id: String) -> String:
	return String(_get_fireteam_definition(fireteam_id).get("lead_unit_id", "")).strip_edges()


func _get_member_loadout(fireteam_id: String, unit_id: String) -> Dictionary:
	var definition: Dictionary = _get_fireteam_definition(fireteam_id)
	if definition.is_empty():
		return _make_member_loadout("medium", DEFAULT_MEMBER_WEAPON, DEFAULT_MEMBER_WEAPON)
	var member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
	if not member_loadouts.has(unit_id) or typeof(member_loadouts.get(unit_id, {})) != TYPE_DICTIONARY:
		return _make_member_loadout(String(definition.get("loadout", "medium")), DEFAULT_MEMBER_WEAPON, DEFAULT_MEMBER_WEAPON)
	var member_loadout: Dictionary = member_loadouts.get(unit_id, {})
	return _make_member_loadout(
		String(member_loadout.get("armor", definition.get("loadout", "medium"))),
		String(member_loadout.get("weapon_1", member_loadout.get("weapon", DEFAULT_MEMBER_WEAPON))),
		String(member_loadout.get("weapon_2", DEFAULT_MEMBER_WEAPON))
	)


func _set_member_loadout(fireteam_id: String, unit_id: String, armor_id: String, weapon_1_id: String, weapon_2_id: String) -> void:
	var definition_index: int = _find_fireteam_definition_index(fireteam_id)
	if definition_index < 0:
		return

	var definition: Dictionary = _fireteam_definitions[definition_index]
	var member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
	var existing_loadout: Dictionary = member_loadouts.get(unit_id, {}) if typeof(member_loadouts.get(unit_id, {})) == TYPE_DICTIONARY else {}
	member_loadouts[unit_id] = _make_member_loadout(
		armor_id if not armor_id.is_empty() else String(existing_loadout.get("armor", definition.get("loadout", "medium"))),
		weapon_1_id if not weapon_1_id.is_empty() else String(existing_loadout.get("weapon_1", existing_loadout.get("weapon", DEFAULT_MEMBER_WEAPON))),
		weapon_2_id if not weapon_2_id.is_empty() else String(existing_loadout.get("weapon_2", DEFAULT_MEMBER_WEAPON))
	)
	definition["member_loadouts"] = member_loadouts
	_fireteam_definitions[definition_index] = definition
	_sanitize_fireteam_state()
	_refresh_ui_state()


func _populate_armor_option_button(option_button: OptionButton, selected_armor_id: String) -> void:
	option_button.clear()
	for armor_id in PackedStringArray(["light", "medium", "heavy"]):
		option_button.add_item(armor_id.capitalize())
		if armor_id == _normalize_loadout_id(selected_armor_id):
			option_button.select(option_button.item_count - 1)


func _populate_weapon_option_button(option_button: OptionButton, selected_weapon_id: String) -> void:
	option_button.clear()
	for option in [
		{"id": "smg", "label": "SMG"},
		{"id": "medictool", "label": "Medictool"},
	]:
		var weapon_id: String = String(option["id"])
		var preview_texture := _get_weapon_preview_texture(weapon_id)
		if preview_texture != null:
			option_button.add_icon_item(preview_texture, String(option["label"]))
		else:
			option_button.add_item(String(option["label"]))
		option_button.set_item_metadata(option_button.item_count - 1, weapon_id)
		if String(option["id"]) == _normalize_weapon_id(selected_weapon_id):
			option_button.select(option_button.item_count - 1)


func _build_weapon_label(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return "SMG"
		"medictool":
			return "Medictool"
		_:
			return "SMG"


func _armor_id_from_index(index: int) -> String:
	match index:
		0:
			return "light"
		1:
			return "medium"
		2:
			return "heavy"
		_:
			return "medium"


func _weapon_id_from_index(index: int) -> String:
	match index:
		0:
			return "smg"
		1:
			return "medictool"
		_:
			return DEFAULT_MEMBER_WEAPON


func _build_weapon_slot_control(slot_name: String, selected_weapon_id: String, fireteam_id: String, member_unit_id: String, slot_index: int) -> Control:
	var slot_box := VBoxContainer.new()
	slot_box.name = "%sSlot" % slot_name
	slot_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_box.add_theme_constant_override("separation", 2)

	var weapon_select := OptionButton.new()
	weapon_select.name = "%sSelect" % slot_name
	weapon_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_select.custom_minimum_size = Vector2(70.0, 0.0)
	weapon_select.add_theme_font_size_override("font_size", 9)
	_populate_weapon_option_button(weapon_select, selected_weapon_id)
	META_UI_SKIN_SCRIPT.style_secondary_button(weapon_select)
	if slot_index == 1:
		if not weapon_select.item_selected.is_connected(_on_member_weapon_1_selected.bind(fireteam_id, member_unit_id)):
			weapon_select.item_selected.connect(_on_member_weapon_1_selected.bind(fireteam_id, member_unit_id))
	else:
		if not weapon_select.item_selected.is_connected(_on_member_weapon_2_selected.bind(fireteam_id, member_unit_id)):
			weapon_select.item_selected.connect(_on_member_weapon_2_selected.bind(fireteam_id, member_unit_id))
	slot_box.add_child(weapon_select)

	var preview_rect := TextureRect.new()
	preview_rect.name = "%sPreview" % slot_name
	preview_rect.custom_minimum_size = Vector2(56.0, 24.0)
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var preview_path: String = _get_weapon_preview_path(selected_weapon_id)
	preview_rect.texture = _get_weapon_preview_texture(selected_weapon_id)
	preview_rect.visible = preview_rect.texture != null
	preview_rect.set_meta("weapon_id", _normalize_weapon_id(selected_weapon_id))
	preview_rect.set_meta("weapon_preview_path", preview_path)
	slot_box.add_child(preview_rect)

	return slot_box


func _get_weapon_preview_path(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return SMG_BLASTER_PREVIEW_PATH
		"medictool":
			return MEDICTOOL_BLASTER_PREVIEW_PATH
		_:
			return ""


func _get_weapon_preview_texture(weapon_id: String) -> Texture2D:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return SMG_BLASTER_PREVIEW_TEXTURE
		"medictool":
			return MEDICTOOL_BLASTER_PREVIEW_TEXTURE
		_:
			return null


func _apply_loadout_member_row_style(panel: PanelContainer, is_lead: bool) -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	if is_lead:
		stylebox.bg_color = Color(0.20, 0.23, 0.28, 1.0)
		stylebox.border_color = Color(0.64, 0.69, 0.76, 1.0)
	else:
		stylebox.bg_color = Color(0.14, 0.16, 0.19, 1.0)
		stylebox.border_color = Color(0.36, 0.40, 0.46, 1.0)
	panel.add_theme_stylebox_override("panel", stylebox)


func _find_fireteam_definition_index(fireteam_id: String) -> int:
	for definition_index in range(_fireteam_definitions.size()):
		if typeof(_fireteam_definitions[definition_index]) != TYPE_DICTIONARY:
			continue
		if String((_fireteam_definitions[definition_index] as Dictionary).get("id", "")).strip_edges().to_lower() == fireteam_id:
			return definition_index
	return -1


func _get_fireteam_definition(fireteam_id: String) -> Dictionary:
	var definition_index: int = _find_fireteam_definition_index(fireteam_id)
	if definition_index < 0:
		return {}
	return (_fireteam_definitions[definition_index] as Dictionary).duplicate(true)


func _get_fireteam_label(fireteam_id: String) -> String:
	var definition: Dictionary = _get_fireteam_definition(fireteam_id)
	if definition.is_empty():
		return fireteam_id.to_upper()
	return String(definition.get("label", fireteam_id.to_upper()))


func _build_next_fireteam_id() -> String:
	var highest_suffix: int = 1
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var fireteam_id: String = String((definition_variant as Dictionary).get("id", "")).strip_edges().to_lower()
		if not fireteam_id.begins_with("ft") or fireteam_id.length() <= 2:
			continue
		var suffix: String = fireteam_id.substr(2)
		if suffix.is_valid_int():
			highest_suffix = maxi(highest_suffix, int(suffix))
	return "ft%d" % (highest_suffix + 1)


func _ensure_focused_unit_id() -> void:
	if not _focused_unit_id.is_empty() and (_selected_unit_ids.has(_focused_unit_id) or _profiles_by_id.has(_focused_unit_id)):
		return
	_focused_unit_id = String(_selected_unit_ids[0]) if not _selected_unit_ids.is_empty() else ""


func _ensure_focused_fireteam_id() -> void:
	if not _focused_fireteam_id.is_empty() and _find_fireteam_definition_index(_focused_fireteam_id) >= 0:
		return
	_focused_fireteam_id = "ft1"


func _apply_fireteam_row_style(panel: PanelContainer, is_selected: bool) -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	if is_selected:
		stylebox.bg_color = Color(0.20, 0.23, 0.28, 1.0)
		stylebox.border_color = Color(0.64, 0.69, 0.76, 1.0)
	else:
		stylebox.bg_color = Color(0.14, 0.16, 0.19, 1.0)
		stylebox.border_color = Color(0.36, 0.40, 0.46, 1.0)
	panel.add_theme_stylebox_override("panel", stylebox)


func _clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _get_team_state_for_unit(unit_id: String) -> Dictionary:
	if unit_id.is_empty() or _last_mission_result.is_empty():
		return {}

	for member_state_variant in _last_mission_result.get("team_states", []):
		if typeof(member_state_variant) != TYPE_DICTIONARY:
			continue
		var member_state: Dictionary = member_state_variant
		if String(member_state.get("unit_id", "")).strip_edges() != unit_id:
			continue
		return member_state.duplicate(true)

	return {}


func _build_unit_status_text(team_state: Dictionary) -> String:
	if team_state.is_empty():
		return "READY FOR MISSION"

	var vital_state: String = String(team_state.get("vital_state", "")).strip_edges().to_lower()
	match vital_state:
		"", "ready":
			return "READY"
		"fit":
			return "FIT"
		"down":
			return "DOWN"
		"bleedout":
			return "BLEEDOUT"
		"respawning":
			return "RESPAWNING"
		_:
			return "UNKNOWN"


func _build_unit_secondary_text(team_state: Dictionary, unit_id: String) -> String:
	var fireteam_text: String = _build_unit_location_text(unit_id)
	var respawn_text: String = _build_unit_respawn_text(unit_id)
	if team_state.is_empty():
		return "%s | %s" % [fireteam_text, respawn_text]

	var health_points: int = int(team_state.get("health_points", -1))
	if health_points >= 0:
		return "%s | %s | HP %d" % [fireteam_text, respawn_text, health_points]
	return "%s | %s | Return logged" % [fireteam_text, respawn_text]


func _build_unit_location_text(unit_id: String) -> String:
	if _is_unit_in_transit_to_fob(unit_id):
		return "Loc: Transit To FOB / ETA %ds" % _get_unit_transit_eta_seconds(unit_id)
	var craft_state: Dictionary = _find_transport_craft_state_by_pilot(unit_id)
	if not craft_state.is_empty():
		var craft_name: String = String(craft_state.get("display_name", "craft")).strip_edges()
		if bool(craft_state.get("is_in_transit", false)):
			return "Loc: %s / Pilot / Transit" % craft_name
		return "Loc: %s / Pilot" % craft_name
	var assigned_fireteam_id := _get_selected_fireteam_id_for_unit(unit_id)
	if assigned_fireteam_id.is_empty():
		return "Loc: FOB / Pool"

	var location_text := _build_fireteam_display_text(assigned_fireteam_id)
	if _boarded_fireteam_ids.has(assigned_fireteam_id):
		return "Loc: Rover / %s / Boarded" % location_text
	if _dropship_phase == "boarding" and assigned_fireteam_id == _get_boarding_fireteam_id():
		return "Loc: Rover / %s / Boarding" % location_text
	if _boarding_order.has(assigned_fireteam_id):
		return "Loc: Rover / %s / Wait Zone" % location_text
	if bool(_get_fireteam_definition(assigned_fireteam_id).get("respawn_enabled", false)):
		return "Loc: FOB / %s / Respawn" % location_text
	if assigned_fireteam_id == _loadout_staged_fireteam_id:
		return "Loc: FOB / %s / Loadout" % location_text
	return "Loc: FOB / %s" % location_text


func _build_unit_respawn_text(unit_id: String) -> String:
	var assigned_fireteam_id := _get_selected_fireteam_id_for_unit(unit_id)
	if assigned_fireteam_id.is_empty():
		return "Respawn: off"
	return "Respawn: %s" % ("FOB" if bool(_get_fireteam_definition(assigned_fireteam_id).get("respawn_enabled", false)) else "off")


func _render_dropship_fireteam_cards(container: VBoxContainer) -> void:
	_clear_container(container)
	var visible_craft_states: Array = _get_visible_transport_craft_states()
	if visible_craft_states.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No Homebase craft visible in FOB yet."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		container.add_child(empty_label)
		return

	for craft_state_variant in visible_craft_states:
		var craft_state: Dictionary = Dictionary(craft_state_variant)
		var craft_card := _build_transport_craft_card(craft_state)
		if craft_card == null:
			continue
		container.add_child(craft_card)


func _render_staging_fireteam_card(container: VBoxContainer, fireteam_id: String, empty_text: String, source_context: String, member_ids: PackedStringArray = [], lead_unit_id: String = "") -> void:
	_clear_container(container)
	var normalized_fireteam_id := _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		var empty_label := Label.new()
		empty_label.text = empty_text
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 9)
		container.add_child(empty_label)
		return

	var fireteam_card := _create_fireteam_card(normalized_fireteam_id, source_context)
	if fireteam_card == null:
		return
	if source_context == "respawn_staging":
		_render_fireteam_card_member_loadout_rows(fireteam_card.get_member_host(), normalized_fireteam_id, member_ids, lead_unit_id)
	container.add_child(fireteam_card)


func _create_fireteam_card(fireteam_id: String, source_context: String = "fireteam_list") -> FOBFireteamCard:
	var definition := _get_fireteam_definition(fireteam_id)
	if definition.is_empty():
		return null

	var fireteam_card: FOBFireteamCard = FOB_FIRETEAM_CARD_SCRIPT.new()
	fireteam_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fireteam_card.setup_card(
		fireteam_id,
		String(definition.get("label", fireteam_id.to_upper())),
		fireteam_id == _focused_fireteam_id,
		bool(definition.get("respawn_enabled", false)),
		String(definition.get("loadout", "medium")),
		"Lead: %s | Members: %s" % [_build_display_name(String(definition.get("lead_unit_id", ""))), _format_member_names(_build_fireteam_member_names(fireteam_id))],
		source_context
	)
	if not fireteam_card.card_pressed.is_connected(_on_fireteam_card_pressed):
		fireteam_card.card_pressed.connect(_on_fireteam_card_pressed)
	if not fireteam_card.rename_committed.is_connected(_on_fireteam_card_label_committed):
		fireteam_card.rename_committed.connect(_on_fireteam_card_label_committed)
	if not fireteam_card.unit_dropped.is_connected(_on_fireteam_card_unit_dropped):
		fireteam_card.unit_dropped.connect(_on_fireteam_card_unit_dropped)
	return fireteam_card


func _build_transport_craft_card(craft_state: Dictionary) -> Control:
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return null
	var is_selected: bool = craft_id == _dropship_transport_craft_id
	var is_in_transit: bool = bool(craft_state.get("is_in_transit", false))
	var is_boardable: bool = bool(craft_state.get("is_boardable", false))
	var can_stage_fireteams: bool = _can_stage_fireteam_into_craft(craft_state)
	var craft_card: PanelContainer = PanelContainer.new()
	craft_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if can_stage_fireteams:
		craft_card.set_script(FOB_DROP_PANEL_SCRIPT)
		craft_card.drop_kind = "dropship|%s" % craft_id
		craft_card.fireteam_dropped.connect(_on_staging_fireteam_dropped)
	var is_waiting_on_mission: bool = bool(craft_state.get("mission_waiting", false))
	var is_transit_to_mission: bool = bool(craft_state.get("mission_transit_to_map", false))
	var is_transit_to_fob: bool = bool(craft_state.get("mission_transit_to_fob", false))
	var is_launch_ready_in_fob: bool = craft_id == _mission_launch_ready_craft_id and _has_boarded_mission_payload() and not is_waiting_on_mission and not is_transit_to_mission and not is_transit_to_fob
	var pilot_unit_id: String = String(craft_state.get("pilot_unit_id", "")).strip_edges()
	TRANSPORT_CRAFT_CARD_UI_SCRIPT.apply_card_state(
		craft_card,
		{
			"selected": is_selected,
			"in_transit": is_in_transit,
			"can_stage": can_stage_fireteams,
			"title_text": UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title(_build_transport_craft_title(craft_state)),
			"ship_texture": _get_transport_craft_texture(craft_state),
			"pilot_profile": _profiles_by_id.get(pilot_unit_id, null),
			"pilot_text": _build_transport_craft_pilot_text(craft_state),
			"pilot_source_context": "transport_craft_pilot",
			"pilot_selected": pilot_unit_id == _focused_unit_id,
			"pilot_disabled": is_in_transit,
			"pilot_card_pressed": Callable(self, "_on_operator_card_pressed"),
			"pilot_card_open_requested": Callable(self, "_on_operator_card_open_requested"),
			"info_lines": [
				_build_transport_craft_cargo_text(craft_state),
				_build_transport_craft_status_line(craft_state),
			],
			"progress_visible": is_in_transit,
			"progress_value": _build_transport_craft_progress_value(craft_state),
			"primary_action": {
				"visible": true,
				"text": "Board",
				"disabled": not _can_start_boarding_for_craft(craft_state),
				"minimum_width": 52.0,
				"ready_style": true,
				"callback": Callable(self, "_on_transport_craft_boarding_requested").bind(craft_id),
			},
			"secondary_action": {
				"visible": true,
				"text": "Waiting" if is_waiting_on_mission else "En Route" if is_transit_to_mission else "Return" if is_transit_to_fob else "Ready" if is_launch_ready_in_fob else "Send",
				"disabled": is_launch_ready_in_fob or is_waiting_on_mission or is_transit_to_mission or is_transit_to_fob or not _can_mark_transport_craft_launch_ready(craft_state),
				"minimum_width": 58.0,
				"ready_style": true,
				"callback": Callable(self, "_on_transport_craft_mission_stage_requested").bind(craft_id),
			},
		}
	)

	var extra_content_host: VBoxContainer = TRANSPORT_CRAFT_CARD_UI_SCRIPT.get_extra_content_host(craft_card)

	if is_boardable:
		var drop_label := Label.new()
		if is_selected and not _dropship_staged_fireteam_ids.is_empty():
			if _get_transport_craft_remaining_capacity(craft_state) <= 0:
				drop_label.text = "Full %d/%d NPC assigned + pilot" % [_get_transport_craft_staged_member_count(craft_id), DROPSHIP_NPC_CAPACITY]
			else:
				drop_label.text = "Assigned fireteams | %d/%d NPC + pilot" % [_get_transport_craft_staged_member_count(craft_id), DROPSHIP_NPC_CAPACITY]
		else:
			drop_label.text = "Drop FT here to board this ship (max 6 NPC + pilot)"
		drop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		drop_label.add_theme_font_size_override("font_size", 9)
		extra_content_host.add_child(drop_label)
		if is_selected and not _boarding_order.is_empty():
			for fireteam_id_variant in _boarding_order:
				var fireteam_id: String = String(fireteam_id_variant)
				var fireteam_card := _create_fireteam_card(fireteam_id, "dropship_wait")
				if fireteam_card == null:
					continue
				_render_dropship_member_rows(fireteam_card.get_member_host(), fireteam_id, _get_member_unit_ids_for_fireteam(fireteam_id))
				extra_content_host.add_child(fireteam_card)

	return craft_card


func _build_transport_craft_title(craft_state: Dictionary) -> String:
	var craft_name: String = String(craft_state.get("display_name", "craft")).strip_edges()
	if bool(craft_state.get("mission_waiting", false)):
		return "%s · MAP" % craft_name
	if bool(craft_state.get("mission_transit_to_map", false)):
		return "%s · HANDOVER" % craft_name
	if bool(craft_state.get("mission_transit_to_fob", false)):
		return "%s · RETURN" % craft_name
	if bool(craft_state.get("is_in_transit", false)):
		return "%s · TRANSIT" % craft_name
	if bool(craft_state.get("is_boardable", false)):
		return "%s · FOB" % craft_name
	return "%s · CARGO" % craft_name


func _build_transport_craft_pilot_text(craft_state: Dictionary) -> String:
	return "Pilot: %s" % _build_optional_text(String(craft_state.get("pilot_display_name", "")).strip_edges(), "none")


func _build_transport_craft_cargo_text(craft_state: Dictionary) -> String:
	var cargo_name: String = String(craft_state.get("cargo_display_name", "")).strip_edges()
	if cargo_name.is_empty():
		return ""
	return "Cargo: %s" % cargo_name


func _build_transport_craft_status_line(craft_state: Dictionary) -> String:
	if bool(craft_state.get("mission_waiting", false)):
		return "Status: Holding on mission map | waiting for Drop"
	if bool(craft_state.get("mission_transit_to_map", false)):
		return "Status: ETA mission map %ds" % int(craft_state.get("transfer_eta_seconds", 0))
	if bool(craft_state.get("mission_transit_to_fob", false)):
		return "Status: returning to FOB | ETA %ds" % int(craft_state.get("transfer_eta_seconds", 0))
	if bool(craft_state.get("is_in_transit", false)):
		return "Status: inbound to FOB | ETA %ds | 6 NPC + pilot" % int(craft_state.get("transfer_eta_seconds", 0))
	if String(craft_state.get("craft_id", "")).strip_edges() == _mission_launch_ready_craft_id and _has_boarded_mission_payload():
		return "Status: staged in FOB | start mission to launch"
	if bool(craft_state.get("is_boardable", false)):
		return "Status: docked in FOB | %s" % _build_transport_craft_capacity_text(craft_state)
	return "Status: visible in FOB as delivered cargo state"


func _build_transport_craft_capacity_text(craft_state: Dictionary) -> String:
	if not bool(craft_state.get("is_boardable", false)):
		return ""
	var staged_member_count: int = _get_transport_craft_staged_member_count(String(craft_state.get("craft_id", "")).strip_edges())
	if staged_member_count >= DROPSHIP_NPC_CAPACITY:
		return "Full %d/%d NPC + pilot" % [staged_member_count, DROPSHIP_NPC_CAPACITY]
	return "Capacity %d/%d NPC + pilot" % [staged_member_count, DROPSHIP_NPC_CAPACITY]


func _build_transport_craft_progress_value(craft_state: Dictionary) -> float:
	if bool(craft_state.get("is_in_transit", false)):
		return float(craft_state.get("transfer_progress", 0.0))
	return 100.0


func _get_transport_craft_texture(craft_state: Dictionary) -> Texture2D:
	if String(craft_state.get("craft_type", "dropship")).strip_edges().to_lower() == "dropship":
		if bool(craft_state.get("mission_transit_to_map", false)):
			return DROPSHIP_TEXTURE_SE
		if bool(craft_state.get("mission_transit_to_fob", false)):
			return DROPSHIP_TEXTURE_NW
		if bool(craft_state.get("is_in_transit", false)):
			return DROPSHIP_TEXTURE_NW
		if bool(craft_state.get("mission_waiting", false)):
			return DROPSHIP_TEXTURE_SE
	var texture_path: String = String(craft_state.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return DROPSHIP_FOB_TEXTURE if bool(craft_state.get("is_boardable", false)) else DROPSHIP_TEXTURE_NW
	var resource: Resource = load(texture_path)
	return resource as Texture2D


func _get_visible_transport_craft_states() -> Array:
	var visible_states: Array = []
	for craft_state_variant in _transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = craft_state_variant
		if not bool(craft_state.get("visible_in_fob", false)):
			continue
		visible_states.append(craft_state)
	return visible_states


func _get_transport_craft_state(craft_id: String) -> Dictionary:
	for craft_state_variant in _transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = craft_state_variant
		if String(craft_state.get("craft_id", "")).strip_edges() == craft_id:
			return craft_state.duplicate(true)
	return {}


func _get_selected_transport_craft_state() -> Dictionary:
	var selected_craft_state: Dictionary = _get_transport_craft_state(_dropship_transport_craft_id)
	if not selected_craft_state.is_empty():
		return selected_craft_state
	var visible_states: Array = _get_visible_transport_craft_states()
	if visible_states.is_empty():
		return {}
	return Dictionary(visible_states[0]).duplicate(true)


func _get_transport_craft_staged_member_count(craft_id: String) -> int:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_craft_id != _dropship_transport_craft_id:
		return 0
	var staged_member_count: int = 0
	for fireteam_id_variant in _dropship_staged_fireteam_ids:
		staged_member_count += _get_member_unit_ids_for_fireteam(String(fireteam_id_variant)).size()
	return staged_member_count


func _get_transport_craft_remaining_capacity(craft_state: Dictionary) -> int:
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	return maxi(DROPSHIP_NPC_CAPACITY - _get_transport_craft_staged_member_count(craft_id), 0)


func _has_transport_craft_capacity_for_fireteam(craft_state: Dictionary, fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return _get_transport_craft_remaining_capacity(craft_state) > 0
	if _dropship_staged_fireteam_ids.has(normalized_fireteam_id):
		return true
	var member_count: int = _get_member_unit_ids_for_fireteam(normalized_fireteam_id).size()
	if member_count <= 0:
		return false
	return member_count <= _get_transport_craft_remaining_capacity(craft_state)


func _can_stage_fireteam_into_craft(craft_state: Dictionary, fireteam_id: String = "") -> bool:
	if craft_state.is_empty():
		return false
	if bool(craft_state.get("is_in_transit", false)):
		return false
	if not bool(craft_state.get("is_boardable", false)):
		return false
	return _has_transport_craft_capacity_for_fireteam(craft_state, fireteam_id)


func _can_mark_transport_craft_launch_ready(craft_state: Dictionary) -> bool:
	if craft_state.is_empty():
		return false
	if not _has_boarded_mission_payload():
		return false
	if String(craft_state.get("craft_id", "")).strip_edges() != _dropship_transport_craft_id:
		return false
	if not bool(craft_state.get("is_boardable", false)):
		return false
	return not bool(craft_state.get("mission_waiting", false)) and not bool(craft_state.get("mission_transit_to_map", false)) and not bool(craft_state.get("mission_transit_to_fob", false))


func _can_request_homebase_mission_start(craft_state: Dictionary) -> bool:
	if craft_state.is_empty():
		return false
	if not _has_boarded_mission_payload():
		return false
	return bool(craft_state.get("mission_waiting", false))


func _can_start_boarding_for_craft(craft_state: Dictionary) -> bool:
	if craft_state.is_empty():
		return false
	if String(craft_state.get("craft_id", "")).strip_edges() != _dropship_transport_craft_id:
		return false
	if _dropship_phase == "boarding":
		return false
	return _dropship_phase == "ready" and not _boarding_order.is_empty()


func _on_transport_craft_selected(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_dropship_transport_craft_id = normalized_craft_id
	_refresh_ui_state()


func _on_transport_craft_boarding_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_dropship_transport_craft_id = normalized_craft_id
	_on_start_boarding_button_pressed()
	_refresh_ui_state()


func _on_transport_craft_mission_stage_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_dropship_transport_craft_id = normalized_craft_id
	var craft_state: Dictionary = _get_transport_craft_state(normalized_craft_id)
	if not _can_mark_transport_craft_launch_ready(craft_state):
		_refresh_ui_state()
		return
	_mission_launch_ready_craft_id = normalized_craft_id
	transport_craft_mission_stage_requested.emit(normalized_craft_id)
	_refresh_ui_state()


func _sanitize_staging_state() -> void:
	_loadout_staged_fireteam_id = _normalize_fireteam_id(_loadout_staged_fireteam_id)
	if _find_fireteam_definition_index(_loadout_staged_fireteam_id) < 0 or _build_fireteam_member_names(_loadout_staged_fireteam_id).is_empty():
		_loadout_staged_fireteam_id = ""

	_respawn_staged_fireteam_id = _normalize_fireteam_id(_respawn_staged_fireteam_id)
	if _find_fireteam_definition_index(_respawn_staged_fireteam_id) < 0 or not bool(_get_fireteam_definition(_respawn_staged_fireteam_id).get("respawn_enabled", false)):
		_respawn_staged_fireteam_id = ""

	var sanitized_dropship_ids: PackedStringArray = []
	for fireteam_id_variant in _dropship_staged_fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or _find_fireteam_definition_index(fireteam_id) < 0:
			continue
		if _build_fireteam_member_names(fireteam_id).is_empty() or sanitized_dropship_ids.has(fireteam_id):
			continue
		sanitized_dropship_ids.append(fireteam_id)
	_dropship_staged_fireteam_ids = sanitized_dropship_ids
	_sanitize_transport_craft_state()
	_trim_dropship_queue_to_capacity()
	_boarding_order = _build_boarding_order()


func _trim_dropship_queue_to_capacity() -> void:
	if _dropship_transport_craft_id.is_empty():
		return
	var remaining_capacity: int = DROPSHIP_NPC_CAPACITY
	var trimmed_queue: PackedStringArray = []
	for fireteam_id_variant in _dropship_staged_fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or trimmed_queue.has(fireteam_id):
			continue
		var member_count: int = _get_member_unit_ids_for_fireteam(fireteam_id).size()
		if member_count <= 0 or member_count > remaining_capacity:
			continue
		trimmed_queue.append(fireteam_id)
		remaining_capacity -= member_count
	_dropship_staged_fireteam_ids = trimmed_queue


func _sanitize_transport_craft_state() -> void:
	var selected_craft_id: String = _dropship_transport_craft_id.strip_edges()
	if selected_craft_id.is_empty():
		var pending_launch_state: Dictionary = _get_transport_craft_state(_mission_launch_ready_craft_id)
		if not _can_request_homebase_mission_start(pending_launch_state) and not bool(pending_launch_state.get("mission_transit_to_map", false)) and not bool(pending_launch_state.get("mission_transit_to_fob", false)):
			_mission_launch_ready_craft_id = ""
		return
	var craft_state: Dictionary = _get_transport_craft_state(selected_craft_id)
	if not craft_state.is_empty() and (bool(craft_state.get("visible_in_fob", false)) or bool(craft_state.get("is_in_transit", false)) or bool(craft_state.get("mission_waiting", false))):
		var launch_ready_state: Dictionary = _get_transport_craft_state(_mission_launch_ready_craft_id)
		if not _can_request_homebase_mission_start(launch_ready_state) and not bool(launch_ready_state.get("mission_transit_to_map", false)) and not bool(launch_ready_state.get("mission_transit_to_fob", false)):
			_mission_launch_ready_craft_id = ""
		return
	_dropship_transport_craft_id = ""
	_dropship_staged_fireteam_ids = PackedStringArray()
	_boarding_order = PackedStringArray()
	_dropship_phase = "idle"
	_mission_launch_ready_craft_id = ""


func _build_fireteam_display_text(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return "UNASSIGNED"
	return _get_fireteam_label(normalized_fireteam_id)


func _build_display_name(unit_id: String) -> String:
	if unit_id.is_empty():
		return "none"
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return unit_id
	return String(profile.display_name)


func _build_optional_text(value: String, fallback: String) -> String:
	if value.strip_edges().is_empty():
		return fallback
	return value


func _build_skill_block_text(profile) -> String:
	var skill_values: Dictionary = {}
	if profile != null and profile.skill_values != null:
		skill_values = Dictionary(profile.skill_values)

	return "Accuracy: %.1f\nSpeed: %.1f\nLeadership: %.1f\nToughness: %.1f" % [
		float(skill_values.get("accuracy", 0.0)),
		float(skill_values.get("speed", 0.0)),
		float(skill_values.get("leadership", 0.0)),
		float(skill_values.get("toughness", 0.0)),
	]


func _build_overlay_status_text(unit_id: String) -> String:
	var craft_state := _find_transport_craft_state_by_pilot(unit_id)
	var assigned_fireteam_id := _get_selected_fireteam_id_for_unit(unit_id)
	var team_state := _get_team_state_for_unit(unit_id)
	var location_text := "%s | %s" % [_build_unit_location_text(unit_id), _build_unit_respawn_text(unit_id)]
	if _is_unit_in_transit_to_fob(unit_id):
		return "Inbound to FOB | %s | Progress %.0f%%" % [location_text, _get_unit_transit_progress(unit_id)]
	if not craft_state.is_empty():
		return "Assigned to %s | %s" % [String(craft_state.get("display_name", "craft")).strip_edges(), location_text]
	if not team_state.is_empty():
		return "%s | %s" % [_build_unit_status_text(team_state), location_text]
	if assigned_fireteam_id.is_empty():
		return "Available in FOB pool | %s" % location_text
	return "Assigned to %s | %s" % [_build_fireteam_display_text(assigned_fireteam_id), location_text]


func _get_transport_craft_pilot_unit_ids() -> PackedStringArray:
	var pilot_unit_ids: PackedStringArray = []
	for craft_state_variant in _transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = craft_state_variant
		var pilot_unit_id: String = String(craft_state.get("pilot_unit_id", "")).strip_edges()
		if pilot_unit_id.is_empty() or pilot_unit_ids.has(pilot_unit_id):
			continue
		pilot_unit_ids.append(pilot_unit_id)
	return pilot_unit_ids


func _get_transit_to_fob_unit_ids() -> PackedStringArray:
	var transit_unit_ids: PackedStringArray = []
	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_data_variant)
		if not bool(unit_data.get("is_transit_to_fob", false)):
			continue
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or transit_unit_ids.has(unit_id):
			continue
		transit_unit_ids.append(unit_id)
	return transit_unit_ids


func _get_available_unit_config(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_data_variant)
		if String(unit_data.get("unit_id", "")).strip_edges() != normalized_unit_id:
			continue
		return unit_data.duplicate(true)
	return {}


func _is_unit_in_transit_to_fob(unit_id: String) -> bool:
	return bool(_get_available_unit_config(unit_id).get("is_transit_to_fob", false))


func _get_unit_transit_progress(unit_id: String) -> float:
	return clampf(float(_get_available_unit_config(unit_id).get("transfer_progress", 0.0)), 0.0, 100.0)


func _get_unit_transit_eta_seconds(unit_id: String) -> int:
	return maxi(int(_get_available_unit_config(unit_id).get("transfer_eta_seconds", 0)), 0)


func _build_transit_to_fob_secondary_text(unit_id: String) -> String:
	return "Loc: Transit To FOB | ETA %ds | Progress %.0f%%" % [_get_unit_transit_eta_seconds(unit_id), _get_unit_transit_progress(unit_id)]


func _find_transport_craft_state_by_pilot(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	for craft_state_variant in _transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = craft_state_variant
		if not bool(craft_state.get("visible_in_fob", false)):
			continue
		if String(craft_state.get("pilot_unit_id", "")).strip_edges() != normalized_unit_id:
			continue
		return craft_state.duplicate(true)
	return {}


func _is_transport_craft_pilot(unit_id: String) -> bool:
	return not _find_transport_craft_state_by_pilot(unit_id).is_empty()


func _build_boarding_progress_value(fireteam_id: String) -> float:
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
	if member_ids.is_empty():
		return 0.0
	var boarded_members: float = float(_count_boarded_members_in_fireteam(fireteam_id))
	var active_member_progress: float = 0.0
	if _dropship_phase == "boarding" and fireteam_id == _get_boarding_fireteam_id() and member_ids.has(_get_boarding_member_id()):
		active_member_progress = 1.0 - (_boarding_seconds / DEFAULT_BOARDING_SECONDS)
	return clampf(((boarded_members + active_member_progress) / float(member_ids.size())) * 100.0, 0.0, 100.0)


func _build_boarding_progress_text(fireteam_id: String) -> String:
	var total_members: int = _get_member_unit_ids_for_fireteam(fireteam_id).size()
	var boarded_members: int = _count_boarded_members_in_fireteam(fireteam_id)
	if _boarded_fireteam_ids.has(fireteam_id):
		return "Boarding: all %d members boarded" % total_members
	match _dropship_phase:
		"incoming":
			return "Boarding: dropship inbound | %d/%d boarded" % [boarded_members, total_members]
		"ready":
			return "Boarding: manual start ready | %d/%d boarded" % [boarded_members, total_members]
		"boarding":
			if fireteam_id == _get_boarding_fireteam_id():
				return "Boarding: %d/%d boarded | active: %s" % [boarded_members, total_members, _build_display_name(_get_boarding_member_id())]
			return "Boarding: queued | %d/%d boarded" % [boarded_members, total_members]
		"boarded":
			return "Boarding: completed | %d/%d boarded" % [boarded_members, total_members]
		_:
			return "Boarding: waiting for dropship"


func _build_dropship_visual_texture(selected_craft_state: Dictionary = {}) -> Texture2D:
	if not selected_craft_state.is_empty():
		return _get_transport_craft_texture(selected_craft_state)
	match _dropship_phase:
		"incoming":
			return DROPSHIP_TEXTURE_NW
		"ready", "boarding", "boarded":
			return DROPSHIP_FOB_TEXTURE
		_:
			return null


func _build_dropship_arrival_progress_value(selected_craft_state: Dictionary = {}) -> float:
	if not selected_craft_state.is_empty():
		return _build_transport_craft_progress_value(selected_craft_state)
	if _dropship_phase == "incoming":
		return clampf((1.0 - (_dropship_eta_seconds / DEFAULT_DROPSHIP_ETA_SECONDS)) * 100.0, 0.0, 100.0)
	if _dropship_phase == "ready" or _dropship_phase == "boarding" or _dropship_phase == "boarded":
		return 100.0
	return 0.0


func _build_dropship_arrival_visual_text(selected_craft_state: Dictionary = {}) -> String:
	if not selected_craft_state.is_empty():
		if bool(selected_craft_state.get("mission_waiting", false)):
			return "%s holding on mission map" % String(selected_craft_state.get("display_name", "craft")).strip_edges()
		if bool(selected_craft_state.get("mission_transit_to_map", false)):
			return "%s outbound to mission" % String(selected_craft_state.get("display_name", "craft")).strip_edges()
		if bool(selected_craft_state.get("mission_transit_to_fob", false)):
			return "%s returning to FOB" % String(selected_craft_state.get("display_name", "craft")).strip_edges()
		if bool(selected_craft_state.get("is_in_transit", false)):
			return "%s inbound" % String(selected_craft_state.get("display_name", "craft")).strip_edges()
		if bool(selected_craft_state.get("is_boardable", false)):
			return "%s at FOB" % String(selected_craft_state.get("display_name", "craft")).strip_edges()
		return "%s visible in FOB" % String(selected_craft_state.get("display_name", "craft")).strip_edges()
	match _dropship_phase:
		"incoming":
			return "Approach to FOB"
		"ready":
			return "craft_speederB_SE at FOB"
		"boarding":
			return "craft_speederB_SE boarding"
		"boarded":
			return "craft_speederB_SE boarded"
		_:
			return "No craft in FOB"


func _build_member_boarding_progress_value(fireteam_id: String, unit_id: String) -> float:
	if _boarded_unit_ids.has(unit_id):
		return 100.0
	if _dropship_phase == "boarding" and fireteam_id == _get_boarding_fireteam_id() and unit_id == _get_boarding_member_id():
		return clampf((1.0 - (_boarding_seconds / DEFAULT_BOARDING_SECONDS)) * 100.0, 0.0, 100.0)
	return 0.0


func _build_member_boarding_status_text(fireteam_id: String, unit_id: String) -> String:
	if _boarded_unit_ids.has(unit_id):
		return "Boarded"
	match _dropship_phase:
		"incoming":
			return "Awaiting dropship"
		"ready":
			return "Ready for manual boarding"
		"boarding":
			if fireteam_id == _get_boarding_fireteam_id() and unit_id == _get_boarding_member_id():
				return "Boarding %.0fs" % _boarding_seconds
			return "Queued"
		"boarded":
			return "Completed"
		_:
			return "Waiting"


func _build_overlay_loadout_text(unit_id: String, profile) -> String:
	if profile == null:
		return "standard kit"
	var assigned_fireteam_id := _get_selected_fireteam_id_for_unit(unit_id)
	if not assigned_fireteam_id.is_empty():
		var member_loadout := _get_member_loadout(assigned_fireteam_id, unit_id)
		return CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_member_loadout(member_loadout, "standard kit")
	return CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_ids(String(profile.armor_id), String(profile.weapon_1_id), String(profile.weapon_2_id), "standard kit")


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null
	var resource: Resource = load(portrait_path)
	return resource as Texture2D
