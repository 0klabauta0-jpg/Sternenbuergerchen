class_name NPCCompactCard
extends PanelContainer

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

signal card_pressed(unit_id, profile, source_context)
signal card_open_requested(unit_id, profile, source_context)
signal card_unit_dropped(dropped_unit_id, source_context)
signal lead_toggle_requested(unit_id)
signal remove_requested(unit_id, source_context)

const COMPACT_CARD_MIN_SIZE := Vector2(148.0, 58.0)
const FULL_CARD_MIN_HEIGHT := 92.0
const COMPACT_TEXT_MIN_WIDTH := 88.0
const COMPACT_PORTRAIT_SIZE := 38.0
const COMPACT_STAR_WIDTH := 22.0
const COMPACT_REMOVE_BUTTON_SIZE := 18.0
const COMPACT_MARGIN_WIDTH := 8.0
const COMPACT_HBOX_SEPARATION := 6.0
const CARD_Z_INDEX := 24
const SELECTED_BORDER_COLOR := TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER_SELECTED

var _profile = null
var _uses_readonly_profile_reference: bool = false
var _secondary_text_override: String = ""
var _has_secondary_text_override: bool = false
var _card_tooltip_override: String = ""
var _has_card_tooltip_override: bool = false
var _source_context: String = "roster"
var _is_selected: bool = false
var _is_disabled: bool = false
var _drag_enabled: bool = true
var _compact_mode: bool = false
var _is_lead: bool = false
var _show_lead_indicator: bool = false
var _show_badges: bool = true
var _show_progress: bool = false
var _progress_value: float = 0.0
var _show_remove_action: bool = false
var _fixed_size: bool = false
var _fixed_card_size: Vector2 = Vector2.ZERO
var _compact_wrap_text_enabled: bool = false
var _compact_data_a_max_lines: int = 1
var _compact_data_b_max_lines: int = 1
var _compact_text_min_width_override: float = 0.0
var _compact_name_font_size_override: int = 0
var _compact_data_font_size_override: int = 0
var _compact_line_height_override: float = 0.0
var _compact_portrait_size_override: float = 0.0
var _is_drag_preview: bool = false
var _drag_preview_size: Vector2 = Vector2.ZERO
var _drag_preview_text_width: float = 0.0


func _ready() -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(self)
	set_meta("native_ui_screen_family", "person_card")
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if _is_drag_preview or _fixed_size else Control.SIZE_EXPAND_FILL
	_apply_canvas_order()
	set_meta("drag_preview_z_index_contract", int(META_USEROLOGY_CONTRACT_SCRIPT.get("DRAG_PREVIEW_Z_INDEX")))
	set_meta("badge_layout_contract", "right_of_main_text")
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_ui()
	_refresh_card()


func setup_from_profile(profile, options: Dictionary = {}) -> void:
	var copy_profile: bool = bool(options.get("copy_profile", true))
	if typeof(profile) == TYPE_OBJECT and profile != null and profile.has_method("duplicate_profile"):
		_profile = profile.duplicate_profile() if copy_profile else profile
		_uses_readonly_profile_reference = not copy_profile
	elif typeof(profile) == TYPE_DICTIONARY:
		_profile = META_UNIT_PROFILE_SCRIPT.new(profile)
		_uses_readonly_profile_reference = false
	else:
		_profile = META_UNIT_PROFILE_SCRIPT.new()
		_uses_readonly_profile_reference = false

	if options.has("secondary_text_override"):
		_secondary_text_override = String(options.get("secondary_text_override", "")).strip_edges()
		_has_secondary_text_override = true
	else:
		_secondary_text_override = ""
		_has_secondary_text_override = false

	if options.has("card_tooltip_override"):
		_card_tooltip_override = String(options.get("card_tooltip_override", "")).strip_edges()
		_has_card_tooltip_override = true
	else:
		_card_tooltip_override = ""
		_has_card_tooltip_override = false

	_source_context = String(options.get("source_context", _source_context)).strip_edges()
	if _source_context.is_empty():
		_source_context = "roster"

	_is_selected = bool(options.get("selected", _is_selected))
	_is_disabled = bool(options.get("disabled", _is_disabled))
	_drag_enabled = bool(options.get("drag_enabled", _drag_enabled))
	_compact_mode = bool(options.get("compact_mode", _compact_mode))
	_is_lead = bool(options.get("is_lead", _is_lead))
	_show_lead_indicator = bool(options.get("show_lead_indicator", _show_lead_indicator))
	_show_badges = bool(options.get("show_badges", _show_badges))
	_show_progress = bool(options.get("show_progress", _show_progress))
	_progress_value = clampf(float(options.get("progress_value", _progress_value)), 0.0, 100.0)
	_show_remove_action = bool(options.get("show_remove_action", _show_remove_action))
	_fixed_size = bool(options.get("fixed_size", _fixed_size))
	_compact_wrap_text_enabled = bool(options.get("compact_wrap_text", _compact_wrap_text_enabled))
	_compact_data_a_max_lines = maxi(1, int(options.get("compact_data_a_max_lines", _compact_data_a_max_lines)))
	_compact_data_b_max_lines = maxi(1, int(options.get("compact_data_b_max_lines", _compact_data_b_max_lines)))
	_compact_text_min_width_override = maxf(0.0, float(options.get("compact_text_min_width", _compact_text_min_width_override)))
	_compact_name_font_size_override = maxi(0, int(options.get("compact_name_font_size", _compact_name_font_size_override)))
	_compact_data_font_size_override = maxi(0, int(options.get("compact_data_font_size", _compact_data_font_size_override)))
	_compact_line_height_override = maxf(0.0, float(options.get("compact_line_height", _compact_line_height_override)))
	_compact_portrait_size_override = maxf(0.0, float(options.get("compact_portrait_size", _compact_portrait_size_override)))
	var requested_fixed_size = options.get("fixed_card_size", _fixed_card_size)
	if typeof(requested_fixed_size) == TYPE_VECTOR2:
		_fixed_card_size = requested_fixed_size
	_is_drag_preview = bool(options.get("drag_preview", _is_drag_preview))
	_drag_preview_size = options.get("drag_preview_size", _drag_preview_size) if typeof(options.get("drag_preview_size", _drag_preview_size)) == TYPE_VECTOR2 else _drag_preview_size
	_drag_preview_text_width = float(options.get("drag_preview_text_width", _drag_preview_text_width))
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if _is_drag_preview or _fixed_size else Control.SIZE_EXPAND_FILL
	_apply_canvas_order()

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


func get_profile_reference_for_readonly_display():
	return _profile


func get_profile_reference_contract_snapshot() -> Dictionary:
	return {
		"unit_id": get_unit_id(),
		"source_context": _source_context,
		"uses_readonly_profile_reference": _uses_readonly_profile_reference,
		"external_get_profile_returns_copy": true,
		"has_reference_getter": true,
		"secondary_text_override": _secondary_text_override if _has_secondary_text_override else "",
		"has_card_tooltip_override": _has_card_tooltip_override,
	}


func get_source_context() -> String:
	return _source_context


func get_card_userology_snapshot() -> Dictionary:
	var badge_row := get_node_or_null("Margin/HBox/TextVBox/NameRow/BadgeRow") as HBoxContainer
	var min_badge_size: Vector2 = Vector2.ZERO
	if badge_row != null and badge_row.get_child_count() > 0:
		var first_badge := badge_row.get_child(0) as Control
		min_badge_size = first_badge.custom_minimum_size if first_badge != null else Vector2.ZERO
	var remove_button := get_node_or_null("Margin/HBox/TextVBox/NameRow/RemoveButton") as Button
	return {
		"unit_id": get_unit_id(),
		"source_context": _source_context,
		"drag_enabled": _drag_enabled,
		"drag_preview_z_index": int(META_USEROLOGY_CONTRACT_SCRIPT.get("DRAG_PREVIEW_Z_INDEX")),
		"drag_preview_above_windows": true,
		"badge_layout": "right_of_main_text",
		"badge_minimum_size": min_badge_size,
		"badge_tooltips_available": _badge_tooltips_available(badge_row),
		"show_badges": _show_badges,
		"compact_remove_action": remove_button != null and remove_button.visible,
		"fixed_size": _fixed_size,
		"uses_readonly_profile_reference": _uses_readonly_profile_reference,
	}


func get_compact_readability_snapshot() -> Dictionary:
	var name_label := get_node_or_null("Margin/HBox/TextVBox/NameRow/NameLabel") as Label
	var data_a_label := get_node_or_null("Margin/HBox/TextVBox/DataALabel") as Label
	var data_b_label := get_node_or_null("Margin/HBox/TextVBox/DataBLabel") as Label
	var portrait_rect := get_node_or_null("Margin/HBox/PortraitRect") as TextureRect
	return {
		"schema": "sternenbuergerchen.npc_compact_card_readability.v1",
		"source_context": _source_context,
		"card_size": custom_minimum_size,
		"name_font_size": name_label.get_theme_font_size("font_size") if name_label != null else 0,
		"data_a_font_size": data_a_label.get_theme_font_size("font_size") if data_a_label != null else 0,
		"data_b_font_size": data_b_label.get_theme_font_size("font_size") if data_b_label != null else 0,
		"portrait_size": portrait_rect.custom_minimum_size if portrait_rect != null else Vector2.ZERO,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _gui_input(event: InputEvent) -> void:
	if _profile == null or not _profile.is_valid():
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if mouse_event.double_click:
				card_open_requested.emit(get_unit_id(), get_profile(), _source_context)
				return
			if _is_disabled:
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

	var viewport := get_viewport()
	if viewport != null and viewport.gui_is_dragging():
		var preview := NPCCompactCard.new()
		preview.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var preview_options := {
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
		if _has_secondary_text_override:
			preview_options["secondary_text_override"] = _secondary_text_override
		preview.setup_from_profile(
			get_profile(),
			preview_options
		)
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.custom_minimum_size = preview_size
		preview.size = preview.custom_minimum_size
		preview.z_index = int(META_USEROLOGY_CONTRACT_SCRIPT.get("DRAG_PREVIEW_Z_INDEX"))
		preview.set_meta("global_drag_layer", true)
		preview.set_meta("above_windows", true)
		preview.modulate = Color(1.0, 1.0, 1.0, 0.92)
		set_drag_preview(preview)

	return {
		"type": "homebase_unit_card",
		"unit_id": get_unit_id(),
		"source_context": _source_context,
	}


func _apply_canvas_order() -> void:
	z_as_relative = false
	z_index = int(META_USEROLOGY_CONTRACT_SCRIPT.get("DRAG_PREVIEW_Z_INDEX")) if _is_drag_preview else CARD_Z_INDEX
	set_meta("global_card_z_order", true)


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
	PORTRAIT_IDENTITY_CATALOG_SCRIPT.apply_texture_rect_contract(portrait_rect, "roster")
	hbox.add_child(portrait_rect)

	var text_vbox := VBoxContainer.new()
	text_vbox.name = "TextVBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)

	var name_row := HBoxContainer.new()
	name_row.name = "NameRow"
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_theme_constant_override("separation", 4)
	text_vbox.add_child(name_row)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)

	var badge_row := HBoxContainer.new()
	badge_row.name = "BadgeRow"
	badge_row.add_theme_constant_override("separation", 3)
	name_row.add_child(badge_row)

	var remove_button := Button.new()
	remove_button.name = "RemoveButton"
	remove_button.text = "X"
	remove_button.tooltip_text = "Remove from this slot"
	remove_button.flat = true
	remove_button.focus_mode = Control.FOCUS_NONE
	remove_button.custom_minimum_size = Vector2(COMPACT_REMOVE_BUTTON_SIZE, COMPACT_REMOVE_BUTTON_SIZE)
	remove_button.visible = false
	remove_button.mouse_filter = Control.MOUSE_FILTER_STOP
	remove_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	remove_button.add_theme_font_size_override("font_size", 9)
	if not remove_button.pressed.is_connected(_on_remove_action_pressed):
		remove_button.pressed.connect(_on_remove_action_pressed)
	name_row.add_child(remove_button)

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
	var name_row: HBoxContainer = get_node("Margin/HBox/TextVBox/NameRow")
	var name_label: Label = get_node("Margin/HBox/TextVBox/NameRow/NameLabel")
	var data_a_label: Label = get_node("Margin/HBox/TextVBox/DataALabel")
	var data_b_label: Label = get_node("Margin/HBox/TextVBox/DataBLabel")
	var badge_row: HBoxContainer = get_node("Margin/HBox/TextVBox/NameRow/BadgeRow")
	var remove_button: Button = get_node("Margin/HBox/TextVBox/NameRow/RemoveButton")
	var margin: MarginContainer = get_node("Margin")
	var hbox: HBoxContainer = get_node("Margin/HBox")
	var text_vbox: VBoxContainer = get_node("Margin/HBox/TextVBox")
	var progress_bar: ProgressBar = get_node("Margin/HBox/TextVBox/ProgressBar")

	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	data_a_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	data_b_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_a_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	data_b_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _compact_mode:
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		data_a_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if _compact_wrap_text_enabled else TextServer.AUTOWRAP_OFF
		data_b_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if _compact_wrap_text_enabled else TextServer.AUTOWRAP_OFF
		name_label.max_lines_visible = 1
		data_a_label.max_lines_visible = _compact_data_a_max_lines if _compact_wrap_text_enabled else 1
		data_b_label.max_lines_visible = _compact_data_b_max_lines if _compact_wrap_text_enabled else 1
		name_label.clip_text = true
		data_a_label.clip_text = not _compact_wrap_text_enabled
		data_b_label.clip_text = not _compact_wrap_text_enabled
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
		star_button.custom_minimum_size = Vector2(COMPACT_STAR_WIDTH, COMPACT_STAR_WIDTH) if _compact_mode else Vector2(24.0, 24.0)
		star_button.tooltip_text = "Lead aktiv" if _is_lead else "Als Lead setzen"
		star_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if _is_lead:
			star_button.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
			star_button.add_theme_font_size_override("font_size", 22 if not _compact_mode else 20)
		else:
			star_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))
			star_button.add_theme_font_size_override("font_size", 22 if not _compact_mode else 20)

	var display_name: String = "Unknown Operator"
	var data_a_text: String = "Role unavailable"
	var data_b_text: String = "Callsign unavailable"
	var portrait_texture: Texture2D = null
	if _profile != null:
		display_name = String(_profile.display_name if not String(_profile.display_name).is_empty() else _profile.unit_id)
		data_a_text = _build_primary_data_text()
		data_b_text = _build_secondary_data_text()
		portrait_texture = _load_portrait_texture(String(_profile.portrait_id), String(_profile.portrait_path))

	name_label.text = display_name
	# Identity uses the same cached display face as the screen headings. Body
	# information and all host-supplied compact sizes keep their existing fonts.
	name_label.add_theme_font_override("font", TACTICAL_UI_THEME_SCRIPT.get_heading_font())
	data_a_label.text = data_a_text
	data_b_label.text = data_b_text
	tooltip_text = _card_tooltip_override if _has_card_tooltip_override else ""
	_populate_badge_row(badge_row)
	remove_button.visible = _show_remove_action
	remove_button.disabled = _is_disabled
	remove_button.tooltip_text = "Return %s to Available Operators" % display_name
	portrait_rect.texture = portrait_texture
	portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if portrait_texture != null else Color(0.35, 0.37, 0.42, 1.0)
	progress_bar.visible = _show_progress
	progress_bar.value = _progress_value
	TACTICAL_UI_THEME_SCRIPT.style_progress_bar(progress_bar, "accent" if not _is_disabled else "neutral")
	progress_bar.modulate = Color.WHITE
	_apply_density(margin, hbox, text_vbox, portrait_rect, name_label, data_a_label, data_b_label, badge_row, progress_bar)

	_apply_state_visuals(name_label, data_a_label, data_b_label)


func _build_primary_data_text() -> String:
	var role_name: String = String(_profile.role_name).strip_edges()
	if role_name.is_empty():
		return "Role unavailable"

	return role_name


func _build_secondary_data_text() -> String:
	if _has_secondary_text_override:
		return _secondary_text_override

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
	badge_row: HBoxContainer,
	progress_bar: ProgressBar
) -> void:
	if _compact_mode:
		var is_mission_drop_pilot: bool = _source_context == "mission_drop_pilot"
		var compact_width := _get_compact_required_width()
		if custom_minimum_size.x > compact_width:
			compact_width = custom_minimum_size.x
		if _fixed_size and _fixed_card_size.x > 0.0:
			compact_width = _fixed_card_size.x
		if _is_drag_preview and _drag_preview_size.x > 0.0:
			compact_width = _drag_preview_size.x
		var compact_height := 46.0 if is_mission_drop_pilot else COMPACT_CARD_MIN_SIZE.y
		if _is_drag_preview and _drag_preview_size.y > compact_height:
			compact_height = _drag_preview_size.y
		if badge_row.visible:
			compact_height = maxf(compact_height, 58.0)
		if _show_progress:
			compact_height = maxf(compact_height, 68.0)
		if _fixed_size and _fixed_card_size.y > 0.0:
			compact_height = _fixed_card_size.y
		custom_minimum_size = Vector2(compact_width, compact_height)
		margin.add_theme_constant_override("margin_left", 2 if is_mission_drop_pilot else 4)
		margin.add_theme_constant_override("margin_top", 2 if is_mission_drop_pilot else 4)
		margin.add_theme_constant_override("margin_right", 2 if is_mission_drop_pilot else 4)
		margin.add_theme_constant_override("margin_bottom", 2 if is_mission_drop_pilot else 4)
		hbox.add_theme_constant_override("separation", 4 if is_mission_drop_pilot else 6)
		text_vbox.add_theme_constant_override("separation", 0 if is_mission_drop_pilot else 1)
		var compact_name_row := name_label.get_parent() as HBoxContainer
		if compact_name_row != null:
			compact_name_row.add_theme_constant_override("separation", 3)
		var portrait_size: Vector2 = Vector2(30.0, 30.0) if is_mission_drop_pilot else PORTRAIT_IDENTITY_CATALOG_SCRIPT.get_target_size("compact")
		if _compact_portrait_size_override > 0.0:
			portrait_size = Vector2(_compact_portrait_size_override, _compact_portrait_size_override)
		portrait_rect.custom_minimum_size = portrait_size
		portrait_rect.set_meta("portrait_target_size", portrait_rect.custom_minimum_size)
		var compact_text_width := 76.0 if is_mission_drop_pilot else COMPACT_TEXT_MIN_WIDTH
		if _drag_preview_text_width > compact_text_width:
			compact_text_width = _drag_preview_text_width
		if _compact_text_min_width_override > 0.0:
			compact_text_width = _compact_text_min_width_override
		text_vbox.custom_minimum_size = Vector2(compact_text_width, 0.0)
		name_label.custom_minimum_size = Vector2(0.0, 12.0 if is_mission_drop_pilot else 14.0)
		var data_a_line_height: float = _compact_line_height_override if _compact_line_height_override > 0.0 else (10.0 if is_mission_drop_pilot else 12.0)
		var data_b_line_height: float = data_a_line_height
		data_a_label.custom_minimum_size = Vector2(0.0, data_a_line_height * float(_compact_data_a_max_lines if _compact_wrap_text_enabled else 1))
		data_b_label.custom_minimum_size = Vector2(0.0, data_b_line_height * float(_compact_data_b_max_lines if _compact_wrap_text_enabled else 1))
		badge_row.custom_minimum_size = Vector2(0.0, 22.0)
		var name_font_size: int = _compact_name_font_size_override if _compact_name_font_size_override > 0 else (10 if is_mission_drop_pilot else 14)
		var data_font_size: int = _compact_data_font_size_override if _compact_data_font_size_override > 0 else (8 if is_mission_drop_pilot else 10)
		name_label.add_theme_font_size_override("font_size", name_font_size)
		data_a_label.add_theme_font_size_override("font_size", data_font_size)
		data_b_label.add_theme_font_size_override("font_size", data_font_size)
		progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
		return

	custom_minimum_size = Vector2(custom_minimum_size.x, FULL_CARD_MIN_HEIGHT)
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	hbox.add_theme_constant_override("separation", 8)
	text_vbox.add_theme_constant_override("separation", 2)
	var full_name_row := name_label.get_parent() as HBoxContainer
	if full_name_row != null:
		full_name_row.add_theme_constant_override("separation", 4)
	PORTRAIT_IDENTITY_CATALOG_SCRIPT.apply_texture_rect_contract(portrait_rect, "roster")
	text_vbox.custom_minimum_size = Vector2.ZERO
	name_label.custom_minimum_size = Vector2.ZERO
	data_a_label.custom_minimum_size = Vector2.ZERO
	data_b_label.custom_minimum_size = Vector2.ZERO
	badge_row.custom_minimum_size = Vector2(0.0, 18.0)
	name_label.add_theme_font_size_override("font_size", 14)
	data_a_label.add_theme_font_size_override("font_size", 12)
	data_b_label.add_theme_font_size_override("font_size", 12)
	progress_bar.custom_minimum_size = Vector2(0.0, 10.0)


func _get_compact_required_width() -> float:
	var required_width := COMPACT_MARGIN_WIDTH + COMPACT_PORTRAIT_SIZE + COMPACT_HBOX_SEPARATION + COMPACT_TEXT_MIN_WIDTH
	required_width += 28.0
	if _show_remove_action:
		required_width += COMPACT_HBOX_SEPARATION + COMPACT_REMOVE_BUTTON_SIZE
	if _show_lead_indicator:
		required_width += COMPACT_HBOX_SEPARATION + COMPACT_STAR_WIDTH
	if required_width < COMPACT_CARD_MIN_SIZE.x:
		return COMPACT_CARD_MIN_SIZE.x
	return required_width


func _populate_badge_row(badge_row: HBoxContainer) -> void:
	for child in badge_row.get_children():
		badge_row.remove_child(child)
		child.queue_free()
	if not _show_badges:
		badge_row.visible = false
		return
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", _profile))
	badge_row.visible = not badges.is_empty()
	if badges.is_empty():
		return
	var icon_size: float = 22.0 if _compact_mode else 24.0
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var texture_rect := TextureRect.new()
		texture_rect.name = "RankBadge_%s" % String(badge.get("badge_key", badge.get("badge_id", "unknown"))).strip_edges()
		texture_rect.custom_minimum_size = Vector2(icon_size, icon_size)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", texture_rect, badge)
		var badge_path: String = String(badge.get("path", "")).strip_edges()
		if not badge_path.is_empty() and ResourceLoader.exists(badge_path):
			texture_rect.texture = load(badge_path) as Texture2D
		if texture_rect.texture == null:
			texture_rect.modulate = Color(1.0, 0.45, 0.35, 0.95)
			texture_rect.set_meta("missing_rank_badge_asset", true)
		badge_row.add_child(texture_rect)


func _badge_tooltips_available(badge_row: HBoxContainer) -> bool:
	if badge_row == null:
		return true
	for child in badge_row.get_children():
		var control := child as Control
		if control != null and control.visible and control.tooltip_text.strip_edges().is_empty():
			return false
	return true



func _apply_state_visuals(name_label: Label, data_a_label: Label, data_b_label: Label) -> void:
	var fill: Color = TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL
	var border: Color = TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER
	var name_color: Color = TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT
	var detail_color: Color = TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT_MUTED
	if _is_disabled:
		fill = TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_ALT
		border = TACTICAL_UI_THEME_SCRIPT.COLOR_BORDER.darkened(0.2)
		name_color = TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT_MUTED
		detail_color = TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT_MUTED
	elif _is_selected:
		fill = TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL_SELECTED
		border = SELECTED_BORDER_COLOR
	var stylebox: StyleBoxFlat = TACTICAL_UI_THEME_SCRIPT.build_flat_stylebox(fill, border, 6, 2, Vector4.ZERO)
	add_theme_stylebox_override("panel", stylebox)
	name_label.add_theme_color_override("font_color", name_color)
	data_a_label.add_theme_color_override("font_color", detail_color)
	data_b_label.add_theme_color_override("font_color", detail_color)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not _is_disabled else Control.CURSOR_ARROW


func _on_star_button_pressed() -> void:
	if _profile != null and _profile.is_valid():
		lead_toggle_requested.emit(get_unit_id())


func _on_remove_action_pressed() -> void:
	if _profile != null and _profile.is_valid():
		remove_requested.emit(get_unit_id(), _source_context)


func _load_portrait_texture(portrait_id: String, portrait_path: String) -> Texture2D:
	return PORTRAIT_IDENTITY_CATALOG_SCRIPT.load_texture(portrait_id, portrait_path)
