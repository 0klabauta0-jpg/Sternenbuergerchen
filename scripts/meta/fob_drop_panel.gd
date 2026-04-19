class_name FOBDropPanel
extends PanelContainer

signal fireteam_dropped(fireteam_id, drop_kind)
signal unit_dropped(unit_id, drop_kind)

@export var drop_kind: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_set_passive_descendant_mouse_filter(self)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var drag_type: String = String(data.get("type", "")).strip_edges()
	return drag_type == "fob_fireteam_card" or drag_type == "homebase_unit_card"


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var drag_type: String = String(data.get("type", "")).strip_edges()
	if drag_type == "fob_fireteam_card":
		fireteam_dropped.emit(String(data.get("fireteam_id", "")).strip_edges(), drop_kind)
	elif drag_type == "homebase_unit_card":
		unit_dropped.emit(String(data.get("unit_id", "")).strip_edges(), drop_kind)


func _set_passive_descendant_mouse_filter(root: Node) -> void:
	for child in root.get_children():
		if child is Label or child is MarginContainer or child is BoxContainer or child is TextureRect or child is ScrollContainer:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_passive_descendant_mouse_filter(child)