extends RefCounted
## Read-only A5 transport presentation. Commands remain in the tactical owner.
const THEME = preload("res://scripts/ui/tactical_ui_theme.gd")
const LAYOUT = preload("res://scripts/meta/drop_light_layout_contract.gd")
const SHIPS = preload("res://scripts/terrain/frontier_ship_visuals.gd")
const PANEL_PATH := "../TacticalUI/MissionDropshipPanel"
const FULL_PATH := "../TacticalUI/A5DropshipDetailsPopup/Contents/Scroll/A5DropshipFullPanel"


static func ensure(controller: Node) -> Control:
	var layer := controller.get_node_or_null("../TacticalUI")
	if layer == null:
		return null
	var panel := controller.get_node_or_null(PANEL_PATH) as VBoxContainer
	if panel == null:
		panel = VBoxContainer.new()
		panel.name = "MissionDropshipPanel"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_constant_override("separation", 4)
		layer.add_child(panel)
		var selector := OptionButton.new()
		selector.name = "CraftSelector"
		selector.fit_to_longest_item = false
		selector.clip_text = true
		selector.item_selected.connect(Callable(controller, "_on_native_dropship_selected"))
		panel.add_child(selector)
		THEME.style_command_button(selector)
		var card := PanelContainer.new()
		card.name = "CompactCard"
		card.set_meta("native_a5_quiet_frame", true)
		panel.add_child(card)
		card.add_theme_stylebox_override("panel", THEME.build_flat_stylebox(THEME.COLOR_PANEL, THEME.COLOR_BORDER, 2, 1, Vector4(8, 6, 8, 6)))
		var box := VBoxContainer.new()
		box.name = "Contents"
		box.add_theme_constant_override("separation", 4)
		card.add_child(box)
		var header := HBoxContainer.new()
		header.name = "Header"
		header.add_theme_constant_override("separation", 8)
		box.add_child(header)
		var ship := TextureRect.new()
		ship.name = "ShipTexture"
		ship.custom_minimum_size = Vector2(102, 60)
		ship.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ship.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ship.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(ship)
		var identity := VBoxContainer.new()
		identity.name = "Identity"
		identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		identity.add_theme_constant_override("separation", 0)
		header.add_child(identity)
		for spec in [["A5TransportHeading", 19], ["A5TransportState", 14]]:
			var label := Label.new()
			label.name = spec[0]
			label.clip_text = true
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.max_lines_visible = 1
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			identity.add_child(label)
			if String(spec[0]) == "A5TransportHeading":
				THEME.style_section_heading(label, spec[1])
			else:
				THEME.style_label(label, false, spec[1])
			_set_readout_minimum_height(label, 1.0)
		var actions := HBoxContainer.new()
		actions.name = "Actions"
		actions.add_theme_constant_override("separation", 4)
		box.add_child(actions)
		var direction_row := HBoxContainer.new()
		direction_row.name = "ApproachRow"
		var heading := Label.new()
		heading.text = "Anflugrichtung"
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		direction_row.add_child(heading)
		var dial: Control = preload("res://scripts/ui/components/approach_dial.gd").new()
		dial.name = "ApproachDial"
		dial.direction_selected.connect(func(direction: String): controller.call("_on_mission_dropship_card_approach_pressed", String(controller.get("_mission_drop_craft_id")), direction))
		direction_row.add_child(dial)
		box.add_child(direction_row)
		for action in ["set_lz", "drop", "board", "return"]:
			var button := Button.new()
			button.name = action
			button.custom_minimum_size = Vector2(0, 30)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.set_meta("mission_dropship_card_command_button", true)
			button.set_meta("mission_dropship_card_command", action)
			actions.add_child(button)
			THEME.style_command_button(button)
		var feedback := Label.new()
		feedback.name = "MissionDropshipCardFeedbackLabel"
		feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		feedback.max_lines_visible = 1
		box.add_child(feedback)
		THEME.style_label(feedback, false, 13)
		var details := Button.new()
		details.name = "DetailsButton"
		details.text = "⋯"
		details.tooltip_text = "Pilot, Passagiere, Anflugrichtung und weitere Transportaktionen"
		details.custom_minimum_size = Vector2(32, 28)
		details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		details.pressed.connect(Callable(controller, "_open_native_dropship_details"))
		header.add_child(details)
		THEME.style_command_button(details)
		var popup := PopupPanel.new()
		popup.name = "A5DropshipDetailsPopup"
		popup.theme = THEME.get_theme()
		popup.exclusive = true
		layer.add_child(popup)
		var contents := VBoxContainer.new()
		contents.name = "Contents"
		contents.add_theme_constant_override("separation", 8)
		popup.add_child(contents)
		var close := Button.new()
		close.name = "CloseButton"
		close.text = "Transportdetails schließen"
		close.pressed.connect(popup.hide)
		contents.add_child(close)
		THEME.style_command_button(close)
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		contents.add_child(scroll)
		var full := VBoxContainer.new()
		full.name = "A5DropshipFullPanel"
		full.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		full.add_theme_constant_override("separation", 8)
		scroll.add_child(full)
		full.resized.connect(Callable(controller, "_deferred_enforce_mission_dropship_panel_geometry"), CONNECT_DEFERRED)
	return controller.get_node_or_null(FULL_PATH) as Control


static func refresh(controller: Node, entries: Array, tactical_visible: bool) -> void:
	if controller == null or not controller.is_inside_tree():
		return
	ensure(controller)
	var panel := controller.get_node_or_null(PANEL_PATH) as VBoxContainer
	if panel == null:
		return
	var popup := controller.get_node_or_null("../TacticalUI/A5DropshipDetailsPopup") as PopupPanel
	if not tactical_visible and popup != null:
		popup.hide()
	panel.visible = tactical_visible
	var viewport_size := Vector2i(controller.get_viewport().get_visible_rect().size)
	var hud_layout: Dictionary = LAYOUT.get_mission_hud_layout(viewport_size)
	var rect: Rect2i = hud_layout.mission_control
	_apply_readable_geometry(panel, rect, hud_layout)
	if not panel.is_set_as_top_level():
		panel.set_as_top_level(true)
	if not panel.position.is_equal_approx(Vector2(rect.position)):
		panel.position = Vector2(rect.position)
	if panel.custom_minimum_size != Vector2(rect.size.x, 0):
		panel.custom_minimum_size = Vector2(rect.size.x, 0)
	var selector := panel.get_node("CraftSelector") as OptionButton
	var selected_id := String(controller.get("_mission_drop_craft_id"))
	var selected_card: Dictionary = {}
	var current_keys: PackedStringArray = []
	for value in entries:
		var entry: Dictionary = value
		current_keys.append(String(entry.get("craft_id", "")) + "|" + SHIPS.get_ui_display_name(entry, "dropship"))
	var selector_signature := "\n".join(current_keys)
	if String(selector.get_meta("entries_signature", "")) != selector_signature:
		selector.clear()
		for value in entries:
			var entry: Dictionary = value
			selector.add_item(SHIPS.get_ui_display_name(entry, "dropship"))
			selector.set_item_metadata(selector.item_count - 1, String(entry.get("craft_id", "")))
		selector.set_meta("entries_signature", selector_signature)
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		if String(entry.get("craft_id", "")) == selected_id:
			selected_card = entry
			selector.select(index)
	if selected_card.is_empty() and not entries.is_empty():
		selected_card = entries[0]
	selector.visible = entries.size() > 1
	var card := panel.get_node("CompactCard") as PanelContainer
	var craft_id := String(selected_card.get("craft_id", ""))
	card.set_meta("mission_dropship_card", not selected_card.is_empty())
	card.set_meta("mission_dropship_craft_id", craft_id)
	card.set_meta("mission_dropship_selected", not craft_id.is_empty() and craft_id == selected_id)
	var transit := bool(controller.call("_is_mission_dropship_card_in_transit", selected_card)) if not selected_card.is_empty() else false
	var pending := bool(controller.call("_is_network_dropship_command_pending", craft_id)) if not craft_id.is_empty() else false
	card.set_meta("mission_dropship_card_inaccessible", transit)
	card.set_meta("mission_dropship_card_accessible", not selected_card.is_empty() and not transit)
	var title := card.get_node("Contents/Header/Identity/A5TransportHeading") as Label
	var status := card.get_node("Contents/Header/Identity/A5TransportState") as Label
	var ship := card.get_node("Contents/Header/ShipTexture") as TextureRect
	title.text = "Dropship" if selected_card.is_empty() else SHIPS.get_ui_display_name(selected_card, "dropship")
	THEME.style_section_heading(title, int(hud_layout.body_font_size) + 2)
	status.text = "Kein Dropship" if selected_card.is_empty() else _state_text(selected_card)
	if not selected_card.is_empty():
		var authoritative_status := String(controller.call("_build_mission_dropship_status_text", selected_card))
		if authoritative_status == "Air asset lost":
			status.text = "Verloren"
		elif authoritative_status == "Air asset unavailable":
			status.text = "Nicht verfügbar"
		elif authoritative_status.begins_with("Damage "):
			status.text = authoritative_status.replace("Damage ", "Schaden ")
		elif authoritative_status.begins_with("Threat lock "):
			status.text = authoritative_status.replace("Threat lock ", "Bedroht ")
	var status_visual: Dictionary = _status_visual(selected_card, pending, status.text)
	status.text = String(status_visual.symbol) + "  " + status.text
	status.tooltip_text = ("Anfrage wird geprüft\n" if pending else "") + status.text
	status.add_theme_color_override("font_color", status_visual.color)
	status.set_meta("native_a5_status_shape", status_visual.symbol)
	ship.texture = controller.call("_get_mission_dropship_card_texture", selected_card) as Texture2D if not selected_card.is_empty() else null
	ship.visible = ship.texture != null
	# Wrapped, clipped Labels report a 1px native minimum. Reserve actual font
	# lines independently of the ship image, including the no-transport state.
	# One line each (clipped, full text in the tooltip): width never wraps.
	for one_line in [title, status]:
		one_line.max_lines_visible = 1
		one_line.autowrap_mode = TextServer.AUTOWRAP_OFF
		one_line.clip_text = true
		_set_readout_minimum_height(one_line, 100000.0)
	title.tooltip_text = title.text
	var landed: bool = not selected_card.is_empty() and bool(controller.call("_is_parked_campaign_dropship", craft_id))
	for action in ["set_lz", "drop", "board", "return"]:
		var button := card.get_node("Contents/Actions/" + action) as Button
		var method: String = {"set_lz":"_on_mission_dropship_card_set_lz_pressed", "drop":"_on_mission_dropship_card_drop_pressed", "board":"_on_campaign_extraction_pressed", "return":"_on_mission_dropship_return_pressed"}[action]
		var allowed := false
		if not selected_card.is_empty():
			match action:
				"set_lz": allowed = bool(controller.call("_can_request_mission_dropship_card_lz", selected_card))
				"drop": allowed = bool(controller.call("_can_request_mission_dropship_card_drop", selected_card))
				"board": allowed = landed
				"return": allowed = bool(controller.call("_can_request_mission_dropship_return", selected_card)) and (not landed or bool(controller.call("get_campaign_pilot_flight_guard", craft_id).get("ok", false)))
		button.disabled = pending or not allowed
		button.text = {"set_lz":"Landezone waehlen", "drop":"Trupp absetzen" if landed else "Landen", "board":"Einsteigen", "return":"Abheben"}[action]
		if action == "set_lz": button.text = "Landezone waehlen"
		button.tooltip_text = "Alle Bodenpersonen muessen zum Schiff. Einsteigen wird nach Ankunft bestaetigt." if action == "board" else ("Pilot und Besatzung muessen an Bord sein." if action == "return" else "Landezone und Anflug des ausgewaehlten Schiffs")
		button.set_meta("mission_dropship_craft_id", craft_id)
		var callback := Callable(controller, method).bind(craft_id)
		if not button.pressed.is_connected(callback):
			for connection in button.get_signal_connection_list("pressed"):
				button.pressed.disconnect(connection.callable)
			button.pressed.connect(callback)
		match action:
			"set_lz": button.visible = not landed
			"drop": button.visible = landed or (bool(selected_card.get("has_lz_position", false)) and bool(selected_card.get("has_embarked_payload", false)))
			"board": button.visible = false # Aufsitzen belongs to the selected troop card.
			"return": button.visible = allowed or landed
	var approach_row := card.get_node("Contents/ApproachRow") as Control
	approach_row.visible = not landed and not selected_card.is_empty()
	approach_row.get_node("ApproachDial").call("set_direction", String(selected_card.get("approach_angle", "NW")))
	_style_primary_action(card, int(hud_layout.body_font_size))
	var feedback := card.get_node("Contents/MissionDropshipCardFeedbackLabel") as Label
	feedback.text = "" if selected_card.is_empty() else String(controller.call("_get_mission_dropship_card_feedback_text", selected_card))
	if feedback.text == "Trupp ab": feedback.text = "Trupp abgesetzt"
	feedback.max_lines_visible = 1
	feedback.tooltip_text = feedback.text
	feedback.mouse_filter = Control.MOUSE_FILTER_PASS
	feedback.visible = not feedback.text.is_empty() and feedback.text != "Trupp ab"
	if not selected_card.is_empty():
		controller.call("_apply_mission_dropship_card_feedback_style", feedback, controller.call("_get_mission_dropship_card_feedback_tone", selected_card))
	card.tooltip_text = "Keine Transportdaten" if selected_card.is_empty() else String(controller.call("_build_mission_dropship_status_text", selected_card))
	var target_size := Vector2(rect.size.x, panel.get_combined_minimum_size().y)
	if not panel.size.is_equal_approx(target_size):
		panel.size = target_size


static func _apply_readable_geometry(panel: VBoxContainer, rect: Rect2i, metrics: Dictionary) -> void:
	var font_size: int = int(metrics.body_font_size)
	var signature: String = "%d:%d:p7" % [rect.size.x, font_size]
	if String(panel.get_meta("native_a5_readable_metrics", "")) == signature:
		return
	panel.set_meta("native_a5_readable_metrics", signature)
	var tier: int = 2 if font_size >= 18 else (1 if font_size >= 16 else 0)
	var card := panel.get_node("CompactCard") as PanelContainer
	card.add_theme_stylebox_override("panel", THEME.build_flat_stylebox(THEME.COLOR_PANEL, THEME.COLOR_ACCENT.darkened(0.38), 6, 2, Vector4(8, 6, 8, 6)))
	var image := card.get_node("Contents/Header/ShipTexture") as TextureRect
	image.custom_minimum_size = [Vector2(84, 48), Vector2(96, 56), Vector2(112, 64)][tier]
	var details := card.get_node("Contents/Header/DetailsButton") as Button
	details.text = "Details"
	details.custom_minimum_size = [Vector2(64, 26), Vector2(68, 28), Vector2(76, 32)][tier]
	details.add_theme_font_size_override("font_size", font_size - 1)
	var status := card.get_node("Contents/Header/Identity/A5TransportState") as Label
	THEME.style_label(status, false, font_size - 1)
	var feedback := card.get_node("Contents/MissionDropshipCardFeedbackLabel") as Label
	THEME.style_label(feedback, false, maxi(13, font_size - 2))
	var approach_heading := card.get_node("Contents/ApproachRow").get_child(0) as Label
	approach_heading.add_theme_font_size_override("font_size", font_size - 1)
	var actions := card.get_node("Contents/Actions") as HBoxContainer
	actions.add_theme_constant_override("separation", 4)
	for action in ["set_lz", "drop", "board", "return"]:
		var button := actions.get_node(NodePath(action)) as Button
		button.custom_minimum_size = Vector2(0, _action_height(font_size))
		button.add_theme_font_size_override("font_size", maxi(13, font_size - 2))
	var selector := panel.get_node("CraftSelector") as OptionButton
	selector.custom_minimum_size.y = [28, 30, 36][tier]
	selector.add_theme_font_size_override("font_size", font_size - 1)


static func _action_height(font_size: int) -> int:
	return 40 if font_size >= 18 else (32 if font_size >= 16 else 28)


static func _status_visual(card: Dictionary, pending: bool, text: String) -> Dictionary:
	if pending:
		return {"symbol": "…", "color": THEME.COLOR_WARNING}
	if card.is_empty():
		return {"symbol": "○", "color": THEME.COLOR_TEXT_MUTED}
	if text.contains("Verloren") or text.contains("Schaden") or text.contains("Nicht verfügbar") or text.contains("Bedroht"):
		return {"symbol": "!", "color": THEME.COLOR_DANGER}
	var phase: String = String(card.get("state", ""))
	if phase in ["to_mission", "inbound", "outbound", "to_homebase", "to_fob"]:
		return {"symbol": "➜", "color": THEME.COLOR_ACCENT}
	return {"symbol": "●", "color": THEME.COLOR_SUCCESS}


static func _style_primary_action(card: PanelContainer, font_size: int) -> void:
	var lz := card.get_node("Contents/Actions/set_lz") as Button
	var drop := card.get_node("Contents/Actions/drop") as Button
	var primary: String = "drop" if drop.visible and not drop.disabled else ("set_lz" if not lz.disabled else "details")
	card.set_meta("native_a5_next_action", primary)
	for button in [lz, drop]:
		var key: String = String(button.name) + ":" + str(primary == String(button.name)) + ":" + str(font_size)
		if String(button.get_meta("native_a5_primary_style", "")) != key:
			THEME.style_command_button(button, "accent" if primary == String(button.name) else "neutral")
			button.add_theme_font_size_override("font_size", maxi(13, font_size - 2))
			button.custom_minimum_size = Vector2(0, _action_height(font_size))
			button.set_meta("native_a5_primary_style", key)


static func style_details_card(card: PanelContainer) -> void:
	card.custom_minimum_size = Vector2(336, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = Color.WHITE
	card.add_theme_stylebox_override("panel", THEME.build_flat_stylebox(THEME.COLOR_PANEL, THEME.COLOR_BORDER_SELECTED if bool(card.get_meta("mission_dropship_selected", false)) else THEME.COLOR_BORDER, 2, 1))
	var margin := card.get_node("MarginContainer") as MarginContainer
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	(card.get_node("MarginContainer/VBox") as VBoxContainer).add_theme_constant_override("separation", 4)
	_style_details_node(card)
	var title := card.get_node("MarginContainer/VBox/HeaderRow/TitleLabel") as Label
	THEME.style_section_heading(title, 18)
	title.custom_minimum_size.y = ceilf(title.get_theme_font("font").get_height(18))
	var pilot := card.get_node_or_null("MarginContainer/VBox/ContentRow/InfoVBox/PilotCardHost/PilotCard") as Control
	if pilot != null:
		# Transit disables commands, not the readability of this read-only profile.
		pilot.modulate = Color.WHITE


static func _style_details_node(node: Node) -> void:
	if node is Label:
		var label := node as Label
		var font_size := maxi(12, label.get_theme_font_size("font_size"))
		THEME.style_label(label, false, font_size)
		label.custom_minimum_size.y = maxf(label.custom_minimum_size.y, ceilf(label.get_theme_font("font").get_height(font_size)))
		label.tooltip_text = label.text if label.tooltip_text.is_empty() else label.tooltip_text
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	elif node is Button:
		var button := node as Button
		THEME.style_command_button(button, "selected" if bool(button.get_meta("mission_dropship_card_command_active", false)) else "neutral")
		button.add_theme_font_size_override("font_size", maxi(12, button.get_theme_font_size("font_size")))
		button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 28), maxf(button.custom_minimum_size.y, 28))
	elif node is Control and bool(node.get_meta("mission_dropship_passenger_portrait_chip", false)):
		var chip := node as Control
		chip.custom_minimum_size = Vector2(72, 68)
		var portrait := chip.get_node("PassengerPortraitRect") as TextureRect
		portrait.custom_minimum_size = Vector2(42, 48)
	for child in node.get_children():
		_style_details_node(child)


static func preserve_details_scroll(controller: Node) -> void:
	var scroll := controller.get_node_or_null("../TacticalUI/A5DropshipDetailsPopup/Contents/Scroll") as ScrollContainer
	if scroll != null and not scroll.has_meta("native_a5_pending_scroll_position"):
		scroll.set_meta("native_a5_pending_scroll_position", Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical))


static func restore_details_scroll(controller: Node) -> void:
	var scroll := controller.get_node_or_null("../TacticalUI/A5DropshipDetailsPopup/Contents/Scroll") as ScrollContainer
	if scroll != null and scroll.has_meta("native_a5_pending_scroll_position"):
		var previous: Vector2i = scroll.get_meta("native_a5_pending_scroll_position")
		scroll.scroll_horizontal = previous.x
		scroll.scroll_vertical = previous.y
		scroll.remove_meta("native_a5_pending_scroll_position")


static func fit_details_popup(controller: Node) -> void:
	var popup := controller.get_node_or_null("../TacticalUI/A5DropshipDetailsPopup") as PopupPanel
	var full := controller.get_node_or_null(FULL_PATH) as Control
	if popup == null or full == null or not popup.visible or not controller.is_inside_tree():
		return
	var available := controller.get_viewport().get_visible_rect().size - Vector2(48, 48)
	var contents := popup.get_node("Contents") as VBoxContainer
	var close := contents.get_node("CloseButton") as Button
	var padding := THEME.get_theme().get_stylebox("panel", "PopupPanel").get_minimum_size()
	var content_height := full.get_combined_minimum_size().y if full.visible else 0.0
	var height := close.get_combined_minimum_size().y + contents.get_theme_constant("separation") + content_height + padding.y
	var target_size := Vector2i(minf(440, available.x), minf(maxf(120, ceilf(height)), available.y))
	var resized := popup.size != target_size
	if resized:
		popup.size = target_size
	# Native minimum-size adjustment can invalidate popup_centered()'s initial
	# origin before content layout. Center the final geometry, not that stale
	# origin; positioning never reopens the window or steals action focus.
	if popup.is_embedded():
		var centered := Vector2i((controller.get_viewport().get_visible_rect().size - Vector2(popup.size)) * 0.5)
		if popup.position != centered:
			popup.position = centered
	elif resized:
		popup.move_to_center()


static func _set_readout_minimum_height(label: Label, available_width: float) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var line_spacing := label.get_theme_constant("line_spacing")
	var signature := [label.text, available_width, font_size, line_spacing, font]
	if label.get_meta("native_a5_readout_metrics", []) == signature:
		return
	var line_height := ceilf(font.get_height(font_size))
	var needs_two_lines := label.text.contains("\n") or font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > maxf(available_width, 1.0)
	var minimum := Vector2(0, line_height * (2.0 if needs_two_lines else 1.0) + (line_spacing if needs_two_lines else 0))
	if label.custom_minimum_size != minimum:
		label.custom_minimum_size = minimum
	label.set_meta("native_a5_readout_metrics", signature)


static func _state_text(card: Dictionary) -> String:
	var state := String(card.get("state", ""))
	var text := "Bereit"
	match state:
		"to_mission", "inbound": text = "Im Anflug"
		"to_homebase": text = "Heimflug"
		"to_fob": text = "Rückflug FOB"
		"landed", "on_mission": text = "Gelandet"
		"waiting": text = "Bereit"
		"unloading": text = "Ausstieg läuft"
		"outbound": text = "Im Abflug"
		"complete": text = "Abgesetzt"
		"recovering": text = "Wird geborgen"
		"unavailable": text = "Nicht verfügbar"
		"destroyed", "lost": text = "Verloren"
		_: text = "Status unbekannt"
	var eta := int(ceil(float(card.get("eta_seconds", 0))))
	if eta > 0 and state in ["to_mission", "inbound", "to_homebase", "to_fob"]:
		text += " · %d s" % eta
	return text
