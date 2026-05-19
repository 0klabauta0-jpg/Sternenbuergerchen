extends SceneTree

const WORKBENCH_SCENE_PATH: String = "res://scenes/editor/map_builder_workbench.tscn"
const MANIFEST_PATH: String = "res://data/map_builder_workbench_manifest.json"
const WORKBENCH_SCRIPT_PATH: String = "res://scripts/editor/map_builder_workbench.gd"
const COMPILE_SCRIPT_PATH: String = "res://scripts/editor/compile_map_builder_workbench.gd"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_488_map_builder_workbench_meshlibrary_mvp.md"
const TOOLING_CONTRACT_PATH: String = "res://docs/dev/map_builder_tooling_spike_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const ROUNDTRIP_PATH: String = "user://task_488_map_builder_workbench_output.json"

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_488 Map Builder Workbench MeshLibrary MVP ===")
	_test_docs()
	_test_manifest()
	_test_workbench_scene()
	_test_compile_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_488 task file exists")
	_assert(FileAccess.file_exists(WORKBENCH_SCRIPT_PATH), "Workbench script exists")
	_assert(FileAccess.file_exists(COMPILE_SCRIPT_PATH), "Compile runner script exists")
	_assert(FileAccess.file_exists(WORKBENCH_SCENE_PATH), "Workbench scene exists")
	_assert(_read_text(TASK_DOC_PATH).contains("MeshLibrary"), "Task documents MeshLibrary scope")
	_assert(_read_text(TASK_DOC_PATH).contains("Asset-Placer-kompatible"), "Task documents Asset-Placer-compatible props")
	_assert(_read_text(TOOLING_CONTRACT_PATH).contains("TASK_488"), "Tooling contract tracks TASK_488")
	_assert(_read_text(STATUS_PATH).contains("TASK_488 - Map Builder Workbench MeshLibrary MVP"), "Implementation status tracks TASK_488")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_488 - Map Builder Workbench MeshLibrary MVP"), "Roadmap lists TASK_488")


func _test_manifest() -> void:
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(not manifest.is_empty(), "Workbench manifest parses")
	var mesh_section: Dictionary = Dictionary(manifest.get("mesh_library", {}))
	var items: Array = Array(mesh_section.get("items", []))
	_assert(items.size() >= 15, "Manifest contains at least 15 MeshLibrary items")
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var item_ids: Dictionary = {}
	var type_ids: Dictionary = {}
	for item_variant in items:
		if typeof(item_variant) != TYPE_DICTIONARY:
			_assert(false, "Manifest item is a Dictionary")
			continue
		var item: Dictionary = Dictionary(item_variant)
		var item_id: int = int(item.get("item_id", -1))
		var type_id: String = String(item.get("type_id", "")).strip_edges().to_lower()
		_assert(item_id > 0, "MeshLibrary item has a positive item_id: %s" % type_id)
		_assert(not item_ids.has(item_id), "MeshLibrary item_id is unique: %d" % item_id)
		item_ids[item_id] = true
		type_ids[type_id] = true
		_assert(catalog != null and bool(catalog.call("has_type", type_id)), "MeshLibrary type_id exists in TerrainTileCatalog: %s" % type_id)
		_assert(ResourceLoader.exists(String(item.get("model_path", ""))), "MeshLibrary model exists: %s" % type_id)
	_assert(type_ids.has("spacekit_terrain_road_straight"), "Manifest includes road straight")
	_assert(type_ids.has("nature_ground_dirt_river_tile"), "Manifest includes water tile")
	_assert(type_ids.has("modular_wall"), "Manifest includes modular wall")
	_assert(type_ids.has("station_wall_door"), "Manifest includes station door wall")
	var props: Array = Array(Dictionary(manifest.get("asset_placer_props", {})).get("sample_assets", []))
	var prop_type_ids: Dictionary = {}
	for prop_variant in props:
		var prop: Dictionary = Dictionary(prop_variant)
		var prop_type_id: String = String(prop.get("type_id", "")).strip_edges().to_lower()
		prop_type_ids[prop_type_id] = true
		_assert(catalog != null and bool(catalog.call("has_type", prop_type_id)), "Prop type_id exists in TerrainTileCatalog: %s" % prop_type_id)
		_assert(ResourceLoader.exists(String(prop.get("model_path", ""))), "Prop model exists: %s" % prop_type_id)
	_assert(prop_type_ids.has("factory_building_a"), "Manifest includes factory building prop")
	_assert(prop_type_ids.has("spacekit_rover"), "Manifest includes rover prop")
	_assert(prop_type_ids.has("station_computer"), "Manifest includes computer prop")


func _test_workbench_scene() -> void:
	var workbench = _instantiate_workbench()
	_assert(workbench != null, "Workbench scene instantiates")
	if workbench == null:
		return
	var snapshot: Dictionary = Dictionary(workbench.call("configure_workbench", true))
	_assert(int(snapshot.get("mesh_library_item_count", 0)) >= 15, "Workbench builds a MeshLibrary with core items")
	_assert(int(snapshot.get("item_type_map_count", 0)) >= 15, "Workbench keeps item_id to type_id mapping")
	_assert(int(snapshot.get("grid_used_cell_count", 0)) >= 15, "Workbench seeds demo GridMap cells")
	_assert(int(snapshot.get("prop_node_count", 0)) >= 4, "Workbench seeds Asset-Placer-compatible props")
	_assert(Array(snapshot.get("warnings", [])).is_empty(), "Workbench configuration has no warnings")
	var grid_map: GridMap = workbench.call("get_grid_map")
	var prop_root: Node3D = workbench.call("get_prop_root")
	var mesh_library: MeshLibrary = workbench.call("get_mesh_library")
	_assert(grid_map != null and grid_map.mesh_library == mesh_library, "GridMap uses generated MeshLibrary")
	_assert(prop_root != null and _has_prop_meta(prop_root, "factory_building_a"), "Factory prop exposes sb_* metadata")
	workbench.queue_free()


func _test_compile_roundtrip() -> void:
	var workbench = _instantiate_workbench()
	_assert(workbench != null, "Workbench scene instantiates for compile")
	if workbench == null:
		return
	var result: Dictionary = Dictionary(workbench.call("compile_to_map_data"))
	_assert(bool(result.get("ok", false)), "Workbench compiles to TerrainMapData")
	_assert(Array(result.get("issues", [])).is_empty(), "Workbench compile has no issues")
	var stats: Dictionary = Dictionary(result.get("stats", {}))
	_assert(int(stats.get("applied_count", 0)) >= 19, "Workbench compile applies GridMap cells and props")
	var map_data = result.get("map_data", null)
	_assert(map_data != null, "Workbench compile returns map data")
	if map_data != null:
		_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(8, 6), "Workbench map keeps manifest grid size")
		var road_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
		var water_tile = map_data.call("get_tile_at_grid", Vector2i(0, 1))
		var building_tile = map_data.call("get_tile_at_grid", Vector2i(1, 1))
		var computer_tile = map_data.call("get_tile_at_grid", Vector2i(0, 2))
		_assert(road_tile != null and String(road_tile.type_id) == "spacekit_terrain_road_straight", "GridMap road item compiles by item_id mapping")
		_assert(road_tile != null and String(road_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "GridMap road surface compiles")
		_assert(road_tile != null and absf(float(road_tile.object_rotation_degrees)) > 0.001, "Rotated GridMap cell compiles non-zero rotation")
		_assert(water_tile != null and String(water_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER, "GridMap water surface compiles")
		_assert(building_tile != null and String(building_tile.type_id) == "modular_floor", "Floor remains base type under building prop")
		_assert(building_tile != null and String(building_tile.object_type_id) == "factory_building_a", "Asset-Placer-compatible building prop compiles")
		_assert(building_tile != null and String(building_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Building prop does not reset floor surface")
		_assert(building_tile != null and absf(float(building_tile.object_scale) - 1.15) <= 0.001, "Prop object scale compiles")
		_assert(computer_tile != null and String(computer_tile.type_id) == "station_floor_panel", "Station floor remains base type under computer prop")
		_assert(computer_tile != null and String(computer_tile.object_type_id) == "station_computer", "Computer prop compiles on object layer")
	var save_result: Dictionary = Dictionary(workbench.call("save_compiled_map", ROUNDTRIP_PATH))
	_assert(bool(save_result.get("ok", false)), "Workbench save_compiled_map writes JSON")
	var loaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", ROUNDTRIP_PATH)
	var loaded_building = loaded.call("get_tile_at_grid", Vector2i(1, 1)) if loaded != null else null
	_assert(loaded_building != null and String(loaded_building.object_type_id) == "factory_building_a", "Roundtrip preserves compiled prop object")
	_assert(loaded_building != null and String(loaded_building.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Roundtrip preserves layered road surface")
	workbench.queue_free()


func _instantiate_workbench():
	var scene: PackedScene = load(WORKBENCH_SCENE_PATH) as PackedScene
	if scene == null:
		return null
	var workbench = scene.instantiate()
	workbench.auto_configure_on_ready = false
	get_root().add_child(workbench)
	return workbench


func _has_prop_meta(prop_root: Node, expected_type_id: String) -> bool:
	for child in prop_root.get_children():
		if not child.has_meta("sb_type_id"):
			continue
		if String(child.get_meta("sb_type_id")) != expected_type_id:
			continue
		return child.has_meta("sb_grid_position") and child.has_meta("sb_rotation_degrees") and child.has_meta("sb_object_scale")
	return false


func _read_json(path: String) -> Dictionary:
	var text := _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
