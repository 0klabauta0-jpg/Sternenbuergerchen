class_name HomebaseTeamDropPanel
extends PanelContainer

signal unit_dropped(unit_id)
signal fireteam_dropped(fireteam_id, target_id)

var _drop_enabled: bool = true


func _ready() -> void:
	_refresh_visuals()


func set_drop_enabled(enabled: bool) -> void:
	_drop_enabled = enabled
	_refresh_visuals()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not _drop_enabled or typeof(data) != TYPE_DICTIONARY:
		return false

	var drag_data: Dictionary = data
	var drag_type: String = String(drag_data.get("type", "")).strip_edges()
	if drag_type == "homebase_unit_card":
		return not String(drag_data.get("unit_id", "")).strip_edges().is_empty()
	if drag_type != "fob_fireteam_card":
		return false
	if not bool(get_meta("homebase_fireteam_drop_target", false)) or not bool(get_meta("homebase_fireteam_drop_enabled", false)):
		return false
	return not String(get_meta("homebase_fireteam_drop_target_id", "")).strip_edges().is_empty() \
		and not String(drag_data.get("fireteam_id", "")).strip_edges().is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return

	var drag_type: String = String(data.get("type", "")).strip_edges()
	if drag_type == "homebase_unit_card":
		var unit_id: String = String(data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			return
		unit_dropped.emit(unit_id)
	elif drag_type == "fob_fireteam_card":
		fireteam_dropped.emit(
			String(data.get("fireteam_id", "")).strip_edges(),
			String(get_meta("homebase_fireteam_drop_target_id", "")).strip_edges()
		)



func _refresh_visuals() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 10
	stylebox.corner_radius_top_right = 10
	stylebox.corner_radius_bottom_right = 10
	stylebox.corner_radius_bottom_left = 10
	if _drop_enabled:
		stylebox.bg_color = Color(0.11, 0.14, 0.16, 1.0)
		stylebox.border_color = Color(0.40, 0.58, 0.68, 1.0)
	else:
		stylebox.bg_color = Color(0.10, 0.10, 0.12, 1.0)
		stylebox.border_color = Color(0.28, 0.30, 0.34, 1.0)

	add_theme_stylebox_override("panel", stylebox)
