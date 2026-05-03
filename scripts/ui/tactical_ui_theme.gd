class_name TacticalUITheme
extends RefCounted

const COLOR_PANEL := Color(0.10, 0.12, 0.15, 0.96)
const COLOR_PANEL_ALT := Color(0.14, 0.16, 0.20, 0.96)
const COLOR_PANEL_SELECTED := Color(0.18, 0.22, 0.27, 0.98)
const COLOR_BORDER := Color(0.34, 0.39, 0.46, 1.0)
const COLOR_BORDER_SELECTED := Color(0.62, 0.70, 0.78, 1.0)
const COLOR_TEXT := Color(0.86, 0.89, 0.92, 1.0)
const COLOR_TEXT_MUTED := Color(0.62, 0.67, 0.72, 1.0)
const COLOR_TEXT_DARK := Color(0.13, 0.16, 0.20, 1.0)
const COLOR_ACCENT := Color(0.37, 0.67, 0.86, 1.0)
const COLOR_SUCCESS := Color(0.36, 0.72, 0.48, 1.0)
const COLOR_WARNING := Color(0.88, 0.68, 0.30, 1.0)
const COLOR_DANGER := Color(0.82, 0.31, 0.30, 1.0)
const COLOR_NEUTRAL := Color(0.46, 0.51, 0.58, 1.0)

const CORNER_RADIUS := 6
const COMPACT_ICON_SIZE := Vector2(18.0, 18.0)
const TOOL_ICON_SIZE := Vector2(24.0, 24.0)
const CARD_PADDING := Vector4(8.0, 6.0, 8.0, 6.0)
const BADGE_PADDING := Vector4(7.0, 3.0, 7.0, 3.0)


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
	label.add_theme_stylebox_override("normal", build_flat_stylebox(color.darkened(0.30), color.lightened(0.08), 5, 1, BADGE_PADDING))
	label.add_theme_color_override("font_color", COLOR_TEXT)
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
	button.add_theme_stylebox_override("normal", build_flat_stylebox(COLOR_PANEL_ALT, color.darkened(0.10), 5, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_stylebox_override("hover", build_flat_stylebox(COLOR_PANEL_SELECTED, color, 5, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_stylebox_override("pressed", build_flat_stylebox(color.darkened(0.28), color.lightened(0.12), 5, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_stylebox_override("disabled", build_flat_stylebox(Color(0.10, 0.11, 0.13, 0.82), COLOR_NEUTRAL.darkened(0.25), 5, 1, Vector4(8.0, 4.0, 8.0, 4.0)))
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", COLOR_TEXT)
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_color_override("font_focus_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED.darkened(0.16))
	button.add_theme_font_size_override("font_size", 9)


static func style_progress_bar(progress_bar: ProgressBar, status_key: String = "neutral") -> void:
	if progress_bar == null:
		return
	var color := status_color(status_key)
	progress_bar.add_theme_stylebox_override("background", build_flat_stylebox(Color(0.05, 0.06, 0.08, 0.96), COLOR_BORDER.darkened(0.18), 4, 1, Vector4.ZERO))
	progress_bar.add_theme_stylebox_override("fill", build_flat_stylebox(color.darkened(0.12), color.lightened(0.10), 4, 0, Vector4.ZERO))


static func build_flat_stylebox(fill_color: Color, border_color: Color, radius: int = CORNER_RADIUS, border_width: int = 1, content_margin: Vector4 = Vector4.ZERO) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
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
	return stylebox
