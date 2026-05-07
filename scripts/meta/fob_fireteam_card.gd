class_name FOBFireteamCard
extends PanelContainer

signal card_pressed(fireteam_id)
signal rename_committed(fireteam_id, next_label)
signal unit_dropped(unit_id, fireteam_id)

var _fireteam_id: String = ""
var _is_selected: bool = false
var _source_context: String = "fireteam_list"


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_ui()
	_apply_visual_state()


func setup_card(fireteam_id: String, label: String, is_selected: bool, respawn_enabled: bool, loadout_id: String, member_summary_text: String, source_context: String = "fireteam_list", teamfit_summary_text: String = "") -> void:
	_fireteam_id = fireteam_id.strip_edges().to_lower()
	_is_selected = is_selected
	_source_context = source_context.strip_edges() if not source_context.strip_edges().is_empty() else "fireteam_list"
	_ensure_ui()

	var title_edit := get_node("Margin/VBox/HeaderRow/TitleEdit") as LineEdit
	var stage_label := get_node("Margin/VBox/StageLabel") as Label
	var member_label := get_node("Margin/VBox/MemberLabel") as Label
	var teamfit_label := get_node("Margin/VBox/TeamfitLabel") as Label
	var drop_hint_label := get_node("Margin/VBox/DropHintLabel") as Label
	var margin := get_node("Margin") as MarginContainer
	var vbox := get_node("Margin/VBox") as VBoxContainer
	var header_row := get_node("Margin/VBox/HeaderRow") as HBoxContainer
	var member_host := get_node("Margin/VBox/MemberHost") as VBoxContainer
	var editable_in_list: bool = _source_context == "fireteam_list"

	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	member_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	teamfit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	member_host.mouse_filter = Control.MOUSE_FILTER_IGNORE

	title_edit.text = label.strip_edges() if not label.strip_edges().is_empty() else _fireteam_id.to_upper()
	title_edit.placeholder_text = _fireteam_id.to_upper()
	title_edit.editable = editable_in_list
	title_edit.focus_mode = Control.FOCUS_ALL if editable_in_list else Control.FOCUS_NONE
	title_edit.mouse_filter = Control.MOUSE_FILTER_STOP if editable_in_list else Control.MOUSE_FILTER_IGNORE
	title_edit.add_theme_font_size_override("font_size", 11)
	stage_label.add_theme_font_size_override("font_size", 9)
	member_label.add_theme_font_size_override("font_size", 9)
	teamfit_label.add_theme_font_size_override("font_size", 9)
	drop_hint_label.add_theme_font_size_override("font_size", 9)
	stage_label.text = "Respawn: %s | Loadout: %s" % ["FOB" if respawn_enabled else "off", loadout_id.to_upper()]
	member_label.text = member_summary_text
	teamfit_label.text = teamfit_summary_text.strip_edges()
	teamfit_label.visible = not teamfit_label.text.is_empty()
	drop_hint_label.text = "Drop operator cards here"
	_apply_visual_state()


func get_member_host() -> VBoxContainer:
	_ensure_ui()
	return get_node("Margin/VBox/MemberHost") as VBoxContainer


func get_fireteam_id() -> String:
	return _fireteam_id


func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected
	_apply_visual_state()


func _gui_input(event: InputEvent) -> void:
	if _fireteam_id.is_empty():
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			card_pressed.emit(_fireteam_id)


func _get_drag_data(_at_position: Vector2):
	if _fireteam_id.is_empty():
		return null

	var preview := PanelContainer.new()
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = Color(0.18, 0.20, 0.25, 0.95)
	stylebox.border_color = Color(0.64, 0.69, 0.76, 1.0)
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	preview.add_theme_stylebox_override("panel", stylebox)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	preview.add_child(margin)
	var label := Label.new()
	label.text = "Fireteam %s" % _fireteam_id.to_upper()
	margin.add_child(label)
	set_drag_preview(preview)

	return {
		"type": "fob_fireteam_card",
		"fireteam_id": _fireteam_id,
		"source_context": _source_context,
	}


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	return String(data.get("type", "")).strip_edges() == "homebase_unit_card" and not _fireteam_id.is_empty()


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(_at_position, data):
		return
	unit_dropped.emit(String(data.get("unit_id", "")).strip_edges(), _fireteam_id)


func _ensure_ui() -> void:
	if get_node_or_null("Margin") != null:
		return

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)

	var header_row := HBoxContainer.new()
	header_row.name = "HeaderRow"
	header_row.add_theme_constant_override("separation", 4)
	vbox.add_child(header_row)

	var title_edit := LineEdit.new()
	title_edit.name = "TitleEdit"
	title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_edit.placeholder_text = "FT"
	title_edit.text_submitted.connect(_on_title_edit_submitted)
	title_edit.focus_exited.connect(_on_title_edit_focus_exited.bind(title_edit))
	header_row.add_child(title_edit)

	var stage_label := Label.new()
	stage_label.name = "StageLabel"
	stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(stage_label)

	var member_label := Label.new()
	member_label.name = "MemberLabel"
	member_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(member_label)

	var teamfit_label := Label.new()
	teamfit_label.name = "TeamfitLabel"
	teamfit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teamfit_label.visible = false
	vbox.add_child(teamfit_label)

	var drop_hint_label := Label.new()
	drop_hint_label.name = "DropHintLabel"
	drop_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(drop_hint_label)

	var member_host := VBoxContainer.new()
	member_host.name = "MemberHost"
	member_host.add_theme_constant_override("separation", 2)
	member_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(member_host)


func _apply_visual_state() -> void:
	var stylebox := StyleBoxFlat.new()
	stylebox.border_width_left = 2
	stylebox.border_width_top = 2
	stylebox.border_width_right = 2
	stylebox.border_width_bottom = 2
	stylebox.corner_radius_top_left = 6
	stylebox.corner_radius_top_right = 6
	stylebox.corner_radius_bottom_left = 6
	stylebox.corner_radius_bottom_right = 6
	if _is_selected:
		stylebox.bg_color = Color(0.20, 0.23, 0.28, 1.0)
		stylebox.border_color = Color(0.64, 0.69, 0.76, 1.0)
	else:
		stylebox.bg_color = Color(0.14, 0.16, 0.19, 1.0)
		stylebox.border_color = Color(0.36, 0.40, 0.46, 1.0)
	add_theme_stylebox_override("panel", stylebox)


func _on_title_edit_submitted(next_text: String) -> void:
	rename_committed.emit(_fireteam_id, next_text)


func _on_title_edit_focus_exited(title_edit: LineEdit) -> void:
	if title_edit == null:
		return
	rename_committed.emit(_fireteam_id, title_edit.text)
