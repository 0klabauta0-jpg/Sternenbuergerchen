class_name TacticalCommandRules
extends RefCounted

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")

const TEMPO_CAUTIOUS: String = "cautious"
const TEMPO_NORMAL: String = "normal"
const TEMPO_RAPID: String = "rapid"

const FIRE_RULE_HOLD: String = "hold"
const FIRE_RULE_RETURN: String = "return"
const FIRE_RULE_FREE: String = "free"
const FIRE_RULE_SUPPRESS: String = "suppress"

const CONTACT_AVOID: String = "avoid"
const CONTACT_REPORT: String = "report"
const CONTACT_FIX: String = "fix"
const CONTACT_ASSAULT: String = "assault"
const CONTACT_WITHDRAW: String = "withdraw"

const COVER_LOW: String = "low"
const COVER_NORMAL: String = "normal"
const COVER_HIGH: String = "high"

const SECURITY_360: String = "360"
const SECURITY_FACING: String = "facing"
const SECURITY_SECTOR: String = "sector"
const SECURITY_NONE_IN_TRANSIT: String = "none_in_transit"

const ALLOWED_TEMPOS: PackedStringArray = [
	TEMPO_CAUTIOUS,
	TEMPO_NORMAL,
	TEMPO_RAPID,
]
const ALLOWED_FIRE_RULES: PackedStringArray = [
	FIRE_RULE_HOLD,
	FIRE_RULE_RETURN,
	FIRE_RULE_FREE,
	FIRE_RULE_SUPPRESS,
]
const ALLOWED_CONTACT_RESPONSES: PackedStringArray = [
	CONTACT_AVOID,
	CONTACT_REPORT,
	CONTACT_FIX,
	CONTACT_ASSAULT,
	CONTACT_WITHDRAW,
]
const ALLOWED_COVER_PRIORITIES: PackedStringArray = [
	COVER_LOW,
	COVER_NORMAL,
	COVER_HIGH,
]
const ALLOWED_SECURITY_MODES: PackedStringArray = [
	SECURITY_360,
	SECURITY_FACING,
	SECURITY_SECTOR,
	SECURITY_NONE_IN_TRANSIT,
]

var tempo: String = TEMPO_NORMAL
var fire_rule: String = FIRE_RULE_RETURN
var contact_response: String = CONTACT_REPORT
var cover_priority: String = COVER_NORMAL
var security_mode: String = SECURITY_FACING
var normalized_from_conflict: bool = false
var warnings: PackedStringArray = PackedStringArray()


func _init(data: Dictionary = {}) -> void:
	_apply_dict(data)
	_normalize_conflicts()


static func from_dict(data: Dictionary) -> RefCounted:
	var script_ref: GDScript = load("res://scripts/tactical/tactical_command_rules.gd")
	return script_ref.new(data)


static func get_default_rules() -> Dictionary:
	return from_dict({}).to_dict()


static func get_rule_catalog() -> Dictionary:
	return {
		"tempo": PackedStringArray(ALLOWED_TEMPOS),
		"fire_rule": PackedStringArray(ALLOWED_FIRE_RULES),
		"contact_response": PackedStringArray(ALLOWED_CONTACT_RESPONSES),
		"cover_priority": PackedStringArray(ALLOWED_COVER_PRIORITIES),
		"security_mode": PackedStringArray(ALLOWED_SECURITY_MODES),
	}


static func get_help_ids() -> PackedStringArray:
	return PackedStringArray([
		"mission.rule.tempo",
		"mission.rule.tempo_cautious",
		"mission.rule.tempo_normal",
		"mission.rule.tempo_rapid",
		"mission.rule.fire_rule",
		"mission.rule.fire_rule_hold",
		"mission.rule.fire_rule_return",
		"mission.rule.fire_rule_free",
		"mission.rule.fire_rule_suppress",
		"mission.rule.contact_response",
		"mission.rule.cover_priority",
		"mission.rule.security_mode",
		"mission.command.roe_fire_rules",
	])


static func normalize_dict(data: Dictionary) -> Dictionary:
	return from_dict(data).to_dict()


static func is_allowed_tempo(value: String) -> bool:
	return ALLOWED_TEMPOS.has(value.strip_edges().to_lower())


static func is_allowed_fire_rule(value: String) -> bool:
	return ALLOWED_FIRE_RULES.has(value.strip_edges().to_lower())


static func is_allowed_contact_response(value: String) -> bool:
	return ALLOWED_CONTACT_RESPONSES.has(value.strip_edges().to_lower())


static func is_allowed_cover_priority(value: String) -> bool:
	return ALLOWED_COVER_PRIORITIES.has(value.strip_edges().to_lower())


static func is_allowed_security_mode(value: String) -> bool:
	return ALLOWED_SECURITY_MODES.has(_normalize_security_mode(value))


func is_valid() -> bool:
	return is_allowed_tempo(tempo) \
		and is_allowed_fire_rule(fire_rule) \
		and is_allowed_contact_response(contact_response) \
		and is_allowed_cover_priority(cover_priority) \
		and is_allowed_security_mode(security_mode)


func to_dict() -> Dictionary:
	return {
		"tempo": tempo,
		"fire_rule": fire_rule,
		"contact_response": contact_response,
		"cover_priority": cover_priority,
		"security_mode": security_mode,
		"normalized_from_conflict": normalized_from_conflict,
		"warnings": PackedStringArray(warnings),
	}


func to_intent_payload(base_payload: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = base_payload.duplicate(true)
	payload["tempo"] = tempo
	payload["fire_rule"] = fire_rule
	payload["contact_response"] = contact_response
	payload["cover_priority"] = cover_priority
	payload["security_mode"] = security_mode
	payload["tactical_rules"] = to_dict()
	var metadata: Dictionary = Dictionary(payload.get("metadata", {})).duplicate(true)
	metadata["tactical_rules"] = to_dict()
	payload["metadata"] = metadata
	return payload


func to_plan_overrides() -> Dictionary:
	return {
		"security_mode": _to_plan_security_mode(),
		"cover_priority": _to_plan_cover_priority(),
		"tactical_rules": to_dict(),
	}


func get_feedback_snapshot() -> Dictionary:
	var summary: String = "TMP %s | FIRE %s | CNT %s | COV %s | SEC %s" % [
		tempo.to_upper(),
		fire_rule.to_upper(),
		contact_response.to_upper(),
		cover_priority.to_upper(),
		security_mode.to_upper(),
	]
	var strong_map_status: String = ""
	if fire_rule == FIRE_RULE_SUPPRESS:
		strong_map_status = "SUPPRESS"
	elif contact_response == CONTACT_AVOID:
		strong_map_status = "AVOID"
	elif contact_response == CONTACT_WITHDRAW:
		strong_map_status = "WITHDRAW"
	elif security_mode == SECURITY_360:
		strong_map_status = "360"
	return {
		"rule_summary": summary,
		"selected_fireteam_text": summary,
		"mission_control_text": _build_mission_control_text(),
		"map_status": strong_map_status,
		"bubble_status": _build_bubble_status(),
		"help_ids": get_help_ids(),
		"warnings": PackedStringArray(warnings),
		"ui_sets_unit_truth": false,
	}


func _apply_dict(data: Dictionary) -> void:
	tempo = _normalize_value(String(data.get("tempo", TEMPO_NORMAL)), ALLOWED_TEMPOS, TEMPO_NORMAL)
	fire_rule = _normalize_value(String(data.get("fire_rule", data.get("fire_status", FIRE_RULE_RETURN))), ALLOWED_FIRE_RULES, FIRE_RULE_RETURN)
	contact_response = _normalize_value(String(data.get("contact_response", CONTACT_REPORT)), ALLOWED_CONTACT_RESPONSES, CONTACT_REPORT)
	cover_priority = _normalize_value(String(data.get("cover_priority", data.get("cover_rule", COVER_NORMAL))), ALLOWED_COVER_PRIORITIES, COVER_NORMAL)
	security_mode = _normalize_security_mode(String(data.get("security_mode", SECURITY_FACING)))
	if not ALLOWED_SECURITY_MODES.has(security_mode):
		security_mode = SECURITY_FACING
	warnings = PackedStringArray()
	normalized_from_conflict = false


func _normalize_conflicts() -> void:
	if contact_response == CONTACT_AVOID and (fire_rule == FIRE_RULE_FREE or fire_rule == FIRE_RULE_SUPPRESS):
		fire_rule = FIRE_RULE_HOLD
		_record_warning("conflict:avoid_contact_fire_rule:fire_rule_hold")
	if contact_response == CONTACT_WITHDRAW and fire_rule == FIRE_RULE_SUPPRESS:
		fire_rule = FIRE_RULE_RETURN
		_record_warning("conflict:withdraw_suppress:fire_rule_return")
	if tempo == TEMPO_RAPID and security_mode == SECURITY_360:
		security_mode = SECURITY_FACING
		_record_warning("conflict:rapid_360_security:security_facing")
	if contact_response == CONTACT_ASSAULT and fire_rule == FIRE_RULE_HOLD:
		contact_response = CONTACT_FIX
		_record_warning("conflict:assault_hold_fire:contact_fix")


func _record_warning(warning_id: String) -> void:
	if warnings.has(warning_id):
		return
	warnings.append(warning_id)
	normalized_from_conflict = true


func _to_plan_security_mode() -> String:
	match security_mode:
		SECURITY_360:
			return "all_round"
		SECURITY_NONE_IN_TRANSIT:
			return "none_in_transit"
		_:
			return security_mode


func _to_plan_cover_priority() -> float:
	match cover_priority:
		COVER_LOW:
			return 0.32
		COVER_HIGH:
			return 0.76
		_:
			return 0.55


func _build_mission_control_text() -> String:
	if warnings.is_empty():
		return "Rules set: %s/%s/%s" % [tempo, fire_rule, contact_response]
	return "Rules normalized: %s" % String(warnings[0])


func _build_bubble_status() -> String:
	if normalized_from_conflict:
		return "rules adjusted"
	if fire_rule == FIRE_RULE_SUPPRESS:
		return "suppress ready"
	if contact_response == CONTACT_AVOID:
		return "avoid contact"
	return "rules copy"


static func _normalize_value(value: String, allowed_values: PackedStringArray, fallback: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	if allowed_values.has(normalized):
		return normalized
	return fallback


static func _normalize_security_mode(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower().replace("-", "_")
	match normalized:
		"all_round", "allround", "360":
			return SECURITY_360
		"directional":
			return SECURITY_FACING
		"none_in_transit", "noneintransit":
			return SECURITY_NONE_IN_TRANSIT
		_:
			return normalized
