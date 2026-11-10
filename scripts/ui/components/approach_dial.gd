extends Control
## Presentation of the four existing per-craft approach directions.
signal direction_selected(direction: String)
var selected: String = "NW"
var _buttons: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(112, 80)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for spec in [["NW",Vector2(0,0)],["NE",Vector2(64,0)],["SW",Vector2(0,48)],["SE",Vector2(64,48)]]:
		var key: String = spec[0]
		var button := Button.new()
		button.text = key
		button.position = spec[1]
		button.size = Vector2(48,32)
		button.tooltip_text = "Anflug aus " + key
		button.toggle_mode = true
		add_child(button)
		_buttons[key] = button
		button.pressed.connect(func(): direction_selected.emit(key))
	set_direction(selected)

func set_direction(direction: String) -> void:
	selected = direction
	for key in _buttons: (_buttons[key] as Button).set_pressed_no_signal(key == selected)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(56,40), 20, Color("77cdd3"), false, 1.5, true)
	draw_line(Vector2(56,40), Vector2(44 if selected.ends_with("W") else 68,28 if selected.begins_with("N") else 52),Color("edc05c"),2,true)
