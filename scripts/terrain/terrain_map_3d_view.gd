class_name TerrainMap3DView
extends CanvasLayer

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")
const FOG_OF_WAR_MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const CONTACT_DENSITY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/tactical/visuals/contact_density_overlay.gd")

const VIEWPORT_CONTAINER_NAME: String = "ViewportContainer"
const VIEWPORT_NAME: String = "SubViewport"
const WORLD_ROOT_NAME: String = "WorldRoot"
const MAP_ROOT_NAME: String = "MapRoot3D"
const MARKER_ROOT_NAME: String = "MarkerRoot3D"
const FOW_ROOT_NAME: String = "FogOfWarRoot3D"
const PATROL_ROOT_NAME: String = "PatrolRoot3D"
const SELECTION_ROOT_NAME: String = "SelectionRoot3D"
const UNIT_ROOT_NAME: String = "UnitRoot3D"
const ORDER_ROOT_NAME: String = "OrderRoot3D"
const CONTACT_ROOT_NAME: String = "ContactRoot3D"
const CONTACT_DENSITY_ROOT_NAME: String = "ContactDensityRoot3D"
const DROP_ROOT_NAME: String = "DropRoot3D"
const STATUS_ROOT_NAME: String = "StatusRoot3D"
const FEEDBACK_BUBBLE_HUD_ROOT_NAME: String = "FeedbackBubbleHudRoot"
const CAMERA_NAME: String = "Camera3D"
const LIGHT_NAME: String = "SunLight3D"
const ENVIRONMENT_NAME: String = "WorldEnvironment"
const RENDER_MONITOR_NAMES: PackedStringArray = [
	"RENDER_TOTAL_OBJECTS_IN_FRAME",
	"RENDER_TOTAL_PRIMITIVES_IN_FRAME",
	"RENDER_TOTAL_DRAW_CALLS_IN_FRAME",
	"RENDER_VIDEO_MEM_USED",
	"RENDER_TEXTURE_MEM_USED",
	"RENDER_BUFFER_MEM_USED",
	"PIPELINE_COMPILATIONS_CANVAS",
	"PIPELINE_COMPILATIONS_MESH",
	"PIPELINE_COMPILATIONS_SURFACE",
	"PIPELINE_COMPILATIONS_DRAW",
	"PIPELINE_COMPILATIONS_SPECIALIZATION",
]
const CONTACT_DENSITY_UPDATE_INTERVAL_MSEC: int = 250
const CONTACT_DENSITY_CELL_SIZE_WORLD: float = 128.0
const CONTACT_DENSITY_MAX_SOURCE_CONTACTS: int = 96
const CONTACT_DENSITY_MAX_HEAT_CELLS: int = 48


const TERRAIN_3D_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const TERRAIN_SURFACE_VISUAL_THEME_CATALOG_PATH: String = "res://data/terrain_surface_visual_theme_catalog.json"
const NPC_UNIT_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const WEAPON_FIRE_VFX_CATALOG_PATH: String = "res://data/weapon_fire_vfx_catalog.json"
const TILE_SPACING: float = 1.0
const TILE_THICKNESS: float = 0.035
const HEIGHT_STEP: float = 0.5
const OBJECT_HEIGHT_STEP: float = 0.42
const CAMERA_DEFAULT_SIZE: float = 34.0
const CAMERA_MIN_SIZE: float = 5.5
const CAMERA_MAX_SIZE: float = 120.0
const CAMERA_ZOOM_STEP: float = 2.2
const CAMERA_PAN_UNITS_PER_SECOND: float = 9.0
const CAMERA_DRAG_PAN_FACTOR: float = 0.065
const CONTINUOUS_REDRAW_AFTER_CAMERA_MSEC: int = 220
const UNIT_PROXY_SMOOTH_SPEED: float = 18.0
const UNIT_PROXY_SNAP_DISTANCE: float = 2.4
const MOVEMENT_STEP_SFX_RATE_LIMIT_MSEC: int = 420
const DEFAULT_HALF_TILE_WIDTH: float = 64.0
const DEFAULT_HALF_TILE_HEIGHT: float = 32.0
const TILE_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_SW.png")
const SPACE_STATION_COLORMAP_TEXTURE: Texture2D = preload("res://Assets/curated/kenney/space_station/models/Textures/colormap.png")
const SPACE_KIT_TERRAIN_TOP_SAMPLE: Vector2i = Vector2i(256, 315)
const SPACE_KIT_TERRAIN_TOP_COLOR_FALLBACK: Color = Color(1.0, 0.6235, 0.4667, 1.0)
const CLIFF_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_SE.png")
const CLIFF_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_SW.png")
const CLIFF_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_NE.png")
const CLIFF_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_NW.png")
const CLIFF_CORNER_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_SE.png")
const CLIFF_CORNER_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_SW.png")
const CLIFF_CORNER_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_NE.png")
const CLIFF_CORNER_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_NW.png")
const RAMP_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_SE.png")
const RAMP_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_SW.png")
const RAMP_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_NE.png")
const RAMP_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_rampLarge_NW.png")
const SLOPE_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_side_SE.png")
const SLOPE_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_side_SW.png")
const SLOPE_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_side_NE.png")
const SLOPE_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_side_NW.png")
const WALL_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wall_SE.png")
const WALL_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wall_SW.png")
const WALL_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wall_NE.png")
const WALL_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wall_NW.png")
const WALL_CORNER_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_SE.png")
const WALL_CORNER_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_SW.png")
const WALL_CORNER_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_NE.png")
const WALL_CORNER_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_wallCorner_NW.png")
const ROCK_SMALL_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/rock_SW.png")
const ROCK_LARGE_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/rock_largeB_SW.png")
const DEFAULT_DROPSHIP_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/craft_speederB_SE.png")
const FRIENDLY_UNIT_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/astronautA_SW.png")
const ENEMY_UNIT_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/astronautB_SW.png")
const TEXTURE_CARD_PIXEL_SIZE: float = 0.0154
const TILE_TEXTURE_PIXEL_SIZE: float = 0.0154
const UNIT_TEXTURE_PIXEL_SIZE: float = 0.0150
const DROPSHIP_TEXTURE_PIXEL_SIZE: float = 0.0152
const STATUS_LABEL_PIXEL_SIZE: float = 0.018
const STATUS_LABEL_HEIGHT: float = 1.16
const MOVEMENT_LABEL_HEIGHT: float = 1.06
const FIXED_CARD_YAW_DEGREES: float = 45.0
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)
const KENNEY_MODEL_ROOT: String = "res://Assets/kenney_space-kit/Models/GLTF format"
const KENNEY_AUTHORING_OFFSET_X: float = 2.0
const KENNEY_AUTHORING_OFFSET_Z: float = 1.5
const KENNEY_OFFSET_EPSILON: float = 0.01
const FRIENDLY_UNIT_MODEL_NAME: String = "astronautA"
const ENEMY_UNIT_MODEL_NAME: String = "astronautB"
const DROPSHIP_MODEL_NAME: String = "craft_speederB"
const UNIT_MODEL_SCALE: float = 0.66
const UNIT_FALLBACK_BODY_RADIUS: float = 0.18
const UNIT_FALLBACK_BODY_HEIGHT: float = 0.585
const UNIT_BASE_RADIUS: float = 0.27
const UNIT_BASE_HEIGHT: float = 0.034
const DROPSHIP_MODEL_SCALE: float = 1.48
const DROPSHIP_MODEL_FORWARD_ROTATION_OFFSET_DEGREES: float = 180.0
const AIR_LAYER_ID: String = "mission_air"
const AIR_LAYER_DEFAULT_TEAM_ID: String = "team_alpha"
const AIR_LAYER_MIN_CLEARANCE: float = 0.72
const AIR_LAYER_DEFAULT_CLEARANCE: float = 1.28
const FOW_OVERLAY_HEIGHT: float = 0.032
const FOW_OVERLAY_SURFACE_Y_OFFSET: float = 0.074
const FOW_BLACKOUT_COVER_Y_OFFSET: float = 0.42
const FOW_KNOWN_DIM_COLOR: Color = Color(0.02, 0.05, 0.06, 0.28)
const FOW_EXPLORED_DIM_COLOR: Color = Color(0.02, 0.04, 0.06, 0.62)
const FOW_UNKNOWN_BLACK_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const UNIT_AIM_POSE_WEAPON_PITCH_DEGREES: float = -30.0
const UNIT_AIM_POSE_WEAPON_FORWARD_OFFSET: float = 0.026
const UNIT_READY_POSE_WEAPON_PITCH_DEGREES: float = -14.0
const UNIT_READY_POSE_WEAPON_FORWARD_OFFSET: float = 0.014
const EDITOR_EMPTY_BACKGROUND_COLOR: Color = Color(0.12, 0.13, 0.12, 1.0)
const EDITOR_LIGHT_ROTATION_DEGREES: Vector3 = Vector3(-58.0, -32.0, 0.0)
const EDITOR_LIGHT_ENERGY: float = 1.18
const EDITOR_LIGHT_SHADOW_ENABLED_DEFAULT: bool = true
const EDITOR_LIGHT_SHADOW_OPACITY: float = 0.42
const EDITOR_LIGHT_SHADOW_BLUR: float = 2.15
const EDITOR_AMBIENT_LIGHT_COLOR: Color = Color(0.82, 0.86, 0.88, 1.0)
const EDITOR_AMBIENT_LIGHT_ENERGY: float = 0.92
const TILE_GRID_LINE_COLOR: Color = Color(0.56, 0.97, 1.0, 0.96)
const TILE_GRID_LINE_SHADOW_COLOR: Color = Color(0.015, 0.025, 0.03, 0.96)
const TILE_GRID_LINE_WIDTH_FACTOR: float = 0.045
const TILE_GRID_LINE_SHADOW_WIDTH_FACTOR: float = 0.078
const TILE_GRID_LINE_SURFACE_Y_OFFSET: float = 0.058
const TILE_GRID_LINE_HIGHLIGHT_Y_OFFSET: float = 0.004
const TILE_GRID_LINE_MATERIAL_KEY: String = "editor_tile_grid_overlay"
const TILE_GRID_LINE_SHADOW_MATERIAL_KEY: String = "editor_tile_grid_shadow_overlay"
const TILE_SELECTION_FILL_MATERIAL_KEY: String = "editor_tile_selection_fill"
const TILE_SELECTION_BORDER_MATERIAL_KEY: String = "editor_tile_selection_border"
const TILE_SELECTION_SURFACE_Y_OFFSET: float = 0.12
const TILE_SELECTION_BORDER_WIDTH_FACTOR: float = 0.078
const TILE_SELECTION_FILL_COLOR: Color = Color(0.05, 0.58, 1.0, 0.46)
const TILE_SELECTION_BORDER_COLOR: Color = Color(0.78, 0.98, 1.0, 1.0)
const DROPSHIP_LZ_MARKER_FILL: float = 1.18
const DROPSHIP_APPROACH_LINE_WIDTH_FACTOR: float = 0.34
const DROPSHIP_APPROACH_VECTOR_COLOR: Color = Color(0.42, 1.0, 0.52, 0.62)
const FRIENDLY_AIM_LINE_COLOR: Color = Color(0.66, 1.0, 0.72, 0.82)
const FRIENDLY_AIM_TIP_COLOR: Color = Color(0.78, 1.0, 0.84, 0.92)
const FRIENDLY_AIM_LINE_HEIGHT: float = 0.58
const FRIENDLY_FIRE_LINE_BARREL_OFFSET_WORLD: float = 28.0
const FIRETEAM_ORIENTATION_LINE_COLOR: Color = Color(0.9, 0.98, 1.0, 0.88)
const FIRETEAM_ORIENTATION_TIP_COLOR: Color = Color(1.0, 1.0, 1.0, 0.82)
const FIRETEAM_ORIENTATION_LINE_LENGTH_WORLD: float = 58.0
const FRIENDLY_FIRE_SECTOR_TILE_COLOR: Color = Color(0.52, 1.0, 0.58, 0.12)
const FRIENDLY_FIRE_SECTOR_BLOCKER_COLOR: Color = Color(1.0, 0.84, 0.34, 0.32)
const FRIENDLY_FIRE_SECTOR_BLOCKER_LINE_COLOR: Color = Color(0.95, 1.0, 0.62, 0.48)
const FRIENDLY_FIRE_SECTOR_ANGLE_DEGREES: float = 70.0
const FRIENDLY_FIRE_SECTOR_SEGMENTS: int = 10
const FRIENDLY_FIRE_SECTOR_TILE_FILL: float = 0.82
const FRIENDLY_FIRE_SECTOR_BLOCKER_TILE_FILL: float = 0.58
const FRIENDLY_FIRE_SECTOR_SURFACE_OFFSET: float = 0.18
const FRIENDLY_FIRE_SECTOR_BLOCKER_LINE_LIMIT: int = 4
const FRIENDLY_FIRE_FACING_STEM_MIN_WORLD: float = 30.0
const FRIENDLY_FIRE_FACING_STEM_MAX_WORLD: float = 88.0
const FRIENDLY_AIM_DIRECTION_DEADZONE_RADIANS: float = 0.14
const FRIENDLY_FIRE_SECTOR_VISUAL_MODE_LOS_LINE: String = "los_line_only"
const FRIENDLY_FIRE_SECTOR_VISUAL_MODE_TILE_ALIGNED_LOS: String = "tile_aligned_los"
const FRIENDLY_FIRE_SECTOR_SCAN_MODE_LOS_LINE: String = "single_facing_los_line"
const FRIENDLY_FIRE_SECTOR_SCAN_MODE_TILE_CACHE: String = "range_bounded_los_cache"
const SELECTED_UNIT_MARKER_COLOR: Color = Color(0.45, 0.78, 1.0, 0.34)
const SELECTED_UNIT_MARKER_RADIUS: float = 0.32
const SELECTED_UNIT_MARKER_HEIGHT: float = 0.035
const SELECTED_UNIT_MARKER_SURFACE_OFFSET: float = 0.014
const DYNAMIC_ORDER_VISUAL_REFRESH_INTERVAL_MSEC: int = 90
const MISSION_LOS_DEBUG_SAMPLE_LIMIT: int = 24
const MISSION_LOS_DEBUG_CLEAR_LINE_COLOR: Color = Color(0.38, 1.0, 0.68, 0.76)
const MISSION_LOS_DEBUG_BLOCKED_LINE_COLOR: Color = Color(1.0, 0.32, 0.22, 0.82)
const MISSION_LOS_DEBUG_BLOCKER_MARKER_COLOR: Color = Color(1.0, 0.72, 0.24, 0.46)
const MISSION_LOS_DEBUG_CONTACT_MARKER_COLOR: Color = Color(0.72, 0.9, 1.0, 0.42)

const LEGACY_MODEL_BY_TYPE: Dictionary = {
	"wall_straight_se": "corridor_wall",
	"wall_straight_sw": "corridor_wall",
	"wall_straight_ne": "corridor_wall",
	"wall_straight_nw": "corridor_wall",
	"wall_corner_se": "corridor_wallCorner",
	"wall_corner_sw": "corridor_wallCorner",
	"wall_corner_ne": "corridor_wallCorner",
	"wall_corner_nw": "corridor_wallCorner",
	"cliff_straight_se": "terrain_sideCliff",
	"cliff_straight_sw": "terrain_sideCliff",
	"cliff_straight_ne": "terrain_sideCliff",
	"cliff_straight_nw": "terrain_sideCliff",
	"cliff_corner_se": "terrain_sideCorner",
	"cliff_corner_sw": "terrain_sideCorner",
	"cliff_corner_ne": "terrain_sideCorner",
	"cliff_corner_nw": "terrain_sideCorner",
	"slope_se": "terrain_rampLarge",
	"slope_sw": "terrain_rampLarge",
	"slope_ne": "terrain_rampLarge",
	"slope_nw": "terrain_rampLarge",
	"rock_small": "rock",
	"rock_large": "rock_largeB",
}

var _viewport_container: SubViewportContainer = null
var _subviewport: SubViewport = null
var _feedback_bubble_hud_root: Control = null
var _world_root: Node3D = null
var _map_root: Node3D = null
var _marker_root: Node3D = null
var _fow_root: Node3D = null
var _patrol_root: Node3D = null
var _selection_root: Node3D = null
var _unit_root: Node3D = null
var _order_root: Node3D = null
var _contact_root: Node3D = null
var _contact_density_root: Node3D = null
var _drop_root: Node3D = null
var _status_root: Node3D = null
var _camera: Camera3D = null
var _environment: WorldEnvironment = null

var _terrain_map_data = null
var _tile_catalog = null
var _terrain_3d_mapping: Dictionary = {}
var _terrain_surface_visual_theme_catalog: Dictionary = {}
var _npc_unit_visual_mapping: Dictionary = {}
var _weapon_fire_vfx_catalog: Dictionary = {}
var _editor_light_shadows_enabled: bool = EDITOR_LIGHT_SHADOW_ENABLED_DEFAULT
var _weapon_fire_vfx_texture_cache: Dictionary = {}
var _comic_bubble_texture_cache: Dictionary = {}
var _model_scene_cache: Dictionary = {}
var _box_mesh_cache: Dictionary = {}
var _material_cache: Dictionary = {}
var _space_kit_terrain_top_color: Color = Color.TRANSPARENT
var _render_tile_by_grid: Dictionary = {}
var _unit_nodes: Array = []
var _unit_proxies_by_id: Dictionary = {}
var _selected_grid_positions: Array = []
var _order_payload: Dictionary = {}
var _area_order_preview_payload: Dictionary = {}
var _contact_entries: Array = []
var _contact_selected_fireteam_ids: PackedStringArray = PackedStringArray()
var _drop_payload: Dictionary = {}
var _mission_status_payload: Dictionary = {}
var _fog_of_war_state: Dictionary = {}
var _fog_of_war_mode: String = FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF
var _fog_of_war_team_id: String = ""
var _fog_of_war_state_signature: String = ""
var _fow_visible_tile_ids: Dictionary = {}
var _fow_explored_tile_ids: Dictionary = {}
var _fow_visible_tile_grids: Dictionary = {}
var _fow_explored_tile_grids: Dictionary = {}
var _fow_visible_target_ids: Dictionary = {}
var _fow_visible_event_ids: Dictionary = {}
var _fow_last_known_contacts: Array = []

var _grid_size: Vector2i = Vector2i.ZERO
var _grid_origin_world: Vector2 = Vector2.ZERO
var _half_tile_width: float = DEFAULT_HALF_TILE_WIDTH
var _half_tile_height: float = DEFAULT_HALF_TILE_HEIGHT
var _focus_grid_position: Vector2 = Vector2.ZERO
var _camera_size: float = CAMERA_DEFAULT_SIZE
var _camera_yaw_degrees: float = 45.0
var _camera_pitch_degrees: float = 58.0
var _map_tile_count: int = 0
var _ground_mesh_count: int = 0
var _tile_texture_count: int = 0
var _height_edge_texture_count: int = 0
var _height_edge_model_count: int = 0
var _slope_edge_model_count: int = 0
var _cliff_edge_model_count: int = 0
var _nature_cliff_edge_model_count: int = 0
var _nature_slope_step_model_count: int = 0
var _nature_cliff_theme_counts: Dictionary = {}
var _height_edge_visual_entries: Array = []
var _height_edge_authoring_conflict_count: int = 0
var _surface_tint_count: int = 0
var _elevated_surface_tint_count: int = 0
var _nature_surface_ground_model_count: int = 0
var _nature_surface_detail_model_count: int = 0
var _nature_surface_theme_counts: Dictionary = {}
var _surface_visual_entries: Array = []
var _surface_detail_visual_entries: Array = []
var _asset_texture_count: int = 0
var _asset_model_count: int = 0
var _space_station_model_count: int = 0
var _space_station_textured_surface_count: int = 0
var _nature_prop_model_count: int = 0
var _nature_prop_role_counts: Dictionary = {}
var _nature_prop_visual_entries: Array = []
var _placeholder_object_count: int = 0
var _missing_asset_mapping_count: int = 0
var _missing_unit_model_count: int = 0
var _missing_dropship_model_count: int = 0
var _unit_texture_count: int = 0
var _unit_model_count: int = 0
var _animated_unit_model_count: int = 0
var _unit_visual_error_count: int = 0
var _unit_animation_player_count: int = 0
var _unit_animation_error_count: int = 0
var _unit_helmet_attachment_count: int = 0
var _unit_helmet_error_count: int = 0
var _unit_skeleton_count: int = 0
var _unit_socket_count: int = 0
var _unit_socket_fallback_count: int = 0
var _unit_head_socket_count: int = 0
var _unit_right_hand_socket_count: int = 0
var _unit_animation_retarget_fallback_count: int = 0
var _unit_blaster_attachment_count: int = 0
var _unit_blaster_error_count: int = 0
var _unit_visual_loadout_count: int = 0
var _unit_visual_loadout_error_count: int = 0
var _enemy_animated_unit_model_count: int = 0
var _unit_status_badge_count: int = 0
var _drop_visual_static_signature: String = ""
var _dropship_visual_nodes_by_id: Dictionary = {}
var _dropship_approach_lines_by_id: Dictionary = {}
var _dropship_approach_arrow_count: int = 0
var _dropship_lz_label_count: int = 0
var _dropship_texture_visible: bool = false
var _dropship_model_visible: bool = false
var _air_visual_count: int = 0
var _fow_hidden_air_visual_count: int = 0
var _air_unknown_terrain_reveal_block_count: int = 0
var _dropship_air_y: float = 0.0
var _dropship_surface_y: float = 0.0
var _dropship_air_clearance: float = 0.0
var _dropship_rotation_y: float = 0.0
var _map_render_duration_msec: int = 0
var _marker_count: int = 0
var _compass_marker_count: int = 0
var _patrol_segment_count: int = 0
var _patrol_preview_segment_count: int = 0
var _editor_patrol_preview_path_id: String = ""
var _area_order_count: int = 0
var _waypoint_visual_count: int = 0
var _area_order_tile_marker_count: int = 0
var _waypoint_tile_marker_count: int = 0
var _movement_style_visual_count: int = 0
var _movement_bound_marker_count: int = 0
var _movement_group_marker_count: int = 0
var _movement_group_marker_entries: Array = []
var _movement_style_entries: Array = []
var _fireteam_orientation_visual_count: int = 0
var _fireteam_orientation_entries: Array = []
var _multi_fireteam_plan_visual_count: int = 0
var _multi_fireteam_plan_entries: Array = []
var _enemy_security_visual_count: int = 0
var _enemy_security_entries: Array = []
var _enemy_tactics_visual_count: int = 0
var _enemy_tactics_entries: Array = []
var _friendly_aim_visual_count: int = 0
var _friendly_aim_entries: Array = []
var _friendly_aim_direction_by_unit_id: Dictionary = {}
var _friendly_aim_tile_marker_count: int = 0
var _friendly_aim_blocker_marker_count: int = 0
var _friendly_aim_los_line_count: int = 0
var _mission_los_debug_line_count: int = 0
var _mission_los_debug_clear_line_count: int = 0
var _mission_los_debug_blocked_line_count: int = 0
var _mission_los_debug_blocker_marker_count: int = 0
var _mission_los_debug_sampled_pair_count: int = 0
var _mission_los_debug_bounded_skipped_count: int = 0
var _mission_los_debug_fow_hidden_contact_count: int = 0
var _mission_los_debug_source_unit_count: int = 0
var _mission_los_debug_contact_candidate_count: int = 0
var _mission_los_debug_entries: Array = []
var _selected_unit_marker_count: int = 0
var _selected_unit_marker_entries: Array = []
var _weapon_fire_vfx_visual_count: int = 0
var _weapon_fire_vfx_entries: Array = []
var _weapon_fire_sfx_count: int = 0
var _weapon_fire_sfx_suppressed_count: int = 0
var _feedback_bubble_visual_count: int = 0
var _feedback_bubble_entries: Array = []
var _tactical_communication_event_visual_count: int = 0
var _tactical_communication_event_entries: Array = []
var _movement_step_ready_at_msec: Dictionary = {}
var _movement_step_sfx_count: int = 0
var _movement_step_sfx_suppressed_rate_limit_count: int = 0
var _movement_step_sfx_entries: Array = []
var _audio_event_bus = null
var _fow_overlay_tile_count: int = 0
var _fow_visible_tile_count: int = 0
var _fow_known_dim_tile_count: int = 0
var _fow_explored_tile_count: int = 0
var _fow_unknown_tile_count: int = 0
var _fow_tile_total_count: int = 0
var _fow_overlay_rebuild_count: int = 0
var _fow_hidden_order_visual_count: int = 0
var _fow_hidden_contact_count: int = 0
var _fow_hidden_unit_proxy_count: int = 0
var _fow_allowed_contact_count: int = 0
var _lz_tile_marker_count: int = 0
var _requested_lz_marker_count: int = 0
var _resolved_lz_marker_count: int = 0
var _tile_grid_line_count: int = 0
var _contact_count: int = 0
var _contact_visual_entries: Array = []
var _contact_density_overlay_enabled: bool = false
var _contact_density_overlay = CONTACT_DENSITY_OVERLAY_SCRIPT.new()
var _contact_density_entries: Array = []
var _contact_density_source_count: int = 0
var _contact_density_current_source_count: int = 0
var _contact_density_last_known_source_count: int = 0
var _contact_density_fow_hidden_count: int = 0
var _contact_density_rebuild_count: int = 0
var _contact_density_skipped_interval_count: int = 0
var _contact_density_last_rebuild_msec: int = 0
var _contact_density_last_signature: String = ""
var _objective_status_visible: bool = false
var _mission_result_visible: bool = false
var _continuous_redraw_until_msec: int = 0
var _render_snapshot_request_count: int = 0
var _order_payload_apply_count: int = 0
var _contact_payload_apply_count: int = 0
var _drop_payload_apply_count: int = 0
var _mission_status_payload_apply_count: int = 0
var _order_visual_signature: String = ""
var _order_dynamic_visual_signature: String = ""
var _last_dynamic_order_visual_refresh_msec: int = 0
var _fire_sector_los_cache: Dictionary = {}
var _fire_sector_los_cache_signature: String = ""


func _ready() -> void:
	layer = -100
	_ensure_nodes()
	_resize_subviewport()
	_update_camera_transform()
	_request_viewport_redraw()
	set_process(true)


func _process(delta: float) -> void:
	_resize_subviewport()
	_sync_unit_proxies(false, delta)
	_refresh_dynamic_order_visuals_if_needed()
	if _subviewport != null and _subviewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS and Time.get_ticks_msec() > _continuous_redraw_until_msec:
		_subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func configure_from_map(terrain_map_data) -> void:
	_terrain_map_data = terrain_map_data
	_order_visual_signature = ""
	_order_dynamic_visual_signature = ""
	_fire_sector_los_cache.clear()
	_fire_sector_los_cache_signature = ""
	_read_map_transform()
	render_map()


func render_map(terrain_map_data = null) -> void:
	var render_started_at_msec: int = Time.get_ticks_msec()
	if terrain_map_data != null:
		_terrain_map_data = terrain_map_data
		_order_visual_signature = ""
		_order_dynamic_visual_signature = ""
		_fire_sector_los_cache.clear()
		_fire_sector_los_cache_signature = ""
	_read_map_transform()
	_ensure_nodes()
	_clear_children(_map_root)
	_clear_children(_marker_root)
	_clear_children(_fow_root)
	_clear_children(_patrol_root)
	_clear_children(_selection_root)
	_clear_children(_order_root)
	_clear_children(_contact_root)
	_clear_children(_contact_density_root)
	_clear_children(_drop_root)
	_clear_children(_feedback_bubble_hud_root)
	_render_tile_by_grid.clear()
	_map_tile_count = 0
	_ground_mesh_count = 0
	_tile_texture_count = 0
	_height_edge_texture_count = 0
	_height_edge_model_count = 0
	_slope_edge_model_count = 0
	_cliff_edge_model_count = 0
	_nature_cliff_edge_model_count = 0
	_nature_slope_step_model_count = 0
	_nature_cliff_theme_counts.clear()
	_height_edge_visual_entries.clear()
	_height_edge_authoring_conflict_count = 0
	_surface_tint_count = 0
	_elevated_surface_tint_count = 0
	_nature_surface_ground_model_count = 0
	_nature_surface_detail_model_count = 0
	_nature_surface_theme_counts.clear()
	_surface_visual_entries.clear()
	_surface_detail_visual_entries.clear()
	_asset_texture_count = 0
	_asset_model_count = 0
	_space_station_model_count = 0
	_space_station_textured_surface_count = 0
	_nature_prop_model_count = 0
	_nature_prop_role_counts.clear()
	_nature_prop_visual_entries.clear()
	_placeholder_object_count = 0
	_missing_asset_mapping_count = 0
	_missing_unit_model_count = 0
	_missing_dropship_model_count = 0
	_tile_grid_line_count = 0
	_marker_count = 0
	_compass_marker_count = 0
	_patrol_segment_count = 0
	_patrol_preview_segment_count = 0
	_movement_style_visual_count = 0
	_movement_bound_marker_count = 0
	_movement_group_marker_count = 0
	_movement_style_entries.clear()
	_enemy_security_visual_count = 0
	_enemy_security_entries.clear()
	_enemy_tactics_visual_count = 0
	_enemy_tactics_entries.clear()
	_friendly_aim_visual_count = 0
	_friendly_aim_entries.clear()
	_friendly_aim_tile_marker_count = 0
	_friendly_aim_blocker_marker_count = 0
	_friendly_aim_los_line_count = 0
	_reset_mission_los_debug_counters()
	_selected_unit_marker_count = 0
	_selected_unit_marker_entries.clear()
	_weapon_fire_vfx_visual_count = 0
	_weapon_fire_vfx_entries.clear()
	_feedback_bubble_visual_count = 0
	_feedback_bubble_entries.clear()
	_clear_children(_feedback_bubble_hud_root)
	_tactical_communication_event_visual_count = 0
	_tactical_communication_event_entries.clear()
	_reset_fow_overlay_counters(false)
	if _terrain_map_data == null:
		_map_render_duration_msec = Time.get_ticks_msec() - render_started_at_msec
		return

	var tiles: Array = Array(_terrain_map_data.call("get_tiles"))
	for tile_data in tiles:
		if tile_data != null:
			_render_tile_by_grid[tile_data.grid_position] = tile_data
	for tile_data in tiles:
		_add_tile_visual(tile_data)
	_add_tile_grid_lines(tiles)
	for tile_data in tiles:
		_add_height_edge_visuals(tile_data)
	_rebuild_fog_of_war_visuals()
	_rebuild_marker_visuals()
	_rebuild_patrol_visuals()
	_rebuild_selection_visuals()
	_rebuild_order_visuals()
	_rebuild_contact_visuals()
	_rebuild_drop_visuals()
	_sync_unit_proxies()
	_update_camera_transform()
	_map_render_duration_msec = Time.get_ticks_msec() - render_started_at_msec


func set_unit_nodes(unit_nodes: Array) -> void:
	_unit_nodes.clear()
	for unit in unit_nodes:
		if unit is Node:
			_unit_nodes.append(unit)
	_sync_unit_proxies(true)


func set_selected_grid_positions(grid_positions: Array) -> void:
	_selected_grid_positions.clear()
	var seen: Dictionary = {}
	for grid_variant in grid_positions:
		var grid_position: Vector2i
		if grid_variant is Vector2i:
			grid_position = Vector2i(grid_variant)
		elif grid_variant is Vector2:
			grid_position = Vector2i(roundi(grid_variant.x), roundi(grid_variant.y))
		else:
			continue
		var grid_key: String = "%d,%d" % [grid_position.x, grid_position.y]
		if seen.has(grid_key):
			continue
		if _terrain_map_data != null and _terrain_map_data.has_method("get_tile_at_grid") and _terrain_map_data.call("get_tile_at_grid", grid_position) == null:
			continue
		seen[grid_key] = true
		_selected_grid_positions.append(grid_position)
	_rebuild_selection_visuals()
	_request_viewport_redraw()


func get_selected_grid_positions() -> Array:
	return _selected_grid_positions.duplicate()


func set_order_visual_payload(order_payload: Dictionary) -> void:
	_order_payload_apply_count += 1
	var next_signature: String = _build_order_visual_signature(order_payload)
	if next_signature == _order_visual_signature:
		_order_payload = order_payload.duplicate(true)
		return
	_order_visual_signature = next_signature
	_order_payload = order_payload.duplicate(true)
	if _order_payload.has("contact_density_heatmap_enabled"):
		var contact_density_enabled: bool = bool(_order_payload.get("contact_density_heatmap_enabled", false))
		if contact_density_enabled != _contact_density_overlay_enabled:
			_set_contact_density_heatmap_enabled_internal(contact_density_enabled, true)
	_order_dynamic_visual_signature = _build_order_dynamic_visual_signature()
	_rebuild_order_visuals()
	_request_viewport_redraw()


func set_area_order_preview_payload(preview_payload: Dictionary) -> void:
	_area_order_preview_payload = preview_payload.duplicate(true)
	_rebuild_order_visuals()
	_request_viewport_redraw()


func _build_order_visual_signature(order_payload: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(var_to_str(order_payload))
	if bool(order_payload.get("fire_sector_overlay_enabled", false)):
		var selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(order_payload.get("selected_fireteam_ids", PackedStringArray()))
		var unit_parts: Array = []
		for unit in _unit_nodes:
			if unit == null or not (unit is Node2D):
				continue
			var fireteam_id: String = _get_unit_fireteam_id(unit)
			if fireteam_id.is_empty() or not selected_fireteam_ids.has(fireteam_id):
				continue
			if not _is_unit_world_visible(unit):
				continue
			var weapon_id: String = _get_unit_active_attack_weapon_id(unit)
			if weapon_id.is_empty():
				continue
			var unit_position: Vector2 = (unit as Node2D).global_position
			var aim_direction: Vector2 = _resolve_unit_aim_direction(unit, unit_position)
			var grid_position: Vector2i = _world_to_grid_position(unit_position)
			unit_parts.append("%s:%d,%d:%s:%.2f" % [
				_get_unit_id(unit),
				grid_position.x,
				grid_position.y,
				weapon_id,
				aim_direction.angle() if aim_direction.length_squared() > 0.0001 else 0.0,
			])
		unit_parts.sort()
		parts.append("fire:%s" % "|".join(unit_parts))
	if bool(order_payload.get("los_debug_overlay_enabled", false)):
		var los_selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(order_payload.get("selected_fireteam_ids", PackedStringArray()))
		var debug_unit_parts: Array = []
		for unit in _unit_nodes:
			if unit == null or not (unit is Node2D):
				continue
			var fireteam_id: String = _get_unit_fireteam_id(unit)
			if fireteam_id.is_empty() or not los_selected_fireteam_ids.has(fireteam_id):
				continue
			if not _is_unit_world_visible(unit):
				continue
			var unit_position: Vector2 = (unit as Node2D).global_position
			var grid_position: Vector2i = _world_to_grid_position(unit_position)
			debug_unit_parts.append("%s:%d,%d" % [_get_unit_id(unit), grid_position.x, grid_position.y])
		debug_unit_parts.sort()
		parts.append("los_debug:%s:%d" % ["|".join(debug_unit_parts), _contact_payload_apply_count])
	return "\n".join(parts)


func _refresh_dynamic_order_visuals_if_needed() -> void:
	if _order_payload.is_empty() or _order_root == null:
		return
	var selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(_order_payload.get("selected_fireteam_ids", PackedStringArray()))
	if selected_fireteam_ids.is_empty() and not bool(_order_payload.get("fire_sector_overlay_enabled", false)) and not bool(_order_payload.get("los_debug_overlay_enabled", false)):
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_dynamic_order_visual_refresh_msec < DYNAMIC_ORDER_VISUAL_REFRESH_INTERVAL_MSEC:
		return
	_last_dynamic_order_visual_refresh_msec = now_msec
	var next_signature: String = _build_order_dynamic_visual_signature()
	if next_signature == _order_dynamic_visual_signature:
		return
	_order_dynamic_visual_signature = next_signature
	_rebuild_order_visuals()
	_request_viewport_redraw()


func _build_order_dynamic_visual_signature() -> String:
	var selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(_order_payload.get("selected_fireteam_ids", PackedStringArray()))
	if selected_fireteam_ids.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	parts.append("selected:%s" % ",".join(selected_fireteam_ids))
	parts.append("fire:%s:%s" % [str(bool(_order_payload.get("fire_sector_overlay_enabled", false))), _get_fire_sector_visual_mode()])
	parts.append("los_debug:%s:%d" % [str(bool(_order_payload.get("los_debug_overlay_enabled", false))), _contact_payload_apply_count])
	for unit in _unit_nodes:
		if unit == null or not (unit is Node2D):
			continue
		var fireteam_id: String = _get_unit_fireteam_id(unit)
		if fireteam_id.is_empty() or not selected_fireteam_ids.has(fireteam_id):
			continue
		if not _is_unit_world_visible(unit):
			continue
		var unit_id: String = _get_unit_id(unit)
		var unit_position: Vector2 = (unit as Node2D).global_position
		var proxy := _unit_proxies_by_id.get(unit_id, null) as Node3D
		var rotation_y: float = float(proxy.rotation_degrees.y) if proxy != null and is_instance_valid(proxy) else 0.0
		parts.append("%s:%s:%.1f,%.1f:%.1f" % [
			unit_id,
			fireteam_id,
			unit_position.x,
			unit_position.y,
			rotation_y,
		])
	parts.sort()
	return "|".join(parts)


func set_contact_entries(contact_entries: Array, selected_fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	_contact_payload_apply_count += 1
	_contact_entries.clear()
	for entry_variant in contact_entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			_contact_entries.append(Dictionary(entry_variant).duplicate(true))
	_contact_selected_fireteam_ids = selected_fireteam_ids.duplicate()
	_rebuild_contact_visuals()
	_rebuild_contact_density_heatmap(false)
	if bool(_order_payload.get("los_debug_overlay_enabled", false)):
		_order_dynamic_visual_signature = _build_order_dynamic_visual_signature()
		_rebuild_order_visuals()
	_request_viewport_redraw()


func set_contact_density_heatmap_enabled(enabled: bool) -> void:
	if _set_contact_density_heatmap_enabled_internal(enabled, true):
		_request_viewport_redraw()


func get_contact_density_heatmap_snapshot() -> Dictionary:
	return {
		"enabled": _contact_density_overlay_enabled,
		"heat_cell_count": _contact_density_entries.size(),
		"heat_cells": _contact_density_entries.duplicate(true),
		"source_contact_count": _contact_density_source_count,
		"current_source_count": _contact_density_current_source_count,
		"last_known_source_count": _contact_density_last_known_source_count,
		"fow_hidden_count": _contact_density_fow_hidden_count,
		"rebuild_count": _contact_density_rebuild_count,
		"skipped_interval_count": _contact_density_skipped_interval_count,
		"last_rebuild_msec": _contact_density_last_rebuild_msec,
		"update_interval_msec": CONTACT_DENSITY_UPDATE_INTERVAL_MSEC,
		"cell_size_world": CONTACT_DENSITY_CELL_SIZE_WORLD,
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"fow_policy": "current_or_last_known_contacts_after_visual_fow_filter",
	}


func _set_contact_density_heatmap_enabled_internal(enabled: bool, force_rebuild: bool = false) -> bool:
	if _contact_density_overlay_enabled == enabled and not force_rebuild:
		return false
	_contact_density_overlay_enabled = enabled
	_rebuild_contact_density_heatmap(true)
	return true


func set_fog_of_war_state(fog_of_war_state: Dictionary) -> void:
	var normalized_state: Dictionary = _normalize_fog_of_war_visual_state(fog_of_war_state)
	var next_signature: String = _build_fog_of_war_visual_signature(normalized_state)
	if next_signature == _fog_of_war_state_signature:
		return
	_fog_of_war_state_signature = next_signature
	_apply_fog_of_war_visual_state(normalized_state)
	_rebuild_fog_of_war_visuals()
	_rebuild_order_visuals()
	_rebuild_contact_visuals()
	_rebuild_contact_density_heatmap(true)
	_rebuild_drop_visuals()
	_sync_unit_proxies(true)
	_request_viewport_redraw()


func set_fog_of_war_visual_state(fog_of_war_state: Dictionary) -> void:
	set_fog_of_war_state(fog_of_war_state)


func set_mission_drop_visual_state(drop_payload: Dictionary) -> void:
	_drop_payload_apply_count += 1
	var normalized_payload: Dictionary = _normalize_mission_drop_visual_payload(drop_payload)
	var next_static_signature: String = _build_drop_visual_static_signature(normalized_payload)
	var can_update_motion: bool = next_static_signature == _drop_visual_static_signature and _can_update_drop_visual_motion(normalized_payload)
	_drop_payload = normalized_payload
	if can_update_motion:
		_update_drop_visual_motion()
	else:
		_drop_visual_static_signature = next_static_signature
		_rebuild_drop_visuals()
	_request_viewport_redraw()


func set_mission_status_payload(status_payload: Dictionary) -> void:
	_mission_status_payload_apply_count += 1
	_mission_status_payload = status_payload.duplicate(true)
	_rebuild_status_visuals()
	_request_viewport_redraw()


func focus_world_position(world_position: Vector2) -> void:
	_focus_grid_position = _world_to_grid_float(world_position)
	_update_camera_transform()


func focus_map_center() -> void:
	if _grid_size == Vector2i.ZERO:
		_focus_grid_position = Vector2.ZERO
	else:
		_focus_grid_position = Vector2(maxf(float(_grid_size.x - 1), 0.0) * 0.5, maxf(float(_grid_size.y - 1), 0.0) * 0.5)
	_update_camera_transform()


func _get_map_center_world_position() -> Vector2:
	if _terrain_map_data != null and _terrain_map_data.has_method("grid_to_world") and _grid_size != Vector2i.ZERO:
		var center_grid := Vector2i(int(floor(float(maxi(_grid_size.x - 1, 0)) * 0.5)), int(floor(float(maxi(_grid_size.y - 1, 0)) * 0.5)))
		return Vector2(_terrain_map_data.call("grid_to_world", center_grid))
	return _grid_float_to_world(_focus_grid_position)


func pan_camera(input_direction: Vector2, delta_seconds: float = 1.0) -> void:
	if input_direction == Vector2.ZERO:
		return
	var yaw_rad: float = deg_to_rad(_camera_yaw_degrees)
	var right := Vector2(cos(yaw_rad), -sin(yaw_rad))
	var forward := Vector2(sin(yaw_rad), cos(yaw_rad))
	var grid_delta: Vector2 = (right * input_direction.x + forward * input_direction.y) * CAMERA_PAN_UNITS_PER_SECOND * delta_seconds
	_focus_grid_position += grid_delta
	_clamp_focus_to_map()
	_update_camera_transform()
	_request_viewport_redraw(true)


func pan_camera_pixels(pixel_delta: Vector2) -> void:
	if pixel_delta == Vector2.ZERO:
		return
	var viewport_height: float = maxf(float(_get_viewport_size().y), 1.0)
	var drag_scale: float = _camera_size / viewport_height
	pan_camera(pixel_delta * CAMERA_DRAG_PAN_FACTOR * drag_scale, 1.0)


func rotate_camera(delta_degrees: float) -> void:
	_camera_yaw_degrees = wrapf(_camera_yaw_degrees + delta_degrees, 0.0, 360.0)
	_update_camera_transform()
	_request_viewport_redraw(true)


func zoom_camera(delta_steps: float) -> void:
	_camera_size = clampf(_camera_size - (delta_steps * CAMERA_ZOOM_STEP), CAMERA_MIN_SIZE, CAMERA_MAX_SIZE)
	_update_camera_transform()
	_request_viewport_redraw(true)


func get_camera_yaw_degrees() -> float:
	return _camera_yaw_degrees


func get_camera_size() -> float:
	return _camera_size


func screen_to_world_position(screen_position: Vector2):
	_ensure_nodes()
	if _camera == null or _subviewport == null:
		return null
	var viewport_position: Vector2 = _screen_to_viewport_position(screen_position)
	var picked_tile = _pick_tile_at_screen_position(viewport_position)
	if picked_tile != null and typeof(picked_tile.world_position) == TYPE_VECTOR2:
		return Vector2(picked_tile.world_position)
	var ray_origin: Vector3 = _camera.project_ray_origin(viewport_position)
	var ray_dir: Vector3 = _camera.project_ray_normal(viewport_position)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_dir)
	if typeof(hit) != TYPE_VECTOR3:
		return null
	return _position_3d_to_world(Vector3(hit))


func screen_to_grid_position(screen_position: Vector2):
	_ensure_nodes()
	if _camera == null or _terrain_map_data == null:
		return null
	var viewport_position: Vector2 = _screen_to_viewport_position(screen_position)
	var picked_tile = _pick_tile_at_screen_position(viewport_position)
	if picked_tile == null:
		return null
	if typeof(picked_tile.grid_position) == TYPE_VECTOR2I:
		return Vector2i(picked_tile.grid_position)
	if typeof(picked_tile.world_position) == TYPE_VECTOR2:
		return _world_to_grid_position(Vector2(picked_tile.world_position))
	return null


func world_to_screen_position(world_position: Vector2) -> Vector2:
	_ensure_nodes()
	if _camera == null:
		return Vector2.ZERO
	return _camera.unproject_position(_world_to_surface_3d_position(world_position, 0.0))


func world_to_grid_position(world_position: Vector2):
	var grid_position: Vector2i = _world_to_grid_position(world_position)
	if _terrain_map_data != null and _terrain_map_data.has_method("get_tile_at_grid"):
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			return null
	return grid_position


func grid_to_world_position(grid_position: Vector2i):
	if _terrain_map_data != null and _terrain_map_data.has_method("get_tile_at_grid"):
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data != null and typeof(tile_data.world_position) == TYPE_VECTOR2:
			return Vector2(tile_data.world_position)
	return _grid_float_to_world(Vector2(grid_position))


func snap_world_position_to_tile_center(world_position: Vector2) -> Vector2:
	var grid_position: Vector2i = _world_to_grid_position(world_position)
	if _terrain_map_data != null:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data != null and typeof(tile_data.world_position) == TYPE_VECTOR2:
			return Vector2(tile_data.world_position)
	return _grid_float_to_world(Vector2(grid_position))


func screen_rect_to_tile_world_positions(screen_rect: Rect2) -> Array:
	var result: Array = []
	if _terrain_map_data == null or _camera == null:
		return result
	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		if tile_data == null or typeof(tile_data.world_position) != TYPE_VECTOR2:
			continue
		var screen_position: Vector2 = world_to_screen_position(Vector2(tile_data.world_position))
		if screen_rect.has_point(screen_position):
			result.append(Vector2(tile_data.world_position))
	return result


func _pick_tile_at_screen_position(viewport_position: Vector2):
	if _terrain_map_data == null or _camera == null:
		return null
	var best_tile = null
	var best_score: float = INF
	var camera_origin: Vector3 = _camera.global_position
	var camera_forward: Vector3 = -_camera.global_transform.basis.z.normalized()
	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var screen_quad: Array[Vector2] = _get_tile_top_screen_quad(tile_data)
		if screen_quad.size() != 4 or not _screen_point_is_inside_convex_quad(viewport_position, screen_quad):
			continue
		var surface_y: float = (float(tile_data.height_level) * _get_3d_height_step()) + TILE_SELECTION_SURFACE_Y_OFFSET
		var tile_center_3d: Vector3 = _grid_to_3d_position(Vector2(tile_data.grid_position), surface_y)
		var camera_depth: float = (tile_center_3d - camera_origin).dot(camera_forward)
		var center_screen: Vector2 = _camera.unproject_position(tile_center_3d)
		var score: float = camera_depth + (viewport_position.distance_squared_to(center_screen) * 0.0001)
		if score < best_score:
			best_score = score
			best_tile = tile_data
	return best_tile


func _get_tile_top_screen_quad(tile_data) -> Array[Vector2]:
	var result: Array[Vector2] = []
	if tile_data == null or _camera == null:
		return result
	var cell_size: float = _get_3d_cell_size()
	var half_size: float = cell_size * 0.5
	var top_y: float = (float(tile_data.height_level) * _get_3d_height_step()) + TILE_GRID_LINE_SURFACE_Y_OFFSET
	var center: Vector3 = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y)
	for corner in [
		center + Vector3(-half_size, 0.0, -half_size),
		center + Vector3(half_size, 0.0, -half_size),
		center + Vector3(half_size, 0.0, half_size),
		center + Vector3(-half_size, 0.0, half_size),
	]:
		result.append(_camera.unproject_position(corner))
	return result


func _screen_point_is_inside_convex_quad(point: Vector2, quad: Array[Vector2]) -> bool:
	if quad.size() != 4:
		return false
	var saw_positive: bool = false
	var saw_negative: bool = false
	for index in range(quad.size()):
		var a: Vector2 = quad[index]
		var b: Vector2 = quad[(index + 1) % quad.size()]
		var edge: Vector2 = b - a
		var to_point: Vector2 = point - a
		var cross: float = edge.cross(to_point)
		if cross > 0.001:
			saw_positive = true
		elif cross < -0.001:
			saw_negative = true
		if saw_positive and saw_negative:
			return false
	return true


func get_audio_sfx_debug_snapshot() -> Dictionary:
	var bus = _ensure_audio_event_bus(false)
	if bus != null and bus.has_method("get_diagnostic_snapshot"):
		return Dictionary(bus.call("get_diagnostic_snapshot")).duplicate(true)
	return {}


func emit_movement_step_sfx_for_tests(unit_id: String, surface_type: String, is_unit_visible: bool, moving: bool, now_msec: int) -> Dictionary:
	return _maybe_emit_unit_step_sfx(unit_id, Vector2.ZERO, moving, is_unit_visible, surface_type, now_msec)


func set_editor_shadow_readability_enabled(enabled: bool) -> void:
	_editor_light_shadows_enabled = enabled
	_apply_editor_light_settings()
	_request_viewport_redraw()


func set_editor_patrol_preview_path_id(path_id: String) -> void:
	var normalized_path_id: String = path_id.strip_edges()
	if normalized_path_id == _editor_patrol_preview_path_id:
		return
	_editor_patrol_preview_path_id = normalized_path_id
	if _patrol_root != null and _terrain_map_data != null:
		_rebuild_patrol_visuals()
	_request_viewport_redraw()


func get_render_snapshot() -> Dictionary:
	_render_snapshot_request_count += 1
	var render_budget_by_category: Dictionary = _build_render_budget_by_category()
	var render_budget_totals: Dictionary = _build_render_budget_totals(render_budget_by_category)
	var render_monitor_snapshot: Dictionary = _build_render_monitor_snapshot()
	return {
		"tile_count": _map_tile_count,
		"editor_visual_recovery": _build_editor_visual_recovery_snapshot(),
		"editor_light": _build_editor_light_snapshot(),
		"ground_mesh_count": _ground_mesh_count,
		"tile_texture_count": _tile_texture_count,
		"height_edge_texture_count": _height_edge_texture_count,
		"height_edge_model_count": _height_edge_model_count,
		"slope_edge_model_count": _slope_edge_model_count,
		"cliff_edge_model_count": _cliff_edge_model_count,
		"nature_cliff_edge_model_count": _nature_cliff_edge_model_count,
		"nature_slope_step_model_count": _nature_slope_step_model_count,
		"nature_cliff_theme_counts": _nature_cliff_theme_counts.duplicate(true),
		"height_edge_visual_entries": _height_edge_visual_entries.duplicate(true),
		"height_edge_authoring_conflict_count": _height_edge_authoring_conflict_count,
		"surface_tint_count": _surface_tint_count,
		"elevated_surface_tint_count": _elevated_surface_tint_count,
		"nature_surface_ground_model_count": _nature_surface_ground_model_count,
		"nature_surface_detail_model_count": _nature_surface_detail_model_count,
		"nature_surface_theme_counts": _nature_surface_theme_counts.duplicate(true),
		"surface_visual_entries": _surface_visual_entries.duplicate(true),
		"surface_detail_visual_entries": _surface_detail_visual_entries.duplicate(true),
		"surface_detail_visual_count": _surface_detail_visual_entries.size(),
		"surface_visual_theme_catalog_loaded": not _get_terrain_surface_visual_theme_catalog().is_empty(),
		"asset_texture_count": _asset_texture_count,
		"asset_model_count": _asset_model_count,
		"space_station_model_count": _space_station_model_count,
		"space_station_textured_surface_count": _space_station_textured_surface_count,
		"nature_prop_model_count": _nature_prop_model_count,
		"nature_prop_role_counts": _nature_prop_role_counts.duplicate(true),
		"nature_prop_visual_entries": _nature_prop_visual_entries.duplicate(true),
		"placeholder_object_count": _placeholder_object_count,
		"missing_asset_mapping_count": _missing_asset_mapping_count + _missing_unit_model_count + _missing_dropship_model_count,
		"missing_map_asset_mapping_count": _missing_asset_mapping_count,
		"missing_unit_model_count": _missing_unit_model_count,
		"missing_dropship_model_count": _missing_dropship_model_count,
		"unit_texture_count": _unit_texture_count,
		"unit_model_count": _unit_model_count,
		"animated_unit_model_count": _animated_unit_model_count,
		"unit_visual_error_count": _unit_visual_error_count,
		"unit_animation_player_count": _unit_animation_player_count,
		"unit_animation_error_count": _unit_animation_error_count,
		"unit_helmet_attachment_count": _unit_helmet_attachment_count,
		"unit_helmet_error_count": _unit_helmet_error_count,
		"unit_skeleton_count": _unit_skeleton_count,
		"unit_socket_count": _unit_socket_count,
		"unit_socket_fallback_count": _unit_socket_fallback_count,
		"unit_head_socket_count": _unit_head_socket_count,
		"unit_right_hand_socket_count": _unit_right_hand_socket_count,
		"unit_animation_retarget_fallback_count": _unit_animation_retarget_fallback_count,
		"unit_blaster_attachment_count": _unit_blaster_attachment_count,
		"unit_blaster_error_count": _unit_blaster_error_count,
		"unit_visual_loadout_count": _unit_visual_loadout_count,
		"unit_visual_loadout_error_count": _unit_visual_loadout_error_count,
		"enemy_animated_unit_model_count": _enemy_animated_unit_model_count,
		"unit_visual_mapping_loaded": not _get_npc_unit_visual_mapping().is_empty(),
		"unit_status_badge_count": _unit_status_badge_count,
		"marker_count": _marker_count,
		"compass_marker_count": _compass_marker_count,
		"patrol_segment_count": _patrol_segment_count,
		"editor_patrol_preview_path_id": _editor_patrol_preview_path_id,
		"editor_patrol_preview_segment_count": _patrol_preview_segment_count,
		"selected_grid_count": _selected_grid_positions.size(),
		"selected_grid_positions": _selected_grid_positions.duplicate(),
		"unit_proxy_count": _unit_proxies_by_id.size(),
		"unit_proxy_ids": _get_unit_proxy_ids(false),
		"visible_unit_proxy_ids": _get_unit_proxy_ids(true),
		"missing_unit_model_ids": _get_unit_proxy_ids_with_meta("missing_unit_model"),
		"unit_visual_error_ids": _get_unit_proxy_ids_with_meta("unit_visual_error"),
		"unit_proxy_state_by_id": _get_unit_proxy_state_by_id(),
		"area_order_count": _area_order_count,
		"waypoint_visual_count": _waypoint_visual_count,
		"area_order_tile_marker_count": _area_order_tile_marker_count,
		"waypoint_tile_marker_count": _waypoint_tile_marker_count,
		"order_selected_fireteam_ids": Array(_get_string_array_from_variant(_order_payload.get("selected_fireteam_ids", PackedStringArray()))),
		"order_phase_index": int(_order_payload.get("phase_index", 0)),
		"movement_style_visual_count": _movement_style_visual_count,
		"movement_bound_marker_count": _movement_bound_marker_count,
		"movement_group_marker_count": _movement_group_marker_count,
		"movement_group_marker_entries": _movement_group_marker_entries.duplicate(true),
		"movement_style_entries": _movement_style_entries.duplicate(true),
		"fireteam_orientation_visual_count": _fireteam_orientation_visual_count,
		"fireteam_orientation_entries": _fireteam_orientation_entries.duplicate(true),
		"multi_fireteam_plan_visual_count": _multi_fireteam_plan_visual_count,
		"multi_fireteam_plan_entries": _multi_fireteam_plan_entries.duplicate(true),
		"enemy_security_visual_count": _enemy_security_visual_count,
		"enemy_security_entries": _enemy_security_entries.duplicate(true),
		"enemy_tactics_visual_count": _enemy_tactics_visual_count,
		"enemy_tactics_entries": _enemy_tactics_entries.duplicate(true),
		"friendly_aim_visual_count": _friendly_aim_visual_count,
		"friendly_aim_entries": _friendly_aim_entries.duplicate(true),
		"friendly_fire_sector_overlay_enabled": bool(_order_payload.get("fire_sector_overlay_enabled", false)),
		"friendly_fire_sector_visual_mode": _get_fire_sector_visual_mode(),
		"friendly_fire_sector_scan_mode": _get_fire_sector_scan_mode(),
		"friendly_fire_sector_tile_marker_count": _friendly_aim_tile_marker_count,
		"friendly_fire_sector_blocker_marker_count": _friendly_aim_blocker_marker_count,
		"friendly_fire_sector_los_line_count": _friendly_aim_los_line_count,
		"friendly_fire_sector_los_cache_size": _fire_sector_los_cache.size(),
		"friendly_fire_sector_blocker_line_limit": FRIENDLY_FIRE_SECTOR_BLOCKER_LINE_LIMIT,
		"friendly_fire_sector_angle_degrees": FRIENDLY_FIRE_SECTOR_ANGLE_DEGREES,
		"mission_los_debug_overlay_enabled": bool(_order_payload.get("los_debug_overlay_enabled", false)),
		"mission_los_debug_line_count": _mission_los_debug_line_count,
		"mission_los_debug_clear_line_count": _mission_los_debug_clear_line_count,
		"mission_los_debug_blocked_line_count": _mission_los_debug_blocked_line_count,
		"mission_los_debug_blocker_marker_count": _mission_los_debug_blocker_marker_count,
		"mission_los_debug_sampled_pair_count": _mission_los_debug_sampled_pair_count,
		"mission_los_debug_sample_limit": _get_mission_los_debug_sample_limit(),
		"mission_los_debug_bounded_skipped_count": _mission_los_debug_bounded_skipped_count,
		"mission_los_debug_fow_hidden_contact_count": _mission_los_debug_fow_hidden_contact_count,
		"mission_los_debug_source_unit_count": _mission_los_debug_source_unit_count,
		"mission_los_debug_contact_candidate_count": _mission_los_debug_contact_candidate_count,
		"mission_los_debug_entries": _mission_los_debug_entries.duplicate(true),
		"mission_los_debug_contact_visibility_policy": "selected_fireteams_known_contacts_fow_last_known_only",
		"selected_unit_marker_count": _selected_unit_marker_count,
		"selected_unit_marker_entries": _selected_unit_marker_entries.duplicate(true),
		"weapon_fire_vfx_visual_count": _weapon_fire_vfx_visual_count,
		"weapon_fire_vfx_entries": _weapon_fire_vfx_entries.duplicate(true),
		"weapon_fire_vfx_catalog_loaded": not _get_weapon_fire_vfx_catalog().is_empty(),
		"weapon_fire_sfx_count": _weapon_fire_sfx_count,
		"weapon_fire_sfx_suppressed_count": _weapon_fire_sfx_suppressed_count,
		"feedback_bubble_visual_count": _feedback_bubble_visual_count,
		"feedback_bubble_entries": _feedback_bubble_entries.duplicate(true),
		"tactical_communication_event_visual_count": _tactical_communication_event_visual_count,
		"tactical_communication_event_entries": _tactical_communication_event_entries.duplicate(true),
		"movement_step_sfx_count": _movement_step_sfx_count,
		"movement_step_sfx_suppressed_rate_limit_count": _movement_step_sfx_suppressed_rate_limit_count,
		"movement_step_sfx_entries": _movement_step_sfx_entries.duplicate(true),
		"audio_sfx": get_audio_sfx_debug_snapshot(),
		"fog_of_war_mode": _fog_of_war_mode,
		"fog_of_war_team_id": _fog_of_war_team_id,
		"fog_of_war_active": _is_fog_of_war_visual_filter_active(),
		"fow_tile_total_count": _fow_tile_total_count,
		"fow_visible_tile_count": _fow_visible_tile_count,
		"fow_known_dim_tile_count": _fow_known_dim_tile_count,
		"fow_explored_tile_count": _fow_explored_tile_count,
		"fow_unknown_tile_count": _fow_unknown_tile_count,
		"fow_overlay_tile_count": _fow_overlay_tile_count,
		"fow_overlay_rebuild_count": _fow_overlay_rebuild_count,
		"fow_hidden_order_visual_count": _fow_hidden_order_visual_count,
		"fow_hidden_contact_count": _fow_hidden_contact_count,
		"fow_hidden_unit_proxy_count": _fow_hidden_unit_proxy_count,
		"fow_dynamic_hidden_count": _get_fow_dynamic_hidden_count(),
		"fow_allowed_contact_count": _fow_allowed_contact_count,
		"lz_tile_marker_count": _lz_tile_marker_count,
		"requested_lz_marker_visible": _requested_lz_marker_count > 0,
		"resolved_lz_marker_visible": _resolved_lz_marker_count > 0,
		"requested_lz_marker_count": _requested_lz_marker_count,
		"resolved_lz_marker_count": _resolved_lz_marker_count,
		"dropship_lz_label_count": _dropship_lz_label_count,
		"dropship_lz_marker_fill": DROPSHIP_LZ_MARKER_FILL,
		"dropship_approach_line_width_factor": DROPSHIP_APPROACH_LINE_WIDTH_FACTOR,
		"dropship_approach_vector_shape": "wide_arrow",
		"requested_lz_position": _drop_payload.get("requested_lz_position", _drop_payload.get("target_lz_position", _drop_payload.get("lz_position", null))),
		"resolved_lz_position": _drop_payload.get("resolved_lz_position", _drop_payload.get("actual_landing_position", null)),
		"tile_grid_line_count": _tile_grid_line_count,
		"contact_count": _contact_count,
		"contact_entries": _get_contact_visual_entries(),
		"contact_density_heatmap": get_contact_density_heatmap_snapshot(),
		"contact_density_heatmap_enabled": _contact_density_overlay_enabled,
		"contact_density_heat_cell_count": _contact_density_entries.size(),
		"contact_density_heat_cells": _contact_density_entries.duplicate(true),
		"contact_density_source_contact_count": _contact_density_source_count,
		"contact_density_current_source_count": _contact_density_current_source_count,
		"contact_density_last_known_source_count": _contact_density_last_known_source_count,
		"contact_density_fow_hidden_count": _contact_density_fow_hidden_count,
		"contact_density_rebuild_count": _contact_density_rebuild_count,
		"contact_density_update_interval_msec": CONTACT_DENSITY_UPDATE_INTERVAL_MSEC,
		"contact_density_skipped_interval_count": _contact_density_skipped_interval_count,
		"objective_status_visible": _objective_status_visible,
		"objective_capture_progress": float(_mission_status_payload.get("objective_capture_progress", 0.0)),
		"mission_result_visible": _mission_result_visible,
		"mission_result": String(_mission_status_payload.get("result", "")),
		"has_lz": bool(_drop_payload.get("has_lz_position", false)),
		"show_lz_marker": bool(_drop_payload.get("show_lz_marker", bool(_drop_payload.get("has_lz_position", false)))),
		"dropship_visible": bool(_drop_payload.get("dropship_visible", false)),
		"dropship_texture_visible": _dropship_texture_visible,
		"dropship_model_visible": _dropship_model_visible,
		"dropship_visual_count": _air_visual_count,
		"dropship_approach_line_count": _dropship_approach_lines_by_id.size(),
		"dropship_approach_arrow_count": _dropship_approach_arrow_count,
		"flight_altitude_layer": String(_drop_payload.get("air_layer", AIR_LAYER_ID)),
		"air_visual_count": _air_visual_count,
		"fow_hidden_air_visual_count": _fow_hidden_air_visual_count,
		"air_unknown_terrain_reveal_block_count": _air_unknown_terrain_reveal_block_count,
		"dropship_air_y": _dropship_air_y,
		"dropship_surface_y": _dropship_surface_y,
		"dropship_air_clearance": _dropship_air_clearance,
		"dropship_rotation_y": _dropship_rotation_y,
		"dropship_above_terrain": (_dropship_model_visible or _dropship_texture_visible) and _dropship_air_clearance >= AIR_LAYER_MIN_CLEARANCE,
		"dropship_fow_policy": String(_drop_payload.get("fow_policy", "friendly_air_visible_lz_requires_visible_tile")),
		"dropship_team_id": String(_drop_payload.get("team_id", AIR_LAYER_DEFAULT_TEAM_ID)),
		"render_budget_by_category": render_budget_by_category,
		"render_budget_totals": render_budget_totals,
		"render_transparency_budget": _build_render_transparency_budget(render_budget_totals),
		"draw_budget_snapshot": _build_draw_budget_snapshot(render_monitor_snapshot),
		"pipeline_compilation_snapshot": _build_pipeline_compilation_snapshot(render_monitor_snapshot),
		"camera_yaw_degrees": _camera_yaw_degrees,
		"camera_size": _camera_size,
		"map_render_duration_msec": _map_render_duration_msec,
		"render_snapshot_request_count": _render_snapshot_request_count,
		"order_payload_apply_count": _order_payload_apply_count,
		"contact_payload_apply_count": _contact_payload_apply_count,
		"drop_payload_apply_count": _drop_payload_apply_count,
		"mission_status_payload_apply_count": _mission_status_payload_apply_count,
	}


func _build_editor_visual_recovery_snapshot() -> Dictionary:
	var grid_material := _get_tile_grid_material_for_snapshot()
	return {
		"height_step": _get_3d_height_step(),
		"ground_thickness": _get_3d_ground_thickness(),
		"grid_line_color": TILE_GRID_LINE_COLOR.to_html(true),
		"grid_line_width_factor": TILE_GRID_LINE_WIDTH_FACTOR,
		"grid_line_shadow_width_factor": TILE_GRID_LINE_SHADOW_WIDTH_FACTOR,
		"grid_line_surface_y_offset": TILE_GRID_LINE_SURFACE_Y_OFFSET,
		"grid_depth_tested": grid_material != null and not grid_material.no_depth_test,
		"grid_depth_draw_mode": int(grid_material.depth_draw_mode) if grid_material != null else -1,
		"selection_fill_color": TILE_SELECTION_FILL_COLOR.to_html(true),
		"selection_border_color": TILE_SELECTION_BORDER_COLOR.to_html(true),
		"selection_surface_y_offset": TILE_SELECTION_SURFACE_Y_OFFSET,
		"selection_border_width_factor": TILE_SELECTION_BORDER_WIDTH_FACTOR,
	}


func _build_editor_light_snapshot() -> Dictionary:
	var light: DirectionalLight3D = null
	if _world_root != null:
		light = _world_root.get_node_or_null(LIGHT_NAME) as DirectionalLight3D
	var environment: Environment = null
	if _environment != null:
		environment = _environment.environment
	return {
		"rotation_degrees": light.rotation_degrees if light != null else EDITOR_LIGHT_ROTATION_DEGREES,
		"energy": float(light.light_energy) if light != null else EDITOR_LIGHT_ENERGY,
		"shadow_enabled": bool(light.shadow_enabled) if light != null else _editor_light_shadows_enabled,
		"shadow_opacity": float(light.shadow_opacity) if light != null else EDITOR_LIGHT_SHADOW_OPACITY,
		"shadow_blur": float(light.shadow_blur) if light != null else EDITOR_LIGHT_SHADOW_BLUR,
		"ambient_light_color": environment.ambient_light_color.to_html(true) if environment != null else EDITOR_AMBIENT_LIGHT_COLOR.to_html(true),
		"ambient_light_energy": float(environment.ambient_light_energy) if environment != null else EDITOR_AMBIENT_LIGHT_ENERGY,
		"background_color": environment.background_color.to_html(true) if environment != null else EDITOR_EMPTY_BACKGROUND_COLOR.to_html(true),
	}


func _get_tile_grid_material_for_snapshot() -> StandardMaterial3D:
	if _material_cache.has(TILE_GRID_LINE_MATERIAL_KEY):
		return _material_cache[TILE_GRID_LINE_MATERIAL_KEY] as StandardMaterial3D
	var grid_node: MeshInstance3D = null
	if _map_root != null:
		grid_node = _map_root.get_node_or_null("TileGridLines3D") as MeshInstance3D
	if grid_node != null and grid_node.mesh != null and grid_node.mesh.get_surface_count() > 0:
		return grid_node.mesh.surface_get_material(0) as StandardMaterial3D
	return null


func _build_render_budget_by_category() -> Dictionary:
	return {
		"map": _build_node_budget_for_root(_map_root),
		"marker": _build_node_budget_for_root(_marker_root),
		"patrol": _build_node_budget_for_root(_patrol_root),
		"selection": _build_node_budget_for_root(_selection_root),
		"fow": _build_node_budget_for_root(_fow_root),
		"unit": _build_node_budget_for_root(_unit_root),
		"order": _build_node_budget_for_root(_order_root),
		"contact": _build_node_budget_for_root(_contact_root),
		"drop": _build_node_budget_for_root(_drop_root),
		"status": _build_node_budget_for_root(_status_root),
	}


func _build_node_budget_for_root(node: Node) -> Dictionary:
	var counts: Dictionary = {
		"node_count": 0,
		"node3d_count": 0,
		"geometry_instance_count": 0,
		"mesh_instance_count": 0,
		"multimesh_instance_count": 0,
		"sprite3d_count": 0,
		"label3d_count": 0,
		"material_count": 0,
		"transparent_material_count": 0,
	}
	var material_keys: Dictionary = {}
	_accumulate_node_budget(node, counts, material_keys)
	counts["material_count"] = material_keys.size()
	return counts


func _accumulate_node_budget(node: Node, counts: Dictionary, material_keys: Dictionary) -> void:
	if node == null:
		return
	counts["node_count"] = int(counts.get("node_count", 0)) + 1
	if node is Node3D:
		counts["node3d_count"] = int(counts.get("node3d_count", 0)) + 1
	if node is GeometryInstance3D:
		counts["geometry_instance_count"] = int(counts.get("geometry_instance_count", 0)) + 1
	if node is MeshInstance3D:
		counts["mesh_instance_count"] = int(counts.get("mesh_instance_count", 0)) + 1
		_accumulate_mesh_materials(node as MeshInstance3D, counts, material_keys)
	if node is MultiMeshInstance3D:
		counts["multimesh_instance_count"] = int(counts.get("multimesh_instance_count", 0)) + 1
	if node is Sprite3D:
		counts["sprite3d_count"] = int(counts.get("sprite3d_count", 0)) + 1
	if node is Label3D:
		counts["label3d_count"] = int(counts.get("label3d_count", 0)) + 1
	for child in node.get_children():
		_accumulate_node_budget(child, counts, material_keys)


func _accumulate_mesh_materials(mesh_instance: MeshInstance3D, counts: Dictionary, material_keys: Dictionary) -> void:
	if mesh_instance == null:
		return
	_register_budget_material(mesh_instance.material_override, counts, material_keys)
	var mesh: Mesh = mesh_instance.mesh
	if mesh == null:
		return
	for surface_index in range(mesh.get_surface_count()):
		_register_budget_material(mesh.surface_get_material(surface_index), counts, material_keys)


func _register_budget_material(material: Material, counts: Dictionary, material_keys: Dictionary) -> void:
	if material == null:
		return
	var key: String = material.resource_path.strip_edges()
	if key.is_empty():
		key = "instance:%d" % material.get_instance_id()
	material_keys[key] = true
	if material is BaseMaterial3D and int((material as BaseMaterial3D).transparency) != BaseMaterial3D.TRANSPARENCY_DISABLED:
		counts["transparent_material_count"] = int(counts.get("transparent_material_count", 0)) + 1


func _build_render_budget_totals(category_budgets: Dictionary) -> Dictionary:
	var totals: Dictionary = {
		"category_count": category_budgets.size(),
		"node_count": 0,
		"node3d_count": 0,
		"geometry_instance_count": 0,
		"mesh_instance_count": 0,
		"multimesh_instance_count": 0,
		"sprite3d_count": 0,
		"label3d_count": 0,
		"material_count": 0,
		"transparent_material_count": 0,
	}
	for budget_variant in category_budgets.values():
		var budget: Dictionary = Dictionary(budget_variant)
		for key_variant in totals.keys():
			var key: String = String(key_variant)
			if key == "category_count":
				continue
			totals[key] = int(totals.get(key, 0)) + int(budget.get(key, 0))
	return totals


func _build_render_transparency_budget(render_budget_totals: Dictionary) -> Dictionary:
	var label_count: int = int(render_budget_totals.get("label3d_count", 0))
	var sprite_count: int = int(render_budget_totals.get("sprite3d_count", 0))
	var transparent_material_count: int = int(render_budget_totals.get("transparent_material_count", 0))
	return {
		"label3d_count": label_count,
		"sprite3d_count": sprite_count,
		"transparent_material_count": transparent_material_count,
		"feedback_bubble_count": _feedback_bubble_visual_count,
		"weapon_fire_vfx_count": _weapon_fire_vfx_visual_count,
		"friendly_aim_visual_count": _friendly_aim_visual_count,
		"surface_tint_count": _surface_tint_count,
		"fog_of_war_overlay_count": _fow_overlay_tile_count,
		"transparent_overlay_count": label_count + sprite_count + transparent_material_count + _feedback_bubble_visual_count + _weapon_fire_vfx_visual_count + _friendly_aim_visual_count + _surface_tint_count + _fow_known_dim_tile_count + _fow_explored_tile_count,
		"budget_policy": "observe_and_keep_small_before_optimizing",
	}


func _build_render_monitor_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for monitor_name in RENDER_MONITOR_NAMES:
		result[String(monitor_name)] = _get_performance_monitor_value(String(monitor_name))
	return result


func _get_performance_monitor_value(monitor_name: String) -> Dictionary:
	if not ClassDB.class_has_integer_constant("Performance", monitor_name):
		return {"available": false, "value": -1.0}
	var monitor_id: int = ClassDB.class_get_integer_constant("Performance", monitor_name)
	return {
		"available": true,
		"value": float(Performance.get_monitor(monitor_id)),
	}


func _build_draw_budget_snapshot(render_monitor_snapshot: Dictionary) -> Dictionary:
	return {
		"objects_in_frame": Dictionary(render_monitor_snapshot.get("RENDER_TOTAL_OBJECTS_IN_FRAME", {})),
		"primitives_in_frame": Dictionary(render_monitor_snapshot.get("RENDER_TOTAL_PRIMITIVES_IN_FRAME", {})),
		"draw_calls_in_frame": Dictionary(render_monitor_snapshot.get("RENDER_TOTAL_DRAW_CALLS_IN_FRAME", {})),
		"video_mem_used": Dictionary(render_monitor_snapshot.get("RENDER_VIDEO_MEM_USED", {})),
		"texture_mem_used": Dictionary(render_monitor_snapshot.get("RENDER_TEXTURE_MEM_USED", {})),
		"buffer_mem_used": Dictionary(render_monitor_snapshot.get("RENDER_BUFFER_MEM_USED", {})),
	}


func _build_pipeline_compilation_snapshot(render_monitor_snapshot: Dictionary) -> Dictionary:
	return {
		"canvas": Dictionary(render_monitor_snapshot.get("PIPELINE_COMPILATIONS_CANVAS", {})),
		"mesh": Dictionary(render_monitor_snapshot.get("PIPELINE_COMPILATIONS_MESH", {})),
		"surface": Dictionary(render_monitor_snapshot.get("PIPELINE_COMPILATIONS_SURFACE", {})),
		"draw": Dictionary(render_monitor_snapshot.get("PIPELINE_COMPILATIONS_DRAW", {})),
		"specialization": Dictionary(render_monitor_snapshot.get("PIPELINE_COMPILATIONS_SPECIALIZATION", {})),
	}


func _ensure_nodes() -> void:
	if _viewport_container == null:
		_viewport_container = get_node_or_null(VIEWPORT_CONTAINER_NAME) as SubViewportContainer
	if _viewport_container == null:
		_viewport_container = SubViewportContainer.new()
		_viewport_container.name = VIEWPORT_CONTAINER_NAME
		_viewport_container.stretch = true
		_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_viewport_container)

	if _subviewport == null:
		_subviewport = _viewport_container.get_node_or_null(VIEWPORT_NAME) as SubViewport
	if _subviewport == null:
		_subviewport = SubViewport.new()
		_subviewport.name = VIEWPORT_NAME
		_subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		_subviewport.transparent_bg = false
		_subviewport.size = _get_viewport_size()
		_viewport_container.add_child(_subviewport)

	if _feedback_bubble_hud_root == null:
		_feedback_bubble_hud_root = get_node_or_null(FEEDBACK_BUBBLE_HUD_ROOT_NAME) as Control
	if _feedback_bubble_hud_root == null:
		_feedback_bubble_hud_root = Control.new()
		_feedback_bubble_hud_root.name = FEEDBACK_BUBBLE_HUD_ROOT_NAME
		_feedback_bubble_hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_feedback_bubble_hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(_feedback_bubble_hud_root)
	_feedback_bubble_hud_root.z_as_relative = false
	_feedback_bubble_hud_root.z_index = 512

	if _world_root == null:
		_world_root = _subviewport.get_node_or_null(WORLD_ROOT_NAME) as Node3D
	if _world_root == null:
		_world_root = Node3D.new()
		_world_root.name = WORLD_ROOT_NAME
		_subviewport.add_child(_world_root)

	_map_root = _ensure_node3d(_world_root, MAP_ROOT_NAME)
	_marker_root = _ensure_node3d(_world_root, MARKER_ROOT_NAME)
	_fow_root = _ensure_node3d(_world_root, FOW_ROOT_NAME)
	_patrol_root = _ensure_node3d(_world_root, PATROL_ROOT_NAME)
	_selection_root = _ensure_node3d(_world_root, SELECTION_ROOT_NAME)
	_unit_root = _ensure_node3d(_world_root, UNIT_ROOT_NAME)
	_order_root = _ensure_node3d(_world_root, ORDER_ROOT_NAME)
	_contact_density_root = _ensure_node3d(_world_root, CONTACT_DENSITY_ROOT_NAME)
	_contact_root = _ensure_node3d(_world_root, CONTACT_ROOT_NAME)
	_drop_root = _ensure_node3d(_world_root, DROP_ROOT_NAME)
	_status_root = _ensure_node3d(_world_root, STATUS_ROOT_NAME)

	if _camera == null:
		_camera = _world_root.get_node_or_null(CAMERA_NAME) as Camera3D
	if _camera == null:
		_camera = Camera3D.new()
		_camera.name = CAMERA_NAME
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.current = true
		_world_root.add_child(_camera)

	var light := _world_root.get_node_or_null(LIGHT_NAME) as DirectionalLight3D
	if light == null:
		light = DirectionalLight3D.new()
		light.name = LIGHT_NAME
		_world_root.add_child(light)
	_apply_editor_light_settings()

	if _environment == null:
		_environment = _world_root.get_node_or_null(ENVIRONMENT_NAME) as WorldEnvironment
	if _environment == null:
		_environment = WorldEnvironment.new()
		_environment.name = ENVIRONMENT_NAME
		_world_root.add_child(_environment)
	if _environment.environment == null:
		_environment.environment = Environment.new()
	var environment := _environment.environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = EDITOR_EMPTY_BACKGROUND_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = EDITOR_AMBIENT_LIGHT_COLOR
	environment.ambient_light_energy = EDITOR_AMBIENT_LIGHT_ENERGY


func _apply_editor_light_settings() -> void:
	if _world_root == null:
		return
	var light := _world_root.get_node_or_null(LIGHT_NAME) as DirectionalLight3D
	if light == null:
		return
	light.light_energy = EDITOR_LIGHT_ENERGY
	light.rotation_degrees = EDITOR_LIGHT_ROTATION_DEGREES
	light.shadow_enabled = _editor_light_shadows_enabled
	light.shadow_opacity = EDITOR_LIGHT_SHADOW_OPACITY
	light.shadow_blur = EDITOR_LIGHT_SHADOW_BLUR


func _ensure_node3d(parent: Node, node_name: String) -> Node3D:
	var node := parent.get_node_or_null(node_name) as Node3D
	if node != null:
		return node
	node = Node3D.new()
	node.name = node_name
	parent.add_child(node)
	return node


func _resize_subviewport() -> void:
	if _subviewport == null or _viewport_container == null:
		return
	var viewport_size: Vector2i = _get_viewport_size()
	if _subviewport.size != viewport_size:
		_subviewport.size = viewport_size
		_request_viewport_redraw()
	_viewport_container.offset_left = 0.0
	_viewport_container.offset_top = 0.0
	_viewport_container.offset_right = 0.0
	_viewport_container.offset_bottom = 0.0
	if _feedback_bubble_hud_root != null:
		_feedback_bubble_hud_root.offset_left = 0.0
		_feedback_bubble_hud_root.offset_top = 0.0
		_feedback_bubble_hud_root.offset_right = 0.0
		_feedback_bubble_hud_root.offset_bottom = 0.0


func _request_viewport_redraw(continuous: bool = false) -> void:
	if _subviewport == null:
		return
	if continuous:
		_continuous_redraw_until_msec = Time.get_ticks_msec() + CONTINUOUS_REDRAW_AFTER_CAMERA_MSEC
		_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		return
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _get_viewport_size() -> Vector2i:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2i(1280, 720)
	var visible_size: Vector2 = viewport.get_visible_rect().size
	return Vector2i(maxi(roundi(visible_size.x), 1), maxi(roundi(visible_size.y), 1))


func _screen_to_viewport_position(screen_position: Vector2) -> Vector2:
	return Vector2(
		clampf(screen_position.x, 0.0, float(_get_viewport_size().x)),
		clampf(screen_position.y, 0.0, float(_get_viewport_size().y))
	)


func _read_map_transform() -> void:
	if _terrain_map_data == null:
		return
	_grid_size = _terrain_map_data.call("get_grid_size")
	_grid_origin_world = _terrain_map_data.call("get_grid_origin")
	var tile_size: Dictionary = Dictionary(_terrain_map_data.call("get_tile_size"))
	_half_tile_width = maxf(float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH)), 0.001)
	_half_tile_height = maxf(float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT)), 0.001)
	if _focus_grid_position == Vector2.ZERO:
		focus_map_center()


func _update_camera_transform() -> void:
	_ensure_nodes()
	if _camera == null:
		return
	_camera.size = _camera_size
	var focus_3d: Vector3 = _grid_to_3d_position(_focus_grid_position, 0.0)
	var yaw_rad: float = deg_to_rad(_camera_yaw_degrees)
	var pitch_rad: float = deg_to_rad(_camera_pitch_degrees)
	var horizontal_distance: float = maxf(_camera_size * 1.08, 10.0)
	var height: float = maxf(sin(pitch_rad) * _camera_size * 1.18, 8.0)
	var camera_offset := Vector3(sin(yaw_rad) * horizontal_distance, height, cos(yaw_rad) * horizontal_distance)
	_camera.global_position = focus_3d + camera_offset
	_camera.look_at(focus_3d, Vector3.UP)
	_request_viewport_redraw()


func _clamp_focus_to_map() -> void:
	if _grid_size == Vector2i.ZERO:
		return
	_focus_grid_position.x = clampf(_focus_grid_position.x, -2.0, float(_grid_size.x) + 2.0)
	_focus_grid_position.y = clampf(_focus_grid_position.y, -2.0, float(_grid_size.y) + 2.0)


func _add_tile_visual(tile_data) -> void:
	if tile_data == null or _map_root == null:
		return
	var height_level: int = maxi(int(tile_data.height_level), 0)
	var top_y: float = float(height_level) * _get_3d_height_step()
	var tile_thickness: float = _get_3d_ground_thickness()
	var tile_fill: float = _get_3d_ground_fill()
	var cell_size: float = _get_3d_cell_size()
	if _uses_strict_3d_asset_mapping():
		var ground_visual_type_id: String = _resolve_ground_surface_model_key(tile_data)
		if not _add_ground_model_visual(tile_data, top_y, ground_visual_type_id):
			_add_missing_asset_marker(tile_data, top_y, ground_visual_type_id)
	else:
		var tile_mesh := _make_box_mesh(Vector3(cell_size * tile_fill, tile_thickness, cell_size * tile_fill))
		var tile_instance := MeshInstance3D.new()
		tile_instance.name = "Tile_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
		tile_instance.mesh = tile_mesh
		tile_instance.material_override = _make_material(_get_tile_color(tile_data))
		tile_instance.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y - (tile_thickness * 0.5))
		_map_root.add_child(tile_instance)
		_ground_mesh_count += 1
	_add_surface_tint_visual(tile_data, top_y)
	_add_surface_detail_visual(tile_data, top_y)
	_map_tile_count += 1

	var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	var structure_visual_type_id: String = _resolve_structure_tile_asset_type_id(type_id)
	if not structure_visual_type_id.is_empty():
		_add_object_visual(tile_data, top_y, structure_visual_type_id, true)
	var object_visual_type_id: String = _resolve_tile_asset_type_id(object_type_id, "" if not structure_visual_type_id.is_empty() else type_id)
	if not object_visual_type_id.is_empty():
		_add_object_visual(tile_data, top_y, object_visual_type_id, true)
	elif structure_visual_type_id.is_empty() and (bool(tile_data.blocks_los) or int(tile_data.object_height) > 0):
		_add_object_visual(tile_data, top_y, "")


func _add_object_visual(tile_data, top_y: float, visual_type_id: String, apply_tile_rotation: bool = false) -> void:
	if not visual_type_id.is_empty() and _add_asset_model_visual(tile_data, top_y, visual_type_id, apply_tile_rotation):
		return
	if _uses_strict_3d_asset_mapping():
		_add_missing_asset_marker(tile_data, top_y, _get_missing_visual_type_id(tile_data, visual_type_id))
		return
	if not visual_type_id.is_empty() and _add_asset_texture_visual(tile_data, top_y, visual_type_id):
		return

	var object_height: float = maxf(float(tile_data.object_height), 1.0) * OBJECT_HEIGHT_STEP
	var type_id: String = visual_type_id
	if type_id.is_empty():
		type_id = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	if type_id.is_empty():
		type_id = String(tile_data.type_id) if tile_data.type_id is String else ""
	if type_id.begins_with("rock_"):
		object_height = maxf(object_height, 0.55)
	elif type_id.begins_with("wall_") or type_id.begins_with("cliff_"):
		object_height = maxf(object_height, 1.1)
	elif not bool(tile_data.blocks_los):
		object_height = maxf(object_height, 0.35)

	var cell_size: float = _get_3d_cell_size()
	var mesh := _make_box_mesh(Vector3(cell_size * 0.62, object_height, cell_size * 0.62))
	var instance := MeshInstance3D.new()
	instance.name = "Object_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
	instance.mesh = mesh
	instance.material_override = _make_material(_get_object_color(type_id, tile_data))
	instance.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + (object_height * 0.5))
	_map_root.add_child(instance)
	_placeholder_object_count += 1


func _add_ground_model_visual(tile_data, top_y: float, visual_type_id: String = "ground_flat") -> bool:
	var normalized_visual_type_id: String = visual_type_id.strip_edges().to_lower()
	if normalized_visual_type_id.is_empty():
		normalized_visual_type_id = "ground_flat"
	var model_scene := _get_asset_model_scene(normalized_visual_type_id)
	if model_scene == null or _map_root == null:
		return false
	var model_instance := model_scene.instantiate() as Node3D
	if model_instance == null:
		return false
	_normalize_asset_model_instance(model_instance)
	var material_override_color: Color = _apply_ground_surface_material_override(model_instance, normalized_visual_type_id, tile_data)
	var material_override_unshaded: bool = material_override_color != Color.TRANSPARENT and normalized_visual_type_id == "ground_flat"
	var mapped_entry: Dictionary = _get_model_entry_for_type(normalized_visual_type_id)
	if _is_space_station_model_entry(mapped_entry):
		_space_station_model_count += 1
		_space_station_textured_surface_count += _apply_space_station_colormap_recursive(model_instance)

	var ground_root := Node3D.new()
	ground_root.name = "Tile_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
	var model_height: float = _get_normalized_model_height(model_instance)
	var model_scale: float = _get_ground_surface_model_scale(normalized_visual_type_id)
	var visual_height: float = model_height * model_scale
	var surface_top_y_offset: float = _get_ground_surface_top_y_offset(normalized_visual_type_id)
	var visual_top_y: float = top_y + surface_top_y_offset
	var ground_y: float = visual_top_y
	if visual_height > 0.001:
		ground_y = visual_top_y - visual_height
	ground_root.position = _grid_to_3d_position(Vector2(tile_data.grid_position), ground_y)
	if _ground_surface_supports_tile_rotation(normalized_visual_type_id):
		ground_root.rotation_degrees.y = _get_tile_object_rotation_degrees(tile_data)
	ground_root.scale = Vector3.ONE * model_scale
	ground_root.add_child(model_instance)
	_map_root.add_child(ground_root)
	_ground_mesh_count += 1
	_register_ground_surface_visual(tile_data, normalized_visual_type_id, ground_y, top_y, visual_height, material_override_color, material_override_unshaded, surface_top_y_offset)
	return true


func _ground_surface_supports_tile_rotation(visual_type_id: String) -> bool:
	var normalized_visual_type_id: String = visual_type_id.strip_edges().to_lower()
	return normalized_visual_type_id == "station_floor_panel" or normalized_visual_type_id.begins_with("station_set_floor") or normalized_visual_type_id == "modular_floor" or normalized_visual_type_id == "modular_floor_big" or normalized_visual_type_id == "modular_floor_raised"


func _resolve_ground_surface_model_key(tile_data) -> String:
	if tile_data == null:
		return "ground_flat"
	var catalog: Dictionary = _get_terrain_surface_visual_theme_catalog()
	if catalog.is_empty():
		return "ground_flat"
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	var type_overrides: Dictionary = Dictionary(catalog.get("tile_type_overrides", {}))
	if not type_id.is_empty() and type_overrides.has(type_id):
		var override_key: String = String(type_overrides.get(type_id, "")).strip_edges().to_lower()
		if not override_key.is_empty():
			return override_key
	if _tile_should_use_station_floor_surface(tile_data):
		return "station_floor_panel"
	var surface_type: String = String(tile_data.surface_type).strip_edges().to_lower()
	var surface_models: Dictionary = Dictionary(catalog.get("surface_model_by_surface", {}))
	var model_key: String = String(surface_models.get(surface_type, "")).strip_edges().to_lower()
	if model_key.is_empty():
		model_key = String(surface_models.get(TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, "ground_flat")).strip_edges().to_lower()
	return model_key if not model_key.is_empty() else "ground_flat"


func _tile_should_use_station_floor_surface(tile_data) -> bool:
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower() if tile_data.object_type_id is String else ""
	if type_id == "station_floor_panel" or type_id.begins_with("station_") or object_type_id.begins_with("station_"):
		return true
	if String(tile_data.surface_type).strip_edges().to_lower() != TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
		return false
	for prefix in ["wall_", "station_wall"]:
		if type_id.begins_with(prefix):
			return true
	return false


func _add_surface_detail_visual(tile_data, top_y: float) -> void:
	if tile_data == null or _map_root == null or not _uses_strict_3d_asset_mapping():
		return
	var detail_model_key: String = _resolve_surface_detail_model_key(tile_data)
	if detail_model_key.is_empty():
		return
	var model_scene := _get_asset_model_scene(detail_model_key)
	if model_scene == null:
		_add_missing_asset_marker(tile_data, top_y, detail_model_key)
		return
	var model_instance := model_scene.instantiate() as Node3D
	if model_instance == null:
		return
	_normalize_asset_model_instance(model_instance)

	var detail_root := Node3D.new()
	detail_root.name = "SurfaceDetail_%s_%d_%d" % [detail_model_key, tile_data.grid_position.x, tile_data.grid_position.y]
	detail_root.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + _get_asset_y_offset(detail_model_key)) + _get_asset_position_offset(detail_model_key)
	detail_root.rotation_degrees.y = _get_asset_rotation_y(detail_model_key)
	detail_root.scale = Vector3.ONE * _get_asset_model_scale(detail_model_key)
	detail_root.add_child(model_instance)
	_map_root.add_child(detail_root)
	_register_surface_detail_visual(tile_data, detail_model_key, detail_root, top_y)


func _resolve_surface_detail_model_key(tile_data) -> String:
	if tile_data == null:
		return ""
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	if type_id.is_empty():
		return ""
	var catalog: Dictionary = _get_terrain_surface_visual_theme_catalog()
	var detail_by_type: Dictionary = Dictionary(catalog.get("surface_detail_by_tile_type", {}))
	return String(detail_by_type.get(type_id, "")).strip_edges().to_lower()


func _register_surface_detail_visual(tile_data, visual_type_id: String, visual_root: Node3D, top_y: float) -> void:
	if tile_data == null:
		return
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	var visual_entry: Dictionary = _get_surface_visual_entry_for_model_key(visual_type_id)
	var is_nature_kit: bool = _is_nature_kit_model_entry(mapped_entry)
	var theme: String = String(visual_entry.get("theme", mapped_entry.get("nature_theme", ""))).strip_edges()
	if theme.is_empty():
		theme = "detail"
	if is_nature_kit:
		_nature_surface_detail_model_count += 1
		_nature_surface_theme_counts[theme] = int(_nature_surface_theme_counts.get(theme, 0)) + 1
	_surface_detail_visual_entries.append({
		"node_name": String(visual_root.name) if visual_root != null else "",
		"grid_position": tile_data.grid_position,
		"type_id": String(tile_data.type_id),
		"surface_type": String(tile_data.surface_type),
		"model_key": visual_type_id,
		"model_path": String(mapped_entry.get("model_path", "")),
		"source_id": String(mapped_entry.get("source_id", "")),
		"theme": theme,
		"visual_id": String(visual_entry.get("visual_id", visual_type_id)),
		"is_nature_kit": is_nature_kit,
		"surface_y": top_y,
		"world_y": visual_root.position.y if visual_root != null else top_y,
		"y_offset": _get_asset_y_offset(visual_type_id),
		"position_offset": _get_asset_position_offset(visual_type_id),
	})


func _register_ground_surface_visual(
	tile_data,
	visual_type_id: String,
	ground_y: float = 0.0,
	top_y: float = 0.0,
	visual_height: float = 0.0,
	material_override_color: Color = Color.TRANSPARENT,
	material_override_unshaded: bool = false,
	surface_top_y_offset: float = 0.0
) -> void:
	if tile_data == null:
		return
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	var visual_entry: Dictionary = _get_surface_visual_entry_for_model_key(visual_type_id)
	var is_nature_kit: bool = _is_nature_kit_model_entry(mapped_entry)
	var theme: String = String(visual_entry.get("theme", mapped_entry.get("nature_theme", ""))).strip_edges()
	if theme.is_empty():
		theme = "default"
	if is_nature_kit:
		_nature_surface_ground_model_count += 1
		_nature_surface_theme_counts[theme] = int(_nature_surface_theme_counts.get(theme, 0)) + 1
	_surface_visual_entries.append({
		"grid_position": tile_data.grid_position,
		"type_id": String(tile_data.type_id),
		"surface_type": String(tile_data.surface_type),
		"model_key": visual_type_id,
		"model_path": String(mapped_entry.get("model_path", "")),
		"source_id": String(mapped_entry.get("source_id", "")),
		"theme": theme,
		"visual_id": String(visual_entry.get("visual_id", visual_type_id)),
		"is_nature_kit": is_nature_kit,
		"surface_y": top_y,
		"surface_top_y_offset": surface_top_y_offset,
		"world_y": ground_y,
		"visual_bottom_y": ground_y,
		"visual_top_y": ground_y + visual_height,
		"visual_height": visual_height,
		"scale": _get_ground_surface_model_scale(visual_type_id),
		"has_material_override": material_override_color != Color.TRANSPARENT,
		"material_override_color": material_override_color,
		"material_override_unshaded": material_override_unshaded,
	})


func _apply_ground_surface_material_override(model_instance: Node3D, visual_type_id: String, tile_data) -> Color:
	var override_color: Color = _get_ground_surface_model_override_color(visual_type_id, tile_data)
	if override_color == Color.TRANSPARENT:
		return Color.TRANSPARENT
	var material: StandardMaterial3D = _make_unshaded_material(override_color) if visual_type_id.strip_edges().to_lower() == "ground_flat" else _make_material(override_color)
	_apply_material_override_recursive(model_instance, material)
	return override_color


func _get_ground_surface_model_override_color(visual_type_id: String, tile_data) -> Color:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized == "ground_flat":
		return _get_space_kit_terrain_top_color()
	if normalized != "nature_ground_dirt":
		return Color.TRANSPARENT
	var surface_type: String = TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
	if tile_data != null and tile_data.surface_type is String:
		surface_type = String(tile_data.surface_type).strip_edges().to_lower()
	match surface_type:
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			return Color(0.62, 0.48, 0.30, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
			return Color(0.36, 0.35, 0.31, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			return Color(0.34, 0.36, 0.34, 1.0)
		_:
			return Color(0.38, 0.34, 0.24, 1.0)


func _get_space_kit_terrain_top_color() -> Color:
	if _space_kit_terrain_top_color != Color.TRANSPARENT:
		return _space_kit_terrain_top_color
	var sampled_color: Color = _sample_space_kit_terrain_top_color()
	_space_kit_terrain_top_color = sampled_color if sampled_color != Color.TRANSPARENT else SPACE_KIT_TERRAIN_TOP_COLOR_FALLBACK
	return _space_kit_terrain_top_color


func _sample_space_kit_terrain_top_color() -> Color:
	if TILE_TEXTURE == null:
		return Color.TRANSPARENT
	var image: Image = TILE_TEXTURE.get_image()
	if image == null or image.is_empty():
		return Color.TRANSPARENT
	var sample_position := Vector2i(
		clampi(SPACE_KIT_TERRAIN_TOP_SAMPLE.x, 0, image.get_width() - 1),
		clampi(SPACE_KIT_TERRAIN_TOP_SAMPLE.y, 0, image.get_height() - 1)
	)
	var sampled_color: Color = image.get_pixelv(sample_position)
	if sampled_color.a < 0.5:
		sampled_color = _find_opaque_space_kit_terrain_pixel(image, sample_position)
	if sampled_color.a < 0.5:
		return Color.TRANSPARENT
	sampled_color.a = 1.0
	return sampled_color


func _find_opaque_space_kit_terrain_pixel(image: Image, sample_position: Vector2i) -> Color:
	var radius: int = 64
	for y in range(maxi(sample_position.y - radius, 0), mini(sample_position.y + radius + 1, image.get_height())):
		for x in range(maxi(sample_position.x - radius, 0), mini(sample_position.x + radius + 1, image.get_width())):
			var sampled_color: Color = image.get_pixel(x, y)
			if sampled_color.a >= 0.5:
				return sampled_color
	return Color.TRANSPARENT


func _add_missing_asset_marker(tile_data, top_y: float, visual_type_id: String) -> void:
	if tile_data == null or _map_root == null:
		return
	var type_id: String = visual_type_id.strip_edges().to_lower()
	if type_id.is_empty():
		type_id = "unknown"
	var cell_size: float = _get_3d_cell_size()
	var marker := MeshInstance3D.new()
	marker.name = "MissingAsset_%s_%d_%d" % [type_id, tile_data.grid_position.x, tile_data.grid_position.y]
	marker.mesh = _make_box_mesh(Vector3(cell_size * 0.42, cell_size * 0.22, cell_size * 0.42))
	marker.material_override = _make_material(Color(1.0, 0.12, 0.72, 1.0))
	marker.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + 0.14)
	_map_root.add_child(marker)
	_missing_asset_mapping_count += 1


func _add_surface_tint_visual(tile_data, top_y: float) -> void:
	if tile_data == null or _map_root == null or not _uses_strict_3d_asset_mapping():
		return
	if _tile_should_use_station_floor_surface(tile_data):
		return
	var surface_type: String = String(tile_data.surface_type).strip_edges().to_lower()
	if surface_type == TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND:
		return
	var tint_color := Color.TRANSPARENT
	match surface_type:
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			tint_color = Color(1.0, 0.86, 0.34, 0.34)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			tint_color = Color(0.64, 0.69, 0.72, 0.30)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
			tint_color = Color(0.54, 0.50, 0.42, 0.32)
		_:
			return
	var cell_size: float = _get_3d_cell_size()
	var tint := MeshInstance3D.new()
	tint.name = "SurfaceTint_%s_%d_%d" % [surface_type, tile_data.grid_position.x, tile_data.grid_position.y]
	tint.mesh = _make_box_mesh(Vector3(cell_size * 0.82, 0.012, cell_size * 0.82))
	tint.material_override = _make_material(tint_color, true)
	tint.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + 0.018)
	_map_root.add_child(tint)
	_surface_tint_count += 1
	if int(tile_data.height_level) > 0:
		_elevated_surface_tint_count += 1


func _add_tile_grid_lines(tiles: Array) -> void:
	if _map_root == null or tiles.is_empty():
		return
	var shadow_material := _make_editor_grid_material(false)
	var highlight_material := _make_editor_grid_material(true)
	var shadow_mesh := ImmediateMesh.new()
	shadow_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, shadow_material)
	var highlight_mesh := ImmediateMesh.new()
	highlight_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, highlight_material)
	var cell_size: float = _get_3d_cell_size()
	var half_size: float = cell_size * 0.5
	var line_width: float = maxf(cell_size * TILE_GRID_LINE_WIDTH_FACTOR, 0.012)
	var shadow_line_width: float = maxf(cell_size * TILE_GRID_LINE_SHADOW_WIDTH_FACTOR, 0.018)
	var line_count: int = 0
	var rendered_edges: Dictionary = {}
	for tile_data in tiles:
		if tile_data == null:
			continue
		var grid_position: Vector2 = Vector2(tile_data.grid_position)
		var top_y: float = (float(tile_data.height_level) * _get_3d_height_step()) + TILE_GRID_LINE_SURFACE_Y_OFFSET
		var center: Vector3 = _grid_to_3d_position(grid_position, top_y)
		var highlight_center: Vector3 = center + Vector3(0.0, TILE_GRID_LINE_HIGHLIGHT_Y_OFFSET, 0.0)
		var nw := center + Vector3(-half_size, 0.0, -half_size)
		var ne := center + Vector3(half_size, 0.0, -half_size)
		var se := center + Vector3(half_size, 0.0, half_size)
		var sw := center + Vector3(-half_size, 0.0, half_size)
		var hnw := highlight_center + Vector3(-half_size, 0.0, -half_size)
		var hne := highlight_center + Vector3(half_size, 0.0, -half_size)
		var hse := highlight_center + Vector3(half_size, 0.0, half_size)
		var hsw := highlight_center + Vector3(-half_size, 0.0, half_size)
		if _add_unique_grid_line_quad(shadow_mesh, rendered_edges, nw, ne, shadow_line_width):
			_add_grid_line_quad(highlight_mesh, hnw, hne, line_width)
			line_count += 1
		if _add_unique_grid_line_quad(shadow_mesh, rendered_edges, ne, se, shadow_line_width):
			_add_grid_line_quad(highlight_mesh, hne, hse, line_width)
			line_count += 1
		if _add_unique_grid_line_quad(shadow_mesh, rendered_edges, se, sw, shadow_line_width):
			_add_grid_line_quad(highlight_mesh, hse, hsw, line_width)
			line_count += 1
		if _add_unique_grid_line_quad(shadow_mesh, rendered_edges, sw, nw, shadow_line_width):
			_add_grid_line_quad(highlight_mesh, hsw, hnw, line_width)
			line_count += 1
	shadow_mesh.surface_end()
	highlight_mesh.surface_end()
	if line_count <= 0:
		return
	var shadow_lines := MeshInstance3D.new()
	shadow_lines.name = "TileGridShadowLines3D"
	shadow_lines.mesh = shadow_mesh
	_map_root.add_child(shadow_lines)
	var lines := MeshInstance3D.new()
	lines.name = "TileGridLines3D"
	lines.mesh = highlight_mesh
	_map_root.add_child(lines)
	_tile_grid_line_count = line_count


func _add_unique_grid_line_quad(mesh: ImmediateMesh, rendered_edges: Dictionary, start_point: Vector3, end_point: Vector3, line_width: float) -> bool:
	var edge_key: String = _get_grid_edge_key(start_point, end_point)
	if rendered_edges.has(edge_key):
		return false
	rendered_edges[edge_key] = true
	_add_grid_line_quad(mesh, start_point, end_point, line_width)
	return true


func _add_grid_line_quad(mesh: ImmediateMesh, start_point: Vector3, end_point: Vector3, line_width: float) -> void:
	var direction: Vector3 = end_point - start_point
	if direction.length_squared() <= 0.000001:
		return
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0.0, direction.x) * (line_width * 0.5)
	var a := start_point + side
	var b := end_point + side
	var c := end_point - side
	var d := start_point - side
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(c)
	mesh.surface_add_vertex(d)


func _get_grid_edge_key(start_point: Vector3, end_point: Vector3) -> String:
	var start_key: String = _get_grid_point_key(start_point)
	var end_key: String = _get_grid_point_key(end_point)
	if end_key.naturalnocasecmp_to(start_key) < 0:
		return "%s|%s" % [end_key, start_key]
	return "%s|%s" % [start_key, end_key]


func _get_grid_point_key(point: Vector3) -> String:
	return "%d,%d,%d" % [roundi(point.x * 1000.0), roundi(point.y * 1000.0), roundi(point.z * 1000.0)]


func _add_height_edge_visuals(tile_data) -> void:
	if _uses_strict_3d_asset_mapping():
		_add_height_edge_model_visuals(tile_data)
	else:
		_add_height_edge_texture_visuals(tile_data)


func _add_height_edge_model_visuals(tile_data) -> void:
	if tile_data == null or _map_root == null:
		return
	if int(tile_data.height_level) <= 0:
		return
	var current_edge_type: String = String(tile_data.edge_type)
	var edge_dirs: Array[Vector2i] = _collect_lower_height_edge_dirs(tile_data)
	if edge_dirs.is_empty():
		return
	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
		_height_edge_authoring_conflict_count += edge_dirs.size()
		return

	var grid_pos: Vector2i = tile_data.grid_position
	var top_y: float = float(int(tile_data.height_level)) * _get_3d_height_step()
	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF:
		var corner_map: Array = [
			[Vector2i(1, 0), Vector2i(0, 1), "cliff_corner_ne"],
			[Vector2i(1, 0), Vector2i(0, -1), "cliff_corner_nw"],
			[Vector2i(-1, 0), Vector2i(0, 1), "cliff_corner_se"],
			[Vector2i(-1, 0), Vector2i(0, -1), "cliff_corner_sw"],
		]
		var edges_consumed_by_corners: Array[Vector2i] = []
		for corner_entry in corner_map:
			var dir_a: Vector2i = corner_entry[0]
			var dir_b: Vector2i = corner_entry[1]
			var visual_type_id: String = String(corner_entry[2])
			if edge_dirs.has(dir_a) and edge_dirs.has(dir_b):
				if _add_height_edge_model(tile_data, top_y, visual_type_id, "HeightCorner_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, dir_a.x + dir_b.x, dir_a.y + dir_b.y], [dir_a, dir_b]):
					if not edges_consumed_by_corners.has(dir_a):
						edges_consumed_by_corners.append(dir_a)
					if not edges_consumed_by_corners.has(dir_b):
						edges_consumed_by_corners.append(dir_b)
		for edge_dir in edge_dirs:
			if edges_consumed_by_corners.has(edge_dir):
				continue
			_add_height_edge_model(tile_data, top_y, _get_height_edge_visual_type_id(current_edge_type, edge_dir), "HeightEdge_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, edge_dir.x, edge_dir.y], [edge_dir])
		return

	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		for edge_dir in edge_dirs:
			_add_height_edge_model(tile_data, top_y, _get_height_edge_visual_type_id(current_edge_type, edge_dir), "HeightEdge_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, edge_dir.x, edge_dir.y], [edge_dir])


func _add_height_edge_model(tile_data, top_y: float, visual_type_id: String, node_name: String, edge_dirs: Array = []) -> bool:
	if String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF and _has_explicit_cliff_visual_at_height_edge_anchor(tile_data, edge_dirs):
		return false
	var model_scene := _get_asset_model_scene(visual_type_id)
	if model_scene == null or _map_root == null:
		_add_missing_asset_marker(tile_data, top_y, visual_type_id)
		return false
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	var model_instance := model_scene.instantiate() as Node3D
	if model_instance == null:
		_add_missing_asset_marker(tile_data, top_y, visual_type_id)
		return false
	_normalize_asset_model_instance(model_instance)
	var edge_base_y: float = _get_height_edge_base_y(tile_data, edge_dirs)
	var edge_span: float = maxf(top_y - edge_base_y, _get_3d_height_step())
	var model_height: float = _get_normalized_model_height(model_instance)
	var model_scale: float = _get_asset_model_scale(visual_type_id)
	var visual_root := Node3D.new()
	visual_root.name = "%s_%s" % [node_name, visual_type_id]
	var anchor_grid_position: Vector2 = _get_height_edge_anchor_grid_position(tile_data, edge_dirs)
	visual_root.position = _grid_to_3d_position(anchor_grid_position, edge_base_y + _get_height_edge_asset_y_offset(visual_type_id)) + _get_asset_position_offset(visual_type_id)
	visual_root.rotation_degrees.y = _get_asset_rotation_y(visual_type_id)
	visual_root.scale = Vector3(model_scale, edge_span / model_height, model_scale)
	visual_root.add_child(model_instance)
	_map_root.add_child(visual_root)
	_asset_model_count += 1
	_height_edge_model_count += 1
	var is_slope_edge: bool = String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	var is_nature_kit: bool = _is_nature_kit_model_entry(mapped_entry)
	if String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		_slope_edge_model_count += 1
	else:
		_cliff_edge_model_count += 1
	if is_nature_kit:
		var theme: String = String(mapped_entry.get("nature_theme", "default")).strip_edges()
		if theme.is_empty():
			theme = "default"
		_nature_cliff_theme_counts[theme] = int(_nature_cliff_theme_counts.get(theme, 0)) + 1
		if is_slope_edge:
			_nature_slope_step_model_count += 1
		else:
			_nature_cliff_edge_model_count += 1
	_height_edge_visual_entries.append({
		"node_name": visual_root.name,
		"visual_type_id": visual_type_id,
		"edge_type": String(tile_data.edge_type),
		"surface_type": String(tile_data.surface_type),
		"grid_position": tile_data.grid_position,
		"anchor_grid_position": anchor_grid_position,
		"edge_dirs": edge_dirs.duplicate(),
		"base_y": edge_base_y,
		"top_y": top_y,
		"height_span": edge_span,
		"model_path": String(mapped_entry.get("model_path", "")),
		"source_id": String(mapped_entry.get("source_id", "")),
		"nature_theme": String(mapped_entry.get("nature_theme", "")),
		"edge_role": String(mapped_entry.get("edge_role", "")),
		"is_nature_kit": is_nature_kit,
	})
	return true


func _has_explicit_cliff_visual_at_height_edge_anchor(tile_data, edge_dirs: Array) -> bool:
	if tile_data == null or edge_dirs.is_empty():
		return false
	var anchor_grid_position := Vector2i(tile_data.grid_position)
	for edge_dir_variant in edge_dirs:
		anchor_grid_position += Vector2i(edge_dir_variant)
	var anchor_tile = _render_tile_by_grid.get(anchor_grid_position, null)
	if anchor_tile == null:
		return false
	var anchor_type_id: String = String(anchor_tile.type_id).strip_edges().to_lower() if anchor_tile.type_id is String else ""
	return anchor_type_id.begins_with("cliff_")


func _get_height_edge_anchor_grid_position(tile_data, edge_dirs: Array) -> Vector2:
	if tile_data == null:
		return Vector2.ZERO
	var anchor_grid := Vector2(tile_data.grid_position)
	if edge_dirs.is_empty():
		return anchor_grid
	var offset := Vector2.ZERO
	for edge_dir_variant in edge_dirs:
		offset += Vector2(Vector2i(edge_dir_variant))
	return anchor_grid + offset


func _get_height_edge_base_y(tile_data, edge_dirs: Array) -> float:
	if tile_data == null:
		return 0.0
	var current_height: int = int(tile_data.height_level)
	var lower_height: int = maxi(current_height - 1, 0)
	var grid_pos: Vector2i = tile_data.grid_position
	for edge_dir_variant in edge_dirs:
		var edge_dir := Vector2i(edge_dir_variant)
		var neighbor = _render_tile_by_grid.get(grid_pos + edge_dir, null)
		var neighbor_height: int = int(neighbor.height_level) if neighbor != null else 0
		lower_height = mini(lower_height, neighbor_height)
	return float(maxi(lower_height, 0)) * _get_3d_height_step()


func _get_height_edge_asset_y_offset(visual_type_id: String) -> float:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if mapped_entry.is_empty():
		return 0.0
	return float(mapped_entry.get("y_offset", 0.0))


func _get_normalized_model_height(model_instance: Node3D) -> float:
	if model_instance == null:
		return 1.0
	var bounds: Dictionary = _get_local_visual_bounds(model_instance)
	if not bool(bounds.get("valid", false)):
		return 1.0
	var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
	var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
	return maxf(max_value.y - min_value.y, 0.001)


func _collect_lower_height_edge_dirs(tile_data) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if tile_data == null:
		return result
	var grid_pos: Vector2i = tile_data.grid_position
	var my_height: int = int(tile_data.height_level)
	for neighbor_offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor = _render_tile_by_grid.get(grid_pos + neighbor_offset, null)
		var neighbor_height: int = int(neighbor.height_level) if neighbor != null else 0
		if neighbor_height < my_height:
			result.append(neighbor_offset)
	return result


func _get_height_edge_visual_type_id(edge_type: String, edge_dir: Vector2i) -> String:
	var suffix: String = ""
	match edge_dir:
		Vector2i(1, 0):
			suffix = "se"
		Vector2i(-1, 0):
			suffix = "nw"
		Vector2i(0, 1):
			suffix = "sw"
		Vector2i(0, -1):
			suffix = "ne"
		_:
			suffix = "se"
	if edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		return "slope_%s" % suffix
	return "cliff_straight_%s" % suffix


func _add_height_edge_texture_visuals(tile_data) -> void:
	if tile_data == null or _map_root == null:
		return
	if _has_3d_asset_mapping():
		return
	if int(tile_data.height_level) <= 0:
		return
	var current_edge_type: String = String(tile_data.edge_type)
	var grid_pos: Vector2i = tile_data.grid_position
	var my_height: int = int(tile_data.height_level)
	var cliff_edge_dirs: Array[Vector2i] = _collect_lower_height_edge_dirs(tile_data)
	if cliff_edge_dirs.is_empty():
		return
	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
		_height_edge_authoring_conflict_count += cliff_edge_dirs.size()
		return
	var is_slope: bool = current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE

	var top_y: float = float(my_height) * _get_3d_height_step()
	var corner_map: Array = [
		[Vector2i(1, 0), Vector2i(0, 1), CLIFF_CORNER_NE],
		[Vector2i(1, 0), Vector2i(0, -1), CLIFF_CORNER_NW],
		[Vector2i(-1, 0), Vector2i(0, 1), CLIFF_CORNER_SE],
		[Vector2i(-1, 0), Vector2i(0, -1), CLIFF_CORNER_SW],
	]
	var edges_consumed_by_corners: Array[Vector2i] = []
	if not is_slope:
		for corner_entry in corner_map:
			var dir_a: Vector2i = corner_entry[0]
			var dir_b: Vector2i = corner_entry[1]
			var corner_texture := corner_entry[2] as Texture2D
			if cliff_edge_dirs.has(dir_a) and cliff_edge_dirs.has(dir_b):
				_add_height_edge_texture_card(tile_data, top_y, corner_texture, "Corner_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, dir_a.x + dir_b.x, dir_a.y + dir_b.y], [dir_a, dir_b])
				if not edges_consumed_by_corners.has(dir_a):
					edges_consumed_by_corners.append(dir_a)
				if not edges_consumed_by_corners.has(dir_b):
					edges_consumed_by_corners.append(dir_b)

	var edge_texture_map: Dictionary
	if is_slope:
		edge_texture_map = {
			Vector2i(1, 0): SLOPE_TEXTURE_SE,
			Vector2i(-1, 0): SLOPE_TEXTURE_NW,
			Vector2i(0, 1): SLOPE_TEXTURE_SW,
			Vector2i(0, -1): SLOPE_TEXTURE_NE,
		}
	else:
		edge_texture_map = {
			Vector2i(1, 0): CLIFF_TEXTURE_SE,
			Vector2i(-1, 0): CLIFF_TEXTURE_NW,
			Vector2i(0, 1): CLIFF_TEXTURE_SW,
			Vector2i(0, -1): CLIFF_TEXTURE_NE,
		}

	for edge_dir in cliff_edge_dirs:
		if edges_consumed_by_corners.has(edge_dir):
			continue
		var edge_texture := edge_texture_map.get(edge_dir, null) as Texture2D
		_add_height_edge_texture_card(tile_data, top_y, edge_texture, "Edge_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, edge_dir.x, edge_dir.y], [edge_dir])


func _add_height_edge_texture_card(tile_data, top_y: float, texture: Texture2D, node_name: String, edge_dirs: Array = []) -> void:
	if texture == null:
		return
	var card := _add_texture_card(
		_map_root,
		texture,
		_grid_to_3d_position(_get_height_edge_anchor_grid_position(tile_data, edge_dirs), top_y + 0.018),
		"Height%s" % node_name,
		TEXTURE_CARD_PIXEL_SIZE,
		_get_kenney_anchor_offset(texture),
		Color(1.0, 1.0, 1.0, 1.0)
	)
	if card != null:
		_height_edge_texture_count += 1


func _add_asset_texture_visual(tile_data, top_y: float, visual_type_id: String) -> bool:
	var texture_info: Dictionary = _resolve_asset_texture_info(tile_data, visual_type_id)
	var texture := texture_info.get("texture", null) as Texture2D
	if texture == null or _map_root == null:
		return false
	var visual_root := Node3D.new()
	visual_root.name = "AssetTexture_%s_%d_%d" % [visual_type_id, tile_data.grid_position.x, tile_data.grid_position.y]
	visual_root.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + _get_asset_y_offset(visual_type_id))
	_map_root.add_child(visual_root)
	var pixel_size: float = _get_asset_texture_pixel_size(visual_type_id)
	var sprite := _add_texture_card(
		visual_root,
		texture,
		Vector3.ZERO,
		"Texture",
		pixel_size,
		_get_kenney_anchor_offset(texture, Vector2(texture_info.get("offset", Vector2.ZERO))),
		Color(1.0, 1.0, 1.0, 1.0)
	)
	if sprite == null:
		visual_root.queue_free()
		return false
	_asset_texture_count += 1
	return true


func _resolve_asset_texture_info(tile_data, visual_type_id: String) -> Dictionary:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	var texture: Texture2D = null
	var pos_offset := Vector2.ZERO

	match normalized:
		"wall_straight_se":
			texture = WALL_TEXTURE_NE
		"wall_straight_sw":
			texture = WALL_TEXTURE_SE
		"wall_straight_ne":
			texture = WALL_TEXTURE_NW
		"wall_straight_nw":
			texture = WALL_TEXTURE_SW
		"wall_corner_se":
			texture = WALL_CORNER_NW
		"wall_corner_sw":
			texture = WALL_CORNER_NE
		"wall_corner_ne":
			texture = WALL_CORNER_SW
		"wall_corner_nw":
			texture = WALL_CORNER_SE
		"cliff_straight_se":
			texture = CLIFF_TEXTURE_SE
			pos_offset = Vector2(33.0, 24.0)
		"cliff_straight_sw":
			texture = CLIFF_TEXTURE_SW
			pos_offset = Vector2(33.0, 56.0)
		"cliff_straight_ne":
			texture = CLIFF_TEXTURE_NE
			pos_offset = Vector2(-31.0, 23.0)
		"cliff_straight_nw":
			texture = CLIFF_TEXTURE_NW
			pos_offset = Vector2(-32.0, 56.0)
		"cliff_corner_se":
			texture = CLIFF_CORNER_NE
			pos_offset = Vector2(-64.0, 40.0)
		"cliff_corner_sw":
			texture = CLIFF_CORNER_SE
			pos_offset = Vector2(1.0, 7.0)
		"cliff_corner_ne":
			texture = CLIFF_CORNER_NW
			pos_offset = Vector2(0.0, 73.0)
		"cliff_corner_nw":
			texture = CLIFF_CORNER_SW
			pos_offset = Vector2(65.0, 40.0)
		"slope_se":
			texture = RAMP_TEXTURE_SE
			pos_offset = Vector2(0.0, 32.0)
		"slope_sw":
			texture = RAMP_TEXTURE_SW
			pos_offset = Vector2(0.0, 32.0)
		"slope_ne":
			texture = RAMP_TEXTURE_NE
			pos_offset = Vector2(0.0, 32.0)
		"slope_nw":
			texture = RAMP_TEXTURE_NW
			pos_offset = Vector2(0.0, 32.0)
		"rock_small":
			texture = ROCK_SMALL_TEXTURE
		"rock_large":
			texture = ROCK_LARGE_TEXTURE

	if texture == null:
		texture = _resolve_catalog_object_texture(tile_data, normalized)
	return {
		"texture": texture,
		"offset": pos_offset,
	}


func _resolve_tile_texture(tile_data) -> Texture2D:
	if tile_data == null:
		return TILE_TEXTURE
	var tile_catalog = _get_tile_catalog()
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	if tile_catalog != null and not type_id.is_empty():
		var is_object_layer_type: bool = false
		if tile_catalog.has_method("is_object_layer_type"):
			is_object_layer_type = bool(tile_catalog.call("is_object_layer_type", type_id))
		if not is_object_layer_type:
			var type_texture := tile_catalog.get_texture(type_id) as Texture2D
			if type_texture != null:
				return type_texture
	return TILE_TEXTURE


func _resolve_catalog_object_texture(tile_data, visual_type_id: String) -> Texture2D:
	var tile_catalog = _get_tile_catalog()
	if tile_catalog == null:
		return null
	var object_type_id: String = visual_type_id
	if object_type_id.is_empty() and tile_data != null:
		object_type_id = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	if object_type_id.is_empty() and tile_data != null:
		object_type_id = String(tile_data.type_id) if tile_data.type_id is String else ""
	if object_type_id.is_empty():
		return null
	return tile_catalog.get_texture(object_type_id) as Texture2D


func _add_texture_card(parent: Node3D, texture: Texture2D, local_position: Vector3, node_name: String, pixel_size: float, pixel_offset: Vector2 = Vector2.ZERO, modulate: Color = Color(1.0, 1.0, 1.0, 1.0)) -> Sprite3D:
	if parent == null or texture == null:
		return null
	var sprite := Sprite3D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.centered = true
	sprite.pixel_size = pixel_size
	sprite.offset = pixel_offset
	sprite.modulate = modulate
	sprite.shaded = false
	sprite.double_sided = true
	sprite.transparent = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.rotation_degrees = _get_fixed_texture_card_rotation_degrees()
	sprite.position = local_position
	parent.add_child(sprite)
	return sprite


func _get_fixed_texture_card_rotation_degrees() -> Vector3:
	var elevation_degrees: float = rad_to_deg(atan2(sin(deg_to_rad(_camera_pitch_degrees)) * 1.18, 1.08))
	return Vector3(-elevation_degrees, FIXED_CARD_YAW_DEGREES, 0.0)


func _get_kenney_anchor_offset(texture: Texture2D, additional_offset: Vector2 = Vector2.ZERO) -> Vector2:
	if texture == null:
		return additional_offset
	return (texture.get_size() * 0.5) - KENNEY_DIAMOND_CENTER + additional_offset


func _add_asset_model_visual(tile_data, top_y: float, visual_type_id: String, apply_tile_rotation: bool = false) -> bool:
	var model_scene := _get_asset_model_scene(visual_type_id)
	if model_scene == null or _map_root == null:
		return false
	var model_instance := model_scene.instantiate() as Node3D
	if model_instance == null:
		return false
	_normalize_asset_model_instance(model_instance)

	var visual_root := Node3D.new()
	visual_root.name = "Asset_%s_%d_%d" % [visual_type_id, tile_data.grid_position.x, tile_data.grid_position.y]
	visual_root.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + _get_asset_y_offset(visual_type_id)) + _get_asset_position_offset(visual_type_id)
	visual_root.rotation_degrees.y = _get_asset_rotation_y(visual_type_id)
	if apply_tile_rotation:
		visual_root.rotation_degrees.y += _get_tile_object_rotation_degrees(tile_data)
	visual_root.scale = Vector3.ONE * _get_asset_model_scale(visual_type_id)
	visual_root.add_child(model_instance)
	_map_root.add_child(visual_root)
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if _is_space_station_model_entry(mapped_entry):
		_space_station_model_count += 1
		_space_station_textured_surface_count += _apply_space_station_colormap_recursive(model_instance)
	if not _has_model_mapping_for_type(visual_type_id):
		_apply_map_asset_material_override(model_instance, visual_type_id)
	_asset_model_count += 1
	_register_nature_prop_visual(tile_data, visual_type_id, visual_root)
	return true


func _get_tile_object_rotation_degrees(tile_data) -> float:
	if tile_data == null:
		return 0.0
	return fposmod(float(tile_data.object_rotation_degrees), 360.0)


func _register_nature_prop_visual(tile_data, visual_type_id: String, visual_root: Node3D) -> void:
	if tile_data == null:
		return
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if not _is_nature_kit_model_entry(mapped_entry):
		return
	var prop_role: String = String(mapped_entry.get("prop_role", "nature_prop")).strip_edges()
	if prop_role.is_empty():
		prop_role = "nature_prop"
	_nature_prop_model_count += 1
	_nature_prop_role_counts[prop_role] = int(_nature_prop_role_counts.get(prop_role, 0)) + 1
	var visual_scale: Vector3 = visual_root.scale if visual_root != null else Vector3.ZERO
	var surface_y: float = float(tile_data.height_level) * _get_3d_height_step()
	_nature_prop_visual_entries.append({
		"node_name": String(visual_root.name) if visual_root != null else "",
		"visual_type_id": visual_type_id,
		"object_type_id": String(tile_data.object_type_id),
		"type_id": String(tile_data.type_id),
		"grid_position": tile_data.grid_position,
		"height_level": int(tile_data.height_level),
		"object_height": int(tile_data.object_height),
		"walkable": bool(tile_data.walkable),
		"blocks_los": bool(tile_data.blocks_los),
		"cover_value": int(tile_data.cover_value),
		"model_path": String(mapped_entry.get("model_path", "")),
		"source_id": String(mapped_entry.get("source_id", "")),
		"prop_role": prop_role,
		"gameplay_role": String(mapped_entry.get("gameplay_role", "")),
		"scale": visual_scale.x,
		"y_offset": _get_asset_y_offset(visual_type_id),
		"surface_y": surface_y,
		"world_y": visual_root.position.y if visual_root != null else surface_y,
		"position_offset": _get_asset_position_offset(visual_type_id),
	})


func _normalize_asset_model_instance(model_instance: Node3D) -> void:
	# Kenney GLBs carry the pack's 2x1.5 authoring offset on the first model child.
	model_instance.position = Vector3.ZERO
	for child in model_instance.get_children():
		var anchor_child := child as Node3D
		if anchor_child == null:
			continue
		var child_position: Vector3 = anchor_child.position
		var has_authoring_x: bool = absf(absf(child_position.x) - KENNEY_AUTHORING_OFFSET_X) <= KENNEY_OFFSET_EPSILON
		var has_authoring_z: bool = absf(absf(child_position.z) - KENNEY_AUTHORING_OFFSET_Z) <= KENNEY_OFFSET_EPSILON
		if has_authoring_x and has_authoring_z:
			anchor_child.position = Vector3.ZERO
	var bounds: Dictionary = _get_local_visual_bounds(model_instance)
	if bool(bounds.get("valid", false)):
		var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
		var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
		var center: Vector3 = (min_value + max_value) * 0.5
		model_instance.position = Vector3(-center.x, -min_value.y, -center.z)


func _get_local_visual_bounds(node: Node3D) -> Dictionary:
	var bounds: Dictionary = {
		"valid": false,
		"min": Vector3.ZERO,
		"max": Vector3.ZERO,
	}
	_accumulate_local_visual_bounds(node, Transform3D.IDENTITY, bounds)
	return bounds


func _accumulate_local_visual_bounds(node: Node, parent_transform: Transform3D, bounds: Dictionary) -> void:
	var current_transform := parent_transform
	var node_3d := node as Node3D
	if node_3d != null:
		current_transform = parent_transform * node_3d.transform
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		_merge_transformed_aabb(bounds, current_transform, mesh_instance.get_aabb())
	for child in node.get_children():
		_accumulate_local_visual_bounds(child, current_transform, bounds)


func _merge_transformed_aabb(bounds: Dictionary, source_transform: Transform3D, aabb: AABB) -> void:
	var corners: Array[Vector3] = [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.position + aabb.size,
	]
	for corner in corners:
		var transformed_corner: Vector3 = source_transform * corner
		if not bool(bounds.get("valid", false)):
			bounds["valid"] = true
			bounds["min"] = transformed_corner
			bounds["max"] = transformed_corner
			continue
		var min_value: Vector3 = Vector3(bounds.get("min", Vector3.ZERO))
		var max_value: Vector3 = Vector3(bounds.get("max", Vector3.ZERO))
		bounds["min"] = Vector3(
			minf(min_value.x, transformed_corner.x),
			minf(min_value.y, transformed_corner.y),
			minf(min_value.z, transformed_corner.z)
		)
		bounds["max"] = Vector3(
			maxf(max_value.x, transformed_corner.x),
			maxf(max_value.y, transformed_corner.y),
			maxf(max_value.z, transformed_corner.z)
		)


func _apply_map_asset_material_override(model_instance: Node3D, visual_type_id: String) -> void:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	var override_color: Color = Color.TRANSPARENT
	if normalized.begins_with("rock_") or normalized.begins_with("cliff_"):
		override_color = Color(0.46, 0.45, 0.42, 1.0)
	elif normalized.begins_with("wall_"):
		override_color = Color(0.62, 0.65, 0.67, 1.0)
	elif normalized.begins_with("slope_"):
		override_color = Color(0.50, 0.52, 0.48, 1.0)
	if override_color == Color.TRANSPARENT:
		return
	_apply_material_override_recursive(model_instance, _make_material(override_color))


func _apply_material_override_recursive(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_override_recursive(child, material)


func _apply_space_station_colormap_recursive(node: Node) -> int:
	var applied_surface_count: int = 0
	var mesh_instance := node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		var material := _make_space_station_colormap_material()
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			mesh_instance.set_surface_override_material(surface_index, material)
			applied_surface_count += 1
	for child in node.get_children():
		applied_surface_count += _apply_space_station_colormap_recursive(child)
	return applied_surface_count


func _rebuild_marker_visuals() -> void:
	_clear_children(_marker_root)
	_marker_count = 0
	_compass_marker_count = 0
	if _terrain_map_data == null or _marker_root == null:
		return
	for marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
		var marker_record: Dictionary = Dictionary(_terrain_map_data.call("get_marker_record", marker_id))
		var world_position: Vector2 = Vector2(marker_record.get("position", _terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)))
		var color: Color = Color(marker_record.get("color", Color(0.9, 0.9, 0.9, 1.0)))
		var compass_letter: String = _get_compass_marker_letter(marker_id, marker_record)
		if not compass_letter.is_empty():
			var compass_font_size: int = 24 if compass_letter.length() > 1 else 30
			_add_label3d(_marker_root, compass_letter, _world_to_3d_position(world_position, 0.62), "CompassMarker_%s" % String(marker_id), Color(0.98, 0.96, 0.9, 1.0), compass_font_size)
			_marker_count += 1
			_compass_marker_count += 1
			continue
		var marker := MeshInstance3D.new()
		marker.name = "Marker_%s" % String(marker_id)
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.34
		mesh.bottom_radius = 0.34
		mesh.height = 0.08
		mesh.radial_segments = 4
		marker.mesh = mesh
		marker.material_override = _make_material(Color(color.r, color.g, color.b, 0.92))
		marker.position = _world_to_surface_3d_position(world_position, 0.22)
		marker.rotation_degrees.y = 45.0
		_marker_root.add_child(marker)
		_marker_count += 1


func _get_compass_marker_letter(marker_id: String, marker_record: Dictionary = {}) -> String:
	var marker_name: String = String(marker_record.get("name", "")).strip_edges()
	var normalized_marker_name: String = marker_name.to_upper()
	match marker_id.strip_edges().to_lower():
		"corner_north":
			return marker_name if ["N", "NORD", "NORTH"].has(normalized_marker_name) else "N"
		"corner_east":
			return marker_name if ["E", "OST", "EAST"].has(normalized_marker_name) else "E"
		"corner_south":
			return marker_name if ["S", "SUED", "SUD", "SOUTH"].has(normalized_marker_name) else "S"
		"corner_west":
			return marker_name if ["W", "WEST"].has(normalized_marker_name) else "W"
	return marker_name if ["N", "E", "S", "W", "NORD", "OST", "SUED", "SUD", "WEST"].has(normalized_marker_name) and marker_id.begins_with("compass_") else ""


func _rebuild_patrol_visuals() -> void:
	_clear_children(_patrol_root)
	_patrol_segment_count = 0
	_patrol_preview_segment_count = 0
	if _terrain_map_data == null or _patrol_root == null:
		return
	var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
	for spawn_id_variant in patrol_paths.keys():
		var path_id: String = String(spawn_id_variant).strip_edges()
		var path_points: Array = Array(_terrain_map_data.call("get_patrol_path", path_id))
		if path_points.size() < 2:
			continue
		var is_preview: bool = path_id == _editor_patrol_preview_path_id
		var color := Color(1.0, 0.82, 0.18, 0.96) if is_preview else Color(0.25, 0.92, 0.4, 0.82)
		for index in range(1, path_points.size()):
			_add_line3d(_patrol_root, _world_to_surface_3d_position(Vector2(path_points[index - 1]), 0.28), _world_to_surface_3d_position(Vector2(path_points[index]), 0.28), color, "Patrol_%s_%d" % [path_id, index])
			_patrol_segment_count += 1
			if is_preview:
				_patrol_preview_segment_count += 1


func _rebuild_selection_visuals() -> void:
	_clear_children(_selection_root)
	if _terrain_map_data == null or _selection_root == null:
		return
	for grid_variant in _selected_grid_positions:
		var grid_position := Vector2i(grid_variant)
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			continue
		var cell_size: float = _get_3d_cell_size()
		var mesh := _make_box_mesh(Vector3(cell_size * 0.98, 0.045, cell_size * 0.98))
		var selection := MeshInstance3D.new()
		selection.name = "Selection_%d_%d" % [grid_position.x, grid_position.y]
		selection.mesh = mesh
		selection.material_override = _make_editor_selection_material(false)
		var selection_y: float = (float(tile_data.height_level) * _get_3d_height_step()) + TILE_SELECTION_SURFACE_Y_OFFSET
		selection.position = _grid_to_3d_position(Vector2(grid_position), selection_y)
		_selection_root.add_child(selection)
		_add_selection_border(grid_position, selection_y + 0.035)


func _add_selection_border(grid_position: Vector2i, y_position: float) -> void:
	if _selection_root == null:
		return
	var material := _make_editor_selection_material(true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var cell_size: float = _get_3d_cell_size()
	var half_size: float = cell_size * 0.5
	var line_width: float = maxf(cell_size * TILE_SELECTION_BORDER_WIDTH_FACTOR, 0.026)
	var center: Vector3 = _grid_to_3d_position(Vector2(grid_position), y_position)
	var nw := center + Vector3(-half_size, 0.0, -half_size)
	var ne := center + Vector3(half_size, 0.0, -half_size)
	var se := center + Vector3(half_size, 0.0, half_size)
	var sw := center + Vector3(-half_size, 0.0, half_size)
	_add_grid_line_quad(mesh, nw, ne, line_width)
	_add_grid_line_quad(mesh, ne, se, line_width)
	_add_grid_line_quad(mesh, se, sw, line_width)
	_add_grid_line_quad(mesh, sw, nw, line_width)
	mesh.surface_end()
	var border := MeshInstance3D.new()
	border.name = "SelectionBorder_%d_%d" % [grid_position.x, grid_position.y]
	border.mesh = mesh
	_selection_root.add_child(border)


func _normalize_fog_of_war_visual_state(fog_of_war_state: Dictionary) -> Dictionary:
	var raw_mode: String = String(fog_of_war_state.get("mode", fog_of_war_state.get("fog_of_war_mode", FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF))).strip_edges()
	var mode: String = FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF if raw_mode.is_empty() else String(FOG_OF_WAR_MODE_CONTRACT_SCRIPT.call("normalize_mode", raw_mode))
	var terrain_knowledge: Dictionary = Dictionary(fog_of_war_state.get("terrain_knowledge", {}))
	var current_visibility: Dictionary = Dictionary(fog_of_war_state.get("current_visibility", {}))
	return {
		"mode": mode,
		"team_id": String(fog_of_war_state.get("team_id", "")).strip_edges(),
		"terrain_knowledge": {
			"visible_tile_ids": _normalize_fow_string_array(terrain_knowledge.get("visible_tile_ids", fog_of_war_state.get("visible_tile_ids", []))),
			"explored_tile_ids": _normalize_fow_string_array(terrain_knowledge.get("explored_tile_ids", fog_of_war_state.get("explored_tile_ids", []))),
		},
		"current_visibility": {
			"visible_target_ids": _normalize_fow_string_array(current_visibility.get("visible_target_ids", fog_of_war_state.get("visible_target_ids", []))),
			"visible_event_ids": _normalize_fow_string_array(current_visibility.get("visible_event_ids", fog_of_war_state.get("visible_event_ids", []))),
		},
		"last_known_contacts": _normalize_fow_last_known_contacts(fog_of_war_state.get("last_known_contacts", [])),
	}


func _build_fog_of_war_visual_signature(fog_of_war_state: Dictionary) -> String:
	var terrain_knowledge: Dictionary = Dictionary(fog_of_war_state.get("terrain_knowledge", {}))
	var current_visibility: Dictionary = Dictionary(fog_of_war_state.get("current_visibility", {}))
	var parts: PackedStringArray = PackedStringArray([
		String(fog_of_war_state.get("mode", FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF)),
		String(fog_of_war_state.get("team_id", "")),
		_join_fow_string_array(PackedStringArray(terrain_knowledge.get("visible_tile_ids", PackedStringArray()))),
		_join_fow_string_array(PackedStringArray(terrain_knowledge.get("explored_tile_ids", PackedStringArray()))),
		_join_fow_string_array(PackedStringArray(current_visibility.get("visible_target_ids", PackedStringArray()))),
		_join_fow_string_array(PackedStringArray(current_visibility.get("visible_event_ids", PackedStringArray()))),
	])
	for contact_variant in Array(fog_of_war_state.get("last_known_contacts", [])):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var contact_part: String = "%s:%s:%d" % [
			String(contact.get("target_id", "")),
			_format_fow_position(contact.get("last_known_position", null)),
			int(contact.get("last_seen_tick", 0)),
		]
		parts.append(contact_part)
	return "|".join(parts)


func _apply_fog_of_war_visual_state(fog_of_war_state: Dictionary) -> void:
	_fog_of_war_state = fog_of_war_state.duplicate(true)
	_fog_of_war_mode = String(fog_of_war_state.get("mode", FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF))
	_fog_of_war_team_id = String(fog_of_war_state.get("team_id", "")).strip_edges()
	var terrain_knowledge: Dictionary = Dictionary(fog_of_war_state.get("terrain_knowledge", {}))
	var current_visibility: Dictionary = Dictionary(fog_of_war_state.get("current_visibility", {}))
	_fow_visible_tile_ids = _build_fow_lookup(PackedStringArray(terrain_knowledge.get("visible_tile_ids", PackedStringArray())))
	_fow_explored_tile_ids = _build_fow_lookup(PackedStringArray(terrain_knowledge.get("explored_tile_ids", PackedStringArray())))
	_fow_visible_tile_grids = _build_fow_grid_lookup(PackedStringArray(terrain_knowledge.get("visible_tile_ids", PackedStringArray())))
	_fow_explored_tile_grids = _build_fow_grid_lookup(PackedStringArray(terrain_knowledge.get("explored_tile_ids", PackedStringArray())))
	_fow_visible_target_ids = _build_fow_lookup(PackedStringArray(current_visibility.get("visible_target_ids", PackedStringArray())))
	_fow_visible_event_ids = _build_fow_lookup(PackedStringArray(current_visibility.get("visible_event_ids", PackedStringArray())))
	_fow_last_known_contacts = Array(fog_of_war_state.get("last_known_contacts", [])).duplicate(true)


func _normalize_fow_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		result = PackedStringArray(value)
	elif value is Array:
		for entry_variant in Array(value):
			var entry: String = String(entry_variant).strip_edges()
			if not entry.is_empty():
				result.append(entry)
	result.sort()
	return result


func _normalize_fow_last_known_contacts(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for contact_variant in Array(value):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(contact_variant)
		var target_id: String = String(source.get("target_id", source.get("unit_id", ""))).strip_edges()
		if target_id.is_empty():
			continue
		var contact: Dictionary = {
			"target_id": target_id,
			"unit_id": target_id,
			"team_id": String(source.get("team_id", "")).strip_edges(),
			"last_seen_tick": maxi(int(source.get("last_seen_tick", 0)), 0),
			"detection_state": String(source.get("detection_state", "lost")).strip_edges().to_lower(),
			"fow_last_known": true,
		}
		var position: Variant = _coerce_fow_position(source.get("last_known_position", source.get("position", null)))
		if position != null:
			contact["last_known_position"] = position
		result.append(contact)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("target_id", "")) < String(b.get("target_id", ""))
	)
	return result


func _coerce_fow_position(value: Variant) -> Variant:
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_VECTOR2I:
		var grid_position := Vector2i(value)
		return Vector2(grid_position.x, grid_position.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null


func _build_fow_lookup(ids: PackedStringArray) -> Dictionary:
	var lookup: Dictionary = {}
	for id in ids:
		var normalized_id: String = String(id).strip_edges()
		if not normalized_id.is_empty():
			lookup[normalized_id] = true
	return lookup


func _build_fow_grid_lookup(ids: PackedStringArray) -> Dictionary:
	var lookup: Dictionary = {}
	for id in ids:
		var grid_variant: Variant = _try_parse_fow_tile_grid(String(id))
		if typeof(grid_variant) == TYPE_VECTOR2I:
			lookup[Vector2i(grid_variant)] = true
	return lookup


func _try_parse_fow_tile_grid(tile_id: String) -> Variant:
	var normalized_id: String = tile_id.strip_edges()
	if not normalized_id.begins_with("tile_"):
		return null
	var parts: PackedStringArray = normalized_id.substr(5).split("_")
	if parts.size() != 2:
		return null
	if not String(parts[0]).is_valid_int() or not String(parts[1]).is_valid_int():
		return null
	return Vector2i(int(parts[0]), int(parts[1]))


func _join_fow_string_array(ids: PackedStringArray) -> String:
	return ",".join(ids)


func _format_fow_position(value: Variant) -> String:
	if typeof(value) != TYPE_VECTOR2:
		return ""
	var position := Vector2(value)
	return "%.2f,%.2f" % [position.x, position.y]


func _is_fog_of_war_visual_filter_active() -> bool:
	return _fog_of_war_mode != FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_OFF


func _reset_fow_overlay_counters(preserve_rebuild_count: bool = true) -> void:
	_fow_overlay_tile_count = 0
	_fow_visible_tile_count = 0
	_fow_known_dim_tile_count = 0
	_fow_explored_tile_count = 0
	_fow_unknown_tile_count = 0
	_fow_tile_total_count = 0
	_fow_hidden_order_visual_count = 0
	_fow_hidden_contact_count = 0
	_fow_hidden_unit_proxy_count = 0
	_fow_allowed_contact_count = 0
	if not preserve_rebuild_count:
		_fow_overlay_rebuild_count = 0


func _rebuild_fog_of_war_visuals() -> void:
	_clear_children(_fow_root)
	_fow_overlay_tile_count = 0
	_fow_visible_tile_count = 0
	_fow_known_dim_tile_count = 0
	_fow_explored_tile_count = 0
	_fow_unknown_tile_count = 0
	_fow_tile_total_count = 0
	if _fow_root == null or _terrain_map_data == null:
		return
	var tiles: Array = Array(_terrain_map_data.call("get_tiles"))
	_fow_tile_total_count = tiles.size()
	if not _is_fog_of_war_visual_filter_active():
		_fow_visible_tile_count = tiles.size()
		return

	var known_dim_transforms: Array = []
	var explored_transforms: Array = []
	var unknown_transforms: Array = []
	var blackout_y: float = _get_fow_blackout_cover_y(tiles)
	for tile_data in tiles:
		if tile_data == null:
			continue
		var tile_state: String = _get_fow_tile_state(tile_data)
		match tile_state:
			FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE:
				_fow_visible_tile_count += 1
			FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_KNOWN:
				_fow_known_dim_tile_count += 1
				known_dim_transforms.append(_get_fow_surface_overlay_transform(tile_data))
			FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_EXPLORED:
				_fow_explored_tile_count += 1
				explored_transforms.append(_get_fow_surface_overlay_transform(tile_data))
			_:
				_fow_unknown_tile_count += 1
				unknown_transforms.append(_get_fow_blackout_overlay_transform(tile_data, blackout_y))
	_fow_overlay_tile_count = known_dim_transforms.size() + explored_transforms.size() + unknown_transforms.size()
	_add_fow_overlay_multimesh("FoWKnownDimOverlay", known_dim_transforms, FOW_KNOWN_DIM_COLOR, true)
	_add_fow_overlay_multimesh("FoWExploredOverlay", explored_transforms, FOW_EXPLORED_DIM_COLOR, true)
	_add_fow_overlay_multimesh("FoWUnknownBlackoutOverlay", unknown_transforms, FOW_UNKNOWN_BLACK_COLOR, false)
	_fow_overlay_rebuild_count += 1


func _get_fow_tile_state(tile_data) -> String:
	if not _is_fog_of_war_visual_filter_active():
		return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE
	var grid_position: Vector2i = Vector2i(tile_data.grid_position)
	if _fow_visible_tile_grids.has(grid_position):
		return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE
	var tile_id: String = _get_explicit_tile_id_for_fow(tile_data)
	if not tile_id.is_empty() and _fow_visible_tile_ids.has(tile_id):
		return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_VISIBLE
	if _fog_of_war_mode == FOG_OF_WAR_MODE_CONTRACT_SCRIPT.MODE_KNOWN_TERRAIN:
		return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_KNOWN
	if _fow_explored_tile_grids.has(grid_position):
		return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_EXPLORED
	if not tile_id.is_empty() and _fow_explored_tile_ids.has(tile_id):
		return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_EXPLORED
	return FOG_OF_WAR_MODE_CONTRACT_SCRIPT.TERRAIN_STATE_UNKNOWN


func _get_explicit_tile_id_for_fow(tile_data) -> String:
	if tile_data == null:
		return ""
	return String(tile_data.tile_id).strip_edges()


func _get_fow_surface_overlay_transform(tile_data) -> Transform3D:
	var grid_position: Vector2 = Vector2(tile_data.grid_position)
	var top_y: float = (float(tile_data.height_level) * _get_3d_height_step()) + FOW_OVERLAY_SURFACE_Y_OFFSET
	return Transform3D(Basis(), _grid_to_3d_position(grid_position, top_y))


func _get_fow_blackout_overlay_transform(tile_data, blackout_y: float) -> Transform3D:
	return Transform3D(Basis(), _grid_to_3d_position(Vector2(tile_data.grid_position), blackout_y))


func _get_fow_blackout_cover_y(tiles: Array) -> float:
	var max_y: float = 0.0
	for tile_data in tiles:
		if tile_data == null:
			continue
		var tile_top_y: float = float(tile_data.height_level) * _get_3d_height_step()
		var object_top_y: float = tile_top_y + (maxf(float(tile_data.object_height), 0.0) * OBJECT_HEIGHT_STEP)
		max_y = maxf(max_y, object_top_y)
	return max_y + FOW_BLACKOUT_COVER_Y_OFFSET


func _add_fow_overlay_multimesh(node_name: String, transforms: Array, color: Color, transparent: bool) -> void:
	if _fow_root == null or transforms.is_empty():
		return
	var cell_size: float = _get_3d_cell_size()
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = _make_box_mesh(Vector3(cell_size * 0.99, FOW_OVERLAY_HEIGHT, cell_size * 0.99))
	multi_mesh.instance_count = transforms.size()
	for index in range(transforms.size()):
		var instance_transform: Transform3D = transforms[index]
		multi_mesh.set_instance_transform(index, instance_transform)
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multi_mesh
	instance.material_override = _make_material(color, transparent)
	_fow_root.add_child(instance)


func _fow_is_target_currently_visible(target_id: String) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	var normalized_id: String = target_id.strip_edges()
	return not normalized_id.is_empty() and _fow_visible_target_ids.has(normalized_id)


func _fow_is_event_currently_visible(event_id: String) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	var normalized_id: String = event_id.strip_edges()
	return not normalized_id.is_empty() and _fow_visible_event_ids.has(normalized_id)


func _fow_is_world_position_currently_visible(position_variant: Variant) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if typeof(position_variant) != TYPE_VECTOR2:
		return false
	if _terrain_map_data == null or not _terrain_map_data.has_method("get_tile_at_grid"):
		return false
	var grid_position: Vector2i = _world_to_grid_position(Vector2(position_variant))
	if _fow_visible_tile_grids.has(grid_position):
		return true
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return false
	var tile_id: String = _get_explicit_tile_id_for_fow(tile_data)
	return not tile_id.is_empty() and _fow_visible_tile_ids.has(tile_id)


func _fow_allows_unit_proxy(unit: Node) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if unit == null:
		return false
	var unit_team_id: String = _get_unit_team_id(unit)
	if not _fog_of_war_team_id.is_empty() and unit_team_id == _fog_of_war_team_id:
		return true
	var unit_id: String = _get_unit_id(unit)
	if _fow_is_target_currently_visible(unit_id):
		return true
	if unit is Node2D:
		return _fow_is_world_position_currently_visible((unit as Node2D).global_position)
	return false


func _fow_allows_enemy_security_visual(security_state: Dictionary) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if _fow_is_world_position_currently_visible(security_state.get("anchor_position", null)):
		return true
	if _fow_any_unit_id_visible(PackedStringArray(security_state.get("watched_unit_ids", PackedStringArray()))):
		return true
	for assignment_variant in Array(security_state.get("member_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		if _fow_is_target_currently_visible(String(assignment.get("unit_id", assignment.get("member_id", "")))):
			return true
	return false


func _fow_allows_enemy_tactics_visual(tactics_state: Dictionary) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if _fow_is_world_position_currently_visible(tactics_state.get("anchor_position", null)):
		return true
	if _fow_any_unit_id_visible(PackedStringArray(tactics_state.get("moving_unit_ids", PackedStringArray()))):
		return true
	if _fow_any_unit_id_visible(PackedStringArray(tactics_state.get("covering_unit_ids", PackedStringArray()))):
		return true
	for position_variant in Dictionary(tactics_state.get("target_positions_by_unit_id", {})).values():
		if _fow_is_world_position_currently_visible(position_variant):
			return true
	return false


func _fow_allows_fire_event_visual(fire_event: Dictionary) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if _fow_is_event_currently_visible(String(fire_event.get("event_id", ""))):
		return true
	if _fow_is_target_currently_visible(String(fire_event.get("attacker_unit_id", ""))):
		return true
	if _fow_is_target_currently_visible(String(fire_event.get("target_unit_id", ""))):
		return true
	return _fow_is_world_position_currently_visible(fire_event.get("attacker_position", null)) or _fow_is_world_position_currently_visible(fire_event.get("target_position", null))


func _fow_allows_feedback_bubble_visual(feedback_bubble: Dictionary) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if _fow_is_target_currently_visible(String(feedback_bubble.get("unit_id", ""))):
		return true
	return _fow_is_world_position_currently_visible(feedback_bubble.get("anchor_position", null))


func _fow_allows_tactical_communication_event_visual(communication_event: Dictionary) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if _fow_is_event_currently_visible(String(communication_event.get("event_id", ""))):
		return true
	if _fow_is_target_currently_visible(String(communication_event.get("unit_id", ""))):
		return true
	if _fow_is_world_position_currently_visible(communication_event.get("anchor_position", null)):
		return true
	return _fow_is_world_position_currently_visible(communication_event.get("target_position", null))


func _fow_allows_contact_visual(contact: Dictionary) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	if bool(contact.get("fow_last_known", false)):
		return true
	var target_id: String = String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges()
	if _fow_is_target_currently_visible(target_id):
		return true
	return _fow_is_world_position_currently_visible(contact.get("last_known_position", contact.get("position", null)))


func _fow_any_unit_id_visible(unit_ids: PackedStringArray) -> bool:
	for unit_id in unit_ids:
		if _fow_is_target_currently_visible(String(unit_id)):
			return true
	return false


func _get_fow_dynamic_hidden_count() -> int:
	return _fow_hidden_order_visual_count + _fow_hidden_contact_count + _fow_hidden_unit_proxy_count + _fow_hidden_air_visual_count


func _get_contact_visual_entries() -> Array:
	return _contact_visual_entries.duplicate(true)


func _normalize_mission_drop_visual_payload(drop_payload: Dictionary) -> Dictionary:
	var payload: Dictionary = drop_payload.duplicate(true)
	if payload.has("visible") and not payload.has("dropship_visible"):
		payload["dropship_visible"] = bool(payload.get("visible", false))
	if payload.has("position") and not payload.has("dropship_position"):
		payload["dropship_position"] = payload.get("position")
	if payload.has("target_position") and not payload.has("dropship_target_position"):
		payload["dropship_target_position"] = payload.get("target_position")
	if payload.has("has_lz") and not payload.has("has_lz_position"):
		payload["has_lz_position"] = bool(payload.get("has_lz", false))
	if not payload.has("show_lz_marker"):
		payload["show_lz_marker"] = bool(payload.get("has_lz_position", false))
	if not payload.has("air_layer"):
		payload["air_layer"] = AIR_LAYER_ID
	if not payload.has("team_id"):
		payload["team_id"] = AIR_LAYER_DEFAULT_TEAM_ID
	payload["flight_altitude_clearance"] = maxf(float(payload.get("flight_altitude_clearance", AIR_LAYER_DEFAULT_CLEARANCE)), AIR_LAYER_MIN_CLEARANCE)
	payload["terrain_height_independent"] = true
	payload["reveals_unknown_terrain"] = false
	payload["fow_policy"] = "friendly_air_visible_lz_requires_visible_tile"
	payload["dropship_visuals"] = _normalize_dropship_visual_entries(payload)
	if not Array(payload.get("dropship_visuals", [])).is_empty():
		payload["dropship_visible"] = true
	return payload


func _normalize_dropship_visual_entries(payload: Dictionary) -> Array:
	var entries: Array = []
	for entry_variant in Array(payload.get("dropship_visuals", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		if entry.has("visible") and not entry.has("dropship_visible"):
			entry["dropship_visible"] = bool(entry.get("visible", false))
		if entry.has("position") and not entry.has("dropship_position"):
			entry["dropship_position"] = entry.get("position")
		if entry.has("target_position") and not entry.has("dropship_target_position"):
			entry["dropship_target_position"] = entry.get("target_position")
		if entry.has("has_lz") and not entry.has("has_lz_position"):
			entry["has_lz_position"] = bool(entry.get("has_lz", false))
		if not entry.has("show_lz_marker"):
			entry["show_lz_marker"] = bool(entry.get("has_lz_position", false))
		if not entry.has("show_approach_vector"):
			entry["show_approach_vector"] = bool(entry.get("show_lz_marker", true))
		if not entry.has("team_id"):
			entry["team_id"] = String(payload.get("team_id", AIR_LAYER_DEFAULT_TEAM_ID))
		if not entry.has("air_layer"):
			entry["air_layer"] = String(payload.get("air_layer", AIR_LAYER_ID))
		if not entry.has("flight_altitude_clearance"):
			entry["flight_altitude_clearance"] = float(payload.get("flight_altitude_clearance", AIR_LAYER_DEFAULT_CLEARANCE))
		entry["flight_altitude_clearance"] = maxf(float(entry.get("flight_altitude_clearance", AIR_LAYER_DEFAULT_CLEARANCE)), AIR_LAYER_MIN_CLEARANCE)
		entry["terrain_height_independent"] = true
		var has_line_or_lz: bool = bool(entry.get("has_lz_position", false)) or typeof(entry.get("lz_position", null)) == TYPE_VECTOR2 or typeof(entry.get("dropship_target_position", null)) == TYPE_VECTOR2
		if typeof(entry.get("dropship_position", null)) == TYPE_VECTOR2 and (bool(entry.get("dropship_visible", false)) or has_line_or_lz):
			entries.append(entry)
	if entries.is_empty() and bool(payload.get("dropship_visible", false)) and typeof(payload.get("dropship_position", null)) == TYPE_VECTOR2:
		var fallback_entry: Dictionary = payload.duplicate(true)
		var fallback_id: String = String(fallback_entry.get("craft_id", "mission_dropship")).strip_edges()
		if fallback_id.is_empty():
			fallback_id = "mission_dropship"
		fallback_entry["craft_id"] = fallback_id
		entries.append(fallback_entry)
	return entries


func _build_drop_visual_static_signature(payload: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("lz:%s:%s" % [str(bool(payload.get("has_lz_position", false))), _vector2_signature(payload.get("lz_position", null))])
	var payload_show_lz_marker: bool = bool(payload.get("show_lz_marker", bool(payload.get("has_lz_position", false))))
	parts.append("show_lz:%s" % str(payload_show_lz_marker))
	parts.append("req:%s" % _vector2_signature(payload.get("requested_lz_position", payload.get("target_lz_position", null))))
	parts.append("res:%s" % _vector2_signature(payload.get("resolved_lz_position", payload.get("actual_landing_position", null))))
	var entries: Array = Array(payload.get("dropship_visuals", []))
	for index in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[index])
		parts.append("%s:%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [
			_get_dropship_visual_id(entry, index),
			String(entry.get("state", "")).strip_edges().to_lower(),
			_texture_signature(entry.get("dropship_texture", null)),
			str(bool(entry.get("dropship_visible", false))),
			_vector2_signature(entry.get("approach_origin_position", entry.get("dropship_position", null))),
			_vector2_signature(entry.get("approach_vector_origin_position", entry.get("dropship_position", null))),
			_vector2_signature(entry.get("approach_vector_target_position", entry.get("dropship_target_position", null))),
			str(bool(entry.get("show_lz_marker", bool(entry.get("has_lz_position", false))))),
			str(bool(entry.get("show_approach_vector", true))),
			String(entry.get("approach_vector_shape", "wide_arrow")).strip_edges(),
			String(entry.get("team_id", AIR_LAYER_DEFAULT_TEAM_ID)).strip_edges(),
		])
		parts.append("lz:%s:%s:%s" % [
			_vector2_signature(entry.get("lz_position", null)),
			_vector2_signature(entry.get("dropship_target_position", null)),
			String(entry.get("lz_label", entry.get("lz_name", ""))).strip_edges(),
		])
	return "|".join(parts)


func _vector2_signature(value: Variant) -> String:
	if typeof(value) != TYPE_VECTOR2:
		return "-"
	var vector_value: Vector2 = Vector2(value)
	return "%.2f,%.2f" % [vector_value.x, vector_value.y]


func _texture_signature(value: Variant) -> String:
	var texture := value as Texture2D
	if texture == null:
		return ""
	return texture.resource_path


func _can_update_drop_visual_motion(payload: Dictionary) -> bool:
	if _drop_root == null:
		return false
	if _is_fog_of_war_visual_filter_active():
		return false
	var entries: Array = Array(payload.get("dropship_visuals", []))
	if entries.is_empty():
		return false
	for index in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[index])
		var visual_id: String = _get_dropship_visual_id(entry, index)
		if not bool(entry.get("dropship_visible", false)):
			if not _dropship_approach_lines_by_id.has(visual_id):
				return false
			continue
		if not _dropship_visual_nodes_by_id.has(visual_id):
			return false
		var node := _dropship_visual_nodes_by_id.get(visual_id, null) as Node3D
		if node == null or not is_instance_valid(node):
			return false
	return true


func _update_drop_visual_motion() -> void:
	var entries: Array = Array(_drop_payload.get("dropship_visuals", []))
	for index in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[index])
		var visual_id: String = _get_dropship_visual_id(entry, index)
		if typeof(entry.get("dropship_position", null)) != TYPE_VECTOR2:
			continue
		var world_position: Vector2 = Vector2(entry.get("dropship_position", Vector2.ZERO))
		var node := _dropship_visual_nodes_by_id.get(visual_id, null) as Node3D
		if node != null and is_instance_valid(node):
			var extra_y_offset: float = float(node.get_meta("dropship_extra_y_offset", 0.0))
			node.position = _world_to_air_layer_3d_position_for_payload(entry, world_position, extra_y_offset)
			if String(node.get_meta("dropship_visual_mode", "")).strip_edges() != "texture":
				node.rotation_degrees.y = _get_dropship_rotation_y_for_payload(entry, world_position)
		_update_dropship_approach_line(entry, visual_id, world_position)


func _rebuild_order_visuals() -> void:
	_clear_children(_order_root)
	_area_order_count = 0
	_waypoint_visual_count = 0
	_area_order_tile_marker_count = 0
	_waypoint_tile_marker_count = 0
	_movement_style_visual_count = 0
	_movement_bound_marker_count = 0
	_movement_group_marker_count = 0
	_movement_group_marker_entries.clear()
	_movement_style_entries.clear()
	_fireteam_orientation_visual_count = 0
	_fireteam_orientation_entries.clear()
	_multi_fireteam_plan_visual_count = 0
	_multi_fireteam_plan_entries.clear()
	_enemy_security_visual_count = 0
	_enemy_security_entries.clear()
	_enemy_tactics_visual_count = 0
	_enemy_tactics_entries.clear()
	_friendly_aim_visual_count = 0
	_friendly_aim_entries.clear()
	_friendly_aim_tile_marker_count = 0
	_friendly_aim_blocker_marker_count = 0
	_friendly_aim_los_line_count = 0
	_reset_mission_los_debug_counters()
	_weapon_fire_vfx_visual_count = 0
	_weapon_fire_vfx_entries.clear()
	_feedback_bubble_visual_count = 0
	_feedback_bubble_entries.clear()
	_tactical_communication_event_visual_count = 0
	_tactical_communication_event_entries.clear()
	_fow_hidden_order_visual_count = 0
	if _order_root == null:
		return
	if _order_payload.is_empty():
		_add_area_order_preview_visuals()
		return
	var phase_index: int = int(_order_payload.get("phase_index", 1))
	var anchor_by_fireteam: Dictionary = {}
	var fireteam_anchor_entries: Array = Array(_order_payload.get("fireteam_anchors", []))
	for anchor_variant in fireteam_anchor_entries:
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor_dict: Dictionary = Dictionary(anchor_variant)
		var fireteam_id: String = String(anchor_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or typeof(anchor_dict.get("position", null)) != TYPE_VECTOR2:
			continue
		anchor_by_fireteam[fireteam_id] = Vector2(anchor_dict.get("position", Vector2.ZERO))

	_add_selected_fireteam_unit_markers()
	_add_selected_fireteam_aim_visuals()
	_add_mission_los_debug_visuals()
	_add_fireteam_orientation_visuals(fireteam_anchor_entries)

	for area_variant in Array(_order_payload.get("area_order_dicts", [])):
		if typeof(area_variant) != TYPE_DICTIONARY:
			continue
		_add_area_order_visual(Dictionary(area_variant))
	_add_area_order_preview_visuals()

	for plan_variant in Array(_order_payload.get("plan_dicts", [])):
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		_add_plan_visual(Dictionary(plan_variant), phase_index, anchor_by_fireteam)

	for movement_variant in Array(_order_payload.get("movement_state_dicts", [])):
		if typeof(movement_variant) != TYPE_DICTIONARY:
			continue
		_add_movement_state_visual(Dictionary(movement_variant))

	for multi_plan_variant in Array(_order_payload.get("multi_fireteam_plan_dicts", [])):
		if typeof(multi_plan_variant) != TYPE_DICTIONARY:
			continue
		_add_multi_fireteam_plan_visual(Dictionary(multi_plan_variant))

	for enemy_security_variant in Array(_order_payload.get("enemy_security_dicts", [])):
		if typeof(enemy_security_variant) != TYPE_DICTIONARY:
			continue
		var enemy_security: Dictionary = Dictionary(enemy_security_variant)
		if not _fow_allows_enemy_security_visual(enemy_security):
			_fow_hidden_order_visual_count += 1
			continue
		_add_enemy_security_visual(enemy_security)

	for enemy_tactics_variant in Array(_order_payload.get("enemy_tactics_dicts", [])):
		if typeof(enemy_tactics_variant) != TYPE_DICTIONARY:
			continue
		var enemy_tactics: Dictionary = Dictionary(enemy_tactics_variant)
		if not _fow_allows_enemy_tactics_visual(enemy_tactics):
			_fow_hidden_order_visual_count += 1
			continue
		_add_enemy_tactics_visual(enemy_tactics)

	for fire_event_variant in Array(_order_payload.get("fire_event_dicts", [])):
		if typeof(fire_event_variant) != TYPE_DICTIONARY:
			continue
		var fire_event: Dictionary = Dictionary(fire_event_variant)
		if not _fow_allows_fire_event_visual(fire_event):
			_fow_hidden_order_visual_count += 1
			continue
		_add_weapon_fire_vfx_visual(fire_event)

	for feedback_bubble_variant in _select_feedback_bubbles_for_visuals(Array(_order_payload.get("feedback_bubble_dicts", []))):
		if typeof(feedback_bubble_variant) != TYPE_DICTIONARY:
			continue
		var feedback_bubble: Dictionary = Dictionary(feedback_bubble_variant)
		if not _fow_allows_feedback_bubble_visual(feedback_bubble):
			_fow_hidden_order_visual_count += 1
			continue
		_add_feedback_bubble_visual(feedback_bubble)

	for communication_event_variant in Array(_order_payload.get("tactical_communication_event_dicts", [])):
		if typeof(communication_event_variant) != TYPE_DICTIONARY:
			continue
		var communication_event: Dictionary = Dictionary(communication_event_variant)
		if not _fow_allows_tactical_communication_event_visual(communication_event):
			_fow_hidden_order_visual_count += 1
			continue
		_add_tactical_communication_event_visual(communication_event)


func _select_feedback_bubbles_for_visuals(feedback_bubbles: Array) -> Array:
	var selected_by_anchor: Dictionary = {}
	var ordered_keys: PackedStringArray = []
	for bubble_variant in feedback_bubbles:
		if typeof(bubble_variant) != TYPE_DICTIONARY:
			continue
		var bubble: Dictionary = Dictionary(bubble_variant)
		if not _is_feedback_bubble_visual_candidate(bubble):
			continue
		var anchor_key: String = _build_feedback_bubble_anchor_key(bubble)
		if anchor_key.is_empty():
			anchor_key = "bubble:%d" % ordered_keys.size()
		if not selected_by_anchor.has(anchor_key):
			selected_by_anchor[anchor_key] = bubble
			ordered_keys.append(anchor_key)
			continue
		var previous: Dictionary = Dictionary(selected_by_anchor.get(anchor_key, {}))
		if _get_feedback_bubble_visual_priority(bubble) > _get_feedback_bubble_visual_priority(previous):
			selected_by_anchor[anchor_key] = bubble
	var selected: Array = []
	for anchor_key in ordered_keys:
		selected.append(Dictionary(selected_by_anchor.get(String(anchor_key), {})))
	return selected


func _is_feedback_bubble_visual_candidate(feedback_bubble: Dictionary) -> bool:
	if String(feedback_bubble.get("display_type", "")).strip_edges() != "comic_bubble":
		return false
	if not bool(feedback_bubble.get("visual_only", false)):
		return false
	if String(feedback_bubble.get("anchor_space", "")).strip_edges().to_lower() == "hud":
		return typeof(feedback_bubble.get("hud_anchor_position", null)) == TYPE_VECTOR2
	return typeof(feedback_bubble.get("anchor_position", null)) == TYPE_VECTOR2


func _build_feedback_bubble_anchor_key(feedback_bubble: Dictionary) -> String:
	var anchor_space: String = String(feedback_bubble.get("anchor_space", "")).strip_edges().to_lower()
	var fireteam_id: String = String(feedback_bubble.get("fireteam_id", "")).strip_edges().to_lower()
	if not fireteam_id.is_empty():
		return "%s:ft:%s" % [anchor_space, fireteam_id]
	var unit_id: String = String(feedback_bubble.get("unit_id", "")).strip_edges()
	if not unit_id.is_empty():
		return "%s:unit:%s" % [anchor_space, unit_id]
	if anchor_space == "hud" and typeof(feedback_bubble.get("hud_anchor_position", null)) == TYPE_VECTOR2:
		var hud_anchor_position: Vector2 = Vector2(feedback_bubble.get("hud_anchor_position", Vector2.ZERO))
		return "hud:pos:%d:%d" % [roundi(hud_anchor_position.x / 8.0), roundi(hud_anchor_position.y / 8.0)]
	if typeof(feedback_bubble.get("anchor_position", null)) == TYPE_VECTOR2:
		var anchor_position: Vector2 = Vector2(feedback_bubble.get("anchor_position", Vector2.ZERO))
		return "world:pos:%d:%d" % [roundi(anchor_position.x / 8.0), roundi(anchor_position.y / 8.0)]
	return ""


func _get_feedback_bubble_visual_priority(feedback_bubble: Dictionary) -> int:
	var source: String = String(feedback_bubble.get("source", "")).strip_edges().to_lower()
	var purpose: String = String(feedback_bubble.get("purpose", "")).strip_edges().to_lower()
	var category: String = String(feedback_bubble.get("category", "")).strip_edges().to_lower()
	if purpose == "command_feedback" or source == "fireteamleader_command_feedback" or category == "ftl_command_feedback":
		return 30
	if source.find("fireteamleader") >= 0:
		return 20
	if purpose == "npc_thought" or category == "npc_thought_peek":
		return 10
	return 1


func _add_area_order_visual(area_data: Dictionary) -> void:
	var command_type: String = String(area_data.get("command_type", "")).strip_edges().to_lower()
	var color: Color = _get_command_color(command_type)
	var tile_world_positions: Array = Array(area_data.get("tile_world_positions", []))
	if tile_world_positions.is_empty():
		var center: Vector2 = Vector2(area_data.get("center_position", Vector2.ZERO))
		tile_world_positions = [center]
	for world_variant in tile_world_positions:
		var marker_name: String = "AreaOrderTile_%s" % String(area_data.get("area_order_id", ""))
		if _add_world_tile_marker(_order_root, Vector2(world_variant), Color(color.r, color.g, color.b, 0.34), marker_name, 0.045, 0.92):
			_area_order_tile_marker_count += 1
	_area_order_count += 1


func _add_area_order_preview_visuals() -> void:
	if _area_order_preview_payload.is_empty():
		return
	var tile_world_positions: Array = Array(_area_order_preview_payload.get("tile_world_positions", []))
	var preview_color := Color(0.84, 0.94, 1.0, 0.48)
	if tile_world_positions.is_empty():
		var polygon: PackedVector2Array = PackedVector2Array(_area_order_preview_payload.get("world_polygon", PackedVector2Array()))
		if polygon.size() < 2:
			return
		for index in range(polygon.size()):
			var start_world: Vector2 = polygon[index]
			var end_world: Vector2 = polygon[(index + 1) % polygon.size()]
			_add_line3d(_order_root, _world_to_surface_3d_position(start_world, 0.72), _world_to_surface_3d_position(end_world, 0.72), preview_color, "AreaOrderPreviewEdge")
		return
	for world_variant in tile_world_positions:
		_add_world_tile_marker(_order_root, Vector2(world_variant), preview_color, "AreaOrderPreviewTile", 0.065, 0.96)


func _add_plan_visual(plan_data: Dictionary, phase_index: int, anchor_by_fireteam: Dictionary) -> void:
	if int(plan_data.get("phase", -1)) != phase_index:
		return
	var fireteam_id: String = String(plan_data.get("fireteam_id", "")).strip_edges().to_lower()
	var last_position: Variant = anchor_by_fireteam.get(fireteam_id, null)
	for waypoint_variant in Array(plan_data.get("waypoints", [])):
		if typeof(waypoint_variant) != TYPE_DICTIONARY:
			continue
		var waypoint: Dictionary = Dictionary(waypoint_variant)
		var waypoint_status: String = String(waypoint.get("status", "")).strip_edges().to_lower()
		if waypoint_status == "completed" or waypoint_status == "cancelled":
			continue
		if typeof(waypoint.get("target_position", null)) != TYPE_VECTOR2:
			continue
		var target_position: Vector2 = Vector2(waypoint.get("target_position", Vector2.ZERO))
		var command_color: Color = _get_command_color(String(waypoint.get("command_type", "move")))
		if typeof(last_position) == TYPE_VECTOR2:
			_add_line3d(_order_root, _world_to_surface_3d_position(Vector2(last_position), 0.36), _world_to_surface_3d_position(target_position, 0.36), command_color, "WaypointLine")
		if _add_world_tile_marker(_order_root, target_position, Color(command_color.r, command_color.g, command_color.b, 0.42), "WaypointTile", 0.05, 0.82):
			_waypoint_tile_marker_count += 1
		_waypoint_visual_count += 1
		last_position = target_position


func _add_movement_state_visual(movement_state: Dictionary) -> void:
	var style: String = String(movement_state.get("advance_style", movement_state.get("effective_style", ""))).strip_edges().to_lower()
	if style.is_empty():
		return
	var origin_position: Vector2 = Vector2(movement_state.get("bound_origin_position", movement_state.get("progress_anchor_position", Vector2.ZERO)))
	var target_position: Vector2 = Vector2(movement_state.get("bound_target_position", movement_state.get("current_anchor_target_position", origin_position)))
	var color: Color = _get_movement_style_color(style)
	var fireteam_id: String = String(movement_state.get("fireteam_id", "")).strip_edges().to_lower()
	_add_line3d(_order_root, _world_to_surface_3d_position(origin_position, 0.64), _world_to_surface_3d_position(target_position, 0.64), color, "AdvanceLine_%s_%s" % [style, fireteam_id])
	_movement_style_visual_count += 1
	if _add_world_tile_marker(_order_root, target_position, Color(color.r, color.g, color.b, 0.42), "AdvanceBound_%s_%s" % [style, fireteam_id], 0.06, _get_movement_bound_marker_fill(style)):
		_movement_bound_marker_count += 1
	_add_movement_group_markers(movement_state, origin_position, target_position, color)
	var label_text: String = _build_movement_map_label(movement_state)
	if not label_text.is_empty():
		_add_label3d(_order_root, label_text, _world_to_surface_3d_position(target_position, MOVEMENT_LABEL_HEIGHT), "AdvanceLabel_%s_%s" % [style, fireteam_id], color.lightened(0.08), 13)
	_movement_style_entries.append(_build_movement_style_entry(movement_state, label_text))


func _add_fireteam_orientation_visuals(anchor_entries: Array) -> void:
	for anchor_variant in anchor_entries:
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor_dict: Dictionary = Dictionary(anchor_variant)
		var fireteam_id: String = String(anchor_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or typeof(anchor_dict.get("position", null)) != TYPE_VECTOR2:
			continue
		var heading_variant: Variant = anchor_dict.get("heading_direction", null)
		if typeof(heading_variant) != TYPE_VECTOR2:
			continue
		var direction: Vector2 = Vector2(heading_variant)
		if direction.length_squared() <= 0.0001:
			continue
		direction = direction.normalized()
		var origin_position: Vector2 = Vector2(anchor_dict.get("position", Vector2.ZERO))
		var tip_position: Vector2 = origin_position + direction * FIRETEAM_ORIENTATION_LINE_LENGTH_WORLD
		var line_color: Color = FIRETEAM_ORIENTATION_LINE_COLOR.lerp(_get_fireteam_color(fireteam_id), 0.22)
		_add_line3d(
			_order_root,
			_world_to_surface_3d_position(origin_position, 0.76),
			_world_to_surface_3d_position(tip_position, 0.76),
			line_color,
			"FireteamOrientation_%s" % fireteam_id
		)
		_add_marker3d(_order_root, tip_position, FIRETEAM_ORIENTATION_TIP_COLOR, "FireteamOrientationTip_%s" % fireteam_id, 0.10, 0.035, 4)
		_fireteam_orientation_visual_count += 1
		_fireteam_orientation_entries.append({
			"fireteam_id": fireteam_id,
			"position": origin_position,
			"heading_direction": direction,
			"heading_angle": float(anchor_dict.get("heading_angle", direction.angle())),
			"heading_source": String(anchor_dict.get("heading_source", "")),
			"tip_position": tip_position,
		})


func _add_movement_group_markers(movement_state: Dictionary, origin_position: Vector2, target_position: Vector2, color: Color) -> void:
	var target_positions: Dictionary = Dictionary(movement_state.get("current_target_positions", {}))
	var moving_unit_ids: PackedStringArray = PackedStringArray(movement_state.get("moving_unit_ids", movement_state.get("current_moving_unit_ids", PackedStringArray())))
	var covering_unit_ids: PackedStringArray = PackedStringArray(movement_state.get("covering_unit_ids", movement_state.get("current_covering_unit_ids", PackedStringArray())))
	for unit_id in moving_unit_ids:
		var marker_position: Vector2 = Vector2(target_positions.get(String(unit_id), target_position))
		if _add_snapped_movement_group_marker(marker_position, color.lightened(0.12), "AdvanceMoving_%s" % String(unit_id), String(unit_id), "moving", 0.48):
			_movement_group_marker_count += 1
	for cover_index in range(covering_unit_ids.size()):
		var cover_position: Vector2 = origin_position + Vector2(8.0 * float(cover_index), 8.0)
		if _add_snapped_movement_group_marker(cover_position, Color(color.r, color.g, color.b, 0.46), "AdvanceCover_%s" % String(covering_unit_ids[cover_index]), String(covering_unit_ids[cover_index]), "covering", 0.34):
			_movement_group_marker_count += 1


func _add_snapped_movement_group_marker(world_position: Vector2, color: Color, node_name: String, unit_id: String, role: String, fill: float) -> bool:
	if _terrain_map_data == null or not _terrain_map_data.has_method("get_tile_at_grid"):
		return false
	var grid_position: Vector2i = _world_to_grid_position(world_position)
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return false
	if not _add_tile_marker(_order_root, grid_position, color, "%s_%d_%d" % [node_name, grid_position.x, grid_position.y], 0.05, fill):
		return false
	_movement_group_marker_entries.append({
		"unit_id": unit_id,
		"role": role,
		"grid_position": grid_position,
		"world_position": Vector2(tile_data.world_position) if typeof(tile_data.world_position) == TYPE_VECTOR2 else _grid_float_to_world(Vector2(grid_position)),
	})
	return true


func _add_multi_fireteam_plan_visual(plan_data: Dictionary) -> void:
	var plan_id: String = String(plan_data.get("plan_id", "")).strip_edges()
	for assignment_variant in Array(plan_data.get("role_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		if typeof(assignment.get("planned_position", null)) != TYPE_VECTOR2:
			continue
		var role: String = String(assignment.get("role", "")).strip_edges().to_lower()
		var fireteam_id: String = String(assignment.get("fireteam_id", "")).strip_edges().to_lower()
		var planned_position: Vector2 = Vector2(assignment.get("planned_position", Vector2.ZERO))
		var color: Color = _get_multi_fireteam_role_color(role)
		var marker_name: String = "MultiPlan_%s_%s_%s" % [_sanitize_node_name(plan_id), _sanitize_node_name(fireteam_id), _sanitize_node_name(role)]
		if _add_world_tile_marker(_order_root, planned_position, Color(color.r, color.g, color.b, 0.46), marker_name, 0.068, 0.58):
			_multi_fireteam_plan_visual_count += 1
		var label_text: String = String(assignment.get("map_label_text", "")).strip_edges()
		if label_text.is_empty():
			label_text = String(assignment.get("role_label", role.substr(0, mini(role.length(), 3)).to_upper()))
		_add_label3d(_order_root, label_text, _world_to_surface_3d_position(planned_position, MOVEMENT_LABEL_HEIGHT + 0.16), "%s_Label" % marker_name, color.lightened(0.08), 12)
		_multi_fireteam_plan_entries.append({
			"plan_id": plan_id,
			"fireteam_id": fireteam_id,
			"role": role,
			"role_label": String(assignment.get("role_label", "")),
			"map_label_text": label_text,
			"planned_position": planned_position,
			"status": String(assignment.get("status", "")),
		})


func _get_multi_fireteam_role_color(role: String) -> Color:
	match role.strip_edges().to_lower():
		"lead":
			return Color(0.42, 0.92, 1.0, 0.96)
		"support":
			return Color(1.0, 0.78, 0.24, 0.96)
		"security":
			return Color(0.48, 0.96, 0.62, 0.94)
		"reserve":
			return Color(0.86, 0.86, 0.94, 0.88)
		"recon":
			return Color(0.76, 0.62, 1.0, 0.92)
		_:
			return Color(0.86, 0.9, 0.94, 0.84)


func _build_movement_style_entry(movement_state: Dictionary, label_text: String) -> Dictionary:
	var readability: Dictionary = Dictionary(movement_state.get("map_readability", {}))
	return {
		"fireteam_id": String(movement_state.get("fireteam_id", "")),
		"advance_style": String(movement_state.get("advance_style", movement_state.get("effective_style", readability.get("advance_style", "")))),
		"style_code": String(movement_state.get("style_code", readability.get("style_code", ""))),
		"moving_unit_ids": PackedStringArray(movement_state.get("moving_unit_ids", movement_state.get("current_moving_unit_ids", readability.get("moving_unit_ids", PackedStringArray())))),
		"covering_unit_ids": PackedStringArray(movement_state.get("covering_unit_ids", movement_state.get("current_covering_unit_ids", readability.get("covering_unit_ids", PackedStringArray())))),
		"bound_index": int(movement_state.get("bound_index", readability.get("bound_index", 1))),
		"bound_count": int(movement_state.get("bound_count", readability.get("bound_count", 1))),
		"group_index": int(movement_state.get("group_index", readability.get("group_index", 1))),
		"group_count": int(movement_state.get("group_count", readability.get("group_count", 1))),
		"bound_distance": float(movement_state.get("bound_distance", readability.get("bound_distance", 0.0))),
		"multi_tile_bound": bool(movement_state.get("multi_tile_bound", readability.get("multi_tile_bound", false))),
		"bound_target_position": Vector2(movement_state.get("bound_target_position", readability.get("bound_target_position", movement_state.get("current_anchor_target_position", Vector2.ZERO)))),
		"map_label_text": label_text,
		"status_line": String(movement_state.get("readability_status_line", readability.get("status_line", ""))),
	}


func _build_movement_map_label(movement_state: Dictionary) -> String:
	var readability: Dictionary = Dictionary(movement_state.get("map_readability", {}))
	var style_code: String = String(movement_state.get("style_code", readability.get("style_code", ""))).strip_edges().to_upper()
	if style_code.is_empty():
		style_code = "MOV"
	var bound_index: int = maxi(int(movement_state.get("bound_index", readability.get("bound_index", 1))), 1)
	var bound_count: int = maxi(int(movement_state.get("bound_count", readability.get("bound_count", 1))), 1)
	var group_index: int = maxi(int(movement_state.get("group_index", readability.get("group_index", 1))), 1)
	var group_count: int = maxi(int(movement_state.get("group_count", readability.get("group_count", 1))), 1)
	if group_count > 1:
		return "%s %d/%d G%d/%d" % [style_code, bound_index, bound_count, group_index, group_count]
	return "%s %d/%d" % [style_code, bound_index, bound_count]


func _add_enemy_security_visual(security_state: Dictionary) -> void:
	if typeof(security_state.get("anchor_position", null)) != TYPE_VECTOR2:
		return
	var anchor_position: Vector2 = Vector2(security_state.get("anchor_position"))
	var direction_angle: float = float(security_state.get("direction_angle", security_state.get("facing_angle", 0.0)))
	var security_mode: String = String(security_state.get("security_mode", "")).strip_edges().to_lower()
	var sector_width: float = float(security_state.get("sector_width", TAU if security_mode == "360" else PI * 0.7))
	var group_id: String = String(security_state.get("security_group_id", security_state.get("fireteam_id", "enemy"))).strip_edges().to_lower()
	if group_id.is_empty():
		group_id = "enemy"
	var color: Color = Color(1.0, 0.46, 0.12, 0.88)
	var range_hint: float = _resolve_enemy_security_visual_length(security_state)
	var direction_tip: Vector2 = anchor_position + Vector2.RIGHT.rotated(direction_angle) * range_hint
	_add_line3d(_order_root, _world_to_surface_3d_position(anchor_position, 0.76), _world_to_surface_3d_position(direction_tip, 0.76), color, "EnemySecurityFacing_%s" % group_id)
	_add_marker3d(_order_root, direction_tip, Color(color.r, color.g, color.b, 0.58), "EnemySecurityTip_%s" % group_id, 0.12, 0.12, 3)
	if _add_world_tile_marker(_order_root, anchor_position, Color(color.r, color.g, color.b, 0.22), "EnemySecurityAnchor_%s" % group_id, 0.035, 0.42):
		_enemy_security_visual_count += 1
	var label_text: String = String(security_state.get("watch_label", "")).strip_edges()
	if label_text.is_empty():
		label_text = "EN SEC %s" % security_mode.to_upper()
	_add_label3d(_order_root, label_text, _world_to_surface_3d_position(anchor_position, MOVEMENT_LABEL_HEIGHT + 0.22), "EnemySecurityLabel_%s" % group_id, color.lightened(0.08), 12)
	_enemy_security_entries.append({
		"security_group_id": group_id,
		"security_mode": security_mode,
		"facing_angle": direction_angle,
		"sector_width": sector_width,
		"watched_unit_ids": PackedStringArray(security_state.get("watched_unit_ids", PackedStringArray())),
		"watch_label": label_text,
	})


func _resolve_enemy_security_visual_length(security_state: Dictionary) -> float:
	var max_range: float = 0.0
	for assignment_variant in Array(security_state.get("member_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		max_range = maxf(max_range, float(Dictionary(assignment_variant).get("weapon_range_world", 0.0)))
	if max_range <= 0.0:
		max_range = 144.0
	return clampf(max_range * 0.18, 72.0, 180.0)


func _add_enemy_tactics_visual(tactics_state: Dictionary) -> void:
	if typeof(tactics_state.get("anchor_position", null)) != TYPE_VECTOR2:
		return
	var group_id: String = String(tactics_state.get("security_group_id", tactics_state.get("fireteam_id", "enemy"))).strip_edges().to_lower()
	if group_id.is_empty():
		group_id = "enemy"
	var anchor_position: Vector2 = Vector2(tactics_state.get("anchor_position"))
	var label_text: String = String(tactics_state.get("tactic_label", "")).strip_edges()
	if label_text.is_empty():
		label_text = String(tactics_state.get("advance_style", "hold")).strip_edges().to_upper()
	var color: Color = Color(1.0, 0.66, 0.18, 0.86)
	var target_positions: Dictionary = Dictionary(tactics_state.get("target_positions_by_unit_id", {}))
	var moving_unit_ids: PackedStringArray = PackedStringArray(tactics_state.get("moving_unit_ids", PackedStringArray()))
	for unit_id in moving_unit_ids:
		if not target_positions.has(String(unit_id)):
			continue
		var target_position: Vector2 = Vector2(target_positions.get(String(unit_id), anchor_position))
		_add_line3d(_order_root, _world_to_surface_3d_position(anchor_position, 0.58), _world_to_surface_3d_position(target_position, 0.58), color, "EnemyTacticLine_%s_%s" % [group_id, String(unit_id)])
		_add_marker3d(_order_root, target_position, Color(color.r, color.g, color.b, 0.48), "EnemyTacticTarget_%s_%s" % [group_id, String(unit_id)], 0.1, 0.09, 4)
	_enemy_tactics_visual_count += 1
	_add_label3d(_order_root, label_text, _world_to_surface_3d_position(anchor_position, MOVEMENT_LABEL_HEIGHT + 0.44), "EnemyTacticLabel_%s" % group_id, color.lightened(0.06), 12)
	_enemy_tactics_entries.append({
		"security_group_id": group_id,
		"advance_style": String(tactics_state.get("advance_style", "")),
		"tactic_label": label_text,
		"moving_unit_ids": moving_unit_ids,
		"covering_unit_ids": PackedStringArray(tactics_state.get("covering_unit_ids", PackedStringArray())),
		"role_by_unit_id": Dictionary(tactics_state.get("role_by_unit_id", {})).duplicate(true),
	})


func _add_selected_fireteam_unit_markers() -> void:
	var selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(_order_payload.get("selected_fireteam_ids", PackedStringArray()))
	if selected_fireteam_ids.is_empty():
		return
	for unit in _unit_nodes:
		if unit == null or not (unit is Node2D):
			continue
		var fireteam_id: String = _get_unit_fireteam_id(unit)
		if fireteam_id.is_empty() or not selected_fireteam_ids.has(fireteam_id):
			continue
		if not _is_unit_world_visible(unit):
			continue
		var unit_id: String = _get_unit_id(unit)
		var unit_position: Vector2 = (unit as Node2D).global_position
		_add_marker3d(
			_order_root,
			unit_position,
			SELECTED_UNIT_MARKER_COLOR,
			"SelectedUnit_%s" % _sanitize_node_name(unit_id),
			SELECTED_UNIT_MARKER_RADIUS,
			SELECTED_UNIT_MARKER_HEIGHT,
			4,
			SELECTED_UNIT_MARKER_SURFACE_OFFSET
		)
		_selected_unit_marker_count += 1
		_selected_unit_marker_entries.append({
			"unit_id": unit_id,
			"fireteam_id": fireteam_id,
			"position": unit_position,
			"grid_position": _world_to_grid_position(unit_position),
			"surface_offset": SELECTED_UNIT_MARKER_SURFACE_OFFSET,
			"visual_only": true,
		})


func _add_selected_fireteam_aim_visuals() -> void:
	if not bool(_order_payload.get("fire_sector_overlay_enabled", false)):
		_friendly_aim_direction_by_unit_id.clear()
		return
	var selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(_order_payload.get("selected_fireteam_ids", PackedStringArray()))
	if selected_fireteam_ids.is_empty():
		_friendly_aim_direction_by_unit_id.clear()
		return
	var visual_mode: String = _get_fire_sector_visual_mode()
	var seen_unit_ids: Dictionary = {}
	for unit in _unit_nodes:
		if unit == null or not (unit is Node2D):
			continue
		var fireteam_id: String = _get_unit_fireteam_id(unit)
		if fireteam_id.is_empty() or not selected_fireteam_ids.has(fireteam_id):
			continue
		if not _is_unit_world_visible(unit):
			continue
		var weapon_id: String = _get_unit_active_attack_weapon_id(unit)
		if weapon_id.is_empty():
			continue
		var range_world: float = float(WEAPON_DATA_SCRIPT.call("get_effective_world_range", weapon_id, _terrain_map_data))
		var range_tiles: int = maxi(int(WEAPON_DATA_SCRIPT.call("get_effective_tile_range", weapon_id)), 1)
		if range_world <= 0.0:
			continue
		var unit_position: Vector2 = (unit as Node2D).global_position
		var unit_id: String = _get_unit_id(unit)
		var aim_direction: Vector2 = _resolve_unit_visible_aim_direction(unit, unit_position)
		if aim_direction.length_squared() <= 0.0001:
			continue
		aim_direction = _stabilize_friendly_aim_direction(unit_id, aim_direction)
		seen_unit_ids[unit_id] = true
		var line_anchor: Dictionary = _build_unit_fire_line_anchor(unit, unit_position, aim_direction)
		var facing_length: float = clampf(range_world * 0.16, FRIENDLY_FIRE_FACING_STEM_MIN_WORLD, FRIENDLY_FIRE_FACING_STEM_MAX_WORLD)
		var default_tip_position: Vector2 = unit_position + aim_direction * range_world
		var default_facing_tip_position: Vector2 = unit_position + aim_direction * facing_length
		var sector_report: Dictionary = {}
		var visual_shape: String = "los_line"
		var tile_aligned: bool = false
		if visual_mode == FRIENDLY_FIRE_SECTOR_VISUAL_MODE_TILE_ALIGNED_LOS:
			sector_report = _add_fire_sector_tile_visuals(_order_root, unit_position, aim_direction, range_world, range_tiles, deg_to_rad(FRIENDLY_FIRE_SECTOR_ANGLE_DEGREES), "FriendlyFireSector_%s" % unit_id)
			var facing_line_origin: Vector3 = Vector3(line_anchor.get("origin_3d", _world_to_surface_3d_position(unit_position, FRIENDLY_AIM_LINE_HEIGHT)))
			_add_line3d(_order_root, facing_line_origin, _world_to_3d_position(default_facing_tip_position, facing_line_origin.y), FRIENDLY_AIM_LINE_COLOR, "FriendlyFacingLine_%s" % unit_id)
			_add_marker3d(_order_root, default_facing_tip_position, FRIENDLY_AIM_TIP_COLOR, "FriendlyFacingTip_%s" % unit_id, 0.075, 0.07, 10)
			visual_shape = "tile_sector"
			tile_aligned = true
		else:
			sector_report = _add_fire_sector_los_line_visuals(_order_root, unit_position, aim_direction, range_world, range_tiles, "FriendlySightLine_%s" % unit_id, line_anchor)
			_add_marker3d(_order_root, Vector2(sector_report.get("tip_position", default_tip_position)), FRIENDLY_AIM_TIP_COLOR, "FriendlySightTip_%s" % unit_id, 0.075, 0.07, 10)
		var tip_position: Vector2 = Vector2(sector_report.get("tip_position", default_tip_position))
		var facing_tip_position: Vector2 = Vector2(sector_report.get("facing_tip_position", default_facing_tip_position))
		_friendly_aim_visual_count += 1
		_friendly_aim_entries.append({
			"unit_id": unit_id,
			"fireteam_id": fireteam_id,
			"weapon_id": weapon_id,
			"range_world": range_world,
			"range_tiles": range_tiles,
			"origin_position": unit_position,
			"origin_grid": sector_report.get("origin_grid", _world_to_grid_position(unit_position)),
			"line_origin_position": sector_report.get("line_origin_position", Vector2(line_anchor.get("origin_world", unit_position))),
			"line_origin_anchor": String(sector_report.get("line_origin_anchor", line_anchor.get("anchor", "unit_center"))),
			"tip_position": tip_position,
			"facing_tip_position": facing_tip_position,
			"visual_shape": visual_shape,
			"tile_aligned": tile_aligned,
			"visible_tile_count": int(sector_report.get("visible_tile_count", 0)),
			"blocker_tile_count": int(sector_report.get("blocker_tile_count", 0)),
			"los_line_count": int(sector_report.get("los_line_count", 0)),
			"blocker_grids": Array(sector_report.get("blocker_grids", [])).duplicate(true),
			"los_blocker_samples": Array(sector_report.get("los_blocker_samples", [])).duplicate(true),
			"los_blocked": bool(sector_report.get("los_blocked", false)),
			"sector_angle_degrees": FRIENDLY_FIRE_SECTOR_ANGLE_DEGREES,
			"visual_only": true,
		})
	_prune_stabilized_friendly_aim_directions(seen_unit_ids)


func _reset_mission_los_debug_counters() -> void:
	_mission_los_debug_line_count = 0
	_mission_los_debug_clear_line_count = 0
	_mission_los_debug_blocked_line_count = 0
	_mission_los_debug_blocker_marker_count = 0
	_mission_los_debug_sampled_pair_count = 0
	_mission_los_debug_bounded_skipped_count = 0
	_mission_los_debug_fow_hidden_contact_count = 0
	_mission_los_debug_source_unit_count = 0
	_mission_los_debug_contact_candidate_count = 0
	_mission_los_debug_entries.clear()


func _add_mission_los_debug_visuals() -> void:
	if not bool(_order_payload.get("los_debug_overlay_enabled", false)):
		return
	var selected_fireteam_ids: PackedStringArray = _get_string_array_from_variant(_order_payload.get("selected_fireteam_ids", PackedStringArray()))
	var source_units: Array = _get_mission_los_debug_source_units(selected_fireteam_ids)
	_mission_los_debug_source_unit_count = source_units.size()
	if source_units.is_empty():
		return
	var contact_candidates: Array = _get_mission_los_debug_contact_candidates(selected_fireteam_ids)
	_mission_los_debug_contact_candidate_count = contact_candidates.size()
	if contact_candidates.is_empty():
		return
	var sample_limit: int = _get_mission_los_debug_sample_limit()
	var possible_pair_count: int = source_units.size() * contact_candidates.size()
	for unit_variant in source_units:
		if _mission_los_debug_sampled_pair_count >= sample_limit:
			break
		var source_unit := unit_variant as Node
		if source_unit == null:
			continue
		for contact_variant in contact_candidates:
			if _mission_los_debug_sampled_pair_count >= sample_limit:
				break
			if typeof(contact_variant) != TYPE_DICTIONARY:
				continue
			var contact: Dictionary = Dictionary(contact_variant)
			var entry: Dictionary = _add_mission_los_debug_pair_visual(source_unit, contact, _mission_los_debug_sampled_pair_count)
			if entry.is_empty():
				continue
			_mission_los_debug_sampled_pair_count += 1
			_mission_los_debug_entries.append(entry)
	_mission_los_debug_bounded_skipped_count = maxi(possible_pair_count - _mission_los_debug_sampled_pair_count, 0)


func _get_mission_los_debug_source_units(selected_fireteam_ids: PackedStringArray) -> Array:
	var result: Array = []
	var debug_unit_ids: PackedStringArray = _get_string_array_from_variant(_order_payload.get("los_debug_unit_ids", PackedStringArray()))
	var hovered_unit_id: String = String(_order_payload.get("los_debug_hovered_unit_id", "")).strip_edges()
	if not hovered_unit_id.is_empty() and not debug_unit_ids.has(hovered_unit_id):
		debug_unit_ids.append(hovered_unit_id)
	var use_unit_filter: bool = not debug_unit_ids.is_empty()
	for unit in _unit_nodes:
		if unit == null or not (unit is Node2D):
			continue
		if not _is_unit_world_visible(unit):
			continue
		var unit_id: String = _get_unit_id(unit)
		if use_unit_filter:
			if debug_unit_ids.has(unit_id):
				result.append(unit)
			continue
		var fireteam_id: String = _get_unit_fireteam_id(unit)
		if fireteam_id.is_empty() or not selected_fireteam_ids.has(fireteam_id):
			continue
		result.append(unit)
	return result


func _get_mission_los_debug_contact_candidates(selected_fireteam_ids: PackedStringArray) -> Array:
	var candidates: Array = []
	var selected_lookup: Dictionary = {}
	for fireteam_id_variant in selected_fireteam_ids:
		selected_lookup[String(fireteam_id_variant).strip_edges().to_lower()] = true
	var contact_source_entries: Array = _contact_entries.duplicate(true)
	var current_contact_ids: Dictionary = {}
	for current_variant in _contact_entries:
		if typeof(current_variant) != TYPE_DICTIONARY:
			continue
		var current_contact: Dictionary = Dictionary(current_variant)
		var current_id: String = String(current_contact.get("target_id", current_contact.get("unit_id", ""))).strip_edges()
		if not current_id.is_empty():
			current_contact_ids[current_id] = true
	if _is_fog_of_war_visual_filter_active():
		for last_known_variant in _fow_last_known_contacts:
			if typeof(last_known_variant) != TYPE_DICTIONARY:
				continue
			var last_known_contact: Dictionary = Dictionary(last_known_variant)
			var last_known_id: String = String(last_known_contact.get("target_id", last_known_contact.get("unit_id", ""))).strip_edges()
			if last_known_id.is_empty() or current_contact_ids.has(last_known_id):
				continue
			contact_source_entries.append(last_known_contact)

	var seen_contact_keys: Dictionary = {}
	for contact_variant in contact_source_entries:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var fireteam_id: String = String(contact.get("fireteam_id", "")).strip_edges().to_lower()
		if not selected_lookup.is_empty() and (fireteam_id.is_empty() or not selected_lookup.has(fireteam_id)):
			continue
		if not _fow_allows_contact_visual(contact):
			_mission_los_debug_fow_hidden_contact_count += 1
			continue
		var position_variant: Variant = contact.get("last_known_position", contact.get("position", null))
		if typeof(position_variant) != TYPE_VECTOR2:
			continue
		var target_id: String = String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges()
		if target_id.is_empty():
			continue
		var position: Vector2 = Vector2(position_variant)
		var contact_key: String = "%s:%d,%d" % [target_id, roundi(position.x), roundi(position.y)]
		if seen_contact_keys.has(contact_key):
			continue
		seen_contact_keys[contact_key] = true
		candidates.append(contact.duplicate(true))
	return candidates


func _add_mission_los_debug_pair_visual(source_unit: Node, contact: Dictionary, sample_index: int) -> Dictionary:
	if _order_root == null or _terrain_map_data == null or not (source_unit is Node2D):
		return {}
	var origin_position: Vector2 = (source_unit as Node2D).global_position
	var target_position: Vector2 = Vector2(contact.get("last_known_position", contact.get("position", Vector2.ZERO)))
	var origin_grid: Vector2i = _world_to_grid_position(origin_position)
	var target_grid: Vector2i = _world_to_grid_position(target_position)
	if _terrain_map_data.call("get_tile_at_grid", origin_grid) == null or _terrain_map_data.call("get_tile_at_grid", target_grid) == null:
		return {}
	var blocker_grid: Vector2i = _find_fire_sector_los_blocker_grid_cached(origin_grid, target_grid)
	var sentinel := Vector2i(2147483647, 2147483647)
	var blocked: bool = blocker_grid != sentinel
	var line_tip_position: Vector2 = target_position
	var blocker_position: Variant = null
	if blocked:
		line_tip_position = _get_tile_world_position_for_grid(blocker_grid, _grid_float_to_world(Vector2(blocker_grid)))
		blocker_position = line_tip_position
		if _add_world_tile_marker(
			_order_root,
			line_tip_position,
			MISSION_LOS_DEBUG_BLOCKER_MARKER_COLOR,
			"MissionLOSDebugBlocker_%d_%d_%d" % [blocker_grid.x, blocker_grid.y, sample_index],
			0.125,
			0.54
		):
			_mission_los_debug_blocker_marker_count += 1
	var source_unit_id: String = _get_unit_id(source_unit)
	var target_id: String = String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges()
	_add_line3d(
		_order_root,
		_world_to_surface_3d_position(origin_position, 0.98),
		_world_to_surface_3d_position(line_tip_position, 0.98),
		MISSION_LOS_DEBUG_BLOCKED_LINE_COLOR if blocked else MISSION_LOS_DEBUG_CLEAR_LINE_COLOR,
		"MissionLOSDebug_%s_%s_%d" % [_sanitize_node_name(source_unit_id), _sanitize_node_name(target_id), sample_index]
	)
	_add_marker3d(
		_order_root,
		target_position,
		MISSION_LOS_DEBUG_CONTACT_MARKER_COLOR,
		"MissionLOSDebugContact_%s_%d" % [_sanitize_node_name(target_id), sample_index],
		0.075,
		0.045,
		8
	)
	_mission_los_debug_line_count += 1
	if blocked:
		_mission_los_debug_blocked_line_count += 1
	else:
		_mission_los_debug_clear_line_count += 1
	return {
		"source_unit_id": source_unit_id,
		"source_fireteam_id": _get_unit_fireteam_id(source_unit),
		"target_id": target_id,
		"detection_state": String(contact.get("detection_state", "unknown")).strip_edges().to_lower(),
		"origin_position": origin_position,
		"target_position": target_position,
		"origin_grid": origin_grid,
		"target_grid": target_grid,
		"line_state": "blocked" if blocked else "clear",
		"blocked": blocked,
		"blocker_grid": blocker_grid if blocked else Vector2i(-1, -1),
		"blocker_position": blocker_position,
		"fow_last_known": bool(contact.get("fow_last_known", false)),
		"sample_index": sample_index,
		"visual_only": true,
	}


func _get_mission_los_debug_sample_limit() -> int:
	return clampi(int(_order_payload.get("los_debug_sample_limit", MISSION_LOS_DEBUG_SAMPLE_LIMIT)), 1, 64)


func _stabilize_friendly_aim_direction(unit_id: String, raw_direction: Vector2) -> Vector2:
	var normalized_direction: Vector2 = raw_direction.normalized()
	if unit_id.strip_edges().is_empty():
		return normalized_direction
	var previous_variant = _friendly_aim_direction_by_unit_id.get(unit_id, null)
	if typeof(previous_variant) == TYPE_VECTOR2:
		var previous_direction: Vector2 = Vector2(previous_variant)
		if previous_direction.length_squared() > 0.0001:
			var angle_delta: float = absf(wrapf(normalized_direction.angle() - previous_direction.normalized().angle(), -PI, PI))
			if angle_delta < FRIENDLY_AIM_DIRECTION_DEADZONE_RADIANS:
				return previous_direction.normalized()
	_friendly_aim_direction_by_unit_id[unit_id] = normalized_direction
	return normalized_direction


func _prune_stabilized_friendly_aim_directions(seen_unit_ids: Dictionary) -> void:
	for key_variant in _friendly_aim_direction_by_unit_id.keys():
		var unit_id: String = String(key_variant)
		if not seen_unit_ids.has(unit_id):
			_friendly_aim_direction_by_unit_id.erase(unit_id)


func _get_fire_sector_visual_mode() -> String:
	var mode: String = String(_order_payload.get("fire_sector_visual_mode", FRIENDLY_FIRE_SECTOR_VISUAL_MODE_LOS_LINE)).strip_edges().to_lower()
	if mode == FRIENDLY_FIRE_SECTOR_VISUAL_MODE_TILE_ALIGNED_LOS:
		return mode
	return FRIENDLY_FIRE_SECTOR_VISUAL_MODE_LOS_LINE


func _get_fire_sector_scan_mode() -> String:
	if _get_fire_sector_visual_mode() == FRIENDLY_FIRE_SECTOR_VISUAL_MODE_TILE_ALIGNED_LOS:
		return FRIENDLY_FIRE_SECTOR_SCAN_MODE_TILE_CACHE
	return FRIENDLY_FIRE_SECTOR_SCAN_MODE_LOS_LINE


func _resolve_unit_visible_aim_direction(unit: Node, unit_world_position: Vector2) -> Vector2:
	var aim_direction: Vector2 = _resolve_unit_aim_direction(unit, unit_world_position)
	if aim_direction.length_squared() > 0.0001:
		return aim_direction.normalized()
	var proxy := _unit_proxies_by_id.get(_get_unit_id(unit), null) as Node3D
	if proxy != null and is_instance_valid(proxy) and proxy.visible:
		var proxy_direction: Vector2 = _get_world_direction_from_proxy_yaw(unit_world_position, float(proxy.rotation_degrees.y))
		if proxy_direction.length_squared() > 0.0001:
			return proxy_direction.normalized()
	return Vector2.RIGHT


func _get_unit_fireteam_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_fireteam_id"):
		return String(unit.call("get_fireteam_id")).strip_edges().to_lower()
	return ""


func _get_unit_active_attack_weapon_id(unit: Node) -> String:
	var candidates := PackedStringArray()
	if unit != null and unit.has_method("get_active_weapon_id"):
		candidates.append(String(unit.call("get_active_weapon_id")))
	for weapon_id in _get_unit_visual_weapon_ids(unit):
		if not candidates.has(String(weapon_id)):
			candidates.append(String(weapon_id))
	for candidate in candidates:
		var normalized: String = String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", String(candidate))).strip_edges().to_lower()
		if not normalized.is_empty() and bool(WEAPON_DATA_SCRIPT.call("is_attack_weapon_id", normalized)):
			return normalized
	return ""


func _build_unit_fire_line_anchor(unit: Node, unit_world_position: Vector2, aim_direction: Vector2) -> Dictionary:
	var direction: Vector2 = aim_direction.normalized() if aim_direction.length_squared() > 0.0001 else Vector2.RIGHT
	var anchor_world: Vector2 = unit_world_position + direction * FRIENDLY_FIRE_LINE_BARREL_OFFSET_WORLD
	var anchor_3d: Vector3 = _world_to_surface_3d_position(anchor_world, FRIENDLY_AIM_LINE_HEIGHT)
	var anchor_name: String = "barrel_offset"
	var proxy := _unit_proxies_by_id.get(_get_unit_id(unit), null) as Node3D
	if proxy != null and is_instance_valid(proxy) and proxy.visible:
		var weapon_node: Node3D = _find_unit_blaster_visual_node(proxy)
		var weapon_posture: String = _normalize_unit_weapon_posture(String(proxy.get_meta("unit_weapon_posture", "")))
		if weapon_node != null and is_instance_valid(weapon_node) and weapon_posture != "lowered":
			anchor_3d = weapon_node.global_position
			anchor_name = "weapon_visual"
	return {
		"origin_world": anchor_world,
		"origin_3d": anchor_3d,
		"anchor": anchor_name,
	}


func _resolve_unit_aim_direction(unit: Node, unit_world_position: Vector2) -> Vector2:
	var proxy := _unit_proxies_by_id.get(_get_unit_id(unit), null) as Node3D
	var explicit_facing_direction: Vector2 = _resolve_unit_explicit_facing_direction(unit)
	if explicit_facing_direction.length_squared() > 0.0001:
		return explicit_facing_direction
	if proxy != null and is_instance_valid(proxy):
		var proxy_direction: Vector2 = _get_world_direction_from_proxy_yaw(unit_world_position, float(proxy.rotation_degrees.y))
		if proxy_direction.length_squared() > 0.0001:
			return proxy_direction
	var motion_or_target_direction: Vector2 = _resolve_unit_motion_or_target_direction(proxy, unit, unit_world_position)
	if motion_or_target_direction.length_squared() > 0.0001:
		return motion_or_target_direction
	var target_position_variant = unit.call("get_target_position") if unit != null and unit.has_method("get_target_position") else null
	if typeof(target_position_variant) == TYPE_VECTOR2:
		var target_position: Vector2 = Vector2(target_position_variant)
		if unit_world_position.distance_squared_to(target_position) > 1.0:
			return (target_position - unit_world_position).normalized()
	return Vector2.RIGHT


func _resolve_unit_explicit_facing_direction(unit: Node) -> Vector2:
	if unit == null:
		return Vector2.ZERO
	for meta_key in ["facing_angle", "map_facing_angle", "enemy_facing_angle"]:
		if unit.has_meta(meta_key):
			return Vector2.RIGHT.rotated(float(unit.get_meta(meta_key, 0.0))).normalized()
	return Vector2.ZERO


func _resolve_unit_motion_or_target_direction(proxy: Node3D, unit: Node, current_world_position: Vector2) -> Vector2:
	if proxy != null and is_instance_valid(proxy) and proxy.has_meta("last_world_position"):
		var previous_position: Variant = proxy.get_meta("last_world_position")
		if typeof(previous_position) == TYPE_VECTOR2:
			var previous_world_position: Vector2 = Vector2(previous_position)
			if previous_world_position.distance_squared_to(current_world_position) > 0.25:
				return (current_world_position - previous_world_position).normalized()
	var target_position_variant = unit.call("get_target_position") if unit != null and unit.has_method("get_target_position") else null
	if typeof(target_position_variant) == TYPE_VECTOR2:
		var target_position: Vector2 = Vector2(target_position_variant)
		if current_world_position.distance_squared_to(target_position) > 1.0:
			return (target_position - current_world_position).normalized()
	return Vector2.ZERO


func _get_world_direction_from_proxy_yaw(unit_world_position: Vector2, yaw_degrees: float) -> Vector2:
	var yaw_radians: float = deg_to_rad(yaw_degrees)
	var grid_direction := Vector2(sin(yaw_radians), -cos(yaw_radians))
	var world_tip: Vector2 = _grid_float_to_world(_world_to_grid_float(unit_world_position) + grid_direction)
	if unit_world_position.distance_squared_to(world_tip) <= 0.001:
		return Vector2.ZERO
	return (world_tip - unit_world_position).normalized()


func _ensure_audio_event_bus(create_if_missing: bool = true):
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus):
		return _audio_event_bus
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree != null:
		var current_scene := tree.current_scene
		if current_scene != null:
			var scene_bus := current_scene.find_child("AudioEventBus", true, false)
			if scene_bus != null and scene_bus.has_method("emit_weapon_fire"):
				_audio_event_bus = scene_bus
				return _audio_event_bus
		var root_bus := tree.root.find_child("AudioEventBus", true, false)
		if root_bus != null and root_bus.has_method("emit_weapon_fire"):
			_audio_event_bus = root_bus
			return _audio_event_bus
	if not create_if_missing:
		return null
	_audio_event_bus = AUDIO_EVENT_BUS_SCRIPT.new()
	_audio_event_bus.name = "AudioEventBus"
	var parent: Node = self
	if tree != null and tree.current_scene != null:
		parent = tree.current_scene
	parent.add_child(_audio_event_bus)
	if _audio_event_bus.has_method("initialize"):
		_audio_event_bus.call("initialize")
	return _audio_event_bus


func _emit_weapon_fire_sfx_from_fire_event(fire_event: Dictionary, weapon_id: String, muzzle_position: Vector2) -> Dictionary:
	var event_id: String = String(fire_event.get("event_id", "")).strip_edges()
	if event_id.is_empty():
		return {"played": false, "reason": "missing_fire_event_id"}
	var bus = _ensure_audio_event_bus()
	if bus == null or not bus.has_method("emit_weapon_fire"):
		return {"played": false, "reason": "missing_audio_event_bus"}
	var result: Dictionary = Dictionary(bus.call("emit_weapon_fire", weapon_id, {
		"position": _world_to_surface_3d_position(muzzle_position, 0.78),
		"unit_id": String(fire_event.get("attacker_unit_id", "")),
		"team_id": String(fire_event.get("attacker_team_id", "")),
		"target_unit_id": String(fire_event.get("target_unit_id", "")),
		"source": "terrain_weapon_fire_vfx",
		"visible_to_local": true,
		"visibility_context": "visible_fire_event",
		"dedupe_key": event_id,
		"dedupe_window_msec": 5000,
	})).duplicate(true)
	if bool(result.get("played", false)):
		_weapon_fire_sfx_count += 1
	else:
		_weapon_fire_sfx_suppressed_count += 1
	return result


func _add_weapon_fire_vfx_visual(fire_event: Dictionary) -> void:
	var event_id: String = String(fire_event.get("event_id", "")).strip_edges()
	if event_id.is_empty():
		return
	if typeof(fire_event.get("attacker_position", null)) != TYPE_VECTOR2 or typeof(fire_event.get("target_position", null)) != TYPE_VECTOR2:
		return
	var attacker_position: Vector2 = Vector2(fire_event.get("attacker_position"))
	var target_position: Vector2 = Vector2(fire_event.get("target_position"))
	var direction: Vector2 = target_position - attacker_position
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var weapon_id: String = WEAPON_DATA_SCRIPT.call("normalize_weapon_id", String(fire_event.get("weapon_id", "rifle")))
	var muzzle_entry: Dictionary = _get_weapon_fire_vfx_entry(weapon_id)
	var texture: Texture2D = _get_weapon_fire_vfx_texture(String(muzzle_entry.get("path", "")))
	if texture == null:
		return
	var barrel_offset: float = float(muzzle_entry.get("barrel_offset_world", 28.0))
	var muzzle_position: Vector2 = attacker_position + direction.normalized() * barrel_offset
	var pixel_size: float = float(muzzle_entry.get("pixel_size", 0.010))
	var is_friendly_fire: bool = bool(fire_event.get("is_friendly_fire", false))
	var color: Color = Color(1.0, 0.32, 0.28, 0.9) if is_friendly_fire else Color(1.0, 0.78, 0.28, 0.82)
	_add_texture_card(_order_root, texture, _world_to_surface_3d_position(muzzle_position, 0.92), "WeaponFireMuzzle_%s" % _sanitize_node_name(event_id), pixel_size, Vector2.ZERO, Color(1.0, 0.95, 0.62, 0.92))
	_add_line3d(_order_root, _world_to_surface_3d_position(muzzle_position, 0.78), _world_to_surface_3d_position(target_position, 0.78), color, "WeaponFireTrace_%s" % _sanitize_node_name(event_id))
	var flank_label: String = _build_flank_fire_vfx_label(fire_event)
	if not flank_label.is_empty():
		_add_label3d(_order_root, flank_label, _world_to_surface_3d_position(target_position + Vector2(0.0, -22.0), MOVEMENT_LABEL_HEIGHT + 0.82), "WeaponFireFlank_%s" % _sanitize_node_name(event_id), Color(1.0, 0.70, 0.24, 0.96), 12)
	if is_friendly_fire:
		_add_marker3d(_order_root, target_position, Color(1.0, 0.16, 0.14, 0.62), "WeaponFireFriendlyFlash_%s" % _sanitize_node_name(event_id), 0.18, 0.12, 8)
		_add_label3d(_order_root, "FRIENDLY FIRE", _world_to_surface_3d_position(target_position + Vector2(0.0, -38.0), MOVEMENT_LABEL_HEIGHT + 0.94), "WeaponFireFriendlyLabel_%s" % _sanitize_node_name(event_id), Color(1.0, 0.24, 0.22, 0.98), 13)
	var audio_result: Dictionary = _emit_weapon_fire_sfx_from_fire_event(fire_event, weapon_id, muzzle_position)
	_weapon_fire_vfx_visual_count += 1
	_weapon_fire_vfx_entries.append({
		"event_id": event_id,
		"weapon_id": weapon_id,
		"muzzle_id": String(muzzle_entry.get("id", "")),
		"attacker_unit_id": String(fire_event.get("attacker_unit_id", "")),
		"target_unit_id": String(fire_event.get("target_unit_id", "")),
		"muzzle_position": muzzle_position,
		"audio_event_id": String(audio_result.get("event_id", "")),
		"audio_played": bool(audio_result.get("played", false)),
		"audio_reason": String(audio_result.get("reason", "")),
		"source": String(fire_event.get("source", "")),
		"is_flank": bool(fire_event.get("is_flank", false)),
		"flank_direction_label": String(fire_event.get("flank_direction_label", "")),
		"is_friendly_fire": is_friendly_fire,
		"friendly_fire_target_unit_id": String(fire_event.get("friendly_fire_target_unit_id", "")),
	})


func _build_flank_fire_vfx_label(fire_event: Dictionary) -> String:
	if not bool(fire_event.get("is_flank", false)):
		return ""
	var direction_label: String = String(fire_event.get("flank_direction_label", "")).strip_edges()
	if direction_label.is_empty():
		return "FLANK"
	return "FLANK %s" % direction_label.to_upper()


func _add_feedback_bubble_visual(feedback_bubble: Dictionary) -> void:
	if String(feedback_bubble.get("display_type", "")).strip_edges() != "comic_bubble":
		return
	if not bool(feedback_bubble.get("visual_only", false)):
		return
	if String(feedback_bubble.get("anchor_space", "")).strip_edges().to_lower() == "hud" and typeof(feedback_bubble.get("hud_anchor_position", null)) == TYPE_VECTOR2:
		_add_hud_feedback_bubble_visual(feedback_bubble)
		return
	if typeof(feedback_bubble.get("anchor_position", null)) != TYPE_VECTOR2:
		return
	var bubble_id: String = String(feedback_bubble.get("bubble_id", "")).strip_edges()
	var text: String = String(feedback_bubble.get("text", "")).strip_edges()
	if bubble_id.is_empty() or text.is_empty():
		return
	var anchor_position: Vector2 = Vector2(feedback_bubble.get("anchor_position", Vector2.ZERO))
	var card_position: Vector3 = _world_to_surface_3d_position(anchor_position + Vector2(0.0, -22.0), MOVEMENT_LABEL_HEIGHT + 0.78)
	var texture: Texture2D = _get_comic_bubble_texture(String(feedback_bubble.get("path", "")))
	if texture != null:
		var sprite := _add_texture_card(
			_order_root,
			texture,
			card_position,
			"FeedbackBubble_%s_%d" % [_sanitize_node_name(bubble_id), _feedback_bubble_visual_count],
			0.0066,
			Vector2.ZERO,
			Color(1.0, 1.0, 1.0, 0.96)
		)
		if sprite != null:
			sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			sprite.no_depth_test = true
	else:
		_add_marker3d(_order_root, anchor_position, Color(0.96, 0.92, 0.82, 0.78), "FeedbackBubbleFallback_%s" % _sanitize_node_name(bubble_id), 0.24, 0.12, 16)
	var label: Label3D = _add_label3d(
		_order_root,
		text,
		card_position + Vector3(0.0, 0.035, -0.02),
		"FeedbackBubbleText_%s_%d" % [_sanitize_node_name(bubble_id), _feedback_bubble_visual_count],
		TACTICAL_UI_THEME_SCRIPT.COLOR_FEEDBACK_BUBBLE_TEXT,
		TACTICAL_UI_THEME_SCRIPT.FEEDBACK_BUBBLE_LABEL_FONT_SIZE
	)
	label.pixel_size = STATUS_LABEL_PIXEL_SIZE * 0.68
	label.outline_size = 3
	label.outline_modulate = Color(TACTICAL_UI_THEME_SCRIPT.COLOR_FEEDBACK_BUBBLE_OUTLINE.r, TACTICAL_UI_THEME_SCRIPT.COLOR_FEEDBACK_BUBBLE_OUTLINE.g, TACTICAL_UI_THEME_SCRIPT.COLOR_FEEDBACK_BUBBLE_OUTLINE.b, 0.9)
	_feedback_bubble_visual_count += 1
	_feedback_bubble_entries.append({
		"bubble_id": bubble_id,
		"fireteam_id": String(feedback_bubble.get("fireteam_id", "")).strip_edges().to_lower(),
		"unit_id": String(feedback_bubble.get("unit_id", "")).strip_edges(),
		"feedback_action": String(feedback_bubble.get("feedback_action", "")).strip_edges(),
		"feedback_state": String(feedback_bubble.get("feedback_state", "")).strip_edges(),
		"source": String(feedback_bubble.get("source", "")).strip_edges(),
		"category": String(feedback_bubble.get("category", "")).strip_edges(),
		"purpose": String(feedback_bubble.get("purpose", "")).strip_edges(),
		"thought_kind": String(feedback_bubble.get("thought_kind", "")).strip_edges(),
		"skill_tier": String(feedback_bubble.get("skill_tier", "")).strip_edges(),
		"text_source": String(feedback_bubble.get("text_source", "")).strip_edges(),
		"text_key": String(feedback_bubble.get("text_key", "")).strip_edges(),
		"role_text_key": String(feedback_bubble.get("role_text_key", "")).strip_edges(),
		"situation_key": String(feedback_bubble.get("situation_key", "")).strip_edges(),
		"text": text,
		"path": String(feedback_bubble.get("path", "")).strip_edges(),
		"anchor_position": anchor_position,
		"visual_only": true,
	})


func _add_hud_feedback_bubble_visual(feedback_bubble: Dictionary) -> void:
	if _feedback_bubble_hud_root == null:
		return
	var bubble_id: String = String(feedback_bubble.get("bubble_id", "")).strip_edges()
	var text: String = String(feedback_bubble.get("text", "")).strip_edges()
	if bubble_id.is_empty() or text.is_empty():
		return
	var hud_anchor_position: Vector2 = Vector2(feedback_bubble.get("hud_anchor_position", Vector2.ZERO))
	var bubble_size: Vector2 = _coerce_hud_bubble_size(feedback_bubble.get("max_size", Vector2i(148, 52)))
	bubble_size = _build_compact_hud_bubble_size(text, bubble_size)
	var viewport_size := Vector2(_get_viewport_size())
	if viewport_size.x < bubble_size.x + 1.0 or viewport_size.y < bubble_size.y + 1.0:
		viewport_size = Vector2(1280.0, 720.0)
	var bubble_position: Vector2 = _resolve_hud_feedback_bubble_position(hud_anchor_position, bubble_size, viewport_size)

	var bubble_root := Control.new()
	bubble_root.name = "HudFeedbackBubble_%s_%d" % [_sanitize_node_name(bubble_id), _feedback_bubble_visual_count]
	bubble_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble_root.position = bubble_position
	bubble_root.size = bubble_size
	bubble_root.z_as_relative = false
	bubble_root.z_index = int(feedback_bubble.get("z_index", 76))
	_feedback_bubble_hud_root.add_child(bubble_root)

	var tail := Polygon2D.new()
	tail.name = "BubbleTailLeft"
	tail.polygon = PackedVector2Array([
		Vector2(0.0, bubble_size.y * 0.54),
		Vector2(11.0, bubble_size.y * 0.54 - 6.0),
		Vector2(11.0, bubble_size.y * 0.54 + 6.0),
	])
	tail.color = Color(0.94, 0.97, 0.98, 0.96)
	tail.position = Vector2(-8.0, 0.0)
	bubble_root.add_child(tail)

	var fallback := PanelContainer.new()
	fallback.name = "BubbleFallback"
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.add_theme_stylebox_override("panel", _build_hud_bubble_stylebox())
	bubble_root.add_child(fallback)

	var label := Label.new()
	label.name = "BubbleText"
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TACTICAL_UI_THEME_SCRIPT.COLOR_FEEDBACK_BUBBLE_TEXT)
	label.add_theme_font_size_override("font_size", 8 if text.length() <= 18 else 9)
	label.position = Vector2(8.0, 6.0)
	label.size = Vector2(maxf(bubble_size.x - 16.0, 1.0), maxf(bubble_size.y - 12.0, 1.0))
	bubble_root.add_child(label)

	var world_anchor: Vector2 = Vector2(feedback_bubble.get("anchor_position", Vector2.ZERO)) if typeof(feedback_bubble.get("anchor_position", null)) == TYPE_VECTOR2 else Vector2.ZERO
	_feedback_bubble_visual_count += 1
	_feedback_bubble_entries.append({
		"bubble_id": bubble_id,
		"fireteam_id": String(feedback_bubble.get("fireteam_id", "")).strip_edges().to_lower(),
		"unit_id": String(feedback_bubble.get("unit_id", "")).strip_edges(),
		"feedback_action": String(feedback_bubble.get("feedback_action", "")).strip_edges(),
		"feedback_state": String(feedback_bubble.get("feedback_state", "")).strip_edges(),
		"source": String(feedback_bubble.get("source", "")).strip_edges(),
		"category": String(feedback_bubble.get("category", "")).strip_edges(),
		"purpose": String(feedback_bubble.get("purpose", "")).strip_edges(),
		"thought_kind": String(feedback_bubble.get("thought_kind", "")).strip_edges(),
		"skill_tier": String(feedback_bubble.get("skill_tier", "")).strip_edges(),
		"text_source": String(feedback_bubble.get("text_source", "")).strip_edges(),
		"text_key": String(feedback_bubble.get("text_key", "")).strip_edges(),
		"role_text_key": String(feedback_bubble.get("role_text_key", "")).strip_edges(),
		"situation_key": String(feedback_bubble.get("situation_key", "")).strip_edges(),
		"text": text,
		"path": String(feedback_bubble.get("path", "")).strip_edges(),
		"anchor_position": world_anchor,
		"anchor_space": "hud",
		"hud_anchor_source": String(feedback_bubble.get("hud_anchor_source", "")).strip_edges(),
		"hud_anchor_position": hud_anchor_position,
		"hud_bubble_position": bubble_position,
		"hud_bubble_size": bubble_size,
		"hud_tail_side": "left",
		"hud_tail_points_to_anchor": true,
		"visual_only": true,
	})


func _coerce_hud_bubble_size(value: Variant) -> Vector2:
	if value is Vector2i:
		var vector_i: Vector2i = value
		return Vector2(float(vector_i.x), float(vector_i.y))
	if value is Vector2:
		return Vector2(value)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 168.0)), float(dict.get("y", 72.0)))
	return Vector2(168.0, 72.0)


func _build_compact_hud_bubble_size(text: String, requested_size: Vector2) -> Vector2:
	var trimmed_text: String = text.strip_edges()
	var character_count: int = trimmed_text.length()
	var line_count: int = maxi(trimmed_text.split("\n").size(), 1)
	var target_width: float = 88.0 + float(mini(character_count, 28)) * 2.0
	var target_height: float = 34.0 + float(maxi(line_count - 1, 0)) * 10.0
	return Vector2(
		clampf(minf(requested_size.x, target_width), 84.0, 148.0),
		clampf(minf(requested_size.y, target_height), 34.0, 54.0)
	)


func _resolve_hud_feedback_bubble_position(hud_anchor_position: Vector2, bubble_size: Vector2, viewport_size: Vector2) -> Vector2:
	var base_position: Vector2 = _clamp_hud_feedback_bubble_position(
		hud_anchor_position + Vector2(10.0, -bubble_size.y * 0.52),
		bubble_size,
		viewport_size
	)
	var step: float = bubble_size.y + 4.0
	for offset_y in [0.0, step, -step, step * 2.0, -step * 2.0]:
		var candidate: Vector2 = _clamp_hud_feedback_bubble_position(base_position + Vector2(0.0, offset_y), bubble_size, viewport_size)
		if not _hud_feedback_bubble_position_overlaps(candidate, bubble_size):
			return candidate
	return base_position


func _clamp_hud_feedback_bubble_position(position: Vector2, bubble_size: Vector2, viewport_size: Vector2) -> Vector2:
	return Vector2(
		clampf(position.x, 0.0, maxf(viewport_size.x - bubble_size.x, 0.0)),
		clampf(position.y, 0.0, maxf(viewport_size.y - bubble_size.y, 0.0))
	)


func _hud_feedback_bubble_position_overlaps(position: Vector2, bubble_size: Vector2) -> bool:
	var candidate_rect := Rect2(position, bubble_size).grow(3.0)
	for entry_variant in _feedback_bubble_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("anchor_space", "")).strip_edges().to_lower() != "hud":
			continue
		if typeof(entry.get("hud_bubble_position", null)) != TYPE_VECTOR2:
			continue
		var existing_position: Vector2 = Vector2(entry.get("hud_bubble_position", Vector2.ZERO))
		var existing_size: Vector2 = _coerce_hud_bubble_size(entry.get("hud_bubble_size", Vector2(148.0, 52.0)))
		var existing_rect := Rect2(existing_position, existing_size).grow(3.0)
		if candidate_rect.intersects(existing_rect):
			return true
	return false


func _build_hud_bubble_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.94, 0.97, 0.98, 0.96)
	stylebox.border_color = Color(0.08, 0.13, 0.16, 0.85)
	stylebox.set_border_width_all(1)
	stylebox.set_corner_radius_all(6)
	stylebox.content_margin_left = 10.0
	stylebox.content_margin_top = 8.0
	stylebox.content_margin_right = 10.0
	stylebox.content_margin_bottom = 8.0
	return stylebox


func _add_tactical_communication_event_visual(communication_event: Dictionary) -> void:
	if not bool(communication_event.get("visual_only", true)):
		return
	var channels: PackedStringArray = PackedStringArray(communication_event.get("channels", PackedStringArray()))
	if not channels.has("map_marker"):
		return
	var anchor_variant = communication_event.get("anchor_position", communication_event.get("target_position", null))
	if typeof(anchor_variant) != TYPE_VECTOR2:
		return
	var anchor_position: Vector2 = Vector2(anchor_variant)
	var event_id: String = String(communication_event.get("event_id", "")).strip_edges()
	if event_id.is_empty():
		return
	var priority: int = int(communication_event.get("priority", 0))
	var color: Color = _get_tactical_communication_color(priority, String(communication_event.get("event_type", "")))
	var marker_name: String = "TacCom_%s" % _sanitize_node_name(event_id)
	if not _add_world_tile_marker(_order_root, anchor_position, Color(color.r, color.g, color.b, 0.32), marker_name, 0.048, 0.52):
		return
	var label_text: String = String(communication_event.get("map_label", communication_event.get("short_text", ""))).strip_edges()
	if label_text.is_empty():
		label_text = String(communication_event.get("event_type", "")).strip_edges().to_upper()
	_add_label3d(_order_root, label_text, _world_to_surface_3d_position(anchor_position, MOVEMENT_LABEL_HEIGHT + 0.38), "%s_Label" % marker_name, color.lightened(0.08), 11)
	var target_variant = communication_event.get("target_position", null)
	var has_highlight_line: bool = String(communication_event.get("event_type", "")).strip_edges().to_lower() == "bounding_rotation" and typeof(target_variant) == TYPE_VECTOR2
	if has_highlight_line:
		var target_position: Vector2 = Vector2(target_variant)
		if anchor_position.distance_squared_to(target_position) > 4.0:
			_add_line3d(_order_root, _world_to_surface_3d_position(anchor_position, 0.84), _world_to_surface_3d_position(target_position, 0.84), Color(color.r, color.g, color.b, 0.74), "%s_Line" % marker_name)
	_tactical_communication_event_visual_count += 1
	_tactical_communication_event_entries.append({
		"event_id": event_id,
		"event_type": String(communication_event.get("event_type", "")),
		"fireteam_id": String(communication_event.get("fireteam_id", "")).strip_edges().to_lower(),
		"unit_id": String(communication_event.get("unit_id", "")).strip_edges(),
		"priority": priority,
		"channels": channels,
		"short_text": String(communication_event.get("short_text", "")),
		"map_label": label_text,
		"anchor_position": anchor_position,
		"target_position": Vector2(target_variant) if typeof(target_variant) == TYPE_VECTOR2 else null,
		"has_highlight_line": has_highlight_line,
		"visual_only": true,
	})


func _get_tactical_communication_color(priority: int, event_type: String) -> Color:
	if priority >= 100:
		return Color(1.0, 0.34, 0.24, 0.94)
	if priority >= 80:
		return Color(1.0, 0.76, 0.24, 0.92)
	if event_type.strip_edges().to_lower().contains("objective"):
		return Color(0.50, 0.94, 0.66, 0.9)
	return Color(0.52, 0.88, 1.0, 0.88)


func _get_comic_bubble_texture(path: String) -> Texture2D:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty():
		return null
	if _comic_bubble_texture_cache.has(normalized_path):
		return _comic_bubble_texture_cache[normalized_path] as Texture2D
	if not ResourceLoader.exists(normalized_path):
		return null
	var texture := load(normalized_path) as Texture2D
	if texture != null:
		_comic_bubble_texture_cache[normalized_path] = texture
	return texture


func _get_weapon_fire_vfx_entry(weapon_id: String) -> Dictionary:
	var catalog: Dictionary = _get_weapon_fire_vfx_catalog()
	if catalog.is_empty():
		return {}
	var default_by_weapon: Dictionary = Dictionary(catalog.get("default_by_weapon", {}))
	var entry_id: String = String(default_by_weapon.get(weapon_id, catalog.get("default_id", "muzzle_flash_01"))).strip_edges()
	for entry_variant in Array(catalog.get("muzzle_flashes", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("id", "")) == entry_id:
			return entry
	for entry_variant in Array(catalog.get("muzzle_flashes", [])):
		if typeof(entry_variant) == TYPE_DICTIONARY:
			return Dictionary(entry_variant)
	return {}


func _get_weapon_fire_vfx_texture(path: String) -> Texture2D:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty():
		return null
	if _weapon_fire_vfx_texture_cache.has(normalized_path):
		return _weapon_fire_vfx_texture_cache[normalized_path] as Texture2D
	if not ResourceLoader.exists(normalized_path):
		return null
	var texture := load(normalized_path) as Texture2D
	if texture != null:
		_weapon_fire_vfx_texture_cache[normalized_path] = texture
	return texture


func _get_weapon_fire_vfx_catalog() -> Dictionary:
	if not _weapon_fire_vfx_catalog.is_empty():
		return _weapon_fire_vfx_catalog
	if not FileAccess.file_exists(WEAPON_FIRE_VFX_CATALOG_PATH):
		return {}
	var file := FileAccess.open(WEAPON_FIRE_VFX_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		_weapon_fire_vfx_catalog = Dictionary(parsed)
	return _weapon_fire_vfx_catalog


func _get_fireteam_color(fireteam_id: String) -> Color:
	match fireteam_id.strip_edges().to_lower():
		"blue", "ft1":
			return Color(0.42, 0.76, 1.0, 0.95)
		"gold", "ft2":
			return Color(1.0, 0.86, 0.3, 0.95)
		_:
			return Color(0.88, 0.88, 0.88, 0.85)


func _get_movement_style_color(style: String) -> Color:
	match style.strip_edges().to_lower():
		"bounding":
			return Color(1.0, 0.78, 0.24, 0.94)
		"caterpillar", "creep":
			return Color(0.48, 0.96, 0.62, 0.94)
		"rush":
			return Color(0.32, 0.72, 1.0, 0.92)
		_:
			return Color(0.86, 0.9, 0.94, 0.84)


func _get_movement_bound_marker_fill(style: String) -> float:
	match style.strip_edges().to_lower():
		"bounding":
			return 0.76
		"caterpillar", "creep":
			return 0.56
		_:
			return 0.9


func _rebuild_contact_density_heatmap(force_rebuild: bool = false) -> void:
	if _contact_density_root == null:
		return
	if not _contact_density_overlay_enabled:
		_reset_contact_density_heatmap(true)
		return
	var source_snapshot: Dictionary = _build_contact_density_allowed_source_snapshot()
	var signature: String = _build_contact_density_source_signature(source_snapshot)
	var now_msec: int = Time.get_ticks_msec()
	var source_count: int = int(source_snapshot.get("current_source_count", 0)) + int(source_snapshot.get("last_known_source_count", 0))
	var first_non_empty_source: bool = _contact_density_entries.is_empty() and source_count > 0
	var source_cleared: bool = _contact_density_source_count > 0 and source_count == 0
	if not force_rebuild and signature == _contact_density_last_signature:
		return
	if not force_rebuild and not first_non_empty_source and not source_cleared and _contact_density_last_rebuild_msec > 0 and now_msec - _contact_density_last_rebuild_msec < CONTACT_DENSITY_UPDATE_INTERVAL_MSEC:
		_contact_density_skipped_interval_count += 1
		return
	var heat_snapshot: Dictionary = Dictionary(_contact_density_overlay.call("build_heat_cells", Array(source_snapshot.get("source_entries", [])), {
		"enabled": _contact_density_overlay_enabled,
		"cell_size_world": CONTACT_DENSITY_CELL_SIZE_WORLD,
		"max_source_contacts": CONTACT_DENSITY_MAX_SOURCE_CONTACTS,
		"max_heat_cells": CONTACT_DENSITY_MAX_HEAT_CELLS,
	}))
	_contact_density_last_signature = signature
	_contact_density_last_rebuild_msec = now_msec
	_contact_density_rebuild_count += 1
	_contact_density_source_count = int(heat_snapshot.get("source_contact_count", 0))
	_contact_density_current_source_count = int(source_snapshot.get("current_source_count", 0))
	_contact_density_last_known_source_count = int(source_snapshot.get("last_known_source_count", 0))
	_contact_density_fow_hidden_count = int(source_snapshot.get("fow_hidden_count", 0))
	_contact_density_entries = Array(heat_snapshot.get("heat_cells", [])).duplicate(true)
	_clear_children(_contact_density_root)
	for cell_variant in _contact_density_entries:
		if typeof(cell_variant) == TYPE_DICTIONARY:
			_add_contact_density_cell_visual(Dictionary(cell_variant))


func _reset_contact_density_heatmap(clear_visual: bool = false) -> void:
	_contact_density_entries.clear()
	_contact_density_source_count = 0
	_contact_density_current_source_count = 0
	_contact_density_last_known_source_count = 0
	_contact_density_fow_hidden_count = 0
	_contact_density_last_signature = ""
	if clear_visual:
		_clear_children(_contact_density_root)


func _build_contact_density_allowed_source_snapshot() -> Dictionary:
	var selected_lookup: Dictionary = _build_contact_selected_fireteam_lookup()
	var source_entries: Array = []
	var current_source_count: int = 0
	var last_known_source_count: int = 0
	var fow_hidden_count: int = 0
	for contact_variant in _build_contact_source_entries_with_last_known():
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant).duplicate(true)
		var fireteam_id: String = String(contact.get("fireteam_id", "")).strip_edges().to_lower()
		if not selected_lookup.is_empty() and not selected_lookup.has(fireteam_id):
			continue
		if not _fow_allows_contact_visual(contact):
			fow_hidden_count += 1
			continue
		var position_variant = contact.get("last_known_position", contact.get("position", null))
		if typeof(position_variant) != TYPE_VECTOR2:
			continue
		contact["last_known_position"] = Vector2(position_variant)
		contact["grid_position"] = _world_to_grid_position(Vector2(position_variant))
		contact["visual_only"] = true
		contact["ui_sets_gameplay_truth"] = false
		if bool(contact.get("fow_last_known", false)):
			last_known_source_count += 1
		else:
			current_source_count += 1
		source_entries.append(contact)
	return {
		"source_entries": source_entries,
		"current_source_count": current_source_count,
		"last_known_source_count": last_known_source_count,
		"fow_hidden_count": fow_hidden_count,
		"selected_fireteam_ids": Array(_contact_selected_fireteam_ids),
		"fow_policy": "current_or_last_known_contacts_after_visual_fow_filter",
	}


func _build_contact_density_source_signature(source_snapshot: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("enabled:%s" % str(_contact_density_overlay_enabled))
	parts.append("fow:%s:%s" % [_fog_of_war_mode, _fog_of_war_team_id])
	parts.append("selected:%s" % ",".join(_contact_selected_fireteam_ids))
	parts.append("hidden:%d" % int(source_snapshot.get("fow_hidden_count", 0)))
	var contact_parts: PackedStringArray = PackedStringArray()
	for contact_variant in Array(source_snapshot.get("source_entries", [])):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var position: Vector2 = Vector2(contact.get("last_known_position", Vector2.ZERO))
		contact_parts.append("%s:%s:%s:%.1f,%.1f:%s" % [
			String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges(),
			String(contact.get("fireteam_id", "")).strip_edges().to_lower(),
			String(contact.get("detection_state", "")).strip_edges().to_lower(),
			position.x,
			position.y,
			str(bool(contact.get("fow_last_known", false))),
		])
	contact_parts.sort()
	parts.append("contacts:%s" % "|".join(contact_parts))
	return "\n".join(parts)


func _add_contact_density_cell_visual(cell: Dictionary) -> void:
	var center_variant = cell.get("center_position", null)
	if typeof(center_variant) != TYPE_VECTOR2:
		return
	var center_position: Vector2 = Vector2(center_variant)
	var intensity: float = clampf(float(cell.get("intensity", 0.0)), 0.0, 1.0)
	var contact_count: int = maxi(int(cell.get("contact_count", 0)), 0)
	if contact_count <= 0:
		return
	var grid_position: Vector2i = _world_to_grid_position(center_position)
	var color: Color = _get_contact_density_heat_color(intensity, contact_count)
	if _add_tile_marker(_contact_density_root, grid_position, color, "ContactDensity_%s" % _sanitize_node_name(String(cell.get("cell_key", ""))), 0.026, clampf(0.56 + intensity * 0.36, 0.56, 0.94)):
		if contact_count >= 2:
			_add_label3d(_contact_density_root, "HOT %d" % contact_count, _world_to_surface_3d_position(center_position, 0.46), "ContactDensityLabel_%s" % _sanitize_node_name(String(cell.get("cell_key", ""))), color.lightened(0.22), 10)


func _get_contact_density_heat_color(intensity: float, contact_count: int) -> Color:
	var clamped_intensity: float = clampf(intensity, 0.0, 1.0)
	var alpha: float = clampf(0.16 + clamped_intensity * 0.34 + minf(float(contact_count), 4.0) * 0.025, 0.18, 0.58)
	return Color(1.0, 0.30 + clamped_intensity * 0.32, 0.08, alpha)


func _rebuild_contact_visuals() -> void:
	_clear_children(_contact_root)
	_contact_count = 0
	_contact_visual_entries.clear()
	_fow_hidden_contact_count = 0
	_fow_allowed_contact_count = 0
	if _contact_root == null:
		return
	var selected_lookup: Dictionary = _build_contact_selected_fireteam_lookup()
	for contact_variant in _build_contact_source_entries_with_last_known():
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var fireteam_id: String = String(contact.get("fireteam_id", "")).strip_edges().to_lower()
		if not selected_lookup.is_empty() and not selected_lookup.has(fireteam_id):
			continue
		if not _fow_allows_contact_visual(contact):
			_fow_hidden_contact_count += 1
			continue
		var position_variant = contact.get("last_known_position", null)
		if typeof(position_variant) != TYPE_VECTOR2:
			continue
		var detection_state: String = String(contact.get("detection_state", "unknown")).strip_edges().to_lower()
		_add_marker3d(_contact_root, Vector2(position_variant), _get_contact_color(detection_state), "Contact_%s" % String(contact.get("unit_id", _contact_count)), 0.36, 0.48, 4)
		var enemy_profile_label: String = String(contact.get("enemy_profile_label", "")).strip_edges()
		if bool(contact.get("enemy_profile_revealed", false)) and not enemy_profile_label.is_empty():
			_add_label3d(_contact_root, enemy_profile_label.to_upper(), _world_to_surface_3d_position(Vector2(position_variant) + Vector2(0.0, -24.0), MOVEMENT_LABEL_HEIGHT + 0.52), "ContactProfile_%s" % String(contact.get("unit_id", _contact_count)), Color(1.0, 0.76, 0.32, 0.95), 11)
		if bool(contact.get("fow_last_known", false)):
			_fow_allowed_contact_count += 1
		_contact_visual_entries.append({
			"unit_id": String(contact.get("unit_id", contact.get("target_id", ""))).strip_edges(),
			"target_id": String(contact.get("target_id", contact.get("unit_id", ""))).strip_edges(),
			"detection_state": detection_state,
			"last_known_position": Vector2(position_variant),
			"fow_last_known": bool(contact.get("fow_last_known", false)),
			"enemy_profile_revealed": bool(contact.get("enemy_profile_revealed", false)),
			"enemy_profile_id": String(contact.get("enemy_profile_id", "")),
			"enemy_profile_label": enemy_profile_label,
		})
		_contact_count += 1


func _build_contact_selected_fireteam_lookup() -> Dictionary:
	var selected_lookup: Dictionary = {}
	for fireteam_id_variant in _contact_selected_fireteam_ids:
		selected_lookup[String(fireteam_id_variant).strip_edges().to_lower()] = true
	return selected_lookup


func _build_contact_source_entries_with_last_known() -> Array:
	var contact_source_entries: Array = _contact_entries.duplicate(true)
	var current_contact_ids: Dictionary = {}
	for current_variant in _contact_entries:
		if typeof(current_variant) != TYPE_DICTIONARY:
			continue
		var current_contact: Dictionary = Dictionary(current_variant)
		var current_id: String = String(current_contact.get("target_id", current_contact.get("unit_id", ""))).strip_edges()
		if not current_id.is_empty():
			current_contact_ids[current_id] = true
	if _is_fog_of_war_visual_filter_active():
		for last_known_variant in _fow_last_known_contacts:
			if typeof(last_known_variant) != TYPE_DICTIONARY:
				continue
			var last_known_contact: Dictionary = Dictionary(last_known_variant).duplicate(true)
			var last_known_id: String = String(last_known_contact.get("target_id", last_known_contact.get("unit_id", ""))).strip_edges()
			if last_known_id.is_empty() or current_contact_ids.has(last_known_id):
				continue
			last_known_contact["fow_last_known"] = true
			last_known_contact["detection_state"] = String(last_known_contact.get("detection_state", "lost")).strip_edges().to_lower()
			contact_source_entries.append(last_known_contact)
	return contact_source_entries


func _rebuild_drop_visuals() -> void:
	_clear_children(_drop_root)
	_dropship_visual_nodes_by_id.clear()
	_dropship_approach_lines_by_id.clear()
	_dropship_approach_arrow_count = 0
	_dropship_lz_label_count = 0
	_dropship_texture_visible = false
	_dropship_model_visible = false
	_missing_dropship_model_count = 0
	_lz_tile_marker_count = 0
	_requested_lz_marker_count = 0
	_resolved_lz_marker_count = 0
	_air_visual_count = 0
	_fow_hidden_air_visual_count = 0
	_air_unknown_terrain_reveal_block_count = 0
	_dropship_air_y = 0.0
	_dropship_surface_y = 0.0
	_dropship_air_clearance = 0.0
	_dropship_rotation_y = 0.0
	if _drop_root == null or _drop_payload.is_empty():
		return
	var show_primary_lz_marker: bool = bool(_drop_payload.get("show_lz_marker", bool(_drop_payload.get("has_lz_position", false))))
	if show_primary_lz_marker and bool(_drop_payload.get("has_lz_position", false)) and typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
		var lz_position: Vector2 = Vector2(_drop_payload.get("lz_position", Vector2.ZERO))
		if _air_layer_allows_surface_marker(lz_position):
			if _add_world_tile_marker(_drop_root, lz_position, Color(0.38, 1.0, 0.62, 0.44), "LZTile", 0.075, DROPSHIP_LZ_MARKER_FILL):
				_lz_tile_marker_count += 1
		else:
			_fow_hidden_air_visual_count += 1
			_air_unknown_terrain_reveal_block_count += 1

	var requested_lz_variant = _drop_payload.get("requested_lz_position", _drop_payload.get("target_lz_position", null))
	if typeof(requested_lz_variant) == TYPE_VECTOR2:
		var requested_lz_position: Vector2 = Vector2(requested_lz_variant)
		if _air_layer_allows_surface_marker(requested_lz_position):
			if _add_world_tile_marker(_drop_root, requested_lz_position, Color(0.42, 0.72, 1.0, 0.42), "RequestedLZTile", 0.075, 1.04):
				_requested_lz_marker_count += 1

	var resolved_lz_variant = _drop_payload.get("resolved_lz_position", _drop_payload.get("actual_landing_position", null))
	if typeof(resolved_lz_variant) == TYPE_VECTOR2:
		var resolved_lz_position: Vector2 = Vector2(resolved_lz_variant)
		if _air_layer_allows_surface_marker(resolved_lz_position):
			if _add_world_tile_marker(_drop_root, resolved_lz_position, Color(1.0, 0.78, 0.28, 0.50), "ResolvedLZTile", 0.105, 0.82):
				_resolved_lz_marker_count += 1

	var dropship_entries: Array = Array(_drop_payload.get("dropship_visuals", []))
	for index in range(dropship_entries.size()):
		var entry: Dictionary = Dictionary(dropship_entries[index])
		if typeof(entry.get("dropship_position", null)) != TYPE_VECTOR2:
			continue
		var ship_position: Vector2 = Vector2(entry.get("dropship_position", Vector2.ZERO))
		var visual_id: String = _get_dropship_visual_id(entry, index)
		var show_entry_lz_marker: bool = bool(entry.get("show_lz_marker", bool(entry.get("has_lz_position", false))))
		if show_entry_lz_marker and bool(entry.get("has_lz_position", false)) and typeof(entry.get("lz_position", null)) == TYPE_VECTOR2:
			var entry_lz_position: Vector2 = Vector2(entry.get("lz_position", Vector2.ZERO))
			if _air_layer_allows_surface_marker(entry_lz_position):
				var lz_color := Color(0.42, 0.72, 1.0, 0.46)
				if bool(entry.get("selected", false)):
					lz_color = Color(0.50, 1.0, 0.66, 0.54)
				if _add_planned_lz_marker(entry_lz_position, lz_color, "DropshipLZ_%s" % _sanitize_node_name(visual_id)):
					_requested_lz_marker_count += 1
					var lz_label: String = String(entry.get("lz_label", entry.get("lz_name", ""))).strip_edges()
					if not lz_label.is_empty():
						_add_label3d(_drop_root, lz_label, _world_to_surface_3d_position(entry_lz_position, 0.62), "DropshipLZLabel_%s" % _sanitize_node_name(visual_id), lz_color.lightened(0.18), 13)
						_dropship_lz_label_count += 1
			else:
				_fow_hidden_air_visual_count += 1
		_add_dropship_approach_line(entry, visual_id, ship_position)
		if not bool(entry.get("dropship_visible", false)):
			continue
		if _air_layer_allows_air_visual_for_payload(entry, ship_position):
			var visual_node := _add_dropship_proxy(ship_position, entry, visual_id)
			if visual_node != null:
				_dropship_visual_nodes_by_id[visual_id] = visual_node
		else:
			_fow_hidden_air_visual_count += 1


func _air_layer_allows_surface_marker(world_position: Vector2) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	var team_id: String = String(_drop_payload.get("team_id", AIR_LAYER_DEFAULT_TEAM_ID)).strip_edges()
	if _fog_of_war_team_id.is_empty() or team_id.is_empty() or team_id == _fog_of_war_team_id:
		return true
	return _fow_is_world_position_currently_visible(world_position)


func _add_planned_lz_marker(world_position: Vector2, color: Color, node_name: String) -> bool:
	return _add_world_tile_marker(_drop_root, world_position, color, node_name, 0.12, DROPSHIP_LZ_MARKER_FILL)


func _air_layer_allows_air_visual(world_position: Vector2) -> bool:
	return _air_layer_allows_air_visual_for_payload(_drop_payload, world_position)


func _air_layer_allows_air_visual_for_payload(payload: Dictionary, world_position: Vector2) -> bool:
	if not _is_fog_of_war_visual_filter_active():
		return true
	var team_id: String = String(payload.get("team_id", AIR_LAYER_DEFAULT_TEAM_ID)).strip_edges()
	if _fog_of_war_team_id.is_empty() or team_id.is_empty() or team_id == _fog_of_war_team_id:
		return true
	return _fow_is_world_position_currently_visible(world_position)


func _world_to_air_layer_3d_position(world_position: Vector2, extra_y_offset: float = 0.0) -> Vector3:
	return _world_to_air_layer_3d_position_for_payload(_drop_payload, world_position, extra_y_offset)


func _world_to_air_layer_3d_position_for_payload(payload: Dictionary, world_position: Vector2, extra_y_offset: float = 0.0) -> Vector3:
	_dropship_surface_y = _get_world_surface_y(world_position)
	_dropship_air_clearance = maxf(float(payload.get("flight_altitude_clearance", AIR_LAYER_DEFAULT_CLEARANCE)) + extra_y_offset, AIR_LAYER_MIN_CLEARANCE)
	_dropship_air_y = _dropship_surface_y + _dropship_air_clearance
	return _world_to_3d_position(world_position, _dropship_air_y)


func _get_dropship_visual_id(entry: Dictionary, index: int) -> String:
	var visual_id: String = String(entry.get("craft_id", entry.get("asset_id", ""))).strip_edges()
	if visual_id.is_empty():
		visual_id = "dropship_%d" % index
	return visual_id


func _add_dropship_approach_line(entry: Dictionary, visual_id: String, ship_position: Vector2) -> void:
	if not bool(entry.get("show_approach_vector", true)):
		return
	var target_position: Vector2
	if typeof(entry.get("approach_vector_target_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(entry.get("approach_vector_target_position", Vector2.ZERO))
	elif typeof(entry.get("dropship_target_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(entry.get("dropship_target_position", Vector2.ZERO))
	elif typeof(entry.get("lz_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(entry.get("lz_position", Vector2.ZERO))
	else:
		return
	var line_origin: Vector2 = _get_dropship_approach_vector_origin(entry, ship_position)
	if line_origin.distance_squared_to(target_position) <= 4.0:
		return
	if not _air_layer_allows_surface_marker(target_position):
		return
	var line := _add_dropship_approach_vector3d(
		_drop_root,
		_world_to_air_layer_3d_position_for_payload(entry, line_origin),
		_world_to_surface_3d_position(target_position, 0.52),
		DROPSHIP_APPROACH_VECTOR_COLOR,
		"DropshipApproach_%s" % _sanitize_node_name(visual_id),
		maxf(_get_3d_cell_size() * DROPSHIP_APPROACH_LINE_WIDTH_FACTOR, 0.08),
		entry
	)
	if line != null:
		_dropship_approach_lines_by_id[visual_id] = line
		if String(entry.get("approach_vector_shape", "wide_arrow")).strip_edges().to_lower() == "wide_arrow":
			_dropship_approach_arrow_count += 1


func _update_dropship_approach_line(entry: Dictionary, visual_id: String, ship_position: Vector2) -> void:
	var line := _dropship_approach_lines_by_id.get(visual_id, null) as MeshInstance3D
	if line == null or not is_instance_valid(line):
		return
	if not bool(entry.get("show_approach_vector", true)):
		line.visible = false
		return
	var target_position: Vector2
	if typeof(entry.get("approach_vector_target_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(entry.get("approach_vector_target_position", Vector2.ZERO))
	elif typeof(entry.get("dropship_target_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(entry.get("dropship_target_position", Vector2.ZERO))
	elif typeof(entry.get("lz_position", null)) == TYPE_VECTOR2:
		target_position = Vector2(entry.get("lz_position", Vector2.ZERO))
	else:
		line.visible = false
		return
	var line_origin: Vector2 = _get_dropship_approach_vector_origin(entry, ship_position)
	line.visible = line_origin.distance_squared_to(target_position) > 4.0
	if not line.visible:
		return
	line.mesh = _make_dropship_approach_vector_mesh(
		_world_to_air_layer_3d_position_for_payload(entry, line_origin),
		_world_to_surface_3d_position(target_position, 0.52),
		DROPSHIP_APPROACH_VECTOR_COLOR,
		maxf(_get_3d_cell_size() * DROPSHIP_APPROACH_LINE_WIDTH_FACTOR, 0.08),
		entry
	)


func _get_dropship_approach_vector_origin(entry: Dictionary, fallback_position: Vector2) -> Vector2:
	if typeof(entry.get("approach_vector_origin_position", null)) == TYPE_VECTOR2:
		return Vector2(entry.get("approach_vector_origin_position", fallback_position))
	return fallback_position


func _get_dropship_approach_line_origin(entry: Dictionary, fallback_position: Vector2) -> Vector2:
	if typeof(entry.get("approach_origin_position", null)) == TYPE_VECTOR2:
		return Vector2(entry.get("approach_origin_position", fallback_position))
	return fallback_position


func _rebuild_status_visuals() -> void:
	_clear_children(_status_root)
	_objective_status_visible = false
	_mission_result_visible = false
	if _status_root == null or _mission_status_payload.is_empty():
		return
	var objective_position_variant = _mission_status_payload.get("objective_position", null)
	if typeof(objective_position_variant) == TYPE_VECTOR2:
		_add_objective_status_visual(Vector2(objective_position_variant))
	if bool(_mission_status_payload.get("mission_resolved", false)):
		_add_mission_result_visual(Vector2(objective_position_variant) if typeof(objective_position_variant) == TYPE_VECTOR2 else _get_map_center_world_position())


func _add_objective_status_visual(world_position: Vector2) -> void:
	var progress: float = clampf(float(_mission_status_payload.get("objective_capture_progress", 0.0)), 0.0, 1.0)
	var capture_radius: float = maxf(float(_mission_status_payload.get("objective_capture_radius", 80.0)), 1.0)
	var ring_radius: float = clampf((capture_radius / maxf(_half_tile_width, 1.0)) * 0.52, 0.48, 2.7)
	var base_color: Color = _get_objective_status_color()
	var zone_mesh := CylinderMesh.new()
	zone_mesh.top_radius = ring_radius
	zone_mesh.bottom_radius = ring_radius
	zone_mesh.height = 0.035
	zone_mesh.radial_segments = 32
	var zone := MeshInstance3D.new()
	zone.name = "ObjectiveCaptureZone"
	zone.mesh = zone_mesh
	zone.material_override = _make_material(Color(base_color.r, base_color.g, base_color.b, 0.18), true)
	zone.position = _world_to_surface_3d_position(world_position, 0.31)
	_status_root.add_child(zone)

	var progress_mesh := CylinderMesh.new()
	progress_mesh.top_radius = maxf(ring_radius * maxf(progress, 0.08), 0.18)
	progress_mesh.bottom_radius = progress_mesh.top_radius
	progress_mesh.height = 0.045
	progress_mesh.radial_segments = 32
	var progress_disc := MeshInstance3D.new()
	progress_disc.name = "ObjectiveCaptureProgress"
	progress_disc.mesh = progress_mesh
	progress_disc.material_override = _make_material(Color(base_color.r, base_color.g, base_color.b, 0.42), true)
	progress_disc.position = _world_to_surface_3d_position(world_position, 0.35)
	_status_root.add_child(progress_disc)

	var label_text: String = _build_objective_status_label_text(progress)
	_add_label3d(_status_root, label_text, _world_to_surface_3d_position(world_position, STATUS_LABEL_HEIGHT), "ObjectiveStatusLabel3D", base_color, 18)
	_objective_status_visible = true


func _add_mission_result_visual(anchor_world_position: Vector2) -> void:
	var result: String = String(_mission_status_payload.get("result", "")).strip_edges().to_upper()
	if result.is_empty():
		result = "RESOLVED"
	var condition: String = String(_mission_status_payload.get("win_condition_type", "")).strip_edges()
	var winning_team: String = String(_mission_status_payload.get("winning_team_id", "")).strip_edges()
	var color := Color(0.56, 1.0, 0.68, 1.0) if result == "VICTORY" else Color(1.0, 0.56, 0.48, 1.0)
	var lines: PackedStringArray = PackedStringArray([result])
	if not winning_team.is_empty():
		lines.append("Winner %s" % winning_team)
	if not condition.is_empty():
		lines.append(condition)
	_add_label3d(_status_root, "\n".join(lines), _world_to_surface_3d_position(anchor_world_position, STATUS_LABEL_HEIGHT + 0.74), "MissionResultLabel3D", color, 22)
	_mission_result_visible = true


func _build_objective_status_label_text(progress: float) -> String:
	var owner_text: String = String(_mission_status_payload.get("objective_owner_team_id", "")).strip_edges()
	if owner_text.is_empty():
		owner_text = "neutral"
	var progress_percent: int = int(round(progress * 100.0))
	var line_two: String = "CAP %d%%" % progress_percent
	if bool(_mission_status_payload.get("objective_contested", false)):
		line_two += " CONTESTED"
	else:
		var capturing_team: String = String(_mission_status_payload.get("objective_capturing_team_id", "")).strip_edges()
		if not capturing_team.is_empty() and capturing_team != owner_text:
			line_two += " -> %s" % capturing_team
	return "OBJ %s\n%s" % [owner_text, line_two]


func _get_objective_status_color() -> Color:
	if bool(_mission_status_payload.get("objective_contested", false)):
		return Color(1.0, 0.78, 0.34, 1.0)
	var owner_text: String = String(_mission_status_payload.get("objective_owner_team_id", "")).strip_edges()
	var capturing_team: String = String(_mission_status_payload.get("objective_capturing_team_id", "")).strip_edges()
	var team_text: String = owner_text if not owner_text.is_empty() else capturing_team
	match team_text:
		"team_alpha":
			return Color(0.45, 0.95, 0.66, 1.0)
		"team_bravo":
			return Color(1.0, 0.52, 0.46, 1.0)
		_:
			return Color(0.86, 0.9, 0.94, 1.0)


func _add_label3d(parent: Node3D, text: String, position: Vector3, node_name: String, color: Color, font_size: int = 18) -> Label3D:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.font_size = font_size
	label.pixel_size = STATUS_LABEL_PIXEL_SIZE
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.92)
	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = position
	parent.add_child(label)
	return label


func _add_dropship_proxy(world_position: Vector2, visual_payload: Dictionary = {}, visual_id: String = "primary") -> Node3D:
	var payload: Dictionary = visual_payload if not visual_payload.is_empty() else _drop_payload
	_dropship_rotation_y = _get_dropship_rotation_y_for_payload(payload, world_position)
	var model_scene := _get_asset_model_scene("fahrzeug_speeder_b_se")
	if model_scene == null:
		model_scene = _get_asset_model_scene_by_name(DROPSHIP_MODEL_NAME)
	if model_scene != null:
		var model_instance := model_scene.instantiate() as Node3D
		if model_instance != null:
			_normalize_asset_model_instance(model_instance)
			var craft_root := Node3D.new()
			var extra_y_offset: float = _get_asset_y_offset("fahrzeug_speeder_b_se")
			craft_root.name = "DropshipModel_%s" % _sanitize_node_name(visual_id)
			craft_root.position = _world_to_air_layer_3d_position_for_payload(payload, world_position, extra_y_offset)
			craft_root.set_meta("flight_altitude_layer", String(payload.get("air_layer", AIR_LAYER_ID)))
			craft_root.set_meta("terrain_height_independent", true)
			craft_root.set_meta("dropship_visual_mode", "model")
			craft_root.set_meta("dropship_extra_y_offset", extra_y_offset)
			craft_root.rotation_degrees.y = _dropship_rotation_y
			craft_root.scale = Vector3.ONE * (_get_asset_model_scale("fahrzeug_speeder_b_se") if _has_model_mapping_for_type("fahrzeug_speeder_b_se") else DROPSHIP_MODEL_SCALE)
			craft_root.add_child(model_instance)
			_drop_root.add_child(craft_root)
			_dropship_model_visible = true
			_air_visual_count += 1
			return craft_root

	if _uses_strict_3d_asset_mapping():
		_add_runtime_missing_asset_marker(
			_drop_root,
			_world_to_air_layer_3d_position_for_payload(payload, world_position),
			"MissingAsset_dropship_model_%s" % _sanitize_node_name(visual_id)
		)
		_missing_dropship_model_count = 1
		return null

	var dropship_texture := payload.get("dropship_texture", null) as Texture2D
	if dropship_texture == null:
		dropship_texture = DEFAULT_DROPSHIP_TEXTURE
	var sprite := _add_texture_card(
		_drop_root,
		dropship_texture,
		_world_to_air_layer_3d_position_for_payload(payload, world_position),
		"DropshipTexture_%s" % _sanitize_node_name(visual_id),
		DROPSHIP_TEXTURE_PIXEL_SIZE
	)
	if sprite != null:
		sprite.set_meta("flight_altitude_layer", String(payload.get("air_layer", AIR_LAYER_ID)))
		sprite.set_meta("terrain_height_independent", true)
		sprite.set_meta("dropship_visual_mode", "texture")
		sprite.set_meta("dropship_extra_y_offset", 0.0)
		_dropship_texture_visible = true
		_air_visual_count += 1
		return sprite

	var proxy_root := Node3D.new()
	proxy_root.name = "DropshipProxy_%s" % _sanitize_node_name(visual_id)
	proxy_root.position = _world_to_air_layer_3d_position_for_payload(payload, world_position)
	proxy_root.rotation_degrees.y = -_camera_yaw_degrees
	proxy_root.set_meta("flight_altitude_layer", String(payload.get("air_layer", AIR_LAYER_ID)))
	proxy_root.set_meta("terrain_height_independent", true)
	proxy_root.set_meta("dropship_visual_mode", "proxy")
	proxy_root.set_meta("dropship_extra_y_offset", 0.0)
	_drop_root.add_child(proxy_root)
	var body_mesh := _make_box_mesh(Vector3(2.9, 0.46, 1.25))
	var body := MeshInstance3D.new()
	body.name = "DropshipProxy"
	body.mesh = body_mesh
	body.material_override = _make_material(Color(0.95, 0.76, 0.32, 0.96))
	proxy_root.add_child(body)
	_air_visual_count += 1

	var wing_mesh := _make_box_mesh(Vector3(1.05, 0.16, 2.45))
	var wing := MeshInstance3D.new()
	wing.name = "DropshipWing"
	wing.mesh = wing_mesh
	wing.material_override = _make_material(Color(0.72, 0.76, 0.78, 0.88))
	wing.position = Vector3(0.0, -0.04, 0.0)
	proxy_root.add_child(wing)
	return proxy_root


func _get_dropship_rotation_y(world_position: Vector2) -> float:
	return _get_dropship_rotation_y_for_payload(_drop_payload, world_position)


func _get_dropship_rotation_y_for_payload(payload: Dictionary, world_position: Vector2) -> float:
	if typeof(payload.get("dropship_target_position", null)) == TYPE_VECTOR2:
		var target_position: Vector2 = Vector2(payload.get("dropship_target_position", world_position))
		return _get_dropship_model_yaw(world_position, target_position, -_camera_yaw_degrees)
	if typeof(payload.get("lz_position", null)) == TYPE_VECTOR2:
		return _get_dropship_model_yaw(world_position, Vector2(payload.get("lz_position", Vector2.ZERO)), -_camera_yaw_degrees)
	return wrapf(-_camera_yaw_degrees + DROPSHIP_MODEL_FORWARD_ROTATION_OFFSET_DEGREES, 0.0, 360.0)


func _get_dropship_model_yaw(from_world_position: Vector2, to_world_position: Vector2, fallback_yaw: float = 0.0) -> float:
	var direction_yaw: float = _get_world_direction_yaw(from_world_position, to_world_position, fallback_yaw)
	return wrapf(direction_yaw + DROPSHIP_MODEL_FORWARD_ROTATION_OFFSET_DEGREES, 0.0, 360.0)


func _maybe_emit_unit_step_sfx(
	unit_id: String,
	world_position: Vector2,
	unit_is_moving: bool,
	unit_is_visible: bool,
	surface_type_override: String = "",
	now_msec_override: int = -1
) -> Dictionary:
	if unit_id.strip_edges().is_empty():
		return {"played": false, "reason": "missing_unit_id"}
	if not unit_is_visible:
		return {"played": false, "reason": "hidden_unit"}
	if not unit_is_moving:
		return {"played": false, "reason": "unit_not_moving"}
	var now_msec: int = now_msec_override if now_msec_override >= 0 else Time.get_ticks_msec()
	var ready_msec: int = int(_movement_step_ready_at_msec.get(unit_id, 0))
	if now_msec < ready_msec:
		_movement_step_sfx_suppressed_rate_limit_count += 1
		return {"played": false, "reason": "movement_step_rate_limited"}
	var bus = _ensure_audio_event_bus()
	if bus == null or not bus.has_method("emit_movement_step"):
		return {"played": false, "reason": "missing_audio_event_bus"}
	var surface_type: String = surface_type_override.strip_edges().to_lower()
	if surface_type.is_empty():
		surface_type = _get_surface_type_for_world_position(world_position)
	var result: Dictionary = Dictionary(bus.call("emit_movement_step", surface_type, {
		"position": _world_to_surface_3d_position(world_position, 0.08),
		"unit_id": unit_id,
		"source": "terrain_unit_proxy",
		"visible_to_local": true,
		"visibility_context": "visible_unit_proxy",
		"dedupe_key": "step:%s" % unit_id,
		"dedupe_window_msec": MOVEMENT_STEP_SFX_RATE_LIMIT_MSEC,
		"now_msec": now_msec,
	})).duplicate(true)
	if bool(result.get("played", false)):
		_movement_step_ready_at_msec[unit_id] = now_msec + MOVEMENT_STEP_SFX_RATE_LIMIT_MSEC
		_movement_step_sfx_count += 1
		_movement_step_sfx_entries.append({
			"unit_id": unit_id,
			"surface_type": surface_type,
			"event_id": String(result.get("event_id", "")),
			"position": world_position,
			"now_msec": now_msec,
		})
		if _movement_step_sfx_entries.size() > 24:
			_movement_step_sfx_entries.pop_front()
	else:
		_movement_step_sfx_suppressed_rate_limit_count += 1
	return result


func _get_surface_type_for_world_position(world_position: Vector2) -> String:
	if _terrain_map_data == null:
		return "neutral"
	var grid_position: Vector2i = _world_to_grid_position(world_position)
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return "neutral"
	var surface_type: String = String(tile_data.surface_type).strip_edges().to_lower()
	if surface_type.is_empty():
		return "neutral"
	return surface_type


func _sync_unit_proxies(force_rebuild: bool = false, delta: float = -1.0) -> void:
	_ensure_nodes()
	if _unit_root == null:
		return
	var seen_ids: Dictionary = {}
	var unit_texture_count: int = 0
	var unit_model_count: int = 0
	var animated_unit_model_count: int = 0
	var unit_visual_error_count: int = 0
	var unit_animation_player_count: int = 0
	var unit_animation_error_count: int = 0
	var unit_helmet_attachment_count: int = 0
	var unit_helmet_error_count: int = 0
	var unit_skeleton_count: int = 0
	var unit_socket_count: int = 0
	var unit_socket_fallback_count: int = 0
	var unit_head_socket_count: int = 0
	var unit_right_hand_socket_count: int = 0
	var unit_animation_retarget_fallback_count: int = 0
	var unit_blaster_attachment_count: int = 0
	var unit_blaster_error_count: int = 0
	var unit_visual_loadout_count: int = 0
	var unit_visual_loadout_error_count: int = 0
	var enemy_animated_unit_model_count: int = 0
	var unit_status_badge_count: int = 0
	var missing_unit_model_count: int = 0
	var fow_hidden_unit_proxy_count: int = 0
	var changed: bool = false
	for unit in _unit_nodes:
		if not is_instance_valid(unit):
			continue
		var unit_id: String = _get_unit_id(unit)
		if unit_id.is_empty():
			continue
		seen_ids[unit_id] = true
		var proxy := _unit_proxies_by_id.get(unit_id, null) as Node3D
		if proxy == null or force_rebuild or not is_instance_valid(proxy):
			if proxy != null and is_instance_valid(proxy):
				proxy.queue_free()
			proxy = _create_unit_proxy(unit)
			proxy.name = "UnitProxy_%s" % unit_id
			_unit_root.add_child(proxy)
			_unit_proxies_by_id[unit_id] = proxy
			changed = true
		var base_visible: bool = _is_unit_base_world_visible(unit)
		var fow_allowed: bool = _fow_allows_unit_proxy(unit)
		if base_visible and not fow_allowed:
			fow_hidden_unit_proxy_count += 1
		var next_visible: bool = base_visible and fow_allowed
		if proxy.visible != next_visible:
			changed = true
		proxy.visible = next_visible
		proxy.set_meta("unit_id", unit_id)
		proxy.set_meta("team_id", _get_unit_team_id(unit))
		proxy.set_meta("vital_state", _get_unit_vital_state(unit))
		proxy.set_meta("overwatch_ready", bool(unit.get_meta("overwatch_ready", false)) if unit != null and unit.has_meta("overwatch_ready") else false)
		proxy.set_meta("overwatch_shot_ready", bool(unit.get_meta("overwatch_shot_ready", false)) if unit != null and unit.has_meta("overwatch_shot_ready") else false)
		proxy.set_meta("overwatch_cooldown_remaining_ticks", int(unit.get_meta("overwatch_cooldown_remaining_ticks", 0)) if unit != null and unit.has_meta("overwatch_cooldown_remaining_ticks") else 0)
		var active_fire_event: Dictionary = _get_active_fire_event_for_unit(unit_id)
		var runtime_posture: Dictionary = _get_unit_runtime_posture_snapshot(unit)
		var displayed_weapon_posture: String = "aimed" if not active_fire_event.is_empty() else String(runtime_posture.get("weapon_posture", "lowered"))
		var displayed_movement_posture: String = "engage" if not active_fire_event.is_empty() else String(runtime_posture.get("movement_posture", "idle"))
		proxy.set_meta("unit_movement_posture", displayed_movement_posture)
		proxy.set_meta("unit_weapon_posture", displayed_weapon_posture)
		proxy.set_meta("unit_runtime_weapon_posture", String(runtime_posture.get("weapon_posture", "lowered")))
		proxy.set_meta("unit_posture_policy_id", String(runtime_posture.get("posture_policy_id", "")))
		proxy.set_meta("unit_posture_source", "fire_event" if not active_fire_event.is_empty() else "runtime")
		proxy.set_meta("unit_aim_pose_active", displayed_weapon_posture == "aimed")
		proxy.set_meta("unit_ready_pose_active", displayed_weapon_posture == "ready")
		proxy.set_meta("unit_aim_pose_source_event_id", String(active_fire_event.get("event_id", "")))
		proxy.set_meta("unit_aim_pose_target_unit_id", String(active_fire_event.get("target_unit_id", "")))
		var unit_is_moving: bool = false
		var weapon_pose_direction: Vector2 = Vector2.ZERO
		if unit is Node2D:
			var unit_world_position: Vector2 = (unit as Node2D).global_position
			if not active_fire_event.is_empty():
				weapon_pose_direction = _get_fire_event_direction_for_unit(active_fire_event, unit_world_position)
			if weapon_pose_direction.length_squared() <= 0.0001:
				weapon_pose_direction = _resolve_unit_aim_direction(unit, unit_world_position)
			var next_position: Vector3 = _world_to_surface_3d_position(unit_world_position, 0.06)
			var proxy_distance: float = proxy.position.distance_to(next_position)
			unit_is_moving = proxy_distance > 0.01
			_maybe_emit_unit_step_sfx(unit_id, unit_world_position, unit_is_moving, next_visible)
			if proxy_distance > 0.0001:
				changed = true
			if force_rebuild or delta <= 0.0 or proxy_distance >= UNIT_PROXY_SNAP_DISTANCE:
				proxy.position = next_position
			else:
				proxy.position = proxy.position.lerp(next_position, clampf(delta * UNIT_PROXY_SMOOTH_SPEED, 0.0, 1.0))
			var next_rotation_y: float = _get_unit_proxy_rotation_y(proxy, unit, unit_world_position, active_fire_event)
			if absf(wrapf(proxy.rotation_degrees.y - next_rotation_y, -180.0, 180.0)) > 0.01:
				changed = true
			proxy.rotation_degrees.y = next_rotation_y
			proxy.set_meta("last_world_position", unit_world_position)
		else:
			var next_rotation_y: float = proxy.rotation_degrees.y
			if not proxy.has_meta("last_rotation_y"):
				next_rotation_y = 0.0
			if absf(wrapf(proxy.rotation_degrees.y - next_rotation_y, -180.0, 180.0)) > 0.01:
				changed = true
			proxy.rotation_degrees.y = next_rotation_y
		proxy.set_meta("last_rotation_y", proxy.rotation_degrees.y)
		if _update_unit_visual_animation(proxy, unit_is_moving, displayed_weapon_posture == "aimed"):
			changed = true
		if _update_unit_weapon_aim_pose(proxy, active_fire_event, displayed_weapon_posture, weapon_pose_direction):
			changed = true
		if _update_unit_status_badge(proxy, unit):
			unit_status_badge_count += 1
		if bool(proxy.get_meta("uses_unit_texture", false)):
			unit_texture_count += 1
		if bool(proxy.get_meta("uses_kenney_model", false)):
			unit_model_count += 1
		if bool(proxy.get_meta("uses_animated_character_model", false)):
			animated_unit_model_count += 1
			if _get_unit_team_id(unit) != "team_alpha":
				enemy_animated_unit_model_count += 1
		if bool(proxy.get_meta("unit_visual_error", false)):
			unit_visual_error_count += 1
		if bool(proxy.get_meta("unit_animation_player_available", false)):
			unit_animation_player_count += 1
		if bool(proxy.get_meta("unit_animation_error", false)):
			unit_animation_error_count += 1
		if bool(proxy.get_meta("unit_helmet_attachment_available", false)):
			unit_helmet_attachment_count += 1
		if bool(proxy.get_meta("unit_helmet_error", false)):
			unit_helmet_error_count += 1
		if bool(proxy.get_meta("unit_skeleton_available", false)):
			unit_skeleton_count += 1
		unit_socket_count += int(proxy.get_meta("unit_socket_count", 0))
		unit_socket_fallback_count += int(proxy.get_meta("unit_socket_fallback_count", 0))
		if bool(proxy.get_meta("unit_head_socket_available", false)):
			unit_head_socket_count += 1
		if bool(proxy.get_meta("unit_right_hand_socket_available", false)):
			unit_right_hand_socket_count += 1
		unit_animation_retarget_fallback_count += int(proxy.get_meta("unit_animation_retarget_fallback_count", 0))
		if bool(proxy.get_meta("unit_blaster_attachment_available", false)):
			unit_blaster_attachment_count += 1
		if bool(proxy.get_meta("unit_blaster_error", false)):
			unit_blaster_error_count += 1
		if bool(proxy.get_meta("unit_visual_loadout_available", false)):
			unit_visual_loadout_count += 1
		if bool(proxy.get_meta("unit_visual_loadout_error", false)):
			unit_visual_loadout_error_count += 1
		if bool(proxy.get_meta("missing_unit_model", false)):
			missing_unit_model_count += 1
	for unit_id_variant in _unit_proxies_by_id.keys():
		var unit_id := String(unit_id_variant)
		if seen_ids.has(unit_id):
			continue
		var proxy_to_remove := _unit_proxies_by_id[unit_id] as Node
		if proxy_to_remove != null and is_instance_valid(proxy_to_remove):
			proxy_to_remove.queue_free()
		_unit_proxies_by_id.erase(unit_id)
		changed = true
	if _unit_texture_count != unit_texture_count:
		changed = true
	_unit_texture_count = unit_texture_count
	if _unit_model_count != unit_model_count:
		changed = true
	_unit_model_count = unit_model_count
	if _animated_unit_model_count != animated_unit_model_count:
		changed = true
	_animated_unit_model_count = animated_unit_model_count
	if _unit_visual_error_count != unit_visual_error_count:
		changed = true
	_unit_visual_error_count = unit_visual_error_count
	if _unit_animation_player_count != unit_animation_player_count:
		changed = true
	_unit_animation_player_count = unit_animation_player_count
	if _unit_animation_error_count != unit_animation_error_count:
		changed = true
	_unit_animation_error_count = unit_animation_error_count
	if _unit_helmet_attachment_count != unit_helmet_attachment_count:
		changed = true
	_unit_helmet_attachment_count = unit_helmet_attachment_count
	if _unit_helmet_error_count != unit_helmet_error_count:
		changed = true
	_unit_helmet_error_count = unit_helmet_error_count
	if _unit_skeleton_count != unit_skeleton_count:
		changed = true
	_unit_skeleton_count = unit_skeleton_count
	if _unit_socket_count != unit_socket_count:
		changed = true
	_unit_socket_count = unit_socket_count
	if _unit_socket_fallback_count != unit_socket_fallback_count:
		changed = true
	_unit_socket_fallback_count = unit_socket_fallback_count
	if _unit_head_socket_count != unit_head_socket_count:
		changed = true
	_unit_head_socket_count = unit_head_socket_count
	if _unit_right_hand_socket_count != unit_right_hand_socket_count:
		changed = true
	_unit_right_hand_socket_count = unit_right_hand_socket_count
	if _unit_animation_retarget_fallback_count != unit_animation_retarget_fallback_count:
		changed = true
	_unit_animation_retarget_fallback_count = unit_animation_retarget_fallback_count
	if _unit_blaster_attachment_count != unit_blaster_attachment_count:
		changed = true
	_unit_blaster_attachment_count = unit_blaster_attachment_count
	if _unit_blaster_error_count != unit_blaster_error_count:
		changed = true
	_unit_blaster_error_count = unit_blaster_error_count
	if _unit_visual_loadout_count != unit_visual_loadout_count:
		changed = true
	_unit_visual_loadout_count = unit_visual_loadout_count
	if _unit_visual_loadout_error_count != unit_visual_loadout_error_count:
		changed = true
	_unit_visual_loadout_error_count = unit_visual_loadout_error_count
	if _enemy_animated_unit_model_count != enemy_animated_unit_model_count:
		changed = true
	_enemy_animated_unit_model_count = enemy_animated_unit_model_count
	if _unit_status_badge_count != unit_status_badge_count:
		changed = true
	_unit_status_badge_count = unit_status_badge_count
	if _missing_unit_model_count != missing_unit_model_count:
		changed = true
	_missing_unit_model_count = missing_unit_model_count
	if _fow_hidden_unit_proxy_count != fow_hidden_unit_proxy_count:
		changed = true
	_fow_hidden_unit_proxy_count = fow_hidden_unit_proxy_count
	if changed:
		_request_viewport_redraw()


func _get_unit_runtime_posture_snapshot(unit: Node) -> Dictionary:
	var result: Dictionary = {
		"movement_posture": "idle",
		"weapon_posture": "lowered",
		"posture_policy_id": "",
	}
	if unit == null or not unit.has_method("get_runtime_status"):
		return result
	var runtime_status = unit.call("get_runtime_status")
	if runtime_status == null or not runtime_status.has_method("get"):
		return result
	result["movement_posture"] = _normalize_unit_movement_posture(String(runtime_status.get("movement_posture")))
	result["weapon_posture"] = _normalize_unit_weapon_posture(String(runtime_status.get("weapon_posture")))
	result["posture_policy_id"] = String(runtime_status.get("posture_policy_id")).strip_edges().to_lower()
	return result


func _normalize_unit_movement_posture(value: String) -> String:
	match value.strip_edges().to_lower():
		"travel", "walk", "move", "march":
			return "travel"
		"tactical", "ready", "m_position", "m-position":
			return "tactical"
		"engage", "engaging", "aim", "aimed":
			return "engage"
		"overwatch", "hold", "watch":
			return "overwatch"
		_:
			return "idle"


func _normalize_unit_weapon_posture(value: String) -> String:
	match value.strip_edges().to_lower():
		"ready", "ready_low", "ready-low", "m_position", "m-position":
			return "ready"
		"aim", "aimed", "firing", "shooting":
			return "aimed"
		_:
			return "lowered"


func _update_unit_status_badge(proxy: Node3D, unit: Node) -> bool:
	if proxy == null:
		return false
	var label := proxy.get_node_or_null("UnitStateBadge") as Label3D
	var badge_text: String = _get_unit_status_badge_text(unit)
	if badge_text.is_empty() or not proxy.visible:
		if label != null:
			label.visible = false
		return false
	if label == null:
		label = _add_label3d(proxy, badge_text, Vector3(0.0, 0.98, 0.0), "UnitStateBadge", _get_unit_status_badge_color(unit), 13)
		label.pixel_size = 0.014
		label.outline_size = 3
	else:
		label.text = badge_text
		label.modulate = _get_unit_status_badge_color(unit)
		label.visible = true
	return true


func _get_unit_status_badge_text(unit: Node) -> String:
	if unit == null:
		return ""
	var vital_state: String = ""
	if unit.has_method("get_vital_state"):
		vital_state = String(unit.call("get_vital_state")).strip_edges().to_lower()
	if not vital_state.is_empty() and vital_state != "fit":
		if vital_state == "respawning":
			var respawn_seconds: int = _get_unit_respawn_remaining_seconds(unit)
			return "RESPAWN %ds" % respawn_seconds if respawn_seconds > 0 else "RESPAWN"
		return vital_state.to_upper()
	if unit.has_method("is_in_contact") and bool(unit.call("is_in_contact")):
		return "CONTACT"
	if bool(unit.get_meta("overwatch_ready", false)):
		return "OVW"
	var runtime_status = unit.call("get_runtime_status") if unit.has_method("get_runtime_status") else null
	var status_text: String = ""
	var source_command: String = ""
	if runtime_status != null:
		status_text = String(runtime_status.get("status")).strip_edges().to_lower() if runtime_status.has_method("get") else ""
		source_command = String(runtime_status.get("source_command_type")).strip_edges().to_lower() if runtime_status.has_method("get") else ""
	if source_command == "take":
		return "TAKE"
	if source_command == "defend":
		return "DEFEND"
	if source_command == "flank":
		return "FLANK"
	match status_text:
		"pending_move":
			return "MOVE"
		"engaging":
			return "ENGAGE"
		"holding":
			return "HOLD"
		"assigned":
			return "READY"
		"idle":
			return "IDLE"
		_:
			return ""


func _get_unit_status_badge_color(unit: Node) -> Color:
	if unit != null and unit.has_method("get_team_id") and String(unit.call("get_team_id")).strip_edges() != "team_alpha":
		return Color(1.0, 0.56, 0.46, 1.0)
	var vital_state: String = String(unit.call("get_vital_state")).strip_edges().to_lower() if unit != null and unit.has_method("get_vital_state") else ""
	match vital_state:
		"down", "bleedout":
			return Color(1.0, 0.42, 0.38, 1.0)
		"respawning":
			return Color(0.72, 0.9, 1.0, 1.0)
	if unit != null and unit.has_method("is_in_contact") and bool(unit.call("is_in_contact")):
		return Color(1.0, 0.78, 0.34, 1.0)
	if unit != null and bool(unit.get_meta("overwatch_ready", false)):
		if not bool(unit.get_meta("overwatch_shot_ready", true)):
			return Color(0.48, 0.72, 0.78, 0.9)
		return Color(0.46, 0.98, 0.92, 1.0)
	return Color(0.62, 0.92, 1.0, 1.0)


func _get_unit_respawn_remaining_seconds(unit: Node) -> int:
	if unit == null:
		return 0
	if unit.has_method("get_respawn_remaining_seconds"):
		return maxi(int(unit.call("get_respawn_remaining_seconds")), 0)
	if unit.has_meta("respawn_remaining_seconds"):
		return maxi(int(unit.get_meta("respawn_remaining_seconds", 0)), 0)
	return 0


func _get_unit_proxy_rotation_y(proxy: Node3D, unit: Node, current_world_position: Vector2, active_fire_event: Dictionary = {}) -> float:
	var fallback_yaw: float = proxy.rotation_degrees.y if proxy != null else 0.0
	if not active_fire_event.is_empty():
		var fire_direction: Vector2 = _get_fire_event_direction_for_unit(active_fire_event, current_world_position)
		if fire_direction.length_squared() > 0.0001:
			return _get_world_direction_yaw(current_world_position, current_world_position + fire_direction, fallback_yaw)
	var explicit_facing_direction: Vector2 = _resolve_unit_explicit_facing_direction(unit)
	if explicit_facing_direction.length_squared() > 0.0001:
		return _get_world_direction_yaw(current_world_position, current_world_position + explicit_facing_direction, fallback_yaw)
	var motion_or_target_direction: Vector2 = _resolve_unit_motion_or_target_direction(proxy, unit, current_world_position)
	if motion_or_target_direction.length_squared() > 0.0001:
		return _get_world_direction_yaw(current_world_position, current_world_position + motion_or_target_direction, fallback_yaw)
	var target_position: Variant = unit.call("get_target_position") if unit != null and unit.has_method("get_target_position") else null
	if typeof(target_position) == TYPE_VECTOR2:
		var target_world_position: Vector2 = Vector2(target_position)
		if current_world_position.distance_squared_to(target_world_position) > 0.25:
			return _get_world_direction_yaw(current_world_position, target_world_position, fallback_yaw)

	if proxy != null and proxy.has_meta("last_world_position"):
		var previous_position: Variant = proxy.get_meta("last_world_position")
		if typeof(previous_position) == TYPE_VECTOR2:
			var previous_world_position: Vector2 = Vector2(previous_position)
			if previous_world_position.distance_squared_to(current_world_position) > 0.01:
				return _get_world_direction_yaw(previous_world_position, current_world_position, fallback_yaw)

	return fallback_yaw


func _get_active_fire_event_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty() or _order_payload.is_empty():
		return {}
	var fire_events: Array = Array(_order_payload.get("fire_event_dicts", []))
	var index: int = fire_events.size() - 1
	while index >= 0:
		var fire_event_variant = fire_events[index]
		index -= 1
		if typeof(fire_event_variant) != TYPE_DICTIONARY:
			continue
		var fire_event: Dictionary = Dictionary(fire_event_variant)
		if String(fire_event.get("attacker_unit_id", "")).strip_edges() != normalized_unit_id:
			continue
		if not _fow_allows_fire_event_visual(fire_event):
			continue
		return fire_event.duplicate(true)
	return {}


func _get_fire_event_direction_for_unit(fire_event: Dictionary, current_world_position: Vector2) -> Vector2:
	var target_position: Vector2 = _get_vector2_from_variant(fire_event.get("target_position", current_world_position), current_world_position)
	if current_world_position.distance_squared_to(target_position) > 0.0001:
		return (target_position - current_world_position).normalized()
	var attacker_position: Vector2 = _get_vector2_from_variant(fire_event.get("attacker_position", current_world_position), current_world_position)
	if attacker_position.distance_squared_to(target_position) > 0.0001:
		return (target_position - attacker_position).normalized()
	return Vector2.ZERO


func _get_vector2_from_variant(value: Variant, fallback: Vector2) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	if typeof(value) == TYPE_VECTOR2I:
		var vector2i_value: Vector2i = value
		return Vector2(vector2i_value.x, vector2i_value.y)
	if typeof(value) == TYPE_ARRAY:
		var values: Array = Array(value)
		if values.size() >= 2:
			return Vector2(float(values[0]), float(values[1]))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", fallback.x)), float(dict.get("y", fallback.y)))
	return fallback


func _get_world_direction_yaw(from_world_position: Vector2, to_world_position: Vector2, fallback_yaw: float = 0.0) -> float:
	var delta_grid: Vector2 = _world_to_grid_float(to_world_position) - _world_to_grid_float(from_world_position)
	if delta_grid.length_squared() <= 0.0001:
		return fallback_yaw
	return wrapf(rad_to_deg(atan2(delta_grid.x, -delta_grid.y)), 0.0, 360.0)


func _create_unit_proxy(unit: Node) -> Node3D:
	var root := Node3D.new()
	var unit_visual_entry: Dictionary = _get_unit_visual_entry(unit)
	var model_scene := _get_unit_model_scene(unit, unit_visual_entry)
	if model_scene != null:
		var model_instance := model_scene.instantiate() as Node3D
		if model_instance != null:
			_normalize_asset_model_instance(model_instance)
			var model_root := Node3D.new()
			model_root.name = "UnitModel_%s" % _get_unit_visual_name(unit, unit_visual_entry)
			model_root.scale = Vector3.ONE * _get_unit_model_scale(unit_visual_entry)
			model_root.rotation_degrees.y = _get_unit_model_root_rotation_y(unit_visual_entry)
			root.set_meta("unit_model_root_rotation_y_degrees", model_root.rotation_degrees.y)
			var material_applied: bool = _apply_unit_visual_material(model_instance, unit_visual_entry)
			if not material_applied and _unit_visual_entry_has_skin(unit_visual_entry):
				_add_runtime_missing_asset_marker(
					root,
					Vector3(0.0, 0.72, 0.0),
					"MissingAsset_unit_skin_%s" % _sanitize_node_name(_get_unit_visual_name(unit, unit_visual_entry))
				)
				root.set_meta("unit_visual_error", true)
			model_root.add_child(model_instance)
			if not unit_visual_entry.is_empty():
				var visual_archetype_id: String = String(unit_visual_entry.get("resolved_visual_archetype_id", unit_visual_entry.get("visual_archetype_id", ""))).strip_edges()
				if not visual_archetype_id.is_empty():
					root.set_meta("unit_visual_archetype_id", visual_archetype_id)
				var faction_id: String = String(unit_visual_entry.get("faction_id", "")).strip_edges()
				if not faction_id.is_empty():
					root.set_meta("unit_visual_faction_id", faction_id)
				var visual_loadout_id: String = String(unit_visual_entry.get("resolved_visual_loadout_id", "")).strip_edges()
				if not visual_loadout_id.is_empty():
					root.set_meta("unit_visual_loadout_available", true)
					root.set_meta("unit_visual_loadout_id", visual_loadout_id)
				if bool(unit_visual_entry.get("visual_loadout_error", false)):
					root.set_meta("unit_visual_loadout_error", true)
					root.set_meta("unit_visual_error", true)
				if _setup_unit_visual_animation(root, model_root, model_instance, unit_visual_entry):
					root.set_meta("unit_animation_player_available", true)
				else:
					root.set_meta("unit_animation_error", true)
					root.set_meta("unit_visual_error", true)
				_setup_unit_visual_sockets(root, model_root, model_instance, unit_visual_entry)
				if _attach_unit_helmet(root, model_root, model_instance, unit_visual_entry):
					root.set_meta("unit_helmet_attachment_available", true)
				elif _unit_visual_entry_has_helmet(unit_visual_entry):
					root.set_meta("unit_helmet_error", true)
					root.set_meta("unit_visual_error", true)
				if _attach_unit_blaster(root, model_root, model_instance, unit_visual_entry):
					root.set_meta("unit_blaster_attachment_available", true)
				elif _unit_visual_entry_has_blaster(unit_visual_entry):
					root.set_meta("unit_blaster_error", true)
					root.set_meta("unit_visual_error", true)
			root.add_child(model_root)
			root.set_meta("uses_kenney_model", true)
			if not unit_visual_entry.is_empty():
				root.set_meta("uses_animated_character_model", true)

	if not bool(root.get_meta("uses_kenney_model", false)) and _uses_strict_3d_asset_mapping():
		_add_runtime_missing_asset_marker(
			root,
			Vector3(0.0, 0.42, 0.0),
			"MissingAsset_unit_model_%s" % _sanitize_node_name(_get_unit_visual_name(unit, unit_visual_entry))
		)
		root.set_meta("missing_unit_model", true)
		if not unit_visual_entry.is_empty():
			root.set_meta("unit_visual_error", true)
	elif not bool(root.get_meta("uses_kenney_model", false)):
		var unit_texture := _get_unit_visual_texture(unit)
		if unit_texture != null:
			var unit_card := _add_texture_card(root, unit_texture, Vector3(0.0, 0.34, 0.0), "UnitTexture", UNIT_TEXTURE_PIXEL_SIZE)
			if unit_card != null:
				root.set_meta("uses_unit_texture", true)
				var weapon_texture := _get_unit_weapon_visual_texture(unit)
				if weapon_texture != null:
					_add_texture_card(root, weapon_texture, Vector3(0.0, 0.36, 0.0), "UnitWeaponTexture", UNIT_TEXTURE_PIXEL_SIZE, _get_unit_weapon_visual_offset(unit))

	if not bool(root.get_meta("uses_kenney_model", false)) and not bool(root.get_meta("uses_unit_texture", false)) and not bool(root.get_meta("missing_unit_model", false)):
		var body := MeshInstance3D.new()
		var mesh := CapsuleMesh.new()
		mesh.radius = UNIT_FALLBACK_BODY_RADIUS
		mesh.height = UNIT_FALLBACK_BODY_HEIGHT
		body.mesh = mesh
		body.material_override = _make_material(_get_unit_color(unit))
		root.add_child(body)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = UNIT_BASE_RADIUS
	base_mesh.bottom_radius = UNIT_BASE_RADIUS
	base_mesh.height = UNIT_BASE_HEIGHT
	base_mesh.radial_segments = 16
	base.mesh = base_mesh
	base.material_override = _make_material(Color(0.05, 0.08, 0.1, 0.72), true)
	base.position.y = -0.02
	root.add_child(base)
	return root


func _setup_unit_visual_animation(proxy_root: Node3D, model_root: Node3D, model_instance: Node3D, unit_visual_entry: Dictionary) -> bool:
	var animation_paths: Dictionary = _get_unit_animation_paths(unit_visual_entry)
	if animation_paths.is_empty():
		return true
	var animation_player := AnimationPlayer.new()
	animation_player.name = "UnitVisualAnimationPlayer"
	var library := AnimationLibrary.new()
	var expected_count: int = 0
	var imported_count: int = 0
	for animation_name_variant in animation_paths.keys():
		var animation_name: String = String(animation_name_variant).strip_edges().to_lower()
		var animation_path: String = String(animation_paths[animation_name_variant]).strip_edges()
		if animation_name.is_empty() or animation_path.is_empty():
			continue
		expected_count += 1
		var animation: Animation = _load_animation_from_scene(animation_path, animation_name)
		if animation == null:
			continue
		var duplicated := animation.duplicate(true) as Animation
		if duplicated == null:
			continue
		duplicated.loop_mode = Animation.LOOP_LINEAR
		animation_player.set_meta("source_animation_%s" % animation_name, String(duplicated.get_meta("source_animation_name", "")))
		library.add_animation(animation_name, duplicated)
		imported_count += 1
	if imported_count > 0:
		animation_player.add_animation_library("", library)
		model_root.add_child(animation_player)
		animation_player.root_node = animation_player.get_path_to(model_instance)
		model_root.set_meta("unit_animation_player_node", String(animation_player.name))
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
	if expected_count == 0 or imported_count < expected_count:
		_add_runtime_missing_asset_marker(
			proxy_root,
			Vector3(0.0, 0.64, 0.0),
			"MissingAsset_unit_animation_%s" % _sanitize_node_name(_get_unit_visual_name(null, unit_visual_entry))
		)
		return false
	return true


func _load_animation_from_scene(animation_scene_path: String, preferred_animation_name: String = "") -> Animation:
	if not ResourceLoader.exists(animation_scene_path):
		return null
	var animation_scene := _get_asset_model_scene_by_path(animation_scene_path)
	if animation_scene == null:
		return null
	var animation_root := animation_scene.instantiate()
	if animation_root == null:
		return null
	var animation: Animation = _find_best_animation(animation_root, preferred_animation_name)
	animation_root.free()
	return animation


func _find_best_animation(node: Node, preferred_animation_name: String = "") -> Animation:
	var animation_player := node as AnimationPlayer
	if animation_player != null:
		var preferred_text: String = preferred_animation_name.strip_edges().to_lower()
		if not preferred_text.is_empty():
			for animation_name in animation_player.get_animation_list():
				var name_text: String = String(animation_name)
				var normalized_name: String = name_text.strip_edges().to_lower()
				if normalized_name == "reset" or normalized_name.find("targeting pose") >= 0:
					continue
				if normalized_name.find(preferred_text) >= 0:
					var preferred_animation := animation_player.get_animation(name_text)
					if preferred_animation != null:
						preferred_animation.set_meta("source_animation_name", name_text)
						return preferred_animation
		for animation_name in animation_player.get_animation_list():
			var name_text: String = String(animation_name)
			var normalized_name: String = name_text.strip_edges().to_lower()
			if normalized_name.is_empty() or normalized_name == "reset" or normalized_name.find("targeting pose") >= 0:
				continue
			var animation := animation_player.get_animation(name_text)
			if animation != null:
				animation.set_meta("source_animation_name", name_text)
				return animation
	for child in node.get_children():
		var child_animation: Animation = _find_best_animation(child, preferred_animation_name)
		if child_animation != null:
			return child_animation
	return null


func _update_unit_visual_animation(proxy: Node3D, is_moving: bool, is_firing: bool = false) -> bool:
	var animation_player: AnimationPlayer = _find_unit_visual_animation_player(proxy)
	if animation_player == null:
		return false
	var desired_animation: String = "walk" if is_moving else "idle"
	if is_firing:
		for candidate in ["shoot", "attack", "fire", "idle"]:
			if animation_player.has_animation(candidate):
				desired_animation = candidate
				break
	if not animation_player.has_animation(desired_animation):
		return false
	if animation_player.current_animation == desired_animation and animation_player.is_playing():
		return false
	animation_player.play(desired_animation)
	return true


func _update_unit_weapon_aim_pose(proxy: Node3D, active_fire_event: Dictionary, weapon_posture: String = "lowered", aim_direction: Vector2 = Vector2.ZERO) -> bool:
	if proxy == null:
		return false
	var normalized_weapon_posture: String = _normalize_unit_weapon_posture("aimed" if not active_fire_event.is_empty() else weapon_posture)
	var is_active: bool = normalized_weapon_posture == "aimed"
	var is_ready: bool = normalized_weapon_posture == "ready"
	var changed: bool = false
	var weapon_node: Node3D = _find_unit_blaster_visual_node(proxy)
	proxy.set_meta("unit_aim_pose_weapon_node_available", weapon_node != null)
	var aim_yaw_delta_degrees: float = 0.0
	var has_aim_yaw: bool = false
	if (is_active or is_ready) and aim_direction.length_squared() > 0.0001:
		var aim_yaw_degrees: float = _get_world_direction_yaw(Vector2.ZERO, aim_direction.normalized(), proxy.rotation_degrees.y)
		aim_yaw_delta_degrees = wrapf(aim_yaw_degrees - proxy.rotation_degrees.y, -180.0, 180.0)
		has_aim_yaw = true
	if absf(float(proxy.get_meta("unit_aim_pose_yaw_delta_degrees", 0.0)) - aim_yaw_delta_degrees) > 0.01:
		proxy.set_meta("unit_aim_pose_yaw_delta_degrees", aim_yaw_delta_degrees)
		changed = true
	if bool(proxy.get_meta("unit_aim_pose_yaw_active", false)) != has_aim_yaw:
		proxy.set_meta("unit_aim_pose_yaw_active", has_aim_yaw)
		changed = true
	if weapon_node == null:
		return changed
	if not weapon_node.has_meta("unit_aim_pose_base_rotation_degrees"):
		weapon_node.set_meta("unit_aim_pose_base_rotation_degrees", weapon_node.rotation_degrees)
	if not weapon_node.has_meta("unit_aim_pose_base_position"):
		weapon_node.set_meta("unit_aim_pose_base_position", weapon_node.position)
	var base_rotation: Vector3 = _get_vector3_meta(weapon_node, "unit_aim_pose_base_rotation_degrees", weapon_node.rotation_degrees)
	var base_position: Vector3 = _get_vector3_meta(weapon_node, "unit_aim_pose_base_position", weapon_node.position)
	var desired_rotation: Vector3 = base_rotation
	var desired_position: Vector3 = base_position
	if is_active:
		desired_rotation = base_rotation + Vector3(UNIT_AIM_POSE_WEAPON_PITCH_DEGREES, 0.0, 0.0)
		desired_position = base_position + Vector3(0.0, 0.0, -UNIT_AIM_POSE_WEAPON_FORWARD_OFFSET)
	elif is_ready:
		desired_rotation = base_rotation + Vector3(UNIT_READY_POSE_WEAPON_PITCH_DEGREES, 0.0, 0.0)
		desired_position = base_position + Vector3(0.0, 0.0, -UNIT_READY_POSE_WEAPON_FORWARD_OFFSET)
	if weapon_node.rotation_degrees.distance_squared_to(desired_rotation) > 0.0001:
		weapon_node.rotation_degrees = desired_rotation
		changed = true
	if weapon_node.position.distance_squared_to(desired_position) > 0.000001:
		weapon_node.position = desired_position
		changed = true
	if bool(weapon_node.get_meta("unit_aim_pose_applied", false)) != is_active:
		weapon_node.set_meta("unit_aim_pose_applied", is_active)
		changed = true
	if bool(weapon_node.get_meta("unit_ready_pose_applied", false)) != is_ready:
		weapon_node.set_meta("unit_ready_pose_applied", is_ready)
		changed = true
	if String(weapon_node.get_meta("unit_weapon_posture_applied", "")) != normalized_weapon_posture:
		weapon_node.set_meta("unit_weapon_posture_applied", normalized_weapon_posture)
		changed = true
	if _update_unit_weapon_child_aim_yaw(weapon_node, aim_yaw_delta_degrees, has_aim_yaw):
		changed = true
	return changed


func _update_unit_weapon_child_aim_yaw(weapon_node: Node3D, aim_yaw_delta_degrees: float, apply_aim_yaw: bool) -> bool:
	if weapon_node == null:
		return false
	var changed: bool = false
	var desired_yaw_delta: float = aim_yaw_delta_degrees if apply_aim_yaw else 0.0
	for child in weapon_node.get_children():
		var child_3d := child as Node3D
		if child_3d == null:
			continue
		if not child_3d.has_meta("unit_aim_pose_base_rotation_degrees"):
			child_3d.set_meta("unit_aim_pose_base_rotation_degrees", child_3d.rotation_degrees)
		var base_rotation: Vector3 = _get_vector3_meta(child_3d, "unit_aim_pose_base_rotation_degrees", child_3d.rotation_degrees)
		var desired_rotation: Vector3 = base_rotation + Vector3(0.0, desired_yaw_delta, 0.0)
		if child_3d.rotation_degrees.distance_squared_to(desired_rotation) > 0.0001:
			child_3d.rotation_degrees = desired_rotation
			changed = true
	return changed


func _find_unit_blaster_visual_node(node: Node) -> Node3D:
	if node == null:
		return null
	var node_3d := node as Node3D
	if node_3d != null and String(node.name).begins_with("BlasterVisual_"):
		return node_3d
	for child in node.get_children():
		var found: Node3D = _find_unit_blaster_visual_node(child)
		if found != null:
			return found
	return null


func _get_vector3_meta(node: Node, meta_name: String, fallback: Vector3) -> Vector3:
	if node == null or not node.has_meta(meta_name):
		return fallback
	var value: Variant = node.get_meta(meta_name)
	if typeof(value) == TYPE_VECTOR3:
		return Vector3(value)
	return fallback


func _find_unit_visual_animation_player(node: Node) -> AnimationPlayer:
	if node == null:
		return null
	var animation_player := node as AnimationPlayer
	if animation_player != null and animation_player.name == "UnitVisualAnimationPlayer":
		return animation_player
	for child in node.get_children():
		var found: AnimationPlayer = _find_unit_visual_animation_player(child)
		if found != null:
			return found
	return null


func _setup_unit_visual_sockets(proxy_root: Node3D, model_root: Node3D, model_instance: Node3D, unit_visual_entry: Dictionary) -> void:
	var socket_entries: Dictionary = _get_unit_socket_entries(unit_visual_entry)
	if socket_entries.is_empty():
		return
	var skeleton: Skeleton3D = _find_first_skeleton(model_instance)
	if skeleton != null:
		proxy_root.set_meta("unit_skeleton_available", true)
		model_root.set_meta("unit_skeleton_bone_count", skeleton.get_bone_count())

	var socket_count: int = 0
	var fallback_count: int = 0
	var head_socket_available: bool = false
	var right_hand_socket_available: bool = false
	for socket_name_variant in socket_entries.keys():
		var socket_name: String = String(socket_name_variant).strip_edges()
		if socket_name.is_empty():
			continue
		var socket_entry: Dictionary = Dictionary(socket_entries.get(socket_name_variant, {}))
		var socket_node: Node3D = _create_unit_visual_socket(model_root, skeleton, socket_name, socket_entry)
		if socket_node == null:
			continue
		socket_count += 1
		if bool(socket_node.get_meta("socket_uses_fallback", false)):
			fallback_count += 1
		if socket_name == "HeadSocket":
			head_socket_available = true
		elif socket_name == "RightHandSocket":
			right_hand_socket_available = true

	proxy_root.set_meta("unit_socket_count", socket_count)
	proxy_root.set_meta("unit_socket_fallback_count", fallback_count)
	proxy_root.set_meta("unit_head_socket_available", head_socket_available)
	proxy_root.set_meta("unit_right_hand_socket_available", right_hand_socket_available)
	proxy_root.set_meta("unit_animation_retarget_fallback_count", 0)


func _create_unit_visual_socket(model_root: Node3D, skeleton: Skeleton3D, socket_name: String, socket_entry: Dictionary) -> Node3D:
	var bone_name: String = _find_matching_socket_bone_name(skeleton, _get_socket_bone_names(socket_entry), socket_name)
	var socket_node: Node3D = null
	var fallback_anchor: Vector3 = _get_vector3_from_variant(socket_entry.get("fallback_anchor", Vector3.ZERO), Vector3.ZERO)
	if skeleton != null and not bone_name.is_empty():
		var bone_attachment := BoneAttachment3D.new()
		bone_attachment.name = socket_name
		bone_attachment.bone_name = bone_name
		bone_attachment.set_meta("socket_mode", "bone:%s" % bone_name)
		skeleton.add_child(bone_attachment)
		socket_node = bone_attachment
		_apply_unit_socket_transform(socket_node, socket_entry, Vector3.ZERO)
	else:
		var fallback_socket := Node3D.new()
		fallback_socket.name = socket_name
		fallback_socket.set_meta("socket_mode", "fallback_anchor")
		fallback_socket.set_meta("socket_uses_fallback", true)
		model_root.add_child(fallback_socket)
		socket_node = fallback_socket
		_apply_unit_socket_transform(socket_node, socket_entry, fallback_anchor)
	return socket_node


func _apply_unit_socket_transform(socket_node: Node3D, socket_entry: Dictionary, base_position: Vector3) -> void:
	if socket_node == null:
		return
	var socket_offset: Vector3 = _get_vector3_from_variant(socket_entry.get("offset", Vector3.ZERO), Vector3.ZERO)
	socket_node.position = base_position + socket_offset
	socket_node.rotation_degrees = _get_vector3_from_variant(socket_entry.get("rotation_degrees", Vector3.ZERO), Vector3.ZERO)


func _find_unit_visual_socket(node: Node, socket_name: String) -> Node3D:
	if node == null:
		return null
	if String(node.name) == socket_name:
		return node as Node3D
	for child in node.get_children():
		var found: Node3D = _find_unit_visual_socket(child, socket_name)
		if found != null:
			return found
	return null


func _attach_unit_helmet(proxy_root: Node3D, model_root: Node3D, model_instance: Node3D, unit_visual_entry: Dictionary) -> bool:
	var helmet_path: String = _get_unit_helmet_path(unit_visual_entry)
	if helmet_path.is_empty():
		return true
	if not ResourceLoader.exists(helmet_path):
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		_add_runtime_missing_asset_marker(
			proxy_root,
			Vector3(0.0, 0.56, 0.0),
			"MissingAsset_unit_helmet_%s" % _sanitize_node_name(_get_unit_visual_name(null, unit_visual_entry))
		)
		return false
	var helmet_scene := _get_asset_model_scene_by_path(helmet_path)
	if helmet_scene == null:
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		return false
	var helmet_instance := helmet_scene.instantiate() as Node3D
	if helmet_instance == null:
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		return false
	_normalize_asset_model_instance(helmet_instance)
	helmet_instance.name = "HelmetVisual_%s" % helmet_path.get_file().get_basename()
	var attachment_entry: Dictionary = _get_unit_helmet_attachment_entry(unit_visual_entry)
	_apply_unit_helmet_transform(helmet_instance, attachment_entry, model_instance)
	var socket_name: String = String(attachment_entry.get("socket_name", "HeadSocket")).strip_edges()
	var socket: Node3D = _find_unit_visual_socket(model_root, socket_name)
	if socket != null:
		socket.add_child(helmet_instance)
		model_root.set_meta("helmet_attachment_mode", "socket:%s" % socket_name)
		helmet_instance.set_meta("attachment_socket", socket_name)
		return true

	var skeleton: Skeleton3D = _find_first_skeleton(model_instance)
	var bone_name: String = _find_matching_bone_name(skeleton, _get_helmet_bone_names(attachment_entry))
	if skeleton != null and not bone_name.is_empty():
		var bone_attachment := BoneAttachment3D.new()
		bone_attachment.name = "HelmetAttachment"
		bone_attachment.bone_name = bone_name
		skeleton.add_child(bone_attachment)
		bone_attachment.add_child(helmet_instance)
		model_root.set_meta("helmet_attachment_mode", "bone:%s" % bone_name)
		return true

	var head_anchor := Node3D.new()
	head_anchor.name = "HeadAnchor"
	head_anchor.position = _get_vector3_from_variant(attachment_entry.get("fallback_anchor", Vector3(0.0, 1.38, 0.0)), Vector3(0.0, 1.38, 0.0))
	model_root.add_child(head_anchor)
	head_anchor.add_child(helmet_instance)
	model_root.set_meta("helmet_attachment_mode", "head_anchor")
	return true


func _attach_unit_blaster(proxy_root: Node3D, model_root: Node3D, _model_instance: Node3D, unit_visual_entry: Dictionary) -> bool:
	var blaster_path: String = _get_unit_blaster_path(unit_visual_entry)
	if blaster_path.is_empty():
		return false
	if not ResourceLoader.exists(blaster_path):
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		_add_runtime_missing_asset_marker(
			proxy_root,
			Vector3(0.0, 0.50, 0.0),
			"MissingAsset_unit_blaster_%s" % _sanitize_node_name(_get_unit_visual_name(null, unit_visual_entry))
		)
		return false
	var blaster_scene := _get_asset_model_scene_by_path(blaster_path)
	if blaster_scene == null:
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		return false
	var blaster_instance := blaster_scene.instantiate() as Node3D
	if blaster_instance == null:
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		return false
	_normalize_asset_model_instance(blaster_instance)
	blaster_instance.name = "BlasterVisual_%s" % blaster_path.get_file().get_basename()
	var attachment_entry: Dictionary = _get_unit_blaster_attachment_entry(unit_visual_entry)
	_apply_unit_blaster_transform(blaster_instance, attachment_entry)
	if not _apply_unit_blaster_material(blaster_instance, attachment_entry):
		_mark_unit_visual_loadout_error(proxy_root, unit_visual_entry)
		return false
	var socket_name: String = String(attachment_entry.get("socket_name", "RightHandSocket")).strip_edges()
	var socket: Node3D = _find_unit_visual_socket(model_root, socket_name)
	if socket != null:
		socket.add_child(blaster_instance)
		model_root.set_meta("blaster_attachment_mode", "socket:%s" % socket_name)
		blaster_instance.set_meta("attachment_socket", socket_name)
		return true

	var hand_anchor := Node3D.new()
	hand_anchor.name = "RightHandAnchor"
	hand_anchor.position = _get_vector3_from_variant(attachment_entry.get("fallback_anchor", Vector3(0.22, 0.84, 0.10)), Vector3(0.22, 0.84, 0.10))
	model_root.add_child(hand_anchor)
	hand_anchor.add_child(blaster_instance)
	model_root.set_meta("blaster_attachment_mode", "right_hand_anchor")
	return true


func _mark_unit_visual_loadout_error(proxy_root: Node3D, unit_visual_entry: Dictionary) -> void:
	if proxy_root == null:
		return
	if String(unit_visual_entry.get("resolved_visual_loadout_id", "")).strip_edges().is_empty():
		return
	proxy_root.set_meta("unit_visual_loadout_error", true)


func _find_first_skeleton(node: Node) -> Skeleton3D:
	var skeleton := node as Skeleton3D
	if skeleton != null:
		return skeleton
	for child in node.get_children():
		var found: Skeleton3D = _find_first_skeleton(child)
		if found != null:
			return found
	return null


func _find_matching_bone_name(skeleton: Skeleton3D, candidate_names: PackedStringArray) -> String:
	if skeleton == null:
		return ""
	for candidate in candidate_names:
		var candidate_text: String = String(candidate).strip_edges()
		if candidate_text.is_empty():
			continue
		var bone_index: int = skeleton.find_bone(candidate_text)
		if bone_index >= 0:
			return candidate_text
	var bone_count: int = skeleton.get_bone_count()
	for index in range(bone_count):
		var bone_name: String = skeleton.get_bone_name(index)
		if bone_name.to_lower().find("head") >= 0:
			return bone_name
	return ""


func _find_matching_socket_bone_name(skeleton: Skeleton3D, candidate_names: PackedStringArray, socket_name: String) -> String:
	if skeleton == null:
		return ""
	for candidate in candidate_names:
		var candidate_text: String = String(candidate).strip_edges()
		if candidate_text.is_empty():
			continue
		var bone_index: int = skeleton.find_bone(candidate_text)
		if bone_index >= 0:
			return candidate_text
	var best_match: String = ""
	var bone_count: int = skeleton.get_bone_count()
	for index in range(bone_count):
		var bone_name: String = skeleton.get_bone_name(index)
		if _bone_name_matches_socket(bone_name, socket_name):
			if best_match.is_empty() or bone_name.length() < best_match.length():
				best_match = bone_name
	return best_match


func _bone_name_matches_socket(bone_name: String, socket_name: String) -> bool:
	var bone_text: String = bone_name.strip_edges().to_lower()
	if bone_text.is_empty() or bone_text.find("_end") >= 0 or bone_text.ends_with("end"):
		return false
	var socket_text: String = socket_name.strip_edges().to_lower()
	if socket_text == "headsocket":
		return bone_text.find("head") >= 0
	if socket_text == "righthandsocket":
		return bone_text.find("righthand") >= 0 or (bone_text.find("right") >= 0 and bone_text.find("hand") >= 0)
	if socket_text == "lefthandsocket":
		return bone_text.find("lefthand") >= 0 or (bone_text.find("left") >= 0 and bone_text.find("hand") >= 0)
	if socket_text == "backsocket":
		return bone_text.find("spine") >= 0 or bone_text.find("chest") >= 0
	return false


func _get_unit_proxy_ids(visible_only: bool) -> Array:
	var unit_ids: Array = []
	for unit_id_variant in _unit_proxies_by_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var proxy := _unit_proxies_by_id.get(unit_id_variant, null) as Node3D
		if proxy == null or not is_instance_valid(proxy):
			continue
		if visible_only and not proxy.visible:
			continue
		unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _get_unit_proxy_ids_with_meta(meta_name: String) -> Array:
	var unit_ids: Array = []
	var normalized_meta_name: String = meta_name.strip_edges()
	if normalized_meta_name.is_empty():
		return unit_ids
	for unit_id_variant in _unit_proxies_by_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var proxy := _unit_proxies_by_id.get(unit_id_variant, null) as Node3D
		if proxy == null or not is_instance_valid(proxy):
			continue
		if bool(proxy.get_meta(normalized_meta_name, false)):
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _get_unit_proxy_state_by_id() -> Dictionary:
	var result: Dictionary = {}
	for unit_id_variant in _unit_proxies_by_id.keys():
		var unit_id: String = String(unit_id_variant).strip_edges()
		if unit_id.is_empty():
			continue
		var proxy := _unit_proxies_by_id.get(unit_id_variant, null) as Node3D
		if proxy == null or not is_instance_valid(proxy):
			continue
		result[unit_id] = {
			"visible": proxy.visible,
			"rotation_y_degrees": float(proxy.rotation_degrees.y),
			"team_id": String(proxy.get_meta("team_id", "")).strip_edges(),
			"vital_state": String(proxy.get_meta("vital_state", "")).strip_edges(),
			"missing_unit_model": bool(proxy.get_meta("missing_unit_model", false)),
			"unit_visual_error": bool(proxy.get_meta("unit_visual_error", false)),
			"uses_unit_texture": bool(proxy.get_meta("uses_unit_texture", false)),
			"uses_kenney_model": bool(proxy.get_meta("uses_kenney_model", false)),
			"unit_visual_archetype_id": String(proxy.get_meta("unit_visual_archetype_id", "")).strip_edges(),
			"unit_visual_faction_id": String(proxy.get_meta("unit_visual_faction_id", "")).strip_edges(),
			"unit_model_root_rotation_y_degrees": float(proxy.get_meta("unit_model_root_rotation_y_degrees", 0.0)),
			"unit_weapon_anchor_distance_3d": _get_unit_weapon_anchor_distance_3d(proxy),
			"unit_aim_pose_active": bool(proxy.get_meta("unit_aim_pose_active", false)),
			"unit_ready_pose_active": bool(proxy.get_meta("unit_ready_pose_active", false)),
			"unit_movement_posture": String(proxy.get_meta("unit_movement_posture", "")).strip_edges(),
			"unit_weapon_posture": String(proxy.get_meta("unit_weapon_posture", "")).strip_edges(),
			"unit_runtime_weapon_posture": String(proxy.get_meta("unit_runtime_weapon_posture", "")).strip_edges(),
			"unit_posture_policy_id": String(proxy.get_meta("unit_posture_policy_id", "")).strip_edges(),
			"unit_posture_source": String(proxy.get_meta("unit_posture_source", "")).strip_edges(),
			"unit_aim_pose_weapon_node_available": bool(proxy.get_meta("unit_aim_pose_weapon_node_available", false)),
			"unit_aim_pose_yaw_active": bool(proxy.get_meta("unit_aim_pose_yaw_active", false)),
			"unit_aim_pose_yaw_delta_degrees": float(proxy.get_meta("unit_aim_pose_yaw_delta_degrees", 0.0)),
			"unit_aim_pose_source_event_id": String(proxy.get_meta("unit_aim_pose_source_event_id", "")).strip_edges(),
			"unit_aim_pose_target_unit_id": String(proxy.get_meta("unit_aim_pose_target_unit_id", "")).strip_edges(),
		}
	return result


func _get_unit_weapon_anchor_distance_3d(proxy: Node3D) -> float:
	if proxy == null or not is_instance_valid(proxy):
		return -1.0
	var weapon_node: Node3D = _find_unit_blaster_visual_node(proxy)
	if weapon_node == null or not is_instance_valid(weapon_node):
		return -1.0
	var proxy_position: Vector3 = proxy.global_position
	var weapon_position: Vector3 = weapon_node.global_position
	return Vector2(weapon_position.x - proxy_position.x, weapon_position.z - proxy_position.z).length()


func _apply_unit_helmet_transform(helmet_instance: Node3D, attachment_entry: Dictionary, model_instance: Node3D) -> void:
	if helmet_instance == null:
		return
	helmet_instance.position = _get_vector3_from_variant(attachment_entry.get("offset", Vector3.ZERO), Vector3.ZERO)
	helmet_instance.rotation_degrees = _get_vector3_from_variant(attachment_entry.get("rotation_degrees", Vector3.ZERO), Vector3.ZERO)
	_apply_unit_attachment_visual_adjustment(helmet_instance, attachment_entry)
	helmet_instance.scale = Vector3.ONE * _get_unit_helmet_scale(helmet_instance, model_instance, attachment_entry)


func _apply_unit_blaster_transform(blaster_instance: Node3D, attachment_entry: Dictionary) -> void:
	if blaster_instance == null:
		return
	blaster_instance.position = _get_vector3_from_variant(attachment_entry.get("offset", Vector3.ZERO), Vector3.ZERO)
	blaster_instance.rotation_degrees = _get_vector3_from_variant(attachment_entry.get("rotation_degrees", Vector3.ZERO), Vector3.ZERO)
	_apply_unit_attachment_visual_adjustment(blaster_instance, attachment_entry)
	blaster_instance.scale = Vector3.ONE * float(attachment_entry.get("scale", 0.10))


func _apply_unit_attachment_visual_adjustment(attachment_instance: Node3D, attachment_entry: Dictionary) -> void:
	if attachment_instance == null:
		return
	var visual_offset: Vector3 = _get_vector3_from_variant(attachment_entry.get("visual_offset", Vector3.ZERO), Vector3.ZERO)
	var visual_rotation: Vector3 = _get_vector3_from_variant(attachment_entry.get("visual_rotation_degrees", Vector3.ZERO), Vector3.ZERO)
	if visual_offset.length_squared() <= 0.000001 and visual_rotation.length_squared() <= 0.000001:
		return
	for child in attachment_instance.get_children():
		var child_3d := child as Node3D
		if child_3d == null:
			continue
		child_3d.position += visual_offset
		child_3d.rotation_degrees += visual_rotation


func _apply_unit_blaster_material(blaster_instance: Node3D, attachment_entry: Dictionary) -> bool:
	if blaster_instance == null:
		return false
	var texture_path: String = String(attachment_entry.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return true
	if not ResourceLoader.exists(texture_path):
		return false
	var texture := load(texture_path) as Texture2D
	if texture == null:
		return false
	_apply_material_override_recursive(blaster_instance, _make_texture_material(texture))
	return true


func _get_unit_helmet_scale(helmet_instance: Node3D, model_instance: Node3D, attachment_entry: Dictionary) -> float:
	var explicit_scale: float = float(attachment_entry.get("scale", 1.0))
	var scale_mode: String = String(attachment_entry.get("scale_mode", "")).strip_edges().to_lower()
	if scale_mode != "fit_to_model":
		return explicit_scale

	var helmet_bounds: Dictionary = _get_local_visual_bounds(helmet_instance)
	var model_bounds: Dictionary = _get_local_visual_bounds(model_instance)
	if not bool(helmet_bounds.get("valid", false)) or not bool(model_bounds.get("valid", false)):
		return explicit_scale

	var helmet_size: Vector3 = Vector3(helmet_bounds.get("max", Vector3.ZERO)) - Vector3(helmet_bounds.get("min", Vector3.ZERO))
	var model_size: Vector3 = Vector3(model_bounds.get("max", Vector3.ZERO)) - Vector3(model_bounds.get("min", Vector3.ZERO))
	var fit_scales: Array[float] = []
	if helmet_size.y > 0.0001 and model_size.y > 0.0001:
		fit_scales.append((model_size.y * float(attachment_entry.get("target_height_ratio", 0.14))) / helmet_size.y)
	var helmet_width: float = maxf(helmet_size.x, helmet_size.z)
	var model_width: float = maxf(model_size.x, model_size.z)
	if helmet_width > 0.0001 and model_width > 0.0001:
		fit_scales.append((model_width * float(attachment_entry.get("target_width_ratio", 0.22))) / helmet_width)
	if fit_scales.is_empty():
		return explicit_scale
	var fit_scale: float = fit_scales[0]
	for scale_value in fit_scales:
		fit_scale = minf(fit_scale, float(scale_value))
	fit_scale *= float(attachment_entry.get("scale_multiplier", 1.0))
	if attachment_entry.has("max_scale"):
		fit_scale = minf(fit_scale, float(attachment_entry.get("max_scale", fit_scale)))
	if attachment_entry.has("min_scale"):
		fit_scale = maxf(fit_scale, float(attachment_entry.get("min_scale", fit_scale)))
	return fit_scale


func _add_runtime_missing_asset_marker(parent: Node3D, position: Vector3, node_name: String) -> void:
	if parent == null:
		return
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.mesh = _make_box_mesh(Vector3(0.42, 0.22, 0.42))
	marker.material_override = _make_material(Color(1.0, 0.12, 0.72, 1.0))
	marker.position = position
	parent.add_child(marker)


func _sanitize_node_name(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	for token in ["/", "\\", " ", ":", ".", "-"]:
		result = result.replace(token, "_")
	return "unknown" if result.is_empty() else result


func _add_world_tile_marker(parent: Node3D, world_position: Vector2, color: Color, node_name: String, height: float = 0.045, fill: float = 0.9) -> bool:
	var grid_position: Vector2i = _world_to_grid_position(world_position)
	return _add_tile_marker(parent, grid_position, color, "%s_%d_%d" % [node_name, grid_position.x, grid_position.y], height, fill)


func _add_tile_marker(parent: Node3D, grid_position: Vector2i, color: Color, node_name: String, height: float = 0.045, fill: float = 0.9) -> bool:
	if parent == null:
		return false
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position) if _terrain_map_data != null else null
	if tile_data == null:
		return false
	var cell_size: float = _get_3d_cell_size()
	var marker_fill: float = clampf(fill, 0.1, 1.4)
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.mesh = _make_box_mesh(Vector3(cell_size * marker_fill, maxf(height, 0.01), cell_size * marker_fill))
	marker.material_override = _make_material(color, true)
	var top_y: float = float(tile_data.height_level) * _get_3d_height_step()
	marker.position = _grid_to_3d_position(Vector2(grid_position), top_y + 0.014 + (height * 0.5))
	parent.add_child(marker)
	return true


func _add_marker3d(parent: Node3D, world_position: Vector2, color: Color, node_name: String, radius: float, height: float, radial_segments: int = 12, surface_offset: float = 0.28) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.mesh = mesh
	marker.material_override = _make_material(color)
	marker.position = _world_to_surface_3d_position(world_position, surface_offset + height * 0.5)
	if radial_segments == 4:
		marker.rotation_degrees.y = 45.0
	parent.add_child(marker)


func _add_fire_sector_los_line_visuals(parent: Node3D, origin_world: Vector2, center_direction: Vector2, range_world: float, range_tiles: int, node_name: String, line_anchor: Dictionary = {}) -> Dictionary:
	var origin_grid: Vector2i = _world_to_grid_position(origin_world)
	var direction: Vector2 = center_direction.normalized() if center_direction.length_squared() > 0.0001 else Vector2.RIGHT
	var raw_tip_position: Vector2 = origin_world + direction * maxf(range_world, 0.0)
	var facing_length: float = clampf(range_world * 0.16, FRIENDLY_FIRE_FACING_STEM_MIN_WORLD, FRIENDLY_FIRE_FACING_STEM_MAX_WORLD)
	var line_origin_world: Vector2 = Vector2(line_anchor.get("origin_world", origin_world))
	var report: Dictionary = {
		"origin_grid": origin_grid,
		"line_origin_position": line_origin_world,
		"line_origin_anchor": String(line_anchor.get("anchor", "unit_center")),
		"visible_tile_count": 0,
		"blocker_tile_count": 0,
		"los_line_count": 0,
		"blocker_grids": [],
		"los_blocker_samples": [],
		"tip_position": raw_tip_position,
		"facing_tip_position": origin_world + direction * facing_length,
		"los_blocked": false,
	}
	if parent == null or center_direction.length_squared() <= 0.0001 or range_world <= 0.0:
		return report

	var target_grid: Vector2i = _resolve_fire_sector_los_target_grid(origin_grid, raw_tip_position, range_tiles)
	var blocker_grid := Vector2i(2147483647, 2147483647)
	if target_grid != Vector2i(2147483647, 2147483647) and target_grid != origin_grid:
		blocker_grid = _find_fire_sector_los_blocker_grid_cached(origin_grid, target_grid)
	if blocker_grid != Vector2i(2147483647, 2147483647):
		var blocker_world: Vector2 = _get_tile_world_position_for_grid(blocker_grid, _grid_float_to_world(Vector2(blocker_grid)))
		report["blocker_tile_count"] = 1
		report["blocker_grids"] = [blocker_grid]
		report["los_blocker_samples"] = [{
			"blocker_grid": blocker_grid,
			"blocker_position": blocker_world,
			"line_grids": _build_grid_line(origin_grid, blocker_grid),
		}]
		report["tip_position"] = blocker_world
		report["los_blocked"] = true

	var line_origin_3d_variant: Variant = line_anchor.get("origin_3d", null)
	var line_origin_3d: Vector3 = Vector3(line_origin_3d_variant) if typeof(line_origin_3d_variant) == TYPE_VECTOR3 else _world_to_surface_3d_position(line_origin_world, FRIENDLY_AIM_LINE_HEIGHT)
	var line_tip_3d: Vector3 = _world_to_3d_position(Vector2(report.get("tip_position", raw_tip_position)), line_origin_3d.y)
	_add_line3d(
		parent,
		line_origin_3d,
		line_tip_3d,
		FRIENDLY_FIRE_SECTOR_BLOCKER_LINE_COLOR if bool(report.get("los_blocked", false)) else FRIENDLY_AIM_LINE_COLOR,
		node_name
	)
	_friendly_aim_los_line_count += 1
	report["los_line_count"] = 1
	return report


func _resolve_fire_sector_los_target_grid(origin_grid: Vector2i, raw_tip_position: Vector2, range_tiles: int) -> Vector2i:
	var sentinel := Vector2i(2147483647, 2147483647)
	if _terrain_map_data == null:
		return sentinel
	var raw_target_grid: Vector2i = _world_to_grid_position(raw_tip_position)
	if _terrain_map_data.call("get_tile_at_grid", raw_target_grid) != null:
		return raw_target_grid
	var line_grids: Array = _build_grid_line(origin_grid, raw_target_grid)
	var last_valid_grid: Vector2i = sentinel
	var max_steps: int = maxi(range_tiles, 1)
	for index in range(1, line_grids.size()):
		if index > max_steps:
			break
		var grid_position: Vector2i = line_grids[index]
		if _terrain_map_data.call("get_tile_at_grid", grid_position) == null:
			continue
		last_valid_grid = grid_position
	return last_valid_grid


func _get_tile_world_position_for_grid(grid_position: Vector2i, fallback_position: Vector2) -> Vector2:
	if _terrain_map_data == null:
		return fallback_position
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return fallback_position
	return Vector2(tile_data.world_position)


func _add_fire_sector_tile_visuals(parent: Node3D, origin_world: Vector2, center_direction: Vector2, range_world: float, range_tiles: int, sector_angle_radians: float, node_name: String) -> Dictionary:
	var origin_grid: Vector2i = _world_to_grid_position(origin_world)
	var report: Dictionary = {
		"origin_grid": origin_grid,
		"visible_tile_count": 0,
		"blocker_tile_count": 0,
		"los_line_count": 0,
		"blocker_grids": [],
		"los_blocker_samples": [],
	}
	if parent == null or _terrain_map_data == null or center_direction.length_squared() <= 0.0001 or range_world <= 0.0:
		return report

	var direction: Vector2 = center_direction.normalized()
	var half_angle: float = sector_angle_radians * 0.5
	var range_padding: float = maxf(_half_tile_width, _half_tile_height)
	var visible_grids: Array = []
	var blocker_grids: Array = []
	var blocker_lookup: Dictionary = {}
	var blocker_samples: Array = []
	var max_grid_range: int = maxi(range_tiles, 1)

	for grid_x in range(origin_grid.x - max_grid_range, origin_grid.x + max_grid_range + 1):
		for grid_y in range(origin_grid.y - max_grid_range, origin_grid.y + max_grid_range + 1):
			var grid_position := Vector2i(grid_x, grid_y)
			if grid_position == origin_grid:
				continue
			var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
			if tile_data == null:
				continue
			var tile_world_position: Vector2 = Vector2(tile_data.world_position)
			var to_tile: Vector2 = tile_world_position - origin_world
			var tile_distance_world: float = to_tile.length()
			if tile_distance_world <= 0.001 or tile_distance_world > range_world + range_padding:
				continue
			if _grid_distance_score(origin_grid, grid_position) > float(maxi(range_tiles, 0)) + 0.35:
				continue
			var angle_delta: float = absf(wrapf(to_tile.normalized().angle() - direction.angle(), -PI, PI))
			if angle_delta > half_angle:
				continue

			var blocker_grid: Vector2i = _find_fire_sector_los_blocker_grid_cached(origin_grid, grid_position)
			if blocker_grid != Vector2i(2147483647, 2147483647):
				var blocker_key: String = "%d,%d" % [blocker_grid.x, blocker_grid.y]
				if not blocker_lookup.has(blocker_key):
					blocker_lookup[blocker_key] = true
					blocker_grids.append(blocker_grid)
					if blocker_samples.size() < FRIENDLY_FIRE_SECTOR_BLOCKER_LINE_LIMIT:
						var blocker_world: Vector2 = _grid_float_to_world(Vector2(blocker_grid))
						var blocker_tile = _terrain_map_data.call("get_tile_at_grid", blocker_grid)
						if blocker_tile != null:
							blocker_world = Vector2(blocker_tile.world_position)
						_add_line3d(
							parent,
							_world_to_surface_3d_position(origin_world, 0.74),
							_world_to_surface_3d_position(blocker_world, 0.74),
							FRIENDLY_FIRE_SECTOR_BLOCKER_LINE_COLOR,
							"%s_LOSBlock_%d_%d" % [node_name, blocker_grid.x, blocker_grid.y]
						)
						_friendly_aim_los_line_count += 1
						blocker_samples.append({
							"blocker_grid": blocker_grid,
							"blocker_position": blocker_world,
							"line_grids": _build_grid_line(origin_grid, blocker_grid),
						})
				continue
			visible_grids.append(grid_position)

	_add_tile_fill_batch(parent, visible_grids, FRIENDLY_FIRE_SECTOR_TILE_COLOR, "%s_Tiles" % node_name, FRIENDLY_FIRE_SECTOR_SURFACE_OFFSET, FRIENDLY_FIRE_SECTOR_TILE_FILL)
	_add_tile_fill_batch(parent, blocker_grids, FRIENDLY_FIRE_SECTOR_BLOCKER_COLOR, "%s_Blockers" % node_name, FRIENDLY_FIRE_SECTOR_SURFACE_OFFSET + 0.018, FRIENDLY_FIRE_SECTOR_BLOCKER_TILE_FILL)
	_friendly_aim_tile_marker_count += visible_grids.size()
	_friendly_aim_blocker_marker_count += blocker_grids.size()
	report["visible_tile_count"] = visible_grids.size()
	report["blocker_tile_count"] = blocker_grids.size()
	report["los_line_count"] = blocker_samples.size()
	report["blocker_grids"] = blocker_grids.duplicate()
	report["los_blocker_samples"] = blocker_samples.duplicate(true)
	return report


func _find_fire_sector_los_blocker_grid_cached(start_grid: Vector2i, end_grid: Vector2i) -> Vector2i:
	var cache_key: String = "%d,%d>%d,%d" % [start_grid.x, start_grid.y, end_grid.x, end_grid.y]
	if _fire_sector_los_cache.has(cache_key):
		return Vector2i(_fire_sector_los_cache[cache_key])
	var blocker_grid: Vector2i = _find_fire_sector_los_blocker_grid(start_grid, end_grid)
	_fire_sector_los_cache[cache_key] = blocker_grid
	return blocker_grid


func _add_tile_fill_batch(parent: Node3D, grid_positions: Array, color: Color, node_name: String, surface_offset: float, fill: float) -> void:
	if parent == null or grid_positions.is_empty():
		return
	var material := _make_unshaded_material(color, true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var cell_size: float = _get_3d_cell_size()
	var half_extent: float = cell_size * clampf(fill, 0.1, 1.0) * 0.5
	for grid_variant in grid_positions:
		var grid_position: Vector2i = grid_variant
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position) if _terrain_map_data != null else null
		if tile_data == null:
			continue
		var top_y: float = float(tile_data.height_level) * _get_3d_height_step()
		var center: Vector3 = _grid_to_3d_position(Vector2(grid_position), top_y + surface_offset)
		var north_west: Vector3 = center + Vector3(-half_extent, 0.0, -half_extent)
		var north_east: Vector3 = center + Vector3(half_extent, 0.0, -half_extent)
		var south_east: Vector3 = center + Vector3(half_extent, 0.0, half_extent)
		var south_west: Vector3 = center + Vector3(-half_extent, 0.0, half_extent)
		mesh.surface_add_vertex(north_west)
		mesh.surface_add_vertex(north_east)
		mesh.surface_add_vertex(south_east)
		mesh.surface_add_vertex(north_west)
		mesh.surface_add_vertex(south_east)
		mesh.surface_add_vertex(south_west)
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)


func _find_fire_sector_los_blocker_grid(start_grid: Vector2i, end_grid: Vector2i) -> Vector2i:
	var sentinel := Vector2i(2147483647, 2147483647)
	if _terrain_map_data == null:
		return sentinel
	var start_tile = _terrain_map_data.call("get_tile_at_grid", start_grid)
	var end_tile = _terrain_map_data.call("get_tile_at_grid", end_grid)
	if start_tile == null or end_tile == null:
		return sentinel
	var eye_height: float = float(start_tile.height_level) + 1.0
	var target_height: float = float(end_tile.height_level) + 1.0
	var line_grids: Array = _build_grid_line(start_grid, end_grid)
	for index in range(1, line_grids.size()):
		var grid_position: Vector2i = line_grids[index]
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			continue
		var progress: float = float(index) / float(maxi(line_grids.size() - 1, 1))
		var ray_height: float = lerpf(eye_height, target_height, progress)
		var blocker_height: float = float(tile_data.height_level) + float(tile_data.object_height)
		if bool(tile_data.blocks_los) and blocker_height >= ray_height - 0.05:
			return grid_position
	return sentinel


func _build_grid_line(start_grid: Vector2i, end_grid: Vector2i) -> Array:
	var cells: Array = []
	var x0: int = start_grid.x
	var y0: int = start_grid.y
	var x1: int = end_grid.x
	var y1: int = end_grid.y
	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2: int = err * 2
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	return cells


func _grid_distance_score(start_grid: Vector2i, end_grid: Vector2i) -> float:
	return float(maxi(absi(end_grid.x - start_grid.x), absi(end_grid.y - start_grid.y)))


func _add_fire_sector3d(parent: Node3D, origin_world: Vector2, center_direction: Vector2, range_world: float, sector_angle_radians: float, color: Color, node_name: String) -> void:
	if parent == null or center_direction.length_squared() <= 0.0001 or range_world <= 0.0:
		return
	var direction: Vector2 = center_direction.normalized()
	var half_angle: float = sector_angle_radians * 0.5
	var segment_count: int = maxi(FRIENDLY_FIRE_SECTOR_SEGMENTS, 2)
	var material := _make_unshaded_material(color, true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	var origin_3d: Vector3 = _world_to_surface_3d_position(origin_world, 0.52)
	for index in range(segment_count):
		var start_ratio: float = float(index) / float(segment_count)
		var end_ratio: float = float(index + 1) / float(segment_count)
		var start_angle: float = lerpf(-half_angle, half_angle, start_ratio)
		var end_angle: float = lerpf(-half_angle, half_angle, end_ratio)
		var start_world: Vector2 = origin_world + direction.rotated(start_angle) * range_world
		var end_world: Vector2 = origin_world + direction.rotated(end_angle) * range_world
		mesh.surface_add_vertex(origin_3d)
		mesh.surface_add_vertex(_world_to_surface_3d_position(start_world, 0.52))
		mesh.surface_add_vertex(_world_to_surface_3d_position(end_world, 0.52))
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)


func _add_fire_sector_outline3d(parent: Node3D, origin_world: Vector2, center_direction: Vector2, range_world: float, sector_angle_radians: float, color: Color, node_name: String) -> void:
	if parent == null or center_direction.length_squared() <= 0.0001 or range_world <= 0.0:
		return
	var direction: Vector2 = center_direction.normalized()
	var half_angle: float = sector_angle_radians * 0.5
	var segment_count: int = maxi(FRIENDLY_FIRE_SECTOR_SEGMENTS, 2)
	var material := _make_unshaded_material(color, true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	var origin_3d: Vector3 = _world_to_surface_3d_position(origin_world, 0.55)
	var left_world: Vector2 = origin_world + direction.rotated(-half_angle) * range_world
	var right_world: Vector2 = origin_world + direction.rotated(half_angle) * range_world
	mesh.surface_add_vertex(origin_3d)
	mesh.surface_add_vertex(_world_to_surface_3d_position(left_world, 0.55))
	mesh.surface_add_vertex(origin_3d)
	mesh.surface_add_vertex(_world_to_surface_3d_position(right_world, 0.55))
	var previous_world: Vector2 = left_world
	for index in range(1, segment_count + 1):
		var ratio: float = float(index) / float(segment_count)
		var angle: float = lerpf(-half_angle, half_angle, ratio)
		var current_world: Vector2 = origin_world + direction.rotated(angle) * range_world
		mesh.surface_add_vertex(_world_to_surface_3d_position(previous_world, 0.55))
		mesh.surface_add_vertex(_world_to_surface_3d_position(current_world, 0.55))
		previous_world = current_world
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)


func _add_line3d(parent: Node3D, start_position: Vector3, end_position: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var mesh := _make_line_mesh(start_position, end_position, color)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)
	return instance


func _add_wide_line3d(parent: Node3D, start_position: Vector3, end_position: Vector3, color: Color, node_name: String, line_width: float) -> MeshInstance3D:
	var mesh := _make_wide_line_mesh(start_position, end_position, color, line_width)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)
	return instance


func _add_dropship_approach_vector3d(parent: Node3D, start_position: Vector3, end_position: Vector3, color: Color, node_name: String, line_width: float, entry: Dictionary) -> MeshInstance3D:
	var mesh := _make_dropship_approach_vector_mesh(start_position, end_position, color, line_width, entry)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.set_meta("dropship_approach_vector_shape", String(entry.get("approach_vector_shape", "wide_arrow")).strip_edges().to_lower())
	parent.add_child(instance)
	return instance


func _make_line_mesh(start_position: Vector3, end_position: Vector3, color: Color) -> ImmediateMesh:
	var material := _make_material(color, true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(start_position)
	mesh.surface_add_vertex(end_position)
	mesh.surface_end()
	return mesh


func _make_wide_line_mesh(start_position: Vector3, end_position: Vector3, color: Color, line_width: float) -> ImmediateMesh:
	var material := _make_material(color, true)
	var mesh := ImmediateMesh.new()
	var direction: Vector3 = end_position - start_position
	if direction.length_squared() <= 0.0001:
		return mesh
	direction = direction.normalized()
	var side := Vector3(-direction.z, 0.0, direction.x)
	if side.length_squared() <= 0.0001:
		side = Vector3.RIGHT
	side = side.normalized() * (maxf(line_width, 0.01) * 0.5)
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	mesh.surface_add_vertex(start_position - side)
	mesh.surface_add_vertex(start_position + side)
	mesh.surface_add_vertex(end_position + side)
	mesh.surface_add_vertex(start_position - side)
	mesh.surface_add_vertex(end_position + side)
	mesh.surface_add_vertex(end_position - side)
	mesh.surface_end()
	return mesh


func _make_dropship_approach_vector_mesh(start_position: Vector3, end_position: Vector3, color: Color, line_width: float, entry: Dictionary) -> ImmediateMesh:
	var shape: String = String(entry.get("approach_vector_shape", "wide_arrow")).strip_edges().to_lower()
	if shape == "wide_arrow":
		return _make_wide_arrow_mesh(start_position, end_position, color, line_width)
	return _make_wide_line_mesh(start_position, end_position, color, line_width)


func _make_wide_arrow_mesh(start_position: Vector3, end_position: Vector3, color: Color, line_width: float) -> ImmediateMesh:
	var material := _make_material(color, true)
	var mesh := ImmediateMesh.new()
	var direction: Vector3 = end_position - start_position
	var length: float = direction.length()
	if length <= 0.0001:
		return mesh
	direction /= length
	var side := Vector3(-direction.z, 0.0, direction.x)
	if side.length_squared() <= 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var shaft_half_width: float = maxf(line_width, 0.01) * 0.5
	var head_half_width: float = shaft_half_width * 1.45
	var head_length: float = clampf(maxf(line_width * 2.0, 0.14), shaft_half_width * 1.25, length * 0.32)
	var head_base: Vector3 = end_position - direction * head_length
	var shaft_side: Vector3 = side * shaft_half_width
	var head_side: Vector3 = side * head_half_width
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
	if start_position.distance_squared_to(head_base) > 0.0001:
		mesh.surface_add_vertex(start_position - shaft_side)
		mesh.surface_add_vertex(start_position + shaft_side)
		mesh.surface_add_vertex(head_base + shaft_side)
		mesh.surface_add_vertex(start_position - shaft_side)
		mesh.surface_add_vertex(head_base + shaft_side)
		mesh.surface_add_vertex(head_base - shaft_side)
	mesh.surface_add_vertex(head_base - head_side)
	mesh.surface_add_vertex(head_base + head_side)
	mesh.surface_add_vertex(end_position)
	mesh.surface_end()
	return mesh


func _make_box_mesh(size: Vector3) -> BoxMesh:
	var key: String = "%.3f:%.3f:%.3f" % [size.x, size.y, size.z]
	if _box_mesh_cache.has(key):
		return _box_mesh_cache[key] as BoxMesh
	var mesh := BoxMesh.new()
	mesh.size = size
	_box_mesh_cache[key] = mesh
	return mesh


func _make_material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var key: String = "%s:%s" % [color.to_html(true), str(transparent or color.a < 0.99)]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.metallic = 0.0
	if transparent or color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[key] = material
	return material


func _make_unshaded_material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var key: String = "unshaded:%s:%s" % [color.to_html(true), str(transparent or color.a < 0.99)]
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.metallic = 0.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.disable_receive_shadows = true
	if transparent or color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material_cache[key] = material
	return material


func _make_editor_grid_material(is_highlight: bool = true) -> StandardMaterial3D:
	var key: String = TILE_GRID_LINE_MATERIAL_KEY if is_highlight else TILE_GRID_LINE_SHADOW_MATERIAL_KEY
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = TILE_GRID_LINE_COLOR if is_highlight else TILE_GRID_LINE_SHADOW_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = false
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.disable_receive_shadows = true
	_material_cache[key] = material
	return material


func _make_editor_selection_material(is_border: bool) -> StandardMaterial3D:
	var key: String = TILE_SELECTION_BORDER_MATERIAL_KEY if is_border else TILE_SELECTION_FILL_MATERIAL_KEY
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_color = TILE_SELECTION_BORDER_COLOR if is_border else TILE_SELECTION_FILL_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.no_depth_test = true
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	material.disable_receive_shadows = true
	_material_cache[key] = material
	return material


func _make_texture_material(texture: Texture2D) -> StandardMaterial3D:
	var key: String = "texture:%s" % String(texture.resource_path)
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.roughness = 0.86
	material.metallic = 0.0
	_material_cache[key] = material
	return material


func _make_space_station_colormap_material() -> StandardMaterial3D:
	var key: String = "space_station_colormap:%s" % String(SPACE_STATION_COLORMAP_TEXTURE.resource_path)
	if _material_cache.has(key):
		return _material_cache[key] as StandardMaterial3D
	var material := StandardMaterial3D.new()
	material.albedo_texture = SPACE_STATION_COLORMAP_TEXTURE
	material.albedo_color = Color.WHITE
	material.roughness = 0.78
	material.metallic = 0.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_material_cache[key] = material
	return material


func _resolve_tile_asset_type_id(object_type_id: String, type_id: String) -> String:
	var normalized_object: String = object_type_id.strip_edges().to_lower()
	if not normalized_object.is_empty():
		return normalized_object

	var normalized_type: String = type_id.strip_edges().to_lower()
	if normalized_type.is_empty() or normalized_type == "ground_flat":
		return ""
	if LEGACY_MODEL_BY_TYPE.has(normalized_type):
		return normalized_type

	var tile_catalog = _get_tile_catalog()
	if tile_catalog == null:
		return ""
	if tile_catalog.has_method("is_object_layer_type") and bool(tile_catalog.call("is_object_layer_type", normalized_type)):
		return normalized_type
	var entry: Dictionary = Dictionary(tile_catalog.call("get_type", normalized_type)) if tile_catalog.has_method("get_type") else {}
	if not String(entry.get("texture_path", "")).strip_edges().is_empty():
		return normalized_type
	return ""


func _resolve_structure_tile_asset_type_id(type_id: String) -> String:
	var normalized_type: String = type_id.strip_edges().to_lower()
	if normalized_type.is_empty() or normalized_type == "ground_flat":
		return ""
	var tile_catalog = _get_tile_catalog()
	if tile_catalog != null and tile_catalog.has_method("is_structure_layer_type") and bool(tile_catalog.call("is_structure_layer_type", normalized_type)):
		return normalized_type
	for prefix in ["wall_", "rock_", "cliff_", "slope_"]:
		if normalized_type.begins_with(prefix):
			return normalized_type
	var mapped_entry: Dictionary = _get_model_entry_for_type(normalized_type)
	var layer_name: String = String(mapped_entry.get("layer", "")).strip_edges().to_lower()
	if layer_name == "terrain_object" or layer_name == "structure":
		return normalized_type
	return ""


func _get_missing_visual_type_id(tile_data, visual_type_id: String) -> String:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if not normalized.is_empty():
		return normalized
	if tile_data == null:
		return "unknown"
	normalized = String(tile_data.object_type_id).strip_edges().to_lower() if tile_data.object_type_id is String else ""
	if not normalized.is_empty():
		return normalized
	normalized = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	if not normalized.is_empty():
		return normalized
	return "unknown"


func _is_legacy_object_type(tile_data) -> bool:
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	return type_id.begins_with("wall_") or type_id.begins_with("cliff_") or type_id.begins_with("slope_") or type_id.begins_with("rock_")


func _get_asset_model_scene(visual_type_id: String) -> PackedScene:
	var mapped_path: String = _get_model_path_for_type(visual_type_id)
	if not mapped_path.is_empty():
		return _get_asset_model_scene_by_path(mapped_path)
	if _uses_strict_3d_asset_mapping():
		return null
	var model_name: String = _resolve_asset_model_name(visual_type_id)
	if model_name.is_empty():
		return null
	return _get_asset_model_scene_by_name(model_name)


func _get_asset_model_scene_by_name(model_name: String) -> PackedScene:
	if model_name.strip_edges().is_empty():
		return null
	var model_path: String = "%s/%s.glb" % [KENNEY_MODEL_ROOT, model_name]
	return _get_asset_model_scene_by_path(model_path)


func _get_asset_model_scene_by_path(model_path: String) -> PackedScene:
	if model_path.strip_edges().is_empty():
		return null
	if _model_scene_cache.has(model_path):
		return _model_scene_cache.get(model_path, null) as PackedScene
	if not ResourceLoader.exists(model_path):
		_model_scene_cache[model_path] = null
		return null
	var packed_scene := load(model_path) as PackedScene
	_model_scene_cache[model_path] = packed_scene
	return packed_scene


func _is_nature_kit_model_entry(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var source_id: String = String(entry.get("source_id", "")).strip_edges()
	var model_path: String = String(entry.get("model_path", "")).strip_edges()
	return source_id == "kenney_nature_kit_classic" or model_path.contains("res://Assets/used/terrain/nature_kit_classic/")


func _is_space_station_model_entry(entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var source_id: String = String(entry.get("source_id", "")).strip_edges()
	var model_path: String = String(entry.get("model_path", "")).strip_edges()
	return source_id == "space_station_kit" or model_path.contains("res://Assets/curated/kenney/space_station/")


func _has_3d_asset_mapping() -> bool:
	return not _get_terrain_3d_mapping().is_empty()


func _uses_strict_3d_asset_mapping() -> bool:
	return _has_3d_asset_mapping()


func _has_model_mapping_for_type(type_id: String) -> bool:
	return not _get_model_entry_for_type(type_id).is_empty()


func _get_model_entry_for_type(type_id: String) -> Dictionary:
	var model_key: String = _get_model_key_for_type(type_id)
	if model_key.is_empty():
		return {}
	return Dictionary(Dictionary(_get_terrain_3d_mapping().get("models", {})).get(model_key, {}))


func _get_model_key_for_type(type_id: String) -> String:
	var normalized: String = type_id.strip_edges().to_lower()
	if normalized.is_empty():
		return ""
	var models: Dictionary = Dictionary(_get_terrain_3d_mapping().get("models", {}))
	if models.has(normalized):
		return normalized
	var without_direction: String = _strip_direction_suffix(normalized)
	if models.has(without_direction):
		return without_direction
	return ""


func _get_model_path_for_type(type_id: String) -> String:
	var entry: Dictionary = _get_model_entry_for_type(type_id)
	return String(entry.get("model_path", "")).strip_edges()


func _get_terrain_3d_mapping() -> Dictionary:
	if not _terrain_3d_mapping.is_empty():
		return _terrain_3d_mapping
	if not FileAccess.file_exists(TERRAIN_3D_MAPPING_PATH):
		return {}
	var file := FileAccess.open(TERRAIN_3D_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_terrain_3d_mapping = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	return _terrain_3d_mapping


func _get_terrain_surface_visual_theme_catalog() -> Dictionary:
	if not _terrain_surface_visual_theme_catalog.is_empty():
		return _terrain_surface_visual_theme_catalog
	if not FileAccess.file_exists(TERRAIN_SURFACE_VISUAL_THEME_CATALOG_PATH):
		return {}
	var file := FileAccess.open(TERRAIN_SURFACE_VISUAL_THEME_CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_terrain_surface_visual_theme_catalog = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	return _terrain_surface_visual_theme_catalog


func _get_surface_visual_entry_for_model_key(model_key: String) -> Dictionary:
	var normalized_key: String = model_key.strip_edges().to_lower()
	if normalized_key.is_empty():
		return {}
	for entry_variant in Array(_get_terrain_surface_visual_theme_catalog().get("visuals", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("model_key", "")).strip_edges().to_lower() == normalized_key:
			return entry
	return {}


func _get_npc_unit_visual_mapping() -> Dictionary:
	if not _npc_unit_visual_mapping.is_empty():
		return _npc_unit_visual_mapping
	if not FileAccess.file_exists(NPC_UNIT_VISUAL_MAPPING_PATH):
		return {}
	var file := FileAccess.open(NPC_UNIT_VISUAL_MAPPING_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	_npc_unit_visual_mapping = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	return _npc_unit_visual_mapping


func _get_3d_grid_number(key: String, fallback: float) -> float:
	return float(Dictionary(_get_terrain_3d_mapping().get("grid", {})).get(key, fallback))


func _get_3d_cell_size() -> float:
	return _get_3d_grid_number("cell_size", TILE_SPACING)


func _get_3d_height_step() -> float:
	return _get_3d_grid_number("height_step", HEIGHT_STEP)


func _get_3d_ground_thickness() -> float:
	return _get_3d_grid_number("ground_thickness", TILE_THICKNESS)


func _get_3d_ground_fill() -> float:
	return clampf(_get_3d_grid_number("ground_fill_no_grid", 0.995), 0.1, 1.0)


func _resolve_asset_model_name(visual_type_id: String) -> String:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized.is_empty() or normalized == "ground_flat":
		return ""
	if LEGACY_MODEL_BY_TYPE.has(normalized):
		return String(LEGACY_MODEL_BY_TYPE[normalized])

	var tile_catalog = _get_tile_catalog()
	if tile_catalog == null or not tile_catalog.has_method("get_type"):
		return ""
	var entry: Dictionary = Dictionary(tile_catalog.call("get_type", normalized))
	var texture_path: String = String(entry.get("texture_path", "")).strip_edges()
	if texture_path.is_empty():
		return ""
	return _strip_direction_suffix(texture_path.get_file().get_basename())


func _strip_direction_suffix(value: String) -> String:
	var lowered: String = value.to_lower()
	for suffix in ["_ne", "_nw", "_se", "_sw"]:
		if lowered.ends_with(suffix):
			return value.substr(0, value.length() - suffix.length())
	return value


func _get_asset_rotation_y(visual_type_id: String) -> float:
	var rotation_offset: float = float(_get_model_entry_for_type(visual_type_id).get("rotation_degrees_offset", 0.0))
	match _get_direction_suffix(visual_type_id):
		"ne":
			return 0.0 + rotation_offset
		"se":
			return 90.0 + rotation_offset
		"sw":
			return 180.0 + rotation_offset
		"nw":
			return 270.0 + rotation_offset
		_:
			return rotation_offset


func _get_direction_suffix(visual_type_id: String) -> String:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	var parts := normalized.split("_", false)
	if parts.is_empty():
		return ""
	var suffix: String = String(parts[parts.size() - 1])
	match suffix:
		"ne", "nw", "se", "sw":
			return suffix
		_:
			return ""


func _get_asset_model_scale(visual_type_id: String) -> float:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if not mapped_entry.is_empty():
		return float(mapped_entry.get("scale", float(Dictionary(_get_terrain_3d_mapping().get("grid", {})).get("default_object_scale", 1.0))))
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized.begins_with("rock_") or normalized.begins_with("crater_"):
		return _get_3d_cell_size() * 0.95
	if normalized.begins_with("deko_"):
		return _get_3d_cell_size() * 0.9
	if normalized.begins_with("fahrzeug_"):
		return _get_3d_cell_size() * 0.92
	if normalized.begins_with("gebaeude_"):
		return _get_3d_cell_size() * 0.96
	return _get_3d_cell_size()


func _get_ground_surface_model_scale(visual_type_id: String) -> float:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if not mapped_entry.is_empty() and mapped_entry.has("scale"):
		return float(mapped_entry.get("scale", _get_3d_cell_size()))
	return _get_3d_cell_size()


func _get_asset_texture_pixel_size(visual_type_id: String) -> float:
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized.begins_with("technik_satellite"):
		return TEXTURE_CARD_PIXEL_SIZE * 1.32
	if normalized.begins_with("fahrzeug_"):
		return TEXTURE_CARD_PIXEL_SIZE * 1.22
	if normalized.begins_with("gebaeude_") or normalized.begins_with("plattform_"):
		return TEXTURE_CARD_PIXEL_SIZE * 1.08
	if normalized.begins_with("rock_"):
		return TEXTURE_CARD_PIXEL_SIZE * 0.96
	return TEXTURE_CARD_PIXEL_SIZE


func _get_ground_surface_top_y_offset(visual_type_id: String) -> float:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if mapped_entry.is_empty():
		return 0.0
	var layer: String = String(mapped_entry.get("layer", "")).strip_edges().to_lower()
	if layer != "terrain_surface" and layer != "terrain":
		return 0.0
	return float(mapped_entry.get("y_offset", 0.0))


func _get_asset_y_offset(visual_type_id: String) -> float:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if not mapped_entry.is_empty():
		var layer: String = String(mapped_entry.get("layer", "")).strip_edges().to_lower()
		if layer == "terrain_surface" or layer == "terrain":
			return float(mapped_entry.get("y_offset", 0.0))
		var grid: Dictionary = Dictionary(_get_terrain_3d_mapping().get("grid", {}))
		return float(grid.get("object_y_offset", 0.04)) + float(mapped_entry.get("y_offset", 0.0))
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized.begins_with("crater_") or normalized.begins_with("rail_") or normalized.begins_with("plattform_"):
		return 0.018
	return 0.028


func _get_asset_position_offset(visual_type_id: String) -> Vector3:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if mapped_entry.is_empty():
		return Vector3.ZERO
	if mapped_entry.has("position_offset"):
		var raw_offset = mapped_entry.get("position_offset", [])
		if raw_offset is Array and raw_offset.size() >= 3:
			return Vector3(float(raw_offset[0]), float(raw_offset[1]), float(raw_offset[2]))

	var normalized: String = visual_type_id.strip_edges().to_lower()
	if not normalized.begins_with("wall_straight_"):
		return Vector3.ZERO
	var edge_anchor_offset: float = float(mapped_entry.get("edge_anchor_offset", 0.0))
	if is_zero_approx(edge_anchor_offset):
		return Vector3.ZERO
	var offset_amount: float = edge_anchor_offset * _get_3d_cell_size()
	match _get_direction_suffix(normalized):
		"se":
			return Vector3(offset_amount, 0.0, 0.0)
		"nw":
			return Vector3(-offset_amount, 0.0, 0.0)
		"sw":
			return Vector3(0.0, 0.0, offset_amount)
		"ne":
			return Vector3(0.0, 0.0, -offset_amount)
		_:
			return Vector3.ZERO


func _get_tile_catalog():
	if _tile_catalog == null:
		_tile_catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	return _tile_catalog


func _build_tile_modulate(tile_data) -> Color:
	if tile_data == null:
		return Color(1.0, 1.0, 1.0, 1.0)

	var tile_color := Color(1.0, 1.0, 1.0, 1.0)
	var tile_catalog = _get_tile_catalog()
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	var has_catalog_texture: bool = false
	if not type_id.is_empty() and tile_catalog != null:
		var type_texture: Texture2D = tile_catalog.get_texture(type_id)
		has_catalog_texture = type_texture != null
		if tile_catalog.has_method("is_texture_cached"):
			has_catalog_texture = bool(tile_catalog.call("is_texture_cached", type_id))

	if not has_catalog_texture:
		match String(tile_data.surface_type):
			TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
				tile_color = Color(0.82, 0.82, 0.84, 1.0)
			TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
				tile_color = Color(1.0, 0.95, 0.72, 1.0)
			TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
				tile_color = Color(0.88, 0.78, 0.66, 1.0)

		var height_level: int = int(tile_data.height_level)
		if height_level == 1:
			tile_color = tile_color.lightened(0.08)
		elif height_level >= 2:
			tile_color = tile_color.lightened(0.16)

		if bool(tile_data.blocks_los):
			tile_color = tile_color.darkened(0.1)

		if not bool(tile_data.walkable):
			tile_color = tile_color.darkened(0.14)

	var gp: Vector2i = tile_data.grid_position
	if (gp.x + gp.y) % 2 == 0:
		tile_color = tile_color.darkened(0.08)

	return tile_color


func _get_tile_color(tile_data) -> Color:
	var tile_color := _get_space_kit_terrain_top_color()
	match String(tile_data.surface_type):
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			tile_color = Color(0.37, 0.40, 0.41, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			tile_color = Color(0.54, 0.48, 0.34, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
			tile_color = Color(0.39, 0.39, 0.36, 1.0)
	if int(tile_data.cover_value) > 0:
		tile_color = tile_color.lerp(Color(0.34, 0.50, 0.38, 1.0), 0.18)
	if bool(tile_data.blocks_los):
		tile_color = tile_color.darkened(0.16)
	if not bool(tile_data.walkable):
		tile_color = tile_color.darkened(0.26)
	if int(tile_data.height_level) > 0:
		tile_color = tile_color.lightened(0.08 * float(tile_data.height_level))
	var gp: Vector2i = tile_data.grid_position
	if (gp.x + gp.y) % 2 == 0:
		tile_color = tile_color.darkened(0.045)
	return tile_color


func _get_object_color(type_id: String, tile_data) -> Color:
	var normalized := type_id.strip_edges().to_lower()
	if normalized.begins_with("wall_"):
		return Color(0.64, 0.68, 0.72, 1.0)
	if normalized.begins_with("cliff_") or normalized.begins_with("rock_"):
		return Color(0.45, 0.44, 0.42, 1.0)
	if bool(tile_data.blocks_los):
		return Color(0.58, 0.63, 0.66, 1.0)
	return Color(0.86, 0.68, 0.28, 1.0)


func _get_command_color(command_type: String) -> Color:
	match command_type.strip_edges().to_lower():
		"defend":
			return Color(0.28, 0.9, 0.48, 0.92)
		"engage", "take":
			return Color(1.0, 0.32, 0.24, 0.92)
		"flank":
			return Color(0.98, 0.78, 0.24, 0.92)
		_:
			return Color(0.32, 0.72, 1.0, 0.92)


func _get_contact_color(detection_state: String) -> Color:
	match detection_state.strip_edges().to_lower():
		"suspected":
			return Color(0.95, 0.92, 0.45, 0.82)
		"lost":
			return Color(0.62, 0.65, 0.7, 0.64)
		_:
			return Color(1.0, 0.42, 0.34, 0.92)


func _get_unit_visual_entry(unit: Node) -> Dictionary:
	var mapping: Dictionary = _get_npc_unit_visual_mapping()
	if mapping.is_empty():
		return {}
	var unit_id: String = _get_unit_id(unit)
	var unit_entries: Dictionary = Dictionary(mapping.get("unit_ids", {}))
	var unit_entry: Dictionary = Dictionary(unit_entries.get(unit_id, {}))
	if not unit_entry.is_empty():
		return _apply_unit_visual_loadout(unit, _apply_unit_visual_archetype(unit, unit_entry))
	var archetype_entry: Dictionary = _get_unit_meta_visual_archetype_entry(unit)
	if not archetype_entry.is_empty():
		return _apply_unit_visual_loadout(unit, archetype_entry)
	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	var team_entry: Dictionary = Dictionary(visual_entries.get(_get_unit_team_id(unit), {}))
	if not team_entry.is_empty():
		return _apply_unit_visual_loadout(unit, _apply_unit_visual_archetype(unit, team_entry))
	return _apply_unit_visual_loadout(unit, _apply_unit_visual_archetype(unit, Dictionary(visual_entries.get("default", {}))))


func _apply_unit_visual_archetype(unit: Node, unit_visual_entry: Dictionary) -> Dictionary:
	if unit_visual_entry.is_empty():
		return {}
	var archetype_id: String = _resolve_unit_visual_archetype_id(unit, unit_visual_entry)
	if archetype_id.is_empty():
		return unit_visual_entry
	var archetype_entry: Dictionary = _get_visual_archetype_entry(archetype_id)
	if archetype_entry.is_empty():
		return unit_visual_entry
	var result: Dictionary = _merge_unit_visual_entry(archetype_entry, unit_visual_entry)
	result["resolved_visual_archetype_id"] = String(archetype_entry.get("resolved_visual_archetype_id", _normalize_visual_archetype_id(archetype_id))).strip_edges()
	return result


func _get_unit_meta_visual_archetype_entry(unit: Node) -> Dictionary:
	var archetype_id: String = _resolve_unit_visual_archetype_id(unit, {})
	if archetype_id.is_empty():
		return {}
	var archetype_entry: Dictionary = _get_visual_archetype_entry(archetype_id)
	if not archetype_entry.is_empty() and String(archetype_entry.get("resolved_visual_archetype_id", "")).strip_edges().is_empty():
		archetype_entry["resolved_visual_archetype_id"] = _normalize_visual_archetype_id(archetype_id)
	return archetype_entry


func _resolve_unit_visual_archetype_id(unit: Node, unit_visual_entry: Dictionary) -> String:
	var explicit_archetype_id: String = String(unit_visual_entry.get("visual_archetype_id", unit_visual_entry.get("visual_archetype", ""))).strip_edges().to_lower()
	if not explicit_archetype_id.is_empty():
		return explicit_archetype_id
	if unit != null:
		for meta_key in ["visual_archetype_id", "enemy_visual_archetype_id", "visual_archetype", "enemy_visual_archetype"]:
			if unit.has_meta(meta_key):
				var meta_value: String = String(unit.get_meta(meta_key, "")).strip_edges().to_lower()
				if not meta_value.is_empty():
					return meta_value
		if unit.has_meta("enemy_tactics_config"):
			var tactics_variant: Variant = unit.get_meta("enemy_tactics_config")
			if typeof(tactics_variant) == TYPE_DICTIONARY:
				var tactics_archetype: String = String(Dictionary(tactics_variant).get("visual_archetype", "")).strip_edges().to_lower()
				if not tactics_archetype.is_empty():
					return tactics_archetype
	return ""


func _get_visual_archetype_entry(archetype_id: String, visited: PackedStringArray = PackedStringArray()) -> Dictionary:
	var normalized_id: String = _normalize_visual_archetype_id(archetype_id)
	if normalized_id.is_empty() or visited.has(normalized_id):
		return {}
	var visual_archetypes: Dictionary = Dictionary(_get_npc_unit_visual_mapping().get("visual_archetypes", {}))
	var entry: Dictionary = Dictionary(visual_archetypes.get(normalized_id, {})).duplicate(true)
	if entry.is_empty():
		return {}
	var model_path: String = String(entry.get("model_path", "")).strip_edges()
	var skin_path: String = String(entry.get("skin_path", "")).strip_edges()
	var status: String = String(entry.get("status", "")).strip_edges().to_lower()
	if status == "planned" or model_path.is_empty() or skin_path.is_empty():
		var fallback_id: String = String(entry.get("fallback_archetype_id", "")).strip_edges().to_lower()
		if not fallback_id.is_empty() and fallback_id != normalized_id:
			var next_visited: PackedStringArray = visited.duplicate()
			next_visited.append(normalized_id)
			return _get_visual_archetype_entry(fallback_id, next_visited)
		return {}
	entry["resolved_visual_archetype_id"] = normalized_id
	return entry


func _normalize_visual_archetype_id(archetype_id: String) -> String:
	var normalized_id: String = archetype_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return ""
	var aliases: Dictionary = Dictionary(_get_npc_unit_visual_mapping().get("visual_archetype_aliases", {}))
	return String(aliases.get(normalized_id, normalized_id)).strip_edges().to_lower()


func _apply_unit_visual_loadout(unit: Node, unit_visual_entry: Dictionary) -> Dictionary:
	if unit_visual_entry.is_empty():
		return {}
	var result: Dictionary = unit_visual_entry.duplicate(true)
	if _unit_has_only_empty_weapon_slots(unit):
		result["weapon_visual_disabled"] = true
		result.erase("resolved_visual_loadout_id")
		result.erase("visual_loadout_id")
		result.erase("loadout_id")
		result.erase("blaster_path")
		result.erase("blaster_attachment")
		return result
	var loadout_id: String = _resolve_unit_visual_loadout_id(unit, result)
	if loadout_id.is_empty():
		return result
	var loadout_entry: Dictionary = _get_visual_loadout_entry(loadout_id)
	if loadout_entry.is_empty():
		var default_loadout_id: String = String(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("visual_loadout_id", "")).strip_edges().to_lower()
		loadout_entry = _get_visual_loadout_entry(default_loadout_id)
		if not default_loadout_id.is_empty() and not loadout_entry.is_empty():
			result["resolved_visual_loadout_id"] = default_loadout_id
		return _merge_unit_visual_entry(result, loadout_entry)
	result = _merge_unit_visual_entry(result, loadout_entry)
	result["resolved_visual_loadout_id"] = loadout_id
	return result


func _unit_has_only_empty_weapon_slots(unit: Node) -> bool:
	if unit == null:
		return false
	var saw_slot: bool = false
	for method_name in ["get_weapon_1_id", "get_weapon_2_id"]:
		if not unit.has_method(method_name):
			continue
		var weapon_id: String = String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", String(unit.call(method_name)))).strip_edges().to_lower()
		if weapon_id.is_empty():
			continue
		saw_slot = true
		if weapon_id != "none":
			return false
	return saw_slot


func _resolve_unit_visual_loadout_id(unit: Node, unit_visual_entry: Dictionary) -> String:
	var weapon_loadouts: Dictionary = Dictionary(_get_npc_unit_visual_mapping().get("weapon_visual_loadouts", {}))
	for weapon_id in _get_unit_visual_weapon_ids(unit):
		if weapon_id == "medictool" and weapon_loadouts.has(weapon_id):
			return String(weapon_loadouts.get(weapon_id, "")).strip_edges().to_lower()
	for weapon_id in _get_unit_visual_weapon_ids(unit):
		if (weapon_id == "sniper" or weapon_id == "rocket_launcher") and weapon_loadouts.has(weapon_id):
			return String(weapon_loadouts.get(weapon_id, "")).strip_edges().to_lower()

	var explicit_loadout_id: String = String(unit_visual_entry.get("visual_loadout_id", unit_visual_entry.get("loadout_id", ""))).strip_edges().to_lower()
	if not explicit_loadout_id.is_empty():
		return explicit_loadout_id

	var role_id: String = _get_unit_role_id(unit)
	var role_loadouts: Dictionary = Dictionary(_get_npc_unit_visual_mapping().get("role_visual_loadouts", {}))
	if not role_id.is_empty() and role_loadouts.has(role_id):
		return String(role_loadouts.get(role_id, "")).strip_edges().to_lower()

	for weapon_id in _get_unit_visual_weapon_ids(unit):
		if weapon_loadouts.has(weapon_id):
			return String(weapon_loadouts.get(weapon_id, "")).strip_edges().to_lower()

	return String(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("visual_loadout_id", "")).strip_edges().to_lower()


func _get_visual_loadout_entry(loadout_id: String) -> Dictionary:
	var normalized_id: String = loadout_id.strip_edges().to_lower()
	if normalized_id.is_empty():
		return {}
	var visual_loadouts: Dictionary = Dictionary(_get_npc_unit_visual_mapping().get("visual_loadouts", {}))
	return Dictionary(visual_loadouts.get(normalized_id, {}))


func _merge_unit_visual_entry(base_entry: Dictionary, override_entry: Dictionary) -> Dictionary:
	var result: Dictionary = base_entry.duplicate(true)
	for key_variant in override_entry.keys():
		var key: String = String(key_variant)
		var override_value = override_entry.get(key_variant)
		if override_value is Dictionary and result.get(key, null) is Dictionary:
			result[key] = _merge_unit_visual_entry(Dictionary(result.get(key, {})), Dictionary(override_value))
		else:
			result[key] = override_value
	return result


func _get_unit_model_scene(unit: Node, unit_visual_entry: Dictionary) -> PackedScene:
	if not unit_visual_entry.is_empty():
		return _get_asset_model_scene_by_path(String(unit_visual_entry.get("model_path", "")).strip_edges())
	return _get_asset_model_scene_by_name(_get_unit_model_name(unit))


func _get_unit_visual_name(unit: Node, unit_visual_entry: Dictionary) -> String:
	var visual_id: String = String(unit_visual_entry.get("visual_id", "")).strip_edges()
	if not visual_id.is_empty():
		return visual_id
	return _get_unit_model_name(unit)


func _get_unit_model_scale(unit_visual_entry: Dictionary) -> float:
	if unit_visual_entry.has("scale"):
		return float(unit_visual_entry.get("scale", UNIT_MODEL_SCALE))
	return float(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("scale", UNIT_MODEL_SCALE))


func _get_unit_model_root_rotation_y(unit_visual_entry: Dictionary) -> float:
	if unit_visual_entry.has("rotation_degrees_y"):
		return float(unit_visual_entry.get("rotation_degrees_y", 0.0))
	return float(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("rotation_degrees_y", 0.0))


func _get_unit_animation_paths(unit_visual_entry: Dictionary) -> Dictionary:
	if unit_visual_entry.has("animation_paths"):
		return Dictionary(unit_visual_entry.get("animation_paths", {}))
	var defaults: Dictionary = Dictionary(_get_npc_unit_visual_mapping().get("defaults", {}))
	if defaults.has("animation_paths"):
		return Dictionary(defaults.get("animation_paths", {}))
	return Dictionary(_get_npc_unit_visual_mapping().get("animation_paths", {}))


func _get_unit_helmet_path(unit_visual_entry: Dictionary) -> String:
	var helmet_path: String = String(unit_visual_entry.get("helmet_path", "")).strip_edges()
	if not helmet_path.is_empty():
		return helmet_path
	return String(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("helmet_path", "")).strip_edges()


func _unit_visual_entry_has_helmet(unit_visual_entry: Dictionary) -> bool:
	return not _get_unit_helmet_path(unit_visual_entry).is_empty()


func _get_unit_blaster_path(unit_visual_entry: Dictionary) -> String:
	if bool(unit_visual_entry.get("weapon_visual_disabled", false)):
		return ""
	var blaster_path: String = String(unit_visual_entry.get("blaster_path", "")).strip_edges()
	if not blaster_path.is_empty():
		return blaster_path
	return String(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("blaster_path", "")).strip_edges()


func _unit_visual_entry_has_blaster(unit_visual_entry: Dictionary) -> bool:
	return not _get_unit_blaster_path(unit_visual_entry).is_empty()


func _get_unit_helmet_attachment_entry(unit_visual_entry: Dictionary) -> Dictionary:
	if unit_visual_entry.has("helmet_attachment"):
		return Dictionary(unit_visual_entry.get("helmet_attachment", {}))
	return Dictionary(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("helmet_attachment", {}))


func _get_unit_blaster_attachment_entry(unit_visual_entry: Dictionary) -> Dictionary:
	if unit_visual_entry.has("blaster_attachment"):
		return Dictionary(unit_visual_entry.get("blaster_attachment", {}))
	return Dictionary(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("blaster_attachment", {}))


func _get_unit_socket_entries(unit_visual_entry: Dictionary) -> Dictionary:
	if unit_visual_entry.has("sockets"):
		return Dictionary(unit_visual_entry.get("sockets", {}))
	return Dictionary(Dictionary(_get_npc_unit_visual_mapping().get("defaults", {})).get("sockets", {}))


func _get_helmet_bone_names(attachment_entry: Dictionary) -> PackedStringArray:
	return _get_string_array_from_variant(attachment_entry.get("bone_names", []))


func _get_socket_bone_names(socket_entry: Dictionary) -> PackedStringArray:
	return _get_string_array_from_variant(socket_entry.get("bone_names", []))


func _get_string_array_from_variant(names_variant: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if typeof(names_variant) == TYPE_ARRAY:
		for name_variant in Array(names_variant):
			var name_text: String = String(name_variant).strip_edges()
			if not name_text.is_empty() and not result.has(name_text):
				result.append(name_text)
	elif typeof(names_variant) == TYPE_PACKED_STRING_ARRAY:
		for name_text in PackedStringArray(names_variant):
			if not name_text.strip_edges().is_empty() and not result.has(name_text):
				result.append(name_text.strip_edges())
	return result


func _get_vector3_from_variant(value: Variant, fallback: Vector3) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		return Vector3(value)
	if typeof(value) == TYPE_ARRAY:
		var values: Array = Array(value)
		if values.size() >= 3:
			return Vector3(float(values[0]), float(values[1]), float(values[2]))
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector3(float(dict.get("x", fallback.x)), float(dict.get("y", fallback.y)), float(dict.get("z", fallback.z)))
	return fallback


func _unit_visual_entry_has_skin(unit_visual_entry: Dictionary) -> bool:
	return not String(unit_visual_entry.get("skin_path", "")).strip_edges().is_empty()


func _apply_unit_visual_material(model_instance: Node3D, unit_visual_entry: Dictionary) -> bool:
	var skin_path: String = String(unit_visual_entry.get("skin_path", "")).strip_edges()
	if skin_path.is_empty():
		return true
	if not ResourceLoader.exists(skin_path):
		return false
	var skin_texture := load(skin_path) as Texture2D
	if skin_texture == null:
		return false
	_apply_material_override_recursive(model_instance, _make_texture_material(skin_texture))
	return true


func _get_unit_team_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_team_id"):
		return String(unit.call("get_team_id")).strip_edges().to_lower()
	return ""


func _get_unit_vital_state(unit: Node) -> String:
	if unit != null and unit.has_method("get_vital_state"):
		return String(unit.call("get_vital_state")).strip_edges().to_lower()
	return ""


func _get_unit_role_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_role_id"):
		return String(unit.call("get_role_id")).strip_edges().to_lower()
	if unit != null:
		var role_value = unit.get("role_id") if unit.has_method("get") else null
		if role_value != null:
			return String(role_value).strip_edges().to_lower()
	return ""


func _get_unit_visual_weapon_ids(unit: Node) -> PackedStringArray:
	var result := PackedStringArray()
	for method_name in ["get_active_weapon_id", "get_weapon_1_id", "get_weapon_2_id"]:
		if unit == null or not unit.has_method(method_name):
			continue
		var weapon_id: String = String(WEAPON_DATA_SCRIPT.call("normalize_weapon_id", String(unit.call(method_name)))).strip_edges().to_lower()
		if not weapon_id.is_empty() and not result.has(weapon_id):
			result.append(weapon_id)
	return result


func _get_unit_color(unit: Node) -> Color:
	if _get_unit_team_id(unit) == "team_alpha":
		return Color(0.32, 0.74, 1.0, 1.0)
	return Color(1.0, 0.34, 0.26, 1.0)


func _get_unit_visual_texture(unit: Node) -> Texture2D:
	if unit != null:
		var visual := unit.get_node_or_null("Visual") as Sprite2D
		if visual != null and visual.texture != null:
			return visual.texture
	return FRIENDLY_UNIT_TEXTURE if _get_unit_team_id(unit) == "team_alpha" else ENEMY_UNIT_TEXTURE


func _get_unit_weapon_visual_texture(unit: Node) -> Texture2D:
	if unit == null:
		return null
	var visual := unit.get_node_or_null("Visual") as Sprite2D
	if visual == null:
		return null
	var weapon_visual := visual.get_node_or_null("WeaponVisual") as Sprite2D
	if weapon_visual == null or weapon_visual.texture == null:
		return null
	return weapon_visual.texture


func _get_unit_weapon_visual_offset(unit: Node) -> Vector2:
	if unit == null:
		return Vector2.ZERO
	var visual := unit.get_node_or_null("Visual") as Sprite2D
	if visual == null:
		return Vector2.ZERO
	var weapon_visual := visual.get_node_or_null("WeaponVisual") as Sprite2D
	if weapon_visual == null:
		return Vector2.ZERO
	return weapon_visual.position


func _get_unit_model_name(unit: Node) -> String:
	return FRIENDLY_UNIT_MODEL_NAME if _get_unit_team_id(unit) == "team_alpha" else ENEMY_UNIT_MODEL_NAME


func _get_unit_id(unit: Node) -> String:
	if unit == null:
		return ""
	if unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return str(unit.get_path())


func _is_unit_world_visible(unit: Node) -> bool:
	return _is_unit_base_world_visible(unit) and _fow_allows_unit_proxy(unit)


func _is_unit_base_world_visible(unit: Node) -> bool:
	if unit == null:
		return false
	if unit is CanvasItem:
		return (unit as CanvasItem).visible
	return unit.is_inside_tree()


func _world_to_grid_float(world_position: Vector2) -> Vector2:
	var delta: Vector2 = world_position - _grid_origin_world
	var grid_x: float = ((delta.y / _half_tile_height) + (delta.x / _half_tile_width)) * 0.5
	var grid_y: float = ((delta.y / _half_tile_height) - (delta.x / _half_tile_width)) * 0.5
	return Vector2(grid_x, grid_y)


func _world_to_grid_position(world_position: Vector2) -> Vector2i:
	var grid_position: Vector2 = _world_to_grid_float(world_position)
	return Vector2i(roundi(grid_position.x), roundi(grid_position.y))


func _grid_float_to_world(grid_position: Vector2) -> Vector2:
	return Vector2(
		_grid_origin_world.x + ((grid_position.x - grid_position.y) * _half_tile_width),
		_grid_origin_world.y + ((grid_position.x + grid_position.y) * _half_tile_height)
	)


func _world_to_3d_position(world_position: Vector2, y_offset: float) -> Vector3:
	return _grid_to_3d_position(_world_to_grid_float(world_position), y_offset)


func _world_to_surface_3d_position(world_position: Vector2, y_offset: float) -> Vector3:
	return _world_to_3d_position(world_position, _get_world_surface_y(world_position) + y_offset)


func _get_world_surface_y(world_position: Vector2) -> float:
	return _get_grid_surface_y(_world_to_grid_position(world_position))


func _get_grid_surface_y(grid_position: Vector2i) -> float:
	if _terrain_map_data == null or not _terrain_map_data.has_method("get_tile_at_grid"):
		return 0.0
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return 0.0
	return float(tile_data.height_level) * _get_3d_height_step()


func _grid_to_3d_position(grid_position: Vector2, y_offset: float) -> Vector3:
	var cell_size: float = _get_3d_cell_size()
	return Vector3(grid_position.x * cell_size, y_offset, grid_position.y * cell_size)


func _position_3d_to_world(position_3d: Vector3) -> Vector2:
	var cell_size: float = _get_3d_cell_size()
	return _grid_float_to_world(Vector2(position_3d.x / cell_size, position_3d.z / cell_size))


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.free()
