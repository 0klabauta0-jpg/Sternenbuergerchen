class_name RuntimeLeader
extends Node

signal promoted(new_leader)
signal demoted(old_leader)
signal assigned(entity)
signal command_issued(order)

var _current_entity: Node = null
var _is_leader: bool = false


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


# Orders are only forwarded; execution belongs to later systems.
func command(order: Dictionary) -> void:
	if typeof(order) != TYPE_DICTIONARY:
		push_warning("RuntimeLeader.command expects a Dictionary order.")
		return

	command_issued.emit(order)
