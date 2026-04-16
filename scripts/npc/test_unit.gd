class_name TestUnit
extends Node2D

const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")
const UNIT_VITAL_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_vital_status.gd")

signal runtime_status_changed(runtime_status)
signal unit_command_assigned(command)
signal damage_applied(amount, health_points, hit_context)
signal vital_status_changed(vital_status)

@export var unit_id: String = "unit_test_001"
@export var display_name: String = "Test Unit"
@export var team_id: String = "team_test"
@export var max_health_points: int = 100

var _runtime_status: RefCounted = UNIT_RUNTIME_STATUS_SCRIPT.new()
var _current_unit_command: RefCounted = null
var _vital_status: RefCounted = UNIT_VITAL_STATUS_SCRIPT.new()
var _last_damage_context: Dictionary = {}


func _ready() -> void:
	_runtime_status = _build_runtime_status("idle")
	_vital_status = _build_vital_status("fit", max_health_points, 0)
	_apply_vital_visual()


func get_unit_id() -> String:
	return unit_id


func get_runtime_status():
	return _runtime_status


func get_current_unit_command():
	return _current_unit_command


func get_health() -> int:
	return int(_vital_status.health_points)


func get_team_id() -> String:
	return team_id


func get_vital_status():
	return _vital_status


func get_vital_state() -> String:
	return String(_vital_status.state)


func get_last_damage_context() -> Dictionary:
	return _last_damage_context.duplicate(true)


func get_target_position():
	return _runtime_status.target_position


func apply_damage(amount: int, hit_context: Dictionary = {}) -> bool:
	if amount <= 0:
		return false

	var next_health: int = maxi(get_health() - amount, 0)
	var next_state: String = String(_vital_status.state)
	if next_health == 0 and next_state == "fit":
		next_state = "down"

	_set_vital_status(next_state, next_health, int(_vital_status.bleedout_ticks))
	_last_damage_context = hit_context.duplicate(true)
	damage_applied.emit(amount, next_health, _last_damage_context)
	return true


func advance_bleedout() -> bool:
	if String(_vital_status.state) != "down":
		return false

	_set_vital_status("bleedout", get_health(), int(_vital_status.bleedout_ticks) + 1)
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


func _build_vital_status(state: String, health_points: int, bleedout_ticks: int):
	var vital_status = UNIT_VITAL_STATUS_SCRIPT.new()
	vital_status.state = state
	vital_status.health_points = health_points
	vital_status.bleedout_ticks = bleedout_ticks
	return vital_status


func _set_vital_status(state: String, health_points: int, bleedout_ticks: int) -> void:
	var vital_status = _build_vital_status(state, health_points, bleedout_ticks)
	if not bool(vital_status.call("is_valid")):
		return

	_vital_status = vital_status
	_apply_vital_visual()
	vital_status_changed.emit(_vital_status)


func _map_unit_command_to_status(command_type: String) -> String:
	match command_type:
		"move_to_position":
			return "pending_move"
		"hold_position":
			return "holding"
		_:
			return "assigned"


func _apply_vital_visual() -> void:
	match String(_vital_status.state):
		"down":
			modulate = Color(1.0, 0.55, 0.55, 0.85)
			rotation_degrees = 28.0
		"bleedout":
			modulate = Color(0.45, 0.45, 0.45, 0.7)
			rotation_degrees = 45.0
		_:
			modulate = Color(1.0, 1.0, 1.0, 1.0)
			rotation_degrees = 0.0
