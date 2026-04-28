class_name UnitCommand
extends RefCounted

const TYPE_MOVE_TO_POSITION: String = "move_to_position"
const TYPE_HOLD_POSITION: String = "hold_position"
const TYPE_ENGAGE_AREA: String = "engage_area"
const TYPE_RETREAT: String = "retreat"
const TYPE_SEEK_COVER: String = "seek_cover"
const FIRE_STATUS_FIRE_AT_WILL: String = "fire_at_will"
const FIRE_STATUS_HOLD_FIRE: String = "hold_fire"
const ALLOWED_COMMAND_TYPES: PackedStringArray = [
	TYPE_MOVE_TO_POSITION,
	TYPE_HOLD_POSITION,
	TYPE_ENGAGE_AREA,
	TYPE_RETREAT,
	TYPE_SEEK_COVER,
]
const ALLOWED_FIRE_STATUSES: PackedStringArray = [
	FIRE_STATUS_FIRE_AT_WILL,
	FIRE_STATUS_HOLD_FIRE,
]

var command_type: String = ""
var priority: int = 0
var unit_id: String = ""
var team_id: String = ""
var fire_status: String = FIRE_STATUS_FIRE_AT_WILL
var source_command_type: String = ""
var move_speed_factor: float = 1.0
var cover_score: float = 0.0
var attack_bonus: float = 0.0
var target_position: Variant = null
var target_floor_index: int = 0
var target_area_id: String = ""
var source_task_type: String = ""
var command_token: String = ""
var phase: int = -1


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> UnitCommand:
	var script_ref: GDScript = load("res://scripts/npc/unit_command.gd")
	return script_ref.new(data)


static func is_allowed_command_type(value: String) -> bool:
	return ALLOWED_COMMAND_TYPES.has(value)


func is_valid() -> bool:
	if not is_allowed_command_type(command_type):
		return false

	if not ALLOWED_FIRE_STATUSES.has(fire_status):
		return false

	if move_speed_factor < 0.0:
		return false

	if not _has_valid_target_position():
		return false

	if target_floor_index < 0:
		return false

	return true


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"command_type": command_type,
		"priority": priority,
		"unit_id": unit_id,
		"team_id": team_id,
		"fire_status": fire_status,
		"source_command_type": source_command_type,
		"move_speed_factor": move_speed_factor,
		"cover_score": cover_score,
		"attack_bonus": attack_bonus,
	}

	if target_position != null:
		data["target_position"] = target_position
		if target_floor_index != 0:
			data["target_floor_index"] = target_floor_index

	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id

	if not source_task_type.is_empty():
		data["source_task_type"] = source_task_type

	if not command_token.is_empty():
		data["command_token"] = command_token

	if phase >= 0:
		data["phase"] = phase

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("command_type"):
		command_type = String(data["command_type"])

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

	if data.has("source_command_type"):
		source_command_type = String(data["source_command_type"])

	if data.has("move_speed_factor"):
		var raw_move_speed_factor: Variant = data["move_speed_factor"]
		if typeof(raw_move_speed_factor) == TYPE_INT or typeof(raw_move_speed_factor) == TYPE_FLOAT:
			move_speed_factor = float(raw_move_speed_factor)

	if data.has("cover_score"):
		var raw_cover_score: Variant = data["cover_score"]
		if typeof(raw_cover_score) == TYPE_INT or typeof(raw_cover_score) == TYPE_FLOAT:
			cover_score = float(raw_cover_score)

	if data.has("attack_bonus"):
		var raw_attack_bonus: Variant = data["attack_bonus"]
		if typeof(raw_attack_bonus) == TYPE_INT or typeof(raw_attack_bonus) == TYPE_FLOAT:
			attack_bonus = float(raw_attack_bonus)

	if data.has("target_position"):
		target_position = data["target_position"]

	if data.has("target_floor_index"):
		var raw_target_floor_index: Variant = data["target_floor_index"]
		if typeof(raw_target_floor_index) == TYPE_INT or typeof(raw_target_floor_index) == TYPE_FLOAT:
			target_floor_index = int(raw_target_floor_index)

	if data.has("target_area_id"):
		target_area_id = String(data["target_area_id"])

	if data.has("source_task_type"):
		source_task_type = String(data["source_task_type"])

	if data.has("command_token"):
		command_token = String(data["command_token"])

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3
