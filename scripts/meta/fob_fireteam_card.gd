class_name FOBFireteamCard
extends PanelContainer

signal card_pressed(fireteam_id)
signal rename_committed(fireteam_id, next_label)
signal unit_dropped(unit_id, fireteam_id)
signal fireteam_dropped(fireteam_id, target_id)

const META_USEROLOGY_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/meta_userology_contract.gd")

const REFERENCE_CARD_MIN_SIZE := Vector2(280.0, 74.0)
const CARD_Z_INDEX := 24
const SELECTED_BORDER_COLOR := Color("f2c94c")

var _fireteam_id: String = ""
var _is_selected: bool = false
var _source_context: String = "fireteam_list"


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_canvas_order(false)
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
	stage_label.visible = true
	stage_label.text = _build_loadout_stage_text(loadout_id, _source_context)
	stage_label.set_meta("fireteam_card_loadout_visible", true)
	var show_member_summary: bool = _source_context == "fireteam_list" or _source_context == "mission_mini"
	if show_member_summary:
		member_label.text = member_summary_text
		member_label.visible = true
	else:
		member_label.text = ""
		member_label.visible = false
	teamfit_label.text = teamfit_summary_text.strip_edges()
	teamfit_label.visible = not teamfit_label.text.is_empty()
	drop_hint_label.text = "Drop operator cards here"
	_apply_density(editable_in_list, margin, vbox, title_edit, stage_label, member_label, teamfit_label, drop_hint_label)
	if _source_context == "loadout_staging":
		custom_minimum_size = Vector2(custom_minimum_size.x, 48.0)
		set_meta("loadout_reference_summary_hidden", true)
	_apply_visual_state()


func _build_loadout_stage_text(loadout_id: String, source_context: String) -> String:
	var loadout_text: String = loadout_id.strip_edges().to_upper()
	if loadout_text.is_empty():
		loadout_text = "MEDIUM"
	if source_context == "loadout_staging":
		return "FOB | Loadout: %s" % loadout_text
	return "Loadout: %s" % loadout_text


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
	preview.z_as_relative = false
	preview.z_index = int(META_USEROLOGY_CONTRACT_SCRIPT.get("DRAG_PREVIEW_Z_INDEX"))
	preview.custom_minimum_size = Vector2(188.0, 40.0)
	preview.size = preview.custom_minimum_size
	preview.set_meta("global_drag_layer", true)
	preview.set_meta("above_windows", true)
	preview.set_meta("fireteam_drag_preview_fixed_width", true)
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
	label.custom_minimum_size = Vector2(164.0, 20.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	margin.add_child(label)
	set_drag_preview(preview)

	return {
		"type": "fob_fireteam_card",
		"fireteam_id": _fireteam_id,
		"source_context": _source_context,
	}


func _apply_canvas_order(is_drag_preview: bool) -> void:
	z_as_relative = false
	z_index = int(META_USEROLOGY_CONTRACT_SCRIPT.get("DRAG_PREVIEW_Z_INDEX")) if is_drag_preview else CARD_Z_INDEX
	set_meta("global_card_z_order", true)


func _apply_density(
	editable_in_list: bool,
	margin: MarginContainer,
	vbox: VBoxContainer,
	title_edit: LineEdit,
	stage_label: Label,
	member_label: Label,
	teamfit_label: Label,
	drop_hint_label: Label
) -> void:
	if editable_in_list:
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		custom_minimum_size = Vector2.ZERO
		clip_contents = false
		margin.add_theme_constant_override("margin_left", 6)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_right", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		vbox.add_theme_constant_override("separation", 2)
		stage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		member_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		teamfit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		drop_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stage_label.max_lines_visible = -1
		member_label.max_lines_visible = -1
		teamfit_label.max_lines_visible = -1
		drop_hint_label.max_lines_visible = -1
		stage_label.clip_text = false
		member_label.clip_text = false
		teamfit_label.clip_text = false
		drop_hint_label.clip_text = false
		drop_hint_label.visible = true
		set_meta("fob_fireteam_reference_card", false)
		return

	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	custom_minimum_size = REFERENCE_CARD_MIN_SIZE
	clip_contents = true
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	vbox.add_theme_constant_override("separation", 1)
	title_edit.custom_minimum_size = Vector2(0.0, 22.0)
	stage_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	member_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	teamfit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	drop_hint_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	stage_label.max_lines_visible = 1
	member_label.max_lines_visible = 1
	teamfit_label.max_lines_visible = 1
	drop_hint_label.max_lines_visible = 1
	stage_label.clip_text = true
	member_label.clip_text = true
	teamfit_label.clip_text = true
	drop_hint_label.clip_text = true
	teamfit_label.visible = false
	drop_hint_label.visible = false
	set_meta("fob_fireteam_reference_card", true)


func _can_drop_data(_at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var drag_type: String = String(data.get("type", "")).strip_edges()
	if drag_type == "homebase_unit_card":
		return not _fireteam_id.is_empty()
	if drag_type != "fob_fireteam_card":
		return false
	if not bool(get_meta("homebase_fireteam_drop_target", false)) or not bool(get_meta("homebase_fireteam_drop_enabled", false)):
		return false
	var target_id: String = String(get_meta("homebase_fireteam_drop_target_id", "")).strip_edges()
	var dropped_fireteam_id: String = String(data.get("fireteam_id", "")).strip_edges()
	return not target_id.is_empty() and not dropped_fireteam_id.is_empty() and dropped_fireteam_id != _fireteam_id


func _drop_data(_at_position: Vector2, data) -> void:
	if not _can_drop_data(_at_position, data):
		return
	var drag_type: String = String(data.get("type", "")).strip_edges()
	if drag_type == "homebase_unit_card":
		unit_dropped.emit(String(data.get("unit_id", "")).strip_edges(), _fireteam_id)
	elif drag_type == "fob_fireteam_card":
		fireteam_dropped.emit(
			String(data.get("fireteam_id", "")).strip_edges(),
			String(get_meta("homebase_fireteam_drop_target_id", "")).strip_edges()
		)


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
		stylebox.border_color = SELECTED_BORDER_COLOR
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
