class_name FireteamExecutionPlan
extends RefCounted

const COMMANDER_INTENT_SCRIPT: GDScript = preload("res://scripts/command/commander_intent.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")

const MOVEMENT_STYLE_RUSH: String = "rush"
const MOVEMENT_STYLE_BOUNDING: String = "bounding"
const MOVEMENT_STYLE_CATERPILLAR: String = "caterpillar"
const MOVEMENT_STYLE_HOLD: String = "hold"
const MOVEMENT_STYLE_PROBE: String = "probe"

const SECURITY_NONE_IN_TRANSIT: String = "none_in_transit"
const SECURITY_FACING: String = "facing"
const SECURITY_SECTOR: String = "sector"
const SECURITY_ALL_ROUND: String = "all_round"

const STATUS_COPY: String = "copy"
const STATUS_CANNOT: String = "cannot"
const STATUS_ADAPTING: String = "adapting"
const STATUS_COMPLETE: String = "complete"
const STATUS_NEEDS_ORDERS: String = "needs_orders"

const BREAKOUT_AUTO_ADAPT: String = "auto_adapt"
const BREAKOUT_HOLD_AND_REPORT: String = "hold_and_report"
const BREAKOUT_REQUEST_ORDERS: String = "request_orders"
const BREAKOUT_ABORT_TO_SAFE: String = "abort_to_safe"

const ACTION_MOVE_TO_POSITION: String = "move_to_position"
const ACTION_HOLD_POSITION: String = "hold_position"
const ACTION_ENGAGE_AREA: String = "engage_area"
const ACTION_SEEK_COVER: String = "seek_cover"
const ACTION_RETREAT: String = "retreat"

const ALLOWED_MOVEMENT_STYLES: PackedStringArray = [
	MOVEMENT_STYLE_RUSH,
	MOVEMENT_STYLE_BOUNDING,
	MOVEMENT_STYLE_CATERPILLAR,
	MOVEMENT_STYLE_HOLD,
	MOVEMENT_STYLE_PROBE,
]
const ALLOWED_SECURITY_MODES: PackedStringArray = [
	SECURITY_NONE_IN_TRANSIT,
	SECURITY_FACING,
	SECURITY_SECTOR,
	SECURITY_ALL_ROUND,
]
const ALLOWED_STATUS_RESPONSES: PackedStringArray = [
	STATUS_COPY,
	STATUS_CANNOT,
	STATUS_ADAPTING,
	STATUS_COMPLETE,
	STATUS_NEEDS_ORDERS,
]
const ALLOWED_BREAKOUT_CLASSES: PackedStringArray = [
	BREAKOUT_AUTO_ADAPT,
	BREAKOUT_HOLD_AND_REPORT,
	BREAKOUT_REQUEST_ORDERS,
	BREAKOUT_ABORT_TO_SAFE,
]
const ALLOWED_ACTION_TYPES: PackedStringArray = [
	ACTION_MOVE_TO_POSITION,
	ACTION_HOLD_POSITION,
	ACTION_ENGAGE_AREA,
	ACTION_SEEK_COVER,
	ACTION_RETREAT,
]

var plan_id: String = ""
var command_id: String = ""
var fireteam_id: String = ""
var team_id: String = ""
var coordination_plan_id: String = ""
var coordination_role: String = ""
var phase: int = -1
var status_response: String = STATUS_COPY
var movement_style: String = MOVEMENT_STYLE_RUSH
var security_mode: String = SECURITY_FACING
var cover_priority: float = 0.5
var route_bias: String = "direct"
var communication_state: String = "clear"
var expected_duration_seconds: float = 8.0
var target_position: Variant = null
var target_area_id: String = ""
var tactical_rules: Dictionary = {}
var ftl_skill_factors: Dictionary = {}
var allowed_breakout_classes: PackedStringArray = [
	BREAKOUT_AUTO_ADAPT,
	BREAKOUT_HOLD_AND_REPORT,
	BREAKOUT_REQUEST_ORDERS,
]
var source_intent: Dictionary = {}
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	if not data.is_empty():
		_apply_dict(data)
	_finalize_defaults()


static func from_dict(data: Dictionary) -> FireteamExecutionPlan:
	var script_ref: GDScript = load("res://scripts/tactical/fireteam_execution_plan.gd")
	return script_ref.new(data)


static func from_intent(intent_variant: Variant, ftl_skill: Dictionary = {}, overrides: Dictionary = {}) -> FireteamExecutionPlan:
	var intent = _coerce_intent(intent_variant)
	if intent == null:
		return from_dict({"status_response": STATUS_CANNOT})
	var intent_dict: Dictionary = intent.call("to_dict")
	var skill: Dictionary = _normalize_skill_factors(ftl_skill)
	var plan_data: Dictionary = {
		"command_id": String(intent_dict.get("command_id", "")),
		"fireteam_id": String(intent_dict.get("fireteam_id", "")),
		"team_id": String(intent_dict.get("team_id", "")),
		"phase": int(intent_dict.get("phase", -1)),
		"status_response": STATUS_COPY if bool(intent.call("is_valid")) else STATUS_CANNOT,
		"movement_style": _map_movement_style(intent_dict),
		"security_mode": _map_security_mode(intent_dict),
		"cover_priority": _map_cover_priority(intent_dict, skill),
		"route_bias": _map_route_bias(intent_dict),
		"communication_state": _map_communication_state(skill),
		"expected_duration_seconds": _map_expected_duration(intent_dict, skill),
		"target_position": intent_dict.get("target_position", null),
		"target_area_id": String(intent_dict.get("target_area_id", "")),
		"tactical_rules": _extract_tactical_rules(intent_dict),
		"ftl_skill_factors": skill,
		"allowed_breakout_classes": _map_allowed_breakouts(intent_dict, skill),
		"source_intent": intent_dict,
	}
	for key in overrides.keys():
		plan_data[key] = overrides[key]
	return from_dict(plan_data)


static func is_allowed_movement_style(value: String) -> bool:
	return ALLOWED_MOVEMENT_STYLES.has(value.strip_edges().to_lower())


static func is_allowed_security_mode(value: String) -> bool:
	return ALLOWED_SECURITY_MODES.has(value.strip_edges().to_lower())


static func is_allowed_status_response(value: String) -> bool:
	return ALLOWED_STATUS_RESPONSES.has(value.strip_edges().to_lower())


static func is_allowed_breakout_class(value: String) -> bool:
	return ALLOWED_BREAKOUT_CLASSES.has(value.strip_edges().to_lower())


static func is_allowed_action_type(value: String) -> bool:
	return ALLOWED_ACTION_TYPES.has(value.strip_edges().to_lower())


static func validate_unit_action(action: Dictionary) -> bool:
	if String(action.get("action_id", "")).strip_edges().is_empty():
		return false
	if String(action.get("plan_id", "")).strip_edges().is_empty():
		return false
	if String(action.get("command_id", "")).strip_edges().is_empty():
		return false
	if String(action.get("unit_id", "")).strip_edges().is_empty():
		return false
	if not is_allowed_action_type(String(action.get("action_type", ""))):
		return false
	if String(action.get("ui_control_path", "")).strip_edges() != "":
		return false
	var target = action.get("target_position", null)
	if target == null:
		return true
	var value_type: int = typeof(target)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3


func is_valid() -> bool:
	if plan_id.is_empty() or command_id.is_empty() or fireteam_id.is_empty():
		return false
	if not is_allowed_status_response(status_response):
		return false
	if not is_allowed_movement_style(movement_style):
		return false
	if not is_allowed_security_mode(security_mode):
		return false
	if cover_priority < 0.0 or cover_priority > 1.0:
		return false
	if expected_duration_seconds < 0.0:
		return false
	if not _has_valid_target_position():
		return false
	for breakout_class in allowed_breakout_classes:
		if not ALLOWED_BREAKOUT_CLASSES.has(String(breakout_class)):
			return false
	return true


func allows_breakout_class(breakout_class: String) -> bool:
	return allowed_breakout_classes.has(breakout_class.strip_edges().to_lower())


func build_breakout_plan_context(trigger: String = "", context: Dictionary = {}) -> Dictionary:
	var snapshot: Dictionary = to_snapshot()
	snapshot["breakout_trigger"] = trigger.strip_edges().to_lower()
	snapshot["breakout_context"] = context.duplicate(true)
	snapshot["allowed_breakout_classes"] = PackedStringArray(allowed_breakout_classes)
	snapshot["ui_sets_gameplay_truth"] = false
	return snapshot


func to_dict() -> Dictionary:
	var data: Dictionary = {
		"plan_id": plan_id,
		"command_id": command_id,
		"fireteam_id": fireteam_id,
		"phase": phase,
		"status_response": status_response,
		"movement_style": movement_style,
		"security_mode": security_mode,
		"cover_priority": cover_priority,
		"route_bias": route_bias,
		"communication_state": communication_state,
		"expected_duration_seconds": expected_duration_seconds,
		"tactical_rules": tactical_rules.duplicate(true),
		"ftl_skill_factors": ftl_skill_factors.duplicate(true),
		"allowed_breakout_classes": PackedStringArray(allowed_breakout_classes),
		"source_intent": source_intent.duplicate(true),
		"metadata": metadata.duplicate(true),
	}
	if not coordination_plan_id.is_empty():
		data["coordination_plan_id"] = coordination_plan_id
	if not coordination_role.is_empty():
		data["coordination_role"] = coordination_role
	if not team_id.is_empty():
		data["team_id"] = team_id
	if target_position != null:
		data["target_position"] = target_position
	if not target_area_id.is_empty():
		data["target_area_id"] = target_area_id
	return data


func to_snapshot() -> Dictionary:
	var snapshot: Dictionary = to_dict()
	snapshot["ftl_response"] = status_response
	snapshot["planning_quality"] = float(ftl_skill_factors.get("planning_quality", 0.5))
	snapshot["reaction_delay_seconds"] = float(ftl_skill_factors.get("reaction_delay_seconds", 0.25))
	snapshot["communication_clarity"] = float(ftl_skill_factors.get("communication_clarity", 0.5))
	snapshot["coordination_plan_id"] = coordination_plan_id
	snapshot["coordination_role"] = coordination_role
	snapshot["ui_sets_unit_truth"] = false
	snapshot["runtime_authority"] = "SimulationRoot"
	return snapshot


func build_unit_action(unit_id: String, target_override: Variant = null, action_type_override: String = "") -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	var action_type: String = action_type_override.strip_edges().to_lower()
	if action_type.is_empty():
		action_type = _map_default_unit_action_type()
	var target = target_override if target_override != null else target_position
	var action: Dictionary = {
		"action_id": "%s:%s:%s" % [plan_id, normalized_unit_id, action_type],
		"plan_id": plan_id,
		"command_id": command_id,
		"fireteam_id": fireteam_id,
		"team_id": team_id if not team_id.is_empty() else fireteam_id,
		"unit_id": normalized_unit_id,
		"action_type": action_type,
		"runtime_command_type": _map_unit_action_to_runtime_command(action_type),
		"source": "FireteamExecutionPlan",
		"ui_control_path": "",
	}
	if not coordination_plan_id.is_empty():
		action["coordination_plan_id"] = coordination_plan_id
	if not coordination_role.is_empty():
		action["coordination_role"] = coordination_role
	if target != null:
		action["target_position"] = target
	if not target_area_id.is_empty():
		action["target_area_id"] = target_area_id
	return action


func build_unit_actions(unit_ids: PackedStringArray) -> Array:
	var actions: Array = []
	for unit_id in unit_ids:
		var action: Dictionary = build_unit_action(String(unit_id))
		if validate_unit_action(action):
			actions.append(action)
	return actions


func unit_action_to_runtime_command(action: Dictionary) -> Dictionary:
	if not validate_unit_action(action):
		return {}
	var data: Dictionary = {
		"command_type": String(action.get("runtime_command_type", "")),
		"priority": 12,
		"unit_id": String(action.get("unit_id", "")),
		"team_id": String(action.get("team_id", "")),
		"source_command_type": String(source_intent.get("verb", "")),
		"source_task_type": "fireteam_execution_plan",
		"command_token": String(action.get("action_id", "")),
	}
	if action.has("target_position"):
		data["target_position"] = action["target_position"]
	if action.has("target_area_id"):
		data["target_area_id"] = action["target_area_id"]
	if phase >= 0:
		data["phase"] = phase
	var command = UNIT_COMMAND_SCRIPT.new(data)
	if not bool(command.call("is_valid")):
		return {}
	return command.call("to_dict")


func _apply_dict(data: Dictionary) -> void:
	plan_id = String(data.get("plan_id", "")).strip_edges()
	command_id = String(data.get("command_id", "")).strip_edges()
	fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	team_id = String(data.get("team_id", "")).strip_edges()
	coordination_plan_id = String(data.get("coordination_plan_id", "")).strip_edges()
	coordination_role = String(data.get("coordination_role", "")).strip_edges().to_lower()
	phase = int(data.get("phase", -1))
	status_response = String(data.get("status_response", STATUS_COPY)).strip_edges().to_lower()
	movement_style = String(data.get("movement_style", MOVEMENT_STYLE_RUSH)).strip_edges().to_lower()
	security_mode = String(data.get("security_mode", SECURITY_FACING)).strip_edges().to_lower()
	cover_priority = clampf(float(data.get("cover_priority", 0.5)), 0.0, 1.0)
	route_bias = String(data.get("route_bias", "direct")).strip_edges().to_lower()
	communication_state = String(data.get("communication_state", "clear")).strip_edges().to_lower()
	expected_duration_seconds = maxf(float(data.get("expected_duration_seconds", 8.0)), 0.0)
	target_position = data.get("target_position", null)
	target_area_id = String(data.get("target_area_id", "")).strip_edges()
	tactical_rules = Dictionary(data.get("tactical_rules", {})).duplicate(true)
	ftl_skill_factors = _normalize_skill_factors(Dictionary(data.get("ftl_skill_factors", {})))
	allowed_breakout_classes = PackedStringArray(data.get("allowed_breakout_classes", allowed_breakout_classes))
	source_intent = Dictionary(data.get("source_intent", {})).duplicate(true)
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)


func _finalize_defaults() -> void:
	if plan_id.is_empty():
		plan_id = _build_default_plan_id()
	if not is_allowed_status_response(status_response):
		status_response = STATUS_CANNOT
	if not is_allowed_movement_style(movement_style):
		movement_style = MOVEMENT_STYLE_RUSH
	if not is_allowed_security_mode(security_mode):
		security_mode = SECURITY_FACING


func _build_default_plan_id() -> String:
	return "plan_%s_%s_p%d" % [
		fireteam_id if not fireteam_id.is_empty() else "none",
		command_id if not command_id.is_empty() else "no_command",
		phase,
	]


func _map_default_unit_action_type() -> String:
	match movement_style:
		MOVEMENT_STYLE_HOLD:
			return ACTION_HOLD_POSITION
		MOVEMENT_STYLE_PROBE:
			return ACTION_SEEK_COVER
		_:
			var verb: String = String(source_intent.get("verb", "")).strip_edges().to_lower()
			if verb == COMMANDER_INTENT_SCRIPT.VERB_ENGAGE or verb == COMMANDER_INTENT_SCRIPT.VERB_TAKE:
				return ACTION_ENGAGE_AREA
			if verb == COMMANDER_INTENT_SCRIPT.VERB_WITHDRAW:
				return ACTION_RETREAT
			return ACTION_MOVE_TO_POSITION


func _map_unit_action_to_runtime_command(action_type: String) -> String:
	match action_type:
		ACTION_HOLD_POSITION:
			return UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
		ACTION_ENGAGE_AREA:
			return UNIT_COMMAND_SCRIPT.TYPE_ENGAGE_AREA
		ACTION_SEEK_COVER:
			return UNIT_COMMAND_SCRIPT.TYPE_SEEK_COVER
		ACTION_RETREAT:
			return UNIT_COMMAND_SCRIPT.TYPE_RETREAT
		_:
			return UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION


func _has_valid_target_position() -> bool:
	if target_position == null:
		return true
	var value_type: int = typeof(target_position)
	return value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR2I or value_type == TYPE_VECTOR3


static func _coerce_intent(intent_variant: Variant):
	if intent_variant == null:
		return null
	if intent_variant is RefCounted and intent_variant.has_method("to_dict") and intent_variant.has_method("is_valid"):
		return intent_variant
	if typeof(intent_variant) == TYPE_DICTIONARY:
		return COMMANDER_INTENT_SCRIPT.call("from_dict", intent_variant)
	return null


static func _extract_tactical_rules(intent: Dictionary) -> Dictionary:
	return {
		"tempo": String(intent.get("tempo", COMMANDER_INTENT_SCRIPT.TEMPO_NORMAL)),
		"fire_rule": String(intent.get("fire_rule", COMMANDER_INTENT_SCRIPT.FIRE_RULE_RETURN)),
		"contact_response": String(intent.get("contact_response", COMMANDER_INTENT_SCRIPT.CONTACT_RESPONSE_REPORT)),
		"cover_priority": String(intent.get("cover_priority", "normal")),
		"security_mode": String(intent.get("security_mode", SECURITY_FACING)),
		"risk": String(intent.get("risk", COMMANDER_INTENT_SCRIPT.RISK_NORMAL)),
		"sync_group_id": String(intent.get("sync_group_id", "")),
	}


static func _map_movement_style(intent: Dictionary) -> String:
	var verb: String = String(intent.get("verb", COMMANDER_INTENT_SCRIPT.VERB_MOVE)).strip_edges().to_lower()
	var tempo: String = String(intent.get("tempo", COMMANDER_INTENT_SCRIPT.TEMPO_NORMAL)).strip_edges().to_lower()
	match verb:
		COMMANDER_INTENT_SCRIPT.VERB_DEFEND, COMMANDER_INTENT_SCRIPT.VERB_HOLD:
			return MOVEMENT_STYLE_HOLD
		COMMANDER_INTENT_SCRIPT.VERB_TAKE, COMMANDER_INTENT_SCRIPT.VERB_ENGAGE, COMMANDER_INTENT_SCRIPT.VERB_FLANK, COMMANDER_INTENT_SCRIPT.VERB_SUPPORT:
			return MOVEMENT_STYLE_BOUNDING
		COMMANDER_INTENT_SCRIPT.VERB_RECON, COMMANDER_INTENT_SCRIPT.VERB_SECURE:
			return MOVEMENT_STYLE_PROBE
		_:
			return MOVEMENT_STYLE_CATERPILLAR if tempo == COMMANDER_INTENT_SCRIPT.TEMPO_CAUTIOUS else MOVEMENT_STYLE_RUSH


static func _map_security_mode(intent: Dictionary) -> String:
	var requested_security: String = String(intent.get("security_mode", "")).strip_edges().to_lower()
	match requested_security:
		"360", "all_round":
			return SECURITY_ALL_ROUND
		"sector":
			return SECURITY_SECTOR
		"none_in_transit", "none-in-transit":
			return SECURITY_NONE_IN_TRANSIT
		"facing", "directional":
			return SECURITY_FACING
	var verb: String = String(intent.get("verb", COMMANDER_INTENT_SCRIPT.VERB_MOVE)).strip_edges().to_lower()
	match verb:
		COMMANDER_INTENT_SCRIPT.VERB_DEFEND, COMMANDER_INTENT_SCRIPT.VERB_HOLD:
			return SECURITY_ALL_ROUND
		COMMANDER_INTENT_SCRIPT.VERB_TAKE, COMMANDER_INTENT_SCRIPT.VERB_ENGAGE, COMMANDER_INTENT_SCRIPT.VERB_SUPPORT:
			return SECURITY_SECTOR
		COMMANDER_INTENT_SCRIPT.VERB_MOVE, COMMANDER_INTENT_SCRIPT.VERB_WITHDRAW, COMMANDER_INTENT_SCRIPT.VERB_BYPASS:
			return SECURITY_FACING
		_:
			return SECURITY_SECTOR


static func _map_cover_priority(intent: Dictionary, skill: Dictionary) -> float:
	var requested_cover: String = String(intent.get("cover_priority", "")).strip_edges().to_lower()
	match requested_cover:
		"low":
			return clampf(0.32 + ((float(skill.get("planning_quality", 0.5)) - 0.5) * 0.1), 0.0, 1.0)
		"high":
			return clampf(0.76 + ((float(skill.get("planning_quality", 0.5)) - 0.5) * 0.1), 0.0, 1.0)
		"normal":
			return clampf(0.55 + ((float(skill.get("planning_quality", 0.5)) - 0.5) * 0.1), 0.0, 1.0)
	var risk: String = String(intent.get("risk", COMMANDER_INTENT_SCRIPT.RISK_NORMAL)).strip_edges().to_lower()
	var tempo: String = String(intent.get("tempo", COMMANDER_INTENT_SCRIPT.TEMPO_NORMAL)).strip_edges().to_lower()
	var base: float = 0.55
	if risk == COMMANDER_INTENT_SCRIPT.RISK_LOW:
		base = 0.75
	elif risk == COMMANDER_INTENT_SCRIPT.RISK_HIGH:
		base = 0.35
	if tempo == COMMANDER_INTENT_SCRIPT.TEMPO_CAUTIOUS:
		base += 0.12
	elif tempo == COMMANDER_INTENT_SCRIPT.TEMPO_RAPID:
		base -= 0.12
	base += (float(skill.get("planning_quality", 0.5)) - 0.5) * 0.16
	return clampf(base, 0.0, 1.0)


static func _map_route_bias(intent: Dictionary) -> String:
	var risk: String = String(intent.get("risk", COMMANDER_INTENT_SCRIPT.RISK_NORMAL)).strip_edges().to_lower()
	var tempo: String = String(intent.get("tempo", COMMANDER_INTENT_SCRIPT.TEMPO_NORMAL)).strip_edges().to_lower()
	if risk == COMMANDER_INTENT_SCRIPT.RISK_LOW:
		return "cover"
	if tempo == COMMANDER_INTENT_SCRIPT.TEMPO_RAPID:
		return "direct"
	return "balanced"


static func _map_communication_state(skill: Dictionary) -> String:
	var clarity: float = float(skill.get("communication_clarity", 0.5))
	if clarity >= 0.78:
		return "clear"
	if clarity >= 0.45:
		return "brief"
	return "uncertain"


static func _map_expected_duration(intent: Dictionary, skill: Dictionary) -> float:
	var tempo: String = String(intent.get("tempo", COMMANDER_INTENT_SCRIPT.TEMPO_NORMAL)).strip_edges().to_lower()
	var base: float = 8.0
	if tempo == COMMANDER_INTENT_SCRIPT.TEMPO_CAUTIOUS:
		base = 12.0
	elif tempo == COMMANDER_INTENT_SCRIPT.TEMPO_RAPID:
		base = 5.5
	base = base / clampf(float(skill.get("tempo_modifier", 1.0)), 0.86, 1.14)
	var initiative: float = float(skill.get("initiative", 0.5))
	return maxf(base - (initiative * 1.5), 2.0)


static func _map_allowed_breakouts(intent: Dictionary, skill: Dictionary) -> PackedStringArray:
	var result: PackedStringArray = [
		BREAKOUT_AUTO_ADAPT,
		BREAKOUT_HOLD_AND_REPORT,
		BREAKOUT_REQUEST_ORDERS,
	]
	if float(skill.get("breakout_judgement", 0.5)) < 0.34:
		result.remove_at(result.find(BREAKOUT_AUTO_ADAPT))
	var risk: String = String(intent.get("risk", COMMANDER_INTENT_SCRIPT.RISK_NORMAL)).strip_edges().to_lower()
	if risk == COMMANDER_INTENT_SCRIPT.RISK_HIGH or float(skill.get("breakout_judgement", 0.5)) >= 0.72:
		result.append(BREAKOUT_ABORT_TO_SAFE)
	return result


static func _normalize_skill_factors(raw_skill: Dictionary) -> Dictionary:
	var leadership: float = clampf(float(raw_skill.get("leadership", raw_skill.get("planning_quality", 0.5))), 0.0, 1.0)
	var discipline: float = clampf(float(raw_skill.get("discipline", raw_skill.get("fire_discipline", 0.5))), 0.0, 1.0)
	var cohesion: float = clampf(float(raw_skill.get("cohesion", raw_skill.get("execution_cohesion", 0.5))), 0.0, 1.0)
	var communication: float = clampf(float(raw_skill.get("communication", raw_skill.get("communication_clarity", leadership))), 0.0, 1.0)
	var initiative: float = clampf(float(raw_skill.get("initiative", leadership)), 0.0, 1.0)
	var derived_planning_quality: float = clampf((leadership * 0.45) + (discipline * 0.2) + (cohesion * 0.2) + (initiative * 0.15), 0.0, 1.0)
	var planning_quality: float = clampf(float(raw_skill.get("planning_quality", derived_planning_quality)), 0.0, 1.0)
	var reaction_delay_seconds: float = clampf(float(raw_skill.get("reaction_delay_seconds", lerpf(0.65, 0.12, planning_quality))), 0.05, 0.85)
	return {
		"leadership": leadership,
		"discipline": discipline,
		"cohesion": cohesion,
		"communication_clarity": communication,
		"initiative": initiative,
		"planning_quality": planning_quality,
		"reaction_delay_seconds": reaction_delay_seconds,
		"cohesion_modifier": lerpf(0.82, 1.18, cohesion),
		"fire_discipline_modifier": lerpf(0.85, 1.15, discipline),
		"breakout_judgement": clampf(float(raw_skill.get("breakout_judgement", planning_quality)), 0.0, 1.0),
		"spacing_quality": clampf(float(raw_skill.get("spacing_quality", cohesion)), 0.0, 1.0),
		"contact_report_quality": clampf(float(raw_skill.get("contact_report_quality", communication)), 0.0, 1.0),
		"tempo_modifier": clampf(float(raw_skill.get("tempo_modifier", 1.0)), 0.86, 1.14),
	}
