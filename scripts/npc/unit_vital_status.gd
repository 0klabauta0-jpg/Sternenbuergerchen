class_name UnitVitalStatus
extends RefCounted

const STATE_FIT: String = "fit"
const STATE_DOWN: String = "down"
const STATE_BLEEDOUT: String = "bleedout"
const STATE_RESPAWNING: String = "respawning"
const ALLOWED_STATES: PackedStringArray = [
	STATE_FIT,
	STATE_DOWN,
	STATE_BLEEDOUT,
	STATE_RESPAWNING,
]

var state: String = STATE_FIT
var health_points: int = 100
var bleedout_ticks: int = 0


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> UnitVitalStatus:
	var script_ref: GDScript = load("res://scripts/npc/unit_vital_status.gd")
	return script_ref.new(data)


static func is_allowed_state(value: String) -> bool:
	return ALLOWED_STATES.has(value)


func is_valid() -> bool:
	return is_allowed_state(state) and health_points >= 0 and bleedout_ticks >= 0


func to_dict() -> Dictionary:
	return {
		"state": state,
		"health_points": health_points,
		"bleedout_ticks": bleedout_ticks,
	}


func _apply_dict(data: Dictionary) -> void:
	if data.has("state"):
		state = String(data["state"])

	if data.has("health_points"):
		var raw_health: Variant = data["health_points"]
		if typeof(raw_health) == TYPE_INT or typeof(raw_health) == TYPE_FLOAT:
			health_points = int(raw_health)

	if data.has("bleedout_ticks"):
		var raw_ticks: Variant = data["bleedout_ticks"]
		if typeof(raw_ticks) == TYPE_INT or typeof(raw_ticks) == TYPE_FLOAT:
			bleedout_ticks = int(raw_ticks)
