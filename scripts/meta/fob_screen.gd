class_name FOBTestScreen
extends Control

signal back_requested()
signal mission_start_requested(selected_unit_ids)

var _selected_unit_ids: PackedStringArray = []
var _last_mission_result: Dictionary = {}
var _unit_roles: Dictionary = {}  # unit_id -> role


func _ready() -> void:
	var back_button: Button = get_node("Panel/Margin/VBox/ButtonRow/BackButton")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	if not start_button.pressed.is_connected(_on_start_mission_button_pressed):
		start_button.pressed.connect(_on_start_mission_button_pressed)

	_render_team()


func set_team(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	_unit_roles.clear()
	# Default: first unit is FTL, others specialists
	for i in range(_selected_unit_ids.size()):
		var unit_id = _selected_unit_ids[i]
		_unit_roles[unit_id] = "FTL" if i == 0 else "Specialist"
	if is_inside_tree():
		_render_team()


func get_team() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func get_unit_roles() -> Dictionary:
	return _unit_roles.duplicate()


func set_last_mission_result(mission_result: Dictionary) -> void:
	_last_mission_result = mission_result.duplicate(true)
	if is_inside_tree():
		_render_team()


func clear_last_mission_result() -> void:
	_last_mission_result.clear()
	if is_inside_tree():
		_render_team()


func request_mission_start() -> void:
	if _selected_unit_ids.is_empty():
		return

	mission_start_requested.emit(get_team())


func _render_team() -> void:
	var team_status_label: Label = get_node("Panel/Margin/VBox/TeamStatusLabel")
	var mission_result_label: Label = get_node("Panel/Margin/VBox/MissionResultLabel")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	var loadout_grid: GridContainer = get_node("Panel/Margin/VBox/LoadoutSection/LoadoutGrid")
	start_button.disabled = _selected_unit_ids.is_empty()

	# Clear existing loadout UI
	for child in loadout_grid.get_children():
		child.queue_free()

	if _selected_unit_ids.is_empty():
		team_status_label.text = "FOB team: none\nStatus: waiting for transfer"
		mission_result_label.text = "Last mission: none"
		return

	team_status_label.text = "FOB team: %s\nStatus: ready for mission start" % ", ".join(_selected_unit_ids)
	mission_result_label.text = _build_mission_result_text()

	# Render loadout
	for unit_id in _selected_unit_ids:
		var unit_label = Label.new()
		unit_label.text = unit_id
		loadout_grid.add_child(unit_label)

		var role_option = OptionButton.new()
		role_option.add_item("FTL", 0)
		role_option.add_item("Specialist", 1)
		var current_role = _unit_roles.get(unit_id, "Specialist")
		role_option.selected = 0 if current_role == "FTL" else 1
		role_option.item_selected.connect(_on_role_changed.bind(unit_id))
		loadout_grid.add_child(role_option)


func _build_mission_result_text() -> String:
	if _last_mission_result.is_empty():
		return "Last mission: none"

	var lines: PackedStringArray = []
	lines.append(
		"Last mission: %s (%s)" % [
			String(_last_mission_result.get("mission_outcome", "ended")),
			String(_last_mission_result.get("winning_team_id", "unknown")),
		]
	)

	for member_state in _last_mission_result.get("team_states", []):
		lines.append(
			"%s: %s" % [
				String(member_state.get("unit_id", "")),
				String(member_state.get("vital_state", "unknown")),
			]
		)

	return "\n".join(lines)


func _on_role_changed(index: int, unit_id: String) -> void:
	var role = "FTL" if index == 0 else "Specialist"
	_unit_roles[unit_id] = role
	# Ensure only one FTL
	if role == "FTL":
		for other_id in _unit_roles.keys():
			if other_id != unit_id and _unit_roles[other_id] == "FTL":
				_unit_roles[other_id] = "Specialist"
	_render_team()


func _on_back_button_pressed() -> void:
	back_requested.emit()


func _on_start_mission_button_pressed() -> void:
	request_mission_start()
