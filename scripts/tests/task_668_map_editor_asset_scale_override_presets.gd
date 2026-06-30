extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_668_map_editor_asset_scale_override_presets.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const TEST_PREFERENCES_PATH: String = "user://task_668_map_editor_builder_preferences.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_668 Map Editor Asset Scale Override Presets ===")
	_test_docs()
	await _test_asset_scale_override_survives_selection_and_reload()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_668 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Asset Scale Override Presets"), "Task documents asset scale overrides")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Asset Scale Override Presets"), "Workflow contract documents asset scale overrides")
	_assert(_read_text(STATUS_PATH).contains("TASK_668 - Map Editor Asset Scale Override Presets"), "Implementation status tracks TASK_668")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_668 - Map Editor Asset Scale Override Presets"), "Roadmap lists TASK_668")
	_assert(_read_text(REPORT_PATH).contains("TASK_668 - Map Editor Asset Scale Override Presets"), "Current handbook references TASK_668")


func _test_asset_scale_override_survives_selection_and_reload() -> void:
	var editor_one = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor_one.call("set_palette_authoring_preferences_path_for_test", TEST_PREFERENCES_PATH)), "Test can isolate the preference path")
	root.add_child(editor_one)
	await _wait_frames(14)
	_assert(bool(editor_one.call("clear_palette_authoring_preferences_for_test")), "Test starts with clean preferences")
	_assert(bool(editor_one.call("set_palette_type_for_authoring", "factory_building_a")), "Factory asset can be selected")
	_assert(bool(editor_one.call("set_object_placement_scale_preset", 1.6)), "Placement scale can be set to 1.6")
	_assert(bool(editor_one.call("save_palette_scale_override_for_authoring", "factory_building_a")), "Factory asset can save scale override")

	var snapshot: Dictionary = Dictionary(editor_one.call("get_map_editor_usability_snapshot", false))
	var palette: Dictionary = Dictionary(snapshot.get("palette", {}))
	var overrides: Dictionary = Dictionary(palette.get("asset_scale_overrides", {}))
	_assert(bool(palette.get("selected_has_scale_override", false)), "Selected asset reports a scale override")
	_assert(is_equal_approx(float(palette.get("selected_scale_override", 0.0)), 1.6), "Selected scale override is 1.6")
	_assert(overrides.has("factory_building_a"), "Snapshot includes factory scale override")
	_assert(not bool(palette.get("ui_sets_gameplay_truth", true)), "Scale override snapshot is not gameplay truth")

	_assert(bool(editor_one.call("set_object_placement_scale_preset", 1.0)), "Placement scale can be changed away from override")
	_assert(bool(editor_one.call("set_palette_type_for_authoring", "station_set_door_single")), "Different asset can be selected")
	_assert(bool(editor_one.call("set_palette_type_for_authoring", "factory_building_a")), "Factory asset can be selected again")
	snapshot = Dictionary(editor_one.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	_assert(is_equal_approx(float(palette.get("placement_scale", 0.0)), 1.6), "Selecting factory reapplies saved scale override")
	_assert(bool(editor_one.call("save_palette_authoring_preferences_for_test")), "Scale override preferences can be saved")
	editor_one.queue_free()
	await _wait_frames(3)

	var editor_two = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor_two.call("set_palette_authoring_preferences_path_for_test", TEST_PREFERENCES_PATH)), "Second editor uses isolated preference path")
	root.add_child(editor_two)
	await _wait_frames(14)
	_assert(bool(editor_two.call("set_palette_type_for_authoring", "factory_building_a")), "Second editor selects factory asset")
	snapshot = Dictionary(editor_two.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	overrides = Dictionary(palette.get("asset_scale_overrides", {}))
	_assert(bool(palette.get("preferences_loaded", false)), "Second editor loaded preferences")
	_assert(overrides.has("factory_building_a"), "Scale override survives new editor instance")
	_assert(is_equal_approx(float(overrides.get("factory_building_a", 0.0)), 1.6), "Loaded factory scale override remains 1.6")
	_assert(is_equal_approx(float(palette.get("placement_scale", 0.0)), 1.6), "Loaded factory selection applies scale override")
	_assert(bool(editor_two.call("clear_palette_scale_override_for_authoring", "factory_building_a")), "Scale override can be cleared")
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
