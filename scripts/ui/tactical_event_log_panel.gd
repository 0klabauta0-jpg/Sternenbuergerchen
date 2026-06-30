class_name TacticalEventLogPanel
extends PanelContainer

const DEFAULT_MAX_VISIBLE_EVENTS: int = 8
const ROW_MIN_HEIGHT: float = 22.0

@export var max_visible_events: int = DEFAULT_MAX_VISIBLE_EVENTS
@export var selected_only: bool = false
@export var collapse_when_empty: bool = true

var _event_entries: Array = []
var _selected_fireteam_ids: PackedStringArray = PackedStringArray()
var _rendered_entries: Array = []
var _last_render_signature: String = ""
var _empty_state_collapsed: bool = false

var _header_label: Label = null
var _count_label: Label = null
var _selected_filter_button: CheckButton = null
var _scroll: ScrollContainer = null
var _entry_list: VBoxContainer = null


func _ready() -> void:
	_ensure_structure()
	_refresh_display()


func set_feedback_snapshot(snapshot: Dictionary) -> void:
	var selected_ids: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in Array(snapshot.get("selected_fireteam_ids", [])):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or selected_ids.has(fireteam_id):
			continue
		selected_ids.append(fireteam_id)
	set_event_entries(Array(snapshot.get("tactical_event_log", [])), selected_ids, selected_only)


func set_event_entries(entries: Array, selected_fireteam_ids: PackedStringArray = PackedStringArray(), show_selected_only: Variant = null) -> void:
	_event_entries.clear()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		_event_entries.append(Dictionary(entry_variant).duplicate(true))
	_selected_fireteam_ids = _normalize_fireteam_ids(selected_fireteam_ids)
	if show_selected_only != null:
		selected_only = bool(show_selected_only)
	_refresh_display()


func set_selected_only(is_enabled: bool) -> void:
	if selected_only == is_enabled:
		return
	selected_only = is_enabled
	_refresh_display(true)


func get_panel_snapshot() -> Dictionary:
	var severity_counts: Dictionary = {}
	for entry_variant in _rendered_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var severity: String = String(Dictionary(entry_variant).get("severity", "info")).strip_edges().to_lower()
		severity_counts[severity] = int(severity_counts.get(severity, 0)) + 1
	var first_event_id: String = ""
	if not _rendered_entries.is_empty() and typeof(_rendered_entries[0]) == TYPE_DICTIONARY:
		first_event_id = String(Dictionary(_rendered_entries[0]).get("event_id", ""))
	return {
		"event_count": _event_entries.size(),
		"rendered_entry_count": _rendered_entries.size(),
		"max_visible_events": max_visible_events,
		"selected_only": selected_only,
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"first_event_id": first_event_id,
		"newest_first": true,
		"scrollable_overflow": _rendered_entries.size() > max_visible_events,
		"severity_counts": severity_counts,
		"global_rect": get_global_rect(),
		"collapse_when_empty": collapse_when_empty,
		"empty_state_collapsed": _empty_state_collapsed,
		"visible": visible,
		"mouse_filter": mouse_filter,
		"visibility_mode": "collapsed_empty" if _empty_state_collapsed else "expanded",
	}


func get_rendered_event_entries() -> Array:
	var result: Array = []
	for entry_variant in _rendered_entries:
		if typeof(entry_variant) == TYPE_DICTIONARY:
			result.append(Dictionary(entry_variant).duplicate(true))
	return result


func _ensure_structure() -> void:
	if _entry_list != null:
		return
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(300.0, 184.0)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.name = "EventLogMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root := VBoxContainer.new()
	root.name = "EventLogVBox"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 5)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.name = "EventLogHeader"
	header.add_theme_constant_override("separation", 6)
	root.add_child(header)

	_header_label = Label.new()
	_header_label.name = "EventLogHeaderLabel"
	_header_label.text = "#19 EVENT LOG"
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_label.add_theme_font_size_override("font_size", 10)
	header.add_child(_header_label)

	_count_label = Label.new()
	_count_label.name = "EventLogCountLabel"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.add_theme_font_size_override("font_size", 9)
	header.add_child(_count_label)

	_selected_filter_button = CheckButton.new()
	_selected_filter_button.name = "EventLogSelectedFilterButton"
	_selected_filter_button.focus_mode = Control.FOCUS_NONE
	_selected_filter_button.text = "SEL"
	_selected_filter_button.button_pressed = selected_only
	_selected_filter_button.custom_minimum_size = Vector2(48.0, 0.0)
	_selected_filter_button.add_theme_font_size_override("font_size", 8)
	_selected_filter_button.toggled.connect(_on_selected_filter_toggled)
	header.add_child(_selected_filter_button)

	_scroll = ScrollContainer.new()
	_scroll.name = "EventLogScroll"
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	root.add_child(_scroll)

	_entry_list = VBoxContainer.new()
	_entry_list.name = "EventLogEntries"
	_entry_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entry_list.add_theme_constant_override("separation", 3)
	_scroll.add_child(_entry_list)


func _refresh_display(force: bool = false) -> void:
	_ensure_structure()
	var filtered_entries: Array = _build_filtered_entries()
	var signature: String = _build_render_signature(filtered_entries)
	if not force and signature == _last_render_signature:
		return
	_last_render_signature = signature
	_rendered_entries = filtered_entries
	_clear_entry_list()
	if _selected_filter_button != null:
		_selected_filter_button.set_pressed_no_signal(selected_only)
	if _count_label != null:
		_count_label.text = "%d" % filtered_entries.size()
	_apply_empty_state_layout(filtered_entries.is_empty())
	if filtered_entries.is_empty():
		_add_empty_row()
		return
	for entry_variant in filtered_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		_add_event_row(Dictionary(entry_variant))


func _build_filtered_entries() -> Array:
	var filtered: Array = []
	for entry_variant in _event_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant).duplicate(true)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
		if selected_only and not _selected_fireteam_ids.is_empty() and not fireteam_id.is_empty() and not _selected_fireteam_ids.has(fireteam_id):
			continue
		filtered.append(entry)
	filtered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_time: int = int(a.get("created_msec", 0))
		var b_time: int = int(b.get("created_msec", 0))
		if a_time == b_time:
			return String(a.get("event_id", "")) < String(b.get("event_id", ""))
		return a_time > b_time
	)
	return filtered


func _add_event_row(entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "EventLogRow_%s" % _sanitize_node_name(String(entry.get("event_id", "event")))
	row.custom_minimum_size = Vector2(0.0, ROW_MIN_HEIGHT)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 5)
	_entry_list.add_child(row)

	var strip := ColorRect.new()
	strip.name = "SeverityStrip"
	strip.custom_minimum_size = Vector2(4.0, ROW_MIN_HEIGHT)
	strip.color = _color_for_severity(String(entry.get("severity", "info")))
	row.add_child(strip)

	var time_label := Label.new()
	time_label.name = "TimeLabel"
	time_label.custom_minimum_size = Vector2(38.0, ROW_MIN_HEIGHT)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 9)
	time_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.82, 0.96))
	time_label.text = _format_time(int(entry.get("created_msec", 0)))
	row.add_child(time_label)

	var text_label := Label.new()
	text_label.name = "EventTextLabel"
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 9)
	text_label.add_theme_color_override("font_color", _text_color_for_severity(String(entry.get("severity", "info"))))
	text_label.text = _format_event_text(entry)
	row.add_child(text_label)


func _add_empty_row() -> void:
	var label := Label.new()
	label.name = "EventLogEmptyLabel"
	label.text = "NO EVENTS"
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color(0.62, 0.70, 0.74, 0.86))
	_entry_list.add_child(label)


func _apply_empty_state_layout(is_empty: bool) -> void:
	_empty_state_collapsed = collapse_when_empty and is_empty
	visible = not _empty_state_collapsed
	mouse_filter = Control.MOUSE_FILTER_IGNORE if _empty_state_collapsed else Control.MOUSE_FILTER_STOP


func _clear_entry_list() -> void:
	for child in _entry_list.get_children():
		child.queue_free()


func _build_render_signature(entries: Array) -> String:
	var tokens: PackedStringArray = PackedStringArray()
	tokens.append("sel=%s" % str(selected_only))
	tokens.append("ids=%s" % "|".join(_selected_fireteam_ids))
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		tokens.append("%s:%d:%s:%s" % [
			String(entry.get("event_id", "")),
			int(entry.get("created_msec", 0)),
			String(entry.get("severity", "")),
			String(entry.get("short_text", "")),
		])
	return ";".join(tokens)


func _format_event_text(entry: Dictionary) -> String:
	var team: String = String(entry.get("fireteam_id", "")).strip_edges().to_upper()
	var text: String = String(entry.get("short_text", entry.get("map_label", ""))).strip_edges()
	if text.is_empty():
		text = String(entry.get("event_type", "event")).strip_edges().replace("_", " ").to_upper()
	if team.is_empty():
		return text
	return "%s %s" % [team, text]


func _format_time(created_msec: int) -> String:
	var total_seconds: int = maxi(int(floor(float(created_msec) / 1000.0)), 0)
	return "%02d:%02d" % [floori(float(total_seconds) / 60.0), total_seconds % 60]


func _color_for_severity(severity: String) -> Color:
	match severity.strip_edges().to_lower():
		"critical":
			return Color(1.0, 0.34, 0.28, 0.88)
		"warning":
			return Color(1.0, 0.76, 0.30, 0.84)
		"tactical":
			return Color(0.45, 0.78, 1.0, 0.82)
		"low":
			return Color(0.52, 0.60, 0.66, 0.78)
		_:
			return Color(0.66, 0.92, 0.76, 0.82)


func _text_color_for_severity(severity: String) -> Color:
	match severity.strip_edges().to_lower():
		"critical":
			return Color(1.0, 0.72, 0.68, 0.96)
		"warning":
			return Color(1.0, 0.86, 0.56, 0.96)
		"tactical":
			return Color(0.72, 0.88, 1.0, 0.95)
		_:
			return Color(0.82, 0.90, 0.88, 0.95)


func _normalize_fireteam_ids(fireteam_ids: PackedStringArray) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or result.has(fireteam_id):
			continue
		result.append(fireteam_id)
	return result


func _sanitize_node_name(value: String) -> String:
	var result: String = value.strip_edges()
	for token in [" ", "/", "\\", ":", ".", "|", "#"]:
		result = result.replace(token, "_")
	return "event" if result.is_empty() else result


func _on_selected_filter_toggled(is_pressed: bool) -> void:
	set_selected_only(is_pressed)
