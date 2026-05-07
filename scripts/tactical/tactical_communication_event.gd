class_name TacticalCommunicationEvent
extends RefCounted

const SOURCE_ID: String = "tactical_communication_feedback"

const EVENT_ORDER_RECEIVED: String = "order_received"
const EVENT_PLAN_ROLE_ASSIGNED: String = "plan_role_assigned"
const EVENT_PHASE_STARTED: String = "phase_started"
const EVENT_PHASE_COMPLETED: String = "phase_completed"
const EVENT_CONTACT_REPORT: String = "contact_report"
const EVENT_BREAKOUT_ADAPTATION: String = "breakout_adaptation"
const EVENT_CANNOT_EXECUTE: String = "cannot_execute"
const EVENT_NEEDS_ORDERS: String = "needs_orders"
const EVENT_OBJECTIVE_PROGRESS: String = "objective_progress"
const EVENT_OBJECTIVE_COMPLETE: String = "objective_complete"
const EVENT_AIR_ASSET_THREATENED: String = "air_asset_threatened"
const EVENT_AIR_ASSET_DESTROYED: String = "air_asset_destroyed"

const CHANNEL_SELECTED_FIRETEAM: String = "selected_fireteam"
const CHANNEL_MISSION_CONTROL: String = "mission_control"
const CHANNEL_MAP_MARKER: String = "map_marker"
const CHANNEL_FTL_BUBBLE: String = "ftl_bubble"
const CHANNEL_AUDIO_BLIP: String = "audio_blip"

const PRIORITY_CRITICAL: int = 100
const PRIORITY_HIGH: int = 80
const PRIORITY_NORMAL: int = 50
const PRIORITY_LOW: int = 20

var event_id: String = ""
var event_type: String = EVENT_ORDER_RECEIVED
var fireteam_id: String = ""
var unit_id: String = ""
var priority: int = PRIORITY_NORMAL
var duration_seconds: float = 2.0
var channels: PackedStringArray = PackedStringArray()
var feedback_action: String = "move"
var feedback_state: String = "accepted"
var short_text: String = ""
var detail_text: String = ""
var map_label: String = ""
var phase: int = 0
var created_msec: int = 0
var cooldown_key: String = ""
var source: String = SOURCE_ID
var visual_only: bool = true
var metadata: Dictionary = {}
var anchor_position = null
var target_position = null


static func from_dict(data: Dictionary):
	var event = load("res://scripts/tactical/tactical_communication_event.gd").new()
	event.event_type = normalize_event_type(String(data.get("event_type", data.get("type", EVENT_ORDER_RECEIVED))))
	event.fireteam_id = String(data.get("fireteam_id", "")).strip_edges().to_lower()
	event.unit_id = String(data.get("unit_id", "")).strip_edges()
	event.phase = maxi(int(data.get("phase", data.get("plan_phase_index", 0))), 0)
	event.priority = clampi(int(data.get("priority", default_priority_for_event_type(event.event_type))), PRIORITY_LOW, PRIORITY_CRITICAL)
	event.duration_seconds = clampf(float(data.get("duration_seconds", default_duration_for_event_type(event.event_type))), 0.75, 5.0)
	event.channels = normalize_channels(data.get("channels", default_channels_for_event_type(event.event_type)))
	event.feedback_action = normalize_feedback_action(String(data.get("feedback_action", default_feedback_action_for_event_type(event.event_type))))
	event.feedback_state = normalize_feedback_state(String(data.get("feedback_state", default_feedback_state_for_event_type(event.event_type))))
	event.short_text = String(data.get("short_text", data.get("text", ""))).strip_edges()
	event.detail_text = String(data.get("detail_text", data.get("detail", ""))).strip_edges()
	event.map_label = String(data.get("map_label", "")).strip_edges()
	event.created_msec = maxi(int(data.get("created_msec", 0)), 0)
	event.source = String(data.get("source", SOURCE_ID)).strip_edges()
	if event.source.is_empty():
		event.source = SOURCE_ID
	event.visual_only = bool(data.get("visual_only", true))
	event.metadata = Dictionary(data.get("metadata", {})).duplicate(true)
	event.anchor_position = _coerce_vector2_or_null(data.get("anchor_position", data.get("planned_position", null)))
	event.target_position = _coerce_vector2_or_null(data.get("target_position", null))
	event.event_id = String(data.get("event_id", "")).strip_edges()
	if event.event_id.is_empty():
		event.event_id = build_stable_event_id(event.event_type, {
			"fireteam_id": event.fireteam_id,
			"unit_id": event.unit_id,
			"phase": event.phase,
			"plan_id": String(data.get("plan_id", event.metadata.get("plan_id", ""))),
			"role": String(data.get("role", event.metadata.get("role", ""))),
			"step": String(data.get("step", event.metadata.get("step", ""))),
		})
	event.cooldown_key = String(data.get("cooldown_key", "")).strip_edges()
	if event.cooldown_key.is_empty():
		event.cooldown_key = "%s:%s:%s" % [event.event_type, event.fireteam_id, event.unit_id]
	return event


func to_dict() -> Dictionary:
	var result: Dictionary = {
		"event_id": event_id,
		"event_type": event_type,
		"fireteam_id": fireteam_id,
		"unit_id": unit_id,
		"priority": priority,
		"duration_seconds": duration_seconds,
		"channels": channels,
		"feedback_action": feedback_action,
		"feedback_state": feedback_state,
		"short_text": short_text,
		"detail_text": detail_text,
		"map_label": map_label,
		"phase": phase,
		"created_msec": created_msec,
		"cooldown_key": cooldown_key,
		"source": source,
		"visual_only": visual_only,
		"metadata": metadata.duplicate(true),
	}
	if typeof(anchor_position) == TYPE_VECTOR2:
		result["anchor_position"] = Vector2(anchor_position)
	if typeof(target_position) == TYPE_VECTOR2:
		result["target_position"] = Vector2(target_position)
	return result


func to_snapshot() -> Dictionary:
	var snapshot: Dictionary = to_dict()
	snapshot.erase("metadata")
	snapshot["metadata_keys"] = PackedStringArray(metadata.keys())
	snapshot["is_critical"] = priority >= PRIORITY_CRITICAL
	snapshot["has_map_marker"] = channels.has(CHANNEL_MAP_MARKER)
	snapshot["has_bubble"] = channels.has(CHANNEL_FTL_BUBBLE)
	return snapshot


func is_valid() -> bool:
	return not event_id.strip_edges().is_empty() and not event_type.strip_edges().is_empty() and not channels.is_empty()


static func normalize_event_type(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"order", "ack", "received":
			return EVENT_ORDER_RECEIVED
		"role", "role_assigned", "plan_role":
			return EVENT_PLAN_ROLE_ASSIGNED
		"phase_start", "phase_started", "start_phase":
			return EVENT_PHASE_STARTED
		"phase_done", "phase_complete", "complete_phase":
			return EVENT_PHASE_COMPLETED
		"contact", "contact_report":
			return EVENT_CONTACT_REPORT
		"breakout", "adaptation", "route_adaptation":
			return EVENT_BREAKOUT_ADAPTATION
		"blocked", "cannot", "cannot_execute":
			return EVENT_CANNOT_EXECUTE
		"needs_orders", "question":
			return EVENT_NEEDS_ORDERS
		"objective", "objective_progress":
			return EVENT_OBJECTIVE_PROGRESS
		"objective_done", "objective_complete":
			return EVENT_OBJECTIVE_COMPLETE
		"air_threat", "air_asset_threatened":
			return EVENT_AIR_ASSET_THREATENED
		"air_destroyed", "air_asset_destroyed":
			return EVENT_AIR_ASSET_DESTROYED
		_:
			return EVENT_ORDER_RECEIVED if normalized.is_empty() else normalized


static func normalize_channels(value) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var raw: Array = []
	if value is PackedStringArray:
		raw = Array(value)
	elif value is Array:
		raw = Array(value)
	elif value is String:
		raw = [String(value)]
	for channel_variant in raw:
		var channel: String = normalize_channel(String(channel_variant))
		if channel.is_empty() or result.has(channel):
			continue
		result.append(channel)
	if result.is_empty():
		result.append(CHANNEL_SELECTED_FIRETEAM)
	return result


static func normalize_channel(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"selected", "selected_fireteam", "17", "#17":
			return CHANNEL_SELECTED_FIRETEAM
		"mission", "mission_control", "18", "#18":
			return CHANNEL_MISSION_CONTROL
		"map", "marker", "map_marker", "status":
			return CHANNEL_MAP_MARKER
		"bubble", "ftl_bubble", "fireteamleader_bubble":
			return CHANNEL_FTL_BUBBLE
		"audio", "radio", "radio_blip", "audio_blip":
			return CHANNEL_AUDIO_BLIP
		_:
			return normalized


static func default_channels_for_event_type(event_type: String) -> PackedStringArray:
	match normalize_event_type(event_type):
		EVENT_CONTACT_REPORT, EVENT_CANNOT_EXECUTE, EVENT_AIR_ASSET_THREATENED, EVENT_AIR_ASSET_DESTROYED:
			return PackedStringArray([CHANNEL_SELECTED_FIRETEAM, CHANNEL_MISSION_CONTROL, CHANNEL_MAP_MARKER, CHANNEL_FTL_BUBBLE, CHANNEL_AUDIO_BLIP])
		EVENT_PLAN_ROLE_ASSIGNED, EVENT_PHASE_STARTED, EVENT_PHASE_COMPLETED, EVENT_BREAKOUT_ADAPTATION:
			return PackedStringArray([CHANNEL_SELECTED_FIRETEAM, CHANNEL_MISSION_CONTROL, CHANNEL_MAP_MARKER, CHANNEL_FTL_BUBBLE])
		EVENT_OBJECTIVE_PROGRESS, EVENT_OBJECTIVE_COMPLETE:
			return PackedStringArray([CHANNEL_MISSION_CONTROL, CHANNEL_MAP_MARKER, CHANNEL_FTL_BUBBLE])
		_:
			return PackedStringArray([CHANNEL_SELECTED_FIRETEAM, CHANNEL_MISSION_CONTROL, CHANNEL_FTL_BUBBLE])


static func default_priority_for_event_type(event_type: String) -> int:
	match normalize_event_type(event_type):
		EVENT_AIR_ASSET_DESTROYED, EVENT_CANNOT_EXECUTE:
			return PRIORITY_CRITICAL
		EVENT_CONTACT_REPORT, EVENT_AIR_ASSET_THREATENED, EVENT_BREAKOUT_ADAPTATION:
			return PRIORITY_HIGH
		EVENT_PLAN_ROLE_ASSIGNED, EVENT_PHASE_STARTED, EVENT_PHASE_COMPLETED, EVENT_OBJECTIVE_COMPLETE:
			return PRIORITY_NORMAL
		_:
			return PRIORITY_LOW


static func default_duration_for_event_type(event_type: String) -> float:
	match normalize_event_type(event_type):
		EVENT_AIR_ASSET_DESTROYED, EVENT_CANNOT_EXECUTE:
			return 3.2
		EVENT_CONTACT_REPORT, EVENT_AIR_ASSET_THREATENED, EVENT_BREAKOUT_ADAPTATION:
			return 2.6
		_:
			return 2.0


static func default_feedback_action_for_event_type(event_type: String) -> String:
	match normalize_event_type(event_type):
		EVENT_CONTACT_REPORT, EVENT_AIR_ASSET_THREATENED, EVENT_AIR_ASSET_DESTROYED:
			return "engage"
		EVENT_CANNOT_EXECUTE, EVENT_NEEDS_ORDERS:
			return "move"
		EVENT_OBJECTIVE_PROGRESS, EVENT_OBJECTIVE_COMPLETE:
			return "take"
		EVENT_BREAKOUT_ADAPTATION:
			return "flank"
		EVENT_PHASE_STARTED:
			return "go"
		_:
			return "move"


static func default_feedback_state_for_event_type(event_type: String) -> String:
	match normalize_event_type(event_type):
		EVENT_CANNOT_EXECUTE, EVENT_NEEDS_ORDERS:
			return "blocked"
		EVENT_CONTACT_REPORT, EVENT_AIR_ASSET_THREATENED, EVENT_AIR_ASSET_DESTROYED:
			return "contact"
		EVENT_OBJECTIVE_COMPLETE, EVENT_PHASE_COMPLETED:
			return "done"
		EVENT_BREAKOUT_ADAPTATION:
			return "running"
		_:
			return "accepted"


static func normalize_feedback_action(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	return "move" if normalized.is_empty() else normalized


static func normalize_feedback_state(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"ok", "ack", "accept", "accepted":
			return "accepted"
		"blocked", "cannot", "failed":
			return "blocked"
		"running", "active", "adapt":
			return "running"
		"done", "complete", "completed":
			return "done"
		"contact", "danger":
			return "contact"
		"cover", "covered":
			return "cover"
		_:
			return "accepted" if normalized.is_empty() else normalized


static func build_stable_event_id(event_type: String, context: Dictionary = {}) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	tokens.append("comm")
	tokens.append(_sanitize_token(normalize_event_type(event_type)))
	for key in ["plan_id", "fireteam_id", "unit_id", "phase", "role", "step"]:
		var value: String = str(context.get(key, "")).strip_edges()
		if value.is_empty():
			continue
		tokens.append(_sanitize_token(value))
	if tokens.size() <= 2:
		tokens.append("global")
	return ":".join(tokens)


static func _coerce_vector2_or_null(value):
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	if typeof(value) == TYPE_VECTOR2I:
		var grid := Vector2i(value)
		return Vector2(grid.x, grid.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null


static func _sanitize_token(value: String) -> String:
	var result: String = value.strip_edges().to_lower()
	for token in [" ", "/", "\\", ":", ".", "|", "#"]:
		result = result.replace(token, "_")
	return "x" if result.is_empty() else result
