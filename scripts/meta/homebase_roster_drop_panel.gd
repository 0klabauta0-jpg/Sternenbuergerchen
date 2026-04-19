class_name HomebaseRosterDropPanel
extends PanelContainer

signal unit_dropped(unit_id)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var drag_data: Dictionary = data
	return String(drag_data.get("type", "")).strip_edges() == "homebase_unit_card" and not String(drag_data.get("unit_id", "")).strip_edges().is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var unit_id: String = String(Dictionary(data).get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return
	unit_dropped.emit(unit_id)