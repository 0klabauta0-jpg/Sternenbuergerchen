extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_683_map_editor_interaction_fullhd_sight_pass.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_64x64.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_PNG_PATH: String = "res://tmp/map_editor_interaction_fullhd_sight_pass.png"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/map_editor_interaction_fullhd_sight_pass.json"
const TARGET_VIEWPORT: Vector2i = Vector2i(1920, 1080)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_683 Map Editor Interaction FullHD Sight Pass ===")
	_test_docs()
	await _test_editor_interaction_fullhd_sight_packet()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_683: FAILED")
		quit(1)
		return
	print("TASK_683: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_683 task file exists")
	_assert(task_text.contains("Map Editor Interaction FullHD Sight Pass"), "Task documents FullHD sight pass")
	_assert(contract_text.contains("Editor FullHD Sight Evidence"), "Interaction contract documents FullHD evidence")
	_assert(status_text.contains("TASK_683 - Map Editor Interaction FullHD Sight Pass"), "Implementation status tracks TASK_683")
	_assert(roadmap_text.contains("TASK_683 - Map Editor Interaction FullHD Sight Pass"), "Roadmap lists TASK_683")
	_assert(handbook_text.contains("TASK_683 - Map Editor Interaction FullHD Sight Pass"), "Current handbook references TASK_683")
	_assert(handbook_text.contains('data-export-key="map_editor_interaction_fullhd.png_path"'), "Current handbook exports TASK_683 PNG path")
	_assert(handbook_text.contains('data-note-key="notes.map_editor_interaction_fullhd"'), "Current handbook exports TASK_683 notes")


func _test_editor_interaction_fullhd_sight_packet() -> void:
	_ensure_output_dir()
	root.size = TARGET_VIEWPORT
	var editor = MAP_EDITOR_SCENE.instantiate()
	editor.set("map_file_path", MAP_PATH)
	root.add_child(editor)
	await _wait_frames(20)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	scenario["map_file_path"] = MAP_PATH
	editor.call("set_mission_scenario_authoring_fields", scenario)
	await _wait_frames(8)

	editor.call("_select_marker", "objective_point")
	await _wait_frames(4)
	var preset_applied: bool = bool(editor.call("apply_interaction_binding_preset_to_editor", "computer_operate"))
	await _wait_frames(4)
	_assert(preset_applied, "Computer preset can be loaded for FullHD sight pass")
	_scroll_property_panel_to_bottom(editor)
	await _wait_frames(4)

	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var inspector_snapshot: Dictionary = Dictionary(usability.get("interaction_binding_inspector", {}))
	var editor_snapshot: Dictionary = Dictionary(usability.get("interaction_binding_editor", {}))
	var ui_sight: Dictionary = _collect_ui_sight(editor)
	var image: Image = _capture_viewport_image_or_empty()
	var viewport_readback_available: bool = image != null and image.get_width() == TARGET_VIEWPORT.x and image.get_height() == TARGET_VIEWPORT.y
	if not viewport_readback_available:
		image = _build_review_board(usability, ui_sight)
	_assert(image.get_width() == TARGET_VIEWPORT.x and image.get_height() == TARGET_VIEWPORT.y, "TASK_683 image has FullHD dimensions")
	_assert(_count_visible_samples(image) > 0, "TASK_683 image has visible pixels")
	var png_error: Error = image.save_png(OUTPUT_PNG_PATH)
	_assert(png_error == OK and FileAccess.file_exists(OUTPUT_PNG_PATH), "TASK_683 PNG is written")

	var manifest: Dictionary = _build_manifest(usability, ui_sight, image, viewport_readback_available)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_683 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_fullhd_sight_pass.v1", "Manifest schema is stable")
	_assert(String(parsed.get("selected_marker_id", "")) == "objective_point", "Manifest records selected marker")
	_assert(int(parsed.get("preset_count", 0)) >= 6, "Manifest records preset catalog")
	_assert(String(parsed.get("selected_preset_id", "")) == "computer_operate", "Manifest records selected preset")
	_assert(bool(parsed.get("all_required_controls_visible", false)), "All required controls have visible FullHD footprint")
	_assert(bool(parsed.get("property_panel_scrollable", false)), "Property panel remains scrollable")
	_assert(bool(parsed.get("inspector_available", false)), "Binding inspector is available")
	_assert(bool(parsed.get("editor_available", false)), "Binding editor is available")
	_assert(not bool(parsed.get("ui_sets_gameplay_truth", true)), "Sight pass does not set gameplay truth")
	_assert(bool(parsed.get("manual_fullhd_review_required", false)), "Manifest keeps manual FullHD review required")
	_assert(not bool(parsed.get("manual_fullhd_review_done", true)), "Manifest does not claim manual FullHD review done")
	_assert(bool(inspector_snapshot.get("read_only", false)), "Inspector snapshot remains read-only")
	_assert(not bool(inspector_snapshot.get("ui_sets_gameplay_truth", true)), "Inspector does not set gameplay truth")
	_assert(not bool(editor_snapshot.get("ui_sets_gameplay_truth", true)), "Editor snapshot does not set gameplay truth")

	editor.queue_free()
	await _wait_frames(2)


func _collect_ui_sight(editor: Node) -> Dictionary:
	var viewport_size: Vector2 = Vector2(float(TARGET_VIEWPORT.x), float(TARGET_VIEWPORT.y))
	var control_paths: Dictionary = {
		"top_bar": "UI/TopBar",
		"palette_panel": "UI/PalettePanel",
		"property_panel": "UI/PropertyPanel",
		"property_scroll": "UI/PropertyPanel/Margin",
		"marker_panel": "UI/PropertyPanel/Margin/VBox/MarkerEditorPanel",
		"binding_inspector": "UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingInspectorLabel",
		"binding_editor": "UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel",
		"preset_option": "UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel/InteractionBindingPresetRow/InteractionBindingPresetOption",
		"apply_button": "UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel/InteractionBindingActionRow/InteractionBindingApplyButton",
		"remove_button": "UI/PropertyPanel/Margin/VBox/MarkerEditorPanel/InteractionBindingEditorPanel/InteractionBindingActionRow/InteractionBindingRemoveButton",
	}
	var required_ids: PackedStringArray = PackedStringArray([
		"property_panel",
		"marker_panel",
		"binding_inspector",
		"binding_editor",
		"preset_option",
		"apply_button",
		"remove_button",
	])
	var controls: Dictionary = {}
	var all_required_visible: bool = true
	for id in control_paths.keys():
		var path: String = String(control_paths[id])
		var control := editor.get_node_or_null(path) as Control
		var sight: Dictionary = _control_sight(control, viewport_size)
		sight["path"] = path
		controls[id] = sight
		if required_ids.has(String(id)) and not bool(sight.get("visible_footprint", false)):
			all_required_visible = false
	var property_scroll := editor.get_node_or_null("UI/PropertyPanel/Margin") as ScrollContainer
	return {
		"viewport": {"width": TARGET_VIEWPORT.x, "height": TARGET_VIEWPORT.y},
		"controls": controls,
		"required_control_ids": required_ids,
		"all_required_controls_visible": all_required_visible,
		"property_panel_scrollable": property_scroll != null and int(property_scroll.vertical_scroll_mode) != int(ScrollContainer.SCROLL_MODE_DISABLED),
	}


func _scroll_property_panel_to_bottom(editor: Node) -> void:
	var property_scroll := editor.get_node_or_null("UI/PropertyPanel/Margin") as ScrollContainer
	if property_scroll == null:
		return
	var scrollbar := property_scroll.get_v_scroll_bar()
	if scrollbar == null:
		return
	property_scroll.scroll_vertical = int(ceil(scrollbar.max_value))


func _control_sight(control: Control, viewport_size: Vector2) -> Dictionary:
	if control == null:
		return {
			"exists": false,
			"visible_in_tree": false,
			"visible_footprint": false,
			"inside_viewport": false,
			"rect": {},
		}
	var rect: Rect2 = control.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, viewport_size)
	var intersects: bool = viewport_rect.intersects(rect) and rect.size.x > 2.0 and rect.size.y > 2.0
	return {
		"exists": true,
		"visible_in_tree": control.is_visible_in_tree(),
		"visible_footprint": control.is_visible_in_tree() and intersects,
		"inside_viewport": rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y,
		"rect": {
			"x": rect.position.x,
			"y": rect.position.y,
			"w": rect.size.x,
			"h": rect.size.y,
		},
	}


func _build_manifest(usability: Dictionary, ui_sight: Dictionary, image: Image, viewport_readback_available: bool) -> Dictionary:
	var inspector: Dictionary = Dictionary(usability.get("interaction_binding_inspector", {}))
	var binding_editor: Dictionary = Dictionary(usability.get("interaction_binding_editor", {}))
	var preset_preview: Dictionary = Dictionary(binding_editor.get("preset_preview", {}))
	return {
		"schema": "sternenbuergerchen.map_editor_interaction_fullhd_sight_pass.v1",
		"task_id": "TASK_683",
		"source_task_id": "TASK_682",
		"display_server": DisplayServer.get_name(),
		"viewport_readback_available": viewport_readback_available,
		"generated_evidence_board": not viewport_readback_available,
		"viewport": {"width": image.get_width(), "height": image.get_height()},
		"png_path": ProjectSettings.globalize_path(OUTPUT_PNG_PATH),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"selected_marker_id": String(Dictionary(usability.get("marker_tool", {})).get("selected_marker_id", "")),
		"selected_preset_id": String(binding_editor.get("selected_preset_id", "")),
		"preset_count": int(binding_editor.get("preset_count", 0)),
		"preset_preview": preset_preview,
		"binding_inspector": inspector,
		"binding_editor": binding_editor,
		"ui_sight": ui_sight,
		"all_required_controls_visible": bool(ui_sight.get("all_required_controls_visible", false)),
		"property_panel_scrollable": bool(ui_sight.get("property_panel_scrollable", false)),
		"inspector_available": String(inspector.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_inspector.v1",
		"editor_available": String(binding_editor.get("schema", "")) == "sternenbuergerchen.map_editor_interaction_binding_editor.v1",
		"manual_checks": [
			{"id": "real_window_launched", "label": "Editor in real FullHD window launched", "done": false},
			{"id": "panel_density_ok", "label": "Right panel density feels comfortable", "done": false},
			{"id": "scroll_workflow_ok", "label": "Marker and binding fields remain easy to reach", "done": false},
			{"id": "preset_labels_readable", "label": "Preset and status labels are readable at default zoom", "done": false},
		],
		"manual_fullhd_review_required": true,
		"manual_fullhd_review_done": false,
		"read_only_evidence": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_684 - Map Editor Interaction FullHD Polish Findings",
	}


func _build_review_board(usability: Dictionary, ui_sight: Dictionary) -> Image:
	var image: Image = Image.create(TARGET_VIEWPORT.x, TARGET_VIEWPORT.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.035, 0.045, 0.047, 1.0))
	_fill_rect(image, Rect2i(0, 0, 1920, 104), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(0, 984, 1920, 96), Color(0.018, 0.066, 0.080, 1.0))
	_fill_rect(image, Rect2i(32, 130, 380, 824), Color(0.070, 0.096, 0.104, 1.0))
	_draw_rect_outline(image, Rect2i(32, 130, 380, 824), Color(0.20, 0.42, 0.48, 1.0), 3)
	_fill_rect(image, Rect2i(430, 130, 1030, 824), Color(0.060, 0.075, 0.073, 1.0))
	_draw_grid(image, Rect2i(470, 170, 950, 744), Color(0.11, 0.15, 0.15, 1.0))
	_fill_rect(image, Rect2i(1484, 130, 404, 824), Color(0.070, 0.096, 0.104, 1.0))
	_draw_rect_outline(image, Rect2i(1484, 130, 404, 824), Color(0.20, 0.42, 0.48, 1.0), 3)
	var binding_editor: Dictionary = Dictionary(usability.get("interaction_binding_editor", {}))
	var preset_count: int = int(binding_editor.get("preset_count", 0))
	var selected_marker: String = String(Dictionary(usability.get("marker_tool", {})).get("selected_marker_id", ""))
	var marker_width: int = clampi(80 + selected_marker.length() * 8, 80, 320)
	var preset_width: int = clampi(50 + preset_count * 36, 50, 300)
	_fill_rect(image, Rect2i(1508, 176, marker_width, 30), Color(0.62, 0.84, 1.0, 1.0))
	_fill_rect(image, Rect2i(1508, 226, preset_width, 30), Color(0.46, 0.85, 0.58, 1.0))
	_fill_rect(image, Rect2i(1508, 286, 330, 54), Color(0.86, 0.70, 0.18, 1.0))
	var controls: Dictionary = Dictionary(ui_sight.get("controls", {}))
	var y: int = 372
	for id in Array(ui_sight.get("required_control_ids", [])):
		var sight: Dictionary = Dictionary(controls.get(String(id), {}))
		var color := Color(0.46, 0.85, 0.58, 1.0) if bool(sight.get("visible_footprint", false)) else Color(0.92, 0.36, 0.30, 1.0)
		_fill_rect(image, Rect2i(1508, y, 300, 24), color)
		y += 42
	_fill_rect(image, Rect2i(72, 188, 280, 36), Color(0.86, 0.70, 0.18, 1.0))
	_fill_rect(image, Rect2i(72, 250, 220, 36), Color(0.46, 0.85, 0.58, 1.0))
	return image


func _draw_grid(image: Image, rect: Rect2i, color: Color) -> void:
	_draw_rect_outline(image, rect, color, 2)
	for x in range(rect.position.x + 64, rect.position.x + rect.size.x, 64):
		_fill_rect(image, Rect2i(x, rect.position.y, 1, rect.size.y), color)
	for y in range(rect.position.y + 64, rect.position.y + rect.size.y, 64):
		_fill_rect(image, Rect2i(rect.position.x, y, rect.size.x, 1), color)


func _draw_rect_outline(image: Image, rect: Rect2i, color: Color, thickness: int = 2) -> void:
	var safe_thickness: int = maxi(1, thickness)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, rect.size.x, safe_thickness), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y + rect.size.y - safe_thickness, rect.size.x, safe_thickness), color)
	_fill_rect(image, Rect2i(rect.position.x, rect.position.y, safe_thickness, rect.size.y), color)
	_fill_rect(image, Rect2i(rect.position.x + rect.size.x - safe_thickness, rect.position.y, safe_thickness, rect.size.y), color)


func _fill_rect(image: Image, rect: Rect2i, color: Color) -> void:
	var x0: int = clampi(rect.position.x, 0, image.get_width())
	var y0: int = clampi(rect.position.y, 0, image.get_height())
	var x1: int = clampi(rect.position.x + rect.size.x, 0, image.get_width())
	var y1: int = clampi(rect.position.y + rect.size.y, 0, image.get_height())
	for y in range(y0, y1):
		for x in range(x0, x1):
			image.set_pixel(x, y, color)


func _capture_viewport_image_or_empty() -> Image:
	if DisplayServer.get_name().strip_edges().to_lower() == "headless":
		return Image.new()
	var viewport_texture: ViewportTexture = root.get_texture()
	if viewport_texture == null:
		return Image.new()
	var image: Image = viewport_texture.get_image()
	if image == null:
		return Image.new()
	return image


func _count_visible_samples(image: Image) -> int:
	var count: int = 0
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width <= 0 or height <= 0:
		return 0
	var step_y: int = maxi(1, floori(float(height) / 24.0))
	var step_x: int = maxi(1, floori(float(width) / 24.0))
	for y in range(0, height, step_y):
		for x in range(0, width, step_x):
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.01 and (pixel.r > 0.05 or pixel.g > 0.05 or pixel.b > 0.05):
				count += 1
	return count


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_683 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _load_json_dict(path: String) -> Dictionary:
	return _read_json(path)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
