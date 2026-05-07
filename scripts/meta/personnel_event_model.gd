class_name PersonnelEventModel
extends RefCounted

const SCHEMA_VERSION: int = 1

const EVENT_RECRUIT_AVAILABLE: String = "recruit_available"
const EVENT_JOINS_ROSTER: String = "joins_roster"
const EVENT_LEAVES_ROSTER: String = "leaves_roster"
const EVENT_DISMISSED: String = "dismissed"
const EVENT_UNAVAILABLE: String = "unavailable"
const EVENT_RETURNS: String = "returns"
const EVENT_REQUESTS_CHANGE: String = "requests_change"

const VALID_EVENT_TYPES: PackedStringArray = [
	EVENT_RECRUIT_AVAILABLE,
	EVENT_JOINS_ROSTER,
	EVENT_LEAVES_ROSTER,
	EVENT_DISMISSED,
	EVENT_UNAVAILABLE,
	EVENT_RETURNS,
	EVENT_REQUESTS_CHANGE,
]


static func make_event(
	event_type: String,
	unit_id: String = "",
	display_name: String = "",
	message: String = "",
	payload: Dictionary = {},
	requires_confirmation: bool = false
) -> Dictionary:
	var normalized_type: String = event_type.strip_edges().to_lower()
	var normalized_unit_id: String = unit_id.strip_edges().to_lower()
	var normalized_payload: Dictionary = payload.duplicate(true)
	var resolved_display_name: String = display_name.strip_edges()
	var resolved_message: String = message.strip_edges()
	if resolved_message.is_empty():
		resolved_message = _build_fallback_message(normalized_type, resolved_display_name, normalized_unit_id, normalized_payload)
	var event_id: String = _build_event_id(normalized_type, normalized_unit_id, normalized_payload, resolved_message)
	return {
		"schema_version": SCHEMA_VERSION,
		"event_id": event_id,
		"event_type": normalized_type,
		"unit_id": normalized_unit_id,
		"display_name": resolved_display_name,
		"message": resolved_message,
		"payload": normalized_payload,
		"requires_confirmation": requires_confirmation,
		"status": "pending" if requires_confirmation else "info",
		"created_at_unix_time": int(Time.get_unix_time_from_system()),
	}


static func format_event_message(event: Dictionary) -> String:
	var message: String = String(event.get("message", "")).strip_edges()
	if not message.is_empty():
		return message
	return _build_fallback_message(
		String(event.get("event_type", "")).strip_edges().to_lower(),
		String(event.get("display_name", "")).strip_edges(),
		String(event.get("unit_id", "")).strip_edges().to_lower(),
		Dictionary(event.get("payload", {}))
	)


static func validate_event(event: Dictionary) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	if event.is_empty():
		errors.append("personnel_event_missing")
		return {"valid": false, "errors": errors}
	if int(event.get("schema_version", 0)) != SCHEMA_VERSION:
		errors.append("schema_version_invalid")
	var event_type: String = String(event.get("event_type", "")).strip_edges().to_lower()
	if not VALID_EVENT_TYPES.has(event_type):
		errors.append("event_type_invalid:%s" % event_type)
	if String(event.get("event_id", "")).strip_edges().is_empty():
		errors.append("event_id_missing")
	if format_event_message(event).strip_edges().is_empty():
		errors.append("message_missing")
	if typeof(event.get("payload", {})) != TYPE_DICTIONARY:
		errors.append("payload_not_dictionary")
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


static func validate_events(events: Array) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var event_ids: Dictionary = {}
	for event_variant in events:
		if typeof(event_variant) != TYPE_DICTIONARY:
			errors.append("personnel_event_not_dictionary")
			continue
		var event: Dictionary = Dictionary(event_variant)
		var validation: Dictionary = validate_event(event)
		if not bool(validation.get("valid", false)):
			for error in PackedStringArray(validation.get("errors", PackedStringArray())):
				errors.append(error)
		var event_id: String = String(event.get("event_id", "")).strip_edges()
		if event_id.is_empty():
			continue
		if event_ids.has(event_id):
			errors.append("event_id_duplicate:%s" % event_id)
		event_ids[event_id] = true
	return {
		"valid": errors.is_empty(),
		"errors": errors,
	}


static func _build_event_id(event_type: String, unit_id: String, payload: Dictionary, message: String) -> String:
	var reason: String = String(payload.get("reason", payload.get("trigger", payload.get("milestone", "")))).strip_edges().to_lower()
	if reason.is_empty():
		reason = message.strip_edges().to_lower()
	if reason.is_empty():
		reason = "event"
	var owner: String = unit_id if not unit_id.is_empty() else String(payload.get("candidate_unit_id", payload.get("target_unit_id", "roster"))).strip_edges().to_lower()
	if owner.is_empty():
		owner = "roster"
	return "%s:%s:%s" % [event_type, _sanitize_id(owner), _sanitize_id(reason)]


static func _build_fallback_message(event_type: String, display_name: String, unit_id: String, payload: Dictionary) -> String:
	var name: String = display_name if not display_name.is_empty() else unit_id
	if name.is_empty():
		name = String(payload.get("candidate_display_name", "Roster")).strip_edges()
	match event_type:
		EVENT_RECRUIT_AVAILABLE:
			var candidate_name: String = String(payload.get("candidate_display_name", name)).strip_edges()
			return "%s ist fuer das Roster verfuegbar." % candidate_name
		EVENT_JOINS_ROSTER:
			return "%s tritt dem Roster bei." % name
		EVENT_LEAVES_ROSTER:
			return "%s verlaesst das Roster." % name
		EVENT_DISMISSED:
			return "%s wurde aus dem Roster entlassen." % name
		EVENT_UNAVAILABLE:
			return "%s ist voruebergehend nicht verfuegbar." % name
		EVENT_RETURNS:
			return "%s meldet sich wieder einsatzbereit." % name
		EVENT_REQUESTS_CHANGE:
			return "%s bittet um eine Veraenderung im Team." % name
		_:
			return "Personnel update fuer %s." % name


static func _sanitize_id(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			result += character
		elif character == "_" or character == "-":
			result += character
		elif character == " " or character == ":" or character == "/":
			result += "_"
	while result.contains("__"):
		result = result.replace("__", "_")
	result = result.trim_prefix("_").trim_suffix("_")
	if result.is_empty():
		return "event"
	return result.substr(0, 64)
