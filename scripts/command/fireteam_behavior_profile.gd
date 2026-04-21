class_name FireteamBehaviorProfile
extends RefCounted

const ADVANCE_STYLE_RUSH: String = "rush"
const ADVANCE_STYLE_BOUNDING: String = "bounding"
const ADVANCE_STYLE_CREEP: String = "creep"
const FIRE_DISCIPLINE_HOLD_FIRE: String = "hold_fire"
const FIRE_DISCIPLINE_SEMI_DISCIPLINED: String = "semi_disciplined"
const FIRE_DISCIPLINE_FIRE_AT_WILL: String = "fire_at_will"
const TACTICAL_STANCE_CAUTIOUS: String = "cautious"
const TACTICAL_STANCE_NORMAL: String = "normal"
const TACTICAL_STANCE_AGGRESSIVE: String = "aggressive"
const ALLOWED_ADVANCE_STYLES: PackedStringArray = [
	ADVANCE_STYLE_RUSH,
	ADVANCE_STYLE_BOUNDING,
	ADVANCE_STYLE_CREEP,
]
const ALLOWED_FIRE_DISCIPLINE: PackedStringArray = [
	FIRE_DISCIPLINE_HOLD_FIRE,
	FIRE_DISCIPLINE_SEMI_DISCIPLINED,
	FIRE_DISCIPLINE_FIRE_AT_WILL,
]
const ALLOWED_TACTICAL_STANCES: PackedStringArray = [
	TACTICAL_STANCE_CAUTIOUS,
	TACTICAL_STANCE_NORMAL,
	TACTICAL_STANCE_AGGRESSIVE,
]

var fireteam_id: String = ""
var leader_unit_id: String = ""
var advance_style: String = ADVANCE_STYLE_CREEP
var cover_priority: float = 0.5
var fire_discipline: String = FIRE_DISCIPLINE_SEMI_DISCIPLINED
var cohesion_threshold: float = 100.0
var suppression_threshold: int = 1
var tactical_stance: String = TACTICAL_STANCE_NORMAL
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)


static func from_dict(data: Dictionary) -> FireteamBehaviorProfile:
	var script_ref: GDScript = load("res://scripts/command/fireteam_behavior_profile.gd")
	return script_ref.new(data)


static func is_allowed_advance_style(value: String) -> bool:
	return ALLOWED_ADVANCE_STYLES.has(value)


static func is_allowed_fire_discipline(value: String) -> bool:
	return ALLOWED_FIRE_DISCIPLINE.has(value)


static func is_allowed_tactical_stance(value: String) -> bool:
	return ALLOWED_TACTICAL_STANCES.has(value)


func is_valid() -> bool:
	if fireteam_id.is_empty():
		return false

	if not is_allowed_advance_style(advance_style):
		return false

	if not is_allowed_fire_discipline(fire_discipline):
		return false

	if not is_allowed_tactical_stance(tactical_stance):
		return false

	if cover_priority < 0.0 or cover_priority > 1.0:
		return false

	if cohesion_threshold < 0.0:
		return false

	return suppression_threshold >= 0


func to_dict() -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"leader_unit_id": leader_unit_id,
		"advance_style": advance_style,
		"cover_priority": cover_priority,
		"fire_discipline": fire_discipline,
		"cohesion_threshold": cohesion_threshold,
		"suppression_threshold": suppression_threshold,
		"tactical_stance": tactical_stance,
		"metadata": metadata.duplicate(true),
	}


func _apply_dict(data: Dictionary) -> void:
	fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	leader_unit_id = String(data.get("leader_unit_id", "")).strip_edges()
	advance_style = String(data.get("advance_style", ADVANCE_STYLE_CREEP)).strip_edges().to_lower()
	fire_discipline = String(data.get("fire_discipline", FIRE_DISCIPLINE_SEMI_DISCIPLINED)).strip_edges().to_lower()
	cover_priority = clampf(float(data.get("cover_priority", 0.5)), 0.0, 1.0)
	cohesion_threshold = maxf(float(data.get("cohesion_threshold", 100.0)), 0.0)
	suppression_threshold = maxi(int(data.get("suppression_threshold", 1)), 0)
	tactical_stance = String(data.get("tactical_stance", TACTICAL_STANCE_NORMAL)).strip_edges().to_lower()
	if not is_allowed_tactical_stance(tactical_stance):
		tactical_stance = TACTICAL_STANCE_NORMAL
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)
