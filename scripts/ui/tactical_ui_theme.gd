class_name TacticalUITheme
extends RefCounted

const COLOR_PANEL := Color("151c21")
const COLOR_PANEL_ALT := Color("252d33")
const COLOR_PANEL_SELECTED := Color("0c1114")
const COLOR_BORDER := Color("4d5a63")
const COLOR_BORDER_SELECTED := Color("f2c94c")
const COLOR_TEXT := Color("edf3f6")
const COLOR_TEXT_MUTED := Color("a9b4bc")
const COLOR_TEXT_DARK := Color("1e252a")
const COLOR_ACCENT := Color("63d1d2")
const COLOR_SUCCESS := Color("69c391")
const COLOR_WARNING := Color("d89b31")
const COLOR_DANGER := Color("d66c66")
const COLOR_NEUTRAL := Color("8e9aa3")

const CORNER_RADIUS := 6
const COMPACT_ICON_SIZE := Vector2(18.0, 18.0)
const TOOL_ICON_SIZE := Vector2(24.0, 24.0)
const CARD_PADDING := Vector4(8.0, 6.0, 8.0, 6.0)
const BADGE_PADDING := Vector4(7.0, 3.0, 7.0, 3.0)
const COLOR_BUTTON_LIGHT := Color("d9dee7")
const COLOR_BUTTON_BORDER := Color("78848d")
const COLOR_FEEDBACK_BUBBLE_TEXT := COLOR_TEXT_DARK
const COLOR_FEEDBACK_BUBBLE_OUTLINE := Color("edf3f6")
const FEEDBACK_BUBBLE_LABEL_FONT_SIZE := 11

static var _flat_stylebox_cache: Dictionary = {}


static func status_color(status_key: String) -> Color:
	match status_key.strip_edges().to_lower():
		"success", "ready", "go", "active":
			return COLOR_SUCCESS
		"warning", "contact", "suppressed", "pending":
			return COLOR_WARNING
		"danger", "critical", "pinned", "blocked":
			return COLOR_DANGER
		"accent", "selected", "command":
			return COLOR_ACCENT
		_:
			return COLOR_NEUTRAL


static func style_card(panel: PanelContainer, selected: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override(
		"panel",
		build_flat_stylebox(
			COLOR_PANEL_SELECTED if selected else COLOR_PANEL,
			COLOR_BORDER_SELECTED if selected else COLOR_BORDER,
			CORNER_RADIUS,
			1,
			CARD_PADDING
		)
	)


static func style_badge(label: Label, status_key: String) -> void:
	if label == null:
		return
	var color := status_color(status_key)
	label.add_theme_stylebox_override("normal", build_flat_stylebox(color, color, 6, 1, BADGE_PADDING, 0.16))
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 9)


static func style_label(label: Label, muted: bool = false, font_size: int = 10) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", COLOR_TEXT_MUTED if muted else COLOR_TEXT)
	label.add_theme_font_size_override("font_size", font_size)


static func style_command_button(button: Button, status_key: String = "neutral") -> void:
	if button == null:
		return
	var color := status_color(status_key)
	var normal_fill := COLOR_DANGER if status_key == "danger" else (COLOR_SUCCESS if status_key == "success" or status_key == "go" else COLOR_BUTTON_LIGHT)
	var normal_text := COLOR_TEXT_DARK
	var hover_fill := normal_fill.lightened(0.05) if normal_fill != COLOR_BUTTON_LIGHT else Color("edf3f6")
	var pressed_fill := normal_fill.darkened(0.08) if normal_fill != COLOR_BUTTON_LIGHT else Color("bcc7d0")
	if status_key == "accent" or status_key == "command":
		normal_fill = COLOR_PANEL_SELECTED
		hover_fill = Color("182027")
		pressed_fill = Color("0a0f12")
		normal_text = COLOR_TEXT
	if status_key == "warning":
		normal_fill = COLOR_BUTTON_LIGHT
		hover_fill = Color("edf3f6")
		pressed_fill = Color("bcc7d0")
	button.add_theme_stylebox_override("normal", build_flat_stylebox(normal_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_stylebox_override("hover", build_flat_stylebox(hover_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_stylebox_override("pressed", build_flat_stylebox(pressed_fill, COLOR_BUTTON_BORDER, 6, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_stylebox_override("disabled", build_flat_stylebox(Color("586067"), COLOR_BORDER, 6, 1, Vector4(8.0, 4.0, 8.0, 4.0), 0.82))
	button.add_theme_color_override("font_color", normal_text)
	button.add_theme_color_override("font_hover_color", normal_text)
	button.add_theme_color_override("font_pressed_color", normal_text)
	button.add_theme_color_override("font_focus_color", normal_text)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED.darkened(0.16))
	button.add_theme_font_size_override("font_size", 9)


static func style_progress_bar(progress_bar: ProgressBar, status_key: String = "neutral") -> void:
	if progress_bar == null:
		return
	var color := status_color(status_key)
	progress_bar.add_theme_stylebox_override("background", build_flat_stylebox(Color("0b1014"), Color("35414a"), 6, 1, Vector4.ZERO))
	progress_bar.add_theme_stylebox_override("fill", build_flat_stylebox(color, color, 5, 0, Vector4.ZERO))


static func build_flat_stylebox(fill_color: Color, border_color: Color, radius: int = CORNER_RADIUS, border_width: int = 1, content_margin: Vector4 = Vector4.ZERO, alpha: float = 1.0) -> StyleBoxFlat:
	var cache_key: String = _build_flat_stylebox_cache_key(fill_color, border_color, radius, border_width, content_margin, alpha)
	if _flat_stylebox_cache.has(cache_key):
		return _flat_stylebox_cache[cache_key] as StyleBoxFlat
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(fill_color.r, fill_color.g, fill_color.b, alpha)
	stylebox.border_color = border_color
	stylebox.border_width_left = border_width
	stylebox.border_width_top = border_width
	stylebox.border_width_right = border_width
	stylebox.border_width_bottom = border_width
	stylebox.corner_radius_top_left = radius
	stylebox.corner_radius_top_right = radius
	stylebox.corner_radius_bottom_left = radius
	stylebox.corner_radius_bottom_right = radius
	stylebox.content_margin_left = content_margin.x
	stylebox.content_margin_top = content_margin.y
	stylebox.content_margin_right = content_margin.z
	stylebox.content_margin_bottom = content_margin.w
	_flat_stylebox_cache[cache_key] = stylebox
	return stylebox


static func get_stylebox_cache_snapshot() -> Dictionary:
	return {
		"flat_stylebox_cache_count": _flat_stylebox_cache.size(),
		"stylebox_reuse_enabled": true,
		"cache_keys": _flat_stylebox_cache.keys(),
	}


static func clear_stylebox_cache() -> void:
	_flat_stylebox_cache.clear()


static func _build_flat_stylebox_cache_key(fill_color: Color, border_color: Color, radius: int, border_width: int, content_margin: Vector4, alpha: float) -> String:
	return "%s|%s|%d|%d|%.2f,%.2f,%.2f,%.2f|%.3f" % [
		fill_color.to_html(true),
		border_color.to_html(true),
		radius,
		border_width,
		content_margin.x,
		content_margin.y,
		content_margin.z,
		content_margin.w,
		alpha,
	]
