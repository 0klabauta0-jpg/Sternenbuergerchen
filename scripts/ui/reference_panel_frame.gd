class_name ReferencePanelFrame
extends RefCounted
## Passive native drawing over the owner's background and below its children.
## No Control children, layout/minimum-size writes, input or gameplay state.
const META_KEY := "native_reference_panel_frame"
var _target: WeakRef
var _variant := "frame"
var _selected := false
var _portrait_binding_scheduled := false


static func decorate(target: Control, variant: String = "frame", selected: bool = false) -> void:
	if target == null:
		return
	var painter = target.get_meta(META_KEY) if target.has_meta(META_KEY) else null
	if painter == null:
		painter = ReferencePanelFrame.new()
		painter._target = weakref(target)
		target.set_meta(META_KEY, painter)
		target.draw.connect(painter._paint)
		target.resized.connect(painter._queue_redraw)
		painter._variant = variant
		painter._selected = selected
		target.queue_redraw()
	elif painter._variant != variant or painter._selected != selected:
		painter._variant = variant
		painter._selected = selected
		target.queue_redraw()
	if variant != "portrait" and not painter._portrait_binding_scheduled:
		painter._portrait_binding_scheduled = true
		# Card factories usually create identity controls after styling the panel.
		# Bind once after construction; never scan during drawing or per-frame work.
		painter.call_deferred("_bind_portrait_regions")


func _queue_redraw() -> void:
	var target := _target.get_ref() as Control
	if target != null:
		target.queue_redraw()


func _bind_portrait_regions() -> void:
	var target := _target.get_ref() as Control
	if target == null:
		return
	for child in target.find_children("*Portrait*", "TextureRect", true, false):
		decorate(child as Control, "portrait")


func _paint() -> void:
	var target := _target.get_ref() as Control
	if target == null or target.size.x < 12.0 or target.size.y < 12.0:
		return
	if _variant == "portrait":
		_paint_portrait(target)
		return
	var fill := Color("071f29")
	var border := Color("2e7b8a")
	if target.has_theme_stylebox("panel"):
		var style := target.get_theme_stylebox("panel") as StyleBoxFlat
		if style != null:
			# A5 target/team modules intentionally use transparent divider surfaces.
			if style.bg_color.a <= 0.1:
				return
			fill = style.bg_color
			border = style.border_color
	var selected := _selected or border.is_equal_approx(Color("ffd348"))
	if bool(target.get_meta("native_a5_quiet_frame", false)):
		# Mission A5 uses a single fine, cut-corner edge. Other screen families
		# retain their existing layered frame until separately revised.
		target.draw_polyline(_outline(Rect2(Vector2.ONE, target.size - Vector2.ONE * 2), 5.0), border, 1.0, true)
		return
	var compact := _variant in ["card", "thin_frame", "subtle", "panel", "body"]
	var corner := 4.0 if compact else 7.0
	var outer := Rect2(Vector2.ONE * 1.0, target.size - Vector2.ONE * 2.0)
	var inner := Rect2(Vector2.ONE * 3.0, target.size - Vector2.ONE * 6.0)
	var header_height := 0.0
	if _variant == "card" and target.size.y >= 36.0:
		header_height = minf(24.0, target.size.y * 0.36)
	elif _variant in ["frame", "header", "mission_header"] and target.size.y >= 48.0:
		header_height = minf(36.0, target.size.y * 0.28)
	if header_height > 0.0:
		_paint_header(target, outer, corner, header_height, fill, border)
	# A dark separation groove and inset edge replace the single undifferentiated
	# hairline. Both stay inside the original rect and require no larger margins.
	target.draw_polyline(_outline(outer, corner), Color("020f16"), 3.0, true)
	target.draw_polyline(_outline(outer, corner), border, 1.5 if selected else 1.0, true)
	target.draw_polyline(_outline(inner, maxf(corner - 2.0, 1.0)), Color(border.darkened(0.40), 0.72), 1.0, true)
	var highlight := Color(border.lightened(0.25), 0.80 if selected else 0.55)
	var rail_end := minf(target.size.x - corner - 4.0, maxf(corner + 8.0, target.size.x * 0.36))
	target.draw_line(Vector2(corner + 3.0, 2.5), Vector2(rail_end, 2.5), highlight, 1.0, true)
	if selected:
		target.draw_line(Vector2(3.0, corner + 4.0), Vector2(3.0, target.size.y - corner - 4.0), Color("ffd348"), 2.0, true)


func _paint_header(target: Control, rect: Rect2, corner: float, height: float,
		fill: Color, border: Color) -> void:
	var top := fill.lerp(Color("20505c"), 0.48)
	var bottom := fill.lerp(Color("12323d"), 0.36)
	var bottom_y := rect.position.y + height
	var polygon := PackedVector2Array([
		Vector2(rect.position.x + corner, rect.position.y), Vector2(rect.end.x - corner, rect.position.y),
		Vector2(rect.end.x, rect.position.y + corner), Vector2(rect.end.x, bottom_y),
		Vector2(rect.position.x, bottom_y), Vector2(rect.position.x, rect.position.y + corner)])
	target.draw_polygon(polygon, PackedColorArray([top, top, top, bottom, bottom, top]))
	target.draw_line(Vector2(8.0, bottom_y), Vector2(target.size.x - 8.0, bottom_y),
		Color(border.darkened(0.32), 0.75), 1.0, true)


func _paint_portrait(target: Control) -> void:
	# Preserve the real portrait bytes, filter, crop and slot dimensions. A clear
	# image window helps dark identities without inventing faces or adding tint.
	if target.size.x < 24.0 or target.size.y < 24.0:
		return
	var outer := Rect2(Vector2.ONE * 0.75, target.size - Vector2.ONE * 1.5)
	var inner := Rect2(Vector2.ONE * 2.0, target.size - Vector2.ONE * 4.0)
	target.draw_polyline(_outline(outer, 3.0), Color("020f16"), 2.5, true)
	target.draw_polyline(_outline(outer, 3.0), Color("83a7aa"), 1.0, true)
	target.draw_polyline(_outline(inner, 2.0), Color(0.69, 0.79, 0.75, 0.30), 1.0, true)


func _outline(rect: Rect2, cut: float) -> PackedVector2Array:
	var corner := minf(cut, minf(rect.size.x, rect.size.y) * 0.24)
	return PackedVector2Array([
		Vector2(rect.position.x + corner, rect.position.y), Vector2(rect.end.x - corner, rect.position.y),
		Vector2(rect.end.x, rect.position.y + corner), Vector2(rect.end.x, rect.end.y - corner),
		Vector2(rect.end.x - corner, rect.end.y), Vector2(rect.position.x + corner, rect.end.y),
		Vector2(rect.position.x, rect.end.y - corner), Vector2(rect.position.x, rect.position.y + corner),
		Vector2(rect.position.x + corner, rect.position.y)])
