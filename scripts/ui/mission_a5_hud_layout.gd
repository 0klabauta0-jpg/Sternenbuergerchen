extends RefCounted
## Pure presentation of existing mission Controls. No command, transport or unit state.
## Existing Control instances and their NodePaths/callbacks remain intact.

const THEME := preload("res://scripts/ui/tactical_ui_theme.gd")
const LAYOUT := preload("res://scripts/meta/drop_light_layout_contract.gd")
const ICONS := preload("res://scripts/ui/native_ui_icons.gd")
const BASE := "../TacticalUI/BottomDock/BottomMargin/BottomRow/"
const GRID := BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const INFO := BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox"
const FIRST: PackedStringArray = ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "GoCommandMatrixButton"]
const SECOND: PackedStringArray = ["TargetButton", "ClearTargetButton", "DeleteOrderButton", "SortCommandMatrixButton"]
const RULES: PackedStringArray = ["FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton"]
const RULE_LABELS := {"FireRuleHoldButton": "FH", "FireRuleReturnButton": "AF", "FireRuleFreeButton": "FF", "FireRuleSuppressButton": "UN"}
const LABELS := {"MoveButton": "Bewegen", "TakeButton": "Nehmen", "HoldButton": "Halten", "FlankButton": "Flanke", "GoCommandMatrixButton": "Plan\nausführen", "TargetButton": "Ziel", "ClearTargetButton": "Leeren", "DeleteOrderButton": "Löschen", "SortCommandMatrixButton": "Ordnen"}
const ICON_IDS := {"MoveButton": "move", "TakeButton": "take", "HoldButton": "defend", "FlankButton": "flank"}
const CHARACTER_OVERLAY_Z := 64


static func configure(controller: Node, state: Dictionary = {}) -> void:
	var layer := controller.get_node_or_null("../TacticalUI") as CanvasLayer
	var grid := controller.get_node_or_null(GRID) as GridContainer
	if layer == null or grid == null:
		return
	var viewport_size := Vector2i(controller.get_viewport().get_visible_rect().size)
	var character_overlay := layer.get_node_or_null("CharacterOverlay") as Control
	if character_overlay != null:
		character_overlay.z_as_relative = false
		character_overlay.z_index = CHARACTER_OVERLAY_Z
	var geometry_signature := _geometry_signature(controller, grid, viewport_size)
	if String(grid.get_meta("native_a5_geometry_signature", "")) == geometry_signature:
		grid.set_meta("native_a5_geometry_skip_count", int(grid.get_meta("native_a5_geometry_skip_count", 0)) + 1)
		_refresh_presentation(controller, grid, state)
		return
	grid.set_meta("native_a5_geometry_apply_count", int(grid.get_meta("native_a5_geometry_apply_count", 0)) + 1)
	var layout: Dictionary = LAYOUT.get_mission_hud_layout(viewport_size)
	var band: Rect2i = layout.bottom_dock
	var team: Rect2i = layout.selected_fireteam
	var target := _ensure_target_panel(layer)
	_place(target, Rect2(layout.target_order))
	target.z_index = 2
	_layout_target_labels(target, Rect2(layout.target_order))
	var team_panel := controller.get_node_or_null(BASE + "FireteamPanel") as PanelContainer
	if team_panel != null:
		_ensure_label(team_panel, "A5TeamIdentity", 16)
		(team_panel.get_node("A5TeamIdentity") as Label).max_lines_visible = 1
		_place(team_panel.get_node("A5TeamIdentity") as Control, Rect2(team.position + Vector2i(8, 6), Vector2i(team.size.x - 88, 24)))
		_ensure_label(team_panel, "A5FireRuleHeading", 12).text = "FEUERREGEL"
		_place(team_panel.get_node("A5FireRuleHeading") as Control, Rect2(team.position + Vector2i(8, 100), Vector2i(272, 18)))
		THEME.style_card(team_panel)
	var band_panel := controller.get_node_or_null("../TacticalUI/BottomDock") as PanelContainer
	if band_panel != null:
		band_panel.theme = THEME.get_theme()
		if not band_panel.has_meta("a5_band_style"):
			var style: StyleBoxFlat = THEME.build_flat_stylebox(THEME.COLOR_PANEL, THEME.COLOR_BORDER, 0, 1, Vector4.ZERO).duplicate()
			style.border_width_left = 0
			style.border_width_right = 0
			style.border_width_bottom = 0
			band_panel.set_meta("a5_band_style", style)
		band_panel.add_theme_stylebox_override("panel", band_panel.get_meta("a5_band_style"))
	for path in [BASE + "CommandPanel", BASE + "CommandPanel/CommandMargin", BASE + "CommandPanel/CommandMargin/CommandScroll", BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox", GRID, BASE + "FireteamPanel", BASE + "FireteamPanel/FireteamMargin", BASE + "FireteamPanel/FireteamMargin/FireteamVBox", BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow"]:
		var control := controller.get_node_or_null(path) as Control
		if control != null:
			control.clip_contents = false
	for path in [BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandHeaderLabel", BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamHeaderLabel"]:
		var label := controller.get_node_or_null(path) as Control
		if label != null:
			label.visible = false
	grid.columns = 5
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.set_meta("native_a5_layout", true)
	grid.set_meta("command_hierarchy_order", PackedStringArray(["move", "take", "defend", "flank", "go_plan", "engage", "clear_target", "delete_order", "sort_fireteam"]))
	var context_buttons: Array[Button] = []
	for child in grid.get_children():
		var button := child as Button
		if button == null:
			continue
		_hide_internal_slot_badge(button)
		var name := String(button.name)
		if FIRST.has(name) or SECOND.has(name):
			var row := 0 if FIRST.has(name) else 1
			var column := FIRST.find(name) if row == 0 else SECOND.find(name)
			_present_primary_action(button, state)
			button.visible = true
			_place(button, Rect2(Vector2(band.position + Vector2i(8 + column * 70, 16 + row * 72)), Vector2(64, 64)))
			button.set_meta("native_a5_primary_action", true)
		elif RULES.has(name):
			var index := RULES.find(name)
			_present_fire_rule(button, state)
			button.visible = true
			_place(button, Rect2(Vector2(team.position + Vector2i(8 + index * 70, 122)), Vector2(64, 36)))
		elif bool(button.get_meta("drop_light_command_placeholder", false)):
			var active_context := not button.disabled and not button.text.strip_edges().is_empty() and not button.get_signal_connection_list("pressed").is_empty()
			button.visible = active_context
			if active_context:
				context_buttons.append(button)
	var context_offset := 48 if not context_buttons.is_empty() else 0
	for index in range(context_buttons.size()):
		var button := context_buttons[index]
		_present_context_button(button)
		_place(button, Rect2(368 + index * 128, band.position.y - 44, 120, 36))
	_place_context_tool(controller, "DoorBreachButton", Rect2(Vector2(layout.target_order.position + Vector2i(8, 132)), Vector2(112, 32)), true)
	_place_context_tool(controller, "WaypointEraseButton", Rect2(Vector2(layout.target_order.position + Vector2i(128, 132)), Vector2(112, 32)), false)
	var all_button := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton") as Button
	if all_button != null:
		_place(all_button, Rect2(Vector2(team.position + Vector2i(team.size.x - 76, 6)), Vector2(64, 26)))
	var stance_panel := controller.get_node_or_null(INFO + "/TacticalStancePanel") as Control
	if stance_panel != null:
		stance_panel.clip_contents = false
		_place(stance_panel, Rect2(Vector2(team.position + Vector2i(8, 34)), Vector2(280, 62)))
		_refresh_stance_buttons(stance_panel)
	var info_scroll := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll") as ScrollContainer
	if info_scroll != null:
		info_scroll.clip_contents = true
		_place(info_scroll, Rect2(Vector2(team.position + Vector2i(304, 34)), Vector2(maxi(120, team.size.x - 320), 132)))
		# Legacy status strings remain readable in the existing scroll and tooltip,
		# but their old 640px/large-label minimum may not spill over the header.
		for label_name in ["CommandFeedbackLabel", "HotkeyLegendLabel"]:
			var detail := controller.get_node_or_null(INFO + "/" + label_name) as Label
			if detail != null:
				detail.custom_minimum_size = Vector2.ZERO
				detail.clip_text = true
				detail.max_lines_visible = 3
				detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				detail.tooltip_text = detail.text
				THEME.style_label(detail, label_name == "HotkeyLegendLabel", 12)
	_layout_team_readouts(controller, Rect2(team))
	var members := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as ScrollContainer
	if members != null:
		var members_rect := Rect2(layout.selected_members)
		members_rect.position.y -= context_offset
		_place(members, members_rect)
		members.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		members.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		members.mouse_filter = Control.MOUSE_FILTER_PASS
		members.clip_contents = true
	var mini := controller.get_node_or_null("../TacticalUI/FireteamMiniPanel") as Control
	if mini != null:
		_place(mini, Rect2(layout.fireteam_mini))
		mini.set_meta("native_a5_layout", true)
	var log_panel := controller.get_node_or_null("../TacticalUI/TacticalEventLogPanel") as Control
	if log_panel != null:
		var log_rect := Rect2(layout.event_log)
		log_rect.position.y -= context_offset
		_place(log_panel, log_rect)
		log_panel.set_meta("native_a5_layout", true)
		log_panel.clip_contents = true
	var strategic := controller.get_node_or_null(BASE + "StrategicPanel") as Control
	if strategic != null:
		_place(strategic, Rect2(layout.mission_control))
	_keep_transport_and_control_separate(controller)
	grid.set_meta("native_a5_geometry_signature", geometry_signature)


static func _geometry_signature(controller: Node, grid: GridContainer, viewport_size: Vector2i) -> String:
	var context: PackedStringArray = []
	for child in grid.get_children():
		if child is Button and _is_active_context_button(child):
			context.append("%s:%s" % [child.name, child.text])
	var craft := controller.get_node_or_null("../TacticalUI/MissionDropshipPanel") as Control
	var transport := str(craft.get_global_rect()) if craft != null and craft.visible else "hidden"
	return "%s|%d|%s|%s" % [viewport_size, grid.get_child_count(), "|".join(context), transport]


static func _is_active_context_button(button: Button) -> bool:
	return bool(button.get_meta("drop_light_command_placeholder", false)) and not button.disabled and not button.text.strip_edges().is_empty() and not button.get_signal_connection_list("pressed").is_empty()


static func _refresh_presentation(controller: Node, grid: GridContainer, state: Dictionary) -> void:
	# Bounded existing controls only. Selection, disabled state and source text
	# can change without invalidating geometry or rebuilding a control tree.
	for child in grid.get_children():
		var button := child as Button
		if button == null:
			continue
		_hide_internal_slot_badge(button)
		var name := String(button.name)
		if FIRST.has(name) or SECOND.has(name):
			_present_primary_action(button, state)
		elif RULES.has(name):
			_present_fire_rule(button, state)
		elif _is_active_context_button(button):
			_present_context_button(button)
	var layout: Dictionary = LAYOUT.get_mission_hud_layout(Vector2i(controller.get_viewport().get_visible_rect().size))
	_place_context_tool(controller, "DoorBreachButton", Rect2(Vector2(layout.target_order.position + Vector2i(8, 132)), Vector2(112, 32)), true)
	_place_context_tool(controller, "WaypointEraseButton", Rect2(Vector2(layout.target_order.position + Vector2i(128, 132)), Vector2(112, 32)), false)
	var stance := controller.get_node_or_null(INFO + "/TacticalStancePanel") as Control
	if stance != null:
		_refresh_stance_buttons(stance)
	_layout_team_readouts(controller, Rect2(layout.selected_fireteam))


static func _hide_internal_slot_badge(button: Button) -> void:
	# Legacy refreshes can create this direct child after the initial layout.
	# Keep diagnostic text/slot metadata; only hide the internal player badge.
	var marker := button.get_node_or_null("TinyButtonMarker") as Control
	if marker != null and marker.visible:
		marker.visible = false
		marker.set_meta("command_matrix_player_hidden", true)


static func _button_style_dirty(button: Button, selected: bool, font_size: int) -> bool:
	if not button.has_meta("native_a5_normal_style"):
		return true
	return button.get_meta("native_a5_normal_style") != button.get_theme_stylebox("normal") \
		or bool(button.get_meta("native_a5_selected", not selected)) != selected \
		or button.get_theme_font_size("font_size") != font_size \
		or button.get_meta("native_a5_font_color", Color.TRANSPARENT) != button.get_theme_color("font_color") \
		or button.self_modulate != Color.WHITE


static func _remember_button_style(button: Button, selected: bool) -> void:
	button.set_meta("native_a5_normal_style", button.get_theme_stylebox("normal"))
	button.set_meta("native_a5_font_color", button.get_theme_color("font_color"))
	button.set_meta("native_a5_selected", selected)


static func _present_primary_action(button: Button, state: Dictionary) -> void:
	if not button.visible:
		button.visible = true
	var name := String(button.name)
	var selected := bool(state.get("target_armed", false)) if name == "TargetButton" else button.button_pressed
	if _button_style_dirty(button, selected, 12):
		THEME.style_action_tile(button, selected, name == "GoCommandMatrixButton")
		if name == "GoCommandMatrixButton":
			_style_execute_tile(button)
		button.self_modulate = Color.WHITE
		button.add_theme_font_size_override("font_size", 12)
		_remember_button_style(button, selected)
	if button.text != LABELS[name]:
		button.text = LABELS[name]
	if ICON_IDS.has(name):
		var icon: Texture2D = ICONS.get_icon(ICON_IDS[name])
		if button.icon != icon:
			button.icon = icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = true
	if button.get_theme_constant("icon_max_width") != 24:
		button.add_theme_constant_override("icon_max_width", 24)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.clip_text = false


static func _present_fire_rule(button: Button, state: Dictionary) -> void:
	if not button.visible:
		button.visible = true
	var selected := String(button.get_meta("fire_rule", "")) == String(state.get("fire_rule", ""))
	if _button_style_dirty(button, selected, 13):
		THEME.style_command_button(button, "selected" if selected else "neutral")
		button.self_modulate = Color.WHITE
		button.add_theme_font_size_override("font_size", 13)
		_remember_button_style(button, selected)
	button.text = RULE_LABELS[String(button.name)]
	button.icon = null


static func _present_context_button(button: Button) -> void:
	if not button.visible:
		button.visible = true
	if _button_style_dirty(button, false, 12):
		THEME.style_command_button(button, "accent")
		button.self_modulate = Color.WHITE
		button.add_theme_font_size_override("font_size", 12)
		_remember_button_style(button, false)


static func _refresh_stance_buttons(stance: Control) -> void:
	for name in ["Cautious", "Normal", "Aggressive"]:
		var button := stance.get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer/%sButton" % name) as Button
		if button != null:
			if button.get_theme_font_size("font_size") != 12:
				button.add_theme_font_size_override("font_size", 12)
			if button.custom_minimum_size != Vector2(76, 26):
				button.custom_minimum_size = Vector2(76, 26)


static func refresh(controller: Node, view_model: Dictionary) -> void:
	var panel := controller.get_node_or_null("../TacticalUI/A5TargetOrderPanel") as PanelContainer
	if panel == null:
		return
	panel.visible = bool(view_model.get("visible", true))
	_set_text(panel.get_node("Contents/Target") as Label, "Ziel gewählt" if bool(view_model.get("target_selected", false)) else "Ziel auswählen")
	_set_text(panel.get_node("Contents/Order") as Label, String(view_model.get("order", "Kein Plan ausgewählt")))
	var feedback := String(view_model.get("feedback", ""))
	_set_text(panel.get_node("Contents/Feedback") as Label, feedback)
	panel.tooltip_text = "Ziel: %s\n%s\n%s\n\n%s" % [view_model.get("target", "—"), view_model.get("order", ""), feedback, view_model.get("detail", "")]
	var title := controller.get_node_or_null(BASE + "FireteamPanel/A5TeamIdentity") as Label
	if title != null:
		_set_text(title, String(view_model.get("team", "Kein Fireteam ausgewählt")))


static func _ensure_target_panel(layer: CanvasLayer) -> PanelContainer:
	var panel := layer.get_node_or_null("A5TargetOrderPanel") as PanelContainer
	if panel != null:
		return panel
	panel = PanelContainer.new()
	panel.name = "A5TargetOrderPanel"
	panel.theme = THEME.get_theme()
	THEME.style_card(panel)
	panel.set_meta("ui_sets_gameplay_truth", false)
	layer.add_child(panel)
	var contents := VBoxContainer.new()
	contents.name = "Contents"
	contents.add_theme_constant_override("separation", 6)
	panel.add_child(contents)
	_ensure_label(contents, "Heading", 13).text = "ZIEL / AUFTRAG"
	_ensure_label(contents, "Target", 14)
	_ensure_label(contents, "Order", 13).max_lines_visible = 2
	_ensure_label(contents, "Feedback", 12).max_lines_visible = 2
	return panel


static func _layout_target_labels(panel: PanelContainer, rect: Rect2) -> void:
	var contents := panel.get_node("Contents") as Control
	contents.clip_contents = false
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slots := {"Heading": Rect2(8, 8, 232, 18), "Target": Rect2(8, 32, 232, 34), "Order": Rect2(8, 68, 232, 38), "Feedback": Rect2(8, 108, 232, 20)}
	for name in slots:
		var label := contents.get_node(NodePath(name)) as Label
		var slot: Rect2 = slots[name]
		_place(label, Rect2(rect.position + slot.position, slot.size))
		label.max_lines_visible = 1 if name in ["Heading", "Feedback"] else 2
		label.clip_text = true


static func _style_execute_tile(button: Button) -> void:
	# "ausführen" needs 60px with the same readable 12px label. Its measured
	# 68px minimum came from horizontal padding, so keep type size and trim only
	# this tile's inside padding. Cached new styles leave shared boxes untouched.
	button.icon = null
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var base := button.get_theme_stylebox(state) as StyleBoxFlat
		button.add_theme_stylebox_override(state, THEME.build_flat_stylebox(base.bg_color, base.border_color, base.corner_radius_top_left, base.border_width_left, Vector4(2, 4, 2, 4)))


static func _layout_team_readouts(controller: Node, rect: Rect2) -> void:
	# Preserve the real decision/status readouts in their original nodes. They
	# get bounded lines beside the parameters instead of occupying the header.
	var width := maxf(120.0, rect.size.x - 320.0)
	var readouts := {
		BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel": Rect2(304, 34, width, 56),
		INFO + "/CommandFeedbackLabel": Rect2(304, 96, width, 48),
		INFO + "/HotkeyLegendLabel": Rect2(304, 148, width, 18),
	}
	for path in readouts:
		var label := controller.get_node_or_null(NodePath(path)) as Label
		if label == null:
			continue
		var slot: Rect2 = readouts[path]
		label.visible = true
		label.clip_text = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = 1 if label.name == "HotkeyLegendLabel" else 3
		label.tooltip_text = label.text if label.tooltip_text.is_empty() else label.tooltip_text
		var font_size := 13 if label.name == "FireteamStatusLabel" else 12
		var color: Color = THEME.COLOR_TEXT_MUTED if label.name == "HotkeyLegendLabel" else THEME.COLOR_TEXT
		if label.get_theme_font_size("font_size") != font_size or label.get_theme_color("font_color") != color:
			THEME.style_label(label, label.name == "HotkeyLegendLabel", font_size)
		_place(label, Rect2(rect.position + slot.position, slot.size))


static func _ensure_label(parent: Node, name: String, font_size: int) -> Label:
	var label := parent.get_node_or_null(NodePath(name)) as Label
	if label == null:
		label = Label.new()
		label.name = name
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(label)
	THEME.style_label(label, false, font_size)
	return label


static func _place(control: Control, rect: Rect2) -> void:
	if control == null:
		return
	var setup_required := not control.is_set_as_top_level()
	var rect_changed := not control.position.is_equal_approx(rect.position) or not control.size.is_equal_approx(rect.size)
	if setup_required:
		control.set_as_top_level(true)
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if control.custom_minimum_size != rect.size:
		control.custom_minimum_size = rect.size
	if rect_changed or setup_required:
		control.position = rect.position
		control.size = rect.size
		control.set_deferred("position", rect.position)
		control.set_deferred("size", rect.size)
		var layer := control.get_canvas_layer_node()
		if layer != null:
			layer.set_meta("native_a5_rect_write_count", int(layer.get_meta("native_a5_rect_write_count", 0)) + 2)
	# These are the original nodes under earlier container siblings. Raising only
	# their native drawing layer prevents later panel backgrounds covering them.
	if control.z_index != 5:
		control.z_index = 5
	if not control.has_meta("native_a5_layout"):
		control.set_meta("native_a5_layout", true)


static func _place_context_tool(controller: Node, name: String, rect: Rect2, interaction: bool) -> void:
	var button := controller.get_node_or_null(GRID + "/" + name) as Button
	if button == null:
		return
	button.visible = (not String(button.get_meta("mission_interaction_type", "")).is_empty()) if interaction else not button.disabled
	if not button.visible:
		return
	if _button_style_dirty(button, false, 12):
		THEME.style_command_button(button)
		button.self_modulate = Color.WHITE
		button.add_theme_font_size_override("font_size", 12)
		_remember_button_style(button, false)
	_place(button, rect)


static func _set_text(label: Label, text: String) -> void:
	if label.text != text:
		label.text = text


static func _keep_transport_and_control_separate(controller: Node) -> void:
	var craft := controller.get_node_or_null("../TacticalUI/MissionDropshipPanel") as Control
	var strategic := controller.get_node_or_null(BASE + "StrategicPanel") as Control
	if strategic == null:
		return
	if craft != null and craft.visible and craft.get_global_rect().intersects(strategic.get_global_rect()):
		var rect := strategic.get_global_rect()
		rect.position = Vector2(craft.position.x - rect.size.x - 16.0, 112.0)
		_place(strategic, rect)
	var log_panel := controller.get_node_or_null("../TacticalUI/TacticalEventLogPanel") as Control
	if log_panel != null and log_panel.get_global_rect().intersects(strategic.get_global_rect()):
		var rect := strategic.get_global_rect()
		rect.position = Vector2(log_panel.get_global_rect().position.x - rect.size.x - 16.0, 104.0)
		_place(strategic, rect)
