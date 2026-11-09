extends PanelContainer
## Native drag adapter. Holds only displayed IDs; owner validates every drop.

signal payload_dropped(payload: Dictionary)

var drag_payload: Dictionary = {}
var accepted_type: String = ""
var equipment_key: String = ""

func get_drag_payload() -> Dictionary:
	return drag_payload.duplicate(true)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty():
		return null
	var preview := Label.new()
	preview.text = String(drag_payload.get("label", drag_payload.get("unit_id", drag_payload.get("fireteam_id", drag_payload.get("item_id", "")))))
	preview.add_theme_font_size_override("font_size", 18)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_drag_preview(preview)
	return get_drag_payload()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or accepted_type.is_empty():
		return false
	var payload: Dictionary = Dictionary(data)
	if String(payload.get("type", "")) != accepted_type:
		return false
	match accepted_type:
		"homebase_unit_card":
			return not String(payload.get("unit_id", "")).strip_edges().is_empty()
		"fob_fireteam_card":
			return not String(payload.get("fireteam_id", "")).strip_edges().is_empty()
		"homebase_loadout_item":
			return String(payload.get("key", "")) == equipment_key and not String(payload.get("item_id", "")).strip_edges().is_empty()
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		payload_dropped.emit(Dictionary(data).duplicate(true))

func forward_drag_from(control: Control) -> void:
	control.set_drag_forwarding(_get_drag_data, _can_drop_data, _drop_data)
