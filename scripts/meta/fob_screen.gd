class_name FOBTestScreen
extends Control

signal back_requested()
signal mission_start_requested(selected_unit_ids)

var _selected_unit_ids: PackedStringArray = []


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
	if is_inside_tree():
		_render_team()


func get_team() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func request_mission_start() -> void:
	if _selected_unit_ids.is_empty():
		return

	mission_start_requested.emit(get_team())


func _render_team() -> void:
	var team_status_label: Label = get_node("Panel/Margin/VBox/TeamStatusLabel")
	var start_button: Button = get_node("Panel/Margin/VBox/ButtonRow/StartMissionButton")
	start_button.disabled = _selected_unit_ids.is_empty()

	if _selected_unit_ids.is_empty():
		team_status_label.text = "FOB team: none\nStatus: waiting for transfer"
		return

	team_status_label.text = "FOB team: %s\nStatus: ready for mission start" % ", ".join(_selected_unit_ids)


func _on_back_button_pressed() -> void:
	back_requested.emit()


func _on_start_mission_button_pressed() -> void:
	request_mission_start()
