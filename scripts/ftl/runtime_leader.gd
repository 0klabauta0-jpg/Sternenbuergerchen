class_name RuntimeLeader
extends Node

signal promoted(new_leader)
signal demoted(old_leader)
signal assigned(entity)
signal command_issued(order)
signal ftl_task_assigned(task)
signal ftl_task_processed(task)
signal ftl_task_enqueued(task)
signal ftl_task_dequeued(task)

var _current_entity: Node = null
var _is_leader: bool = false
var _current_ftl_task: RefCounted = null
var _processed_ftl_task_count: int = 0
var _ftl_task_queue: Array = []


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

	_processed_ftl_task_count += 1
	ftl_task_processed.emit(_current_ftl_task)


func get_current_ftl_task():
	return _current_ftl_task


func get_processed_ftl_task_count() -> int:
	return _processed_ftl_task_count


func get_ftl_task_queue_size() -> int:
	return _ftl_task_queue.size()


# Orders are only forwarded; execution belongs to later systems.
func command(order: Dictionary) -> void:
	if typeof(order) != TYPE_DICTIONARY:
		push_warning("RuntimeLeader.command expects a Dictionary order.")
		return

	command_issued.emit(order)


func _is_valid_ftl_task(task) -> bool:
	return task != null and task.has_method("is_valid") and bool(task.call("is_valid"))
