class_name CommanderOrderIntent
extends RefCounted

const COMMAND_MOVE: String = "move"
const COMMAND_DEFEND: String = "defend"
const COMMAND_FLANK: String = "flank"
const COMMAND_TAKE: String = "take"
const COMMAND_ENGAGE: String = "engage"
const COMMAND_HOLD: String = "hold"
const ALLOWED_COMMAND_TYPES: PackedStringArray = [
	COMMAND_MOVE,
	COMMAND_DEFEND,
	COMMAND_FLANK,
	COMMAND_TAKE,
	COMMAND_ENGAGE,
	COMMAND_HOLD,
]
const ALLOWED_ENTRY_SOURCES: PackedStringArray = [
	"button",
	"hotkey",
	"rmb",
	"go",
	"compatibility",
	"public_world_waypoint",
]

var command_type: String = COMMAND_MOVE
var selected_fireteam_ids: PackedStringArray = PackedStringArray()
var target_position: Variant = null
var target_area_id: String = ""
var phase: int = -1
var source_peer_id: int = 1
var entry_source: String = ""
var plan_id: String = ""
var command_token: String = ""
var team_id: String = ""
var plan_revision: int = 0
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)
	_normalize()


static func from_dict(data: Dictionary) -> CommanderOrderIntent:
	var script_ref: GDScript = load("res://scripts/mission/commander_order_intent.gd")
	return script_ref.new(data)


static func is_allowed_command_type(value: String) -> bool:
	return ALLOWED_COMMAND_TYPES.has(value.strip_edges().to_lower())


static func is_allowed_entry_source(value: String) -> bool:
	return ALLOWED_ENTRY_SOURCES.has(value.strip_edges().to_lower())


func is_valid() -> bool:
	if not is_allowed_command_type(command_type):
		return false
	if selected_fireteam_ids.is_empty():
		return false
	if not _has_valid_target_position():
		return false
	if command_type != COMMAND_HOLD and target_position == null and target_area_id.is_empty():
		return false
	if phase < -1 or source_peer_id <= 0 or plan_revision < 0:
		return false
	if not entry_source.is_empty() and not is_allowed_entry_source(entry_source):
		return false
	return not plan_id.is_empty()


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"command_type": command_type,
		"selected_fireteam_ids": PackedStringArray(selected_fireteam_ids),
		"phase": phase,
		"source_peer_id": source_peer_id,
		"entry_source": entry_source,
		"plan_id": plan_id,
		"plan_revision": plan_revision,
		"metadata": metadata.duplicate(true),
	}
	if target_position != null:
		data["target_position"] = target_position
	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id
	if not command_token.is_empty():
		data["command_token"] = command_token
	if not team_id.is_empty():
		data["team_id"] = team_id
	return data


func with_command_token(next_command_token: String) -> CommanderOrderIntent:
	var next_data: Dictionary = to_dict()
	next_data["command_token"] = next_command_token
	return from_dict(next_data)


func _apply_dict(data: Dictionary) -> void:
	command_type = String(data.get("command_type", data.get("verb", data.get("type", COMMAND_MOVE))))
	selected_fireteam_ids = _normalize_fireteam_ids(data.get("selected_fireteam_ids", data.get("coordinated_fireteam_ids", [data.get("fireteam_id", "")])))
	target_position = data.get("target_position", null)
	target_area_id = String(data.get("target_area_id", ""))
	phase = int(data.get("phase", -1))
	source_peer_id = int(data.get("source_peer_id", data.get("peer_id", 1)))
	entry_source = String(data.get("entry_source", ""))
	plan_id = String(data.get("plan_id", ""))
	command_token = String(data.get("command_token", ""))
	team_id = String(data.get("team_id", ""))
	plan_revision = int(data.get("plan_revision", 0))
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)


func _normalize() -> void:
	command_type = command_type.strip_edges().to_lower()
	selected_fireteam_ids = _normalize_fireteam_ids(selected_fireteam_ids)
	target_area_id = target_area_id.strip_edges()
	entry_source = entry_source.strip_edges().to_lower()
	plan_id = plan_id.strip_edges()
	command_token = command_token.strip_edges()
	team_id = team_id.strip_edges()


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true
	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3


static func _normalize_fireteam_ids(values: Variant) -> PackedStringArray:
	var normalized: PackedStringArray = PackedStringArray()
	for value in Array(values):
		var fireteam_id: String = String(value).strip_edges().to_lower()
		if fireteam_id.is_empty() or normalized.has(fireteam_id):
			continue
		normalized.append(fireteam_id)
	return normalized
