class_name DebriefTestScreen
extends Control

const PERSONNEL_EVENT_MODEL_SCRIPT: GDScript = preload("res://scripts/meta/personnel_event_model.gd")
const AIR_ASSET_RECOVERY_STATE_SCRIPT: GDScript = preload("res://scripts/meta/air_asset_recovery_state.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const BACKGROUND_ID: String = "debrief_desert_explosion_base"
const DEBRIEF_SUMMARY_CHIP_COUNT_MIN := 5
const DEBRIEF_TEAM_STATUS_MAX_CHARS := 180

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


func get_debrief_visual_polish_snapshot() -> Dictionary:
	var summary_strip := get_node_or_null("Panel/Margin/VBox/SummaryStrip") as HBoxContainer
	var result_label := get_node_or_null("Panel/Margin/VBox/ResultLabel") as Label
	var team_state_label := get_node_or_null("Panel/Margin/VBox/TeamStateLabel") as Label
	var homebase_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/ReturnToHomebaseButton") as Button
	var fob_button := get_node_or_null("Panel/Margin/VBox/ButtonRow/ReturnToFOBButton") as Button
	var chips: Array = []
	if summary_strip != null:
		for child in summary_strip.get_children():
			var chip_label := child as Label
			if chip_label == null:
				continue
			chips.append({
				"name": chip_label.name,
				"text": chip_label.text,
				"style_id": String(chip_label.get_meta("debrief_chip_style_id", "")),
			})
	var checks: Array = []
	_append_visual_polish_check(checks, "summary_strip_visible", summary_strip != null and summary_strip.visible, "Summary strip should be visible.")
	_append_visual_polish_check(checks, "summary_chips_visible", chips.size() >= DEBRIEF_SUMMARY_CHIP_COUNT_MIN, "Debrief should show compact outcome chips.")
	_append_visual_polish_check(checks, "result_text_compact", result_label != null and result_label.text.length() <= 140 and result_label.text.count("\n") <= 1, "Result text should be short enough to scan.")
	_append_visual_polish_check(checks, "team_status_compact", team_state_label != null and team_state_label.text.length() <= DEBRIEF_TEAM_STATUS_MAX_CHARS, "Team status should stay compact.")
	_append_visual_polish_check(checks, "homebase_primary_action", homebase_button != null and String(homebase_button.get_meta("debrief_action_role", "")) == "primary_homebase", "Return to Homebase should read as the primary action.")
	_append_visual_polish_check(checks, "fob_secondary_action", fob_button != null and String(fob_button.get_meta("debrief_action_role", "")) == "secondary_fob", "Return to FOB should remain secondary.")
	_append_visual_polish_check(checks, "background_readability_policy", String(get_node_or_null("Panel").get_meta("background_readability_policy", "")) == "dimmed_catalog_background" if get_node_or_null("Panel") != null else false, "Dimmed background readability policy should remain active.")
	_append_visual_polish_check(checks, "read_only", true, "Snapshot reads visual state only.")
	var failed_count: int = 0
	for check_variant in checks:
		var check: Dictionary = Dictionary(check_variant)
		if not bool(check.get("passed", false)):
			failed_count += 1
	return {
		"schema": "sternenbuergerchen.debrief_visual_polish.v1",
		"task_id": "TASK_587",
		"gate": "pass" if failed_count == 0 else "fail",
		"failed_count": failed_count,
		"check_count": checks.size(),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"layout_key": "debrief_visual_polish_v1",
		"has_mission_result": not _mission_result.is_empty(),
		"summary_chip_count": chips.size(),
		"summary_chips": chips,
		"result_text": result_label.text if result_label != null else "",
		"result_text_length": result_label.text.length() if result_label != null else 0,
		"result_line_count": result_label.get_line_count() if result_label != null else 0,
		"team_status_text": team_state_label.text if team_state_label != null else "",
		"team_status_length": team_state_label.text.length() if team_state_label != null else 0,
		"primary_action_label": homebase_button.text if homebase_button != null else "",
		"secondary_action_label": fob_button.text if fob_button != null else "",
		"visual_only": true,
		"checks": checks,
	}


func get_background_catalog_snapshot() -> Dictionary:
	var entry: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", BACKGROUND_ID))
	var background := get_node_or_null("Background") as TextureRect
	var shade := get_node_or_null("BackgroundShade") as ColorRect
	var panel := get_node_or_null("Panel") as PanelContainer
	var panel_style: StyleBoxFlat = null
	if panel != null:
		panel_style = panel.get_theme_stylebox("panel") as StyleBoxFlat
	return {
		"background_id": BACKGROUND_ID,
		"path": String(entry.get("res_path", "")),
		"entry": entry,
		"uses_catalog": not entry.is_empty(),
		"has_texture": background != null and background.texture != null,
		"stretch_mode": int(background.stretch_mode) if background != null else -1,
		"shade_alpha": shade.color.a if shade != null else 0.0,
		"panel_alpha": panel_style.bg_color.a if panel_style != null else 0.0,
		"visual_only": true,
	}


func _render_result() -> void:
	var result_label: Label = get_node("Panel/Margin/VBox/ResultLabel")
	var team_state_label: Label = get_node("Panel/Margin/VBox/TeamStateLabel")
	var summary_strip: HBoxContainer = _ensure_summary_strip()
	var air_asset_label: Label = _ensure_air_asset_events_label()
	var ftl_feedback_label: Label = _ensure_ftl_feedback_label()
	var character_events_label: Label = _ensure_character_events_label()
	var personnel_events_label: Label = _ensure_personnel_events_label()
	_apply_help_id(character_events_label, "debrief.character_updates")
	_apply_help_id(air_asset_label, "fob.flightdeck")
	_apply_help_id(ftl_feedback_label, "character_sheet.ftl_tactical_impact")

	if _mission_result.is_empty():
		_render_summary_chips(summary_strip, [
			{"id": "result", "text": "PENDING"},
			{"id": "winner", "text": "WIN -"},
			{"id": "duration", "text": "TIME -"},
			{"id": "condition", "text": "COND -"},
			{"id": "objective", "text": "OBJ -"},
		])
		result_label.text = "Mission pending | Debrief data unavailable"
		team_state_label.text = "Team: unavailable"
		air_asset_label.text = "Air asset: pending"
		ftl_feedback_label.text = "FTL feedback: pending"
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

	_render_summary_chips(summary_strip, [
		{"id": "result", "text": result.to_upper()},
		{"id": "winner", "text": "WIN %s" % winner_text.to_upper()},
		{"id": "duration", "text": "TIME %ss" % _format_debrief_seconds(duration_seconds)},
		{"id": "condition", "text": "COND %s" % _format_compact_token(win_condition_type, "unknown")},
		{"id": "objective", "text": "OBJ %s" % ("TAKEN" if objective_captured else "OPEN")},
	])
	result_label.text = "Mission %s | %s | Winner %s | %s" % [
		mission_outcome,
		result.to_upper(),
		winner_text,
		_format_compact_token(win_condition_type, "condition unknown"),
	]

	var team_state_counts: Dictionary = {}
	var team_state_tokens: PackedStringArray = []
	for member_state in _mission_result.get("team_states", []):
		var display_name: String = String(member_state.get("display_name", member_state.get("unit_id", "")))
		var vital_state: String = String(member_state.get("vital_state", "unknown"))
		var health_points: int = int(member_state.get("health_points", -1))
		team_state_counts[vital_state] = int(team_state_counts.get(vital_state, 0)) + 1
		if team_state_tokens.size() < 4:
			team_state_tokens.append("%s %s %dHP" % [display_name, vital_state.to_upper(), health_points])

	if team_state_tokens.is_empty():
		team_state_label.text = "Team: unavailable"
	else:
		team_state_label.text = "Team: %s | %s" % [
			_format_team_state_counts(team_state_counts),
			" | ".join(team_state_tokens),
		]

	var recovery_state: Dictionary = Dictionary(_mission_result.get("air_asset_recovery", {})).duplicate(true)
	if recovery_state.is_empty():
		air_asset_label.text = "Air asset: no loss reported"
	else:
		air_asset_label.text = String(AIR_ASSET_RECOVERY_STATE_SCRIPT.call("build_debrief_summary", recovery_state))

	var ftl_feedback_lines: PackedStringArray = _build_ftl_feedback_lines(Array(_mission_result.get("fireteam_tactical_debrief", [])))
	if ftl_feedback_lines.is_empty():
		ftl_feedback_label.text = "FTL feedback: unavailable"
	else:
		ftl_feedback_label.text = "FTL feedback:\n%s" % "\n".join(ftl_feedback_lines)

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


func _ensure_ftl_feedback_label() -> Label:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("FTLFeedbackLabel") as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = "FTLFeedbackLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var character_label := vbox.get_node_or_null("CharacterEventsLabel")
	var button_row := vbox.get_node_or_null("ButtonRow")
	if character_label != null:
		vbox.add_child(label)
		vbox.move_child(label, character_label.get_index())
	elif button_row != null:
		vbox.add_child(label)
		vbox.move_child(label, button_row.get_index())
	else:
		vbox.add_child(label)
	return label


func _apply_contextual_help_ids() -> void:
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/CharacterEventsLabel") as Control, "debrief.character_updates")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/AirAssetEventsLabel") as Control, "fob.flightdeck")
	_apply_help_id(get_node_or_null("Panel/Margin/VBox/FTLFeedbackLabel") as Control, "character_sheet.ftl_tactical_impact")


func _apply_readability_style() -> void:
	var panel := get_node_or_null("Panel") as PanelContainer
	if panel != null:
		META_UI_SKIN_SCRIPT.style_tactical_panel(panel, "frame")
		_apply_debrief_panel_style(panel)
		panel.set_meta("debrief_contrast_policy", "translucent_high_contrast_panel")
		panel.set_meta("background_readability_policy", "dimmed_catalog_background")

	META_UI_SKIN_SCRIPT.style_header_label(get_node_or_null("Panel/Margin/VBox/TitleLabel"), 18)
	var title_label := get_node_or_null("Panel/Margin/VBox/TitleLabel") as Label
	if title_label != null:
		title_label.text = "Mission Debrief"
		title_label.set_meta("debrief_title_style_id", "debrief_title_v1")
	_apply_summary_chip_style()
	for path in [
		"Panel/Margin/VBox/ResultLabel",
		"Panel/Margin/VBox/TeamStateLabel",
		"Panel/Margin/VBox/AirAssetEventsLabel",
		"Panel/Margin/VBox/FTLFeedbackLabel",
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
		var button := get_node_or_null(path) as Button
		if button == null:
			continue
		if button.name == "ReturnToHomebaseButton":
			META_UI_SKIN_SCRIPT.style_primary_button(button)
			button.set_meta("debrief_action_role", "primary_homebase")
		else:
			META_UI_SKIN_SCRIPT.style_secondary_button(button)
			button.set_meta("debrief_action_role", "secondary_fob")


func _apply_help_id(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_id: String = help_id.strip_edges()
	if normalized_id.is_empty():
		return
	control.set_meta("help_id", normalized_id)
	control.tooltip_text = ""


func _build_ftl_feedback_lines(entries: Array) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for entry_variant in entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_upper()
		if fireteam_id.is_empty():
			fireteam_id = "TEAM"
		var reaction_delay: float = maxf(float(entry.get("reaction_delay_seconds", 0.0)), 0.0)
		var plan_quality: float = clampf(float(entry.get("plan_quality", 0.5)), 0.0, 1.0)
		var tempo_delta: int = int(round((clampf(float(entry.get("tempo_modifier", 1.0)), 0.0, 2.0) - 1.0) * 100.0))
		var contact_count: int = maxi(int(entry.get("contact_report_count", 0)), 0)
		var report_quality: float = clampf(float(entry.get("contact_report_quality", 0.5)), 0.0, 1.0)
		var morale: float = clampf(float(entry.get("morale", 0.5)), 0.0, 1.0)
		var frustration: float = clampf(float(entry.get("frustration", 0.0)), 0.0, 1.0)
		lines.append("%s: Reaktion %.2fs | Plan %s | Tempo %+d%% | Kontakte %d (Meldung %s) | Moral %s" % [
			fireteam_id,
			reaction_delay,
			_format_debrief_quality_bucket(plan_quality),
			tempo_delta,
			contact_count,
			_format_contact_report_quality_bucket(report_quality),
			_format_debrief_morale_bucket(morale, frustration),
		])
		if lines.size() >= 4:
			break
	return lines


func _format_debrief_quality_bucket(value: float) -> String:
	if value >= 0.66:
		return "stark"
	if value >= 0.42:
		return "solide"
	return "roh"


func _format_contact_report_quality_bucket(value: float) -> String:
	if value >= 0.70:
		return "hoch"
	if value >= 0.42:
		return "mittel"
	return "niedrig"


func _format_debrief_morale_bucket(morale: float, frustration: float) -> String:
	if morale < 0.35 or frustration >= 0.68:
		return "kritisch"
	if morale < 0.48 or frustration >= 0.46:
		return "sinkt"
	if morale >= 0.64 and frustration <= 0.28:
		return "stabil"
	return "ruhig"


func _ensure_summary_strip() -> HBoxContainer:
	var vbox := get_node("Panel/Margin/VBox") as VBoxContainer
	var existing := vbox.get_node_or_null("SummaryStrip") as HBoxContainer
	if existing != null:
		return existing
	var strip := HBoxContainer.new()
	strip.name = "SummaryStrip"
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 8)
	vbox.add_child(strip)
	var result_label := vbox.get_node_or_null("ResultLabel")
	if result_label != null:
		vbox.move_child(strip, result_label.get_index())
	return strip


func _render_summary_chips(strip: HBoxContainer, chips: Array) -> void:
	if strip == null:
		return
	while strip.get_child_count() > chips.size():
		var extra := strip.get_child(strip.get_child_count() - 1)
		strip.remove_child(extra)
		extra.queue_free()
	for index in range(chips.size()):
		var chip_data: Dictionary = Dictionary(chips[index])
		var chip: Label = null
		if index < strip.get_child_count():
			chip = strip.get_child(index) as Label
		if chip == null:
			chip = Label.new()
			strip.add_child(chip)
		chip.name = "DebriefChip_%s" % String(chip_data.get("id", index)).strip_edges()
		chip.text = String(chip_data.get("text", "")).strip_edges()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.clip_text = true
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chip.set_meta("debrief_chip_style_id", "debrief_summary_chip_v1")
	_apply_summary_chip_style()


func _apply_summary_chip_style() -> void:
	var strip := get_node_or_null("Panel/Margin/VBox/SummaryStrip") as HBoxContainer
	if strip == null:
		return
	for child in strip.get_children():
		var chip := child as Label
		if chip == null:
			continue
		chip.add_theme_color_override("font_color", Color("172026"))
		chip.add_theme_font_size_override("font_size", 11)
		chip.add_theme_stylebox_override("normal", _build_chip_stylebox())


func _build_chip_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color("d7e2e8")
	stylebox.border_color = Color("94a6b0")
	stylebox.border_width_left = 1
	stylebox.border_width_top = 1
	stylebox.border_width_right = 1
	stylebox.border_width_bottom = 1
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.content_margin_left = 8
	stylebox.content_margin_top = 5
	stylebox.content_margin_right = 8
	stylebox.content_margin_bottom = 5
	return stylebox


func _format_debrief_seconds(seconds: float) -> String:
	var total_seconds: int = maxi(int(round(seconds)), 0)
	var minutes: int = total_seconds / 60
	var remaining_seconds: int = total_seconds % 60
	if minutes <= 0:
		return "%d" % remaining_seconds
	return "%d:%02d" % [minutes, remaining_seconds]


func _format_compact_token(value: String, fallback: String) -> String:
	var normalized: String = value.strip_edges()
	if normalized.is_empty():
		normalized = fallback
	return normalized.replace("_", " ").to_upper()


func _format_team_state_counts(counts: Dictionary) -> String:
	var keys: Array = counts.keys()
	keys.sort()
	var parts: PackedStringArray = PackedStringArray()
	for key_variant in keys:
		var key: String = String(key_variant).strip_edges()
		if key.is_empty():
			continue
		parts.append("%s %d" % [key.to_upper(), int(counts.get(key, 0))])
	if parts.is_empty():
		return "UNKNOWN"
	return " / ".join(parts)


func _append_visual_polish_check(checks: Array, check_id: String, passed: bool, message: String) -> void:
	checks.append({
		"id": check_id,
		"passed": passed,
		"message": message,
	})


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
	stylebox.bg_color = Color(0.145, 0.176, 0.200, 0.58)
	stylebox.border_color = Color(0.302, 0.353, 0.388, 0.82)
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
