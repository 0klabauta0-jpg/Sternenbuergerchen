class_name CharacterSheetView
extends RefCounted

const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const SHEET_WIDTH: float = 280.0
const ROW_LABEL_WIDTH: float = 150.0
const ROW_VALUE_WIDTH: float = 46.0


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
	_add_bar_section(sheet_root, "KERNWERTE (0,00 - 1,00):", Array(model.get("core_rows", [])))
	_add_value_section(sheet_root, "KOMMUNIKATION:", Array(model.get("communication_rows", [])))
	var platform_rows: Array = Array(model.get("platform_rows", []))
	if not platform_rows.is_empty():
		_add_value_section(sheet_root, "PLATTFORM-SKILLS (nur falls relevant):", platform_rows)
	_add_value_section(sheet_root, "ABGELEITET:", Array(model.get("derived_rows", [])))
	_add_value_section(sheet_root, "VERHALTENSPROFIL:", Array(model.get("behavior_rows", [])))


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
	portrait_rect.custom_minimum_size = Vector2(96.0, 120.0)
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.texture = _load_portrait_texture(String(profile.portrait_path)) if profile != null else null
	portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if portrait_rect.texture != null else Color(0.35, 0.37, 0.42, 1.0)
	summary_row.add_child(portrait_rect)

	var summary_vbox := VBoxContainer.new()
	summary_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_vbox.add_theme_constant_override("separation", 4)
	summary_row.add_child(summary_vbox)

	var name_label := Label.new()
	name_label.text = String(model.get("name", "Unknown Operator"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_header_label(name_label, 16)
	summary_vbox.add_child(name_label)

	var reserved_space := Control.new()
	reserved_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reserved_space.custom_minimum_size = Vector2(0.0, 28.0)
	summary_vbox.add_child(reserved_space)


static func _add_text_section(host: VBoxContainer, title: String, body_text: String) -> void:
	_add_section_header(host, title)
	var body_label := Label.new()
	body_label.text = body_text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	META_UI_SKIN_SCRIPT.style_body_label(body_label, 10)
	host.add_child(body_label)


static func _add_bar_section(host: VBoxContainer, title: String, rows: Array) -> void:
	_add_section_header(host, title)
	_add_bar_rows(host, rows)


static func _add_bar_rows(host: VBoxContainer, rows: Array) -> void:
	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)

	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_variant
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		section_vbox.add_child(row)

		var label := Label.new()
		label.text = "%s:" % String(row_data.get("label", "Metric"))
		label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
		META_UI_SKIN_SCRIPT.style_body_label(label, 10)
		row.add_child(label)

		var progress_bar := ProgressBar.new()
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		var row_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
		progress_bar.value = row_value * 100.0
		progress_bar.show_percentage = false
		progress_bar.custom_minimum_size = Vector2(0.0, 16.0)
		progress_bar.modulate = Color(0.65, 0.79, 0.92, 1.0) if String(row_data.get("value_text", "n/a")) != "n/a" else Color(0.32, 0.34, 0.38, 0.55)
		row.add_child(progress_bar)

		var value_label := Label.new()
		value_label.text = String(row_data.get("value_text", "0,00"))
		value_label.custom_minimum_size = Vector2(ROW_VALUE_WIDTH, 0.0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
		row.add_child(value_label)


static func _add_value_section(host: VBoxContainer, title: String, rows: Array) -> void:
	if rows.is_empty():
		return
	_add_section_header(host, title)
	_add_value_rows(host, rows)


static func _add_value_rows(host: VBoxContainer, rows: Array) -> void:
	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)

	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_variant
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		section_vbox.add_child(row)

		var label := Label.new()
		label.text = "%s:" % String(row_data.get("label", "Value"))
		label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
		META_UI_SKIN_SCRIPT.style_body_label(label, 10)
		row.add_child(label)

		var value_label := Label.new()
		value_label.text = String(row_data.get("value_text", "n/a"))
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
		row.add_child(value_label)


static func _add_section_header(host: VBoxContainer, title: String) -> void:
	var header_label := Label.new()
	header_label.text = title
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 11)
	host.add_child(header_label)


static func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null
	var resource: Resource = load(portrait_path)
	return resource as Texture2D