class_name RuntimeLeader
extends Node

const FTL_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/ftl/ftl_runtime_status.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const FLANK_OFFSET_DISTANCE: float = 72.0
const ROLE_ANCHOR: String = "anchor"
const ROLE_RECON: String = "recon"
const ROLE_ASSAULT: String = "assault"
const MOVE_RECON_LATERAL_OFFSET: float = 28.0
const MOVE_ASSAULT_FORWARD_OFFSET: float = 24.0
const FLANK_RECON_LATERAL_SCALE: float = 1.45
const FLANK_ASSAULT_FORWARD_OFFSET: float = 28.0
const DELAY_ANCHOR_MOVE: int = 3
const DELAY_ANCHOR_FLANK: int = 4
const DELAY_ANCHOR_TAKE: int = 2
const DELAY_RECON_DEFEND: int = 1
const DELAY_RECON_MOVE: int = 1
const DELAY_ASSAULT_DEFEND: int = 2
const DELAY_ASSAULT_MOVE: int = 1

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
	var task_type: String = String(task.get("task_type"))
	var source_command_type: String = String(task.get("source_command_type"))
	var command_type: String = _map_task_type_to_unit_command_type(task_type)
	if command_type.is_empty():
		return null

	var unit_command = UNIT_COMMAND_SCRIPT.new()
	unit_command.command_type = command_type
	unit_command.priority = int(task.get("priority"))
	unit_command.unit_id = String(task.get("unit_id"))
	if unit_command.unit_id.is_empty():
		unit_command.unit_id = String(unit.call("get_unit_id"))
	unit_command.team_id = String(task.get("team_id"))
	unit_command.fire_status = _map_task_type_to_fire_status(task_type, source_command_type)
	unit_command.source_command_type = source_command_type
	unit_command.cover_score = _derive_cover_score(task_type, source_command_type, unit)
	unit_command.attack_bonus = _derive_attack_bonus(task_type, source_command_type, unit)
	unit_command.execution_delay_ticks = _derive_execution_delay_ticks(task_type, source_command_type, unit)
	unit_command.target_position = _derive_target_position(task, unit, command_type, source_command_type)
	unit_command.target_area_id = String(task.get("target_area_id"))
	unit_command.source_task_type = task_type
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


func _map_task_type_to_fire_status(task_type: String, source_command_type: String) -> String:
	if source_command_type == "move":
		return "hold_fire"

	if source_command_type == "flank":
		return "fire_at_will"

	match task_type:
		"engage_in_area", "hold_position", "seek_cover":
			return "fire_at_will"
		_:
			return "hold_fire"


func _derive_cover_score(task_type: String, source_command_type: String, unit: Node) -> float:
	var cover_score: float = 0.0
	if source_command_type == "defend":
		cover_score = 0.7
	elif source_command_type == "flank":
		cover_score = 0.15
	else:
		match task_type:
			"hold_position":
				cover_score = 0.55
			"seek_cover":
				cover_score = 0.8
			"engage_in_area":
				cover_score = 0.2
			_:
				cover_score = 0.0

	match _get_unit_combat_role(unit):
		ROLE_ANCHOR:
			cover_score += 0.2
		ROLE_RECON:
			cover_score += 0.05
		ROLE_ASSAULT:
			cover_score -= 0.1

	return clampf(cover_score, 0.0, 1.0)


func _derive_attack_bonus(task_type: String, source_command_type: String, unit: Node) -> float:
	var attack_bonus: float = 0.0
	if source_command_type == "flank":
		attack_bonus = 0.35
	else:
		match task_type:
			"engage_in_area":
				attack_bonus = 0.2
			"hold_position":
				attack_bonus = 0.05
			_:
				attack_bonus = 0.0

	match _get_unit_combat_role(unit):
		ROLE_ANCHOR:
			attack_bonus -= 0.08
		ROLE_RECON:
			attack_bonus += 0.08
		ROLE_ASSAULT:
			attack_bonus += 0.18

	return clampf(attack_bonus, 0.0, 0.75)


func _derive_target_position(task, unit: Node, command_type: String, source_command_type: String):
	var raw_target_position: Variant = task.get("target_position")
	if command_type == "hold_position" and unit is Node2D:
		return (unit as Node2D).position

	if typeof(raw_target_position) != TYPE_VECTOR2:
		return raw_target_position

	if source_command_type == "move" and unit is Node2D:
		var unit_position: Vector2 = (unit as Node2D).position
		var move_direction: Vector2 = raw_target_position - unit_position
		if move_direction.is_zero_approx():
			return raw_target_position

		var move_forward_direction: Vector2 = move_direction.normalized()
		var move_lateral_sign: float = -1.0 if unit_position.y <= raw_target_position.y else 1.0
		var move_lateral_direction: Vector2 = move_forward_direction.orthogonal() * move_lateral_sign
		match _get_unit_combat_role(unit):
			ROLE_ANCHOR:
				return unit_position.lerp(raw_target_position, 0.72)
			ROLE_RECON:
				return unit_position.lerp(raw_target_position, 0.88) + move_lateral_direction * MOVE_RECON_LATERAL_OFFSET
			ROLE_ASSAULT:
				return raw_target_position + move_forward_direction * MOVE_ASSAULT_FORWARD_OFFSET
			_:
				return raw_target_position

	if source_command_type != "flank":
		return raw_target_position

	if not (unit is Node2D):
		return raw_target_position

	var unit_position: Vector2 = (unit as Node2D).position
	var direction: Vector2 = raw_target_position - unit_position
	if direction.is_zero_approx():
		return raw_target_position

	var combat_role: String = _get_unit_combat_role(unit)
	var forward_direction: Vector2 = direction.normalized()
	var flank_sign: float = 1.0
	if unit_position.y <= raw_target_position.y:
		flank_sign = -1.0

	var lateral_direction: Vector2 = forward_direction.orthogonal() * flank_sign
	var flank_offset: Vector2 = lateral_direction * FLANK_OFFSET_DISTANCE
	match combat_role:
		ROLE_ANCHOR:
			return raw_target_position + flank_offset * 0.7
		ROLE_RECON:
			return raw_target_position + flank_offset * FLANK_RECON_LATERAL_SCALE
		ROLE_ASSAULT:
			return raw_target_position + flank_offset + forward_direction * FLANK_ASSAULT_FORWARD_OFFSET
		_:
			return raw_target_position + flank_offset


func _derive_execution_delay_ticks(task_type: String, source_command_type: String, unit: Node) -> int:
	var combat_role: String = _get_unit_combat_role(unit)
	match combat_role:
		ROLE_ANCHOR:
			match source_command_type:
				"move":
					return DELAY_ANCHOR_MOVE
				"flank":
					return DELAY_ANCHOR_FLANK
				"take":
					return DELAY_ANCHOR_TAKE
				_:
					if task_type == "hold_position":
						return 0
		ROLE_RECON:
			match source_command_type:
				"defend":
					return DELAY_RECON_DEFEND
				"move", "take":
					return DELAY_RECON_MOVE
				"flank":
					return 0
		ROLE_ASSAULT:
			match source_command_type:
				"defend":
					return DELAY_ASSAULT_DEFEND
				"move":
					return DELAY_ASSAULT_MOVE
				"take", "flank":
					return 0

	return 0


func _get_unit_combat_role(unit: Node) -> String:
	if unit == null or not unit.has_method("get_combat_role"):
		return ROLE_ANCHOR

	var combat_role: String = String(unit.call("get_combat_role"))
	match combat_role:
		ROLE_ANCHOR, ROLE_RECON, ROLE_ASSAULT:
			return combat_role
		_:
			return ROLE_ANCHOR
