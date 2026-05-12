class_name UnitRuntimeStatus
extends RefCounted

const STATUS_IDLE: String = "idle"
const STATUS_ASSIGNED: String = "assigned"
const STATUS_PENDING_MOVE: String = "pending_move"
const STATUS_ENGAGING: String = "engaging"
const STATUS_HOLDING: String = "holding"
const FIRE_STATUS_FIRE_AT_WILL: String = "fire_at_will"
const FIRE_STATUS_HOLD_FIRE: String = "hold_fire"
const FIRE_STATUS_SEMI_DISCIPLINED: String = "semi_disciplined"
const MOVEMENT_POSTURE_IDLE: String = "idle"
const MOVEMENT_POSTURE_TRAVEL: String = "travel"
const MOVEMENT_POSTURE_TACTICAL: String = "tactical"
const MOVEMENT_POSTURE_ENGAGE: String = "engage"
const MOVEMENT_POSTURE_OVERWATCH: String = "overwatch"
const WEAPON_POSTURE_LOWERED: String = "lowered"
const WEAPON_POSTURE_READY: String = "ready"
const WEAPON_POSTURE_AIMED: String = "aimed"
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
	FIRE_STATUS_SEMI_DISCIPLINED,
]
const ALLOWED_MOVEMENT_POSTURES: PackedStringArray = [
	MOVEMENT_POSTURE_IDLE,
	MOVEMENT_POSTURE_TRAVEL,
	MOVEMENT_POSTURE_TACTICAL,
	MOVEMENT_POSTURE_ENGAGE,
	MOVEMENT_POSTURE_OVERWATCH,
]
const ALLOWED_WEAPON_POSTURES: PackedStringArray = [
	WEAPON_POSTURE_LOWERED,
	WEAPON_POSTURE_READY,
	WEAPON_POSTURE_AIMED,
]

var status: String = STATUS_IDLE
var active_command_type: String = ""
var priority: int = 0
var unit_id: String = ""
var team_id: String = ""
var fireteam_id: String = ""
var fire_status: String = FIRE_STATUS_FIRE_AT_WILL
var source_command_type: String = ""
var move_speed_factor: float = 1.0
var cover_score: float = 0.0
var attack_bonus: float = 0.0
var target_position: Variant = null
var phase: int = -1
var movement_posture: String = MOVEMENT_POSTURE_IDLE
var weapon_posture: String = WEAPON_POSTURE_LOWERED
var posture_policy_id: String = ""


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> UnitRuntimeStatus:
	var script_ref: GDScript = load("res://scripts/npc/unit_runtime_status.gd")
	return script_ref.new(data)


static func is_allowed_status(value: String) -> bool:
	return ALLOWED_STATUSES.has(value)


static func is_allowed_movement_posture(value: String) -> bool:
	return ALLOWED_MOVEMENT_POSTURES.has(value)


static func is_allowed_weapon_posture(value: String) -> bool:
	return ALLOWED_WEAPON_POSTURES.has(value)


func is_valid() -> bool:
	if not is_allowed_status(status):
		return false

	if not ALLOWED_FIRE_STATUSES.has(fire_status):
		return false

	if not is_allowed_movement_posture(movement_posture):
		return false

	if not is_allowed_weapon_posture(weapon_posture):
		return false

	if move_speed_factor < 0.0:
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
		"source_command_type": source_command_type,
		"move_speed_factor": move_speed_factor,
		"cover_score": cover_score,
		"attack_bonus": attack_bonus,
		"movement_posture": movement_posture,
		"weapon_posture": weapon_posture,
		"posture_policy_id": posture_policy_id,
	}

	if target_position != null:
		data["target_position"] = target_position

	if phase >= 0:
		data["phase"] = phase

	if not fireteam_id.is_empty():
		data["fireteam_id"] = fireteam_id

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

	if data.has("fireteam_id"):
		fireteam_id = String(data["fireteam_id"])

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

	if data.has("phase"):
		var raw_phase: Variant = data["phase"]
		if typeof(raw_phase) == TYPE_INT or typeof(raw_phase) == TYPE_FLOAT:
			phase = int(raw_phase)

	if data.has("movement_posture"):
		movement_posture = normalize_movement_posture(data["movement_posture"], MOVEMENT_POSTURE_IDLE)

	if data.has("weapon_posture"):
		weapon_posture = normalize_weapon_posture(data["weapon_posture"], WEAPON_POSTURE_LOWERED)

	if data.has("posture_policy_id"):
		posture_policy_id = String(data["posture_policy_id"]).strip_edges().to_lower()


static func normalize_movement_posture(value: Variant, fallback: String = MOVEMENT_POSTURE_IDLE) -> String:
	var normalized: String = String(value).strip_edges().to_lower()
	match normalized:
		"", "default":
			return fallback if ALLOWED_MOVEMENT_POSTURES.has(fallback) else MOVEMENT_POSTURE_IDLE
		"walk", "march", "move", "travel":
			return MOVEMENT_POSTURE_TRAVEL
		"m_position", "m-position", "ready", "tactical":
			return MOVEMENT_POSTURE_TACTICAL
		"aim", "aimed", "engage", "engaging":
			return MOVEMENT_POSTURE_ENGAGE
		"watch", "hold", "overwatch":
			return MOVEMENT_POSTURE_OVERWATCH
		_:
			return fallback if ALLOWED_MOVEMENT_POSTURES.has(fallback) else MOVEMENT_POSTURE_IDLE


static func normalize_weapon_posture(value: Variant, fallback: String = WEAPON_POSTURE_LOWERED) -> String:
	var normalized: String = String(value).strip_edges().to_lower()
	match normalized:
		"", "default":
			return fallback if ALLOWED_WEAPON_POSTURES.has(fallback) else WEAPON_POSTURE_LOWERED
		"down", "low", "lowered", "safe":
			return WEAPON_POSTURE_LOWERED
		"ready", "ready_low", "ready-low", "m_position", "m-position":
			return WEAPON_POSTURE_READY
		"aim", "aimed", "firing", "shooting":
			return WEAPON_POSTURE_AIMED
		_:
			return fallback if ALLOWED_WEAPON_POSTURES.has(fallback) else WEAPON_POSTURE_LOWERED


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true

	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3
