class_name TacticalInputController
extends Node

const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const TACTICAL_CARD_SCRIPT: GDScript = preload("res://scripts/ui/components/tactical_card.gd")
const STATUS_BADGE_SCRIPT: GDScript = preload("res://scripts/ui/components/status_badge.gd")
const COMMAND_BUTTON_SCRIPT: GDScript = preload("res://scripts/ui/components/command_button.gd")
const PROGRESS_LINE_SCRIPT: GDScript = preload("res://scripts/ui/components/progress_line.gd")
const UI_BLOCK_LABELS_SCRIPT: GDScript = preload("res://scripts/meta/ui_block_labels.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const TRANSPORT_CRAFT_CARD_UI_SCRIPT: GDScript = preload("res://scripts/meta/transport_craft_card_ui.gd")
const FOB_FIRETEAM_CARD_SCRIPT: GDScript = preload("res://scripts/meta/fob_fireteam_card.gd")
const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const MISSION_PRIMARY_VIEW_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_primary_view_bridge.gd")
const MISSION_DROPSHIP_EFFECT_ADAPTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_dropship_effect_adapter.gd")
const AIR_ASSET_STATUS_SCRIPT: GDScript = preload("res://scripts/mission/air_asset_status.gd")
const AIR_ASSET_THREAT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/combat/air_asset_threat_resolver.gd")
const MISSION_COMMAND_INPUT_GUARD_SCRIPT: GDScript = preload("res://scripts/mission/mission_command_input_guard.gd")
const FIRETEAM_SELECTION_ADAPTER_SCRIPT: GDScript = preload("res://scripts/tactical/ui/fireteam_selection_adapter.gd")
const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const FIRETEAM_ORDER_PLAN_SCRIPT: GDScript = preload("res://scripts/command/fireteam_order_plan.gd")
const FIRETEAM_WAYPOINT_SCRIPT: GDScript = preload("res://scripts/command/fireteam_waypoint.gd")
const AREA_ORDER_SCRIPT: GDScript = preload("res://scripts/command/area_order.gd")
const FIRETEAM_BEHAVIOR_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_behavior_resolver.gd")
const MULTI_FIRETEAM_PLAN_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/multi_fireteam_plan_resolver.gd")
const FIRETEAM_ORDER_VISUALIZER_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/fireteam_order_visualizer.gd")
const AD_HOC_ORDER_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/ad_hoc_order_controller.gd")
const AD_HOC_ORDER_SCRIPT: GDScript = preload("res://scripts/command/ad_hoc_order.gd")
const WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/waypoint_intent_preview_resolver.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const AREA_ORDER_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/area_order_resolver.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const FIRETEAM_COORDINATION_MANAGER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_coordination_manager.gd")
const TACTICAL_STANCE_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_stance_controller.gd")
const FIRETEAM_MOVEMENT_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const FIRETEAM_SECURITY_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_security_controller.gd")
const CONTACT_MAP_OVERLAY_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/contact_map_overlay.gd")
const FIRETEAMLEADER_FEEDBACK_BUBBLE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const TACTICAL_COMMUNICATION_EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const TACTICAL_COMMUNICATION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")
const TACTICAL_EVENT_LOG_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_event_log.gd")
const FTL_READINESS_SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/tactical/ftl_readiness_snapshot_contract.gd")
const TACTICAL_BREAKOUT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_breakout_resolver.gd")
const MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/mission_command_hierarchy_contract.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const COMIC_BUBBLE_RUNTIME_GATE_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_runtime_gate.gd")
const NPC_THOUGHT_BUBBLE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/npc_thought_bubble_resolver.gd")
const HOVER_SCROLL_BEHAVIOR_SCRIPT: GDScript = preload("res://scripts/ui/hover_scroll_behavior.gd")
const FTL_READINESS_GAUGE_SCRIPT: GDScript = preload("res://scripts/ui/ftl_readiness_gauge.gd")
const FIRETEAM_MEMBER_STATUS_ROW_SCRIPT: GDScript = preload("res://scripts/ui/fireteam_member_status_row.gd")
const DROPSHIP_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NE.png")
const DROPSHIP_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_NW.png")
const DROPSHIP_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png")
const DROPSHIP_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SW.png")

const ALL_FIRETEAM_LABEL: String = "ALL"
const APPROACH_ANGLES: PackedStringArray = ["NW", "NE", "SW", "SE"]
const HOTKEY_LEGEND: String = "LMB Select/Center | Doubleclick Center | RMB Order | RMB Drag Area | Shift+RMB Append | CTRL+LMB Add | C Fire Arc | L LOS | DEL Order | T Sort | G GO"
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
const TACTICAL_EVENT_LOG_PANEL_PATH: String = "../TacticalUI/TacticalEventLogPanel"
const COMMAND_GRID_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const DELETE_ORDER_BUTTON_PATH: String = COMMAND_GRID_PATH + "/DeleteOrderButton"
const SORT_COMMAND_BUTTON_PATH: String = COMMAND_GRID_PATH + "/SortCommandMatrixButton"
const CARD_REFRESH_INTERVAL_SECONDS: float = 0.35
const FIRETEAM_SECURITY_REFRESH_INTERVAL_SECONDS: float = 0.20
const AREA_ORDER_PREVIEW_REFRESH_MSEC: int = 80
const AREA_ORDER_PREVIEW_SIGNATURE_STEP: float = 8.0
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
const DROP_OFFMAP_DISTANCE_MULTIPLIER: float = 1.8
const DROP_OFFMAP_MIN_DISTANCE: float = 720.0
const DROP_SHIP_SPEED: float = 1200.0
const DROP_LANDING_HOLD_SECONDS: float = 0.75
const DROP_UNLOAD_INTERVAL_SECONDS: float = 0.45
const DROP_SHIP_RECALL_COOLDOWN_SECONDS: float = 2.5
const DROP_SEQUENCE_INBOUND: String = "inbound"
const DROP_SEQUENCE_LANDED: String = "landed"
const DROP_SEQUENCE_UNLOADING: String = "unloading"
const DROP_SEQUENCE_COMPLETE: String = "complete"
const DROP_SEQUENCE_OUTBOUND: String = "outbound"
const MISSION_DROPSHIP_PANEL_SIZE: Vector2 = Vector2(312.0, 152.0)
const MISSION_DROPSHIP_PANEL_MARGIN_RIGHT: float = 16.0
const MISSION_DROPSHIP_PANEL_MARGIN_TOP: float = 100.0
const MISSION_DROPSHIP_PANEL_GAP_BELOW_IDENTITY: float = 10.0
const MISSION_DROPSHIP_PANEL_STACK_GAP: float = 8.0
const MISSION_DROPSHIP_HOLD_SPACING: float = 92.0
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
const TILE_TARGET_COMMAND_TYPES: PackedStringArray = ["move", "defend", "flank", "take"]
const POST_DROP_SECURITY_ORIGIN: String = "post_drop_360_security"
const POST_DROP_SECURITY_MODE: String = "360"
const POST_DROP_SECURITY_RADIUS_TILES: int = 4
const POST_DROP_SECURITY_TILE_WORLD_STEP: float = 64.0
const POST_DROP_SECURITY_MOVE_SPEED_FACTOR: float = 0.68
const POST_DROP_COVER_SEARCH_RADIUS_FACTOR: float = 1.65
const POST_DROP_COVER_MIN_SCORE: float = 32.0

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
@export var fireteamleader_feedback_bubbles_enabled: bool = true
@export var character_overlay_dev_editor_enabled: bool = false

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
var _focused_fireteam_id: String = ""
var _fire_sector_overlay_enabled: bool = false
var _los_debug_overlay_enabled: bool = false
var _contact_density_heatmap_enabled: bool = false
var _fireteamleader_feedback_bubbles: Array = []
var _fireteamleader_feedback_sequence: int = 0
var _tactical_communication_resolver = null
var _tactical_communication_events: Array = []
var _tactical_event_log = null
var _tactical_breakout_resolver = null
var _tactical_breakout_records: Array = []
var _npc_thought_bubbles: Array = []
var _npc_thought_peek_active_last_frame: bool = false
var _npc_thought_bubble_refresh_msec: int = 0
var _last_command_text: String = "AWAITING INPUT"
var _last_target_position: Vector2 = Vector2.ZERO
var _lz_position: Vector2 = Vector2.ZERO
var _has_lz_position: bool = false
var _has_selected_tile: bool = false
var _selected_tile_grid_position: Vector2i = Vector2i.ZERO
var _selected_tile_world_position: Vector2 = Vector2.ZERO
var _is_lz_placement_armed: bool = false
var _lz_placement_craft_id: String = ""
var _is_target_placement_armed: bool = false
var _drop_ship_requested: bool = false
var _drop_ship_staged: bool = false
var _mission_drop_source: String = ""
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
var _mission_drop_cards: Array = []
var _air_asset_status = null
var _air_asset_threat_resolver = null
var _air_asset_threat_events: Array = []
var _air_asset_lz_secure_level: float = 0.0
var _meta_transfer_routes: Array = []
var _drop_ship_cooldown_remaining: float = 0.0
var _card_refresh_time_remaining: float = 0.0
var _fireteam_security_refresh_time_remaining: float = 0.0
var _drop_sequence_phase: String = ""
var _drop_sequence_units: Array = []
var _drop_sequence_unit_index: int = 0
var _drop_sequence_timer: float = 0.0
var _drop_sequence_position: Vector2 = Vector2.ZERO
var _drop_sequence_fireteam_name: String = "ALL"
var _drop_sequence_visual_only: bool = false
var _drop_sequence_craft_id: String = ""
var _drop_sequence_display_name: String = ""
var _drop_sequence_lz_position: Vector2 = Vector2.ZERO
var _drop_sequence_approach_angle: String = "NW"
var _drop_sequence_embarked_unit_ids: Dictionary = {}
var _parallel_drop_sequences_by_craft: Dictionary = {}
var _embarked_unit_ids: Dictionary = {}
var _deployed_unit_ids: Dictionary = {}
var _deployed_unit_positions: Dictionary = {}
var _runtime_activation_pending_fireteam_ids: Dictionary = {}
var _post_drop_security_pending_fireteam_ids: Dictionary = {}
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
var _multi_fireteam_plans_by_id: Dictionary = {}
var _waypoint_sequence: int = 0
var _area_order_sequence: int = 0
var _multi_fireteam_plan_sequence: int = 0
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
var _right_order_press_active: bool = false
var _right_order_drag_active: bool = false
var _right_order_press_screen_position: Vector2 = Vector2.ZERO
var _right_order_drag_screen_position: Vector2 = Vector2.ZERO
var _right_order_append_mode: bool = false
var _area_order_preview_signature: String = ""
var _area_order_preview_last_update_msec: int = 0
var _waypoint_menu_append_mode: bool = false
var _area_order_menu_append_mode: bool = false
var _order_visualizer_pending: bool = false
var _phase_execution_by_fireteam: Dictionary = {}
var _active_behavior_profiles_by_fireteam: Dictionary = {}
var _ad_hoc_order_controller = null
var _area_order_resolver = null
var _multi_fireteam_plan_resolver = null
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
var _waypoint_intent_preview_resolver = WAYPOINT_INTENT_PREVIEW_RESOLVER_SCRIPT.new()
var _comic_bubble_runtime_gate = null
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
	HOVER_SCROLL_BEHAVIOR_SCRIPT.call("install", get_parent() if get_parent() != null else self)
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
	_get_comic_bubble_runtime_gate()
	_ensure_order_visualizer()
	_ensure_contact_map_overlay()
	_ensure_mission_nav_timer_label()
	_ensure_mission_dropship_panel()
	_ensure_air_asset_status()
	_apply_drop_light_fixed_hud_layout()
	_apply_contextual_help_ids()
	_apply_command_hierarchy_metadata()
	_sync_phase_selection_from_controller()
	_initialize_fireteam_suppression_state()
	if not _use_visible_units_for_fireteam_ui():
		_ensure_default_fireteam_selection()
	_ensure_default_tile_selection(false)
	_sync_initial_runtime_active_units()
	_apply_drop_presence_state_to_units()
	_refresh_selection_visuals()
	_refresh_order_visuals()
	_refresh_button_state()
	_refresh_world_overlays()
	_update_ui()
	_refresh_ad_hoc_panel_visibility()
	_emit_planning_state_changed()
	call_deferred("_ensure_default_tile_selection")
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
	_update_npc_thought_peek_visuals()
	if _prune_fireteamleader_feedback_bubbles():
		_refresh_order_visuals()
	_flush_pending_drop_runtime_phase_starts()
	_refresh_fireteam_runtime_ui_if_pending()
	_fireteam_security_refresh_time_remaining -= delta
	if _fireteam_security_refresh_time_remaining <= 0.0:
		_fireteam_security_refresh_time_remaining = FIRETEAM_SECURITY_REFRESH_INTERVAL_SECONDS
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
			if _begin_right_order_context_interaction(mouse_button_event.position, mouse_button_event.shift_pressed):
				get_viewport().set_input_as_handled()
			return

		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT and not mouse_button_event.pressed:
			if _finish_right_order_context_interaction(mouse_button_event.position, mouse_button_event.shift_pressed):
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

			if mouse_button_event.double_click:
				if _try_center_fireteam_from_map_click(mouse_button_event.position, mouse_button_event.ctrl_pressed):
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

			if _try_focus_area_order_at_position(mouse_button_event.position):
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
		if _update_right_order_context_drag((event as InputEventMouseMotion).position):
			get_viewport().set_input_as_handled()
			return
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
			if _delete_selected_order():
				get_viewport().set_input_as_handled()
		KEY_C:
			_toggle_fire_sector_overlay()
			get_viewport().set_input_as_handled()
		KEY_L:
			_toggle_los_debug_overlay()
			get_viewport().set_input_as_handled()
		KEY_T:
			_on_sort_fireteam_pressed()
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


func is_fire_sector_overlay_enabled() -> bool:
	return _fire_sector_overlay_enabled


func set_fire_sector_overlay_enabled(enabled: bool) -> void:
	if _fire_sector_overlay_enabled == enabled:
		return
	_fire_sector_overlay_enabled = enabled
	_last_command_text = "FIRE ARC ON" if _fire_sector_overlay_enabled else "FIRE ARC OFF"
	_refresh_order_visuals()
	_update_ui()


func _toggle_fire_sector_overlay() -> void:
	set_fire_sector_overlay_enabled(not _fire_sector_overlay_enabled)


func is_los_debug_overlay_enabled() -> bool:
	return _los_debug_overlay_enabled


func set_los_debug_overlay_enabled(enabled: bool) -> void:
	if _los_debug_overlay_enabled == enabled:
		return
	_los_debug_overlay_enabled = enabled
	_last_command_text = "LOS DEBUG ON" if _los_debug_overlay_enabled else "LOS DEBUG OFF"
	_refresh_order_visuals()
	_update_ui()


func _toggle_los_debug_overlay() -> void:
	set_los_debug_overlay_enabled(not _los_debug_overlay_enabled)


func is_contact_density_heatmap_enabled() -> bool:
	return _contact_density_heatmap_enabled


func set_contact_density_heatmap_enabled(enabled: bool) -> void:
	if _contact_density_heatmap_enabled == enabled:
		return
	_contact_density_heatmap_enabled = enabled
	_last_command_text = "CONTACT HEAT ON" if _contact_density_heatmap_enabled else "CONTACT HEAT OFF"
	_refresh_order_visuals()
	_update_ui()


func _toggle_contact_density_heatmap() -> void:
	set_contact_density_heatmap_enabled(not _contact_density_heatmap_enabled)


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
	var selected_tile_state_provided: bool = planning_state.has("has_selected_tile") or planning_state.has("selected_tile") or planning_state.has("selected_tile_world_position")
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
	if planning_state.has("mission_drop_source"):
		_mission_drop_source = String(planning_state.get("mission_drop_source", "")).strip_edges().to_lower()
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
	if planning_state.has("mission_drop_cards"):
		_mission_drop_cards = _sanitize_mission_dropship_cards(Array(planning_state.get("mission_drop_cards", [])))
		if not _mission_drop_craft_id.is_empty():
			var selected_drop_card: Dictionary = _find_raw_mission_dropship_card_entry(_mission_drop_craft_id)
			if not selected_drop_card.is_empty():
				selected_drop_card = selected_drop_card.duplicate(true)
				var planning_has_lz_position: bool = bool(planning_state.get("has_lz_position", false))
				var has_multiple_drop_cards: bool = _mission_drop_cards.size() > 1
				var should_seed_lz_from_scalar: bool = not has_multiple_drop_cards or planning_has_lz_position
				if planning_state.has("has_lz_position") and should_seed_lz_from_scalar:
					selected_drop_card["has_lz_position"] = bool(planning_state.get("has_lz_position", false))
				if planning_state.has("lz_position") and should_seed_lz_from_scalar:
					selected_drop_card["lz_position"] = planning_state["lz_position"]
				if planning_state.has("approach_angle") and (planning_has_lz_position or not selected_drop_card.has("approach_angle")):
					selected_drop_card["approach_angle"] = planning_state["approach_angle"]
				if not selected_drop_card.has("drop_ship_requested") and planning_state.has("drop_ship_requested"):
					selected_drop_card["drop_ship_requested"] = bool(planning_state.get("drop_ship_requested", false))
				if not selected_drop_card.has("drop_ship_staged") and planning_state.has("drop_ship_staged"):
					selected_drop_card["drop_ship_staged"] = bool(planning_state.get("drop_ship_staged", false))
				_apply_mission_dropship_card_selection(selected_drop_card)
	if planning_state.has("air_asset_status"):
		_air_asset_status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", Dictionary(planning_state.get("air_asset_status", {})))
	if planning_state.has("meta_transfer_routes"):
		_meta_transfer_routes = _sanitize_meta_transfer_routes(Array(planning_state.get("meta_transfer_routes", [])))
	if planning_state.has("embarked_unit_ids"):
		_embarked_unit_ids = _build_drop_unit_state_dict(Array(planning_state.get("embarked_unit_ids", [])))
	if planning_state.has("deployed_unit_ids"):
		_deployed_unit_ids = _build_drop_unit_state_dict(Array(planning_state.get("deployed_unit_ids", [])))
	if planning_state.has("deployed_unit_positions"):
		_deployed_unit_positions = _sanitize_deployed_unit_positions(Dictionary(planning_state.get("deployed_unit_positions", {})))
	_prune_deployed_unit_positions()
	_sync_selected_mission_dropship_payload_presence_from_card()
	if planning_state.has("selected_fireteam"):
		_select_fireteam_by_name(String(planning_state.get("selected_fireteam", _get_fireteam_name())), false)
	if planning_state.has("selected_fireteams"):
		_set_selected_fireteams(_sanitize_fireteam_ids(PackedStringArray(Array(planning_state.get("selected_fireteams", [])))), false)
	if selected_tile_state_provided:
		var tile_state: Dictionary = Dictionary(planning_state.get("selected_tile", {}))
		var has_tile: bool = bool(planning_state.get("has_selected_tile", tile_state.get("has_selected_tile", false)))
		if has_tile:
			var grid_variant = planning_state.get("selected_tile_grid_position", tile_state.get("grid_position", Vector2i.ZERO))
			var world_variant = planning_state.get("selected_tile_world_position", tile_state.get("world_position", Vector2.ZERO))
			var tile_context: Dictionary = {}
			if typeof(grid_variant) == TYPE_VECTOR2I and typeof(world_variant) == TYPE_VECTOR2:
				tile_context = {
					"grid_position": Vector2i(grid_variant),
					"world_position": Vector2(world_variant),
				}
			elif typeof(world_variant) == TYPE_VECTOR2:
				tile_context = _build_tile_context_from_world_position(Vector2(world_variant))
			if not tile_context.is_empty():
				_set_selected_tile_context(tile_context, "", false, false)
			else:
				_clear_selected_tile_selection(false, false)
		else:
			_clear_selected_tile_selection(false, false)
	if planning_state.has("tactical_stance_sync") and _tactical_stance_controller != null:
		_tactical_stance_controller.call("load_sync_state", Dictionary(planning_state.get("tactical_stance_sync", {})), _get_available_fireteam_ids())
	elif planning_state.has("tactical_stances") and _tactical_stance_controller != null:
		_tactical_stance_controller.call("load_stance_snapshot", Dictionary(planning_state.get("tactical_stances", {})), _get_available_fireteam_ids())
	if planning_state.has("order_plans"):
		_load_order_plans_from_state(Array(planning_state.get("order_plans", [])))
	if planning_state.has("area_orders"):
		_load_area_orders_from_state(Array(planning_state.get("area_orders", [])))
	if planning_state.has("multi_fireteam_plans"):
		_load_multi_fireteam_plans_from_state(Array(planning_state.get("multi_fireteam_plans", [])))
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
	if not selected_tile_state_provided:
		_ensure_default_tile_selection(false)
	else:
		_refresh_tile_selection_visuals()
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
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		_mission_drop_progress = _build_active_drop_sequence_progress_value()
	_store_selected_mission_dropship_plan()
	_store_active_drop_sequence_card()
	var planning_state: Dictionary = {
		"has_lz_position": _has_lz_position,
		"lz_position": _lz_position,
		"approach_angle": _get_approach_angle_name(),
		"drop_ship_requested": _drop_ship_requested,
		"drop_ship_staged": _drop_ship_staged,
		"mission_drop_source": _mission_drop_source,
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
		"mission_drop_cards": _build_mission_drop_cards_snapshot(),
		"air_asset_status": get_air_asset_status_snapshot(),
		"meta_transfer_routes": _serialize_meta_transfer_routes(),
		"embarked_unit_ids": _build_sorted_drop_unit_id_array(_embarked_unit_ids),
		"deployed_unit_ids": _build_sorted_drop_unit_id_array(_deployed_unit_ids),
		"deployed_unit_positions": _serialize_deployed_unit_positions(),
		"selected_fireteam": _get_fireteam_name(),
		"selected_fireteams": Array(_selected_fireteam_ids),
		"has_selected_tile": _has_selected_tile,
		"selected_tile": _build_selected_tile_snapshot(),
		"selected_tile_grid_position": _selected_tile_grid_position,
		"selected_tile_world_position": _selected_tile_world_position,
		"selected_phase": _get_phase_name(),
		"order_plans": _serialize_order_plans(),
		"area_orders": _serialize_area_orders(),
		"multi_fireteam_plans": _serialize_multi_fireteam_plans(),
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
		_record_fireteamleader_feedback_for_selected_fireteams("go", "blocked", "observer")
		_refresh_order_visuals()
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
		_record_fireteamleader_feedback_for_selected_fireteams("go", "blocked", "inactive")
		_refresh_order_visuals()
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
		_record_fireteamleader_feedback_for_selected_fireteams("go", "blocked", "no_orders")
		_refresh_order_visuals()
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
	_record_fireteamleader_feedback_for_fireteam_ids(issued_fireteams, "go", "accepted", "issued")
	_record_fireteamleader_feedback_for_fireteam_ids(continued_fireteams, "go", "running", "continued")
	_record_fireteamleader_feedback_for_fireteam_ids(already_active_fireteams, "go", "running", "already_active")
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
	return _enrich_contact_entries_with_recon(Array(combat_driver.call("get_contact_snapshot")).duplicate(true), "")


func get_fireteam_contact_snapshot(fireteam_id: String) -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_fireteam_contact_snapshot"):
		return []
	return _enrich_contact_entries_with_recon(Array(combat_driver.call("get_fireteam_contact_snapshot", fireteam_id)).duplicate(true), fireteam_id)


func get_flank_vulnerability_snapshot() -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_flank_vulnerability_snapshot"):
		return []
	return Array(combat_driver.call("get_flank_vulnerability_snapshot")).duplicate(true)


func get_enemy_security_snapshot() -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_enemy_security_snapshot"):
		return []
	return Array(combat_driver.call("get_enemy_security_snapshot")).duplicate(true)


func get_enemy_team_tactics_snapshot() -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_enemy_team_tactics_snapshot"):
		return []
	return Array(combat_driver.call("get_enemy_team_tactics_snapshot")).duplicate(true)


func _enrich_contact_entries_with_recon(contact_entries: Array, fallback_fireteam_id: String = "") -> Array:
	var tactics_by_unit_id: Dictionary = _build_enemy_tactics_by_unit_id()
	var result: Array = []
	for contact_variant in contact_entries:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant).duplicate(true)
		var fireteam_id: String = String(contact.get("fireteam_id", fallback_fireteam_id)).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = fallback_fireteam_id.strip_edges().to_lower()
		var detection_state: String = String(contact.get("detection_state", "")).strip_edges().to_lower()
		var unit_id: String = String(contact.get("unit_id", contact.get("target_id", ""))).strip_edges()
		var report_quality: float = _get_contact_report_quality_for_fireteam(fireteam_id)
		if detection_state == "confirmed" and report_quality >= 0.66 and tactics_by_unit_id.has(unit_id):
			var tactics_state: Dictionary = Dictionary(tactics_by_unit_id.get(unit_id, {}))
			var profile_id: String = String(tactics_state.get("profile_id", "")).strip_edges().to_lower()
			contact["enemy_profile_revealed"] = true
			contact["enemy_profile_id"] = profile_id
			contact["enemy_profile_label"] = _get_enemy_profile_player_label(profile_id, String(tactics_state.get("tactic_label", "")))
			contact["contact_report_quality"] = report_quality
		result.append(contact)
	return result


func _build_enemy_tactics_by_unit_id() -> Dictionary:
	var result: Dictionary = {}
	for state_variant in get_enemy_team_tactics_snapshot():
		if typeof(state_variant) != TYPE_DICTIONARY:
			continue
		var state: Dictionary = Dictionary(state_variant)
		for unit_id_variant in PackedStringArray(state.get("unit_ids", PackedStringArray())):
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty():
				continue
			result[unit_id] = state.duplicate(true)
	return result


func _get_contact_report_quality_for_fireteam(fireteam_id: String) -> float:
	var profile_dict: Dictionary = get_active_behavior_profile(fireteam_id)
	var public_snapshot: Dictionary = Dictionary(Dictionary(profile_dict.get("metadata", {})).get("ftl_public_snapshot", {}))
	if public_snapshot.has("contact_report_quality"):
		return clampf(float(public_snapshot.get("contact_report_quality", 0.5)), 0.0, 1.0)
	return clampf(float(profile_dict.get("contact_report_quality", 0.5)), 0.0, 1.0)


func _get_enemy_profile_player_label(profile_id: String, fallback_label: String = "") -> String:
	match profile_id.strip_edges().to_lower():
		"guard_hold":
			return "Wache"
		"patrol_probe":
			return "Patrouille"
		"aggressive_push":
			return "Sturmtrupp"
		"defensive_cover":
			return "Deckungssucher"
		"sniper_watch":
			return "Scharfschuetze"
		_:
			var clean_fallback: String = fallback_label.strip_edges()
			return clean_fallback if not clean_fallback.is_empty() else "Feindprofil"


func get_fire_event_snapshot() -> Array:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_fire_event_snapshot"):
		return []
	return Array(combat_driver.call("get_fire_event_snapshot")).duplicate(true)


func get_overwatch_member_ready_snapshot() -> Dictionary:
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("get_overwatch_member_ready_snapshot"):
		return {}
	return Dictionary(combat_driver.call("get_overwatch_member_ready_snapshot")).duplicate(true)


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
	return set_fireteams_tactical_stance(_selected_fireteam_ids, next_stance)


func set_fireteams_tactical_stance(fireteam_ids: PackedStringArray, next_stance: String) -> bool:
	_ensure_tactical_stance_controller()
	if _tactical_stance_controller == null or fireteam_ids.is_empty():
		return false
	var normalized_fireteam_ids: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or normalized_fireteam_ids.has(fireteam_id):
			continue
		normalized_fireteam_ids.append(fireteam_id)
	if normalized_fireteam_ids.is_empty():
		return false
	var applied_count: int = int(_tactical_stance_controller.call("apply_to_fireteams", normalized_fireteam_ids, next_stance))
	if applied_count <= 0:
		return false
	for fireteam_id_variant in normalized_fireteam_ids:
		_refresh_active_behavior_profile_for_fireteam(String(fireteam_id_variant))
	var first_stance: String = String(_tactical_stance_controller.call("get_requested_stance", String(normalized_fireteam_ids[0])))
	_last_command_text = "STANCE %s (%d)" % [_get_tactical_stance_short_label(first_stance), applied_count]
	_refresh_button_state()
	_refresh_order_visuals()
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


func get_fireteam_orientation_snapshot() -> Array:
	var entries: Array = []
	for anchor_variant in _build_fireteam_anchor_visualization_entries():
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor_entry: Dictionary = Dictionary(anchor_variant).duplicate(true)
		if typeof(anchor_entry.get("heading_direction", null)) != TYPE_VECTOR2:
			continue
		var heading_direction: Vector2 = Vector2(anchor_entry.get("heading_direction", Vector2.ZERO))
		if heading_direction.length_squared() <= 0.0001:
			continue
		entries.append(anchor_entry)
	return entries


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
	_sync_unit_overwatch_badges()
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


func get_selected_tile_snapshot() -> Dictionary:
	return _build_selected_tile_snapshot()


func select_tile_from_world_position_for_test(world_position: Vector2) -> Dictionary:
	var tile_context: Dictionary = _build_tile_context_from_world_position(world_position)
	if tile_context.is_empty():
		return {"has_selected_tile": false, "selected": false}
	_set_selected_tile_context(tile_context, "TILE SELECTED %s" % _format_grid_position(Vector2i(tile_context.get("grid_position", Vector2i.ZERO))), false)
	return _build_selected_tile_snapshot()


func clear_selected_tile_for_test() -> Dictionary:
	_clear_selected_tile_selection(false, true)
	return _build_selected_tile_snapshot()


func _has_primary_grid_for_command_selection() -> bool:
	var primary_view = _get_primary_3d_view()
	return primary_view != null and primary_view.has_method("world_to_grid_position") and primary_view.has_method("set_selected_grid_positions")


func _requires_selected_tile_for_command(command_type: String) -> bool:
	return TILE_TARGET_COMMAND_TYPES.has(command_type.strip_edges().to_lower())


func _build_tile_context_from_screen_position(screen_position: Vector2) -> Dictionary:
	if _has_primary_grid_for_command_selection():
		var grid_variant = _primary_view_bridge.call("screen_to_grid_position", get_parent(), screen_position)
		if typeof(grid_variant) != TYPE_VECTOR2I:
			return {}
		return _build_tile_context_from_grid_position(Vector2i(grid_variant))
	var world_position: Vector2 = _clamp_world_position_to_viewport(_screen_to_world_position(screen_position))
	return {
		"grid_position": Vector2i.ZERO,
		"world_position": world_position,
	}


func _build_tile_context_from_world_position(world_position: Vector2) -> Dictionary:
	var clamped_position: Vector2 = _clamp_world_position_to_viewport(world_position)
	if _has_primary_grid_for_command_selection():
		var snapped_position: Vector2 = _snap_world_position_to_primary_tile(clamped_position)
		var grid_variant = _primary_view_bridge.call("world_to_grid_position", get_parent(), snapped_position)
		if typeof(grid_variant) != TYPE_VECTOR2I:
			grid_variant = _primary_view_bridge.call("world_to_grid_position", get_parent(), clamped_position)
		if typeof(grid_variant) != TYPE_VECTOR2I:
			return {}
		return _build_tile_context_from_grid_position(Vector2i(grid_variant))
	return {
		"grid_position": Vector2i.ZERO,
		"world_position": clamped_position,
	}


func _build_tile_context_from_grid_position(grid_position: Vector2i) -> Dictionary:
	if _has_primary_grid_for_command_selection():
		var world_variant = _primary_view_bridge.call("grid_to_world_position", get_parent(), grid_position)
		if typeof(world_variant) != TYPE_VECTOR2:
			return {}
		return {
			"grid_position": grid_position,
			"world_position": Vector2(world_variant),
		}
	return {
		"grid_position": grid_position,
		"world_position": _selected_tile_world_position,
	}


func _select_tile_from_screen_position(screen_position: Vector2, command_text: String = "TILE SELECTED") -> bool:
	var tile_context: Dictionary = _build_tile_context_from_screen_position(screen_position)
	if tile_context.is_empty():
		_last_command_text = "NO TILE UNDER CURSOR"
		_refresh_button_state()
		_update_ui()
		return false
	var grid_position := Vector2i(tile_context.get("grid_position", Vector2i.ZERO))
	return _set_selected_tile_context(tile_context, "%s %s" % [command_text, _format_grid_position(grid_position)])


func _ensure_default_tile_selection(should_update_ui: bool = true) -> bool:
	if _has_selected_tile:
		_refresh_tile_selection_visuals()
		return true
	var objective_marker := get_node_or_null(objective_point_path) as Node2D
	var tile_context: Dictionary = {}
	if objective_marker != null:
		tile_context = _build_tile_context_from_world_position(objective_marker.global_position)
	if tile_context.is_empty():
		tile_context = _build_tile_context_from_world_position(_get_target_position())
	if tile_context.is_empty():
		return false
	return _set_selected_tile_context(tile_context, "", false, should_update_ui)


func _set_selected_tile_context(tile_context: Dictionary, command_text: String = "", should_emit_signal: bool = true, should_update_ui: bool = true) -> bool:
	var grid_variant = tile_context.get("grid_position", null)
	var world_variant = tile_context.get("world_position", null)
	if typeof(grid_variant) != TYPE_VECTOR2I or typeof(world_variant) != TYPE_VECTOR2:
		return false
	_has_selected_tile = true
	_selected_tile_grid_position = Vector2i(grid_variant)
	_selected_tile_world_position = Vector2(world_variant)
	_refresh_tile_selection_visuals()
	if not command_text.strip_edges().is_empty():
		_last_command_text = command_text
	_refresh_button_state()
	if should_update_ui:
		_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()
	return true


func _clear_selected_tile_selection(should_emit_signal: bool = true, should_update_ui: bool = true) -> void:
	_has_selected_tile = false
	_selected_tile_grid_position = Vector2i.ZERO
	_selected_tile_world_position = Vector2.ZERO
	_refresh_tile_selection_visuals()
	_refresh_button_state()
	if should_update_ui:
		_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()


func _refresh_tile_selection_visuals() -> void:
	var selected_grids: Array = []
	if _has_selected_tile:
		selected_grids.append(_selected_tile_grid_position)
	_primary_view_bridge.call("set_selected_grid_positions", get_parent(), selected_grids)


func _build_selected_tile_snapshot() -> Dictionary:
	return {
		"has_selected_tile": _has_selected_tile,
		"grid_position": _selected_tile_grid_position,
		"grid_x": _selected_tile_grid_position.x,
		"grid_y": _selected_tile_grid_position.y,
		"world_position": _selected_tile_world_position,
		"world_text": _format_world_position(_selected_tile_world_position) if _has_selected_tile else "",
		"grid_text": _format_grid_position(_selected_tile_grid_position) if _has_selected_tile else "",
	}


func _format_grid_position(grid_position: Vector2i) -> String:
	return "G%d,%d" % [grid_position.x, grid_position.y]


func _apply_selected_tile_to_target_marker() -> bool:
	if not _has_selected_tile:
		return false
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return false
	target_marker.global_position = _selected_tile_world_position
	_last_target_position = _selected_tile_world_position
	return true


func try_place_target_from_screen_position(screen_position: Vector2) -> bool:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return false

	var tile_context: Dictionary = _build_tile_context_from_screen_position(screen_position)
	if _has_primary_grid_for_command_selection() and tile_context.is_empty():
		_last_command_text = "NO TILE UNDER CURSOR"
		_update_ui()
		return false
	var clamped_position: Vector2 = Vector2(tile_context.get("world_position", _clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))) if not tile_context.is_empty() else _clamp_world_position_to_viewport(_screen_to_world_position(screen_position))
	if not tile_context.is_empty():
		_set_selected_tile_context(tile_context, "", false, false)
	target_marker.global_position = clamped_position
	_last_target_position = clamped_position
	_last_command_text = "TARGET SET @ %s" % _format_world_position(clamped_position)
	_refresh_button_state()
	_update_ui()
	return true


func _place_lz_from_screen_position(screen_position: Vector2) -> bool:
	var armed_craft_id: String = _lz_placement_craft_id.strip_edges()
	if not armed_craft_id.is_empty() and armed_craft_id != _mission_drop_craft_id.strip_edges():
		_select_mission_dropship_craft(armed_craft_id, false)
	var tile_context: Dictionary = _build_tile_context_from_screen_position(screen_position)
	if _has_primary_grid_for_command_selection() and tile_context.is_empty():
		_last_command_text = "NO TILE UNDER CURSOR"
		_update_ui()
		return false
	_lz_position = Vector2(tile_context.get("world_position", _snap_world_position_to_primary_tile(_clamp_world_position_to_viewport(_screen_to_world_position(screen_position))))) if not tile_context.is_empty() else _snap_world_position_to_primary_tile(_clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))
	if not tile_context.is_empty():
		_set_selected_tile_context(tile_context, "", false, false)
	_has_lz_position = true
	_is_lz_placement_armed = false
	_lz_placement_craft_id = ""
	var lz_label: String = _build_mission_dropship_lz_name(_mission_drop_craft_id, _mission_drop_display_name)
	_last_command_text = "%s SET %s @ %s" % [lz_label, _get_approach_angle_name(), _format_world_position(_lz_position)]
	_store_selected_mission_dropship_plan()
	_refresh_button_state()
	_refresh_world_overlays()
	_update_ui()
	_emit_planning_state_changed()
	return true


func _issue_command(command_type: String, display_text: String) -> bool:
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_record_fireteamleader_feedback_for_selected_fireteams(command_type, "blocked", "observer")
		_refresh_order_visuals()
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
		_record_fireteamleader_feedback_for_selected_fireteams(command_type, "blocked", "inactive")
		_refresh_order_visuals()
		_update_ui()
		return false

	var requires_tile: bool = _requires_selected_tile_for_command(command_type) and _has_primary_grid_for_command_selection()
	if requires_tile and not _has_selected_tile:
		_last_command_text = "SELECT TILE FIRST"
		_record_fireteamleader_feedback_for_selected_fireteams(command_type, "blocked", "no_tile")
		_refresh_button_state()
		_refresh_order_visuals()
		_update_ui()
		return false
	if requires_tile:
		_apply_selected_tile_to_target_marker()

	var issued_count: int = 0
	for driver in _get_active_flow_drivers():
		if driver == null or (not driver.has_method("issue_command") and not driver.has_method("issue_command_at_position")):
			continue

		var did_issue: bool = false
		if requires_tile and driver.has_method("issue_command_at_position"):
			did_issue = bool(driver.call("issue_command_at_position", _selected_tile_world_position, command_type, _get_live_order_phase_index()))
		elif driver.has_method("issue_command"):
			did_issue = bool(driver.call("issue_command", command_type, _get_live_order_phase_index()))
		if did_issue:
			issued_count += 1

	if issued_count == 0:
		_last_command_text = "%s FAILED" % display_text
		_record_fireteamleader_feedback_for_selected_fireteams(command_type, "blocked", "failed")
		_refresh_order_visuals()
		_update_ui()
		return false

	_last_command_text = "%s (%s)" % [display_text, _get_fireteam_name()]
	_record_fireteamleader_feedback_for_selected_fireteams(command_type, "accepted", "accepted")
	_refresh_order_visuals()
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
	_store_selected_mission_dropship_plan()
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
	_focus_primary_view_on_selected_fireteams()


func _on_target_button_pressed() -> void:
	_is_lz_placement_armed = false
	_is_target_placement_armed = not _is_target_placement_armed
	_last_command_text = "CLICK MAP FOR TARGET TILE" if _is_target_placement_armed else "TARGET PLACEMENT CANCELLED"
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


func _on_delete_order_pressed() -> void:
	if _delete_selected_order():
		return
	_last_command_text = "NO ORDER SELECTED"
	_refresh_button_state()
	_update_ui()


func _on_sort_fireteam_pressed() -> void:
	if preview_mode:
		_last_command_text = "PREVIEW MODE"
		_update_ui()
		return
	if not _can_issue_local_commands():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	if _selected_fireteam_ids.is_empty():
		_last_command_text = "SELECT FIRETEAM FIRST"
		_update_ui()
		return
	var did_focus: bool = _focus_primary_view_on_selected_fireteams()
	_record_fireteamleader_feedback_for_selected_fireteams("sort", "accepted", "center" if did_focus else "selected")
	_last_command_text = "SORT %s" % _get_fireteam_name().to_upper()
	_refresh_order_visuals()
	_refresh_button_state()
	_update_ui()


func _on_clear_target_pressed() -> void:
	_snap_target_to_objective()
	var target_context: Dictionary = _build_tile_context_from_world_position(_get_target_position())
	if not target_context.is_empty():
		_set_selected_tile_context(target_context, "", false, false)
	_last_command_text = "TARGET RESET TO OBJECTIVE"
	_refresh_button_state()
	_update_ui()


func _on_set_lz_pressed() -> void:
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	_is_lz_placement_armed = not _is_lz_placement_armed
	_lz_placement_craft_id = _mission_drop_craft_id.strip_edges() if _is_lz_placement_armed else ""
	_last_command_text = "CLICK MAP FOR LZ TILE" if _is_lz_placement_armed else "LZ PLACEMENT CANCELLED"
	_update_ui()


func _on_call_dropship_pressed() -> void:
	_request_selected_mission_dropship_drop(false)


func _request_selected_mission_dropship_drop(ignore_global_cooldown: bool = false) -> void:
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	if not _is_mission_drop_available():
		_last_command_text = "DROP SHIP NOT ON MISSION MAP"
		_update_ui()
		return
	if not ignore_global_cooldown and not preview_mode and _drop_ship_cooldown_remaining > 0.0:
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
		if _try_start_drop_sequence(ignore_global_cooldown):
			_last_command_text = "DROP INBOUND %s" % _get_approach_angle_name()
		else:
			_last_command_text = "DROP %s" % _get_approach_angle_name()
	elif _has_live_drop_sequence_for_craft(_mission_drop_craft_id):
		_last_command_text = "DROP ALREADY ACTIVE"
	elif _try_start_drop_sequence(ignore_global_cooldown):
		_drop_ship_requested = true
		_last_command_text = "DROP INBOUND %s" % _get_approach_angle_name()
	else:
		_drop_ship_requested = false
		_last_command_text = "NO DROP TEAM AVAILABLE"
	_store_selected_mission_dropship_plan()
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
		TACTICAL_EVENT_LOG_PANEL_PATH,
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
	_refresh_tactical_event_log_panel()

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


func _refresh_tactical_event_log_panel() -> void:
	var panel := get_node_or_null(TACTICAL_EVENT_LOG_PANEL_PATH) as Control
	if panel == null or not panel.has_method("set_feedback_snapshot"):
		return
	panel.call("set_feedback_snapshot", get_command_feedback_snapshot())
	_refresh_mission_control_craft_summary()
	_refresh_dynamic_button_styles()
	_apply_drop_light_hud_button_labels()
	_apply_command_hierarchy_metadata()
	_enforce_drop_light_fixed_hud_layout()
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
	_apply_fireteam_panel_action_button_contract()


func _refresh_fireteam_phase_panel() -> void:
	var legacy_phase_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel") as Control
	if legacy_phase_panel != null:
		legacy_phase_panel.visible = false
	var panel := _ensure_fireteam_phase_panel()
	if panel == null:
		return
	panel.visible = PHASE_PLANNING_ENABLED
	if not PHASE_PLANNING_ENABLED:
		_apply_fireteam_panel_action_button_contract()
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
		go_phase_button.visible = false
		go_phase_button.disabled = preview_mode or not _can_issue_local_commands() or not _has_selected_fireteam_orders_to_execute()
		go_phase_button.tooltip_text = "Start the live mission from Homebase before GO can execute orders." if preview_mode else "Fuehrt das ausgewaehlte Fireteam zum naechsten offenen Zielpunkt."
		META_UI_SKIN_SCRIPT.style_tactical_button(go_phase_button, not go_phase_button.disabled)
	_apply_fireteam_panel_action_button_contract()


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
		if suppression_progress is Control:
			(suppression_progress as Control).tooltip_text = "SUPP = Suppression. Steigt unter Beschuss; bei vollem Balken ist das Fireteam gepinnt."
	var stance_text: String = _build_selected_tactical_stance_text()
	var execution_text: String = _build_selected_execution_quality_text()
	var movement_text: String = _format_movement_state_text(get_fireteam_movement_state(selected_fireteam_id))
	var security_text: String = _format_security_state_text(get_fireteam_security_state(selected_fireteam_id))
	var flank_text: String = _format_flank_vulnerability_text(get_fireteam_flank_vulnerability_state(selected_fireteam_id))
	if suppression_label != null:
		var ad_hoc_text: String = " | AD-HOC %s" % ad_hoc_type.to_upper() if not ad_hoc_type.is_empty() else ""
		suppression_label.text = "%s | STANCE %s | EXEC %s | MOVE %s | SEC %s | FLK %s | SUPP %.2f/%.2f%s" % [lead_name, stance_text, execution_text, movement_text, security_text, flank_text, suppression_value, suppression_threshold, ad_hoc_text]
	var can_return_to_plan: bool = _can_return_fireteam_to_plan(selected_fireteam_id)
	if return_button != null:
		return_button.call("configure", "Return to Plan", "return_to_plan", "Fuehrt das ausgewaehlte Fireteam zurueck in den geplanten Ablauf.", "command" if can_return_to_plan else "neutral")
		return_button.visible = can_return_to_plan
		return_button.disabled = not can_return_to_plan
	_apply_fireteam_panel_action_button_contract()


func _has_pending_plan_for_fireteam(fireteam_id: String) -> bool:
	var active_phase_index: int = _get_live_order_phase_index()
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, active_phase_index), null)
	if plan == null:
		return false
	for waypoint in plan.waypoints:
		if String(waypoint.status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or String(waypoint.status) == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED:
			return true
	return false


func _can_return_fireteam_to_plan(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return false
	if _has_pending_plan_for_fireteam(normalized_fireteam_id):
		return true
	return _ad_hoc_order_controller != null and bool(_ad_hoc_order_controller.call("has_active_order", normalized_fireteam_id))


func _can_return_selected_fireteams_to_plan() -> bool:
	for fireteam_id_variant in _selected_fireteam_ids:
		if _can_return_fireteam_to_plan(String(fireteam_id_variant)):
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

	var selected_cards_fireteam_id: String = _get_selected_member_cards_fireteam_id()
	var units: Array = []
	if not selected_cards_fireteam_id.is_empty():
		units = _get_fireteam_units(selected_cards_fireteam_id, true)
	else:
		units = _get_selected_friendly_units(not _use_visible_units_for_fireteam_ui())
	card_row.set_meta("selected_member_cards_fireteam_id", selected_cards_fireteam_id)
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
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges() if unit != null and unit.has_method("get_unit_id") else ""
		var in_drop_transit: bool = not unit_id.is_empty() and _embarked_unit_ids.has(unit_id) and not _deployed_unit_ids.has(unit_id)
		card.custom_minimum_size = Vector2(156.0, 70.0)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.call(
			"setup_from_profile",
			_build_fireteam_card_profile(unit),
			{
				"source_context": "mission_selected_fireteam_member",
				"compact_mode": true,
				"drag_enabled": false,
				"show_lead_indicator": true,
				"is_lead": _is_unit_current_fireteam_lead(unit),
				"selected": _is_selected_member_card_unit(unit, selected_cards_fireteam_id),
				"disabled": in_drop_transit,
				"fixed_size": true,
				"fixed_card_size": Vector2(156.0, 70.0),
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
		var card: FOBFireteamCard = FOB_FIRETEAM_CARD_SCRIPT.new()
		card.name = "FireteamMiniCard_%s" % normalized_fireteam_id.capitalize()
		card.custom_minimum_size = Vector2(0.0, 86.0)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.set_meta("fireteam_id", normalized_fireteam_id)

		var lead = _resolve_fireteam_leader_for_behavior(normalized_fireteam_id)
		var selected_fireteam: bool = _selected_fireteam_ids.has(normalized_fireteam_id)
		var runtime_inactive: bool = not preview_mode and not _is_fireteam_runtime_active(normalized_fireteam_id)
		var lead_name: String = String(lead.call("get_display_name")) if lead != null and lead.has_method("get_display_name") else "Kein Lead"
		card.call(
			"setup_card",
			normalized_fireteam_id,
			_get_fireteam_display_label(normalized_fireteam_id),
			selected_fireteam,
			false,
			_get_mission_fireteam_loadout_id(normalized_fireteam_id),
			_build_mission_fireteam_reference_summary(normalized_fireteam_id, lead_name, units),
			"mission_mini"
		)
		_apply_fireteam_mini_card_status_context(card, normalized_fireteam_id, units)
		_apply_fireteam_mini_card_leader_portrait(card, lead)
		card.set_meta("mission_fireteam_mini_card", true)
		card.set_meta("fob_fireteam_reference_card", true)
		card.modulate = Color(1.0, 1.0, 1.0, 0.58) if runtime_inactive else Color.WHITE
		var input_callable := Callable(self, "_on_fireteam_mini_card_gui_input").bind(normalized_fireteam_id)
		if not card.gui_input.is_connected(input_callable):
			card.gui_input.connect(input_callable)
		if not card.card_pressed.is_connected(_on_fireteam_mini_reference_card_pressed):
			card.card_pressed.connect(_on_fireteam_mini_reference_card_pressed)
		card_host.add_child(card)


func _on_fireteam_mini_card_gui_input(event: InputEvent, fireteam_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index != MOUSE_BUTTON_LEFT:
			return
		_cancel_selection_interaction()
		get_viewport().set_input_as_handled()
		if mouse_button_event.pressed:
			_on_fireteam_group_pressed(fireteam_id)


func _on_fireteam_mini_reference_card_pressed(fireteam_id: String) -> void:
	_cancel_selection_interaction()
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	_on_fireteam_group_pressed(fireteam_id)


func _get_mission_fireteam_loadout_id(fireteam_id: String) -> String:
	var definition: Dictionary = _get_mission_fireteam_definition(fireteam_id)
	var loadout_id: String = String(definition.get("loadout", definition.get("loadout_id", "medium"))).strip_edges()
	return loadout_id if not loadout_id.is_empty() else "medium"


func _get_selected_member_cards_fireteam_id() -> String:
	if _selected_fireteam_ids.size() != 1:
		return ""
	var selected_fireteam_id: String = _get_selected_fireteam_id().strip_edges().to_lower()
	if selected_fireteam_id.is_empty():
		return ""
	if _is_fireteam_runtime_active(selected_fireteam_id) or not _get_fireteam_units(selected_fireteam_id, true).is_empty():
		return selected_fireteam_id
	return ""


func _is_selected_member_card_unit(unit: Node, selected_cards_fireteam_id: String) -> bool:
	if unit == null:
		return false
	var normalized_fireteam_id: String = selected_cards_fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return _is_unit_selected(unit)
	if not unit.has_method("get_fireteam_id"):
		return false
	return String(unit.call("get_fireteam_id")).strip_edges().to_lower() == normalized_fireteam_id


func _apply_fireteam_mini_card_leader_portrait(card: Control, lead) -> void:
	if card == null or lead == null:
		return
	var header_row := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	if header_row == null:
		return
	var portrait_rect := header_row.get_node_or_null("LeaderPortraitRect") as TextureRect
	if portrait_rect == null:
		portrait_rect = TextureRect.new()
		portrait_rect.name = "LeaderPortraitRect"
		portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait_rect.custom_minimum_size = Vector2(34.0, 34.0)
		portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		header_row.add_child(portrait_rect)
		header_row.move_child(portrait_rect, 0)
	var profile = _build_profile_from_unit(lead)
	var portrait_id: String = ""
	var portrait_path: String = ""
	if profile != null:
		portrait_id = String(profile.get("portrait_id")).strip_edges()
		portrait_path = String(profile.get("portrait_path")).strip_edges()
	if portrait_path.is_empty() and lead.has_method("get_portrait_path"):
		portrait_path = String(lead.call("get_portrait_path")).strip_edges()
	portrait_rect.texture = _load_portrait_identity_texture(portrait_id, portrait_path)
	portrait_rect.modulate = Color.WHITE if portrait_rect.texture != null else Color(0.36, 0.39, 0.44, 1.0)
	portrait_rect.set_meta("mission_fireteam_leader_portrait", true)


func _apply_fireteam_mini_card_status_context(card: Control, fireteam_id: String, units: Array = []) -> void:
	if card == null:
		return
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var profile_dict: Dictionary = get_active_behavior_profile(normalized_fireteam_id)
	var contact_context: Dictionary = _build_fireteam_contact_badge_context(normalized_fireteam_id)
	var coordination_context: Dictionary = _build_fireteam_coordination_badge_context(normalized_fireteam_id)
	var status_snapshot: Dictionary = _build_fireteam_status_card_entry(normalized_fireteam_id, units, profile_dict, contact_context)
	var tooltip_parts: PackedStringArray = PackedStringArray()
	var execution_text: String = _build_execution_quality_tooltip_text(profile_dict)
	if not execution_text.is_empty():
		tooltip_parts.append(execution_text)
	var ftl_text: String = _build_ftl_quality_tooltip_text(profile_dict)
	if not ftl_text.is_empty():
		tooltip_parts.append(ftl_text)
	var morale_text: String = _build_morale_tooltip_text(profile_dict)
	if not morale_text.is_empty():
		tooltip_parts.append(morale_text)
	var contact_text: String = _build_fireteam_contact_tooltip_text(contact_context)
	if not contact_text.is_empty():
		tooltip_parts.append(contact_text)
	var coordination_text: String = _build_fireteam_coordination_tooltip_text(coordination_context)
	if not coordination_text.is_empty():
		tooltip_parts.append(coordination_text)
	card.tooltip_text = "\n".join(tooltip_parts)
	card.set_meta("execution_reason", String(profile_dict.get("execution_reason", "")).strip_edges().to_lower())
	card.set_meta("contact_state", String(contact_context.get("state", "")).strip_edges().to_lower())
	card.set_meta("tactical_stance", get_requested_tactical_stance(normalized_fireteam_id))
	card.set_meta("mission_fireteam_status_card_snapshot", status_snapshot.duplicate(true))
	card.set_meta("mission_fireteam_status_selected", bool(status_snapshot.get("selected", false)))
	_apply_fireteam_mini_status_summary(card, status_snapshot)
	_apply_fireteam_member_status_row(card, normalized_fireteam_id, units)
	_apply_fireteam_mini_contact_badge(card, contact_context)
	_apply_fireteam_mini_ftl_quality_indicator(card, profile_dict, normalized_fireteam_id)
	_apply_fireteam_mini_morale_indicator(card, profile_dict)
	_apply_fireteam_mini_coordination_badge(card, coordination_context)
	_apply_fireteam_mini_stance_toggle(card, normalized_fireteam_id)


func _apply_fireteam_mini_status_summary(card: Control, status_snapshot: Dictionary) -> void:
	var stage_label := card.get_node_or_null("Margin/VBox/StageLabel") as Label
	var member_label := card.get_node_or_null("Margin/VBox/MemberLabel") as Label
	if stage_label != null:
		stage_label.text = String(status_snapshot.get("secondary_text", "")).strip_edges()
		stage_label.visible = not stage_label.text.is_empty()
		stage_label.tooltip_text = String(status_snapshot.get("tooltip_text", ""))
		stage_label.set_meta("mission_fireteam_status_secondary", true)
	if member_label != null:
		member_label.text = String(status_snapshot.get("primary_text", "")).strip_edges()
		member_label.visible = not member_label.text.is_empty()
		member_label.tooltip_text = String(status_snapshot.get("tooltip_text", ""))
		member_label.set_meta("mission_fireteam_status_primary", true)


func _apply_fireteam_member_status_row(card: Control, fireteam_id: String, units: Array = []) -> void:
	var row := card.get_node_or_null("FireteamMemberStatusRow") as Control
	if row == null:
		row = FIRETEAM_MEMBER_STATUS_ROW_SCRIPT.new()
		row.name = "FireteamMemberStatusRow"
		card.add_child(row)
	row.anchor_left = 0.0
	row.anchor_right = 0.0
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 6.0
	row.offset_right = 6.0 + FIRETEAM_MEMBER_STATUS_ROW_SCRIPT.DEFAULT_SIZE.x
	row.offset_top = -FIRETEAM_MEMBER_STATUS_ROW_SCRIPT.DEFAULT_SIZE.y - 4.0
	row.offset_bottom = -4.0
	var snapshot: Dictionary = _build_fireteam_member_status_row_entry(fireteam_id, _get_fireteam_units(fireteam_id, true))
	row.call("set_member_snapshot", snapshot)
	row.set_meta("mission_fireteam_member_status_row", true)
	row.set_meta("mission_fireteam_member_status_snapshot", Dictionary(row.call("get_row_snapshot")).duplicate(true))
	card.set_meta("mission_fireteam_member_status_host", true)


func _apply_fireteam_mini_contact_badge(card: Control, contact_context: Dictionary) -> void:
	var header_row := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	if header_row == null:
		return
	var badge := header_row.get_node_or_null("ContactBadge") as Label
	if badge == null:
		badge = Label.new()
		badge.name = "ContactBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.custom_minimum_size = Vector2(42.0, 18.0)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 9)
		header_row.add_child(badge)
	var badge_text: String = _format_fireteam_contact_badge_text(contact_context)
	badge.visible = not badge_text.is_empty()
	badge.text = badge_text
	badge.modulate = _contact_badge_color(String(contact_context.get("state", "")))
	badge.set_meta("mission_fireteam_contact_badge", true)


func _apply_fireteam_mini_ftl_quality_indicator(card: Control, profile_dict: Dictionary, fireteam_id: String = "") -> void:
	var header_row := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	if header_row == null:
		return
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		normalized_fireteam_id = String(profile_dict.get("fireteam_id", "")).strip_edges().to_lower()
	var public_snapshot: Dictionary = Dictionary(Dictionary(profile_dict.get("metadata", {})).get("ftl_public_snapshot", {}))
	var gauge := header_row.get_node_or_null("FTLReadinessGauge") as Control
	if gauge == null:
		gauge = FTL_READINESS_GAUGE_SCRIPT.new()
		gauge.name = "FTLReadinessGauge"
		header_row.add_child(gauge)
		header_row.move_child(gauge, 0)
	var readiness_snapshot: Dictionary = _build_ftl_readiness_snapshot_for_fireteam(normalized_fireteam_id) if not normalized_fireteam_id.is_empty() else Dictionary(FTL_READINESS_SNAPSHOT_CONTRACT_SCRIPT.call("build_snapshot", normalized_fireteam_id, null, profile_dict, {}))
	gauge.call("set_snapshot", readiness_snapshot)
	gauge.set_meta("mission_fireteam_ftl_readiness_gauge", true)
	gauge.set_meta("mission_fireteam_ftl_readiness_state", String(Dictionary(gauge.call("get_gauge_snapshot")).get("display_state", "")))
	if public_snapshot.is_empty():
		return
	var plan_dot := header_row.get_node_or_null("FTLPlanQualityDot") as ColorRect
	if plan_dot == null:
		plan_dot = ColorRect.new()
		plan_dot.name = "FTLPlanQualityDot"
		plan_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plan_dot.custom_minimum_size = Vector2(8.0, 8.0)
		header_row.add_child(plan_dot)
	var plan_quality: float = clampf(float(public_snapshot.get("plan_quality", 0.5)), 0.0, 1.0)
	plan_dot.color = _plan_quality_color(plan_quality)
	plan_dot.set_meta("mission_fireteam_ftl_plan_quality", plan_quality)

	var reaction_bars := header_row.get_node_or_null("FTLReactionBars") as HBoxContainer
	if reaction_bars == null:
		reaction_bars = HBoxContainer.new()
		reaction_bars.name = "FTLReactionBars"
		reaction_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
		reaction_bars.add_theme_constant_override("separation", 1)
		header_row.add_child(reaction_bars)
	while reaction_bars.get_child_count() < 3:
		var bar := ColorRect.new()
		bar.name = "Bar%d" % (reaction_bars.get_child_count() + 1)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(4.0, 12.0)
		reaction_bars.add_child(bar)
	var reaction_delay: float = clampf(float(public_snapshot.get("reaction_delay_seconds", profile_dict.get("reaction_delay_seconds", 0.35))), 0.0, 1.0)
	var filled_bars: int = _reaction_delay_bar_count(reaction_delay)
	for index in range(reaction_bars.get_child_count()):
		var bar_rect := reaction_bars.get_child(index) as ColorRect
		if bar_rect == null:
			continue
		bar_rect.color = Color(0.42, 0.78, 0.96, 1.0) if index < filled_bars else Color(0.22, 0.25, 0.29, 1.0)
	reaction_bars.set_meta("mission_fireteam_ftl_reaction_delay", reaction_delay)


func _apply_fireteam_mini_morale_indicator(card: Control, profile_dict: Dictionary) -> void:
	var header_row := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	if header_row == null:
		return
	var context: Dictionary = _build_morale_badge_context(profile_dict)
	var badge := header_row.get_node_or_null("MoraleBadge") as Label
	if badge == null:
		badge = Label.new()
		badge.name = "MoraleBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.custom_minimum_size = Vector2(28.0, 18.0)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 9)
		header_row.add_child(badge)
	badge.visible = not context.is_empty()
	if context.is_empty():
		return
	badge.text = String(context.get("text", "M"))
	badge.modulate = Color(context.get("color", Color.WHITE))
	badge.set_meta("mission_fireteam_morale_state", String(context.get("state", "")))
	badge.set_meta("mission_fireteam_morale", float(context.get("morale", 0.5)))
	badge.set_meta("mission_fireteam_frustration", float(context.get("frustration", 0.0)))


func _apply_fireteam_mini_coordination_badge(card: Control, coordination_context: Dictionary) -> void:
	var header_row := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	if header_row == null:
		return
	var badge := header_row.get_node_or_null("CoordinationBadge") as Label
	if badge == null:
		badge = Label.new()
		badge.name = "CoordinationBadge"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.custom_minimum_size = Vector2(42.0, 18.0)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 9)
		header_row.add_child(badge)
	badge.visible = not coordination_context.is_empty()
	if coordination_context.is_empty():
		return
	badge.text = "COORD"
	badge.modulate = Color(0.48, 0.82, 1.0, 1.0) if String(coordination_context.get("role", "")) == "advance" else Color(0.64, 1.0, 0.72, 1.0)
	badge.set_meta("mission_fireteam_coordination_role", String(coordination_context.get("role", "")))
	badge.set_meta("mission_fireteam_coordination_partner", String(coordination_context.get("partner_fireteam_id", "")))


func _apply_fireteam_mini_stance_toggle(card: Control, fireteam_id: String) -> void:
	var header_row := card.get_node_or_null("Margin/VBox/HeaderRow") as HBoxContainer
	if header_row == null:
		return
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var toggle_row := header_row.get_node_or_null("StanceToggle") as HBoxContainer
	if toggle_row == null:
		toggle_row = HBoxContainer.new()
		toggle_row.name = "StanceToggle"
		toggle_row.mouse_filter = Control.MOUSE_FILTER_STOP
		toggle_row.add_theme_constant_override("separation", 1)
		header_row.add_child(toggle_row)
	var current_stance: String = get_requested_tactical_stance(normalized_fireteam_id)
	for stance_id in ["cautious", "normal", "aggressive"]:
		var button_name: String = "Stance%sButton" % _get_tactical_stance_short_label(String(stance_id))
		var button := toggle_row.get_node_or_null(button_name) as Button
		if button == null:
			button = Button.new()
			button.name = button_name
			button.focus_mode = Control.FOCUS_NONE
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.toggle_mode = true
			button.custom_minimum_size = Vector2(24.0, 20.0)
			button.add_theme_font_size_override("font_size", 9)
			toggle_row.add_child(button)
		button.text = _get_tactical_stance_short_label(String(stance_id))
		button.tooltip_text = "Tactical Stance: %s" % _get_tactical_stance_button_text(String(stance_id))
		button.button_pressed = current_stance == String(stance_id)
		button.set_meta("mission_fireteam_stance_button", true)
		button.set_meta("fireteam_id", normalized_fireteam_id)
		button.set_meta("mission_fireteam_stance_id", String(stance_id))
		if button.has_meta("tactical_stance_id"):
			button.remove_meta("tactical_stance_id")
		META_UI_SKIN_SCRIPT.style_tactical_button(button, button.button_pressed)
		var press_callable := Callable(self, "_on_fireteam_mini_stance_button_pressed").bind(normalized_fireteam_id, String(stance_id))
		if not button.pressed.is_connected(press_callable):
			button.pressed.connect(press_callable)
	toggle_row.set_meta("mission_fireteam_stance_toggle", true)


func _on_fireteam_mini_stance_button_pressed(fireteam_id: String, stance_id: String) -> void:
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	set_fireteams_tactical_stance(PackedStringArray([fireteam_id]), stance_id)


func _build_fireteam_contact_badge_context(fireteam_id: String) -> Dictionary:
	var highest_rank: int = 0
	var highest_state: String = ""
	var contact_count: int = 0
	var revealed_profiles: PackedStringArray = PackedStringArray()
	for contact_variant in get_fireteam_contact_snapshot(fireteam_id):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var state: String = String(contact.get("detection_state", "")).strip_edges().to_lower()
		var rank: int = _rank_contact_badge_state(state)
		if rank <= 0:
			continue
		contact_count += 1
		if rank > highest_rank:
			highest_rank = rank
			highest_state = state
		if bool(contact.get("enemy_profile_revealed", false)):
			var profile_label: String = String(contact.get("enemy_profile_label", "")).strip_edges()
			if not profile_label.is_empty() and not revealed_profiles.has(profile_label):
				revealed_profiles.append(profile_label)
	if highest_state.is_empty():
		return {}
	return {
		"state": highest_state,
		"count": contact_count,
		"revealed_profiles": revealed_profiles,
	}


func _rank_contact_badge_state(state: String) -> int:
	match state.strip_edges().to_lower():
		"lost":
			return 1
		"suspected":
			return 2
		"spotted":
			return 3
		"confirmed":
			return 4
		_:
			return 0


func _format_fireteam_contact_badge_text(contact_context: Dictionary) -> String:
	var state: String = String(contact_context.get("state", "")).strip_edges().to_lower()
	if state.is_empty():
		return ""
	var short_label: String = ""
	match state:
		"suspected":
			short_label = "SUS"
		"spotted":
			short_label = "SPOT"
		"confirmed":
			short_label = "CONF"
		"lost":
			short_label = "LOST"
		_:
			return ""
	var count: int = maxi(int(contact_context.get("count", 1)), 1)
	return "%s %d" % [short_label, count] if count > 1 else short_label


func _contact_badge_color(state: String) -> Color:
	match state.strip_edges().to_lower():
		"suspected":
			return Color(0.68, 0.70, 0.74, 1.0)
		"spotted":
			return Color(0.96, 0.58, 0.22, 1.0)
		"confirmed":
			return Color(1.0, 0.28, 0.25, 1.0)
		"lost":
			return Color(0.42, 0.48, 0.54, 1.0)
		_:
			return Color.WHITE


func _build_fireteam_coordination_badge_context(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	for assignment_variant in _active_coordination_by_id.values():
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		var advance_fireteam_id: String = String(assignment.get("advance_fireteam_id", "")).strip_edges().to_lower()
		var cover_fireteam_id: String = String(assignment.get("cover_fireteam_id", "")).strip_edges().to_lower()
		if advance_fireteam_id == normalized_fireteam_id:
			return {
				"coordination_id": String(assignment.get("coordination_id", "")),
				"role": "advance",
				"partner_fireteam_id": cover_fireteam_id,
			}
		if cover_fireteam_id == normalized_fireteam_id:
			return {
				"coordination_id": String(assignment.get("coordination_id", "")),
				"role": "cover",
				"partner_fireteam_id": advance_fireteam_id,
			}
	return {}


func _build_fireteam_coordination_tooltip_text(coordination_context: Dictionary) -> String:
	if coordination_context.is_empty():
		return ""
	var role: String = String(coordination_context.get("role", "")).strip_edges().to_lower()
	var partner_id: String = String(coordination_context.get("partner_fireteam_id", "")).strip_edges().to_lower()
	var partner_label: String = _get_fireteam_display_label(partner_id)
	if partner_label.is_empty():
		partner_label = partner_id.to_upper()
	if role == "cover":
		return "Coordination: covering %s" % partner_label
	if role == "advance":
		return "Coordination: advancing under %s cover" % partner_label
	return "Coordination active"


func _build_execution_quality_tooltip_text(profile_dict: Dictionary) -> String:
	if profile_dict.is_empty():
		return ""
	var label: String = String(profile_dict.get("execution_label", "STEADY")).strip_edges().to_upper()
	var hint: String = String(profile_dict.get("execution_hint", "")).strip_edges()
	if hint.is_empty():
		var reason: String = String(profile_dict.get("execution_reason", "")).strip_edges().replace("_", " ")
		hint = reason.capitalize() if not reason.is_empty() else "No execution reason recorded."
	return "%s: %s" % [label, hint]


func _build_ftl_quality_tooltip_text(profile_dict: Dictionary) -> String:
	var public_snapshot: Dictionary = Dictionary(Dictionary(profile_dict.get("metadata", {})).get("ftl_public_snapshot", {}))
	if public_snapshot.is_empty():
		return ""
	var plan_quality: float = clampf(float(public_snapshot.get("plan_quality", 0.5)), 0.0, 1.0)
	var reaction_delay: float = clampf(float(public_snapshot.get("reaction_delay_seconds", profile_dict.get("reaction_delay_seconds", 0.35))), 0.0, 1.0)
	return "FTL: plan %s, reaction %s" % [_format_plan_quality_bucket(plan_quality), _format_reaction_delay_bucket(reaction_delay)]


func _build_morale_tooltip_text(profile_dict: Dictionary) -> String:
	var context: Dictionary = _build_morale_badge_context(profile_dict)
	if context.is_empty():
		return ""
	return "Morale: %s (morale %d%%, frustration %d%%)" % [
		String(context.get("state_label", "steady")),
		int(round(float(context.get("morale", 0.5)) * 100.0)),
		int(round(float(context.get("frustration", 0.0)) * 100.0)),
	]


func _build_morale_badge_context(profile_dict: Dictionary) -> Dictionary:
	var public_snapshot: Dictionary = Dictionary(Dictionary(profile_dict.get("metadata", {})).get("ftl_public_snapshot", {}))
	if public_snapshot.is_empty():
		return {}
	var morale: float = clampf(float(public_snapshot.get("morale", 0.5)), 0.0, 1.0)
	var frustration: float = clampf(float(public_snapshot.get("frustration", 0.0)), 0.0, 1.0)
	var state: String = "steady"
	var state_label: String = "steady"
	var text: String = "M~"
	var color: Color = Color(0.72, 0.78, 0.84, 1.0)
	if morale < 0.35 or frustration >= 0.68:
		state = "critical"
		state_label = "critical"
		text = "M!"
		color = Color(1.0, 0.34, 0.28, 1.0)
	elif morale < 0.48 or frustration >= 0.46:
		state = "sinking"
		state_label = "sinking"
		text = "M-"
		color = Color(0.98, 0.66, 0.26, 1.0)
	elif morale >= 0.64 and frustration <= 0.28:
		state = "stable"
		state_label = "stable"
		text = "M+"
		color = Color(0.34, 0.84, 0.52, 1.0)
	return {
		"state": state,
		"state_label": state_label,
		"text": text,
		"color": color,
		"morale": morale,
		"frustration": frustration,
	}


func _build_fireteam_contact_tooltip_text(contact_context: Dictionary) -> String:
	var badge_text: String = _format_fireteam_contact_badge_text(contact_context)
	if badge_text.is_empty():
		return ""
	var state: String = String(contact_context.get("state", "")).strip_edges().to_lower().replace("_", " ")
	var profile_text: String = ""
	var revealed_profiles: PackedStringArray = PackedStringArray(contact_context.get("revealed_profiles", PackedStringArray()))
	if not revealed_profiles.is_empty():
		profile_text = " | Recon: %s" % ", ".join(revealed_profiles)
	return "Contact: %s (%s)%s" % [badge_text, state, profile_text]


func _format_plan_quality_bucket(value: float) -> String:
	if value >= 0.66:
		return "strong"
	if value >= 0.42:
		return "fair"
	return "raw"


func _format_reaction_delay_bucket(value: float) -> String:
	if value <= 0.24:
		return "fast"
	if value <= 0.45:
		return "steady"
	return "slow"


func _plan_quality_color(value: float) -> Color:
	if value >= 0.66:
		return Color(0.30, 0.82, 0.42, 1.0)
	if value >= 0.42:
		return Color(0.92, 0.74, 0.28, 1.0)
	return Color(0.95, 0.30, 0.28, 1.0)


func _reaction_delay_bar_count(value: float) -> int:
	if value <= 0.24:
		return 3
	if value <= 0.45:
		return 2
	return 1


func _build_mission_fireteam_reference_summary(fireteam_id: String, lead_name: String, units: Array) -> String:
	var info_lines: Array = _build_fireteam_mini_info_lines(fireteam_id, units)
	var info_text: String = " | ".join(PackedStringArray(info_lines))
	if info_text.is_empty():
		return "Lead %s" % lead_name
	return "Lead %s | %s" % [lead_name, info_text]


func get_fireteam_status_card_snapshot() -> Array:
	var result: Array = []
	for fireteam_id_variant in _get_displayable_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		result.append(_build_fireteam_status_card_entry(
			fireteam_id,
			_get_fireteam_units(fireteam_id, not _use_visible_units_for_fireteam_ui()),
			get_active_behavior_profile(fireteam_id),
			_build_fireteam_contact_badge_context(fireteam_id)
		))
	return result


func get_fireteam_member_status_row_snapshot() -> Array:
	var result: Array = []
	for fireteam_id_variant in _get_displayable_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		result.append(_build_fireteam_member_status_row_entry(
			fireteam_id,
			_get_fireteam_units(fireteam_id, true)
		))
	return result


func _build_fireteam_member_status_row_entry(fireteam_id: String, units: Array = []) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var resolved_units: Array = units.duplicate()
	if resolved_units.is_empty():
		resolved_units = _get_fireteam_units(normalized_fireteam_id, true)
	var suppression_state: Dictionary = Dictionary(_suppression_state_by_fireteam.get(normalized_fireteam_id, {}))
	var is_suppressed: bool = bool(suppression_state.get("is_suppressed", false)) or bool(suppression_state.get("is_heavily_suppressed", false))
	var members: Array = []
	for unit in resolved_units:
		members.append(_build_fireteam_member_status_entry(unit, is_suppressed))
	return {
		"fireteam_id": normalized_fireteam_id,
		"members": members,
		"member_count": members.size(),
		"counts": _count_fireteam_member_statuses(members),
		"read_only": true,
	}


func _build_fireteam_member_status_entry(unit: Node, fireteam_suppressed: bool) -> Dictionary:
	if unit == null:
		return {
			"unit_id": "",
			"display_name": "Unknown",
			"status": "unknown",
			"vital_state": "unknown",
			"health_ratio": 0.0,
			"is_suppressed": false,
			"is_busy": false,
			"read_only": true,
		}
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges() if unit.has_method("get_unit_id") else ""
	var display_name: String = String(unit.call("get_display_name")).strip_edges() if unit.has_method("get_display_name") else unit_id
	var vital_state: String = String(unit.call("get_vital_state")).strip_edges().to_lower() if unit.has_method("get_vital_state") else "fit"
	var health_points: int = _get_unit_health_points(unit)
	var max_health_points: int = _get_unit_max_health_points(unit)
	var health_ratio: float = 1.0
	if health_points >= 0 and max_health_points > 0:
		health_ratio = clampf(float(health_points) / float(max_health_points), 0.0, 1.0)
	var is_busy: bool = _is_fireteam_member_busy(unit)
	var status: String = _resolve_fireteam_member_status(vital_state, health_ratio, fireteam_suppressed, is_busy)
	return {
		"unit_id": unit_id,
		"display_name": display_name,
		"status": status,
		"label": _fireteam_member_status_label(status),
		"vital_state": vital_state,
		"health_points": health_points,
		"max_health_points": max_health_points,
		"health_ratio": health_ratio,
		"is_suppressed": fireteam_suppressed,
		"is_busy": is_busy,
		"role_label": _build_fireteam_member_role_label(unit),
		"read_only": true,
	}


func _count_fireteam_member_statuses(members: Array) -> Dictionary:
	var counts: Dictionary = {
		"fit": 0,
		"wounded": 0,
		"down": 0,
		"suppressed": 0,
		"busy": 0,
		"unknown": 0,
	}
	for member_variant in members:
		if typeof(member_variant) != TYPE_DICTIONARY:
			counts["unknown"] = int(counts.get("unknown", 0)) + 1
			continue
		var status: String = String(Dictionary(member_variant).get("status", "unknown")).strip_edges().to_lower()
		if not counts.has(status):
			status = "unknown"
		counts[status] = int(counts.get(status, 0)) + 1
	return counts


func _build_fireteam_status_card_entry(fireteam_id: String, units: Array = [], profile_dict: Dictionary = {}, contact_context: Dictionary = {}) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var resolved_units: Array = units.duplicate()
	if resolved_units.is_empty():
		resolved_units = _get_fireteam_units(normalized_fireteam_id, true)
	var resolved_profile: Dictionary = profile_dict.duplicate(true) if not profile_dict.is_empty() else get_active_behavior_profile(normalized_fireteam_id)
	var resolved_contact: Dictionary = contact_context.duplicate(true) if not contact_context.is_empty() else _build_fireteam_contact_badge_context(normalized_fireteam_id)
	var member_status: Dictionary = _build_fireteam_member_status_row_entry(normalized_fireteam_id, _get_fireteam_units(normalized_fireteam_id, true))
	var readiness_snapshot: Dictionary = _build_ftl_readiness_snapshot_for_fireteam(normalized_fireteam_id)
	var readiness_context: Dictionary = _build_fireteam_status_readiness_context(readiness_snapshot)
	var health_context: Dictionary = _build_fireteam_health_status_context(resolved_units)
	var movement_state: Dictionary = get_fireteam_movement_state(normalized_fireteam_id)
	var movement_text: String = _compact_fireteam_movement_text(movement_state, resolved_profile)
	var position_context: Dictionary = _build_fireteam_position_status_context(normalized_fireteam_id)
	var execution_text: String = _format_execution_quality_text(resolved_profile)
	var contact_count: int = maxi(int(resolved_contact.get("count", 0)), 0)
	var contact_state: String = String(resolved_contact.get("state", "clear")).strip_edges().to_lower()
	if contact_state.is_empty():
		contact_state = "clear"
	var contact_text: String = _format_fireteam_status_contact_text(contact_state, contact_count)
	var loadout_id: String = _get_mission_fireteam_loadout_id(normalized_fireteam_id).strip_edges().to_upper()
	var primary_text: String = "EX %s | RDY %s | %s | %s" % [
		execution_text,
		String(readiness_context.get("label", "N/A")),
		contact_text,
		String(health_context.get("text", "HP 0/0")),
	]
	var secondary_parts: PackedStringArray = PackedStringArray()
	secondary_parts.append("LD %s" % (loadout_id if not loadout_id.is_empty() else "MEDIUM"))
	secondary_parts.append("MV %s" % movement_text)
	secondary_parts.append("POS %s" % String(position_context.get("text", "--")))
	var secondary_text: String = " | ".join(secondary_parts)
	var tooltip_parts: PackedStringArray = PackedStringArray()
	tooltip_parts.append("Execution: %s" % execution_text)
	tooltip_parts.append("Readiness: %s" % String(readiness_context.get("label", "N/A")))
	tooltip_parts.append("Contact: %s" % contact_text)
	tooltip_parts.append("Health: %s" % String(health_context.get("detail_text", health_context.get("text", ""))))
	tooltip_parts.append("Move: %s" % movement_text)
	tooltip_parts.append("Position: %s" % String(position_context.get("text", "--")))
	return {
		"fireteam_id": normalized_fireteam_id,
		"selected": _selected_fireteam_ids.has(normalized_fireteam_id),
		"primary_text": primary_text,
		"secondary_text": secondary_text,
		"tooltip_text": "\n".join(tooltip_parts),
		"execution_text": execution_text,
		"execution_label": String(resolved_profile.get("execution_label", "STEADY")).strip_edges().to_upper(),
		"readiness_state": String(readiness_context.get("state", "unavailable")),
		"readiness_label": String(readiness_context.get("label", "N/A")),
		"readiness_score": float(readiness_context.get("score", -1.0)),
		"reaction_delay_seconds": readiness_context.get("reaction_delay_seconds", null),
		"reaction_delay_seconds_available": bool(readiness_context.get("reaction_delay_seconds_available", false)),
		"contact_state": contact_state,
		"contact_count": contact_count,
		"contact_text": contact_text,
		"movement_text": movement_text,
		"movement_state": movement_state.duplicate(true),
		"advance_style": String(resolved_profile.get("advance_style", movement_state.get("effective_style", ""))).strip_edges().to_lower(),
		"position": position_context.duplicate(true),
		"health": health_context.duplicate(true),
		"member_status": member_status.duplicate(true),
		"member_count": resolved_units.size(),
		"loadout_id": loadout_id.to_lower(),
		"read_only": true,
	}


func _build_fireteam_status_readiness_context(readiness_snapshot: Dictionary) -> Dictionary:
	var plan_available: bool = bool(readiness_snapshot.get("plan_quality_available", readiness_snapshot.has("plan_quality") and readiness_snapshot.get("plan_quality") != null))
	var morale_available: bool = bool(readiness_snapshot.get("morale_available", readiness_snapshot.has("morale") and readiness_snapshot.get("morale") != null))
	var reaction_available: bool = bool(readiness_snapshot.get("reaction_delay_seconds_available", readiness_snapshot.has("reaction_delay_seconds") and readiness_snapshot.get("reaction_delay_seconds") != null))
	var value_ranges: Dictionary = Dictionary(readiness_snapshot.get("value_ranges", {}))
	var reaction_range: Dictionary = Dictionary(value_ranges.get("reaction_delay_seconds", {}))
	var min_reaction_delay: float = maxf(float(reaction_range.get("min", 0.05)), 0.001)
	var max_reaction_delay: float = maxf(float(reaction_range.get("max", 0.85)), min_reaction_delay + 0.001)
	var plan_quality: float = clampf(float(readiness_snapshot.get("plan_quality", 0.0)) if plan_available else 0.0, 0.0, 1.0)
	var morale: float = clampf(float(readiness_snapshot.get("morale", 0.0)) if morale_available else 0.0, 0.0, 1.0)
	var reaction_delay: float = clampf(float(readiness_snapshot.get("reaction_delay_seconds", max_reaction_delay)) if reaction_available else max_reaction_delay, min_reaction_delay, max_reaction_delay)
	var reaction_ratio: float = 1.0 - clampf((reaction_delay - min_reaction_delay) / (max_reaction_delay - min_reaction_delay), 0.0, 1.0)
	var total: float = 0.0
	var weight: float = 0.0
	if plan_available:
		total += plan_quality * 0.42
		weight += 0.42
	if morale_available:
		total += morale * 0.28
		weight += 0.28
	if reaction_available:
		total += reaction_ratio * 0.30
		weight += 0.30
	var score: float = -1.0 if weight <= 0.0 else clampf(total / weight, 0.0, 1.0)
	var state: String = _format_fireteam_status_readiness_state(score, plan_available, morale_available, reaction_available)
	return {
		"state": state,
		"label": _format_fireteam_status_readiness_label(state),
		"score": score,
		"reaction_delay_seconds": reaction_delay if reaction_available else null,
		"reaction_delay_seconds_available": reaction_available,
	}


func _format_fireteam_status_readiness_state(score: float, plan_available: bool, morale_available: bool, reaction_available: bool) -> String:
	if not plan_available and not morale_available and not reaction_available:
		return "unavailable"
	if score >= 0.70:
		return "high"
	if score <= 0.38:
		return "low"
	return "medium"


func _format_fireteam_status_readiness_label(state: String) -> String:
	match state.strip_edges().to_lower():
		"high":
			return "HIGH"
		"medium":
			return "MED"
		"low":
			return "LOW"
		_:
			return "N/A"


func _format_fireteam_status_contact_text(contact_state: String, contact_count: int) -> String:
	var count: int = maxi(contact_count, 0)
	if count <= 0:
		return "C0"
	match contact_state.strip_edges().to_lower():
		"confirmed":
			return "C%d CONF" % count
		"spotted":
			return "C%d SPOT" % count
		"suspected":
			return "C%d SUS" % count
		"lost":
			return "C%d LOST" % count
		_:
			return "C%d" % count


func _compact_fireteam_movement_text(movement_state: Dictionary, profile_dict: Dictionary) -> String:
	var movement_text: String = _format_movement_state_text(movement_state)
	if not movement_text.is_empty() and movement_text != "-":
		return movement_text
	var advance_style: String = String(profile_dict.get("advance_style", movement_state.get("effective_style", ""))).strip_edges().to_lower()
	if advance_style.is_empty():
		return "-"
	var compact_label: String = _get_movement_style_short_label(advance_style)
	return compact_label if compact_label != "-" else advance_style.substr(0, mini(4, advance_style.length())).to_upper()


func _build_fireteam_position_status_context(fireteam_id: String) -> Dictionary:
	var anchor := _get_selection_anchor_for_fireteam(fireteam_id)
	if anchor == null:
		return {
			"has_position": false,
			"has_grid": false,
			"text": "--",
			"world_position": Vector2.ZERO,
			"grid_position": Vector2i.ZERO,
		}
	var world_position: Vector2 = anchor.global_position
	var grid_variant = _primary_view_bridge.call("world_to_grid_position", get_parent(), world_position)
	if typeof(grid_variant) == TYPE_VECTOR2I:
		var grid_position := Vector2i(grid_variant)
		return {
			"has_position": true,
			"has_grid": true,
			"text": _format_grid_position(grid_position),
			"world_position": world_position,
			"grid_position": grid_position,
		}
	return {
		"has_position": true,
		"has_grid": false,
		"text": _format_world_position(world_position),
		"world_position": world_position,
		"grid_position": Vector2i.ZERO,
	}


func _build_fireteam_health_status_context(units: Array) -> Dictionary:
	var total_count: int = units.size()
	var fit_count: int = 0
	var wounded_count: int = 0
	var down_count: int = 0
	var bleedout_count: int = 0
	var respawn_count: int = 0
	for unit in units:
		if unit == null:
			continue
		var vital_state: String = String(unit.call("get_vital_state")).strip_edges().to_lower() if unit.has_method("get_vital_state") else "fit"
		match vital_state:
			"down":
				down_count += 1
			"bleedout":
				bleedout_count += 1
			"respawning":
				respawn_count += 1
			_:
				var health_points: int = _get_unit_health_points(unit)
				var max_health_points: int = _get_unit_max_health_points(unit)
				if health_points >= 0 and max_health_points > 0 and health_points < max_health_points:
					wounded_count += 1
				else:
					fit_count += 1
	var text: String = "HP %d/%d" % [fit_count, total_count]
	var details: PackedStringArray = PackedStringArray([text])
	if wounded_count > 0:
		details.append("WOUND %d" % wounded_count)
	if down_count > 0:
		details.append("DOWN %d" % down_count)
	if bleedout_count > 0:
		details.append("BLEED %d" % bleedout_count)
	if respawn_count > 0:
		details.append("RESPAWN %d" % respawn_count)
	return {
		"total_count": total_count,
		"fit_count": fit_count,
		"wounded_count": wounded_count,
		"down_count": down_count,
		"bleedout_count": bleedout_count,
		"respawn_count": respawn_count,
		"text": text,
		"detail_text": " | ".join(details),
	}


func _get_unit_max_health_points(unit: Node) -> int:
	if unit == null:
		return -1
	if unit.has_method("get_max_health_points"):
		return int(unit.call("get_max_health_points"))
	var exported_max_health = unit.get("max_health_points")
	if typeof(exported_max_health) == TYPE_INT or typeof(exported_max_health) == TYPE_FLOAT:
		return int(exported_max_health)
	return -1


func _is_fireteam_member_busy(unit: Node) -> bool:
	if unit == null or not unit.has_method("get_runtime_status"):
		return false
	var runtime_status = unit.call("get_runtime_status")
	if runtime_status == null or not runtime_status.has_method("get"):
		return false
	var status_name: String = String(runtime_status.get("status")).strip_edges().to_lower()
	var active_command_type: String = String(runtime_status.get("active_command_type")).strip_edges().to_lower()
	if not active_command_type.is_empty():
		return true
	return not status_name.is_empty() and status_name != "idle"


func _resolve_fireteam_member_status(vital_state: String, health_ratio: float, is_suppressed: bool, is_busy: bool) -> String:
	match vital_state.strip_edges().to_lower():
		"down", "bleedout", "respawning":
			return "down"
	if health_ratio < 0.999:
		return "wounded"
	if is_suppressed:
		return "suppressed"
	if is_busy:
		return "busy"
	return "fit"


func _fireteam_member_status_label(status: String) -> String:
	match status.strip_edges().to_lower():
		"fit":
			return "F"
		"wounded":
			return "W"
		"down":
			return "D"
		"suppressed":
			return "S"
		"busy":
			return "B"
		_:
			return "?"


func _build_fireteam_member_role_label(unit: Node) -> String:
	if unit == null:
		return ""
	if _is_unit_current_fireteam_lead(unit):
		return "FTL"
	if unit.has_method("get_role_name"):
		var role_name: String = String(unit.call("get_role_name")).strip_edges()
		if not role_name.is_empty():
			return role_name
	return ""


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
		parts.append(_format_unit_vital_state_text(unit))
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
	var vital_summary: String = _build_fireteam_vital_summary_text(units)
	var summary: String = "%s | %d Wegpunkte" % [member_count_text, planned_waypoint_count]
	if not vital_summary.is_empty():
		summary = "%s | %s" % [summary, vital_summary]
	return [summary]


func _build_fireteam_vital_summary_text(units: Array) -> String:
	var fit_count: int = 0
	var down_count: int = 0
	var bleedout_count: int = 0
	var respawn_count: int = 0
	var shortest_respawn_seconds: int = 0
	for unit in units:
		if unit == null or not unit.has_method("get_vital_state"):
			continue
		var vital_state: String = String(unit.call("get_vital_state")).strip_edges().to_lower()
		match vital_state:
			"down":
				down_count += 1
			"bleedout":
				bleedout_count += 1
			"respawning":
				respawn_count += 1
				var remaining_seconds: int = _get_unit_respawn_remaining_seconds(unit)
				if remaining_seconds > 0 and (shortest_respawn_seconds <= 0 or remaining_seconds < shortest_respawn_seconds):
					shortest_respawn_seconds = remaining_seconds
			_:
				fit_count += 1
	var parts: PackedStringArray = PackedStringArray()
	if fit_count > 0:
		parts.append("FIT %d" % fit_count)
	if down_count > 0:
		parts.append("DOWN %d" % down_count)
	if bleedout_count > 0:
		parts.append("BLEED %d" % bleedout_count)
	if respawn_count > 0:
		var respawn_text: String = "RESPAWN %d" % respawn_count
		if shortest_respawn_seconds > 0:
			respawn_text = "%s %ds" % [respawn_text, shortest_respawn_seconds]
		parts.append(respawn_text)
	return " | ".join(parts)


func _format_unit_vital_state_text(unit: Node) -> String:
	var vital_state: String = String(unit.call("get_vital_state")).strip_edges().to_lower() if unit != null and unit.has_method("get_vital_state") else "fit"
	if vital_state == "respawning":
		var respawn_seconds: int = _get_unit_respawn_remaining_seconds(unit)
		return "RESPAWN %ds" % respawn_seconds if respawn_seconds > 0 else "RESPAWN"
	if vital_state == "bleedout":
		return "BLEEDOUT"
	if vital_state == "down":
		return "DOWN"
	return vital_state.to_upper()


func _get_unit_respawn_remaining_seconds(unit: Node) -> int:
	if unit == null:
		return 0
	if unit.has_method("get_respawn_remaining_seconds"):
		return maxi(int(unit.call("get_respawn_remaining_seconds")), 0)
	if unit.has_meta("respawn_remaining_seconds"):
		return maxi(int(unit.get_meta("respawn_remaining_seconds", 0)), 0)
	return 0


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
		render_options["editable_metrics"] = false
		render_options["two_column_layout"] = true
		render_options["show_badge_progress"] = true
		render_options["hide_loadout_dropdowns"] = true
	CHARACTER_SHEET_VIEW_SCRIPT.render(host, profile, render_options)
	if unit != null and character_overlay_dev_editor_enabled:
		_append_character_overlay_dev_editor(host, unit)


func _find_friendly_unit_by_id(unit_id: String) -> Node:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return null
	var mission_root: Node = get_parent()
	if mission_root == null:
		return null
	return _find_friendly_unit_by_id_recursive(mission_root, normalized_unit_id)


func _find_friendly_unit_by_id_recursive(root_node: Node, unit_id: String) -> Node:
	if root_node == null:
		return null
	if root_node.has_method("get_team_id") and root_node.has_method("get_unit_id"):
		if String(root_node.call("get_team_id")).strip_edges() == FRIENDLY_TEAM_ID and String(root_node.call("get_unit_id")).strip_edges() == unit_id:
			return root_node
	for child in root_node.get_children():
		var found: Node = _find_friendly_unit_by_id_recursive(child, unit_id)
		if found != null:
			return found
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
	panel.offset_left = -460.0
	panel.offset_top = -360.0
	panel.offset_right = 460.0
	panel.offset_bottom = 360.0
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
	HOVER_SCROLL_BEHAVIOR_SCRIPT.call("install", scroll)

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
		"sniper", "sniper_rifle":
			return "SNP"
		"rocket_launcher", "rocket", "panzerfaust":
			return "RKT"
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
	var tactical_text: String = _build_selected_tactical_communication_text()
	var multi_plan_text: String = _build_selected_multi_fireteam_plan_info_text()
	if not multi_plan_text.is_empty():
		return "%s\n%s" % [tactical_text, multi_plan_text] if not tactical_text.is_empty() else multi_plan_text
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
		return "%s\nWP -" % tactical_text if not tactical_text.is_empty() else "WP -"
	var base_text: String = "\n".join(info_lines)
	return "%s\n%s" % [tactical_text, base_text] if not tactical_text.is_empty() else base_text


func _build_selected_multi_fireteam_plan_info_text() -> String:
	if _selected_fireteam_ids.is_empty():
		return ""
	var lines: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in _selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		var assignment: Dictionary = _find_multi_fireteam_assignment_for_fireteam(fireteam_id)
		if assignment.is_empty():
			continue
		lines.append("%s %s P%d | %s | %s" % [
			_get_fireteam_display_label(fireteam_id),
			String(assignment.get("role_label", "")).to_upper(),
			int(assignment.get("plan_phase_index", 0)),
			String(assignment.get("next_step", "")),
			String(assignment.get("status", "")),
		])
	if lines.is_empty():
		return ""
	return "\n".join(lines)


func _build_mission_control_multi_fireteam_plan_text() -> String:
	var selected_plan: Dictionary = _find_multi_fireteam_plan_for_selected_fireteams()
	var tactical_text: String = _build_mission_control_tactical_communication_text()
	if selected_plan.is_empty():
		return tactical_text
	var plan_text: String = String(selected_plan.get("mission_control_text", ""))
	if tactical_text.is_empty():
		return plan_text
	if plan_text.is_empty():
		return tactical_text
	return "%s | %s" % [tactical_text, plan_text]


func _find_multi_fireteam_plan_for_selected_fireteams() -> Dictionary:
	for fireteam_id_variant in _selected_fireteam_ids:
		var plan: Dictionary = _find_multi_fireteam_plan_for_fireteam(String(fireteam_id_variant))
		if not plan.is_empty():
			return plan
	return {}


func _find_multi_fireteam_plan_for_fireteam(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	for plan_variant in _multi_fireteam_plans_by_id.values():
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan: Dictionary = Dictionary(plan_variant)
		for assignment_variant in Array(plan.get("role_assignments", [])):
			if typeof(assignment_variant) != TYPE_DICTIONARY:
				continue
			if String(Dictionary(assignment_variant).get("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
				return plan.duplicate(true)
	return {}


func _find_multi_fireteam_assignment_for_fireteam(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var plan: Dictionary = _find_multi_fireteam_plan_for_fireteam(normalized_fireteam_id)
	if plan.is_empty():
		return {}
	for assignment_variant in Array(plan.get("role_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		if String(assignment.get("fireteam_id", "")).strip_edges().to_lower() == normalized_fireteam_id:
			return assignment.duplicate(true)
	return {}


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
	var intent_preview_text: String = _build_waypoint_intent_preview_text(normalized_fireteam_id)
	if not intent_preview_text.is_empty():
		text = "%s | %s" % [text, intent_preview_text]
	if not movement_text.is_empty():
		text = "%s | %s" % [text, movement_text]
	return text


func _build_waypoint_intent_preview_text(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return ""
	for entry_variant in _build_waypoint_intent_preview_entries():
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("fireteam_id", "")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		return "Dist %dm | ETA~%ds" % [
			int(round(float(entry.get("distance_world", 0.0)))),
			maxi(int(ceil(float(entry.get("eta_seconds_estimate", 0.0)))), 0),
		]
	return ""


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
		ship_text = "Dropship wartet off-map"
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
	if _has_live_drop_sequence_for_craft(_mission_drop_craft_id) and not _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		var selected_card: Dictionary = _find_mission_dropship_card_entry(_mission_drop_craft_id)
		var selected_state: String = String(selected_card.get("state", "")).strip_edges().to_lower()
		ship_text = "Dropship %s" % (selected_state if not selected_state.is_empty() else "aktiv")
	elif _is_drop_sequence_active() and not _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		ship_text = "Anderes Dropship aktiv"
	elif _drop_sequence_phase == DROP_SEQUENCE_INBOUND:
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
	var air_state: String = str(get_air_asset_status_snapshot().get("state", "intact")).strip_edges().to_lower()
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", air_state)) or air_state == "recovering" or air_state == "unavailable":
		return false
	var selected_card: Dictionary = _find_mission_dropship_card_entry(_mission_drop_craft_id)
	if not selected_card.is_empty():
		return String(selected_card.get("state", "")).strip_edges().to_lower() == "waiting"
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


func _load_portrait_identity_texture(portrait_id: String, portrait_path: String) -> Texture2D:
	return PORTRAIT_IDENTITY_CATALOG_SCRIPT.load_texture(portrait_id.strip_edges(), portrait_path.strip_edges()) as Texture2D


func _load_optional_texture(texture_path: String) -> Texture2D:
	if texture_path.strip_edges().is_empty():
		return null
	var resource: Resource = load(texture_path)
	return resource as Texture2D


func _sanitize_mission_dropship_cards(cards: Array) -> Array:
	var sanitized_cards: Array = []
	var seen_craft_ids: Dictionary = {}
	for card_variant in cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = _sanitize_mission_dropship_card(Dictionary(card_variant))
		var craft_id: String = String(card.get("craft_id", "")).strip_edges()
		if craft_id.is_empty() or seen_craft_ids.has(craft_id):
			continue
		seen_craft_ids[craft_id] = true
		sanitized_cards.append(card)
	return sanitized_cards


func _sanitize_mission_dropship_card(card: Dictionary) -> Dictionary:
	var craft_id: String = String(card.get("craft_id", card.get("mission_drop_craft_id", ""))).strip_edges()
	var display_name: String = String(card.get("display_name", card.get("mission_drop_display_name", "Dropship"))).strip_edges()
	if display_name.is_empty():
		display_name = "Dropship"
	var has_embarked_payload: bool = card.has("embarked_unit_ids")
	var approach_angle: String = _sanitize_approach_angle_name(String(card.get("approach_angle", _get_approach_angle_name())))
	var result: Dictionary = {
		"craft_id": craft_id,
		"display_name": display_name,
		"title_text": String(card.get("title_text", card.get("mission_drop_title_text", display_name))).strip_edges(),
		"texture_path": String(card.get("texture_path", card.get("mission_drop_texture_path", ""))).strip_edges(),
		"state": String(card.get("state", card.get("mission_drop_state", ""))).strip_edges().to_lower(),
		"pilot_text": String(card.get("pilot_text", card.get("mission_drop_pilot_text", ""))).strip_edges(),
		"status_line": String(card.get("status_line", card.get("mission_drop_status_line", ""))).strip_edges(),
		"progress": clampf(float(card.get("progress", card.get("mission_drop_progress", 0.0))), 0.0, 100.0),
		"eta_seconds": maxi(int(card.get("eta_seconds", card.get("mission_drop_eta_seconds", 0))), 0),
		"pilot_unit_id": String(card.get("pilot_unit_id", card.get("mission_drop_pilot_unit_id", ""))).strip_edges(),
		"pilot_display_name": String(card.get("pilot_display_name", card.get("mission_drop_pilot_display_name", ""))).strip_edges(),
		"pilot_portrait_path": String(card.get("pilot_portrait_path", card.get("mission_drop_pilot_portrait_path", ""))).strip_edges(),
		"passenger_count": maxi(int(card.get("passenger_count", card.get("mission_drop_passenger_count", 0))), 0),
		"embarked_unit_ids": _sanitize_drop_payload_ids(Array(card.get("embarked_unit_ids", []))),
		"boarded_fireteam_ids": _sanitize_drop_payload_ids(Array(card.get("boarded_fireteam_ids", []))),
		"queued_fireteam_ids": _sanitize_drop_payload_ids(Array(card.get("queued_fireteam_ids", []))),
		"card_feedback_text": String(card.get("card_feedback_text", "")).strip_edges(),
		"has_embarked_payload": has_embarked_payload,
	}
	if card.has("has_lz_position"):
		result["has_lz_position"] = bool(card.get("has_lz_position", false))
	if card.has("lz_position"):
		result["lz_position"] = _coerce_vector2_value(card.get("lz_position", Vector2.ZERO), Vector2.ZERO)
	if card.has("lz_label") or card.has("lz_name"):
		var raw_lz_label: String = String(card.get("lz_label", card.get("lz_name", ""))).strip_edges()
		if not raw_lz_label.is_empty():
			result["lz_label"] = raw_lz_label
			result["lz_name"] = raw_lz_label
	elif bool(result.get("has_lz_position", false)):
		var generated_lz_label: String = _build_mission_dropship_lz_name(craft_id, display_name)
		result["lz_label"] = generated_lz_label
		result["lz_name"] = generated_lz_label
	if card.has("approach_angle"):
		result["approach_angle"] = approach_angle
	if card.has("drop_ship_requested"):
		result["drop_ship_requested"] = bool(card.get("drop_ship_requested", false))
	if card.has("drop_ship_staged"):
		result["drop_ship_staged"] = bool(card.get("drop_ship_staged", false))
	if card.has("drop_sequence_position"):
		result["drop_sequence_position"] = _coerce_vector2_value(card.get("drop_sequence_position", Vector2.ZERO), Vector2.ZERO)
	if card.has("dropship_position"):
		result["dropship_position"] = _coerce_vector2_value(card.get("dropship_position", Vector2.ZERO), Vector2.ZERO)
	return result


func _sanitize_approach_angle_name(angle_name: String, fallback: String = "NW") -> String:
	var normalized_name: String = angle_name.strip_edges().to_upper()
	if APPROACH_ANGLES.has(normalized_name):
		return normalized_name
	var normalized_fallback: String = fallback.strip_edges().to_upper()
	if APPROACH_ANGLES.has(normalized_fallback):
		return normalized_fallback
	return "NW"


func _coerce_vector2_value(value: Variant, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2(value)
	if typeof(value) == TYPE_DICTIONARY:
		var dict_value: Dictionary = Dictionary(value)
		return Vector2(float(dict_value.get("x", fallback.x)), float(dict_value.get("y", fallback.y)))
	if typeof(value) == TYPE_ARRAY:
		var array_value: Array = Array(value)
		if array_value.size() >= 2:
			return Vector2(float(array_value[0]), float(array_value[1]))
	return fallback


func _build_mission_dropship_lz_name(craft_id: String = "", display_name: String = "") -> String:
	var label: String = display_name.strip_edges()
	if label.is_empty():
		label = craft_id.strip_edges().replace("_", " ")
	if label.is_empty():
		label = "Dropship"
	return "LZ %s" % label


func _build_mission_drop_cards_snapshot() -> Array:
	var cards: Array = _sanitize_mission_dropship_cards(_mission_drop_cards)
	var selected_craft_id: String = _mission_drop_craft_id.strip_edges()
	if not selected_craft_id.is_empty():
		var did_merge_selected_card: bool = false
		for index in range(cards.size()):
			var card: Dictionary = Dictionary(cards[index]).duplicate(true)
			if String(card.get("craft_id", "")).strip_edges() != selected_craft_id:
				continue
			cards[index] = _write_current_mission_dropship_state_to_card(card)
			did_merge_selected_card = true
			break
		if not did_merge_selected_card:
			cards.append(_write_current_mission_dropship_state_to_card(_build_current_mission_dropship_card()))
	cards = _merge_active_drop_sequence_into_cards(cards)
	return _sanitize_mission_dropship_cards(cards)


func _store_selected_mission_dropship_plan() -> void:
	var selected_craft_id: String = _mission_drop_craft_id.strip_edges()
	if selected_craft_id.is_empty():
		return
	_mission_drop_cards = _build_mission_drop_cards_snapshot()


func _store_active_drop_sequence_card() -> void:
	if not _is_drop_sequence_active() or _drop_sequence_craft_id.strip_edges().is_empty():
		return
	_mission_drop_cards = _sanitize_mission_dropship_cards(_merge_active_drop_sequence_into_cards(_sanitize_mission_dropship_cards(_mission_drop_cards)))


func _merge_active_drop_sequence_into_cards(cards: Array) -> Array:
	var active_sequences: Array = []
	if _is_drop_sequence_active() and not _drop_sequence_craft_id.strip_edges().is_empty():
		active_sequences.append(_capture_active_drop_sequence())
	for sequence_variant in _parallel_drop_sequences_by_craft.values():
		if typeof(sequence_variant) != TYPE_DICTIONARY:
			continue
		var sequence: Dictionary = Dictionary(sequence_variant)
		if _is_drop_sequence_dict_active(sequence) and not String(sequence.get("craft_id", "")).strip_edges().is_empty():
			active_sequences.append(sequence)
	for sequence_variant in active_sequences:
		var active_card_fields: Dictionary = _build_drop_sequence_card_fields(Dictionary(sequence_variant))
		var active_craft_id: String = String(active_card_fields.get("craft_id", "")).strip_edges()
		if active_craft_id.is_empty():
			continue
		var did_merge_active_card: bool = false
		for index in range(cards.size()):
			var card: Dictionary = Dictionary(cards[index]).duplicate(true)
			if String(card.get("craft_id", "")).strip_edges() != active_craft_id:
				continue
			for key in active_card_fields.keys():
				card[key] = active_card_fields[key]
			cards[index] = card
			did_merge_active_card = true
			break
		if not did_merge_active_card:
			cards.append(active_card_fields)
	return cards


func _build_active_drop_sequence_card_fields() -> Dictionary:
	var fields: Dictionary = _build_drop_sequence_card_fields(_capture_active_drop_sequence())
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		fields["pilot_text"] = _mission_drop_pilot_text
		fields["pilot_unit_id"] = _mission_drop_pilot_unit_id
		fields["pilot_display_name"] = _mission_drop_pilot_display_name
		fields["pilot_portrait_path"] = _mission_drop_pilot_portrait_path
		fields["texture_path"] = _mission_drop_texture_path
		fields["title_text"] = _mission_drop_title_text
	return fields


func _build_drop_sequence_card_fields(sequence: Dictionary) -> Dictionary:
	var craft_id: String = String(sequence.get("craft_id", "")).strip_edges()
	var display_name: String = String(sequence.get("display_name", "Dropship")).strip_edges()
	if display_name.is_empty():
		display_name = "Dropship"
	var units: Array = Array(sequence.get("units", []))
	var embarked_unit_ids: Dictionary = Dictionary(sequence.get("embarked_unit_ids", {}))
	var passenger_ids: Array = _build_sorted_drop_unit_id_array(embarked_unit_ids)
	var fireteam_ids: Array = _sanitize_drop_payload_ids(Array(sequence.get("boarded_fireteam_ids", [])))
	if fireteam_ids.is_empty():
		var raw_card: Dictionary = _find_raw_mission_dropship_card_entry(craft_id)
		fireteam_ids = _sanitize_drop_payload_ids(Array(raw_card.get("boarded_fireteam_ids", [])))
	if fireteam_ids.is_empty():
		fireteam_ids = _build_fireteam_ids_for_drop_units(units)
	var lz_position: Vector2 = _coerce_vector2_value(sequence.get("lz_position", Vector2.ZERO), Vector2.ZERO)
	var approach_angle: String = _sanitize_approach_angle_name(String(sequence.get("approach_angle", "NW")))
	var lz_label: String = _build_mission_dropship_lz_name(craft_id, display_name)
	var position: Vector2 = _coerce_vector2_value(sequence.get("position", Vector2.ZERO), Vector2.ZERO)
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": String(sequence.get("phase", "")).strip_edges().to_lower(),
		"progress": _build_drop_sequence_progress_value(sequence),
		"eta_seconds": _mission_drop_eta_seconds,
		"passenger_count": passenger_ids.size(),
		"embarked_unit_ids": passenger_ids,
		"boarded_fireteam_ids": fireteam_ids,
		"has_lz_position": true,
		"lz_position": lz_position,
		"lz_label": lz_label,
		"lz_name": lz_label,
		"approach_angle": approach_angle,
		"drop_ship_requested": String(sequence.get("phase", "")).strip_edges().to_lower() != DROP_SEQUENCE_OUTBOUND,
		"drop_ship_staged": true,
		"drop_sequence_position": position,
		"dropship_position": position,
		"card_feedback_text": String(sequence.get("card_feedback_text", "")).strip_edges(),
	}


func _update_mission_dropship_card_fields(craft_id: String, fields: Dictionary) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	var cards: Array = _sanitize_mission_dropship_cards(_mission_drop_cards)
	var did_update: bool = false
	for index in range(cards.size()):
		var card: Dictionary = Dictionary(cards[index]).duplicate(true)
		if String(card.get("craft_id", "")).strip_edges() != normalized_craft_id:
			continue
		for key in fields.keys():
			card[key] = fields[key]
		cards[index] = card
		did_update = true
		break
	if not did_update:
		var new_card: Dictionary = fields.duplicate(true)
		new_card["craft_id"] = normalized_craft_id
		cards.append(new_card)
	_mission_drop_cards = _sanitize_mission_dropship_cards(cards)


func _write_current_mission_dropship_state_to_card(card: Dictionary) -> Dictionary:
	var result: Dictionary = card.duplicate(true)
	result["craft_id"] = _mission_drop_craft_id if not _mission_drop_craft_id.is_empty() else String(result.get("craft_id", "mission_drop_sequence")).strip_edges()
	if not _mission_drop_display_name.is_empty():
		result["display_name"] = _mission_drop_display_name
	if not _mission_drop_title_text.is_empty():
		result["title_text"] = _mission_drop_title_text
	if not _mission_drop_texture_path.is_empty():
		result["texture_path"] = _mission_drop_texture_path
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		result["state"] = _drop_sequence_phase
	elif not _mission_drop_state.is_empty():
		result["state"] = _mission_drop_state
	if not _mission_drop_pilot_text.is_empty():
		result["pilot_text"] = _mission_drop_pilot_text
	if not _mission_drop_status_line.is_empty():
		result["status_line"] = _mission_drop_status_line
	result["progress"] = _build_active_drop_sequence_progress_value() if _is_active_drop_sequence_for_craft(_mission_drop_craft_id) else _mission_drop_progress
	result["eta_seconds"] = _mission_drop_eta_seconds
	result["pilot_unit_id"] = _mission_drop_pilot_unit_id
	result["pilot_display_name"] = _mission_drop_pilot_display_name
	result["pilot_portrait_path"] = _mission_drop_pilot_portrait_path
	var passenger_ids: Array = _build_sorted_drop_unit_id_array(_embarked_unit_ids)
	if passenger_ids.is_empty():
		var existing_passenger_ids: Array = _sanitize_drop_payload_ids(Array(result.get("embarked_unit_ids", [])))
		if not existing_passenger_ids.is_empty():
			passenger_ids = existing_passenger_ids
	result["passenger_count"] = _mission_drop_passenger_count if _mission_drop_passenger_count > 0 else passenger_ids.size()
	result["embarked_unit_ids"] = passenger_ids
	var boarded_fireteam_ids: Array = _sanitize_drop_payload_ids(Array(result.get("boarded_fireteam_ids", [])))
	if boarded_fireteam_ids.is_empty():
		boarded_fireteam_ids = _build_fireteam_ids_for_unit_ids(passenger_ids)
	if not boarded_fireteam_ids.is_empty():
		result["boarded_fireteam_ids"] = boarded_fireteam_ids
	result["has_lz_position"] = _has_lz_position
	result["lz_position"] = _lz_position
	if _has_lz_position:
		var lz_label: String = _build_mission_dropship_lz_name(String(result.get("craft_id", "")), String(result.get("display_name", "")))
		result["lz_label"] = lz_label
		result["lz_name"] = lz_label
	else:
		result.erase("lz_label")
		result.erase("lz_name")
	result["approach_angle"] = _get_approach_angle_name()
	result["drop_ship_requested"] = _drop_ship_requested
	result["drop_ship_staged"] = _drop_ship_staged
	return result


func _sanitize_drop_payload_ids(source_ids: Array) -> Array:
	var result: Array = []
	var seen_ids: Dictionary = {}
	for id_variant in source_ids:
		var normalized_id: String = String(id_variant).strip_edges()
		if normalized_id.is_empty() or seen_ids.has(normalized_id):
			continue
		seen_ids[normalized_id] = true
		result.append(normalized_id)
	return result


func _build_current_mission_dropship_card() -> Dictionary:
	return _sanitize_mission_dropship_card(
		{
			"craft_id": _mission_drop_craft_id if not _mission_drop_craft_id.is_empty() else "mission_drop_sequence",
			"display_name": _mission_drop_display_name if not _mission_drop_display_name.is_empty() else "Dropship",
			"title_text": _mission_drop_title_text,
			"texture_path": _mission_drop_texture_path,
			"state": _drop_sequence_phase if _is_active_drop_sequence_for_craft(_mission_drop_craft_id) else _mission_drop_state,
			"pilot_text": _mission_drop_pilot_text,
			"status_line": _mission_drop_status_line,
			"progress": _build_mission_dropship_progress_value(),
			"eta_seconds": _mission_drop_eta_seconds,
			"pilot_unit_id": _mission_drop_pilot_unit_id,
			"pilot_display_name": _mission_drop_pilot_display_name,
			"pilot_portrait_path": _mission_drop_pilot_portrait_path,
			"passenger_count": _mission_drop_passenger_count if _mission_drop_passenger_count > 0 else _embarked_unit_ids.size(),
		}
	)


func _get_mission_dropship_card_entries() -> Array:
	var entries: Array = _sanitize_mission_dropship_cards(_mission_drop_cards)
	var selected_craft_id: String = _mission_drop_craft_id.strip_edges()
	if not selected_craft_id.is_empty():
		var did_merge_selected_card: bool = false
		for index in range(entries.size()):
			var card: Dictionary = Dictionary(entries[index]).duplicate(true)
			if String(card.get("craft_id", "")).strip_edges() != selected_craft_id:
				continue
			entries[index] = _write_current_mission_dropship_state_to_card(card)
			did_merge_selected_card = true
			break
		if not did_merge_selected_card:
			entries.append(_write_current_mission_dropship_state_to_card(_build_current_mission_dropship_card()))
	if entries.is_empty() and (not _mission_drop_craft_id.is_empty() or _is_drop_sequence_active()):
		entries.append(_build_current_mission_dropship_card())
	entries = _merge_active_drop_sequence_into_cards(entries)
	return _sanitize_mission_dropship_cards(entries)


func _find_mission_dropship_card_entry(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return {}
	for card_variant in _get_mission_dropship_card_entries():
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return card
	return {}


func _find_raw_mission_dropship_card_entry(craft_id: String) -> Dictionary:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return {}
	for card_variant in _mission_drop_cards:
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")).strip_edges() == normalized_craft_id:
			return card.duplicate(true)
	return {}


func _sync_selected_mission_dropship_payload_presence_from_card() -> void:
	var selected_card: Dictionary = _find_raw_mission_dropship_card_entry(_mission_drop_craft_id)
	if selected_card.is_empty() or not bool(selected_card.get("has_embarked_payload", false)):
		return
	var payload_ids: Array = _sanitize_drop_payload_ids(Array(selected_card.get("embarked_unit_ids", [])))
	var active_payload_ids: Array = []
	for unit_id_variant in payload_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or _deployed_unit_ids.has(unit_id):
			continue
		active_payload_ids.append(unit_id)
	_embarked_unit_ids = _build_drop_unit_state_dict(active_payload_ids)
	if active_payload_ids.is_empty():
		_mission_drop_passenger_count = 0
	else:
		_mission_drop_passenger_count = maxi(_mission_drop_passenger_count, active_payload_ids.size())


func select_mission_dropship_craft(craft_id: String) -> bool:
	return _select_mission_dropship_craft(craft_id, true)


func _select_mission_dropship_craft(craft_id: String, should_emit_signal: bool = true) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	var current_craft_id: String = _mission_drop_craft_id.strip_edges()
	if _is_drop_sequence_active() and normalized_craft_id != current_craft_id:
		if _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
			_store_primary_drop_sequence_as_parallel()
		else:
			_store_active_drop_sequence_card()
	_store_selected_mission_dropship_plan()
	var selected_card: Dictionary = _find_mission_dropship_card_entry(normalized_craft_id)
	if selected_card.is_empty():
		return false
	_apply_mission_dropship_card_selection(selected_card)
	if not _is_drop_sequence_active():
		_drop_ship_requested = false
	_last_command_text = "DROPSHIP SELECTED: %s" % _mission_drop_display_name
	_refresh_button_state()
	_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()
	return true


func _apply_mission_dropship_card_selection(card: Dictionary) -> void:
	_mission_drop_craft_id = String(card.get("craft_id", "")).strip_edges()
	_mission_drop_display_name = String(card.get("display_name", "Dropship")).strip_edges()
	_mission_drop_title_text = String(card.get("title_text", _mission_drop_display_name)).strip_edges()
	_mission_drop_texture_path = String(card.get("texture_path", "")).strip_edges()
	_mission_drop_state = String(card.get("state", "")).strip_edges().to_lower()
	_mission_drop_pilot_text = String(card.get("pilot_text", "")).strip_edges()
	_mission_drop_status_line = String(card.get("status_line", "")).strip_edges()
	_mission_drop_progress = clampf(float(card.get("progress", 0.0)), 0.0, 100.0)
	_mission_drop_eta_seconds = maxi(int(card.get("eta_seconds", 0)), 0)
	_mission_drop_pilot_unit_id = String(card.get("pilot_unit_id", "")).strip_edges()
	_mission_drop_pilot_display_name = String(card.get("pilot_display_name", "")).strip_edges()
	_mission_drop_pilot_portrait_path = String(card.get("pilot_portrait_path", "")).strip_edges()
	_mission_drop_passenger_count = maxi(int(card.get("passenger_count", 0)), 0)
	var card_count: int = _get_mission_dropship_card_entries().size()
	if card.has("approach_angle"):
		var angle_index: int = APPROACH_ANGLES.find(_sanitize_approach_angle_name(String(card.get("approach_angle", _get_approach_angle_name()))))
		if angle_index >= 0:
			_current_approach_index = angle_index
	elif card_count > 1:
		_current_approach_index = APPROACH_ANGLES.find("NW")
	if card.has("has_lz_position"):
		_has_lz_position = bool(card.get("has_lz_position", false))
		_lz_position = _coerce_vector2_value(card.get("lz_position", Vector2.ZERO), Vector2.ZERO)
	elif card_count > 1:
		_has_lz_position = false
		_lz_position = Vector2.ZERO
	if card.has("drop_ship_requested"):
		_drop_ship_requested = bool(card.get("drop_ship_requested", false))
	elif card_count > 1:
		_drop_ship_requested = false
	if card.has("drop_ship_staged"):
		_drop_ship_staged = bool(card.get("drop_ship_staged", false))
	elif card_count > 1:
		_drop_ship_staged = false
	if bool(card.get("has_embarked_payload", false)):
		var payload_ids: Array = _sanitize_drop_payload_ids(Array(card.get("embarked_unit_ids", [])))
		var active_payload_ids: Array = []
		for unit_id_variant in payload_ids:
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty() or _deployed_unit_ids.has(unit_id):
				continue
			active_payload_ids.append(unit_id)
		_embarked_unit_ids = _build_drop_unit_state_dict(active_payload_ids)
		if active_payload_ids.is_empty():
			_mission_drop_passenger_count = 0
		else:
			_mission_drop_passenger_count = maxi(_mission_drop_passenger_count, active_payload_ids.size())


func _extract_mission_dropship_card_fireteam_ids(card: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for source_key in ["boarded_fireteam_ids", "queued_fireteam_ids"]:
		for fireteam_id_variant in Array(card.get(source_key, [])):
			var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
			if fireteam_id.is_empty() or result.has(fireteam_id):
				continue
			result.append(fireteam_id)
	for fireteam_id_variant in _build_fireteam_ids_for_unit_ids(_sanitize_drop_payload_ids(Array(card.get("embarked_unit_ids", [])))):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	return result


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
	var panel := tactical_ui.get_node_or_null("MissionDropshipPanel") as Control
	if panel != null:
		return
	panel = VBoxContainer.new()
	panel.name = "MissionDropshipPanel"
	panel.visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = false
	panel.add_theme_constant_override("separation", int(MISSION_DROPSHIP_PANEL_STACK_GAP))
	_enforce_mission_dropship_panel_geometry(panel)
	tactical_ui.add_child(panel)
	_set_control_tree_mouse_filter(panel, Control.MOUSE_FILTER_IGNORE)


func _refresh_mission_dropship_panel() -> void:
	var panel := get_node_or_null("../TacticalUI/MissionDropshipPanel") as Control
	if panel == null:
		return
	_enforce_mission_dropship_panel_geometry(panel)
	var card_entries: Array = _get_mission_dropship_card_entries()
	var show_panel: bool = _tactical_ui_visible and not card_entries.is_empty()
	if not show_panel:
		panel.visible = false
		return
	panel.visible = false
	_clear_mission_dropship_panel_cards(panel)
	for card_variant in card_entries:
		var card: Dictionary = Dictionary(card_variant)
		var is_transit: bool = _is_mission_dropship_card_in_transit(card)
		var craft_id: String = String(card.get("craft_id", "")).strip_edges()
		var is_selected: bool = not craft_id.is_empty() and craft_id == _mission_drop_craft_id.strip_edges()
		var ship_texture := _get_mission_dropship_texture(card)
		var card_panel := PanelContainer.new()
		card_panel.name = "MissionDropshipCard_%s" % _sanitize_node_name(craft_id)
		card_panel.custom_minimum_size = MISSION_DROPSHIP_PANEL_SIZE
		card_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
		card_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		card_panel.focus_mode = Control.FOCUS_ALL
		card_panel.set_meta("mission_dropship_card", true)
		card_panel.set_meta("mission_dropship_craft_id", craft_id)
		card_panel.set_meta("mission_dropship_selected", is_selected)
		card_panel.set_meta("mission_dropship_card_inaccessible", is_transit)
		card_panel.set_meta("mission_dropship_card_accessible", not is_transit)
		card_panel.tooltip_text = "Select %s for Mission Control" % String(card.get("display_name", "Dropship")).strip_edges()
		if not card_panel.gui_input.is_connected(_on_mission_dropship_card_gui_input.bind(craft_id)):
			card_panel.gui_input.connect(_on_mission_dropship_card_gui_input.bind(craft_id))
		panel.add_child(card_panel)
		TRANSPORT_CRAFT_CARD_UI_SCRIPT.ensure_card_structure(card_panel)
		TRANSPORT_CRAFT_CARD_UI_SCRIPT.apply_card_state(
			card_panel,
			{
				"selected": is_selected,
				"in_transit": is_transit,
				"can_stage": false,
				"title_text": _build_mission_dropship_title_text(card),
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
				"pilot_profile": _build_mission_dropship_pilot_profile(card),
				"pilot_text": _build_mission_dropship_pilot_text(card),
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
					_build_mission_dropship_passenger_text(card),
					_build_mission_dropship_status_text(card),
				],
				"info_line_font_size": MISSION_DROPSHIP_INFO_FONT_SIZE,
				"progress_bar_height": 4.0,
				"progress_visible": _should_show_mission_dropship_card_progress(card),
				"progress_value": _build_mission_dropship_progress_value(card),
				"primary_action": {
					"visible": _can_request_mission_dropship_return(card),
					"text": "FOB",
					"tooltip_text": "Return this dropship to FOB.",
					"disabled": not _can_request_mission_dropship_return(card),
					"square_size": 42.0,
					"ready_style": true,
					"callback": Callable(self, "_on_mission_dropship_return_pressed").bind(craft_id),
				},
				"secondary_action": {
					"visible": false,
				},
				"clear_extra_content": true,
			}
		)
		_populate_mission_dropship_passenger_content(card_panel, card)
		_set_control_tree_mouse_filter(card_panel, Control.MOUSE_FILTER_IGNORE)
		card_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_restore_mission_dropship_action_button_mouse_filters(card_panel)
	_enforce_mission_dropship_panel_geometry(panel)
	panel.visible = true
	call_deferred("_deferred_enforce_mission_dropship_panel_geometry")


func _populate_mission_dropship_passenger_content(card_panel: PanelContainer, card: Dictionary) -> void:
	if card_panel == null:
		return
	var host: VBoxContainer = TRANSPORT_CRAFT_CARD_UI_SCRIPT.get_extra_content_host(card_panel)
	if host == null:
		return
	var payload_ids: Array = _sanitize_drop_payload_ids(Array(card.get("embarked_unit_ids", [])))
	host.set_meta("mission_dropship_passenger_content", true)
	_append_mission_dropship_card_command_row(host, card)
	var feedback_text: String = _get_mission_dropship_card_feedback_text(card)
	if not feedback_text.is_empty():
		var feedback_label := Label.new()
		feedback_label.name = "MissionDropshipCardFeedbackLabel"
		feedback_label.text = feedback_text
		feedback_label.add_theme_font_size_override("font_size", 9)
		feedback_label.set_meta("mission_dropship_card_feedback_text", feedback_text)
		META_UI_SKIN_SCRIPT.style_body_label(feedback_label, 9)
		host.add_child(feedback_label)
	if payload_ids.is_empty():
		if feedback_text == "Trupp ab":
			for fireteam_id_variant in _sanitize_drop_payload_ids(Array(card.get("boarded_fireteam_ids", []))):
				var deployed_fireteam_card := _build_mission_dropship_fireteam_payload_card(String(fireteam_id_variant), [], card)
				if deployed_fireteam_card != null:
					host.add_child(deployed_fireteam_card)
			if host.get_child_count() > 1:
				return
		var empty_label := Label.new()
		empty_label.name = "PassengerEmptyLabel"
		empty_label.text = "Passengers: none"
		empty_label.add_theme_font_size_override("font_size", 8)
		META_UI_SKIN_SCRIPT.style_body_label(empty_label, 8)
		host.add_child(empty_label)
		return
	var grouped_payload: Dictionary = _group_payload_unit_ids_by_fireteam(payload_ids)
	for fireteam_id_variant in grouped_payload.keys():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		var group_ids: Array = Array(grouped_payload.get(fireteam_id, []))
		var fireteam_card := _build_mission_dropship_fireteam_payload_card(fireteam_id, group_ids, card)
		if fireteam_card != null:
			host.add_child(fireteam_card)


func _append_mission_dropship_card_command_row(host: VBoxContainer, card: Dictionary) -> void:
	if host == null:
		return
	var craft_id: String = String(card.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return
	var row := HBoxContainer.new()
	row.name = "MissionDropshipCardCommandRow"
	row.add_theme_constant_override("separation", 2)
	row.set_meta("mission_dropship_card_command_row", true)
	row.set_meta("mission_dropship_craft_id", craft_id)
	host.add_child(row)

	var lz_button := _build_mission_dropship_card_command_button(
		"LZ",
		"Set landing zone for this dropship.",
		not _can_request_mission_dropship_card_lz(card),
		Callable(self, "_on_mission_dropship_card_set_lz_pressed").bind(craft_id),
		craft_id,
		"set_lz"
	)
	row.add_child(lz_button)
	for approach_angle in APPROACH_ANGLES:
		row.add_child(
			_build_mission_dropship_card_command_button(
				String(approach_angle),
				"Set %s approach for this dropship." % String(approach_angle),
				not _can_request_mission_dropship_card_lz(card),
				Callable(self, "_on_mission_dropship_card_approach_pressed").bind(craft_id, String(approach_angle)),
				craft_id,
				"approach_%s" % String(approach_angle).to_lower()
			)
		)
	var drop_button := _build_mission_dropship_card_command_button(
		_build_mission_dropship_card_drop_button_label(card),
		"Drop this dropship payload at its own LZ.",
		not _can_request_mission_dropship_card_drop(card),
		Callable(self, "_on_mission_dropship_card_drop_pressed").bind(craft_id),
		craft_id,
		"drop"
	)
	row.add_child(drop_button)


func _build_mission_dropship_card_command_button(text: String, tooltip_text: String, disabled: bool, callback: Callable, craft_id: String, action_id: String) -> Button:
	var button := Button.new()
	button.name = "MissionDropshipCardCommand_%s_%s" % [_sanitize_node_name(craft_id), _sanitize_node_name(action_id)]
	button.text = text
	button.tooltip_text = tooltip_text
	button.disabled = disabled
	button.custom_minimum_size = Vector2(27.0, 18.0)
	button.add_theme_font_size_override("font_size", 7)
	button.set_meta("mission_dropship_card_command_button", true)
	button.set_meta("mission_dropship_craft_id", craft_id)
	button.set_meta("mission_dropship_card_command", action_id)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	if callback.is_valid() and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if not disabled and action_id == "drop":
		META_UI_SKIN_SCRIPT.style_transfer_button(button, true)
	else:
		META_UI_SKIN_SCRIPT.style_secondary_button(button)
	return button


func _group_payload_unit_ids_by_fireteam(payload_ids: Array) -> Dictionary:
	var grouped_payload: Dictionary = {}
	for unit_id_variant in payload_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var fireteam_id: String = "unassigned"
		var unit := _find_friendly_unit_by_id(unit_id)
		if unit != null and unit.has_method("get_fireteam_id"):
			fireteam_id = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty():
			fireteam_id = "unassigned"
		if not grouped_payload.has(fireteam_id):
			grouped_payload[fireteam_id] = []
		grouped_payload[fireteam_id].append(unit_id)
	return grouped_payload


func _build_mission_dropship_fireteam_payload_card(fireteam_id: String, group_ids: Array, card: Dictionary) -> Control:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		normalized_fireteam_id = "unassigned"
	var panel := PanelContainer.new()
	panel.name = "PassengerGroup_%s" % _sanitize_node_name(normalized_fireteam_id)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("mission_dropship_fireteam_payload_card", true)
	panel.set_meta("mission_dropship_fireteam_id", normalized_fireteam_id)
	panel.set_meta("mission_dropship_payload_unit_ids", _sanitize_drop_payload_ids(group_ids))
	panel.set_meta("mission_dropship_deboard_progress", _build_mission_dropship_fireteam_deboard_progress_value(card, group_ids))
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "PassengerFireteamVBox"
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	var header := Label.new()
	header.name = "PassengerGroupLabel"
	if group_ids.is_empty() and _get_mission_dropship_card_feedback_text(card) == "Trupp ab":
		header.text = "%s | deployed" % _get_fireteam_display_label(normalized_fireteam_id)
	else:
		header.text = "%s | %d passengers" % [_get_fireteam_display_label(normalized_fireteam_id), group_ids.size()]
	header.add_theme_font_size_override("font_size", 8)
	header.clip_text = true
	header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	META_UI_SKIN_SCRIPT.style_body_label(header, 8)
	vbox.add_child(header)

	var portrait_row := HBoxContainer.new()
	portrait_row.name = "PassengerPortraitRow"
	portrait_row.add_theme_constant_override("separation", 2)
	portrait_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	portrait_row.set_meta("mission_dropship_payload_portrait_row", true)
	vbox.add_child(portrait_row)
	for unit_id_variant in group_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		var chip := _build_mission_dropship_passenger_portrait_chip(unit_id)
		if chip != null:
			portrait_row.add_child(chip)

	var progress_value: float = _build_mission_dropship_fireteam_deboard_progress_value(card, group_ids)
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	if state == DROP_SEQUENCE_UNLOADING or progress_value >= 100.0:
		var progress_bar := ProgressBar.new()
		progress_bar.name = "PassengerDeboardProgress"
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = progress_value
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size = Vector2(0.0, 5.0)
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.set_meta("mission_dropship_deboard_progress", progress_value)
		vbox.add_child(progress_bar)

	var feedback_text: String = _get_mission_dropship_card_feedback_text(card)
	if feedback_text == "Trupp ab":
		var feedback_label := Label.new()
		feedback_label.name = "PassengerFireteamFeedbackLabel"
		feedback_label.text = feedback_text
		feedback_label.add_theme_font_size_override("font_size", 8)
		feedback_label.set_meta("mission_dropship_fireteam_feedback_text", feedback_text)
		META_UI_SKIN_SCRIPT.style_body_label(feedback_label, 8)
		vbox.add_child(feedback_label)
	return panel


func _build_mission_dropship_passenger_portrait_chip(unit_id: String) -> Control:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return null
	var unit := _find_friendly_unit_by_id(normalized_unit_id)
	var display_name: String = normalized_unit_id
	var portrait_path: String = ""
	if unit != null:
		if unit.has_method("get_display_name"):
			display_name = String(unit.call("get_display_name")).strip_edges()
		if unit.has_method("get_portrait_path"):
			portrait_path = String(unit.call("get_portrait_path")).strip_edges()
	if display_name.is_empty():
		display_name = normalized_unit_id
	var chip := VBoxContainer.new()
	chip.name = "PassengerPortrait_%s" % _sanitize_node_name(normalized_unit_id)
	chip.custom_minimum_size = Vector2(34.0, 42.0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.set_meta("mission_dropship_passenger_unit_id", normalized_unit_id)
	chip.set_meta("mission_dropship_passenger_portrait_chip", true)

	var portrait_rect := TextureRect.new()
	portrait_rect.name = "PassengerPortraitRect"
	portrait_rect.custom_minimum_size = Vector2(30.0, 30.0)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait_rect.texture = _load_portrait_texture(portrait_path)
	portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if portrait_rect.texture != null else Color(0.35, 0.37, 0.42, 1.0)
	portrait_rect.set_meta("mission_dropship_passenger_portrait", true)
	chip.add_child(portrait_rect)

	var name_label := Label.new()
	name_label.name = "PassengerPortraitName"
	name_label.text = display_name
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 7)
	META_UI_SKIN_SCRIPT.style_body_label(name_label, 7)
	chip.add_child(name_label)
	return chip


func _build_mission_dropship_fireteam_deboard_progress_value(card: Dictionary, group_ids: Array) -> float:
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	if state == DROP_SEQUENCE_UNLOADING:
		return clampf(float(card.get("progress", 0.0)), 0.0, 100.0)
	if state == DROP_SEQUENCE_COMPLETE or state == DROP_SEQUENCE_OUTBOUND or state == "to_fob" or state == "to_homebase":
		return 100.0 if group_ids.is_empty() else clampf(float(card.get("progress", 100.0)), 0.0, 100.0)
	return 0.0


func _build_mission_dropship_passenger_chip(unit_id: String) -> Control:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return null
	var unit := _find_friendly_unit_by_id(normalized_unit_id)
	var display_name: String = normalized_unit_id
	var callsign: String = ""
	if unit != null:
		if unit.has_method("get_display_name"):
			display_name = String(unit.call("get_display_name")).strip_edges()
		if unit.has_method("get_callsign"):
			callsign = String(unit.call("get_callsign")).strip_edges()
	if display_name.is_empty():
		display_name = normalized_unit_id
	var chip := PanelContainer.new()
	chip.name = "PassengerChip_%s" % _sanitize_node_name(normalized_unit_id)
	chip.custom_minimum_size = Vector2(136.0, 20.0)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.set_meta("mission_dropship_passenger_unit_id", normalized_unit_id)
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.08, 0.11, 0.13, 0.86)
	stylebox.border_color = Color(0.37, 0.75, 0.92, 0.82)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 3
	stylebox.corner_radius_top_right = 3
	stylebox.corner_radius_bottom_left = 3
	stylebox.corner_radius_bottom_right = 3
	chip.add_theme_stylebox_override("panel", stylebox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 1)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 1)
	chip.add_child(margin)

	var label := Label.new()
	label.name = "PassengerNameLabel"
	label.text = display_name if callsign.is_empty() else "%s | %s" % [display_name, callsign]
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", 8)
	META_UI_SKIN_SCRIPT.style_body_label(label, 8)
	margin.add_child(label)
	return chip


func _can_request_mission_dropship_return(card: Dictionary) -> bool:
	var craft_id: String = String(card.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return false
	if _has_live_drop_sequence_for_craft(craft_id):
		return false
	return String(card.get("state", "")).strip_edges().to_lower() == "waiting"


func _can_request_mission_dropship_card_lz(card: Dictionary) -> bool:
	var craft_id: String = String(card.get("craft_id", "")).strip_edges()
	if craft_id.is_empty() or _is_mission_dropship_card_in_transit(card):
		return false
	if _has_live_drop_sequence_for_craft(craft_id):
		return false
	return String(card.get("state", "")).strip_edges().to_lower() == "waiting"


func _can_request_mission_dropship_card_drop(card: Dictionary) -> bool:
	if not _can_request_mission_dropship_card_lz(card):
		return false
	if not bool(card.get("has_lz_position", false)):
		return false
	if Array(card.get("embarked_unit_ids", [])).is_empty() and int(card.get("passenger_count", 0)) <= 0:
		return false
	return true


func _build_mission_dropship_card_drop_button_label(card: Dictionary) -> String:
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	match state:
		DROP_SEQUENCE_INBOUND:
			return "In"
		DROP_SEQUENCE_LANDED:
			return "TD"
		DROP_SEQUENCE_UNLOADING:
			return "Out"
		DROP_SEQUENCE_OUTBOUND:
			return "RTB"
		DROP_SEQUENCE_COMPLETE:
			return "Done"
		_:
			return "Drop"


func _restore_mission_dropship_action_button_mouse_filters(card_panel: PanelContainer) -> void:
	if card_panel == null:
		return
	for button_path in [
		"MarginContainer/VBox/HeaderRow/PrimaryActionButton",
		"MarginContainer/VBox/HeaderRow/SecondaryActionButton",
	]:
		var button := card_panel.get_node_or_null(button_path) as Button
		if button == null or not button.visible:
			continue
		button.mouse_filter = Control.MOUSE_FILTER_STOP
	for node in _collect_node_tree(card_panel):
		var command_button := node as Button
		if command_button != null and bool(command_button.get_meta("mission_dropship_card_command_button", false)):
			command_button.mouse_filter = Control.MOUSE_FILTER_STOP


func _collect_node_tree(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_node_tree(child))
	return result


func _ensure_mission_control_craft_summary() -> PanelContainer:
	var action_row := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow") as HBoxContainer
	if action_row == null:
		return null
	var existing_panel := action_row.get_node_or_null("MissionCraftSummary") as PanelContainer
	if existing_panel != null:
		return existing_panel
	var panel := PanelContainer.new()
	panel.name = "MissionCraftSummary"
	panel.custom_minimum_size = Vector2(126.0, 48.0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("mission_control_selected_craft_summary", true)
	META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "thin_frame")
	action_row.add_child(panel)
	var drop_button := action_row.get_node_or_null("CallDropshipButton") as Button
	if drop_button != null:
		action_row.move_child(panel, drop_button.get_index() + 1)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", 4)
	margin.add_child(row)

	var ship_texture := TextureRect.new()
	ship_texture.name = "ShipTexture"
	ship_texture.custom_minimum_size = Vector2(36.0, 28.0)
	ship_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ship_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(ship_texture)

	var info := VBoxContainer.new()
	info.name = "Info"
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	for label_name in ["NameLabel", "PilotLabel", "PlanLabel"]:
		var label := Label.new()
		label.name = label_name
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size", 7 if label_name != "NameLabel" else 8)
		META_UI_SKIN_SCRIPT.style_body_label(label, 7 if label_name != "NameLabel" else 8)
		info.add_child(label)
	return panel


func _refresh_mission_control_craft_summary() -> void:
	var panel := _ensure_mission_control_craft_summary()
	if panel == null:
		return
	var selected_craft_id: String = _mission_drop_craft_id.strip_edges()
	panel.visible = not selected_craft_id.is_empty() or not _mission_drop_display_name.is_empty()
	panel.set_meta("mission_drop_craft_id", selected_craft_id)
	if not panel.visible:
		return
	var selected_card: Dictionary = _find_mission_dropship_card_entry(selected_craft_id)
	var ship_texture := panel.get_node_or_null("Margin/Row/ShipTexture") as TextureRect
	if ship_texture != null:
		ship_texture.texture = _get_mission_dropship_texture(selected_card)
	var name_label := panel.get_node_or_null("Margin/Row/Info/NameLabel") as Label
	if name_label != null:
		name_label.text = _mission_drop_display_name if not _mission_drop_display_name.is_empty() else String(selected_card.get("display_name", "Dropship")).strip_edges()
	var pilot_name: String = _mission_drop_pilot_display_name
	if pilot_name.is_empty():
		pilot_name = String(selected_card.get("pilot_display_name", "")).strip_edges()
	if pilot_name.is_empty():
		pilot_name = "Pilot: none"
	var pilot_label := panel.get_node_or_null("Margin/Row/Info/PilotLabel") as Label
	if pilot_label != null:
		pilot_label.text = pilot_name
	var plan_label := panel.get_node_or_null("Margin/Row/Info/PlanLabel") as Label
	if plan_label != null:
		plan_label.text = "%s | %s" % [_get_approach_angle_name(), "LZ OK" if _has_lz_position else "LZ offen"]


func _on_mission_dropship_card_gui_input(event: InputEvent, craft_id: String) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _select_mission_dropship_craft(craft_id, true):
				get_viewport().set_input_as_handled()
			return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
			if _select_mission_dropship_craft(craft_id, true):
				get_viewport().set_input_as_handled()


func _on_mission_dropship_card_set_lz_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	if not _select_mission_dropship_craft(normalized_craft_id, false):
		return
	if not _can_edit_planning():
		_last_command_text = "OBSERVER MODE"
		_update_ui()
		return
	_is_lz_placement_armed = true
	_lz_placement_craft_id = normalized_craft_id
	_last_command_text = "CLICK MAP FOR LZ TILE: %s" % _mission_drop_display_name
	_refresh_button_state()
	_update_ui()


func _on_mission_dropship_card_approach_pressed(craft_id: String, angle_name: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	if not _select_mission_dropship_craft(normalized_craft_id, false):
		return
	_select_approach_angle(angle_name)


func _on_mission_dropship_card_drop_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	if not _select_mission_dropship_craft(normalized_craft_id, false):
		return
	_request_selected_mission_dropship_drop(true)


func _on_mission_dropship_return_pressed(craft_id: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	var selected_card: Dictionary = _find_mission_dropship_card_entry(normalized_craft_id)
	if selected_card.is_empty() or not _can_request_mission_dropship_return(selected_card):
		return
	_select_mission_dropship_craft(normalized_craft_id, false)
	_drop_ship_requested = false
	_drop_ship_staged = false
	_mission_drop_state = "to_fob"
	_mission_drop_progress = 0.0
	_mission_drop_eta_seconds = 0
	_mission_drop_return_requested = true
	_last_command_text = "%s RTB FOB" % _mission_drop_display_name
	_store_selected_mission_dropship_plan()
	_emit_planning_state_changed()
	_refresh_button_state()
	_update_ui()
	_refresh_world_overlays()


func _clear_mission_dropship_panel_cards(panel: Control) -> void:
	for child in panel.get_children():
		panel.remove_child(child)
		child.queue_free()


func _sanitize_node_name(value: String) -> String:
	var safe_name: String = value.strip_edges()
	if safe_name.is_empty():
		return "dropship"
	for token in [" ", "/", "\\", ":", "|", ".", ","]:
		safe_name = safe_name.replace(token, "_")
	return safe_name


func _is_mission_dropship_card_in_transit(card: Dictionary) -> bool:
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	return state == "to_mission" or state == "to_fob" or state == "to_homebase" or state == DROP_SEQUENCE_OUTBOUND


func _should_show_mission_dropship_card_progress(card: Dictionary) -> bool:
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	return state == "to_mission" or state == "to_fob" or state == "to_homebase" or state == DROP_SEQUENCE_UNLOADING or state == DROP_SEQUENCE_OUTBOUND


func _get_mission_dropship_card_feedback_text(card: Dictionary) -> String:
	return String(card.get("card_feedback_text", "")).strip_edges()


func _refresh_legacy_mission_dropship_panel() -> void:
	var panel := get_node_or_null("../TacticalUI/MissionDropshipPanel") as PanelContainer
	if panel == null:
		return
	var is_transit: bool = _mission_drop_state == "to_mission" or _mission_drop_state == "to_fob" or _mission_drop_state == "to_homebase" or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND
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
			"progress_visible": is_transit or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING,
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


func _enforce_mission_dropship_panel_geometry(panel: Control) -> void:
	if panel == null:
		return
	var viewport := get_viewport()
	var viewport_size: Vector2 = viewport.get_visible_rect().size if viewport != null else Vector2(1920.0, 1080.0)
	var card_count: int = maxi(_get_mission_dropship_card_entries().size(), 1)
	var panel_size := Vector2(
		MISSION_DROPSHIP_PANEL_SIZE.x,
		MISSION_DROPSHIP_PANEL_SIZE.y * float(card_count) + MISSION_DROPSHIP_PANEL_STACK_GAP * float(card_count - 1)
	)
	var panel_position := Vector2(
		maxf(viewport_size.x - panel_size.x - MISSION_DROPSHIP_PANEL_MARGIN_RIGHT, 0.0),
		_get_mission_dropship_panel_top_offset()
	)
	panel.top_level = true
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.position = panel_position
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	panel.offset_left = panel_position.x
	panel.offset_top = panel_position.y
	panel.offset_right = panel_position.x + panel_size.x
	panel.offset_bottom = panel_position.y + panel_size.y
	panel.clip_contents = false
	panel.set_deferred("position", panel_position)
	panel.set_deferred("size", panel_size)


func _deferred_enforce_mission_dropship_panel_geometry() -> void:
	var panel := get_node_or_null("../TacticalUI/MissionDropshipPanel") as Control
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


func _build_mission_dropship_title_text(card: Dictionary = {}) -> String:
	var air_status: Dictionary = get_air_asset_status_snapshot()
	var air_state: String = str(air_status.get("state", "intact")).strip_edges().to_lower()
	var air_suffix: String = ""
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", air_state)):
		air_suffix = "LOST"
	elif air_state == "damaged" or air_state == "hit":
		air_suffix = "DAMAGED"
	elif bool(AIR_ASSET_STATUS_SCRIPT.call("is_warning_state", air_state)):
		air_suffix = "AIR RISK"
	if not card.is_empty():
		var card_title: String = String(card.get("title_text", "")).strip_edges()
		if card_title.is_empty():
			card_title = String(card.get("display_name", "Dropship")).strip_edges()
		return "%s Â· %s" % [card_title, air_suffix] if not air_suffix.is_empty() else card_title
	if not _mission_drop_title_text.is_empty():
		return "%s Â· %s" % [_mission_drop_title_text, air_suffix] if not air_suffix.is_empty() else _mission_drop_title_text
	var craft_name: String = _mission_drop_display_name if not _mission_drop_display_name.is_empty() else "Dropship"
	if not air_suffix.is_empty():
		return "%s Â· %s" % [craft_name, air_suffix]
	match _mission_drop_state:
		"waiting":
			return "%s · MAP" % craft_name
		"to_mission":
			return "%s · HANDOVER" % craft_name
		"to_fob":
			return "%s · RETURN" % craft_name
		_:
			return craft_name


func _build_mission_dropship_pilot_text(card: Dictionary = {}) -> String:
	if not card.is_empty():
		var pilot_text: String = String(card.get("pilot_text", "")).strip_edges()
		if not pilot_text.is_empty():
			return pilot_text
		var pilot_display_name: String = String(card.get("pilot_display_name", "")).strip_edges()
		return "Pilot: %s" % (pilot_display_name if not pilot_display_name.is_empty() else "unassigned")
	if not _mission_drop_pilot_text.is_empty():
		return _mission_drop_pilot_text
	return "Pilot: %s" % (_mission_drop_pilot_display_name if not _mission_drop_pilot_display_name.is_empty() else "unassigned")


func _build_mission_dropship_passenger_text(card: Dictionary = {}) -> String:
	if not card.is_empty():
		return "Passengers: %d" % maxi(int(card.get("passenger_count", 0)), 0)
	var passenger_count: int = _mission_drop_passenger_count if _mission_drop_passenger_count > 0 else _embarked_unit_ids.size()
	return "Passengers: %d" % passenger_count


func _build_mission_dropship_progress_value(card: Dictionary = {}) -> float:
	if not card.is_empty():
		return clampf(float(card.get("progress", 0.0)), 0.0, 100.0)
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		return _build_active_drop_sequence_progress_value()
	return _mission_drop_progress


func _build_active_drop_sequence_progress_value() -> float:
	if _drop_sequence_phase == DROP_SEQUENCE_INBOUND:
		var staging_position: Vector2 = _get_drop_sequence_staging_position()
		var total_distance: float = staging_position.distance_to(_drop_sequence_lz_position)
		if total_distance > 0.001:
			var covered_distance: float = total_distance - _drop_sequence_position.distance_to(_drop_sequence_lz_position)
			return clampf((covered_distance / total_distance) * 100.0, 0.0, 100.0)
		return 0.0
	if _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		var exit_position: Vector2 = _get_drop_sequence_exit_position()
		var total_return_distance: float = _drop_sequence_lz_position.distance_to(exit_position)
		if total_return_distance > 0.001:
			var covered_return_distance: float = total_return_distance - _drop_sequence_position.distance_to(exit_position)
			return clampf((covered_return_distance / total_return_distance) * 100.0, 0.0, 100.0)
		return 0.0
	if _drop_sequence_phase == DROP_SEQUENCE_UNLOADING:
		return _build_drop_unload_progress_value(_drop_sequence_unit_index, _drop_sequence_units.size(), _drop_sequence_timer)
	return _mission_drop_progress


func _build_drop_sequence_progress_value(sequence: Dictionary) -> float:
	var phase: String = String(sequence.get("phase", "")).strip_edges().to_lower()
	var lz_position: Vector2 = _coerce_vector2_value(sequence.get("lz_position", Vector2.ZERO), Vector2.ZERO)
	var position: Vector2 = _coerce_vector2_value(sequence.get("position", Vector2.ZERO), Vector2.ZERO)
	var approach_angle: String = _sanitize_approach_angle_name(String(sequence.get("approach_angle", "NW")))
	if phase == DROP_SEQUENCE_INBOUND:
		var staging_position: Vector2 = _get_drop_staging_position_for_lz(lz_position, approach_angle)
		var total_distance: float = staging_position.distance_to(lz_position)
		if total_distance > 0.001:
			var covered_distance: float = total_distance - position.distance_to(lz_position)
			return clampf((covered_distance / total_distance) * 100.0, 0.0, 100.0)
		return 0.0
	if phase == DROP_SEQUENCE_OUTBOUND:
		var exit_position: Vector2 = _get_drop_staging_position_for_lz(lz_position, approach_angle)
		var total_return_distance: float = lz_position.distance_to(exit_position)
		if total_return_distance > 0.001:
			var covered_return_distance: float = total_return_distance - position.distance_to(exit_position)
			return clampf((covered_return_distance / total_return_distance) * 100.0, 0.0, 100.0)
		return 0.0
	if phase == DROP_SEQUENCE_UNLOADING:
		return _build_drop_unload_progress_value(int(sequence.get("unit_index", 0)), Array(sequence.get("units", [])).size(), float(sequence.get("timer", 0.0)))
	return clampf(float(sequence.get("progress", _mission_drop_progress)), 0.0, 100.0)


func _build_drop_unload_progress_value(unit_index: int, unit_count: int, timer_seconds: float) -> float:
	if unit_count <= 0:
		return 100.0
	var active_fraction: float = clampf(timer_seconds / maxf(DROP_UNLOAD_INTERVAL_SECONDS, 0.001), 0.0, 1.0)
	return clampf(((float(unit_index) + active_fraction) / float(unit_count)) * 100.0, 0.0, 100.0)


func _build_mission_dropship_pilot_profile(card: Dictionary = {}):
	if not card.is_empty():
		var card_pilot_unit_id: String = String(card.get("pilot_unit_id", "")).strip_edges()
		var card_pilot_display_name: String = String(card.get("pilot_display_name", "")).strip_edges()
		var card_pilot_portrait_path: String = String(card.get("pilot_portrait_path", "")).strip_edges()
		if card_pilot_display_name.is_empty() and card_pilot_portrait_path.is_empty():
			return null
		var card_pilot_unit = _find_friendly_unit_by_id(card_pilot_unit_id)
		if card_pilot_unit != null:
			var card_pilot_profile = _build_profile_from_unit(card_pilot_unit)
			if card_pilot_profile != null and card_pilot_profile.has_method("duplicate_profile"):
				var duplicated_card_profile = card_pilot_profile.duplicate_profile()
				duplicated_card_profile.secondary_text = _build_mission_dropship_pilot_text(card)
				return duplicated_card_profile
			return card_pilot_profile
		return META_UNIT_PROFILE_BUILDER_SCRIPT.build_from_identity_config(
			{
				"unit_id": card_pilot_unit_id if not card_pilot_unit_id.is_empty() else "mission_drop_pilot",
				"display_name": card_pilot_display_name if not card_pilot_display_name.is_empty() else "Unassigned Pilot",
				"portrait_path": card_pilot_portrait_path,
				"role_name": "Dropship Pilot",
				"team_id": FRIENDLY_TEAM_ID,
			},
			{
				"secondary_text": _build_mission_dropship_pilot_text(card),
			}
		)
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


func _build_mission_dropship_status_text(card: Dictionary = {}) -> String:
	var air_status: Dictionary = get_air_asset_status_snapshot()
	var air_state: String = str(air_status.get("state", "intact")).strip_edges().to_lower()
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_terminal_state", air_state)):
		return "Air asset lost"
	if air_state == "recovering" or air_state == "unavailable":
		return "Air asset unavailable"
	if air_state == "damaged" or air_state == "hit":
		return "Damage %d%%" % int(round((1.0 - float(air_status.get("integrity_ratio", 1.0))) * 100.0))
	if bool(AIR_ASSET_STATUS_SCRIPT.call("is_warning_state", air_state)):
		return "Threat lock %d%%" % int(round(float(air_status.get("risk", 0.0)) * 100.0))
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id) and card.is_empty():
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
	if not card.is_empty():
		var card_status_line: String = String(card.get("status_line", "")).strip_edges()
		if not card_status_line.is_empty():
			return card_status_line
		match String(card.get("state", "")).strip_edges().to_lower():
			DROP_SEQUENCE_INBOUND:
				return "Inbound to LZ"
			DROP_SEQUENCE_LANDED:
				return "Landed at LZ"
			DROP_SEQUENCE_UNLOADING:
				return "Dropping %d" % maxi(int(card.get("passenger_count", 0)), 0)
			DROP_SEQUENCE_OUTBOUND:
				return "Leaving mission map"
			DROP_SEQUENCE_COMPLETE:
				return "Drop complete"
			"waiting":
				if bool(card.get("drop_ship_requested", false)):
					return "Drop waiting | %s" % ("LZ set" if bool(card.get("has_lz_position", false)) else "set LZ")
				if bool(card.get("has_lz_position", false)):
					return "Ready off-map | LZ set"
				return "Holding off-map | set LZ"
			"to_mission":
				return "ETA mission map %ds" % maxi(int(card.get("eta_seconds", 0)), 0)
			"to_fob":
				return "Returning to FOB %ds" % maxi(int(card.get("eta_seconds", 0)), 0)
			_:
				return "Mission transport offline"
	if not _mission_drop_status_line.is_empty():
		return _mission_drop_status_line
	match _mission_drop_state:
		"waiting":
			return "Holding off-map"
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


func _apply_contextual_help_ids() -> void:
	_ensure_fireteam_status_panel()
	_ensure_tactical_stance_panel()
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel", "mission.command_matrix")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll", "mission_hud.command_matrix")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel", "mission.command_matrix")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton", "mission.command.move")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton", "mission.command.defend")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton", "mission.command.flank")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton", "mission.command.take")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton", "mission.command.attack_area")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton", "mission.command.clear_target")
	_apply_help_id(DELETE_ORDER_BUTTON_PATH, "mission.command.clear_target")
	_apply_help_id(SORT_COMMAND_BUTTON_PATH, "mission.command.go_plan")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton", "mission.command.go_plan")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton", "mission.command.go_plan")
	_apply_help_id("../TacticalUI/AreaOrderCommandMenu", "mission.command.defend_area")
	_apply_help_id(FIRETEAM_PANEL_PATH, "mission.selected_fireteam")
	_apply_help_id(FIRETEAM_HEADER_LABEL_PATH, "mission.selected_fireteam")
	_apply_help_id(FIRETEAM_STATUS_LABEL_PATH, "mission.command.advance_style")
	_apply_help_id(FIRETEAM_ALL_BUTTON_PATH, "mission.selected_fireteam")
	_apply_help_id(command_feedback_label_path, "mission.command.area_order")
	_apply_help_id(hotkey_legend_label_path, "mission.command.area_order")
	_apply_help_id("%s/FireteamStatusPanel" % FIRETEAM_INFO_VBOX_PATH, "mission.command.overwatch")
	_apply_help_id("%s/FireteamStatusPanel/MarginContainer/HBoxContainer/SuppressionLabel" % FIRETEAM_INFO_VBOX_PATH, "mission.command.security")
	_apply_help_id("%s/FireteamStatusPanel/MarginContainer/HBoxContainer/ReturnToPlanButton" % FIRETEAM_INFO_VBOX_PATH, "mission.command.go_plan")
	_apply_help_id("%s/TacticalStancePanel" % FIRETEAM_INFO_VBOX_PATH, "mission.command.stance")
	_apply_help_id("%s/TacticalStancePanel/MarginContainer/VBoxContainer/HBoxContainer/CautiousButton" % FIRETEAM_INFO_VBOX_PATH, "mission.command.stance")
	_apply_help_id("%s/TacticalStancePanel/MarginContainer/VBoxContainer/HBoxContainer/NormalButton" % FIRETEAM_INFO_VBOX_PATH, "mission.command.stance")
	_apply_help_id("%s/TacticalStancePanel/MarginContainer/VBoxContainer/HBoxContainer/AggressiveButton" % FIRETEAM_INFO_VBOX_PATH, "mission.command.stance")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel", "mission.mission_control")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll", "mission_hud.mission_control")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicHeaderLabel", "mission.mission_control")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel", "mission.command.go_plan")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton", "mission.command.set_lz")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton", "mission.command.call_dropship")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid", "mission.command.approach")
	_apply_help_id("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel", "mission.command.medic_adjacent")
	_apply_command_hierarchy_group_help_ids()


func _apply_help_id(path: Variant, help_id: String) -> void:
	var node := get_node_or_null(NodePath(str(path)))
	if node == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	node.set_meta("help_id", normalized_id)


func _apply_command_hierarchy_group_help_ids() -> void:
	var group_help_ids: Dictionary = Dictionary(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call("get_group_help_ids"))
	_set_command_hierarchy_panel_meta(
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel",
		str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("PANEL_COMMAND_MATRIX")),
		PackedStringArray([str(group_help_ids.get("goal", ""))])
	)
	_set_command_hierarchy_panel_meta(
		FIRETEAM_PANEL_PATH,
		str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("PANEL_FIRETEAM_DETAILS")),
		PackedStringArray([str(group_help_ids.get("rule", ""))])
	)
	_set_command_hierarchy_panel_meta(
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel",
		str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("PANEL_MISSION_CONTROL")),
		PackedStringArray([
			str(group_help_ids.get("plan", "")),
			str(group_help_ids.get("air_lz", "")),
			str(group_help_ids.get("breakout", "")),
		])
	)


func _set_command_hierarchy_panel_meta(path: Variant, panel_role: String, group_help_ids: PackedStringArray) -> void:
	var node := get_node_or_null(NodePath(str(path)))
	if node == null:
		return
	node.set_meta("command_hierarchy_panel_role", panel_role)
	node.set_meta("command_hierarchy_group_help_ids", group_help_ids)


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
	var viewport := get_viewport()
	if viewport == null:
		return world_position
	var visible_rect: Rect2 = viewport.get_visible_rect()
	var canvas_transform: Transform2D = viewport.get_canvas_transform()
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
		{"path": move_button_path, "command_type": "move"},
		{"path": defend_button_path, "command_type": "defend"},
		{"path": flank_button_path, "command_type": "flank"},
		{"path": take_button_path, "command_type": "take"},
	]
	for button_entry_variant in command_buttons:
		var button_entry: Dictionary = Dictionary(button_entry_variant)
		var button_path: NodePath = NodePath(str(button_entry.get("path", "")))
		var command_type: String = String(button_entry.get("command_type", "")).strip_edges().to_lower()
		var command_button := get_node_or_null(button_path) as BaseButton
		if command_button == null:
			continue
		var needs_tile: bool = _requires_selected_tile_for_command(command_type) and _has_primary_grid_for_command_selection()
		command_button.disabled = preview_mode or not _can_issue_local_commands() or _selected_fireteam_ids.is_empty() or (needs_tile and not _has_selected_tile)

	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
	]:
		var utility_button := get_node_or_null(path) as BaseButton
		if utility_button == null:
			continue
		utility_button.disabled = not _can_edit_planning()

	var delete_order_button := get_node_or_null(DELETE_ORDER_BUTTON_PATH) as BaseButton
	if delete_order_button != null:
		delete_order_button.disabled = not _can_edit_planning() or not _has_deletable_order_focus()

	var sort_button := get_node_or_null(SORT_COMMAND_BUTTON_PATH) as BaseButton
	if sort_button != null:
		sort_button.disabled = preview_mode or not _can_issue_local_commands() or _selected_fireteam_ids.is_empty()

	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/PrevEditPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/AddPhaseButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextEditPhaseButton",
	]:
		var phase_button := get_node_or_null(path) as BaseButton
		if phase_button == null:
			continue
		phase_button.visible = PHASE_PLANNING_ENABLED
		phase_button.disabled = true if not PHASE_PLANNING_ENABLED else not _can_edit_planning()

	var call_dropship_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as BaseButton
	if call_dropship_button != null:
		call_dropship_button.disabled = not _can_edit_planning() or not _is_mission_drop_available() or (not preview_mode and _drop_ship_cooldown_remaining > 0.0)

	var next_phase_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel/PhaseControlMargin/PhaseControlVBox/PhaseActionRow/NextPhaseButton") as BaseButton
	if next_phase_button != null:
		next_phase_button.visible = PHASE_PLANNING_ENABLED
		next_phase_button.disabled = true if not PHASE_PLANNING_ENABLED else preview_mode or not _can_issue_local_commands() or not _has_pending_global_phase()
	var go_matrix_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton") as BaseButton
	if go_matrix_button != null:
		go_matrix_button.disabled = preview_mode or not _can_issue_local_commands() or not _has_selected_fireteam_orders_to_execute()
	var plan_matrix_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton") as BaseButton
	if plan_matrix_button != null:
		plan_matrix_button.disabled = preview_mode or not _can_issue_local_commands() or not _can_return_selected_fireteams_to_plan()
	_refresh_tactical_stance_panel()


func _build_command_control_snapshot() -> Dictionary:
	return {
		"move": _build_button_snapshot(move_button_path),
		"defend": _build_button_snapshot(defend_button_path),
		"flank": _build_button_snapshot(flank_button_path),
		"take": _build_button_snapshot(take_button_path),
		"target": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_TARGET")))),
		"clear_target": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_CLEAR_TARGET")))),
		"delete_order": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_DELETE_ORDER")))),
		"sort_fireteam": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_SORT")))),
		"set_lz": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_SET_LZ")))),
		"call_dropship": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_CALL_DROPSHIP")))),
		"go_plan": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_GO_PLAN")))),
		"return_to_plan": _build_button_snapshot(NodePath(str(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.get("BUTTON_PATH_RETURN_TO_PLAN")))),
		"hierarchy": get_command_hierarchy_snapshot(),
	}


func _build_button_snapshot(button_path: NodePath) -> Dictionary:
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		return {
			"exists": false,
			"path": str(button_path),
			"text": "",
			"disabled": true,
			"visible": false,
			"is_visible_in_tree": false,
			"tooltip_text": "",
			"help_id": "",
			"command_hierarchy_action_id": "",
			"command_hierarchy_group_id": "",
			"command_hierarchy_panel_role": "",
			"command_hierarchy_disabled_reason": "missing button",
			"command_hierarchy_requires_tile_selection": false,
			"pressed_signal_connection_count": 0,
		}
	var global_rect: Rect2 = button.get_global_rect() if button.is_inside_tree() else Rect2()
	return {
		"exists": true,
		"path": str(button_path),
		"text": str(button.get("text")),
		"disabled": bool(button.disabled),
		"visible": bool(button.visible),
		"is_visible_in_tree": bool(button.is_visible_in_tree()) if button.is_inside_tree() else bool(button.visible),
		"tooltip_text": button.tooltip_text,
		"help_id": str(button.get_meta("help_id", "")),
		"command_hierarchy_action_id": str(button.get_meta("command_hierarchy_action_id", "")),
		"command_hierarchy_group_id": str(button.get_meta("command_hierarchy_group_id", "")),
		"command_hierarchy_panel_role": str(button.get_meta("command_hierarchy_panel_role", "")),
		"command_hierarchy_help_id": str(button.get_meta("command_hierarchy_help_id", "")),
		"command_hierarchy_context": str(button.get_meta("command_hierarchy_context", "")),
		"command_hierarchy_requires_tile_selection": bool(button.get_meta("command_hierarchy_requires_tile_selection", false)),
		"command_hierarchy_disabled_reason": str(button.get_meta("command_hierarchy_disabled_reason", "")),
		"global_rect": global_rect,
		"pressed_signal_connection_count": button.pressed.get_connections().size(),
	}


func get_command_hierarchy_snapshot() -> Dictionary:
	return Dictionary(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call(
		"build_hierarchy_snapshot",
		_build_command_hierarchy_context(),
		_build_full_command_button_snapshot()
	))


func _build_full_command_button_snapshot() -> Dictionary:
	var button_snapshots: Dictionary = {}
	for action_variant in Array(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call("get_action_catalog")):
		var action: Dictionary = Dictionary(action_variant)
		var action_id: String = str(action.get("action_id", ""))
		var button_path: String = str(action.get("button_path", ""))
		if action_id.is_empty() or button_path.is_empty():
			continue
		button_snapshots[action_id] = _build_hierarchy_button_snapshot(action_id, NodePath(button_path))
	return button_snapshots


func _build_hierarchy_button_snapshot(action_id: String, button_path: NodePath) -> Dictionary:
	var snapshot: Dictionary = _build_button_snapshot(button_path)
	snapshot["action_id"] = action_id
	return snapshot


func _build_command_hierarchy_context() -> Dictionary:
	return {
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"selected_fireteam_count": _selected_fireteam_ids.size(),
		"single_fireteam_context": _selected_fireteam_ids.size() == 1,
		"multi_fireteam_context": _selected_fireteam_ids.size() > 1,
		"preview_mode": preview_mode,
		"can_issue_local_commands": _can_issue_local_commands(),
		"can_edit_planning": _can_edit_planning(),
		"phase_planning_enabled": PHASE_PLANNING_ENABLED,
		"has_pending_global_phase": _has_pending_global_phase(),
		"has_multi_fireteam_plan": not _find_multi_fireteam_plan_for_selected_fireteams().is_empty(),
		"has_target": get_node_or_null(target_marker_path) != null,
		"has_lz": _has_lz_position,
		"has_selected_tile": _has_selected_tile,
		"requires_tile_selection": _has_primary_grid_for_command_selection(),
		"selected_tile_grid_position": _selected_tile_grid_position,
		"selected_tile_world_position": _selected_tile_world_position,
		"drop_available": _is_mission_drop_available(),
		"drop_requested": _drop_ship_requested,
		"drop_cooldown_remaining": _drop_ship_cooldown_remaining,
		"target_placement_armed": _is_target_placement_armed,
		"lz_placement_armed": _is_lz_placement_armed,
	}


func _apply_command_hierarchy_metadata() -> void:
	var context: Dictionary = _build_command_hierarchy_context()
	var button_snapshots: Dictionary = _build_full_command_button_snapshot()
	var hierarchy: Dictionary = Dictionary(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call("build_hierarchy_snapshot", context, button_snapshots))
	var actions_by_id: Dictionary = Dictionary(hierarchy.get("actions_by_id", {}))
	for action_id_variant in actions_by_id.keys():
		var action: Dictionary = Dictionary(actions_by_id[action_id_variant])
		var button_path: String = str(action.get("button_path", ""))
		if button_path.is_empty():
			continue
		var button := get_node_or_null(NodePath(button_path)) as Button
		if button == null:
			continue
		var metadata: Dictionary = Dictionary(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call(
			"build_button_metadata",
			action,
			context,
			Dictionary(button_snapshots.get(str(action_id_variant), {}))
		))
		for key_variant in metadata.keys():
			button.set_meta(str(key_variant), metadata[key_variant])
		button.set_meta("command_hierarchy_group_help_id", _get_command_hierarchy_group_help_id(str(action.get("group_id", ""))))
		button.tooltip_text = _build_command_hierarchy_tooltip(action, button, str(metadata.get("command_hierarchy_disabled_reason", "")))


func _get_command_hierarchy_group_help_id(group_id: String) -> String:
	var group_help_ids: Dictionary = Dictionary(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call("get_group_help_ids"))
	return str(group_help_ids.get(group_id, ""))


func _build_command_hierarchy_tooltip(action: Dictionary, button: Button, disabled_reason: String) -> String:
	var label: String = str(action.get("label", ""))
	if label.is_empty():
		label = button.text
	var group_labels: Dictionary = Dictionary(MISSION_COMMAND_HIERARCHY_CONTRACT_SCRIPT.call("get_group_labels"))
	var group_label: String = str(group_labels.get(str(action.get("group_id", "")), ""))
	var prefix: String = label if group_label.is_empty() else "%s | %s" % [group_label, label]
	var parts: PackedStringArray = PackedStringArray([prefix])
	var tooltip_hint: String = String(action.get("tooltip_hint", "")).strip_edges()
	if not tooltip_hint.is_empty():
		parts.append(tooltip_hint)
	var status_source: String = String(action.get("status_source", "")).strip_edges()
	if bool(action.get("status_only", false)) and not status_source.is_empty():
		parts.append("Source: %s" % status_source)
	if not disabled_reason.is_empty():
		parts.append(disabled_reason)
	return " | ".join(parts)


func _get_label_text(label_path: Variant) -> String:
	var label := get_node_or_null(NodePath(String(label_path))) as Label
	if label == null:
		return ""
	return label.text


func _refresh_world_overlays() -> void:
	var primary_has_live_drop_state: bool = not _mission_drop_state.is_empty()
	var primary_has_live_drop_sequence: bool = not _drop_sequence_phase.is_empty()
	var dropship_position: Vector2 = _drop_sequence_position if primary_has_live_drop_sequence else _get_drop_staging_position()
	var dropship_visuals: Array = _build_mission_dropship_visual_entries(primary_has_live_drop_state or primary_has_live_drop_sequence, dropship_position)
	var dropship_visible: bool = not dropship_visuals.is_empty()
	var primary_dropship_position: Vector2 = dropship_position
	var primary_dropship_target: Vector2 = _get_primary_dropship_target_position(primary_dropship_position)
	if not dropship_visuals.is_empty() and not (primary_has_live_drop_state or primary_has_live_drop_sequence):
		var first_visual: Dictionary = Dictionary(dropship_visuals[0])
		primary_dropship_position = Vector2(first_visual.get("dropship_position", primary_dropship_position))
		primary_dropship_target = Vector2(first_visual.get("dropship_target_position", primary_dropship_target))
	_publish_dropship_snapshot_context(
		{
			"visible": dropship_visible,
			"state": _drop_sequence_phase if primary_has_live_drop_sequence else _mission_drop_state,
			"has_lz": _has_lz_position,
			"show_lz_marker": _has_lz_position and _should_show_lz_marker_for_state(_drop_sequence_phase if primary_has_live_drop_sequence else _mission_drop_state),
			"lz_position": _lz_position,
			"position": primary_dropship_position,
			"target_position": primary_dropship_target,
			"dropship_visuals": dropship_visuals,
			"progress": _build_mission_dropship_progress_value(),
			"air_asset_status": get_air_asset_status_snapshot(),
		}
	)

	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		if _primary_view_bridge.call(
			"sync_mission_drop_visual_state",
			get_parent(),
			{
				"has_lz_position": _has_lz_position,
				"show_lz_marker": _has_lz_position and _should_show_lz_marker_for_state(_drop_sequence_phase if primary_has_live_drop_sequence else _mission_drop_state),
				"lz_position": _lz_position,
				"lz_label": _build_mission_dropship_lz_name(_mission_drop_craft_id, _mission_drop_display_name) if _has_lz_position else "",
				"dropship_visible": dropship_visible,
				"dropship_position": primary_dropship_position,
				"dropship_target_position": primary_dropship_target,
				"dropship_visuals": dropship_visuals,
				"dropship_texture": _get_mission_dropship_texture(),
			}
		):
			_refresh_meta_transfer_route_overlay()
			return

	var lz_marker := get_node_or_null("../LZMarker") as Node2D
	var show_primary_lz_marker: bool = _has_lz_position and _should_show_lz_marker_for_state(_drop_sequence_phase if primary_has_live_drop_sequence else _mission_drop_state)
	if lz_marker != null:
		lz_marker.visible = show_primary_lz_marker
		if show_primary_lz_marker:
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
			if not _is_mission_dropship_position_inside_map_airspace(dropship_marker.global_position):
				dropship_marker.visible = false
			if sprite != null:
				sprite.texture = _get_mission_dropship_texture()
			var approach_line := dropship_marker.get_node_or_null("ApproachLine") as Line2D
			if approach_line != null:
				approach_line.clear_points()
				var line_delta: Vector2 = _lz_position - dropship_marker.global_position if show_primary_lz_marker else Vector2.ZERO
				if show_primary_lz_marker and line_delta.length_squared() > 4.0:
					approach_line.add_point(Vector2.ZERO)
					approach_line.add_point(line_delta)
	_refresh_meta_transfer_route_overlay()


func _build_mission_dropship_visual_entries(primary_visible: bool, primary_position: Vector2) -> Array:
	var entries: Array = []
	var seen_craft_ids: Dictionary = {}
	var selected_craft_id: String = _mission_drop_craft_id.strip_edges()
	var cards: Array = _get_mission_dropship_card_entries()
	for index in range(cards.size()):
		var card: Dictionary = Dictionary(cards[index])
		var craft_id: String = String(card.get("craft_id", "")).strip_edges()
		if craft_id.is_empty():
			craft_id = "mission_drop_%d" % index
		if seen_craft_ids.has(craft_id):
			continue
		var entry: Dictionary = _build_mission_dropship_visual_entry(card, index, primary_visible, primary_position, craft_id == selected_craft_id, craft_id == _drop_sequence_craft_id.strip_edges(), cards.size())
		if entry.is_empty():
			continue
		seen_craft_ids[craft_id] = true
		entries.append(entry)
	if entries.is_empty() and primary_visible and _is_mission_dropship_position_inside_map_airspace(primary_position):
		var target_position: Vector2 = _get_primary_dropship_target_position(primary_position)
		entries.append(
			{
				"craft_id": selected_craft_id if not selected_craft_id.is_empty() else "mission_drop_sequence",
				"display_name": _mission_drop_display_name if not _mission_drop_display_name.is_empty() else "Dropship",
				"state": _drop_sequence_phase if not _drop_sequence_phase.is_empty() else _mission_drop_state,
				"dropship_visible": true,
				"dropship_position": primary_position,
				"dropship_target_position": target_position,
				"has_lz_position": _has_lz_position,
				"show_lz_marker": _has_lz_position and _should_show_lz_marker_for_state(_drop_sequence_phase if not _drop_sequence_phase.is_empty() else _mission_drop_state),
				"lz_position": _lz_position,
				"lz_label": _build_mission_dropship_lz_name(selected_craft_id, _mission_drop_display_name),
				"dropship_texture": _get_mission_dropship_texture(),
				"approach_vector_shape": "wide_arrow",
				"team_id": FRIENDLY_TEAM_ID,
				"selected": true,
			}
		)
	return entries


func _build_mission_dropship_visual_entry(card: Dictionary, index: int, primary_visible: bool, primary_position: Vector2, is_selected: bool, is_active_sequence_card: bool, card_count: int = 1) -> Dictionary:
	var state: String = String(card.get("state", "")).strip_edges().to_lower()
	if is_active_sequence_card and _is_drop_sequence_active():
		state = _drop_sequence_phase
	if state.is_empty() and not (is_active_sequence_card and primary_visible):
		return {}
	if not _is_mission_dropship_state_visible_on_map(state) and not (is_active_sequence_card and primary_visible):
		return {}
	var craft_id: String = String(card.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		craft_id = "mission_drop_%d" % index
	var display_name: String = String(card.get("display_name", "Dropship")).strip_edges()
	var ship_position: Vector2 = _get_mission_dropship_card_position(card, index, state)
	if is_active_sequence_card and _is_drop_sequence_active():
		ship_position = primary_position
	elif card.has("drop_sequence_position"):
		ship_position = _coerce_vector2_value(card.get("drop_sequence_position", ship_position), ship_position)
	elif card.has("dropship_position"):
		ship_position = _coerce_vector2_value(card.get("dropship_position", ship_position), ship_position)
	var target_position: Vector2 = _get_mission_dropship_card_target_position(card, index, state, ship_position)
	var has_lz: bool = bool(card.get("has_lz_position", false))
	var lz_position: Vector2 = _coerce_vector2_value(card.get("lz_position", _lz_position if is_selected else Vector2.ZERO), _lz_position if is_selected else Vector2.ZERO)
	var lz_label: String = String(card.get("lz_label", card.get("lz_name", ""))).strip_edges()
	if lz_label.is_empty() and has_lz:
		lz_label = _build_mission_dropship_lz_name(craft_id, display_name)
	var body_visible: bool = _should_show_mission_dropship_body_for_state(state) and _is_mission_dropship_position_inside_player_area(ship_position)
	if not body_visible and not has_lz:
		return {}
	var approach_origin_position: Vector2 = _get_mission_dropship_approach_origin_position(card, index, state, ship_position, has_lz, lz_position, is_selected)
	var show_lz_marker: bool = has_lz and bool(card.get("show_lz_marker", _should_show_lz_marker_for_state(state)))
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": state,
		"dropship_visible": body_visible,
		"dropship_position": ship_position,
		"dropship_target_position": target_position,
		"approach_origin_position": approach_origin_position,
		"approach_vector_origin_position": approach_origin_position,
		"approach_vector_target_position": lz_position if has_lz else target_position,
		"approach_vector_shape": "wide_arrow",
		"approach_angle": _sanitize_approach_angle_name(String(card.get("approach_angle", _get_approach_angle_name()))),
		"show_approach_vector": show_lz_marker,
		"has_lz_position": has_lz,
		"show_lz_marker": show_lz_marker,
		"lz_position": lz_position,
		"lz_label": lz_label,
		"dropship_texture": _get_mission_dropship_texture(card),
		"team_id": FRIENDLY_TEAM_ID,
		"selected": is_selected,
	}


func _should_show_mission_dropship_body_for_state(state: String) -> bool:
	match state.strip_edges().to_lower():
		"to_fob", DROP_SEQUENCE_INBOUND, DROP_SEQUENCE_LANDED, DROP_SEQUENCE_UNLOADING, DROP_SEQUENCE_COMPLETE, DROP_SEQUENCE_OUTBOUND:
			return true
		_:
			return false


func _should_show_lz_marker_for_state(state: String) -> bool:
	match state.strip_edges().to_lower():
		DROP_SEQUENCE_LANDED, DROP_SEQUENCE_UNLOADING, DROP_SEQUENCE_COMPLETE, DROP_SEQUENCE_OUTBOUND, "to_fob", "to_homebase":
			return false
		_:
			return true


func _is_mission_dropship_state_visible_on_map(state: String) -> bool:
	match state.strip_edges().to_lower():
		"to_mission", "waiting", "to_fob", DROP_SEQUENCE_INBOUND, DROP_SEQUENCE_LANDED, DROP_SEQUENCE_UNLOADING, DROP_SEQUENCE_COMPLETE, DROP_SEQUENCE_OUTBOUND:
			return true
		_:
			return false


func _is_mission_dropship_position_inside_map_airspace(world_position: Vector2) -> bool:
	var map_bounds: Rect2 = _get_map_world_bounds()
	if map_bounds.size.x <= 1.0 or map_bounds.size.y <= 1.0:
		return true
	return map_bounds.grow(128.0).has_point(world_position)


func _is_mission_dropship_position_inside_player_area(world_position: Vector2) -> bool:
	var map_bounds: Rect2 = _get_map_world_bounds()
	if map_bounds.size.x <= 1.0 or map_bounds.size.y <= 1.0:
		return true
	return map_bounds.has_point(world_position)


func _get_mission_dropship_card_position(card: Dictionary, index: int, state: String) -> Vector2:
	var hold_position: Vector2 = _get_mission_dropship_hold_position(index)
	var has_lz: bool = bool(card.get("has_lz_position", false))
	var lz_position: Vector2 = _coerce_vector2_value(card.get("lz_position", _lz_position), _lz_position)
	var approach_angle: String = _sanitize_approach_angle_name(String(card.get("approach_angle", _get_approach_angle_name())))
	var staging_position: Vector2 = _get_drop_staging_position_for_lz(lz_position if has_lz else hold_position, approach_angle)
	var progress: float = clampf(float(card.get("progress", 100.0 if state == "waiting" else 0.0)) / 100.0, 0.0, 1.0)
	match state.strip_edges().to_lower():
		"to_mission":
			return staging_position.lerp(hold_position, progress)
		"to_fob":
			var return_start_position: Vector2 = lz_position if has_lz else hold_position
			return return_start_position.lerp(staging_position, progress)
		DROP_SEQUENCE_INBOUND:
			var inbound_target_position: Vector2 = lz_position if has_lz else hold_position
			return staging_position.lerp(inbound_target_position, progress)
		DROP_SEQUENCE_OUTBOUND:
			var outbound_start_position: Vector2 = lz_position if has_lz else hold_position
			return outbound_start_position.lerp(staging_position, progress)
		DROP_SEQUENCE_LANDED, DROP_SEQUENCE_UNLOADING, DROP_SEQUENCE_COMPLETE:
			return lz_position if has_lz else hold_position
		_:
			return hold_position


func _get_mission_dropship_approach_origin_position(card: Dictionary, index: int, state: String, ship_position: Vector2, has_lz: bool, lz_position: Vector2, is_selected: bool) -> Vector2:
	if not has_lz:
		return ship_position
	var approach_angle: String = _sanitize_approach_angle_name(String(card.get("approach_angle", _get_approach_angle_name())))
	if is_selected:
		approach_angle = _get_approach_angle_name()
	match state.strip_edges().to_lower():
		"waiting", "to_mission":
			return _get_drop_staging_position_for_lz(lz_position, approach_angle)
		_:
			return ship_position


func _get_mission_dropship_card_target_position(card: Dictionary, index: int, state: String, ship_position: Vector2) -> Vector2:
	var has_lz: bool = bool(card.get("has_lz_position", false))
	var lz_position: Vector2 = _coerce_vector2_value(card.get("lz_position", _lz_position), _lz_position)
	var approach_angle: String = _sanitize_approach_angle_name(String(card.get("approach_angle", _get_approach_angle_name())))
	match state.strip_edges().to_lower():
		"to_fob", DROP_SEQUENCE_OUTBOUND:
			return _get_drop_staging_position_for_lz(lz_position if has_lz else _get_mission_dropship_hold_position(index), approach_angle)
		DROP_SEQUENCE_INBOUND, DROP_SEQUENCE_LANDED, DROP_SEQUENCE_UNLOADING, DROP_SEQUENCE_COMPLETE:
			return lz_position if has_lz else ship_position
		_:
			if has_lz:
				return lz_position
			return _get_mission_dropship_hold_position(index) + Vector2(96.0, 42.0)


func _get_mission_dropship_hold_position(index: int) -> Vector2:
	var map_bounds: Rect2 = _get_map_world_bounds()
	if map_bounds.size.x <= 1.0 or map_bounds.size.y <= 1.0:
		return _lz_position if _has_lz_position else Vector2.ZERO
	var margin_x: float = minf(maxf(map_bounds.size.x * 0.12, 96.0), map_bounds.size.x * 0.35)
	var margin_y: float = minf(maxf(map_bounds.size.y * 0.10, 72.0), map_bounds.size.y * 0.35)
	var hold_x: float = map_bounds.position.x + map_bounds.size.x - margin_x
	var hold_y: float = map_bounds.position.y + margin_y + (float(index) * MISSION_DROPSHIP_HOLD_SPACING)
	hold_y = clampf(hold_y, map_bounds.position.y + margin_y, map_bounds.position.y + map_bounds.size.y - margin_y)
	return Vector2(hold_x, hold_y)


func _get_drop_staging_position_for_lz(lz_position: Vector2, approach_angle: String) -> Vector2:
	var offset: Vector2 = Vector2(APPROACH_OFFSETS.get(_sanitize_approach_angle_name(approach_angle), Vector2(180.0, -112.0)))
	if offset.length_squared() <= 0.001:
		offset = Vector2(180.0, -112.0)
	var map_bounds: Rect2 = _get_map_world_bounds()
	var map_span: float = maxf(maxf(map_bounds.size.x, map_bounds.size.y) * DROP_OFFMAP_DISTANCE_MULTIPLIER, DROP_OFFMAP_MIN_DISTANCE)
	return lz_position + offset.normalized() * map_span


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


func _apply_drop_light_fixed_hud_layout() -> void:
	var tactical_ui := get_node_or_null("../TacticalUI") as CanvasLayer
	if tactical_ui != null:
		tactical_ui.set_meta("drop_light_fixed_fullhd_layout", true)
		tactical_ui.set_meta("drop_light_screen", DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SCREEN_MISSION_HUD"))
	var target_viewport: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	for path in [
		"../TacticalUI/MissionTint",
		"../TacticalUI/BottomDock",
		"../TacticalUI/BottomDock/BottomMargin",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow",
	]:
		var passive_control := get_node_or_null(path) as Control
		if passive_control != null:
			passive_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint := get_node_or_null("../TacticalUI/MissionTint") as Control
	if tint != null:
		tint.custom_minimum_size = Vector2(float(target_viewport.x), float(target_viewport.y))
	_enforce_drop_light_fixed_hud_layout()
	call_deferred("_deferred_enforce_drop_light_fixed_hud_layout")


func _enforce_drop_light_fixed_hud_layout() -> void:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	_apply_fixed_hud_window_contract("../TacticalUI/MissionIdentityPanel", layout.get("mission_identity"))
	_apply_fixed_hud_window_contract("../TacticalUI/TopNavPanel", layout.get("top_nav"))
	_apply_fixed_hud_window_contract(FIRETEAM_MINI_PANEL_PATH, layout.get("fireteam_mini"))
	_apply_fixed_hud_window_contract("../TacticalUI/BottomDock", layout.get("bottom_dock"))
	_apply_fixed_hud_window_contract("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel", layout.get("command_matrix"))
	_apply_fixed_hud_window_contract(FIRETEAM_PANEL_PATH, layout.get("selected_fireteam"))
	_apply_fixed_hud_window_contract("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel", layout.get("mission_control"))


func _deferred_enforce_drop_light_fixed_hud_layout() -> void:
	_enforce_drop_light_fixed_hud_layout()


func _apply_fixed_hud_window_contract(path: String, rect_variant: Variant) -> void:
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


func _set_square_hud_button(path: String, size: Vector2i, font_size: int = 8) -> void:
	var button := get_node_or_null(path) as Button
	if button == null:
		return
	_configure_square_hud_button(button, size, font_size)


func _configure_square_hud_button(button: Button, size: Vector2i, font_size: int = 8) -> void:
	if button == null:
		return
	var fixed_size := Vector2(float(size.x), float(size.y))
	button.custom_minimum_size = fixed_size
	button.size = fixed_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_text = true
	button.add_theme_font_size_override("font_size", font_size)
	button.set_meta("drop_light_square_action_button", true)


func _apply_command_button_markers() -> void:
	var marker_by_path: Dictionary = {
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton": "16.1",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton": "16.2",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton": "16.3",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton": "16.4",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton": "16.5",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton": "16.6",
		DELETE_ORDER_BUTTON_PATH: "16.7",
		SORT_COMMAND_BUTTON_PATH: "16.10",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton": "16.15",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton": "16.20",
	}
	for path_variant in marker_by_path.keys():
		_apply_button_corner_marker(String(path_variant), String(marker_by_path[path_variant]))
	for slot_index in range(7, 21):
		if [7, 10, 15, 20].has(slot_index):
			continue
		_apply_button_corner_marker("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/CommandSlot%02d" % slot_index, "16.%d" % slot_index)


func _apply_button_corner_marker(path: String, marker_text: String) -> void:
	var button := get_node_or_null(path) as Button
	if button == null:
		return
	var marker := button.get_node_or_null("TinyButtonMarker") as Label
	if marker == null:
		marker = Label.new()
		marker.name = "TinyButtonMarker"
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		marker.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_child(marker)
	marker.text = marker_text
	marker.position = Vector2(2.0, 1.0)
	marker.size = Vector2(24.0, 9.0)
	marker.z_index = 8
	marker.add_theme_font_size_override("font_size", 6)
	marker.add_theme_color_override("font_color", Color(0.78, 0.91, 0.96, 0.9))
	button.set_meta("drop_light_button_marker", marker_text)


func _apply_drop_light_hud_button_labels() -> void:
	var command_labels: Dictionary = {
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton": "Move",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton": "Hold",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton": "Flank",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton": "Take",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton": "Pick" if _is_target_placement_armed else "Target",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton": "Clear",
		DELETE_ORDER_BUTTON_PATH: "Del",
		SORT_COMMAND_BUTTON_PATH: "Sort",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton": "GO",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton": "Plan",
	}
	for path_variant in command_labels.keys():
		var button := get_node_or_null(String(path_variant)) as Button
		if button == null:
			continue
		button.text = String(command_labels[path_variant])
		button.tooltip_text = String(command_labels[path_variant])

	var lz_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton") as Button
	if lz_button != null:
		lz_button.text = "Pick" if _is_lz_placement_armed else "LZ"
		lz_button.tooltip_text = "Pick landing zone" if _is_lz_placement_armed else "Set landing zone"

	var drop_button := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton") as Button
	if drop_button != null:
		drop_button.text = _build_drop_light_drop_button_label()
		drop_button.tooltip_text = "Call dropship"
	_apply_command_button_markers()


func _build_drop_light_drop_button_label() -> String:
	if not preview_mode and _drop_ship_cooldown_remaining > 0.0 and not _is_drop_sequence_active():
		return "Cooldown %ds" % int(ceil(_drop_ship_cooldown_remaining))
	if _has_live_drop_sequence_for_craft(_mission_drop_craft_id) and not _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		var selected_card: Dictionary = _find_mission_dropship_card_entry(_mission_drop_craft_id)
		match String(selected_card.get("state", "")).strip_edges().to_lower():
			DROP_SEQUENCE_INBOUND:
				return "Inbound"
			DROP_SEQUENCE_LANDED:
				return "Landed"
			DROP_SEQUENCE_UNLOADING:
				return "Deboarding"
			DROP_SEQUENCE_OUTBOUND:
				return "Outbound"
			DROP_SEQUENCE_COMPLETE:
				return "Drop Complete"
	match _drop_sequence_phase:
		DROP_SEQUENCE_INBOUND:
			return "Inbound"
		DROP_SEQUENCE_LANDED:
			return "Landed"
		DROP_SEQUENCE_UNLOADING:
			return "Deboarding"
		DROP_SEQUENCE_OUTBOUND:
			return "Outbound"
		DROP_SEQUENCE_COMPLETE:
			return "Drop Complete"
		_:
			return "Drop"


func _apply_compact_mission_control_layout() -> void:
	var action_button_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	var small_button_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("SMALL_ACTION_BUTTON_SIZE")
	var top_nav_panel := get_node_or_null("../TacticalUI/TopNavPanel") as Control
	if top_nav_panel != null:
		top_nav_panel.clip_contents = true
	for path in [
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/HomebaseNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/FOBNavButton",
		"../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionNavButton",
	]:
		var nav_button := get_node_or_null(path) as Button
		if nav_button == null:
			continue
		nav_button.custom_minimum_size = Vector2(96.0, 32.0)
		nav_button.add_theme_font_size_override("font_size", 8)
	var nav_timer_label := get_node_or_null("../TacticalUI/TopNavPanel/NavMargin/NavRow/MissionTimerLabel") as Label
	if nav_timer_label != null:
		nav_timer_label.custom_minimum_size = Vector2(40.0, 0.0)
	var bottom_dock := get_node_or_null("../TacticalUI/BottomDock") as Control
	if bottom_dock != null:
		bottom_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bottom_dock.clip_contents = false
	for path in [
		"../TacticalUI/BottomDock/BottomMargin",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow",
	]:
		var passive_control := get_node_or_null(path) as Control
		if passive_control != null:
			passive_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var strategic_action_row := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow") as HBoxContainer
	if strategic_action_row != null:
		strategic_action_row.alignment = BoxContainer.ALIGNMENT_BEGIN
		strategic_action_row.add_theme_constant_override("separation", 4)
		strategic_action_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_ensure_mission_control_craft_summary()
	var phase_control_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/PhaseControlPanel") as Control
	if phase_control_panel != null:
		phase_control_panel.visible = PHASE_PLANNING_ENABLED
	var command_grid := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid") as GridContainer
	if command_grid != null:
		command_grid.columns = 5
		command_grid.add_theme_constant_override("h_separation", 7)
		command_grid.add_theme_constant_override("v_separation", 8)
		_apply_command_grid_hierarchy_order(command_grid)
		_ensure_command_grid_placeholder_buttons(command_grid)
	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/MoveButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/HoldButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/FlankButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TakeButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/TargetButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/ClearTargetButton",
		DELETE_ORDER_BUTTON_PATH,
		SORT_COMMAND_BUTTON_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/SetLZButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow/CallDropshipButton",
	]:
		_set_square_hud_button(path, action_button_size)
	var approach_grid := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid") as GridContainer
	if approach_grid != null:
		approach_grid.columns = 2
		approach_grid.add_theme_constant_override("h_separation", 8)
		approach_grid.add_theme_constant_override("v_separation", 8)
		approach_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/NEButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SWButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid/SEButton",
	]:
		_set_square_hud_button(path, small_button_size)
	var strategic_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel") as Control
	if strategic_panel != null:
		strategic_panel.clip_contents = true
	var command_panel := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel") as Control
	if command_panel != null:
		command_panel.clip_contents = true
	var fireteam_panel := get_node_or_null(FIRETEAM_PANEL_PATH) as Control
	if fireteam_panel != null:
		fireteam_panel.clip_contents = true
	_ensure_tactical_stance_panel()
	_ensure_fireteam_status_panel()
	_apply_compact_fireteam_info_text_contract()
	var fireteam_body_row := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow") as HBoxContainer
	if fireteam_body_row != null:
		fireteam_body_row.add_theme_constant_override("separation", 8)
	var fireteam_info_scroll := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll") as Control
	if fireteam_info_scroll != null:
		fireteam_info_scroll.custom_minimum_size = Vector2(304.0, 0.0)
		fireteam_info_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		fireteam_info_scroll.clip_contents = true
	var fireteam_cards_scroll := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control
	if fireteam_cards_scroll != null:
		fireteam_cards_scroll.custom_minimum_size = Vector2(840.0, 0.0)
		fireteam_cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fireteam_cards_scroll.clip_contents = true
		fireteam_cards_scroll.set_meta("selected_fireteam_cards_source", "_refresh_selected_fireteam_cards")
	var fireteam_cards_spacer := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody/FireteamCardsSpacer") as Control
	if fireteam_cards_spacer != null:
		fireteam_cards_spacer.visible = false
		fireteam_cards_spacer.custom_minimum_size = Vector2.ZERO
		fireteam_cards_spacer.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var fireteam_cards_body := get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll/FireteamCardsBody") as HBoxContainer
	if fireteam_cards_body != null:
		fireteam_cards_body.alignment = BoxContainer.ALIGNMENT_BEGIN
		fireteam_cards_body.clip_contents = true
	var fireteam_cards_row := get_node_or_null(FIRETEAM_SELECTED_CARDS_ROW_PATH) as HBoxContainer
	if fireteam_cards_row != null:
		fireteam_cards_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		fireteam_cards_row.clip_contents = false
	var fireteam_mini_panel := get_node_or_null(FIRETEAM_MINI_PANEL_PATH) as Control
	if fireteam_mini_panel != null:
		fireteam_mini_panel.clip_contents = false
		_apply_fireteam_mini_overlay_style()
	_apply_fireteam_panel_action_button_contract()
	_apply_card_bound_mission_control_layout()
	_enforce_drop_light_fixed_hud_layout()


func _apply_card_bound_mission_control_layout() -> void:
	for path in [
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicActionRow",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/ApproachGrid",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel",
	]:
		var control := get_node_or_null(path) as Control
		if control == null:
			continue
		control.visible = false
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.set_meta("mission_control_card_bound_hidden", true)


func _apply_command_grid_hierarchy_order(command_grid: GridContainer) -> void:
	var ordered_names: PackedStringArray = PackedStringArray([
		"MoveButton",
		"TakeButton",
		"HoldButton",
		"FlankButton",
		"TargetButton",
		"ClearTargetButton",
	])
	for index in range(ordered_names.size()):
		var child := command_grid.get_node_or_null(ordered_names[index])
		if child == null:
			continue
		command_grid.move_child(child, index)
	command_grid.set_meta("command_hierarchy_order", PackedStringArray(["move", "take", "defend", "flank", "engage", "clear_target", "delete_order", "sort_fireteam"]))
	command_grid.set_meta("command_hierarchy_columns", command_grid.columns)


func _ensure_command_grid_placeholder_buttons(command_grid: GridContainer) -> void:
	if command_grid == null:
		return
	var action_button_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	for slot_index in range(7, 21):
		if slot_index == 7:
			_ensure_command_grid_action_button(command_grid, "DeleteOrderButton", "Del", "Delete selected waypoint or area order", Callable(self, "_on_delete_order_pressed"), slot_index)
			continue
		if slot_index == 10:
			_ensure_command_grid_action_button(command_grid, "SortCommandMatrixButton", "Sort", "Center and sort selected fireteam", Callable(self, "_on_sort_fireteam_pressed"), slot_index)
			continue
		if slot_index == 15:
			_ensure_command_grid_action_button(command_grid, "GoCommandMatrixButton", "GO", "Execute selected orders", Callable(self, "_on_go_phase_pressed"), slot_index)
			continue
		if slot_index == 20:
			_ensure_command_grid_action_button(command_grid, "PlanCommandMatrixButton", "Plan", "Return selected fireteam to plan", Callable(self, "_on_return_to_plan_button_pressed"), slot_index)
			continue
		var slot_name := "CommandSlot%02d" % slot_index
		var button := command_grid.get_node_or_null(slot_name) as Button
		if button == null:
			button = Button.new()
			button.name = slot_name
			button.focus_mode = Control.FOCUS_NONE
			button.text = ""
			button.tooltip_text = "Reserve command slot"
			button.disabled = true
			button.set_meta("drop_light_command_placeholder", true)
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			command_grid.add_child(button)
		button.set_meta("drop_light_command_placeholder", true)
		button.disabled = true
		_configure_square_hud_button(button, action_button_size)
		META_UI_SKIN_SCRIPT.style_tactical_button(button, false)
		command_grid.move_child(button, slot_index - 1)
	command_grid.set_meta("command_placeholder_slots", 10)


func _ensure_command_grid_action_button(command_grid: GridContainer, button_name: String, text: String, tooltip: String, callback: Callable, slot_index: int) -> void:
	var stale_placeholder := command_grid.get_node_or_null("CommandSlot%02d" % slot_index) as Button
	if stale_placeholder != null:
		command_grid.remove_child(stale_placeholder)
		stale_placeholder.queue_free()
	var button := command_grid.get_node_or_null(button_name) as Button
	if button == null:
		button = Button.new()
		button.name = button_name
		button.focus_mode = Control.FOCUS_ALL
		command_grid.add_child(button)
	button.text = text
	button.tooltip_text = tooltip
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_meta("drop_light_command_placeholder", false)
	button.set_meta("command_matrix_slot_id", "16.%d" % slot_index)
	if callback.is_valid() and not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	_configure_square_hud_button(button, DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE"))
	META_UI_SKIN_SCRIPT.style_tactical_button(button, false)
	command_grid.move_child(button, slot_index - 1)


func _apply_compact_fireteam_info_text_contract() -> void:
	var info_vbox := get_node_or_null(FIRETEAM_INFO_VBOX_PATH) as Control
	if info_vbox != null:
		info_vbox.custom_minimum_size = Vector2.ZERO
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for path in [
		command_feedback_label_path,
		hotkey_legend_label_path,
		NodePath("%s/TacticalStancePanel/MarginContainer/VBoxContainer/SummaryLabel" % FIRETEAM_INFO_VBOX_PATH),
		NodePath("%s/FireteamStatusPanel/MarginContainer/HBoxContainer/SuppressionLabel" % FIRETEAM_INFO_VBOX_PATH),
		NodePath("%s/FireteamPhasePanel/MarginContainer/VBoxContainer/PhaseStatusLabel" % FIRETEAM_INFO_VBOX_PATH),
		NodePath("%s/FireteamPhasePanel/MarginContainer/VBoxContainer/PhaseListLabel" % FIRETEAM_INFO_VBOX_PATH),
	]:
		var label := get_node_or_null(path) as Label
		if label == null:
			continue
		label.custom_minimum_size = Vector2.ZERO
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.max_lines_visible = 1
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var status_progress := get_node_or_null("%s/FireteamStatusPanel/MarginContainer/HBoxContainer/SuppressionProgressLine" % FIRETEAM_INFO_VBOX_PATH) as Control
	if status_progress != null:
		status_progress.custom_minimum_size = Vector2(64.0, 22.0)


func _apply_fireteam_panel_action_button_contract() -> void:
	var action_button_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	var fireteam_info_vbox := get_node_or_null(FIRETEAM_INFO_VBOX_PATH) as Node
	if fireteam_info_vbox == null:
		return
	for node in fireteam_info_vbox.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		var stance_id: String = String(button.get_meta("tactical_stance_id", "")).strip_edges().to_lower()
		if not stance_id.is_empty():
			button.tooltip_text = _get_tactical_stance_button_text(stance_id)
			button.text = _get_tactical_stance_short_label(stance_id)
		elif button.name == "ReturnToPlanButton":
			button.tooltip_text = "Plan: kehrt nur aus Ad-hoc oder Unterbrechung in die geplante Wegpunktkette zurueck."
			button.text = "Plan"
		elif button.name != "GoPhaseButton":
			continue
		_configure_square_hud_button(button, action_button_size, 7)


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
		DELETE_ORDER_BUTTON_PATH,
		SORT_COMMAND_BUTTON_PATH,
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton",
		"../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton",
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
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null(DELETE_ORDER_BUTTON_PATH) as Button, _has_deletable_order_focus())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null(SORT_COMMAND_BUTTON_PATH) as Button, not preview_mode and _can_issue_local_commands() and not _selected_fireteam_ids.is_empty())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/GoCommandMatrixButton") as Button, not preview_mode and _can_issue_local_commands() and _has_selected_fireteam_orders_to_execute())
	META_UI_SKIN_SCRIPT.style_tactical_button(get_node_or_null("../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/PlanCommandMatrixButton") as Button, not preview_mode and _can_issue_local_commands() and _can_return_selected_fireteams_to_plan())
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
	_apply_fireteam_mini_overlay_style()


func _apply_fireteam_mini_overlay_style() -> void:
	var panel := get_node_or_null(FIRETEAM_MINI_PANEL_PATH) as PanelContainer
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = false
	panel.set_meta("mission_fireteam_mini_backgroundless", true)
	for path in [
		"../TacticalUI/FireteamMiniPanel/MiniMargin",
		"../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox",
		"../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll",
		"../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox",
	]:
		var passive_control := get_node_or_null(path) as Control
		if passive_control != null:
			passive_control.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _can_issue_local_commands() -> bool:
	return bool(_command_input_guard.call("can_issue_local_commands", get_node_or_null("../SimulationRoot"), multiplayer))


func _can_edit_planning() -> bool:
	return bool(_command_input_guard.call("can_edit_planning", preview_mode, get_node_or_null("../SimulationRoot"), multiplayer))


func _emit_planning_state_changed() -> void:
	planning_state_changed.emit(get_planning_state())


func get_selected_fireteam_ids() -> PackedStringArray:
	return _selected_fireteam_ids.duplicate()


func set_fireteamleader_feedback_bubbles_enabled(enabled: bool) -> void:
	var settings: Dictionary = get_fireteamleader_feedback_bubble_settings()
	settings["mode"] = COMIC_BUBBLE_SETTINGS_SCRIPT.MODE_NORMAL if enabled else COMIC_BUBBLE_SETTINGS_SCRIPT.MODE_OFF
	settings["ftl_command_feedback_enabled"] = enabled
	set_comic_bubble_settings(settings)


func get_fireteamleader_feedback_bubble_settings() -> Dictionary:
	var settings: Dictionary = Dictionary(_get_comic_bubble_runtime_gate().call("get_settings"))
	settings["enabled"] = bool(settings.get("enabled", true)) and fireteamleader_feedback_bubbles_enabled and bool(settings.get("ftl_command_feedback_enabled", true))
	return Dictionary(FIRETEAMLEADER_FEEDBACK_BUBBLE_RESOLVER_SCRIPT.call("normalize_settings", settings))


func set_comic_bubble_settings(settings: Dictionary) -> void:
	var normalized_settings: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("normalize_settings", settings))
	_get_comic_bubble_runtime_gate().call("set_settings", normalized_settings)
	fireteamleader_feedback_bubbles_enabled = bool(normalized_settings.get("enabled", true)) and bool(normalized_settings.get("ftl_command_feedback_enabled", true))
	if not fireteamleader_feedback_bubbles_enabled:
		_fireteamleader_feedback_bubbles.clear()
	if not bool(normalized_settings.get("enabled", true)) or not bool(normalized_settings.get("npc_thought_peek_enabled", true)):
		_npc_thought_bubbles.clear()
	_refresh_order_visuals()


func set_comic_bubble_mode(mode: String) -> void:
	var settings: Dictionary = Dictionary(_get_comic_bubble_runtime_gate().call("get_settings"))
	settings["mode"] = COMIC_BUBBLE_SETTINGS_SCRIPT.call("normalize_mode", mode)
	set_comic_bubble_settings(settings)


func get_comic_bubble_settings_snapshot() -> Dictionary:
	return Dictionary(_get_comic_bubble_runtime_gate().call("get_snapshot"))


func get_fireteamleader_feedback_bubble_snapshot() -> Array:
	if not fireteamleader_feedback_bubbles_enabled or not bool(Dictionary(_get_comic_bubble_runtime_gate().call("get_settings")).get("enabled", true)):
		return []
	_prune_fireteamleader_feedback_bubbles()
	var snapshot: Array = []
	for bubble_variant in _fireteamleader_feedback_bubbles:
		if typeof(bubble_variant) != TYPE_DICTIONARY:
			continue
		var bubble: Dictionary = Dictionary(bubble_variant).duplicate(true)
		_apply_fireteamleader_feedback_hud_anchor(bubble, String(bubble.get("fireteam_id", "")))
		snapshot.append(bubble)
	return snapshot


func set_npc_thought_peek_override(active: bool) -> void:
	_get_comic_bubble_runtime_gate().call("set_thought_peek_override", active)
	_refresh_npc_thought_bubbles(true)
	_refresh_order_visuals()


func clear_npc_thought_peek_override() -> void:
	_get_comic_bubble_runtime_gate().call("clear_thought_peek_override")
	_refresh_npc_thought_bubbles(true)
	_refresh_order_visuals()


func get_npc_thought_bubble_snapshot() -> Array:
	_refresh_npc_thought_bubbles(false)
	return _npc_thought_bubbles.duplicate(true)


func get_comic_bubble_visual_payload_snapshot() -> Array:
	var payloads: Array = []
	for bubble_variant in get_fireteamleader_feedback_bubble_snapshot():
		if typeof(bubble_variant) != TYPE_DICTIONARY:
			continue
		var bubble: Dictionary = Dictionary(bubble_variant).duplicate(true)
		_apply_fireteamleader_feedback_hud_anchor(bubble, String(bubble.get("fireteam_id", "")))
		payloads.append(bubble)
	payloads.append_array(get_npc_thought_bubble_snapshot())
	return payloads


func get_tactical_communication_event_snapshot() -> Array:
	return _tactical_communication_events.duplicate(true)


func get_tactical_event_log_snapshot(options: Dictionary = {}) -> Array:
	_ensure_tactical_event_log()
	if _tactical_event_log == null:
		return []
	return Array(_tactical_event_log.call("get_snapshot", options))


func get_tactical_event_log_contract_snapshot() -> Dictionary:
	_ensure_tactical_event_log()
	if _tactical_event_log == null:
		return {}
	return Dictionary(_tactical_event_log.call("get_contract_snapshot"))


func get_ftl_readiness_snapshot() -> Array:
	var entries: Array = []
	for fireteam_id_variant in _get_available_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		entries.append(_build_ftl_readiness_snapshot_for_fireteam(fireteam_id))
	return entries


func get_ftl_readiness_contract_snapshot() -> Dictionary:
	return {
		"schema_version": FTL_READINESS_SNAPSHOT_CONTRACT_SCRIPT.SCHEMA_VERSION,
		"value_ranges": FTL_READINESS_SNAPSHOT_CONTRACT_SCRIPT.call("get_value_ranges"),
		"read_only": true,
		"contains_node_reference": false,
	}


func _build_ftl_readiness_snapshot_for_fireteam(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var leader = _resolve_fireteam_leader_for_behavior(normalized_fireteam_id)
	var profile_dict: Dictionary = get_active_behavior_profile(normalized_fireteam_id)
	var assignment_dict: Dictionary = _find_multi_fireteam_assignment_for_fireteam(normalized_fireteam_id)
	return Dictionary(FTL_READINESS_SNAPSHOT_CONTRACT_SCRIPT.call(
		"build_snapshot",
		normalized_fireteam_id,
		leader,
		profile_dict,
		assignment_dict
	))


func get_tactical_breakout_snapshot() -> Array:
	return _tactical_breakout_records.duplicate(true)


func get_fireteam_coordination_snapshot() -> Array:
	var result: Array = []
	var coordination_ids: Array = _active_coordination_by_id.keys()
	coordination_ids.sort()
	for coordination_id_variant in coordination_ids:
		var assignment: Dictionary = Dictionary(_active_coordination_by_id.get(coordination_id_variant, {})).duplicate(true)
		if assignment.is_empty():
			continue
		result.append(assignment)
	return result


func get_air_asset_status_snapshot() -> Dictionary:
	_ensure_air_asset_status()
	if _air_asset_status == null or not _air_asset_status.has_method("to_snapshot"):
		return {}
	return Dictionary(_air_asset_status.call("to_snapshot")).duplicate(true)


func get_air_asset_threat_snapshot() -> Array:
	return _air_asset_threat_events.duplicate(true)


func set_air_asset_lz_secure_level_for_test(level: float) -> void:
	_air_asset_lz_secure_level = clampf(level, 0.0, 1.0)
	_ensure_air_asset_status()
	if _air_asset_status != null:
		_air_asset_status.lz_secure_level = _air_asset_lz_secure_level
	_update_ui()


func evaluate_air_asset_threat(context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	_ensure_air_asset_status()
	_ensure_air_asset_threat_resolver()
	if _air_asset_threat_resolver == null:
		return {}
	return Dictionary(_air_asset_threat_resolver.call("evaluate_threat", get_air_asset_status_snapshot(), _build_air_asset_threat_context(context), options))


func apply_air_asset_threat(context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var result: Dictionary = evaluate_air_asset_threat(context, options)
	if result.is_empty():
		return {}
	_store_air_asset_threat_event(result)
	if not bool(result.get("eligible", false)):
		_last_command_text = "AIR THREAT BLOCKED: %s" % str(result.get("blocked_reason", "")).to_upper()
		_update_ui()
		return result
	var next_status: Dictionary = Dictionary(result.get("next_status", {})).duplicate(true)
	_air_asset_status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", next_status)
	_enqueue_air_asset_status_effect(next_status, result)
	_record_air_asset_threat_communication(result)
	_record_air_asset_breakout(result)
	if bool(result.get("destroy_allow", result.get("destroy_allowed", false))):
		_last_command_text = "AIR ASSET LOST"
	elif bool(result.get("hit_allowed", false)):
		_last_command_text = "AIR ASSET HIT"
	else:
		_last_command_text = "AIR THREAT WARNING"
	_refresh_mission_dropship_panel()
	_refresh_world_overlays()
	_update_ui()
	return result


func record_tactical_breakout(trigger: String, fireteam_id: String = "", context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() and not _selected_fireteam_ids.is_empty():
		normalized_fireteam_id = str(_selected_fireteam_ids[0]).strip_edges().to_lower()
	var breakout_context: Dictionary = context.duplicate(true)
	breakout_context["trigger"] = trigger
	if not normalized_fireteam_id.is_empty():
		breakout_context["fireteam_id"] = normalized_fireteam_id
	var plan_context: Dictionary = _build_tactical_breakout_plan_context(normalized_fireteam_id, breakout_context)
	return _record_tactical_breakout(plan_context, breakout_context, options)


func record_tactical_breakout_from_context(context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var breakout_context: Dictionary = context.duplicate(true)
	var normalized_fireteam_id: String = str(breakout_context.get("fireteam_id", "")).strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() and not _selected_fireteam_ids.is_empty():
		normalized_fireteam_id = str(_selected_fireteam_ids[0]).strip_edges().to_lower()
	breakout_context["fireteam_id"] = normalized_fireteam_id
	var plan_context: Dictionary = _build_tactical_breakout_plan_context(normalized_fireteam_id, breakout_context)
	return _record_tactical_breakout(plan_context, breakout_context, options)


func resolve_tactical_breakout_return_to_plan(breakout_id: String, context: Dictionary = {}) -> Dictionary:
	_ensure_tactical_breakout_resolver()
	var normalized_id: String = breakout_id.strip_edges()
	if normalized_id.is_empty():
		return {}
	for index in range(_tactical_breakout_records.size()):
		var record: Dictionary = Dictionary(_tactical_breakout_records[index])
		if str(record.get("breakout_id", "")) != normalized_id:
			continue
		var returned: Dictionary = Dictionary(TACTICAL_BREAKOUT_RESOLVER_SCRIPT.call("mark_return_to_plan", record, context))
		_tactical_breakout_records[index] = returned
		if bool(returned.get("resolved", false)) and not bool(context.get("skip_runtime_return", false)):
			_return_fireteam_to_plan(str(returned.get("fireteam_id", "")), false)
			var event: Dictionary = Dictionary(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_event", TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_PHASE_COMPLETED, {
				"event_id": str(returned.get("return_to_plan_event_id", "")),
				"plan_id": str(returned.get("plan_id", "")),
				"fireteam_id": str(returned.get("fireteam_id", "")),
				"phase": int(returned.get("phase", 0)),
				"role": "return_to_plan",
				"step": str(returned.get("trigger", "")),
				"short_text": "RETURN PLAN",
				"detail_text": "Breakout resolved | return to plan",
				"priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_NORMAL,
			}, context))
			_record_tactical_communication_events([event], context)
		_update_ui()
		return returned
	return {}


func record_tactical_communication_event(event_type: String, context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	_ensure_tactical_communication_resolver()
	var event: Dictionary = Dictionary(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_event", event_type, context, options))
	var emitted_events: Array = _record_tactical_communication_events([event], options)
	if emitted_events.is_empty():
		return {}
	_refresh_order_visuals()
	_update_ui()
	return Dictionary(emitted_events[0])


func record_tactical_communication_events(events: Array, options: Dictionary = {}) -> Array:
	var emitted_events: Array = _record_tactical_communication_events(events, options)
	if not emitted_events.is_empty():
		_refresh_order_visuals()
		_update_ui()
	return emitted_events


func _record_tactical_breakout(plan_context: Dictionary, breakout_context: Dictionary, options: Dictionary = {}) -> Dictionary:
	_ensure_tactical_breakout_resolver()
	if _tactical_breakout_resolver == null:
		return {}
	var breakout: Dictionary = Dictionary(_tactical_breakout_resolver.call("evaluate_breakout", plan_context, breakout_context, options))
	if breakout.is_empty():
		return {}
	_store_tactical_breakout_record(breakout)
	var event: Dictionary = _build_tactical_breakout_communication_event(breakout, options)
	if not event.is_empty():
		_record_tactical_communication_events([event], options)
	_update_ui()
	return breakout


func _build_tactical_breakout_communication_event(breakout: Dictionary, options: Dictionary = {}) -> Dictionary:
	var status: String = String(breakout.get("status", "")).strip_edges().to_lower()
	var breakout_class: String = String(breakout.get("breakout_class", "")).strip_edges().to_lower()
	if status == "needs_orders" or breakout_class == "request_orders":
		var fireteam_id: String = String(breakout.get("fireteam_id", "")).strip_edges().to_lower()
		var fireteam_label: String = _get_fireteam_display_label(fireteam_id)
		if fireteam_label.is_empty():
			fireteam_label = fireteam_id.to_upper()
		return Dictionary(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_event", TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_NEEDS_ORDERS, {
			"event_id": str(breakout.get("event_id", "")),
			"plan_id": str(breakout.get("plan_id", "")),
			"fireteam_id": fireteam_id,
			"phase": int(breakout.get("phase", 0)),
			"role": "needs_orders",
			"step": str(breakout.get("trigger", "")),
			"short_text": "%s wartet auf Befehl" % fireteam_label,
			"detail_text": str(breakout.get("detail_text", "FTL requests commander input")),
			"map_label": "NEEDS ORDERS",
			"priority": int(breakout.get("priority", TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH)),
			"communication_clarity": float(breakout.get("communication_clarity", 0.5)),
			"anchor_position": breakout.get("anchor_position", null),
			"target_position": breakout.get("target_position", null),
		}, options))
	return Dictionary(TACTICAL_BREAKOUT_RESOLVER_SCRIPT.call("build_communication_event", breakout, options))


func _store_tactical_breakout_record(breakout: Dictionary) -> void:
	var retained_records: Array = []
	var breakout_id: String = str(breakout.get("breakout_id", ""))
	for existing_variant in _tactical_breakout_records:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		var existing: Dictionary = Dictionary(existing_variant)
		if str(existing.get("breakout_id", "")) == breakout_id:
			continue
		retained_records.append(existing)
	retained_records.append(breakout.duplicate(true))
	while retained_records.size() > 12:
		retained_records.pop_front()
	_tactical_breakout_records = retained_records


func _ensure_air_asset_status() -> void:
	if _air_asset_status != null:
		return
	var asset_id: String = _mission_drop_craft_id.strip_edges()
	if asset_id.is_empty():
		asset_id = "mission_dropship"
	var display_name: String = _mission_drop_display_name.strip_edges()
	if display_name.is_empty():
		display_name = "Mission Dropship"
	_air_asset_status = AIR_ASSET_STATUS_SCRIPT.call("from_dict", {
		"asset_id": asset_id,
		"asset_type": "dropship",
		"display_name": display_name,
		"state": "intact",
		"integrity": 100,
		"max_integrity": 100,
		"lz_secure_level": _air_asset_lz_secure_level,
		"position": _get_air_asset_position(),
		"metadata": {
			"source": "MissionTacticalSandboxController",
			"visual_only": false,
		},
	})


func _ensure_air_asset_threat_resolver() -> void:
	if _air_asset_threat_resolver == null:
		_air_asset_threat_resolver = AIR_ASSET_THREAT_RESOLVER_SCRIPT.new()


func _build_air_asset_threat_context(context: Dictionary) -> Dictionary:
	_ensure_air_asset_status()
	var status: Dictionary = get_air_asset_status_snapshot()
	var result: Dictionary = context.duplicate(true)
	result["asset_id"] = str(result.get("asset_id", status.get("asset_id", "mission_dropship"))).strip_edges()
	result["asset_type"] = str(result.get("asset_type", status.get("asset_type", "dropship"))).strip_edges()
	result["asset_position"] = result.get("asset_position", _get_air_asset_position())
	result["lz_secure_level"] = clampf(float(result.get("lz_secure_level", _air_asset_lz_secure_level)), 0.0, 1.0)
	result["has_line_of_sight"] = bool(result.get("has_line_of_sight", result.get("los", true)))
	result["visible_in_fow"] = bool(result.get("visible_in_fow", result.get("fow_visible", true)))
	result["altitude_layer"] = str(result.get("altitude_layer", result.get("height_layer", "low"))).strip_edges().to_lower()
	result["warning_seen"] = bool(result.get("warning_seen", bool(status.get("warning_visible", false)) or bool(AIR_ASSET_STATUS_SCRIPT.call("is_warning_state", str(status.get("state", ""))))))
	if not result.has("range_tiles"):
		result["range_tiles"] = float(result.get("distance_tiles", 10.0))
	if not result.has("enemy_at_pressure"):
		result["enemy_at_pressure"] = float(result.get("anti_armor_pressure", 0.5))
	if not result.has("enemy_security_pressure"):
		result["enemy_security_pressure"] = float(result.get("enemy_security", 0.25))
	return result


func _store_air_asset_threat_event(result: Dictionary) -> void:
	var retained_events: Array = []
	var threat_id: String = str(result.get("threat_id", result.get("event_id", ""))).strip_edges()
	for existing_variant in _air_asset_threat_events:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		var existing: Dictionary = Dictionary(existing_variant)
		if str(existing.get("threat_id", existing.get("event_id", ""))).strip_edges() == threat_id:
			continue
		retained_events.append(existing)
	retained_events.append(result.duplicate(true))
	while retained_events.size() > 12:
		retained_events.pop_front()
	_air_asset_threat_events = retained_events


func _record_air_asset_threat_communication(result: Dictionary) -> void:
	var trigger: String = str(result.get("tactical_breakout_trigger", "air_asset_threatened")).strip_edges()
	var event_type: String = TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED if trigger == "air_asset_destroyed" else TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED
	var status: Dictionary = Dictionary(result.get("next_status", {}))
	var state: String = str(result.get("next_state", status.get("state", ""))).strip_edges()
	var risk_percent: int = int(round(float(result.get("risk", 0.0)) * 100.0))
	record_tactical_communication_event(event_type, {
		"event_id": str(result.get("event_id", "")),
		"fireteam_id": _get_air_asset_feedback_fireteam_id(),
		"phase": _current_phase_index,
		"role": "air_asset",
		"step": state,
		"short_text": "AIR LOST" if event_type == TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED else "AIR THREAT",
		"detail_text": "%s %s | %s | risk %d%%" % [str(status.get("display_name", "Dropship")), state.to_upper(), str(result.get("weapon_id", "")), risk_percent],
		"map_label": "AIR LOST" if event_type == TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED else "AIR RISK",
		"target_position": _get_air_asset_position(),
		"anchor_position": _get_air_asset_position(),
		"priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL if event_type == TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED else TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH,
		"metadata": {
			"air_asset_status": status,
			"threat_id": str(result.get("threat_id", "")),
		},
	}, {"now_msec": Time.get_ticks_msec()})


func _record_air_asset_breakout(result: Dictionary) -> void:
	var trigger: String = str(result.get("tactical_breakout_trigger", "")).strip_edges()
	if trigger.is_empty():
		return
	record_tactical_breakout(trigger, _get_air_asset_feedback_fireteam_id(), {
		"air_asset_state": str(result.get("next_state", "")),
		"air_asset_threatened": trigger == "air_asset_threatened",
		"air_asset_destroyed": trigger == "air_asset_destroyed",
		"weapon_id": str(result.get("weapon_id", "")),
		"risk": float(result.get("risk", 0.0)),
		"sequence": str(result.get("event_id", "")),
		"target_position": _get_air_asset_position(),
		"allowed_breakout_classes": PackedStringArray(["auto_adapt", "hold_and_report", "request_orders", "abort_to_safe"]),
	})


func _enqueue_air_asset_status_effect(status_snapshot: Dictionary, result: Dictionary) -> void:
	if _dropship_effect_adapter == null or not _dropship_effect_adapter.has_method("enqueue_air_asset_status_effect"):
		return
	_dropship_effect_adapter.call("enqueue_air_asset_status_effect", get_node_or_null("../SimulationRoot"), status_snapshot, result)


func _get_air_asset_feedback_fireteam_id() -> String:
	if not _selected_fireteam_ids.is_empty():
		return str(_selected_fireteam_ids[0]).strip_edges().to_lower()
	var ids: PackedStringArray = _get_available_fireteam_ids()
	if not ids.is_empty():
		return str(ids[0]).strip_edges().to_lower()
	return "blue"


func _get_air_asset_position() -> Vector2:
	if _drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_LANDED or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING or _drop_sequence_phase == DROP_SEQUENCE_COMPLETE or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		return _drop_sequence_position
	if _has_lz_position:
		return _lz_position
	return _get_drop_staging_position()


func _build_tactical_breakout_plan_context(fireteam_id: String, context: Dictionary = {}) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var behavior_profile: Dictionary = get_active_behavior_profile(normalized_fireteam_id)
	var skill: Dictionary = _build_tactical_breakout_skill_context(normalized_fireteam_id, behavior_profile, context)
	var plan_context: Dictionary = {
		"plan_id": str(context.get("plan_id", "runtime_%s_p%d" % [normalized_fireteam_id if not normalized_fireteam_id.is_empty() else "none", _current_phase_index])),
		"command_id": str(context.get("command_id", _last_command_text)),
		"fireteam_id": normalized_fireteam_id,
		"phase": int(context.get("phase", _current_phase_index)),
		"target_position": context.get("target_position", _get_target_position()),
		"allowed_breakout_classes": PackedStringArray(context.get("allowed_breakout_classes", [
			"auto_adapt",
			"hold_and_report",
			"request_orders",
		])),
		"ftl_skill_factors": skill,
		"metadata": {
			"source": "MissionTacticalSandboxController",
			"visual_only": true,
		},
	}
	if not behavior_profile.is_empty():
		plan_context["behavior_profile"] = behavior_profile
	return plan_context


func _build_tactical_breakout_skill_context(fireteam_id: String, behavior_profile: Dictionary, context: Dictionary = {}) -> Dictionary:
	var metadata: Dictionary = Dictionary(behavior_profile.get("metadata", {}))
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	var leadership: float = float(context.get("leadership", 0.5))
	if leader != null and leader.has_method("get_leadership_skill"):
		leadership = float(leader.call("get_leadership_skill"))
	var breakout_judgement: float = clampf(float(context.get("breakout_judgement", metadata.get("breakout_judgement", leadership))), 0.0, 1.0)
	var communication_clarity: float = clampf(float(context.get("communication_clarity", metadata.get("communication_clarity", leadership))), 0.0, 1.0)
	return {
		"leadership": leadership,
		"planning_quality": clampf(float(context.get("planning_quality", metadata.get("planning_quality", leadership))), 0.0, 1.0),
		"breakout_judgement": breakout_judgement,
		"communication_clarity": communication_clarity,
		"reaction_delay_seconds": clampf(float(context.get("reaction_delay_seconds", lerpf(0.8, 0.12, breakout_judgement))), 0.05, 1.25),
	}


func _record_tactical_communication_events(events: Array, options: Dictionary = {}) -> Array:
	_ensure_tactical_communication_resolver()
	if _tactical_communication_resolver == null:
		return []
	var emitted_events: Array = Array(_tactical_communication_resolver.call("resolve_events", events, options))
	for event_variant in emitted_events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		_store_tactical_communication_event(Dictionary(event_variant))
	return emitted_events


func _store_tactical_communication_event(event: Dictionary) -> void:
	var event_id: String = String(event.get("event_id", "")).strip_edges()
	if event_id.is_empty():
		return
	var retained_events: Array = []
	for existing_variant in _tactical_communication_events:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		var existing: Dictionary = Dictionary(existing_variant)
		if String(existing.get("event_id", "")).strip_edges() == event_id:
			continue
		retained_events.append(existing)
	retained_events.append(event.duplicate(true))
	while retained_events.size() > 10:
		retained_events.pop_front()
	_tactical_communication_events = retained_events
	_store_tactical_event_log_entries([event])
	_maybe_store_tactical_communication_bubble(event)


func _maybe_store_tactical_communication_bubble(event: Dictionary) -> void:
	if not fireteamleader_feedback_bubbles_enabled:
		return
	var channels: PackedStringArray = PackedStringArray(event.get("channels", PackedStringArray()))
	if not channels.has(TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_FTL_BUBBLE):
		return
	var fireteam_id: String = String(event.get("fireteam_id", "")).strip_edges().to_lower()
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	var anchor_position_variant = event.get("anchor_position", null)
	if typeof(anchor_position_variant) != TYPE_VECTOR2:
		anchor_position_variant = _resolve_fireteamleader_feedback_anchor_position(leader, fireteam_id)
	if typeof(anchor_position_variant) != TYPE_VECTOR2:
		return
	var payload: Dictionary = Dictionary(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call(
		"build_bubble_payload",
		event,
		leader,
		Vector2(anchor_position_variant),
		get_fireteamleader_feedback_bubble_settings(),
		{
			"fireteam_id": fireteam_id,
			"unit_id": String(event.get("unit_id", "")),
			"fireteam_units": _get_units_for_fireteam(fireteam_id),
		}
	))
	if not bool(payload.get("ok", false)):
		return
	if not bool(_get_comic_bubble_runtime_gate().call("should_emit_payload", payload, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK)):
		return
	_store_fireteamleader_feedback_bubble(payload)


func _build_selected_tactical_communication_text() -> String:
	return String(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_selected_fireteam_text", _tactical_communication_events, _selected_fireteam_ids, 2)).strip_edges()


func _build_mission_control_tactical_communication_text() -> String:
	return String(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_mission_control_text", _tactical_communication_events, 2)).strip_edges()


func _store_tactical_event_log_entries(events: Array) -> void:
	_ensure_tactical_event_log()
	if _tactical_event_log == null:
		return
	_tactical_event_log.call("ingest_tactical_communication_events", events)


func record_fireteamleader_feedback_bubble_for_unit(
	feedback_action: String,
	feedback_state: String,
	leader,
	fireteam_id: String = "",
	detail: String = ""
) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() and leader != null and leader.has_method("get_fireteam_id"):
		normalized_fireteam_id = String(leader.call("get_fireteam_id")).strip_edges().to_lower()
	var anchor_position_variant: Variant = _resolve_fireteamleader_feedback_anchor_position(leader, normalized_fireteam_id)
	if typeof(anchor_position_variant) != TYPE_VECTOR2:
		return {}
	var unit_id: String = String(leader.call("get_unit_id")).strip_edges() if leader != null and leader.has_method("get_unit_id") else ""
	var payload: Dictionary = Dictionary(FIRETEAMLEADER_FEEDBACK_BUBBLE_RESOLVER_SCRIPT.call(
		"build_command_feedback",
		feedback_action,
		feedback_state,
		leader,
		Vector2(anchor_position_variant),
		get_fireteamleader_feedback_bubble_settings(),
		{
			"fireteam_id": normalized_fireteam_id,
			"unit_id": unit_id,
			"detail": detail,
			"fireteam_units": _get_units_for_fireteam(normalized_fireteam_id),
		}
	))
	if not bool(payload.get("ok", false)):
		return {}
	if not bool(_get_comic_bubble_runtime_gate().call("should_emit_payload", payload, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK)):
		return {}
	_store_fireteamleader_feedback_bubble(payload)
	return payload


func _record_fireteamleader_feedback_for_selected_fireteams(feedback_action: String, feedback_state: String, detail: String = "") -> void:
	_record_fireteamleader_feedback_for_fireteam_ids(_selected_fireteam_ids, feedback_action, feedback_state, detail)


func _record_fireteamleader_feedback_for_fireteam_ids(fireteam_ids: PackedStringArray, feedback_action: String, feedback_state: String, detail: String = "") -> void:
	for fireteam_id_variant in fireteam_ids:
		var normalized_fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if normalized_fireteam_id.is_empty():
			continue
		_record_fireteamleader_feedback_for_fireteam(normalized_fireteam_id, feedback_action, feedback_state, detail)


func _record_fireteamleader_feedback_for_fireteam(fireteam_id: String, feedback_action: String, feedback_state: String, detail: String = "") -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var leader = _resolve_fireteam_leader_for_behavior(normalized_fireteam_id)
	return record_fireteamleader_feedback_bubble_for_unit(feedback_action, feedback_state, leader, normalized_fireteam_id, detail)


func _resolve_fireteamleader_feedback_anchor_position(leader, fireteam_id: String) -> Variant:
	if leader is Node2D:
		return (leader as Node2D).global_position
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if not normalized_fireteam_id.is_empty():
		var fireteam_anchor_position: Variant = _resolve_fireteam_visual_anchor_position(normalized_fireteam_id)
		if typeof(fireteam_anchor_position) == TYPE_VECTOR2:
			return Vector2(fireteam_anchor_position)
	return null


func _apply_fireteamleader_feedback_hud_anchor(payload: Dictionary, fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		normalized_fireteam_id = String(payload.get("fireteam_id", "")).strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	var hud_anchor_variant: Variant = _resolve_fireteam_mini_card_bubble_anchor_position(normalized_fireteam_id)
	if typeof(hud_anchor_variant) != TYPE_VECTOR2:
		return
	payload["anchor_space"] = "hud"
	payload["hud_anchor_source"] = "fireteam_mini_card"
	payload["hud_anchor_position"] = Vector2(hud_anchor_variant)


func _resolve_fireteam_mini_card_bubble_anchor_position(fireteam_id: String) -> Variant:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return null
	var card_host := get_node_or_null(FIRETEAM_MINI_CARDS_VBOX_PATH) as VBoxContainer
	if card_host == null:
		return null
	for child in card_host.get_children():
		var card := child as Control
		if card == null:
			continue
		if String(card.get_meta("fireteam_id", "")).strip_edges().to_lower() != normalized_fireteam_id:
			continue
		var rect: Rect2 = card.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return null
		return rect.position + Vector2(rect.size.x + 6.0, clampf(rect.size.y * 0.42, 22.0, 38.0))
	return null


func _store_fireteamleader_feedback_bubble(payload: Dictionary) -> void:
	if not fireteamleader_feedback_bubbles_enabled:
		return
	_prune_fireteamleader_feedback_bubbles()
	var normalized_payload: Dictionary = payload.duplicate(true)
	if not _normalize_fireteamleader_feedback_speaker(normalized_payload):
		return
	_apply_fireteamleader_feedback_hud_anchor(normalized_payload, String(normalized_payload.get("fireteam_id", "")))
	normalized_payload["z_index"] = maxi(int(normalized_payload.get("z_index", 0)), 420)
	if not normalized_payload.has("max_size"):
		normalized_payload["max_size"] = Vector2i(148, 52)
	var now_msec: int = Time.get_ticks_msec()
	var duration_seconds: float = clampf(float(normalized_payload.get("duration_seconds", 1.8)), 0.4, 6.0)
	normalized_payload["created_at_msec"] = now_msec
	normalized_payload["expires_at_msec"] = now_msec + maxi(roundi(duration_seconds * 1000.0), 250)
	_fireteamleader_feedback_sequence += 1
	normalized_payload["feedback_sequence"] = _fireteamleader_feedback_sequence
	var identity_key: String = _build_fireteamleader_feedback_identity(normalized_payload)
	var retained_bubbles: Array = []
	for existing_variant in _fireteamleader_feedback_bubbles:
		if typeof(existing_variant) != TYPE_DICTIONARY:
			continue
		var existing_payload: Dictionary = Dictionary(existing_variant).duplicate(true)
		if _build_fireteamleader_feedback_identity(existing_payload) == identity_key:
			continue
		retained_bubbles.append(existing_payload)
	retained_bubbles.append(normalized_payload)
	var settings: Dictionary = get_fireteamleader_feedback_bubble_settings()
	var max_total: int = maxi(int(settings.get("max_active_bubbles_total", 4)), 1)
	while retained_bubbles.size() > max_total:
		retained_bubbles.remove_at(_find_lowest_priority_fireteamleader_feedback_index(retained_bubbles))
	_fireteamleader_feedback_bubbles = retained_bubbles


func _prune_fireteamleader_feedback_bubbles(now_msec: int = -1) -> bool:
	if _fireteamleader_feedback_bubbles.is_empty():
		return false
	var resolved_now_msec: int = Time.get_ticks_msec() if now_msec < 0 else now_msec
	var retained_bubbles: Array = []
	var changed: bool = false
	for bubble_variant in _fireteamleader_feedback_bubbles:
		if typeof(bubble_variant) != TYPE_DICTIONARY:
			changed = true
			continue
		var bubble: Dictionary = Dictionary(bubble_variant).duplicate(true)
		var expires_at_msec: int = int(bubble.get("expires_at_msec", 0))
		if expires_at_msec > 0 and resolved_now_msec >= expires_at_msec:
			changed = true
			continue
		retained_bubbles.append(bubble)
	if changed:
		_fireteamleader_feedback_bubbles = retained_bubbles
	return changed


func _normalize_fireteamleader_feedback_speaker(payload: Dictionary) -> bool:
	var fireteam_id: String = String(payload.get("fireteam_id", "")).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return false
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	if leader == null or not leader.has_method("get_unit_id"):
		return false
	var leader_unit_id: String = String(leader.call("get_unit_id")).strip_edges()
	if leader_unit_id.is_empty():
		return false
	var payload_unit_id: String = String(payload.get("unit_id", "")).strip_edges()
	if not payload_unit_id.is_empty() and payload_unit_id != leader_unit_id:
		return false
	payload["unit_id"] = leader_unit_id
	payload["speaker_role"] = "fireteamleader"
	payload["leader_only_bubble"] = true
	return true


func _build_fireteamleader_feedback_identity(payload: Dictionary) -> String:
	var unit_id: String = String(payload.get("unit_id", "")).strip_edges()
	if not unit_id.is_empty():
		return "unit:%s" % unit_id
	var fireteam_id: String = String(payload.get("fireteam_id", "")).strip_edges().to_lower()
	if not fireteam_id.is_empty():
		return "fireteam:%s" % fireteam_id
	return "bubble:%s" % String(payload.get("feedback_sequence", payload.get("bubble_id", ""))).strip_edges()


func _find_lowest_priority_fireteamleader_feedback_index(bubbles: Array) -> int:
	var lowest_index: int = 0
	var lowest_priority: int = 999999
	for index in range(bubbles.size()):
		var payload: Dictionary = Dictionary(bubbles[index]) if typeof(bubbles[index]) == TYPE_DICTIONARY else {}
		var priority: int = _get_fireteamleader_feedback_priority(payload)
		if priority < lowest_priority:
			lowest_priority = priority
			lowest_index = index
	return lowest_index


func _get_fireteamleader_feedback_priority(payload: Dictionary) -> int:
	if payload.has("priority"):
		return int(payload.get("priority", 0))
	var state: String = String(payload.get("feedback_state", "")).strip_edges().to_lower()
	if state == "blocked" and not String(payload.get("validation_key", "")).strip_edges().is_empty():
		return 120
	match state:
		"blocked", "contact":
			return 100
		"done", "cover":
			return 80
		"running":
			return 50
		_:
			return 20


func _update_npc_thought_peek_visuals() -> void:
	var active: bool = bool(_get_comic_bubble_runtime_gate().call("is_thought_peek_active"))
	if active == _npc_thought_peek_active_last_frame:
		return
	_npc_thought_peek_active_last_frame = active
	_refresh_npc_thought_bubbles(true)
	_refresh_order_visuals()


func _refresh_npc_thought_bubbles(force_refresh: bool = false) -> void:
	var gate = _get_comic_bubble_runtime_gate()
	if not bool(gate.call("is_thought_peek_active")):
		if not _npc_thought_bubbles.is_empty():
			_npc_thought_bubbles.clear()
		_npc_thought_bubble_refresh_msec = 0
		return
	var now_msec: int = Time.get_ticks_msec()
	if not force_refresh and not _npc_thought_bubbles.is_empty() and now_msec - _npc_thought_bubble_refresh_msec < 500:
		return
	var candidates: Array = _get_npc_thought_candidate_units()
	var settings: Dictionary = Dictionary(gate.call("get_settings"))
	var thought_limit: int = maxi(int(settings.get("max_thought_bubbles_total", 4)), 0)
	settings["max_active_bubbles_total"] = mini(maxi(int(settings.get("max_active_bubbles_total", 4)), 0), thought_limit)
	var raw_payloads: Array = Array(NPC_THOUGHT_BUBBLE_RESOLVER_SCRIPT.call("build_thoughts_for_units", candidates, settings, {"selected_fireteam_ids": _selected_fireteam_ids}))
	var filtered_payloads: Array = Array(gate.call("filter_payloads", raw_payloads, COMIC_BUBBLE_SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK, now_msec))
	if thought_limit > 0 and filtered_payloads.size() > thought_limit:
		filtered_payloads = filtered_payloads.slice(0, thought_limit)
	_npc_thought_bubbles = filtered_payloads
	_npc_thought_bubble_refresh_msec = now_msec


func _get_npc_thought_candidate_units() -> Array:
	var selected_lookup: Dictionary = {}
	for fireteam_id_variant in _selected_fireteam_ids:
		var selected_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not selected_id.is_empty():
			selected_lookup[selected_id] = true
	var result: Array = []
	for unit in _get_all_friendly_units(false):
		if unit == null or not (unit is Node2D) or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if not selected_lookup.is_empty() and not selected_lookup.has(fireteam_id):
			continue
		result.append(unit)
	if not result.is_empty():
		return result
	for unit in _get_all_friendly_units(true):
		if unit is Node2D:
			result.append(unit)
	return result


func get_unit_presence_audit_snapshot() -> Dictionary:
	var unit_registry = get_node_or_null("../UnitRegistry")
	var friendly_entries: Array = _build_unit_presence_audit_entries(_get_all_friendly_units(true), unit_registry)
	var enemy_entries: Array = _build_unit_presence_audit_entries(_get_all_enemy_units(true), unit_registry)
	var all_entries: Array = friendly_entries + enemy_entries
	return {
		"friendly_units": friendly_entries,
		"enemy_units": enemy_entries,
		"active_unit_ids": _extract_presence_audit_unit_ids(all_entries, "registry_active", true),
		"active_friendly_unit_ids": _extract_presence_audit_unit_ids(friendly_entries, "registry_active", true),
		"active_enemy_unit_ids": _extract_presence_audit_unit_ids(enemy_entries, "registry_active", true),
		"visible_unit_ids": _extract_presence_audit_unit_ids(all_entries, "visible", true),
		"hidden_registered_unit_ids": _extract_hidden_registered_presence_unit_ids(all_entries),
		"inactive_enemy_unit_ids": _extract_presence_audit_unit_ids(enemy_entries, "registry_active", false),
		"embarked_unit_ids": _build_sorted_drop_unit_id_array(_embarked_unit_ids),
		"deployed_unit_ids": _build_sorted_drop_unit_id_array(_deployed_unit_ids),
	}


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
		if _select_tile_from_screen_position(screen_position):
			return true
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
	_focus_primary_view_on_selected_fireteams()


func _try_center_fireteam_from_map_click(screen_position: Vector2, ctrl_pressed: bool) -> bool:
	var unit = _find_selectable_unit_at_screen_position(screen_position)
	if unit != null:
		_apply_unit_click_selection(unit, ctrl_pressed)
		_last_command_text = "CENTER %s" % _get_fireteam_name().to_upper()
		_update_ui()
		return true
	if _selected_fireteam_ids.is_empty():
		return false
	if not _focus_primary_view_on_selected_fireteams():
		return false
	_last_command_text = "CENTER %s" % _get_fireteam_name().to_upper()
	_update_ui()
	return true


func _focus_primary_view_on_selected_fireteams() -> bool:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view == null or not primary_3d_view.has_method("focus_world_position"):
		return false
	var center := Vector2.ZERO
	var anchor_count: int = 0
	for fireteam_id_variant in _selected_fireteam_ids:
		var anchor := _get_selection_anchor_for_fireteam(String(fireteam_id_variant))
		if anchor == null:
			continue
		center += anchor.global_position
		anchor_count += 1
	if anchor_count <= 0:
		return false
	primary_3d_view.call("focus_world_position", center / float(anchor_count))
	return true


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
	_update_focused_fireteam_from_selection()
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


func _update_focused_fireteam_from_selection() -> void:
	if _selected_fireteam_ids.is_empty():
		_focused_fireteam_id = ""
		return
	if _selected_fireteam_ids.size() == 1:
		_focused_fireteam_id = String(_selected_fireteam_ids[0]).strip_edges().to_lower()
		return
	if not _focused_fireteam_id.is_empty() and _selected_fireteam_ids.has(_focused_fireteam_id):
		return
	_focused_fireteam_id = String(_selected_fireteam_ids[0]).strip_edges().to_lower()


func _refresh_selection_visuals() -> void:
	_selection_adapter.call("apply_unit_selection", _get_all_friendly_units(true), _selected_fireteam_ids)
	_refresh_tile_selection_visuals()


func _sync_unit_tactical_stance_badges() -> void:
	var sync_state: Dictionary = get_tactical_stance_sync_state()
	var stance_revision: int = maxi(int(sync_state.get("revision", 0)), 0)
	for unit in _get_all_friendly_units(true):
		if unit == null or not unit.has_method("set_tactical_stance_indicator") or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		unit.call("set_tactical_stance_indicator", get_requested_tactical_stance(fireteam_id), stance_revision)


func _sync_unit_overwatch_badges() -> void:
	var units_by_id: Dictionary = {}
	var ready_snapshot: Dictionary = get_overwatch_member_ready_snapshot()
	for unit in _get_all_friendly_units(true):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		unit.set_meta("overwatch_ready", false)
		unit.set_meta("overwatch_fireteam_id", "")
		unit.set_meta("overwatch_security_mode", "")
		unit.set_meta("overwatch_shot_ready", false)
		unit.set_meta("overwatch_cooldown_remaining_ticks", 0)
		units_by_id[unit_id] = unit
	for security_state_variant in get_fireteam_security_snapshot():
		if typeof(security_state_variant) != TYPE_DICTIONARY:
			continue
		var security_state: Dictionary = Dictionary(security_state_variant)
		if not bool(security_state.get("overwatch_ready", false)) or not bool(security_state.get("is_active", false)):
			continue
		var fireteam_id: String = String(security_state.get("fireteam_id", "")).strip_edges().to_lower()
		var security_mode: String = String(security_state.get("security_mode", "")).strip_edges().to_lower()
		for unit_id_variant in PackedStringArray(security_state.get("overwatch_unit_ids", PackedStringArray())):
			var unit_id: String = String(unit_id_variant).strip_edges()
			if unit_id.is_empty() or not units_by_id.has(unit_id):
				continue
			var unit: Node = units_by_id.get(unit_id)
			var ready_state: Dictionary = Dictionary(ready_snapshot.get(unit_id, {}))
			unit.set_meta("overwatch_ready", true)
			unit.set_meta("overwatch_fireteam_id", fireteam_id)
			unit.set_meta("overwatch_security_mode", security_mode)
			unit.set_meta("overwatch_shot_ready", bool(ready_state.get("ready", true)))
			unit.set_meta("overwatch_cooldown_remaining_ticks", int(ready_state.get("cooldown_remaining_ticks", 0)))


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
		var child_team_id: String = String(child.call("get_team_id")).strip_edges()
		if child_team_id == FRIENDLY_TEAM_ID or child_team_id.is_empty() or child_team_id == "team_unused":
			continue
		if not include_hidden and child is CanvasItem and not (child as CanvasItem).visible:
			continue
		result.append(child)
	return result


func _build_unit_presence_audit_entries(units: Array, unit_registry) -> Array:
	var entries: Array = []
	for unit in units:
		var entry: Dictionary = _build_unit_presence_audit_entry(unit, unit_registry)
		if not entry.is_empty():
			entries.append(entry)
	entries.sort_custom(Callable(self, "_sort_unit_presence_audit_entries"))
	return entries


func _build_unit_presence_audit_entry(unit, unit_registry) -> Dictionary:
	if unit == null or not unit.has_method("get_unit_id"):
		return {}
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	if unit_id.is_empty():
		return {}
	var entry: Dictionary = {
		"unit_id": unit_id,
		"team_id": String(unit.call("get_team_id")).strip_edges() if unit.has_method("get_team_id") else "",
		"fireteam_id": String(unit.call("get_fireteam_id")).strip_edges().to_lower() if unit.has_method("get_fireteam_id") else "",
		"visible": bool((unit as CanvasItem).visible) if unit is CanvasItem else unit.is_inside_tree(),
		"registry_active": _is_presence_audit_unit_registered(unit_registry, unit_id),
		"node_path": String(unit.get_path()),
		"vital_state": String(unit.call("get_vital_state")).strip_edges().to_lower() if unit.has_method("get_vital_state") else "",
		"runtime_state": "",
		"role_id": String(unit.call("get_role_id")).strip_edges() if unit.has_method("get_role_id") else "",
		"weapon_1_id": String(unit.call("get_weapon_1_id")).strip_edges() if unit.has_method("get_weapon_1_id") else "",
		"weapon_2_id": String(unit.call("get_weapon_2_id")).strip_edges() if unit.has_method("get_weapon_2_id") else "",
	}
	if unit.has_method("get_runtime_status"):
		var runtime_status = unit.call("get_runtime_status")
		if runtime_status != null and runtime_status.has_method("to_dict"):
			var runtime_dict: Dictionary = runtime_status.call("to_dict")
			entry["runtime_state"] = String(runtime_dict.get("status", "")).strip_edges()
	return entry


func _is_presence_audit_unit_registered(unit_registry, unit_id: String) -> bool:
	if unit_registry == null or unit_id.is_empty():
		return false
	if unit_registry.has_method("has_unit"):
		return bool(unit_registry.call("has_unit", unit_id))
	if unit_registry.has_method("get_unit"):
		return unit_registry.call("get_unit", unit_id) != null
	return false


func _extract_presence_audit_unit_ids(entries: Array, key: String, expected_value: bool) -> Array:
	var unit_ids: Array = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get(key, false)) != expected_value:
			continue
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _extract_hidden_registered_presence_unit_ids(entries: Array) -> Array:
	var unit_ids: Array = []
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if not bool(entry.get("registry_active", false)) or bool(entry.get("visible", false)):
			continue
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _sort_unit_presence_audit_entries(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))


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
		var damage_delta: int = previous_health - current_health
		gain += SUPPRESSION_HIT_GAIN + clampf(float(damage_delta) / 8.0, 0.25, 2.5)
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
	var anchor = _get_selection_anchor_for_fireteam(fireteam_id)
	record_tactical_breakout("suppressed_pinned", fireteam_id, {
		"is_suppressed": true,
		"anchor_position": anchor.global_position if anchor != null else _get_target_position(),
		"sequence": Time.get_ticks_msec(),
	}, {"now_msec": Time.get_ticks_msec()})


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
	var breakout_id_to_resolve: String = ""
	for record_variant in _tactical_breakout_records:
		if typeof(record_variant) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = Dictionary(record_variant)
		if str(record.get("fireteam_id", "")) != fireteam_id:
			continue
		if str(record.get("trigger", "")) != "suppressed_pinned" or bool(record.get("resolved", false)):
			continue
		breakout_id_to_resolve = str(record.get("breakout_id", ""))
		break
	if not breakout_id_to_resolve.is_empty():
		resolve_tactical_breakout_return_to_plan(breakout_id_to_resolve, {"reason": "suppression_clear", "now_msec": Time.get_ticks_msec(), "skip_runtime_return": true})


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
	if overlay != null:
		if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
			overlay.visible = false
		else:
			overlay.position = selection_rect.position
			overlay.size = selection_rect.size
			overlay.visible = true
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("set_area_order_preview_payload"):
		if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
			_area_order_preview_signature = ""
			primary_3d_view.call("set_area_order_preview_payload", {})
			var hidden_visualizer_clear := get_node_or_null("../FireteamOrderVisualizer")
			if hidden_visualizer_clear != null and hidden_visualizer_clear.has_method("set_area_order_preview_payload"):
				hidden_visualizer_clear.call("set_area_order_preview_payload", {})
			return
		if not _should_refresh_area_order_preview_payload(selection_rect):
			return
		var preview_payload_3d: Dictionary = {}
		preview_payload_3d = _build_area_order_payload_from_screen_rect(selection_rect)
		primary_3d_view.call("set_area_order_preview_payload", preview_payload_3d)
		var hidden_visualizer := get_node_or_null("../FireteamOrderVisualizer")
		if hidden_visualizer != null and hidden_visualizer.has_method("set_area_order_preview_payload"):
			hidden_visualizer.call("set_area_order_preview_payload", {})
		return
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer != null and visualizer.has_method("set_area_order_preview_payload"):
		if selection_rect.size.x <= 0.0 or selection_rect.size.y <= 0.0:
			visualizer.call("set_area_order_preview_payload", {})
		else:
			var preview_payload: Dictionary = _build_area_order_payload_from_screen_rect(selection_rect)
			if not preview_payload.is_empty():
				visualizer.call("set_area_order_preview_payload", preview_payload)
				return
			visualizer.call("set_area_order_preview_payload", {})


func _should_refresh_area_order_preview_payload(selection_rect: Rect2) -> bool:
	var next_signature: String = _build_area_order_preview_signature(selection_rect)
	var now_msec: int = Time.get_ticks_msec()
	if next_signature == _area_order_preview_signature:
		return false
	if not _area_order_preview_signature.is_empty() and now_msec - _area_order_preview_last_update_msec < AREA_ORDER_PREVIEW_REFRESH_MSEC:
		return false
	_area_order_preview_signature = next_signature
	_area_order_preview_last_update_msec = now_msec
	return true


func _build_area_order_preview_signature(selection_rect: Rect2) -> String:
	var step: float = maxf(AREA_ORDER_PREVIEW_SIGNATURE_STEP, 1.0)
	return "%d,%d,%d,%d" % [
		roundi(selection_rect.position.x / step),
		roundi(selection_rect.position.y / step),
		roundi(selection_rect.end.x / step),
		roundi(selection_rect.end.y / step),
	]


func get_order_plans_snapshot() -> Array:
	return _serialize_order_plans()


func get_area_orders_snapshot() -> Array:
	return _serialize_area_orders()


func get_multi_fireteam_plan_snapshot() -> Array:
	return _serialize_multi_fireteam_plans()


func get_visualized_waypoints_snapshot() -> Array:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_visible_waypoints"):
		return []
	return Array(visualizer.call("get_visible_waypoints"))


func get_waypoint_intent_preview_snapshot() -> Array:
	return _build_waypoint_intent_preview_entries()


func get_waypoint_intent_preview_contract_snapshot() -> Dictionary:
	var entries: Array = get_waypoint_intent_preview_snapshot()
	return {
		"entry_count": entries.size(),
		"entries": entries,
		"source": "WaypointIntentPreviewResolver",
		"eta_state": "estimated",
		"risk_policy": "unknown_until_morale_or_fatigue_data_exists",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func get_visualized_area_orders_snapshot() -> Array:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	if visualizer == null or not visualizer.has_method("get_visible_area_orders"):
		return []
	return Array(visualizer.call("get_visible_area_orders"))


func get_fire_sector_overlay_snapshot() -> Dictionary:
	var visualizer := get_node_or_null("../FireteamOrderVisualizer")
	var visualizer_snapshot: Dictionary = {}
	if visualizer != null and visualizer.has_method("get_security_overlay_snapshot"):
		visualizer_snapshot = Dictionary(visualizer.call("get_security_overlay_snapshot"))
	var primary_snapshot: Dictionary = {}
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("get_render_snapshot"):
		var render_snapshot: Dictionary = Dictionary(primary_3d_view.call("get_render_snapshot"))
		primary_snapshot = {
			"enabled": bool(render_snapshot.get("friendly_fire_sector_overlay_enabled", false)),
			"visual_count": int(render_snapshot.get("friendly_aim_visual_count", 0)),
			"visual_mode": String(render_snapshot.get("friendly_fire_sector_visual_mode", "")),
			"scan_mode": String(render_snapshot.get("friendly_fire_sector_scan_mode", "")),
			"los_line_count": int(render_snapshot.get("friendly_fire_sector_los_line_count", 0)),
		}
	return {
		"enabled": _fire_sector_overlay_enabled,
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"visualizer": visualizer_snapshot,
		"primary_3d": primary_snapshot,
		"contact_visibility_policy": "enemy_highlights_require_contact_or_fow_visibility",
		"read_only": true,
	}


func get_los_debug_overlay_snapshot() -> Dictionary:
	var primary_snapshot: Dictionary = {}
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("get_render_snapshot"):
		var render_snapshot: Dictionary = Dictionary(primary_3d_view.call("get_render_snapshot"))
		primary_snapshot = {
			"enabled": bool(render_snapshot.get("mission_los_debug_overlay_enabled", false)),
			"line_count": int(render_snapshot.get("mission_los_debug_line_count", 0)),
			"clear_line_count": int(render_snapshot.get("mission_los_debug_clear_line_count", 0)),
			"blocked_line_count": int(render_snapshot.get("mission_los_debug_blocked_line_count", 0)),
			"sample_limit": int(render_snapshot.get("mission_los_debug_sample_limit", 0)),
			"bounded_skipped_count": int(render_snapshot.get("mission_los_debug_bounded_skipped_count", 0)),
			"fow_hidden_contact_count": int(render_snapshot.get("mission_los_debug_fow_hidden_contact_count", 0)),
			"contact_visibility_policy": String(render_snapshot.get("mission_los_debug_contact_visibility_policy", "")),
		}
	return {
		"enabled": _los_debug_overlay_enabled,
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"primary_3d": primary_snapshot,
		"contact_visibility_policy": "selected_fireteams_known_contacts_fow_last_known_only",
		"read_only": true,
	}


func get_contact_density_heatmap_snapshot() -> Dictionary:
	var primary_snapshot: Dictionary = {}
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null and primary_3d_view.has_method("get_render_snapshot"):
		var render_snapshot: Dictionary = Dictionary(primary_3d_view.call("get_render_snapshot"))
		primary_snapshot = Dictionary(render_snapshot.get("contact_density_heatmap", {}))
	return {
		"enabled": _contact_density_heatmap_enabled,
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"primary_3d": primary_snapshot,
		"heat_cell_count": int(primary_snapshot.get("heat_cell_count", 0)),
		"source_contact_count": int(primary_snapshot.get("source_contact_count", 0)),
		"fow_hidden_count": int(primary_snapshot.get("fow_hidden_count", 0)),
		"contact_visibility_policy": "current_or_last_known_contacts_after_visual_fow_filter",
		"read_only": true,
	}


func get_cover_effectiveness_readout_snapshot() -> Dictionary:
	var fireteam_id: String = _get_cover_readout_fireteam_id()
	var selected_tile_readout: Dictionary = _build_selected_tile_cover_effectiveness_readout()
	var contact_readouts: Array = _build_contact_cover_effectiveness_readouts(fireteam_id)
	var primary_readout: Dictionary = selected_tile_readout
	if not contact_readouts.is_empty():
		primary_readout = Dictionary(contact_readouts[0]).duplicate(true)
	return {
		"readout_state": String(primary_readout.get("readout_state", "unknown")),
		"primary": primary_readout,
		"selected_tile": selected_tile_readout,
		"contacts": contact_readouts,
		"readout_text": _format_cover_effectiveness_readout_text(primary_readout),
		"combat_truth_source": String(primary_readout.get("combat_truth_source", "")),
		"selected_fireteam_id": fireteam_id,
		"read_only": true,
		"ui_may_execute_commands": false,
	}


func _get_cover_readout_fireteam_id() -> String:
	if not _selected_fireteam_ids.is_empty():
		return String(_selected_fireteam_ids[0]).strip_edges().to_lower()
	var selected_fireteam_id: String = _get_selected_fireteam_id()
	return selected_fireteam_id.strip_edges().to_lower()


func _build_selected_tile_cover_effectiveness_readout() -> Dictionary:
	if not _has_selected_tile:
		return _build_unknown_cover_effectiveness_readout("no_selected_tile", "", "selected_tile")
	var cover_score: int = clampi(int(round(_estimate_cover_score_at_world_position(_selected_tile_world_position))), 0, 100)
	return {
		"readout_type": "selected_tile",
		"readout_state": "estimated",
		"source": "TerrainRegistry",
		"combat_truth_source": "terrain_snapshot_only",
		"read_only": true,
		"ui_may_execute_commands": false,
		"grid_position": _selected_tile_grid_position,
		"grid_text": _format_grid_position(_selected_tile_grid_position),
		"world_position": _selected_tile_world_position,
		"raw_cover_score": cover_score,
		"raw_cover_state": _resolve_cover_effectiveness_state(cover_score),
		"effective_cover_score": cover_score,
		"effective_cover_state": _resolve_cover_effectiveness_state(cover_score),
		"cover_state": _resolve_cover_effectiveness_state(cover_score),
		"range_state": "unknown",
		"los_state": "unknown",
		"flank_state": "unknown",
		"flank_relevant": false,
		"attack_quality_label": "terrain_only",
	}


func _build_contact_cover_effectiveness_readouts(fireteam_id: String) -> Array:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return []
	var combat_driver = _get_combat_loop_driver()
	if combat_driver == null or not combat_driver.has_method("build_cover_effectiveness_readout_for_contact"):
		return []
	var result: Array = []
	for contact_variant in get_fireteam_contact_snapshot(normalized_fireteam_id):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var detection_state: String = String(contact.get("detection_state", "")).strip_edges().to_lower()
		var target_unit_id: String = String(contact.get("unit_id", contact.get("target_id", ""))).strip_edges()
		var readout: Dictionary = {}
		if _contact_state_allows_cover_effectiveness_detail(detection_state):
			readout = Dictionary(combat_driver.call("build_cover_effectiveness_readout_for_contact", normalized_fireteam_id, target_unit_id)).duplicate(true)
			readout["contact_unit_id"] = target_unit_id
		else:
			readout = _build_unknown_cover_effectiveness_readout("contact_not_visible", detection_state, "contact")
		readout["readout_type"] = "contact"
		readout["fireteam_id"] = normalized_fireteam_id
		readout["contact_state"] = detection_state
		result.append(readout)
		if result.size() >= 3:
			break
	return result


func _build_unknown_cover_effectiveness_readout(reason: String, contact_state: String = "", readout_type: String = "unknown") -> Dictionary:
	return {
		"readout_type": readout_type,
		"readout_state": "unknown",
		"reason": reason,
		"source": "TacticalInputController",
		"combat_truth_source": "hidden_or_missing_input",
		"read_only": true,
		"ui_may_execute_commands": false,
		"contact_state": contact_state,
		"range_state": "unknown",
		"los_state": "unknown",
		"cover_state": "unknown",
		"raw_cover_state": "unknown",
		"effective_cover_state": "unknown",
		"flank_state": "unknown",
		"flank_relevant": false,
		"combat_attackable": false,
		"attack_quality_label": "unknown",
	}


func _contact_state_allows_cover_effectiveness_detail(contact_state: String) -> bool:
	var normalized_state: String = contact_state.strip_edges().to_lower()
	return normalized_state == "spotted" or normalized_state == "confirmed"


func _resolve_cover_effectiveness_state(cover_score: int) -> String:
	if cover_score < 0:
		return "unknown"
	if cover_score >= 70:
		return "full_cover"
	if cover_score >= 35:
		return "partial_cover"
	if cover_score > 0:
		return "light_cover"
	return "no_cover"


func _format_cover_effectiveness_readout_text(readout: Dictionary) -> String:
	if readout.is_empty():
		return "COV ? | RNG ? | LOS ? | FLK ?"
	return "COV %s | RNG %s | LOS %s | FLK %s" % [
		_compact_cover_effectiveness_label(String(readout.get("cover_state", "unknown"))),
		_compact_cover_effectiveness_label(String(readout.get("range_state", "unknown"))),
		_compact_cover_effectiveness_label(String(readout.get("los_state", "unknown"))),
		_compact_cover_effectiveness_label(String(readout.get("flank_state", "unknown"))),
	]


func _compact_cover_effectiveness_label(value: String) -> String:
	match value.strip_edges().to_lower():
		"full_cover":
			return "FULL"
		"partial_cover":
			return "PART"
		"light_cover":
			return "LIGHT"
		"no_cover":
			return "OPEN"
		"in_range":
			return "IN"
		"out_of_range":
			return "OUT"
		"clear":
			return "CLR"
		"blocked":
			return "BLOCK"
		"flank":
			return "YES"
		"not_flank":
			return "NO"
		_:
			return "?"


func get_command_feedback_snapshot() -> Dictionary:
	var cover_effectiveness_readout: Dictionary = get_cover_effectiveness_readout_snapshot()
	return {
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"selected_fireteam_label": _get_fireteam_name(),
		"selected_tile": _build_selected_tile_snapshot(),
		"phase_name": _get_phase_name(),
		"target_text": _build_target_text(),
		"selected_order_text": _build_selected_waypoint_info_text(),
		"selected_multi_fireteam_plan_text": _build_selected_multi_fireteam_plan_info_text(),
		"mission_control_plan_text": _build_mission_control_multi_fireteam_plan_text(),
		"selected_status_text": _build_fireteam_status_text(),
		"last_command_text": _last_command_text,
		"command_feedback_text": _get_label_text(command_feedback_label_path),
		"selected_fireteam_status_label_text": _get_label_text(FIRETEAM_STATUS_LABEL_PATH),
		"mission_control_status_text": _get_label_text("../TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel/StrategicMargin/StrategicScroll/StrategicVBox/StrategicStatusLabel"),
		"command_buttons": _build_command_control_snapshot(),
		"command_hierarchy": get_command_hierarchy_snapshot(),
		"planned_waypoint_count": _count_selected_phase_waypoints(),
		"planned_area_order_count": _count_selected_area_orders(),
		"multi_fireteam_plan_count": _serialize_multi_fireteam_plans().size(),
		"visualized_waypoint_count": get_visualized_waypoints_snapshot().size(),
		"visualized_area_order_count": get_visualized_area_orders_snapshot().size(),
		"waypoint_intent_preview_count": get_waypoint_intent_preview_snapshot().size(),
		"waypoint_intent_preview": get_waypoint_intent_preview_snapshot(),
		"waypoint_intent_preview_contract": get_waypoint_intent_preview_contract_snapshot(),
		"fire_sector_overlay": get_fire_sector_overlay_snapshot(),
		"los_debug_overlay": get_los_debug_overlay_snapshot(),
		"contact_density_heatmap": get_contact_density_heatmap_snapshot(),
		"cover_effectiveness_readout": cover_effectiveness_readout,
		"cover_effectiveness_text": String(cover_effectiveness_readout.get("readout_text", "")),
		"fireteam_orientation_count": get_fireteam_orientation_snapshot().size(),
		"fireteam_orientations": get_fireteam_orientation_snapshot(),
		"active_area_defense": get_active_area_defense_snapshot(),
		"active_area_attack": get_active_area_attack_snapshot(),
		"fireteamleader_feedback_bubbles_enabled": fireteamleader_feedback_bubbles_enabled,
		"fireteamleader_feedback_bubble_count": get_fireteamleader_feedback_bubble_snapshot().size(),
		"fireteamleader_feedback_bubbles": get_fireteamleader_feedback_bubble_snapshot(),
		"tactical_communication_event_count": get_tactical_communication_event_snapshot().size(),
		"tactical_communication_events": get_tactical_communication_event_snapshot(),
		"tactical_event_log_count": get_tactical_event_log_snapshot().size(),
		"tactical_event_log": get_tactical_event_log_snapshot(),
		"tactical_event_log_contract": get_tactical_event_log_contract_snapshot(),
		"ftl_readiness_count": get_ftl_readiness_snapshot().size(),
		"ftl_readiness": get_ftl_readiness_snapshot(),
		"ftl_readiness_contract": get_ftl_readiness_contract_snapshot(),
		"fireteam_status_card_count": get_fireteam_status_card_snapshot().size(),
		"fireteam_status_cards": get_fireteam_status_card_snapshot(),
		"fireteam_member_status_row_count": get_fireteam_member_status_row_snapshot().size(),
		"fireteam_member_status_rows": get_fireteam_member_status_row_snapshot(),
		"tactical_breakout_count": get_tactical_breakout_snapshot().size(),
		"tactical_breakouts": get_tactical_breakout_snapshot(),
		"fireteam_coordination_count": get_fireteam_coordination_snapshot().size(),
		"fireteam_coordination": get_fireteam_coordination_snapshot(),
		"air_asset_status": get_air_asset_status_snapshot(),
		"air_asset_threat_count": get_air_asset_threat_snapshot().size(),
		"air_asset_threats": get_air_asset_threat_snapshot(),
		"selected_tactical_communication_text": _build_selected_tactical_communication_text(),
		"mission_control_tactical_communication_text": _build_mission_control_tactical_communication_text(),
		"npc_thought_bubble_count": get_npc_thought_bubble_snapshot().size(),
		"npc_thought_bubbles": get_npc_thought_bubble_snapshot(),
	}


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


func _ensure_multi_fireteam_plan_resolver() -> void:
	if _multi_fireteam_plan_resolver != null:
		return
	_multi_fireteam_plan_resolver = MULTI_FIRETEAM_PLAN_RESOLVER_SCRIPT.new()


func _ensure_tactical_communication_resolver() -> void:
	if _tactical_communication_resolver != null:
		return
	_tactical_communication_resolver = TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.new()


func _ensure_tactical_event_log() -> void:
	if _tactical_event_log != null:
		return
	_tactical_event_log = TACTICAL_EVENT_LOG_SCRIPT.new()


func _ensure_tactical_breakout_resolver() -> void:
	if _tactical_breakout_resolver != null:
		return
	_tactical_breakout_resolver = TACTICAL_BREAKOUT_RESOLVER_SCRIPT.new()


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


func _get_comic_bubble_runtime_gate():
	if _comic_bubble_runtime_gate != null:
		return _comic_bubble_runtime_gate
	COMIC_BUBBLE_SETTINGS_SCRIPT.call("ensure_input_map_actions")
	_comic_bubble_runtime_gate = COMIC_BUBBLE_RUNTIME_GATE_SCRIPT.new()
	_comic_bubble_runtime_gate.call("load_settings")
	var settings: Dictionary = Dictionary(_comic_bubble_runtime_gate.call("get_settings"))
	fireteamleader_feedback_bubbles_enabled = bool(settings.get("enabled", true)) and bool(settings.get("ftl_command_feedback_enabled", true))
	return _comic_bubble_runtime_gate


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
	if visualizer.has_method("set_waypoint_intent_preview_entries"):
		visualizer.call("set_waypoint_intent_preview_entries", _build_waypoint_intent_preview_entries())
	if visualizer.has_method("set_area_order_dicts"):
		visualizer.call("set_area_order_dicts", _serialize_area_orders())
	visualizer.call("set_ad_hoc_order_dicts", _build_ad_hoc_visualization_entries())
	if visualizer.has_method("set_security_overlay_enabled"):
		visualizer.call("set_security_overlay_enabled", _fire_sector_overlay_enabled)
	visualizer.call("set_security_dicts", get_fireteam_security_snapshot())
	if visualizer.has_method("set_movement_state_dicts"):
		visualizer.call("set_movement_state_dicts", get_fireteam_movement_snapshot())
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
			"fire_sector_overlay_enabled": _fire_sector_overlay_enabled,
			"fire_sector_visual_mode": "los_line_only",
			"los_debug_overlay_enabled": _los_debug_overlay_enabled,
			"los_debug_sample_limit": 24,
			"contact_density_heatmap_enabled": _contact_density_heatmap_enabled,
			"fireteam_anchors": _build_fireteam_anchor_visualization_entries(),
			"plan_dicts": _serialize_order_plans(),
			"waypoint_intent_preview_entries": _build_waypoint_intent_preview_entries(),
			"area_order_dicts": _serialize_area_orders(),
			"multi_fireteam_plan_dicts": _serialize_multi_fireteam_plans(),
			"ad_hoc_order_dicts": _build_ad_hoc_visualization_entries(),
			"security_dicts": get_fireteam_security_snapshot(),
			"movement_state_dicts": get_fireteam_movement_snapshot(),
			"enemy_security_dicts": get_enemy_security_snapshot(),
			"enemy_tactics_dicts": get_enemy_team_tactics_snapshot(),
			"fire_event_dicts": get_fire_event_snapshot(),
			"feedback_bubble_dicts": get_comic_bubble_visual_payload_snapshot(),
			"tactical_communication_event_dicts": get_tactical_communication_event_snapshot(),
		}
	)


func refresh_flank_vulnerability_state() -> void:
	_refresh_fireteam_status_panel()
	_update_ui()


func _try_open_waypoint_menu_at_position(screen_position: Vector2, append_mode: bool = false) -> bool:
	var existing_target: Dictionary = _find_waypoint_target_at_screen_position(screen_position)
	if not existing_target.is_empty():
		_focused_waypoint_ref = existing_target.duplicate(true)
		_focused_area_order_ref = {}
		_refresh_button_state()
		_open_waypoint_command_menu(screen_position, [existing_target], true, false)
		return true
	var existing_area_order_target: Dictionary = _find_area_order_target_at_screen_position(screen_position)
	if not existing_area_order_target.is_empty():
		_focused_area_order_ref = existing_area_order_target.duplicate(true)
		_focused_waypoint_ref = {}
		_refresh_button_state()
		_open_area_order_command_menu(screen_position, [existing_area_order_target], true, false)
		return true

	if _selected_fireteam_ids.is_empty():
		_last_command_text = "SELECT FIRETEAM FIRST"
		_update_ui()
		return false

	var tile_context: Dictionary = _build_tile_context_from_screen_position(screen_position)
	if _has_primary_grid_for_command_selection() and tile_context.is_empty():
		_last_command_text = "NO TILE UNDER CURSOR"
		_refresh_button_state()
		_update_ui()
		return false
	var waypoint_world_position: Vector2 = Vector2(tile_context.get("world_position", _snap_planning_position_to_tile_center(_clamp_world_position_to_viewport(_screen_to_world_position(screen_position)))))
	if not tile_context.is_empty():
		_set_selected_tile_context(tile_context, "", false, false)
	var waypoint_targets: Array = _create_waypoints_for_selected_fireteams(waypoint_world_position, not append_mode, true)
	if waypoint_targets.is_empty():
		return false
	_focused_waypoint_ref = Dictionary(waypoint_targets[0]).duplicate(true)
	_focused_area_order_ref = {}
	_open_waypoint_command_menu(screen_position, waypoint_targets, false, append_mode)
	_last_command_text = "WAYPOINT %s (%s)" % ["APPENDED" if append_mode else "SET", _get_phase_name()]
	_update_ui()
	_emit_planning_state_changed()
	return true


func _create_waypoints_for_selected_fireteams(world_position: Vector2, replace_existing_next_order: bool = false, snap_to_tile_center: bool = true) -> Array:
	var waypoint_targets: Array = []
	var snapped_world_position: Vector2 = _snap_planning_position_to_tile_center(world_position) if snap_to_tile_center else world_position
	if replace_existing_next_order:
		_replace_next_orders_for_fireteams(_selected_fireteam_ids, _get_live_order_phase_index())
	for fireteam_id in _selected_fireteam_ids:
		var waypoint_target: Dictionary = _append_waypoint_to_plan(String(fireteam_id), _get_live_order_phase_index(), snapped_world_position)
		if waypoint_target.is_empty():
			continue
		waypoint_targets.append(waypoint_target)
	_refresh_order_visuals()
	return waypoint_targets


func _replace_next_orders_for_fireteams(fireteam_ids: PackedStringArray, phase_index: int) -> void:
	var sanitized_fireteam_ids: PackedStringArray = _sanitize_fireteam_ids(fireteam_ids)
	if sanitized_fireteam_ids.is_empty():
		return
	for fireteam_id_variant in sanitized_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		_remove_replaceable_waypoints_for_fireteam(fireteam_id, phase_index)
		_remove_replaceable_area_orders_for_fireteam(fireteam_id)
	_remove_empty_multi_fireteam_plans()


func _remove_replaceable_waypoints_for_fireteam(fireteam_id: String, phase_index: int) -> void:
	var plan_key: String = _build_order_plan_key(fireteam_id, phase_index)
	var plan = _order_plans_by_key.get(plan_key, null)
	if plan == null or plan.waypoints.is_empty():
		return
	var retained_waypoints: Array = []
	var next_active_index: int = -1
	for waypoint in plan.waypoints:
		if waypoint == null:
			continue
		var status: String = String(waypoint.status).strip_edges().to_lower()
		if status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING or status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_INTERRUPTED or status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_CANCELLED:
			continue
		if status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_ACTIVE:
			next_active_index = retained_waypoints.size()
		retained_waypoints.append(waypoint)
	plan.waypoints = retained_waypoints
	plan.active_waypoint_index = next_active_index
	if plan.waypoints.is_empty():
		_order_plans_by_key.erase(plan_key)
	elif next_active_index < 0 and String(plan.status) != FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_COMPLETED:
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_DRAFT


func _remove_replaceable_area_orders_for_fireteam(fireteam_id: String) -> void:
	for area_order_id_variant in _area_orders_by_id.keys().duplicate():
		var area_order_id: String = String(area_order_id_variant)
		var area_order = _area_orders_by_id.get(area_order_id, null)
		if area_order == null:
			continue
		if String(area_order.fireteam_id).strip_edges().to_lower() != fireteam_id:
			continue
		var status: String = String(area_order.status).strip_edges().to_lower()
		if status != AREA_ORDER_SCRIPT.STATUS_PENDING and status != AREA_ORDER_SCRIPT.STATUS_CANCELLED:
			continue
		_remove_multi_fireteam_plans_for_area_order_id(area_order_id)
		_area_orders_by_id.erase(area_order_id)


func _remove_empty_multi_fireteam_plans() -> void:
	for plan_id_variant in _multi_fireteam_plans_by_id.keys().duplicate():
		var plan_id: String = String(plan_id_variant)
		var plan: Dictionary = Dictionary(_multi_fireteam_plans_by_id.get(plan_id, {}))
		var area_context: Dictionary = Dictionary(plan.get("area_context", {}))
		var refs: Array = Array(area_context.get("area_order_refs", []))
		var has_live_ref: bool = false
		for ref_variant in refs:
			if typeof(ref_variant) != TYPE_DICTIONARY:
				continue
			if _area_orders_by_id.has(String(Dictionary(ref_variant).get("area_order_id", "")).strip_edges()):
				has_live_ref = true
				break
		if not has_live_ref:
			_multi_fireteam_plans_by_id.erase(plan_id)


func issue_right_click_command_for_test(world_position: Vector2, command_type: String, append_mode: bool = false) -> bool:
	var waypoint_targets: Array = _create_waypoints_for_selected_fireteams(world_position, not append_mode, false)
	if waypoint_targets.is_empty():
		return false
	_waypoint_menu_append_mode = append_mode
	return _set_waypoint_command_for_targets(waypoint_targets, command_type)


func issue_right_drag_area_command_for_test(start_world_position: Vector2, end_world_position: Vector2, command_type: String, append_mode: bool = false) -> bool:
	var payload: Dictionary = _build_area_order_payload_from_world_rect(start_world_position, end_world_position)
	var area_targets: Array = _create_area_orders_from_payload(_selected_fireteam_ids, payload, AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, true, not append_mode)
	if area_targets.is_empty():
		return false
	_area_order_menu_append_mode = append_mode
	return _set_area_order_command_for_targets(area_targets, command_type)


func create_area_order_for_selected_fireteams_from_world_rect(start_world_position: Vector2, end_world_position: Vector2, command_type: String = AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND) -> Array:
	return create_area_order_for_fireteams_from_world_rect(_selected_fireteam_ids, start_world_position, end_world_position, command_type)


func create_area_order_for_fireteams_from_world_rect(fireteam_ids: PackedStringArray, start_world_position: Vector2, end_world_position: Vector2, command_type: String = AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND) -> Array:
	var payload: Dictionary = _build_area_order_payload_from_world_rect(start_world_position, end_world_position)
	return _create_area_orders_from_payload(fireteam_ids, payload, command_type, true)


func _create_area_orders_for_selected_fireteams_from_screen_rect(screen_rect: Rect2, command_type: String = AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND) -> Array:
	var payload: Dictionary = _build_area_order_payload_from_screen_rect(screen_rect)
	return _create_area_orders_from_payload(_selected_fireteam_ids, payload, command_type, true)


func _create_area_orders_from_payload(fireteam_ids: PackedStringArray, payload: Dictionary, command_type: String, should_emit_signal: bool, replace_existing_next_order: bool = false) -> Array:
	var normalized_command_type: String = _normalize_area_order_command_type(command_type)
	var sanitized_fireteam_ids: PackedStringArray = _sanitize_fireteam_ids(fireteam_ids)
	if sanitized_fireteam_ids.is_empty():
		return []
	if Array(payload.get("tile_positions", [])).is_empty() and PackedVector2Array(payload.get("world_polygon", PackedVector2Array())).is_empty():
		return []
	if replace_existing_next_order:
		_replace_next_orders_for_fireteams(sanitized_fireteam_ids, _get_live_order_phase_index())

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
	var coordinated_plan: Dictionary = _maybe_create_multi_fireteam_area_plan(sanitized_fireteam_ids, normalized_command_type, payload, targets)
	_refresh_order_visuals()
	_last_command_text = "PLAN %s (%d)" % [normalized_command_type.to_upper(), targets.size()] if not coordinated_plan.is_empty() else "AREA %s (%d)" % [normalized_command_type.to_upper(), targets.size()]
	_update_ui()
	if should_emit_signal:
		_emit_planning_state_changed()
	return targets


func _maybe_create_multi_fireteam_area_plan(fireteam_ids: PackedStringArray, command_type: String, payload: Dictionary, targets: Array) -> Dictionary:
	if fireteam_ids.size() < 2:
		return {}
	_ensure_multi_fireteam_plan_resolver()
	if _multi_fireteam_plan_resolver == null:
		return {}
	_multi_fireteam_plan_sequence += 1
	var plan_id: String = "mission_multi_%04d" % _multi_fireteam_plan_sequence
	var area_context: Dictionary = payload.duplicate(true)
	area_context["command_type"] = command_type
	area_context["area_order_refs"] = targets.duplicate(true)
	var intent = COMMANDER_INTENT_SCRIPT.new({
		"verb": _map_area_command_to_commander_verb(command_type),
		"coordinated_fireteam_ids": fireteam_ids,
		"target_position": Vector2(payload.get("center_position", _get_target_position())),
		"target_area_id": "area_%04d" % _area_order_sequence,
		"sync_group_id": plan_id,
		"phase": _get_live_order_phase_index(),
		"tempo": "normal",
		"fire_rule": "return",
		"contact_response": "report",
		"risk": "normal",
	})
	var plan: Dictionary = Dictionary(MULTI_FIRETEAM_PLAN_RESOLVER_SCRIPT.call("resolve_area_plan", intent, _build_multi_fireteam_contexts(fireteam_ids), {
		"plan_id": plan_id,
		"phase": _get_live_order_phase_index(),
		"area_context": area_context,
		"min_spacing": 96.0,
	}))
	if plan.is_empty():
		return {}
	_multi_fireteam_plans_by_id[String(plan.get("plan_id", plan_id))] = plan
	_record_tactical_communication_events(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_events_for_multi_fireteam_plan", plan, {
		"plan_id": plan_id,
		"phase": _get_live_order_phase_index(),
		"max_events": 6,
	}))
	for target_variant in targets:
		var target: Dictionary = Dictionary(target_variant)
		var area_order = _area_orders_by_id.get(String(target.get("area_order_id", "")), null)
		if area_order == null:
			continue
		area_order.metadata["multi_fireteam_plan_id"] = String(plan.get("plan_id", plan_id))
		area_order.metadata["sync_group_id"] = String(plan.get("sync_group_id", plan_id))
	return plan


func _map_area_command_to_commander_verb(command_type: String) -> String:
	match command_type.strip_edges().to_lower():
		AREA_ORDER_SCRIPT.COMMAND_TYPE_TAKE:
			return COMMANDER_INTENT_SCRIPT.VERB_TAKE
		AREA_ORDER_SCRIPT.COMMAND_TYPE_ENGAGE:
			return COMMANDER_INTENT_SCRIPT.VERB_ENGAGE
		AREA_ORDER_SCRIPT.COMMAND_TYPE_FLANK:
			return COMMANDER_INTENT_SCRIPT.VERB_FLANK
		_:
			return COMMANDER_INTENT_SCRIPT.VERB_DEFEND


func _build_multi_fireteam_contexts(fireteam_ids: PackedStringArray) -> Array:
	var contexts: Array = []
	for fireteam_id_variant in fireteam_ids:
		var context: Dictionary = _build_multi_fireteam_context(String(fireteam_id_variant))
		if not context.is_empty():
			contexts.append(context)
	return contexts


func _build_multi_fireteam_context(fireteam_id: String) -> Dictionary:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return {}
	var units: Array = _get_fireteam_units(normalized_fireteam_id, true)
	var anchor_position: Variant = _resolve_fireteam_visual_anchor_position(normalized_fireteam_id)
	var position: Vector2 = Vector2(anchor_position) if typeof(anchor_position) == TYPE_VECTOR2 else _get_target_position()
	var member_count: int = 0
	var medic_count: int = 0
	var leadership_total: float = 0.0
	var discipline_total: float = 0.0
	var speed_total: float = 0.0
	var accuracy_total: float = 0.0
	var awareness_total: float = 0.0
	var stealth_total: float = 0.0
	for unit in units:
		if unit == null:
			continue
		var vital_state: String = String(unit.call("get_vital_state")) if unit.has_method("get_vital_state") else "fit"
		if vital_state != "fit":
			continue
		member_count += 1
		leadership_total += _read_multi_fireteam_unit_skill(unit, "get_leadership_skill", "skill_leadership", 0.5)
		discipline_total += _read_multi_fireteam_unit_skill(unit, "get_discipline_skill", "discipline", 0.5)
		speed_total += _read_multi_fireteam_unit_skill(unit, "get_speed_skill", "skill_speed", 0.5)
		accuracy_total += _read_multi_fireteam_unit_skill(unit, "get_accuracy_skill", "skill_accuracy", 0.5)
		awareness_total += _read_multi_fireteam_unit_skill(unit, "get_awareness_skill", "awareness", 0.5)
		stealth_total += _read_multi_fireteam_unit_skill(unit, "get_stealth_skill", "stealth", 0.5)
		if _unit_looks_like_medic(unit):
			medic_count += 1
	var divisor: float = float(maxi(member_count, 1))
	return {
		"fireteam_id": normalized_fireteam_id,
		"team_id": FRIENDLY_TEAM_ID,
		"display_label": _get_fireteam_display_label(normalized_fireteam_id),
		"position": position,
		"member_count": member_count,
		"medic_count": medic_count,
		"leadership": leadership_total / divisor,
		"discipline": discipline_total / divisor,
		"cohesion": 0.68,
		"communication": leadership_total / divisor,
		"initiative": speed_total / divisor,
		"speed": speed_total / divisor,
		"accuracy": accuracy_total / divisor,
		"awareness": awareness_total / divisor,
		"stealth": stealth_total / divisor,
		"readiness": clampf(float(member_count) / 4.0, 0.0, 1.0),
		"weapon_range": clampf((accuracy_total / divisor) * 0.7 + 0.25, 0.0, 1.0),
		"cover_quality": 0.5,
		"contact_pressure": clampf(float(get_fireteam_contact_snapshot(normalized_fireteam_id).size()) / 3.0, 0.0, 1.0),
		"blocked_path": false,
	}


func _read_multi_fireteam_unit_skill(unit, method_name: String, property_name: String, fallback: float) -> float:
	if unit != null and unit.has_method(method_name):
		return clampf(float(unit.call(method_name)), 0.0, 1.0)
	if unit != null and unit.has_method("get"):
		var value = unit.get(property_name)
		if value != null:
			return clampf(float(value), 0.0, 1.0)
	return fallback


func _unit_looks_like_medic(unit) -> bool:
	if unit == null or not unit.has_method("get"):
		return false
	for property_name in ["role_id", "mission_role", "primary_weapon_id", "secondary_weapon_id", "loadout_id"]:
		var value = unit.get(property_name)
		if value != null and String(value).strip_edges().to_lower().contains("medic"):
			return true
	return false


func _build_fireteam_anchor_visualization_entries() -> Array:
	var entries: Array = []
	for fireteam_id_variant in _get_available_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var anchor_position: Variant = _resolve_fireteam_visual_anchor_position(fireteam_id)
		if typeof(anchor_position) != TYPE_VECTOR2:
			continue
		var entry: Dictionary = {
			"fireteam_id": fireteam_id,
			"position": Vector2(anchor_position),
		}
		var heading_entry: Dictionary = _resolve_fireteam_heading_entry(fireteam_id, Vector2(anchor_position))
		if not heading_entry.is_empty():
			entry.merge(heading_entry, true)
		entries.append(entry)
	return entries


func _build_waypoint_intent_preview_entries() -> Array:
	if _waypoint_intent_preview_resolver == null:
		return []
	return Array(
		_waypoint_intent_preview_resolver.call(
			"build_preview_entries",
			_serialize_order_plans(),
			_build_fireteam_anchor_visualization_entries(),
			{
				"phase_index": _get_live_order_phase_index(),
				"selected_fireteam_ids": _selected_fireteam_ids,
				"speed_world_per_second_by_fireteam": _build_waypoint_preview_speed_by_fireteam(),
			}
		)
	).duplicate(true)


func _build_waypoint_preview_speed_by_fireteam() -> Dictionary:
	var result: Dictionary = {}
	for fireteam_id_variant in _get_available_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var speed_total: float = 0.0
		var unit_count: int = 0
		for unit in _get_fireteam_units(fireteam_id, true):
			if unit == null:
				continue
			speed_total += _read_multi_fireteam_unit_skill(unit, "get_speed_skill", "skill_speed", 0.5)
			unit_count += 1
		var average_speed: float = speed_total / float(unit_count) if unit_count > 0 else 0.5
		result[fireteam_id] = 88.0 + (clampf(average_speed, 0.0, 1.0) * 56.0)
	return result


func _resolve_fireteam_heading_entry(fireteam_id: String, anchor_position: Vector2) -> Dictionary:
	var movement_heading: Dictionary = _resolve_fireteam_movement_heading(fireteam_id)
	if not movement_heading.is_empty():
		return movement_heading
	var security_heading: Dictionary = _resolve_fireteam_security_heading(fireteam_id)
	if not security_heading.is_empty():
		return security_heading
	var facing_heading: Dictionary = _resolve_fireteam_unit_facing_heading(fireteam_id)
	if not facing_heading.is_empty():
		return facing_heading
	var target_heading: Dictionary = _resolve_fireteam_target_heading(fireteam_id, anchor_position)
	if not target_heading.is_empty():
		return target_heading
	return {}


func _resolve_fireteam_movement_heading(fireteam_id: String) -> Dictionary:
	var movement_state: Dictionary = get_fireteam_movement_state(fireteam_id)
	if movement_state.is_empty():
		return {}
	var origin_position: Vector2 = _coerce_vector2_value(movement_state.get("current_anchor_origin_position", movement_state.get("progress_anchor_position", movement_state.get("bound_origin_position", Vector2.ZERO))), Vector2.ZERO)
	var target_position: Vector2 = _coerce_vector2_value(movement_state.get("current_anchor_target_position", movement_state.get("bound_target_position", movement_state.get("final_target_position", origin_position))), origin_position)
	var direction: Vector2 = target_position - origin_position
	if direction.length_squared() <= 0.0001:
		direction = _coerce_vector2_value(movement_state.get("final_target_position", target_position), target_position) - origin_position
	return _build_heading_entry(direction, "movement")


func _resolve_fireteam_security_heading(fireteam_id: String) -> Dictionary:
	var security_state: Dictionary = get_fireteam_security_state(fireteam_id)
	if security_state.is_empty():
		return {}
	if not bool(security_state.get("is_active", false)) and typeof(security_state.get("main_threat_position", null)) != TYPE_VECTOR2:
		return {}
	var direction: Vector2 = Vector2.RIGHT.rotated(float(security_state.get("direction_angle", 0.0)))
	return _build_heading_entry(direction, "security")


func _resolve_fireteam_unit_facing_heading(fireteam_id: String) -> Dictionary:
	var leader = _resolve_fireteam_leader_for_behavior(fireteam_id)
	var leader_heading: Dictionary = _resolve_unit_facing_heading(leader)
	if not leader_heading.is_empty():
		return leader_heading
	for unit in _get_fireteam_units(fireteam_id, true):
		var unit_heading: Dictionary = _resolve_unit_facing_heading(unit)
		if not unit_heading.is_empty():
			return unit_heading
	return {}


func _resolve_unit_facing_heading(unit) -> Dictionary:
	if unit == null or not (unit is Node):
		return {}
	for meta_key in ["facing_angle", "map_facing_angle"]:
		if (unit as Node).has_meta(meta_key):
			return _build_heading_entry(Vector2.RIGHT.rotated(float((unit as Node).get_meta(meta_key, 0.0))), "unit_facing")
	return {}


func _resolve_fireteam_target_heading(fireteam_id: String, anchor_position: Vector2) -> Dictionary:
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, _get_live_order_phase_index()), null)
	if plan != null:
		for waypoint in plan.waypoints:
			if waypoint == null:
				continue
			var waypoint_status: String = String(waypoint.status)
			if waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_COMPLETED or waypoint_status == FIRETEAM_WAYPOINT_SCRIPT.STATUS_CANCELLED:
				continue
			if typeof(waypoint.target_position) == TYPE_VECTOR2:
				return _build_heading_entry(Vector2(waypoint.target_position) - anchor_position, "planned_target")
	for area_order in _area_orders_by_id.values():
		if area_order == null:
			continue
		if String(area_order.fireteam_id).strip_edges().to_lower() != fireteam_id:
			continue
		if String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_COMPLETED or String(area_order.status) == AREA_ORDER_SCRIPT.STATUS_CANCELLED:
			continue
		if typeof(area_order.center_position) == TYPE_VECTOR2:
			return _build_heading_entry(Vector2(area_order.center_position) - anchor_position, "planned_area")
	return {}


func _build_heading_entry(direction: Vector2, source: String) -> Dictionary:
	if direction.length_squared() <= 0.0001:
		return {}
	var normalized_direction: Vector2 = direction.normalized()
	return {
		"heading_direction": normalized_direction,
		"heading_angle": normalized_direction.angle(),
		"heading_source": source,
	}


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


func _extract_multi_fireteam_plan_sequence(plan_id: String) -> int:
	var parts: PackedStringArray = plan_id.strip_edges().split("_")
	if parts.size() < 1:
		return 0
	return int(parts[parts.size() - 1])


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


func _serialize_multi_fireteam_plans() -> Array:
	var result: Array = []
	var keys: Array = _multi_fireteam_plans_by_id.keys()
	keys.sort()
	for key in keys:
		var plan: Dictionary = Dictionary(_multi_fireteam_plans_by_id.get(key, {})).duplicate(true)
		if plan.is_empty() or not bool(MULTI_FIRETEAM_PLAN_RESOLVER_SCRIPT.call("is_valid_plan", plan)):
			continue
		result.append(plan)
	return result


func _load_multi_fireteam_plans_from_state(plan_dicts: Array) -> void:
	_multi_fireteam_plans_by_id.clear()
	for plan_variant in plan_dicts:
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		var plan: Dictionary = Dictionary(plan_variant).duplicate(true)
		if plan.is_empty() or not bool(MULTI_FIRETEAM_PLAN_RESOLVER_SCRIPT.call("is_valid_plan", plan)):
			continue
		var plan_id: String = String(plan.get("plan_id", "")).strip_edges()
		if plan_id.is_empty():
			continue
		_multi_fireteam_plans_by_id[plan_id] = plan
		var sequence: int = _extract_multi_fireteam_plan_sequence(plan_id)
		if sequence > _multi_fireteam_plan_sequence:
			_multi_fireteam_plan_sequence = sequence
	_refresh_order_visuals()


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
	var readability_status_line: String = String(state.get("readability_status_line", "")).strip_edges()
	if readability_status_line.is_empty():
		readability_status_line = String(Dictionary(state.get("map_readability", {})).get("status_line", "")).strip_edges()
	if not readability_status_line.is_empty():
		return readability_status_line
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
	metadata["security_mode_override"] = "directional"
	metadata["security_direction_angle"] = _resolve_objective_security_angle_for_fireteam(fireteam_id, anchor_position)
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


func _apply_post_drop_360_security_behavior(fireteam_id: String, phase_index: int) -> bool:
	_ensure_fireteam_movement_controller()
	if _fireteam_movement_controller != null:
		_fireteam_movement_controller.call("reset_fireteam", fireteam_id)
	_clear_fireteam_runtime_execution_for_post_drop(fireteam_id)
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
	metadata["origin"] = POST_DROP_SECURITY_ORIGIN
	metadata["origin_command_type"] = "hold_position"
	metadata["phase"] = phase_index
	metadata["rough_target_position"] = anchor_position
	metadata["security_mode_override"] = POST_DROP_SECURITY_MODE
	metadata["security_radius_tiles"] = POST_DROP_SECURITY_RADIUS_TILES
	metadata["security_radius_world"] = _get_post_drop_security_radius_world()
	metadata["security_direction_angle"] = _resolve_objective_security_angle_for_fireteam(fireteam_id, anchor_position)
	behavior_profile.metadata = metadata
	_set_active_behavior_profile(fireteam_id, behavior_profile)
	var issued: bool = _issue_fireteam_post_drop_360_security_positions(fireteam_id, phase_index, anchor_position)
	_mirror_flow_driver_order_for_fireteam(fireteam_id, anchor_position, "defend", phase_index)
	_record_fireteamleader_feedback_for_fireteam(fireteam_id, "defend", "cover", POST_DROP_SECURITY_ORIGIN)
	refresh_fireteam_security_state()
	return issued


func _clear_fireteam_runtime_execution_for_post_drop(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	_phase_execution_by_fireteam.erase(normalized_fireteam_id)
	_ad_hoc_execution_by_fireteam.erase(normalized_fireteam_id)
	_ad_hoc_resume_state_by_fireteam.erase(normalized_fireteam_id)
	_area_defense_execution_by_fireteam.erase(normalized_fireteam_id)
	_area_attack_execution_by_fireteam.erase(normalized_fireteam_id)
	_suppression_interrupt_pending_by_fireteam.erase(normalized_fireteam_id)


func _issue_fireteam_post_drop_360_security_positions(fireteam_id: String, phase_index: int, anchor_position: Vector2) -> bool:
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root == null:
		return false
	var units: Array = _get_fireteam_units(fireteam_id, true)
	units.sort_custom(Callable(self, "_sort_unit_nodes_for_cards"))
	if units.is_empty():
		return false
	var ring_radius: float = _get_post_drop_security_radius_world()
	var sector_count: int = maxi(units.size(), 1)
	var objective_angle: float = _resolve_objective_security_angle_for_fireteam(fireteam_id, anchor_position)
	var used_cover_positions: Array = []
	var issued_count: int = 0
	for index in range(units.size()):
		var unit = units[index]
		if not (unit is Node2D):
			continue
		if unit.has_method("get_vital_state") and String(unit.call("get_vital_state")) != "fit":
			continue
		if not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		var sector_angle: float = _resolve_post_drop_security_sector_angle(index, sector_count, objective_angle)
		var target_position: Vector2 = anchor_position
		var command_type: String = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
		var speed_factor: float = 0.0
		if index > 0:
			target_position = _resolve_post_drop_cover_position(anchor_position, sector_angle, ring_radius, used_cover_positions)
			command_type = UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION
			speed_factor = POST_DROP_SECURITY_MOVE_SPEED_FACTOR
		else:
			used_cover_positions.append(anchor_position)
		_set_unit_map_facing_angle(unit, sector_angle)
		if unit is Node:
			(unit as Node).set_meta("post_drop_security_active", true)
			(unit as Node).set_meta("post_drop_security_radius_tiles", POST_DROP_SECURITY_RADIUS_TILES)
		if unit.has_method("show_event_text"):
			unit.call("show_event_text", "SEC 360", Color(0.58, 0.92, 1.0, 1.0), 2.4)
		var command = UNIT_COMMAND_SCRIPT.new()
		command.command_type = command_type
		command.priority = 13
		command.unit_id = unit_id
		command.team_id = FRIENDLY_TEAM_ID
		if unit.has_method("get_team_id"):
			command.team_id = String(unit.call("get_team_id"))
		command.target_position = target_position
		command.move_speed_factor = speed_factor
		command.cover_score = maxf(float(unit.call("get_cover_score")) if unit.has_method("get_cover_score") else 0.0, _estimate_cover_score_at_world_position(target_position))
		command.attack_bonus = 0.0
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
		command.source_command_type = "hold_position"
		command.source_task_type = POST_DROP_SECURITY_ORIGIN
		command.phase = phase_index
		if not bool(command.call("is_valid")):
			continue
		if unit.has_method("assign_unit_command"):
			unit.call("assign_unit_command", command)
		var command_dict: Dictionary = command.to_dict()
		command_dict["requeue_until_target"] = command_type == UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION
		command_dict["security_mode"] = POST_DROP_SECURITY_MODE
		command_dict["security_radius_tiles"] = POST_DROP_SECURITY_RADIUS_TILES
		command_dict["facing_angle"] = sector_angle
		simulation_root.call("enqueue_command", command_dict)
		issued_count += 1
	return issued_count > 0


func _get_post_drop_security_radius_world() -> float:
	return float(POST_DROP_SECURITY_RADIUS_TILES) * POST_DROP_SECURITY_TILE_WORLD_STEP


func _resolve_objective_security_angle_for_fireteam(fireteam_id: String, anchor_position: Vector2) -> float:
	var objective_position: Vector2 = _get_target_position()
	var base_angle: float = 0.0
	if anchor_position.distance_squared_to(objective_position) > 4.0:
		base_angle = (objective_position - anchor_position).angle()
	var nearby_ids: PackedStringArray = _get_nearby_runtime_fireteam_ids(anchor_position, 260.0)
	if nearby_ids.size() <= 1:
		return base_angle
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var own_index: int = nearby_ids.find(normalized_fireteam_id)
	if own_index < 0:
		return base_angle
	var center_index: float = (float(nearby_ids.size()) - 1.0) * 0.5
	return wrapf(base_angle + ((float(own_index) - center_index) * 0.48), -PI, PI)


func _get_nearby_runtime_fireteam_ids(anchor_position: Vector2, radius: float) -> PackedStringArray:
	var result := PackedStringArray()
	for fireteam_id_variant in _get_available_fireteam_ids():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or not _is_fireteam_runtime_active(fireteam_id):
			continue
		var fireteam_anchor: Variant = _resolve_fireteam_visual_anchor_position(fireteam_id)
		if typeof(fireteam_anchor) != TYPE_VECTOR2:
			continue
		if Vector2(fireteam_anchor).distance_to(anchor_position) <= radius:
			result.append(fireteam_id)
	result.sort()
	return result


func _resolve_post_drop_security_sector_angle(index: int, member_count: int, objective_angle: float) -> float:
	if member_count <= 1:
		return objective_angle
	if index == 0:
		return objective_angle
	if index == member_count - 1 and member_count >= 4:
		return wrapf(objective_angle + PI, -PI, PI)
	var side_index: int = index - 1
	var side_sign: float = -1.0 if side_index % 2 == 0 else 1.0
	var side_step: float = 0.56 + (0.38 * float(int(side_index / 2)))
	return wrapf(objective_angle + (side_sign * side_step), -PI, PI)


func _resolve_post_drop_cover_position(anchor_position: Vector2, sector_angle: float, fallback_radius: float, used_positions: Array) -> Vector2:
	var fallback_position: Vector2 = anchor_position + Vector2.RIGHT.rotated(sector_angle) * fallback_radius
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_walkable_cover_tiles_in_radius"):
		used_positions.append(fallback_position)
		return fallback_position
	var cover_tiles: Array = Array(terrain_registry.call("get_walkable_cover_tiles_in_radius", anchor_position, fallback_radius * POST_DROP_COVER_SEARCH_RADIUS_FACTOR))
	var sector_direction: Vector2 = Vector2.RIGHT.rotated(sector_angle)
	var best_score: float = -INF
	var best_position: Vector2 = fallback_position
	for tile in cover_tiles:
		if tile == null:
			continue
		var tile_position: Vector2 = Vector2(tile.world_position)
		var cover_value: float = float(tile.cover_value)
		if cover_value < POST_DROP_COVER_MIN_SCORE:
			continue
		if _is_position_already_reserved(tile_position, used_positions, 42.0):
			continue
		var offset: Vector2 = tile_position - anchor_position
		if offset.length_squared() <= 4.0:
			continue
		var sector_alignment: float = clampf(offset.normalized().dot(sector_direction), -1.0, 1.0)
		var distance_penalty: float = absf(offset.length() - fallback_radius) * 0.06
		var score: float = cover_value + (sector_alignment * 26.0) - distance_penalty
		if score <= best_score:
			continue
		best_score = score
		best_position = tile_position
	used_positions.append(best_position)
	return best_position


func _is_position_already_reserved(world_position: Vector2, used_positions: Array, min_distance: float) -> bool:
	for used_position_variant in used_positions:
		if typeof(used_position_variant) != TYPE_VECTOR2:
			continue
		if Vector2(used_position_variant).distance_to(world_position) < min_distance:
			return true
	return false


func _estimate_cover_score_at_world_position(world_position: Vector2) -> float:
	var terrain_registry = _get_terrain_registry()
	if terrain_registry == null or not terrain_registry.has_method("get_tile_at_world"):
		return 0.0
	var tile = terrain_registry.call("get_tile_at_world", world_position)
	if tile == null:
		return 0.0
	return float(tile.cover_value)


func _set_unit_map_facing_angle(unit, facing_angle: float) -> void:
	if unit == null or not (unit is Node):
		return
	(unit as Node).set_meta("facing_angle", facing_angle)
	(unit as Node).set_meta("map_facing_angle", facing_angle)


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
		_set_unit_map_facing_angle(unit, _resolve_objective_security_angle_for_fireteam(fireteam_id, command.target_position))
		command.move_speed_factor = 0.0
		command.cover_score = 0.0
		if unit.has_method("get_cover_score"):
			command.cover_score = float(unit.call("get_cover_score"))
		command.cover_score = maxf(command.cover_score, _estimate_cover_score_at_world_position(command.target_position))
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
		_record_bounding_coordination_feedback(assignment, phase_index)


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
		_record_bounding_rotation_feedback(rotated, fireteam_id, phase_index)
		var plan = _order_plans_by_key.get(_build_order_plan_key(next_advancing_fireteam_id, phase_index), null)
		if plan == null:
			continue
		var execution_state: Dictionary = Dictionary(_phase_execution_by_fireteam.get(next_advancing_fireteam_id, {}))
		var waypoint_index: int = int(execution_state.get("waypoint_index", plan.active_waypoint_index))
		if waypoint_index < 0:
			waypoint_index = 0
		_activate_next_waypoint_for_plan(plan, next_advancing_fireteam_id, waypoint_index)


func _record_bounding_rotation_feedback(rotated_assignment: Dictionary, ready_fireteam_id: String, phase_index: int) -> void:
	if rotated_assignment.is_empty():
		return
	var next_advancing_fireteam_id: String = String(rotated_assignment.get("advance_fireteam_id", "")).strip_edges().to_lower()
	var covering_fireteam_id: String = String(rotated_assignment.get("cover_fireteam_id", ready_fireteam_id)).strip_edges().to_lower()
	if next_advancing_fireteam_id.is_empty() or covering_fireteam_id.is_empty():
		return
	var cover_label: String = _get_fireteam_display_label(covering_fireteam_id)
	var advance_label: String = _get_fireteam_display_label(next_advancing_fireteam_id)
	var anchor_position_variant: Variant = _resolve_fireteam_anchor_position_for_feedback(covering_fireteam_id, rotated_assignment.get("cover_target_position", null))
	var target_position_variant: Variant = _resolve_fireteam_anchor_position_for_feedback(next_advancing_fireteam_id, rotated_assignment.get("advance_target_position", null))
	var event: Dictionary = {
		"event_id": "coord_%s_rotate_%d" % [_sanitize_node_name(String(rotated_assignment.get("coordination_id", "bounding"))), Time.get_ticks_msec()],
		"event_type": TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_BOUNDING_ROTATION,
		"fireteam_id": next_advancing_fireteam_id,
		"phase": phase_index,
		"priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_NORMAL,
		"duration_seconds": 2.4,
		"channels": PackedStringArray([
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_SELECTED_FIRETEAM,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MISSION_CONTROL,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MAP_MARKER,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_FTL_BUBBLE,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_AUDIO_BLIP,
		]),
		"feedback_action": "go",
		"feedback_state": "cover",
		"short_text": "%s: cover, %s vor!" % [cover_label, advance_label],
		"detail_text": "Bounding rotation: %s secures, %s advances" % [cover_label, advance_label],
		"map_label": "BOUND ROT",
		"created_msec": Time.get_ticks_msec(),
		"source": TACTICAL_COMMUNICATION_EVENT_SCRIPT.SOURCE_ID,
		"visual_only": true,
		"cooldown_key": "bounding_rotation:%s:%s:%d" % [covering_fireteam_id, next_advancing_fireteam_id, phase_index],
	}
	if typeof(anchor_position_variant) == TYPE_VECTOR2:
		event["anchor_position"] = Vector2(anchor_position_variant)
	if typeof(target_position_variant) == TYPE_VECTOR2:
		event["target_position"] = Vector2(target_position_variant)
	_record_tactical_communication_events([event], {"now_msec": Time.get_ticks_msec(), "cooldown_msec": 250})


func _record_bounding_coordination_feedback(assignment: Dictionary, phase_index: int) -> void:
	if assignment.is_empty():
		return
	var advance_fireteam_id: String = String(assignment.get("advance_fireteam_id", "")).strip_edges().to_lower()
	var cover_fireteam_id: String = String(assignment.get("cover_fireteam_id", "")).strip_edges().to_lower()
	if advance_fireteam_id.is_empty() or cover_fireteam_id.is_empty():
		return
	var cover_label: String = _get_fireteam_display_label(cover_fireteam_id)
	var advance_label: String = _get_fireteam_display_label(advance_fireteam_id)
	var anchor_position_variant: Variant = _resolve_fireteam_anchor_position_for_feedback(cover_fireteam_id, assignment.get("cover_target_position", null))
	var target_position_variant: Variant = _resolve_fireteam_anchor_position_for_feedback(advance_fireteam_id, assignment.get("advance_target_position", null))
	var event: Dictionary = {
		"event_id": "coord_%s_active_%d" % [_sanitize_node_name(String(assignment.get("coordination_id", "bounding"))), Time.get_ticks_msec()],
		"event_type": TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_BOUNDING_ROTATION,
		"fireteam_id": advance_fireteam_id,
		"phase": phase_index,
		"priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_NORMAL,
		"duration_seconds": 2.2,
		"channels": PackedStringArray([
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_SELECTED_FIRETEAM,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MISSION_CONTROL,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MAP_MARKER,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_FTL_BUBBLE,
		]),
		"feedback_action": "go",
		"feedback_state": "cover",
		"short_text": "%s deckt -> %s" % [cover_label, advance_label],
		"detail_text": "Bounding coordination active: %s covers while %s advances" % [cover_label, advance_label],
		"map_label": "COORD",
		"created_msec": Time.get_ticks_msec(),
		"source": TACTICAL_COMMUNICATION_EVENT_SCRIPT.SOURCE_ID,
		"visual_only": true,
		"cooldown_key": "bounding_coordination:%s:%s:%d" % [cover_fireteam_id, advance_fireteam_id, phase_index],
	}
	if typeof(anchor_position_variant) == TYPE_VECTOR2:
		event["anchor_position"] = Vector2(anchor_position_variant)
	if typeof(target_position_variant) == TYPE_VECTOR2:
		event["target_position"] = Vector2(target_position_variant)
	_record_tactical_communication_events([event], {"now_msec": Time.get_ticks_msec(), "cooldown_msec": 500})


func _resolve_fireteam_anchor_position_for_feedback(fireteam_id: String, fallback) -> Variant:
	var anchor = _get_selection_anchor_for_fireteam(fireteam_id)
	if anchor is Node2D:
		return (anchor as Node2D).global_position
	if typeof(fallback) == TYPE_VECTOR2:
		return Vector2(fallback)
	return null


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


func _begin_right_order_context_interaction(screen_position: Vector2, append_mode: bool) -> bool:
	if _is_lz_placement_armed or _is_target_placement_armed:
		return false
	_right_order_press_active = true
	_right_order_drag_active = false
	_right_order_press_screen_position = screen_position
	_right_order_drag_screen_position = screen_position
	_right_order_append_mode = append_mode
	_hide_waypoint_command_menu()
	_hide_area_order_command_menu()
	_update_area_order_overlay(Rect2())
	return true


func _update_right_order_context_drag(screen_position: Vector2) -> bool:
	if not _right_order_press_active:
		return false
	_right_order_drag_screen_position = screen_position
	if not _right_order_drag_active and _right_order_press_screen_position.distance_to(screen_position) < AREA_ORDER_DRAG_THRESHOLD:
		return true
	_right_order_drag_active = true
	if _selected_fireteam_ids.is_empty():
		_last_command_text = "SELECT FIRETEAM FIRST"
		_update_ui()
		_update_area_order_overlay(Rect2())
		return true
	_update_area_order_overlay(_build_selection_rect(_right_order_press_screen_position, screen_position))
	return true


func _finish_right_order_context_interaction(screen_position: Vector2, append_pressed: bool = false) -> bool:
	if not _right_order_press_active:
		return false
	var was_dragging: bool = _right_order_drag_active
	var start_position: Vector2 = _right_order_press_screen_position
	var append_mode: bool = _right_order_append_mode or append_pressed
	_right_order_press_active = false
	_right_order_drag_active = false
	_right_order_press_screen_position = Vector2.ZERO
	_right_order_drag_screen_position = Vector2.ZERO
	_right_order_append_mode = false
	_update_area_order_overlay(Rect2())
	if was_dragging:
		if _selected_fireteam_ids.is_empty():
			_last_command_text = "SELECT FIRETEAM FIRST"
			_update_ui()
			return true
		var area_payload: Dictionary = _build_area_order_payload_from_screen_rect(_build_selection_rect(start_position, screen_position))
		if area_payload.is_empty():
			_last_command_text = "AREA EMPTY"
			_update_ui()
			return true
		var area_order_targets: Array = _create_area_orders_from_payload(_selected_fireteam_ids, area_payload, AREA_ORDER_SCRIPT.COMMAND_TYPE_DEFEND, true, not append_mode)
		if area_order_targets.is_empty():
			_last_command_text = "AREA EMPTY"
			_update_ui()
			return true
		_open_area_order_command_menu(screen_position, area_order_targets, false, append_mode)
		return true
	return _try_open_waypoint_menu_at_position(screen_position, append_mode)


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
	_focused_area_order_ref = {}
	_dragged_waypoint_press_screen_position = screen_position
	_is_dragging_waypoint = true
	_has_dragged_waypoint = false
	_hide_waypoint_command_menu()
	_refresh_button_state()
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
	else:
		_last_command_text = "WAYPOINT SELECTED"
		_refresh_button_state()
		_update_ui()
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


func _delete_selected_order() -> bool:
	if _delete_focused_area_order():
		_refresh_button_state()
		return true
	if _delete_focused_waypoint():
		_refresh_button_state()
		return true
	_focused_area_order_ref = {}
	_focused_waypoint_ref = {}
	return false


func _has_deletable_order_focus() -> bool:
	if not _focused_area_order_ref.is_empty() and _get_area_order_from_ref(_focused_area_order_ref) != null:
		return true
	if not _focused_waypoint_ref.is_empty() and _get_waypoint_from_ref(_focused_waypoint_ref) != null:
		return true
	return false


func _try_focus_area_order_at_position(screen_position: Vector2) -> bool:
	var existing_area_order_target: Dictionary = _find_area_order_target_at_screen_position(screen_position)
	if existing_area_order_target.is_empty():
		return false
	_focused_area_order_ref = existing_area_order_target.duplicate(true)
	_focused_waypoint_ref = {}
	_hide_waypoint_command_menu()
	_last_command_text = "AREA ORDER SELECTED"
	_refresh_button_state()
	_update_ui()
	return true


func _open_waypoint_command_menu(screen_position: Vector2, waypoint_targets: Array, include_delete_action: bool, append_mode: bool = false) -> void:
	var menu := get_node_or_null("../TacticalUI/WaypointCommandMenu") as PopupMenu
	if menu == null:
		return
	_waypoint_menu_targets = []
	for waypoint_target in waypoint_targets:
		_waypoint_menu_targets.append(Dictionary(waypoint_target).duplicate(true))
	_waypoint_menu_append_mode = append_mode
	menu.clear()
	for marker_type_id in PackedStringArray(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_type_ids_for_context", TERRAIN_MARKER_CATALOG_SCRIPT.CONTEXT_MISSION_PLAYER)):
		menu.add_item(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)), _waypoint_menu_id_for_command(String(marker_type_id)))
	if include_delete_action:
		menu.add_separator()
		menu.add_item("Delete", WAYPOINT_MENU_DELETE_ID)
	menu.reset_size()
	menu.position = screen_position + Vector2(10.0, 10.0)
	menu.popup()


func _open_area_order_command_menu(screen_position: Vector2, area_order_targets: Array, include_delete_action: bool, append_mode: bool = false) -> void:
	var menu := get_node_or_null("../TacticalUI/AreaOrderCommandMenu") as PopupMenu
	if menu == null:
		return
	_area_order_menu_targets = []
	for area_order_target in area_order_targets:
		_area_order_menu_targets.append(Dictionary(area_order_target).duplicate(true))
	_area_order_menu_append_mode = append_mode
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
	_waypoint_menu_append_mode = false


func _hide_area_order_command_menu() -> void:
	var menu := get_node_or_null("../TacticalUI/AreaOrderCommandMenu") as PopupMenu
	if menu != null:
		menu.hide()
	_area_order_menu_targets.clear()
	_area_order_menu_append_mode = false


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
	_last_command_text = "WAYPOINT %s%s" % [command_type.to_upper(), " APPEND" if _waypoint_menu_append_mode else ""]
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
	_last_command_text = "AREA %s%s" % [normalized_command_type.to_upper(), " APPEND" if _area_order_menu_append_mode else ""]
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
		_remove_multi_fireteam_plans_for_area_order_id(area_order_id)
		_area_orders_by_id.erase(area_order_id)
		did_delete = true
	if not did_delete:
		return false
	_refresh_order_visuals()
	_last_command_text = "AREA DELETED"
	_update_ui()
	_emit_planning_state_changed()
	return true


func _remove_multi_fireteam_plans_for_area_order_id(area_order_id: String) -> void:
	var normalized_area_order_id: String = area_order_id.strip_edges()
	if normalized_area_order_id.is_empty():
		return
	for plan_id in _multi_fireteam_plans_by_id.keys().duplicate():
		var plan: Dictionary = Dictionary(_multi_fireteam_plans_by_id.get(plan_id, {}))
		var area_context: Dictionary = Dictionary(plan.get("area_context", {}))
		for ref_variant in Array(area_context.get("area_order_refs", [])):
			if typeof(ref_variant) != TYPE_DICTIONARY:
				continue
			if String(Dictionary(ref_variant).get("area_order_id", "")).strip_edges() == normalized_area_order_id:
				_multi_fireteam_plans_by_id.erase(plan_id)
				break


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


func _try_start_drop_sequence(ignore_global_cooldown: bool = false) -> bool:
	if _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND:
		_handoff_active_drop_sequence_to_card()
	if _has_live_drop_sequence_for_craft(_mission_drop_craft_id):
		return false
	if _is_drop_sequence_active():
		_store_primary_drop_sequence_as_parallel()
	if not _has_lz_position:
		return false
	if not ignore_global_cooldown and not preview_mode and _drop_ship_cooldown_remaining > 0.0:
		return false
	if not preview_mode and _live_drop_bootstrap_consumed and _drop_sequence_phase == DROP_SEQUENCE_COMPLETE:
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
		_prepare_drop_sequence_context()
		_embark_units_for_drop(pending_units)
		_drop_sequence_units = pending_units
		_drop_sequence_fireteam_name = _get_drop_fireteam_name_for_units(_drop_sequence_units)
		_drop_sequence_unit_index = 0
		_drop_sequence_timer = 0.0
		_drop_sequence_phase = DROP_SEQUENCE_INBOUND
		_drop_ship_staged = true
		_drop_sequence_visual_only = false
		_drop_sequence_embarked_unit_ids = _build_drop_unit_state_dict(_build_sorted_drop_unit_id_array(_embarked_unit_ids))
		_drop_sequence_position = _get_drop_sequence_staging_position()
		_mission_drop_progress = _build_active_drop_sequence_progress_value()
		_store_selected_mission_dropship_plan()
		_store_active_drop_sequence_card()
		_emit_planning_state_changed()
		_refresh_world_overlays()
		_update_ui()
		return true
	if pending_units.is_empty():
		return false
	_prepare_drop_sequence_context()
	_embark_units_for_drop(pending_units)
	_drop_sequence_units = pending_units
	_drop_sequence_fireteam_name = _get_drop_fireteam_name_for_units(_drop_sequence_units)
	_drop_sequence_unit_index = 0
	_drop_sequence_timer = 0.0
	_drop_sequence_phase = DROP_SEQUENCE_INBOUND
	_drop_ship_staged = true
	_drop_sequence_visual_only = false
	_drop_sequence_embarked_unit_ids = _build_drop_unit_state_dict(_build_sorted_drop_unit_id_array(_embarked_unit_ids))
	_drop_sequence_position = _get_drop_sequence_staging_position()
	_live_drop_bootstrap_consumed = true
	_mission_drop_progress = _build_active_drop_sequence_progress_value()
	_store_selected_mission_dropship_plan()
	_store_active_drop_sequence_card()
	_refresh_world_overlays()
	_update_ui()
	return true


func _embark_units_for_drop(units: Array) -> void:
	var staging_position: Vector2 = _get_drop_sequence_staging_position()
	for index in range(units.size()):
		var unit = units[index]
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		_embarked_unit_ids[unit_id] = true
		_deployed_unit_ids.erase(unit_id)
		_deployed_unit_positions.erase(unit_id)
		var embark_position: Vector2 = staging_position + Vector2(-18.0 * index, 10.0 * index)
		if preview_mode:
			if unit is Node2D:
				(unit as Node2D).global_position = embark_position
			if unit is CanvasItem:
				(unit as CanvasItem).visible = false
		else:
			_enqueue_dropship_embark_effect(unit, unit_id, embark_position)


func _update_drop_sequence(delta: float) -> void:
	_update_primary_drop_sequence(delta)
	_update_parallel_drop_sequences(delta)


func _update_primary_drop_sequence(delta: float) -> void:
	match _drop_sequence_phase:
		DROP_SEQUENCE_INBOUND:
			_drop_sequence_position = _drop_sequence_position.move_toward(_drop_sequence_lz_position, DROP_SHIP_SPEED * delta)
			if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
				_mission_drop_progress = _build_active_drop_sequence_progress_value()
			_store_active_drop_sequence_card()
			if _drop_sequence_position.distance_to(_drop_sequence_lz_position) <= 2.0:
				_drop_sequence_position = _drop_sequence_lz_position
				_drop_sequence_phase = DROP_SEQUENCE_LANDED
				_drop_sequence_timer = 0.0
				_last_command_text = "DROPSHIP LANDED" if _drop_sequence_visual_only else "TOUCHDOWN %s" % _drop_sequence_fireteam_name
				if not _drop_sequence_visual_only:
					_set_mission_dropship_card_feedback(_drop_sequence_craft_id, "Touchdown")
				_store_active_drop_sequence_card()
				_update_ui()
			_refresh_world_overlays()
		DROP_SEQUENCE_LANDED:
			if _drop_sequence_visual_only:
				_refresh_world_overlays()
				return
			_drop_sequence_timer += delta
			if _drop_sequence_timer >= DROP_LANDING_HOLD_SECONDS:
				_drop_sequence_phase = DROP_SEQUENCE_UNLOADING
				_drop_sequence_timer = 0.0
				_mission_drop_progress = _build_active_drop_sequence_progress_value()
				_store_active_drop_sequence_card()
				_update_ui()
		DROP_SEQUENCE_UNLOADING:
			if _advance_primary_drop_sequence_unloading(delta):
				_drop_sequence_phase = DROP_SEQUENCE_COMPLETE
				_drop_sequence_timer = 0.0
				_mission_drop_progress = 100.0
				_last_command_text = "Trupp ab"
				_set_mission_dropship_card_feedback(_drop_sequence_craft_id, "Trupp ab")
				_store_active_drop_sequence_card()
				_store_selected_mission_dropship_plan()
				_emit_planning_state_changed()
				_update_ui()
		DROP_SEQUENCE_COMPLETE:
			_begin_drop_sequence_outbound()
		DROP_SEQUENCE_OUTBOUND:
			var exit_position: Vector2 = _get_drop_sequence_exit_position()
			_drop_sequence_position = _drop_sequence_position.move_toward(exit_position, DROP_SHIP_SPEED * delta)
			if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
				_mission_drop_progress = _build_active_drop_sequence_progress_value()
			_store_active_drop_sequence_card()
			if _drop_sequence_position.distance_to(exit_position) <= 2.0:
				_drop_ship_cooldown_remaining = DROP_SHIP_RECALL_COOLDOWN_SECONDS
				var completed_craft_id: String = _drop_sequence_craft_id.strip_edges()
				var completed_selected: bool = _is_active_drop_sequence_for_craft(_mission_drop_craft_id)
				if completed_selected:
					_drop_ship_requested = false
					_drop_ship_staged = false
					_mission_drop_state = "to_fob"
					_mission_drop_progress = 0.0
					_mission_drop_return_requested = false
				elif not completed_craft_id.is_empty():
					_update_mission_dropship_card_fields(
						completed_craft_id,
						{
							"state": "to_fob",
							"progress": 0.0,
							"drop_ship_requested": false,
							"drop_ship_staged": false,
						}
					)
				_drop_sequence_position = Vector2.ZERO
				_clear_drop_sequence_context()
				_live_drop_bootstrap_consumed = false
				_last_command_text = "DROPSHIP CLEARED"
				_store_selected_mission_dropship_plan()
				_emit_planning_state_changed()
				_update_ui()
				_refresh_world_overlays()
			_refresh_world_overlays()


func _update_parallel_drop_sequences(delta: float) -> void:
	if _parallel_drop_sequences_by_craft.is_empty():
		return
	var completed_craft_ids: Array = []
	var changed: bool = false
	for craft_id_variant in _parallel_drop_sequences_by_craft.keys():
		var craft_id: String = String(craft_id_variant).strip_edges()
		if craft_id.is_empty():
			completed_craft_ids.append(craft_id_variant)
			continue
		var sequence_variant = _parallel_drop_sequences_by_craft.get(craft_id_variant, {})
		if typeof(sequence_variant) != TYPE_DICTIONARY:
			completed_craft_ids.append(craft_id_variant)
			continue
		var sequence: Dictionary = Dictionary(sequence_variant).duplicate(true)
		if not _is_drop_sequence_dict_active(sequence):
			completed_craft_ids.append(craft_id_variant)
			continue
		if _update_drop_sequence_dict(sequence, delta):
			changed = true
		if _is_drop_sequence_dict_active(sequence):
			_parallel_drop_sequences_by_craft[craft_id] = sequence
			_update_mission_dropship_card_fields(craft_id, _build_drop_sequence_card_fields(sequence))
		else:
			completed_craft_ids.append(craft_id)
	for completed_craft_id in completed_craft_ids:
		_parallel_drop_sequences_by_craft.erase(completed_craft_id)
	if changed:
		_store_selected_mission_dropship_plan()
		_emit_planning_state_changed()
		_update_ui()
		_refresh_world_overlays()


func _update_drop_sequence_dict(sequence: Dictionary, delta: float) -> bool:
	var phase: String = String(sequence.get("phase", "")).strip_edges().to_lower()
	match phase:
		DROP_SEQUENCE_INBOUND:
			var lz_position: Vector2 = _coerce_vector2_value(sequence.get("lz_position", Vector2.ZERO), Vector2.ZERO)
			var position: Vector2 = _coerce_vector2_value(sequence.get("position", Vector2.ZERO), Vector2.ZERO)
			position = position.move_toward(lz_position, DROP_SHIP_SPEED * delta)
			sequence["position"] = position
			if position.distance_to(lz_position) <= 2.0:
				sequence["position"] = lz_position
				sequence["phase"] = DROP_SEQUENCE_LANDED
				sequence["timer"] = 0.0
				if not bool(sequence.get("visual_only", false)):
					sequence["card_feedback_text"] = "Touchdown"
					_set_mission_dropship_card_feedback(String(sequence.get("craft_id", "")).strip_edges(), "Touchdown")
					_last_command_text = "TOUCHDOWN %s" % String(sequence.get("fireteam_name", "ALL")).strip_edges()
			return true
		DROP_SEQUENCE_LANDED:
			if bool(sequence.get("visual_only", false)):
				return false
			sequence["timer"] = float(sequence.get("timer", 0.0)) + delta
			if float(sequence.get("timer", 0.0)) >= DROP_LANDING_HOLD_SECONDS:
				sequence["phase"] = DROP_SEQUENCE_UNLOADING
				sequence["timer"] = 0.0
				sequence["progress"] = _build_drop_sequence_progress_value(sequence)
			return true
		DROP_SEQUENCE_UNLOADING:
			if _advance_drop_sequence_unloading_for_sequence(sequence, delta):
				sequence["phase"] = DROP_SEQUENCE_COMPLETE
				sequence["timer"] = 0.0
				sequence["progress"] = 100.0
				sequence["card_feedback_text"] = "Trupp ab"
				_set_mission_dropship_card_feedback(String(sequence.get("craft_id", "")).strip_edges(), "Trupp ab")
				_last_command_text = "Trupp ab"
			return true
		DROP_SEQUENCE_COMPLETE:
			_begin_drop_sequence_outbound_for_sequence(sequence)
			return true
		DROP_SEQUENCE_OUTBOUND:
			var lz_position: Vector2 = _coerce_vector2_value(sequence.get("lz_position", Vector2.ZERO), Vector2.ZERO)
			var approach_angle: String = _sanitize_approach_angle_name(String(sequence.get("approach_angle", "NW")))
			var exit_position: Vector2 = _get_drop_staging_position_for_lz(lz_position, approach_angle)
			var position: Vector2 = _coerce_vector2_value(sequence.get("position", Vector2.ZERO), Vector2.ZERO)
			position = position.move_toward(exit_position, DROP_SHIP_SPEED * delta)
			sequence["position"] = position
			if position.distance_to(exit_position) <= 2.0:
				_complete_parallel_drop_sequence_return(sequence, exit_position)
				sequence["phase"] = ""
			return true
		_:
			return false


func _advance_primary_drop_sequence_unloading(delta: float) -> bool:
	if _drop_sequence_units.is_empty():
		return true
	_drop_sequence_timer += maxf(delta, 0.0)
	while _drop_sequence_timer >= DROP_UNLOAD_INTERVAL_SECONDS and _drop_sequence_unit_index < _drop_sequence_units.size():
		_drop_sequence_timer -= DROP_UNLOAD_INTERVAL_SECONDS
		_deploy_next_embarked_unit()
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		_mission_drop_passenger_count = _embarked_unit_ids.size()
		_mission_drop_progress = _build_active_drop_sequence_progress_value()
	_store_active_drop_sequence_card()
	_store_selected_mission_dropship_plan()
	_emit_planning_state_changed()
	_update_ui()
	_refresh_world_overlays()
	return _drop_sequence_unit_index >= _drop_sequence_units.size()


func _advance_drop_sequence_unloading_for_sequence(sequence: Dictionary, delta: float) -> bool:
	var units: Array = Array(sequence.get("units", []))
	if units.is_empty():
		return true
	sequence["timer"] = float(sequence.get("timer", 0.0)) + maxf(delta, 0.0)
	while float(sequence.get("timer", 0.0)) >= DROP_UNLOAD_INTERVAL_SECONDS and int(sequence.get("unit_index", 0)) < units.size():
		sequence["timer"] = float(sequence.get("timer", 0.0)) - DROP_UNLOAD_INTERVAL_SECONDS
		_deploy_next_embarked_unit_for_sequence(sequence)
	sequence["progress"] = _build_drop_sequence_progress_value(sequence)
	return int(sequence.get("unit_index", 0)) >= units.size()


func _set_mission_dropship_card_feedback(craft_id: String, feedback_text: String) -> void:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return
	_update_mission_dropship_card_fields(
		normalized_craft_id,
		{
			"card_feedback_text": feedback_text.strip_edges(),
		}
	)


func _complete_drop_sequence_deployment_for_sequence(sequence: Dictionary) -> void:
	if bool(sequence.get("visual_only", false)):
		return
	if String(sequence.get("phase", "")).strip_edges().to_lower() != DROP_SEQUENCE_UNLOADING:
		sequence["phase"] = DROP_SEQUENCE_UNLOADING
		sequence["timer"] = 0.0
		sequence["card_feedback_text"] = "Touchdown"
		_last_command_text = "TOUCHDOWN %s" % String(sequence.get("fireteam_name", "ALL")).strip_edges()
		_set_mission_dropship_card_feedback(String(sequence.get("craft_id", "")).strip_edges(), "Touchdown")
	sequence["position"] = _coerce_vector2_value(sequence.get("lz_position", Vector2.ZERO), Vector2.ZERO)


func _begin_drop_sequence_outbound_for_sequence(sequence: Dictionary) -> void:
	if bool(sequence.get("visual_only", false)):
		return
	var craft_id: String = String(sequence.get("craft_id", "")).strip_edges()
	if craft_id == _mission_drop_craft_id.strip_edges():
		_mission_drop_state = "to_fob"
		_mission_drop_passenger_count = _embarked_unit_ids.size()
		_mission_drop_return_requested = true
		_mission_drop_progress = _build_drop_sequence_progress_value(sequence)
	sequence["phase"] = DROP_SEQUENCE_OUTBOUND
	sequence["timer"] = 0.0
	_last_command_text = "%s AB | DROPSHIP RTB" % String(sequence.get("fireteam_name", "ALL")).strip_edges()


func _complete_parallel_drop_sequence_return(sequence: Dictionary, exit_position: Vector2) -> void:
	var craft_id: String = String(sequence.get("craft_id", "")).strip_edges()
	if craft_id.is_empty():
		return
	_drop_ship_cooldown_remaining = DROP_SHIP_RECALL_COOLDOWN_SECONDS
	var return_fields: Dictionary = {
		"state": "to_fob",
		"progress": 100.0,
		"drop_ship_requested": false,
		"drop_ship_staged": false,
		"drop_sequence_position": exit_position,
		"dropship_position": exit_position,
	}
	_update_mission_dropship_card_fields(craft_id, return_fields)
	if craft_id == _mission_drop_craft_id.strip_edges():
		_drop_ship_requested = false
		_drop_ship_staged = false
		_mission_drop_state = "to_fob"
		_mission_drop_progress = 100.0
		_mission_drop_return_requested = false
	_last_command_text = "DROPSHIP CLEARED"


func _deploy_next_embarked_unit_for_sequence(sequence: Dictionary) -> void:
	var units: Array = Array(sequence.get("units", []))
	var unit_index: int = int(sequence.get("unit_index", 0))
	if unit_index >= units.size():
		return
	var unit = units[unit_index]
	var unload_index: int = unit_index
	sequence["unit_index"] = unit_index + 1
	if unit == null or not unit.has_method("get_unit_id"):
		return
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
	var embarked_ids: Dictionary = Dictionary(sequence.get("embarked_unit_ids", {}))
	embarked_ids.erase(unit_id)
	sequence["embarked_unit_ids"] = embarked_ids
	_embarked_unit_ids.erase(unit_id)
	_deployed_unit_ids[unit_id] = true
	var lz_position: Vector2 = _coerce_vector2_value(sequence.get("lz_position", Vector2.ZERO), Vector2.ZERO)
	var approach_angle: String = _sanitize_approach_angle_name(String(sequence.get("approach_angle", "NW")))
	var deploy_position: Vector2 = lz_position + _get_unload_offset(unload_index, approach_angle)
	_deployed_unit_positions[unit_id] = deploy_position
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
		unit.call("show_event_text", "AB", Color(0.55, 1.0, 0.72, 1.0), 1.5)
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower() if unit.has_method("get_fireteam_id") else ""
	if not fireteam_id.is_empty():
		_post_drop_security_pending_fireteam_ids[fireteam_id] = true
		if preview_mode:
			_maybe_start_active_phase_for_fireteam(fireteam_id)
		else:
			_runtime_activation_pending_fireteam_ids[fireteam_id] = true
	_last_command_text = "AB %d/%d" % [int(sequence.get("unit_index", 0)), units.size()]


func _show_drop_team_event_text_for_sequence(sequence: Dictionary, event_text: String, color: Color, duration_seconds: float) -> void:
	for unit in Array(sequence.get("units", [])):
		if unit == null or not unit.has_method("show_event_text"):
			continue
		unit.call("show_event_text", event_text, color, duration_seconds)


func _complete_drop_sequence_deployment() -> void:
	if _drop_sequence_visual_only:
		return
	if _drop_sequence_phase != DROP_SEQUENCE_UNLOADING:
		_drop_sequence_phase = DROP_SEQUENCE_UNLOADING
		_drop_sequence_timer = 0.0
		_last_command_text = "TOUCHDOWN %s" % _drop_sequence_fireteam_name
		_set_mission_dropship_card_feedback(_drop_sequence_craft_id, "Touchdown")
		_update_ui()
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		_mission_drop_passenger_count = _embarked_unit_ids.size()
	_drop_sequence_position = _drop_sequence_lz_position
	_store_active_drop_sequence_card()
	_store_selected_mission_dropship_plan()
	_emit_planning_state_changed()


func _begin_drop_sequence_outbound() -> void:
	if _drop_sequence_visual_only:
		return
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		_mission_drop_state = "to_fob"
		_mission_drop_passenger_count = _embarked_unit_ids.size()
		_mission_drop_return_requested = true
	_drop_sequence_phase = DROP_SEQUENCE_OUTBOUND
	_drop_sequence_timer = 0.0
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		_mission_drop_progress = _build_active_drop_sequence_progress_value()
	_last_command_text = "%s AB | DROPSHIP RTB" % _drop_sequence_fireteam_name
	_store_active_drop_sequence_card()
	_store_selected_mission_dropship_plan()
	_emit_planning_state_changed()
	_update_ui()
	_refresh_world_overlays()


func _handoff_active_drop_sequence_to_card() -> void:
	if not _is_drop_sequence_active():
		return
	var was_outbound: bool = _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND
	if _is_active_drop_sequence_for_craft(_mission_drop_craft_id):
		_mission_drop_progress = _build_active_drop_sequence_progress_value()
		if was_outbound:
			_mission_drop_state = "to_fob"
	_store_active_drop_sequence_card()
	if was_outbound and not _drop_sequence_craft_id.strip_edges().is_empty():
		_update_mission_dropship_card_fields(
			_drop_sequence_craft_id,
			{
				"state": "to_fob",
				"progress": _build_active_drop_sequence_progress_value(),
				"drop_ship_requested": false,
				"drop_ship_staged": false,
			}
		)
	_drop_sequence_position = Vector2.ZERO
	_clear_drop_sequence_context()
	_live_drop_bootstrap_consumed = false
	if was_outbound or _mission_drop_state == "to_fob":
		_drop_ship_requested = false
		_drop_ship_staged = false
	_store_selected_mission_dropship_plan()
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
	_drop_sequence_embarked_unit_ids.erase(unit_id)
	_embarked_unit_ids.erase(unit_id)
	_deployed_unit_ids[unit_id] = true
	var deploy_position: Vector2 = _drop_sequence_lz_position + _get_unload_offset(unload_index, _get_drop_sequence_approach_angle_name())
	_deployed_unit_positions[unit_id] = deploy_position
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
		unit.call("show_event_text", "AB", Color(0.55, 1.0, 0.72, 1.0), 1.5)
	var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower() if unit.has_method("get_fireteam_id") else ""
	if not fireteam_id.is_empty():
		_post_drop_security_pending_fireteam_ids[fireteam_id] = true
		if preview_mode:
			_maybe_start_active_phase_for_fireteam(fireteam_id)
		else:
			_runtime_activation_pending_fireteam_ids[fireteam_id] = true
	_last_command_text = "AB %d/%d" % [_drop_sequence_unit_index, _drop_sequence_units.size()]
	_update_ui()


func _show_drop_team_event_text(event_text: String, color: Color, duration_seconds: float) -> void:
	for unit in _drop_sequence_units:
		if unit == null or not unit.has_method("show_event_text"):
			continue
		unit.call("show_event_text", event_text, color, duration_seconds)


func _is_drop_sequence_active() -> bool:
	return _drop_sequence_phase == DROP_SEQUENCE_INBOUND or _drop_sequence_phase == DROP_SEQUENCE_LANDED or _drop_sequence_phase == DROP_SEQUENCE_UNLOADING or _drop_sequence_phase == DROP_SEQUENCE_COMPLETE or _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND


func _is_active_drop_sequence_for_craft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	return _is_drop_sequence_active() and not normalized_craft_id.is_empty() and normalized_craft_id == _drop_sequence_craft_id.strip_edges()


func _has_live_drop_sequence_for_craft(craft_id: String) -> bool:
	var normalized_craft_id: String = craft_id.strip_edges()
	if normalized_craft_id.is_empty():
		return false
	if _is_active_drop_sequence_for_craft(normalized_craft_id):
		return true
	if not _parallel_drop_sequences_by_craft.has(normalized_craft_id):
		return false
	var sequence_variant = _parallel_drop_sequences_by_craft.get(normalized_craft_id, {})
	return typeof(sequence_variant) == TYPE_DICTIONARY and _is_drop_sequence_dict_active(Dictionary(sequence_variant))


func _is_drop_sequence_dict_active(sequence: Dictionary) -> bool:
	var phase: String = String(sequence.get("phase", "")).strip_edges().to_lower()
	return phase == DROP_SEQUENCE_INBOUND or phase == DROP_SEQUENCE_LANDED or phase == DROP_SEQUENCE_UNLOADING or phase == DROP_SEQUENCE_COMPLETE or phase == DROP_SEQUENCE_OUTBOUND


func _capture_active_drop_sequence() -> Dictionary:
	return {
		"phase": _drop_sequence_phase,
		"units": _drop_sequence_units.duplicate(),
		"unit_index": _drop_sequence_unit_index,
		"timer": _drop_sequence_timer,
		"position": _drop_sequence_position,
		"fireteam_name": _drop_sequence_fireteam_name,
		"visual_only": _drop_sequence_visual_only,
		"craft_id": _drop_sequence_craft_id,
		"display_name": _drop_sequence_display_name,
		"lz_position": _drop_sequence_lz_position,
		"approach_angle": _drop_sequence_approach_angle,
		"embarked_unit_ids": _drop_sequence_embarked_unit_ids.duplicate(true),
		"card_feedback_text": _get_mission_dropship_card_feedback_text(_find_raw_mission_dropship_card_entry(_drop_sequence_craft_id)),
	}


func _store_primary_drop_sequence_as_parallel() -> bool:
	if not _is_drop_sequence_active() or _drop_sequence_craft_id.strip_edges().is_empty():
		return false
	var sequence: Dictionary = _capture_active_drop_sequence()
	var craft_id: String = String(sequence.get("craft_id", "")).strip_edges()
	_parallel_drop_sequences_by_craft[craft_id] = sequence
	_update_mission_dropship_card_fields(craft_id, _build_drop_sequence_card_fields(sequence))
	_clear_drop_sequence_context()
	_live_drop_bootstrap_consumed = false
	return true


func _prepare_drop_sequence_context() -> void:
	_drop_sequence_craft_id = _mission_drop_craft_id.strip_edges()
	if _drop_sequence_craft_id.is_empty():
		_drop_sequence_craft_id = "mission_drop_sequence"
	_drop_sequence_display_name = _mission_drop_display_name if not _mission_drop_display_name.is_empty() else "Dropship"
	_drop_sequence_lz_position = _lz_position
	_drop_sequence_approach_angle = _get_approach_angle_name()
	_drop_sequence_embarked_unit_ids = _build_drop_unit_state_dict(_build_sorted_drop_unit_id_array(_embarked_unit_ids))


func _clear_drop_sequence_context() -> void:
	_drop_sequence_phase = ""
	_drop_sequence_units = []
	_drop_sequence_unit_index = 0
	_drop_sequence_timer = 0.0
	_drop_sequence_fireteam_name = "ALL"
	_drop_sequence_visual_only = false
	_drop_sequence_craft_id = ""
	_drop_sequence_display_name = ""
	_drop_sequence_lz_position = Vector2.ZERO
	_drop_sequence_approach_angle = "NW"
	_drop_sequence_embarked_unit_ids.clear()


func _get_drop_sequence_approach_angle_name() -> String:
	return _sanitize_approach_angle_name(_drop_sequence_approach_angle, _get_approach_angle_name())


func _get_drop_approach_offset() -> Vector2:
	return Vector2(APPROACH_OFFSETS.get(_get_approach_angle_name(), Vector2(180.0, -112.0)))


func _get_drop_staging_position() -> Vector2:
	var offset: Vector2 = _get_drop_approach_offset()
	if offset.length_squared() <= 0.001:
		offset = Vector2(180.0, -112.0)
	var map_bounds: Rect2 = _get_map_world_bounds()
	var map_span: float = maxf(maxf(map_bounds.size.x, map_bounds.size.y) * DROP_OFFMAP_DISTANCE_MULTIPLIER, DROP_OFFMAP_MIN_DISTANCE)
	return _lz_position + offset.normalized() * map_span


func _get_drop_sequence_staging_position() -> Vector2:
	var offset: Vector2 = Vector2(APPROACH_OFFSETS.get(_get_drop_sequence_approach_angle_name(), Vector2(180.0, -112.0)))
	if offset.length_squared() <= 0.001:
		offset = Vector2(180.0, -112.0)
	var map_bounds: Rect2 = _get_map_world_bounds()
	var map_span: float = maxf(maxf(map_bounds.size.x, map_bounds.size.y) * DROP_OFFMAP_DISTANCE_MULTIPLIER, DROP_OFFMAP_MIN_DISTANCE)
	return _drop_sequence_lz_position + offset.normalized() * map_span


func _get_primary_dropship_target_position(current_dropship_position: Vector2) -> Vector2:
	if _drop_sequence_phase == DROP_SEQUENCE_OUTBOUND or _mission_drop_state == "to_fob":
		return _get_drop_exit_position()
	if _has_lz_position:
		return _lz_position
	return current_dropship_position


func _get_drop_exit_position() -> Vector2:
	return _get_drop_staging_position()


func _get_drop_sequence_exit_position() -> Vector2:
	return _get_drop_sequence_staging_position()


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
	var fallback_lz_position: Vector2 = _drop_sequence_lz_position if _is_drop_sequence_active() else _lz_position
	return Rect2(fallback_lz_position - Vector2(256.0, 192.0), Vector2(512.0, 384.0))


func _get_dropship_marker_texture() -> Texture2D:
	match _drop_sequence_phase:
		DROP_SEQUENCE_OUTBOUND:
			return _get_dropship_texture_for_angle(_get_drop_sequence_approach_angle_name())
		_:
			return _get_dropship_texture_for_angle(_get_opposite_approach_angle_name(_get_drop_sequence_approach_angle_name()))


func _get_mission_dropship_texture(card: Dictionary = {}) -> Texture2D:
	if _is_drop_sequence_active() and card.is_empty():
		return _get_dropship_marker_texture()
	var state: String = String(card.get("state", _mission_drop_state)).strip_edges().to_lower()
	var approach_angle: String = _sanitize_approach_angle_name(String(card.get("approach_angle", "")), _get_approach_angle_name())
	match state:
		"to_mission", DROP_SEQUENCE_INBOUND, DROP_SEQUENCE_LANDED, DROP_SEQUENCE_UNLOADING, DROP_SEQUENCE_COMPLETE:
			return _get_dropship_texture_for_angle(_get_opposite_approach_angle_name(approach_angle))
		"to_fob", DROP_SEQUENCE_OUTBOUND:
			return _get_dropship_texture_for_angle(approach_angle)
		"waiting":
			return _get_dropship_texture_for_angle("SE")
		_:
			var mission_drop_texture := _load_optional_texture(String(card.get("texture_path", _mission_drop_texture_path)).strip_edges())
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


func _get_opposite_approach_angle_name(angle_name: String = "") -> String:
	var normalized_angle: String = _sanitize_approach_angle_name(angle_name, _get_approach_angle_name()) if not angle_name.strip_edges().is_empty() else _get_approach_angle_name()
	match normalized_angle:
		"NE":
			return "SW"
		"SW":
			return "NE"
		"SE":
			return "NW"
		_:
			return "SE"


func _get_units_for_drop_operation() -> Array:
	var selected_payload_units: Array = _get_selected_mission_dropship_payload_units()
	if not selected_payload_units.is_empty():
		return selected_payload_units
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


func _get_selected_mission_dropship_payload_units() -> Array:
	var selected_card: Dictionary = _find_mission_dropship_card_entry(_mission_drop_craft_id)
	if selected_card.is_empty() or not bool(selected_card.get("has_embarked_payload", false)):
		return []
	var payload_ids: Array = Array(selected_card.get("embarked_unit_ids", []))
	if payload_ids.is_empty():
		return []
	var result: Array = []
	for unit_id_variant in payload_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or _deployed_unit_ids.has(unit_id):
			continue
		var unit = _find_friendly_unit_by_id(unit_id)
		if unit != null:
			result.append(unit)
	return result


func _get_selected_mission_dropship_card_fireteam_ids() -> PackedStringArray:
	var selected_card: Dictionary = _find_raw_mission_dropship_card_entry(_mission_drop_craft_id)
	if selected_card.is_empty():
		selected_card = _find_mission_dropship_card_entry(_mission_drop_craft_id)
	if selected_card.is_empty():
		return PackedStringArray()
	return _extract_mission_dropship_card_fireteam_ids(selected_card)


func _get_drop_fireteam_id() -> String:
	var card_fireteam_ids: PackedStringArray = _get_selected_mission_dropship_card_fireteam_ids()
	if card_fireteam_ids.size() == 1:
		return String(card_fireteam_ids[0]).strip_edges().to_lower()
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


func _get_drop_fireteam_name_for_units(units: Array) -> String:
	var fireteam_ids: Array = _build_fireteam_ids_for_drop_units(units)
	if fireteam_ids.size() == 1:
		return _get_fireteam_display_label(String(fireteam_ids[0]))
	return _get_drop_fireteam_name()


func _build_fireteam_ids_for_drop_units(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit == null or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	result.sort()
	return result


func _build_fireteam_ids_for_unit_ids(unit_ids: Array) -> Array:
	var result: Array = []
	for unit_id_variant in unit_ids:
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var unit = _find_friendly_unit_by_id(unit_id)
		if unit == null or not unit.has_method("get_fireteam_id"):
			continue
		var fireteam_id: String = String(unit.call("get_fireteam_id")).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	result.sort()
	return result


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


func _sanitize_deployed_unit_positions(position_state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in position_state.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var position_variant = position_state[unit_id_variant]
		if typeof(position_variant) == TYPE_VECTOR2:
			result[unit_id] = Vector2(position_variant)
		elif typeof(position_variant) == TYPE_DICTIONARY:
			var position_dict: Dictionary = Dictionary(position_variant)
			result[unit_id] = Vector2(float(position_dict.get("x", 0.0)), float(position_dict.get("y", 0.0)))
		elif typeof(position_variant) == TYPE_ARRAY and Array(position_variant).size() >= 2:
			var position_array: Array = Array(position_variant)
			result[unit_id] = Vector2(float(position_array[0]), float(position_array[1]))
	return result


func _serialize_deployed_unit_positions() -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in _deployed_unit_positions.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or not _deployed_unit_ids.has(unit_id):
			continue
		var position_variant = _deployed_unit_positions[unit_id_variant]
		if typeof(position_variant) == TYPE_VECTOR2:
			result[unit_id] = Vector2(position_variant)
	return result


func _prune_deployed_unit_positions() -> void:
	for unit_id_variant in _deployed_unit_positions.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty() or not _deployed_unit_ids.has(unit_id):
			_deployed_unit_positions.erase(unit_id_variant)


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
					var deploy_position: Vector2 = Vector2.ZERO
					if _deployed_unit_positions.has(unit_id):
						deploy_position = Vector2(_deployed_unit_positions[unit_id])
					else:
						var deploy_lz_position: Vector2 = _drop_sequence_lz_position if _is_drop_sequence_active() else _lz_position
						var deploy_approach_angle: String = _get_drop_sequence_approach_angle_name() if _is_drop_sequence_active() else _get_approach_angle_name()
						deploy_position = deploy_lz_position + _get_unload_offset(deployed_index, deploy_approach_angle)
						_deployed_unit_positions[unit_id] = deploy_position
					_enqueue_dropship_deploy_effect(unit, unit_id, deploy_position)
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


func _get_unload_offset(index: int, approach_angle_name: String = "") -> Vector2:
	var base_offset: Vector2 = DROP_UNLOAD_OFFSETS[index] if index >= 0 and index < DROP_UNLOAD_OFFSETS.size() else Vector2(28.0 * float(index), 0.0)
	var resolved_angle_name: String = _sanitize_approach_angle_name(approach_angle_name, _get_approach_angle_name()) if not approach_angle_name.strip_edges().is_empty() else _get_approach_angle_name()
	match resolved_angle_name:
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


func _fireteam_deploy_effects_are_applied(fireteam_id: String) -> bool:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return false
	var checked_deployed_member: bool = false
	var deployed_unit_lookup: Dictionary = {}
	for unit in _get_fireteam_units(normalized_fireteam_id, false):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty() or not _deployed_unit_ids.has(unit_id):
			continue
		checked_deployed_member = true
		deployed_unit_lookup[unit_id] = true
	var simulation_root = get_node_or_null("../SimulationRoot")
	if simulation_root != null:
		for effect_variant in Array(simulation_root.get("effects_queue")):
			if typeof(effect_variant) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = Dictionary(effect_variant)
			if String(effect.get("effect_type", "")) != "dropship_deploy_unit":
				continue
			if deployed_unit_lookup.has(String(effect.get("unit_id", "")).strip_edges()):
				return false
	return checked_deployed_member


func _flush_pending_drop_runtime_phase_starts() -> void:
	if preview_mode or _runtime_activation_pending_fireteam_ids.is_empty():
		return
	for fireteam_id_variant in _runtime_activation_pending_fireteam_ids.keys():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or not _is_fireteam_runtime_active(fireteam_id):
			continue
		if _post_drop_security_pending_fireteam_ids.has(fireteam_id) and not _fireteam_deploy_effects_are_applied(fireteam_id):
			continue
		if _maybe_start_active_phase_for_fireteam(fireteam_id):
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


func _maybe_start_active_phase_for_fireteam(fireteam_id: String) -> bool:
	if preview_mode or fireteam_id.strip_edges().is_empty():
		return false
	var active_phase_index: int = LIVE_ORDER_PHASE_INDEX
	if PHASE_PLANNING_ENABLED:
		var phase_controller = _get_phase_controller()
		if phase_controller == null or not phase_controller.has_method("get_active_phase_index"):
			return false
		active_phase_index = int(phase_controller.call("get_active_phase_index"))
		if active_phase_index < 0:
			return false
	if _post_drop_security_pending_fireteam_ids.has(fireteam_id):
		var applied_post_drop_security: bool = _apply_post_drop_360_security_behavior(fireteam_id, active_phase_index)
		if applied_post_drop_security:
			_post_drop_security_pending_fireteam_ids.erase(fireteam_id)
		return applied_post_drop_security
	if _phase_execution_by_fireteam.has(fireteam_id):
		return true
	var plan = _order_plans_by_key.get(_build_order_plan_key(fireteam_id, active_phase_index), null)
	if plan != null and not plan.waypoints.is_empty():
		for waypoint in plan.waypoints:
			if waypoint != null:
				waypoint.status = FIRETEAM_WAYPOINT_SCRIPT.STATUS_PENDING
		plan.status = FIRETEAM_ORDER_PLAN_SCRIPT.STATUS_PENDING
		plan.active_waypoint_index = -1
		_activate_next_waypoint_for_plan(plan, fireteam_id, 0)
		_post_drop_security_pending_fireteam_ids.erase(fireteam_id)
		return true
	return _apply_default_fireteam_behavior(fireteam_id, active_phase_index)
