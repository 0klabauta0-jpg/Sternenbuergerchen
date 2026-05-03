class_name TerrainMap3DView
extends CanvasLayer

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const VIEWPORT_CONTAINER_NAME: String = "ViewportContainer"
const VIEWPORT_NAME: String = "SubViewport"
const WORLD_ROOT_NAME: String = "WorldRoot"
const MAP_ROOT_NAME: String = "MapRoot3D"
const MARKER_ROOT_NAME: String = "MarkerRoot3D"
const PATROL_ROOT_NAME: String = "PatrolRoot3D"
const SELECTION_ROOT_NAME: String = "SelectionRoot3D"
const UNIT_ROOT_NAME: String = "UnitRoot3D"
const ORDER_ROOT_NAME: String = "OrderRoot3D"
const CONTACT_ROOT_NAME: String = "ContactRoot3D"
const DROP_ROOT_NAME: String = "DropRoot3D"
const STATUS_ROOT_NAME: String = "StatusRoot3D"
const CAMERA_NAME: String = "Camera3D"
const LIGHT_NAME: String = "SunLight3D"
const ENVIRONMENT_NAME: String = "WorldEnvironment"

const TERRAIN_3D_MAPPING_PATH: String = "res://data/terrain_3d_asset_mapping.json"
const NPC_UNIT_VISUAL_MAPPING_PATH: String = "res://data/npc_unit_visual_mapping.json"
const TILE_SPACING: float = 1.0
const TILE_THICKNESS: float = 0.035
const HEIGHT_STEP: float = 0.25
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
const DEFAULT_HALF_TILE_WIDTH: float = 64.0
const DEFAULT_HALF_TILE_HEIGHT: float = 32.0
const TILE_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_SW.png")
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
var _world_root: Node3D = null
var _map_root: Node3D = null
var _marker_root: Node3D = null
var _patrol_root: Node3D = null
var _selection_root: Node3D = null
var _unit_root: Node3D = null
var _order_root: Node3D = null
var _contact_root: Node3D = null
var _drop_root: Node3D = null
var _status_root: Node3D = null
var _camera: Camera3D = null
var _environment: WorldEnvironment = null

var _terrain_map_data = null
var _tile_catalog = null
var _terrain_3d_mapping: Dictionary = {}
var _npc_unit_visual_mapping: Dictionary = {}
var _model_scene_cache: Dictionary = {}
var _box_mesh_cache: Dictionary = {}
var _material_cache: Dictionary = {}
var _render_tile_by_grid: Dictionary = {}
var _unit_nodes: Array = []
var _unit_proxies_by_id: Dictionary = {}
var _selected_grid_positions: Array = []
var _order_payload: Dictionary = {}
var _contact_entries: Array = []
var _contact_selected_fireteam_ids: PackedStringArray = PackedStringArray()
var _drop_payload: Dictionary = {}
var _mission_status_payload: Dictionary = {}

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
var _asset_texture_count: int = 0
var _asset_model_count: int = 0
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
var _enemy_animated_unit_model_count: int = 0
var _unit_status_badge_count: int = 0
var _dropship_texture_visible: bool = false
var _dropship_model_visible: bool = false
var _map_render_duration_msec: int = 0
var _marker_count: int = 0
var _patrol_segment_count: int = 0
var _area_order_count: int = 0
var _waypoint_visual_count: int = 0
var _area_order_tile_marker_count: int = 0
var _waypoint_tile_marker_count: int = 0
var _lz_tile_marker_count: int = 0
var _tile_grid_line_count: int = 0
var _contact_count: int = 0
var _objective_status_visible: bool = false
var _mission_result_visible: bool = false
var _continuous_redraw_until_msec: int = 0
var _render_snapshot_request_count: int = 0
var _order_payload_apply_count: int = 0
var _contact_payload_apply_count: int = 0
var _drop_payload_apply_count: int = 0
var _mission_status_payload_apply_count: int = 0


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
	if _subviewport != null and _subviewport.render_target_update_mode == SubViewport.UPDATE_ALWAYS and Time.get_ticks_msec() > _continuous_redraw_until_msec:
		_subviewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func configure_from_map(terrain_map_data) -> void:
	_terrain_map_data = terrain_map_data
	_read_map_transform()
	render_map()


func render_map(terrain_map_data = null) -> void:
	var render_started_at_msec: int = Time.get_ticks_msec()
	if terrain_map_data != null:
		_terrain_map_data = terrain_map_data
	_read_map_transform()
	_ensure_nodes()
	_clear_children(_map_root)
	_clear_children(_marker_root)
	_clear_children(_patrol_root)
	_clear_children(_selection_root)
	_clear_children(_order_root)
	_clear_children(_contact_root)
	_clear_children(_drop_root)
	_render_tile_by_grid.clear()
	_map_tile_count = 0
	_ground_mesh_count = 0
	_tile_texture_count = 0
	_height_edge_texture_count = 0
	_asset_texture_count = 0
	_asset_model_count = 0
	_placeholder_object_count = 0
	_missing_asset_mapping_count = 0
	_missing_unit_model_count = 0
	_missing_dropship_model_count = 0
	_tile_grid_line_count = 0
	_marker_count = 0
	_patrol_segment_count = 0
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
		_add_height_edge_texture_visuals(tile_data)
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
	for grid_variant in grid_positions:
		if grid_variant is Vector2i:
			_selected_grid_positions.append(Vector2i(grid_variant))
		elif grid_variant is Vector2:
			_selected_grid_positions.append(Vector2i(roundi(grid_variant.x), roundi(grid_variant.y)))
	_rebuild_selection_visuals()
	_request_viewport_redraw()


func set_order_visual_payload(order_payload: Dictionary) -> void:
	_order_payload_apply_count += 1
	_order_payload = order_payload.duplicate(true)
	_rebuild_order_visuals()
	_request_viewport_redraw()


func set_contact_entries(contact_entries: Array, selected_fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	_contact_payload_apply_count += 1
	_contact_entries.clear()
	for entry_variant in contact_entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			_contact_entries.append(Dictionary(entry_variant).duplicate(true))
	_contact_selected_fireteam_ids = selected_fireteam_ids.duplicate()
	_rebuild_contact_visuals()
	_request_viewport_redraw()


func set_mission_drop_visual_state(drop_payload: Dictionary) -> void:
	_drop_payload_apply_count += 1
	_drop_payload = drop_payload.duplicate(true)
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
	var scale: float = _camera_size / viewport_height
	pan_camera(pixel_delta * CAMERA_DRAG_PAN_FACTOR * scale, 1.0)


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
	var ray_origin: Vector3 = _camera.project_ray_origin(viewport_position)
	var ray_dir: Vector3 = _camera.project_ray_normal(viewport_position)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(ray_origin, ray_dir)
	if typeof(hit) != TYPE_VECTOR3:
		return null
	return _position_3d_to_world(Vector3(hit))


func world_to_screen_position(world_position: Vector2) -> Vector2:
	_ensure_nodes()
	if _camera == null:
		return Vector2.ZERO
	return _camera.unproject_position(_world_to_3d_position(world_position, 0.0))


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


func get_render_snapshot() -> Dictionary:
	_render_snapshot_request_count += 1
	return {
		"tile_count": _map_tile_count,
		"ground_mesh_count": _ground_mesh_count,
		"tile_texture_count": _tile_texture_count,
		"height_edge_texture_count": _height_edge_texture_count,
		"asset_texture_count": _asset_texture_count,
		"asset_model_count": _asset_model_count,
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
		"enemy_animated_unit_model_count": _enemy_animated_unit_model_count,
		"unit_visual_mapping_loaded": not _get_npc_unit_visual_mapping().is_empty(),
		"unit_status_badge_count": _unit_status_badge_count,
		"marker_count": _marker_count,
		"patrol_segment_count": _patrol_segment_count,
		"selected_grid_count": _selected_grid_positions.size(),
		"unit_proxy_count": _unit_proxies_by_id.size(),
		"area_order_count": _area_order_count,
		"waypoint_visual_count": _waypoint_visual_count,
		"area_order_tile_marker_count": _area_order_tile_marker_count,
		"waypoint_tile_marker_count": _waypoint_tile_marker_count,
		"lz_tile_marker_count": _lz_tile_marker_count,
		"tile_grid_line_count": _tile_grid_line_count,
		"contact_count": _contact_count,
		"objective_status_visible": _objective_status_visible,
		"objective_capture_progress": float(_mission_status_payload.get("objective_capture_progress", 0.0)),
		"mission_result_visible": _mission_result_visible,
		"mission_result": String(_mission_status_payload.get("result", "")),
		"has_lz": bool(_drop_payload.get("has_lz_position", false)),
		"dropship_visible": bool(_drop_payload.get("dropship_visible", false)),
		"dropship_texture_visible": _dropship_texture_visible,
		"dropship_model_visible": _dropship_model_visible,
		"camera_yaw_degrees": _camera_yaw_degrees,
		"camera_size": _camera_size,
		"map_render_duration_msec": _map_render_duration_msec,
		"render_snapshot_request_count": _render_snapshot_request_count,
		"order_payload_apply_count": _order_payload_apply_count,
		"contact_payload_apply_count": _contact_payload_apply_count,
		"drop_payload_apply_count": _drop_payload_apply_count,
		"mission_status_payload_apply_count": _mission_status_payload_apply_count,
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

	if _world_root == null:
		_world_root = _subviewport.get_node_or_null(WORLD_ROOT_NAME) as Node3D
	if _world_root == null:
		_world_root = Node3D.new()
		_world_root.name = WORLD_ROOT_NAME
		_subviewport.add_child(_world_root)

	_map_root = _ensure_node3d(_world_root, MAP_ROOT_NAME)
	_marker_root = _ensure_node3d(_world_root, MARKER_ROOT_NAME)
	_patrol_root = _ensure_node3d(_world_root, PATROL_ROOT_NAME)
	_selection_root = _ensure_node3d(_world_root, SELECTION_ROOT_NAME)
	_unit_root = _ensure_node3d(_world_root, UNIT_ROOT_NAME)
	_order_root = _ensure_node3d(_world_root, ORDER_ROOT_NAME)
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
		light.light_energy = 1.45
		light.rotation_degrees = Vector3(-62.0, -38.0, 0.0)
		_world_root.add_child(light)

	if _environment == null:
		_environment = _world_root.get_node_or_null(ENVIRONMENT_NAME) as WorldEnvironment
	if _environment == null:
		_environment = WorldEnvironment.new()
		_environment.name = ENVIRONMENT_NAME
		var environment := Environment.new()
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.25, 0.27, 0.27, 1.0)
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.82, 0.86, 0.88, 1.0)
		environment.ambient_light_energy = 0.72
		_environment.environment = environment
		_world_root.add_child(_environment)


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
	var offset := Vector3(sin(yaw_rad) * horizontal_distance, height, cos(yaw_rad) * horizontal_distance)
	_camera.global_position = focus_3d + offset
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
		if not _add_ground_model_visual(tile_data, top_y):
			_add_missing_asset_marker(tile_data, top_y, "ground_flat")
	else:
		var tile_mesh := _make_box_mesh(Vector3(cell_size * tile_fill, tile_thickness, cell_size * tile_fill))
		var tile_instance := MeshInstance3D.new()
		tile_instance.name = "Tile_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
		tile_instance.mesh = tile_mesh
		tile_instance.material_override = _make_material(_get_tile_color(tile_data))
		tile_instance.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y - (tile_thickness * 0.5))
		_map_root.add_child(tile_instance)
		_ground_mesh_count += 1
	_map_tile_count += 1

	var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	var visual_type_id: String = _resolve_tile_asset_type_id(object_type_id, type_id)
	if not visual_type_id.is_empty() or bool(tile_data.blocks_los) or int(tile_data.object_height) > 0:
		_add_object_visual(tile_data, top_y, visual_type_id)


func _add_object_visual(tile_data, top_y: float, visual_type_id: String) -> void:
	if not visual_type_id.is_empty() and _add_asset_model_visual(tile_data, top_y, visual_type_id):
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


func _add_ground_model_visual(tile_data, top_y: float) -> bool:
	var model_scene := _get_asset_model_scene("ground_flat")
	if model_scene == null or _map_root == null:
		return false
	var model_instance := model_scene.instantiate() as Node3D
	if model_instance == null:
		return false
	_normalize_asset_model_instance(model_instance)

	var ground_root := Node3D.new()
	ground_root.name = "Tile_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
	ground_root.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + 0.002)
	ground_root.scale = Vector3.ONE * _get_3d_cell_size()
	ground_root.add_child(model_instance)
	_map_root.add_child(ground_root)
	_ground_mesh_count += 1
	return true


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


func _add_tile_grid_lines(tiles: Array) -> void:
	if _map_root == null or tiles.is_empty():
		return
	var material := _make_material(Color(0.12, 0.08, 0.06, 0.48), true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	var cell_size: float = _get_3d_cell_size()
	var half_size: float = cell_size * 0.5
	var line_count: int = 0
	for tile_data in tiles:
		if tile_data == null:
			continue
		var grid_position: Vector2 = Vector2(tile_data.grid_position)
		var top_y: float = (float(tile_data.height_level) * _get_3d_height_step()) + 0.018
		var center: Vector3 = _grid_to_3d_position(grid_position, top_y)
		var nw := center + Vector3(-half_size, 0.0, -half_size)
		var ne := center + Vector3(half_size, 0.0, -half_size)
		var se := center + Vector3(half_size, 0.0, half_size)
		var sw := center + Vector3(-half_size, 0.0, half_size)
		mesh.surface_add_vertex(nw)
		mesh.surface_add_vertex(ne)
		mesh.surface_add_vertex(ne)
		mesh.surface_add_vertex(se)
		mesh.surface_add_vertex(se)
		mesh.surface_add_vertex(sw)
		mesh.surface_add_vertex(sw)
		mesh.surface_add_vertex(nw)
		line_count += 4
	mesh.surface_end()
	if line_count <= 0:
		return
	var lines := MeshInstance3D.new()
	lines.name = "TileGridLines3D"
	lines.mesh = mesh
	_map_root.add_child(lines)
	_tile_grid_line_count = line_count


func _add_height_edge_texture_visuals(tile_data) -> void:
	if tile_data == null or _map_root == null:
		return
	if _has_3d_asset_mapping():
		return
	if int(tile_data.height_level) <= 0 or _is_legacy_object_type(tile_data):
		return
	var current_edge_type: String = String(tile_data.edge_type)
	if current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
		return

	var grid_pos: Vector2i = tile_data.grid_position
	var my_height: int = int(tile_data.height_level)
	var is_slope: bool = current_edge_type == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	var cliff_edge_dirs: Array[Vector2i] = []
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var neighbor = _render_tile_by_grid.get(grid_pos + offset, null)
		var neighbor_height: int = int(neighbor.height_level) if neighbor != null else 0
		if neighbor_height < my_height and not _is_legacy_object_type(neighbor):
			cliff_edge_dirs.append(offset)

	var top_y: float = float(my_height) * _get_3d_height_step()
	var corner_map: Array = [
		[Vector2i(1, 0), Vector2i(0, 1), CLIFF_CORNER_NE],
		[Vector2i(1, 0), Vector2i(0, -1), CLIFF_CORNER_NW],
		[Vector2i(-1, 0), Vector2i(0, 1), CLIFF_CORNER_SE],
		[Vector2i(-1, 0), Vector2i(0, -1), CLIFF_CORNER_SW],
	]
	var edges_consumed_by_corners: Array[Vector2i] = []
	for corner_entry in corner_map:
		var dir_a: Vector2i = corner_entry[0]
		var dir_b: Vector2i = corner_entry[1]
		var corner_texture := corner_entry[2] as Texture2D
		if cliff_edge_dirs.has(dir_a) and cliff_edge_dirs.has(dir_b):
			_add_height_edge_texture_card(tile_data, top_y, corner_texture, "Corner_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, dir_a.x + dir_b.x, dir_a.y + dir_b.y])
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
		_add_height_edge_texture_card(tile_data, top_y, edge_texture, "Edge_%d_%d_%d_%d" % [grid_pos.x, grid_pos.y, edge_dir.x, edge_dir.y])


func _add_height_edge_texture_card(tile_data, top_y: float, texture: Texture2D, node_name: String) -> void:
	if texture == null:
		return
	var card := _add_texture_card(
		_map_root,
		texture,
		_grid_to_3d_position(Vector2(tile_data.grid_position), top_y + 0.018),
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


func _add_asset_model_visual(tile_data, top_y: float, visual_type_id: String) -> bool:
	var model_scene := _get_asset_model_scene(visual_type_id)
	if model_scene == null or _map_root == null:
		return false
	var model_instance := model_scene.instantiate() as Node3D
	if model_instance == null:
		return false
	_normalize_asset_model_instance(model_instance)

	var visual_root := Node3D.new()
	visual_root.name = "Asset_%s_%d_%d" % [visual_type_id, tile_data.grid_position.x, tile_data.grid_position.y]
	visual_root.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + _get_asset_y_offset(visual_type_id))
	visual_root.rotation_degrees.y = _get_asset_rotation_y(visual_type_id)
	visual_root.scale = Vector3.ONE * _get_asset_model_scale(visual_type_id)
	visual_root.add_child(model_instance)
	_map_root.add_child(visual_root)
	if not _has_model_mapping_for_type(visual_type_id):
		_apply_map_asset_material_override(model_instance, visual_type_id)
	_asset_model_count += 1
	return true


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


func _merge_transformed_aabb(bounds: Dictionary, transform: Transform3D, aabb: AABB) -> void:
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
		var transformed_corner: Vector3 = transform * corner
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


func _rebuild_marker_visuals() -> void:
	_clear_children(_marker_root)
	_marker_count = 0
	if _terrain_map_data == null or _marker_root == null:
		return
	for marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
		var marker_record: Dictionary = Dictionary(_terrain_map_data.call("get_marker_record", marker_id))
		var world_position: Vector2 = Vector2(marker_record.get("position", _terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)))
		var color: Color = Color(marker_record.get("color", Color(0.9, 0.9, 0.9, 1.0)))
		var marker := MeshInstance3D.new()
		marker.name = "Marker_%s" % String(marker_id)
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.34
		mesh.bottom_radius = 0.34
		mesh.height = 0.08
		mesh.radial_segments = 4
		marker.mesh = mesh
		marker.material_override = _make_material(Color(color.r, color.g, color.b, 0.92))
		marker.position = _world_to_3d_position(world_position, 0.22)
		marker.rotation_degrees.y = 45.0
		_marker_root.add_child(marker)
		_marker_count += 1


func _rebuild_patrol_visuals() -> void:
	_clear_children(_patrol_root)
	_patrol_segment_count = 0
	if _terrain_map_data == null or _patrol_root == null:
		return
	var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
	for spawn_id_variant in patrol_paths.keys():
		var path_points: Array = Array(_terrain_map_data.call("get_patrol_path", String(spawn_id_variant)))
		if path_points.size() < 2:
			continue
		var color := Color(0.25, 0.92, 0.4, 0.82)
		for index in range(1, path_points.size()):
			_add_line3d(_patrol_root, _world_to_3d_position(Vector2(path_points[index - 1]), 0.28), _world_to_3d_position(Vector2(path_points[index]), 0.28), color, "Patrol_%s_%d" % [String(spawn_id_variant), index])
			_patrol_segment_count += 1


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
		var mesh := _make_box_mesh(Vector3(cell_size * 0.98, 0.05, cell_size * 0.98))
		var selection := MeshInstance3D.new()
		selection.name = "Selection_%d_%d" % [grid_position.x, grid_position.y]
		selection.mesh = mesh
		selection.material_override = _make_material(Color(1.0, 0.94, 0.35, 0.52), true)
		selection.position = _grid_to_3d_position(Vector2(grid_position), (float(tile_data.height_level) * _get_3d_height_step()) + 0.09)
		_selection_root.add_child(selection)


func _rebuild_order_visuals() -> void:
	_clear_children(_order_root)
	_area_order_count = 0
	_waypoint_visual_count = 0
	_area_order_tile_marker_count = 0
	_waypoint_tile_marker_count = 0
	if _order_root == null or _order_payload.is_empty():
		return
	var phase_index: int = int(_order_payload.get("phase_index", 1))
	var anchor_by_fireteam: Dictionary = {}
	for anchor_variant in Array(_order_payload.get("fireteam_anchors", [])):
		if typeof(anchor_variant) != TYPE_DICTIONARY:
			continue
		var anchor_dict: Dictionary = Dictionary(anchor_variant)
		var fireteam_id: String = String(anchor_dict.get("fireteam_id", "")).strip_edges().to_lower()
		if fireteam_id.is_empty() or typeof(anchor_dict.get("position", null)) != TYPE_VECTOR2:
			continue
		anchor_by_fireteam[fireteam_id] = Vector2(anchor_dict.get("position", Vector2.ZERO))

	for area_variant in Array(_order_payload.get("area_order_dicts", [])):
		if typeof(area_variant) != TYPE_DICTIONARY:
			continue
		_add_area_order_visual(Dictionary(area_variant))

	for plan_variant in Array(_order_payload.get("plan_dicts", [])):
		if typeof(plan_variant) != TYPE_DICTIONARY:
			continue
		_add_plan_visual(Dictionary(plan_variant), phase_index, anchor_by_fireteam)


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


func _add_plan_visual(plan_data: Dictionary, phase_index: int, anchor_by_fireteam: Dictionary) -> void:
	if int(plan_data.get("phase", -1)) != phase_index:
		return
	var fireteam_id: String = String(plan_data.get("fireteam_id", "")).strip_edges().to_lower()
	var last_position: Variant = anchor_by_fireteam.get(fireteam_id, null)
	for waypoint_variant in Array(plan_data.get("waypoints", [])):
		if typeof(waypoint_variant) != TYPE_DICTIONARY:
			continue
		var waypoint: Dictionary = Dictionary(waypoint_variant)
		if typeof(waypoint.get("target_position", null)) != TYPE_VECTOR2:
			continue
		var target_position: Vector2 = Vector2(waypoint.get("target_position", Vector2.ZERO))
		var command_color: Color = _get_command_color(String(waypoint.get("command_type", "move")))
		if typeof(last_position) == TYPE_VECTOR2:
			_add_line3d(_order_root, _world_to_3d_position(Vector2(last_position), 0.36), _world_to_3d_position(target_position, 0.36), command_color, "WaypointLine")
		if _add_world_tile_marker(_order_root, target_position, Color(command_color.r, command_color.g, command_color.b, 0.42), "WaypointTile", 0.05, 0.82):
			_waypoint_tile_marker_count += 1
		_waypoint_visual_count += 1
		last_position = target_position


func _rebuild_contact_visuals() -> void:
	_clear_children(_contact_root)
	_contact_count = 0
	if _contact_root == null:
		return
	var selected_lookup: Dictionary = {}
	for fireteam_id_variant in _contact_selected_fireteam_ids:
		selected_lookup[String(fireteam_id_variant).strip_edges().to_lower()] = true
	for contact_variant in _contact_entries:
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var contact: Dictionary = Dictionary(contact_variant)
		var fireteam_id: String = String(contact.get("fireteam_id", "")).strip_edges().to_lower()
		if not selected_lookup.is_empty() and not selected_lookup.has(fireteam_id):
			continue
		var position_variant = contact.get("last_known_position", null)
		if typeof(position_variant) != TYPE_VECTOR2:
			continue
		var detection_state: String = String(contact.get("detection_state", "unknown")).strip_edges().to_lower()
		_add_marker3d(_contact_root, Vector2(position_variant), _get_contact_color(detection_state), "Contact_%s" % String(contact.get("unit_id", _contact_count)), 0.36, 0.48, 4)
		_contact_count += 1


func _rebuild_drop_visuals() -> void:
	_clear_children(_drop_root)
	_dropship_texture_visible = false
	_dropship_model_visible = false
	_missing_dropship_model_count = 0
	_lz_tile_marker_count = 0
	if _drop_root == null or _drop_payload.is_empty():
		return
	if bool(_drop_payload.get("has_lz_position", false)) and typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
		var lz_position: Vector2 = Vector2(_drop_payload.get("lz_position", Vector2.ZERO))
		if _add_world_tile_marker(_drop_root, lz_position, Color(0.38, 1.0, 0.62, 0.44), "LZTile", 0.055, 0.96):
			_lz_tile_marker_count += 1

	if bool(_drop_payload.get("dropship_visible", false)) and typeof(_drop_payload.get("dropship_position", null)) == TYPE_VECTOR2:
		var ship_position: Vector2 = Vector2(_drop_payload.get("dropship_position", Vector2.ZERO))
		_add_dropship_proxy(ship_position)
		if typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
			_add_line3d(_drop_root, _world_to_3d_position(ship_position, 0.52), _world_to_3d_position(Vector2(_drop_payload.get("lz_position", Vector2.ZERO)), 0.52), Color(0.56, 1.0, 0.68, 0.86), "DropshipApproach")


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
	zone.position = _world_to_3d_position(world_position, 0.31)
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
	progress_disc.position = _world_to_3d_position(world_position, 0.35)
	_status_root.add_child(progress_disc)

	var label_text: String = _build_objective_status_label_text(progress)
	_add_label3d(_status_root, label_text, _world_to_3d_position(world_position, STATUS_LABEL_HEIGHT), "ObjectiveStatusLabel3D", base_color, 18)
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
	_add_label3d(_status_root, "\n".join(lines), _world_to_3d_position(anchor_world_position, STATUS_LABEL_HEIGHT + 0.74), "MissionResultLabel3D", color, 22)
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


func _add_dropship_proxy(world_position: Vector2) -> void:
	var model_scene := _get_asset_model_scene("fahrzeug_speeder_b_se")
	if model_scene == null:
		model_scene = _get_asset_model_scene_by_name(DROPSHIP_MODEL_NAME)
	if model_scene != null:
		var model_instance := model_scene.instantiate() as Node3D
		if model_instance != null:
			_normalize_asset_model_instance(model_instance)
			var craft_root := Node3D.new()
			craft_root.name = "DropshipModel_%s" % DROPSHIP_MODEL_NAME
			craft_root.position = _world_to_3d_position(world_position, _get_asset_y_offset("fahrzeug_speeder_b_se"))
			craft_root.rotation_degrees.y = _get_dropship_rotation_y(world_position)
			craft_root.scale = Vector3.ONE * (_get_asset_model_scale("fahrzeug_speeder_b_se") if _has_model_mapping_for_type("fahrzeug_speeder_b_se") else DROPSHIP_MODEL_SCALE)
			craft_root.add_child(model_instance)
			_drop_root.add_child(craft_root)
			_dropship_model_visible = true
			return

	if _uses_strict_3d_asset_mapping():
		_add_runtime_missing_asset_marker(
			_drop_root,
			_world_to_3d_position(world_position, 0.72),
			"MissingAsset_dropship_model_%s" % _sanitize_node_name(DROPSHIP_MODEL_NAME)
		)
		_missing_dropship_model_count = 1
		return

	var dropship_texture := _drop_payload.get("dropship_texture", null) as Texture2D
	if dropship_texture == null:
		dropship_texture = DEFAULT_DROPSHIP_TEXTURE
	var sprite := _add_texture_card(
		_drop_root,
		dropship_texture,
		_world_to_3d_position(world_position, 0.72),
		"DropshipTexture",
		DROPSHIP_TEXTURE_PIXEL_SIZE
	)
	if sprite != null:
		_dropship_texture_visible = true
		return

	var body_mesh := _make_box_mesh(Vector3(2.9, 0.46, 1.25))
	var body := MeshInstance3D.new()
	body.name = "DropshipProxy"
	body.mesh = body_mesh
	body.material_override = _make_material(Color(0.95, 0.76, 0.32, 0.96))
	body.position = _world_to_3d_position(world_position, 0.72)
	body.rotation_degrees.y = -_camera_yaw_degrees
	_drop_root.add_child(body)

	var wing_mesh := _make_box_mesh(Vector3(1.05, 0.16, 2.45))
	var wing := MeshInstance3D.new()
	wing.name = "DropshipWing"
	wing.mesh = wing_mesh
	wing.material_override = _make_material(Color(0.72, 0.76, 0.78, 0.88))
	wing.position = body.position + Vector3(0.0, -0.04, 0.0)
	wing.rotation = body.rotation
	_drop_root.add_child(wing)


func _get_dropship_rotation_y(world_position: Vector2) -> float:
	if typeof(_drop_payload.get("dropship_target_position", null)) == TYPE_VECTOR2:
		var target_position: Vector2 = Vector2(_drop_payload.get("dropship_target_position", world_position))
		return _get_world_direction_yaw(world_position, target_position, -_camera_yaw_degrees)
	if typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
		return _get_world_direction_yaw(world_position, Vector2(_drop_payload.get("lz_position", Vector2.ZERO)), -_camera_yaw_degrees)
	return -_camera_yaw_degrees


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
	var enemy_animated_unit_model_count: int = 0
	var unit_status_badge_count: int = 0
	var missing_unit_model_count: int = 0
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
		var next_visible: bool = _is_unit_world_visible(unit)
		if proxy.visible != next_visible:
			changed = true
		proxy.visible = next_visible
		var unit_is_moving: bool = false
		if unit is Node2D:
			var unit_world_position: Vector2 = (unit as Node2D).global_position
			var next_position: Vector3 = _world_to_3d_position(unit_world_position, 0.06)
			var proxy_distance: float = proxy.position.distance_to(next_position)
			unit_is_moving = proxy_distance > 0.01
			if proxy_distance > 0.0001:
				changed = true
			if force_rebuild or delta <= 0.0 or proxy_distance >= UNIT_PROXY_SNAP_DISTANCE:
				proxy.position = next_position
			else:
				proxy.position = proxy.position.lerp(next_position, clampf(delta * UNIT_PROXY_SMOOTH_SPEED, 0.0, 1.0))
			var next_rotation_y: float = _get_unit_proxy_rotation_y(proxy, unit, unit_world_position)
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
		if _update_unit_visual_animation(proxy, unit_is_moving):
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
	if _enemy_animated_unit_model_count != enemy_animated_unit_model_count:
		changed = true
	_enemy_animated_unit_model_count = enemy_animated_unit_model_count
	if _unit_status_badge_count != unit_status_badge_count:
		changed = true
	_unit_status_badge_count = unit_status_badge_count
	if _missing_unit_model_count != missing_unit_model_count:
		changed = true
	_missing_unit_model_count = missing_unit_model_count
	if changed:
		_request_viewport_redraw()


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
		return vital_state.to_upper()
	if unit.has_method("is_in_contact") and bool(unit.call("is_in_contact")):
		return "CONTACT"
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
	if unit != null and unit.has_method("is_in_contact") and bool(unit.call("is_in_contact")):
		return Color(1.0, 0.78, 0.34, 1.0)
	return Color(0.62, 0.92, 1.0, 1.0)


func _get_unit_proxy_rotation_y(proxy: Node3D, unit: Node, current_world_position: Vector2) -> float:
	var fallback_yaw: float = proxy.rotation_degrees.y if proxy != null else 0.0
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


func _update_unit_visual_animation(proxy: Node3D, is_moving: bool) -> bool:
	var animation_player: AnimationPlayer = _find_unit_visual_animation_player(proxy)
	if animation_player == null:
		return false
	var desired_animation: String = "walk" if is_moving else "idle"
	if not animation_player.has_animation(desired_animation):
		return false
	if animation_player.current_animation == desired_animation and animation_player.is_playing():
		return false
	animation_player.play(desired_animation)
	return true


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
	var offset: Vector3 = _get_vector3_from_variant(socket_entry.get("offset", Vector3.ZERO), Vector3.ZERO)
	socket_node.position = base_position + offset
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
		_add_runtime_missing_asset_marker(
			proxy_root,
			Vector3(0.0, 0.56, 0.0),
			"MissingAsset_unit_helmet_%s" % _sanitize_node_name(_get_unit_visual_name(null, unit_visual_entry))
		)
		return false
	var helmet_scene := _get_asset_model_scene_by_path(helmet_path)
	if helmet_scene == null:
		return false
	var helmet_instance := helmet_scene.instantiate() as Node3D
	if helmet_instance == null:
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


func _attach_unit_blaster(proxy_root: Node3D, model_root: Node3D, model_instance: Node3D, unit_visual_entry: Dictionary) -> bool:
	var blaster_path: String = _get_unit_blaster_path(unit_visual_entry)
	if blaster_path.is_empty():
		return true
	if not ResourceLoader.exists(blaster_path):
		_add_runtime_missing_asset_marker(
			proxy_root,
			Vector3(0.0, 0.50, 0.0),
			"MissingAsset_unit_blaster_%s" % _sanitize_node_name(_get_unit_visual_name(null, unit_visual_entry))
		)
		return false
	var blaster_scene := _get_asset_model_scene_by_path(blaster_path)
	if blaster_scene == null:
		return false
	var blaster_instance := blaster_scene.instantiate() as Node3D
	if blaster_instance == null:
		return false
	_normalize_asset_model_instance(blaster_instance)
	blaster_instance.name = "BlasterVisual_%s" % blaster_path.get_file().get_basename()
	var attachment_entry: Dictionary = _get_unit_blaster_attachment_entry(unit_visual_entry)
	_apply_unit_blaster_transform(blaster_instance, attachment_entry)
	if not _apply_unit_blaster_material(blaster_instance, attachment_entry):
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
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.mesh = _make_box_mesh(Vector3(cell_size * clampf(fill, 0.1, 1.0), maxf(height, 0.01), cell_size * clampf(fill, 0.1, 1.0)))
	marker.material_override = _make_material(color, true)
	var top_y: float = float(tile_data.height_level) * _get_3d_height_step()
	marker.position = _grid_to_3d_position(Vector2(grid_position), top_y + 0.014 + (height * 0.5))
	parent.add_child(marker)
	return true


func _add_marker3d(parent: Node3D, world_position: Vector2, color: Color, node_name: String, radius: float, height: float, radial_segments: int = 12) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	var marker := MeshInstance3D.new()
	marker.name = node_name
	marker.mesh = mesh
	marker.material_override = _make_material(color)
	marker.position = _world_to_3d_position(world_position, 0.28 + height * 0.5)
	if radial_segments == 4:
		marker.rotation_degrees.y = 45.0
	parent.add_child(marker)


func _add_line3d(parent: Node3D, start_position: Vector3, end_position: Vector3, color: Color, node_name: String) -> void:
	var material := _make_material(color, true)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	mesh.surface_add_vertex(start_position)
	mesh.surface_add_vertex(end_position)
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	parent.add_child(instance)


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


func _get_asset_y_offset(visual_type_id: String) -> float:
	var mapped_entry: Dictionary = _get_model_entry_for_type(visual_type_id)
	if not mapped_entry.is_empty():
		var grid: Dictionary = Dictionary(_get_terrain_3d_mapping().get("grid", {}))
		return float(grid.get("object_y_offset", 0.04)) + float(mapped_entry.get("y_offset", 0.0))
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized.begins_with("crater_") or normalized.begins_with("rail_") or normalized.begins_with("plattform_"):
		return 0.018
	return 0.028


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
	var has_catalog_texture: bool = not type_id.is_empty() and tile_catalog != null and tile_catalog.get_texture(type_id) != null

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
	var tile_color := Color(0.30, 0.35, 0.39, 1.0)
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
		return unit_entry
	var visual_entries: Dictionary = Dictionary(mapping.get("unit_visuals", {}))
	var team_entry: Dictionary = Dictionary(visual_entries.get(_get_unit_team_id(unit), {}))
	if not team_entry.is_empty():
		return team_entry
	return Dictionary(visual_entries.get("default", {}))


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
