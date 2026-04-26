extends Node2D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_MAP_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_renderer.gd")
const TERRAIN_MARKER_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_marker_catalog.gd")
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
const PATROL_SPAWN_IDS: PackedStringArray = ["enemy_delta", "enemy_echo", "enemy_alpha", "enemy_bravo"]
const PATROL_PICK_RADIUS: float = 28.0
const MARKER_OVERLAY_NAME: String = "MarkerOverlay"
const MARKER_PICK_RADIUS: float = 26.0
const MARKER_DRAG_THRESHOLD: float = 4.0

@export var map_file_path: String = ""

var _terrain_map_data = null
var _terrain_registry = null
var _tile_catalog = null
var _terrain_renderer = null
var _tile_sprites_by_grid: Dictionary = {}
var _cliff_sprites_by_grid: Dictionary = {}
var _wall_sprites_by_grid: Dictionary = {}
var _selected_grid_position: Vector2i = Vector2i(-1, -1)
var _last_selected_surface_type: String = TERRAIN_TILE_DATA_SCRIPT.DEFAULT_SURFACE_TYPE
var _last_selected_edge_type: String = TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF
var _selected_grids: Array = []
var _selection_tool_enabled: bool = false
var _selected_type_id: String = ""
var _is_panning: bool = false
var _is_painting: bool = false
var _last_painted_grid: Vector2i = Vector2i(-1, -1)
var _hover_preview: Sprite2D = null
var _hover_grid_position: Vector2i = Vector2i(-1, -1)
var _dirty: bool = false
var _is_refreshing_property_controls: bool = false
var _is_refreshing_map_settings_controls: bool = false
var _last_undo_state: Dictionary = {}
var _current_map_path: String = DEFAULT_MAP_PATH
var _pending_dialog_action: String = ""
var _patrol_tool_enabled: bool = false
var _patrol_spawn_id: String = "enemy_delta"
var _dragged_patrol_waypoint_index: int = -1
var _marker_tool_enabled: bool = false
var _selected_marker_id: String = ""
var _dragged_marker_id: String = ""
var _dragged_marker_press_screen_position: Vector2 = Vector2.ZERO
var _is_dragging_marker: bool = false
var _has_dragged_marker: bool = false
var _is_refreshing_marker_controls: bool = false
var _marker_feedback_text: String = ""


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_ensure_terrain_registry()
	_load_tile_catalog()
	_terrain_renderer = TERRAIN_MAP_RENDERER_SCRIPT.new(_tile_catalog)
	_populate_surface_type_options()
	_populate_edge_type_options()
	_populate_brush_size_options()
	_populate_tile_palette()
	_connect_ui_signals()
	_add_selection_tool_button()
	_add_patrol_tool_controls()
	_ensure_marker_editor_controls()
	_ensure_patrol_overlay()
	_ensure_marker_overlay()
	_load_map(map_file_path if not map_file_path.is_empty() else DEFAULT_MAP_PATH)


func _process(delta: float) -> void:
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
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE or mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = mouse_button_event.pressed
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if _marker_tool_enabled and not _is_pointer_over_control():
				if mouse_button_event.pressed:
					if _handle_marker_left_press(mouse_button_event):
						return
				elif _finish_marker_drag():
					return
			if _patrol_tool_enabled and not _is_pointer_over_control():
				if mouse_button_event.pressed:
					_handle_patrol_left_click(get_global_mouse_position(), mouse_button_event.ctrl_pressed)
				else:
					_dragged_patrol_waypoint_index = -1
				return
			if not mouse_button_event.pressed:
				_is_painting = false
				_last_painted_grid = Vector2i(-1, -1)
				return
			if _is_pointer_over_control():
				return
			var grid_pos = _terrain_registry.world_to_grid(get_global_mouse_position())
			if _selection_tool_enabled:
				if mouse_button_event.ctrl_pressed:
					if _selected_grids.has(grid_pos):
						_selected_grids.erase(grid_pos)
					else:
						_selected_grids.append(grid_pos)
				else:
					_selected_grids = [grid_pos]
				_refresh_selection_visual()
				_refresh_property_panel()
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
		if _update_marker_drag(get_global_mouse_position(), mouse_motion.relative):
			return
		if _patrol_tool_enabled and _dragged_patrol_waypoint_index >= 0 and not _is_pointer_over_control():
			_move_patrol_waypoint(_dragged_patrol_waypoint_index, get_global_mouse_position())
			return
		if _is_panning:
			var camera := _get_camera()
			if camera != null:
				camera.position -= mouse_motion.relative * camera.zoom
			return
		if _is_painting and _is_brush_enabled() and _has_selected_type():
			_apply_brush_at_world_position(get_global_mouse_position())
			return
		if _is_brush_enabled() and not _is_pointer_over_control():
			_update_hover_preview(get_global_mouse_position())
			return
		_hide_hover_preview()


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
	_refresh_patrol_overlay()
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


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
	_selected_grid_position = Vector2i(-1, -1)
	_selected_grids.clear()
	_last_undo_state.clear()
	_mark_dirty(false)
	_rebuild_registry_from_map_data()
	_rebuild_tile_sprites()
	_center_camera_on_map()
	_refresh_selection_visual()
	_refresh_property_panel()
	_refresh_top_bar()
	_refresh_patrol_overlay()
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


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
	if _terrain_renderer == null:
		return
	_terrain_renderer.set_tile_catalog(_tile_catalog)
	var render_state: Dictionary = _terrain_renderer.render_map(_terrain_map_data, self)
	_tile_sprites_by_grid = render_state.get("tiles", {})
	_cliff_sprites_by_grid = render_state.get("cliffs", {})
	_wall_sprites_by_grid = render_state.get("walls", {})
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
	if _terrain_renderer == null:
		return Color(1.0, 1.0, 1.0, 1.0)
	_terrain_renderer.set_tile_catalog(_tile_catalog)
	return _terrain_renderer.build_tile_modulate(tile_data)


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
				var is_directional: bool = _selected_type_id.begins_with("cliff_") or _selected_type_id.begins_with("slope_")
				if is_directional and (dx != 0 or dy != 0):
					# Surrounding tiles get height + edge properties only, not directional type_id
					var entry: Dictionary = _tile_catalog.get_type(_selected_type_id)
					var patch: Dictionary = {
						"height_level": int(entry.get("height_level", 0)),
						"edge_type": String(entry.get("edge_type", "cliff")),
						"walkable": bool(entry.get("walkable", true)),
						"blocks_los": bool(entry.get("blocks_los", false)),
						"surface_type": String(entry.get("surface_type", "ground")),
					}
					if _apply_tile_patch(target_tile, patch):
						any_changed = true
						_refresh_tile_visual(target_tile)
				else:
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
	var outline_root := get_node_or_null("SelectionOutline") as Node2D
	if outline_root == null or _terrain_map_data == null:
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


func _add_selection_tool_button() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return

	var existing_button := button_row.get_node_or_null("SelectButton") as Button
	if existing_button != null:
		existing_button.button_pressed = _selection_tool_enabled
		return

	var select_btn := Button.new()
	select_btn.name = "SelectButton"
	select_btn.text = "Select"
	select_btn.toggle_mode = true
	select_btn.button_pressed = _selection_tool_enabled
	select_btn.toggled.connect(_on_selection_tool_toggled)
	button_row.add_child(select_btn)


func _add_patrol_tool_controls() -> void:
	var button_row := get_node_or_null("UI/TopBar/Margin/HBox") as HBoxContainer
	if button_row == null:
		return
	var patrol_button := button_row.get_node_or_null("PatrolButton") as Button
	if patrol_button == null:
		patrol_button = Button.new()
		patrol_button.name = "PatrolButton"
		patrol_button.text = "Patrol"
		patrol_button.toggle_mode = true
		patrol_button.toggled.connect(_on_patrol_tool_toggled)
		button_row.add_child(patrol_button)
	var spawn_selector := button_row.get_node_or_null("PatrolSpawnOption") as OptionButton
	if spawn_selector == null:
		spawn_selector = OptionButton.new()
		spawn_selector.name = "PatrolSpawnOption"
		spawn_selector.custom_minimum_size = Vector2(120.0, 0.0)
		button_row.add_child(spawn_selector)
	_refresh_patrol_spawn_selector()
	if not spawn_selector.item_selected.is_connected(_on_patrol_spawn_selected):
		spawn_selector.item_selected.connect(_on_patrol_spawn_selected)
	var clear_button := button_row.get_node_or_null("ClearPatrolButton") as Button
	if clear_button == null:
		clear_button = Button.new()
		clear_button.name = "ClearPatrolButton"
		clear_button.text = "Clear Patrol"
		clear_button.pressed.connect(_on_clear_patrol_pressed)
		button_row.add_child(clear_button)
	_update_patrol_topbar_state()


func _on_selection_tool_toggled(pressed: bool) -> void:
	_selection_tool_enabled = pressed
	if pressed:
		_marker_tool_enabled = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
		_is_painting = false
		_last_painted_grid = Vector2i(-1, -1)


func _on_patrol_tool_toggled(pressed: bool) -> void:
	_patrol_tool_enabled = pressed
	if pressed:
		_marker_tool_enabled = false
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false
		_selection_tool_enabled = false
		var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
		if select_button != null and select_button.button_pressed:
			select_button.button_pressed = false
	_update_patrol_topbar_state()
	_refresh_patrol_overlay()


func _on_patrol_spawn_selected(index: int) -> void:
	var spawn_selector := get_node_or_null("UI/TopBar/Margin/HBox/PatrolSpawnOption") as OptionButton
	if spawn_selector == null or index < 0 or index >= spawn_selector.item_count:
		return
	_patrol_spawn_id = String(spawn_selector.get_item_metadata(index)).strip_edges()
	_refresh_patrol_overlay()


func _on_clear_patrol_pressed() -> void:
	if _terrain_map_data == null or _patrol_spawn_id.is_empty():
		return
	_terrain_map_data.call("set_patrol_path", _patrol_spawn_id, [])
	_mark_dirty(true)
	_refresh_patrol_overlay()


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
		var edge_idx: int = 0
		match String(tile_data.edge_type):
			TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE:
				edge_idx = 1
			TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE:
				edge_idx = 2
		edge_type_option_button.select(edge_idx)
	_set_property_controls_enabled(true)
	_is_refreshing_property_controls = false


func _refresh_map_settings_panel() -> void:
	var grid_size_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/GridSizeLabel") as Label
	var mission_slot_spinbox := _get_mission_slot_spinbox()
	if grid_size_label == null or mission_slot_spinbox == null:
		return

	_is_refreshing_map_settings_controls = true
	if _terrain_map_data == null:
		grid_size_label.text = "Grid: -"
		mission_slot_spinbox.value = MIN_MISSION_SLOT_COUNT
		mission_slot_spinbox.editable = false
		_refresh_marker_editor_controls()
		_is_refreshing_map_settings_controls = false
		return

	var grid_size: Vector2i = _terrain_map_data.call("get_grid_size")
	grid_size_label.text = "Grid: %d x %d" % [grid_size.x, grid_size.y]
	mission_slot_spinbox.value = clampi(int(_terrain_map_data.call("get_mission_slot_count")), MIN_MISSION_SLOT_COUNT, MAX_MISSION_SLOT_COUNT)
	mission_slot_spinbox.editable = true
	_refresh_marker_editor_controls()
	_is_refreshing_map_settings_controls = false


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
		toolbar.add_child(add_type_option)

		var add_marker_button := Button.new()
		add_marker_button.name = "AddMarkerButton"
		add_marker_button.text = "Add"
		toolbar.add_child(add_marker_button)

		var marker_tool_button := Button.new()
		marker_tool_button.name = "MarkerToolButton"
		marker_tool_button.text = "Marker Tool"
		marker_tool_button.toggle_mode = true
		toolbar.add_child(marker_tool_button)

		var remove_marker_button := Button.new()
		remove_marker_button.name = "RemoveMarkerButton"
		remove_marker_button.text = "Remove"
		toolbar.add_child(remove_marker_button)

		var marker_list := ItemList.new()
		marker_list.name = "MarkerList"
		marker_list.select_mode = ItemList.SELECT_SINGLE
		marker_list.allow_reselect = true
		marker_list.custom_minimum_size = Vector2(0.0, 170.0)
		marker_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
		color_row.add_child(color_picker_button)

		var marker_info_label := Label.new()
		marker_info_label.name = "MarkerInfoLabel"
		marker_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		marker_info_label.text = "Select a marker to edit it."
		marker_panel.add_child(marker_info_label)

	_populate_marker_type_options()
	_connect_marker_editor_signals()
	_refresh_marker_editor_controls()


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
		var selected_index: int = 0
		for index in range(option_button.item_count):
			if String(option_button.get_item_metadata(index)) == previous_type_id:
				selected_index = index
				break
		if option_button.item_count > 0:
			option_button.select(selected_index)


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
		_is_refreshing_marker_controls = false
		return

	var marker_type_id: String = String(selected_record.get("marker_type_id", "")).strip_edges()
	for index in range(selected_type_option.item_count):
		if String(selected_type_option.get_item_metadata(index)) == marker_type_id:
			selected_type_option.select(index)
			break
	marker_name_line_edit.text = String(selected_record.get("name", _selected_marker_id))
	marker_color_button.color = Color(selected_record.get("color", Color(0.9, 0.9, 0.9, 1.0)))
	marker_info_label.text = _build_marker_info_text(selected_record)
	_is_refreshing_marker_controls = false


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


func _on_marker_tool_toggled(pressed: bool) -> void:
	_marker_tool_enabled = pressed
	if not pressed:
		_is_dragging_marker = false
		_has_dragged_marker = false
		_dragged_marker_id = ""
		_refresh_marker_editor_controls()
		return
	_selection_tool_enabled = false
	_patrol_tool_enabled = false
	var select_button := get_node_or_null("UI/TopBar/Margin/HBox/SelectButton") as Button
	if select_button != null:
		select_button.button_pressed = false
	var patrol_button := get_node_or_null("UI/TopBar/Margin/HBox/PatrolButton") as Button
	if patrol_button != null:
		patrol_button.button_pressed = false
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	if brush_button != null and brush_button.button_pressed:
		brush_button.button_pressed = false
	_hide_hover_preview()
	_refresh_marker_editor_controls()


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
	else:
		_selected_marker_id = normalized_marker_id
		var marker_position: Vector2 = _terrain_map_data.call("get_marker_position", normalized_marker_id, Vector2.ZERO)
		_selected_grid_position = _terrain_registry.world_to_grid(marker_position) if _terrain_registry != null else _selected_grid_position
	_refresh_selection_visual()
	_refresh_marker_overlay()
	_refresh_marker_editor_controls()


func _handle_marker_left_press(mouse_button_event: InputEventMouseButton) -> bool:
	var world_position: Vector2 = get_global_mouse_position()
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
	if not is_drag:
		_set_marker_feedback("Marker placed on tile center.")
	return true


func _snap_world_position_to_tile_center(world_position: Vector2):
	var tile_data = _resolve_tile_at_world_position(world_position)
	if tile_data == null:
		return null
	return Vector2(tile_data.world_position)


func _find_marker_id_at_world_position(world_position: Vector2) -> String:
	if _terrain_map_data == null:
		return ""
	var best_marker_id: String = ""
	var best_distance_sq: float = MARKER_PICK_RADIUS * MARKER_PICK_RADIUS
	for marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
		var marker_position: Vector2 = _terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)
		var distance_sq: float = marker_position.distance_squared_to(world_position)
		if distance_sq > best_distance_sq:
			continue
		best_distance_sq = distance_sq
		best_marker_id = String(marker_id)
	return best_marker_id


func _can_place_marker_at_world_position(marker_id: String, world_position: Vector2) -> bool:
	if _terrain_map_data == null:
		return false
	for other_marker_id in PackedStringArray(_terrain_map_data.call("get_marker_ids")):
		if String(other_marker_id) == marker_id:
			continue
		if _marker_positions_equal(world_position, Vector2(_terrain_map_data.call("get_marker_position", other_marker_id, Vector2.ZERO))):
			return false
	return true


func _find_first_available_marker_world_position(preferred_world_position: Vector2, ignore_marker_id: String = ""):
	var preferred_tile_position = _snap_world_position_to_tile_center(preferred_world_position)
	if preferred_tile_position != null and _can_place_marker_at_world_position(ignore_marker_id, preferred_tile_position):
		return preferred_tile_position
	if _terrain_map_data == null:
		return null
	for tile_data in _terrain_map_data.call("get_tiles"):
		if tile_data == null:
			continue
		if _can_place_marker_at_world_position(ignore_marker_id, Vector2(tile_data.world_position)):
			return Vector2(tile_data.world_position)
	return null


func _marker_positions_equal(a: Vector2, b: Vector2) -> bool:
	return a.distance_squared_to(b) <= 1.0


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
		return
	for child in overlay.get_children():
		child.queue_free()
	if _terrain_map_data == null:
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
	tile_data.type_id = ""
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
	tile_data.object_height = restored_tile.object_height

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
	_update_patrol_topbar_state()


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


func _connect_ui_signals() -> void:
	var save_button := get_node_or_null("UI/TopBar/Margin/HBox/SaveButton") as Button
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
	var file_dialog := get_node_or_null("UI/LoadDialog") as FileDialog
	var confirm_dialog := get_node_or_null("UI/DirtyConfirmDialog") as ConfirmationDialog
	var new_map_dialog := _get_new_map_dialog()
	var tile_type_list := _get_tile_type_list()
	if save_button != null and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
	if save_as_dialog != null and not save_as_dialog.file_selected.is_connected(_on_save_as_file_selected):
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
		var save_as_dialog := get_node_or_null("UI/SaveAsDialog") as FileDialog
		if save_as_dialog != null:
			save_as_dialog.current_dir = "res://maps"
			save_as_dialog.current_file = _current_map_path.get_file() if not _current_map_path.is_empty() else "new_map.json"
			save_as_dialog.popup_centered_ratio(0.65)
		return
	_save_current_map()

func _on_save_as_file_selected(path: String) -> void:
	if path.is_empty():
		return
	_current_map_path = path
	_save_current_map()


func _ensure_patrol_overlay() -> void:
	var existing_overlay := get_node_or_null(PATROL_OVERLAY_NAME) as Node2D
	if existing_overlay != null:
		return
	var overlay := Node2D.new()
	overlay.name = PATROL_OVERLAY_NAME
	overlay.z_index = 35
	add_child(overlay)


func _refresh_patrol_overlay() -> void:
	var overlay := get_node_or_null(PATROL_OVERLAY_NAME) as Node2D
	if overlay == null or _terrain_map_data == null:
		return
	for child in overlay.get_children():
		child.queue_free()
	var patrol_paths: Dictionary = Dictionary(_terrain_map_data.call("get_patrol_paths"))
	for spawn_id_variant in patrol_paths.keys():
		var spawn_id: String = String(spawn_id_variant).strip_edges()
		if spawn_id.is_empty():
			continue
		var is_active_spawn: bool = spawn_id == _patrol_spawn_id
		var base_color: Color = Color(0.25, 0.9, 0.35, 0.9) if is_active_spawn else Color(0.25, 0.75, 0.3, 0.5)
		var path_points: Array = Array(_terrain_map_data.call("get_patrol_path", spawn_id))
		if path_points.size() >= 2:
			var line := Line2D.new()
			line.width = 2.0
			line.default_color = base_color
			for point_variant in path_points:
				line.add_point(Vector2(point_variant))
			overlay.add_child(line)
		for waypoint_index in range(path_points.size()):
			var waypoint_position: Vector2 = Vector2(path_points[waypoint_index])
			var marker := Line2D.new()
			marker.width = 2.0
			marker.default_color = base_color
			marker.add_point(waypoint_position + Vector2(-5.0, 0.0))
			marker.add_point(waypoint_position + Vector2(5.0, 0.0))
			marker.add_point(waypoint_position + Vector2(0.0, 0.0))
			marker.add_point(waypoint_position + Vector2(0.0, -5.0))
			marker.add_point(waypoint_position + Vector2(0.0, 5.0))
			overlay.add_child(marker)
			var label := Label.new()
			label.position = waypoint_position + Vector2(6.0, -12.0)
			label.text = "%s:%d" % [spawn_id, waypoint_index + 1]
			label.modulate = base_color
			label.add_theme_font_size_override("font_size", 10)
			overlay.add_child(label)


func _refresh_patrol_spawn_selector() -> void:
	var spawn_selector := get_node_or_null("UI/TopBar/Margin/HBox/PatrolSpawnOption") as OptionButton
	if spawn_selector == null:
		return
	spawn_selector.clear()
	for spawn_id in PATROL_SPAWN_IDS:
		spawn_selector.add_item(spawn_id)
		spawn_selector.set_item_metadata(spawn_selector.item_count - 1, spawn_id)
	var selected_index: int = 0
	for index in range(spawn_selector.item_count):
		if String(spawn_selector.get_item_metadata(index)) == _patrol_spawn_id:
			selected_index = index
			break
	spawn_selector.select(selected_index)


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
	if _terrain_map_data == null:
		return -1
	var patrol_path: Array = Array(_terrain_map_data.call("get_patrol_path", _patrol_spawn_id))
	var best_index: int = -1
	var best_dist_sq: float = PATROL_PICK_RADIUS * PATROL_PICK_RADIUS
	for index in range(patrol_path.size()):
		var waypoint_position: Vector2 = Vector2(patrol_path[index])
		var dist_sq: float = waypoint_position.distance_squared_to(world_position)
		if dist_sq > best_dist_sq:
			continue
		best_dist_sq = dist_sq
		best_index = index
	return best_index


func _add_patrol_waypoint(world_position: Vector2) -> void:
	var patrol_path: Array = Array(_terrain_map_data.call("get_patrol_path", _patrol_spawn_id))
	patrol_path.append(world_position)
	_terrain_map_data.call("set_patrol_path", _patrol_spawn_id, patrol_path)
	_mark_dirty(true)
	_refresh_patrol_overlay()


func _move_patrol_waypoint(index: int, world_position: Vector2) -> void:
	var patrol_path: Array = Array(_terrain_map_data.call("get_patrol_path", _patrol_spawn_id))
	if index < 0 or index >= patrol_path.size():
		return
	patrol_path[index] = world_position
	_terrain_map_data.call("set_patrol_path", _patrol_spawn_id, patrol_path)
	_mark_dirty(true)
	_refresh_patrol_overlay()


func _remove_patrol_waypoint(index: int) -> void:
	var patrol_path: Array = Array(_terrain_map_data.call("get_patrol_path", _patrol_spawn_id))
	if index < 0 or index >= patrol_path.size():
		return
	patrol_path.remove_at(index)
	_terrain_map_data.call("set_patrol_path", _patrol_spawn_id, patrol_path)
	_mark_dirty(true)
	_refresh_patrol_overlay()


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
		return
	_terrain_map_data.call("set_marker_position", marker_id, tile_data.world_position)
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

	# Auto-enable brush when a type is selected
	var brush_button := get_node_or_null("UI/TopBar/Margin/HBox/BrushButton") as Button
	if brush_button != null and not brush_button.button_pressed:
		brush_button.button_pressed = true
	if _marker_tool_enabled:
		var marker_tool_button := _get_marker_tool_button()
		if marker_tool_button != null and marker_tool_button.button_pressed:
			marker_tool_button.button_pressed = false


# Deselect palette item to enter select mode
func _on_tile_type_deselected() -> void:
	var tile_type_list := _get_tile_type_list()
	if tile_type_list != null:
		for i in range(tile_type_list.item_count):
			tile_type_list.deselect(i)
	_selected_type_id = ""
	_hide_hover_preview()


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


func _get_mission_slot_spinbox() -> SpinBox:
	return get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionSlotRow/MissionSlotSpinBox") as SpinBox


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
	if tile_type_list == null or _tile_catalog == null:
		return

	tile_type_list.clear()
	tile_type_list.visible = true
	if palette_groups_root != null:
		palette_groups_root.visible = false
		for child in palette_groups_root.get_children():
			child.queue_free()

	var types_by_group: Dictionary = {}
	for tile_type in _tile_catalog.get_all_types():
		var palette_group: String = String(tile_type.get("palette_group", "default")).strip_edges().to_lower()
		if palette_group.is_empty():
			palette_group = "default"
		var group_types: Array = Array(types_by_group.get(palette_group, []))
		group_types.append(tile_type)
		types_by_group[palette_group] = group_types

	for group in _tile_catalog.get_palette_groups():
		var group_id: String = String(Dictionary(group).get("group_id", "")).strip_edges().to_lower()
		if group_id.is_empty() or not types_by_group.has(group_id):
			continue
		var header_index: int = tile_type_list.item_count
		tile_type_list.add_item("-- %s --" % String(Dictionary(group).get("display_name", group_id.capitalize())))
		tile_type_list.set_item_metadata(header_index, "__group:%s" % group_id)
		tile_type_list.set_item_selectable(header_index, false)
		for tile_type in Array(types_by_group.get(group_id, [])):
			var type_id := String(Dictionary(tile_type).get("type_id", ""))
			var display_name := String(Dictionary(tile_type).get("display_name", type_id))
			tile_type_list.add_item(display_name)
			tile_type_list.set_item_metadata(tile_type_list.item_count - 1, type_id)


func _get_tile_type_list() -> ItemList:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/TileTypeList") as ItemList


func _get_palette_groups_root() -> VBoxContainer:
	return get_node_or_null("UI/PalettePanel/Margin/VBox/PaletteGroups") as VBoxContainer


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
		return TILE_TEXTURE
	_terrain_renderer.set_tile_catalog(_tile_catalog)
	return _terrain_renderer.resolve_tile_texture(tile_data)


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
			pos_offset = Vector2(33, 24)
		"cliff_straight_sw":
			texture = CLIFF_TEXTURE_SW
			pos_offset = Vector2(33, 56)
		"cliff_straight_ne":
			texture = CLIFF_TEXTURE_NE
			pos_offset = Vector2(-31, 23)
		"cliff_straight_nw":
			texture = CLIFF_TEXTURE_NW
			pos_offset = Vector2(-32, 56)
		"cliff_corner_se":
			texture = CLIFF_CORNER_NE
			pos_offset = Vector2(-64, 40)
		"cliff_corner_sw":
			texture = CLIFF_CORNER_SE
			pos_offset = Vector2(1, 7)
		"cliff_corner_ne":
			texture = CLIFF_CORNER_NW
			pos_offset = Vector2(0, 73)
		"cliff_corner_nw":
			texture = CLIFF_CORNER_SW
			pos_offset = Vector2(65, 40)
		"slope_se":
			texture = RAMP_TEXTURE_SE
			pos_offset = Vector2(0, 32)
		"slope_sw":
			texture = RAMP_TEXTURE_SW
			pos_offset = Vector2(0, 32)
		"slope_ne":
			texture = RAMP_TEXTURE_NE
			pos_offset = Vector2(0, 32)
		"slope_nw":
			texture = RAMP_TEXTURE_NW
			pos_offset = Vector2(0, 32)
		"rock_small":
			texture = ROCK_SMALL_TEXTURE
		"rock_large":
			texture = ROCK_LARGE_TEXTURE
		_:
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
