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
const HOMEBASE_TEAM_DROP_PANEL_SCRIPT: GDScript = preload("res://scripts/meta/homebase_team_drop_panel.gd")
const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const HOVER_SCROLL_BEHAVIOR_SCRIPT: GDScript = preload("res://scripts/ui/hover_scroll_behavior.gd")
const FLIGHTDECK_PLATFORM_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/platform_large_NW.png")
const DROPSHIP_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png")
const CARGO_CRAFT_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_cargoA_NE.png")
const HOMEBASE_OPERATOR_CARD_SIZE := Vector2(316.0, 66.0)
const HOMEBASE_STAGED_CARD_SIZE := Vector2(316.0, 66.0)
const HOMEBASE_TRANSFER_GHOST_CARD_SIZE := Vector2(316.0, 74.0)
const HOMEBASE_SHIPCARD_IMAGE_SIZE := Vector2(248.0, 164.0)
const HOMEBASE_SHIPCARD_BUTTON_SIZE := Vector2(166.0, 114.0)
const HOMEBASE_SHIPCARD_IMAGE_OFFSET := Vector2(-58.0, -36.0)

signal selection_changed(selected_unit_ids)
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
var _profiles_by_id: Dictionary = {}
var _focused_unit_id: String = ""
var _roster_cards_by_unit_id: Dictionary = {}
var _staged_cards_by_unit_id: Dictionary = {}
var _team_feedback_text: String = ""
var _character_sheet_open: bool = false
var _aircraft_feedback_text: String = ""
var _mission_catalog: Array = []
var _selected_mission_id: String = "fob_transfer"
var _selected_mission_map_path: String = "res://maps/test_mission.json"
var _selected_mission_name: String = "Operation: FOB Transfer"
var _selected_mission_slot_count: int = 3
var _mission_launch_ready: bool = false
var _mission_launch_summary: String = ""
var _mission_slot_usage_override: int = -1
var _mission_pilot_count_override: int = -1
var _aircraft_definitions: Array = []
var _assigned_pilot_by_craft: Dictionary = {}
var _aircraft_location_by_craft: Dictionary = {}
var _selected_cargo_by_craft: Dictionary = {}
var _loaded_cargo_by_craft: Dictionary = {}
var _team_transfer_entries: Array = []
var _pilot_transfer_entries: Array = []
var _cargo_load_entries: Array = []
var _selected_aircraft_id: String = ""
var _personnel_events: Array = []


func _ready() -> void:
	META_UI_SKIN_SCRIPT.apply_homebase(self)
	_apply_drop_light_fixed_layout()
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

	_rebuild_profiles()
	_rebuild_ui()


func setup_roster(available_units: Array, selected_unit_ids: PackedStringArray = []) -> void:
	_available_units = available_units.duplicate(true)
	_selected_unit_ids = _normalize_selected_unit_ids(selected_unit_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	_team_feedback_text = ""
	if is_inside_tree():
		_rebuild_profiles()
		_rebuild_ui()


func set_fireteam_context(selected_fireteam_ids: PackedStringArray = []) -> void:
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(selected_fireteam_ids)
	if is_inside_tree() and _character_sheet_open:
		_update_character_sheet()


func set_mission_context(mission_catalog: Array, selected_map_path: String, mission_name: String, mission_slot_count: int, selected_mission_id: String = "") -> void:
	_mission_catalog = mission_catalog.duplicate(true)
	_selected_mission_id = selected_mission_id.strip_edges() if not selected_mission_id.strip_edges().is_empty() else _selected_mission_id
	_selected_mission_map_path = selected_map_path.strip_edges() if not selected_map_path.strip_edges().is_empty() else _selected_mission_map_path
	_selected_mission_name = mission_name.strip_edges() if not mission_name.strip_edges().is_empty() else _selected_mission_name
	_selected_mission_slot_count = maxi(mission_slot_count, 1)
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
	_aircraft_definitions = aircraft_definitions.duplicate(true)
	_assigned_pilot_by_craft = assigned_pilot_by_craft.duplicate(true)
	_aircraft_location_by_craft = aircraft_location_by_craft.duplicate(true)
	_selected_cargo_by_craft = selected_cargo_by_craft.duplicate(true)
	_loaded_cargo_by_craft = loaded_cargo_by_craft.duplicate(true)
	_team_transfer_entries = team_transfer_entries.duplicate(true)
	_pilot_transfer_entries = pilot_transfer_entries.duplicate(true)
	_cargo_load_entries = cargo_load_entries.duplicate(true)
	_selected_unit_ids = _normalize_selected_unit_ids(_selected_unit_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	if is_inside_tree():
		_rebuild_ui()


func set_selected_unit_ids(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = _normalize_selected_unit_ids(selected_unit_ids)
	_selected_fireteam_ids = _normalize_selected_fireteam_ids(_selected_fireteam_ids)
	_team_feedback_text = ""
	if is_inside_tree():
		_rebuild_ui()


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


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


func get_aircraft_panel_snapshot() -> Dictionary:
	var selected_craft: Dictionary = _get_selected_aircraft_definition()
	return {
		"selected_aircraft_id": _selected_aircraft_id,
		"visible_aircraft_definitions": _get_visible_homebase_aircraft_definitions(),
		"selected_status_text": _build_aircraft_status_text(
			selected_craft,
			String(selected_craft.get("display_name", _selected_aircraft_id)).strip_edges(),
			_get_assigned_pilot_id(_selected_aircraft_id),
			_has_active_pilot_transfer_for_craft(_selected_aircraft_id) or _is_craft_in_transit(_selected_aircraft_id),
			_has_active_cargo_load_for_craft(_selected_aircraft_id)
		) if not selected_craft.is_empty() else "",
		"can_send_selected": _can_send_craft(selected_craft, _selected_aircraft_id) if not selected_craft.is_empty() else false,
		"can_remove_selected": _can_remove_selected_aircraft(),
		"flightdeck_stage_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage"),
		"deck_activity_visible": _node_is_visible("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll"),
		"shipcards_are_primary_status": true,
	}


func request_mission_start() -> void:
	if not _mission_launch_ready:
		return
	mission_start_requested.emit()


func confirm_selection() -> void:
	if _selected_unit_ids.is_empty():
		return

	team_confirmed.emit(get_selected_unit_ids())


func _rebuild_profiles() -> void:
	_profiles_by_id = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id(_available_units)


func _rebuild_ui() -> void:
	_ensure_focused_unit_id()
	_ensure_selected_aircraft_id()
	_apply_block_labels()
	_apply_homebase_compact_panel_policy()
	_render_roster()
	_render_staged_team()
	_update_mission_info()
	_update_team_summary()
	_update_team_transfer_list()
	_update_aircraft_panel()
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
	_character_sheet_open = true
	_ensure_drop_light_topbar()
	_ensure_drop_light_flightdeck_stage()
	_enforce_drop_light_fixed_layout()
	call_deferred("_enforce_drop_light_fixed_layout")


func _enforce_drop_light_fixed_layout() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_homebase_layout")
	_apply_fixed_window_contract("DropLightTopbar", layout.get("topbar"))
	_apply_fixed_window_contract("Panel/Margin/VBox/MissionPanel", layout.get("mission_brief"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/RosterPanel", layout.get("roster"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/TeamPanel", layout.get("transfer_team"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/AircraftPanel", layout.get("flightdeck"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/InfoPanel", layout.get("character_sheet"))


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


func _set_object_property_if_available(target: Object, property_name: String, value: Variant) -> void:
	if target == null:
		return
	for property_info in target.get_property_list():
		if String(Dictionary(property_info).get("name", "")) == property_name:
			target.set(property_name, value)
			return


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

	for badge_text in ["Roster", "Transfer", "Flightdeck", "Sheet"]:
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
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_FLIGHT_DECK,
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_DECK_ACTIVITY,
		"Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/InfoHeaderRow/InfoHeaderLabel": UI_BLOCK_LABELS_SCRIPT.HOMEBASE_CHARACTER_SHEET,
	}
	for path_variant in label_text_by_path.keys():
		var label := get_node_or_null(String(path_variant)) as Label
		if label != null:
			label.text = String(label_text_by_path[path_variant])


func _apply_homebase_compact_panel_policy() -> void:
	for path in [
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersHeaderLabel",
		"Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ActiveTransfersScroll",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersHeaderLabel",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftTransfersScroll",
		"Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/DropLightFlightdeckStage",
	]:
		var control := get_node_or_null(path) as Control
		if control == null:
			continue
		control.visible = false
		control.custom_minimum_size = Vector2.ZERO
		control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		control.set_meta("homebase_compact_status_hidden", true)

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
	_clear_container(roster_list)
	_roster_cards_by_unit_id.clear()

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
		var card_profile = profile.duplicate_profile()
		card_profile.secondary_text = _build_roster_card_secondary_text(unit_id, card_profile)
		var transit_entry: Dictionary = _find_transfer_entry_for_unit(unit_id)
		var is_in_transit: bool = not transit_entry.is_empty()

		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.setup_from_profile(
			card_profile,
			{
				"source_context": "roster",
				"selected": _is_roster_card_highlighted(unit_id),
				"disabled": is_in_transit,
				"drag_enabled": not is_in_transit and not _selected_unit_ids.has(unit_id),
				"compact_mode": true,
				"show_progress": is_in_transit,
				"progress_value": _build_transfer_progress_value(transit_entry) if is_in_transit else 0.0,
				"fixed_size": true,
				"fixed_card_size": HOMEBASE_OPERATOR_CARD_SIZE,
			}
		)
		if not card.card_pressed.is_connected(_on_compact_card_pressed):
			card.card_pressed.connect(_on_compact_card_pressed)
		if not card.card_open_requested.is_connected(_on_compact_card_open_requested):
			card.card_open_requested.connect(_on_compact_card_open_requested)
		roster_list.add_child(card)
		_roster_cards_by_unit_id[unit_id] = card


func _render_staged_team() -> void:
	var selected_team_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList")
	_clear_container(selected_team_list)
	_staged_cards_by_unit_id.clear()

	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue
		var card_profile = profile.duplicate_profile()
		card_profile.secondary_text = _build_roster_card_secondary_text(unit_id, card_profile)

		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.setup_from_profile(
			card_profile,
			{
				"source_context": "staged",
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
		selected_team_list.add_child(card)
		_staged_cards_by_unit_id[unit_id] = card

	_render_team_transfer_ghost_cards(selected_team_list)


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

			var card_profile = profile.duplicate_profile()
			card_profile.secondary_text = _build_transfer_ghost_secondary_text(entry)

			var card = NPC_COMPACT_CARD_SCENE.instantiate()
			card.set_meta("homebase_transfer_ghost_card", true)
			card.set_meta("transfer_id", String(entry.get("transfer_id", "")).strip_edges())
			card.setup_from_profile(
				card_profile,
				{
					"source_context": "transfer_ghost",
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
	start_mission_button.disabled = not _mission_launch_ready
	start_mission_button.text = "Start"
	META_UI_SKIN_SCRIPT.style_transfer_button(start_mission_button, _mission_launch_ready)
	mission_name_label.text = _selected_mission_name
	mission_team_limit_label.text = "Mission slots: %d / %d" % [mini(mission_slot_usage, _selected_mission_slot_count), _selected_mission_slot_count]
	var launch_text: String = _mission_launch_summary if not _mission_launch_summary.is_empty() else ("Dropship ready for launch" if _mission_launch_ready else "Dropship not launch-ready")
	mission_transfer_label.text = "Map: %s | Transfer: %s | Pilots: %d | %s" % [_build_selected_mission_map_label(), _build_transfer_status_text(staged_count, team_capacity), pilot_count, launch_text]
	mission_summary_label.text = _build_mission_summary_text(staged_count, team_capacity, pilot_count, mission_slot_usage)
	if not _mission_launch_summary.is_empty():
		mission_summary_label.text = "%s\n%s" % [mission_summary_label.text, _mission_launch_summary]
	_update_personnel_notifications()


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

	for craft_variant in visible_aircraft_definitions:
		shipcards_list.add_child(_build_shipcard(Dictionary(craft_variant)))

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
	var profile = _profiles_by_id.get(_focused_unit_id, null)
	CHARACTER_SHEET_VIEW_SCRIPT.render(
		_get_character_sheet_content_host(),
		profile,
		{
			"status_text": _build_sheet_status_text(_focused_unit_id),
			"fireteam_text": _build_homebase_fireteam_text(_focused_unit_id),
			"editable_metrics": false,
			"hide_loadout_dropdowns": true,
		}
	)


func _get_character_sheet_content_host() -> VBoxContainer:
	return get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoScroll/InfoVBox/GeneratedSheetContent") as VBoxContainer


func _on_compact_card_pressed(unit_id: String, _profile, _source_context: String) -> void:
	_remember_card_profile(unit_id, _profile)
	_focused_unit_id = unit_id
	_team_feedback_text = ""
	_update_team_summary()
	if _character_sheet_open:
		_update_character_sheet()
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


func _on_roster_drop_panel_unit_dropped(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var assigned_craft_id: String = _find_assigned_craft_for_unit(normalized_unit_id)
	if not assigned_craft_id.is_empty():
		_assigned_pilot_by_craft.erase(assigned_craft_id)
		_selected_aircraft_id = assigned_craft_id
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
		_selected_aircraft_id = normalized_craft_id
		_update_aircraft_panel()
		return
	if not previous_craft_id.is_empty():
		_assigned_pilot_by_craft.erase(previous_craft_id)

	_selected_aircraft_id = normalized_craft_id
	_assigned_pilot_by_craft[normalized_craft_id] = unit_id
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
	var craft_id: String = _selected_aircraft_id.strip_edges()
	if craft_id.is_empty():
		return
	var cargo_selector: OptionButton = get_node("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftCargoRow/CargoSelector")
	if index < 0 or index >= cargo_selector.item_count:
		return
	var cargo_id: String = String(cargo_selector.get_item_metadata(index)).strip_edges()
	_selected_cargo_by_craft[craft_id] = cargo_id
	_aircraft_feedback_text = ""
	_update_aircraft_panel()
	aircraft_cargo_selected.emit(craft_id, cargo_id)


func _on_add_aircraft_button_pressed() -> void:
	_aircraft_feedback_text = ""
	aircraft_add_requested.emit(_get_selected_aircraft_base_type())


func _on_remove_aircraft_button_pressed() -> void:
	var craft_id: String = _selected_aircraft_id.strip_edges()
	if craft_id.is_empty() or not _can_remove_selected_aircraft():
		return
	_aircraft_feedback_text = ""
	aircraft_remove_requested.emit(craft_id)


func _on_load_cargo_button_pressed() -> void:
	var craft_def: Dictionary = _get_selected_aircraft_definition()
	var craft_id: String = _selected_aircraft_id.strip_edges()
	var cargo_id: String = _get_selected_cargo_id(craft_id)
	if craft_id.is_empty() or cargo_id.is_empty() or not _can_load_selected_cargo(craft_def, craft_id):
		return
	_aircraft_feedback_text = "%s loading started for %s." % [_build_cargo_display_name(craft_def, cargo_id), _build_craft_display_name(craft_id)]
	aircraft_cargo_load_requested.emit(craft_id, cargo_id)


func _on_clear_pilot_button_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	_selected_aircraft_id = normalized_craft_id
	if normalized_craft_id.is_empty() or not _assigned_pilot_by_craft.has(normalized_craft_id):
		return
	var pilot_id: String = String(_assigned_pilot_by_craft.get(normalized_craft_id, "")).strip_edges()
	_assigned_pilot_by_craft.erase(normalized_craft_id)
	_aircraft_feedback_text = "%s removed from %s." % [_build_display_name(pilot_id), _build_craft_display_name(normalized_craft_id)]
	_rebuild_ui()
	aircraft_pilot_cleared.emit(normalized_craft_id)


func _on_send_pilot_button_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	_selected_aircraft_id = normalized_craft_id
	var pilot_id: String = _get_assigned_pilot_id(normalized_craft_id)
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	if normalized_craft_id.is_empty() or pilot_id.is_empty() or not _can_send_craft(craft_def, normalized_craft_id):
		return
	var cargo_text: String = _build_cargo_display_name(craft_def, _get_loaded_cargo_id(normalized_craft_id))
	_aircraft_feedback_text = "%s launched toward FOB%s." % [
		_build_display_name(pilot_id),
		" with %s" % cargo_text if not cargo_text.is_empty() else "",
	]
	aircraft_pilot_transfer_requested.emit(normalized_craft_id, pilot_id)


func _on_shipcard_select_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_selected_aircraft_id = normalized_craft_id
	_update_aircraft_panel()


func _on_shipcard_cargo_selected(index: int, craft_id: String, cargo_selector: OptionButton) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or cargo_selector == null:
		return
	if index < 0 or index >= cargo_selector.item_count:
		return
	var cargo_id: String = String(cargo_selector.get_item_metadata(index)).strip_edges()
	_selected_aircraft_id = normalized_craft_id
	if cargo_id.is_empty():
		_selected_cargo_by_craft.erase(normalized_craft_id)
	else:
		_selected_cargo_by_craft[normalized_craft_id] = cargo_id
	_aircraft_feedback_text = ""
	_update_aircraft_panel()
	aircraft_cargo_selected.emit(normalized_craft_id, cargo_id)


func _on_shipcard_load_cargo_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	var cargo_id: String = _get_selected_cargo_id(normalized_craft_id)
	if normalized_craft_id.is_empty() or cargo_id.is_empty() or not _can_load_selected_cargo(craft_def, normalized_craft_id):
		return
	_selected_aircraft_id = normalized_craft_id
	_aircraft_feedback_text = "%s loading started for %s." % [_build_cargo_display_name(craft_def, cargo_id), _build_craft_display_name(normalized_craft_id)]
	aircraft_cargo_load_requested.emit(normalized_craft_id, cargo_id)


func _on_shipcard_remove_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or not _can_remove_aircraft(normalized_craft_id):
		return
	_selected_aircraft_id = normalized_craft_id
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
	_focused_unit_id = unit_id
	_team_feedback_text = ""
	_rebuild_ui()
	return true


func _remove_unit_from_team(unit_id: String) -> bool:
	if not _selected_unit_ids.has(unit_id):
		return false

	var next_selection: PackedStringArray = []
	for selected_unit_id in _selected_unit_ids:
		if String(selected_unit_id) == unit_id:
			continue

		next_selection.append(String(selected_unit_id))

	_selected_unit_ids = next_selection
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
	var info_panel: Control = get_node("Panel/Margin/VBox/ContentRow/InfoPanel")
	info_panel.visible = _character_sheet_open


func _build_send_to_fob_tooltip() -> String:
	if _selected_unit_ids.is_empty():
		return "SEND TO FOB\n\n- Startet einen Teamtransfer mit Fortschrittsbalken.\n- Vorher mindestens eine Person in die Mitte ziehen."

	return "SEND TO FOB\n\n- Startet den Anflug des aktuell gestagten Teams zur FOB.\n- Der Screen bleibt auf Homebase.\n- Das Team erscheint erst nach Ankunft in der FOB."


func _build_transfer_status_text(staged_count: int, team_capacity: int) -> String:
	var transfer_count: int = _team_transfer_entries.size() + _pilot_transfer_entries.size() + _cargo_load_entries.size()
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
	if not _team_transfer_entries.is_empty() or not _pilot_transfer_entries.is_empty() or not _cargo_load_entries.is_empty():
		return "%s on %s is active. Mission occupancy is currently %d / %d including pilots, and confirmed transfers stay visible in Homebase until arrival." % [_selected_mission_name, _build_selected_mission_map_label(), mini(mission_slot_usage, _selected_mission_slot_count), _selected_mission_slot_count]

	if staged_count <= 0:
		return "%s uses %s as current map. Mission occupancy is %d / %d including pilots; the center window starts empty and defines the next transfer package." % [_selected_mission_name, _build_selected_mission_map_label(), mini(mission_slot_usage, _selected_mission_slot_count), _selected_mission_slot_count]

	if staged_count >= team_capacity:
		return "The transfer package for %s is full. Mission occupancy is %d / %d including pilots; review the staged operators and send the team to FOB when ready." % [_selected_mission_name, mini(mission_slot_usage, _selected_mission_slot_count), _selected_mission_slot_count]

	return "The transfer package is still open. You can stage %d more operator(s) before the current Homebase mission limit is reached." % [team_capacity - staged_count]


func _count_assigned_pilots() -> int:
	var unique_pilot_ids: Dictionary = {}
	for pilot_id_variant in _assigned_pilot_by_craft.values():
		var pilot_id: String = String(pilot_id_variant).strip_edges()
		if pilot_id.is_empty():
			continue
		unique_pilot_ids[pilot_id] = true
	return unique_pilot_ids.size()


func _build_selected_mission_map_label() -> String:
	var map_file_path: String = _selected_mission_map_path.get_file().get_basename()
	if map_file_path.is_empty():
		return "unknown_map"
	return map_file_path


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
	return [
		{
			"craft_id": "dropship_template",
			"craft_type": "dropship",
			"display_name": "Dropship",
			"summary": "Single-pilot shuttle for the FOB corridor.",
			"texture": DROPSHIP_TEXTURE,
			"supports_cargo": false,
			"cargo_options": [],
		},
		{
			"craft_id": "craft_cargoB_template",
			"craft_type": "craft_cargoB",
			"display_name": "Frachter",
			"summary": "Cargo freighter for Rover-sized payloads.",
			"texture": CARGO_CRAFT_TEXTURE,
			"supports_cargo": true,
			"cargo_options": [
				{"cargo_id": "", "display_name": "No Cargo"},
				{"cargo_id": "rover", "display_name": "Rover"},
			],
		}
	]


func _build_aircraft_status_text(craft_def: Dictionary, craft_name: String, assigned_pilot_id: String, craft_busy: bool, cargo_loading: bool) -> String:
	if not _aircraft_feedback_text.is_empty():
		return _aircraft_feedback_text
	var craft_id: String = String(craft_def.get("craft_id", "")).strip_edges()
	if bool(craft_def.get("air_asset_unavailable", false)):
		var meta_state: String = String(craft_def.get("air_asset_meta_status", "")).strip_edges()
		var label: String = "replacement pending" if meta_state == "destroyed_replacement_pending" else "repairing"
		return "%s %s. ETA %ds. Pilot state: %s." % [craft_name, label, int(craft_def.get("air_asset_recovery_eta_seconds", 0)), String(craft_def.get("pilot_recovery_state", "pilot_safe_homebase"))]
	if _is_craft_in_transit(craft_id):
		return "%s is currently in transit between Homebase and FOB." % craft_name
	if cargo_loading:
		return "%s is currently loading %s at Homebase." % [craft_name, _build_cargo_display_name(craft_def, _get_selected_cargo_id(craft_id))]
	if craft_busy:
		return "%s is currently inbound to FOB." % craft_name
	var loaded_cargo_id: String = _get_loaded_cargo_id(craft_id)
	if not loaded_cargo_id.is_empty():
		return "%s ready with %s onboard." % [craft_name, _build_cargo_display_name(craft_def, loaded_cargo_id)]
	if not assigned_pilot_id.is_empty():
		return "%s ready. Pilot %s can launch the ship immediately." % [craft_name, _build_display_name(assigned_pilot_id)]
	if _craft_supports_cargo(craft_def):
		var selected_cargo_id: String = _get_selected_cargo_id(craft_id)
		if not selected_cargo_id.is_empty():
			return "%s idle at Homebase. Selected cargo: %s." % [craft_name, _build_cargo_display_name(craft_def, selected_cargo_id)]
	return "%s idle at Homebase. Assign a pilot to start a solo transfer." % craft_name


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
	var is_selected: bool = craft_id == _selected_aircraft_id

	var loaded_cargo_id: String = _get_loaded_cargo_id(craft_id)
	var selected_cargo_id: String = loaded_cargo_id if not loaded_cargo_id.is_empty() else _get_selected_cargo_id(craft_id)

	var shipcard := PanelContainer.new()
	shipcard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shipcard.custom_minimum_size = Vector2(0.0, 168.0 if cargo_capable else 144.0)
	shipcard.add_theme_stylebox_override("panel", _build_shipcard_stylebox(is_selected, craft_busy or cargo_loading or air_asset_unavailable, craft_in_transit or air_asset_unavailable))
	shipcard.modulate = Color(1.0, 1.0, 1.0, 0.56) if craft_in_transit or air_asset_unavailable else Color(1.0, 1.0, 1.0, 1.0)
	shipcard.set_meta("homebase_shipcard_no_horizontal_overflow", true)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	shipcard.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "ShipcardContentRow"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)

	var ship_box := VBoxContainer.new()
	ship_box.name = "ShipVisualBox"
	ship_box.custom_minimum_size = Vector2(HOMEBASE_SHIPCARD_BUTTON_SIZE.x + 2.0, 0.0)
	ship_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ship_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ship_box.add_theme_constant_override("separation", 1)
	row.add_child(ship_box)

	var ship_label := Label.new()
	ship_label.name = "ShipVisualLabel"
	ship_label.text = "%s%s%s" % [craft_name, " *" if is_selected else "", " | TRANSIT" if craft_in_transit else ""]
	ship_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_label.add_theme_font_size_override("font_size", 9)
	ship_box.add_child(ship_label)

	var ship_button := Button.new()
	ship_button.name = "ShipVisualButton"
	ship_button.flat = true
	ship_button.focus_mode = Control.FOCUS_NONE
	ship_button.custom_minimum_size = HOMEBASE_SHIPCARD_BUTTON_SIZE
	ship_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	ship_button.clip_contents = true
	ship_button.pressed.connect(_on_shipcard_select_requested.bind(craft_id))
	ship_box.add_child(ship_button)

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

	if cargo_capable:
		var cargo_label := Label.new()
		cargo_label.text = _build_shipcard_cargo_status_text(craft_def, craft_id)
		cargo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cargo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cargo_label.add_theme_font_size_override("font_size", 8)
		ship_box.add_child(cargo_label)

	if craft_in_transit:
		var transit_label := Label.new()
		transit_label.text = "ETA FOB: %s" % _build_transfer_eta_text(_find_transfer_entry_for_craft(craft_id))
		transit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		transit_label.add_theme_font_size_override("font_size", 8)
		ship_box.add_child(transit_label)
	elif air_asset_unavailable:
		var recovery_label := Label.new()
		recovery_label.text = "Recovery ETA: %ds" % int(craft_def.get("air_asset_recovery_eta_seconds", 0))
		recovery_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		recovery_label.add_theme_font_size_override("font_size", 8)
		ship_box.add_child(recovery_label)

	var content_vbox := VBoxContainer.new()
	content_vbox.name = "ShipcardInfoVBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	content_vbox.add_theme_constant_override("separation", 4)
	row.add_child(content_vbox)

	var pilot_panel: PanelContainer = _build_shipcard_pilot_panel(craft_id, craft_name, assigned_pilot_id, craft_busy or cargo_loading or air_asset_unavailable, craft_in_transit or air_asset_unavailable)
	pilot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_child(pilot_panel)

	if cargo_capable:
		var cargo_row := HBoxContainer.new()
		cargo_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cargo_row.add_theme_constant_override("separation", 4)
		content_vbox.add_child(cargo_row)

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
		content_vbox.add_child(progress_block)

	var actions := VBoxContainer.new()
	actions.name = "ShipActionColumn"
	actions.alignment = BoxContainer.ALIGNMENT_BEGIN
	actions.custom_minimum_size = Vector2(44.0, 0.0)
	actions.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	actions.add_theme_constant_override("separation", 3)
	actions.set_meta("homebase_actions_top_aligned", true)
	row.add_child(actions)

	var send_button := Button.new()
	send_button.text = "Send"
	send_button.custom_minimum_size = Vector2(42.0, 22.0)
	send_button.add_theme_font_size_override("font_size", 8)
	send_button.disabled = air_asset_unavailable or assigned_pilot_id.is_empty() or not _can_send_craft(craft_def, craft_id)
	META_UI_SKIN_SCRIPT.style_transfer_button(send_button, not send_button.disabled)
	send_button.pressed.connect(_on_send_pilot_button_pressed.bind(craft_id))
	actions.add_child(send_button)

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.custom_minimum_size = Vector2(42.0, 20.0)
	clear_button.add_theme_font_size_override("font_size", 8)
	clear_button.disabled = assigned_pilot_id.is_empty() or craft_in_transit or air_asset_unavailable
	META_UI_SKIN_SCRIPT.style_secondary_button(clear_button)
	clear_button.pressed.connect(_on_clear_pilot_button_pressed.bind(craft_id))
	actions.add_child(clear_button)

	var remove_button := Button.new()
	remove_button.text = "X"
	remove_button.tooltip_text = "Remove this shipcard from the flight deck."
	remove_button.custom_minimum_size = Vector2(42.0, 20.0)
	remove_button.add_theme_font_size_override("font_size", 8)
	remove_button.disabled = not _can_remove_aircraft(craft_id)
	META_UI_SKIN_SCRIPT.style_secondary_button(remove_button)
	remove_button.pressed.connect(_on_shipcard_remove_requested.bind(craft_id))
	actions.add_child(remove_button)

	return shipcard


func _build_shipcard_progress_block(craft_id: String, cargo_loading: bool, craft_in_transit: bool) -> Control:
	var entry: Dictionary = _find_transfer_entry_for_craft(craft_id)
	var label_text := "Inbound to FOB"
	if entry.is_empty() and cargo_loading:
		entry = _find_cargo_load_entry_for_craft(craft_id)
		label_text = "Cargo loading"
	if entry.is_empty() or (not craft_in_transit and not cargo_loading):
		return null

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)

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
	vbox.add_child(progress_bar)
	return vbox


func _build_shipcard_pilot_panel(craft_id: String, craft_name: String, assigned_pilot_id: String, craft_busy: bool, craft_in_transit: bool = false) -> PanelContainer:
	var drop_panel := PanelContainer.new()
	drop_panel.custom_minimum_size = Vector2(0.0, 52.0)
	drop_panel.mouse_filter = Control.MOUSE_FILTER_PASS
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

	host.add_child(_build_assigned_pilot_row(assigned_pilot_id, craft_name, craft_busy, craft_in_transit))
	return drop_panel


func _build_assigned_pilot_row(unit_id: String, craft_name: String, craft_busy: bool = false, craft_in_transit: bool = false) -> Control:
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return _build_empty_state_label("Pilot profile unavailable.")

	var card_profile = profile.duplicate_profile()
	card_profile.secondary_text = "Inbound to FOB / %s" % craft_name if craft_in_transit else "Assigned to %s" % craft_name
	var card = NPC_COMPACT_CARD_SCENE.instantiate()
	card.setup_from_profile(
		card_profile,
		{
			"source_context": "aircraft_shipcard",
			"selected": unit_id == _focused_unit_id,
			"disabled": craft_in_transit,
			"drag_enabled": not craft_busy,
			"compact_mode": true,
		}
	)
	if not card.card_pressed.is_connected(_on_compact_card_pressed):
		card.card_pressed.connect(_on_compact_card_pressed)
	if not card.card_open_requested.is_connected(_on_compact_card_open_requested):
		card.card_open_requested.connect(_on_compact_card_open_requested)
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
	var entries: Array = []
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() != craft_id:
			continue
		entries.append(entry)
	return entries


func _get_selected_aircraft_definition() -> Dictionary:
	for entry_variant in _get_visible_homebase_aircraft_definitions():
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == _selected_aircraft_id:
			return entry
	return {}


func _get_selected_aircraft_base_type() -> String:
	var selector: OptionButton = get_node_or_null("Panel/Margin/VBox/ContentRow/AircraftPanel/AircraftMargin/AircraftVBox/AircraftSelectorRow/AircraftSelector")
	if selector != null and selector.selected >= 0 and selector.selected < selector.item_count:
		var selected_type: String = String(selector.get_item_metadata(selector.selected)).strip_edges()
		if not selected_type.is_empty():
			return selected_type
	return "dropship"


func _get_aircraft_definition_by_id(craft_id: String) -> Dictionary:
	for entry_variant in _aircraft_definitions:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry
	return {}


func _ensure_selected_aircraft_id() -> void:
	var visible_aircraft_definitions: Array = _get_visible_homebase_aircraft_definitions()
	if not _selected_aircraft_id.is_empty():
		for entry_variant in visible_aircraft_definitions:
			var entry: Dictionary = Dictionary(entry_variant)
			if String(entry.get("craft_id", "")).strip_edges() == _selected_aircraft_id:
				return
	if visible_aircraft_definitions.is_empty():
		_selected_aircraft_id = ""
		return
	_selected_aircraft_id = String(Dictionary(visible_aircraft_definitions[0]).get("craft_id", "")).strip_edges()


func _can_remove_selected_aircraft() -> bool:
	return _can_remove_aircraft(_selected_aircraft_id)


func _can_remove_aircraft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return false
	var craft_def: Dictionary = _get_aircraft_definition_by_id(normalized_craft_id)
	if craft_def.is_empty() or _get_aircraft_location(normalized_craft_id) != "homebase":
		return false
	if bool(craft_def.get("air_asset_unavailable", false)):
		return false
	if not _get_assigned_pilot_id(craft_id).is_empty():
		return false
	if _has_active_pilot_transfer_for_craft(craft_id):
		return false
	if _has_active_cargo_load_for_craft(craft_id):
		return false
	if not _get_loaded_cargo_id(craft_id).is_empty():
		return false
	return true


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
	return String(_assigned_pilot_by_craft.get(craft_id, "")).strip_edges()


func _get_selected_cargo_id(craft_id: String) -> String:
	return String(_selected_cargo_by_craft.get(craft_id, "")).strip_edges()


func _get_loaded_cargo_id(craft_id: String) -> String:
	return String(_loaded_cargo_by_craft.get(craft_id, "")).strip_edges()


func _build_craft_display_name(craft_id: String) -> String:
	for entry_variant in _aircraft_definitions:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() != craft_id:
			continue
		return String(entry.get("display_name", craft_id)).strip_edges()
	return craft_id


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
	return bool(craft_def.get("supports_cargo", false))


func _get_cargo_options_for_craft(craft_def: Dictionary) -> Array:
	return Array(craft_def.get("cargo_options", []))


func _build_cargo_display_name(craft_def: Dictionary, cargo_id: String) -> String:
	var normalized_cargo_id: String = cargo_id.strip_edges()
	if normalized_cargo_id.is_empty():
		return ""
	for cargo_option_variant in _get_cargo_options_for_craft(craft_def):
		var cargo_option: Dictionary = Dictionary(cargo_option_variant)
		if String(cargo_option.get("cargo_id", "")).strip_edges() != normalized_cargo_id:
			continue
		return String(cargo_option.get("display_name", normalized_cargo_id)).strip_edges()
	return normalized_cargo_id.capitalize()


func _is_unit_assigned_to_aircraft(unit_id: String) -> bool:
	for pilot_id_variant in _assigned_pilot_by_craft.values():
		if String(pilot_id_variant).strip_edges() == unit_id:
			return true
	return false


func _find_assigned_craft_for_unit(unit_id: String) -> String:
	for craft_id_variant in _assigned_pilot_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if String(_assigned_pilot_by_craft.get(craft_id, "")).strip_edges() == unit_id:
			return craft_id
	return ""


func _get_visible_homebase_aircraft_definitions() -> Array:
	var visible_definitions: Array = []
	for entry_variant in _aircraft_definitions:
		var entry: Dictionary = Dictionary(entry_variant)
		var craft_id: String = String(entry.get("craft_id", "")).strip_edges()
		if craft_id.is_empty() or not _is_craft_visible_in_homebase(craft_id):
			continue
		visible_definitions.append(entry)
	return visible_definitions


func _get_aircraft_location(craft_id: String) -> String:
	return String(_aircraft_location_by_craft.get(craft_id, "homebase")).strip_edges().to_lower()


func _is_craft_visible_in_homebase(craft_id: String) -> bool:
	var craft_location: String = _get_aircraft_location(craft_id)
	if craft_location == "homebase":
		return true
	if craft_location == "transit" and _has_active_pilot_transfer_for_craft(craft_id):
		return true
	return false


func _is_craft_in_transit(craft_id: String) -> bool:
	return _get_aircraft_location(craft_id) == "transit" or _has_active_pilot_transfer_for_craft(craft_id)


func _has_active_pilot_transfer_for_craft(craft_id: String) -> bool:
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return true
	return false


func _has_active_cargo_load_for_craft(craft_id: String) -> bool:
	for entry_variant in _cargo_load_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return true
	return false


func _get_visible_cargo_load_entries(craft_id: String) -> Array:
	var entries: Array = []
	for entry_variant in _cargo_load_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() != craft_id:
			continue
		entries.append(entry)
	return entries


func _find_cargo_load_entry_for_craft(craft_id: String) -> Dictionary:
	for entry_variant in _cargo_load_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry
	return {}


func _can_load_selected_cargo(craft_def: Dictionary, craft_id: String) -> bool:
	if craft_def.is_empty() or not _craft_supports_cargo(craft_def):
		return false
	if bool(craft_def.get("air_asset_unavailable", false)):
		return false
	if _has_active_cargo_load_for_craft(craft_id) or _has_active_pilot_transfer_for_craft(craft_id):
		return false
	if not _get_loaded_cargo_id(craft_id).is_empty():
		return false
	return not _get_selected_cargo_id(craft_id).is_empty()


func _can_send_craft(craft_def: Dictionary, craft_id: String) -> bool:
	if bool(craft_def.get("air_asset_unavailable", false)):
		return false
	if _has_active_pilot_transfer_for_craft(craft_id) or _has_active_cargo_load_for_craft(craft_id):
		return false
	if _craft_supports_cargo(craft_def):
		var selected_cargo_id: String = _get_selected_cargo_id(craft_id)
		var loaded_cargo_id: String = _get_loaded_cargo_id(craft_id)
		if not selected_cargo_id.is_empty() and loaded_cargo_id.is_empty():
			return false
	return true


func _find_transfer_entry_for_unit(unit_id: String) -> Dictionary:
	for entry_variant in _team_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_ids: Array = Array(entry.get("unit_ids", []))
		for entry_unit_id_variant in unit_ids:
			if String(entry_unit_id_variant).strip_edges() == unit_id:
				return entry
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("pilot_unit_id", "")).strip_edges() == unit_id:
			return entry
	return {}


func _find_transfer_entry_for_craft(craft_id: String) -> Dictionary:
	for entry_variant in _pilot_transfer_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("craft_id", "")).strip_edges() == craft_id:
			return entry
	return {}


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
