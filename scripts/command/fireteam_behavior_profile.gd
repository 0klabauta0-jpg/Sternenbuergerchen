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
var order_fidelity: float = 0.65
var reaction_delay_seconds: float = 0.25
var execution_cohesion: float = 0.65
var execution_fire_discipline: float = 0.65
var contact_stability: float = 0.65
var initiative: float = 0.5
var execution_label: String = "STEADY"
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

	if order_fidelity < 0.0 or order_fidelity > 1.0:
		return false

	if reaction_delay_seconds < 0.0:
		return false

	if execution_cohesion < 0.0 or execution_cohesion > 1.0:
		return false

	if execution_fire_discipline < 0.0 or execution_fire_discipline > 1.0:
		return false

	if contact_stability < 0.0 or contact_stability > 1.0:
		return false

	if initiative < 0.0 or initiative > 1.0:
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
		"order_fidelity": order_fidelity,
		"reaction_delay_seconds": reaction_delay_seconds,
		"execution_cohesion": execution_cohesion,
		"execution_fire_discipline": execution_fire_discipline,
		"contact_stability": contact_stability,
		"initiative": initiative,
		"execution_label": execution_label,
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
	order_fidelity = clampf(float(data.get("order_fidelity", 0.65)), 0.0, 1.0)
	reaction_delay_seconds = maxf(float(data.get("reaction_delay_seconds", 0.25)), 0.0)
	execution_cohesion = clampf(float(data.get("execution_cohesion", 0.65)), 0.0, 1.0)
	execution_fire_discipline = clampf(float(data.get("execution_fire_discipline", 0.65)), 0.0, 1.0)
	contact_stability = clampf(float(data.get("contact_stability", 0.65)), 0.0, 1.0)
	initiative = clampf(float(data.get("initiative", 0.5)), 0.0, 1.0)
	execution_label = String(data.get("execution_label", "STEADY")).strip_edges().to_upper()
	if execution_label.is_empty():
		execution_label = "STEADY"
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)
