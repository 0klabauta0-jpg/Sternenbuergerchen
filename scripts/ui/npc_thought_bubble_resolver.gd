class_name NPCThoughtBubbleResolver
extends RefCounted

const COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_visual_contract.gd")
const COMIC_BUBBLE_TEXT_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_text_resolver.gd")
const CHARACTER_GAMEPLAY_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/character_gameplay_resolver.gd")

const SOURCE_ID: String = "npc_thought_peek"
const THOUGHT_STATE: String = "thought"


static func build_unit_thought(unit, settings: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if unit == null or not (unit is Node2D):
		return {}
	var text_payload: Dictionary = Dictionary(COMIC_BUBBLE_TEXT_RESOLVER_SCRIPT.call("resolve_npc_thought_text_payload", unit, context))
	var text: String = String(text_payload.get("text", ""))
	if text.strip_edges().is_empty():
		text = _resolve_text(unit, context)
	if text.strip_edges().is_empty():
		return {}
	var character_context: Dictionary = Dictionary(CHARACTER_GAMEPLAY_RESOLVER_SCRIPT.call("resolve_thought_context", unit, context))
	var bubble_id: String = _resolve_bubble_id(unit, context, character_context)
	var unit_id: String = String(unit.call("get_unit_id")).strip_edges() if unit.has_method("get_unit_id") else String(context.get("unit_id", "")).strip_edges()
	var payload: Dictionary = Dictionary(COMIC_BUBBLE_VISUAL_CONTRACT_SCRIPT.call(
		"build_display_payload",
		bubble_id,
		text,
		(unit as Node2D).global_position,
		unit_id,
		{"duration_seconds": float(settings.get("duration_seconds", 1.4))}
	))
	if not bool(payload.get("ok", false)):
		return payload
	payload["source"] = SOURCE_ID
	payload["category"] = "npc_thought_peek"
	payload["feedback_state"] = THOUGHT_STATE
	payload["thought_kind"] = _resolve_thought_kind(unit, context, character_context)
	payload["text_source"] = String(text_payload.get("text_source", ""))
	payload["text_key"] = String(text_payload.get("text_key", ""))
	payload["skill_tier"] = String(text_payload.get("skill_tier", ""))
	payload["role_text_key"] = String(text_payload.get("role_key", ""))
	payload["situation_key"] = String(text_payload.get("situation_key", ""))
	payload["fireteam_id"] = _get_string(unit, "get_fireteam_id", String(context.get("fireteam_id", ""))).strip_edges().to_lower()
	payload["role_id"] = _get_string(unit, "get_role_id", "").strip_edges().to_lower()
	payload["vital_state"] = _get_string(unit, "get_vital_state", "fit").strip_edges().to_lower()
	payload["selected"] = bool(context.get("selected", false))
	payload["character_morale_state"] = String(text_payload.get("character_morale_state", character_context.get("morale_state", "")))
	payload["character_frustration_state"] = String(text_payload.get("character_frustration_state", character_context.get("frustration_state", "")))
	payload["character_teamfit_label"] = String(text_payload.get("character_teamfit_label", character_context.get("teamfit_label", "")))
	payload["character_relationship_hint"] = String(text_payload.get("character_relationship_hint", character_context.get("relationship_hint", "")))
	payload["character_thought_key"] = String(text_payload.get("character_thought_key", character_context.get("thought_key", "")))
	payload["character_gameplay_source"] = String(text_payload.get("character_gameplay_source", character_context.get("source", "")))
	payload["priority"] = _resolve_priority(unit, context, character_context)
	payload["spoiler_safe"] = true
	return payload


static func build_thoughts_for_units(units: Array, settings: Dictionary = {}, context: Dictionary = {}) -> Array:
	var result: Array = []
	for unit in units:
		var unit_context: Dictionary = context.duplicate(true)
		var selected_fireteam_ids: PackedStringArray = PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
		var fireteam_id: String = _get_string(unit, "get_fireteam_id", "").strip_edges().to_lower()
		unit_context["selected"] = selected_fireteam_ids.is_empty() or selected_fireteam_ids.has(fireteam_id)
		var payload: Dictionary = build_unit_thought(unit, settings, unit_context)
		if bool(payload.get("ok", false)):
			result.append(payload)
	result.sort_custom(Callable(NPCThoughtBubbleResolver, "_sort_by_priority_desc"))
	return result


static func _resolve_bubble_id(unit, context: Dictionary, character_context: Dictionary = {}) -> String:
	var vital_state: String = _get_string(unit, "get_vital_state", "fit").strip_edges().to_lower()
	var health_ratio: float = _health_ratio(unit)
	if vital_state != "fit" or health_ratio < 0.55:
		return "bubble_npc_status_low"
	if String(character_context.get("frustration_state", "")) == "high" or String(character_context.get("morale_state", "")) == "low":
		return "bubble_npc_status_low"
	if bool(context.get("selected", false)) or bool(unit.get("is_fireteam_lead")):
		return "bubble_npc_thought_focus"
	return "bubble_npc_thought_quiet"


static func _resolve_text(unit, context: Dictionary) -> String:
	var vital_state: String = _get_string(unit, "get_vital_state", "fit").strip_edges().to_lower()
	var role_id: String = _get_string(unit, "get_role_id", "").strip_edges().to_lower()
	var health_ratio: float = _health_ratio(unit)
	# Ersatztexte: ganze deutsche Saetze, die man ohne Vorwissen versteht.
	if vital_state == "down" or vital_state == "bleedout":
		return "Ich liege am Boden und brauche Hilfe."
	if vital_state == "respawning":
		return "Holt mich zurück, ich bin noch da."
	if health_ratio < 0.55:
		return "Ich bin getroffen, aber ich halte durch."
	if _has_current_command(unit):
		return "Ich habe den Befehl und bin unterwegs."
	if bool(unit.get("is_fireteam_lead")):
		return "Mein Trupp bleibt bei mir."
	match role_id:
		"medic", "combat_medic", "field_medic":
			return "Ich habe die Verwundeten im Blick und bleibe nah."
		"pilot", "dropship_pilot":
			return "Ich habe die Landezone im Kopf."
		"heavy", "support", "specialist":
			return "Mein schweres Gerät ist bereit."
		"engineer":
			return "Die Technik ist klar, es kann weitergehen."
		_:
			if bool(context.get("selected", false)):
				return "Ich sichere die Umgebung, alles ruhig."
			return "Ich bleibe ruhig und halte die Augen offen."


static func _resolve_thought_kind(unit, context: Dictionary, character_context: Dictionary = {}) -> String:
	var character_thought_key: String = String(character_context.get("thought_key", "")).strip_edges()
	if not character_thought_key.is_empty():
		return "character:%s" % character_thought_key
	var vital_state: String = _get_string(unit, "get_vital_state", "fit").strip_edges().to_lower()
	if vital_state != "fit" or _health_ratio(unit) < 0.55:
		return "health"
	if _has_current_command(unit):
		return "order"
	if bool(unit.get("is_fireteam_lead")):
		return "leader"
	var role_id: String = _get_string(unit, "get_role_id", "").strip_edges().to_lower()
	return "role:%s" % role_id if not role_id.is_empty() else "status"


static func _resolve_priority(unit, context: Dictionary, character_context: Dictionary = {}) -> int:
	var priority: int = 10
	if bool(context.get("selected", false)):
		priority += 35
	if bool(unit.get("is_fireteam_lead")):
		priority += 25
	var vital_state: String = _get_string(unit, "get_vital_state", "fit").strip_edges().to_lower()
	if vital_state == "down" or vital_state == "bleedout":
		priority += 100
	elif vital_state != "fit" or _health_ratio(unit) < 0.55:
		priority += 70
	if _has_current_command(unit):
		priority += 20
	priority += int(character_context.get("thought_priority_bonus", 0))
	return priority


static func _health_ratio(unit) -> float:
	if unit == null or not unit.has_method("get_health") or not unit.has_method("get_max_health_points"):
		return 1.0
	var max_health: int = maxi(int(unit.call("get_max_health_points")), 1)
	return clampf(float(unit.call("get_health")) / float(max_health), 0.0, 1.0)


static func _has_current_command(unit) -> bool:
	if unit == null or not unit.has_method("get_current_unit_command"):
		return false
	return unit.call("get_current_unit_command") != null


static func _get_string(unit, method_name: String, fallback: String) -> String:
	if unit != null and unit.has_method(method_name):
		return String(unit.call(method_name))
	return fallback


static func _sort_by_priority_desc(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = int(a.get("priority", 0))
	var b_priority: int = int(b.get("priority", 0))
	if a_priority != b_priority:
		return a_priority > b_priority
	return String(a.get("unit_id", "")) < String(b.get("unit_id", ""))
