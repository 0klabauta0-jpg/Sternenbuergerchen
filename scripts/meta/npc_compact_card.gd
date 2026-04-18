class_name NPCCompactCard
extends PanelContainer

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")

signal card_pressed(unit_id, profile, source_context)

var _profile = null
var _source_context: String = "roster"
var _is_selected: bool = false
var _is_disabled: bool = false
var _drag_enabled: bool = true


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0.0, 92.0)
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
			card_pressed.emit(get_unit_id(), get_profile(), _source_context)


func _get_drag_data(_at_position: Vector2):
	if not _drag_enabled or _is_disabled or _profile == null or not _profile.is_valid():
		return null

	var preview = duplicate()
	if preview is Control:
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if preview is CanvasItem:
		preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
	set_drag_preview(preview)

	return {
		"type": "homebase_unit_card",
		"unit_id": get_unit_id(),
		"source_context": _source_context,
	}


func _ensure_ui() -> void:
	if get_node_or_null("Margin") != null:
		return

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.name = "HBox"
	hbox.add_theme_constant_override("separation", 10)
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
	text_vbox.add_theme_constant_override("separation", 4)
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


func _refresh_card() -> void:
	_ensure_ui()
	var portrait_rect: TextureRect = get_node("Margin/HBox/PortraitRect")
	var name_label: Label = get_node("Margin/HBox/TextVBox/NameLabel")
	var data_a_label: Label = get_node("Margin/HBox/TextVBox/DataALabel")
	var data_b_label: Label = get_node("Margin/HBox/TextVBox/DataBLabel")

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

	_apply_state_visuals(name_label, data_a_label, data_b_label)


func _build_primary_data_text() -> String:
	var role_name: String = String(_profile.role_name).strip_edges()
	if role_name.is_empty():
		return "Role unavailable"

	return role_name


func _build_secondary_data_text() -> String:
	var callsign: String = String(_profile.callsign).strip_edges()
	if not callsign.is_empty():
		return "Callsign: %s" % callsign

	var homeworld: String = String(_profile.homeworld).strip_edges()
	if not homeworld.is_empty():
		return "Origin: %s" % homeworld

	return "No secondary data"


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


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null

	var resource: Resource = load(portrait_path)
	return resource as Texture2D