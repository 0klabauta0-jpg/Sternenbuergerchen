class_name TacticalEventLogPanel
extends PanelContainer

const TACTICAL_HUD_LANGUAGE_PRESENTER_SCRIPT: GDScript = preload("res://scripts/ui/tactical_hud_language_presenter.gd")
const UI_THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const DEFAULT_MAX_VISIBLE_EVENTS: int = 8
const ROW_MIN_HEIGHT: float = 22.0
const RELEASE_FIRST_EXCHANGE_HUD_DENSITY_FIRE_VISUAL_POLISH_STYLE_ID: String = "task_889_release_first_exchange_hud_density_fire_visual_polish_v1"
const TASK_1159_EVENT_LOG_1280_READABILITY_STYLE_ID: String = "task_1159_tactical_event_log_1280_readability_v1"
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_MAX_VISIBLE_EVENTS: int = 4
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_MIN_SIZE: Vector2 = Vector2(360.0, 220.0)
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_ROW_MIN_HEIGHT: float = 32.0
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_HEADER_FONT_SIZE: int = 13
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_COUNT_FONT_SIZE: int = 12
const LEFT_TACTICAL_STACK_DETAIL_EVENT_FILTER_FONT_SIZE: int = 13
const LEFT_TACTICAL_STACK_DETAIL_EVENT_FILTER_MIN_WIDTH: float = 96.0
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_ROW_FONT_SIZE: int = 13
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_TIME_FONT_SIZE: int = 12
const RELEASE_FIRST_EXCHANGE_EVENT_LOG_STRIP_WIDTH: float = 5.0
const TASK_1159_EVENT_LOG_BACKGROUND_COLOR: Color = Color(UI_THEME.COLOR_PANEL, 0.98)
const TASK_1159_EVENT_LOG_BORDER_COLOR: Color = UI_THEME.COLOR_BORDER

@export var max_visible_events: int = DEFAULT_MAX_VISIBLE_EVENTS
@export var selected_only: bool = false
@export var collapse_when_empty: bool = true

var _event_entries: Array = []
## Anzeigenamen der Trupps (Kennung -> Name); fehlt einer, steht wie bisher die Kennung in Grossbuchstaben.
var _fireteam_display_labels: Dictionary = {}
var _selected_fireteam_ids: PackedStringArray = PackedStringArray()
var _rendered_entries: Array = []
var _last_render_signature: String = ""
var _last_feedback_snapshot_signature: String = ""
var _feedback_snapshot_apply_count: int = 0
var _feedback_snapshot_skip_count: int = 0
var _empty_state_collapsed: bool = false
var _selected_only_default_initialized: bool = false

var _header_label: Label = null
var _count_label: Label = null
var _selected_filter_button: CheckButton = null
var _scroll: ScrollContainer = null
var _entry_list: VBoxContainer = null
var _release_first_exchange_hud_density_fire_visual_polish_active: bool = false


func _ready() -> void:
	set_meta("native_a5_quiet_frame", true)
	_ensure_structure()
	_apply_task_1159_background_style()
	_refresh_display()


func set_fireteam_display_labels(labels: Dictionary) -> void:
	_fireteam_display_labels = labels.duplicate()


func set_feedback_snapshot(snapshot: Dictionary) -> void:
	var selected_ids: PackedStringArray = PackedStringArray()
	for fireteam_id_variant in Array(snapshot.get("selected_fireteam_ids", [])):
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or selected_ids.has(fireteam_id):
			continue
		selected_ids.append(fireteam_id)
	var event_entries: Array = Array(snapshot.get("tactical_event_log", []))
	if snapshot.has("event_log_selected_only_default") and not _selected_only_default_initialized:
		selected_only = bool(snapshot.get("event_log_selected_only_default", false))
		_selected_only_default_initialized = true
	var polish_snapshot: Dictionary = Dictionary(snapshot.get("release_first_exchange_hud_density_fire_visual_polish", {}))
	if snapshot.has("release_first_exchange_hud_density_fire_visual_polish"):
		apply_release_first_exchange_hud_density_fire_visual_polish(polish_snapshot)
	var feedback_signature: String = _build_feedback_snapshot_signature(event_entries, selected_ids, selected_only, polish_snapshot)
	if feedback_signature == _last_feedback_snapshot_signature:
		_feedback_snapshot_skip_count += 1
		return
	_last_feedback_snapshot_signature = feedback_signature
	_feedback_snapshot_apply_count += 1
	set_event_entries(event_entries, selected_ids, selected_only)


func apply_release_first_exchange_hud_density_fire_visual_polish(snapshot: Dictionary) -> void:
	var active: bool = bool(snapshot.get("active", false)) and String(snapshot.get("style_id", "")) == RELEASE_FIRST_EXCHANGE_HUD_DENSITY_FIRE_VISUAL_POLISH_STYLE_ID
	var size_needs_update: bool = active and (
		custom_minimum_size.x < RELEASE_FIRST_EXCHANGE_EVENT_LOG_MIN_SIZE.x
		or custom_minimum_size.y < RELEASE_FIRST_EXCHANGE_EVENT_LOG_MIN_SIZE.y
	)
	if _release_first_exchange_hud_density_fire_visual_polish_active == active and not size_needs_update and (not active or max_visible_events == RELEASE_FIRST_EXCHANGE_EVENT_LOG_MAX_VISIBLE_EVENTS):
		return
	_release_first_exchange_hud_density_fire_visual_polish_active = active
	if active:
		_apply_task_1159_background_style()
		max_visible_events = int(snapshot.get("event_log_max_visible_events", RELEASE_FIRST_EXCHANGE_EVENT_LOG_MAX_VISIBLE_EVENTS))
		if custom_minimum_size == Vector2.ZERO:
			custom_minimum_size = RELEASE_FIRST_EXCHANGE_EVENT_LOG_MIN_SIZE
		else:
			custom_minimum_size = Vector2(
				maxf(custom_minimum_size.x, RELEASE_FIRST_EXCHANGE_EVENT_LOG_MIN_SIZE.x),
				maxf(custom_minimum_size.y, RELEASE_FIRST_EXCHANGE_EVENT_LOG_MIN_SIZE.y)
			)
	else:
		max_visible_events = DEFAULT_MAX_VISIBLE_EVENTS
	_refresh_display(true)


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
	_selected_only_default_initialized = true
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
	var panel_style := get_theme_stylebox("panel") as StyleBoxFlat
	return {
		"event_count": _event_entries.size(),
		"rendered_entry_count": _rendered_entries.size(),
		"max_visible_events": max_visible_events,
		"selected_only": selected_only,
		"selected_fireteam_ids": Array(_selected_fireteam_ids),
		"first_event_id": first_event_id,
		"newest_first": true,
		"scrollable_overflow": _rendered_entries.size() > max_visible_events,
		"source_event_count": _event_entries.size(),
		"release_first_exchange_hud_density_fire_visual_polish_active": _release_first_exchange_hud_density_fire_visual_polish_active,
		"release_first_exchange_hud_density_fire_visual_polish_style_id": RELEASE_FIRST_EXCHANGE_HUD_DENSITY_FIRE_VISUAL_POLISH_STYLE_ID if _release_first_exchange_hud_density_fire_visual_polish_active else "",
		"task_1159_readability_style_id": TASK_1159_EVENT_LOG_1280_READABILITY_STYLE_ID,
		"task_1159_readability_active": true,
		"row_min_height": _get_row_min_height(),
		"row_font_size": _get_row_font_size(),
		"time_font_size": _get_time_font_size(),
		"header_font_size": _get_header_font_size(),
		"count_font_size": _get_count_font_size(),
		"filter_font_size": _selected_filter_button.get_theme_font_size("font_size") if _selected_filter_button != null else 0,
		"filter_min_width": _selected_filter_button.custom_minimum_size.x if _selected_filter_button != null else 0.0,
		"count_separated_from_filter": _count_label != null and _selected_filter_button != null and _count_label.get_parent() == _selected_filter_button.get_parent(),
		"background_alpha": panel_style.bg_color.a if panel_style != null else 0.0,
		"custom_minimum_size_x": custom_minimum_size.x,
		"custom_minimum_size_y": custom_minimum_size.y,
		"severity_counts": severity_counts,
		"global_rect": get_global_rect(),
		"collapse_when_empty": collapse_when_empty,
		"empty_state_collapsed": _empty_state_collapsed,
		"visible": visible,
		"mouse_filter": mouse_filter,
		"visibility_mode": "collapsed_empty" if _empty_state_collapsed else "expanded",
		"feedback_snapshot_apply_count": _feedback_snapshot_apply_count,
		"feedback_snapshot_skip_count": _feedback_snapshot_skip_count,
		"feedback_snapshot_delta_read_only": true,
		"feedback_snapshot_sets_gameplay_truth": false,
		"selected_only_default_initialized": _selected_only_default_initialized,
	}


func _apply_task_1159_background_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = TASK_1159_EVENT_LOG_BACKGROUND_COLOR
	style.border_color = TASK_1159_EVENT_LOG_BORDER_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)
	UI_THEME.decorate_panel(self, "thin_frame")


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
	_header_label.text = String(TACTICAL_HUD_LANGUAGE_PRESENTER_SCRIPT.call("event_log_header"))
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_label.add_theme_font_size_override("font_size", _get_header_font_size())
	header.add_child(_header_label)

	_count_label = Label.new()
	_count_label.name = "EventLogCountLabel"
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_count_label.add_theme_font_size_override("font_size", _get_count_font_size())
	header.add_child(_count_label)

	_selected_filter_button = CheckButton.new()
	_selected_filter_button.name = "EventLogSelectedFilterButton"
	_selected_filter_button.focus_mode = Control.FOCUS_NONE
	_selected_filter_button.text = String(TACTICAL_HUD_LANGUAGE_PRESENTER_SCRIPT.call("selected_filter_label"))
	_selected_filter_button.button_pressed = selected_only
	_selected_filter_button.custom_minimum_size = Vector2(LEFT_TACTICAL_STACK_DETAIL_EVENT_FILTER_MIN_WIDTH, 0.0)
	_selected_filter_button.add_theme_font_size_override("font_size", LEFT_TACTICAL_STACK_DETAIL_EVENT_FILTER_FONT_SIZE)
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
	_apply_release_first_exchange_event_log_header_style()
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
	if _release_first_exchange_hud_density_fire_visual_polish_active and max_visible_events > 0 and filtered.size() > max_visible_events:
		return filtered.slice(0, max_visible_events)
	return filtered


func _add_event_row(entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.name = "EventLogRow_%s" % _sanitize_node_name(String(entry.get("event_id", "event")))
	var row_min_height: float = _get_row_min_height()
	row.custom_minimum_size = Vector2(0.0, row_min_height)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6 if _release_first_exchange_hud_density_fire_visual_polish_active else 5)
	_entry_list.add_child(row)

	var strip := ColorRect.new()
	strip.name = "SeverityStrip"
	strip.custom_minimum_size = Vector2(_get_severity_strip_width(), row_min_height)
	strip.color = _color_for_severity(String(entry.get("severity", "info")))
	row.add_child(strip)

	var time_label := Label.new()
	time_label.name = "TimeLabel"
	time_label.custom_minimum_size = Vector2(44.0 if _release_first_exchange_hud_density_fire_visual_polish_active else 38.0, row_min_height)
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", _get_time_font_size())
	time_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.82, 0.96))
	time_label.text = _format_time(int(entry.get("created_msec", 0)))
	row.add_child(time_label)

	var text_label := Label.new()
	text_label.name = "EventTextLabel"
	# Labels otherwise ignore pointer hit testing, including their tooltip.
	# Pass wheel/input onward to the native scroll while exposing full text.
	text_label.mouse_filter = Control.MOUSE_FILTER_PASS
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.max_lines_visible = 2
	text_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_label.add_theme_font_size_override("font_size", _get_row_font_size())
	text_label.add_theme_color_override("font_color", _text_color_for_severity(String(entry.get("severity", "info"))))
	text_label.text = _format_event_text(entry)
	text_label.tooltip_text = "%s\n%s" % [time_label.text, text_label.text]
	row.add_child(text_label)


func _add_empty_row() -> void:
	var label := Label.new()
	label.name = "EventLogEmptyLabel"
	label.text = "KEINE EREIGNISSE"
	label.add_theme_font_size_override("font_size", _get_row_font_size())
	label.add_theme_color_override("font_color", Color(0.62, 0.70, 0.74, 0.86))
	_entry_list.add_child(label)


func _apply_release_first_exchange_event_log_header_style() -> void:
	_apply_task_1159_background_style()
	if _header_label != null:
		_header_label.add_theme_font_size_override("font_size", _get_header_font_size())
	if _count_label != null:
		_count_label.add_theme_font_size_override("font_size", _get_count_font_size())
	if _selected_filter_button != null:
		_selected_filter_button.custom_minimum_size = Vector2(
			maxf(_selected_filter_button.custom_minimum_size.x, LEFT_TACTICAL_STACK_DETAIL_EVENT_FILTER_MIN_WIDTH),
			_selected_filter_button.custom_minimum_size.y
		)
		_selected_filter_button.add_theme_font_size_override("font_size", LEFT_TACTICAL_STACK_DETAIL_EVENT_FILTER_FONT_SIZE)
	if _entry_list != null:
		_entry_list.add_theme_constant_override("separation", 4 if _release_first_exchange_hud_density_fire_visual_polish_active else 3)


func _get_row_min_height() -> float:
	return 24.0


func _get_header_font_size() -> int:
	return RELEASE_FIRST_EXCHANGE_EVENT_LOG_HEADER_FONT_SIZE


func _get_count_font_size() -> int:
	return RELEASE_FIRST_EXCHANGE_EVENT_LOG_COUNT_FONT_SIZE


func _get_row_font_size() -> int:
	return RELEASE_FIRST_EXCHANGE_EVENT_LOG_ROW_FONT_SIZE


func _get_time_font_size() -> int:
	return RELEASE_FIRST_EXCHANGE_EVENT_LOG_TIME_FONT_SIZE


func _get_severity_strip_width() -> float:
	return 2.0


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
		tokens.append("%s:%d:%s:%s:%d" % [
			String(entry.get("event_id", "")),
			int(entry.get("created_msec", 0)),
			String(entry.get("severity", "")),
			String(entry.get("short_text", "")),
			int(entry.get("repeat_count", 1)),
		])
	return ";".join(tokens)


func _build_feedback_snapshot_signature(entries: Array, selected_fireteam_ids: PackedStringArray, show_selected_only: bool, polish_snapshot: Dictionary) -> String:
	var tokens: PackedStringArray = PackedStringArray([
		"selected=%s" % "|".join(selected_fireteam_ids),
		"selected_only=%s" % str(show_selected_only),
		"polish_active=%s" % str(bool(polish_snapshot.get("active", false))),
		"polish_style=%s" % String(polish_snapshot.get("style_id", "")).strip_edges(),
		"polish_max=%d" % int(polish_snapshot.get("event_log_max_visible_events", DEFAULT_MAX_VISIBLE_EVENTS)),
	])
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		tokens.append("%s:%d:%s:%s:%s:%d" % [
			String(entry.get("event_id", "")),
			int(entry.get("created_msec", 0)),
			String(entry.get("severity", "")),
			String(entry.get("short_text", "")),
			String(entry.get("fireteam_id", "")),
			int(entry.get("repeat_count", 1)),
		])
	return ";".join(tokens)


func _format_event_text(entry: Dictionary) -> String:
	var team: String = String(entry.get("fireteam_id", "")).strip_edges().to_upper()
	var team_label: String = String(_fireteam_display_labels.get(String(entry.get("fireteam_id", "")).strip_edges().to_lower(), "")).strip_edges()
	if not team_label.is_empty():
		team = team_label
	# Deutsche Farbnamen (Blau, Rot, ...) aus data/comms/trupp_farben.json; ohne Zuordnung bleibt die bisherige Anzeige.
	if not team.is_empty():
		team = String(load("res://scripts/tactical/trupp_farben.gd").call("display_name", String(entry.get("fireteam_id", "")), team))
	var text: String = String(entry.get("short_text", entry.get("map_label", ""))).strip_edges()
	if text.is_empty():
		text = String(entry.get("event_type", "event")).strip_edges().replace("_", " ").to_upper()
	text = String(Dictionary(TACTICAL_HUD_LANGUAGE_PRESENTER_SCRIPT.call("event_text_snapshot", text)).get("display_text", text))
	var repeat_count: int = maxi(int(entry.get("repeat_count", 1)), 1)
	if repeat_count > 1:
		text = "%s x%d" % [text, repeat_count]
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
