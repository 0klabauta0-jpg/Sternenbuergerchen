extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_667_map_editor_persistent_palette_presets.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const EXPECTED_PREFERENCES_PATH: String = "user://task_667_map_editor_builder_preferences.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_667 Map Editor Persistent Palette Presets ===")
	_test_docs()
	await _test_palette_preferences_survive_new_editor_instance()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_667 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Persistent Palette Presets"), "Task documents persistent palette presets")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Persistent Palette Authoring Preferences"), "Workflow contract documents persistent palette preferences")
	_assert(_read_text(STATUS_PATH).contains("TASK_667 - Map Editor Persistent Palette Presets"), "Implementation status tracks TASK_667")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_667 - Map Editor Persistent Palette Presets"), "Roadmap lists TASK_667")
	_assert(_read_text(REPORT_PATH).contains("TASK_667 - Map Editor Persistent Palette Presets"), "Current handbook references TASK_667")


func _test_palette_preferences_survive_new_editor_instance() -> void:
	var editor_one = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor_one.call("set_palette_authoring_preferences_path_for_test", EXPECTED_PREFERENCES_PATH)), "Test can isolate the preference path")
	root.add_child(editor_one)
	await _wait_frames(14)
	_assert(bool(editor_one.call("clear_palette_authoring_preferences_for_test")), "Test can start from a clean preference file")
	_assert(bool(editor_one.call("toggle_palette_favorite_for_authoring", "factory_building_a")), "Factory asset can be persisted as favorite")
	_assert(bool(editor_one.call("set_palette_type_for_authoring", "station_set_door_single")), "Station door can be persisted as recent")
	_assert(bool(editor_one.call("set_object_placement_scale_preset", 1.6)), "Placement scale preference can be set")
	_assert(bool(editor_one.call("save_palette_authoring_preferences_for_test")), "Palette preferences can be saved explicitly")

	var first_snapshot: Dictionary = Dictionary(editor_one.call("get_map_editor_usability_snapshot", false))
	var first_palette: Dictionary = Dictionary(first_snapshot.get("palette", {}))
	_assert(String(first_palette.get("preferences_path", "")) == EXPECTED_PREFERENCES_PATH, "Snapshot exposes user preference path")
	_assert(bool(first_palette.get("preferences_file_exists", false)), "Preference file exists after saving")
	_assert(bool(first_palette.get("preferences_saved", false)), "Snapshot marks preferences as saved")
	_assert(not bool(first_palette.get("ui_sets_gameplay_truth", true)), "Palette preference snapshot is not gameplay truth")
	editor_one.queue_free()
	await _wait_frames(3)

	var editor_two = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor_two.call("set_palette_authoring_preferences_path_for_test", EXPECTED_PREFERENCES_PATH)), "Second editor uses the isolated preference path")
	root.add_child(editor_two)
	await _wait_frames(14)
	var second_snapshot: Dictionary = Dictionary(editor_two.call("get_map_editor_usability_snapshot", false))
	var second_palette: Dictionary = Dictionary(second_snapshot.get("palette", {}))
	_assert(bool(second_palette.get("preferences_persistent", false)), "Second editor reports persistent preferences")
	_assert(bool(second_palette.get("preferences_loaded", false)), "Second editor loaded preferences")
	_assert(String(second_palette.get("preferences_path", "")) == EXPECTED_PREFERENCES_PATH, "Second editor keeps the same preference path")
	_assert(PackedStringArray(second_palette.get("favorite_type_ids", PackedStringArray())).has("factory_building_a"), "Favorite asset survives new editor instance")
	_assert(PackedStringArray(second_palette.get("recent_type_ids", PackedStringArray())).has("station_set_door_single"), "Recent asset survives new editor instance")
	_assert(is_equal_approx(float(second_palette.get("placement_scale", 0.0)), 1.6), "Placement scale survives new editor instance")
	_assert(not bool(second_palette.get("ui_sets_gameplay_truth", true)), "Loaded preference snapshot still does not set gameplay truth")
	_assert(bool(editor_two.call("set_palette_favorites_filter_enabled", true)), "Favorites/recent filter can be enabled after loading")
	second_snapshot = Dictionary(editor_two.call("get_map_editor_usability_snapshot", false))
	second_palette = Dictionary(second_snapshot.get("palette", {}))
	var visible_ids := PackedStringArray(second_palette.get("visible_type_ids", PackedStringArray()))
	_assert(visible_ids.has("factory_building_a"), "Loaded favorites filter shows persisted favorite")
	_assert(visible_ids.has("station_set_door_single"), "Loaded favorites filter shows persisted recent")
	_assert(bool(editor_two.call("clear_palette_authoring_preferences_for_test")), "Test cleans up preference file")
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
