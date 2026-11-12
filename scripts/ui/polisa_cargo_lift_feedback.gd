extends Control
## Cosmetic projection of an already committed Supply purchase; no cargo state.
var _progress := 1.0:
	set(value):
		_progress = value
		queue_redraw()
var _animation: Tween

func _init() -> void:
	custom_minimum_size = Vector2(100, 42)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func show_delivery() -> void:
	if _animation != null and _animation.is_valid(): _animation.kill()
	visible = true
	_progress = 0.0
	_animation = create_tween()
	_animation.tween_property(self, "_progress", 1.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_interval(1.0)
	_animation.tween_callback(func(): visible = false)

func _draw() -> void:
	var center := size.x * 0.5
	var rail := Color("8ea7b3")
	draw_line(Vector2(center - 18.0, 4.0), Vector2(center - 18.0, 36.0), rail, 2.0)
	draw_line(Vector2(center + 18.0, 4.0), Vector2(center + 18.0, 36.0), rail, 2.0)
	var y := lerpf(6.0, 24.0, _progress)
	draw_rect(Rect2(center - 12.0, y, 24.0, 12.0), Color("e5b34f"))
	draw_line(Vector2(center - 15.0, y + 14.0), Vector2(center + 15.0, y + 14.0), rail, 2.0)
