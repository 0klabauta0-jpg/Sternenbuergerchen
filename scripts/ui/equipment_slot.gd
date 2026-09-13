extends Button
## Reusable source/target. Payload describes intent only; no inventory lives here.
signal dropped(data: Dictionary, target: Dictionary)
signal rejected(reason: String)
var source: Dictionary = {}
var target: Dictionary = {}
var accept: Callable
var amount: Callable
var _last_rejection: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(142, 54)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	expand_icon = true
	add_theme_constant_override("icon_max_width", 24)
	add_theme_constant_override("h_separation", 9)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _get_drag_data(_at: Vector2) -> Variant:
	if source.is_empty() or int(source.get("available", 0)) <= 0:
		return null
	var data: Dictionary = source.duplicate(true)
	data.kind = "crew_item"
	data.amount = mini(int(data.available), maxi(1, int(amount.call()) if amount.is_valid() else 1))
	if source.get("from", "") == "equipment": data.amount = 1
	var preview := Label.new()
	preview.text = text.replace("\n", " · ") + " × " + str(data.amount)
	preview.add_theme_color_override("font_color", Color("efab6f"))
	set_drag_preview(preview)
	return data

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("kind") != "crew_item": return false
	var reason: String = str(accept.call(data, target)) if accept.is_valid() else "Kein Ablageziel."
	if reason != _last_rejection:
		_last_rejection = reason
		if not reason.is_empty(): rejected.emit(reason)
	return reason.is_empty()

func _drop_data(_at: Vector2, data: Variant) -> void:
	if _can_drop_data(_at, data): dropped.emit(data.duplicate(true), target.duplicate(true))
