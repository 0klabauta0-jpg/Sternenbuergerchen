class_name TransportCraftCardUI
extends RefCounted

const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")


static func ensure_card_structure(card: PanelContainer) -> void:
	if card == null or card.get_node_or_null("MarginContainer") != null:
		return
	card.clip_contents = true

	var margin := MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", 6)
	vbox.add_child(header_row)

	var title_label := Label.new()
	title_label.name = "TitleLabel"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", 11)
	META_UI_SKIN_SCRIPT.style_body_label(title_label, 11)
	header_row.add_child(title_label)

	for button_name in ["PrimaryActionButton", "SecondaryActionButton"]:
		var action_button := Button.new()
		action_button.name = button_name
		action_button.visible = false
		var action_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
		action_button.custom_minimum_size = Vector2(float(action_size.x), float(action_size.y))
		action_button.add_theme_font_size_override("font_size", 8)
		header_row.add_child(action_button)

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.custom_minimum_size = Vector2(0.0, 58.0)
	content_row.add_theme_constant_override("separation", 8)
	vbox.add_child(content_row)

	var ship_texture := TextureRect.new()
	ship_texture.name = "ShipTexture"
	ship_texture.custom_minimum_size = Vector2(88.0, 52.0)
	ship_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ship_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ship_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_row.add_child(ship_texture)

	var info_vbox := VBoxContainer.new()
	info_vbox.name = "InfoVBox"
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	content_row.add_child(info_vbox)

	var pilot_card_host := VBoxContainer.new()
	pilot_card_host.name = "PilotCardHost"
	pilot_card_host.custom_minimum_size = Vector2(0.0, 58.0)
	pilot_card_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(pilot_card_host)

	var pilot_label_fallback := Label.new()
	pilot_label_fallback.name = "PilotLabelFallback"
	pilot_label_fallback.visible = false
	pilot_label_fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pilot_label_fallback.add_theme_font_size_override("font_size", 9)
	META_UI_SKIN_SCRIPT.style_body_label(pilot_label_fallback, 9)
	info_vbox.add_child(pilot_label_fallback)

	var info_lines_host := VBoxContainer.new()
	info_lines_host.name = "InfoLinesHost"
	info_lines_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_lines_host.add_theme_constant_override("separation", 2)
	info_vbox.add_child(info_lines_host)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0.0, 8.0)
	progress_bar.visible = false
	vbox.add_child(progress_bar)

	var extra_content_host := VBoxContainer.new()
	extra_content_host.name = "ExtraContentHost"
	extra_content_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	extra_content_host.add_theme_constant_override("separation", 4)
	vbox.add_child(extra_content_host)


static func apply_card_state(card: PanelContainer, state: Dictionary) -> void:
	ensure_card_structure(card)
	var is_selected: bool = bool(state.get("selected", false))
	var is_in_transit: bool = bool(state.get("in_transit", false))
	var can_stage: bool = bool(state.get("can_stage", false))
	card.add_theme_stylebox_override("panel", _build_transport_craft_stylebox(is_selected, is_in_transit, can_stage))
	card.modulate = Color(1.0, 1.0, 1.0, 0.58) if is_in_transit else Color(1.0, 1.0, 1.0, 1.0)

	var title_label := card.get_node("MarginContainer/VBox/HeaderRow/TitleLabel") as Label
	title_label.text = String(state.get("title_text", "")).strip_edges()
	var title_font_size: int = int(state.get("title_font_size", 11))
	title_label.add_theme_font_size_override("font_size", title_font_size)
	META_UI_SKIN_SCRIPT.style_body_label(title_label, title_font_size)

	var margin := card.get_node("MarginContainer") as MarginContainer
	margin.add_theme_constant_override("margin_left", int(state.get("margin_left", 6)))
	margin.add_theme_constant_override("margin_top", int(state.get("margin_top", 6)))
	margin.add_theme_constant_override("margin_right", int(state.get("margin_right", 6)))
	margin.add_theme_constant_override("margin_bottom", int(state.get("margin_bottom", 6)))

	var vbox := card.get_node("MarginContainer/VBox") as VBoxContainer
	vbox.add_theme_constant_override("separation", int(state.get("vbox_separation", 4)))

	var header_row := card.get_node("MarginContainer/VBox/HeaderRow") as HBoxContainer
	header_row.add_theme_constant_override("separation", int(state.get("header_separation", 6)))

	_apply_action_button(card.get_node("MarginContainer/VBox/HeaderRow/PrimaryActionButton") as Button, Dictionary(state.get("primary_action", {})))
	_apply_action_button(card.get_node("MarginContainer/VBox/HeaderRow/SecondaryActionButton") as Button, Dictionary(state.get("secondary_action", {})))

	var content_row := card.get_node("MarginContainer/VBox/ContentRow") as HBoxContainer
	content_row.custom_minimum_size = Vector2(0.0, float(state.get("content_minimum_height", 58.0)))
	content_row.add_theme_constant_override("separation", int(state.get("content_separation", 8)))

	var info_vbox := card.get_node("MarginContainer/VBox/ContentRow/InfoVBox") as VBoxContainer
	info_vbox.add_theme_constant_override("separation", int(state.get("info_vbox_separation", 2)))

	var info_lines_host := card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/InfoLinesHost") as VBoxContainer
	info_lines_host.add_theme_constant_override("separation", int(state.get("info_lines_separation", 2)))

	var ship_texture := card.get_node("MarginContainer/VBox/ContentRow/ShipTexture") as TextureRect
	ship_texture.texture = state.get("ship_texture", null) as Texture2D
	ship_texture.custom_minimum_size = Vector2(
		float(state.get("ship_texture_width", 88.0)),
		float(state.get("ship_texture_height", 52.0))
	)
	ship_texture.stretch_mode = int(state.get("ship_texture_stretch_mode", TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	ship_texture.set_meta("transport_ship_texture_enlarged", ship_texture.custom_minimum_size.x > 88.0 or ship_texture.custom_minimum_size.y > 52.0)
	ship_texture.modulate = Color(1.0, 1.0, 1.0, 0.52) if is_in_transit else Color(1.0, 1.0, 1.0, 1.0)

	_refresh_pilot_content(card, state)
	_refresh_info_lines(card, Array(state.get("info_lines", [])), int(state.get("info_line_font_size", 9)))

	var progress_bar := card.get_node("MarginContainer/VBox/ProgressBar") as ProgressBar
	progress_bar.value = clampf(float(state.get("progress_value", 0.0)), 0.0, 100.0)
	progress_bar.visible = bool(state.get("progress_visible", false))
	progress_bar.custom_minimum_size = Vector2(0.0, float(state.get("progress_bar_height", 8.0)))

	if bool(state.get("clear_extra_content", true)):
		clear_extra_content(card)


static func get_extra_content_host(card: PanelContainer) -> VBoxContainer:
	ensure_card_structure(card)
	return card.get_node("MarginContainer/VBox/ExtraContentHost") as VBoxContainer


static func clear_extra_content(card: PanelContainer) -> void:
	var host := get_extra_content_host(card)
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()


static func _apply_action_button(button: Button, config: Dictionary) -> void:
	if button == null:
		return
	var is_visible: bool = bool(config.get("visible", false))
	button.visible = is_visible
	if not is_visible:
		button.disabled = true
		return
	button.text = String(config.get("text", "")).strip_edges()
	button.disabled = bool(config.get("disabled", false))
	var action_size: Vector2i = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("ACTION_BUTTON_SIZE")
	var square_size := float(config.get("square_size", config.get("minimum_width", action_size.x)))
	button.custom_minimum_size = Vector2(square_size, square_size)
	button.tooltip_text = String(config.get("tooltip_text", "")).strip_edges()
	var use_ready_style: bool = bool(config.get("ready_style", false))
	if not button.disabled and use_ready_style:
		META_UI_SKIN_SCRIPT.style_transfer_button(button, true)
	else:
		META_UI_SKIN_SCRIPT.style_secondary_button(button)
	var pressed_callback: Callable = config.get("callback", Callable())
	if pressed_callback.is_valid() and not button.pressed.is_connected(pressed_callback):
		button.pressed.connect(pressed_callback)


static func _refresh_pilot_content(card: PanelContainer, state: Dictionary) -> void:
	var pilot_card_host := card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/PilotCardHost") as VBoxContainer
	var fallback_label := card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/PilotLabelFallback") as Label
	pilot_card_host.custom_minimum_size = Vector2(0.0, float(state.get("pilot_card_minimum_height", 58.0)))
	pilot_card_host.add_theme_constant_override("separation", int(state.get("pilot_host_separation", 0)))
	var pilot_profile = state.get("pilot_profile", null)
	var pilot_card = pilot_card_host.get_node_or_null("PilotCard")
	var pilot_text: String = String(state.get("pilot_text", "")).strip_edges()
	var pilot_text_font_size: int = int(state.get("pilot_text_font_size", 9))
	fallback_label.add_theme_font_size_override("font_size", pilot_text_font_size)
	META_UI_SKIN_SCRIPT.style_body_label(fallback_label, pilot_text_font_size)
	if pilot_profile != null:
		if pilot_card == null:
			pilot_card = NPC_COMPACT_CARD_SCENE.instantiate()
			pilot_card.name = "PilotCard"
			pilot_card_host.add_child(pilot_card)
		pilot_card.visible = true
		pilot_card.custom_minimum_size = Vector2(
			float(state.get("pilot_card_minimum_width", 156.0)),
			float(state.get("pilot_card_minimum_height", 58.0))
		)
		pilot_card.call(
			"setup_from_profile",
			pilot_profile,
			{
				"source_context": String(state.get("pilot_source_context", "transport_craft_pilot")).strip_edges(),
				"selected": bool(state.get("pilot_selected", false)),
				"disabled": bool(state.get("pilot_disabled", false)),
				"drag_enabled": false,
				"compact_mode": true,
			}
		)
		pilot_card.mouse_filter = int(state.get("pilot_mouse_filter", Control.MOUSE_FILTER_PASS))
		pilot_card.modulate = Color(1.0, 1.0, 1.0, 0.56) if bool(state.get("pilot_disabled", false)) else Color(1.0, 1.0, 1.0, 1.0)
		var card_pressed: Callable = state.get("pilot_card_pressed", Callable())
		if card_pressed.is_valid() and pilot_card.has_signal("card_pressed") and not pilot_card.card_pressed.is_connected(card_pressed):
			pilot_card.card_pressed.connect(card_pressed)
		var card_open_requested: Callable = state.get("pilot_card_open_requested", Callable())
		if card_open_requested.is_valid() and pilot_card.has_signal("card_open_requested") and not pilot_card.card_open_requested.is_connected(card_open_requested):
			pilot_card.card_open_requested.connect(card_open_requested)
		fallback_label.visible = false
		return

	if pilot_card != null:
		pilot_card.visible = false
	fallback_label.visible = not pilot_text.is_empty()
	fallback_label.text = pilot_text


static func _refresh_info_lines(card: PanelContainer, info_lines: Array, font_size: int = 9) -> void:
	var info_lines_host := card.get_node("MarginContainer/VBox/ContentRow/InfoVBox/InfoLinesHost") as VBoxContainer
	for child in info_lines_host.get_children():
		info_lines_host.remove_child(child)
		child.queue_free()
	for line_variant in info_lines:
		var line_text: String = String(line_variant).strip_edges()
		if line_text.is_empty():
			continue
		var info_label := Label.new()
		info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info_label.add_theme_font_size_override("font_size", font_size)
		META_UI_SKIN_SCRIPT.style_body_label(info_label, font_size)
		info_label.text = line_text
		info_lines_host.add_child(info_label)


static func _build_transport_craft_stylebox(is_selected: bool, is_in_transit: bool, can_stage: bool) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.11, 0.14, 0.17, 0.72) if is_in_transit else Color(0.11, 0.14, 0.17, 1.0)
	if is_selected:
		stylebox.border_color = Color(0.66, 0.73, 0.80, 0.96)
	elif is_in_transit:
		stylebox.border_color = Color(0.56, 0.59, 0.63, 0.82)
	elif can_stage:
		stylebox.border_color = Color(0.48, 0.63, 0.49, 1.0)
	else:
		stylebox.border_color = Color(0.31, 0.36, 0.42, 1.0)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	return stylebox
