class_name SimulationRoot
extends Node

signal tick_processed(tick: int)
signal command_processed(cmd: Dictionary)
signal target_unit_resolved(unit_id: String, unit: Node)

@export var unit_registry_path: NodePath

var command_queue: Array = []
var effects_queue: Array = []
var tick_counter: int = 0
var is_processing_tick: bool = false
var last_processed_command: Dictionary = {}
var processed_command_count: int = 0
var last_target_unit_id: String = ""
var last_target_unit_ref: Node = null

var _unit_registry: Node = null


func enqueue_command(cmd: Dictionary) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_command expects a Dictionary command.")
		return

	command_queue.append(cmd)


func enqueue_effect(effect: Dictionary) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot.enqueue_effect expects a Dictionary effect.")
		return

	effects_queue.append(effect)


func clear_queues() -> void:
	command_queue.clear()
	effects_queue.clear()


func get_tick() -> int:
	return tick_counter


func _ready() -> void:
	_unit_registry = _get_unit_registry()


# Commands are committed before effects on every authoritative physics tick.
func _physics_process(delta: float) -> void:
	tick_counter += 1
	is_processing_tick = true

	var commands: Array = _drain_queue(command_queue)
	_process_commands(commands, delta)

	var effects: Array = _drain_queue(effects_queue)
	_process_effects(effects, delta)

	is_processing_tick = false
	tick_processed.emit(tick_counter)


func _process_commands(commands: Array, delta: float) -> void:
	var ordered_commands: Array = _order_payloads(commands)

	for cmd in ordered_commands:
		_apply_command(cmd, delta)


func _process_effects(effects: Array, delta: float) -> void:
	var ordered_effects: Array = _order_payloads(effects)

	for effect in ordered_effects:
		_apply_effect(effect, delta)


func _apply_command(cmd: Dictionary, delta: float) -> void:
	if typeof(cmd) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary commands.")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying a command.")
		return

	if not cmd.has("type"):
		push_warning("SimulationRoot command is missing a type.")
		return

	var command_type: Variant = cmd["type"]
	if typeof(command_type) != TYPE_STRING:
		push_warning("SimulationRoot command type must be a String.")
		return

	if command_type != "move":
		push_warning("SimulationRoot does not handle command type '%s' yet." % String(command_type))
		return

	last_processed_command = cmd.duplicate(true)
	processed_command_count += 1
	command_processed.emit(last_processed_command.duplicate(true))

	if not cmd.has("unit_id"):
		return

	var unit_id: Variant = cmd["unit_id"]
	if typeof(unit_id) != TYPE_STRING or String(unit_id).strip_edges().is_empty():
		push_warning("SimulationRoot command unit_id must be a non-empty String.")
		return

	last_target_unit_id = String(unit_id)
	last_target_unit_ref = _resolve_target_unit(last_target_unit_id)

	if last_target_unit_ref == null:
		push_warning("SimulationRoot could not resolve unit_id '%s'." % last_target_unit_id)
		return

	target_unit_resolved.emit(last_target_unit_id, last_target_unit_ref)


func _apply_effect(effect: Dictionary, delta: float) -> void:
	if typeof(effect) != TYPE_DICTIONARY:
		push_warning("SimulationRoot can only apply Dictionary effects.")
		return

	if delta < 0.0:
		push_warning("SimulationRoot received a negative physics delta while applying an effect.")
		return

	# TODO: Deterministic effect commits belong here once systems exist.


func _drain_queue(queue: Array) -> Array:
	var drained: Array = queue.duplicate(false)
	queue.clear()
	return drained


func _order_payloads(payloads: Array) -> Array:
	var decorated: Array = []
	var index: int = 0

	for payload in payloads:
		if typeof(payload) != TYPE_DICTIONARY:
			push_warning("SimulationRoot expected queued payloads to be dictionaries.")
			index += 1
			continue

		decorated.append(
			{
				"index": index,
				"priority": _extract_priority(payload),
				"payload": payload,
			}
		)
		index += 1

	decorated.sort_custom(_sort_payload_entries)

	var ordered: Array = []
	for entry in decorated:
		ordered.append(entry["payload"])

	return ordered


func _extract_priority(payload: Dictionary) -> int:
	if not payload.has("priority"):
		return 0

	var priority: Variant = payload["priority"]
	if typeof(priority) == TYPE_INT or typeof(priority) == TYPE_FLOAT:
		return int(priority)

	push_warning("SimulationRoot expected payload priority to be numeric.")
	return 0


func _sort_payload_entries(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = int(a["priority"])
	var b_priority: int = int(b["priority"])

	if a_priority == b_priority:
		return int(a["index"]) < int(b["index"])

	return a_priority > b_priority


func _get_unit_registry() -> Node:
	if _unit_registry != null and is_instance_valid(_unit_registry):
		return _unit_registry

	if unit_registry_path.is_empty():
		return null

	_unit_registry = get_node_or_null(unit_registry_path)
	return _unit_registry


func _resolve_target_unit(unit_id: String) -> Node:
	var registry: Node = _get_unit_registry()
	if registry == null:
		push_warning("SimulationRoot has no UnitRegistry reference for target resolution.")
		return null

	if not registry.has_method("get_unit"):
		push_warning("SimulationRoot expects UnitRegistry to provide get_unit().")
		return null

	return registry.call("get_unit", unit_id)
