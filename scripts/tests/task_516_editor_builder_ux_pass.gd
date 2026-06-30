extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_516_editor_builder_ux_pass.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const TEST_PREFERENCES_PATH: String = "user://task_516_map_editor_builder_preferences.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_516 Editor Builder UX Pass ===")
	_test_docs()
	await _test_palette_search_favorites_recent_and_scale_presets()
	await _test_builder_drag_preview_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_516 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Editor Builder UX Pass"), "Task documents the editor builder UX pass")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Palette Search, Favorites and Presets"), "Workflow contract documents palette search/favorites/presets")
	_assert(_read_text(STATUS_PATH).contains("TASK_516 - Editor Builder UX Pass"), "Implementation status tracks TASK_516")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_516 - Editor Builder UX Pass"), "Roadmap lists TASK_516")
	_assert(_read_text(REPORT_PATH).contains("TASK_516 - Editor Builder UX Pass"), "Review report references TASK_516")


func _test_palette_search_favorites_recent_and_scale_presets() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor.call("set_palette_authoring_preferences_path_for_test", TEST_PREFERENCES_PATH)), "Palette test uses an isolated preference path")
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("clear_palette_authoring_preferences_for_test")), "Palette test starts with clean preferences")

	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var palette: Dictionary = Dictionary(snapshot.get("palette", {}))
	_assert(Vector2i(palette.get("preview_icon_size", Vector2i.ZERO)) == Vector2i(72, 72), "Palette keeps large preview icons")
	_assert(Vector2(palette.get("selected_preview_size", Vector2.ZERO)).x >= 112.0, "Selected asset keeps a large preview block")
	_assert(PackedFloat32Array(palette.get("scale_presets", PackedFloat32Array())).has(1.6), "Palette exposes the 1.6 scale preset")

	_assert(bool(editor.call("set_palette_search_query_for_authoring", "door")), "Search query can be set")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	_assert(String(palette.get("search_query", "")) == "door", "Palette snapshot stores search query")
	_assert(bool(palette.get("search_active", false)), "Palette snapshot marks active search")
	_assert(int(palette.get("visible_count", 0)) > 0, "Search keeps matching assets visible")
	for type_id in PackedStringArray(palette.get("visible_type_ids", PackedStringArray())):
		var normalized_type_id: String = String(type_id).strip_edges().to_lower()
		var display_names := PackedStringArray(palette.get("visible_display_names", PackedStringArray()))
		var display_name: String = String(display_names[PackedStringArray(palette.get("visible_type_ids", PackedStringArray())).find(type_id)]).to_lower() if display_names.size() == PackedStringArray(palette.get("visible_type_ids", PackedStringArray())).size() else ""
		_assert(normalized_type_id.contains("door") or display_name.contains("door"), "Search result matches door: %s" % normalized_type_id)

	_assert(bool(editor.call("set_palette_search_query_for_authoring", "")), "Search query can be cleared")
	_assert(bool(editor.call("set_palette_type_for_authoring", "factory_building_a")), "Factory asset can be selected")
	_assert(bool(editor.call("toggle_palette_favorite_for_authoring", "factory_building_a")), "Factory asset can be favorited")
	_assert(bool(editor.call("activate_runtime_builder_tool", "door_open")), "Door quick tool updates recent assets")
	_assert(bool(editor.call("set_palette_favorites_filter_enabled", true)), "Favorites/recent filter can be enabled")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	_assert(bool(palette.get("favorites_filter_enabled", false)), "Palette snapshot marks favorites filter")
	_assert(PackedStringArray(palette.get("favorite_type_ids", PackedStringArray())).has("factory_building_a"), "Favorites snapshot contains factory asset")
	_assert(PackedStringArray(palette.get("recent_type_ids", PackedStringArray())).has("station_set_door_single"), "Recent snapshot contains door quick tool asset")
	var visible_ids := PackedStringArray(palette.get("visible_type_ids", PackedStringArray()))
	_assert(visible_ids.has("factory_building_a"), "Favorites filter shows favorite assets")
	_assert(visible_ids.has("station_set_door_single"), "Favorites filter also shows recent assets")

	_assert(bool(editor.call("set_object_placement_scale_preset", 1.6)), "Scale preset setter accepts 1.6")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	palette = Dictionary(snapshot.get("palette", {}))
	_assert(is_equal_approx(float(palette.get("placement_scale", 0.0)), 1.6), "Scale preset updates placement scale")
	_assert(bool(editor.call("clear_palette_authoring_preferences_for_test")), "Palette test cleans isolated preferences")
	editor.queue_free()
	await _wait_frames(2)


func _test_builder_drag_preview_snapshot() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	_assert(bool(editor.call("set_palette_authoring_preferences_path_for_test", TEST_PREFERENCES_PATH)), "Builder preview test uses an isolated preference path")
	root.add_child(editor)
	await _wait_frames(14)
	_assert(bool(editor.call("activate_runtime_builder_tool", "pipe_line")), "Pipe line activates")
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	var network: Dictionary = Dictionary(builder.get("network", {}))
	var preview: Dictionary = Dictionary(builder.get("network_drag_preview", {}))
	_assert(String(Dictionary(snapshot.get("network_drag_tool", {})).get("kind", "")) == "pipe", "Network kind is pipe")
	_assert(bool(network.get("enabled", false)), "Network snapshot is enabled for pipe")
	_assert(bool(preview.get("active", false)), "Builder snapshot exposes active network preview")
	_assert(String(preview.get("kind", "")) == "pipe", "Builder preview summary keeps network kind")
	_assert(String(preview.get("label", "")).contains("Pipe"), "Builder preview summary has a readable label")
	_assert(bool(editor.call("clear_palette_authoring_preferences_for_test")), "Builder preview test cleans isolated preferences")
	editor.queue_free()
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
