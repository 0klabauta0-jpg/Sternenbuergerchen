extends Node

const DEFAULT_MARKER_COLOR: Color = Color(0.95, 0.85, 0.2, 1.0)
const MOVE_COLOR: Color = Color(0.95, 0.85, 0.2, 1.0)
const DEFEND_COLOR: Color = Color(0.4, 0.9, 1.0, 1.0)
const FLANK_COLOR: Color = Color(1.0, 0.65, 0.3, 1.0)
const TAKE_COLOR: Color = Color(1.0, 0.42, 0.42, 1.0)
const PHASE_APPROACH: int = 0
const PHASE_ASSAULT: int = 1
const PHASE_HOLD: int = 2
const FIRETEAM_ALL: String = "all"
const FIRETEAM_BLUE: String = "blue"
const FIRETEAM_GOLD: String = "gold"
const FIRETEAM_ORDER: PackedStringArray = [
	FIRETEAM_ALL,
	FIRETEAM_BLUE,
	FIRETEAM_GOLD,
]
const PHASE_ORDER: PackedInt32Array = [
	PHASE_APPROACH,
	PHASE_ASSAULT,
	PHASE_HOLD,
]

@export var order_team_label: String = "ALPHA TEAM"
@export var runtime_leader_path: NodePath
@export var command_feedback_label_path: NodePath
@export var target_marker_path: NodePath
@export var target_visual_path: NodePath
@export var target_label_path: NodePath
@export var flow_driver_paths: Array[NodePath] = []

var _last_command_type: String = ""
var _active_fireteam_id: String = FIRETEAM_ALL
var _active_order_phase: int = PHASE_APPROACH


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
		KEY_4:
			issue_take()
		KEY_Q, KEY_TAB:
			cycle_active_fireteam(-1)
		KEY_E:
			cycle_active_fireteam(1)
		KEY_R:
			cycle_order_phase(1)
		KEY_F:
			cycle_order_phase(-1)


func issue_move() -> int:
	return _issue_team_command("move")


func issue_defend() -> int:
	return _issue_team_command("defend")


func issue_flank() -> int:
	return _issue_team_command("flank")


func issue_take() -> int:
	return _issue_team_command("take")


func set_active_fireteam(fireteam_id: String) -> void:
	if not FIRETEAM_ORDER.has(fireteam_id):
		return

	_active_fireteam_id = fireteam_id
	_refresh_feedback()


func get_active_fireteam() -> String:
	return _active_fireteam_id


func set_active_order_phase(order_phase: int) -> void:
	if not PHASE_ORDER.has(order_phase):
		return

	_active_order_phase = order_phase
	_refresh_feedback()


func get_active_order_phase() -> int:
	return _active_order_phase


func cycle_active_fireteam(step: int) -> void:
	var current_index: int = FIRETEAM_ORDER.find(_active_fireteam_id)
	if current_index < 0:
		current_index = 0

	var next_index: int = posmod(current_index + step, FIRETEAM_ORDER.size())
	set_active_fireteam(FIRETEAM_ORDER[next_index])


func cycle_order_phase(step: int) -> void:
	var current_index: int = PHASE_ORDER.find(_active_order_phase)
	if current_index < 0:
		current_index = 0

	var next_index: int = posmod(current_index + step, PHASE_ORDER.size())
	set_active_order_phase(PHASE_ORDER[next_index])


func _issue_team_command(command_type: String) -> int:
	var issue_count: int = 0
	var target_position: Variant = _get_target_position()
	for flow_driver_path in flow_driver_paths:
		var flow_driver = get_node_or_null(flow_driver_path)
		if flow_driver == null or not flow_driver.has_method("issue_command"):
			continue

		if not _matches_active_fireteam(flow_driver):
			continue

		if bool(flow_driver.call("issue_command", command_type, target_position, _active_order_phase)):
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
	lines.append("%s ORDER" % order_team_label)
	lines.append("ACTIVE FT: %s" % _get_fireteam_feedback_text())
	lines.append("ORDER PHASE: %s" % _get_phase_feedback_text())
	if _last_command_type.is_empty():
		lines.append("AWAITING INPUT")
	else:
		lines.append(_get_command_feedback_text(_last_command_type))

	lines.append("Q/E FT   R/F PHASE")
	lines.append("1 MOVE   2 DEFEND   3 FLANK   4 TAKE")
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


func _matches_active_fireteam(flow_driver: Node) -> bool:
	if _active_fireteam_id == FIRETEAM_ALL:
		return true

	if flow_driver == null:
		return false

	var flow_driver_fireteam_id: String = String(flow_driver.get("fireteam_id"))
	return flow_driver_fireteam_id == _active_fireteam_id


func _get_command_feedback_text(command_type: String) -> String:
	match command_type:
		"move":
			return "MOVE ORDER"
		"defend":
			return "HOLD / DEFEND"
		"flank":
			return "FLANK"
		"take":
			return "TAKE / ENGAGE"
		_:
			return "ORDER"


func _get_fireteam_feedback_text() -> String:
	match _active_fireteam_id:
		FIRETEAM_BLUE:
			return "BLUE"
		FIRETEAM_GOLD:
			return "GOLD"
		_:
			return "ALL"


func _get_phase_feedback_text() -> String:
	match _active_order_phase:
		PHASE_ASSAULT:
			return "ASSAULT"
		PHASE_HOLD:
			return "HOLD"
		_:
			return "APPROACH"


func _get_target_label_text(command_type: String) -> String:
	match command_type:
		"move":
			return "MOVE TARGET"
		"defend":
			return "DEFEND POINT"
		"flank":
			return "FLANK TARGET"
		"take":
			return "ENGAGE AREA"
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
		"take":
			return TAKE_COLOR
		_:
			return DEFAULT_MARKER_COLOR
