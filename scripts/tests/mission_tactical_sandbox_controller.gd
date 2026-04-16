extends Node

const DEFAULT_MARKER_COLOR: Color = Color(0.95, 0.85, 0.2, 1.0)
const MOVE_COLOR: Color = Color(0.95, 0.85, 0.2, 1.0)
const DEFEND_COLOR: Color = Color(0.4, 0.9, 1.0, 1.0)
const FLANK_COLOR: Color = Color(1.0, 0.65, 0.3, 1.0)

@export var runtime_leader_path: NodePath
@export var command_feedback_label_path: NodePath
@export var target_marker_path: NodePath
@export var target_visual_path: NodePath
@export var target_label_path: NodePath
@export var flow_driver_paths: Array[NodePath] = []

var _last_command_type: String = ""


func _ready() -> void:
	var runtime_leader = get_node_or_null(runtime_leader_path)
	if runtime_leader == null:
		push_warning("MissionTacticalSandboxController requires a direct RuntimeLeader reference.")
	else:
		if not runtime_leader.command_issued.is_connected(_on_runtime_leader_command_issued):
			runtime_leader.command_issued.connect(_on_runtime_leader_command_issued)

	_refresh_feedback()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return

	if not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_1:
			issue_move()
		KEY_2:
			issue_defend()
		KEY_3:
			issue_flank()


func issue_move() -> int:
	return _issue_team_command("move")


func issue_defend() -> int:
	return _issue_team_command("defend")


func issue_flank() -> int:
	return _issue_team_command("flank")


func _issue_team_command(command_type: String) -> int:
	var issue_count: int = 0
	var target_position: Variant = _get_target_position()
	for flow_driver_path in flow_driver_paths:
		var flow_driver = get_node_or_null(flow_driver_path)
		if flow_driver == null or not flow_driver.has_method("issue_command"):
			continue

		if bool(flow_driver.call("issue_command", command_type, target_position)):
			issue_count += 1

	if issue_count > 0:
		_set_last_command_type(command_type)

	return issue_count


func _on_runtime_leader_command_issued(order: Dictionary) -> void:
	var command_type: String = String(order.get("type", ""))
	if command_type.is_empty():
		return

	_set_last_command_type(command_type)


func _set_last_command_type(command_type: String) -> void:
	_last_command_type = command_type
	_refresh_feedback()


func _refresh_feedback() -> void:
	_refresh_command_feedback_label()
	_refresh_target_marker_feedback()


func _refresh_command_feedback_label() -> void:
	var command_feedback_label = get_node_or_null(command_feedback_label_path) as Label
	if command_feedback_label == null:
		return

	var lines: PackedStringArray = []
	lines.append("ACTIVE ORDER")
	if _last_command_type.is_empty():
		lines.append("AWAITING INPUT")
	else:
		lines.append(_get_command_feedback_text(_last_command_type))

	lines.append("1 MOVE   2 DEFEND   3 FLANK")
	command_feedback_label.text = "\n".join(lines)
	command_feedback_label.modulate = _get_command_color(_last_command_type)


func _refresh_target_marker_feedback() -> void:
	var target_visual = get_node_or_null(target_visual_path) as Polygon2D
	if target_visual != null:
		target_visual.color = _get_command_color(_last_command_type)

	var target_label = get_node_or_null(target_label_path) as Label
	if target_label != null:
		target_label.text = _get_target_label_text(_last_command_type)
		target_label.modulate = _get_command_color(_last_command_type)


func _get_target_position() -> Variant:
	var target_marker = get_node_or_null(target_marker_path)
	if target_marker is Node2D:
		return target_marker.position

	return null


func _get_command_feedback_text(command_type: String) -> String:
	match command_type:
		"move":
			return "MOVE ORDER"
		"defend":
			return "HOLD / DEFEND"
		"flank":
			return "FLANK"
		_:
			return "ORDER"


func _get_target_label_text(command_type: String) -> String:
	match command_type:
		"move":
			return "MOVE TARGET"
		"defend":
			return "DEFEND POINT"
		"flank":
			return "FLANK TARGET"
		_:
			return "ORDER TARGET"


func _get_command_color(command_type: String) -> Color:
	match command_type:
		"move":
			return MOVE_COLOR
		"defend":
			return DEFEND_COLOR
		"flank":
			return FLANK_COLOR
		_:
			return DEFAULT_MARKER_COLOR
