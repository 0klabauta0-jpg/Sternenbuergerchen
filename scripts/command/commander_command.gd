class_name CommanderCommand
extends RefCounted

const TYPE_MOVE: String = "move"
const TYPE_ENGAGE: String = "engage"
const TYPE_TAKE: String = "take"
const TYPE_DEFEND: String = "defend"
const TYPE_FLANK: String = "flank"
const PHASE_APPROACH: int = 0
const PHASE_ASSAULT: int = 1
const PHASE_HOLD: int = 2
const ALLOWED_COMMAND_TYPES: PackedStringArray = [
	TYPE_MOVE,
	TYPE_ENGAGE,
	TYPE_TAKE,
	TYPE_DEFEND,
	TYPE_FLANK,
]
const ALLOWED_PHASES: PackedInt32Array = [
	PHASE_APPROACH,
	PHASE_ASSAULT,
	PHASE_HOLD,
]

var command_type: String = ""
var priority: int = 0
var unit_id: String = ""
var team_id: String = ""
var target_position: Variant = null
var target_floor_index: int = 0
var phase: int = -1


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> CommanderCommand:
	var script_ref: GDScript = load("res://scripts/command/commander_command.gd")
	return script_ref.new(data)


static func is_allowed_command_type(value: String) -> bool:
	return ALLOWED_COMMAND_TYPES.has(value)


static func is_allowed_phase(value: int) -> bool:
	return value >= 0


static func get_phase_name(value: int) -> String:
	match value:
		PHASE_APPROACH:
			return "APPROACH"
		PHASE_ASSAULT:
			return "ASSAULT"
		PHASE_HOLD:
			return "HOLD"
		_:
			return "PHASE %d" % value


static func get_phase_short_name(value: int) -> String:
	match value:
		PHASE_APPROACH:
			return "APR"
		PHASE_ASSAULT:
			return "ASS"
		PHASE_HOLD:
			return "HLD"
		_:
			return "P%d" % value


# This validates only the lightweight data contract, not gameplay semantics.
func is_valid() -> bool:
	if not is_allowed_command_type(command_type):
		return false

	if phase >= 0 and not is_allowed_phase(phase):
		return false

	if not _has_valid_target_position():
		return false

	if target_floor_index < 0:
		return false

	return true


# Existing runtime systems still consume loose dictionaries with the "type" key.
func to_dict() -> Dictionary:
	var data: Dictionary = {
		"type": command_type,
		"priority": priority,
		"unit_id": unit_id,
		"team_id": team_id,
	}

	if target_position != null:
		data["target_position"] = target_position
		if target_floor_index != 0:
			data["target_floor_index"] = target_floor_index

	if phase >= 0:
		data["phase"] = phase

	return data


func _apply_dict(data: Dictionary) -> void:
	if data.has("command_type"):
		command_type = String(data["command_type"])
	elif data.has("type"):
		command_type = String(data["type"])

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

	if data.has("target_floor_index"):
		var raw_target_floor_index: Variant = data["target_floor_index"]
		if typeof(raw_target_floor_index) == TYPE_INT or typeof(raw_target_floor_index) == TYPE_FLOAT:
			target_floor_index = int(raw_target_floor_index)

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3
