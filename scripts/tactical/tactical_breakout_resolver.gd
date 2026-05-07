class_name TacticalBreakoutResolver
extends RefCounted

const FIRETEAM_EXECUTION_PLAN_SCRIPT: GDScript = preload("res://scripts/tactical/fireteam_execution_plan.gd")
const TACTICAL_COMMUNICATION_EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const TACTICAL_COMMUNICATION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_resolver.gd")

const CATALOG_PATH: String = "res://data/tactical_breakout_catalog.json"

const TRIGGER_CONTACT: String = "contact"
const TRIGGER_SUPPRESSED_PINNED: String = "suppressed_pinned"
const TRIGGER_CASUALTY_MEDIC_NEEDED: String = "casualty_medic_needed"
const TRIGGER_BLOCKED_ROUTE: String = "blocked_route"
const TRIGGER_OUT_OF_WEAPON_RANGE: String = "out_of_weapon_range"
const TRIGGER_LOW_AMMO_NO_WEAPON: String = "low_ammo_no_weapon"
const TRIGGER_LEADER_DOWN: String = "leader_down"
const TRIGGER_AIR_ASSET_THREATENED: String = "air_asset_threatened"
const TRIGGER_AIR_ASSET_DESTROYED: String = "air_asset_destroyed"
const TRIGGER_RULE_CONFLICT: String = "rule_conflict"

const BREAKOUT_AUTO_ADAPT: String = "auto_adapt"
const BREAKOUT_HOLD_AND_REPORT: String = "hold_and_report"
const BREAKOUT_REQUEST_ORDERS: String = "request_orders"
const BREAKOUT_ABORT_TO_SAFE: String = "abort_to_safe"

const STATUS_AUTO_ADAPTING: String = "auto_adapting"
const STATUS_HOLDING: String = "holding"
const STATUS_NEEDS_ORDERS: String = "needs_orders"
const STATUS_ABORTING: String = "aborting"
const STATUS_RETURNED_TO_PLAN: String = "returned_to_plan"

const DEFAULT_ALLOWED_BREAKOUTS: PackedStringArray = [
	BREAKOUT_AUTO_ADAPT,
	BREAKOUT_HOLD_AND_REPORT,
	BREAKOUT_REQUEST_ORDERS,
]


static func get_catalog() -> Dictionary:
	var catalog: Dictionary = _read_catalog_file()
	if catalog.is_empty():
		catalog = _fallback_catalog()
	return catalog.duplicate(true)


static func get_trigger_catalog() -> Dictionary:
	return Dictionary(get_catalog().get("triggers", {})).duplicate(true)


static func get_breakout_class_catalog() -> Dictionary:
	return Dictionary(get_catalog().get("breakout_classes", {})).duplicate(true)


static func normalize_trigger(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"contact", "spotted", "enemy_contact":
			return TRIGGER_CONTACT
		"suppressed", "pinned", "suppression", "suppressed_pinned":
			return TRIGGER_SUPPRESSED_PINNED
		"casualty", "medic", "medic_needed", "casualty_medic_needed":
			return TRIGGER_CASUALTY_MEDIC_NEEDED
		"blocked", "blocked_path", "no_path", "blocked_route":
			return TRIGGER_BLOCKED_ROUTE
		"range", "out_of_range", "out_of_weapon_range":
			return TRIGGER_OUT_OF_WEAPON_RANGE
		"ammo", "low_ammo", "no_weapon", "low_ammo_no_weapon":
			return TRIGGER_LOW_AMMO_NO_WEAPON
		"leader", "leader_down", "ftl_down":
			return TRIGGER_LEADER_DOWN
		"air_threat", "lz_threatened", "air_asset_threatened":
			return TRIGGER_AIR_ASSET_THREATENED
		"air_destroyed", "air_lost", "air_asset_destroyed":
			return TRIGGER_AIR_ASSET_DESTROYED
		"rule", "conflict", "rule_conflict", "plan_rule_conflict":
			return TRIGGER_RULE_CONFLICT
		_:
			return normalized


static func normalize_breakout_class(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"adapt", "auto", "auto_adapt":
			return BREAKOUT_AUTO_ADAPT
		"hold", "report", "hold_and_report":
			return BREAKOUT_HOLD_AND_REPORT
		"request", "question", "needs_orders", "request_orders":
			return BREAKOUT_REQUEST_ORDERS
		"abort", "safe", "abort_to_safe":
			return BREAKOUT_ABORT_TO_SAFE
		_:
			return BREAKOUT_HOLD_AND_REPORT if normalized.is_empty() else normalized


static func detect_trigger(context: Dictionary) -> String:
	if bool(context.get("air_asset_destroyed", false)):
		return TRIGGER_AIR_ASSET_DESTROYED
	if bool(context.get("air_asset_threatened", context.get("lz_threatened", false))):
		return TRIGGER_AIR_ASSET_THREATENED
	if bool(context.get("leader_down", false)):
		return TRIGGER_LEADER_DOWN
	if bool(context.get("blocked_path", context.get("no_path", false))):
		return TRIGGER_BLOCKED_ROUTE
	if bool(context.get("is_suppressed", context.get("pinned", false))):
		return TRIGGER_SUPPRESSED_PINNED
	if bool(context.get("medic_needed", false)) or int(context.get("casualty_count", 0)) > 0:
		return TRIGGER_CASUALTY_MEDIC_NEEDED
	if bool(context.get("out_of_weapon_range", false)):
		return TRIGGER_OUT_OF_WEAPON_RANGE
	if bool(context.get("low_ammo", false)) or bool(context.get("no_weapon", false)):
		return TRIGGER_LOW_AMMO_NO_WEAPON
	if bool(context.get("rule_conflict", context.get("plan_rule_conflict", false))):
		return TRIGGER_RULE_CONFLICT
	if bool(context.get("contact", false)) or float(context.get("contact_pressure", 0.0)) > 0.0:
		return TRIGGER_CONTACT
	return ""


static func evaluate_breakout(plan_variant: Variant, context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var plan: Dictionary = _coerce_plan_snapshot(plan_variant)
	var trigger: String = normalize_trigger(str(context.get("trigger", context.get("event_type", ""))))
	if trigger.is_empty():
		trigger = detect_trigger(context)
	if trigger.is_empty():
		return {}
	var trigger_catalog: Dictionary = get_trigger_catalog()
	if not trigger_catalog.has(trigger):
		return {}
	var trigger_def: Dictionary = Dictionary(trigger_catalog.get(trigger, {}))
	var skill: Dictionary = _extract_skill(plan, context)
	var desired_class: String = normalize_breakout_class(str(context.get("breakout_class", trigger_def.get("breakout_class", BREAKOUT_HOLD_AND_REPORT))))
	var final_class: String = _resolve_breakout_class(trigger, desired_class, plan, context, skill)
	var class_catalog: Dictionary = get_breakout_class_catalog()
	var class_def: Dictionary = Dictionary(class_catalog.get(final_class, {}))
	var fireteam_id: String = str(context.get("fireteam_id", plan.get("fireteam_id", ""))).strip_edges().to_lower()
	if fireteam_id.is_empty():
		return {}
	var plan_id: String = str(plan.get("plan_id", context.get("plan_id", "runtime_plan"))).strip_edges()
	if plan_id.is_empty():
		plan_id = "runtime_plan"
	var phase: int = int(context.get("phase", plan.get("phase", 0)))
	var sequence: String = str(context.get("sequence", options.get("sequence", 0)))
	var event_id: String = str(context.get("event_id", "")).strip_edges()
	if event_id.is_empty():
		event_id = _build_event_id(trigger, fireteam_id, plan_id, sequence)
	var communication_event_type: String = str(trigger_def.get("communication_event_type", _event_type_for_class(final_class)))
	var judgement: float = clampf(float(skill.get("breakout_judgement", 0.5)), 0.0, 1.0)
	var communication_clarity: float = clampf(float(skill.get("communication_clarity", 0.5)), 0.0, 1.0)
	var allowed: PackedStringArray = _allowed_breakouts(plan)
	var within_rules: bool = allowed.has(final_class)
	var cause_label: String = str(context.get("cause_label", trigger_def.get("cause_label", trigger))).strip_edges()
	var short_label: String = str(context.get("short_label", trigger_def.get("short_label", trigger))).strip_edges().to_upper()
	var status: String = str(class_def.get("status", _status_for_class(final_class)))
	var return_allowed: bool = bool(class_def.get("return_to_plan_allowed", _return_allowed_for_class(final_class))) and trigger != TRIGGER_AIR_ASSET_DESTROYED
	var result: Dictionary = {
		"breakout_id": "breakout:%s:%s:%s:%s" % [trigger, fireteam_id, plan_id, sequence],
		"event_id": event_id,
		"plan_id": plan_id,
		"command_id": str(plan.get("command_id", "")),
		"fireteam_id": fireteam_id,
		"phase": phase,
		"trigger": trigger,
		"breakout_class": final_class,
		"requested_breakout_class": desired_class,
		"status": status,
		"cause_label": cause_label,
		"short_label": short_label,
		"detail_text": _build_detail_text(cause_label, final_class, judgement, communication_clarity),
		"communication_event_type": communication_event_type,
		"priority": int(trigger_def.get("priority", TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH)),
		"requires_player_response": final_class == BREAKOUT_REQUEST_ORDERS or final_class == BREAKOUT_ABORT_TO_SAFE,
		"player_options": PackedStringArray(class_def.get("player_options", ["confirm", "override", "abort", "regroup"])),
		"return_to_plan_allowed": return_allowed,
		"auto_return_to_plan": return_allowed and final_class == BREAKOUT_AUTO_ADAPT,
		"within_commander_rules": within_rules,
		"commander_rule_resolution": "as_requested" if desired_class == final_class and within_rules else "adjusted_to_allowed_or_request",
		"ftl_skill_tier": _skill_tier(judgement),
		"breakout_judgement": judgement,
		"communication_clarity": communication_clarity,
		"detection_delay_seconds": _detection_delay_seconds(judgement, trigger),
		"resolved": false,
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"runtime_authority": "SimulationRoot",
	}
	if typeof(context.get("anchor_position", null)) == TYPE_VECTOR2:
		result["anchor_position"] = Vector2(context.get("anchor_position"))
	elif typeof(plan.get("target_position", null)) == TYPE_VECTOR2:
		result["anchor_position"] = Vector2(plan.get("target_position"))
	if typeof(context.get("target_position", null)) == TYPE_VECTOR2:
		result["target_position"] = Vector2(context.get("target_position"))
	elif typeof(plan.get("target_position", null)) == TYPE_VECTOR2:
		result["target_position"] = Vector2(plan.get("target_position"))
	return result


static func resolve_breakouts(candidates: Array, options: Dictionary = {}) -> Array:
	var result: Array = []
	for candidate_variant in candidates:
		if typeof(candidate_variant) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = Dictionary(candidate_variant)
		var plan: Dictionary = Dictionary(candidate.get("plan", candidate.get("execution_plan", {})))
		var context: Dictionary = Dictionary(candidate.get("context", candidate)).duplicate(true)
		var breakout: Dictionary = evaluate_breakout(plan, context, options)
		if not breakout.is_empty():
			result.append(breakout)
	return result


static func build_communication_event(breakout: Dictionary, options: Dictionary = {}) -> Dictionary:
	if breakout.is_empty():
		return {}
	var event_type: String = str(breakout.get("communication_event_type", _event_type_for_class(str(breakout.get("breakout_class", "")))))
	return Dictionary(TACTICAL_COMMUNICATION_RESOLVER_SCRIPT.call("build_event", event_type, {
		"event_id": str(breakout.get("event_id", "")),
		"plan_id": str(breakout.get("plan_id", "")),
		"fireteam_id": str(breakout.get("fireteam_id", "")),
		"phase": int(breakout.get("phase", 0)),
		"role": str(breakout.get("breakout_class", "")),
		"step": str(breakout.get("trigger", "")),
		"short_text": str(breakout.get("short_label", "")),
		"detail_text": str(breakout.get("detail_text", "")),
		"map_label": str(breakout.get("short_label", "")),
		"priority": int(breakout.get("priority", TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH)),
		"communication_clarity": float(breakout.get("communication_clarity", 0.5)),
		"anchor_position": breakout.get("anchor_position", null),
		"target_position": breakout.get("target_position", null),
	}, options))


static func mark_return_to_plan(breakout: Dictionary, context: Dictionary = {}) -> Dictionary:
	var next: Dictionary = breakout.duplicate(true)
	if next.is_empty():
		return {}
	if not can_return_to_plan(next, context):
		next["return_to_plan_denied_reason"] = _return_denied_reason(next, context)
		return next
	next["status"] = STATUS_RETURNED_TO_PLAN
	next["resolved"] = true
	next["return_to_plan_reason"] = str(context.get("reason", "condition_resolved"))
	next["return_to_plan_event_id"] = "%s:return" % str(next.get("event_id", ""))
	next["resolved_msec"] = maxi(int(context.get("now_msec", Time.get_ticks_msec())), 0)
	return next


static func can_return_to_plan(breakout: Dictionary, context: Dictionary = {}) -> bool:
	if breakout.is_empty() or bool(breakout.get("resolved", false)):
		return false
	if not bool(breakout.get("return_to_plan_allowed", false)):
		return false
	if bool(context.get("still_blocked", false)) or bool(context.get("still_suppressed", false)) or bool(context.get("air_asset_destroyed", false)):
		return false
	return true


static func _resolve_breakout_class(trigger: String, desired_class: String, plan: Dictionary, context: Dictionary, skill: Dictionary) -> String:
	var judgement: float = clampf(float(skill.get("breakout_judgement", 0.5)), 0.0, 1.0)
	var final_class: String = desired_class
	match trigger:
		TRIGGER_AIR_ASSET_DESTROYED:
			final_class = BREAKOUT_ABORT_TO_SAFE
		TRIGGER_BLOCKED_ROUTE:
			final_class = BREAKOUT_AUTO_ADAPT if judgement >= 0.58 else BREAKOUT_HOLD_AND_REPORT
		TRIGGER_CONTACT:
			if judgement < 0.34:
				final_class = BREAKOUT_REQUEST_ORDERS
		TRIGGER_SUPPRESSED_PINNED:
			final_class = BREAKOUT_HOLD_AND_REPORT
		TRIGGER_CASUALTY_MEDIC_NEEDED:
			final_class = BREAKOUT_HOLD_AND_REPORT
		TRIGGER_LOW_AMMO_NO_WEAPON, TRIGGER_OUT_OF_WEAPON_RANGE, TRIGGER_RULE_CONFLICT:
			final_class = BREAKOUT_REQUEST_ORDERS
		TRIGGER_LEADER_DOWN:
			final_class = BREAKOUT_HOLD_AND_REPORT if judgement >= 0.68 else BREAKOUT_REQUEST_ORDERS
		TRIGGER_AIR_ASSET_THREATENED:
			final_class = BREAKOUT_REQUEST_ORDERS
	var allowed: PackedStringArray = _allowed_breakouts(plan)
	if allowed.has(final_class):
		return final_class
	if final_class == BREAKOUT_ABORT_TO_SAFE and allowed.has(BREAKOUT_REQUEST_ORDERS):
		return BREAKOUT_REQUEST_ORDERS
	if final_class == BREAKOUT_AUTO_ADAPT and allowed.has(BREAKOUT_HOLD_AND_REPORT):
		return BREAKOUT_HOLD_AND_REPORT
	if allowed.has(BREAKOUT_REQUEST_ORDERS):
		return BREAKOUT_REQUEST_ORDERS
	if allowed.has(BREAKOUT_HOLD_AND_REPORT):
		return BREAKOUT_HOLD_AND_REPORT
	return str(allowed[0]) if not allowed.is_empty() else BREAKOUT_REQUEST_ORDERS


static func _allowed_breakouts(plan: Dictionary) -> PackedStringArray:
	var allowed: PackedStringArray = PackedStringArray(plan.get("allowed_breakout_classes", DEFAULT_ALLOWED_BREAKOUTS))
	if allowed.is_empty():
		allowed = DEFAULT_ALLOWED_BREAKOUTS
	var result: PackedStringArray = PackedStringArray()
	for value in allowed:
		var breakout_class: String = normalize_breakout_class(str(value))
		if breakout_class.is_empty() or result.has(breakout_class):
			continue
		result.append(breakout_class)
	return result


static func _coerce_plan_snapshot(plan_variant: Variant) -> Dictionary:
	if plan_variant == null:
		return {}
	if typeof(plan_variant) == TYPE_DICTIONARY:
		return Dictionary(plan_variant).duplicate(true)
	if plan_variant is RefCounted and plan_variant.has_method("to_snapshot"):
		return Dictionary(plan_variant.call("to_snapshot"))
	if plan_variant is RefCounted and plan_variant.has_method("to_dict"):
		return Dictionary(plan_variant.call("to_dict"))
	return {}


static func _extract_skill(plan: Dictionary, context: Dictionary) -> Dictionary:
	var skill: Dictionary = Dictionary(plan.get("ftl_skill_factors", {})).duplicate(true)
	for key in ["breakout_judgement", "communication_clarity", "planning_quality", "reaction_delay_seconds"]:
		if context.has(key):
			skill[key] = context[key]
	if not skill.has("breakout_judgement"):
		skill["breakout_judgement"] = float(skill.get("planning_quality", 0.5))
	if not skill.has("communication_clarity"):
		skill["communication_clarity"] = float(skill.get("communication", 0.5))
	return skill


static func _event_type_for_class(breakout_class: String) -> String:
	match normalize_breakout_class(breakout_class):
		BREAKOUT_AUTO_ADAPT:
			return TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_BREAKOUT_ADAPTATION
		BREAKOUT_REQUEST_ORDERS:
			return TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_NEEDS_ORDERS
		BREAKOUT_ABORT_TO_SAFE:
			return TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CANNOT_EXECUTE
		_:
			return TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CONTACT_REPORT


static func _status_for_class(breakout_class: String) -> String:
	match normalize_breakout_class(breakout_class):
		BREAKOUT_AUTO_ADAPT:
			return STATUS_AUTO_ADAPTING
		BREAKOUT_REQUEST_ORDERS:
			return STATUS_NEEDS_ORDERS
		BREAKOUT_ABORT_TO_SAFE:
			return STATUS_ABORTING
		_:
			return STATUS_HOLDING


static func _return_allowed_for_class(breakout_class: String) -> bool:
	var normalized: String = normalize_breakout_class(breakout_class)
	return normalized == BREAKOUT_AUTO_ADAPT or normalized == BREAKOUT_HOLD_AND_REPORT


static func _build_event_id(trigger: String, fireteam_id: String, plan_id: String, sequence: String) -> String:
	var clean_sequence: String = sequence.strip_edges()
	if clean_sequence.is_empty():
		clean_sequence = "0"
	return "breakout:%s:%s:%s:%s" % [trigger, fireteam_id, plan_id, clean_sequence]


static func _build_detail_text(cause_label: String, breakout_class: String, judgement: float, communication_clarity: float) -> String:
	var action_text: String = "reports and waits"
	match normalize_breakout_class(breakout_class):
		BREAKOUT_AUTO_ADAPT:
			action_text = "adapts route and keeps plan intent"
		BREAKOUT_REQUEST_ORDERS:
			action_text = "requests commander input"
		BREAKOUT_ABORT_TO_SAFE:
			action_text = "aborts toward safety"
	return "%s | %s | FTL %.0f | COMMS %.0f" % [
		cause_label,
		action_text,
		judgement * 100.0,
		communication_clarity * 100.0,
	]


static func _skill_tier(judgement: float) -> String:
	if judgement >= 0.72:
		return "high"
	if judgement >= 0.42:
		return "neutral"
	return "low"


static func _detection_delay_seconds(judgement: float, trigger: String) -> float:
	var base: float = lerpf(2.4, 0.35, clampf(judgement, 0.0, 1.0))
	if trigger == TRIGGER_AIR_ASSET_DESTROYED or trigger == TRIGGER_LEADER_DOWN:
		base *= 0.65
	return snappedf(maxf(base, 0.15), 0.01)


static func _return_denied_reason(breakout: Dictionary, context: Dictionary) -> String:
	if not bool(breakout.get("return_to_plan_allowed", false)):
		return "breakout class requires commander response"
	if bool(context.get("still_blocked", false)):
		return "route still blocked"
	if bool(context.get("still_suppressed", false)):
		return "fireteam still suppressed"
	if bool(context.get("air_asset_destroyed", false)):
		return "air asset destroyed"
	return "breakout already resolved or unavailable"


static func _read_catalog_file() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


static func _fallback_catalog() -> Dictionary:
	return {
		"schema_version": 1,
		"breakout_classes": {
			BREAKOUT_AUTO_ADAPT: {"status": STATUS_AUTO_ADAPTING, "return_to_plan_allowed": true, "player_options": PackedStringArray(["confirm", "override", "regroup"])},
			BREAKOUT_HOLD_AND_REPORT: {"status": STATUS_HOLDING, "return_to_plan_allowed": true, "player_options": PackedStringArray(["confirm", "override", "abort", "regroup"])},
			BREAKOUT_REQUEST_ORDERS: {"status": STATUS_NEEDS_ORDERS, "return_to_plan_allowed": false, "player_options": PackedStringArray(["confirm", "override", "abort", "regroup"])},
			BREAKOUT_ABORT_TO_SAFE: {"status": STATUS_ABORTING, "return_to_plan_allowed": false, "player_options": PackedStringArray(["confirm", "override", "abort", "regroup"])},
		},
		"triggers": {
			TRIGGER_CONTACT: {"breakout_class": BREAKOUT_HOLD_AND_REPORT, "communication_event_type": TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CONTACT_REPORT, "priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH, "short_label": "CONTACT", "cause_label": "Contact"},
			TRIGGER_SUPPRESSED_PINNED: {"breakout_class": BREAKOUT_HOLD_AND_REPORT, "communication_event_type": TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_BREAKOUT_ADAPTATION, "priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH, "short_label": "PINNED", "cause_label": "Suppressed"},
			TRIGGER_BLOCKED_ROUTE: {"breakout_class": BREAKOUT_AUTO_ADAPT, "communication_event_type": TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, "priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL, "short_label": "BLOCKED", "cause_label": "Blocked route"},
			TRIGGER_AIR_ASSET_DESTROYED: {"breakout_class": BREAKOUT_ABORT_TO_SAFE, "communication_event_type": TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED, "priority": TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL, "short_label": "AIR LOST", "cause_label": "Air asset destroyed"},
		},
	}
