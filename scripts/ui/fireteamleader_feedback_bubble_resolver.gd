class_name FireteamleaderFeedbackBubbleResolver
extends RefCounted

const COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const COMIC_BUBBLE_TEXT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_text_resolver.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")
const TACTICAL_COMMUNICATION_COPY_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_copy.gd")

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

const VALIDATION_SOURCE_DEFAULT: String = "controller_feedback"
const VALIDATION_TEXT_SOURCE: String = "command_validation"
const VALIDATION_PRIORITY: int = 120


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
	var validation_feedback: Dictionary = _resolve_validation_feedback(state, action, context)
	var character_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("resolve_ftl_context", leader, Array(context.get("fireteam_units", [])), context))
	var skill_tier: String = String(character_context.get("skill_tier", "")).strip_edges()
	if skill_tier.is_empty():
		skill_tier = resolve_skill_tier(leader)
	var bubble_id: String = _resolve_bubble_id(action, state)
	var text_context: Dictionary = context.duplicate(true)
	text_context["skill_tier"] = skill_tier
	text_context["character_gameplay_context"] = character_context
	# Einzige Satzquelle: data/tactical_communication_copy.json (ueber TacticalCommunicationCopy).
	# Befehlskontext, comms_lines und comic_bubble_text_catalog liefern hier keinen Satz mehr.
	var text_payload: Dictionary = {}
	if not validation_feedback.is_empty():
		text_payload = {
			"ok": true,
			"text": String(validation_feedback.get("message", "")),
			"text_source": VALIDATION_TEXT_SOURCE,
			"text_key": "command_validation.%s" % String(validation_feedback.get("validation_key", "")),
			"trigger": "command_validation",
			"quality_level": -1,
			"delay_seconds": 0.0,
		}
	else:
		text_payload = Dictionary(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("command_text", action, state, skill_tier, text_context))
		text_payload["ok"] = not text_payload.is_empty()
		text_payload["trigger"] = String(text_context.get("comms_trigger", "order_confirmed"))
		text_payload["quality_level"] = -1
		text_payload["delay_seconds"] = 0.0
	var text: String = String(text_payload.get("text", "")).replace("\n", " ").strip_edges()
	if text.is_empty():
		text = String(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("validation_text", "default"))
	var important: bool = bool(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("is_important", int(validation_feedback.get("priority", 0)), state))
	var duration_seconds: float = float(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("duration_for_text", text, important))
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
	var modifiers: Dictionary = Dictionary(character_context.get("gameplay_modifiers", {}))
	# Ganzer Satz in einer Zeile; die HUD-Blase bricht selbst um (sonst kuerzt der Bildvertrag auf zwei Zeilen).
	payload["text"] = text
	payload["duration_seconds"] = duration_seconds
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
	if not validation_feedback.is_empty():
		payload["validation_key"] = String(validation_feedback.get("validation_key", ""))
		payload["validation_detail"] = String(validation_feedback.get("validation_detail", ""))
		payload["validation_source"] = String(validation_feedback.get("validation_source", VALIDATION_SOURCE_DEFAULT))
		payload["validation_message"] = String(validation_feedback.get("message", ""))
		payload["priority"] = maxi(int(payload.get("priority", 0)), int(validation_feedback.get("priority", VALIDATION_PRIORITY)))
	return payload


static func resolve_validation_feedback(feedback_action: String, feedback_state: String, context: Dictionary = {}) -> Dictionary:
	var action: String = _normalize_action(feedback_action)
	var state: String = _normalize_state(feedback_state, action)
	return _resolve_validation_feedback(state, action, context)


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


static func _resolve_validation_feedback(state: String, action: String, context: Dictionary) -> Dictionary:
	if state != STATE_BLOCKED:
		return {}
	if not String(context.get("tactical_event_type", "")).strip_edges().is_empty() and String(context.get("validation_key", "")).strip_edges().is_empty():
		# Ereignisse tragen ihren Satz selbst; ihre Detailzeile ist keine Pruefmeldung.
		return {}
	var raw_key: String = String(context.get("validation_key", "")).strip_edges()
	if raw_key.is_empty():
		raw_key = String(context.get("validation_detail", "")).strip_edges()
	if raw_key.is_empty():
		raw_key = String(context.get("detail", "")).strip_edges()
	if raw_key.is_empty():
		raw_key = String(context.get("blocked_reason", context.get("reason", ""))).strip_edges()
	var validation_key: String = _normalize_validation_key(raw_key)
	if validation_key.is_empty():
		return {}
	var message: String = String(context.get("validation_message", "")).strip_edges()
	if message.is_empty():
		message = _validation_message_for_key(validation_key, action)
	return {
		"validation_key": validation_key,
		"validation_detail": raw_key,
		"validation_source": String(context.get("validation_source", VALIDATION_SOURCE_DEFAULT)).strip_edges(),
		"message": message,
		"priority": VALIDATION_PRIORITY,
	}


static func _normalize_validation_key(raw_key: String) -> String:
	var key: String = raw_key.strip_edges().to_lower()
	if key.is_empty():
		return ""
	key = key.replace("-", "_").replace(" ", "_")
	match key:
		"no_tile", "select_tile", "select_a_map_tile", "map_tile", "map_tile_required", "requires_tile_selection", "tile_required":
			return "select_tile_first"
		"select_tile_first":
			return "select_tile_first"
		"observer", "observer_mode", "host_controls_mission_commands", "host_controls_mission_command", "remote_client":
			return "observer_mode"
		"inactive", "wait_for_insertion", "insertion_pending", "not_inserted":
			return "wait_for_insertion"
		"failed", "blocked", "blocked_route", "route_blocked", "path_blocked", "cannot_reach":
			return "blocked_route"
		"no_los", "line_of_sight_blocked", "los_blocked":
			return "no_los"
		"too_far", "out_of_range", "range_blocked":
			return "too_far"
		"no_orders", "needs_orders":
			return "no_orders"
		"no_contact", "ad_hoc_no_contact":
			return "no_contact"
		"no_fireteam", "select_fireteam", "select_fireteam_first", "select_one_or_more_fireteams":
			return "select_fireteam_first"
		"no_lz", "set_lz_before_drop_call", "set_lz_first":
			return "set_lz_first"
		"drop_cooldown", "dropship_cooldown":
			return "drop_cooldown"
		"dropship_unavailable", "drop_ship_not_on_mission_map", "drop_unavailable", "no_drop_team_available":
			return "dropship_unavailable"
		_:
			return key


static func _validation_message_for_key(validation_key: String, _action: String) -> String:
	# Verstaendliche Meldungen stehen in data/tactical_communication_copy.json (Abschnitt "validation").
	return String(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("validation_text", validation_key))


static func _resolve_unit_id(leader, fallback: String = "") -> String:
	if leader != null and leader.has_method("get_unit_id"):
		return String(leader.call("get_unit_id")).strip_edges()
	return fallback.strip_edges()


static func _call_float(target, method_name: String, fallback: float) -> float:
	if target != null and target.has_method(method_name):
		return float(target.call(method_name))
	return fallback
