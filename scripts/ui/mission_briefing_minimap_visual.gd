class_name MissionBriefingMinimapVisual
extends Control

const MAP_PADDING: float = 8.0

var _visual_snapshot: Dictionary = {}


func set_visual_snapshot(snapshot: Dictionary) -> void:
	_visual_snapshot = snapshot.duplicate(true)
	set_meta("mission_briefing_minimap_visual_snapshot", _visual_snapshot.duplicate(true))
	tooltip_text = _build_tooltip_text()
	queue_redraw()


func get_visual_snapshot() -> Dictionary:
	return _visual_snapshot.duplicate(true)


func _draw() -> void:
	var content_rect: Rect2 = Rect2(Vector2(MAP_PADDING, MAP_PADDING), Vector2(maxf(size.x - MAP_PADDING * 2.0, 1.0), maxf(size.y - MAP_PADDING * 2.0, 1.0)))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#10181d"), true)
	draw_rect(content_rect, Color("#172229"), true)
	draw_rect(content_rect, Color("#38505e"), false, 1.0)
	if not bool(_visual_snapshot.get("configured", false)):
		return
	_draw_terrain_samples(content_rect)
	_draw_overlay_entries(content_rect)
	draw_rect(content_rect, _with_alpha(Color("#d7e2e8"), 0.35), false, 1.0)


func _draw_terrain_samples(content_rect: Rect2) -> void:
	var samples: Array = Array(_visual_snapshot.get("terrain_samples", []))
	if samples.is_empty():
		return
	var stride: int = maxi(int(_visual_snapshot.get("sample_stride", 1)), 1)
	var grid_size: Dictionary = Dictionary(_visual_snapshot.get("grid_size", {}))
	var sample_size := Vector2(
		maxf(content_rect.size.x * float(stride) / maxf(float(grid_size.get("x", 1)), 1.0), 2.0),
		maxf(content_rect.size.y * float(stride) / maxf(float(grid_size.get("y", 1)), 1.0), 2.0)
	)
	for sample_variant in samples:
		var sample: Dictionary = Dictionary(sample_variant)
		var uv: Vector2 = _dict_to_uv(Dictionary(sample.get("uv", {})))
		var position: Vector2 = _uv_to_position(uv, content_rect)
		var sample_rect := Rect2(position - sample_size * 0.5, sample_size)
		draw_rect(sample_rect, _parse_color(String(sample.get("color_hex", "#344f3f")), Color("#344f3f")), true)


func _draw_overlay_entries(content_rect: Rect2) -> void:
	for entry_variant in Array(_visual_snapshot.get("overlay_entries", [])):
		var entry: Dictionary = Dictionary(entry_variant)
		var uv: Vector2 = _dict_to_uv(Dictionary(entry.get("uv", {})))
		var position: Vector2 = _uv_to_position(uv, content_rect)
		var color: Color = _parse_color(String(entry.get("color_hex", "#d7e2e8")), Color("#d7e2e8"))
		var kind: String = String(entry.get("kind", "note")).strip_edges().to_lower()
		match kind:
			"danger":
				draw_circle(position, 7.0, _with_alpha(color, 0.18))
				draw_arc(position, 8.0, 0.0, TAU, 24, color, 2.0)
			"route":
				draw_circle(position, 4.5, color)
				draw_line(position + Vector2(-8.0, 5.0), position + Vector2(8.0, -5.0), color, 2.0)
			"objective":
				draw_rect(Rect2(position - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), color, true)
				draw_rect(Rect2(position - Vector2(6.0, 6.0), Vector2(12.0, 12.0)), Color("#10181d"), false, 1.0)
			"team_spawn":
				var points: PackedVector2Array = PackedVector2Array([
					position + Vector2(0.0, -7.0),
					position + Vector2(7.0, 0.0),
					position + Vector2(0.0, 7.0),
					position + Vector2(-7.0, 0.0),
				])
				var outline: PackedVector2Array = PackedVector2Array([
					points[0],
					points[1],
					points[2],
					points[3],
					points[0],
				])
				draw_colored_polygon(points, color)
				draw_polyline(outline, Color("#10181d"), 1.0)
			_:
				draw_circle(position, 5.0, color)


func _uv_to_position(uv: Vector2, rect: Rect2) -> Vector2:
	return rect.position + Vector2(uv.x * rect.size.x, uv.y * rect.size.y)


func _dict_to_uv(value: Dictionary) -> Vector2:
	return Vector2(clampf(float(value.get("x", 0.0)), 0.0, 1.0), clampf(float(value.get("y", 0.0)), 0.0, 1.0))


func _parse_color(value: String, fallback: Color) -> Color:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		return fallback
	return Color.html(normalized)


func _with_alpha(color: Color, alpha: float) -> Color:
	var result: Color = color
	result.a = alpha
	return result


func _build_tooltip_text() -> String:
	if not bool(_visual_snapshot.get("configured", false)):
		return "Briefing minimap not configured."
	return "Briefing minimap | %d samples | %d markers" % [
		int(_visual_snapshot.get("sample_count", 0)),
		int(_visual_snapshot.get("entry_count", 0)),
	]
