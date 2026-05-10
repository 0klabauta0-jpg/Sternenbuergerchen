class_name DebriefTestScreen
extends Control

const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const BACKGROUND_ID: String = "debrief_desert_explosion_base"

signal return_to_fob_requested()
signal return_to_homebase_requested()

var _mission_result: Dictionary = {}


func _ready() -> void:
	_apply_background_texture()
	var to_fob_button: Button = get_node("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton")
	var to_homebase_button: Button = get_node("Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton")
	if not to_fob_button.pressed.is_connected(_on_return_to_fob_pressed):
		to_fob_button.pressed.connect(_on_return_to_fob_pressed)
	if not to_homebase_button.pressed.is_connected(_on_return_to_homebase_pressed):
		to_homebase_button.pressed.connect(_on_return_to_homebase_pressed)

	_apply_readability_style()
	_render_result()
	_apply_contextual_help_ids()


func set_mission_result(mission_result: Dictionary) -> void:
	_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_render_result()


func get_mission_result() -> Dictionary:
	return _mission_result.duplicate(true)


func get_background_catalog_snapshot() -> Dictionary:
	var entry: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", BACKGROUND_ID))
	var background := get_node_or_null("Background") as TextureRect
	var shade := get_node_or_null("BackgroundShade") as ColorRect
	return {
		"background_id": BACKGROUND_ID,
		"path": String(entry.get("res_path", "")),
		"entry": entry,
		"uses_catalog": not entry.is_empty(),
		"has_texture": background != null and background.texture != null,
		"stretch_mode": int(background.stretch_mode) if background != null else -1,
		"shade_alpha": shade.color.a if shade != null else 0.0,
		"visual_only": true,
	}


func _render_result() -> void:
	var result_label: Label = get_node("Panel/Margin/VBox/ResultLabel")
	var team_state_label: Label = get_node("Panel/Margin/VBox/TeamStateLabel")
	var air_asset_label: Label = _ensure_air_asset_events_label()
	var character_events_label: Label = _ensure_character_events_label()
	var personnel_events_label: Label = _ensure_personnel_events_label()
	_apply_help_id(character_events_label, "debrief.character_updates")
	_apply_help_id(air_asset_label, "fob.flightdeck")

	if _mission_result.is_empty():
		result_label.text = "Mission result: pending"
		team_state_label.text = "Returned team state: unavailable"
		air_asset_label.text = "Air asset: pending"
		character_events_label.text = "Character updates: pending"
		personnel_events_label.text = "Personnel updates: pending"
		_apply_readability_style()
		return

	var winner_team_id: String = String(_mission_result.get("winning_team_id", ""))
	var result: String = String(_mission_result.get("result", "ended"))
	var mission_outcome: String = String(_mission_result.get("mission_outcome", "ended"))
	var win_condition_type: String = String(_mission_result.get("win_condition_type", ""))
	var duration_seconds: float = float(_mission_result.get("duration_seconds", 0.0))
	var objective_captured: bool = bool(_mission_result.get("objective_captured", false))

	var winner_text: String = winner_team_id
	if winner_text.is_empty():
		winner_text = "unknown"

	result_label.text = "Mission %s\nResult: %s\nWinner: %s\nCondition: %s\nDuration: %.1fs\nObjective captured: %s" % [
		mission_outcome,
		result.to_upper(),
		winner_text,
		win_condition_type,
		duration_seconds,
		"yes" if objective_captured else "no",
	]

	var team_state_lines: PackedStringArray = []
	for member_state in _mission_result.get("team_states", []):
		var display_name: String = String(member_state.get("display_name", member_state.get("unit_id", "")))
		var vital_state: String = String(member_state.get("vital_state", "unknown"))
		var health_points: int = int(member_state.get("health_points", -1))
		team_state_lines.append("%s: %s (%d HP)" % [display_name, vital_state, health_points])

	if team_state_lines.is_empty():
		team_state_label.text = "Returned team state: unavailable"
	else:
		team_state_label.text = "Returned team state:\n%s" % "\n".join(team_state_lines)

	var recovery_state: Dictionary = Dictionary(_mission_result.get("air_asset_recovery", {})).duplicate(true)
	if recovery_state.is_empty():
		air_asset_label.text = "Air asset: no loss reported"
	else:
		air_asset_label.text = String(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_debrief_summary", recovery_state))

	var character_event_lines: PackedStringArray = []
	for event_variant in Array(_mission_result.get("character_events", [])):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = Dictionary(event_variant)
		var summary_text: String = String(event.get("summary_text", "")).strip_edges()
		if summary_text.is_empty():
			continue
		character_event_lines.append(summary_text)
		if character_event_lines.size() >= 5:
			break
	if character_event_lines.is_empty():
		character_events_label.text = "Character updates: none"
	else:
		character_events_label.text = "Character updates:\n%s" % "\n".join(character_event_lines)

	var personnel_event_lines: PackedStringArray = PackedStringArray()
	for event_variant in Array(_mission_result.get("personnel_events", [])):
		if typeof(event_variant) != TYPE_DICTIONARY:
			continue
		var message: String = String(PERSONNEL_EVENT_MODEL_SCRIPT.call("format_event_message", Dictionary(event_variant))).strip_edges()
		if message.is_empty():
			continue
		personnel_event_lines.append(message)
		if personnel_event_lines.size() >= 5:
			break
	if personnel_event_lines.is_empty():
		personnel_events_label.text = "Personnel updates: none"
	else:
		personnel_events_label.text = "Personnel updates:\n%s" % "\n".join(personnel_event_lines)
	_apply_readability_style()


func _ensure_character_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("CharacterEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "CharacterEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _ensure_air_asset_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("AirAssetEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "AirAssetEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/CharacterEventsLabel") as Control, "debrief.character_updates")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/AirAssetEventsLabel") as Control, "fob.flightdeck")


func _apply_readability_style() -> void:
	var panel := get_node_or_null("Panel") as PanelContainer
	if panel != null:
		META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")
		_apply_debrief_panel_style(panel)
		panel.set_meta("debrief_contrast_policy", "high_contrast_dark_panel")
		panel.set_meta("background_readability_policy", "dimmed_catalog_background")

	META_UI_SKIN_SCRIPT.style_header_label(get_node_or_null("Panel/Margin/VBox/TitleLabel"), 18)
	for path in [
		"Panel/Margin/VBox/ResultLabel",
		"Panel/Margin/VBox/TeamStateLabel",
		"Panel/Margin/VBox/AirAssetEventsLabel",
		"Panel/Margin/VBox/CharacterEventsLabel",
		"Panel/Margin/VBox/PersonnelEventsLabel",
	]:
		var label := get_node_or_null(path) as Label
		if label == null:
			continue
		META_UI_SKIN_SCRIPT.style_body_label(label, 13)
		label.add_theme_color_override("font_color", Color("d7e2e8"))

	for path in [
		"Panel/Margin/VBox/ButtonRow/ReturnToFOBButton",
		"Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton",
	]:
		META_UI_SKIN_SCRIPT.style_secondary_button(get_node_or_null(path) as Button)


func _apply_help_id(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	control.set_meta("help_id", normalized_id)
	control.tooltip_text = ""


func _apply_background_texture() -> void:
	var nodes: Dictionary = _ensure_background_nodes()
	var background := nodes.get("background") as TextureRect
	var shade := nodes.get("shade") as ColorRect
	var result: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("apply_to_texture_rect", background, BACKGROUND_ID))
	var entry: Dictionary = Dictionary(result.get("entry", BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", BACKGROUND_ID)))
	if shade != null:
		var dim_strength: float = clampf(float(entry.get("dim_strength", 0.62)), 0.0, 0.95)
		shade.color = Color(0.015, 0.027, 0.033, dim_strength)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if background != null:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		background.set_meta("background_id", BACKGROUND_ID)
		background.set_meta("visual_only", true)


func _ensure_background_nodes() -> Dictionary:
	var background := get_node_or_null("Background") as TextureRect
	if background == null:
		background = TextureRect.new()
		background.name = "Background"
		add_child(background)
		move_child(background, 0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var shade := get_node_or_null("BackgroundShade") as ColorRect
	if shade == null:
		shade = ColorRect.new()
		shade.name = "BackgroundShade"
		add_child(shade)
		move_child(shade, min(1, get_child_count() - 1))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.offset_left = 0.0
	shade.offset_top = 0.0
	shade.offset_right = 0.0
	shade.offset_bottom = 0.0
	return {"background": background, "shade": shade}


func _apply_debrief_panel_style(panel: PanelContainer) -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.145, 0.176, 0.200, 0.90)
	stylebox.border_color = Color(0.302, 0.353, 0.388, 0.95)
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	stylebox.content_margin_left = 14
	stylebox.content_margin_top = 12
	stylebox.content_margin_right = 14
	stylebox.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", stylebox)


func _ensure_personnel_events_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("PersonnelEventsLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "PersonnelEventsLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var button_row := vbox.get_node_or_null("ButtonRow")
	if button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _on_return_to_fob_pressed() -> void:
	return_to_fob_requested.emit()


func _on_return_to_homebase_pressed() -> void:
	return_to_homebase_requested.emit()
