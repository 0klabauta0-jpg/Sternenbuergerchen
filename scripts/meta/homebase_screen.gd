class_name HomebaseTestScreen
extends Control

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const FRONTIER_SHIP_VISUALS_SCRIPT: GDScript = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const OPERATIONS_PRESENTER_SCRIPT: GDScript = preload("res://scripts/meta/homebase_operations_presenter.gd")
const PORTRAIT_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")

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
const PRE_MISSION_READINESS_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/pre_mission_readiness_presenter.gd")
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
const HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID := "task_645_homebase_followup_panel_v1"
const HOMEBASE_POST_DEBRIEF_DENSITY_FINDINGS_STYLE_ID := "task_647_homebase_density_findings_v1"
const HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID := "task_755_station_homebase_return_panel_v1"
const HOMEBASE_REENTRY_PLAN_STYLE_ID := "task_762_station_reentry_plan_v1"
const HOMEBASE_REENTRY_PLAN_LINE := "Reentry-Plan: Fireteam -> Loadout -> Dropship -> Start -> Preview vor GO"
const HOMEBASE_REENTRY_FIRETEAM_STAGING_STYLE_ID := "task_763_station_reentry_fireteam_staging_v1"
const HOMEBASE_REENTRY_LOADOUT_BRIDGE_STYLE_ID := "task_764_station_reentry_loadout_bridge_v1"
const HOMEBASE_REENTRY_DROPSHIP_BOARDING_STYLE_ID := "task_765_station_reentry_dropship_boarding_v1"
const HOMEBASE_REENTRY_START_PERMISSION_STYLE_ID := "task_766_station_reentry_start_permission_v1"
const HOMEBASE_RELEASE_CTA_EMPHASIS_STYLE_ID := "task_821_release_first_homebase_cta_v1"
const HOMEBASE_RELEASE_CTA_FONT_SIZE := 10
const HOMEBASE_RELEASE_CTA_MIN_HEIGHT := 88.0
const HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE := 12
const HOMEBASE_POST_DEBRIEF_FOLLOWUP_MIN_HEIGHT := 198.0
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
var _selected_briefing_loadout_recommendation_id: String = ""
var _selected_briefing_loadout_recommendation: Dictionary = {}
var _briefing_loadout_apply_count: int = 0
var _briefing_loadout_feedback_text: String = ""
var _roster_sort_mode: String = HOMEBASE_ROSTER_SORT_NAME_ASC
var _profiles_by_id: Dictionary = {}
var _focused_unit_id: String = ""
var _roster_cards_by_unit_id: Dictionary = {}
var _staged_cards_by_unit_id: Dictionary = {}
var _roster_card_pool = HOMEBASE_CARD_POOL_SCRIPT.new()
var _staged_card_pool = HOMEBASE_CARD_POOL_SCRIPT.new()
var _team_feedback_text: String = ""
var _character_sheet_open: bool = false
var _r2_briefing_details_open: bool = false
var _r3_geometry_signature: String = ""
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
var _mission_briefing_source_signature: String = ""
var _mission_briefing_rendered_panel: WeakRef
var _pre_mission_readiness_presenter = PRE_MISSION_READINESS_PRESENTER_SCRIPT.new()
var _pre_mission_readiness_snapshot: Dictionary = {}
var _aircraft_manager = AIRCRAFT_MANAGER_SCRIPT.new()
var _team_transfer_entries: Array = []
var _personnel_events: Array = []
var _last_mission_result_summary: Dictionary = {}
var _post_mission_skill_delta_summary: Dictionary = {}
var _post_mission_skill_delta_by_unit_id: Dictionary = {}
var _operations_mode: String = "squad"
var _operations_presenter: Control
var _operations_return_button: Button


func _ready() -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(self)
	set_meta("native_ui_screen_family", "homebase")
	if not get_viewport().size_changed.is_connected(_on_r3_viewport_changed):
		get_viewport().size_changed.connect(_on_r3_viewport_changed)
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
	_ensure_operations_presenter()
	_sync_operations_visibility()


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
	_fireteam_definitions = _merge_fireteam_definitions(_fireteam_definitions, fireteam_definitions)
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
		_restore_r3_briefing_source_visibility()
		_update_personnel_notifications()
		_apply_r2_briefing_visibility(true)


func set_last_mission_result_summary(mission_result: Dictionary) -> void:
	_last_mission_result_summary = mission_result.duplicate(true)
	if is_inside_tree():
		_restore_r3_briefing_source_visibility()
		_update_post_debrief_homebase_summary()
		_update_next_sortie_readiness_summary()
		_apply_r2_briefing_visibility(true)


func set_post_mission_skill_delta_summary(summary: Dictionary) -> void:
	_post_mission_skill_delta_summary = summary.duplicate(true)
	_rebuild_post_mission_skill_delta_lookup()
	if is_inside_tree() and _character_sheet_open:
		_update_character_sheet()


func get_frontier_probe_post_debrief_homebase_readability_snapshot() -> Dictionary:
	var label := _get_post_debrief_homebase_summary_label()
	var label_visible: bool = _control_is_visible(label)
	var label_text: String = label.text.strip_edges() if label != null else ""
	var route_id: String = _get_last_result_route_id()
	var scenario_id: String = _get_last_result_scenario_id()
	var is_frontier_probe: bool = _is_frontier_probe_last_result()
	var result_text: String = _build_post_debrief_homebase_result_text()
	var next_step_text: String = _build_post_debrief_homebase_next_step_text()
	var checks: Array = []
	_append_visual_audit_check(checks, "frontier_probe_result_present", is_frontier_probe, "critical", "Homebase return summary should carry the Frontier Probe result.")
	_append_visual_audit_check(checks, "summary_label_visible", label_visible, "critical", "Homebase should show a compact post-Debrief summary.")
	_append_visual_audit_check(checks, "summary_mentions_debrief", label_text.contains("Debrief"), "critical", "Summary should explain that the Debrief was reviewed.")
	_append_visual_audit_check(checks, "summary_mentions_homebase", label_text.contains("Homebase"), "critical", "Summary should make the return target clear.")
	_append_visual_audit_check(checks, "summary_mentions_next_step", not next_step_text.is_empty() and label_text.contains(next_step_text), "critical", "Summary should name the next useful Homebase action.")
	_append_visual_audit_check(checks, "summary_compact", label_text.length() <= 180 and label_text.count("\n") == 0, "critical", "Summary should stay compact in the MissionPanel.")
	_append_visual_audit_check(checks, "result_preserved", not result_text.is_empty(), "critical", "Mission result should remain readable after return.")
	_append_visual_audit_check(checks, "read_only", true, "critical", "Snapshot reads Homebase result display only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.frontier_probe_post_debrief_homebase_readability.v1",
		"task_id": "TASK_640",
		"source_task_ids": ["TASK_639", "TASK_594"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"route_id": route_id,
		"scenario_id": scenario_id,
		"frontier_probe_result_present": is_frontier_probe,
		"summary_label_visible": label_visible,
		"summary_text": label_text,
		"result_text": result_text,
		"next_step_text": next_step_text,
		"mission_result_preserved": not _last_mission_result_summary.is_empty(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"checks": checks,
		"recommended_next_task": "TASK_641 - Frontier Probe Homebase Next Sortie Readiness",
	}


func get_station_scenario_post_debrief_homebase_readability_snapshot() -> Dictionary:
	var label := _get_post_debrief_homebase_summary_label()
	var label_visible: bool = _control_is_visible(label)
	var label_text: String = label.text.strip_edges() if label != null else ""
	var route_id: String = _get_last_result_route_id()
	var scenario_id: String = _get_last_result_scenario_id()
	var is_station_result: bool = _is_station_scenario_last_result()
	var result_text: String = _build_post_debrief_homebase_result_text()
	var next_step_text: String = _build_post_debrief_homebase_next_step_text()
	var checks: Array = []
	_append_visual_audit_check(checks, "station_result_present", is_station_result, "critical", "Homebase return summary should carry the Station Scenario result.")
	_append_visual_audit_check(checks, "summary_label_visible", label_visible, "critical", "Homebase should show a compact Station post-Debrief summary.")
	_append_visual_audit_check(checks, "summary_mentions_debrief", label_text.contains("Debrief"), "critical", "Summary should explain that the Debrief was reviewed.")
	_append_visual_audit_check(checks, "summary_mentions_homebase", label_text.contains("Homebase"), "critical", "Summary should make the return target clear.")
	_append_visual_audit_check(checks, "summary_mentions_station", label_text.contains("Station Drill"), "critical", "Summary should name the Station Drill result.")
	_append_visual_audit_check(checks, "summary_mentions_next_step", not next_step_text.is_empty() and label_text.contains(next_step_text), "critical", "Summary should name the next useful Homebase action.")
	_append_visual_audit_check(checks, "summary_compact", label_text.length() <= 180 and label_text.count("\n") == 0, "critical", "Summary should stay compact in the MissionPanel.")
	_append_visual_audit_check(checks, "result_preserved", not result_text.is_empty(), "critical", "Mission result should remain readable after Station return.")
	_append_visual_audit_check(checks, "read_only", true, "critical", "Snapshot reads Homebase result display only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_scenario_post_debrief_homebase_readability.v1",
		"task_id": "TASK_745",
		"source_task_ids": ["TASK_744", "TASK_640"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"route_id": route_id,
		"scenario_id": scenario_id,
		"station_result_present": is_station_result,
		"summary_label_visible": label_visible,
		"summary_text": label_text,
		"result_text": result_text,
		"next_step_text": next_step_text,
		"mission_result_preserved": not _last_mission_result_summary.is_empty(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"checks": checks,
		"recommended_next_task": "TASK_746 - Station Scenario Homebase Next Sortie Readiness",
	}


func get_station_scenario_homebase_next_sortie_readiness_snapshot() -> Dictionary:
	var post_snapshot: Dictionary = get_station_scenario_post_debrief_homebase_readability_snapshot()
	var readiness: Dictionary = get_pre_mission_readiness_snapshot()
	var staging: Dictionary = get_homebase_direct_staging_snapshot()
	var label := _get_next_sortie_readiness_label()
	var label_visible: bool = _control_is_visible(label)
	var label_text: String = label.text.strip_edges() if label != null else ""
	var steps: Array = _build_next_sortie_readiness_steps(readiness, staging)
	var current_step_id: String = _resolve_next_sortie_current_step_id(readiness, staging)
	var readiness_line: String = _build_next_sortie_readiness_line(steps, current_step_id, true)
	var post_gate: String = String(post_snapshot.get("gate", "")).strip_edges()
	var checks: Array = []
	_append_visual_audit_check(checks, "station_result_present", bool(post_snapshot.get("station_result_present", false)), "critical", "Next-sortie readiness should only appear for a carried Station Scenario result.")
	_append_visual_audit_check(checks, "post_debrief_summary_gate", post_gate == "pass", "critical", "Readiness should build on the green Station post-Debrief Homebase summary.")
	_append_visual_audit_check(checks, "readiness_label_visible", label_visible, "critical", "Homebase should show a compact station next-sortie readiness line.")
	_append_visual_audit_check(checks, "readiness_line_matches_label", not readiness_line.is_empty() and label_text == readiness_line, "critical", "Rendered station readiness line should match the snapshot.")
	_append_visual_audit_check(checks, "current_next_step_present", _next_sortie_steps_contain(steps, current_step_id), "critical", "Station readiness should point to one concrete current next step.")
	_append_visual_audit_check(checks, "readiness_steps_complete", _next_sortie_steps_contain(steps, "review_roster_gains") and _next_sortie_steps_contain(steps, "stage_fireteam") and _next_sortie_steps_contain(steps, "assign_loadout") and _next_sortie_steps_contain(steps, "prepare_transport") and _next_sortie_steps_contain(steps, "start_next_sortie"), "critical", "Station readiness should cover roster review, staging, loadout, transport and launch.")
	_append_visual_audit_check(checks, "review_gains_non_blocking", not _has_last_result_progression_awards() or current_step_id != "review_roster_gains", "critical", "Roster gains should remain visible without hiding the next actionable station sortie step.")
	_append_visual_audit_check(checks, "read_only", true, "critical", "Snapshot reads existing Homebase state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_scenario_homebase_next_sortie_readiness.v1",
		"task_id": "TASK_746",
		"source_task_ids": ["TASK_745", "TASK_534", "TASK_594"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"route_id": String(post_snapshot.get("route_id", "")),
		"scenario_id": String(post_snapshot.get("scenario_id", "")),
		"station_result_present": bool(post_snapshot.get("station_result_present", false)),
		"post_debrief_summary_gate": post_gate,
		"post_debrief_summary_text": String(post_snapshot.get("summary_text", "")),
		"readiness_label_visible": label_visible,
		"readiness_line": readiness_line,
		"rendered_readiness_line": label_text,
		"current_next_step_id": current_step_id,
		"readiness_steps": steps,
		"review_gains_non_blocking": not _has_last_result_progression_awards() or current_step_id != "review_roster_gains",
		"pre_mission_readiness_state": String(readiness.get("overall_state", "")).strip_edges(),
		"pre_mission_readiness_summary": String(readiness.get("summary_text", "")).strip_edges(),
		"can_request_mission_start": can_request_mission_start(),
		"payload_fireteam_count": Array(staging.get("payload_fireteam_ids", [])).size(),
		"payload_operator_count": int(staging.get("payload_operator_count", 0)),
		"boarding_progress_ratio": float(staging.get("boarding_progress_ratio", 0.0)),
		"mission_result_preserved": not _last_mission_result_summary.is_empty(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"checks": checks,
		"recommended_next_task": "TASK_747 - Station Scenario Homebase Visible Readiness Review",
	}


func get_frontier_probe_homebase_next_sortie_readiness_snapshot() -> Dictionary:
	var post_snapshot: Dictionary = get_frontier_probe_post_debrief_homebase_readability_snapshot()
	var readiness: Dictionary = get_pre_mission_readiness_snapshot()
	var staging: Dictionary = get_homebase_direct_staging_snapshot()
	var label := _get_next_sortie_readiness_label()
	var label_visible: bool = _control_is_visible(label)
	var label_text: String = label.text.strip_edges() if label != null else ""
	var steps: Array = _build_next_sortie_readiness_steps(readiness, staging)
	var current_step_id: String = _resolve_next_sortie_current_step_id(readiness, staging)
	var readiness_line: String = _build_next_sortie_readiness_line(steps, current_step_id)
	var post_gate: String = String(post_snapshot.get("gate", "")).strip_edges()
	var checks: Array = []
	_append_visual_audit_check(checks, "frontier_probe_result_present", bool(post_snapshot.get("frontier_probe_result_present", false)), "critical", "Next-sortie readiness should only appear for a carried Frontier Probe result.")
	_append_visual_audit_check(checks, "post_debrief_summary_gate", post_gate == "pass", "critical", "Readiness should build on the green post-Debrief Homebase summary.")
	_append_visual_audit_check(checks, "readiness_label_visible", label_visible, "critical", "Homebase should show a compact next-sortie readiness line.")
	_append_visual_audit_check(checks, "readiness_line_matches_label", not readiness_line.is_empty() and label_text == readiness_line, "critical", "Rendered readiness line should match the snapshot.")
	_append_visual_audit_check(checks, "current_next_step_present", _next_sortie_steps_contain(steps, current_step_id), "critical", "Readiness should point to one concrete current next step.")
	_append_visual_audit_check(checks, "readiness_steps_complete", _next_sortie_steps_contain(steps, "review_roster_gains") and _next_sortie_steps_contain(steps, "stage_fireteam") and _next_sortie_steps_contain(steps, "assign_loadout") and _next_sortie_steps_contain(steps, "prepare_transport") and _next_sortie_steps_contain(steps, "start_next_sortie"), "critical", "Readiness should cover roster review, staging, loadout, transport and launch.")
	_append_visual_audit_check(checks, "review_gains_non_blocking", not _has_last_result_progression_awards() or current_step_id != "review_roster_gains", "critical", "Roster gains should remain visible without hiding the next actionable sortie step.")
	_append_visual_audit_check(checks, "read_only", true, "critical", "Snapshot reads existing Homebase state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.frontier_probe_homebase_next_sortie_readiness.v1",
		"task_id": "TASK_641",
		"source_task_ids": ["TASK_640", "TASK_534", "TASK_594"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"route_id": String(post_snapshot.get("route_id", "")),
		"scenario_id": String(post_snapshot.get("scenario_id", "")),
		"frontier_probe_result_present": bool(post_snapshot.get("frontier_probe_result_present", false)),
		"post_debrief_summary_gate": post_gate,
		"post_debrief_summary_text": String(post_snapshot.get("summary_text", "")),
		"readiness_label_visible": label_visible,
		"readiness_line": readiness_line,
		"rendered_readiness_line": label_text,
		"current_next_step_id": current_step_id,
		"readiness_steps": steps,
		"review_gains_non_blocking": not _has_last_result_progression_awards() or current_step_id != "review_roster_gains",
		"pre_mission_readiness_state": String(readiness.get("overall_state", "")).strip_edges(),
		"pre_mission_readiness_summary": String(readiness.get("summary_text", "")).strip_edges(),
		"can_request_mission_start": can_request_mission_start(),
		"payload_fireteam_count": Array(staging.get("payload_fireteam_ids", [])).size(),
		"payload_operator_count": int(staging.get("payload_operator_count", 0)),
		"boarding_progress_ratio": float(staging.get("boarding_progress_ratio", 0.0)),
		"mission_result_preserved": not _last_mission_result_summary.is_empty(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"checks": checks,
		"recommended_next_task": "TASK_642 - Frontier Probe Homebase Visible Readiness Review",
	}


func get_station_scenario_homebase_visible_readiness_review_snapshot() -> Dictionary:
	var readiness_snapshot: Dictionary = get_station_scenario_homebase_next_sortie_readiness_snapshot()
	var post_label := _get_post_debrief_homebase_summary_label()
	var readiness_label := _get_next_sortie_readiness_label()
	var followup_panel := _get_post_debrief_followup_panel()
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as Control
	var mission_vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as Control
	var post_rect: Rect2 = _control_global_rect(post_label)
	var readiness_rect: Rect2 = _control_global_rect(readiness_label)
	var followup_rect: Rect2 = _control_global_rect(followup_panel)
	var mission_rect: Rect2 = _control_global_rect(mission_panel)
	var mission_child_max_bottom: float = _visible_child_max_bottom(mission_panel)
	var readiness_line: String = String(readiness_snapshot.get("readiness_line", "")).strip_edges()
	var rendered_line: String = readiness_label.text.strip_edges() if readiness_label != null else ""
	var summary_font_size: int = post_label.get_theme_font_size("font_size") if post_label != null else 0
	var readiness_font_size: int = readiness_label.get_theme_font_size("font_size") if readiness_label != null else 0
	var followup_style_id: String = String(followup_panel.get_meta("homebase_followup_style_id", "")) if followup_panel != null else ""
	var checks: Array = []
	_append_visual_audit_check(checks, "readiness_gate_pass", String(readiness_snapshot.get("gate", "")) == "pass", "critical", "TASK_746 readiness gate should be green before visible review.")
	_append_visual_audit_check(checks, "post_summary_visible", _control_is_visible(post_label), "critical", "Station post-Debrief Homebase summary should remain visible.")
	_append_visual_audit_check(checks, "next_sortie_visible", _control_is_visible(readiness_label), "critical", "Station next-sortie readiness line should be visible.")
	_append_visual_audit_check(checks, "line_matches_snapshot", not readiness_line.is_empty() and rendered_line == readiness_line, "critical", "Rendered station readiness line should match TASK_746 snapshot text.")
	_append_visual_audit_check(checks, "labels_inside_mission_panel", _rect_inside(post_rect, mission_rect) and _rect_inside(readiness_rect, mission_rect), "critical", "Station summary and Next-Sortie lines should stay inside MissionPanel.")
	_append_visual_audit_check(checks, "followup_panel_visible", _control_is_visible(followup_panel), "critical", "Station post-Debrief follow-up panel should be visible.")
	_append_visual_audit_check(checks, "followup_panel_inside_mission_panel", _rect_inside(followup_rect, mission_rect), "critical", "Station follow-up panel should stay inside MissionPanel.")
	_append_visual_audit_check(checks, "labels_inside_followup_panel", _rect_inside(post_rect, followup_rect) and _rect_inside(readiness_rect, followup_rect), "critical", "Station summary and next-sortie labels should be grouped inside the follow-up panel.")
	_append_visual_audit_check(checks, "followup_panel_emphasis_style", followup_style_id == HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID, "critical", "Station follow-up panel should expose the Homebase follow-up emphasis style.")
	_append_visual_audit_check(checks, "followup_label_emphasis", summary_font_size >= HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE and readiness_font_size >= HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE, "critical", "Station follow-up labels should be visibly larger than the old compact labels.")
	_append_visual_audit_check(checks, "next_sortie_below_post_summary", readiness_rect.position.y >= post_rect.end.y - 1.0, "critical", "Station Next-Sortie line should sit below the Debrief return summary.")
	_append_visual_audit_check(checks, "labels_do_not_overlap", not _rects_overlap(post_rect, readiness_rect) or readiness_rect.position.y >= post_rect.end.y - 1.0, "critical", "Station return and next-sortie lines should not visually overlap.")
	_append_visual_audit_check(checks, "mission_panel_no_overflow", mission_panel != null and mission_child_max_bottom <= mission_rect.end.y + 0.5, "critical", "MissionPanel content should not overflow after adding Station readiness lines.")
	_append_visual_audit_check(checks, "readiness_line_compact", rendered_line.length() <= 190 and rendered_line.count("\n") == 0, "critical", "Station next-sortie line should remain compact enough for the Homebase mission panel.")
	_append_visual_audit_check(checks, "mission_vbox_visible", _control_is_visible(mission_vbox), "critical", "MissionVBox should be visible for the Station review capture.")
	_append_visual_audit_check(checks, "read_only", bool(readiness_snapshot.get("read_only", false)) and not bool(readiness_snapshot.get("ui_sets_gameplay_truth", true)), "critical", "Station visible review should read existing Homebase state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_scenario_homebase_visible_readiness_review.v1",
		"task_id": "TASK_747",
		"source_task_ids": ["TASK_746", "TASK_745"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"readiness_gate": String(readiness_snapshot.get("gate", "")),
		"route_id": String(readiness_snapshot.get("route_id", "")),
		"scenario_id": String(readiness_snapshot.get("scenario_id", "")),
		"current_next_step_id": String(readiness_snapshot.get("current_next_step_id", "")),
		"readiness_line": readiness_line,
		"rendered_readiness_line": rendered_line,
		"post_summary_text": post_label.text.strip_edges() if post_label != null else "",
		"post_summary_visible": _control_is_visible(post_label),
		"next_sortie_visible": _control_is_visible(readiness_label),
		"followup_panel_visible": _control_is_visible(followup_panel),
		"followup_panel_style_id": followup_style_id,
		"followup_panel_min_height": followup_panel.custom_minimum_size.y if followup_panel != null else 0.0,
		"post_summary_font_size": summary_font_size,
		"next_sortie_font_size": readiness_font_size,
		"post_summary_emphasis": bool(post_label.get_meta("homebase_followup_emphasis", false)) if post_label != null else false,
		"next_sortie_emphasis": bool(readiness_label.get_meta("homebase_followup_emphasis", false)) if readiness_label != null else false,
		"mission_panel_visible": _control_is_visible(mission_panel),
		"mission_vbox_visible": _control_is_visible(mission_vbox),
		"post_summary_rect": _rect_to_dict(post_rect),
		"next_sortie_rect": _rect_to_dict(readiness_rect),
		"followup_panel_rect": _rect_to_dict(followup_rect),
		"mission_panel_rect": _rect_to_dict(mission_rect),
		"mission_child_max_bottom": mission_child_max_bottom,
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"visual_only": true,
		"checks": checks,
		"recommended_next_task": "TASK_748 - Station Scenario Homebase Readiness Visual Polish Findings",
	}


func get_station_homebase_return_panel_polish_snapshot() -> Dictionary:
	var visible_snapshot: Dictionary = get_station_scenario_homebase_visible_readiness_review_snapshot()
	var readiness_snapshot: Dictionary = get_station_scenario_homebase_next_sortie_readiness_snapshot()
	var pre_mission_readiness_snapshot: Dictionary = get_pre_mission_readiness_snapshot()
	var followup_panel := _get_post_debrief_followup_panel()
	var title_label := _get_post_debrief_followup_title_label()
	var action_label := _get_post_debrief_followup_action_label()
	var chip_row := _get_post_debrief_followup_step_chip_row()
	var reentry_label := _get_station_reentry_plan_label()
	var reentry_staging_label := _get_station_reentry_fireteam_staging_label()
	var reentry_loadout_label := _get_station_reentry_loadout_bridge_label()
	var reentry_boarding_label := _get_station_reentry_dropship_boarding_label()
	var reentry_start_label := _get_station_reentry_start_permission_label()
	var post_label := _get_post_debrief_homebase_summary_label()
	var readiness_label := _get_next_sortie_readiness_label()
	var start_button := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as Control
	var panel_rect: Rect2 = _control_global_rect(followup_panel)
	var title_rect: Rect2 = _control_global_rect(title_label)
	var action_rect: Rect2 = _control_global_rect(action_label)
	var chip_row_rect: Rect2 = _control_global_rect(chip_row)
	var reentry_rect: Rect2 = _control_global_rect(reentry_label)
	var reentry_staging_rect: Rect2 = _control_global_rect(reentry_staging_label)
	var reentry_loadout_rect: Rect2 = _control_global_rect(reentry_loadout_label)
	var reentry_boarding_rect: Rect2 = _control_global_rect(reentry_boarding_label)
	var reentry_start_rect: Rect2 = _control_global_rect(reentry_start_label)
	var post_rect: Rect2 = _control_global_rect(post_label)
	var readiness_rect: Rect2 = _control_global_rect(readiness_label)
	var mission_rect: Rect2 = _control_global_rect(mission_panel)
	var staging_snapshot: Dictionary = get_homebase_direct_staging_snapshot()
	var loadout_readiness_item: Dictionary = _find_readiness_item(Array(pre_mission_readiness_snapshot.get("items", [])), "loadout")
	var dropship_readiness_item: Dictionary = _find_readiness_item(Array(pre_mission_readiness_snapshot.get("items", [])), "dropship")
	var boarding_readiness_item: Dictionary = _find_readiness_item(Array(pre_mission_readiness_snapshot.get("items", [])), "boarding")
	var start_readiness_item: Dictionary = _find_readiness_item(Array(pre_mission_readiness_snapshot.get("items", [])), "start")
	var steps: Array = Array(readiness_snapshot.get("readiness_steps", [])).duplicate(true)
	var chips: Array = _build_station_return_panel_step_chip_snapshot(steps)
	var title_text: String = title_label.text.strip_edges() if title_label != null else ""
	var action_text: String = action_label.text.strip_edges() if action_label != null else ""
	var reentry_text: String = reentry_label.text.strip_edges() if reentry_label != null else ""
	var reentry_style_id: String = String(reentry_label.get_meta("station_reentry_plan_style_id", "")) if reentry_label != null else ""
	var reentry_staging_text: String = reentry_staging_label.text.strip_edges() if reentry_staging_label != null else ""
	var reentry_staging_expected_text: String = _build_station_reentry_fireteam_staging_line(staging_snapshot)
	var reentry_staging_style_id: String = String(reentry_staging_label.get_meta("station_reentry_fireteam_staging_style_id", "")) if reentry_staging_label != null else ""
	var reentry_loadout_text: String = reentry_loadout_label.text.strip_edges() if reentry_loadout_label != null else ""
	var reentry_loadout_expected_text: String = _build_station_reentry_loadout_bridge_line(loadout_readiness_item)
	var reentry_loadout_style_id: String = String(reentry_loadout_label.get_meta("station_reentry_loadout_bridge_style_id", "")) if reentry_loadout_label != null else ""
	var reentry_loadout_state: String = String(loadout_readiness_item.get("state", "")).strip_edges()
	var reentry_loadout_detail: String = String(loadout_readiness_item.get("detail", "")).strip_edges()
	var reentry_boarding_text: String = reentry_boarding_label.text.strip_edges() if reentry_boarding_label != null else ""
	var reentry_boarding_expected_text: String = _build_station_reentry_dropship_boarding_line(dropship_readiness_item, boarding_readiness_item, staging_snapshot)
	var reentry_boarding_style_id: String = String(reentry_boarding_label.get_meta("station_reentry_dropship_boarding_style_id", "")) if reentry_boarding_label != null else ""
	var reentry_dropship_state: String = String(dropship_readiness_item.get("state", "")).strip_edges()
	var reentry_boarding_state: String = String(boarding_readiness_item.get("state", "")).strip_edges()
	var reentry_dropship_detail: String = String(dropship_readiness_item.get("detail", "")).strip_edges()
	var reentry_boarding_detail: String = String(boarding_readiness_item.get("detail", "")).strip_edges()
	var reentry_start_text: String = reentry_start_label.text.strip_edges() if reentry_start_label != null else ""
	var reentry_start_expected_text: String = _build_station_reentry_start_permission_line(start_readiness_item, pre_mission_readiness_snapshot)
	var reentry_start_style_id: String = String(reentry_start_label.get_meta("station_reentry_start_permission_style_id", "")) if reentry_start_label != null else ""
	var reentry_start_state: String = String(start_readiness_item.get("state", "")).strip_edges()
	var reentry_start_detail: String = String(start_readiness_item.get("detail", "")).strip_edges()
	var reentry_can_start: bool = bool(pre_mission_readiness_snapshot.get("can_start", false))
	var reentry_start_button_text: String = start_button.text.strip_edges() if start_button != null else ""
	var reentry_start_button_disabled: bool = start_button.disabled if start_button != null else true
	var reentry_selected_fireteam_count: int = _count_unique_nonempty_strings(Array(staging_snapshot.get("selected_fireteam_ids", [])))
	var reentry_selected_operator_count: int = Array(staging_snapshot.get("selected_unit_ids", [])).size()
	var reentry_payload_fireteam_count: int = Array(staging_snapshot.get("payload_fireteam_ids", [])).size()
	var reentry_payload_operator_count: int = int(staging_snapshot.get("payload_operator_count", 0))
	var reentry_boarded_operator_count: int = int(staging_snapshot.get("boarded_operator_count", 0))
	var reentry_staging_read_only: bool = bool(reentry_staging_label.get_meta("read_only", false)) if reentry_staging_label != null else false
	var reentry_loadout_read_only: bool = bool(reentry_loadout_label.get_meta("read_only", false)) if reentry_loadout_label != null else false
	var reentry_boarding_read_only: bool = bool(reentry_boarding_label.get_meta("read_only", false)) if reentry_boarding_label != null else false
	var reentry_start_read_only: bool = bool(reentry_start_label.get_meta("read_only", false)) if reentry_start_label != null else false
	var chip_count: int = chips.size()
	var current_step_id: String = String(readiness_snapshot.get("current_next_step_id", "")).strip_edges()
	var checks: Array = []
	_append_visual_audit_check(checks, "visible_readiness_gate_pass", String(visible_snapshot.get("gate", "")) == "pass", "critical", "Return-panel polish builds on green station visible-readiness gate.")
	_append_visual_audit_check(checks, "panel_visible", _control_is_visible(followup_panel), "critical", "Station Homebase return panel should be visible.")
	_append_visual_audit_check(checks, "panel_style_id", String(followup_panel.get_meta("homebase_return_panel_style_id", "")) == HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID if followup_panel != null else false, "critical", "Return panel should expose TASK_755 style metadata.")
	_append_visual_audit_check(checks, "title_visible", _control_is_visible(title_label) and title_text == "Rueckkehr abgeschlossen", "critical", "Return panel title should make the completed return obvious.")
	_append_visual_audit_check(checks, "action_visible", _control_is_visible(action_label) and action_text.contains("Naechster Auftrag") and action_text.contains(_station_next_sortie_step_label(current_step_id)), "critical", "Return panel action line should name the current next Homebase action.")
	_append_visual_audit_check(checks, "chips_visible", _control_is_visible(chip_row) and chip_count >= 5, "critical", "Return panel should show all next-sortie steps as compact chips.")
	_append_visual_audit_check(checks, "reentry_plan_visible", _control_is_visible(reentry_label) and reentry_text == HOMEBASE_REENTRY_PLAN_LINE, "critical", "Return panel should show the full Reentry plan before the next sortie.")
	_append_visual_audit_check(checks, "reentry_plan_style_id", reentry_style_id == HOMEBASE_REENTRY_PLAN_STYLE_ID, "critical", "Reentry plan should expose TASK_762 style metadata.")
	_append_visual_audit_check(checks, "reentry_plan_compact", reentry_text.length() <= 82 and reentry_text.count("\n") == 0, "critical", "Reentry plan should stay compact and one-line.")
	_append_visual_audit_check(checks, "reentry_fireteam_staging_visible", _control_is_visible(reentry_staging_label) and reentry_staging_text == reentry_staging_expected_text, "critical", "Return panel should show Fireteam staging from the existing Homebase staging snapshot.")
	_append_visual_audit_check(checks, "reentry_fireteam_staging_style_id", reentry_staging_style_id == HOMEBASE_REENTRY_FIRETEAM_STAGING_STYLE_ID, "critical", "Fireteam staging line should expose TASK_763 style metadata.")
	_append_visual_audit_check(checks, "reentry_fireteam_staging_mentions_fireteam", reentry_staging_text.contains("Fireteam") and reentry_staging_text.contains("Operatoren"), "critical", "Fireteam staging line should name fireteam and operator context.")
	_append_visual_audit_check(checks, "reentry_fireteam_staging_compact", reentry_staging_text.length() <= 98 and reentry_staging_text.count("\n") == 0, "critical", "Fireteam staging line should stay compact and one-line.")
	_append_visual_audit_check(checks, "reentry_loadout_bridge_visible", _control_is_visible(reentry_loadout_label) and reentry_loadout_text == reentry_loadout_expected_text, "critical", "Return panel should show Loadout readiness from the existing pre-mission readiness snapshot.")
	_append_visual_audit_check(checks, "reentry_loadout_bridge_style_id", reentry_loadout_style_id == HOMEBASE_REENTRY_LOADOUT_BRIDGE_STYLE_ID, "critical", "Loadout bridge line should expose TASK_764 style metadata.")
	_append_visual_audit_check(checks, "reentry_loadout_bridge_mentions_loadout", reentry_loadout_text.contains("Loadout") and not reentry_loadout_state.is_empty(), "critical", "Loadout bridge line should name Loadout and carry a readiness state.")
	_append_visual_audit_check(checks, "reentry_loadout_bridge_compact", reentry_loadout_text.length() <= 92 and reentry_loadout_text.count("\n") == 0, "critical", "Loadout bridge line should stay compact and one-line.")
	_append_visual_audit_check(checks, "reentry_dropship_boarding_visible", _control_is_visible(reentry_boarding_label) and reentry_boarding_text == reentry_boarding_expected_text, "critical", "Return panel should show Dropship and Boarding state from existing readiness/staging snapshots.")
	_append_visual_audit_check(checks, "reentry_dropship_boarding_style_id", reentry_boarding_style_id == HOMEBASE_REENTRY_DROPSHIP_BOARDING_STYLE_ID, "critical", "Dropship boarding line should expose TASK_765 style metadata.")
	_append_visual_audit_check(checks, "reentry_dropship_boarding_mentions_dropship", reentry_boarding_text.contains("Dropship") and reentry_boarding_text.contains("Boarding"), "critical", "Dropship boarding line should name Dropship and Boarding.")
	_append_visual_audit_check(checks, "reentry_dropship_boarding_compact", reentry_boarding_text.length() <= 104 and reentry_boarding_text.count("\n") == 0, "critical", "Dropship boarding line should stay compact and one-line.")
	_append_visual_audit_check(checks, "reentry_start_permission_visible", _control_is_visible(reentry_start_label) and reentry_start_text == reentry_start_expected_text, "critical", "Return panel should show Start permission from existing readiness/startbutton snapshots.")
	_append_visual_audit_check(checks, "reentry_start_permission_style_id", reentry_start_style_id == HOMEBASE_REENTRY_START_PERMISSION_STYLE_ID, "critical", "Start permission line should expose TASK_766 style metadata.")
	_append_visual_audit_check(checks, "reentry_start_permission_mentions_start", reentry_start_text.contains("Startfreigabe") and not reentry_start_state.is_empty(), "critical", "Start permission line should name the release state.")
	_append_visual_audit_check(checks, "reentry_start_permission_matches_button", (reentry_can_start and not reentry_start_button_disabled) or (not reentry_can_start and reentry_start_button_disabled), "critical", "Start permission line should agree with the existing Start button state.")
	_append_visual_audit_check(checks, "reentry_start_permission_compact", reentry_start_text.length() <= 112 and reentry_start_text.count("\n") == 0, "critical", "Start permission line should stay compact and one-line.")
	_append_visual_audit_check(checks, "current_chip_present", _station_return_panel_chip_state_exists(chips, current_step_id, "current"), "critical", "Return panel chips should mark the current next step.")
	_append_visual_audit_check(checks, "chip_labels_german", _station_return_panel_chips_have_german_labels(chips), "critical", "Return panel chips should use the same German station step labels.")
	_append_visual_audit_check(checks, "inside_followup_panel", _rect_inside(title_rect, panel_rect) and _rect_inside(action_rect, panel_rect) and _rect_inside(chip_row_rect, panel_rect) and _rect_inside(reentry_rect, panel_rect) and _rect_inside(reentry_staging_rect, panel_rect) and _rect_inside(reentry_loadout_rect, panel_rect) and _rect_inside(reentry_boarding_rect, panel_rect) and _rect_inside(reentry_start_rect, panel_rect) and _rect_inside(post_rect, panel_rect) and _rect_inside(readiness_rect, panel_rect), "critical", "Return title, action, chips, Reentry plan, Fireteam staging, Loadout bridge, Dropship boarding, Start permission and legacy lines should stay inside the follow-up panel.")
	_append_visual_audit_check(checks, "reentry_plan_inside_followup_panel", _rect_inside(reentry_rect, panel_rect), "critical", "Reentry plan should stay grouped in the follow-up panel.")
	_append_visual_audit_check(checks, "reentry_fireteam_staging_inside_followup_panel", _rect_inside(reentry_staging_rect, panel_rect), "critical", "Fireteam staging line should stay grouped in the follow-up panel.")
	_append_visual_audit_check(checks, "reentry_loadout_bridge_inside_followup_panel", _rect_inside(reentry_loadout_rect, panel_rect), "critical", "Loadout bridge line should stay grouped in the follow-up panel.")
	_append_visual_audit_check(checks, "reentry_dropship_boarding_inside_followup_panel", _rect_inside(reentry_boarding_rect, panel_rect), "critical", "Dropship boarding line should stay grouped in the follow-up panel.")
	_append_visual_audit_check(checks, "reentry_start_permission_inside_followup_panel", _rect_inside(reentry_start_rect, panel_rect), "critical", "Start permission line should stay grouped in the follow-up panel.")
	_append_visual_audit_check(checks, "inside_mission_panel", _rect_inside(panel_rect, mission_rect), "critical", "Return panel should stay inside the MissionPanel.")
	_append_visual_audit_check(checks, "read_only", bool(visible_snapshot.get("read_only", false)) and bool(readiness_snapshot.get("read_only", false)) and reentry_staging_read_only and reentry_loadout_read_only and reentry_boarding_read_only and reentry_start_read_only, "critical", "Return panel polish should read existing Homebase state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_homebase_return_panel_polish.v1",
		"task_id": "TASK_755",
		"source_task_ids": ["TASK_754", "TASK_749", "TASK_747", "TASK_746", "TASK_762", "TASK_763", "TASK_764", "TASK_765", "TASK_766"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"return_panel_style_id": String(followup_panel.get_meta("homebase_return_panel_style_id", "")) if followup_panel != null else "",
		"return_panel_title_text": title_text,
		"return_panel_action_text": action_text,
		"return_panel_chip_count": chip_count,
		"return_panel_step_chips": chips,
		"return_panel_primary_step_id": current_step_id,
		"reentry_plan_style_id": reentry_style_id,
		"reentry_plan_text": reentry_text,
		"reentry_plan_visible": _control_is_visible(reentry_label),
		"reentry_fireteam_staging_style_id": reentry_staging_style_id,
		"reentry_fireteam_staging_text": reentry_staging_text,
		"reentry_fireteam_staging_expected_text": reentry_staging_expected_text,
		"reentry_fireteam_staging_visible": _control_is_visible(reentry_staging_label),
		"reentry_fireteam_staging_read_only": reentry_staging_read_only,
		"reentry_selected_fireteam_count": reentry_selected_fireteam_count,
		"reentry_selected_operator_count": reentry_selected_operator_count,
		"reentry_payload_fireteam_count": reentry_payload_fireteam_count,
		"reentry_payload_operator_count": reentry_payload_operator_count,
		"reentry_boarded_operator_count": reentry_boarded_operator_count,
		"reentry_loadout_bridge_style_id": reentry_loadout_style_id,
		"reentry_loadout_bridge_text": reentry_loadout_text,
		"reentry_loadout_bridge_expected_text": reentry_loadout_expected_text,
		"reentry_loadout_bridge_visible": _control_is_visible(reentry_loadout_label),
		"reentry_loadout_bridge_read_only": reentry_loadout_read_only,
		"reentry_loadout_state": reentry_loadout_state,
		"reentry_loadout_detail": reentry_loadout_detail,
		"reentry_loadout_item_present": not loadout_readiness_item.is_empty(),
		"reentry_dropship_boarding_style_id": reentry_boarding_style_id,
		"reentry_dropship_boarding_text": reentry_boarding_text,
		"reentry_dropship_boarding_expected_text": reentry_boarding_expected_text,
		"reentry_dropship_boarding_visible": _control_is_visible(reentry_boarding_label),
		"reentry_dropship_boarding_read_only": reentry_boarding_read_only,
		"reentry_dropship_state": reentry_dropship_state,
		"reentry_boarding_state": reentry_boarding_state,
		"reentry_dropship_detail": reentry_dropship_detail,
		"reentry_boarding_detail": reentry_boarding_detail,
		"reentry_dropship_item_present": not dropship_readiness_item.is_empty(),
		"reentry_boarding_item_present": not boarding_readiness_item.is_empty(),
		"reentry_start_permission_style_id": reentry_start_style_id,
		"reentry_start_permission_text": reentry_start_text,
		"reentry_start_permission_expected_text": reentry_start_expected_text,
		"reentry_start_permission_visible": _control_is_visible(reentry_start_label),
		"reentry_start_permission_read_only": reentry_start_read_only,
		"reentry_start_state": reentry_start_state,
		"reentry_start_detail": reentry_start_detail,
		"reentry_start_item_present": not start_readiness_item.is_empty(),
		"reentry_can_start": reentry_can_start,
		"reentry_start_button_text": reentry_start_button_text,
		"reentry_start_button_disabled": reentry_start_button_disabled,
		"readiness_line": String(readiness_snapshot.get("readiness_line", "")),
		"rendered_readiness_line": readiness_label.text.strip_edges() if readiness_label != null else "",
		"post_summary_text": post_label.text.strip_edges() if post_label != null else "",
		"panel_rect": _rect_to_dict(panel_rect),
		"title_rect": _rect_to_dict(title_rect),
		"action_rect": _rect_to_dict(action_rect),
		"chip_row_rect": _rect_to_dict(chip_row_rect),
		"reentry_plan_rect": _rect_to_dict(reentry_rect),
		"reentry_fireteam_staging_rect": _rect_to_dict(reentry_staging_rect),
		"reentry_loadout_bridge_rect": _rect_to_dict(reentry_loadout_rect),
		"reentry_dropship_boarding_rect": _rect_to_dict(reentry_boarding_rect),
		"reentry_start_permission_rect": _rect_to_dict(reentry_start_rect),
		"post_summary_rect": _rect_to_dict(post_rect),
		"next_sortie_rect": _rect_to_dict(readiness_rect),
		"return_panel_polish_ready": failed_count == 0,
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"visual_only": true,
		"checks": checks,
		"recommended_next_task": "TASK_756 - Station Homebase Real Window Recapture",
	}


func get_frontier_probe_homebase_visible_readiness_review_snapshot() -> Dictionary:
	var readiness_snapshot: Dictionary = get_frontier_probe_homebase_next_sortie_readiness_snapshot()
	var post_label := _get_post_debrief_homebase_summary_label()
	var readiness_label := _get_next_sortie_readiness_label()
	var followup_panel := _get_post_debrief_followup_panel()
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as Control
	var mission_vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as Control
	var post_rect: Rect2 = _control_global_rect(post_label)
	var readiness_rect: Rect2 = _control_global_rect(readiness_label)
	var followup_rect: Rect2 = _control_global_rect(followup_panel)
	var mission_rect: Rect2 = _control_global_rect(mission_panel)
	var mission_child_max_bottom: float = _visible_child_max_bottom(mission_panel)
	var readiness_line: String = String(readiness_snapshot.get("readiness_line", "")).strip_edges()
	var rendered_line: String = readiness_label.text.strip_edges() if readiness_label != null else ""
	var summary_font_size: int = post_label.get_theme_font_size("font_size") if post_label != null else 0
	var readiness_font_size: int = readiness_label.get_theme_font_size("font_size") if readiness_label != null else 0
	var followup_style_id: String = String(followup_panel.get_meta("homebase_followup_style_id", "")) if followup_panel != null else ""
	var checks: Array = []
	_append_visual_audit_check(checks, "readiness_gate_pass", String(readiness_snapshot.get("gate", "")) == "pass", "critical", "TASK_641 readiness gate should be green before visual review.")
	_append_visual_audit_check(checks, "post_summary_visible", _control_is_visible(post_label), "critical", "Post-Debrief Homebase summary should remain visible.")
	_append_visual_audit_check(checks, "next_sortie_visible", _control_is_visible(readiness_label), "critical", "Next-sortie readiness line should be visible.")
	_append_visual_audit_check(checks, "line_matches_snapshot", not readiness_line.is_empty() and rendered_line == readiness_line, "critical", "Rendered line should match TASK_641 snapshot text.")
	_append_visual_audit_check(checks, "labels_inside_mission_panel", _rect_inside(post_rect, mission_rect) and _rect_inside(readiness_rect, mission_rect), "critical", "Post-Debrief and Next-Sortie lines should stay inside MissionPanel.")
	_append_visual_audit_check(checks, "followup_panel_visible", _control_is_visible(followup_panel), "critical", "Post-Debrief follow-up panel should be visible.")
	_append_visual_audit_check(checks, "followup_panel_inside_mission_panel", _rect_inside(followup_rect, mission_rect), "critical", "Follow-up panel should stay inside MissionPanel.")
	_append_visual_audit_check(checks, "labels_inside_followup_panel", _rect_inside(post_rect, followup_rect) and _rect_inside(readiness_rect, followup_rect), "critical", "Summary and next-sortie labels should be grouped inside the follow-up panel.")
	_append_visual_audit_check(checks, "followup_panel_emphasis_style", followup_style_id == HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID, "critical", "Follow-up panel should expose the TASK_645 emphasis style.")
	_append_visual_audit_check(checks, "followup_label_emphasis", summary_font_size >= HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE and readiness_font_size >= HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE, "critical", "Follow-up labels should be visibly larger than the old compact labels.")
	_append_visual_audit_check(checks, "next_sortie_below_post_summary", readiness_rect.position.y >= post_rect.end.y - 1.0, "critical", "Next-Sortie line should sit below the Debrief return summary.")
	_append_visual_audit_check(checks, "labels_do_not_overlap", not _rects_overlap(post_rect, readiness_rect) or readiness_rect.position.y >= post_rect.end.y - 1.0, "critical", "Return and next-sortie lines should not visually overlap.")
	_append_visual_audit_check(checks, "mission_panel_no_overflow", mission_panel != null and mission_child_max_bottom <= mission_rect.end.y + 0.5, "critical", "MissionPanel content should not overflow after adding readiness lines.")
	_append_visual_audit_check(checks, "readiness_line_compact", rendered_line.length() <= 190 and rendered_line.count("\n") == 0, "critical", "Next-sortie line should remain compact enough for the Homebase mission panel.")
	_append_visual_audit_check(checks, "mission_vbox_visible", _control_is_visible(mission_vbox), "critical", "MissionVBox should be visible for the review capture.")
	_append_visual_audit_check(checks, "read_only", bool(readiness_snapshot.get("read_only", false)) and not bool(readiness_snapshot.get("ui_sets_gameplay_truth", true)), "critical", "Visible review should read existing Homebase state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.frontier_probe_homebase_visible_readiness_review.v1",
		"task_id": "TASK_642",
		"source_task_ids": ["TASK_641", "TASK_640"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"readiness_gate": String(readiness_snapshot.get("gate", "")),
		"route_id": String(readiness_snapshot.get("route_id", "")),
		"scenario_id": String(readiness_snapshot.get("scenario_id", "")),
		"current_next_step_id": String(readiness_snapshot.get("current_next_step_id", "")),
		"readiness_line": readiness_line,
		"rendered_readiness_line": rendered_line,
		"post_summary_text": post_label.text.strip_edges() if post_label != null else "",
		"post_summary_visible": _control_is_visible(post_label),
		"next_sortie_visible": _control_is_visible(readiness_label),
		"followup_panel_visible": _control_is_visible(followup_panel),
		"followup_panel_style_id": followup_style_id,
		"followup_panel_min_height": followup_panel.custom_minimum_size.y if followup_panel != null else 0.0,
		"post_summary_font_size": summary_font_size,
		"next_sortie_font_size": readiness_font_size,
		"post_summary_emphasis": bool(post_label.get_meta("homebase_followup_emphasis", false)) if post_label != null else false,
		"next_sortie_emphasis": bool(readiness_label.get_meta("homebase_followup_emphasis", false)) if readiness_label != null else false,
		"mission_panel_visible": _control_is_visible(mission_panel),
		"mission_vbox_visible": _control_is_visible(mission_vbox),
		"post_summary_rect": _rect_to_dict(post_rect),
		"next_sortie_rect": _rect_to_dict(readiness_rect),
		"followup_panel_rect": _rect_to_dict(followup_rect),
		"mission_panel_rect": _rect_to_dict(mission_rect),
		"mission_child_max_bottom": mission_child_max_bottom,
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"visual_only": true,
		"checks": checks,
		"recommended_next_task": "TASK_643 - Frontier Probe Homebase Readiness Visual Polish Findings",
	}


func get_homebase_missionpanel_density_playfeel_snapshot() -> Dictionary:
	var visible_snapshot: Dictionary = get_frontier_probe_homebase_visible_readiness_review_snapshot()
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as Control
	var mission_vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as Control
	var mission_summary_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	var briefing_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel") as Control
	var readiness_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel") as Control
	var followup_panel := _get_post_debrief_followup_panel()
	var mission_rect: Rect2 = _control_global_rect(mission_panel)
	var briefing_rect: Rect2 = _control_global_rect(briefing_panel)
	var readiness_rect: Rect2 = _control_global_rect(readiness_panel)
	var followup_rect: Rect2 = _control_global_rect(followup_panel)
	var child_max_bottom: float = _visible_child_max_bottom(mission_panel)
	var visible_sections: Array = _build_missionpanel_density_sections(mission_vbox, mission_rect)
	var visible_section_count: int = visible_sections.size()
	var total_text_length: int = _collect_visible_text_length(mission_vbox)
	var mission_summary_collapsed: bool = mission_summary_label != null and bool(mission_summary_label.get_meta("homebase_density_summary_collapsed", false))
	var density_findings_style_id: String = ""
	if mission_summary_label != null:
		density_findings_style_id = String(mission_summary_label.get_meta("homebase_density_findings_style_id", ""))
	var vertical_fill_ratio: float = 0.0
	if mission_rect.size.y > 0.0:
		vertical_fill_ratio = maxf(0.0, child_max_bottom - mission_rect.position.y) / mission_rect.size.y
	var order_ok: bool = _control_is_visible(briefing_panel) and _control_is_visible(readiness_panel) and _control_is_visible(followup_panel) \
		and briefing_rect.position.y <= readiness_rect.position.y + 0.5 \
		and readiness_rect.position.y <= followup_rect.position.y + 0.5
	var checks: Array = []
	_append_visual_audit_check(checks, "visible_readiness_gate_pass", String(visible_snapshot.get("gate", "")) == "pass", "critical", "MissionPanel density should build on the green visible-readiness gate.")
	_append_visual_audit_check(checks, "mission_panel_visible", _control_is_visible(mission_panel), "critical", "MissionPanel should be visible.")
	_append_visual_audit_check(checks, "key_sections_visible", _control_is_visible(briefing_panel) and _control_is_visible(readiness_panel) and _control_is_visible(followup_panel), "critical", "Briefing, readiness and follow-up sections should all be visible.")
	_append_visual_audit_check(checks, "key_sections_inside_panel", _rect_inside(briefing_rect, mission_rect) and _rect_inside(readiness_rect, mission_rect) and _rect_inside(followup_rect, mission_rect), "critical", "Key MissionPanel sections should stay inside MissionPanel.")
	_append_visual_audit_check(checks, "key_section_order", order_ok, "critical", "MissionPanel should scan as briefing -> readiness -> follow-up.")
	_append_visual_audit_check(checks, "mission_panel_no_overflow", mission_panel != null and child_max_bottom <= mission_rect.end.y + 0.5, "critical", "MissionPanel content should not overflow.")
	_append_visual_audit_check(checks, "visible_section_budget", visible_section_count >= 4 and visible_section_count <= 8, "critical", "MissionPanel should have a small number of direct visible chunks.")
	_append_visual_audit_check(checks, "vertical_density_budget", vertical_fill_ratio <= 0.96, "warning", "MissionPanel is close to full height and should be checked in a real window.")
	_append_visual_audit_check(checks, "text_density_budget", total_text_length <= 1200, "warning", "MissionPanel visible text is close to the scanability budget and should be checked in a real window.")
	_append_visual_audit_check(checks, "followup_polish_present", String(visible_snapshot.get("followup_panel_style_id", "")) == HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID, "critical", "TASK_645 follow-up polish should remain present.")
	_append_visual_audit_check(checks, "density_findings_applied", mission_summary_collapsed and density_findings_style_id == HOMEBASE_POST_DEBRIEF_DENSITY_FINDINGS_STYLE_ID, "critical", "Post-Debrief Homebase should collapse the legacy MissionSummary line when the follow-up panel is active.")
	_append_visual_audit_check(checks, "density_warning_reduced", mission_summary_collapsed and visible_section_count <= 6 and total_text_length <= 1200, "critical", "TASK_647 should reduce scan pressure by collapsing duplicate text and one visible section.")
	_append_visual_audit_check(checks, "read_only", bool(visible_snapshot.get("read_only", false)) and not bool(visible_snapshot.get("ui_sets_gameplay_truth", true)), "critical", "Density review should read existing Homebase state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.homebase_missionpanel_density_playfeel.v1",
		"task_id": "TASK_646",
		"source_task_ids": ["TASK_645", "TASK_642"],
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"visible_readiness_gate": String(visible_snapshot.get("gate", "")),
		"mission_panel_visible": _control_is_visible(mission_panel),
		"mission_panel_rect": _rect_to_dict(mission_rect),
		"mission_child_max_bottom": child_max_bottom,
		"vertical_fill_ratio": vertical_fill_ratio,
		"visible_section_count": visible_section_count,
		"visible_sections": visible_sections,
		"total_visible_text_length": total_text_length,
		"briefing_panel_visible": _control_is_visible(briefing_panel),
		"readiness_panel_visible": _control_is_visible(readiness_panel),
		"followup_panel_visible": _control_is_visible(followup_panel),
		"mission_summary_visible": _control_is_visible(mission_summary_label),
		"mission_summary_collapsed": mission_summary_collapsed,
		"density_findings_style_id": density_findings_style_id,
		"briefing_panel_rect": _rect_to_dict(briefing_rect),
		"readiness_panel_rect": _rect_to_dict(readiness_rect),
		"followup_panel_rect": _rect_to_dict(followup_rect),
		"key_section_order": "briefing_readiness_followup" if order_ok else "needs_review",
		"followup_panel_style_id": String(visible_snapshot.get("followup_panel_style_id", "")),
		"post_summary_font_size": int(visible_snapshot.get("post_summary_font_size", 0)),
		"next_sortie_font_size": int(visible_snapshot.get("next_sortie_font_size", 0)),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"visual_only": true,
		"checks": checks,
		"recommended_next_task": "TASK_648 - Continue Homebase/Core-Loop Playfeel only after real-window review confirms the panel reads cleanly",
	}


func get_post_mission_skill_delta_snapshot() -> Dictionary:
	var focused_delta: Dictionary = _get_post_mission_skill_delta_for_unit(_focused_unit_id)
	var focused_text: String = _format_post_mission_skill_delta_text(focused_delta)
	var focused_has_delta: bool = not focused_delta.is_empty()
	var style_id: String = "homebase_progression_delta_v1" if focused_has_delta else ""
	var badge_text: String = "MISSION GAIN" if focused_has_delta else ""
	var has_expected_schema: bool = String(_post_mission_skill_delta_summary.get("schema", "")) == "sternenbuergerchen.skill_progress_award_summary.v1"
	var has_resolver_authority: bool = String(_post_mission_skill_delta_summary.get("authority", "")) == "MissionProgressionResolver"
	var sheet_visible: bool = _character_sheet_open and focused_has_delta
	var checks: Array = [
		{"id": "source_schema", "passed": has_expected_schema},
		{"id": "authority_resolver", "passed": has_resolver_authority},
		{"id": "unit_delta_lookup", "passed": _post_mission_skill_delta_by_unit_id.size() > 0},
		{"id": "focused_delta_visible", "passed": focused_has_delta and not focused_text.is_empty()},
		{"id": "character_sheet_delta_visible", "passed": sheet_visible},
		{"id": "visual_style_ready", "passed": style_id == "homebase_progression_delta_v1" and badge_text == "MISSION GAIN"},
		{"id": "read_only", "passed": bool(_post_mission_skill_delta_summary.get("read_only", false)) and not bool(_post_mission_skill_delta_summary.get("ui_sets_gameplay_truth", true))},
	]
	return {
		"schema": "sternenbuergerchen.post_mission_skill_delta_homebase_bridge.v1",
		"task_id": "TASK_594",
		"source_schema": String(_post_mission_skill_delta_summary.get("schema", "")),
		"authority": String(_post_mission_skill_delta_summary.get("authority", "")),
		"source": String(_post_mission_skill_delta_summary.get("source", "")),
		"unit_delta_count": _post_mission_skill_delta_by_unit_id.size(),
		"focused_unit_id": _focused_unit_id,
		"focused_delta_text": focused_text,
		"homebase_delta_visible": focused_has_delta,
		"character_sheet_delta_visible": sheet_visible,
		"style_id": style_id,
		"badge_text": badge_text,
		"visual_polish_ready": style_id == "homebase_progression_delta_v1" and badge_text == "MISSION GAIN" and focused_has_delta,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"checks": checks,
		"gate": "pass" if _all_snapshot_checks_passed(checks) else "needs_attention",
	}


func get_homebase_progression_f6_evidence_snapshot() -> Dictionary:
	var bridge_snapshot: Dictionary = get_post_mission_skill_delta_snapshot()
	var popup := get_node_or_null("CharacterSheetPopup") as Control
	var sheet_content := get_node_or_null("CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/PopupScroll/GeneratedSheetContent") as Control
	var award_highlight: Control = null
	var award_value_row: Control = null
	var award_label: Label = null
	var award_value: Label = null
	if sheet_content != null:
		award_highlight = sheet_content.find_child("PostMissionAwardHighlightRow", true, false) as Control
		award_value_row = sheet_content.find_child("PostMissionAwardValueRow", true, false) as Control
		award_label = sheet_content.find_child("PostMissionAwardLabel", true, false) as Label
		award_value = sheet_content.find_child("PostMissionAwardValue", true, false) as Label
	var popup_rect: Rect2 = _control_global_rect(popup)
	var sheet_rect: Rect2 = _control_global_rect(sheet_content)
	var highlight_rect: Rect2 = _control_global_rect(award_highlight)
	var value_row_rect: Rect2 = _control_global_rect(award_value_row)
	var label_rect: Rect2 = _control_global_rect(award_label)
	var value_rect: Rect2 = _control_global_rect(award_value)
	var award_label_text: String = award_label.text.strip_edges() if award_label != null else ""
	var award_value_text: String = award_value.text.strip_edges() if award_value != null else ""
	var bridge_gate: String = String(bridge_snapshot.get("gate", "")).strip_edges()
	var style_id: String = String(bridge_snapshot.get("style_id", "")).strip_edges()
	var badge_text: String = String(bridge_snapshot.get("badge_text", "")).strip_edges()
	var checks: Array = []
	_append_visual_audit_check(checks, "bridge_gate_pass", bridge_gate == "pass", "critical", "Post-mission skill delta gate should stay green.")
	_append_visual_audit_check(checks, "popup_visible", _control_is_visible(popup), "critical", "Character Sheet popup should be visible.")
	_append_visual_audit_check(checks, "sheet_content_visible", _control_is_visible(sheet_content), "critical", "Generated Character Sheet content should be visible.")
	_append_visual_audit_check(checks, "award_controls_visible", _control_is_visible(award_highlight) and _control_is_visible(award_value_row) and _control_is_visible(award_label) and _control_is_visible(award_value), "critical", "MISSION GAIN controls should be visible.")
	_append_visual_audit_check(checks, "award_inside_popup", _rect_inside(highlight_rect, popup_rect) and _rect_inside(label_rect, popup_rect) and _rect_inside(value_rect, popup_rect), "critical", "Award row should stay inside the Character Sheet popup.")
	_append_visual_audit_check(checks, "award_inside_sheet_content", _rect_inside(highlight_rect, sheet_rect) and _rect_inside(label_rect, sheet_rect) and _rect_inside(value_rect, sheet_rect), "critical", "Award row should stay inside generated sheet content.")
	_append_visual_audit_check(checks, "style_id_present", style_id == "homebase_progression_delta_v1", "critical", "Award row should keep the TASK_595 style id.")
	_append_visual_audit_check(checks, "badge_visible", badge_text == "MISSION GAIN" and award_label_text.contains("MISSION GAIN"), "critical", "MISSION GAIN badge should be visible in the row label.")
	_append_visual_audit_check(checks, "value_text_visible", award_value_text.contains("XP +"), "critical", "Award row value should include the visible XP delta.")
	_append_visual_audit_check(checks, "label_text_compact", award_label_text.length() <= 48 and award_label_text.count("\n") == 0, "critical", "Award label should stay compact.")
	_append_visual_audit_check(checks, "value_text_compact", award_value_text.length() <= 80 and award_value_text.count("\n") <= 1, "critical", "Award value should stay compact.")
	_append_visual_audit_check(checks, "read_only", bool(bridge_snapshot.get("read_only", false)) and not bool(bridge_snapshot.get("ui_sets_gameplay_truth", true)), "critical", "Evidence snapshot should read existing state only.")
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.homebase_progression_f6_evidence.v1",
		"task_id": "TASK_597",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": "homebase_progression_f6_evidence_v1",
		"bridge_gate": bridge_gate,
		"source_schema": String(bridge_snapshot.get("schema", "")),
		"focused_unit_id": String(bridge_snapshot.get("focused_unit_id", "")),
		"focused_delta_text": String(bridge_snapshot.get("focused_delta_text", "")),
		"style_id": style_id,
		"badge_text": badge_text,
		"popup_rect": _rect_to_dict(popup_rect),
		"sheet_content_rect": _rect_to_dict(sheet_rect),
		"award_highlight_rect": _rect_to_dict(highlight_rect),
		"award_value_row_rect": _rect_to_dict(value_row_rect),
		"award_label_rect": _rect_to_dict(label_rect),
		"award_value_rect": _rect_to_dict(value_rect),
		"award_label_text": award_label_text,
		"award_value_text": award_value_text,
		"manual_review_required": true,
		"manual_review_done": false,
		"visual_only": true,
		"checks": checks,
	}


func _control_is_visible(control: Control) -> bool:
	return control != null and control.visible and (control.is_visible_in_tree() if control.is_inside_tree() else true)


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	if inner.size.x <= 0.0 or inner.size.y <= 0.0 or outer.size.x <= 0.0 or outer.size.y <= 0.0:
		return false
	return inner.position.x >= outer.position.x - 0.5 \
		and inner.position.y >= outer.position.y - 0.5 \
		and inner.end.x <= outer.end.x + 0.5 \
		and inner.end.y <= outer.end.y + 0.5


func _rect_to_dict(rect: Rect2) -> Dictionary:
	return {
		"x": rect.position.x,
		"y": rect.position.y,
		"width": rect.size.x,
		"height": rect.size.y,
	}


func _rebuild_post_mission_skill_delta_lookup() -> void:
	_post_mission_skill_delta_by_unit_id = {}
	if String(_post_mission_skill_delta_summary.get("schema", "")) != "sternenbuergerchen.skill_progress_award_summary.v1":
		return
	for award_variant in Array(_post_mission_skill_delta_summary.get("listed_awards", [])):
		if typeof(award_variant) != TYPE_DICTIONARY:
			continue
		var award: Dictionary = Dictionary(award_variant).duplicate(true)
		var unit_id: String = String(award.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		_post_mission_skill_delta_by_unit_id[unit_id] = award


func _get_post_mission_skill_delta_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id := unit_id.strip_edges()
	if normalized_unit_id.is_empty() or not _post_mission_skill_delta_by_unit_id.has(normalized_unit_id):
		return {}
	return Dictionary(_post_mission_skill_delta_by_unit_id.get(normalized_unit_id, {})).duplicate(true)


func _format_post_mission_skill_delta_text(award: Dictionary) -> String:
	if award.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	var xp_delta: int = int(award.get("xp_delta", 0))
	if xp_delta > 0:
		parts.append("XP +%d" % xp_delta)
	var skill_gain_count: int = int(award.get("skill_gain_count", 0))
	if skill_gain_count > 0:
		parts.append("Skills +%d" % skill_gain_count)
	var ftl_gain: float = float(award.get("ftl_tactical_gain", 0.0))
	if ftl_gain > 0.0:
		parts.append("FTL +%.3f" % ftl_gain)
	if parts.is_empty():
		parts.append("no delta")
	return " | ".join(parts)


func _all_snapshot_checks_passed(checks: Array) -> bool:
	if checks.is_empty():
		return false
	for check_variant in checks:
		if typeof(check_variant) != TYPE_DICTIONARY:
			return false
		if not bool(Dictionary(check_variant).get("passed", false)):
			return false
	return true


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
	var background_image := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingBackgroundImage") as TextureRect
	var minimap_visual := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingMinimapVisual") as Control
	var loadout_cards := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutCards") as VBoxContainer
	var bridge_status_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutBridgeStatusLabel") as Label
	var bridge_apply_button := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutBridgeRow/BriefingLoadoutApplyButton") as Button
	if title_label != null:
		snapshot["rendered_title_text"] = title_label.text
	if status_label != null:
		snapshot["rendered_status_text"] = status_label.text
	if objectives_label != null:
		snapshot["rendered_objective_text"] = objectives_label.text
	if teams_label != null:
		snapshot["rendered_team_text"] = teams_label.text
	if background_image != null:
		snapshot["rendered_background_visible"] = background_image.visible
		snapshot["rendered_background_has_texture"] = background_image.texture != null
		snapshot["rendered_background_tooltip"] = background_image.tooltip_text
	if minimap_visual != null and minimap_visual.has_method("get_visual_snapshot"):
		var visual_snapshot: Dictionary = Dictionary(minimap_visual.call("get_visual_snapshot"))
		snapshot["rendered_minimap_visible"] = minimap_visual.visible
		snapshot["rendered_minimap_sample_count"] = int(visual_snapshot.get("sample_count", 0))
		snapshot["rendered_minimap_entry_count"] = int(visual_snapshot.get("entry_count", 0))
		snapshot["rendered_minimap_draw_mode"] = String(visual_snapshot.get("draw_mode", ""))
	if loadout_cards != null:
		snapshot["rendered_loadout_card_count"] = loadout_cards.get_child_count()
		snapshot["rendered_loadout_card_text"] = _build_briefing_loadout_card_text(loadout_cards)
		snapshot["rendered_recommended_loadout_button_count"] = _count_briefing_recommendation_buttons(loadout_cards)
	if bridge_status_label != null:
		snapshot["recommended_loadout_status_text"] = bridge_status_label.text
	if bridge_apply_button != null:
		snapshot["recommended_loadout_apply_button_disabled"] = bridge_apply_button.disabled
		snapshot["recommended_loadout_apply_button_text"] = bridge_apply_button.text
	snapshot["selected_recommended_loadout_id"] = _selected_briefing_loadout_recommendation_id
	snapshot["selected_recommended_loadout_label"] = String(_selected_briefing_loadout_recommendation.get("label", "")).strip_edges()
	snapshot["recommended_loadout_apply_ready"] = _is_briefing_loadout_apply_ready()
	snapshot["recommended_loadout_apply_count"] = _briefing_loadout_apply_count
	snapshot["recommended_loadout_feedback_text"] = _briefing_loadout_feedback_text
	return snapshot


func get_pre_mission_readiness_snapshot() -> Dictionary:
	var snapshot: Dictionary = _pre_mission_readiness_snapshot.duplicate(true)
	snapshot["panel_visible"] = _node_is_visible("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel")
	var summary_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel/ReadinessMargin/ReadinessVBox/ReadinessSummaryLabel") as Label
	var list := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel/ReadinessMargin/ReadinessVBox/ReadinessItemList") as Container
	if summary_label != null:
		snapshot["rendered_summary_text"] = summary_label.text
	if list != null:
		snapshot["rendered_item_count"] = list.get_child_count()
		snapshot["rendered_item_text"] = _build_readiness_item_list_text(list)
		snapshot["rendered_item_columns"] = int(list.get("columns")) if list is GridContainer else 1
		snapshot["rendered_item_visuals"] = _build_readiness_chip_visual_snapshot(list)
	return snapshot


func get_pre_mission_startflow_visual_snapshot() -> Dictionary:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	var mission_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as Control
	var roster_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel") as Control
	var fireteam_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel") as Control
	var flightdeck_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel") as Control
	var briefing_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel") as Control
	var readiness_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel") as Control
	var action_cue_panel := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel") as Control
	var action_cue_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel/ReadinessMargin/ReadinessVBox/ReadinessSummaryLabel") as Label
	var start_button := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	var mission_team_limit_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTeamLimitLabel") as Label
	var mission_transfer_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/MissionTransferLabel") as Label
	var mission_summary_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	var mission_rect: Rect2 = _control_global_rect(mission_panel)
	var roster_rect: Rect2 = _control_global_rect(roster_panel)
	var fireteam_rect: Rect2 = _control_global_rect(fireteam_panel)
	var flightdeck_rect: Rect2 = _control_global_rect(flightdeck_panel)
	var action_cue_rect: Rect2 = _control_global_rect(action_cue_panel)
	var action_cue_label_rect: Rect2 = _control_global_rect(action_cue_label)
	var child_bottom: float = _visible_child_max_bottom(mission_panel)
	return {
		"ui_sets_gameplay_truth": false,
		"layout_source": "drop_light_homebase_fullhd",
		"target_viewport": DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT"),
		"mission_contract_rect": layout.get("mission_brief"),
		"roster_contract_rect": layout.get("roster"),
		"fireteams_contract_rect": layout.get("fireteams"),
		"flightdeck_contract_rect": layout.get("flightdeck"),
		"mission_rect": mission_rect,
		"roster_rect": roster_rect,
		"fireteam_rect": fireteam_rect,
		"flightdeck_rect": flightdeck_rect,
		"release_candidate_action_cue_rect": action_cue_rect,
		"release_candidate_action_cue_label_rect": action_cue_label_rect,
		"briefing_min_height": briefing_panel.custom_minimum_size.y if briefing_panel != null else 0.0,
		"readiness_min_height": readiness_panel.custom_minimum_size.y if readiness_panel != null else 0.0,
		"mission_child_max_bottom": child_bottom,
		"mission_child_overflows": mission_panel != null and child_bottom > mission_rect.end.y + 0.5,
		"mission_overlaps_work_columns": _rects_overlap(mission_rect, roster_rect) or _rects_overlap(mission_rect, fireteam_rect) or _rects_overlap(mission_rect, flightdeck_rect),
		"mission_team_limit_text": mission_team_limit_label.text if mission_team_limit_label != null else "",
		"mission_transfer_text": mission_transfer_label.text if mission_transfer_label != null else "",
		"mission_summary_text": mission_summary_label.text if mission_summary_label != null else "",
		"start_button_text": start_button.text if start_button != null else "",
		"start_button_disabled": start_button.disabled if start_button != null else true,
		"start_button_tooltip": start_button.tooltip_text if start_button != null else "",
		"start_button_readiness_color": String(start_button.get_meta("pre_mission_readiness_color_hex", "")) if start_button != null else "",
		"readiness_summary": String(_pre_mission_readiness_snapshot.get("summary_text", "")).strip_edges(),
		"readiness_overall_state": String(_pre_mission_readiness_snapshot.get("overall_state", "")).strip_edges(),
		"release_candidate_action_cue_visible": action_cue_panel != null and action_cue_panel.visible,
		"release_candidate_action_cue_text": String(action_cue_label.get_meta("release_candidate_action_cue_text", action_cue_label.text)).strip_edges() if action_cue_label != null else "",
		"release_candidate_action_cue_tooltip": action_cue_panel.tooltip_text if action_cue_panel != null else "",
		"release_candidate_action_cue_step_count": int(action_cue_panel.get_meta("release_candidate_action_cue_step_count", 0)) if action_cue_panel != null else 0,
		"release_candidate_action_cue_style_id": String(action_cue_panel.get_meta("release_candidate_action_cue_style_id", "")) if action_cue_panel != null else "",
		"release_candidate_action_cue_priority": String(action_cue_panel.get_meta("release_candidate_action_cue_priority", "")) if action_cue_panel != null else "",
		"release_candidate_action_cue_min_height": action_cue_panel.custom_minimum_size.y if action_cue_panel != null else 0.0,
		"release_candidate_action_cue_font_size": int(action_cue_label.get_meta("release_candidate_action_cue_font_size", 0)) if action_cue_label != null else 0,
		"start_button_release_candidate_action_cue_text": String(start_button.get_meta("release_candidate_action_cue_text", "")).strip_edges() if start_button != null else "",
		"start_button_release_candidate_primary_cta": bool(start_button.get_meta("release_candidate_primary_cta_button", false)) if start_button != null else false,
	}


func get_release_candidate_playability_polish_snapshot() -> Dictionary:
	var startflow: Dictionary = get_pre_mission_startflow_visual_snapshot()
	var readiness: Dictionary = get_pre_mission_readiness_snapshot()
	var cue_text: String = String(startflow.get("release_candidate_action_cue_text", "")).strip_edges()
	var expected_ready_text: String = _build_release_candidate_action_cue_text("ready")
	var readiness_state: String = String(startflow.get("readiness_overall_state", "")).strip_edges()
	var cue_matches_state: bool = cue_text == _build_release_candidate_action_cue_text(readiness_state)
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_playability_polish.v1",
		"task_id": "TASK_809",
		"source_task_id": "TASK_808",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"readiness_overall_state": readiness_state,
		"start_button_text": String(startflow.get("start_button_text", "")).strip_edges(),
		"start_button_disabled": bool(startflow.get("start_button_disabled", true)),
		"release_candidate_action_cue_visible": bool(startflow.get("release_candidate_action_cue_visible", false)),
		"release_candidate_action_cue_text": cue_text,
		"release_candidate_action_cue_expected_ready_text": expected_ready_text,
		"release_candidate_action_cue_tooltip": String(startflow.get("release_candidate_action_cue_tooltip", "")).strip_edges(),
		"release_candidate_action_cue_step_count": int(startflow.get("release_candidate_action_cue_step_count", 0)),
		"release_candidate_action_cue_matches_state": cue_matches_state,
		"release_candidate_action_cue_ready": readiness_state == "ready" and cue_text == expected_ready_text,
		"rendered_readiness_item_text": String(readiness.get("rendered_item_text", "")).strip_edges(),
		"recommended_next_task": "TASK_810 - Station Reentry Release Candidate First Mission CTA Visual Smoke",
	}


func get_release_candidate_first_mission_cta_visual_smoke_snapshot() -> Dictionary:
	var startflow: Dictionary = get_pre_mission_startflow_visual_snapshot()
	var readiness: Dictionary = get_pre_mission_readiness_snapshot()
	var polish: Dictionary = get_release_candidate_playability_polish_snapshot()
	var aircraft: Dictionary = get_aircraft_panel_snapshot()
	var staging: Dictionary = get_homebase_direct_staging_snapshot()
	var checks: Array = []
	var readiness_text: String = String(readiness.get("rendered_item_text", "")).strip_edges()
	var selected_status_text: String = String(aircraft.get("selected_status_text", "")).strip_edges()
	var cue_text: String = String(polish.get("release_candidate_action_cue_text", "")).strip_edges()
	var expected_ready_text: String = String(polish.get("release_candidate_action_cue_expected_ready_text", "")).strip_edges()
	var cue_rect: Rect2 = startflow.get("release_candidate_action_cue_rect", Rect2())
	var cue_label_rect: Rect2 = startflow.get("release_candidate_action_cue_label_rect", Rect2())
	var mission_rect: Rect2 = startflow.get("mission_rect", Rect2())
	var payload_operator_count: int = int(staging.get("payload_operator_count", 0))
	var boarded_operator_count: int = int(staging.get("boarded_operator_count", 0))

	_append_visual_audit_check(
		checks,
		"read_only_boundaries",
		_snapshot_boundary_is_read_only(polish) and not bool(startflow.get("ui_sets_gameplay_truth", true)),
		"critical",
		"CTA visual smoke must read existing Homebase state only."
	)
	_append_visual_audit_check(
		checks,
		"singleplayer_cta_ready",
		String(polish.get("readiness_overall_state", "")) == "ready" \
			and bool(polish.get("release_candidate_action_cue_ready", false)) \
			and cue_text == expected_ready_text,
		"critical",
		"Singleplayer Homebase should show the exact ready action chain before the first mission.",
		{"cue_text": cue_text, "expected_ready_text": expected_ready_text}
	)
	_append_visual_audit_check(
		checks,
		"start_button_actionable",
		String(polish.get("start_button_text", "")).strip_edges() == "Einsatz starten" \
			and not bool(polish.get("start_button_disabled", true)),
		"critical",
		"The visible Start Mission button should be enabled for the release start path."
	)
	_append_visual_audit_check(
		checks,
		"visible_readiness_has_no_stop_blocker",
		readiness_text.find("STOP Team") < 0 \
			and readiness_text.find("STOP Dropship") < 0 \
			and readiness_text.find("STOP Pilot") < 0 \
			and readiness_text.find("STOP Boarding") < 0,
		"critical",
		"Visible readiness chips should not contradict the ready CTA with STOP blockers.",
		{"rendered_readiness_item_text": readiness_text}
	)
	_append_visual_audit_check(
		checks,
		"flightdeck_has_shipcard",
		Array(aircraft.get("visible_aircraft_definitions", [])).size() >= 1 \
			and not selected_status_text.contains("Flight deck empty"),
		"critical",
		"Flightdeck should show a usable shipcard instead of the empty blocker.",
		{"selected_status_text": selected_status_text}
	)
	_append_visual_audit_check(
		checks,
		"payload_boarded",
		payload_operator_count > 0 and boarded_operator_count >= payload_operator_count,
		"critical",
		"Dropship payload should carry a boarded Fireteam for the first mission.",
		{
			"payload_operator_count": payload_operator_count,
			"boarded_operator_count": boarded_operator_count,
		}
	)
	_append_visual_audit_check(
		checks,
		"cta_inside_mission_panel",
		_rect_inside(cue_rect, mission_rect) and _rect_inside(cue_label_rect, mission_rect),
		"critical",
		"The CTA panel and label should stay inside the MissionPanel.",
		{
			"cue_rect": cue_rect,
			"cue_label_rect": cue_label_rect,
			"mission_rect": mission_rect,
		}
	)
	_append_visual_audit_check(
		checks,
		"cta_label_has_readable_bounds",
		cue_label_rect.size.x >= 180.0 and cue_label_rect.size.y >= 8.0,
		"critical",
		"The CTA label should have enough visible bounds to be readable in the release window.",
		{"cue_label_rect": cue_label_rect}
	)
	_append_visual_audit_check(
		checks,
		"mission_panel_no_overflow",
		not bool(startflow.get("mission_child_overflows", true)),
		"critical",
		"The first-mission CTA should not push MissionPanel content out of bounds."
	)

	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_first_mission_cta_visual_smoke.v1",
		"task_id": "TASK_810",
		"source_task_id": "TASK_809",
		"singleplayer_path_expected": "MainMenu -> Einzelspieler -> Homebase",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"release_candidate_action_cue_text": cue_text,
		"release_candidate_action_cue_expected_ready_text": expected_ready_text,
		"release_candidate_action_cue_ready": bool(polish.get("release_candidate_action_cue_ready", false)),
		"release_candidate_action_cue_visible": bool(polish.get("release_candidate_action_cue_visible", false)),
		"release_candidate_action_cue_step_count": int(polish.get("release_candidate_action_cue_step_count", 0)),
		"readiness_overall_state": String(polish.get("readiness_overall_state", "")).strip_edges(),
		"start_button_text": String(polish.get("start_button_text", "")).strip_edges(),
		"start_button_disabled": bool(polish.get("start_button_disabled", true)),
		"rendered_readiness_item_text": readiness_text,
		"flightdeck_selected_status_text": selected_status_text,
		"visible_aircraft_count": Array(aircraft.get("visible_aircraft_definitions", [])).size(),
		"payload_operator_count": payload_operator_count,
		"boarded_operator_count": boarded_operator_count,
		"cue_rect": cue_rect,
		"cue_label_rect": cue_label_rect,
		"mission_rect": mission_rect,
		"check_count": checks.size(),
		"failed_count": failed_count,
		"checks": checks,
		"issues": _build_visual_audit_issue_list(checks),
		"status": "pass" if failed_count == 0 else "fail",
		"manual_screenshot_required": true,
		"manual_screenshot_done": false,
		"recommended_next_task": "TASK_811 - Station Reentry Release Candidate First Mission Live Window Polish Findings",
	}


func get_release_candidate_first_homebase_cta_emphasis_snapshot() -> Dictionary:
	var smoke: Dictionary = get_release_candidate_first_mission_cta_visual_smoke_snapshot()
	var startflow: Dictionary = get_pre_mission_startflow_visual_snapshot()
	var cue_text: String = String(smoke.get("release_candidate_action_cue_text", "")).strip_edges()
	var checks: Array = []
	_append_visual_audit_check(
		checks,
		"source_cta_smoke_pass",
		String(smoke.get("status", "")) == "pass" and int(smoke.get("failed_count", -1)) == 0,
		"critical",
		"CTA emphasis builds on the green first-mission CTA smoke."
	)
	_append_visual_audit_check(
		checks,
		"cta_style_applied",
		String(startflow.get("release_candidate_action_cue_style_id", "")) == HOMEBASE_RELEASE_CTA_EMPHASIS_STYLE_ID \
			and String(startflow.get("release_candidate_action_cue_priority", "")) == "primary",
		"critical",
		"The first Homebase action cue should have a dedicated primary emphasis style."
	)
	_append_visual_audit_check(
		checks,
		"cta_font_and_height_emphasized",
		int(startflow.get("release_candidate_action_cue_font_size", 0)) >= HOMEBASE_RELEASE_CTA_FONT_SIZE \
			and float(startflow.get("release_candidate_action_cue_min_height", 0.0)) >= HOMEBASE_RELEASE_CTA_MIN_HEIGHT,
		"critical",
		"The first Homebase action cue should be larger than the old compact readout.",
		{
			"font_size": int(startflow.get("release_candidate_action_cue_font_size", 0)),
			"min_height": float(startflow.get("release_candidate_action_cue_min_height", 0.0)),
		}
	)
	_append_visual_audit_check(
		checks,
		"start_button_carries_same_cue",
		bool(startflow.get("start_button_release_candidate_primary_cta", false)) \
			and String(startflow.get("start_button_release_candidate_action_cue_text", "")).strip_edges() == cue_text,
		"critical",
		"The Start Mission button should carry the same next-action cue as the readiness panel."
	)
	_append_visual_audit_check(
		checks,
		"read_only_boundaries",
		_snapshot_boundary_is_read_only(smoke) and not bool(startflow.get("ui_sets_gameplay_truth", true)),
		"critical",
		"CTA emphasis must remain a visual/read-only projection."
	)
	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	return {
		"schema": "sternenbuergerchen.station_reentry_release_candidate_first_homebase_cta_emphasis.v1",
		"task_id": "TASK_821",
		"source_task_id": "TASK_810",
		"singleplayer_path_expected": "MainMenu -> Einzelspieler -> Homebase",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_navigation": false,
		"creates_command": false,
		"creates_fire_event": false,
		"creates_damage_event": false,
		"sets_multiplayer_truth": false,
		"source_status": String(smoke.get("status", "")),
		"release_candidate_action_cue_text": cue_text,
		"release_candidate_action_cue_style_id": String(startflow.get("release_candidate_action_cue_style_id", "")),
		"release_candidate_action_cue_priority": String(startflow.get("release_candidate_action_cue_priority", "")),
		"release_candidate_action_cue_font_size": int(startflow.get("release_candidate_action_cue_font_size", 0)),
		"release_candidate_action_cue_min_height": float(startflow.get("release_candidate_action_cue_min_height", 0.0)),
		"start_button_release_candidate_action_cue_text": String(startflow.get("start_button_release_candidate_action_cue_text", "")).strip_edges(),
		"start_button_release_candidate_primary_cta": bool(startflow.get("start_button_release_candidate_primary_cta", false)),
		"check_count": checks.size(),
		"failed_count": failed_count,
		"checks": checks,
		"issues": _build_visual_audit_issue_list(checks),
		"status": "pass" if failed_count == 0 else "fail",
		"recommended_next_task": "TASK_822 - Release Singleplayer Visible Window Findings",
	}


func get_pre_mission_visual_audit_snapshot() -> Dictionary:
	var startflow: Dictionary = get_pre_mission_startflow_visual_snapshot()
	var readiness: Dictionary = get_pre_mission_readiness_snapshot()
	var checks: Array = []
	var density: float = _calculate_mission_deck_density(startflow)
	var chips: Array = Array(readiness.get("rendered_item_visuals", []))
	var contrast: Dictionary = _calculate_readiness_chip_contrast(chips)
	var readiness_state: String = String(startflow.get("readiness_overall_state", "")).strip_edges()
	var expected_color_hex: String = _get_readiness_color(readiness_state).to_html(false)
	var start_color_hex: String = String(startflow.get("start_button_readiness_color", "")).strip_edges()

	_append_visual_audit_check(
		checks,
		"read_only_snapshot",
		not bool(startflow.get("ui_sets_gameplay_truth", true)),
		"critical",
		"Visual audit reads existing startflow snapshots only."
	)
	_append_visual_audit_check(
		checks,
		"mission_deck_bounds",
		not bool(startflow.get("mission_child_overflows", true)) and not bool(startflow.get("mission_overlaps_work_columns", true)),
		"critical",
		"Mission deck must not overflow or overlap roster, fireteams or flightdeck.",
		{
			"density": density,
			"mission_child_overflows": bool(startflow.get("mission_child_overflows", true)),
			"mission_overlaps_work_columns": bool(startflow.get("mission_overlaps_work_columns", true)),
		}
	)
	_append_visual_audit_check(
		checks,
		"mission_deck_density",
		density >= 0.20 and density <= 0.96,
		"warning",
		"Mission deck content should use the available FullHD space without crowding it.",
		{"density": density}
	)
	_append_visual_audit_check(
		checks,
		"readiness_chip_grid",
		int(readiness.get("rendered_item_columns", 0)) == 4 \
			and int(readiness.get("rendered_item_count", 0)) >= 6 \
			and chips.size() == int(readiness.get("rendered_item_count", 0)),
		"critical",
		"Readiness chips should stay in a stable four-column grid with visual metadata.",
		{
			"columns": int(readiness.get("rendered_item_columns", 0)),
			"rendered_item_count": int(readiness.get("rendered_item_count", 0)),
			"visual_count": chips.size(),
		}
	)
	_append_visual_audit_check(
		checks,
		"readiness_chip_contrast",
		float(contrast.get("min_text_contrast", 0.0)) >= 4.5 \
			and float(contrast.get("min_status_contrast", 0.0)) >= 3.0 \
			and int(contrast.get("chips_with_detailed_tooltip", 0)) == chips.size(),
		"critical",
		"Readiness status chips need readable text, visible status color and useful tooltips.",
		contrast
	)
	_append_visual_audit_check(
		checks,
		"start_button_matches_readiness",
		_start_button_matches_readiness(startflow),
		"critical",
		"Start button label, disabled state and readiness state should agree.",
		{
			"readiness_state": readiness_state,
			"start_button_text": String(startflow.get("start_button_text", "")),
			"start_button_disabled": bool(startflow.get("start_button_disabled", true)),
		}
	)
	_append_visual_audit_check(
		checks,
		"start_button_color_matches_readiness",
		start_color_hex == expected_color_hex,
		"critical",
		"Start button readiness color should mirror the readiness state.",
		{
			"expected_color_hex": expected_color_hex,
			"actual_color_hex": start_color_hex,
		}
	)

	var failed_count: int = _count_visual_audit_failures(checks, "critical")
	var warning_count: int = _count_visual_audit_failures(checks, "warning")
	return {
		"ui_sets_gameplay_truth": false,
		"audit_id": "pre_mission_f6_visual_audit_v1",
		"automated_visual_gate": "pass" if failed_count == 0 else "fail",
		"manual_screenshot_required": true,
		"manual_screenshot_done": false,
		"check_count": checks.size(),
		"failed_count": failed_count,
		"warning_count": warning_count,
		"mission_deck_density": density,
		"readiness_overall_state": readiness_state,
		"readiness_chip_count": chips.size(),
		"readiness_text_min_contrast": float(contrast.get("min_text_contrast", 0.0)),
		"readiness_status_min_contrast": float(contrast.get("min_status_contrast", 0.0)),
		"checks": checks,
		"issues": _build_visual_audit_issue_list(checks),
		"recommended_next_action": "Run a real F6 FullHD screenshot pass and tune only visible spacing or contrast issues.",
	}


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
	# A launch consumes exactly the craft requested by the Mission button. Other
	# ready crafts remain staged at Homebase and must not expand this handoff.
	var mission_setup_payload_fireteam_ids: PackedStringArray = selected_payload_fireteam_ids.duplicate() if direct_ready else PackedStringArray()
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


func seed_homebase_direct_launch_payload(craft_id: String, fireteam_ids: PackedStringArray, complete_boarding: bool = false) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_sanitize_homebase_direct_staging_state()
	var seeded_count: int = 0
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or _get_fireteam_definition(fireteam_id).is_empty():
			continue
		_add_homebase_direct_payload_fireteam_to_craft(fireteam_id, normalized_craft_id)
		if complete_boarding:
			var state: Dictionary = _ensure_homebase_direct_boarding_state(fireteam_id, normalized_craft_id)
			state["elapsed_seconds"] = _get_homebase_fireteam_boarding_total_seconds(fireteam_id)
			state["craft_id"] = normalized_craft_id
			_homebase_direct_boarding_state_by_fireteam_id[fireteam_id] = state
		seeded_count += 1
	if seeded_count <= 0:
		var fallback_fireteam_id: String = _get_first_seedable_homebase_fireteam_id()
		if not fallback_fireteam_id.is_empty():
			_add_homebase_direct_payload_fireteam_to_craft(fallback_fireteam_id, normalized_craft_id)
			if complete_boarding:
				var fallback_state: Dictionary = _ensure_homebase_direct_boarding_state(fallback_fireteam_id, normalized_craft_id)
				fallback_state["elapsed_seconds"] = _get_homebase_fireteam_boarding_total_seconds(fallback_fireteam_id)
				fallback_state["craft_id"] = normalized_craft_id
				_homebase_direct_boarding_state_by_fireteam_id[fallback_fireteam_id] = fallback_state
			set_meta("homebase_direct_launch_payload_fallback_seeded", true)
	if is_inside_tree():
		_refresh_homebase_direct_boarding_ui()


func _get_first_seedable_homebase_fireteam_id() -> String:
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var fireteam_id: String = _normalize_fireteam_id(String(Dictionary(definition_variant).get("id", "")))
		if fireteam_id.is_empty():
			continue
		if not _get_member_unit_ids_for_fireteam(fireteam_id).is_empty():
			return fireteam_id
	return ""


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
		"mission_drop_pilot_unit_id": String(drop_state.get("mission_drop_pilot_unit_id", "")).strip_edges(),
		"mission_drop_pilot_display_name": String(drop_state.get("mission_drop_pilot_display_name", "")).strip_edges(),
		"payload_fallback_seeded": bool(get_meta("homebase_direct_launch_payload_fallback_seeded", false)),
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
	if _operations_presenter != null:
		_operations_presenter.call("refresh")
		_sync_operations_visibility()


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
	custom_minimum_size = Vector2.ZERO
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
	var layout := get_native_r2_layout_snapshot()
	_r3_geometry_signature = _r3_homebase_geometry_signature()
	_apply_fixed_window_contract("Panel", layout.viewport)
	_apply_fixed_window_contract("DropLightTopbar", layout.topbar)
	_ensure_r2_briefing_scroll()
	_ensure_r2_briefing_toggle()
	_apply_r2_briefing_visibility()
	_apply_fixed_window_contract("Panel/Margin/VBox/MissionPanel", layout.mission_brief)
	for entry in [
		["Panel/Margin/VBox/ContentRow/RosterPanel", "roster"],
		["Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel", "fireteams"],
		["Panel/Margin/VBox/ContentRow/AircraftPanel", "flightdeck"],
	]:
		var panel := get_node_or_null(entry[0]) as Control
		if panel != null:
			panel.visible = not _r2_briefing_details_open
		_apply_fixed_window_contract(entry[0], layout[entry[1]])
	_retire_homebase_loadout_panel()
	_disable_legacy_homebase_window("Panel/Margin/VBox/ContentRow/TeamPanel", "homebase_legacy_transfer_window_disabled")
	_disable_legacy_homebase_window("Panel/Margin/VBox/ContentRow/InfoPanel", "homebase_legacy_character_sheet_window_disabled")
	_apply_character_popup_rect()
	_apply_r4_preparation_visuals(layout)
	_sync_operations_visibility()


func _apply_r4_preparation_visuals(layout: Dictionary) -> void:
	# Presentation follows the existing occupancy-driven rectangles. The image
	# occupies only free space below the real transport work area.
	for entry in [
		["Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel", 20, ""],
		["Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel", 20, ""],
		["Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel", 20, ""],
		["Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftHeaderLabel", 20, "dropship"],
	]:
		META_UI_SKIN_SCRIPT.style_preparation_heading(get_node_or_null(entry[0]) as Label, entry[1], entry[2])
	var title := get_node_or_null("DropLightTopbar/Margin/Row/TitleLabel") as Label
	if title != null:
		TACTICAL_UI_THEME_SCRIPT.style_screen_heading(title, 26)
	var deck: Rect2i = layout.flightdeck
	var viewport: Rect2i = layout.viewport
	var stage_top := deck.end.y + 12
	META_UI_SKIN_SCRIPT.update_frontier_stage(self, Rect2i(deck.position.x, stage_top, deck.size.x, maxi(0, viewport.size.y - stage_top - 16)), not _r2_briefing_details_open)


func get_native_r2_layout_snapshot() -> Dictionary:
	var viewport_size := Vector2i(get_viewport_rect().size)
	var usable_width := viewport_size.x - 64
	var roster_width := int(round(float(usable_width) * 0.25 / 8.0)) * 8
	var team_width := int(round(float(usable_width) * 0.28 / 8.0)) * 8
	var work_top := 192
	var work_height := maxi(200, viewport_size.y - work_top - 16)
	var counts := _r3_homebase_content_counts()
	var team_height := mini(work_height, 128 if counts.teams == 0 else 152 + counts.teams * 72 + counts.members * 82)
	var ship_rows := int(ceil(float(counts.craft) / float(_r3_ship_columns())))
	var transport_height := mini(work_height, 184 if counts.craft == 0 else 88 + ship_rows * 176 + counts.payload_teams * 80 + counts.payload_members * 24)
	return {
		"viewport": Rect2i(Vector2i.ZERO, viewport_size),
		"topbar": Rect2i(0, 0, viewport_size.x, 56),
		"mission_brief": Rect2i(16, 64, viewport_size.x - 32, viewport_size.y - 80 if _r2_briefing_details_open else 112),
		"roster": Rect2i(16, work_top, roster_width, work_height),
		"fireteams": Rect2i(32 + roster_width, work_top, team_width, team_height),
		"flightdeck": Rect2i(48 + roster_width + team_width, work_top, usable_width - roster_width - team_width, transport_height),
		"character_popup": Rect2i(viewport_size.x - mini(808, viewport_size.x - 32) - 16, 32, mini(808, viewport_size.x - 32), mini(840, viewport_size.y - 64)),
		"briefing_details_open": _r2_briefing_details_open,
		"ui_sets_gameplay_truth": false,
	}


func _r3_homebase_content_counts() -> Dictionary:
	var result := {"teams": 0, "members": 0, "craft": 0, "payload_teams": 0, "payload_members": 0}
	for definition: Dictionary in _fireteam_definitions:
		var fireteam_id := String(definition.get("id", ""))
		if _is_homebase_fireteam_in_flightdeck_payload(fireteam_id):
			continue
		result.teams += 1
		result.members += _get_member_unit_ids_for_fireteam(fireteam_id).size()
	var craft_definitions := _get_visible_homebase_aircraft_definitions()
	result.craft = craft_definitions.size()
	for craft: Dictionary in craft_definitions:
		var payload_ids := _get_homebase_direct_payload_fireteam_ids_for_craft(String(craft.get("craft_id", "")))
		result.payload_teams += payload_ids.size()
		result.payload_members += _build_unit_ids_for_fireteams(payload_ids).size()
	return result


func _r3_ship_columns() -> int:
	var usable_width := int(get_viewport_rect().size.x) - 64
	var roster_width := int(round(float(usable_width) * 0.25 / 8.0)) * 8
	var team_width := int(round(float(usable_width) * 0.28 / 8.0)) * 8
	return 2 if usable_width - roster_width - team_width >= int(HOMEBASE_SHIPCARD_COMPACT_WIDTH * 2 + 40) else 1


func _r3_homebase_geometry_signature() -> String:
	return "%s|%s|%s" % [get_viewport_rect().size, _r3_homebase_content_counts(), _r2_briefing_details_open]


func _queue_r3_homebase_geometry_if_changed() -> void:
	if _r3_geometry_signature != _r3_homebase_geometry_signature():
		call_deferred("_enforce_drop_light_fixed_layout")


func _on_r3_viewport_changed() -> void:
	if is_node_ready():
		_update_aircraft_panel()
	_enforce_drop_light_fixed_layout()


func _ensure_r2_briefing_scroll() -> void:
	var panel := get_node_or_null("Panel/Margin/VBox/MissionPanel") as PanelContainer
	if panel == null:
		return
	var old_margin := panel.get_node_or_null("MissionMargin") as MarginContainer
	if old_margin == null:
		return
	# Keep every existing briefing NodePath and callback. Only its presentation
	# wrapper changes so long recommendations cannot enlarge the bounded frame.
	var content := old_margin.get_node("MissionVBox") as VBoxContainer
	old_margin.remove_child(content)
	panel.remove_child(old_margin)
	old_margin.queue_free()
	var scroll := ScrollContainer.new()
	scroll.name = "MissionMargin"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)


func _ensure_r2_briefing_toggle() -> void:
	var header := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow") as HBoxContainer
	if header == null:
		return
	var button := header.get_node_or_null("R2BriefingDetailsButton") as Button
	if button == null:
		button = Button.new()
		button.name = "R2BriefingDetailsButton"
		button.custom_minimum_size = Vector2(144, 30)
		button.pressed.connect(_on_r2_briefing_details_pressed)
		header.add_child(button)
	button.text = "Zur Vorbereitung" if _r2_briefing_details_open else "Briefingdetails"
	button.tooltip_text = "Vollständiges Briefing, Empfehlungen und Bereitschaft anzeigen."
	META_UI_SKIN_SCRIPT.style_secondary_button(button)


func _on_r2_briefing_details_pressed() -> void:
	_r2_briefing_details_open = not _r2_briefing_details_open
	_update_mission_info()
	var scroll := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin") as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 0
	_enforce_drop_light_fixed_layout()


func _apply_r2_briefing_visibility(capture_source_visibility: bool = false) -> void:
	var vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	if vbox == null:
		return
	# Preserve the source updater's intended visibility while folding the whole
	# detail body. This avoids showing a clipped strip of its first large frame.
	var summary := vbox.get_node_or_null("R2PreparationStatus") as Label
	if summary == null:
		summary = Label.new()
		summary.name = "R2PreparationStatus"
		summary.clip_text = true
		summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		summary.add_theme_font_size_override("font_size", 12)
		vbox.add_child(summary)
		vbox.move_child(summary, 3)
	summary.text = String(_pre_mission_readiness_snapshot.get("summary_text", ""))
	summary.tooltip_text = summary.text
	for child in vbox.get_children():
		if not child is Control or child.name in ["HeaderRow", "MissionHeaderLabel", "MissionInfoRow", "R2PreparationStatus"]:
			continue
		var control := child as Control
		if capture_source_visibility or not control.has_meta("r3_detail_source_visible"):
			control.set_meta("r3_detail_source_visible", control.visible)
		control.visible = _r2_briefing_details_open and bool(control.get_meta("r3_detail_source_visible", false))
	for label_name in ["MissionHeaderLabel", "MissionSummaryLabel"]:
		var label := vbox.get_node_or_null(label_name) as Label
		if label != null:
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.max_lines_visible = -1 if _r2_briefing_details_open else 1
			label.tooltip_text = label.text
	var info_row := vbox.get_node_or_null("MissionInfoRow")
	if info_row != null:
		for child in info_row.get_children():
			if child is Label:
				(child as Label).clip_text = true
				(child as Label).text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				(child as Label).tooltip_text = (child as Label).text
		var technical_transfer := info_row.get_node_or_null("MissionTransferLabel") as Control
		if technical_transfer != null:
			technical_transfer.visible = _r2_briefing_details_open


func _restore_r3_briefing_source_visibility() -> void:
	var vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox")
	if vbox == null:
		return
	for child in vbox.get_children():
		if child is Control and child.has_meta("r3_detail_source_visible"):
			(child as Control).visible = bool(child.get_meta("r3_detail_source_visible"))


func _apply_fixed_window_contract(path: String, rect_variant: Variant) -> void:
	if typeof(rect_variant) != TYPE_RECT2I:
		return
	var control := get_node_or_null(path) as Control
	if control == null:
		return
	var rect: Rect2i = rect_variant
	var target := Rect2(Vector2(rect.position), Vector2(rect.size))
	if control.get_global_rect().is_equal_approx(target) and control.custom_minimum_size == Vector2(rect.size):
		return
	control.set_as_top_level(true)
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.custom_minimum_size = Vector2(float(rect.size.x), float(rect.size.y))
	control.position = Vector2(float(rect.position.x), float(rect.position.y))
	control.size = Vector2(float(rect.size.x), float(rect.size.y))
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
		label.text = "Sortieren"
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
	summary_label.max_lines_visible = 3
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
	var rect: Rect2i = get_native_r2_layout_snapshot().character_popup
	_apply_fixed_window_contract("CharacterSheetPopup", rect)
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
	title_label.text = "Heimatbasis"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(title_label, 14)
	row.add_child(title_label)

	for badge_text in ["Personal", "Trupps", "Ausrüstung", "Transport"]:
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
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel": "Einsatzvorbereitung",
		"Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterHeaderLabel": "Personalreserve",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHeaderRow/TeamHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_TRANSFER_TEAM,
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_INBOUND_TO_FOB,
		"Panel/Margin/VBox/ContentRow/HomebaseFireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel": "Trupps",
		"Panel/Margin/VBox/ContentRow/HomebaseLoadoutPanel/LoadoutMargin/LoadoutVBox/LoadoutHeaderRow/LoadoutHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_LOADOUT,
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftHeaderLabel": "Transport",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_DECK_ACTIVITY,
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/InfoHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_CHARACTER_SHEET,
		"CharacterSheetPopup/PopupPanel/PopupMargin/PopupVBox/PopupHeaderRow/PopupHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_CHARACTER_POPUP,
	}
	for path_variant in label_text_by_path.keys():
		var label := get_node_or_null(String(path_variant)) as Label
		if label != null:
			label.text = String(label_text_by_path[path_variant])
	var nav := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/NavButtonRow/HomebaseNavButton") as Button
	if nav != null:
		nav.text = "Heimatbasis"


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
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefHomebaseSummaryLabel",
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
	# The pooled card may have the old 316px minimum from a previous setup.
	# Let the existing compact layout fill the actual roster viewport instead.
	card.custom_minimum_size = Vector2(0.0, HOMEBASE_OPERATOR_CARD_SIZE.y)
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
			"fixed_size": false,
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
		fireteam_list.add_child(_build_empty_state_label("Noch kein Trupp. Mit + einen Trupp anlegen."))
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
		fireteam_list.add_child(_build_empty_state_label("Alle Trupps sind im Transport. Dort bleiben sie auswählbar."))


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
	_restore_r3_briefing_source_visibility()
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
	mission_team_limit_label.text = _build_mission_slot_status_text(mission_slot_usage, pilot_count, direct_payload_operator_count, direct_payload_fireteam_count)
	mission_team_limit_label.tooltip_text = mission_team_limit_label.text
	mission_team_limit_label.text = "Einsatz: %d Kräfte · %d Trupps · %d Piloten" % [direct_payload_operator_count, direct_payload_fireteam_count, pilot_count] if _should_use_homebase_direct_mission_copy() else "Auswahl: %d/%d · Piloten: %d" % [staged_count, team_capacity, pilot_count]
	mission_team_limit_label.set_meta("mission_slot_usage_count", mission_slot_usage)
	mission_team_limit_label.set_meta("mission_operator_count", staged_count)
	mission_team_limit_label.set_meta("mission_pilot_count", pilot_count)
	mission_team_limit_label.set_meta("homebase_direct_payload_operator_count", direct_payload_operator_count)
	mission_team_limit_label.set_meta("homebase_direct_payload_fireteam_count", direct_payload_fireteam_count)
	var launch_text: String = _mission_launch_summary if not _mission_launch_summary.is_empty() else ("Homebase dropship ready" if direct_payload_ready else ("Dropship ready for launch" if _mission_launch_ready else "Dropship not launch-ready"))
	mission_transfer_label.text = _build_mission_transfer_status_text(staged_count, team_capacity, pilot_count, launch_text, direct_payload_status_text, direct_payload_ready, can_start_mission)
	mission_transfer_label.set_meta("homebase_direct_payload_ready", direct_payload_ready)
	mission_transfer_label.set_meta("homebase_direct_payload_operator_count", direct_payload_operator_count)
	mission_transfer_label.set_meta("homebase_direct_boarded_operator_count", direct_boarded_operator_count)
	mission_transfer_label.set_meta("homebase_direct_boarding_progress_ratio", _get_homebase_direct_boarding_progress_ratio())
	mission_transfer_label.set_meta("homebase_direct_payload_fireteam_count", direct_payload_fireteam_count)
	mission_transfer_label.set_meta("homebase_direct_payload_status_text", direct_payload_status_text)
	mission_summary_label.text = _build_mission_summary_text(staged_count, team_capacity, pilot_count, mission_slot_usage)
	if not _mission_launch_summary.is_empty() and not _should_use_homebase_direct_mission_copy():
		mission_summary_label.text = "%s\n%s" % [mission_summary_label.text, _mission_launch_summary]
	mission_summary_label.set_meta("homebase_direct_payload_ready", direct_payload_ready)
	mission_summary_label.set_meta("homebase_direct_payload_operator_count", direct_payload_operator_count)
	mission_summary_label.set_meta("homebase_direct_boarded_operator_count", direct_boarded_operator_count)
	mission_summary_label.set_meta("homebase_direct_boarding_progress_ratio", _get_homebase_direct_boarding_progress_ratio())
	mission_summary_label.set_meta("homebase_direct_payload_fireteam_count", direct_payload_fireteam_count)
	mission_summary_label.set_meta("homebase_direct_payload_status_text", direct_payload_status_text)
	_update_personnel_notifications()
	_update_post_debrief_homebase_summary()
	_update_mission_briefing_panel()
	_update_pre_mission_readiness_panel()
	_update_next_sortie_readiness_summary()
	_apply_post_debrief_density_findings()
	var preparation_status := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/R2PreparationStatus") as Label
	if preparation_status != null:
		preparation_status.text = String(_pre_mission_readiness_snapshot.get("summary_text", ""))
		preparation_status.tooltip_text = preparation_status.text
	_apply_r2_briefing_visibility(true)


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


func _update_post_debrief_homebase_summary() -> void:
	_ensure_post_debrief_followup_title_label()
	var label := _ensure_post_debrief_homebase_summary_label()
	var summary_text: String = _build_post_debrief_homebase_summary_text()
	if summary_text.is_empty():
		label.visible = false
		label.text = ""
		_sync_post_debrief_followup_panel_visibility()
		return
	label.visible = true
	label.text = summary_text
	label.tooltip_text = "Read-only summary of the last mission result carried back from Debrief."
	label.set_meta("frontier_probe_post_debrief_homebase_summary", _is_frontier_probe_last_result())
	label.set_meta("frontier_probe_result_present", _is_frontier_probe_last_result())
	label.set_meta("station_scenario_post_debrief_homebase_summary", _is_station_scenario_last_result())
	label.set_meta("station_result_present", _is_station_scenario_last_result())
	label.set_meta("post_debrief_homebase_result_text", _build_post_debrief_homebase_result_text())
	label.set_meta("post_debrief_homebase_next_step_text", _build_post_debrief_homebase_next_step_text())
	label.set_meta("homebase_followup_emphasis", true)
	label.set_meta("homebase_followup_style_id", HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID)
	_sync_post_debrief_followup_panel_visibility()


func _update_next_sortie_readiness_summary() -> void:
	var label := _ensure_next_sortie_readiness_label()
	var readiness: Dictionary = _pre_mission_readiness_snapshot.duplicate(true)
	var staging: Dictionary = get_homebase_direct_staging_snapshot()
	var steps: Array = _build_next_sortie_readiness_steps(readiness, staging)
	var current_step_id: String = _resolve_next_sortie_current_step_id(readiness, staging)
	var line: String = _build_next_sortie_readiness_line(steps, current_step_id, _is_station_scenario_last_result())
	if line.is_empty():
		label.visible = false
		label.text = ""
		_sync_post_debrief_followup_panel_visibility()
		return
	label.visible = true
	label.text = line
	label.tooltip_text = "Read-only next-sortie readiness built from Homebase staging and readiness snapshots."
	label.set_meta("frontier_probe_homebase_next_sortie_readiness", _is_frontier_probe_last_result())
	label.set_meta("station_scenario_homebase_next_sortie_readiness", _is_station_scenario_last_result())
	label.set_meta("current_next_step_id", current_step_id)
	label.set_meta("readiness_step_count", steps.size())
	label.set_meta("readiness_line", line)
	label.set_meta("homebase_followup_emphasis", true)
	label.set_meta("homebase_followup_style_id", HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID)
	_update_station_return_panel_polish(steps, current_step_id)
	_sync_post_debrief_followup_panel_visibility()


func _ensure_post_debrief_followup_panel() -> PanelContainer:
	var mission_vbox := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	var existing := mission_vbox.get_node_or_null("PostDebriefFollowupPanel") as PanelContainer
	if existing != null:
		return existing
	var panel := PanelContainer.new()
	panel.name = "PostDebriefFollowupPanel"
	panel.custom_minimum_size = Vector2(0.0, HOMEBASE_POST_DEBRIEF_FOLLOWUP_MIN_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.visible = false
	panel.add_theme_stylebox_override("panel", _build_post_debrief_followup_panel_style())
	panel.set_meta("homebase_followup_style_id", HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID)
	panel.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	panel.set_meta("read_only", true)
	panel.set_meta("ui_sets_gameplay_truth", false)
	var margin := MarginContainer.new()
	margin.name = "FollowupMargin"
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "FollowupVBox"
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	mission_vbox.add_child(panel)
	var readiness_panel := mission_vbox.get_node_or_null("PreMissionReadinessPanel")
	if readiness_panel != null:
		mission_vbox.move_child(panel, readiness_panel.get_index() + 1)
	else:
		var briefing_panel := mission_vbox.get_node_or_null("MissionBriefingPanel")
		if briefing_panel != null:
			mission_vbox.move_child(panel, briefing_panel.get_index() + 1)
	return panel


func _ensure_post_debrief_followup_title_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("ReturnPanelTitleLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "ReturnPanelTitleLabel"
	label.text = "Rueckkehr abgeschlossen"
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", 13)
	META_UI_SKIN_SCRIPT.style_body_label(label, 13)
	label.add_theme_color_override("font_color", Color("f2d88f"))
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	vbox.add_child(label)
	vbox.move_child(label, 0)
	return label


func _ensure_post_debrief_followup_action_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("ReturnPanelActionLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "ReturnPanelActionLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE)
	META_UI_SKIN_SCRIPT.style_body_label(label, HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE)
	label.add_theme_color_override("font_color", Color("e8f2ff"))
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	vbox.add_child(label)
	vbox.move_child(label, 1)
	return label


func _ensure_post_debrief_followup_step_chip_row() -> HBoxContainer:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("ReturnPanelStepChipRow") as HBoxContainer
	if existing != null:
		return existing
	var row := HBoxContainer.new()
	row.name = "ReturnPanelStepChipRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 4)
	row.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	row.set_meta("read_only", true)
	vbox.add_child(row)
	vbox.move_child(row, 2)
	return row


func _ensure_station_reentry_plan_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("StationReentryPlanLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "StationReentryPlanLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(label, 11)
	label.add_theme_color_override("font_color", Color("b8e9ff"))
	label.set_meta("station_reentry_plan_style_id", HOMEBASE_REENTRY_PLAN_STYLE_ID)
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	label.set_meta("ui_sets_gameplay_truth", false)
	vbox.add_child(label)
	vbox.move_child(label, 3)
	return label


func _ensure_station_reentry_fireteam_staging_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("StationReentryFireteamStagingLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "StationReentryFireteamStagingLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(label, 11)
	label.add_theme_color_override("font_color", Color("d3f4c7"))
	label.set_meta("station_reentry_fireteam_staging_style_id", HOMEBASE_REENTRY_FIRETEAM_STAGING_STYLE_ID)
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	label.set_meta("ui_sets_gameplay_truth", false)
	vbox.add_child(label)
	vbox.move_child(label, mini(4, vbox.get_child_count() - 1))
	return label


func _ensure_station_reentry_loadout_bridge_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("StationReentryLoadoutBridgeLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "StationReentryLoadoutBridgeLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(label, 11)
	label.add_theme_color_override("font_color", Color("f2e3a2"))
	label.set_meta("station_reentry_loadout_bridge_style_id", HOMEBASE_REENTRY_LOADOUT_BRIDGE_STYLE_ID)
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	label.set_meta("ui_sets_gameplay_truth", false)
	vbox.add_child(label)
	vbox.move_child(label, mini(5, vbox.get_child_count() - 1))
	return label


func _ensure_station_reentry_dropship_boarding_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("StationReentryDropshipBoardingLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "StationReentryDropshipBoardingLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(label, 11)
	label.add_theme_color_override("font_color", Color("ffd4a8"))
	label.set_meta("station_reentry_dropship_boarding_style_id", HOMEBASE_REENTRY_DROPSHIP_BOARDING_STYLE_ID)
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	label.set_meta("ui_sets_gameplay_truth", false)
	vbox.add_child(label)
	vbox.move_child(label, mini(6, vbox.get_child_count() - 1))
	return label


func _ensure_station_reentry_start_permission_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("StationReentryStartPermissionLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "StationReentryStartPermissionLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 18.0)
	label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(label, 11)
	label.add_theme_color_override("font_color", Color("f5e6a8"))
	label.set_meta("station_reentry_start_permission_style_id", HOMEBASE_REENTRY_START_PERMISSION_STYLE_ID)
	label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
	label.set_meta("read_only", true)
	label.set_meta("ui_sets_gameplay_truth", false)
	vbox.add_child(label)
	vbox.move_child(label, mini(7, vbox.get_child_count() - 1))
	return label


func _ensure_post_debrief_homebase_summary_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("PostDebriefHomebaseSummaryLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "PostDebriefHomebaseSummaryLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 20.0)
	label.add_theme_font_size_override("font_size", HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE)
	META_UI_SKIN_SCRIPT.style_body_label(label, HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE)
	label.add_theme_color_override("font_color", Color("c7f2df"))
	label.set_meta("homebase_followup_emphasis", true)
	label.set_meta("homebase_followup_style_id", HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID)
	vbox.add_child(label)
	return label


func _ensure_next_sortie_readiness_label() -> Label:
	var vbox := _get_post_debrief_followup_vbox()
	var existing := vbox.get_node_or_null("NextSortieReadinessLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "NextSortieReadinessLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size = Vector2(0.0, 20.0)
	label.add_theme_font_size_override("font_size", HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE)
	META_UI_SKIN_SCRIPT.style_body_label(label, HOMEBASE_POST_DEBRIEF_FOLLOWUP_FONT_SIZE)
	label.add_theme_color_override("font_color", Color("d6e9ff"))
	label.set_meta("homebase_followup_emphasis", true)
	label.set_meta("homebase_followup_style_id", HOMEBASE_POST_DEBRIEF_FOLLOWUP_STYLE_ID)
	vbox.add_child(label)
	return label


func _get_post_debrief_homebase_summary_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/PostDebriefHomebaseSummaryLabel") as Label


func _get_next_sortie_readiness_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/NextSortieReadinessLabel") as Label


func _get_post_debrief_followup_title_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/ReturnPanelTitleLabel") as Label


func _get_post_debrief_followup_action_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/ReturnPanelActionLabel") as Label


func _get_post_debrief_followup_step_chip_row() -> HBoxContainer:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/ReturnPanelStepChipRow") as HBoxContainer


func _get_station_reentry_plan_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/StationReentryPlanLabel") as Label


func _get_station_reentry_fireteam_staging_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/StationReentryFireteamStagingLabel") as Label


func _get_station_reentry_loadout_bridge_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/StationReentryLoadoutBridgeLabel") as Label


func _get_station_reentry_dropship_boarding_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/StationReentryDropshipBoardingLabel") as Label


func _get_station_reentry_start_permission_label() -> Label:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel/FollowupMargin/FollowupVBox/StationReentryStartPermissionLabel") as Label


func _get_post_debrief_followup_panel() -> PanelContainer:
	return get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PostDebriefFollowupPanel") as PanelContainer


func _get_post_debrief_followup_vbox() -> VBoxContainer:
	var panel := _ensure_post_debrief_followup_panel()
	return panel.get_node("FollowupMargin/FollowupVBox") as VBoxContainer


func _sync_post_debrief_followup_panel_visibility() -> void:
	var panel := _get_post_debrief_followup_panel()
	if panel == null:
		return
	var post_label := _get_post_debrief_homebase_summary_label()
	var readiness_label := _get_next_sortie_readiness_label()
	var post_intends_visible: bool = post_label != null and post_label.visible and not post_label.text.strip_edges().is_empty()
	var readiness_intends_visible: bool = readiness_label != null and readiness_label.visible and not readiness_label.text.strip_edges().is_empty()
	panel.visible = post_intends_visible or readiness_intends_visible
	var title_label := _get_post_debrief_followup_title_label()
	if title_label != null:
		title_label.visible = panel.visible and _is_station_scenario_last_result()
	var action_label := _get_post_debrief_followup_action_label()
	if action_label != null:
		action_label.visible = panel.visible and _is_station_scenario_last_result()
	var chip_row := _get_post_debrief_followup_step_chip_row()
	if chip_row != null:
		chip_row.visible = panel.visible and _is_station_scenario_last_result()
	var reentry_label := _get_station_reentry_plan_label()
	if reentry_label != null:
		reentry_label.visible = panel.visible and _is_station_scenario_last_result()
	var reentry_staging_label := _get_station_reentry_fireteam_staging_label()
	if reentry_staging_label != null:
		reentry_staging_label.visible = panel.visible and _is_station_scenario_last_result()
	var reentry_loadout_label := _get_station_reentry_loadout_bridge_label()
	if reentry_loadout_label != null:
		reentry_loadout_label.visible = panel.visible and _is_station_scenario_last_result()
	var reentry_boarding_label := _get_station_reentry_dropship_boarding_label()
	if reentry_boarding_label != null:
		reentry_boarding_label.visible = panel.visible and _is_station_scenario_last_result()
	var reentry_start_label := _get_station_reentry_start_permission_label()
	if reentry_start_label != null:
		reentry_start_label.visible = panel.visible and _is_station_scenario_last_result()
	_apply_post_debrief_density_findings()


func _apply_post_debrief_density_findings() -> void:
	var summary_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	if summary_label == null:
		return
	var followup_panel := _get_post_debrief_followup_panel()
	var should_collapse: bool = (_is_frontier_probe_last_result() or _is_station_scenario_last_result()) and _control_is_visible(followup_panel)
	summary_label.set_meta("homebase_density_summary_collapsed", should_collapse)
	summary_label.set_meta("homebase_density_findings_style_id", HOMEBASE_POST_DEBRIEF_DENSITY_FINDINGS_STYLE_ID if should_collapse else "")
	if should_collapse:
		summary_label.visible = false
		summary_label.tooltip_text = "Collapsed while the post-Debrief follow-up panel carries the result and next sortie."
		return
	summary_label.visible = true


func _build_post_debrief_followup_panel_style() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.045, 0.085, 0.095, 0.96)
	stylebox.border_color = Color(0.32, 0.72, 0.72, 0.84)
	stylebox.border_width_left = 3
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.content_margin_left = 4
	stylebox.content_margin_right = 4
	stylebox.content_margin_top = 4
	stylebox.content_margin_bottom = 4
	return stylebox


func _update_station_return_panel_polish(steps: Array, current_step_id: String) -> void:
	var title_label := _ensure_post_debrief_followup_title_label()
	var action_label := _ensure_post_debrief_followup_action_label()
	var chip_row := _ensure_post_debrief_followup_step_chip_row()
	var reentry_label := _ensure_station_reentry_plan_label()
	var reentry_staging_label := _ensure_station_reentry_fireteam_staging_label()
	var reentry_loadout_label := _ensure_station_reentry_loadout_bridge_label()
	var reentry_boarding_label := _ensure_station_reentry_dropship_boarding_label()
	var reentry_start_label := _ensure_station_reentry_start_permission_label()
	var station_result: bool = _is_station_scenario_last_result()
	title_label.visible = station_result
	action_label.visible = station_result
	chip_row.visible = station_result
	reentry_label.visible = station_result
	reentry_staging_label.visible = station_result
	reentry_loadout_label.visible = station_result
	reentry_boarding_label.visible = station_result
	reentry_start_label.visible = station_result
	if not station_result:
		action_label.text = ""
		reentry_label.text = ""
		reentry_staging_label.text = ""
		reentry_loadout_label.text = ""
		reentry_boarding_label.text = ""
		reentry_start_label.text = ""
		_clear_return_panel_step_chips(chip_row)
		return
	var current_label: String = _station_next_sortie_step_label(current_step_id)
	action_label.text = "Naechster Auftrag: %s" % current_label
	action_label.tooltip_text = "Read-only: aktueller Homebase-Schritt aus Readiness- und Staging-Snapshot."
	reentry_label.text = HOMEBASE_REENTRY_PLAN_LINE
	reentry_label.tooltip_text = "Read-only: Reentry-Orientierung aus dem Station-Return-Panel; Start und GO bleiben separate bestaetigte Schritte."
	var staging: Dictionary = get_homebase_direct_staging_snapshot()
	reentry_staging_label.text = _build_station_reentry_fireteam_staging_line(staging)
	reentry_staging_label.tooltip_text = "Read-only: Fireteam-Staging aus Homebase-Direct-Staging-Snapshot; Drop und Start bleiben bestaetigte Aktionen."
	reentry_staging_label.set_meta("station_reentry_fireteam_staging_text", reentry_staging_label.text)
	reentry_staging_label.set_meta("station_reentry_fireteam_staging_style_id", HOMEBASE_REENTRY_FIRETEAM_STAGING_STYLE_ID)
	reentry_staging_label.set_meta("selected_fireteam_count", _count_unique_nonempty_strings(Array(staging.get("selected_fireteam_ids", []))))
	reentry_staging_label.set_meta("selected_operator_count", Array(staging.get("selected_unit_ids", [])).size())
	reentry_staging_label.set_meta("payload_fireteam_count", Array(staging.get("payload_fireteam_ids", [])).size())
	reentry_staging_label.set_meta("payload_operator_count", int(staging.get("payload_operator_count", 0)))
	reentry_staging_label.set_meta("boarded_operator_count", int(staging.get("boarded_operator_count", 0)))
	var readiness: Dictionary = get_pre_mission_readiness_snapshot()
	var loadout_item: Dictionary = _find_readiness_item(Array(readiness.get("items", [])), "loadout")
	reentry_loadout_label.text = _build_station_reentry_loadout_bridge_line(loadout_item)
	reentry_loadout_label.tooltip_text = "Read-only: Loadout-Status aus PreMissionReadiness; Aenderungen bleiben im bestehenden Loadout-Panel."
	reentry_loadout_label.set_meta("station_reentry_loadout_bridge_text", reentry_loadout_label.text)
	reentry_loadout_label.set_meta("station_reentry_loadout_bridge_style_id", HOMEBASE_REENTRY_LOADOUT_BRIDGE_STYLE_ID)
	reentry_loadout_label.set_meta("loadout_state", String(loadout_item.get("state", "")).strip_edges())
	reentry_loadout_label.set_meta("loadout_detail", String(loadout_item.get("detail", "")).strip_edges())
	var dropship_item: Dictionary = _find_readiness_item(Array(readiness.get("items", [])), "dropship")
	var boarding_item: Dictionary = _find_readiness_item(Array(readiness.get("items", [])), "boarding")
	reentry_boarding_label.text = _build_station_reentry_dropship_boarding_line(dropship_item, boarding_item, staging)
	reentry_boarding_label.tooltip_text = "Read-only: Dropship- und Boarding-Stand aus PreMissionReadiness und Homebase-Direct-Staging."
	reentry_boarding_label.set_meta("station_reentry_dropship_boarding_text", reentry_boarding_label.text)
	reentry_boarding_label.set_meta("station_reentry_dropship_boarding_style_id", HOMEBASE_REENTRY_DROPSHIP_BOARDING_STYLE_ID)
	reentry_boarding_label.set_meta("dropship_state", String(dropship_item.get("state", "")).strip_edges())
	reentry_boarding_label.set_meta("boarding_state", String(boarding_item.get("state", "")).strip_edges())
	reentry_boarding_label.set_meta("payload_operator_count", int(staging.get("payload_operator_count", 0)))
	reentry_boarding_label.set_meta("boarded_operator_count", int(staging.get("boarded_operator_count", 0)))
	var start_item: Dictionary = _find_readiness_item(Array(readiness.get("items", [])), "start")
	reentry_start_label.text = _build_station_reentry_start_permission_line(start_item, readiness)
	reentry_start_label.tooltip_text = "Read-only: Startfreigabe aus PreMissionReadiness und bestehendem Startbutton."
	reentry_start_label.set_meta("station_reentry_start_permission_text", reentry_start_label.text)
	reentry_start_label.set_meta("station_reentry_start_permission_style_id", HOMEBASE_REENTRY_START_PERMISSION_STYLE_ID)
	reentry_start_label.set_meta("start_state", String(start_item.get("state", "")).strip_edges())
	reentry_start_label.set_meta("can_start", bool(readiness.get("can_start", false)))
	_refresh_return_panel_step_chips(chip_row, steps, current_step_id)


func _build_station_reentry_fireteam_staging_line(staging: Dictionary) -> String:
	var selected_fireteam_count: int = _count_unique_nonempty_strings(Array(staging.get("selected_fireteam_ids", [])))
	var selected_operator_count: int = Array(staging.get("selected_unit_ids", [])).size()
	var payload_fireteam_count: int = Array(staging.get("payload_fireteam_ids", [])).size()
	var payload_operator_count: int = int(staging.get("payload_operator_count", 0))
	var boarded_operator_count: int = int(staging.get("boarded_operator_count", 0))
	if payload_fireteam_count > 0:
		var expected_operator_count: int = maxi(payload_operator_count, selected_operator_count)
		return "Fireteam-Staging: %d FT im Dropship | %d/%d Operatoren an Bord | Start nach Boarding" % [payload_fireteam_count, boarded_operator_count, expected_operator_count]
	if selected_fireteam_count > 0 or selected_operator_count > 0:
		return "Fireteam-Staging: %d FT bereit | %d Operatoren | Dropship beladen" % [selected_fireteam_count, selected_operator_count]
	return "Fireteam-Staging: 0 FT bereit | 0 Operatoren | Fireteam bereitstellen"


func _count_unique_nonempty_strings(values: Array) -> int:
	var seen: Dictionary = {}
	for value_variant in values:
		var value: String = String(value_variant).strip_edges().to_lower()
		if value.is_empty():
			continue
		seen[value] = true
	return seen.size()


func _find_readiness_item(items: Array, item_id: String) -> Dictionary:
	var normalized_item_id: String = item_id.strip_edges()
	if normalized_item_id.is_empty():
		return {}
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(item_variant)
		if String(item.get("id", "")).strip_edges() == normalized_item_id:
			return item.duplicate(true)
	return {}


func _build_station_reentry_loadout_bridge_line(loadout_item: Dictionary) -> String:
	var state: String = String(loadout_item.get("state", "warn")).strip_edges()
	var detail: String = _compact_station_reentry_loadout_detail(String(loadout_item.get("detail", "")).strip_edges())
	var badge: String = "OK" if state == "ready" else "Hinweis" if state == "warn" else "Blocker"
	if detail.is_empty():
		detail = "Loadout pruefen"
	return "Loadout-Check: %s | %s" % [badge, detail]


func _compact_station_reentry_loadout_detail(detail: String) -> String:
	if detail.contains("Briefing-Empfehlung"):
		return "Empfehlung angewendet"
	if detail.contains("Standard-/manuelle"):
		return "Standard/manuell vorhanden, Empfehlung offen"
	if detail.contains("noch nicht sichtbar"):
		return "Payload-Loadouts pruefen"
	if detail.length() <= 58:
		return detail
	return "%s..." % detail.substr(0, 55).strip_edges()


func _build_station_reentry_dropship_boarding_line(dropship_item: Dictionary, boarding_item: Dictionary, staging: Dictionary) -> String:
	var dropship_state: String = String(dropship_item.get("state", "blocked")).strip_edges()
	var boarding_state: String = String(boarding_item.get("state", "blocked")).strip_edges()
	var payload_count: int = int(staging.get("payload_operator_count", 0))
	var boarded_count: int = int(staging.get("boarded_operator_count", 0))
	var dropship_badge: String = "OK" if dropship_state == "ready" else "Blocker" if dropship_state == "blocked" else "Hinweis"
	var boarding_badge: String = "OK" if boarding_state == "ready" else "Blocker" if boarding_state == "blocked" else "Hinweis"
	if payload_count > 0:
		return "Dropship: %s | Boarding: %s %d/%d Operatoren" % [dropship_badge, boarding_badge, boarded_count, payload_count]
	return "Dropship: %s | Boarding: %s | Payload fehlt" % [dropship_badge, boarding_badge]


func _build_station_reentry_start_permission_line(start_item: Dictionary, readiness: Dictionary) -> String:
	var start_state: String = String(start_item.get("state", "blocked")).strip_edges()
	var detail: String = String(start_item.get("detail", "")).strip_edges()
	var can_start: bool = bool(readiness.get("can_start", false))
	var badge: String = "OK" if can_start and start_state == "ready" else "Blockiert" if start_state == "blocked" else "Hinweis"
	if detail.is_empty():
		detail = "Startbutton darf Mission ausloesen." if can_start else "Startbutton bleibt blockiert."
	return "Startfreigabe: %s | %s" % [badge, _compact_station_reentry_start_detail(detail)]


func _compact_station_reentry_start_detail(detail: String) -> String:
	if detail.length() <= 74:
		return detail
	return "%s..." % detail.substr(0, 71).strip_edges()


func _refresh_return_panel_step_chips(row: HBoxContainer, steps: Array, current_step_id: String) -> void:
	_clear_return_panel_step_chips(row)
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		var step_id: String = String(step.get("id", "")).strip_edges()
		if step_id.is_empty():
			continue
		var label := Label.new()
		label.name = "StepChip_%s" % step_id
		label.text = _station_next_sortie_step_label(step_id)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size = Vector2(78.0, 18.0)
		label.add_theme_font_size_override("font_size", 9)
		META_UI_SKIN_SCRIPT.style_body_label(label, 9)
		var state: String = String(step.get("state", "pending")).strip_edges()
		if step_id == current_step_id:
			state = "current"
		label.add_theme_color_override("font_color", _return_panel_chip_text_color(state))
		label.set_meta("homebase_return_panel_style_id", HOMEBASE_RETURN_PANEL_POLISH_STYLE_ID)
		label.set_meta("step_id", step_id)
		label.set_meta("step_state", state)
		label.set_meta("read_only", true)
		row.add_child(label)


func _clear_return_panel_step_chips(row: HBoxContainer) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()


func _return_panel_chip_text_color(state: String) -> Color:
	match state:
		"ready":
			return Color("93d8a5")
		"current":
			return Color("f2d88f")
		_:
			return Color("9fb1bd")


func _build_station_return_panel_step_chip_snapshot(steps: Array) -> Array:
	var chips: Array = []
	var row := _get_post_debrief_followup_step_chip_row()
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		var step_id: String = String(step.get("id", "")).strip_edges()
		if step_id.is_empty():
			continue
		var node: Label = null
		if row != null:
			node = row.get_node_or_null("StepChip_%s" % step_id) as Label
		chips.append({
			"id": step_id,
			"label": node.text.strip_edges() if node != null else _station_next_sortie_step_label(step_id),
			"state": String(node.get_meta("step_state", step.get("state", ""))) if node != null else String(step.get("state", "")),
			"visible": _control_is_visible(node),
			"read_only": bool(node.get_meta("read_only", false)) if node != null else false,
		})
	return chips


func _station_return_panel_chip_state_exists(chips: Array, step_id: String, expected_state: String) -> bool:
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		if String(chip.get("id", "")) == step_id and String(chip.get("state", "")) == expected_state:
			return true
	return false


func _station_return_panel_chips_have_german_labels(chips: Array) -> bool:
	var expected: PackedStringArray = PackedStringArray(["Auswertung ansehen", "Fireteam bereitstellen", "Loadout pruefen", "Dropship beladen", "Start freigeben"])
	for expected_label in expected:
		var found: bool = false
		for chip_variant in chips:
			if String(Dictionary(chip_variant).get("label", "")) == expected_label:
				found = true
				break
		if not found:
			return false
	return true


func _build_missionpanel_density_sections(mission_vbox: Control, mission_rect: Rect2) -> Array:
	var sections: Array = []
	if mission_vbox == null:
		return sections
	for child in mission_vbox.get_children():
		var control := child as Control
		if control == null or not _control_is_visible(control):
			continue
		var rect: Rect2 = _control_global_rect(control)
		sections.append({
			"name": control.name,
			"rect": _rect_to_dict(rect),
			"inside_mission_panel": _rect_inside(rect, mission_rect),
			"text_length": _collect_visible_text_length(control),
			"child_count": control.get_child_count(),
		})
	return sections


func _collect_visible_text_length(root_node: Node) -> int:
	if root_node == null:
		return 0
	var total: int = 0
	var root_control := root_node as Control
	if root_control != null and not _control_is_visible(root_control):
		return 0
	if root_node is Label:
		total += (root_node as Label).text.strip_edges().length()
	elif root_node is Button:
		total += (root_node as Button).text.strip_edges().length()
	elif root_node is LineEdit:
		total += (root_node as LineEdit).text.strip_edges().length()
	for child in root_node.get_children():
		total += _collect_visible_text_length(child)
	return total


func _build_post_debrief_homebase_summary_text() -> String:
	if _last_mission_result_summary.is_empty():
		return ""
	if not _is_frontier_probe_last_result() and not _is_station_scenario_last_result():
		return ""
	var result_text: String = _build_post_debrief_homebase_result_text()
	var next_step_text: String = _build_post_debrief_homebase_next_step_text()
	if result_text.is_empty() or next_step_text.is_empty():
		return ""
	return "Debrief complete -> Homebase | %s | Next: %s" % [result_text, next_step_text]


func _build_post_debrief_homebase_result_text() -> String:
	if _last_mission_result_summary.is_empty():
		return ""
	var outcome: String = String(_last_mission_result_summary.get("result", "ended")).strip_edges()
	if outcome.is_empty():
		outcome = String(_last_mission_result_summary.get("mission_outcome", "ended")).strip_edges()
	var route_label: String = "Station Drill" if _is_station_scenario_last_result() else "Frontier Probe"
	var win_condition: String = String(_last_mission_result_summary.get("win_condition_type", "")).strip_edges()
	var duration_seconds: int = int(round(float(_last_mission_result_summary.get("duration_seconds", 0.0))))
	var parts: PackedStringArray = PackedStringArray([route_label, outcome.to_upper()])
	if not win_condition.is_empty():
		parts.append(win_condition)
	if duration_seconds > 0:
		parts.append("%ds" % duration_seconds)
	return " / ".join(Array(parts))


func _build_post_debrief_homebase_next_step_text() -> String:
	var award_summary: Dictionary = Dictionary(_last_mission_result_summary.get("progression_award_summary", {}))
	if int(award_summary.get("total_xp_delta", 0)) > 0 or Array(award_summary.get("listed_awards", [])).size() > 0:
		return "review roster gains"
	return "prep next sortie"


func _build_next_sortie_readiness_steps(readiness: Dictionary, staging: Dictionary) -> Array:
	if not _supports_next_sortie_readiness_last_result():
		return []
	var current_step_id: String = _resolve_next_sortie_current_step_id(readiness, staging)
	return [
		_make_next_sortie_step("review_roster_gains", "Review gains", _has_last_result_progression_awards(), current_step_id),
		_make_next_sortie_step("stage_fireteam", "Stage fireteam", int(staging.get("payload_operator_count", 0)) > 0, current_step_id),
		_make_next_sortie_step("assign_loadout", "Assign loadout", _readiness_item_is_ready(readiness, "loadout"), current_step_id),
		_make_next_sortie_step("prepare_transport", "Load dropship", bool(staging.get("drop_ship_staged", false)) or bool(staging.get("homebase_direct_craft_ready", false)), current_step_id),
		_make_next_sortie_step("start_next_sortie", "Start next sortie", can_request_mission_start(), current_step_id),
	]


func _make_next_sortie_step(id: String, label: String, ready: bool, current_step_id: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"ready": ready,
		"state": "current" if id == current_step_id else "ready" if ready else "pending",
		"current": id == current_step_id,
	}


func _resolve_next_sortie_current_step_id(readiness: Dictionary, staging: Dictionary) -> String:
	if not _supports_next_sortie_readiness_last_result():
		return ""
	if int(staging.get("payload_operator_count", 0)) <= 0:
		return "stage_fireteam"
	if not _readiness_item_is_ready(readiness, "loadout"):
		return "assign_loadout"
	if not bool(staging.get("drop_ship_staged", false)) or not bool(staging.get("homebase_direct_craft_ready", false)):
		return "prepare_transport"
	return "start_next_sortie"


func _build_next_sortie_readiness_line(steps: Array, current_step_id: String, station_microcopy: bool = false) -> String:
	if steps.is_empty() or current_step_id.is_empty():
		return ""
	if station_microcopy:
		return _build_station_next_sortie_readiness_line(steps, current_step_id)
	var labels: PackedStringArray = PackedStringArray()
	var current_label: String = current_step_id
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		var label: String = String(step.get("label", "")).strip_edges()
		if not label.is_empty():
			labels.append(label)
		if String(step.get("id", "")).strip_edges() == current_step_id:
			current_label = label
	return "Next sortie: %s | now: %s" % [" -> ".join(Array(labels)), current_label]


func _build_station_next_sortie_readiness_line(steps: Array, current_step_id: String) -> String:
	var current_label: String = _station_next_sortie_step_label(current_step_id)
	var next_labels: PackedStringArray = PackedStringArray()
	var found_current: bool = false
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		var step_id: String = String(step.get("id", "")).strip_edges()
		if step_id == current_step_id:
			found_current = true
			continue
		if not found_current:
			continue
		var label: String = _station_next_sortie_step_label(step_id)
		if not label.is_empty():
			next_labels.append(label)
	if next_labels.is_empty():
		return "Naechste Sortie: %s" % current_label
	return "Naechste Sortie: %s | danach: %s" % [current_label, ", ".join(Array(next_labels))]


func _station_next_sortie_step_label(step_id: String) -> String:
	match step_id:
		"review_roster_gains":
			return "Auswertung ansehen"
		"stage_fireteam":
			return "Fireteam bereitstellen"
		"assign_loadout":
			return "Loadout pruefen"
		"prepare_transport":
			return "Dropship beladen"
		"start_next_sortie":
			return "Start freigeben"
		_:
			return step_id.capitalize()


func _readiness_item_is_ready(readiness: Dictionary, item_id: String) -> bool:
	for item_variant in Array(readiness.get("items", [])):
		var item: Dictionary = Dictionary(item_variant)
		if String(item.get("id", "")).strip_edges() == item_id:
			return bool(item.get("ready", false))
	return false


func _next_sortie_steps_contain(steps: Array, step_id: String) -> bool:
	if step_id.is_empty():
		return false
	for step_variant in steps:
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("id", "")).strip_edges() == step_id:
			return true
	return false


func _supports_next_sortie_readiness_last_result() -> bool:
	return _is_frontier_probe_last_result() or _is_station_scenario_last_result()


func _has_last_result_progression_awards() -> bool:
	var award_summary: Dictionary = Dictionary(_last_mission_result_summary.get("progression_award_summary", {}))
	return int(award_summary.get("total_xp_delta", 0)) > 0 or Array(award_summary.get("listed_awards", [])).size() > 0


func _get_last_result_route_id() -> String:
	var route_id: String = String(_last_mission_result_summary.get("route_id", "")).strip_edges()
	if route_id.is_empty() and _is_frontier_probe_last_result():
		return "frontier_probe_aa_computer_cargo"
	if route_id.is_empty() and _is_station_scenario_last_result():
		return "station_route_aa_door_computer_cargo"
	return route_id


func _get_last_result_scenario_id() -> String:
	for key in ["scenario_id", "mission_id", "source_mission_id"]:
		var value: String = String(_last_mission_result_summary.get(key, "")).strip_edges()
		if not value.is_empty():
			return value
	var scenario_file_path: String = String(_last_mission_result_summary.get("scenario_file_path", "")).strip_edges()
	if scenario_file_path.get_file().get_basename() == "frontier_probe_vertical_slice":
		return "frontier_probe_vertical_slice"
	if scenario_file_path.get_file().get_basename() == "station_route_one_screen_multiplayer_drill":
		return "station_route_one_screen_multiplayer_drill"
	return ""


func _is_frontier_probe_last_result() -> bool:
	if _last_mission_result_summary.is_empty():
		return false
	if String(_last_mission_result_summary.get("route_id", "")).strip_edges() == "frontier_probe_aa_computer_cargo":
		return true
	if _get_last_result_scenario_id() == "frontier_probe_vertical_slice":
		return true
	return String(_last_mission_result_summary.get("scenario_file_path", "")).strip_edges().ends_with("frontier_probe_vertical_slice.json")


func _is_station_scenario_last_result() -> bool:
	if _last_mission_result_summary.is_empty():
		return false
	if String(_last_mission_result_summary.get("route_id", "")).strip_edges() == "station_route_aa_door_computer_cargo":
		return true
	if _get_last_result_scenario_id() == "station_route_one_screen_multiplayer_drill":
		return true
	return String(_last_mission_result_summary.get("scenario_file_path", "")).strip_edges().ends_with("station_route_one_screen_multiplayer_drill.json")


func _update_mission_briefing_panel() -> void:
	_selected_mission_scenario_path = _resolve_selected_mission_scenario_path()
	var panel := _ensure_mission_briefing_panel()
	var source_signature := _build_mission_briefing_source_signature(
		_selected_mission_scenario_path, _selected_mission_map_path, "multiplayer_pvp")
	var source_changed := source_signature != _mission_briefing_source_signature or _mission_briefing_panel_snapshot.is_empty()
	if source_changed:
		_mission_briefing_panel_snapshot = Dictionary(_mission_briefing_panel_presenter.call(
			"build_snapshot_from_files", _selected_mission_scenario_path,
			_selected_mission_map_path, "multiplayer_pvp"))
		_mission_briefing_source_signature = source_signature
	panel.visible = bool(_mission_briefing_panel_snapshot.get("configured", false))
	if not source_changed and _mission_briefing_rendered_panel != null and _mission_briefing_rendered_panel.get_ref() == panel:
		# Only the file-derived presentation is reused. Roster/transport/loadout
		# DTOs, readiness and start permission still refresh through their owners.
		_update_mission_briefing_loadout_bridge_controls()
		return
	_mission_briefing_rendered_panel = weakref(panel)
	_set_mission_briefing_label("BriefingTitleLabel", String(_mission_briefing_panel_snapshot.get("title", "Mission Briefing")).strip_edges())
	_set_mission_briefing_label("BriefingSummaryLabel", String(_mission_briefing_panel_snapshot.get("summary", "")).strip_edges())
	_set_mission_briefing_label("BriefingStatusLabel", String(_mission_briefing_panel_snapshot.get("panel_status_text", "")).strip_edges())
	_set_mission_briefing_label("BriefingObjectivesLabel", "Ziele: %s" % String(_mission_briefing_panel_snapshot.get("objective_text", "-")).strip_edges())
	_set_mission_briefing_label("BriefingThreatsLabel", "Risiken: %s" % String(_mission_briefing_panel_snapshot.get("threat_text", "-")).strip_edges())
	_set_mission_briefing_label("BriefingTeamsLabel", "Teams: %s" % String(_mission_briefing_panel_snapshot.get("team_spawn_text", "-")).strip_edges())
	_set_mission_briefing_label("BriefingLoadoutLabel", "Empfohlen: %s" % String(_mission_briefing_panel_snapshot.get("loadout_text", "-")).strip_edges())
	_set_mission_briefing_background_image(String(_mission_briefing_panel_snapshot.get("background_image_path", "")).strip_edges())
	_set_mission_briefing_minimap_visual(Dictionary(_mission_briefing_panel_snapshot.get("minimap_visual_snapshot", {})))
	_set_mission_briefing_loadout_cards(Array(_mission_briefing_panel_snapshot.get("loadout_card_entries", [])))
	panel.set_meta("mission_briefing_snapshot", _mission_briefing_panel_snapshot.duplicate(true))


func _mission_briefing_catalog_source_paths() -> PackedStringArray:
	# MapData normalization reads this external catalog. Marker/tactics/weapon
	# definitions used by these presenters are already-loaded script constants.
	return PackedStringArray(["res://data/terrain_tile_catalog.json"])


func _build_mission_briefing_source_signature(scenario_path: String, map_path: String, play_mode: String) -> String:
	var scenario_source := scenario_path.strip_edges()
	var selected_map_source := map_path.strip_edges()
	var scenario: Dictionary = {}
	if not scenario_source.is_empty() and FileAccess.file_exists(scenario_source):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(scenario_source))
		if parsed is Dictionary:
			scenario = parsed
	# Match PanelPresenter's actual source resolution when no explicit map wins.
	var resolved_map_source := selected_map_source
	if resolved_map_source.is_empty():
		resolved_map_source = String(scenario.get("map_file_path", "")).strip_edges()
	var briefing_variant: Variant = scenario.get("briefing", scenario.get("mission_briefing", {}))
	var briefing: Dictionary = briefing_variant if briefing_variant is Dictionary else {}
	var background_source := String(briefing.get("background_image_path", "")).strip_edges()
	var sources: Array = []
	for path in [scenario_source, resolved_map_source, background_source]:
		sources.append(_mission_briefing_source_file_identity(path))
	for path in _mission_briefing_catalog_source_paths():
		sources.append(_mission_briefing_source_file_identity(path))
	return JSON.stringify({"scenario": scenario_source, "selected_map": selected_map_source,
		"resolved_map": resolved_map_source, "play_mode": play_mode, "sources": sources}).sha256_text()


func _mission_briefing_source_file_identity(path: String) -> Dictionary:
	var normalized := path.strip_edges()
	var exists := not normalized.is_empty() and FileAccess.file_exists(normalized)
	return {"path": normalized, "exists": exists,
		"sha256": FileAccess.get_sha256(normalized) if exists else "",
		"resource_exists": not normalized.is_empty() and ResourceLoader.exists(normalized)}


func _update_pre_mission_readiness_panel() -> void:
	var panel := _ensure_pre_mission_readiness_panel()
	_pre_mission_readiness_snapshot = Dictionary(_pre_mission_readiness_presenter.call("build_snapshot", {
		"briefing": _mission_briefing_panel_snapshot.duplicate(true),
		"loadout": get_briefing_loadout_bridge_snapshot(),
		"aircraft": get_aircraft_panel_snapshot(),
		"staging": get_homebase_direct_staging_snapshot(),
		"can_start": can_request_mission_start(),
	}))
	panel.visible = true
	panel.set_meta("pre_mission_readiness_snapshot", _pre_mission_readiness_snapshot.duplicate(true))
	_set_pre_mission_readiness_summary(String(_pre_mission_readiness_snapshot.get("summary_text", "")).strip_edges())
	_set_pre_mission_readiness_items(Array(_pre_mission_readiness_snapshot.get("items", [])))
	_sync_start_button_with_readiness_snapshot()
	_update_release_candidate_action_cue_panel()


func _ensure_mission_briefing_panel() -> PanelContainer:
	var mission_vbox := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	var existing := mission_vbox.get_node_or_null("MissionBriefingPanel") as PanelContainer
	if existing != null:
		return existing
	var panel := PanelContainer.new()
	panel.name = "MissionBriefingPanel"
	panel.custom_minimum_size = Vector2(0.0, 158.0)
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
		"BriefingBackgroundImage",
		"BriefingMinimapVisual",
		"BriefingObjectivesLabel",
		"BriefingThreatsLabel",
		"BriefingTeamsLabel",
		"BriefingLoadoutLabel",
		"BriefingLoadoutCards",
	]:
		if label_name == "BriefingBackgroundImage":
			var texture_rect := TextureRect.new()
			texture_rect.name = label_name
			texture_rect.custom_minimum_size = Vector2(0.0, 44.0)
			texture_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.mouse_filter = Control.MOUSE_FILTER_PASS
			texture_rect.visible = false
			vbox.add_child(texture_rect)
			continue
		if label_name == "BriefingMinimapVisual":
			var minimap_visual: Control = MISSION_BRIEFING_MINIMAP_VISUAL_SCRIPT.new()
			minimap_visual.name = label_name
			minimap_visual.custom_minimum_size = Vector2(0.0, 58.0)
			minimap_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			minimap_visual.mouse_filter = Control.MOUSE_FILTER_PASS
			vbox.add_child(minimap_visual)
			continue
		if label_name == "BriefingLoadoutCards":
			var cards := VBoxContainer.new()
			cards.name = label_name
			cards.add_theme_constant_override("separation", 3)
			cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.add_child(cards)
			continue
		var label := Label.new()
		label.name = label_name
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.custom_minimum_size = Vector2(0.0, 12.0)
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


func _ensure_pre_mission_readiness_panel() -> PanelContainer:
	var mission_vbox := get_node("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	var existing := mission_vbox.get_node_or_null("PreMissionReadinessPanel") as PanelContainer
	if existing != null:
		return existing
	var panel := PanelContainer.new()
	panel.name = "PreMissionReadinessPanel"
	panel.custom_minimum_size = Vector2(0.0, 74.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")
	var margin := MarginContainer.new()
	margin.name = "ReadinessMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.name = "ReadinessVBox"
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	var title_label := Label.new()
	title_label.name = "ReadinessTitleLabel"
	title_label.text = "Pre-Mission Readiness"
	META_UI_SKIN_SCRIPT.style_header_label(title_label, 10)
	vbox.add_child(title_label)
	var summary_label := Label.new()
	summary_label.name = "ReadinessSummaryLabel"
	summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	summary_label.clip_text = true
	summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	META_UI_SKIN_SCRIPT.style_body_label(summary_label, 8)
	vbox.add_child(summary_label)
	var list := GridContainer.new()
	list.name = "ReadinessItemList"
	list.columns = 4
	list.add_theme_constant_override("separation", 1)
	vbox.add_child(list)
	mission_vbox.add_child(panel)
	var briefing_panel := mission_vbox.get_node_or_null("MissionBriefingPanel")
	if briefing_panel != null:
		mission_vbox.move_child(panel, briefing_panel.get_index() + 1)
	return panel


func _update_release_candidate_action_cue_panel() -> void:
	var panel := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel") as Control
	var label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel/ReadinessMargin/ReadinessVBox/ReadinessSummaryLabel") as Label
	var start_button := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	if panel == null or label == null:
		return
	var readiness_state: String = String(_pre_mission_readiness_snapshot.get("overall_state", "")).strip_edges()
	var cue_text: String = _build_release_candidate_action_cue_text(readiness_state)
	var tooltip_text: String = _build_release_candidate_action_cue_tooltip(readiness_state)
	var summary_text: String = String(_pre_mission_readiness_snapshot.get("summary_text", "")).strip_edges()
	var is_ready: bool = readiness_state == "ready"
	panel.visible = true
	panel.tooltip_text = tooltip_text
	panel.custom_minimum_size.y = max(panel.custom_minimum_size.y, HOMEBASE_RELEASE_CTA_MIN_HEIGHT)
	var panel_container := panel as PanelContainer
	if panel_container != null:
		META_UI_SKIN_SCRIPT.style_tactical_panel(panel_container, "header" if is_ready else "thin_frame")
	panel.set_meta("release_candidate_action_cue_text", cue_text)
	panel.set_meta("release_candidate_action_cue_step_count", _release_candidate_action_cue_step_count(readiness_state))
	panel.set_meta("release_candidate_action_cue_style_id", HOMEBASE_RELEASE_CTA_EMPHASIS_STYLE_ID)
	panel.set_meta("release_candidate_action_cue_priority", "primary" if is_ready else "blocking")
	panel.set_meta("readiness_overall_state", readiness_state)
	panel.set_meta("read_only", true)
	panel.set_meta("ui_sets_gameplay_truth", false)
	label.text = cue_text if summary_text.is_empty() else "%s | %s" % [cue_text, summary_text]
	label.tooltip_text = tooltip_text
	META_UI_SKIN_SCRIPT.style_body_label(label, HOMEBASE_RELEASE_CTA_FONT_SIZE)
	label.add_theme_color_override("font_color", Color("f7e7aa") if is_ready else Color("f4c1c1"))
	label.set_meta("release_candidate_action_cue_text", cue_text)
	label.set_meta("release_candidate_action_cue_step_count", _release_candidate_action_cue_step_count(readiness_state))
	label.set_meta("release_candidate_action_cue_font_size", HOMEBASE_RELEASE_CTA_FONT_SIZE)
	label.set_meta("release_candidate_action_cue_style_id", HOMEBASE_RELEASE_CTA_EMPHASIS_STYLE_ID)
	label.set_meta("read_only", true)
	label.set_meta("ui_sets_gameplay_truth", false)
	if start_button != null:
		start_button.tooltip_text = tooltip_text
		start_button.set_meta("release_candidate_action_cue_text", cue_text)
		start_button.set_meta("release_candidate_primary_cta_button", is_ready)
		start_button.set_meta("release_candidate_action_cue_style_id", HOMEBASE_RELEASE_CTA_EMPHASIS_STYLE_ID)


func _build_release_candidate_action_cue_text(readiness_state: String) -> String:
	match readiness_state.strip_edges().to_lower():
		"ready":
			return "Naechster Griff: Start Mission -> LZ waehlen -> Drop -> Preview lesen -> GO"
		"warn":
			return "Naechster Griff: Start pruefen -> WARN-Chips lesen -> bewusst Start Mission"
	return "Naechster Griff: STOP-Chips loesen -> Dropship/Pilot/Boarding pruefen"


func _build_release_candidate_action_cue_tooltip(readiness_state: String) -> String:
	var summary: String = String(_pre_mission_readiness_snapshot.get("summary_text", "")).strip_edges()
	if summary.is_empty():
		summary = "Pre-Mission-Readiness lesen."
	return "%s\n%s" % [_build_release_candidate_action_cue_text(readiness_state), summary]


func _release_candidate_action_cue_step_count(readiness_state: String) -> int:
	match readiness_state.strip_edges().to_lower():
		"ready":
			return 5
		"warn":
			return 3
	return 2


func _set_mission_briefing_label(label_name: String, text: String) -> void:
	var label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/%s" % label_name) as Label
	if label == null:
		return
	label.text = text
	label.tooltip_text = text


func _set_mission_briefing_background_image(image_path: String) -> void:
	var texture_rect := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingBackgroundImage") as TextureRect
	if texture_rect == null:
		return
	var normalized_path: String = image_path.strip_edges()
	texture_rect.texture = null
	texture_rect.visible = false
	texture_rect.tooltip_text = "Briefing image: none"
	if normalized_path.is_empty() or not ResourceLoader.exists(normalized_path):
		texture_rect.tooltip_text = "Briefing image missing: %s" % normalized_path if not normalized_path.is_empty() else "Briefing image: none"
		return
	var texture := load(normalized_path) as Texture2D
	if texture == null:
		texture_rect.tooltip_text = "Briefing image could not load: %s" % normalized_path
		return
	texture_rect.texture = texture
	texture_rect.visible = true
	texture_rect.tooltip_text = "Briefing image: %s" % normalized_path.get_file()


func _set_mission_briefing_minimap_visual(snapshot: Dictionary) -> void:
	var minimap_visual := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingMinimapVisual") as Control
	if minimap_visual == null or not minimap_visual.has_method("set_visual_snapshot"):
		return
	minimap_visual.visible = bool(snapshot.get("configured", false))
	minimap_visual.call("set_visual_snapshot", snapshot)


func _set_mission_briefing_loadout_cards(entries: Array) -> void:
	var cards := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutCards") as VBoxContainer
	if cards == null:
		return
	_clear_container(cards)
	cards.visible = not entries.is_empty()
	var visible_recommendation_ids: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var recommendation_id: String = String(entry.get("recommendation_id", "")).strip_edges()
		if recommendation_id.is_empty():
			recommendation_id = "rec_%d" % visible_recommendation_ids.size()
		visible_recommendation_ids.append(recommendation_id)
		var button := Button.new()
		button.name = "BriefingLoadoutRecommendationButton"
		button.toggle_mode = true
		button.button_pressed = recommendation_id == _selected_briefing_loadout_recommendation_id
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.clip_text = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0.0, 24.0)
		button.add_theme_font_size_override("font_size", 8)
		META_UI_SKIN_SCRIPT.style_secondary_button(button)
		button.text = "%s | %s | %s" % [
			String(entry.get("label", "Loadout")).strip_edges(),
			String(entry.get("subtitle", "-")).strip_edges(),
			String(entry.get("body", "")).strip_edges(),
		]
		button.tooltip_text = "%s\n%s" % [button.text, String(entry.get("apply_hint_text", "")).strip_edges()]
		button.set_meta("ui_sets_gameplay_truth", false)
		button.set_meta("briefing_loadout_recommendation_button", true)
		button.set_meta("recommendation_id", recommendation_id)
		button.set_meta("loadout_patch_preview", Dictionary(entry.get("loadout_patch_preview", {})).duplicate(true))
		button.pressed.connect(Callable(self, "_on_briefing_loadout_recommendation_pressed").bind(recommendation_id))
		cards.add_child(button)
	if not _selected_briefing_loadout_recommendation_id.is_empty() and not visible_recommendation_ids.has(_selected_briefing_loadout_recommendation_id):
		_selected_briefing_loadout_recommendation_id = ""
		_selected_briefing_loadout_recommendation = {}
	_ensure_mission_briefing_loadout_bridge_controls()
	_update_mission_briefing_loadout_bridge_controls()


func _build_briefing_loadout_card_text(cards: VBoxContainer) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for child in cards.get_children():
		var control := child as Control
		if control == null:
			continue
		var text: String = ""
		if control is Button:
			text = (control as Button).text.strip_edges()
		elif control is Label:
			text = (control as Label).text.strip_edges()
		if not text.is_empty():
			lines.append(text.replace("\n", " / "))
	if lines.is_empty():
		return ""
	return " | ".join(lines)


func _set_pre_mission_readiness_summary(text: String) -> void:
	var label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel/ReadinessMargin/ReadinessVBox/ReadinessSummaryLabel") as Label
	if label == null:
		return
	label.text = text
	label.tooltip_text = text


func _set_pre_mission_readiness_items(items: Array) -> void:
	var list := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/PreMissionReadinessPanel/ReadinessMargin/ReadinessVBox/ReadinessItemList") as Container
	if list == null:
		return
	_clear_container(list)
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(item_variant)
		var state: String = String(item.get("state", "")).strip_edges()
		var icon_text: String = _get_readiness_icon_text(state)
		var legacy_marker: String = _get_readiness_legacy_marker(state)
		var color_hex: String = _get_readiness_color(state).to_html(false)
		var text_color_hex: String = _get_readiness_text_color(state).to_html(false)
		var label_text: String = String(item.get("label", "")).strip_edges()
		var chip_text: String = "%s %s" % [legacy_marker, label_text]
		var visible_text: String = "%s %s" % [icon_text, label_text]
		var chip := PanelContainer.new()
		chip.name = "ReadinessItemChip"
		chip.custom_minimum_size = Vector2(220.0, 18.0)
		chip.tooltip_text = "%s: %s" % [visible_text, String(item.get("detail", "")).strip_edges()]
		chip.add_theme_stylebox_override("panel", _build_readiness_chip_style(state))
		chip.set_meta("pre_mission_readiness_item", true)
		chip.set_meta("readiness_id", String(item.get("id", "")).strip_edges())
		chip.set_meta("readiness_state", state)
		chip.set_meta("readiness_blocking", bool(item.get("blocking", false)))
		chip.set_meta("readiness_icon_text", icon_text)
		chip.set_meta("readiness_color_hex", color_hex)
		chip.set_meta("readiness_text_color_hex", text_color_hex)
		chip.set_meta("readiness_text", chip_text)
		var margin := MarginContainer.new()
		margin.name = "ReadinessChipMargin"
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_top", 1)
		margin.add_theme_constant_override("margin_bottom", 1)
		chip.add_child(margin)
		var row := HBoxContainer.new()
		row.name = "ReadinessChipRow"
		row.add_theme_constant_override("separation", 4)
		margin.add_child(row)
		var swatch := ColorRect.new()
		swatch.name = "ReadinessStateSwatch"
		swatch.color = _get_readiness_color(state)
		swatch.custom_minimum_size = Vector2(5.0, 12.0)
		swatch.set_meta("readiness_color_hex", color_hex)
		row.add_child(swatch)
		var label := Label.new()
		label.name = "ReadinessItemLabel"
		label.text = visible_text
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 8)
		META_UI_SKIN_SCRIPT.style_body_label(label, 8)
		label.add_theme_color_override("font_color", _get_readiness_text_color(state))
		label.set_meta("readiness_icon_text", icon_text)
		label.set_meta("readiness_color_hex", color_hex)
		label.set_meta("readiness_text_color_hex", text_color_hex)
		row.add_child(label)
		list.add_child(chip)


func _build_readiness_item_list_text(list: Container) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for child in list.get_children():
		var text: String = String(child.get_meta("readiness_text", "")).strip_edges() if child is Control else ""
		if text.is_empty() and child is Label:
			text = (child as Label).text.strip_edges()
		if not text.is_empty():
			lines.append(text)
	return " | ".join(lines)


func _build_readiness_chip_visual_snapshot(list: Container) -> Array:
	var entries: Array = []
	for child in list.get_children():
		var control := child as Control
		if control == null or not bool(control.get_meta("pre_mission_readiness_item", false)):
			continue
		entries.append({
			"id": String(control.get_meta("readiness_id", "")).strip_edges(),
			"state": String(control.get_meta("readiness_state", "")).strip_edges(),
			"icon_text": String(control.get_meta("readiness_icon_text", "")).strip_edges(),
			"color_hex": String(control.get_meta("readiness_color_hex", "")).strip_edges(),
			"text_color_hex": String(control.get_meta("readiness_text_color_hex", "")).strip_edges(),
			"text": String(control.get_meta("readiness_text", "")).strip_edges(),
			"tooltip": control.tooltip_text,
		})
	return entries


func _calculate_mission_deck_density(startflow: Dictionary) -> float:
	var mission_rect: Rect2 = startflow.get("mission_rect", Rect2())
	if mission_rect.size.y <= 0.0:
		return 0.0
	var child_bottom: float = float(startflow.get("mission_child_max_bottom", mission_rect.position.y))
	return clampf((child_bottom - mission_rect.position.y) / mission_rect.size.y, 0.0, 99.0)


func _append_visual_audit_check(checks: Array, check_id: String, passed: bool, severity: String, message: String, details: Dictionary = {}) -> void:
	checks.append({
		"id": check_id,
		"passed": passed,
		"severity": severity,
		"message": message,
		"details": details.duplicate(true),
	})


func _count_visual_audit_failures(checks: Array, severity_filter: String) -> int:
	var count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)) and String(check.get("severity", "")) == severity_filter:
			count += 1
	return count


func _build_visual_audit_issue_list(checks: Array) -> Array:
	var issues: Array = []
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			issues.append({
				"id": String(check.get("id", "")),
				"severity": String(check.get("severity", "")),
				"message": String(check.get("message", "")),
			})
	return issues


func _snapshot_boundary_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_navigation", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _calculate_readiness_chip_contrast(chips: Array) -> Dictionary:
	var dark_chip_background := Color(0.07, 0.09, 0.10, 0.92)
	var min_text_contrast: float = 99.0
	var min_status_contrast: float = 99.0
	var chips_with_detailed_tooltip: int = 0
	for chip_variant in chips:
		var chip: Dictionary = Dictionary(chip_variant)
		var state: String = String(chip.get("state", "")).strip_edges()
		var text: String = String(chip.get("text", "")).strip_edges()
		var tooltip: String = String(chip.get("tooltip", "")).strip_edges()
		min_text_contrast = minf(min_text_contrast, _contrast_ratio(_get_readiness_text_color(state), dark_chip_background))
		min_status_contrast = minf(min_status_contrast, _contrast_ratio(_get_readiness_color(state), dark_chip_background))
		if not tooltip.is_empty() and tooltip.length() > text.length():
			chips_with_detailed_tooltip += 1
	if chips.is_empty():
		min_text_contrast = 0.0
		min_status_contrast = 0.0
	return {
		"min_text_contrast": min_text_contrast,
		"min_status_contrast": min_status_contrast,
		"chips_with_detailed_tooltip": chips_with_detailed_tooltip,
		"chip_count": chips.size(),
	}


func _start_button_matches_readiness(startflow: Dictionary) -> bool:
	var state: String = String(startflow.get("readiness_overall_state", "")).strip_edges()
	var text: String = String(startflow.get("start_button_text", "")).strip_edges()
	var disabled: bool = bool(startflow.get("start_button_disabled", true))
	match state:
		"ready":
			return text == "Start Mission" and not disabled
		"warn":
			return text == "Start pruefen"
		_:
			return text == "Start blockiert" and disabled


func _contrast_ratio(a: Color, b: Color) -> float:
	var lighter: float = maxf(_relative_luminance(a), _relative_luminance(b))
	var darker: float = minf(_relative_luminance(a), _relative_luminance(b))
	return (lighter + 0.05) / (darker + 0.05)


func _relative_luminance(color: Color) -> float:
	return 0.2126 * _srgb_channel_to_linear(color.r) \
		+ 0.7152 * _srgb_channel_to_linear(color.g) \
		+ 0.0722 * _srgb_channel_to_linear(color.b)


func _srgb_channel_to_linear(value: float) -> float:
	if value <= 0.03928:
		return value / 12.92
	return pow((value + 0.055) / 1.055, 2.4)


func _get_readiness_icon_text(state: String) -> String:
	match state.strip_edges().to_lower():
		"ready":
			return "OK"
		"warn":
			return "WARN"
		_:
			return "STOP"


func _get_readiness_legacy_marker(state: String) -> String:
	match state.strip_edges().to_lower():
		"ready":
			return "OK"
		"warn":
			return "!"
		_:
			return "X"


func _get_readiness_color(state: String) -> Color:
	match state.strip_edges().to_lower():
		"ready":
			return Color("69c391")
		"warn":
			return Color("d89b31")
		_:
			return Color("d66c66")


func _get_readiness_text_color(state: String) -> Color:
	match state.strip_edges().to_lower():
		"ready":
			return Color("dff6e8")
		"warn":
			return Color("ffe8b8")
		_:
			return Color("ffd6d2")


func _build_readiness_chip_style(state: String) -> StyleBoxFlat:
	var color := _get_readiness_color(state)
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.07, 0.09, 0.10, 0.92)
	stylebox.border_color = color
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	stylebox.content_margin_left = 2
	stylebox.content_margin_right = 2
	stylebox.content_margin_top = 1
	stylebox.content_margin_bottom = 1
	return stylebox


func _sync_start_button_with_readiness_snapshot() -> void:
	var start_button := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/HeaderRow/StartMissionButton") as Button
	if start_button == null:
		return
	var overall_state: String = String(_pre_mission_readiness_snapshot.get("overall_state", "")).strip_edges()
	var summary_text: String = String(_pre_mission_readiness_snapshot.get("summary_text", "")).strip_edges()
	if overall_state == "ready":
		start_button.text = "Einsatz starten"
	elif overall_state == "warn":
		start_button.text = "Start pruefen"
	else:
		start_button.text = "Start blockiert"
	start_button.tooltip_text = summary_text
	start_button.set_meta("pre_mission_readiness_state", overall_state)
	start_button.set_meta("pre_mission_readiness_summary", summary_text)
	start_button.set_meta("pre_mission_readiness_color_hex", _get_readiness_color(overall_state).to_html(false))


func _ensure_mission_briefing_loadout_bridge_controls() -> void:
	var briefing_vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox") as VBoxContainer
	if briefing_vbox == null:
		return
	var status_label := briefing_vbox.get_node_or_null("BriefingLoadoutBridgeStatusLabel") as Label
	if status_label == null:
		status_label = Label.new()
		status_label.name = "BriefingLoadoutBridgeStatusLabel"
		status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status_label.clip_text = true
		status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		status_label.add_theme_font_size_override("font_size", 8)
		META_UI_SKIN_SCRIPT.style_body_label(status_label, 8)
		status_label.add_theme_color_override("font_color", Color("c7d2dc"))
		briefing_vbox.add_child(status_label)
	var bridge_row := briefing_vbox.get_node_or_null("BriefingLoadoutBridgeRow") as HBoxContainer
	if bridge_row == null:
		bridge_row = HBoxContainer.new()
		bridge_row.name = "BriefingLoadoutBridgeRow"
		bridge_row.add_theme_constant_override("separation", 4)
		briefing_vbox.add_child(bridge_row)
	var apply_button := bridge_row.get_node_or_null("BriefingLoadoutApplyButton") as Button
	if apply_button == null:
		apply_button = Button.new()
		apply_button.name = "BriefingLoadoutApplyButton"
		apply_button.text = "Empfehlung anwenden"
		apply_button.custom_minimum_size = Vector2(140.0, 26.0)
		META_UI_SKIN_SCRIPT.style_primary_button(apply_button)
		apply_button.set_meta("briefing_loadout_apply_button", true)
		apply_button.pressed.connect(Callable(self, "apply_selected_briefing_loadout_recommendation_to_selected_units"))
		bridge_row.add_child(apply_button)


func _update_mission_briefing_loadout_bridge_controls() -> void:
	var cards := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutCards") as VBoxContainer
	if cards != null:
		for child in cards.get_children():
			var button := child as Button
			if button == null:
				continue
			var recommendation_id: String = String(button.get_meta("recommendation_id", "")).strip_edges()
			button.button_pressed = recommendation_id == _selected_briefing_loadout_recommendation_id
	var status_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutBridgeStatusLabel") as Label
	if status_label != null:
		status_label.text = _build_briefing_loadout_bridge_status_text()
		status_label.tooltip_text = status_label.text
	var apply_button := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionBriefingPanel/BriefingMargin/BriefingVBox/BriefingLoadoutBridgeRow/BriefingLoadoutApplyButton") as Button
	if apply_button != null:
		apply_button.disabled = not _is_briefing_loadout_apply_ready()
		apply_button.tooltip_text = _build_briefing_loadout_bridge_status_text()


func _count_briefing_recommendation_buttons(cards: VBoxContainer) -> int:
	var count: int = 0
	for child in cards.get_children():
		var control := child as Control
		if control != null and bool(control.get_meta("briefing_loadout_recommendation_button", false)):
			count += 1
	return count


func _on_briefing_loadout_recommendation_pressed(recommendation_id: String) -> void:
	select_briefing_loadout_recommendation(recommendation_id)


func select_briefing_loadout_recommendation(recommendation_id: String) -> Dictionary:
	var normalized_id: String = recommendation_id.strip_edges()
	var recommendation: Dictionary = _get_briefing_loadout_recommendation(normalized_id)
	if recommendation.is_empty():
		_selected_briefing_loadout_recommendation_id = ""
		_selected_briefing_loadout_recommendation = {}
		_briefing_loadout_feedback_text = "Keine Briefing-Empfehlung ausgewaehlt."
	else:
		_selected_briefing_loadout_recommendation_id = normalized_id
		_selected_briefing_loadout_recommendation = recommendation.duplicate(true)
		_briefing_loadout_feedback_text = "Empfehlung ausgewaehlt: %s" % String(recommendation.get("label", normalized_id)).strip_edges()
	_update_mission_briefing_loadout_bridge_controls()
	return get_briefing_loadout_bridge_snapshot()


func apply_selected_briefing_loadout_recommendation_to_selected_units() -> Dictionary:
	return apply_briefing_loadout_recommendation_to_unit_ids(
		_selected_briefing_loadout_recommendation_id,
		_selected_unit_ids
	)


func apply_briefing_loadout_recommendation_to_unit_ids(recommendation_id: String, unit_ids: PackedStringArray) -> Dictionary:
	var normalized_id: String = recommendation_id.strip_edges()
	var recommendation: Dictionary = _get_briefing_loadout_recommendation(normalized_id)
	if recommendation.is_empty():
		_briefing_loadout_feedback_text = "Keine gueltige Briefing-Empfehlung gewaehlt."
		_update_mission_briefing_loadout_bridge_controls()
		return get_briefing_loadout_bridge_snapshot()
	var armor_id: String = String(recommendation.get("armor_id", HOMEBASE_DEFAULT_LOADOUT_ID)).strip_edges()
	var weapon_1_id: String = String(recommendation.get("primary_weapon_id", HOMEBASE_DEFAULT_PRIMARY_WEAPON)).strip_edges()
	var weapon_2_id: String = String(recommendation.get("secondary_weapon_id", HOMEBASE_DEFAULT_SECONDARY_WEAPON)).strip_edges()
	if armor_id.is_empty():
		armor_id = HOMEBASE_DEFAULT_LOADOUT_ID
	if weapon_1_id.is_empty():
		weapon_1_id = HOMEBASE_DEFAULT_PRIMARY_WEAPON
	if weapon_2_id.is_empty():
		weapon_2_id = HOMEBASE_DEFAULT_SECONDARY_WEAPON
	var applied_unit_ids: PackedStringArray = PackedStringArray()
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or applied_unit_ids.has(unit_id):
			continue
		var fireteam_id: String = _get_fireteam_id_for_unit(unit_id)
		if fireteam_id.is_empty():
			continue
		_set_homebase_member_loadout(fireteam_id, unit_id, armor_id, weapon_1_id, weapon_2_id)
		applied_unit_ids.append(unit_id)
	if applied_unit_ids.is_empty():
		_briefing_loadout_feedback_text = "Empfehlung nicht angewendet: keine gestagten Operatoren mit Fireteam-Zuweisung."
	else:
		_briefing_loadout_apply_count += 1
		_selected_briefing_loadout_recommendation_id = normalized_id
		_selected_briefing_loadout_recommendation = recommendation.duplicate(true)
		_briefing_loadout_feedback_text = "%s auf %d Operatoren angewendet." % [
			String(recommendation.get("label", normalized_id)).strip_edges(),
			applied_unit_ids.size(),
		]
		if is_inside_tree():
			_render_homebase_fireteams()
			_update_homebase_loadout_panel()
	_update_mission_briefing_loadout_bridge_controls()
	var result: Dictionary = get_briefing_loadout_bridge_snapshot()
	result["applied_unit_ids"] = Array(applied_unit_ids)
	result["ok"] = not applied_unit_ids.is_empty()
	return result


func get_briefing_loadout_bridge_snapshot() -> Dictionary:
	return {
		"selected_recommendation_id": _selected_briefing_loadout_recommendation_id,
		"selected_recommendation_label": String(_selected_briefing_loadout_recommendation.get("label", "")).strip_edges(),
		"selected_patch_preview": Dictionary(_selected_briefing_loadout_recommendation.get("loadout_patch_preview", {})).duplicate(true),
		"selected_unit_ids": Array(_selected_unit_ids),
		"selected_unit_count": _selected_unit_ids.size(),
		"selected_unit_loadouts": _build_member_loadout_snapshot_for_unit_ids(_selected_unit_ids),
		"apply_ready": _is_briefing_loadout_apply_ready(),
		"apply_count": _briefing_loadout_apply_count,
		"feedback_text": _briefing_loadout_feedback_text,
		"ui_sets_gameplay_truth": false,
	}


func _get_briefing_loadout_recommendation(recommendation_id: String) -> Dictionary:
	var normalized_id: String = recommendation_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	for entry_variant in Array(_mission_briefing_panel_snapshot.get("loadout_card_entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		if String(entry.get("recommendation_id", "")).strip_edges() == normalized_id:
			return entry
	return {}


func _is_briefing_loadout_apply_ready() -> bool:
	return not _selected_briefing_loadout_recommendation_id.is_empty() and not _selected_unit_ids.is_empty()


func _build_briefing_loadout_bridge_status_text() -> String:
	if not _briefing_loadout_feedback_text.is_empty():
		return _briefing_loadout_feedback_text
	if _selected_briefing_loadout_recommendation_id.is_empty():
		return "Loadout-Empfehlung auswaehlen; Apply bleibt bestaetigungspflichtig."
	if _selected_unit_ids.is_empty():
		return "Empfehlung gewaehlt, aber keine Operatoren gestagt."
	return "Bereit: Empfehlung kann auf %d gestagte Operatoren angewendet werden." % _selected_unit_ids.size()


func _build_member_loadout_snapshot_for_unit_ids(unit_ids: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		result[unit_id] = _get_member_loadout(unit_id)
	return result


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
	_queue_r3_homebase_geometry_if_changed()
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
		var payload_craft := _get_aircraft_definition_by_id(_get_homebase_direct_payload_craft_id())
		if bool(payload_craft.get("mission_transit_to_homebase", false)):
			var craft_name: String = FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_display_name(payload_craft)
			status_label.text = "%s · Rückflug (%d s)" % [craft_name, int(payload_craft.get("transfer_eta_seconds", 0))]
			shipcards_list.add_child(_build_empty_state_label("Der Transport ist nach seiner Rückkehr wieder verfügbar."))
		else:
			status_label.text = "Noch kein Transport. Schiffstyp wählen und mit + hinzufügen."
			shipcards_list.add_child(_build_empty_state_label("Trupps und Pilot anschließend auf die Schiffskarte ziehen."))
			transfers_list.add_child(_build_empty_state_label("No loading or ship flights queued."))
		status_label.tooltip_text = status_label.text
		return

	selector.disabled = selector.item_count == 0
	var selected_craft_id: String = String(selected_craft.get("craft_id", "")).strip_edges()
	var craft_name: String = String(selected_craft.get("display_name", selected_craft_id)).strip_edges()
	var assigned_pilot_id: String = _get_assigned_pilot_id(selected_craft_id)
	var craft_in_transit: bool = _is_craft_in_transit(selected_craft_id)
	var craft_busy: bool = _has_active_pilot_transfer_for_craft(selected_craft_id) or craft_in_transit
	var cargo_loading: bool = _has_active_cargo_load_for_craft(selected_craft_id)
	status_label.text = _build_aircraft_status_text(selected_craft, craft_name, assigned_pilot_id, craft_busy, cargo_loading)
	status_label.tooltip_text = status_label.text
	status_label.text = "%s · %s" % [craft_name, "unterwegs" if craft_in_transit else "Pilot: %s" % _build_display_name(assigned_pilot_id) if not assigned_pilot_id.is_empty() else "Pilot fehlt"]
	if not _aircraft_feedback_text.is_empty():
		status_label.text = _aircraft_feedback_text
	status_label.max_lines_visible = 2

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
	var column_count := _r3_ship_columns()
	shipcards_list.set_meta("homebase_shipcards_two_column_layout", column_count == 2)
	shipcards_list.set_meta("homebase_shipcard_compact_width", HOMEBASE_SHIPCARD_COMPACT_WIDTH)
	var row: HBoxContainer = null
	for craft_index in range(visible_aircraft_definitions.size()):
		if craft_index % column_count == 0:
			row = HBoxContainer.new()
			row.name = "ShipCardRow_%d" % int(craft_index / column_count)
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
	var post_mission_delta: Dictionary = _get_post_mission_skill_delta_for_unit(_focused_unit_id)
	CHARACTER_SHEET_VIEW_SCRIPT.render(
		content_host,
		profile,
		{
			"status_text": _build_sheet_status_text(_focused_unit_id),
			"fireteam_text": _build_homebase_fireteam_text(_focused_unit_id),
			"post_mission_skill_delta": post_mission_delta,
			"post_mission_skill_delta_text": _format_post_mission_skill_delta_text(post_mission_delta),
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


func _merge_fireteam_definitions(existing_definitions: Array, incoming_definitions: Array) -> Array:
	var merged_by_id: Dictionary = {}
	var ordered_ids: PackedStringArray = []
	for source_definitions in [existing_definitions, incoming_definitions]:
		for definition_variant in _normalize_fireteam_definitions(Array(source_definitions)):
			var definition: Dictionary = Dictionary(definition_variant)
			var fireteam_id: String = _normalize_fireteam_id(String(definition.get("id", "")))
			if fireteam_id.is_empty():
				continue
			if not merged_by_id.has(fireteam_id):
				ordered_ids.append(fireteam_id)
			merged_by_id[fireteam_id] = definition
	var merged_definitions: Array = []
	for fireteam_id in ordered_ids:
		if merged_by_id.has(fireteam_id):
			merged_definitions.append(Dictionary(merged_by_id[fireteam_id]).duplicate(true))
	return merged_definitions


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
	if member_ids.is_empty():
		var definition: Dictionary = _get_fireteam_definition(normalized_fireteam_id)
		member_ids = PackedStringArray(Array(definition.get("member_unit_ids", [])))
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
		var previous_team_id: String = _normalize_fireteam_id(String(_selected_fireteam_ids[unit_index]))
		if not previous_team_id.is_empty() and previous_team_id != normalized_fireteam_id:
			# Empty-team fallback reads this existing owner field. Remove the old
			# membership before sanitizing, including the last member's departure.
			for definition_index in range(_fireteam_definitions.size()):
				var definition: Dictionary = Dictionary(_fireteam_definitions[definition_index])
				if _normalize_fireteam_id(String(definition.get("id", ""))) != previous_team_id:
					continue
				var previous_members: PackedStringArray = PackedStringArray(Array(definition.get("member_unit_ids", [])))
				var member_index: int = previous_members.find(normalized_unit_id)
				if member_index >= 0:
					previous_members.remove_at(member_index)
				definition["member_unit_ids"] = previous_members
				_fireteam_definitions[definition_index] = definition
				break
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
	return PORTRAIT_CATALOG_SCRIPT.resolve_path(String(profile.portrait_id), String(profile.portrait_path))


func _build_homebase_fireteam_summary_text() -> String:
	var assigned_count := 0
	for fireteam_id in _selected_fireteam_ids:
		if not _normalize_fireteam_id(String(fireteam_id)).is_empty():
			assigned_count += 1
	return "Ausgewählt: %d · Truppzuordnung: %d\nKräfte auf Truppkarten ziehen; Trupps anschließend zum Transport." % [_selected_unit_ids.size(), assigned_count]


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
	if _operations_presenter != null and _operations_mode != "legacy":
		_operations_presenter.call("refresh")
		return
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
	if _should_use_homebase_direct_mission_copy():
		var payload_operator_count: int = _get_homebase_direct_payload_operator_count()
		var payload_fireteam_count: int = _get_homebase_direct_payload_fireteam_ids().size()
		var boarded_operator_count: int = _get_homebase_direct_boarded_operator_count()
		if payload_operator_count > 0 and boarded_operator_count >= payload_operator_count:
			return "%s is ready as Homebase Direct sortie. Payload: %d ops / %d FT boarded, pilot assigned. Press Start Mission, then choose LZ, Drop, Preview and GO." % [_selected_mission_name, payload_operator_count, payload_fireteam_count]
		if payload_operator_count > 0:
			return "%s is staged as Homebase Direct sortie. Payload boarding: %d / %d NPC. Wait for boarding, then press Start Mission." % [_selected_mission_name, boarded_operator_count, payload_operator_count]
		return "%s is a Homebase Direct sortie. Put a Fireteam into a Dropship and assign a pilot before Start Mission." % _selected_mission_name
	var aircraft_snapshot: Dictionary = _aircraft_manager.get_contract_snapshot()
	var has_aircraft_activity: bool = int(aircraft_snapshot.get("pilot_transfer_count", 0)) > 0 or int(aircraft_snapshot.get("cargo_load_count", 0)) > 0
	if not _team_transfer_entries.is_empty() or has_aircraft_activity:
		return "%s on %s is active. Mission occupancy is currently %d / %d including pilots, and confirmed transfers stay visible in Homebase until arrival." % [_selected_mission_name, _build_selected_mission_map_label(), mission_slot_usage, _selected_mission_slot_count]

	if staged_count <= 0:
		return "%s uses %s as current map. Mission occupancy is %d / %d including pilots; the center window starts empty and defines the next transfer package." % [_selected_mission_name, _build_selected_mission_map_label(), mission_slot_usage, _selected_mission_slot_count]

	if staged_count >= team_capacity:
		return "The transfer package for %s is full. Mission occupancy is %d / %d including pilots; review the staged operators and send the team to FOB when ready." % [_selected_mission_name, mission_slot_usage, _selected_mission_slot_count]

	return "The transfer package is still open. You can stage %d more operator(s) before the current Homebase mission limit is reached." % [team_capacity - staged_count]


func _build_mission_slot_status_text(mission_slot_usage: int, pilot_count: int, payload_operator_count: int, payload_fireteam_count: int) -> String:
	if _should_use_homebase_direct_mission_copy():
		return "Mission payload: %d ops / %d FT | Pilot: %d" % [payload_operator_count, payload_fireteam_count, pilot_count]
	return "Mission slots: %d / %d" % [mission_slot_usage, _selected_mission_slot_count]


func _build_mission_transfer_status_text(staged_count: int, team_capacity: int, pilot_count: int, launch_text: String, direct_payload_status_text: String, direct_payload_ready: bool, can_start_mission: bool) -> String:
	if _should_use_homebase_direct_mission_copy():
		var readiness_text: String = "Start Mission ready" if can_start_mission else "Start Mission blocked"
		var sortie_text: String = "Direct sortie ready" if direct_payload_ready else "Direct sortie staging"
		return "Map: %s | %s | Pilots: %d | %s | %s" % [_build_selected_mission_map_label(), sortie_text, pilot_count, readiness_text, direct_payload_status_text]
	return "Map: %s | Transfer: %s | Pilots: %d | %s | %s" % [_build_selected_mission_map_label(), _build_transfer_status_text(staged_count, team_capacity), pilot_count, launch_text, direct_payload_status_text]


func _should_use_homebase_direct_mission_copy() -> bool:
	return _has_homebase_direct_launch_payload() \
		or _get_homebase_direct_payload_operator_count() > 0 \
		or not _get_homebase_direct_payload_craft_id().is_empty()


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
	var craft_name: String = FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_display_name(craft_def)
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
	ship_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var selected_texture: Texture2D = _get_aircraft_texture(craft_def)
	var model_preview: Texture2D = FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_preview_texture(craft_def)
	var is_model_preview: bool = model_preview != null and selected_texture == model_preview
	# Choose the model's uncropped geometry before the first size write. Setting
	# the old Speeder minimum first would clamp this detached Control to 128x84.
	var image_size: Vector2 = HOMEBASE_SHIPCARD_BUTTON_SIZE if is_model_preview else HOMEBASE_SHIPCARD_IMAGE_SIZE
	ship_texture.custom_minimum_size = image_size
	ship_texture.texture = selected_texture
	ship_texture.size = image_size
	ship_texture.position = Vector2.ZERO if is_model_preview else HOMEBASE_SHIPCARD_IMAGE_OFFSET
	if is_model_preview:
		ship_texture.set_meta("frontier_model_preview", true)
		ship_texture.set_meta("frontier_visual_asset_id", String(FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_identity(craft_def).get("asset_id", "")))
	ship_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ship_texture.set_meta("homebase_shipcard_visual_anchor", "left_top")
	ship_texture.set_meta("homebase_shipcard_visual_offset", ship_texture.position)
	ship_texture.set_meta("homebase_shipcard_visual_enlarged", ship_texture.size.x > HOMEBASE_SHIPCARD_BUTTON_SIZE.x)
	ship_texture.set_meta("homebase_shipcard_visual_crop_compensates_transparency", not bool(ship_texture.get_meta("frontier_model_preview", false)))
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
	mission_toggle.text = "Einsatz"
	mission_toggle.button_pressed = dispatch_target == HOMEBASE_DISPATCH_TARGET_MISSION
	mission_toggle.disabled = craft_in_transit or air_asset_unavailable
	mission_toggle.custom_minimum_size = Vector2(64.0, 20.0)
	mission_toggle.add_theme_font_size_override("font_size", 8)
	mission_toggle.tooltip_text = "An: direkt zum Einsatz. Aus: Transfer zur FOB."
	mission_toggle.set_meta("homebase_shipcard_dispatch_toggle", true)
	mission_toggle.set_meta("craft_id", craft_id)
	mission_toggle.set_meta("dispatch_target", dispatch_target)
	mission_toggle.toggled.connect(_on_shipcard_dispatch_target_toggled.bind(craft_id))
	actions.add_child(mission_toggle)

	var send_button := Button.new()
	send_button.name = "ShipSendButton"
	send_button.text = "Starten"
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
		return "Keine Einsatzkräfte zugewiesen"
	var total_count: int = _build_unit_ids_for_fireteams(payload_fireteam_ids).size()
	var boarded_count: int = _get_homebase_direct_boarded_operator_count_for_craft(normalized_craft_id)
	if _are_homebase_payload_fireteams_boarded(payload_fireteam_ids):
		return "Einsatzkräfte: %d/%d an Bord" % [boarded_count, total_count]
	return "Einschiffen: %d/%d Kräfte" % [boarded_count, total_count]


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
	var border: Color = TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER
	if is_selected:
		border = TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER_SELECTED
	elif craft_in_transit:
		border = TACTICAL_UI_THEME_SCRIPT.COLOR_ACCENT
	elif craft_busy:
		border = TACTICAL_UI_THEME_SCRIPT.COLOR_WARNING
	return TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(
		TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_SELECTED if is_selected else TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL,
		border, 6, 2 if is_selected else 1, Vector4.ZERO
	)


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
		selector.add_item(FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_display_name(craft_option))
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
	var preview: Texture2D = FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_preview_texture(craft_def)
	if preview != null:
		return preview
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
	return PORTRAIT_CATALOG_SCRIPT.load_texture("", portrait_path) if not portrait_path.is_empty() else null


func _ensure_operations_presenter() -> void:
	if _operations_presenter != null:
		return
	_operations_presenter = OPERATIONS_PRESENTER_SCRIPT.new()
	_operations_presenter.name = "OperationsRoot"
	add_child(_operations_presenter)
	_operations_presenter.call("configure", self)
	var popup := get_node_or_null("CharacterSheetPopup") as Control
	if popup != null:
		popup.z_index = 100
	_operations_return_button = Button.new()
	_operations_return_button.name = "OperationsReturnButton"
	_operations_return_button.text = "‹ Zur Truppansicht"
	_operations_return_button.position = Vector2(18, 14)
	_operations_return_button.custom_minimum_size = Vector2(208, 44)
	_operations_return_button.add_theme_font_size_override("font_size", 18)
	_operations_return_button.z_index = 200
	add_child(_operations_return_button)
	_operations_return_button.pressed.connect(func(): request_operation("navigate", {"mode": "squad"}))
	visibility_changed.connect(_sync_operations_visibility)


func _sync_operations_visibility() -> void:
	if _operations_presenter == null:
		return
	var legacy: bool = _operations_mode == "legacy"
	var panel := get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = legacy
	var old_header := get_node_or_null("DropLightTopbar") as Control
	if old_header != null:
		old_header.visible = legacy
	_operations_presenter.visible = not legacy
	if _operations_return_button != null:
		_operations_return_button.visible = legacy


func _operations_payload_craft_for_team(fireteam_id: String) -> String:
	if fireteam_id.is_empty():
		return ""
	for craft_id_variant in _get_homebase_direct_payload_craft_keys():
		var craft_id: String = String(craft_id_variant)
		if _get_homebase_direct_payload_fireteam_ids_for_craft_raw(craft_id).has(fireteam_id):
			return craft_id
	return ""


func _operations_craft_busy(craft_id: String) -> bool:
	if craft_id.is_empty():
		return true
	return _is_craft_in_transit(craft_id) or _has_active_pilot_transfer_for_craft(craft_id) or _has_active_cargo_load_for_craft(craft_id) or _get_aircraft_location(craft_id) != "homebase"


func _operations_unit_entry(unit_data: Dictionary) -> Dictionary:
	var id: String = String(unit_data.get("unit_id", "")).strip_edges()
	var profile = _profiles_by_id.get(id, null)
	var fireteam_id: String = _get_fireteam_id_for_unit(id)
	var payload_craft: String = _operations_payload_craft_for_team(fireteam_id)
	var pilot_craft: String = _find_assigned_craft_for_unit(id)
	var in_transit: bool = not _find_transfer_entry_for_unit(id).is_empty()
	var busy: bool = in_transit or not pilot_craft.is_empty() or not payload_craft.is_empty()
	var role_id: String = String(unit_data.get("roster_role_category", unit_data.get("role_id", "")))
	var role_names: Dictionary = {"leader": "Truppführung", "medic": "Sanität", "engineer": "Technik", "pilot": "Pilot", "shooter": "Schütze", "heavy_support": "Unterstützung", "scout_sniper": "Aufklärung"}
	var role: String = String(role_names.get(role_id, String(profile.role_name) if profile != null else String(unit_data.get("role_name", "Operator"))))
	var status: String = "Bereit"
	if in_transit:
		status = "Unterwegs"
	elif not payload_craft.is_empty():
		status = "An Bord" if _are_homebase_payload_fireteams_boarded(PackedStringArray([fireteam_id])) else "Boarding"
	elif not pilot_craft.is_empty():
		status = "Pilot zugewiesen"
	elif not fireteam_id.is_empty():
		status = "Im Trupp · %s" % _get_fireteam_label(fireteam_id)
	var focused_members: PackedStringArray = _get_member_unit_ids_for_fireteam(_focused_fireteam_id)
	var target_busy: bool = not _operations_payload_craft_for_team(_focused_fireteam_id).is_empty()
	var capacity_available: bool = _selected_unit_ids.has(id) or _selected_unit_ids.size() < _get_team_capacity()
	return {"id": id, "name": _build_display_name(id), "role": role, "status": status,
		"portrait_id": String(profile.portrait_id) if profile != null else String(unit_data.get("portrait_id", "")),
		"portrait_path": String(profile.portrait_path) if profile != null else String(unit_data.get("portrait_path", "")),
		"fireteam_id": fireteam_id, "busy": busy, "in_transit": in_transit,
		"can_assign": not busy and not target_busy and fireteam_id != _focused_fireteam_id and focused_members.size() < 4 and capacity_available,
		"can_remove": not busy and not fireteam_id.is_empty(),
		"can_edit": not busy and not fireteam_id.is_empty(), "loadout": _get_member_loadout(id)}


func get_operations_snapshot() -> Dictionary:
	# Read-only projection: never sanitize, seed, advance timers or change owners.
	var roster: Array = []
	var by_id: Dictionary = {}
	for unit_variant in _available_units:
		var unit: Dictionary = _operations_unit_entry(Dictionary(unit_variant))
		roster.append(unit)
		by_id[String(unit.get("id", ""))] = unit
	var fireteams: Array = []
	var focused_team: Dictionary = {}
	for definition_variant in _fireteam_definitions:
		var definition: Dictionary = Dictionary(definition_variant)
		var id: String = _normalize_fireteam_id(String(definition.get("id", "")))
		var members: Array = []
		for unit_id in _get_member_unit_ids_for_fireteam(id):
			if by_id.has(String(unit_id)):
				members.append(Dictionary(by_id[String(unit_id)]).duplicate(true))
		var team: Dictionary = {"id": id, "label": _get_fireteam_label(id), "members": members,
			"busy": not _operations_payload_craft_for_team(id).is_empty(), "lead_unit_id": String(definition.get("lead_unit_id", ""))}
		fireteams.append(team)
		if id == _focused_fireteam_id:
			focused_team = team
	var crafts: Array = []
	var selected_craft: Dictionary = {}
	for craft_variant in _aircraft_manager.get_aircraft_definitions():
		var definition: Dictionary = Dictionary(craft_variant)
		var id: String = String(definition.get("craft_id", ""))
		var pilot_id: String = _get_assigned_pilot_id(id)
		var busy: bool = _operations_craft_busy(id)
		var payload_teams: PackedStringArray = _get_homebase_direct_payload_fireteam_ids_for_craft_raw(id)
		var payload_ids: PackedStringArray = _build_unit_ids_for_fireteams(payload_teams)
		var gate: Dictionary = _build_homebase_direct_staging_craft_gate_for_craft(id)
		var boarded: bool = not payload_teams.is_empty() and _are_homebase_payload_fireteams_boarded(payload_teams)
		var can_start: bool = not busy and not pilot_id.is_empty() and _can_send_craft(definition, id) and _has_homebase_direct_launch_payload_for_craft(id)
		var pilots: Array = [{"id": "", "label": "Pilot auswählen"}]
		for unit_variant in roster:
			var unit: Dictionary = Dictionary(unit_variant)
			if String(unit.id) == pilot_id or (not bool(unit.busy) and String(unit.fireteam_id).is_empty() and not _selected_unit_ids.has(String(unit.id))):
				pilots.append({"id": String(unit.id), "label": String(unit.name)})
		var progress: float = _get_homebase_direct_boarding_progress_ratio_for_craft(id) * 100.0
		var status: String = "Bereit" if can_start else "Vorbereitung"
		var next_step: String = "Boarding starten"
		if busy:
			status = "Unterwegs" if _is_craft_in_transit(id) else "Im Einsatz"
			var transfer: Dictionary = _find_transfer_entry_for_craft(id)
			progress = _build_transfer_progress_value(transfer) if not transfer.is_empty() else 0.0
			next_step = "Rückkehr abwarten"
		elif pilot_id.is_empty():
			status = "Pilot fehlt"
			next_step = "Pilot auswählen"
		elif not payload_teams.is_empty() and not boarded:
			status = "Boarding läuft"
			next_step = "Boarding abwarten"
		elif can_start:
			next_step = "Einsatz starten"
		var craft: Dictionary = {"id": id, "name": String(definition.get("display_name", "Dropship")),
			"texture_path": String(definition.get("texture_path", "")), "pilot_id": pilot_id,
			"pilot_name": _build_display_name(pilot_id) if not pilot_id.is_empty() else "", "pilot_options": pilots,
			"busy": busy, "status": status, "progress": progress, "next_step": next_step,
			"has_payload": not payload_teams.is_empty(), "payload_fireteam_ids": Array(payload_teams),
			"passenger_count": payload_ids.size(), "can_start": can_start,
			"can_board": not busy and bool(gate.get("can_stage", false)) and not Array(focused_team.get("members", [])).is_empty() and not bool(focused_team.get("busy", false)),
			"can_unboard": not busy and payload_teams.has(_focused_fireteam_id)}
		var preview: Texture2D = _get_aircraft_texture(definition)
		craft["texture_path"] = preview.resource_path if preview != null else ""
		craft["name"] = FRONTIER_SHIP_VISUALS_SCRIPT.get_ui_display_name(definition)
		crafts.append(craft)
		if id == _get_selected_aircraft_id():
			selected_craft = craft
	if selected_craft.is_empty() and not crafts.is_empty():
		selected_craft = Dictionary(crafts[0])
	var missions: Array = []
	for mission_variant in _mission_catalog:
		var mission: Dictionary = Dictionary(mission_variant)
		missions.append({"id": String(mission.get("id", mission.get("mission_id", ""))), "label": String(mission.get("display_name", mission.get("mission_name", mission.get("name", "Einsatz"))))})
	return {"mode": _operations_mode, "roster": roster, "fireteams": fireteams,
		"focused_fireteam_id": _focused_fireteam_id, "focused_fireteam": focused_team,
		"focused_unit": Dictionary(by_id.get(_focused_unit_id, {})).duplicate(true),
		"crafts": crafts, "selected_craft": selected_craft, "missions": missions,
		"mission_id": _selected_mission_id, "mission_name": _selected_mission_name,
		"loadout_options": {"armor": LOADOUT_CONTRACT_SCRIPT.get_compact_armor_options(), "weapon_1": LOADOUT_CONTRACT_SCRIPT.get_homebase_primary_weapon_options(), "weapon_2": LOADOUT_CONTRACT_SCRIPT.get_homebase_secondary_weapon_options()},
		"presentation": _operations_presenter.call("get_presentation_snapshot") if _operations_presenter != null else {}}


func request_operation(operation: String, payload: Dictionary = {}) -> Dictionary:
	var unit_id: String = String(payload.get("unit_id", _focused_unit_id)).strip_edges()
	var team_id: String = _normalize_fireteam_id(String(payload.get("fireteam_id", _focused_fireteam_id)))
	var craft_id: String = String(payload.get("craft_id", _get_selected_aircraft_id())).strip_edges()
	match operation:
		"navigate":
			var mode: String = String(payload.get("mode", "squad"))
			if not ["base", "personnel", "squad", "mission"].has(mode):
				return _operations_rejected("invalid_mode", "Ansicht nicht verfügbar")
			_operations_mode = mode
			_sync_operations_visibility()
		"legacy":
			return _operations_rejected("legacy_disabled", "Bitte die Operationsnavigation verwenden")
		"focus_unit", "details":
			if not _profiles_by_id.has(unit_id):
				return _operations_rejected("unknown_unit", "Person nicht verfügbar")
			if operation == "details":
				_on_compact_card_open_requested(unit_id, _profiles_by_id[unit_id], "operations")
			else:
				_on_compact_card_pressed(unit_id, _profiles_by_id[unit_id], "operations")
		"focus_fireteam":
			if _get_fireteam_definition(team_id).is_empty():
				return _operations_rejected("unknown_team", "Trupp nicht verfügbar")
			_on_homebase_fireteam_card_pressed(team_id)
		"add_fireteam":
			_on_homebase_add_fireteam_pressed()
		"assign", "remove", "loadout":
			if not _profiles_by_id.has(unit_id):
				return _operations_rejected("unknown_unit", "Person nicht verfügbar")
			var unit: Dictionary = _operations_unit_entry(_get_available_unit_data(unit_id))
			if bool(unit.get("busy", true)):
				return _operations_rejected("unit_busy", "Kraft ist an Bord, zugewiesen oder unterwegs")
			_focused_unit_id = unit_id
			if operation == "assign":
				if _get_fireteam_definition(team_id).is_empty() or not _operations_payload_craft_for_team(team_id).is_empty():
					return _operations_rejected("team_busy", "Trupp ist nicht für die Vorbereitung verfügbar")
				if _get_member_unit_ids_for_fireteam(team_id).size() >= 4 and String(unit.get("fireteam_id", "")) != team_id:
					return _operations_rejected("team_full", "Vier Truppplätze sind belegt")
				_on_homebase_fireteam_card_pressed(team_id)
				_on_homebase_assign_focused_unit_pressed()
				if _get_fireteam_id_for_unit(unit_id) != team_id:
					return _operations_rejected("assignment_blocked", "Kein freier Einsatzplatz")
			elif operation == "remove":
				if String(unit.get("fireteam_id", "")).is_empty():
					return _operations_rejected("not_assigned", "Person ist keinem Trupp zugewiesen")
				_on_homebase_clear_focused_unit_pressed()
				_on_remove_button_pressed(unit_id)
			else:
				if not bool(unit.get("can_edit", false)):
					return _operations_rejected("not_assigned", "Person zuerst einem Trupp zuweisen")
				var key: String = String(payload.get("key", ""))
				var value: String = String(payload.get("value", ""))
				var options: Dictionary = {"armor": LOADOUT_CONTRACT_SCRIPT.get_compact_armor_options(), "weapon_1": LOADOUT_CONTRACT_SCRIPT.get_homebase_primary_weapon_options(), "weapon_2": LOADOUT_CONTRACT_SCRIPT.get_homebase_secondary_weapon_options()}
				var allowed: bool = false
				for option_variant in Array(options.get(key, [])):
					if String(Dictionary(option_variant).get("id", "")) == value:
						allowed = true
				if not allowed:
					return _operations_rejected("invalid_equipment", "Ausrüstung nicht verfügbar")
				_set_homebase_member_loadout_value(unit_id, key, value)
				_emit_homebase_fireteam_context_changed()
		"craft":
			if _get_aircraft_definition_by_id(craft_id).is_empty():
				return _operations_rejected("unknown_craft", "Schiff nicht verfügbar")
			_on_shipcard_select_requested(craft_id)
		"pilot", "board", "unboard", "start":
			if _get_aircraft_definition_by_id(craft_id).is_empty() or _operations_craft_busy(craft_id):
				return _operations_rejected("craft_busy", "Schiff ist nicht an der Heimatbasis verfügbar")
			if operation == "pilot":
				if unit_id.is_empty():
					_on_clear_pilot_button_pressed(craft_id)
				elif not _profiles_by_id.has(unit_id) or _selected_unit_ids.has(unit_id) or not _find_transfer_entry_for_unit(unit_id).is_empty():
					return _operations_rejected("pilot_busy", "Pilot ist nicht verfügbar")
				else:
					var previous: String = _find_assigned_craft_for_unit(unit_id)
					if not previous.is_empty() and previous != craft_id and _operations_craft_busy(previous):
						return _operations_rejected("pilot_busy", "Pilot ist unterwegs")
					_on_aircraft_pilot_drop_panel_unit_dropped(unit_id, craft_id)
			elif operation == "board":
				if _get_fireteam_definition(team_id).is_empty() or _get_member_unit_ids_for_fireteam(team_id).is_empty() or not _operations_payload_craft_for_team(team_id).is_empty() or not bool(_build_homebase_direct_staging_craft_gate_for_craft(craft_id).get("can_stage", false)):
					return _operations_rejected("boarding_blocked", "Trupp und Pilot für Boarding vorbereiten")
				_on_shipcard_dispatch_target_toggled(true, craft_id)
				_on_homebase_shipcard_fireteam_dropped(team_id, craft_id)
			elif operation == "unboard":
				if not _get_homebase_direct_payload_fireteam_ids_for_craft_raw(craft_id).has(team_id):
					return _operations_rejected("not_embarked", "Dieser Trupp ist nicht im Schiff")
				_on_homebase_dropship_fireteam_remove_pressed(team_id, craft_id)
			else:
				if _get_assigned_pilot_id(craft_id).is_empty() or not _has_homebase_direct_launch_payload_for_craft(craft_id) or not _can_send_craft(_get_aircraft_definition_by_id(craft_id), craft_id):
					return _operations_rejected("launch_blocked", "Pilot, Trupp und Boarding prüfen")
				_on_shipcard_dispatch_target_toggled(true, craft_id)
				_on_send_pilot_button_pressed(craft_id)
		"mission":
			var mission_id: String = String(payload.get("mission_id", ""))
			var found: bool = false
			for mission_variant in _mission_catalog:
				var mission: Dictionary = Dictionary(mission_variant)
				if String(mission.get("id", mission.get("mission_id", ""))) == mission_id:
					found = true
			if not found:
				return _operations_rejected("unknown_mission", "Einsatz nicht verfügbar")
			mission_selection_changed.emit(mission_id)
		_:
			return _operations_rejected("unknown_operation", "Aktion nicht verfügbar")
	if _operations_presenter != null:
		_operations_presenter.call("refresh")
	_sync_operations_visibility()
	return {"ok": true, "operation": operation, "message": ""}


func _operations_rejected(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}


func _get_team_drop_panel():
	return get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel")


func _get_roster_drop_panel():
	return get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel")


func _node_is_visible(path: String) -> bool:
	var control := get_node_or_null(path) as Control
	return control != null and control.visible and (control.is_visible_in_tree() if control.is_inside_tree() else true)


func _control_global_rect(control: Control) -> Rect2:
	if control == null:
		return Rect2()
	return Rect2(control.global_position, control.size)


func _rects_overlap(first: Rect2, second: Rect2) -> bool:
	if first.size == Vector2.ZERO or second.size == Vector2.ZERO:
		return false
	return first.intersects(second)


func _visible_child_max_bottom(root_control: Control) -> float:
	if root_control == null:
		return 0.0
	var max_bottom: float = root_control.global_position.y
	for child in root_control.get_children():
		var child_control := child as Control
		if child_control == null or not child_control.visible:
			continue
		var child_rect := _control_global_rect(child_control)
		max_bottom = maxf(max_bottom, child_rect.end.y)
		max_bottom = maxf(max_bottom, _visible_child_max_bottom(child_control))
	return max_bottom


func _clear_container(container: Node) -> void:
	if container == null:
		return

	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
