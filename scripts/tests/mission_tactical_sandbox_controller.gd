extends Node

@export var sandbox_label_path: NodePath
@export var target_marker_path: NodePath
@export var flow_driver_paths: Array[NodePath] = []
@export var target_positions: Array[Vector2] = []

var _current_target_index: int = 0
var _last_order_name: String = "none"


func _ready() -> void:
	if target_positions.is_empty():
		var target_marker = get_node_or_null(target_marker_path)
		if target_marker is Node2D:
			target_positions.append(target_marker.position)

	_sync_target_marker()
	_update_sandbox_label()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_1:
			issue_move()
		KEY_2:
			issue_defend()
		KEY_3:
			issue_flank()
		KEY_Q:
			cycle_target(-1)
		KEY_E, KEY_TAB:
			cycle_target(1)


func issue_move() -> int:
	return _issue_team_command("move")


func issue_defend() -> int:
	return _issue_team_command("defend")


func issue_flank() -> int:
	return _issue_team_command("flank")


func cycle_target(step: int = 1) -> void:
	if target_positions.is_empty():
		return

	_current_target_index = wrapi(_current_target_index + step, 0, target_positions.size())
	_sync_target_marker()
	_update_sandbox_label()


func get_current_target_position() -> Vector2:
	if target_positions.is_empty():
		return Vector2.ZERO

	return target_positions[_current_target_index]


func _issue_team_command(command_type: String) -> int:
	var issued_count: int = 0
	for flow_driver_path in flow_driver_paths:
		var flow_driver = get_node_or_null(flow_driver_path)
		if flow_driver == null or not flow_driver.has_method("issue_command"):
			continue

		if bool(flow_driver.call("issue_command", command_type, get_current_target_position())):
			issued_count += 1

	if issued_count > 0:
		_last_order_name = command_type

	_update_sandbox_label()
	return issued_count


func _sync_target_marker() -> void:
	var target_marker = get_node_or_null(target_marker_path)
	if not (target_marker is Node2D) or target_positions.is_empty():
		return

	target_marker.position = get_current_target_position()


func _update_sandbox_label() -> void:
	var sandbox_label = get_node_or_null(sandbox_label_path)
	if sandbox_label == null:
		return

	var lines: PackedStringArray = []
	lines.append("Sandbox")
	lines.append("1 move  2 defend  3 flank")
	lines.append("Q/E target")
	lines.append("Target: %s" % str(get_current_target_position()))
	lines.append("Last order: %s" % _last_order_name)
	sandbox_label.text = "\n".join(lines)
