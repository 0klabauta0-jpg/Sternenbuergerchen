class_name TacticalCommunicationResolver
extends RefCounted

const TACTICAL_COMMUNICATION_EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")
const FIRETEAMLEADER_FEEDBACK_BUBBLE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/ui/fireteamleader_feedback_bubble_resolver.gd")
const TACTICAL_COMMUNICATION_COPY_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_copy.gd")
const PERSONALITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/personality_catalog.gd")
const TRUPP_FARBEN_SCRIPT: GDScript = preload("res://scripts/tactical/trupp_farben.gd")

const COPY_CATALOG_PATH: String = "res://data/tactical_communication_copy.json"
const SOURCE_ID: String = "tactical_communication_feedback"
const DEFAULT_COOLDOWN_MSEC: int = 1100
const CRITICAL_COOLDOWN_MSEC: int = 450
const DEFAULT_MAX_EVENTS: int = 5
const DEFAULT_MAX_PER_CHANNEL: int = 3

static var _copy_catalog_cache: Dictionary = {}
static var _copy_catalog_cache_loaded: bool = false

var _last_emit_msec_by_key: Dictionary = {}


static func build_event(event_type: String, context: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	var normalized_type: String = TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("normalize_event_type", event_type)
	var copy_entry: Dictionary = _copy_entry_for_type(normalized_type)
	var trigger_entry: Dictionary = TACTICAL_COMMUNICATION_COPY_SCRIPT.call("trigger_entry", String(context.get("copy_trigger", "")))
	var has_catalog_copy: bool = not copy_entry.is_empty() or not trigger_entry.is_empty()
	if not trigger_entry.is_empty():
		# Der Ausloeser (z. B. Sanitaeter, Munition) bestimmt Anlass und Kartentext; die Ereignisart liefert Prioritaet und Kanaele.
		copy_entry = copy_entry.duplicate(true)
		copy_entry["map_label"] = trigger_entry.get("map_label", copy_entry.get("map_label", ""))
	var skill_tier: String = _resolve_skill_tier(context)
	var occasion: String = String(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("occasion_for_event", normalized_type, String(context.get("copy_trigger", ""))))
	# Eine Satzquelle: data/comms/funk_saetze.json (Anlass + Persoenlichkeit + Funkguete). Gibt es dort einen Satz, gewinnt er
	# gegen mitgegebene Texte; die Detailzeile darf vom Aufrufer kommen. Dieser Satz zaehlt den Anlass nicht weiter (die Blase tut es).
	var funk_text: String = ""
	if not occasion.is_empty():
		funk_text = String(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("leader_text", occasion, PERSONALITY_CATALOG_SCRIPT.normalize(context.get("personality", "")), skill_tier, _funk_seed_key(context), context, false))
	var short_text: String = funk_text if not funk_text.is_empty() else _format_copy(String(context.get("short_text", "")).strip_edges(), context, skill_tier)
	var detail_text: String = _format_copy(String(context.get("detail_text", short_text)).strip_edges(), context, skill_tier)
	var map_label_template: String = String(copy_entry.get("map_label", "")) if has_catalog_copy and not String(copy_entry.get("map_label", "")).is_empty() else String(context.get("map_label", copy_entry.get("map_label", short_text)))
	var map_label: String = _format_copy(map_label_template.strip_edges(), context, skill_tier)
	var phase: int = maxi(int(context.get("phase", context.get("plan_phase_index", options.get("phase", 0)))), 0)
	var fireteam_id: String = String(context.get("fireteam_id", "")).strip_edges().to_lower()
	var unit_id: String = String(context.get("unit_id", context.get("leader_unit_id", ""))).strip_edges()
	var priority: int = int(context.get("priority", options.get("priority", copy_entry.get("priority", TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("default_priority_for_event_type", normalized_type)))))
	var channels: Variant = context.get("channels", options.get("channels", copy_entry.get("channels", TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("default_channels_for_event_type", normalized_type))))
	var event_id: String = String(context.get("event_id", options.get("event_id", ""))).strip_edges()
	if event_id.is_empty():
		event_id = String(TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("build_stable_event_id", normalized_type, {
			"plan_id": String(context.get("plan_id", options.get("plan_id", ""))),
			"fireteam_id": fireteam_id,
			"unit_id": unit_id,
			"phase": phase,
			"role": String(context.get("role", context.get("role_label", ""))),
			"step": String(context.get("step", context.get("next_step", ""))),
		}))
	var event_data: Dictionary = {
		"event_id": event_id,
		"event_type": normalized_type,
		"fireteam_id": fireteam_id,
		"unit_id": unit_id,
		"priority": priority,
		"duration_seconds": float(context.get("duration_seconds", copy_entry.get("duration_seconds", TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("default_duration_for_event_type", normalized_type)))),
		"channels": channels,
		"feedback_action": String(context.get("feedback_action", copy_entry.get("feedback_action", TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("default_feedback_action_for_event_type", normalized_type)))),
		"feedback_state": String(context.get("feedback_state", copy_entry.get("feedback_state", TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("default_feedback_state_for_event_type", normalized_type)))),
		"short_text": short_text,
		"detail_text": detail_text,
		"map_label": map_label,
		"phase": phase,
		"created_msec": maxi(int(options.get("now_msec", Time.get_ticks_msec())), 0),
		"source": SOURCE_ID,
		"visual_only": true,
		"metadata": _build_public_metadata(context, skill_tier),
		"speech": {
			"occasion": occasion,
			"skill_tier": skill_tier,
			"team": str(context.get("team", context.get("display_label", ""))),
			"direction_label": str(context.get("direction_label", context.get("direction", ""))),
			"objective_label": str(context.get("objective_label", "")),
		},
	}
	if typeof(context.get("anchor_position", null)) == TYPE_VECTOR2:
		event_data["anchor_position"] = Vector2(context.get("anchor_position"))
	elif typeof(context.get("planned_position", null)) == TYPE_VECTOR2:
		event_data["anchor_position"] = Vector2(context.get("planned_position"))
	elif typeof(context.get("position", null)) == TYPE_VECTOR2:
		event_data["anchor_position"] = Vector2(context.get("position"))
	if typeof(context.get("target_position", null)) == TYPE_VECTOR2:
		event_data["target_position"] = Vector2(context.get("target_position"))
	var event = TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("from_dict", event_data)
	return Dictionary(event.call("to_snapshot")) if event != null and event.has_method("to_snapshot") else {}


func resolve_events(raw_events: Array, options: Dictionary = {}) -> Array:
	var normalized_events: Array = []
	for raw_variant in raw_events:
		var event: Dictionary = _normalize_raw_event(raw_variant, options)
		if event.is_empty():
			continue
		normalized_events.append(event)
	normalized_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority: int = int(a.get("priority", 0))
		var b_priority: int = int(b.get("priority", 0))
		if a_priority == b_priority:
			return String(a.get("event_id", "")) < String(b.get("event_id", ""))
		return a_priority > b_priority
	)

	var now_msec: int = maxi(int(options.get("now_msec", Time.get_ticks_msec())), 0)
	var max_events: int = maxi(int(options.get("max_events", DEFAULT_MAX_EVENTS)), 1)
	var max_per_channel: int = maxi(int(options.get("max_per_channel", DEFAULT_MAX_PER_CHANNEL)), 1)
	var channel_counts: Dictionary = {}
	var emitted: Array = []
	for event_variant in normalized_events:
		var event: Dictionary = Dictionary(event_variant)
		if not _passes_cooldown(event, now_msec, options):
			continue
		if not _has_available_channel(event, channel_counts, max_per_channel):
			continue
		emitted.append(event)
		_mark_channels(event, channel_counts)
		_mark_cooldown(event, now_msec, options)
		if emitted.size() >= max_events:
			break
	return emitted


func reset_cooldowns() -> void:
	_last_emit_msec_by_key.clear()


static func clear_copy_catalog_cache() -> void:
	_copy_catalog_cache.clear()
	_copy_catalog_cache_loaded = false
	TACTICAL_COMMUNICATION_COPY_SCRIPT.call("clear_cache")


static func build_events_for_multi_fireteam_plan(plan: Dictionary, options: Dictionary = {}) -> Array:
	var events: Array = []
	var plan_id: String = String(plan.get("plan_id", options.get("plan_id", ""))).strip_edges()
	var phase: int = maxi(int(plan.get("phase", options.get("phase", 0))), 0)
	var target_position = plan.get("target_position", null)
	events.append(build_event(TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_PHASE_STARTED, {
		"plan_id": plan_id,
		"phase": phase,
		"role": "plan",
		"step": String(plan.get("status", "")),
		"target_position": target_position,
		"anchor_position": target_position,
		"detail": String(plan.get("mission_control_text", "")),
		"channels": PackedStringArray([
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MISSION_CONTROL,
			TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MAP_MARKER,
		]),
	}, options))
	for assignment_variant in Array(plan.get("role_assignments", [])):
		if typeof(assignment_variant) != TYPE_DICTIONARY:
			continue
		var assignment: Dictionary = Dictionary(assignment_variant)
		var base_context: Dictionary = {
			"plan_id": plan_id,
			"phase": int(assignment.get("plan_phase_index", phase)),
			"fireteam_id": String(assignment.get("fireteam_id", "")),
			"unit_id": String(Dictionary(assignment.get("ftl_public_snapshot", {})).get("unit_id", "")),
			"team": String(assignment.get("display_label", assignment.get("fireteam_id", ""))).to_upper(),
			"display_label": String(assignment.get("display_label", assignment.get("fireteam_id", ""))).to_upper(),
			"role": String(assignment.get("role", "")),
			"role_label": String(assignment.get("role_label", "")),
			"step": String(assignment.get("next_step", "")),
			"next_step": String(assignment.get("next_step", "")),
			"planned_position": assignment.get("planned_position", null),
			"target_position": target_position,
			"ftl_public_snapshot": Dictionary(assignment.get("ftl_public_snapshot", {})).duplicate(true),
			"communication_clarity": float(assignment.get("communication_clarity", 0.5)),
			"detail": "%s %s" % [String(assignment.get("role_label", "")), String(assignment.get("next_step", ""))],
		}
		events.append(build_event(TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED, base_context, options))
		var status: String = String(assignment.get("status", "")).strip_edges().to_lower()
		if status == "blocked_path" or bool(assignment.get("blocked_path", false)):
			var blocked_context: Dictionary = base_context.duplicate(true)
			blocked_context["priority"] = TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL
			blocked_context["step"] = "blocked"
			events.append(build_event(TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, blocked_context, options))
		elif status == "contact_stable" or float(assignment.get("contact_pressure", 0.0)) >= 0.5:
			var contact_context: Dictionary = base_context.duplicate(true)
			contact_context["priority"] = TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH
			contact_context["step"] = "contact"
			events.append(build_event(TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CONTACT_REPORT, contact_context, options))
	return events


static func build_selected_fireteam_text(events: Array, selected_fireteam_ids: PackedStringArray, limit: int = 2) -> String:
	var selected_lookup: Dictionary = {}
	for fireteam_id_variant in selected_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if not fireteam_id.is_empty():
			selected_lookup[fireteam_id] = true
	var lines: PackedStringArray = PackedStringArray()
	for event in _sort_events_for_text(events):
		if not PackedStringArray(event.get("channels", PackedStringArray())).has(TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_SELECTED_FIRETEAM):
			continue
		var fireteam_id: String = String(event.get("fireteam_id", "")).strip_edges().to_lower()
		if not selected_lookup.is_empty() and not fireteam_id.is_empty() and not selected_lookup.has(fireteam_id):
			continue
		var short_text: String = String(event.get("short_text", "")).strip_edges()
		if short_text.is_empty():
			continue
		# Mehrere Trupps im Fenster: der Satz steht in Ich-Form, daher den Trupp voranstellen.
		lines.append("%s: %s" % [TRUPP_FARBEN_SCRIPT.display_name(fireteam_id), short_text] if not fireteam_id.is_empty() else short_text)
		if lines.size() >= maxi(limit, 1):
			break
	return "\n".join(lines)


static func build_mission_control_text(events: Array, limit: int = 2) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for event in _sort_events_for_text(events):
		if not PackedStringArray(event.get("channels", PackedStringArray())).has(TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_MISSION_CONTROL):
			continue
		var text: String = String(event.get("detail_text", event.get("short_text", ""))).strip_edges()
		if text.is_empty():
			continue
		lines.append(text)
		if lines.size() >= maxi(limit, 1):
			break
	return " | ".join(lines)


static func build_bubble_payload(event: Dictionary, leader, anchor_position: Vector2, settings: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	if not PackedStringArray(event.get("channels", PackedStringArray())).has(TACTICAL_COMMUNICATION_EVENT_SCRIPT.CHANNEL_FTL_BUBBLE):
		return {}
	var payload: Dictionary = Dictionary(FIRETEAMLEADER_FEEDBACK_BUBBLE_RESOLVER_SCRIPT.call(
		"build_command_feedback",
		String(event.get("feedback_action", "move")),
		String(event.get("feedback_state", "accepted")),
		leader,
		anchor_position,
		settings,
		{
			"fireteam_id": String(event.get("fireteam_id", context.get("fireteam_id", ""))),
			"unit_id": String(event.get("unit_id", context.get("unit_id", ""))),
			"detail": String(event.get("detail_text", "")),
			"fireteam_units": Array(context.get("fireteam_units", [])),
			"tactical_event_type": String(event.get("event_type", "")),
			"event_type": String(event.get("event_type", "")),
			"active_command": String(event.get("feedback_action", "")),
			"personality": String(context.get("personality", "")),
			"funk_peek": true,
		}
	))
	if not bool(payload.get("ok", false)):
		return {}
	# Einzige Satzquelle: data/comms/funk_saetze.json. Der Satz des Ereignisses wird hier mit der Persoenlichkeit des
	# Truppfuehrers gewaehlt; der Ersatz aus der Befehlsrueckmeldung gilt nur, wenn das Ereignis keinen Anlass hat.
	var speech: Dictionary = Dictionary(event.get("speech", {}))
	var occasion: String = String(speech.get("occasion", "")).strip_edges()
	var event_text: String = String(event.get("short_text", "")).strip_edges()
	if not occasion.is_empty():
		var fill_context: Dictionary = {
			"team": String(speech.get("team", "")),
			"fireteam_id": String(event.get("fireteam_id", context.get("fireteam_id", ""))),
			"direction_label": String(speech.get("direction_label", "")),
			"objective_label": String(speech.get("objective_label", "")),
		}
		var seed_key: String = String(event.get("unit_id", "")).strip_edges()
		if seed_key.is_empty() and leader != null and leader is Object and leader.has_method("get_unit_id"):
			seed_key = String(leader.call("get_unit_id")).strip_edges()
		if seed_key.is_empty():
			seed_key = String(event.get("fireteam_id", "")).strip_edges().to_lower()
		var spoken: String = String(TACTICAL_COMMUNICATION_COPY_SCRIPT.call(
			"leader_text",
			occasion,
			FIRETEAMLEADER_FEEDBACK_BUBBLE_RESOLVER_SCRIPT.call("resolve_leader_personality", leader, context),
			String(speech.get("skill_tier", "neutral")),
			seed_key,
			fill_context,
			true
		))
		if not spoken.is_empty():
			event_text = spoken
	if not event_text.is_empty():
		payload["text"] = event_text.replace("\n", " ")
		payload["text_source"] = TACTICAL_COMMUNICATION_COPY_SCRIPT.TEXT_SOURCE_ID
		payload["text_key"] = "events.%s" % String(event.get("event_type", ""))
	payload["source"] = SOURCE_ID
	payload["tactical_communication_event_id"] = String(event.get("event_id", ""))
	payload["tactical_communication_event_type"] = String(event.get("event_type", ""))
	payload["priority"] = int(event.get("priority", 0))
	payload["channels"] = PackedStringArray(event.get("channels", PackedStringArray()))
	payload["duration_seconds"] = float(TACTICAL_COMMUNICATION_COPY_SCRIPT.call(
		"duration_for_text",
		String(payload.get("text", "")),
		bool(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("is_important", int(event.get("priority", 0)), String(event.get("feedback_state", ""))))
	))
	payload["category"] = "ftl_command_feedback"
	return payload


func _normalize_raw_event(raw_variant, options: Dictionary) -> Dictionary:
	if typeof(raw_variant) == TYPE_DICTIONARY:
		var raw: Dictionary = Dictionary(raw_variant)
		if raw.has("event_id") and raw.has("event_type"):
			var event = TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("from_dict", raw)
			return Dictionary(event.call("to_snapshot")) if event != null and event.has_method("to_snapshot") else {}
		return build_event(String(raw.get("event_type", raw.get("type", ""))), raw, options)
	if raw_variant is String:
		return build_event(String(raw_variant), {}, options)
	return {}


func _passes_cooldown(event: Dictionary, now_msec: int, options: Dictionary) -> bool:
	var cooldown_key: String = String(event.get("cooldown_key", "")).strip_edges()
	if cooldown_key.is_empty():
		cooldown_key = "%s:%s:%s" % [String(event.get("event_type", "")), String(event.get("fireteam_id", "")), String(event.get("unit_id", ""))]
	var ready_msec: int = int(_last_emit_msec_by_key.get(cooldown_key, 0))
	return now_msec >= ready_msec


func _mark_cooldown(event: Dictionary, now_msec: int, options: Dictionary) -> void:
	var cooldown_key: String = String(event.get("cooldown_key", "")).strip_edges()
	if cooldown_key.is_empty():
		cooldown_key = "%s:%s:%s" % [String(event.get("event_type", "")), String(event.get("fireteam_id", "")), String(event.get("unit_id", ""))]
	var cooldown_msec: int = int(options.get("cooldown_msec", DEFAULT_COOLDOWN_MSEC))
	if int(event.get("priority", 0)) >= TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL:
		cooldown_msec = int(options.get("critical_cooldown_msec", CRITICAL_COOLDOWN_MSEC))
	_last_emit_msec_by_key[cooldown_key] = now_msec + maxi(cooldown_msec, 0)


static func _has_available_channel(event: Dictionary, channel_counts: Dictionary, max_per_channel: int) -> bool:
	for channel in PackedStringArray(event.get("channels", PackedStringArray())):
		if int(channel_counts.get(channel, 0)) < max_per_channel:
			return true
	return false


static func _mark_channels(event: Dictionary, channel_counts: Dictionary) -> void:
	for channel in PackedStringArray(event.get("channels", PackedStringArray())):
		channel_counts[channel] = int(channel_counts.get(channel, 0)) + 1


static func _sort_events_for_text(events: Array) -> Array:
	var result: Array = []
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY:
			result.append(Dictionary(event_variant))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_priority: int = int(a.get("priority", 0))
		var b_priority: int = int(b.get("priority", 0))
		if a_priority == b_priority:
			return int(a.get("created_msec", 0)) > int(b.get("created_msec", 0))
		return a_priority > b_priority
	)
	return result


## Schluessel fuer die Fassungswahl: die sprechende Einheit, sonst der Trupp.
static func _funk_seed_key(context: Dictionary) -> String:
	var unit_id: String = String(context.get("unit_id", context.get("leader_unit_id", ""))).strip_edges()
	return unit_id if not unit_id.is_empty() else String(context.get("fireteam_id", "")).strip_edges().to_lower()


static func _build_public_metadata(context: Dictionary, skill_tier: String) -> Dictionary:
	return {
		"plan_id": str(context.get("plan_id", "")),
		"role": str(context.get("role", "")),
		"role_label": str(context.get("role_label", "")),
		"step": str(context.get("step", context.get("next_step", ""))),
		"skill_tier": skill_tier,
		"communication_clarity": _resolve_communication_clarity(context),
	}


static func _resolve_skill_tier(context: Dictionary) -> String:
	var clarity: float = _resolve_communication_clarity(context)
	if clarity >= 0.70:
		return "high"
	if clarity < 0.42:
		return "low"
	return "neutral"


static func _resolve_communication_clarity(context: Dictionary) -> float:
	if context.has("communication_clarity"):
		return clampf(float(context.get("communication_clarity", 0.5)), 0.0, 1.0)
	var public_snapshot: Dictionary = Dictionary(context.get("ftl_public_snapshot", context.get("ftl_skill_snapshot", {})))
	if public_snapshot.has("communication_clarity"):
		return clampf(float(public_snapshot.get("communication_clarity", 0.5)), 0.0, 1.0)
	if public_snapshot.has("communication"):
		return clampf(float(public_snapshot.get("communication", 0.5)), 0.0, 1.0)
	return 0.5


static func _copy_entry_for_type(event_type: String) -> Dictionary:
	var catalog: Dictionary = _load_copy_catalog()
	return Dictionary(Dictionary(catalog.get("events", {})).get(event_type, {}))


static func _load_copy_catalog() -> Dictionary:
	return TACTICAL_COMMUNICATION_COPY_SCRIPT.call("load_catalog")


static func _format_copy(template: String, context: Dictionary, _skill_tier: String) -> String:
	return String(TACTICAL_COMMUNICATION_COPY_SCRIPT.call("format_text", template, context))
