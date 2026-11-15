extends RefCounted
## Pure presentation of existing mission Controls. No command, transport or unit state.
## Existing Control instances and their NodePaths/callbacks remain intact.

const THEME := preload("res://scripts/ui/tactical_ui_theme.gd")
const LAYOUT := preload("res://scripts/meta/drop_light_layout_contract.gd")
const ICONS := preload("res://scripts/ui/native_ui_icons.gd")
const TARGET_ICON := preload("res://Assets/curated/kenney/tactical_icons/target_marker.png")
const BASE := "../TacticalUI/BottomDock/BottomMargin/BottomRow/"
const GRID := BASE + "CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid"
const INFO := BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll/FireteamInfoVBox"
const FIRST: PackedStringArray = ["MoveButton", "TakeButton", "HoldButton", "FlankButton", "GoCommandMatrixButton"]
const SECOND: PackedStringArray = ["TargetButton", "ClearTargetButton", "DeleteOrderButton", "SortCommandMatrixButton"]
const RULES: PackedStringArray = ["FireRuleHoldButton", "FireRuleReturnButton", "FireRuleFreeButton", "FireRuleSuppressButton"]
const RULE_LABELS := {"FireRuleHoldButton": "FH", "FireRuleReturnButton": "AF", "FireRuleFreeButton": "FF", "FireRuleSuppressButton": "UN"}
const LABELS := {"MoveButton": "Bewegen", "TakeButton": "Nehmen", "HoldButton": "Halten", "FlankButton": "Flanke", "GoCommandMatrixButton": "Plan\nausführen", "TargetButton": "Ziel", "ClearTargetButton": "Leeren", "DeleteOrderButton": "Löschen", "SortCommandMatrixButton": "Ordnen"}
const ICON_IDS := {"MoveButton": "move", "TakeButton": "take", "HoldButton": "defend", "FlankButton": "flank", "TargetButton": "order_target", "ClearTargetButton": "order_clear", "DeleteOrderButton": "order_delete", "SortCommandMatrixButton": "order_sort", "GoCommandMatrixButton": "order_go"}
const CHARACTER_OVERLAY_Z := 64
const FIRE_CODES: PackedStringArray = ["hold", "return", "free", "suppress"]
const FIRE_NAMES: PackedStringArray = ["Feuer halten", "Antwortfeuer", "Feuer frei", "Unterdrücken"]
const IDENTITY := "../TacticalUI/MissionIdentityPanel"
const IDENTITY_SOURCES := IDENTITY + "/MissionIdentityMargin/MissionIdentityVBox/"
const STRATEGIC := BASE + "StrategicPanel"
const STRATEGIC_SOURCES := STRATEGIC + "/StrategicMargin/StrategicScroll/StrategicVBox/"
const EVACUATION_SOURCE := STRATEGIC_SOURCES + "StrategicActionRow/MissionEvacuationButton"


static func configure(controller: Node, state: Dictionary = {}) -> void:
	# MetaFlow supplies planning state before entering the mission into the
	# SceneTree. The normal ready/layout pass owns the first viewport geometry.
	if controller == null or not controller.is_inside_tree():
		return
	var viewport: Viewport = controller.get_viewport()
	if viewport == null:
		return
	var layer := controller.get_node_or_null("../TacticalUI") as CanvasLayer
	var grid := controller.get_node_or_null(GRID) as GridContainer
	if layer == null or grid == null:
		return
	var viewport_size := Vector2i(viewport.get_visible_rect().size)
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
		if not bool(team_panel.get_meta("native_a5_quiet_frame", false)):
			team_panel.set_meta("native_a5_quiet_frame", true)
			team_panel.queue_redraw()
		_ensure_team_controls(controller, team_panel, layer)
		_layout_selected_team_controls(controller, team_panel, Rect2(team), layout)
	var command_panel := controller.get_node_or_null(BASE + "CommandPanel") as PanelContainer
	if command_panel != null:
		_style_dock_module(command_panel, false)
	var band_root := controller.get_node_or_null("../TacticalUI/BottomDock") as Control
	if band_root != null:
		# Production scenes own a plain Control here, not a PanelContainer.
		# A passive child supplies the complete opaque instrument surface while
		# every existing command and absolute A5 slot stays in its original owner.
		var band_panel := band_root.get_node_or_null("A5InstrumentSurface") as Panel
		if band_panel == null:
			band_panel = Panel.new()
			band_panel.name = "A5InstrumentSurface"
			band_panel.mouse_filter = Control.MOUSE_FILTER_STOP
			band_panel.focus_mode = Control.FOCUS_NONE
			band_panel.theme = THEME.get_theme()
			var style: StyleBoxFlat = THEME.build_flat_stylebox(THEME.COLOR_PANEL, THEME.COLOR_ACCENT.darkened(0.55), 0, 1, Vector4.ZERO).duplicate()
			style.border_width_left = 0
			style.border_width_right = 0
			style.border_width_bottom = 0
			band_panel.add_theme_stylebox_override("panel", style)
			band_root.add_child(band_panel)
			band_root.move_child(band_panel, 0)
		_place(band_panel, Rect2(band))
		band_panel.z_as_relative = false
		band_panel.z_index = 0
		band_root.set_meta("native_r4_continuous_instrument_surface", true)
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
			button.set_meta("native_a5_action_font", int(layout.body_font_size) - 2)
			button.set_meta("native_a5_action_edge", int(layout.action_edge))
			_present_primary_action(button, state)
			button.visible = true
			var action_edge: int = int(layout.action_edge)
			var step: int = action_edge + int(layout.action_gap)
			_place(button, Rect2(Vector2(band.position + Vector2i(int(layout.action_inset) + column * step, int(layout.action_inset) + row * (action_edge + int(layout.action_inset)))), Vector2(action_edge, action_edge)))
			button.set_meta("native_a5_primary_action", true)
		elif RULES.has(name):
			var index := RULES.find(name)
			_present_fire_rule(button, state)
			_place(button, Rect2(Vector2(team.position + Vector2i(8 + index * 58, 94)), Vector2(52, 28)))
		elif bool(button.get_meta("drop_light_command_placeholder", false)):
			var active_context := not button.disabled and not button.text.strip_edges().is_empty() and not button.get_signal_connection_list("pressed").is_empty()
			button.visible = active_context
			if active_context:
				context_buttons.append(button)
	var context_offset := 48 if not context_buttons.is_empty() else 0
	for index in range(context_buttons.size()):
		var button := context_buttons[index]
		_present_context_button(button)
		_place(button, Rect2(maxf(float(layout.target_order.position.x), float(team.end.x + 12)) + index * 128, band.position.y - 44, 120, 36))
	_place_context_tool(controller, "DoorBreachButton", _context_tool_rect(layout, 0), true)
	_place_context_tool(controller, "WaypointEraseButton", _context_tool_rect(layout, 1), false)
	var all_button := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton") as Button
	if all_button != null:
		_place(all_button, Rect2(Vector2(team.position + Vector2i(team.size.x - 64, 8)), Vector2(52, 24)))
	var stance_panel := controller.get_node_or_null(INFO + "/TacticalStancePanel") as Control
	if stance_panel != null:
		stance_panel.clip_contents = false
		var params_rect: Rect2i = layout.team_parameters
		_place(stance_panel, Rect2(Vector2(params_rect.position) + Vector2(8, float(layout.action_inset + 30)), Vector2(336, 28)))
		_refresh_stance_buttons(stance_panel)
	var info_scroll := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamInfoScroll") as ScrollContainer
	if info_scroll != null:
		info_scroll.clip_contents = true
		_place(info_scroll, Rect2(Vector2(team.position + Vector2i(8, 40)), Vector2(team.size.x - 16, team.size.y - 48)))
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
		# A5 carries member identity in the portrait-led team cards on the left.
		# Keep the original NPC controls and their data/character paths available,
		# but do not duplicate the same people as a second horizontal HUD strip.
		members.visible = false
	var mini := controller.get_node_or_null("../TacticalUI/FireteamMiniPanel") as Control
	if mini != null:
		_place(mini, Rect2(layout.fireteam_mini))
		mini.set_meta("native_a5_layout", true)
		var mini_header := mini.get_node_or_null("MiniMargin/MiniVBox/MiniHeaderLabel") as Control
		if mini_header != null:
			mini_header.visible = false
		var mini_margin := mini.get_node_or_null("MiniMargin") as MarginContainer
		if mini_margin != null:
			for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
				mini_margin.add_theme_constant_override(side, 0)
		var mini_cards := mini.get_node_or_null("MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox") as VBoxContainer
		if mini_cards != null:
			mini_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
			mini_cards.alignment = BoxContainer.ALIGNMENT_END
			mini_cards.add_theme_constant_override("separation", 8)
			for card in mini_cards.get_children():
				if card is Control and controller.has_method("_resize_native_a5_fireteam_card"):
					controller.call("_resize_native_a5_fireteam_card", card)
		var mini_scroll := mini.get_node_or_null("MiniMargin/MiniVBox/MiniCardsScroll") as ScrollContainer
		if mini_scroll != null:
			mini_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			mini_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
			mini_scroll.clip_contents = true
		if mini is PanelContainer:
			(mini as PanelContainer).add_theme_stylebox_override("panel", THEME.build_flat_stylebox(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	var log_panel := controller.get_node_or_null("../TacticalUI/TacticalEventLogPanel") as Control
	if log_panel != null:
		var log_rect := Rect2(layout.event_log)
		log_rect.position.y -= context_offset
		_place(log_panel, log_rect)
		log_panel.set_meta("native_a5_layout", true)
		log_panel.clip_contents = true
		log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_style_protocol(controller, layout)
	_refresh_navigation(controller, layout)
	var strategic := controller.get_node_or_null(BASE + "StrategicPanel") as Control
	if strategic != null:
		_layout_player_readouts(controller, viewport_size)
	_refresh_fire_rule_selector(controller, state)
	grid.set_meta("native_a5_geometry_signature", geometry_signature)


static func _geometry_signature(controller: Node, grid: GridContainer, viewport_size: Vector2i) -> String:
	var context: PackedStringArray = []
	for child in grid.get_children():
		if child is Button and _is_active_context_button(child):
			context.append("%s:%s" % [child.name, child.text])
	var craft := controller.get_node_or_null("../TacticalUI/MissionDropshipPanel") as Control
	var transport := str(craft.get_global_rect()) if craft != null and craft.visible else "hidden"
	return "playtest_a5_readable_left_v1|%s|%d|%s|%s" % [viewport_size, grid.get_child_count(), "|".join(context), transport]


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
	_refresh_navigation(controller, layout)
	_style_protocol(controller, layout)
	_place_context_tool(controller, "DoorBreachButton", _context_tool_rect(layout, 0), true)
	_place_context_tool(controller, "WaypointEraseButton", _context_tool_rect(layout, 1), false)
	var stance := controller.get_node_or_null(INFO + "/TacticalStancePanel") as Control
	if stance != null:
		_refresh_stance_buttons(stance)
	_layout_team_readouts(controller, Rect2(layout.selected_fireteam))
	_hide_raw_readouts(controller)
	_refresh_fire_rule_selector(controller, state)


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
	if name == "DeleteOrderButton":
		selected = bool(state.get("delete_active", false))
	elif name == "SortCommandMatrixButton":
		selected = bool(state.get("sort_active", false))
	var font_size: int = int(button.get_meta("native_a5_action_font", 12))
	if _button_style_dirty(button, selected, font_size):
		THEME.style_action_tile(button, selected, name == "GoCommandMatrixButton")
		if name == "GoCommandMatrixButton":
			_style_execute_tile(button)
		button.self_modulate = Color.WHITE
		button.add_theme_font_override("font", THEME.get_heading_font())
		button.add_theme_font_size_override("font_size", font_size)
		_remember_button_style(button, selected)
	if button.text != LABELS[name]:
		button.text = LABELS[name]
	# The native slot owns the final size even after a generic theme refresh.
	# At 1280px the generic 64px minimum otherwise expands the 52px square.
	var edge := float(button.get_meta("native_a5_action_edge", 52))
	var native_size := Vector2(edge, edge)
	if button.custom_minimum_size != native_size:
		button.custom_minimum_size = native_size
	if button.size != native_size:
		button.size = native_size
	if ICON_IDS.has(name):
		var icon: Texture2D = ICONS.get_icon(ICON_IDS[name])
		if button.icon != icon:
			button.icon = icon
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.expand_icon = true
	var icon_width: int = maxi(12, roundi(edge * 0.22)) if name == "GoCommandMatrixButton" else maxi(22, roundi(edge * 0.43))
	if button.get_theme_constant("icon_max_width") != icon_width:
		button.add_theme_constant_override("icon_max_width", icon_width)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.clip_text = false


static func _present_fire_rule(button: Button, state: Dictionary) -> void:
	# Original nodes retain callback, gate, metadata and confirmed toggle state.
	# The compact selector is their player-facing presentation.
	if button.visible:
		button.visible = false
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
	# The legacy frame plus inner margin otherwise requires 56px even with the
	# summary hidden. Keep one 8px frame inset around the 28px button row.
	var margin := stance.get_node_or_null("MarginContainer") as MarginContainer
	if margin != null:
		for side in ["margin_top", "margin_bottom"]:
			if margin.get_theme_constant(side) != 0:
				margin.add_theme_constant_override(side, 0)
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_right", 4)
	var summary := stance.get_node_or_null("MarginContainer/VBoxContainer/SummaryLabel") as Label
	if summary != null:
		summary.visible = false
		stance.tooltip_text = summary.tooltip_text
	var labels := {"Cautious": "Vorsichtig", "Normal": "Normal", "Aggressive": "Offensiv"}
	var height: int = int(stance.get_viewport().get_visible_rect().size.y)
	var font_size: int = 16 if height >= 1260 else (14 if height >= 900 else 13)
	for name in ["Cautious", "Normal", "Aggressive"]:
		var button := stance.get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer/%sButton" % name) as Button
		if button != null:
			if button.text != labels[name]:
				button.text = labels[name]
			button.set_meta("mission_selected_fireteam_stance_player_label", button.text)
			if button.get_theme_font_size("font_size") != font_size:
				button.add_theme_font_size_override("font_size", font_size)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.custom_minimum_size = Vector2(0, 28 if height >= 1260 else (26 if height >= 900 else 24))


static func refresh(controller: Node, view_model: Dictionary) -> void:
	var panel := controller.get_node_or_null("../TacticalUI/A5TargetOrderPanel") as PanelContainer
	if panel == null:
		return
	panel.visible = bool(view_model.get("visible", true))
	var feedback := String(view_model.get("feedback", ""))
	if view_model.has("player_context"):
		refresh_player_readout(controller, Dictionary(view_model.player_context))
	else:
		# Small presenter fixtures can refresh a rule independently of the full VM.
		_set_text(panel.get_node("Contents/Target") as Label, "Ziel gewählt" if bool(view_model.get("target_selected", false)) else "Ziel auswählen")
		_set_text(panel.get_node("Contents/Order") as Label, String(view_model.get("order", "Auftrag: Befehl auswählen")))
		_set_text(panel.get_node("Contents/Feedback") as Label, _player_command_feedback(feedback))
	panel.tooltip_text = "Ziel: %s\n%s\n%s\n\n%s" % [view_model.get("target", "—"), view_model.get("order", ""), feedback, view_model.get("detail", "")]
	var title := controller.get_node_or_null(BASE + "FireteamPanel/A5TeamIdentity") as Label
	if title != null:
		_set_text(title, String(view_model.get("team", "Kein Fireteam ausgewählt")))
	var summary := controller.get_node_or_null(BASE + "FireteamPanel/A5TeamSummary") as Label
	if summary != null:
		_set_text(summary, String(view_model.get("team_summary", "")))
	_refresh_fire_rule_selector(controller, view_model)
	_refresh_details_text(controller)
	_refresh_combined_team_card(controller)


static func _refresh_combined_team_card(controller:Node) -> void:
	var team:=controller.get_node_or_null(BASE+"FireteamPanel") as Control
	if team==null or not team.has_node("A5TeamPortraits"):return
	var id:=String(controller.call("_get_selected_fireteam_id"))
	var source:Node=controller.get_node_or_null("../TacticalUI/FireteamMiniPanel/MiniMargin/MiniVBox/MiniCardsScroll/MiniCardsVBox/FireteamMiniCard_"+id.capitalize()+"/Margin/VBox/FireteamMemberPortraitStrip")
	var row:=team.get_node("A5TeamPortraits") as HBoxContainer
	var sources:Array=source.get_children() if source!=null else []
	while row.get_child_count()>sources.size():row.get_child(-1).free()
	while row.get_child_count()<sources.size():
		var portrait:=TextureRect.new();portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;portrait.mouse_filter=Control.MOUSE_FILTER_STOP;row.add_child(portrait)
	var card_layout:Dictionary=LAYOUT.get_mission_hud_layout(Vector2i(controller.get_viewport().get_visible_rect().size))
	var ph:float=float(card_layout.portrait_height)
	var count:int=sources.size()
	var edge:float=floorf((float(card_layout.card_width)-20.0-4.0*(count-1))/maxf(1.0,float(count)))
	for i in sources.size():
		var portrait:=row.get_child(i) as TextureRect
		var original:=sources[i] as TextureRect
		portrait.texture=original.texture;portrait.modulate=original.modulate;portrait.tooltip_text=original.tooltip_text;portrait.custom_minimum_size=Vector2(minf(edge,ph),ph)
		var unit_id:=String(original.get_meta("mission_member_unit_id",""))
		var callback:=Callable(controller,"_on_native_member_portrait_gui_input").bind(unit_id,id)
		var route_key:=id+":"+unit_id
		if String(portrait.get_meta("combined_member_route",""))!=route_key:
			for connection in portrait.get_signal_connection_list("gui_input"):portrait.gui_input.disconnect(connection.callable)
			portrait.gui_input.connect(callback)
			portrait.set_meta("combined_member_route",route_key)
	var boarding:Dictionary=controller.call("get_selected_team_boarding_snapshot")
	var board:=team.get_node("A5TeamBoard") as Button
	board.disabled=not bool(boarding.can_board);board.tooltip_text=String(boarding.message)
	var status:=team.get_node("A5BoardStatus") as Label
	_set_text(status,String(boarding.message))


static func build_player_readout(context: Dictionary) -> Dictionary:
	# This projection consumes confirmed snapshots only. It never submits a
	# command or promotes a request, selected control or fallback cue to truth.
	var objective: Dictionary = Dictionary(context.get("objective", {}))
	var mission_text := "Einsatzziel nicht verfügbar"
	var mission_heading := "EINSATZ"
	var local_team := String(context.get("local_team_id", "")).strip_edges().to_lower()
	if bool(objective.get("available", false)):
		mission_heading = "EINSATZZIEL"
		var owner := String(objective.get("owning_team_id", "")).strip_edges().to_lower()
		var progress := clampf(float(objective.get("capture_progress", 0.0)), 0.0, 1.0)
		mission_text = "Einsatzziel sichern"
		if bool(objective.get("contested", false)):
			mission_text = "Einsatzziel umkämpft"
		elif not owner.is_empty() and progress >= 1.0:
			mission_text = "Einsatzziel besetzt" if local_team.is_empty() else ("Einsatzziel gesichert" if owner == local_team else "Einsatzziel gegnerisch besetzt")
		elif progress > 0.0 and not local_team.is_empty() and String(objective.get("capturing_team_id", "")).to_lower() == local_team:
			mission_text = "Einsatzziel sichern · %d %%" % int(floor(progress * 100.0))
	# The old CUE WAIT fallback exists even without a route. Only an explicitly
	# active route may replace the objective with its actual next runtime step.
	if bool(context.get("route_active", false)):
		var cue: Dictionary = Dictionary(context.get("route_cue", {}))
		var route_text := _player_route_step(cue)
		if not route_text.is_empty():
			mission_heading = "EINSATZROUTE"
			mission_text = route_text
	var scenario_id:=String(context.get("singleplayer_scenario_id",""))
	var confirmed: Dictionary=context.get("confirmed_interactions",{})
	if scenario_id=="satellite_recovery":
		mission_heading="SATELLITENBERGUNG"
		mission_text="Satellitendaten sichern"
		if bool(Dictionary(confirmed.get("satellite_data",{})).get("complete",false)): mission_text="Daten gesichert · zum Schiff zurückkehren"
		if bool(Dictionary(confirmed.get("ship_return",{})).get("complete",false)): mission_text="Rückkehr bestätigt · Einsteigen und abheben"
	elif scenario_id=="trade_outpost_visit":
		mission_heading="HANDELSBESUCH"
		mission_text="Händler aufsuchen"
		if bool(Dictionary(confirmed.get("trade_service",{})).get("complete",false)): mission_text="Handel freigeschaltet · Versorgung / Rückflug"
	var cards: Array = Array(context.get("transport_cards", []))
	var transport_text := "Kein Dropship im Einsatz"
	if cards.size() > 1:
		transport_text = "%d Dropships im Einsatz" % cards.size()
	elif cards.size() == 1:
		var card: Dictionary = Dictionary(cards[0])
		var transport_state := _player_transport_state(String(card.get("state", "")))
		transport_text = "Dropship · %s" % transport_state
		if String(card.get("state", "")) in ["to_mission", "to_fob", "to_homebase"] and float(card.get("eta_seconds", 0)) > 0.0:
			transport_text += " · %d s" % int(ceil(float(card.eta_seconds)))
	var remaining := float(context.get("remaining_seconds", -1.0))
	if remaining >= 0.0:
		var seconds := int(ceil(remaining))
		transport_text += "\nZeitlimit %02d:%02d" % [int(seconds / 60), seconds % 60]
	var order := "Auftrag: Befehl auswählen"
	var selected := int(context.get("selection_count", 0))
	var executing := clampi(int(context.get("executing_count", 0)), 0, maxi(selected, 0))
	var planned := int(context.get("planned_count", 0))
	var focused := String(context.get("focused_order_label", "")).strip_edges()
	var command_labels := {"MOVE": "Bewegen", "TAKE": "Nehmen", "DEFEND": "Halten", "FLANK": "Flankieren", "ENGAGE": "Ziel bekämpfen"}
	focused = String(command_labels.get(focused.to_upper(), focused))
	if selected <= 0:
		order = "Auftrag: Fireteam auswählen"
	elif not focused.is_empty():
		order = "Auftrag: %s" % focused
	elif executing > 0:
		order = "Auftrag: Wird ausgeführt" if executing == selected else "Auftrag: %d von %d Teams aktiv" % [executing, selected]
		if executing == selected:
			var active_labels: Array = Array(context.get("active_order_labels", []))
			var labels_complete: bool = active_labels.size() == executing
			var active_names: Dictionary = {}
			for label_variant in active_labels:
				var active_name := String(command_labels.get(String(label_variant).strip_edges().to_upper(), ""))
				if active_name.is_empty():
					labels_complete = false
				else:
					active_names[active_name] = true
			if labels_complete and active_names.size() == 1:
				order = "Auftrag: %s" % String(active_names.keys()[0])
			elif labels_complete and active_names.size() > 1:
				order = "Auftrag: Verschiedene Befehle"
	elif planned > 0:
		order = "Auftrag: %d %s geplant" % [planned, "Befehl" if planned == 1 else "Befehle"]
	var feedback := _player_command_feedback(String(context.get("feedback", "")))
	if feedback.is_empty() and bool(context.get("target_armed", false)):
		feedback = "Ziel auf Karte wählen"
	elif feedback.is_empty() and executing > 0:
		# A focused future order is still only a selection, not the running one.
		feedback = "Ausführung läuft" if focused.is_empty() else "Team führt Befehle aus"
	elif feedback.is_empty() and bool(context.get("can_execute", false)) and planned > 0:
		feedback = "Mit Plan ausführen starten"
	return {"read_only": true, "ui_sets_gameplay_truth": false, "mission_heading": mission_heading, "mission_text": mission_text, "transport_heading": "TRANSPORT / ZEIT" if remaining >= 0.0 else "TRANSPORT", "transport_text": transport_text, "target": "Ziel gewählt" if bool(context.get("target_selected", false)) else "Ziel auswählen", "order": order, "feedback": feedback}


static func _player_route_step(cue: Dictionary) -> String:
	var token := String(cue.get("next_token", "")).to_upper()
	var labels := {"AA": "Luftabwehr ausschalten", "DOOR": "Tür öffnen", "COM": "Computer halten", "CARGO": "Fracht-Landezone sichern", "DONE": "Einsatzroute abgeschlossen"}
	if not labels.has(token):
		return ""
	var label := String(labels[token])
	match String(cue.get("runtime_status", "")):
		"blocked": return "%s · blockiert" % label
		"in_progress": return "%s · läuft" % label
		"out_of_range": return "%s · näher heran" % label
		"interrupted": return "%s · unterbrochen" % label
		"departing": return "Fracht fliegt ab"
		"departed": return "Fracht abgeflogen"
		"complete": return "Einsatzroute abgeschlossen" if token == "DONE" else "%s · erledigt" % label
	return label


static func _player_transport_state(state: String) -> String:
	match state.strip_edges().to_lower():
		"waiting": return "Wartet"
		"to_mission", "inbound": return "Im Anflug"
		"on_mission", "landed": return "Vor Ort"
		"unloading": return "Ausstieg läuft"
		"to_fob": return "Rückflug zur FOB"
		"to_homebase": return "Rückflug zur Heimatbasis"
		"outbound": return "Verlässt das Einsatzgebiet"
		"complete": return "Absetzen abgeschlossen"
		"recovering": return "Wird geborgen"
		"unavailable": return "Nicht verfügbar"
		"destroyed", "lost": return "Verloren"
	return "Status nicht verfügbar"


static func _player_command_feedback(raw: String) -> String:
	var code := raw.strip_edges().to_upper()
	if code.contains("TIMEOUT"):
		return "Keine Bestätigung · Details"
	if code.contains("BLOCKED") or code.contains("BLOCKIERT") or code.contains("REJECT") or code.contains("FAILED"):
		return "Aktion blockiert · Details"
	if code.contains("REQUEST") or code.contains("WARTE AUF HOST") or code.contains("-> HOST") or code.contains("HOST PENDING"):
		return "Anfrage wird geprüft"
	match code:
		"PREVIEW MODE": return "Vorschau · Einsatz zuerst starten"
		"OBSERVER MODE": return "Beobachten · keine Befehlsfreigabe"
		"NO TILE UNDER CURSOR", "SELECT TILE FIRST": return "Ziel auf Karte wählen"
		"NO ORDERS TO EXECUTE", "NO ORDERS TO SEND": return "Zuerst einen Befehl planen"
		"NO ORDER SELECTED": return "Befehl zum Löschen auswählen"
		"ALTE PLANUNGSDATEN": return "Plan konnte nicht geladen werden"
	if code.begins_with("WAIT FOR INSERTION"):
		return "Fireteam muss zuerst aussteigen"
	return ""


static func refresh_player_readout(controller: Node, context: Dictionary) -> void:
	var model := build_player_readout(context)
	for spec in [[IDENTITY + "/A5MissionHeading", "mission_heading"], [IDENTITY + "/A5MissionState", "mission_text"], [STRATEGIC + "/A5TransportHeading", "transport_heading"], [STRATEGIC + "/A5TransportState", "transport_text"], ["../TacticalUI/A5TargetOrderPanel/Contents/Target", "target"], ["../TacticalUI/A5TargetOrderPanel/Contents/Order", "order"], ["../TacticalUI/A5TargetOrderPanel/Contents/Feedback", "feedback"]]:
		var label := controller.get_node_or_null(String(spec[0])) as Label
		if label != null:
			_set_text(label, String(model.get(String(spec[1]), "")))
			if String(spec[1]) in ["mission_text", "transport_text"]:
				label.tooltip_text = label.text
	# The production light refresh runs the legacy stance writer first. Restore
	# only these three known controls; no configure(), placement or tree scan.
	refresh_selected_stance(controller)
	_hide_raw_readouts(controller)
	_refresh_details_text(controller)


static func refresh_selected_stance(controller: Node) -> void:
	# This bounded restore is also called after the owner's direct button-state
	# refresh, which can run after the ordinary readout in a live mission.
	var stance := controller.get_node_or_null(INFO + "/TacticalStancePanel") as Control
	if stance != null and bool(stance.get_meta("native_a5_layout", false)):
		_refresh_stance_buttons(stance)


static func _layout_player_readouts(controller: Node, viewport_size: Vector2i) -> void:
	var layout: Dictionary = LAYOUT.get_mission_hud_layout(viewport_size)
	var font_size: int = int(layout.body_font_size)
	for spec in [[IDENTITY, Rect2(layout.mission_identity), "A5MissionHeading", "A5MissionState"], [STRATEGIC, Rect2(layout.mission_control), "A5TransportHeading", "A5TransportState"]]:
		var panel := controller.get_node_or_null(String(spec[0])) as Control
		if panel == null:
			continue
		var rect: Rect2 = spec[1]
		_place(panel, rect)
		panel.clip_contents = false
		var heading := _ensure_label(panel, String(spec[2]), font_size + 2)
		THEME.style_section_heading(heading, font_size + 2)
		var body := _ensure_label(panel, String(spec[3]), font_size)
		for label in [heading, body]:
			label.clip_text = true
			label.max_lines_visible = 1 if rect.size.y < 80 else 2
		body.tooltip_text = body.text
		body.mouse_filter = Control.MOUSE_FILTER_PASS
		_place(heading, Rect2(rect.position + Vector2(52, 6), Vector2(rect.size.x - 148, font_size + 10)))
		_place(body, Rect2(rect.position + Vector2(52, font_size + 18), Vector2(rect.size.x - 62, rect.size.y - (font_size + 18) - 4)))
		var icon_id := "dropship" if String(spec[0]) == STRATEGIC else "target"
		var icon := _ensure_readout_icon(panel, icon_id)
		_place(icon, Rect2(rect.position + Vector2(10, (rect.size.y - 30) / 2), Vector2(26, 30)))
		var card := panel as PanelContainer
		if card != null:
			THEME.style_card(card)
			card.set_meta("native_a5_quiet_frame", true)
		if String(spec[0]) == IDENTITY:
			var details := panel.get_node_or_null("A5ReadoutDetailsButton") as Button
			if details == null:
				details = Button.new()
				details.name = "A5ReadoutDetailsButton"
				details.text = "Details"
				details.tooltip_text = "Vollständige Einsatz-, Transport- und Befehlsmeldungen sowie Evakuieren anzeigen"
				details.pressed.connect(Callable(controller, "_open_native_team_details"))
				panel.add_child(details)
				THEME.style_command_button(details)
				details.add_theme_font_size_override("font_size", font_size - 1)
			_place(details, Rect2(rect.position + Vector2(rect.size.x - 86, 4), Vector2(76, 24)))
	_hide_raw_readouts(controller)


static func _hide_raw_readouts(controller: Node) -> void:
	var strategic := controller.get_node_or_null(STRATEGIC) as Control
	if strategic != null:
		# The compact Cutlass card owns the visible transport projection. Keep
		# the old source tree intact for the explicit diagnostic detail view.
		strategic.visible = false
	# Direct known labels only: owners keep writing their full source strings.
	for path in [IDENTITY_SOURCES + "MissionIdentityHeaderLabel", IDENTITY_SOURCES + "MissionIdentityBodyLabel", STRATEGIC_SOURCES + "StrategicHeaderLabel", STRATEGIC_SOURCES + "StrategicStatusLabel", STRATEGIC_SOURCES + "MissionTeamChipLabel"]:
		var label := controller.get_node_or_null(path) as Label
		if label != null and label.visible:
			label.visible = false
		if label != null:
			label.set_meta("native_a5_source_readout_hidden", true)


static func _layout_selected_team_controls(controller: Node, team: PanelContainer, rect: Rect2, metrics: Dictionary) -> void:
	var font_size: int = int(metrics.body_font_size)
	var params := Rect2(metrics.team_parameters)
	var inset: float = float(metrics.action_inset)
	var identity := _ensure_label(team, "A5TeamIdentity", font_size + 2)
	THEME.style_section_heading(identity, font_size + 2)
	identity.max_lines_visible = 1
	identity.add_theme_color_override("font_color", THEME.COLOR_BORDER_SELECTED)
	_place(identity, Rect2(rect.position + Vector2(10, 8), Vector2(rect.size.x - 164, 26)))
	var summary := _ensure_label(team, "A5TeamSummary", font_size - 1)
	summary.max_lines_visible = 1
	_place(summary, Rect2(params.position + Vector2(8, inset), Vector2(336, 24)))
	var fire_heading := _ensure_label(team, "A5FireRuleHeading", font_size - 1)
	fire_heading.text = "Feuerregel"
	fire_heading.max_lines_visible = 1
	fire_heading.clip_text = true
	fire_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fire_heading.visible = true
	_place(fire_heading, Rect2(params.position + Vector2(8, inset + 64), Vector2(88, 28)))
	fire_heading.z_index = 12
	var selector := team.get_node("A5FireRuleSelector") as OptionButton
	selector.add_theme_font_size_override("font_size", font_size)
	_place(selector, Rect2(params.position + Vector2(100, inset + 64), Vector2(244, 28)))
	var details := team.get_node("A5DetailsButton") as Button
	details.add_theme_font_size_override("font_size", font_size - 1)
	_place(details, Rect2(rect.position + Vector2(rect.size.x - 144, 8), Vector2(76, 24)))
	var all := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/AllFireteamsButton") as Button
	if all != null:
		all.add_theme_font_size_override("font_size", font_size - 1)
	var portraits:=team.get_node("A5TeamPortraits") as HBoxContainer
	_place(portraits,Rect2(rect.position+Vector2(10,36),Vector2(rect.size.x-20,metrics.portrait_height)))
	var board:=team.get_node("A5TeamBoard") as Button
	board.add_theme_font_size_override("font_size",font_size)
	_place(board,Rect2(params.position+Vector2(360,inset+30),Vector2(104,28)))
	var status:=team.get_node("A5BoardStatus") as Label
	_place(status,Rect2(params.position+Vector2(360,inset+62),Vector2(160,36)))
	team.mouse_filter = Control.MOUSE_FILTER_STOP
	THEME.style_card(team, true)
	team.set_meta("native_a5_parameter_group_left", true)
	team.set_meta("native_a5_parameter_group_band", true)


static func _refresh_navigation(controller: Node, metrics: Dictionary) -> void:
	var panel := controller.get_node_or_null("../TacticalUI/TopNavPanel") as Control
	if panel == null:
		return
	var route: String = String(controller.call("_get_mission_drop_payload_source_for_craft")) if controller.has_method("_get_mission_drop_payload_source_for_craft") else ""
	var font_size: int = int(metrics.body_font_size)
	var row := panel.get_node_or_null("NavMargin/NavRow") as HBoxContainer
	if row == null:
		return
	for name in ["HomebaseNavButton", "FOBNavButton", "MissionNavButton"]:
		var button := row.get_node_or_null(NodePath(name)) as Button
		if button == null:
			continue
		if name == "FOBNavButton":
			button.visible = route != "homebase_direct"
			button.set_meta("native_a5_route_presentation_only", true)
		button.add_theme_font_size_override("font_size", font_size)
		button.custom_minimum_size = Vector2(100 if font_size < 18 else 128, 36 if font_size < 18 else 44)
	var timer := row.get_node_or_null("MissionTimerLabel") as Label
	if timer != null:
		timer.add_theme_font_size_override("font_size", font_size)
		timer.custom_minimum_size.x = 62 if font_size < 18 else 80
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.clip_contents = false


static func _style_protocol(controller: Node, metrics: Dictionary) -> void:
	var panel := controller.get_node_or_null("../TacticalUI/TacticalEventLogPanel") as Control
	if panel == null:
		return
	var font_size: int = int(metrics.body_font_size)
	for name in ["EventLogHeaderLabel", "EventLogCountLabel", "EventLogSelectedFilterButton"]:
		var control := panel.get_node_or_null("EventLogMargin/EventLogVBox/EventLogHeader/" + name) as Control
		if control != null and control.get_theme_font_size("font_size") != font_size - 1:
			control.add_theme_font_size_override("font_size", font_size - 1)
	var entries := panel.get_node_or_null("EventLogMargin/EventLogVBox/EventLogScroll/EventLogEntries")
	if entries == null:
		return
	for row in entries.get_children():
		for name in ["EventTextLabel", "TimeLabel"]:
			var label := row.get_node_or_null(NodePath(name)) as Label
			if label != null:
				if label.get_theme_font_size("font_size") != font_size - 1:
					label.add_theme_font_size_override("font_size", font_size - 1)
				if name == "TimeLabel":
					label.custom_minimum_size.x = 56 if font_size >= 16 else 46


static func _ensure_team_controls(controller: Node, team: PanelContainer, layer: CanvasLayer) -> void:
	if team.get_node_or_null("A5TeamPortraits") == null:
		var portraits:=HBoxContainer.new();portraits.name="A5TeamPortraits";portraits.add_theme_constant_override("separation",4);team.add_child(portraits)
		var board:=Button.new();board.name="A5TeamBoard";board.text="Aufsitzen";board.pressed.connect(Callable(controller,"request_selected_team_boarding"));team.add_child(board);THEME.style_command_button(board)
		var status:=Label.new();status.name="A5BoardStatus";status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",13);team.add_child(status)
	if team.get_node_or_null("A5FireRuleSelector") == null:
		var selector := OptionButton.new()
		selector.name = "A5FireRuleSelector"
		selector.fit_to_longest_item = false
		selector.clip_text = true
		selector.focus_mode = Control.FOCUS_ALL
		selector.theme = THEME.get_theme()
		for index in range(FIRE_CODES.size()):
			selector.add_item(FIRE_NAMES[index], index)
			selector.set_item_metadata(index, FIRE_CODES[index])
		selector.item_selected.connect(Callable(controller, "_on_native_fire_rule_selected"))
		selector.set_meta("ui_sets_gameplay_truth", false)
		team.add_child(selector)
		THEME.style_command_button(selector)
		selector.add_theme_font_size_override("font_size", 14)
	if team.get_node_or_null("A5DetailsButton") == null:
		var button := Button.new()
		button.name = "A5DetailsButton"
		button.text = "Details"
		button.tooltip_text = "Teamzustand, Befehlsdetails, Evakuieren und Tastenkürzel anzeigen"
		button.pressed.connect(Callable(controller, "_open_native_team_details"))
		team.add_child(button)
		THEME.style_command_button(button)
		button.add_theme_font_size_override("font_size", 12)
	if layer.get_node_or_null("A5TeamDetailsPopup") == null:
		var popup := PopupPanel.new()
		popup.name = "A5TeamDetailsPopup"
		popup.theme = THEME.get_theme()
		popup.min_size = Vector2i(360, 240)
		popup.exclusive = true
		popup.set_meta("ui_sets_gameplay_truth", false)
		layer.add_child(popup)
		var margin := MarginContainer.new()
		margin.name = "Margin"
		for side in ["left", "top", "right", "bottom"]:
			margin.add_theme_constant_override("margin_" + side, 12)
		popup.add_child(margin)
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		var box := VBoxContainer.new()
		box.name = "Box"
		box.add_theme_constant_override("separation", 10)
		margin.add_child(box)
		var header := HBoxContainer.new()
		box.add_child(header)
		var heading := Label.new()
		heading.text = "Einsatz-, Team- und Befehlsdetails"
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(heading)
		var close := Button.new()
		close.name = "Close"
		close.text = "Schließen"
		close.pressed.connect(Callable(popup, "hide"))
		header.add_child(close)
		var scroll := ScrollContainer.new()
		scroll.name = "Scroll"
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(scroll)
		var text := Label.new()
		text.name = "Text"
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		THEME.style_label(text, false, 14)
		scroll.add_child(text)
		var evacuation := Button.new()
		evacuation.name = "A5EvacuationButton"
		evacuation.text = "Evakuieren · Einsatz abbrechen"
		evacuation.disabled = true
		evacuation.custom_minimum_size.y = 32
		evacuation.set_meta("ui_sets_gameplay_truth", false)
		evacuation.pressed.connect(_request_existing_evacuation.bind(controller))
		box.add_child(evacuation)
		THEME.style_command_button(evacuation)


static func _refresh_fire_rule_selector(controller: Node, state: Dictionary) -> void:
	var selector := controller.get_node_or_null(BASE + "FireteamPanel/A5FireRuleSelector") as OptionButton
	if selector == null:
		return
	var menu := selector.get_popup()
	var any_enabled := false
	for index in range(RULES.size()):
		var original := controller.get_node_or_null(GRID + "/" + RULES[index]) as Button
		var disabled := original == null or original.disabled
		if selector.is_item_disabled(index) != disabled:
			selector.set_item_disabled(index, disabled)
		any_enabled = any_enabled or not disabled
		if original != null and menu.get_item_tooltip(index) != original.tooltip_text:
			menu.set_item_tooltip(index, original.tooltip_text)
	selector.disabled = not bool(state.get("fire_rule_enabled", false)) or not any_enabled
	var consensus := String(state.get("fire_rule", ""))
	var index := FIRE_CODES.find(consensus)
	if selector.selected != index:
		selector.select(index)
	if index < 0:
		var placeholder := "Gemischte Feuerregeln" if consensus == "mixed" else "Fireteam auswählen"
		if selector.text != placeholder:
			selector.text = placeholder
	else:
		selector.set_meta("help_id", "mission.rule.fire_rule_" + consensus)
	selector.tooltip_text = "Bestätigte Feuerregel: %s\n%s" % [FIRE_NAMES[index] if index >= 0 else selector.text, menu.get_item_tooltip(index) if index >= 0 else "Wähle eine gemeinsame Regel für die ausgewählten Fireteams."]
	var heading := controller.get_node_or_null(BASE + "FireteamPanel/A5FireRuleHeading") as Label
	if heading != null:
		var feedback := String(state.get("feedback", ""))
		var status := "Feuerregel"
		if feedback.begins_with("FIRE "):
			if feedback.contains(" REQUEST"):
				status = "Angefragt"
			elif feedback.contains("REJECT"):
				status = "Abgelehnt"
			elif feedback.contains("TIMEOUT"):
				status = "Zeitablauf"
		_set_text(heading, status)
		heading.tooltip_text = "Feuerregel · Änderung angefragt" if status == "Angefragt" else feedback


static func _refresh_details_text(controller: Node) -> void:
	var popup := controller.get_node_or_null("../TacticalUI/A5TeamDetailsPopup") as PopupPanel
	if popup == null or not popup.visible:
		return
	_refresh_evacuation_action(controller, popup)
	var parts: PackedStringArray = []
	for path in [IDENTITY_SOURCES + "MissionIdentityHeaderLabel", IDENTITY_SOURCES + "MissionIdentityBodyLabel", STRATEGIC_SOURCES + "StrategicHeaderLabel", STRATEGIC_SOURCES + "MissionTeamChipLabel", STRATEGIC_SOURCES + "StrategicStatusLabel", BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel", INFO + "/CommandFeedbackLabel", INFO + "/HotkeyLegendLabel"]:
		var source := controller.get_node_or_null(path) as Label
		if source != null and not source.text.strip_edges().is_empty():
			parts.append(source.text)
			# The legacy 1280 presenter caps only its visible copy. Preserve its
			# complete source and the detailed tooltips as well as that copy.
			var full := String(source.get_meta("mission_control_1280_full_status_text", ""))
			if not full.is_empty() and full != source.text:
				parts.append(full)
			if not source.tooltip_text.is_empty() and source.tooltip_text != source.text and source.tooltip_text != full:
				parts.append(source.tooltip_text)
	_set_text(popup.get_node("Margin/Box/Scroll/Text") as Label, "\n\n".join(parts))


static func _refresh_evacuation_action(controller: Node, popup: PopupPanel) -> void:
	# The ordinary craft-controls cache does not track moving ground teams.
	# Ask the existing UI owner to refresh its gate while details are visible;
	# eligibility and the eventual result remain in their original owners.
	controller.call("_refresh_mission_evacuation_button")
	var source := controller.get_node_or_null(EVACUATION_SOURCE) as Button
	var action := popup.get_node("Margin/Box/A5EvacuationButton") as Button
	action.disabled = source == null or source.disabled or not source.visible
	action.tooltip_text = source.tooltip_text if source != null else "Evakuierung für diesen Einsatz nicht verfügbar."


static func _request_existing_evacuation(controller: Node) -> void:
	var popup := controller.get_node_or_null("../TacticalUI/A5TeamDetailsPopup") as PopupPanel
	if popup == null or not popup.visible:
		return
	_refresh_evacuation_action(controller, popup)
	var action := popup.get_node("Margin/Box/A5EvacuationButton") as Button
	if not action.is_visible_in_tree() or action.disabled:
		return
	var source := controller.get_node_or_null(EVACUATION_SOURCE) as Button
	if source != null:
		source.pressed.emit()


static func _ensure_target_panel(layer: CanvasLayer) -> PanelContainer:
	var panel := layer.get_node_or_null("A5TargetOrderPanel") as PanelContainer
	if panel != null:
		return panel
	panel = PanelContainer.new()
	panel.name = "A5TargetOrderPanel"
	panel.theme = THEME.get_theme()
	_style_dock_module(panel, true)
	panel.set_meta("ui_sets_gameplay_truth", false)
	layer.add_child(panel)
	var contents := VBoxContainer.new()
	contents.name = "Contents"
	contents.add_theme_constant_override("separation", 6)
	panel.add_child(contents)
	var heading := _ensure_label(contents, "Heading", 16)
	THEME.style_section_heading(heading, 16)
	heading.text = "ZIEL / AUFTRAG"
	_ensure_label(contents, "Target", 14)
	_ensure_label(contents, "Order", 13).max_lines_visible = 2
	_ensure_label(contents, "Feedback", 12).max_lines_visible = 2
	return panel


static func _layout_target_labels(panel: PanelContainer, rect: Rect2) -> void:
	var contents := panel.get_node("Contents") as Control
	contents.clip_contents = false
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var body_font: int = 18 if rect.size.y >= 185 else (16 if rect.size.y >= 150 else 14)
	var slots := {"Heading": Rect2(12, 6, rect.size.x - 24, rect.size.y * 0.19), "Target": Rect2(12, rect.size.y * 0.23, rect.size.x - 24, rect.size.y * 0.20), "Order": Rect2(12, rect.size.y * 0.46, rect.size.x - 24, rect.size.y * 0.22), "Feedback": Rect2(12, rect.size.y * 0.72, rect.size.x - 24, rect.size.y * 0.23)}
	for name in slots:
		var label := contents.get_node(NodePath(name)) as Label
		var slot: Rect2 = slots[name]
		_place(label, Rect2(rect.position + slot.position, slot.size))
		label.max_lines_visible = 1 if name in ["Heading", "Feedback"] else 2
		THEME.style_label(label, false, body_font + (2 if name == "Heading" else 0))
		label.clip_text = true


static func _style_dock_module(panel: PanelContainer, divider: bool) -> void:
	# One continuous instrument surface; separators group the existing modules
	# without drawing three unrelated rounded dialog frames over the band.
	var key := "native_r4_dock_divider" if divider else "native_r4_dock_clear"
	if not panel.has_meta(key):
		var style: StyleBoxFlat = THEME.build_flat_stylebox(Color.TRANSPARENT, THEME.COLOR_BORDER, 0, 0, Vector4.ZERO).duplicate()
		style.border_width_left = 1 if divider else 0
		panel.set_meta(key, style)
	panel.add_theme_stylebox_override("panel", panel.get_meta(key))


static func _ensure_readout_icon(panel: Control, icon_id: String) -> TextureRect:
	var icon := panel.get_node_or_null("A5ReadoutIcon") as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = "A5ReadoutIcon"
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = TARGET_ICON if icon_id == "target" else ICONS.get_icon(icon_id)
		icon.modulate = THEME.COLOR_ACCENT if icon_id == "target" else Color.WHITE
		icon.set_meta("native_r4_decorative_readout_icon", true)
		panel.add_child(icon)
	return icon


static func _style_execute_tile(button: Button) -> void:
	# The condensed native face keeps the complete two-line label inside the
	# compact square. Cached styles leave shared boxes and other buttons intact.
	button.icon = null
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var base := button.get_theme_stylebox(state) as StyleBoxFlat
		button.add_theme_stylebox_override(state, THEME.build_flat_stylebox(base.bg_color, base.border_color, base.corner_radius_top_left, base.border_width_left, Vector4(2, 3, 2, 3)))


static func _layout_team_readouts(controller: Node, _rect: Rect2) -> void:
	var members := controller.get_node_or_null(BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamBodyRow/FireteamCardsScroll") as Control
	if members != null:
		members.visible = false
	# The source nodes remain owned and updated by their existing presenters.
	# Their complete text is available in the explicit details popup.
	for path in [BASE + "FireteamPanel/FireteamMargin/FireteamVBox/FireteamHeaderRow/FireteamStatusLabel", INFO + "/CommandFeedbackLabel", INFO + "/HotkeyLegendLabel"]:
		var label := controller.get_node_or_null(NodePath(path)) as Label
		if label == null:
			continue
		label.visible = false
		label.set_meta("native_a5_source_readout_hidden", true)
		if not label.has_meta("native_a5_layout"):
			label.set_meta("native_a5_layout", true)


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


static func _context_tool_rect(layout: Dictionary, index: int) -> Rect2:
	# Context editing has a real slot after the team parameters, so pending,
	# rejected and timed-out command feedback stays visible in the target block.
	var team: Rect2i = layout.selected_fireteam
	return Rect2(team.end.x + 8, team.position.y + 8 + index * 36, 176, 28)


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
