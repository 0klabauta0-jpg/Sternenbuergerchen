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

## Creates a validated detached medical model; the authoritative mission
## transaction must verify actor identity before publishing it.
static func prepare_checkpoint_value(data: Dictionary, max_health: int) -> Dictionary:
	if max_health <= 0 or data.size() != 3 or not data.has_all(["state", "health_points", "bleedout_ticks"]) or typeof(data.state) != TYPE_STRING or not is_allowed_state(data.state):
		return {"ok":false, "reason":"invalid_vital_checkpoint"}
	for key in ["health_points", "bleedout_ticks"]:
		var value: Variant = data[key]
		if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)) or floor(float(value)) != float(value) or float(value) < 0 or float(value) > 1000000000.0:
			return {"ok":false, "reason":"invalid_vital_checkpoint"}
	if int(data.health_points) > max_health: return {"ok":false, "reason":"invalid_vital_checkpoint"}
	var candidate := from_dict(data)
	if not candidate.is_valid(): return {"ok":false, "reason":"invalid_vital_checkpoint"}
	return {"ok":true, "model":candidate}
