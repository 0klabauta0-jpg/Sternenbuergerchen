class_name TestUnit
extends Node

const UNIT_RUNTIME_STATUS_SCRIPT: GDScript = preload("res://scripts/npc/unit_runtime_status.gd")

signal runtime_status_changed(runtime_status)

@export var unit_id: String = "unit_test_001"
@export var display_name: String = "Test Unit"
@export var team_id: String = "team_test"

var _runtime_status: RefCounted = UNIT_RUNTIME_STATUS_SCRIPT.new()


func _ready() -> void:
	_runtime_status = _build_runtime_status("idle")


func get_unit_id() -> String:
	return unit_id


func get_runtime_status():
	return _runtime_status


func set_runtime_status(status_name: String, active_command_type: String = "", priority: int = 0, phase: int = -1) -> bool:
	var runtime_status = _build_runtime_status(status_name, active_command_type, priority, phase)
	if not bool(runtime_status.call("is_valid")):
		push_warning("TestUnit.set_runtime_status expects a valid UnitRuntimeStatus-compatible value.")
		return false

	_runtime_status = runtime_status
	runtime_status_changed.emit(_runtime_status)
	return true


func _build_runtime_status(status_name: String, active_command_type: String = "", priority: int = 0, phase: int = -1):
	var runtime_status = UNIT_RUNTIME_STATUS_SCRIPT.new()
	runtime_status.status = status_name
	runtime_status.active_command_type = active_command_type
	runtime_status.priority = priority
	runtime_status.unit_id = unit_id
	runtime_status.team_id = team_id
	runtime_status.phase = phase
	return runtime_status
