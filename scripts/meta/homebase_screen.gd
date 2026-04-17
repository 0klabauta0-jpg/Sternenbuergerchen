class_name HomebaseTestScreen
extends Control

const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const PREVIEW_ROOT_NAME: String = "PreviewUnits"

signal selection_changed(selected_unit_ids)
signal team_confirmed(selected_unit_ids)

var _available_units: Array = []
var _selected_unit_ids: PackedStringArray = []
var _preview_units_by_id: Dictionary = {}


func _ready() -> void:
	var confirm_button: Button = get_node("Panel/Margin/VBox/ConfirmButton")
	if not confirm_button.pressed.is_connected(_on_confirm_button_pressed):
		confirm_button.pressed.connect(_on_confirm_button_pressed)

	_ensure_preview_root()
	_rebuild_preview_units()
	_render_roster()


func setup_roster(available_units: Array, selected_unit_ids: PackedStringArray = []) -> void:
	_available_units = available_units.duplicate(true)
	_selected_unit_ids = selected_unit_ids.duplicate()
	if is_inside_tree():
		_rebuild_preview_units()
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
		check_box.text = "%s | %s" % [display_name, _build_unit_detail_text(unit_id)]
		check_box.button_pressed = _selected_unit_ids.has(unit_id)
		check_box.toggled.connect(_on_unit_toggled.bind(unit_id))
		check_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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


func _build_unit_detail_text(unit_id: String) -> String:
	var preview_unit = _preview_units_by_id.get(unit_id, null)
	if preview_unit == null:
		return unit_id

	var skill_text: String = unit_id
	if preview_unit.has_method("get_skill_summary_text"):
		skill_text = String(preview_unit.call("get_skill_summary_text"))

	var trait_text: String = ""
	if preview_unit.has_method("get_trait_summary_text"):
		trait_text = String(preview_unit.call("get_trait_summary_text"))

	if trait_text.is_empty():
		return "%s | -" % skill_text

	return "%s | %s" % [skill_text, trait_text]


func _ensure_preview_root() -> Node:
	var preview_root = get_node_or_null(PREVIEW_ROOT_NAME)
	if preview_root == null:
		preview_root = Node.new()
		preview_root.name = PREVIEW_ROOT_NAME
		add_child(preview_root)

	return preview_root


func _rebuild_preview_units() -> void:
	var preview_root: Node = _ensure_preview_root()
	for child in preview_root.get_children():
		preview_root.remove_child(child)
		child.queue_free()

	_preview_units_by_id.clear()
	for unit_data in _available_units:
		var unit_id: String = String(unit_data.get("unit_id", ""))
		if unit_id.is_empty():
			continue

		var preview_unit = TEST_UNIT_SCRIPT.new()
		preview_unit.visible = false
		preview_unit.unit_id = unit_id
		preview_unit.team_id = String(unit_data.get("team_id", "team_alpha"))
		preview_unit.display_name = String(unit_data.get("display_name", unit_id))
		if preview_unit.has_method("apply_identity_config"):
			preview_unit.call("apply_identity_config", unit_data)
		preview_root.add_child(preview_unit)
		preview_unit.set_process(false)
		_preview_units_by_id[unit_id] = preview_unit
