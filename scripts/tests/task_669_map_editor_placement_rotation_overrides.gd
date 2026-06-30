extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_669_map_editor_placement_rotation_overrides.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const TEST_PREFERENCES_PATH: String = "user://task_669_map_editor_builder_preferences.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_669 Map Editor Placement Rotation Overrides ===")
	_test_docs()
	await _test_placement_rotation_override_and_brush_apply()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_669 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Placement Rotation Overrides"), "Task documents placement rotation overrides")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Asset Rotation Override Presets"), "Workflow contract documents asset rotation overrides")
	_assert(_read_text(STATUS_PATH).contains("TASK_669 - Map Editor Placement Rotation Overrides"), "Implementation status tracks TASK_669")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_669 - Map Editor Placement Rotation Overrides"), "Roadmap lists TASK_669")
	_assert(_read_text(REPORT_PATH).contains("TASK_669 - Map Editor Placement Rotation Overrides"), "Current handbook references TASK_669")


func _test_placement_rotation_override_and_brush_apply() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor.call("set_palette_authoring_preferences_path_for_test", TEST_PREFERENCES_PATH)), "Test can isolate the preference path")
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("clear_palette_authoring_preferences_for_test")), "Test starts with clean preferences")
	_assert(bool(editor.call("set_palette_type_for_authoring", "factory_building_a")), "Factory asset can be selected")
	_assert(bool(editor.call("set_object_placement_rotation_degrees", 180.0)), "Placement rotation can be set to 180")
	_assert(bool(editor.call("save_palette_rotation_override_for_authoring", "factory_building_a")), "Factory asset can save rotation override")

	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var palette: Dictionary = Dictionary(snapshot.get("palette", {}))
	var overrides: Dictionary = Dictionary(palette.get("asset_rotation_overrides", {}))
	_assert(is_equal_approx(float(palette.get("placement_rotation_degrees", -1.0)), 180.0), "Palette snapshot reports placement rotation")
	_assert(bool(palette.get("selected_has_rotation_override", false)), "Selected asset reports a rotation override")
	_assert(is_equal_approx(float(palette.get("selected_rotation_override_degrees", -1.0)), 180.0), "Selected rotation override is 180")
	_assert(overrides.has("factory_building_a"), "Snapshot includes factory rotation override")
	_assert(not bool(palette.get("ui_sets_gameplay_truth", true)), "Rotation override snapshot is not gameplay truth")

	_assert(bool(editor.call("set_object_placement_rotation_degrees", 0.0)), "Placement rotation can be changed away from override")
	_assert(bool(editor.call("set_palette_type_for_authoring", "station_set_door_single")), "Different asset can be selected")
	_assert(bool(editor.call("set_palette_type_for_authoring", "factory_building_a")), "Factory asset can be selected again")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	_assert(is_equal_approx(float(palette.get("placement_rotation_degrees", -1.0)), 180.0), "Selecting factory reapplies saved rotation override")

	var terrain_map_data = editor.get("_terrain_map_data")
	var target_grid := Vector2i(2, 2)
	var target_tile = terrain_map_data.call("get_tile_at_grid", target_grid) if terrain_map_data != null else null
	_assert(target_tile != null, "Brush target tile exists")
	if target_tile != null:
		var world_position: Vector2 = Vector2(target_tile.world_position)
		editor.call("_apply_brush_at_world_position", world_position)
		editor.call("_select_tile_at_world_position", world_position)
		await _wait_frames(2)
		snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
		var selected_tile: Dictionary = Dictionary(snapshot.get("selected_tile", {}))
		_assert(String(selected_tile.get("type_id", "")) == "factory_building_a" or String(selected_tile.get("object_type_id", "")) == "factory_building_a", "Brush applies factory asset")
		_assert(is_equal_approx(float(selected_tile.get("object_rotation_degrees", -1.0)), 180.0), "Brush writes placement rotation into tile")

	_assert(bool(editor.call("save_palette_authoring_preferences_for_test")), "Rotation override preferences can be saved")
	editor.queue_free()
	await _wait_frames(3)

	var editor_two = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor_two.call("set_palette_authoring_preferences_path_for_test", TEST_PREFERENCES_PATH)), "Second editor uses isolated preference path")
	root.add_child(editor_two)
	await _wait_frames(14)
	_assert(bool(editor_two.call("set_palette_type_for_authoring", "factory_building_a")), "Second editor selects factory asset")
	snapshot = Dictionary(editor_two.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	overrides = Dictionary(palette.get("asset_rotation_overrides", {}))
	_assert(bool(palette.get("preferences_loaded", false)), "Second editor loaded preferences")
	_assert(overrides.has("factory_building_a"), "Rotation override survives new editor instance")
	_assert(is_equal_approx(float(overrides.get("factory_building_a", -1.0)), 180.0), "Loaded factory rotation override remains 180")
	_assert(is_equal_approx(float(palette.get("placement_rotation_degrees", -1.0)), 180.0), "Loaded factory selection applies rotation override")
	_assert(bool(editor_two.call("clear_palette_rotation_override_for_authoring", "factory_building_a")), "Rotation override can be cleared")
	_assert(bool(editor_two.call("clear_palette_authoring_preferences_for_test")), "Test cleans up isolated preferences")
	editor_two.queue_free()
	await _wait_frames(2)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
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
