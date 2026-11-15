extends Control
## Presentation of the four existing per-craft approach directions.
signal direction_selected(direction: String)
var selected: String = "NW"
var _buttons: Dictionary = {}

func _ready() -> void:
	custom_minimum_size = Vector2(96, 56)
	mouse_filter = Control.MOUSE_FILTER_PASS
	for spec in [["NW",Vector2(0,0)],["NE",Vector2(54,0)],["SW",Vector2(0,32)],["SE",Vector2(54,32)]]:
		var key: String = spec[0]
		var button := Button.new()
		button.text = key
		button.position = spec[1]
		button.size = Vector2(42,24)
		button.add_theme_font_size_override("font_size", 13)
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
	draw_circle(Vector2(48,28), 11, Color("77cdd3"), false, 1.5, true)
	draw_line(Vector2(48,28), Vector2(40 if selected.ends_with("W") else 56,20 if selected.begins_with("N") else 36),Color("edc05c"),2,true)
