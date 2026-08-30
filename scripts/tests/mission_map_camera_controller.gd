class_name MissionMapCameraController
extends Camera2D

const CAMERA_PAN_SPEED: float = 780.0
const CAMERA_ZOOM_STEP: float = 0.08
const MIN_CAMERA_ZOOM: float = 0.55
const MAX_CAMERA_ZOOM: float = 1.9
const ACTION_PAN_UP: StringName = &"tactical_camera_pan_up"
const ACTION_PAN_DOWN: StringName = &"tactical_camera_pan_down"
const ACTION_PAN_LEFT: StringName = &"tactical_camera_pan_left"
const ACTION_PAN_RIGHT: StringName = &"tactical_camera_pan_right"
const ACTION_ROTATE_LEFT: StringName = &"tactical_camera_rotate_left"
const ACTION_ROTATE_RIGHT: StringName = &"tactical_camera_rotate_right"
const ACTION_ROTATE_DRAG: StringName = &"tactical_camera_rotate_drag"
const ACTION_ZOOM_IN: StringName = &"tactical_camera_zoom_in"
const ACTION_ZOOM_OUT: StringName = &"tactical_camera_zoom_out"

@export var focus_marker_path: NodePath

var _is_panning: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	_refresh_camera_activity()
	if _get_primary_3d_view() != null:
		_deactivate_camera()
	if focus_marker_path.is_empty():
		return
	var focus_marker := get_node_or_null(focus_marker_path) as Node2D
	if focus_marker != null:
		global_position = focus_marker.global_position


func _process(delta: float) -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		_deactivate_camera()
		var primary_direction := Vector2.ZERO
		if Input.is_action_pressed(ACTION_PAN_UP):
			primary_direction.y -= 1.0
		if Input.is_action_pressed(ACTION_PAN_DOWN):
			primary_direction.y += 1.0
		if Input.is_action_pressed(ACTION_PAN_LEFT):
			primary_direction.x -= 1.0
		if Input.is_action_pressed(ACTION_PAN_RIGHT):
			primary_direction.x += 1.0
		if primary_direction != Vector2.ZERO:
			primary_3d_view.call("pan_camera", primary_direction.normalized(), delta)
		if Input.is_action_pressed(ACTION_ROTATE_LEFT):
			primary_3d_view.call("rotate_camera", -80.0 * delta)
		if Input.is_action_pressed(ACTION_ROTATE_RIGHT):
			primary_3d_view.call("rotate_camera", 80.0 * delta)
		return
	if not _is_camera_active():
		return
	var direction := Vector2.ZERO
	if Input.is_action_pressed(ACTION_PAN_UP):
		direction.y -= 1.0
	if Input.is_action_pressed(ACTION_PAN_DOWN):
		direction.y += 1.0
	if Input.is_action_pressed(ACTION_PAN_LEFT):
		direction.x -= 1.0
	if Input.is_action_pressed(ACTION_PAN_RIGHT):
		direction.x += 1.0
	if direction == Vector2.ZERO:
		return
	position += direction.normalized() * CAMERA_PAN_SPEED * delta / zoom.x


func _unhandled_input(event: InputEvent) -> void:
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		if event is InputEventMouseButton:
			var mouse_button_event := event as InputEventMouseButton
			if mouse_button_event.is_action_pressed(ACTION_ZOOM_IN) and not _is_pointer_over_control():
				primary_3d_view.call("zoom_camera", 1.0)
				get_viewport().set_input_as_handled()
				return
			if mouse_button_event.is_action_pressed(ACTION_ZOOM_OUT) and not _is_pointer_over_control():
				primary_3d_view.call("zoom_camera", -1.0)
				get_viewport().set_input_as_handled()
				return
			if mouse_button_event.is_action_pressed(ACTION_ROTATE_DRAG) or mouse_button_event.is_action_released(ACTION_ROTATE_DRAG):
				_is_panning = mouse_button_event.is_action_pressed(ACTION_ROTATE_DRAG) and not _is_pointer_over_control()
				if _is_panning:
					get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseMotion and _is_panning:
			var mouse_motion := event as InputEventMouseMotion
			primary_3d_view.call("rotate_camera", -mouse_motion.relative.x * 0.28)
			get_viewport().set_input_as_handled()
			return
		return
	if not _is_camera_active():
		return
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.is_action_pressed(ACTION_ZOOM_IN) and not _is_pointer_over_control():
			_adjust_camera_zoom(CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if mouse_button_event.is_action_pressed(ACTION_ZOOM_OUT) and not _is_pointer_over_control():
			_adjust_camera_zoom(-CAMERA_ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if mouse_button_event.is_action_pressed(ACTION_ROTATE_DRAG) or mouse_button_event.is_action_released(ACTION_ROTATE_DRAG):
			_is_panning = mouse_button_event.is_action_pressed(ACTION_ROTATE_DRAG) and not _is_pointer_over_control()
			if _is_panning:
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseMotion and _is_panning:
		var mouse_motion := event as InputEventMouseMotion
		position -= mouse_motion.relative * zoom
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_refresh_camera_activity()
	elif what == NOTIFICATION_EXIT_TREE:
		_deactivate_camera()


func _adjust_camera_zoom(delta: float) -> void:
	var next_zoom: float = clampf(zoom.x + delta, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
	zoom = Vector2(next_zoom, next_zoom)


func _refresh_camera_activity() -> void:
	if is_visible_in_tree():
		enabled = true
		make_current()
		return
	_deactivate_camera()


func _deactivate_camera() -> void:
	enabled = false
	_is_panning = false


func _is_camera_active() -> bool:
	return enabled and is_current() and is_visible_in_tree()


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _get_primary_3d_view():
	var parent := get_parent()
	if parent == null:
		return null
	return parent.get_node_or_null("Primary3DView")
