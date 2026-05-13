class_name HomebaseUnitDropTarget
extends Control

signal unit_dropped(unit_id, fireteam_id, drop_zone, anchor_unit_id)

var fireteam_id: String = ""
var drop_zone: String = "member"
var anchor_unit_id: String = ""
var _drop_enabled: bool = true


func setup_drop_target(next_fireteam_id: String, next_drop_zone: String = "member", next_anchor_unit_id: String = "", enabled: bool = true) -> void:
	fireteam_id = next_fireteam_id.strip_edges().to_lower()
	drop_zone = next_drop_zone.strip_edges().to_lower()
	if drop_zone.is_empty():
		drop_zone = "member"
	anchor_unit_id = next_anchor_unit_id.strip_edges()
	_drop_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("homebase_unit_drop_target", true)
	set_meta("homebase_unit_drop_fireteam_id", fireteam_id)
	set_meta("homebase_unit_drop_zone", drop_zone)
	set_meta("homebase_unit_drop_anchor_unit_id", anchor_unit_id)
	set_meta("homebase_unit_drop_enabled", _drop_enabled)


func set_drop_enabled(enabled: bool) -> void:
	_drop_enabled = enabled
	set_meta("homebase_unit_drop_enabled", _drop_enabled)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not _drop_enabled or fireteam_id.is_empty() or typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = Dictionary(data)
	if String(payload.get("type", "")).strip_edges() != "homebase_unit_card":
		return false
	var dropped_unit_id: String = String(payload.get("unit_id", "")).strip_edges()
	if dropped_unit_id.is_empty():
		return false
	return anchor_unit_id.is_empty() or dropped_unit_id != anchor_unit_id


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var payload: Dictionary = Dictionary(data)
	unit_dropped.emit(String(payload.get("unit_id", "")).strip_edges(), fireteam_id, drop_zone, anchor_unit_id)
