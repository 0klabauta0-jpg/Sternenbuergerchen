@tool
extends EditorPlugin

const WORKBENCH_SCENE_PATH: String = "res://scenes/editor/map_builder_workbench.tscn"
const DEFAULT_OUTPUT_PATH: String = "res://maps/map_builder_workbench_output.json"

var _dock: Control
var _status_label: Label
var _output_path_edit: LineEdit
var _tool_buttons: Array[Button] = []
var _headless_editor_mode: bool = false


func _enter_tree() -> void:
	_headless_editor_mode = DisplayServer.get_name() == "headless"
	if _headless_editor_mode:
		return
	_dock = _build_dock()
	add_control_to_dock(DOCK_SLOT_LEFT_UL, _dock)
	scene_changed.connect(_on_scene_changed)
	_refresh_status.call_deferred()


func _exit_tree() -> void:
	if _headless_editor_mode:
		return
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null


func _build_dock() -> HBoxContainer:
	var root := HBoxContainer.new()
	root.name = "Map Builder"
	root.custom_minimum_size = Vector2(380.0, 320.0)
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var tool_rail := VBoxContainer.new()
	tool_rail.custom_minimum_size = Vector2(44.0, 0.0)
	tool_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tool_rail)

	tool_rail.add_child(_make_tool_button("Workbench oeffnen", _open_workbench_scene, ["PackedScene", "Folder", "Load"], "O"))
	tool_rail.add_child(_make_tool_button("MeshLibrary vorbereiten", _configure_workbench, ["Reload", "Tools", "MeshInstance3D"], "R"))
	tool_rail.add_child(_make_tool_button("GridMap auswaehlen und Tile-Palette nutzen", _select_grid_map, ["GridMap", "Grid", "ToolSelect"], "G"))
	tool_rail.add_child(_make_tool_button("AssetPlacerProps auswaehlen", _select_prop_root, ["Node3D", "Object", "Instance"], "P"))
	tool_rail.add_child(HSeparator.new())
	tool_rail.add_child(_make_tool_button("Nach Mission-JSON kompilieren", _compile_workbench, ["Save", "File", "StatusSuccess"], "S"))
	tool_rail.add_spacer(false)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(content)

	var title := Label.new()
	title.text = "Map Builder Workbench"
	title.add_theme_font_size_override("font_size", 16)
	content.add_child(title)

	var help := Label.new()
	help.text = "F6 ist Vorschau. Zum Bauen links ein Werkzeug waehlen: Workbench oeffnen, GridMap malen, Props sammeln, Mission-JSON kompilieren."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(help)

	content.add_child(HSeparator.new())
	content.add_child(_make_action_row("Select", "GridMap auswaehlen", "Prop-Root", _select_grid_map, _select_prop_root))

	var output_label := Label.new()
	output_label.text = "Compile Output"
	content.add_child(output_label)

	_output_path_edit = LineEdit.new()
	_output_path_edit.text = DEFAULT_OUTPUT_PATH
	_output_path_edit.placeholder_text = "res://maps/meine_map.json"
	_output_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_output_path_edit)

	var compile_row := HBoxContainer.new()
	compile_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compile_row.add_child(_make_button("Vorbereiten", _configure_workbench, ["Reload", "Tools"]))
	compile_row.add_child(_make_button("Kompilieren", _compile_workbench, ["Save", "StatusSuccess"]))
	content.add_child(compile_row)
	content.add_child(HSeparator.new())

	_status_label = Label.new()
	_status_label.text = "Workbench nicht geprueft."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_status_label)
	return root


func _make_action_row(left_label: String, first_text: String, second_text: String, first_target: Callable, second_target: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = left_label
	label.custom_minimum_size.x = 56.0
	row.add_child(label)
	row.add_child(_make_button(first_text, first_target, ["GridMap", "Grid", "ToolSelect"]))
	row.add_child(_make_button(second_text, second_target, ["Node3D", "Object", "Instance"]))
	return row


func _make_button(text: String, target: Callable, icon_candidates: Array[String] = []) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(target)
	_apply_editor_icon(button, icon_candidates)
	return button


func _make_tool_button(tooltip: String, target: Callable, icon_candidates: Array[String], fallback_text: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(40.0, 40.0)
	button.tooltip_text = tooltip
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.expand_icon = true
	button.pressed.connect(func() -> void:
		_mark_active_tool(button)
		target.call()
	)
	if not _apply_editor_icon(button, icon_candidates):
		button.text = fallback_text
	_tool_buttons.append(button)
	return button


func _apply_editor_icon(button: Button, icon_candidates: Array[String]) -> bool:
	var base_control := EditorInterface.get_base_control()
	for icon_name in icon_candidates:
		if base_control.has_theme_icon(icon_name, "EditorIcons"):
			button.icon = base_control.get_theme_icon(icon_name, "EditorIcons")
			return true
	return false


func _mark_active_tool(active_button: Button) -> void:
	for button in _tool_buttons:
		button.button_pressed = button == active_button


func _open_workbench_scene() -> void:
	EditorInterface.open_scene_from_path(WORKBENCH_SCENE_PATH)
	_set_status("Workbench-Scene geoeffnet. Danach 'MeshLibrary vorbereiten' und 'GridMap auswaehlen' nutzen.", Color(0.75, 0.95, 1.0))
	_refresh_status.call_deferred()


func _configure_workbench() -> void:
	var workbench := _get_workbench_root()
	if workbench == null:
		_open_workbench_scene()
		return
	if not workbench.has_method("configure_workbench"):
		_set_status("Aktuelle Scene ist keine MapBuilderWorkbench.", Color(1.0, 0.75, 0.45))
		return
	var snapshot: Dictionary = Dictionary(workbench.call("configure_workbench", true))
	_set_status(
		"Bereit: %d MeshLibrary-Items, %d GridMap-Zellen, %d Props. Jetzt 'GridMap auswaehlen' klicken."
		% [
			int(snapshot.get("mesh_library_item_count", 0)),
			int(snapshot.get("grid_used_cell_count", 0)),
			int(snapshot.get("prop_node_count", 0)),
		],
		Color(0.75, 1.0, 0.75)
	)


func _select_grid_map() -> void:
	var workbench := _get_workbench_root()
	if workbench == null:
		_open_workbench_scene()
		return
	if workbench.has_method("configure_workbench"):
		workbench.call("configure_workbench", false)
	var grid_map: Node = workbench.get_node_or_null("GridMap")
	if grid_map == null:
		_set_status("GridMap-Node fehlt in der Workbench.", Color(1.0, 0.55, 0.45))
		return
	_select_editor_node(grid_map)
	_set_status("GridMap ist ausgewaehlt. Godots GridMap-Palette sollte jetzt fuer Boden, Strassen, Wasser und Waende nutzbar sein.", Color(0.75, 0.95, 1.0))


func _select_prop_root() -> void:
	var workbench := _get_workbench_root()
	if workbench == null:
		_open_workbench_scene()
		return
	var prop_root: Node = workbench.get_node_or_null("AssetPlacerProps")
	if prop_root == null:
		_set_status("AssetPlacerProps-Node fehlt in der Workbench.", Color(1.0, 0.55, 0.45))
		return
	_select_editor_node(prop_root)
	_set_status("AssetPlacerProps ist ausgewaehlt. Freie Props gehoeren unter diesen Node und brauchen sb_type_id plus sb_grid_position.", Color(0.75, 0.95, 1.0))


func _compile_workbench() -> void:
	var workbench := _get_workbench_root()
	if workbench == null:
		_open_workbench_scene()
		return
	if not workbench.has_method("save_compiled_map"):
		_set_status("Aktuelle Scene kann nicht kompiliert werden.", Color(1.0, 0.55, 0.45))
		return
	var output_path: String = _output_path_edit.text.strip_edges()
	if output_path.is_empty():
		output_path = DEFAULT_OUTPUT_PATH
	var result: Dictionary = Dictionary(workbench.call("save_compiled_map", output_path))
	if not bool(result.get("ok", false)):
		_set_status("Compile fehlgeschlagen: %s" % str(result), Color(1.0, 0.55, 0.45))
		return
	var stats: Dictionary = Dictionary(result.get("stats", {}))
	_set_status(
		"Kompiliert: %s | %d/%d Placements angewendet."
		% [
			String(result.get("output_path", output_path)),
			int(stats.get("applied_count", 0)),
			int(stats.get("placement_count", 0)),
		],
		Color(0.75, 1.0, 0.75)
	)


func _refresh_status() -> void:
	if _status_label == null:
		return
	var workbench := _get_workbench_root()
	if workbench == null:
		_set_status("Keine Workbench-Scene aktiv. 'Workbench oeffnen' klicken.", Color(0.95, 0.85, 0.55))
		return
	_set_status("Workbench aktiv. Naechster Schritt: MeshLibrary vorbereiten oder GridMap auswaehlen.", Color(0.75, 0.95, 1.0))


func _on_scene_changed(_scene_root: Node) -> void:
	_refresh_status.call_deferred()


func _get_workbench_root() -> Node:
	var root := EditorInterface.get_edited_scene_root()
	if root != null and root.has_method("configure_workbench") and root.has_method("save_compiled_map"):
		return root
	return null


func _select_editor_node(node: Node) -> void:
	var selection := EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	if EditorInterface.has_method("edit_node"):
		EditorInterface.call("edit_node", node)


func _set_status(message: String, color: Color) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.modulate = color
