class_name MissionMapCameraController
extends Camera2D

const CAMERA_PAN_SPEED: float = 780.0
const CAMERA_ZOOM_STEP: float = 0.08
const MIN_CAMERA_ZOOM: float = 0.55
const MAX_CAMERA_ZOOM: float = 1.9

@export var focus_marker_path: NodePath

var _is_panning: bool = false


func _ready() -> void:
	enabled = true
	make_current()
	process_mode = Node.PROCESS_MODE_INHERIT
	if focus_marker_path.is_empty():
		return
	var focus_marker := get_node_or_null(focus_marker_path) as Node2D
	if focus_marker != null:
		global_position = focus_marker.global_position


func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	if direction == Vector2.ZERO:
		return
	position += direction.normalized() * CAMERA_PAN_SPEED * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button_event.pressed and not _is_pointer_over_control():
			_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button_event.pressed and not _is_pointer_over_control():
			_adjust_camera_zoom(CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE:
			_is_panning = mouse_button_event.pressed and not _is_pointer_over_control()
			if mouse_button_event.pressed:
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_panning:
		var mouse_motion := event as InputEventMouseMotion
		position -= mouse_motion.relative * zoom
		get_viewport().set_input_as_handled()


func _adjust_camera_zoom(delta: float) -> void:
	var next_zoom: float = clampf(zoom.x + delta, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	zoom = Vector2(next_zoom, next_zoom)


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null
