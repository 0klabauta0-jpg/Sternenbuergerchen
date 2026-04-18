extends Node2D

var _diamonds: PackedVector2Array = PackedVector2Array()
var _half_w: float = 64.0
var _half_h: float = 32.0
var _grid_color: Color = Color(0.0, 1.0, 0.0, 0.6)
var _grid_width: float = 3.0

var _compass_labels: Array = []


func set_grid_data(tile_centers: PackedVector2Array, half_w: float, half_h: float) -> void:
	_diamonds = tile_centers
	_half_w = half_w
	_half_h = half_h
	queue_redraw()


func set_compass_data(compass: Array) -> void:
	# compass = [["N", Vector2], ["O", Vector2], ...]
	for child in get_children():
		child.queue_free()
	for entry in compass:
		var lbl := Label.new()
		lbl.text = entry[0]
		lbl.add_theme_font_size_override("font_size", 80)
		lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.5))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size = Vector2(160, 120)
		lbl.position = entry[1] - lbl.size * 0.5
		add_child(lbl)


func _draw() -> void:
	for i in _diamonds.size():
		var center: Vector2 = _diamonds[i]
		var top: Vector2 = center + Vector2(0.0, -_half_h)
		var right: Vector2 = center + Vector2(_half_w, 0.0)
		var bottom: Vector2 = center + Vector2(0.0, _half_h)
		var left: Vector2 = center + Vector2(-_half_w, 0.0)
		draw_line(top, right, _grid_color, _grid_width, true)
		draw_line(right, bottom, _grid_color, _grid_width, true)
		draw_line(bottom, left, _grid_color, _grid_width, true)
		draw_line(left, top, _grid_color, _grid_width, true)
