class_name FOBTestScreen
extends Control

const META_UNIT_PROFILE_BUILDER_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile_builder.gd")
const NPC_META_CARD_SCENE: PackedScene = preload("res://scenes/meta/components/npc_meta_card.tscn")

signal back_requested()
signal mission_start_requested(selected_unit_ids)

var _available_units: Array = []
var _selected_unit_ids: PackedStringArray = []
var _last_mission_result: Dictionary = {}
var _profiles_by_id: Dictionary = {}
var _card_nodes_by_unit_id: Dictionary = {}
var _focused_unit_id: String = ""
var _focus_card = null


func _ready() -> void:
	var back_button: Button = get_node("Panel/Margin/VBox/ButtonRow/BackButton")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	if not start_button.pressed.is_connected(_on_start_mission_button_pressed):
		start_button.pressed.connect(_on_start_mission_button_pressed)

	_ensure_focus_card()
	_rebuild_profiles()
	_render_team()


func set_available_units(available_units: Array) -> void:
	_available_units = available_units.duplicate(true)
	if is_inside_tree():
		_rebuild_profiles()
		_render_team()


func set_team(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	if is_inside_tree():
		_rebuild_profiles()
		_render_team()


func get_team() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func set_last_mission_result(mission_result: Dictionary) -> void:
	_last_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_rebuild_profiles()
		_render_team()


func clear_last_mission_result() -> void:
	_last_mission_result.clear()
	if is_inside_tree():
		_rebuild_profiles()
		_render_team()


func request_mission_start() -> void:
	if _selected_unit_ids.is_empty():
		return

	mission_start_requested.emit(get_team())


func _render_team() -> void:
	var team_card_list: VBoxContainer = get_node("Panel/Margin/VBox/ContentRow/TeamColumn/TeamScroll/TeamCardList")
	for child in team_card_list.get_children():
		team_card_list.remove_child(child)
		child.queue_free()

	_card_nodes_by_unit_id.clear()
	_ensure_focused_unit_id()

	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var profile = _profiles_by_id.get(unit_id, null)
		if profile == null:
			continue

		var card = NPC_META_CARD_SCENE.instantiate()
		card.setup_from_profile(
			profile,
			{
				"selectable": true,
				"selected": unit_id == _focused_unit_id,
				"disabled": false,
				"show_status_line": true,
			}
		)
		if not card.card_pressed.is_connected(_on_card_pressed):
			card.card_pressed.connect(_on_card_pressed)
		team_card_list.add_child(card)
		_card_nodes_by_unit_id[unit_id] = card

	_refresh_ui_state()


func _refresh_ui_state() -> void:
	_refresh_card_states()
	_update_summary_panel()
	_update_focus_panel()


func _refresh_card_states() -> void:
	for unit_id in _card_nodes_by_unit_id.keys():
		var card = _card_nodes_by_unit_id.get(unit_id, null)
		if card == null:
			continue

		card.set_interaction_state(true, String(unit_id) == _focused_unit_id, false)


func _update_summary_panel() -> void:
	var team_status_label: Label = get_node("Panel/Margin/VBox/TeamStatusLabel")
	var readiness_label: Label = get_node("Panel/Margin/VBox/ReadinessLabel")
	var mission_result_label: Label = get_node("Panel/Margin/VBox/MissionResultLabel")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	start_button.disabled = _selected_unit_ids.is_empty()

	if _selected_unit_ids.is_empty():
		team_status_label.text = "FOB team: none"
		readiness_label.text = "Ready units: 0 / 0"
		mission_result_label.text = "Last mission: waiting for transfer"
		return

	team_status_label.text = "FOB team: %d operators staged" % _selected_unit_ids.size()
	readiness_label.text = "Ready units: %d / %d" % [_count_ready_units(), _selected_unit_ids.size()]
	mission_result_label.text = _build_mission_summary_text()


func _update_focus_panel() -> void:
	var focus_meta_label: Label = get_node("Panel/Margin/VBox/ContentRow/FocusPanel/FocusMargin/FocusVBox/FocusMetaLabel")
	var focus_help_label: Label = get_node("Panel/Margin/VBox/ContentRow/FocusPanel/FocusMargin/FocusVBox/FocusHelpLabel")
	_ensure_focus_card()

	var profile = _profiles_by_id.get(_focused_unit_id, null)
	if profile == null:
		focus_meta_label.text = "No operator focused."
		focus_help_label.text = "Transferred operators appear here after Homebase confirmation."
		if _focus_card != null:
			_focus_card.visible = false
		return

	var focus_profile = profile.duplicate_profile()
	_focus_card.visible = true
	_focus_card.setup_from_profile(
		focus_profile,
		{
			"selectable": false,
			"selected": false,
			"disabled": false,
			"show_status_line": true,
		}
	)

	var team_state: Dictionary = _get_team_state_for_unit(_focused_unit_id)
	var health_points: int = int(team_state.get("health_points", -1))
	var health_text: String = "unknown"
	if health_points >= 0:
		health_text = str(health_points)

	focus_meta_label.text = "Unit ID: %s\nTeam: %s\nFireteam: %s\nHealth: %s" % [
		String(focus_profile.unit_id),
		_build_optional_text(String(focus_profile.team_id), "unassigned"),
		_build_optional_text(String(focus_profile.fireteam_id).to_upper(), "none"),
		health_text,
	]
	focus_help_label.text = _build_focus_help_text(team_state)


func _build_mission_summary_text() -> String:
	if _last_mission_result.is_empty():
		return "Last mission: none recorded"

	var lines: PackedStringArray = []
	lines.append(
		"Last mission: %s" % _format_status_text(String(_last_mission_result.get("mission_outcome", "ended")), "ENDED")
	)

	var result_text: String = String(_last_mission_result.get("result", "")).strip_edges()
	if not result_text.is_empty():
		lines.append("Result: %s" % _format_status_text(result_text, "ENDED"))

	var winner_team_id: String = String(_last_mission_result.get("winning_team_id", "")).strip_edges()
	if not winner_team_id.is_empty():
		lines.append("Winner: %s" % winner_team_id)

	var duration_seconds: float = float(_last_mission_result.get("duration_seconds", 0.0))
	if duration_seconds > 0.0:
		lines.append("Duration: %.1fs" % duration_seconds)

	return " | ".join(lines)


func _on_card_pressed(unit_id: String, _profile) -> void:
	_focused_unit_id = unit_id
	_refresh_ui_state()


func _rebuild_profiles() -> void:
	_profiles_by_id = META_UNIT_PROFILE_BUILDER_SCRIPT.build_profiles_by_unit_id(
		_build_selected_unit_configs(),
		_build_profile_options_by_unit_id()
	)
	_ensure_focused_unit_id()


func _build_selected_unit_configs() -> Array:
	var selected_lookup: Dictionary = {}
	for unit_id_variant in _selected_unit_ids:
		selected_lookup[String(unit_id_variant)] = true

	var selected_unit_configs: Array = []
	for unit_data_variant in _available_units:
		if typeof(unit_data_variant) != TYPE_DICTIONARY:
			continue

		var unit_data: Dictionary = unit_data_variant
		var unit_id: String = String(unit_data.get("unit_id", "")).strip_edges()
		if unit_id.is_empty() or not selected_lookup.has(unit_id):
			continue

		selected_unit_configs.append(unit_data.duplicate(true))
		selected_lookup.erase(unit_id)

	for missing_unit_id in selected_lookup.keys():
		selected_unit_configs.append(_build_fallback_unit_config(String(missing_unit_id)))

	return selected_unit_configs


func _build_fallback_unit_config(unit_id: String) -> Dictionary:
	var team_state: Dictionary = _get_team_state_for_unit(unit_id)
	return {
		"unit_id": unit_id,
		"display_name": String(team_state.get("display_name", unit_id)),
		"team_id": "",
		"fireteam_id": "",
		"skill_accuracy": 0.5,
		"skill_speed": 0.5,
		"skill_leadership": 0.3,
		"skill_toughness": 0.5,
		"trait_ids": [],
	}


func _build_profile_options_by_unit_id() -> Dictionary:
	var options_by_unit_id: Dictionary = {}
	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		var team_state: Dictionary = _get_team_state_for_unit(unit_id)
		options_by_unit_id[unit_id] = {
			"status_text": _build_unit_status_text(team_state),
			"secondary_text": _build_unit_secondary_text(team_state),
		}

	return options_by_unit_id


func _count_ready_units() -> int:
	var ready_count: int = 0
	for unit_id_variant in _selected_unit_ids:
		if _is_unit_ready_for_mission(_get_team_state_for_unit(String(unit_id_variant))):
			ready_count += 1

	return ready_count


func _is_unit_ready_for_mission(team_state: Dictionary) -> bool:
	if team_state.is_empty():
		return true

	var vital_state: String = String(team_state.get("vital_state", "")).strip_edges().to_lower()
	return vital_state.is_empty() or vital_state == "fit" or vital_state == "ready"


func _build_unit_status_text(team_state: Dictionary) -> String:
	if team_state.is_empty():
		return "READY FOR MISSION"

	var vital_state: String = String(team_state.get("vital_state", "")).strip_edges().to_lower()
	match vital_state:
		"", "ready":
			return "READY"
		"fit":
			return "FIT"
		"down":
			return "DOWN"
		"bleedout":
			return "BLEEDOUT"
		"respawning":
			return "RESPAWNING"
		_:
			return "UNKNOWN"


func _build_unit_secondary_text(team_state: Dictionary) -> String:
	if team_state.is_empty():
		return "Awaiting deployment"

	var health_points: int = int(team_state.get("health_points", -1))
	if health_points >= 0:
		return "HP %d" % health_points

	return "Return logged"


func _build_focus_help_text(team_state: Dictionary) -> String:
	if team_state.is_empty():
		return "No return data recorded for this operator. Ready for the next mission."

	return "Latest return state: %s." % _build_unit_status_text(team_state)


func _get_team_state_for_unit(unit_id: String) -> Dictionary:
	if unit_id.is_empty() or _last_mission_result.is_empty():
		return {}

	for member_state_variant in _last_mission_result.get("team_states", []):
		if typeof(member_state_variant) != TYPE_DICTIONARY:
			continue

		var member_state: Dictionary = member_state_variant
		if String(member_state.get("unit_id", "")).strip_edges() != unit_id:
			continue

		return member_state.duplicate(true)

	return {}


func _ensure_focus_card() -> void:
	if _focus_card != null:
		return

	var focus_card_host: VBoxContainer = get_node_or_null("Panel/Margin/VBox/ContentRow/FocusPanel/FocusMargin/FocusVBox/FocusCardHost")
	if focus_card_host == null:
		return

	_focus_card = NPC_META_CARD_SCENE.instantiate()
	_focus_card.visible = false
	focus_card_host.add_child(_focus_card)


func _ensure_focused_unit_id() -> void:
	if not _focused_unit_id.is_empty() and _profiles_by_id.has(_focused_unit_id):
		return

	for unit_id_variant in _selected_unit_ids:
		var unit_id: String = String(unit_id_variant)
		if _profiles_by_id.has(unit_id):
			_focused_unit_id = unit_id
			return

	_focused_unit_id = ""


func _format_status_text(value: String, fallback: String) -> String:
	var normalized_value: String = value.strip_edges()
	if normalized_value.is_empty():
		return fallback

	return normalized_value.replace("_", " ").to_upper()


func _build_optional_text(value: String, fallback: String) -> String:
	if value.strip_edges().is_empty():
		return fallback

	return value


func _on_back_button_pressed() -> void:
	back_requested.emit()


func _on_start_mission_button_pressed() -> void:
	request_mission_start()
