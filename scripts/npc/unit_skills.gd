class_name UnitSkills
extends RefCounted

const DEFAULT_ACCURACY: float = 0.5
const DEFAULT_SPEED: float = 0.5
const DEFAULT_LEADERSHIP: float = 0.3
const DEFAULT_TOUGHNESS: float = 0.5

var accuracy: float = DEFAULT_ACCURACY
var speed: float = DEFAULT_SPEED
var leadership: float = DEFAULT_LEADERSHIP
var toughness: float = DEFAULT_TOUGHNESS


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary):
	var script_ref: GDScript = load("res://scripts/npc/unit_skills.gd")
	return script_ref.new(data)


func is_valid() -> bool:
	return _is_skill_value_valid(accuracy) and _is_skill_value_valid(speed) and _is_skill_value_valid(leadership) and _is_skill_value_valid(toughness)


func to_dict() -> Dictionary:
	return {
		"accuracy": accuracy,
		"speed": speed,
		"leadership": leadership,
		"toughness": toughness,
	}


func duplicate_skills():
	var script_ref: GDScript = load("res://scripts/npc/unit_skills.gd")
	return script_ref.new(to_dict())


func apply_modifier(skill_name: String, amount: float) -> void:
	match skill_name:
		"accuracy":
			accuracy = _clamp_skill_value(accuracy + amount)
		"speed":
			speed = _clamp_skill_value(speed + amount)
		"leadership":
			leadership = _clamp_skill_value(leadership + amount)
		"toughness":
			toughness = _clamp_skill_value(toughness + amount)


func _apply_dict(data: Dictionary) -> void:
	if data.has("accuracy"):
		accuracy = _coerce_skill_value(data["accuracy"], DEFAULT_ACCURACY)

	if data.has("speed"):
		speed = _coerce_skill_value(data["speed"], DEFAULT_SPEED)

	if data.has("leadership"):
		leadership = _coerce_skill_value(data["leadership"], DEFAULT_LEADERSHIP)

	if data.has("toughness"):
		toughness = _coerce_skill_value(data["toughness"], DEFAULT_TOUGHNESS)


func _coerce_skill_value(value: Variant, fallback: float) -> float:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		return _clamp_skill_value(float(value))

	return fallback


func _is_skill_value_valid(value: float) -> bool:
	return value >= 0.0 and value <= 1.0


func _clamp_skill_value(value: float) -> float:
	return clampf(value, 0.0, 1.0)
