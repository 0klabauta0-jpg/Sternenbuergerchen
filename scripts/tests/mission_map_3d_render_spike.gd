extends Node3D

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_RENDERER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_renderer.gd")

@export var map_path: String = "res://maps/test_mission_32x32_slots8.json"
@export var show_debug_grid: bool = true
@export var camera_controls_enabled: bool = true
@export var camera_pan_speed: float = 8.0
@export var camera_rotation_speed: float = 80.0
@export var camera_zoom_step: float = 1.0
@export var camera_min_size: float = 5.0
@export var camera_max_size: float = 42.0

var render_result: Dictionary = {}
var _camera_focus: Vector3 = Vector3(15.5, 0.0, 15.5)
var _camera_yaw_degrees: float = 35.5
var _camera_distance: float = 12.9
var _camera_height: float = 9.0


func _ready() -> void:
	set_process(true)
	set_process_unhandled_input(true)
	_ensure_camera_and_light()
	render_map()
	_frame_camera_on_objects()


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
		_camera_focus += move.normalized() * camera_pan_speed * delta
		_apply_camera_transform()
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


func render_map() -> Dictionary:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", map_path)
	var map_root := get_node_or_null("MapRoot") as Node3D
	if map_root == null:
		map_root = Node3D.new()
		map_root.name = "MapRoot"
		add_child(map_root)
	var renderer = TERRAIN_MAP_3D_RENDERER_SCRIPT.new()
	render_result = renderer.call("render_map", map_data, map_root, {"show_debug_grid": show_debug_grid})
	return render_result


func set_debug_grid_enabled(is_enabled: bool) -> void:
	show_debug_grid = is_enabled
	render_map()
	_frame_camera_on_objects()


func get_camera_focus() -> Vector3:
	return _camera_focus


func get_camera_size() -> float:
	var camera := get_node_or_null("Camera3D") as Camera3D
	return camera.size if camera != null else 0.0


func rotate_camera_by(delta_degrees: float) -> void:
	_camera_yaw_degrees = wrapf(_camera_yaw_degrees + delta_degrees, -180.0, 180.0)
	_apply_camera_transform()


func zoom_camera_by_steps(step_count: int) -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return
	camera.size = clampf(camera.size + float(step_count) * camera_zoom_step, camera_min_size, camera_max_size)


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


func _frame_camera_on_objects() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return
	var stats: Dictionary = Dictionary(render_result.get("stats", {}))
	var focus: Vector3 = Vector3(stats.get("object_focus", Vector3(15.5, 0.0, 15.5)))
	_camera_focus = focus
	_camera_yaw_degrees = 35.5
	_camera_distance = 12.9
	_camera_height = 9.0
	camera.size = 12.0 if int(stats.get("object_count", 0)) > 0 else 26.0
	_apply_camera_transform()


func _apply_camera_transform() -> void:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return
	var yaw: float = deg_to_rad(_camera_yaw_degrees)
	var offset := Vector3(sin(yaw) * _camera_distance, _camera_height, cos(yaw) * _camera_distance)
	camera.look_at_from_position(_camera_focus + offset, _camera_focus, Vector3.UP)


func _get_camera_forward_flat() -> Vector3:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return Vector3.FORWARD
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD


func _get_camera_right_flat() -> Vector3:
	var camera := get_node_or_null("Camera3D") as Camera3D
	if camera == null:
		return Vector3.RIGHT
	var right: Vector3 = camera.global_transform.basis.x
	right.y = 0.0
	return right.normalized() if right.length() > 0.001 else Vector3.RIGHT
