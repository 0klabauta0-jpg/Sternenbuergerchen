class_name TacticalInputController
extends Node

const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const TACTICAL_CARD_SCRIPT: GDScript = preload("res://scripts/ui/components/tactical_card.gd")
const STATUS_BADGE_SCRIPT: GDScript = preload("res://scripts/ui/components/status_badge.gd")
const COMMAND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/components/command_button.gd")
const PROGRESS_LINE_SCRIPT: GDScript = preload("res://scripts/ui/components/progress_line.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const TRANSPORT_CRAFT_CARD_UI_SCRIPT: GDScript = preload("res://scripts/meta/transport_craft_card_ui.gd")
const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const MISSION_PRIMARY_VIEW_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_primary_view_bridge.gd")
const MISSION_DROPSHIP_EFFECT_ADAPTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_dropship_effect_adapter.gd")
const MISSION_COMMAND_INPUT_GUARD_SCRIPT: GDScript = preload("res://scripts/mission/mission_command_input_guard.gd")
const FIRETEAM_SELECTION_ADAPTER_SCRIPT: GDScript = preload("res://scripts/tactical/ui/fireteam_selection_adapter.gd")
const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/fireteam_order_visualizer.gd")
const AD_HOC_ORDER_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/ad_hoc_order_controller.gd")
const AD_HOC_ORDER_SCRIPT: GDScript = preload("res://scripts/command/ad_hoc_order.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const FIRETEAM_COORDINATION_MANAGER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_coordination_manager.gd")
const TACTICAL_STANCE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_stance_controller.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const CONTACT_MAP_OVERLAY_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/contact_map_overlay.gd")
const DROPSHIP_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NE.png")
const DROPSHIP_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NW.png")
const DROPSHIP_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png")
const DROPSHIP_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SW.png")

const ALL_FIRETEAM_LABEL: String = "ALL"
const APPROACH_ANGLES: PackedStringArray = ["NW", "NE", "SW", "SE"]
const HOTKEY_LEGEND: String = "LMB Select | RMB Waypoint | SHIFT+Drag Area | CTRL+LMB Add | Drag Lasso | DEL Marker | 1 Move | 2 Hold | 3 Flank | 4 Take | Q/E Team | R/F Edit Phase | G GO"
const LIVE_ORDER_PHASE_INDEX: int = 1
const PHASE_PLANNING_ENABLED: bool = false
const FRIENDLY_TEAM_ID: String = "team_alpha"
const FIRETEAM_PANEL_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel"
const FIRETEAM_HEADER_LABEL_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel"
const FIRETEAM_STATUS_LABEL_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel"
const FIRETEAM_ALL_BUTTON_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton"
const FIRETEAM_INFO_VBOX_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox"
const FIRETEAM_SELECTED_CARDS_ROW_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsRow"
const FIRETEAM_MINI_PANEL_PATH: String = "../TacticalUI/FireteamMiniPanel"
const FIRETEAM_MINI_HEADER_LABEL_PATH: String = "../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniHeaderLabel"
const FIRETEAM_MINI_CARDS_VBOX_PATH: String = "../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox"
const CARD_REFRESH_INTERVAL_SECONDS: float = 0.35
const UNIT_SELECTION_PICK_RADIUS: float = 34.0
const SELECTION_DRAG_THRESHOLD: float = 10.0
const WAYPOINT_DRAG_THRESHOLD: float = 4.0
const AREA_ORDER_DRAG_THRESHOLD: float = 14.0
const AREA_ORDER_ISO_TILE_HALF_WIDTH: float = 64.0
const AREA_ORDER_ISO_TILE_HALF_HEIGHT: float = 32.0
const PHASE_WAYPOINT_COMPLETE_RADIUS: float = 26.0
const AREA_DEFENSE_POSITION_REACHED_RADIUS: float = 24.0
const AREA_ATTACK_APPROACH_REACHED_RADIUS: float = 30.0
const AD_HOC_ORDER_COMPLETE_RADIUS: float = 28.0
const DEV_CHARACTER_STAT_ROWS: Array = [
	{"key": "skill_accuracy", "label": "Treffsicherheit"},
	{"key": "skill_speed", "label": "Tempo"},
	{"key": "skill_leadership", "label": "Fuehrung"},
	{"key": "skill_toughness", "label": "Zaehigkeit"},
	{"key": "awareness", "label": "Aufmerksamkeit"},
	{"key": "recognition", "label": "Erkennung"},
	{"key": "discipline", "label": "Disziplin"},
	{"key": "stealth", "label": "Tarnung"},
]
const SUPPRESSION_HIT_GAIN: float = 1.5
const SUPPRESSION_NEAR_MISS_GAIN: float = 0.35
const SUPPRESSION_BASE_DECAY_PER_SECOND: float = 0.2
const SUPPRESSION_MIN_HOLD_MSEC: int = 500
const SUPPRESSION_NEAR_MISS_INTERVAL_MSEC: int = 950
const SUPPRESSION_HIT_CHANCE_MALUS: float = -0.3
const SUPPRESSION_MOVE_FACTOR: float = 0.3
const SUPPRESSION_HEAVY_MOVE_FACTOR: float = 0.0
const SUPPRESSION_COVER_BONUS: float = 24.0
const LEADER_INITIATED_FLANK_COOLDOWN_SECONDS: float = 6.0
const WAYPOINT_MENU_MOVE_ID: int = 100
const WAYPOINT_MENU_DEFEND_ID: int = 101
const WAYPOINT_MENU_ENGAGE_ID: int = 102
const WAYPOINT_MENU_FLANK_ID: int = 103
const WAYPOINT_MENU_TAKE_ID: int = 104
const WAYPOINT_MENU_DELETE_ID: int = 199
const AREA_ORDER_MENU_DEFEND_ID: int = 201
const AREA_ORDER_MENU_ENGAGE_ID: int = 202
const AREA_ORDER_MENU_TAKE_ID: int = 203
const AREA_ORDER_MENU_FLANK_ID: int = 204
const AREA_ORDER_MENU_DELETE_ID: int = 299
const DROP_OFFMAP_DISTANCE_MULTIPLIER: float = 2.0
const DROP_OFFMAP_MIN_DISTANCE: float = 720.0
const DROP_SHIP_SPEED: float = 340.0
const DROP_LANDING_HOLD_SECONDS: float = 0.75
const DROP_UNLOAD_INTERVAL_SECONDS: float = 0.45
const DROP_SHIP_RECALL_COOLDOWN_SECONDS: float = 2.5
const DROP_SEQUENCE_INBOUND: String = "inbound"
const DROP_SEQUENCE_LANDED: String = "landed"
const DROP_SEQUENCE_UNLOADING: String = "unloading"
const DROP_SEQUENCE_COMPLETE: String = "complete"
const DROP_SEQUENCE_OUTBOUND: String = "outbound"
const MISSION_DROPSHIP_PANEL_SIZE: Vector2 = Vector2(312.0, 104.0)
const MISSION_DROPSHIP_PANEL_MARGIN_RIGHT: float = 16.0
const MISSION_DROPSHIP_PANEL_MARGIN_TOP: float = 100.0
const MISSION_DROPSHIP_PANEL_GAP_BELOW_IDENTITY: float = 10.0
const MISSION_DROPSHIP_TITLE_FONT_SIZE: int = 10
const MISSION_DROPSHIP_SHIP_TEXTURE_SIZE: Vector2 = Vector2(72.0, 42.0)
const MISSION_DROPSHIP_PILOT_CARD_SIZE: Vector2 = Vector2(136.0, 50.0)
const MISSION_DROPSHIP_CONTENT_HEIGHT: float = 50.0
const MISSION_DROPSHIP_INFO_FONT_SIZE: int = 8
const MISSION_DROPSHIP_PROGRESS_HEIGHT: float = 6.0
const META_TRANSFER_ROUTE_COLOR: Color = Color(0.92, 0.74, 0.22, 0.72)
const META_TRANSFER_ROUTE_TEAM_COLOR: Color = Color(0.45, 0.92, 0.64, 0.96)
const META_TRANSFER_ROUTE_PILOT_COLOR: Color = Color(0.96, 0.84, 0.38, 0.98)
const META_TRANSFER_ROUTE_HOMEBASE_COLOR: Color = Color(0.95, 0.78, 0.34, 0.84)
const META_TRANSFER_ROUTE_FOB_COLOR: Color = Color(0.48, 0.9, 1.0, 0.88)
const META_TRANSFER_ROUTE_WIDTH: float = 4.0
const META_TRANSFER_ROUTE_HOMEBASE_OFFSET: Vector2 = Vector2(-252.0, -214.0)
const META_TRANSFER_ROUTE_BEND_OFFSET: Vector2 = Vector2(-158.0, -106.0)
const META_TRANSFER_ROUTE_MARKER_OFFSET: float = 12.0
const APPROACH_OFFSETS: Dictionary = {
	"NW": Vector2(-180.0, -112.0),
	"NE": Vector2(180.0, -112.0),
	"SW": Vector2(-180.0, 112.0),
	"SE": Vector2(180.0, 112.0),
}
const DROP_UNLOAD_OFFSETS := [
	Vector2(-44.0, 18.0),
	Vector2(-12.0, 6.0),
	Vector2(18.0, -8.0),
	Vector2(46.0, -18.0),
	Vector2(-62.0, 34.0),
	Vector2(64.0, -32.0),
	Vector2(-24.0, 42.0),
	Vector2(26.0, -42.0),
]

signal planning_state_changed(planning_state)

@export var alpha_flow_driver_path: NodePath
@export var bravo_flow_driver_path: NodePath
@export var charlie_flow_driver_path: NodePath
@export var target_marker_path: NodePath
@export var objective_point_path: NodePath
@export var command_feedback_label_path: NodePath
@export var hotkey_legend_label_path: NodePath
@export var move_button_path: NodePath
@export var defend_button_path: NodePath
@export var flank_button_path: NodePath
@export var take_button_path: NodePath

var preview_mode: bool = false
var _tactical_ui_visible: bool = true
var _primary_view_bridge = MISSION_PRIMARY_VIEW_BRIDGE_SCRIPT.new()
var _dropship_effect_adapter = MISSION_DROPSHIP_EFFECT_ADAPTER_SCRIPT.new()
var _command_input_guard = MISSION_COMMAND_INPUT_GUARD_SCRIPT.new()
var _selection_adapter = FIRETEAM_SELECTION_ADAPTER_SCRIPT.new()

var _current_fireteam_index: int = 0
var _current_phase_index: int = 1
var _current_approach_index: int = 0
var _selected_fireteam_ids: PackedStringArray = []
var _last_command_text: String = "AWAITING INPUT"
var _last_target_position: Vector2 = Vector2.ZERO
var _lz_position: Vector2 = Vector2.ZERO
var _has_lz_position: bool = false
var _is_lz_placement_armed: bool = false
var _is_target_placement_armed: bool = false
var _drop_ship_requested: bool = false
var _drop_ship_staged: bool = false
var _mission_drop_craft_id: String = ""
var _mission_drop_display_name: String = ""
var _mission_drop_title_text: String = ""
var _mission_drop_texture_path: String = ""
var _mission_drop_state: String = ""
var _mission_drop_pilot_text: String = ""
var _mission_drop_status_line: String = ""
var _mission_drop_progress: float = 0.0
var _mission_drop_eta_seconds: int = 0
var _mission_drop_pilot_unit_id: String = ""
var _mission_drop_pilot_display_name: String = ""
var _mission_drop_pilot_portrait_path: String = ""
var _mission_drop_passenger_count: int = 0
var _mission_drop_return_requested: bool = false
var _meta_transfer_routes: Array = []
var _drop_ship_cooldown_remaining: float = 0.0
var _card_refresh_time_remaining: float = 0.0
var _drop_sequence_phase: String = ""
var _drop_sequence_units: Array = []
var _drop_sequence_unit_index: int = 0
var _drop_sequence_timer: float = 0.0
var _drop_sequence_position: Vector2 = Vector2.ZERO
var _drop_sequence_fireteam_name: String = "ALL"
var _drop_sequence_visual_only: bool = false
var _embarked_unit_ids: Dictionary = {}
var _deployed_unit_ids: Dictionary = {}
var _runtime_activation_pending_fireteam_ids: Dictionary = {}
var _fireteam_runtime_ui_refresh_frames_remaining: int = 0
var _live_drop_bootstrap_consumed: bool = false
var _character_overlay_open: bool = false
var _character_overlay_unit_id: String = ""
var _selection_press_active: bool = false
var _selection_drag_active: bool = false
var _selection_press_screen_position: Vector2 = Vector2.ZERO
var _selection_drag_screen_position: Vector2 = Vector2.ZERO
var _selection_press_unit_id: String = ""
var _selection_press_ctrl: bool = false
var _order_plans_by_key: Dictionary = {}
var _area_orders_by_id: Dictionary = {}
var _waypoint_sequence: int = 0
var _area_order_sequence: int = 0
var _waypoint_menu_targets: Array = []
var _area_order_menu_targets: Array = []
var _focused_waypoint_ref: Dictionary = {}
var _focused_area_order_ref: Dictionary = {}
var _dragged_waypoint_ref: Dictionary = {}
var _dragged_waypoint_press_screen_position: Vector2 = Vector2.ZERO
var _is_dragging_waypoint: bool = false
var _has_dragged_waypoint: bool = false
var _area_order_press_active: bool = false
var _area_order_drag_active: bool = false
var _area_order_press_screen_position: Vector2 = Vector2.ZERO
var _area_order_drag_screen_position: Vector2 = Vector2.ZERO
var _order_visualizer_pending: bool = false
var _phase_execution_by_fireteam: Dictionary = {}
var _active_behavior_profiles_by_fireteam: Dictionary = {}
var _ad_hoc_order_controller = null
var _area_order_resolver = null
var _tactical_stance_controller = null
var _ad_hoc_execution_by_fireteam: Dictionary = {}
var _ad_hoc_resume_state_by_fireteam: Dictionary = {}
var _area_defense_execution_by_fireteam: Dictionary = {}
var _area_attack_execution_by_fireteam: Dictionary = {}
var _suppression_state_by_fireteam: Dictionary = {}
var _suppression_interrupt_pending_by_fireteam: Dictionary = {}
var _suppression_near_miss_ready_at_msec_by_fireteam: Dictionary = {}
var _tracked_health_by_unit_id: Dictionary = {}
var _coordination_manager = null
var _fireteam_movement_controller = null
var _fireteam_security_controller = null
var _active_coordination_by_id: Dictionary = {}
var _leader_initiated_flank_ready_at_msec_by_fireteam: Dictionary = {}
var _contact_overlay_pending: bool = false
var _last_planning_state_issue: String = ""


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_last_target_position = _get_target_position()
	if not _has_lz_position:
		_lz_position = _last_target_position
	_apply_hud_skin()
	_connect_button(move_button_path, Callable(self, "issue_move"))
	_connect_button(defend_button_path, Callable(self, "issue_defend"))
	_connect_button(flank_button_path, Callable(self, "issue_flank"))
	_connect_button(take_button_path, Callable(self, "issue_take"))
	_connect_named_button("../TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton", Callable(self, "_on_homebase_nav_pressed"))
	_connect_named_button("../TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton", Callable(self, "_on_fob_nav_pressed"))
	_connect_named_button("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton", Callable(self, "_on_mission_nav_pressed"))
	_connect_named_button(FIRETEAM_ALL_BUTTON_PATH, Callable(self, "_on_all_fireteam_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton", Callable(self, "_on_target_button_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton", Callable(self, "_on_clear_target_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton", Callable(self, "_on_set_lz_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton", Callable(self, "_on_call_dropship_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton", Callable(self, "_on_previous_edit_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton", Callable(self, "_on_add_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton", Callable(self, "_on_next_edit_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton", Callable(self, "_on_next_phase_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton", Callable(self, "_on_approach_nw_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton", Callable(self, "_on_approach_ne_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton", Callable(self, "_on_approach_sw_pressed"))
	_connect_named_button("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton", Callable(self, "_on_approach_se_pressed"))
	_ensure_character_overlay()
	_ensure_selection_overlay()
	_ensure_area_order_overlay()
	_ensure_waypoint_command_menu()
	_ensure_area_order_command_menu()
	_ensure_ad_hoc_order_controller()
	_ensure_area_order_resolver()
	_ensure_tactical_stance_controller()
	_ensure_coordination_manager()
	_ensure_fireteam_movement_controller()
	_ensure_fireteam_security_controller()
	_ensure_order_visualizer()
	_ensure_contact_map_overlay()
	_ensure_mission_nav_timer_label()
	_ensure_mission_dropship_panel()
	_sync_phase_selection_from_controller()
	_initialize_fireteam_suppression_state()
	_ensure_default_fireteam_selection()
	_sync_initial_runtime_active_units()
	_apply_drop_presence_state_to_units()
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_button_state()
	_refresh_world_overlays()
	_update_ui()
	_refresh_ad_hoc_panel_visibility()
	_emit_planning_state_changed()
	call_deferred("_maybe_bootstrap_live_drop")


func _process(delta: float) -> void:
	if _drop_ship_cooldown_remaining > 0.0:
		_drop_ship_cooldown_remaining = maxf(_drop_ship_cooldown_remaining - delta, 0.0)
	_update_drop_sequence(delta)
	_update_fireteam_suppression(delta)
	_update_leader_initiated_flanks()
	_update_ad_hoc_execution(delta)
	_update_active_phase_execution(delta)
	_update_area_defense_execution(delta)
	_update_area_attack_execution(delta)
	_flush_pending_drop_runtime_phase_starts()
	_refresh_fireteam_runtime_ui_if_pending()
	refresh_fireteam_security_state()
	_card_refresh_time_remaining -= delta
	if _card_refresh_time_remaining > 0.0:
		return
	_card_refresh_time_remaining = CARD_REFRESH_INTERVAL_SECONDS
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_edit_planning():
		return

	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and mouse_button_event.pressed:
			if _is_pointer_over_control() or _is_lz_placement_armed or _is_target_placement_armed:
				return
			if _try_open_waypoint_menu_at_position(mouse_button_event.position):
				get_viewport().set_input_as_handled()
			return

		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			if _is_pointer_over_control():
				return

			if mouse_button_event.shift_pressed:
				if _begin_area_order_interaction(mouse_button_event.position):
					get_viewport().set_input_as_handled()
				return

			if _try_begin_waypoint_drag(mouse_button_event.position):
				get_viewport().set_input_as_handled()
				return

			if _is_lz_placement_armed:
				if _place_lz_from_screen_position(mouse_button_event.position):
					get_viewport().set_input_as_handled()
				return

			if _is_target_placement_armed:
				if try_place_target_from_screen_position(mouse_button_event.position):
					_is_target_placement_armed = false
					_update_ui()
					get_viewport().set_input_as_handled()
				return

			_begin_selection_interaction(mouse_button_event.position, mouse_button_event.ctrl_pressed)
			get_viewport().set_input_as_handled()
			return

		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
			if _finish_area_order_interaction(mouse_button_event.position):
				get_viewport().set_input_as_handled()
				return
			if _finish_waypoint_drag(mouse_button_event.position):
				get_viewport().set_input_as_handled()
				return
			if _finish_selection_interaction(mouse_button_event.position):
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion:
		if _update_area_order_drag((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()
			return
		if _update_waypoint_drag((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()
			return
		if _update_selection_drag((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()
			return

	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.physical_keycode:
		KEY_DELETE:
			if _delete_focused_area_order() or _delete_focused_waypoint():
				get_viewport().set_input_as_handled()
		KEY_1:
			issue_move()
			get_viewport().set_input_as_handled()
		KEY_2:
			issue_defend()
			get_viewport().set_input_as_handled()
		KEY_3:
			issue_flank()
			get_viewport().set_input_as_handled()
		KEY_4:
			issue_take()
			get_viewport().set_input_as_handled()
		KEY_Q:
			_change_fireteam(-1)
			get_viewport().set_input_as_handled()
		KEY_E:
			if execute_selected_fireteam_orders():
				get_viewport().set_input_as_handled()
		KEY_TAB:
			_change_fireteam(1)
			get_viewport().set_input_as_handled()
		KEY_R:
			_change_phase(-1)
			get_viewport().set_input_as_handled()
		KEY_F:
			_change_phase(1)
			get_viewport().set_input_as_handled()
		KEY_G:
			if execute_selected_fireteam_orders():
				get_viewport().set_input_as_handled()


func issue_move() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	return _issue_command("move", "MOVE ORDER")


func issue_defend() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	return _issue_command("defend", "HOLD / DEFEND")


func issue_flank() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	return _issue_command("flank", "FLANK")


func issue_take() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	_snap_target_to_objective()
	return _issue_command("take", "TAKE / ENGAGE")


func issue_ad_hoc_order(order_type: String, target_position: Variant = null) -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return false
	_ensure_ad_hoc_order_controller()
	var issued_count: int = 0
	var normalized_order_type: String = order_type.strip_edges().to_lower()
	for fireteam_id in _selected_fireteam_ids:
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		if not _is_fireteam_eligible_for_ad_hoc(normalized_fireteam_id):
			continue
		if _interrupt_active_plan_for_ad_hoc(normalized_fireteam_id):
			if _start_ad_hoc_order_for_fireteam(normalized_fireteam_id, normalized_order_type, target_position):
				issued_count += 1
	if issued_count <= 0:
		_last_command_text = "AD-HOC BLOCKED (NO CONTACT)"
		_refresh_ad_hoc_panel_visibility()
		_update_ui()
		return false
	_last_command_text = "AD-HOC %s (%d)" % [normalized_order_type.to_upper(), issued_count]
	_refresh_order_visuals()
	_refresh_ad_hoc_panel_visibility()
	_update_ui()
	_emit_planning_state_changed()
	return true


func return_selected_fireteams_to_plan() -> bool:
	_ensure_ad_hoc_order_controller()
	var returned: int = 0
	for fireteam_id in _selected_fireteam_ids:
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		if _return_fireteam_to_plan(normalized_fireteam_id, true):
			returned += 1
	if returned <= 0:
		return false
	_last_command_text = "RETURN TO PLAN (%d)" % returned
	_refresh_order_visuals()
	_refresh_ad_hoc_panel_visibility()
	_update_ui()
	_emit_planning_state_changed()
	return true


func set_planning_state(planning_state: Dictionary) -> void:
	_last_planning_state_issue = _get_unsupported_planning_state_issue(planning_state)
	if not _last_planning_state_issue.is_empty():
		_last_command_text = "ALTE PLANUNGSDATEN"
		push_warning("TacticalInputController: %s" % _last_planning_state_issue)
		_update_ui()
		return
	var preserve_live_execution: bool = _should_preserve_live_execution_during_planning_sync(planning_state)
	_ensure_tactical_stance_controller()
	if planning_state.has("approach_angle"):
		var approach_angle: String = String(planning_state.get("approach_angle", "NW")).strip_edges().to_upper()
		var angle_index: int = APPROACH_ANGLES.find(approach_angle)
		if angle_index != -1:
			_current_approach_index = angle_index
	if planning_state.has("has_lz_position"):
		_has_lz_position = bool(planning_state.get("has_lz_position", false))
	if planning_state.has("lz_position"):
		var next_position = planning_state.get("lz_position", Vector2.ZERO)
		if typeof(next_position) == TYPE_VECTOR2:
			_lz_position = next_position
	if planning_state.has("drop_ship_requested"):
		_drop_ship_requested = bool(planning_state.get("drop_ship_requested", false))
	if planning_state.has("drop_ship_staged"):
		_drop_ship_staged = bool(planning_state.get("drop_ship_staged", false))
	if planning_state.has("mission_drop_craft_id"):
		_mission_drop_craft_id = String(planning_state.get("mission_drop_craft_id", "")).strip_edges()
	if planning_state.has("mission_drop_display_name"):
		_mission_drop_display_name = String(planning_state.get("mission_drop_display_name", "")).strip_edges()
	if planning_state.has("mission_drop_title_text"):
		_mission_drop_title_text = String(planning_state.get("mission_drop_title_text", "")).strip_edges()
	if planning_state.has("mission_drop_texture_path"):
		_mission_drop_texture_path = String(planning_state.get("mission_drop_texture_path", "")).strip_edges()
	if planning_state.has("mission_drop_state"):
		_mission_drop_state = String(planning_state.get("mission_drop_state", "")).strip_edges().to_lower()
	if planning_state.has("mission_drop_pilot_text"):
		_mission_drop_pilot_text = String(planning_state.get("mission_drop_pilot_text", "")).strip_edges()
	if planning_state.has("mission_drop_status_line"):
		_mission_drop_status_line = String(planning_state.get("mission_drop_status_line", "")).strip_edges()
	if planning_state.has("mission_drop_progress"):
		_mission_drop_progress = clampf(float(planning_state.get("mission_drop_progress", 0.0)), 0.0, 100.0)
	if planning_state.has("mission_drop_eta_seconds"):
		_mission_drop_eta_seconds = maxi(int(planning_state.get("mission_drop_eta_seconds", 0)), 0)
	if planning_state.has("mission_drop_pilot_unit_id"):
		_mission_drop_pilot_unit_id = String(planning_state.get("mission_drop_pilot_unit_id", "")).strip_edges()
	if planning_state.has("mission_drop_pilot_display_name"):
		_mission_drop_pilot_display_name = String(planning_state.get("mission_drop_pilot_display_name", "")).strip_edges()
	if planning_state.has("mission_drop_pilot_portrait_path"):
		_mission_drop_pilot_portrait_path = String(planning_state.get("mission_drop_pilot_portrait_path", "")).strip_edges()
	if planning_state.has("mission_drop_passenger_count"):
		_mission_drop_passenger_count = maxi(int(planning_state.get("mission_drop_passenger_count", 0)), 0)
	if planning_state.has("mission_drop_return_requested"):
		_mission_drop_return_requested = bool(planning_state.get("mission_drop_return_requested", false))
	if planning_state.has("meta_transfer_routes"):
		_meta_transfer_routes = _sanitize_meta_transfer_routes(Array(planning_state.get("meta_transfer_routes", [])))
	if planning_state.has("embarked_unit_ids"):
		_embarked_unit_ids = _build_drop_unit_state_dict(Array(planning_state.get("embarked_unit_ids", [])))
	if planning_state.has("deployed_unit_ids"):
		_deployed_unit_ids = _build_drop_unit_state_dict(Array(planning_state.get("deployed_unit_ids", [])))
	if planning_state.has("selected_fireteam"):
		_select_fireteam_by_name(String(planning_state.get("selected_fireteam", _get_fireteam_name())), false)
	if planning_state.has("selected_fireteams"):
		_set_selected_fireteams(_sanitize_fireteam_ids(PackedStringArray(Array(planning_state.get("selected_fireteams", [])))), false)
	if planning_state.has("tactical_stance_sync") and _tactical_stance_controller != null:
		_tactical_stance_controller.call("load_sync_state", Dictionary(planning_state.get("tactical_stance_sync", {})), _get_available_fireteam_ids())
	elif planning_state.has("tactical_stances") and _tactical_stance_controller != null:
		_tactical_stance_controller.call("load_stance_snapshot", Dictionary(planning_state.get("tactical_stances", {})), _get_available_fireteam_ids())
	if planning_state.has("order_plans"):
		_load_order_plans_from_state(Array(planning_state.get("order_plans", [])))
	if planning_state.has("area_orders"):
		_load_area_orders_from_state(Array(planning_state.get("area_orders", [])))
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("load_from_planning_state"):
		phase_controller.call("load_from_planning_state", planning_state, _get_max_order_plan_phase(), false)
	_sync_phase_selection_from_controller()
	if not preserve_live_execution:
		_phase_execution_by_fireteam.clear()
		_ad_hoc_execution_by_fireteam.clear()
		_ad_hoc_resume_state_by_fireteam.clear()
		_area_defense_execution_by_fireteam.clear()
		_area_attack_execution_by_fireteam.clear()
		_active_coordination_by_id.clear()
		_initialize_fireteam_suppression_state()
	_refresh_button_state()
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_world_overlays()
	_apply_drop_presence_state_to_units()
	_update_ui()
	_maybe_bootstrap_live_drop()


func _should_preserve_live_execution_during_planning_sync(planning_state: Dictionary) -> bool:
	if preview_mode:
		return false
	if _phase_execution_by_fireteam.is_empty() and _ad_hoc_execution_by_fireteam.is_empty():
		return false
	if not planning_state.has("order_plans"):
		return false
	var current_order_plans_text: String = JSON.stringify(_serialize_order_plans())
	var incoming_order_plans_text: String = JSON.stringify(Array(planning_state.get("order_plans", [])))
	if current_order_plans_text != incoming_order_plans_text:
		return false
	var phase_controller = _get_phase_controller()
	if PHASE_PLANNING_ENABLED and phase_controller != null and planning_state.has("active_phase_index") and phase_controller.has_method("get_active_phase_index"):
		if int(planning_state.get("active_phase_index", -999)) != int(phase_controller.call("get_active_phase_index")):
			return false
	return true


func get_planning_state() -> Dictionary:
	_ensure_tactical_stance_controller()
	var planning_state: Dictionary = {
		"has_lz_position": _has_lz_position,
		"lz_position": _lz_position,
		"approach_angle": _get_approach_angle_name(),
		"drop_ship_requested": _drop_ship_requested,
		"drop_ship_staged": _drop_ship_staged,
		"mission_drop_craft_id": _mission_drop_craft_id,
		"mission_drop_display_name": _mission_drop_display_name,
		"mission_drop_title_text": _mission_drop_title_text,
		"mission_drop_texture_path": _mission_drop_texture_path,
		"mission_drop_state": _mission_drop_state,
		"mission_drop_pilot_text": _mission_drop_pilot_text,
		"mission_drop_status_line": _mission_drop_status_line,
		"mission_drop_progress": _mission_drop_progress,
		"mission_drop_eta_seconds": _mission_drop_eta_seconds,
		"mission_drop_pilot_unit_id": _mission_drop_pilot_unit_id,
		"mission_drop_pilot_display_name": _mission_drop_pilot_display_name,
		"mission_drop_pilot_portrait_path": _mission_drop_pilot_portrait_path,
		"mission_drop_passenger_count": _mission_drop_passenger_count,
		"mission_drop_return_requested": _mission_drop_return_requested,
		"meta_transfer_routes": _serialize_meta_transfer_routes(),
		"embarked_unit_ids": _build_sorted_drop_unit_id_array(_embarked_unit_ids),
		"deployed_unit_ids": _build_sorted_drop_unit_id_array(_deployed_unit_ids),
		"selected_fireteam": _get_fireteam_name(),
		"selected_fireteams": Array(_selected_fireteam_ids),
		"selected_phase": _get_phase_name(),
		"order_plans": _serialize_order_plans(),
		"area_orders": _serialize_area_orders(),
	}
	if _tactical_stance_controller != null:
		planning_state["tactical_stances"] = Dictionary(_tactical_stance_controller.call("get_stance_snapshot"))
		planning_state["tactical_stance_sync"] = Dictionary(_tactical_stance_controller.call("get_sync_state"))
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("build_planning_state_fragment"):
		planning_state.merge(Dictionary(phase_controller.call("build_planning_state_fragment")), true)
	return planning_state


func has_pending_friendly_insertions() -> bool:
	return not _embarked_unit_ids.is_empty()


func add_global_phase() -> int:
	if not PHASE_PLANNING_ENABLED:
		_current_phase_index = _get_live_order_phase_index()
		_last_command_text = "DIREKTMODUS: PHASEN AUS"
		_update_ui()
		return _current_phase_index
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("add_phase"):
		return -1
	var next_phase_index: int = int(phase_controller.call("add_phase"))
	_current_phase_index = int(phase_controller.call("set_selected_phase_index", next_phase_index))
	_last_command_text = "PHASE %s ADDED" % _get_phase_name()
	_refresh_button_state()
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()
	return next_phase_index


func advance_to_next_phase() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return false
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("advance_to_next_phase"):
		return false
	var next_phase_index: int = int(phase_controller.call("advance_to_next_phase"))
	if next_phase_index < 0:
		_last_command_text = "NO NEXT PHASE"
		_update_ui()
		return false
	_reset_tactical_stances_for_new_phase()
	_start_active_phase_execution(next_phase_index)
	_refresh_button_state()
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()
	return true


func execute_selected_fireteam_orders() -> bool:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return false
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return false
	if _selected_fireteam_ids.is_empty():
		_last_command_text = "NO FIRETEAM SELECTED"
		_update_ui()
		return false
	var inactive_fireteams: PackedStringArray = []
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not _is_fireteam_runtime_active(fireteam_id):
			inactive_fireteams.append(fireteam_id.to_upper())
	if not inactive_fireteams.is_empty():
		_last_command_text = "WAIT FOR INSERTION: %s" % ", ".join(inactive_fireteams)
		_update_ui()
		return false
	var target_phase_index: int = _get_live_order_phase_index()
	var issued_fireteams: PackedStringArray = []
	var already_active_fireteams: PackedStringArray = []
	var continued_fireteams: PackedStringArray = []
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if _area_defense_execution_by_fireteam.has(fireteam_id):
			if _try_continue_active_area_defense(fireteam_id):
				if not _has_pending_waypoint_order(fireteam_id, target_phase_index):
					continued_fireteams.append(fireteam_id.to_upper())
					continue
			else:
				already_active_fireteams.append(fireteam_id.to_upper())
				continue
		if _area_attack_execution_by_fireteam.has(fireteam_id):
			if _try_continue_active_area_attack(fireteam_id):
				if not _has_pending_waypoint_order(fireteam_id, target_phase_index):
					continued_fireteams.append(fireteam_id.to_upper())
					continue
			else:
				already_active_fireteams.append(fireteam_id.to_upper())
				continue
		if _phase_execution_by_fireteam.has(fireteam_id):
			if _try_continue_active_fireteam_order(fireteam_id):
				continued_fireteams.append(fireteam_id.to_upper())
				continue
			already_active_fireteams.append(fireteam_id.to_upper())
			continue
		var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, target_phase_index), null)
		if plan == null or plan.waypoints.is_empty():
			if _activate_next_defend_area_order(fireteam_id, target_phase_index):
				issued_fireteams.append(fireteam_id.to_upper())
				continue
			if _activate_next_attack_area_order(fireteam_id, target_phase_index):
				issued_fireteams.append(fireteam_id.to_upper())
				continue
			if _apply_default_fireteam_behavior(fireteam_id, target_phase_index):
				issued_fireteams.append(fireteam_id.to_upper())
			continue
		var next_waypoint_index: int = _find_next_executable_waypoint_index(plan)
		if next_waypoint_index < 0:
			if _activate_next_defend_area_order(fireteam_id, target_phase_index):
				issued_fireteams.append(fireteam_id.to_upper())
				continue
			if _activate_next_attack_area_order(fireteam_id, target_phase_index):
				issued_fireteams.append(fireteam_id.to_upper())
			continue
		_reset_non_completed_waypoints_for_resume(plan)
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		if _activate_next_waypoint_for_plan(plan, fireteam_id, next_waypoint_index):
			issued_fireteams.append(fireteam_id.to_upper())
	if issued_fireteams.is_empty() and already_active_fireteams.is_empty() and continued_fireteams.is_empty():
		_last_command_text = "NO ORDERS TO EXECUTE"
		_update_ui()
		return false
	if not issued_fireteams.is_empty():
		_apply_fireteam_coordination_for_phase(target_phase_index)
	var go_bits: PackedStringArray = []
	if not issued_fireteams.is_empty():
		go_bits.append("GO %s" % ", ".join(issued_fireteams))
	if not continued_fireteams.is_empty():
		go_bits.append("NEXT %s" % ", ".join(continued_fireteams))
	if not already_active_fireteams.is_empty():
		go_bits.append("ACTIVE %s" % ", ".join(already_active_fireteams))
	_last_command_text = " | ".join(go_bits)
	_refresh_button_state()
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()
	return true


func get_phase_state_snapshot() -> Dictionary:
	var phase_controller = _get_phase_controller()
	if phase_controller == null:
		return {}
	return {
		"selected_phase_index": int(phase_controller.call("get_selected_phase_index")),
		"active_phase_index": int(phase_controller.call("get_active_phase_index")),
		"phase_count": int(phase_controller.call("get_phase_count")),
		"phase_states": Array(phase_controller.call("get_phase_states_snapshot")),
	}


func get_last_planning_state_issue() -> String:
	return _last_planning_state_issue


func get_active_behavior_profile(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _active_behavior_profiles_by_fireteam.has(normalized_fireteam_id):
		return {}
	var profile = _active_behavior_profiles_by_fireteam[normalized_fireteam_id]
	if profile == null:
		return {}
	if profile.has_method("to_dict"):
		return profile.to_dict()
	if typeof(profile) == TYPE_DICTIONARY:
		return Dictionary(profile).duplicate(true)
	return {}


func get_requested_tactical_stance(fireteam_id: String) -> String:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null:
		return "normal"
	return String(_tactical_stance_controller.call("get_requested_stance", fireteam_id))


func get_fireteam_movement_state(fireteam_id: String) -> Dictionary:
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller == null:
		return {}
	return Dictionary(_fireteam_movement_controller.call("get_fireteam_state", fireteam_id)).duplicate(true)


func get_fireteam_security_state(fireteam_id: String) -> Dictionary:
	_ensure_fireteam_security_controller()
	if _fireteam_security_controller == null:
		return {}
	return Dictionary(_fireteam_security_controller.call("get_fireteam_state", fireteam_id)).duplicate(true)


func get_contact_snapshot() -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_contact_snapshot"):
		return []
	return Array(combat_driver.call("get_contact_snapshot")).duplicate(true)


func get_fireteam_contact_snapshot(fireteam_id: String) -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_fireteam_contact_snapshot"):
		return []
	return Array(combat_driver.call("get_fireteam_contact_snapshot", fireteam_id)).duplicate(true)


func get_flank_vulnerability_snapshot() -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_flank_vulnerability_snapshot"):
		return []
	return Array(combat_driver.call("get_flank_vulnerability_snapshot")).duplicate(true)


func get_terrain_move_debug_snapshot(unit_id: String = "") -> Variant:
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null or not simulation_root.has_method("get_terrain_move_debug_snapshot"):
		return [] if unit_id.strip_edges().is_empty() else {}
	return simulation_root.call("get_terrain_move_debug_snapshot", unit_id)


func set_terrain_move_debug_enabled(enabled: bool) -> void:
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_terrain_move_debug_enabled"):
		simulation_root.call("set_terrain_move_debug_enabled", enabled)


func build_terrain_move_debug_text(unit_id: String) -> String:
	var snapshot: Dictionary = Dictionary(get_terrain_move_debug_snapshot(unit_id))
	if snapshot.is_empty():
		return "MOVE DEBUG -"
	var original_grid: Vector2i = Vector2i(snapshot.get("original_target_grid", Vector2i.ZERO))
	var replacement_grid: Variant = snapshot.get("replacement_target_grid", null)
	var final_grid: Vector2i = Vector2i(snapshot.get("final_waypoint_grid", Vector2i.ZERO))
	var reason: String = String(snapshot.get("blocker_reason", "")).strip_edges()
	if reason.is_empty():
		reason = "walkable"
	var replacement_text: String = "--"
	if typeof(replacement_grid) == TYPE_VECTOR2I:
		var replacement_grid_value: Vector2i = replacement_grid
		replacement_text = "%d,%d" % [replacement_grid_value.x, replacement_grid_value.y]
	return "MOVE DEBUG | Ziel %d,%d | Ersatz %s | Final %d,%d | Grund %s" % [
		original_grid.x,
		original_grid.y,
		replacement_text,
		final_grid.x,
		final_grid.y,
		reason,
	]


func get_fireteam_flank_vulnerability_state(fireteam_id: String) -> Dictionary:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_fireteam_flank_vulnerability_state"):
		return {}
	return Dictionary(combat_driver.call("get_fireteam_flank_vulnerability_state", fireteam_id)).duplicate(true)


func get_tactical_stances_snapshot() -> Dictionary:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null:
		return {}
	return Dictionary(_tactical_stance_controller.call("get_stance_snapshot")).duplicate(true)


func get_tactical_stance_sync_state() -> Dictionary:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null:
		return {}
	return Dictionary(_tactical_stance_controller.call("get_sync_state")).duplicate(true)


func apply_tactical_stance_sync_state(sync_state: Dictionary, should_emit_signal: bool = false) -> void:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null:
		return
	_tactical_stance_controller.call("load_sync_state", sync_state, _get_available_fireteam_ids())
	_refresh_tactical_stance_panel()
	_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()


func set_selected_fireteams_tactical_stance(next_stance: String) -> bool:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null or _selected_fireteam_ids.is_empty():
		return false
	var applied_count: int = int(_tactical_stance_controller.call("apply_to_fireteams", _selected_fireteam_ids, next_stance))
	if applied_count <= 0:
		return false
	for fireteam_id_variant in _selected_fireteam_ids:
		_refresh_active_behavior_profile_for_fireteam(String(fireteam_id_variant))
	var first_stance: String = String(_tactical_stance_controller.call("get_requested_stance", String(_selected_fireteam_ids[0])))
	_last_command_text = "STANCE %s (%d)" % [_get_tactical_stance_short_label(first_stance), applied_count]
	_refresh_button_state()
	_update_ui()
	_emit_planning_state_changed()
	return true


func get_active_behavior_profiles_snapshot() -> Array:
	var result: Array = []
	var fireteam_ids: Array = _active_behavior_profiles_by_fireteam.keys()
	fireteam_ids.sort()
	for fireteam_id in fireteam_ids:
		var profile_dict: Dictionary = get_active_behavior_profile(String(fireteam_id))
		if profile_dict.is_empty():
			continue
		result.append(profile_dict)
	return result


func get_fireteam_movement_snapshot() -> Array:
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller == null:
		return []
	return Array(_fireteam_movement_controller.call("get_state_snapshot")).duplicate(true)


func get_active_area_defense_snapshot() -> Array:
	var result: Array = []
	var fireteam_ids: Array = _area_defense_execution_by_fireteam.keys()
	fireteam_ids.sort()
	for fireteam_id_variant in fireteam_ids:
		var state: Dictionary = Dictionary(_area_defense_execution_by_fireteam.get(fireteam_id_variant, {})).duplicate(true)
		if state.is_empty():
			continue
		result.append(state)
	return result


func get_active_area_attack_snapshot() -> Array:
	var result: Array = []
	var fireteam_ids: Array = _area_attack_execution_by_fireteam.keys()
	fireteam_ids.sort()
	for fireteam_id_variant in fireteam_ids:
		var state: Dictionary = Dictionary(_area_attack_execution_by_fireteam.get(fireteam_id_variant, {})).duplicate(true)
		if state.is_empty():
			continue
		result.append(state)
	return result


func get_fireteam_attack_area_context(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var state: Dictionary = Dictionary(_area_attack_execution_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	if state.is_empty():
		return {}
	return Dictionary(state.get("target_area", {})).duplicate(true)


func get_fireteam_security_snapshot() -> Array:
	_ensure_fireteam_security_controller()
	if _fireteam_security_controller == null:
		return []
	return Array(_fireteam_security_controller.call("get_state_snapshot")).duplicate(true)


func refresh_fireteam_security_state() -> bool:
	_ensure_fireteam_security_controller()
	if _fireteam_security_controller == null:
		return false
	var previous_snapshot_text: String = JSON.stringify(get_fireteam_security_snapshot())
	for fireteam_id_variant in _get_available_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant)
		var behavior_profile_dict: Dictionary = get_active_behavior_profile(fireteam_id)
		if not _is_fireteam_runtime_active(fireteam_id) or behavior_profile_dict.is_empty():
			_fireteam_security_controller.call("reset_fireteam", fireteam_id)
			continue
		_fireteam_security_controller.call(
			"update_fireteam_state",
			fireteam_id,
			_get_fireteam_units(fireteam_id, true),
			_resolve_fireteam_leader_for_behavior(fireteam_id),
			behavior_profile_dict,
			get_fireteam_movement_state(fireteam_id),
			Dictionary(_suppression_state_by_fireteam.get(fireteam_id, {})).duplicate(true),
			Dictionary(_ad_hoc_order_controller.call("get_active_order", fireteam_id)) if _ad_hoc_order_controller != null else {},
			get_fireteam_contact_snapshot(fireteam_id),
			_get_area_execution_security_context(fireteam_id)
		)
	var next_snapshot_text: String = JSON.stringify(get_fireteam_security_snapshot())
	if previous_snapshot_text == next_snapshot_text:
		return false
	_refresh_order_visuals()
	_refresh_fireteam_status_panel()
	return true


func get_current_fireteam_lead_unit(fireteam_id: String):
	return _resolve_fireteam_leader_for_behavior(fireteam_id)


func get_fireteam_suppression_snapshot(fireteam_id: String = "") -> Dictionary:
	if fireteam_id.strip_edges().is_empty():
		var aggregated: Dictionary = {}
		for known_fireteam_id in _suppression_state_by_fireteam.keys():
			aggregated[String(known_fireteam_id)] = Dictionary(_suppression_state_by_fireteam[known_fireteam_id]).duplicate(true)
		return aggregated
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	return Dictionary(_suppression_state_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)


func try_place_target_from_screen_position(screen_position: Vector2) -> bool:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return false

	var world_position: Vector2 = _screen_to_world_position(screen_position)
	var clamped_position: Vector2 = _clamp_world_position_to_viewport(world_position)
	target_marker.global_position = clamped_position
	_last_target_position = clamped_position
	_last_command_text = "TARGET SET @ %s" % _format_world_position(clamped_position)
	_update_ui()
	return true


func _place_lz_from_screen_position(screen_position: Vector2) -> bool:
	var world_position: Vector2 = _screen_to_world_position(screen_position)
	_lz_position = _snap_world_position_to_primary_tile(_clamp_world_position_to_viewport(world_position))
	_has_lz_position = true
	_is_lz_placement_armed = false
	_last_command_text = "LZ SET %s @ %s" % [_get_approach_angle_name(), _format_world_position(_lz_position)]
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _issue_command(command_type: String, display_text: String) -> bool:
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return false

	if _selected_fireteam_ids.is_empty():
		_last_command_text = "NO FIRETEAM SELECTED"
		_update_ui()
		return false
	var inactive_fireteams: PackedStringArray = []
	for fireteam_id in _selected_fireteam_ids:
		if not _is_fireteam_runtime_active(String(fireteam_id)):
			inactive_fireteams.append(String(fireteam_id).to_upper())
	if not inactive_fireteams.is_empty():
		_last_command_text = "WAIT FOR INSERTION: %s" % ", ".join(inactive_fireteams)
		_update_ui()
		return false

	var issued_count: int = 0
	for driver in _get_active_flow_drivers():
		if driver == null or not driver.has_method("issue_command"):
			continue

		if bool(driver.call("issue_command", command_type, _get_live_order_phase_index())):
			issued_count += 1

	if issued_count == 0:
		_last_command_text = "%s FAILED" % display_text
		_update_ui()
		return false

	_last_command_text = "%s (%s)" % [display_text, _get_fireteam_name()]
	_update_ui()
	return true


func _change_fireteam(delta: int) -> void:
	var selection_options: Array = _get_fireteam_selection_options()
	if selection_options.is_empty():
		return
	var next_index: int = wrapi(_current_fireteam_index + delta, 0, selection_options.size())
	_set_selected_fireteams(_selection_ids_for_index(next_index))


func _change_phase(delta: int) -> void:
	if not PHASE_PLANNING_ENABLED:
		_current_phase_index = _get_live_order_phase_index()
		_last_command_text = "DIREKTMODUS: PHASEN AUS"
		_update_ui()
		return
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("cycle_selected_phase"):
		_current_phase_index = maxi(_current_phase_index + delta, 1)
	else:
		_current_phase_index = int(phase_controller.call("cycle_selected_phase", delta))
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()


func _select_fireteam_by_name(fireteam_name: String, should_emit_signal: bool = true) -> void:
	var next_index: int = _find_fireteam_selection_index_by_name(fireteam_name)
	if next_index == -1:
		return
	_set_selected_fireteams(_selection_ids_for_index(next_index), should_emit_signal)


func _select_approach_angle(angle_name: String) -> void:
	var normalized_name: String = angle_name.strip_edges().to_upper()
	var next_index: int = APPROACH_ANGLES.find(normalized_name)
	if next_index == -1:
		return
	_current_approach_index = next_index
	_last_command_text = "APPROACH %s" % normalized_name
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()


func _on_homebase_nav_pressed() -> void:
	_navigate_to_meta_view("homebase")


func _on_fob_nav_pressed() -> void:
	_navigate_to_meta_view("fob")


func _on_mission_nav_pressed() -> void:
	_navigate_to_meta_view("mission")


func _on_all_fireteam_pressed() -> void:
	_select_fireteam_by_name(ALL_FIRETEAM_LABEL)


func _on_fireteam_group_pressed(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	_set_selected_fireteams(PackedStringArray([normalized_fireteam_id]))


func _on_target_button_pressed() -> void:
	_is_lz_placement_armed = false
	_is_target_placement_armed = not _is_target_placement_armed
	_last_command_text = "CLICK MAP FOR TARGET" if _is_target_placement_armed else "TARGET PLACEMENT CANCELLED"
	_update_ui()


func _on_previous_edit_phase_pressed() -> void:
	if not PHASE_PLANNING_ENABLED:
		_last_command_text = "DIREKTMODUS: PHASEN AUS"
		_update_ui()
		return
	_change_phase(-1)


func _on_add_phase_pressed() -> void:
	if not PHASE_PLANNING_ENABLED:
		_last_command_text = "DIREKTMODUS: PHASEN AUS"
		_update_ui()
		return
	add_global_phase()


func _on_next_edit_phase_pressed() -> void:
	if not PHASE_PLANNING_ENABLED:
		_last_command_text = "DIREKTMODUS: PHASEN AUS"
		_update_ui()
		return
	_change_phase(1)


func _on_next_phase_pressed() -> void:
	if not PHASE_PLANNING_ENABLED:
		execute_selected_fireteam_orders()
		return
	advance_to_next_phase()


func _on_go_phase_pressed() -> void:
	execute_selected_fireteam_orders()


func _on_clear_target_pressed() -> void:
	_snap_target_to_objective()
	_last_command_text = "TARGET RESET TO OBJECTIVE"
	_update_ui()


func _on_set_lz_pressed() -> void:
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	_is_lz_placement_armed = not _is_lz_placement_armed
	_last_command_text = "CLICK MAP FOR LZ" if _is_lz_placement_armed else "LZ PLACEMENT CANCELLED"
	_update_ui()


func _on_call_dropship_pressed() -> void:
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	if not _is_mission_drop_available():
		_last_command_text = "DROP SHIP NOT ON MISSION MAP"
		_update_ui()
		return
	if not preview_mode and _drop_ship_cooldown_remaining > 0.0:
		_last_command_text = "DROP COOLDOWN %.1FS" % _drop_ship_cooldown_remaining
		_update_ui()
		return
	if not _has_lz_position:
		_last_command_text = "SET LZ BEFORE DROP CALL"
		_update_ui()
		return
	_drop_ship_staged = true
	_mission_drop_return_requested = false
	if preview_mode:
		_drop_ship_requested = true
		if _try_start_drop_sequence():
			_last_command_text = "DROP INBOUND %s" % _get_approach_angle_name()
		else:
			_last_command_text = "DROP %s" % _get_approach_angle_name()
	elif _is_drop_sequence_active():
		_last_command_text = "DROP ALREADY ACTIVE"
	elif _try_start_drop_sequence():
		_drop_ship_requested = true
		_last_command_text = "DROP INBOUND %s" % _get_approach_angle_name()
	else:
		_drop_ship_requested = false
		_last_command_text = "NO DROP TEAM AVAILABLE"
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()


func _on_approach_nw_pressed() -> void:
	_select_approach_angle("NW")


func _on_approach_ne_pressed() -> void:
	_select_approach_angle("NE")


func _on_approach_sw_pressed() -> void:
	_select_approach_angle("SW")


func _on_approach_se_pressed() -> void:
	_select_approach_angle("SE")


func _navigate_to_meta_view(target_view: String) -> void:
	var mission_root: Node = get_parent()
	if mission_root == null:
		_last_command_text = "META NAV UNAVAILABLE"
		_update_ui()
		return

	var mission_host: Node = mission_root.get_parent()
	if mission_host == null:
		_last_command_text = "META NAV UNAVAILABLE"
		_update_ui()
		return

	var meta_root: Node = mission_host.get_parent()
	if meta_root == null:
		_last_command_text = "META NAV UNAVAILABLE"
		_update_ui()
		return

	match target_view:
		"homebase":
			if meta_root.has_method("_show_homebase"):
				meta_root.call("_show_homebase")
				return
		"fob":
			if meta_root.has_method("_show_fob"):
				meta_root.call("_show_fob")
				return
		"mission":
			if meta_root.has_method("_show_mission"):
				meta_root.call("_show_mission")
				return

	_last_command_text = "META NAV UNAVAILABLE"
	_update_ui()


func _get_active_flow_drivers() -> Array:
	return _get_flow_drivers_for_fireteams(_selected_fireteam_ids)


func _get_flow_drivers_for_fireteam(fireteam_id: String) -> Array:
	return _get_flow_drivers_for_fireteams(PackedStringArray([fireteam_id.strip_edges().to_lower()]))


func _get_flow_drivers_for_fireteams(fireteam_ids: PackedStringArray) -> Array:
	var alpha_driver = get_node_or_null(alpha_flow_driver_path)
	var bravo_driver = get_node_or_null(bravo_flow_driver_path)
	var charlie_driver = get_node_or_null(charlie_flow_driver_path)
	var drivers: Array = []
	for driver in [alpha_driver, bravo_driver, charlie_driver]:
		if driver == null:
			continue
		var driver_fireteam_id: String = _get_fireteam_id_for_flow_driver(driver)
		if driver_fireteam_id.is_empty() or not fireteam_ids.has(driver_fireteam_id):
			continue
		drivers.append(driver)
	var active_drivers: Array = []
	for driver in drivers:
		if driver == null:
			continue
		if _is_flow_driver_runtime_active(driver):
			active_drivers.append(driver)
	return active_drivers


func _get_fireteam_id_for_flow_driver(driver: Node) -> String:
	if driver == null or not driver.has_method("get"):
		return ""
	var unit_id: String = String(driver.get("unit_id")).strip_edges()
	if unit_id.is_empty():
		return ""
	var unit = _find_friendly_unit_by_id(unit_id)
	if unit == null or not unit.has_method("get_fireteam_id"):
		return ""
	return String(unit.call("get_fireteam_id")).strip_edges().to_lower()


func _is_flow_driver_runtime_active(driver: Node) -> bool:
	if driver == null or not driver.has_method("get"):
		return false
	var unit_id: String = String(driver.get("unit_id")).strip_edges()
	if unit_id.is_empty():
		return true
	if _deployed_unit_ids.has(unit_id):
		return true
	var unit_registry = get_node_or_null("../UnitRegistry")
	if unit_registry == null:
		return false
	if unit_registry.has_method("has_unit"):
		return bool(unit_registry.call("has_unit", unit_id))
	if unit_registry.has_method("get_unit"):
		return unit_registry.call("get_unit", unit_id) != null
	return false


func _get_fireteam_name() -> String:
	if _selected_fireteam_ids.is_empty():
		return "NONE"
	if _is_all_fireteams_selected():
		return ALL_FIRETEAM_LABEL
	if _selected_fireteam_ids.size() == 1:
		return _get_fireteam_display_label(String(_selected_fireteam_ids[0]))
	var labels: PackedStringArray = []
	for fireteam_id in _selected_fireteam_ids:
		labels.append(_get_fireteam_display_label(String(fireteam_id)))
	return " + ".join(labels)


func _get_fireteam_display_label(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return "UNASSIGNED"
	var definition: Dictionary = _get_mission_fireteam_definition(normalized_fireteam_id)
	var label_text: String = String(definition.get("label", "")).strip_edges()
	if label_text.is_empty():
		label_text = String(definition.get("display_name", "")).strip_edges()
	if not label_text.is_empty():
		return label_text.to_upper()
	return CHARACTER_SHEET_FORMATTER_SCRIPT.format_fireteam_label(normalized_fireteam_id)


func _get_mission_fireteam_definition(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup == null:
		return {}
	var definitions_variant = mission_setup.get("selected_fireteam_definitions")
	if typeof(definitions_variant) != TYPE_ARRAY:
		return {}
	for definition_variant in Array(definitions_variant):
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		if String(definition.get("id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return definition.duplicate(true)
	return {}


func _get_phase_name() -> String:
	if not PHASE_PLANNING_ENABLED:
		return "LIVE"
	var phase_controller = _get_phase_controller()
	if phase_controller != null and phase_controller.has_method("get_selected_phase_name"):
		return String(phase_controller.call("get_selected_phase_name"))
	return "P%d" % maxi(_current_phase_index, 1)


func _get_approach_angle_name() -> String:
	return APPROACH_ANGLES[_current_approach_index]


func set_tactical_ui_visible(is_visible: bool) -> void:
	_tactical_ui_visible = is_visible
	for path in [
		"../TacticalUI/MissionTint",
		"../TacticalUI/MissionIdentityPanel",
		"../TacticalUI/MissionDropshipPanel",
		"../TacticalUI/TopNavPanel",
		FIRETEAM_MINI_PANEL_PATH,
		"../TacticalUI/BottomDock",
	]:
		var canvas_item := get_node_or_null(path) as CanvasItem
		if canvas_item != null:
			canvas_item.visible = is_visible
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay != null:
		overlay.visible = is_visible and _character_overlay_open


func _update_ui() -> void:
	_apply_block_labels()
	_sync_unit_tactical_stance_badges()
	var command_feedback_label := get_node_or_null(command_feedback_label_path) as Label
	if command_feedback_label != null:
		if not _last_planning_state_issue.is_empty():
			command_feedback_label.text = "PLANUNG NICHT GELADEN\nAlte Planungsdaten erkannt.\nBitte Plan im aktuellen Phasensystem neu anlegen."
		else:
			command_feedback_label.text = "TEAM %s | PHASE %s\nTARGET %s\n%s\nLAST %s" % [
				_get_fireteam_name(),
				_get_phase_name(),
				_build_target_text(),
				_build_selected_waypoint_info_text(),
				_last_command_text,
			]

	var hotkey_legend_label := get_node_or_null(hotkey_legend_label_path) as Label
	if hotkey_legend_label != null:
		if preview_mode:
			hotkey_legend_label.text = "MISSION PREVIEW | Homebase Start unlocks GO/orders | RMB waypoints | DEL removes"
		else:
			hotkey_legend_label.text = HOTKEY_LEGEND if _can_issue_local_commands() else "OBSERVER MODE | Host controls mission orders in multiplayer V1"

	var fireteam_status_label := get_node_or_null(FIRETEAM_STATUS_LABEL_PATH) as Label
	if fireteam_status_label != null:
		fireteam_status_label.text = _build_fireteam_status_text()
	_refresh_fireteam_status_panel()
	_refresh_fireteam_phase_panel()
	_refresh_mission_nav_timer_label()
	_refresh_mission_dropship_panel()

	var strategic_status_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel") as Label
	if strategic_status_label != null:
		strategic_status_label.text = _build_strategic_status_text()

	var phase_status_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseStatusLabel") as Label
	if phase_status_label != null:
		phase_status_label.text = _build_phase_status_text()

	var phase_list_label := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseListLabel") as Label
	if phase_list_label != null:
		phase_list_label.text = _build_phase_list_text()

	var set_lz_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton") as Button
	if set_lz_button != null:
		set_lz_button.text = "Click Map..." if _is_lz_placement_armed else "Set LZ"

	var target_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton") as Button
	if target_button != null:
		target_button.text = "Click Map..." if _is_target_placement_armed else "Target"

	var call_dropship_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as Button
	if call_dropship_button != null:
		if not preview_mode and _drop_ship_cooldown_remaining > 0.0 and not _is_drop_sequence_active():
			call_dropship_button.text = "Cooldown %ds" % int(ceil(_drop_ship_cooldown_remaining))
		else:
			match _drop_sequence_phase:
				DROP_SEQUENCE_INBOUND:
					call_dropship_button.text = "Inbound"
				DROP_SEQUENCE_LANDED:
					call_dropship_button.text = "Landed"
				DROP_SEQUENCE_UNLOADING:
					call_dropship_button.text = "Deboarding"
				DROP_SEQUENCE_OUTBOUND:
					call_dropship_button.text = "Outbound"
				DROP_SEQUENCE_COMPLETE:
					call_dropship_button.text = "Drop Complete"
				_:
					call_dropship_button.text = "Drop"

	_apply_compact_mission_control_layout()
	_refresh_dynamic_button_styles()
	_refresh_world_overlays()
	_sync_primary_3d_mission_status_visuals()
	_suppress_legacy_2d_readability_overlays()
	_refresh_ad_hoc_panel_visibility()
	_refresh_selected_fireteam_cards()
	_refresh_fireteam_mini_cards()
	if _character_overlay_open:
		_update_character_overlay()
	if not _tactical_ui_visible:
		set_tactical_ui_visible(false)


func _ensure_ad_hoc_panel() -> Control:
	var existing_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/AdHocOrderPanel") as PanelContainer
	if existing_panel != null:
		return existing_panel
	var command_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control
	if command_panel == null:
		return null
	var panel := PanelContainer.new()
	panel.name = "AdHocOrderPanel"
	panel.anchor_right = 1.0
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.offset_right = -8.0
	panel.offset_bottom = 142.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.visible = false
	command_panel.add_child(panel)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "AdHocVBox"
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "AdHocTitleLabel"
	title.text = "Ad-Hoc Orders (Combat)"
	META_UI_SKIN_SCRIPT.style_header_label(title, 11)
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	vbox.add_child(row)
	for order_type in ["flank", "disengage", "fall_back", "focus_fire", "hold_till_last_man"]:
		var button := Button.new()
		button.text = order_type.to_upper()
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.set_meta("ad_hoc_order_type", order_type)
		if not button.pressed.is_connected(_on_ad_hoc_button_pressed.bind(button)):
			button.pressed.connect(_on_ad_hoc_button_pressed.bind(button))
		META_UI_SKIN_SCRIPT.style_tactical_button(button, false)
		row.add_child(button)
	var return_button := Button.new()
	return_button.name = "ReturnToPlanButton"
	return_button.text = "RETURN TO PLAN"
	if not return_button.pressed.is_connected(_on_return_to_plan_button_pressed):
		return_button.pressed.connect(_on_return_to_plan_button_pressed)
	META_UI_SKIN_SCRIPT.style_tactical_button(return_button, false)
	vbox.add_child(return_button)
	return panel


func _ensure_fireteam_status_panel() -> Control:
	var existing_panel := get_node_or_null("%s/FireteamStatusPanel" % FIRETEAM_INFO_VBOX_PATH) as PanelContainer
	if existing_panel != null:
		return existing_panel
	var fireteam_info_vbox := get_node_or_null(FIRETEAM_INFO_VBOX_PATH) as VBoxContainer
	if fireteam_info_vbox == null:
		return null
	var panel := TACTICAL_CARD_SCRIPT.new() as PanelContainer
	panel.name = "FireteamStatusPanel"
	fireteam_info_vbox.add_child(panel)
	fireteam_info_vbox.move_child(panel, 1)

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "HBoxContainer"
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var status_badge := STATUS_BADGE_SCRIPT.new() as Label
	status_badge.name = "SelectionStateBadge"
	row.add_child(status_badge)

	var status_label := Label.new()
	status_label.name = "SuppressionLabel"
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_body_label(status_label, 11)
	row.add_child(status_label)

	var suppression_progress := PROGRESS_LINE_SCRIPT.new() as Control
	suppression_progress.name = "SuppressionProgressLine"
	suppression_progress.custom_minimum_size = Vector2(92.0, 22.0)
	row.add_child(suppression_progress)

	var return_button := COMMAND_BUTTON_SCRIPT.new() as Button
	return_button.name = "ReturnToPlanButton"
	return_button.custom_minimum_size = Vector2(94.0, 22.0)
	return_button.call("configure", "Return to Plan", "return_to_plan", "Fuehrt das ausgewaehlte Fireteam zurueck in den geplanten Ablauf.", "command")
	if not return_button.pressed.is_connected(_on_return_to_plan_button_pressed):
		return_button.pressed.connect(_on_return_to_plan_button_pressed)
	row.add_child(return_button)
	return panel


func _ensure_tactical_stance_panel() -> Control:
	var existing_panel := get_node_or_null("%s/TacticalStancePanel" % FIRETEAM_INFO_VBOX_PATH) as PanelContainer
	if existing_panel != null:
		return existing_panel
	var fireteam_info_vbox := get_node_or_null(FIRETEAM_INFO_VBOX_PATH) as VBoxContainer
	if fireteam_info_vbox == null:
		return null
	var panel := PanelContainer.new()
	panel.name = "TacticalStancePanel"
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")
	fireteam_info_vbox.add_child(panel)
	fireteam_info_vbox.move_child(panel, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var summary_label := Label.new()
	summary_label.name = "SummaryLabel"
	META_UI_SKIN_SCRIPT.style_body_label(summary_label, 10)
	vbox.add_child(summary_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	vbox.add_child(row)
	for stance_id in ["cautious", "normal", "aggressive"]:
		var button := Button.new()
		button.name = "%sButton" % String(stance_id).capitalize()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, 22.0)
		button.add_theme_font_size_override("font_size", 8)
		button.text = _get_tactical_stance_button_text(stance_id)
		button.set_meta("tactical_stance_id", stance_id)
		if not button.pressed.is_connected(_on_tactical_stance_button_pressed.bind(button)):
			button.pressed.connect(_on_tactical_stance_button_pressed.bind(button))
		META_UI_SKIN_SCRIPT.style_tactical_button(button, false)
		row.add_child(button)
	return panel


func _ensure_fireteam_phase_panel() -> Control:
	var existing_panel := get_node_or_null("%s/FireteamPhasePanel" % FIRETEAM_INFO_VBOX_PATH) as PanelContainer
	if existing_panel != null:
		return existing_panel
	var fireteam_info_vbox := get_node_or_null(FIRETEAM_INFO_VBOX_PATH) as VBoxContainer
	if fireteam_info_vbox == null:
		return null
	var panel := PanelContainer.new()
	panel.name = "FireteamPhasePanel"
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")
	fireteam_info_vbox.add_child(panel)
	fireteam_info_vbox.move_child(panel, 2)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var status_label := Label.new()
	status_label.name = "PhaseStatusLabel"
	META_UI_SKIN_SCRIPT.style_body_label(status_label, 10)
	vbox.add_child(status_label)

	var list_label := Label.new()
	list_label.name = "PhaseListLabel"
	list_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(list_label, 9)
	vbox.add_child(list_label)

	var row := HBoxContainer.new()
	row.name = "PhaseActionRow"
	row.add_theme_constant_override("separation", 4)
	vbox.add_child(row)

	var button_specs: Array = [
		{"name": "PrevEditPhaseButton", "text": "< Edit", "callback": Callable(self, "_on_previous_edit_phase_pressed")},
		{"name": "AddPhaseButton", "text": "+P", "callback": Callable(self, "_on_add_phase_pressed")},
		{"name": "NextEditPhaseButton", "text": "Edit >", "callback": Callable(self, "_on_next_edit_phase_pressed")},
		{"name": "NextPhaseButton", "text": "Next", "callback": Callable(self, "_on_next_phase_pressed")},
		{"name": "GoPhaseButton", "text": "GO", "callback": Callable(self, "_on_go_phase_pressed"), "min_width": 64.0},
	]
	if not PHASE_PLANNING_ENABLED:
		button_specs = [
			{"name": "GoPhaseButton", "text": "GO", "callback": Callable(self, "_on_go_phase_pressed"), "min_width": 64.0},
		]
	for spec_variant in button_specs:
		var spec: Dictionary = Dictionary(spec_variant)
		var button := Button.new()
		var callback: Callable = spec.get("callback", Callable())
		button.name = String(spec.get("name", "")).strip_edges()
		button.text = String(spec.get("text", "")).strip_edges()
		button.custom_minimum_size = Vector2(float(spec.get("min_width", 52.0)), 22.0)
		button.add_theme_font_size_override("font_size", 8)
		if not button.pressed.is_connected(callback):
			button.pressed.connect(callback)
		META_UI_SKIN_SCRIPT.style_tactical_button(button, false)
		row.add_child(button)
	return panel


func _refresh_tactical_stance_panel() -> void:
	var panel := _ensure_tactical_stance_panel()
	if panel == null:
		return
	var summary_label := panel.get_node_or_null("MarginContainer/VBoxContainer/SummaryLabel") as Label
	var shared_stance: String = _get_shared_selected_tactical_stance()
	var summary_text: String = "STANCE N | no fireteams selected"
	if not _selected_fireteam_ids.is_empty():
		var selection_text: String = "%s selected" % _get_fireteam_name()
		if _selected_fireteam_ids.size() > 1 and not _is_all_fireteams_selected():
			selection_text = "%d fireteams selected" % _selected_fireteam_ids.size()
		elif _is_all_fireteams_selected():
			selection_text = "all fireteams selected"
		var stance_text: String = "STANCE MIXED"
		if not shared_stance.is_empty():
			stance_text = "STANCE %s" % _get_tactical_stance_short_label(shared_stance)
		summary_text = "%s | %s" % [stance_text, selection_text]
	if summary_label != null:
		summary_label.text = summary_text
	var button_row := panel.get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer") as HBoxContainer
	if button_row == null:
		return
	for child in button_row.get_children():
		var button := child as Button
		if button == null:
			continue
		var stance_id: String = String(button.get_meta("tactical_stance_id", "")).strip_edges().to_lower()
		META_UI_SKIN_SCRIPT.style_tactical_button(button, not shared_stance.is_empty() and stance_id == shared_stance)
		button.disabled = not _can_edit_planning() or _selected_fireteam_ids.is_empty()


func _refresh_fireteam_phase_panel() -> void:
	var legacy_phase_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel") as Control
	if legacy_phase_panel != null:
		legacy_phase_panel.visible = false
	var panel := _ensure_fireteam_phase_panel()
	if panel == null:
		return
	var status_label := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseStatusLabel") as Label
	if status_label != null:
		status_label.text = _build_phase_status_text()
	var list_label := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseListLabel") as Label
	if list_label != null:
		list_label.text = _build_phase_list_text()
	var prev_button := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseActionRow/PrevEditPhaseButton") as Button
	var add_button := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseActionRow/AddPhaseButton") as Button
	var next_edit_button := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseActionRow/NextEditPhaseButton") as Button
	var next_phase_button := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseActionRow/NextPhaseButton") as Button
	var go_phase_button := panel.get_node_or_null("MarginContainer/VBoxContainer/PhaseActionRow/GoPhaseButton") as Button
	for button in [prev_button, add_button, next_edit_button, next_phase_button]:
		if button == null:
			continue
		button.visible = PHASE_PLANNING_ENABLED
		button.disabled = true if not PHASE_PLANNING_ENABLED else not _can_edit_planning()
		META_UI_SKIN_SCRIPT.style_tactical_button(button, false)
	if go_phase_button != null:
		go_phase_button.disabled = preview_mode or not _can_issue_local_commands() or not _has_selected_fireteam_orders_to_execute()
		go_phase_button.tooltip_text = "Start the live mission from Homebase before GO can execute orders." if preview_mode else "Fuehrt das ausgewaehlte Fireteam zum naechsten offenen Zielpunkt."
		META_UI_SKIN_SCRIPT.style_tactical_button(go_phase_button, not go_phase_button.disabled)


func _refresh_fireteam_status_panel() -> void:
	var panel := _ensure_fireteam_status_panel()
	if panel == null:
		return
	_refresh_tactical_stance_panel()
	var selection_badge := panel.get_node_or_null("MarginContainer/HBoxContainer/SelectionStateBadge") as Node
	var suppression_label := panel.get_node_or_null("MarginContainer/HBoxContainer/SuppressionLabel") as Label
	var suppression_progress := panel.get_node_or_null("MarginContainer/HBoxContainer/SuppressionProgressLine") as Node
	var return_button := panel.get_node_or_null("MarginContainer/HBoxContainer/ReturnToPlanButton") as Button
	var selected_fireteam_id: String = _get_selected_fireteam_id()
	if selected_fireteam_id.is_empty() and not _selected_fireteam_ids.is_empty():
		selected_fireteam_id = String(_selected_fireteam_ids[0]).strip_edges().to_lower()
	var state: Dictionary = Dictionary(_suppression_state_by_fireteam.get(selected_fireteam_id, {}))
	var suppression_value: float = float(state.get("value", 0.0))
	var suppression_threshold: float = float(state.get("threshold", 1.0))
	var lead_name: String = "-"
	var lead = _resolve_fireteam_leader_for_behavior(selected_fireteam_id)
	if lead != null and lead.has_method("get_display_name"):
		lead_name = "★ %s" % String(lead.call("get_display_name"))
	var ad_hoc_type: String = ""
	if _ad_hoc_order_controller != null:
		ad_hoc_type = String(Dictionary(_ad_hoc_order_controller.call("get_active_order", selected_fireteam_id)).get("order_type", "")).strip_edges()
	var badge_text: String = "NO SEL"
	var badge_status_key: String = "neutral"
	if not selected_fireteam_id.is_empty():
		if suppression_threshold > 0.0 and suppression_value >= suppression_threshold:
			badge_text = "PINNED"
			badge_status_key = "danger"
		elif not ad_hoc_type.is_empty():
			badge_text = "AD HOC"
			badge_status_key = "warning"
		elif suppression_value > 0.0:
			badge_text = "CONTACT"
			badge_status_key = "warning"
		else:
			badge_text = "READY"
			badge_status_key = "success"
	if selection_badge != null and selection_badge.has_method("set_badge"):
		selection_badge.call("set_badge", badge_text, badge_status_key)
	if suppression_progress != null and suppression_progress.has_method("set_progress"):
		suppression_progress.call("set_progress", "SUPP", suppression_value, maxf(suppression_threshold, 1.0), badge_status_key)
	var stance_text: String = _build_selected_tactical_stance_text()
	var execution_text: String = _build_selected_execution_quality_text()
	var movement_text: String = _format_movement_state_text(get_fireteam_movement_state(selected_fireteam_id))
	var security_text: String = _format_security_state_text(get_fireteam_security_state(selected_fireteam_id))
	var flank_text: String = _format_flank_vulnerability_text(get_fireteam_flank_vulnerability_state(selected_fireteam_id))
	if suppression_label != null:
		var ad_hoc_text: String = " | AD-HOC %s" % ad_hoc_type.to_upper() if not ad_hoc_type.is_empty() else ""
		suppression_label.text = "%s | STANCE %s | EXEC %s | MOVE %s | SEC %s | FLK %s | SUPP %.2f/%.2f%s" % [lead_name, stance_text, execution_text, movement_text, security_text, flank_text, suppression_value, suppression_threshold, ad_hoc_text]
	var can_return_to_plan: bool = selected_fireteam_id.is_empty() == false and (_has_pending_plan_for_fireteam(selected_fireteam_id) or (_ad_hoc_order_controller != null and bool(_ad_hoc_order_controller.call("has_active_order", selected_fireteam_id))))
	if return_button != null:
		return_button.call("configure", "Return to Plan", "return_to_plan", "Fuehrt das ausgewaehlte Fireteam zurueck in den geplanten Ablauf.", "command" if can_return_to_plan else "neutral")
		return_button.disabled = not can_return_to_plan


func _has_pending_plan_for_fireteam(fireteam_id: String) -> bool:
	var active_phase_index: int = _get_live_order_phase_index()
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, active_phase_index), null)
	if plan == null:
		return false
	for waypoint in plan.waypoints:
		if String(waypoint.status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or String(waypoint.status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED:
			return true
	return false


func _refresh_ad_hoc_panel_visibility() -> void:
	var panel := _ensure_ad_hoc_panel()
	if panel == null:
		return
	var in_combat: bool = false
	for fireteam_id in _selected_fireteam_ids:
		if _is_fireteam_in_combat(String(fireteam_id)):
			in_combat = true
			break
	panel.visible = not preview_mode and _can_issue_local_commands() and in_combat


func _on_ad_hoc_button_pressed(button: Button) -> void:
	if button == null:
		return
	var order_type: String = String(button.get_meta("ad_hoc_order_type", "")).strip_edges().to_lower()
	if order_type.is_empty():
		return
	issue_ad_hoc_order(order_type, _get_target_position())


func _on_tactical_stance_button_pressed(button: Button) -> void:
	if button == null:
		return
	var stance_id: String = String(button.get_meta("tactical_stance_id", "")).strip_edges().to_lower()
	if stance_id.is_empty():
		return
	set_selected_fireteams_tactical_stance(stance_id)


func _on_return_to_plan_button_pressed() -> void:
	return_selected_fireteams_to_plan()


func _refresh_selected_fireteam_cards() -> void:
	var card_row := get_node_or_null(FIRETEAM_SELECTED_CARDS_ROW_PATH) as HBoxContainer
	if card_row == null:
		return

	for child in card_row.get_children():
		child.queue_free()

	var units: Array = _get_selected_friendly_units(not _use_visible_units_for_fireteam_ui())
	if units.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Kein aktives Fireteam im Sichtbereich."
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.custom_minimum_size = Vector2(280.0, 44.0)
		META_UI_SKIN_SCRIPT.style_body_label(empty_label, 11)
		card_row.add_child(empty_label)
		return

	for unit in units:
		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.custom_minimum_size = Vector2(180.0 if preview_mode else 156.0, 58.0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.call(
			"setup_from_profile",
			_build_fireteam_card_profile(unit),
			{
				"source_context": "mission_tactical",
				"compact_mode": true,
				"drag_enabled": false,
				"show_lead_indicator": true,
				"is_lead": _is_unit_current_fireteam_lead(unit),
				"selected": _is_unit_selected(unit),
			}
		)
		if not card.card_open_requested.is_connected(_on_fireteam_card_open_requested):
			card.card_open_requested.connect(_on_fireteam_card_open_requested)
		card_row.add_child(card)


func _refresh_fireteam_mini_cards() -> void:
	var card_host := get_node_or_null(FIRETEAM_MINI_CARDS_VBOX_PATH) as VBoxContainer
	if card_host == null:
		return

	var fireteam_panel := get_node_or_null(FIRETEAM_MINI_PANEL_PATH) as Control
	for child in card_host.get_children():
		card_host.remove_child(child)
		child.queue_free()

	var available_fireteam_ids: PackedStringArray = _get_displayable_fireteam_ids()
	if fireteam_panel != null:
		fireteam_panel.visible = not available_fireteam_ids.is_empty()
	if available_fireteam_ids.is_empty():
		return

	for fireteam_id in available_fireteam_ids:
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		var units: Array = _get_fireteam_units(normalized_fireteam_id, not _use_visible_units_for_fireteam_ui())
		var card := PanelContainer.new()
		card.name = "FireteamMiniCard_%s" % normalized_fireteam_id.capitalize()
		card.custom_minimum_size = Vector2(0.0, 0.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.set_meta("fireteam_id", normalized_fireteam_id)
		var card_click_callback: Callable = Callable(self, "_on_fireteam_mini_card_gui_input").bind(normalized_fireteam_id)
		if not card.gui_input.is_connected(card_click_callback):
			card.gui_input.connect(card_click_callback)
		card_host.add_child(card)

		var lead = _resolve_fireteam_leader_for_behavior(normalized_fireteam_id)
		var selected_fireteam: bool = _selected_fireteam_ids.has(normalized_fireteam_id)
		var runtime_inactive: bool = not preview_mode and not _is_fireteam_runtime_active(normalized_fireteam_id)
		var lead_name: String = String(lead.call("get_display_name")) if lead != null and lead.has_method("get_display_name") else "Kein Lead"
		var lead_portrait_path: String = String(lead.call("get_portrait_path")) if lead != null and lead.has_method("get_portrait_path") else ""
		var fireteam_texture: Texture2D = _load_portrait_texture(lead_portrait_path)
		if fireteam_texture == null and lead != null and lead.has_method("get_weapon_visual_texture_path"):
			fireteam_texture = _load_optional_texture(String(lead.call("get_weapon_visual_texture_path")))
		TRANSPORT_CRAFT_CARD_UI_SCRIPT.apply_card_state(
			card,
			{
				"selected": selected_fireteam,
				"in_transit": runtime_inactive,
				"can_stage": false,
				"title_text": _get_fireteam_display_label(normalized_fireteam_id),
				"title_font_size": 10,
				"margin_left": 6,
				"margin_top": 6,
				"margin_right": 6,
				"margin_bottom": 6,
				"vbox_separation": 2,
				"header_separation": 4,
				"content_separation": 4,
				"ship_texture": fireteam_texture,
				"ship_texture_width": 40.0,
				"ship_texture_height": 40.0,
				"content_minimum_height": 42.0,
				"pilot_profile": null,
				"pilot_text": "Lead %s" % lead_name,
				"pilot_text_font_size": 8,
				"pilot_source_context": "mission_fireteam_lead",
				"pilot_disabled": runtime_inactive,
				"pilot_mouse_filter": Control.MOUSE_FILTER_IGNORE,
				"pilot_card_minimum_width": 124.0,
				"pilot_card_minimum_height": 32.0,
				"pilot_host_separation": 0,
				"info_vbox_separation": 0,
				"info_lines_separation": 0,
				"info_lines": _build_fireteam_mini_info_lines(normalized_fireteam_id, units),
				"info_line_font_size": 8,
				"progress_visible": false,
				"primary_action": {
					"visible": false,
				},
				"secondary_action": {
					"visible": false,
				},
				"clear_extra_content": true,
			}
		)


func _on_fireteam_mini_card_gui_input(event: InputEvent, fireteam_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		_cancel_selection_interaction()
		get_viewport().set_input_as_handled()
		if mouse_button_event.pressed:
			_on_fireteam_group_pressed(fireteam_id)


func _build_fireteam_card_profile(unit: Node):
	var profile = _build_profile_from_unit(unit)
	if profile == null or not profile.has_method("duplicate_profile"):
		return profile

	var card_profile = profile.duplicate_profile()
	if preview_mode:
		var loadout_summary: String = _build_preview_fireteam_card_loadout_summary(unit)
		if not loadout_summary.is_empty():
			card_profile.role_name = loadout_summary
		card_profile.secondary_text = _build_unit_secondary_text(unit)
	else:
		card_profile.role_name = _build_live_fireteam_card_runtime_line(unit)
		card_profile.secondary_text = _build_live_fireteam_card_detail_line(unit)
	return card_profile


func _build_profile_from_unit(unit: Node) -> RefCounted:
	return META_UNIT_PROFILE_BUILDER_SCRIPT.build_from_test_unit(
		unit,
		{
			"secondary_text": _build_unit_secondary_text(unit),
			"status_text": _build_tactical_character_status_text(unit),
		}
	)


func _build_tactical_character_status_text(unit: Node) -> String:
	if unit == null:
		return "Taktische Daten nicht verfuegbar"
	var fireteam_label: String = _get_fireteam_display_label(String(unit.call("get_fireteam_id")))
	if fireteam_label.is_empty():
		fireteam_label = "UNASSIGNED"
	var state_bits: PackedStringArray = ["Fireteam %s" % fireteam_label]
	var unit_id: String = String(unit.call("get_unit_id"))
	if _embarked_unit_ids.has(unit_id):
		state_bits.append("Embarked")
	elif _deployed_unit_ids.has(unit_id):
		state_bits.append("Deployed")
	else:
		state_bits.append(String(unit.call("get_vital_state")).capitalize())
	state_bits.append("Phase %s" % _get_phase_name())
	return " | ".join(state_bits)


func _build_live_fireteam_card_runtime_line(unit: Node) -> String:
	if unit == null:
		return "Runtime unavailable"
	var parts: PackedStringArray = []
	var vital_state: String = String(unit.call("get_vital_state")) if unit.has_method("get_vital_state") else "fit"
	if vital_state != "fit":
		parts.append(vital_state.to_upper())
	else:
		var runtime_status = unit.call("get_runtime_status") if unit.has_method("get_runtime_status") else null
		var source_command_type: String = ""
		var status_name: String = ""
		var phase_index: int = -1
		if runtime_status != null and runtime_status.has_method("get"):
			source_command_type = String(runtime_status.get("source_command_type"))
			status_name = String(runtime_status.get("status"))
			phase_index = int(runtime_status.get("phase"))
		var command_label: String = source_command_type.to_upper()
		if command_label.is_empty():
			command_label = status_name.to_upper()
		if command_label.is_empty():
			command_label = "IDLE"
		parts.append(command_label)
		if unit.has_method("get_fire_status"):
			parts.append(_format_unit_fire_status_short(String(unit.call("get_fire_status"))))
		if phase_index >= 0:
			parts.append(COMMANDER_COMMAND_SCRIPT.get_phase_short_name(phase_index))
	if unit.has_method("get_effective_cover_score"):
		parts.append("COV %d" % int(unit.call("get_effective_cover_score")))
	return " | ".join(parts)


func _build_live_fireteam_card_detail_line(unit: Node) -> String:
	if unit == null:
		return "No unit data"
	var detail_parts: PackedStringArray = []
	if unit.has_method("get_skill_summary_text"):
		detail_parts.append(String(unit.call("get_skill_summary_text")))
	var trait_text: String = String(unit.call("get_trait_summary_text")).strip_edges() if unit.has_method("get_trait_summary_text") else ""
	if not trait_text.is_empty():
		detail_parts.append(trait_text)
	return " | ".join(detail_parts)


func _format_unit_fire_status_short(fire_status: String) -> String:
	match fire_status.strip_edges().to_lower():
		"hold_fire":
			return "HF"
		"fire_at_will":
			return "FAW"
		"semi_disciplined":
			return "SEC"
		_:
			return fire_status.strip_edges().to_upper()


func _build_fireteam_group_status_text(fireteam_id: String, units: Array) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return "Keine Daten"
	var lead_name: String = "-"
	for unit in units:
		if unit != null and _is_unit_current_fireteam_lead(unit):
			lead_name = String(unit.call("get_display_name"))
			break
	if lead_name == "-" and not units.is_empty() and (units[0] as Node).has_method("get_display_name"):
		lead_name = String((units[0] as Node).call("get_display_name"))
	var planned_waypoint_count: int = _count_selected_phase_waypoints_for_fireteams(PackedStringArray([normalized_fireteam_id]))
	return "%d Operatoren | %d Wegpunkte | Lead %s" % [units.size(), planned_waypoint_count, lead_name]


func _build_fireteam_mini_info_lines(fireteam_id: String, units: Array) -> Array:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var member_count_text := "%d Mitglieder" % units.size()
	if units.size() == 1:
		member_count_text = "1 Mitglied"
	var planned_waypoint_count: int = _count_selected_phase_waypoints_for_fireteams(PackedStringArray([normalized_fireteam_id]))
	return ["%s | %d Wegpunkte" % [member_count_text, planned_waypoint_count]]


func _on_fireteam_card_open_requested(unit_id: String, _profile, _source_context: String) -> void:
	_open_character_overlay(unit_id)


func _open_character_overlay(unit_id: String) -> void:
	_character_overlay_unit_id = unit_id.strip_edges()
	_character_overlay_open = true
	_update_character_overlay()
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay != null:
		overlay.visible = true


func _close_character_overlay() -> void:
	_character_overlay_open = false
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay != null:
		overlay.visible = false


func _update_character_overlay() -> void:
	var host := _get_character_overlay_host()
	if host == null:
		return
	var profile = null
	var unit := _find_friendly_unit_by_id(_character_overlay_unit_id)
	var render_options: Dictionary = {}
	if unit != null:
		profile = _build_profile_from_unit(unit)
		render_options["loadout_text"] = _build_tactical_loadout_text(unit)
		render_options["fireteam_text"] = _build_tactical_fireteam_text(unit)
	CHARACTER_SHEET_VIEW_SCRIPT.render(host, profile, render_options)
	if unit != null:
		_append_character_overlay_dev_editor(host, unit)


func _find_friendly_unit_by_id(unit_id: String) -> Node:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return null
	var mission_root: Node = get_parent()
	if mission_root == null:
		return null
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		if String(child.call("get_unit_id")).strip_edges() == normalized_unit_id:
			return child
	return null


func _get_character_overlay_host() -> VBoxContainer:
	var overlay := get_node_or_null("../TacticalUI/CharacterOverlay") as Control
	if overlay == null:
		return null
	return overlay.get_node_or_null("OverlayPanel/OverlayMargin/OverlayVBox/OverlayScroll/OverlayContentVBox") as VBoxContainer


func _append_character_overlay_dev_editor(host: VBoxContainer, unit: Node) -> void:
	if host == null or unit == null or not unit.has_method("apply_identity_config"):
		return

	var panel := PanelContainer.new()
	panel.name = "DevStatsPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "subtle")
	host.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var header := Label.new()
	header.text = "DEV-WERTE"
	META_UI_SKIN_SCRIPT.style_header_label(header, 11)
	vbox.add_child(header)

	var hint := Label.new()
	hint.text = "Nur zum Balancing waehrend der Entwicklung. Werte werden auf die laufende Unit angewendet."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(hint, 9)
	vbox.add_child(hint)

	var unit_id: String = String(unit.call("get_unit_id")) if unit.has_method("get_unit_id") else ""
	for row_variant in DEV_CHARACTER_STAT_ROWS:
		var row_data: Dictionary = row_variant
		var stat_key: String = String(row_data.get("key", "")).strip_edges()
		if stat_key.is_empty():
			continue
		_append_character_overlay_dev_slider(vbox, unit, unit_id, stat_key, String(row_data.get("label", stat_key)))


func _append_character_overlay_dev_slider(host: VBoxContainer, unit: Node, unit_id: String, stat_key: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	host.add_child(row)

	var label := Label.new()
	label.text = "%s:" % label_text
	label.custom_minimum_size = Vector2(96.0, 0.0)
	META_UI_SKIN_SCRIPT.style_body_label(label, 9)
	row.add_child(label)

	var slider := HSlider.new()
	slider.name = "Dev_%s" % stat_key
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = _get_unit_dev_stat_value(unit, stat_key)
	row.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%.2f" % slider.value
	value_label.custom_minimum_size = Vector2(42.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	META_UI_SKIN_SCRIPT.style_body_label(value_label, 9)
	row.add_child(value_label)

	if not slider.value_changed.is_connected(_on_dev_unit_slider_preview_changed):
		slider.value_changed.connect(_on_dev_unit_slider_preview_changed.bind(value_label))
	if not slider.drag_ended.is_connected(_on_dev_unit_slider_drag_ended):
		slider.drag_ended.connect(_on_dev_unit_slider_drag_ended.bind(slider, unit_id, stat_key))


func _get_unit_dev_stat_value(unit: Node, stat_key: String) -> float:
	if unit == null:
		return 0.0
	match stat_key:
		"skill_accuracy":
			return float(unit.call("get_accuracy_skill")) if unit.has_method("get_accuracy_skill") else 0.0
		"skill_speed":
			return float(unit.call("get_speed_skill")) if unit.has_method("get_speed_skill") else 0.0
		"skill_leadership":
			return float(unit.call("get_leadership_skill")) if unit.has_method("get_leadership_skill") else 0.0
		"skill_toughness":
			return float(unit.call("get_toughness_skill")) if unit.has_method("get_toughness_skill") else 0.0
		"awareness":
			return float(unit.call("get_awareness")) if unit.has_method("get_awareness") else 0.0
		"recognition":
			return float(unit.call("get_recognition")) if unit.has_method("get_recognition") else 0.0
		"discipline":
			return float(unit.call("get_discipline")) if unit.has_method("get_discipline") else 0.0
		"stealth":
			return float(unit.call("get_stealth")) if unit.has_method("get_stealth") else 0.0
		_:
			return 0.0


func _on_dev_unit_slider_preview_changed(value: float, value_label: Label) -> void:
	if value_label != null:
		value_label.text = "%.2f" % clampf(value, 0.0, 1.0)


func _on_dev_unit_slider_drag_ended(value_changed: bool, slider: HSlider, unit_id: String, stat_key: String) -> void:
	if not value_changed or slider == null:
		return
	var unit := _find_friendly_unit_by_id(unit_id)
	if unit == null or not unit.has_method("apply_identity_config"):
		return
	unit.call("apply_identity_config", {stat_key: clampf(float(slider.value), 0.0, 1.0)})
	_update_ui()
	call_deferred("_update_character_overlay")


func _ensure_character_overlay() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("CharacterOverlay") != null:
		return

	var overlay := Control.new()
	overlay.name = "CharacterOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	tactical_ui.add_child(overlay)

	var shade := ColorRect.new()
	shade.name = "OverlayShade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.color = Color(0.02, 0.05, 0.05, 0.72)
	overlay.add_child(shade)

	var panel := PanelContainer.new()
	panel.name = "OverlayPanel"
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -210.0
	panel.offset_top = -300.0
	panel.offset_right = 210.0
	panel.offset_bottom = 300.0
	overlay.add_child(panel)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")

	var margin := MarginContainer.new()
	margin.name = "OverlayMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var overlay_vbox := VBoxContainer.new()
	overlay_vbox.name = "OverlayVBox"
	overlay_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(overlay_vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "OverlayHeaderRow"
	header_row.add_theme_constant_override("separation", 8)
	overlay_vbox.add_child(header_row)

	var header_label := Label.new()
	header_label.name = "OverlayHeaderLabel"
	header_label.text = "Character Sheet"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 12)
	header_row.add_child(header_label)

	var close_button := Button.new()
	close_button.name = "CloseOverlayButton"
	close_button.text = "Close"
	META_UI_SKIN_SCRIPT.style_tactical_button(close_button, false)
	if not close_button.pressed.is_connected(_close_character_overlay):
		close_button.pressed.connect(_close_character_overlay)
	header_row.add_child(close_button)

	var scroll := ScrollContainer.new()
	scroll.name = "OverlayScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay_vbox.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.name = "OverlayContentVBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(content_vbox)


func _build_unit_secondary_text(unit: Node) -> String:
	var parts: PackedStringArray = []
	var unit_id: String = String(unit.call("get_unit_id"))
	if _is_unit_current_fireteam_lead(unit):
		parts.append("Lead")
	if _embarked_unit_ids.has(unit_id):
		parts.append("Embarked")
	elif _deployed_unit_ids.has(unit_id):
		parts.append("Deployed")
	else:
		parts.append(String(unit.call("get_vital_state")).capitalize())
	var callsign: String = String(unit.call("get_callsign")).strip_edges()
	if not callsign.is_empty():
		parts.append(callsign)
	return " | ".join(parts)


func _build_tactical_loadout_text(unit: Node) -> String:
	if unit == null or not unit.has_method("get_unit_id"):
		return "standard kit"

	var effective_loadout: Dictionary = _get_effective_member_loadout(unit)
	return CHARACTER_SHEET_FORMATTER_SCRIPT.build_loadout_text_from_ids(
		String(effective_loadout.get("armor", "medium")),
		String(effective_loadout.get("weapon_1", "rifle")),
		String(effective_loadout.get("weapon_2", "rifle")),
		"standard kit"
	)


func _build_preview_fireteam_card_loadout_summary(unit: Node) -> String:
	if unit == null:
		return ""
	var effective_loadout: Dictionary = _get_effective_member_loadout(unit)
	return "%s | %s | %s" % [
		_build_compact_armor_label(String(effective_loadout.get("armor", "medium"))),
		_build_compact_weapon_label(String(effective_loadout.get("weapon_1", "rifle"))),
		_build_compact_weapon_label(String(effective_loadout.get("weapon_2", "rifle"))),
	]


func _get_effective_member_loadout(unit: Node) -> Dictionary:
	if unit == null or not unit.has_method("get_unit_id"):
		return {
			"armor": "medium",
			"weapon_1": "rifle",
			"weapon_2": "rifle",
		}

	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup != null:
		var member_loadouts: Dictionary = mission_setup.get("member_loadouts") if typeof(mission_setup.get("member_loadouts")) == TYPE_DICTIONARY else {}
		if member_loadouts.has(unit_id) and typeof(member_loadouts.get(unit_id)) == TYPE_DICTIONARY:
			var loadout: Dictionary = Dictionary(member_loadouts.get(unit_id, {}))
			return {
				"armor": String(loadout.get("armor", "medium")).strip_edges(),
				"weapon_1": String(loadout.get("weapon_1", loadout.get("weapon", "rifle"))).strip_edges(),
				"weapon_2": String(loadout.get("weapon_2", "rifle")).strip_edges(),
			}

	return {
		"armor": String(unit.call("get_armor_id")).strip_edges() if unit.has_method("get_armor_id") else "medium",
		"weapon_1": String(unit.call("get_weapon_1_id")).strip_edges() if unit.has_method("get_weapon_1_id") else "rifle",
		"weapon_2": String(unit.call("get_weapon_2_id")).strip_edges() if unit.has_method("get_weapon_2_id") else "rifle",
	}


func _build_compact_armor_label(armor_id: String) -> String:
	match armor_id.strip_edges().to_lower():
		"light":
			return "Light"
		"heavy":
			return "Heavy"
		_:
			return "Medium"


func _build_compact_weapon_label(weapon_id: String) -> String:
	match weapon_id.strip_edges().to_lower():
		"smg":
			return "SMG"
		"rail_gun", "special":
			return "Rail"
		"medictool", "medic_tool", "medic-tool":
			return "Med"
		_:
			return "Rifle"


func _build_tactical_fireteam_text(unit: Node) -> String:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return "UNASSIGNED"
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup != null:
		var selected_unit_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_unit_ids"))
		var selected_fireteam_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
		var unit_index: int = selected_unit_ids.find(unit_id)
		if unit_index >= 0 and unit_index < selected_fireteam_ids.size():
			return _get_fireteam_display_label(String(selected_fireteam_ids[unit_index]))
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	return _get_fireteam_display_label(fireteam_id)


func _get_selected_friendly_units(include_hidden: bool = true) -> Array:
	if _selected_fireteam_ids.is_empty():
		return []

	var mission_root: Node = get_parent()
	if mission_root == null:
		return []

	var selected_units: Array = []
	var selected_fireteam_id: String = _get_selected_fireteam_id()
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id") or not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		var unit_id: String = String(child.call("get_unit_id"))
		if not include_hidden and child is CanvasItem and not (child as CanvasItem).visible and not _embarked_unit_ids.has(unit_id):
			continue
		var child_fireteam_id: String = String(child.call("get_fireteam_id")).strip_edges().to_lower()
		if not selected_fireteam_id.is_empty() and child_fireteam_id != selected_fireteam_id:
			continue
		if selected_fireteam_id.is_empty() and not _selected_fireteam_ids.has(child_fireteam_id):
			continue
		selected_units.append(child)

	selected_units.sort_custom(Callable(self, "_sort_unit_nodes_for_cards"))
	return selected_units


func _sort_unit_nodes_for_cards(a: Node, b: Node) -> bool:
	var a_is_lead: bool = _is_unit_current_fireteam_lead(a)
	var b_is_lead: bool = _is_unit_current_fireteam_lead(b)
	if a_is_lead != b_is_lead:
		return a_is_lead and not b_is_lead
	return String(a.call("get_display_name")) < String(b.call("get_display_name"))


func _get_selected_fireteam_id() -> String:
	if _selected_fireteam_ids.size() == 1:
		return String(_selected_fireteam_ids[0])
	return ""


func _build_fireteam_status_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "NO SELECTION | 0 Karten | Click unit or drag leaders"

	var units: Array = _get_selected_friendly_units(not _use_visible_units_for_fireteam_ui())
	var planned_waypoint_count: int = _count_selected_phase_waypoints()
	var planned_area_count: int = _count_selected_area_orders()
	if units.is_empty():
		return "%s | %d Wegpunkte | %d Gebiete | keine Einheiten aktiv" % [_get_fireteam_name(), planned_waypoint_count, planned_area_count]

	var lead_name: String = "-"
	var embarked_count: int = 0
	var deployed_count: int = 0
	for unit in units:
		var unit_id: String = String(unit.call("get_unit_id"))
		if _embarked_unit_ids.has(unit_id):
			embarked_count += 1
		elif _deployed_unit_ids.has(unit_id):
			deployed_count += 1
		if lead_name == "-" and _is_unit_current_fireteam_lead(unit):
			lead_name = String(unit.call("get_display_name"))
	if lead_name == "-":
		lead_name = String((units[0] as Node).call("get_display_name"))
	var drop_state_text: String = "Lead %s" % lead_name
	if embarked_count > 0:
		drop_state_text = "%d embarked | %d deployed | Lead %s" % [embarked_count, deployed_count, lead_name]
	elif deployed_count > 0:
		drop_state_text = "%d deployed | Lead %s" % [deployed_count, lead_name]
	var mode_text: String = "PREVIEW - START MISSION FOR GO | " if preview_mode else ""
	return "%s%s | %d Karten | %d Wegpunkte | %d Gebiete | STANCE %s | EXEC %s | MOVE %s | SEC %s | FLK %s | %s" % [mode_text, _get_fireteam_name(), units.size(), planned_waypoint_count, planned_area_count, _build_selected_tactical_stance_text(), _build_selected_execution_quality_text(), _build_selected_movement_text(), _build_selected_security_text(), _build_selected_flank_vulnerability_text(), drop_state_text]


func _build_selected_waypoint_info_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "WP -"
	var info_lines: PackedStringArray = []
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var info_text: String = _build_fireteam_waypoint_info_text(fireteam_id)
		if info_text.is_empty():
			continue
		if _selected_fireteam_ids.size() > 1:
			info_lines.append("%s %s" % [fireteam_id.to_upper(), info_text])
		else:
			info_lines.append(info_text)
	if info_lines.is_empty():
		return "WP -"
	return "\n".join(info_lines)


func _build_fireteam_waypoint_info_text(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return ""
	var area_defense_text: String = _build_fireteam_area_defense_info_text(normalized_fireteam_id)
	if not area_defense_text.is_empty():
		return area_defense_text
	var area_attack_text: String = _build_fireteam_area_attack_info_text(normalized_fireteam_id)
	if not area_attack_text.is_empty():
		return area_attack_text
	var phase_index: int = _get_live_order_phase_index()
	var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(normalized_fireteam_id, {}))
	if not execution_state.is_empty():
		phase_index = int(execution_state.get("phase", phase_index))
	var plan = _order_plans_by_key.get(_build_order_plan_key(normalized_fireteam_id, phase_index), null)
	if plan == null or plan.waypoints.is_empty():
		return "WP keine geplanten Befehle"
	var waypoint_index: int = int(execution_state.get("waypoint_index", -1))
	if waypoint_index < 0:
		waypoint_index = _find_next_executable_waypoint_index(plan)
	if waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
		return "WP abgeschlossen"
	var waypoint = plan.waypoints[waypoint_index]
	if waypoint == null:
		return "WP -"
	var command_text: String = _get_waypoint_command_display_name(String(waypoint.command_type))
	var status_text: String = String(waypoint.status).strip_edges().to_upper()
	if bool(execution_state.get("waiting_for_go", false)) or _should_display_waypoint_waiting_for_go(normalized_fireteam_id, waypoint, execution_state):
		status_text = "WARTET AUF GO"
	var movement_text: String = _build_waypoint_movement_description(get_fireteam_movement_state(normalized_fireteam_id))
	var target_text: String = _format_world_position(Vector2(waypoint.target_position)) if typeof(waypoint.target_position) == TYPE_VECTOR2 else "--"
	var text: String = "WP %d/%d %s | %s | Ziel %s" % [waypoint_index + 1, plan.waypoints.size(), command_text, status_text, target_text]
	if not movement_text.is_empty():
		text = "%s | %s" % [text, movement_text]
	return text


func _build_fireteam_area_defense_info_text(fireteam_id: String) -> String:
	var state: Dictionary = Dictionary(_area_defense_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
	if not state.is_empty():
		return _build_area_order_feedback_line(fireteam_id, AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, state, _area_orders_by_id.get(String(state.get("area_order_id", "")), null))
	var area_order = _find_next_defend_area_order(fireteam_id)
	if area_order == null:
		return ""
	return _build_area_order_feedback_line(fireteam_id, AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, {}, area_order)


func _build_fireteam_area_attack_info_text(fireteam_id: String) -> String:
	var state: Dictionary = Dictionary(_area_attack_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
	if not state.is_empty():
		var command_type: String = String(state.get("command_type", AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE)).strip_edges().to_lower()
		return _build_area_order_feedback_line(fireteam_id, command_type, state, _area_orders_by_id.get(String(state.get("area_order_id", "")), null))
	var area_order = _find_next_attack_area_order(fireteam_id)
	if area_order == null:
		return ""
	return _build_area_order_feedback_line(fireteam_id, String(area_order.command_type), {}, area_order)


func _build_area_order_feedback_line(fireteam_id: String, command_type: String, state: Dictionary = {}, area_order = null) -> String:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	var center_position: Vector2 = _resolve_area_feedback_center_position(state, area_order)
	var area_context: Dictionary = _resolve_area_feedback_context(state, area_order, center_position)
	var field_count: int = _resolve_area_feedback_field_count(state, area_order)
	var mode_text: String = _build_area_feedback_mode_text(normalized_command_type, state)
	var size_text: String = _build_area_feedback_size_text(normalized_command_type, field_count, state)
	var security_text: String = _build_area_feedback_security_text(fireteam_id)
	var contact_text: String = _build_area_feedback_contact_text(fireteam_id, area_context, normalized_command_type)
	var detail_parts: PackedStringArray = []
	if not mode_text.is_empty():
		detail_parts.append(mode_text)
	if not security_text.is_empty():
		detail_parts.append(security_text)
	if not contact_text.is_empty():
		detail_parts.append(contact_text)
	detail_parts.append("Ziel %s" % _format_world_position(center_position))
	return "AREA %s | %s | %s" % [
		_get_area_feedback_command_label(normalized_command_type),
		size_text,
		" | ".join(detail_parts),
	]


func _resolve_area_feedback_center_position(state: Dictionary, area_order) -> Vector2:
	if typeof(state.get("center_position", null)) == TYPE_VECTOR2:
		return Vector2(state.get("center_position"))
	if area_order != null and typeof(area_order.center_position) == TYPE_VECTOR2:
		return Vector2(area_order.center_position)
	return Vector2.ZERO


func _resolve_area_feedback_context(state: Dictionary, area_order, center_position: Vector2) -> Dictionary:
	var target_area: Dictionary = Dictionary(state.get("target_area", {})).duplicate(true)
	if not target_area.is_empty():
		return target_area
	if area_order == null:
		return {
			"center_position": center_position,
			"area_radius": 48.0,
		}
	var radius: float = 48.0
	for point_variant in Array(area_order.world_polygon):
		radius = maxf(radius, Vector2(point_variant).distance_to(center_position))
	for point_variant in Array(area_order.tile_world_positions):
		radius = maxf(radius, Vector2(point_variant).distance_to(center_position))
	return {
		"area_order_id": String(area_order.area_order_id),
		"fireteam_id": String(area_order.fireteam_id),
		"command_type": String(area_order.command_type),
		"center_position": center_position,
		"area_radius": radius,
		"tile_positions": Array(area_order.tile_positions).duplicate(true),
		"tile_world_positions": Array(area_order.tile_world_positions).duplicate(true),
		"world_polygon": PackedVector2Array(area_order.world_polygon),
	}


func _resolve_area_feedback_field_count(state: Dictionary, area_order) -> int:
	var target_area: Dictionary = Dictionary(state.get("target_area", {}))
	var tile_positions: Array = Array(target_area.get("tile_positions", []))
	if not tile_positions.is_empty():
		return tile_positions.size()
	if area_order != null:
		tile_positions = Array(area_order.tile_positions)
		if not tile_positions.is_empty():
			return tile_positions.size()
		var tile_world_positions: Array = Array(area_order.tile_world_positions)
		if not tile_world_positions.is_empty():
			return tile_world_positions.size()
	var assignments: Array = Array(state.get("assignments", []))
	return maxi(assignments.size(), 1)


func _build_area_feedback_size_text(command_type: String, field_count: int, state: Dictionary) -> String:
	var normalized_field_count: int = maxi(field_count, 1)
	if command_type == AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE:
		var secured_count: int = normalized_field_count if String(state.get("status", "")).strip_edges().to_lower() == "secured" else 0
		return "%d/%d Felder gesichert" % [secured_count, normalized_field_count]
	return "%d Felder" % normalized_field_count


func _build_area_feedback_mode_text(command_type: String, state: Dictionary) -> String:
	if state.is_empty():
		return "geplant"
	var status: String = String(state.get("status", "")).strip_edges().to_lower()
	var waiting_for_go: bool = bool(state.get("waiting_for_go", false))
	if waiting_for_go:
		if status == "secured":
			return "GESICHERT | WARTET AUF GO | HALTET GEBIET"
		return "WARTET AUF GO | HALTET GEBIET"
	match command_type:
		AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
			return "verteidigt" if status == "holding" else "bezieht Stellung"
		AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE:
			return "nimmt Gebiet" if status != "secured" else "GESICHERT | HALTET GEBIET"
		AREA_ORDER_SCRIPT.COMMAND_TYPE_FLANK:
			return _build_area_feedback_approach_text(state, "Flank")
		_:
			return _build_area_feedback_approach_text(state, "Approach")


func _build_area_feedback_approach_text(state: Dictionary, prefix: String) -> String:
	if String(state.get("status", "")).strip_edges().to_lower() == "engaging":
		return "Kontakt suchen"
	if String(state.get("status", "")).strip_edges().to_lower() == "occupying":
		return "rueckt ins Gebiet"
	if String(state.get("status", "")).strip_edges().to_lower() == "secured":
		return "haltet Gebiet"
	var center_position: Vector2 = Vector2(state.get("center_position", Vector2.ZERO))
	var approach_position: Vector2 = Vector2(state.get("approach_position", center_position))
	return "%s %s" % [prefix, _format_area_approach_direction(approach_position, center_position)]


func _format_area_approach_direction(approach_position: Vector2, center_position: Vector2) -> String:
	var delta: Vector2 = approach_position - center_position
	if delta.length() < 0.001:
		return "-"
	var horizontal: String = "E" if delta.x > 0.0 else "W"
	var vertical: String = "S" if delta.y > 0.0 else "N"
	return "%s%s" % [vertical, horizontal]


func _build_area_feedback_security_text(fireteam_id: String) -> String:
	var security_state: Dictionary = get_fireteam_security_state(fireteam_id)
	if security_state.is_empty() or not bool(security_state.get("is_active", false)):
		return "SEC -"
	var mode: String = String(security_state.get("security_mode", "")).strip_edges().to_lower()
	if mode == "360":
		return "SEC 360"
	if mode == "directional":
		return "SEC DIR"
	return "SEC %s" % mode.to_upper()


func _build_area_feedback_contact_text(fireteam_id: String, area_context: Dictionary, command_type: String) -> String:
	var highest_rank: int = 0
	for contact_variant in get_fireteam_contact_snapshot(fireteam_id):
		var contact: Dictionary = Dictionary(contact_variant)
		var contact_position: Vector2 = Vector2(contact.get("last_known_position", Vector2.ZERO))
		if not area_context.is_empty() and not bool(AREA_ORDER_RESOLVER_SCRIPT.call("is_position_in_area_context", area_context, contact_position)):
			continue
		highest_rank = maxi(highest_rank, _rank_area_feedback_contact_state(String(contact.get("detection_state", ""))))
	if highest_rank >= 4:
		return "Kontakt bestaetigt"
	if highest_rank == 3:
		return "Kontakt gesichtet"
	if highest_rank == 2:
		return "Kontakt verloren"
	if highest_rank == 1:
		return "Kontakt vermutet"
	if command_type == AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
		return "wartet auf Kontakt"
	return "kein Kontakt"


func _rank_area_feedback_contact_state(detection_state: String) -> int:
	match detection_state.strip_edges().to_lower():
		"confirmed":
			return 4
		"spotted":
			return 3
		"lost":
			return 2
		"suspected":
			return 1
		_:
			return 0


func _get_area_feedback_command_label(command_type: String) -> String:
	match command_type.strip_edges().to_lower():
		AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
			return "DEFEND"
		AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE:
			return "TAKE"
		AREA_ORDER_SCRIPT.COMMAND_TYPE_FLANK:
			return "FLANK"
		_:
			return "ATTACK"


func _should_display_waypoint_waiting_for_go(fireteam_id: String, waypoint, execution_state: Dictionary) -> bool:
	if waypoint == null or String(waypoint.command_type).strip_edges().to_lower() != FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND:
		return false
	if String(waypoint.status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE:
		return true
	var anchor := _get_selection_anchor_for_fireteam(fireteam_id)
	if anchor == null:
		return false
	var resolved_target_position: Variant = execution_state.get("resolved_target_position", waypoint.target_position)
	if typeof(resolved_target_position) != TYPE_VECTOR2:
		return false
	return anchor.global_position.distance_to(Vector2(resolved_target_position)) <= PHASE_WAYPOINT_COMPLETE_RADIUS


func _get_waypoint_command_display_name(command_type: String) -> String:
	match command_type.strip_edges().to_lower():
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND:
			return "DEFEND"
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE:
			return "ENGAGE"
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK:
			return "FLANK"
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE:
			return "TAKE"
		_:
			return "MOVE"


func _build_waypoint_movement_description(movement_state: Dictionary) -> String:
	if movement_state.is_empty():
		return ""
	match String(movement_state.get("effective_style", "")).strip_edges().to_lower():
		"rush":
			return "Bewegung: stuermt"
		"bounding":
			return "Bewegung: gebunden"
		"caterpillar", "creep":
			return "Bewegung: raupenartig"
		_:
			return ""


func _build_strategic_status_text() -> String:
	if not _last_planning_state_issue.is_empty():
		return "Alte Planungsdaten erkannt\nBitte Plan im aktuellen\nPhasensystem neu anlegen."
	var lz_text: String = "LZ offen" if not _has_lz_position else "LZ %s" % _format_world_position(_lz_position)
	var ship_text: String = "Drop wartend"
	if _mission_drop_state == "to_mission":
		ship_text = "Dropship unterwegs zur Mission (%ds)" % _mission_drop_eta_seconds
	elif _mission_drop_state == "waiting":
		ship_text = "Dropship wartet auf Mission-Map"
	elif _mission_drop_state == "to_fob":
		ship_text = "Dropship Rueckflug zur FOB (%ds)" % _mission_drop_eta_seconds
	if _mission_drop_state.is_empty() and _drop_ship_staged and not _drop_ship_requested and _drop_sequence_phase.is_empty():
		ship_text = "Dropship staged off-map"
	if _drop_ship_requested:
		ship_text = "Drop aus %s angefordert" % _get_approach_angle_name()
	if preview_mode:
		ship_text = "%s (Preview)" % ship_text
	if not preview_mode and _drop_ship_cooldown_remaining > 0.0 and _drop_sequence_phase.is_empty():
		ship_text = "Drop bereit in %.1fs" % _drop_ship_cooldown_remaining
	if _drop_sequence_phase == DROP_SEQUENCE_INBOUND:
		ship_text = "Dropship inbound"
	elif _drop_sequence_phase == DROP_SEQUENCE_LANDED:
		ship_text = "Dropship gelandet"
	elif _drop_sequence_phase == DROP_SEQUENCE_UNLOADING:
		ship_text = "Deboarding %d/%d" % [_drop_sequence_unit_index, _drop_sequence_units.size()]
	elif _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		ship_text = "Dropship outbound"
	elif _drop_sequence_phase == DROP_SEQUENCE_COMPLETE:
		ship_text = "Fireteam entladen"
	var time_text: String = _build_mission_time_limit_text()
	var transfer_text: String = _build_meta_transfer_status_text()
	if transfer_text.is_empty():
		return "%s\nApproach %s\n%s\n%s" % [lz_text, _get_approach_angle_name(), ship_text, time_text]
	return "%s\nApproach %s\n%s\n%s\n%s" % [lz_text, _get_approach_angle_name(), ship_text, transfer_text, time_text]


func _build_meta_transfer_status_text() -> String:
	if not preview_mode or _meta_transfer_routes.is_empty():
		return ""
	var operator_count: int = 0
	var craft_count: int = 0
	var next_eta_seconds: int = 0
	for route_variant in _meta_transfer_routes:
		if typeof(route_variant) != TYPE_DICTIONARY:
			continue
		var route: Dictionary = Dictionary(route_variant)
		if String(route.get("entry_type", "team")).strip_edges().to_lower() == "pilot":
			craft_count += 1
		else:
			operator_count += maxi(int(route.get("member_count", 0)), 1)
		var eta_seconds: int = maxi(int(route.get("eta_seconds", 0)), 0)
		if eta_seconds > 0 and (next_eta_seconds <= 0 or eta_seconds < next_eta_seconds):
			next_eta_seconds = eta_seconds
	var summary_bits: PackedStringArray = []
	if operator_count > 0:
		summary_bits.append("%d NPC" % operator_count)
	if craft_count > 0:
		summary_bits.append("%d Craft" % craft_count)
	if summary_bits.is_empty():
		summary_bits.append("%d aktiv" % _meta_transfer_routes.size())
	if next_eta_seconds > 0:
		return "HB->FOB %s | ETA %ds" % [" + ".join(summary_bits), next_eta_seconds]
	return "HB->FOB %s" % " + ".join(summary_bits)


func _build_phase_status_text() -> String:
	if not PHASE_PLANNING_ENABLED:
		return "Direktmodus | GO fuehrt zum naechsten Zielpunkt"
	var phase_controller = _get_phase_controller()
	if phase_controller == null:
		return "Active P0 PRE | Edit %s" % _get_phase_name()
	return "Active %s | Edit %s" % [
		String(phase_controller.call("get_active_phase_name")),
		String(phase_controller.call("get_selected_phase_name")),
	]


func _build_mission_time_limit_text() -> String:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_remaining_time_limit_seconds"):
		return "Time --:--"
	var remaining_seconds: float = float(combat_driver.call("get_remaining_time_limit_seconds"))
	if remaining_seconds < 0.0:
		return "Time --:--"
	var minutes: int = int(floor(remaining_seconds / 60.0))
	var seconds: int = int(remaining_seconds) % 60
	return "Time %02d:%02d" % [minutes, seconds]


func _is_mission_drop_available() -> bool:
	if _mission_drop_state == "waiting":
		return true
	if _drop_ship_staged and _mission_drop_craft_id.is_empty():
		return true
	return _mission_drop_craft_id.is_empty() and not _embarked_unit_ids.is_empty() and _deployed_unit_ids.is_empty()


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.strip_edges().is_empty():
		return null
	var resource: Resource = load(portrait_path)
	return resource as Texture2D


func _load_optional_texture(texture_path: String) -> Texture2D:
	if texture_path.strip_edges().is_empty():
		return null
	var resource: Resource = load(texture_path)
	return resource as Texture2D


func _ensure_mission_nav_timer_label() -> void:
	var nav_row := get_node_or_null("../TacticalUI/TopNavPanel/NavMargin/NavRow") as HBoxContainer
	if nav_row == null:
		return
	var timer_label := nav_row.get_node_or_null("MissionTimerLabel") as Label
	if timer_label == null:
		timer_label = Label.new()
		timer_label.name = "MissionTimerLabel"
		timer_label.custom_minimum_size = Vector2(44.0, 0.0)
		timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		timer_label.add_theme_font_size_override("font_size", 8)
		nav_row.add_child(timer_label)


func _refresh_mission_nav_timer_label() -> void:
	var timer_label := get_node_or_null("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionTimerLabel") as Label
	if timer_label == null:
		return
	var combat_driver = _get_combat_loop_driver()
	if combat_driver != null and combat_driver.has_method("get_remaining_time_limit_seconds"):
		var remaining_seconds: float = float(combat_driver.call("get_remaining_time_limit_seconds"))
		if remaining_seconds >= 0.0:
			var total_seconds: int = maxi(int(round(remaining_seconds)), 0)
			timer_label.text = "%02d:%02d" % [floori(float(total_seconds) / 60.0), total_seconds % 60]
			return
	timer_label.text = "--:--"


func _ensure_mission_dropship_panel() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null:
		return
	var panel := tactical_ui.get_node_or_null("MissionDropshipPanel") as PanelContainer
	if panel != null:
		return
	panel = PanelContainer.new()
	panel.name = "MissionDropshipPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = true
	_enforce_mission_dropship_panel_geometry(panel)
	tactical_ui.add_child(panel)
	TRANSPORT_CRAFT_CARD_UI_SCRIPT.ensure_card_structure(panel)
	_set_control_tree_mouse_filter(panel, Control.MOUSE_FILTER_IGNORE)


func _refresh_mission_dropship_panel() -> void:
	var panel := get_node_or_null("../TacticalUI/MissionDropshipPanel") as PanelContainer
	if panel == null:
		return
	_enforce_mission_dropship_panel_geometry(panel)
	var show_panel: bool = _tactical_ui_visible and (not _mission_drop_craft_id.is_empty() or _is_drop_sequence_active())
	if not show_panel:
		panel.visible = false
		return
	panel.visible = false
	var is_transit: bool = _mission_drop_state == "to_mission" or _mission_drop_state == "to_fob" or _mission_drop_state == "waiting" or _drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND
	var ship_texture := _get_mission_dropship_texture()
	TRANSPORT_CRAFT_CARD_UI_SCRIPT.apply_card_state(
		panel,
		{
			"selected": false,
			"in_transit": is_transit,
			"can_stage": false,
			"title_text": _build_mission_dropship_title_text(),
			"title_font_size": 9,
			"margin_left": 4,
			"margin_top": 1,
			"margin_right": 4,
			"margin_bottom": 1,
			"vbox_separation": 0,
			"header_separation": 4,
			"content_separation": 4,
			"ship_texture": ship_texture,
			"ship_texture_width": 64.0,
			"ship_texture_height": 36.0,
			"content_minimum_height": 42.0,
			"pilot_profile": _build_mission_dropship_pilot_profile(),
			"pilot_text": _build_mission_dropship_pilot_text(),
			"pilot_text_font_size": MISSION_DROPSHIP_INFO_FONT_SIZE,
			"pilot_source_context": "mission_drop_pilot",
			"pilot_disabled": is_transit,
			"pilot_mouse_filter": Control.MOUSE_FILTER_IGNORE,
			"pilot_card_minimum_width": 128.0,
			"pilot_card_minimum_height": 42.0,
			"pilot_host_separation": 0,
			"info_vbox_separation": 0,
			"info_lines_separation": 0,
			"info_lines": [
				_build_mission_dropship_passenger_text(),
				_build_mission_dropship_status_text(),
			],
			"info_line_font_size": MISSION_DROPSHIP_INFO_FONT_SIZE,
			"progress_bar_height": 4.0,
			"progress_visible": is_transit,
			"progress_value": _build_mission_dropship_progress_value(),
			"primary_action": {
				"visible": false,
			},
			"secondary_action": {
				"visible": false,
			},
			"clear_extra_content": true,
		}
	)
	_set_control_tree_mouse_filter(panel, Control.MOUSE_FILTER_IGNORE)
	_enforce_mission_dropship_panel_geometry(panel)
	panel.visible = true
	call_deferred("_deferred_enforce_mission_dropship_panel_geometry")


func _enforce_mission_dropship_panel_geometry(panel: PanelContainer) -> void:
	if panel == null:
		return
	var viewport := get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size if viewport != null else Vector2(1920.0, 1080.0)
	var panel_position := Vector2(
		maxf(viewport_size.x - MISSION_DROPSHIP_PANEL_SIZE.x - MISSION_DROPSHIP_PANEL_MARGIN_RIGHT, 0.0),
		_get_mission_dropship_panel_top_offset()
	)
	panel.top_level = true
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.position = panel_position
	panel.size = MISSION_DROPSHIP_PANEL_SIZE
	panel.custom_minimum_size = MISSION_DROPSHIP_PANEL_SIZE
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + MISSION_DROPSHIP_PANEL_SIZE.x
	panel.offset_bottom = panel_position.y + MISSION_DROPSHIP_PANEL_SIZE.y
	panel.clip_contents = true
	panel.set_deferred("position", panel_position)
	panel.set_deferred("size", MISSION_DROPSHIP_PANEL_SIZE)


func _deferred_enforce_mission_dropship_panel_geometry() -> void:
	var panel := get_node_or_null("../TacticalUI/MissionDropshipPanel") as PanelContainer
	if panel == null:
		return
	_enforce_mission_dropship_panel_geometry(panel)


func _get_mission_dropship_panel_top_offset() -> float:
	var top_offset := MISSION_DROPSHIP_PANEL_MARGIN_TOP
	var mission_identity_panel := get_node_or_null("../TacticalUI/MissionIdentityPanel") as Control
	if mission_identity_panel != null:
		top_offset = maxf(top_offset, mission_identity_panel.offset_bottom + MISSION_DROPSHIP_PANEL_GAP_BELOW_IDENTITY)
	return top_offset


func _set_control_tree_mouse_filter(root: Node, mouse_filter: Control.MouseFilter) -> void:
	if root is Control:
		(root as Control).mouse_filter = mouse_filter
	for child in root.get_children():
		_set_control_tree_mouse_filter(child, mouse_filter)


func _build_mission_dropship_title_text() -> String:
	if not _mission_drop_title_text.is_empty():
		return _mission_drop_title_text
	var craft_name: String = _mission_drop_display_name if not _mission_drop_display_name.is_empty() else "Dropship"
	match _mission_drop_state:
		"waiting":
			return "%s · MAP" % craft_name
		"to_mission":
			return "%s · HANDOVER" % craft_name
		"to_fob":
			return "%s · RETURN" % craft_name
		_:
			return craft_name


func _build_mission_dropship_pilot_text() -> String:
	if not _mission_drop_pilot_text.is_empty():
		return _mission_drop_pilot_text
	return "Pilot: %s" % (_mission_drop_pilot_display_name if not _mission_drop_pilot_display_name.is_empty() else "unassigned")


func _build_mission_dropship_passenger_text() -> String:
	var passenger_count: int = _mission_drop_passenger_count if _mission_drop_passenger_count > 0 else _embarked_unit_ids.size()
	return "Passengers: %d" % passenger_count


func _build_mission_dropship_progress_value() -> float:
	if _drop_sequence_phase == DROP_SEQUENCE_INBOUND:
		var staging_position: Vector2 = _get_drop_staging_position()
		var total_distance: float = staging_position.distance_to(_lz_position)
		if total_distance > 0.001:
			var covered_distance: float = total_distance - _drop_sequence_position.distance_to(_lz_position)
			return clampf((covered_distance / total_distance) * 100.0, 0.0, 100.0)
		return 0.0
	if _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		var exit_position: Vector2 = _get_drop_exit_position()
		var total_return_distance: float = _lz_position.distance_to(exit_position)
		if total_return_distance > 0.001:
			var covered_return_distance: float = total_return_distance - _drop_sequence_position.distance_to(exit_position)
			return clampf((covered_return_distance / total_return_distance) * 100.0, 0.0, 100.0)
		return 0.0
	return _mission_drop_progress


func _build_mission_dropship_pilot_profile():
	if _mission_drop_pilot_display_name.is_empty() and _mission_drop_pilot_portrait_path.is_empty():
		return null
	var pilot_unit = _find_friendly_unit_by_id(_mission_drop_pilot_unit_id)
	if pilot_unit != null:
		var pilot_profile = _build_profile_from_unit(pilot_unit)
		if pilot_profile != null and pilot_profile.has_method("duplicate_profile"):
			var duplicated_profile = pilot_profile.duplicate_profile()
			duplicated_profile.secondary_text = _build_mission_dropship_pilot_text()
			return duplicated_profile
		return pilot_profile
	return META_UNIT_PROFILE_BUILDER_SCRIPT.build_from_identity_config(
		{
			"unit_id": _mission_drop_pilot_unit_id if not _mission_drop_pilot_unit_id.is_empty() else "mission_drop_pilot",
			"display_name": _mission_drop_pilot_display_name if not _mission_drop_pilot_display_name.is_empty() else "Unassigned Pilot",
			"portrait_path": _mission_drop_pilot_portrait_path,
			"role_name": "Dropship Pilot",
			"team_id": FRIENDLY_TEAM_ID,
		},
		{
			"secondary_text": _build_mission_dropship_pilot_text(),
		}
	)


func _build_mission_dropship_status_text() -> String:
	if _is_drop_sequence_active():
		match _drop_sequence_phase:
			DROP_SEQUENCE_INBOUND:
				return "Inbound to LZ"
			DROP_SEQUENCE_LANDED:
				return "Landed at LZ"
			DROP_SEQUENCE_UNLOADING:
				return "Dropping %d/%d" % [_drop_sequence_unit_index, _drop_sequence_units.size()]
			DROP_SEQUENCE_OUTBOUND:
				return "Leaving mission map"
			DROP_SEQUENCE_COMPLETE:
				return "Drop complete"
	if not _mission_drop_status_line.is_empty():
		return _mission_drop_status_line
	match _mission_drop_state:
		"waiting":
			return "Holding on mission map"
		"to_mission":
			return "ETA mission map %ds" % _mission_drop_eta_seconds
		"to_fob":
			return "Returning to FOB %ds" % _mission_drop_eta_seconds
		_:
			return "Mission transport offline"


func _build_phase_list_text() -> String:
	if not PHASE_PLANNING_ENABLED:
		return "Phasen geparkt | Befehle laufen als Live-Wegpunktkette"
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("get_phase_list_text"):
		return "Phases P0 PRE | %s" % _get_phase_name()
	return "Phases %s" % String(phase_controller.call("get_phase_list_text"))


func _connect_button(button_path: NodePath, callback: Callable) -> void:
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _connect_named_button(button_path: String, callback: Callable) -> void:
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		return
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _get_target_position() -> Vector2:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return Vector2.ZERO
	return target_marker.global_position


func _build_target_text() -> String:
	var target_position: Vector2 = _get_target_position()
	_last_target_position = target_position
	return _format_world_position(target_position)


func _format_world_position(world_position: Vector2) -> String:
	return "%d, %d" % [int(round(world_position.x)), int(round(world_position.y))]


func _screen_to_world_position(screen_position: Vector2) -> Vector2:
	return Vector2(_primary_view_bridge.call("screen_to_world_position", get_parent(), get_viewport(), screen_position))


func _snap_world_position_to_primary_tile(world_position: Vector2) -> Vector2:
	return Vector2(_primary_view_bridge.call("snap_world_position_to_tile_center", get_parent(), world_position))


func _clamp_world_position_to_viewport(world_position: Vector2) -> Vector2:
	if _get_primary_3d_view() != null:
		var map_bounds: Rect2 = _get_map_world_bounds().grow(128.0)
		if map_bounds.size.x > 0.0 and map_bounds.size.y > 0.0:
			return Vector2(
				clampf(world_position.x, map_bounds.position.x, map_bounds.end.x),
				clampf(world_position.y, map_bounds.position.y, map_bounds.end.y)
			)
		return world_position
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var inverse_transform: Transform2D = canvas_transform.affine_inverse()
	var world_a: Vector2 = inverse_transform * visible_rect.position
	var world_b: Vector2 = inverse_transform * visible_rect.end
	var min_x: float = minf(world_a.x, world_b.x)
	var max_x: float = maxf(world_a.x, world_b.x)
	var min_y: float = minf(world_a.y, world_b.y)
	var max_y: float = maxf(world_a.y, world_b.y)
	return Vector2(
		clampf(world_position.x, min_x, max_x),
		clampf(world_position.y, min_y, max_y)
	)


func _get_primary_3d_view():
	return _primary_view_bridge.call("get_primary_view", get_parent())


func _snap_target_to_objective() -> void:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	var objective_marker := get_node_or_null(objective_point_path) as Node2D
	if target_marker == null or objective_marker == null:
		return

	target_marker.global_position = objective_marker.global_position
	_last_target_position = objective_marker.global_position


func _refresh_button_state() -> void:
	var command_buttons: Array = [
		move_button_path,
		defend_button_path,
		flank_button_path,
		take_button_path,
	]
	for button_path in command_buttons:
		var command_button := get_node_or_null(button_path) as BaseButton
		if command_button == null:
			continue
		command_button.disabled = preview_mode or not _can_issue_local_commands() or _selected_fireteam_ids.is_empty()

	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton",
	]:
		var utility_button := get_node_or_null(path) as BaseButton
		if utility_button == null:
			continue
		utility_button.disabled = not _can_edit_planning()

	var call_dropship_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as BaseButton
	if call_dropship_button != null:
		call_dropship_button.disabled = not _can_edit_planning() or not _is_mission_drop_available() or (not preview_mode and _drop_ship_cooldown_remaining > 0.0)

	var next_phase_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton") as BaseButton
	if next_phase_button != null:
		next_phase_button.visible = PHASE_PLANNING_ENABLED
		next_phase_button.disabled = true if not PHASE_PLANNING_ENABLED else preview_mode or not _can_issue_local_commands() or not _has_pending_global_phase()
	_refresh_tactical_stance_panel()


func _refresh_world_overlays() -> void:
	var primary_has_live_drop_state: bool = not _mission_drop_state.is_empty()
	var primary_has_live_drop_sequence: bool = not _drop_sequence_phase.is_empty()
	var dropship_visible: bool = primary_has_live_drop_state or primary_has_live_drop_sequence
	var dropship_position: Vector2 = _drop_sequence_position if primary_has_live_drop_sequence else _get_drop_staging_position()
	_publish_dropship_snapshot_context(
		{
			"visible": dropship_visible,
			"state": _drop_sequence_phase if primary_has_live_drop_sequence else _mission_drop_state,
			"has_lz": _has_lz_position,
			"lz_position": _lz_position,
			"position": dropship_position,
			"target_position": _get_primary_dropship_target_position(dropship_position),
			"progress": _build_mission_dropship_progress_value(),
		}
	)

	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		if _primary_view_bridge.call(
			"sync_mission_drop_visual_state",
			get_parent(),
			{
				"has_lz_position": _has_lz_position,
				"lz_position": _lz_position,
				"dropship_visible": dropship_visible,
				"dropship_position": dropship_position,
				"dropship_target_position": _get_primary_dropship_target_position(dropship_position),
				"dropship_texture": _get_mission_dropship_texture(),
			}
		):
			_refresh_meta_transfer_route_overlay()
			return

	var lz_marker := get_node_or_null("../LZMarker") as Node2D
	if lz_marker != null:
		lz_marker.visible = _has_lz_position
		if _has_lz_position:
			lz_marker.global_position = _lz_position

	var dropship_marker := get_node_or_null("../DropshipPlanMarker") as Node2D
	if dropship_marker != null:
		var has_live_drop_state: bool = not _mission_drop_state.is_empty()
		var has_live_drop_sequence: bool = not _drop_sequence_phase.is_empty()
		if not has_live_drop_state and not has_live_drop_sequence:
			dropship_marker.visible = false
		else:
			var sprite := dropship_marker.get_node_or_null("Sprite") as Sprite2D
			dropship_marker.visible = true
			if has_live_drop_sequence and (_drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_LANDED or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING or _drop_sequence_phase == DROP_SEQUENCE_COMPLETE or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND):
				dropship_marker.global_position = _drop_sequence_position
			elif not _has_lz_position:
				dropship_marker.global_position = _get_drop_staging_position()
			else:
				dropship_marker.global_position = _get_drop_staging_position()
			if sprite != null:
				sprite.texture = _get_mission_dropship_texture()
			var approach_line := dropship_marker.get_node_or_null("ApproachLine") as Line2D
			if approach_line != null:
				approach_line.clear_points()
				var line_delta: Vector2 = _lz_position - dropship_marker.global_position if _has_lz_position else Vector2.ZERO
				if _has_lz_position and line_delta.length_squared() > 4.0:
					approach_line.add_point(Vector2.ZERO)
					approach_line.add_point(line_delta)
	_refresh_meta_transfer_route_overlay()


func _publish_dropship_snapshot_context(dropship_context: Dictionary) -> void:
	var simulation_root := get_node_or_null("../SimulationRoot")
	if simulation_root == null or not simulation_root.has_method("set_multiplayer_snapshot_context"):
		return
	simulation_root.call("set_multiplayer_snapshot_context", {"dropship": dropship_context})


func _sync_primary_3d_mission_status_visuals() -> void:
	if _get_primary_3d_view() == null:
		return
	var payload: Dictionary = {}
	var combat_driver := get_node_or_null("../CombatLoopDriver")
	if combat_driver != null and combat_driver.has_method("get_playability_snapshot"):
		payload = Dictionary(combat_driver.call("get_playability_snapshot")).duplicate(true)
	if payload.is_empty():
		var simulation_root := get_node_or_null("../SimulationRoot")
		var objective_status = simulation_root.call("get_objective_status") if simulation_root != null and simulation_root.has_method("get_objective_status") else null
		if objective_status != null:
			payload["objective_position"] = objective_status.position
			payload["objective_capture_radius"] = float(objective_status.capture_radius)
			payload["objective_owner_team_id"] = String(objective_status.owning_team_id)
			payload["objective_capturing_team_id"] = String(objective_status.capturing_team_id)
			payload["objective_capture_progress"] = clampf(float(objective_status.capture_progress), 0.0, 1.0)
			payload["objective_contested"] = bool(objective_status.call("is_contested"))
	if payload.is_empty():
		return
	_primary_view_bridge.call("sync_mission_status_payload", get_parent(), payload)


func _suppress_legacy_2d_readability_overlays() -> void:
	_primary_view_bridge.call("suppress_legacy_readability_overlays", get_parent())


func _ensure_meta_transfer_route_overlay() -> Node2D:
	var mission_root: Node = get_parent()
	if mission_root == null:
		return null
	var overlay := mission_root.get_node_or_null("MetaTransferRouteOverlay") as Node2D
	if overlay != null:
		return overlay
	if not mission_root.is_node_ready():
		call_deferred("_refresh_meta_transfer_route_overlay")
		return null

	overlay = Node2D.new()
	overlay.name = "MetaTransferRouteOverlay"
	overlay.visible = false
	overlay.z_index = 1
	mission_root.add_child(overlay)

	var route_line := Line2D.new()
	route_line.name = "RouteLine"
	route_line.default_color = META_TRANSFER_ROUTE_COLOR
	route_line.width = META_TRANSFER_ROUTE_WIDTH
	overlay.add_child(route_line)

	var homebase_anchor := Polygon2D.new()
	homebase_anchor.name = "HomebaseAnchor"
	homebase_anchor.color = META_TRANSFER_ROUTE_HOMEBASE_COLOR
	homebase_anchor.polygon = PackedVector2Array([
		Vector2(-16.0, 0.0),
		Vector2(0.0, -10.0),
		Vector2(16.0, 0.0),
		Vector2(0.0, 10.0),
	])
	overlay.add_child(homebase_anchor)

	var fob_anchor := Polygon2D.new()
	fob_anchor.name = "FobAnchor"
	fob_anchor.color = META_TRANSFER_ROUTE_FOB_COLOR
	fob_anchor.polygon = PackedVector2Array([
		Vector2(0.0, -12.0),
		Vector2(12.0, 0.0),
		Vector2(0.0, 12.0),
		Vector2(-12.0, 0.0),
	])
	overlay.add_child(fob_anchor)

	var marker_host := Node2D.new()
	marker_host.name = "RouteMarkerHost"
	overlay.add_child(marker_host)
	return overlay


func _refresh_meta_transfer_route_overlay() -> void:
	var overlay := _ensure_meta_transfer_route_overlay()
	if overlay == null:
		return
	var show_overlay: bool = preview_mode and not _meta_transfer_routes.is_empty()
	overlay.visible = show_overlay
	if not show_overlay:
		return

	var route_points: PackedVector2Array = _build_meta_transfer_route_points()
	var route_line := overlay.get_node_or_null("RouteLine") as Line2D
	if route_line != null:
		route_line.clear_points()
		for route_point in route_points:
			route_line.add_point(route_point)

	var homebase_anchor := overlay.get_node_or_null("HomebaseAnchor") as Polygon2D
	if homebase_anchor != null and route_points.size() > 0:
		homebase_anchor.position = route_points[0]

	var fob_anchor := overlay.get_node_or_null("FobAnchor") as Polygon2D
	if fob_anchor != null and route_points.size() > 0:
		fob_anchor.position = route_points[route_points.size() - 1]

	var marker_host := overlay.get_node_or_null("RouteMarkerHost") as Node2D
	if marker_host == null:
		return
	for child in marker_host.get_children():
		marker_host.remove_child(child)
		child.queue_free()

	for route_index in range(_meta_transfer_routes.size()):
		var route_marker := _build_meta_transfer_route_marker(Dictionary(_meta_transfer_routes[route_index]), route_points, route_index)
		if route_marker != null:
			marker_host.add_child(route_marker)


func _build_meta_transfer_route_points() -> PackedVector2Array:
	var fob_anchor: Vector2 = _get_meta_transfer_fob_anchor_position()
	return PackedVector2Array(
		[
			fob_anchor + META_TRANSFER_ROUTE_HOMEBASE_OFFSET,
			fob_anchor + META_TRANSFER_ROUTE_BEND_OFFSET,
			fob_anchor,
		]
	)


func _get_meta_transfer_fob_anchor_position() -> Vector2:
	var spawn_anchor := get_node_or_null("../MapRoot/spawn_alpha") as Node2D
	if spawn_anchor != null:
		return spawn_anchor.global_position
	var objective_marker := get_node_or_null(objective_point_path) as Node2D
	if objective_marker != null:
		return objective_marker.global_position
	return _get_target_position()


func _build_meta_transfer_route_marker(route: Dictionary, route_points: PackedVector2Array, route_index: int) -> Node2D:
	if route.is_empty():
		return null
	var marker := Node2D.new()
	var transfer_id: String = String(route.get("transfer_id", "transfer_%d" % route_index)).strip_edges()
	marker.name = "TransferMarker_%s" % transfer_id
	marker.set_meta("transfer_id", transfer_id)
	marker.set_meta("entry_type", String(route.get("entry_type", "team")).strip_edges().to_lower())
	marker.set_meta("member_count", maxi(int(route.get("member_count", 0)), 0))
	marker.set_meta("eta_seconds", maxi(int(route.get("eta_seconds", 0)), 0))
	marker.set_meta("progress_value", clampf(float(route.get("progress_value", 0.0)), 0.0, 100.0))

	var progress_ratio: float = clampf(float(route.get("progress_value", 0.0)) / 100.0, 0.0, 1.0)
	var route_normal: Vector2 = _sample_meta_transfer_route_normal(route_points, progress_ratio)
	var stagger_index: float = float(route_index % 3) - 1.0
	marker.position = _sample_meta_transfer_route_point(route_points, progress_ratio) + (route_normal * stagger_index * META_TRANSFER_ROUTE_MARKER_OFFSET)

	var icon := Polygon2D.new()
	icon.name = "Icon"
	icon.color = _build_meta_transfer_route_marker_color(String(route.get("entry_type", "team")))
	icon.polygon = _build_meta_transfer_route_marker_polygon(String(route.get("entry_type", "team")))
	marker.add_child(icon)
	return marker


func _build_meta_transfer_route_marker_color(entry_type: String) -> Color:
	return META_TRANSFER_ROUTE_PILOT_COLOR if entry_type.strip_edges().to_lower() == "pilot" else META_TRANSFER_ROUTE_TEAM_COLOR


func _build_meta_transfer_route_marker_polygon(entry_type: String) -> PackedVector2Array:
	if entry_type.strip_edges().to_lower() == "pilot":
		return PackedVector2Array([
			Vector2(0.0, -12.0),
			Vector2(11.0, 6.0),
			Vector2(-11.0, 6.0),
		])
	return PackedVector2Array([
		Vector2(0.0, -11.0),
		Vector2(11.0, 0.0),
		Vector2(0.0, 11.0),
		Vector2(-11.0, 0.0),
	])


func _sample_meta_transfer_route_point(route_points: PackedVector2Array, progress_ratio: float) -> Vector2:
	if route_points.is_empty():
		return Vector2.ZERO
	if route_points.size() == 1:
		return route_points[0]
	var target_ratio: float = clampf(progress_ratio, 0.0, 1.0)
	var segment_lengths: Array = []
	var total_length: float = 0.0
	for segment_index in range(route_points.size() - 1):
		var segment_length: float = route_points[segment_index].distance_to(route_points[segment_index + 1])
		segment_lengths.append(segment_length)
		total_length += segment_length
	if total_length <= 0.001:
		return route_points[route_points.size() - 1]
	var target_distance: float = target_ratio * total_length
	var traversed_distance: float = 0.0
	for segment_index in range(segment_lengths.size()):
		var segment_length: float = float(segment_lengths[segment_index])
		if traversed_distance + segment_length >= target_distance:
			var local_ratio: float = 0.0 if segment_length <= 0.001 else (target_distance - traversed_distance) / segment_length
			return route_points[segment_index].lerp(route_points[segment_index + 1], local_ratio)
		traversed_distance += segment_length
	return route_points[route_points.size() - 1]


func _sample_meta_transfer_route_normal(route_points: PackedVector2Array, progress_ratio: float) -> Vector2:
	if route_points.size() < 2:
		return Vector2.UP
	var target_ratio: float = clampf(progress_ratio, 0.0, 1.0)
	var segment_lengths: Array = []
	var total_length: float = 0.0
	for segment_index in range(route_points.size() - 1):
		var segment_length: float = route_points[segment_index].distance_to(route_points[segment_index + 1])
		segment_lengths.append(segment_length)
		total_length += segment_length
	if total_length <= 0.001:
		return Vector2.UP
	var target_distance: float = target_ratio * total_length
	var traversed_distance: float = 0.0
	for segment_index in range(segment_lengths.size()):
		var segment_length: float = float(segment_lengths[segment_index])
		if traversed_distance + segment_length >= target_distance:
			var direction: Vector2 = (route_points[segment_index + 1] - route_points[segment_index]).normalized()
			var normal: Vector2 = direction.orthogonal().normalized()
			return normal if normal.length_squared() > 0.001 else Vector2.UP
		traversed_distance += segment_length
	return Vector2.UP


func _sanitize_meta_transfer_routes(route_entries: Array) -> Array:
	var sanitized_routes: Array = []
	for route_variant in route_entries:
		if typeof(route_variant) != TYPE_DICTIONARY:
			continue
		var route: Dictionary = Dictionary(route_variant)
		var transfer_id: String = String(route.get("transfer_id", "")).strip_edges()
		if transfer_id.is_empty():
			continue
		sanitized_routes.append(
			{
				"transfer_id": transfer_id,
				"entry_type": String(route.get("entry_type", "team")).strip_edges().to_lower(),
				"progress_value": clampf(float(route.get("progress_value", 0.0)), 0.0, 100.0),
				"eta_seconds": maxi(int(route.get("eta_seconds", 0)), 0),
				"member_count": maxi(int(route.get("member_count", 0)), 0),
				"display_name": String(route.get("display_name", "")).strip_edges(),
			}
		)
	return sanitized_routes


func _serialize_meta_transfer_routes() -> Array:
	var serialized_routes: Array = []
	for route_variant in _meta_transfer_routes:
		if typeof(route_variant) != TYPE_DICTIONARY:
			continue
		serialized_routes.append(Dictionary(route_variant).duplicate(true))
	return serialized_routes


func _apply_compact_mission_control_layout() -> void:
	var top_nav_panel := get_node_or_null("../TacticalUI/TopNavPanel") as Control
	if top_nav_panel != null:
		top_nav_panel.offset_right = 332.0
	for path in [
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton",
	]:
		var nav_button := get_node_or_null(path) as Button
		if nav_button == null:
			continue
		nav_button.custom_minimum_size = Vector2(60.0, 22.0)
		nav_button.add_theme_font_size_override("font_size", 8)
	var nav_timer_label := get_node_or_null("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionTimerLabel") as Label
	if nav_timer_label != null:
		nav_timer_label.custom_minimum_size = Vector2(40.0, 0.0)
	var bottom_dock := get_node_or_null("../TacticalUI/BottomDock") as Control
	if bottom_dock != null:
		bottom_dock.offset_top = -254.0
		bottom_dock.offset_bottom = -6.0
	var strategic_action_row := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow") as HBoxContainer
	if strategic_action_row != null:
		strategic_action_row.alignment = BoxContainer.ALIGNMENT_END
		strategic_action_row.add_theme_constant_override("separation", 4)
	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton",
	]:
		var button := get_node_or_null(path) as Button
		if button == null:
			continue
		button.custom_minimum_size = Vector2(62.0, 22.0)
		button.add_theme_font_size_override("font_size", 8)
	var strategic_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control
	if strategic_panel != null:
		strategic_panel.custom_minimum_size = Vector2(276.0, 170.0)
	var command_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control
	if command_panel != null:
		command_panel.custom_minimum_size = Vector2(296.0, 170.0)
	var fireteam_panel := get_node_or_null(FIRETEAM_PANEL_PATH) as Control
	if fireteam_panel != null:
		fireteam_panel.custom_minimum_size = Vector2(428.0, 170.0)
	var fireteam_mini_panel := get_node_or_null(FIRETEAM_MINI_PANEL_PATH) as Control
	if fireteam_mini_panel != null:
		fireteam_mini_panel.anchor_bottom = 0.0
		fireteam_mini_panel.offset_left = 16.0
		fireteam_mini_panel.offset_top = 84.0
		fireteam_mini_panel.offset_right = 264.0
		fireteam_mini_panel.offset_bottom = 236.0


func _refresh_dynamic_button_styles() -> void:
	for path in [
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton",
		FIRETEAM_ALL_BUTTON_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton",
	]:
		var button := get_node_or_null(path) as Button
		if button != null:
			META_UI_SKIN_SCRIPT.style_tactical_button(button, false)

	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton") as Button, true)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null(FIRETEAM_ALL_BUTTON_PATH) as Button, _is_all_fireteams_selected())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton") as Button, _is_target_placement_armed)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton") as Button, _is_lz_placement_armed)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as Button, _drop_ship_requested)
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton") as Button, PHASE_PLANNING_ENABLED and not preview_mode and _can_issue_local_commands() and not _phase_execution_by_fireteam.is_empty())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/%sButton" % _get_approach_angle_name()) as Button, true)


func _apply_block_labels() -> void:
	var label_text_by_path: Dictionary = {
		"../TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityHeaderLabel": UI_BLOCK_LABELS_SCRIPT.MISSION_LIVE_TACTICAL_GRID,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel": UI_BLOCK_LABELS_SCRIPT.MISSION_COMMAND_MATRIX,
		FIRETEAM_HEADER_LABEL_PATH: UI_BLOCK_LABELS_SCRIPT.MISSION_SELECTED_FIRETEAM,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel": UI_BLOCK_LABELS_SCRIPT.MISSION_CONTROL,
		"../TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel": UI_BLOCK_LABELS_SCRIPT.CHARACTER_OVERLAY,
	}
	for path_variant in label_text_by_path.keys():
		var label := get_node_or_null(String(path_variant)) as Label
		if label != null:
			label.text = String(label_text_by_path[path_variant])


func _apply_hud_skin() -> void:
	for path in [
		"../TacticalUI/MissionIdentityPanel",
		"../TacticalUI/TopNavPanel",
		FIRETEAM_MINI_PANEL_PATH,
		"../TacticalUI/BottomDock",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel",
		FIRETEAM_PANEL_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel",
		"../TacticalUI/CharacterOverlay/OverlayPanel",
	]:
		var panel := get_node_or_null(path) as PanelContainer
		if panel == null:
			continue
		META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")

	META_UI_SKIN_SCRIPT.style_tactical_panel(get_node_or_null("../TacticalUI/TopNavPanel") as PanelContainer, "header")
	META_UI_SKIN_SCRIPT.style_tactical_panel(get_node_or_null("../TacticalUI/MissionIdentityPanel") as PanelContainer, "header")
	META_UI_SKIN_SCRIPT.style_tactical_panel(get_node_or_null("../TacticalUI/BottomDock") as PanelContainer, "panel")

	for path in [
		"../TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityHeaderLabel",
		FIRETEAM_MINI_HEADER_LABEL_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel",
		FIRETEAM_HEADER_LABEL_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel",
		"../TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/OverlayHeaderLabel",
	]:
		META_UI_SKIN_SCRIPT.style_header_label(get_node_or_null(path), 12)

	for path in [
		"../TacticalUI/MissionIdentityPanel/MissionIdentityMargin/MissionIdentityVBox/MissionIdentityBodyLabel",
		command_feedback_label_path,
		hotkey_legend_label_path,
		FIRETEAM_STATUS_LABEL_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel",
	]:
		META_UI_SKIN_SCRIPT.style_body_label(get_node_or_null(path), 10)

	_refresh_dynamic_button_styles()
	_refresh_tactical_stance_panel()
	_refresh_button_state()
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/CharacterOverlay/OverlayPanel/OverlayMargin/OverlayVBox/OverlayHeaderRow/CloseOverlayButton") as Button, false)


func _can_issue_local_commands() -> bool:
	return bool(_command_input_guard.call("can_issue_local_commands", get_node_or_null("../SimulationRoot"), multiplayer))


func _can_edit_planning() -> bool:
	return bool(_command_input_guard.call("can_edit_planning", preview_mode, get_node_or_null("../SimulationRoot"), multiplayer))


func _emit_planning_state_changed() -> void:
	planning_state_changed.emit(get_planning_state())


func get_selected_fireteam_ids() -> PackedStringArray:
	return _selected_fireteam_ids.duplicate()


func _ensure_default_fireteam_selection() -> void:
	if not _selected_fireteam_ids.is_empty():
		return
	_set_selected_fireteams(_get_available_fireteam_ids(), false)


func _ensure_selection_overlay() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("SelectionDragOverlay") != null:
		return

	var selection_overlay := ColorRect.new()
	selection_overlay.name = "SelectionDragOverlay"
	selection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_overlay.visible = false
	selection_overlay.color = Color(0.52, 0.88, 1.0, 0.18)
	selection_overlay.z_index = 20
	tactical_ui.add_child(selection_overlay)


func _ensure_area_order_overlay() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("AreaOrderDragOverlay") != null:
		return

	var area_overlay := ColorRect.new()
	area_overlay.name = "AreaOrderDragOverlay"
	area_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area_overlay.visible = false
	area_overlay.color = Color(0.48, 0.92, 0.54, 0.2)
	area_overlay.z_index = 21
	tactical_ui.add_child(area_overlay)


func _begin_selection_interaction(screen_position: Vector2, ctrl_pressed: bool) -> void:
	_selection_press_active = true
	_selection_drag_active = false
	_selection_press_screen_position = screen_position
	_selection_drag_screen_position = screen_position
	_selection_press_ctrl = ctrl_pressed
	var unit = _find_selectable_unit_at_screen_position(screen_position)
	_selection_press_unit_id = String(unit.call("get_unit_id")) if unit != null else ""
	_update_selection_overlay(Rect2())


func _update_selection_drag(screen_position: Vector2) -> bool:
	if not _selection_press_active or _is_lz_placement_armed or _is_target_placement_armed:
		return false
	if not _selection_press_unit_id.is_empty():
		return false

	_selection_drag_screen_position = screen_position
	if not _selection_drag_active and _selection_press_screen_position.distance_to(screen_position) < SELECTION_DRAG_THRESHOLD:
		return false

	_selection_drag_active = true
	_update_selection_overlay(_build_selection_rect(_selection_press_screen_position, screen_position))
	return true


func _cancel_selection_interaction() -> void:
	if not _selection_press_active and not _selection_drag_active:
		return
	_selection_press_active = false
	_selection_drag_active = false
	_selection_press_unit_id = ""
	_selection_press_ctrl = false
	_update_selection_overlay(Rect2())


func _finish_selection_interaction(screen_position: Vector2) -> bool:
	if not _selection_press_active:
		return false

	var ctrl_pressed: bool = _selection_press_ctrl
	var unit_id: String = _selection_press_unit_id
	var was_dragging: bool = _selection_drag_active
	_selection_press_active = false
	_selection_drag_active = false
	_selection_press_unit_id = ""
	_update_selection_overlay(Rect2())

	if was_dragging:
		_apply_lasso_selection(_build_selection_rect(_selection_press_screen_position, screen_position), ctrl_pressed)
		return true

	if not unit_id.is_empty():
		var unit = _find_friendly_unit_by_id(unit_id)
		if unit != null:
			_apply_unit_click_selection(unit, ctrl_pressed)
			return true

	if not ctrl_pressed:
		_clear_selection()
		return true

	return false


func _apply_unit_click_selection(unit: Node, ctrl_pressed: bool) -> void:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return
	_set_selected_fireteams(PackedStringArray(_selection_adapter.call("build_unit_click_selection", _selected_fireteam_ids, fireteam_id, ctrl_pressed)))


func _apply_lasso_selection(selection_rect: Rect2, ctrl_pressed: bool) -> void:
	var lasso_fireteam_ids: PackedStringArray = []
	for fireteam_id in _get_available_fireteam_ids():
		var unit: Node2D = _get_selection_anchor_for_fireteam(fireteam_id)
		if unit == null:
			continue
		var screen_pos: Vector2 = Vector2(_primary_view_bridge.call("world_to_screen_position", get_parent(), get_viewport(), (unit as Node2D).global_position))
		if not selection_rect.has_point(screen_pos):
			continue
		if lasso_fireteam_ids.has(fireteam_id):
			continue
		lasso_fireteam_ids.append(fireteam_id)

	_set_selected_fireteams(PackedStringArray(_selection_adapter.call("merge_lasso_selection", _selected_fireteam_ids, lasso_fireteam_ids, ctrl_pressed)))


func _clear_selection() -> void:
	_set_selected_fireteams(PackedStringArray())


func _set_selected_fireteams(next_selected_fireteam_ids: PackedStringArray, should_emit_signal: bool = true) -> void:
	_selected_fireteam_ids = _sanitize_fireteam_ids(next_selected_fireteam_ids)
	_current_fireteam_index = 0
	var selection_options: Array = _get_fireteam_selection_options()
	for option_index in range(selection_options.size()):
		var option_ids := PackedStringArray(Array((selection_options[option_index] as Dictionary).get("ids", [])))
		if _selection_ids_match(option_ids, _selected_fireteam_ids):
			_current_fireteam_index = option_index
			break
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_button_state()
	_refresh_tactical_stance_panel()
	_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()


func _refresh_selection_visuals() -> void:
	_selection_adapter.call("apply_unit_selection", _get_all_friendly_units(true), _selected_fireteam_ids)


func _sync_unit_tactical_stance_badges() -> void:
	var sync_state: Dictionary = get_tactical_stance_sync_state()
	var stance_revision: int = maxi(int(sync_state.get("revision", 0)), 0)
	for unit in _get_all_friendly_units(true):
		if unit == null or not unit.has_method("set_tactical_stance_indicator") or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		unit.call("set_tactical_stance_indicator", get_requested_tactical_stance(fireteam_id), stance_revision)


func _get_all_friendly_units(include_hidden: bool = true) -> Array:
	var mission_root: Node = get_parent()
	if mission_root == null:
		return []

	var result: Array = []
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id") or not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		if not include_hidden and child is CanvasItem and not (child as CanvasItem).visible and not _embarked_unit_ids.has(String(child.call("get_unit_id"))):
			continue
		result.append(child)

	result.sort_custom(Callable(self, "_sort_unit_nodes_for_cards"))
	return result


func _get_all_enemy_units(include_hidden: bool = true) -> Array:
	var mission_root: Node = get_parent()
	if mission_root == null:
		return []
	var result: Array = []
	for child in mission_root.get_children():
		if not child.has_method("get_team_id") or not child.has_method("get_unit_id"):
			continue
		if String(child.call("get_team_id")).strip_edges() == FRIENDLY_TEAM_ID:
			continue
		if not include_hidden and child is CanvasItem and not (child as CanvasItem).visible:
			continue
		result.append(child)
	return result


func _sync_initial_runtime_active_units() -> void:
	var unit_registry = get_node_or_null("../UnitRegistry")
	if unit_registry == null:
		return
	for unit in _get_all_friendly_units(true):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty() or _embarked_unit_ids.has(unit_id):
			continue
		var is_registered: bool = false
		if unit_registry.has_method("has_unit"):
			is_registered = bool(unit_registry.call("has_unit", unit_id))
		elif unit_registry.has_method("get_unit"):
			is_registered = unit_registry.call("get_unit", unit_id) != null
		if is_registered:
			_deployed_unit_ids[unit_id] = true


func _get_fireteam_units(fireteam_id: String, include_hidden: bool = true) -> Array:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return []
	var result: Array = []
	for unit in _get_all_friendly_units(include_hidden):
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		result.append(unit)
	return result


func _resolve_fireteam_leader_for_behavior(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var mission_combat_driver = _get_mission_combat_loop_driver()
	if mission_combat_driver != null and mission_combat_driver.has_method("get_current_fireteam_lead_unit"):
		var active_lead = mission_combat_driver.call("get_current_fireteam_lead_unit", normalized_fireteam_id)
		if active_lead != null:
			return active_lead
	var mission_root: Node = get_parent()
	if mission_root == null:
		return _get_selection_anchor_for_fireteam(normalized_fireteam_id)
	var best_unit = null
	var best_leadership: float = -1.0
	for unit in mission_root.get_children():
		if unit == null or not unit.has_method("get_team_id") or not unit.has_method("get_fireteam_id"):
			continue
		if String(unit.call("get_team_id")).strip_edges() != FRIENDLY_TEAM_ID:
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		var is_fit: bool = not unit.has_method("get_vital_state") or String(unit.call("get_vital_state")) == "fit"
		if not is_fit:
			continue
		if bool(unit.get("is_fireteam_lead")):
			return unit
		var leadership: float = float(unit.call("get_leadership_skill")) if unit.has_method("get_leadership_skill") else 0.0
		if leadership > best_leadership:
			best_leadership = leadership
			best_unit = unit
	if best_unit != null:
		return best_unit
	return _get_selection_anchor_for_fireteam(normalized_fireteam_id)


func _get_mission_combat_loop_driver():
	return get_node_or_null("../MissionCombatLoopDriver")


func _is_unit_current_fireteam_lead(unit: Node) -> bool:
	if unit == null or not unit.has_method("get_fireteam_id") or not unit.has_method("get_unit_id"):
		return false
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return false
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	if leader == null or not leader.has_method("get_unit_id"):
		return bool(unit.get("is_fireteam_lead"))
	return String(leader.call("get_unit_id")) == String(unit.call("get_unit_id"))


func _initialize_fireteam_suppression_state() -> void:
	_suppression_state_by_fireteam.clear()
	_suppression_interrupt_pending_by_fireteam.clear()
	_suppression_near_miss_ready_at_msec_by_fireteam.clear()
	_tracked_health_by_unit_id.clear()
	for fireteam_id in _get_available_fireteam_ids():
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		_suppression_state_by_fireteam[normalized_fireteam_id] = {
			"value": 0.0,
			"threshold": 1.0,
			"is_suppressed": false,
			"is_heavily_suppressed": false,
			"applied_level": 0,
			"hold_until_msec": 0,
		}
		_suppression_interrupt_pending_by_fireteam[normalized_fireteam_id] = false
		_suppression_near_miss_ready_at_msec_by_fireteam[normalized_fireteam_id] = 0
		for unit in _get_fireteam_units(normalized_fireteam_id, true):
			if unit == null or not unit.has_method("get_unit_id"):
				continue
			var health_points: int = _get_unit_health_points(unit)
			if health_points < 0:
				continue
			_tracked_health_by_unit_id[String(unit.call("get_unit_id"))] = health_points


func _update_fireteam_suppression(delta: float) -> void:
	if preview_mode:
		return
	if _suppression_state_by_fireteam.is_empty():
		_initialize_fireteam_suppression_state()
	var now_msec: int = Time.get_ticks_msec()
	for fireteam_id in _get_available_fireteam_ids():
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		var state: Dictionary = Dictionary(_suppression_state_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
		if state.is_empty():
			continue
		var units: Array = _get_fireteam_units(normalized_fireteam_id, true)
		var leader = _resolve_fireteam_leader_for_behavior(normalized_fireteam_id)
		var leadership: float = float(leader.call("get_leadership_skill")) if leader != null and leader.has_method("get_leadership_skill") else 0.0
		var trait_ids: PackedStringArray = PackedStringArray(leader.call("get_trait_ids")) if leader != null and leader.has_method("get_trait_ids") else PackedStringArray()
		var threshold: float = _resolve_suppression_threshold(normalized_fireteam_id)
		if trait_ids.has("reckless"):
			threshold *= 1.8
		state["threshold"] = threshold
		var suppression_gain: float = _compute_suppression_gain_from_damage(units)
		if _is_fireteam_in_combat(normalized_fireteam_id) and now_msec >= int(_suppression_near_miss_ready_at_msec_by_fireteam.get(normalized_fireteam_id, 0)):
			suppression_gain += SUPPRESSION_NEAR_MISS_GAIN
			_suppression_near_miss_ready_at_msec_by_fireteam[normalized_fireteam_id] = now_msec + SUPPRESSION_NEAR_MISS_INTERVAL_MSEC
		var decay_per_second: float = SUPPRESSION_BASE_DECAY_PER_SECOND * (1.0 + clampf(leadership, 0.0, 1.0))
		if trait_ids.has("calm"):
			decay_per_second *= 2.0
		var next_value: float = maxf(float(state.get("value", 0.0)) + suppression_gain - (decay_per_second * delta), 0.0)
		state["value"] = next_value
		var was_suppressed: bool = bool(state.get("is_suppressed", false))
		var was_heavy: bool = bool(state.get("is_heavily_suppressed", false))
		var hold_until_msec: int = int(state.get("hold_until_msec", 0))
		var threshold_triggered: bool = next_value >= threshold
		if threshold_triggered and not was_suppressed:
			hold_until_msec = now_msec + SUPPRESSION_MIN_HOLD_MSEC
		var is_suppressed: bool = threshold_triggered or now_msec < hold_until_msec
		var is_heavy: bool = next_value >= threshold * 1.8
		state["is_suppressed"] = is_suppressed
		state["is_heavily_suppressed"] = is_heavy
		state["hold_until_msec"] = hold_until_msec if is_suppressed else 0
		_suppression_state_by_fireteam[normalized_fireteam_id] = state
		if is_suppressed and not _should_ignore_suppression(normalized_fireteam_id):
			_interrupt_plan_for_suppression(normalized_fireteam_id)
		if (was_suppressed != is_suppressed) or (was_heavy != is_heavy):
			_notify_suppression_changed(normalized_fireteam_id, state)
		_apply_suppression_effects_for_fireteam(normalized_fireteam_id, state)
		if (was_suppressed or was_heavy) and not is_suppressed:
			_try_auto_resume_after_suppression(normalized_fireteam_id)


func _resolve_suppression_threshold(fireteam_id: String) -> float:
	var profile_dict: Dictionary = get_active_behavior_profile(fireteam_id)
	var base_threshold: float = 2.0
	if not profile_dict.is_empty():
		base_threshold = maxf(float(profile_dict.get("suppression_threshold", 2.0)), 1.0)
	var flank_state: Dictionary = get_fireteam_flank_vulnerability_state(fireteam_id)
	if bool(flank_state.get("is_active", false)) or bool(flank_state.get("is_morale_active", false)):
		base_threshold = maxf(base_threshold * float(flank_state.get("effective_suppression_threshold_multiplier", flank_state.get("suppression_threshold_multiplier", 1.0))), 1.0)
	return base_threshold


func _compute_suppression_gain_from_damage(units: Array) -> float:
	var gain: float = 0.0
	for unit in units:
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		var current_health: int = _get_unit_health_points(unit)
		if current_health < 0:
			continue
		var previous_health: int = int(_tracked_health_by_unit_id.get(unit_id, current_health))
		_tracked_health_by_unit_id[unit_id] = current_health
		if current_health >= previous_health:
			continue
		gain += SUPPRESSION_HIT_GAIN + (float(previous_health - current_health) / 100.0)
	return gain


func _get_unit_health_points(unit: Node) -> int:
	if unit == null:
		return -1
	if unit.has_method("get_health_points"):
		return int(unit.call("get_health_points"))
	if unit.has_method("get_health"):
		return int(unit.call("get_health"))
	return -1


func _should_ignore_suppression(fireteam_id: String) -> bool:
	_ensure_ad_hoc_order_controller()
	if _ad_hoc_order_controller == null:
		return false
	var active_order: Dictionary = Dictionary(_ad_hoc_order_controller.call("get_active_order", fireteam_id))
	return String(active_order.get("order_type", "")) == AD_HOC_ORDER_SCRIPT.ORDER_TYPE_HOLD_TILL_LAST_MAN


func _interrupt_plan_for_suppression(fireteam_id: String) -> void:
	var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(fireteam_id, {}))
	if execution_state.is_empty():
		return
	var phase_index: int = int(execution_state.get("phase", _current_phase_index))
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, phase_index), null)
	if plan == null:
		return
	var waypoint_index: int = int(execution_state.get("waypoint_index", -1))
	if waypoint_index >= 0 and waypoint_index < plan.waypoints.size():
		plan.waypoints[waypoint_index].status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_INTERRUPTED
	_phase_execution_by_fireteam.erase(fireteam_id)
	_area_defense_execution_by_fireteam.erase(fireteam_id)
	_area_attack_execution_by_fireteam.erase(fireteam_id)
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	_suppression_interrupt_pending_by_fireteam[fireteam_id] = true


func _apply_suppression_effects_for_fireteam(fireteam_id: String, suppression_state: Dictionary) -> void:
	if _should_ignore_suppression(fireteam_id):
		return
	var suppression_level: int = 0
	if bool(suppression_state.get("is_heavily_suppressed", false)):
		suppression_level = 2
	elif bool(suppression_state.get("is_suppressed", false)):
		suppression_level = 1
	var previously_applied: int = int(suppression_state.get("applied_level", 0))
	if suppression_level == previously_applied:
		return
	for unit in _get_fireteam_units(fireteam_id, true):
		if unit == null or not unit.has_method("get_runtime_status") or not unit.has_method("set_runtime_status"):
			continue
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status == null:
			continue
		var next_move_speed_factor: float = float(runtime_status.move_speed_factor)
		var next_fire_status: String = String(runtime_status.fire_status)
		var next_cover_score: float = float(runtime_status.cover_score)
		var next_attack_bonus: float = float(runtime_status.attack_bonus)
		if suppression_level == 2:
			next_move_speed_factor = SUPPRESSION_HEAVY_MOVE_FACTOR
			next_fire_status = "semi_disciplined"
			next_cover_score = maxf(next_cover_score, SUPPRESSION_COVER_BONUS)
			next_attack_bonus = SUPPRESSION_HIT_CHANCE_MALUS
		elif suppression_level == 1:
			next_move_speed_factor = minf(next_move_speed_factor, SUPPRESSION_MOVE_FACTOR)
			next_fire_status = "semi_disciplined"
			next_cover_score = maxf(next_cover_score, SUPPRESSION_COVER_BONUS)
			next_attack_bonus = SUPPRESSION_HIT_CHANCE_MALUS
		unit.call(
			"set_runtime_status",
			String(runtime_status.status),
			String(runtime_status.active_command_type),
			int(runtime_status.priority),
			next_fire_status,
			String(runtime_status.source_command_type),
			next_move_speed_factor,
			next_cover_score,
			next_attack_bonus,
			int(runtime_status.phase),
			runtime_status.target_position
		)
	var next_state := suppression_state.duplicate(true)
	next_state["applied_level"] = suppression_level
	_suppression_state_by_fireteam[fireteam_id] = next_state


func _try_auto_resume_after_suppression(fireteam_id: String) -> void:
	if not bool(_suppression_interrupt_pending_by_fireteam.get(fireteam_id, false)):
		return
	_suppression_interrupt_pending_by_fireteam[fireteam_id] = false
	_return_fireteam_to_plan(fireteam_id, false)


func _notify_suppression_changed(fireteam_id: String, suppression_state: Dictionary) -> void:
	var event_router = get_node_or_null("../EventRouter")
	if event_router != null and event_router.has_method("notify_suppression_changed"):
		event_router.call("notify_suppression_changed", fireteam_id, suppression_state)
	if event_router != null and event_router.has_method("notify_threat_detected"):
		event_router.call(
			"notify_threat_detected",
			self,
			{
				"type": "suppression_changed",
				"fireteam_id": fireteam_id,
				"value": float(suppression_state.get("value", 0.0)),
				"threshold": float(suppression_state.get("threshold", 1.0)),
				"is_suppressed": bool(suppression_state.get("is_suppressed", false)),
				"is_heavily_suppressed": bool(suppression_state.get("is_heavily_suppressed", false)),
				}
			)


func _update_leader_initiated_flanks() -> void:
	_ensure_ad_hoc_order_controller()
	var now_msec: int = Time.get_ticks_msec()
	for fireteam_id in _get_available_fireteam_ids():
		var normalized_fireteam_id: String = String(fireteam_id).strip_edges().to_lower()
		if not _is_fireteam_in_combat(normalized_fireteam_id):
			continue
		if _ad_hoc_order_controller != null and bool(_ad_hoc_order_controller.call("has_active_order", normalized_fireteam_id)):
			continue
		if now_msec < int(_leader_initiated_flank_ready_at_msec_by_fireteam.get(normalized_fireteam_id, 0)):
			continue
		var leader = _resolve_fireteam_leader_for_behavior(normalized_fireteam_id)
		if leader == null:
			continue
		var leadership: float = float(leader.call("get_leadership_skill")) if leader.has_method("get_leadership_skill") else 0.0
		if leadership <= 0.7:
			continue
		var trait_ids: PackedStringArray = PackedStringArray(leader.call("get_trait_ids")) if leader.has_method("get_trait_ids") else PackedStringArray()
		if not (trait_ids.has("aggressive") or trait_ids.has("reckless")):
			continue
		var flank_target_position: Vector2 = _resolve_autonomous_flank_target(normalized_fireteam_id, leader)
		if flank_target_position == Vector2.INF:
			continue
		if not _interrupt_active_plan_for_ad_hoc(normalized_fireteam_id):
			continue
		if not _start_ad_hoc_order_for_fireteam(normalized_fireteam_id, "flank", flank_target_position):
			continue
		_leader_initiated_flank_ready_at_msec_by_fireteam[normalized_fireteam_id] = now_msec + int(LEADER_INITIATED_FLANK_COOLDOWN_SECONDS * 1000.0)
		var event_router = get_node_or_null("../EventRouter")
		if event_router != null and event_router.has_method("notify_leader_initiated_flank"):
			event_router.call(
				"notify_leader_initiated_flank",
				normalized_fireteam_id,
				leader,
				{
					"fireteam_id": normalized_fireteam_id,
					"leader_unit_id": String(leader.call("get_unit_id")) if leader.has_method("get_unit_id") else "",
					"target_position": flank_target_position,
					"trigger": "autonomous_leader_flank",
				}
			)
		_refresh_order_visuals()
		_update_ui()


func _resolve_autonomous_flank_target(_fireteam_id: String, leader) -> Vector2:
	if leader == null or not (leader is Node2D):
		return Vector2.INF
	var contact_target_id: String = String(leader.call("get_contact_target_id")) if leader.has_method("get_contact_target_id") else ""
	if contact_target_id.is_empty():
		return Vector2.INF
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		return Vector2.INF
	var leader_position: Vector2 = (leader as Node2D).global_position
	var cover_tiles: Array = terrain_registry.call("get_walkable_cover_tiles_in_radius", leader_position, 140.0)
	var best_score: float = -INF
	var best_position: Vector2 = Vector2.INF
	for tile in cover_tiles:
		if tile == null:
			continue
		var tile_position: Vector2 = Vector2(tile.world_position)
		var cover_value: float = float(tile.cover_value)
		if cover_value < 40.0:
			continue
		var offset_distance: float = tile_position.distance_to(leader_position)
		if offset_distance < 36.0:
			continue
		var score: float = cover_value - (offset_distance * 0.08)
		if score <= best_score:
			continue
		best_score = score
		best_position = tile_position
	return best_position


func _find_selectable_unit_at_screen_position(screen_position: Vector2) -> Node:
	var world_position: Vector2 = _screen_to_world_position(screen_position)
	var best_unit: Node = null
	var best_distance_sq: float = UNIT_SELECTION_PICK_RADIUS * UNIT_SELECTION_PICK_RADIUS
	for unit in _get_all_friendly_units(false):
		if not (unit is Node2D):
			continue
		var distance_sq: float = (unit as Node2D).global_position.distance_squared_to(world_position)
		if distance_sq > best_distance_sq:
			continue
		best_distance_sq = distance_sq
		best_unit = unit
	return best_unit


func _get_selection_anchor_for_fireteam(fireteam_id: String) -> Node2D:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null

	var first_match: Node2D = null
	for unit in _get_all_friendly_units(true):
		if not (unit is Node2D):
			continue
		if String(unit.call("get_fireteam_id")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		if first_match == null:
			first_match = unit as Node2D
		if _is_unit_current_fireteam_lead(unit):
			return unit as Node2D

	return first_match


func _is_all_fireteams_selected() -> bool:
	var available_fireteam_ids: PackedStringArray = _get_available_fireteam_ids()
	if available_fireteam_ids.is_empty() or _selected_fireteam_ids.is_empty():
		return false
	for fireteam_id in available_fireteam_ids:
		if not _selected_fireteam_ids.has(fireteam_id):
			return false
	return true


func _get_available_fireteam_ids() -> PackedStringArray:
	var available_fireteam_ids: PackedStringArray = []
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup != null:
		for fireteam_id_variant in PackedStringArray(mission_setup.get("selected_team_fireteam_ids")):
			var configured_fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
			if configured_fireteam_id.is_empty() or available_fireteam_ids.has(configured_fireteam_id):
				continue
			available_fireteam_ids.append(configured_fireteam_id)
	for unit in _get_all_friendly_units(true):
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty() or available_fireteam_ids.has(fireteam_id):
			continue
		available_fireteam_ids.append(fireteam_id)
	return available_fireteam_ids


func _get_displayable_fireteam_ids() -> PackedStringArray:
	if not _use_visible_units_for_fireteam_ui():
		return _get_available_fireteam_ids()
	var displayable_fireteam_ids: PackedStringArray = []
	for unit in _get_all_friendly_units(false):
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty() or displayable_fireteam_ids.has(fireteam_id):
			continue
		displayable_fireteam_ids.append(fireteam_id)
	return displayable_fireteam_ids


func _use_visible_units_for_fireteam_ui() -> bool:
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup == null:
		return false
	return bool(mission_setup.get("defer_friendly_runtime_activation"))


func _sanitize_fireteam_ids(raw_fireteam_ids: PackedStringArray) -> PackedStringArray:
	var normalized_input: PackedStringArray = []
	for fireteam_id_variant in raw_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or normalized_input.has(fireteam_id):
			continue
		normalized_input.append(fireteam_id)
	var available_fireteam_ids: PackedStringArray = _get_available_fireteam_ids()
	if available_fireteam_ids.is_empty():
		return normalized_input
	var result: PackedStringArray = []
	for fireteam_id in available_fireteam_ids:
		if normalized_input.has(fireteam_id):
			result.append(fireteam_id)
	return result


func _selection_ids_for_index(index: int) -> PackedStringArray:
	var selection_options: Array = _get_fireteam_selection_options()
	if selection_options.is_empty():
		return PackedStringArray()
	var wrapped_index: int = wrapi(index, 0, selection_options.size())
	return PackedStringArray(Array(selection_options[wrapped_index].get("ids", [])))


func _get_fireteam_selection_options() -> Array:
	var available_fireteam_ids: PackedStringArray = _get_available_fireteam_ids()
	if available_fireteam_ids.is_empty():
		return []
	var options: Array = [
		{
			"name": ALL_FIRETEAM_LABEL,
			"ids": Array(available_fireteam_ids),
		}
	]
	for fireteam_id in available_fireteam_ids:
		options.append(
			{
				"name": _get_fireteam_display_label(String(fireteam_id)),
				"ids": [String(fireteam_id)],
				"fireteam_id": String(fireteam_id),
			}
		)
	return options


func _find_fireteam_selection_index_by_name(fireteam_name: String) -> int:
	var normalized_name: String = fireteam_name.strip_edges().to_upper()
	var selection_options: Array = _get_fireteam_selection_options()
	for option_index in range(selection_options.size()):
		var option: Dictionary = selection_options[option_index]
		if String(option.get("name", "")).strip_edges().to_upper() == normalized_name:
			return option_index
		var option_ids := PackedStringArray(Array(option.get("ids", [])))
		if option_ids.size() == 1 and String(option_ids[0]).strip_edges().to_upper() == normalized_name:
			return option_index
	if normalized_name == "BLUE" and selection_options.size() > 1:
		return 1
	if normalized_name == "GOLD" and selection_options.size() > 2:
		return 2
	return -1


func _selection_ids_match(left_ids: PackedStringArray, right_ids: PackedStringArray) -> bool:
	if left_ids.size() != right_ids.size():
		return false
	for fireteam_id in left_ids:
		if not right_ids.has(fireteam_id):
			return false
	return true


func _is_unit_selected(unit: Node) -> bool:
	if unit == null or not unit.has_method("get_fireteam_id"):
		return false
	return _selected_fireteam_ids.has(String(unit.call("get_fireteam_id")).strip_edges().to_lower())


func _build_selection_rect(start_position: Vector2, end_position: Vector2) -> Rect2:
	var top_left := Vector2(minf(start_position.x, end_position.x), minf(start_position.y, end_position.y))
	var size := Vector2(absf(end_position.x - start_position.x), absf(end_position.y - start_position.y))
	return Rect2(top_left, size)


func _update_selection_overlay(selection_rect: Rect2) -> void:
	var overlay := get_node_or_null("../TacticalUI/SelectionDragOverlay") as ColorRect
	if overlay == null:
		return
	if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
		overlay.visible = false
		return
	overlay.position = selection_rect.position
	overlay.size = selection_rect.size
	overlay.visible = true


func _update_area_order_overlay(selection_rect: Rect2) -> void:
	var overlay := get_node_or_null("../TacticalUI/AreaOrderDragOverlay") as ColorRect
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer != null and visualizer.has_method("set_area_order_preview_payload"):
		if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
			visualizer.call("set_area_order_preview_payload", {})
		else:
			var preview_payload: Dictionary = _build_area_order_payload_from_screen_rect(selection_rect)
			if not preview_payload.is_empty():
				visualizer.call("set_area_order_preview_payload", preview_payload)
				if overlay != null:
					overlay.visible = false
				return
			visualizer.call("set_area_order_preview_payload", {})
	if overlay == null:
		return
	if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
		overlay.visible = false
		return
	overlay.position = selection_rect.position
	overlay.size = selection_rect.size
	overlay.visible = true


func get_order_plans_snapshot() -> Array:
	return _serialize_order_plans()


func get_area_orders_snapshot() -> Array:
	return _serialize_area_orders()


func get_visualized_waypoints_snapshot() -> Array:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_visible_waypoints"):
		return []
	return Array(visualizer.call("get_visible_waypoints"))


func get_visualized_area_orders_snapshot() -> Array:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_visible_area_orders"):
		return []
	return Array(visualizer.call("get_visible_area_orders"))


func get_active_ad_hoc_orders_snapshot() -> Array:
	_ensure_ad_hoc_order_controller()
	if _ad_hoc_order_controller == null:
		return []
	return Array(_ad_hoc_order_controller.call("get_active_orders_snapshot"))


func _ensure_waypoint_command_menu() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("WaypointCommandMenu") != null:
		return

	var menu := PopupMenu.new()
	menu.name = "WaypointCommandMenu"
	menu.hide_on_checkable_item_selection = true
	menu.hide_on_item_selection = true
	if not menu.id_pressed.is_connected(_on_waypoint_menu_id_pressed):
		menu.id_pressed.connect(_on_waypoint_menu_id_pressed)
	tactical_ui.add_child(menu)


func _ensure_area_order_command_menu() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui == null or tactical_ui.get_node_or_null("AreaOrderCommandMenu") != null:
		return

	var menu := PopupMenu.new()
	menu.name = "AreaOrderCommandMenu"
	menu.hide_on_checkable_item_selection = true
	menu.hide_on_item_selection = true
	if not menu.id_pressed.is_connected(_on_area_order_menu_id_pressed):
		menu.id_pressed.connect(_on_area_order_menu_id_pressed)
	tactical_ui.add_child(menu)


func _ensure_ad_hoc_order_controller() -> void:
	if _ad_hoc_order_controller != null:
		return
	_ad_hoc_order_controller = AD_HOC_ORDER_CONTROLLER_SCRIPT.new()


func _ensure_area_order_resolver() -> void:
	if _area_order_resolver != null:
		return
	_area_order_resolver = AREA_ORDER_RESOLVER_SCRIPT.new()


func _ensure_tactical_stance_controller() -> void:
	if _tactical_stance_controller != null:
		return
	_tactical_stance_controller = TACTICAL_STANCE_CONTROLLER_SCRIPT.new()


func _ensure_coordination_manager() -> void:
	if _coordination_manager != null:
		return
	_coordination_manager = FIRETEAM_COORDINATION_MANAGER_SCRIPT.new()


func _ensure_fireteam_movement_controller() -> void:
	if _fireteam_movement_controller != null:
		return
	_fireteam_movement_controller = FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT.new()


func _ensure_fireteam_security_controller() -> void:
	if _fireteam_security_controller != null:
		return
	_fireteam_security_controller = FIRETEAM_SECURITY_CONTROLLER_SCRIPT.new()


func _ensure_order_visualizer() -> void:
	var mission_root := get_parent()
	if mission_root == null or mission_root.get_node_or_null("FireteamOrderVisualizer") != null or _order_visualizer_pending:
		return

	var visualizer = FIRETEAM_ORDER_VISUALIZER_SCRIPT.new()
	visualizer.name = "FireteamOrderVisualizer"
	visualizer.z_index = 5
	_order_visualizer_pending = true
	mission_root.call_deferred("add_child", visualizer)
	call_deferred("_finalize_order_visualizer_attach")


func _finalize_order_visualizer_attach() -> void:
	_order_visualizer_pending = false
	_refresh_order_visuals()


func _ensure_contact_map_overlay() -> void:
	var mission_root := get_parent()
	if mission_root == null or mission_root.get_node_or_null("ContactMapOverlay") != null or _contact_overlay_pending:
		return
	var overlay = CONTACT_MAP_OVERLAY_SCRIPT.new()
	overlay.name = "ContactMapOverlay"
	overlay.z_index = 6
	_contact_overlay_pending = true
	mission_root.call_deferred("add_child", overlay)
	call_deferred("_finalize_contact_map_overlay_attach")


func _finalize_contact_map_overlay_attach() -> void:
	_contact_overlay_pending = false
	refresh_contact_overlay()


func _refresh_order_visuals() -> void:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null:
		_sync_primary_3d_order_visuals()
		refresh_contact_overlay()
		return
	if visualizer is CanvasItem:
		_primary_view_bridge.call("hide_canvas_item_when_primary", get_parent(), visualizer as CanvasItem)
	visualizer.call("set_phase_index", _get_live_order_phase_index())
	visualizer.call("set_selected_fireteam_ids", _selected_fireteam_ids)
	if visualizer.has_method("set_fireteam_anchor_dicts"):
		visualizer.call("set_fireteam_anchor_dicts", _build_fireteam_anchor_visualization_entries())
	visualizer.call("set_plan_dicts", _serialize_order_plans())
	if visualizer.has_method("set_area_order_dicts"):
		visualizer.call("set_area_order_dicts", _serialize_area_orders())
	visualizer.call("set_ad_hoc_order_dicts", _build_ad_hoc_visualization_entries())
	visualizer.call("set_security_dicts", get_fireteam_security_snapshot())
	_sync_primary_3d_order_visuals()
	refresh_contact_overlay()


func refresh_contact_overlay() -> void:
	var overlay := get_node_or_null("../ContactMapOverlay")
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		_primary_view_bridge.call("sync_contact_entries", get_parent(), get_contact_snapshot(), _selected_fireteam_ids)
	if overlay == null:
		return
	if overlay is CanvasItem:
		_primary_view_bridge.call("hide_canvas_item_when_primary", get_parent(), overlay as CanvasItem)
	overlay.call("set_selected_fireteam_ids", _selected_fireteam_ids)
	overlay.call("set_contact_entries", get_contact_snapshot())


func _sync_primary_3d_order_visuals() -> void:
	if _get_primary_3d_view() == null:
		return
	_primary_view_bridge.call(
		"sync_order_visual_payload",
		get_parent(),
		{
			"phase_index": _get_live_order_phase_index(),
			"selected_fireteam_ids": _selected_fireteam_ids,
			"fireteam_anchors": _build_fireteam_anchor_visualization_entries(),
			"plan_dicts": _serialize_order_plans(),
			"area_order_dicts": _serialize_area_orders(),
			"ad_hoc_order_dicts": _build_ad_hoc_visualization_entries(),
			"security_dicts": get_fireteam_security_snapshot(),
		}
	)


func refresh_flank_vulnerability_state() -> void:
	_refresh_fireteam_status_panel()
	_update_ui()


func _try_open_waypoint_menu_at_position(screen_position: Vector2) -> bool:
	var existing_target: Dictionary = _find_waypoint_target_at_screen_position(screen_position)
	if not existing_target.is_empty():
		_focused_waypoint_ref = existing_target.duplicate(true)
		_open_waypoint_command_menu(screen_position, [existing_target], true)
		return true
	var existing_area_order_target: Dictionary = _find_area_order_target_at_screen_position(screen_position)
	if not existing_area_order_target.is_empty():
		_focused_area_order_ref = existing_area_order_target.duplicate(true)
		_open_area_order_command_menu(screen_position, [existing_area_order_target], true)
		return true

	if _selected_fireteam_ids.is_empty():
		_last_command_text = "SELECT FIRETEAM FIRST"
		_update_ui()
		return false

	var waypoint_targets: Array = _create_waypoints_for_selected_fireteams(_clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
	if waypoint_targets.is_empty():
		return false
	_focused_waypoint_ref = Dictionary(waypoint_targets[0]).duplicate(true)
	_open_waypoint_command_menu(screen_position, waypoint_targets, false)
	_last_command_text = "WAYPOINT ADDED (%s)" % _get_phase_name()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _create_waypoints_for_selected_fireteams(world_position: Vector2) -> Array:
	var waypoint_targets: Array = []
	var snapped_world_position: Vector2 = _snap_planning_position_to_tile_center(world_position)
	for fireteam_id in _selected_fireteam_ids:
		var waypoint_target: Dictionary = _append_waypoint_to_plan(String(fireteam_id), _get_live_order_phase_index(), snapped_world_position)
		if waypoint_target.is_empty():
			continue
		waypoint_targets.append(waypoint_target)
	_refresh_order_visuals()
	return waypoint_targets


func create_area_order_for_selected_fireteams_from_world_rect(start_world_position: Vector2, end_world_position: Vector2, command_type: String = AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND) -> Array:
	return create_area_order_for_fireteams_from_world_rect(_selected_fireteam_ids, start_world_position, end_world_position, command_type)


func create_area_order_for_fireteams_from_world_rect(fireteam_ids: PackedStringArray, start_world_position: Vector2, end_world_position: Vector2, command_type: String = AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND) -> Array:
	var payload: Dictionary = _build_area_order_payload_from_world_rect(start_world_position, end_world_position)
	return _create_area_orders_from_payload(fireteam_ids, payload, command_type, true)


func _create_area_orders_for_selected_fireteams_from_screen_rect(screen_rect: Rect2, command_type: String = AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND) -> Array:
	var payload: Dictionary = _build_area_order_payload_from_screen_rect(screen_rect)
	return _create_area_orders_from_payload(_selected_fireteam_ids, payload, command_type, true)


func _create_area_orders_from_payload(fireteam_ids: PackedStringArray, payload: Dictionary, command_type: String, should_emit_signal: bool) -> Array:
	var normalized_command_type: String = _normalize_area_order_command_type(command_type)
	var sanitized_fireteam_ids: PackedStringArray = _sanitize_fireteam_ids(fireteam_ids)
	if sanitized_fireteam_ids.is_empty():
		return []
	if Array(payload.get("tile_positions", [])).is_empty() and PackedVector2Array(payload.get("world_polygon", PackedVector2Array())).is_empty():
		return []

	var targets: Array = []
	for fireteam_id_variant in sanitized_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var area_order = AREA_ORDER_SCRIPT.new({
			"area_order_id": _next_area_order_id(),
			"fireteam_id": fireteam_id,
			"command_type": normalized_command_type,
			"tile_positions": Array(payload.get("tile_positions", [])).duplicate(true),
			"tile_world_positions": Array(payload.get("tile_world_positions", [])).duplicate(true),
			"world_polygon": PackedVector2Array(payload.get("world_polygon", PackedVector2Array())),
			"center_position": Vector2(payload.get("center_position", Vector2.ZERO)),
			"created_at_order_index": _get_next_area_order_index_for_fireteam(fireteam_id),
			"status": AREA_ORDER_SCRIPT.STATUS_PENDING,
			"metadata": {
				"created_phase": _get_live_order_phase_index(),
			},
		})
		if area_order == null or not area_order.is_valid():
			continue
		_area_orders_by_id[area_order.area_order_id] = area_order
		targets.append({
			"area_order_id": String(area_order.area_order_id),
			"fireteam_id": fireteam_id,
		})
	if targets.is_empty():
		return []
	_focused_area_order_ref = Dictionary(targets[0]).duplicate(true)
	_refresh_order_visuals()
	_last_command_text = "AREA %s (%d)" % [normalized_command_type.to_upper(), targets.size()]
	_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()
	return targets


func _build_fireteam_anchor_visualization_entries() -> Array:
	var entries: Array = []
	for fireteam_id_variant in _get_available_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var anchor_position: Variant = _resolve_fireteam_visual_anchor_position(fireteam_id)
		if typeof(anchor_position) != TYPE_VECTOR2:
			continue
		entries.append({
			"fireteam_id": fireteam_id,
			"position": Vector2(anchor_position),
		})
	return entries


func _resolve_fireteam_visual_anchor_position(fireteam_id: String) -> Variant:
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for unit in _get_fireteam_units(fireteam_id, true):
		if not (unit is Node2D):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		sum += (unit as Node2D).global_position
		count += 1
	if count > 0:
		return sum / float(count)
	var anchor := _get_selection_anchor_for_fireteam(fireteam_id)
	if anchor != null:
		return anchor.global_position
	return null


func _append_waypoint_to_plan(fireteam_id: String, phase_index: int, world_position: Vector2) -> Dictionary:
	var plan = _get_or_create_order_plan(fireteam_id, phase_index)
	if plan == null:
		return {}

	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.waypoint_id = _next_waypoint_id()
	waypoint.command_type = FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	waypoint.target_position = world_position
	waypoint.metadata = {"created_phase": phase_index}
	plan.waypoints.append(waypoint)
	return {
		"fireteam_id": fireteam_id,
		"phase": phase_index,
		"waypoint_id": waypoint.waypoint_id,
	}


func _get_or_create_order_plan(fireteam_id: String, phase_index: int):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var plan_key: String = _build_order_plan_key(normalized_fireteam_id, phase_index)
	if _order_plans_by_key.has(plan_key):
		return _order_plans_by_key[plan_key]

	var plan = FIRETEAM_ORDER_PLAN_SCRIPT.new()
	plan.plan_id = "plan_%s_p%d" % [normalized_fireteam_id, maxi(phase_index, 0)]
	plan.fireteam_id = normalized_fireteam_id
	plan.phase = phase_index
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT
	_order_plans_by_key[plan_key] = plan
	return plan


func _build_order_plan_key(fireteam_id: String, phase_index: int) -> String:
	return "%s|%d" % [fireteam_id.strip_edges().to_lower(), maxi(phase_index, 0)]


func _next_waypoint_id() -> String:
	_waypoint_sequence += 1
	return "wp_%04d" % _waypoint_sequence


func _next_area_order_id() -> String:
	_area_order_sequence += 1
	return "area_%04d" % _area_order_sequence


func _serialize_order_plans() -> Array:
	var result: Array = []
	var keys: Array = _order_plans_by_key.keys()
	keys.sort()
	for key in keys:
		var plan = _order_plans_by_key[key]
		if plan == null or not plan.is_valid() or plan.waypoints.is_empty():
			continue
		result.append(plan.to_dict())
	return result


func _serialize_area_orders() -> Array:
	var result: Array = []
	var keys: Array = _area_orders_by_id.keys()
	keys.sort()
	for key in keys:
		var area_order = _area_orders_by_id[key]
		if area_order == null or not area_order.is_valid():
			continue
		result.append(area_order.to_dict())
	return result


func _load_order_plans_from_state(plan_dicts: Array) -> void:
	_order_plans_by_key.clear()
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var adjusted_plan_dict: Dictionary = Dictionary(plan_variant).duplicate(true)
		adjusted_plan_dict["phase"] = maxi(int(adjusted_plan_dict.get("phase", 0)), 0)
		var plan = FIRETEAM_ORDER_PLAN_SCRIPT.call("from_dict", adjusted_plan_dict)
		if plan == null or not plan.is_valid():
			continue
		_order_plans_by_key[_build_order_plan_key(String(plan.fireteam_id), int(plan.phase))] = plan
		for waypoint_variant in plan.waypoints:
			var waypoint_id: String = String(waypoint_variant.waypoint_id if waypoint_variant is RefCounted else Dictionary(waypoint_variant).get("waypoint_id", ""))
			var waypoint_sequence: int = _extract_waypoint_sequence(waypoint_id)
			if waypoint_sequence > _waypoint_sequence:
				_waypoint_sequence = waypoint_sequence
	_refresh_order_visuals()


func _load_area_orders_from_state(area_order_dicts: Array) -> void:
	_area_orders_by_id.clear()
	for area_order_variant in area_order_dicts:
		if typeof(area_order_variant) != TYPE_DICTIONARY:
			continue
		var area_order = AREA_ORDER_SCRIPT.call("from_dict", Dictionary(area_order_variant))
		if area_order == null or not area_order.is_valid():
			continue
		_area_orders_by_id[String(area_order.area_order_id)] = area_order
		var sequence: int = _extract_area_order_sequence(String(area_order.area_order_id))
		if sequence > _area_order_sequence:
			_area_order_sequence = sequence
	_refresh_order_visuals()


func _get_max_order_plan_phase() -> int:
	var max_phase: int = -1
	for plan_key in _order_plans_by_key.keys():
		var plan = _order_plans_by_key[plan_key]
		if plan == null:
			continue
		max_phase = maxi(max_phase, int(plan.phase))
	return max_phase


func _get_unsupported_planning_state_issue(planning_state: Dictionary) -> String:
	var uses_global_phase_state: bool = planning_state.has("selected_phase_index") or planning_state.has("active_phase_index") or planning_state.has("phase_states") or planning_state.has("phase_count")
	if uses_global_phase_state:
		return ""
	if planning_state.has("selected_phase"):
		var selected_phase: String = String(planning_state.get("selected_phase", "")).strip_edges()
		return "Old planning data detected: '%s' uses the removed selected_phase format without the numbered phase state. Please recreate this plan with the current phase system." % selected_phase
	if planning_state.has("order_plans") and not Array(planning_state.get("order_plans", [])).is_empty():
		return "Old planning data detected: order plans without the numbered phase state are no longer supported. Please recreate this plan with the current phase system."
	return ""


func _get_phase_controller():
	return get_node_or_null("../PhaseController")


func _get_combat_loop_driver():
	var combat_driver = get_node_or_null("../CombatLoopDriver")
	if combat_driver != null:
		return combat_driver
	return get_node_or_null("../MissionCombatLoopDriver")


func _sync_phase_selection_from_controller() -> void:
	if not PHASE_PLANNING_ENABLED:
		_current_phase_index = _get_live_order_phase_index()
		return
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("get_selected_phase_index"):
		_current_phase_index = maxi(_current_phase_index, 1)
		return
	_current_phase_index = int(phase_controller.call("get_selected_phase_index"))


func _has_pending_global_phase() -> bool:
	if not PHASE_PLANNING_ENABLED:
		return false
	var phase_controller = _get_phase_controller()
	if phase_controller == null:
		return false
	return int(phase_controller.call("get_active_phase_index")) < int(phase_controller.call("get_phase_count")) - 1


func _get_live_order_phase_index() -> int:
	return LIVE_ORDER_PHASE_INDEX


func _has_selected_fireteam_orders_to_execute() -> bool:
	if _selected_fireteam_ids.is_empty():
		return false
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or not _is_fireteam_runtime_active(fireteam_id):
			continue
		if _area_defense_execution_by_fireteam.has(fireteam_id):
			return true
		if _area_attack_execution_by_fireteam.has(fireteam_id):
			return true
		if _phase_execution_by_fireteam.has(fireteam_id):
			return true
		var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, _get_live_order_phase_index()), null)
		if plan != null:
			for waypoint in plan.waypoints:
				if waypoint != null and String(waypoint.status) != FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED:
					return true
		if _find_next_defend_area_order(fireteam_id) != null:
			return true
		if _find_next_attack_area_order(fireteam_id) != null:
			return true
	return false


func _find_next_executable_waypoint_index(plan) -> int:
	if plan == null or plan.waypoints.is_empty():
		return -1
	var active_waypoint_index: int = int(plan.active_waypoint_index)
	if active_waypoint_index >= 0 and active_waypoint_index < plan.waypoints.size():
		var active_status: String = String(plan.waypoints[active_waypoint_index].status)
		if active_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE:
			return active_waypoint_index
	for waypoint_index in range(plan.waypoints.size()):
		var waypoint = plan.waypoints[waypoint_index]
		if waypoint == null:
			continue
		var waypoint_status: String = String(waypoint.status)
		if waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED or waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE:
			return waypoint_index
	return -1


func _find_next_executable_waypoint_index_after(plan, current_waypoint_index: int) -> int:
	if plan == null or plan.waypoints.is_empty():
		return -1
	for waypoint_index in range(maxi(current_waypoint_index + 1, 0), plan.waypoints.size()):
		var waypoint = plan.waypoints[waypoint_index]
		if waypoint == null:
			continue
		var waypoint_status: String = String(waypoint.status)
		if waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED or waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE:
			return waypoint_index
	return -1


func _reset_non_completed_waypoints_for_resume(plan) -> void:
	if plan == null:
		return
	for waypoint in plan.waypoints:
		if waypoint != null and String(waypoint.status) != FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED:
			waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	plan.active_waypoint_index = -1


func _try_continue_active_fireteam_order(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	if execution_state.is_empty():
		return false
	var phase_index: int = int(execution_state.get("phase", _get_live_order_phase_index()))
	var plan = _order_plans_by_key.get(_build_order_plan_key(normalized_fireteam_id, phase_index), null)
	if plan == null:
		return false
	var waypoint_index: int = int(execution_state.get("waypoint_index", -1))
	if waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
		return false
	var next_waypoint_index: int = _find_next_executable_waypoint_index_after(plan, waypoint_index)
	if next_waypoint_index < 0:
		return false
	var waypoint = plan.waypoints[waypoint_index]
	if waypoint == null:
		return false
	var command_type: String = String(waypoint.command_type).strip_edges().to_lower()
	var waiting_for_go: bool = bool(execution_state.get("waiting_for_go", false))
	if not waiting_for_go and command_type == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND:
		waiting_for_go = true
	if not waiting_for_go:
		return false
	return _complete_waypoint_and_activate_next(normalized_fireteam_id, plan, waypoint_index, next_waypoint_index)


func _try_continue_active_area_defense(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var execution_state: Dictionary = Dictionary(_area_defense_execution_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	if execution_state.is_empty() or not bool(execution_state.get("waiting_for_go", false)):
		return false
	var area_order = _area_orders_by_id.get(String(execution_state.get("area_order_id", "")), null)
	if area_order != null:
		area_order.status = AREA_ORDER_SCRIPT.STATUS_COMPLETED
	_area_defense_execution_by_fireteam.erase(normalized_fireteam_id)
	_set_active_behavior_profile(normalized_fireteam_id, null)
	_last_command_text = "AREA DEFENSE RELEASED %s" % normalized_fireteam_id.to_upper()
	_refresh_order_visuals()
	_refresh_fireteam_status_panel()
	return true


func _try_continue_active_area_attack(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var execution_state: Dictionary = Dictionary(_area_attack_execution_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	if execution_state.is_empty() or not bool(execution_state.get("waiting_for_go", false)):
		return false
	var area_order = _area_orders_by_id.get(String(execution_state.get("area_order_id", "")), null)
	if area_order != null:
		area_order.status = AREA_ORDER_SCRIPT.STATUS_COMPLETED
	_area_attack_execution_by_fireteam.erase(normalized_fireteam_id)
	_set_active_behavior_profile(normalized_fireteam_id, null)
	_last_command_text = "AREA ATTACK RELEASED %s" % normalized_fireteam_id.to_upper()
	_refresh_order_visuals()
	_refresh_fireteam_status_panel()
	return true


func _has_pending_waypoint_order(fireteam_id: String, phase_index: int) -> bool:
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id.strip_edges().to_lower(), phase_index), null)
	return plan != null and _find_next_executable_waypoint_index(plan) >= 0


func _find_next_defend_area_order(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var candidates: Array = []
	for area_order in _area_orders_by_id.values():
		if area_order == null:
			continue
		if String(area_order.fireteam_id).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		if String(area_order.command_type) != AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
			continue
		var status: String = String(area_order.status)
		if status != AREA_ORDER_SCRIPT.STATUS_PENDING and status != AREA_ORDER_SCRIPT.STATUS_ACTIVE:
			continue
		candidates.append(area_order)
	candidates.sort_custom(func(a, b) -> bool:
		var index_a: int = int(a.created_at_order_index)
		var index_b: int = int(b.created_at_order_index)
		if index_a == index_b:
			return String(a.area_order_id) < String(b.area_order_id)
		return index_a < index_b
	)
	return null if candidates.is_empty() else candidates[0]


func _find_next_attack_area_order(fireteam_id: String):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var candidates: Array = []
	for area_order in _area_orders_by_id.values():
		if area_order == null:
			continue
		if String(area_order.fireteam_id).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		var command_type: String = String(area_order.command_type).strip_edges().to_lower()
		if command_type != AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE and command_type != AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE and command_type != AREA_ORDER_SCRIPT.COMMAND_TYPE_FLANK:
			continue
		var status: String = String(area_order.status)
		if status != AREA_ORDER_SCRIPT.STATUS_PENDING and status != AREA_ORDER_SCRIPT.STATUS_ACTIVE:
			continue
		candidates.append(area_order)
	candidates.sort_custom(func(a, b) -> bool:
		var index_a: int = int(a.created_at_order_index)
		var index_b: int = int(b.created_at_order_index)
		if index_a == index_b:
			return String(a.area_order_id) < String(b.area_order_id)
		return index_a < index_b
	)
	return null if candidates.is_empty() else candidates[0]


func _activate_next_defend_area_order(fireteam_id: String, phase_index: int) -> bool:
	var area_order = _find_next_defend_area_order(fireteam_id)
	if area_order == null:
		return false
	return _start_defend_area_order(fireteam_id, area_order, phase_index)


func _activate_next_attack_area_order(fireteam_id: String, phase_index: int) -> bool:
	var area_order = _find_next_attack_area_order(fireteam_id)
	if area_order == null:
		return false
	return _start_attack_area_order(fireteam_id, area_order, phase_index)


func _start_defend_area_order(fireteam_id: String, area_order, phase_index: int) -> bool:
	if area_order == null or not _is_fireteam_runtime_active(fireteam_id):
		return false
	_ensure_area_order_resolver()
	if _area_order_resolver == null:
		return false
	var units: Array = _get_fireteam_units(fireteam_id, true)
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	var resolution: Dictionary = Dictionary(_area_order_resolver.call("resolve_defend_area", area_order, units, leader, _get_terrain_registry()))
	if resolution.is_empty():
		return false
	var assignments: Array = Array(resolution.get("assignments", []))
	if assignments.is_empty():
		return false
	var center_position: Vector2 = Vector2(resolution.get("center_position", area_order.center_position))
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, center_position)
	if behavior_profile != null:
		var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
		metadata["origin"] = "area_order"
		metadata["phase"] = phase_index
		metadata["area_order_id"] = String(area_order.area_order_id)
		metadata["area_center_position"] = center_position
		behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	var issued_count: int = 0
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if _issue_area_defense_unit_command(fireteam_id, assignment, phase_index, false, String(area_order.area_order_id)):
			issued_count += 1
	if issued_count <= 0:
		_set_active_behavior_profile(fireteam_id, null)
		return false
	area_order.status = AREA_ORDER_SCRIPT.STATUS_ACTIVE
	_area_defense_execution_by_fireteam[fireteam_id] = {
		"fireteam_id": fireteam_id,
		"phase": phase_index,
		"area_order_id": String(area_order.area_order_id),
		"command_type": AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND,
		"status": "moving",
		"waiting_for_go": false,
		"center_position": center_position,
		"assignments": assignments.duplicate(true),
		"issued_count": issued_count,
	}
	_refresh_order_visuals()
	refresh_fireteam_security_state()
	return true


func _start_attack_area_order(fireteam_id: String, area_order, phase_index: int) -> bool:
	if area_order == null or not _is_fireteam_runtime_active(fireteam_id):
		return false
	_ensure_area_order_resolver()
	if _area_order_resolver == null:
		return false
	var units: Array = _get_fireteam_units(fireteam_id, true)
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	var resolution: Dictionary = Dictionary(_area_order_resolver.call("resolve_attack_area", area_order, units, leader, _get_terrain_registry()))
	if resolution.is_empty():
		return false
	var assignments: Array = Array(resolution.get("assignments", []))
	if assignments.is_empty():
		return false
	var command_type: String = String(resolution.get("command_type", area_order.command_type)).strip_edges().to_lower()
	var center_position: Vector2 = Vector2(resolution.get("center_position", area_order.center_position))
	var approach_position: Vector2 = Vector2(resolution.get("approach_position", center_position))
	var target_area: Dictionary = Dictionary(resolution.get("target_area", {})).duplicate(true)
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, command_type, center_position)
	if behavior_profile != null:
		var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
		metadata["origin"] = "area_order"
		metadata["phase"] = phase_index
		metadata["area_order_id"] = String(area_order.area_order_id)
		metadata["area_center_position"] = center_position
		metadata["approach_position"] = approach_position
		metadata["target_area"] = target_area.duplicate(true)
		behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	var issued_count: int = 0
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		if _issue_area_attack_unit_command(fireteam_id, assignment, phase_index, false, String(area_order.area_order_id), command_type):
			issued_count += 1
	if issued_count <= 0:
		_set_active_behavior_profile(fireteam_id, null)
		return false
	area_order.status = AREA_ORDER_SCRIPT.STATUS_ACTIVE
	_area_attack_execution_by_fireteam[fireteam_id] = {
		"fireteam_id": fireteam_id,
		"phase": phase_index,
		"area_order_id": String(area_order.area_order_id),
		"command_type": command_type,
		"status": "approaching",
		"waiting_for_go": false,
		"center_position": center_position,
		"approach_position": approach_position,
		"area_radius": float(resolution.get("area_radius", 0.0)),
		"target_area": target_area,
		"assignments": assignments.duplicate(true),
		"issued_count": issued_count,
	}
	_refresh_order_visuals()
	refresh_fireteam_security_state()
	return true


func _complete_waypoint_and_activate_next(fireteam_id: String, plan, waypoint_index: int, next_waypoint_index: int) -> bool:
	if plan == null or waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
		return false
	plan.waypoints[waypoint_index].status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED
	plan.active_waypoint_index = waypoint_index
	_phase_execution_by_fireteam.erase(fireteam_id)
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	return _activate_next_waypoint_for_plan(plan, fireteam_id, next_waypoint_index)


func _get_shared_selected_tactical_stance() -> String:
	if _selected_fireteam_ids.is_empty():
		return ""
	var shared_stance: String = ""
	for fireteam_id_variant in _selected_fireteam_ids:
		var stance: String = get_requested_tactical_stance(String(fireteam_id_variant))
		if shared_stance.is_empty():
			shared_stance = stance
			continue
		if stance != shared_stance:
			return ""
	return shared_stance


func _build_selected_tactical_stance_text() -> String:
	var shared_stance: String = _get_shared_selected_tactical_stance()
	if shared_stance.is_empty():
		return "MIXED" if not _selected_fireteam_ids.is_empty() else "N"
	return _get_tactical_stance_short_label(shared_stance)


func _build_selected_movement_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "-"
	var shared_text: String = ""
	for fireteam_id in _selected_fireteam_ids:
		var state: Dictionary = get_fireteam_movement_state(String(fireteam_id))
		var movement_text: String = _format_movement_state_text(state)
		if shared_text.is_empty():
			shared_text = movement_text
			continue
		if movement_text != shared_text:
			return "MIXED"
	return shared_text


func _build_selected_execution_quality_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "-"
	var shared_text: String = ""
	for fireteam_id in _selected_fireteam_ids:
		var profile_dict: Dictionary = get_active_behavior_profile(String(fireteam_id))
		var execution_text: String = _format_execution_quality_text(profile_dict)
		if shared_text.is_empty():
			shared_text = execution_text
			continue
		if execution_text != shared_text:
			return "MIXED"
	return shared_text


func _build_selected_security_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "-"
	var shared_text: String = ""
	for fireteam_id in _selected_fireteam_ids:
		var security_text: String = _format_security_state_text(get_fireteam_security_state(String(fireteam_id)))
		if shared_text.is_empty():
			shared_text = security_text
			continue
		if security_text != shared_text:
			return "MIXED"
	return shared_text


func _build_selected_flank_vulnerability_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return "-"
	var shared_text: String = ""
	for fireteam_id in _selected_fireteam_ids:
		var flank_text: String = _format_flank_vulnerability_text(get_fireteam_flank_vulnerability_state(String(fireteam_id)))
		if shared_text.is_empty():
			shared_text = flank_text
			continue
		if flank_text != shared_text:
			return "MIXED"
	return shared_text


func _format_movement_state_text(state: Dictionary) -> String:
	if state.is_empty():
		return "-"
	var style_label: String = _get_movement_style_short_label(String(state.get("effective_style", "")))
	var stage_index: int = int(state.get("stage_index", 0)) + 1
	if bool(state.get("simplified_due_to_losses", false)):
		return "%s S%d LOSS" % [style_label, stage_index]
	return "%s S%d" % [style_label, stage_index]


func _format_execution_quality_text(profile_dict: Dictionary) -> String:
	if profile_dict.is_empty():
		return "-"
	var label: String = String(profile_dict.get("execution_label", "STEADY")).strip_edges().to_upper()
	if label.is_empty():
		label = "STEADY"
	var order_fidelity_percent: int = int(roundi(clampf(float(profile_dict.get("order_fidelity", 0.0)), 0.0, 1.0) * 100.0))
	return "%s %d" % [label, order_fidelity_percent]


func _format_security_state_text(state: Dictionary) -> String:
	if state.is_empty() or not bool(state.get("is_active", false)):
		return "-"
	if not String(state.get("area_order_id", "")).strip_edges().is_empty():
		var area_status: String = String(state.get("area_status", "")).strip_edges().to_lower()
		if area_status == "holding":
			return "AREA HOLD"
		return "AREA SEC"
	var mode: String = String(state.get("security_mode", "directional")).strip_edges().to_lower()
	var mode_label: String = "DIR"
	if mode == "360":
		mode_label = "360"
	if bool(state.get("overwatch_ready", false)):
		return "%s+OVW" % mode_label
	return mode_label


func _get_area_defense_security_context(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var state: Dictionary = Dictionary(_area_defense_execution_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	if state.is_empty():
		return {}
	return {
		"area_order_id": String(state.get("area_order_id", "")),
		"command_type": "defend_area",
		"center_position": Vector2(state.get("center_position", Vector2.ZERO)),
		"status": String(state.get("status", "")),
		"assignments": Array(state.get("assignments", [])).duplicate(true),
	}


func _get_area_attack_security_context(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var state: Dictionary = Dictionary(_area_attack_execution_by_fireteam.get(normalized_fireteam_id, {})).duplicate(true)
	if state.is_empty():
		return {}
	var status: String = String(state.get("status", "approaching")).strip_edges().to_lower()
	if status == "approaching":
		return {}
	var command_type: String = "take" if status == "secured" else String(state.get("command_type", "take"))
	return {
		"area_order_id": String(state.get("area_order_id", "")),
		"command_type": command_type,
		"center_position": Vector2(state.get("center_position", Vector2.ZERO)),
		"status": status,
		"assignments": Array(state.get("assignments", [])).duplicate(true),
	}


func _get_area_execution_security_context(fireteam_id: String) -> Dictionary:
	var defense_context: Dictionary = _get_area_defense_security_context(fireteam_id)
	if not defense_context.is_empty():
		return defense_context
	return _get_area_attack_security_context(fireteam_id)


func _format_flank_vulnerability_text(state: Dictionary) -> String:
	if state.is_empty() or (not bool(state.get("is_active", false)) and not bool(state.get("is_morale_active", false))):
		return "-"
	var parts: PackedStringArray = []
	var direction_label: String = _get_flank_direction_short_label(String(state.get("direction_label", "")))
	if not direction_label.is_empty():
		parts.append(direction_label)
	if bool(state.get("is_active", false)):
		var remaining_seconds: float = float(state.get("remaining_seconds", 0.0))
		parts.append("ON" if remaining_seconds <= 0.05 else "%.1fs" % remaining_seconds)
	if bool(state.get("is_morale_active", false)):
		var morale_label: String = _get_flank_morale_short_label(String(state.get("morale_state", "")))
		if not morale_label.is_empty():
			parts.append(morale_label)
			var morale_seconds: float = float(state.get("morale_remaining_seconds", 0.0))
			if morale_seconds > 0.05:
				parts.append("%.1fs" % morale_seconds)
	return " ".join(parts)


func _get_flank_direction_short_label(direction_label: String) -> String:
	match direction_label.strip_edges().to_lower():
		"rear":
			return "REAR"
		"left":
			return "LEFT"
		"right":
			return "RIGHT"
		_:
			return ""


func _get_flank_morale_short_label(morale_state: String) -> String:
	match morale_state.strip_edges().to_lower():
		"shaken":
			return "SHK"
		"alerted":
			return "ALRT"
		_:
			return ""


func _get_movement_style_short_label(style_id: String) -> String:
	match style_id.strip_edges().to_lower():
		"bounding":
			return "BND"
		"caterpillar", "creep":
			return "CAT"
		"rush":
			return "RSH"
		_:
			return "-"


func _get_tactical_stance_short_label(stance_id: String) -> String:
	match stance_id.strip_edges().to_lower():
		"cautious":
			return "C"
		"aggressive":
			return "A"
		_:
			return "N"


func _get_tactical_stance_button_text(stance_id: String) -> String:
	match stance_id.strip_edges().to_lower():
		"cautious":
			return "Vorsichtiger"
		"aggressive":
			return "Aggressiver"
		_:
			return "Normal"


func _get_terrain_registry():
	var terrain_registry = get_node_or_null("../TerrainRegistry")
	if terrain_registry != null:
		return terrain_registry
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null or not simulation_root.has_method("_get_terrain_registry"):
		return null
	return simulation_root.call("_get_terrain_registry")


func _resolve_fireteam_behavior_profile(fireteam_id: String, command_type: String, rough_target_position = null):
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var tactical_stance: String = get_requested_tactical_stance(normalized_fireteam_id)
	return FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT.call(
		"resolve_profile",
		normalized_fireteam_id,
		_get_fireteam_units(normalized_fireteam_id, true),
		_resolve_fireteam_leader_for_behavior(normalized_fireteam_id),
		command_type,
		rough_target_position,
		_get_terrain_registry(),
		tactical_stance
	)


func _set_active_behavior_profile(fireteam_id: String, behavior_profile) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	if behavior_profile == null:
		_active_behavior_profiles_by_fireteam.erase(normalized_fireteam_id)
		return
	_active_behavior_profiles_by_fireteam[normalized_fireteam_id] = behavior_profile


func _refresh_active_behavior_profile_for_fireteam(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _active_behavior_profiles_by_fireteam.has(normalized_fireteam_id):
		return
	var existing_profile_dict: Dictionary = get_active_behavior_profile(normalized_fireteam_id)
	if existing_profile_dict.is_empty():
		return
	var metadata: Dictionary = Dictionary(existing_profile_dict.get("metadata", {})).duplicate(true)
	var command_type: String = String(metadata.get("origin_command_type", "hold_position")).strip_edges().to_lower()
	var rough_target_position: Variant = metadata.get("rough_target_position", null)
	if typeof(rough_target_position) != TYPE_VECTOR2:
		var anchor = _get_selection_anchor_for_fireteam(normalized_fireteam_id)
		rough_target_position = anchor.global_position if anchor != null else null
	var refreshed_profile = _resolve_fireteam_behavior_profile(normalized_fireteam_id, command_type, rough_target_position)
	if refreshed_profile == null:
		return
	refreshed_profile.metadata = metadata
	_set_active_behavior_profile(normalized_fireteam_id, refreshed_profile)


func _reset_tactical_stances_for_new_phase() -> void:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null:
		return
	_tactical_stance_controller.call("reset_fireteams")


func _notify_flank_initiated(fireteam_id: String, rough_target_position: Vector2, resolved_target_position: Vector2, behavior_profile) -> void:
	var event_router = get_node_or_null("../EventRouter")
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	if event_router == null or leader == null or not event_router.has_method("notify_flank_initiated"):
		return
	var profile_dict: Dictionary = behavior_profile.to_dict() if behavior_profile != null and behavior_profile.has_method("to_dict") else {}
	event_router.call(
		"notify_flank_initiated",
		fireteam_id,
		leader,
		{
			"fireteam_id": fireteam_id,
			"leader_unit_id": String(leader.call("get_unit_id")) if leader != null and leader.has_method("get_unit_id") else "",
			"rough_target_position": rough_target_position,
			"resolved_target_position": resolved_target_position,
			"behavior_profile": profile_dict,
		}
	)


func _apply_default_fireteam_behavior(fireteam_id: String, phase_index: int) -> bool:
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	if not _is_fireteam_runtime_active(fireteam_id):
		_set_active_behavior_profile(fireteam_id, null)
		return false
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	if leader == null or not (leader is Node2D):
		_set_active_behavior_profile(fireteam_id, null)
		return false
	var anchor_position: Vector2 = (leader as Node2D).global_position
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, "hold_position", anchor_position)
	if behavior_profile == null:
		return false
	var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
	metadata["origin"] = "standard_behavior"
	metadata["phase"] = phase_index
	behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	if _issue_fireteam_hold_current_positions(fireteam_id, phase_index):
		_mirror_flow_driver_order_for_fireteam(fireteam_id, anchor_position, "defend", phase_index)
		return true
	var issued_count: int = 0
	for driver in _get_flow_drivers_for_fireteam(fireteam_id):
		if driver == null or not driver.has_method("issue_command_at_position"):
			continue
		if bool(driver.call("issue_command_at_position", anchor_position, "defend", phase_index)):
			issued_count += 1
	return issued_count > 0


func _issue_fireteam_hold_current_positions(fireteam_id: String, phase_index: int) -> bool:
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null:
		return false
	var issued_count: int = 0
	for unit in _get_fireteam_units(fireteam_id, true):
		if not (unit is Node2D):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		if not unit.has_method("get_unit_id"):
			continue
		var command = UNIT_COMMAND_SCRIPT.new()
		command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
		command.priority = 11
		command.unit_id = String(unit.call("get_unit_id"))
		command.team_id = FRIENDLY_TEAM_ID
		if unit.has_method("get_team_id"):
			command.team_id = String(unit.call("get_team_id"))
		command.target_position = (unit as Node2D).global_position
		command.move_speed_factor = 0.0
		command.cover_score = 0.0
		if unit.has_method("get_cover_score"):
			command.cover_score = float(unit.call("get_cover_score"))
		command.attack_bonus = 0.0
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
		command.source_command_type = "hold_position"
		command.source_task_type = "default_hold"
		command.phase = phase_index
		if not bool(command.call("is_valid")):
			continue
		if unit.has_method("assign_unit_command"):
			unit.call("assign_unit_command", command)
		simulation_root.call("enqueue_command", command.to_dict())
		issued_count += 1
	return issued_count > 0


func _start_active_phase_execution(active_phase_index: int) -> void:
	_phase_execution_by_fireteam.clear()
	_ad_hoc_execution_by_fireteam.clear()
	_ad_hoc_resume_state_by_fireteam.clear()
	_area_defense_execution_by_fireteam.clear()
	_area_attack_execution_by_fireteam.clear()
	_suppression_interrupt_pending_by_fireteam.clear()
	_active_coordination_by_id.clear()
	_active_behavior_profiles_by_fireteam.clear()
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_all")
	var activated_fireteams: PackedStringArray = []
	var default_fireteams: PackedStringArray = []
	for fireteam_id in _get_available_fireteam_ids():
		if not _is_fireteam_runtime_active(String(fireteam_id)):
			continue
		var plan = _order_plans_by_key.get(_build_order_plan_key(String(fireteam_id), active_phase_index), null)
		if plan == null or plan.waypoints.is_empty():
			if _activate_next_defend_area_order(String(fireteam_id), active_phase_index):
				activated_fireteams.append(String(fireteam_id).to_upper())
				continue
			if _activate_next_attack_area_order(String(fireteam_id), active_phase_index):
				activated_fireteams.append(String(fireteam_id).to_upper())
				continue
			if _apply_default_fireteam_behavior(String(fireteam_id), active_phase_index):
				default_fireteams.append(String(fireteam_id).to_upper())
			continue
		for waypoint in plan.waypoints:
			waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		plan.active_waypoint_index = -1
		if _activate_next_waypoint_for_plan(plan, String(fireteam_id), 0):
			activated_fireteams.append(String(fireteam_id).to_upper())
	if activated_fireteams.is_empty() and default_fireteams.is_empty():
		_last_command_text = "PHASE P%d ACTIVE (NO PLANS)" % active_phase_index
		return
	_apply_fireteam_coordination_for_phase(active_phase_index)
	var phase_bits: PackedStringArray = []
	if not activated_fireteams.is_empty():
		phase_bits.append("ORDERS %s" % ", ".join(activated_fireteams))
	if not default_fireteams.is_empty():
		phase_bits.append("DEFAULT %s" % ", ".join(default_fireteams))
	_last_command_text = "PHASE P%d STARTED (%s)" % [active_phase_index, " | ".join(phase_bits)]


func _build_ad_hoc_visualization_entries() -> Array:
	_ensure_ad_hoc_order_controller()
	if _ad_hoc_order_controller == null:
		return []
	var entries: Array = []
	for order_variant in Array(_ad_hoc_order_controller.call("get_active_orders_snapshot")):
		if typeof(order_variant) != TYPE_DICTIONARY:
			continue
		var order_dict: Dictionary = Dictionary(order_variant).duplicate(true)
		var fireteam_id: String = String(order_dict.get("fireteam_id", "")).strip_edges().to_lower()
		var anchor = _get_selection_anchor_for_fireteam(fireteam_id)
		if anchor == null:
			continue
		var target_position: Vector2 = anchor.global_position
		if typeof(order_dict.get("target_position", null)) == TYPE_VECTOR2:
			target_position = Vector2(order_dict.get("target_position", anchor.global_position))
		entries.append({
			"fireteam_id": fireteam_id,
			"order_id": String(order_dict.get("order_id", "")),
			"order_type": String(order_dict.get("order_type", "")),
			"anchor_position": anchor.global_position,
			"target_position": target_position,
			"label": "AD-HOC: %s" % String(order_dict.get("order_type", "")).to_upper(),
		})
	return entries


func _apply_fireteam_coordination_for_phase(phase_index: int) -> void:
	_ensure_coordination_manager()
	if _coordination_manager == null:
		return
	var execution_targets: Array = []
	var leadership_by_fireteam: Dictionary = {}
	for fireteam_id in _phase_execution_by_fireteam.keys():
		var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(fireteam_id, {}))
		if int(execution_state.get("phase", -1)) != phase_index:
			continue
		var resolved_target_position: Variant = execution_state.get("resolved_target_position", null)
		if typeof(resolved_target_position) != TYPE_VECTOR2:
			continue
		execution_targets.append({
			"fireteam_id": String(fireteam_id),
			"phase": phase_index,
			"target_position": Vector2(resolved_target_position),
		})
		var leader = _resolve_fireteam_leader_for_behavior(String(fireteam_id))
		leadership_by_fireteam[String(fireteam_id)] = float(leader.call("get_leadership_skill")) if leader != null and leader.has_method("get_leadership_skill") else 0.0
	var assignments: Array = Array(_coordination_manager.call("resolve_bounding_assignments", execution_targets, leadership_by_fireteam))
	var event_router = get_node_or_null("../EventRouter")
	for assignment_variant in assignments:
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant).duplicate(true)
		var coordination_id: String = String(assignment.get("coordination_id", "")).strip_edges()
		if coordination_id.is_empty() or _active_coordination_by_id.has(coordination_id):
			continue
		var cover_fireteam_id: String = String(assignment.get("cover_fireteam_id", "")).strip_edges().to_lower()
		if cover_fireteam_id.is_empty():
			continue
		_phase_execution_by_fireteam.erase(cover_fireteam_id)
		_issue_cover_hold_for_fireteam(cover_fireteam_id, phase_index)
		_active_coordination_by_id[coordination_id] = assignment
		if event_router != null and event_router.has_method("request_fireteam_coordination"):
			event_router.call("request_fireteam_coordination", assignment)


func _issue_cover_hold_for_fireteam(fireteam_id: String, phase_index: int) -> void:
	if not _is_fireteam_runtime_active(fireteam_id):
		return
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	var anchor = _get_selection_anchor_for_fireteam(fireteam_id)
	if anchor == null:
		return
	for driver in _get_flow_drivers_for_fireteam(fireteam_id):
		if driver != null and driver.has_method("issue_command_at_position"):
			driver.call("issue_command_at_position", anchor.global_position, "defend", phase_index)


func _notify_fireteam_ready_for_coordination(fireteam_id: String) -> void:
	var event_router = get_node_or_null("../EventRouter")
	for coordination_id in _active_coordination_by_id.keys().duplicate():
		var assignment: Dictionary = Dictionary(_active_coordination_by_id.get(coordination_id, {})).duplicate(true)
		if String(assignment.get("advance_fireteam_id", "")) != fireteam_id:
			continue
		if event_router != null and event_router.has_method("notify_fireteam_ready_to_advance"):
			event_router.call("notify_fireteam_ready_to_advance", fireteam_id, String(coordination_id))
		var rotated: Dictionary = Dictionary(_coordination_manager.call("rotate_assignment", assignment, fireteam_id))
		_active_coordination_by_id[coordination_id] = rotated
		var next_advancing_fireteam_id: String = String(rotated.get("advance_fireteam_id", "")).strip_edges().to_lower()
		if next_advancing_fireteam_id.is_empty():
			continue
		var phase_index: int = int(rotated.get("phase", _current_phase_index))
		var plan = _order_plans_by_key.get(_build_order_plan_key(next_advancing_fireteam_id, phase_index), null)
		if plan == null:
			continue
		var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(next_advancing_fireteam_id, {}))
		var waypoint_index: int = int(execution_state.get("waypoint_index", plan.active_waypoint_index))
		if waypoint_index < 0:
			waypoint_index = 0
		_activate_next_waypoint_for_plan(plan, next_advancing_fireteam_id, waypoint_index)


func _interrupt_active_plan_for_ad_hoc(fireteam_id: String) -> bool:
	var active_phase_index: int = _get_live_order_phase_index()
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, active_phase_index), null)
	var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
	var resume_state: Dictionary = {
		"phase": active_phase_index,
		"waypoint_index": int(execution_state.get("waypoint_index", -1)),
	}
	_ad_hoc_resume_state_by_fireteam[fireteam_id] = resume_state
	if plan != null:
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_INTERRUPTED
		var current_waypoint_index: int = int(execution_state.get("waypoint_index", -1))
		if current_waypoint_index >= 0 and current_waypoint_index < plan.waypoints.size():
			plan.waypoints[current_waypoint_index].status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
	_phase_execution_by_fireteam.erase(fireteam_id)
	_area_defense_execution_by_fireteam.erase(fireteam_id)
	_area_attack_execution_by_fireteam.erase(fireteam_id)
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	if _ad_hoc_order_controller != null:
		_ad_hoc_order_controller.call("cancel_order", fireteam_id, "superseded")
	_ad_hoc_execution_by_fireteam.erase(fireteam_id)
	return true


func _start_ad_hoc_order_for_fireteam(fireteam_id: String, order_type: String, target_position: Variant) -> bool:
	if not _is_fireteam_runtime_active(fireteam_id):
		return false
	_ensure_ad_hoc_order_controller()
	if _ad_hoc_order_controller == null:
		return false
	var active_phase_index: int = _get_live_order_phase_index()
	var execution_target: Vector2 = _get_target_position()
	if typeof(target_position) == TYPE_VECTOR2:
		execution_target = Vector2(target_position)
	var resume_state: Dictionary = Dictionary(_ad_hoc_resume_state_by_fireteam.get(fireteam_id, {
		"phase": active_phase_index,
		"waypoint_index": int(Dictionary(_phase_execution_by_fireteam.get(fireteam_id, {})).get("waypoint_index", -1)),
	})).duplicate(true)
	var order_dict: Dictionary = Dictionary(_ad_hoc_order_controller.call("issue_order", fireteam_id, order_type, execution_target, active_phase_index, true, resume_state))
	if order_dict.is_empty():
		return false
	if not _issue_ad_hoc_order_for_fireteam(fireteam_id, order_dict):
		_ad_hoc_order_controller.call("cancel_order", fireteam_id, "issue_failed")
		return false
	_ad_hoc_execution_by_fireteam[fireteam_id] = {
		"target_position": execution_target,
		"hold_elapsed": 0.0,
		"order_type": order_type,
	}
	return true


func _activate_next_waypoint_for_plan(plan, fireteam_id: String, waypoint_index: int) -> bool:
	if plan == null or waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED if plan != null else FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		return false
	plan.active_waypoint_index = waypoint_index
	plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_ACTIVE
	var waypoint = plan.waypoints[waypoint_index]
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, String(waypoint.command_type), waypoint.target_position)
	if behavior_profile != null:
		var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
		metadata["origin"] = "planned_order"
		metadata["phase"] = int(plan.phase)
		behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	var resolved_target_position = waypoint.target_position
	if behavior_profile != null:
		var behavior_metadata: Dictionary = Dictionary(behavior_profile.metadata)
		if typeof(behavior_metadata.get("resolved_target_position", null)) == TYPE_VECTOR2:
			resolved_target_position = Vector2(behavior_metadata.get("resolved_target_position", waypoint.target_position))
	_phase_execution_by_fireteam[fireteam_id] = {
		"phase": int(plan.phase),
		"waypoint_index": waypoint_index,
		"hold_elapsed": 0.0,
		"resolved_target_position": resolved_target_position,
	}
	return _issue_waypoint_for_fireteam(fireteam_id, waypoint, int(plan.phase), behavior_profile)


func _issue_waypoint_for_fireteam(fireteam_id: String, waypoint, phase_index: int, behavior_profile = null) -> bool:
	if not _is_fireteam_runtime_active(fireteam_id):
		return false
	if waypoint == null or typeof(waypoint.target_position) != TYPE_VECTOR2:
		return false
	var target_position: Vector2 = waypoint.target_position
	var command_type: String = String(waypoint.command_type).strip_edges().to_lower()
	if behavior_profile != null:
		var behavior_metadata: Dictionary = Dictionary(behavior_profile.metadata)
		if typeof(behavior_metadata.get("resolved_target_position", null)) == TYPE_VECTOR2:
			target_position = Vector2(behavior_metadata.get("resolved_target_position", waypoint.target_position))
	_ensure_fireteam_movement_controller()
	var simulation_root = get_node_or_null("../SimulationRoot")
	if _fireteam_movement_controller != null and simulation_root != null:
		var movement_result: Dictionary = Dictionary(
			_fireteam_movement_controller.call(
				"start_execution",
				fireteam_id,
				command_type,
				phase_index,
				target_position,
				behavior_profile,
				_get_fireteam_units(fireteam_id, true),
				_resolve_fireteam_leader_for_behavior(fireteam_id),
				simulation_root
			)
		)
		if bool(movement_result.get("started", false)):
			_mirror_flow_driver_order_for_fireteam(fireteam_id, target_position, command_type, phase_index)
			if command_type == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK:
				_notify_flank_initiated(fireteam_id, waypoint.target_position, target_position, behavior_profile)
			return true
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	var issued_count: int = 0
	for driver in _get_flow_drivers_for_fireteam(fireteam_id):
		if driver == null:
			continue
		if driver.has_method("issue_command_at_position"):
			if bool(driver.call("issue_command_at_position", target_position, command_type, phase_index)):
				issued_count += 1
		elif driver.has_method("issue_command"):
			var target_marker := get_node_or_null(target_marker_path) as Node2D
			var previous_position: Vector2 = target_marker.global_position if target_marker != null else Vector2.ZERO
			if target_marker != null:
				target_marker.global_position = target_position
			if bool(driver.call("issue_command", command_type, phase_index)):
				issued_count += 1
			if target_marker != null:
				target_marker.global_position = previous_position
	if issued_count > 0 and command_type == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK:
		_notify_flank_initiated(fireteam_id, waypoint.target_position, target_position, behavior_profile)
	return issued_count > 0


func _mirror_flow_driver_order_for_fireteam(fireteam_id: String, target_position: Vector2, command_type: String, phase_index: int) -> void:
	# Keep existing flow-driver observability in sync while movement execution owns the live unit commands.
	for driver in _get_flow_drivers_for_fireteam(fireteam_id):
		if driver != null and driver.has_method("mirror_command_at_position"):
			driver.call("mirror_command_at_position", target_position, command_type, phase_index)


func _issue_ad_hoc_order_for_fireteam(fireteam_id: String, order_dict: Dictionary) -> bool:
	var order_type: String = String(order_dict.get("order_type", "")).strip_edges().to_lower()
	var anchor = _get_selection_anchor_for_fireteam(fireteam_id)
	var anchor_position: Vector2 = anchor.global_position if anchor != null else _get_target_position()
	var target_position: Vector2 = anchor_position
	if typeof(order_dict.get("target_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(order_dict.get("target_position", anchor_position))
	var command_type: String = "move"
	match order_type:
		"flank":
			command_type = "flank"
		"disengage":
			command_type = "defend"
			target_position = anchor_position
		"fall_back":
			command_type = "move"
			target_position = anchor_position + (anchor_position - target_position).normalized() * 96.0
		"focus_fire":
			command_type = "take"
		"hold_till_last_man":
			command_type = "defend"
			target_position = anchor_position
		_:
			command_type = "move"
	var waypoint = FIRETEAM_WAYPOINT_SCRIPT.new()
	waypoint.command_type = command_type
	waypoint.target_position = target_position
	waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE
	var behavior_profile = _resolve_fireteam_behavior_profile(fireteam_id, command_type, target_position)
	if behavior_profile != null:
		var metadata: Dictionary = Dictionary(behavior_profile.metadata).duplicate(true)
		metadata["origin"] = "ad_hoc_order"
		metadata["ad_hoc_order_type"] = order_type
		behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	return _issue_waypoint_for_fireteam(fireteam_id, waypoint, int(order_dict.get("source_phase", _current_phase_index)), behavior_profile)


func _update_fireteam_movement_execution(fireteam_id: String) -> Dictionary:
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller == null:
		return {}
	var result: Dictionary = Dictionary(
		_fireteam_movement_controller.call(
			"update_execution",
			fireteam_id,
			_get_fireteam_units(fireteam_id, true),
			_resolve_fireteam_leader_for_behavior(fireteam_id),
			get_node_or_null("../SimulationRoot")
		)
	)
	var bound_data: Dictionary = Dictionary(result.get("bound_complete", {})).duplicate(true)
	if not bound_data.is_empty():
		_notify_fireteam_bound_complete(fireteam_id, bound_data)
	return result


func _notify_fireteam_bound_complete(fireteam_id: String, bound_data: Dictionary) -> void:
	var event_router = get_node_or_null("../EventRouter")
	if event_router != null and event_router.has_method("notify_fireteam_bound_complete"):
		event_router.call("notify_fireteam_bound_complete", fireteam_id, bound_data)


func _update_area_defense_execution(_delta: float) -> void:
	if preview_mode or _area_defense_execution_by_fireteam.is_empty():
		return
	var did_change: bool = false
	for fireteam_id in _area_defense_execution_by_fireteam.keys().duplicate():
		var state: Dictionary = Dictionary(_area_defense_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
		if state.is_empty() or bool(state.get("waiting_for_go", false)):
			continue
		if not _are_area_defense_assignments_reached(state):
			continue
		for assignment_variant in Array(state.get("assignments", [])):
			_issue_area_defense_unit_command(String(fireteam_id), Dictionary(assignment_variant), int(state.get("phase", _get_live_order_phase_index())), true, String(state.get("area_order_id", "")))
		state["status"] = "holding"
		state["waiting_for_go"] = true
		_area_defense_execution_by_fireteam[fireteam_id] = state
		did_change = true
	if not did_change:
		return
	_last_command_text = "HALTET GEBIET"
	_refresh_order_visuals()
	refresh_fireteam_security_state()
	_update_ui()
	_emit_planning_state_changed()


func _are_area_defense_assignments_reached(state: Dictionary) -> bool:
	var assignments: Array = Array(state.get("assignments", []))
	if assignments.is_empty():
		return false
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_friendly_unit_by_id(String(assignment.get("unit_id", "")))
		if not (unit is Node2D):
			return false
		var target_position: Vector2 = Vector2(assignment.get("target_position", state.get("center_position", Vector2.ZERO)))
		if (unit as Node2D).global_position.distance_to(target_position) > AREA_DEFENSE_POSITION_REACHED_RADIUS:
			return false
	return true


func _issue_area_defense_unit_command(_fireteam_id: String, assignment: Dictionary, phase_index: int, hold_position: bool, area_order_id: String = "") -> bool:
	var unit_id: String = String(assignment.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return false
	var unit = _find_friendly_unit_by_id(unit_id)
	if unit == null:
		return false
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION
	if hold_position:
		command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
	command.priority = 13
	command.unit_id = unit_id
	command.team_id = FRIENDLY_TEAM_ID
	if unit.has_method("get_team_id"):
		command.team_id = String(unit.call("get_team_id"))
	command.target_position = Vector2(assignment.get("target_position", Vector2.ZERO))
	command.move_speed_factor = 0.85
	if hold_position:
		command.move_speed_factor = 0.0
	command.cover_score = float(assignment.get("cover_score", 0.0))
	command.attack_bonus = 0.0
	command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_HOLD_FIRE
	if hold_position:
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	command.source_command_type = "defend"
	command.source_task_type = "defend_area"
	command.target_area_id = area_order_id
	command.phase = phase_index
	if not bool(command.call("is_valid")):
		return false
	if unit.has_method("assign_unit_command"):
		unit.call("assign_unit_command", command)
	var command_dict: Dictionary = command.to_dict()
	command_dict["requeue_until_target"] = not hold_position
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null:
		return false
	simulation_root.call("enqueue_command", command_dict)
	return true


func _update_area_attack_execution(_delta: float) -> void:
	if preview_mode or _area_attack_execution_by_fireteam.is_empty():
		return
	var did_change: bool = false
	var did_start_occupation: bool = false
	var did_secure_area: bool = false
	for fireteam_id in _area_attack_execution_by_fireteam.keys().duplicate():
		var state: Dictionary = Dictionary(_area_attack_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
		if state.is_empty() or bool(state.get("waiting_for_go", false)):
			continue
		var status: String = String(state.get("status", "approaching")).strip_edges().to_lower()
		if status == "engaging" or status == "occupying":
			if not _are_area_attack_assignments_reached(state):
				continue
			if status == "engaging" and not _is_attack_area_cleared(Dictionary(state.get("target_area", {})).duplicate(true)):
				continue
			for assignment_variant in Array(state.get("assignments", [])):
				_issue_area_attack_unit_command(
					String(fireteam_id),
					Dictionary(assignment_variant),
					int(state.get("phase", _get_live_order_phase_index())),
					true,
					String(state.get("area_order_id", "")),
					String(state.get("command_type", "take"))
				)
			state["status"] = "secured"
			state["waiting_for_go"] = true
			_area_attack_execution_by_fireteam[fireteam_id] = state
			did_change = true
			did_secure_area = true
			continue
		if not _are_area_attack_assignments_reached(state):
			continue
		var target_area: Dictionary = Dictionary(state.get("target_area", {})).duplicate(true)
		var area_cleared: bool = _is_attack_area_cleared(target_area)
		var occupation_assignments: Array = _build_attack_area_occupation_assignments(String(fireteam_id), state)
		if occupation_assignments.is_empty():
			occupation_assignments = Array(state.get("assignments", [])).duplicate(true)
		state["approach_assignments"] = Array(state.get("assignments", [])).duplicate(true)
		state["assignments"] = occupation_assignments.duplicate(true)
		state["status"] = "engaging"
		if area_cleared:
			state["status"] = "occupying"
		for assignment_variant in occupation_assignments:
			_issue_area_attack_unit_command(
				String(fireteam_id),
				Dictionary(assignment_variant),
				int(state.get("phase", _get_live_order_phase_index())),
				false,
				String(state.get("area_order_id", "")),
				String(state.get("command_type", "take"))
			)
		_area_attack_execution_by_fireteam[fireteam_id] = state
		did_change = true
		did_start_occupation = true
	if not did_change:
		return
	_last_command_text = "AREA KONTAKT"
	if did_start_occupation:
		_last_command_text = "AREA BESETZEN"
	if did_secure_area:
		_last_command_text = "AREA GESICHERT"
	_refresh_order_visuals()
	refresh_fireteam_security_state()
	_update_ui()
	_emit_planning_state_changed()


func _build_attack_area_occupation_assignments(fireteam_id: String, state: Dictionary) -> Array:
	_ensure_area_order_resolver()
	if _area_order_resolver == null:
		return []
	var area_order = _area_orders_by_id.get(String(state.get("area_order_id", "")), null)
	if area_order == null:
		return []
	var units: Array = _get_fireteam_units(fireteam_id, true)
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	var resolution: Dictionary = Dictionary(_area_order_resolver.call("resolve_occupy_area", area_order, units, leader, _get_terrain_registry()))
	return Array(resolution.get("assignments", [])).duplicate(true)


func _are_area_attack_assignments_reached(state: Dictionary) -> bool:
	var assignments: Array = Array(state.get("assignments", []))
	if assignments.is_empty():
		return false
	for assignment_variant in assignments:
		var assignment: Dictionary = Dictionary(assignment_variant)
		var unit = _find_friendly_unit_by_id(String(assignment.get("unit_id", "")))
		if not (unit is Node2D):
			return false
		var target_position: Vector2 = Vector2(assignment.get("target_position", state.get("approach_position", Vector2.ZERO)))
		if (unit as Node2D).global_position.distance_to(target_position) > AREA_ATTACK_APPROACH_REACHED_RADIUS:
			return false
	return true


func _is_attack_area_cleared(target_area: Dictionary) -> bool:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver != null and combat_driver.has_method("is_area_cleared"):
		return bool(combat_driver.call("is_area_cleared", target_area))
	return true


func _issue_area_attack_unit_command(_fireteam_id: String, assignment: Dictionary, phase_index: int, hold_position: bool, area_order_id: String = "", source_command_type: String = "take") -> bool:
	var unit_id: String = String(assignment.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return false
	var unit = _find_friendly_unit_by_id(unit_id)
	if unit == null:
		return false
	var command = UNIT_COMMAND_SCRIPT.new()
	command.command_type = UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA
	if hold_position:
		command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
	command.priority = 14
	command.unit_id = unit_id
	command.team_id = FRIENDLY_TEAM_ID
	if unit.has_method("get_team_id"):
		command.team_id = String(unit.call("get_team_id"))
	command.target_position = Vector2(assignment.get("target_position", Vector2.ZERO))
	command.move_speed_factor = 0.9
	if hold_position:
		command.move_speed_factor = 0.0
	command.cover_score = float(assignment.get("cover_score", 0.0))
	command.attack_bonus = 0.0
	command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
	command.source_command_type = source_command_type
	command.source_task_type = "attack_area"
	command.target_area_id = area_order_id
	command.phase = phase_index
	if not bool(command.call("is_valid")):
		return false
	if unit.has_method("assign_unit_command"):
		unit.call("assign_unit_command", command)
	var command_dict: Dictionary = command.to_dict()
	command_dict["requeue_until_target"] = not hold_position
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null:
		return false
	simulation_root.call("enqueue_command", command_dict)
	return true


func _update_active_phase_execution(delta: float) -> void:
	if preview_mode or _phase_execution_by_fireteam.is_empty():
		return
	var did_change: bool = false
	for fireteam_id in _phase_execution_by_fireteam.keys().duplicate():
		if _ad_hoc_order_controller != null and bool(_ad_hoc_order_controller.call("has_active_order", String(fireteam_id))):
			continue
		var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
		var phase_index: int = int(execution_state.get("phase", -1))
		var plan = _order_plans_by_key.get(_build_order_plan_key(String(fireteam_id), phase_index), null)
		if plan == null:
			_phase_execution_by_fireteam.erase(fireteam_id)
			_ensure_fireteam_movement_controller()
			if _fireteam_movement_controller != null:
				_fireteam_movement_controller.call("reset_fireteam", String(fireteam_id))
			continue
		var waypoint_index: int = int(execution_state.get("waypoint_index", -1))
		if waypoint_index < 0 or waypoint_index >= plan.waypoints.size():
			_phase_execution_by_fireteam.erase(fireteam_id)
			_ensure_fireteam_movement_controller()
			if _fireteam_movement_controller != null:
				_fireteam_movement_controller.call("reset_fireteam", String(fireteam_id))
			continue
		var waypoint = plan.waypoints[waypoint_index]
		var anchor := _get_selection_anchor_for_fireteam(String(fireteam_id))
		var resolved_target_position: Vector2 = Vector2(execution_state.get("resolved_target_position", waypoint.target_position))
		_ensure_fireteam_movement_controller()
		var had_movement_execution: bool = _fireteam_movement_controller != null and bool(_fireteam_movement_controller.call("has_active_execution", String(fireteam_id)))
		var movement_result: Dictionary = _update_fireteam_movement_execution(String(fireteam_id))
		if not Dictionary(movement_result.get("bound_complete", {})).is_empty():
			did_change = true
		if anchor == null or typeof(resolved_target_position) != TYPE_VECTOR2:
			continue
		var movement_finished: bool = bool(movement_result.get("finished", false))
		var anchor_reached_target: bool = anchor.global_position.distance_to(resolved_target_position) <= PHASE_WAYPOINT_COMPLETE_RADIUS
		if had_movement_execution and not movement_finished:
			continue
		if not had_movement_execution and not anchor_reached_target:
			continue
		if String(waypoint.command_type).strip_edges().to_lower() == FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND:
			if not bool(execution_state.get("waiting_for_go", false)):
				execution_state["waiting_for_go"] = true
				_phase_execution_by_fireteam[fireteam_id] = execution_state
				did_change = true
			continue
		execution_state["hold_elapsed"] = float(execution_state.get("hold_elapsed", 0.0)) + delta
		var required_hold: float = maxf(float(waypoint.hold_duration_seconds), 0.0)
		if float(execution_state.get("hold_elapsed", 0.0)) + 0.001 < required_hold:
			_phase_execution_by_fireteam[fireteam_id] = execution_state
			continue
		waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED
		plan.active_waypoint_index = waypoint_index
		_phase_execution_by_fireteam.erase(fireteam_id)
		_ensure_fireteam_movement_controller()
		if _fireteam_movement_controller != null:
			_fireteam_movement_controller.call("reset_fireteam", String(fireteam_id))
		_notify_fireteam_ready_for_coordination(String(fireteam_id))
		if waypoint_index + 1 >= plan.waypoints.size():
			plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED
			_apply_default_fireteam_behavior(String(fireteam_id), phase_index)
		else:
			_activate_next_waypoint_for_plan(plan, String(fireteam_id), waypoint_index + 1)
		did_change = true
	if not did_change:
		return
	if _phase_execution_by_fireteam.is_empty():
		var phase_controller = _get_phase_controller()
		if phase_controller != null and phase_controller.has_method("get_active_phase_name"):
			_last_command_text = "%s COMPLETE" % String(phase_controller.call("get_active_phase_name"))
	_refresh_order_visuals()
	_update_ui()
	_emit_planning_state_changed()


func _update_ad_hoc_execution(delta: float) -> void:
	_ensure_ad_hoc_order_controller()
	if preview_mode or _ad_hoc_order_controller == null or _ad_hoc_execution_by_fireteam.is_empty():
		return
	var did_change: bool = false
	for fireteam_id in _ad_hoc_execution_by_fireteam.keys().duplicate():
		var order_dict: Dictionary = Dictionary(_ad_hoc_order_controller.call("get_active_order", String(fireteam_id)))
		if order_dict.is_empty():
			_ad_hoc_execution_by_fireteam.erase(fireteam_id)
			_ensure_fireteam_movement_controller()
			if _fireteam_movement_controller != null:
				_fireteam_movement_controller.call("reset_fireteam", String(fireteam_id))
			continue
		var execution_state: Dictionary = Dictionary(_ad_hoc_execution_by_fireteam.get(fireteam_id, {})).duplicate(true)
		var order_type: String = String(order_dict.get("order_type", ""))
		if order_type == AD_HOC_ORDER_SCRIPT.ORDER_TYPE_HOLD_TILL_LAST_MAN:
			if _count_fit_units_for_fireteam(String(fireteam_id)) <= 0:
				_return_fireteam_to_plan(String(fireteam_id), false)
				did_change = true
			continue
		var movement_result: Dictionary = _update_fireteam_movement_execution(String(fireteam_id))
		if not Dictionary(movement_result.get("bound_complete", {})).is_empty():
			did_change = true
		var anchor := _get_selection_anchor_for_fireteam(String(fireteam_id))
		if anchor == null:
			continue
		var target_position: Vector2 = Vector2(execution_state.get("target_position", anchor.global_position))
		if anchor.global_position.distance_to(target_position) > AD_HOC_ORDER_COMPLETE_RADIUS:
			continue
		execution_state["hold_elapsed"] = float(execution_state.get("hold_elapsed", 0.0)) + delta
		if float(execution_state.get("hold_elapsed", 0.0)) < 0.25:
			_ad_hoc_execution_by_fireteam[fireteam_id] = execution_state
			continue
		_return_fireteam_to_plan(String(fireteam_id), false)
		did_change = true
	if did_change:
		_refresh_order_visuals()
		_refresh_ad_hoc_panel_visibility()
		_update_ui()
		_emit_planning_state_changed()


func _extract_waypoint_sequence(waypoint_id: String) -> int:
	var parts: PackedStringArray = waypoint_id.strip_edges().split("_")
	if parts.size() < 2:
		return 0
	return int(parts[parts.size() - 1])


func _extract_area_order_sequence(area_order_id: String) -> int:
	var parts: PackedStringArray = area_order_id.strip_edges().split("_")
	if parts.size() < 2:
		return 0
	return int(parts[parts.size() - 1])


func _is_fireteam_eligible_for_ad_hoc(fireteam_id: String) -> bool:
	if fireteam_id.is_empty():
		return false
	if _is_fireteam_in_combat(fireteam_id):
		return true
	var suppression_state: Dictionary = Dictionary(_suppression_state_by_fireteam.get(fireteam_id, {}))
	return float(suppression_state.get("value", 0.0)) > 0.25


func _is_fireteam_in_combat(fireteam_id: String) -> bool:
	for unit in _get_units_for_fireteam(fireteam_id):
		if unit != null and unit.has_method("is_in_contact") and bool(unit.call("is_in_contact")):
			return true
	return false


func _get_units_for_fireteam(fireteam_id: String) -> Array:
	return _get_fireteam_units(fireteam_id, true)


func _count_fit_units_for_fireteam(fireteam_id: String) -> int:
	var count: int = 0
	for unit in _get_units_for_fireteam(fireteam_id):
		if unit != null and unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) == "fit":
			count += 1
	return count


func _return_fireteam_to_plan(fireteam_id: String, manual_return: bool) -> bool:
	_ensure_ad_hoc_order_controller()
	var had_active_ad_hoc: bool = _ad_hoc_order_controller != null and bool(_ad_hoc_order_controller.call("has_active_order", fireteam_id))
	if had_active_ad_hoc:
		var method_name: String = "cancel_order" if manual_return else "complete_order"
		var reason: String = "manual_return" if manual_return else "completed"
		_ad_hoc_order_controller.call(method_name, fireteam_id, reason)
	var event_router = get_node_or_null("../EventRouter")
	if event_router != null and event_router.has_method("request_return_to_plan"):
		event_router.call("request_return_to_plan", fireteam_id, "manual" if manual_return else "auto")
	_ad_hoc_execution_by_fireteam.erase(fireteam_id)
	_ad_hoc_resume_state_by_fireteam.erase(fireteam_id)
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	_suppression_interrupt_pending_by_fireteam[fireteam_id] = false
	var active_phase_index: int = _get_live_order_phase_index()
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, active_phase_index), null)
	if plan == null or plan.waypoints.is_empty():
		return _apply_default_fireteam_behavior(fireteam_id, active_phase_index) or had_active_ad_hoc
	var next_pending_index: int = -1
	for waypoint_index in range(plan.waypoints.size()):
		var waypoint_status: String = String(plan.waypoints[waypoint_index].status)
		if waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED:
			plan.waypoints[waypoint_index].status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
			next_pending_index = waypoint_index
			break
	if next_pending_index < 0:
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED
		return _apply_default_fireteam_behavior(fireteam_id, active_phase_index) or had_active_ad_hoc
	var resumed: bool = _activate_next_waypoint_for_plan(plan, fireteam_id, next_pending_index) or had_active_ad_hoc
	_apply_fireteam_coordination_for_phase(active_phase_index)
	return resumed


func _count_selected_phase_waypoints() -> int:
	return _count_selected_phase_waypoints_for_fireteams(_selected_fireteam_ids)


func _count_selected_defend_area_orders() -> int:
	var count: int = 0
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		for area_order in _area_orders_by_id.values():
			if area_order == null:
				continue
			if String(area_order.fireteam_id).strip_edges().to_lower() != fireteam_id:
				continue
			if String(area_order.command_type) != AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND:
				continue
			if String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_COMPLETED or String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_CANCELLED:
				continue
			count += 1
	return count


func _count_selected_area_orders() -> int:
	var count: int = 0
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		for area_order in _area_orders_by_id.values():
			if area_order == null:
				continue
			if String(area_order.fireteam_id).strip_edges().to_lower() != fireteam_id:
				continue
			if String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_COMPLETED or String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_CANCELLED:
				continue
			count += 1
	return count


func _count_selected_phase_waypoints_for_fireteams(fireteam_ids: PackedStringArray) -> int:
	var total: int = 0
	for fireteam_id in fireteam_ids:
		var plan = _order_plans_by_key.get(_build_order_plan_key(String(fireteam_id), _get_live_order_phase_index()), null)
		if plan == null:
			continue
		for waypoint in plan.waypoints:
			if waypoint != null and String(waypoint.status) != FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED:
				total += 1
	return total


func _find_waypoint_target_at_screen_position(screen_position: Vector2) -> Dictionary:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("world_to_screen_position"):
		for waypoint_variant in get_visualized_waypoints_snapshot():
			if typeof(waypoint_variant) != TYPE_DICTIONARY:
				continue
			var waypoint_data_3d: Dictionary = Dictionary(waypoint_variant)
			if typeof(waypoint_data_3d.get("position", null)) != TYPE_VECTOR2:
				continue
			var marker_screen_position: Vector2 = primary_3d_view.call("world_to_screen_position", Vector2(waypoint_data_3d.get("position", Vector2.ZERO)))
			if marker_screen_position.distance_to(screen_position) <= 20.0:
				return {
					"fireteam_id": String(waypoint_data_3d.get("fireteam_id", "")).strip_edges().to_lower(),
					"phase": int(waypoint_data_3d.get("phase", _current_phase_index)),
					"waypoint_id": String(waypoint_data_3d.get("waypoint_id", "")).strip_edges(),
				}
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_waypoint_hit"):
		return {}
	var waypoint_data: Dictionary = visualizer.call("get_waypoint_hit", screen_position, get_viewport().get_canvas_transform())
	if waypoint_data.is_empty():
		return {}
	return {
		"fireteam_id": String(waypoint_data.get("fireteam_id", "")).strip_edges().to_lower(),
		"phase": int(waypoint_data.get("phase", _current_phase_index)),
		"waypoint_id": String(waypoint_data.get("waypoint_id", "")).strip_edges(),
	}


func _find_area_order_target_at_screen_position(screen_position: Vector2) -> Dictionary:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("world_to_screen_position"):
		for area_variant in get_visualized_area_orders_snapshot():
			if typeof(area_variant) != TYPE_DICTIONARY:
				continue
			var area_order_data_3d: Dictionary = Dictionary(area_variant)
			if typeof(area_order_data_3d.get("center_position", null)) == TYPE_VECTOR2:
				var center_screen_position: Vector2 = primary_3d_view.call("world_to_screen_position", Vector2(area_order_data_3d.get("center_position", Vector2.ZERO)))
				if center_screen_position.distance_to(screen_position) <= 28.0:
					return {
						"area_order_id": String(area_order_data_3d.get("area_order_id", "")).strip_edges(),
						"fireteam_id": String(area_order_data_3d.get("fireteam_id", "")).strip_edges().to_lower(),
					}
			for tile_world_position_variant in Array(area_order_data_3d.get("tile_world_positions", [])):
				var tile_screen_position: Vector2 = primary_3d_view.call("world_to_screen_position", Vector2(tile_world_position_variant))
				if tile_screen_position.distance_to(screen_position) <= 22.0:
					return {
						"area_order_id": String(area_order_data_3d.get("area_order_id", "")).strip_edges(),
						"fireteam_id": String(area_order_data_3d.get("fireteam_id", "")).strip_edges().to_lower(),
					}
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_area_order_hit"):
		return {}
	var area_order_data: Dictionary = visualizer.call("get_area_order_hit", screen_position, get_viewport().get_canvas_transform())
	if area_order_data.is_empty():
		return {}
	return {
		"area_order_id": String(area_order_data.get("area_order_id", "")).strip_edges(),
		"fireteam_id": String(area_order_data.get("fireteam_id", "")).strip_edges().to_lower(),
	}


func _begin_area_order_interaction(screen_position: Vector2) -> bool:
	if _is_lz_placement_armed or _is_target_placement_armed:
		return false
	if _selected_fireteam_ids.is_empty():
		_last_command_text = "SELECT FIRETEAM FIRST"
		_update_ui()
		return false
	_area_order_press_active = true
	_area_order_drag_active = false
	_area_order_press_screen_position = screen_position
	_area_order_drag_screen_position = screen_position
	_hide_waypoint_command_menu()
	_hide_area_order_command_menu()
	_update_area_order_overlay(Rect2())
	return true


func _update_area_order_drag(screen_position: Vector2) -> bool:
	if not _area_order_press_active:
		return false
	_area_order_drag_screen_position = screen_position
	if not _area_order_drag_active and _area_order_press_screen_position.distance_to(screen_position) < AREA_ORDER_DRAG_THRESHOLD:
		return true
	_area_order_drag_active = true
	_update_area_order_overlay(_build_selection_rect(_area_order_press_screen_position, screen_position))
	return true


func _finish_area_order_interaction(screen_position: Vector2) -> bool:
	if not _area_order_press_active:
		return false
	var was_dragging: bool = _area_order_drag_active
	var start_position: Vector2 = _area_order_press_screen_position
	_area_order_press_active = false
	_area_order_drag_active = false
	_update_area_order_overlay(Rect2())
	if not was_dragging:
		return true
	var area_order_targets: Array = _create_area_orders_for_selected_fireteams_from_screen_rect(_build_selection_rect(start_position, screen_position))
	if area_order_targets.is_empty():
		_last_command_text = "AREA EMPTY"
		_update_ui()
		return true
	_open_area_order_command_menu(screen_position, area_order_targets, false)
	return true


func _try_begin_waypoint_drag(screen_position: Vector2) -> bool:
	if _is_lz_placement_armed or _is_target_placement_armed:
		return false
	var waypoint_ref: Dictionary = _find_waypoint_target_at_screen_position(screen_position)
	if waypoint_ref.is_empty():
		return false
	_dragged_waypoint_ref = waypoint_ref.duplicate(true)
	_focused_waypoint_ref = waypoint_ref.duplicate(true)
	_dragged_waypoint_press_screen_position = screen_position
	_is_dragging_waypoint = true
	_has_dragged_waypoint = false
	_hide_waypoint_command_menu()
	return true


func _update_waypoint_drag(screen_position: Vector2) -> bool:
	if not _is_dragging_waypoint or _dragged_waypoint_ref.is_empty():
		return false
	if not _has_dragged_waypoint and _dragged_waypoint_press_screen_position.distance_to(screen_position) < WAYPOINT_DRAG_THRESHOLD:
		return true
	_has_dragged_waypoint = true
	_update_waypoint_targets([_dragged_waypoint_ref], _clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
	return true


func _finish_waypoint_drag(screen_position: Vector2) -> bool:
	if not _is_dragging_waypoint:
		return false
	if _has_dragged_waypoint:
		_update_waypoint_targets([_dragged_waypoint_ref], _clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
		_last_command_text = "WAYPOINT MOVED"
		_update_ui()
		_emit_planning_state_changed()
	_is_dragging_waypoint = false
	_has_dragged_waypoint = false
	_dragged_waypoint_ref = {}
	return true


func _delete_focused_waypoint() -> bool:
	if _focused_waypoint_ref.is_empty():
		return false
	var did_delete: bool = _delete_waypoint_targets([_focused_waypoint_ref])
	if did_delete:
		_focused_waypoint_ref = {}
		_hide_waypoint_command_menu()
	return did_delete


func _delete_focused_area_order() -> bool:
	if _focused_area_order_ref.is_empty():
		return false
	var did_delete: bool = _delete_area_order_targets([_focused_area_order_ref])
	if did_delete:
		_focused_area_order_ref = {}
		_hide_area_order_command_menu()
	return did_delete


func _open_waypoint_command_menu(screen_position: Vector2, waypoint_targets: Array, include_delete_action: bool) -> void:
	var menu := get_node_or_null("../TacticalUI/WaypointCommandMenu") as PopupMenu
	if menu == null:
		return
	_waypoint_menu_targets = []
	for waypoint_target in waypoint_targets:
		_waypoint_menu_targets.append(Dictionary(waypoint_target).duplicate(true))
	menu.clear()
	for marker_type_id in PackedStringArray(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_type_ids_for_context", TERRAIN_MARKER_CATALOG_SCRIPT.CONTEXT_MISSION_PLAYER)):
		menu.add_item(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)), _waypoint_menu_id_for_command(String(marker_type_id)))
	if include_delete_action:
		menu.add_separator()
		menu.add_item("Delete", WAYPOINT_MENU_DELETE_ID)
	menu.reset_size()
	menu.position = screen_position + Vector2(10.0, 10.0)
	menu.popup()


func _open_area_order_command_menu(screen_position: Vector2, area_order_targets: Array, include_delete_action: bool) -> void:
	var menu := get_node_or_null("../TacticalUI/AreaOrderCommandMenu") as PopupMenu
	if menu == null:
		return
	_area_order_menu_targets = []
	for area_order_target in area_order_targets:
		_area_order_menu_targets.append(Dictionary(area_order_target).duplicate(true))
	menu.clear()
	menu.add_item("Defend Area", AREA_ORDER_MENU_DEFEND_ID)
	menu.add_item("Engage Area", AREA_ORDER_MENU_ENGAGE_ID)
	menu.add_item("Take Area", AREA_ORDER_MENU_TAKE_ID)
	menu.add_item("Flank Area", AREA_ORDER_MENU_FLANK_ID)
	if include_delete_action:
		menu.add_separator()
		menu.add_item("Delete", AREA_ORDER_MENU_DELETE_ID)
	menu.reset_size()
	menu.position = screen_position + Vector2(10.0, 10.0)
	menu.popup()


func _hide_waypoint_command_menu() -> void:
	var menu := get_node_or_null("../TacticalUI/WaypointCommandMenu") as PopupMenu
	if menu != null:
		menu.hide()
	_waypoint_menu_targets.clear()


func _hide_area_order_command_menu() -> void:
	var menu := get_node_or_null("../TacticalUI/AreaOrderCommandMenu") as PopupMenu
	if menu != null:
		menu.hide()
	_area_order_menu_targets.clear()


func _on_waypoint_menu_id_pressed(item_id: int) -> void:
	match item_id:
		WAYPOINT_MENU_MOVE_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE)
		WAYPOINT_MENU_DEFEND_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND)
		WAYPOINT_MENU_ENGAGE_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE)
		WAYPOINT_MENU_FLANK_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK)
		WAYPOINT_MENU_TAKE_ID:
			_set_waypoint_command_for_targets(_waypoint_menu_targets, FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE)
		WAYPOINT_MENU_DELETE_ID:
			_delete_waypoint_targets(_waypoint_menu_targets)
	_hide_waypoint_command_menu()


func _on_area_order_menu_id_pressed(item_id: int) -> void:
	match item_id:
		AREA_ORDER_MENU_DEFEND_ID:
			_set_area_order_command_for_targets(_area_order_menu_targets, AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND)
		AREA_ORDER_MENU_ENGAGE_ID:
			_set_area_order_command_for_targets(_area_order_menu_targets, AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE)
		AREA_ORDER_MENU_TAKE_ID:
			_set_area_order_command_for_targets(_area_order_menu_targets, AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE)
		AREA_ORDER_MENU_FLANK_ID:
			_set_area_order_command_for_targets(_area_order_menu_targets, AREA_ORDER_SCRIPT.COMMAND_TYPE_FLANK)
		AREA_ORDER_MENU_DELETE_ID:
			_delete_area_order_targets(_area_order_menu_targets)
	_hide_area_order_command_menu()


func _set_waypoint_command_for_targets(waypoint_targets: Array, command_type: String) -> bool:
	var did_change: bool = false
	for waypoint_target in waypoint_targets:
		var waypoint = _get_waypoint_from_ref(Dictionary(waypoint_target))
		if waypoint == null:
			continue
		waypoint.command_type = command_type
		did_change = true
	if not did_change:
		return false
	_refresh_order_visuals()
	_last_command_text = "WAYPOINT %s" % command_type.to_upper()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _set_area_order_command_for_targets(area_order_targets: Array, command_type: String) -> bool:
	var normalized_command_type: String = _normalize_area_order_command_type(command_type)
	var did_change: bool = false
	for area_order_target in area_order_targets:
		var area_order = _get_area_order_from_ref(Dictionary(area_order_target))
		if area_order == null:
			continue
		area_order.command_type = normalized_command_type
		did_change = true
	if not did_change:
		return false
	_refresh_order_visuals()
	_last_command_text = "AREA %s" % normalized_command_type.to_upper()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _update_waypoint_targets(waypoint_targets: Array, world_position: Vector2) -> bool:
	var snapped_world_position: Vector2 = _snap_planning_position_to_tile_center(world_position)
	var did_change: bool = false
	for waypoint_target in waypoint_targets:
		var waypoint = _get_waypoint_from_ref(Dictionary(waypoint_target))
		if waypoint == null:
			continue
		waypoint.target_position = snapped_world_position
		did_change = true
	if not did_change:
		return false
	_refresh_order_visuals()
	_update_ui()
	return true


func _delete_area_order_targets(area_order_targets: Array) -> bool:
	var did_delete: bool = false
	for area_order_target in area_order_targets:
		var area_order_id: String = String(Dictionary(area_order_target).get("area_order_id", "")).strip_edges()
		if area_order_id.is_empty() or not _area_orders_by_id.has(area_order_id):
			continue
		_area_orders_by_id.erase(area_order_id)
		did_delete = true
	if not did_delete:
		return false
	_refresh_order_visuals()
	_last_command_text = "AREA DELETED"
	_update_ui()
	_emit_planning_state_changed()
	return true


func _get_area_order_from_ref(area_order_target: Dictionary):
	var area_order_id: String = String(area_order_target.get("area_order_id", "")).strip_edges()
	if area_order_id.is_empty() or not _area_orders_by_id.has(area_order_id):
		return null
	return _area_orders_by_id[area_order_id]


func _waypoint_menu_id_for_command(command_type: String) -> int:
	match command_type.strip_edges().to_lower():
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_MOVE:
			return WAYPOINT_MENU_MOVE_ID
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_DEFEND:
			return WAYPOINT_MENU_DEFEND_ID
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_ENGAGE:
			return WAYPOINT_MENU_ENGAGE_ID
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_FLANK:
			return WAYPOINT_MENU_FLANK_ID
		FIRETEAM_WAYPOINT_SCRIPT.COMMAND_TYPE_TAKE:
			return WAYPOINT_MENU_TAKE_ID
	return WAYPOINT_MENU_MOVE_ID


func _normalize_area_order_command_type(command_type: String) -> String:
	var normalized_command_type: String = command_type.strip_edges().to_lower()
	if AREA_ORDER_SCRIPT.call("is_allowed_command_type", normalized_command_type):
		return normalized_command_type
	return AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND


func _build_area_order_payload_from_screen_rect(screen_rect: Rect2) -> Dictionary:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("screen_rect_to_tile_world_positions"):
		var terrain_registry_3d = _get_terrain_registry()
		var tile_entries_3d: Array = []
		for tile_world_position_variant in Array(primary_3d_view.call("screen_rect_to_tile_world_positions", screen_rect)):
			if terrain_registry_3d == null or not terrain_registry_3d.has_method("get_tile_at_world"):
				continue
			var tile_data = terrain_registry_3d.call("get_tile_at_world", Vector2(tile_world_position_variant))
			if tile_data != null:
				tile_entries_3d.append(tile_data)
		var tile_payload_3d: Dictionary = _build_area_order_payload_from_tiles(tile_entries_3d)
		if not tile_payload_3d.is_empty():
			return tile_payload_3d
		var world_polygon_3d: PackedVector2Array = PackedVector2Array([
			_screen_to_world_position(screen_rect.position),
			_screen_to_world_position(Vector2(screen_rect.end.x, screen_rect.position.y)),
			_screen_to_world_position(screen_rect.end),
			_screen_to_world_position(Vector2(screen_rect.position.x, screen_rect.end.y)),
		])
		return {
			"tile_positions": [],
			"tile_world_positions": [],
			"world_polygon": world_polygon_3d,
			"center_position": _average_polygon_points(world_polygon_3d),
		}

	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null and terrain_registry.has_method("get_all_tiles"):
		var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
		var tile_entries: Array = []
		for tile_data in Array(terrain_registry.call("get_all_tiles")):
			if tile_data == null or typeof(tile_data.world_position) != TYPE_VECTOR2:
				continue
			var tile_screen_position: Vector2 = canvas_transform * Vector2(tile_data.world_position)
			if screen_rect.has_point(tile_screen_position):
				tile_entries.append(tile_data)
		var tile_payload: Dictionary = _build_area_order_payload_from_tiles(tile_entries)
		if not tile_payload.is_empty():
			return tile_payload

	var world_polygon: PackedVector2Array = PackedVector2Array([
		_screen_to_world_position(screen_rect.position),
		_screen_to_world_position(Vector2(screen_rect.end.x, screen_rect.position.y)),
		_screen_to_world_position(screen_rect.end),
		_screen_to_world_position(Vector2(screen_rect.position.x, screen_rect.end.y)),
	])
	return {
		"tile_positions": [],
		"tile_world_positions": [],
		"world_polygon": world_polygon,
		"center_position": _average_polygon_points(world_polygon),
	}


func _build_area_order_payload_from_world_rect(start_world_position: Vector2, end_world_position: Vector2) -> Dictionary:
	var world_rect := Rect2(
		Vector2(minf(start_world_position.x, end_world_position.x), minf(start_world_position.y, end_world_position.y)),
		Vector2(absf(end_world_position.x - start_world_position.x), absf(end_world_position.y - start_world_position.y))
	)
	var terrain_registry = _get_terrain_registry()
	if terrain_registry != null and terrain_registry.has_method("get_all_tiles"):
		var tile_entries: Array = []
		for tile_data in Array(terrain_registry.call("get_all_tiles")):
			if tile_data == null or typeof(tile_data.world_position) != TYPE_VECTOR2:
				continue
			if world_rect.has_point(Vector2(tile_data.world_position)):
				tile_entries.append(tile_data)
		var tile_payload: Dictionary = _build_area_order_payload_from_tiles(tile_entries)
		if not tile_payload.is_empty():
			return tile_payload
	var world_polygon: PackedVector2Array = PackedVector2Array([
		world_rect.position,
		Vector2(world_rect.end.x, world_rect.position.y),
		world_rect.end,
		Vector2(world_rect.position.x, world_rect.end.y),
	])
	return {
		"tile_positions": [],
		"tile_world_positions": [],
		"world_polygon": world_polygon,
		"center_position": _average_polygon_points(world_polygon),
	}


func _build_area_order_payload_from_tiles(tile_entries: Array) -> Dictionary:
	if tile_entries.is_empty():
		return {}
	var sorted_entries: Array = []
	for tile_data in tile_entries:
		if tile_data == null or typeof(tile_data.grid_position) != TYPE_VECTOR2I or typeof(tile_data.world_position) != TYPE_VECTOR2:
			continue
		sorted_entries.append({
			"grid_position": Vector2i(tile_data.grid_position),
			"world_position": Vector2(tile_data.world_position),
		})
	if sorted_entries.is_empty():
		return {}
	sorted_entries.sort_custom(_sort_area_tile_entries)

	var tile_positions: Array = []
	var tile_world_positions: Array = []
	var center_position := Vector2.ZERO
	for entry_variant in sorted_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		tile_positions.append(Vector2i(entry.get("grid_position", Vector2i.ZERO)))
		var world_position: Vector2 = Vector2(entry.get("world_position", Vector2.ZERO))
		tile_world_positions.append(world_position)
		center_position += world_position
	center_position /= float(tile_world_positions.size())
	return {
		"tile_positions": tile_positions,
		"tile_world_positions": tile_world_positions,
		"world_polygon": _build_world_polygon_for_area_tile_positions(tile_world_positions),
		"center_position": center_position,
	}


func _sort_area_tile_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_grid: Vector2i = Vector2i(a.get("grid_position", Vector2i.ZERO))
	var b_grid: Vector2i = Vector2i(b.get("grid_position", Vector2i.ZERO))
	if a_grid.x == b_grid.x:
		return a_grid.y < b_grid.y
	return a_grid.x < b_grid.x


func _build_world_polygon_for_area_tile_positions(tile_world_positions: Array) -> PackedVector2Array:
	if tile_world_positions.is_empty():
		return PackedVector2Array()
	var hull_points: PackedVector2Array = PackedVector2Array()
	for world_position_variant in tile_world_positions:
		var world_position: Vector2 = Vector2(world_position_variant)
		hull_points.append(world_position + Vector2(0.0, -AREA_ORDER_ISO_TILE_HALF_HEIGHT))
		hull_points.append(world_position + Vector2(AREA_ORDER_ISO_TILE_HALF_WIDTH, 0.0))
		hull_points.append(world_position + Vector2(0.0, AREA_ORDER_ISO_TILE_HALF_HEIGHT))
		hull_points.append(world_position + Vector2(-AREA_ORDER_ISO_TILE_HALF_WIDTH, 0.0))
	if hull_points.size() <= 3:
		return hull_points
	return Geometry2D.convex_hull(hull_points)


func _average_polygon_points(polygon: PackedVector2Array) -> Vector2:
	if polygon.is_empty():
		return Vector2.ZERO
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	return center / float(polygon.size())


func _get_next_area_order_index_for_fireteam(fireteam_id: String) -> int:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var order_count: int = 0
	var plan = _order_plans_by_key.get(_build_order_plan_key(normalized_fireteam_id, _get_live_order_phase_index()), null)
	if plan != null:
		order_count += plan.waypoints.size()
	for area_order in _area_orders_by_id.values():
		if area_order != null and String(area_order.fireteam_id).strip_edges().to_lower() == normalized_fireteam_id:
			order_count += 1
	return order_count


func _snap_planning_position_to_tile_center(world_position: Vector2) -> Vector2:
	var clamped_world_position: Vector2 = _clamp_world_position_to_viewport(world_position)
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_tile_at_world"):
		return clamped_world_position
	var tile_data = terrain_registry.call("get_tile_at_world", clamped_world_position)
	if tile_data == null:
		return clamped_world_position
	if typeof(tile_data.world_position) == TYPE_VECTOR2:
		return Vector2(tile_data.world_position)
	return clamped_world_position


func _delete_waypoint_targets(waypoint_targets: Array) -> bool:
	var did_delete: bool = false
	for waypoint_target in waypoint_targets:
		if _remove_waypoint_from_plan(Dictionary(waypoint_target)):
			did_delete = true
	if not did_delete:
		return false
	_refresh_order_visuals()
	_last_command_text = "WAYPOINT DELETED"
	_update_ui()
	_emit_planning_state_changed()
	return true


func _remove_waypoint_from_plan(waypoint_target: Dictionary) -> bool:
	var fireteam_id: String = String(waypoint_target.get("fireteam_id", "")).strip_edges().to_lower()
	var phase_index: int = int(waypoint_target.get("phase", _current_phase_index))
	var plan_key: String = _build_order_plan_key(fireteam_id, phase_index)
	var plan = _order_plans_by_key.get(plan_key, null)
	if plan == null:
		return false
	var waypoint_id: String = String(waypoint_target.get("waypoint_id", "")).strip_edges()
	for index in range(plan.waypoints.size()):
		var waypoint = plan.waypoints[index]
		if String(waypoint.waypoint_id) != waypoint_id:
			continue
		plan.waypoints.remove_at(index)
		if plan.waypoints.is_empty():
			_order_plans_by_key.erase(plan_key)
		return true
	return false


func _get_waypoint_from_ref(waypoint_target: Dictionary):
	var fireteam_id: String = String(waypoint_target.get("fireteam_id", "")).strip_edges().to_lower()
	var phase_index: int = int(waypoint_target.get("phase", _current_phase_index))
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, phase_index), null)
	if plan == null:
		return null
	var waypoint_id: String = String(waypoint_target.get("waypoint_id", "")).strip_edges()
	for waypoint in plan.waypoints:
		if String(waypoint.waypoint_id) == waypoint_id:
			return waypoint
	return null


func _maybe_bootstrap_live_drop() -> void:
	if preview_mode or _live_drop_bootstrap_consumed:
		return
	if not _drop_ship_requested or not _has_lz_position:
		return
	if not is_inside_tree():
		return
	if not is_node_ready():
		call_deferred("_maybe_bootstrap_live_drop")
		return
	if _try_start_drop_sequence():
		_live_drop_bootstrap_consumed = true


func _try_start_drop_sequence() -> bool:
	if not _has_lz_position:
		return false
	if not preview_mode and _drop_ship_cooldown_remaining > 0.0:
		return false
	if not preview_mode and _live_drop_bootstrap_consumed and _drop_sequence_phase == DROP_SEQUENCE_COMPLETE:
		return false
	if _is_drop_sequence_active():
		return false
	var pending_units: Array = []
	for unit in _get_units_for_drop_operation():
		var unit_id: String = String(unit.call("get_unit_id"))
		if _deployed_unit_ids.has(unit_id):
			continue
		pending_units.append(unit)
	if preview_mode:
		if _mission_drop_state != "waiting":
			return false
		if pending_units.is_empty():
			return false
		_embark_units_for_drop(pending_units)
		_drop_sequence_units = pending_units
		_drop_sequence_fireteam_name = _get_drop_fireteam_name()
		_drop_sequence_unit_index = 0
		_drop_sequence_timer = 0.0
		_drop_sequence_phase = DROP_SEQUENCE_INBOUND
		_drop_ship_staged = true
		_drop_sequence_visual_only = false
		_drop_sequence_position = _get_drop_staging_position()
		_emit_planning_state_changed()
		_refresh_world_overlays()
		_update_ui()
		return true
	if pending_units.is_empty():
		return false
	_embark_units_for_drop(pending_units)
	_drop_sequence_units = pending_units
	_drop_sequence_fireteam_name = _get_drop_fireteam_name()
	_drop_sequence_unit_index = 0
	_drop_sequence_timer = 0.0
	_drop_sequence_phase = DROP_SEQUENCE_INBOUND
	_drop_ship_staged = true
	_drop_sequence_visual_only = false
	_drop_sequence_position = _get_drop_staging_position()
	_live_drop_bootstrap_consumed = true
	_refresh_world_overlays()
	_update_ui()
	return true


func _embark_units_for_drop(units: Array) -> void:
	var staging_position: Vector2 = _get_drop_staging_position()
	for index in range(units.size()):
		var unit = units[index]
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		_embarked_unit_ids[unit_id] = true
		var embark_position: Vector2 = staging_position + Vector2(-18.0 * index, 10.0 * index)
		if preview_mode:
			if unit is Node2D:
				(unit as Node2D).global_position = embark_position
			if unit is CanvasItem:
				(unit as CanvasItem).visible = false
		else:
			_enqueue_dropship_embark_effect(unit, unit_id, embark_position)


func _update_drop_sequence(delta: float) -> void:
	match _drop_sequence_phase:
		DROP_SEQUENCE_INBOUND:
			_drop_sequence_position = _drop_sequence_position.move_toward(_lz_position, DROP_SHIP_SPEED * delta)
			if _drop_sequence_position.distance_to(_lz_position) <= 2.0:
				_drop_sequence_position = _lz_position
				if _drop_sequence_visual_only:
					_drop_sequence_phase = DROP_SEQUENCE_LANDED
					_drop_sequence_timer = 0.0
					_last_command_text = "DROPSHIP LANDED"
					_update_ui()
				else:
					_complete_drop_sequence_deployment()
					_begin_drop_sequence_outbound()
			_refresh_world_overlays()
		DROP_SEQUENCE_LANDED:
			if _drop_sequence_visual_only:
				_refresh_world_overlays()
				return
			_complete_drop_sequence_deployment()
			_begin_drop_sequence_outbound()
		DROP_SEQUENCE_UNLOADING:
			_complete_drop_sequence_deployment()
			_begin_drop_sequence_outbound()
		DROP_SEQUENCE_COMPLETE:
			_begin_drop_sequence_outbound()
		DROP_SEQUENCE_OUTBOUND:
			var exit_position: Vector2 = _get_drop_exit_position()
			_drop_sequence_position = _drop_sequence_position.move_toward(exit_position, DROP_SHIP_SPEED * delta)
			if _drop_sequence_position.distance_to(exit_position) <= 2.0:
				_drop_ship_cooldown_remaining = DROP_SHIP_RECALL_COOLDOWN_SECONDS
				_drop_ship_requested = false
				_drop_ship_staged = false
				_mission_drop_state = "to_fob"
				_mission_drop_progress = 0.0
				_mission_drop_return_requested = false
				_drop_sequence_position = Vector2.ZERO
				_drop_sequence_phase = ""
				_drop_sequence_units = []
				_drop_sequence_unit_index = 0
				_drop_sequence_timer = 0.0
				_drop_sequence_fireteam_name = "ALL"
				_drop_sequence_visual_only = false
				_live_drop_bootstrap_consumed = false
				_last_command_text = "DROPSHIP CLEARED"
				_emit_planning_state_changed()
				_update_ui()
				_refresh_world_overlays()
			_refresh_world_overlays()


func _complete_drop_sequence_deployment() -> void:
	if _drop_sequence_visual_only:
		return
	if _drop_sequence_phase != DROP_SEQUENCE_UNLOADING:
		_drop_sequence_phase = DROP_SEQUENCE_UNLOADING
		_last_command_text = "DEBOARDING %s" % _drop_sequence_fireteam_name
	while _drop_sequence_unit_index < _drop_sequence_units.size():
		_deploy_next_embarked_unit()
	_mission_drop_passenger_count = _embarked_unit_ids.size()
	_drop_sequence_position = _lz_position
	_emit_planning_state_changed()


func _begin_drop_sequence_outbound() -> void:
	if _drop_sequence_visual_only:
		return
	_mission_drop_state = "to_fob"
	_mission_drop_passenger_count = _embarked_unit_ids.size()
	_mission_drop_return_requested = true
	_drop_sequence_phase = DROP_SEQUENCE_OUTBOUND
	_drop_sequence_timer = 0.0
	_last_command_text = "DROPSHIP RTB"
	_emit_planning_state_changed()
	_update_ui()
	_refresh_world_overlays()


func _deploy_next_embarked_unit() -> void:
	if _drop_sequence_unit_index >= _drop_sequence_units.size():
		return
	var unit = _drop_sequence_units[_drop_sequence_unit_index]
	var unload_index: int = _drop_sequence_unit_index
	_drop_sequence_unit_index += 1
	if unit == null or not unit.has_method("get_unit_id"):
		return
	var unit_id: String = String(unit.call("get_unit_id"))
	_embarked_unit_ids.erase(unit_id)
	_deployed_unit_ids[unit_id] = true
	var deploy_position: Vector2 = _lz_position + _get_unload_offset(unload_index)
	if preview_mode:
		if unit is Node2D:
			(unit as Node2D).global_position = deploy_position
		if unit is CanvasItem:
			(unit as CanvasItem).visible = true
		if unit.has_method("set_runtime_status"):
			unit.call("set_runtime_status", "idle")
		if unit.has_method("refresh_terrain_readability"):
			unit.call("refresh_terrain_readability")
	else:
		_enqueue_dropship_deploy_effect(unit, unit_id, deploy_position)
		_fireteam_runtime_ui_refresh_frames_remaining = 6
	if unit.has_method("show_event_text"):
		unit.call("show_event_text", "DISEMBARK", Color(0.55, 1.0, 0.72, 1.0), 1.5)
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower() if unit.has_method("get_fireteam_id") else ""
	if not fireteam_id.is_empty():
		if preview_mode:
			_maybe_start_active_phase_for_fireteam(fireteam_id)
		else:
			_runtime_activation_pending_fireteam_ids[fireteam_id] = true
	_last_command_text = "DEBOARD %d/%d" % [_drop_sequence_unit_index, _drop_sequence_units.size()]
	_update_ui()


func _is_drop_sequence_active() -> bool:
	return _drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_LANDED or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING or _drop_sequence_phase == DROP_SEQUENCE_COMPLETE or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND


func _get_drop_approach_offset() -> Vector2:
	return Vector2(APPROACH_OFFSETS.get(_get_approach_angle_name(), Vector2(180.0, -112.0)))


func _get_drop_staging_position() -> Vector2:
	var offset: Vector2 = _get_drop_approach_offset()
	if offset.length_squared() <= 0.001:
		offset = Vector2(180.0, -112.0)
	var map_bounds: Rect2 = _get_map_world_bounds()
	var map_span: float = maxf(maxf(map_bounds.size.x, map_bounds.size.y) * DROP_OFFMAP_DISTANCE_MULTIPLIER, DROP_OFFMAP_MIN_DISTANCE)
	return _lz_position + offset.normalized() * map_span


func _get_primary_dropship_target_position(current_dropship_position: Vector2) -> Vector2:
	if _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND or _mission_drop_state == "to_fob":
		return _get_drop_exit_position()
	if _has_lz_position:
		return _lz_position
	return current_dropship_position


func _get_drop_exit_position() -> Vector2:
	return _get_drop_staging_position()


func _get_map_world_bounds() -> Rect2:
	var terrain_registry = get_node_or_null("../TerrainRegistry")
	var has_point: bool = false
	var min_pos: Vector2 = Vector2.ZERO
	var max_pos: Vector2 = Vector2.ZERO
	if terrain_registry != null and terrain_registry.has_method("get_all_tiles"):
		for tile_data in Array(terrain_registry.call("get_all_tiles")):
			if tile_data == null:
				continue
			var world_position: Vector2 = Vector2(tile_data.get("world_position"))
			if not has_point:
				min_pos = world_position
				max_pos = world_position
				has_point = true
				continue
			min_pos.x = minf(min_pos.x, world_position.x)
			min_pos.y = minf(min_pos.y, world_position.y)
			max_pos.x = maxf(max_pos.x, world_position.x)
			max_pos.y = maxf(max_pos.y, world_position.y)
	if has_point:
		return Rect2(min_pos, (max_pos - min_pos).abs())
	var map_root := get_node_or_null("../MapRoot") as Node2D
	if map_root != null:
		for child in map_root.get_children():
			var child_node := child as Node2D
			if child_node == null:
				continue
			var world_position: Vector2 = child_node.global_position
			if not has_point:
				min_pos = world_position
				max_pos = world_position
				has_point = true
				continue
			min_pos.x = minf(min_pos.x, world_position.x)
			min_pos.y = minf(min_pos.y, world_position.y)
			max_pos.x = maxf(max_pos.x, world_position.x)
			max_pos.y = maxf(max_pos.y, world_position.y)
	if has_point:
		return Rect2(min_pos, (max_pos - min_pos).abs())
	return Rect2(_lz_position - Vector2(256.0, 192.0), Vector2(512.0, 384.0))


func _get_dropship_marker_texture() -> Texture2D:
	match _drop_sequence_phase:
		DROP_SEQUENCE_OUTBOUND:
			return _get_dropship_texture_for_angle(_get_approach_angle_name())
		_:
			return _get_dropship_texture_for_angle(_get_opposite_approach_angle_name())


func _get_mission_dropship_texture() -> Texture2D:
	if _is_drop_sequence_active():
		return _get_dropship_marker_texture()
	match _mission_drop_state:
		"to_mission":
			return _get_dropship_texture_for_angle(_get_opposite_approach_angle_name())
		"to_fob":
			return _get_dropship_texture_for_angle(_get_approach_angle_name())
		"waiting":
			return _get_dropship_texture_for_angle("SE")
		_:
			var mission_drop_texture := _load_optional_texture(_mission_drop_texture_path)
			return mission_drop_texture if mission_drop_texture != null else _get_dropship_texture_for_angle("SE")


func _get_dropship_texture_for_angle(angle_name: String) -> Texture2D:
	match angle_name.strip_edges().to_upper():
		"NE":
			return DROPSHIP_TEXTURE_NE
		"SW":
			return DROPSHIP_TEXTURE_SW
		"SE":
			return DROPSHIP_TEXTURE_SE
		_:
			return DROPSHIP_TEXTURE_NW


func _get_opposite_approach_angle_name() -> String:
	match _get_approach_angle_name():
		"NE":
			return "SW"
		"SW":
			return "NE"
		"SE":
			return "NW"
		_:
			return "SE"


func _get_units_for_drop_operation() -> Array:
	var requested_fireteam_id: String = _get_drop_fireteam_id()
	var result: Array = []
	var fallback_units: Array = []
	for unit in _get_selected_friendly_units(true):
		var unit_fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if not requested_fireteam_id.is_empty() and unit_fireteam_id != requested_fireteam_id:
			continue
		fallback_units.append(unit)
		if _embarked_unit_ids.has(String(unit.call("get_unit_id")).strip_edges()):
			result.append(unit)
	if not result.is_empty():
		return result
	return fallback_units


func _get_drop_fireteam_id() -> String:
	var selected_fireteam_id: String = _get_selected_fireteam_id()
	if not selected_fireteam_id.is_empty():
		return selected_fireteam_id
	var mission_setup: Node = get_node_or_null("../MissionSetup")
	if mission_setup == null:
		return ""
	var meta_fireteam_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
	var unique_fireteam_ids: Dictionary = {}
	for fireteam_id_variant in meta_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			unique_fireteam_ids[fireteam_id] = true
	if unique_fireteam_ids.size() == 1:
		return String(unique_fireteam_ids.keys()[0])
	return ""


func _get_drop_fireteam_name() -> String:
	var fireteam_id: String = _get_drop_fireteam_id()
	if fireteam_id.is_empty():
		return ALL_FIRETEAM_LABEL
	return _get_fireteam_display_label(fireteam_id)


func _build_drop_unit_state_dict(unit_ids: Array) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		result[unit_id] = true
	return result


func _build_sorted_drop_unit_id_array(unit_state: Dictionary) -> Array:
	var unit_ids: Array = []
	for unit_id_variant in unit_state.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _apply_drop_presence_state_to_units() -> void:
	var mission_setup = get_node_or_null("../MissionSetup")
	var uses_deferred_activation: bool = mission_setup != null and bool(mission_setup.get("defer_friendly_runtime_activation"))
	if not uses_deferred_activation and _embarked_unit_ids.is_empty() and _deployed_unit_ids.is_empty():
		return
	var deployed_index: int = 0
	for unit in _get_all_friendly_units(true):
		if unit == null or not unit.has_method("get_unit_id") or not (unit is CanvasItem):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		var desired_visible: bool = true
		var should_apply_presence: bool = true
		if _embarked_unit_ids.has(unit_id):
			desired_visible = false
		elif _deployed_unit_ids.has(unit_id):
			desired_visible = true
		elif uses_deferred_activation:
			desired_visible = false
		else:
			should_apply_presence = false
		if not should_apply_presence:
			continue
		if preview_mode:
			(unit as CanvasItem).visible = desired_visible
		else:
			if _deployed_unit_ids.has(unit_id):
				if not _is_unit_runtime_registered(unit_id):
					_enqueue_dropship_deploy_effect(unit, unit_id, _lz_position + _get_unload_offset(deployed_index))
					_runtime_activation_pending_fireteam_ids[String(unit.call("get_fireteam_id")).strip_edges().to_lower()] = true
				elif unit is CanvasItem and not (unit as CanvasItem).visible:
					_enqueue_dropship_presence_effect(unit, unit_id, true)
				deployed_index += 1
			else:
				_enqueue_dropship_presence_effect(unit, unit_id, desired_visible)


func _is_unit_runtime_registered(unit_id: String) -> bool:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return false
	var unit_registry = get_node_or_null("../UnitRegistry")
	if unit_registry == null:
		return false
	if unit_registry.has_method("has_unit"):
		return bool(unit_registry.call("has_unit", normalized_unit_id))
	if unit_registry.has_method("get_unit"):
		return unit_registry.call("get_unit", normalized_unit_id) != null
	return false


func _get_unload_offset(index: int) -> Vector2:
	var base_offset: Vector2 = DROP_UNLOAD_OFFSETS[index] if index >= 0 and index < DROP_UNLOAD_OFFSETS.size() else Vector2(28.0 * float(index), 0.0)
	match _get_approach_angle_name():
		"NE":
			return Vector2(-base_offset.y, base_offset.x)
		"SW":
			return Vector2(base_offset.y, -base_offset.x)
		"SE":
			return Vector2(-base_offset.x, -base_offset.y)
		_:
			return base_offset


func _enqueue_dropship_embark_effect(unit: Node, unit_id: String, world_position: Vector2) -> void:
	_dropship_effect_adapter.call("enqueue_embark_effect", get_node_or_null("../SimulationRoot"), unit, unit_id, world_position)


func _enqueue_dropship_presence_effect(unit: Node, unit_id: String, is_visible: bool) -> void:
	_dropship_effect_adapter.call("enqueue_presence_effect", get_node_or_null("../SimulationRoot"), unit, unit_id, is_visible)


func _enqueue_dropship_deploy_effect(unit: Node, unit_id: String, world_position: Vector2) -> void:
	var team_id: String = ""
	if unit != null and unit.has_method("get_team_id"):
		team_id = String(unit.call("get_team_id")).strip_edges()
	if team_id.is_empty():
		var mission_setup = get_node_or_null("../MissionSetup")
		if mission_setup != null:
			team_id = String(mission_setup.get("team_id")).strip_edges()
	_dropship_effect_adapter.call("enqueue_deploy_effect", get_node_or_null("../SimulationRoot"), unit, unit_id, world_position, team_id)
	_enqueue_initial_loadout_effect_for_unit(unit_id)


func _flush_pending_drop_runtime_phase_starts() -> void:
	if preview_mode or _runtime_activation_pending_fireteam_ids.is_empty():
		return
	for fireteam_id_variant in _runtime_activation_pending_fireteam_ids.keys():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or not _is_fireteam_runtime_active(fireteam_id):
			continue
		_maybe_start_active_phase_for_fireteam(fireteam_id)
		_runtime_activation_pending_fireteam_ids.erase(fireteam_id_variant)
	_refresh_selected_fireteam_cards()
	_refresh_fireteam_mini_cards()


func _refresh_fireteam_runtime_ui_if_pending() -> void:
	if preview_mode or _fireteam_runtime_ui_refresh_frames_remaining <= 0:
		return
	_fireteam_runtime_ui_refresh_frames_remaining -= 1
	_refresh_selected_fireteam_cards()
	_refresh_fireteam_mini_cards()


func _enqueue_initial_loadout_effect_for_unit(unit_id: String) -> void:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return
	var mission_setup = get_node_or_null("../MissionSetup")
	if mission_setup == null or not mission_setup.has_method("get_unit_loadout_modifiers_dict"):
		return
	var modifiers_dict: Dictionary = Dictionary(mission_setup.call("get_unit_loadout_modifiers_dict", normalized_unit_id)).duplicate(true)
	if modifiers_dict.is_empty():
		return
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null or not simulation_root.has_method("enqueue_effect"):
		return
	simulation_root.call(
		"enqueue_effect",
		{
			"effect_type": "apply_loadout_modifiers",
			"unit_id": normalized_unit_id,
			"modifiers": modifiers_dict,
		}
	)


func _is_fireteam_runtime_active(fireteam_id: String) -> bool:
	if preview_mode:
		return false
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return false
	if not _use_visible_units_for_fireteam_ui():
		for active_unit in _get_fireteam_units(normalized_fireteam_id, false):
			if active_unit != null and active_unit.has_method("get_unit_id"):
				return true
		return false
	for unit in _get_fireteam_units(normalized_fireteam_id, true):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if _deployed_unit_ids.has(unit_id):
			return true
	return false


func _maybe_start_active_phase_for_fireteam(fireteam_id: String) -> void:
	if preview_mode or fireteam_id.strip_edges().is_empty():
		return
	if not PHASE_PLANNING_ENABLED:
		return
	if _phase_execution_by_fireteam.has(fireteam_id):
		return
	var phase_controller = _get_phase_controller()
	if phase_controller == null or not phase_controller.has_method("get_active_phase_index"):
		return
	var active_phase_index: int = int(phase_controller.call("get_active_phase_index"))
	if active_phase_index < 0:
		return
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, active_phase_index), null)
	if plan != null and not plan.waypoints.is_empty():
		for waypoint in plan.waypoints:
			if waypoint != null:
				waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		plan.active_waypoint_index = -1
		_activate_next_waypoint_for_plan(plan, fireteam_id, 0)
		return
	_apply_default_fireteam_behavior(fireteam_id, active_phase_index)
