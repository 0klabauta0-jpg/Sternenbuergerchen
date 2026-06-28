class_name HomebaseTestScreen
extends Control

const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const LOADOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/command/loadout_contract.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const AIRCRAFT_MANAGER_SCRIPT: GDScript = preload("res://scripts/meta/aircraft_manager.gd")
const HOMEBASE_CARD_POOL_SCRIPT: GDScript = preload("res://scripts/meta/homebase_card_pool.gd")
const HOMEBASE_TEAM_DROP_PANEL_SCRIPT: GDScript = preload("res://scripts/meta/homebase_team_drop_panel.gd")
const FOB_DROP_PANEL_SCRIPT: GDScript = preload("res://scripts/meta/fob_drop_panel.gd")
const FOB_FIRETEAM_CARD_SCRIPT: GDScript = preload("res://scripts/meta/fob_fireteam_card.gd")
const HOMEBASE_FIRETEAM_DROP_TARGET_SCRIPT: GDScript = preload("res://scripts/meta/homebase_fireteam_drop_target.gd")
const HOMEBASE_UNIT_DROP_TARGET_SCRIPT: GDScript = preload("res://scripts/meta/homebase_unit_drop_target.gd")
const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const HOVER_SCROLL_BEHAVIOR_SCRIPT: GDScript = preload("res://scripts/ui/hover_scroll_behavior.gd")
const MISSION_BRIEFING_PANEL_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_briefing_panel_presenter.gd")
const MISSION_BRIEFING_MINIMAP_VISUAL_SCRIPT: GDScript = preload("res://scripts/ui/mission_briefing_minimap_visual.gd")
const FLIGHTDECK_PLATFORM_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/platform_large_NW.png")
const HOMEBASE_OPERATOR_CARD_SIZE := Vector2(316.0, 66.0)
const HOMEBASE_STAGED_CARD_SIZE := Vector2(316.0, 66.0)
const HOMEBASE_TRANSFER_GHOST_CARD_SIZE := Vector2(316.0, 74.0)
const HOMEBASE_SHIPCARD_COMPACT_WIDTH := 404.0
const HOMEBASE_SHIPCARD_IMAGE_SIZE := Vector2(128.0, 84.0)
const HOMEBASE_SHIPCARD_BUTTON_SIZE := Vector2(94.0, 62.0)
const HOMEBASE_SHIPCARD_IMAGE_OFFSET := Vector2(-28.0, -18.0)
const HOMEBASE_FIRETEAM_INLINE_LOADOUT_SELECTOR_SIZE := Vector2(70.0, 20.0)
const HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE := Vector2i(18, 14)
const HOMEBASE_DIRECT_AVERAGE_BOARDING_SECONDS_PER_OPERATOR := 4.0
const HOMEBASE_DIRECT_MIN_BOARDING_SECONDS_PER_OPERATOR := 2.6
const HOMEBASE_DIRECT_MAX_BOARDING_SECONDS_PER_OPERATOR := 5.4
const HOMEBASE_DIRECT_BOARDING_UI_REFRESH_SECONDS := 0.25
const HOMEBASE_DEFAULT_FIRETEAM_ID := "ft1"
const HOMEBASE_DEFAULT_LOADOUT_ID := "medium"
const HOMEBASE_DEFAULT_PRIMARY_WEAPON := "rifle"
const HOMEBASE_DEFAULT_SECONDARY_WEAPON := "none"
const HOMEBASE_DIRECT_STAGING_DROP_KIND := "homebase_dropship"
const HOMEBASE_DISPATCH_TARGET_MISSION := "mission"
const HOMEBASE_DISPATCH_TARGET_FOB := "fob"
const HOMEBASE_ROSTER_SORT_LEADER_DESC := "leader_desc"
const HOMEBASE_ROSTER_SORT_LEADER_ASC := "leader_asc"
const HOMEBASE_ROSTER_SORT_TUTOR_DESC := "tutor_desc"
const HOMEBASE_ROSTER_SORT_TUTOR_ASC := "tutor_asc"
const HOMEBASE_ROSTER_SORT_PILOT_DESC := "pilot_desc"
const HOMEBASE_ROSTER_SORT_PILOT_ASC := "pilot_asc"
const HOMEBASE_ROSTER_SORT_XP_DESC := "xp_desc"
const HOMEBASE_ROSTER_SORT_NAME_ASC := "name_asc"
const HOMEBASE_ROSTER_SORT_OPTIONS: Array = [
	{"id": HOMEBASE_ROSTER_SORT_LEADER_DESC, "label": "Leader high"},
	{"id": HOMEBASE_ROSTER_SORT_LEADER_ASC, "label": "Leader low"},
	{"id": HOMEBASE_ROSTER_SORT_TUTOR_DESC, "label": "Tutor high"},
	{"id": HOMEBASE_ROSTER_SORT_TUTOR_ASC, "label": "Tutor low"},
	{"id": HOMEBASE_ROSTER_SORT_PILOT_DESC, "label": "Pilot high"},
	{"id": HOMEBASE_ROSTER_SORT_PILOT_ASC, "label": "Pilot low"},
	{"id": HOMEBASE_ROSTER_SORT_XP_DESC, "label": "Most XP"},
	{"id": HOMEBASE_ROSTER_SORT_NAME_ASC, "label": "Name"},
]

signal selection_changed(selected_unit_ids)
signal fireteam_context_changed(selected_unit_ids, selected_fireteam_ids)
signal team_confirmed(selected_unit_ids)
signal mission_selection_changed(mission_id)
signal mission_start_requested()
signal aircraft_pilot_assigned(craft_id, pilot_unit_id)
signal aircraft_pilot_cleared(craft_id)
signal aircraft_pilot_transfer_requested(craft_id, pilot_unit_id)
signal aircraft_cargo_selected(craft_id, cargo_id)
signal aircraft_cargo_load_requested(craft_id, cargo_id)
signal aircraft_add_requested(base_craft_type)
signal aircraft_remove_requested(craft_id)

var _available_units: Array = []
var _selected_unit_ids: PackedStringArray = []
var _selected_fireteam_ids: PackedStringArray = []
var _fireteam_definitions: Array = []
var _focused_fireteam_id: String = HOMEBASE_DEFAULT_FIRETEAM_ID
var _loadout_staged_fireteam_id: String = HOMEBASE_DEFAULT_FIRETEAM_ID
var _homebase_dropship_staged_fireteam_ids: PackedStringArray = []
var _homebase_dropship_payload_craft_id: String = ""
var _homebase_dropship_staged_fireteam_ids_by_craft: Dictionary = {}
var _homebase_dispatch_target_by_craft: Dictionary = {}
var _homebase_direct_boarding_state_by_fireteam_id: Dictionary = {}
var _homebase_direct_boarding_refresh_seconds: float = 0.0
var _homebase_direct_boarding_force_refresh: bool = false
var _homebase_direct_boarding_refresh_deferred_for_drag: bool = false
var _pending_homebase_direct_mission_craft_id: String = ""
var _member_loadout_by_unit_id: Dictionary = {}
var _homebase_loadout_preview_texture_cache: Dictionary = {}
var _roster_sort_mode: String = HOMEBASE_ROSTER_SORT_NAME_ASC
var _profiles_by_id: Dictionary = {}
var _focused_unit_id: String = ""
var _roster_cards_by_unit_id: Dictionary = {}
var _staged_cards_by_unit_id: Dictionary = {}
var _roster_card_pool = HOMEBASE_CARD_POOL_SCRIPT.new()
var _staged_card_pool = HOMEBASE_CARD_POOL_SCRIPT.new()
var _team_feedback_text: String = ""
var _character_sheet_open: bool = false
var _aircraft_feedback_text: String = ""
var _mission_catalog: Array = []
var _selected_mission_id: String = "fob_transfer"
var _selected_mission_map_path: String = "res://maps/Ground_Mission01_32x32.json"
var _selected_mission_scenario_path: String = "res://data/mission_scenarios/ground_mission01_default.json"
var _selected_mission_name: String = "Operation: FOB Transfer"
var _selected_mission_slot_count: int = 3
var _mission_launch_ready: bool = false
var _mission_launch_summary: String = ""
var _mission_slot_usage_override: int = -1
var _mission_pilot_count_override: int = -1
var _mission_briefing_panel_presenter = MISSION_BRIEFING_PANEL_PRESENTER_SCRIPT.new()
var _mission_briefing_panel_snapshot: Dictionary = {}
var _aircraft_manager = AIRCRAFT_MANAGER_SCRIPT.new()
var _team_transfer_entries: Array = []
var _personnel_events: Array = []


func _ready() -> void:
	set_process(true)
	META_UI_SKIN_SCRIPT.apply_homebase(self)
	_apply_drop_light_fixed_layout()
	_ensure_homebase_direct_staging_panels()
	_ensure_character_sheet_popup()
	HOVER_SCROLL_BEHAVIOR_SCRIPT.call("install", self)
	_apply_contextual_help_ids()
	var mission_selector: OptionButton = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector")
	var start_mission_button: Button = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton")
	var confirm_button: Button = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/ConfirmButton")
	var close_sheet_button: Button = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/CloseSheetButton")
	var aircraft_selector: OptionButton = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AircraftSelector")
	var add_aircraft_button: Button = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AddAircraftButton")
	var remove_aircraft_button: Button = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/RemoveAircraftButton")
	var aircraft_cargo_row: HBoxContainer = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow")
	var cargo_selector: OptionButton = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/CargoSelector")
	var load_cargo_button: Button = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/LoadCargoButton")
	_configure_flightdeck_option_button(mission_selector)
	_configure_flightdeck_option_button(aircraft_selector)
	_configure_flightdeck_option_button(cargo_selector)
	if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
		confirm_button.pressed.connect(_on_confirm_button_pressed)
	if not mission_selector.item_selected.is_connected(_on_mission_selector_item_selected):
		mission_selector.item_selected.connect(_on_mission_selector_item_selected)
	if not start_mission_button.pressed.is_connected(_on_start_mission_button_pressed):
		start_mission_button.pressed.connect(_on_start_mission_button_pressed)
	if not close_sheet_button.pressed.is_connected(_on_close_sheet_button_pressed):
		close_sheet_button.pressed.connect(_on_close_sheet_button_pressed)
	if not aircraft_selector.item_selected.is_connected(_on_aircraft_selector_item_selected):
		aircraft_selector.item_selected.connect(_on_aircraft_selector_item_selected)
	if not add_aircraft_button.pressed.is_connected(_on_add_aircraft_button_pressed):
		add_aircraft_button.pressed.connect(_on_add_aircraft_button_pressed)
	if not remove_aircraft_button.pressed.is_connected(_on_remove_aircraft_button_pressed):
		remove_aircraft_button.pressed.connect(_on_remove_aircraft_button_pressed)
	if not cargo_selector.item_selected.is_connected(_on_cargo_selector_item_selected):
		cargo_selector.item_selected.connect(_on_cargo_selector_item_selected)
	if not load_cargo_button.pressed.is_connected(_on_load_cargo_button_pressed):
		load_cargo_button.pressed.connect(_on_load_cargo_button_pressed)
	META_UI_SKIN_SCRIPT.style_secondary_button(close_sheet_button)
	META_UI_SKIN_SCRIPT.style_secondary_button(load_cargo_button)
	META_UI_SKIN_SCRIPT.style_transfer_button(start_mission_button, false)
	remove_aircraft_button.visible = false
	aircraft_cargo_row.visible = false

	var roster_drop_panel = _get_roster_drop_panel()
	if roster_drop_panel != null and not roster_drop_panel.unit_dropped.is_connected(_on_roster_drop_panel_unit_dropped):
		roster_drop_panel.unit_dropped.connect(_on_roster_drop_panel_unit_dropped)
	var team_drop_panel = _get_team_drop_panel()
	if team_drop_panel != null and not team_drop_panel.unit_dropped.is_connected(_on_team_drop_panel_unit_dropped):
		team_drop_panel.unit_dropped.connect(_on_team_drop_panel_unit_dropped)
	_connect_homebase_direct_staging_signals()

	_rebuild_profiles()
	_rebuild_ui()


func _process(delta: float) -> void:
	var boarding_advanced: bool = _advance_homebase_direct_boarding(delta)
	if not boarding_advanced and not _homebase_direct_boarding_force_refresh:
		return
	if _homebase_direct_boarding_force_refresh:
		_homebase_direct_boarding_refresh_seconds = 0.0
		_refresh_homebase_direct_boarding_ui()
		return
	_homebase_direct_boarding_refresh_seconds += maxf(delta, 0.0)
	if _homebase_direct_boarding_refresh_seconds < HOMEBASE_DIRECT_BOARDING_UI_REFRESH_SECONDS:
		return
	_homebase_direct_boarding_refresh_seconds = 0.0
	_refresh_homebase_direct_boarding_ui()


func setup_roster(available_units: Array, selected_unit_ids: PackedStringArray = []) -> void:
	_available_units = available_units.duplicate(true)
	_selected_unit_ids = _normalize_selected_unit_ids(selected_unit_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	_sanitize_homebase_direct_staging_state()
	_team_feedback_text = ""
	if is_inside_tree():
		_rebuild_profiles()
		_rebuild_ui()


func set_fireteam_context(selected_fireteam_ids: PackedStringArray = [], fireteam_definitions: Array = []) -> void:
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(selected_fireteam_ids)
	_fireteam_definitions = _normalize_fireteam_definitions(fireteam_definitions)
	_sanitize_homebase_direct_staging_state()
	if is_inside_tree():
		_render_homebase_fireteams()
		_update_homebase_loadout_panel()
		_update_homebase_flightdeck_staging_panel()
		if _character_sheet_open:
			_update_character_sheet()


func set_mission_context(mission_catalog: Array, selected_map_path: String, mission_name: String, mission_slot_count: int, selected_mission_id: String = "") -> void:
	_mission_catalog = mission_catalog.duplicate(true)
	_selected_mission_id = selected_mission_id.strip_edges() if not selected_mission_id.strip_edges().is_empty() else _selected_mission_id
	_selected_mission_map_path = selected_map_path.strip_edges() if not selected_map_path.strip_edges().is_empty() else _selected_mission_map_path
	_selected_mission_name = mission_name.strip_edges() if not mission_name.strip_edges().is_empty() else _selected_mission_name
	_selected_mission_slot_count = maxi(mission_slot_count, 1)
	_selected_mission_scenario_path = _resolve_selected_mission_scenario_path()
	if is_inside_tree():
		_update_mission_info()


func set_mission_occupancy(slot_usage_count: int, pilot_count: int = -1) -> void:
	_mission_slot_usage_override = maxi(slot_usage_count, 0)
	_mission_pilot_count_override = pilot_count
	if is_inside_tree():
		_update_mission_info()


func set_transport_state(
	aircraft_definitions: Array,
	assigned_pilot_by_craft: Dictionary,
	team_transfer_entries: Array,
	pilot_transfer_entries: Array,
	aircraft_location_by_craft: Dictionary = {},
	selected_cargo_by_craft: Dictionary = {},
	loaded_cargo_by_craft: Dictionary = {},
	cargo_load_entries: Array = []
) -> void:
	_team_transfer_entries = team_transfer_entries.duplicate(true)
	_aircraft_manager.set_transport_state(
		aircraft_definitions,
		assigned_pilot_by_craft,
		pilot_transfer_entries,
		aircraft_location_by_craft,
		selected_cargo_by_craft,
		loaded_cargo_by_craft,
		cargo_load_entries
	)
	_selected_unit_ids = _normalize_selected_unit_ids(_selected_unit_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	if is_inside_tree():
		_rebuild_ui()


func set_selected_unit_ids(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = _normalize_selected_unit_ids(selected_unit_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	_sanitize_homebase_direct_staging_state()
	_team_feedback_text = ""
	if is_inside_tree():
		_rebuild_ui()


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func get_selected_fireteam_ids() -> PackedStringArray:
	return _selected_fireteam_ids.duplicate()


func set_mission_launch_state(is_ready: bool, summary_text: String = "") -> void:
	_mission_launch_ready = is_ready
	_mission_launch_summary = summary_text.strip_edges()
	if is_inside_tree():
		_update_mission_info()


func set_personnel_events(personnel_events: Array) -> void:
	_personnel_events = []
	for event_variant in personnel_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		_personnel_events.append(Dictionary(event_variant).duplicate(true))
	if is_inside_tree():
		_update_personnel_notifications()


func get_personnel_notification_snapshot() -> Dictionary:
	return {
		"event_count": _personnel_events.size(),
		"messages": _build_personnel_notification_messages(),
	}


func get_mission_briefing_panel_snapshot() -> Dictionary:
	var snapshot: Dictionary = _mission_briefing_panel_snapshot.duplicate(true)
	snapshot["panel_visible"] = _node_is_visible("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel")
	var title_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingTitleLabel") as Label
	var status_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingStatusLabel") as Label
	var objectives_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingObjectivesLabel") as Label
	var teams_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingTeamsLabel") as Label
	var minimap_visual := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingMinimapVisual") as Control
	if title_label != null:
		snapshot["rendered_title_text"] = title_label.text
	if status_label != null:
		snapshot["rendered_status_text"] = status_label.text
	if objectives_label != null:
		snapshot["rendered_objective_text"] = objectives_label.text
	if teams_label != null:
		snapshot["rendered_team_text"] = teams_label.text
	if minimap_visual != null and minimap_visual.has_method("get_visual_snapshot"):
		var visual_snapshot: Dictionary = Dictionary(minimap_visual.call("get_visual_snapshot"))
		snapshot["rendered_minimap_visible"] = minimap_visual.visible
		snapshot["rendered_minimap_sample_count"] = int(visual_snapshot.get("sample_count", 0))
		snapshot["rendered_minimap_entry_count"] = int(visual_snapshot.get("entry_count", 0))
		snapshot["rendered_minimap_draw_mode"] = String(visual_snapshot.get("draw_mode", ""))
	return snapshot


func get_aircraft_panel_snapshot() -> Dictionary:
	var selected_craft: Dictionary = _get_selected_aircraft_definition()
	var direct_craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate()
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids()
	var payload_operator_count: int = _build_unit_ids_for_fireteams(payload_fireteam_ids).size()
	var selected_aircraft_id: String = _get_selected_aircraft_id()
	var payload_craft_id: String = _get_homebase_direct_payload_craft_id()
	return {
		"selected_aircraft_id": selected_aircraft_id,
		"visible_aircraft_definitions": _get_visible_homebase_aircraft_definitions(),
		"selected_status_text": _build_aircraft_status_text(
			selected_craft,
			String(selected_craft.get("display_name", selected_aircraft_id)).strip_edges(),
			_get_assigned_pilot_id(selected_aircraft_id),
			_has_active_pilot_transfer_for_craft(selected_aircraft_id) or _is_craft_in_transit(selected_aircraft_id),
			_has_active_cargo_load_for_craft(selected_aircraft_id)
		) if not selected_craft.is_empty() else "",
		"can_send_selected": _can_send_craft(selected_craft, selected_aircraft_id) if not selected_craft.is_empty() else false,
		"can_remove_selected": _can_remove_selected_aircraft(),
		"aircraft_manager_contract": _aircraft_manager.get_contract_snapshot(),
		"flightdeck_stage_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage"),
		"deck_activity_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll"),
		"shipcards_are_primary_status": true,
		"homebase_direct_staging_enabled": true,
		"fireteams_panel_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel"),
		"loadout_panel_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel"),
		"fixed_character_sheet_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/InfoPanel"),
		"character_popup_visible": _node_is_visible("CharacterSheetPopup"),
		"staged_fireteam_ids": Array(_homebase_dropship_staged_fireteam_ids),
		"payload_fireteam_ids": Array(payload_fireteam_ids),
		"payload_fireteam_ids_by_craft": _build_homebase_direct_payload_by_craft_snapshot(),
		"payload_craft_id": payload_craft_id,
		"payload_operator_count": payload_operator_count,
		"boarded_operator_count": _get_homebase_direct_boarded_operator_count(),
		"boarding_progress_ratio": _get_homebase_direct_boarding_progress_ratio(),
		"homebase_dispatch_target": _get_homebase_dispatch_target(payload_craft_id),
		"homebase_direct_payload_status_text": _build_homebase_direct_payload_status_text(direct_craft_gate, false),
		"homebase_direct_craft_ready": bool(direct_craft_gate.get("can_stage", false)),
		"homebase_direct_craft_block_reason": String(direct_craft_gate.get("block_reason", "")).strip_edges(),
		"homebase_direct_craft_block_text": String(direct_craft_gate.get("block_text", "")).strip_edges(),
	}


func get_aircraft_manager_contract_snapshot() -> Dictionary:
	return _aircraft_manager.get_contract_snapshot()


func build_homebase_direct_drop_state() -> Dictionary:
	return build_homebase_direct_drop_state_for_craft(_get_homebase_direct_payload_craft_id())


func build_homebase_direct_drop_state_for_craft(craft_id: String) -> Dictionary:
	_sanitize_homebase_direct_staging_state()
	var requested_craft_id: String = craft_id.strip_edges()
	if requested_craft_id.is_empty():
		requested_craft_id = _get_homebase_direct_payload_craft_id()
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(requested_craft_id) if not requested_craft_id.is_empty() else _get_homebase_direct_payload_fireteam_ids()
	var payload_unit_ids: PackedStringArray = _build_unit_ids_for_fireteams(payload_fireteam_ids)
	var craft_gate: Dictionary = _build_homebase_direct_staging_craft_gate_for_craft(requested_craft_id) if not requested_craft_id.is_empty() else _get_homebase_direct_staging_craft_gate()
	var payload_craft: Dictionary = Dictionary(craft_gate.get("craft", {}))
	var payload_craft_id: String = String(payload_craft.get("craft_id", "")).strip_edges()
	var dispatch_target: String = _get_homebase_dispatch_target(payload_craft_id)
	var boarding_complete: bool = _are_homebase_payload_fireteams_boarded(payload_fireteam_ids)
	var direct_ready: bool = bool(craft_gate.get("can_stage", false)) and boarding_complete and not payload_unit_ids.is_empty()
	var boarded_fireteam_ids: PackedStringArray = payload_fireteam_ids if direct_ready else PackedStringArray()
	var embarked_unit_ids: PackedStringArray = payload_unit_ids if direct_ready else PackedStringArray()
	var craft_display_name: String = String(payload_craft.get("display_name", "")).strip_edges()
	if craft_display_name.is_empty():
		craft_display_name = "Dropship"
	var assigned_pilot_id: String = _get_assigned_pilot_id(payload_craft_id)
	var fireteam_definitions: Array = _get_fireteam_definitions_snapshot()
	var selected_payload_fireteam_ids: PackedStringArray = boarded_fireteam_ids
	var payload_fireteam_definitions: Array = _filter_fireteam_definitions_for_ids(fireteam_definitions, selected_payload_fireteam_ids)
	var member_loadouts: Dictionary = _build_homebase_member_loadouts(selected_payload_fireteam_ids)
	var mission_setup_payload_fireteam_ids: PackedStringArray = _get_homebase_direct_ready_payload_fireteam_ids()
	if mission_setup_payload_fireteam_ids.is_empty() and direct_ready:
		mission_setup_payload_fireteam_ids = selected_payload_fireteam_ids.duplicate()
	var mission_setup_unit_ids: PackedStringArray = _build_unit_ids_for_fireteams(mission_setup_payload_fireteam_ids)
	var mission_setup_fireteam_ids: PackedStringArray = _build_fireteam_ids_for_units(mission_setup_unit_ids)
	var mission_setup_fireteam_definitions: Array = _filter_fireteam_definitions_for_ids(fireteam_definitions, mission_setup_payload_fireteam_ids)
	var mission_setup_member_loadouts: Dictionary = _build_homebase_member_loadouts(mission_setup_payload_fireteam_ids)
	return {
		"transport_craft_id": payload_craft_id,
		"dropship_phase": "homebase_ready" if direct_ready else "waiting",
		"queued_fireteam_ids": Array(payload_fireteam_ids),
		"queued_unit_ids": Array(payload_unit_ids),
		"queued_passenger_count": payload_unit_ids.size(),
		"boarded_fireteam_ids": Array(boarded_fireteam_ids),
		"embarked_unit_ids": Array(embarked_unit_ids),
		"launch_ready_craft_id": payload_craft_id if direct_ready else "",
		"drop_ship_staged": direct_ready,
		"mission_drop_craft_id": payload_craft_id,
		"mission_drop_display_name": craft_display_name,
		"mission_drop_title_text": UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title(craft_display_name),
		"mission_drop_texture_path": String(payload_craft.get("texture_path", "")).strip_edges(),
		"mission_drop_state": "waiting" if direct_ready else "",
		"mission_drop_pilot_text": "Pilot: %s" % _build_display_name(assigned_pilot_id) if not assigned_pilot_id.is_empty() else "Pilot: none",
		"mission_drop_status_line": "Homebase direct staging" if direct_ready else String(craft_gate.get("block_text", "")).strip_edges(),
		"mission_drop_progress": 0.0,
		"mission_drop_eta_seconds": 0,
		"mission_drop_pilot_unit_id": assigned_pilot_id,
		"mission_drop_pilot_display_name": _build_display_name(assigned_pilot_id) if not assigned_pilot_id.is_empty() else "",
		"mission_drop_pilot_portrait_path": _get_profile_portrait_path(assigned_pilot_id),
		"mission_drop_passenger_count": embarked_unit_ids.size(),
		"mission_drop_cards": _build_homebase_mission_drop_cards(payload_fireteam_ids, payload_unit_ids, payload_craft_id, direct_ready),
		"selected_unit_ids": Array(embarked_unit_ids),
		"selected_fireteam_ids": Array(_build_fireteam_ids_for_units(embarked_unit_ids)),
		"selected_team_unit_configs": _build_homebase_unit_configs_for_unit_ids(embarked_unit_ids),
		"fireteam_definitions": fireteam_definitions,
		"selected_fireteam_definitions": payload_fireteam_definitions,
		"member_loadouts": member_loadouts,
		"mission_setup_unit_ids": Array(mission_setup_unit_ids),
		"mission_setup_fireteam_ids": Array(mission_setup_fireteam_ids),
		"mission_setup_team_unit_configs": _build_homebase_unit_configs_for_unit_ids(mission_setup_unit_ids),
		"mission_setup_fireteam_definitions": mission_setup_fireteam_definitions,
		"mission_setup_member_loadouts": mission_setup_member_loadouts,
		"homebase_team_unit_ids": Array(_selected_unit_ids),
		"homebase_team_fireteam_ids": Array(_selected_fireteam_ids),
		"homebase_team_unit_configs": _build_homebase_selected_unit_configs(),
		"homebase_fireteam_definitions": fireteam_definitions.duplicate(true),
		"homebase_direct_staging": true,
		"homebase_direct_payload_craft_id": payload_craft_id,
		"homebase_dispatch_target": dispatch_target,
		"homebase_direct_payload_status_text": _build_homebase_direct_payload_status_text(craft_gate, false),
		"homebase_direct_payload_operator_count": payload_unit_ids.size(),
		"homebase_direct_boarded_operator_count": _get_homebase_direct_boarded_operator_count_for_fireteams(payload_fireteam_ids),
		"homebase_direct_boarding_progress_ratio": _get_homebase_direct_boarding_progress_ratio_for_craft(payload_craft_id) if not payload_craft_id.is_empty() else _get_homebase_direct_boarding_progress_ratio(),
		"homebase_direct_payload_fireteam_count": payload_fireteam_ids.size(),
		"homebase_direct_boarding_complete": boarding_complete,
		"homebase_direct_craft_ready": bool(craft_gate.get("can_stage", false)),
		"homebase_direct_craft_block_reason": String(craft_gate.get("block_reason", "")).strip_edges(),
		"homebase_direct_craft_block_text": String(craft_gate.get("block_text", "")).strip_edges(),
	}


func get_homebase_direct_staging_snapshot() -> Dictionary:
	var drop_state: Dictionary = build_homebase_direct_drop_state()
	var craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate()
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids()
	var payload_operator_count: int = _build_unit_ids_for_fireteams(payload_fireteam_ids).size()
	var payload_craft_id: String = _get_homebase_direct_payload_craft_id()
	return {
		"direct_staging_enabled": true,
		"fireteams_panel_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel"),
		"loadout_panel_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel"),
		"flightdeck_panel_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/AircraftPanel"),
		"fixed_character_sheet_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/InfoPanel"),
		"character_popup_visible": _node_is_visible("CharacterSheetPopup"),
		"selected_unit_ids": Array(_selected_unit_ids),
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"staged_fireteam_ids": Array(_homebase_dropship_staged_fireteam_ids),
		"payload_fireteam_ids": Array(payload_fireteam_ids),
		"payload_fireteam_ids_by_craft": _build_homebase_direct_payload_by_craft_snapshot(),
		"payload_craft_id": payload_craft_id,
		"payload_operator_count": payload_operator_count,
		"boarded_operator_count": _get_homebase_direct_boarded_operator_count(),
		"boarding_progress_ratio": _get_homebase_direct_boarding_progress_ratio(),
		"boarding_refresh_deferred_for_drag": _homebase_direct_boarding_refresh_deferred_for_drag,
		"homebase_dispatch_target": _get_homebase_dispatch_target(payload_craft_id),
		"payload_status_text": _build_homebase_direct_payload_status_text(craft_gate, false),
		"fireteam_payload_statuses": _build_homebase_fireteam_payload_status_snapshot(craft_gate),
		"embarked_unit_ids": Array(PackedStringArray(Array(drop_state.get("embarked_unit_ids", [])))),
		"drop_ship_staged": bool(drop_state.get("drop_ship_staged", false)),
		"member_loadouts": Dictionary(drop_state.get("member_loadouts", {})).duplicate(true),
		"transport_craft_id": String(drop_state.get("transport_craft_id", "")).strip_edges(),
		"mission_drop_craft_id": String(drop_state.get("mission_drop_craft_id", "")).strip_edges(),
		"homebase_direct_craft_ready": bool(craft_gate.get("can_stage", false)),
		"homebase_direct_craft_block_reason": String(craft_gate.get("block_reason", "")).strip_edges(),
		"homebase_direct_craft_block_text": String(craft_gate.get("block_text", "")).strip_edges(),
		"can_request_mission_start": can_request_mission_start(),
		"uses_fob_drop_panel_contract": bool(get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel").get_meta("homebase_uses_fob_drop_panel_contract", false)) if get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") != null else false,
	}


func can_request_mission_start(craft_id: String = "") -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if not normalized_craft_id.is_empty():
		return _mission_launch_ready or _has_homebase_direct_launch_payload_for_craft(normalized_craft_id)
	return _mission_launch_ready or _has_homebase_direct_launch_payload()


func request_mission_start(craft_id: String = "") -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if not can_request_mission_start(normalized_craft_id):
		return
	_pending_homebase_direct_mission_craft_id = normalized_craft_id
	mission_start_requested.emit()


func consume_homebase_direct_mission_craft_id() -> String:
	var craft_id: String = _pending_homebase_direct_mission_craft_id.strip_edges()
	_pending_homebase_direct_mission_craft_id = ""
	return craft_id


func confirm_selection() -> void:
	if _selected_unit_ids.is_empty():
		return

	team_confirmed.emit(get_selected_unit_ids())


func _rebuild_profiles() -> void:
	_profiles_by_id = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id(_available_units)


func _rebuild_ui() -> void:
	_ensure_homebase_direct_staging_panels()
	_ensure_homebase_roster_sort_controls()
	_ensure_character_sheet_popup()
	_ensure_focused_unit_id()
	_ensure_selected_aircraft_id()
	_sanitize_homebase_direct_staging_state()
	_apply_block_labels()
	_apply_homebase_compact_panel_policy()
	_render_roster()
	_render_staged_team()
	_render_homebase_fireteams()
	_update_homebase_loadout_panel()
	_update_mission_info()
	_update_team_summary()
	_update_team_transfer_list()
	_update_aircraft_panel()
	_update_homebase_flightdeck_staging_panel()
	_update_character_sheet()
	_update_character_sheet_visibility()
	_update_drop_light_flightdeck_stage()
	_apply_mission_brief_contrast_policy()
	_apply_contextual_help_ids()
	call_deferred("_enforce_drop_light_fixed_layout")


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel"), "homebase.roster")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel"), "homebase.roster")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll"), "homebase.roster")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel"), "homebase.transfer_team")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/TeamHeaderLabel"), "homebase.transfer_team")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel"), "homebase.transfer_team")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll"), "homebase.transfer_team")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersScroll"), "homebase.transfer_team")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel"), "homebase.fireteams")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll"), "homebase.fireteams")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel"), "homebase.flightdeck")
	_apply_help_id(get_node_or_null("CharacterSheetPopup"), "homebase.character_popup")


func _apply_help_id(node: Node, help_id: String) -> void:
	var control := node as Control
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	control.set_meta("help_id", normalized_id)
	control.tooltip_text = ""


func _apply_drop_light_fixed_layout() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	custom_minimum_size = Vector2(float(target_viewport.x), float(target_viewport.y))
	set_meta("drop_light_fixed_fullhd_layout", true)
	set_meta("drop_light_screen", DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SCREEN_HOMEBASE"))
	_character_sheet_open = false
	_ensure_drop_light_topbar()
	_ensure_homebase_direct_staging_panels()
	_ensure_character_sheet_popup()
	_ensure_drop_light_flightdeck_stage()
	_enforce_drop_light_fixed_layout()
	call_deferred("_enforce_drop_light_fixed_layout")


func _enforce_drop_light_fixed_layout() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	_apply_fixed_window_contract("DropLightTopbar", layout.get("topbar"))
	_apply_fixed_window_contract("Panel/Margin/VBox/MissionPanel", layout.get("mission_brief"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/RosterPanel", layout.get("roster"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel", layout.get("fireteams"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/AircraftPanel", layout.get("flightdeck"))
	_retire_homebase_loadout_panel()
	_disable_legacy_homebase_window("Panel/Margin/VBox/ContentRow/TeamPanel", "homebase_legacy_transfer_window_disabled")
	_disable_legacy_homebase_window("Panel/Margin/VBox/ContentRow/InfoPanel", "homebase_legacy_character_sheet_window_disabled")
	_apply_character_popup_rect()


func _apply_fixed_window_contract(path: String, rect_variant: Variant) -> void:
	if typeof(rect_variant) != TYPE_RECT2I:
		return
	var control := get_node_or_null(path) as Control
	if control == null:
		return
	var rect: Rect2i = rect_variant
	control.set_as_top_level(true)
	control.position = Vector2(float(rect.position.x), float(rect.position.y))
	control.size = Vector2(float(rect.size.x), float(rect.size.y))
	control.custom_minimum_size = Vector2(float(rect.size.x), float(rect.size.y))
	control.set_deferred("position", Vector2(float(rect.position.x), float(rect.position.y)))
	control.set_deferred("size", Vector2(float(rect.size.x), float(rect.size.y)))
	control.set_meta("drop_light_rect", rect)
	control.set_meta("drop_light_fixed_fullhd_layout", true)


func _configure_flightdeck_option_button(selector: OptionButton) -> void:
	if selector == null:
		return
	selector.clip_text = true
	selector.set_meta("homebase_flightdeck_dropdown_unclipped", true)
	var popup := selector.get_popup()
	if popup == null:
		return
	popup.set_meta("homebase_flightdeck_dropdown_unclipped", true)
	popup.set_meta("homebase_dropdown_owner", selector.name)
	if popup.has_method("set_as_top_level"):
		popup.call("set_as_top_level", true)
	_set_object_property_if_available(popup, "always_on_top", true)
	_set_object_property_if_available(popup, "unresizable", false)
	_set_object_property_if_available(popup, "max_size", Vector2i(420, 280))
	_set_object_property_if_available(popup, "min_size", Vector2i(180, 0))


func _ensure_homebase_roster_sort_controls() -> void:
	var roster_vbox := get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox") as VBoxContainer
	if roster_vbox == null:
		return
	var sort_row := roster_vbox.get_node_or_null("RosterSortRow") as HBoxContainer
	if sort_row == null:
		sort_row = HBoxContainer.new()
		sort_row.name = "RosterSortRow"
		sort_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sort_row.add_theme_constant_override("separation", 4)
		sort_row.set_meta("homebase_roster_sort_controls", true)

		var label := Label.new()
		label.name = "RosterSortLabel"
		label.text = "Sort"
		label.custom_minimum_size = Vector2(32.0, 0.0)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		META_UI_SKIN_SCRIPT.style_body_label(label, 9)
		sort_row.add_child(label)

		var selector := OptionButton.new()
		selector.name = "RosterSortSelector"
		selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selector.custom_minimum_size = Vector2(0.0, 22.0)
		selector.add_theme_font_size_override("font_size", 8)
		selector.set_meta("homebase_roster_sort_selector", true)
		sort_row.add_child(selector)

		var insert_index := roster_vbox.get_child_count()
		var help_label := roster_vbox.get_node_or_null("RosterHelpLabel")
		if help_label != null:
			insert_index = help_label.get_index() + 1
		roster_vbox.add_child(sort_row)
		roster_vbox.move_child(sort_row, mini(insert_index, roster_vbox.get_child_count() - 1))
	var selector := sort_row.get_node_or_null("RosterSortSelector") as OptionButton
	_populate_homebase_roster_sort_selector(selector)


func _populate_homebase_roster_sort_selector(selector: OptionButton) -> void:
	if selector == null:
		return
	_configure_flightdeck_option_button(selector)
	var selected_index := 0
	selector.clear()
	for option_index in range(HOMEBASE_ROSTER_SORT_OPTIONS.size()):
		var option: Dictionary = Dictionary(HOMEBASE_ROSTER_SORT_OPTIONS[option_index])
		var option_id: String = String(option.get("id", "")).strip_edges()
		selector.add_item(String(option.get("label", option_id)).strip_edges())
		selector.set_item_metadata(selector.item_count - 1, option_id)
		if option_id == _roster_sort_mode:
			selected_index = selector.item_count - 1
	if selector.item_count > 0:
		selector.select(clampi(selected_index, 0, selector.item_count - 1))
	var callback := Callable(self, "_on_roster_sort_selected").bind(selector)
	if not bool(selector.get_meta("homebase_roster_sort_connected", false)):
		selector.item_selected.connect(callback)
		selector.set_meta("homebase_roster_sort_connected", true)
	META_UI_SKIN_SCRIPT.style_secondary_button(selector)


func _set_object_property_if_available(target: Object, property_name: String, value: Variant) -> void:
	if target == null:
		return
	for property_info in target.get_property_list():
		if String(Dictionary(property_info).get("name", "")) == property_name:
			target.set(property_name, value)
			return


func _ensure_homebase_direct_staging_panels() -> void:
	var content_row := get_node_or_null("Panel/Margin/VBox/ContentRow") as HBoxContainer
	if content_row == null:
		return

	var fireteam_panel := content_row.get_node_or_null("HomebaseFireteamPanel") as PanelContainer
	if fireteam_panel == null:
		fireteam_panel = _create_homebase_fireteam_panel()
		content_row.add_child(fireteam_panel)

	var loadout_panel := content_row.get_node_or_null("HomebaseLoadoutPanel") as PanelContainer
	if loadout_panel == null:
		loadout_panel = _create_homebase_loadout_panel()
		content_row.add_child(loadout_panel)
	_retire_homebase_loadout_panel(loadout_panel)

	var aircraft_panel := content_row.get_node_or_null("AircraftPanel")
	if aircraft_panel != null:
		content_row.move_child(fireteam_panel, mini(aircraft_panel.get_index(), content_row.get_child_count() - 1))
		content_row.move_child(aircraft_panel, mini(fireteam_panel.get_index() + 1, content_row.get_child_count() - 1))
		content_row.move_child(loadout_panel, content_row.get_child_count() - 1)

	_ensure_homebase_flightdeck_staging_panel()
	_connect_homebase_direct_staging_signals()


func _create_homebase_fireteam_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "HomebaseFireteamPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.set_script(FOB_DROP_PANEL_SCRIPT)
	panel.set("drop_kind", "fireteam_pool")
	panel.set_meta("homebase_direct_staging_panel", true)
	panel.set_meta("homebase_uses_fob_drop_panel_contract", true)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.name = "FireteamMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "FireteamVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "FireteamHeaderRow"
	header_row.add_theme_constant_override("separation", 4)
	vbox.add_child(header_row)

	var header_label := Label.new()
	header_label.name = "FireteamHeaderLabel"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 12)
	header_row.add_child(header_label)

	var add_button := Button.new()
	add_button.name = "AddFireteamButton"
	add_button.text = "+"
	add_button.custom_minimum_size = Vector2(30.0, 30.0)
	META_UI_SKIN_SCRIPT.style_secondary_button(add_button)
	header_row.add_child(add_button)

	var remove_button := Button.new()
	remove_button.name = "RemoveFireteamButton"
	remove_button.text = "-"
	remove_button.custom_minimum_size = Vector2(30.0, 30.0)
	META_UI_SKIN_SCRIPT.style_secondary_button(remove_button)
	header_row.add_child(remove_button)

	var action_row := HBoxContainer.new()
	action_row.name = "FireteamActionRow"
	action_row.add_theme_constant_override("separation", 4)
	vbox.add_child(action_row)

	var assign_button := Button.new()
	assign_button.name = "AssignFocusedUnitButton"
	assign_button.text = "Assign"
	assign_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_secondary_button(assign_button)
	action_row.add_child(assign_button)

	var clear_button := Button.new()
	clear_button.name = "ClearFocusedUnitButton"
	clear_button.text = "Clear"
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_secondary_button(clear_button)
	action_row.add_child(clear_button)
	action_row.visible = false
	action_row.set_meta("homebase_fireteam_assign_clear_hidden", true)
	assign_button.visible = false
	assign_button.set_meta("homebase_fireteam_assign_clear_hidden", true)
	clear_button.visible = false
	clear_button.set_meta("homebase_fireteam_assign_clear_hidden", true)

	var summary_label := Label.new()
	summary_label.name = "FireteamSummaryLabel"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(summary_label, 9)
	vbox.add_child(summary_label)

	var scroll := ScrollContainer.new()
	scroll.name = "FireteamScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "FireteamList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	return panel


func _create_homebase_loadout_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "HomebaseLoadoutPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.set_script(FOB_DROP_PANEL_SCRIPT)
	panel.set("drop_kind", "loadout")
	panel.set_meta("homebase_direct_staging_panel", true)
	panel.set_meta("homebase_uses_fob_drop_panel_contract", true)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.name = "LoadoutMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "LoadoutVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "LoadoutHeaderRow"
	header_row.add_theme_constant_override("separation", 4)
	vbox.add_child(header_row)

	var header_label := Label.new()
	header_label.name = "LoadoutHeaderLabel"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 12)
	header_row.add_child(header_label)

	var clear_button := Button.new()
	clear_button.name = "ClearLoadoutButton"
	clear_button.text = "Clear"
	clear_button.custom_minimum_size = Vector2(56.0, 30.0)
	META_UI_SKIN_SCRIPT.style_secondary_button(clear_button)
	header_row.add_child(clear_button)

	var status_label := Label.new()
	status_label.name = "LoadoutStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(status_label, 9)
	vbox.add_child(status_label)

	var fireteam_list := HBoxContainer.new()
	fireteam_list.name = "LoadoutFireteamList"
	fireteam_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(fireteam_list)

	var scroll := ScrollContainer.new()
	scroll.name = "LoadoutMemberScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var member_list := VBoxContainer.new()
	member_list.name = "LoadoutMemberList"
	member_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	member_list.add_theme_constant_override("separation", 5)
	scroll.add_child(member_list)
	return panel


func _retire_homebase_loadout_panel(panel_override: Control = null) -> void:
	var panel := panel_override
	if panel == null:
		panel = get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	if panel == null:
		return
	panel.visible = false
	panel.custom_minimum_size = Vector2.ZERO
	panel.size = Vector2.ZERO
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("homebase_loadout_window_retired", true)
	panel.set_meta("homebase_loadout_controls_moved_to_fireteams", true)


func _retire_homebase_direct_staging_panel(panel: Control) -> void:
	if panel == null:
		return
	panel.visible = false
	panel.custom_minimum_size = Vector2.ZERO
	panel.size = Vector2.ZERO
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("homebase_direct_staging_folded_into_shipcards", true)
	panel.set_meta("homebase_direct_staging_visible_in_shipcards", true)


func _ensure_homebase_flightdeck_staging_panel() -> void:
	var aircraft_vbox := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox") as VBoxContainer
	if aircraft_vbox == null:
		return
	var existing_panel := aircraft_vbox.get_node_or_null("DirectDropshipFireteamPanel") as PanelContainer
	if existing_panel != null:
		_ensure_homebase_direct_staging_status_label(existing_panel)
		_retire_homebase_direct_staging_panel(existing_panel)
		return
	var panel := PanelContainer.new()
	panel.name = "DirectDropshipFireteamPanel"
	panel.custom_minimum_size = Vector2(0.0, 96.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.set_script(FOB_DROP_PANEL_SCRIPT)
	panel.set("drop_kind", HOMEBASE_DIRECT_STAGING_DROP_KIND)
	panel.set_meta("homebase_direct_dropship_staging_panel", true)
	panel.set_meta("homebase_uses_fob_drop_panel_contract", true)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.name = "DirectDropshipMargin"
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "DirectDropshipVBox"
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var header_label := Label.new()
	header_label.name = "DirectDropshipHeaderLabel"
	header_label.text = "Direct Dropship Staging"
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 10)
	vbox.add_child(header_label)

	var status_label := Label.new()
	status_label.name = "DirectDropshipStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(status_label, 8)
	vbox.add_child(status_label)

	var list := VBoxContainer.new()
	list.name = "DirectDropshipList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(list)

	var insert_index := aircraft_vbox.get_child_count()
	var shipcards_scroll := aircraft_vbox.get_node_or_null("ShipCardsScroll")
	if shipcards_scroll != null:
		insert_index = shipcards_scroll.get_index()
	aircraft_vbox.add_child(panel)
	aircraft_vbox.move_child(panel, insert_index)
	_retire_homebase_direct_staging_panel(panel)


func _ensure_homebase_direct_staging_status_label(panel: PanelContainer) -> Label:
	var vbox := panel.get_node_or_null("DirectDropshipMargin/DirectDropshipVBox") as VBoxContainer
	if vbox == null:
		return null
	var existing := vbox.get_node_or_null("DirectDropshipStatusLabel") as Label
	if existing != null:
		return existing
	var status_label := Label.new()
	status_label.name = "DirectDropshipStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(status_label, 8)
	var list := vbox.get_node_or_null("DirectDropshipList")
	vbox.add_child(status_label)
	if list != null:
		vbox.move_child(status_label, list.get_index())
	return status_label


func _connect_homebase_direct_staging_signals() -> void:
	var fireteam_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel")
	if fireteam_panel != null:
		if fireteam_panel.has_signal("fireteam_dropped") and not fireteam_panel.is_connected("fireteam_dropped", Callable(self, "_on_homebase_staging_fireteam_dropped")):
			fireteam_panel.connect("fireteam_dropped", Callable(self, "_on_homebase_staging_fireteam_dropped"))
		if fireteam_panel.has_signal("unit_dropped") and not fireteam_panel.is_connected("unit_dropped", Callable(self, "_on_homebase_direct_unit_dropped")):
			fireteam_panel.connect("unit_dropped", Callable(self, "_on_homebase_direct_unit_dropped"))
	var loadout_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel")
	if loadout_panel != null:
		if loadout_panel.has_signal("fireteam_dropped") and not loadout_panel.is_connected("fireteam_dropped", Callable(self, "_on_homebase_staging_fireteam_dropped")):
			loadout_panel.connect("fireteam_dropped", Callable(self, "_on_homebase_staging_fireteam_dropped"))
		if loadout_panel.has_signal("unit_dropped") and not loadout_panel.is_connected("unit_dropped", Callable(self, "_on_homebase_direct_unit_dropped")):
			loadout_panel.connect("unit_dropped", Callable(self, "_on_homebase_direct_unit_dropped"))
	var dropship_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel")
	if dropship_panel != null:
		if dropship_panel.has_signal("fireteam_dropped") and not dropship_panel.is_connected("fireteam_dropped", Callable(self, "_on_homebase_staging_fireteam_dropped")):
			dropship_panel.connect("fireteam_dropped", Callable(self, "_on_homebase_staging_fireteam_dropped"))
		if dropship_panel.has_signal("unit_dropped") and not dropship_panel.is_connected("unit_dropped", Callable(self, "_on_homebase_direct_unit_dropped")):
			dropship_panel.connect("unit_dropped", Callable(self, "_on_homebase_direct_unit_dropped"))
	for button_path in [
		"Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AddFireteamButton",
		"Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/RemoveFireteamButton",
		"Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamActionRow/AssignFocusedUnitButton",
		"Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamActionRow/ClearFocusedUnitButton",
		"Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/ClearLoadoutButton",
	]:
		var button := get_node_or_null(button_path) as Button
		if button == null:
			continue
		match button.name:
			"AddFireteamButton":
				if not button.pressed.is_connected(_on_homebase_add_fireteam_pressed):
					button.pressed.connect(_on_homebase_add_fireteam_pressed)
			"RemoveFireteamButton":
				if not button.pressed.is_connected(_on_homebase_remove_fireteam_pressed):
					button.pressed.connect(_on_homebase_remove_fireteam_pressed)
			"AssignFocusedUnitButton":
				if not button.pressed.is_connected(_on_homebase_assign_focused_unit_pressed):
					button.pressed.connect(_on_homebase_assign_focused_unit_pressed)
			"ClearFocusedUnitButton":
				if not button.pressed.is_connected(_on_homebase_clear_focused_unit_pressed):
					button.pressed.connect(_on_homebase_clear_focused_unit_pressed)
			"ClearLoadoutButton":
				if not button.pressed.is_connected(_on_homebase_clear_loadout_pressed):
					button.pressed.connect(_on_homebase_clear_loadout_pressed)


func _ensure_character_sheet_popup() -> void:
	if get_node_or_null("CharacterSheetPopup") != null:
		return
	var root := Control.new()
	root.name = "CharacterSheetPopup"
	root.visible = false
	root.set_as_top_level(true)
	root.z_as_relative = false
	root.z_index = 120
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_meta("homebase_character_sheet_popup", true)
	root.set_meta("outside_numbered_window_grid", true)
	add_child(root)

	var panel := PanelContainer.new()
	panel.name = "PopupPanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "PopupMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "PopupVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "PopupHeaderRow"
	header_row.add_theme_constant_override("separation", 8)
	vbox.add_child(header_row)

	var header_label := Label.new()
	header_label.name = "PopupHeaderLabel"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 13)
	header_row.add_child(header_label)

	var close_button := Button.new()
	close_button.name = "ClosePopupButton"
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2(72.0, 32.0)
	META_UI_SKIN_SCRIPT.style_secondary_button(close_button)
	if not close_button.pressed.is_connected(_on_close_sheet_button_pressed):
		close_button.pressed.connect(_on_close_sheet_button_pressed)
	header_row.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.name = "PopupScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "GeneratedSheetContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	scroll.add_child(content)
	_apply_character_popup_rect()


func _apply_character_popup_rect() -> void:
	var popup := get_node_or_null("CharacterSheetPopup") as Control
	if popup == null:
		return
	popup.set_as_top_level(true)
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var rect_variant: Variant = layout.get("character_popup")
	if typeof(rect_variant) != TYPE_RECT2I:
		return
	var rect: Rect2i = rect_variant
	popup.position = Vector2(float(rect.position.x), float(rect.position.y))
	popup.size = Vector2(float(rect.size.x), float(rect.size.y))
	popup.custom_minimum_size = Vector2(float(rect.size.x), float(rect.size.y))
	popup.set_deferred("position", popup.position)
	popup.set_deferred("size", popup.size)
	popup.set_meta("homebase_character_popup_rect", rect)


func _disable_legacy_homebase_window(path: String, meta_key: String) -> void:
	var control := get_node_or_null(path) as Control
	if control == null:
		return
	control.visible = false
	control.custom_minimum_size = Vector2.ZERO
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.set_meta(meta_key, true)


func _ensure_drop_light_topbar() -> void:
	if get_node_or_null("DropLightTopbar") != null:
		return
	var topbar := Control.new()
	topbar.name = "DropLightTopbar"
	topbar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	topbar.set_meta("drop_light_fixed_fullhd_layout", true)
	add_child(topbar)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = META_UI_SKIN_SCRIPT.COLOR_HEADER
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	topbar.add_child(background)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 8)
	topbar.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING")) * 2)
	margin.add_child(row)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Homebase"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(title_label, 14)
	row.add_child(title_label)

	for badge_text in ["Roster", "#10 Fireteams", "#13 Loadout", "Flightdeck"]:
		var badge := Label.new()
		badge.text = badge_text
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.custom_minimum_size = Vector2(112.0, 32.0)
		META_UI_SKIN_SCRIPT.style_body_label(badge, 10)
		row.add_child(badge)


func _ensure_drop_light_flightdeck_stage() -> void:
	var aircraft_vbox := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox") as VBoxContainer
	if aircraft_vbox == null or aircraft_vbox.get_node_or_null("DropLightFlightdeckStage") != null:
		return
	var stage_panel := PanelContainer.new()
	stage_panel.name = "DropLightFlightdeckStage"
	stage_panel.custom_minimum_size = Vector2(0.0, 220.0)
	stage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_panel.set_meta("drop_light_read_only_visual_stage", true)
	META_UI_SKIN_SCRIPT.style_tactical_panel(stage_panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stage_panel.add_child(margin)

	var pad_stage := Control.new()
	pad_stage.name = "PadStage"
	pad_stage.clip_contents = true
	pad_stage.custom_minimum_size = Vector2(0.0, 204.0)
	pad_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(pad_stage)

	var insert_index := aircraft_vbox.get_child_count()
	var shipcards_scroll := aircraft_vbox.get_node_or_null("ShipCardsScroll")
	if shipcards_scroll != null:
		insert_index = shipcards_scroll.get_index()
	aircraft_vbox.add_child(stage_panel)
	aircraft_vbox.move_child(stage_panel, insert_index)


func _apply_block_labels() -> void:
	var label_text_by_path: Dictionary = {
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_MISSION_BRIEF,
		"Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_AVAILABLE_OPERATORS,
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/TeamHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_TRANSFER_TEAM,
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_INBOUND_TO_FOB,
		"Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_FIRETEAMS,
		"Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/LoadoutHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_LOADOUT,
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_FLIGHT_DECK,
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_DECK_ACTIVITY,
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/InfoHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_CHARACTER_SHEET,
		"CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/PopupHeaderRow/PopupHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_CHARACTER_POPUP,
	}
	for path_variant in label_text_by_path.keys():
		var label := get_node_or_null(String(path_variant)) as Label
		if label != null:
			label.text = String(label_text_by_path[path_variant])


func _apply_homebase_compact_panel_policy() -> void:
	for path in [
		"Panel/Margin/VBox/ContentRow/TeamPanel",
		"Panel/Margin/VBox/ContentRow/InfoPanel",
		"Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersHeaderLabel",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersScroll",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersHeaderLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel",
	]:
		var control := get_node_or_null(path) as Control
		if control == null:
			continue
		control.visible = false
		control.custom_minimum_size = Vector2.ZERO
		control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		control.set_meta("homebase_compact_status_hidden", true)
		if path == "Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel":
			control.set_meta("homebase_loadout_window_retired", true)
			control.set_meta("homebase_loadout_controls_moved_to_fireteams", true)
		if path == "Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel":
			control.set_meta("homebase_direct_staging_folded_into_shipcards", true)
			control.set_meta("homebase_direct_staging_visible_in_shipcards", true)

	var shipcards_scroll := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll") as ScrollContainer
	if shipcards_scroll != null:
		shipcards_scroll.custom_minimum_size = Vector2.ZERO
		shipcards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		shipcards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		shipcards_scroll.set_meta("homebase_primary_status_region", true)
		shipcards_scroll.set_meta("homebase_shipcards_fit_without_horizontal_scroll", true)

	var team_drop_panel := _get_team_drop_panel() as Control
	if team_drop_panel != null:
		team_drop_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _apply_mission_brief_contrast_policy() -> void:
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as PanelContainer
	if mission_panel != null:
		META_UI_SKIN_SCRIPT.style_tactical_panel(mission_panel, "header")
		mission_panel.set_meta("mission_brief_contrast_policy", "high_contrast_dark_panel")

	var header_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel") as Label
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 12)
	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionNameLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTeamLimitLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTransferLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PersonnelEventsLabel",
	]:
		var label := get_node_or_null(path) as Label
		if label == null:
			continue
		META_UI_SKIN_SCRIPT.style_body_label(label, 10)
		label.add_theme_color_override("font_color", Color("d7e2e8"))


func _render_roster() -> void:
	var roster_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList")
	_roster_cards_by_unit_id.clear()
	var card_specs: Array = []

	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		if _selected_unit_ids.has(unit_id):
			continue
		if _is_unit_assigned_to_aircraft(unit_id):
			continue

		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue
		var secondary_text: String = _build_roster_card_secondary_text(unit_id, profile)
		var transit_entry: Dictionary = _find_transfer_entry_for_unit(unit_id)
		var is_in_transit: bool = not transit_entry.is_empty()
		var sort_metrics: Dictionary = _build_homebase_roster_sort_metrics(unit_id, profile)
		card_specs.append(
			{
				"key": _build_homebase_card_pool_key("roster", unit_id),
				"unit_id": unit_id,
				"profile": profile,
				"secondary_text": secondary_text,
				"is_in_transit": is_in_transit,
				"progress_value": _build_transfer_progress_value(transit_entry) if is_in_transit else 0.0,
				"sort_metrics": sort_metrics,
				"sort_name": String(sort_metrics.get("sort_name", unit_id)).strip_edges(),
			}
		)

	card_specs.sort_custom(Callable(self, "_compare_homebase_roster_card_specs"))
	_roster_card_pool.reconcile(
		roster_list,
		card_specs,
		Callable(self, "_create_homebase_pool_card"),
		Callable(self, "_configure_roster_pool_card")
	)


func _render_staged_team() -> void:
	var selected_team_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList")
	_clear_homebase_transfer_ghost_cards(selected_team_list)
	_staged_cards_by_unit_id.clear()
	var card_specs: Array = []

	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue
		var secondary_text: String = _build_roster_card_secondary_text(unit_id, profile)
		card_specs.append(
			{
				"key": _build_homebase_card_pool_key("staged", unit_id),
				"unit_id": unit_id,
				"profile": profile,
				"secondary_text": secondary_text,
			}
		)

	_staged_card_pool.reconcile(
		selected_team_list,
		card_specs,
		Callable(self, "_create_homebase_pool_card"),
		Callable(self, "_configure_staged_pool_card")
	)

	_render_team_transfer_ghost_cards(selected_team_list)


func get_homebase_card_pool_snapshot() -> Dictionary:
	return {
		"roster": _roster_card_pool.get_snapshot(),
		"staged": _staged_card_pool.get_snapshot(),
		"roster_dictionary_count": _roster_cards_by_unit_id.size(),
		"staged_dictionary_count": _staged_cards_by_unit_id.size(),
	}


func get_homebase_roster_sort_snapshot() -> Dictionary:
	var visible_unit_ids: Array = []
	var roster_list := get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	if roster_list != null:
		for child in roster_list.get_children():
			if child is Control and (child as Control).has_meta("homebase_roster_pool_unit_id"):
				visible_unit_ids.append(String((child as Control).get_meta("homebase_roster_pool_unit_id", "")).strip_edges())
	return {
		"mode": _roster_sort_mode,
		"visible_unit_ids": visible_unit_ids,
	}


func _compare_homebase_roster_card_specs(left_variant: Variant, right_variant: Variant) -> bool:
	var left: Dictionary = Dictionary(left_variant)
	var right: Dictionary = Dictionary(right_variant)
	var sort_key := "sort_name"
	var descending := false
	match _roster_sort_mode:
		HOMEBASE_ROSTER_SORT_LEADER_DESC:
			sort_key = "leader_score"
			descending = true
		HOMEBASE_ROSTER_SORT_LEADER_ASC:
			sort_key = "leader_score"
		HOMEBASE_ROSTER_SORT_TUTOR_DESC:
			sort_key = "tutor_score"
			descending = true
		HOMEBASE_ROSTER_SORT_TUTOR_ASC:
			sort_key = "tutor_score"
		HOMEBASE_ROSTER_SORT_PILOT_DESC:
			sort_key = "pilot_score"
			descending = true
		HOMEBASE_ROSTER_SORT_PILOT_ASC:
			sort_key = "pilot_score"
		HOMEBASE_ROSTER_SORT_XP_DESC:
			sort_key = "xp_score"
			descending = true
		_:
			sort_key = "sort_name"
	if sort_key == "sort_name":
		return _compare_homebase_roster_names(left, right)
	var left_metrics: Dictionary = Dictionary(left.get("sort_metrics", {}))
	var right_metrics: Dictionary = Dictionary(right.get("sort_metrics", {}))
	var left_value: float = float(left_metrics.get(sort_key, 0.0))
	var right_value: float = float(right_metrics.get(sort_key, 0.0))
	if not is_equal_approx(left_value, right_value):
		return left_value > right_value if descending else left_value < right_value
	return _compare_homebase_roster_names(left, right)


func _compare_homebase_roster_names(left: Dictionary, right: Dictionary) -> bool:
	var left_name: String = String(left.get("sort_name", "")).strip_edges().to_lower()
	var right_name: String = String(right.get("sort_name", "")).strip_edges().to_lower()
	if left_name != right_name:
		return left_name < right_name
	return String(left.get("unit_id", "")).strip_edges() < String(right.get("unit_id", "")).strip_edges()


func _build_homebase_roster_sort_metrics(unit_id: String, profile) -> Dictionary:
	var unit_data: Dictionary = _get_available_unit_data(unit_id)
	var display_name: String = _build_display_name(unit_id).to_lower()
	return {
		"leader_score": _get_homebase_profile_metric(profile, unit_data, ["leadership"], ["skill_leadership", "leadership"], 0.0),
		"tutor_score": _get_homebase_tutor_sort_score(profile, unit_data),
		"pilot_score": _get_homebase_pilot_sort_score(profile, unit_data),
		"xp_score": _get_homebase_xp_sort_score(profile, unit_data),
		"sort_name": display_name,
	}


func _get_homebase_profile_metric(profile, unit_data: Dictionary, profile_keys: Array, unit_data_keys: Array, fallback: float = 0.0) -> float:
	var candidate_dictionaries: Array = []
	if profile != null:
		for property_name in ["skill_values", "function_scores", "platform_values", "communication_values", "behavior_axes", "method_scores", "progression", "ftl_tactical_progression"]:
			var value = profile.get(property_name)
			if typeof(value) == TYPE_DICTIONARY:
				candidate_dictionaries.append(Dictionary(value))
	candidate_dictionaries.append(unit_data)
	for dictionary_variant in candidate_dictionaries:
		var dictionary: Dictionary = Dictionary(dictionary_variant)
		for key_variant in profile_keys:
			var key: String = String(key_variant).strip_edges()
			if dictionary.has(key):
				return float(dictionary.get(key, fallback))
		for key_variant in unit_data_keys:
			var key: String = String(key_variant).strip_edges()
			if dictionary.has(key):
				return float(dictionary.get(key, fallback))
	return fallback


func _get_homebase_tutor_sort_score(profile, unit_data: Dictionary) -> float:
	var leadership: float = _get_homebase_profile_metric(profile, unit_data, ["leadership"], ["skill_leadership"], 0.0)
	var discipline: float = _get_homebase_profile_metric(profile, unit_data, ["discipline", "order_fidelity"], ["discipline", "skill_discipline"], leadership)
	var speech: float = _get_homebase_profile_metric(profile, unit_data, ["speech", "coordination", "coordinator"], ["speech", "coordinator"], leadership)
	return clampf((leadership * 0.5) + (discipline * 0.25) + (speech * 0.25), 0.0, 1.0)


func _get_homebase_pilot_sort_score(profile, unit_data: Dictionary) -> float:
	var dropship: float = _get_homebase_profile_metric(profile, unit_data, ["dropship_piloting", "piloting", "pilot"], ["dropship_piloting", "skill_piloting", "pilot_score"], -1.0)
	var freighter: float = _get_homebase_profile_metric(profile, unit_data, ["freighter_piloting"], ["freighter_piloting"], -1.0)
	var fighter: float = _get_homebase_profile_metric(profile, unit_data, ["fighter_piloting"], ["fighter_piloting"], -1.0)
	var vehicle: float = _get_homebase_profile_metric(profile, unit_data, ["ground_vehicle_handling"], ["ground_vehicle_handling"], -1.0)
	var best := maxf(maxf(dropship, freighter), maxf(fighter, vehicle))
	if best >= 0.0:
		return clampf(best, 0.0, 1.0)
	var speed: float = _get_homebase_profile_metric(profile, unit_data, ["speed"], ["skill_speed"], 0.0)
	var leadership: float = _get_homebase_profile_metric(profile, unit_data, ["leadership"], ["skill_leadership"], 0.0)
	return clampf((speed * 0.65) + (leadership * 0.35), 0.0, 1.0)


func _get_homebase_xp_sort_score(profile, unit_data: Dictionary) -> float:
	var xp: float = _get_homebase_profile_metric(profile, unit_data, ["xp", "experience", "total_xp"], ["xp", "experience", "total_xp"], -1.0)
	if xp >= 0.0:
		return xp
	var progression: Dictionary = {}
	if profile != null and typeof(profile.get("progression")) == TYPE_DICTIONARY:
		progression = Dictionary(profile.get("progression"))
	for key in ["xp", "experience", "total_xp", "mission_xp"]:
		if progression.has(key):
			return float(progression.get(key, 0.0))
	return 0.0


func _build_homebase_card_pool_key(context: String, unit_id: String, fireteam_id: String = "") -> String:
	var parts: PackedStringArray = PackedStringArray([context.strip_edges().to_lower(), unit_id.strip_edges()])
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if not normalized_fireteam_id.is_empty():
		parts.append(normalized_fireteam_id)
	return "|".join(parts)


func _create_homebase_pool_card(_spec: Dictionary):
	var card = NPC_COMPACT_CARD_SCENE.instantiate()
	card.set_meta("homebase_card_pool_managed", true)
	return card


func _configure_roster_pool_card(card, spec: Dictionary) -> void:
	if card == null:
		return
	var unit_id: String = String(spec.get("unit_id", "")).strip_edges()
	var profile = spec.get("profile", null)
	var is_in_transit: bool = bool(spec.get("is_in_transit", false))
	card.setup_from_profile(
		profile,
		{
			"source_context": "roster",
			"copy_profile": false,
			"secondary_text_override": String(spec.get("secondary_text", "")).strip_edges(),
			"selected": _is_roster_card_highlighted(unit_id),
			"disabled": is_in_transit,
			"drag_enabled": not is_in_transit and not _selected_unit_ids.has(unit_id),
			"compact_mode": true,
			"show_progress": is_in_transit,
			"progress_value": float(spec.get("progress_value", 0.0)),
			"fixed_size": true,
			"fixed_card_size": HOMEBASE_OPERATOR_CARD_SIZE,
		}
	)
	if not card.card_pressed.is_connected(_on_compact_card_pressed):
		card.card_pressed.connect(_on_compact_card_pressed)
	if not card.card_open_requested.is_connected(_on_compact_card_open_requested):
		card.card_open_requested.connect(_on_compact_card_open_requested)
	card.set_meta("homebase_roster_pool_unit_id", unit_id)
	var sort_metrics: Dictionary = Dictionary(spec.get("sort_metrics", {}))
	card.set_meta("homebase_roster_sort_mode", _roster_sort_mode)
	for metric_key in ["leader_score", "tutor_score", "pilot_score", "xp_score", "sort_name"]:
		card.set_meta("homebase_roster_%s" % metric_key, sort_metrics.get(metric_key, "" if metric_key == "sort_name" else 0.0))
	_roster_cards_by_unit_id[unit_id] = card


func _configure_staged_pool_card(card, spec: Dictionary) -> void:
	if card == null:
		return
	var unit_id: String = String(spec.get("unit_id", "")).strip_edges()
	var profile = spec.get("profile", null)
	card.setup_from_profile(
		profile,
		{
			"source_context": "staged",
			"copy_profile": false,
			"secondary_text_override": String(spec.get("secondary_text", "")).strip_edges(),
			"selected": unit_id == _focused_unit_id,
			"disabled": false,
			"drag_enabled": false,
			"compact_mode": true,
			"show_remove_action": true,
			"fixed_size": true,
			"fixed_card_size": HOMEBASE_STAGED_CARD_SIZE,
		}
	)
	if not card.card_pressed.is_connected(_on_compact_card_pressed):
		card.card_pressed.connect(_on_compact_card_pressed)
	if not card.card_open_requested.is_connected(_on_compact_card_open_requested):
		card.card_open_requested.connect(_on_compact_card_open_requested)
	if card.has_signal("remove_requested") and not card.remove_requested.is_connected(_on_staged_card_remove_requested):
		card.remove_requested.connect(_on_staged_card_remove_requested)
	card.set_meta("homebase_staged_pool_unit_id", unit_id)
	_staged_cards_by_unit_id[unit_id] = card


func _clear_homebase_transfer_ghost_cards(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		if bool(child.get_meta("homebase_transfer_ghost_card", false)):
			container.remove_child(child)
			child.queue_free()


func _render_homebase_fireteams() -> void:
	var fireteam_list := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamScroll/FireteamList") as VBoxContainer
	var summary_label := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamSummaryLabel") as Label
	if fireteam_list == null:
		return
	_clear_container(fireteam_list)
	if summary_label != null:
		summary_label.text = _build_homebase_fireteam_summary_text()

	if _fireteam_definitions.is_empty():
		fireteam_list.add_child(_build_empty_state_label("No fireteams available."))
		return

	var rendered_fireteam_count := 0
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty():
			continue
		if _is_homebase_fireteam_in_flightdeck_payload(fireteam_id):
			continue
		var fireteam_card: FOBFireteamCard = _create_homebase_fireteam_card(fireteam_id, "fireteam_list")
		if fireteam_card == null:
			continue
		fireteam_list.add_child(fireteam_card)
		rendered_fireteam_count += 1
		_render_homebase_fireteam_members(fireteam_card.get_member_host(), fireteam_id, String(definition.get("lead_unit_id", "")).strip_edges())
	if rendered_fireteam_count == 0:
		fireteam_list.add_child(_build_empty_state_label("All fireteam cards are currently on the Flightdeck payload."))


func _create_homebase_fireteam_card(fireteam_id: String, source_context: String = "fireteam_list") -> FOBFireteamCard:
	var definition: Dictionary = _get_fireteam_definition(fireteam_id)
	if definition.is_empty():
		return null
	var card: FOBFireteamCard = FOB_FIRETEAM_CARD_SCRIPT.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.setup_card(
		fireteam_id,
		String(definition.get("label", fireteam_id.to_upper())).strip_edges(),
		fireteam_id == _focused_fireteam_id,
		bool(definition.get("respawn_enabled", false)),
		String(definition.get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID)).strip_edges(),
		"Lead: %s | Members: %s" % [
			_build_display_name(String(definition.get("lead_unit_id", "")).strip_edges()),
			_format_member_names(_build_fireteam_member_names(fireteam_id)),
		],
		source_context,
		"Homebase direct staging"
	)
	_apply_homebase_fireteam_card_payload_truth(card, fireteam_id, source_context)
	if not card.card_pressed.is_connected(_on_homebase_fireteam_card_pressed):
		card.card_pressed.connect(_on_homebase_fireteam_card_pressed)
	if not card.rename_committed.is_connected(_on_homebase_fireteam_label_committed):
		card.rename_committed.connect(_on_homebase_fireteam_label_committed)
	if not card.unit_dropped.is_connected(_on_homebase_fireteam_card_unit_dropped):
		card.unit_dropped.connect(_on_homebase_fireteam_card_unit_dropped)
	if source_context == "fireteam_list":
		_configure_homebase_fireteam_header_unit_drop_targets(card, fireteam_id)
	card.set_meta("homebase_direct_fireteam_card", true)
	return card


func _configure_homebase_fireteam_header_unit_drop_targets(card: FOBFireteamCard, fireteam_id: String) -> void:
	if card == null:
		return
	for path in ["Margin/VBox/HeaderRow", "Margin/VBox/HeaderRow/TitleEdit"]:
		var target := card.get_node_or_null(path) as Control
		_configure_homebase_fireteam_unit_drop_target(target, fireteam_id, "lead")


func _configure_homebase_fireteam_unit_drop_target(control: Control, fireteam_id: String, drop_zone: String, anchor_unit_id: String = "", enabled: bool = true) -> void:
	if control == null or _normalize_fireteam_id(fireteam_id).is_empty():
		return
	control.set_script(HOMEBASE_UNIT_DROP_TARGET_SCRIPT)
	if control.has_method("setup_drop_target"):
		control.call("setup_drop_target", fireteam_id, drop_zone, anchor_unit_id, enabled)
	var callback := Callable(self, "_on_homebase_fireteam_unit_drop_target_dropped")
	if control.has_signal("unit_dropped") and not control.is_connected("unit_dropped", callback):
		control.connect("unit_dropped", callback)


func _render_homebase_fireteam_members(member_host: VBoxContainer, fireteam_id: String, lead_unit_id: String) -> void:
	_clear_container(member_host)
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		var member_profile = _profiles_by_id.get(member_unit_id, null)
		if member_profile == null:
			continue
		var member_block := VBoxContainer.new()
		member_block.name = "HomebaseFireteamMemberBlock_%s" % member_unit_id
		member_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		member_block.add_theme_constant_override("separation", 2)
		member_block.set_meta("homebase_fireteam_inline_loadout_block", true)
		member_block.set_meta("fireteam_id", fireteam_id)
		member_block.set_meta("unit_id", member_unit_id)
		_configure_homebase_fireteam_unit_drop_target(member_block, fireteam_id, "member", member_unit_id)
		var member_card = NPC_COMPACT_CARD_SCENE.instantiate()
		member_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		member_card.setup_from_profile(
			member_profile,
			{
				"source_context": "homebase_fireteam",
				"copy_profile": false,
				"selected": member_unit_id == _focused_unit_id,
				"disabled": false,
				"drag_enabled": true,
				"compact_mode": true,
				"show_lead_indicator": true,
				"is_lead": member_unit_id == lead_unit_id,
			}
		)
		if not member_card.card_pressed.is_connected(_on_compact_card_pressed):
			member_card.card_pressed.connect(_on_compact_card_pressed)
		if not member_card.card_open_requested.is_connected(_on_compact_card_open_requested):
			member_card.card_open_requested.connect(_on_compact_card_open_requested)
		var member_drop_callback := Callable(self, "_on_homebase_fireteam_member_card_unit_dropped").bind(fireteam_id, member_unit_id)
		if member_card.has_signal("card_unit_dropped") and not member_card.card_unit_dropped.is_connected(member_drop_callback):
			member_card.card_unit_dropped.connect(member_drop_callback)
		member_block.add_child(member_card)
		member_block.add_child(_build_homebase_fireteam_inline_loadout_row(fireteam_id, member_unit_id))
		member_host.add_child(member_block)


func _update_homebase_loadout_panel() -> void:
	var loadout_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	var fireteam_list := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutFireteamList") as HBoxContainer
	var member_list := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutMemberScroll/LoadoutMemberList") as VBoxContainer
	var status_label := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutStatusLabel") as Label
	if fireteam_list == null or member_list == null:
		return
	_clear_container(fireteam_list)
	_clear_container(member_list)
	if loadout_panel != null and bool(loadout_panel.get_meta("homebase_loadout_window_retired", false)):
		if status_label != null:
			status_label.text = ""
		return
	var fireteam_id: String = _normalize_fireteam_id(_loadout_staged_fireteam_id)
	var has_focus_fireteam: bool = not fireteam_id.is_empty() and not _get_fireteam_definition(fireteam_id).is_empty()
	if status_label != null:
		status_label.text = _build_homebase_loadout_status_text(fireteam_id, has_focus_fireteam)
	if not has_focus_fireteam:
		fireteam_list.add_child(_build_empty_state_label("Drop a fireteam here to edit its loadout."))
		return
	var card = _create_homebase_fireteam_card(fireteam_id, "loadout_staging")
	if card != null:
		fireteam_list.add_child(card)
	var definition: Dictionary = _get_fireteam_definition(fireteam_id)
	var lead_unit_id: String = String(definition.get("lead_unit_id", "")).strip_edges()
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		var row := _build_homebase_loadout_member_row(fireteam_id, member_unit_id, lead_unit_id)
		if row != null:
			member_list.add_child(row)


func _build_homebase_loadout_member_row(fireteam_id: String, unit_id: String, lead_unit_id: String) -> Control:
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return null
	var row_panel := PanelContainer.new()
	row_panel.name = "HomebaseLoadoutMemberRow_%s" % unit_id
	row_panel.custom_minimum_size = Vector2(0.0, 72.0)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	row_panel.set_meta("compact_loadout_member_row", true)
	row_panel.set_meta("homebase_direct_loadout_row", true)
	row_panel.set_meta("fireteam_id", fireteam_id)
	row_panel.set_meta("unit_id", unit_id)
	META_UI_SKIN_SCRIPT.style_tactical_panel(row_panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	row_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "LoadoutRow"
	row.add_theme_constant_override("separation", 5)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)

	var member_secondary_text: String = "Lead" if unit_id == lead_unit_id else "Member"
	var member_card = NPC_COMPACT_CARD_SCENE.instantiate()
	member_card.custom_minimum_size = Vector2(136.0, 54.0)
	member_card.setup_from_profile(
		profile,
		{
			"source_context": "homebase_loadout",
			"copy_profile": false,
			"secondary_text_override": member_secondary_text,
			"selected": unit_id == _focused_unit_id,
			"disabled": false,
			"drag_enabled": false,
			"compact_mode": true,
			"fixed_size": true,
			"fixed_card_size": Vector2(136.0, 54.0),
			"show_lead_indicator": true,
			"is_lead": unit_id == lead_unit_id,
		}
	)
	if not member_card.card_pressed.is_connected(_on_compact_card_pressed):
		member_card.card_pressed.connect(_on_compact_card_pressed)
	if not member_card.card_open_requested.is_connected(_on_compact_card_open_requested):
		member_card.card_open_requested.connect(_on_compact_card_open_requested)
	row.add_child(member_card)

	var controls := VBoxContainer.new()
	controls.name = "LoadoutControls"
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 3)
	row.add_child(controls)

	var member_loadout: Dictionary = _get_member_loadout(unit_id)
	controls.add_child(_build_homebase_loadout_option_row("Armor", _get_homebase_armor_options(), String(member_loadout.get("armor", HOMEBASE_DEFAULT_LOADOUT_ID)), unit_id, "armor"))
	controls.add_child(_build_homebase_loadout_option_row("Primary", _get_homebase_primary_weapon_options(), String(member_loadout.get("weapon_1", HOMEBASE_DEFAULT_PRIMARY_WEAPON)), unit_id, "weapon_1"))
	controls.add_child(_build_homebase_loadout_option_row("Secondary", _get_homebase_secondary_weapon_options(), String(member_loadout.get("weapon_2", HOMEBASE_DEFAULT_SECONDARY_WEAPON)), unit_id, "weapon_2"))
	return row_panel


func _build_homebase_loadout_option_row(label_text: String, options: Array, current_value: String, unit_id: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "%sRow" % key.capitalize()
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(48.0, 0.0)
	label.add_theme_font_size_override("font_size", 9)
	META_UI_SKIN_SCRIPT.style_body_label(label, 9)
	row.add_child(label)
	var selector := OptionButton.new()
	selector.name = "%sSelector" % key.capitalize()
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option_variant in options:
		var option_value: String = String(option_variant).strip_edges()
		_add_homebase_loadout_option(selector, option_value, false)
		if option_value == current_value:
			selector.select(selector.item_count - 1)
	_configure_flightdeck_option_button(selector)
	selector.set_meta("compact_loadout_dropdown", true)
	selector.set_meta("homebase_loadout_unit_id", unit_id)
	selector.set_meta("homebase_loadout_key", key)
	if not selector.item_selected.is_connected(_on_homebase_loadout_option_selected.bind(unit_id, key, selector)):
		selector.item_selected.connect(_on_homebase_loadout_option_selected.bind(unit_id, key, selector))
	row.add_child(selector)
	return row


func _build_homebase_fireteam_inline_loadout_row(fireteam_id: String, unit_id: String) -> Control:
	var member_loadout: Dictionary = _get_member_loadout(unit_id)
	var row := HBoxContainer.new()
	row.name = "InlineLoadoutRow_%s" % unit_id
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 3)
	row.set_meta("homebase_fireteam_inline_loadout_row", true)
	row.set_meta("fireteam_id", fireteam_id)
	row.set_meta("unit_id", unit_id)
	row.add_child(_build_homebase_inline_loadout_selector_pair("A", _get_homebase_armor_options(), String(member_loadout.get("armor", HOMEBASE_DEFAULT_LOADOUT_ID)), unit_id, "armor"))
	row.add_child(_build_homebase_inline_loadout_selector_pair("P", _get_homebase_primary_weapon_options(), String(member_loadout.get("weapon_1", HOMEBASE_DEFAULT_PRIMARY_WEAPON)), unit_id, "weapon_1"))
	row.add_child(_build_homebase_inline_loadout_selector_pair("S", _get_homebase_secondary_weapon_options(), String(member_loadout.get("weapon_2", HOMEBASE_DEFAULT_SECONDARY_WEAPON)), unit_id, "weapon_2"))
	return row


func _build_homebase_inline_loadout_selector_pair(label_text: String, options: Array, current_value: String, unit_id: String, key: String) -> Control:
	var pair := HBoxContainer.new()
	pair.name = "%sInlinePair" % key.capitalize()
	pair.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pair.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(10.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	META_UI_SKIN_SCRIPT.style_body_label(label, 8)
	pair.add_child(label)

	var selector := OptionButton.new()
	selector.name = "%sInlineSelector" % key.capitalize()
	selector.custom_minimum_size = HOMEBASE_FIRETEAM_INLINE_LOADOUT_SELECTOR_SIZE
	selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selector.add_theme_font_size_override("font_size", 8)
	selector.clip_text = true
	_set_object_property_if_available(selector, "fit_to_longest_item", false)
	for option_variant in options:
		var option_value: String = String(option_variant).strip_edges()
		_add_homebase_loadout_option(selector, option_value, true)
		if option_value == current_value:
			selector.select(selector.item_count - 1)
	_configure_flightdeck_option_button(selector)
	selector.set_meta("compact_loadout_dropdown", true)
	selector.set_meta("homebase_fireteam_inline_loadout_dropdown", true)
	selector.set_meta("homebase_loadout_unit_id", unit_id)
	selector.set_meta("homebase_loadout_key", key)
	if not selector.item_selected.is_connected(_on_homebase_loadout_option_selected.bind(unit_id, key, selector)):
		selector.item_selected.connect(_on_homebase_loadout_option_selected.bind(unit_id, key, selector))
	pair.add_child(selector)
	return pair


func _add_homebase_loadout_option(selector: OptionButton, option_value: String, compact: bool) -> void:
	if selector == null:
		return
	var normalized_value: String = option_value.strip_edges().to_lower()
	var label_text: String = _build_homebase_compact_loadout_option_label(normalized_value) if compact else _build_homebase_loadout_option_label(normalized_value)
	var icon: Texture2D = _get_homebase_loadout_preview_icon(normalized_value)
	if icon != null:
		selector.add_icon_item(icon, label_text)
		selector.set_meta("homebase_loadout_preview_icon_count", int(selector.get_meta("homebase_loadout_preview_icon_count", 0)) + 1)
	else:
		selector.add_item(label_text)
	var item_index: int = selector.item_count - 1
	selector.set_item_metadata(item_index, normalized_value)
	selector.set_meta("homebase_loadout_preview_icon_max_width", HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE.x)
	selector.set_meta("homebase_loadout_preview_icon_max_height", HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE.y)
	if selector.has_method("set_item_icon_max_width"):
		selector.call("set_item_icon_max_width", item_index, HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE.x)
	var popup := selector.get_popup()
	if popup != null and popup.has_method("set_item_icon_max_width"):
		popup.call("set_item_icon_max_width", item_index, HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE.x)


func _get_homebase_loadout_preview_icon(option_value: String) -> Texture2D:
	var normalized_value: String = option_value.strip_edges().to_lower()
	if normalized_value.is_empty() or _get_homebase_armor_options().has(normalized_value):
		return null
	if _homebase_loadout_preview_texture_cache.has(normalized_value):
		return _homebase_loadout_preview_texture_cache.get(normalized_value, null) as Texture2D
	var preview_path: String = String(WEAPON_DATA_SCRIPT.call("get_preview_path", normalized_value)).strip_edges()
	if preview_path.is_empty() or not ResourceLoader.exists(preview_path):
		_homebase_loadout_preview_texture_cache[normalized_value] = null
		return null
	var source_texture := load(preview_path) as Texture2D
	var preview_texture: Texture2D = _build_homebase_scaled_preview_texture(source_texture)
	_homebase_loadout_preview_texture_cache[normalized_value] = preview_texture
	return preview_texture


func _build_homebase_scaled_preview_texture(source_texture: Texture2D) -> Texture2D:
	if source_texture == null:
		return null
	var image: Image = source_texture.get_image()
	if image == null or image.is_empty():
		return source_texture
	var width: int = maxi(image.get_width(), 1)
	var height: int = maxi(image.get_height(), 1)
	var ratio: float = minf(
		float(HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE.x) / float(width),
		float(HOMEBASE_LOADOUT_DROPDOWN_ICON_MAX_SIZE.y) / float(height)
	)
	if ratio >= 1.0:
		return source_texture
	var scaled_width: int = maxi(1, int(roundf(float(width) * ratio)))
	var scaled_height: int = maxi(1, int(roundf(float(height) * ratio)))
	image.resize(scaled_width, scaled_height, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _build_homebase_loadout_option_label(option_value: String) -> String:
	var normalized_value: String = option_value.strip_edges().to_lower()
	if normalized_value == "light" or normalized_value == "medium" or normalized_value == "heavy":
		return String(LOADOUT_CONTRACT_SCRIPT.call("get_armor_label", normalized_value))
	return String(LOADOUT_CONTRACT_SCRIPT.call("get_weapon_label", normalized_value))


func _build_homebase_compact_loadout_option_label(option_value: String) -> String:
	var normalized_value: String = option_value.strip_edges().to_lower()
	if _get_homebase_armor_options().has(normalized_value):
		return String(LOADOUT_CONTRACT_SCRIPT.call("get_compact_armor_label", normalized_value))
	return String(LOADOUT_CONTRACT_SCRIPT.call("get_compact_weapon_label", normalized_value))


func _get_homebase_armor_options() -> Array:
	return Array(LOADOUT_CONTRACT_SCRIPT.call("get_armor_ids"))


func _get_homebase_primary_weapon_options() -> Array:
	return Array(LOADOUT_CONTRACT_SCRIPT.call("get_homebase_primary_weapon_ids"))


func _get_homebase_secondary_weapon_options() -> Array:
	return Array(LOADOUT_CONTRACT_SCRIPT.call("get_homebase_secondary_weapon_ids"))


func _update_homebase_flightdeck_staging_panel() -> void:
	var panel := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel") as PanelContainer
	var list := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DirectDropshipFireteamPanel/DirectDropshipMargin/DirectDropshipVBox/DirectDropshipList") as VBoxContainer
	if list == null:
		return
	var status_label := _ensure_homebase_direct_staging_status_label(panel) if panel != null else null
	var craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate()
	if status_label != null:
		var status_text: String = _build_homebase_direct_staging_status_text(craft_gate)
		status_label.text = status_text
		status_label.set_meta("homebase_direct_payload_status_text", status_text)
		status_label.set_meta("homebase_direct_payload_operator_count", _get_homebase_direct_payload_operator_count())
		status_label.set_meta("homebase_direct_boarded_operator_count", _get_homebase_direct_boarded_operator_count())
		status_label.set_meta("homebase_direct_boarding_progress_ratio", _get_homebase_direct_boarding_progress_ratio())
		status_label.set_meta("homebase_direct_payload_fireteam_count", _get_homebase_direct_payload_fireteam_ids().size())
		status_label.set_meta("homebase_direct_craft_block_reason", String(craft_gate.get("block_reason", "")).strip_edges())
		status_label.set_meta("homebase_direct_craft_ready", bool(craft_gate.get("can_stage", false)))
	_clear_container(list)
	if _homebase_dropship_staged_fireteam_ids.is_empty():
		list.add_child(_build_empty_state_label("Drop fireteam cards here to board the selected dropship."))
		return
	if not _get_homebase_direct_payload_craft_id().is_empty():
		list.add_child(_build_empty_state_label("Payload fireteam cards are shown on the assigned dropship card."))
		return
	for fireteam_id in _filter_existing_fireteam_ids(_homebase_dropship_staged_fireteam_ids):
		var fireteam_card := _build_homebase_dropship_fireteam_card(String(fireteam_id), _get_homebase_direct_payload_craft_id(), "homebase_dropship_staging")
		if fireteam_card != null:
			list.add_child(fireteam_card)


func _build_homebase_dropship_fireteam_card(fireteam_id: String, craft_id: String, source_context: String = "dropship_wait") -> Control:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return null
	var card: FOBFireteamCard = _create_homebase_fireteam_card(normalized_fireteam_id, source_context)
	if card == null:
		return null
	card.custom_minimum_size = Vector2(0.0, card.custom_minimum_size.y)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("homebase_shipcard_payload_row", true)
	card.set_meta("homebase_shipcard_payload_fireteam_card", true)
	card.set_meta("craft_id", craft_id.strip_edges())
	card.set_meta("fireteam_id", normalized_fireteam_id)
	card.set_meta("homebase_fireteam_single_visual_owner", "flightdeck")
	var craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate() if craft_id.strip_edges().is_empty() else _build_homebase_direct_staging_craft_gate_for_craft(craft_id)
	var status: Dictionary = _build_homebase_fireteam_payload_status(normalized_fireteam_id, HOMEBASE_DIRECT_STAGING_DROP_KIND, craft_gate)
	card.set_meta("homebase_direct_payload_status", String(status.get("status", "")).strip_edges())
	card.set_meta("homebase_direct_payload_operator_count", int(status.get("operator_count", 0)))
	card.set_meta("homebase_direct_payload_fireteam_count", _get_homebase_direct_payload_fireteam_ids_for_craft(craft_id).size())
	card.set_meta("homebase_direct_payload_boarded", bool(status.get("boarded", false)))
	card.set_meta("homebase_direct_payload_block_reason", String(status.get("block_reason", "")).strip_edges())
	card.set_meta("homebase_direct_payload_boarding_progress", _build_homebase_boarding_progress_value(normalized_fireteam_id, craft_gate))
	_apply_homebase_dropship_payload_card_presentation(card)
	_render_homebase_dropship_member_progress_rows(card.get_member_host(), normalized_fireteam_id, craft_gate)
	return card


func _apply_homebase_dropship_payload_card_presentation(card: FOBFireteamCard) -> void:
	if card == null:
		return
	_apply_homebase_fireteam_card_clean_presentation(card)
	card.set_meta("homebase_shipcard_payload_debug_labels_hidden", true)


func _apply_homebase_fireteam_card_clean_presentation(card: FOBFireteamCard) -> void:
	if card == null:
		return
	for label_path in [
		"Margin/VBox/StageLabel",
		"Margin/VBox/MemberLabel",
		"Margin/VBox/TeamfitLabel",
		"Margin/VBox/DropHintLabel",
	]:
		var label := card.get_node_or_null(label_path) as Label
		if label == null:
			continue
		label.text = ""
		label.visible = false
		label.set_meta("homebase_fireteam_aux_label_hidden", true)
		label.set_meta("homebase_shipcard_payload_aux_label_hidden", true)
	var title_edit := card.get_node_or_null("Margin/VBox/HeaderRow/TitleEdit") as LineEdit
	if title_edit != null:
		title_edit.add_theme_font_size_override("font_size", 10)
		title_edit.custom_minimum_size = Vector2(0.0, 20.0)
	card.set_meta("homebase_fireteam_clean_presentation", true)


func _render_homebase_dropship_member_progress_rows(container: VBoxContainer, fireteam_id: String, craft_gate: Dictionary) -> void:
	if container == null:
		return
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(normalized_fireteam_id)
	var status_label := Label.new()
	status_label.name = "HomebaseBoardingStatusLabel_%s" % normalized_fireteam_id
	status_label.text = _build_homebase_boarding_progress_text(normalized_fireteam_id, craft_gate)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.set_meta("homebase_shipcard_payload_progress_label", true)
	status_label.set_meta("fireteam_id", normalized_fireteam_id)
	status_label.set_meta("homebase_direct_payload_boarding_progress", _build_homebase_boarding_progress_value(normalized_fireteam_id, craft_gate))
	META_UI_SKIN_SCRIPT.style_body_label(status_label, 8)
	container.add_child(status_label)

	for member_unit_id in member_ids:
		var member_row := HBoxContainer.new()
		member_row.name = "HomebaseBoardingMember_%s" % member_unit_id
		member_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		member_row.add_theme_constant_override("separation", 4)
		member_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		member_row.set_meta("homebase_shipcard_payload_member_row", true)
		member_row.set_meta("fireteam_id", normalized_fireteam_id)
		member_row.set_meta("unit_id", member_unit_id)
		container.add_child(member_row)

		var member_profile = _profiles_by_id.get(member_unit_id, null)
		var portrait := TextureRect.new()
		portrait.name = "PayloadMemberPortrait_%s" % member_unit_id
		portrait.custom_minimum_size = Vector2(18.0, 18.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		portrait.texture = _load_portrait_texture(String(member_profile.portrait_path)) if member_profile != null else null
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.set_meta("homebase_shipcard_payload_mini_portrait", true)
		portrait.set_meta("homebase_shipcard_payload_member_portrait", true)
		portrait.set_meta("fireteam_id", normalized_fireteam_id)
		portrait.set_meta("unit_id", member_unit_id)
		member_row.add_child(portrait)

		var name_label := Label.new()
		name_label.text = _build_display_name(member_unit_id)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", 8)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		META_UI_SKIN_SCRIPT.style_body_label(name_label, 8)
		member_row.add_child(name_label)

		var state_label := Label.new()
		state_label.text = _build_homebase_member_boarding_status_text(normalized_fireteam_id, member_unit_id, craft_gate)
		state_label.custom_minimum_size = Vector2(54.0, 0.0)
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		state_label.add_theme_font_size_override("font_size", 8)
		state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		META_UI_SKIN_SCRIPT.style_body_label(state_label, 8)
		member_row.add_child(state_label)

		var progress_bar := ProgressBar.new()
		progress_bar.name = "HomebaseBoardingProgress_%s" % member_unit_id
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = _build_homebase_member_boarding_progress_value(normalized_fireteam_id, member_unit_id, craft_gate)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size = Vector2(0.0, 7.0)
		progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress_bar.set_meta("homebase_shipcard_payload_member_progress", true)
		progress_bar.set_meta("fireteam_id", normalized_fireteam_id)
		progress_bar.set_meta("unit_id", member_unit_id)
		progress_bar.set_meta("homebase_direct_payload_boarding_progress", progress_bar.value)
		container.add_child(progress_bar)


func _render_team_transfer_ghost_cards(selected_team_list: VBoxContainer) -> void:
	var rendered_unit_ids: Dictionary = {}
	for entry_variant in _team_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		for unit_id_variant in Array(entry.get("unit_ids", [])):
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty() or _selected_unit_ids.has(unit_id) or rendered_unit_ids.has(unit_id):
				continue

			var profile = _build_transfer_card_profile(unit_id, entry)
			if profile == null:
				continue

			var secondary_text: String = _build_transfer_ghost_secondary_text(entry)

			var card = NPC_COMPACT_CARD_SCENE.instantiate()
			card.set_meta("homebase_transfer_ghost_card", true)
			card.set_meta("transfer_id", String(entry.get("transfer_id", "")).strip_edges())
			card.setup_from_profile(
				profile,
				{
					"source_context": "transfer_ghost",
					"copy_profile": false,
					"secondary_text_override": secondary_text,
					"selected": false,
					"disabled": true,
					"drag_enabled": false,
					"compact_mode": true,
					"show_progress": true,
					"progress_value": _build_transfer_progress_value(entry),
					"fixed_size": true,
					"fixed_card_size": HOMEBASE_TRANSFER_GHOST_CARD_SIZE,
				}
			)
			if not card.card_pressed.is_connected(_on_compact_card_pressed):
				card.card_pressed.connect(_on_compact_card_pressed)
			if not card.card_open_requested.is_connected(_on_compact_card_open_requested):
				card.card_open_requested.connect(_on_compact_card_open_requested)
			selected_team_list.add_child(card)
			rendered_unit_ids[unit_id] = true


func _build_transfer_card_profile(unit_id: String, entry: Dictionary):
	var profile = _profiles_by_id.get(unit_id, null)
	if profile != null and profile.has_method("duplicate_profile"):
		return profile

	for unit_variant in Array(entry.get("unit_profiles", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_variant)
		if String(unit_data.get("unit_id", "")).strip_edges() != unit_id:
			continue
		var transfer_profiles: Dictionary = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id([unit_data])
		return transfer_profiles.get(unit_id, null)

	var fallback_profiles: Dictionary = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id(
		[
			{
				"unit_id": unit_id,
				"display_name": unit_id.replace("_", " ").capitalize(),
				"role_name": "Operator",
				"availability_status": "in_transit",
				"status_text": "In Transit",
			}
		]
	)
	return fallback_profiles.get(unit_id, null)


func _build_transfer_ghost_secondary_text(entry: Dictionary) -> String:
	return "Transit to FOB | ETA %s" % _build_transfer_eta_text(entry)


func _update_team_summary() -> void:
	var confirm_button: Button = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/ConfirmButton")
	var team_status_label: Label = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamStatusLabel")
	var selected_names_label: Label = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/SelectedNamesLabel")
	var team_panel: Control = get_node("Panel/Margin/VBox/ContentRow/TeamPanel")
	var roster_panel: Control = get_node("Panel/Margin/VBox/ContentRow/RosterPanel")
	var aircraft_panel: Control = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel")
	var info_panel: Control = get_node("Panel/Margin/VBox/ContentRow/InfoPanel")
	var fireteam_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") as Control
	var loadout_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel") as Control
	var mission_panel: Control = get_node("Panel/Margin/VBox/MissionPanel")
	var team_drop_panel = _get_team_drop_panel()

	confirm_button.disabled = _selected_unit_ids.is_empty()
	META_UI_SKIN_SCRIPT.style_transfer_button(confirm_button, not _selected_unit_ids.is_empty())
	team_status_label.text = "Staged team: %d / %d" % [_selected_unit_ids.size(), _get_team_capacity()]
	selected_names_label.text = _build_selected_names_text()
	confirm_button.tooltip_text = _build_send_to_fob_tooltip()
	team_panel.tooltip_text = _build_team_hint_text()
	roster_panel.tooltip_text = _build_roster_tooltip_text()
	aircraft_panel.tooltip_text = _build_aircraft_tooltip_text()
	info_panel.tooltip_text = _build_character_sheet_tooltip_text()
	if fireteam_panel != null:
		fireteam_panel.tooltip_text = "FIRETEAMS\n\n- Drop operators on fireteam cards.\n- Use inline dropdowns for loadout.\n- Drop fireteam cards to Flightdeck."
	if loadout_panel != null:
		loadout_panel.tooltip_text = ""
	mission_panel.tooltip_text = _build_mission_tooltip_text()
	if team_drop_panel != null:
		team_drop_panel.tooltip_text = _build_team_hint_text()
		team_drop_panel.set_drop_enabled(_selected_unit_ids.size() < _get_team_capacity())


func _update_mission_info() -> void:
	var mission_selector: OptionButton = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector")
	var start_mission_button: Button = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton")
	var mission_name_label: Label = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionNameLabel")
	var mission_team_limit_label: Label = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTeamLimitLabel")
	var mission_transfer_label: Label = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTransferLabel")
	var mission_summary_label: Label = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel")

	_populate_mission_selector(mission_selector)
	var team_capacity: int = _get_team_capacity()
	var staged_count: int = _selected_unit_ids.size()
	var pilot_count: int = _mission_pilot_count_override if _mission_pilot_count_override >= 0 else _count_assigned_pilots()
	var mission_slot_usage: int = _mission_slot_usage_override if _mission_slot_usage_override >= 0 else staged_count + pilot_count
	var direct_craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate()
	var direct_payload_fireteam_count: int = _get_homebase_direct_payload_fireteam_ids().size()
	var direct_payload_operator_count: int = _get_homebase_direct_payload_operator_count()
	var direct_boarded_operator_count: int = _get_homebase_direct_boarded_operator_count()
	var direct_payload_status_text: String = _build_homebase_direct_payload_status_text(direct_craft_gate, false)
	var direct_payload_ready: bool = _has_homebase_direct_launch_payload()
	var can_start_mission: bool = can_request_mission_start()
	start_mission_button.disabled = not can_start_mission
	start_mission_button.text = "Start"
	start_mission_button.set_meta("homebase_direct_payload_ready", direct_payload_ready)
	start_mission_button.set_meta("homebase_direct_payload_operator_count", direct_payload_operator_count)
	start_mission_button.set_meta("homebase_direct_boarded_operator_count", direct_boarded_operator_count)
	start_mission_button.set_meta("homebase_direct_boarding_progress_ratio", _get_homebase_direct_boarding_progress_ratio())
	start_mission_button.set_meta("homebase_direct_payload_fireteam_count", direct_payload_fireteam_count)
	start_mission_button.set_meta("homebase_direct_payload_status_text", direct_payload_status_text)
	META_UI_SKIN_SCRIPT.style_transfer_button(start_mission_button, can_start_mission)
	mission_name_label.text = _selected_mission_name
	mission_team_limit_label.text = "Mission slots: %d / %d" % [mission_slot_usage, _selected_mission_slot_count]
	mission_team_limit_label.set_meta("mission_slot_usage_count", mission_slot_usage)
	mission_team_limit_label.set_meta("mission_operator_count", staged_count)
	mission_team_limit_label.set_meta("mission_pilot_count", pilot_count)
	var launch_text: String = _mission_launch_summary if not _mission_launch_summary.is_empty() else ("Homebase dropship ready" if direct_payload_ready else ("Dropship ready for launch" if _mission_launch_ready else "Dropship not launch-ready"))
	mission_transfer_label.text = "Map: %s | Transfer: %s | Pilots: %d | %s | %s" % [_build_selected_mission_map_label(), _build_transfer_status_text(staged_count, team_capacity), pilot_count, launch_text, direct_payload_status_text]
	mission_transfer_label.set_meta("homebase_direct_payload_ready", direct_payload_ready)
	mission_transfer_label.set_meta("homebase_direct_payload_operator_count", direct_payload_operator_count)
	mission_transfer_label.set_meta("homebase_direct_boarded_operator_count", direct_boarded_operator_count)
	mission_transfer_label.set_meta("homebase_direct_boarding_progress_ratio", _get_homebase_direct_boarding_progress_ratio())
	mission_transfer_label.set_meta("homebase_direct_payload_fireteam_count", direct_payload_fireteam_count)
	mission_transfer_label.set_meta("homebase_direct_payload_status_text", direct_payload_status_text)
	mission_summary_label.text = _build_mission_summary_text(staged_count, team_capacity, pilot_count, mission_slot_usage)
	if not _mission_launch_summary.is_empty():
		mission_summary_label.text = "%s\n%s" % [mission_summary_label.text, _mission_launch_summary]
	mission_summary_label.set_meta("homebase_direct_payload_ready", direct_payload_ready)
	mission_summary_label.set_meta("homebase_direct_payload_operator_count", direct_payload_operator_count)
	mission_summary_label.set_meta("homebase_direct_boarded_operator_count", direct_boarded_operator_count)
	mission_summary_label.set_meta("homebase_direct_boarding_progress_ratio", _get_homebase_direct_boarding_progress_ratio())
	mission_summary_label.set_meta("homebase_direct_payload_fireteam_count", direct_payload_fireteam_count)
	mission_summary_label.set_meta("homebase_direct_payload_status_text", direct_payload_status_text)
	_update_personnel_notifications()
	_update_mission_briefing_panel()


func _update_personnel_notifications() -> void:
	var label: Label = _ensure_personnel_notifications_label()
	var messages: PackedStringArray = _build_personnel_notification_messages()
	if messages.is_empty():
		label.visible = false
		label.text = ""
		return
	label.visible = true
	label.text = "Personnel: %s" % " | ".join(messages)


func _ensure_personnel_notifications_label() -> Label:
	var mission_vbox := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	var existing := mission_vbox.get_node_or_null("PersonnelEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "PersonnelEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 8)
	META_UI_SKIN_SCRIPT.style_body_label(label, 8)
	mission_vbox.add_child(label)
	var summary_label := mission_vbox.get_node_or_null("MissionSummaryLabel")
	if summary_label != null:
		mission_vbox.move_child(label, summary_label.get_index() + 1)
	return label


func _update_mission_briefing_panel() -> void:
	_selected_mission_scenario_path = _resolve_selected_mission_scenario_path()
	var panel := _ensure_mission_briefing_panel()
	if _selected_mission_scenario_path.strip_edges().is_empty():
		_mission_briefing_panel_snapshot = Dictionary(_mission_briefing_panel_presenter.call("build_snapshot_from_files", "", _selected_mission_map_path, "multiplayer_pvp"))
		panel.visible = false
		return
	_mission_briefing_panel_snapshot = Dictionary(_mission_briefing_panel_presenter.call(
		"build_snapshot_from_files",
		_selected_mission_scenario_path,
		_selected_mission_map_path,
		"multiplayer_pvp"
	))
	panel.visible = bool(_mission_briefing_panel_snapshot.get("configured", false))
	_set_mission_briefing_label("BriefingTitleLabel", String(_mission_briefing_panel_snapshot.get("title", "Mission Briefing")).strip_edges())
	_set_mission_briefing_label("BriefingSummaryLabel", String(_mission_briefing_panel_snapshot.get("summary", "")).strip_edges())
	_set_mission_briefing_label("BriefingStatusLabel", String(_mission_briefing_panel_snapshot.get("panel_status_text", "")).strip_edges())
	_set_mission_briefing_label("BriefingObjectivesLabel", "Ziele: %s" % String(_mission_briefing_panel_snapshot.get("objective_text", "-")).strip_edges())
	_set_mission_briefing_label("BriefingThreatsLabel", "Risiken: %s" % String(_mission_briefing_panel_snapshot.get("threat_text", "-")).strip_edges())
	_set_mission_briefing_label("BriefingTeamsLabel", "Teams: %s" % String(_mission_briefing_panel_snapshot.get("team_spawn_text", "-")).strip_edges())
	_set_mission_briefing_label("BriefingLoadoutLabel", "Empfohlen: %s" % String(_mission_briefing_panel_snapshot.get("loadout_text", "-")).strip_edges())
	_set_mission_briefing_minimap_visual(Dictionary(_mission_briefing_panel_snapshot.get("minimap_visual_snapshot", {})))
	panel.set_meta("mission_briefing_snapshot", _mission_briefing_panel_snapshot.duplicate(true))


func _ensure_mission_briefing_panel() -> PanelContainer:
	var mission_vbox := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	var existing := mission_vbox.get_node_or_null("MissionBriefingPanel") as PanelContainer
	if existing != null:
		return existing
	var panel := PanelContainer.new()
	panel.name = "MissionBriefingPanel"
	panel.custom_minimum_size = Vector2(0.0, 220.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "body")
	var margin := MarginContainer.new()
	margin.name = "BriefingMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "BriefingVBox"
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	for label_name in [
		"BriefingTitleLabel",
		"BriefingSummaryLabel",
		"BriefingStatusLabel",
		"BriefingMinimapVisual",
		"BriefingObjectivesLabel",
		"BriefingThreatsLabel",
		"BriefingTeamsLabel",
		"BriefingLoadoutLabel",
	]:
		if label_name == "BriefingMinimapVisual":
			var minimap_visual: Control = MISSION_BRIEFING_MINIMAP_VISUAL_SCRIPT.new()
			minimap_visual.name = label_name
			minimap_visual.custom_minimum_size = Vector2(0.0, 96.0)
			minimap_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			minimap_visual.mouse_filter = Control.MOUSE_FILTER_PASS
			vbox.add_child(minimap_visual)
			continue
		var label := Label.new()
		label.name = label_name
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var font_size: int = 9
		if label_name == "BriefingTitleLabel":
			font_size = 11
			META_UI_SKIN_SCRIPT.style_header_label(label, font_size)
			label.add_theme_color_override("font_color", Color("e7edf4"))
		else:
			META_UI_SKIN_SCRIPT.style_body_label(label, font_size)
			label.add_theme_color_override("font_color", Color("cad7df"))
		vbox.add_child(label)
	mission_vbox.add_child(panel)
	var anchor := mission_vbox.get_node_or_null("PersonnelEventsLabel")
	if anchor == null:
		anchor = mission_vbox.get_node_or_null("MissionSummaryLabel")
	if anchor != null:
		mission_vbox.move_child(panel, anchor.get_index() + 1)
	return panel


func _set_mission_briefing_label(label_name: String, text: String) -> void:
	var label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/%s" % label_name) as Label
	if label == null:
		return
	label.text = text
	label.tooltip_text = text


func _set_mission_briefing_minimap_visual(snapshot: Dictionary) -> void:
	var minimap_visual := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingMinimapVisual") as Control
	if minimap_visual == null or not minimap_visual.has_method("set_visual_snapshot"):
		return
	minimap_visual.visible = bool(snapshot.get("configured", false))
	minimap_visual.call("set_visual_snapshot", snapshot)


func _build_personnel_notification_messages() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for event_variant in _personnel_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		var message: String = String(PERSONNEL_EVENT_MODEL_SCRIPT.call("format_event_message", event)).strip_edges()
		if message.is_empty():
			continue
		result.append(message)
		if result.size() >= 2:
			break
	return result


func _update_team_transfer_list() -> void:
	var transfer_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersScroll/ActiveTransfersList")
	_clear_container(transfer_list)

	if _team_transfer_entries.is_empty():
		transfer_list.add_child(_build_empty_state_label("No team currently inbound to FOB."))
		return

	for entry_variant in _team_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		transfer_list.add_child(_build_transfer_entry_card(_build_team_transfer_title(entry), _build_team_transfer_detail(entry), entry))


func _update_aircraft_panel() -> void:
	var selector: OptionButton = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AircraftSelector")
	var add_aircraft_button: Button = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AddAircraftButton")
	var remove_aircraft_button: Button = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/RemoveAircraftButton")
	var aircraft_cargo_row: HBoxContainer = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow")
	var cargo_selector: OptionButton = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/CargoSelector")
	var load_cargo_button: Button = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/LoadCargoButton")
	var status_label: Label = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftStatusLabel")
	var shipcards_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/ShipCardsScroll/ShipCardsList")
	var transfers_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll/AircraftTransfersList")

	_populate_aircraft_selector(selector)
	add_aircraft_button.disabled = false
	remove_aircraft_button.visible = false
	aircraft_cargo_row.visible = false
	cargo_selector.clear()
	cargo_selector.disabled = true
	load_cargo_button.text = "Load"
	load_cargo_button.disabled = true
	META_UI_SKIN_SCRIPT.style_secondary_button(load_cargo_button)
	_clear_container(shipcards_list)
	_clear_container(transfers_list)
	var visible_aircraft_definitions: Array = _get_visible_homebase_aircraft_definitions()

	var selected_craft: Dictionary = _get_selected_aircraft_definition()
	if selected_craft.is_empty():
		selector.disabled = selector.item_count == 0
		remove_aircraft_button.disabled = true
		status_label.text = "Flight deck empty. Select a ship above and press + to add a shipcard."
		shipcards_list.add_child(_build_empty_state_label("Flight deck starts empty. Select a craft type above and press + to add it here."))
		transfers_list.add_child(_build_empty_state_label("No loading or ship flights queued."))
		return

	selector.disabled = selector.item_count == 0
	var selected_craft_id: String = String(selected_craft.get("craft_id", "")).strip_edges()
	var craft_name: String = String(selected_craft.get("display_name", selected_craft_id)).strip_edges()
	var assigned_pilot_id: String = _get_assigned_pilot_id(selected_craft_id)
	var craft_in_transit: bool = _is_craft_in_transit(selected_craft_id)
	var craft_busy: bool = _has_active_pilot_transfer_for_craft(selected_craft_id) or craft_in_transit
	var cargo_loading: bool = _has_active_cargo_load_for_craft(selected_craft_id)
	status_label.text = _build_aircraft_status_text(selected_craft, craft_name, assigned_pilot_id, craft_busy, cargo_loading)

	_render_homebase_shipcards(shipcards_list, visible_aircraft_definitions)

	var visible_entries: Array = []
	visible_entries.append_array(_get_visible_cargo_load_entries(selected_craft_id))
	visible_entries.append_array(_get_visible_pilot_transfer_entries(selected_craft_id))
	if visible_entries.is_empty():
		transfers_list.add_child(_build_empty_state_label("No loading or ship flights currently active."))
		return

	for entry_variant in visible_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("entry_type", "")).strip_edges() == "cargo_load":
			transfers_list.add_child(_build_transfer_entry_card(_build_cargo_load_title(entry), _build_cargo_load_detail(entry), entry))
		else:
			transfers_list.add_child(_build_transfer_entry_card(_build_pilot_transfer_title(entry), _build_pilot_transfer_detail(entry), entry))


func _render_homebase_shipcards(shipcards_list: VBoxContainer, visible_aircraft_definitions: Array) -> void:
	if shipcards_list == null:
		return
	shipcards_list.add_theme_constant_override("separation", 6)
	shipcards_list.set_meta("homebase_shipcards_two_column_layout", true)
	shipcards_list.set_meta("homebase_shipcard_compact_width", HOMEBASE_SHIPCARD_COMPACT_WIDTH)
	var row: HBoxContainer = null
	for craft_index in range(visible_aircraft_definitions.size()):
		if craft_index % 2 == 0:
			row = HBoxContainer.new()
			row.name = "ShipCardRow_%d" % int(craft_index / 2)
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 6)
			row.set_meta("homebase_shipcard_row", true)
			shipcards_list.add_child(row)
		var shipcard := _build_shipcard(Dictionary(visible_aircraft_definitions[craft_index]))
		if shipcard != null and row != null:
			row.add_child(shipcard)


func _update_drop_light_flightdeck_stage() -> void:
	var stage_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage") as Control
	if stage_panel == null or not stage_panel.visible:
		return
	var pad_stage := stage_panel.get_node_or_null("Margin/PadStage") as Control
	if pad_stage == null:
		return
	for child in pad_stage.get_children():
		pad_stage.remove_child(child)
		child.queue_free()

	var platform := TextureRect.new()
	platform.name = "PlatformTexture"
	platform.texture = FLIGHTDECK_PLATFORM_TEXTURE
	platform.position = Vector2(132.0, 72.0)
	platform.custom_minimum_size = Vector2(220.0, 112.0)
	platform.size = platform.custom_minimum_size
	platform.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	platform.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
	platform.set_meta("drop_light_asset_path", FLIGHTDECK_PLATFORM_TEXTURE.resource_path)
	pad_stage.add_child(platform)

	var visible_aircraft_definitions: Array = _get_visible_homebase_aircraft_definitions()
	var craft_positions: Array[Vector2] = [
		Vector2(40.0, 24.0),
		Vector2(246.0, 20.0),
		Vector2(152.0, 118.0),
	]
	var craft_index := 0
	for craft_variant in visible_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			continue
		var craft_texture: Texture2D = _get_aircraft_texture(craft_def)
		if craft_texture == null:
			continue
		var craft_position: Vector2 = craft_positions[mini(craft_index, craft_positions.size() - 1)] + Vector2(float((craft_index / craft_positions.size()) * 28), 0.0)
		var craft_texture_rect := TextureRect.new()
		craft_texture_rect.name = "CraftTexture_%s" % craft_id
		craft_texture_rect.texture = craft_texture
		craft_texture_rect.position = craft_position
		craft_texture_rect.custom_minimum_size = Vector2(132.0, 80.0)
		craft_texture_rect.size = craft_texture_rect.custom_minimum_size
		craft_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		craft_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		craft_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		craft_texture_rect.modulate = Color(1.0, 1.0, 1.0, 0.52) if _is_craft_in_transit(craft_id) else Color(1.0, 1.0, 1.0, 1.0)
		craft_texture_rect.set_meta("drop_light_asset_path", craft_texture.resource_path)
		craft_texture_rect.set_meta("craft_id", craft_id)
		pad_stage.add_child(craft_texture_rect)

		var stack_label := Label.new()
		stack_label.name = "CraftStack_%s" % craft_id
		stack_label.position = craft_position + Vector2(8.0, 70.0)
		stack_label.custom_minimum_size = Vector2(148.0, 44.0)
		stack_label.size = stack_label.custom_minimum_size
		stack_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack_label.text = _build_drop_light_craft_stage_text(craft_def)
		stack_label.add_theme_font_size_override("font_size", 9)
		META_UI_SKIN_SCRIPT.style_body_label(stack_label, 9)
		pad_stage.add_child(stack_label)
		craft_index += 1


func _build_drop_light_craft_stage_text(craft_def: Dictionary) -> String:
	var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
	var craft_name: String = String(craft_def.get("display_name", craft_id)).strip_edges()
	var pilot_id: String = _get_assigned_pilot_id(craft_id)
	var pilot_text: String = _build_display_name(pilot_id) if not pilot_id.is_empty() else "No pilot"
	if bool(craft_def.get("air_asset_unavailable", false)):
		var meta_state: String = String(craft_def.get("air_asset_meta_status", "")).strip_edges()
		var action: String = "Replacement" if meta_state == "destroyed_replacement_pending" else "Repair"
		return "%s\n%s\n%s ETA %ds" % [craft_name, pilot_text, action, int(craft_def.get("air_asset_recovery_eta_seconds", 0))]
	if _is_craft_in_transit(craft_id):
		return "%s\n%s\nETA %s" % [craft_name, pilot_text, _build_transfer_eta_text(_find_transfer_entry_for_craft(craft_id))]
	var cargo_text: String = _build_cargo_display_name(craft_def, _get_loaded_cargo_id(craft_id))
	if not cargo_text.is_empty():
		return "%s\n%s\n%s" % [craft_name, pilot_text, cargo_text]
	return "%s\n%s" % [craft_name, pilot_text]


func _update_character_sheet() -> void:
	var content_host := _get_character_sheet_content_host()
	if content_host == null:
		return
	var profile = _profiles_by_id.get(_focused_unit_id, null)
	CHARACTER_SHEET_VIEW_SCRIPT.render(
		content_host,
		profile,
		{
			"status_text": _build_sheet_status_text(_focused_unit_id),
			"fireteam_text": _build_homebase_fireteam_text(_focused_unit_id),
			"editable_metrics": false,
			"two_column_layout": true,
			"show_badge_progress": true,
			"hide_loadout_dropdowns": true,
		}
	)


func _get_character_sheet_content_host() -> VBoxContainer:
	var popup_host := get_node_or_null("CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/PopupScroll/GeneratedSheetContent") as VBoxContainer
	if popup_host != null:
		return popup_host
	return get_node_or_null("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/GeneratedSheetContent") as VBoxContainer


func _on_compact_card_pressed(unit_id: String, _profile, _source_context: String) -> void:
	_remember_card_profile(unit_id, _profile)
	_focused_unit_id = unit_id
	_team_feedback_text = ""
	_update_team_summary()
	if _character_sheet_open:
		_update_character_sheet()
	_render_homebase_fireteams()
	_update_homebase_loadout_panel()
	_refresh_card_highlights()


func _on_compact_card_open_requested(unit_id: String, _profile, _source_context: String) -> void:
	_remember_card_profile(unit_id, _profile)
	_focused_unit_id = unit_id
	_character_sheet_open = true
	_team_feedback_text = ""
	_update_team_summary()
	_update_character_sheet()
	_update_character_sheet_visibility()
	_refresh_card_highlights()


func _remember_card_profile(unit_id: String, profile) -> void:
	var normalized_unit_id := unit_id.strip_edges()
	if normalized_unit_id.is_empty() or profile == null or _profiles_by_id.has(normalized_unit_id):
		return
	if typeof(profile) == TYPE_OBJECT and profile.has_method("duplicate_profile"):
		_profiles_by_id[normalized_unit_id] = profile.duplicate_profile()


func _on_staged_card_remove_requested(unit_id: String, _source_context: String) -> void:
	_on_remove_button_pressed(unit_id)


func _on_team_drop_panel_unit_dropped(unit_id: String) -> void:
	if _add_unit_to_team(unit_id):
		selection_changed.emit(get_selected_unit_ids())


func _on_homebase_fireteam_card_pressed(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	_focused_fireteam_id = normalized_fireteam_id
	_loadout_staged_fireteam_id = normalized_fireteam_id
	_render_homebase_fireteams()
	_update_homebase_loadout_panel()


func _on_homebase_fireteam_label_committed(fireteam_id: String, next_label: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	var cleaned_label: String = next_label.strip_edges()
	for definition_index in range(_fireteam_definitions.size()):
		var definition: Dictionary = Dictionary(_fireteam_definitions[definition_index])
		if _normalize_fireteam_id(String(definition.get("id", ""))) != normalized_fireteam_id:
			continue
		definition["label"] = cleaned_label if not cleaned_label.is_empty() else normalized_fireteam_id.to_upper()
		_fireteam_definitions[definition_index] = definition
		break
	_emit_homebase_fireteam_context_changed()
	_render_homebase_fireteams()
	_update_homebase_loadout_panel()


func _on_homebase_fireteam_card_unit_dropped(unit_id: String, fireteam_id: String) -> void:
	_handle_homebase_fireteam_unit_dropped(unit_id, fireteam_id)


func _on_homebase_fireteam_member_card_unit_dropped(unit_id: String, _source_context: String, fireteam_id: String, anchor_unit_id: String) -> void:
	_handle_homebase_fireteam_unit_dropped(unit_id, fireteam_id, false, anchor_unit_id)


func _on_homebase_fireteam_unit_drop_target_dropped(unit_id: String, fireteam_id: String, drop_zone: String, anchor_unit_id: String) -> void:
	_handle_homebase_fireteam_unit_dropped(unit_id, fireteam_id, drop_zone.strip_edges().to_lower() == "lead", anchor_unit_id)


func _handle_homebase_fireteam_unit_dropped(unit_id: String, fireteam_id: String, make_lead: bool = false, anchor_unit_id: String = "") -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_unit_id.is_empty() or normalized_fireteam_id.is_empty():
		return
	if not _selected_unit_ids.has(normalized_unit_id):
		if not _add_unit_to_team(normalized_unit_id):
			return
	_assign_unit_to_fireteam(normalized_unit_id, normalized_fireteam_id)
	if not anchor_unit_id.strip_edges().is_empty():
		_move_selected_unit_next_to_anchor(normalized_unit_id, anchor_unit_id)
	if make_lead:
		_set_homebase_fireteam_lead(normalized_fireteam_id, normalized_unit_id)
	_reconcile_homebase_fireteam_leads()
	_focused_unit_id = normalized_unit_id
	_focused_fireteam_id = normalized_fireteam_id
	_loadout_staged_fireteam_id = normalized_fireteam_id
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_staging_fireteam_dropped(fireteam_id: String, drop_kind: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var normalized_drop_kind: String = drop_kind.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or _get_fireteam_definition(normalized_fireteam_id).is_empty():
		return
	_focused_fireteam_id = normalized_fireteam_id
	if normalized_drop_kind == "loadout":
		_loadout_staged_fireteam_id = normalized_fireteam_id
	elif normalized_drop_kind == HOMEBASE_DIRECT_STAGING_DROP_KIND:
		_add_homebase_direct_payload_fireteam_to_craft(normalized_fireteam_id, _get_selected_aircraft_id())
	elif normalized_drop_kind == "fireteam_pool":
		_remove_homebase_direct_payload_fireteam(normalized_fireteam_id)
	else:
		_remove_homebase_direct_payload_fireteam(normalized_fireteam_id)
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_shipcard_fireteam_dropped(fireteam_id: String, craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_set_selected_aircraft_id(normalized_craft_id)
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty() or _get_fireteam_definition(normalized_fireteam_id).is_empty():
		return
	_focused_fireteam_id = normalized_fireteam_id
	_add_homebase_direct_payload_fireteam_to_craft(normalized_fireteam_id, normalized_craft_id)
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_direct_unit_dropped(unit_id: String, drop_kind: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var fireteam_id: String = _get_selected_fireteam_id_for_unit(normalized_unit_id)
	if fireteam_id.is_empty():
		if not _selected_unit_ids.has(normalized_unit_id):
			if not _add_unit_to_team(normalized_unit_id):
				return
		fireteam_id = _focused_fireteam_id
		_assign_unit_to_fireteam(normalized_unit_id, fireteam_id)
	if drop_kind.strip_edges().to_lower() == "loadout":
		_loadout_staged_fireteam_id = fireteam_id
	elif drop_kind.strip_edges().to_lower() == HOMEBASE_DIRECT_STAGING_DROP_KIND:
		_add_homebase_direct_payload_fireteam_to_craft(fireteam_id, _get_selected_aircraft_id())
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_add_fireteam_pressed() -> void:
	var next_index := 1
	while not _get_fireteam_definition("ft%d" % next_index).is_empty():
		next_index += 1
	var fireteam_id := "ft%d" % next_index
	_fireteam_definitions.append(
		{
			"id": fireteam_id,
			"label": fireteam_id.to_upper(),
			"lead_unit_id": "",
			"loadout": HOMEBASE_DEFAULT_LOADOUT_ID,
			"respawn_enabled": false,
		}
	)
	_focused_fireteam_id = fireteam_id
	_loadout_staged_fireteam_id = fireteam_id
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_remove_fireteam_pressed() -> void:
	var fireteam_id: String = _normalize_fireteam_id(_focused_fireteam_id)
	if fireteam_id.is_empty() or _fireteam_definitions.size() <= 1:
		return
	var next_definitions: Array = []
	for definition_variant in _fireteam_definitions:
		var definition: Dictionary = Dictionary(definition_variant)
		if _normalize_fireteam_id(String(definition.get("id", ""))) == fireteam_id:
			continue
		next_definitions.append(definition)
	_fireteam_definitions = next_definitions
	for unit_index in range(_selected_fireteam_ids.size()):
		if String(_selected_fireteam_ids[unit_index]).strip_edges().to_lower() == fireteam_id:
			_selected_fireteam_ids[unit_index] = ""
	_remove_homebase_direct_payload_fireteam(fireteam_id)
	_focused_fireteam_id = _normalize_fireteam_id(String(Dictionary(_fireteam_definitions[0]).get("id", HOMEBASE_DEFAULT_FIRETEAM_ID))) if not _fireteam_definitions.is_empty() else HOMEBASE_DEFAULT_FIRETEAM_ID
	_loadout_staged_fireteam_id = _focused_fireteam_id
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_assign_focused_unit_pressed() -> void:
	if _focused_unit_id.is_empty():
		return
	if not _selected_unit_ids.has(_focused_unit_id):
		if not _add_unit_to_team(_focused_unit_id):
			return
	_assign_unit_to_fireteam(_focused_unit_id, _focused_fireteam_id)
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_clear_focused_unit_pressed() -> void:
	if _focused_unit_id.is_empty():
		return
	_assign_unit_to_fireteam(_focused_unit_id, "")
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _on_homebase_clear_loadout_pressed() -> void:
	_loadout_staged_fireteam_id = ""
	_update_homebase_loadout_panel()


func _on_homebase_loadout_option_selected(index: int, unit_id: String, key: String, selector: OptionButton) -> void:
	if selector == null or index < 0 or index >= selector.item_count:
		return
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_key: String = key.strip_edges()
	if normalized_unit_id.is_empty() or normalized_key.is_empty():
		return
	var next_value: String = String(selector.get_item_metadata(index)).strip_edges()
	_set_homebase_member_loadout_value(normalized_unit_id, normalized_key, next_value)
	_render_homebase_fireteams()
	_update_homebase_loadout_panel()


func _on_roster_sort_selected(index: int, selector: OptionButton) -> void:
	if selector == null or index < 0 or index >= selector.item_count:
		return
	var next_mode: String = String(selector.get_item_metadata(index)).strip_edges()
	if next_mode.is_empty() or next_mode == _roster_sort_mode:
		return
	_roster_sort_mode = next_mode
	_render_roster()


func _on_homebase_dropship_fireteam_remove_pressed(fireteam_id: String, craft_id: String = "") -> void:
	_remove_homebase_direct_payload_fireteam(fireteam_id, craft_id)
	_emit_homebase_fireteam_context_changed()
	_rebuild_ui()


func _remove_homebase_direct_payload_fireteam(fireteam_id: String, craft_id: String = "") -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	var craft_filter: String = craft_id.strip_edges()
	var next_by_craft: Dictionary = {}
	for current_craft_id_variant in _get_homebase_direct_payload_craft_keys():
		var current_craft_id: String = String(current_craft_id_variant).strip_edges()
		if not craft_filter.is_empty() and current_craft_id != craft_filter:
			next_by_craft[current_craft_id] = _get_homebase_direct_payload_fireteam_ids_for_craft_raw(current_craft_id)
			continue
		var next_fireteam_ids: PackedStringArray = _remove_fireteam_id_from_list(
			_get_homebase_direct_payload_fireteam_ids_for_craft_raw(current_craft_id),
			normalized_fireteam_id
		)
		if not next_fireteam_ids.is_empty():
			next_by_craft[current_craft_id] = next_fireteam_ids
	_homebase_dropship_staged_fireteam_ids_by_craft = next_by_craft
	_homebase_direct_boarding_state_by_fireteam_id.erase(normalized_fireteam_id)
	_sync_homebase_direct_legacy_payload_list()
	if _homebase_dropship_staged_fireteam_ids.is_empty():
		_homebase_dropship_payload_craft_id = ""
	elif not _homebase_dropship_payload_craft_id.is_empty() and _get_homebase_direct_payload_fireteam_ids_for_craft(_homebase_dropship_payload_craft_id).is_empty():
		_homebase_dropship_payload_craft_id = _find_first_homebase_direct_payload_craft_id()


func _on_roster_drop_panel_unit_dropped(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var assigned_craft_id: String = _find_assigned_craft_for_unit(normalized_unit_id)
	if not assigned_craft_id.is_empty():
		_aircraft_manager.clear_assigned_pilot(assigned_craft_id)
		_set_selected_aircraft_id(assigned_craft_id)
		_aircraft_feedback_text = "%s returned to roster from %s." % [_build_display_name(normalized_unit_id), _build_craft_display_name(assigned_craft_id)]
		_rebuild_ui()
		aircraft_pilot_cleared.emit(assigned_craft_id)
		return
	if _selected_unit_ids.has(normalized_unit_id) and _remove_unit_from_team(normalized_unit_id):
		selection_changed.emit(get_selected_unit_ids())


func _on_aircraft_pilot_drop_panel_unit_dropped(unit_id: String, craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or not _profiles_by_id.has(unit_id):
		return
	if _has_active_pilot_transfer_for_craft(normalized_craft_id):
		_aircraft_feedback_text = "This craft is already in flight to FOB."
		_update_aircraft_panel()
		return
	var previous_craft_id: String = _find_assigned_craft_for_unit(unit_id)
	if previous_craft_id == normalized_craft_id:
		_set_selected_aircraft_id(normalized_craft_id)
		_update_aircraft_panel()
		return

	_set_selected_aircraft_id(normalized_craft_id)
	_aircraft_manager.assign_pilot(normalized_craft_id, unit_id)
	_aircraft_feedback_text = "%s assigned to %s." % [_build_display_name(unit_id), _build_craft_display_name(normalized_craft_id)]
	_rebuild_ui()
	aircraft_pilot_assigned.emit(normalized_craft_id, unit_id)


func _on_remove_button_pressed(unit_id: String) -> void:
	if _remove_unit_from_team(unit_id):
		selection_changed.emit(get_selected_unit_ids())


func _on_confirm_button_pressed() -> void:
	confirm_selection()


func _on_mission_selector_item_selected(index: int) -> void:
	var mission_selector: OptionButton = get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/MissionSelector")
	if index < 0 or index >= mission_selector.item_count:
		return
	var mission_id: String = String(mission_selector.get_item_metadata(index)).strip_edges()
	if mission_id.is_empty() or mission_id == _selected_mission_id:
		return
	mission_selection_changed.emit(mission_id)


func _on_start_mission_button_pressed() -> void:
	request_mission_start()


func _on_aircraft_selector_item_selected(index: int) -> void:
	if index < 0:
		return
	_aircraft_feedback_text = ""
	_update_aircraft_panel()


func _on_cargo_selector_item_selected(index: int) -> void:
	var craft_id: String = _get_selected_aircraft_id()
	if craft_id.is_empty():
		return
	var cargo_selector: OptionButton = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/CargoSelector")
	if index < 0 or index >= cargo_selector.item_count:
		return
	var cargo_id: String = String(cargo_selector.get_item_metadata(index)).strip_edges()
	_aircraft_manager.set_selected_cargo_id(craft_id, cargo_id)
	_aircraft_feedback_text = ""
	_update_aircraft_panel()
	aircraft_cargo_selected.emit(craft_id, cargo_id)


func _on_add_aircraft_button_pressed() -> void:
	_aircraft_feedback_text = ""
	aircraft_add_requested.emit(_get_selected_aircraft_base_type())


func _on_remove_aircraft_button_pressed() -> void:
	var craft_id: String = _get_selected_aircraft_id()
	if craft_id.is_empty() or not _can_remove_selected_aircraft():
		return
	_aircraft_feedback_text = ""
	aircraft_remove_requested.emit(craft_id)


func _on_load_cargo_button_pressed() -> void:
	var craft_def: Dictionary = _get_selected_aircraft_definition()
	var craft_id: String = _get_selected_aircraft_id()
	var cargo_id: String = _get_selected_cargo_id(craft_id)
	if craft_id.is_empty() or cargo_id.is_empty() or not _can_load_selected_cargo(craft_def, craft_id):
		return
	_aircraft_feedback_text = "%s loading started for %s." % [_build_cargo_display_name(craft_def, cargo_id), _build_craft_display_name(craft_id)]
	aircraft_cargo_load_requested.emit(craft_id, cargo_id)


func _on_clear_pilot_button_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	_set_selected_aircraft_id(normalized_craft_id)
	if normalized_craft_id.is_empty() or _get_assigned_pilot_id(normalized_craft_id).is_empty():
		return
	var pilot_id: String = _aircraft_manager.clear_assigned_pilot(normalized_craft_id)
	_aircraft_feedback_text = "%s removed from %s." % [_build_display_name(pilot_id), _build_craft_display_name(normalized_craft_id)]
	_rebuild_ui()
	aircraft_pilot_cleared.emit(normalized_craft_id)


func _on_send_pilot_button_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	_set_selected_aircraft_id(normalized_craft_id)
	_set_homebase_dropship_payload_craft(normalized_craft_id)
	var pilot_id: String = _get_assigned_pilot_id(normalized_craft_id)
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	if normalized_craft_id.is_empty() or pilot_id.is_empty() or not _can_dispatch_shipcard(craft_def, normalized_craft_id, pilot_id):
		return
	if _get_homebase_dispatch_target(normalized_craft_id) == HOMEBASE_DISPATCH_TARGET_MISSION:
		_aircraft_feedback_text = "%s launched straight to Mission with %d operator(s)." % [
			_build_display_name(pilot_id),
			_build_unit_ids_for_fireteams(_get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id)).size(),
		]
		request_mission_start(normalized_craft_id)
		return
	var cargo_text: String = _build_cargo_display_name(craft_def, _get_loaded_cargo_id(normalized_craft_id))
	_aircraft_feedback_text = "%s launched toward FOB%s." % [
		_build_display_name(pilot_id),
		" with %s" % cargo_text if not cargo_text.is_empty() else "",
	]
	aircraft_pilot_transfer_requested.emit(normalized_craft_id, pilot_id)


func _on_shipcard_dispatch_target_toggled(send_to_mission: bool, craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_set_selected_aircraft_id(normalized_craft_id)
	_homebase_dispatch_target_by_craft[normalized_craft_id] = HOMEBASE_DISPATCH_TARGET_MISSION if send_to_mission else HOMEBASE_DISPATCH_TARGET_FOB
	_aircraft_feedback_text = ""
	_update_aircraft_panel()
	_update_mission_info()


func _on_shipcard_select_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_set_selected_aircraft_id(normalized_craft_id)
	_update_aircraft_panel()


func _on_shipcard_cargo_selected(index: int, craft_id: String, cargo_selector: OptionButton) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or cargo_selector == null:
		return
	if index < 0 or index >= cargo_selector.item_count:
		return
	var cargo_id: String = String(cargo_selector.get_item_metadata(index)).strip_edges()
	_set_selected_aircraft_id(normalized_craft_id)
	_aircraft_manager.set_selected_cargo_id(normalized_craft_id, cargo_id)
	_aircraft_feedback_text = ""
	_update_aircraft_panel()
	aircraft_cargo_selected.emit(normalized_craft_id, cargo_id)


func _on_shipcard_load_cargo_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	var cargo_id: String = _get_selected_cargo_id(normalized_craft_id)
	if normalized_craft_id.is_empty() or cargo_id.is_empty() or not _can_load_selected_cargo(craft_def, normalized_craft_id):
		return
	_set_selected_aircraft_id(normalized_craft_id)
	_aircraft_feedback_text = "%s loading started for %s." % [_build_cargo_display_name(craft_def, cargo_id), _build_craft_display_name(normalized_craft_id)]
	aircraft_cargo_load_requested.emit(normalized_craft_id, cargo_id)


func _on_shipcard_remove_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or not _can_remove_aircraft(normalized_craft_id):
		return
	_set_selected_aircraft_id(normalized_craft_id)
	_aircraft_feedback_text = ""
	aircraft_remove_requested.emit(normalized_craft_id)


func _on_close_sheet_button_pressed() -> void:
	_character_sheet_open = false
	_update_character_sheet_visibility()


func _add_unit_to_team(unit_id: String) -> bool:
	if unit_id.is_empty() or not _profiles_by_id.has(unit_id):
		_team_feedback_text = "This operator is not available for staging."
		_update_team_summary()
		return false

	if _selected_unit_ids.has(unit_id):
		_team_feedback_text = "%s is already staged." % _build_display_name(unit_id)
		_update_team_summary()
		return false

	if _is_unit_assigned_to_aircraft(unit_id):
		_team_feedback_text = "%s is assigned to the flight deck." % _build_display_name(unit_id)
		_update_team_summary()
		return false

	if _selected_unit_ids.size() >= _get_team_capacity():
		_team_feedback_text = "The current mission test only supports %d staged operators." % _get_team_capacity()
		_update_team_summary()
		return false

	_selected_unit_ids.append(unit_id)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	if not _focused_fireteam_id.is_empty():
		_assign_unit_to_fireteam(unit_id, _focused_fireteam_id)
	_focused_unit_id = unit_id
	_team_feedback_text = ""
	_rebuild_ui()
	return true


func _remove_unit_from_team(unit_id: String) -> bool:
	if not _selected_unit_ids.has(unit_id):
		return false

	var next_selection: PackedStringArray = []
	var next_fireteam_ids: PackedStringArray = []
	for selected_unit_id in _selected_unit_ids:
		var selected_index: int = _selected_unit_ids.find(String(selected_unit_id))
		if String(selected_unit_id) == unit_id:
			continue

		next_selection.append(String(selected_unit_id))
		next_fireteam_ids.append(String(_selected_fireteam_ids[selected_index]).strip_edges() if selected_index >= 0 and selected_index < _selected_fireteam_ids.size() else "")

	_selected_unit_ids = next_selection
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(next_fireteam_ids)
	_sanitize_homebase_direct_staging_state()
	if _focused_unit_id == unit_id:
		_focused_unit_id = ""
	_team_feedback_text = "%s removed from the transfer team." % _build_display_name(unit_id)
	_rebuild_ui()
	return true


func _refresh_card_highlights() -> void:
	for unit_id in _roster_cards_by_unit_id.keys():
		var roster_card = _roster_cards_by_unit_id.get(unit_id, null)
		if roster_card == null:
			continue

		var unit_in_transit: bool = not _find_transfer_entry_for_unit(String(unit_id)).is_empty()
		roster_card.set_visual_state(_is_roster_card_highlighted(String(unit_id)), unit_in_transit)
		roster_card.set_drag_enabled(not unit_in_transit and not _selected_unit_ids.has(String(unit_id)) and not _is_unit_assigned_to_aircraft(String(unit_id)))

	for unit_id in _staged_cards_by_unit_id.keys():
		var staged_card = _staged_cards_by_unit_id.get(unit_id, null)
		if staged_card == null:
			continue

		staged_card.set_visual_state(String(unit_id) == _focused_unit_id, false)


func _ensure_focused_unit_id() -> void:
	if not _focused_unit_id.is_empty() and _profiles_by_id.has(_focused_unit_id):
		return

	for unit_id in _selected_unit_ids:
		if _profiles_by_id.has(String(unit_id)):
			_focused_unit_id = String(unit_id)
			return

	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if _profiles_by_id.has(unit_id):
			_focused_unit_id = unit_id
			return

	_focused_unit_id = ""


func _normalize_selected_unit_ids(selected_unit_ids: PackedStringArray) -> PackedStringArray:
	var available_lookup: Dictionary = {}
	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue

		available_lookup[unit_id] = true

	var normalized_selection: PackedStringArray = []
	for selected_unit_id in selected_unit_ids:
		var unit_id: String = String(selected_unit_id).strip_edges()
		if unit_id.is_empty() or not available_lookup.has(unit_id) or normalized_selection.has(unit_id) or _is_unit_assigned_to_aircraft(unit_id):
			continue

		normalized_selection.append(unit_id)
		if normalized_selection.size() >= _get_team_capacity():
			break

	return normalized_selection


func _normalize_selected_fireteam_ids(selected_fireteam_ids: PackedStringArray) -> PackedStringArray:
	var normalized_fireteam_ids: PackedStringArray = []
	for unit_index in range(_selected_unit_ids.size()):
		var fireteam_id: String = ""
		if unit_index < selected_fireteam_ids.size():
			fireteam_id = String(selected_fireteam_ids[unit_index]).strip_edges().to_lower()
		normalized_fireteam_ids.append(fireteam_id)
	return normalized_fireteam_ids


func _normalize_fireteam_definitions(fireteam_definitions: Array) -> Array:
	var normalized_definitions: Array = []
	var seen_ids: Dictionary = {}
	for definition_variant in fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant).duplicate(true)
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty() or seen_ids.has(fireteam_id):
			continue
		seen_ids[fireteam_id] = true
		definition["id"] = fireteam_id
		definition["label"] = String(definition.get("label", fireteam_id.to_upper())).strip_edges()
		definition["lead_unit_id"] = String(definition.get("lead_unit_id", "")).strip_edges()
		definition["loadout"] = _normalize_loadout_id(String(definition.get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID)))
		definition["respawn_enabled"] = bool(definition.get("respawn_enabled", false))
		definition["member_loadouts"] = _normalize_member_loadout_dictionary(
			definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {},
			String(definition.get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID))
		)
		definition["member_unit_ids"] = PackedStringArray(Array(definition.get("member_unit_ids", [])))
		normalized_definitions.append(definition)
	return normalized_definitions


func _sanitize_homebase_direct_staging_state() -> void:
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	if _fireteam_definitions.is_empty():
		_fireteam_definitions = _build_default_homebase_fireteam_definitions()

	var known_fireteam_ids: Dictionary = {}
	for definition_variant in _fireteam_definitions:
		var definition: Dictionary = Dictionary(definition_variant)
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty():
			continue
		known_fireteam_ids[fireteam_id] = true

	for assigned_fireteam_id in _selected_fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(assigned_fireteam_id))
		if fireteam_id.is_empty() or known_fireteam_ids.has(fireteam_id):
			continue
		_fireteam_definitions.append(
			{
				"id": fireteam_id,
				"label": fireteam_id.to_upper(),
				"lead_unit_id": "",
				"loadout": HOMEBASE_DEFAULT_LOADOUT_ID,
				"respawn_enabled": false,
			}
		)
		known_fireteam_ids[fireteam_id] = true

	_reconcile_homebase_fireteam_leads()
	if _get_fireteam_definition(_focused_fireteam_id).is_empty():
		_focused_fireteam_id = _get_first_fireteam_id()
	if _get_fireteam_definition(_loadout_staged_fireteam_id).is_empty():
		_loadout_staged_fireteam_id = _focused_fireteam_id
	_migrate_homebase_direct_payload_legacy_state()
	var sanitized_by_craft: Dictionary = {}
	var seen_fireteams: Dictionary = {}
	for craft_id_variant in _get_homebase_direct_payload_craft_keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if not craft_id.is_empty() and _get_aircraft_definition_by_id(craft_id).is_empty():
			continue
		var sanitized_fireteam_ids: PackedStringArray = []
		for fireteam_id in _filter_existing_fireteam_ids(_get_homebase_direct_payload_fireteam_ids_for_craft_raw(craft_id)):
			var normalized_fireteam_id: String = _normalize_fireteam_id(String(fireteam_id))
			if normalized_fireteam_id.is_empty() or seen_fireteams.has(normalized_fireteam_id):
				continue
			seen_fireteams[normalized_fireteam_id] = craft_id
			sanitized_fireteam_ids.append(normalized_fireteam_id)
		if not sanitized_fireteam_ids.is_empty():
			sanitized_by_craft[craft_id] = sanitized_fireteam_ids
	_homebase_dropship_staged_fireteam_ids_by_craft = sanitized_by_craft
	_sync_homebase_direct_legacy_payload_list()
	_homebase_dropship_payload_craft_id = _homebase_dropship_payload_craft_id.strip_edges()
	if _homebase_dropship_staged_fireteam_ids.is_empty():
		_homebase_dropship_payload_craft_id = ""
	elif _homebase_dropship_payload_craft_id.is_empty() or _get_homebase_direct_payload_fireteam_ids_for_craft(_homebase_dropship_payload_craft_id).is_empty():
		var selected_craft_id: String = _get_selected_aircraft_id()
		if not selected_craft_id.is_empty() and not _get_homebase_direct_payload_fireteam_ids_for_craft(selected_craft_id).is_empty():
			_homebase_dropship_payload_craft_id = selected_craft_id
		else:
			_homebase_dropship_payload_craft_id = _find_first_homebase_direct_payload_craft_id()
	_sync_homebase_member_loadouts_into_fireteam_definitions()
	_sanitize_homebase_direct_boarding_states()


func _set_homebase_dropship_payload_craft(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if _homebase_dropship_payload_craft_id == normalized_craft_id:
		return
	_homebase_dropship_payload_craft_id = normalized_craft_id


func _migrate_homebase_direct_payload_legacy_state() -> void:
	if not _homebase_dropship_staged_fireteam_ids_by_craft.is_empty():
		return
	var legacy_fireteam_ids: PackedStringArray = _filter_existing_fireteam_ids(_homebase_dropship_staged_fireteam_ids)
	if legacy_fireteam_ids.is_empty():
		return
	_homebase_dropship_staged_fireteam_ids_by_craft[_homebase_dropship_payload_craft_id.strip_edges()] = legacy_fireteam_ids


func _sync_homebase_direct_legacy_payload_list() -> void:
	var aggregate_fireteam_ids: PackedStringArray = []
	for craft_id in _get_homebase_direct_payload_craft_keys():
		for fireteam_id in _get_homebase_direct_payload_fireteam_ids_for_craft_raw(String(craft_id)):
			var normalized_fireteam_id: String = _normalize_fireteam_id(String(fireteam_id))
			if normalized_fireteam_id.is_empty() or aggregate_fireteam_ids.has(normalized_fireteam_id):
				continue
			aggregate_fireteam_ids.append(normalized_fireteam_id)
	_homebase_dropship_staged_fireteam_ids = _filter_existing_fireteam_ids(aggregate_fireteam_ids)


func _find_first_homebase_direct_payload_craft_id() -> String:
	for craft_id in _get_homebase_direct_payload_craft_keys():
		var normalized_craft_id: String = String(craft_id).strip_edges()
		if normalized_craft_id.is_empty():
			continue
		if not _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id).is_empty():
			return normalized_craft_id
	return ""


func _add_homebase_direct_payload_fireteam_to_craft(fireteam_id: String, craft_id: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_fireteam_id.is_empty() or _get_fireteam_definition(normalized_fireteam_id).is_empty():
		return
	_remove_homebase_direct_payload_fireteam(normalized_fireteam_id)
	var fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft_raw(normalized_craft_id)
	if not fireteam_ids.has(normalized_fireteam_id):
		fireteam_ids.append(normalized_fireteam_id)
	_homebase_dropship_staged_fireteam_ids_by_craft[normalized_craft_id] = fireteam_ids
	_set_homebase_dropship_payload_craft(normalized_craft_id)
	_ensure_homebase_direct_boarding_state(normalized_fireteam_id, normalized_craft_id)
	_sync_homebase_direct_legacy_payload_list()


func _build_default_homebase_fireteam_definitions() -> Array:
	var lead_unit_id := ""
	if not _selected_unit_ids.is_empty():
		lead_unit_id = String(_selected_unit_ids[0]).strip_edges()
	return [
		{
			"id": HOMEBASE_DEFAULT_FIRETEAM_ID,
			"label": "ALPHA",
			"lead_unit_id": lead_unit_id,
			"loadout": HOMEBASE_DEFAULT_LOADOUT_ID,
			"respawn_enabled": false,
		}
	]


func _reconcile_homebase_fireteam_leads() -> void:
	for definition_index in range(_fireteam_definitions.size()):
		var definition: Dictionary = Dictionary(_fireteam_definitions[definition_index])
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty():
			continue
		var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
		var lead_unit_id: String = String(definition.get("lead_unit_id", "")).strip_edges()
		if lead_unit_id.is_empty() or not member_ids.has(lead_unit_id):
			definition["lead_unit_id"] = String(member_ids[0]) if not member_ids.is_empty() else ""
			_fireteam_definitions[definition_index] = definition


func _set_homebase_fireteam_lead(fireteam_id: String, unit_id: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_fireteam_id.is_empty() or normalized_unit_id.is_empty():
		return
	for definition_index in range(_fireteam_definitions.size()):
		var definition: Dictionary = Dictionary(_fireteam_definitions[definition_index])
		if _normalize_fireteam_id(String(definition.get("id", ""))) != normalized_fireteam_id:
			continue
		definition["lead_unit_id"] = normalized_unit_id
		_fireteam_definitions[definition_index] = definition
		return


func _normalize_fireteam_id(fireteam_id: String) -> String:
	return fireteam_id.strip_edges().to_lower()


func _get_first_fireteam_id() -> String:
	for definition_variant in _fireteam_definitions:
		var fireteam_id: String = _normalize_fireteam_id(String(Dictionary(definition_variant).get("id", "")))
		if not fireteam_id.is_empty():
			return fireteam_id
	return HOMEBASE_DEFAULT_FIRETEAM_ID


func _get_fireteam_definition(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return {}
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		if _normalize_fireteam_id(String(definition.get("id", ""))) == normalized_fireteam_id:
			return definition
	return {}


func _get_fireteam_label(fireteam_id: String) -> String:
	var definition: Dictionary = _get_fireteam_definition(fireteam_id)
	var label_text: String = String(definition.get("label", fireteam_id.to_upper())).strip_edges()
	return label_text if not label_text.is_empty() else fireteam_id.to_upper()


func _get_member_unit_ids_for_fireteam(fireteam_id: String) -> PackedStringArray:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var member_ids: PackedStringArray = []
	if normalized_fireteam_id.is_empty():
		return member_ids
	for unit_index in range(_selected_unit_ids.size()):
		if unit_index >= _selected_fireteam_ids.size():
			continue
		if _normalize_fireteam_id(String(_selected_fireteam_ids[unit_index])) == normalized_fireteam_id:
			member_ids.append(String(_selected_unit_ids[unit_index]))
	return member_ids


func _build_fireteam_member_names(fireteam_id: String) -> PackedStringArray:
	var names: PackedStringArray = []
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		names.append(_build_display_name(String(member_unit_id)))
	return names


func _format_member_names(member_names: PackedStringArray) -> String:
	if member_names.is_empty():
		return "none"
	if member_names.size() <= 3:
		return ", ".join(member_names)
	var first_names: PackedStringArray = []
	for name_index in range(3):
		first_names.append(String(member_names[name_index]))
	return "%s +%d" % [", ".join(first_names), member_names.size() - 3]


func _assign_unit_to_fireteam(unit_id: String, fireteam_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var unit_index: int = _selected_unit_ids.find(normalized_unit_id)
	if unit_index < 0:
		return
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	if unit_index < _selected_fireteam_ids.size():
		_selected_fireteam_ids[unit_index] = normalized_fireteam_id
	_sanitize_homebase_direct_staging_state()


func _move_selected_unit_next_to_anchor(unit_id: String, anchor_unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_anchor_unit_id: String = anchor_unit_id.strip_edges()
	if normalized_unit_id.is_empty() or normalized_anchor_unit_id.is_empty() or normalized_unit_id == normalized_anchor_unit_id:
		return
	var pairs: Array = []
	for unit_index in range(_selected_unit_ids.size()):
		var current_fireteam_id := ""
		if unit_index < _selected_fireteam_ids.size():
			current_fireteam_id = String(_selected_fireteam_ids[unit_index]).strip_edges()
		pairs.append({
			"unit_id": String(_selected_unit_ids[unit_index]).strip_edges(),
			"fireteam_id": current_fireteam_id,
		})
	var moving_index := -1
	var anchor_index := -1
	for pair_index in range(pairs.size()):
		var pair: Dictionary = Dictionary(pairs[pair_index])
		if String(pair.get("unit_id", "")) == normalized_unit_id:
			moving_index = pair_index
		if String(pair.get("unit_id", "")) == normalized_anchor_unit_id:
			anchor_index = pair_index
	if moving_index < 0 or anchor_index < 0 or moving_index == anchor_index:
		return
	var moving_pair: Dictionary = Dictionary(pairs[moving_index])
	pairs.remove_at(moving_index)
	if moving_index < anchor_index:
		anchor_index -= 1
	var insert_index: int = anchor_index + 1
	if insert_index < 0:
		insert_index = 0
	if insert_index > pairs.size():
		insert_index = pairs.size()
	pairs.insert(insert_index, moving_pair)
	var next_unit_ids: PackedStringArray = []
	var next_fireteam_ids: PackedStringArray = []
	for pair_variant in pairs:
		var pair: Dictionary = Dictionary(pair_variant)
		next_unit_ids.append(String(pair.get("unit_id", "")).strip_edges())
		next_fireteam_ids.append(_normalize_fireteam_id(String(pair.get("fireteam_id", ""))))
	_selected_unit_ids = next_unit_ids
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(next_fireteam_ids)
	_sanitize_homebase_direct_staging_state()


func _emit_homebase_fireteam_context_changed() -> void:
	fireteam_context_changed.emit(get_selected_unit_ids(), get_selected_fireteam_ids())


func _remove_fireteam_id_from_list(source: PackedStringArray, fireteam_id: String) -> PackedStringArray:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var result: PackedStringArray = []
	for source_fireteam_id in source:
		var current_fireteam_id: String = _normalize_fireteam_id(String(source_fireteam_id))
		if current_fireteam_id.is_empty() or current_fireteam_id == normalized_fireteam_id or result.has(current_fireteam_id):
			continue
		result.append(current_fireteam_id)
	return result


func _filter_existing_fireteam_ids(source: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	for fireteam_id_variant in source:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or result.has(fireteam_id) or _get_fireteam_definition(fireteam_id).is_empty():
			continue
		if _get_member_unit_ids_for_fireteam(fireteam_id).is_empty():
			continue
		result.append(fireteam_id)
	return result


func _normalize_loadout_id(value: String) -> String:
	return String(LOADOUT_CONTRACT_SCRIPT.call("normalize_armor_id", value, HOMEBASE_DEFAULT_LOADOUT_ID))


func _normalize_weapon_id(value: String, fallback: String = HOMEBASE_DEFAULT_PRIMARY_WEAPON) -> String:
	return String(LOADOUT_CONTRACT_SCRIPT.call("normalize_weapon_id", value, fallback))


func _make_member_loadout(armor_id: String, weapon_1_id: String, weapon_2_id: String) -> Dictionary:
	return Dictionary(LOADOUT_CONTRACT_SCRIPT.call(
		"make_member_loadout",
		armor_id,
		weapon_1_id,
		weapon_2_id,
		HOMEBASE_DEFAULT_LOADOUT_ID,
		HOMEBASE_DEFAULT_PRIMARY_WEAPON,
		HOMEBASE_DEFAULT_SECONDARY_WEAPON
	))


func _normalize_member_loadout(
	loadout_variant: Variant,
	default_armor_id: String = HOMEBASE_DEFAULT_LOADOUT_ID,
	default_weapon_1_id: String = HOMEBASE_DEFAULT_PRIMARY_WEAPON,
	default_weapon_2_id: String = HOMEBASE_DEFAULT_SECONDARY_WEAPON
) -> Dictionary:
	return Dictionary(LOADOUT_CONTRACT_SCRIPT.call(
		"normalize_member_loadout",
		loadout_variant,
		default_armor_id,
		default_weapon_1_id,
		default_weapon_2_id
	))


func _normalize_member_loadout_dictionary(member_loadouts: Dictionary, default_armor_id: String = HOMEBASE_DEFAULT_LOADOUT_ID) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in member_loadouts.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		result[unit_id] = _normalize_member_loadout(member_loadouts.get(unit_id_variant, {}), default_armor_id)
	return result


func _sync_homebase_member_loadouts_into_fireteam_definitions() -> void:
	var existing_cache: Dictionary = _normalize_member_loadout_dictionary(_member_loadout_by_unit_id)
	var next_cache: Dictionary = {}
	for definition_index in range(_fireteam_definitions.size()):
		if typeof(_fireteam_definitions[definition_index]) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(_fireteam_definitions[definition_index]).duplicate(true)
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty():
			continue
		var default_armor_id: String = _normalize_loadout_id(String(definition.get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID)))
		var existing_member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
		var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
		var sanitized_member_loadouts: Dictionary = {}
		for member_unit_id in member_ids:
			var unit_id: String = String(member_unit_id).strip_edges()
			var profile_default_loadout: Dictionary = _get_profile_default_member_loadout(unit_id, default_armor_id)
			var source_loadout: Dictionary = {}
			if existing_member_loadouts.has(unit_id) and typeof(existing_member_loadouts.get(unit_id)) == TYPE_DICTIONARY:
				source_loadout = Dictionary(existing_member_loadouts.get(unit_id, {}))
			elif existing_cache.has(unit_id):
				source_loadout = Dictionary(existing_cache.get(unit_id, {}))
			else:
				source_loadout = profile_default_loadout
			var normalized_loadout: Dictionary = _normalize_member_loadout(
				source_loadout,
				String(profile_default_loadout.get("armor", default_armor_id)),
				String(profile_default_loadout.get("weapon_1", HOMEBASE_DEFAULT_PRIMARY_WEAPON)),
				String(profile_default_loadout.get("weapon_2", HOMEBASE_DEFAULT_SECONDARY_WEAPON))
			)
			sanitized_member_loadouts[unit_id] = normalized_loadout
			next_cache[unit_id] = normalized_loadout
		definition["loadout"] = default_armor_id
		definition["member_unit_ids"] = member_ids.duplicate()
		definition["member_loadouts"] = sanitized_member_loadouts
		_fireteam_definitions[definition_index] = definition
	_member_loadout_by_unit_id = next_cache


func _get_fireteam_id_for_unit(unit_id: String) -> String:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return ""
	for unit_index in range(_selected_unit_ids.size()):
		if String(_selected_unit_ids[unit_index]).strip_edges() != normalized_unit_id:
			continue
		if unit_index < _selected_fireteam_ids.size():
			return _normalize_fireteam_id(String(_selected_fireteam_ids[unit_index]))
	return ""


func _set_homebase_member_loadout(fireteam_id: String, unit_id: String, armor_id: String, weapon_1_id: String, weapon_2_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_unit_id.is_empty():
		return
	if normalized_fireteam_id.is_empty():
		normalized_fireteam_id = _get_fireteam_id_for_unit(normalized_unit_id)
	if normalized_fireteam_id.is_empty():
		return
	var member_loadout: Dictionary = _make_member_loadout(armor_id, weapon_1_id, weapon_2_id)
	_member_loadout_by_unit_id[normalized_unit_id] = member_loadout
	_write_member_loadout_to_fireteam_definition(normalized_fireteam_id, normalized_unit_id, member_loadout)
	_sync_homebase_member_loadouts_into_fireteam_definitions()


func _set_homebase_member_loadout_value(unit_id: String, key: String, value: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var member_loadout: Dictionary = _get_member_loadout(normalized_unit_id)
	match key.strip_edges().to_lower():
		"armor", "kit":
			member_loadout["armor"] = _normalize_loadout_id(value)
		"weapon_1", "primary":
			member_loadout["weapon_1"] = _normalize_weapon_id(value, HOMEBASE_DEFAULT_PRIMARY_WEAPON)
		"weapon_2", "sidearm", "secondary":
			member_loadout["weapon_2"] = _normalize_weapon_id(value, HOMEBASE_DEFAULT_SECONDARY_WEAPON)
		_:
			return
	var fireteam_id: String = _get_fireteam_id_for_unit(normalized_unit_id)
	_member_loadout_by_unit_id[normalized_unit_id] = member_loadout
	_write_member_loadout_to_fireteam_definition(fireteam_id, normalized_unit_id, member_loadout)
	_sync_homebase_member_loadouts_into_fireteam_definitions()


func _write_member_loadout_to_fireteam_definition(fireteam_id: String, unit_id: String, member_loadout: Dictionary) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_fireteam_id.is_empty() or normalized_unit_id.is_empty():
		return
	for definition_index in range(_fireteam_definitions.size()):
		if typeof(_fireteam_definitions[definition_index]) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(_fireteam_definitions[definition_index]).duplicate(true)
		if _normalize_fireteam_id(String(definition.get("id", ""))) != normalized_fireteam_id:
			continue
		var member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
		var default_loadout: Dictionary = _get_profile_default_member_loadout(normalized_unit_id, String(definition.get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID)))
		member_loadouts[normalized_unit_id] = _normalize_member_loadout(
			member_loadout,
			String(default_loadout.get("armor", HOMEBASE_DEFAULT_LOADOUT_ID)),
			String(default_loadout.get("weapon_1", HOMEBASE_DEFAULT_PRIMARY_WEAPON)),
			String(default_loadout.get("weapon_2", HOMEBASE_DEFAULT_SECONDARY_WEAPON))
		)
		definition["member_loadouts"] = member_loadouts
		_fireteam_definitions[definition_index] = definition
		return


func _get_homebase_direct_staging_craft_gate() -> Dictionary:
	var payload_craft_id: String = _get_homebase_direct_payload_craft_id()
	if payload_craft_id.is_empty():
		return _aircraft_manager.build_homebase_direct_staging_craft_gate()
	return _build_homebase_direct_staging_craft_gate_for_craft(payload_craft_id)


func _build_homebase_direct_staging_craft_gate_for_craft(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	var block_reason: String = _get_homebase_direct_staging_craft_block_reason(craft_def, normalized_craft_id)
	return {
		"craft": craft_def,
		"can_stage": block_reason.is_empty(),
		"block_reason": block_reason,
		"block_text": _build_homebase_direct_staging_block_text(block_reason, craft_def, normalized_craft_id),
		"payload_craft_id": normalized_craft_id,
		"manager_contract": "aircraft_manager_state_validation",
	}


func _get_homebase_direct_staging_craft_block_reason(craft_def: Dictionary, craft_id: String) -> String:
	return _aircraft_manager.get_homebase_direct_staging_craft_block_reason(craft_def, craft_id)


func _build_homebase_direct_staging_block_text(block_reason: String, craft_def: Dictionary, craft_id: String) -> String:
	return _aircraft_manager.build_homebase_direct_staging_block_text(block_reason, craft_def, craft_id)


func _has_homebase_direct_launch_payload() -> bool:
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids()
	return bool(_get_homebase_direct_staging_craft_gate().get("can_stage", false)) \
		and _are_homebase_payload_fireteams_boarded(payload_fireteam_ids) \
		and not _build_unit_ids_for_fireteams(payload_fireteam_ids).is_empty()


func _has_homebase_direct_launch_payload_for_craft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return false
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id)
	return bool(_build_homebase_direct_staging_craft_gate_for_craft(normalized_craft_id).get("can_stage", false)) \
		and _are_homebase_payload_fireteams_boarded(payload_fireteam_ids) \
		and not _build_unit_ids_for_fireteams(payload_fireteam_ids).is_empty()


func _build_unit_ids_for_fireteams(fireteam_ids: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	for fireteam_id in fireteam_ids:
		for unit_id in _get_member_unit_ids_for_fireteam(String(fireteam_id)):
			var normalized_unit_id: String = String(unit_id).strip_edges()
			if normalized_unit_id.is_empty() or result.has(normalized_unit_id):
				continue
			result.append(normalized_unit_id)
	return result


func _get_fireteam_definitions_snapshot() -> Array:
	_sync_homebase_member_loadouts_into_fireteam_definitions()
	var snapshot: Array = []
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) == TYPE_DICTIONARY:
			snapshot.append(Dictionary(definition_variant).duplicate(true))
	return snapshot


func _filter_fireteam_definitions_for_ids(fireteam_definitions: Array, fireteam_ids: PackedStringArray) -> Array:
	var fireteam_lookup: Dictionary = {}
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if not fireteam_id.is_empty():
			fireteam_lookup[fireteam_id] = true

	var result: Array = []
	for definition_variant in fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant).duplicate(true)
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty() or not fireteam_lookup.has(fireteam_id):
			continue
		result.append(definition)
	return result


func _build_homebase_member_loadouts(fireteam_ids: PackedStringArray) -> Dictionary:
	_sync_homebase_member_loadouts_into_fireteam_definitions()
	var result: Dictionary = {}
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		var definition: Dictionary = _get_fireteam_definition(fireteam_id)
		if definition.is_empty():
			continue
		var lead_unit_id: String = String(definition.get("lead_unit_id", "")).strip_edges()
		for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
			var unit_id: String = String(member_unit_id).strip_edges()
			if unit_id.is_empty():
				continue
			var entry: Dictionary = _get_member_loadout(unit_id)
			if not lead_unit_id.is_empty() and unit_id == lead_unit_id:
				entry["is_fireteam_lead"] = true
			result[unit_id] = entry
	return result


func _build_fireteam_ids_for_units(unit_ids: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = []
	for unit_id_variant in unit_ids:
		result.append(_get_fireteam_id_for_unit(String(unit_id_variant)))
	return result


func _build_homebase_selected_unit_configs() -> Array:
	return _build_homebase_unit_configs_for_unit_ids(_selected_unit_ids)


func _build_homebase_unit_configs_for_unit_ids(unit_ids: PackedStringArray) -> Array:
	var selected_lookup: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if not unit_id.is_empty():
			selected_lookup[unit_id] = true
	var configs: Array = []
	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_data_variant).duplicate(true)
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or not selected_lookup.has(unit_id):
			continue
		unit_data["fireteam_id"] = _get_fireteam_id_for_unit(unit_id)
		configs.append(unit_data)
		selected_lookup.erase(unit_id)
	for missing_unit_id in selected_lookup.keys():
		configs.append(
			{
				"unit_id": String(missing_unit_id),
				"display_name": String(missing_unit_id),
				"team_id": "",
				"fireteam_id": _get_fireteam_id_for_unit(String(missing_unit_id)),
				"skill_accuracy": 0.5,
				"skill_speed": 0.5,
				"skill_leadership": 0.3,
				"skill_toughness": 0.5,
				"trait_ids": [],
			}
		)
	return configs


func _get_member_loadout(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return _make_member_loadout(HOMEBASE_DEFAULT_LOADOUT_ID, HOMEBASE_DEFAULT_PRIMARY_WEAPON, HOMEBASE_DEFAULT_SECONDARY_WEAPON)
	var fireteam_id: String = _get_fireteam_id_for_unit(normalized_unit_id)
	var definition: Dictionary = _get_fireteam_definition(fireteam_id)
	var default_armor_id: String = String(definition.get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID))
	var profile_default_loadout: Dictionary = _get_profile_default_member_loadout(normalized_unit_id, default_armor_id)
	var member_loadouts: Dictionary = definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {}
	if member_loadouts.has(normalized_unit_id):
		return _normalize_member_loadout(
			member_loadouts.get(normalized_unit_id, {}),
			String(profile_default_loadout.get("armor", default_armor_id)),
			String(profile_default_loadout.get("weapon_1", HOMEBASE_DEFAULT_PRIMARY_WEAPON)),
			String(profile_default_loadout.get("weapon_2", HOMEBASE_DEFAULT_SECONDARY_WEAPON))
		)
	if _member_loadout_by_unit_id.has(normalized_unit_id):
		return _normalize_member_loadout(
			_member_loadout_by_unit_id.get(normalized_unit_id, {}),
			String(profile_default_loadout.get("armor", default_armor_id)),
			String(profile_default_loadout.get("weapon_1", HOMEBASE_DEFAULT_PRIMARY_WEAPON)),
			String(profile_default_loadout.get("weapon_2", HOMEBASE_DEFAULT_SECONDARY_WEAPON))
		)
	return profile_default_loadout


func _get_profile_default_member_loadout(unit_id: String, default_armor_id: String = HOMEBASE_DEFAULT_LOADOUT_ID) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return _make_member_loadout(default_armor_id, HOMEBASE_DEFAULT_PRIMARY_WEAPON, HOMEBASE_DEFAULT_SECONDARY_WEAPON)

	var unit_data: Dictionary = _get_available_unit_data(normalized_unit_id)
	if not unit_data.is_empty():
		var armor_id: String = String(unit_data.get("armor", unit_data.get("armor_id", default_armor_id)))
		var weapon_1_id: String = HOMEBASE_DEFAULT_PRIMARY_WEAPON
		if unit_data.has("weapon_1") or unit_data.has("weapon_1_id"):
			weapon_1_id = String(unit_data.get("weapon_1_id", unit_data.get("weapon_1", weapon_1_id)))
		var weapon_2_id: String = HOMEBASE_DEFAULT_SECONDARY_WEAPON
		if unit_data.has("weapon_2") or unit_data.has("weapon_2_id"):
			weapon_2_id = String(unit_data.get("weapon_2_id", unit_data.get("weapon_2", weapon_2_id)))
		return _make_member_loadout(armor_id, weapon_1_id, weapon_2_id)

	var profile = _profiles_by_id.get(normalized_unit_id, null)
	if profile != null:
		return _make_member_loadout(
			String(profile.armor_id),
			String(profile.weapon_1_id),
			String(profile.weapon_2_id)
		)
	return _make_member_loadout(default_armor_id, HOMEBASE_DEFAULT_PRIMARY_WEAPON, HOMEBASE_DEFAULT_SECONDARY_WEAPON)


func _get_available_unit_data(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue
		var unit_data: Dictionary = Dictionary(unit_data_variant)
		if String(unit_data.get("unit_id", "")).strip_edges() == normalized_unit_id:
			return unit_data.duplicate(true)
	return {}


func _get_profile_portrait_path(unit_id: String) -> String:
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return ""
	return String(profile.portrait_path)


func _build_homebase_fireteam_summary_text() -> String:
	var assigned_count := 0
	for fireteam_id in _selected_fireteam_ids:
		if not _normalize_fireteam_id(String(fireteam_id)).is_empty():
			assigned_count += 1
	return "%d staged | %d assigned | Drop operators onto cards, then drop fireteams to Loadout or Flightdeck." % [_selected_unit_ids.size(), assigned_count]


func _get_homebase_direct_payload_fireteam_ids() -> PackedStringArray:
	var active_craft_id: String = _get_homebase_direct_payload_craft_id()
	if not active_craft_id.is_empty():
		return _get_homebase_direct_payload_fireteam_ids_for_craft(active_craft_id)
	return _get_homebase_direct_payload_fireteam_ids_for_craft("")


func _get_homebase_direct_payload_fireteam_ids_for_craft(craft_id: String) -> PackedStringArray:
	return _filter_existing_fireteam_ids(_get_homebase_direct_payload_fireteam_ids_for_craft_raw(craft_id))


func _get_homebase_direct_payload_fireteam_ids_for_craft_raw(craft_id: String) -> PackedStringArray:
	var normalized_craft_id: String = craft_id.strip_edges()
	var value = _homebase_dropship_staged_fireteam_ids_by_craft.get(normalized_craft_id, PackedStringArray())
	if value is PackedStringArray:
		return (value as PackedStringArray).duplicate()
	if value is Array:
		return PackedStringArray(value)
	return PackedStringArray()


func _get_homebase_direct_all_payload_fireteam_ids() -> PackedStringArray:
	var result: PackedStringArray = []
	for craft_id in _get_homebase_direct_payload_craft_keys():
		for fireteam_id in _get_homebase_direct_payload_fireteam_ids_for_craft(String(craft_id)):
			var normalized_fireteam_id: String = _normalize_fireteam_id(String(fireteam_id))
			if normalized_fireteam_id.is_empty() or result.has(normalized_fireteam_id):
				continue
			result.append(normalized_fireteam_id)
	return result


func _get_homebase_direct_ready_payload_fireteam_ids() -> PackedStringArray:
	var result: PackedStringArray = []
	for craft_id in _get_homebase_direct_payload_craft_keys():
		var normalized_craft_id: String = String(craft_id).strip_edges()
		if normalized_craft_id.is_empty():
			continue
		var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id)
		if payload_fireteam_ids.is_empty():
			continue
		var craft_gate: Dictionary = _build_homebase_direct_staging_craft_gate_for_craft(normalized_craft_id)
		if not bool(craft_gate.get("can_stage", false)) or not _are_homebase_payload_fireteams_boarded(payload_fireteam_ids):
			continue
		for fireteam_id in payload_fireteam_ids:
			var normalized_fireteam_id: String = _normalize_fireteam_id(String(fireteam_id))
			if normalized_fireteam_id.is_empty() or result.has(normalized_fireteam_id):
				continue
			result.append(normalized_fireteam_id)
	return result


func _build_homebase_direct_payload_by_craft_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for craft_id in _get_homebase_direct_payload_craft_keys():
		var normalized_craft_id: String = String(craft_id).strip_edges()
		var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id)
		if payload_fireteam_ids.is_empty():
			continue
		snapshot[normalized_craft_id] = Array(payload_fireteam_ids)
	return snapshot


func _get_homebase_direct_payload_craft_keys() -> Array:
	var keys: Array = []
	for key_variant in _homebase_dropship_staged_fireteam_ids_by_craft.keys():
		keys.append(String(key_variant).strip_edges())
	keys.sort()
	return keys


func _find_homebase_direct_payload_craft_for_fireteam(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return ""
	for craft_id in _get_homebase_direct_payload_craft_keys():
		if _get_homebase_direct_payload_fireteam_ids_for_craft(String(craft_id)).has(normalized_fireteam_id):
			return String(craft_id)
	return ""


func _get_homebase_direct_payload_craft_id() -> String:
	var stored_craft_id: String = _homebase_dropship_payload_craft_id.strip_edges()
	if not stored_craft_id.is_empty() and not _get_homebase_direct_payload_fireteam_ids_for_craft(stored_craft_id).is_empty():
		return stored_craft_id
	var selected_craft_id: String = _get_selected_aircraft_id()
	if not selected_craft_id.is_empty() and not _get_homebase_direct_payload_fireteam_ids_for_craft(selected_craft_id).is_empty():
		return selected_craft_id
	for craft_id in _get_homebase_direct_payload_craft_keys():
		var normalized_craft_id: String = String(craft_id).strip_edges()
		if normalized_craft_id.is_empty():
			continue
		if not _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id).is_empty():
			return normalized_craft_id
	return stored_craft_id


func _get_homebase_direct_payload_operator_count() -> int:
	return _build_unit_ids_for_fireteams(_get_homebase_direct_payload_fireteam_ids()).size()


func _get_homebase_direct_payload_operator_count_for_craft(craft_id: String) -> int:
	return _build_unit_ids_for_fireteams(_get_homebase_direct_payload_fireteam_ids_for_craft(craft_id)).size()


func _get_homebase_direct_boarded_operator_count() -> int:
	return _get_homebase_direct_boarded_operator_count_for_fireteams(_get_homebase_direct_payload_fireteam_ids())


func _get_homebase_direct_boarded_operator_count_for_craft(craft_id: String) -> int:
	return _get_homebase_direct_boarded_operator_count_for_fireteams(_get_homebase_direct_payload_fireteam_ids_for_craft(craft_id))


func _get_homebase_direct_boarded_operator_count_for_fireteams(fireteam_ids: PackedStringArray) -> int:
	var boarded_count := 0
	for fireteam_id in fireteam_ids:
		boarded_count += _get_homebase_boarded_member_count(String(fireteam_id))
	return boarded_count


func _get_homebase_direct_boarding_progress_ratio() -> float:
	var total_count: int = _get_homebase_direct_payload_operator_count()
	if total_count <= 0:
		return 0.0
	return clampf(float(_get_homebase_direct_boarded_operator_count()) / float(total_count), 0.0, 1.0)


func _get_homebase_direct_boarding_progress_ratio_for_craft(craft_id: String) -> float:
	var total_count: int = _get_homebase_direct_payload_operator_count_for_craft(craft_id)
	if total_count <= 0:
		return 0.0
	return clampf(float(_get_homebase_direct_boarded_operator_count_for_craft(craft_id)) / float(total_count), 0.0, 1.0)


func _is_homebase_fireteam_in_flightdeck_payload(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	return not normalized_fireteam_id.is_empty() and _get_homebase_direct_all_payload_fireteam_ids().has(normalized_fireteam_id)


func _refresh_homebase_direct_boarding_ui() -> void:
	if not is_inside_tree():
		return
	if _is_homebase_gui_drag_active():
		_homebase_direct_boarding_refresh_deferred_for_drag = true
		_homebase_direct_boarding_force_refresh = true
		return
	_homebase_direct_boarding_refresh_deferred_for_drag = false
	_homebase_direct_boarding_force_refresh = false
	_update_mission_info()
	_update_aircraft_panel()
	_update_homebase_flightdeck_staging_panel()


func _is_homebase_gui_drag_active() -> bool:
	if bool(get_meta("debug_gui_drag_in_progress", false)):
		return true
	var viewport := get_viewport()
	return viewport != null and viewport.gui_is_dragging()


func _debug_advance_homebase_direct_boarding(delta_seconds: float) -> void:
	if _advance_homebase_direct_boarding(delta_seconds):
		_refresh_homebase_direct_boarding_ui()


func _advance_homebase_direct_boarding(delta_seconds: float) -> bool:
	var delta: float = maxf(delta_seconds, 0.0)
	if delta <= 0.0:
		return false
	_sanitize_homebase_direct_boarding_states()
	if _get_homebase_direct_all_payload_fireteam_ids().is_empty():
		return false
	var changed := false
	for fireteam_id in _get_homebase_direct_all_payload_fireteam_ids():
		var normalized_fireteam_id: String = _normalize_fireteam_id(String(fireteam_id))
		var craft_id: String = _find_homebase_direct_payload_craft_for_fireteam(normalized_fireteam_id)
		var craft_gate: Dictionary = _build_homebase_direct_staging_craft_gate_for_craft(craft_id) if not craft_id.is_empty() else _get_homebase_direct_staging_craft_gate()
		if not bool(craft_gate.get("can_stage", false)):
			continue
		var total_seconds: float = _get_homebase_fireteam_boarding_total_seconds(normalized_fireteam_id)
		if normalized_fireteam_id.is_empty() or total_seconds <= 0.0:
			continue
		var state: Dictionary = _ensure_homebase_direct_boarding_state(normalized_fireteam_id, craft_id)
		var elapsed_seconds: float = clampf(float(state.get("elapsed_seconds", 0.0)), 0.0, total_seconds)
		if elapsed_seconds >= total_seconds:
			continue
		var next_elapsed_seconds: float = minf(elapsed_seconds + delta, total_seconds)
		if next_elapsed_seconds + 0.001 >= total_seconds:
			_homebase_direct_boarding_force_refresh = true
		state["elapsed_seconds"] = next_elapsed_seconds
		state["craft_id"] = craft_id
		_homebase_direct_boarding_state_by_fireteam_id[normalized_fireteam_id] = state
		changed = true
	return changed


func _ensure_homebase_direct_boarding_state(fireteam_id: String, craft_id: String = "") -> Dictionary:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return {}
	var normalized_craft_id: String = craft_id.strip_edges()
	var existing: Dictionary = Dictionary(_homebase_direct_boarding_state_by_fireteam_id.get(normalized_fireteam_id, {}))
	if existing.is_empty() or String(existing.get("craft_id", "")).strip_edges() != normalized_craft_id:
		existing = {
			"fireteam_id": normalized_fireteam_id,
			"craft_id": normalized_craft_id,
			"elapsed_seconds": 0.0,
		}
		_homebase_direct_boarding_state_by_fireteam_id[normalized_fireteam_id] = existing
	return existing


func _sanitize_homebase_direct_boarding_states() -> void:
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_all_payload_fireteam_ids()
	var payload_lookup: Dictionary = {}
	for fireteam_id in payload_fireteam_ids:
		payload_lookup[_normalize_fireteam_id(String(fireteam_id))] = true
	for key_variant in _homebase_direct_boarding_state_by_fireteam_id.keys():
		var fireteam_id: String = _normalize_fireteam_id(String(key_variant))
		if not payload_lookup.has(fireteam_id):
			_homebase_direct_boarding_state_by_fireteam_id.erase(key_variant)
			continue
		var state: Dictionary = Dictionary(_homebase_direct_boarding_state_by_fireteam_id.get(key_variant, {}))
		var owning_craft_id: String = _find_homebase_direct_payload_craft_for_fireteam(fireteam_id)
		if String(state.get("craft_id", "")).strip_edges() != owning_craft_id:
			_homebase_direct_boarding_state_by_fireteam_id.erase(key_variant)
	for fireteam_id in payload_fireteam_ids:
		_ensure_homebase_direct_boarding_state(String(fireteam_id), _find_homebase_direct_payload_craft_for_fireteam(String(fireteam_id)))


func _get_homebase_boarding_elapsed_seconds(fireteam_id: String) -> float:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var craft_id: String = _find_homebase_direct_payload_craft_for_fireteam(normalized_fireteam_id)
	var state: Dictionary = _ensure_homebase_direct_boarding_state(normalized_fireteam_id, craft_id)
	return maxf(float(state.get("elapsed_seconds", 0.0)), 0.0)


func _debug_get_homebase_member_boarding_seconds(unit_id: String) -> float:
	return _get_homebase_member_boarding_seconds(unit_id)


func _debug_get_homebase_fireteam_boarding_total_seconds(fireteam_id: String) -> float:
	return _get_homebase_fireteam_boarding_total_seconds(fireteam_id)


func _get_homebase_fireteam_boarding_total_seconds(fireteam_id: String) -> float:
	var total_seconds: float = 0.0
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		total_seconds += _get_homebase_member_boarding_seconds(String(member_unit_id))
	return total_seconds


func _get_homebase_member_boarding_start_seconds(fireteam_id: String, unit_id: String) -> float:
	var normalized_unit_id: String = unit_id.strip_edges()
	var accumulated_seconds: float = 0.0
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		var current_unit_id: String = String(member_unit_id).strip_edges()
		if current_unit_id == normalized_unit_id:
			return accumulated_seconds
		accumulated_seconds += _get_homebase_member_boarding_seconds(current_unit_id)
	return 0.0


func _get_homebase_member_boarding_seconds(unit_id: String) -> float:
	var speed: float = _get_homebase_unit_boarding_value(unit_id, "speed", "skill_speed", 0.5)
	var discipline: float = _get_homebase_unit_boarding_value(unit_id, "discipline", "discipline", 0.5)
	var boarding_quality: float = clampf((speed * 0.55) + (discipline * 0.45), 0.0, 1.0)
	var skill_multiplier: float = lerpf(1.35, 0.65, boarding_quality)
	return clampf(
		HOMEBASE_DIRECT_AVERAGE_BOARDING_SECONDS_PER_OPERATOR * skill_multiplier,
		HOMEBASE_DIRECT_MIN_BOARDING_SECONDS_PER_OPERATOR,
		HOMEBASE_DIRECT_MAX_BOARDING_SECONDS_PER_OPERATOR
	)


func _get_homebase_unit_boarding_value(unit_id: String, skill_key: String, unit_data_key: String, fallback: float) -> float:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_skill_key: String = skill_key.strip_edges().to_lower()
	var profile = _profiles_by_id.get(normalized_unit_id, null)
	if profile != null:
		var skill_values: Dictionary = {}
		if profile.skill_values != null:
			skill_values = Dictionary(profile.skill_values)
		if skill_values.has(normalized_skill_key):
			return clampf(float(skill_values.get(normalized_skill_key, fallback)), 0.0, 1.0)
		if normalized_skill_key == "discipline":
			var behavior_axes: Dictionary = {}
			if profile.behavior_axes != null:
				behavior_axes = Dictionary(profile.behavior_axes)
			if behavior_axes.has("order_fidelity"):
				return clampf(float(behavior_axes.get("order_fidelity", fallback)), 0.0, 1.0)

	var unit_data: Dictionary = _get_available_unit_data(normalized_unit_id)
	if unit_data.has(normalized_skill_key):
		return clampf(float(unit_data.get(normalized_skill_key, fallback)), 0.0, 1.0)
	if unit_data.has(unit_data_key):
		return clampf(float(unit_data.get(unit_data_key, fallback)), 0.0, 1.0)
	if normalized_skill_key == "discipline" and (unit_data.has("skill_leadership") or unit_data.has("skill_toughness")):
		var leadership: float = float(unit_data.get("skill_leadership", fallback))
		var toughness: float = float(unit_data.get("skill_toughness", fallback))
		return clampf((leadership * 0.55) + (toughness * 0.45), 0.0, 1.0)
	return clampf(fallback, 0.0, 1.0)


func _get_homebase_boarded_member_count(fireteam_id: String) -> int:
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
	if member_ids.is_empty():
		return 0
	var elapsed_seconds: float = _get_homebase_boarding_elapsed_seconds(fireteam_id)
	var completed_count: int = 0
	var accumulated_seconds: float = 0.0
	for member_unit_id in member_ids:
		accumulated_seconds += _get_homebase_member_boarding_seconds(String(member_unit_id))
		if elapsed_seconds + 0.001 < accumulated_seconds:
			break
		completed_count += 1
	return clampi(completed_count, 0, member_ids.size())


func _is_homebase_fireteam_boarding_complete(fireteam_id: String) -> bool:
	var total_seconds: float = _get_homebase_fireteam_boarding_total_seconds(fireteam_id)
	return total_seconds > 0.0 and _get_homebase_boarding_elapsed_seconds(fireteam_id) + 0.001 >= total_seconds


func _are_homebase_payload_fireteams_boarded(payload_fireteam_ids: PackedStringArray) -> bool:
	if payload_fireteam_ids.is_empty():
		return false
	for fireteam_id in payload_fireteam_ids:
		if not _is_homebase_fireteam_boarding_complete(String(fireteam_id)):
			return false
	return true


func _get_homebase_active_boarding_unit_id(fireteam_id: String) -> String:
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
	if member_ids.is_empty() or _is_homebase_fireteam_boarding_complete(fireteam_id):
		return ""
	var elapsed_seconds: float = _get_homebase_boarding_elapsed_seconds(fireteam_id)
	var accumulated_seconds: float = 0.0
	for member_unit_id in member_ids:
		accumulated_seconds += _get_homebase_member_boarding_seconds(String(member_unit_id))
		if elapsed_seconds < accumulated_seconds:
			return String(member_unit_id)
	return ""


func _build_homebase_boarding_progress_value(fireteam_id: String, craft_gate: Dictionary) -> float:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty() or not _is_homebase_fireteam_in_flightdeck_payload(normalized_fireteam_id):
		return 0.0
	if not bool(craft_gate.get("can_stage", false)):
		return 0.0
	var total_seconds: float = _get_homebase_fireteam_boarding_total_seconds(normalized_fireteam_id)
	if total_seconds <= 0.0:
		return 0.0
	return clampf((_get_homebase_boarding_elapsed_seconds(normalized_fireteam_id) / total_seconds) * 100.0, 0.0, 100.0)


func _build_homebase_member_boarding_progress_value(fireteam_id: String, unit_id: String, craft_gate: Dictionary) -> float:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or not bool(craft_gate.get("can_stage", false)):
		return 0.0
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
	var member_index: int = -1
	for index in range(member_ids.size()):
		if String(member_ids[index]).strip_edges() == normalized_unit_id:
			member_index = index
			break
	if member_index < 0:
		return 0.0
	var elapsed_seconds: float = _get_homebase_boarding_elapsed_seconds(fireteam_id)
	var member_start: float = _get_homebase_member_boarding_start_seconds(fireteam_id, normalized_unit_id)
	var member_duration: float = _get_homebase_member_boarding_seconds(normalized_unit_id)
	if member_duration <= 0.0:
		return 0.0
	return clampf(((elapsed_seconds - member_start) / member_duration) * 100.0, 0.0, 100.0)


func _build_homebase_boarding_progress_text(fireteam_id: String, craft_gate: Dictionary) -> String:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var total_members: int = _get_member_unit_ids_for_fireteam(normalized_fireteam_id).size()
	var boarded_members: int = _get_homebase_boarded_member_count(normalized_fireteam_id)
	if bool(craft_gate.get("can_stage", false)):
		var active_unit_id: String = _get_homebase_active_boarding_unit_id(normalized_fireteam_id)
		if active_unit_id.is_empty():
			return "Flight Deck | boarded %d/%d NPC" % [boarded_members, total_members]
		return "Flight Deck | boarding %d/%d | active: %s" % [boarded_members, total_members, _build_display_name(active_unit_id)]
	var block_reason: String = String(craft_gate.get("block_reason", "")).strip_edges()
	return "Flight Deck | queued | %d/%d boarded | %s" % [boarded_members, total_members, _build_homebase_direct_block_badge(block_reason)]


func _build_homebase_member_boarding_status_text(fireteam_id: String, unit_id: String, craft_gate: Dictionary) -> String:
	if _build_homebase_member_boarding_progress_value(fireteam_id, unit_id, craft_gate) >= 100.0:
		return "Boarded"
	if unit_id.strip_edges() == _get_homebase_active_boarding_unit_id(fireteam_id):
		return "Boarding"
	return "Queued"


func _build_homebase_fireteam_payload_status_snapshot(craft_gate: Dictionary) -> Array:
	var snapshot: Array = []
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		if fireteam_id.is_empty():
			continue
		snapshot.append(_build_homebase_fireteam_payload_status(fireteam_id, "fireteam_list", craft_gate))
	return snapshot


func _apply_homebase_fireteam_card_payload_truth(card: FOBFireteamCard, fireteam_id: String, source_context: String) -> void:
	if card == null:
		return
	var craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate()
	var status: Dictionary = _build_homebase_fireteam_payload_status(fireteam_id, source_context, craft_gate)
	var status_text: String = String(status.get("visible_text", "")).strip_edges()
	var loadout_text: String = String(_get_fireteam_definition(fireteam_id).get("loadout", HOMEBASE_DEFAULT_LOADOUT_ID)).strip_edges().to_upper()
	if loadout_text.is_empty():
		loadout_text = HOMEBASE_DEFAULT_LOADOUT_ID.to_upper()
	var is_flightdeck_card: bool = source_context == "dropship_wait" or source_context == "homebase_dropship_staging" or source_context == HOMEBASE_DIRECT_STAGING_DROP_KIND
	var stage_label := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	if stage_label != null:
		stage_label.text = status_text if is_flightdeck_card else "Loadout: %s | %s" % [loadout_text, status_text]
		stage_label.set_meta("homebase_direct_payload_status", String(status.get("status", "")).strip_edges())
		stage_label.set_meta("homebase_direct_payload_operator_count", int(status.get("operator_count", 0)))
		stage_label.set_meta("homebase_direct_payload_boarded", bool(status.get("boarded", false)))
		stage_label.set_meta("homebase_direct_payload_block_reason", String(status.get("block_reason", "")).strip_edges())
		stage_label.tooltip_text = String(status.get("tooltip_text", "")).strip_edges()
	var teamfit_label := card.get_node_or_null("Margin/VBox/TeamfitLabel") as Label
	if teamfit_label != null and (source_context == "fireteam_list" or is_flightdeck_card):
		teamfit_label.text = "" if is_flightdeck_card else String(status.get("detail_text", "")).strip_edges()
		teamfit_label.visible = false if is_flightdeck_card else not teamfit_label.text.is_empty()
		teamfit_label.set_meta("homebase_direct_payload_status", String(status.get("status", "")).strip_edges())
		teamfit_label.set_meta("homebase_direct_payload_operator_count", int(status.get("operator_count", 0)))
		teamfit_label.set_meta("homebase_direct_payload_boarded", bool(status.get("boarded", false)))
		teamfit_label.tooltip_text = String(status.get("tooltip_text", "")).strip_edges()
	card.set_meta("homebase_direct_payload_status", String(status.get("status", "")).strip_edges())
	card.set_meta("homebase_direct_payload_text", status_text)
	card.set_meta("homebase_direct_payload_operator_count", int(status.get("operator_count", 0)))
	card.set_meta("homebase_direct_payload_fireteam_count", int(status.get("payload_fireteam_count", _get_homebase_direct_payload_fireteam_ids().size())))
	card.set_meta("homebase_direct_payload_boarded", bool(status.get("boarded", false)))
	card.set_meta("homebase_direct_payload_boarding_progress", _build_homebase_boarding_progress_value(fireteam_id, craft_gate))
	card.set_meta("homebase_direct_payload_queued", bool(status.get("queued", false)))
	card.set_meta("homebase_direct_payload_block_reason", String(status.get("block_reason", "")).strip_edges())
	card.tooltip_text = String(status.get("tooltip_text", "")).strip_edges()
	_apply_homebase_fireteam_card_clean_presentation(card)


func _build_homebase_fireteam_payload_status(fireteam_id: String, source_context: String, craft_gate: Dictionary) -> Dictionary:
	var normalized_id: String = _normalize_fireteam_id(fireteam_id)
	var gate_craft_id: String = String(craft_gate.get("payload_craft_id", "")).strip_edges()
	var owning_craft_id: String = _find_homebase_direct_payload_craft_for_fireteam(normalized_id)
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(gate_craft_id) if not gate_craft_id.is_empty() else _get_homebase_direct_payload_fireteam_ids()
	if not owning_craft_id.is_empty() and not payload_fireteam_ids.has(normalized_id):
		payload_fireteam_ids = _get_homebase_direct_payload_fireteam_ids_for_craft(owning_craft_id)
		craft_gate = _build_homebase_direct_staging_craft_gate_for_craft(owning_craft_id)
	var operator_count: int = _get_member_unit_ids_for_fireteam(normalized_id).size()
	var is_queued: bool = payload_fireteam_ids.has(normalized_id)
	var craft_ready: bool = bool(craft_gate.get("can_stage", false))
	var block_reason: String = String(craft_gate.get("block_reason", "")).strip_edges()
	var block_text: String = String(craft_gate.get("block_text", "")).strip_edges()
	var loadout_editing: bool = _normalize_fireteam_id(_loadout_staged_fireteam_id) == normalized_id or source_context == "loadout_staging"
	var status_id := "homebase"
	var visible_text := "Staged in Homebase | not boarded"
	var detail_text := "Not in launch payload"
	var boarded := false
	if is_queued and craft_ready:
		var boarded_members: int = _get_homebase_boarded_member_count(normalized_id)
		var boarding_complete: bool = _is_homebase_fireteam_boarding_complete(normalized_id)
		status_id = "boarded" if boarding_complete else "boarding"
		boarded = boarding_complete
		visible_text = "Flight Deck | boarded %d/%d NPC" % [boarded_members, operator_count]
		if loadout_editing and source_context == "loadout_staging":
			visible_text = "Loadout editing | %s" % visible_text
		detail_text = "True mission payload" if boarding_complete else "Boarding in sequence"
	elif is_queued:
		status_id = "blocked"
		visible_text = "%s | %d operators queued" % [_build_homebase_direct_block_badge(block_reason), operator_count]
		if loadout_editing:
			visible_text = "Loadout editing | %s" % visible_text
		detail_text = block_text if not block_text.is_empty() else _build_homebase_direct_block_badge(block_reason)
	elif loadout_editing:
		status_id = "loadout_editing"
		visible_text = "Loadout editing | not boarded"
		detail_text = "Kit edits only; not a launch payload"
	var tooltip_text: String = detail_text
	if block_text.is_empty():
		block_text = String(craft_gate.get("block_text", "")).strip_edges()
	if status_id == "blocked" and not block_text.is_empty():
		tooltip_text = "%s\n%s" % [visible_text, block_text]
	return {
		"fireteam_id": normalized_id,
		"status": status_id,
		"visible_text": visible_text,
		"detail_text": detail_text,
		"tooltip_text": tooltip_text,
		"operator_count": operator_count,
		"payload_operator_count": _build_unit_ids_for_fireteams(payload_fireteam_ids).size(),
		"payload_fireteam_count": payload_fireteam_ids.size(),
		"queued": is_queued,
		"boarded": boarded,
		"loadout_editing": loadout_editing,
		"block_reason": block_reason,
		"block_text": block_text,
	}


func _build_homebase_direct_block_badge(block_reason: String) -> String:
	match block_reason.strip_edges():
		"no_homebase_craft":
			return "Blocked: no dropship"
		"not_dropship":
			return "Blocked: selected craft"
		"air_asset_unavailable":
			return "Blocked: unavailable craft"
		"craft_in_transit", "craft_busy":
			return "Blocked: busy craft"
		"not_at_homebase":
			return "Blocked: not at homebase"
		_:
			return "Blocked: craft gate"


func _build_homebase_direct_payload_status_text(craft_gate: Dictionary, include_blocker_text: bool = true) -> String:
	var gate_craft_id: String = String(craft_gate.get("payload_craft_id", "")).strip_edges()
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(gate_craft_id) if not gate_craft_id.is_empty() else _get_homebase_direct_payload_fireteam_ids()
	var payload_operator_count: int = _build_unit_ids_for_fireteams(payload_fireteam_ids).size()
	var count_text: String = "Payload: %d ops / %d FT" % [payload_operator_count, payload_fireteam_ids.size()]
	if payload_fireteam_ids.is_empty():
		return "%s | no fireteam boarded" % count_text
	if bool(craft_gate.get("can_stage", false)):
		var boarded_count: int = _get_homebase_direct_boarded_operator_count_for_fireteams(payload_fireteam_ids)
		if _are_homebase_payload_fireteams_boarded(payload_fireteam_ids):
			return "%s | Boarded %d/%d NPC | Flight Deck" % [count_text, boarded_count, payload_operator_count]
		return "%s | Boarding %d/%d NPC | Flight Deck" % [count_text, boarded_count, payload_operator_count]
	var block_reason: String = String(craft_gate.get("block_reason", "")).strip_edges()
	var block_text: String = String(craft_gate.get("block_text", "")).strip_edges()
	if include_blocker_text and not block_text.is_empty():
		return "%s | %s | %s" % [count_text, _build_homebase_direct_block_badge(block_reason), block_text]
	return "%s | %s" % [count_text, _build_homebase_direct_block_badge(block_reason)]


func _build_homebase_loadout_status_text(fireteam_id: String, has_focus_fireteam: bool) -> String:
	if not has_focus_fireteam:
		return "Drop a fireteam card from #10 here."
	var member_count: int = _get_member_unit_ids_for_fireteam(fireteam_id).size()
	var craft_gate: Dictionary = _get_homebase_direct_staging_craft_gate()
	var payload_status: Dictionary = _build_homebase_fireteam_payload_status(fireteam_id, "loadout_staging", craft_gate)
	return "%s | %d operators | %s" % [_get_fireteam_label(fireteam_id), member_count, String(payload_status.get("visible_text", "Compact Homebase loadout")).strip_edges()]


func _build_homebase_direct_staging_status_text(craft_gate: Dictionary) -> String:
	var gate_craft_id: String = String(craft_gate.get("payload_craft_id", "")).strip_edges()
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(gate_craft_id) if not gate_craft_id.is_empty() else _get_homebase_direct_payload_fireteam_ids()
	var payload_operator_count: int = _build_unit_ids_for_fireteams(payload_fireteam_ids).size()
	var count_text: String = "Flightdeck payload: %d operators / %d fireteam(s)." % [payload_operator_count, payload_fireteam_ids.size()]
	if payload_fireteam_ids.is_empty():
		var empty_block_text: String = String(craft_gate.get("block_text", "")).strip_edges()
		if not empty_block_text.is_empty():
			return "%s %s" % [count_text, empty_block_text]
		return "%s Drop a fireteam card here to board it." % count_text
	if bool(craft_gate.get("can_stage", false)):
		var craft_def: Dictionary = Dictionary(craft_gate.get("craft", {}))
		var craft_name: String = String(craft_def.get("display_name", "Dropship")).strip_edges()
		return "%s %s. Boarding %d/%d NPC." % [
			count_text,
			craft_name,
			_get_homebase_direct_boarded_operator_count_for_fireteams(payload_fireteam_ids),
			payload_operator_count,
		]
	var block_reason: String = String(craft_gate.get("block_reason", "")).strip_edges()
	var block_text: String = String(craft_gate.get("block_text", "Add a Homebase dropship to the Flightdeck.")).strip_edges()
	return "%s %s. %s" % [count_text, _build_homebase_direct_block_badge(block_reason), block_text]


func _build_homebase_mission_drop_cards(payload_fireteam_ids: PackedStringArray, payload_unit_ids: PackedStringArray, payload_craft_id: String = "", payload_ready: bool = false) -> Array:
	var cards: Array = []
	var visible_aircraft_definitions: Array = _get_visible_homebase_aircraft_definitions()
	if visible_aircraft_definitions.is_empty():
		return cards
	for craft_variant in visible_aircraft_definitions:
		var craft_def: Dictionary = Dictionary(craft_variant)
		var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			continue
		var is_payload_craft: bool = craft_id == payload_craft_id
		var assigned_pilot_id: String = _get_assigned_pilot_id(craft_id)
		var pilot_display_name: String = _build_display_name(assigned_pilot_id) if not assigned_pilot_id.is_empty() else ""
		cards.append(
			{
				"craft_id": craft_id,
				"display_name": String(craft_def.get("display_name", craft_id)).strip_edges(),
				"title_text": UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title(String(craft_def.get("display_name", craft_id)).strip_edges()),
				"texture_path": String(craft_def.get("texture_path", "")).strip_edges(),
				"payload_source": "homebase_direct",
				"state": "waiting" if is_payload_craft and payload_ready else "",
				"pilot_text": "Pilot: %s" % pilot_display_name if not pilot_display_name.is_empty() else "Pilot: none",
				"pilot_unit_id": assigned_pilot_id,
				"pilot_display_name": pilot_display_name,
				"pilot_portrait_path": _get_profile_portrait_path(assigned_pilot_id),
				"queued_fireteam_ids": Array(payload_fireteam_ids if is_payload_craft else PackedStringArray()),
				"boarded_fireteam_ids": Array(payload_fireteam_ids if is_payload_craft and payload_ready else PackedStringArray()),
				"embarked_unit_ids": Array(payload_unit_ids if is_payload_craft and payload_ready else PackedStringArray()),
				"passenger_count": payload_unit_ids.size() if is_payload_craft and payload_ready else 0,
			}
		)
	return cards


func _build_selected_names_text() -> String:
	if _selected_unit_ids.is_empty():
		return "No staged operators yet."

	var display_names: PackedStringArray = []
	for unit_id in _selected_unit_ids:
		display_names.append(_build_display_name(String(unit_id)))

	return ", ".join(display_names)


func _build_team_hint_text() -> String:
	if not _team_feedback_text.is_empty():
		return _team_feedback_text

	if _selected_unit_ids.size() >= _get_team_capacity():
		return "Transferteam voll. Entferne zuerst eine bereits gestagte Person."

	if not _team_transfer_entries.is_empty():
		return "TRANSFERFENSTER\n\n- Send to FOB startet jetzt einen Anflug mit Fortschrittsbalken.\n- Der View bleibt auf Homebase, bis du selbst wechselst.\n- Eingetroffene Teams erscheinen erst danach in der FOB."

	return "TRANSFERFENSTER\n\n- Ziehe Personen aus dem linken Roster hier hinein.\n- Die Karten in der Mitte zeigen das aktuelle Transferpaket.\n- Bestaetigt wird oben rechts direkt im Transferfenster."


func _build_roster_tooltip_text() -> String:
	return "ROSTER\n\n- Klick fokussiert die Karte.\n- Doppelklick oeffnet den Charakterbogen.\n- Ziehen legt die Person ins Transferfenster oder aufs Flugdeck.\n- Bereits gestagte oder zugewiesene Personen verschwinden links."


func _build_mission_tooltip_text() -> String:
	return "MISSION BRIEF\n\n- Zeigt Einsatzname, Teamlimit und Transferstatus.\n- Das Dropdown oben rechts wechselt die aktuelle Mission und damit auch die aktive Map.\n- Senden sitzt nicht mehr hier, sondern oben rechts im Transferfenster."


func _build_aircraft_tooltip_text() -> String:
	return "FLIGHT DECK\n\n- Das obere Dropdown waehlt nur den Schiffstyp fuer +.\n- Das Deck startet leer; jede Shipcard entsteht erst ueber +.\n- Frachter tragen Cargo-Dropdown und Load direkt in ihrer Shipcard.\n- Entfernt wird ein Schiff ueber - direkt in der jeweiligen Shipcard."


func _build_character_sheet_tooltip_text() -> String:
	return "CHARAKTERBOGEN\n\n- Wird per Doppelklick auf eine NPC-Karte geoeffnet.\n- Rein lesende Profilansicht der fokussierten Person.\n- Ueber Close wieder ausblendbar."


func _update_character_sheet_visibility() -> void:
	var info_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/InfoPanel") as Control
	if info_panel != null:
		info_panel.visible = false
		info_panel.set_meta("homebase_legacy_character_sheet_window_disabled", true)
	var popup := get_node_or_null("CharacterSheetPopup") as Control
	if popup == null:
		return
	_apply_character_popup_rect()
	popup.visible = _character_sheet_open
	popup.set_meta("character_sheet_popup_visible", _character_sheet_open)


func _build_send_to_fob_tooltip() -> String:
	if _selected_unit_ids.is_empty():
		return "SEND TO FOB\n\n- Startet einen Teamtransfer mit Fortschrittsbalken.\n- Vorher mindestens eine Person in die Mitte ziehen."

	return "SEND TO FOB\n\n- Startet den Anflug des aktuell gestagten Teams zur FOB.\n- Der Screen bleibt auf Homebase.\n- Das Team erscheint erst nach Ankunft in der FOB."


func _build_transfer_status_text(staged_count: int, team_capacity: int) -> String:
	var aircraft_snapshot: Dictionary = _aircraft_manager.get_contract_snapshot()
	var transfer_count: int = _team_transfer_entries.size() + int(aircraft_snapshot.get("pilot_transfer_count", 0)) + int(aircraft_snapshot.get("cargo_load_count", 0))
	if transfer_count > 0:
		if staged_count > 0:
			return "%d staged, %d inbound" % [staged_count, transfer_count]
		return "%d transfer(s) inbound to FOB" % transfer_count

	if staged_count <= 0:
		return "awaiting roster selection"

	if staged_count >= team_capacity:
		return "ready to send"

	return "%d of %d operators staged" % [staged_count, team_capacity]


func _build_mission_summary_text(staged_count: int, team_capacity: int, pilot_count: int, mission_slot_usage: int = -1) -> String:
	if mission_slot_usage < 0:
		mission_slot_usage = staged_count + pilot_count
	var aircraft_snapshot: Dictionary = _aircraft_manager.get_contract_snapshot()
	var has_aircraft_activity: bool = int(aircraft_snapshot.get("pilot_transfer_count", 0)) > 0 or int(aircraft_snapshot.get("cargo_load_count", 0)) > 0
	if not _team_transfer_entries.is_empty() or has_aircraft_activity:
		return "%s on %s is active. Mission occupancy is currently %d / %d including pilots, and confirmed transfers stay visible in Homebase until arrival." % [_selected_mission_name, _build_selected_mission_map_label(), mission_slot_usage, _selected_mission_slot_count]

	if staged_count <= 0:
		return "%s uses %s as current map. Mission occupancy is %d / %d including pilots; the center window starts empty and defines the next transfer package." % [_selected_mission_name, _build_selected_mission_map_label(), mission_slot_usage, _selected_mission_slot_count]

	if staged_count >= team_capacity:
		return "The transfer package for %s is full. Mission occupancy is %d / %d including pilots; review the staged operators and send the team to FOB when ready." % [_selected_mission_name, mission_slot_usage, _selected_mission_slot_count]

	return "The transfer package is still open. You can stage %d more operator(s) before the current Homebase mission limit is reached." % [team_capacity - staged_count]


func _count_assigned_pilots() -> int:
	return _aircraft_manager.count_assigned_pilots()


func _build_selected_mission_map_label() -> String:
	var map_file_path: String = _selected_mission_map_path.get_file().get_basename()
	if map_file_path.is_empty():
		return "unknown_map"
	return map_file_path


func _resolve_selected_mission_scenario_path() -> String:
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("mission_id", "")).strip_edges() == _selected_mission_id:
			return String(mission_definition.get("scenario_file_path", "")).strip_edges()
	for mission_variant in _mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		if String(mission_definition.get("map_file_path", "")).strip_edges() == _selected_mission_map_path:
			return String(mission_definition.get("scenario_file_path", "")).strip_edges()
	return _selected_mission_scenario_path.strip_edges()


func _populate_mission_selector(selector: OptionButton) -> void:
	if selector == null:
		return
	_configure_flightdeck_option_button(selector)
	selector.clear()
	var mission_catalog: Array = _mission_catalog if not _mission_catalog.is_empty() else [
		{
			"mission_id": _selected_mission_id,
			"mission_name": _selected_mission_name,
			"map_file_path": _selected_mission_map_path,
			"slot_count": _selected_mission_slot_count,
		}
	]
	var selected_index: int = -1
	for mission_variant in mission_catalog:
		var mission_definition: Dictionary = Dictionary(mission_variant)
		var mission_id: String = String(mission_definition.get("mission_id", "")).strip_edges()
		var mission_name: String = String(mission_definition.get("mission_name", "Mission")).strip_edges()
		var map_file_path: String = String(mission_definition.get("map_file_path", "")).strip_edges()
		var slot_count: int = int(mission_definition.get("slot_count", _selected_mission_slot_count))
		selector.add_item("%s | %s | %d Slots" % [mission_name, map_file_path.get_file().get_basename(), slot_count])
		selector.set_item_metadata(selector.item_count - 1, mission_id)
		if mission_id == _selected_mission_id or (mission_id.is_empty() and map_file_path == _selected_mission_map_path):
			selected_index = selector.item_count - 1
	if selected_index < 0 and selector.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		selector.select(selected_index)
	META_UI_SKIN_SCRIPT.style_secondary_button(selector)


func _build_sheet_status_text(unit_id: String) -> String:
	var assigned_craft_id: String = _find_assigned_craft_for_unit(unit_id)
	if not assigned_craft_id.is_empty():
		return "Loc: Homebase / Flight Deck | Status: assigned pilot for %s" % _build_craft_display_name(assigned_craft_id)

	var transit_entry: Dictionary = _find_transfer_entry_for_unit(unit_id)
	if not transit_entry.is_empty():
		return "Loc: Transit Lane / FOB Approach | Status: eta %s" % _build_transfer_eta_text(transit_entry)

	if _selected_unit_ids.has(unit_id):
		return "Loc: Homebase / Transfer Window | Status: staged for FOB transfer"

	return "Loc: Homebase / Roster | Status: available"


func _build_homebase_fireteam_text(unit_id: String) -> String:
	return CHARACTER_SHEET_FORMATTER_SCRIPT.format_fireteam_label(_get_selected_fireteam_id_for_unit(unit_id))


func _get_selected_fireteam_id_for_unit(unit_id: String) -> String:
	var unit_index: int = _selected_unit_ids.find(unit_id)
	if unit_index < 0 or unit_index >= _selected_fireteam_ids.size():
		return ""
	return String(_selected_fireteam_ids[unit_index]).strip_edges().to_lower()


func _build_homebase_location_text(unit_id: String) -> String:
	var assigned_craft_id: String = _find_assigned_craft_for_unit(unit_id)
	if not assigned_craft_id.is_empty():
		return "Loc: Homebase / Flight Deck / %s" % _build_craft_display_name(assigned_craft_id)

	var transit_entry: Dictionary = _find_transfer_entry_for_unit(unit_id)
	if not transit_entry.is_empty():
		return "Loc: Transit To FOB / ETA %s" % _build_transfer_eta_text(transit_entry)

	if _selected_unit_ids.has(unit_id):
		return "Loc: Homebase / Transfer Window"
	return "Loc: Homebase / Roster"


func _build_roster_card_secondary_text(unit_id: String, profile) -> String:
	var status_text: String = ""
	if profile != null:
		status_text = String(profile.status_text).strip_edges()
		if status_text.is_empty():
			status_text = String(profile.availability_status).strip_edges()
	status_text = status_text.capitalize() if not status_text.is_empty() else "Active"
	var location_text: String = _build_homebase_location_text(unit_id)
	return "%s | %s" % [status_text, location_text]


func _build_default_aircraft_definitions() -> Array:
	return _aircraft_manager.build_default_aircraft_definitions()


func _build_aircraft_status_text(craft_def: Dictionary, craft_name: String, assigned_pilot_id: String, craft_busy: bool, cargo_loading: bool) -> String:
	return _aircraft_manager.build_aircraft_status_text(
		craft_def,
		craft_name,
		assigned_pilot_id,
		_build_display_name(assigned_pilot_id) if not assigned_pilot_id.is_empty() else "",
		_aircraft_feedback_text
	)


func _build_team_transfer_title(entry: Dictionary) -> String:
	var display_names: PackedStringArray = []
	for unit_id_variant in entry.get("unit_ids", []):
		display_names.append(_build_display_name(String(unit_id_variant)))
	if display_names.is_empty():
		return "Inbound fireteam"
	return "Fireteam: %s" % ", ".join(display_names)


func _build_team_transfer_detail(entry: Dictionary) -> String:
	return "%d operator(s) inbound | ETA %s" % [Array(entry.get("unit_ids", [])).size(), _build_transfer_eta_text(entry)]


func _build_pilot_transfer_title(entry: Dictionary) -> String:
	var pilot_id: String = String(entry.get("pilot_unit_id", "")).strip_edges()
	var craft_name: String = _build_craft_display_name(String(entry.get("craft_id", "")).strip_edges())
	return "%s | %s" % [craft_name, _build_display_name(pilot_id)]


func _build_pilot_transfer_detail(entry: Dictionary) -> String:
	var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
	var cargo_name: String = _build_cargo_display_name(_get_aircraft_definition_by_id(craft_id), String(entry.get("cargo_id", "")).strip_edges())
	if cargo_name.is_empty():
		return "Ship inbound to FOB | ETA %s" % _build_transfer_eta_text(entry)
	return "Ship inbound to FOB | Cargo %s | ETA %s" % [cargo_name, _build_transfer_eta_text(entry)]


func _build_cargo_load_title(entry: Dictionary) -> String:
	var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
	return "%s | Loading %s" % [
		_build_craft_display_name(craft_id),
		_build_cargo_display_name(_get_aircraft_definition_by_id(craft_id), String(entry.get("cargo_id", "")).strip_edges()),
	]


func _build_cargo_load_detail(entry: Dictionary) -> String:
	return "Cargo prep at Homebase | ETA %s" % _build_transfer_eta_text(entry)


func _build_transfer_entry_card(title: String, detail: String, entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.10, 0.13, 0.15, 1.0)
	stylebox.border_color = Color(0.26, 0.40, 0.47, 1.0)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", stylebox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title_label)

	var progress_bar := ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = _build_transfer_progress_value(entry)
	progress_bar.show_percentage = false
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(progress_bar)

	var detail_label := Label.new()
	detail_label.text = detail
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(detail_label)
	return panel


func _build_shipcard(craft_def: Dictionary) -> Control:
	var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
	var craft_name: String = String(craft_def.get("display_name", craft_id)).strip_edges()
	var assigned_pilot_id: String = _get_assigned_pilot_id(craft_id)
	var craft_in_transit: bool = _is_craft_in_transit(craft_id)
	var craft_busy: bool = _has_active_pilot_transfer_for_craft(craft_id) or craft_in_transit
	var cargo_loading: bool = _has_active_cargo_load_for_craft(craft_id)
	var air_asset_unavailable: bool = bool(craft_def.get("air_asset_unavailable", false))
	var cargo_capable: bool = _craft_supports_cargo(craft_def)
	var is_selected: bool = craft_id == _get_selected_aircraft_id()

	var loaded_cargo_id: String = _get_loaded_cargo_id(craft_id)
	var selected_cargo_id: String = loaded_cargo_id if not loaded_cargo_id.is_empty() else _get_selected_cargo_id(craft_id)

	var shipcard := PanelContainer.new()
	shipcard.name = "Shipcard_%s" % craft_id
	shipcard.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	shipcard.custom_minimum_size = Vector2(HOMEBASE_SHIPCARD_COMPACT_WIDTH, 0.0)
	shipcard.add_theme_stylebox_override("panel", _build_shipcard_stylebox(is_selected, craft_busy or cargo_loading or air_asset_unavailable, craft_in_transit or air_asset_unavailable))
	shipcard.modulate = Color(1.0, 1.0, 1.0, 0.56) if craft_in_transit or air_asset_unavailable else Color(1.0, 1.0, 1.0, 1.0)
	shipcard.set_meta("homebase_shipcard", true)
	shipcard.set_meta("craft_id", craft_id)
	shipcard.set_meta("homebase_shipcard_in_transit", craft_in_transit)
	shipcard.set_meta("homebase_shipcard_no_horizontal_overflow", true)
	shipcard.set_meta("homebase_shipcard_half_width", true)
	shipcard.set_meta("homebase_shipcard_compact_width", HOMEBASE_SHIPCARD_COMPACT_WIDTH)
	_configure_homebase_shipcard_fireteam_drop_target(shipcard, craft_id, not craft_in_transit and not air_asset_unavailable)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	shipcard.add_child(margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.name = "ShipcardVBox"
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(card_vbox)

	var top_row := HBoxContainer.new()
	top_row.name = "ShipcardTopRow"
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_theme_constant_override("separation", 4)
	top_row.set_meta("homebase_shipcard_top_lane", true)
	card_vbox.add_child(top_row)

	var ship_button := Button.new()
	ship_button.name = "ShipVisualButton"
	ship_button.flat = true
	ship_button.focus_mode = Control.FOCUS_NONE
	ship_button.custom_minimum_size = HOMEBASE_SHIPCARD_BUTTON_SIZE
	ship_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ship_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ship_button.clip_contents = true
	ship_button.pressed.connect(_on_shipcard_select_requested.bind(craft_id))
	_configure_homebase_shipcard_fireteam_drop_target(ship_button, craft_id, not craft_in_transit and not air_asset_unavailable)
	top_row.add_child(ship_button)

	var ship_texture := TextureRect.new()
	ship_texture.name = "ShipTexture"
	ship_texture.texture = _get_aircraft_texture(craft_def)
	ship_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ship_texture.custom_minimum_size = HOMEBASE_SHIPCARD_IMAGE_SIZE
	ship_texture.size = HOMEBASE_SHIPCARD_IMAGE_SIZE
	ship_texture.position = HOMEBASE_SHIPCARD_IMAGE_OFFSET
	ship_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_texture.set_meta("homebase_shipcard_visual_anchor", "left_top")
	ship_texture.set_meta("homebase_shipcard_visual_offset", HOMEBASE_SHIPCARD_IMAGE_OFFSET)
	ship_texture.set_meta("homebase_shipcard_visual_enlarged", true)
	ship_texture.set_meta("homebase_shipcard_visual_crop_compensates_transparency", true)
	if ship_texture.texture != null:
		ship_texture.modulate = Color(1.0, 1.0, 1.0, 0.46 if craft_in_transit or air_asset_unavailable else 1.0)
	else:
		ship_texture.modulate = Color(0.35, 0.37, 0.42, 1.0)
	ship_button.add_child(ship_texture)

	var title_vbox := VBoxContainer.new()
	title_vbox.name = "ShipcardTitleVBox"
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_vbox.add_theme_constant_override("separation", 1)
	top_row.add_child(title_vbox)

	var ship_label := Label.new()
	ship_label.name = "ShipVisualLabel"
	ship_label.text = "%s%s%s" % [craft_name, " *" if is_selected else "", " | TRANSIT" if craft_in_transit else ""]
	ship_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	ship_label.clip_text = true
	ship_label.add_theme_font_size_override("font_size", 9)
	META_UI_SKIN_SCRIPT.style_body_label(ship_label, 9)
	title_vbox.add_child(ship_label)

	var ship_payload_label := Label.new()
	ship_payload_label.name = "ShipPayloadSummaryLabel"
	ship_payload_label.text = _build_homebase_shipcard_payload_summary(craft_id, craft_in_transit, air_asset_unavailable)
	ship_payload_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ship_payload_label.add_theme_font_size_override("font_size", 8)
	ship_payload_label.set_meta("homebase_shipcard_payload_summary_label", true)
	ship_payload_label.set_meta("craft_id", craft_id)
	ship_payload_label.set_meta("homebase_direct_boarded_operator_count", _get_homebase_direct_boarded_operator_count_for_craft(craft_id))
	ship_payload_label.set_meta("homebase_direct_payload_operator_count", _get_homebase_direct_payload_operator_count_for_craft(craft_id))
	META_UI_SKIN_SCRIPT.style_body_label(ship_payload_label, 8)
	title_vbox.add_child(ship_payload_label)

	if cargo_capable:
		var cargo_row := HBoxContainer.new()
		cargo_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cargo_row.add_theme_constant_override("separation", 4)
		card_vbox.add_child(cargo_row)

		var cargo_dropdown := OptionButton.new()
		cargo_dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cargo_dropdown.custom_minimum_size = Vector2(0.0, 22.0)
		cargo_dropdown.add_theme_font_size_override("font_size", 8)
		_configure_flightdeck_option_button(cargo_dropdown)
		var selected_cargo_index: int = -1
		for cargo_option_variant in _get_cargo_options_for_craft(craft_def):
			var cargo_option: Dictionary = Dictionary(cargo_option_variant)
			var cargo_id: String = String(cargo_option.get("cargo_id", "")).strip_edges()
			cargo_dropdown.add_item(String(cargo_option.get("display_name", cargo_id)).strip_edges())
			cargo_dropdown.set_item_metadata(cargo_dropdown.item_count - 1, cargo_id)
			if cargo_id == selected_cargo_id:
				selected_cargo_index = cargo_dropdown.item_count - 1
		if selected_cargo_index >= 0:
			cargo_dropdown.select(selected_cargo_index)
		elif cargo_dropdown.item_count > 0:
			cargo_dropdown.select(0)
		cargo_dropdown.disabled = air_asset_unavailable or cargo_loading or not loaded_cargo_id.is_empty() or craft_in_transit
		META_UI_SKIN_SCRIPT.style_secondary_button(cargo_dropdown)
		cargo_dropdown.item_selected.connect(_on_shipcard_cargo_selected.bind(craft_id, cargo_dropdown))
		cargo_row.add_child(cargo_dropdown)

		var cargo_load_button := Button.new()
		cargo_load_button.text = "Loaded" if not loaded_cargo_id.is_empty() else ("Loading" if cargo_loading else "Load")
		cargo_load_button.custom_minimum_size = Vector2(52.0, 22.0)
		cargo_load_button.add_theme_font_size_override("font_size", 8)
		cargo_load_button.disabled = air_asset_unavailable or craft_in_transit or cargo_loading or not _can_load_selected_cargo(craft_def, craft_id)
		if cargo_load_button.disabled:
			META_UI_SKIN_SCRIPT.style_secondary_button(cargo_load_button)
		else:
			META_UI_SKIN_SCRIPT.style_transfer_button(cargo_load_button, true)
		cargo_load_button.pressed.connect(_on_shipcard_load_cargo_pressed.bind(craft_id))
		cargo_row.add_child(cargo_load_button)

	var progress_block := _build_shipcard_progress_block(craft_id, cargo_loading, craft_in_transit)
	if progress_block != null:
		card_vbox.add_child(progress_block)

	var actions := HBoxContainer.new()
	actions.name = "ShipActionColumn"
	actions.alignment = BoxContainer.ALIGNMENT_BEGIN
	actions.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	actions.add_theme_constant_override("separation", 2)
	actions.set_meta("homebase_actions_top_aligned", true)
	actions.set_meta("homebase_shipcard_actions_top_lane", true)
	top_row.add_child(actions)

	var dispatch_target: String = _get_homebase_dispatch_target(craft_id)
	var mission_toggle := CheckBox.new()
	mission_toggle.name = "ShipDestinationToggle"
	mission_toggle.text = "Mission"
	mission_toggle.button_pressed = dispatch_target == HOMEBASE_DISPATCH_TARGET_MISSION
	mission_toggle.disabled = craft_in_transit or air_asset_unavailable
	mission_toggle.custom_minimum_size = Vector2(64.0, 20.0)
	mission_toggle.add_theme_font_size_override("font_size", 8)
	mission_toggle.tooltip_text = "Checked: direct mission payload. Off: FOB transfer target."
	mission_toggle.set_meta("homebase_shipcard_dispatch_toggle", true)
	mission_toggle.set_meta("craft_id", craft_id)
	mission_toggle.set_meta("dispatch_target", dispatch_target)
	mission_toggle.toggled.connect(_on_shipcard_dispatch_target_toggled.bind(craft_id))
	actions.add_child(mission_toggle)

	var send_button := Button.new()
	send_button.name = "ShipSendButton"
	send_button.text = "Send"
	send_button.custom_minimum_size = Vector2(48.0, 20.0)
	send_button.add_theme_font_size_override("font_size", 8)
	send_button.disabled = air_asset_unavailable or craft_in_transit or not _can_dispatch_shipcard(craft_def, craft_id, assigned_pilot_id)
	send_button.tooltip_text = "Launch this dropship straight to Mission." if dispatch_target == HOMEBASE_DISPATCH_TARGET_MISSION else "Send this dropship to FOB."
	send_button.set_meta("homebase_shipcard_send_target", dispatch_target)
	send_button.set_meta("craft_id", craft_id)
	send_button.set_meta("homebase_direct_payload_ready", _has_homebase_direct_launch_payload_for_craft(craft_id))
	send_button.set_meta("homebase_direct_payload_operator_count", _get_homebase_direct_payload_operator_count_for_craft(craft_id))
	if send_button.disabled:
		META_UI_SKIN_SCRIPT.style_secondary_button(send_button)
	else:
		META_UI_SKIN_SCRIPT.style_transfer_button(send_button, true)
	send_button.pressed.connect(_on_send_pilot_button_pressed.bind(craft_id))
	actions.add_child(send_button)

	var remove_button := Button.new()
	remove_button.text = "X"
	remove_button.tooltip_text = "Remove this shipcard from the flight deck."
	remove_button.custom_minimum_size = Vector2(28.0, 20.0)
	remove_button.add_theme_font_size_override("font_size", 8)
	remove_button.disabled = not _can_remove_aircraft(craft_id)
	META_UI_SKIN_SCRIPT.style_secondary_button(remove_button)
	remove_button.pressed.connect(_on_shipcard_remove_requested.bind(craft_id))
	actions.add_child(remove_button)

	var pilot_panel: PanelContainer = _build_shipcard_pilot_panel(craft_id, craft_name, assigned_pilot_id, craft_busy or cargo_loading or air_asset_unavailable, craft_in_transit or air_asset_unavailable)
	pilot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(pilot_panel)

	var payload_panel := _build_shipcard_direct_payload_panel(craft_id)
	if payload_panel != null:
		card_vbox.add_child(payload_panel)

	_configure_homebase_shipcard_wide_fireteam_drop_targets(shipcard, craft_id, not craft_in_transit and not air_asset_unavailable)
	return shipcard


func _build_homebase_shipcard_payload_summary(craft_id: String, craft_in_transit: bool, air_asset_unavailable: bool) -> String:
	var normalized_craft_id: String = craft_id.strip_edges()
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	if air_asset_unavailable:
		return "Recovery ETA: %ds" % int(craft_def.get("air_asset_recovery_eta_seconds", 0))
	if craft_in_transit:
		return "%s: ETA %s" % [_build_shipcard_transfer_label(craft_def), _build_transfer_eta_text(_find_transfer_entry_for_craft(normalized_craft_id))]
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id)
	if payload_fireteam_ids.is_empty():
		return "Payload: empty"
	var total_count: int = _build_unit_ids_for_fireteams(payload_fireteam_ids).size()
	var boarded_count: int = _get_homebase_direct_boarded_operator_count_for_craft(normalized_craft_id)
	if _are_homebase_payload_fireteams_boarded(payload_fireteam_ids):
		return "Payload: %d/%d NPC boarded" % [boarded_count, total_count]
	return "Boarding: %d/%d NPC" % [boarded_count, total_count]


func _configure_homebase_shipcard_fireteam_drop_target(control: Control, craft_id: String, enabled: bool) -> void:
	if control == null or craft_id.strip_edges().is_empty():
		return
	control.set_script(HOMEBASE_FIRETEAM_DROP_TARGET_SCRIPT)
	if control.has_method("setup_drop_target"):
		control.call("setup_drop_target", craft_id, enabled)
	_connect_homebase_shipcard_fireteam_drop_target(control)


func _configure_existing_homebase_shipcard_fireteam_drop_target(control: Control, craft_id: String, enabled: bool) -> void:
	if control == null or craft_id.strip_edges().is_empty():
		return
	control.set_meta("homebase_fireteam_drop_target", true)
	control.set_meta("homebase_fireteam_drop_target_id", craft_id.strip_edges())
	control.set_meta("homebase_fireteam_drop_enabled", enabled)
	_connect_homebase_shipcard_fireteam_drop_target(control)


func _connect_homebase_shipcard_fireteam_drop_target(control: Control) -> void:
	if control == null:
		return
	var callback := Callable(self, "_on_homebase_shipcard_fireteam_dropped")
	if control.has_signal("fireteam_dropped") and not control.is_connected("fireteam_dropped", callback):
		control.connect("fireteam_dropped", callback)


func _configure_homebase_shipcard_wide_fireteam_drop_targets(root_node: Node, craft_id: String, enabled: bool) -> void:
	if root_node == null or craft_id.strip_edges().is_empty():
		return
	var should_descend := true
	var control := root_node as Control
	if control != null:
		var existing_script: Variant = control.get_script()
		if existing_script == null or existing_script == HOMEBASE_FIRETEAM_DROP_TARGET_SCRIPT:
			_configure_homebase_shipcard_fireteam_drop_target(control, craft_id, enabled)
		elif control.has_signal("fireteam_dropped"):
			_configure_existing_homebase_shipcard_fireteam_drop_target(control, craft_id, enabled)
			should_descend = false
		else:
			should_descend = false
	if not should_descend:
		return
	for child in root_node.get_children():
		_configure_homebase_shipcard_wide_fireteam_drop_targets(child, craft_id, enabled)


func _build_shipcard_direct_payload_panel(craft_id: String) -> Control:
	var payload_fireteam_ids: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft(craft_id)
	if payload_fireteam_ids.is_empty():
		return null
	var craft_gate: Dictionary = _build_homebase_direct_staging_craft_gate_for_craft(craft_id)
	var panel := PanelContainer.new()
	panel.name = "ShipcardDirectPayloadPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.set_meta("homebase_shipcard_payload_panel", true)
	panel.set_meta("craft_id", craft_id)
	panel.set_meta("payload_fireteam_ids", Array(payload_fireteam_ids))
	panel.set_meta("homebase_direct_payload_boarded", _are_homebase_payload_fireteams_boarded(payload_fireteam_ids))
	panel.set_meta("homebase_direct_boarded_operator_count", _get_homebase_direct_boarded_operator_count_for_craft(craft_id))
	panel.set_meta("homebase_direct_payload_operator_count", _build_unit_ids_for_fireteams(payload_fireteam_ids).size())
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "PayloadVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var header := Label.new()
	header.name = "PayloadHeaderLabel"
	header.text = "Flight Deck: %d/%d NPC | %d FT" % [
		_get_homebase_direct_boarded_operator_count_for_craft(craft_id),
		_build_unit_ids_for_fireteams(payload_fireteam_ids).size(),
		payload_fireteam_ids.size(),
	]
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.clip_text = true
	header.add_theme_font_size_override("font_size", 8)
	header.set_meta("homebase_shipcard_payload_header", true)
	header.set_meta("homebase_direct_boarded_operator_count", _get_homebase_direct_boarded_operator_count_for_craft(craft_id))
	header.set_meta("homebase_direct_payload_operator_count", _build_unit_ids_for_fireteams(payload_fireteam_ids).size())
	META_UI_SKIN_SCRIPT.style_body_label(header, 8)
	vbox.add_child(header)

	for fireteam_id in payload_fireteam_ids:
		var fireteam_card := _build_homebase_dropship_fireteam_card(String(fireteam_id), craft_id, "dropship_wait")
		if fireteam_card == null:
			continue
		var remove_button := Button.new()
		remove_button.name = "ShipcardPayloadRemove_%s" % fireteam_id
		remove_button.text = "x"
		remove_button.custom_minimum_size = Vector2(22.0, 18.0)
		remove_button.add_theme_font_size_override("font_size", 8)
		remove_button.set_meta("homebase_shipcard_payload_remove_button", true)
		remove_button.set_meta("craft_id", craft_id)
		remove_button.set_meta("fireteam_id", String(fireteam_id))
		META_UI_SKIN_SCRIPT.style_secondary_button(remove_button)
		remove_button.pressed.connect(_on_homebase_dropship_fireteam_remove_pressed.bind(String(fireteam_id), craft_id))
		var header_row := fireteam_card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
		if header_row != null:
			header_row.add_child(remove_button)
		else:
			fireteam_card.add_child(remove_button)
		vbox.add_child(fireteam_card)
	return panel


func _build_shipcard_progress_block(craft_id: String, cargo_loading: bool, craft_in_transit: bool) -> Control:
	var entry: Dictionary = _find_transfer_entry_for_craft(craft_id)
	var label_text: String = _build_shipcard_transfer_label(_get_aircraft_definition_by_id(craft_id))
	if entry.is_empty() and cargo_loading:
		entry = _find_cargo_load_entry_for_craft(craft_id)
		label_text = "Cargo loading"
	if entry.is_empty() or (not craft_in_transit and not cargo_loading):
		return null

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	vbox.set_meta("homebase_shipcard_progress_block", true)
	vbox.set_meta("craft_id", craft_id)
	vbox.set_meta("homebase_shipcard_progress_label", label_text)

	var label := Label.new()
	label.text = "%s | ETA %s" % [label_text, _build_transfer_eta_text(entry)]
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 8)
	META_UI_SKIN_SCRIPT.style_body_label(label, 8)
	vbox.add_child(label)

	var progress_bar := ProgressBar.new()
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = _build_transfer_progress_value(entry)
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.set_meta("homebase_shipcard_transfer_progress", true)
	progress_bar.set_meta("craft_id", craft_id)
	vbox.add_child(progress_bar)
	return vbox


func _build_shipcard_transfer_label(craft_def: Dictionary) -> String:
	var mission_phase: String = String(craft_def.get("mission_phase", "")).strip_edges().to_lower()
	if bool(craft_def.get("mission_transit_to_map", false)) or mission_phase == "to_mission":
		return "To Mission"
	if bool(craft_def.get("mission_transit_to_homebase", false)) or mission_phase == "to_homebase":
		return "Returning Homebase"
	if bool(craft_def.get("mission_transit_to_fob", false)) or mission_phase == "to_fob":
		return "Returning FOB"
	return "Inbound to FOB"


func _build_shipcard_pilot_panel(craft_id: String, craft_name: String, assigned_pilot_id: String, craft_busy: bool, craft_in_transit: bool = false) -> PanelContainer:
	var drop_panel := PanelContainer.new()
	drop_panel.name = "ShipcardPilotPanel"
	drop_panel.custom_minimum_size = Vector2(0.0, 52.0)
	drop_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	drop_panel.set_meta("homebase_shipcard_pilot_panel", true)
	drop_panel.set_meta("craft_id", craft_id.strip_edges())
	drop_panel.set_script(HOMEBASE_TEAM_DROP_PANEL_SCRIPT)
	if drop_panel.has_method("set_drop_enabled"):
		drop_panel.call("set_drop_enabled", not craft_busy and not craft_in_transit)
	if drop_panel.has_signal("unit_dropped"):
		drop_panel.unit_dropped.connect(_on_aircraft_pilot_drop_panel_unit_dropped.bind(craft_id))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	drop_panel.add_child(margin)

	var host := VBoxContainer.new()
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.add_theme_constant_override("separation", 2)
	margin.add_child(host)

	if assigned_pilot_id.is_empty():
		var label := Label.new()
		label.text = "Drop pilot into %s" % craft_name
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		host.add_child(label)
		return drop_panel

	host.add_child(_build_assigned_pilot_row(assigned_pilot_id, craft_name, craft_busy, craft_in_transit, craft_id))
	return drop_panel


func _build_assigned_pilot_row(unit_id: String, craft_name: String, craft_busy: bool = false, craft_in_transit: bool = false, craft_id: String = "") -> Control:
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return _build_empty_state_label("Pilot profile unavailable.")

	var secondary_text: String = "Inbound to FOB / %s" % craft_name if craft_in_transit else "Assigned to %s" % craft_name
	var card = NPC_COMPACT_CARD_SCENE.instantiate()
	card.setup_from_profile(
		profile,
		{
			"source_context": "aircraft_shipcard",
			"copy_profile": false,
			"secondary_text_override": secondary_text,
			"selected": unit_id == _focused_unit_id,
			"disabled": craft_in_transit,
			"drag_enabled": not craft_busy and not craft_in_transit,
			"compact_mode": true,
		}
	)
	if not card.card_pressed.is_connected(_on_compact_card_pressed):
		card.card_pressed.connect(_on_compact_card_pressed)
	if not card.card_open_requested.is_connected(_on_compact_card_open_requested):
		card.card_open_requested.connect(_on_compact_card_open_requested)
	card.set_meta("homebase_assigned_pilot_card", true)
	card.set_meta("unit_id", unit_id)
	card.set_meta("craft_id", craft_id.strip_edges())
	card.set_meta("homebase_shipcard_pilot_drag_source", not craft_busy and not craft_in_transit)
	if craft_in_transit:
		card.modulate = Color(1.0, 1.0, 1.0, 0.56)
	return card


func _build_empty_state_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	return label


func _build_shipcard_stylebox(is_selected: bool, craft_busy: bool, craft_in_transit: bool = false) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.14, 0.17, 0.72) if craft_in_transit else Color(0.12, 0.14, 0.17, 1.0)
	if is_selected:
		stylebox.border_color = Color(0.40, 0.92, 0.56, 1.0)
	elif craft_in_transit:
		stylebox.border_color = Color(0.56, 0.58, 0.62, 0.82)
	else:
		stylebox.border_color = Color(0.55, 0.46, 0.22, 1.0) if craft_busy else Color(0.31, 0.36, 0.42, 1.0)
	var border_width: int = 2 if is_selected else 1
	stylebox.border_width_left = border_width
	stylebox.border_width_top = border_width
	stylebox.border_width_right = border_width
	stylebox.border_width_bottom = border_width
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	return stylebox


func _build_shipcard_cargo_status_text(craft_def: Dictionary, craft_id: String) -> String:
	if not _craft_supports_cargo(craft_def):
		return ""
	var loaded_cargo_id: String = _get_loaded_cargo_id(craft_id)
	if not loaded_cargo_id.is_empty():
		return "Loaded: %s" % _build_cargo_display_name(craft_def, loaded_cargo_id)
	if _has_active_cargo_load_for_craft(craft_id):
		return "Loading: %s" % _build_cargo_display_name(craft_def, _get_selected_cargo_id(craft_id))
	var selected_cargo_id: String = _get_selected_cargo_id(craft_id)
	if not selected_cargo_id.is_empty():
		return "Selected: %s" % _build_cargo_display_name(craft_def, selected_cargo_id)
	return "Cargo: none"


func _build_transfer_progress_value(entry: Dictionary) -> float:
	var duration_seconds: float = max(float(entry.get("duration_seconds", 1.0)), 1.0)
	var elapsed_seconds: float = clamp(float(entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
	return (elapsed_seconds / duration_seconds) * 100.0


func _build_transfer_eta_text(entry: Dictionary) -> String:
	var duration_seconds: float = max(float(entry.get("duration_seconds", 1.0)), 1.0)
	var elapsed_seconds: float = clamp(float(entry.get("elapsed_seconds", 0.0)), 0.0, duration_seconds)
	var remaining_seconds: int = maxi(int(ceil(duration_seconds - elapsed_seconds)), 0)
	return "%ds" % remaining_seconds


func _get_visible_pilot_transfer_entries(craft_id: String) -> Array:
	return _aircraft_manager.get_visible_pilot_transfer_entries(craft_id)


func _get_selected_aircraft_definition() -> Dictionary:
	return _aircraft_manager.get_selected_aircraft_definition()


func _get_selected_aircraft_id() -> String:
	return _aircraft_manager.get_selected_aircraft_id()


func _set_selected_aircraft_id(craft_id: String) -> void:
	_aircraft_manager.set_selected_aircraft_id(craft_id)


func _get_selected_aircraft_base_type() -> String:
	var selector: OptionButton = get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AircraftSelector")
	if selector != null and selector.selected >= 0 and selector.selected < selector.item_count:
		var selected_type: String = String(selector.get_item_metadata(selector.selected)).strip_edges()
		if not selected_type.is_empty():
			return selected_type
	return "dropship"


func _get_aircraft_definition_by_id(craft_id: String) -> Dictionary:
	return _aircraft_manager.get_aircraft_definition_by_id(craft_id)


func _ensure_selected_aircraft_id() -> void:
	_aircraft_manager.ensure_selected_aircraft_id()


func _can_remove_selected_aircraft() -> bool:
	return _aircraft_manager.can_remove_selected_aircraft()


func _can_remove_aircraft(craft_id: String) -> bool:
	return _aircraft_manager.can_remove_aircraft(craft_id)


func _populate_aircraft_selector(selector: OptionButton) -> void:
	if selector == null:
		return
	_configure_flightdeck_option_button(selector)
	var selected_type: String = "dropship"
	if selector.item_count > 0 and selector.selected >= 0 and selector.selected < selector.item_count:
		selected_type = String(selector.get_item_metadata(selector.selected)).strip_edges()
	selector.clear()
	var selected_index: int = -1
	for craft_option_variant in _build_default_aircraft_definitions():
		var craft_option: Dictionary = Dictionary(craft_option_variant)
		var craft_type: String = String(craft_option.get("craft_type", "dropship")).strip_edges()
		selector.add_item(String(craft_option.get("display_name", craft_type)).strip_edges())
		selector.set_item_metadata(selector.item_count - 1, craft_type)
		if craft_type == selected_type:
			selected_index = selector.item_count - 1
	if selected_index < 0 and selector.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		selector.select(selected_index)


func _get_assigned_pilot_id(craft_id: String) -> String:
	return _aircraft_manager.get_assigned_pilot_id(craft_id)


func _get_selected_cargo_id(craft_id: String) -> String:
	return _aircraft_manager.get_selected_cargo_id(craft_id)


func _get_loaded_cargo_id(craft_id: String) -> String:
	return _aircraft_manager.get_loaded_cargo_id(craft_id)


func _build_craft_display_name(craft_id: String) -> String:
	return _aircraft_manager.build_craft_display_name(craft_id)


func _get_aircraft_texture(craft_def: Dictionary) -> Texture2D:
	var direct_texture = craft_def.get("texture", null)
	if direct_texture is Texture2D:
		return direct_texture as Texture2D
	var texture_path: String = String(craft_def.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return null
	var resource: Resource = load(texture_path)
	return resource as Texture2D


func _craft_supports_cargo(craft_def: Dictionary) -> bool:
	return _aircraft_manager.craft_supports_cargo(craft_def)


func _get_cargo_options_for_craft(craft_def: Dictionary) -> Array:
	return _aircraft_manager.get_cargo_options_for_craft(craft_def)


func _build_cargo_display_name(craft_def: Dictionary, cargo_id: String) -> String:
	return _aircraft_manager.build_cargo_display_name(craft_def, cargo_id)


func _is_unit_assigned_to_aircraft(unit_id: String) -> bool:
	return _aircraft_manager.is_unit_assigned_to_aircraft(unit_id)


func _find_assigned_craft_for_unit(unit_id: String) -> String:
	return _aircraft_manager.find_assigned_craft_for_unit(unit_id)


func _get_visible_homebase_aircraft_definitions() -> Array:
	return _aircraft_manager.get_visible_homebase_aircraft_definitions()


func _get_aircraft_location(craft_id: String) -> String:
	return _aircraft_manager.get_aircraft_location(craft_id)


func _is_craft_visible_in_homebase(craft_id: String) -> bool:
	return _aircraft_manager.is_craft_visible_in_homebase(craft_id)


func _is_craft_in_transit(craft_id: String) -> bool:
	return _aircraft_manager.is_craft_in_transit(craft_id)


func _has_active_pilot_transfer_for_craft(craft_id: String) -> bool:
	return _aircraft_manager.has_active_pilot_transfer_for_craft(craft_id)


func _has_active_cargo_load_for_craft(craft_id: String) -> bool:
	return _aircraft_manager.has_active_cargo_load_for_craft(craft_id)


func _get_visible_cargo_load_entries(craft_id: String) -> Array:
	return _aircraft_manager.get_visible_cargo_load_entries(craft_id)


func _find_cargo_load_entry_for_craft(craft_id: String) -> Dictionary:
	return _aircraft_manager.find_cargo_load_entry_for_craft(craft_id)


func _can_load_selected_cargo(craft_def: Dictionary, craft_id: String) -> bool:
	return _aircraft_manager.can_load_selected_cargo(craft_def, craft_id)


func _can_send_craft(craft_def: Dictionary, craft_id: String) -> bool:
	return _aircraft_manager.can_send_craft(craft_def, craft_id)


func _can_dispatch_shipcard(craft_def: Dictionary, craft_id: String, assigned_pilot_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or assigned_pilot_id.strip_edges().is_empty():
		return false
	if not _can_send_craft(craft_def, normalized_craft_id):
		return false
	if _get_homebase_dispatch_target(normalized_craft_id) == HOMEBASE_DISPATCH_TARGET_MISSION:
		return _has_homebase_direct_launch_payload_for_craft(normalized_craft_id)
	return true


func _get_homebase_dispatch_target(craft_id: String) -> String:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return HOMEBASE_DISPATCH_TARGET_FOB
	var stored_target: String = String(_homebase_dispatch_target_by_craft.get(normalized_craft_id, "")).strip_edges().to_lower()
	if stored_target == HOMEBASE_DISPATCH_TARGET_MISSION or stored_target == HOMEBASE_DISPATCH_TARGET_FOB:
		return stored_target
	if not _get_homebase_direct_payload_fireteam_ids_for_craft(normalized_craft_id).is_empty():
		return HOMEBASE_DISPATCH_TARGET_MISSION
	return HOMEBASE_DISPATCH_TARGET_FOB


func _find_transfer_entry_for_unit(unit_id: String) -> Dictionary:
	for entry_variant in _team_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_ids: Array = Array(entry.get("unit_ids", []))
		for entry_unit_id_variant in unit_ids:
			if String(entry_unit_id_variant).strip_edges() == unit_id:
				return entry
	return _aircraft_manager.find_pilot_transfer_entry_for_unit(unit_id)


func _find_transfer_entry_for_craft(craft_id: String) -> Dictionary:
	return _aircraft_manager.find_transfer_entry_for_craft(craft_id)


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


func _is_roster_card_highlighted(unit_id: String) -> bool:
	return unit_id == _focused_unit_id or _selected_unit_ids.has(unit_id)


func _build_display_name(unit_id: String) -> String:
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return unit_id

	return String(profile.display_name)


func _build_optional_text(value: String, fallback: String) -> String:
	if value.strip_edges().is_empty():
		return fallback

	return value


func _get_team_capacity() -> int:
	return maxi(_selected_mission_slot_count, 1)


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null

	var resource: Resource = load(portrait_path)
	return resource as Texture2D


func _get_team_drop_panel():
	return get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel")


func _get_roster_drop_panel():
	return get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel")


func _node_is_visible(path: String) -> bool:
	var control := get_node_or_null(path) as Control
	return control != null and control.visible and (control.is_visible_in_tree() if control.is_inside_tree() else true)


func _clear_container(container: Node) -> void:
	if container == null:
		return

	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
