@tool
extends EditorPlugin

const WORKBENCH_SCENE_PATH: String = "res://scenes/editor/map_builder_workbench.tscn"
const WORKBENCH_MANIFEST_PATH: String = "res://data/map_builder_workbench_manifest.json"
const DEFAULT_OUTPUT_PATH: String = "res://maps/map_builder_workbench_output.json"
const TOOL_SELECT: String = "select"
const TOOL_PAINT: String = "paint"
const TOOL_ERASE: String = "erase"
const TOOL_PROPS: String = "props"

var _dock: Control
var _status_label: Label
var _output_path_edit: LineEdit
var _palette_list: ItemList
var _category_filter: OptionButton
var _selected_item_label: Label
var _rotation_label: Label
var _height_spin: SpinBox
var _scale_spin: SpinBox
var _tool_buttons: Array[Button] = []
var _palette_entries: Array[Dictionary] = []
var _selected_entry: Dictionary = {}
var _active_tool: String = TOOL_SELECT
var _rotation_degrees: float = 0.0
var _headless_editor_mode: bool = false


func _enter_tree() -> void:
	_headless_editor_mode = DisplayServer.get_name() == "headless"
	if _headless_editor_mode:
		return
	if has_method("set_input_event_forwarding_always_enabled"):
		call("set_input_event_forwarding_always_enabled")
	_load_palette_entries()
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

	tool_rail.add_child(_make_tool_button("Select: Workbench/Node auswaehlen", func() -> void: _set_active_tool(TOOL_SELECT), ["ToolSelect", "Cursor"], "S"))
	tool_rail.add_child(_make_tool_button("Paint: ausgewaehltes Tile/Prop in den Viewport setzen", func() -> void: _set_active_tool(TOOL_PAINT), ["Edit", "CanvasItem", "MeshInstance3D"], "P"))
	tool_rail.add_child(_make_tool_button("Erase: GridMap-Kachel unter dem Cursor loeschen", func() -> void: _set_active_tool(TOOL_ERASE), ["Remove", "Clear", "GuiClose"], "E"))
	tool_rail.add_child(_make_tool_button("Rotate: Platzierung um 90 Grad drehen", _rotate_selected_clockwise, ["Reload", "RotateRight", "BoneAttachment3D"], "R"))
	tool_rail.add_child(HSeparator.new())
	tool_rail.add_child(_make_tool_button("Workbench oeffnen", _open_workbench_scene, ["PackedScene", "Folder", "Load"], "O"))
	tool_rail.add_child(_make_tool_button("MeshLibrary vorbereiten", _configure_workbench, ["Tools", "GridMap", "Reload"], "M"))
	tool_rail.add_child(_make_tool_button("GridMap auswaehlen", _select_grid_map, ["GridMap", "Grid", "ToolSelect"], "G"))
	tool_rail.add_child(_make_tool_button("AssetPlacerProps auswaehlen", _select_prop_root, ["Node3D", "Object", "Instance"], "A"))
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
	help.text = "Palette waehlen, Paint aktivieren, dann im 3D-Viewport linksklicken. Q/E oder Rotate dreht in 90-Grad-Schritten."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(help)

	content.add_child(HSeparator.new())
	content.add_child(_build_palette_panel())
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
	_refresh_palette()
	return root


func _build_palette_panel() -> VBoxContainer:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var category_row := HBoxContainer.new()
	var category_label := Label.new()
	category_label.text = "Kategorie"
	category_label.custom_minimum_size.x = 72.0
	category_row.add_child(category_label)
	_category_filter = OptionButton.new()
	_category_filter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_category_filter.item_selected.connect(func(_index: int) -> void: _refresh_palette())
	category_row.add_child(_category_filter)
	panel.add_child(category_row)

	_palette_list = ItemList.new()
	_palette_list.fixed_icon_size = Vector2i(48, 48)
	_palette_list.max_columns = 2
	_palette_list.same_column_width = true
	_palette_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_palette_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_palette_list.item_selected.connect(_on_palette_item_selected)
	panel.add_child(_palette_list)

	var selected_row := HBoxContainer.new()
	_selected_item_label = Label.new()
	_selected_item_label.text = "Auswahl: -"
	_selected_item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	selected_row.add_child(_selected_item_label)
	_rotation_label = Label.new()
	_rotation_label.text = "Rot 0"
	selected_row.add_child(_rotation_label)
	panel.add_child(selected_row)

	var controls := HBoxContainer.new()
	controls.add_child(_make_button("-90", _rotate_selected_counter_clockwise, ["RotateLeft", "Reload"]))
	controls.add_child(_make_button("+90", _rotate_selected_clockwise, ["RotateRight", "Reload"]))
	var height_label := Label.new()
	height_label.text = "Y"
	controls.add_child(height_label)
	_height_spin = SpinBox.new()
	_height_spin.min_value = 0
	_height_spin.max_value = 2
	_height_spin.step = 1
	_height_spin.value = 0
	_height_spin.custom_minimum_size.x = 56.0
	controls.add_child(_height_spin)
	var scale_label := Label.new()
	scale_label.text = "Scale"
	controls.add_child(scale_label)
	_scale_spin = SpinBox.new()
	_scale_spin.min_value = 0.25
	_scale_spin.max_value = 2.5
	_scale_spin.step = 0.05
	_scale_spin.value = 1.0
	_scale_spin.custom_minimum_size.x = 72.0
	controls.add_child(_scale_spin)
	panel.add_child(controls)

	_populate_category_filter()
	return panel


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


func _load_palette_entries() -> void:
	_palette_entries.clear()
	if not FileAccess.file_exists(WORKBENCH_MANIFEST_PATH):
		return
	var file := FileAccess.open(WORKBENCH_MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var manifest: Dictionary = Dictionary(parsed)
	var mesh_section: Dictionary = Dictionary(manifest.get("mesh_library", {}))
	for item_variant in Array(mesh_section.get("items", [])):
		if typeof(item_variant) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = Dictionary(item_variant)
		_palette_entries.append({
			"kind": "grid",
			"item_id": int(item.get("item_id", -1)),
			"type_id": String(item.get("type_id", "")).strip_edges().to_lower(),
			"label": String(item.get("label", item.get("type_id", ""))),
			"category": String(item.get("category", "grid")).strip_edges(),
			"preview_path": String(item.get("preview_path", "")).strip_edges(),
		})
	var props_section: Dictionary = Dictionary(manifest.get("asset_placer_props", {}))
	for prop_variant in Array(props_section.get("sample_assets", [])):
		if typeof(prop_variant) != TYPE_DICTIONARY:
			continue
		var prop: Dictionary = Dictionary(prop_variant)
		_palette_entries.append({
			"kind": "prop",
			"type_id": String(prop.get("type_id", "")).strip_edges().to_lower(),
			"label": String(prop.get("label", prop.get("type_id", ""))),
			"category": "props",
			"preview_path": String(prop.get("preview_path", "")).strip_edges(),
			"default_scale": float(prop.get("scale", 1.0)),
		})


func _populate_category_filter() -> void:
	if _category_filter == null:
		return
	_category_filter.clear()
	_category_filter.add_item("Alle")
	_category_filter.add_item("Tiles")
	_category_filter.add_item("Props")
	var categories: Dictionary = {}
	for entry in _palette_entries:
		var category: String = String(Dictionary(entry).get("category", "")).strip_edges()
		if not category.is_empty():
			categories[category] = true
	var sorted_categories := categories.keys()
	sorted_categories.sort()
	for category in sorted_categories:
		if category in ["props"]:
			continue
		_category_filter.add_item(String(category).capitalize())


func _refresh_palette() -> void:
	if _palette_list == null:
		return
	_palette_list.clear()
	var selected_filter: String = _category_filter.get_item_text(_category_filter.selected) if _category_filter != null and _category_filter.get_item_count() > 0 else "Alle"
	for entry_variant in _palette_entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if not _entry_matches_filter(entry, selected_filter):
			continue
		var preview_path: String = String(entry.get("preview_path", "")).strip_edges()
		var icon: Texture2D = load(preview_path) as Texture2D if not preview_path.is_empty() else null
		_palette_list.add_item("%s\n%s" % [String(entry.get("label", "")), String(entry.get("kind", ""))], icon, true)
		var index: int = _palette_list.get_item_count() - 1
		_palette_list.set_item_metadata(index, entry)
	if _palette_list.get_item_count() > 0 and _selected_entry.is_empty():
		_palette_list.select(0)
		_on_palette_item_selected(0)


func _entry_matches_filter(entry: Dictionary, selected_filter: String) -> bool:
	var normalized_filter: String = selected_filter.strip_edges().to_lower()
	var kind: String = String(entry.get("kind", "")).strip_edges().to_lower()
	var category: String = String(entry.get("category", "")).strip_edges().to_lower()
	if normalized_filter == "alle":
		return true
	if normalized_filter == "tiles":
		return kind == "grid"
	if normalized_filter == "props":
		return kind == "prop"
	return category == normalized_filter


func _on_palette_item_selected(index: int) -> void:
	if _palette_list == null or index < 0 or index >= _palette_list.get_item_count():
		return
	_selected_entry = Dictionary(_palette_list.get_item_metadata(index))
	if _selected_entry.get("kind", "") == "prop" and _scale_spin != null:
		_scale_spin.value = float(_selected_entry.get("default_scale", _scale_spin.value))
	_set_active_tool(TOOL_PAINT)
	_update_selected_label()


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


func _set_active_tool(tool: String) -> void:
	_active_tool = tool
	if tool == TOOL_SELECT:
		_select_grid_map()
	elif tool == TOOL_PAINT:
		_configure_workbench()
	_update_selected_label()


func _rotate_selected_clockwise() -> void:
	_rotation_degrees = fposmod(_rotation_degrees + 90.0, 360.0)
	_update_selected_label()


func _rotate_selected_counter_clockwise() -> void:
	_rotation_degrees = fposmod(_rotation_degrees - 90.0, 360.0)
	_update_selected_label()


func _update_selected_label() -> void:
	if _selected_item_label != null:
		var label_text: String = String(_selected_entry.get("label", "-")) if not _selected_entry.is_empty() else "-"
		var kind: String = String(_selected_entry.get("kind", "-")) if not _selected_entry.is_empty() else "-"
		_selected_item_label.text = "%s: %s" % [kind.capitalize(), label_text]
	if _rotation_label != null:
		_rotation_label.text = "Rot %d" % int(_rotation_degrees)
	if _status_label != null and _active_tool in [TOOL_PAINT, TOOL_ERASE]:
		var verb: String = "setzen" if _active_tool == TOOL_PAINT else "loeschen"
		_set_status("Werkzeug aktiv: %s. Linksklick im 3D-Viewport zum %s. Q/E dreht." % [_active_tool.capitalize(), verb], Color(0.75, 0.95, 1.0))


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


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> AfterGUIInput:
	if _headless_editor_mode or not (_active_tool in [TOOL_PAINT, TOOL_ERASE]):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_rotate_selected_counter_clockwise()
			return _handled()
		if event.keycode == KEY_E:
			_rotate_selected_clockwise()
			return _handled()
		if event.keycode == KEY_ESCAPE:
			_active_tool = TOOL_SELECT
			_update_selected_label()
			return _handled()
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			return _apply_paint_at_event(viewport_camera, mouse_button.position)
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			return _apply_paint_at_event(viewport_camera, motion.position)
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _apply_paint_at_event(viewport_camera: Camera3D, mouse_position: Vector2) -> AfterGUIInput:
	var workbench := _get_workbench_root()
	if workbench == null:
		_set_status("Keine Workbench aktiv. Erst Workbench oeffnen.", Color(1.0, 0.75, 0.45))
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var grid_map := workbench.get_node_or_null("GridMap") as GridMap
	if grid_map == null:
		_set_status("GridMap fehlt in der Workbench.", Color(1.0, 0.55, 0.45))
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var cell: Vector3i = _cell_from_viewport(viewport_camera, mouse_position, grid_map)
	if cell == Vector3i(999999, 999999, 999999):
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _height_spin != null:
		cell.y = int(_height_spin.value)
	if _active_tool == TOOL_ERASE:
		if workbench.has_method("erase_grid_cell") and bool(workbench.call("erase_grid_cell", cell)):
			_mark_scene_dirty()
			_set_status("GridMap-Zelle geloescht: %s" % str(cell), Color(0.95, 0.85, 0.55))
			return _handled()
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	if _selected_entry.is_empty():
		_set_status("Keine Palette-Auswahl. Erst Tile oder Prop waehlen.", Color(1.0, 0.75, 0.45))
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	var kind: String = String(_selected_entry.get("kind", ""))
	if kind == "grid":
		var item_id: int = int(_selected_entry.get("item_id", -1))
		if workbench.has_method("place_grid_item") and bool(workbench.call("place_grid_item", item_id, cell, _rotation_degrees)):
			_mark_scene_dirty()
			_set_status("Tile gesetzt: %s @ %s" % [String(_selected_entry.get("label", "")), str(cell)], Color(0.75, 1.0, 0.75))
			return _handled()
	if kind == "prop":
		var scale_value: float = float(_scale_spin.value) if _scale_spin != null else 1.0
		var grid_position := Vector2i(cell.x, cell.z)
		if workbench.has_method("place_prop") and workbench.call("place_prop", String(_selected_entry.get("type_id", "")), grid_position, _rotation_degrees, scale_value) != null:
			_mark_scene_dirty()
			_set_status("Prop gesetzt: %s @ %s" % [String(_selected_entry.get("label", "")), str(grid_position)], Color(0.75, 1.0, 0.75))
			return _handled()
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func _cell_from_viewport(viewport_camera: Camera3D, mouse_position: Vector2, grid_map: GridMap) -> Vector3i:
	var ray_origin: Vector3 = viewport_camera.project_ray_origin(mouse_position)
	var ray_dir: Vector3 = viewport_camera.project_ray_normal(mouse_position)
	var local_origin: Vector3 = grid_map.to_local(ray_origin)
	var local_target: Vector3 = grid_map.to_local(ray_origin + ray_dir)
	var local_dir: Vector3 = (local_target - local_origin).normalized()
	if absf(local_dir.y) < 0.0001:
		return Vector3i(999999, 999999, 999999)
	var target_y: float = float(_height_spin.value) * grid_map.cell_size.y if _height_spin != null else 0.0
	var distance: float = (target_y - local_origin.y) / local_dir.y
	if distance < 0.0:
		return Vector3i(999999, 999999, 999999)
	var local_point: Vector3 = local_origin + local_dir * distance
	return grid_map.local_to_map(local_point)


func _mark_scene_dirty() -> void:
	if EditorInterface.has_method("mark_scene_as_unsaved"):
		EditorInterface.call("mark_scene_as_unsaved")


func _handled() -> AfterGUIInput:
	get_viewport().set_input_as_handled()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


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
