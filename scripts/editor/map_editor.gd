extends Node2D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TILE_TEXTURE: Texture2D = preload("res://Assets/kenney_space-kit/Isometric/terrain_SW.png")
const MIN_CAMERA_ZOOM: float = 0.5
const MAX_CAMERA_ZOOM: float = 3.0
const CAMERA_ZOOM_STEP: float = 0.1

@export var map_file_path: String = "res://maps/test_mission.json"

var _terrain_map_data = null
var _terrain_registry = null
var _tile_sprites_by_grid: Dictionary = {}
var _selected_grid_position: Vector2i = Vector2i(-1, -1)
var _is_panning: bool = false


func _ready() -> void:
	set_process_unhandled_input(true)
	_ensure_terrain_registry()
	_load_map(map_file_path)
	_refresh_selection_visual()
	_refresh_property_panel()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button_event.pressed:
			_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.pressed:
			_adjust_camera_zoom(CAMERA_ZOOM_STEP)
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE or mouse_button_event.button_index == MOUSE_BUTTON_RIGHT:
			_is_panning = mouse_button_event.pressed
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed and not _is_pointer_over_control():
			_select_tile_at_world_position(get_global_mouse_position())
			return

	if event is InputEventMouseMotion and _is_panning:
		var mouse_motion := event as InputEventMouseMotion
		var camera := _get_camera()
		if camera != null:
			camera.position -= mouse_motion.relative * camera.zoom
		return


func _load_map(path: String) -> void:
	_terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", path)
	_tile_sprites_by_grid.clear()
	_selected_grid_position = Vector2i(-1, -1)
	_rebuild_registry_from_map_data()
	_rebuild_tile_sprites()
	_center_camera_on_map()


func _rebuild_registry_from_map_data() -> void:
	_terrain_registry.clear_tiles()
	if _terrain_map_data == null:
		return

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	_terrain_registry.configure_iso_grid(
		_terrain_map_data.call("get_grid_origin"),
		float(tile_size.get("half_width", 64.0)),
		float(tile_size.get("half_height", 32.0))
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
		var tile_sprite := Sprite2D.new()
		tile_sprite.texture = TILE_TEXTURE
		tile_sprite.centered = false
		tile_sprite.z_index = -20
		tile_sprite.position = tile_data.world_position - (TILE_TEXTURE.get_size() * 0.5)
		tile_sprite.modulate = _build_tile_modulate(tile_data)
		tile_container.add_child(tile_sprite)
		_tile_sprites_by_grid[tile_data.grid_position] = tile_sprite


func _build_tile_modulate(tile_data) -> Color:
	if tile_data == null:
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
	var grid_position: Vector2i = _terrain_registry.world_to_grid(world_position)
	var tile_data = _terrain_map_data.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return

	_selected_grid_position = grid_position
	_refresh_selection_visual()
	_refresh_property_panel()


func _refresh_selection_visual() -> void:
	var outline := get_node_or_null("SelectionOutline") as Line2D
	if outline == null:
		return

	outline.clear_points()
	var tile_data = _terrain_map_data.call("get_tile_at_grid", _selected_grid_position) if _terrain_map_data != null else null
	if tile_data == null:
		return

	var tile_size: Dictionary = _terrain_map_data.call("get_tile_size")
	var half_width: float = float(tile_size.get("half_width", 64.0))
	var half_height: float = float(tile_size.get("half_height", 32.0))
	var center: Vector2 = tile_data.world_position
	outline.add_point(center + Vector2(0.0, -half_height))
	outline.add_point(center + Vector2(half_width, 0.0))
	outline.add_point(center + Vector2(0.0, half_height))
	outline.add_point(center + Vector2(-half_width, 0.0))
	outline.add_point(center + Vector2(0.0, -half_height))


func _refresh_property_panel() -> void:
	var tile_data = _terrain_map_data.call("get_tile_at_grid", _selected_grid_position) if _terrain_map_data != null else null
	var tile_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/TileLabel") as Label
	var walkable_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/WalkableLabel") as Label
	var blocks_los_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/BlocksLosLabel") as Label
	var cover_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/CoverValueLabel") as Label
	var height_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/HeightLevelLabel") as Label
	var surface_label := get_node_or_null("UI/PropertyPanel/Margin/VBox/SurfaceTypeLabel") as Label
	if tile_label == null or walkable_label == null or blocks_los_label == null or cover_label == null or height_label == null or surface_label == null:
		return

	if tile_data == null:
		tile_label.text = "Tile: -"
		walkable_label.text = "walkable: -"
		blocks_los_label.text = "blocks_los: -"
		cover_label.text = "cover_value: -"
		height_label.text = "height_level: -"
		surface_label.text = "surface_type: -"
		return

	tile_label.text = "Tile: (%d, %d)" % [_selected_grid_position.x, _selected_grid_position.y]
	walkable_label.text = "walkable: %s" % ("true" if bool(tile_data.walkable) else "false")
	blocks_los_label.text = "blocks_los: %s" % ("true" if bool(tile_data.blocks_los) else "false")
	cover_label.text = "cover_value: %d" % int(tile_data.cover_value)
	height_label.text = "height_level: %d" % int(tile_data.height_level)
	surface_label.text = "surface_type: %s" % String(tile_data.surface_type)


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
	var center_grid := Vector2i(maxi(grid_size.x - 1, 0) / 2, maxi(grid_size.y - 1, 0) / 2)
	camera.position = _terrain_registry.grid_to_world(center_grid)


func _get_camera() -> Camera2D:
	return get_node_or_null("Camera2D") as Camera2D


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _ensure_terrain_registry() -> void:
	if _terrain_registry != null:
		return

	_terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	_terrain_registry.name = "RuntimeTerrainRegistry"
	add_child(_terrain_registry)
