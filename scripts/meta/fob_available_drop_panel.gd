class_name FOBAvailableDropPanel
extends PanelContainer

signal unit_dropped(unit_id)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_descendant_mouse_filter(self)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return String(data.get("type", "")).strip_edges() == "homebase_unit_card" and not String(data.get("unit_id", "")).strip_edges().is_empty()


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(_at_position, data):
		return
	unit_dropped.emit(String(data.get("unit_id", "")).strip_edges())


func _set_descendant_mouse_filter(root: Node) -> void:
	for child in root.get_children():
		if child is Control:
			if child is ScrollContainer:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
			else:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_descendant_mouse_filter(child)