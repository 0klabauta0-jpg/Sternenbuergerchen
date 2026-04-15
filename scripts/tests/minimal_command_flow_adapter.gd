class_name MinimalCommandFlowAdapter
extends Node

const TEST_ORDER: Dictionary = {
	"type": "move",
	"priority": 10,
	"unit_id": "unit_test_001",
}

@export var unit_registry_path: NodePath
@export var runtime_leader_path: NodePath
@export var event_router_path: NodePath
@export var simulation_root_path: NodePath
@export var test_unit_path: NodePath

var registration_success: bool = false
var lookup_matches: bool = false
var assigned_entity_matches: bool = false
var command_signal_count: int = 0
var routed_command_count: int = 0
var enqueued_command_count: int = 0
var processed_signal_count: int = 0
var queue_size_after_enqueue: int = 0
var last_command: Dictionary = {}
var last_processed_command: Dictionary = {}

var _unit_registry: Node = null
var _runtime_leader: Node = null
var _event_router: Node = null
var _simulation_root: Node = null
var _test_unit: Node = null


func _ready() -> void:
	_unit_registry = get_node_or_null(unit_registry_path)
	_runtime_leader = get_node_or_null(runtime_leader_path)
	_event_router = get_node_or_null(event_router_path)
	_simulation_root = get_node_or_null(simulation_root_path)
	_test_unit = get_node_or_null(test_unit_path)

	if _unit_registry == null or _runtime_leader == null or _event_router == null or _simulation_root == null or _test_unit == null:
		push_warning("MinimalCommandFlowAdapter requires UnitRegistry, RuntimeLeader, EventRouter, SimulationRoot, and TestUnit references.")
		return

	if not _unit_registry.has_method("register_unit") or not _unit_registry.has_method("get_unit"):
		push_warning("MinimalCommandFlowAdapter requires a registry with register_unit() and get_unit().")
		return

	if not _runtime_leader.has_method("assign") or not _runtime_leader.has_method("command") or not _runtime_leader.has_signal("assigned") or not _runtime_leader.has_signal("command_issued"):
		push_warning("MinimalCommandFlowAdapter requires a RuntimeLeader-compatible node.")
		return

	if not _event_router.has_method("route_squad_command") or not _event_router.has_signal("squad_command"):
		push_warning("MinimalCommandFlowAdapter requires an EventRouter-compatible node.")
		return

	if not _simulation_root.has_method("enqueue_command") or not _simulation_root.has_signal("command_processed"):
		push_warning("MinimalCommandFlowAdapter requires a SimulationRoot-compatible node.")
		return

	if not _test_unit.has_method("get_unit_id"):
		push_warning("MinimalCommandFlowAdapter requires a unit with get_unit_id().")
		return

	_runtime_leader.connect("assigned", Callable(self, "_on_runtime_leader_assigned"))
	_runtime_leader.connect("command_issued", Callable(self, "_on_runtime_leader_command_issued"))
	_event_router.connect("squad_command", Callable(self, "_on_squad_command"))
	_simulation_root.connect("command_processed", Callable(self, "_on_command_processed"))

	var unit_id: String = String(_test_unit.call("get_unit_id"))
	registration_success = bool(_unit_registry.call("register_unit", unit_id, _test_unit))
	lookup_matches = _unit_registry.call("get_unit", unit_id) == _test_unit
	_runtime_leader.call("assign", _test_unit)
	_runtime_leader.call("command", TEST_ORDER.duplicate(true))


func get_registration_success() -> bool:
	return registration_success


func get_lookup_matches() -> bool:
	return lookup_matches


func get_assigned_entity_matches() -> bool:
	return assigned_entity_matches


func get_command_signal_count() -> int:
	return command_signal_count


func get_routed_command_count() -> int:
	return routed_command_count


func get_enqueued_command_count() -> int:
	return enqueued_command_count


func get_processed_signal_count() -> int:
	return processed_signal_count


func get_queue_size_after_enqueue() -> int:
	return queue_size_after_enqueue


func get_last_command() -> Dictionary:
	return last_command.duplicate(true)


func get_last_processed_command() -> Dictionary:
	return last_processed_command.duplicate(true)


func _on_runtime_leader_assigned(entity: Node) -> void:
	assigned_entity_matches = entity == _test_unit


func _on_runtime_leader_command_issued(order: Dictionary) -> void:
	command_signal_count += 1
	last_command = order.duplicate(true)
	_event_router.call("route_squad_command", _runtime_leader, order)


func _on_squad_command(_squad: Node, order: Dictionary) -> void:
	routed_command_count += 1
	_simulation_root.call("enqueue_command", order)
	enqueued_command_count += 1
	var queued_commands: Array = _simulation_root.get("command_queue")
	queue_size_after_enqueue = queued_commands.size()


func _on_command_processed(cmd: Dictionary) -> void:
	processed_signal_count += 1
	last_processed_command = cmd.duplicate(true)
