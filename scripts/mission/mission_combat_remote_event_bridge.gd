class_name MissionCombatRemoteEventBridge
extends RefCounted

const EVENT_TYPE_COMBAT_UI_EVENT: String = "combat_ui_event"


func build_event_payload(
	event_text: String,
	unit_id: String = "",
	event_color: Color = Color.WHITE,
	duration_seconds: float = 1.2,
	unit_event_text: String = ""
) -> Dictionary:
	return {
		"event_type": EVENT_TYPE_COMBAT_UI_EVENT,
		"read_only": true,
		"event_text": event_text,
		"unit_id": unit_id.strip_edges(),
		"event_color": event_color,
		"duration_seconds": maxf(duration_seconds, 0.0),
		"unit_event_text": unit_event_text,
	}


func apply_event_payload(driver: Node, payload: Dictionary) -> void:
	if driver == null:
		return
	if not bool(payload.get("read_only", false)):
		return
	if String(payload.get("event_type", "")) != EVENT_TYPE_COMBAT_UI_EVENT:
		return

	var event_text: String = String(payload.get("event_text", ""))
	driver.call("_set_event_text", event_text)

	var unit_id: String = String(payload.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return

	var unit = driver.call("_resolve_unit_by_id", unit_id)
	if unit == null or not unit.has_method("show_event_text"):
		return

	var resolved_unit_event_text: String = String(payload.get("unit_event_text", ""))
	if resolved_unit_event_text.is_empty():
		resolved_unit_event_text = event_text
	unit.call("show_event_text", resolved_unit_event_text, Color(payload.get("event_color", Color.WHITE)), float(payload.get("duration_seconds", 1.2)))
