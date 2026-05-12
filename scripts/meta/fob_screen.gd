class_name FOBTestScreen
extends Control

const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const TRANSPORT_CRAFT_CARD_UI_SCRIPT: GDScript = preload("res://scripts/meta/transport_craft_card_ui.gd")
const FOB_FIRETEAM_CARD_SCRIPT: GDScript = preload("res://scripts/meta/fob_fireteam_card.gd")
const FOB_DROP_PANEL_SCRIPT: GDScript = preload("res://scripts/meta/fob_drop_panel.gd")
const FIRETEAM_COHESION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/fireteam_cohesion_resolver.gd")
const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const LOADOUT_MODIFIER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/command/loadout_modifier_resolver.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const HOVER_SCROLL_BEHAVIOR_SCRIPT: GDScript = preload("res://scripts/ui/hover_scroll_behavior.gd")
const DROPSHIP_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NE.png")
const DROPSHIP_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NW.png")
const DROPSHIP_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png")
const DROPSHIP_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SW.png")
const DROPSHIP_FOB_TEXTURE: Texture2D = DROPSHIP_TEXTURE_SE
const SMG_BLASTER_PREVIEW_TEXTURE: Texture2D = preload("res://Assets/used/npc/blaster_kit/previews/blaster-a.png")
const SMG_BLASTER_PREVIEW_PATH := "res://Assets/used/npc/blaster_kit/previews/blaster-a.png"
const MEDICTOOL_BLASTER_PREVIEW_TEXTURE: Texture2D = preload("res://Assets/used/npc/blaster_kit/previews/blaster-b.png")
const MEDICTOOL_BLASTER_PREVIEW_PATH := "res://Assets/used/npc/blaster_kit/previews/blaster-b.png"
const SNIPER_PREVIEW_TEXTURE: Texture2D = preload("res://Assets/used/npc/weapon_pack/previews/sniper.png")
const SNIPER_PREVIEW_PATH := "res://Assets/used/npc/weapon_pack/previews/sniper.png"
const ROCKET_LAUNCHER_PREVIEW_TEXTURE: Texture2D = preload("res://Assets/used/npc/weapon_pack/previews/rocketlauncherModern.png")
const ROCKET_LAUNCHER_PREVIEW_PATH := "res://Assets/used/npc/weapon_pack/previews/rocketlauncherModern.png"

signal mission_start_requested(selected_unit_ids, selected_fireteam_ids)
signal transport_craft_mission_stage_requested(craft_id)
signal transport_craft_pilot_assigned(craft_id, pilot_unit_id)
signal transport_craft_pilot_cleared(craft_id)

const DEFAULT_DROPSHIP_ETA_SECONDS := 18.0
const DEFAULT_BOARDING_SECONDS := 6.0
const DEFAULT_RESPAWN_ANCHOR_SECONDS := 6.0
const DROPSHIP_NPC_CAPACITY := 6
const DEFAULT_MEMBER_WEAPON := "smg"
const WEAPON_LOADOUT_OPTIONS: Array = [
	{"id": "smg", "label": "SMG"},
	{"id": "rifle", "label": "Rifle"},
	{"id": "sniper", "label": "Sniper"},
	{"id": "rocket_launcher", "label": "Rocket"},
	{"id": "medictool", "label": "Medictool"},
	{"id": "none", "label": "None"},
]
const DEFAULT_MISSION_NAME := "Operation: FOB Transfer"
const DEFAULT_MISSION_MAP := "test_mission_32x32_slots8"
const DEFAULT_MISSION_SLOT_COUNT := 8
const FOB_FIRETEAM_REFERENCE_CARD_WIDTH := 280.0
const FOB_TRANSPORT_CARD_WIDTH := 440.0
const FOB_TRANSPORT_SHIP_TEXTURE_WIDTH := 176.0
const FOB_TRANSPORT_SHIP_TEXTURE_HEIGHT := 104.0

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
var _respawn_anchor_fireteam_id: String = ""
var _respawn_anchor_seconds: float = 0.0
var _dropship_staged_fireteam_ids: PackedStringArray = []
var _dropship_state_by_craft: Dictionary = {}
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
var _unified_transit_entries: Array = []
var _pending_transport_remove: Dictionary = {}


func _ready() -> void:
	META_UI_SKIN_SCRIPT.apply_fob(self)
	_apply_drop_light_fixed_layout()
	HOVER_SCROLL_BEHAVIOR_SCRIPT.call("install", self)
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
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/ContentRow/FireteamPanel") as Control, "fob.fireteams")
	_apply_help_id(dropship_panel as Control, "fob.flightdeck")
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


func _apply_drop_light_fixed_layout() -> void:
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	custom_minimum_size = Vector2(float(target_viewport.x), float(target_viewport.y))
	set_meta("drop_light_fixed_fullhd_layout", true)
	set_meta("drop_light_screen", DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SCREEN_FOB"))

	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout")
	var base_spacing: int = int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING"))
	_apply_fixed_control_contract("Panel", layout.get("viewport"))
	_apply_fixed_control_contract("Panel/Margin/VBox/MissionPanel", layout.get("topbar"))
	_apply_fixed_control_contract("Panel/Margin/VBox/ContentRow/AvailablePanel", layout.get("unassigned_pool"))
	_apply_fixed_control_contract("Panel/Margin/VBox/ContentRow/FireteamPanel", layout.get("fireteams"))
	_apply_fixed_control_contract("Panel/Margin/VBox/ContentRow/StagingPanel", layout.get("loadout"))
	_apply_fixed_control_contract("Panel/Margin/VBox/ContentRow/DropshipPanel", layout.get("flightdeck"))
	_apply_fixed_control_contract("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipQueueScroll", layout.get("ship_slots"))

	var vbox := get_node_or_null("Panel/Margin/VBox") as VBoxContainer
	if vbox != null:
		vbox.add_theme_constant_override("separation", base_spacing)

	var content_row := get_node_or_null("Panel/Margin/VBox/ContentRow") as HBoxContainer
	if content_row != null:
		content_row.custom_minimum_size = Vector2(0.0, float((layout.get("fireteams") as Rect2i).size.y))
		content_row.add_theme_constant_override("separation", base_spacing * 2)

	var available_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/AvailablePanel") as Control
	if available_panel != null:
		var unassigned_pool_rect: Rect2i = layout.get("unassigned_pool")
		available_panel.visible = true
		available_panel.custom_minimum_size = Vector2(float(unassigned_pool_rect.size.x), float(unassigned_pool_rect.size.y))
		available_panel.size_flags_stretch_ratio = float(maxi(unassigned_pool_rect.size.x, 1))
		available_panel.set_meta("drop_light_unassigned_pool_window", true)

	var available_header_label := get_node_or_null("Panel/Margin/VBox/ContentRow/AvailablePanel/AvailableMargin/AvailableVBox/AvailableHeaderLabel") as Label
	if available_header_label != null:
		available_header_label.text = "#09 NPC POOL"

	var staging_header_label := get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/StagingHeaderLabel") as Label
	if staging_header_label != null:
		staging_header_label.visible = false

	_apply_drop_light_topbar_compaction()

	var loadout_panel := get_node_or_null("Panel/Margin/VBox/ContentRow/StagingPanel/StagingMargin/StagingVBox/LoadoutPanel") as Control
	if loadout_panel != null:
		var loadout_rect: Rect2i = layout.get("loadout")
		loadout_panel.custom_minimum_size = Vector2(float(loadout_rect.size.x - base_spacing * 4 - 4), 0.0)
		loadout_panel.set_meta("drop_light_rect", loadout_rect)

	var dropship_top_row := get_node_or_null("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow") as Control
	if dropship_top_row != null:
		dropship_top_row.visible = false
		dropship_top_row.custom_minimum_size = Vector2.ZERO
		dropship_top_row.set_meta("replaced_by_transport_card_19", true)

	var dropship_visual := get_node_or_null("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipTopRow/DropshipVisualVBox/DropshipSpriteRect") as TextureRect
	if dropship_visual != null:
		dropship_visual.custom_minimum_size = Vector2(280.0, 160.0)
		dropship_visual.set_meta("drop_light_uses_project_craft_asset", true)

	_apply_square_button_contract("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/StartBoardingButton")
	_apply_square_button_contract("Panel/Margin/VBox/ContentRow/DropshipPanel/DropshipMargin/DropshipVBox/DropshipHeaderRow/RemoveDropshipFireteamButton")
	_ensure_drop_light_bottom_row(layout)
	_enforce_drop_light_fixed_layout()
	call_deferred("_enforce_drop_light_fixed_layout")


func _enforce_drop_light_fixed_layout() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_fob_layout")
	_apply_fixed_window_contract("Panel", layout.get("viewport"))
	_apply_fixed_window_contract("Panel/Margin/VBox/MissionPanel", layout.get("topbar"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/AvailablePanel", layout.get("unassigned_pool"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/FireteamPanel", layout.get("fireteams"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/StagingPanel", layout.get("loadout"))
	_apply_fixed_window_contract("Panel/Margin/VBox/ContentRow/DropshipPanel", layout.get("flightdeck"))
	_apply_fixed_window_contract("Panel/Margin/VBox/DropLightBottomRow/BoardingStatusPanel", layout.get("boarding_status"))
	_apply_fixed_window_contract("Panel/Margin/VBox/DropLightBottomRow/ActionsPanel", layout.get("actions"))


func _apply_fixed_window_contract(path: String, rect_variant: Variant) -> void:
	if typeof(rect_variant) != TYPE_RECT2I:
		return
	var control := get_node_or_null(path) as Control
	if control == null:
		return
	var rect: Rect2i = rect_variant
	var fixed_position := Vector2(float(rect.position.x), float(rect.position.y))
	var fixed_size := Vector2(float(rect.size.x), float(rect.size.y))
	control.set_as_top_level(true)
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.position = fixed_position
	control.size = fixed_size
	control.custom_minimum_size = fixed_size
	control.set_deferred("position", fixed_position)
	control.set_deferred("size", fixed_size)
	control.set_meta("drop_light_rect", rect)
	control.set_meta("drop_light_fixed_fullhd_layout", true)


func _apply_drop_light_topbar_compaction() -> void:
	var mission_vbox := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox") as VBoxContainer
	if mission_vbox != null:
		mission_vbox.add_theme_constant_override("separation", 0)

	var mission_header_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionHeaderLabel") as Label
	if mission_header_label != null:
		mission_header_label.add_theme_font_size_override("font_size", 10)

	var mission_info_row := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow") as HBoxContainer
	if mission_info_row != null:
		mission_info_row.visible = false

	var mission_summary_label := get_node_or_null("Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionSummaryLabel") as Label
	if mission_summary_label != null:
		mission_summary_label.visible = false

	for path in [
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/TeamStatusLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/FireteamStatusLabel",
		"Panel/Margin/VBox/MissionPanel/MissionMargin/MissionVBox/MissionInfoRow/DropshipStatusLabel",
	]:
		var label := get_node_or_null(path) as Label
		if label != null:
			label.add_theme_font_size_override("font_size", 8)


func _apply_fixed_control_contract(path: String, rect_variant: Variant) -> void:
	if typeof(rect_variant) != TYPE_RECT2I:
		return
	var control := get_node_or_null(path) as Control
	if control == null:
		return
	var rect: Rect2i = rect_variant
	control.custom_minimum_size = Vector2(float(rect.size.x), float(rect.size.y))
	control.size_flags_stretch_ratio = float(maxi(rect.size.x, 1))
	control.set_meta("drop_light_rect", rect)
	control.set_meta("drop_light_fixed_fullhd_layout", true)


func _apply_square_button_contract(path: String) -> void:
	var button := get_node_or_null(path) as Button
	if button == null:
		return
	var action_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	button.custom_minimum_size = Vector2(float(action_size.x), float(action_size.y))
	button.set_meta("drop_light_square_action_button", true)


func _ensure_drop_light_bottom_row(layout: Dictionary) -> void:
	var vbox := get_node_or_null("Panel/Margin/VBox") as VBoxContainer
	if vbox == null or vbox.get_node_or_null("DropLightBottomRow") != null:
		return
	var bottom_row := HBoxContainer.new()
	bottom_row.name = "DropLightBottomRow"
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.add_theme_constant_override("separation", int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING")) * 2)
	bottom_row.custom_minimum_size = Vector2(0.0, float((layout.get("boarding_status") as Rect2i).size.y))
	bottom_row.set_meta("drop_light_fixed_fullhd_layout", true)
	vbox.add_child(bottom_row)

	var boarding_panel := _create_drop_light_bottom_panel("BoardingStatusPanel", "BOARDING STATUS", layout.get("boarding_status"))
	bottom_row.add_child(boarding_panel)

	var actions_panel := _create_drop_light_bottom_panel("ActionsPanel", "ACTIONS", layout.get("actions"))
	var actions_grid := GridContainer.new()
	actions_grid.name = "ActionGrid"
	actions_grid.columns = 6
	actions_grid.add_theme_constant_override("h_separation", int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING")))
	actions_grid.add_theme_constant_override("v_separation", int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING")))
	var actions_vbox := actions_panel.get_node("Margin/VBox") as VBoxContainer
	actions_vbox.add_child(actions_grid)
	for button_data in [
		["BoardButton", "Board"],
		["UnboardButton", "Unboard"],
		["SendButton", "Send"],
		["HoldButton", "Hold"],
		["CargoButton", "Cargo"],
		["MedbayLaterButton", "Medbay"],
	]:
		var action_button := Button.new()
		action_button.name = String(button_data[0])
		action_button.text = String(button_data[1])
		action_button.add_theme_font_size_override("font_size", 8)
		_style_drop_light_action_button(action_button)
		actions_grid.add_child(action_button)
	bottom_row.add_child(actions_panel)

	var board_button := actions_grid.get_node("BoardButton") as Button
	if not board_button.pressed.is_connected(_on_drop_light_board_action_pressed):
		board_button.pressed.connect(_on_drop_light_board_action_pressed)
	var send_button := actions_grid.get_node("SendButton") as Button
	if not send_button.pressed.is_connected(_on_drop_light_send_action_pressed):
		send_button.pressed.connect(_on_drop_light_send_action_pressed)


func _create_drop_light_bottom_panel(panel_name: String, title_text: String, rect_variant: Variant) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if typeof(rect_variant) == TYPE_RECT2I:
		var rect: Rect2i = rect_variant
		panel.custom_minimum_size = Vector2(float(rect.size.x), float(rect.size.y))
		panel.size_flags_stretch_ratio = float(maxi(rect.size.x, 1))
		panel.set_meta("drop_light_rect", rect)
	panel.set_meta("drop_light_fixed_fullhd_layout", true)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	var margin_size: int = int(DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("BASE_SPACING"))
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", margin_size)
	margin.add_child(vbox)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title_text
	title_label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(title_label, 11)
	vbox.add_child(title_label)

	var body_label := Label.new()
	body_label.name = "BodyLabel"
	body_label.text = ""
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 10)
	META_UI_SKIN_SCRIPT.style_body_label(body_label, 10)
	vbox.add_child(body_label)
	return panel


func _style_drop_light_action_button(button: Button) -> void:
	var action_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	button.custom_minimum_size = Vector2(float(action_size.x), float(action_size.y))
	button.set_meta("drop_light_square_action_button", true)
	META_UI_SKIN_SCRIPT.style_secondary_button(button)


func _on_drop_light_board_action_pressed() -> void:
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()
	if _can_start_boarding_for_craft(selected_craft_state):
		_on_transport_craft_boarding_requested(String(selected_craft_state.get("craft_id", "")).strip_edges())


func _on_drop_light_send_action_pressed() -> void:
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()
	if _can_mark_transport_craft_launch_ready(selected_craft_state):
		_on_transport_craft_mission_stage_requested(String(selected_craft_state.get("craft_id", "")).strip_edges())


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


func get_selected_unit_configs() -> Array:
	var configs: Array = []
	for config_variant in _build_selected_unit_configs():
		if typeof(config_variant) != TYPE_DICTIONARY:
			continue
		configs.append(Dictionary(config_variant).duplicate(true))
	return configs


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
	_save_current_dropship_state()
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
	if normalized_craft_id == _dropship_transport_craft_id:
		_save_current_dropship_state()
	_mission_launch_ready_craft_id = normalized_craft_id
	if is_inside_tree():
		_refresh_ui_state()


func clear_mission_boarded_payload(craft_id: String = "") -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		_boarded_unit_ids = PackedStringArray()
		_boarded_fireteam_ids = PackedStringArray()
		_dropship_staged_fireteam_ids = PackedStringArray()
		_dropship_state_by_craft.clear()
		_current_boarding_unit_id = ""
		_current_boarding_fireteam_id = ""
		_dropship_phase = "idle"
		if is_inside_tree():
			_refresh_ui_state()
		return
	var cleared_state: Dictionary = _build_empty_dropship_craft_state()
	if normalized_craft_id == _dropship_transport_craft_id:
		_apply_dropship_craft_state(cleared_state)
		_save_current_dropship_state()
	else:
		_dropship_state_by_craft[normalized_craft_id] = cleared_state
	if normalized_craft_id == _mission_launch_ready_craft_id:
		_mission_launch_ready_craft_id = ""
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


func _has_boarded_mission_payload(craft_id: String = "") -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_craft_id == _dropship_transport_craft_id:
		return not _boarded_unit_ids.is_empty()
	return not _get_boarded_unit_ids_for_craft(normalized_craft_id).is_empty()


func build_mission_drop_state() -> Dictionary:
	_save_current_dropship_state()
	var mission_craft_state: Dictionary = _get_transport_craft_state(_mission_launch_ready_craft_id)
	if mission_craft_state.is_empty():
		mission_craft_state = _get_meta_mission_craft_state()
	var payload_craft_id: String = _mission_launch_ready_craft_id.strip_edges()
	if payload_craft_id.is_empty():
		payload_craft_id = _dropship_transport_craft_id.strip_edges()
	var payload_state: Dictionary = _get_dropship_state_for_craft(payload_craft_id)
	var queued_fireteam_ids: PackedStringArray = _copy_packed_string_array(payload_state.get("staged_fireteam_ids", PackedStringArray()))
	var boarded_fireteam_ids: PackedStringArray = _copy_packed_string_array(payload_state.get("boarded_fireteam_ids", PackedStringArray()))
	var boarded_unit_ids: PackedStringArray = _copy_packed_string_array(payload_state.get("boarded_unit_ids", PackedStringArray()))
	if (not payload_craft_id.is_empty() and payload_craft_id == _dropship_transport_craft_id) or (payload_craft_id.is_empty() and not _boarded_unit_ids.is_empty()):
		queued_fireteam_ids = _dropship_staged_fireteam_ids.duplicate()
		boarded_fireteam_ids = _boarded_fireteam_ids.duplicate()
		boarded_unit_ids = _boarded_unit_ids.duplicate()
	var payload_phase: String = String(payload_state.get("phase", _dropship_phase)).strip_edges()
	var mission_drop_state: String = "waiting" if bool(mission_craft_state.get("mission_waiting", false)) else ("to_mission" if bool(mission_craft_state.get("mission_transit_to_map", false)) else ("to_fob" if bool(mission_craft_state.get("mission_transit_to_fob", false)) else ""))
	return {
		"transport_craft_id": payload_craft_id,
		"dropship_phase": payload_phase,
		"queued_fireteam_ids": Array(queued_fireteam_ids),
		"boarded_fireteam_ids": Array(boarded_fireteam_ids),
		"embarked_unit_ids": Array(boarded_unit_ids),
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
		"mission_drop_passenger_count": boarded_unit_ids.size(),
		"mission_drop_cards": _build_mission_drop_cards(),
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
		var cohesion_snapshot: Dictionary = _build_fireteam_cohesion_snapshot(fireteam_id, definition)
		fireteams.append(
			{
				"id": fireteam_id,
				"label": String(definition.get("label", fireteam_id.to_upper())),
				"lead_name": _build_display_name(String(definition.get("lead_unit_id", ""))),
				"member_names": _build_fireteam_member_names(fireteam_id),
				"respawn_enabled": bool(definition.get("respawn_enabled", false)),
				"loadout": String(definition.get("loadout", "medium")),
				"cohesion": float(cohesion_snapshot.get("cohesion", 0.0)),
				"teamfit_summary_text": String(cohesion_snapshot.get("summary_text", "")),
				"gameplay_modifiers": Dictionary(cohesion_snapshot.get("gameplay_modifiers", {})).duplicate(true),
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


func get_flightdeck_snapshot() -> Dictionary:
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()
	return {
		"selected_craft_id": String(selected_craft_state.get("craft_id", "")).strip_edges(),
		"visible_transport_craft_states": _get_visible_transport_craft_states(),
		"dropship_state_by_craft": _build_dropship_state_by_craft_snapshot(),
		"dropship_status": _build_dropship_status_text(selected_craft_state),
		"dropship_eta": _build_dropship_eta_text(selected_craft_state),
		"can_board": _can_start_boarding_for_craft(selected_craft_state),
		"can_send": _can_mark_transport_craft_launch_ready(selected_craft_state),
		"can_start_mission": can_request_mission_start(),
	}


func set_unified_transit_entries_for_test(entries: Array) -> void:
	_unified_transit_entries = Array(Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_snapshot", entries)).get("entries", [])).duplicate(true)
	if is_inside_tree():
		_rebuild_profiles()
		_refresh_ui_state()


func get_unified_transit_snapshot() -> Dictionary:
	return META_USEROLOGY_CONTRACT_SCRIPT.call("build_transit_snapshot", _unified_transit_entries)


func complete_unified_transit_for_test(entity_id: String) -> Dictionary:
	var result: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("complete_transit", _unified_transit_entries, entity_id))
	_unified_transit_entries = Array(result.get("remaining", [])).duplicate(true)
	return result


func get_unassigned_operator_pool_snapshot() -> Dictionary:
	return META_USEROLOGY_CONTRACT_SCRIPT.call(
		"build_unassigned_pool",
		_build_selected_unit_configs(),
		_build_assignment_lookup(),
		{},
		{},
		_unified_transit_entries
	)


func get_fireteam_assignment_board_snapshot() -> Dictionary:
	return META_USEROLOGY_CONTRACT_SCRIPT.call(
		"build_fireteam_board",
		_fireteam_definitions,
		_build_selected_unit_configs(),
		_build_assignment_lookup()
	)


func get_compact_flightdeck_snapshot() -> Dictionary:
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()
	var selected_craft_id: String = String(selected_craft_state.get("craft_id", "")).strip_edges()
	var boarded_unit_ids: PackedStringArray = _get_boarded_unit_ids_for_craft(selected_craft_id)
	var passenger_units: Array = []
	for unit_id_variant in boarded_unit_ids:
		var profile = _profiles_by_id.get(String(unit_id_variant), null)
		if profile != null and profile.has_method("to_dict"):
			passenger_units.append(profile.call("to_dict"))
		else:
			passenger_units.append(_build_fallback_unit_config(String(unit_id_variant)))
	var card: Dictionary = Dictionary(META_USEROLOGY_CONTRACT_SCRIPT.call("build_compact_flightdeck_card", selected_craft_state, passenger_units))
	card["pilot_status_text"] = _build_transport_craft_pilot_text(selected_craft_state) if not selected_craft_state.is_empty() else "Pilot: none"
	card["boarding_uses_transport_contract"] = true
	return card


func get_fob_userology_snapshot() -> Dictionary:
	return {
		"flightdeck": get_flightdeck_snapshot(),
		"compact_flightdeck": get_compact_flightdeck_snapshot(),
		"unassigned_pool": get_unassigned_operator_pool_snapshot(),
		"fireteam_board": get_fireteam_assignment_board_snapshot(),
		"transit": get_unified_transit_snapshot(),
		"drag_badges": META_USEROLOGY_CONTRACT_SCRIPT.call("build_drag_badge_contract"),
		"grey_text_contrast_policy": "important_labels_use_skin_body_or_badge",
		"remove_action_policy": "small_x_with_confirmation",
	}


func rename_transport_craft_for_test(craft_id: String, next_display_name: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	var safe_name: String = next_display_name.strip_edges()
	if safe_name.is_empty():
		safe_name = "Dropship"
	for index in range(_transport_craft_states.size()):
		if typeof(_transport_craft_states[index]) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = Dictionary(_transport_craft_states[index]).duplicate(true)
		if String(craft_state.get("craft_id", "")).strip_edges() != normalized_craft_id:
			continue
		craft_state["display_name"] = safe_name
		craft_state["rename_persisted_in_meta_state"] = true
		_transport_craft_states[index] = craft_state
		if is_inside_tree():
			_refresh_ui_state()
		return {"ok": true, "craft_id": normalized_craft_id, "display_name": safe_name}
	return {"ok": false, "craft_id": normalized_craft_id, "display_name": ""}


func assign_unit_to_fireteam_for_test(unit_id: String, fireteam_id: String) -> void:
	_set_selected_fireteam_for_unit(unit_id, fireteam_id)


func remove_unit_to_unassigned_for_test(unit_id: String) -> void:
	_set_selected_fireteam_for_unit(unit_id, "")


func request_transport_remove_confirm_for_test(unit_id: String, craft_id: String = "") -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		normalized_craft_id = _dropship_transport_craft_id
	_pending_transport_remove = {
		"unit_id": normalized_unit_id,
		"craft_id": normalized_craft_id,
		"requires_confirmation": true,
		"target_after_remove": "fob_unassigned",
	}
	return _pending_transport_remove.duplicate(true)


func confirm_transport_remove_for_test() -> Dictionary:
	var pending: Dictionary = _pending_transport_remove.duplicate(true)
	var unit_id: String = String(pending.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return {"ok": false, "reason": "no_pending_remove"}
	var craft_id: String = String(pending.get("craft_id", "")).strip_edges()
	if not craft_id.is_empty():
		_set_selected_transport_craft_state(craft_id)
	if _boarded_unit_ids.has(unit_id):
		_boarded_unit_ids.remove_at(_boarded_unit_ids.find(unit_id))
		_save_current_dropship_state()
	_set_selected_fireteam_for_unit(unit_id, "")
	_pending_transport_remove.clear()
	return {"ok": true, "unit_id": unit_id, "target_after_remove": "fob_unassigned"}


func _build_assignment_lookup() -> Dictionary:
	return _build_validated_assignment_lookup()


func _build_valid_fireteam_id_set() -> Dictionary:
	var valid_ids: Dictionary = {}
	for definition_variant in _fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var fireteam_id: String = _normalize_fireteam_id(String((definition_variant as Dictionary).get("id", "")))
		if fireteam_id.is_empty():
			continue
		valid_ids[fireteam_id] = true
	return valid_ids


func _build_validated_assignment_lookup() -> Dictionary:
	var assignments: Dictionary = {}
	var valid_fireteam_ids: Dictionary = _build_valid_fireteam_id_set()
	for index in range(_selected_unit_ids.size()):
		var unit_id: String = String(_selected_unit_ids[index]).strip_edges()
		if unit_id.is_empty():
			continue
		var fireteam_id: String = ""
		if index < _selected_fireteam_ids.size():
			fireteam_id = _normalize_fireteam_id(String(_selected_fireteam_ids[index]))
		if not fireteam_id.is_empty() and not valid_fireteam_ids.has(fireteam_id):
			fireteam_id = ""
		assignments[unit_id] = fireteam_id
	return assignments


func _get_meta_mission_craft_state() -> Dictionary:
	var craft_states: Array = _get_meta_mission_craft_states()
	if craft_states.is_empty():
		return {}
	return Dictionary(craft_states[0]).duplicate(true)


func _get_meta_mission_craft_states() -> Array:
	var craft_states: Array = []
	for craft_state_variant in _transport_craft_states:
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = Dictionary(craft_state_variant)
		if not bool(craft_state.get("mission_waiting", false)) and not bool(craft_state.get("mission_transit_to_map", false)) and not bool(craft_state.get("mission_transit_to_fob", false)):
			continue
		craft_states.append(_build_meta_mission_craft_state(craft_state))
	return craft_states


func _build_meta_mission_craft_state(craft_state: Dictionary) -> Dictionary:
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	var dropship_state: Dictionary = _get_dropship_state_for_craft(craft_id)
	var boarded_unit_ids: PackedStringArray = _copy_packed_string_array(dropship_state.get("boarded_unit_ids", PackedStringArray()))
	var boarded_fireteam_ids: PackedStringArray = _copy_packed_string_array(dropship_state.get("boarded_fireteam_ids", PackedStringArray()))
	var queued_fireteam_ids: PackedStringArray = _copy_packed_string_array(dropship_state.get("staged_fireteam_ids", PackedStringArray()))
	return {
		"craft_id": craft_id,
		"display_name": String(craft_state.get("display_name", "Dropship")).strip_edges(),
		"texture_path": String(craft_state.get("texture_path", "")).strip_edges(),
		"pilot_unit_id": String(craft_state.get("pilot_unit_id", "")).strip_edges(),
		"pilot_display_name": String(craft_state.get("pilot_display_name", "")).strip_edges(),
		"pilot_portrait_path": String(craft_state.get("pilot_portrait_path", "")).strip_edges(),
		"passenger_count": boarded_unit_ids.size(),
		"embarked_unit_ids": Array(boarded_unit_ids),
		"boarded_fireteam_ids": Array(boarded_fireteam_ids),
		"queued_fireteam_ids": Array(queued_fireteam_ids),
		"transfer_progress": float(craft_state.get("transfer_progress", 0.0)),
		"transfer_eta_seconds": int(craft_state.get("transfer_eta_seconds", 0)),
		"mission_waiting": bool(craft_state.get("mission_waiting", false)),
		"mission_transit_to_map": bool(craft_state.get("mission_transit_to_map", false)),
		"mission_transit_to_fob": bool(craft_state.get("mission_transit_to_fob", false)),
	}


func _build_mission_drop_cards() -> Array:
	var cards: Array = []
	for craft_state_variant in _get_meta_mission_craft_states():
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = Dictionary(craft_state_variant)
		var mission_drop_state: String = "waiting" if bool(craft_state.get("mission_waiting", false)) else ("to_mission" if bool(craft_state.get("mission_transit_to_map", false)) else ("to_fob" if bool(craft_state.get("mission_transit_to_fob", false)) else ""))
		cards.append(
			{
				"craft_id": String(craft_state.get("craft_id", "")).strip_edges(),
				"display_name": String(craft_state.get("display_name", "Dropship")).strip_edges(),
				"title_text": UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title(_build_transport_craft_title(craft_state)),
				"texture_path": String(craft_state.get("texture_path", "")).strip_edges(),
				"state": mission_drop_state,
				"pilot_text": _build_transport_craft_pilot_text(craft_state),
				"status_line": _build_transport_craft_status_line(craft_state),
				"progress": float(craft_state.get("transfer_progress", 0.0)),
				"eta_seconds": int(craft_state.get("transfer_eta_seconds", 0)),
				"pilot_unit_id": String(craft_state.get("pilot_unit_id", "")).strip_edges(),
				"pilot_display_name": String(craft_state.get("pilot_display_name", "")).strip_edges(),
				"pilot_portrait_path": String(craft_state.get("pilot_portrait_path", "")).strip_edges(),
				"passenger_count": int(craft_state.get("passenger_count", 0)),
				"embarked_unit_ids": Array(craft_state.get("embarked_unit_ids", [])),
				"boarded_fireteam_ids": Array(craft_state.get("boarded_fireteam_ids", [])),
				"queued_fireteam_ids": Array(craft_state.get("queued_fireteam_ids", [])),
			}
		)
	return cards


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
	_update_drop_light_bottom_row()
	_update_character_overlay()
	_update_character_overlay_visibility()
	_enforce_drop_light_fixed_layout()


func _refresh_dropship_status_ui() -> void:
	_update_brief_panel()
	_update_staging_panel()
	_update_dropship_panel()
	_update_drop_light_bottom_row()


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
			"fireteam_list",
			_build_fireteam_card_teamfit_summary(fireteam_id, definition)
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
	_apply_help_id(clear_loadout_button, "loadout.clear_selection")
	_apply_help_id(loadout_status_label, "loadout.weight")
	_apply_help_id(loadout_help_label, "loadout.empty_team_default")
	_apply_help_id(loadout_fireteam_list, "fob.fireteams")
	_apply_help_id(loadout_member_list, "loadout.member_row")

	var loadout_fireteam_id: String = _normalize_fireteam_id(_loadout_staged_fireteam_id)
	var loadout_definition: Dictionary = _get_fireteam_definition(loadout_fireteam_id)
	var has_loadout_fireteam: bool = not loadout_definition.is_empty()
	var loadout_fireteam_label: String = _get_fireteam_label(loadout_fireteam_id)
	var lead_unit_id: String = String(loadout_definition.get("lead_unit_id", "")) if has_loadout_fireteam else ""
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(loadout_fireteam_id)

	var respawn_fireteam_id: String = _normalize_fireteam_id(_respawn_staged_fireteam_id)
	var respawn_definition: Dictionary = _get_fireteam_definition(respawn_fireteam_id)
	var respawn_enabled: bool = bool(respawn_definition.get("respawn_enabled", false)) if not respawn_definition.is_empty() else false
	var respawn_anchor_active: bool = _is_respawn_anchor_active(respawn_fireteam_id)
	var respawn_fireteam_label: String = _get_fireteam_label(respawn_fireteam_id)
	var respawn_lead_unit_id: String = String(respawn_definition.get("lead_unit_id", "")) if not respawn_definition.is_empty() else ""
	var respawn_member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(respawn_fireteam_id)

	if respawn_anchor_active:
		respawn_status_label.text = "Respawn anchor: locating %s | %.0fs" % [respawn_fireteam_label, _respawn_anchor_seconds]
	elif respawn_enabled:
		respawn_status_label.text = "Respawn anchor: FOB active for %s" % respawn_fireteam_label
	else:
		respawn_status_label.text = "Respawn anchor: not set"
	set_respawn_button.disabled = respawn_fireteam_id.is_empty() or respawn_enabled or respawn_anchor_active
	clear_respawn_button.disabled = respawn_fireteam_id.is_empty() or (not respawn_enabled and not respawn_anchor_active)

	loadout_status_label.visible = has_loadout_fireteam
	loadout_status_label.text = "Loadout: %s | Weight %.1f" % [String(loadout_definition.get("loadout", "medium")).strip_edges().to_upper(), _calculate_fireteam_loadout_weight(loadout_fireteam_id, member_ids)]
	loadout_help_label.text = ""
	loadout_help_label.visible = false
	clear_loadout_button.disabled = not has_loadout_fireteam

	_render_staging_fireteam_card(respawn_fireteam_list, respawn_fireteam_id, "", "respawn_staging", respawn_member_ids, respawn_lead_unit_id)
	_render_staging_fireteam_card(loadout_fireteam_list, loadout_fireteam_id, "", "loadout_staging")
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
	_apply_help_id(status_label, "fob.flightdeck")
	_apply_help_id(eta_label, "fob.flightdeck")
	_apply_help_id(queue_label, "fob.flightdeck")
	_apply_help_id(help_label, "fob.flightdeck")
	_apply_help_id(dropship_sprite_rect, "fob.flightdeck")
	_apply_help_id(dropship_arrival_progress, "fob.flightdeck")
	_apply_help_id(dropship_arrival_label, "fob.flightdeck")
	_apply_help_id(start_boarding_button, "fob.flightdeck")
	_apply_help_id(remove_dropship_fireteam_button, "fob.flightdeck")
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()

	status_label.text = _build_dropship_status_text(selected_craft_state)
	eta_label.text = _build_dropship_eta_text(selected_craft_state)
	queue_label.text = _build_boarding_queue_text()
	help_label.text = "Ziehen Sie Fireteam-Karten direkt auf eine FOB-Shipcard. In Transit sichtbare Schiffe bleiben hier ausgegraut, bis sie eintreffen."
	help_label.visible = false
	dropship_sprite_rect.texture = _build_dropship_visual_texture(selected_craft_state)
	dropship_arrival_progress.value = _build_dropship_arrival_progress_value(selected_craft_state)
	dropship_arrival_progress.visible = not selected_craft_state.is_empty() and bool(selected_craft_state.get("is_in_transit", false))
	dropship_arrival_label.text = _build_dropship_arrival_visual_text(selected_craft_state)
	start_boarding_button.visible = false
	start_boarding_button.disabled = true
	remove_dropship_fireteam_button.disabled = not _get_staged_fireteam_ids_for_craft(_dropship_transport_craft_id).has(_focused_fireteam_id)
	_render_dropship_fireteam_cards(queue_list)


func _update_drop_light_bottom_row() -> void:
	var bottom_row := get_node_or_null("Panel/Margin/VBox/DropLightBottomRow") as HBoxContainer
	if bottom_row == null:
		return
	var body_label := bottom_row.get_node_or_null("BoardingStatusPanel/Margin/VBox/BodyLabel") as Label
	var selected_craft_state: Dictionary = _get_selected_transport_craft_state()
	var selected_craft_name: String = String(selected_craft_state.get("display_name", "")).strip_edges()
	if selected_craft_name.is_empty():
		selected_craft_name = "no craft"
	if body_label != null:
		body_label.text = "Selected: %s\nQueue: %d fireteams\nInside dropship: %d NPC" % [
			selected_craft_name,
			_boarding_order.size(),
			_boarded_unit_ids.size(),
		]

	var action_grid := bottom_row.get_node_or_null("ActionsPanel/Margin/VBox/ActionGrid") as GridContainer
	if action_grid == null:
		return
	var board_button := action_grid.get_node_or_null("BoardButton") as Button
	var send_button := action_grid.get_node_or_null("SendButton") as Button
	var board_enabled := _can_start_boarding_for_craft(selected_craft_state)
	var send_enabled := _can_mark_transport_craft_launch_ready(selected_craft_state)
	for child in action_grid.get_children():
		var button := child as Button
		if button == null:
			continue
		_style_drop_light_action_button(button)
		button.disabled = true
	if board_button != null:
		board_button.disabled = not board_enabled
		META_UI_SKIN_SCRIPT.style_transfer_button(board_button, board_enabled)
	if send_button != null:
		send_button.disabled = not send_enabled
		META_UI_SKIN_SCRIPT.style_transfer_button(send_button, send_enabled)


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
		"editable_metrics": false,
		"two_column_layout": true,
		"show_badge_progress": true,
		"hide_loadout_dropdowns": true,
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
			return "Unzugewiesene FOB-Operators stehen direkt links neben #10. Grau markierte Karten sind noch im Anflug."
		return "Ziehe NPC-Karten von hier auf #10 FIRETEAMS oder zurueck in diesen Pool, um sie zu loesen."

	return "Focused operator: %s | Current fireteam: %s" % [_build_display_name(_focused_unit_id), _build_fireteam_display_text(_get_selected_fireteam_id_for_unit(_focused_unit_id))]


func _build_fireteam_panel_summary_text() -> String:
	if _selected_unit_ids.is_empty():
		return "No transferred operators in FOB."

	return "Focused fireteam: %s | Lead: %s | Assigned operators: %d / %d" % [_get_fireteam_label(_focused_fireteam_id), _build_display_name(_get_fireteam_lead_unit_id(_focused_fireteam_id)), _count_assigned_operators(), _selected_unit_ids.size()]


func _build_dropship_status_text(selected_craft_state: Dictionary = {}) -> String:
	if not selected_craft_state.is_empty():
		var craft_name: String = String(selected_craft_state.get("display_name", "craft")).strip_edges()
		var craft_id: String = String(selected_craft_state.get("craft_id", "")).strip_edges()
		if bool(selected_craft_state.get("air_asset_unavailable", false)):
			var meta_state: String = String(selected_craft_state.get("air_asset_meta_status", "")).strip_edges()
			return "%s: replacement pending" % craft_name if meta_state == "destroyed_replacement_pending" else "%s: repairing" % craft_name
		if bool(selected_craft_state.get("mission_waiting", false)):
			return "%s: waiting on mission map" % craft_name
		if bool(selected_craft_state.get("mission_transit_to_map", false)):
			return "%s: outbound to mission map" % craft_name
		if bool(selected_craft_state.get("mission_transit_to_fob", false)):
			return "%s: returning from mission map" % craft_name
		if bool(selected_craft_state.get("is_in_transit", false)):
			return "%s: inbound from Homebase" % craft_name
		if craft_id == _mission_launch_ready_craft_id and _has_boarded_mission_payload(craft_id):
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
		if bool(selected_craft_state.get("air_asset_unavailable", false)):
			return "Recovery ETA: %ds" % int(selected_craft_state.get("air_asset_recovery_eta_seconds", 0))
		if bool(selected_craft_state.get("mission_waiting", false)):
			return "Mission ETA: on-station | awaiting Drop"
		if bool(selected_craft_state.get("mission_transit_to_map", false)) or bool(selected_craft_state.get("mission_transit_to_fob", false)):
			return "Mission ETA: %ds" % int(selected_craft_state.get("transfer_eta_seconds", 0))
		if bool(selected_craft_state.get("is_in_transit", false)):
			return "Arrival ETA: %ds" % int(selected_craft_state.get("transfer_eta_seconds", 0))
		if _dropship_transport_craft_id == String(selected_craft_state.get("craft_id", "")).strip_edges() and not _boarding_order.is_empty():
			match _dropship_phase:
				"ready":
					return "Arrival ETA: docked | auto boarding"
				"boarding":
					return "NPC boarding timer: %.0fs" % _boarding_seconds
				"boarded":
					return "Arrival ETA: docked"
		return "Arrival ETA: already docked"
	match _dropship_phase:
		"incoming":
			return "Arrival ETA: %.0fs" % _dropship_eta_seconds
		"ready":
			return "Arrival ETA: docked | auto boarding"
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


func _on_operator_card_pressed(unit_id: String, profile, _source_context: String) -> void:
	_remember_card_profile(unit_id, profile)
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


func _on_operator_card_open_requested(unit_id: String, profile, _source_context: String) -> void:
	_remember_card_profile(unit_id, profile)
	_focused_unit_id = unit_id
	_refresh_card_highlights()
	_open_character_overlay(unit_id)


func _remember_card_profile(unit_id: String, profile) -> void:
	var normalized_unit_id := unit_id.strip_edges()
	if normalized_unit_id.is_empty() or profile == null or _profiles_by_id.has(normalized_unit_id):
		return
	if typeof(profile) == TYPE_OBJECT and profile.has_method("duplicate_profile"):
		_profiles_by_id[normalized_unit_id] = profile.duplicate_profile()


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
	if _release_transport_craft_pilot_to_pool(unit_id):
		return
	_focused_unit_id = unit_id
	_set_selected_fireteam_for_unit(unit_id, "")


func _on_transport_craft_card_unit_dropped(unit_id: String, drop_kind: String) -> void:
	var target_craft_id: String = _transport_craft_id_from_drop_kind(drop_kind)
	if target_craft_id.is_empty():
		return
	_assign_transport_craft_pilot_from_pool(target_craft_id, unit_id)


func _on_transport_craft_pilot_card_unit_dropped(unit_id: String, _source_context: String, craft_id: String) -> void:
	_assign_transport_craft_pilot_from_pool(craft_id, unit_id)


func _release_transport_craft_pilot_to_pool(unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return false
	var craft_state: Dictionary = _find_transport_craft_state_by_pilot(normalized_unit_id)
	if craft_state.is_empty() or not _can_edit_transport_craft_pilot(craft_state):
		return false
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return false
	_set_transport_craft_pilot_id(craft_id, "")
	_append_unit_to_fob_pool(normalized_unit_id)
	_focused_unit_id = normalized_unit_id
	transport_craft_pilot_cleared.emit(craft_id)
	_rebuild_profiles()
	_refresh_ui_state()
	return true


func _assign_transport_craft_pilot_from_pool(craft_id: String, unit_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_craft_id.is_empty() or normalized_unit_id.is_empty():
		return false
	var craft_state: Dictionary = _get_transport_craft_state(normalized_craft_id)
	if craft_state.is_empty() or not _can_edit_transport_craft_pilot(craft_state):
		return false
	var current_pilot_id: String = String(craft_state.get("pilot_unit_id", "")).strip_edges()
	if current_pilot_id == normalized_unit_id:
		return true
	var source_craft_state: Dictionary = _find_transport_craft_state_by_pilot(normalized_unit_id)
	var source_craft_id: String = String(source_craft_state.get("craft_id", "")).strip_edges()
	if not source_craft_id.is_empty() and source_craft_id != normalized_craft_id:
		if not _can_edit_transport_craft_pilot(source_craft_state):
			return false
		_set_transport_craft_pilot_id(source_craft_id, "")
	if not current_pilot_id.is_empty():
		_append_unit_to_fob_pool(current_pilot_id)
	_remove_unit_from_fob_pool(normalized_unit_id)
	_set_transport_craft_pilot_id(normalized_craft_id, normalized_unit_id)
	_focused_unit_id = normalized_unit_id
	transport_craft_pilot_assigned.emit(normalized_craft_id, normalized_unit_id)
	_rebuild_profiles()
	_refresh_ui_state()
	return true


func _transport_craft_id_from_drop_kind(drop_kind: String) -> String:
	var normalized_drop_kind: String = drop_kind.strip_edges()
	if not normalized_drop_kind.begins_with("dropship|"):
		return ""
	return normalized_drop_kind.trim_prefix("dropship|").strip_edges()


func _can_edit_transport_craft_pilot(craft_state: Dictionary) -> bool:
	if craft_state.is_empty():
		return false
	if bool(craft_state.get("air_asset_unavailable", false)):
		return false
	if bool(craft_state.get("is_in_transit", false)):
		return false
	if bool(craft_state.get("mission_waiting", false)) or bool(craft_state.get("mission_transit_to_map", false)) or bool(craft_state.get("mission_transit_to_fob", false)):
		return false
	return bool(craft_state.get("visible_in_fob", false)) and bool(craft_state.get("is_boardable", false))


func _set_transport_craft_pilot_id(craft_id: String, pilot_unit_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	var normalized_pilot_id: String = pilot_unit_id.strip_edges()
	for index in range(_transport_craft_states.size()):
		if typeof(_transport_craft_states[index]) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = Dictionary(_transport_craft_states[index]).duplicate(true)
		if String(craft_state.get("craft_id", "")).strip_edges() != normalized_craft_id:
			continue
		craft_state["pilot_unit_id"] = normalized_pilot_id
		craft_state["pilot_display_name"] = _build_display_name(normalized_pilot_id) if not normalized_pilot_id.is_empty() else ""
		craft_state["pilot_portrait_path"] = _build_unit_portrait_path(normalized_pilot_id)
		_transport_craft_states[index] = craft_state
		return


func _append_unit_to_fob_pool(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or _selected_unit_ids.has(normalized_unit_id):
		return
	_selected_unit_ids.append(normalized_unit_id)
	_selected_fireteam_ids.append("")


func _remove_unit_from_fob_pool(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var next_unit_ids: PackedStringArray = []
	var next_fireteam_ids: PackedStringArray = []
	for unit_index in range(_selected_unit_ids.size()):
		var current_unit_id: String = String(_selected_unit_ids[unit_index]).strip_edges()
		if current_unit_id.is_empty() or current_unit_id == normalized_unit_id:
			continue
		next_unit_ids.append(current_unit_id)
		next_fireteam_ids.append(String(_selected_fireteam_ids[unit_index]).strip_edges() if unit_index < _selected_fireteam_ids.size() else "")
	_selected_unit_ids = next_unit_ids
	_selected_fireteam_ids = next_fireteam_ids
	_sanitize_fireteam_state()
	_sanitize_staging_state()


func _build_unit_portrait_path(unit_id: String) -> String:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return ""
	var profile = _profiles_by_id.get(normalized_unit_id, null)
	if profile != null:
		return String(profile.portrait_path)
	var unit_data: Dictionary = _get_available_unit_data(normalized_unit_id)
	return String(unit_data.get("portrait_path", "")).strip_edges()


func _on_set_respawn_button_pressed() -> void:
	if _respawn_staged_fireteam_id.is_empty():
		return
	_start_respawn_anchor_progress(_respawn_staged_fireteam_id)


func _on_clear_respawn_button_pressed() -> void:
	if _respawn_staged_fireteam_id.is_empty():
		return
	_clear_respawn_anchor_progress(_respawn_staged_fireteam_id)
	_set_fireteam_respawn_enabled(_respawn_staged_fireteam_id, false)
	_respawn_staged_fireteam_id = ""
	_refresh_ui_state()


func _on_clear_loadout_button_pressed() -> void:
	if _loadout_staged_fireteam_id.is_empty():
		return
	_loadout_staged_fireteam_id = ""
	_refresh_ui_state()


func _on_remove_dropship_fireteam_button_pressed() -> void:
	if not _get_staged_fireteam_ids_for_craft(_dropship_transport_craft_id).has(_focused_fireteam_id):
		return
	if _remove_fireteam_from_dropship_queues(_focused_fireteam_id):
		if _dropship_staged_fireteam_ids.is_empty():
			_dropship_transport_craft_id = ""
		_restart_dropship_cycle()
		_refresh_ui_state()


func _on_start_boarding_button_pressed() -> void:
	_start_boarding_sequence()


func _start_boarding_sequence() -> bool:
	var selected_craft_state: Dictionary = _get_transport_craft_state(_dropship_transport_craft_id)
	if selected_craft_state.is_empty():
		if _dropship_phase != "ready" or _boarding_order.is_empty():
			return false
	elif not _can_start_boarding_for_craft(selected_craft_state):
		return false
	_boarding_index = 0
	_boarding_member_index = 0
	_current_boarding_unit_id = ""
	_boarded_unit_ids = PackedStringArray()
	_boarded_fireteam_ids = PackedStringArray()
	_start_next_boarding_step()
	_save_current_dropship_state()
	_refresh_dropship_status_ui()
	return true


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
		_start_respawn_anchor_progress(normalized_fireteam_id)
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
	_tick_respawn_anchor_progress()
	_save_current_dropship_state()
	var selected_craft_id: String = _dropship_transport_craft_id.strip_edges()
	var known_craft_ids: PackedStringArray = _get_known_dropship_craft_ids()
	if known_craft_ids.is_empty():
		_tick_selected_dropship_progress()
	for craft_id in known_craft_ids:
		var normalized_craft_id: String = String(craft_id).strip_edges()
		if normalized_craft_id.is_empty():
			continue
		var stored_state: Dictionary = _capture_current_dropship_state() if normalized_craft_id == selected_craft_id else _get_stored_dropship_state_for_craft(normalized_craft_id)
		if not _is_dropship_craft_phase_ticking(String(stored_state.get("phase", "idle"))):
			continue
		var next_state: Dictionary = _tick_dropship_craft_progress_state(stored_state)
		_dropship_state_by_craft[normalized_craft_id] = next_state
		if normalized_craft_id == selected_craft_id:
			_apply_dropship_craft_state(next_state)

	_update_dropship_timer_state()
	_refresh_dropship_status_ui()


func _tick_selected_dropship_progress() -> void:
	var next_state: Dictionary = _tick_dropship_craft_progress_state(_capture_current_dropship_state())
	_apply_dropship_craft_state(next_state)


func _tick_dropship_craft_progress_state(source_state: Dictionary) -> Dictionary:
	var next_state: Dictionary = _coerce_dropship_craft_state(source_state)
	match String(next_state.get("phase", "idle")).strip_edges():
		"incoming":
			var eta_seconds: float = maxf(float(next_state.get("eta_seconds", 0.0)) - 1.0, 0.0)
			next_state["eta_seconds"] = eta_seconds
			if eta_seconds <= 0.0:
				next_state["eta_seconds"] = 0.0
				next_state["phase"] = "ready"
		"boarding":
			var boarding_seconds: float = maxf(float(next_state.get("boarding_seconds", 0.0)) - 1.0, 0.0)
			next_state["boarding_seconds"] = boarding_seconds
			if boarding_seconds <= 0.0:
				next_state = _complete_current_boarding_member_in_state(next_state)
				next_state = _start_next_boarding_step_in_state(next_state)
		_:
			pass
	return next_state


func _complete_current_boarding_member_in_state(source_state: Dictionary) -> Dictionary:
	var next_state: Dictionary = _coerce_dropship_craft_state(source_state)
	var current_unit_id: String = String(next_state.get("current_boarding_unit_id", "")).strip_edges()
	if current_unit_id.is_empty():
		return next_state
	var boarded_unit_ids: PackedStringArray = _copy_packed_string_array(next_state.get("boarded_unit_ids", PackedStringArray()))
	if not boarded_unit_ids.has(current_unit_id):
		boarded_unit_ids.append(current_unit_id)
	next_state["boarded_unit_ids"] = boarded_unit_ids

	var current_fireteam_id: String = _get_boarding_fireteam_id_for_state(next_state)
	var boarded_fireteam_ids: PackedStringArray = _copy_packed_string_array(next_state.get("boarded_fireteam_ids", PackedStringArray()))
	if not current_fireteam_id.is_empty() and _is_fireteam_fully_boarded_in_state(current_fireteam_id, next_state) and not boarded_fireteam_ids.has(current_fireteam_id):
		boarded_fireteam_ids.append(current_fireteam_id)
	next_state["boarded_fireteam_ids"] = boarded_fireteam_ids
	next_state["boarding_member_index"] = int(next_state.get("boarding_member_index", 0)) + 1
	next_state["current_boarding_unit_id"] = ""
	return next_state


func _start_next_boarding_step_in_state(source_state: Dictionary) -> Dictionary:
	var next_state: Dictionary = _coerce_dropship_craft_state(source_state)
	var boarding_order: PackedStringArray = _copy_packed_string_array(next_state.get("boarding_order", PackedStringArray()))
	var boarding_index: int = int(next_state.get("boarding_index", 0))
	var boarding_member_index: int = int(next_state.get("boarding_member_index", 0))
	var boarded_unit_ids: PackedStringArray = _copy_packed_string_array(next_state.get("boarded_unit_ids", PackedStringArray()))
	var boarded_fireteam_ids: PackedStringArray = _copy_packed_string_array(next_state.get("boarded_fireteam_ids", PackedStringArray()))

	while boarding_index < boarding_order.size():
		var candidate_fireteam_id: String = String(boarding_order[boarding_index])
		var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(candidate_fireteam_id)
		if member_ids.is_empty():
			boarding_index += 1
			boarding_member_index = 0
			continue
		while boarding_member_index < member_ids.size():
			var candidate_unit_id: String = String(member_ids[boarding_member_index])
			if boarded_unit_ids.has(candidate_unit_id):
				boarding_member_index += 1
				continue
			next_state["boarding_index"] = boarding_index
			next_state["boarding_member_index"] = boarding_member_index
			next_state["current_boarding_unit_id"] = candidate_unit_id
			next_state["current_boarding_fireteam_id"] = candidate_fireteam_id
			next_state["phase"] = "boarding"
			next_state["boarding_seconds"] = DEFAULT_BOARDING_SECONDS
			return next_state
		next_state["boarding_index"] = boarding_index
		next_state["boarding_member_index"] = boarding_member_index
		if _is_fireteam_fully_boarded_in_state(candidate_fireteam_id, next_state) and not boarded_fireteam_ids.has(candidate_fireteam_id):
			boarded_fireteam_ids.append(candidate_fireteam_id)
			next_state["boarded_fireteam_ids"] = boarded_fireteam_ids
		boarding_index += 1
		boarding_member_index = 0

	next_state["phase"] = "boarded"
	next_state["boarding_seconds"] = 0.0
	next_state["boarding_index"] = boarding_index
	next_state["boarding_member_index"] = boarding_member_index
	next_state["current_boarding_unit_id"] = ""
	next_state["current_boarding_fireteam_id"] = ""
	return next_state


func _get_boarding_fireteam_id_for_state(state: Dictionary) -> String:
	if String(state.get("phase", "idle")).strip_edges() != "boarding":
		return ""
	var boarding_order: PackedStringArray = _copy_packed_string_array(state.get("boarding_order", PackedStringArray()))
	var boarding_index: int = int(state.get("boarding_index", 0))
	if boarding_index < 0 or boarding_index >= boarding_order.size():
		return String(state.get("current_boarding_fireteam_id", "")).strip_edges()
	return String(boarding_order[boarding_index])


func _is_fireteam_fully_boarded_in_state(fireteam_id: String, state: Dictionary) -> bool:
	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(fireteam_id)
	if member_ids.is_empty():
		return false
	var boarded_unit_ids: PackedStringArray = _copy_packed_string_array(state.get("boarded_unit_ids", PackedStringArray()))
	for member_unit_id in member_ids:
		if not boarded_unit_ids.has(String(member_unit_id)):
			return false
	return true


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
			_current_boarding_fireteam_id = candidate_fireteam_id
			_dropship_phase = "boarding"
			_boarding_seconds = DEFAULT_BOARDING_SECONDS
			if dropship_timer != null:
				dropship_timer.start()
			_save_current_dropship_state()
			return
		if _is_fireteam_fully_boarded(candidate_fireteam_id) and not _boarded_fireteam_ids.has(candidate_fireteam_id):
			_boarded_fireteam_ids.append(candidate_fireteam_id)
		_boarding_index += 1
		_boarding_member_index = 0

	_dropship_phase = "boarded"
	_boarding_seconds = 0.0
	_current_boarding_unit_id = ""
	_current_boarding_fireteam_id = ""
	_update_dropship_timer_state()
	_save_current_dropship_state()


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
			var previous_craft_id: String = _dropship_transport_craft_id
			if not previous_craft_id.is_empty():
				_dropship_state_by_craft.erase(previous_craft_id)
			_dropship_transport_craft_id = ""
		_update_dropship_timer_state()
		_save_current_dropship_state()
		if is_inside_tree():
			_refresh_dropship_status_ui()
		return

	var selected_craft_state: Dictionary = _get_transport_craft_state(_dropship_transport_craft_id)
	if not selected_craft_state.is_empty() and _can_stage_fireteam_into_craft(selected_craft_state):
		_dropship_phase = "ready"
		_dropship_eta_seconds = 0.0
		if _start_boarding_sequence():
			_save_current_dropship_state()
			return
		_update_dropship_timer_state()
		_save_current_dropship_state()
		if is_inside_tree():
			_refresh_dropship_status_ui()
		return

	_dropship_phase = "incoming"
	_dropship_eta_seconds = DEFAULT_DROPSHIP_ETA_SECONDS
	if dropship_timer != null:
		dropship_timer.start()
	_update_dropship_timer_state()
	_save_current_dropship_state()
	if is_inside_tree():
		_refresh_dropship_status_ui()


func _update_dropship_timer_state() -> void:
	var dropship_timer := get_node_or_null("DropshipTimer") as Timer
	if dropship_timer == null:
		return

	var timer_needed: bool = _is_respawn_anchor_active() or _has_active_dropship_craft_timer_state()
	if timer_needed:
		if dropship_timer.is_stopped():
			dropship_timer.start()
		return
	dropship_timer.stop()


func _start_respawn_anchor_progress(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	if not _set_fireteam_respawn_flag(normalized_fireteam_id, false):
		return

	_respawn_staged_fireteam_id = normalized_fireteam_id
	_respawn_anchor_fireteam_id = normalized_fireteam_id
	_respawn_anchor_seconds = DEFAULT_RESPAWN_ANCHOR_SECONDS
	_update_dropship_timer_state()
	_refresh_ui_state()


func _clear_respawn_anchor_progress(fireteam_id: String = "") -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty() or _respawn_anchor_fireteam_id == normalized_fireteam_id:
		_respawn_anchor_fireteam_id = ""
		_respawn_anchor_seconds = 0.0


func _tick_respawn_anchor_progress() -> void:
	if not _is_respawn_anchor_active():
		return

	_respawn_anchor_seconds = maxf(_respawn_anchor_seconds - 1.0, 0.0)
	if _respawn_anchor_seconds > 0.0:
		return

	var completed_fireteam_id: String = _respawn_anchor_fireteam_id
	_clear_respawn_anchor_progress(completed_fireteam_id)
	_set_fireteam_respawn_enabled(completed_fireteam_id, true)


func _is_respawn_anchor_active(fireteam_id: String = "") -> bool:
	if _respawn_anchor_fireteam_id.is_empty() or _respawn_anchor_seconds <= 0.0:
		return false
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	return normalized_fireteam_id.is_empty() or normalized_fireteam_id == _respawn_anchor_fireteam_id


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
	return _build_boarding_order_from_queue(_dropship_staged_fireteam_ids)


func _build_boarding_order_from_queue(staged_fireteam_ids: PackedStringArray) -> PackedStringArray:
	var order: PackedStringArray = []
	for fireteam_id_variant in staged_fireteam_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty():
			continue
		if _build_fireteam_member_names(fireteam_id).is_empty():
			continue
		order.append(fireteam_id)
	return order


func _copy_packed_string_array(value) -> PackedStringArray:
	var result: PackedStringArray = []
	if typeof(value) == TYPE_PACKED_STRING_ARRAY:
		var packed_entries: PackedStringArray = value
		for entry in packed_entries:
			var normalized_entry: String = String(entry).strip_edges()
			if not normalized_entry.is_empty():
				result.append(normalized_entry)
		return result
	if typeof(value) == TYPE_ARRAY:
		var array_entries: Array = value
		for entry in array_entries:
			var normalized_entry: String = String(entry).strip_edges()
			if not normalized_entry.is_empty():
				result.append(normalized_entry)
	return result


func _build_empty_dropship_craft_state() -> Dictionary:
	return {
		"staged_fireteam_ids": PackedStringArray(),
		"phase": "idle",
		"eta_seconds": 0.0,
		"boarding_seconds": 0.0,
		"boarding_order": PackedStringArray(),
		"boarding_index": 0,
		"boarding_member_index": 0,
		"current_boarding_unit_id": "",
		"current_boarding_fireteam_id": "",
		"boarded_unit_ids": PackedStringArray(),
		"boarded_fireteam_ids": PackedStringArray(),
	}


func _capture_current_dropship_state() -> Dictionary:
	return {
		"staged_fireteam_ids": _dropship_staged_fireteam_ids.duplicate(),
		"phase": _dropship_phase,
		"eta_seconds": _dropship_eta_seconds,
		"boarding_seconds": _boarding_seconds,
		"boarding_order": _boarding_order.duplicate(),
		"boarding_index": _boarding_index,
		"boarding_member_index": _boarding_member_index,
		"current_boarding_unit_id": _current_boarding_unit_id,
		"current_boarding_fireteam_id": _current_boarding_fireteam_id,
		"boarded_unit_ids": _boarded_unit_ids.duplicate(),
		"boarded_fireteam_ids": _boarded_fireteam_ids.duplicate(),
	}


func _coerce_dropship_craft_state(raw_state: Dictionary) -> Dictionary:
	var state: Dictionary = _build_empty_dropship_craft_state()
	state["staged_fireteam_ids"] = _copy_packed_string_array(raw_state.get("staged_fireteam_ids", PackedStringArray()))
	state["phase"] = String(raw_state.get("phase", "idle")).strip_edges()
	if String(state.get("phase", "")).is_empty():
		state["phase"] = "idle"
	state["eta_seconds"] = float(raw_state.get("eta_seconds", 0.0))
	state["boarding_seconds"] = float(raw_state.get("boarding_seconds", 0.0))
	state["boarding_order"] = _copy_packed_string_array(raw_state.get("boarding_order", PackedStringArray()))
	var boarding_order: PackedStringArray = _copy_packed_string_array(state.get("boarding_order", PackedStringArray()))
	var staged_fireteam_ids: PackedStringArray = _copy_packed_string_array(state.get("staged_fireteam_ids", PackedStringArray()))
	if boarding_order.is_empty() and not staged_fireteam_ids.is_empty():
		state["boarding_order"] = _build_boarding_order_from_queue(state["staged_fireteam_ids"])
	state["boarding_index"] = int(raw_state.get("boarding_index", 0))
	state["boarding_member_index"] = int(raw_state.get("boarding_member_index", 0))
	state["current_boarding_unit_id"] = String(raw_state.get("current_boarding_unit_id", "")).strip_edges()
	state["current_boarding_fireteam_id"] = String(raw_state.get("current_boarding_fireteam_id", "")).strip_edges()
	state["boarded_unit_ids"] = _copy_packed_string_array(raw_state.get("boarded_unit_ids", PackedStringArray()))
	state["boarded_fireteam_ids"] = _copy_packed_string_array(raw_state.get("boarded_fireteam_ids", PackedStringArray()))
	return state


func _apply_dropship_craft_state(state: Dictionary) -> void:
	var coerced_state: Dictionary = _coerce_dropship_craft_state(state)
	_dropship_staged_fireteam_ids = _copy_packed_string_array(coerced_state.get("staged_fireteam_ids", PackedStringArray()))
	_dropship_phase = String(coerced_state.get("phase", "idle")).strip_edges()
	if _dropship_phase.is_empty():
		_dropship_phase = "idle"
	_dropship_eta_seconds = float(coerced_state.get("eta_seconds", 0.0))
	_boarding_seconds = float(coerced_state.get("boarding_seconds", 0.0))
	_boarding_order = _copy_packed_string_array(coerced_state.get("boarding_order", PackedStringArray()))
	_boarding_index = int(coerced_state.get("boarding_index", 0))
	_boarding_member_index = int(coerced_state.get("boarding_member_index", 0))
	_current_boarding_unit_id = String(coerced_state.get("current_boarding_unit_id", "")).strip_edges()
	_current_boarding_fireteam_id = String(coerced_state.get("current_boarding_fireteam_id", "")).strip_edges()
	_boarded_unit_ids = _copy_packed_string_array(coerced_state.get("boarded_unit_ids", PackedStringArray()))
	_boarded_fireteam_ids = _copy_packed_string_array(coerced_state.get("boarded_fireteam_ids", PackedStringArray()))


func _save_current_dropship_state() -> void:
	var craft_id: String = _dropship_transport_craft_id.strip_edges()
	if craft_id.is_empty():
		return
	_dropship_state_by_craft[craft_id] = _capture_current_dropship_state()


func _set_selected_transport_craft_state(craft_id: String, save_previous: bool = true) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	if normalized_craft_id == _dropship_transport_craft_id:
		return
	if save_previous:
		_save_current_dropship_state()
	_dropship_transport_craft_id = normalized_craft_id
	var stored_variant = _dropship_state_by_craft.get(normalized_craft_id, _build_empty_dropship_craft_state())
	var stored_state: Dictionary = stored_variant if typeof(stored_variant) == TYPE_DICTIONARY else _build_empty_dropship_craft_state()
	_apply_dropship_craft_state(stored_state)


func _get_dropship_state_for_craft(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return _build_empty_dropship_craft_state()
	if normalized_craft_id == _dropship_transport_craft_id:
		return _capture_current_dropship_state()
	var stored_variant = _dropship_state_by_craft.get(normalized_craft_id, _build_empty_dropship_craft_state())
	var stored_state: Dictionary = stored_variant if typeof(stored_variant) == TYPE_DICTIONARY else _build_empty_dropship_craft_state()
	return _coerce_dropship_craft_state(stored_state)


func _get_stored_dropship_state_for_craft(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return _build_empty_dropship_craft_state()
	var stored_variant = _dropship_state_by_craft.get(normalized_craft_id, _build_empty_dropship_craft_state())
	var stored_state: Dictionary = stored_variant if typeof(stored_variant) == TYPE_DICTIONARY else _build_empty_dropship_craft_state()
	return _coerce_dropship_craft_state(stored_state)


func _get_known_dropship_craft_ids() -> PackedStringArray:
	var craft_ids: PackedStringArray = []
	for craft_id_variant in _dropship_state_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty() or craft_ids.has(craft_id):
			continue
		craft_ids.append(craft_id)
	for craft_state_variant in _get_visible_transport_craft_states():
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = Dictionary(craft_state_variant)
		var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
		if craft_id.is_empty() or craft_ids.has(craft_id):
			continue
		craft_ids.append(craft_id)
	if not _dropship_transport_craft_id.is_empty() and not craft_ids.has(_dropship_transport_craft_id):
		craft_ids.append(_dropship_transport_craft_id)
	return craft_ids


func _is_dropship_craft_phase_ticking(phase: String) -> bool:
	var normalized_phase: String = phase.strip_edges()
	return normalized_phase == "incoming" or normalized_phase == "boarding"


func _has_active_dropship_craft_timer_state() -> bool:
	if _is_dropship_craft_phase_ticking(_dropship_phase):
		return true
	for craft_id in _get_known_dropship_craft_ids():
		if String(craft_id) == _dropship_transport_craft_id:
			continue
		var state: Dictionary = _get_stored_dropship_state_for_craft(String(craft_id))
		if _is_dropship_craft_phase_ticking(String(state.get("phase", "idle"))):
			return true
	return false


func _get_staged_fireteam_ids_for_craft(craft_id: String) -> PackedStringArray:
	return _copy_packed_string_array(_get_dropship_state_for_craft(craft_id).get("staged_fireteam_ids", PackedStringArray()))


func _get_boarding_order_for_craft(craft_id: String) -> PackedStringArray:
	var state: Dictionary = _get_dropship_state_for_craft(craft_id)
	var order: PackedStringArray = _copy_packed_string_array(state.get("boarding_order", PackedStringArray()))
	if order.is_empty():
		order = _build_boarding_order_from_queue(_copy_packed_string_array(state.get("staged_fireteam_ids", PackedStringArray())))
	return order


func _get_boarded_unit_ids_for_craft(craft_id: String) -> PackedStringArray:
	return _copy_packed_string_array(_get_dropship_state_for_craft(craft_id).get("boarded_unit_ids", PackedStringArray()))


func _get_boarded_fireteam_ids_for_craft(craft_id: String) -> PackedStringArray:
	return _copy_packed_string_array(_get_dropship_state_for_craft(craft_id).get("boarded_fireteam_ids", PackedStringArray()))


func _append_unique_fireteam_ids(target: PackedStringArray, source: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = target.duplicate()
	for fireteam_id_variant in source:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	return result


func _get_visible_transport_craft_fireteam_ids(craft_id: String) -> PackedStringArray:
	var fireteam_ids: PackedStringArray = PackedStringArray()
	fireteam_ids = _append_unique_fireteam_ids(fireteam_ids, _get_boarding_order_for_craft(craft_id))
	fireteam_ids = _append_unique_fireteam_ids(fireteam_ids, _get_boarded_fireteam_ids_for_craft(craft_id))
	fireteam_ids = _append_unique_fireteam_ids(fireteam_ids, _get_staged_fireteam_ids_for_craft(craft_id))
	for unit_id_variant in _get_boarded_unit_ids_for_craft(craft_id):
		var unit_id: String = String(unit_id_variant).strip_edges()
		var fireteam_id: String = _get_selected_fireteam_id_for_unit(unit_id)
		if fireteam_id.is_empty() or fireteam_ids.has(fireteam_id):
			continue
		fireteam_ids.append(fireteam_id)
	return fireteam_ids


func _build_dropship_state_by_craft_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for craft_state_variant in _get_visible_transport_craft_states():
		if typeof(craft_state_variant) != TYPE_DICTIONARY:
			continue
		var craft_state: Dictionary = craft_state_variant
		var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			continue
		var state: Dictionary = _get_dropship_state_for_craft(craft_id)
		snapshot[craft_id] = {
			"staged_fireteam_ids": Array(_copy_packed_string_array(state.get("staged_fireteam_ids", PackedStringArray()))),
			"boarding_order": Array(_copy_packed_string_array(state.get("boarding_order", PackedStringArray()))),
			"boarded_unit_ids": Array(_copy_packed_string_array(state.get("boarded_unit_ids", PackedStringArray()))),
			"boarded_fireteam_ids": Array(_copy_packed_string_array(state.get("boarded_fireteam_ids", PackedStringArray()))),
			"phase": String(state.get("phase", "idle")).strip_edges(),
			"boarding_seconds": float(state.get("boarding_seconds", 0.0)),
			"eta_seconds": float(state.get("eta_seconds", 0.0)),
			"current_boarding_unit_id": String(state.get("current_boarding_unit_id", "")).strip_edges(),
			"current_boarding_fireteam_id": String(state.get("current_boarding_fireteam_id", "")).strip_edges(),
		}
	return snapshot


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
	_save_current_dropship_state()


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


func _set_fireteam_respawn_flag(fireteam_id: String, enabled: bool) -> bool:
	var definition_index: int = _find_fireteam_definition_index(fireteam_id)
	if definition_index < 0:
		return false

	var definition: Dictionary = _fireteam_definitions[definition_index]
	definition["respawn_enabled"] = enabled
	_fireteam_definitions[definition_index] = definition
	return true


func _set_fireteam_respawn_enabled(fireteam_id: String, enabled: bool) -> void:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return
	if not _set_fireteam_respawn_flag(normalized_fireteam_id, enabled):
		return
	if enabled:
		_clear_respawn_anchor_progress(normalized_fireteam_id)
		_respawn_staged_fireteam_id = normalized_fireteam_id
	elif _respawn_staged_fireteam_id == normalized_fireteam_id:
		_clear_respawn_anchor_progress(normalized_fireteam_id)
		_respawn_staged_fireteam_id = ""
	elif _respawn_anchor_fireteam_id == normalized_fireteam_id:
		_clear_respawn_anchor_progress(normalized_fireteam_id)
	_update_dropship_timer_state()
	_refresh_ui_state()


func _remove_fireteam_from_dropship_state(state: Dictionary, fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var next_state: Dictionary = _coerce_dropship_craft_state(state)
	if normalized_fireteam_id.is_empty():
		next_state["changed"] = false
		return next_state

	var changed := false
	var next_staged_fireteam_ids: PackedStringArray = []
	for queued_fireteam_id in _copy_packed_string_array(next_state.get("staged_fireteam_ids", PackedStringArray())):
		if String(queued_fireteam_id) == normalized_fireteam_id:
			changed = true
			continue
		next_staged_fireteam_ids.append(String(queued_fireteam_id))
	next_state["staged_fireteam_ids"] = next_staged_fireteam_ids
	next_state["boarding_order"] = _build_boarding_order_from_queue(next_staged_fireteam_ids)

	var next_boarded_fireteam_ids: PackedStringArray = []
	for boarded_fireteam_id in _copy_packed_string_array(next_state.get("boarded_fireteam_ids", PackedStringArray())):
		if String(boarded_fireteam_id) == normalized_fireteam_id:
			changed = true
			continue
		next_boarded_fireteam_ids.append(String(boarded_fireteam_id))
	next_state["boarded_fireteam_ids"] = next_boarded_fireteam_ids

	var member_ids: PackedStringArray = _get_member_unit_ids_for_fireteam(normalized_fireteam_id)
	var next_boarded_unit_ids: PackedStringArray = []
	for boarded_unit_id in _copy_packed_string_array(next_state.get("boarded_unit_ids", PackedStringArray())):
		if member_ids.has(String(boarded_unit_id)):
			changed = true
			continue
		next_boarded_unit_ids.append(String(boarded_unit_id))
	next_state["boarded_unit_ids"] = next_boarded_unit_ids

	if String(next_state.get("current_boarding_fireteam_id", "")).strip_edges() == normalized_fireteam_id:
		next_state["current_boarding_fireteam_id"] = ""
		next_state["current_boarding_unit_id"] = ""
		changed = true
	if next_staged_fireteam_ids.is_empty() and next_boarded_unit_ids.is_empty():
		next_state["phase"] = "idle"
		next_state["eta_seconds"] = 0.0
		next_state["boarding_seconds"] = 0.0
		next_state["boarding_index"] = 0
		next_state["boarding_member_index"] = 0
	next_state["changed"] = changed
	return next_state


func _remove_fireteam_from_dropship_queues(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return false

	var changed := false
	var selected_state: Dictionary = _remove_fireteam_from_dropship_state(_capture_current_dropship_state(), normalized_fireteam_id)
	if bool(selected_state.get("changed", false)):
		selected_state.erase("changed")
		_apply_dropship_craft_state(selected_state)
		changed = true

	for craft_id_variant in _dropship_state_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty() or craft_id == _dropship_transport_craft_id:
			continue
		var stored_variant = _dropship_state_by_craft.get(craft_id, {})
		if typeof(stored_variant) != TYPE_DICTIONARY:
			continue
		var next_state: Dictionary = _remove_fireteam_from_dropship_state(stored_variant, normalized_fireteam_id)
		if bool(next_state.get("changed", false)):
			next_state.erase("changed")
			_dropship_state_by_craft[craft_id] = next_state
			changed = true

	if changed:
		_save_current_dropship_state()
	return changed


func _is_fireteam_in_any_dropship_state(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return false
	if _dropship_staged_fireteam_ids.has(normalized_fireteam_id) or _boarded_fireteam_ids.has(normalized_fireteam_id):
		return true
	for craft_id_variant in _dropship_state_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty() or craft_id == _dropship_transport_craft_id:
			continue
		var state: Dictionary = _get_dropship_state_for_craft(craft_id)
		if _copy_packed_string_array(state.get("staged_fireteam_ids", PackedStringArray())).has(normalized_fireteam_id):
			return true
		if _copy_packed_string_array(state.get("boarded_fireteam_ids", PackedStringArray())).has(normalized_fireteam_id):
			return true
	return false


func _queue_fireteam_for_dropship(fireteam_id: String, craft_id: String = "") -> void:
	var target_craft_id: String = craft_id.strip_edges()
	if target_craft_id.is_empty():
		target_craft_id = _dropship_transport_craft_id
	if target_craft_id.is_empty():
		var fallback_craft_state: Dictionary = _get_selected_transport_craft_state()
		target_craft_id = String(fallback_craft_state.get("craft_id", "")).strip_edges()
	if not target_craft_id.is_empty():
		_set_selected_transport_craft_state(target_craft_id)

	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		_refresh_ui_state()
		return
	var target_craft_state: Dictionary = _get_transport_craft_state(target_craft_id)
	if not target_craft_state.is_empty() and not _can_stage_fireteam_into_craft(target_craft_state, normalized_fireteam_id):
		return
	_remove_fireteam_from_dropship_queues(normalized_fireteam_id)
	if not _dropship_staged_fireteam_ids.has(normalized_fireteam_id):
		_dropship_staged_fireteam_ids.append(normalized_fireteam_id)
	_restart_dropship_cycle()
	_save_current_dropship_state()
	_refresh_ui_state()


func _remove_fireteam_from_other_staging(fireteam_id: String, target_drop_kind: String) -> bool:
	var dropship_queue_changed: bool = false
	if target_drop_kind != "loadout" and _loadout_staged_fireteam_id == fireteam_id:
		_loadout_staged_fireteam_id = ""
	if target_drop_kind != "respawn" and _respawn_staged_fireteam_id == fireteam_id:
		_set_fireteam_respawn_enabled(fireteam_id, false)
		_respawn_staged_fireteam_id = ""
	if target_drop_kind != "dropship":
		dropship_queue_changed = _remove_fireteam_from_dropship_queues(fireteam_id)
	return dropship_queue_changed


func _is_fireteam_staged_in_window(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		return false
	if _loadout_staged_fireteam_id == normalized_fireteam_id:
		return true
	if _respawn_staged_fireteam_id == normalized_fireteam_id:
		return true
	return _is_fireteam_in_any_dropship_state(normalized_fireteam_id)


func _render_loadout_member_rows(
	container: VBoxContainer,
	fireteam_id: String,
	member_ids: PackedStringArray,
	lead_unit_id: String,
	has_focus_fireteam: bool
) -> void:
	_clear_container(container)
	if not has_focus_fireteam:
		return

	if member_ids.is_empty():
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
	row_panel.name = "LoadoutMemberRow_%s" % member_unit_id
	row_panel.custom_minimum_size = Vector2(0.0, 58.0)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	row_panel.set_meta("compact_loadout_member_row", true)
	row_panel.set_meta("unit_id", member_unit_id)
	row_panel.gui_input.connect(_on_loadout_member_row_gui_input.bind(member_unit_id))
	_apply_help_id(row_panel, "loadout.member_row")
	_apply_loadout_member_row_style(row_panel, member_unit_id == lead_unit_id)

	var row_margin := MarginContainer.new()
	row_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_margin.add_theme_constant_override("margin_left", 4)
	row_margin.add_theme_constant_override("margin_top", 4)
	row_margin.add_theme_constant_override("margin_right", 4)
	row_margin.add_theme_constant_override("margin_bottom", 4)
	row_panel.add_child(row_margin)

	var content_row := HBoxContainer.new()
	content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_row.alignment = BoxContainer.ALIGNMENT_CENTER
	content_row.add_theme_constant_override("separation", 6)
	row_margin.add_child(content_row)

	var member_card = NPC_COMPACT_CARD_SCENE.instantiate()
	member_card.name = "LoadoutMemberCard_%s" % member_unit_id
	member_card.custom_minimum_size = Vector2(132.0, 42.0)
	member_card.setup_from_profile(
		member_profile,
		{
			"source_context": "loadout_staging",
			"selected": _focused_unit_id == member_unit_id,
			"disabled": false,
			"drag_enabled": false,
			"compact_mode": true,
			"fixed_size": true,
			"fixed_card_size": Vector2(132.0, 42.0),
			"is_lead": member_unit_id == lead_unit_id,
			"show_lead_indicator": member_unit_id == lead_unit_id,
		}
	)
	member_card.mouse_filter = Control.MOUSE_FILTER_STOP
	if member_card.has_signal("card_pressed") and not member_card.card_pressed.is_connected(_on_operator_card_pressed):
		member_card.card_pressed.connect(_on_operator_card_pressed)
	if member_card.has_signal("card_open_requested") and not member_card.card_open_requested.is_connected(_on_operator_card_open_requested):
		member_card.card_open_requested.connect(_on_operator_card_open_requested)
	content_row.add_child(member_card)

	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(34.0, 34.0)
	portrait.visible = false
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = _load_portrait_texture(String(member_profile.portrait_path))
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_row.add_child(portrait)

	var identity_vbox := VBoxContainer.new()
	identity_vbox.name = "Identity"
	identity_vbox.custom_minimum_size = Vector2(108.0, 0.0)
	identity_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_vbox.add_theme_constant_override("separation", 1)
	content_row.add_child(identity_vbox)

	var name_row := HBoxContainer.new()
	name_row.name = "NameRow"
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 4)
	identity_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = _build_display_name(member_unit_id)
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(name_label)

	var badge_row := HBoxContainer.new()
	badge_row.name = "RankBadgeRow"
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.add_theme_constant_override("separation", 2)
	name_row.add_child(badge_row)
	_populate_compact_loadout_badge_row(badge_row, member_profile, member_unit_id == lead_unit_id)

	var member_loadout: Dictionary = _get_member_loadout(fireteam_id, member_unit_id)

	var status_label := Label.new()
	status_label.name = "LoadoutStatusLabel"
	status_label.text = _build_compact_member_loadout_status(member_unit_id, member_loadout)
	status_label.clip_text = true
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.add_theme_font_size_override("font_size", 8)
	status_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.83, 1.0))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_vbox.add_child(status_label)

	var selectors_row := HBoxContainer.new()
	selectors_row.name = "LoadoutDropdowns"
	selectors_row.custom_minimum_size = Vector2(152.0, 0.0)
	selectors_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	selectors_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selectors_row.add_theme_constant_override("separation", 3)
	content_row.add_child(selectors_row)

	var armor_select := _build_compact_loadout_select("ArmorSelect", 46.0, "loadout.armor")
	_apply_help_id(armor_select, "loadout.armor")
	_populate_compact_armor_option_button(armor_select, String(member_loadout.get("armor", "medium")))
	if not armor_select.item_selected.is_connected(_on_member_armor_selected.bind(fireteam_id, member_unit_id)):
		armor_select.item_selected.connect(_on_member_armor_selected.bind(fireteam_id, member_unit_id))
	selectors_row.add_child(armor_select)

	var weapon_1_id: String = String(member_loadout.get("weapon_1", member_loadout.get("weapon", DEFAULT_MEMBER_WEAPON)))
	var weapon_1_select := _build_compact_loadout_select("Weapon1Select", 50.0, "loadout.weapon_slot")
	_populate_compact_weapon_option_button(weapon_1_select, weapon_1_id)
	if not weapon_1_select.item_selected.is_connected(_on_member_weapon_1_selected.bind(fireteam_id, member_unit_id)):
		weapon_1_select.item_selected.connect(_on_member_weapon_1_selected.bind(fireteam_id, member_unit_id))
	selectors_row.add_child(weapon_1_select)
	selectors_row.add_child(_build_compact_weapon_preview("Weapon1Preview", weapon_1_id))

	var weapon_2_id: String = String(member_loadout.get("weapon_2", DEFAULT_MEMBER_WEAPON))
	var weapon_2_select := _build_compact_loadout_select("Weapon2Select", 50.0, "loadout.weapon_slot")
	_populate_compact_weapon_option_button(weapon_2_select, weapon_2_id)
	if not weapon_2_select.item_selected.is_connected(_on_member_weapon_2_selected.bind(fireteam_id, member_unit_id)):
		weapon_2_select.item_selected.connect(_on_member_weapon_2_selected.bind(fireteam_id, member_unit_id))
	selectors_row.add_child(weapon_2_select)
	selectors_row.add_child(_build_compact_weapon_preview("Weapon2Preview", weapon_2_id))

	return row_panel


func _build_compact_loadout_select(control_name: String, min_width: float, help_id: String) -> OptionButton:
	var option_button := OptionButton.new()
	option_button.name = control_name
	option_button.custom_minimum_size = Vector2(min_width, 24.0)
	option_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	option_button.add_theme_font_size_override("font_size", 8)
	option_button.mouse_filter = Control.MOUSE_FILTER_STOP
	option_button.set_meta("compact_loadout_dropdown", true)
	_apply_help_id(option_button, help_id)
	META_UI_SKIN_SCRIPT.style_secondary_button(option_button)
	return option_button


func _populate_compact_armor_option_button(option_button: OptionButton, selected_armor_id: String) -> void:
	option_button.clear()
	var armor_options: Array = [
		{"id": "light", "label": "L"},
		{"id": "medium", "label": "M"},
		{"id": "heavy", "label": "H"},
	]
	for option_variant in armor_options:
		var option: Dictionary = Dictionary(option_variant)
		var armor_id: String = String(option.get("id", "medium"))
		option_button.add_item(String(option.get("label", armor_id.capitalize())))
		option_button.set_item_metadata(option_button.item_count - 1, armor_id)
		if armor_id == _normalize_loadout_id(selected_armor_id):
			option_button.select(option_button.item_count - 1)


func _populate_compact_weapon_option_button(option_button: OptionButton, selected_weapon_id: String) -> void:
	option_button.clear()
	for option_variant in WEAPON_LOADOUT_OPTIONS:
		var option: Dictionary = Dictionary(option_variant)
		var weapon_id: String = String(option.get("id", DEFAULT_MEMBER_WEAPON))
		option_button.add_item(_build_compact_weapon_label(weapon_id))
		option_button.set_item_metadata(option_button.item_count - 1, weapon_id)
		if weapon_id == _normalize_weapon_id(selected_weapon_id):
			option_button.select(option_button.item_count - 1)


func _build_compact_weapon_label(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return "SMG"
		"rifle":
			return "Rifle"
		"sniper":
			return "Snip"
		"rocket_launcher":
			return "Rkt"
		"medictool":
			return "Med"
		"none":
			return "-"
		_:
			return "SMG"


func _build_compact_weapon_preview(preview_name: String, weapon_id: String) -> TextureRect:
	var preview_rect := TextureRect.new()
	preview_rect.name = preview_name
	preview_rect.custom_minimum_size = Vector2.ZERO
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var normalized_weapon_id: String = _normalize_weapon_id(weapon_id)
	preview_rect.texture = _get_weapon_preview_texture(normalized_weapon_id)
	preview_rect.visible = preview_rect.texture != null
	preview_rect.tooltip_text = "No weapon" if normalized_weapon_id == "none" else _build_weapon_label(normalized_weapon_id)
	preview_rect.set_meta("weapon_id", normalized_weapon_id)
	preview_rect.set_meta("weapon_preview_path", _get_weapon_preview_path(normalized_weapon_id))
	_apply_help_id(preview_rect, "loadout.weapon_none" if normalized_weapon_id == "none" else "loadout.weapon_preview")
	return preview_rect


func _populate_compact_loadout_badge_row(badge_row: HBoxContainer, member_profile, is_lead: bool) -> void:
	for child in badge_row.get_children():
		badge_row.remove_child(child)
		child.queue_free()

	var badge_source = member_profile
	if member_profile != null and member_profile.has_method("to_dict"):
		var profile_data: Dictionary = Dictionary(member_profile.call("to_dict")).duplicate(true)
		profile_data["is_fireteam_lead"] = is_lead
		badge_source = profile_data

	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", badge_source, 2))
	badge_row.visible = not badges.is_empty()
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var texture_rect := TextureRect.new()
		texture_rect.name = "RankBadge_%s" % String(badge.get("badge_key", badge.get("badge_id", "unknown"))).strip_edges()
		texture_rect.custom_minimum_size = Vector2(18.0, 18.0)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", texture_rect, badge)
		var badge_path: String = String(badge.get("path", "")).strip_edges()
		if not badge_path.is_empty() and ResourceLoader.exists(badge_path):
			texture_rect.texture = load(badge_path) as Texture2D
		if texture_rect.texture == null:
			texture_rect.modulate = Color(1.0, 0.45, 0.35, 0.95)
			texture_rect.set_meta("missing_rank_badge_asset", true)
		badge_row.add_child(texture_rect)


func _build_compact_member_loadout_status(unit_id: String, member_loadout: Dictionary) -> String:
	var respawn_text: String = _build_unit_respawn_text(unit_id)
	return "FOB | %s | %s" % [respawn_text, _format_member_loadout_short(member_loadout)]


func _format_member_loadout_short(member_loadout: Dictionary) -> String:
	var armor_label: String = _normalize_loadout_id(String(member_loadout.get("armor", "medium"))).capitalize()
	var weapon_1_label: String = _build_weapon_label(String(member_loadout.get("weapon_1", member_loadout.get("weapon", DEFAULT_MEMBER_WEAPON))))
	var weapon_2_label: String = _build_weapon_label(String(member_loadout.get("weapon_2", DEFAULT_MEMBER_WEAPON)))
	return "%s / %s / %s" % [armor_label, weapon_1_label, weapon_2_label]


func _on_loadout_member_row_gui_input(event: InputEvent, unit_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		var profile = _profiles_by_id.get(unit_id, null)
		if mouse_event.double_click:
			_open_character_overlay(unit_id)
			return
		_on_operator_card_pressed(unit_id, profile, "loadout_staging")


func _render_fireteam_card_member_loadout_rows(container: VBoxContainer, fireteam_id: String, member_ids: PackedStringArray, lead_unit_id: String) -> void:
	for member_unit_id in member_ids:
		var member_row := _build_member_loadout_row(fireteam_id, member_unit_id, lead_unit_id, true)
		if member_row != null:
			container.add_child(member_row)


func _render_dropship_member_rows(container: VBoxContainer, fireteam_id: String, member_ids: PackedStringArray) -> void:
	_render_fireteam_member_progress_rows(container, fireteam_id, member_ids, "boarding")


func _render_respawn_anchor_member_rows(container: VBoxContainer, fireteam_id: String, member_ids: PackedStringArray) -> void:
	_render_fireteam_member_progress_rows(container, fireteam_id, member_ids, "respawn_anchor")


func _render_fireteam_member_progress_rows(container: VBoxContainer, fireteam_id: String, member_ids: PackedStringArray, progress_mode: String) -> void:
	var status_label := Label.new()
	status_label.text = _build_fireteam_progress_text(fireteam_id, progress_mode)
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
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_progress_member_row_gui_input.bind(member_unit_id))
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
		member_status_label.text = _build_member_progress_status_text(fireteam_id, member_unit_id, progress_mode)
		member_status_label.add_theme_font_size_override("font_size", 9)
		member_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(member_status_label)

		var progress_bar := ProgressBar.new()
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = _build_member_progress_value(fireteam_id, member_unit_id, progress_mode)
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
		progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		member_vbox.add_child(progress_bar)


func _on_progress_member_row_gui_input(event: InputEvent, unit_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return
		var profile = _profiles_by_id.get(unit_id, null)
		if mouse_event.double_click:
			_open_character_overlay(unit_id)
			return
		_on_operator_card_pressed(unit_id, profile, "fireteam_progress")


func _on_close_overlay_button_pressed() -> void:
	_character_overlay_open = false
	_update_character_overlay_visibility()


func _build_fireteam_member_names(fireteam_id: String) -> PackedStringArray:
	var member_names: PackedStringArray = []
	for unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		member_names.append(_build_display_name(unit_id))

	return member_names


func _build_fireteam_card_teamfit_summary(fireteam_id: String, definition: Dictionary) -> String:
	var snapshot: Dictionary = _build_fireteam_cohesion_snapshot(fireteam_id, definition)
	if snapshot.is_empty():
		return "Teamfit: no members"
	return String(snapshot.get("summary_text", "Teamfit: n/a"))


func _build_fireteam_cohesion_snapshot(fireteam_id: String, definition: Dictionary = {}) -> Dictionary:
	var member_units: Array = _get_fireteam_member_profile_data(fireteam_id)
	var lead_unit_id: String = String(definition.get("lead_unit_id", "")).strip_edges()
	return Dictionary(FIRETEAM_COHESION_RESOLVER_SCRIPT.call("build_fireteam_snapshot", fireteam_id, member_units, lead_unit_id))


func _get_fireteam_member_profile_data(fireteam_id: String) -> Array:
	var member_units: Array = []
	for member_unit_id in _get_member_unit_ids_for_fireteam(fireteam_id):
		var profile = _profiles_by_id.get(member_unit_id, null)
		if profile != null and profile.has_method("to_dict"):
			member_units.append(Dictionary(profile.call("to_dict")).duplicate(true))
			continue
		var unit_data: Dictionary = _get_available_unit_data(member_unit_id)
		if not unit_data.is_empty():
			member_units.append(unit_data)
	return member_units


func _get_available_unit_data(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	for unit_variant in _available_units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges() == normalized_unit_id:
			return unit.duplicate(true)
	return {}


func _get_member_unit_ids_for_fireteam(fireteam_id: String) -> PackedStringArray:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var member_ids: PackedStringArray = []
	if normalized_fireteam_id.is_empty() or _find_fireteam_definition_index(normalized_fireteam_id) < 0:
		return member_ids
	var assignments: Dictionary = _build_assignment_lookup()
	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		if String(assignments.get(unit_id, "")) != normalized_fireteam_id:
			continue
		member_ids.append(unit_id)
	return member_ids


func _format_member_names(member_names: PackedStringArray) -> String:
	if member_names.is_empty():
		return "none"
	return ", ".join(member_names)


func _get_selected_fireteam_id_for_unit(unit_id: String) -> String:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return ""
	return String(_build_assignment_lookup().get(normalized_unit_id, ""))


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
		definition.get("member_loadouts", {}) if typeof(definition.get("member_loadouts", {})) == TYPE_DICTIONARY else {},
		_extract_member_unit_ids_from_definition(definition)
	)


func _make_fireteam_definition(
	fireteam_id: String,
	label: String,
	respawn_enabled: bool = false,
	loadout: String = "medium",
	lead_unit_id: String = "",
	member_loadouts: Dictionary = {},
	member_unit_ids: PackedStringArray = PackedStringArray()
) -> Dictionary:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	return {
		"id": normalized_fireteam_id,
		"label": label.strip_edges() if not label.strip_edges().is_empty() else normalized_fireteam_id.to_upper(),
		"respawn_enabled": respawn_enabled,
		"loadout": _normalize_loadout_id(loadout),
		"lead_unit_id": lead_unit_id.strip_edges(),
		"member_loadouts": member_loadouts.duplicate(true),
		"member_unit_ids": member_unit_ids.duplicate(),
	}


func _extract_member_unit_ids_from_definition(definition: Dictionary) -> PackedStringArray:
	var member_ids: PackedStringArray = []
	var source_variant = definition.get("member_unit_ids", definition.get("members", []))
	if typeof(source_variant) != TYPE_ARRAY and typeof(source_variant) != TYPE_PACKED_STRING_ARRAY:
		return member_ids
	for member_variant in source_variant:
		var member_unit_id: String = ""
		if typeof(member_variant) == TYPE_DICTIONARY:
			var member_data: Dictionary = member_variant
			member_unit_id = String(member_data.get("unit_id", member_data.get("id", ""))).strip_edges()
		else:
			member_unit_id = String(member_variant).strip_edges()
		if member_unit_id.is_empty() or member_ids.has(member_unit_id):
			continue
		member_ids.append(member_unit_id)
	return member_ids


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
		"smg", "maschinenpistole", "mp":
			return "smg"
		"rifle", "assault_rifle", "sturmgewehr":
			return "rifle"
		"sniper", "sniper_rifle", "sniper-rifle", "sniper rifle", "scharfschuetzengewehr", "praezisionsgewehr":
			return "sniper"
		"rocket_launcher", "rocket", "rocketlauncher", "rocket-launcher", "rocket launcher", "panzerfaust", "raketenwerfer":
			return "rocket_launcher"
		"medic_tool", "medic-tool", "medic tool", "medictool":
			return "medictool"
		"none", "no_weapon", "no-weapon", "no weapon", "unarmed", "keine_waffe", "keine-waffe", "keine waffe":
			return "none"
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
		definition["member_unit_ids"] = member_ids.duplicate()
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
	for option in WEAPON_LOADOUT_OPTIONS:
		var weapon_id: String = String(option["id"])
		var option_label: String = _build_weapon_option_label(weapon_id, String(option["label"]))
		var preview_texture := _get_weapon_preview_texture(weapon_id)
		if preview_texture != null:
			option_button.add_icon_item(preview_texture, option_label)
		else:
			option_button.add_item(option_label)
		option_button.set_item_metadata(option_button.item_count - 1, weapon_id)
		if String(option["id"]) == _normalize_weapon_id(selected_weapon_id):
			option_button.select(option_button.item_count - 1)


func _build_weapon_option_label(weapon_id: String, fallback_label: String = "") -> String:
	var label: String = fallback_label.strip_edges()
	if label.is_empty():
		label = _build_weapon_label(weapon_id)
	var tile_range: int = int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id))
	return "%s %d" % [label, tile_range]


func _build_weapon_label(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return "SMG"
		"rifle":
			return "Rifle"
		"sniper":
			return "Sniper"
		"rocket_launcher":
			return "Rocket"
		"medictool":
			return "Medictool"
		"none":
			return "None"
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
	if index >= 0 and index < WEAPON_LOADOUT_OPTIONS.size():
		return _normalize_weapon_id(String(Dictionary(WEAPON_LOADOUT_OPTIONS[index]).get("id", DEFAULT_MEMBER_WEAPON)))
	return DEFAULT_MEMBER_WEAPON


func _build_weapon_slot_control(slot_name: String, selected_weapon_id: String, fireteam_id: String, member_unit_id: String, slot_index: int) -> Control:
	var slot_box := VBoxContainer.new()
	slot_box.name = "%sSlot" % slot_name
	slot_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_box.add_theme_constant_override("separation", 2)
	_apply_help_id(slot_box, "loadout.weapon_slot")

	var weapon_select := OptionButton.new()
	weapon_select.name = "%sSelect" % slot_name
	weapon_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_select.custom_minimum_size = Vector2(70.0, 0.0)
	weapon_select.add_theme_font_size_override("font_size", 9)
	_apply_help_id(weapon_select, "loadout.weapon_slot")
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
	_apply_help_id(preview_rect, "loadout.weapon_none" if _normalize_weapon_id(selected_weapon_id) == "none" else "loadout.weapon_preview")
	preview_rect.tooltip_text = "No weapon selected." if _normalize_weapon_id(selected_weapon_id) == "none" else preview_path
	slot_box.add_child(preview_rect)

	return slot_box


func _get_weapon_preview_path(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return SMG_BLASTER_PREVIEW_PATH
		"rifle":
			return SMG_BLASTER_PREVIEW_PATH
		"sniper":
			return SNIPER_PREVIEW_PATH
		"rocket_launcher":
			return ROCKET_LAUNCHER_PREVIEW_PATH
		"medictool":
			return MEDICTOOL_BLASTER_PREVIEW_PATH
		"none":
			return ""
		_:
			return ""


func _get_weapon_preview_texture(weapon_id: String) -> Texture2D:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return SMG_BLASTER_PREVIEW_TEXTURE
		"rifle":
			return SMG_BLASTER_PREVIEW_TEXTURE
		"sniper":
			return SNIPER_PREVIEW_TEXTURE
		"rocket_launcher":
			return ROCKET_LAUNCHER_PREVIEW_TEXTURE
		"medictool":
			return MEDICTOOL_BLASTER_PREVIEW_TEXTURE
		"none":
			return null
		_:
			return null


func _calculate_fireteam_loadout_weight(fireteam_id: String, member_ids: PackedStringArray) -> float:
	var total_weight: float = 0.0
	for member_unit_id in member_ids:
		total_weight += _calculate_member_loadout_weight(_get_member_loadout(fireteam_id, String(member_unit_id)))
	return total_weight


func _calculate_member_loadout_weight(member_loadout: Dictionary) -> float:
	var resolver = LOADOUT_MODIFIER_RESOLVER_SCRIPT.new()
	if resolver == null:
		return 0.0
	return float(resolver.call("calculate_loadout_weight", member_loadout))


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


func _apply_help_id(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_help_id: String = help_id.strip_edges()
	if normalized_help_id.is_empty():
		return
	control.set_meta("help_id", normalized_help_id)
	if normalized_help_id != "loadout.weapon_none":
		control.tooltip_text = ""


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
	if _is_respawn_anchor_active(assigned_fireteam_id):
		return "Loc: FOB / %s / Locating" % location_text
	if bool(_get_fireteam_definition(assigned_fireteam_id).get("respawn_enabled", false)):
		return "Loc: FOB / %s / Respawn" % location_text
	if assigned_fireteam_id == _loadout_staged_fireteam_id:
		return "Loc: FOB / %s / Loadout" % location_text
	return "Loc: FOB / %s" % location_text


func _build_unit_respawn_text(unit_id: String) -> String:
	var assigned_fireteam_id := _get_selected_fireteam_id_for_unit(unit_id)
	if assigned_fireteam_id.is_empty():
		return "Respawn: off"
	if _is_respawn_anchor_active(assigned_fireteam_id):
		return "Respawn: locating"
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
		_make_transport_card_scroll_friendly(craft_card)


func _make_transport_card_scroll_friendly(root: Node) -> void:
	if root == null:
		return
	var control := root as Control
	if control != null and not (control is BaseButton):
		control.mouse_filter = Control.MOUSE_FILTER_PASS
	for child in root.get_children():
		_make_transport_card_scroll_friendly(child)


func _render_staging_fireteam_card(container: VBoxContainer, fireteam_id: String, empty_text: String, source_context: String, member_ids: PackedStringArray = [], lead_unit_id: String = "") -> void:
	_clear_container(container)
	var normalized_fireteam_id := _normalize_fireteam_id(fireteam_id)
	if normalized_fireteam_id.is_empty():
		if empty_text.strip_edges().is_empty():
			return
		var empty_label := Label.new()
		empty_label.text = empty_text
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 9)
		container.add_child(empty_label)
		return

	var fireteam_card := _create_fireteam_card(normalized_fireteam_id, source_context)
	if fireteam_card == null:
		return
	_apply_fireteam_reference_card_contract(fireteam_card, source_context)
	if source_context == "respawn_staging":
		_render_respawn_anchor_member_rows(fireteam_card.get_member_host(), normalized_fireteam_id, member_ids)
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
		source_context,
		_build_fireteam_card_teamfit_summary(fireteam_id, definition)
	)
	if not fireteam_card.card_pressed.is_connected(_on_fireteam_card_pressed):
		fireteam_card.card_pressed.connect(_on_fireteam_card_pressed)
	if not fireteam_card.rename_committed.is_connected(_on_fireteam_card_label_committed):
		fireteam_card.rename_committed.connect(_on_fireteam_card_label_committed)
	if not fireteam_card.unit_dropped.is_connected(_on_fireteam_card_unit_dropped):
		fireteam_card.unit_dropped.connect(_on_fireteam_card_unit_dropped)
	_apply_fireteam_reference_card_contract(fireteam_card, source_context)
	return fireteam_card


func _apply_fireteam_reference_card_contract(fireteam_card: Control, source_context: String) -> void:
	if fireteam_card == null or source_context == "fireteam_list":
		return
	fireteam_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	fireteam_card.custom_minimum_size = Vector2(FOB_FIRETEAM_REFERENCE_CARD_WIDTH, fireteam_card.custom_minimum_size.y)
	fireteam_card.set_meta("fob_fireteam_reference_card", true)
	fireteam_card.set_meta("fob_fireteam_reference_width", FOB_FIRETEAM_REFERENCE_CARD_WIDTH)


func _build_transport_craft_card(craft_state: Dictionary) -> Control:
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return null
	var is_selected: bool = craft_id == _dropship_transport_craft_id
	var is_in_transit: bool = bool(craft_state.get("is_in_transit", false))
	var is_boardable: bool = bool(craft_state.get("is_boardable", false))
	var can_stage_fireteams: bool = _can_stage_fireteam_into_craft(craft_state)
	var can_edit_pilot: bool = _can_edit_transport_craft_pilot(craft_state)
	var craft_card: PanelContainer = PanelContainer.new()
	craft_card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	craft_card.custom_minimum_size = Vector2(FOB_TRANSPORT_CARD_WIDTH, 0.0)
	craft_card.mouse_filter = Control.MOUSE_FILTER_PASS
	craft_card.set_meta("transport_craft_id", craft_id)
	craft_card.set_meta("shared_transport_card_width", FOB_TRANSPORT_CARD_WIDTH)
	craft_card.set_meta("shared_transport_card_half_width", true)
	craft_card.set_meta("fob_ship_texture_size", Vector2(FOB_TRANSPORT_SHIP_TEXTURE_WIDTH, FOB_TRANSPORT_SHIP_TEXTURE_HEIGHT))
	craft_card.gui_input.connect(_on_transport_craft_card_gui_input.bind(craft_id))
	if can_stage_fireteams or can_edit_pilot:
		craft_card.set_script(FOB_DROP_PANEL_SCRIPT)
		craft_card.drop_kind = "dropship|%s" % craft_id
		if can_stage_fireteams:
			craft_card.fireteam_dropped.connect(_on_staging_fireteam_dropped)
		craft_card.unit_dropped.connect(_on_transport_craft_card_unit_dropped)
	var is_waiting_on_mission: bool = bool(craft_state.get("mission_waiting", false))
	var is_transit_to_mission: bool = bool(craft_state.get("mission_transit_to_map", false))
	var is_transit_to_fob: bool = bool(craft_state.get("mission_transit_to_fob", false))
	var is_air_asset_recovery: bool = bool(craft_state.get("air_asset_unavailable", false))
	var is_launch_ready_in_fob: bool = craft_id == _mission_launch_ready_craft_id and _has_boarded_mission_payload(craft_id) and not is_waiting_on_mission and not is_transit_to_mission and not is_transit_to_fob
	var can_send_to_mission: bool = _can_mark_transport_craft_launch_ready(craft_state)
	var send_block_reason: String = _get_transport_craft_launch_block_reason(craft_state)
	var pilot_unit_id: String = String(craft_state.get("pilot_unit_id", "")).strip_edges()
	craft_card.set_meta("transport_craft_can_send", can_send_to_mission)
	craft_card.set_meta("transport_craft_send_block_reason", send_block_reason)
	TRANSPORT_CRAFT_CARD_UI_SCRIPT.apply_card_state(
		craft_card,
		{
			"selected": is_selected,
			"in_transit": is_in_transit or is_air_asset_recovery,
			"can_stage": can_stage_fireteams,
			"title_text": UI_BLOCK_LABELS_SCRIPT.prefixed_transport_title(_build_transport_craft_title(craft_state)),
			"ship_texture": _get_transport_craft_texture(craft_state),
			"ship_texture_width": FOB_TRANSPORT_SHIP_TEXTURE_WIDTH,
			"ship_texture_height": FOB_TRANSPORT_SHIP_TEXTURE_HEIGHT,
			"ship_texture_stretch_mode": TextureRect.STRETCH_KEEP_ASPECT_COVERED,
			"content_minimum_height": FOB_TRANSPORT_SHIP_TEXTURE_HEIGHT,
			"pilot_profile": _profiles_by_id.get(pilot_unit_id, null),
			"pilot_text": _build_transport_craft_pilot_text(craft_state),
			"pilot_source_context": "transport_craft_pilot",
			"pilot_selected": pilot_unit_id == _focused_unit_id,
			"pilot_disabled": is_in_transit,
			"pilot_drag_enabled": can_edit_pilot,
			"pilot_card_unit_dropped": Callable(self, "_on_transport_craft_pilot_card_unit_dropped").bind(craft_id),
			"pilot_card_pressed": Callable(self, "_on_operator_card_pressed"),
			"pilot_card_open_requested": Callable(self, "_on_operator_card_open_requested"),
			"info_lines": [
				_build_transport_craft_cargo_text(craft_state),
				_build_transport_craft_status_line(craft_state),
			],
			"progress_visible": true,
			"progress_value": _build_transport_craft_progress_value(craft_state),
			"primary_action": {
				"visible": true,
				"text": "Board",
				"disabled": not _can_start_boarding_for_craft(craft_state),
				"square_size": 48.0,
				"ready_style": true,
				"callback": Callable(self, "_on_transport_craft_boarding_requested").bind(craft_id),
			},
			"secondary_action": {
				"visible": true,
				"text": "Waiting" if is_waiting_on_mission else "En Route" if is_transit_to_mission else "Return" if is_transit_to_fob else "Ready" if is_launch_ready_in_fob else "Send",
				"disabled": is_air_asset_recovery or is_launch_ready_in_fob or is_waiting_on_mission or is_transit_to_mission or is_transit_to_fob or not can_send_to_mission,
				"square_size": 48.0,
				"ready_style": true,
				"callback": Callable(self, "_on_transport_craft_mission_stage_requested").bind(craft_id),
			},
		}
	)

	var extra_content_host: VBoxContainer = TRANSPORT_CRAFT_CARD_UI_SCRIPT.get_extra_content_host(craft_card)

	var visible_fireteam_ids: PackedStringArray = _get_visible_transport_craft_fireteam_ids(craft_id)
	var visible_member_count: int = maxi(_get_transport_craft_staged_member_count(craft_id), _get_boarded_unit_ids_for_craft(craft_id).size())
	craft_card.set_meta("transport_craft_payload_visible", not visible_fireteam_ids.is_empty() or visible_member_count > 0)
	craft_card.set_meta("transport_craft_visible_fireteam_ids", Array(visible_fireteam_ids))
	if is_boardable or not visible_fireteam_ids.is_empty() or visible_member_count > 0:
		var drop_label := Label.new()
		if not visible_fireteam_ids.is_empty() or visible_member_count > 0:
			if _get_transport_craft_remaining_capacity(craft_state) <= 0 and is_boardable:
				drop_label.text = "Full %d/%d NPC assigned + pilot" % [visible_member_count, DROPSHIP_NPC_CAPACITY]
			elif _has_boarded_mission_payload(craft_id):
				drop_label.text = "Inside dropship | %d/%d NPC + pilot" % [visible_member_count, DROPSHIP_NPC_CAPACITY]
			else:
				drop_label.text = "Assigned fireteams | %d/%d NPC + pilot" % [visible_member_count, DROPSHIP_NPC_CAPACITY]
			drop_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			drop_label.add_theme_font_size_override("font_size", 9)
			extra_content_host.add_child(drop_label)
		if not visible_fireteam_ids.is_empty():
			for fireteam_id_variant in visible_fireteam_ids:
				var fireteam_id: String = String(fireteam_id_variant)
				var fireteam_card := _create_fireteam_card(fireteam_id, "dropship_wait")
				if fireteam_card == null:
					continue
				_apply_fireteam_reference_card_contract(fireteam_card, "dropship_wait")
				_render_dropship_member_rows(fireteam_card.get_member_host(), fireteam_id, _get_member_unit_ids_for_fireteam(fireteam_id))
				extra_content_host.add_child(fireteam_card)

	return craft_card


func _build_transport_craft_title(craft_state: Dictionary) -> String:
	var craft_name: String = String(craft_state.get("display_name", "craft")).strip_edges()
	if bool(craft_state.get("air_asset_unavailable", false)):
		var meta_state: String = String(craft_state.get("air_asset_meta_status", "")).strip_edges()
		return "%s Â· REPLACE" % craft_name if meta_state == "destroyed_replacement_pending" else "%s Â· REPAIR" % craft_name
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
	if bool(craft_state.get("air_asset_unavailable", false)):
		var meta_state: String = String(craft_state.get("air_asset_meta_status", "")).strip_edges()
		var eta_seconds: int = int(craft_state.get("air_asset_recovery_eta_seconds", 0))
		var label: String = "replacement pending" if meta_state == "destroyed_replacement_pending" else "repairing"
		return "Status: %s | ETA %ds" % [label, eta_seconds]
	if bool(craft_state.get("mission_waiting", false)):
		return "Status: Holding off-map | waiting for Drop"
	if bool(craft_state.get("mission_transit_to_map", false)):
		return "Status: ETA mission map %ds" % int(craft_state.get("transfer_eta_seconds", 0))
	if bool(craft_state.get("mission_transit_to_fob", false)):
		return "Status: returning to FOB | ETA %ds" % int(craft_state.get("transfer_eta_seconds", 0))
	if bool(craft_state.get("is_in_transit", false)):
		return "Status: inbound to FOB | ETA %ds | 6 NPC + pilot" % int(craft_state.get("transfer_eta_seconds", 0))
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	if craft_id == _mission_launch_ready_craft_id and _has_boarded_mission_payload(craft_id):
		return "Status: staged in FOB | start mission to launch"
	if bool(craft_state.get("is_boardable", false)):
		var launch_block_reason: String = _get_transport_craft_launch_block_reason(craft_state)
		if launch_block_reason == "boarding_in_progress":
			return "Status: boarding in progress | %s" % _build_transport_craft_boarding_count_text(craft_id)
		if launch_block_reason == "boarding_pending":
			return "Status: boarding pending | %s" % _build_transport_craft_boarding_count_text(craft_id)
		if launch_block_reason == "boarding_incomplete":
			return "Status: boarding incomplete | %s" % _build_transport_craft_boarding_count_text(craft_id)
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
	if bool(craft_state.get("air_asset_unavailable", false)):
		return float(craft_state.get("air_asset_recovery_progress", 0.0))
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
	if normalized_craft_id.is_empty():
		return 0
	var staged_member_count: int = 0
	for fireteam_id_variant in _get_staged_fireteam_ids_for_craft(normalized_craft_id):
		staged_member_count += _get_member_unit_ids_for_fireteam(String(fireteam_id_variant)).size()
	return staged_member_count


func _get_transport_craft_remaining_capacity(craft_state: Dictionary) -> int:
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	return maxi(DROPSHIP_NPC_CAPACITY - _get_transport_craft_staged_member_count(craft_id), 0)


func _has_transport_craft_capacity_for_fireteam(craft_state: Dictionary, fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = _normalize_fireteam_id(fireteam_id)
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	if normalized_fireteam_id.is_empty():
		return _get_transport_craft_remaining_capacity(craft_state) > 0
	if _get_staged_fireteam_ids_for_craft(craft_id).has(normalized_fireteam_id):
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
	return _get_transport_craft_launch_block_reason(craft_state).is_empty()


func _get_transport_craft_launch_block_reason(craft_state: Dictionary) -> String:
	if craft_state.is_empty():
		return "missing_craft"
	if bool(craft_state.get("air_asset_unavailable", false)):
		return "air_asset_unavailable"
	if not bool(craft_state.get("is_boardable", false)):
		return "not_boardable"
	if bool(craft_state.get("mission_waiting", false)):
		return "mission_waiting"
	if bool(craft_state.get("mission_transit_to_map", false)):
		return "mission_transit_to_map"
	if bool(craft_state.get("mission_transit_to_fob", false)):
		return "mission_transit_to_fob"

	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	var dropship_state: Dictionary = _get_dropship_state_for_craft(craft_id)
	var phase: String = String(dropship_state.get("phase", "idle")).strip_edges()
	var boarding_counts: Dictionary = _get_transport_craft_boarding_counts(craft_id)
	var missing_unit_ids: PackedStringArray = _copy_packed_string_array(boarding_counts.get("missing_unit_ids", PackedStringArray()))

	if phase == "boarding":
		return "boarding_in_progress"
	if phase == "incoming" and not missing_unit_ids.is_empty():
		return "dropship_inbound"
	if phase == "ready" and not missing_unit_ids.is_empty():
		return "boarding_pending"
	if not missing_unit_ids.is_empty():
		return "boarding_incomplete"
	if not _has_boarded_mission_payload(craft_id):
		return "no_boarded_payload"
	return ""


func _get_transport_craft_required_boarding_unit_ids(craft_id: String) -> PackedStringArray:
	var required_unit_ids: PackedStringArray = []
	for fireteam_id_variant in _get_visible_transport_craft_fireteam_ids(craft_id):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges()
		if fireteam_id.is_empty():
			continue
		for unit_id_variant in _get_member_unit_ids_for_fireteam(fireteam_id):
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty() or required_unit_ids.has(unit_id):
				continue
			required_unit_ids.append(unit_id)
	return required_unit_ids


func _get_transport_craft_boarding_counts(craft_id: String) -> Dictionary:
	var required_unit_ids: PackedStringArray = _get_transport_craft_required_boarding_unit_ids(craft_id)
	var boarded_unit_ids: PackedStringArray = _get_boarded_unit_ids_for_craft(craft_id)
	var missing_unit_ids: PackedStringArray = []
	var boarded_required_count: int = 0
	for unit_id_variant in required_unit_ids:
		var unit_id: String = String(unit_id_variant)
		if boarded_unit_ids.has(unit_id):
			boarded_required_count += 1
			continue
		missing_unit_ids.append(unit_id)
	return {
		"boarded_count": boarded_required_count,
		"required_count": required_unit_ids.size(),
		"missing_unit_ids": missing_unit_ids,
	}


func _build_transport_craft_boarding_count_text(craft_id: String) -> String:
	var boarding_counts: Dictionary = _get_transport_craft_boarding_counts(craft_id)
	var required_count: int = int(boarding_counts.get("required_count", 0))
	if required_count <= 0:
		return "%d NPC boarded" % _get_boarded_unit_ids_for_craft(craft_id).size()
	return "%d/%d NPC boarded" % [int(boarding_counts.get("boarded_count", 0)), required_count]


func _can_request_homebase_mission_start(craft_state: Dictionary) -> bool:
	if craft_state.is_empty():
		return false
	if bool(craft_state.get("air_asset_unavailable", false)):
		return false
	var craft_id: String = String(craft_state.get("craft_id", "")).strip_edges()
	var has_boarded_payload: bool = _has_boarded_mission_payload(craft_id) or int(craft_state.get("passenger_count", 0)) > 0
	if not has_boarded_payload:
		return false
	return bool(craft_state.get("mission_waiting", false))


func _can_start_boarding_for_craft(craft_state: Dictionary) -> bool:
	if craft_state.is_empty():
		return false
	if bool(craft_state.get("air_asset_unavailable", false)):
		return false
	if not bool(craft_state.get("is_boardable", false)):
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
	_set_selected_transport_craft_state(normalized_craft_id)
	_refresh_ui_state()


func _on_transport_craft_card_gui_input(event: InputEvent, craft_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_transport_craft_selected(craft_id)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_on_transport_craft_selected(craft_id)


func _on_transport_craft_boarding_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_set_selected_transport_craft_state(normalized_craft_id)
	_on_start_boarding_button_pressed()
	_refresh_ui_state()


func _on_transport_craft_mission_stage_requested(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_set_selected_transport_craft_state(normalized_craft_id)
	var craft_state: Dictionary = _get_transport_craft_state(normalized_craft_id)
	if not _can_mark_transport_craft_launch_ready(craft_state):
		_refresh_ui_state()
		return
	_save_current_dropship_state()
	_mission_launch_ready_craft_id = normalized_craft_id
	transport_craft_mission_stage_requested.emit(normalized_craft_id)
	_refresh_ui_state()


func _sanitize_dropship_fireteam_queue(source_ids: PackedStringArray) -> PackedStringArray:
	var sanitized_ids: PackedStringArray = []
	for fireteam_id_variant in source_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or _find_fireteam_definition_index(fireteam_id) < 0:
			continue
		if _build_fireteam_member_names(fireteam_id).is_empty() or sanitized_ids.has(fireteam_id):
			continue
		sanitized_ids.append(fireteam_id)
	return sanitized_ids


func _trim_dropship_queue_for_capacity(source_ids: PackedStringArray) -> PackedStringArray:
	var remaining_capacity: int = DROPSHIP_NPC_CAPACITY
	var trimmed_queue: PackedStringArray = []
	for fireteam_id_variant in source_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or trimmed_queue.has(fireteam_id):
			continue
		var member_count: int = _get_member_unit_ids_for_fireteam(fireteam_id).size()
		if member_count <= 0 or member_count > remaining_capacity:
			continue
		trimmed_queue.append(fireteam_id)
		remaining_capacity -= member_count
	return trimmed_queue


func _sanitize_boarded_unit_ids(source_ids: PackedStringArray) -> PackedStringArray:
	var sanitized_ids: PackedStringArray = []
	for unit_id_variant in source_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or not _selected_unit_ids.has(unit_id) or sanitized_ids.has(unit_id):
			continue
		sanitized_ids.append(unit_id)
	return sanitized_ids


func _sanitize_boarded_fireteam_ids(source_ids: PackedStringArray) -> PackedStringArray:
	var sanitized_ids: PackedStringArray = []
	for fireteam_id_variant in source_ids:
		var fireteam_id: String = _normalize_fireteam_id(String(fireteam_id_variant))
		if fireteam_id.is_empty() or _find_fireteam_definition_index(fireteam_id) < 0 or sanitized_ids.has(fireteam_id):
			continue
		sanitized_ids.append(fireteam_id)
	return sanitized_ids


func _sanitize_saved_dropship_states() -> void:
	var sanitized_states: Dictionary = {}
	for craft_id_variant in _dropship_state_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty():
			continue
		var craft_state: Dictionary = _get_transport_craft_state(craft_id)
		if craft_state.is_empty():
			continue
		var raw_state_variant = _dropship_state_by_craft.get(craft_id, {})
		if typeof(raw_state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = _coerce_dropship_craft_state(raw_state_variant)
		var staged_ids: PackedStringArray = _trim_dropship_queue_for_capacity(_sanitize_dropship_fireteam_queue(_copy_packed_string_array(state.get("staged_fireteam_ids", PackedStringArray()))))
		state["staged_fireteam_ids"] = staged_ids
		state["boarding_order"] = _build_boarding_order_from_queue(staged_ids)
		state["boarded_unit_ids"] = _sanitize_boarded_unit_ids(_copy_packed_string_array(state.get("boarded_unit_ids", PackedStringArray())))
		state["boarded_fireteam_ids"] = _sanitize_boarded_fireteam_ids(_copy_packed_string_array(state.get("boarded_fireteam_ids", PackedStringArray())))
		if staged_ids.is_empty() and _copy_packed_string_array(state.get("boarded_unit_ids", PackedStringArray())).is_empty() and String(state.get("phase", "idle")).strip_edges() == "idle":
			continue
		sanitized_states[craft_id] = state
	_dropship_state_by_craft = sanitized_states


func _sanitize_staging_state() -> void:
	_loadout_staged_fireteam_id = _normalize_fireteam_id(_loadout_staged_fireteam_id)
	if _find_fireteam_definition_index(_loadout_staged_fireteam_id) < 0 or _build_fireteam_member_names(_loadout_staged_fireteam_id).is_empty():
		_loadout_staged_fireteam_id = ""

	_respawn_staged_fireteam_id = _normalize_fireteam_id(_respawn_staged_fireteam_id)
	if _find_fireteam_definition_index(_respawn_staged_fireteam_id) < 0 or (not bool(_get_fireteam_definition(_respawn_staged_fireteam_id).get("respawn_enabled", false)) and not _is_respawn_anchor_active(_respawn_staged_fireteam_id)):
		_respawn_staged_fireteam_id = ""
		_clear_respawn_anchor_progress()

	_respawn_anchor_fireteam_id = _normalize_fireteam_id(_respawn_anchor_fireteam_id)
	if _respawn_anchor_fireteam_id != _respawn_staged_fireteam_id or _find_fireteam_definition_index(_respawn_anchor_fireteam_id) < 0:
		_clear_respawn_anchor_progress()

	_dropship_staged_fireteam_ids = _sanitize_dropship_fireteam_queue(_dropship_staged_fireteam_ids)
	_sanitize_transport_craft_state()
	_trim_dropship_queue_to_capacity()
	_boarding_order = _build_boarding_order()
	_save_current_dropship_state()
	_sanitize_saved_dropship_states()


func _trim_dropship_queue_to_capacity() -> void:
	if _dropship_transport_craft_id.is_empty():
		return
	_dropship_staged_fireteam_ids = _trim_dropship_queue_for_capacity(_dropship_staged_fireteam_ids)
	_save_current_dropship_state()


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
	_dropship_state_by_craft.erase(selected_craft_id)
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
			return "Boarding: auto start ready | %d/%d boarded" % [boarded_members, total_members]
		"boarding":
			if fireteam_id == _get_boarding_fireteam_id():
				return "Boarding: %d/%d boarded | active: %s" % [boarded_members, total_members, _build_display_name(_get_boarding_member_id())]
			return "Boarding: queued | %d/%d boarded" % [boarded_members, total_members]
		"boarded":
			return "Boarding: completed | %d/%d boarded" % [boarded_members, total_members]
		_:
			return "Boarding: waiting for dropship"


func _build_respawn_anchor_progress_value(fireteam_id: String) -> float:
	if bool(_get_fireteam_definition(fireteam_id).get("respawn_enabled", false)):
		return 100.0
	if _is_respawn_anchor_active(fireteam_id):
		return clampf((1.0 - (_respawn_anchor_seconds / DEFAULT_RESPAWN_ANCHOR_SECONDS)) * 100.0, 0.0, 100.0)
	return 0.0


func _build_respawn_anchor_progress_text(fireteam_id: String) -> String:
	var total_members: int = _get_member_unit_ids_for_fireteam(fireteam_id).size()
	if bool(_get_fireteam_definition(fireteam_id).get("respawn_enabled", false)):
		return "Verorten: FOB anchor active | %d members ready" % total_members
	if _is_respawn_anchor_active(fireteam_id):
		return "Verorten: FOB anchor in progress | %.0fs" % _respawn_anchor_seconds
	return "Verorten: waiting for FOB anchor"


func _build_fireteam_progress_text(fireteam_id: String, progress_mode: String) -> String:
	if progress_mode == "respawn_anchor":
		return _build_respawn_anchor_progress_text(fireteam_id)
	return _build_boarding_progress_text(fireteam_id)


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
			return "Ready for auto boarding"
		"boarding":
			if fireteam_id == _get_boarding_fireteam_id() and unit_id == _get_boarding_member_id():
				return "Boarding %.0fs" % _boarding_seconds
			return "Queued"
		"boarded":
			return "Completed"
		_:
			return "Waiting"


func _build_member_respawn_anchor_progress_value(fireteam_id: String, _unit_id: String) -> float:
	return _build_respawn_anchor_progress_value(fireteam_id)


func _build_member_respawn_anchor_status_text(fireteam_id: String, _unit_id: String) -> String:
	if bool(_get_fireteam_definition(fireteam_id).get("respawn_enabled", false)):
		return "Located"
	if _is_respawn_anchor_active(fireteam_id):
		return "Locating %.0fs" % _respawn_anchor_seconds
	return "Waiting"


func _build_member_progress_value(fireteam_id: String, unit_id: String, progress_mode: String) -> float:
	if progress_mode == "respawn_anchor":
		return _build_member_respawn_anchor_progress_value(fireteam_id, unit_id)
	return _build_member_boarding_progress_value(fireteam_id, unit_id)


func _build_member_progress_status_text(fireteam_id: String, unit_id: String, progress_mode: String) -> String:
	if progress_mode == "respawn_anchor":
		return _build_member_respawn_anchor_status_text(fireteam_id, unit_id)
	return _build_member_boarding_status_text(fireteam_id, unit_id)


func _build_overlay_loadout_text(unit_id: String, profile) -> String:
	if profile == null:
		return "standard kit"
	var assigned_fireteam_id := _get_selected_fireteam_id_for_unit(unit_id)
	if not assigned_fireteam_id.is_empty():
		var member_loadout := _get_member_loadout(assigned_fireteam_id, unit_id)
		return "%s | Weight %.1f" % [
			CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_member_loadout(member_loadout, "standard kit"),
			_calculate_member_loadout_weight(member_loadout),
		]
	var profile_loadout: Dictionary = {
		"armor": String(profile.armor_id),
		"weapon_1": String(profile.weapon_1_id),
		"weapon_2": String(profile.weapon_2_id),
	}
	return "%s | Weight %.1f" % [
		CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_ids(String(profile.armor_id), String(profile.weapon_1_id), String(profile.weapon_2_id), "standard kit"),
		_calculate_member_loadout_weight(profile_loadout),
	]


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null
	var resource: Resource = load(portrait_path)
	return resource as Texture2D
