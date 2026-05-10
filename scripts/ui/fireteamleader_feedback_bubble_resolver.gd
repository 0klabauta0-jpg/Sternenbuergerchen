class_name FireteamleaderFeedbackBubbleResolver
extends RefCounted

const COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const COMIC_BUBBLE_TEXT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_text_resolver.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")
const COMMS_LINES_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/comms_lines_resolver.gd")

const SOURCE_ID: String = "fireteamleader_command_feedback"
const DEFAULT_ENABLED: bool = true
const DEFAULT_MODE: String = "normal"
const DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL: int = 4
const DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT: int = 1

const STATE_ACCEPTED: String = "accepted"
const STATE_BLOCKED: String = "blocked"
const STATE_RUNNING: String = "running"
const STATE_DONE: String = "done"
const STATE_CONTACT: String = "contact"
const STATE_COVER: String = "cover"

const SKILL_TIER_LOW: String = "low"
const SKILL_TIER_HIGH: String = "high"
const SKILL_TIER_NEUTRAL: String = "neutral"


static func get_default_settings() -> Dictionary:
	return {
		"enabled": DEFAULT_ENABLED,
		"mode": DEFAULT_MODE,
		"max_active_bubbles_total": DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL,
		"max_active_bubbles_per_unit": DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT,
	}


static func normalize_settings(settings: Dictionary = {}) -> Dictionary:
	var result: Dictionary = get_default_settings()
	result.merge(settings, true)
	result["enabled"] = bool(result.get("enabled", DEFAULT_ENABLED))
	result["mode"] = String(result.get("mode", DEFAULT_MODE)).strip_edges().to_lower()
	if String(result.get("mode", "")).is_empty():
		result["mode"] = DEFAULT_MODE
	result["max_active_bubbles_total"] = maxi(int(result.get("max_active_bubbles_total", DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL)), 1)
	result["max_active_bubbles_per_unit"] = maxi(int(result.get("max_active_bubbles_per_unit", DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT)), 1)
	return result


static func build_command_feedback(
	feedback_action: String,
	feedback_state: String,
	leader,
	anchor_position: Vector2,
	settings: Dictionary = {},
	context: Dictionary = {}
) -> Dictionary:
	var normalized_settings: Dictionary = normalize_settings(settings)
	if not bool(normalized_settings.get("enabled", DEFAULT_ENABLED)):
		return {}
	var action: String = _normalize_action(feedback_action)
	var state: String = _normalize_state(feedback_state, action)
	var character_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("resolve_ftl_context", leader, Array(context.get("fireteam_units", [])), context))
	var skill_tier: String = String(character_context.get("skill_tier", "")).strip_edges()
	if skill_tier.is_empty():
		skill_tier = resolve_skill_tier(leader)
	var bubble_id: String = _resolve_bubble_id(action, state)
	var text_context: Dictionary = context.duplicate(true)
	text_context["skill_tier"] = skill_tier
	text_context["character_gameplay_context"] = character_context
	var text_payload: Dictionary = Dictionary(COMMS_LINES_RESOLVER_SCRIPT.call("resolve_feedback_text_payload", action, state, leader, text_context))
	if not bool(text_payload.get("ok", false)):
		text_payload = Dictionary(COMIC_BUBBLE_TEXT_RESOLVER_SCRIPT.call(
			"resolve_ftl_text_payload",
			action,
			state,
			leader,
			text_context
		))
	var text: String = String(text_payload.get("text", ""))
	if text.is_empty():
		text = _resolve_text(action, state, skill_tier)
	var modifiers: Dictionary = Dictionary(character_context.get("gameplay_modifiers", {}))
	var duration_seconds: float = clampf(
		_resolve_duration_seconds(state, skill_tier) * float(modifiers.get("feedback_duration_multiplier", 1.0)),
		1.2,
		2.4
	)
	var unit_id: String = _resolve_unit_id(leader, String(context.get("unit_id", "")))
	var payload: Dictionary = Dictionary(COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT.call(
		"build_display_payload",
		bubble_id,
		text,
		anchor_position,
		unit_id,
		{"duration_seconds": duration_seconds}
	))
	if not bool(payload.get("ok", false)):
		return payload
	payload["source"] = SOURCE_ID
	payload["feedback_action"] = action
	payload["feedback_state"] = state
	payload["skill_tier"] = skill_tier
	payload["text_source"] = String(text_payload.get("text_source", ""))
	payload["text_key"] = String(text_payload.get("text_key", ""))
	payload["comms_trigger"] = String(text_payload.get("trigger", ""))
	payload["communication_quality_level"] = int(text_payload.get("quality_level", -1))
	payload["communication_delay_seconds"] = float(text_payload.get("delay_seconds", 0.0))
	payload["fireteam_id"] = String(context.get("fireteam_id", "")).strip_edges().to_lower()
	payload["detail"] = String(context.get("detail", "")).strip_edges()
	payload["settings_mode"] = String(normalized_settings.get("mode", DEFAULT_MODE))
	payload["character_gameplay_source"] = String(character_context.get("source", ""))
	payload["character_morale_state"] = String(character_context.get("morale_state", ""))
	payload["character_frustration_state"] = String(character_context.get("frustration_state", ""))
	payload["character_teamfit_label"] = String(character_context.get("cohesion_label", ""))
	payload["ftl_clarity_label"] = String(character_context.get("ftl_clarity_label", ""))
	payload["communication_modifier"] = float(modifiers.get("communication_modifier", 0.0))
	payload["coordination_modifier"] = float(modifiers.get("coordination_modifier", 0.0))
	return payload


static func resolve_skill_tier(leader) -> String:
	var skill_tier: String = String(COMIC_BUBBLE_TEXT_RESOLVER_SCRIPT.call("resolve_skill_tier", leader, {"channel": "ftl"}))
	return SKILL_TIER_NEUTRAL if skill_tier.is_empty() else skill_tier


static func _normalize_action(feedback_action: String) -> String:
	var action: String = feedback_action.strip_edges().to_lower()
	match action:
		"engage", "attack", "contact":
			return "engage"
		"defend", "cover", "hold":
			return "defend"
		"take", "objective", "capture":
			return "take"
		"go", "execute", "next":
			return "go"
		"heal", "support", "medbay":
			return "support"
		"flank":
			return "flank"
		"move":
			return "move"
		_:
			return "move" if action.is_empty() else action


static func _normalize_state(feedback_state: String, action: String) -> String:
	var state: String = feedback_state.strip_edges().to_lower()
	match state:
		"ok", "ack", "accepted", "accept":
			return STATE_ACCEPTED
		"invalid", "failed", "blocked", "reject", "rejected":
			return STATE_BLOCKED
		"active", "running", "continue", "continuing":
			return STATE_RUNNING
		"done", "complete", "completed":
			return STATE_DONE
		"contact", "danger":
			return STATE_CONTACT
		"cover", "covered":
			return STATE_COVER
		_:
			if action == "engage":
				return STATE_CONTACT
			if action == "defend":
				return STATE_COVER
			if action == "take":
				return STATE_RUNNING
			return STATE_ACCEPTED


static func _resolve_bubble_id(action: String, state: String) -> String:
	match state:
		STATE_BLOCKED:
			return "bubble_ftl_warning"
		STATE_CONTACT:
			return "bubble_ftl_contact"
		STATE_DONE:
			return "bubble_command_confirm"
		STATE_RUNNING:
			return "bubble_command_confirm" if action == "take" else "bubble_ftl_short_order"
		STATE_COVER:
			return "bubble_ftl_short_order"
		_:
			if action == "engage":
				return "bubble_ftl_contact"
			if action == "take":
				return "bubble_command_confirm"
			return "bubble_ftl_ack"


static func _resolve_text(action: String, state: String, skill_tier: String) -> String:
	var high_skill: bool = skill_tier == SKILL_TIER_HIGH
	match state:
		STATE_BLOCKED:
			return "Nicht moeglich.\nNeuer Punkt." if high_skill else "Geht nicht.\nNeuer Punkt?"
		STATE_CONTACT:
			return "Kontakt.\nFeuer frei." if high_skill else "Kontakt da.\nIch halte drauf."
		STATE_COVER:
			return "In Deckung.\nSektor halten." if high_skill else "Deckung suchen.\nIch halte hier."
		STATE_RUNNING:
			if action == "take":
				return "Objective laeuft.\nWir nehmen es." if high_skill else "Zum Objective.\nWir versuchen's."
			return "Laeuft.\nNaechster Schritt." if high_skill else "Bin dran.\nWeiter."
		STATE_DONE:
			return "Auftrag erledigt." if high_skill else "Fertig.\nSoweit klar."
		_:
			match action:
				"move":
					return "Verstanden.\nRuecke vor." if high_skill else "Okay.\nIch geh los."
				"defend":
					return "In Deckung.\nSektor halten." if high_skill else "Halte hier.\nDeckung suchen."
				"flank":
					return "Flanke laeuft.\nLeise vor." if high_skill else "Flanke.\nIch probier's."
				"take":
					return "Objective laeuft.\nWir nehmen es." if high_skill else "Zum Objective.\nWir versuchen's."
				"support":
					return "Support kommt.\nHalte durch." if high_skill else "Bin unterwegs.\nBleib liegen."
				"go":
					return "GO bestaetigt.\nAusfuehren." if high_skill else "GO gehoert.\nWir gehen."
				_:
					return "Verstanden." if high_skill else "Okay."


static func _resolve_duration_seconds(state: String, skill_tier: String) -> float:
	if state == STATE_BLOCKED:
		return 2.2
	if state == STATE_CONTACT:
		return 2.0
	return 1.7 if skill_tier == SKILL_TIER_HIGH else 1.9


static func _resolve_unit_id(leader, fallback: String = "") -> String:
	if leader != null and leader.has_method("get_unit_id"):
		return String(leader.call("get_unit_id")).strip_edges()
	return fallback.strip_edges()


static func _call_float(target, method_name: String, fallback: float) -> float:
	if target != null and target.has_method(method_name):
		return float(target.call(method_name))
	return fallback
