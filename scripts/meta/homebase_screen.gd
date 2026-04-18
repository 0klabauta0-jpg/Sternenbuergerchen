class_name HomebaseTestScreen
extends Control

const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const NPC_COMPACT_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_compact_card.tscn")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")

signal selection_changed(selected_unit_ids)
signal team_confirmed(selected_unit_ids)

var _available_units: Array = []
var _selected_unit_ids: PackedStringArray = []
var _profiles_by_id: Dictionary = {}
var _focused_unit_id: String = ""
var _roster_cards_by_unit_id: Dictionary = {}
var _staged_cards_by_unit_id: Dictionary = {}
var _team_feedback_text: String = ""


func _ready() -> void:
	var confirm_button: Button = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ConfirmButton")
	if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
		confirm_button.pressed.connect(_on_confirm_button_pressed)

	var team_drop_panel = _get_team_drop_panel()
	if team_drop_panel != null and not team_drop_panel.unit_dropped.is_connected(_on_team_drop_panel_unit_dropped):
		team_drop_panel.unit_dropped.connect(_on_team_drop_panel_unit_dropped)

	_rebuild_profiles()
	_rebuild_ui()


func setup_roster(available_units: Array, selected_unit_ids: PackedStringArray = []) -> void:
	_available_units = available_units.duplicate(true)
	_selected_unit_ids = _normalize_selected_unit_ids(selected_unit_ids)
	_team_feedback_text = ""
	if is_inside_tree():
		_rebuild_profiles()
		_rebuild_ui()


func set_selected_unit_ids(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = _normalize_selected_unit_ids(selected_unit_ids)
	_team_feedback_text = ""
	if is_inside_tree():
		_rebuild_ui()


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func confirm_selection() -> void:
	if _selected_unit_ids.is_empty():
		return

	team_confirmed.emit(get_selected_unit_ids())


func _rebuild_profiles() -> void:
	_profiles_by_id = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id(_available_units)


func _rebuild_ui() -> void:
	_ensure_focused_unit_id()
	_render_roster()
	_render_staged_team()
	_update_team_summary()
	_update_character_sheet()


func _render_roster() -> void:
	var roster_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList")
	_clear_container(roster_list)
	_roster_cards_by_unit_id.clear()

	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue

		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue

		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.setup_from_profile(
			profile,
			{
				"source_context": "roster",
				"selected": _selected_unit_ids.has(unit_id),
				"disabled": false,
				"drag_enabled": not _selected_unit_ids.has(unit_id),
			}
		)
		if not card.card_pressed.is_connected(_on_compact_card_pressed):
			card.card_pressed.connect(_on_compact_card_pressed)
		roster_list.add_child(card)
		_roster_cards_by_unit_id[unit_id] = card


func _render_staged_team() -> void:
	var selected_team_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList")
	_clear_container(selected_team_list)
	_staged_cards_by_unit_id.clear()

	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		selected_team_list.add_child(row)

		var card = NPC_COMPACT_CARD_SCENE.instantiate()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.setup_from_profile(
			profile,
			{
				"source_context": "staged",
				"selected": unit_id == _focused_unit_id,
				"disabled": false,
				"drag_enabled": false,
			}
		)
		if not card.card_pressed.is_connected(_on_compact_card_pressed):
			card.card_pressed.connect(_on_compact_card_pressed)
		row.add_child(card)
		_staged_cards_by_unit_id[unit_id] = card

		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.custom_minimum_size = Vector2(84.0, 0.0)
		remove_button.pressed.connect(_on_remove_button_pressed.bind(unit_id))
		row.add_child(remove_button)


func _update_team_summary() -> void:
	var confirm_button: Button = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/ConfirmButton")
	var team_hint_label: Label = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamHintLabel")
	var team_status_label: Label = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamStatusLabel")
	var selected_names_label: Label = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/SelectedNamesLabel")
	var drop_info_label: Label = get_node("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/DropInfoLabel")
	var team_drop_panel = _get_team_drop_panel()

	confirm_button.disabled = _selected_unit_ids.is_empty()
	team_status_label.text = "Staged team: %d / %d" % [_selected_unit_ids.size(), _get_team_capacity()]
	selected_names_label.text = _build_selected_names_text()
	team_hint_label.text = _build_team_hint_text()
	drop_info_label.text = "Drop operators here to stage them for FOB transfer."
	if team_drop_panel != null:
		team_drop_panel.set_drop_enabled(_selected_unit_ids.size() < _get_team_capacity())


func _update_character_sheet() -> void:
	var portrait_rect: TextureRect = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/PortraitRect")
	var sheet_name_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetNameLabel")
	var sheet_identity_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetIdentityLabel")
	var sheet_role_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetRoleLabel")
	var sheet_status_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetStatusLabel")
	var sheet_skill_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetSkillLabel")
	var sheet_trait_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetTraitLabel")
	var sheet_loadout_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetLoadoutLabel")
	var sheet_bio_label: Label = get_node("Panel/Margin/VBox/ContentRow/InfoPanel/InfoMargin/InfoVBox/SheetBioLabel")

	var profile = _profiles_by_id.get(_focused_unit_id, null)
	if profile == null:
		portrait_rect.texture = null
		sheet_name_label.text = "No operator selected"
		sheet_identity_label.text = "Click a portrait card on the right to inspect a full character sheet."
		sheet_role_label.text = "Role: unavailable"
		sheet_status_label.text = "Status: waiting for selection"
		sheet_skill_label.text = "Skills: unavailable"
		sheet_trait_label.text = "Traits: unavailable"
		sheet_loadout_label.text = "Loadout: unavailable"
		sheet_bio_label.text = "Biography: unavailable"
		return

	portrait_rect.texture = _load_portrait_texture(String(profile.portrait_path))
	portrait_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if portrait_rect.texture != null else Color(0.35, 0.37, 0.42, 1.0)
	var age_text: String = "unknown"
	if int(profile.age_years) > 0:
		age_text = str(int(profile.age_years))

	sheet_name_label.text = "%s" % String(profile.display_name)
	sheet_identity_label.text = "Callsign: %s\nOrigin: %s\nAge: %s" % [
		_build_optional_text(String(profile.callsign), "none"),
		_build_optional_text(String(profile.homeworld), "unknown"),
		age_text,
	]
	sheet_role_label.text = "Role: %s\nSpecialty: %s\nFireteam: %s" % [
		_build_optional_text(String(profile.role_name), "Operator"),
		_build_optional_text(String(profile.specialty_text), "general duty"),
		_build_optional_text(String(profile.fireteam_id).to_upper(), "none"),
	]
	sheet_status_label.text = "Status: %s" % _build_sheet_status_text(_focused_unit_id)
	sheet_skill_label.text = "Skills: %s" % _build_optional_text(String(profile.skill_summary_text), "n/a")
	sheet_trait_label.text = "Traits: %s" % _build_optional_text(String(profile.trait_summary_text), "none")
	sheet_loadout_label.text = "Loadout: %s" % _build_optional_text(String(profile.loadout_summary), "standard kit")
	sheet_bio_label.text = "Bio: %s" % _build_optional_text(String(profile.biography_text), "No biography recorded.")


func _on_compact_card_pressed(unit_id: String, _profile, _source_context: String) -> void:
	_focused_unit_id = unit_id
	_team_feedback_text = ""
	_update_team_summary()
	_update_character_sheet()
	_refresh_card_highlights()


func _on_team_drop_panel_unit_dropped(unit_id: String) -> void:
	if _add_unit_to_team(unit_id):
		selection_changed.emit(get_selected_unit_ids())


func _on_remove_button_pressed(unit_id: String) -> void:
	if _remove_unit_from_team(unit_id):
		selection_changed.emit(get_selected_unit_ids())


func _on_confirm_button_pressed() -> void:
	confirm_selection()


func _add_unit_to_team(unit_id: String) -> bool:
	if unit_id.is_empty() or not _profiles_by_id.has(unit_id):
		_team_feedback_text = "This operator is not available for staging."
		_update_team_summary()
		return false

	if _selected_unit_ids.has(unit_id):
		_team_feedback_text = "%s is already staged." % _build_display_name(unit_id)
		_update_team_summary()
		return false

	if _selected_unit_ids.size() >= _get_team_capacity():
		_team_feedback_text = "The current mission test only supports %d staged operators." % _get_team_capacity()
		_update_team_summary()
		return false

	_selected_unit_ids.append(unit_id)
	_focused_unit_id = unit_id
	_team_feedback_text = ""
	_rebuild_ui()
	return true


func _remove_unit_from_team(unit_id: String) -> bool:
	if not _selected_unit_ids.has(unit_id):
		return false

	var next_selection: PackedStringArray = []
	for selected_unit_id in _selected_unit_ids:
		if String(selected_unit_id) == unit_id:
			continue

		next_selection.append(String(selected_unit_id))

	_selected_unit_ids = next_selection
	if _focused_unit_id == unit_id:
		_focused_unit_id = ""
	_team_feedback_text = "%s removed from the transfer team." % _build_display_name(unit_id)
	_rebuild_ui()
	return true


func _refresh_card_highlights() -> void:
	for unit_id in _roster_cards_by_unit_id.keys():
		var roster_card = _roster_cards_by_unit_id.get(unit_id, null)
		if roster_card == null:
			continue

		roster_card.set_visual_state(_selected_unit_ids.has(String(unit_id)), false)
		roster_card.set_drag_enabled(not _selected_unit_ids.has(String(unit_id)))

	for unit_id in _staged_cards_by_unit_id.keys():
		var staged_card = _staged_cards_by_unit_id.get(unit_id, null)
		if staged_card == null:
			continue

		staged_card.set_visual_state(String(unit_id) == _focused_unit_id, false)


func _ensure_focused_unit_id() -> void:
	if not _focused_unit_id.is_empty() and _profiles_by_id.has(_focused_unit_id):
		return

	for unit_id in _selected_unit_ids:
		if _profiles_by_id.has(String(unit_id)):
			_focused_unit_id = String(unit_id)
			return

	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if _profiles_by_id.has(unit_id):
			_focused_unit_id = unit_id
			return

	_focused_unit_id = ""


func _normalize_selected_unit_ids(selected_unit_ids: PackedStringArray) -> PackedStringArray:
	var available_lookup: Dictionary = {}
	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue

		available_lookup[unit_id] = true

	var normalized_selection: PackedStringArray = []
	for selected_unit_id in selected_unit_ids:
		var unit_id: String = String(selected_unit_id).strip_edges()
		if unit_id.is_empty() or not available_lookup.has(unit_id) or normalized_selection.has(unit_id):
			continue

		normalized_selection.append(unit_id)
		if normalized_selection.size() >= _get_team_capacity():
			break

	return normalized_selection


func _build_selected_names_text() -> String:
	if _selected_unit_ids.is_empty():
		return "No staged operators yet."

	var display_names: PackedStringArray = []
	for unit_id in _selected_unit_ids:
		display_names.append(_build_display_name(String(unit_id)))

	return ", ".join(display_names)


func _build_team_hint_text() -> String:
	if not _team_feedback_text.is_empty():
		return _team_feedback_text

	if _selected_unit_ids.size() >= _get_team_capacity():
		return "Team full. Remove a staged operator before adding another one."

	return "Drag operators from the right roster into the center staging zone. Click any small card to open its character sheet."


func _build_sheet_status_text(unit_id: String) -> String:
	if _selected_unit_ids.has(unit_id):
		return "Staged for FOB transfer"

	return "Available in roster"


func _build_display_name(unit_id: String) -> String:
	var profile = _profiles_by_id.get(unit_id, null)
	if profile == null:
		return unit_id

	return String(profile.display_name)


func _build_optional_text(value: String, fallback: String) -> String:
	if value.strip_edges().is_empty():
		return fallback

	return value


func _get_team_capacity() -> int:
	return int(UNIT_ROSTER_PRESETS_SCRIPT.get_homebase_team_capacity())


func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null

	var resource: Resource = load(portrait_path)
	return resource as Texture2D


func _get_team_drop_panel():
	return get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel")


func _clear_container(container: Node) -> void:
	if container == null:
		return

	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
