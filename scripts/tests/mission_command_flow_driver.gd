extends Node

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const TRANSLATOR_SCRIPT: GDScript = preload("res://scripts/command/command_to_ftltask_translator.gd")

@export var auto_run_on_ready: bool = true
@export var commander_command_type: String = "take"
@export var team_id: String = "team_alpha"
@export var unit_id: String = "unit_alpha"
@export var phase: int = -1
@export var runtime_leader_path: NodePath
@export var event_router_path: NodePath
@export var simulation_root_path: NodePath
@export var unit_registry_path: NodePath
@export var target_marker_path: NodePath

var last_translated_task: RefCounted = null
var last_enqueued_command: Dictionary = {}
var last_issued_order: Dictionary = {}


func _ready() -> void:
	var runtime_leader = get_node_or_null(runtime_leader_path)
	var event_router = get_node_or_null(event_router_path)
	if runtime_leader == null or event_router == null:
		push_warning("MissionCommandFlowDriver requires direct RuntimeLeader and EventRouter references.")
		return

	if not runtime_leader.command_issued.is_connected(_on_runtime_leader_command_issued):
		runtime_leader.command_issued.connect(_on_runtime_leader_command_issued)

	if not event_router.squad_command.is_connected(_on_squad_command):
		event_router.squad_command.connect(_on_squad_command)

	if auto_run_on_ready:
		run_flow()


func run_flow() -> bool:
	return issue_command()


func issue_command(command_type_override: String = "", phase_override: int = -1) -> bool:
	return _issue_command_internal(command_type_override, phase_override, null)


func issue_command_at_position(target_world_position: Vector2, command_type_override: String = "", phase_override: int = -1) -> bool:
	return _issue_command_internal(command_type_override, phase_override, target_world_position)


func mirror_command_at_position(target_world_position: Vector2, command_type_override: String = "", phase_override: int = -1) -> bool:
	var command = COMMANDER_COMMAND_SCRIPT.new()
	command.command_type = commander_command_type if command_type_override.is_empty() else command_type_override
	command.priority = 10
	command.unit_id = unit_id
	command.team_id = team_id
	command.target_position = target_world_position
	command.phase = phase if phase_override < 0 else phase_override
	if not bool(command.call("is_valid")):
		return false
	last_issued_order = command.call("to_dict")
	return true


func _issue_command_internal(command_type_override: String, phase_override: int, target_position_override) -> bool:
	var runtime_leader = get_node_or_null(runtime_leader_path)
	var target_marker = get_node_or_null(target_marker_path)
	if runtime_leader == null or not (target_marker is Node2D):
		push_warning("MissionCommandFlowDriver requires a RuntimeLeader and a Node2D target marker.")
		return false

	var command = COMMANDER_COMMAND_SCRIPT.new()
	command.command_type = commander_command_type if command_type_override.is_empty() else command_type_override
	command.priority = 10
	command.unit_id = unit_id
	command.team_id = team_id
	if typeof(target_position_override) == TYPE_VECTOR2:
		command.target_position = target_position_override
	else:
		command.target_position = target_marker.global_position
	command.phase = phase if phase_override < 0 else phase_override
	if not bool(command.call("is_valid")):
		push_warning("MissionCommandFlowDriver could not build a valid CommanderCommand.")
		return false

	last_issued_order = command.call("to_dict")
	runtime_leader.call("command", last_issued_order)
	return true


func _on_runtime_leader_command_issued(order: Dictionary) -> void:
	var ordered_unit_id: String = String(order.get("unit_id", unit_id))
	if ordered_unit_id != unit_id:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var event_router = get_node_or_null(event_router_path)
	if runtime_leader == null or event_router == null:
		return

	event_router.call("route_squad_command", runtime_leader, order)


func _on_squad_command(_squad: Node, order: Dictionary) -> void:
	var ordered_unit_id: String = String(order.get("unit_id", unit_id))
	if ordered_unit_id != unit_id:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var simulation_root = get_node_or_null(simulation_root_path)
	var unit_registry = get_node_or_null(unit_registry_path)
	if runtime_leader == null or simulation_root == null or unit_registry == null:
		push_warning("MissionCommandFlowDriver requires RuntimeLeader, SimulationRoot and UnitRegistry references.")
		return

	var translator = TRANSLATOR_SCRIPT.new()
	var translated_task = translator.call("translate_from_dict", order)
	if translated_task == null or not bool(translated_task.call("is_valid")):
		push_warning("MissionCommandFlowDriver could not translate the incoming commander order.")
		return

	if not bool(runtime_leader.call("assign_ftl_task", translated_task)):
		return

	runtime_leader.call("process_current_ftl_task")
	var unit = unit_registry.call("get_unit", unit_id)
	if unit == null:
		last_translated_task = translated_task
		return

	runtime_leader.call("assign", unit)
	if not bool(runtime_leader.call("assign_current_ftl_task_to_unit")):
		return

	if not unit.has_method("get_current_unit_command"):
		push_warning("MissionCommandFlowDriver could not resolve the target unit for command enqueue.")
		return

	var unit_command = unit.call("get_current_unit_command")
	if unit_command == null or not unit_command.has_method("to_dict"):
		push_warning("MissionCommandFlowDriver requires a valid UnitCommand before enqueue.")
		return

	last_translated_task = translated_task
	last_enqueued_command = unit_command.call("to_dict")
	_enqueue_unit_command(simulation_root, last_enqueued_command)


func _enqueue_unit_command(simulation_root: Node, command_dict: Dictionary) -> void:
	if simulation_root == null:
		return

	var is_server_authoritative_mode: bool = bool(simulation_root.get("is_server_authoritative"))
	if not is_server_authoritative_mode:
		simulation_root.call("enqueue_command", command_dict)
		return

	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		simulation_root.call("request_command", command_dict)
		return

	if multiplayer.is_server():
		simulation_root.call("request_command", command_dict)
		return

	simulation_root.call("submit_multiplayer_command", command_dict)
