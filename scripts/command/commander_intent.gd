class_name CommanderIntent
extends RefCounted

const VERB_MOVE: String = "move"
const VERB_TAKE: String = "take"
const VERB_DEFEND: String = "defend"
const VERB_ENGAGE: String = "engage"
const VERB_FLANK: String = "flank"
const VERB_SECURE: String = "secure"
const VERB_RECON: String = "recon"
const VERB_WITHDRAW: String = "withdraw"
const VERB_SUPPORT: String = "support"
const VERB_BYPASS: String = "bypass"
const VERB_HOLD: String = "hold"

const TEMPO_CAUTIOUS: String = "cautious"
const TEMPO_NORMAL: String = "normal"
const TEMPO_RAPID: String = "rapid"

const FIRE_RULE_HOLD: String = "hold"
const FIRE_RULE_RETURN: String = "return"
const FIRE_RULE_FREE: String = "free"
const FIRE_RULE_SUPPRESS: String = "suppress"

const CONTACT_RESPONSE_AVOID: String = "avoid"
const CONTACT_RESPONSE_REPORT: String = "report"
const CONTACT_RESPONSE_FIX: String = "fix"
const CONTACT_RESPONSE_ASSAULT: String = "assault"
const CONTACT_RESPONSE_WITHDRAW: String = "withdraw"

const RISK_LOW: String = "low"
const RISK_NORMAL: String = "normal"
const RISK_HIGH: String = "high"

const ALLOWED_VERBS: PackedStringArray = [
	VERB_MOVE,
	VERB_TAKE,
	VERB_DEFEND,
	VERB_ENGAGE,
	VERB_FLANK,
	VERB_SECURE,
	VERB_RECON,
	VERB_WITHDRAW,
	VERB_SUPPORT,
	VERB_BYPASS,
	VERB_HOLD,
]
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
	CONTACT_RESPONSE_AVOID,
	CONTACT_RESPONSE_REPORT,
	CONTACT_RESPONSE_FIX,
	CONTACT_RESPONSE_ASSAULT,
	CONTACT_RESPONSE_WITHDRAW,
]
const ALLOWED_RISK_LEVELS: PackedStringArray = [
	RISK_LOW,
	RISK_NORMAL,
	RISK_HIGH,
]

var command_id: String = ""
var verb: String = VERB_MOVE
var fireteam_id: String = ""
var team_id: String = ""
var target_position: Variant = null
var target_area_id: String = ""
var priority: int = 0
var tempo: String = TEMPO_NORMAL
var fire_rule: String = FIRE_RULE_RETURN
var contact_response: String = CONTACT_RESPONSE_REPORT
var risk: String = RISK_NORMAL
var cover_priority: String = "normal"
var security_mode: String = "facing"
var cover_priority_explicit: bool = false
var security_mode_explicit: bool = false
var sync_group_id: String = ""
var coordinated_fireteam_ids: PackedStringArray = PackedStringArray()
var phase: int = -1
var tactical_rules: Dictionary = {}
var metadata: Dictionary = {}
var normalization_warnings: PackedStringArray = PackedStringArray()

var _direct_unit_id: String = ""


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)
	_finalize_defaults()


static func from_dict(data: Dictionary) -> CommanderIntent:
	var script_ref: GDScript = load("res://scripts/command/commander_intent.gd")
	return script_ref.new(data)


static func from_legacy_command_dict(data: Dictionary) -> CommanderIntent:
	var normalized: Dictionary = {
		"command_id": String(data.get("command_id", data.get("command_token", ""))),
		"verb": String(data.get("command_type", data.get("type", VERB_MOVE))),
		"fireteam_id": String(data.get("fireteam_id", data.get("team_id", ""))),
		"team_id": String(data.get("team_id", "")),
		"target_position": data.get("target_position", null),
		"target_area_id": String(data.get("target_area_id", "")),
		"priority": int(data.get("priority", 0)),
		"phase": int(data.get("phase", -1)),
		"metadata": {
			"legacy_command_type": String(data.get("command_type", data.get("type", ""))),
			"legacy_unit_id_ignored": String(data.get("unit_id", "")),
		},
	}
	return from_dict(normalized)


static func is_allowed_verb(value: String) -> bool:
	return ALLOWED_VERBS.has(value.strip_edges().to_lower())


static func is_allowed_tempo(value: String) -> bool:
	return ALLOWED_TEMPOS.has(value.strip_edges().to_lower())


static func is_allowed_fire_rule(value: String) -> bool:
	return ALLOWED_FIRE_RULES.has(value.strip_edges().to_lower())


static func is_allowed_contact_response(value: String) -> bool:
	return ALLOWED_CONTACT_RESPONSES.has(value.strip_edges().to_lower())


static func is_allowed_risk(value: String) -> bool:
	return ALLOWED_RISK_LEVELS.has(value.strip_edges().to_lower())


func is_valid() -> bool:
	if command_id.is_empty():
		return false
	if fireteam_id.is_empty() and coordinated_fireteam_ids.is_empty():
		return false
	if not is_allowed_verb(verb):
		return false
	if not is_allowed_tempo(tempo):
		return false
	if not is_allowed_fire_rule(fire_rule):
		return false
	if not is_allowed_contact_response(contact_response):
		return false
	if not is_allowed_risk(risk):
		return false
	if phase < -1:
		return false
	if not _has_valid_target_position():
		return false
	if _requires_target() and target_position == null and target_area_id.is_empty():
		return false
	return true


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"command_id": command_id,
		"verb": verb,
		"fireteam_id": fireteam_id,
		"priority": priority,
		"tempo": tempo,
		"fire_rule": fire_rule,
		"contact_response": contact_response,
		"risk": risk,
		"phase": phase,
		"tactical_rules": tactical_rules.duplicate(true),
		"metadata": metadata.duplicate(true),
	}
	if cover_priority_explicit:
		data["cover_priority"] = cover_priority
		data["cover_priority_explicit"] = true
	if security_mode_explicit:
		data["security_mode"] = security_mode
		data["security_mode_explicit"] = true
	if not coordinated_fireteam_ids.is_empty():
		data["coordinated_fireteam_ids"] = PackedStringArray(coordinated_fireteam_ids)
	if not team_id.is_empty():
		data["team_id"] = team_id
	if target_position != null:
		data["target_position"] = target_position
	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id
	if not sync_group_id.is_empty():
		data["sync_group_id"] = sync_group_id
	if not normalization_warnings.is_empty():
		data["normalization_warnings"] = PackedStringArray(normalization_warnings)
	return data


func to_legacy_command_dict() -> Dictionary:
	var data: Dictionary = {
		"type": _to_legacy_command_type(verb),
		"priority": priority,
		"team_id": team_id if not team_id.is_empty() else fireteam_id,
	}
	if target_position != null:
		data["target_position"] = target_position
	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id
	if phase >= 0:
		data["phase"] = phase
	data["intent_command_id"] = command_id
	return data


func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = to_dict()
	snapshot["has_direct_unit_payload"] = not _direct_unit_id.is_empty()
	snapshot["direct_unit_payload_ignored"] = not _direct_unit_id.is_empty()
	snapshot["is_multi_fireteam_intent"] = coordinated_fireteam_ids.size() >= 2
	snapshot["gameplay_truth_owner"] = "SimulationRoot"
	snapshot["ui_sets_unit_truth"] = false
	return snapshot


func _apply_dict(data: Dictionary) -> void:
	var source_metadata: Dictionary = Dictionary(data.get("metadata", {})).duplicate(true)
	metadata = source_metadata
	normalization_warnings = _sanitize_string_array(data.get("normalization_warnings", source_metadata.get("normalization_warnings", [])))
	var raw_verb: String = String(data.get("verb", data.get("command_type", data.get("type", VERB_MOVE))))
	var raw_tempo: String = String(data.get("tempo", TEMPO_NORMAL))
	var raw_fire_rule: String = String(data.get("fire_rule", data.get("fire_status", FIRE_RULE_RETURN)))
	var raw_contact_response: String = String(data.get("contact_response", CONTACT_RESPONSE_REPORT))
	var raw_risk: String = String(data.get("risk", RISK_NORMAL))
	cover_priority_explicit = bool(data.get("cover_priority_explicit", source_metadata.get("cover_priority_explicit", false))) or data.has("cover_priority") or data.has("cover_rule")
	security_mode_explicit = bool(data.get("security_mode_explicit", source_metadata.get("security_mode_explicit", false))) or data.has("security_mode")
	command_id = String(data.get("command_id", "")).strip_edges()
	verb = _normalize_verb(raw_verb)
	fireteam_id = String(data.get("fireteam_id", data.get("team_id", ""))).strip_edges().to_lower()
	team_id = String(data.get("team_id", "")).strip_edges()
	target_position = data.get("target_position", null)
	target_area_id = String(data.get("target_area_id", "")).strip_edges()
	priority = int(data.get("priority", 0))
	tempo = raw_tempo.strip_edges().to_lower()
	fire_rule = _normalize_fire_rule(raw_fire_rule)
	contact_response = raw_contact_response.strip_edges().to_lower()
	risk = raw_risk.strip_edges().to_lower()
	cover_priority = String(data.get("cover_priority", data.get("cover_rule", "normal"))).strip_edges().to_lower()
	security_mode = String(data.get("security_mode", "facing")).strip_edges().to_lower()
	sync_group_id = String(data.get("sync_group_id", "")).strip_edges()
	coordinated_fireteam_ids = _sanitize_fireteam_id_array(data.get("coordinated_fireteam_ids", data.get("fireteam_ids", [])))
	phase = int(data.get("phase", -1))
	tactical_rules = Dictionary(data.get("tactical_rules", {})).duplicate(true)
	_direct_unit_id = String(data.get("unit_id", "")).strip_edges()
	_append_unknown_normalization_warning("verb", raw_verb, verb, ALLOWED_VERBS, VERB_MOVE)
	_append_unknown_normalization_warning("tempo", raw_tempo, tempo, ALLOWED_TEMPOS, TEMPO_NORMAL)
	_append_unknown_normalization_warning("fire_rule", raw_fire_rule, fire_rule, ALLOWED_FIRE_RULES, FIRE_RULE_RETURN)
	_append_unknown_normalization_warning("contact_response", raw_contact_response, contact_response, ALLOWED_CONTACT_RESPONSES, CONTACT_RESPONSE_REPORT)
	_append_unknown_normalization_warning("risk", raw_risk, risk, ALLOWED_RISK_LEVELS, RISK_NORMAL)


func _finalize_defaults() -> void:
	if not is_allowed_verb(verb):
		verb = VERB_MOVE
	if not is_allowed_tempo(tempo):
		tempo = TEMPO_NORMAL
	if not is_allowed_fire_rule(fire_rule):
		fire_rule = FIRE_RULE_RETURN
	if not is_allowed_contact_response(contact_response):
		contact_response = CONTACT_RESPONSE_REPORT
	if not is_allowed_risk(risk):
		risk = RISK_NORMAL
	if cover_priority.is_empty():
		cover_priority = "normal"
	if security_mode.is_empty():
		security_mode = "facing"
	if command_id.is_empty():
		command_id = _build_default_command_id()
	_sync_normalization_warnings_metadata()


func _append_unknown_normalization_warning(field_id: String, raw_value: String, normalized_value: String, allowed_values: PackedStringArray, fallback_value: String) -> void:
	var raw_normalized: String = raw_value.strip_edges().to_lower()
	if raw_normalized.is_empty() or allowed_values.has(normalized_value):
		return
	var warning: String = "unknown_%s:%s:fallback_%s" % [field_id, raw_normalized, fallback_value]
	if not normalization_warnings.has(warning):
		normalization_warnings.append(warning)


func _sync_normalization_warnings_metadata() -> void:
	if normalization_warnings.is_empty():
		metadata.erase("normalization_warnings")
		return
	metadata["normalization_warnings"] = PackedStringArray(normalization_warnings)


func _build_default_command_id() -> String:
	var fireteam_token: String = fireteam_id
	if fireteam_token.is_empty() and not coordinated_fireteam_ids.is_empty():
		fireteam_token = _join_fireteam_ids(coordinated_fireteam_ids)
	if fireteam_token.is_empty():
		fireteam_token = "multi"
	var target_token: String = target_area_id
	if target_token.is_empty() and target_position != null:
		target_token = str(target_position).replace(" ", "")
	if target_token.is_empty():
		target_token = "no_target"
	var raw_id: String = "%s_%s_p%d_%s" % [fireteam_token, verb, phase, target_token]
	return "intent_%s" % _sanitize_id(raw_id)


func _normalize_verb(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"attack", "attack_area":
			return VERB_ENGAGE
		"move_to_area", "move_to_position":
			return VERB_MOVE
		"hold_position":
			return VERB_HOLD
		"engage_area":
			return VERB_ENGAGE
		_:
			return normalized


func _normalize_fire_rule(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"hold_fire":
			return FIRE_RULE_HOLD
		"fire_at_will":
			return FIRE_RULE_FREE
		"semi_disciplined":
			return FIRE_RULE_RETURN
		_:
			return normalized


func _to_legacy_command_type(value: String) -> String:
	match value.strip_edges().to_lower():
		VERB_SECURE:
			return VERB_DEFEND
		VERB_RECON, VERB_BYPASS, VERB_WITHDRAW, VERB_SUPPORT:
			return VERB_MOVE
		VERB_HOLD:
			return VERB_DEFEND
		_:
			return value.strip_edges().to_lower()


func _requires_target() -> bool:
	return verb != VERB_HOLD


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true
	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3


func _sanitize_id(value: String) -> String:
	var result: String = ""
	for index in range(value.length()):
		var code: int = value.unicode_at(index)
		var is_lower: bool = code >= 97 and code <= 122
		var is_number: bool = code >= 48 and code <= 57
		var is_separator: bool = code == 95
		result += value[index] if is_lower or is_number or is_separator else "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	return result.strip_edges().trim_prefix("_").trim_suffix("_")


func _sanitize_fireteam_id_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for id_variant in Array(value):
		var fireteam_value: String = String(id_variant).strip_edges().to_lower()
		if fireteam_value.is_empty() or result.has(fireteam_value):
			continue
		result.append(fireteam_value)
	return result


func _sanitize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in Array(value):
		var entry: String = String(entry_variant).strip_edges()
		if entry.is_empty() or result.has(entry):
			continue
		result.append(entry)
	return result


func _join_fireteam_ids(values: PackedStringArray) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for value in values:
		parts.append(String(value))
	return "_".join(parts)
