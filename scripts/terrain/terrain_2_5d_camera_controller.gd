class_name Terrain25DCameraController
extends RefCounted

const DEFAULT_FOCUS: Vector3 = Vector3(15.5, 0.0, 15.5)

var focus: Vector3 = DEFAULT_FOCUS
var yaw_degrees: float = 35.5
var distance: float = 12.9
var height: float = 9.0
var camera_size: float = 14.0
var zoom_step: float = 1.0
var min_size: float = 5.0
var max_size: float = 42.0

var _camera: Camera3D = null


func bind_camera(camera: Camera3D) -> void:
	_camera = camera
	if _camera == null:
		return
	_camera.current = true
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = clampf(camera_size, min_size, max_size)
	apply_transform()


func set_focus(next_focus: Vector3) -> void:
	focus = next_focus
	apply_transform()


func get_focus() -> Vector3:
	return focus


func set_camera_size(next_size: float) -> void:
	camera_size = clampf(next_size, min_size, max_size)
	if _camera != null:
		_camera.size = camera_size


func get_camera_size() -> float:
	if _camera != null:
		return float(_camera.size)
	return camera_size


func rotate_by(delta_degrees: float) -> void:
	yaw_degrees = wrapf(yaw_degrees + delta_degrees, -180.0, 180.0)
	apply_transform()


func zoom_by_steps(step_count: int) -> void:
	set_camera_size(get_camera_size() + float(step_count) * zoom_step)


func pan_by_world(delta_world: Vector3) -> void:
	focus += Vector3(delta_world.x, 0.0, delta_world.z)
	apply_transform()


func pan_by_local(input_direction: Vector2, amount: float) -> void:
	if input_direction == Vector2.ZERO or amount <= 0.0:
		return
	var flat_forward: Vector3 = get_forward_flat()
	var flat_right: Vector3 = get_right_flat()
	var movement: Vector3 = (flat_right * input_direction.x) + (flat_forward * input_direction.y)
	if movement.length() <= 0.001:
		return
	pan_by_world(movement.normalized() * amount)


func frame_focus(next_focus: Vector3, next_size: float = -1.0, next_yaw_degrees: float = 35.5, next_distance: float = 12.9, next_height: float = 9.0) -> void:
	focus = next_focus
	yaw_degrees = wrapf(next_yaw_degrees, -180.0, 180.0)
	distance = maxf(next_distance, 0.001)
	height = maxf(next_height, 0.001)
	if next_size > 0.0:
		set_camera_size(next_size)
	apply_transform()


func apply_transform() -> void:
	if _camera == null:
		return
	var yaw: float = deg_to_rad(yaw_degrees)
	var offset := Vector3(sin(yaw) * distance, height, cos(yaw) * distance)
	_camera.look_at_from_position(focus + offset, focus, Vector3.UP)


func get_forward_flat() -> Vector3:
	if _camera == null:
		var yaw: float = deg_to_rad(yaw_degrees)
		return Vector3(-sin(yaw), 0.0, -cos(yaw)).normalized()
	var forward: Vector3 = -_camera.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD


func get_right_flat() -> Vector3:
	if _camera == null:
		var yaw: float = deg_to_rad(yaw_degrees)
		return Vector3(cos(yaw), 0.0, -sin(yaw)).normalized()
	var right: Vector3 = _camera.global_transform.basis.x
	right.y = 0.0
	return right.normalized() if right.length() > 0.001 else Vector3.RIGHT


func get_state_snapshot() -> Dictionary:
	return {
		"focus": focus,
		"yaw_degrees": yaw_degrees,
		"distance": distance,
		"height": height,
		"camera_size": get_camera_size(),
	}
