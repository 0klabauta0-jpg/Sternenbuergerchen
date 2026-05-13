class_name TacticalEventLog
extends RefCounted

const TACTICAL_COMMUNICATION_EVENT_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_communication_event.gd")

const DEFAULT_MAX_ENTRIES: int = 100

var max_entries: int = DEFAULT_MAX_ENTRIES

var _entries: Array = []
var _dedupe_keys: Dictionary = {}


func configure(options: Dictionary = {}) -> void:
	max_entries = maxi(int(options.get("max_entries", max_entries)), 1)
	_trim_to_max_entries()


func reset() -> void:
	_entries.clear()
	_dedupe_keys.clear()


func ingest_events(events: Array, options: Dictionary = {}) -> Array:
	return ingest_tactical_communication_events(events, options)


func ingest_tactical_communication_events(events: Array, options: Dictionary = {}) -> Array:
	var added_entries: Array = []
	if options.has("max_entries"):
		configure({"max_entries": int(options.get("max_entries", max_entries))})
	for event_variant in events:
		var entry: Dictionary = normalize_tactical_communication_event(event_variant)
		if entry.is_empty():
			continue
		var dedupe_key: String = _dedupe_key_for_entry(entry)
		if dedupe_key.is_empty() or _dedupe_keys.has(dedupe_key):
			continue
		_entries.append(entry)
		_dedupe_keys[dedupe_key] = true
		added_entries.append(entry.duplicate(true))
	_sort_entries()
	_trim_to_max_entries()
	return added_entries


func get_snapshot(options: Dictionary = {}) -> Array:
	var result: Array = []
	var newest_first: bool = bool(options.get("newest_first", true))
	var limit: int = maxi(int(options.get("limit", _entries.size())), 0)
	var source: Array = _entries.duplicate(true)
	source.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_time: int = int(a.get("created_msec", 0))
		var b_time: int = int(b.get("created_msec", 0))
		if a_time == b_time:
			return String(a.get("event_id", "")) < String(b.get("event_id", ""))
		return a_time > b_time if newest_first else a_time < b_time
	)
	for entry_variant in source:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		result.append(Dictionary(entry_variant).duplicate(true))
		if limit > 0 and result.size() >= limit:
			break
	return result


func get_entry_count() -> int:
	return _entries.size()


func get_contract_snapshot() -> Dictionary:
	return {
		"max_entries": max_entries,
		"entry_count": _entries.size(),
		"dedupe_key_count": _dedupe_keys.size(),
		"read_only_adapter": true,
		"source": TACTICAL_COMMUNICATION_EVENT_SCRIPT.SOURCE_ID,
	}


static func normalize_tactical_communication_event(event_variant) -> Dictionary:
	var event_dict: Dictionary = _coerce_event_dictionary(event_variant)
	if event_dict.is_empty():
		return {}
	var event = TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("from_dict", event_dict)
	if event == null or not event.has_method("to_snapshot"):
		return {}
	var snapshot: Dictionary = Dictionary(event.call("to_snapshot"))
	if String(snapshot.get("event_id", "")).strip_edges().is_empty():
		return {}
	var priority: int = clampi(int(snapshot.get("priority", 0)), TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_LOW, TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL)
	var created_msec: int = maxi(int(snapshot.get("created_msec", 0)), 0)
	var event_type: String = String(snapshot.get("event_type", "")).strip_edges().to_lower()
	var entry: Dictionary = {
		"event_id": String(snapshot.get("event_id", "")).strip_edges(),
		"event_type": event_type,
		"category": _category_for_event_type(event_type),
		"severity": _severity_for_priority(priority),
		"priority": priority,
		"created_msec": created_msec,
		"timestamp_seconds": float(created_msec) / 1000.0,
		"fireteam_id": String(snapshot.get("fireteam_id", "")).strip_edges().to_lower(),
		"unit_id": String(snapshot.get("unit_id", "")).strip_edges(),
		"short_text": String(snapshot.get("short_text", snapshot.get("map_label", ""))).strip_edges(),
		"detail_text": String(snapshot.get("detail_text", "")).strip_edges(),
		"map_label": String(snapshot.get("map_label", "")).strip_edges(),
		"phase": maxi(int(snapshot.get("phase", 0)), 0),
		"channels": PackedStringArray(snapshot.get("channels", PackedStringArray())),
		"cooldown_key": String(snapshot.get("cooldown_key", "")).strip_edges(),
		"source": String(snapshot.get("source", TACTICAL_COMMUNICATION_EVENT_SCRIPT.SOURCE_ID)).strip_edges(),
		"visual_only": bool(snapshot.get("visual_only", true)),
	}
	if typeof(snapshot.get("anchor_position", null)) == TYPE_VECTOR2:
		entry["anchor_position"] = Vector2(snapshot.get("anchor_position"))
	if typeof(snapshot.get("target_position", null)) == TYPE_VECTOR2:
		entry["target_position"] = Vector2(snapshot.get("target_position"))
	return entry


static func _coerce_event_dictionary(event_variant) -> Dictionary:
	if typeof(event_variant) == TYPE_DICTIONARY:
		return Dictionary(event_variant).duplicate(true)
	if event_variant is Object and event_variant.has_method("to_dict"):
		return Dictionary(event_variant.call("to_dict")).duplicate(true)
	if event_variant is Object and event_variant.has_method("to_snapshot"):
		return Dictionary(event_variant.call("to_snapshot")).duplicate(true)
	return {}


static func _severity_for_priority(priority: int) -> String:
	if priority >= TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_CRITICAL:
		return "critical"
	if priority >= TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_HIGH:
		return "warning"
	if priority >= TACTICAL_COMMUNICATION_EVENT_SCRIPT.PRIORITY_NORMAL:
		return "info"
	return "low"


static func _category_for_event_type(event_type: String) -> String:
	match TACTICAL_COMMUNICATION_EVENT_SCRIPT.call("normalize_event_type", event_type):
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CONTACT_REPORT, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_FRIENDLY_FIRE:
			return "contact"
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_CANNOT_EXECUTE, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_NEEDS_ORDERS:
			return "command"
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_OBJECTIVE_PROGRESS, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_OBJECTIVE_COMPLETE:
			return "objective"
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_THREATENED, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_AIR_ASSET_DESTROYED:
			return "air_asset"
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_BOUNDING_ROTATION, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_BREAKOUT_ADAPTATION:
			return "movement"
		TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_PLAN_ROLE_ASSIGNED, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_PHASE_STARTED, TACTICAL_COMMUNICATION_EVENT_SCRIPT.EVENT_PHASE_COMPLETED:
			return "plan"
		_:
			return "status"


func _dedupe_key_for_entry(entry: Dictionary) -> String:
	var event_id: String = String(entry.get("event_id", "")).strip_edges()
	if not event_id.is_empty():
		return "event_id:%s" % event_id
	var cooldown_key: String = String(entry.get("cooldown_key", "")).strip_edges()
	if not cooldown_key.is_empty():
		return "cooldown:%s" % cooldown_key
	return ""


func _sort_entries() -> void:
	_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_time: int = int(a.get("created_msec", 0))
		var b_time: int = int(b.get("created_msec", 0))
		if a_time == b_time:
			return String(a.get("event_id", "")) < String(b.get("event_id", ""))
		return a_time < b_time
	)


func _trim_to_max_entries() -> void:
	_sort_entries()
	while _entries.size() > max_entries:
		var removed: Dictionary = Dictionary(_entries.pop_front())
		var dedupe_key: String = _dedupe_key_for_entry(removed)
		if not dedupe_key.is_empty():
			_dedupe_keys.erase(dedupe_key)
