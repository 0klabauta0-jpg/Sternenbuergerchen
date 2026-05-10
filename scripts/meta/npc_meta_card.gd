class_name NPCMetaCard
extends PanelContainer

const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

signal card_pressed(unit_id, profile)

var _profile = null
var _is_selectable: bool = false
var _is_selected: bool = false
var _is_disabled: bool = false
var _show_status_line: bool = true


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(220.0, 0.0)
	set_meta("badge_layout_contract", "right_of_main_text")
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_ui()
	_refresh_card()


func setup_from_profile(profile, options: Dictionary = {}) -> void:
	if typeof(profile) == TYPE_OBJECT and profile != null and profile.has_method("duplicate_profile"):
		_profile = profile.duplicate_profile()
	elif typeof(profile) == TYPE_DICTIONARY:
		_profile = META_UNIT_PROFILE_SCRIPT.new(profile)
	else:
		_profile = META_UNIT_PROFILE_SCRIPT.new()

	_is_selectable = bool(options.get("selectable", _is_selectable))
	_is_selected = bool(options.get("selected", _is_selected))
	_is_disabled = bool(options.get("disabled", _is_disabled))
	_show_status_line = bool(options.get("show_status_line", _show_status_line))

	if is_inside_tree():
		_refresh_card()


func set_interaction_state(selectable: bool, selected: bool, disabled: bool = false) -> void:
	_is_selectable = selectable
	_is_selected = selected
	_is_disabled = disabled
	if is_inside_tree():
		_refresh_card()


func set_show_status_line(show_status_line: bool) -> void:
	_show_status_line = show_status_line
	if is_inside_tree():
		_refresh_card()


func get_unit_id() -> String:
	if _profile == null:
		return ""

	return String(_profile.unit_id)


func get_profile():
	if _profile == null or not _profile.has_method("duplicate_profile"):
		return null

	return _profile.duplicate_profile()


func get_card_userology_snapshot() -> Dictionary:
	var badge_row := get_node_or_null("Margin/VBox/BadgeRow") as HBoxContainer
	var min_badge_size: Vector2 = Vector2.ZERO
	if badge_row != null and badge_row.get_child_count() > 0:
		var first_badge := badge_row.get_child(0) as Control
		min_badge_size = first_badge.custom_minimum_size if first_badge != null else Vector2.ZERO
	return {
		"unit_id": get_unit_id(),
		"badge_layout": "right_of_main_text",
		"badge_minimum_size": min_badge_size,
		"badge_tooltips_available": _badge_tooltips_available(badge_row),
		"character_sheet_compatible": true,
	}


func _gui_input(event: InputEvent) -> void:
	if not _can_emit_press():
		return

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			card_pressed.emit(get_unit_id(), get_profile())
			accept_event()


func _ensure_ui() -> void:
	if get_node_or_null("Margin") != null:
		return

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	var skills_label := Label.new()
	skills_label.name = "SkillsLabel"
	skills_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(skills_label)

	var traits_label := Label.new()
	traits_label.name = "TraitsLabel"
	traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(traits_label)

	var badge_row := HBoxContainer.new()
	badge_row.name = "BadgeRow"
	badge_row.add_theme_constant_override("separation", 4)
	vbox.add_child(badge_row)

	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(status_label)


func _refresh_card() -> void:
	_ensure_ui()
	var name_label: Label = get_node("Margin/VBox/NameLabel")
	var skills_label: Label = get_node("Margin/VBox/SkillsLabel")
	var traits_label: Label = get_node("Margin/VBox/TraitsLabel")
	var badge_row: HBoxContainer = get_node("Margin/VBox/BadgeRow")
	var status_label: Label = get_node("Margin/VBox/StatusLabel")

	var display_name: String = "Unknown Unit"
	var skill_summary_text: String = "A:0.0 S:0.0 L:0.0 T:0.0"
	var trait_summary_text: String = "-"
	var status_line: String = ""
	if _profile != null:
		display_name = String(_profile.display_name if not String(_profile.display_name).is_empty() else _profile.unit_id)
		skill_summary_text = String(_profile.skill_summary_text if not String(_profile.skill_summary_text).is_empty() else skill_summary_text)
		trait_summary_text = String(_profile.trait_summary_text if not String(_profile.trait_summary_text).is_empty() else trait_summary_text)
		status_line = _build_status_line()

	name_label.text = display_name
	skills_label.text = skill_summary_text
	traits_label.text = trait_summary_text
	_populate_badge_row(badge_row)
	status_label.text = status_line
	status_label.visible = _show_status_line and not status_line.is_empty()

	_apply_state_visuals(name_label, skills_label, traits_label, status_label)


func _apply_state_visuals(name_label: Label, skills_label: Label, traits_label: Label, status_label: Label) -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_right = 8
	stylebox.corner_radius_bottom_left = 8

	var name_color := Color(0.94, 0.96, 0.98, 1.0)
	var detail_color := Color(0.78, 0.82, 0.86, 1.0)
	var status_color := Color(0.72, 0.82, 0.98, 1.0)

	if _is_disabled:
		stylebox.bg_color = Color(0.11, 0.11, 0.12, 1.0)
		stylebox.border_color = Color(0.28, 0.28, 0.30, 1.0)
		name_color = Color(0.58, 0.60, 0.62, 1.0)
		detail_color = Color(0.46, 0.48, 0.50, 1.0)
		status_color = Color(0.46, 0.48, 0.50, 1.0)
	elif _is_selected:
		stylebox.bg_color = Color(0.16, 0.23, 0.18, 1.0)
		stylebox.border_color = Color(0.68, 0.84, 0.58, 1.0)
		status_color = Color(0.84, 0.93, 0.68, 1.0)
	elif _is_selectable:
		stylebox.bg_color = Color(0.13, 0.15, 0.18, 1.0)
		stylebox.border_color = Color(0.43, 0.55, 0.65, 1.0)
	else:
		stylebox.bg_color = Color(0.12, 0.12, 0.14, 1.0)
		stylebox.border_color = Color(0.30, 0.33, 0.37, 1.0)

	add_theme_stylebox_override("panel", stylebox)
	name_label.add_theme_color_override("font_color", name_color)
	skills_label.add_theme_color_override("font_color", detail_color)
	traits_label.add_theme_color_override("font_color", detail_color)
	status_label.add_theme_color_override("font_color", status_color)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _can_emit_press() else Control.CURSOR_ARROW


func _build_status_line() -> String:
	if _profile == null:
		return ""

	var lines: PackedStringArray = []
	var status_text: String = String(_profile.status_text).strip_edges()
	var secondary_text: String = String(_profile.secondary_text).strip_edges()
	if not status_text.is_empty():
		lines.append(status_text)
	if not secondary_text.is_empty() and secondary_text != status_text:
		lines.append(secondary_text)

	return " | ".join(lines)


func _populate_badge_row(badge_row: HBoxContainer) -> void:
	for child in badge_row.get_children():
		badge_row.remove_child(child)
		child.queue_free()
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", _profile))
	badge_row.visible = not badges.is_empty()
	for badge_variant in badges:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		var texture_rect := TextureRect.new()
		texture_rect.name = "RankBadge_%s" % String(badge.get("badge_key", badge.get("badge_id", "unknown"))).strip_edges()
		texture_rect.custom_minimum_size = META_USEROLOGY_CONTRACT_SCRIPT.get("MIN_BADGE_SIZE")
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		texture_rect.tooltip_text = "%s: %s" % [String(badge.get("label", "Badge")), String(badge.get("reason", ""))]
		var badge_path: String = String(badge.get("path", "")).strip_edges()
		if not badge_path.is_empty() and ResourceLoader.exists(badge_path):
			texture_rect.texture = load(badge_path) as Texture2D
		if texture_rect.texture == null:
			texture_rect.modulate = Color(1.0, 0.45, 0.35, 0.95)
			texture_rect.set_meta("missing_rank_badge_asset", true)
		badge_row.add_child(texture_rect)


func _badge_tooltips_available(badge_row: HBoxContainer) -> bool:
	if badge_row == null:
		return true
	for child in badge_row.get_children():
		var control := child as Control
		if control != null and control.visible and control.tooltip_text.strip_edges().is_empty():
			return false
	return true


func _can_emit_press() -> bool:
	return _is_selectable and not _is_disabled and _profile != null and _profile.is_valid()
