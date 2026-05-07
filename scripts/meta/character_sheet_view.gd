class_name CharacterSheetView
extends RefCounted

const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const SHEET_WIDTH: float = 280.0
const ROW_LABEL_WIDTH: float = 150.0
const ROW_VALUE_WIDTH: float = 46.0
const SECTION_HELP_IDS: Dictionary = {
	"TRAIT:": "character_sheet.traits",
	"KURZBESCHREIBUNG:": "character_sheet.identity",
	"ROLLE / LOADOUT:": "character_sheet.role_loadout",
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
	_add_value_section(sheet_root, "ROLLE / LOADOUT:", Array(model.get("role_loadout_rows", [])))
	_add_value_section(sheet_root, "STATUS / RECOVERY:", Array(model.get("status_rows", [])))
	_add_value_section(sheet_root, "TEAMFIT:", Array(model.get("relationship_rows", [])))
	_add_value_section(sheet_root, "PROGRESS:", Array(model.get("progress_rows", [])))
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
		var help_id: String = String(row_data.get("help_id", ""))
		_set_help_id(row, help_id)
		section_vbox.add_child(row)

		var label := Label.new()
		label.text = "%s:" % String(row_data.get("label", "Metric"))
		label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
		_set_help_id(label, help_id)
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
		_set_help_id(progress_bar, help_id)
		row.add_child(progress_bar)

		var value_label := Label.new()
		value_label.text = String(row_data.get("value_text", "0,00"))
		value_label.custom_minimum_size = Vector2(ROW_VALUE_WIDTH, 0.0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_set_help_id(value_label, help_id)
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


static func _add_section_header(host: VBoxContainer, title: String) -> void:
	var header_label := Label.new()
	header_label.text = title
	_set_help_id(header_label, String(SECTION_HELP_IDS.get(title, "")))
	META_UI_SKIN_SCRIPT.style_header_label(header_label, 11)
	host.add_child(header_label)


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
