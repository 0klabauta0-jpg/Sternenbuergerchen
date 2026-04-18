extends Node2D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TILE_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_SW.png")
const CLIFF_TEXTURE_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_SE.png")
const CLIFF_TEXTURE_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_SW.png")
const CLIFF_TEXTURE_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_NE.png")
const CLIFF_TEXTURE_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCliff_NW.png")
const CLIFF_CORNER_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_SE.png")
const CLIFF_CORNER_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_SW.png")
const CLIFF_CORNER_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_NE.png")
const CLIFF_CORNER_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_sideCorner_NW.png")
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
const CORRIDOR_STRAIGHT_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_SW.png")
const CORRIDOR_STRAIGHT_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_SE.png")
const CORRIDOR_CORNER_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_corner_SW.png")
const CORRIDOR_CORNER_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_corner_SE.png")
const CORRIDOR_CORNER_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_corner_NW.png")
const CORRIDOR_CORNER_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_corner_NE.png")
const CORRIDOR_END_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_end_SW.png")
const CORRIDOR_END_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_end_SE.png")
const CORRIDOR_END_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_end_NW.png")
const CORRIDOR_END_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_end_NE.png")
const CORRIDOR_SPLIT_SW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_split_SW.png")
const CORRIDOR_SPLIT_SE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_split_SE.png")
const CORRIDOR_SPLIT_NW: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_split_NW.png")
const CORRIDOR_SPLIT_NE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_split_NE.png")
const CORRIDOR_CROSS: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/corridor_cross_SW.png")
const DEFAULT_MAP_PATH: String = "res://maps/test_mission.json"
const DEFAULT_NEW_MAP_PATH: String = "res://maps/new_map.json"
const DEFAULT_NEW_MAP_NAME: String = "new_map"
const DEFAULT_GRID_SIZE: Vector2i = Vector2i(64, 64)
const DEFAULT_GRID_ORIGIN: Vector2 = Vector2(0.0, 0.0)
const DEFAULT_HALF_TILE_WIDTH: float = 64.0
const DEFAULT_HALF_TILE_HEIGHT: float = 32.0
const KENNEY_DIAMOND_CENTER := Vector2(256.0, 315.0)
const MIN_CAMERA_ZOOM: float = 0.1
const MAX_CAMERA_ZOOM: float = 3.0
const CAMERA_ZOOM_STEP: float = 0.05

@export var map_file_path: String = ""

var _terrain_map_data = null
var _terrain_registry = null
var _tile_catalog = null
var _tile_sprites_by_grid: Dictionary = {}
var _cliff_sprites_by_grid: Dictionary = {}
var _wall_sprites_by_grid: Dictionary = {}
var _selected_grid_position: Vector2i = Vector2i(-1, -1)
var _selected_type_id: String = ""
var _is_panning: bool = false
var _is_painting: bool = false
var _last_painted_grid: Vector2i = Vector2i(-1, -1)
var _hover_preview: Sprite2D = null
var _hover_grid_position: Vector2i = Vector2i(-1, -1)
var _dirty: bool = false
var _is_refreshing_property_controls: bool = false
var _last_undo_state: Dictionary = {}
var _current_map_path: String = DEFAULT_MAP_PATH
var _pending_dialog_action: String = ""


func _ready() -> void:
	set_process_unhandled_input(true)
	_ensure_terrain_registry()
	_load_tile_catalog()
	_populate_surface_type_options()
	_populate_edge_type_options()
	_populate_brush_size_options()
	_populate_tile_palette()
	_connect_ui_signals()
	_load_map(map_file_path if not map_file_path.is_empty() else DEFAULT_MAP_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.ctrl_pressed and key_event.physical_keycode == KEY_Z:
			_undo_last_change()
			return

	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button_event.pressed and not _is_pointer_over_control():
			_adjust_camera_zoom(CAMERA_ZOOM_STEP)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.pressed and not _is_pointer_over_control():
			_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE or mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = mouse_button_event.pressed
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_button_event.pressed:
				_is_painting = false
				_last_painted_grid = Vector2i(-1, -1)
				return
			if _is_pointer_over_control():
				return
			if _is_brush_enabled() and _has_selected_type():
				_is_painting = true
				_last_painted_grid = Vector2i(-1, -1)
				_apply_brush_at_world_position(get_global_mouse_position())
				return
			_select_tile_at_world_position(get_global_mouse_position())
			return

	if event is InputEventMouseMotion:
		var mouse_motion := event as InputEventMouseMotion
		if _is_panning:
			var camera := _get_camera()
			if camera != null:
				camera.position -= mouse_motion.relative * camera.zoom
			return
		if _is_painting and _is_brush_enabled() and _has_selected_type():
			#_apply_brush_at_world_position(get_global_mouse_position())
			return
		if _is_brush_enabled() and not _is_pointer_over_control():
			_update_hover_preview(get_global_mouse_position())
			return
		_hide_hover_preview()


func _load_map(path: String) -> void:
	_current_map_path = path
	_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", path)
	if _terrain_map_data == null or _terrain_map_data.call("get_tiles").is_empty():
		_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call(
			"create_empty",
			path.get_file().get_basename() if not path.is_empty() else DEFAULT_NEW_MAP_NAME,
			DEFAULT_GRID_SIZE,
			DEFAULT_GRID_ORIGIN,
			DEFAULT_HALF_TILE_WIDTH,
			DEFAULT_HALF_TILE_HEIGHT
		)

	_tile_sprites_by_grid.clear()
	_cliff_sprites_by_grid.clear()
	_selected_grid_position = Vector2i(-1, -1)
	_last_undo_state.clear()
	_mark_dirty(false)
	_rebuild_registry_from_map_data()
	_rebuild_tile_sprites()
	_center_camera_on_map()
	_refresh_selection_visual()
	_refresh_property_panel()
	_refresh_top_bar()


func _create_new_map() -> void:
	_current_map_path = DEFAULT_NEW_MAP_PATH
	_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call(
		"create_empty",
		DEFAULT_NEW_MAP_NAME,
		DEFAULT_GRID_SIZE,
		DEFAULT_GRID_ORIGIN,
		DEFAULT_HALF_TILE_WIDTH,
		DEFAULT_HALF_TILE_HEIGHT
	)
	_tile_sprites_by_grid.clear()
	_cliff_sprites_by_grid.clear()
	_selected_grid_position = Vector2i(-1, -1)
	_last_undo_state.clear()
	_mark_dirty(false)
	_rebuild_registry_from_map_data()
	_rebuild_tile_sprites()
	_center_camera_on_map()
	_refresh_selection_visual()
	_refresh_property_panel()
	_refresh_top_bar()


func _save_current_map() -> void:
	if _terrain_map_data == null or _current_map_path.is_empty():
		return

	var map_name: String = _current_map_path.get_file().get_basename()
	if not map_name.is_empty() and _terrain_map_data.has_method("set_map_name"):
		_terrain_map_data.call("set_map_name", map_name)

	var save_error: Error = _terrain_map_data.call("save_to_file", _current_map_path)
	if save_error != OK:
		push_warning("MapEditor could not save map to %s" % _current_map_path)
		return

	_mark_dirty(false)
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
	var tile_container := get_node_or_null("TileContainer") as Node2D
	if tile_container == null:
		return

	for child in tile_container.get_children():
		child.queue_free()

	for tile_data in _terrain_map_data.call("get_tiles"):
		var tile_texture: Texture2D = _resolve_tile_texture(tile_data)
		var tile_sprite := Sprite2D.new()
		tile_sprite.texture = tile_texture
		tile_sprite.centered = false
		tile_sprite.z_index = -20
		tile_sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
		tile_sprite.modulate = _build_tile_modulate(tile_data)
		tile_container.add_child(tile_sprite)
		_tile_sprites_by_grid[tile_data.grid_position] = tile_sprite

	_rebuild_all_cliff_overlays()
	_rebuild_all_wall_overlays()
	_rebuild_grid_overlay()


func _refresh_tile_visual(tile_data) -> void:
	if tile_data == null or not _tile_sprites_by_grid.has(tile_data.grid_position):
		return

	var tile_sprite := _tile_sprites_by_grid[tile_data.grid_position] as Sprite2D
	if tile_sprite == null:
		return

	var tile_texture: Texture2D = _resolve_tile_texture(tile_data)
	tile_sprite.texture = tile_texture
	tile_sprite.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
	tile_sprite.modulate = _build_tile_modulate(tile_data)
	_update_cliff_overlays_around(tile_data.grid_position)
	_update_wall_overlays_around(tile_data.grid_position)


func _build_tile_modulate(tile_data) -> Color:
	if tile_data == null:
		return Color(1.0, 1.0, 1.0, 1.0)

	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	if not type_id.is_empty() and _tile_catalog != null and _tile_catalog.get_texture(type_id) != null:
		return Color(1.0, 1.0, 1.0, 1.0)

	var tile_color: Color = Color(1.0, 1.0, 1.0, 1.0)
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

	return tile_color


func _select_tile_at_world_position(world_position: Vector2) -> void:
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return

	_selected_grid_position = tile_data.grid_position
	_refresh_selection_visual()
	_refresh_property_panel()


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

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var target_grid: Vector2i = center_grid + Vector2i(dx, dy)
			var target_tile = _terrain_map_data.call("get_tile_at_grid", target_grid) if _terrain_map_data != null else null
			if target_tile == null:
				continue

			if not _selected_type_id.is_empty() and _tile_catalog != null and _tile_catalog.has_type(_selected_type_id):
				if dx == 0 and dy == 0:
					_store_undo_state(target_tile)
				if _tile_catalog.apply_type_to_tile(target_tile, _selected_type_id):
					any_changed = true
					_refresh_tile_visual(target_tile)
			else:
				var patch: Dictionary = {
					"walkable": _get_walkable_checkbox().button_pressed,
					"surface_type": _get_selected_surface_type(),
				}
				if _apply_tile_patch(target_tile, patch):
					any_changed = true
					_refresh_tile_visual(target_tile)

	if any_changed:
		_mark_dirty(true)

	_selected_grid_position = center_grid
	_refresh_selection_visual()
	_refresh_property_panel()
	_hide_hover_preview()


func _resolve_tile_at_world_position(world_position: Vector2):
	if _terrain_map_data == null:
		return null

	var grid_position: Vector2i = _terrain_registry.world_to_grid(world_position)
	return _terrain_map_data.call("get_tile_at_grid", grid_position)


func _refresh_selection_visual() -> void:
	var outline := get_node_or_null("SelectionOutline") as Line2D
	if outline == null:
		return

	outline.clear_points()
	var tile_data = _get_selected_tile()
	if tile_data == null:
		return

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_width: float = float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH))
	var half_height: float = float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))
	var center: Vector2 = tile_data.world_position
	outline.add_point(center + Vector2(0.0, -half_height))
	outline.add_point(center + Vector2(half_width, 0.0))
	outline.add_point(center + Vector2(0.0, half_height))
	outline.add_point(center + Vector2(-half_width, 0.0))
	outline.add_point(center + Vector2(0.0, -half_height))


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

	_is_refreshing_property_controls = true
	if tile_data == null:
		tile_label.text = "Tile: -"
		if type_label != null:
			type_label.text = "Typ: -"
		walkable_checkbox.button_pressed = false
		blocks_los_checkbox.button_pressed = false
		cover_spinbox.value = 0
		height_spinbox.value = 0
		surface_option_button.select(_find_surface_option_index(TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE))
		if edge_type_option_button != null:
			edge_type_option_button.select(0)
		_set_property_controls_enabled(false)
		_is_refreshing_property_controls = false
		return

	tile_label.text = "Tile: (%d, %d)" % [tile_data.grid_position.x, tile_data.grid_position.y]
	if type_label != null:
		var tile_type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
		if not tile_type_id.is_empty() and _tile_catalog != null and _tile_catalog.has_type(tile_type_id):
			type_label.text = "Typ: %s" % _tile_catalog.get_display_name(tile_type_id)
		else:
			var matched_type_id: String = _find_matching_type_id(tile_data)
			if matched_type_id.is_empty():
				type_label.text = "Typ: (custom)"
			else:
				type_label.text = "Typ: %s" % _tile_catalog.get_display_name(matched_type_id)
	walkable_checkbox.button_pressed = bool(tile_data.walkable)
	blocks_los_checkbox.button_pressed = bool(tile_data.blocks_los)
	cover_spinbox.value = int(tile_data.cover_value)
	height_spinbox.value = int(tile_data.height_level)
	surface_option_button.select(_find_surface_option_index(String(tile_data.surface_type)))
	if edge_type_option_button != null:
		edge_type_option_button.select(0 if String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF else 1)
	_set_property_controls_enabled(true)
	_is_refreshing_property_controls = false


func _set_property_controls_enabled(is_enabled: bool) -> void:
	_get_walkable_checkbox().disabled = not is_enabled
	_get_blocks_los_checkbox().disabled = not is_enabled
	_get_cover_spinbox().editable = is_enabled
	_get_height_spinbox().editable = is_enabled
	_get_surface_option_button().disabled = not is_enabled
	var edge_type_btn := _get_edge_type_option_button()
	if edge_type_btn != null:
		edge_type_btn.disabled = not is_enabled


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

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var target_grid: Vector2i = center_grid + Vector2i(dx, dy)
			var target_tile = _terrain_map_data.call("get_tile_at_grid", target_grid) if _terrain_map_data != null else null
			if target_tile == null:
				continue

			if _apply_tile_patch(target_tile, patch):
				any_changed = true
				_refresh_tile_visual(target_tile)

	if not any_changed:
		return

	_mark_dirty(true)
	_refresh_property_panel()


func _apply_tile_patch(tile_data, patch: Dictionary) -> bool:
	if tile_data == null or patch.is_empty():
		return false

	var next_walkable: bool = bool(patch.get("walkable", tile_data.walkable))
	var next_blocks_los: bool = bool(patch.get("blocks_los", tile_data.blocks_los))
	var next_cover_value: int = clampi(int(patch.get("cover_value", tile_data.cover_value)), 0, 100)
	var next_height_level: int = clampi(int(patch.get("height_level", tile_data.height_level)), 0, 2)
	var next_surface_type: String = String(patch.get("surface_type", tile_data.surface_type))
	var next_edge_type: String = String(patch.get("edge_type", tile_data.edge_type))

	var changed: bool = (
		tile_data.walkable != next_walkable
		or tile_data.blocks_los != next_blocks_los
		or int(tile_data.cover_value) != next_cover_value
		or int(tile_data.height_level) != next_height_level
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
	tile_data.surface_type = next_surface_type
	tile_data.edge_type = next_edge_type
	return true


func _store_undo_state(tile_data) -> void:
	if tile_data == null or not tile_data.has_method("to_dict"):
		return

	_last_undo_state = {
		"grid_position": tile_data.grid_position,
		"tile_dict": tile_data.call("to_dict"),
	}
	_refresh_top_bar()


func _undo_last_change() -> void:
	if _last_undo_state.is_empty() or _terrain_map_data == null:
		return

	var grid_position: Vector2i = _last_undo_state.get("grid_position", Vector2i(-1, -1))
	var tile_dict: Dictionary = _last_undo_state.get("tile_dict", {})
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null or tile_dict.is_empty():
		return

	var restored_tile = TERRAIN_TILE_DATA_SCRIPT.call("from_dict", tile_dict)
	tile_data.tile_id = restored_tile.tile_id
	tile_data.type_id = restored_tile.type_id
	tile_data.grid_position = restored_tile.grid_position
	tile_data.world_position = restored_tile.world_position
	tile_data.walkable = restored_tile.walkable
	tile_data.blocks_los = restored_tile.blocks_los
	tile_data.cover_value = restored_tile.cover_value
	tile_data.height_level = restored_tile.height_level
	tile_data.surface_type = restored_tile.surface_type
	tile_data.edge_type = restored_tile.edge_type

	_selected_grid_position = grid_position
	_last_undo_state.clear()
	_refresh_tile_visual(tile_data)
	_mark_dirty(true)
	_refresh_selection_visual()
	_refresh_property_panel()
	_refresh_top_bar()


func _refresh_top_bar() -> void:
	var title_label := get_node_or_null("UI/TopBar/Margin/HBox/TitleLabel") as Label
	var path_label := get_node_or_null("UI/TopBar/Margin/HBox/PathLabel") as Label
	var save_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveButton") as Button
	var undo_button := get_node_or_null("UI/TopBar/Margin/HBox/UndoButton") as Button
	if title_label != null:
		title_label.text = "Map Editor%s" % (" *" if _dirty else "")
	if path_label != null:
		path_label.text = _current_map_path if not _current_map_path.is_empty() else "(unsaved)"
	if save_button != null:
		save_button.disabled = _terrain_map_data == null or _current_map_path.is_empty()
	if undo_button != null:
		undo_button.disabled = _last_undo_state.is_empty()


func _mark_dirty(is_dirty: bool) -> void:
	_dirty = is_dirty
	_refresh_top_bar()


func _adjust_camera_zoom(delta: float) -> void:
	var camera := _get_camera()
	if camera == null:
		return

	var next_zoom: float = clampf(camera.zoom.x + delta, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	camera.zoom = Vector2(next_zoom, next_zoom)


func _center_camera_on_map() -> void:
	var camera := _get_camera()
	if camera == null or _terrain_map_data == null:
		return

	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	var center_world: Vector2 = _terrain_registry.grid_to_world(Vector2i(grid_size.x / 2, grid_size.y / 2))
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
	option_button.select(0)


func _populate_edge_type_options() -> void:
	var option_button := _get_edge_type_option_button()
	if option_button == null:
		return

	option_button.clear()
	option_button.add_item("Cliff")
	option_button.add_item("Slope")
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


func _connect_ui_signals() -> void:
	var save_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveButton") as Button
	var load_button := get_node_or_null("UI/TopBar/Margin/HBox/LoadButton") as Button
	var new_map_button := get_node_or_null("UI/TopBar/Margin/HBox/NewMapButton") as Button
	var undo_button := get_node_or_null("UI/TopBar/Margin/HBox/UndoButton") as Button
	var walkable_checkbox := _get_walkable_checkbox()
	var blocks_los_checkbox := _get_blocks_los_checkbox()
	var cover_spinbox := _get_cover_spinbox()
	var height_spinbox := _get_height_spinbox()
	var surface_option_button := _get_surface_option_button()
	var edge_type_option_button := _get_edge_type_option_button()
	var file_dialog := get_node_or_null("UI/LoadDialog") as FileDialog
	var confirm_dialog := get_node_or_null("UI/DirtyConfirmDialog") as ConfirmationDialog
	var tile_type_list := _get_tile_type_list()
	if save_button != null and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
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
	if tile_type_list != null and not tile_type_list.item_selected.is_connected(_on_tile_type_selected):
		tile_type_list.item_selected.connect(_on_tile_type_selected)
	if file_dialog != null:
		file_dialog.access = FileDialog.ACCESS_RESOURCES
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.current_dir = "res://maps"
		file_dialog.filters = PackedStringArray(["*.json ; JSON terrain map"])
		if not file_dialog.file_selected.is_connected(_on_load_file_selected):
			file_dialog.file_selected.connect(_on_load_file_selected)
	if confirm_dialog != null and not confirm_dialog.confirmed.is_connected(_on_dirty_confirmed):
		confirm_dialog.confirmed.connect(_on_dirty_confirmed)


func _on_save_pressed() -> void:
	_save_current_map()


func _on_load_pressed() -> void:
	if _dirty:
		_open_dirty_confirmation("load")
		return

	_open_load_dialog()


func _on_new_map_pressed() -> void:
	if _dirty:
		_open_dirty_confirmation("new")
		return

	_create_new_map()


func _on_undo_pressed() -> void:
	_undo_last_change()


func _on_property_controls_changed(_value: bool) -> void:
	_apply_property_controls_to_selected_tile()


func _on_property_controls_value_changed(_value: float) -> void:
	_apply_property_controls_to_selected_tile()


func _on_surface_selected(_index: int) -> void:
	_apply_property_controls_to_selected_tile()


func _on_edge_type_selected(_index: int) -> void:
	_apply_property_controls_to_selected_tile()


func _on_tile_type_selected(index: int) -> void:
	var tile_type_list := _get_tile_type_list()
	if tile_type_list == null or _tile_catalog == null:
		return

	var type_ids: Array[String] = _tile_catalog.get_type_ids()
	if index < 0 or index >= type_ids.size():
		_selected_type_id = ""
		return

	_selected_type_id = type_ids[index]
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	if brush_button != null and not brush_button.button_pressed:
		brush_button.button_pressed = true


func _on_load_file_selected(path: String) -> void:
	_load_map(path)


func _on_dirty_confirmed() -> void:
	match _pending_dialog_action:
		"load":
			_open_load_dialog()
		"new":
			_create_new_map()

	_pending_dialog_action = ""


func _open_load_dialog() -> void:
	var file_dialog := get_node_or_null("UI/LoadDialog") as FileDialog
	if file_dialog == null:
		return

	file_dialog.current_dir = "res://maps"
	file_dialog.popup_centered_ratio(0.65)


func _open_dirty_confirmation(action_name: String) -> void:
	var confirm_dialog := get_node_or_null("UI/DirtyConfirmDialog") as ConfirmationDialog
	if confirm_dialog == null:
		return

	_pending_dialog_action = action_name
	confirm_dialog.dialog_text = "Ungespeicherte Aenderungen gehen verloren. Fortfahren?"
	confirm_dialog.popup_centered()


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


func _get_walkable_checkbox() -> CheckBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/WalkableCheckBox") as CheckBox


func _get_blocks_los_checkbox() -> CheckBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/BlocksLosCheckBox") as CheckBox


func _get_cover_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/CoverRow/CoverSpinBox") as SpinBox


func _get_height_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/HeightRow/HeightSpinBox") as SpinBox


func _get_edge_type_option_button() -> OptionButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/EdgeTypeRow/EdgeTypeOptionButton") as OptionButton


func _get_brush_size_option_button() -> OptionButton:
	return get_node_or_null("UI/TopBar/Margin/HBox/BrushSizeOptionButton") as OptionButton


func _get_brush_radius() -> int:
	var option_button := _get_brush_size_option_button()
	if option_button == null or option_button.selected < 0:
		return 0

	# Index 0 = 1x1 (radius 0), Index 1 = 3x3 (radius 1), Index 2 = 5x5 (radius 2)
	return option_button.selected


func _get_surface_option_button() -> OptionButton:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/SurfaceRow/SurfaceOptionButton") as OptionButton


func _get_selected_surface_type() -> String:
	var option_button := _get_surface_option_button()
	if option_button == null or option_button.selected < 0:
		return TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE

	return option_button.get_item_text(option_button.selected)


func _get_selected_edge_type() -> String:
	var option_button := _get_edge_type_option_button()
	if option_button == null or option_button.selected < 0:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF

	# Index 0 = "Cliff", Index 1 = "Slope"
	if option_button.selected == 1:
		return TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
	return TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF


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
	if tile_type_list == null or _tile_catalog == null:
		return

	tile_type_list.clear()
	for tile_type in _tile_catalog.get_all_types():
		tile_type_list.add_item(String(tile_type.get("display_name", tile_type.get("type_id", "?"))))


func _get_tile_type_list() -> ItemList:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/TileTypeList") as ItemList


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
	if tile_data == null or _tile_catalog == null:
		return TILE_TEXTURE

	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	if type_id.is_empty():
		return TILE_TEXTURE

	var type_texture: Texture2D = _tile_catalog.get_texture(type_id)
	if type_texture != null:
		return type_texture

	return TILE_TEXTURE


func _rebuild_all_cliff_overlays() -> void:
	_clear_cliff_overlays()
	if _terrain_map_data == null:
		return

	for tile_data in _terrain_map_data.call("get_tiles"):
		if int(tile_data.height_level) > 0 and not _is_object_type(tile_data):
			_create_cliff_overlays_for_tile(tile_data)


func _update_cliff_overlays_around(grid_position: Vector2i) -> void:
	var positions_to_update: Array[Vector2i] = [grid_position]
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		positions_to_update.append(grid_position + offset)

	for pos in positions_to_update:
		_remove_cliff_overlays_at(pos)
		if _terrain_map_data == null:
			continue
		var tile_data = _terrain_map_data.call("get_tile_at_grid", pos)
		if tile_data != null and int(tile_data.height_level) > 0 and not _is_object_type(tile_data):
			_create_cliff_overlays_for_tile(tile_data)


func _create_cliff_overlays_for_tile(tile_data) -> void:
	if tile_data == null or _terrain_map_data == null:
		return

	var cliff_container := get_node_or_null("CliffContainer") as Node2D
	if cliff_container == null:
		return

	var my_height: int = int(tile_data.height_level)
	var grid_pos: Vector2i = tile_data.grid_position
	var is_slope: bool = String(tile_data.edge_type) == TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE
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
		[Vector2i(1, 0), Vector2i(0, 1), CLIFF_CORNER_NE],
		[Vector2i(1, 0), Vector2i(0, -1), CLIFF_CORNER_NW],
		[Vector2i(-1, 0), Vector2i(0, 1), CLIFF_CORNER_SE],
		[Vector2i(-1, 0), Vector2i(0, -1), CLIFF_CORNER_SW],
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
	if tile_data == null:
		return false
	var type_id: String = String(tile_data.type_id) if tile_data.type_id is String else ""
	return type_id.begins_with("wall_") or type_id.begins_with("rock_")


func _rebuild_all_wall_overlays() -> void:
	_clear_wall_overlays()
	if _terrain_map_data == null:
		return

	for tile_data in _terrain_map_data.call("get_tiles"):
		if _is_object_type(tile_data):
			_create_wall_overlays_for_tile(tile_data)


func _update_wall_overlays_around(grid_position: Vector2i) -> void:
	var positions_to_update: Array[Vector2i] = [grid_position]
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		positions_to_update.append(grid_position + offset)

	for pos in positions_to_update:
		_remove_wall_overlays_at(pos)
		if _terrain_map_data == null:
			continue
		var tile_data = _terrain_map_data.call("get_tile_at_grid", pos)
		if tile_data != null and _is_object_type(tile_data):
			_create_wall_overlays_for_tile(tile_data)


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
			texture = WALL_TEXTURE_SE
		"wall_straight_sw":
			texture = WALL_TEXTURE_SW
		"wall_straight_ne":
			texture = WALL_TEXTURE_NE
		"wall_straight_nw":
			texture = WALL_TEXTURE_NW
		"wall_corner_se":
			texture = WALL_CORNER_NW
		"wall_corner_sw":
			texture = WALL_CORNER_NE
		"wall_corner_ne":
			texture = WALL_CORNER_SW
		"wall_corner_nw":
			texture = WALL_CORNER_SE
		"rock_small":
			texture = ROCK_SMALL_TEXTURE
		"rock_large":
			texture = ROCK_LARGE_TEXTURE
		_:
			# Legacy fallback for old "wall" type_id — auto-detect from neighbors
			if not _is_object_type(tile_data):
				return
			texture = WALL_TEXTURE_SW

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


func _rebuild_grid_overlay() -> void:
	var grid_overlay := get_node_or_null("GridOverlay") as Node2D
	if grid_overlay == null:
		return

	for child in grid_overlay.get_children():
		child.queue_free()

	if _terrain_map_data == null:
		return

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_w: float = float(tile_size.get("half_width", DEFAULT_HALF_TILE_WIDTH))
	var half_h: float = float(tile_size.get("half_height", DEFAULT_HALF_TILE_HEIGHT))
	var grid_color: Color = Color(0.0, 0.0, 0.0, 0.35)
	var grid_width: float = 1.0

	for tile_data in _terrain_map_data.call("get_tiles"):
		var center: Vector2 = tile_data.world_position
		var top: Vector2 = center + Vector2(0.0, -half_h)
		var right: Vector2 = center + Vector2(half_w, 0.0)
		var bottom: Vector2 = center + Vector2(0.0, half_h)
		var left: Vector2 = center + Vector2(-half_w, 0.0)

		var line := Line2D.new()
		line.width = grid_width
		line.default_color = grid_color
		line.add_point(top)
		line.add_point(right)
		line.add_point(bottom)
		line.add_point(left)
		line.add_point(top)
		grid_overlay.add_child(line)

	# --- Compass labels at the four diamond corners ---
	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	var origin: Vector2 = _terrain_map_data.call("get_grid_origin")
	var max_x: int = grid_size.x - 1
	var max_y: int = grid_size.y - 1

	# Corner world positions (from _grid_to_world formula)
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

	var preview_texture: Texture2D = TILE_TEXTURE
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
	_hover_preview.position = tile_data.world_position - KENNEY_DIAMOND_CENTER
	_hover_preview.modulate = Color(1.0, 1.0, 1.0, 0.4)
	_hover_preview.visible = true


func _hide_hover_preview() -> void:
	_hover_grid_position = Vector2i(-1, -1)
	if _hover_preview != null:
		_hover_preview.visible = false
