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
const CAMERA_NAME: String = "Camera3D"
const LIGHT_NAME: String = "SunLight3D"

const TILE_SPACING: float = 2.0
const TILE_THICKNESS: float = 0.12
const HEIGHT_STEP: float = 0.34
const OBJECT_HEIGHT_STEP: float = 0.42
const CAMERA_DEFAULT_SIZE: float = 34.0
const CAMERA_MIN_SIZE: float = 5.5
const CAMERA_MAX_SIZE: float = 120.0
const CAMERA_ZOOM_STEP: float = 2.2
const CAMERA_PAN_UNITS_PER_SECOND: float = 9.0
const CAMERA_DRAG_PAN_FACTOR: float = 0.065
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
const TEXTURE_CARD_PIXEL_SIZE: float = 0.0062
const TILE_TEXTURE_PIXEL_SIZE: float = 0.0060
const UNIT_TEXTURE_PIXEL_SIZE: float = 0.0105
const DROPSHIP_TEXTURE_PIXEL_SIZE: float = 0.0094
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)
const KENNEY_MODEL_ROOT: String = "res://Assets/kenney_space-kit/Models/GLTF format"
const KENNEY_AUTHORING_OFFSET_X: float = 2.0
const KENNEY_AUTHORING_OFFSET_Z: float = 1.5
const KENNEY_OFFSET_EPSILON: float = 0.01
const FRIENDLY_UNIT_MODEL_NAME: String = "astronautA"
const ENEMY_UNIT_MODEL_NAME: String = "astronautB"
const DROPSHIP_MODEL_NAME: String = "craft_speederB"
const UNIT_MODEL_SCALE: float = 2.1
const DROPSHIP_MODEL_SCALE: float = 2.35

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
var _camera: Camera3D = null

var _terrain_map_data = null
var _tile_catalog = null
var _model_scene_cache: Dictionary = {}
var _unit_nodes: Array = []
var _unit_proxies_by_id: Dictionary = {}
var _selected_grid_positions: Array = []
var _order_payload: Dictionary = {}
var _contact_entries: Array = []
var _contact_selected_fireteam_ids: PackedStringArray = PackedStringArray()
var _drop_payload: Dictionary = {}

var _grid_size: Vector2i = Vector2i.ZERO
var _grid_origin_world: Vector2 = Vector2.ZERO
var _half_tile_width: float = DEFAULT_HALF_TILE_WIDTH
var _half_tile_height: float = DEFAULT_HALF_TILE_HEIGHT
var _focus_grid_position: Vector2 = Vector2.ZERO
var _camera_size: float = CAMERA_DEFAULT_SIZE
var _camera_yaw_degrees: float = 45.0
var _camera_pitch_degrees: float = 58.0
var _map_tile_count: int = 0
var _tile_texture_count: int = 0
var _asset_texture_count: int = 0
var _asset_model_count: int = 0
var _placeholder_object_count: int = 0
var _unit_texture_count: int = 0
var _unit_model_count: int = 0
var _dropship_texture_visible: bool = false
var _dropship_model_visible: bool = false
var _map_render_duration_msec: int = 0
var _marker_count: int = 0
var _patrol_segment_count: int = 0
var _area_order_count: int = 0
var _contact_count: int = 0


func _ready() -> void:
	layer = -100
	_ensure_nodes()
	_resize_subviewport()
	_update_camera_transform()
	_request_viewport_redraw()
	set_process(true)


func _process(_delta: float) -> void:
	_resize_subviewport()
	_sync_unit_proxies()


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
	_map_tile_count = 0
	_tile_texture_count = 0
	_asset_texture_count = 0
	_asset_model_count = 0
	_placeholder_object_count = 0
	_marker_count = 0
	_patrol_segment_count = 0
	if _terrain_map_data == null:
		_map_render_duration_msec = Time.get_ticks_msec() - render_started_at_msec
		return

	for tile_data in Array(_terrain_map_data.call("get_tiles")):
		_add_tile_visual(tile_data)
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
	_order_payload = order_payload.duplicate(true)
	_rebuild_order_visuals()
	_request_viewport_redraw()


func set_contact_entries(contact_entries: Array, selected_fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	_contact_entries.clear()
	for entry_variant in contact_entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			_contact_entries.append(Dictionary(entry_variant).duplicate(true))
	_contact_selected_fireteam_ids = selected_fireteam_ids.duplicate()
	_rebuild_contact_visuals()
	_request_viewport_redraw()


func set_mission_drop_visual_state(drop_payload: Dictionary) -> void:
	_drop_payload = drop_payload.duplicate(true)
	_rebuild_drop_visuals()
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


func pan_camera_pixels(pixel_delta: Vector2) -> void:
	if pixel_delta == Vector2.ZERO:
		return
	var viewport_height: float = maxf(float(_get_viewport_size().y), 1.0)
	var scale: float = _camera_size / viewport_height
	pan_camera(pixel_delta * CAMERA_DRAG_PAN_FACTOR * scale, 1.0)


func rotate_camera(delta_degrees: float) -> void:
	_camera_yaw_degrees = wrapf(_camera_yaw_degrees + delta_degrees, 0.0, 360.0)
	_update_camera_transform()


func zoom_camera(delta_steps: float) -> void:
	_camera_size = clampf(_camera_size - (delta_steps * CAMERA_ZOOM_STEP), CAMERA_MIN_SIZE, CAMERA_MAX_SIZE)
	_update_camera_transform()


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
	return {
		"tile_count": _map_tile_count,
		"tile_texture_count": _tile_texture_count,
		"asset_texture_count": _asset_texture_count,
		"asset_model_count": _asset_model_count,
		"placeholder_object_count": _placeholder_object_count,
		"unit_texture_count": _unit_texture_count,
		"unit_model_count": _unit_model_count,
		"marker_count": _marker_count,
		"patrol_segment_count": _patrol_segment_count,
		"selected_grid_count": _selected_grid_positions.size(),
		"unit_proxy_count": _unit_proxies_by_id.size(),
		"area_order_count": _area_order_count,
		"contact_count": _contact_count,
		"has_lz": bool(_drop_payload.get("has_lz_position", false)),
		"dropship_visible": bool(_drop_payload.get("dropship_visible", false)),
		"dropship_texture_visible": _dropship_texture_visible,
		"dropship_model_visible": _dropship_model_visible,
		"camera_yaw_degrees": _camera_yaw_degrees,
		"camera_size": _camera_size,
		"map_render_duration_msec": _map_render_duration_msec,
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
		light.light_energy = 1.25
		light.rotation_degrees = Vector3(-58.0, -42.0, 0.0)
		_world_root.add_child(light)


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


func _request_viewport_redraw() -> void:
	if _subviewport == null:
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
	var top_y: float = float(height_level) * HEIGHT_STEP
	var tile_texture: Texture2D = _resolve_tile_texture(tile_data)
	var tile_sprite := _add_texture_card(
		_map_root,
		tile_texture,
		_grid_to_3d_position(Vector2(tile_data.grid_position), top_y + 0.004),
		"Tile_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y],
		TILE_TEXTURE_PIXEL_SIZE,
		_get_kenney_anchor_offset(tile_texture),
		_build_tile_modulate(tile_data)
	)
	if tile_sprite != null:
		_tile_texture_count += 1
	_map_tile_count += 1

	var object_type_id: String = String(tile_data.object_type_id) if tile_data.object_type_id is String else ""
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	var visual_type_id: String = _resolve_tile_asset_type_id(object_type_id, type_id)
	if not visual_type_id.is_empty() or bool(tile_data.blocks_los) or int(tile_data.object_height) > 0:
		_add_object_visual(tile_data, top_y, visual_type_id)


func _add_object_visual(tile_data, top_y: float, visual_type_id: String) -> void:
	if not visual_type_id.is_empty() and _add_asset_texture_visual(tile_data, top_y, visual_type_id):
		return
	if not visual_type_id.is_empty() and _add_asset_model_visual(tile_data, top_y, visual_type_id):
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

	var mesh := BoxMesh.new()
	mesh.size = Vector3(TILE_SPACING * 0.62, object_height, TILE_SPACING * 0.62)
	var instance := MeshInstance3D.new()
	instance.name = "Object_%d_%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
	instance.mesh = mesh
	instance.material_override = _make_material(_get_object_color(type_id, tile_data))
	instance.position = _grid_to_3d_position(Vector2(tile_data.grid_position), top_y + (object_height * 0.5))
	_map_root.add_child(instance)
	_placeholder_object_count += 1


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
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.position = local_position
	parent.add_child(sprite)
	return sprite


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
		var mesh := BoxMesh.new()
		mesh.size = Vector3(TILE_SPACING * 0.98, 0.05, TILE_SPACING * 0.98)
		var selection := MeshInstance3D.new()
		selection.name = "Selection_%d_%d" % [grid_position.x, grid_position.y]
		selection.mesh = mesh
		selection.material_override = _make_material(Color(1.0, 0.94, 0.35, 0.52), true)
		selection.position = _grid_to_3d_position(Vector2(grid_position), (float(tile_data.height_level) * HEIGHT_STEP) + 0.09)
		_selection_root.add_child(selection)


func _rebuild_order_visuals() -> void:
	_clear_children(_order_root)
	_area_order_count = 0
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
		var tile_marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(TILE_SPACING * 0.92, 0.045, TILE_SPACING * 0.92)
		tile_marker.mesh = mesh
		tile_marker.material_override = _make_material(Color(color.r, color.g, color.b, 0.34), true)
		tile_marker.position = _world_to_3d_position(Vector2(world_variant), 0.19)
		_order_root.add_child(tile_marker)
	var center_position: Vector2 = Vector2(area_data.get("center_position", tile_world_positions[0]))
	_add_marker3d(_order_root, center_position, color, "AreaOrder_%s" % String(area_data.get("area_order_id", "")), 0.42, 0.36)
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
		_add_marker3d(_order_root, target_position, command_color, "Waypoint", 0.32, 0.30)
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
	if _drop_root == null or _drop_payload.is_empty():
		return
	if bool(_drop_payload.get("has_lz_position", false)) and typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
		var lz_position: Vector2 = Vector2(_drop_payload.get("lz_position", Vector2.ZERO))
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.88
		mesh.bottom_radius = 0.88
		mesh.height = 0.045
		mesh.radial_segments = 24
		var lz := MeshInstance3D.new()
		lz.name = "LZMarker3D"
		lz.mesh = mesh
		lz.material_override = _make_material(Color(0.38, 1.0, 0.62, 0.44), true)
		lz.position = _world_to_3d_position(lz_position, 0.24)
		_drop_root.add_child(lz)

	if bool(_drop_payload.get("dropship_visible", false)) and typeof(_drop_payload.get("dropship_position", null)) == TYPE_VECTOR2:
		var ship_position: Vector2 = Vector2(_drop_payload.get("dropship_position", Vector2.ZERO))
		_add_dropship_proxy(ship_position)
		if typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
			_add_line3d(_drop_root, _world_to_3d_position(ship_position, 0.52), _world_to_3d_position(Vector2(_drop_payload.get("lz_position", Vector2.ZERO)), 0.52), Color(0.56, 1.0, 0.68, 0.86), "DropshipApproach")


func _add_dropship_proxy(world_position: Vector2) -> void:
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

	var model_scene := _get_asset_model_scene_by_name(DROPSHIP_MODEL_NAME)
	if model_scene != null:
		var model_instance := model_scene.instantiate() as Node3D
		if model_instance != null:
			_normalize_asset_model_instance(model_instance)
			var craft_root := Node3D.new()
			craft_root.name = "DropshipModel_%s" % DROPSHIP_MODEL_NAME
			craft_root.position = _world_to_3d_position(world_position, 0.68)
			craft_root.rotation_degrees.y = _get_dropship_rotation_y(world_position)
			craft_root.scale = Vector3.ONE * DROPSHIP_MODEL_SCALE
			craft_root.add_child(model_instance)
			_drop_root.add_child(craft_root)
			_dropship_model_visible = true
			return

	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(2.9, 0.46, 1.25)
	var body := MeshInstance3D.new()
	body.name = "DropshipProxy"
	body.mesh = body_mesh
	body.material_override = _make_material(Color(0.95, 0.76, 0.32, 0.96))
	body.position = _world_to_3d_position(world_position, 0.72)
	body.rotation_degrees.y = -_camera_yaw_degrees
	_drop_root.add_child(body)

	var wing_mesh := BoxMesh.new()
	wing_mesh.size = Vector3(1.05, 0.16, 2.45)
	var wing := MeshInstance3D.new()
	wing.name = "DropshipWing"
	wing.mesh = wing_mesh
	wing.material_override = _make_material(Color(0.72, 0.76, 0.78, 0.88))
	wing.position = body.position + Vector3(0.0, -0.04, 0.0)
	wing.rotation = body.rotation
	_drop_root.add_child(wing)


func _get_dropship_rotation_y(world_position: Vector2) -> float:
	if typeof(_drop_payload.get("lz_position", null)) == TYPE_VECTOR2:
		var lz_grid: Vector2 = _world_to_grid_float(Vector2(_drop_payload.get("lz_position", Vector2.ZERO)))
		var ship_grid: Vector2 = _world_to_grid_float(world_position)
		var delta: Vector2 = lz_grid - ship_grid
		if delta.length_squared() > 0.001:
			return rad_to_deg(atan2(delta.x, delta.y))
	return -_camera_yaw_degrees


func _sync_unit_proxies(force_rebuild: bool = false) -> void:
	_ensure_nodes()
	if _unit_root == null:
		return
	var seen_ids: Dictionary = {}
	var unit_texture_count: int = 0
	var unit_model_count: int = 0
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
		if unit is Node2D:
			var next_position: Vector3 = _world_to_3d_position((unit as Node2D).global_position, 0.28)
			if proxy.position.distance_squared_to(next_position) > 0.0001:
				changed = true
			proxy.position = next_position
		var next_rotation_y: float = -_camera_yaw_degrees
		if absf(wrapf(proxy.rotation_degrees.y - next_rotation_y, -180.0, 180.0)) > 0.01:
			changed = true
		proxy.rotation_degrees.y = next_rotation_y
		if bool(proxy.get_meta("uses_unit_texture", false)):
			unit_texture_count += 1
		if bool(proxy.get_meta("uses_kenney_model", false)):
			unit_model_count += 1
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
	if changed:
		_request_viewport_redraw()


func _create_unit_proxy(unit: Node) -> Node3D:
	var root := Node3D.new()
	var unit_texture := _get_unit_visual_texture(unit)
	if unit_texture != null:
		var unit_card := _add_texture_card(root, unit_texture, Vector3(0.0, 0.34, 0.0), "UnitTexture", UNIT_TEXTURE_PIXEL_SIZE)
		if unit_card != null:
			root.set_meta("uses_unit_texture", true)
			var weapon_texture := _get_unit_weapon_visual_texture(unit)
			if weapon_texture != null:
				_add_texture_card(root, weapon_texture, Vector3(0.0, 0.36, 0.0), "UnitWeaponTexture", UNIT_TEXTURE_PIXEL_SIZE, _get_unit_weapon_visual_offset(unit))

	if not bool(root.get_meta("uses_unit_texture", false)):
		var model_scene := _get_asset_model_scene_by_name(_get_unit_model_name(unit))
		if model_scene != null:
			var model_instance := model_scene.instantiate() as Node3D
			if model_instance != null:
				_normalize_asset_model_instance(model_instance)
				var model_root := Node3D.new()
				model_root.name = "UnitModel_%s" % _get_unit_model_name(unit)
				model_root.scale = Vector3.ONE * UNIT_MODEL_SCALE
				model_root.add_child(model_instance)
				root.add_child(model_root)
				root.set_meta("uses_kenney_model", true)

	var body := MeshInstance3D.new()
	if not bool(root.get_meta("uses_kenney_model", false)) and not bool(root.get_meta("uses_unit_texture", false)):
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.24
		mesh.height = 0.78
		body.mesh = mesh
		body.material_override = _make_material(_get_unit_color(unit))
		root.add_child(body)
	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.36
	base_mesh.bottom_radius = 0.36
	base_mesh.height = 0.045
	base_mesh.radial_segments = 16
	base.mesh = base_mesh
	base.material_override = _make_material(Color(0.05, 0.08, 0.1, 0.72), true)
	base.position.y = -0.02
	root.add_child(base)
	return root


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


func _make_material(color: Color, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	material.metallic = 0.0
	if transparent or color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
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


func _get_asset_model_scene(visual_type_id: String) -> PackedScene:
	var model_name: String = _resolve_asset_model_name(visual_type_id)
	if model_name.is_empty():
		return null
	return _get_asset_model_scene_by_name(model_name)


func _get_asset_model_scene_by_name(model_name: String) -> PackedScene:
	if model_name.strip_edges().is_empty():
		return null
	var model_path: String = "%s/%s.glb" % [KENNEY_MODEL_ROOT, model_name]
	if _model_scene_cache.has(model_path):
		return _model_scene_cache.get(model_path, null) as PackedScene
	if not ResourceLoader.exists(model_path):
		_model_scene_cache[model_path] = null
		return null
	var packed_scene := load(model_path) as PackedScene
	_model_scene_cache[model_path] = packed_scene
	return packed_scene


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
	match _get_direction_suffix(visual_type_id):
		"ne":
			return 0.0
		"se":
			return -90.0
		"sw":
			return 180.0
		"nw":
			return 90.0
		_:
			return 0.0


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
	var normalized: String = visual_type_id.strip_edges().to_lower()
	if normalized.begins_with("rock_") or normalized.begins_with("crater_"):
		return TILE_SPACING * 0.95
	if normalized.begins_with("deko_"):
		return TILE_SPACING * 0.9
	if normalized.begins_with("fahrzeug_"):
		return TILE_SPACING * 0.92
	if normalized.begins_with("gebaeude_"):
		return TILE_SPACING * 0.96
	return TILE_SPACING


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
	var tile_color := Color(0.46, 0.50, 0.46, 1.0)
	match String(tile_data.surface_type):
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD:
			tile_color = Color(0.50, 0.51, 0.49, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND:
			tile_color = Color(0.66, 0.60, 0.42, 1.0)
		TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK:
			tile_color = Color(0.43, 0.42, 0.39, 1.0)
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


func _get_unit_color(unit: Node) -> Color:
	var team_id: String = ""
	if unit != null and unit.has_method("get_team_id"):
		team_id = String(unit.call("get_team_id")).strip_edges().to_lower()
	if team_id == "team_alpha":
		return Color(0.32, 0.74, 1.0, 1.0)
	return Color(1.0, 0.34, 0.26, 1.0)


func _get_unit_visual_texture(unit: Node) -> Texture2D:
	if unit != null:
		var visual := unit.get_node_or_null("Visual") as Sprite2D
		if visual != null and visual.texture != null:
			return visual.texture
	var team_id: String = ""
	if unit != null and unit.has_method("get_team_id"):
		team_id = String(unit.call("get_team_id")).strip_edges().to_lower()
	return FRIENDLY_UNIT_TEXTURE if team_id == "team_alpha" else ENEMY_UNIT_TEXTURE


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
	var team_id: String = ""
	if unit != null and unit.has_method("get_team_id"):
		team_id = String(unit.call("get_team_id")).strip_edges().to_lower()
	return FRIENDLY_UNIT_MODEL_NAME if team_id == "team_alpha" else ENEMY_UNIT_MODEL_NAME


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


func _grid_float_to_world(grid_position: Vector2) -> Vector2:
	return Vector2(
		_grid_origin_world.x + ((grid_position.x - grid_position.y) * _half_tile_width),
		_grid_origin_world.y + ((grid_position.x + grid_position.y) * _half_tile_height)
	)


func _world_to_3d_position(world_position: Vector2, y_offset: float) -> Vector3:
	return _grid_to_3d_position(_world_to_grid_float(world_position), y_offset)


func _grid_to_3d_position(grid_position: Vector2, y_offset: float) -> Vector3:
	return Vector3(grid_position.x * TILE_SPACING, y_offset, grid_position.y * TILE_SPACING)


func _position_3d_to_world(position_3d: Vector3) -> Vector2:
	return _grid_float_to_world(Vector2(position_3d.x / TILE_SPACING, position_3d.z / TILE_SPACING))


func _clear_children(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.free()
