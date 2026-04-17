extends Node

const FIRETEAM_NAMES: PackedStringArray = ["ALL", "BLUE", "GOLD"]
const PHASE_NAMES: PackedStringArray = ["APPROACH", "ASSAULT", "HOLD"]
const HOTKEY_LEGEND: String = "LMB Set Target | 1 Move | 2 Defend | 3 Flank | 4 Take | Q/E Team | R/F Phase"

@export var alpha_flow_driver_path: NodePath
@export var bravo_flow_driver_path: NodePath
@export var charlie_flow_driver_path: NodePath
@export var target_marker_path: NodePath
@export var objective_point_path: NodePath
@export var command_feedback_label_path: NodePath
@export var hotkey_legend_label_path: NodePath
@export var move_button_path: NodePath
@export var defend_button_path: NodePath
@export var flank_button_path: NodePath
@export var take_button_path: NodePath

var _current_fireteam_index: int = 0
var _current_phase_index: int = 0
var _last_command_text: String = "AWAITING INPUT"
var _last_target_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_process_unhandled_input(true)
	_last_target_position = _get_target_position()
	_connect_button(move_button_path, Callable(self, "issue_move"))
	_connect_button(defend_button_path, Callable(self, "issue_defend"))
	_connect_button(flank_button_path, Callable(self, "issue_flank"))
	_connect_button(take_button_path, Callable(self, "issue_take"))
	_update_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if mouse_button_event.pressed and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			if _is_pointer_over_control():
				return

			if try_place_target_from_screen_position(mouse_button_event.position):
				get_viewport().set_input_as_handled()
			return

	if not (event is InputEventKey):
		return

	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.physical_keycode:
		KEY_1:
			issue_move()
			get_viewport().set_input_as_handled()
		KEY_2:
			issue_defend()
			get_viewport().set_input_as_handled()
		KEY_3:
			issue_flank()
			get_viewport().set_input_as_handled()
		KEY_4:
			issue_take()
			get_viewport().set_input_as_handled()
		KEY_Q:
			_change_fireteam(-1)
			get_viewport().set_input_as_handled()
		KEY_E:
			_change_fireteam(1)
			get_viewport().set_input_as_handled()
		KEY_R:
			_change_phase(-1)
			get_viewport().set_input_as_handled()
		KEY_F:
			_change_phase(1)
			get_viewport().set_input_as_handled()


func issue_move() -> bool:
	return _issue_command("move", "MOVE ORDER")


func issue_defend() -> bool:
	return _issue_command("defend", "HOLD / DEFEND")


func issue_flank() -> bool:
	return _issue_command("flank", "FLANK")


func issue_take() -> bool:
	_snap_target_to_objective()
	return _issue_command("take", "TAKE / ENGAGE")


func try_place_target_from_screen_position(screen_position: Vector2) -> bool:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return false

	var world_position: Vector2 = _screen_to_world_position(screen_position)
	var clamped_position: Vector2 = _clamp_world_position_to_viewport(world_position)
	target_marker.global_position = clamped_position
	_last_target_position = clamped_position
	_update_ui()
	return true


func _issue_command(command_type: String, display_text: String) -> bool:
	var issued_count: int = 0
	for driver in _get_active_flow_drivers():
		if driver == null or not driver.has_method("issue_command"):
			continue

		if bool(driver.call("issue_command", command_type, _current_phase_index)):
			issued_count += 1

	if issued_count == 0:
		_last_command_text = "%s FAILED" % display_text
		_update_ui()
		return false

	_last_command_text = "%s (%s)" % [display_text, _get_fireteam_name()]
	_update_ui()
	return true


func _change_fireteam(delta: int) -> void:
	_current_fireteam_index = wrapi(_current_fireteam_index + delta, 0, FIRETEAM_NAMES.size())
	_update_ui()


func _change_phase(delta: int) -> void:
	_current_phase_index = wrapi(_current_phase_index + delta, 0, PHASE_NAMES.size())
	_update_ui()


func _get_active_flow_drivers() -> Array:
	var alpha_driver = get_node_or_null(alpha_flow_driver_path)
	var bravo_driver = get_node_or_null(bravo_flow_driver_path)
	var charlie_driver = get_node_or_null(charlie_flow_driver_path)

	match _get_fireteam_name():
		"BLUE":
			return [alpha_driver, bravo_driver]
		"GOLD":
			return [charlie_driver]
		_:
			return [alpha_driver, bravo_driver, charlie_driver]


func _get_fireteam_name() -> String:
	return FIRETEAM_NAMES[_current_fireteam_index]


func _get_phase_name() -> String:
	return PHASE_NAMES[_current_phase_index]


func _update_ui() -> void:
	var command_feedback_label := get_node_or_null(command_feedback_label_path) as Label
	if command_feedback_label != null:
		command_feedback_label.text = "ACTIVE TEAM: %s\nACTIVE PHASE: %s\nTARGET: %s\nLAST ORDER: %s" % [
			_get_fireteam_name(),
			_get_phase_name(),
			_build_target_text(),
			_last_command_text,
		]

	var hotkey_legend_label := get_node_or_null(hotkey_legend_label_path) as Label
	if hotkey_legend_label != null:
		hotkey_legend_label.text = HOTKEY_LEGEND


func _connect_button(button_path: NodePath, callback: Callable) -> void:
	var button := get_node_or_null(button_path) as BaseButton
	if button == null:
		return

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _is_pointer_over_control() -> bool:
	return get_viewport().gui_get_hovered_control() != null


func _get_target_position() -> Vector2:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	if target_marker == null:
		return Vector2.ZERO

	return target_marker.global_position


func _build_target_text() -> String:
	var target_position: Vector2 = _get_target_position()
	_last_target_position = target_position
	return "%d, %d" % [
		int(round(target_position.x)),
		int(round(target_position.y)),
	]


func _screen_to_world_position(screen_position: Vector2) -> Vector2:
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_position


func _clamp_world_position_to_viewport(world_position: Vector2) -> Vector2:
	var visible_rect: Rect2 = get_viewport().get_visible_rect()
	var canvas_transform: Transform2D = get_viewport().get_canvas_transform()
	var inverse_transform: Transform2D = canvas_transform.affine_inverse()
	var world_a: Vector2 = inverse_transform * visible_rect.position
	var world_b: Vector2 = inverse_transform * visible_rect.end
	var min_x: float = minf(world_a.x, world_b.x)
	var max_x: float = maxf(world_a.x, world_b.x)
	var min_y: float = minf(world_a.y, world_b.y)
	var max_y: float = maxf(world_a.y, world_b.y)
	return Vector2(
		clampf(world_position.x, min_x, max_x),
		clampf(world_position.y, min_y, max_y)
	)


func _snap_target_to_objective() -> void:
	var target_marker := get_node_or_null(target_marker_path) as Node2D
	var objective_marker := get_node_or_null(objective_point_path) as Node2D
	if target_marker == null or objective_marker == null:
		return

	target_marker.global_position = objective_marker.global_position
	_last_target_position = objective_marker.global_position
	_update_ui()
