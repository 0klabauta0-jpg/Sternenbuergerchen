class_name HomebaseTestScreen
extends Control

signal selection_changed(selected_unit_ids)
signal team_confirmed(selected_unit_ids)

var _available_units: Array = []
var _selected_unit_ids: PackedStringArray = []


func _ready() -> void:
	var confirm_button: Button = get_node("Panel/Margin/VBox/ConfirmButton")
	if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
		confirm_button.pressed.connect(_on_confirm_button_pressed)

	_render_roster()


func setup_roster(available_units: Array, selected_unit_ids: PackedStringArray = []) -> void:
	_available_units = available_units.duplicate(true)
	_selected_unit_ids = selected_unit_ids.duplicate()
	if is_inside_tree():
		_render_roster()


func set_selected_unit_ids(selected_unit_ids: PackedStringArray) -> void:
	_selected_unit_ids = selected_unit_ids.duplicate()
	if is_inside_tree():
		_render_roster()


func get_selected_unit_ids() -> PackedStringArray:
	return _selected_unit_ids.duplicate()


func confirm_selection() -> void:
	var selected_unit_ids: PackedStringArray = _collect_selected_unit_ids()
	if selected_unit_ids.is_empty():
		return

	_selected_unit_ids = selected_unit_ids
	team_confirmed.emit(get_selected_unit_ids())


func _render_roster() -> void:
	var roster_list: VBoxContainer = get_node("Panel/Margin/VBox/RosterList")
	for child in roster_list.get_children():
		roster_list.remove_child(child)
		child.queue_free()

	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", ""))
		if unit_id.is_empty():
			continue

		var check_box := CheckBox.new()
		var display_name: String = String(unit_data.get("display_name", unit_id))
		var team_id: String = String(unit_data.get("team_id", ""))
		check_box.text = "%s (%s / %s)" % [display_name, unit_id, team_id]
		check_box.button_pressed = _selected_unit_ids.has(unit_id)
		check_box.toggled.connect(_on_unit_toggled.bind(unit_id))
		roster_list.add_child(check_box)

	_update_selection_status()


func _collect_selected_unit_ids() -> PackedStringArray:
	var roster_list: VBoxContainer = get_node("Panel/Margin/VBox/RosterList")
	var selected_unit_ids: PackedStringArray = []
	var roster_index: int = 0

	for child in roster_list.get_children():
		if roster_index >= _available_units.size():
			break

		if child is CheckBox and child.button_pressed:
			var unit_data: Dictionary = _available_units[roster_index]
			selected_unit_ids.append(String(unit_data.get("unit_id", "")))

		roster_index += 1

	return selected_unit_ids


func _update_selection_status() -> void:
	var confirm_button: Button = get_node("Panel/Margin/VBox/ConfirmButton")
	var selection_status_label: Label = get_node("Panel/Margin/VBox/SelectionStatusLabel")
	var selected_unit_ids: PackedStringArray = _collect_selected_unit_ids()
	confirm_button.disabled = selected_unit_ids.is_empty()

	if selected_unit_ids.is_empty():
		selection_status_label.text = "Selected team: none"
		return

	selection_status_label.text = "Selected team: %s" % ", ".join(selected_unit_ids)


func _on_unit_toggled(_pressed: bool, _unit_id: String) -> void:
	_selected_unit_ids = _collect_selected_unit_ids()
	_update_selection_status()
	selection_changed.emit(get_selected_unit_ids())


func _on_confirm_button_pressed() -> void:
	confirm_selection()
