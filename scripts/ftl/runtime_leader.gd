class_name RuntimeLeader
extends Node

const FTL_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/ftl/ftl_runtime_status.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

signal promoted(new_leader)
signal demoted(old_leader)
signal assigned(entity)
signal command_issued(order)
signal ftl_task_assigned(task)
signal ftl_task_processed(task)
signal ftl_task_enqueued(task)
signal ftl_task_dequeued(task)
signal runtime_status_changed(runtime_status)
signal unit_command_assigned(unit, command)
signal unit_member_added(unit)

var _current_entity: Node = null
var _is_leader: bool = false
var _current_ftl_task: RefCounted = null
var _processed_ftl_task_count: int = 0
var _ftl_task_queue: Array = []
var _runtime_status: RefCounted = FTL_RUNTIME_STATUS_SCRIPT.new()
var _assigned_units: Array = []


func promote() -> void:
	if _is_leader:
		return

	_is_leader = true
	promoted.emit(_current_entity)


func demote() -> void:
	if not _is_leader:
		return

	_is_leader = false
	demoted.emit(_current_entity)


func assign(entity: Node) -> void:
	_current_entity = entity
	assigned.emit(entity)


func add_unit_member(unit: Node) -> bool:
	if not _is_assignable_unit(unit):
		push_warning("RuntimeLeader.add_unit_member expects a unit-like node with assign_unit_command() and get_unit_id().")
		return false

	if _assigned_units.has(unit):
		return false

	_assigned_units.append(unit)
	unit_member_added.emit(unit)
	return true


func assign_ftl_task(task) -> bool:
	if not _is_valid_ftl_task(task):
		push_warning("RuntimeLeader.assign_ftl_task expects a valid FTLTask-like object.")
		return false

	_current_ftl_task = task
	ftl_task_assigned.emit(task)
	return true


func enqueue_ftl_task(task) -> bool:
	if not _is_valid_ftl_task(task):
		push_warning("RuntimeLeader.enqueue_ftl_task expects a valid FTLTask-like object.")
		return false

	_ftl_task_queue.append(task)
	ftl_task_enqueued.emit(task)
	return true


func process_next_queued_ftl_task() -> void:
	if _ftl_task_queue.is_empty():
		return

	var next_task = _ftl_task_queue.pop_front()
	ftl_task_dequeued.emit(next_task)
	assign_ftl_task(next_task)
	process_current_ftl_task()


func process_current_ftl_task() -> void:
	if _current_ftl_task == null:
		return

	if not _is_valid_ftl_task(_current_ftl_task):
		push_warning("RuntimeLeader cannot process an invalid FTLTask-like object.")
		return

	_update_runtime_status_from_ftl_task(_current_ftl_task)
	_processed_ftl_task_count += 1
	ftl_task_processed.emit(_current_ftl_task)


func get_current_ftl_task():
	return _current_ftl_task


func get_processed_ftl_task_count() -> int:
	return _processed_ftl_task_count


func get_ftl_task_queue_size() -> int:
	return _ftl_task_queue.size()


func get_runtime_status():
	return _runtime_status


func get_assigned_units() -> Array:
	return _assigned_units.duplicate(false)


func get_assigned_unit_count() -> int:
	return _assigned_units.size()


func assign_current_ftl_task_to_unit() -> bool:
	if _current_entity == null or not _is_assignable_unit(_current_entity):
		push_warning("RuntimeLeader.assign_current_ftl_task_to_unit expects an assigned unit-like node.")
		return false

	if _current_ftl_task == null or not _is_valid_ftl_task(_current_ftl_task):
		push_warning("RuntimeLeader.assign_current_ftl_task_to_unit expects a valid current FTLTask.")
		return false

	return _assign_ftl_task_to_unit(_current_ftl_task, _current_entity)


func assign_current_ftl_task_to_all_units() -> int:
	if _current_ftl_task == null or not _is_valid_ftl_task(_current_ftl_task):
		push_warning("RuntimeLeader.assign_current_ftl_task_to_all_units expects a valid current FTLTask.")
		return 0

	var assigned_count: int = 0
	for unit in _assigned_units:
		if _assign_ftl_task_to_unit(_current_ftl_task, unit):
			assigned_count += 1

	return assigned_count


# Orders are only forwarded; execution belongs to later systems.
func command(order: Dictionary) -> void:
	if typeof(order) != TYPE_DICTIONARY:
		push_warning("RuntimeLeader.command expects a Dictionary order.")
		return

	command_issued.emit(order)


func _is_valid_ftl_task(task) -> bool:
	return task != null and task.has_method("is_valid") and bool(task.call("is_valid"))


func _is_assignable_unit(unit: Node) -> bool:
	return unit != null and unit.has_method("assign_unit_command") and unit.has_method("get_unit_id")


func _assign_ftl_task_to_unit(task, unit: Node) -> bool:
	var unit_command = _build_unit_command_from_ftl_task(task, unit)
	if unit_command == null or not bool(unit_command.call("is_valid")):
		push_warning("RuntimeLeader could not derive a valid UnitCommand from the current FTLTask.")
		return false

	if not bool(unit.call("assign_unit_command", unit_command)):
		return false

	unit_command_assigned.emit(unit, unit_command)
	return true


func _update_runtime_status_from_ftl_task(task) -> void:
	var status_name: String = _map_task_type_to_runtime_status(String(task.get("task_type")))
	if status_name.is_empty():
		return

	var runtime_status = FTL_RUNTIME_STATUS_SCRIPT.new()
	runtime_status.status = status_name
	runtime_status.active_task_type = String(task.get("task_type"))
	runtime_status.priority = int(task.get("priority"))
	runtime_status.unit_id = String(task.get("unit_id"))
	runtime_status.team_id = String(task.get("team_id"))
	runtime_status.phase = int(task.get("phase"))

	if not bool(runtime_status.call("is_valid")):
		return

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)


func _map_task_type_to_runtime_status(task_type: String) -> String:
	match task_type:
		"seek_cover":
			return "seeking_cover"
		"move_to_area":
			return "moving_to_area"
		"engage_in_area":
			return "engaging_in_area"
		"hold_position":
			return "holding_position"
		"retreat":
			return "retreating"
		_:
			return ""


func _build_unit_command_from_ftl_task(task, unit: Node):
	var command_type: String = _map_task_type_to_unit_command_type(String(task.get("task_type")))
	if command_type.is_empty():
		return null

	var unit_command = UNIT_COMMAND_SCRIPT.new()
	unit_command.command_type = command_type
	unit_command.priority = int(task.get("priority"))
	unit_command.unit_id = String(task.get("unit_id"))
	if unit_command.unit_id.is_empty():
		unit_command.unit_id = String(unit.call("get_unit_id"))
	unit_command.team_id = String(task.get("team_id"))
	unit_command.target_position = task.get("target_position")
	unit_command.target_area_id = String(task.get("target_area_id"))
	unit_command.source_task_type = String(task.get("task_type"))
	unit_command.phase = int(task.get("phase"))
	return unit_command


func _map_task_type_to_unit_command_type(task_type: String) -> String:
	match task_type:
		"seek_cover":
			return "seek_cover"
		"move_to_area":
			return "move_to_position"
		"engage_in_area":
			return "engage_area"
		"hold_position":
			return "hold_position"
		"retreat":
			return "retreat"
		_:
			return ""
