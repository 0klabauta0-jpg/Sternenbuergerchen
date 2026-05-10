class_name CharacterSheetView
extends RefCounted

const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const SHEET_WIDTH: float = 280.0
const ROW_LABEL_WIDTH: float = 118.0
const ROW_VALUE_WIDTH: float = 46.0
const VALUE_STEP: float = 0.05
const SECTION_HELP_IDS: Dictionary = {
	"TRAIT:": "character_sheet.traits",
	"KURZBESCHREIBUNG:": "character_sheet.identity",
	"ROLLE / LOADOUT:": "character_sheet.role_loadout",
	"LETZTE AUSRUESTUNG:": "character_sheet.loadout_summary",
	"STATUS / RECOVERY:": "character_sheet.status_recovery",
	"TEAMFIT:": "character_sheet.teamfit",
	"PROGRESS:": "character_sheet.progression",
	"KERNWERTE (0,00 - 1,00):": "character_sheet.core_values",
	"KOMMUNIKATION:": "character_sheet.communication",
	"PLATTFORM-SKILLS (nur falls relevant):": "character_sheet.platform_skills",
	"ABGELEITET:": "character_sheet.derived_badges",
	"VERHALTENSPROFIL:": "character_sheet.behavior_profile",
}


static func render(host: VBoxContainer, profile, options: Dictionary = {}) -> void:
	if host == null:
		return
	_clear_container(host)
	host.add_theme_constant_override("separation", 0)

	var model: Dictionary = CHARACTER_SHEET_FORMATTER_SCRIPT.build_sheet_view_model(profile, options)
	var sheet_root := VBoxContainer.new()
	sheet_root.name = "SheetRoot"
	sheet_root.custom_minimum_size = Vector2(SHEET_WIDTH, 0.0)
	sheet_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sheet_root.add_theme_constant_override("separation", 8)
	host.add_child(sheet_root)

	_add_identity_block(sheet_root, model, profile)
	_add_text_section(sheet_root, "TRAIT:", String(model.get("trait_text", "Keine Traits verfuegbar.")))
	_add_text_section(sheet_root, "KURZBESCHREIBUNG:", String(model.get("short_description", "Keine Kurzbeschreibung verfuegbar.")))
	_add_value_section(sheet_root, "ROLLE / LOADOUT:", Array(model.get("role_loadout_rows", [])), profile, options)
	_add_loadout_dropdown_section(sheet_root, profile)
	_add_value_section(sheet_root, "STATUS / RECOVERY:", Array(model.get("status_rows", [])), profile, options)
	_add_value_section(sheet_root, "TEAMFIT:", Array(model.get("relationship_rows", [])), profile, options)
	_add_value_section(sheet_root, "PROGRESS:", Array(model.get("progress_rows", [])), profile, options)
	_add_bar_section(sheet_root, "KERNWERTE (0,00 - 1,00):", Array(model.get("core_rows", [])), profile, options)
	_add_value_section(sheet_root, "KOMMUNIKATION:", Array(model.get("communication_rows", [])), profile, options)
	var platform_rows: Array = Array(model.get("platform_rows", []))
	if not platform_rows.is_empty():
		_add_value_section(sheet_root, "PLATTFORM-SKILLS (nur falls relevant):", platform_rows, profile, options)
	_add_value_section(sheet_root, "ABGELEITET:", Array(model.get("derived_rows", [])), profile, options)
	_add_value_section(sheet_root, "VERHALTENSPROFIL:", Array(model.get("behavior_rows", [])), profile, options)


static func _clear_container(host: VBoxContainer) -> void:
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()


static func _add_identity_block(host: VBoxContainer, model: Dictionary, profile) -> void:
	var summary_row := HBoxContainer.new()
	summary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_theme_constant_override("separation", 12)
	host.add_child(summary_row)

	var portrait_rect := TextureRect.new()
	portrait_rect.name = "PortraitRect"
	_set_help_id(portrait_rect, "character_sheet.identity")
	PORTRAIT_IDENTITY_CATALOG_SCRIPT.apply_texture_rect_contract(portrait_rect, "character_sheet")
	portrait_rect.texture = _load_portrait_texture(String(profile.portrait_id), String(profile.portrait_path)) if profile != null else null
	portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if portrait_rect.texture != null else Color(0.35, 0.37, 0.42, 1.0)
	summary_row.add_child(portrait_rect)

	var summary_vbox := VBoxContainer.new()
	summary_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_vbox.add_theme_constant_override("separation", 4)
	summary_row.add_child(summary_vbox)

	var name_label := Label.new()
	name_label.text = String(model.get("name", "Unknown Operator"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_help_id(name_label, "character_sheet.identity")
	META_UI_SKIN_SCRIPT.style_header_label(name_label, 16)
	summary_vbox.add_child(name_label)

	_add_badge_row(summary_vbox, profile)

	var reserved_space := Control.new()
	reserved_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reserved_space.custom_minimum_size = Vector2(0.0, 28.0)
	summary_vbox.add_child(reserved_space)


static func _add_badge_row(host: VBoxContainer, profile) -> void:
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", profile))
	if badges.is_empty():
		return
	var badge_row := HBoxContainer.new()
	badge_row.name = "RankBadgeRow"
	_set_help_id(badge_row, "character_sheet.rank_badges")
	badge_row.add_theme_constant_override("separation", 5)
	host.add_child(badge_row)
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var texture_rect := TextureRect.new()
		texture_rect.name = "RankBadge_%s" % String(badge.get("badge_key", badge.get("badge_id", "unknown"))).strip_edges()
		_set_help_id(texture_rect, "character_sheet.rank_badges")
		texture_rect.custom_minimum_size = Vector2(18.0, 18.0)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.tooltip_text = "%s: %s" % [String(badge.get("label", "Badge")), String(badge.get("reason", ""))]
		var badge_path: String = String(badge.get("path", "")).strip_edges()
		if not badge_path.is_empty() and ResourceLoader.exists(badge_path):
			texture_rect.texture = load(badge_path) as Texture2D
		if texture_rect.texture == null:
			texture_rect.modulate = Color(1.0, 0.45, 0.35, 0.95)
			texture_rect.set_meta("missing_rank_badge_asset", true)
		badge_row.add_child(texture_rect)


static func _add_text_section(host: VBoxContainer, title: String, body_text: String) -> void:
	_add_section_header(host, title)
	var body_label := Label.new()
	body_label.text = body_text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_help_id(body_label, String(SECTION_HELP_IDS.get(title, "")))
	META_UI_SKIN_SCRIPT.style_body_label(body_label, 10)
	host.add_child(body_label)


static func _add_bar_section(host: VBoxContainer, title: String, rows: Array, profile = null, options: Dictionary = {}) -> void:
	_add_section_header(host, title)
	_add_bar_rows(host, rows, profile, options)


static func _add_bar_rows(host: VBoxContainer, rows: Array, profile = null, options: Dictionary = {}) -> void:
	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)

	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_variant
		_add_metric_editor_row(section_vbox, row_data, profile, options)


static func _add_value_section(host: VBoxContainer, title: String, rows: Array, profile = null, options: Dictionary = {}) -> void:
	if rows.is_empty():
		return
	_add_section_header(host, title)
	_add_value_rows(host, rows, profile, options)


static func _add_value_rows(host: VBoxContainer, rows: Array, profile = null, options: Dictionary = {}) -> void:
	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)

	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_variant
		if row_data.has("value"):
			_add_metric_editor_row(section_vbox, row_data, profile, options)
			continue
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		var help_id: String = String(row_data.get("help_id", ""))
		_set_help_id(row, help_id)
		section_vbox.add_child(row)

		var label := Label.new()
		label.text = "%s:" % String(row_data.get("label", "Value"))
		label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
		_set_help_id(label, help_id)
		META_UI_SKIN_SCRIPT.style_body_label(label, 10)
		row.add_child(label)

		var value_label := Label.new()
		value_label.text = String(row_data.get("value_text", "n/a"))
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_set_help_id(value_label, help_id)
		META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
		row.add_child(value_label)


static func _add_metric_editor_row(host: VBoxContainer, row_data: Dictionary, profile = null, options: Dictionary = {}) -> void:
	var help_id: String = String(row_data.get("help_id", ""))
	var row := HBoxContainer.new()
	row.name = "EditableMetricRow_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.focus_mode = Control.FOCUS_ALL
	row.add_theme_constant_override("separation", 5)
	_set_help_id(row, help_id)
	host.add_child(row)

	var label := Label.new()
	label.name = "MetricLabel_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	label.text = "%s:" % String(row_data.get("label", "Metric"))
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	_set_help_id(label, help_id)
	META_UI_SKIN_SCRIPT.style_body_label(label, 10)
	row.add_child(label)

	var minus_button := Button.new()
	minus_button.name = "MetricMinus_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(24.0, 22.0)
	minus_button.focus_mode = Control.FOCUS_ALL
	_set_help_id(minus_button, help_id)
	row.add_child(minus_button)

	var bar_host := Control.new()
	bar_host.name = "MetricBarHost_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	bar_host.custom_minimum_size = Vector2(0.0, 18.0)
	bar_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_help_id(bar_host, help_id)
	row.add_child(bar_host)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "MetricProgress_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	progress_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_bar.offset_left = 0.0
	progress_bar.offset_top = 0.0
	progress_bar.offset_right = 0.0
	progress_bar.offset_bottom = 0.0
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.modulate = Color(0.65, 0.79, 0.92, 1.0) if String(row_data.get("value_text", "n/a")) != "n/a" else Color(0.32, 0.34, 0.38, 0.55)
	_set_help_id(progress_bar, help_id)
	bar_host.add_child(progress_bar)

	var value_label := Label.new()
	value_label.name = "MetricValueLabel_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	value_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	value_label.offset_left = 6.0
	value_label.offset_top = 0.0
	value_label.offset_right = -2.0
	value_label.offset_bottom = 0.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_help_id(value_label, help_id)
	META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
	bar_host.add_child(value_label)

	var plus_button := Button.new()
	plus_button.name = "MetricPlus_%s" % _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(24.0, 22.0)
	plus_button.focus_mode = Control.FOCUS_ALL
	_set_help_id(plus_button, help_id)
	row.add_child(plus_button)

	var initial_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
	var sync_visuals := func(next_value: float) -> void:
		var normalized_value: float = clampf(next_value, 0.0, 1.0)
		row_data["value"] = normalized_value
		row_data["value_text"] = _format_decimal_comma(normalized_value)
		progress_bar.value = normalized_value * 100.0
		value_label.text = String(row_data.get("value_text", "0,00"))
		minus_button.disabled = normalized_value <= 0.001
		plus_button.disabled = normalized_value >= 0.999
	sync_visuals.call(initial_value)

	var commit_delta := func(delta: float) -> void:
		var next_value: float = clampf(float(row_data.get("value", 0.0)) + delta, 0.0, 1.0)
		_apply_profile_metric_value(profile, row_data, next_value)
		sync_visuals.call(next_value)
		_emit_metric_changed(options, profile, row_data, next_value)
	if not minus_button.pressed.is_connected(commit_delta.bind(-VALUE_STEP)):
		minus_button.pressed.connect(commit_delta.bind(-VALUE_STEP))
	if not plus_button.pressed.is_connected(commit_delta.bind(VALUE_STEP)):
		plus_button.pressed.connect(commit_delta.bind(VALUE_STEP))
	row.gui_input.connect(func(event: InputEvent) -> void:
		var key_event := event as InputEventKey
		if key_event == null or not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_LEFT, KEY_DOWN:
				commit_delta.call(-VALUE_STEP)
				row.accept_event()
			KEY_RIGHT, KEY_UP:
				commit_delta.call(VALUE_STEP)
				row.accept_event()
	)


static func _add_loadout_dropdown_section(host: VBoxContainer, profile) -> void:
	if profile == null:
		return
	_add_section_header(host, "LETZTE AUSRUESTUNG:")
	var section_vbox := VBoxContainer.new()
	section_vbox.name = "LastLoadoutDropdownSection"
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)
	_add_armor_dropdown_row(section_vbox, String(profile.armor_id))
	_add_weapon_dropdown_row(section_vbox, "Waffe 1", "Weapon1LastSelect", "Weapon1LastPreview", String(profile.weapon_1_id))
	_add_weapon_dropdown_row(section_vbox, "Waffe 2", "Weapon2LastSelect", "Weapon2LastPreview", String(profile.weapon_2_id))


static func _add_armor_dropdown_row(host: VBoxContainer, selected_armor_id: String) -> void:
	var row := _build_loadout_row("Ruestung")
	var option := OptionButton.new()
	option.name = "ArmorLastSelect"
	option.custom_minimum_size = Vector2(170.0, 26.0)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.tooltip_text = "Zeigt die zuletzt getragene Ruestung. Andere Eintraege sind hier absichtlich gesperrt."
	option.add_theme_font_size_override("font_size", 9)
	var normalized_selected: String = _normalize_armor_id(selected_armor_id)
	for armor_id in PackedStringArray(["light", "medium", "heavy"]):
		option.add_item("%s Armor" % armor_id.capitalize())
		var item_index: int = option.item_count - 1
		option.set_item_metadata(item_index, armor_id)
		option.set_item_disabled(item_index, armor_id != normalized_selected)
		if armor_id == normalized_selected:
			option.select(item_index)
	row.add_child(option)
	host.add_child(row)


static func _add_weapon_dropdown_row(host: VBoxContainer, label_text: String, option_name: String, preview_name: String, selected_weapon_id: String) -> void:
	var row := _build_loadout_row(label_text)
	var preview := TextureRect.new()
	preview.name = preview_name
	preview.custom_minimum_size = Vector2(24.0, 24.0)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var normalized_selected: String = String(WEAPON_DATA_SCRIPT.call("sanitize_weapon_id", selected_weapon_id))
	preview.texture = _load_weapon_preview_texture(normalized_selected)
	preview.visible = preview.texture != null
	preview.tooltip_text = String(WEAPON_DATA_SCRIPT.call("get_display_name", normalized_selected))
	preview.set_meta("weapon_id", normalized_selected)
	preview.set_meta("weapon_preview_path", String(WEAPON_DATA_SCRIPT.call("get_preview_path", normalized_selected)))
	row.add_child(preview)

	var option := OptionButton.new()
	option.name = option_name
	option.custom_minimum_size = Vector2(146.0, 26.0)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.tooltip_text = "Letzte Waffe. Andere Optionen sind ausgegraut, bis Loadout-Aenderungen ueber die FOB laufen."
	option.add_theme_font_size_override("font_size", 9)
	var all_weapon_ids: PackedStringArray = WEAPON_DATA_SCRIPT.call("get_all_weapon_ids")
	if not all_weapon_ids.has(normalized_selected):
		all_weapon_ids.append(normalized_selected)
	for weapon_id in all_weapon_ids:
		var display_name: String = String(WEAPON_DATA_SCRIPT.call("get_display_name", weapon_id))
		var icon: Texture2D = _load_weapon_preview_texture(weapon_id)
		if icon != null:
			option.add_icon_item(icon, display_name)
		else:
			option.add_item(display_name)
		var item_index: int = option.item_count - 1
		option.set_item_metadata(item_index, weapon_id)
		option.set_item_disabled(item_index, weapon_id != normalized_selected)
		if weapon_id == normalized_selected:
			option.select(item_index)
	row.add_child(option)
	host.add_child(row)


static func _build_loadout_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "LastLoadoutRow_%s" % _sanitize_node_fragment(label_text)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	var label := Label.new()
	label.text = "%s:" % label_text
	label.custom_minimum_size = Vector2(72.0, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	META_UI_SKIN_SCRIPT.style_body_label(label, 10)
	row.add_child(label)
	return row


static func _add_section_header(host: VBoxContainer, title: String) -> void:
	var header_label := Label.new()
	header_label.text = title
	_set_help_id(header_label, String(SECTION_HELP_IDS.get(title, "")))
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 11)
	host.add_child(header_label)


static func _apply_profile_metric_value(profile, row_data: Dictionary, next_value: float) -> void:
	if profile == null:
		return
	var value_group: String = String(row_data.get("value_group", "")).strip_edges()
	var value_key: String = String(row_data.get("value_key", "")).strip_edges()
	if value_group.is_empty() or value_key.is_empty():
		return
	var normalized_value: float = clampf(next_value, 0.0, 1.0)
	match value_group:
		"skill_values":
			var skill_values: Dictionary = Dictionary(profile.skill_values)
			skill_values[value_key] = normalized_value
			profile.skill_values = skill_values
		"communication_values":
			var communication_values: Dictionary = Dictionary(profile.communication_values)
			communication_values[value_key] = normalized_value
			profile.communication_values = communication_values
		"platform_values":
			var platform_values: Dictionary = Dictionary(profile.platform_values)
			platform_values[value_key] = normalized_value
			profile.platform_values = platform_values
		"behavior_axes":
			var behavior_axes: Dictionary = Dictionary(profile.behavior_axes)
			behavior_axes[value_key] = normalized_value
			profile.behavior_axes = behavior_axes
		"progression":
			var progression_values: Dictionary = Dictionary(profile.progression)
			progression_values[value_key] = normalized_value
			profile.progression = progression_values


static func _emit_metric_changed(options: Dictionary, profile, row_data: Dictionary, next_value: float) -> void:
	var callback_variant: Variant = options.get("on_value_changed", null)
	if typeof(callback_variant) != TYPE_CALLABLE:
		return
	var callback: Callable = callback_variant
	if not callback.is_valid():
		return
	callback.call(profile, row_data.duplicate(true), clampf(next_value, 0.0, 1.0))


static func _load_weapon_preview_texture(weapon_id: String) -> Texture2D:
	var preview_path: String = String(WEAPON_DATA_SCRIPT.call("get_preview_path", weapon_id)).strip_edges()
	if preview_path.is_empty() or not ResourceLoader.exists(preview_path):
		return null
	return load(preview_path) as Texture2D


static func _normalize_armor_id(armor_id: String) -> String:
	var normalized: String = armor_id.strip_edges().to_lower()
	if normalized == "light" or normalized == "medium" or normalized == "heavy":
		return normalized
	return "medium"


static func _format_decimal_comma(value: float) -> String:
	return ("%.2f" % clampf(value, 0.0, 1.0)).replace(".", ",")


static func _sanitize_node_fragment(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower().replace(" ", "_").replace("/", "_")
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9") or character == "_":
			result += character
	if result.is_empty():
		result = "metric"
	return result


static func _load_portrait_texture(portrait_id: String, portrait_path: String) -> Texture2D:
	return PORTRAIT_IDENTITY_CATALOG_SCRIPT.load_texture(portrait_id, portrait_path)


static func _set_help_id(control: Control, help_id: String) -> void:
	if control == null:
		return
	var normalized_help_id: String = help_id.strip_edges()
	if normalized_help_id.is_empty():
		return
	control.set_meta("help_id", normalized_help_id)
	control.tooltip_text = ""
