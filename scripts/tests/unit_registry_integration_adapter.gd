class_name UnitRegistryIntegrationAdapter
extends Node

@export var unit_registry_path: NodePath
@export var runtime_leader_path: NodePath
@export var test_unit_path: NodePath

var registration_success: bool = false
var lookup_matches: bool = false
var assigned_signal_count: int = 0
var assigned_entity_matches: bool = false

var _unit_registry: Node = null
var _runtime_leader: Node = null
var _test_unit: Node = null


func _ready() -> void:
	_unit_registry = get_node_or_null(unit_registry_path) as UnitRegistry
	_runtime_leader = get_node_or_null(runtime_leader_path) as RuntimeLeader
	_test_unit = get_node_or_null(test_unit_path) as TestUnit

	if _unit_registry == null or _runtime_leader == null or _test_unit == null:
		push_warning("UnitRegistryIntegrationAdapter requires UnitRegistry, RuntimeLeader, and TestUnit references.")
		return

	if not _unit_registry.has_method("register_unit") or not _unit_registry.has_method("get_unit"):
		push_warning("UnitRegistryIntegrationAdapter requires a registry with register_unit() and get_unit().")
		return

	if not _runtime_leader.has_method("assign") or not _runtime_leader.has_signal("assigned"):
		push_warning("UnitRegistryIntegrationAdapter requires a RuntimeLeader-compatible node.")
		return

	if not _test_unit.has_method("get_unit_id"):
		push_warning("UnitRegistryIntegrationAdapter requires a unit with get_unit_id().")
		return

	_runtime_leader.connect("assigned", Callable(self, "_on_runtime_leader_assigned"))

	var unit_id: String = String(_test_unit.call("get_unit_id"))
	registration_success = bool(_unit_registry.call("register_unit", unit_id, _test_unit))
	lookup_matches = _unit_registry.call("get_unit", unit_id) == _test_unit
	_runtime_leader.call("assign", _test_unit)


func get_registration_success() -> bool:
	return registration_success


func get_lookup_matches() -> bool:
	return lookup_matches


func get_assigned_signal_count() -> int:
	return assigned_signal_count


func get_assigned_entity_matches() -> bool:
	return assigned_entity_matches


func _on_runtime_leader_assigned(entity: Node) -> void:
	assigned_signal_count += 1
	assigned_entity_matches = entity == _test_unit
