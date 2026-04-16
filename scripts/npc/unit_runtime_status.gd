class_name UnitRuntimeStatus
extends RefCounted

const STATUS_IDLE: String = "idle"
const STATUS_ASSIGNED: String = "assigned"
const STATUS_PENDING_MOVE: String = "pending_move"
const STATUS_ENGAGING: String = "engaging"
const STATUS_HOLDING: String = "holding"
const FIRE_STATUS_FIRE_AT_WILL: String = "fire_at_will"
const FIRE_STATUS_HOLD_FIRE: String = "hold_fire"
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_IDLE,
	STATUS_ASSIGNED,
	STATUS_PENDING_MOVE,
	STATUS_ENGAGING,
	STATUS_HOLDING,
]
const ALLOWED_FIRE_STATUSES: PackedStringArray = [
	FIRE_STATUS_FIRE_AT_WILL,
	FIRE_STATUS_HOLD_FIRE,
]

var status: String = STATUS_IDLE
var active_command_type: String = ""
var priority: int = 0
var unit_id: String = ""
var team_id: String = ""
var fire_status: String = FIRE_STATUS_FIRE_AT_WILL
var target_position: Variant = null
var phase: int = -1


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> UnitRuntimeStatus:
	var script_ref: GDScript = load("res://scripts/npc/unit_runtime_status.gd")
	return script_ref.new(data)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	if not is_allowed_status(status):
		return false

	if not ALLOWED_FIRE_STATUSES.has(fire_status):
		return false

	return _has_valid_target_position()


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"status": status,
		"active_command_type": active_command_type,
		"priority": priority,
		"unit_id": unit_id,
		"team_id": team_id,
		"fire_status": fire_status,
	}

	if target_position != null:
		data["target_position"] = target_position

	if phase >= 0:
		data["phase"] = phase

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("status"):
		status = String(data["status"])

	if data.has("active_command_type"):
		active_command_type = String(data["active_command_type"])

	if data.has("priority"):
		var raw_priority: Variant = data["priority"]
		if typeof(raw_priority) == TYPE_INT or typeof(raw_priority) == TYPE_FLOAT:
			priority = int(raw_priority)

	if data.has("unit_id"):
		unit_id = String(data["unit_id"])

	if data.has("team_id"):
		team_id = String(data["team_id"])

	if data.has("fire_status"):
		fire_status = String(data["fire_status"])

	if data.has("target_position"):
		target_position = data["target_position"]

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3
