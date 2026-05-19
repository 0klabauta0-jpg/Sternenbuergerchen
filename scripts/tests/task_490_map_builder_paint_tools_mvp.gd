extends SceneTree

const PLUGIN_SCRIPT_PATH: String = "res://addons/map_builder_workbench/map_builder_workbench_plugin.gd"
const WORKBENCH_SCENE_PATH: String = "res://scenes/editor/map_builder_workbench.tscn"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_490_map_builder_paint_tools_mvp.md"
const TOOLING_CONTRACT_PATH: String = "res://docs/dev/map_builder_tooling_spike_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_490 Map Builder Paint Tools MVP ===")
	_test_docs()
	_test_plugin_paint_contract()
	_test_workbench_paint_api()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_490 task file exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Paint-/Erase-/Rotate"), "Task documents paint/erase/rotate tools")
	_assert(_read_text(TOOLING_CONTRACT_PATH).contains("TASK_490"), "Tooling contract tracks TASK_490")
	_assert(_read_text(STATUS_PATH).contains("TASK_490 - Map Builder Paint Tools MVP"), "Implementation status tracks TASK_490")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_490 - Map Builder Paint Tools MVP"), "Roadmap lists TASK_490")


func _test_plugin_paint_contract() -> void:
	var script := _read_text(PLUGIN_SCRIPT_PATH)
	_assert(script.contains("ItemList"), "Dock exposes an ItemList palette")
	_assert(script.contains("OptionButton"), "Dock exposes category filtering")
	_assert(script.contains("TOOL_PAINT"), "Plugin has a paint tool")
	_assert(script.contains("TOOL_ERASE"), "Plugin has an erase tool")
	_assert(script.contains("_forward_3d_gui_input"), "Plugin handles 3D viewport input")
	_assert(script.contains("MOUSE_BUTTON_LEFT"), "Plugin paints on left click")
	_assert(script.contains("KEY_Q") and script.contains("KEY_E"), "Plugin supports Q/E rotation")
	_assert(script.contains("place_grid_item"), "Plugin writes GridMap tiles through Workbench API")
	_assert(script.contains("place_prop"), "Plugin writes props through Workbench API")
	_assert(script.contains("AssetPlacerProps"), "Plugin keeps prop authoring under AssetPlacerProps")


func _test_workbench_paint_api() -> void:
	var scene: PackedScene = load(WORKBENCH_SCENE_PATH) as PackedScene
	_assert(scene != null, "Workbench scene loads")
	if scene == null:
		return
	var workbench = scene.instantiate()
	workbench.auto_configure_on_ready = false
	workbench.seed_demo_layout_when_empty = false
	get_root().add_child(workbench)
	var snapshot: Dictionary = Dictionary(workbench.call("configure_workbench", true))
	_assert(int(snapshot.get("mesh_library_item_count", 0)) >= 15, "Workbench still builds MeshLibrary for paint API")
	_assert(int(snapshot.get("grid_used_cell_count", -1)) == 0, "Paint verifier starts with an empty GridMap")
	_assert(bool(workbench.call("place_grid_item", 2, Vector3i(1, 0, 0), 90.0)), "place_grid_item sets a road tile")
	_assert(bool(workbench.call("place_grid_item", 8, Vector3i(2, 0, 2), 0.0)), "place_grid_item sets a floor tile")
	var prop = workbench.call("place_prop", "factory_building_a", Vector2i(2, 2), 180.0, 1.15)
	_assert(prop != null, "place_prop creates a prop node")
	_assert(prop != null and prop.has_meta("sb_type_id"), "Prop node carries sb_type_id")
	_assert(prop != null and prop.has_meta("sb_grid_position"), "Prop node carries sb_grid_position")
	var grid_map: GridMap = workbench.call("get_grid_map")
	_assert(grid_map != null and int(grid_map.get_cell_item(Vector3i(1, 0, 0))) == 2, "GridMap stores painted road item")
	_assert(bool(workbench.call("erase_grid_cell", Vector3i(5, 0, 5))), "erase_grid_cell handles empty cells")
	var result: Dictionary = Dictionary(workbench.call("compile_to_map_data"))
	_assert(bool(result.get("ok", false)), "Painted workbench compiles")
	_assert(Array(result.get("issues", [])).is_empty(), "Painted compile has no issues")
	var map_data = result.get("map_data", null)
	_assert(map_data != null, "Painted compile returns map data")
	if map_data != null:
		var road_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
		var building_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
		_assert(road_tile != null and String(road_tile.type_id) == "spacekit_terrain_road_straight", "Painted road compiles by item id")
		_assert(road_tile != null and String(road_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Painted road compiles road surface")
		_assert(road_tile != null and absf(float(road_tile.object_rotation_degrees)) > 0.001, "Painted road rotation compiles")
		_assert(building_tile != null and String(building_tile.type_id) == "modular_floor", "Painted floor remains base type")
		_assert(building_tile != null and String(building_tile.object_type_id) == "factory_building_a", "Painted prop compiles to object layer")
		_assert(building_tile != null and absf(float(building_tile.object_scale) - 1.15) <= 0.001, "Painted prop scale compiles")
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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
