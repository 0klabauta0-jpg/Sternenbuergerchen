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
var _pan_previous_position := Vector2.ZERO


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
	# Camera polling follows the same input permission as event callbacks.
	# Modal menus disable input, while the rest of the simulation keeps ticking.
	if not is_processing_unhandled_input():
		return
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		enabled = false
		if not is_visible_in_tree():
			_is_panning = false
			return
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
			primary_3d_view.call("pan_camera_keyboard", primary_direction.normalized(), delta)
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


func cancel_modal_input() -> void:
	_is_panning = false
	_pan_previous_position = Vector2.ZERO


func _input(event: InputEvent) -> void:
	# Continue an established map drag before GUI handling; press/wheel below
	# still wait for unhandled input so panels retain their normal capture.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		_is_panning = false
		return
	if not _is_panning or not event is InputEventMouseMotion:
		return
	if not is_visible_in_tree() or (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) == 0:
		_is_panning = false
		return
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view != null:
		primary_3d_view.call("pan_camera_between_screen_positions", _pan_previous_position, event.position)
	elif _is_camera_active():
		position += (_pan_previous_position - event.position) / zoom
	_pan_previous_position = event.position
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventMouseButton:
		return
	var primary_3d_view = _get_primary_3d_view()
	if primary_3d_view == null and not _is_camera_active():
		return
	if _is_pointer_over_control():
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_MIDDLE:
		_is_panning = mouse_event.pressed
		_pan_previous_position = mouse_event.position
		get_viewport().set_input_as_handled()
		return
	var zoom_steps: float = 0.0
	if mouse_event.is_action_pressed(ACTION_ZOOM_IN):
		zoom_steps = 1.0
	elif mouse_event.is_action_pressed(ACTION_ZOOM_OUT):
		zoom_steps = -1.0
	if is_zero_approx(zoom_steps):
		return
	if primary_3d_view != null:
		primary_3d_view.call("zoom_camera_wheel_at_screen_position", zoom_steps, mouse_event.position)
	else:
		var before: Vector2 = get_canvas_transform().affine_inverse() * mouse_event.position
		_adjust_camera_zoom(zoom_steps * CAMERA_ZOOM_STEP)
		force_update_scroll()
		var after: Vector2 = get_canvas_transform().affine_inverse() * mouse_event.position
		global_position += before - after
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_refresh_camera_activity()
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_is_panning = false
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
