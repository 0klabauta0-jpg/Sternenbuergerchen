extends Node
## World mouse selection gesture only; no crew movement or simulation state.
signal clicked(screen: Vector2)
signal box_finished(bounds: Rect2)

const DRAG_THRESHOLD := 6.0
var _selecting := false
var _start := Vector2.ZERO
var _frame: Panel

func _ready() -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 0
	add_child(overlay)
	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.37,0.84,0.79,0.13)
	style.border_color = Color("97e7dd")
	style.set_border_width_all(2)
	_frame.add_theme_stylebox_override("panel",style)
	overlay.add_child(_frame)
	_frame.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_selecting = true
		_start = event.position
		_frame.position = _start
		_frame.size = Vector2.ZERO
		_frame.hide()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	# Once a world gesture starts, capture its release even over a HUD panel.
	if not _selecting:
		return
	if event is InputEventMouseMotion:
		var bounds := Rect2(_start,event.position-_start).abs()
		_frame.position = bounds.position
		_frame.size = bounds.size
		_frame.visible = _start.distance_to(event.position) >= DRAG_THRESHOLD
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_selecting = false
		_frame.hide()
		if _start.distance_to(event.position) >= DRAG_THRESHOLD:
			box_finished.emit(Rect2(_start,event.position-_start).abs())
		else:
			clicked.emit(event.position)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_selecting = false
		if is_instance_valid(_frame):
			_frame.hide()
