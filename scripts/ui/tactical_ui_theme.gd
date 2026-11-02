class_name TacticalUITheme
extends RefCounted

const COLOR_PANEL := Color("071f29")
const COLOR_PANEL_ALT := Color("102f3b")
const COLOR_PANEL_SELECTED := Color("092630")
const COLOR_BORDER := Color("2e7b8a")
const COLOR_BORDER_SELECTED := Color("ffd348")
const COLOR_TEXT := Color("f4f2e9")
const COLOR_TEXT_MUTED := Color("a8c0ca")
const COLOR_TEXT_DARK := Color("07202a")
const COLOR_ACCENT := Color("29e1e7")
const COLOR_SUCCESS := Color("37d9bf")
const COLOR_WARNING := Color("ffd348")
const COLOR_DANGER := Color("f47572")
const COLOR_NEUTRAL := Color("8caab8")
const HEADING_FONT_PATH: String = "res://Assets/curated/ui_native_r4/BarlowCondensed-Bold.ttf"

const CORNER_RADIUS := 6
const SPACING := 8
const FONT_SIZE := 14
const BUTTON_FONT_SIZE := 13
const ACTION_TILE_SIZE := Vector2(64.0, 64.0)
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
static var _native_theme: Theme
static var _heading_font: Font


static func get_theme() -> Theme:
	if _native_theme != null:
		return _native_theme
	var result := Theme.new()
	result.default_font_size = FONT_SIZE
	var panel := build_flat_stylebox(COLOR_PANEL, COLOR_BORDER, CORNER_RADIUS, 1, Vector4(8, 8, 8, 8), 1.0, 3)
	var inset := build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_BORDER, 4, 1, Vector4(8, 6, 8, 6))
	var focus := build_flat_stylebox(Color.TRANSPARENT, COLOR_ACCENT, 5, 2)
	var selected := build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_BORDER_SELECTED, 4, 1, Vector4(8, 6, 8, 6))
	var hover := build_flat_stylebox(COLOR_PANEL_ALT.lightened(0.05), COLOR_ACCENT, 4, 1, Vector4(8, 6, 8, 6))
	for type_name in ["Control", "Label", "Button", "OptionButton", "MenuButton", "MenuBar", "CheckBox", "CheckButton", "LineEdit", "TextEdit", "CodeEdit", "ItemList", "Tree", "PopupMenu", "ProgressBar", "TabBar", "TabContainer", "TooltipLabel"]:
		result.set_color("font_color", type_name, COLOR_TEXT)
		result.set_color("font_hover_color", type_name, COLOR_TEXT)
		result.set_color("font_focus_color", type_name, COLOR_TEXT)
		result.set_color("font_disabled_color", type_name, COLOR_TEXT_MUTED.darkened(0.18))
		result.set_font_size("font_size", type_name, FONT_SIZE)
	for type_name in ["Panel", "PanelContainer", "PopupPanel", "PopupMenu", "AcceptDialog", "ConfirmationDialog"]:
		result.set_stylebox("panel", type_name, panel)
	result.set_stylebox("panel", "TooltipPanel", build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_BORDER, 5, 1, Vector4(8, 8, 8, 8), 1.0, 3))
	result.set_font_size("font_size", "TooltipLabel", 13)
	result.set_stylebox("embedded_border", "Window", panel)
	result.set_stylebox("embedded_unfocused_border", "Window", panel)
	result.set_color("title_color", "Window", COLOR_TEXT)
	result.set_font_size("title_font_size", "Window", FONT_SIZE)
	for type_name in ["Button", "OptionButton", "MenuButton", "MenuBar"]:
		_set_button_theme(result, type_name)
	for type_name in ["CheckBox", "CheckButton"]:
		_set_button_theme(result, type_name)
		for state in ["normal", "pressed", "disabled"]:
			result.set_stylebox(state, type_name, build_flat_stylebox(Color.TRANSPARENT, Color.TRANSPARENT, 4, 0, Vector4(4, 4, 4, 4)))
	for type_name in ["LineEdit", "TextEdit", "CodeEdit"]:
		result.set_stylebox("normal", type_name, inset)
		result.set_stylebox("read_only", type_name, build_flat_stylebox(COLOR_PANEL, COLOR_BORDER.darkened(0.2), 4, 1, Vector4(8, 6, 8, 6)))
		result.set_stylebox("focus", type_name, focus)
		result.set_color("font_placeholder_color", type_name, COLOR_TEXT_MUTED)
		result.set_color("font_uneditable_color", type_name, COLOR_TEXT_MUTED)
		result.set_color("font_readonly_color", type_name, COLOR_TEXT_MUTED)
		result.set_color("caret_color", type_name, COLOR_ACCENT)
		result.set_color("selection_color", type_name, Color(COLOR_ACCENT, 0.3))
		result.set_color("font_selected_color", type_name, COLOR_TEXT)
	result.set_stylebox("hover", "PopupMenu", hover)
	result.set_color("font_hover_color", "PopupMenu", COLOR_TEXT)
	result.set_color("font_accelerator_color", "PopupMenu", COLOR_TEXT_MUTED)
	result.set_color("font_separator_color", "PopupMenu", COLOR_TEXT_MUTED)
	result.set_constant("v_separation", "PopupMenu", SPACING)
	for type_name in ["HSeparator", "VSeparator"]:
		result.set_stylebox("separator", type_name, build_flat_stylebox(COLOR_BORDER, COLOR_BORDER, 0, 0))
		result.set_constant("separation", type_name, SPACING)
	result.set_stylebox("separator", "PopupMenu", build_flat_stylebox(COLOR_BORDER, COLOR_BORDER, 0, 0, Vector4(0, 1, 0, 1)))
	for type_name in ["ItemList", "Tree"]:
		result.set_stylebox("panel", type_name, inset)
		result.set_stylebox("focus", type_name, focus)
		result.set_stylebox("selected", type_name, selected)
		result.set_stylebox("selected_focus", type_name, selected)
		result.set_stylebox("hovered", type_name, hover)
		result.set_stylebox("cursor", type_name, focus)
		result.set_stylebox("cursor_unfocused", type_name, build_flat_stylebox(Color.TRANSPARENT, COLOR_BORDER_SELECTED, 4, 1))
		result.set_color("font_selected_color", type_name, COLOR_TEXT)
	result.set_stylebox("title_button_normal", "Tree", panel)
	result.set_stylebox("title_button_hover", "Tree", hover)
	result.set_stylebox("title_button_pressed", "Tree", selected)
	for type_name in ["TabBar", "TabContainer"]:
		result.set_stylebox("tab_unselected", type_name, build_flat_stylebox(COLOR_PANEL, COLOR_BORDER, 4, 1, Vector4(8, 6, 8, 6)))
		result.set_stylebox("tab_selected", type_name, selected)
		result.set_stylebox("tab_hovered", type_name, hover)
		result.set_stylebox("tab_disabled", type_name, build_flat_stylebox(COLOR_PANEL, COLOR_BORDER.darkened(0.2), 4, 1, Vector4(8, 6, 8, 6)))
		result.set_stylebox("tab_focus", type_name, focus)
		result.set_color("font_selected_color", type_name, COLOR_TEXT)
		result.set_color("font_unselected_color", type_name, COLOR_TEXT_MUTED)
		result.set_color("font_hovered_color", type_name, COLOR_TEXT)
	result.set_stylebox("panel", "TabContainer", panel)
	result.set_stylebox("panel", "ScrollContainer", build_flat_stylebox(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	result.set_stylebox("focus", "ScrollContainer", focus)
	for type_name in ["HScrollBar", "VScrollBar"]:
		result.set_stylebox("scroll", type_name, build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_PANEL_SELECTED, 4, 0, Vector4(4, 4, 4, 4)))
		result.set_stylebox("scroll_focus", type_name, focus)
		result.set_stylebox("grabber", type_name, build_flat_stylebox(COLOR_BORDER, COLOR_BORDER, 4, 0, Vector4(4, 4, 4, 4)))
		result.set_stylebox("grabber_highlight", type_name, build_flat_stylebox(COLOR_ACCENT.darkened(0.2), COLOR_ACCENT, 4, 0, Vector4(4, 4, 4, 4)))
		result.set_stylebox("grabber_pressed", type_name, build_flat_stylebox(COLOR_ACCENT, COLOR_ACCENT, 4, 0, Vector4(4, 4, 4, 4)))
	for type_name in ["HSlider", "VSlider"]:
		result.set_stylebox("slider", type_name, build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_BORDER, 3, 1, Vector4(3, 3, 3, 3)))
		result.set_stylebox("grabber_area", type_name, build_flat_stylebox(COLOR_ACCENT.darkened(0.2), COLOR_ACCENT, 3, 0))
		result.set_stylebox("grabber_area_highlight", type_name, build_flat_stylebox(COLOR_ACCENT, COLOR_ACCENT, 3, 0))
	result.set_stylebox("background", "ProgressBar", build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_BORDER, 4, 1, Vector4.ZERO))
	result.set_stylebox("fill", "ProgressBar", build_flat_stylebox(COLOR_ACCENT, COLOR_ACCENT, 3, 0))
	for type_name in ["HBoxContainer", "VBoxContainer"]:
		result.set_constant("separation", type_name, SPACING)
	result.set_constant("h_separation", "GridContainer", SPACING)
	result.set_constant("v_separation", "GridContainer", SPACING)
	result.set_color("default_color", "RichTextLabel", COLOR_TEXT)
	result.set_color("selection_color", "RichTextLabel", Color(COLOR_ACCENT, 0.3))
	result.set_stylebox("focus", "RichTextLabel", focus)
	for font_key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
		result.set_font_size(font_key, "RichTextLabel", FONT_SIZE)
	_native_theme = result
	return _native_theme


static func apply_screen(root: Control) -> void:
	if root != null and root.theme != get_theme():
		root.theme = get_theme()


static func get_heading_font() -> Font:
	if _heading_font == null:
		_heading_font = load(HEADING_FONT_PATH) as Font
	return _heading_font


static func style_section_heading(label: Label, font_size: int = 20) -> void:
	_style_heading(label, font_size, "section")


static func style_screen_heading(label: Label, font_size: int = 26) -> void:
	_style_heading(label, font_size, "screen")


static func _style_heading(label: Label, font_size: int, kind: String) -> void:
	if label == null:
		return
	label.add_theme_font_override("font", get_heading_font())
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_color_override("font_shadow_color", Color("02141c"))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.set_meta("native_heading_kind", kind)


static func _set_button_theme(result: Theme, type_name: String) -> void:
	result.set_stylebox("normal", type_name, build_flat_stylebox(COLOR_PANEL_ALT, COLOR_BORDER, 5, 1, Vector4(8, 6, 8, 6)))
	result.set_stylebox("hover", type_name, build_flat_stylebox(COLOR_PANEL_ALT.lightened(0.08), COLOR_ACCENT, 5, 1, Vector4(8, 6, 8, 6)))
	result.set_stylebox("pressed", type_name, build_flat_stylebox(COLOR_PANEL_SELECTED, COLOR_ACCENT, 5, 1, Vector4(8, 6, 8, 6)))
	result.set_stylebox("hover_pressed", type_name, build_flat_stylebox(COLOR_PANEL_ALT, COLOR_ACCENT, 5, 1, Vector4(8, 6, 8, 6)))
	result.set_stylebox("disabled", type_name, build_flat_stylebox(COLOR_PANEL, COLOR_BORDER.darkened(0.25), 5, 1, Vector4(8, 6, 8, 6)))
	result.set_stylebox("focus", type_name, build_flat_stylebox(Color.TRANSPARENT, COLOR_ACCENT, 5, 2))
	result.set_color("font_pressed_color", type_name, COLOR_TEXT)
	result.set_color("font_hover_pressed_color", type_name, COLOR_TEXT)
	result.set_font_size("font_size", type_name, BUTTON_FONT_SIZE)
	result.set_constant("h_separation", type_name, SPACING)


static func style_action_tile(button: Button, selected: bool = false, primary: bool = false) -> void:
	if button == null:
		return
	style_command_button(button, "accent" if primary else ("selected" if selected else "neutral"))
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var base := button.get_theme_stylebox(state) as StyleBoxFlat
		button.add_theme_stylebox_override(state, build_flat_stylebox(base.bg_color, base.border_color, base.corner_radius_top_left, base.border_width_left, Vector4(4, 4, 4, 4)))
	button.custom_minimum_size = ACTION_TILE_SIZE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_constant_override("icon_max_width", 24)


static func status_color(status_key: String) -> Color:
	match status_key.strip_edges().to_lower():
		"success", "ready", "go", "active":
			return COLOR_SUCCESS
		"warning", "contact", "suppressed", "pending":
			return COLOR_WARNING
		"danger", "critical", "pinned", "blocked":
			return COLOR_DANGER
		"selected":
			return COLOR_BORDER_SELECTED
		"accent", "command", "transit", "transport":
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
			CARD_PADDING,
			1.0,
			2
		)
	)


static func style_badge(label: Label, status_key: String) -> void:
	if label == null:
		return
	var color := status_color(status_key)
	label.add_theme_stylebox_override("normal", build_flat_stylebox(color, color, 6, 1, BADGE_PADDING, 0.16))
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 11)


static func style_label(label: Label, muted: bool = false, font_size: int = 13) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", COLOR_TEXT_MUTED if muted else COLOR_TEXT)
	label.add_theme_font_size_override("font_size", font_size)


static func style_command_button(button: Button, status_key: String = "neutral") -> void:
	if button == null:
		return
	button.theme = get_theme()
	var primary := status_key in ["accent", "command", "go"]
	var normal_fill := (COLOR_BORDER_SELECTED if status_key == "go" else COLOR_ACCENT) if primary else COLOR_PANEL_ALT
	var border := COLOR_BORDER_SELECTED if status_key == "selected" else COLOR_BORDER
	var normal_text := COLOR_TEXT_DARK if primary else COLOR_TEXT
	if status_key == "danger":
		normal_fill = COLOR_DANGER
		normal_text = COLOR_TEXT_DARK
	elif status_key == "success":
		normal_fill = COLOR_SUCCESS
		normal_text = COLOR_TEXT_DARK
	elif status_key == "warning":
		border = COLOR_WARNING
	button.add_theme_stylebox_override("normal", build_flat_stylebox(normal_fill, border, 5, 1, Vector4(8, 4, 8, 4)))
	button.add_theme_stylebox_override("hover", build_flat_stylebox(normal_fill.lightened(0.08), COLOR_ACCENT if status_key != "selected" else COLOR_BORDER_SELECTED, 5, 1, Vector4(8, 4, 8, 4)))
	button.add_theme_stylebox_override("pressed", build_flat_stylebox(normal_fill.darkened(0.12), COLOR_ACCENT if status_key != "selected" else COLOR_BORDER_SELECTED, 5, 1, Vector4(8, 4, 8, 4)))
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	button.add_theme_stylebox_override("disabled", build_flat_stylebox(COLOR_PANEL, COLOR_BORDER.darkened(0.25), 5, 1, Vector4(8, 4, 8, 4)))
	button.add_theme_stylebox_override("focus", build_flat_stylebox(Color.TRANSPARENT, COLOR_ACCENT, 5, 2))
	button.add_theme_color_override("font_color", normal_text)
	button.add_theme_color_override("font_hover_color", normal_text)
	button.add_theme_color_override("font_pressed_color", normal_text)
	button.add_theme_color_override("font_focus_color", normal_text)
	button.add_theme_color_override("font_hover_pressed_color", normal_text)
	button.add_theme_color_override("font_disabled_color", COLOR_TEXT_MUTED.darkened(0.16))
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	if button is OptionButton:
		(button as OptionButton).get_popup().theme = get_theme()


static func style_progress_bar(progress_bar: ProgressBar, status_key: String = "neutral") -> void:
	if progress_bar == null:
		return
	var color := status_color(status_key)
	progress_bar.add_theme_stylebox_override("background", build_flat_stylebox(COLOR_PANEL, COLOR_BORDER, 6, 1, Vector4.ZERO))
	progress_bar.add_theme_stylebox_override("fill", build_flat_stylebox(color, color, 5, 0, Vector4.ZERO))


static func build_flat_stylebox(fill_color: Color, border_color: Color, radius: int = CORNER_RADIUS, border_width: int = 1, content_margin: Vector4 = Vector4.ZERO, alpha: float = 1.0, shadow_size: int = 0) -> StyleBoxFlat:
	var cache_key: String = _build_flat_stylebox_cache_key(fill_color, border_color, radius, border_width, content_margin, alpha) + "|%d" % shadow_size
	if _flat_stylebox_cache.has(cache_key):
		return _flat_stylebox_cache[cache_key] as StyleBoxFlat
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(fill_color, fill_color.a * alpha)
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
	stylebox.shadow_size = shadow_size
	stylebox.shadow_color = Color(0, 0, 0, 0.24)
	stylebox.shadow_offset = Vector2(0, 2) if shadow_size > 0 else Vector2.ZERO
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
