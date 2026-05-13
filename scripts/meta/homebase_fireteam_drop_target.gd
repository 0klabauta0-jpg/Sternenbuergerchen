class_name HomebaseFireteamDropTarget
extends Control

signal fireteam_dropped(fireteam_id, target_id)

var target_id: String = ""
var _drop_enabled: bool = true


func setup_drop_target(next_target_id: String, enabled: bool = true) -> void:
	target_id = next_target_id.strip_edges()
	_drop_enabled = enabled
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_meta("homebase_fireteam_drop_target", true)
	set_meta("homebase_fireteam_drop_target_id", target_id)
	set_meta("homebase_fireteam_drop_enabled", _drop_enabled)


func set_drop_enabled(enabled: bool) -> void:
	_drop_enabled = enabled
	set_meta("homebase_fireteam_drop_enabled", _drop_enabled)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not _drop_enabled or target_id.is_empty() or typeof(data) != TYPE_DICTIONARY:
		return false
	var payload: Dictionary = Dictionary(data)
	return String(payload.get("type", "")).strip_edges() == "fob_fireteam_card" \
		and not String(payload.get("fireteam_id", "")).strip_edges().is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var payload: Dictionary = Dictionary(data)
	fireteam_dropped.emit(String(payload.get("fireteam_id", "")).strip_edges(), target_id)
