class_name ContextualHelpPopup
extends Control

const SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")

const EDGE_MARGIN: float = 16.0
const TARGET_GAP: float = 8.0
const COMPACT_HEIGHT_HINT: float = 140.0
const DETAIL_HEIGHT_HINT: float = 260.0

var _title_label: Label = null
var _compact_label: Label = null
var _detail_label: Label = null
var _frame: PanelContainer = null
var _current_help_id: String = ""
var _detail_visible: bool = false
var _last_target_rect: Rect2 = Rect2()
var _last_viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	_ensure_nodes()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


func show_help(payload: Dictionary, target_rect: Rect2, viewport_size: Vector2, include_detail: bool = false) -> void:
	_ensure_nodes()
	_current_help_id = String(payload.get("help_id", ""))
	_detail_visible = include_detail or bool(payload.get("include_detail", false)) or String(payload.get("level", "")) == SERVICE_SCRIPT.LEVEL_DETAIL
	_last_target_rect = target_rect
	_last_viewport_size = viewport_size
	_title_label.text = String(payload.get("title", ""))
	_compact_label.text = "\n".join(_to_string_lines(Array(payload.get("compact_lines", []))))
	_detail_label.text = "\n".join(_to_string_lines(Array(payload.get("detail_lines", []))))
	_detail_label.visible = _detail_visible and not _detail_label.text.strip_edges().is_empty()
	var preferred_size: Vector2 = Vector2(
		float(SERVICE_SCRIPT.DEFAULT_DETAIL_MAX_WIDTH_PX if _detail_visible else SERVICE_SCRIPT.DEFAULT_COMPACT_MAX_WIDTH_PX),
		DETAIL_HEIGHT_HINT if _detail_visible else COMPACT_HEIGHT_HINT
	)
	var popup_rect: Rect2 = calculate_popup_rect(target_rect, viewport_size, _detail_visible, preferred_size)
	var text_width: float = maxf(96.0, popup_rect.size.x - 24.0)
	_title_label.custom_minimum_size = Vector2(text_width, 0.0)
	_compact_label.custom_minimum_size = Vector2(text_width, 0.0)
	_detail_label.custom_minimum_size = Vector2(text_width, 0.0)
	custom_minimum_size = Vector2.ZERO
	position = popup_rect.position
	size = popup_rect.size
	visible = not _current_help_id.is_empty()


func hide_help() -> void:
	visible = false
	_current_help_id = ""
	_detail_visible = false


func get_diagnostic_snapshot() -> Dictionary:
	_ensure_nodes()
	return {
		"visible": visible,
		"help_id": _current_help_id,
		"detail_visible": _detail_visible,
		"position": position,
		"size": size,
		"last_target_rect": _last_target_rect,
		"last_viewport_size": _last_viewport_size,
		"title_autowrap": _title_label.autowrap_mode,
		"compact_autowrap": _compact_label.autowrap_mode,
		"detail_autowrap": _detail_label.autowrap_mode,
		"compact_max_width_px": SERVICE_SCRIPT.DEFAULT_COMPACT_MAX_WIDTH_PX,
		"detail_max_width_px": SERVICE_SCRIPT.DEFAULT_DETAIL_MAX_WIDTH_PX,
		"max_viewport_height_ratio": SERVICE_SCRIPT.DEFAULT_MAX_VIEWPORT_HEIGHT_RATIO,
	}


static func calculate_popup_rect(target_rect: Rect2, viewport_size: Vector2, detail: bool = false, preferred_size: Vector2 = Vector2.ZERO) -> Rect2:
	var max_width: float = float(SERVICE_SCRIPT.DEFAULT_DETAIL_MAX_WIDTH_PX if detail else SERVICE_SCRIPT.DEFAULT_COMPACT_MAX_WIDTH_PX)
	var width: float = preferred_size.x if preferred_size.x > 0.0 else max_width
	width = clampf(width, 220.0, minf(max_width, maxf(220.0, viewport_size.x - EDGE_MARGIN * 2.0)))
	var height_hint: float = preferred_size.y if preferred_size.y > 0.0 else (DETAIL_HEIGHT_HINT if detail else COMPACT_HEIGHT_HINT)
	var max_height: float = maxf(96.0, viewport_size.y * SERVICE_SCRIPT.DEFAULT_MAX_VIEWPORT_HEIGHT_RATIO)
	var height: float = clampf(height_hint, 96.0, max_height)
	var right_space: float = viewport_size.x - target_rect.end.x - EDGE_MARGIN
	var left_space: float = target_rect.position.x - EDGE_MARGIN
	var bottom_space: float = viewport_size.y - target_rect.end.y - EDGE_MARGIN
	var top_space: float = target_rect.position.y - EDGE_MARGIN
	var x: float = target_rect.end.x + TARGET_GAP
	var y: float = target_rect.position.y
	if right_space >= width:
		x = target_rect.end.x + TARGET_GAP
	elif left_space >= width:
		x = target_rect.position.x - width - TARGET_GAP
	elif bottom_space >= height:
		x = target_rect.position.x
		y = target_rect.end.y + TARGET_GAP
	elif top_space >= height:
		x = target_rect.position.x
		y = target_rect.position.y - height - TARGET_GAP
	else:
		var horizontal_space: float = maxf(left_space, right_space)
		var vertical_space: float = maxf(top_space, bottom_space)
		if horizontal_space >= vertical_space:
			x = target_rect.position.x - width - TARGET_GAP if left_space > right_space else target_rect.end.x + TARGET_GAP
		else:
			x = target_rect.position.x
			y = target_rect.position.y - height - TARGET_GAP if top_space > bottom_space else target_rect.end.y + TARGET_GAP
	x = clampf(x, EDGE_MARGIN, maxf(EDGE_MARGIN, viewport_size.x - width - EDGE_MARGIN))
	y = clampf(y, EDGE_MARGIN, maxf(EDGE_MARGIN, viewport_size.y - height - EDGE_MARGIN))
	return Rect2(Vector2(x, y), Vector2(width, height))


func _ensure_nodes() -> void:
	if _title_label != null and is_instance_valid(_title_label):
		return
	clip_contents = true
	_frame = PanelContainer.new()
	_frame.name = "HelpFrame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_frame)
	var margin := MarginContainer.new()
	margin.name = "HelpMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_frame.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "HelpVBox"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.clip_text = true
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 15)
	box.add_child(_title_label)
	_compact_label = Label.new()
	_compact_label.name = "CompactLabel"
	_compact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_compact_label.clip_text = false
	_compact_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_compact_label.add_theme_font_size_override("font_size", 13)
	box.add_child(_compact_label)
	_detail_label = Label.new()
	_detail_label.name = "DetailLabel"
	_detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.clip_text = false
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_font_size_override("font_size", 12)
	_detail_label.visible = false
	box.add_child(_detail_label)


func _to_string_lines(lines: Array) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for line_variant in lines:
		var line: String = String(line_variant).strip_edges()
		if not line.is_empty():
			result.append(line)
	return result
