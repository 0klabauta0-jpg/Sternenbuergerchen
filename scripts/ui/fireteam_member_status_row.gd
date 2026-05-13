class_name FireteamMemberStatusRow
extends Control

const DEFAULT_SIZE: Vector2 = Vector2(168.0, 16.0)
const MIN_VISIBLE_SLOTS: int = 4
const MAX_VISIBLE_SLOTS: int = 6

var _fireteam_id: String = ""
var _members: Array = []
var _diagnostic: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = DEFAULT_SIZE
	size = DEFAULT_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_refresh_diagnostic()


func set_member_snapshot(snapshot: Dictionary) -> void:
	_fireteam_id = String(snapshot.get("fireteam_id", "")).strip_edges().to_lower()
	_members = _normalize_members(Array(snapshot.get("members", [])))
	_refresh_diagnostic()
	queue_redraw()


func get_row_snapshot() -> Dictionary:
	return _diagnostic.duplicate(true)


func _draw() -> void:
	var visible_slots: int = int(_diagnostic.get("visible_chip_count", MIN_VISIBLE_SLOTS))
	var slot_width: float = minf(30.0, (DEFAULT_SIZE.x - float(visible_slots - 1) * 3.0) / float(maxi(visible_slots, 1)))
	var start_x: float = 0.0
	for index in range(visible_slots):
		var member: Dictionary = Dictionary(_members[index]) if index < _members.size() else {}
		var status: String = String(member.get("status", "empty")).strip_edges().to_lower()
		var rect := Rect2(Vector2(start_x, 2.0), Vector2(slot_width, 12.0))
		draw_rect(rect, _status_color(status), true)
		draw_rect(rect, Color(0.02, 0.03, 0.04, 0.82), false, 1.0)
		var short_label: String = _status_short_label(status)
		var font := get_theme_default_font()
		if font != null and not short_label.is_empty():
			draw_string(font, rect.position + Vector2(0.0, 9.5), short_label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8, _status_text_color(status))
		start_x += slot_width + 3.0


func _normalize_members(raw_members: Array) -> Array:
	var result: Array = []
	for member_variant in raw_members:
		if typeof(member_variant) != TYPE_DICTIONARY:
			continue
		var member: Dictionary = Dictionary(member_variant).duplicate(true)
		var status: String = String(member.get("status", "unknown")).strip_edges().to_lower()
		member["status"] = _normalize_status(status)
		member["label"] = String(member.get("label", _status_short_label(status))).strip_edges()
		result.append(member)
	return result


func _refresh_diagnostic() -> void:
	var counts: Dictionary = {
		"fit": 0,
		"wounded": 0,
		"down": 0,
		"suppressed": 0,
		"busy": 0,
		"unknown": 0,
	}
	for member_variant in _members:
		var member: Dictionary = Dictionary(member_variant)
		var status: String = _normalize_status(String(member.get("status", "unknown")))
		counts[status] = int(counts.get(status, 0)) + 1
	var visible_count: int = clampi(maxi(_members.size(), MIN_VISIBLE_SLOTS), MIN_VISIBLE_SLOTS, MAX_VISIBLE_SLOTS)
	_diagnostic = {
		"fireteam_id": _fireteam_id,
		"member_count": _members.size(),
		"visible_chip_count": visible_count,
		"counts": counts,
		"members": _members.duplicate(true),
		"display_state": "neutral" if _members.is_empty() else "active",
		"fixed_size": DEFAULT_SIZE,
		"read_only": true,
	}
	tooltip_text = _build_tooltip_text(counts)


func _build_tooltip_text(counts: Dictionary) -> String:
	if _members.is_empty():
		return "No member data"
	var parts: PackedStringArray = PackedStringArray()
	for status in ["fit", "wounded", "down", "suppressed", "busy", "unknown"]:
		var count: int = int(counts.get(status, 0))
		if count > 0:
			parts.append("%s %d" % [status.to_upper(), count])
	return " | ".join(parts)


func _normalize_status(status: String) -> String:
	match status.strip_edges().to_lower():
		"fit", "ready":
			return "fit"
		"wounded", "hurt", "injured":
			return "wounded"
		"down", "downed", "bleedout", "respawning":
			return "down"
		"suppressed", "pinned":
			return "suppressed"
		"busy", "moving", "acting":
			return "busy"
		_:
			return "unknown"


func _status_short_label(status: String) -> String:
	match _normalize_status(status):
		"fit":
			return "F"
		"wounded":
			return "W"
		"down":
			return "D"
		"suppressed":
			return "S"
		"busy":
			return "B"
		_:
			return ""


func _status_color(status: String) -> Color:
	match _normalize_status(status):
		"fit":
			return Color(0.28, 0.74, 0.45, 0.96)
		"wounded":
			return Color(0.94, 0.66, 0.24, 0.96)
		"down":
			return Color(0.86, 0.22, 0.24, 0.96)
		"suppressed":
			return Color(0.32, 0.56, 0.94, 0.96)
		"busy":
			return Color(0.62, 0.66, 0.70, 0.94)
		_:
			return Color(0.24, 0.27, 0.30, 0.78)


func _status_text_color(status: String) -> Color:
	match _normalize_status(status):
		"wounded":
			return Color(0.12, 0.09, 0.04, 1.0)
		"fit", "down", "suppressed", "busy":
			return Color(0.96, 0.98, 1.0, 1.0)
		_:
			return Color(0.60, 0.64, 0.68, 1.0)
