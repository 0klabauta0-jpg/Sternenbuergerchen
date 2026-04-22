class_name NPCCompactCard
extends PanelContainer

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")

signal card_pressed(unit_id, profile, source_context)
signal card_open_requested(unit_id, profile, source_context)
signal card_unit_dropped(dropped_unit_id, source_context)
signal lead_toggle_requested(unit_id)

const COMPACT_CARD_MIN_SIZE := Vector2(148.0, 58.0)
const FULL_CARD_MIN_HEIGHT := 92.0
const COMPACT_TEXT_MIN_WIDTH := 88.0
const COMPACT_PORTRAIT_SIZE := 38.0
const COMPACT_STAR_WIDTH := 16.0
const COMPACT_MARGIN_WIDTH := 8.0
const COMPACT_HBOX_SEPARATION := 6.0

var _profile = null
var _source_context: String = "roster"
var _is_selected: bool = false
var _is_disabled: bool = false
var _drag_enabled: bool = true
var _compact_mode: bool = false
var _is_lead: bool = false
var _show_lead_indicator: bool = false
var _show_progress: bool = false
var _progress_value: float = 0.0
var _is_drag_preview: bool = false
var _drag_preview_size: Vector2 = Vector2.ZERO
var _drag_preview_text_width: float = 0.0


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if _is_drag_preview else Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_ui()
	_refresh_card()


func setup_from_profile(profile, options: Dictionary = {}) -> void:
	if profile != null and profile.has_method("duplicate_profile"):
		_profile = profile.duplicate_profile()
	elif typeof(profile) == TYPE_DICTIONARY:
		_profile = META_UNIT_PROFILE_SCRIPT.new(profile)
	else:
		_profile = META_UNIT_PROFILE_SCRIPT.new()

	_source_context = String(options.get("source_context", _source_context)).strip_edges()
	if _source_context.is_empty():
		_source_context = "roster"

	_is_selected = bool(options.get("selected", _is_selected))
	_is_disabled = bool(options.get("disabled", _is_disabled))
	_drag_enabled = bool(options.get("drag_enabled", _drag_enabled))
	_compact_mode = bool(options.get("compact_mode", _compact_mode))
	_is_lead = bool(options.get("is_lead", _is_lead))
	_show_lead_indicator = bool(options.get("show_lead_indicator", _show_lead_indicator))
	_show_progress = bool(options.get("show_progress", _show_progress))
	_progress_value = clampf(float(options.get("progress_value", _progress_value)), 0.0, 100.0)
	_is_drag_preview = bool(options.get("drag_preview", _is_drag_preview))
	_drag_preview_size = options.get("drag_preview_size", _drag_preview_size) if typeof(options.get("drag_preview_size", _drag_preview_size)) == TYPE_VECTOR2 else _drag_preview_size
	_drag_preview_text_width = float(options.get("drag_preview_text_width", _drag_preview_text_width))
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if _is_drag_preview else Control.SIZE_EXPAND_FILL

	if is_inside_tree():
		_refresh_card()


func set_visual_state(selected: bool, disabled: bool = false) -> void:
	_is_selected = selected
	_is_disabled = disabled
	if is_inside_tree():
		_refresh_card()


func set_drag_enabled(enabled: bool) -> void:
	_drag_enabled = enabled
	if is_inside_tree():
		_refresh_card()


func get_unit_id() -> String:
	if _profile == null:
		return ""

	return String(_profile.unit_id)


func get_profile():
	if _profile == null or not _profile.has_method("duplicate_profile"):
		return null

	return _profile.duplicate_profile()


func get_source_context() -> String:
	return _source_context


func _gui_input(event: InputEvent) -> void:
	if _is_disabled or _profile == null or not _profile.is_valid():
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if mouse_event.double_click:
				card_open_requested.emit(get_unit_id(), get_profile(), _source_context)
				return
			card_pressed.emit(get_unit_id(), get_profile(), _source_context)


func _get_drag_data(_at_position: Vector2):
	if not _drag_enabled or _is_disabled or _profile == null or not _profile.is_valid():
		return null
	var live_text_vbox := get_node_or_null("Margin/HBox/TextVBox") as VBoxContainer
	var preview_size := size
	if preview_size.x <= 0.0 or preview_size.y <= 0.0:
		preview_size = get_combined_minimum_size()
	var minimum_preview_width := COMPACT_CARD_MIN_SIZE.x if _compact_mode else 220.0
	var minimum_preview_height := COMPACT_CARD_MIN_SIZE.y if _compact_mode else FULL_CARD_MIN_HEIGHT
	if minimum_preview_width > preview_size.x:
		preview_size.x = minimum_preview_width
	if minimum_preview_height > preview_size.y:
		preview_size.y = minimum_preview_height
	var preview_text_width := COMPACT_TEXT_MIN_WIDTH
	if live_text_vbox != null:
		var live_text_width := live_text_vbox.size.x
		var live_text_minimum := live_text_vbox.get_combined_minimum_size()
		if live_text_minimum.x > live_text_width:
			live_text_width = live_text_minimum.x
		if COMPACT_TEXT_MIN_WIDTH > live_text_width:
			live_text_width = COMPACT_TEXT_MIN_WIDTH
		preview_text_width = live_text_width

	var preview := NPCCompactCard.new()
	preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	preview.setup_from_profile(
		get_profile(),
		{
			"source_context": _source_context,
			"selected": _is_selected,
			"disabled": false,
			"drag_enabled": false,
			"compact_mode": _compact_mode,
			"is_lead": _is_lead,
			"show_lead_indicator": _show_lead_indicator,
			"drag_preview": true,
			"drag_preview_size": preview_size,
			"drag_preview_text_width": preview_text_width,
		}
	)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = preview_size
	preview.size = preview.custom_minimum_size
	preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
	set_drag_preview(preview)

	return {
		"type": "homebase_unit_card",
		"unit_id": get_unit_id(),
		"source_context": _source_context,
	}


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if _is_disabled or typeof(data) != TYPE_DICTIONARY:
		return false
	var drag_type: String = String(data.get("type", "")).strip_edges()
	if drag_type != "homebase_unit_card":
		return false
	var dropped_unit_id: String = String(data.get("unit_id", "")).strip_edges()
	return not dropped_unit_id.is_empty() and dropped_unit_id != get_unit_id()


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var dropped_unit_id: String = String(data.get("unit_id", "")).strip_edges()
	card_unit_dropped.emit(dropped_unit_id, _source_context)


func _ensure_ui() -> void:
	if get_node_or_null("Margin") != null:
		return

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	var portrait_rect := TextureRect.new()
	portrait_rect.name = "PortraitRect"
	portrait_rect.custom_minimum_size = Vector2(64.0, 64.0)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hbox.add_child(portrait_rect)

	var text_vbox := VBoxContainer.new()
	text_vbox.name = "TextVBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(name_label)

	var data_a_label := Label.new()
	data_a_label.name = "DataALabel"
	data_a_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(data_a_label)

	var data_b_label := Label.new()
	data_b_label.name = "DataBLabel"
	data_b_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(data_b_label)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
	progress_bar.visible = false
	text_vbox.add_child(progress_bar)

	var star_button := Button.new()
	star_button.name = "StarButton"
	star_button.text = "\u2605"
	star_button.flat = true
	star_button.toggle_mode = true
	star_button.custom_minimum_size = Vector2(COMPACT_STAR_WIDTH, COMPACT_STAR_WIDTH)
	star_button.visible = false
	star_button.mouse_filter = Control.MOUSE_FILTER_STOP
	if not star_button.pressed.is_connected(_on_star_button_pressed):
		star_button.pressed.connect(_on_star_button_pressed)
	hbox.add_child(star_button)


func _refresh_card() -> void:
	_ensure_ui()
	var portrait_rect: TextureRect = get_node("Margin/HBox/PortraitRect")
	var name_label: Label = get_node("Margin/HBox/TextVBox/NameLabel")
	var data_a_label: Label = get_node("Margin/HBox/TextVBox/DataALabel")
	var data_b_label: Label = get_node("Margin/HBox/TextVBox/DataBLabel")
	var margin: MarginContainer = get_node("Margin")
	var hbox: HBoxContainer = get_node("Margin/HBox")
	var text_vbox: VBoxContainer = get_node("Margin/HBox/TextVBox")
	var progress_bar: ProgressBar = get_node("Margin/HBox/TextVBox/ProgressBar")

	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	data_a_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	data_b_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_a_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_b_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _compact_mode:
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		data_a_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		data_b_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.max_lines_visible = 1
		data_a_label.max_lines_visible = 1
		data_b_label.max_lines_visible = 1
		name_label.clip_text = true
		data_a_label.clip_text = true
		data_b_label.clip_text = true
	else:
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		data_a_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		data_b_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.max_lines_visible = -1
		data_a_label.max_lines_visible = -1
		data_b_label.max_lines_visible = -1
		name_label.clip_text = false
		data_a_label.clip_text = false
		data_b_label.clip_text = false

	var star_button = get_node_or_null("Margin/HBox/StarButton")
	if star_button != null:
		star_button.visible = _show_lead_indicator
		star_button.button_pressed = _is_lead
		star_button.custom_minimum_size = Vector2(COMPACT_STAR_WIDTH, COMPACT_STAR_WIDTH) if _compact_mode else Vector2(20.0, 20.0)
		star_button.tooltip_text = "Lead aktiv" if _is_lead else "Als Lead setzen"
		star_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if _is_lead:
			star_button.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
			star_button.add_theme_font_size_override("font_size", 16 if not _compact_mode else 14)
		else:
			star_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
			star_button.add_theme_font_size_override("font_size", 16 if not _compact_mode else 14)

	var display_name: String = "Unknown Operator"
	var data_a_text: String = "Role unavailable"
	var data_b_text: String = "Callsign unavailable"
	var portrait_texture: Texture2D = null
	if _profile != null:
		display_name = String(_profile.display_name if not String(_profile.display_name).is_empty() else _profile.unit_id)
		data_a_text = _build_primary_data_text()
		data_b_text = _build_secondary_data_text()
		portrait_texture = _load_portrait_texture(String(_profile.portrait_path))

	name_label.text = display_name
	data_a_label.text = data_a_text
	data_b_label.text = data_b_text
	portrait_rect.texture = portrait_texture
	portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if portrait_texture != null else Color(0.35, 0.37, 0.42, 1.0)
	progress_bar.visible = _show_progress
	progress_bar.value = _progress_value
	progress_bar.modulate = Color(0.48, 0.82, 0.58, 1.0) if not _is_disabled else Color(0.42, 0.46, 0.44, 0.92)
	_apply_density(margin, hbox, text_vbox, portrait_rect, name_label, data_a_label, data_b_label, progress_bar)

	_apply_state_visuals(name_label, data_a_label, data_b_label)


func _build_primary_data_text() -> String:
	var role_name: String = String(_profile.role_name).strip_edges()
	if role_name.is_empty():
		return "Role unavailable"

	return role_name


func _build_secondary_data_text() -> String:
	var secondary_text: String = String(_profile.secondary_text).strip_edges()
	if not secondary_text.is_empty():
		return secondary_text

	var callsign: String = String(_profile.callsign).strip_edges()
	if not callsign.is_empty():
		return "Callsign: %s" % callsign

	var homeworld: String = String(_profile.homeworld).strip_edges()
	if not homeworld.is_empty():
		return "Origin: %s" % homeworld

	return "No secondary data"


func _apply_density(
	margin: MarginContainer,
	hbox: HBoxContainer,
	text_vbox: VBoxContainer,
	portrait_rect: TextureRect,
	name_label: Label,
	data_a_label: Label,
	data_b_label: Label,
	progress_bar: ProgressBar
) -> void:
	if _compact_mode:
		var is_mission_drop_pilot: bool = _source_context == "mission_drop_pilot"
		var compact_width := _get_compact_required_width()
		if custom_minimum_size.x > compact_width:
			compact_width = custom_minimum_size.x
		if _is_drag_preview and _drag_preview_size.x > 0.0:
			compact_width = _drag_preview_size.x
		var compact_height := 46.0 if is_mission_drop_pilot else COMPACT_CARD_MIN_SIZE.y
		if _is_drag_preview and _drag_preview_size.y > compact_height:
			compact_height = _drag_preview_size.y
		if _show_progress:
			compact_height = maxf(compact_height, 68.0)
		custom_minimum_size = Vector2(compact_width, compact_height)
		margin.add_theme_constant_override("margin_left", 2 if is_mission_drop_pilot else 4)
		margin.add_theme_constant_override("margin_top", 2 if is_mission_drop_pilot else 4)
		margin.add_theme_constant_override("margin_right", 2 if is_mission_drop_pilot else 4)
		margin.add_theme_constant_override("margin_bottom", 2 if is_mission_drop_pilot else 4)
		hbox.add_theme_constant_override("separation", 4 if is_mission_drop_pilot else 6)
		text_vbox.add_theme_constant_override("separation", 0 if is_mission_drop_pilot else 1)
		portrait_rect.custom_minimum_size = Vector2(30.0, 30.0) if is_mission_drop_pilot else Vector2(COMPACT_PORTRAIT_SIZE, COMPACT_PORTRAIT_SIZE)
		var compact_text_width := 76.0 if is_mission_drop_pilot else COMPACT_TEXT_MIN_WIDTH
		if _drag_preview_text_width > compact_text_width:
			compact_text_width = _drag_preview_text_width
		text_vbox.custom_minimum_size = Vector2(compact_text_width, 0.0)
		name_label.custom_minimum_size = Vector2(0.0, 12.0 if is_mission_drop_pilot else 14.0)
		data_a_label.custom_minimum_size = Vector2(0.0, 10.0 if is_mission_drop_pilot else 12.0)
		data_b_label.custom_minimum_size = Vector2(0.0, 10.0 if is_mission_drop_pilot else 12.0)
		name_label.add_theme_font_size_override("font_size", 10 if is_mission_drop_pilot else 12)
		data_a_label.add_theme_font_size_override("font_size", 8 if is_mission_drop_pilot else 10)
		data_b_label.add_theme_font_size_override("font_size", 8 if is_mission_drop_pilot else 10)
		progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
		return

	custom_minimum_size = Vector2(custom_minimum_size.x, FULL_CARD_MIN_HEIGHT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	hbox.add_theme_constant_override("separation", 8)
	text_vbox.add_theme_constant_override("separation", 2)
	portrait_rect.custom_minimum_size = Vector2(64.0, 64.0)
	text_vbox.custom_minimum_size = Vector2.ZERO
	name_label.custom_minimum_size = Vector2.ZERO
	data_a_label.custom_minimum_size = Vector2.ZERO
	data_b_label.custom_minimum_size = Vector2.ZERO
	name_label.add_theme_font_size_override("font_size", 14)
	data_a_label.add_theme_font_size_override("font_size", 12)
	data_b_label.add_theme_font_size_override("font_size", 12)
	progress_bar.custom_minimum_size = Vector2(0.0, 10.0)


func _get_compact_required_width() -> float:
	var required_width := COMPACT_MARGIN_WIDTH + COMPACT_PORTRAIT_SIZE + COMPACT_HBOX_SEPARATION + COMPACT_TEXT_MIN_WIDTH
	if _show_lead_indicator:
		required_width += COMPACT_HBOX_SEPARATION + COMPACT_STAR_WIDTH
	if required_width < COMPACT_CARD_MIN_SIZE.x:
		return COMPACT_CARD_MIN_SIZE.x
	return required_width


func _apply_state_visuals(name_label: Label, data_a_label: Label, data_b_label: Label) -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8

	var name_color := Color(0.94, 0.96, 0.98, 1.0)
	var detail_color := Color(0.76, 0.82, 0.90, 1.0)
	if _is_disabled:
		stylebox.bg_color = Color(0.11, 0.11, 0.13, 1.0)
		stylebox.border_color = Color(0.28, 0.28, 0.31, 1.0)
		name_color = Color(0.56, 0.58, 0.62, 1.0)
		detail_color = Color(0.46, 0.48, 0.52, 1.0)
	elif _is_selected:
		stylebox.bg_color = Color(0.15, 0.22, 0.19, 1.0)
		stylebox.border_color = Color(0.62, 0.84, 0.66, 1.0)
	else:
		stylebox.bg_color = Color(0.13, 0.14, 0.17, 1.0)
		stylebox.border_color = Color(0.34, 0.38, 0.45, 1.0)

	add_theme_stylebox_override("panel", stylebox)
	name_label.add_theme_color_override("font_color", name_color)
	data_a_label.add_theme_color_override("font_color", detail_color)
	data_b_label.add_theme_color_override("font_color", detail_color)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not _is_disabled else Control.CURSOR_ARROW


func _on_star_button_pressed() -> void:
	if _profile != null and _profile.is_valid():
		lead_toggle_requested.emit(get_unit_id())


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null

	var resource: Resource = load(portrait_path)
	return resource as Texture2D
