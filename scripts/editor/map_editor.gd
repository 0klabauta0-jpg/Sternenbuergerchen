extends Node2D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
const TERRAIN_TEXTURE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_texture_catalog.gd")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")
const MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_primary_view_adapter.gd")
const MAP_EDITOR_HEIGHT_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_height_tool.gd")
const MAP_EDITOR_PATROL_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_patrol_tool.gd")
const MAP_EDITOR_PATROL_PREVIEW_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_patrol_preview.gd")
const MAP_EDITOR_TILE_PROPERTY_OVERLAY_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_tile_property_overlay.gd")
const MAP_EDITOR_ADJACENCY_DEBUG_OVERLAY_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_adjacency_debug_overlay.gd")
const TERRAIN_TRUTH_AUDIT_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_truth_audit.gd")
const MAP_EDITOR_MARKER_TOOL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_marker_tool.gd")
const MAP_EDITOR_MISSION_SCENARIO_PANEL_SCRIPT: GDScript = preload("res://scripts/editor/map_editor_mission_scenario_panel.gd")
const MULTIPLAYER_MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const HOVER_SCROLL_BEHAVIOR_SCRIPT: GDScript = preload("res://scripts/ui/hover_scroll_behavior.gd")
const DEFAULT_MAP_PATH: String = "res://maps/test_mission.json"
const DEFAULT_NEW_MAP_PATH: String = "res://maps/new_map.json"
const DEFAULT_NEW_MAP_NAME: String = "new_map"
const DEFAULT_FALLBACK_GRID_SIZE: Vector2i = Vector2i(64, 64)
const DEFAULT_NEW_MAP_GRID_SIZE: Vector2i = Vector2i(32, 32)
const DEFAULT_GRID_ORIGIN: Vector2 = Vector2(0.0, 0.0)
const DEFAULT_HALF_TILE_WIDTH: float = 64.0
const DEFAULT_HALF_TILE_HEIGHT: float = 32.0
const MIN_NEW_MAP_GRID_DIMENSION: int = 1
const MAX_NEW_MAP_GRID_DIMENSION: int = 512
const MIN_MISSION_SLOT_COUNT: int = 1
const MAX_MISSION_SLOT_COUNT: int = 50
const EDITABLE_MARKER_IDS: PackedStringArray = [
	"spawn_alpha",
	"spawn_bravo",
	"objective_point",
]
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)
const MIN_CAMERA_ZOOM: float = 0.1
const MAX_CAMERA_ZOOM: float = 3.0
const CAMERA_ZOOM_STEP: float = 0.05
const CAMERA_PAN_SPEED: float = 800.0
const PATROL_OVERLAY_NAME: String = "PatrolOverlay"
const TILE_PROPERTY_OVERLAY_NAME: String = "TilePropertyOverlay"
const ADJACENCY_DEBUG_OVERLAY_NAME: String = "AdjacencyDebugOverlay"
const PATROL_SPAWN_IDS: PackedStringArray = ["enemy_delta", "enemy_echo", "enemy_alpha", "enemy_bravo"]
const PATROL_PICK_RADIUS: float = 28.0
const PATROL_SEGMENT_PICK_RADIUS: float = 18.0
const MARKER_OVERLAY_NAME: String = "MarkerOverlay"
const MARKER_PICK_RADIUS: float = 26.0
const MARKER_DRAG_THRESHOLD: float = 4.0
const PRIMARY_VIEW_LEGACY_VISIBILITY_NODES: PackedStringArray = [
	"TileContainer",
	"Terrain",
	"CliffContainer",
	"WallContainer",
	"ObjectContainer",
	"GridOverlay",
	TILE_PROPERTY_OVERLAY_NAME,
	ADJACENCY_DEBUG_OVERLAY_NAME,
	"SelectionOutline",
	PATROL_OVERLAY_NAME,
	MARKER_OVERLAY_NAME,
]
const PRIMARY_VIEW_LEGACY_CLEAR_NODES: PackedStringArray = [
	"Terrain",
	"CliffContainer",
	"WallContainer",
	"ObjectContainer",
	"GridOverlay",
	TILE_PROPERTY_OVERLAY_NAME,
	ADJACENCY_DEBUG_OVERLAY_NAME,
	"SelectionOutline",
	PATROL_OVERLAY_NAME,
	MARKER_OVERLAY_NAME,
]
const DEFAULT_SCENARIO_PATH: String = "res://data/mission_scenarios/new_mission_scenario.json"
const DEFAULT_SCENARIO_DIR: String = "res://data/mission_scenarios"
const LIVE_TEST_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const LIVE_TEST_SCENARIO_SCRATCH_PATH: String = "user://mission_editor_live_test_scenario.json"
const SCENARIO_POSITION_META: String = "__position__"
const HEIGHT_TOOL_MODE_RAISE: String = "raise"
const HEIGHT_TOOL_MODE_LOWER: String = "lower"
const HEIGHT_TOOL_MODE_SET_0: String = "set_0"
const HEIGHT_TOOL_MODE_SET_1: String = "set_1"
const HEIGHT_TOOL_MODE_SET_2: String = "set_2"
const AUTO_CLIFF_EDGE_OFFSETS: Array = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
]
const AUTO_CLIFF_CORNER_ENTRIES: Array = [
	[Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), "cliff_corner_sw"],
	[Vector2i(1, 0), Vector2i(0, -1), Vector2i(1, -1), "cliff_corner_se"],
	[Vector2i(-1, 0), Vector2i(0, 1), Vector2i(-1, 1), "cliff_corner_nw"],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), "cliff_corner_ne"],
]
const AUTHORING_TOOL_SELECT: String = "select"
const AUTHORING_TOOL_BRUSH: String = "terrain_brush"
const AUTHORING_TOOL_ERASER: String = "eraser"
const AUTHORING_TOOL_HEIGHT: String = "height"
const AUTHORING_TOOL_MARKER: String = "marker"
const AUTHORING_TOOL_PATROL: String = "patrol"
const AUTHORING_TOOL_NETWORK_DRAG: String = "network_drag"
const TOOL_BUTTON_SIZE: Vector2 = Vector2(34.0, 30.0)
const MAX_UNDO_STACK_SIZE: int = 32
const PALETTE_PREVIEW_ICON_SIZE: Vector2i = Vector2i(72, 72)
const PALETTE_PANEL_MIN_WIDTH: float = 430.0
const PALETTE_SELECTED_PREVIEW_SIZE: Vector2 = Vector2(112.0, 112.0)
const PALETTE_GROUP_SCROLL_HEIGHT: float = 150.0
const PALETTE_GROUP_COLUMNS: int = 2
const PALETTE_GROUP_BUTTON_HEIGHT: float = 22.0
const PALETTE_ASSET_COLUMNS: int = 2
const PALETTE_ASSET_LIST_MIN_HEIGHT: float = 560.0
const PALETTE_ASSET_COLUMN_WIDTH: int = 190
const PALETTE_RECENT_MAX_COUNT: int = 8
const PALETTE_SCALE_PRESETS: Array = [0.5, 1.0, 1.6, 2.0]
const PALETTE_AUTHORING_PREFERENCES_PATH: String = "user://map_editor_builder_preferences.json"
const PALETTE_AUTHORING_PREFERENCES_SCHEMA: String = "sternenbuergerchen.map_editor.palette_preferences.v1"
const RUNTIME_BUILDER_RAIL_NAME: String = "RuntimeBuilderToolRail"
const RUNTIME_BUILDER_RAIL_WIDTH: float = 58.0
const RUNTIME_BUILDER_RAIL_GAP: float = 6.0
const RUNTIME_BUILDER_BUTTON_SIZE: Vector2 = Vector2(44.0, 34.0)
const RUNTIME_BUILDER_ENTRY_SCENE_PATH: String = "res://scenes/editor/map_builder_workbench.tscn"
const RUNTIME_MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const BUILDER_QUICK_TERRAIN_TYPE_ID: String = "ground_flat"
const BUILDER_QUICK_ROAD_TYPE_ID: String = "spacekit_terrain_road_straight"
const BUILDER_QUICK_ASSET_TYPE_ID: String = "factory_building_a"
const BUILDER_QUICK_FACTORY_TYPE_ID: String = "factory_building_a"
const BUILDER_QUICK_SPACE_FLOOR_TYPE_ID: String = "modular_floor"
const BUILDER_QUICK_STATION_DOOR_WALL_TYPE_ID: String = "station_wall_door"
const BUILDER_QUICK_STATION_DOOR_CLOSED_TYPE_ID: String = "station_set_door_single_closed"
const BUILDER_QUICK_STATION_DOOR_HALF_TYPE_ID: String = "station_set_door_single_half"
const BUILDER_QUICK_STATION_DOOR_OPEN_TYPE_ID: String = "station_set_door_single"
const NETWORK_KIND_ROAD: String = "road"
const NETWORK_KIND_RAIL: String = "rail"
const NETWORK_KIND_PIPE: String = "pipe"
const NETWORK_KIND_WALL: String = "wall"
const NETWORK_KIND_CLIFF: String = "cliff"
const NETWORK_DIR_N: int = 1
const NETWORK_DIR_E: int = 2
const NETWORK_DIR_S: int = 4
const NETWORK_DIR_W: int = 8
const OBJECT_SCALE_DEFAULT: float = 1.0
const OBJECT_SCALE_MIN: float = 0.25
const OBJECT_SCALE_MAX: float = 2.5
const OBJECT_SCALE_STEP: float = 0.05
const PALETTE_ITEM_FG_COLOR: Color = Color(0.9, 0.93, 0.9, 1.0)
const PALETTE_SELECTED_BG_COLOR: Color = Color(1.0, 0.86, 0.22, 0.84)
const PALETTE_SELECTED_FG_COLOR: Color = Color(0.08, 0.06, 0.02, 1.0)
const RIGHT_CONTEXT_DRAG_THRESHOLD_PX: float = 6.0
const CONTEXT_MENU_ROTATE_LEFT_ID: int = 101
const CONTEXT_MENU_ROTATE_RIGHT_ID: int = 102
const CONTEXT_MENU_ERASE_OBJECT_ID: int = 103
const INSPECTOR_SECTION_MAP_SETTINGS: String = "map_settings"
const INSPECTOR_SECTION_MARKERS: String = "markers"
const INSPECTOR_SECTION_MISSION_SCENARIO: String = "mission_scenario"
const EDITOR_UI_REFRESH_SELECTION: int = 1 << 0
const EDITOR_UI_REFRESH_PROPERTIES: int = 1 << 1
const EDITOR_UI_REFRESH_TOOL_STATE: int = 1 << 2
const EDITOR_UI_REFRESH_HOVER: int = 1 << 3
const EDITOR_UI_REFRESH_SCENARIO: int = 1 << 4
const EDITOR_UI_REFRESH_PATROL_PREVIEW: int = 1 << 5

@export var map_file_path: String = ""

var _terrain_map_data = null
var _terrain_registry = null
var _tile_catalog = null
var _terrain_renderer = null
var _tile_sprites_by_grid: Dictionary = {}
var _cliff_sprites_by_grid: Dictionary = {}
var _wall_sprites_by_grid: Dictionary = {}
var _object_sprites_by_grid: Dictionary = {}
var _selected_grid_position: Vector2i = Vector2i(-1, -1)
var _last_selected_surface_type: String = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE
var _last_selected_edge_type: String = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
var _selected_grids: Array = []
var _selection_tool_enabled: bool = false
var _eraser_tool_enabled: bool = false
var _selected_type_id: String = ""
var _is_panning: bool = false
var _is_rotating_3d_camera: bool = false
var _is_painting: bool = false
var _last_painted_grid: Vector2i = Vector2i(-1, -1)
var _hover_preview: Sprite2D = null
var _hover_grid_position: Vector2i = Vector2i(-1, -1)
var _dirty: bool = false
var _is_refreshing_property_controls: bool = false
var _is_refreshing_map_settings_controls: bool = false
var _last_undo_state: Dictionary = {}
var _undo_stack: Array[Dictionary] = []
var _active_undo_transaction: Dictionary = {}
var _current_map_path: String = DEFAULT_MAP_PATH
var _pending_dialog_action: String = ""
var _height_tool_enabled: bool = false
var _height_tool_mode: String = HEIGHT_TOOL_MODE_RAISE
var _height_tool_edge_type: String = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
var _patrol_tool_enabled: bool = false
var _patrol_spawn_id: String = "enemy_delta"
var _dragged_patrol_waypoint_index: int = -1
var _network_drag_tool_enabled: bool = false
var _network_tool_kind: String = NETWORK_KIND_ROAD
var _is_network_dragging: bool = false
var _network_drag_start_grid: Vector2i = Vector2i(-1, -1)
var _network_drag_current_grid: Vector2i = Vector2i(-1, -1)
var _network_drag_preview_path: Array[Vector2i] = []
var _last_network_apply_snapshot: Dictionary = {}
var _marker_tool_enabled: bool = false
var _selected_marker_id: String = ""
var _dragged_marker_id: String = ""
var _dragged_marker_press_screen_position: Vector2 = Vector2.ZERO
var _is_dragging_marker: bool = false
var _has_dragged_marker: bool = false
var _is_refreshing_marker_controls: bool = false
var _marker_feedback_text: String = ""
var _mission_scenario = null
var _current_scenario_path: String = ""
var _scenario_dirty: bool = false
var _is_refreshing_scenario_controls: bool = false
var _scenario_feedback_text: String = ""
var _mission_scenario_panel_controller = null
var _terrain_3d_view = null
var _3d_refresh_queued: bool = false
var _editor_ui_refresh_pending_flags: int = 0
var _editor_ui_refresh_queued: bool = false
var _editor_ui_refresh_request_count: int = 0
var _editor_ui_refresh_flush_count: int = 0
var _editor_ui_refresh_flag_request_counts: Dictionary = {}
var _last_editor_ui_refresh_requested_flags: int = 0
var _last_editor_ui_refresh_flushed_flags: int = 0
var _queued_hover_world_position: Vector2 = Vector2.ZERO
var _queued_hover_has_world_position: bool = false
var _queued_hover_hide: bool = false
var _patrol_preview_path_id: String = ""
var _last_patrol_preview_snapshot: Dictionary = {}
var _queued_patrol_preview_world_position: Vector2 = Vector2.ZERO
var _queued_patrol_preview_has_world_position: bool = false
var _queued_patrol_preview_hide: bool = false
var _tile_property_overlay_enabled: bool = false
var _tile_property_overlay_cells_by_grid: Dictionary = {}
var _tile_property_overlay_rebuild_count: int = 0
var _tile_property_overlay_dirty_refresh_count: int = 0
var _tile_property_overlay_skipped_disabled_count: int = 0
var _tile_property_overlay_last_dirty_grid_count: int = 0
var _adjacency_debug_overlay_enabled: bool = false
var _adjacency_debug_overlay_rebuild_count: int = 0
var _adjacency_debug_overlay_skipped_disabled_count: int = 0
var _adjacency_debug_overlay_drawn_entries_by_grid: Dictionary = {}
var _active_palette_group_id: String = ""
var _palette_preview_textures: Dictionary = {}
var _palette_preview_sources: Dictionary = {}
var _placement_object_scale: float = OBJECT_SCALE_DEFAULT
var _palette_search_query: String = ""
var _palette_favorite_type_ids: PackedStringArray = PackedStringArray()
var _palette_recent_type_ids: PackedStringArray = PackedStringArray()
var _palette_favorites_filter_enabled: bool = false
var _palette_preferences_loaded: bool = false
var _palette_preferences_saved: bool = false
var _palette_preferences_last_error: String = ""
var _palette_preferences_load_count: int = 0
var _palette_preferences_save_count: int = 0
var _palette_authoring_preferences_path: String = PALETTE_AUTHORING_PREFERENCES_PATH
var _last_dirty_neighborhood_snapshot: Dictionary = {}
var _right_mouse_pressed: bool = false
var _right_mouse_dragged: bool = false
var _right_mouse_press_screen_position: Vector2 = Vector2.ZERO
var _right_mouse_press_world_position: Vector2 = Vector2.ZERO
var _right_mouse_additive_selection: bool = false
var _right_drag_selection_active: bool = false
var _editor_context_menu: PopupMenu = null
var _runtime_builder_status_text: String = "Runtime Map-Editor bereit."
var _inspector_section_collapsed: Dictionary = {
	INSPECTOR_SECTION_MAP_SETTINGS: false,
	INSPECTOR_SECTION_MARKERS: false,
	INSPECTOR_SECTION_MISSION_SCENARIO: true,
}


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_ensure_terrain_registry()
	_load_tile_catalog()
	_terrain_renderer = TERRAIN_MAP_RENDERER_SCRIPT.new(_tile_catalog)
	_populate_surface_type_options()
	_populate_edge_type_options()
	_populate_brush_size_options()
	_configure_property_height_spinbox()
	_apply_editor_control_panel_style()
	_ensure_editor_save_controls()
	_ensure_map_name_controls()
	_ensure_object_rotation_controls()
	_ensure_object_scale_controls()
	_ensure_palette_workflow_controls()
	_ensure_palette_browser_layout_controls()
	_ensure_palette_quick_filter_controls()
	_ensure_runtime_builder_workbench_controls()
	_ensure_terrain_truth_inspector_controls()
	_ensure_editor_context_menu()
	_load_palette_authoring_preferences()
	_populate_tile_palette()
	_connect_ui_signals()
	_add_height_tool_controls()
	_add_selection_tool_button()
	_add_eraser_tool_button()
	_add_patrol_tool_controls()
	_add_tile_property_overlay_controls()
	_add_adjacency_debug_overlay_controls()
	_arrange_topbar_authoring_tools()
	_ensure_marker_editor_controls()
	_ensure_mission_authoring_controls()
	_ensure_authoring_status_controls()
	_ensure_inspector_section_controls()
	HOVER_SCROLL_BEHAVIOR_SCRIPT.call("install", self)
	_apply_contextual_help_ids()
	_ensure_patrol_overlay()
	_ensure_tile_property_overlay()
	_ensure_adjacency_debug_overlay()
	_ensure_marker_overlay()
	_ensure_3d_primary_view()
	_load_map(map_file_path if not map_file_path.is_empty() else DEFAULT_MAP_PATH)


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("UI/PalettePanel"), "editor.tile_palette")
	_apply_help_id(get_node_or_null("UI/%s" % RUNTIME_BUILDER_RAIL_NAME), "map_editor.runtime_builder")
	_apply_help_id(get_node_or_null("UI/PalettePanel/Margin/VBox/TileTypeList"), "editor.tile_palette")
	_apply_help_id(get_node_or_null("UI/TopBar/Margin/HBox/BrushButton"), "editor.tile_palette")
	_apply_help_id(_get_brush_size_option_button(), "editor.brush_size")
	_apply_help_id(_get_height_tool_button(), "editor.height_tool")
	_apply_help_id(_get_height_mode_option_button(), "editor.height_tool")
	_apply_help_id(_get_height_spinbox(), "editor.height_tool")
	_apply_help_id(get_node_or_null("UI/PropertyPanel/Margin/VBox/HeightRow"), "map_editor.height_tool")
	_apply_help_id(_get_height_edge_option_button(), "editor.edge.slope")
	_apply_help_id(_get_edge_type_option_button(), "editor.edge.cliff")
	_apply_help_id(_get_surface_option_button(), "editor.surface")
	_apply_help_id(_get_marker_tool_button(), "editor.object")
	_apply_help_id(_get_add_marker_type_option_button(), "editor.object")
	_apply_help_id(_get_add_marker_button(), "editor.object")
	_apply_help_id(_get_marker_list(), "editor.object")
	_apply_help_id(_get_remove_marker_button(), "editor.object")
	_apply_help_id(get_node_or_null("UI/TopBar/Margin/HBox/LoadButton"), "editor.load")
	_apply_help_id(get_node_or_null("UI/TopBar/Margin/HBox/SaveButton"), "editor.save")
	_apply_help_id(get_node_or_null("UI/TopBar"), "map_editor.save_load")
	_apply_help_id(get_node_or_null("UI/SaveAsDialog"), "editor.save_as")
	_apply_help_id(_get_scenario_button("ScenarioLoadButton"), "editor.load")
	_apply_help_id(_get_scenario_button("ScenarioSaveButton"), "editor.save")
	_apply_help_id(_get_scenario_button("ScenarioSaveAsButton"), "editor.save_as")
	_apply_help_id(_get_scenario_button("ScenarioLiveTestButton"), "editor.playtest")
	_apply_help_id(_get_scenario_option_button("ScenarioEnemyTacticProfileOption"), "map_editor.tactical_profile")
	_apply_help_id(_get_scenario_option_button("ScenarioEnemyHeavyRoleOption"), "map_editor.tactical_profile")
	_apply_help_id(_get_scenario_option_button("ScenarioEnemyATWeaponOption"), "map_editor.tactical_profile")
	_apply_help_id(_get_scenario_option_button("ScenarioAirAssetRiskOption"), "map_editor.tactical_profile")
	_apply_help_id(_get_scenario_option_button("ScenarioLZThreatZoneOption"), "map_editor.tactical_profile")
	_apply_help_id(_get_scenario_option_button("ScenarioCommIntensityOption"), "map_editor.tactical_profile")


func _apply_help_id(node: Node, help_id: String) -> void:
	if node == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	node.set_meta("help_id", normalized_id)


func _process(delta: float) -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		var view_direction := Vector2.ZERO
		if Input.is_key_pressed(KEY_W):
			view_direction.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			view_direction.y += 1.0
		if Input.is_key_pressed(KEY_A):
			view_direction.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			view_direction.x += 1.0
		if view_direction != Vector2.ZERO:
			primary_3d_view.call("pan_camera", view_direction.normalized(), delta)
		if Input.is_key_pressed(KEY_Q):
			primary_3d_view.call("rotate_camera", -80.0 * delta)
		if Input.is_key_pressed(KEY_E):
			primary_3d_view.call("rotate_camera", 80.0 * delta)
		return

	var camera := _get_camera()
	if camera == null:
		return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if direction != Vector2.ZERO:
		camera.position += direction.normalized() * CAMERA_PAN_SPEED * delta / camera.zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.ctrl_pressed and key_event.physical_keycode == KEY_Z:
			_undo_last_change()
			return
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_DELETE:
			if _delete_selected_marker():
				return
		if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
			_clear_marker_selection()
			_on_tile_type_deselected()
			return

	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button_event.pressed and not _is_pointer_over_control():
			_adjust_camera_zoom(CAMERA_ZOOM_STEP)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.pressed and not _is_pointer_over_control():
			_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mouse_button_event.pressed and not _is_pointer_over_control()
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			if mouse_button_event.pressed:
				_handle_right_mouse_press(mouse_button_event)
			else:
				_handle_right_mouse_release(mouse_button_event)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			var world_position: Vector2 = _screen_to_editor_world_position(mouse_button_event.position)
			if _marker_tool_enabled and not _is_pointer_over_control():
				if mouse_button_event.pressed:
					if _handle_marker_left_press(mouse_button_event):
						return
				elif _finish_marker_drag():
					return
			if _patrol_tool_enabled and not _is_pointer_over_control():
				if mouse_button_event.pressed:
					_handle_patrol_left_click(world_position, mouse_button_event.ctrl_pressed)
				else:
					_dragged_patrol_waypoint_index = -1
				return
			if not mouse_button_event.pressed:
				if _is_network_dragging:
					_finish_network_drag_at_world_position(world_position)
					return
				if _is_painting:
					commit_undo_transaction()
				_is_painting = false
				_last_painted_grid = Vector2i(-1, -1)
				return
			if _is_pointer_over_control():
				return
			if _network_drag_tool_enabled:
				_begin_network_drag_at_world_position(world_position)
				return
			if _height_tool_enabled:
				begin_undo_transaction("height_stroke")
				_is_painting = true
				_last_painted_grid = Vector2i(-1, -1)
				_apply_height_tool_at_world_position(world_position)
				return
			if _eraser_tool_enabled:
				begin_undo_transaction("eraser_stroke")
				_is_painting = true
				_last_painted_grid = Vector2i(-1, -1)
				_apply_eraser_at_world_position(world_position)
				return
			var grid_pos = _terrain_registry.world_to_grid(world_position)
			if _selection_tool_enabled:
				_select_grid_with_selection_tool(grid_pos, mouse_button_event.ctrl_pressed)
				return
			if _is_brush_enabled() and _has_selected_type():
				begin_undo_transaction("brush_stroke")
				_is_painting = true
				_last_painted_grid = Vector2i(-1, -1)
				_apply_brush_at_world_position(world_position)
				return
			_select_tile_at_world_position(world_position)
			return

	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		var world_position: Vector2 = _screen_to_editor_world_position(mouse_motion.position)
		if _update_marker_drag(world_position, mouse_motion.relative):
			return
		if _patrol_tool_enabled and _dragged_patrol_waypoint_index >= 0 and not _is_pointer_over_control():
			_move_patrol_waypoint(_dragged_patrol_waypoint_index, world_position)
			return
		if _right_mouse_pressed:
			if mouse_motion.position.distance_to(_right_mouse_press_screen_position) >= RIGHT_CONTEXT_DRAG_THRESHOLD_PX:
				_right_mouse_dragged = true
			if _selection_tool_enabled and not _is_pointer_over_control():
				if _right_mouse_dragged:
					_right_drag_selection_active = true
					_select_grid_area_from_world(_right_mouse_press_world_position, world_position, _right_mouse_additive_selection)
				return
		if _is_rotating_3d_camera:
			var primary_3d_view = _get_primary_3d_view()
			if primary_3d_view != null:
				primary_3d_view.call("rotate_camera", -mouse_motion.relative.x * 0.28)
			return
		if _is_panning:
			var primary_3d_view = _get_primary_3d_view()
			if primary_3d_view != null:
				primary_3d_view.call("pan_camera_pixels", -mouse_motion.relative)
			else:
				var camera := _get_camera()
				if camera != null:
					camera.position -= mouse_motion.relative * camera.zoom
			return
		if _is_painting and _height_tool_enabled:
			_apply_height_tool_at_world_position(world_position)
			return
		if _is_painting and _eraser_tool_enabled:
			_apply_eraser_at_world_position(world_position)
			return
		if _is_painting and _is_brush_enabled() and _has_selected_type():
			_apply_brush_at_world_position(world_position)
			return
		if _is_network_dragging and not _is_pointer_over_control():
			_update_network_drag_preview_at_world_position(world_position)
			return
		if _patrol_tool_enabled and not _is_pointer_over_control():
			_queue_hover_preview_hide()
			_queue_patrol_route_preview_update(world_position)
			return
		if _is_brush_enabled() and not _is_pointer_over_control():
			_queue_patrol_route_preview_hide()
			_queue_hover_preview_update(world_position)
			return
		_queue_patrol_route_preview_hide()
		_queue_hover_preview_hide()


func _handle_right_mouse_press(mouse_button_event: InputEventMouseButton) -> void:
	_right_mouse_pressed = false
	_right_mouse_dragged = false
	_right_drag_selection_active = false
	if mouse_button_event == null or _is_pointer_over_control():
		_is_rotating_3d_camera = false
		_is_panning = false
		return
	_right_mouse_pressed = true
	_right_mouse_press_screen_position = mouse_button_event.position
	_right_mouse_press_world_position = _screen_to_editor_world_position(mouse_button_event.position)
	_right_mouse_additive_selection = mouse_button_event.ctrl_pressed
	_is_rotating_3d_camera = not _selection_tool_enabled and _get_primary_3d_view() != null
	_is_panning = not _selection_tool_enabled and _get_primary_3d_view() == null


func _handle_right_mouse_release(mouse_button_event: InputEventMouseButton) -> void:
	var was_pressed: bool = _right_mouse_pressed
	var release_position: Vector2 = mouse_button_event.position if mouse_button_event != null else _right_mouse_press_screen_position
	if was_pressed and release_position.distance_to(_right_mouse_press_screen_position) >= RIGHT_CONTEXT_DRAG_THRESHOLD_PX:
		_right_mouse_dragged = true
	var had_area_selection: bool = _right_drag_selection_active
	_right_mouse_pressed = false
	_right_drag_selection_active = false
	_is_rotating_3d_camera = false
	_is_panning = false
	if not was_pressed or _is_pointer_over_control():
		return
	var release_world_position: Vector2 = _screen_to_editor_world_position(release_position)
	if had_area_selection:
		_select_grid_area_from_world(_right_mouse_press_world_position, release_world_position, _right_mouse_additive_selection)
		return
	if _right_mouse_dragged:
		return
	_select_tile_at_world_position(release_world_position)
	_show_editor_context_menu(release_position)


func _show_editor_context_menu(screen_position: Vector2) -> void:
	var menu := _ensure_editor_context_menu()
	if menu == null:
		return
	_refresh_editor_context_menu_actions()
	menu.position = Vector2i(roundi(screen_position.x), roundi(screen_position.y))
	menu.popup()


func _refresh_editor_context_menu_actions() -> void:
	var menu := _ensure_editor_context_menu()
	if menu == null:
		return
	var has_selected_tile: bool = _get_selected_tile() != null
	var has_rotatable_object: bool = _tile_has_rotatable_object(_get_selected_tile())
	var can_erase_object: bool = has_selected_tile and _selected_tile_has_erasable_object()
	_set_context_menu_item_disabled(menu, CONTEXT_MENU_ROTATE_LEFT_ID, not has_rotatable_object)
	_set_context_menu_item_disabled(menu, CONTEXT_MENU_ROTATE_RIGHT_ID, not has_rotatable_object)
	_set_context_menu_item_disabled(menu, CONTEXT_MENU_ERASE_OBJECT_ID, not can_erase_object)


func _set_context_menu_item_disabled(menu: PopupMenu, item_id: int, disabled: bool) -> void:
	if menu == null:
		return
	var item_index: int = menu.get_item_index(item_id)
	if item_index >= 0:
		menu.set_item_disabled(item_index, disabled)


func _on_editor_context_menu_id_pressed(id: int) -> void:
	match id:
		CONTEXT_MENU_ROTATE_LEFT_ID:
			_rotate_selected_object(-90.0)
		CONTEXT_MENU_ROTATE_RIGHT_ID:
			_rotate_selected_object(90.0)
		CONTEXT_MENU_ERASE_OBJECT_ID:
			_erase_selected_tile_object()


func _selected_tile_has_erasable_object() -> bool:
	var tile_data = _get_selected_tile()
	if tile_data == null:
		return false
	var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower() if tile_data.object_type_id is String else ""
	if not object_type_id.is_empty():
		return true
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	if type_id.is_empty() or _tile_catalog == null:
		return false
	if _tile_catalog.has_method("is_object_layer_type") and bool(_tile_catalog.call("is_object_layer_type", type_id)):
		return true
	if _tile_catalog.has_method("is_structure_layer_type") and bool(_tile_catalog.call("is_structure_layer_type", type_id)):
		return true
	return false


func _erase_selected_tile_object() -> bool:
	var tile_data = _get_selected_tile()
	if tile_data == null or not _erase_object_layer_from_tile(tile_data):
		return false
	_refresh_tile_visual(tile_data)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
	_mark_dirty(true)
	return true


func _load_map(path: String) -> void:
	_current_map_path = path
	_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", path)
	var has_load_issue: bool = _terrain_map_data != null and _terrain_map_data.has_method("has_load_issue") and bool(_terrain_map_data.call("has_load_issue"))
	if has_load_issue:
		var load_issue_message: String = String(_terrain_map_data.call("get_load_issue_message"))
		_current_map_path = DEFAULT_NEW_MAP_PATH
		_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call(
			"create_empty",
			DEFAULT_NEW_MAP_NAME,
			DEFAULT_FALLBACK_GRID_SIZE,
			DEFAULT_GRID_ORIGIN,
			DEFAULT_HALF_TILE_WIDTH,
			DEFAULT_HALF_TILE_HEIGHT
		)
		call_deferred("_show_load_issue_dialog", load_issue_message, path)
	elif _terrain_map_data == null or _terrain_map_data.call("get_tiles").is_empty():
		_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call(
			"create_empty",
			path.get_file().get_basename() if not path.is_empty() else DEFAULT_NEW_MAP_NAME,
			DEFAULT_FALLBACK_GRID_SIZE,
			DEFAULT_GRID_ORIGIN,
			DEFAULT_HALF_TILE_WIDTH,
			DEFAULT_HALF_TILE_HEIGHT
		)

	_normalize_object_layer_tiles()
	_tile_sprites_by_grid.clear()
	_cliff_sprites_by_grid.clear()
	_object_sprites_by_grid.clear()
	_set_selected_grid_position(Vector2i(-1, -1))
	_clear_patrol_route_preview(false)
	_clear_undo_history()
	_mark_dirty(false)
	_rebuild_registry_from_map_data()
	_rebuild_tile_sprites()
	_center_camera_on_map()
	_refresh_selection_visual()
	_refresh_property_panel()
	_refresh_top_bar()
	_refresh_patrol_overlay()
	_rebuild_tile_property_overlay()
	_clear_adjacency_debug_overlay()
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()
	if _current_scenario_path.is_empty() and not _scenario_dirty:
		_mission_scenario = _create_default_mission_scenario()
	_refresh_mission_authoring_controls()


func _create_new_map(grid_size: Vector2i = DEFAULT_NEW_MAP_GRID_SIZE) -> void:
	var normalized_grid_size := Vector2i(
		clampi(grid_size.x, MIN_NEW_MAP_GRID_DIMENSION, MAX_NEW_MAP_GRID_DIMENSION),
		clampi(grid_size.y, MIN_NEW_MAP_GRID_DIMENSION, MAX_NEW_MAP_GRID_DIMENSION)
	)
	_current_map_path = DEFAULT_NEW_MAP_PATH
	_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call(
		"create_empty",
		DEFAULT_NEW_MAP_NAME,
		normalized_grid_size,
		DEFAULT_GRID_ORIGIN,
		DEFAULT_HALF_TILE_WIDTH,
		DEFAULT_HALF_TILE_HEIGHT
	)
	_tile_sprites_by_grid.clear()
	_cliff_sprites_by_grid.clear()
	_object_sprites_by_grid.clear()
	_set_selected_grid_position(Vector2i(-1, -1))
	_clear_patrol_route_preview(false)
	_clear_undo_history()
	_mark_dirty(false)
	_rebuild_registry_from_map_data()
	_rebuild_tile_sprites()
	_center_camera_on_map()
	_refresh_selection_visual()
	_refresh_property_panel()
	_refresh_top_bar()
	_refresh_patrol_overlay()
	_rebuild_tile_property_overlay()
	_clear_adjacency_debug_overlay()
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()
	if _current_scenario_path.is_empty() and not _scenario_dirty:
		_mission_scenario = _create_default_mission_scenario()
	_refresh_mission_authoring_controls()


func _normalize_object_layer_tiles() -> void:
	if _terrain_map_data == null or _tile_catalog == null or not _tile_catalog.has_method("is_object_layer_type"):
		return

	for tile_data in _terrain_map_data.call("get_tiles"):
		if tile_data == null:
			continue
		var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
		var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
		if type_id.is_empty() or not object_type_id.is_empty():
			continue
		if bool(_tile_catalog.call("is_object_layer_type", type_id)):
			tile_data.object_type_id = type_id
			tile_data.type_id = "ground_flat"


func _save_current_map() -> void:
	if _terrain_map_data == null or _current_map_path.is_empty():
		return

	_commit_map_name_editor_text(false)
	if _get_current_map_name().is_empty() and _terrain_map_data.has_method("set_map_name"):
		_terrain_map_data.call("set_map_name", _current_map_path.get_file().get_basename())

	var save_error: Error = _terrain_map_data.call("save_to_file", _current_map_path)
	if save_error != OK:
		push_warning("MapEditor could not save map to %s" % _current_map_path)
		return

	_mark_dirty(false)
	_refresh_map_settings_panel()
	_refresh_top_bar()


func _rebuild_registry_from_map_data() -> void:
	_terrain_registry.clear_tiles()
	if _terrain_map_data == null:
		return

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	_terrain_registry.configure_iso_grid(
		_terrain_map_data.call("get_grid_origin"),
		float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH)),
		float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))
	)
	for tile_data in _terrain_map_data.call("get_tiles"):
		_terrain_registry.register_tile(tile_data)


func _rebuild_tile_sprites() -> void:
	if _terrain_renderer == null:
		return
	if _get_primary_3d_view() != null:
		_tile_sprites_by_grid.clear()
		_cliff_sprites_by_grid.clear()
		_wall_sprites_by_grid.clear()
		_object_sprites_by_grid.clear()
		_clear_legacy_2d_map_children()
		_rebuild_tile_property_overlay()
		_refresh_adjacency_debug_overlay_from_snapshot()
		_refresh_3d_map_view()
		_set_legacy_2d_map_visible(false)
		return
	_terrain_renderer.set_tile_catalog(_tile_catalog)
	var render_state: Dictionary = _terrain_renderer.render_map(_terrain_map_data, self)
	_tile_sprites_by_grid = render_state.get("tiles", {})
	_cliff_sprites_by_grid = render_state.get("cliffs", {})
	_wall_sprites_by_grid = render_state.get("walls", {})
	_object_sprites_by_grid = render_state.get("objects", {})
	_rebuild_grid_overlay()
	_rebuild_tile_property_overlay()
	_refresh_adjacency_debug_overlay_from_snapshot()
	_refresh_3d_map_view()
	_set_legacy_2d_map_visible(false)


func _refresh_tile_visual(tile_data, refresh_dirty_neighborhood: bool = true) -> void:
	if tile_data == null or not _tile_sprites_by_grid.has(tile_data.grid_position):
		if tile_data != null:
			_refresh_tile_property_overlay_for_grids([tile_data.grid_position])
		_queue_3d_map_refresh()
		return

	var tile_sprite := _tile_sprites_by_grid[tile_data.grid_position] as Sprite2D
	if tile_sprite == null:
		_refresh_tile_property_overlay_for_grids([tile_data.grid_position])
		_queue_3d_map_refresh()
		return

	var tile_texture: Texture2D = _resolve_tile_texture(tile_data)
	tile_sprite.texture = tile_texture
	tile_sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
	tile_sprite.modulate = _build_tile_modulate(tile_data)
	if refresh_dirty_neighborhood:
		_refresh_dirty_visual_neighborhoods([tile_data.grid_position])
	else:
		_refresh_tile_property_overlay_for_grids([tile_data.grid_position])
	_queue_3d_map_refresh()


func _queue_editor_ui_refresh(flags: int) -> void:
	if flags == 0:
		return
	_editor_ui_refresh_pending_flags = _editor_ui_refresh_pending_flags | flags
	_last_editor_ui_refresh_requested_flags = flags
	_editor_ui_refresh_request_count += 1
	for flag_name in _get_editor_ui_refresh_flag_names(flags):
		_editor_ui_refresh_flag_request_counts[flag_name] = int(_editor_ui_refresh_flag_request_counts.get(flag_name, 0)) + 1
	if _editor_ui_refresh_queued:
		return
	_editor_ui_refresh_queued = true
	call_deferred("_flush_editor_ui_refresh")


func _queue_hover_preview_update(world_position: Vector2) -> void:
	_queued_hover_world_position = world_position
	_queued_hover_has_world_position = true
	_queued_hover_hide = false
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_HOVER)


func _queue_hover_preview_hide() -> void:
	_queued_hover_has_world_position = false
	_queued_hover_hide = true
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_HOVER)


func _queue_patrol_route_preview_update(world_position: Vector2) -> void:
	_queued_patrol_preview_world_position = world_position
	_queued_patrol_preview_has_world_position = true
	_queued_patrol_preview_hide = false
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_PATROL_PREVIEW)


func _queue_patrol_route_preview_hide() -> void:
	_queued_patrol_preview_has_world_position = false
	_queued_patrol_preview_hide = true
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_PATROL_PREVIEW)


func _flush_editor_ui_refresh() -> void:
	var flags: int = _editor_ui_refresh_pending_flags
	_editor_ui_refresh_pending_flags = 0
	_editor_ui_refresh_queued = false
	if flags == 0:
		return
	_last_editor_ui_refresh_flushed_flags = flags
	_editor_ui_refresh_flush_count += 1

	if (flags & EDITOR_UI_REFRESH_HOVER) != 0:
		if _queued_hover_hide or not _queued_hover_has_world_position:
			_hide_hover_preview()
		else:
			_update_hover_preview(_queued_hover_world_position)
		_queued_hover_hide = false
		_queued_hover_has_world_position = false
	if (flags & EDITOR_UI_REFRESH_PATROL_PREVIEW) != 0:
		if _queued_patrol_preview_hide or not _queued_patrol_preview_has_world_position:
			_restore_selected_patrol_route_preview()
		else:
			_update_patrol_route_preview_at_world_position(_queued_patrol_preview_world_position)
		_queued_patrol_preview_hide = false
		_queued_patrol_preview_has_world_position = false
	if (flags & EDITOR_UI_REFRESH_SELECTION) != 0:
		_refresh_selection_visual()
	if (flags & EDITOR_UI_REFRESH_PROPERTIES) != 0:
		_refresh_property_panel()
	if (flags & EDITOR_UI_REFRESH_SCENARIO) != 0:
		_refresh_mission_authoring_controls()
	if (flags & EDITOR_UI_REFRESH_TOOL_STATE) != 0:
		_refresh_top_bar()


func _get_editor_ui_refresh_flag_names(flags: int) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	if (flags & EDITOR_UI_REFRESH_SELECTION) != 0:
		names.append("selection")
	if (flags & EDITOR_UI_REFRESH_PROPERTIES) != 0:
		names.append("properties")
	if (flags & EDITOR_UI_REFRESH_TOOL_STATE) != 0:
		names.append("tool_state")
	if (flags & EDITOR_UI_REFRESH_HOVER) != 0:
		names.append("hover")
	if (flags & EDITOR_UI_REFRESH_SCENARIO) != 0:
		names.append("scenario")
	if (flags & EDITOR_UI_REFRESH_PATROL_PREVIEW) != 0:
		names.append("patrol_preview")
	return names


func get_editor_ui_refresh_debug_snapshot() -> Dictionary:
	return {
		"batched": true,
		"queued": _editor_ui_refresh_queued,
		"pending_flags": _editor_ui_refresh_pending_flags,
		"pending_flag_names": _get_editor_ui_refresh_flag_names(_editor_ui_refresh_pending_flags),
		"last_requested_flags": _last_editor_ui_refresh_requested_flags,
		"last_requested_flag_names": _get_editor_ui_refresh_flag_names(_last_editor_ui_refresh_requested_flags),
		"last_flushed_flags": _last_editor_ui_refresh_flushed_flags,
		"last_flushed_flag_names": _get_editor_ui_refresh_flag_names(_last_editor_ui_refresh_flushed_flags),
		"request_count": _editor_ui_refresh_request_count,
		"flush_count": _editor_ui_refresh_flush_count,
		"flag_request_counts": _editor_ui_refresh_flag_request_counts.duplicate(true),
		"queued_hover_update": _queued_hover_has_world_position,
		"queued_hover_hide": _queued_hover_hide,
		"queued_patrol_preview_update": _queued_patrol_preview_has_world_position,
		"queued_patrol_preview_hide": _queued_patrol_preview_hide,
		"patrol_route_preview": get_patrol_route_preview_snapshot(),
	}


func _build_tile_modulate(tile_data) -> Color:
	if _terrain_renderer == null:
		return Color(1.0, 1.0, 1.0, 1.0)
	_terrain_renderer.set_tile_catalog(_tile_catalog)
	return _terrain_renderer.build_tile_modulate(tile_data)


func _select_tile_at_world_position(world_position: Vector2) -> void:
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return

	_set_selected_grid_position(tile_data.grid_position)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)


func _set_selected_grid_position(grid_position: Vector2i) -> void:
	_selected_grid_position = grid_position
	_selected_grids.clear()
	if grid_position != Vector2i(-1, -1):
		_selected_grids.append(grid_position)


func _select_grid_with_selection_tool(grid_position: Vector2i, additive: bool = false) -> bool:
	if _terrain_map_data == null:
		return false
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return false
	if additive:
		if _selected_grids.has(grid_position):
			_selected_grids.erase(grid_position)
		else:
			_selected_grids.append(grid_position)
	else:
		_selected_grids = [grid_position]
	if _selected_grids.is_empty():
		_selected_grid_position = Vector2i(-1, -1)
	else:
		_selected_grid_position = Vector2i(_selected_grids[_selected_grids.size() - 1])
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE)
	return true


func _select_grid_area_from_world(start_world_position: Vector2, end_world_position: Vector2, additive: bool = false) -> bool:
	if _terrain_registry == null:
		return false
	return _select_grid_area(
		_terrain_registry.world_to_grid(start_world_position),
		_terrain_registry.world_to_grid(end_world_position),
		additive
	)


func _select_grid_area(start_grid_position: Vector2i, end_grid_position: Vector2i, additive: bool = false) -> bool:
	if _terrain_map_data == null:
		return false
	var min_x: int = mini(start_grid_position.x, end_grid_position.x)
	var max_x: int = maxi(start_grid_position.x, end_grid_position.x)
	var min_y: int = mini(start_grid_position.y, end_grid_position.y)
	var max_y: int = maxi(start_grid_position.y, end_grid_position.y)
	var next_selected_grids: Array = _selected_grids.duplicate() if additive else []
	var found_any_tile: bool = false
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var grid_position := Vector2i(x, y)
			if _terrain_map_data.call("get_tile_at_grid", grid_position) == null:
				continue
			found_any_tile = true
			if not next_selected_grids.has(grid_position):
				next_selected_grids.append(grid_position)
	if not found_any_tile:
		return false
	_selected_grids = next_selected_grids
	_selected_grid_position = Vector2i(_selected_grids[_selected_grids.size() - 1]) if not _selected_grids.is_empty() else Vector2i(-1, -1)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE)
	return true


func _apply_brush_at_world_position(world_position: Vector2) -> void:
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return

	if tile_data.grid_position == _last_painted_grid:
		return
	_last_painted_grid = tile_data.grid_position

	var center_grid: Vector2i = tile_data.grid_position
	var radius: int = _get_brush_radius()
	var any_changed: bool = false
	var changed_grids: Array[Vector2i] = []
	var owns_undo_transaction: bool = _ensure_undo_transaction("brush_stroke")

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var target_grid: Vector2i = center_grid + Vector2i(dx, dy)
			var target_tile = _terrain_map_data.call("get_tile_at_grid", target_grid) if _terrain_map_data != null else null
			if target_tile == null:
				continue

			if not _selected_type_id.is_empty() and _tile_catalog != null and _tile_catalog.has_type(_selected_type_id):
				_store_undo_state(target_tile)
				if _tile_catalog.apply_type_to_tile(target_tile, _selected_type_id):
					if _palette_type_uses_object_scale(_selected_type_id):
						target_tile.object_scale = _placement_object_scale
					any_changed = true
					changed_grids.append(target_grid)
					_refresh_tile_visual(target_tile, false)
			else:
				var patch: Dictionary = {
					"walkable": _get_walkable_checkbox().button_pressed,
					"surface_type": _get_selected_surface_type(),
				}
				if _apply_tile_patch(target_tile, patch):
					any_changed = true
					changed_grids.append(target_grid)
					_refresh_tile_visual(target_tile, false)

	if any_changed:
		_refresh_dirty_visual_neighborhoods(changed_grids)
		if owns_undo_transaction:
			commit_undo_transaction()
		_mark_dirty(true)
	elif owns_undo_transaction:
		cancel_empty_undo_transaction()

	_set_selected_grid_position(center_grid)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
	_queue_hover_preview_hide()


func _apply_height_tool_at_world_position(world_position: Vector2) -> void:
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return

	if tile_data.grid_position == _last_painted_grid:
		return
	_last_painted_grid = tile_data.grid_position

	var center_grid: Vector2i = tile_data.grid_position
	var radius: int = _get_brush_radius()
	var any_changed: bool = false
	var changed_grids: Array[Vector2i] = []
	var owns_undo_transaction: bool = _ensure_undo_transaction("height_stroke")

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var target_grid: Vector2i = center_grid + Vector2i(dx, dy)
			var target_tile = _terrain_map_data.call("get_tile_at_grid", target_grid) if _terrain_map_data != null else null
			if target_tile == null:
				continue

			var patch: Dictionary = Dictionary(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("build_height_patch", int(target_tile.height_level), _height_tool_mode, _height_tool_edge_type, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE))
			if _apply_tile_patch(target_tile, patch):
				any_changed = true
				changed_grids.append(target_grid)

	if any_changed:
		_refresh_reconciled_height_edges(changed_grids, _height_tool_edge_type)
		if owns_undo_transaction:
			commit_undo_transaction()
		_mark_dirty(true)
	elif owns_undo_transaction:
		cancel_empty_undo_transaction()

	_set_selected_grid_position(center_grid)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
	_queue_hover_preview_hide()


func _apply_eraser_at_world_position(world_position: Vector2) -> void:
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return

	if tile_data.grid_position == _last_painted_grid:
		return
	_last_painted_grid = tile_data.grid_position

	var owns_undo_transaction: bool = _ensure_undo_transaction("eraser_stroke")
	if not _erase_object_layer_from_tile(tile_data):
		if owns_undo_transaction:
			cancel_empty_undo_transaction()
		_set_selected_grid_position(tile_data.grid_position)
		_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
		_queue_hover_preview_hide()
		return

	_set_selected_grid_position(tile_data.grid_position)
	_refresh_tile_visual(tile_data)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
	if owns_undo_transaction:
		commit_undo_transaction()
	_mark_dirty(true)
	_queue_hover_preview_hide()


func _erase_object_layer_from_tile(tile_data) -> bool:
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower() if tile_data.object_type_id is String else ""
	var has_object_layer: bool = not object_type_id.is_empty()
	if not has_object_layer and _tile_catalog != null and _tile_catalog.has_method("is_object_layer_type"):
		has_object_layer = bool(_tile_catalog.call("is_object_layer_type", type_id))
	var has_structure_layer: bool = _tile_catalog != null and _tile_catalog.has_method("is_structure_layer_type") and bool(_tile_catalog.call("is_structure_layer_type", type_id))
	if not has_object_layer:
		for prefix in ["wall_", "rock_", "cliff_", "slope_"]:
			if type_id.begins_with(prefix):
				has_structure_layer = true
				break
	if not has_object_layer and not has_structure_layer:
		return false

	_store_undo_state(tile_data)
	if has_object_layer and not object_type_id.is_empty():
		tile_data.object_type_id = ""
		tile_data.object_rotation_degrees = 0.0
		tile_data.object_scale = OBJECT_SCALE_DEFAULT
		_restore_tile_base_gameplay_fields(tile_data)
		return true

	tile_data.object_type_id = ""
	tile_data.object_rotation_degrees = 0.0
	tile_data.object_scale = OBJECT_SCALE_DEFAULT
	if (
		(_tile_catalog != null and _tile_catalog.has_method("is_object_layer_type") and bool(_tile_catalog.call("is_object_layer_type", type_id)))
		or has_structure_layer
		or type_id.begins_with("wall_")
		or type_id.begins_with("rock_")
		or type_id.begins_with("cliff_")
		or type_id.begins_with("slope_")
	):
		tile_data.type_id = "ground_flat"
	_restore_tile_base_gameplay_fields(tile_data)
	return true


func _restore_tile_base_gameplay_fields(tile_data) -> void:
	if tile_data == null:
		return
	if _tile_catalog != null and _tile_catalog.has_method("apply_base_gameplay_fields_to_tile"):
		_tile_catalog.call("apply_base_gameplay_fields_to_tile", tile_data)
		return
	tile_data.walkable = true
	tile_data.blocks_los = false
	tile_data.cover_value = 0
	tile_data.object_height = 0


func _get_next_height_tool_level(current_height: int) -> int:
	return int(MAP_EDITOR_HEIGHT_TOOL_SCRIPT.call("get_next_height_level", current_height, _height_tool_mode))


func _resolve_tile_at_world_position(world_position: Vector2):
	if _terrain_map_data == null:
		return null

	var grid_position: Vector2i = _terrain_registry.world_to_grid(world_position)
	return _terrain_map_data.call("get_tile_at_grid", grid_position)


func _refresh_selection_visual() -> void:
	var outline_root := get_node_or_null("SelectionOutline") as Node2D
	if outline_root == null or _terrain_map_data == null:
		_update_3d_selection_visual()
		return

	for child in outline_root.get_children():
		child.queue_free()

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_width: float = float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH))
	var half_height: float = float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))

	var grids = _selected_grids.duplicate()
	if grids.is_empty() and _selected_grid_position != Vector2i(-1, -1):
		grids = [_selected_grid_position]

	for grid in grids:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid)
		if tile_data == null:
			continue

		var center: Vector2 = tile_data.world_position
		var outline := Line2D.new()
		outline.default_color = Color(1, 1, 1, 0.95)
		outline.width = 3.0
		outline.closed = true
		outline.add_point(center + Vector2(0.0, -half_height))
		outline.add_point(center + Vector2(half_width, 0.0))
		outline.add_point(center + Vector2(0.0, half_height))
		outline.add_point(center + Vector2(-half_width, 0.0))
		outline_root.add_child(outline)
	_update_3d_selection_visual()


func _add_height_tool_controls() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return

	var insert_index: int = button_row.get_child_count()
	var brush_size_button := _get_brush_size_option_button()
	if brush_size_button != null:
		insert_index = brush_size_button.get_index() + 1

	var height_button := button_row.get_node_or_null("HeightButton") as Button
	if height_button == null:
		height_button = Button.new()
		height_button.name = "HeightButton"
		height_button.toggle_mode = true
		height_button.toggled.connect(_on_height_tool_toggled)
		button_row.add_child(height_button)
		button_row.move_child(height_button, insert_index)
		insert_index += 1
	_configure_tool_button(height_button, "H", "Height: raises, lowers or sets tile height. Use Hang for walkable slopes and Cliff for hard height edges.")

	var mode_option := button_row.get_node_or_null("HeightModeOption") as OptionButton
	if mode_option == null:
		mode_option = OptionButton.new()
		mode_option.name = "HeightModeOption"
		mode_option.custom_minimum_size = Vector2(96.0, 0.0)
		mode_option.tooltip_text = "Height mode: Anheben/Absenken changes one step; H=0/H=1/H=2 writes an exact level."
		button_row.add_child(mode_option)
		button_row.move_child(mode_option, insert_index)
		insert_index += 1
	_populate_height_mode_options(mode_option)
	if not mode_option.item_selected.is_connected(_on_height_mode_selected):
		mode_option.item_selected.connect(_on_height_mode_selected)

	var edge_option := button_row.get_node_or_null("HeightEdgeOption") as OptionButton
	if edge_option == null:
		edge_option = OptionButton.new()
		edge_option.name = "HeightEdgeOption"
		edge_option.custom_minimum_size = Vector2(92.0, 0.0)
		edge_option.tooltip_text = "Height edge: Hang creates a walkable slope; Cliff creates a blocking vertical side; Keine suppresses visible side pieces."
		button_row.add_child(edge_option)
		button_row.move_child(edge_option, insert_index)
	_populate_height_edge_options(edge_option)
	if not edge_option.item_selected.is_connected(_on_height_edge_selected):
		edge_option.item_selected.connect(_on_height_edge_selected)

	_update_height_topbar_state()


func _populate_height_mode_options(option_button: OptionButton) -> void:
	if option_button == null:
		return
	option_button.clear()
	option_button.add_item("Anheben")
	option_button.set_item_metadata(0, HEIGHT_TOOL_MODE_RAISE)
	option_button.add_item("Absenken")
	option_button.set_item_metadata(1, HEIGHT_TOOL_MODE_LOWER)
	option_button.add_item("H=0")
	option_button.set_item_metadata(2, HEIGHT_TOOL_MODE_SET_0)
	option_button.add_item("H=1")
	option_button.set_item_metadata(3, HEIGHT_TOOL_MODE_SET_1)
	option_button.add_item("H=2")
	option_button.set_item_metadata(4, HEIGHT_TOOL_MODE_SET_2)
	for index in range(option_button.item_count):
		if String(option_button.get_item_metadata(index)) == _height_tool_mode:
			option_button.select(index)
			return
	option_button.select(0)


func _populate_height_edge_options(option_button: OptionButton) -> void:
	if option_button == null:
		return
	option_button.clear()
	option_button.add_item("Hang")
	option_button.set_item_metadata(0, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE)
	option_button.add_item("Cliff")
	option_button.set_item_metadata(1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF)
	option_button.add_item("Keine")
	option_button.set_item_metadata(2, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE)
	for index in range(option_button.item_count):
		if String(option_button.get_item_metadata(index)) == _height_tool_edge_type:
			option_button.select(index)
			return
	option_button.select(0)


func _update_height_topbar_state() -> void:
	var height_button := _get_height_tool_button()
	if height_button != null:
		height_button.disabled = _terrain_map_data == null
		if height_button.disabled and height_button.button_pressed:
			height_button.button_pressed = false
		elif height_button.button_pressed != _height_tool_enabled:
			height_button.button_pressed = _height_tool_enabled
	var mode_option := _get_height_mode_option_button()
	if mode_option != null:
		mode_option.disabled = not _height_tool_enabled
	var edge_option := _get_height_edge_option_button()
	if edge_option != null:
		edge_option.disabled = not _height_tool_enabled


func _clear_height_tool() -> void:
	_height_tool_enabled = false
	var height_button := _get_height_tool_button()
	if height_button != null and height_button.button_pressed:
		height_button.button_pressed = false
	_update_height_topbar_state()


func _add_selection_tool_button() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return

	var existing_button := button_row.get_node_or_null("SelectButton") as Button
	if existing_button != null:
		_configure_tool_button(existing_button, "S", "Select: inspect or edit tiles and objects. Ctrl-click toggles multiple tiles without painting.")
		existing_button.button_pressed = _selection_tool_enabled
		return

	var select_btn := Button.new()
	select_btn.name = "SelectButton"
	select_btn.toggle_mode = true
	select_btn.button_pressed = _selection_tool_enabled
	_configure_tool_button(select_btn, "S", "Select: inspect or edit tiles and objects. Ctrl-click toggles multiple tiles without painting.")
	select_btn.toggled.connect(_on_selection_tool_toggled)
	button_row.add_child(select_btn)


func _add_eraser_tool_button() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return

	var eraser_button := button_row.get_node_or_null("EraserButton") as Button
	if eraser_button == null:
		eraser_button = Button.new()
		eraser_button.name = "EraserButton"
		eraser_button.toggle_mode = true
		eraser_button.toggled.connect(_on_eraser_tool_toggled)
		button_row.add_child(eraser_button)
		var select_button := button_row.get_node_or_null("SelectButton") as Button
		if select_button != null:
			button_row.move_child(eraser_button, select_button.get_index() + 1)
	_configure_tool_button(eraser_button, "E", "Eraser: removes the object/structure layer on clicked tiles. Terrain, height and markers stay intact.")
	eraser_button.button_pressed = _eraser_tool_enabled


func _configure_tool_button(button: Button, label_text: String, tooltip: String) -> void:
	if button == null:
		return
	button.text = label_text
	button.custom_minimum_size = TOOL_BUTTON_SIZE
	button.tooltip_text = tooltip


func _arrange_topbar_authoring_tools() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return
	var insert_index: int = 0
	var brush_size_option := button_row.get_node_or_null("BrushSizeOptionButton") as Control
	if brush_size_option != null:
		insert_index = brush_size_option.get_index() + 1
	for node_name in [
		"SelectButton",
		"EraserButton",
		"HeightButton",
		"HeightModeOption",
		"HeightEdgeOption",
		"PatrolButton",
		"PatrolSpawnOption",
		"ClearPatrolButton",
		"TilePropertyOverlayButton",
		"AdjacencyDebugOverlayButton",
	]:
		var node := button_row.get_node_or_null(node_name) as Control
		if node == null:
			continue
		button_row.move_child(node, insert_index)
		insert_index += 1


func _ensure_runtime_builder_workbench_controls() -> void:
	var ui := get_node_or_null("UI") as CanvasLayer
	if ui == null:
		return
	var rail := ui.get_node_or_null(RUNTIME_BUILDER_RAIL_NAME) as PanelContainer
	if rail == null:
		rail = PanelContainer.new()
		rail.name = RUNTIME_BUILDER_RAIL_NAME
		ui.add_child(rail)
	_apply_runtime_builder_layout_offsets()
	_apply_panel_style(rail, Color(0.045, 0.065, 0.075, 0.97), Color(0.35, 0.64, 0.70, 0.72))

	var margin := rail.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "Margin"
		margin.add_theme_constant_override("margin_left", 5)
		margin.add_theme_constant_override("margin_top", 7)
		margin.add_theme_constant_override("margin_right", 5)
		margin.add_theme_constant_override("margin_bottom", 7)
		rail.add_child(margin)
	var tools := margin.get_node_or_null("Tools") as VBoxContainer
	if tools == null:
		tools = VBoxContainer.new()
		tools.name = "Tools"
		tools.add_theme_constant_override("separation", 5)
		margin.add_child(tools)
	_remove_runtime_builder_tool_button(tools, "road_line")
	_remove_runtime_builder_tool_button(tools, "rail_line")
	_ensure_runtime_builder_tool_button(tools, "select", "S", "Select: Kachel, Objekt oder Marker inspizieren und bearbeiten.", true)
	_ensure_runtime_builder_tool_button(tools, "terrain", "T", "Terrain: normales Bodentile als Brush waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "road", "R", "Road: Strassenplatte als Brush waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "pipe_line", "PI", "Pipe-Line: Ziehen setzt Pipelines fuer Energie, Oel, Rohstoffe oder Abwasser.", true)
	_ensure_runtime_builder_tool_button(tools, "wall_line", "WL", "Wall-Line: Ziehen setzt modulare Waende als vorbereitete Segmentkette.", true)
	_ensure_runtime_builder_tool_button(tools, "cliff_line", "CL", "Cliff-Line: Ziehen setzt vorbereitete Cliff-Segmente.", true)
	_ensure_runtime_builder_tool_button(tools, "asset", "A", "Asset: Gebaeude-Asset als Brush waehlen; danach Palette fuer Varianten nutzen.", true)
	_ensure_runtime_builder_tool_button(tools, "factory", "F", "Factory: Factory-Kit-Gebaeude als Brush waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "space_floor", "SF", "Space Floor: Modular-/Station-Boden als Brush waehlen; Scale kann im Preview-Block korrigiert werden.", true)
	_ensure_runtime_builder_tool_button(tools, "door_wall", "DW", "Door Wall: Space-Station-Wand mit Tuer-Oeffnung als Brush waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "door_closed", "DC", "Door Closed: Space-Station-Tuer im geschlossenen Authoring-Zustand waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "door_half", "DH", "Door Half: Space-Station-Tuer im halb offenen Authoring-Zustand waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "door_open", "DO", "Door Open: Space-Station-Tuer im offenen Authoring-Zustand waehlen.", true)
	_ensure_runtime_builder_tool_button(tools, "erase", "X", "Erase: Objekt-/Struktur-Layer entfernen, Boden und Marker bleiben erhalten.", true)
	_ensure_runtime_builder_tool_button(tools, "height", "H", "Hoehe/Cliff: vorhandenes Hoehenwerkzeug aktivieren.", true)
	_ensure_runtime_builder_tool_button(tools, "marker", "M", "Marker: Spawn- und Objective-Punkte platzieren.", true)
	_ensure_runtime_builder_tool_button(tools, "patrol", "P", "Patrol: NPC-Patrolpunkte fuer den gewaehlten Spawn setzen.", true)
	_ensure_runtime_builder_separator(tools, "RuntimeBuilderRotateSeparator")
	_ensure_runtime_builder_tool_button(tools, "rotate_left", "-90", "Ausgewaehltes rotierbares Objekt links drehen.", false)
	_ensure_runtime_builder_tool_button(tools, "rotate_right", "+90", "Ausgewaehltes rotierbares Objekt rechts drehen.", false)
	_refresh_runtime_builder_workbench_controls()


func _ensure_runtime_builder_tool_button(parent: VBoxContainer, tool_id: String, label_text: String, tooltip: String, is_toggle: bool) -> Button:
	var button_name: String = _build_runtime_builder_button_name(tool_id)
	var button := parent.get_node_or_null(button_name) as Button
	if button == null:
		button = Button.new()
		button.name = button_name
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(activate_runtime_builder_tool.bind(tool_id))
		parent.add_child(button)
	button.text = label_text
	button.toggle_mode = is_toggle
	button.custom_minimum_size = RUNTIME_BUILDER_BUTTON_SIZE
	button.tooltip_text = tooltip
	button.set_meta("builder_tool_id", tool_id)
	button.add_theme_font_size_override("font_size", 11)
	return button


func _remove_runtime_builder_tool_button(parent: VBoxContainer, tool_id: String) -> void:
	var button_name: String = _build_runtime_builder_button_name(tool_id)
	var button := parent.get_node_or_null(button_name) as Button
	if button == null:
		return
	parent.remove_child(button)
	button.queue_free()


func _ensure_runtime_builder_separator(parent: VBoxContainer, separator_name: String) -> void:
	if parent.get_node_or_null(separator_name) != null:
		return
	var separator := HSeparator.new()
	separator.name = separator_name
	separator.custom_minimum_size = Vector2(0.0, 4.0)
	parent.add_child(separator)


func _build_runtime_builder_button_name(tool_id: String) -> String:
	var normalized: String = tool_id.strip_edges().to_lower().replace("_", "")
	return "BuilderTool_%s" % normalized


func _apply_runtime_builder_layout_offsets() -> void:
	var rail := get_node_or_null("UI/%s" % RUNTIME_BUILDER_RAIL_NAME) as PanelContainer
	if rail != null:
		rail.anchor_left = 0.0
		rail.anchor_top = 0.0
		rail.anchor_right = 0.0
		rail.anchor_bottom = 1.0
		rail.offset_left = 0.0
		rail.offset_top = 44.0
		rail.offset_right = RUNTIME_BUILDER_RAIL_WIDTH
		rail.offset_bottom = 0.0
		rail.grow_vertical = Control.GROW_DIRECTION_BOTH
		rail.custom_minimum_size = Vector2(RUNTIME_BUILDER_RAIL_WIDTH, 0.0)
	var palette_panel := get_node_or_null("UI/PalettePanel") as PanelContainer
	if palette_panel != null:
		var left_edge: float = RUNTIME_BUILDER_RAIL_WIDTH + RUNTIME_BUILDER_RAIL_GAP
		palette_panel.offset_left = left_edge
		palette_panel.offset_right = left_edge + PALETTE_PANEL_MIN_WIDTH
		palette_panel.custom_minimum_size = Vector2(PALETTE_PANEL_MIN_WIDTH, palette_panel.custom_minimum_size.y)


func activate_runtime_builder_tool(tool_id: String) -> bool:
	var normalized_tool_id: String = tool_id.strip_edges().to_lower()
	var handled: bool = false
	match normalized_tool_id:
		"select":
			handled = set_authoring_tool(AUTHORING_TOOL_SELECT)
		"terrain":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_TERRAIN_TYPE_ID)
		"road":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_ROAD_TYPE_ID)
		"road_line":
			handled = _activate_runtime_builder_network_tool(NETWORK_KIND_ROAD)
		"rail_line":
			handled = _activate_runtime_builder_network_tool(NETWORK_KIND_RAIL)
		"pipe_line":
			handled = _activate_runtime_builder_network_tool(NETWORK_KIND_PIPE)
		"wall_line":
			handled = _activate_runtime_builder_network_tool(NETWORK_KIND_WALL)
		"cliff_line":
			handled = _activate_runtime_builder_network_tool(NETWORK_KIND_CLIFF)
		"asset":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_ASSET_TYPE_ID)
		"factory":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_FACTORY_TYPE_ID)
		"space_floor":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_SPACE_FLOOR_TYPE_ID)
		"door_wall":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_STATION_DOOR_WALL_TYPE_ID)
		"door_closed":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_STATION_DOOR_CLOSED_TYPE_ID)
		"door_half":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_STATION_DOOR_HALF_TYPE_ID)
		"door_open":
			handled = _activate_runtime_builder_palette_brush(BUILDER_QUICK_STATION_DOOR_OPEN_TYPE_ID)
		"erase":
			handled = set_authoring_tool(AUTHORING_TOOL_ERASER)
		"height":
			handled = set_authoring_tool(AUTHORING_TOOL_HEIGHT)
		"marker":
			handled = set_authoring_tool(AUTHORING_TOOL_MARKER)
		"patrol":
			handled = set_authoring_tool(AUTHORING_TOOL_PATROL)
		"rotate_left":
			handled = _rotate_selected_object(-90.0)
		"rotate_right":
			handled = _rotate_selected_object(90.0)
		_:
			handled = false
	if handled:
		_runtime_builder_status_text = _build_runtime_builder_status_text()
	else:
		_runtime_builder_status_text = "Builder-Tool nicht verfuegbar: %s" % normalized_tool_id
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()
	return handled


func _activate_runtime_builder_palette_brush(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_type(normalized_type_id):
		return false
	if not set_palette_type_for_authoring(normalized_type_id):
		return false
	return set_authoring_tool(AUTHORING_TOOL_BRUSH)


func _activate_runtime_builder_network_tool(kind: String) -> bool:
	var normalized_kind: String = kind.strip_edges().to_lower()
	if not _network_tool_kind_is_valid(normalized_kind):
		return false
	var default_type_id: String = String(_get_network_tool_definition(normalized_kind).get("default_type_id", "")).strip_edges().to_lower()
	if default_type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_type(default_type_id):
		return false
	_network_tool_kind = normalized_kind
	_selected_type_id = default_type_id
	_remember_palette_recent_type_id(default_type_id)
	_refresh_palette_selection_visual()
	_refresh_palette_workflow_controls()
	_refresh_palette_filter_controls()
	return set_authoring_tool(AUTHORING_TOOL_NETWORK_DRAG)


func _refresh_runtime_builder_workbench_controls() -> void:
	var rail := get_node_or_null("UI/%s" % RUNTIME_BUILDER_RAIL_NAME) as PanelContainer
	if rail == null:
		return
	var active_tool: String = _get_active_authoring_tool()
	for button in _get_runtime_builder_tool_buttons():
		if button == null or not button.toggle_mode:
			continue
		var tool_id: String = String(button.get_meta("builder_tool_id", "")).strip_edges().to_lower()
		button.button_pressed = _runtime_builder_button_is_active(tool_id, active_tool)


func _runtime_builder_button_is_active(tool_id: String, active_tool: String) -> bool:
	match tool_id:
		"select":
			return active_tool == AUTHORING_TOOL_SELECT
		"terrain":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_TERRAIN_TYPE_ID
		"road":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_ROAD_TYPE_ID
		"road_line":
			return active_tool == AUTHORING_TOOL_NETWORK_DRAG and _network_tool_kind == NETWORK_KIND_ROAD
		"rail_line":
			return active_tool == AUTHORING_TOOL_NETWORK_DRAG and _network_tool_kind == NETWORK_KIND_RAIL
		"pipe_line":
			return active_tool == AUTHORING_TOOL_NETWORK_DRAG and _network_tool_kind == NETWORK_KIND_PIPE
		"wall_line":
			return active_tool == AUTHORING_TOOL_NETWORK_DRAG and _network_tool_kind == NETWORK_KIND_WALL
		"cliff_line":
			return active_tool == AUTHORING_TOOL_NETWORK_DRAG and _network_tool_kind == NETWORK_KIND_CLIFF
		"asset":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_ASSET_TYPE_ID
		"factory":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_FACTORY_TYPE_ID
		"space_floor":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_SPACE_FLOOR_TYPE_ID
		"door_wall":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_STATION_DOOR_WALL_TYPE_ID
		"door_closed":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_STATION_DOOR_CLOSED_TYPE_ID
		"door_half":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_STATION_DOOR_HALF_TYPE_ID
		"door_open":
			return active_tool == AUTHORING_TOOL_BRUSH and _selected_type_id == BUILDER_QUICK_STATION_DOOR_OPEN_TYPE_ID
		"erase":
			return active_tool == AUTHORING_TOOL_ERASER
		"height":
			return active_tool == AUTHORING_TOOL_HEIGHT
		"marker":
			return active_tool == AUTHORING_TOOL_MARKER
		"patrol":
			return active_tool == AUTHORING_TOOL_PATROL
	return false


func _get_runtime_builder_tool_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	var tools := get_node_or_null("UI/%s/Margin/Tools" % RUNTIME_BUILDER_RAIL_NAME) as VBoxContainer
	if tools == null:
		return buttons
	for child in tools.get_children():
		var button := child as Button
		if button != null and button.has_meta("builder_tool_id"):
			buttons.append(button)
	return buttons


func _build_runtime_builder_status_text() -> String:
	var selected_label: String = _get_palette_type_display_name(_selected_type_id)
	if selected_label.is_empty():
		selected_label = "-"
	return "Tool %s | Asset %s" % [_format_option_label(_get_active_authoring_tool()), selected_label]


func _build_runtime_builder_workbench_snapshot() -> Dictionary:
	var rail := get_node_or_null("UI/%s" % RUNTIME_BUILDER_RAIL_NAME) as PanelContainer
	var palette_panel := get_node_or_null("UI/PalettePanel") as Control
	var tool_ids: PackedStringArray = PackedStringArray()
	for button in _get_runtime_builder_tool_buttons():
		tool_ids.append(String(button.get_meta("builder_tool_id", "")))
	return {
		"enabled": rail != null,
		"entry_scene_path": RUNTIME_BUILDER_ENTRY_SCENE_PATH,
		"runtime_editor_scene_path": RUNTIME_MAP_EDITOR_SCENE_PATH,
		"runs_from_f6_workbench": true,
		"ui_sets_gameplay_truth": false,
		"tool_ids": tool_ids,
		"tool_count": tool_ids.size(),
		"rail_width": RUNTIME_BUILDER_RAIL_WIDTH,
		"palette_panel_offset_left": palette_panel.offset_left if palette_panel != null else 0.0,
		"palette_panel_offset_right": palette_panel.offset_right if palette_panel != null else 0.0,
		"active_tool": _get_active_authoring_tool(),
		"selected_type_id": _selected_type_id,
		"quick_terrain_type_id": BUILDER_QUICK_TERRAIN_TYPE_ID,
		"quick_road_type_id": BUILDER_QUICK_ROAD_TYPE_ID,
		"quick_asset_type_id": BUILDER_QUICK_ASSET_TYPE_ID,
		"quick_factory_type_id": BUILDER_QUICK_FACTORY_TYPE_ID,
		"quick_space_floor_type_id": BUILDER_QUICK_SPACE_FLOOR_TYPE_ID,
		"quick_station_door_wall_type_id": BUILDER_QUICK_STATION_DOOR_WALL_TYPE_ID,
		"quick_station_door_closed_type_id": BUILDER_QUICK_STATION_DOOR_CLOSED_TYPE_ID,
		"quick_station_door_half_type_id": BUILDER_QUICK_STATION_DOOR_HALF_TYPE_ID,
		"quick_station_door_open_type_id": BUILDER_QUICK_STATION_DOOR_OPEN_TYPE_ID,
		"network": _build_network_drag_tool_snapshot(),
		"network_drag_preview": _build_network_drag_preview_summary(),
		"station_doors": _build_station_door_authoring_snapshot(),
		"status": _runtime_builder_status_text,
	}


func apply_runtime_network_path_for_authoring(kind: String, start_grid: Vector2i, end_grid: Vector2i) -> bool:
	var normalized_kind: String = kind.strip_edges().to_lower()
	if not _network_tool_kind_is_valid(normalized_kind):
		return false
	_network_tool_kind = normalized_kind
	var path: Array[Vector2i] = _build_network_drag_path(start_grid, end_grid)
	var applied: bool = _apply_network_path(normalized_kind, path)
	if applied:
		_clear_network_drag_preview()
	return applied


func preview_runtime_network_path_for_authoring(kind: String, start_grid: Vector2i, end_grid: Vector2i) -> bool:
	var normalized_kind: String = kind.strip_edges().to_lower()
	if not _network_tool_kind_is_valid(normalized_kind) or _terrain_map_data == null:
		return false
	if _terrain_map_data.call("get_tile_at_grid", start_grid) == null or _terrain_map_data.call("get_tile_at_grid", end_grid) == null:
		return false
	_network_tool_kind = normalized_kind
	_network_drag_tool_enabled = true
	_is_network_dragging = true
	_network_drag_start_grid = start_grid
	_network_drag_current_grid = end_grid
	_network_drag_preview_path = _build_network_drag_path(start_grid, end_grid)
	_set_selected_grid_position(end_grid)
	_queue_hover_preview_hide()
	_sync_network_drag_preview_to_primary_view()
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE)
	_refresh_runtime_builder_workbench_controls()
	return true


func clear_runtime_network_preview_for_authoring() -> void:
	_clear_network_drag_preview()


func _begin_network_drag_at_world_position(world_position: Vector2) -> bool:
	if _terrain_registry == null or _terrain_map_data == null:
		return false
	var grid_position: Vector2i = _terrain_registry.world_to_grid(world_position)
	if _terrain_map_data.call("get_tile_at_grid", grid_position) == null:
		return false
	_is_network_dragging = true
	_network_drag_start_grid = grid_position
	_network_drag_current_grid = grid_position
	_network_drag_preview_path = _build_network_drag_path(grid_position, grid_position)
	_set_selected_grid_position(grid_position)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
	_queue_hover_preview_hide()
	_sync_network_drag_preview_to_primary_view()
	return true


func _update_network_drag_preview_at_world_position(world_position: Vector2) -> bool:
	if not _is_network_dragging or _terrain_registry == null:
		return false
	var grid_position: Vector2i = _terrain_registry.world_to_grid(world_position)
	if _terrain_map_data == null or _terrain_map_data.call("get_tile_at_grid", grid_position) == null:
		return false
	_network_drag_current_grid = grid_position
	_network_drag_preview_path = _build_network_drag_path(_network_drag_start_grid, grid_position)
	_set_selected_grid_position(grid_position)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES)
	_queue_hover_preview_hide()
	_sync_network_drag_preview_to_primary_view()
	return true


func _finish_network_drag_at_world_position(world_position: Vector2) -> bool:
	if not _is_network_dragging:
		return false
	_update_network_drag_preview_at_world_position(world_position)
	var path: Array[Vector2i] = []
	for grid_variant in _network_drag_preview_path:
		path.append(Vector2i(grid_variant))
	_clear_network_drag_preview()
	if path.is_empty():
		return false
	return _apply_network_path(_network_tool_kind, path)


func _clear_network_drag_preview() -> void:
	_is_network_dragging = false
	_network_drag_start_grid = Vector2i(-1, -1)
	_network_drag_current_grid = Vector2i(-1, -1)
	_network_drag_preview_path.clear()
	_sync_network_drag_preview_to_primary_view()


func _build_network_drag_path(start_grid: Vector2i, end_grid: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if start_grid == Vector2i(-1, -1) or end_grid == Vector2i(-1, -1):
		return path
	var current := Vector2i(start_grid)
	_append_network_path_grid(path, current)
	var delta: Vector2i = end_grid - start_grid
	var horizontal_first: bool = abs(delta.x) >= abs(delta.y)
	if horizontal_first:
		current = _walk_network_axis(path, current, Vector2i(_network_axis_sign(delta.x), 0), abs(delta.x))
		current = _walk_network_axis(path, current, Vector2i(0, _network_axis_sign(delta.y)), abs(delta.y))
	else:
		current = _walk_network_axis(path, current, Vector2i(0, _network_axis_sign(delta.y)), abs(delta.y))
		current = _walk_network_axis(path, current, Vector2i(_network_axis_sign(delta.x), 0), abs(delta.x))
	return path


func _network_axis_sign(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0


func _walk_network_axis(path: Array[Vector2i], start_grid: Vector2i, step: Vector2i, count: int) -> Vector2i:
	var current := Vector2i(start_grid)
	if step == Vector2i.ZERO:
		return current
	for _index in range(count):
		current += step
		_append_network_path_grid(path, current)
	return current


func _append_network_path_grid(path: Array[Vector2i], grid_position: Vector2i) -> void:
	if path.is_empty() or Vector2i(path[path.size() - 1]) != grid_position:
		path.append(grid_position)


func _apply_network_path(kind: String, path: Array[Vector2i]) -> bool:
	var normalized_kind: String = kind.strip_edges().to_lower()
	if path.is_empty() or not _network_tool_kind_is_valid(normalized_kind) or _terrain_map_data == null:
		return false
	var candidate_lookup: Dictionary = {}
	for path_grid in path:
		var grid_position := Vector2i(path_grid)
		if _terrain_map_data.call("get_tile_at_grid", grid_position) == null:
			continue
		candidate_lookup[grid_position] = true
		for offset in _get_network_neighbor_offsets():
			var neighbor_grid: Vector2i = grid_position + offset
			var neighbor_tile = _terrain_map_data.call("get_tile_at_grid", neighbor_grid)
			if _tile_matches_network_kind(neighbor_tile, normalized_kind):
				candidate_lookup[neighbor_grid] = true
	var candidate_grids: Array[Vector2i] = _sort_grid_lookup_keys(candidate_lookup)
	if candidate_grids.is_empty():
		return false

	var changed_grids: Array[Vector2i] = []
	var owns_undo_transaction: bool = _ensure_undo_transaction("network_drag_%s" % normalized_kind)
	for grid_position in candidate_grids:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			continue
		var connection_mask: int = _build_network_connection_mask(grid_position, normalized_kind, candidate_lookup)
		var piece: Dictionary = _resolve_network_piece_for_mask(normalized_kind, connection_mask)
		if _apply_network_piece_to_tile(tile_data, piece):
			changed_grids.append(grid_position)
			_refresh_tile_visual(tile_data, false)
	if changed_grids.is_empty():
		if owns_undo_transaction:
			cancel_empty_undo_transaction()
		_last_network_apply_snapshot = _build_network_apply_snapshot(normalized_kind, path, changed_grids, candidate_grids)
		return false

	_refresh_dirty_visual_neighborhoods(changed_grids)
	if owns_undo_transaction:
		commit_undo_transaction()
	_mark_dirty(true)
	_set_selected_grid_position(Vector2i(path[path.size() - 1]))
	_last_network_apply_snapshot = _build_network_apply_snapshot(normalized_kind, path, changed_grids, candidate_grids)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE)
	return true


func _apply_network_piece_to_tile(tile_data, piece: Dictionary) -> bool:
	if tile_data == null or piece.is_empty() or _tile_catalog == null:
		return false
	var type_id: String = String(piece.get("type_id", "")).strip_edges().to_lower()
	if type_id.is_empty() or not _tile_catalog.has_type(type_id):
		return false
	var rotation_degrees: float = fposmod(float(piece.get("rotation_degrees", 0.0)), 360.0)
	var placement_layer: String = _get_catalog_placement_layer(type_id)
	var current_layer_type: String = String(tile_data.object_type_id).strip_edges().to_lower() if placement_layer == "object" else String(tile_data.type_id).strip_edges().to_lower()
	var next_scale: float = _placement_object_scale if _network_piece_uses_object_scale(type_id) else float(tile_data.object_scale)
	var already_matches: bool = (
		current_layer_type == type_id
		and absf(wrapf(float(tile_data.object_rotation_degrees) - rotation_degrees, -180.0, 180.0)) <= 0.001
		and (not _network_piece_uses_object_scale(type_id) or absf(float(tile_data.object_scale) - next_scale) <= 0.001)
	)
	if already_matches:
		return false
	_store_undo_state(tile_data)
	if not _tile_catalog.apply_type_to_tile(tile_data, type_id):
		return false
	tile_data.object_rotation_degrees = rotation_degrees
	if _network_piece_uses_object_scale(type_id):
		tile_data.object_scale = next_scale
	return true


func _build_network_connection_mask(grid_position: Vector2i, kind: String, candidate_lookup: Dictionary) -> int:
	var mask: int = 0
	var direction_entries: Array = [
		[Vector2i(0, -1), NETWORK_DIR_N],
		[Vector2i(1, 0), NETWORK_DIR_E],
		[Vector2i(0, 1), NETWORK_DIR_S],
		[Vector2i(-1, 0), NETWORK_DIR_W],
	]
	for entry in direction_entries:
		var neighbor_grid: Vector2i = grid_position + Vector2i(entry[0])
		var neighbor_tile = _terrain_map_data.call("get_tile_at_grid", neighbor_grid) if _terrain_map_data != null else null
		if candidate_lookup.has(neighbor_grid) or _tile_matches_network_kind(neighbor_tile, kind):
			mask = mask | int(entry[1])
	return mask


func _resolve_network_piece_for_mask(kind: String, mask: int) -> Dictionary:
	var definition: Dictionary = _get_network_tool_definition(kind)
	var connection_count: int = _count_network_mask_dirs(mask)
	var piece_key: String = "straight"
	if connection_count <= 1:
		piece_key = "end" if definition.has("end") and connection_count == 1 else "straight"
	elif connection_count == 2:
		piece_key = "straight" if _network_mask_has_opposite_pair(mask) else "corner"
	elif connection_count == 3:
		piece_key = "split" if definition.has("split") else "straight"
	else:
		piece_key = "cross" if definition.has("cross") else "straight"
	if not definition.has(piece_key):
		piece_key = "straight"
	var type_id: String = String(definition.get(piece_key, definition.get("default_type_id", ""))).strip_edges().to_lower()
	if _tile_catalog != null and not _tile_catalog.has_type(type_id):
		type_id = String(definition.get("default_type_id", "")).strip_edges().to_lower()
	return {
		"type_id": type_id,
		"piece_key": piece_key,
		"rotation_degrees": _resolve_network_piece_rotation_degrees(piece_key, mask),
	}


func _resolve_network_piece_rotation_degrees(piece_key: String, mask: int) -> float:
	match piece_key:
		"straight":
			return 90.0 if (mask & (NETWORK_DIR_E | NETWORK_DIR_W)) != 0 and (mask & (NETWORK_DIR_N | NETWORK_DIR_S)) == 0 else 0.0
		"end":
			return _network_direction_rotation_degrees(_first_network_mask_dir(mask))
		"corner":
			if (mask & NETWORK_DIR_N) != 0 and (mask & NETWORK_DIR_E) != 0:
				return 0.0
			if (mask & NETWORK_DIR_E) != 0 and (mask & NETWORK_DIR_S) != 0:
				return 90.0
			if (mask & NETWORK_DIR_S) != 0 and (mask & NETWORK_DIR_W) != 0:
				return 180.0
			if (mask & NETWORK_DIR_W) != 0 and (mask & NETWORK_DIR_N) != 0:
				return 270.0
		"split":
			return _network_direction_rotation_degrees(_missing_network_mask_dir(mask))
	return 0.0


func _get_network_tool_definition(kind: String) -> Dictionary:
	match kind.strip_edges().to_lower():
		NETWORK_KIND_ROAD:
			return {
				"default_type_id": "spacekit_terrain_road_straight",
				"straight": "spacekit_terrain_road_straight",
				"corner": "spacekit_terrain_road_corner",
				"end": "spacekit_terrain_road_end",
				"split": "spacekit_terrain_road_split",
				"cross": "spacekit_terrain_road_cross",
			}
		NETWORK_KIND_RAIL:
			return {
				"default_type_id": "spacekit_rail",
				"straight": "spacekit_rail",
				"corner": "spacekit_rail_corner",
				"end": "spacekit_rail_end",
				"split": "spacekit_rail_middle",
				"cross": "spacekit_rail_middle",
			}
		NETWORK_KIND_PIPE:
			return {
				"default_type_id": "spacekit_pipe_straight",
				"straight": "spacekit_pipe_straight",
				"corner": "spacekit_pipe_corner",
				"end": "spacekit_pipe_end",
				"split": "spacekit_pipe_split",
				"cross": "spacekit_pipe_cross",
			}
		NETWORK_KIND_WALL:
			return {
				"default_type_id": "modular_wall",
				"straight": "modular_wall",
				"corner": "modular_wall_corner",
			}
		NETWORK_KIND_CLIFF:
			return {
				"default_type_id": "cliff_straight_se",
				"straight": "cliff_straight_se",
				"corner": "cliff_corner_se",
			}
	return {}


func _network_tool_kind_is_valid(kind: String) -> bool:
	return [
		NETWORK_KIND_ROAD,
		NETWORK_KIND_RAIL,
		NETWORK_KIND_PIPE,
		NETWORK_KIND_WALL,
		NETWORK_KIND_CLIFF,
	].has(kind.strip_edges().to_lower())


func _tile_matches_network_kind(tile_data, kind: String) -> bool:
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower() if tile_data.object_type_id is String else ""
	match kind.strip_edges().to_lower():
		NETWORK_KIND_ROAD:
			return type_id.begins_with("spacekit_terrain_road_")
		NETWORK_KIND_RAIL:
			return object_type_id.begins_with("spacekit_rail") or type_id.begins_with("spacekit_rail")
		NETWORK_KIND_PIPE:
			return object_type_id.begins_with("spacekit_pipe") or type_id.begins_with("spacekit_pipe")
		NETWORK_KIND_WALL:
			return type_id.begins_with("modular_wall") or type_id.begins_with("wall_") or type_id.begins_with("station_wall") or object_type_id.begins_with("modular_wall") or object_type_id.begins_with("station_wall")
		NETWORK_KIND_CLIFF:
			return type_id.begins_with("cliff_")
	return false


func _network_piece_uses_object_scale(type_id: String) -> bool:
	return _palette_type_uses_object_scale(type_id) or type_id.strip_edges().to_lower().begins_with("spacekit_terrain_road_")


func _get_network_neighbor_offsets() -> Array[Vector2i]:
	return [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
	]


func _get_catalog_placement_layer(type_id: String) -> String:
	if _tile_catalog == null or not _tile_catalog.has_type(type_id):
		return "terrain"
	return String(Dictionary(_tile_catalog.get_type(type_id)).get("placement_layer", "terrain")).strip_edges().to_lower()


func _count_network_mask_dirs(mask: int) -> int:
	var count: int = 0
	for direction in [NETWORK_DIR_N, NETWORK_DIR_E, NETWORK_DIR_S, NETWORK_DIR_W]:
		if (mask & direction) != 0:
			count += 1
	return count


func _network_mask_has_opposite_pair(mask: int) -> bool:
	return ((mask & NETWORK_DIR_N) != 0 and (mask & NETWORK_DIR_S) != 0) or ((mask & NETWORK_DIR_E) != 0 and (mask & NETWORK_DIR_W) != 0)


func _first_network_mask_dir(mask: int) -> int:
	for direction in [NETWORK_DIR_N, NETWORK_DIR_E, NETWORK_DIR_S, NETWORK_DIR_W]:
		if (mask & direction) != 0:
			return direction
	return NETWORK_DIR_N


func _missing_network_mask_dir(mask: int) -> int:
	for direction in [NETWORK_DIR_N, NETWORK_DIR_E, NETWORK_DIR_S, NETWORK_DIR_W]:
		if (mask & direction) == 0:
			return direction
	return NETWORK_DIR_N


func _network_direction_rotation_degrees(direction: int) -> float:
	match direction:
		NETWORK_DIR_N:
			return 0.0
		NETWORK_DIR_E:
			return 90.0
		NETWORK_DIR_S:
			return 180.0
		NETWORK_DIR_W:
			return 270.0
	return 0.0


func _build_network_drag_tool_snapshot() -> Dictionary:
	var definitions: Dictionary = {}
	for kind in [NETWORK_KIND_ROAD, NETWORK_KIND_RAIL, NETWORK_KIND_PIPE, NETWORK_KIND_WALL, NETWORK_KIND_CLIFF]:
		var definition: Dictionary = _get_network_tool_definition(kind)
		var available: bool = true
		for key in definition.keys():
			if String(key) == "default_type_id":
				continue
			var type_id: String = String(definition.get(key, "")).strip_edges().to_lower()
			if type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_type(type_id):
				available = false
		definitions[kind] = {
			"available": available,
			"definition": definition,
		}
	return {
		"enabled": _network_drag_tool_enabled,
		"kind": _network_tool_kind,
		"is_dragging": _is_network_dragging,
		"start_grid": _network_drag_start_grid,
		"current_grid": _network_drag_current_grid,
		"preview_path": _network_drag_preview_path.duplicate(),
		"preview_count": _network_drag_preview_path.size(),
		"preview_summary": _build_network_drag_preview_summary(),
		"definitions": definitions,
		"last_apply": _last_network_apply_snapshot.duplicate(true),
		"scale_correctable_prefixes": PackedStringArray(["factory_", "spacekit_", "station_set_", "modular_", "wall_", "cliff_"]),
	}


func _build_network_drag_preview_summary() -> Dictionary:
	var visual_preview: Dictionary = _build_network_drag_visual_preview_snapshot()
	return {
		"active": _network_drag_tool_enabled,
		"dragging": _is_network_dragging,
		"kind": _network_tool_kind,
		"start_grid": _network_drag_start_grid,
		"current_grid": _network_drag_current_grid,
		"path_count": _network_drag_preview_path.size(),
		"path": _network_drag_preview_path.duplicate(),
		"visual_preview": visual_preview,
		"visual_active": bool(visual_preview.get("active", false)),
		"visual_segment_count": int(visual_preview.get("segment_count", 0)),
		"ui_sets_gameplay_truth": false,
		"label": "%s line: %d tiles" % [_network_tool_kind.capitalize(), _network_drag_preview_path.size()],
	}


func _build_network_drag_visual_preview_snapshot() -> Dictionary:
	var path: Array = []
	var segments: Array = []
	for grid_variant in _network_drag_preview_path:
		var grid_position := Vector2i(grid_variant)
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position) if _terrain_map_data != null else null
		var world_position: Vector2 = Vector2(tile_data.world_position) if tile_data != null else Vector2.ZERO
		path.append({
			"grid": grid_position,
			"world_position": world_position,
		})
	for index in range(1, path.size()):
		var previous: Dictionary = Dictionary(path[index - 1])
		var current: Dictionary = Dictionary(path[index])
		segments.append({
			"from_grid": Vector2i(previous.get("grid", Vector2i.ZERO)),
			"to_grid": Vector2i(current.get("grid", Vector2i.ZERO)),
			"from_world": Vector2(previous.get("world_position", Vector2.ZERO)),
			"to_world": Vector2(current.get("world_position", Vector2.ZERO)),
		})
	return {
		"active": _network_drag_tool_enabled and path.size() > 0,
		"dragging": _is_network_dragging,
		"kind": _network_tool_kind,
		"path": path,
		"path_count": path.size(),
		"segments": segments,
		"segment_count": segments.size(),
		"start_grid": _network_drag_start_grid,
		"current_grid": _network_drag_current_grid,
		"color": _get_network_drag_preview_color(_network_tool_kind),
		"line_width": 0.12,
		"surface_offset": 0.44,
		"ui_sets_gameplay_truth": false,
	}


func _get_network_drag_preview_color(kind: String) -> Color:
	match kind.strip_edges().to_lower():
		NETWORK_KIND_PIPE:
			return Color(0.45, 0.9, 1.0, 0.9)
		NETWORK_KIND_WALL:
			return Color(1.0, 0.84, 0.34, 0.92)
		NETWORK_KIND_CLIFF:
			return Color(1.0, 0.56, 0.32, 0.9)
		NETWORK_KIND_RAIL:
			return Color(0.74, 0.78, 0.86, 0.88)
		NETWORK_KIND_ROAD:
			return Color(0.35, 0.95, 0.55, 0.86)
	return Color(0.9, 0.95, 1.0, 0.86)


func _sync_network_drag_preview_to_primary_view() -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view == null or not primary_3d_view.has_method("set_editor_network_drag_preview_snapshot"):
		return
	primary_3d_view.call("set_editor_network_drag_preview_snapshot", _build_network_drag_preview_summary())


func _build_station_door_authoring_snapshot() -> Dictionary:
	var single_states: Dictionary = {
		"closed": BUILDER_QUICK_STATION_DOOR_CLOSED_TYPE_ID,
		"half": BUILDER_QUICK_STATION_DOOR_HALF_TYPE_ID,
		"open": BUILDER_QUICK_STATION_DOOR_OPEN_TYPE_ID,
	}
	var double_states: Dictionary = {
		"closed": "station_set_door_double_closed",
		"half": "station_set_door_double_half",
		"open": "station_set_door_double",
	}
	return {
		"ui_sets_gameplay_truth": false,
		"runtime_animation_truth": false,
		"door_wall_type_id": BUILDER_QUICK_STATION_DOOR_WALL_TYPE_ID,
		"single": _build_station_door_state_family_snapshot(single_states),
		"double": _build_station_door_state_family_snapshot(double_states),
		"quick_tool_ids": PackedStringArray(["door_wall", "door_closed", "door_half", "door_open"]),
	}


func _build_station_door_state_family_snapshot(state_type_ids: Dictionary) -> Dictionary:
	var availability: Dictionary = {}
	var all_available: bool = true
	for state in state_type_ids.keys():
		var type_id: String = String(state_type_ids.get(state, "")).strip_edges().to_lower()
		var available: bool = not type_id.is_empty() and _tile_catalog != null and _tile_catalog.has_type(type_id)
		availability[String(state)] = available
		all_available = all_available and available
	return {
		"available": all_available,
		"states": state_type_ids.duplicate(true),
		"availability": availability,
	}


func _build_network_apply_snapshot(kind: String, path: Array[Vector2i], changed_grids: Array[Vector2i], candidate_grids: Array[Vector2i]) -> Dictionary:
	return {
		"kind": kind,
		"path": path.duplicate(),
		"path_count": path.size(),
		"changed_grids": changed_grids.duplicate(),
		"changed_count": changed_grids.size(),
		"candidate_grids": candidate_grids.duplicate(),
		"candidate_count": candidate_grids.size(),
	}


func _ensure_editor_save_controls() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return
	var save_as_button := button_row.get_node_or_null("SaveAsButton") as Button
	if save_as_button == null:
		save_as_button = Button.new()
		save_as_button.name = "SaveAsButton"
		save_as_button.text = "Save As"
		save_as_button.tooltip_text = "Save the current map under a new file name."
		button_row.add_child(save_as_button)
		var save_button := button_row.get_node_or_null("SaveButton") as Button
		if save_button != null:
			button_row.move_child(save_as_button, save_button.get_index() + 1)


func _ensure_map_name_controls() -> void:
	var panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if panel_parent == null:
		return
	if panel_parent.get_node_or_null("MapNameRow") != null:
		return
	var row := HBoxContainer.new()
	row.name = "MapNameRow"
	row.custom_minimum_size = Vector2(0.0, 28.0)
	var label := Label.new()
	label.name = "MapNameLabel"
	label.text = "Map ID"
	label.tooltip_text = "Map ID: stable internal name used by save files, manifests and mission/testmap lookup."
	label.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(label)
	var line_edit := LineEdit.new()
	line_edit.name = "MapNameLineEdit"
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = DEFAULT_NEW_MAP_NAME
	line_edit.tooltip_text = "Map ID: change this before Save As to store the map under a clear scenario/testmap name."
	row.add_child(line_edit)
	panel_parent.add_child(row)
	var insert_before := panel_parent.get_node_or_null("GridSizeLabel")
	if insert_before != null:
		panel_parent.move_child(row, insert_before.get_index())


func _ensure_object_rotation_controls() -> void:
	var panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if panel_parent == null:
		return
	if panel_parent.get_node_or_null("ObjectRotationRow") != null:
		return
	var row := HBoxContainer.new()
	row.name = "ObjectRotationRow"
	row.custom_minimum_size = Vector2(0.0, 28.0)
	var label := Label.new()
	label.name = "ObjectRotationLabel"
	label.text = "Drehung"
	label.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(label)
	var rotate_left := Button.new()
	rotate_left.name = "ObjectRotateLeftButton"
	rotate_left.text = "-90"
	rotate_left.tooltip_text = "Dreht das ausgewaehlte Objekt oder Stations-Wandteil um 90 Grad nach links."
	row.add_child(rotate_left)
	var rotate_right := Button.new()
	rotate_right.name = "ObjectRotateRightButton"
	rotate_right.text = "+90"
	rotate_right.tooltip_text = "Dreht das ausgewaehlte Objekt oder Stations-Wandteil um 90 Grad nach rechts."
	row.add_child(rotate_right)
	var value_label := Label.new()
	value_label.name = "ObjectRotationValueLabel"
	value_label.text = "-"
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	panel_parent.add_child(row)
	var insert_after := panel_parent.get_node_or_null("SurfaceRow")
	if insert_after != null:
		panel_parent.move_child(row, insert_after.get_index() + 1)


func _ensure_object_scale_controls() -> void:
	var panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if panel_parent == null:
		return
	if panel_parent.get_node_or_null("ObjectScaleRow") != null:
		return
	var row := HBoxContainer.new()
	row.name = "ObjectScaleRow"
	row.custom_minimum_size = Vector2(0.0, 28.0)
	var label := Label.new()
	label.name = "ObjectScaleLabel"
	label.text = "Scale"
	label.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(label)
	var scale_spinbox := SpinBox.new()
	scale_spinbox.name = "ObjectScaleSpinBox"
	scale_spinbox.min_value = OBJECT_SCALE_MIN
	scale_spinbox.max_value = OBJECT_SCALE_MAX
	scale_spinbox.step = OBJECT_SCALE_STEP
	scale_spinbox.value = OBJECT_SCALE_DEFAULT
	scale_spinbox.allow_greater = false
	scale_spinbox.allow_lesser = false
	scale_spinbox.custom_minimum_size = Vector2(92.0, 0.0)
	scale_spinbox.tooltip_text = "Aendert den gespeicherten Scale des ausgewaehlten Assets."
	row.add_child(scale_spinbox)
	var reset_button := Button.new()
	reset_button.name = "ObjectScaleResetButton"
	reset_button.text = "1.0"
	reset_button.tooltip_text = "Setzt den Scale des ausgewaehlten Assets auf 1.0 zurueck."
	row.add_child(reset_button)
	panel_parent.add_child(row)
	var insert_after := panel_parent.get_node_or_null("ObjectRotationRow")
	if insert_after != null:
		panel_parent.move_child(row, insert_after.get_index() + 1)


func _ensure_palette_workflow_controls() -> void:
	var palette_parent := get_node_or_null("UI/PalettePanel/Margin/VBox") as VBoxContainer
	if palette_parent == null:
		return
	if palette_parent.get_node_or_null("PaletteSelectedPreviewRow") != null:
		_ensure_palette_scale_preset_buttons(palette_parent.get_node_or_null("PaletteSelectedPreviewRow/PaletteSelectedInfoBox/PalettePlacementScaleRow") as HBoxContainer)
		_refresh_palette_workflow_controls()
		return
	var row := HBoxContainer.new()
	row.name = "PaletteSelectedPreviewRow"
	row.custom_minimum_size = Vector2(0.0, 92.0)
	var preview_rect := TextureRect.new()
	preview_rect.name = "PaletteSelectedPreviewTextureRect"
	preview_rect.custom_minimum_size = PALETTE_SELECTED_PREVIEW_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_rect.tooltip_text = "Groessere Vorschau fuer das aktuell gewaehlte Palette-Asset."
	row.add_child(preview_rect)
	var info_box := VBoxContainer.new()
	info_box.name = "PaletteSelectedInfoBox"
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var info_label := Label.new()
	info_label.name = "PaletteSelectedInfoLabel"
	info_label.text = "Kein Asset"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.tooltip_text = "Ausgewaehltes Asset, Palette-Gruppe und Platzierungs-Scale."
	info_box.add_child(info_label)
	var scale_row := HBoxContainer.new()
	scale_row.name = "PalettePlacementScaleRow"
	var scale_label := Label.new()
	scale_label.name = "PalettePlacementScaleLabel"
	scale_label.text = "Scale"
	scale_label.custom_minimum_size = Vector2(44.0, 0.0)
	scale_row.add_child(scale_label)
	var placement_scale := SpinBox.new()
	placement_scale.name = "PlacementObjectScaleSpinBox"
	placement_scale.min_value = OBJECT_SCALE_MIN
	placement_scale.max_value = OBJECT_SCALE_MAX
	placement_scale.step = OBJECT_SCALE_STEP
	placement_scale.value = _placement_object_scale
	placement_scale.allow_greater = false
	placement_scale.allow_lesser = false
	placement_scale.custom_minimum_size = Vector2(88.0, 0.0)
	placement_scale.tooltip_text = "Scale fuer neu gepinselte Assets. Default ist 1.0, Korrekturen wie 1.6 werden pro Tile gespeichert."
	scale_row.add_child(placement_scale)
	var reset_button := Button.new()
	reset_button.name = "PlacementObjectScaleResetButton"
	reset_button.text = "1.0"
	reset_button.tooltip_text = "Setzt den Platzierungs-Scale fuer neue Assets auf 1.0."
	scale_row.add_child(reset_button)
	_ensure_palette_scale_preset_buttons(scale_row)
	info_box.add_child(scale_row)
	row.add_child(info_box)
	palette_parent.add_child(row)
	var insert_after := palette_parent.get_node_or_null("PaletteTitle")
	if insert_after != null:
		palette_parent.move_child(row, insert_after.get_index() + 1)
	_refresh_palette_workflow_controls()


func _ensure_palette_scale_preset_buttons(scale_row: HBoxContainer) -> void:
	if scale_row == null:
		return
	for preset_variant in PALETTE_SCALE_PRESETS:
		var preset_value: float = float(preset_variant)
		var button_name: String = "PlacementScalePreset_%s" % _format_scale_token(preset_value)
		var button := scale_row.get_node_or_null(button_name) as Button
		if button == null:
			button = Button.new()
			button.name = button_name
			button.text = _format_scale_label(preset_value)
			button.tooltip_text = "Setzt den Platzierungs-Scale auf %s." % _format_scale_label(preset_value)
			button.custom_minimum_size = Vector2(36.0, 0.0)
			scale_row.add_child(button)
		if not button.pressed.is_connected(set_object_placement_scale_preset.bind(preset_value)):
			button.pressed.connect(set_object_placement_scale_preset.bind(preset_value))


func _ensure_palette_quick_filter_controls() -> void:
	var palette_parent := get_node_or_null("UI/PalettePanel/Margin/VBox") as VBoxContainer
	if palette_parent == null:
		return
	var row := palette_parent.get_node_or_null("PaletteQuickFilterRow") as HBoxContainer
	if row == null:
		row = HBoxContainer.new()
		row.name = "PaletteQuickFilterRow"
		row.custom_minimum_size = Vector2(0.0, 30.0)
		palette_parent.add_child(row)
		var insert_after := palette_parent.get_node_or_null("PaletteGroupsScroll")
		if insert_after == null:
			insert_after = palette_parent.get_node_or_null("PaletteSelectedPreviewRow")
		if insert_after != null:
			palette_parent.move_child(row, insert_after.get_index() + 1)
	var search := row.get_node_or_null("PaletteSearchLineEdit") as LineEdit
	if search == null:
		search = LineEdit.new()
		search.name = "PaletteSearchLineEdit"
		search.placeholder_text = "Asset suchen"
		search.clear_button_enabled = true
		search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		search.tooltip_text = "Filtert Assets nach Name, Gruppe oder Type-ID."
		row.add_child(search)
	if not search.text_changed.is_connected(_on_palette_search_text_changed):
		search.text_changed.connect(_on_palette_search_text_changed)
	var favorite_filter := row.get_node_or_null("PaletteFavoriteFilterButton") as Button
	if favorite_filter == null:
		favorite_filter = Button.new()
		favorite_filter.name = "PaletteFavoriteFilterButton"
		favorite_filter.text = "Fav"
		favorite_filter.toggle_mode = true
		favorite_filter.tooltip_text = "Zeigt Favoriten und zuletzt genutzte Assets."
		favorite_filter.custom_minimum_size = Vector2(48.0, 0.0)
		row.add_child(favorite_filter)
	if not favorite_filter.toggled.is_connected(set_palette_favorites_filter_enabled):
		favorite_filter.toggled.connect(set_palette_favorites_filter_enabled)
	var favorite_toggle := row.get_node_or_null("PaletteFavoriteToggleButton") as Button
	if favorite_toggle == null:
		favorite_toggle = Button.new()
		favorite_toggle.name = "PaletteFavoriteToggleButton"
		favorite_toggle.text = "+"
		favorite_toggle.tooltip_text = "Aktuelles Asset als Favorit merken oder entfernen."
		favorite_toggle.custom_minimum_size = Vector2(34.0, 0.0)
		row.add_child(favorite_toggle)
	if not favorite_toggle.pressed.is_connected(toggle_palette_favorite_for_authoring):
		favorite_toggle.pressed.connect(toggle_palette_favorite_for_authoring)
	_refresh_palette_filter_controls()


func _ensure_palette_browser_layout_controls() -> void:
	var palette_parent := get_node_or_null("UI/PalettePanel/Margin/VBox") as VBoxContainer
	if palette_parent == null:
		return
	var legacy_groups := palette_parent.get_node_or_null("PaletteGroups") as VBoxContainer
	var scroll := palette_parent.get_node_or_null("PaletteGroupsScroll") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		scroll.name = "PaletteGroupsScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.custom_minimum_size = Vector2(0.0, PALETTE_GROUP_SCROLL_HEIGHT)
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		palette_parent.add_child(scroll)
		var insert_after := palette_parent.get_node_or_null("PaletteSelectedPreviewRow")
		if insert_after == null:
			insert_after = palette_parent.get_node_or_null("PaletteTitle")
		if insert_after != null:
			palette_parent.move_child(scroll, insert_after.get_index() + 1)
	else:
		scroll.custom_minimum_size = Vector2(0.0, PALETTE_GROUP_SCROLL_HEIGHT)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var grid := scroll.get_node_or_null("PaletteGroupsGrid") as GridContainer
	if grid == null:
		grid = GridContainer.new()
		grid.name = "PaletteGroupsGrid"
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(grid)
	grid.columns = PALETTE_GROUP_COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 3)
	if legacy_groups != null:
		legacy_groups.visible = false


func _ensure_terrain_truth_inspector_controls() -> void:
	var panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if panel_parent == null:
		return
	var label := panel_parent.get_node_or_null("TerrainTruthInspectorLabel") as Label
	if label == null:
		label = Label.new()
		label.name = "TerrainTruthInspectorLabel"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(0.0, 96.0)
		label.tooltip_text = "Read-only Terrain Truth: dieselben Tile-/LOS-Werte, die Debug-Overlay und Runtime-LOS lesen."
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.78, 0.93, 0.98, 0.96))
		panel_parent.add_child(label)
	var insert_after := panel_parent.get_node_or_null("TypeLabel")
	if insert_after != null:
		panel_parent.move_child(label, insert_after.get_index() + 1)
	_refresh_terrain_truth_inspector(_get_selected_tile())


func _ensure_editor_context_menu() -> PopupMenu:
	if _editor_context_menu != null and is_instance_valid(_editor_context_menu):
		return _editor_context_menu
	_editor_context_menu = get_node_or_null("EditorContextMenu") as PopupMenu
	if _editor_context_menu == null:
		_editor_context_menu = PopupMenu.new()
		_editor_context_menu.name = "EditorContextMenu"
		add_child(_editor_context_menu)
	_editor_context_menu.clear()
	_editor_context_menu.add_item("Drehen links", CONTEXT_MENU_ROTATE_LEFT_ID)
	_editor_context_menu.add_item("Drehen rechts", CONTEXT_MENU_ROTATE_RIGHT_ID)
	_editor_context_menu.add_separator()
	_editor_context_menu.add_item("Objekt entfernen", CONTEXT_MENU_ERASE_OBJECT_ID)
	if not _editor_context_menu.id_pressed.is_connected(_on_editor_context_menu_id_pressed):
		_editor_context_menu.id_pressed.connect(_on_editor_context_menu_id_pressed)
	return _editor_context_menu


func _apply_editor_control_panel_style() -> void:
	_apply_panel_style(get_node_or_null("UI/TopBar") as PanelContainer, Color(0.06, 0.09, 0.11, 0.94), Color(0.32, 0.55, 0.62, 0.72))
	_apply_panel_style(get_node_or_null("UI/PalettePanel") as PanelContainer, Color(0.055, 0.075, 0.085, 0.96), Color(0.28, 0.47, 0.52, 0.68))
	_apply_panel_style(get_node_or_null("UI/PropertyPanel") as PanelContainer, Color(0.065, 0.075, 0.08, 0.96), Color(0.24, 0.39, 0.43, 0.62))
	var palette_panel := get_node_or_null("UI/PalettePanel") as PanelContainer
	if palette_panel != null:
		palette_panel.custom_minimum_size = Vector2(PALETTE_PANEL_MIN_WIDTH, palette_panel.custom_minimum_size.y)
		palette_panel.offset_right = maxf(palette_panel.offset_right, PALETTE_PANEL_MIN_WIDTH)
	var tile_type_list := _get_tile_type_list()
	if tile_type_list != null:
		tile_type_list.fixed_icon_size = PALETTE_PREVIEW_ICON_SIZE
		tile_type_list.icon_mode = ItemList.ICON_MODE_TOP
		tile_type_list.max_columns = PALETTE_ASSET_COLUMNS
		tile_type_list.fixed_column_width = PALETTE_ASSET_COLUMN_WIDTH
		tile_type_list.max_text_lines = 2
		tile_type_list.custom_minimum_size = Vector2(PALETTE_PANEL_MIN_WIDTH - 36.0, PALETTE_ASSET_LIST_MIN_HEIGHT)
		tile_type_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tile_type_list.add_theme_constant_override("h_separation", 10)
		tile_type_list.add_theme_constant_override("v_separation", 10)
		tile_type_list.add_theme_color_override("font_color", PALETTE_ITEM_FG_COLOR)
		tile_type_list.add_theme_color_override("font_selected_color", PALETTE_SELECTED_FG_COLOR)
	var palette_title := get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteTitle") as Label
	if palette_title != null:
		palette_title.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0, 1.0))


func _apply_panel_style(panel: PanelContainer, bg_color: Color, border_color: Color) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)


func _add_patrol_tool_controls() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return
	var patrol_button := button_row.get_node_or_null("PatrolButton") as Button
	if patrol_button == null:
		patrol_button = Button.new()
		patrol_button.name = "PatrolButton"
		patrol_button.toggle_mode = true
		patrol_button.toggled.connect(_on_patrol_tool_toggled)
		button_row.add_child(patrol_button)
	_configure_tool_button(patrol_button, "P", "Patrol: place NPC pre-contact path points for the selected spawn/group.")
	var spawn_selector := button_row.get_node_or_null("PatrolSpawnOption") as OptionButton
	if spawn_selector == null:
		spawn_selector = OptionButton.new()
		spawn_selector.name = "PatrolSpawnOption"
		spawn_selector.custom_minimum_size = Vector2(120.0, 0.0)
		spawn_selector.tooltip_text = "NPC patrol source: choose which spawn/group receives new patrol points."
		button_row.add_child(spawn_selector)
	_refresh_patrol_spawn_selector()
	if not spawn_selector.item_selected.is_connected(_on_patrol_spawn_selected):
		spawn_selector.item_selected.connect(_on_patrol_spawn_selected)
	var clear_button := button_row.get_node_or_null("ClearPatrolButton") as Button
	if clear_button == null:
		clear_button = Button.new()
		clear_button.name = "ClearPatrolButton"
		clear_button.text = "Clear Patrol"
		clear_button.tooltip_text = "Clears the patrol waypoint chain for the selected spawn/group."
		clear_button.pressed.connect(_on_clear_patrol_pressed)
		button_row.add_child(clear_button)
	_update_patrol_topbar_state()
	_arrange_topbar_authoring_tools()


func _add_tile_property_overlay_controls() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return
	var overlay_button := button_row.get_node_or_null("TilePropertyOverlayButton") as Button
	if overlay_button == null:
		overlay_button = Button.new()
		overlay_button.name = "TilePropertyOverlayButton"
		overlay_button.toggle_mode = true
		overlay_button.toggled.connect(_on_tile_property_overlay_toggled)
		button_row.add_child(overlay_button)
	_configure_tool_button(overlay_button, "DBG", "Tile property overlay: blue walkable, red blocked, purple LOS, green cover, amber height.")
	overlay_button.button_pressed = _tile_property_overlay_enabled


func _add_adjacency_debug_overlay_controls() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return
	var overlay_button := button_row.get_node_or_null("AdjacencyDebugOverlayButton") as Button
	if overlay_button == null:
		overlay_button = Button.new()
		overlay_button.name = "AdjacencyDebugOverlayButton"
		overlay_button.toggle_mode = true
		overlay_button.toggled.connect(_on_adjacency_debug_overlay_toggled)
		button_row.add_child(overlay_button)
	_configure_tool_button(overlay_button, "ADJ", "Adjacency solver debug: yellow seeds, cyan recomputed neighbors, orange object candidates.")
	overlay_button.button_pressed = _adjacency_debug_overlay_enabled


func _on_selection_tool_toggled(pressed: bool) -> void:
	_selection_tool_enabled = pressed
	if pressed:
		_clear_height_tool()
		_network_drag_tool_enabled = false
		_clear_network_drag_preview()
		_eraser_tool_enabled = false
		var eraser_button := _get_eraser_tool_button()
		if eraser_button != null and eraser_button.button_pressed:
			eraser_button.button_pressed = false
		var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
		if brush_button != null and brush_button.button_pressed:
			brush_button.button_pressed = false
		_marker_tool_enabled = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
		_patrol_tool_enabled = false
		var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
		if patrol_button != null and patrol_button.button_pressed:
			patrol_button.button_pressed = false
		_clear_patrol_route_preview(true)
		_is_painting = false
		_last_painted_grid = Vector2i(-1, -1)
		_hide_hover_preview()
	_update_patrol_topbar_state()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_brush_tool_toggled(pressed: bool) -> void:
	if pressed:
		_clear_height_tool()
		_network_drag_tool_enabled = false
		_clear_network_drag_preview()
		_selection_tool_enabled = false
		_eraser_tool_enabled = false
		var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
		if select_button != null and select_button.button_pressed:
			select_button.button_pressed = false
		var eraser_button := _get_eraser_tool_button()
		if eraser_button != null and eraser_button.button_pressed:
			eraser_button.button_pressed = false
		_marker_tool_enabled = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
		_patrol_tool_enabled = false
		var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
		if patrol_button != null and patrol_button.button_pressed:
			patrol_button.button_pressed = false
		_clear_patrol_route_preview(true)
	else:
		_is_painting = false
		_last_painted_grid = Vector2i(-1, -1)
		_hide_hover_preview()
	_update_patrol_topbar_state()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_eraser_tool_toggled(pressed: bool) -> void:
	_eraser_tool_enabled = pressed
	if pressed:
		_clear_height_tool()
		_network_drag_tool_enabled = false
		_clear_network_drag_preview()
		_selection_tool_enabled = false
		var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
		if select_button != null and select_button.button_pressed:
			select_button.button_pressed = false
		var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
		if brush_button != null and brush_button.button_pressed:
			brush_button.button_pressed = false
		_marker_tool_enabled = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
		_patrol_tool_enabled = false
		var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
		if patrol_button != null and patrol_button.button_pressed:
			patrol_button.button_pressed = false
		_clear_patrol_route_preview(true)
	else:
		_is_painting = false
		_last_painted_grid = Vector2i(-1, -1)
		_hide_hover_preview()
	_update_patrol_topbar_state()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_patrol_tool_toggled(pressed: bool) -> void:
	_patrol_tool_enabled = pressed
	if pressed:
		_clear_height_tool()
		_network_drag_tool_enabled = false
		_clear_network_drag_preview()
		_marker_tool_enabled = false
		_eraser_tool_enabled = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
		var eraser_button := _get_eraser_tool_button()
		if eraser_button != null and eraser_button.button_pressed:
			eraser_button.button_pressed = false
		_selection_tool_enabled = false
		var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
		if select_button != null and select_button.button_pressed:
			select_button.button_pressed = false
		preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	else:
		_clear_patrol_route_preview(true)
	_update_patrol_topbar_state()
	_refresh_patrol_overlay()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_patrol_spawn_selected(index: int) -> void:
	var spawn_selector := get_node_or_null("UI/TopBar/Margin/HBox/PatrolSpawnOption") as OptionButton
	if spawn_selector == null or index < 0 or index >= spawn_selector.item_count:
		return
	_patrol_spawn_id = String(spawn_selector.get_item_metadata(index)).strip_edges()
	preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	_refresh_patrol_overlay()
	_refresh_authoring_status_controls()


func _on_tile_property_overlay_toggled(pressed: bool) -> void:
	set_tile_property_overlay_enabled(pressed)


func _on_adjacency_debug_overlay_toggled(pressed: bool) -> void:
	set_adjacency_debug_overlay_enabled(pressed)


func _on_clear_patrol_pressed() -> void:
	if _terrain_map_data == null or _patrol_spawn_id.is_empty():
		return
	_terrain_map_data.call("set_patrol_path", _resolve_patrol_edit_path_id(_patrol_spawn_id), [])
	_mark_dirty(true)
	preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	_refresh_patrol_overlay()
	_refresh_authoring_status_controls()


func _refresh_property_panel() -> void:
	var tile_data = _get_selected_tile()
	var tile_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/TileLabel") as Label
	var type_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/TypeLabel") as Label
	var walkable_checkbox := _get_walkable_checkbox()
	var blocks_los_checkbox := _get_blocks_los_checkbox()
	var cover_spinbox := _get_cover_spinbox()
	var height_spinbox := _get_height_spinbox()
	var surface_option_button := _get_surface_option_button()
	var edge_type_option_button := _get_edge_type_option_button()
	if tile_label == null or walkable_checkbox == null or blocks_los_checkbox == null or cover_spinbox == null or height_spinbox == null or surface_option_button == null:
		return
	_refresh_map_settings_panel()

	_is_refreshing_property_controls = true
	if tile_data == null:
		tile_label.text = "Tile: -"
		if type_label != null:
			type_label.text = "Typ: -"
		walkable_checkbox.button_pressed = false
		blocks_los_checkbox.button_pressed = false
		cover_spinbox.value = 0
		height_spinbox.value = 0
		surface_option_button.select(_find_surface_option_index(_last_selected_surface_type))
		if edge_type_option_button != null:
			var edge_idx := 0
			match _last_selected_edge_type:
				TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
					edge_idx = 1
				TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
					edge_idx = 2
			edge_type_option_button.select(edge_idx)
		_refresh_object_rotation_controls(null)
		_refresh_object_scale_controls(null)
		_refresh_terrain_truth_inspector(null)
		_set_property_controls_enabled(false)
		_is_refreshing_property_controls = false
		_refresh_authoring_status_controls()
		_apply_inspector_section_visibility()
		return

	tile_label.text = "Tile: (%d, %d)" % [tile_data.grid_position.x, tile_data.grid_position.y]
	if type_label != null:
		var tile_type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
		var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
		var object_label: String = ""
		if not object_type_id.is_empty() and _tile_catalog != null and _tile_catalog.has_type(object_type_id):
			object_label = " | Objekt: %s" % _tile_catalog.get_display_name(object_type_id)
		if not tile_type_id.is_empty() and _tile_catalog != null and _tile_catalog.has_type(tile_type_id):
			type_label.text = "Typ: %s%s" % [_tile_catalog.get_display_name(tile_type_id), object_label]
		else:
			var matched_type_id: String = _find_matching_type_id(tile_data)
			if matched_type_id.is_empty():
				type_label.text = "Typ: (custom)%s" % object_label
			else:
				type_label.text = "Typ: %s%s" % [_tile_catalog.get_display_name(matched_type_id), object_label]
		var stack_info: Dictionary = _build_tile_layer_stack_info(tile_data)
		type_label.tooltip_text = String(stack_info.get("help_text", ""))
	_refresh_terrain_truth_inspector(tile_data)
	walkable_checkbox.button_pressed = bool(tile_data.walkable)
	blocks_los_checkbox.button_pressed = bool(tile_data.blocks_los)
	cover_spinbox.value = int(tile_data.cover_value)
	height_spinbox.value = int(tile_data.height_level)
	surface_option_button.select(_find_surface_option_index(String(tile_data.surface_type)))
	if edge_type_option_button != null:
		var edge_idx: int = 0
		match String(tile_data.edge_type):
			TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
				edge_idx = 1
			TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
				edge_idx = 2
		edge_type_option_button.select(edge_idx)
	_refresh_object_rotation_controls(tile_data)
	_refresh_object_scale_controls(tile_data)
	_set_property_controls_enabled(true)
	_is_refreshing_property_controls = false
	_refresh_authoring_status_controls()
	_apply_inspector_section_visibility()


func get_selected_tile_truth_debug_snapshot() -> Dictionary:
	return _build_tile_truth_inspector_snapshot(_get_selected_tile())


func _refresh_terrain_truth_inspector(tile_data) -> void:
	var label := get_node_or_null("UI/PropertyPanel/Margin/VBox/TerrainTruthInspectorLabel") as Label
	if label == null:
		return
	var snapshot: Dictionary = _build_tile_truth_inspector_snapshot(tile_data)
	label.text = _format_tile_truth_inspector_text(snapshot)
	label.tooltip_text = "Read-only Terrain Truth. Runtime-LOS nutzt Wandsegmente: %s." % str(bool(snapshot.get("combat_los_uses_segment_policy", false)))


func _build_tile_truth_inspector_snapshot(tile_data) -> Dictionary:
	var policy: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_policy_snapshot"))
	if tile_data == null:
		return {
			"selected": false,
			"visual_only": true,
			"ui_sets_gameplay_truth": false,
			"combat_los_uses_segment_policy": bool(policy.get("combat_los_uses_segment_policy", false)),
			"wall_los_policy": String(policy.get("wall_los_policy", "")),
		}
	var entry: Dictionary = Dictionary(TERRAIN_TRUTH_AUDIT_SCRIPT.call("build_tile_truth_entry", tile_data))
	var truth_label: String = String(MAP_EDITOR_TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_truth_label", tile_data, entry))
	entry["selected"] = true
	entry["visual_only"] = true
	entry["ui_sets_gameplay_truth"] = false
	entry["grid_position"] = tile_data.grid_position
	entry["world_position"] = tile_data.world_position
	entry["truth_label"] = truth_label
	entry["truth_issue_count"] = _get_variant_count(entry.get("issues", PackedStringArray()))
	entry["combat_los_uses_segment_policy"] = bool(policy.get("combat_los_uses_segment_policy", false))
	entry["combat_los_policy_source"] = String(policy.get("combat_los_policy_source", ""))
	entry["wall_los_policy"] = String(policy.get("wall_los_policy", ""))
	return entry


func _format_tile_truth_inspector_text(snapshot: Dictionary) -> String:
	if not bool(snapshot.get("selected", false)):
		return "Terrain Truth\nKein Tile ausgewaehlt.\nRuntime LOS: %s" % String(snapshot.get("wall_los_policy", "-"))
	var grid_position: Vector2i = Vector2i(snapshot.get("grid_position", Vector2i(-1, -1)))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Terrain Truth | %s" % String(snapshot.get("truth_label", "-")))
	lines.append("Grid %d,%d | %s" % [grid_position.x, grid_position.y, String(snapshot.get("tile_id", ""))])
	var object_type_id: String = String(snapshot.get("object_type_id", "")).strip_edges()
	lines.append("Typ %s | Obj %s" % [String(snapshot.get("type_id", "")), object_type_id if not object_type_id.is_empty() else "-"])
	lines.append("Layer %s | %s" % [String(snapshot.get("ground_layer_state", "")), String(snapshot.get("object_layer_state", ""))])
	lines.append("Walk %s | LOS %s | C%d | H%d | ObjH%d" % [
		str(bool(snapshot.get("walkable", false))),
		str(bool(snapshot.get("blocks_los", false))),
		int(snapshot.get("cover_value", 0)),
		int(snapshot.get("height_level", 0)),
		int(snapshot.get("object_height", 0)),
	])
	lines.append("Rot %.0f | Scale %.2f" % [
		float(snapshot.get("object_rotation_degrees", 0.0)),
		float(snapshot.get("object_scale", OBJECT_SCALE_DEFAULT)),
	])
	lines.append("Blocker %s | Seg %d | Runtime %s" % [
		String(snapshot.get("blocker_type", "none")),
		int(snapshot.get("wall_segment_count", 0)),
		String(snapshot.get("wall_los_policy", "")),
	])
	if int(snapshot.get("truth_issue_count", 0)) > 0:
		lines.append("Issues: %s" % ", ".join(PackedStringArray(snapshot.get("issues", PackedStringArray()))))
	return "\n".join(lines)


func _get_variant_count(value: Variant) -> int:
	if value is PackedStringArray:
		return value.size()
	if value is Array:
		return Array(value).size()
	return 0


func _refresh_map_settings_panel() -> void:
	var grid_size_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/GridSizeLabel") as Label
	var mission_slot_spinbox := _get_mission_slot_spinbox()
	var map_name_line_edit := _get_map_name_line_edit()
	if grid_size_label == null or mission_slot_spinbox == null:
		return

	_is_refreshing_map_settings_controls = true
	if _terrain_map_data == null:
		grid_size_label.text = "Grid: -"
		mission_slot_spinbox.value = MIN_MISSION_SLOT_COUNT
		mission_slot_spinbox.editable = false
		if map_name_line_edit != null:
			map_name_line_edit.text = ""
			map_name_line_edit.editable = false
		_refresh_marker_editor_controls()
		_is_refreshing_map_settings_controls = false
		_apply_inspector_section_visibility()
		return

	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	if map_name_line_edit != null:
		map_name_line_edit.text = _get_current_map_name()
		map_name_line_edit.editable = true
	grid_size_label.text = "Grid: %d x %d" % [grid_size.x, grid_size.y]
	mission_slot_spinbox.value = clampi(int(_terrain_map_data.call("get_mission_slot_count")), MIN_MISSION_SLOT_COUNT, MAX_MISSION_SLOT_COUNT)
	mission_slot_spinbox.editable = true
	_refresh_marker_editor_controls()
	_is_refreshing_map_settings_controls = false
	_apply_inspector_section_visibility()


func _update_marker_controls(marker_id: String, marker_position: Vector2, has_marker: bool, can_assign: bool) -> void:
	var marker_label := _get_marker_label(marker_id)
	var marker_button := _get_marker_button(marker_id)
	if marker_label != null:
		if has_marker:
			marker_label.text = "%s: %d, %d" % [marker_id, int(round(marker_position.x)), int(round(marker_position.y))]
		else:
			marker_label.text = "%s: -" % marker_id
	if marker_button != null:
		marker_button.disabled = not can_assign


func _ensure_marker_editor_controls() -> void:
	var marker_title := get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkersTitle") as Label
	if marker_title != null:
		marker_title.text = "Markers"
	var marker_help_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerHelpLabel") as Label
	if marker_help_label != null:
		marker_help_label.text = "Markers come from a fixed list. Add one, place or drag it on the map, double-click to rename, and use DEL to remove it. Markers snap to tiles and do not overlap."
		marker_help_label.tooltip_text = "Markers are editor-authored map annotations. PC/NPC spawns and objectives feed mission setup; notes and danger/loot/recon points guide later gameplay content."
	_hide_legacy_marker_rows()

	var marker_panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if marker_panel_parent == null:
		return
	var marker_panel := marker_panel_parent.get_node_or_null("MarkerEditorPanel") as VBoxContainer
	if marker_panel == null:
		marker_panel = VBoxContainer.new()
		marker_panel.name = "MarkerEditorPanel"
		marker_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		marker_panel.add_theme_constant_override("separation", 6)
		marker_panel_parent.add_child(marker_panel)

		var toolbar := HBoxContainer.new()
		toolbar.name = "MarkerToolbarRow"
		toolbar.add_theme_constant_override("separation", 6)
		marker_panel.add_child(toolbar)

		var add_type_option := OptionButton.new()
		add_type_option.name = "AddMarkerTypeOption"
		add_type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_type_option.tooltip_text = "Marker type to add. The marker info panel explains the selected type."
		toolbar.add_child(add_type_option)

		var add_marker_button := Button.new()
		add_marker_button.name = "AddMarkerButton"
		add_marker_button.text = "Add"
		add_marker_button.tooltip_text = "Create the selected marker type. Single-instance markers such as PC/NPC Spawn are reused instead of duplicated."
		toolbar.add_child(add_marker_button)

		var marker_tool_button := Button.new()
		marker_tool_button.name = "MarkerToolButton"
		marker_tool_button.toggle_mode = true
		toolbar.add_child(marker_tool_button)
		_configure_tool_button(marker_tool_button, "M", "Marker: place selected map markers or drag existing markers on the grid.")

		var remove_marker_button := Button.new()
		remove_marker_button.name = "RemoveMarkerButton"
		remove_marker_button.text = "Remove"
		remove_marker_button.tooltip_text = "Delete the selected marker from this map."
		toolbar.add_child(remove_marker_button)

		var marker_list := ItemList.new()
		marker_list.name = "MarkerList"
		marker_list.select_mode = ItemList.SELECT_SINGLE
		marker_list.allow_reselect = true
		marker_list.custom_minimum_size = Vector2(0.0, 170.0)
		marker_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		marker_list.tooltip_text = "All markers currently stored on this map. Double-click a marker to focus it."
		marker_panel.add_child(marker_list)

		var type_row := HBoxContainer.new()
		type_row.name = "SelectedMarkerTypeRow"
		type_row.add_theme_constant_override("separation", 6)
		marker_panel.add_child(type_row)

		var type_label := Label.new()
		type_label.text = "Type:"
		type_row.add_child(type_label)

		var selected_type_option := OptionButton.new()
		selected_type_option.name = "SelectedMarkerTypeOption"
		selected_type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		selected_type_option.tooltip_text = "Change the selected marker's type while keeping its position."
		type_row.add_child(selected_type_option)

		var name_row := HBoxContainer.new()
		name_row.name = "SelectedMarkerNameRow"
		name_row.add_theme_constant_override("separation", 6)
		marker_panel.add_child(name_row)

		var name_label := Label.new()
		name_label.text = "Name:"
		name_row.add_child(name_label)

		var name_line_edit := LineEdit.new()
		name_line_edit.name = "MarkerNameLineEdit"
		name_line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_line_edit.tooltip_text = "Display name stored with this marker."
		name_row.add_child(name_line_edit)

		var color_row := HBoxContainer.new()
		color_row.name = "SelectedMarkerColorRow"
		color_row.add_theme_constant_override("separation", 6)
		marker_panel.add_child(color_row)

		var color_label := Label.new()
		color_label.text = "Color:"
		color_row.add_child(color_label)

		var color_picker_button := ColorPickerButton.new()
		color_picker_button.name = "MarkerColorButton"
		color_picker_button.custom_minimum_size = Vector2(88.0, 0.0)
		color_picker_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_picker_button.tooltip_text = "Marker color used in the 2D editor overlay."
		color_row.add_child(color_picker_button)

		var marker_info_label := Label.new()
		marker_info_label.name = "MarkerInfoLabel"
		marker_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		marker_info_label.text = "Select a marker to edit it."
		marker_panel.add_child(marker_info_label)

	var marker_tool_button := _get_marker_tool_button()
	if marker_tool_button != null:
		_configure_tool_button(marker_tool_button, "M", "Marker: place selected map markers or drag existing markers on the grid.")
	_populate_marker_type_options()
	_connect_marker_editor_signals()
	_refresh_marker_editor_controls()


func _ensure_mission_scenario_panel_controller():
	if _mission_scenario_panel_controller == null:
		_mission_scenario_panel_controller = MAP_EDITOR_MISSION_SCENARIO_PANEL_SCRIPT.new()
		_mission_scenario_panel_controller.call("setup", self)
	return _mission_scenario_panel_controller


func _ensure_mission_authoring_controls() -> void:
	_ensure_mission_scenario_panel_controller().call("ensure_controls")


func _ensure_authoring_status_controls() -> void:
	var panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if panel_parent == null:
		return
	var status_panel := panel_parent.get_node_or_null("AuthoringStatusPanel") as VBoxContainer
	if status_panel == null:
		var separator := HSeparator.new()
		separator.name = "AuthoringStatusSeparator"
		panel_parent.add_child(separator)

		status_panel = VBoxContainer.new()
		status_panel.name = "AuthoringStatusPanel"
		status_panel.add_theme_constant_override("separation", 3)
		panel_parent.add_child(status_panel)

		var title_label := Label.new()
		title_label.name = "AuthoringStatusTitle"
		title_label.text = "Authoring Status"
		status_panel.add_child(title_label)

		for label_name in ["AuthoringToolStatusLabel", "AuthoringValidationLabel", "AuthoringManifestLabel"]:
			var status_label := Label.new()
			status_label.name = label_name
			status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			status_panel.add_child(status_label)

		var insert_index: int = panel_parent.get_node_or_null("MapSettingsSeparator").get_index() if panel_parent.get_node_or_null("MapSettingsSeparator") != null else 3
		panel_parent.move_child(separator, insert_index)
		panel_parent.move_child(status_panel, insert_index + 1)
	_refresh_authoring_status_controls()


func _refresh_authoring_status_controls() -> void:
	var status_panel := get_node_or_null("UI/PropertyPanel/Margin/VBox/AuthoringStatusPanel") as VBoxContainer
	if status_panel == null:
		return
	var snapshot: Dictionary = get_map_editor_usability_snapshot(false)
	var validation: Dictionary = Dictionary(snapshot.get("validation", {}))
	var manifest: Dictionary = Dictionary(snapshot.get("map_manifest", {}))
	var tool_label := status_panel.get_node_or_null("AuthoringToolStatusLabel") as Label
	var validation_label := status_panel.get_node_or_null("AuthoringValidationLabel") as Label
	var manifest_label := status_panel.get_node_or_null("AuthoringManifestLabel") as Label
	if tool_label != null:
		var selected_grid: Vector2i = Vector2i(snapshot.get("selected_grid", Vector2i(-1, -1)))
		var selected_text: String = "(%d,%d)" % [selected_grid.x, selected_grid.y] if selected_grid.x >= 0 and selected_grid.y >= 0 else "-"
		tool_label.text = "Tool: %s | Brush: %d | Tile: %s" % [
			_format_option_label(String(snapshot.get("active_tool", "select"))),
			int(snapshot.get("brush_radius", 0)),
			selected_text,
		]
		tool_label.tooltip_text = "Tool: current editing mode. Brush is the paint radius. Tile is the selected grid coordinate; '-' means no tile is selected."
	if validation_label != null:
		validation_label.text = "Check: %s | Errors: %d | Warnings: %d" % [
			"OK" if bool(validation.get("valid", false)) else "Needs attention",
			int(validation.get("error_count", 0)),
			int(validation.get("warning_count", 0)),
		]
		validation_label.tooltip_text = _build_authoring_validation_tooltip(validation)
	if manifest_label != null:
		manifest_label.text = "MP Map: %s" % String(manifest.get("state", "not_ready")).replace("_", " ")
		manifest_label.tooltip_text = "MP Map: multiplayer/mission-map readiness state derived from the current map manifest."


func _build_authoring_validation_tooltip(validation: Dictionary) -> String:
	var errors: Array = Array(validation.get("errors", []))
	var warnings: Array = Array(validation.get("warnings", []))
	var lines: Array[String] = [
		"Errors block a clean map export or playtest setup.",
		"Warnings are playable but should be reviewed before using the map as a mission source.",
	]
	if not errors.is_empty():
		lines.append("Errors:")
		lines.append_array(_format_validation_tooltip_lines(errors, 4))
	if not warnings.is_empty():
		lines.append("Warnings:")
		lines.append_array(_format_validation_tooltip_lines(warnings, 4))
	if errors.is_empty() and warnings.is_empty():
		lines.append("No current validation findings.")
	return "\n".join(lines)


func _format_validation_tooltip_lines(values: Array, max_items: int) -> Array[String]:
	var result: Array[String] = []
	var count: int = mini(values.size(), max_items)
	for index in range(count):
		result.append("- %s" % String(values[index]))
	if values.size() > max_items:
		result.append("- ... %d more" % int(values.size() - max_items))
	return result


func _ensure_inspector_section_controls() -> void:
	var panel_parent := get_node_or_null("UI/PropertyPanel/Margin/VBox") as VBoxContainer
	if panel_parent == null:
		return
	_ensure_inspector_toggle(panel_parent, "MapSettingsToggle", INSPECTOR_SECTION_MAP_SETTINGS, "Map Settings", "Grid and mission slot metadata")
	_ensure_inspector_toggle(panel_parent, "MarkersToggle", INSPECTOR_SECTION_MARKERS, "Markers", "Editor and mission marker authoring")
	_ensure_inspector_toggle(panel_parent, "MissionScenarioToggle", INSPECTOR_SECTION_MISSION_SCENARIO, "Mission Scenario", "Mission scenario authoring fields")
	_apply_inspector_section_visibility()


func _ensure_inspector_toggle(parent: VBoxContainer, node_name: String, section_id: String, title: String, tooltip: String) -> void:
	var button := parent.get_node_or_null(node_name) as Button
	if button == null:
		button = Button.new()
		button.name = node_name
		button.toggle_mode = true
		button.pressed.connect(_on_inspector_toggle_pressed.bind(section_id))
		parent.add_child(button)
	button.tooltip_text = _get_inspector_section_tooltip(section_id, tooltip)
	var anchor_node := _get_inspector_section_anchor(section_id)
	if anchor_node != null:
		parent.move_child(button, anchor_node.get_index())
	button.button_pressed = not bool(_inspector_section_collapsed.get(section_id, false))
	button.text = "%s %s" % ["v" if button.button_pressed else ">", title]


func _get_inspector_section_tooltip(section_id: String, fallback_text: String) -> String:
	match section_id:
		INSPECTOR_SECTION_MAP_SETTINGS:
			return "Map Settings: grid size, Map ID, terrain/object metadata and validation context for the current map file."
		INSPECTOR_SECTION_MARKERS:
			return "Markers: authoring points used by mission setup, AI spawns, objectives, rally points and editor-only notes."
		INSPECTOR_SECTION_MISSION_SCENARIO:
			return "Mission Scenario: optional mission-specific setup layered on top of this terrain map."
	return fallback_text


func _get_inspector_section_anchor(section_id: String) -> Node:
	match section_id:
		INSPECTOR_SECTION_MAP_SETTINGS:
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/MapSettingsSeparator")
		INSPECTOR_SECTION_MARKERS:
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkersTitle")
		INSPECTOR_SECTION_MISSION_SCENARIO:
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioSeparator")
	return null


func _on_inspector_toggle_pressed(section_id: String) -> void:
	set_inspector_section_collapsed(section_id, not bool(_inspector_section_collapsed.get(section_id, false)))


func set_inspector_section_collapsed(section_id: String, collapsed: bool) -> bool:
	var normalized_section_id: String = section_id.strip_edges().to_lower()
	if not [
		INSPECTOR_SECTION_MAP_SETTINGS,
		INSPECTOR_SECTION_MARKERS,
		INSPECTOR_SECTION_MISSION_SCENARIO,
	].has(normalized_section_id):
		return false
	_inspector_section_collapsed[normalized_section_id] = collapsed
	_apply_inspector_section_visibility()
	return true


func _apply_inspector_section_visibility() -> void:
	_set_nodes_visible(_get_map_settings_section_nodes(), _is_inspector_section_visible(INSPECTOR_SECTION_MAP_SETTINGS))
	_set_nodes_visible(_get_marker_section_nodes(), _is_inspector_section_visible(INSPECTOR_SECTION_MARKERS))
	_set_nodes_visible(_get_mission_scenario_section_nodes(), _is_inspector_section_visible(INSPECTOR_SECTION_MISSION_SCENARIO))
	_refresh_inspector_toggle_labels()


func _refresh_inspector_toggle_labels() -> void:
	var label_by_button: Dictionary = {
		"MapSettingsToggle": "Map Settings",
		"MarkersToggle": "Markers",
		"MissionScenarioToggle": "Mission Scenario",
	}
	var section_by_button: Dictionary = {
		"MapSettingsToggle": INSPECTOR_SECTION_MAP_SETTINGS,
		"MarkersToggle": INSPECTOR_SECTION_MARKERS,
		"MissionScenarioToggle": INSPECTOR_SECTION_MISSION_SCENARIO,
	}
	for button_name in label_by_button.keys():
		var button := get_node_or_null("UI/PropertyPanel/Margin/VBox/%s" % String(button_name)) as Button
		if button == null:
			continue
		var visible: bool = _is_inspector_section_visible(String(section_by_button.get(button_name, "")))
		button.button_pressed = visible
		button.text = "%s %s" % ["v" if visible else ">", String(label_by_button.get(button_name, button_name))]


func _is_inspector_section_visible(section_id: String) -> bool:
	return not bool(_inspector_section_collapsed.get(section_id, false))


func _set_nodes_visible(nodes: Array, is_visible: bool) -> void:
	for node_variant in nodes:
		var control := node_variant as Control
		if control != null:
			control.visible = is_visible


func _get_map_settings_section_nodes() -> Array:
	return [
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MapSettingsSeparator"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MapSettingsTitle"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MapNameRow"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/GridSizeLabel"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionSlotRow"),
	]


func _get_marker_section_nodes() -> Array:
	return [
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkersTitle"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerHelpLabel"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/SpawnAlphaRow"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/SpawnBravoRow"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectivePointRow"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel"),
	]


func _get_mission_scenario_section_nodes() -> Array:
	return [
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioSeparator"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioPanel"),
	]


func _tile_property_controls_are_visible() -> bool:
	var required_nodes: Array = [
		get_node_or_null("UI/PropertyPanel/Margin/VBox/TitleLabel"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/TileLabel"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/TypeLabel"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/TerrainTruthInspectorLabel"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/WalkableCheckBox"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/CoverRow"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/HeightRow"),
		get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectRotationRow"),
	]
	for node_variant in required_nodes:
		var control := node_variant as Control
		if control == null or not control.visible:
			return false
	return true


func _add_scenario_line_edit_row(parent: VBoxContainer, row_name: String, label_text: String, line_edit_name: String) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var line_edit := LineEdit.new()
	line_edit.name = line_edit_name
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(line_edit)


func _add_scenario_option_row(parent: VBoxContainer, row_name: String, label_text: String, option_name: String, button_name: String, button_text: String) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var option := OptionButton.new()
	option.name = option_name
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(option)
	var button := Button.new()
	button.name = button_name
	button.text = button_text
	row.add_child(button)


func _add_scenario_select_row(parent: VBoxContainer, row_name: String, label_text: String, option_name: String) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var option := OptionButton.new()
	option.name = option_name
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(option)


func _add_scenario_spinbox_row(parent: VBoxContainer, row_name: String, label_text: String, spinbox_name: String, min_value: float, max_value: float, step_value: float) -> void:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	row.add_child(label)
	var spinbox := SpinBox.new()
	spinbox.name = spinbox_name
	spinbox.min_value = min_value
	spinbox.max_value = max_value
	spinbox.step = step_value
	spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spinbox)


func _connect_mission_authoring_signals() -> void:
	_ensure_mission_scenario_panel_controller().call("connect_signals")


func _refresh_mission_authoring_controls() -> void:
	_ensure_mission_scenario_panel_controller().call("refresh")


func _ensure_mission_scenario():
	if _mission_scenario != null:
		return _mission_scenario
	_mission_scenario = _create_default_mission_scenario()
	_current_scenario_path = ""
	_scenario_dirty = false
	return _mission_scenario


func _create_default_mission_scenario():
	var map_path: String = _current_map_path if not _current_map_path.is_empty() else DEFAULT_MAP_PATH
	var scenario_id: String = "%s_scenario" % map_path.get_file().get_basename()
	var objective: Dictionary = {
		"capture_radius": 80.0,
	}
	if _terrain_map_data != null and bool(_terrain_map_data.call("has_marker", "objective_point")):
		objective["marker_id"] = "objective_point"
	else:
		objective["position"] = _get_selected_or_map_center_position(Vector2.ZERO)
	var enemy_ids: PackedStringArray = PackedStringArray(["enemy_delta", "enemy_echo"])
	var enemy_group: Dictionary = {
		"group_id": "red_test_group",
		"display_name": "Test Contacts",
		"team_id": "team_bravo",
		"enemy_ids": Array(enemy_ids),
		"tactics": ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_default_config_for_map_size", _get_current_grid_size()), _get_current_grid_size()),
	}
	if _terrain_map_data != null and bool(_terrain_map_data.call("has_marker", "spawn_bravo")):
		enemy_group["spawn_marker_id"] = "spawn_bravo"
	else:
		enemy_group["spawn_position"] = _get_selected_or_map_center_position(Vector2.ZERO)
	return MISSION_SCENARIO_DATA_SCRIPT.new(
		{
			"version": 1,
			"scenario_id": scenario_id,
			"display_name": scenario_id.capitalize(),
			"map_file_path": map_path,
			"time_limit_seconds": 900.0,
			"mission_slot_count_override": _get_current_map_mission_slot_count(),
			"objective": objective,
			"enemy_groups": [enemy_group],
			"wave_config": {
				"wave_count": 1,
				"units_per_wave": 2,
				"first_wave_delay_seconds": 0.0,
				"wave_delay_seconds": 90.0,
			},
			"patrol_bindings": _build_auto_patrol_bindings(enemy_ids),
			"briefing": {
				"title": scenario_id.capitalize(),
				"summary": "Fuehre das Fireteam in den Einsatz und sichere das Zielgebiet.",
				"minimap_mode": "terrain_only",
				"objectives": ["Zielgebiet sichern"],
				"threats": ["Feindkontakt im Einsatzgebiet"],
				"recommended_loadout": [
					{
						"label": "Ausgewogenes Fireteam",
						"weapon_ids": ["rifle", "sniper", "rocket_launcher", "medictool"],
						"reason": "Reichweite, Anti-Armor und Support fuer den ersten Kontakt.",
					},
				],
			},
			"notes": ["Created by the tactical mission editor MVP."],
		}
	)


func _refresh_scenario_marker_options() -> void:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return
	var objective: Dictionary = Dictionary(scenario.get("objective"))
	var objective_option := _get_scenario_option_button("ScenarioObjectiveOption")
	if objective_option != null:
		_populate_scenario_marker_option(
			objective_option,
			String(objective.get("marker_id", "")).strip_edges(),
			objective.has("position")
		)

	var spawn_option := _get_scenario_option_button("ScenarioSpawnOption")
	if spawn_option != null:
		var group: Dictionary = _get_primary_enemy_group()
		_populate_scenario_marker_option(
			spawn_option,
			String(group.get("spawn_marker_id", "")).strip_edges(),
			group.has("spawn_position")
		)


func _refresh_enemy_tactics_options() -> void:
	var group: Dictionary = _get_primary_enemy_group()
	var tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), _get_current_grid_size())
	_populate_string_option(
		_get_scenario_option_button("ScenarioEnemyTacticProfileOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_profile_ids"),
		String(tactics.get("profile_id", ""))
	)
	_populate_string_option(
		_get_scenario_option_button("ScenarioEnemySecurityModeOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_security_modes"),
		String(tactics.get("security_mode", ""))
	)
	_populate_string_option(
		_get_scenario_option_button("ScenarioEnemyFacingOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_facing_options"),
		String(tactics.get("facing", ""))
	)
	_populate_string_option(
		_get_scenario_option_button("ScenarioEnemyHeavyRoleOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_heavy_weapon_roles"),
		String(tactics.get("heavy_weapon_role", "none"))
	)
	_populate_optional_string_option(
		_get_scenario_option_button("ScenarioEnemyATWeaponOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_anti_armor_weapon_ids"),
		String(tactics.get("weapon_id", ""))
	)
	_populate_string_option(
		_get_scenario_option_button("ScenarioAirAssetRiskOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_air_asset_risk_profiles"),
		String(tactics.get("air_asset_risk_profile", Dictionary(_ensure_mission_scenario().call("get_air_asset_risk_config")).get("profile_id", "none")))
	)
	_populate_optional_marker_option(
		_get_scenario_option_button("ScenarioLZThreatZoneOption"),
		String(tactics.get("lz_threat_zone_id", Dictionary(_ensure_mission_scenario().call("get_air_asset_risk_config")).get("lz_threat_zone_id", "")))
	)
	_populate_string_option(
		_get_scenario_option_button("ScenarioCommIntensityOption"),
		ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("get_communication_intensities"),
		String(tactics.get("communication_intensity", Dictionary(_ensure_mission_scenario().call("get_tactical_authoring_config")).get("communication_intensity", "normal")))
	)


func _populate_string_option(option_button: OptionButton, values: PackedStringArray, selected_value: String) -> void:
	if option_button == null:
		return
	option_button.clear()
	var selected_index: int = -1
	var normalized_selected: String = selected_value.strip_edges().to_lower()
	for value_variant in values:
		var value: String = String(value_variant).strip_edges()
		if value.is_empty():
			continue
		option_button.add_item(_format_option_label(value))
		option_button.set_item_metadata(option_button.item_count - 1, value)
		if value == normalized_selected:
			selected_index = option_button.item_count - 1
	if selected_index < 0 and option_button.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		option_button.select(selected_index)


func _populate_optional_string_option(option_button: OptionButton, values: PackedStringArray, selected_value: String) -> void:
	if option_button == null:
		return
	var options: PackedStringArray = PackedStringArray(["none"])
	for value in values:
		if not options.has(String(value)):
			options.append(String(value))
	_populate_string_option(option_button, options, selected_value if not selected_value.strip_edges().is_empty() else "none")


func _populate_optional_marker_option(option_button: OptionButton, selected_marker_id: String) -> void:
	if option_button == null:
		return
	option_button.clear()
	option_button.add_item("None")
	option_button.set_item_metadata(0, "")
	var selected_index: int = 0
	if _terrain_map_data != null:
		for marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
			var marker_text: String = String(marker_id)
			option_button.add_item(marker_text)
			option_button.set_item_metadata(option_button.item_count - 1, marker_text)
			if marker_text == selected_marker_id:
				selected_index = option_button.item_count - 1
	if not selected_marker_id.is_empty() and selected_index == 0:
		option_button.add_item(selected_marker_id)
		option_button.set_item_metadata(option_button.item_count - 1, selected_marker_id)
		selected_index = option_button.item_count - 1
	option_button.select(selected_index)


func _format_option_label(value: String) -> String:
	var normalized_value: String = value.strip_edges()
	if normalized_value.is_empty():
		return ""
	return normalized_value.replace("_", " ").capitalize()


func _populate_scenario_marker_option(option_button: OptionButton, selected_marker_id: String, use_position: bool) -> void:
	var previous_selection: String = selected_marker_id
	if use_position:
		previous_selection = SCENARIO_POSITION_META
	option_button.clear()
	var selected_index: int = -1
	if _terrain_map_data != null:
		for marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
			var marker_text: String = String(marker_id)
			option_button.add_item(marker_text)
			option_button.set_item_metadata(option_button.item_count - 1, marker_text)
			if marker_text == previous_selection:
				selected_index = option_button.item_count - 1
	if not selected_marker_id.is_empty() and selected_index < 0:
		option_button.add_item(selected_marker_id)
		option_button.set_item_metadata(option_button.item_count - 1, selected_marker_id)
		selected_index = option_button.item_count - 1
	option_button.add_item("Position")
	option_button.set_item_metadata(option_button.item_count - 1, SCENARIO_POSITION_META)
	if previous_selection == SCENARIO_POSITION_META:
		selected_index = option_button.item_count - 1
	if selected_index < 0 and option_button.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		option_button.select(selected_index)


func _sync_mission_scenario_from_controls() -> void:
	_ensure_mission_scenario_panel_controller().call("sync_from_controls")


func _apply_tactical_authoring_from_controls(scenario, group: Dictionary) -> void:
	if scenario == null:
		return
	var tactical_authoring: Dictionary = Dictionary(scenario.call("get_tactical_authoring_config")).duplicate(true)
	var tactics: Dictionary = Dictionary(group.get("tactics", {}))
	var risk: Dictionary = Dictionary(tactical_authoring.get("air_asset_risk", {})).duplicate(true)
	risk["profile_id"] = String(tactics.get("air_asset_risk_profile", risk.get("profile_id", "none"))).strip_edges().to_lower()
	risk["enemy_group_id"] = String(group.get("group_id", risk.get("enemy_group_id", ""))).strip_edges()
	risk["lz_threat_zone_id"] = String(tactics.get("lz_threat_zone_id", risk.get("lz_threat_zone_id", ""))).strip_edges()
	risk["warning_required_before_damage"] = bool(risk.get("warning_required_before_damage", true))
	tactical_authoring["air_asset_risk"] = risk
	tactical_authoring["communication_intensity"] = String(tactics.get("communication_intensity", tactical_authoring.get("communication_intensity", "normal"))).strip_edges().to_lower()
	scenario.set("tactical_authoring", tactical_authoring)


func _get_primary_enemy_group() -> Dictionary:
	if _mission_scenario == null:
		return {}
	var groups: Array = Array(_mission_scenario.get("enemy_groups"))
	if groups.is_empty():
		return {}
	return Dictionary(groups[0])


func _get_current_map_mission_slot_count() -> int:
	if _terrain_map_data == null or not _terrain_map_data.has_method("get_mission_slot_count"):
		return -1
	return int(_terrain_map_data.call("get_mission_slot_count"))


func _get_current_grid_size() -> Vector2i:
	if _terrain_map_data != null and _terrain_map_data.has_method("get_grid_size"):
		return _terrain_map_data.call("get_grid_size")
	return DEFAULT_NEW_MAP_GRID_SIZE


func _build_default_scenario_id() -> String:
	var map_basename: String = _current_map_path.get_file().get_basename() if not _current_map_path.is_empty() else "mission"
	return "%s_scenario" % map_basename


func _get_selected_option_metadata(option_name: String) -> String:
	var option_button := _get_scenario_option_button(option_name)
	if option_button == null or option_button.selected < 0 or option_button.selected >= option_button.item_count:
		return ""
	return String(option_button.get_item_metadata(option_button.selected)).strip_edges()


func _get_selected_or_existing_position(container: Dictionary, fallback_position: Vector2, key: String = "position") -> Vector2:
	if container.has(key):
		return _coerce_vector2(container.get(key, fallback_position), fallback_position)
	return fallback_position


func _get_selected_or_map_center_position(fallback_position: Vector2) -> Vector2:
	var selected_tile = _get_selected_tile()
	if selected_tile != null:
		return selected_tile.world_position
	if _terrain_map_data != null and _terrain_registry != null:
		var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
		if grid_size.x > 0 and grid_size.y > 0:
			return _terrain_registry.grid_to_world(Vector2i(floori(float(grid_size.x) * 0.5), floori(float(grid_size.y) * 0.5)))
	return fallback_position


func _get_required_selected_tile_world_position(feedback_text: String):
	var selected_tile = _get_selected_tile()
	if selected_tile != null:
		return Vector2(selected_tile.world_position)
	_scenario_feedback_text = feedback_text
	_refresh_mission_authoring_controls()
	return null


func _build_auto_patrol_bindings(enemy_ids: PackedStringArray) -> Array:
	var result: Array = []
	if _terrain_map_data == null or not _terrain_map_data.has_method("get_patrol_paths"):
		return result
	var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
	for enemy_id in enemy_ids:
		var normalized_enemy_id: String = String(enemy_id).strip_edges()
		if normalized_enemy_id.is_empty() or not patrol_paths.has(normalized_enemy_id):
			continue
		result.append(
			{
				"binding_id": "%s_patrol" % normalized_enemy_id,
				"target_id": normalized_enemy_id,
				"patrol_path_id": normalized_enemy_id,
				"mode": "pre_contact",
			}
		)
	return result


func _parse_string_list(text: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for raw_item in text.split(",", false):
		var item: String = String(raw_item).strip_edges()
		if not item.is_empty() and not result.has(item):
			result.append(item)
	return result


func _format_patrol_bindings_text(patrol_bindings: Array) -> String:
	var entries: PackedStringArray = PackedStringArray()
	for binding_variant in patrol_bindings:
		var binding: Dictionary = Dictionary(binding_variant)
		var target_id: String = String(binding.get("target_id", "")).strip_edges()
		var patrol_path_id: String = String(binding.get("patrol_path_id", "")).strip_edges()
		if target_id.is_empty() or patrol_path_id.is_empty():
			continue
		entries.append("%s:%s" % [target_id, patrol_path_id])
	return ", ".join(entries)


func _parse_patrol_bindings_text(text: String) -> Array:
	var result: Array = []
	for raw_entry in text.split(",", false):
		var entry: String = String(raw_entry).strip_edges()
		if entry.is_empty():
			continue
		var parts: PackedStringArray = entry.split(":", false)
		var target_id: String = String(parts[0]).strip_edges()
		var patrol_path_id: String = String(parts[1]).strip_edges() if parts.size() > 1 else target_id
		if target_id.is_empty() or patrol_path_id.is_empty():
			continue
		result.append(
			{
				"binding_id": "%s_patrol" % target_id,
				"target_id": target_id,
				"patrol_path_id": patrol_path_id,
				"mode": "pre_contact",
			}
		)
	return result


func _build_mission_scenario_info_text() -> String:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return ""
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	var base_text: String = _scenario_feedback_text
	if bool(validation.get("valid", false)):
		if base_text.is_empty():
			base_text = "Scenario valid."
	else:
		var errors: PackedStringArray = PackedStringArray(validation.get("errors", PackedStringArray()))
		var error_text: String = "; ".join(errors)
		base_text = "%s%s" % [base_text + "\n" if not base_text.is_empty() else "", error_text]
	return base_text


func _mark_scenario_dirty(is_dirty: bool) -> void:
	_scenario_dirty = is_dirty
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_TOOL_STATE)
	var panel := _get_mission_scenario_panel()
	if panel == null:
		return
	var path_label := panel.get_node_or_null("ScenarioPathLabel") as Label
	if path_label != null:
		path_label.text = "Scenario: %s%s" % [_current_scenario_path if not _current_scenario_path.is_empty() else "(new)", " *" if _scenario_dirty else ""]


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


func load_mission_scenario_for_editor(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty():
		return false
	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", normalized_path)
	if scenario == null:
		return false
	_mission_scenario = scenario
	_current_scenario_path = normalized_path
	_scenario_feedback_text = "Scenario loaded."
	_mark_scenario_dirty(false)
	var scenario_map_path: String = String(scenario.get("map_file_path")).strip_edges()
	if not scenario_map_path.is_empty() and FileAccess.file_exists(scenario_map_path) and scenario_map_path != _current_map_path:
		_load_map(scenario_map_path)
	else:
		_refresh_mission_authoring_controls()
	return true


func save_mission_scenario_from_editor(path: String = "") -> Error:
	_sync_mission_scenario_from_controls()
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return ERR_CANT_CREATE
	var save_path: String = path.strip_edges()
	if save_path.is_empty():
		save_path = _current_scenario_path
	if save_path.is_empty():
		save_path = DEFAULT_SCENARIO_PATH
	scenario.set("map_file_path", _current_map_path if not _current_map_path.is_empty() else DEFAULT_MAP_PATH)
	var save_error: Error = scenario.call("save_to_file", save_path)
	if save_error != OK:
		_scenario_feedback_text = "Scenario could not be saved: %s" % save_path
		_refresh_mission_authoring_controls()
		return save_error
	_current_scenario_path = save_path
	_scenario_feedback_text = "Scenario saved."
	_mark_scenario_dirty(false)
	_refresh_mission_authoring_controls()
	return OK


func set_mission_scenario_authoring_fields(data: Dictionary) -> void:
	var base_data: Dictionary = Dictionary(_ensure_mission_scenario().call("to_dict"))
	for key_variant in data.keys():
		base_data[key_variant] = data.get(key_variant)
	if not base_data.has("map_file_path") or String(base_data.get("map_file_path", "")).strip_edges().is_empty():
		base_data["map_file_path"] = _current_map_path if not _current_map_path.is_empty() else DEFAULT_MAP_PATH
	_mission_scenario = MISSION_SCENARIO_DATA_SCRIPT.new(base_data)
	_scenario_feedback_text = "Scenario fields updated."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func set_enemy_tactics_authoring_fields(data: Dictionary) -> void:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return
	var groups: Array = Array(scenario.get("enemy_groups")).duplicate(true)
	var group: Dictionary = _get_primary_enemy_group().duplicate(true)
	if group.is_empty():
		group = {
			"group_id": "red_test_group",
			"display_name": "Test Contacts",
			"team_id": "team_bravo",
			"enemy_ids": ["enemy_delta", "enemy_echo"],
		}
	group["tactics"] = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", data, _get_current_grid_size())
	if groups.is_empty():
		groups.append(group)
	else:
		groups[0] = group
	scenario.set("enemy_groups", groups)
	_scenario_feedback_text = "Enemy tactics updated."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func set_tactical_profile_authoring_fields(data: Dictionary) -> void:
	set_enemy_tactics_authoring_fields(data)
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return
	var tactical_authoring: Dictionary = Dictionary(scenario.call("get_tactical_authoring_config")).duplicate(true)
	if data.has("communication_intensity"):
		tactical_authoring["communication_intensity"] = String(data.get("communication_intensity", "normal")).strip_edges().to_lower()
	var risk: Dictionary = Dictionary(tactical_authoring.get("air_asset_risk", {})).duplicate(true)
	if data.has("air_asset_risk_profile"):
		risk["profile_id"] = String(data.get("air_asset_risk_profile", "none")).strip_edges().to_lower()
	if data.has("lz_threat_zone_id"):
		risk["lz_threat_zone_id"] = String(data.get("lz_threat_zone_id", "")).strip_edges()
	if data.has("enemy_group_id"):
		risk["enemy_group_id"] = String(data.get("enemy_group_id", "")).strip_edges()
	tactical_authoring["air_asset_risk"] = risk
	scenario.set("tactical_authoring", tactical_authoring)
	_scenario_feedback_text = "Tactical profile updated."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func set_mission_briefing_authoring_fields(data: Dictionary) -> void:
	var base_data: Dictionary = Dictionary(_ensure_mission_scenario().call("to_dict"))
	base_data["briefing"] = data.duplicate(true)
	_mission_scenario = MISSION_SCENARIO_DATA_SCRIPT.new(base_data)
	_scenario_feedback_text = "Mission briefing updated."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func get_enemy_tactics_authoring_snapshot() -> Dictionary:
	_ensure_mission_scenario()
	var group: Dictionary = _get_primary_enemy_group()
	return ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), _get_current_grid_size())


func get_tactical_profile_authoring_snapshot() -> Dictionary:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return {}
	var group: Dictionary = _get_primary_enemy_group()
	var tactics: Dictionary = ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("normalize_config", group.get("tactics", {}), _get_current_grid_size())
	var tactical_authoring: Dictionary = Dictionary(scenario.call("get_tactical_authoring_config")).duplicate(true)
	return {
		"group_id": String(group.get("group_id", "")),
		"profile_id": String(tactics.get("profile_id", "")),
		"security_mode": String(tactics.get("security_mode", "")),
		"facing": String(tactics.get("facing", "")),
		"heavy_weapon_role": String(tactics.get("heavy_weapon_role", "none")),
		"weapon_id": String(tactics.get("weapon_id", "")),
		"anti_armor_threat": bool(tactics.get("anti_armor_threat", false)),
		"air_asset_risk_profile": String(tactics.get("air_asset_risk_profile", Dictionary(tactical_authoring.get("air_asset_risk", {})).get("profile_id", "none"))),
		"lz_threat_zone_id": String(tactics.get("lz_threat_zone_id", Dictionary(tactical_authoring.get("air_asset_risk", {})).get("lz_threat_zone_id", ""))),
		"communication_intensity": String(tactics.get("communication_intensity", tactical_authoring.get("communication_intensity", "normal"))),
		"tactical_authoring": tactical_authoring,
		"help_id": "map_editor.tactical_profile",
		"ui_sets_gameplay_truth": false,
	}


func get_mission_briefing_authoring_snapshot() -> Dictionary:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return {}
	return Dictionary(scenario.call("get_briefing")).duplicate(true)


func get_current_mission_scenario_dict() -> Dictionary:
	_sync_mission_scenario_from_controls()
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return {}
	return Dictionary(scenario.call("to_dict")).duplicate(true)


func create_live_test_scene_from_current_scenario():
	var save_path: String = _current_scenario_path if not _current_scenario_path.is_empty() else LIVE_TEST_SCENARIO_SCRATCH_PATH
	var save_error: Error = save_mission_scenario_from_editor(save_path)
	if save_error != OK:
		return null
	var packed_scene: PackedScene = load(LIVE_TEST_SCENE_PATH)
	if packed_scene == null:
		_scenario_feedback_text = "Live test scene missing."
		_refresh_mission_authoring_controls()
		return null
	var scene := packed_scene.instantiate()
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("scenario_file_path", save_path)
	return scene


func set_authoring_tool(tool_id: String) -> bool:
	var normalized_tool_id: String = tool_id.strip_edges().to_lower()
	if normalized_tool_id.is_empty():
		normalized_tool_id = "select"
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	var height_button := _get_height_tool_button()
	var eraser_button := _get_eraser_tool_button()
	var marker_button := _get_marker_tool_button()
	var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
	var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
	if not ["select", "selection", "terrain_brush", "brush", "eraser", "erase", "height", "marker", "patrol", "network", "network_drag"].has(normalized_tool_id):
		return false

	_selection_tool_enabled = normalized_tool_id == AUTHORING_TOOL_SELECT or normalized_tool_id == "selection"
	_eraser_tool_enabled = normalized_tool_id == AUTHORING_TOOL_ERASER or normalized_tool_id == "erase"
	_height_tool_enabled = normalized_tool_id == AUTHORING_TOOL_HEIGHT
	_marker_tool_enabled = normalized_tool_id == AUTHORING_TOOL_MARKER
	_patrol_tool_enabled = normalized_tool_id == AUTHORING_TOOL_PATROL
	_network_drag_tool_enabled = normalized_tool_id == AUTHORING_TOOL_NETWORK_DRAG or normalized_tool_id == "network"
	if not _network_drag_tool_enabled:
		_clear_network_drag_preview()
	if brush_button != null:
		brush_button.button_pressed = normalized_tool_id == AUTHORING_TOOL_BRUSH or normalized_tool_id == "brush"
	if eraser_button != null:
		eraser_button.button_pressed = _eraser_tool_enabled
	if height_button != null:
		height_button.button_pressed = _height_tool_enabled
	if marker_button != null:
		marker_button.button_pressed = _marker_tool_enabled
	if patrol_button != null:
		patrol_button.button_pressed = _patrol_tool_enabled
	if select_button != null:
		select_button.button_pressed = _selection_tool_enabled
	_is_painting = false
	_last_painted_grid = Vector2i(-1, -1)
	if _patrol_tool_enabled:
		preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	else:
		_clear_patrol_route_preview(true)
	_update_height_topbar_state()
	_update_patrol_topbar_state()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()
	return true


func select_grid_for_authoring(grid_position: Vector2i) -> bool:
	if _terrain_map_data == null:
		return false
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return false
	_set_selected_grid_position(grid_position)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE)
	return true


func get_map_editor_usability_snapshot(sync_from_controls: bool = true) -> Dictionary:
	if sync_from_controls and not _is_refreshing_scenario_controls:
		_sync_mission_scenario_from_controls()
	var selected_tile_context: Dictionary = _build_selected_tile_context()
	var validation: Dictionary = get_authoring_validation_snapshot(false)
	var manifest_preview: Dictionary = build_multiplayer_map_manifest_preview()
	return {
		"active_tool": _get_active_authoring_tool(),
		"brush_radius": _get_brush_radius(),
		"brush_footprint_tiles": _get_brush_footprint_tile_count(),
		"selected_grid": _selected_grid_position,
		"hover_grid": _hover_grid_position,
		"selected_type_id": _selected_type_id,
		"selected_tile": selected_tile_context,
		"height_tool": {
			"enabled": _height_tool_enabled,
			"mode": _height_tool_mode,
			"edge_type": _height_tool_edge_type,
		},
		"marker_tool": {
			"enabled": _marker_tool_enabled,
			"selected_marker_id": _selected_marker_id,
			"feedback": _marker_feedback_text,
		},
		"patrol_tool": {
			"enabled": _patrol_tool_enabled,
			"spawn_id": _patrol_spawn_id,
			"waypoint_count": _get_patrol_waypoint_count(_patrol_spawn_id),
		},
		"network_drag_tool": _build_network_drag_tool_snapshot(),
		"station_door_authoring": _build_station_door_authoring_snapshot(),
		"patrol_route_preview": get_patrol_route_preview_snapshot(),
		"tile_property_overlay": get_tile_property_overlay_debug_snapshot(),
		"adjacency_debug_overlay": get_adjacency_debug_overlay_snapshot(),
		"eraser_tool": {
			"enabled": _eraser_tool_enabled,
			"scope": "object_layer_only",
		},
		"runtime_builder_workbench": _build_runtime_builder_workbench_snapshot(),
		"toolbar": _build_toolbar_snapshot(),
		"palette": _build_palette_snapshot(),
		"context_menu": _build_context_menu_snapshot(),
		"inspector": _build_inspector_snapshot(),
		"map_name": _get_current_map_name(),
		"map_path": _current_map_path,
		"save_as_suggested_file": _build_suggested_map_filename(),
		"save_routes_to_save_as": _should_route_save_to_save_as(),
		"scenario_path": _current_scenario_path,
		"dirty": _dirty,
		"scenario_dirty": _scenario_dirty,
		"validation": validation,
		"live_test": _build_live_test_readiness(validation),
		"map_manifest": manifest_preview,
		"action_contract": get_authoring_action_contract_snapshot(),
	}


func get_authoring_validation_snapshot(sync_from_controls: bool = true) -> Dictionary:
	if sync_from_controls and not _is_refreshing_scenario_controls:
		_sync_mission_scenario_from_controls()
	var errors: Array = []
	var warnings: Array = []
	var sections: Dictionary = {}
	sections["map"] = _validate_authoring_map(errors, warnings)
	sections["markers"] = _validate_authoring_markers(errors, warnings)
	sections["patrols"] = _validate_authoring_patrols(errors, warnings)
	sections["hills"] = _validate_authoring_hills(errors, warnings)
	sections["walkability"] = _validate_authoring_walkability(errors, warnings)
	sections["fow"] = _build_fow_authoring_diagnostics()
	sections["scenario"] = _validate_authoring_scenario(errors, warnings)
	sections["multiplayer"] = build_multiplayer_map_manifest_preview()
	return {
		"valid": errors.is_empty(),
		"errors": PackedStringArray(errors),
		"warnings": PackedStringArray(warnings),
		"error_count": errors.size(),
		"warning_count": warnings.size(),
		"sections": sections,
	}


func _build_toolbar_snapshot() -> Dictionary:
	var tool_ids: PackedStringArray = PackedStringArray([
		AUTHORING_TOOL_SELECT,
		AUTHORING_TOOL_BRUSH,
		AUTHORING_TOOL_ERASER,
		AUTHORING_TOOL_HEIGHT,
		AUTHORING_TOOL_MARKER,
		AUTHORING_TOOL_PATROL,
		AUTHORING_TOOL_NETWORK_DRAG,
	])
	var pressed: Dictionary = {
		AUTHORING_TOOL_SELECT: _selection_tool_enabled,
		AUTHORING_TOOL_BRUSH: _is_brush_enabled(),
		AUTHORING_TOOL_ERASER: _eraser_tool_enabled,
		AUTHORING_TOOL_HEIGHT: _height_tool_enabled,
		AUTHORING_TOOL_MARKER: _marker_tool_enabled,
		AUTHORING_TOOL_PATROL: _patrol_tool_enabled,
		AUTHORING_TOOL_NETWORK_DRAG: _network_drag_tool_enabled,
	}
	var active_count: int = 0
	for tool_id in tool_ids:
		if bool(pressed.get(tool_id, false)):
			active_count += 1
	return {
		"tool_ids": tool_ids,
		"pressed": pressed,
		"active_tool": _get_active_authoring_tool(),
		"active_count": active_count,
		"exclusive": active_count <= 1,
		"eraser_scope": "object_layer_only",
	}


func _build_palette_snapshot() -> Dictionary:
	var visible_type_ids: PackedStringArray = PackedStringArray()
	var visible_display_names: PackedStringArray = PackedStringArray()
	var selected_items: PackedInt32Array = PackedInt32Array()
	var preview_icon_count: int = 0
	var catalog_preview_icon_count: int = 0
	var generated_preview_icon_count: int = 0
	var asset_list_icon_mode: int = -1
	var asset_list_max_columns: int = 0
	var asset_list_fixed_column_width: int = 0
	var asset_list_min_size: Vector2 = Vector2.ZERO
	var tile_type_list := _get_tile_type_list()
	if tile_type_list != null:
		asset_list_icon_mode = int(tile_type_list.icon_mode)
		asset_list_max_columns = int(tile_type_list.max_columns)
		asset_list_fixed_column_width = int(tile_type_list.fixed_column_width)
		asset_list_min_size = tile_type_list.custom_minimum_size
		selected_items = tile_type_list.get_selected_items()
		for index in range(tile_type_list.item_count):
			var type_id: String = String(tile_type_list.get_item_metadata(index)).strip_edges()
			if not type_id.is_empty() and not type_id.begins_with("__group:"):
				visible_type_ids.append(type_id)
				visible_display_names.append(tile_type_list.get_item_text(index))
			if tile_type_list.get_item_icon(index) != null:
				preview_icon_count += 1
				var preview_source: String = String(_palette_preview_sources.get(type_id, "")).strip_edges().to_lower()
				if preview_source == "catalog":
					catalog_preview_icon_count += 1
				elif preview_source == "generated":
					generated_preview_icon_count += 1
	var group_ids: PackedStringArray = PackedStringArray()
	if _tile_catalog != null:
		for group_variant in _tile_catalog.get_palette_groups():
			var group: Dictionary = Dictionary(group_variant)
			group_ids.append(String(group.get("group_id", "")))
	var palette_panel := get_node_or_null("UI/PalettePanel") as Control
	var group_scroll := _get_palette_groups_scroll()
	var palette_groups_root := _get_palette_groups_root()
	var group_button_count: int = 0
	var group_button_max_height: float = 0.0
	if palette_groups_root != null:
		for child in palette_groups_root.get_children():
			var child_control := child as Control
			if child_control == null:
				continue
			group_button_count += 1
			group_button_max_height = maxf(group_button_max_height, child_control.custom_minimum_size.y)
	var selected_preview_rect := _get_palette_selected_preview_texture_rect()
	var scale_presets: PackedFloat32Array = PackedFloat32Array()
	for preset_variant in PALETTE_SCALE_PRESETS:
		scale_presets.append(float(preset_variant))
	return {
		"active_group": _active_palette_group_id,
		"group_ids": group_ids,
		"visible_type_ids": visible_type_ids,
		"visible_display_names": visible_display_names,
		"visible_count": visible_type_ids.size(),
		"selected_type_id": _selected_type_id,
		"selected_display_name": _get_palette_type_display_name(_selected_type_id),
		"selected_palette_group": _get_palette_group_for_type(_selected_type_id),
		"selected_type_visible": visible_type_ids.has(_selected_type_id),
		"selected_item_count": selected_items.size(),
		"selected_item_index": int(selected_items[0]) if selected_items.size() > 0 else -1,
		"filtered": not _active_palette_group_id.is_empty() or not _palette_search_query.is_empty() or _palette_favorites_filter_enabled,
		"search_query": _palette_search_query,
		"search_active": not _palette_search_query.is_empty(),
		"favorites_filter_enabled": _palette_favorites_filter_enabled,
		"favorite_type_ids": _palette_favorite_type_ids.duplicate(),
		"favorite_count": _palette_favorite_type_ids.size(),
		"recent_type_ids": _palette_recent_type_ids.duplicate(),
		"recent_count": _palette_recent_type_ids.size(),
		"selected_is_favorite": _palette_type_is_favorite(_selected_type_id),
		"preview_icon_count": preview_icon_count,
		"catalog_preview_icon_count": catalog_preview_icon_count,
		"generated_preview_icon_count": generated_preview_icon_count,
		"visible_types_use_catalog_previews": tile_type_list != null and preview_icon_count == tile_type_list.item_count and catalog_preview_icon_count == preview_icon_count and generated_preview_icon_count == 0,
		"all_visible_items_have_preview_icons": tile_type_list != null and preview_icon_count == tile_type_list.item_count,
		"preview_icon_size": PALETTE_PREVIEW_ICON_SIZE,
		"panel_min_width": palette_panel.custom_minimum_size.x if palette_panel != null else 0.0,
		"group_scrollable": group_scroll != null and int(group_scroll.vertical_scroll_mode) != int(ScrollContainer.SCROLL_MODE_DISABLED),
		"group_scroll_min_height": group_scroll.custom_minimum_size.y if group_scroll != null else 0.0,
		"group_columns": PALETTE_GROUP_COLUMNS,
		"group_button_count": group_button_count,
		"group_button_max_height": group_button_max_height,
		"asset_list_icon_mode": asset_list_icon_mode,
		"asset_list_max_columns": asset_list_max_columns,
		"asset_list_fixed_column_width": asset_list_fixed_column_width,
		"asset_list_min_size": asset_list_min_size,
		"selected_preview_size": selected_preview_rect.custom_minimum_size if selected_preview_rect != null else Vector2.ZERO,
		"placement_scale": _placement_object_scale,
		"scale_presets": scale_presets,
		"scale_min": OBJECT_SCALE_MIN,
		"scale_max": OBJECT_SCALE_MAX,
		"preferences_persistent": true,
		"preferences_schema": PALETTE_AUTHORING_PREFERENCES_SCHEMA,
		"preferences_path": _get_palette_authoring_preferences_path(),
		"preferences_file_exists": FileAccess.file_exists(_get_palette_authoring_preferences_path()),
		"preferences_loaded": _palette_preferences_loaded,
		"preferences_saved": _palette_preferences_saved,
		"preferences_load_count": _palette_preferences_load_count,
		"preferences_save_count": _palette_preferences_save_count,
		"preferences_last_error": _palette_preferences_last_error,
		"ui_sets_gameplay_truth": false,
	}


func _build_context_menu_snapshot() -> Dictionary:
	var menu := _ensure_editor_context_menu()
	return {
		"activation": "right_mouse_release",
		"drag_threshold_px": RIGHT_CONTEXT_DRAG_THRESHOLD_PX,
		"area_selection_uses_right_drag": true,
		"visible": menu != null and menu.visible,
		"selected_tile_erasable": _selected_tile_has_erasable_object(),
		"selected_tile_rotatable": _tile_has_rotatable_object(_get_selected_tile()),
	}


func _build_inspector_snapshot() -> Dictionary:
	var property_scroll := get_node_or_null("UI/PropertyPanel/Margin") as ScrollContainer
	return {
		"tile_properties_visible": _tile_property_controls_are_visible(),
		"property_panel_scrollable": property_scroll != null,
		"property_panel_vertical_scroll_enabled": property_scroll != null and int(property_scroll.vertical_scroll_mode) != int(ScrollContainer.SCROLL_MODE_DISABLED),
		"sections": _inspector_section_collapsed.duplicate(true),
		"map_settings_visible": _is_inspector_section_visible(INSPECTOR_SECTION_MAP_SETTINGS),
		"markers_visible": _is_inspector_section_visible(INSPECTOR_SECTION_MARKERS),
		"mission_scenario_visible": _is_inspector_section_visible(INSPECTOR_SECTION_MISSION_SCENARIO),
		"terrain_truth_visible": get_node_or_null("UI/PropertyPanel/Margin/VBox/TerrainTruthInspectorLabel") != null,
		"selected_tile_terrain_truth": get_selected_tile_truth_debug_snapshot(),
	}


func build_multiplayer_map_manifest_preview(author: String = "") -> Dictionary:
	var result: Dictionary = {
		"ready": false,
		"state": "not_ready",
		"errors": PackedStringArray(),
	}
	if _terrain_map_data == null:
		result["state"] = "map_not_loaded"
		result["errors"] = PackedStringArray(["map_not_loaded"])
		return result
	if _current_map_path.strip_edges().is_empty() or not FileAccess.file_exists(_current_map_path):
		result["state"] = "map_needs_save"
		result["errors"] = PackedStringArray(["map_needs_save"])
		return result
	if _dirty:
		result["state"] = "map_has_unsaved_changes"
		result["errors"] = PackedStringArray(["map_has_unsaved_changes"])
		return result
	var manifest: Dictionary = MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", _current_map_path, _current_scenario_path, author)
	if not bool(manifest.get("valid", false)):
		result["state"] = "manifest_invalid"
		result["errors"] = PackedStringArray(manifest.get("errors", PackedStringArray()))
		result["manifest"] = manifest
		return result
	result["ready"] = true
	result["state"] = "manifest_ready"
	result["manifest"] = MULTIPLAYER_MAP_MANIFEST_SCRIPT.call("normalize_manifest", manifest)
	return result


func get_authoring_action_contract_snapshot() -> Dictionary:
	return {
		"undo_redo_scope": "tile_transaction_stack_v3",
		"undo_transactional": true,
		"undo_available": not _undo_stack.is_empty(),
		"undo_depth": _undo_stack.size(),
		"undo_limit": MAX_UNDO_STACK_SIZE,
		"active_undo_transaction": not _active_undo_transaction.is_empty(),
		"redo_available": false,
		"editor_ui_refresh_batched": true,
		"editor_ui_refresh_flags": _get_editor_ui_refresh_flag_names(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE | EDITOR_UI_REFRESH_HOVER | EDITOR_UI_REFRESH_SCENARIO | EDITOR_UI_REFRESH_PATROL_PREVIEW),
		"patrol_route_preview_visual_only": true,
		"tile_property_overlay_visual_only": true,
		"adjacency_debug_overlay_visual_only": true,
		"tile_patch_fields": PackedStringArray([
			"grid_position",
			"walkable",
			"blocks_los",
			"cover_value",
			"height_level",
			"object_height",
			"surface_type",
			"edge_type",
			"type_id",
			"object_type_id",
			"object_rotation_degrees",
			"object_scale",
		]),
		"tool_action_fields": PackedStringArray([
			"tool_id",
			"brush_radius",
			"affected_grids",
			"before_tiles",
			"after_tiles",
		]),
	}


func _get_active_authoring_tool() -> String:
	if _network_drag_tool_enabled:
		return AUTHORING_TOOL_NETWORK_DRAG
	if _height_tool_enabled:
		return AUTHORING_TOOL_HEIGHT
	if _marker_tool_enabled:
		return AUTHORING_TOOL_MARKER
	if _patrol_tool_enabled:
		return AUTHORING_TOOL_PATROL
	if _eraser_tool_enabled:
		return AUTHORING_TOOL_ERASER
	if _selection_tool_enabled:
		return AUTHORING_TOOL_SELECT
	if _is_brush_enabled():
		return AUTHORING_TOOL_BRUSH
	return AUTHORING_TOOL_SELECT


func _get_brush_footprint_tile_count() -> int:
	var radius: int = _get_brush_radius()
	return (radius * 2 + 1) * (radius * 2 + 1)


func _get_patrol_waypoint_count(spawn_id: String) -> int:
	if _terrain_map_data == null:
		return 0
	return Array(_terrain_map_data.call("get_patrol_path", _resolve_patrol_edit_path_id(spawn_id))).size()


func _build_selected_tile_context() -> Dictionary:
	var tile_data = _get_selected_tile()
	if tile_data == null:
		return {
			"has_tile": false,
			"grid_position": Vector2i(-1, -1),
		}
	return {
		"has_tile": true,
		"grid_position": tile_data.grid_position,
		"type_id": String(tile_data.type_id),
		"object_type_id": String(tile_data.object_type_id),
		"layer_stack": _build_tile_layer_stack_info(tile_data),
		"walkable": bool(tile_data.walkable),
		"blocks_los": bool(tile_data.blocks_los),
		"cover_value": int(tile_data.cover_value),
		"height_level": int(tile_data.height_level),
		"object_height": int(tile_data.object_height),
		"object_rotation_degrees": _get_tile_object_rotation_degrees(tile_data),
		"object_rotatable": _tile_has_rotatable_object(tile_data),
		"object_scale": _get_tile_object_scale(tile_data),
		"object_scalable": _tile_has_scalable_object(tile_data),
		"surface_type": String(tile_data.surface_type),
		"edge_type": String(tile_data.edge_type),
	}


func _build_tile_layer_stack_info(tile_data) -> Dictionary:
	if tile_data == null:
		return {
			"terrain_layer": "",
			"structure_layer": "",
			"object_layer": "",
			"supports_object_on_structure": false,
			"help_text": "Kein Tile ausgewaehlt.",
		}
	var type_id: String = String(tile_data.type_id).strip_edges()
	var object_type_id: String = String(tile_data.object_type_id).strip_edges()
	var type_is_structure: bool = _tile_catalog != null and _tile_catalog.has_method("is_structure_layer_type") and bool(_tile_catalog.call("is_structure_layer_type", type_id))
	var type_is_object: bool = _tile_catalog != null and _tile_catalog.has_method("is_object_layer_type") and bool(_tile_catalog.call("is_object_layer_type", type_id))
	var terrain_layer: String = String(tile_data.surface_type).strip_edges()
	var structure_layer: String = type_id if type_is_structure else ""
	var object_layer: String = object_type_id
	if object_layer.is_empty() and type_is_object:
		object_layer = type_id
	var supports_stack: bool = not structure_layer.is_empty()
	return {
		"terrain_layer": terrain_layer,
		"structure_layer": structure_layer,
		"object_layer": object_layer,
		"supports_object_on_structure": supports_stack,
		"has_object_on_structure": supports_stack and not object_layer.is_empty(),
		"help_text": "Layer: Boden/Surface bleibt unten, Structure liegt darueber, Object liegt oben. Fuer Satellitenschuessel auf Struktur: Struktur waehlen, dann ein Objekt-Asset pinseln; Eraser entfernt zuerst nur das Objekt.",
	}


func _validate_authoring_map(errors: Array, warnings: Array) -> Dictionary:
	if _terrain_map_data == null:
		errors.append("map_not_loaded")
		return {"loaded": false}
	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	var tiles: Array = Array(_terrain_map_data.call("get_tiles"))
	if grid_size.x <= 0 or grid_size.y <= 0:
		errors.append("map_grid_size_invalid")
	if tiles.is_empty():
		errors.append("map_has_no_tiles")
	if _current_map_path.strip_edges().is_empty():
		warnings.append("map_path_empty")
	elif not FileAccess.file_exists(_current_map_path):
		warnings.append("map_not_saved")
	if _dirty:
		warnings.append("map_has_unsaved_changes")
	return {
		"loaded": true,
		"map_name": String(_terrain_map_data.call("get_map_name")),
		"grid_size": grid_size,
		"tile_count": tiles.size(),
		"mission_slot_count": _get_current_map_mission_slot_count(),
		"dirty": _dirty,
	}


func _validate_authoring_markers(errors: Array, warnings: Array) -> Dictionary:
	var marker_ids: PackedStringArray = PackedStringArray()
	if _terrain_map_data == null:
		return {"marker_count": 0, "required_present": false}
	marker_ids = _terrain_map_data.call("get_marker_ids")
	for required_marker_id in EDITABLE_MARKER_IDS:
		if not bool(_terrain_map_data.call("has_marker", required_marker_id)):
			warnings.append("marker_missing:%s" % required_marker_id)
	for marker_id in marker_ids:
		var marker_position: Vector2 = _terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)
		var marker_tile = _get_tile_at_authoring_position(marker_position)
		if marker_tile == null:
			errors.append("marker_outside_map:%s" % marker_id)
			continue
		if not bool(marker_tile.walkable):
			warnings.append("marker_on_non_walkable_tile:%s" % marker_id)
	return {
		"marker_count": marker_ids.size(),
		"required_present": _has_required_authoring_markers(),
		"marker_ids": marker_ids,
	}


func _validate_authoring_patrols(errors: Array, warnings: Array) -> Dictionary:
	var path_count: int = 0
	var waypoint_count: int = 0
	if _terrain_map_data == null:
		return {"path_count": 0, "waypoint_count": 0}
	var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
	path_count = patrol_paths.size()
	for path_id_variant in patrol_paths.keys():
		var path_id: String = String(path_id_variant).strip_edges()
		var waypoints: Array = Array(_terrain_map_data.call("get_patrol_path", path_id))
		waypoint_count += waypoints.size()
		if waypoints.size() < 2:
			warnings.append("patrol_path_short:%s" % path_id)
		for waypoint_index in range(waypoints.size()):
			var waypoint_tile = _get_tile_at_authoring_position(Vector2(waypoints[waypoint_index]))
			if waypoint_tile == null:
				errors.append("patrol_waypoint_outside_map:%s:%d" % [path_id, waypoint_index])
	return {
		"path_count": path_count,
		"waypoint_count": waypoint_count,
		"active_spawn_id": _patrol_spawn_id,
	}


func _validate_authoring_hills(errors: Array, warnings: Array) -> Dictionary:
	var hill_tile_count: int = 0
	var exposed_edge_count: int = 0
	var blocker_object_count: int = 0
	if _terrain_map_data == null:
		return {"hill_tile_count": 0, "exposed_edge_count": 0}
	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var height_level: int = int(tile_data.height_level)
		var edge_type: String = String(tile_data.edge_type)
		if int(tile_data.object_height) > 0:
			blocker_object_count += 1
		if height_level <= 0:
			if edge_type != TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
				warnings.append("ground_tile_has_edge:%s" % String(tile_data.tile_id))
			continue
		hill_tile_count += 1
		var has_lower_neighbor: bool = _has_lower_neighbor(tile_data.grid_position, height_level)
		if has_lower_neighbor:
			exposed_edge_count += 1
			if edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
				errors.append("height_edge_missing:%s" % String(tile_data.tile_id))
		elif edge_type != TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
			warnings.append("plateau_interior_has_edge:%s" % String(tile_data.tile_id))
	return {
		"hill_tile_count": hill_tile_count,
		"exposed_edge_count": exposed_edge_count,
		"blocker_object_count": blocker_object_count,
	}


func _validate_authoring_walkability(errors: Array, warnings: Array) -> Dictionary:
	var walkable_count: int = 0
	var blocker_count: int = 0
	var cover_tile_count: int = 0
	if _terrain_map_data == null:
		return {"walkable_count": 0}
	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		if tile_data == null:
			continue
		if bool(tile_data.walkable):
			walkable_count += 1
		if bool(tile_data.blocks_los) or int(tile_data.object_height) > 0:
			blocker_count += 1
		if int(tile_data.cover_value) > 0:
			cover_tile_count += 1
	if walkable_count <= 0:
		errors.append("map_has_no_walkable_tiles")
	if cover_tile_count <= 0:
		warnings.append("map_has_no_cover_tiles")
	return {
		"walkable_count": walkable_count,
		"blocker_count": blocker_count,
		"cover_tile_count": cover_tile_count,
	}


func _build_fow_authoring_diagnostics() -> Dictionary:
	var los_blocker_count: int = 0
	var cover_tile_count: int = 0
	var elevated_tile_count: int = 0
	if _terrain_map_data == null:
		return {
			"los_blocker_count": 0,
			"cover_tile_count": 0,
			"elevated_tile_count": 0,
		}
	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		if tile_data == null:
			continue
		if bool(tile_data.blocks_los) or int(tile_data.object_height) > 0:
			los_blocker_count += 1
		if int(tile_data.cover_value) > 0:
			cover_tile_count += 1
		if int(tile_data.height_level) > 0:
			elevated_tile_count += 1
	return {
		"los_blocker_count": los_blocker_count,
		"cover_tile_count": cover_tile_count,
		"elevated_tile_count": elevated_tile_count,
	}


func _validate_authoring_scenario(errors: Array, warnings: Array) -> Dictionary:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		errors.append("scenario_not_loaded")
		return {"valid": false}
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	for error_variant in PackedStringArray(validation.get("errors", PackedStringArray())):
		errors.append("scenario:%s" % String(error_variant))
	for diagnostic_variant in PackedStringArray(scenario.call("get_enemy_tactics_diagnostics", _terrain_map_data)):
		warnings.append("enemy_tactics:%s" % String(diagnostic_variant))
	if _scenario_dirty:
		warnings.append("scenario_has_unsaved_changes")
	var enemy_ids: PackedStringArray = scenario.call("get_enemy_ids")
	return {
		"valid": bool(validation.get("valid", false)),
		"enemy_count": enemy_ids.size(),
		"enemy_ids": enemy_ids,
		"patrol_binding_count": Array(scenario.get("patrol_bindings")).size(),
		"dirty": _scenario_dirty,
	}


func _build_live_test_readiness(validation: Dictionary) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if not bool(validation.get("valid", false)):
		errors.append("authoring_validation_failed")
	if _dirty:
		errors.append("map_has_unsaved_changes")
	if _current_map_path.strip_edges().is_empty() or not FileAccess.file_exists(_current_map_path):
		errors.append("map_needs_save")
	if not FileAccess.file_exists(LIVE_TEST_SCENE_PATH):
		errors.append("live_test_scene_missing")
	return {
		"ready": errors.is_empty(),
		"errors": errors,
		"scene_path": LIVE_TEST_SCENE_PATH,
		"scenario_scratch_path": LIVE_TEST_SCENARIO_SCRATCH_PATH,
	}


func _has_required_authoring_markers() -> bool:
	if _terrain_map_data == null:
		return false
	for marker_id in EDITABLE_MARKER_IDS:
		if not bool(_terrain_map_data.call("has_marker", marker_id)):
			return false
	return true


func _get_tile_at_authoring_position(world_position: Vector2):
	if _terrain_registry == null:
		return null
	return _terrain_registry.call("get_tile_at_world", world_position)


func _has_lower_neighbor(grid_position: Vector2i, height_level: int) -> bool:
	if _terrain_map_data == null:
		return false
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor = _terrain_map_data.call("get_tile_at_grid", grid_position + offset)
		var neighbor_height: int = int(neighbor.height_level) if neighbor != null else 0
		if neighbor_height < height_level:
			return true
	return false


func _on_mission_scenario_text_changed(_new_text: String) -> void:
	_on_mission_scenario_control_changed()


func _on_mission_scenario_value_changed(_value: float) -> void:
	_on_mission_scenario_control_changed()


func _on_mission_scenario_option_selected(_index: int) -> void:
	_on_mission_scenario_control_changed()


func _on_mission_scenario_control_changed() -> void:
	if _is_refreshing_scenario_controls:
		return
	_sync_mission_scenario_from_controls()
	_scenario_feedback_text = ""
	_mark_scenario_dirty(true)


func _on_mission_scenario_load_pressed() -> void:
	var load_dialog := get_node_or_null("UI/ScenarioLoadDialog") as FileDialog
	if load_dialog == null:
		return
	load_dialog.current_dir = DEFAULT_SCENARIO_DIR
	load_dialog.popup_centered_ratio(0.65)


func _on_mission_scenario_save_pressed() -> void:
	if _current_scenario_path.is_empty():
		_on_mission_scenario_save_as_pressed()
		return
	save_mission_scenario_from_editor(_current_scenario_path)


func _on_mission_scenario_save_as_pressed() -> void:
	var save_dialog := get_node_or_null("UI/ScenarioSaveAsDialog") as FileDialog
	if save_dialog == null:
		return
	save_dialog.current_dir = DEFAULT_SCENARIO_DIR
	save_dialog.current_file = _current_scenario_path.get_file() if not _current_scenario_path.is_empty() else "%s.json" % _build_default_scenario_id()
	save_dialog.popup_centered_ratio(0.65)


func _on_mission_scenario_live_test_pressed() -> void:
	var scene = create_live_test_scene_from_current_scenario()
	if scene == null:
		return
	var tree := get_tree()
	var current_scene := tree.current_scene
	tree.root.add_child(scene)
	tree.current_scene = scene
	if current_scene != null:
		current_scene.queue_free()


func _on_mission_scenario_use_objective_tile_pressed() -> void:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return
	var selected_position = _get_required_selected_tile_world_position("Select a tile first before setting the objective position.")
	if selected_position == null:
		return
	var objective: Dictionary = Dictionary(scenario.get("objective")).duplicate(true)
	objective.erase("marker_id")
	objective["position"] = Vector2(selected_position)
	scenario.set("objective", objective)
	_scenario_feedback_text = "Objective position set."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func _on_mission_scenario_use_spawn_tile_pressed() -> void:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return
	var selected_position = _get_required_selected_tile_world_position("Select a tile first before setting the enemy spawn position.")
	if selected_position == null:
		return
	var groups: Array = Array(scenario.get("enemy_groups")).duplicate(true)
	var group: Dictionary = _get_primary_enemy_group().duplicate(true)
	if group.is_empty():
		group = {
			"group_id": "red_test_group",
			"team_id": "team_bravo",
			"enemy_ids": ["enemy_delta", "enemy_echo"],
		}
	group.erase("spawn_marker_id")
	group["spawn_position"] = Vector2(selected_position)
	if groups.is_empty():
		groups.append(group)
	else:
		groups[0] = group
	scenario.set("enemy_groups", groups)
	_scenario_feedback_text = "Enemy spawn position set."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func _on_mission_scenario_auto_bind_pressed() -> void:
	var scenario = _ensure_mission_scenario()
	if scenario == null:
		return
	_sync_mission_scenario_from_controls()
	var enemy_ids: PackedStringArray = scenario.call("get_enemy_ids")
	scenario.set("patrol_bindings", _build_auto_patrol_bindings(enemy_ids))
	_scenario_feedback_text = "Patrol bindings refreshed."
	_mark_scenario_dirty(true)
	_refresh_mission_authoring_controls()


func _on_mission_scenario_load_file_selected(path: String) -> void:
	load_mission_scenario_for_editor(path)


func _on_mission_scenario_save_as_file_selected(path: String) -> void:
	save_mission_scenario_from_editor(path)


func _get_mission_scenario_panel() -> VBoxContainer:
	return _ensure_mission_scenario_panel_controller().call("get_panel") as VBoxContainer


func _get_scenario_button(button_name: String) -> Button:
	return _ensure_mission_scenario_panel_controller().call("get_button", button_name) as Button


func _get_scenario_line_edit(line_edit_name: String) -> LineEdit:
	return _ensure_mission_scenario_panel_controller().call("get_line_edit", line_edit_name) as LineEdit


func _get_scenario_spinbox(spinbox_name: String) -> SpinBox:
	return _ensure_mission_scenario_panel_controller().call("get_spinbox", spinbox_name) as SpinBox


func _get_scenario_option_button(option_name: String) -> OptionButton:
	return _ensure_mission_scenario_panel_controller().call("get_option_button", option_name) as OptionButton


func get_mission_scenario_panel_debug_snapshot() -> Dictionary:
	return Dictionary(_ensure_mission_scenario_panel_controller().call("get_debug_snapshot"))


func _hide_legacy_marker_rows() -> void:
	for node_path in [
		"UI/PropertyPanel/Margin/VBox/SpawnAlphaRow",
		"UI/PropertyPanel/Margin/VBox/SpawnBravoRow",
		"UI/PropertyPanel/Margin/VBox/ObjectivePointRow",
	]:
		var row := get_node_or_null(node_path) as Control
		if row != null:
			row.visible = false


func _populate_marker_type_options() -> void:
	var editor_marker_type_ids: PackedStringArray = TERRAIN_MARKER_CATALOG_SCRIPT.call("get_type_ids_for_context", TERRAIN_MARKER_CATALOG_SCRIPT.CONTEXT_EDITOR_ONLY)
	for option_button in [_get_add_marker_type_option_button(), _get_selected_marker_type_option_button()]:
		if option_button == null:
			continue
		var previous_type_id: String = ""
		if option_button.selected >= 0 and option_button.selected < option_button.item_count:
			previous_type_id = String(option_button.get_item_metadata(option_button.selected)).strip_edges()
		option_button.clear()
		for marker_type_id in editor_marker_type_ids:
			option_button.add_item(String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)))
			option_button.set_item_metadata(option_button.item_count - 1, marker_type_id)
			var popup: PopupMenu = option_button.get_popup()
			if popup != null and popup.has_method("set_item_tooltip"):
				popup.call("set_item_tooltip", option_button.item_count - 1, _get_marker_type_tooltip(String(marker_type_id)))
		var selected_index: int = 0
		for index in range(option_button.item_count):
			if String(option_button.get_item_metadata(index)) == previous_type_id:
				selected_index = index
				break
		if option_button.item_count > 0:
			option_button.select(selected_index)


func _get_option_selected_metadata(option_button: OptionButton) -> String:
	if option_button == null or option_button.selected < 0 or option_button.selected >= option_button.item_count:
		return ""
	return String(option_button.get_item_metadata(option_button.selected)).strip_edges().to_lower()


func _get_marker_type_tooltip(marker_type_id: String) -> String:
	var normalized_type_id: String = marker_type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return ""
	if TERRAIN_MARKER_CATALOG_SCRIPT.has_method("get_tooltip"):
		return String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_tooltip", normalized_type_id)).strip_edges()
	return String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", normalized_type_id)).strip_edges()


func _connect_marker_editor_signals() -> void:
	var add_marker_button := _get_add_marker_button()
	if add_marker_button != null and not add_marker_button.pressed.is_connected(_on_add_marker_button_pressed):
		add_marker_button.pressed.connect(_on_add_marker_button_pressed)
	var remove_marker_button := _get_remove_marker_button()
	if remove_marker_button != null and not remove_marker_button.pressed.is_connected(_on_remove_marker_button_pressed):
		remove_marker_button.pressed.connect(_on_remove_marker_button_pressed)
	var marker_tool_button := _get_marker_tool_button()
	if marker_tool_button != null and not marker_tool_button.toggled.is_connected(_on_marker_tool_toggled):
		marker_tool_button.toggled.connect(_on_marker_tool_toggled)
	var marker_list := _get_marker_list()
	if marker_list != null:
		if not marker_list.item_selected.is_connected(_on_marker_list_item_selected):
			marker_list.item_selected.connect(_on_marker_list_item_selected)
		if not marker_list.item_activated.is_connected(_on_marker_list_item_activated):
			marker_list.item_activated.connect(_on_marker_list_item_activated)
	var selected_marker_type_option := _get_selected_marker_type_option_button()
	if selected_marker_type_option != null and not selected_marker_type_option.item_selected.is_connected(_on_selected_marker_type_item_selected):
		selected_marker_type_option.item_selected.connect(_on_selected_marker_type_item_selected)
	var marker_name_line_edit := _get_marker_name_line_edit()
	if marker_name_line_edit != null:
		if not marker_name_line_edit.text_changed.is_connected(_on_marker_name_text_changed):
			marker_name_line_edit.text_changed.connect(_on_marker_name_text_changed)
		if not marker_name_line_edit.text_submitted.is_connected(_on_marker_name_text_submitted):
			marker_name_line_edit.text_submitted.connect(_on_marker_name_text_submitted)
	var marker_color_button := _get_marker_color_button()
	if marker_color_button != null and not marker_color_button.color_changed.is_connected(_on_marker_color_changed):
		marker_color_button.color_changed.connect(_on_marker_color_changed)


func _refresh_marker_editor_controls() -> void:
	var add_type_option := _get_add_marker_type_option_button()
	var add_marker_button := _get_add_marker_button()
	var marker_tool_button := _get_marker_tool_button()
	var remove_marker_button := _get_remove_marker_button()
	var marker_list := _get_marker_list()
	var selected_type_option := _get_selected_marker_type_option_button()
	var marker_name_line_edit := _get_marker_name_line_edit()
	var marker_color_button := _get_marker_color_button()
	var marker_info_label := _get_marker_info_label()
	if add_type_option == null or add_marker_button == null or marker_tool_button == null or remove_marker_button == null or marker_list == null or selected_type_option == null or marker_name_line_edit == null or marker_color_button == null or marker_info_label == null:
		return

	_is_refreshing_marker_controls = true
	_populate_marker_type_options()
	_refresh_marker_list()

	var has_map_data: bool = _terrain_map_data != null
	var selected_record: Dictionary = {}
	if has_map_data and not _selected_marker_id.is_empty() and bool(_terrain_map_data.call("has_marker", _selected_marker_id)):
		selected_record = Dictionary(_terrain_map_data.call("get_marker_record", _selected_marker_id))
	else:
		_selected_marker_id = ""

	add_type_option.disabled = not has_map_data
	var add_marker_type_id: String = _get_option_selected_metadata(add_type_option)
	var add_marker_tooltip: String = _get_marker_type_tooltip(add_marker_type_id)
	add_type_option.tooltip_text = "Marker type to add.\n%s" % add_marker_tooltip if not add_marker_tooltip.is_empty() else "Marker type to add."
	add_marker_button.disabled = not has_map_data
	marker_tool_button.disabled = not has_map_data
	marker_tool_button.button_pressed = _marker_tool_enabled
	remove_marker_button.disabled = selected_record.is_empty()
	selected_type_option.disabled = selected_record.is_empty()
	marker_name_line_edit.editable = not selected_record.is_empty()
	marker_color_button.disabled = selected_record.is_empty()

	if selected_record.is_empty():
		marker_name_line_edit.text = ""
		marker_color_button.color = Color(0.9, 0.9, 0.9, 1.0)
		marker_info_label.text = _marker_feedback_text if not _marker_feedback_text.is_empty() else "Create a marker from the list above and place it directly on the map."
		marker_info_label.tooltip_text = add_marker_tooltip
		_is_refreshing_marker_controls = false
		_refresh_authoring_status_controls()
		_apply_inspector_section_visibility()
		return

	var marker_type_id: String = String(selected_record.get("marker_type_id", "")).strip_edges()
	for index in range(selected_type_option.item_count):
		if String(selected_type_option.get_item_metadata(index)) == marker_type_id:
			selected_type_option.select(index)
			break
	marker_name_line_edit.text = String(selected_record.get("name", _selected_marker_id))
	marker_color_button.color = Color(selected_record.get("color", Color(0.9, 0.9, 0.9, 1.0)))
	marker_info_label.text = _build_marker_info_text(selected_record)
	var selected_marker_tooltip: String = _get_marker_type_tooltip(marker_type_id)
	selected_type_option.tooltip_text = "Selected marker type.\n%s" % selected_marker_tooltip if not selected_marker_tooltip.is_empty() else "Selected marker type."
	marker_info_label.tooltip_text = selected_marker_tooltip
	_is_refreshing_marker_controls = false
	_refresh_authoring_status_controls()
	_apply_inspector_section_visibility()


func _refresh_marker_list() -> void:
	var marker_list := _get_marker_list()
	if marker_list == null:
		return
	marker_list.clear()
	if _terrain_map_data == null:
		return
	var marker_ids: PackedStringArray = _terrain_map_data.call("get_marker_ids")
	var selected_index: int = -1
	for marker_id in marker_ids:
		var marker_record: Dictionary = Dictionary(_terrain_map_data.call("get_marker_record", marker_id))
		marker_list.add_item(_build_marker_list_label(String(marker_id), marker_record))
		marker_list.set_item_metadata(marker_list.item_count - 1, marker_id)
		marker_list.set_item_custom_fg_color(marker_list.item_count - 1, Color(marker_record.get("color", Color(0.9, 0.9, 0.9, 1.0))))
		if String(marker_id) == _selected_marker_id:
			selected_index = marker_list.item_count - 1
	if selected_index >= 0:
		marker_list.select(selected_index)


func _build_marker_list_label(marker_id: String, marker_record: Dictionary) -> String:
	var marker_type_id: String = String(marker_record.get("marker_type_id", marker_id)).strip_edges()
	var marker_name: String = String(marker_record.get("name", marker_id)).strip_edges()
	var type_name: String = String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)).strip_edges()
	if marker_name.is_empty() or marker_name == type_name:
		return type_name
	return "%s | %s" % [type_name, marker_name]


func _build_marker_info_text(marker_record: Dictionary) -> String:
	var marker_type_id: String = String(marker_record.get("marker_type_id", "")).strip_edges()
	var marker_name: String = String(marker_record.get("name", _selected_marker_id)).strip_edges()
	var marker_position: Vector2 = Vector2(marker_record.get("position", Vector2.ZERO))
	var marker_context: String = String(marker_record.get("placement_context", "")).strip_edges().to_lower()
	var context_text: String = "Editor only" if marker_context == TERRAIN_MARKER_CATALOG_SCRIPT.CONTEXT_EDITOR_ONLY else "Mission player"
	var base_text: String = "%s | %s | %d, %d | %s" % [String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)), marker_name, int(round(marker_position.x)), int(round(marker_position.y)), context_text]
	var tooltip_text: String = _get_marker_type_tooltip(marker_type_id)
	if not tooltip_text.is_empty():
		base_text = "%s\n%s" % [base_text, tooltip_text]
	if _marker_feedback_text.is_empty():
		return base_text
	return "%s\n%s" % [_marker_feedback_text, base_text]


func _set_marker_feedback(feedback_text: String) -> void:
	_marker_feedback_text = feedback_text.strip_edges()
	var marker_info_label := _get_marker_info_label()
	if marker_info_label == null:
		return
	if _marker_feedback_text.is_empty():
		marker_info_label.text = "Select a marker to edit it."
		return
	marker_info_label.text = _marker_feedback_text


func _on_add_marker_button_pressed() -> void:
	_add_marker_of_selected_type()


func _on_remove_marker_button_pressed() -> void:
	_delete_selected_marker()


func _on_height_tool_toggled(pressed: bool) -> void:
	_height_tool_enabled = pressed
	if pressed:
		_network_drag_tool_enabled = false
		_clear_network_drag_preview()
		_selection_tool_enabled = false
		_eraser_tool_enabled = false
		_patrol_tool_enabled = false
		_marker_tool_enabled = false
		var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
		if select_button != null:
			select_button.button_pressed = false
		var eraser_button := _get_eraser_tool_button()
		if eraser_button != null:
			eraser_button.button_pressed = false
		var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
		if patrol_button != null:
			patrol_button.button_pressed = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null:
			marker_tool_button.button_pressed = false
		var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
		if brush_button != null and brush_button.button_pressed:
			brush_button.button_pressed = false
		_is_painting = false
		_last_painted_grid = Vector2i(-1, -1)
		_hide_hover_preview()
		_clear_patrol_route_preview(true)
		_refresh_patrol_overlay()
		_refresh_marker_editor_controls()
	_update_height_topbar_state()
	_update_patrol_topbar_state()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_height_mode_selected(index: int) -> void:
	var option_button := _get_height_mode_option_button()
	if option_button == null or index < 0 or index >= option_button.item_count:
		return
	_height_tool_mode = String(option_button.get_item_metadata(index))
	_refresh_authoring_status_controls()


func _on_height_edge_selected(index: int) -> void:
	var option_button := _get_height_edge_option_button()
	if option_button == null or index < 0 or index >= option_button.item_count:
		return
	var edge_type: String = String(option_button.get_item_metadata(index))
	match edge_type:
		TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
			_height_tool_edge_type = edge_type
		_:
			_height_tool_edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	_refresh_authoring_status_controls()


func _on_marker_tool_toggled(pressed: bool) -> void:
	_marker_tool_enabled = pressed
	if not pressed:
		_is_dragging_marker = false
		_has_dragged_marker = false
		_dragged_marker_id = ""
		_refresh_marker_editor_controls()
		return
	_clear_height_tool()
	_network_drag_tool_enabled = false
	_clear_network_drag_preview()
	_selection_tool_enabled = false
	_eraser_tool_enabled = false
	_patrol_tool_enabled = false
	_clear_patrol_route_preview(true)
	var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
	if select_button != null:
		select_button.button_pressed = false
	var eraser_button := _get_eraser_tool_button()
	if eraser_button != null:
		eraser_button.button_pressed = false
	var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
	if patrol_button != null:
		patrol_button.button_pressed = false
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	if brush_button != null and brush_button.button_pressed:
		brush_button.button_pressed = false
	_hide_hover_preview()
	_refresh_marker_editor_controls()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_marker_list_item_selected(index: int) -> void:
	var marker_list := _get_marker_list()
	if marker_list == null or index < 0 or index >= marker_list.item_count:
		return
	_select_marker(String(marker_list.get_item_metadata(index)))


func _on_marker_list_item_activated(index: int) -> void:
	_on_marker_list_item_selected(index)
	_focus_marker_name_editor()


func _on_selected_marker_type_item_selected(index: int) -> void:
	if _is_refreshing_marker_controls or _terrain_map_data == null or _selected_marker_id.is_empty():
		return
	var option_button := _get_selected_marker_type_option_button()
	if option_button == null or index < 0 or index >= option_button.item_count:
		return
	var marker_type_id: String = String(option_button.get_item_metadata(index)).strip_edges()
	if marker_type_id.is_empty():
		return
	if bool(TERRAIN_MARKER_CATALOG_SCRIPT.call("is_single_instance", marker_type_id)):
		for other_marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
			if String(other_marker_id) == _selected_marker_id:
				continue
			if String(_terrain_map_data.call("get_marker_type_id", other_marker_id)) == marker_type_id:
				_set_marker_feedback("Only one %s marker is allowed." % String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)))
				_refresh_marker_editor_controls()
				return
	_terrain_map_data.call("set_marker_type", _selected_marker_id, marker_type_id)
	_mark_dirty(true)
	_set_marker_feedback("Marker type updated.")
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


func _on_marker_name_text_changed(new_text: String) -> void:
	if _is_refreshing_marker_controls or _terrain_map_data == null or _selected_marker_id.is_empty():
		return
	_terrain_map_data.call("set_marker_display_name", _selected_marker_id, new_text)
	_mark_dirty(true)
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


func _on_marker_name_text_submitted(_new_text: String) -> void:
	_focus_marker_name_editor(false)


func _on_marker_color_changed(marker_color: Color) -> void:
	if _is_refreshing_marker_controls or _terrain_map_data == null or _selected_marker_id.is_empty():
		return
	_terrain_map_data.call("set_marker_color", _selected_marker_id, marker_color)
	_mark_dirty(true)
	_set_marker_feedback("Marker color updated.")
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


func _add_marker_of_selected_type() -> bool:
	if _terrain_map_data == null:
		return false
	var add_type_option := _get_add_marker_type_option_button()
	if add_type_option == null or add_type_option.selected < 0 or add_type_option.selected >= add_type_option.item_count:
		return false
	var marker_type_id: String = String(add_type_option.get_item_metadata(add_type_option.selected)).strip_edges()
	if marker_type_id.is_empty():
		return false
	var existing_marker_ids: PackedStringArray = _terrain_map_data.call("get_marker_ids")
	var marker_id: String = String(TERRAIN_MARKER_CATALOG_SCRIPT.call("build_marker_id", marker_type_id, existing_marker_ids))
	if bool(TERRAIN_MARKER_CATALOG_SCRIPT.call("is_single_instance", marker_type_id)) and bool(_terrain_map_data.call("has_marker", marker_id)):
		_select_marker(marker_id)
		_set_marker_feedback("There is already a %s marker." % String(TERRAIN_MARKER_CATALOG_SCRIPT.call("get_display_name", marker_type_id)))
		return false
	var spawn_position = _find_first_available_marker_world_position(_get_default_marker_spawn_position())
	if spawn_position == null:
		_set_marker_feedback("No free tile is available for another marker.")
		return false
	_terrain_map_data.call("set_marker", marker_id, marker_type_id, spawn_position)
	_mark_dirty(true)
	_select_marker(marker_id)
	_set_marker_feedback("Marker added. Place or drag it on the map.")
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()
	return true


func _delete_selected_marker() -> bool:
	if _terrain_map_data == null or _selected_marker_id.is_empty() or not bool(_terrain_map_data.call("has_marker", _selected_marker_id)):
		return false
	_terrain_map_data.call("remove_marker", _selected_marker_id)
	_mark_dirty(true)
	_set_marker_feedback("Marker removed.")
	_selected_marker_id = ""
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()
	return true


func _clear_marker_selection() -> void:
	if _selected_marker_id.is_empty():
		return
	_selected_marker_id = ""
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


func _select_marker(marker_id: String) -> void:
	var normalized_marker_id: String = marker_id.strip_edges()
	if _terrain_map_data == null or normalized_marker_id.is_empty() or not bool(_terrain_map_data.call("has_marker", normalized_marker_id)):
		_selected_marker_id = ""
		_set_selected_grid_position(Vector2i(-1, -1))
	else:
		_selected_marker_id = normalized_marker_id
		var marker_position: Vector2 = _terrain_map_data.call("get_marker_position", normalized_marker_id, Vector2.ZERO)
		if _terrain_registry != null:
			_set_selected_grid_position(_terrain_registry.world_to_grid(marker_position))
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION)
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


func _handle_marker_left_press(mouse_button_event: InputEventMouseButton) -> bool:
	var world_position: Vector2 = _screen_to_editor_world_position(mouse_button_event.position)
	var hit_marker_id: String = _find_marker_id_at_world_position(world_position)
	if not hit_marker_id.is_empty():
		_select_marker(hit_marker_id)
		if mouse_button_event.double_click:
			_focus_marker_name_editor()
			return true
		_dragged_marker_id = hit_marker_id
		_dragged_marker_press_screen_position = mouse_button_event.position
		_is_dragging_marker = true
		_has_dragged_marker = false
		return true
	if _selected_marker_id.is_empty():
		return false
	return _move_marker_to_world_position(_selected_marker_id, world_position)


func _update_marker_drag(world_position: Vector2, _relative: Vector2) -> bool:
	if not _is_dragging_marker or _dragged_marker_id.is_empty():
		return false
	if _is_pointer_over_control():
		return true
	var current_screen_position: Vector2 = get_viewport().get_mouse_position()
	if not _has_dragged_marker and _dragged_marker_press_screen_position.distance_to(current_screen_position) < MARKER_DRAG_THRESHOLD:
		return true
	_has_dragged_marker = true
	_move_marker_to_world_position(_dragged_marker_id, world_position, true)
	return true


func _finish_marker_drag() -> bool:
	if not _is_dragging_marker:
		return false
	if _has_dragged_marker:
		_set_marker_feedback("Marker moved.")
		_refresh_marker_editor_controls()
	_is_dragging_marker = false
	_has_dragged_marker = false
	_dragged_marker_id = ""
	return true


func _move_marker_to_world_position(marker_id: String, world_position: Vector2, is_drag: bool = false) -> bool:
	if _terrain_map_data == null or marker_id.is_empty():
		return false
	var snapped_position = _snap_world_position_to_tile_center(world_position)
	if snapped_position == null:
		if not is_drag:
			_set_marker_feedback("Markers can only be placed on existing tiles.")
		return false
	if not _can_place_marker_at_world_position(marker_id, snapped_position):
		if not is_drag:
			_set_marker_feedback("That tile already has another marker.")
		return false
	_terrain_map_data.call("set_marker_position", marker_id, snapped_position)
	_mark_dirty(true)
	_select_marker(marker_id)
	_queue_3d_map_refresh()
	if not is_drag:
		_set_marker_feedback("Marker placed on tile center.")
	return true


func _snap_world_position_to_tile_center(world_position: Vector2):
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return null
	return Vector2(tile_data.world_position)


func _find_marker_id_at_world_position(world_position: Vector2) -> String:
	return String(MAP_EDITOR_MARKER_TOOL_SCRIPT.call("find_marker_id_at_world_position", _terrain_map_data, world_position, MARKER_PICK_RADIUS))


func _can_place_marker_at_world_position(marker_id: String, world_position: Vector2) -> bool:
	return bool(MAP_EDITOR_MARKER_TOOL_SCRIPT.call("can_place_marker_at_world_position", _terrain_map_data, marker_id, world_position))


func _find_first_available_marker_world_position(preferred_world_position: Vector2, ignore_marker_id: String = ""):
	var preferred_tile_position = _snap_world_position_to_tile_center(preferred_world_position)
	return MAP_EDITOR_MARKER_TOOL_SCRIPT.call("find_first_available_marker_world_position", _terrain_map_data, preferred_tile_position, ignore_marker_id)


func _marker_positions_equal(a: Vector2, b: Vector2) -> bool:
	return bool(MAP_EDITOR_MARKER_TOOL_SCRIPT.call("marker_positions_equal", a, b))


func _get_default_marker_spawn_position() -> Vector2:
	var selected_tile = _get_selected_tile()
	if selected_tile != null:
		return Vector2(selected_tile.world_position)
	if _terrain_map_data == null:
		return Vector2.ZERO
	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	var center_grid := Vector2i(maxi(grid_size.x / 2, 0), maxi(grid_size.y / 2, 0))
	var center_tile = _terrain_map_data.call("get_tile_at_grid", center_grid)
	if center_tile != null:
		return Vector2(center_tile.world_position)
	var tiles: Array = _terrain_map_data.call("get_tiles")
	if tiles.is_empty():
		return Vector2.ZERO
	return Vector2(tiles[0].world_position)


func _ensure_marker_overlay() -> void:
	var existing_overlay := get_node_or_null(MARKER_OVERLAY_NAME) as Node2D
	if existing_overlay != null:
		return
	var overlay := Node2D.new()
	overlay.name = MARKER_OVERLAY_NAME
	overlay.z_index = 36
	add_child(overlay)


func _refresh_marker_overlay() -> void:
	var overlay := get_node_or_null(MARKER_OVERLAY_NAME) as Node2D
	if overlay == null:
		_queue_3d_map_refresh()
		return
	for child in overlay.get_children():
		child.queue_free()
	if _terrain_map_data == null:
		_queue_3d_map_refresh()
		return
	for marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
		var marker_record: Dictionary = Dictionary(_terrain_map_data.call("get_marker_record", marker_id))
		var marker_position: Vector2 = Vector2(marker_record.get("position", Vector2.ZERO))
		var marker_host := Node2D.new()
		marker_host.name = "Marker_%s" % marker_id
		marker_host.position = marker_position
		overlay.add_child(marker_host)
		var marker_color: Color = Color(marker_record.get("color", Color(0.9, 0.9, 0.9, 1.0)))
		var marker_symbol: String = String(marker_record.get("symbol", TERRAIN_MARKER_CATALOG_SCRIPT.call("get_symbol", marker_id))).strip_edges().to_lower()
		_add_marker_symbol_to_host(marker_host, marker_symbol, marker_color, String(marker_id) == _selected_marker_id)
		var marker_label := Label.new()
		marker_label.text = String(marker_record.get("name", marker_id)).strip_edges()
		marker_label.position = Vector2(14.0, -22.0)
		marker_label.modulate = marker_color.lightened(0.18)
		marker_label.add_theme_font_size_override("font_size", 11)
		marker_host.add_child(marker_label)
	_queue_3d_map_refresh()


func _add_marker_symbol_to_host(host: Node2D, marker_symbol: String, marker_color: Color, is_selected: bool) -> void:
	var polygon_points: PackedVector2Array = PackedVector2Array()
	match marker_symbol:
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_SQUARE:
			polygon_points = PackedVector2Array([
				Vector2(-8.0, -8.0),
				Vector2(8.0, -8.0),
				Vector2(8.0, 8.0),
				Vector2(-8.0, 8.0),
			])
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_DIAMOND:
			polygon_points = PackedVector2Array([
				Vector2(0.0, -10.0),
				Vector2(10.0, 0.0),
				Vector2(0.0, 10.0),
				Vector2(-10.0, 0.0),
			])
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_TRIANGLE:
			polygon_points = PackedVector2Array([
				Vector2(0.0, -10.0),
				Vector2(10.0, 9.0),
				Vector2(-10.0, 9.0),
			])
		TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_FLAG:
			var pole := Line2D.new()
			pole.width = 2.0
			pole.default_color = marker_color
			pole.add_point(Vector2(-6.0, 10.0))
			pole.add_point(Vector2(-6.0, -10.0))
			host.add_child(pole)
			polygon_points = PackedVector2Array([
				Vector2(-6.0, -10.0),
				Vector2(8.0, -6.0),
				Vector2(-6.0, -1.0),
			])
		_:
			polygon_points = PackedVector2Array()
	if not polygon_points.is_empty():
		var polygon := Polygon2D.new()
		polygon.polygon = polygon_points
		polygon.color = marker_color
		host.add_child(polygon)
	if marker_symbol == TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CROSS or marker_symbol == TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CHEVRON:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = marker_color
		if marker_symbol == TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CROSS:
			line.add_point(Vector2(-8.0, -8.0))
			line.add_point(Vector2(8.0, 8.0))
			line.add_point(Vector2(0.0, 0.0))
			line.add_point(Vector2(-8.0, 8.0))
			line.add_point(Vector2(8.0, -8.0))
		else:
			line.add_point(Vector2(-9.0, -7.0))
			line.add_point(Vector2(0.0, 0.0))
			line.add_point(Vector2(-9.0, 7.0))
			line.add_point(Vector2(0.0, 0.0))
			line.add_point(Vector2(9.0, 0.0))
		host.add_child(line)
	if marker_symbol == TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CIRCLE or (polygon_points.is_empty() and marker_symbol != TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CROSS and marker_symbol != TERRAIN_MARKER_CATALOG_SCRIPT.SYMBOL_CHEVRON):
		var circle := Polygon2D.new()
		var circle_points := PackedVector2Array()
		for point_index in range(14):
			var angle: float = TAU * float(point_index) / 14.0
			circle_points.append(Vector2(cos(angle), sin(angle)) * 8.5)
		circle.polygon = circle_points
		circle.color = marker_color
		host.add_child(circle)
	if is_selected:
		var selection_outline := Line2D.new()
		selection_outline.width = 2.0
		selection_outline.default_color = Color(1.0, 1.0, 1.0, 0.96)
		selection_outline.closed = true
		selection_outline.add_point(Vector2(0.0, -14.0))
		selection_outline.add_point(Vector2(14.0, 0.0))
		selection_outline.add_point(Vector2(0.0, 14.0))
		selection_outline.add_point(Vector2(-14.0, 0.0))
		host.add_child(selection_outline)


func _focus_marker_name_editor(grab_focus: bool = true) -> void:
	var marker_name_line_edit := _get_marker_name_line_edit()
	if marker_name_line_edit == null:
		return
	if grab_focus:
		marker_name_line_edit.grab_focus()
		marker_name_line_edit.select_all()
	else:
		marker_name_line_edit.release_focus()


func _set_property_controls_enabled(is_enabled: bool) -> void:
	_get_walkable_checkbox().disabled = not is_enabled
	_get_blocks_los_checkbox().disabled = not is_enabled
	_get_cover_spinbox().editable = is_enabled
	_get_height_spinbox().editable = is_enabled
	_get_surface_option_button().disabled = not is_enabled
	var edge_type_btn := _get_edge_type_option_button()
	if edge_type_btn != null:
		edge_type_btn.disabled = not is_enabled


func _refresh_object_rotation_controls(tile_data) -> void:
	var row := get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectRotationRow") as HBoxContainer
	var left_button := _get_object_rotate_left_button()
	var right_button := _get_object_rotate_right_button()
	var value_label := _get_object_rotation_value_label()
	var has_rotatable_object: bool = _tile_has_rotatable_object(tile_data)
	if row != null:
		row.visible = tile_data != null
	if left_button != null:
		left_button.disabled = not has_rotatable_object
	if right_button != null:
		right_button.disabled = not has_rotatable_object
	if value_label != null:
		value_label.text = "%d deg" % int(round(_get_tile_object_rotation_degrees(tile_data))) if has_rotatable_object else "-"


func _refresh_object_scale_controls(tile_data) -> void:
	var row := get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectScaleRow") as HBoxContainer
	var scale_spinbox := _get_object_scale_spinbox()
	var reset_button := _get_object_scale_reset_button()
	var has_scalable_object: bool = _tile_has_scalable_object(tile_data)
	if row != null:
		row.visible = tile_data != null
	if scale_spinbox != null:
		scale_spinbox.editable = has_scalable_object
		scale_spinbox.value = _get_tile_object_scale(tile_data)
	if reset_button != null:
		reset_button.disabled = not has_scalable_object


func _tile_has_rotatable_object(tile_data) -> bool:
	if tile_data == null:
		return false
	var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower() if tile_data.object_type_id is String else ""
	if not object_type_id.is_empty():
		return true
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	if type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_method("is_object_layer_type"):
		return false
	if type_id == "station_floor_panel" or type_id == "modular_floor" or type_id == "modular_floor_big":
		return true
	if bool(_tile_catalog.call("is_object_layer_type", type_id)):
		return true
	if _tile_catalog.has_method("is_structure_layer_type"):
		return bool(_tile_catalog.call("is_structure_layer_type", type_id)) and (type_id.begins_with("station_") or type_id.begins_with("modular_"))
	return false


func _tile_has_scalable_object(tile_data) -> bool:
	return _tile_has_rotatable_object(tile_data)


func _palette_type_uses_object_scale(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return false
	if normalized_type_id == "station_floor_panel" or normalized_type_id == "modular_floor" or normalized_type_id == "modular_floor_big":
		return true
	if _tile_catalog != null:
		if _tile_catalog.has_method("is_object_layer_type") and bool(_tile_catalog.call("is_object_layer_type", normalized_type_id)):
			return true
		if _tile_catalog.has_method("is_structure_layer_type") and bool(_tile_catalog.call("is_structure_layer_type", normalized_type_id)):
			return true
	return (
		normalized_type_id.begins_with("station_")
		or normalized_type_id.begins_with("station_set_")
		or normalized_type_id.begins_with("modular_")
		or normalized_type_id.begins_with("factory_")
		or normalized_type_id.begins_with("spacekit_")
		or normalized_type_id.begins_with("wall_")
		or normalized_type_id.begins_with("cliff_")
		or normalized_type_id.begins_with("rock_")
	)


func _get_tile_object_rotation_degrees(tile_data) -> float:
	if tile_data == null:
		return 0.0
	return fposmod(float(tile_data.object_rotation_degrees), 360.0)


func _get_tile_object_scale(tile_data) -> float:
	if tile_data == null:
		return OBJECT_SCALE_DEFAULT
	return _normalize_object_scale(float(tile_data.object_scale))


func _normalize_object_scale(value: float) -> float:
	if is_nan(value) or is_inf(value):
		return OBJECT_SCALE_DEFAULT
	return snappedf(clampf(value, OBJECT_SCALE_MIN, OBJECT_SCALE_MAX), 0.001)


func _rotate_selected_object(delta_degrees: float) -> bool:
	var tile_data = _get_selected_tile()
	if not _tile_has_rotatable_object(tile_data):
		return false
	var owns_undo_transaction: bool = _ensure_undo_transaction("rotate_object")
	_store_undo_state(tile_data)
	tile_data.object_rotation_degrees = fposmod(float(tile_data.object_rotation_degrees) + delta_degrees, 360.0)
	_refresh_tile_visual(tile_data)
	if owns_undo_transaction:
		commit_undo_transaction()
	_mark_dirty(true)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_PROPERTIES)
	return true


func set_selected_object_scale(value: float) -> bool:
	var tile_data = _get_selected_tile()
	if not _tile_has_scalable_object(tile_data):
		return false
	var normalized_scale: float = _normalize_object_scale(value)
	if is_equal_approx(float(tile_data.object_scale), normalized_scale):
		_refresh_object_scale_controls(tile_data)
		return false
	var owns_undo_transaction: bool = _ensure_undo_transaction("scale_object")
	_store_undo_state(tile_data)
	tile_data.object_scale = normalized_scale
	_refresh_tile_visual(tile_data)
	if owns_undo_transaction:
		commit_undo_transaction()
	_mark_dirty(true)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_PROPERTIES)
	return true


func set_object_placement_scale(value: float) -> bool:
	var normalized_scale: float = _normalize_object_scale(value)
	var changed: bool = not is_equal_approx(_placement_object_scale, normalized_scale)
	_placement_object_scale = normalized_scale
	var placement_scale_spinbox := _get_placement_object_scale_spinbox()
	if placement_scale_spinbox != null and not is_equal_approx(float(placement_scale_spinbox.value), _placement_object_scale):
		placement_scale_spinbox.value = _placement_object_scale
	_refresh_palette_workflow_controls()
	if changed:
		_save_palette_authoring_preferences()
	return changed


func set_object_placement_scale_preset(value: float) -> bool:
	return set_object_placement_scale(value)


func get_object_placement_scale() -> float:
	return _placement_object_scale


func save_palette_authoring_preferences_for_test() -> bool:
	return _save_palette_authoring_preferences()


func set_palette_authoring_preferences_path_for_test(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty() or not normalized_path.begins_with("user://"):
		return false
	_palette_authoring_preferences_path = normalized_path
	_palette_preferences_loaded = false
	_palette_preferences_saved = false
	_palette_preferences_last_error = ""
	return true


func load_palette_authoring_preferences_for_test() -> bool:
	var loaded: bool = _load_palette_authoring_preferences()
	_populate_tile_palette()
	_refresh_palette_filter_controls()
	_refresh_palette_workflow_controls()
	_refresh_runtime_builder_workbench_controls()
	return loaded


func clear_palette_authoring_preferences_for_test() -> bool:
	var preferences_path: String = _get_palette_authoring_preferences_path()
	if FileAccess.file_exists(preferences_path):
		var absolute_path: String = ProjectSettings.globalize_path(preferences_path)
		var remove_error: Error = DirAccess.remove_absolute(absolute_path)
		if remove_error != OK:
			_palette_preferences_last_error = "remove_failed:%s" % error_string(remove_error)
			return false
	_palette_favorite_type_ids = PackedStringArray()
	_palette_recent_type_ids = PackedStringArray()
	_placement_object_scale = OBJECT_SCALE_DEFAULT
	_palette_preferences_loaded = false
	_palette_preferences_saved = false
	_palette_preferences_last_error = ""
	return true


func _load_palette_authoring_preferences() -> bool:
	_palette_preferences_last_error = ""
	var preferences_path: String = _get_palette_authoring_preferences_path()
	if not FileAccess.file_exists(preferences_path):
		_palette_preferences_loaded = false
		return false
	var file := FileAccess.open(preferences_path, FileAccess.READ)
	if file == null:
		_palette_preferences_last_error = "open_read_failed:%s" % error_string(FileAccess.get_open_error())
		_palette_preferences_loaded = false
		return false
	var text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_palette_preferences_last_error = "parse_failed"
		_palette_preferences_loaded = false
		return false
	var preferences: Dictionary = Dictionary(parsed)
	var schema: String = String(preferences.get("schema", "")).strip_edges()
	if not schema.is_empty() and schema != PALETTE_AUTHORING_PREFERENCES_SCHEMA:
		_palette_preferences_last_error = "schema_mismatch:%s" % schema
		_palette_preferences_loaded = false
		return false
	_palette_favorite_type_ids = _normalize_palette_preference_type_ids(preferences.get("favorite_type_ids", []), -1)
	_palette_recent_type_ids = _normalize_palette_preference_type_ids(preferences.get("recent_type_ids", []), PALETTE_RECENT_MAX_COUNT)
	if preferences.has("placement_scale"):
		_placement_object_scale = _normalize_object_scale(float(preferences.get("placement_scale", OBJECT_SCALE_DEFAULT)))
		var placement_scale_spinbox := _get_placement_object_scale_spinbox()
		if placement_scale_spinbox != null:
			placement_scale_spinbox.value = _placement_object_scale
	_palette_preferences_loaded = true
	_palette_preferences_load_count += 1
	return true


func _save_palette_authoring_preferences() -> bool:
	_palette_preferences_last_error = ""
	var preferences: Dictionary = {
		"schema": PALETTE_AUTHORING_PREFERENCES_SCHEMA,
		"favorite_type_ids": Array(_palette_favorite_type_ids),
		"recent_type_ids": Array(_palette_recent_type_ids),
		"placement_scale": _placement_object_scale,
		"stores_gameplay_truth": false,
	}
	var file := FileAccess.open(_get_palette_authoring_preferences_path(), FileAccess.WRITE)
	if file == null:
		_palette_preferences_last_error = "open_write_failed:%s" % error_string(FileAccess.get_open_error())
		_palette_preferences_saved = false
		return false
	file.store_string(JSON.stringify(preferences, "\t"))
	file.close()
	_palette_preferences_saved = true
	_palette_preferences_save_count += 1
	return true


func _get_palette_authoring_preferences_path() -> String:
	var path: String = _palette_authoring_preferences_path.strip_edges()
	return path if not path.is_empty() else PALETTE_AUTHORING_PREFERENCES_PATH


func _normalize_palette_preference_type_ids(value, max_count: int = -1) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if typeof(value) != TYPE_ARRAY and typeof(value) != TYPE_PACKED_STRING_ARRAY:
		return result
	for entry in value:
		var type_id: String = String(entry).strip_edges().to_lower()
		if type_id.is_empty() or result.has(type_id):
			continue
		if _tile_catalog != null and not _tile_catalog.has_type(type_id):
			continue
		result.append(type_id)
		if max_count > 0 and result.size() >= max_count:
			break
	return result


func set_palette_search_query_for_authoring(query: String) -> bool:
	var normalized_query: String = query.strip_edges().to_lower()
	if _palette_search_query == normalized_query:
		_refresh_palette_filter_controls()
		return false
	_palette_search_query = normalized_query
	var search := _get_palette_search_line_edit()
	if search != null and search.text.strip_edges().to_lower() != _palette_search_query:
		search.text = _palette_search_query
	_populate_tile_palette()
	_refresh_palette_filter_controls()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()
	return true


func set_palette_favorites_filter_enabled(is_enabled: bool) -> bool:
	if _palette_favorites_filter_enabled == is_enabled:
		_refresh_palette_filter_controls()
		return false
	_palette_favorites_filter_enabled = is_enabled
	_populate_tile_palette()
	_refresh_palette_filter_controls()
	_refresh_runtime_builder_workbench_controls()
	return true


func toggle_palette_favorite_for_authoring(type_id: String = "") -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		normalized_type_id = _selected_type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_type(normalized_type_id):
		return false
	var next_favorites: PackedStringArray = PackedStringArray()
	var removed: bool = false
	for existing in _palette_favorite_type_ids:
		var existing_id: String = String(existing).strip_edges().to_lower()
		if existing_id == normalized_type_id:
			removed = true
			continue
		if not existing_id.is_empty():
			next_favorites.append(existing_id)
	if not removed:
		next_favorites.append(normalized_type_id)
	_palette_favorite_type_ids = next_favorites
	if _palette_favorites_filter_enabled:
		_populate_tile_palette()
	else:
		_refresh_palette_selection_visual()
	_refresh_palette_filter_controls()
	_refresh_palette_workflow_controls()
	_save_palette_authoring_preferences()
	return true


func _on_palette_search_text_changed(query: String) -> void:
	set_palette_search_query_for_authoring(query)


func _remember_palette_recent_type_id(type_id: String) -> void:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_type(normalized_type_id):
		return
	var next_recent: PackedStringArray = PackedStringArray([normalized_type_id])
	for existing in _palette_recent_type_ids:
		var existing_id: String = String(existing).strip_edges().to_lower()
		if existing_id.is_empty() or existing_id == normalized_type_id:
			continue
		next_recent.append(existing_id)
		if next_recent.size() >= PALETTE_RECENT_MAX_COUNT:
			break
	_palette_recent_type_ids = next_recent
	_save_palette_authoring_preferences()


func _palette_type_is_favorite(type_id: String) -> bool:
	return _palette_favorite_type_ids.has(type_id.strip_edges().to_lower())


func _palette_type_is_recent(type_id: String) -> bool:
	return _palette_recent_type_ids.has(type_id.strip_edges().to_lower())


func _palette_type_matches_fast_filter(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	return _palette_type_is_favorite(normalized_type_id) or _palette_type_is_recent(normalized_type_id)


func _palette_type_matches_search(tile_type: Dictionary, query: String) -> bool:
	var normalized_query: String = query.strip_edges().to_lower()
	if normalized_query.is_empty():
		return true
	var type_id: String = String(tile_type.get("type_id", "")).strip_edges().to_lower()
	var display_name: String = String(tile_type.get("display_name", type_id)).strip_edges().to_lower()
	var palette_group: String = String(tile_type.get("palette_group", "")).strip_edges().to_lower()
	return type_id.contains(normalized_query) or display_name.contains(normalized_query) or palette_group.contains(normalized_query)


func _rank_palette_types_for_workflow(sorted_types: Array) -> Array:
	var favorites: Array = []
	var recent: Array = []
	var rest: Array = []
	for tile_type_variant in sorted_types:
		var tile_type: Dictionary = Dictionary(tile_type_variant)
		var type_id: String = String(tile_type.get("type_id", "")).strip_edges().to_lower()
		if _palette_type_is_favorite(type_id):
			favorites.append(tile_type)
		elif _palette_type_is_recent(type_id):
			recent.append(tile_type)
		else:
			rest.append(tile_type)
	favorites.sort_custom(_sort_palette_type_dicts)
	recent.sort_custom(_sort_palette_type_dicts)
	rest.sort_custom(_sort_palette_type_dicts)
	var result: Array = []
	result.append_array(favorites)
	result.append_array(recent)
	result.append_array(rest)
	return result


func _refresh_palette_filter_controls() -> void:
	var search := _get_palette_search_line_edit()
	if search != null and search.text.strip_edges().to_lower() != _palette_search_query:
		search.text = _palette_search_query
	var favorite_filter := _get_palette_favorite_filter_button()
	if favorite_filter != null:
		favorite_filter.button_pressed = _palette_favorites_filter_enabled
	var favorite_toggle := _get_palette_favorite_toggle_button()
	if favorite_toggle != null:
		var has_selection: bool = not _selected_type_id.strip_edges().is_empty()
		favorite_toggle.disabled = not has_selection
		favorite_toggle.text = "-" if has_selection and _palette_type_is_favorite(_selected_type_id) else "+"
		favorite_toggle.tooltip_text = "Entfernt das aktuelle Asset aus den Favoriten." if has_selection and _palette_type_is_favorite(_selected_type_id) else "Merkt das aktuelle Asset als Favorit."


func _format_scale_token(value: float) -> String:
	return _format_scale_label(value).replace(".", "_")


func _format_scale_label(value: float) -> String:
	return "%.1f" % value


func _on_object_scale_value_changed(value: float) -> void:
	if _is_refreshing_property_controls:
		return
	set_selected_object_scale(value)


func _on_object_scale_reset_pressed() -> void:
	set_selected_object_scale(OBJECT_SCALE_DEFAULT)


func _on_placement_object_scale_value_changed(value: float) -> void:
	set_object_placement_scale(value)


func _on_placement_object_scale_reset_pressed() -> void:
	set_object_placement_scale(OBJECT_SCALE_DEFAULT)


func _on_object_rotate_left_pressed() -> void:
	_rotate_selected_object(-90.0)


func _on_object_rotate_right_pressed() -> void:
	_rotate_selected_object(90.0)


func _apply_property_controls_to_selected_tile() -> void:
	if _is_refreshing_property_controls:
		return

	var tile_data = _get_selected_tile()
	if tile_data == null:
		return

	var patch: Dictionary = {
		"walkable": _get_walkable_checkbox().button_pressed,
		"blocks_los": _get_blocks_los_checkbox().button_pressed,
		"cover_value": int(_get_cover_spinbox().value),
		"height_level": int(_get_height_spinbox().value),
		"surface_type": _get_selected_surface_type(),
		"edge_type": _get_selected_edge_type(),
	}

	var center_grid: Vector2i = tile_data.grid_position
	var radius: int = _get_brush_radius()
	var any_changed: bool = false
	var changed_grids: Array[Vector2i] = []
	var dirty_visual_grids: Array[Vector2i] = []
	var owns_undo_transaction: bool = _ensure_undo_transaction("property_tile_patch")

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var target_grid: Vector2i = center_grid + Vector2i(dx, dy)
			var target_tile = _terrain_map_data.call("get_tile_at_grid", target_grid) if _terrain_map_data != null else null
			if target_tile == null:
				continue

			if _apply_tile_patch(target_tile, patch):
				any_changed = true
				dirty_visual_grids.append(target_grid)
				if patch.has("height_level"):
					changed_grids.append(target_grid)
				else:
					_refresh_tile_visual(target_tile, false)

	if not any_changed:
		if owns_undo_transaction:
			cancel_empty_undo_transaction()
		return

	if patch.has("height_level"):
		_refresh_reconciled_height_edges(changed_grids, _get_selected_edge_type())
	else:
		_refresh_dirty_visual_neighborhoods(dirty_visual_grids)
	if owns_undo_transaction:
		commit_undo_transaction()

	_mark_dirty(true)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_PROPERTIES)


func _apply_tile_patch(tile_data, patch: Dictionary) -> bool:
	if tile_data == null or patch.is_empty():
		return false

	var next_walkable: bool = bool(patch.get("walkable", tile_data.walkable))
	var next_blocks_los: bool = bool(patch.get("blocks_los", tile_data.blocks_los))
	var next_cover_value: int = clampi(int(patch.get("cover_value", tile_data.cover_value)), 0, 100)
	var next_height_level: int = clampi(int(patch.get("height_level", tile_data.height_level)), 0, 2)
	var next_object_height: int = clampi(int(patch.get("object_height", tile_data.object_height)), 0, 3)
	var next_surface_type: String = String(patch.get("surface_type", tile_data.surface_type))
	var next_edge_type: String = String(patch.get("edge_type", tile_data.edge_type))

	var changed: bool = (
		tile_data.walkable != next_walkable
		or tile_data.blocks_los != next_blocks_los
		or int(tile_data.cover_value) != next_cover_value
		or int(tile_data.height_level) != next_height_level
		or int(tile_data.object_height) != next_object_height
		or String(tile_data.surface_type) != next_surface_type
		or String(tile_data.edge_type) != next_edge_type
	)
	if not changed:
		return false

	_store_undo_state(tile_data)
	tile_data.walkable = next_walkable
	tile_data.blocks_los = next_blocks_los
	tile_data.cover_value = next_cover_value
	tile_data.height_level = next_height_level
	tile_data.object_height = next_object_height
	tile_data.surface_type = next_surface_type
	tile_data.edge_type = next_edge_type
	if _should_clear_type_id_for_patch(tile_data, patch):
		tile_data.type_id = ""
	return true


func _should_clear_type_id_for_patch(tile_data, patch: Dictionary) -> bool:
	if tile_data == null:
		return false
	if bool(patch.get("preserve_type_id", false)):
		return false

	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	if type_id.is_empty():
		return false
	var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	if not object_type_id.is_empty() and type_id == "ground_flat":
		return true
	if patch.has("height_level") or patch.has("edge_type"):
		if type_id.begins_with("cliff_") or type_id.begins_with("slope_"):
			return true
	if _tile_catalog != null and _tile_catalog.has_method("preserves_hill_fields_when_applied") and bool(_tile_catalog.call("preserves_hill_fields_when_applied", type_id)):
		return false
	for prefix in ["wall_", "rock_", "cliff_", "slope_"]:
		if type_id.begins_with(prefix):
			return false
	return true


func _refresh_reconciled_height_edges(changed_grids: Array[Vector2i], preferred_edge_type: String) -> void:
	var refresh_lookup: Dictionary = {}
	var visual_seed_lookup: Dictionary = {}
	for grid_position in changed_grids:
		var changed_positions: Array[Vector2i] = _reconcile_height_edges_around(Vector2i(grid_position), preferred_edge_type)
		refresh_lookup[Vector2i(grid_position)] = true
		visual_seed_lookup[Vector2i(grid_position)] = true
		for changed_position in changed_positions:
			refresh_lookup[changed_position] = true
			visual_seed_lookup[changed_position] = true

	var visual_seed_grids: Array[Vector2i] = []
	for grid_variant in visual_seed_lookup.keys():
		visual_seed_grids.append(Vector2i(grid_variant))
	for changed_position in _reconcile_lower_neighbor_cliff_visuals_around(visual_seed_grids):
		refresh_lookup[changed_position] = true

	var refresh_grids: Array[Vector2i] = _sort_grid_lookup_keys(refresh_lookup)
	for grid_position in refresh_grids:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position) if _terrain_map_data != null else null
		if tile_data != null:
			_refresh_tile_visual(tile_data, false)
	_refresh_dirty_visual_neighborhoods(refresh_grids)


func _reconcile_height_edges_around(grid_position: Vector2i, preferred_edge_type: String = "") -> Array[Vector2i]:
	if _terrain_map_data == null:
		return []
	var positions: Array[Vector2i] = [grid_position]
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		positions.append(grid_position + offset)

	var changed_positions: Array[Vector2i] = []
	for pos in positions:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", pos)
		if tile_data == null:
			continue
		var next_edge_type: String = _resolve_auto_height_edge_type(tile_data, preferred_edge_type)
		if String(tile_data.edge_type) == next_edge_type:
			continue
		_store_undo_state(tile_data)
		tile_data.edge_type = next_edge_type
		changed_positions.append(pos)
	return changed_positions


func _resolve_auto_height_edge_type(tile_data, preferred_edge_type: String = "") -> String:
	if tile_data == null:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	var height_level: int = int(tile_data.height_level)
	if height_level <= 0:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	if not _has_lower_neighbor(tile_data.grid_position, height_level):
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE

	var current_edge_type: String = String(tile_data.edge_type)
	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF or current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		return current_edge_type

	var normalized_preferred: String = preferred_edge_type.strip_edges().to_lower()
	if normalized_preferred == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	if normalized_preferred == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF or normalized_preferred == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		return normalized_preferred
	return TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE


func _reconcile_lower_neighbor_cliff_visuals_around(seed_grids: Array[Vector2i]) -> Array[Vector2i]:
	if _terrain_map_data == null or seed_grids.is_empty():
		return []

	var candidate_lookup: Dictionary = {}
	for seed_grid in seed_grids:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				candidate_lookup[Vector2i(seed_grid) + Vector2i(dx, dy)] = true

	var required_visuals: Dictionary = _build_required_lower_neighbor_cliff_visuals(candidate_lookup)
	var changed_positions: Array[Vector2i] = []
	for grid_variant in candidate_lookup.keys():
		var grid_position := Vector2i(grid_variant)
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data == null:
			continue
		var required_type_id: String = String(required_visuals.get(grid_position, ""))
		if required_type_id.is_empty():
			if _is_auto_cliff_visual_tile(tile_data):
				_store_undo_state(tile_data)
				_reset_auto_cliff_visual_tile(tile_data)
				changed_positions.append(grid_position)
			continue
		if _apply_auto_cliff_visual_tile(tile_data, required_type_id):
			changed_positions.append(grid_position)

	return changed_positions


func _build_required_lower_neighbor_cliff_visuals(candidate_lookup: Dictionary) -> Dictionary:
	var required_visuals: Dictionary = {}
	for grid_variant in candidate_lookup.keys():
		var grid_position := Vector2i(grid_variant)
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if not _tile_emits_auto_cliff_visuals(tile_data):
			continue
		for edge_offset_variant in AUTO_CLIFF_EDGE_OFFSETS:
			var edge_offset := Vector2i(edge_offset_variant)
			var lower_grid_position: Vector2i = grid_position + edge_offset
			if _is_lower_auto_cliff_neighbor(tile_data, lower_grid_position):
				var straight_type_id: String = _get_auto_cliff_straight_type_id(edge_offset)
				if not straight_type_id.is_empty():
					required_visuals[lower_grid_position] = straight_type_id

		for corner_entry in AUTO_CLIFF_CORNER_ENTRIES:
			var edge_a := Vector2i(corner_entry[0])
			var edge_b := Vector2i(corner_entry[1])
			var corner_offset := Vector2i(corner_entry[2])
			var corner_grid_position: Vector2i = grid_position + corner_offset
			if (
				_is_lower_auto_cliff_neighbor(tile_data, grid_position + edge_a)
				and _is_lower_auto_cliff_neighbor(tile_data, grid_position + edge_b)
				and _is_lower_auto_cliff_neighbor(tile_data, corner_grid_position)
			):
				required_visuals[corner_grid_position] = String(corner_entry[3])

	return required_visuals


func _tile_emits_auto_cliff_visuals(tile_data) -> bool:
	return (
		tile_data != null
		and int(tile_data.height_level) > 0
		and String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
		and not _is_object_type(tile_data)
	)


func _is_lower_auto_cliff_neighbor(source_tile, lower_grid_position: Vector2i) -> bool:
	if source_tile == null:
		return false
	var lower_tile = _terrain_map_data.call("get_tile_at_grid", lower_grid_position) if _terrain_map_data != null else null
	return (
		lower_tile != null
		and int(lower_tile.height_level) < int(source_tile.height_level)
		and (not _is_object_type(lower_tile) or _is_auto_cliff_visual_tile(lower_tile))
	)


func _get_auto_cliff_straight_type_id(edge_offset: Vector2i) -> String:
	match edge_offset:
		Vector2i(-1, 0):
			return "cliff_straight_se"
		Vector2i(1, 0):
			return "cliff_straight_nw"
		Vector2i(0, -1):
			return "cliff_straight_ne"
		Vector2i(0, 1):
			return "cliff_straight_sw"
	return ""


func _apply_auto_cliff_visual_tile(tile_data, type_id: String) -> bool:
	if tile_data == null or type_id.is_empty() or not _can_rewrite_auto_cliff_visual_tile(tile_data):
		return false

	var changed: bool = (
		String(tile_data.type_id) != type_id
		or bool(tile_data.walkable)
		or not bool(tile_data.blocks_los)
		or int(tile_data.cover_value) != 0
		or int(tile_data.object_height) != 0
		or String(tile_data.edge_type) != TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	)
	if not changed:
		return false

	_store_undo_state(tile_data)
	tile_data.type_id = type_id
	tile_data.walkable = false
	tile_data.blocks_los = true
	tile_data.cover_value = 0
	tile_data.object_height = 0
	tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	return true


func _reset_auto_cliff_visual_tile(tile_data) -> void:
	if tile_data == null:
		return
	var preserved_edge_type: String = String(tile_data.edge_type)
	tile_data.type_id = "ground_flat"
	tile_data.walkable = true
	tile_data.blocks_los = false
	tile_data.cover_value = 0
	tile_data.object_height = 0
	if int(tile_data.height_level) <= 0:
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	elif preserved_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF or preserved_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
		tile_data.edge_type = preserved_edge_type
	else:
		tile_data.edge_type = _resolve_auto_height_edge_type(tile_data, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE)


func _can_rewrite_auto_cliff_visual_tile(tile_data) -> bool:
	if tile_data == null:
		return false
	var object_type_id: String = String(tile_data.object_type_id).strip_edges() if tile_data.object_type_id is String else ""
	if not object_type_id.is_empty():
		return false
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	return type_id.is_empty() or type_id == "ground_flat" or type_id.begins_with("cliff_")


func _is_auto_cliff_visual_tile(tile_data) -> bool:
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id).strip_edges().to_lower() if tile_data.type_id is String else ""
	return type_id.begins_with("cliff_")


func begin_undo_transaction(action_name: String) -> void:
	if not _active_undo_transaction.is_empty():
		commit_undo_transaction()
	_active_undo_transaction = {
		"transaction": true,
		"action_name": action_name.strip_edges() if not action_name.strip_edges().is_empty() else "editor_change",
		"tile_states": [],
		"grid_lookup": {},
	}


func _ensure_undo_transaction(action_name: String) -> bool:
	if _active_undo_transaction.is_empty():
		begin_undo_transaction(action_name)
		return true
	return false


func record_tile_before_change(tile_data) -> void:
	if tile_data == null or not tile_data.has_method("to_dict"):
		return
	if _active_undo_transaction.is_empty():
		var immediate_transaction: Dictionary = _build_undo_transaction("tile_change")
		_append_tile_state_to_transaction(immediate_transaction, tile_data)
		immediate_transaction.erase("grid_lookup")
		_push_undo_entry(immediate_transaction)
		return
	_append_tile_state_to_transaction(_active_undo_transaction, tile_data)


func commit_undo_transaction() -> void:
	if _active_undo_transaction.is_empty():
		return
	var tile_states: Array = Array(_active_undo_transaction.get("tile_states", []))
	if tile_states.is_empty():
		cancel_empty_undo_transaction()
		return
	var undo_transaction: Dictionary = _active_undo_transaction.duplicate(true)
	undo_transaction.erase("grid_lookup")
	_push_undo_entry(undo_transaction)
	_active_undo_transaction.clear()


func cancel_empty_undo_transaction() -> void:
	_active_undo_transaction.clear()
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_TOOL_STATE)


func _build_undo_transaction(action_name: String) -> Dictionary:
	return {
		"transaction": true,
		"action_name": action_name.strip_edges() if not action_name.strip_edges().is_empty() else "editor_change",
		"tile_states": [],
		"grid_lookup": {},
	}


func _append_tile_state_to_transaction(transaction: Dictionary, tile_data) -> void:
	if tile_data == null or not tile_data.has_method("to_dict"):
		return
	var grid_position: Vector2i = tile_data.grid_position
	var grid_key: String = "%d,%d" % [grid_position.x, grid_position.y]
	var grid_lookup: Dictionary = Dictionary(transaction.get("grid_lookup", {}))
	if grid_lookup.has(grid_key):
		return
	var tile_states: Array = Array(transaction.get("tile_states", []))
	tile_states.append({
		"grid_position": grid_position,
		"tile_dict": tile_data.call("to_dict"),
	})
	grid_lookup[grid_key] = true
	transaction["tile_states"] = tile_states
	transaction["grid_lookup"] = grid_lookup


func _push_undo_entry(undo_state: Dictionary) -> void:
	if undo_state.is_empty():
		return
	_undo_stack.append(undo_state)
	while _undo_stack.size() > MAX_UNDO_STACK_SIZE:
		_undo_stack.pop_front()
	_last_undo_state = undo_state
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_TOOL_STATE)


func _store_undo_state(tile_data) -> void:
	record_tile_before_change(tile_data)


func _restore_tile_from_undo_state(undo_state: Dictionary) -> Array[Vector2i]:
	var restored_grids: Array[Vector2i] = []
	var tile_states: Array = Array(undo_state.get("tile_states", []))
	if tile_states.is_empty() and undo_state.has("tile_dict"):
		tile_states = [{
			"grid_position": undo_state.get("grid_position", Vector2i(-1, -1)),
			"tile_dict": undo_state.get("tile_dict", {}),
		}]

	for tile_state_variant in tile_states:
		var tile_state: Dictionary = Dictionary(tile_state_variant)
		var grid_position: Vector2i = tile_state.get("grid_position", Vector2i(-1, -1))
		var tile_dict: Dictionary = Dictionary(tile_state.get("tile_dict", {}))
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position) if _terrain_map_data != null else null
		if tile_data == null or tile_dict.is_empty():
			continue
		var restored_tile = TERRAIN_TILE_DATA_SCRIPT.call("from_dict", tile_dict)
		tile_data.tile_id = restored_tile.tile_id
		tile_data.type_id = restored_tile.type_id
		tile_data.object_type_id = restored_tile.object_type_id
		tile_data.grid_position = restored_tile.grid_position
		tile_data.world_position = restored_tile.world_position
		tile_data.walkable = restored_tile.walkable
		tile_data.blocks_los = restored_tile.blocks_los
		tile_data.cover_value = restored_tile.cover_value
		tile_data.height_level = restored_tile.height_level
		tile_data.surface_type = restored_tile.surface_type
		tile_data.edge_type = restored_tile.edge_type
		tile_data.object_height = restored_tile.object_height
		tile_data.object_rotation_degrees = restored_tile.object_rotation_degrees
		tile_data.object_scale = restored_tile.object_scale
		restored_grids.append(grid_position)
	return restored_grids


func get_undo_debug_snapshot() -> Dictionary:
	var top_entry: Dictionary = Dictionary(_undo_stack[_undo_stack.size() - 1]) if not _undo_stack.is_empty() else {}
	return {
		"undo_depth": _undo_stack.size(),
		"active_transaction": not _active_undo_transaction.is_empty(),
		"active_tile_state_count": Array(_active_undo_transaction.get("tile_states", [])).size() if not _active_undo_transaction.is_empty() else 0,
		"top_action_name": String(top_entry.get("action_name", "")).strip_edges(),
		"top_tile_state_count": Array(top_entry.get("tile_states", [])).size(),
		"undo_limit": MAX_UNDO_STACK_SIZE,
	}


func _undo_last_change() -> void:
	if _undo_stack.is_empty() or _terrain_map_data == null:
		return

	var undo_state: Dictionary = Dictionary(_undo_stack.pop_back())
	_last_undo_state = Dictionary(_undo_stack[_undo_stack.size() - 1]) if not _undo_stack.is_empty() else {}
	var restored_grids: Array[Vector2i] = _restore_tile_from_undo_state(undo_state)
	if restored_grids.is_empty():
		_queue_editor_ui_refresh(EDITOR_UI_REFRESH_TOOL_STATE)
		return

	for grid_position in restored_grids:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
		if tile_data != null:
			_refresh_tile_visual(tile_data, false)
	_refresh_dirty_visual_neighborhoods(restored_grids)
	var grid_position: Vector2i = Vector2i(restored_grids[restored_grids.size() - 1])
	_set_selected_grid_position(grid_position)
	_mark_dirty(true)
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_SELECTION | EDITOR_UI_REFRESH_PROPERTIES | EDITOR_UI_REFRESH_TOOL_STATE)


func _clear_undo_history() -> void:
	_undo_stack.clear()
	_last_undo_state.clear()
	_active_undo_transaction.clear()


func _refresh_top_bar() -> void:
	var title_label := get_node_or_null("UI/TopBar/Margin/HBox/TitleLabel") as Label
	var path_label := get_node_or_null("UI/TopBar/Margin/HBox/PathLabel") as Label
	var save_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveButton") as Button
	var save_as_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveAsButton") as Button
	var undo_button := get_node_or_null("UI/TopBar/Margin/HBox/UndoButton") as Button
	if title_label != null:
		var dirty_suffix: String = " *" if _dirty else ""
		var scenario_suffix: String = " | Scenario *" if _scenario_dirty else ""
		title_label.text = "Map Editor%s%s" % [dirty_suffix, scenario_suffix]
	if path_label != null:
		var map_name: String = _get_current_map_name()
		var path_text: String = _current_map_path if not _current_map_path.is_empty() else "(unsaved)"
		path_label.text = "%s | %s" % [map_name, path_text] if not map_name.is_empty() else path_text
	if save_button != null:
		save_button.disabled = _terrain_map_data == null or _current_map_path.is_empty()
	if save_as_button != null:
		save_as_button.disabled = _terrain_map_data == null
	if undo_button != null:
		undo_button.disabled = _undo_stack.is_empty()
		undo_button.tooltip_text = "Undo last editor change (%d/%d)." % [_undo_stack.size(), MAX_UNDO_STACK_SIZE]
	_update_height_topbar_state()
	_update_patrol_topbar_state()
	_refresh_authoring_status_controls()


func _mark_dirty(is_dirty: bool) -> void:
	_dirty = is_dirty
	_queue_editor_ui_refresh(EDITOR_UI_REFRESH_TOOL_STATE)


func _adjust_camera_zoom(delta: float) -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		primary_3d_view.call("zoom_camera", delta / CAMERA_ZOOM_STEP)
		return

	var camera := _get_camera()
	if camera == null:
		return

	var next_zoom: float = clampf(camera.zoom.x + delta, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	camera.zoom = Vector2(next_zoom, next_zoom)


func _center_camera_on_map() -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		primary_3d_view.call("focus_map_center")
		return

	var camera := _get_camera()
	if camera == null or _terrain_map_data == null:
		return

	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	var center_grid := Vector2i(floori(grid_size.x * 0.5), floori(grid_size.y * 0.5))
	var center_world: Vector2 = _terrain_registry.grid_to_world(center_grid)
	camera.position = center_world


func _populate_surface_type_options() -> void:
	var option_button := _get_surface_option_button()
	if option_button == null:
		return

	option_button.clear()
	option_button.add_item(TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)
	option_button.add_item(TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD)
	option_button.add_item(TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND)
	option_button.add_item(TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK)
	option_button.add_item(TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER)
	option_button.select(0)


func _populate_edge_type_options() -> void:
	var option_button := _get_edge_type_option_button()
	if option_button == null:
		return

	option_button.clear()
	option_button.add_item("Cliff")
	option_button.add_item("Hang")
	option_button.add_item("Keine")
	option_button.select(0)


func _populate_brush_size_options() -> void:
	var option_button := _get_brush_size_option_button()
	if option_button == null:
		return

	option_button.clear()
	option_button.add_item("1x1")
	option_button.add_item("3x3")
	option_button.add_item("5x5")
	option_button.select(0)


func _configure_property_height_spinbox() -> void:
	var height_spinbox := _get_height_spinbox()
	if height_spinbox == null:
		return
	height_spinbox.min_value = 0.0
	height_spinbox.max_value = 2.0
	height_spinbox.step = 1.0


func _connect_ui_signals() -> void:
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	var save_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveButton") as Button
	var save_as_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveAsButton") as Button
	var save_as_dialog := get_node_or_null("UI/SaveAsDialog") as FileDialog
	var load_button := get_node_or_null("UI/TopBar/Margin/HBox/LoadButton") as Button
	var new_map_button := get_node_or_null("UI/TopBar/Margin/HBox/NewMapButton") as Button
	var undo_button := get_node_or_null("UI/TopBar/Margin/HBox/UndoButton") as Button
	var walkable_checkbox := _get_walkable_checkbox()
	var blocks_los_checkbox := _get_blocks_los_checkbox()
	var cover_spinbox := _get_cover_spinbox()
	var height_spinbox := _get_height_spinbox()
	var surface_option_button := _get_surface_option_button()
	var edge_type_option_button := _get_edge_type_option_button()
	var mission_slot_spinbox := _get_mission_slot_spinbox()
	var map_name_line_edit := _get_map_name_line_edit()
	var object_rotate_left_button := _get_object_rotate_left_button()
	var object_rotate_right_button := _get_object_rotate_right_button()
	var object_scale_spinbox := _get_object_scale_spinbox()
	var object_scale_reset_button := _get_object_scale_reset_button()
	var placement_scale_spinbox := _get_placement_object_scale_spinbox()
	var placement_scale_reset_button := _get_placement_object_scale_reset_button()
	var file_dialog := get_node_or_null("UI/LoadDialog") as FileDialog
	var confirm_dialog := get_node_or_null("UI/DirtyConfirmDialog") as ConfirmationDialog
	var new_map_dialog := _get_new_map_dialog()
	var tile_type_list := _get_tile_type_list()
	if brush_button != null:
		_configure_tool_button(brush_button, "B", "Brush: paint the selected palette entry onto tiles.")
		if not brush_button.toggled.is_connected(_on_brush_tool_toggled):
			brush_button.toggled.connect(_on_brush_tool_toggled)
	if save_button != null and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
	if save_as_button != null and not save_as_button.pressed.is_connected(_on_save_as_pressed):
		save_as_button.pressed.connect(_on_save_as_pressed)
	if save_as_dialog != null:
		_configure_map_save_as_dialog(save_as_dialog)
		if not save_as_dialog.file_selected.is_connected(_on_save_as_file_selected):
			save_as_dialog.file_selected.connect(_on_save_as_file_selected)
	if load_button != null and not load_button.pressed.is_connected(_on_load_pressed):
		load_button.pressed.connect(_on_load_pressed)
	if new_map_button != null and not new_map_button.pressed.is_connected(_on_new_map_pressed):
		new_map_button.pressed.connect(_on_new_map_pressed)
	if undo_button != null and not undo_button.pressed.is_connected(_on_undo_pressed):
		undo_button.pressed.connect(_on_undo_pressed)
	if walkable_checkbox != null and not walkable_checkbox.toggled.is_connected(_on_property_controls_changed):
		walkable_checkbox.toggled.connect(_on_property_controls_changed)
	if blocks_los_checkbox != null and not blocks_los_checkbox.toggled.is_connected(_on_property_controls_changed):
		blocks_los_checkbox.toggled.connect(_on_property_controls_changed)
	if cover_spinbox != null and not cover_spinbox.value_changed.is_connected(_on_property_controls_value_changed):
		cover_spinbox.value_changed.connect(_on_property_controls_value_changed)
	if height_spinbox != null and not height_spinbox.value_changed.is_connected(_on_property_controls_value_changed):
		height_spinbox.value_changed.connect(_on_property_controls_value_changed)
	if surface_option_button != null and not surface_option_button.item_selected.is_connected(_on_surface_selected):
		surface_option_button.item_selected.connect(_on_surface_selected)
	if edge_type_option_button != null and not edge_type_option_button.item_selected.is_connected(_on_edge_type_selected):
		edge_type_option_button.item_selected.connect(_on_edge_type_selected)
	if mission_slot_spinbox != null and not mission_slot_spinbox.value_changed.is_connected(_on_mission_slot_spinbox_value_changed):
		mission_slot_spinbox.value_changed.connect(_on_mission_slot_spinbox_value_changed)
	if map_name_line_edit != null:
		if not map_name_line_edit.text_submitted.is_connected(_on_map_name_text_submitted):
			map_name_line_edit.text_submitted.connect(_on_map_name_text_submitted)
		if not map_name_line_edit.focus_exited.is_connected(_on_map_name_focus_exited):
			map_name_line_edit.focus_exited.connect(_on_map_name_focus_exited)
	if object_rotate_left_button != null and not object_rotate_left_button.pressed.is_connected(_on_object_rotate_left_pressed):
		object_rotate_left_button.pressed.connect(_on_object_rotate_left_pressed)
	if object_rotate_right_button != null and not object_rotate_right_button.pressed.is_connected(_on_object_rotate_right_pressed):
		object_rotate_right_button.pressed.connect(_on_object_rotate_right_pressed)
	if object_scale_spinbox != null and not object_scale_spinbox.value_changed.is_connected(_on_object_scale_value_changed):
		object_scale_spinbox.value_changed.connect(_on_object_scale_value_changed)
	if object_scale_reset_button != null and not object_scale_reset_button.pressed.is_connected(_on_object_scale_reset_pressed):
		object_scale_reset_button.pressed.connect(_on_object_scale_reset_pressed)
	if placement_scale_spinbox != null and not placement_scale_spinbox.value_changed.is_connected(_on_placement_object_scale_value_changed):
		placement_scale_spinbox.value_changed.connect(_on_placement_object_scale_value_changed)
	if placement_scale_reset_button != null and not placement_scale_reset_button.pressed.is_connected(_on_placement_object_scale_reset_pressed):
		placement_scale_reset_button.pressed.connect(_on_placement_object_scale_reset_pressed)
	if tile_type_list != null and not tile_type_list.item_selected.is_connected(_on_tile_type_selected):
		tile_type_list.item_selected.connect(_on_tile_type_selected)
	for marker_id in EDITABLE_MARKER_IDS:
		var marker_button := _get_marker_button(marker_id)
		if marker_button != null and not marker_button.pressed.is_connected(_on_marker_assign_button_pressed.bind(marker_id)):
			marker_button.pressed.connect(_on_marker_assign_button_pressed.bind(marker_id))
	_connect_marker_editor_signals()
	if file_dialog != null:
		file_dialog.access = FileDialog.ACCESS_RESOURCES
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.current_dir = "res://maps"
		file_dialog.filters = PackedStringArray(["*.json ; JSON terrain map"])
		if not file_dialog.file_selected.is_connected(_on_load_file_selected):
			file_dialog.file_selected.connect(_on_load_file_selected)
	if confirm_dialog != null and not confirm_dialog.confirmed.is_connected(_on_dirty_confirmed):
		confirm_dialog.confirmed.connect(_on_dirty_confirmed)
	if new_map_dialog != null and not new_map_dialog.confirmed.is_connected(_on_new_map_dialog_confirmed):
		new_map_dialog.confirmed.connect(_on_new_map_dialog_confirmed)


func _on_save_pressed() -> void:
	# Check if Ctrl is pressed for Save As
	if Input.is_key_pressed(KEY_CTRL):
		_open_save_as_dialog()
		return
	if _should_route_save_to_save_as():
		_open_save_as_dialog()
		return
	_save_current_map()


func _on_save_as_pressed() -> void:
	_open_save_as_dialog()


func _on_save_as_file_selected(path: String) -> void:
	if path.is_empty():
		return
	var existing_name: String = _get_current_map_name()
	_current_map_path = _normalize_map_save_path(path)
	if (
		_terrain_map_data != null
		and _terrain_map_data.has_method("set_map_name")
		and (existing_name.is_empty() or existing_name == DEFAULT_NEW_MAP_NAME)
	):
		_terrain_map_data.call("set_map_name", _current_map_path.get_file().get_basename())
	_refresh_map_settings_panel()
	_save_current_map()


func _open_save_as_dialog() -> void:
	_commit_map_name_editor_text(false)
	var save_as_dialog := get_node_or_null("UI/SaveAsDialog") as FileDialog
	if save_as_dialog == null:
		return
	_configure_map_save_as_dialog(save_as_dialog)
	save_as_dialog.current_dir = _get_map_save_as_start_dir()
	save_as_dialog.current_file = _build_suggested_map_filename()
	save_as_dialog.popup_centered_ratio(0.65)


func _configure_map_save_as_dialog(save_as_dialog: FileDialog) -> void:
	if save_as_dialog == null:
		return
	save_as_dialog.access = FileDialog.ACCESS_RESOURCES
	save_as_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_as_dialog.root_subfolder = ""
	save_as_dialog.filters = PackedStringArray(["*.json ; JSON terrain map"])


func _get_map_save_as_start_dir() -> String:
	var current_directory: String = _current_map_path.strip_edges().get_base_dir()
	if current_directory.begins_with("res://"):
		return current_directory
	return "res://maps"


func _should_route_save_to_save_as() -> bool:
	if _current_map_path.strip_edges().is_empty():
		return true
	var normalized_path: String = _current_map_path.strip_edges().replace("\\", "/").to_lower()
	var default_path: String = DEFAULT_NEW_MAP_PATH.replace("\\", "/").to_lower()
	if normalized_path != default_path:
		return false
	var current_name: String = _get_current_map_name().strip_edges()
	if current_name.is_empty() or current_name == DEFAULT_NEW_MAP_NAME:
		return false
	return _sanitize_file_stem(current_name) != DEFAULT_NEW_MAP_NAME


func _build_suggested_map_filename() -> String:
	var stem: String = _sanitize_file_stem(_get_current_map_name())
	if stem.is_empty() and not _current_map_path.is_empty():
		stem = _sanitize_file_stem(_current_map_path.get_file().get_basename())
	if stem.is_empty():
		stem = DEFAULT_NEW_MAP_NAME
	return "%s.json" % stem


func _normalize_map_save_path(path: String) -> String:
	var normalized_path: String = path.strip_edges().replace("\\", "/")
	if normalized_path.is_empty():
		return normalized_path
	if normalized_path.is_absolute_path():
		var localized_path: String = ProjectSettings.localize_path(normalized_path)
		if localized_path.begins_with("res://") or localized_path.begins_with("user://"):
			normalized_path = localized_path
	if normalized_path.get_extension().strip_edges().to_lower() != "json":
		normalized_path = "%s.json" % normalized_path
	return normalized_path


func _sanitize_file_stem(value: String) -> String:
	var sanitized: String = value.strip_edges().to_lower()
	if sanitized.is_empty():
		return ""
	for invalid_character in ["\\", "/", ":", "*", "?", "\"", "<", ">", "|", "."]:
		sanitized = sanitized.replace(invalid_character, "_")
	sanitized = sanitized.replace(" ", "_")
	while sanitized.contains("__"):
		sanitized = sanitized.replace("__", "_")
	sanitized = sanitized.strip_edges().trim_prefix("_").trim_suffix("_")
	return sanitized


func _get_current_map_name() -> String:
	if _terrain_map_data == null or not _terrain_map_data.has_method("get_map_name"):
		return ""
	return String(_terrain_map_data.call("get_map_name")).strip_edges()


func _commit_map_name_editor_text(mark_dirty: bool = true) -> void:
	if _is_refreshing_map_settings_controls:
		return
	if _terrain_map_data == null or not _terrain_map_data.has_method("set_map_name"):
		return
	var line_edit := _get_map_name_line_edit()
	if line_edit == null:
		return
	var next_name: String = line_edit.text.strip_edges()
	if next_name.is_empty():
		next_name = DEFAULT_NEW_MAP_NAME
	if next_name == _get_current_map_name():
		return
	_terrain_map_data.call("set_map_name", next_name)
	if mark_dirty:
		_mark_dirty(true)
	else:
		_queue_editor_ui_refresh(EDITOR_UI_REFRESH_TOOL_STATE)


func _on_map_name_text_submitted(_new_text: String) -> void:
	_commit_map_name_editor_text(true)
	_refresh_map_settings_panel()


func _on_map_name_focus_exited() -> void:
	_commit_map_name_editor_text(true)
	_refresh_map_settings_panel()


func set_tile_property_overlay_enabled(enabled: bool) -> bool:
	if _tile_property_overlay_enabled == enabled:
		return true
	_tile_property_overlay_enabled = enabled
	var overlay_button := get_node_or_null("UI/TopBar/Margin/HBox/TilePropertyOverlayButton") as Button
	if overlay_button != null and overlay_button.button_pressed != enabled:
		overlay_button.button_pressed = enabled
	if enabled:
		_rebuild_tile_property_overlay()
	else:
		_clear_tile_property_overlay()
	_refresh_authoring_status_controls()
	return true


func is_tile_property_overlay_enabled() -> bool:
	return _tile_property_overlay_enabled


func get_tile_property_overlay_debug_snapshot() -> Dictionary:
	var snapshot: Dictionary = Dictionary(MAP_EDITOR_TILE_PROPERTY_OVERLAY_SCRIPT.call("build_overlay_snapshot", _terrain_map_data, _tile_property_overlay_enabled))
	snapshot["drawn_cell_count"] = _tile_property_overlay_cells_by_grid.size()
	snapshot["rebuild_count"] = _tile_property_overlay_rebuild_count
	snapshot["dirty_refresh_count"] = _tile_property_overlay_dirty_refresh_count
	snapshot["skipped_disabled_count"] = _tile_property_overlay_skipped_disabled_count
	snapshot["last_dirty_grid_count"] = _tile_property_overlay_last_dirty_grid_count
	snapshot["batched_with_dirty_neighborhood"] = true
	return snapshot


func _ensure_tile_property_overlay() -> void:
	var existing_overlay := get_node_or_null(TILE_PROPERTY_OVERLAY_NAME) as Node2D
	if existing_overlay != null:
		return
	var overlay := Node2D.new()
	overlay.name = TILE_PROPERTY_OVERLAY_NAME
	overlay.z_index = 31
	add_child(overlay)


func _rebuild_tile_property_overlay() -> void:
	_ensure_tile_property_overlay()
	var overlay := get_node_or_null(TILE_PROPERTY_OVERLAY_NAME) as Node2D
	if overlay == null:
		return
	for child in overlay.get_children():
		child.queue_free()
	_tile_property_overlay_cells_by_grid.clear()
	_tile_property_overlay_last_dirty_grid_count = 0
	if not _tile_property_overlay_enabled:
		_tile_property_overlay_skipped_disabled_count += 1
		return
	if _terrain_map_data == null:
		return
	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		_refresh_tile_property_overlay_cell(tile_data)
	_tile_property_overlay_rebuild_count += 1


func _clear_tile_property_overlay() -> void:
	var overlay := get_node_or_null(TILE_PROPERTY_OVERLAY_NAME) as Node2D
	if overlay != null:
		for child in overlay.get_children():
			child.queue_free()
	_tile_property_overlay_cells_by_grid.clear()
	_tile_property_overlay_last_dirty_grid_count = 0


func _refresh_tile_property_overlay_for_grids(grids: Array[Vector2i]) -> void:
	if grids.is_empty():
		return
	if not _tile_property_overlay_enabled:
		_tile_property_overlay_skipped_disabled_count += 1
		return
	_ensure_tile_property_overlay()
	_tile_property_overlay_last_dirty_grid_count = grids.size()
	for grid_position in grids:
		var tile_data = _terrain_map_data.call("get_tile_at_grid", Vector2i(grid_position)) if _terrain_map_data != null else null
		_refresh_tile_property_overlay_cell(tile_data, Vector2i(grid_position))
	_tile_property_overlay_dirty_refresh_count += 1


func _refresh_tile_property_overlay_cell(tile_data, fallback_grid: Vector2i = Vector2i(-1, -1)) -> void:
	var grid_position: Vector2i = Vector2i(tile_data.grid_position) if tile_data != null else fallback_grid
	if grid_position == Vector2i(-1, -1):
		return
	var previous_node: Node = _tile_property_overlay_cells_by_grid.get(grid_position, null)
	if previous_node != null and is_instance_valid(previous_node):
		if previous_node.get_parent() != null:
			previous_node.get_parent().remove_child(previous_node)
		previous_node.queue_free()
	_tile_property_overlay_cells_by_grid.erase(grid_position)
	if tile_data == null:
		return
	var overlay := get_node_or_null(TILE_PROPERTY_OVERLAY_NAME) as Node2D
	if overlay == null:
		return
	var entry: Dictionary = Dictionary(MAP_EDITOR_TILE_PROPERTY_OVERLAY_SCRIPT.call("build_tile_entry", tile_data))
	if entry.is_empty():
		return
	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_width: float = float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH))
	var half_height: float = float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))
	var center: Vector2 = Vector2(entry.get("world_position", tile_data.world_position))
	var cell_root := Node2D.new()
	cell_root.name = "TileProperty_%d_%d" % [grid_position.x, grid_position.y]
	cell_root.set_meta("grid_position", grid_position)
	cell_root.set_meta("color_role", String(entry.get("color_role", "")))
	cell_root.set_meta("blocker_type", String(entry.get("blocker_type", "none")))
	cell_root.set_meta("wall_segment_count", int(entry.get("wall_segment_count", 0)))
	cell_root.set_meta("object_layer_state", String(entry.get("object_layer_state", "")))
	cell_root.set_meta("truth_label", String(entry.get("truth_label", "")))
	var issues_variant: Variant = entry.get("issues", PackedStringArray())
	var truth_issue_count: int = 0
	if issues_variant is PackedStringArray:
		truth_issue_count = issues_variant.size()
	elif issues_variant is Array:
		truth_issue_count = Array(issues_variant).size()
	cell_root.set_meta("truth_issue_count", truth_issue_count)
	var diamond := Polygon2D.new()
	diamond.name = "Fill"
	diamond.polygon = PackedVector2Array([
		center + Vector2(0.0, -half_height),
		center + Vector2(half_width, 0.0),
		center + Vector2(0.0, half_height),
		center + Vector2(-half_width, 0.0),
	])
	diamond.color = Color(entry.get("color", Color(1.0, 1.0, 1.0, 0.1)))
	cell_root.add_child(diamond)
	var wall_segments: Array = Array(entry.get("wall_segments", []))
	if not wall_segments.is_empty():
		var segment_root := Node2D.new()
		segment_root.name = "WallSegments"
		segment_root.z_index = 2
		for segment_index in range(wall_segments.size()):
			var segment: Dictionary = Dictionary(wall_segments[segment_index])
			var segment_start: Vector2 = _tile_property_overlay_grid_point_to_world(center, grid_position, Vector2(segment.get("segment_start", Vector2.ZERO)), half_width, half_height)
			var segment_end: Vector2 = _tile_property_overlay_grid_point_to_world(center, grid_position, Vector2(segment.get("segment_end", Vector2.ZERO)), half_width, half_height)
			var segment_line := Line2D.new()
			segment_line.name = "WallSegment_%d" % segment_index
			segment_line.width = 3.0
			segment_line.default_color = Color(1.0, 0.84, 0.16, 0.95)
			segment_line.add_point(segment_start)
			segment_line.add_point(segment_end)
			segment_root.add_child(segment_line)
		cell_root.add_child(segment_root)
	var label_text: String = String(entry.get("label", ""))
	if not label_text.is_empty():
		var label := Label.new()
		label.name = "Label"
		label.text = label_text
		label.position = center + Vector2(-half_width * 0.42, -10.0)
		label.size = Vector2(half_width * 0.84, 20.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 0.86))
		cell_root.add_child(label)
	overlay.add_child(cell_root)
	_tile_property_overlay_cells_by_grid[grid_position] = cell_root


func _tile_property_overlay_grid_point_to_world(tile_center: Vector2, tile_grid_position: Vector2i, grid_point: Vector2, half_width: float, half_height: float) -> Vector2:
	var offset: Vector2 = grid_point - Vector2(float(tile_grid_position.x), float(tile_grid_position.y))
	return tile_center + Vector2((offset.x - offset.y) * half_width, (offset.x + offset.y) * half_height)


func set_adjacency_debug_overlay_enabled(enabled: bool) -> bool:
	if _adjacency_debug_overlay_enabled == enabled:
		return true
	_adjacency_debug_overlay_enabled = enabled
	var overlay_button := get_node_or_null("UI/TopBar/Margin/HBox/AdjacencyDebugOverlayButton") as Button
	if overlay_button != null and overlay_button.button_pressed != enabled:
		overlay_button.button_pressed = enabled
	if enabled:
		_refresh_adjacency_debug_overlay_from_snapshot()
	else:
		_clear_adjacency_debug_overlay()
	_refresh_authoring_status_controls()
	return true


func is_adjacency_debug_overlay_enabled() -> bool:
	return _adjacency_debug_overlay_enabled


func get_adjacency_debug_overlay_snapshot() -> Dictionary:
	var snapshot: Dictionary = Dictionary(MAP_EDITOR_ADJACENCY_DEBUG_OVERLAY_SCRIPT.call("build_overlay_snapshot", _last_dirty_neighborhood_snapshot, _adjacency_debug_overlay_enabled, _adjacency_debug_overlay_drawn_entries_by_grid.size()))
	snapshot["rebuild_count"] = _adjacency_debug_overlay_rebuild_count
	snapshot["skipped_disabled_count"] = _adjacency_debug_overlay_skipped_disabled_count
	return snapshot


func _ensure_adjacency_debug_overlay() -> void:
	var existing_overlay := get_node_or_null(ADJACENCY_DEBUG_OVERLAY_NAME) as Node2D
	if existing_overlay != null:
		return
	var overlay := Node2D.new()
	overlay.name = ADJACENCY_DEBUG_OVERLAY_NAME
	overlay.z_index = 33
	add_child(overlay)


func _clear_adjacency_debug_overlay() -> void:
	var overlay := get_node_or_null(ADJACENCY_DEBUG_OVERLAY_NAME) as Node2D
	if overlay != null:
		for child in overlay.get_children():
			child.queue_free()
	_adjacency_debug_overlay_drawn_entries_by_grid.clear()


func _refresh_adjacency_debug_overlay_from_snapshot() -> void:
	if not _adjacency_debug_overlay_enabled:
		_adjacency_debug_overlay_skipped_disabled_count += 1
		return
	_ensure_adjacency_debug_overlay()
	var overlay := get_node_or_null(ADJACENCY_DEBUG_OVERLAY_NAME) as Node2D
	if overlay == null:
		return
	for child in overlay.get_children():
		child.queue_free()
	_adjacency_debug_overlay_drawn_entries_by_grid.clear()
	var entries: Array = Array(MAP_EDITOR_ADJACENCY_DEBUG_OVERLAY_SCRIPT.call("build_entries_from_snapshot", _last_dirty_neighborhood_snapshot))
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var grid_position := Vector2i(entry.get("grid_position", Vector2i(-1, -1)))
		if grid_position == Vector2i(-1, -1):
			continue
		var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position) if _terrain_map_data != null else null
		if tile_data == null:
			continue
		_add_adjacency_debug_entry_visual(overlay, tile_data, entry)
	_adjacency_debug_overlay_rebuild_count += 1


func _add_adjacency_debug_entry_visual(overlay: Node2D, tile_data, entry: Dictionary) -> void:
	if overlay == null or tile_data == null:
		return
	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_width: float = float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH))
	var half_height: float = float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))
	var center: Vector2 = tile_data.world_position
	var grid_position := Vector2i(entry.get("grid_position", tile_data.grid_position))
	var role: String = String(entry.get("role", ""))
	var color: Color = Color(entry.get("color", Color(1.0, 1.0, 1.0, 0.35)))
	var root := Node2D.new()
	root.name = "Adjacency_%s_%d_%d" % [role, grid_position.x, grid_position.y]
	root.set_meta("grid_position", grid_position)
	root.set_meta("role", role)
	var fill := Polygon2D.new()
	fill.name = "Fill"
	fill.polygon = PackedVector2Array([
		center + Vector2(0.0, -half_height),
		center + Vector2(half_width, 0.0),
		center + Vector2(0.0, half_height),
		center + Vector2(-half_width, 0.0),
	])
	fill.color = color
	root.add_child(fill)
	var outline := Line2D.new()
	outline.name = "Outline"
	outline.closed = true
	outline.width = 3.0 if role == "seed" else 2.0
	outline.default_color = Color(color.r, color.g, color.b, minf(color.a + 0.34, 0.95))
	outline.add_point(center + Vector2(0.0, -half_height))
	outline.add_point(center + Vector2(half_width, 0.0))
	outline.add_point(center + Vector2(0.0, half_height))
	outline.add_point(center + Vector2(-half_width, 0.0))
	root.add_child(outline)
	var label := Label.new()
	label.name = "Label"
	label.text = String(entry.get("label", ""))
	label.position = center + Vector2(-10.0, -10.0)
	label.size = Vector2(20.0, 20.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.98, 1.0, 1.0, 0.92))
	root.add_child(label)
	overlay.add_child(root)
	_adjacency_debug_overlay_drawn_entries_by_grid["%s:%s" % [role, str(grid_position)]] = root


func _ensure_patrol_overlay() -> void:
	var existing_overlay := get_node_or_null(PATROL_OVERLAY_NAME) as Node2D
	if existing_overlay != null:
		return
	var overlay := Node2D.new()
	overlay.name = PATROL_OVERLAY_NAME
	overlay.z_index = 35
	add_child(overlay)


func preview_patrol_route_for_reference(reference_id: String, source_type: String = "selection") -> bool:
	var snapshot: Dictionary = Dictionary(MAP_EDITOR_PATROL_PREVIEW_SCRIPT.call("build_preview_snapshot_for_reference", _terrain_map_data, _mission_scenario, reference_id, source_type))
	return _set_patrol_route_preview_from_snapshot(snapshot, true)


func get_patrol_route_preview_snapshot() -> Dictionary:
	if _last_patrol_preview_snapshot.is_empty():
		return Dictionary(MAP_EDITOR_PATROL_PREVIEW_SCRIPT.call("build_preview_snapshot", _terrain_map_data, "", "", ""))
	return _last_patrol_preview_snapshot.duplicate(true)


func get_patrol_authoring_reference_ids() -> PackedStringArray:
	return _build_patrol_authoring_reference_ids()


func set_patrol_authoring_reference(reference_id: String) -> bool:
	var normalized_reference_id: String = reference_id.strip_edges()
	if normalized_reference_id.is_empty() or not _build_patrol_authoring_reference_ids().has(normalized_reference_id):
		return false
	_patrol_spawn_id = normalized_reference_id
	_refresh_patrol_spawn_selector()
	preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	_refresh_patrol_overlay()
	_refresh_authoring_status_controls()
	return true


func _set_patrol_route_preview_from_snapshot(snapshot: Dictionary, queue_visual_refresh: bool = true) -> bool:
	var is_active: bool = bool(snapshot.get("active", false))
	var next_path_id: String = String(snapshot.get("patrol_path_id", "")).strip_edges() if is_active else ""
	if next_path_id == _patrol_preview_path_id and _last_patrol_preview_snapshot == snapshot:
		return is_active
	_patrol_preview_path_id = next_path_id
	_last_patrol_preview_snapshot = snapshot.duplicate(true)
	if queue_visual_refresh:
		_refresh_patrol_overlay()
	return is_active


func _clear_patrol_route_preview(queue_visual_refresh: bool = true) -> void:
	_patrol_preview_path_id = ""
	_last_patrol_preview_snapshot = Dictionary(MAP_EDITOR_PATROL_PREVIEW_SCRIPT.call("build_preview_snapshot", _terrain_map_data, "", "", ""))
	if queue_visual_refresh:
		_refresh_patrol_overlay()


func _restore_selected_patrol_route_preview() -> void:
	if _patrol_tool_enabled and not _patrol_spawn_id.strip_edges().is_empty():
		if preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn"):
			return
	_clear_patrol_route_preview(true)


func _update_patrol_route_preview_at_world_position(world_position: Vector2) -> void:
	var hit: Dictionary = Dictionary(MAP_EDITOR_PATROL_PREVIEW_SCRIPT.call("find_route_reference_near_world_position", _terrain_map_data, world_position, PATROL_PICK_RADIUS, PATROL_SEGMENT_PICK_RADIUS))
	if hit.is_empty():
		_restore_selected_patrol_route_preview()
		return
	var snapshot: Dictionary = Dictionary(MAP_EDITOR_PATROL_PREVIEW_SCRIPT.call(
		"build_preview_snapshot",
		_terrain_map_data,
		String(hit.get("patrol_path_id", "")),
		String(hit.get("source_id", "")),
		String(hit.get("source_type", "hover"))
	))
	if not _set_patrol_route_preview_from_snapshot(snapshot, true):
		_restore_selected_patrol_route_preview()


func _refresh_patrol_overlay() -> void:
	var overlay := get_node_or_null(PATROL_OVERLAY_NAME) as Node2D
	if overlay == null or _terrain_map_data == null:
		_queue_3d_map_refresh()
		return
	for child in overlay.get_children():
		child.queue_free()
	var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
	var path_ids: Array = patrol_paths.keys()
	path_ids.sort()
	var active_path_id: String = _resolve_patrol_edit_path_id(_patrol_spawn_id)
	for spawn_id_variant in path_ids:
		var spawn_id: String = String(spawn_id_variant).strip_edges()
		if spawn_id.is_empty():
			continue
		var is_active_spawn: bool = spawn_id == active_path_id
		var is_preview: bool = spawn_id == _patrol_preview_path_id
		var base_color: Color = Color(0.25, 0.75, 0.3, 0.5)
		if is_preview:
			base_color = Color(1.0, 0.82, 0.18, 0.96)
		elif is_active_spawn:
			base_color = Color(0.25, 0.9, 0.35, 0.9)
		var path_points: Array = Array(_terrain_map_data.call("get_patrol_path", spawn_id))
		if path_points.size() >= 2:
			var line := Line2D.new()
			line.width = 4.0 if is_preview else 2.0
			line.default_color = base_color
			line.z_index = 4 if is_preview else 0
			for point_variant in path_points:
				line.add_point(Vector2(point_variant))
			overlay.add_child(line)
			if is_preview:
				_add_patrol_route_direction_arrows(overlay, path_points, base_color)
		for waypoint_index in range(path_points.size()):
			var waypoint_position: Vector2 = Vector2(path_points[waypoint_index])
			var marker := Line2D.new()
			marker.width = 3.0 if is_preview else 2.0
			marker.default_color = base_color
			marker.z_index = 5 if is_preview else 1
			marker.add_point(waypoint_position + Vector2(-5.0, 0.0))
			marker.add_point(waypoint_position + Vector2(5.0, 0.0))
			marker.add_point(waypoint_position + Vector2(0.0, 0.0))
			marker.add_point(waypoint_position + Vector2(0.0, -5.0))
			marker.add_point(waypoint_position + Vector2(0.0, 5.0))
			overlay.add_child(marker)
			var label := Label.new()
			label.position = waypoint_position + Vector2(6.0, -12.0)
			label.text = "%d" % [waypoint_index + 1] if is_preview else "%s:%d" % [spawn_id, waypoint_index + 1]
			label.modulate = base_color
			label.z_index = 6 if is_preview else 2
			label.add_theme_font_size_override("font_size", 13 if is_preview else 10)
			overlay.add_child(label)
	_sync_patrol_preview_to_primary_view()
	_queue_3d_map_refresh()


func _add_patrol_route_direction_arrows(overlay: Node2D, path_points: Array, color: Color) -> void:
	if overlay == null:
		return
	for segment_index in range(1, path_points.size()):
		var start_position: Vector2 = Vector2(path_points[segment_index - 1])
		var end_position: Vector2 = Vector2(path_points[segment_index])
		var direction: Vector2 = end_position - start_position
		if direction.length_squared() <= 0.001:
			continue
		direction = direction.normalized()
		var tip: Vector2 = start_position.lerp(end_position, 0.62)
		var back: Vector2 = tip - direction * 12.0
		var side: Vector2 = direction.rotated(PI * 0.5) * 5.0
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([tip, back + side, back - side])
		arrow.color = color
		arrow.z_index = 7
		overlay.add_child(arrow)


func _sync_patrol_preview_to_primary_view() -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view == null or not primary_3d_view.has_method("set_editor_patrol_preview_path_id"):
		return
	primary_3d_view.call("set_editor_patrol_preview_path_id", _patrol_preview_path_id)


func _refresh_patrol_spawn_selector() -> void:
	var spawn_selector := get_node_or_null("UI/TopBar/Margin/HBox/PatrolSpawnOption") as OptionButton
	if spawn_selector == null:
		return
	spawn_selector.clear()
	var reference_ids: PackedStringArray = _build_patrol_authoring_reference_ids()
	for spawn_id in reference_ids:
		spawn_selector.add_item(spawn_id)
		spawn_selector.set_item_metadata(spawn_selector.item_count - 1, spawn_id)
	var selected_index: int = -1
	for index in range(spawn_selector.item_count):
		if String(spawn_selector.get_item_metadata(index)) == _patrol_spawn_id:
			selected_index = index
			break
	if selected_index < 0 and spawn_selector.item_count > 0:
		selected_index = 0
		_patrol_spawn_id = String(spawn_selector.get_item_metadata(selected_index)).strip_edges()
	spawn_selector.select(selected_index)


func _build_patrol_authoring_reference_ids() -> PackedStringArray:
	var result: Array = []
	var seen: Dictionary = {}
	if _mission_scenario != null and _mission_scenario.has_method("get_enemy_ids"):
		for enemy_id in PackedStringArray(_mission_scenario.call("get_enemy_ids")):
			_append_unique_patrol_reference_id(result, seen, enemy_id)
		for binding_variant in Array(_mission_scenario.get("patrol_bindings")):
			if typeof(binding_variant) != TYPE_DICTIONARY:
				continue
			var binding: Dictionary = Dictionary(binding_variant)
			_append_unique_patrol_reference_id(result, seen, binding.get("target_id", ""))
			_append_unique_patrol_reference_id(result, seen, binding.get("binding_id", ""))
			_append_unique_patrol_reference_id(result, seen, binding.get("patrol_path_id", ""))
	if _terrain_map_data != null and _terrain_map_data.has_method("get_patrol_paths"):
		var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
		var path_ids: Array = patrol_paths.keys()
		path_ids.sort()
		for path_id_variant in path_ids:
			_append_unique_patrol_reference_id(result, seen, path_id_variant)
	for fallback_id in PATROL_SPAWN_IDS:
		_append_unique_patrol_reference_id(result, seen, fallback_id)
	var packed := PackedStringArray()
	for reference_id_variant in result:
		packed.append(String(reference_id_variant))
	return packed


func _append_unique_patrol_reference_id(result: Array, seen: Dictionary, id_value: Variant) -> void:
	var reference_id: String = String(id_value).strip_edges()
	if reference_id.is_empty() or seen.has(reference_id):
		return
	result.append(reference_id)
	seen[reference_id] = true


func _resolve_patrol_edit_path_id(reference_id: String) -> String:
	var normalized_reference_id: String = reference_id.strip_edges()
	if normalized_reference_id.is_empty():
		return ""
	var resolved: Dictionary = Dictionary(MAP_EDITOR_PATROL_PREVIEW_SCRIPT.call("resolve_route_reference", _terrain_map_data, _mission_scenario, normalized_reference_id))
	var patrol_path_id: String = String(resolved.get("patrol_path_id", "")).strip_edges()
	return patrol_path_id if not patrol_path_id.is_empty() else normalized_reference_id


func _update_patrol_topbar_state() -> void:
	var spawn_selector := get_node_or_null("UI/TopBar/Margin/HBox/PatrolSpawnOption") as OptionButton
	var clear_button := get_node_or_null("UI/TopBar/Margin/HBox/ClearPatrolButton") as Button
	if spawn_selector != null:
		spawn_selector.disabled = not _patrol_tool_enabled
	if clear_button != null:
		clear_button.disabled = not _patrol_tool_enabled


func _handle_patrol_left_click(world_position: Vector2, remove_mode: bool) -> void:
	if _terrain_map_data == null or _patrol_spawn_id.is_empty():
		return
	var waypoint_index: int = _find_patrol_waypoint_index_at(world_position)
	if remove_mode:
		if waypoint_index >= 0:
			_remove_patrol_waypoint(waypoint_index)
		return
	if waypoint_index >= 0:
		_dragged_patrol_waypoint_index = waypoint_index
		_move_patrol_waypoint(waypoint_index, world_position)
		return
	_add_patrol_waypoint(world_position)


func _find_patrol_waypoint_index_at(world_position: Vector2) -> int:
	return int(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("find_waypoint_index_at", _terrain_map_data, _resolve_patrol_edit_path_id(_patrol_spawn_id), world_position, PATROL_PICK_RADIUS))


func _add_patrol_waypoint(world_position: Vector2) -> void:
	var snapped_position = _snap_world_position_to_tile_center(world_position)
	if snapped_position == null:
		return
	if not bool(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("add_waypoint", _terrain_map_data, _resolve_patrol_edit_path_id(_patrol_spawn_id), Vector2(snapped_position))):
		return
	_mark_dirty(true)
	preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	_refresh_patrol_overlay()
	_queue_3d_map_refresh()


func _move_patrol_waypoint(index: int, world_position: Vector2) -> void:
	var snapped_position = _snap_world_position_to_tile_center(world_position)
	if snapped_position == null:
		return
	if not bool(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("move_waypoint", _terrain_map_data, _resolve_patrol_edit_path_id(_patrol_spawn_id), index, Vector2(snapped_position))):
		return
	_mark_dirty(true)
	preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	_refresh_patrol_overlay()
	_queue_3d_map_refresh()


func _remove_patrol_waypoint(index: int) -> void:
	if not bool(MAP_EDITOR_PATROL_TOOL_SCRIPT.call("remove_waypoint", _terrain_map_data, _resolve_patrol_edit_path_id(_patrol_spawn_id), index)):
		return
	_mark_dirty(true)
	preview_patrol_route_for_reference(_patrol_spawn_id, "selected_spawn")
	_refresh_patrol_overlay()
	_queue_3d_map_refresh()


func _on_load_pressed() -> void:
	if _dirty:
		_open_dirty_confirmation("load")
		return

	_open_load_dialog()


func _on_new_map_pressed() -> void:
	if _dirty:
		_open_dirty_confirmation("new")
		return

	_open_new_map_dialog()


func _on_undo_pressed() -> void:
	_undo_last_change()


func _on_property_controls_changed(_value: bool) -> void:
	_apply_property_controls_to_selected_tile()


func _on_property_controls_value_changed(_value: float) -> void:
	_apply_property_controls_to_selected_tile()


func _on_mission_slot_spinbox_value_changed(value: float) -> void:
	if _is_refreshing_map_settings_controls or _terrain_map_data == null:
		return
	var next_slot_count: int = clampi(int(round(value)), MIN_MISSION_SLOT_COUNT, MAX_MISSION_SLOT_COUNT)
	if int(_terrain_map_data.call("get_mission_slot_count")) == next_slot_count:
		return
	_terrain_map_data.call("set_mission_slot_count", next_slot_count)
	_mark_dirty(true)
	_refresh_map_settings_panel()


func _on_marker_assign_button_pressed(marker_id: String) -> void:
	if _terrain_map_data == null:
		return
	var tile_data = _get_selected_tile()
	if tile_data == null:
		_set_marker_feedback("Select a tile first before assigning this marker.")
		return
	_terrain_map_data.call("set_marker_position", marker_id, tile_data.world_position)
	_set_marker_feedback("Marker assigned to selected tile.")
	_mark_dirty(true)
	_refresh_map_settings_panel()


func _on_surface_selected(_index: int) -> void:
	var option_button := _get_surface_option_button()
	if option_button != null and option_button.selected >= 0:
		_last_selected_surface_type = option_button.get_item_text(option_button.selected)
	_apply_property_controls_to_selected_tile()


func _on_edge_type_selected(_index: int) -> void:
	var option_button := _get_edge_type_option_button()
	if option_button != null and option_button.selected >= 0:
		# Index 0 = "Cliff", 1 = "Hang", 2 = "Keine"
		match option_button.selected:
			0:
				_last_selected_edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
			1:
				_last_selected_edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
			2:
				_last_selected_edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	_apply_property_controls_to_selected_tile()


func _on_tile_type_selected(index: int) -> void:
	var tile_type_list := _get_tile_type_list()
	if tile_type_list == null or _tile_catalog == null:
		return

	if index < 0 or index >= tile_type_list.item_count:
		_selected_type_id = ""
		_refresh_palette_selection_visual()
		_refresh_palette_workflow_controls()
		return

	_selected_type_id = String(tile_type_list.get_item_metadata(index))
	if _selected_type_id.begins_with("__group:"):
		_on_tile_type_deselected()
		return
	if _selected_type_id.is_empty():
		var type_ids: Array[String] = _tile_catalog.get_type_ids()
		if index < 0 or index >= type_ids.size():
			return
		_selected_type_id = type_ids[index]
	_remember_palette_recent_type_id(_selected_type_id)

	# Auto-enable brush when a type is selected
	_clear_height_tool()
	_network_drag_tool_enabled = false
	_clear_network_drag_preview()
	_eraser_tool_enabled = false
	var eraser_button := _get_eraser_tool_button()
	if eraser_button != null and eraser_button.button_pressed:
		eraser_button.button_pressed = false
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	if brush_button != null and not brush_button.button_pressed:
		brush_button.button_pressed = true
	if _marker_tool_enabled:
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
	_refresh_palette_selection_visual()
	_refresh_palette_workflow_controls()
	_refresh_palette_filter_controls()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func set_palette_type_for_authoring(type_id: String) -> bool:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_type(normalized_type_id):
		return false
	_selected_type_id = normalized_type_id
	_remember_palette_recent_type_id(normalized_type_id)
	var type_group: String = _get_palette_group_for_type(normalized_type_id)
	if not type_group.is_empty() and _active_palette_group_id != type_group:
		_active_palette_group_id = type_group
		_populate_tile_palette()
	else:
		_refresh_palette_selection_visual()
		_refresh_palette_workflow_controls()
	_clear_height_tool()
	_network_drag_tool_enabled = false
	_clear_network_drag_preview()
	_eraser_tool_enabled = false
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	if brush_button != null and not brush_button.button_pressed:
		brush_button.button_pressed = true
	_refresh_runtime_builder_workbench_controls()
	_refresh_palette_filter_controls()
	_refresh_authoring_status_controls()
	return true


# Deselect palette item to enter select mode
func _on_tile_type_deselected() -> void:
	var tile_type_list := _get_tile_type_list()
	if tile_type_list != null:
		for i in range(tile_type_list.item_count):
			tile_type_list.deselect(i)
	_selected_type_id = ""
	_hide_hover_preview()
	_refresh_palette_selection_visual()
	_refresh_palette_workflow_controls()
	_refresh_palette_filter_controls()
	_refresh_runtime_builder_workbench_controls()
	_refresh_authoring_status_controls()


func _on_load_file_selected(path: String) -> void:
	_load_map(path)


func _on_dirty_confirmed() -> void:
	match _pending_dialog_action:
		"load":
			_open_load_dialog()
		"new":
			_open_new_map_dialog()

	_pending_dialog_action = ""


func _open_load_dialog() -> void:
	var file_dialog := get_node_or_null("UI/LoadDialog") as FileDialog
	if file_dialog == null:
		return

	file_dialog.current_dir = "res://maps"
	file_dialog.popup_centered_ratio(0.65)


func _open_new_map_dialog() -> void:
	var new_map_dialog := _get_new_map_dialog()
	var width_spinbox := _get_new_map_width_spinbox()
	var height_spinbox := _get_new_map_height_spinbox()
	if new_map_dialog == null or width_spinbox == null or height_spinbox == null:
		_create_new_map(DEFAULT_NEW_MAP_GRID_SIZE)
		return

	width_spinbox.value = DEFAULT_NEW_MAP_GRID_SIZE.x
	height_spinbox.value = DEFAULT_NEW_MAP_GRID_SIZE.y
	new_map_dialog.popup_centered()


func _on_new_map_dialog_confirmed() -> void:
	var width_spinbox := _get_new_map_width_spinbox()
	var height_spinbox := _get_new_map_height_spinbox()
	var grid_width := DEFAULT_NEW_MAP_GRID_SIZE.x
	var grid_height := DEFAULT_NEW_MAP_GRID_SIZE.y
	if width_spinbox != null:
		grid_width = clampi(int(width_spinbox.value), MIN_NEW_MAP_GRID_DIMENSION, MAX_NEW_MAP_GRID_DIMENSION)
	if height_spinbox != null:
		grid_height = clampi(int(height_spinbox.value), MIN_NEW_MAP_GRID_DIMENSION, MAX_NEW_MAP_GRID_DIMENSION)

	_create_new_map(Vector2i(grid_width, grid_height))


func _open_dirty_confirmation(action_name: String) -> void:
	var confirm_dialog := get_node_or_null("UI/DirtyConfirmDialog") as ConfirmationDialog
	if confirm_dialog == null:
		return

	_pending_dialog_action = action_name
	confirm_dialog.dialog_text = "Ungespeicherte Aenderungen gehen verloren. Fortfahren?"
	confirm_dialog.popup_centered()


func _show_load_issue_dialog(issue_message: String, source_path: String) -> void:
	var dialog := get_node_or_null("UI/LoadIssueDialog") as AcceptDialog
	if dialog == null:
		return
	var shown_path: String = source_path if not source_path.is_empty() else "(unbekannt)"
	dialog.dialog_text = "Das ist eine alte Datei und wird nicht mehr unterstuetzt.\n\nDatei: %s\n\nBitte die Karte im aktuellen Format neu bauen. Der Editor hat stattdessen eine neue leere Karte geoeffnet.\n\nTechnischer Hinweis: %s" % [shown_path, issue_message]
	dialog.popup_centered()


func _ensure_3d_primary_view() -> void:
	_terrain_3d_view = MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("ensure_primary_view", self, _terrain_3d_view, PRIMARY_VIEW_LEGACY_VISIBILITY_NODES, _hover_preview)


func _get_primary_3d_view():
	_terrain_3d_view = MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("get_primary_view", self, _terrain_3d_view)
	return _terrain_3d_view


func _refresh_3d_map_view() -> void:
	_3d_refresh_queued = false
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view == null:
		return
	if primary_3d_view.has_method("set_editor_patrol_preview_path_id"):
		primary_3d_view.call("set_editor_patrol_preview_path_id", _patrol_preview_path_id)
	MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("refresh_map_view", primary_3d_view, _terrain_map_data, _selected_grids, _selected_grid_position)
	_sync_network_drag_preview_to_primary_view()
	_set_legacy_2d_map_visible(false)


func _queue_3d_map_refresh() -> void:
	if _get_primary_3d_view() == null:
		return
	if _3d_refresh_queued:
		return
	_3d_refresh_queued = true
	call_deferred("_refresh_3d_map_view")


func _update_3d_selection_visual() -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view == null:
		return
	MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("update_selection_visual", primary_3d_view, _selected_grids, _selected_grid_position)


func _set_legacy_2d_map_visible(is_visible: bool) -> void:
	MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("set_legacy_2d_map_visible", self, PRIMARY_VIEW_LEGACY_VISIBILITY_NODES, is_visible, _hover_preview)


func _clear_legacy_2d_map_children() -> void:
	MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("clear_legacy_2d_map_children", self, PRIMARY_VIEW_LEGACY_CLEAR_NODES)


func _screen_to_editor_world_position(screen_position: Vector2) -> Vector2:
	return Vector2(MAP_EDITOR_PRIMARY_VIEW_ADAPTER_SCRIPT.call("screen_to_editor_world_position", _get_primary_3d_view(), screen_position, get_global_mouse_position()))


func _get_camera() -> Camera2D:
	return get_node_or_null("Camera2D") as Camera2D


func _get_selected_tile():
	if _terrain_map_data == null:
		return null

	return _terrain_map_data.call("get_tile_at_grid", _selected_grid_position)


func _has_selected_tile() -> bool:
	return _get_selected_tile() != null


func _has_selected_type() -> bool:
	return not _selected_type_id.is_empty()


func _is_brush_enabled() -> bool:
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	return brush_button != null and brush_button.button_pressed


func _get_eraser_tool_button() -> Button:
	return get_node_or_null("UI/TopBar/Margin/HBox/EraserButton") as Button


func _get_walkable_checkbox() -> CheckBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/WalkableCheckBox") as CheckBox


func _get_blocks_los_checkbox() -> CheckBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/BlocksLosCheckBox") as CheckBox


func _get_cover_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/CoverRow/CoverSpinBox") as SpinBox


func _get_height_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/HeightRow/HeightSpinBox") as SpinBox


func _get_mission_slot_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionSlotRow/MissionSlotSpinBox") as SpinBox


func _get_map_name_line_edit() -> LineEdit:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MapNameRow/MapNameLineEdit") as LineEdit


func _get_object_rotate_left_button() -> Button:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectRotationRow/ObjectRotateLeftButton") as Button


func _get_object_rotate_right_button() -> Button:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectRotationRow/ObjectRotateRightButton") as Button


func _get_object_rotation_value_label() -> Label:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectRotationRow/ObjectRotationValueLabel") as Label


func _get_object_scale_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectScaleRow/ObjectScaleSpinBox") as SpinBox


func _get_object_scale_reset_button() -> Button:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectScaleRow/ObjectScaleResetButton") as Button


func _get_placement_object_scale_spinbox() -> SpinBox:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteSelectedPreviewRow/PaletteSelectedInfoBox/PalettePlacementScaleRow/PlacementObjectScaleSpinBox") as SpinBox


func _get_placement_object_scale_reset_button() -> Button:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteSelectedPreviewRow/PaletteSelectedInfoBox/PalettePlacementScaleRow/PlacementObjectScaleResetButton") as Button


func _get_palette_search_line_edit() -> LineEdit:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteQuickFilterRow/PaletteSearchLineEdit") as LineEdit


func _get_palette_favorite_filter_button() -> Button:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteQuickFilterRow/PaletteFavoriteFilterButton") as Button


func _get_palette_favorite_toggle_button() -> Button:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteQuickFilterRow/PaletteFavoriteToggleButton") as Button


func _get_palette_selected_preview_texture_rect() -> TextureRect:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteSelectedPreviewRow/PaletteSelectedPreviewTextureRect") as TextureRect


func _get_palette_selected_info_label() -> Label:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteSelectedPreviewRow/PaletteSelectedInfoBox/PaletteSelectedInfoLabel") as Label


func _get_add_marker_type_option_button() -> OptionButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerToolbarRow/AddMarkerTypeOption") as OptionButton


func _get_add_marker_button() -> Button:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerToolbarRow/AddMarkerButton") as Button


func _get_marker_tool_button() -> Button:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerToolbarRow/MarkerToolButton") as Button


func _get_remove_marker_button() -> Button:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerToolbarRow/RemoveMarkerButton") as Button


func _get_marker_list() -> ItemList:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerList") as ItemList


func _get_selected_marker_type_option_button() -> OptionButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/SelectedMarkerTypeRow/SelectedMarkerTypeOption") as OptionButton


func _get_marker_name_line_edit() -> LineEdit:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/SelectedMarkerNameRow/MarkerNameLineEdit") as LineEdit


func _get_marker_color_button() -> ColorPickerButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/SelectedMarkerColorRow/MarkerColorButton") as ColorPickerButton


func _get_marker_info_label() -> Label:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/MarkerInfoLabel") as Label


func _get_edge_type_option_button() -> OptionButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/EdgeTypeRow/EdgeTypeOptionButton") as OptionButton


func _get_brush_size_option_button() -> OptionButton:
	return get_node_or_null("UI/TopBar/Margin/HBox/BrushSizeOptionButton") as OptionButton


func _get_height_tool_button() -> Button:
	return get_node_or_null("UI/TopBar/Margin/HBox/HeightButton") as Button


func _get_height_mode_option_button() -> OptionButton:
	return get_node_or_null("UI/TopBar/Margin/HBox/HeightModeOption") as OptionButton


func _get_height_edge_option_button() -> OptionButton:
	return get_node_or_null("UI/TopBar/Margin/HBox/HeightEdgeOption") as OptionButton


func _get_new_map_dialog() -> ConfirmationDialog:
	return get_node_or_null("UI/NewMapDialog") as ConfirmationDialog


func _get_new_map_width_spinbox() -> SpinBox:
	return get_node_or_null("UI/NewMapDialog/Margin/VBox/WidthRow/WidthSpinBox") as SpinBox


func _get_new_map_height_spinbox() -> SpinBox:
	return get_node_or_null("UI/NewMapDialog/Margin/VBox/HeightRow/HeightSpinBox") as SpinBox


func _get_brush_radius() -> int:
	var option_button := _get_brush_size_option_button()
	if option_button == null or option_button.selected < 0:
		return 0

	# Index 0 = 1x1 (radius 0), Index 1 = 3x3 (radius 1), Index 2 = 5x5 (radius 2)
	return option_button.selected


func _get_surface_option_button() -> OptionButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/SurfaceRow/SurfaceOptionButton") as OptionButton


func _get_marker_label(marker_id: String) -> Label:
	match marker_id:
		"spawn_alpha":
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/SpawnAlphaRow/SpawnAlphaLabel") as Label
		"spawn_bravo":
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/SpawnBravoRow/SpawnBravoLabel") as Label
		"objective_point":
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectivePointRow/ObjectivePointLabel") as Label
	return null


func _get_marker_button(marker_id: String) -> Button:
	match marker_id:
		"spawn_alpha":
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/SpawnAlphaRow/SpawnAlphaButton") as Button
		"spawn_bravo":
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/SpawnBravoRow/SpawnBravoButton") as Button
		"objective_point":
			return get_node_or_null("UI/PropertyPanel/Margin/VBox/ObjectivePointRow/ObjectivePointButton") as Button
	return null


func _get_selected_surface_type() -> String:
	var option_button := _get_surface_option_button()
	if option_button == null or option_button.selected < 0:
		return _last_selected_surface_type
	return option_button.get_item_text(option_button.selected)


func _get_selected_edge_type() -> String:
	var option_button := _get_edge_type_option_button()
	if option_button == null or option_button.selected < 0:
		return _last_selected_edge_type
	match option_button.selected:
		0:
			return TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
		1:
			return TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
		2:
			return TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
	return _last_selected_edge_type


func _find_surface_option_index(surface_type: String) -> int:
	var option_button := _get_surface_option_button()
	if option_button == null:
		return 0

	for index in range(option_button.item_count):
		if option_button.get_item_text(index) == surface_type:
			return index

	return 0


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _load_tile_catalog() -> void:
	_tile_catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")


func _populate_tile_palette() -> void:
	var tile_type_list := _get_tile_type_list()
	var palette_groups_root := _get_palette_groups_root()
	var palette_groups_compat_root := _get_palette_groups_compat_root()
	if tile_type_list == null or _tile_catalog == null:
		return

	var types_by_group: Dictionary = {}
	var all_types: Array = []
	for tile_type in _tile_catalog.get_all_types():
		all_types.append(tile_type)
		var palette_group: String = String(tile_type.get("palette_group", "default")).strip_edges().to_lower()
		if palette_group.is_empty():
			palette_group = "default"
		var group_types: Array = Array(types_by_group.get(palette_group, []))
		group_types.append(tile_type)
		types_by_group[palette_group] = group_types
	types_by_group["all"] = all_types

	var available_group_ids: PackedStringArray = PackedStringArray()
	if not all_types.is_empty():
		available_group_ids.append("all")
	for group in _tile_catalog.get_palette_groups():
		var group_id: String = String(Dictionary(group).get("group_id", "")).strip_edges().to_lower()
		if group_id.is_empty() or not types_by_group.has(group_id):
			continue
		available_group_ids.append(group_id)
	if _active_palette_group_id.is_empty() or not available_group_ids.has(_active_palette_group_id):
		_active_palette_group_id = available_group_ids[0] if not available_group_ids.is_empty() else ""

	tile_type_list.clear()
	tile_type_list.visible = true
	if palette_groups_root != null:
		palette_groups_root.visible = true
		for child in palette_groups_root.get_children():
			palette_groups_root.remove_child(child)
			child.queue_free()
	if palette_groups_compat_root != null:
		for child in palette_groups_compat_root.get_children():
			palette_groups_compat_root.remove_child(child)
			child.queue_free()
	if palette_groups_root != null:
		if available_group_ids.has("all"):
			var all_button := _create_palette_group_button("all", "Alle", _active_palette_group_id == "all", "Alle Palette-Assets anzeigen.", true)
			palette_groups_root.add_child(all_button)
			_add_palette_group_compat_button(palette_groups_compat_root, "all", "Alle", _active_palette_group_id == "all", "Alle Palette-Assets anzeigen.")
		for group in _tile_catalog.get_palette_groups():
			var group_dict: Dictionary = Dictionary(group)
			var group_id: String = String(group_dict.get("group_id", "")).strip_edges().to_lower()
			if group_id.is_empty() or not types_by_group.has(group_id):
				continue
			var group_text: String = String(group_dict.get("display_name", group_id.capitalize()))
			var group_button := _create_palette_group_button(group_id, group_text, group_id == _active_palette_group_id, "Filter palette group: %s" % group_text, true)
			palette_groups_root.add_child(group_button)
			_add_palette_group_compat_button(palette_groups_compat_root, group_id, group_text, group_id == _active_palette_group_id, "Filter palette group: %s" % group_text)

	var visible_types: Array = []
	var palette_source_types: Array = all_types if _palette_favorites_filter_enabled else Array(types_by_group.get(_active_palette_group_id, []))
	for tile_type_variant in palette_source_types:
		var tile_type: Dictionary = Dictionary(tile_type_variant)
		var type_id: String = String(tile_type.get("type_id", "")).strip_edges().to_lower()
		if _palette_favorites_filter_enabled and not _palette_type_matches_fast_filter(type_id):
			continue
		if not _palette_type_matches_search(tile_type, _palette_search_query):
			continue
		visible_types.append(tile_type)
	visible_types.sort_custom(_sort_palette_type_dicts)
	visible_types = _rank_palette_types_for_workflow(visible_types)
	var visible_type_ids: PackedStringArray = PackedStringArray()
	for tile_type in visible_types:
		var type_id := String(Dictionary(tile_type).get("type_id", ""))
		var display_name := String(Dictionary(tile_type).get("display_name", type_id))
		tile_type_list.add_item(display_name, _get_palette_preview_texture(type_id))
		tile_type_list.set_item_metadata(tile_type_list.item_count - 1, type_id)
		if not type_id.is_empty():
			visible_type_ids.append(type_id)
	if not visible_type_ids.has(_selected_type_id):
		_selected_type_id = String(visible_type_ids[0]) if not visible_type_ids.is_empty() else ""
	_refresh_palette_selection_visual()
	_refresh_palette_workflow_controls()
	_refresh_palette_filter_controls()


func _on_palette_group_button_pressed(group_id: String) -> void:
	_active_palette_group_id = group_id.strip_edges().to_lower()
	_populate_tile_palette()
	_refresh_palette_workflow_controls()
	_refresh_authoring_status_controls()


func _create_palette_group_button(group_id: String, label: String, selected: bool, tooltip_text: String, connect_signal: bool) -> Button:
	var button := Button.new()
	button.name = "PaletteGroup_%s" % group_id.strip_edges().to_lower()
	button.text = label
	button.toggle_mode = true
	button.button_pressed = selected
	button.tooltip_text = tooltip_text
	_configure_palette_group_button(button, selected)
	if connect_signal:
		button.pressed.connect(_on_palette_group_button_pressed.bind(group_id))
	return button


func _add_palette_group_compat_button(root: Container, group_id: String, label: String, selected: bool, tooltip_text: String) -> void:
	if root == null or root == _get_palette_groups_root():
		return
	var button := _create_palette_group_button(group_id, label, selected, tooltip_text, false)
	root.add_child(button)


func _sort_palette_type_dicts(a: Dictionary, b: Dictionary) -> bool:
	var a_type_id: String = String(a.get("type_id", "")).strip_edges().to_lower()
	var b_type_id: String = String(b.get("type_id", "")).strip_edges().to_lower()
	var a_name: String = String(a.get("display_name", a_type_id)).strip_edges().to_lower()
	var b_name: String = String(b.get("display_name", b_type_id)).strip_edges().to_lower()
	if a_name == b_name:
		return a_type_id < b_type_id
	return a_name < b_name


func _get_palette_type_display_name(type_id: String) -> String:
	var normalized_type_id: String = type_id.strip_edges()
	if normalized_type_id.is_empty():
		return ""
	if _tile_catalog != null and _tile_catalog.has_method("get_display_name"):
		return String(_tile_catalog.call("get_display_name", normalized_type_id))
	return normalized_type_id


func _get_palette_group_for_type(type_id: String) -> String:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty() or _tile_catalog == null or not _tile_catalog.has_method("get_type"):
		return ""
	var entry: Dictionary = Dictionary(_tile_catalog.call("get_type", normalized_type_id))
	return String(entry.get("palette_group", "")).strip_edges().to_lower()


func _get_palette_group_display_name(group_id: String) -> String:
	var normalized_group_id: String = group_id.strip_edges().to_lower()
	if normalized_group_id.is_empty():
		return ""
	if normalized_group_id == "all":
		return "Alle"
	if _tile_catalog != null:
		for group in _tile_catalog.get_palette_groups():
			var group_dict: Dictionary = Dictionary(group)
			if String(group_dict.get("group_id", "")).strip_edges().to_lower() == normalized_group_id:
				return String(group_dict.get("display_name", normalized_group_id.capitalize()))
	return normalized_group_id.capitalize()


func _refresh_palette_workflow_controls() -> void:
	var preview_rect := _get_palette_selected_preview_texture_rect()
	var info_label := _get_palette_selected_info_label()
	var placement_scale_spinbox := _get_placement_object_scale_spinbox()
	if placement_scale_spinbox != null and not is_equal_approx(float(placement_scale_spinbox.value), _placement_object_scale):
		placement_scale_spinbox.value = _placement_object_scale
	if preview_rect == null and info_label == null:
		return
	if _selected_type_id.is_empty():
		if preview_rect != null:
			preview_rect.texture = null
		if info_label != null:
			info_label.text = "Kein Asset"
		return
	var type_display_name: String = _get_palette_type_display_name(_selected_type_id)
	var group_display_name: String = _get_palette_group_display_name(_get_palette_group_for_type(_selected_type_id))
	if preview_rect != null:
		preview_rect.texture = _get_palette_preview_texture(_selected_type_id)
	if info_label != null:
		info_label.text = "%s\n%s\nScale %.2f" % [
			type_display_name,
			group_display_name if not group_display_name.is_empty() else "Palette",
			_placement_object_scale,
		]


func _configure_palette_group_button(button: Button, selected: bool) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(0.0, PALETTE_GROUP_BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.085, 0.12, 0.13, 0.92)
	normal_style.border_color = Color(0.18, 0.32, 0.34, 0.72)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	var hover_style := normal_style.duplicate() as StyleBoxFlat
	if hover_style != null:
		hover_style.bg_color = Color(0.12, 0.18, 0.19, 0.96)
	var pressed_style := normal_style.duplicate() as StyleBoxFlat
	if pressed_style != null:
		pressed_style.bg_color = Color(0.78, 0.64, 0.16, 0.96)
		pressed_style.border_color = Color(1.0, 0.82, 0.24, 1.0)
	button.add_theme_stylebox_override("normal", pressed_style if selected and pressed_style != null else normal_style)
	if hover_style != null:
		button.add_theme_stylebox_override("hover", hover_style)
	if pressed_style != null:
		button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_color_override("font_color", Color(0.86, 0.94, 0.95, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.07, 0.03, 1.0))
	button.add_theme_font_size_override("font_size", 11)


func _get_palette_preview_texture(type_id: String) -> Texture2D:
	var normalized_type_id: String = type_id.strip_edges().to_lower()
	if normalized_type_id.is_empty():
		return _get_generated_palette_preview_texture("default", Color(0.45, 0.52, 0.55, 1.0))
	if _palette_preview_textures.has(normalized_type_id):
		return _palette_preview_textures[normalized_type_id] as Texture2D
	if _tile_catalog != null:
		var catalog_texture: Texture2D = _tile_catalog.get_texture(normalized_type_id)
		if catalog_texture != null:
			var thumbnail: Texture2D = _get_thumbnail_palette_preview_texture(catalog_texture, normalized_type_id)
			_palette_preview_textures[normalized_type_id] = thumbnail
			_palette_preview_sources[normalized_type_id] = "catalog"
			return thumbnail
	var entry: Dictionary = Dictionary(_tile_catalog.call("get_type", normalized_type_id)) if _tile_catalog != null and _tile_catalog.has_method("get_type") else {}
	var color: Color = _get_palette_preview_color(normalized_type_id, entry)
	var generated_texture: Texture2D = _get_generated_palette_preview_texture(normalized_type_id, color, entry)
	_palette_preview_textures[normalized_type_id] = generated_texture
	_palette_preview_sources[normalized_type_id] = "generated"
	return generated_texture


func _get_thumbnail_palette_preview_texture(source_texture: Texture2D, cache_key: String) -> Texture2D:
	var key: String = "__thumbnail:%s" % cache_key.strip_edges().to_lower()
	if _palette_preview_textures.has(key):
		return _palette_preview_textures[key] as Texture2D
	var image: Image = source_texture.get_image()
	if image == null or image.is_empty():
		return source_texture
	var bounds: Rect2i = _get_opaque_image_bounds(image)
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		return source_texture
	var cropped := Image.create(bounds.size.x, bounds.size.y, false, Image.FORMAT_RGBA8)
	cropped.fill(Color(0.0, 0.0, 0.0, 0.0))
	cropped.blit_rect(image, bounds, Vector2i.ZERO)
	var max_size: Vector2i = PALETTE_PREVIEW_ICON_SIZE - Vector2i(2, 2)
	var scale: float = minf(float(max_size.x) / float(bounds.size.x), float(max_size.y) / float(bounds.size.y))
	var target_size := Vector2i(maxi(1, roundi(float(bounds.size.x) * scale)), maxi(1, roundi(float(bounds.size.y) * scale)))
	cropped.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	var thumbnail := Image.create(PALETTE_PREVIEW_ICON_SIZE.x, PALETTE_PREVIEW_ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	thumbnail.fill(Color(0.0, 0.0, 0.0, 0.0))
	var target_position := Vector2i(
		floori(float(PALETTE_PREVIEW_ICON_SIZE.x - target_size.x) * 0.5),
		floori(float(PALETTE_PREVIEW_ICON_SIZE.y - target_size.y) * 0.5)
	)
	thumbnail.blit_rect(cropped, Rect2i(Vector2i.ZERO, target_size), target_position)
	var texture := ImageTexture.create_from_image(thumbnail)
	_palette_preview_textures[key] = texture
	return texture


func _get_opaque_image_bounds(image: Image) -> Rect2i:
	var min_x: int = image.get_width()
	var min_y: int = image.get_height()
	var max_x: int = -1
	var max_y: int = -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= 0.04:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i(0, 0, image.get_width(), image.get_height())
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _get_generated_palette_preview_texture(cache_key: String, color: Color, entry: Dictionary = {}) -> Texture2D:
	var key: String = "__generated:%s" % cache_key.strip_edges().to_lower()
	if _palette_preview_textures.has(key):
		return _palette_preview_textures[key] as Texture2D
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	_paint_palette_preview_icon(image, cache_key.strip_edges().to_lower(), color, entry)
	if PALETTE_PREVIEW_ICON_SIZE != Vector2i(16, 16):
		image.resize(PALETTE_PREVIEW_ICON_SIZE.x, PALETTE_PREVIEW_ICON_SIZE.y, Image.INTERPOLATE_NEAREST)
	var texture := ImageTexture.create_from_image(image)
	_palette_preview_textures[key] = texture
	return texture


func _get_palette_preview_color(type_id: String, entry: Dictionary) -> Color:
	var palette_group: String = String(entry.get("palette_group", "")).strip_edges().to_lower()
	var placement_layer: String = String(entry.get("placement_layer", "")).strip_edges().to_lower()
	if type_id.contains("sand"):
		return Color(0.66, 0.56, 0.36, 1.0)
	if type_id.contains("grass") or type_id.contains("bush"):
		return Color(0.24, 0.56, 0.28, 1.0)
	if type_id.contains("rock") or type_id.contains("cliff"):
		return Color(0.46, 0.47, 0.43, 1.0)
	if type_id.contains("cactus"):
		return Color(0.28, 0.58, 0.36, 1.0)
	if type_id.contains("logs"):
		return Color(0.48, 0.30, 0.18, 1.0)
	if bool(entry.get("visual_surface_variant", false)) or placement_layer == "terrain":
		return Color(0.36, 0.48, 0.42, 1.0)
	if palette_group == "space_station" or type_id.begins_with("station_"):
		return Color(0.42, 0.68, 0.76, 1.0)
	if palette_group == "nature_props":
		return Color(0.32, 0.54, 0.32, 1.0)
	if placement_layer == "structure" or placement_layer == "terrain_object" or type_id.begins_with("wall_"):
		return Color(0.62, 0.58, 0.50, 1.0)
	if palette_group == "technik":
		return Color(0.45, 0.58, 0.78, 1.0)
	if palette_group == "fahrzeuge":
		return Color(0.62, 0.50, 0.34, 1.0)
	return Color(0.48, 0.50, 0.54, 1.0)


func _paint_palette_preview_icon(image: Image, type_id: String, color: Color, entry: Dictionary) -> void:
	var icon_style: String = _resolve_palette_preview_icon_style(type_id, entry)
	var light: Color = color.lightened(0.30)
	var dark: Color = color.darkened(0.38)
	var accent: Color = Color(0.44, 0.92, 1.0, 1.0) if type_id.contains("computer") or type_id.contains("display") else color.lightened(0.52)
	match icon_style:
		"station_floor":
			_paint_icon_diamond(image, 8, 2, 14, 8, 8, 14, 2, 8, color.darkened(0.04))
			_paint_icon_line(image, Vector2i(8, 2), Vector2i(14, 8), light)
			_paint_icon_line(image, Vector2i(14, 8), Vector2i(8, 14), dark)
			_paint_icon_line(image, Vector2i(8, 14), Vector2i(2, 8), dark)
			_paint_icon_line(image, Vector2i(2, 8), Vector2i(8, 2), light)
			_paint_icon_line(image, Vector2i(5, 8), Vector2i(11, 8), dark.lightened(0.22))
			_paint_icon_line(image, Vector2i(8, 5), Vector2i(8, 11), light.darkened(0.12))
		"station_wall":
			_paint_icon_diamond(image, 8, 7, 14, 11, 8, 15, 2, 11, color.darkened(0.18))
			_paint_icon_rect(image, Rect2i(4, 2, 9, 9), color)
			_paint_icon_line(image, Vector2i(4, 2), Vector2i(12, 2), light)
			_paint_icon_line(image, Vector2i(12, 2), Vector2i(12, 10), dark)
			_paint_icon_line(image, Vector2i(4, 6), Vector2i(12, 6), dark.lightened(0.18))
		"station_door":
			_paint_icon_diamond(image, 8, 7, 14, 11, 8, 15, 2, 11, color.darkened(0.18))
			_paint_icon_rect(image, Rect2i(4, 2, 9, 9), color)
			_paint_icon_rect(image, Rect2i(7, 4, 3, 7), dark)
			_paint_icon_line(image, Vector2i(7, 4), Vector2i(9, 4), accent)
		"computer":
			_paint_icon_rect(image, Rect2i(3, 9, 10, 4), dark)
			_paint_icon_rect(image, Rect2i(5, 3, 7, 6), color)
			_paint_icon_rect(image, Rect2i(6, 4, 5, 3), accent)
			_paint_icon_line(image, Vector2i(5, 3), Vector2i(11, 3), light)
		"bed":
			_paint_icon_rect(image, Rect2i(3, 6, 10, 6), color)
			_paint_icon_rect(image, Rect2i(4, 7, 3, 3), light)
			_paint_icon_line(image, Vector2i(3, 12), Vector2i(12, 12), dark)
		"crate":
			_paint_icon_rect(image, Rect2i(4, 4, 9, 9), color)
			_paint_icon_line(image, Vector2i(4, 4), Vector2i(12, 12), dark)
			_paint_icon_line(image, Vector2i(12, 4), Vector2i(4, 12), light)
			_paint_icon_line(image, Vector2i(4, 4), Vector2i(12, 4), light)
		"nature_tree":
			_paint_icon_rect(image, Rect2i(7, 8, 2, 6), Color(0.42, 0.24, 0.12, 1.0))
			_paint_icon_diamond(image, 8, 2, 13, 8, 8, 12, 3, 8, color)
		"nature_bush":
			_paint_icon_diamond(image, 7, 4, 13, 8, 7, 13, 2, 8, color)
			_paint_icon_diamond(image, 10, 3, 15, 8, 10, 12, 5, 8, color.lightened(0.12))
		"nature_cactus":
			_paint_icon_rect(image, Rect2i(7, 3, 3, 11), color)
			_paint_icon_rect(image, Rect2i(4, 7, 3, 3), color.darkened(0.08))
			_paint_icon_rect(image, Rect2i(10, 5, 3, 3), color.lightened(0.08))
			_paint_icon_line(image, Vector2i(8, 3), Vector2i(8, 13), light)
		"nature_logs":
			_paint_icon_rect(image, Rect2i(3, 6, 10, 3), color)
			_paint_icon_rect(image, Rect2i(5, 10, 10, 3), color.darkened(0.08))
			_paint_icon_line(image, Vector2i(3, 6), Vector2i(12, 6), light)
			_paint_icon_line(image, Vector2i(5, 12), Vector2i(14, 12), dark)
		"rock":
			_paint_icon_diamond(image, 8, 3, 14, 8, 9, 14, 2, 9, color)
			_paint_icon_line(image, Vector2i(8, 3), Vector2i(9, 14), dark)
			_paint_icon_line(image, Vector2i(3, 9), Vector2i(13, 8), light)
		"terrain":
			_paint_icon_diamond(image, 8, 2, 14, 8, 8, 14, 2, 8, color)
			_paint_icon_line(image, Vector2i(3, 8), Vector2i(13, 8), dark)
		_:
			_paint_icon_rect(image, Rect2i(4, 4, 9, 9), color)
			_paint_icon_line(image, Vector2i(4, 4), Vector2i(12, 4), light)
			_paint_icon_line(image, Vector2i(12, 4), Vector2i(12, 12), dark)
			_paint_icon_line(image, Vector2i(4, 12), Vector2i(12, 12), dark)


func _resolve_palette_preview_icon_style(type_id: String, entry: Dictionary) -> String:
	var palette_group: String = String(entry.get("palette_group", "")).strip_edges().to_lower()
	var placement_layer: String = String(entry.get("placement_layer", "")).strip_edges().to_lower()
	if type_id == "station_floor_panel":
		return "station_floor"
	if type_id == "station_wall_door":
		return "station_door"
	if type_id == "station_wall" or type_id.begins_with("wall_"):
		return "station_wall"
	if type_id.contains("computer") or type_id.contains("display") or type_id.contains("console"):
		return "computer"
	if type_id.contains("bed"):
		return "bed"
	if type_id.contains("container") or type_id.contains("crate") or type_id.contains("cargo"):
		return "crate"
	if palette_group == "nature_props" and type_id.contains("tree"):
		return "nature_tree"
	if palette_group == "nature_props" and type_id.contains("cactus"):
		return "nature_cactus"
	if palette_group == "nature_props" and type_id.contains("rock"):
		return "rock"
	if palette_group == "nature_props" and (type_id.contains("bush") or type_id.contains("cover")):
		return "nature_bush"
	if palette_group == "nature_props" and type_id.contains("logs"):
		return "nature_logs"
	if type_id.contains("rock") or type_id.contains("felsen"):
		return "rock"
	if bool(entry.get("visual_surface_variant", false)) or placement_layer == "terrain":
		return "terrain"
	return "default"


func _paint_icon_rect(image: Image, rect: Rect2i, color: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			_paint_icon_pixel(image, x, y, color)


func _paint_icon_diamond(image: Image, top_x: int, top_y: int, right_x: int, right_y: int, bottom_x: int, bottom_y: int, left_x: int, left_y: int, color: Color) -> void:
	var center_y: int = left_y
	for y in range(top_y, bottom_y + 1):
		var span: int = 0
		if y <= center_y:
			span = roundi(float(y - top_y) / maxf(float(center_y - top_y), 1.0) * float(right_x - top_x))
		else:
			span = roundi(float(bottom_y - y) / maxf(float(bottom_y - center_y), 1.0) * float(right_x - top_x))
		for x in range(top_x - span, top_x + span + 1):
			_paint_icon_pixel(image, x, y, color)
	_paint_icon_line(image, Vector2i(top_x, top_y), Vector2i(right_x, right_y), color.lightened(0.24))
	_paint_icon_line(image, Vector2i(right_x, right_y), Vector2i(bottom_x, bottom_y), color.darkened(0.30))
	_paint_icon_line(image, Vector2i(bottom_x, bottom_y), Vector2i(left_x, left_y), color.darkened(0.30))
	_paint_icon_line(image, Vector2i(left_x, left_y), Vector2i(top_x, top_y), color.lightened(0.24))


func _paint_icon_line(image: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	var x0: int = start.x
	var y0: int = start.y
	var x1: int = end.x
	var y1: int = end.y
	var dx: int = abs(x1 - x0)
	var sx: int = 1 if x0 < x1 else -1
	var dy: int = -abs(y1 - y0)
	var sy: int = 1 if y0 < y1 else -1
	var error: int = dx + dy
	while true:
		_paint_icon_pixel(image, x0, y0, color)
		if x0 == x1 and y0 == y1:
			break
		var next_error: int = 2 * error
		if next_error >= dy:
			error += dy
			x0 += sx
		if next_error <= dx:
			error += dx
			y0 += sy


func _paint_icon_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)


func _refresh_palette_selection_visual() -> void:
	var tile_type_list := _get_tile_type_list()
	if tile_type_list == null:
		return
	var selected_index: int = -1
	for index in range(tile_type_list.item_count):
		var type_id: String = String(tile_type_list.get_item_metadata(index)).strip_edges()
		tile_type_list.deselect(index)
		tile_type_list.set_item_custom_bg_color(index, Color(0.0, 0.0, 0.0, 0.0))
		tile_type_list.set_item_custom_fg_color(index, PALETTE_ITEM_FG_COLOR)
		if not _selected_type_id.is_empty() and type_id == _selected_type_id:
			selected_index = index
	if selected_index < 0:
		return
	tile_type_list.select(selected_index)
	tile_type_list.set_item_custom_bg_color(selected_index, PALETTE_SELECTED_BG_COLOR)
	tile_type_list.set_item_custom_fg_color(selected_index, PALETTE_SELECTED_FG_COLOR)


func _get_tile_type_list() -> ItemList:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/TileTypeList") as ItemList


func _get_palette_groups_root() -> Container:
	var scroll_grid := get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteGroupsScroll/PaletteGroupsGrid") as Container
	if scroll_grid != null:
		return scroll_grid
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteGroups") as Container


func _get_palette_groups_compat_root() -> Container:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteGroups") as Container


func _get_palette_groups_scroll() -> ScrollContainer:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteGroupsScroll") as ScrollContainer


func _find_matching_type_id(tile_data) -> String:
	if tile_data == null or _tile_catalog == null:
		return ""

	for type_id in _tile_catalog.get_type_ids():
		var entry: Dictionary = _tile_catalog.get_type(type_id)
		if (
			bool(entry.get("walkable", true)) == bool(tile_data.walkable)
			and bool(entry.get("blocks_los", false)) == bool(tile_data.blocks_los)
			and int(entry.get("cover_value", 0)) == int(tile_data.cover_value)
			and int(entry.get("height_level", 0)) == int(tile_data.height_level)
			and int(entry.get("object_height", 0)) == int(tile_data.object_height)
			and String(entry.get("surface_type", "ground")) == String(tile_data.surface_type)
		):
			return type_id

	return ""


func _ensure_terrain_registry() -> void:
	if _terrain_registry != null:
		return

	_terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	_terrain_registry.name = "RuntimeTerrainRegistry"
	add_child(_terrain_registry)


func _resolve_tile_texture(tile_data) -> Texture2D:
	if _terrain_renderer == null:
		return _get_default_tile_texture()
	_terrain_renderer.set_tile_catalog(_tile_catalog)
	return _terrain_renderer.resolve_tile_texture(tile_data)


func _get_default_tile_texture() -> Texture2D:
	return TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_common_texture", "tile_default") as Texture2D


func _get_common_texture(texture_key: String) -> Texture2D:
	return TERRAIN_TEXTURE_CATALOG_SCRIPT.call("get_common_texture", texture_key) as Texture2D


func get_dirty_neighborhood_debug_snapshot() -> Dictionary:
	return _last_dirty_neighborhood_snapshot.duplicate(true)


func _refresh_dirty_visual_neighborhoods(seed_grids: Array[Vector2i]) -> void:
	if seed_grids.is_empty():
		_last_dirty_neighborhood_snapshot = {
			"seed_count": 0,
			"seed_grids": [],
			"neighborhood_grids": [],
			"object_grids": [],
			"raw_neighborhood_candidate_count": 0,
			"cliff_wall_candidate_count": 0,
			"object_candidate_count": 0,
			"duplicate_neighborhood_candidate_count": 0,
			"cliff_refresh_count": 0,
			"wall_refresh_count": 0,
			"object_refresh_count": 0,
		}
		_refresh_adjacency_debug_overlay_from_snapshot()
		return

	var seed_lookup: Dictionary = {}
	var neighborhood_lookup: Dictionary = {}
	var object_lookup: Dictionary = {}
	var raw_neighborhood_candidate_count: int = 0
	for seed_grid in seed_grids:
		var seed := Vector2i(seed_grid)
		seed_lookup[seed] = true
		object_lookup[seed] = true
		for candidate in _build_overlay_neighborhood_candidates(seed):
			raw_neighborhood_candidate_count += 1
			neighborhood_lookup[Vector2i(candidate)] = true

	var neighborhood_grids: Array[Vector2i] = _sort_grid_lookup_keys(neighborhood_lookup)
	var object_grids: Array[Vector2i] = _sort_grid_lookup_keys(object_lookup)
	var cliff_refresh_count: int = 0
	var wall_refresh_count: int = 0
	var object_refresh_count: int = 0

	for grid_position in neighborhood_grids:
		if _refresh_cliff_overlay_at(grid_position):
			cliff_refresh_count += 1
	for grid_position in neighborhood_grids:
		if _refresh_wall_overlay_at(grid_position):
			wall_refresh_count += 1
	for grid_position in object_grids:
		if _refresh_object_overlay_at(grid_position):
			object_refresh_count += 1

	_refresh_tile_property_overlay_for_grids(_sort_grid_lookup_keys(seed_lookup))
	_last_dirty_neighborhood_snapshot = {
		"seed_count": seed_lookup.size(),
		"seed_grids": _sort_grid_lookup_keys(seed_lookup),
		"neighborhood_grids": neighborhood_grids,
		"object_grids": object_grids,
		"raw_neighborhood_candidate_count": raw_neighborhood_candidate_count,
		"cliff_wall_candidate_count": neighborhood_grids.size(),
		"object_candidate_count": object_grids.size(),
		"duplicate_neighborhood_candidate_count": raw_neighborhood_candidate_count - neighborhood_grids.size(),
		"cliff_refresh_count": cliff_refresh_count,
		"wall_refresh_count": wall_refresh_count,
		"object_refresh_count": object_refresh_count,
	}
	_refresh_adjacency_debug_overlay_from_snapshot()


func _build_overlay_neighborhood_candidates(seed_grid: Vector2i) -> Array[Vector2i]:
	return [
		seed_grid,
		seed_grid + Vector2i(1, 0),
		seed_grid + Vector2i(-1, 0),
		seed_grid + Vector2i(0, 1),
		seed_grid + Vector2i(0, -1),
	]


func _sort_grid_lookup_keys(lookup: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for grid_variant in lookup.keys():
		result.append(Vector2i(grid_variant))
	result.sort_custom(Callable(self, "_compare_grid_positions"))
	return result


func _compare_grid_positions(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y


func _rebuild_all_cliff_overlays() -> void:
	_clear_cliff_overlays()
	if _terrain_map_data == null:
		return

	for tile_data in _terrain_map_data.call("get_tiles"):
		if int(tile_data.height_level) > 0 and not _is_object_type(tile_data):
			_create_cliff_overlays_for_tile(tile_data)


func _update_cliff_overlays_around(grid_position: Vector2i) -> void:
	var positions_to_update: Array[Vector2i] = _build_overlay_neighborhood_candidates(grid_position)

	for pos in positions_to_update:
		_refresh_cliff_overlay_at(pos)


func _refresh_cliff_overlay_at(grid_position: Vector2i) -> bool:
	_remove_cliff_overlays_at(grid_position)
	if _terrain_map_data == null:
		return false
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data != null and int(tile_data.height_level) > 0 and not _is_object_type(tile_data):
		_create_cliff_overlays_for_tile(tile_data)
		return true
	return false


func _create_cliff_overlays_for_tile(tile_data) -> void:
	if tile_data == null or _terrain_map_data == null:
		return

	var cliff_container := get_node_or_null("CliffContainer") as Node2D
	if cliff_container == null:
		return

	var my_height: int = int(tile_data.height_level)
	var grid_pos: Vector2i = tile_data.grid_position
	var current_edge_type: String = String(tile_data.edge_type)
	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
		return
	var is_slope: bool = current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	var overlays: Array[Sprite2D] = []

	# Grid neighbor direction → cliff texture mapping:
	# (+1, 0) = SE,  (-1, 0) = NW,  (0, +1) = SW,  (0, -1) = NE
	var cliff_edge_dirs: Array[Vector2i] = []
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor = _terrain_map_data.call("get_tile_at_grid", grid_pos + offset)
		var neighbor_height: int = int(neighbor.height_level) if neighbor != null else 0
		if neighbor_height < my_height and not _is_object_type(neighbor):
			cliff_edge_dirs.append(offset)

	# Step 1: detect corners - pairs of adjacent exposed edges
	# Corner pieces REPLACE the two straight cliff panels they connect
	# Note: Kenney names corners by inner curve direction, so we swap:
	# SE↔NW and SW↔NE (same fix as wall corners)
	var corner_map: Array = [
		[Vector2i(1, 0), Vector2i(0, 1), _get_common_texture("cliff_corner_ne")],
		[Vector2i(1, 0), Vector2i(0, -1), _get_common_texture("cliff_corner_nw")],
		[Vector2i(-1, 0), Vector2i(0, 1), _get_common_texture("cliff_corner_se")],
		[Vector2i(-1, 0), Vector2i(0, -1), _get_common_texture("cliff_corner_sw")],
	]

	var edges_consumed_by_corners: Array[Vector2i] = []

	for corner_entry in corner_map:
		var dir_a: Vector2i = corner_entry[0]
		var dir_b: Vector2i = corner_entry[1]
		var corner_texture: Texture2D = corner_entry[2]
		if cliff_edge_dirs.has(dir_a) and cliff_edge_dirs.has(dir_b):
			var corner_sprite := Sprite2D.new()
			corner_sprite.texture = corner_texture
			corner_sprite.centered = false
			corner_sprite.z_index = -14
			corner_sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
			cliff_container.add_child(corner_sprite)
			overlays.append(corner_sprite)
			if not edges_consumed_by_corners.has(dir_a):
				edges_consumed_by_corners.append(dir_a)
			if not edges_consumed_by_corners.has(dir_b):
				edges_consumed_by_corners.append(dir_b)

	# Step 2: render straight panels only for edges NOT consumed by corners
	# Use terrain_side_* for slopes, terrain_sideCliff_* for cliffs
	var edge_texture_map: Dictionary
	if is_slope:
		edge_texture_map = {
			Vector2i(1, 0): _get_common_texture("slope_se"),
			Vector2i(-1, 0): _get_common_texture("slope_nw"),
			Vector2i(0, 1): _get_common_texture("slope_sw"),
			Vector2i(0, -1): _get_common_texture("slope_ne"),
		}
	else:
		edge_texture_map = {
			Vector2i(1, 0): _get_common_texture("cliff_se"),
			Vector2i(-1, 0): _get_common_texture("cliff_nw"),
			Vector2i(0, 1): _get_common_texture("cliff_sw"),
			Vector2i(0, -1): _get_common_texture("cliff_ne"),
		}

	for edge_dir in cliff_edge_dirs:
		if edges_consumed_by_corners.has(edge_dir):
			continue
		var edge_texture: Texture2D = edge_texture_map[edge_dir]
		var edge_sprite := Sprite2D.new()
		edge_sprite.texture = edge_texture
		edge_sprite.centered = false
		edge_sprite.z_index = -15
		edge_sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
		cliff_container.add_child(edge_sprite)
		overlays.append(edge_sprite)

	if not overlays.is_empty():
		_cliff_sprites_by_grid[grid_pos] = overlays


func _remove_cliff_overlays_at(grid_position: Vector2i) -> void:
	if not _cliff_sprites_by_grid.has(grid_position):
		return

	var overlays: Array = _cliff_sprites_by_grid[grid_position]
	for sprite in overlays:
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()

	_cliff_sprites_by_grid.erase(grid_position)


func _clear_cliff_overlays() -> void:
	var cliff_container := get_node_or_null("CliffContainer") as Node2D
	if cliff_container != null:
		for child in cliff_container.get_children():
			child.queue_free()

	_cliff_sprites_by_grid.clear()


# --- Wall Overlay System ---

func _is_object_type(tile_data) -> bool:
	if _terrain_renderer == null:
		return false
	return _terrain_renderer.is_object_type(tile_data)


func _rebuild_all_wall_overlays() -> void:
	_clear_wall_overlays()
	if _terrain_map_data == null:
		return

	for tile_data in _terrain_map_data.call("get_tiles"):
		if _is_object_type(tile_data):
			_create_wall_overlays_for_tile(tile_data)


func _update_wall_overlays_around(grid_position: Vector2i) -> void:
	var positions_to_update: Array[Vector2i] = _build_overlay_neighborhood_candidates(grid_position)

	for pos in positions_to_update:
		_refresh_wall_overlay_at(pos)


func _refresh_wall_overlay_at(grid_position: Vector2i) -> bool:
	_remove_wall_overlays_at(grid_position)
	if _terrain_map_data == null:
		return false
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data != null and _is_object_type(tile_data):
		_create_wall_overlays_for_tile(tile_data)
		return true
	return false


func _create_wall_overlays_for_tile(tile_data) -> void:
	if tile_data == null or _terrain_map_data == null:
		return

	var wall_container := get_node_or_null("WallContainer") as Node2D
	if wall_container == null:
		return

	var grid_pos: Vector2i = tile_data.grid_position
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""

	var texture: Texture2D = null
	var pos_offset := Vector2.ZERO

	# Use type_id to determine texture and offset directly
	match type_id:
		"wall_straight_se":
			texture = _get_common_texture("wall_ne")
		"wall_straight_sw":
			texture = _get_common_texture("wall_se")
		"wall_straight_ne":
			texture = _get_common_texture("wall_nw")
		"wall_straight_nw":
			texture = _get_common_texture("wall_sw")
		"wall_corner_se":
			texture = _get_common_texture("wall_corner_nw")
		"wall_corner_sw":
			texture = _get_common_texture("wall_corner_ne")
		"wall_corner_ne":
			texture = _get_common_texture("wall_corner_sw")
		"wall_corner_nw":
			texture = _get_common_texture("wall_corner_se")
		"cliff_straight_se":
			texture = _get_common_texture("cliff_se")
			pos_offset = Vector2(33, 24)
		"cliff_straight_sw":
			texture = _get_common_texture("cliff_sw")
			pos_offset = Vector2(33, 56)
		"cliff_straight_ne":
			texture = _get_common_texture("cliff_ne")
			pos_offset = Vector2(-31, 23)
		"cliff_straight_nw":
			texture = _get_common_texture("cliff_nw")
			pos_offset = Vector2(-32, 56)
		"cliff_corner_se":
			texture = _get_common_texture("cliff_corner_ne")
			pos_offset = Vector2(-64, 40)
		"cliff_corner_sw":
			texture = _get_common_texture("cliff_corner_se")
			pos_offset = Vector2(1, 7)
		"cliff_corner_ne":
			texture = _get_common_texture("cliff_corner_nw")
			pos_offset = Vector2(0, 73)
		"cliff_corner_nw":
			texture = _get_common_texture("cliff_corner_sw")
			pos_offset = Vector2(65, 40)
		"slope_se":
			texture = _get_common_texture("ramp_se")
			pos_offset = Vector2(0, 32)
		"slope_sw":
			texture = _get_common_texture("ramp_sw")
			pos_offset = Vector2(0, 32)
		"slope_ne":
			texture = _get_common_texture("ramp_ne")
			pos_offset = Vector2(0, 32)
		"slope_nw":
			texture = _get_common_texture("ramp_nw")
			pos_offset = Vector2(0, 32)
		"rock_small":
			texture = _get_common_texture("rock_small")
		"rock_large":
			texture = _get_common_texture("rock_large")
		_:
			if type_id.begins_with("station_wall"):
				texture = _get_common_texture("wall_sw")
			else:
				return

	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.z_index = 0
	sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER + pos_offset
	wall_container.add_child(sprite)
	_wall_sprites_by_grid[grid_pos] = [sprite]


func _remove_wall_overlays_at(grid_position: Vector2i) -> void:
	if not _wall_sprites_by_grid.has(grid_position):
		return

	var overlays: Array = _wall_sprites_by_grid[grid_position]
	for sprite in overlays:
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()

	_wall_sprites_by_grid.erase(grid_position)


func _clear_wall_overlays() -> void:
	var wall_container := get_node_or_null("WallContainer") as Node2D
	if wall_container != null:
		for child in wall_container.get_children():
			child.queue_free()

	_wall_sprites_by_grid.clear()


func _update_object_overlay_at(grid_position: Vector2i) -> bool:
	return _refresh_object_overlay_at(grid_position)


func _refresh_object_overlay_at(grid_position: Vector2i) -> bool:
	_remove_object_overlay_at(grid_position)
	if _terrain_map_data == null or _terrain_renderer == null:
		return false

	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return false

	_terrain_renderer.set_tile_catalog(_tile_catalog)
	var texture: Texture2D = _terrain_renderer.resolve_object_texture(tile_data)
	if texture == null:
		return false

	var object_container := get_node_or_null("ObjectContainer") as Node2D
	if object_container == null:
		object_container = Node2D.new()
		object_container.name = "ObjectContainer"
		object_container.y_sort_enabled = true
		object_container.z_index = -12
		add_child(object_container)

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.z_index = 0
	sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
	object_container.add_child(sprite)
	_object_sprites_by_grid[grid_position] = [sprite]
	return true


func _remove_object_overlay_at(grid_position: Vector2i) -> void:
	if not _object_sprites_by_grid.has(grid_position):
		return

	var overlays: Array = _object_sprites_by_grid[grid_position]
	for sprite in overlays:
		if sprite != null and is_instance_valid(sprite):
			sprite.queue_free()

	_object_sprites_by_grid.erase(grid_position)


func _rebuild_grid_overlay() -> void:
	var grid_overlay := get_node_or_null("GridOverlay")
	if grid_overlay == null:
		return

	for child in grid_overlay.get_children():
		child.queue_free()

	if _terrain_map_data == null:
		return

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_w: float = float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH))
	var half_h: float = float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))

	# --- Compass labels at the four diamond corners ---
	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	var origin: Vector2 = _terrain_map_data.call("get_grid_origin")
	var max_x: int = grid_size.x - 1
	var max_y: int = grid_size.y - 1

	var north_pos: Vector2 = Vector2(
		origin.x + float(0 - 0) * half_w,
		origin.y + float(0 + 0) * half_h
	)
	var east_pos: Vector2 = Vector2(
		origin.x + float(max_x - 0) * half_w,
		origin.y + float(max_x + 0) * half_h
	)
	var south_pos: Vector2 = Vector2(
		origin.x + float(max_x - max_y) * half_w,
		origin.y + float(max_x + max_y) * half_h
	)
	var west_pos: Vector2 = Vector2(
		origin.x + float(0 - max_y) * half_w,
		origin.y + float(0 + max_y) * half_h
	)

	var compass_data: Array = [
		["N", north_pos + Vector2(0, -half_h * 3)],
		["O", east_pos + Vector2(half_w * 3, 0)],
		["S", south_pos + Vector2(0, half_h * 3)],
		["W", west_pos + Vector2(-half_w * 3, 0)],
	]

	for entry in compass_data:
		var lbl := Label.new()
		lbl.text = entry[0]
		lbl.add_theme_font_size_override("font_size", 80)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size = Vector2(160, 120)
		lbl.position = entry[1] - lbl.size * 0.5
		grid_overlay.add_child(lbl)


# --- Hover Preview ---

func _update_hover_preview(world_position: Vector2) -> void:
	if _get_primary_3d_view() != null:
		_hide_hover_preview()
		return
	if _terrain_map_data == null or _terrain_registry == null:
		_hide_hover_preview()
		return

	var grid_pos: Vector2i = _terrain_registry.world_to_grid(world_position)
	if grid_pos == _hover_grid_position:
		return

	_hover_grid_position = grid_pos
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_pos)
	if tile_data == null:
		_hide_hover_preview()
		return

	var preview_texture: Texture2D = _get_default_tile_texture()
	if not _selected_type_id.is_empty() and _tile_catalog != null:
		var type_texture: Texture2D = _tile_catalog.get_texture(_selected_type_id)
		if type_texture != null:
			preview_texture = type_texture

	if _hover_preview == null:
		_hover_preview = Sprite2D.new()
		_hover_preview.centered = false
		_hover_preview.z_index = 30
		add_child(_hover_preview)

	_hover_preview.texture = preview_texture
	var preview_scale: float = _placement_object_scale if _palette_type_uses_object_scale(_selected_type_id) else OBJECT_SCALE_DEFAULT
	_hover_preview.scale = Vector2.ONE * preview_scale
	_hover_preview.position = tile_data.world_position - (KENNEY_DIAMOND_CENTER * preview_scale)
	_hover_preview.modulate = Color(1.0, 1.0, 1.0, 0.4)
	_hover_preview.visible = true


func _hide_hover_preview() -> void:
	_hover_grid_position = Vector2i(-1, -1)
	if _hover_preview != null:
		_hover_preview.visible = false
