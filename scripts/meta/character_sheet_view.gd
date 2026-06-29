class_name CharacterSheetView
extends RefCounted

const CHARACTER_SHEET_FORMATTER_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_formatter.gd")
const META_UI_SKIN_SCRIPT: GDScript = preload("res://scripts/meta/meta_ui_skin.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const WEAPON_DATA_SCRIPT: GDScript = preload("res://scripts/core/weapon_data.gd")
const SHEET_WIDTH: float = 280.0
const SHEET_WIDE_WIDTH: float = 760.0
const SHEET_LEFT_COLUMN_WIDTH: float = 430.0
const SHEET_RIGHT_COLUMN_WIDTH: float = 300.0
const ROW_LABEL_WIDTH: float = 118.0
const ROW_VALUE_WIDTH: float = 46.0
const DERIVED_TEXT_MIN_WIDTH: float = 220.0
const VALUE_STEP: float = 0.05
const METRIC_POINTS_PER_VALUE: int = 20
const METRIC_GROUP_BUDGET_HELP_ID: String = "character_sheet.skill_group_budget"
const METRIC_LOCK_HELP_ID: String = "character_sheet.value_lock"
const SECTION_HELP_IDS: Dictionary = {
	"TRAIT:": "character_sheet.traits",
	"KURZBESCHREIBUNG:": "character_sheet.identity",
	"ROLLE / LOADOUT:": "character_sheet.role_loadout",
	"LETZTE AUSRUESTUNG:": "character_sheet.loadout_summary",
	"STATUS / RECOVERY:": "character_sheet.status_recovery",
	"TEAMFIT:": "character_sheet.teamfit",
	"PROGRESS:": "character_sheet.progression",
	"WERTE / BUDGETS:": "character_sheet.skill_group_budget",
	"STATUSWERTE:": "character_sheet.progression",
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
	var group_editable_metrics: bool = bool(options.get("group_editable_metrics", false))
	var two_column_layout: bool = bool(options.get("two_column_layout", group_editable_metrics))
	var sheet_root := VBoxContainer.new()
	sheet_root.name = "SheetRoot"
	sheet_root.custom_minimum_size = Vector2(SHEET_WIDE_WIDTH if two_column_layout else SHEET_WIDTH, 0.0)
	sheet_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL if two_column_layout else Control.SIZE_SHRINK_CENTER
	sheet_root.add_theme_constant_override("separation", 8)
	host.add_child(sheet_root)

	_add_identity_block(sheet_root, model, profile, options)
	if two_column_layout:
		var columns := HBoxContainer.new()
		columns.name = "CharacterSheetTwoColumnBody"
		columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		columns.add_theme_constant_override("separation", 16)
		sheet_root.add_child(columns)

		var values_column := VBoxContainer.new()
		values_column.name = "CharacterSheetValuesColumn"
		values_column.custom_minimum_size = Vector2(SHEET_LEFT_COLUMN_WIDTH, 0.0)
		values_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		values_column.add_theme_constant_override("separation", 8)
		columns.add_child(values_column)

		var context_column := VBoxContainer.new()
		context_column.name = "CharacterSheetContextColumn"
		context_column.custom_minimum_size = Vector2(SHEET_RIGHT_COLUMN_WIDTH, 0.0)
		context_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		context_column.add_theme_constant_override("separation", 8)
		columns.add_child(context_column)

		_add_grouped_metric_sections(values_column, model, profile, options)
		_add_trait_section(context_column, String(model.get("trait_text", "Keine Traits verfuegbar.")), Array(model.get("trait_rows", [])))
		if not bool(options.get("hide_short_description", false)):
			_add_text_section(context_column, "KURZBESCHREIBUNG:", String(model.get("short_description", "Keine Kurzbeschreibung verfuegbar.")))
		_add_value_section(context_column, "ROLLE / LOADOUT:", Array(model.get("role_loadout_rows", [])), profile, options)
		_add_value_section(context_column, "STATUS / RECOVERY:", _filter_metric_rows(Array(model.get("status_rows", [])), false), profile, options)
		_add_value_section(context_column, "TEAMFIT:", Array(model.get("relationship_rows", [])), profile, options)
		_add_value_section(context_column, "PROGRESS:", _filter_metric_rows(Array(model.get("progress_rows", [])), false), profile, options)
		_add_value_section(context_column, "ABGELEITET:", Array(model.get("derived_rows", [])), profile, options)
		if not bool(options.get("hide_loadout_dropdowns", false)):
			_add_loadout_dropdown_section(context_column, profile)
		return

	_add_trait_section(sheet_root, String(model.get("trait_text", "Keine Traits verfuegbar.")), Array(model.get("trait_rows", [])))
	if not bool(options.get("hide_short_description", false)):
		_add_text_section(sheet_root, "KURZBESCHREIBUNG:", String(model.get("short_description", "Keine Kurzbeschreibung verfuegbar.")))
	_add_value_section(sheet_root, "ROLLE / LOADOUT:", Array(model.get("role_loadout_rows", [])), profile, options)
	if not bool(options.get("move_last_loadout_to_bottom", false)) and not bool(options.get("hide_loadout_dropdowns", false)):
		_add_loadout_dropdown_section(sheet_root, profile)
	_add_value_section(sheet_root, "STATUS / RECOVERY:", _filter_metric_rows(Array(model.get("status_rows", [])), false) if group_editable_metrics else Array(model.get("status_rows", [])), profile, options)
	_add_value_section(sheet_root, "TEAMFIT:", Array(model.get("relationship_rows", [])), profile, options)
	_add_value_section(sheet_root, "PROGRESS:", _filter_metric_rows(Array(model.get("progress_rows", [])), false) if group_editable_metrics else Array(model.get("progress_rows", [])), profile, options)
	if group_editable_metrics:
		_add_grouped_metric_sections(sheet_root, model, profile, options)
	else:
		_add_bar_section(sheet_root, "KERNWERTE (0,00 - 1,00):", Array(model.get("core_rows", [])), profile, options)
		_add_value_section(sheet_root, "KOMMUNIKATION:", Array(model.get("communication_rows", [])), profile, options)
		var platform_rows: Array = Array(model.get("platform_rows", []))
		if not platform_rows.is_empty():
			_add_value_section(sheet_root, "PLATTFORM-SKILLS (nur falls relevant):", platform_rows, profile, options)
	_add_value_section(sheet_root, "ABGELEITET:", Array(model.get("derived_rows", [])), profile, options)
	if not group_editable_metrics:
		_add_value_section(sheet_root, "VERHALTENSPROFIL:", Array(model.get("behavior_rows", [])), profile, options)
	if bool(options.get("move_last_loadout_to_bottom", false)) and not bool(options.get("hide_loadout_dropdowns", false)):
		_add_loadout_dropdown_section(sheet_root, profile)


static func _clear_container(host: VBoxContainer) -> void:
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()


static func _add_identity_block(host: VBoxContainer, model: Dictionary, profile, options: Dictionary = {}) -> void:
	var summary_row := HBoxContainer.new()
	summary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_theme_constant_override("separation", 12)
	_set_help_id(summary_row, "character_sheet.identity")
	host.add_child(summary_row)

	var portrait_rect := TextureRect.new()
	portrait_rect.name = "PortraitRect"
	_set_help_id(portrait_rect, "character_sheet.portrait")
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
	_set_help_id(name_label, "character_sheet.name")
	META_UI_SKIN_SCRIPT.style_header_label(name_label, 16)
	summary_vbox.add_child(name_label)

	_add_badge_row(summary_vbox, profile, options)
	_add_next_rank_requirement(summary_vbox, profile)

	var reserved_space := Control.new()
	reserved_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reserved_space.custom_minimum_size = Vector2(0.0, 28.0)
	summary_vbox.add_child(reserved_space)


static func _add_badge_row(host: VBoxContainer, profile, options: Dictionary = {}) -> void:
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", profile))
	var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", profile))
	var show_progress_badges: bool = bool(options.get("show_badge_progress", options.get("two_column_layout", false)))
	var display_badges: Array = []
	if show_progress_badges:
		for progress_variant in progress:
			if typeof(progress_variant) != TYPE_DICTIONARY:
				continue
			var progress_badge: Dictionary = Dictionary(progress_variant)
			if String(progress_badge.get("badge_key", "")).strip_edges() == "enemy":
				continue
			display_badges.append(progress_badge)
	else:
		display_badges = badges.duplicate(true)
		if display_badges.is_empty():
			for progress_variant in progress:
				if typeof(progress_variant) != TYPE_DICTIONARY:
					continue
				var progress_badge: Dictionary = Dictionary(progress_variant)
				if bool(progress_badge.get("achieved", false)):
					continue
				display_badges.append(progress_badge)
				if display_badges.size() >= 3:
					break
	if display_badges.is_empty():
		return
	var badge_grid := GridContainer.new()
	badge_grid.name = "RankBadgeGrid"
	badge_grid.columns = 3 if show_progress_badges else clampi(display_badges.size(), 1, 3)
	_set_help_id(badge_grid, "character_sheet.rank_badges")
	badge_grid.add_theme_constant_override("h_separation", 12 if show_progress_badges else 8)
	badge_grid.add_theme_constant_override("v_separation", 5)
	host.add_child(badge_grid)
	for badge_variant in display_badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var badge_key: String = String(badge.get("badge_key", badge.get("badge_id", "unknown"))).strip_edges()
		var badge_cell := VBoxContainer.new()
		badge_cell.name = "RankBadgeCell_%s" % badge_key
		badge_cell.custom_minimum_size = Vector2(58.0 if show_progress_badges else 44.0, 0.0)
		badge_cell.add_theme_constant_override("separation", 2)
		_set_help_id(badge_cell, "character_sheet.rank_badges")
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_cell, badge)
		var icon_holder := CenterContainer.new()
		icon_holder.name = "RankBadgeIconHolder_%s" % badge_key
		badge_cell.add_child(icon_holder)
		var texture_rect := TextureRect.new()
		texture_rect.name = "RankBadge_%s" % badge_key
		_set_help_id(texture_rect, "character_sheet.rank_badges")
		texture_rect.custom_minimum_size = Vector2(20.0, 20.0)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.set_meta("rank_badge_progress_candidate", show_progress_badges)
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", texture_rect, badge)
		var badge_path: String = String(badge.get("path", "")).strip_edges()
		if not badge_path.is_empty() and ResourceLoader.exists(badge_path):
			texture_rect.texture = load(badge_path) as Texture2D
		if not bool(badge.get("achieved", true)):
			texture_rect.modulate = Color(0.42, 0.45, 0.48, 0.52)
			texture_rect.set_meta("rank_badge_locked", true)
		if texture_rect.texture == null:
			texture_rect.modulate = Color(1.0, 0.45, 0.35, 0.95) if bool(badge.get("achieved", true)) else Color(0.50, 0.34, 0.32, 0.64)
			texture_rect.set_meta("missing_rank_badge_asset", true)
		icon_holder.add_child(texture_rect)
		var badge_label := Label.new()
		badge_label.name = "RankBadgeLabel_%s" % badge_key
		badge_label.text = String(badge.get("label", "Badge")).strip_edges()
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		badge_label.max_lines_visible = 2
		badge_label.custom_minimum_size = Vector2(58.0 if show_progress_badges else 44.0, 0.0)
		badge_label.add_theme_font_size_override("font_size", 8 if show_progress_badges else 9)
		badge_label.modulate = Color(0.78, 0.86, 0.90, 0.94) if bool(badge.get("achieved", true)) else Color(0.52, 0.58, 0.62, 0.72)
		_set_help_id(badge_label, "character_sheet.rank_badges")
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_label, badge)
		badge_cell.add_child(badge_label)
		badge_grid.add_child(badge_cell)


static func _add_next_rank_requirement(host: VBoxContainer, profile) -> void:
	var next_badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_next_badge_requirements", profile, 3))
	if next_badges.is_empty():
		return
	var lines := PackedStringArray()
	lines.append("Naechster Rang:")
	for badge_variant in next_badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var requirement: String = String(badge.get("requirement_text", "")).strip_edges()
		if requirement.is_empty():
			continue
		lines.append("%s: %s" % [String(badge.get("label", "Badge")), requirement])
	if lines.size() <= 1:
		return
	var requirement_label := Label.new()
	requirement_label.name = "NextRankRequirementLabel"
	requirement_label.text = "\n".join(lines)
	requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	requirement_label.custom_minimum_size = Vector2(220.0, 0.0)
	requirement_label.modulate = Color(0.72, 0.82, 0.86, 0.94)
	_set_help_id(requirement_label, "character_sheet.rank_badges")
	META_UI_SKIN_SCRIPT.style_body_label(requirement_label, 9)
	host.add_child(requirement_label)


static func _add_text_section(host: VBoxContainer, title: String, body_text: String) -> void:
	_add_section_header(host, title)
	var body_label := Label.new()
	body_label.text = body_text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_help_id(body_label, String(SECTION_HELP_IDS.get(title, "")))
	META_UI_SKIN_SCRIPT.style_body_label(body_label, 10)
	host.add_child(body_label)


static func _add_trait_section(host: VBoxContainer, trait_text: String, trait_rows: Array) -> void:
	_add_section_header(host, "TRAIT:")
	if trait_rows.is_empty():
		var body_label := Label.new()
		body_label.text = trait_text
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_set_help_id(body_label, "character_sheet.traits")
		META_UI_SKIN_SCRIPT.style_body_label(body_label, 10)
		host.add_child(body_label)
		return
	var section_vbox := VBoxContainer.new()
	section_vbox.name = "TraitRows"
	section_vbox.add_theme_constant_override("separation", 4)
	_set_help_id(section_vbox, "character_sheet.traits")
	host.add_child(section_vbox)
	for row_variant in trait_rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = Dictionary(row_variant)
		var help_id: String = String(row_data.get("help_id", "character_sheet.traits")).strip_edges()
		var detail_text: String = String(row_data.get("detail_text", "")).strip_edges()
		var row := VBoxContainer.new()
		row.name = "TraitRow_%s" % _sanitize_node_fragment(String(row_data.get("trait_id", row_data.get("label", "trait"))))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 1)
		row.tooltip_text = detail_text
		_set_help_id(row, help_id)
		section_vbox.add_child(row)
		var title_label := Label.new()
		title_label.name = "TraitLabel_%s" % _sanitize_node_fragment(String(row_data.get("trait_id", row_data.get("label", "trait"))))
		title_label.text = "%s  [%s]" % [String(row_data.get("label", "Trait")), String(row_data.get("value_text", "TAG"))]
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.tooltip_text = detail_text
		_set_help_id(title_label, help_id)
		META_UI_SKIN_SCRIPT.style_body_label(title_label, 10)
		row.add_child(title_label)
		if not detail_text.is_empty():
			var detail_label := Label.new()
			detail_label.name = "TraitDetail_%s" % _sanitize_node_fragment(String(row_data.get("trait_id", row_data.get("label", "trait"))))
			detail_label.text = detail_text
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail_label.modulate = Color(0.72, 0.82, 0.86, 0.92)
			detail_label.tooltip_text = detail_text
			_set_help_id(detail_label, help_id)
			META_UI_SKIN_SCRIPT.style_body_label(detail_label, 9)
			row.add_child(detail_label)


static func _add_bar_section(host: VBoxContainer, title: String, rows: Array, profile = null, options: Dictionary = {}) -> void:
	_add_section_header(host, title)
	_add_bar_rows(host, rows, profile, options)


static func _add_bar_rows(host: VBoxContainer, rows: Array, profile = null, options: Dictionary = {}) -> void:
	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)
	var metric_group_budget: Dictionary = _build_metric_group_budget(rows, options)
	if not metric_group_budget.is_empty():
		var budget_label := _add_metric_group_budget_row(section_vbox, metric_group_budget)
		metric_group_budget["label_node"] = budget_label

	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = Dictionary(row_variant)
		if not metric_group_budget.is_empty():
			row_data["metric_group_budget"] = metric_group_budget
		_add_metric_editor_row(section_vbox, row_data, profile, options)
	if not metric_group_budget.is_empty():
		_sync_metric_group_visuals(metric_group_budget)


static func _add_value_section(host: VBoxContainer, title: String, rows: Array, profile = null, options: Dictionary = {}) -> void:
	if rows.is_empty():
		return
	_add_section_header(host, title)
	_add_value_rows(host, rows, profile, options, title)


static func _add_value_rows(host: VBoxContainer, rows: Array, profile = null, options: Dictionary = {}, title: String = "") -> void:
	var section_vbox := VBoxContainer.new()
	section_vbox.add_theme_constant_override("separation", 4)
	host.add_child(section_vbox)
	if title == "ABGELEITET:":
		_add_derived_dependency_guide(section_vbox)
	var metric_group_budget: Dictionary = _build_metric_group_budget(rows, options)
	if not metric_group_budget.is_empty():
		var budget_label := _add_metric_group_budget_row(section_vbox, metric_group_budget)
		metric_group_budget["label_node"] = budget_label

	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = Dictionary(row_variant)
		if row_data.has("value"):
			if not metric_group_budget.is_empty():
				row_data["metric_group_budget"] = metric_group_budget
			_add_metric_editor_row(section_vbox, row_data, profile, options)
			continue
		if title == "ABGELEITET:":
			_add_stacked_value_row(section_vbox, row_data)
			continue
		var style_key: String = String(row_data.get("style_key", "")).strip_edges()
		var is_post_mission_award: bool = style_key == "post_mission_award"
		var row_panel: PanelContainer = null
		if is_post_mission_award:
			row_panel = PanelContainer.new()
			row_panel.name = "PostMissionAwardHighlightRow"
			row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row_panel.add_theme_stylebox_override("panel", _build_post_mission_award_stylebox())
			row_panel.set_meta("style_id", String(row_data.get("style_id", "")))
			_set_help_id(row_panel, String(row_data.get("help_id", "")))
			row_panel.tooltip_text = String(row_data.get("detail_text", row_data.get("effect_text", ""))).strip_edges()
			section_vbox.add_child(row_panel)
		var row := HBoxContainer.new()
		row.name = "PostMissionAwardValueRow" if is_post_mission_award else "ValueRow_%s" % _sanitize_node_fragment(String(row_data.get("label", "value")))
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		var help_id: String = String(row_data.get("help_id", ""))
		var detail_text: String = String(row_data.get("detail_text", row_data.get("effect_text", ""))).strip_edges()
		_set_help_id(row, help_id)
		row.tooltip_text = detail_text
		if is_post_mission_award:
			row.set_meta("style_id", String(row_data.get("style_id", "")))
			row_panel.add_child(row)
		else:
			section_vbox.add_child(row)

		var label := Label.new()
		label.name = "PostMissionAwardLabel" if is_post_mission_award else "ValueLabel_%s" % _sanitize_node_fragment(String(row_data.get("label", "value")))
		var row_label_text: String = "%s:" % String(row_data.get("label", "Value"))
		if is_post_mission_award:
			row_label_text = "%s | %s" % [String(row_data.get("badge_text", "MISSION GAIN")), row_label_text]
		label.text = row_label_text
		label.custom_minimum_size = Vector2(168.0 if is_post_mission_award else ROW_LABEL_WIDTH, 0.0)
		_set_help_id(label, help_id)
		label.tooltip_text = detail_text
		META_UI_SKIN_SCRIPT.style_body_label(label, 10)
		if is_post_mission_award:
			label.add_theme_color_override("font_color", Color("ffe9a3"))
		row.add_child(label)

		var value_vbox := VBoxContainer.new()
		value_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_vbox.add_theme_constant_override("separation", 1)
		row.add_child(value_vbox)
		var value_label := Label.new()
		value_label.name = "PostMissionAwardValue" if is_post_mission_award else "ValueText_%s" % _sanitize_node_fragment(String(row_data.get("label", "value")))
		value_label.text = String(row_data.get("value_text", "n/a"))
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_set_help_id(value_label, help_id)
		value_label.tooltip_text = detail_text
		META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
		if is_post_mission_award:
			value_label.add_theme_color_override("font_color", Color("f4fbff"))
		value_vbox.add_child(value_label)
		if not detail_text.is_empty():
			var detail_label := Label.new()
			detail_label.name = "DerivedDetail_%s" % _sanitize_node_fragment(String(row_data.get("label", "detail")))
			detail_label.text = detail_text
			detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail_label.modulate = Color(0.72, 0.82, 0.86, 0.92)
			_set_help_id(detail_label, help_id)
			detail_label.tooltip_text = detail_text
			META_UI_SKIN_SCRIPT.style_body_label(detail_label, 9)
			value_vbox.add_child(detail_label)
	if not metric_group_budget.is_empty():
		_sync_metric_group_visuals(metric_group_budget)


static func _add_stacked_value_row(host: VBoxContainer, row_data: Dictionary) -> void:
	var help_id: String = String(row_data.get("help_id", ""))
	var detail_text: String = String(row_data.get("detail_text", row_data.get("effect_text", ""))).strip_edges()
	var row := VBoxContainer.new()
	row.name = "StackedValueRow_%s" % _sanitize_node_fragment(String(row_data.get("label", "value")))
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 2)
	_set_help_id(row, help_id)
	row.tooltip_text = detail_text
	host.add_child(row)

	var label := Label.new()
	label.text = "%s:" % String(row_data.get("label", "Value"))
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_help_id(label, help_id)
	label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(label, 10)
	row.add_child(label)

	var value_label := Label.new()
	value_label.text = String(row_data.get("value_text", "n/a"))
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.custom_minimum_size = Vector2(DERIVED_TEXT_MIN_WIDTH, 0.0)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_set_help_id(value_label, help_id)
	value_label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
	row.add_child(value_label)

	if detail_text.is_empty():
		return
	var detail_label := Label.new()
	detail_label.name = "DerivedDetail_%s" % _sanitize_node_fragment(String(row_data.get("label", "detail")))
	detail_label.text = detail_text
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.custom_minimum_size = Vector2(DERIVED_TEXT_MIN_WIDTH, 0.0)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.modulate = Color(0.72, 0.82, 0.86, 0.92)
	_set_help_id(detail_label, help_id)
	detail_label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(detail_label, 9)
	row.add_child(detail_label)


static func _add_derived_dependency_guide(host: VBoxContainer) -> void:
	var guide := VBoxContainer.new()
	guide.name = "DerivedDependencyGuide"
	guide.add_theme_constant_override("separation", 2)
	_set_help_id(guide, "character_sheet.derived_badges")
	guide.tooltip_text = "Zeigt kompakt, welche sichtbaren Werte die abgeleiteten Zeilen speisen."
	host.add_child(guide)
	for link_variant in [
		{"from": "Kern + Verhalten + Traits", "to": "Method Tags"},
		{"from": "Skills + Plattform + Loadout", "to": "Function Scores"},
		{"from": "Hohe Function Scores", "to": "Primary / Secondary"},
	]:
		var link: Dictionary = Dictionary(link_variant)
		var row := HBoxContainer.new()
		row.name = "DerivedDependencyLink_%s" % _sanitize_node_fragment(String(link.get("to", "derived")))
		row.add_theme_constant_override("separation", 5)
		_set_help_id(row, "character_sheet.derived_badges")
		guide.add_child(row)
		var line := ColorRect.new()
		line.custom_minimum_size = Vector2(18.0, 2.0)
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.color = Color(0.38, 0.82, 0.82, 0.85)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(line)
		var label := Label.new()
		label.text = "%s -> %s" % [String(link.get("from", "")), String(link.get("to", ""))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.custom_minimum_size = Vector2(DERIVED_TEXT_MIN_WIDTH, 0.0)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.modulate = Color(0.70, 0.88, 0.88, 0.95)
		_set_help_id(label, "character_sheet.derived_badges")
		META_UI_SKIN_SCRIPT.style_body_label(label, 9)
		row.add_child(label)


static func _filter_metric_rows(rows: Array, include_metric_rows: bool) -> Array:
	var result: Array = []
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = Dictionary(row_variant)
		if row_data.has("value") == include_metric_rows:
			result.append(row_data)
	return result


static func _add_grouped_metric_sections(host: VBoxContainer, model: Dictionary, profile = null, options: Dictionary = {}) -> void:
	var groups: Array = [
		{"title": "STATUSWERTE:", "rows": _filter_metric_rows(Array(model.get("status_rows", [])), true)},
		{"title": "KERNWERTE (0,00 - 1,00):", "rows": _filter_metric_rows(Array(model.get("core_rows", [])), true)},
		{"title": "KOMMUNIKATION:", "rows": _filter_metric_rows(Array(model.get("communication_rows", [])), true)},
		{"title": "PLATTFORM-SKILLS (nur falls relevant):", "rows": _filter_metric_rows(Array(model.get("platform_rows", [])), true)},
		{"title": "VERHALTENSPROFIL:", "rows": _filter_metric_rows(Array(model.get("behavior_rows", [])), true)},
	]
	var has_metric_rows: bool = false
	for group_variant in groups:
		var group: Dictionary = Dictionary(group_variant)
		if not Array(group.get("rows", [])).is_empty():
			has_metric_rows = true
			break
	if not has_metric_rows:
		return
	_add_section_header(host, "WERTE / BUDGETS:")
	for group_variant in groups:
		var group: Dictionary = Dictionary(group_variant)
		var rows: Array = Array(group.get("rows", []))
		if rows.is_empty():
			continue
		_add_value_section(host, String(group.get("title", "WERTE:")), rows, profile, options)


static func _build_metric_group_budget(rows: Array, options: Dictionary) -> Dictionary:
	var budget_configs: Dictionary = Dictionary(options.get("metric_group_budgets", {}))
	if budget_configs.is_empty():
		return {}
	var group_id: String = ""
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = Dictionary(row_variant)
		var row_group: String = String(row_data.get("value_group", "")).strip_edges()
		if row_group.is_empty() or not row_data.has("value"):
			continue
		group_id = row_group
		break
	if group_id.is_empty() or not budget_configs.has(group_id):
		return {}
	var config: Dictionary = Dictionary(budget_configs.get(group_id, {}))
	var points_per_value: int = maxi(int(config.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1)
	var used_points: int = 0
	var row_count: int = 0
	for row_variant in rows:
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = Dictionary(row_variant)
		if String(row_data.get("value_group", "")).strip_edges() != group_id or not row_data.has("value"):
			continue
		used_points += _metric_value_to_points(float(row_data.get("value", 0.0)), points_per_value)
		row_count += 1
	if row_count <= 0:
		return {}
	var max_points: int = maxi(int(config.get("max_points", used_points)), 0)
	return {
		"group_id": group_id,
		"label": String(config.get("label", group_id.capitalize())),
		"help_id": String(config.get("help_id", METRIC_GROUP_BUDGET_HELP_ID)),
		"max_points": max_points,
		"used_points": used_points,
		"available_points": maxi(max_points - used_points, 0),
		"points_per_value": points_per_value,
		"rows": [],
	}


static func _add_metric_group_budget_row(host: VBoxContainer, budget: Dictionary) -> Label:
	var label := Label.new()
	label.name = "MetricGroupBudget_%s" % _sanitize_node_fragment(String(budget.get("group_id", "group")))
	_set_help_id(label, METRIC_GROUP_BUDGET_HELP_ID)
	label.tooltip_text = "Punktekontingent fuer diese Werte-Gruppe. Gesperrte Balken bleiben bei Budget-Aenderungen unveraendert."
	META_UI_SKIN_SCRIPT.style_body_label(label, 9)
	label.modulate = Color(0.72, 0.86, 0.78, 0.96)
	label.text = _format_metric_group_budget_text(budget)
	host.add_child(label)
	return label


static func _format_metric_group_budget_text(budget: Dictionary) -> String:
	var used_points: int = int(budget.get("used_points", 0))
	var max_points: int = int(budget.get("max_points", 0))
	var available_points: int = maxi(max_points - used_points, 0)
	var over_text: String = " | ueber Cap %d" % maxi(used_points - max_points, 0) if used_points > max_points else ""
	return "Budget %s %d/%d | frei %d%s" % [
		String(budget.get("label", "Gruppe")),
		used_points,
		max_points,
		available_points,
		over_text,
	]


static func _metric_lock_key(row_data: Dictionary) -> String:
	var value_group: String = String(row_data.get("value_group", "")).strip_edges()
	var value_key: String = String(row_data.get("value_key", "")).strip_edges()
	if value_group.is_empty() or value_key.is_empty():
		return ""
	return "%s.%s" % [value_group, value_key]


static func _metric_row_is_locked(row_data: Dictionary, options: Dictionary) -> bool:
	var lock_key: String = _metric_lock_key(row_data)
	if lock_key.is_empty():
		return false
	var locks: Dictionary = Dictionary(options.get("metric_locks", {}))
	return bool(locks.get(lock_key, false))


static func _metric_value_to_points(value: float, points_per_value: int) -> int:
	return roundi(clampf(value, 0.0, 1.0) * float(maxi(points_per_value, 1)))


static func _metric_row_points(row_data: Dictionary) -> int:
	var budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
	var points_per_value: int = maxi(int(budget.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1)
	return _metric_value_to_points(float(row_data.get("value", 0.0)), points_per_value)


static func _metric_row_is_active_candidate(candidate_row: Dictionary, active_row: Dictionary) -> bool:
	return String(candidate_row.get("value_group", "")) == String(active_row.get("value_group", "")) and String(candidate_row.get("value_key", "")) == String(active_row.get("value_key", ""))


static func _metric_available_raise_points(row_data: Dictionary) -> int:
	if bool(row_data.get("metric_locked", false)):
		return 0
	var budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
	var current_points: int = _metric_row_points(row_data)
	var row_capacity: int = maxi(maxi(int(budget.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1) - current_points, 0)
	if budget.is_empty():
		return row_capacity
	var used_points: int = int(budget.get("used_points", 0))
	var max_points: int = int(budget.get("max_points", used_points))
	var free_points: int = maxi(max_points - used_points, 0)
	var takeable_points: int = 0
	for other_variant in Array(budget.get("rows", [])):
		if typeof(other_variant) != TYPE_DICTIONARY:
			continue
		var other_row: Dictionary = other_variant
		if _metric_row_is_active_candidate(other_row, row_data) or bool(other_row.get("metric_locked", false)):
			continue
		takeable_points += _metric_row_points(other_row)
	return mini(row_capacity, free_points + takeable_points)


static func _constrain_metric_value_by_budget(row_data: Dictionary, target_value: float) -> float:
	var normalized_target: float = clampf(target_value, 0.0, 1.0)
	var budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
	if budget.is_empty() or normalized_target <= float(row_data.get("value", 0.0)):
		return normalized_target
	var points_per_value: int = maxi(int(budget.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1)
	var current_points: int = _metric_value_to_points(float(row_data.get("value", 0.0)), points_per_value)
	var max_target_points: int = clampi(current_points + _metric_available_raise_points(row_data), 0, points_per_value)
	var requested_points: int = _metric_value_to_points(normalized_target, points_per_value)
	return float(clampi(requested_points, 0, max_target_points)) / float(points_per_value)


static func _metric_can_apply_delta(row_data: Dictionary, delta: float) -> bool:
	var current_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
	if delta < 0.0:
		return current_value > 0.001
	return _metric_available_raise_points(row_data) > 0


static func _set_metric_row_value(row_data: Dictionary, next_value: float) -> void:
	var normalized_value: float = clampf(next_value, 0.0, 1.0)
	row_data["value"] = normalized_value
	row_data["value_text"] = _format_decimal_comma(normalized_value)


static func _commit_metric_value_with_budget(profile, row_data: Dictionary, target_value: float) -> float:
	if bool(row_data.get("metric_locked", false)):
		_sync_metric_row_visuals(row_data)
		return clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
	var budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
	if budget.is_empty():
		var next_value_no_budget: float = clampf(target_value, 0.0, 1.0)
		_apply_profile_metric_value(profile, row_data, next_value_no_budget)
		_set_metric_row_value(row_data, next_value_no_budget)
		_sync_metric_row_visuals(row_data)
		return next_value_no_budget
	var points_per_value: int = maxi(int(budget.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1)
	var current_points: int = _metric_row_points(row_data)
	var requested_points: int = _metric_value_to_points(target_value, points_per_value)
	if requested_points > current_points:
		requested_points = mini(requested_points, current_points + _metric_available_raise_points(row_data))
		var used_points: int = int(budget.get("used_points", 0))
		var max_points: int = int(budget.get("max_points", used_points))
		var free_points: int = maxi(max_points - used_points, 0)
		var points_to_take: int = maxi(requested_points - current_points - free_points, 0)
		if points_to_take > 0:
			_take_metric_points_from_unlocked_rows(budget, row_data, points_to_take, profile)
	var next_value: float = float(clampi(requested_points, 0, points_per_value)) / float(points_per_value)
	_apply_profile_metric_value(profile, row_data, next_value)
	_set_metric_row_value(row_data, next_value)
	_recalculate_metric_budget(budget)
	_sync_metric_group_visuals(budget)
	return next_value


static func _take_metric_points_from_unlocked_rows(budget: Dictionary, active_row: Dictionary, requested_points: int, profile) -> int:
	var remaining_points: int = maxi(requested_points, 0)
	var candidates: Array = []
	for other_variant in Array(budget.get("rows", [])):
		if typeof(other_variant) != TYPE_DICTIONARY:
			continue
		var other_row: Dictionary = other_variant
		if _metric_row_is_active_candidate(other_row, active_row) or bool(other_row.get("metric_locked", false)):
			continue
		var points: int = _metric_row_points(other_row)
		if points > 0:
			candidates.append({"row": other_row, "points": points})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("points", 0)) > int(b.get("points", 0))
	)
	for candidate_variant in candidates:
		if remaining_points <= 0:
			break
		var candidate: Dictionary = Dictionary(candidate_variant)
		var other_row_variant: Variant = candidate.get("row", {})
		if typeof(other_row_variant) != TYPE_DICTIONARY:
			continue
		var other_row: Dictionary = other_row_variant
		var current_points: int = _metric_row_points(other_row)
		var taken_points: int = mini(current_points, remaining_points)
		var next_points: int = current_points - taken_points
		var next_value: float = float(next_points) / float(maxi(int(budget.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1))
		_apply_profile_metric_value(profile, other_row, next_value)
		_set_metric_row_value(other_row, next_value)
		remaining_points -= taken_points
	return requested_points - remaining_points


static func _recalculate_metric_budget(budget: Dictionary) -> void:
	if budget.is_empty():
		return
	var used_points: int = 0
	for row_variant in Array(budget.get("rows", [])):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_variant
		used_points += _metric_row_points(row_data)
	var max_points: int = int(budget.get("max_points", used_points))
	budget["used_points"] = used_points
	budget["available_points"] = maxi(max_points - used_points, 0)
	_refresh_metric_group_budget_label(budget)


static func _sync_metric_group_visuals(budget: Dictionary) -> void:
	if budget.is_empty():
		return
	for row_variant in Array(budget.get("rows", [])):
		if typeof(row_variant) != TYPE_DICTIONARY:
			continue
		var row_data: Dictionary = row_variant
		_sync_metric_row_visuals(row_data)
	_refresh_metric_group_budget_label(budget)


static func _sync_metric_row_visuals(row_data: Dictionary) -> void:
	var controls: Dictionary = Dictionary(row_data.get("metric_controls", {}))
	var normalized_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
	var slider_variant: Variant = controls.get("slider", null)
	if slider_variant is HSlider and is_instance_valid(slider_variant):
		var slider := slider_variant as HSlider
		slider.set_value_no_signal(normalized_value)
		slider.editable = not bool(row_data.get("metric_locked", false))
	var value_label_variant: Variant = controls.get("value_label", null)
	if value_label_variant is Label and is_instance_valid(value_label_variant):
		var value_label := value_label_variant as Label
		value_label.text = String(row_data.get("value_text", _format_decimal_comma(normalized_value)))
	var minus_variant: Variant = controls.get("minus", null)
	if minus_variant is Button and is_instance_valid(minus_variant):
		var minus_button := minus_variant as Button
		minus_button.disabled = bool(row_data.get("metric_locked", false)) or normalized_value <= 0.001
	var plus_variant: Variant = controls.get("plus", null)
	if plus_variant is Button and is_instance_valid(plus_variant):
		var plus_button := plus_variant as Button
		plus_button.disabled = bool(row_data.get("metric_locked", false)) or normalized_value >= 0.999 or not _metric_can_apply_delta(row_data, VALUE_STEP)
	var lock_variant: Variant = controls.get("lock", null)
	if lock_variant is Button and is_instance_valid(lock_variant):
		var lock_button := lock_variant as Button
		lock_button.set_pressed_no_signal(bool(row_data.get("metric_locked", false)))


static func _update_metric_budget_after_value_change(row_data: Dictionary, previous_value: float, next_value: float) -> void:
	var budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
	if budget.is_empty():
		return
	var points_per_value: int = maxi(int(budget.get("points_per_value", METRIC_POINTS_PER_VALUE)), 1)
	var previous_points: int = _metric_value_to_points(previous_value, points_per_value)
	var next_points: int = _metric_value_to_points(next_value, points_per_value)
	var used_points: int = maxi(int(budget.get("used_points", 0)) - previous_points + next_points, 0)
	var max_points: int = int(budget.get("max_points", used_points))
	budget["used_points"] = used_points
	budget["available_points"] = maxi(max_points - used_points, 0)
	row_data["metric_group_budget"] = budget
	_refresh_metric_group_budget_label(budget)


static func _refresh_metric_group_budget_label(budget: Dictionary) -> void:
	var label_variant: Variant = budget.get("label_node", null)
	if label_variant is Label and is_instance_valid(label_variant):
		var label := label_variant as Label
		label.text = _format_metric_group_budget_text(budget)


static func _emit_metric_lock_changed(options: Dictionary, row_data: Dictionary, locked: bool) -> void:
	var callback_variant: Variant = options.get("on_metric_lock_changed", null)
	if typeof(callback_variant) != TYPE_CALLABLE:
		return
	var callback: Callable = callback_variant
	if not callback.is_valid():
		return
	callback.call({
		"value_group": String(row_data.get("value_group", "")),
		"value_key": String(row_data.get("value_key", "")),
		"help_id": String(row_data.get("help_id", "")),
	}, locked)


static func _metric_controls_are_editable(options: Dictionary) -> bool:
	return bool(options.get("editable_metrics", true))


static func _add_metric_read_only_row(host: VBoxContainer, row_data: Dictionary) -> void:
	var help_id: String = String(row_data.get("help_id", ""))
	var detail_text: String = String(row_data.get("detail_text", row_data.get("effect_text", ""))).strip_edges()
	var metric_fragment: String = _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	var normalized_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
	var row := HBoxContainer.new()
	row.name = "ReadOnlyMetricRow_%s" % metric_fragment
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	_set_help_id(row, help_id)
	row.tooltip_text = detail_text
	host.add_child(row)

	var label := Label.new()
	label.name = "ReadOnlyMetricLabel_%s" % metric_fragment
	label.text = "%s:" % String(row_data.get("label", "Metric"))
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	_set_help_id(label, help_id)
	label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(label, 10)
	row.add_child(label)

	var value_label := Label.new()
	value_label.name = "ReadOnlyMetricValue_%s" % metric_fragment
	value_label.custom_minimum_size = Vector2(ROW_VALUE_WIDTH, 22.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.text = String(row_data.get("value_text", _format_decimal_comma(normalized_value)))
	_set_help_id(value_label, help_id)
	value_label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
	row.add_child(value_label)

	var bar := ProgressBar.new()
	bar.name = "ReadOnlyMetricBar_%s" % metric_fragment
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size = Vector2(0.0, 18.0)
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = normalized_value
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_help_id(bar, help_id)
	bar.tooltip_text = detail_text
	row.add_child(bar)


static func _add_metric_editor_row(host: VBoxContainer, row_data: Dictionary, profile = null, options: Dictionary = {}) -> void:
	if not _metric_controls_are_editable(options):
		_add_metric_read_only_row(host, row_data)
		return
	var help_id: String = String(row_data.get("help_id", ""))
	var detail_text: String = String(row_data.get("detail_text", row_data.get("effect_text", ""))).strip_edges()
	var metric_fragment: String = _sanitize_node_fragment(String(row_data.get("value_key", row_data.get("label", "metric"))))
	row_data["metric_locked"] = _metric_row_is_locked(row_data, options)
	var row := HBoxContainer.new()
	row.name = "EditableMetricRow_%s" % metric_fragment
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.focus_mode = Control.FOCUS_ALL
	row.add_theme_constant_override("separation", 5)
	_set_help_id(row, help_id)
	row.tooltip_text = detail_text
	host.add_child(row)

	var label := Label.new()
	label.name = "MetricLabel_%s" % metric_fragment
	label.text = "%s:" % String(row_data.get("label", "Metric"))
	label.custom_minimum_size = Vector2(ROW_LABEL_WIDTH, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	_set_help_id(label, help_id)
	label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(label, 10)
	row.add_child(label)

	var value_label := Label.new()
	value_label.name = "MetricValueLabel_%s" % metric_fragment
	value_label.custom_minimum_size = Vector2(ROW_VALUE_WIDTH, 22.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.set_meta("metric_value_position", "left_of_minus")
	_set_help_id(value_label, help_id)
	value_label.tooltip_text = detail_text
	META_UI_SKIN_SCRIPT.style_body_label(value_label, 10)
	row.add_child(value_label)

	var minus_button := Button.new()
	minus_button.name = "MetricMinus_%s" % metric_fragment
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(24.0, 22.0)
	minus_button.focus_mode = Control.FOCUS_ALL
	_set_help_id(minus_button, help_id)
	minus_button.tooltip_text = detail_text
	row.add_child(minus_button)

	var bar_host := Control.new()
	bar_host.name = "MetricBarHost_%s" % metric_fragment
	bar_host.custom_minimum_size = Vector2(0.0, 22.0)
	bar_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_help_id(bar_host, help_id)
	bar_host.tooltip_text = detail_text
	row.add_child(bar_host)

	var slider := HSlider.new()
	slider.name = "MetricSlider_%s" % metric_fragment
	slider.set_anchors_preset(Control.PRESET_FULL_RECT)
	slider.offset_left = 0.0
	slider.offset_top = 0.0
	slider.offset_right = 0.0
	slider.offset_bottom = 0.0
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = VALUE_STEP
	slider.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_help_id(slider, help_id)
	slider.tooltip_text = "%s\nMaus ziehen, Pfeiltasten oder Plus/Minus aendern diesen Wert." % detail_text
	bar_host.add_child(slider)

	var plus_button := Button.new()
	plus_button.name = "MetricPlus_%s" % metric_fragment
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(24.0, 22.0)
	plus_button.focus_mode = Control.FOCUS_ALL
	_set_help_id(plus_button, help_id)
	plus_button.tooltip_text = detail_text
	row.add_child(plus_button)

	var lock_button := Button.new()
	lock_button.name = "MetricLock_%s" % metric_fragment
	lock_button.toggle_mode = true
	lock_button.text = "L"
	lock_button.custom_minimum_size = Vector2(24.0, 22.0)
	lock_button.focus_mode = Control.FOCUS_ALL
	_set_help_id(lock_button, METRIC_LOCK_HELP_ID)
	lock_button.tooltip_text = "Diesen Balken sperren, damit er beim Ausgleichen des Punktekontingents nicht veraendert wird."
	row.add_child(lock_button)

	var initial_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
	row_data["metric_controls"] = {
		"slider": slider,
		"value_label": value_label,
		"minus": minus_button,
		"plus": plus_button,
		"lock": lock_button,
	}
	_set_metric_row_value(row_data, initial_value)
	var budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
	if not budget.is_empty():
		var budget_rows: Array = Array(budget.get("rows", []))
		budget_rows.append(row_data)
		budget["rows"] = budget_rows
		row_data["metric_group_budget"] = budget
	_sync_metric_row_visuals(row_data)

	slider.set_meta("metric_drag_active", false)
	slider.set_meta("metric_drag_pending", false)
	slider.set_meta("metric_drag_start_value", initial_value)
	slider.set_meta("metric_drag_preview_value", initial_value)
	var commit_value := func(target_value: float, emit_change: bool = true) -> bool:
		var current_value: float = clampf(float(row_data.get("value", 0.0)), 0.0, 1.0)
		var next_value: float = _commit_metric_value_with_budget(profile, row_data, target_value)
		if absf(next_value - current_value) <= 0.001:
			_sync_metric_row_visuals(row_data)
			return false
		if emit_change:
			_emit_metric_changed(options, profile, row_data, next_value)
		else:
			slider.set_meta("metric_drag_pending", true)
		return true
	var commit_delta := func(delta: float) -> void:
		commit_value.call(clampf(float(row_data.get("value", 0.0)) + delta, 0.0, 1.0), true)
	minus_button.pressed.connect(func() -> void:
		commit_delta.call(-VALUE_STEP)
	)
	plus_button.pressed.connect(func() -> void:
		commit_delta.call(VALUE_STEP)
	)
	slider.drag_started.connect(func() -> void:
		var drag_start_value: float = clampf(float(row_data.get("value", slider.value)), 0.0, 1.0)
		slider.set_meta("metric_drag_active", true)
		slider.set_meta("metric_drag_pending", false)
		slider.set_meta("metric_drag_start_value", drag_start_value)
		slider.set_meta("metric_drag_preview_value", drag_start_value)
	)
	slider.value_changed.connect(func(next_value: float) -> void:
		if bool(slider.get_meta("metric_drag_active", false)):
			var preview_value: float = clampf(next_value, 0.0, 1.0)
			slider.set_meta("metric_drag_pending", true)
			slider.set_meta("metric_drag_preview_value", preview_value)
			var controls: Dictionary = Dictionary(row_data.get("metric_controls", {}))
			var value_label_variant: Variant = controls.get("value_label", null)
			if value_label_variant is Label and is_instance_valid(value_label_variant):
				var preview_label := value_label_variant as Label
				preview_label.text = _format_decimal_comma(preview_value)
			return
		commit_value.call(next_value, true)
	)
	slider.drag_ended.connect(func(_value_changed: bool) -> void:
		slider.set_meta("metric_drag_active", false)
		if not bool(slider.get_meta("metric_drag_pending", false)):
			return
		slider.set_meta("metric_drag_pending", false)
		row_data["value"] = clampf(float(slider.get_meta("metric_drag_start_value", row_data.get("value", 0.0))), 0.0, 1.0)
		commit_value.call(clampf(float(slider.get_meta("metric_drag_preview_value", slider.value)), 0.0, 1.0), true)
	)
	lock_button.toggled.connect(func(button_pressed: bool) -> void:
		row_data["metric_locked"] = button_pressed
		_emit_metric_lock_changed(options, row_data, button_pressed)
		var row_budget: Dictionary = Dictionary(row_data.get("metric_group_budget", {}))
		if row_budget.is_empty():
			_sync_metric_row_visuals(row_data)
		else:
			_sync_metric_group_visuals(row_budget)
	)
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
	_set_help_id(section_vbox, "character_sheet.loadout_summary")
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
	_set_help_id(option, "character_sheet.loadout_summary")
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
	_set_help_id(preview, "character_sheet.loadout_summary")
	row.add_child(preview)

	var option := OptionButton.new()
	option.name = option_name
	option.custom_minimum_size = Vector2(146.0, 26.0)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.tooltip_text = "Letzte Waffe. Andere Optionen sind ausgegraut, bis Loadout-Aenderungen ueber die FOB laufen."
	_set_help_id(option, "character_sheet.loadout_summary")
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
	_set_help_id(row, "character_sheet.loadout_summary")
	var label := Label.new()
	label.text = "%s:" % label_text
	label.custom_minimum_size = Vector2(72.0, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	_set_help_id(label, "character_sheet.loadout_summary")
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
	callback.call(profile, _build_metric_signal_payload(row_data, next_value), clampf(next_value, 0.0, 1.0))


static func _build_metric_signal_payload(row_data: Dictionary, next_value: float) -> Dictionary:
	return {
		"value_group": String(row_data.get("value_group", "")),
		"value_key": String(row_data.get("value_key", "")),
		"label": String(row_data.get("label", "")),
		"help_id": String(row_data.get("help_id", "")),
		"detail_text": String(row_data.get("detail_text", row_data.get("effect_text", ""))),
		"effect_text": String(row_data.get("effect_text", "")),
		"value": clampf(next_value, 0.0, 1.0),
		"value_text": String(row_data.get("value_text", _format_decimal_comma(next_value))),
		"metric_locked": bool(row_data.get("metric_locked", false)),
	}


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


static func _build_post_mission_award_stylebox() -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color("25353a")
	stylebox.border_color = Color("d8b950")
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
