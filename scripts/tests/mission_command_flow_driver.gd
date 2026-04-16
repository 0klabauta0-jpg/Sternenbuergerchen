extends Node

const COMMANDER_COMMAND_SCRIPT: GDScript = preload("res://scripts/command/commander_command.gd")
const TRANSLATOR_SCRIPT: GDScript = preload("res://scripts/command/command_to_ftltask_translator.gd")

@export var auto_run_on_ready: bool = true
@export var team_id: String = "team_alpha"
@export var unit_id: String = "unit_alpha"
@export var runtime_leader_path: NodePath
@export var event_router_path: NodePath
@export var simulation_root_path: NodePath
@export var unit_registry_path: NodePath
@export var target_marker_path: NodePath

var last_translated_task: RefCounted = null
var last_enqueued_command: Dictionary = {}
var _has_run_flow: bool = false


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


func run_flow() -> void:
	if _has_run_flow:
		return

	var runtime_leader = get_node_or_null(runtime_leader_path)
	var target_marker = get_node_or_null(target_marker_path)
	if runtime_leader == null or not (target_marker is Node2D):
		push_warning("MissionCommandFlowDriver requires a RuntimeLeader and a Node2D target marker.")
		return

	var command = COMMANDER_COMMAND_SCRIPT.new()
	command.command_type = "move"
	command.priority = 10
	command.unit_id = unit_id
	command.team_id = team_id
	command.target_position = target_marker.position
	if not bool(command.call("is_valid")):
		push_warning("MissionCommandFlowDriver could not build a valid CommanderCommand.")
		return

	_has_run_flow = true
	runtime_leader.call("command", command.call("to_dict"))


func _on_runtime_leader_command_issued(order: Dictionary) -> void:
	var runtime_leader = get_node_or_null(runtime_leader_path)
	var event_router = get_node_or_null(event_router_path)
	if runtime_leader == null or event_router == null:
		return

	event_router.call("route_squad_command", runtime_leader, order)


func _on_squad_command(_squad: Node, order: Dictionary) -> void:
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
	if not bool(runtime_leader.call("assign_current_ftl_task_to_unit")):
		return

	var unit = unit_registry.call("get_unit", unit_id)
	if unit == null or not unit.has_method("get_current_unit_command"):
		push_warning("MissionCommandFlowDriver could not resolve the target unit for command enqueue.")
		return

	var unit_command = unit.call("get_current_unit_command")
	if unit_command == null or not unit_command.has_method("to_dict"):
		push_warning("MissionCommandFlowDriver requires a valid UnitCommand before enqueue.")
		return

	last_translated_task = translated_task
	last_enqueued_command = unit_command.call("to_dict")
	simulation_root.call("enqueue_command", last_enqueued_command)
