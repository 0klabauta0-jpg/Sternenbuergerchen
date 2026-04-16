class_name FTLRuntimeStatus
extends RefCounted

const STATUS_IDLE: String = "idle"
const STATUS_SEEKING_COVER: String = "seeking_cover"
const STATUS_MOVING_TO_AREA: String = "moving_to_area"
const STATUS_ENGAGING_IN_AREA: String = "engaging_in_area"
const STATUS_HOLDING_POSITION: String = "holding_position"
const STATUS_RETREATING: String = "retreating"
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_IDLE,
	STATUS_SEEKING_COVER,
	STATUS_MOVING_TO_AREA,
	STATUS_ENGAGING_IN_AREA,
	STATUS_HOLDING_POSITION,
	STATUS_RETREATING,
]

var status: String = STATUS_IDLE
var active_task_type: String = ""
var priority: int = 0
var unit_id: String = ""
var team_id: String = ""
var phase: int = -1


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> FTLRuntimeStatus:
	var script_ref: GDScript = load("res://scripts/ftl/ftl_runtime_status.gd")
	return script_ref.new(data)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	return is_allowed_status(status)


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"status": status,
		"active_task_type": active_task_type,
		"priority": priority,
		"unit_id": unit_id,
		"team_id": team_id,
	}

	if phase >= 0:
		data["phase"] = phase

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("status"):
		status = String(data["status"])

	if data.has("active_task_type"):
		active_task_type = String(data["active_task_type"])

	if data.has("priority"):
		var raw_priority: Variant = data["priority"]
		if typeof(raw_priority) == TYPE_INT or typeof(raw_priority) == TYPE_FLOAT:
			priority = int(raw_priority)

	if data.has("unit_id"):
		unit_id = String(data["unit_id"])

	if data.has("team_id"):
		team_id = String(data["team_id"])

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)
