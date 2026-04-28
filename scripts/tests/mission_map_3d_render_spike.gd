extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_camera_controller.gd")
const TERRAIN_25D_PICKER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_2_5d_picker.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")

@export var map_path: String = "res://maps/test_mission_32x32_slots8.json"
@export var show_debug_grid: bool = true
@export var camera_controls_enabled: bool = true
@export var camera_pan_speed: float = 8.0
@export var camera_rotation_speed: float = 80.0
@export var camera_zoom_step: float = 1.0
@export var camera_min_size: float = 5.0
@export var camera_max_size: float = 42.0

var render_result: Dictionary = {}
var last_pick_snapshot: Dictionary = {}

var _camera_controller = TERRAIN_25D_CAMERA_CONTROLLER_SCRIPT.new()
var _picker = TERRAIN_25D_PICKER_SCRIPT.new()
var _terrain_registry = null
var _renderer = null


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_ensure_camera_and_light()
	_bind_camera_controller()
	render_map()
	_frame_camera_on_objects()


func _exit_tree() -> void:
	if _terrain_registry != null and is_instance_valid(_terrain_registry):
		_terrain_registry.free()
	_terrain_registry = null


func _process(delta: float) -> void:
	if not camera_controls_enabled:
		return
	var move := Vector3.ZERO
	var forward := _get_camera_forward_flat()
	var right := _get_camera_right_flat()
	if Input.is_key_pressed(KEY_W):
		move += forward
	if Input.is_key_pressed(KEY_S):
		move -= forward
	if Input.is_key_pressed(KEY_D):
		move += right
	if Input.is_key_pressed(KEY_A):
		move -= right
	if move != Vector3.ZERO:
		_camera_controller.call("pan_by_world", move.normalized() * camera_pan_speed * delta)
	if Input.is_key_pressed(KEY_Q):
		rotate_camera_by(-camera_rotation_speed * delta)
	if Input.is_key_pressed(KEY_E):
		rotate_camera_by(camera_rotation_speed * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not camera_controls_enabled:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if not mouse_event.pressed:
			return
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera_by_steps(-1)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera_by_steps(1)
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			pick_screen_position(mouse_event.position)


func render_map() -> Dictionary:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_path)
	_terrain_registry = _build_registry_from_map(map_data)
	var map_root := get_node_or_null("MapRoot") as Node3D
	if map_root == null:
		map_root = Node3D.new()
		map_root.name = "MapRoot"
		add_child(map_root)
	_renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	render_result = _renderer.call("render_map", map_data, map_root, {"show_debug_grid": show_debug_grid})
	_picker.call("configure_grid", float(_renderer.call("get_grid_cell_size")), float(_renderer.call("get_grid_height_step")))
	return render_result


func set_debug_grid_enabled(is_enabled: bool) -> void:
	show_debug_grid = is_enabled
	render_map()
	_frame_camera_on_objects()


func get_camera_focus() -> Vector3:
	return Vector3(_camera_controller.call("get_focus"))


func get_camera_size() -> float:
	return float(_camera_controller.call("get_camera_size"))


func get_camera_state_snapshot() -> Dictionary:
	return Dictionary(_camera_controller.call("get_state_snapshot"))


func rotate_camera_by(delta_degrees: float) -> void:
	_camera_controller.call("rotate_by", delta_degrees)


func zoom_camera_by_steps(step_count: int) -> void:
	_camera_controller.call("zoom_by_steps", step_count)


func pick_screen_position(screen_position: Vector2, options: Dictionary = {}) -> Dictionary:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		last_pick_snapshot = {"valid": false, "reason": "camera_missing"}
		return last_pick_snapshot
	last_pick_snapshot = Dictionary(_picker.call("pick_screen", camera, screen_position, _terrain_registry, options))
	_update_pick_debug_marker(last_pick_snapshot)
	return last_pick_snapshot


func get_last_pick_snapshot() -> Dictionary:
	return last_pick_snapshot.duplicate(true)


func _ensure_camera_and_light() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		add_child(camera)
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.0
	camera.position = Vector3(16.0, 18.0, 23.0)
	camera.look_at(Vector3(15.5, 0.0, 15.5), Vector3.UP)

	var light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if light == null:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		add_child(light)
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_energy = 1.6


func _bind_camera_controller() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	_camera_controller.zoom_step = camera_zoom_step
	_camera_controller.min_size = camera_min_size
	_camera_controller.max_size = camera_max_size
	_camera_controller.camera_size = camera.size if camera != null else 14.0
	_camera_controller.call("bind_camera", camera)


func _frame_camera_on_objects() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var focus: Vector3 = Vector3(stats.get("object_focus", Vector3(15.5, 0.0, 15.5)))
	_camera_controller.call("frame_focus", focus, 12.0 if int(stats.get("object_count", 0)) > 0 else 26.0, 35.5, 12.9, 9.0)


func _get_camera_forward_flat() -> Vector3:
	return Vector3(_camera_controller.call("get_forward_flat"))


func _get_camera_right_flat() -> Vector3:
	return Vector3(_camera_controller.call("get_right_flat"))


func _build_registry_from_map(map_data):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	if map_data == null:
		return registry
	if map_data.has_method("get_grid_origin") and map_data.has_method("get_tile_size"):
		var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
		registry.call("configure_iso_grid", map_data.call("get_grid_origin"), float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)))
	var tiles: Array = Array(map_data.call("get_tiles")) if map_data.has_method("get_tiles") else []
	for tile_data in tiles:
		registry.call("register_tile", tile_data)
	return registry


func _update_pick_debug_marker(snapshot: Dictionary) -> void:
	var marker := get_node_or_null("PickDebugMarker") as MeshInstance3D
	if marker == null:
		marker = MeshInstance3D.new()
		marker.name = "PickDebugMarker"
		var marker_mesh := SphereMesh.new()
		marker_mesh.radius = 0.12
		marker_mesh.height = 0.24
		marker.mesh = marker_mesh
		var marker_material := StandardMaterial3D.new()
		marker_material.albedo_color = Color(1.0, 0.86, 0.2, 1.0)
		marker.material_override = marker_material
		add_child(marker)
	marker.visible = bool(snapshot.get("valid", false))
	if marker.visible:
		marker.position = Vector3(snapshot.get("world_position_3d", Vector3.ZERO)) + Vector3(0.0, 0.18, 0.0)
