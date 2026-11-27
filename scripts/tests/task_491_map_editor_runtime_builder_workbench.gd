extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const WORKBENCH_SCENE: PackedScene = preload("res://scenes/editor/map_builder_workbench.tscn")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_491_map_editor_runtime_builder_workbench.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const TOOLING_CONTRACT_PATH: String = "res://docs/dev/map_builder_tooling_spike_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const WORKBENCH_SCRIPT_PATH: String = "res://scripts/editor/map_builder_workbench.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_491 Map Editor Runtime Builder Workbench ===")
	_test_docs()
	await _test_runtime_builder_tools()
	_test_workbench_f6_runtime_entry()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_491 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Runtime-Map-Editor"), "Task documents runtime map editor target")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Runtime Builder Workbench"), "Map editor contract documents runtime builder")
	_assert(_read_text(TOOLING_CONTRACT_PATH).contains("TASK_491"), "Tooling contract tracks TASK_491 correction")
	_assert(_read_text(STATUS_PATH).contains("TASK_491 - Map Editor Runtime Builder Workbench"), "Implementation status tracks TASK_491")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_491 - Map Editor Runtime Builder Workbench"), "Roadmap lists TASK_491")


func _test_runtime_builder_tools() -> void:
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	var builder: Dictionary = Dictionary(snapshot.get("runtime_builder_workbench", {}))
	_assert(bool(builder.get("enabled", false)), "Runtime builder rail is created in the map editor")
	_assert(int(builder.get("tool_count", 0)) >= 10, "Runtime builder exposes core tool buttons")
	_assert(float(builder.get("palette_panel_offset_left", 0.0)) >= float(builder.get("rail_width", 0.0)), "Palette is shifted next to the builder rail")
	_assert(not bool(builder.get("ui_sets_gameplay_truth", true)), "Runtime builder is documented as non-authoritative UI")
	var tool_ids: PackedStringArray = PackedStringArray(builder.get("tool_ids", PackedStringArray()))
	for required_tool in ["select", "terrain", "road", "asset", "erase", "height", "marker", "patrol", "rotate_left", "rotate_right"]:
		_assert(tool_ids.has(required_tool), "Runtime builder exposes %s" % required_tool)

	_assert(bool(editor.call("activate_runtime_builder_tool", "road")), "Road quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("active_tool", "")) == "terrain_brush", "Road quick tool enables brush")
	_assert(String(snapshot.get("selected_type_id", "")) == "spacekit_terrain_road_straight", "Road quick tool selects the road plate")

	_assert(bool(editor.call("activate_runtime_builder_tool", "asset")), "Asset quick tool activates")
	snapshot = Dictionary(editor.call("get_map_editor_usability_snapshot", false))
	_assert(String(snapshot.get("active_tool", "")) == "terrain_brush", "Asset quick tool keeps brush active")
	_assert(String(snapshot.get("selected_type_id", "")) == "factory_building_a", "Asset quick tool selects a building asset")

	_assert(bool(editor.call("activate_runtime_builder_tool", "erase")), "Erase quick tool activates")
	_assert(String(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("active_tool", "")) == "eraser", "Erase quick tool switches to eraser")
	_assert(bool(editor.call("activate_runtime_builder_tool", "height")), "Height quick tool activates")
	_assert(String(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("active_tool", "")) == "height", "Height quick tool switches to height")
	_assert(bool(editor.call("activate_runtime_builder_tool", "marker")), "Marker quick tool activates")
	_assert(String(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("active_tool", "")) == "marker", "Marker quick tool switches to marker")
	_assert(bool(editor.call("activate_runtime_builder_tool", "patrol")), "Patrol quick tool activates")
	_assert(String(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("active_tool", "")) == "patrol", "Patrol quick tool switches to patrol")
	_assert(bool(editor.call("activate_runtime_builder_tool", "select")), "Select quick tool activates")
	_assert(String(Dictionary(editor.call("get_map_editor_usability_snapshot", false)).get("active_tool", "")) == "select", "Select quick tool switches to select")
	editor.queue_free()
	await _wait_frames(2)


func _test_workbench_f6_runtime_entry() -> void:
	var workbench = WORKBENCH_SCENE.instantiate()
	_assert(workbench != null, "MapBuilderWorkbench scene still loads")
	if workbench == null:
		return
	_assert(bool(workbench.get("launch_runtime_map_editor_on_play")), "Workbench defaults to launching the runtime map editor on play")
	var snapshot: Dictionary = Dictionary(workbench.call("get_workbench_snapshot"))
	_assert(String(snapshot.get("runtime_map_editor_scene_path", "")) == "res://scenes/editor/map_editor.tscn", "Workbench points F6 to map_editor.tscn")
	var script := _read_text(WORKBENCH_SCRIPT_PATH)
	_assert((script.contains("change_scene_to_file(RUNTIME_MAP_EDITOR_SCENE_PATH)") or script.contains("_change_scene_via_service(get_tree(), RUNTIME_MAP_EDITOR_SCENE_PATH")), "Workbench changes scene to runtime map editor")
	_assert(script.contains("DisplayServer.get_name() == \"headless\""), "Workbench keeps headless tests on the compile path")
	workbench.queue_free()


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
