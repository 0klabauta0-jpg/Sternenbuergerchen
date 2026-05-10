extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_297 Map Editor Inspector Collapsible Panels ===")
	await _test_inspector_sections()
	_test_manual_checklist()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_inspector_sections() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(1, 1))), "Editor can select tile before collapse")
	var before: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var before_inspector: Dictionary = Dictionary(before.get("inspector", {}))
	_assert(bool(before_inspector.get("tile_properties_visible", false)), "Tile Properties are visible on start")
	_assert(editor.get_node_or_null("UI/PropertyPanel/Margin") is ScrollContainer, "Property panel content is inside a ScrollContainer")
	_assert(bool(before_inspector.get("property_panel_scrollable", false)), "Inspector snapshot reports right panel scrolling")
	_assert(bool(before_inspector.get("property_panel_vertical_scroll_enabled", false)), "Right property panel has vertical scrolling enabled")
	_assert(editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MapSettingsToggle") != null, "Map Settings toggle exists")
	_assert(editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MarkersToggle") != null, "Markers toggle exists")
	_assert(editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioToggle") != null, "Mission Scenario toggle exists")

	_assert(bool(editor.call("set_inspector_section_collapsed", "map_settings", true)), "Map Settings can collapse")
	_assert(bool(editor.call("set_inspector_section_collapsed", "markers", true)), "Markers can collapse")
	_assert(bool(editor.call("set_inspector_section_collapsed", "mission_scenario", false)), "Mission Scenario can expand")
	await _wait_frames(2)
	var collapsed: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var inspector: Dictionary = Dictionary(collapsed.get("inspector", {}))
	_assert(bool(inspector.get("tile_properties_visible", false)), "Tile Properties remain visible after collapse")
	_assert(not bool(inspector.get("map_settings_visible", true)), "Map Settings section is hidden when collapsed")
	_assert(not bool(inspector.get("markers_visible", true)), "Markers section is hidden when collapsed")
	_assert(bool(inspector.get("mission_scenario_visible", false)), "Mission Scenario section expands independently")
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(2, 2))), "Property editing still works after collapse")
	var after: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(Vector2i(after.get("selected_grid", Vector2i.ZERO)) == Vector2i(2, 2), "Selection survives inspector collapse")
	editor.queue_free()
	await _wait_frames(2)


func _test_manual_checklist() -> void:
	var path: String = "res://docs/manual_checks/map_editor_inspector_panels_checklist.md"
	_assert(FileAccess.file_exists(path), "Inspector manual checklist exists")
	var text: String = _read_text(path)
	for required_text in ["Tile Properties", "Map Settings", "Markers", "Mission Scenario", "scroll"]:
		_assert(text.contains(required_text), "Inspector checklist covers %s" % required_text)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
