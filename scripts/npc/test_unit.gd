class_name TestUnit
extends Node2D

const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")

signal runtime_status_changed(runtime_status)
signal unit_command_assigned(command)
signal damage_applied(amount, health_points, hit_context)

@export var unit_id: String = "unit_test_001"
@export var display_name: String = "Test Unit"
@export var team_id: String = "team_test"
@export var max_health_points: int = 100

var _runtime_status: RefCounted = UNIT_RUNTIME_STATUS_SCRIPT.new()
var _current_unit_command: RefCounted = null
var _health_points: int = max_health_points
var _last_damage_context: Dictionary = {}


func _ready() -> void:
	_runtime_status = _build_runtime_status("idle")
	_health_points = max_health_points


func get_unit_id() -> String:
	return unit_id


func get_runtime_status():
	return _runtime_status


func get_current_unit_command():
	return _current_unit_command


func get_health() -> int:
	return _health_points


func get_last_damage_context() -> Dictionary:
	return _last_damage_context.duplicate(true)


func get_target_position():
	return _runtime_status.target_position


func apply_damage(amount: int, hit_context: Dictionary = {}) -> bool:
	if amount <= 0:
		return false

	_health_points = maxi(_health_points - amount, 0)
	_last_damage_context = hit_context.duplicate(true)
	damage_applied.emit(amount, _health_points, _last_damage_context)
	return true


func set_target_position(target_position: Variant) -> bool:
	return set_runtime_status(
		String(_runtime_status.status),
		String(_runtime_status.active_command_type),
		int(_runtime_status.priority),
		int(_runtime_status.phase),
		target_position
	)


func assign_unit_command(command) -> bool:
	if command == null or not command.has_method("is_valid") or not bool(command.call("is_valid")):
		push_warning("TestUnit.assign_unit_command expects a valid UnitCommand-like object.")
		return false

	_current_unit_command = command

	var status_name: String = _map_unit_command_to_status(String(command.get("command_type")))
	if not set_runtime_status(
		status_name,
		String(command.get("command_type")),
		int(command.get("priority")),
		int(command.get("phase")),
		command.get("target_position")
	):
		return false

	unit_command_assigned.emit(command)
	return true


func set_runtime_status(
	status_name: String,
	active_command_type: String = "",
	priority: int = 0,
	phase: int = -1,
	target_position: Variant = null
) -> bool:
	var runtime_status = _build_runtime_status(status_name, active_command_type, priority, phase, target_position)
	if not bool(runtime_status.call("is_valid")):
		push_warning("TestUnit.set_runtime_status expects a valid UnitRuntimeStatus-compatible value.")
		return false

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)
	return true


func _build_runtime_status(
	status_name: String,
	active_command_type: String = "",
	priority: int = 0,
	phase: int = -1,
	target_position: Variant = null
):
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new()
	runtime_status.status = status_name
	runtime_status.active_command_type = active_command_type
	runtime_status.priority = priority
	runtime_status.unit_id = unit_id
	runtime_status.team_id = team_id
	runtime_status.target_position = target_position
	runtime_status.phase = phase
	return runtime_status


func _map_unit_command_to_status(command_type: String) -> String:
	match command_type:
		"move_to_position":
			return "pending_move"
		"hold_position":
			return "holding"
		_:
			return "assigned"
