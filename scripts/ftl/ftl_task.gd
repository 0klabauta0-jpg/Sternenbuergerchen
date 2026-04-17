class_name FTLTask
extends RefCounted

const TYPE_SEEK_COVER: String = "seek_cover"
const TYPE_MOVE_TO_AREA: String = "move_to_area"
const TYPE_ENGAGE_IN_AREA: String = "engage_in_area"
const TYPE_HOLD_POSITION: String = "hold_position"
const TYPE_RETREAT: String = "retreat"
const ALLOWED_TASK_TYPES: PackedStringArray = [
	TYPE_SEEK_COVER,
	TYPE_MOVE_TO_AREA,
	TYPE_ENGAGE_IN_AREA,
	TYPE_HOLD_POSITION,
	TYPE_RETREAT,
]

var task_type: String = ""
var priority: int = 0
var unit_id: String = ""
var team_id: String = ""
var target_position: Variant = null
var target_area_id: String = ""
var source_command_type: String = ""
var phase: int = -1


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> FTLTask:
	var script_ref: GDScript = load("res://scripts/ftl/ftl_task.gd")
	return script_ref.new(data)


static func is_allowed_task_type(value: String) -> bool:
	return ALLOWED_TASK_TYPES.has(value)


# This validates only the lightweight data contract, not execution semantics.
func is_valid() -> bool:
	if not is_allowed_task_type(task_type):
		return false

	if not _has_valid_target_position():
		return false

	return true


# The task stays dictionary-friendly so later runtime systems can consume plain data.
func to_dict() -> Dictionary:
	var data: Dictionary = {
		"task_type": task_type,
		"priority": priority,
		"unit_id": unit_id,
		"team_id": team_id,
	}

	if target_position != null:
		data["target_position"] = target_position

	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id

	if not source_command_type.is_empty():
		data["source_command_type"] = source_command_type

	if phase >= 0:
		data["phase"] = phase

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("task_type"):
		task_type = String(data["task_type"])

	if data.has("priority"):
		var raw_priority: Variant = data["priority"]
		if typeof(raw_priority) == TYPE_INT or typeof(raw_priority) == TYPE_FLOAT:
			priority = int(raw_priority)

	if data.has("unit_id"):
		unit_id = String(data["unit_id"])

	if data.has("team_id"):
		team_id = String(data["team_id"])

	if data.has("target_position"):
		target_position = data["target_position"]

	if data.has("target_area_id"):
		target_area_id = String(data["target_area_id"])

	if data.has("source_command_type"):
		source_command_type = String(data["source_command_type"])

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3