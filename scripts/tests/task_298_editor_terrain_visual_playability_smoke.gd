extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const REFERENCE_MAP_PATH: String = "res://maps/editor_terrain_visual_recovery_reference.json"
const REPORT_PATH: String = "res://docs/reports/editor_terrain_visual_recovery_report.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/editor_terrain_visual_playability_smoke.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_298 Editor Terrain Visual Playability Smoke ===")
	await _test_editor_visual_playability_smoke()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_editor_visual_playability_smoke() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	editor.call("_load_map", REFERENCE_MAP_PATH)
	await _wait_frames(10)
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(3, 3))), "Editor selects reference H2 tile")
	for tool_id in ["select", "terrain_brush", "eraser", "height", "patrol"]:
		_assert(bool(editor.call("set_authoring_tool", tool_id)), "Smoke can activate tool: %s" % tool_id)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var toolbar: Dictionary = Dictionary(snapshot.get("toolbar", {}))
	_assert(bool(toolbar.get("exclusive", false)), "Toolbar remains exclusive after smoke tool cycle")
	editor.call("_on_palette_group_button_pressed", "nature_props")
	await _wait_frames(1)
	var nature_palette: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("palette", {}))
	_assert(String(nature_palette.get("active_group", "")) == "nature_props", "Palette filters Nature Props")
	editor.call("_on_palette_group_button_pressed", "space_station")
	await _wait_frames(1)
	var station_palette: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("palette", {}))
	_assert(PackedStringArray(station_palette.get("visible_type_ids", PackedStringArray())).has("station_computer"), "Palette filters Space Station assets")
	_assert(bool(editor.call("set_inspector_section_collapsed", "map_settings", true)), "Smoke collapses Map Settings")
	_assert(bool(editor.call("set_inspector_section_collapsed", "markers", true)), "Smoke collapses Markers")
	_assert(bool(editor.call("set_inspector_section_collapsed", "mission_scenario", false)), "Smoke expands Mission Scenario")
	var inspector: Dictionary = Dictionary(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("inspector", {}))
	_assert(bool(inspector.get("tile_properties_visible", false)), "Tile Properties remain visible in integrated smoke")

	var primary_view: Node = editor.get_node_or_null("Primary3DView")
	await _wait_frames(8)
	var render_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot")) if primary_view != null and primary_view.has_method("get_render_snapshot") else {}
	_assert(int(render_snapshot.get("height_edge_model_count", 0)) > 0, "Smoke renders height edges")
	_assert(bool(Dictionary(render_snapshot.get("editor_visual_recovery", {})).get("grid_depth_tested", false)), "Smoke keeps depth-tested grid")
	_assert(int(render_snapshot.get("nature_prop_model_count", 0)) >= 5, "Smoke renders Nature props")
	_assert(int(render_snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Smoke has no missing map asset mappings")
	_assert(not Dictionary(render_snapshot.get("editor_light", {})).is_empty(), "Smoke reports editor light")
	editor.queue_free()
	await _wait_frames(2)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Visual recovery report exists")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Integrated manual smoke checklist exists")
	var report: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Covered Assets", "Performance Gate", "Open Manual Items"]:
		_assert(report.contains(required_text), "Report covers %s" % required_text)


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
