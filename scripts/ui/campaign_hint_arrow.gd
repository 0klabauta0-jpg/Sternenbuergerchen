extends Control
## Dicker Hinweispfeil mit kurzem Text fuer das Kampagnen-Tutorial.
## Reine Anzeige: faengt keine Eingabe, nimmt keinen Fokus, pausiert nichts.
## Der Baustein deckt das ganze Fenster ab (Vollbild-Control im eigenen CanvasLayer);
## alle Rechtecke sind Fensterkoordinaten.

const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const EDGE_MARGIN: float = 16.0
const TARGET_GAP: float = 6.0
const ARROW_LENGTH: float = 64.0
const SHAFT_WIDTH: float = 18.0
const HEAD_WIDTH: float = 40.0
const HEAD_LENGTH: float = 28.0
const BOX_PAD_X: float = 10.0
const BOX_PAD_Y: float = 8.0
const MAX_TEXT_WIDTH: float = 220.0
const FONT_SIZE: int = 15
const PULSE_DISTANCE: float = 4.0
const FALLBACK_VIEW: Vector2 = Vector2(1280.0, 720.0)

var pulse_enabled: bool = true
## Nur fuer Tests: feste Fenstergroesse statt der des Viewports.
var view_size_override: Vector2 = Vector2.ZERO

var _label: Label = null
var _showing: bool = false
var _target: Rect2 = Rect2()
var _text: String = ""
var _layout: Dictionary = {}


func _ready() -> void:
	_ensure_label()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = _showing
	var viewport: Viewport = get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_relayout):
		viewport.size_changed.connect(_relayout)


func show_at(target_rect: Rect2, text: String) -> void:
	_ensure_label()
	_target = target_rect
	_text = text
	_showing = true
	visible = true
	set_process(pulse_enabled)
	_relayout()


func hide_arrow() -> void:
	_showing = false
	_layout = {}
	visible = false
	set_process(false)
	if _label != null:
		_label.visible = false
	queue_redraw()


func is_showing() -> bool:
	return _showing


## Kasten samt Pfeil in Fensterkoordinaten (ohne Pulsieren). Leer, wenn nichts gezeigt wird.
func get_arrow_rect() -> Rect2:
	if not _showing or _layout.is_empty():
		return Rect2()
	return Rect2(_layout["rect"])


func get_layout_snapshot() -> Dictionary:
	return _layout.duplicate(true)


func _process(_delta: float) -> void:
	if _showing and pulse_enabled:
		queue_redraw()


func _ensure_label() -> void:
	if _label != null and is_instance_valid(_label):
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_label = Label.new()
	_label.name = "HintText"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.focus_mode = Control.FOCUS_NONE
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", THEME.COLOR_TEXT)
	_label.add_theme_constant_override("line_spacing", 0)
	_label.visible = false
	add_child(_label)


func _view_size() -> Vector2:
	if view_size_override.x > 0.0 and view_size_override.y > 0.0:
		return view_size_override
	if is_inside_tree():
		var rect_size: Vector2 = get_viewport_rect().size
		if rect_size.x > 0.0 and rect_size.y > 0.0:
			return rect_size
	return FALLBACK_VIEW


func _measure_text(text: String) -> Vector2:
	if text.strip_edges().is_empty():
		return Vector2.ZERO
	var font: Font = _label.get_theme_font("font")
	var single_line: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE)
	var width: float = minf(MAX_TEXT_WIDTH, ceilf(single_line.x) + 2.0)
	var flags: int = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var wrapped: Vector2 = font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, FONT_SIZE, -1, flags)
	return Vector2(width, ceilf(wrapped.y) + 2.0)


func _relayout() -> void:
	if not _showing or _label == null:
		return
	var text_size: Vector2 = _measure_text(_text)
	_layout = compute_layout(_target, _view_size(), text_size)
	var box: Rect2 = Rect2(_layout["box"])
	var has_box: bool = bool(_layout["has_box"])
	_label.visible = has_box
	if has_box:
		_label.text = _text
		_label.custom_minimum_size = text_size
		_label.position = box.position + Vector2(BOX_PAD_X, BOX_PAD_Y)
		_label.size = text_size
	queue_redraw()


func _draw() -> void:
	if not _showing or _layout.is_empty():
		return
	var box: Rect2 = Rect2(_layout["box"])
	if bool(_layout["has_box"]):
		var style: StyleBoxFlat = THEME.build_flat_stylebox(THEME.COLOR_PANEL, THEME.COLOR_WARNING, THEME.CORNER_RADIUS, 2, Vector4.ZERO, 0.96)
		draw_style_box(style, box)
	var direction: Vector2 = _layout["dir"]
	var shift: Vector2 = Vector2.ZERO
	if pulse_enabled:
		var phase: float = (sin(float(Time.get_ticks_msec()) / 1000.0 * 5.0) + 1.0) * 0.5
		shift = direction * (PULSE_DISTANCE * phase)
	var poly: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in PackedVector2Array(_layout["poly"]):
		poly.append(point + shift)
	draw_colored_polygon(poly, THEME.COLOR_WARNING)
	var outline: PackedVector2Array = poly.duplicate()
	outline.append(poly[0])
	draw_polyline(outline, THEME.COLOR_TEXT_DARK, 2.0, true)


## Reine Rechenfunktion (ohne Baum testbar). `text_size` ist die Groesse des Textblocks
## ohne Kastenrand; Vector2.ZERO heisst: kein Kasten.
static func compute_layout(target: Rect2, view: Vector2, text_size: Vector2) -> Dictionary:
	var box_size: Vector2 = Vector2.ZERO
	if text_size.x > 0.0 and text_size.y > 0.0:
		box_size = text_size + Vector2(BOX_PAD_X * 2.0, BOX_PAD_Y * 2.0)
	var with_box: Dictionary = _layout_for(target, view, box_size)
	if bool(with_box["fits"]) or box_size == Vector2.ZERO:
		return with_box
	# Zu wenig Platz fuer Kasten und Pfeil: Pfeil ohne Kasten.
	return _layout_for(target, view, Vector2.ZERO)


static func _layout_for(target: Rect2, view: Vector2, box_size: Vector2) -> Dictionary:
	var sides: Array[String] = ["right", "left", "below", "above"]
	var best_side: String = "right"
	var best_slack: float = -INF
	for side: String in sides:
		var space: float = 0.0
		var need: float = TARGET_GAP + ARROW_LENGTH
		match side:
			"right":
				space = view.x - EDGE_MARGIN - target.end.x
				need += box_size.x
			"left":
				space = target.position.x - EDGE_MARGIN
				need += box_size.x
			"below":
				space = view.y - EDGE_MARGIN - target.end.y
				need += box_size.y
			_:
				space = target.position.y - EDGE_MARGIN
				need += box_size.y
		var slack: float = space - need
		if slack > best_slack:
			best_slack = slack
			best_side = side
	var half_head: float = HEAD_WIDTH * 0.5
	var center: Vector2 = target.get_center()
	var ty: float = clampf(center.y, EDGE_MARGIN + half_head, maxf(EDGE_MARGIN + half_head, view.y - EDGE_MARGIN - half_head))
	var tx: float = clampf(center.x, EDGE_MARGIN + half_head, maxf(EDGE_MARGIN + half_head, view.x - EDGE_MARGIN - half_head))
	var direction: Vector2 = Vector2.ZERO
	var tip: Vector2 = Vector2.ZERO
	var tail: Vector2 = Vector2.ZERO
	var box_pos: Vector2 = Vector2.ZERO
	match best_side:
		"right":
			direction = Vector2.LEFT
			tip = Vector2(target.end.x + TARGET_GAP, ty)
			tail = tip - direction * ARROW_LENGTH
			box_pos = Vector2(tail.x, clampf(ty - box_size.y * 0.5, EDGE_MARGIN, maxf(EDGE_MARGIN, view.y - EDGE_MARGIN - box_size.y)))
		"left":
			direction = Vector2.RIGHT
			tip = Vector2(target.position.x - TARGET_GAP, ty)
			tail = tip - direction * ARROW_LENGTH
			box_pos = Vector2(tail.x - box_size.x, clampf(ty - box_size.y * 0.5, EDGE_MARGIN, maxf(EDGE_MARGIN, view.y - EDGE_MARGIN - box_size.y)))
		"below":
			direction = Vector2.UP
			tip = Vector2(tx, target.end.y + TARGET_GAP)
			tail = tip - direction * ARROW_LENGTH
			box_pos = Vector2(clampf(tx - box_size.x * 0.5, EDGE_MARGIN, maxf(EDGE_MARGIN, view.x - EDGE_MARGIN - box_size.x)), tail.y)
		_:
			direction = Vector2.DOWN
			tip = Vector2(tx, target.position.y - TARGET_GAP)
			tail = tip - direction * ARROW_LENGTH
			box_pos = Vector2(clampf(tx - box_size.x * 0.5, EDGE_MARGIN, maxf(EDGE_MARGIN, view.x - EDGE_MARGIN - box_size.x)), tail.y - box_size.y)
	var normal: Vector2 = direction.orthogonal()
	var base: Vector2 = tip - direction * HEAD_LENGTH
	var poly: PackedVector2Array = PackedVector2Array([
		tail + normal * (SHAFT_WIDTH * 0.5),
		base + normal * (SHAFT_WIDTH * 0.5),
		base + normal * half_head,
		tip,
		base - normal * half_head,
		base - normal * (SHAFT_WIDTH * 0.5),
		tail - normal * (SHAFT_WIDTH * 0.5),
	])
	var low: Vector2 = poly[0]
	var high: Vector2 = poly[0]
	for point: Vector2 in poly:
		low = Vector2(minf(low.x, point.x), minf(low.y, point.y))
		high = Vector2(maxf(high.x, point.x), maxf(high.y, point.y))
	var bounds: Rect2 = Rect2(low, high - low)
	var has_box: bool = box_size != Vector2.ZERO
	var box: Rect2 = Rect2(box_pos, box_size) if has_box else Rect2()
	var full: Rect2 = bounds.merge(box) if has_box else bounds
	var view_rect: Rect2 = Rect2(Vector2(EDGE_MARGIN, EDGE_MARGIN), view - Vector2(EDGE_MARGIN * 2.0, EDGE_MARGIN * 2.0))
	return {
		"side": best_side,
		"dir": direction,
		"tip": tip,
		"tail": tail,
		"poly": poly,
		"bounds": bounds,
		"box": box,
		"has_box": has_box,
		"rect": full,
		"fits": view_rect.encloses(full) and not full.intersects(target),
	}
