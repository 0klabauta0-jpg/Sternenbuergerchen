class_name RuntimeLeaderIntegrationAdapter
extends Node

const TEST_ORDER: Dictionary = {
	"type": "move",
	"priority": 10,
}

@export var runtime_leader_path: NodePath
@export var event_router_path: NodePath
@export var simulation_root_path: NodePath

var command_signal_count: int = 0
var routed_command_count: int = 0
var enqueued_command_count: int = 0
var last_command: Dictionary = {}
var last_enqueued_command: Dictionary = {}

var _runtime_leader: RuntimeLeader = null
var _event_router: EventRouter = null
var _simulation_root: SimulationRoot = null


func _ready() -> void:
	_runtime_leader = get_node_or_null(runtime_leader_path) as RuntimeLeader
	_event_router = get_node_or_null(event_router_path) as EventRouter
	_simulation_root = get_node_or_null(simulation_root_path) as SimulationRoot

	if _runtime_leader == null or _event_router == null or _simulation_root == null:
		push_warning("RuntimeLeaderIntegrationAdapter requires RuntimeLeader, EventRouter, and SimulationRoot references.")
		return

	_runtime_leader.command_issued.connect(_on_runtime_leader_command_issued)
	_event_router.squad_command.connect(_on_squad_command)

	run_test_command()


func run_test_command() -> void:
	if _runtime_leader == null:
		return

	_runtime_leader.command(TEST_ORDER.duplicate(true))


func get_command_signal_count() -> int:
	return command_signal_count


func get_routed_command_count() -> int:
	return routed_command_count


func get_last_command() -> Dictionary:
	return last_command.duplicate(true)


func get_enqueued_command_count() -> int:
	if _simulation_root == null:
		return 0

	return _simulation_root.command_queue.size()


func get_first_enqueued_command() -> Dictionary:
	if _simulation_root == null or _simulation_root.command_queue.is_empty():
		return last_enqueued_command.duplicate(true)

	return (_simulation_root.command_queue[0] as Dictionary).duplicate(true)


func get_enqueued_command_accept_count() -> int:
	return enqueued_command_count


func _on_runtime_leader_command_issued(order: Dictionary) -> void:
	command_signal_count += 1
	last_command = order.duplicate(true)
	_event_router.route_squad_command(_runtime_leader, order)


func _on_squad_command(_squad: Node, order: Dictionary) -> void:
	routed_command_count += 1
	_simulation_root.enqueue_command(order)
	enqueued_command_count += 1
	last_enqueued_command = order.duplicate(true)
