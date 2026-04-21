class_name FireteamWaypoint
extends RefCounted

const COMMAND_TYPE_MOVE: String = "move"
const COMMAND_TYPE_DEFEND: String = "defend"
const COMMAND_TYPE_ENGAGE: String = "engage"
const COMMAND_TYPE_FLANK: String = "flank"
const COMMAND_TYPE_TAKE: String = "take"
const STATUS_PENDING: String = "pending"
const STATUS_ACTIVE: String = "active"
const STATUS_COMPLETED: String = "completed"
const STATUS_INTERRUPTED: String = "interrupted"
const STATUS_CANCELLED: String = "cancelled"
const ALLOWED_COMMAND_TYPES: PackedStringArray = [
	COMMAND_TYPE_MOVE,
	COMMAND_TYPE_DEFEND,
	COMMAND_TYPE_ENGAGE,
	COMMAND_TYPE_FLANK,
	COMMAND_TYPE_TAKE,
]
const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_PENDING,
	STATUS_ACTIVE,
	STATUS_COMPLETED,
	STATUS_INTERRUPTED,
	STATUS_CANCELLED,
]

var waypoint_id: String = ""
var command_type: String = COMMAND_TYPE_MOVE
var status: String = STATUS_PENDING
var target_position: Variant = null
var target_area_id: String = ""
var hold_duration_seconds: float = 0.0
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> FireteamWaypoint:
	var script_ref: GDScript = load("res://scripts/command/fireteam_waypoint.gd")
	return script_ref.new(data)


static func is_allowed_command_type(value: String) -> bool:
	return ALLOWED_COMMAND_TYPES.has(value)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


func is_valid() -> bool:
	if not is_allowed_command_type(command_type):
		return false

	if not is_allowed_status(status):
		return false

	if hold_duration_seconds < 0.0:
		return false

	if not _has_valid_target_position():
		return false

	return target_position != null or not target_area_id.is_empty()


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"command_type": command_type,
		"status": status,
		"hold_duration_seconds": hold_duration_seconds,
		"metadata": metadata.duplicate(true),
	}

	if not waypoint_id.is_empty():
		data["waypoint_id"] = waypoint_id

	if target_position != null:
		data["target_position"] = target_position

	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("waypoint_id"):
		waypoint_id = String(data["waypoint_id"]).strip_edges()

	if data.has("command_type"):
		command_type = String(data["command_type"]).strip_edges().to_lower()

	if data.has("status"):
		status = String(data["status"]).strip_edges().to_lower()

	if data.has("target_position"):
		target_position = data["target_position"]

	if data.has("target_area_id"):
		target_area_id = String(data["target_area_id"]).strip_edges()

	if data.has("hold_duration_seconds"):
		var raw_hold_duration: Variant = data["hold_duration_seconds"]
		if typeof(raw_hold_duration) == TYPE_INT or typeof(raw_hold_duration) == TYPE_FLOAT:
			hold_duration_seconds = float(raw_hold_duration)

	metadata = Dictionary(data.get("metadata", {})).duplicate(true)


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3