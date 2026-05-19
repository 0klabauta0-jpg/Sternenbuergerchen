extends SceneTree

const IMPORTER_SCRIPT: GDScript = preload("res://scripts/editor/map_builder_scene_importer.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const TASK_DOC_PATH: String = "res://docs/tasks/TASK_486_map_builder_tooling_spike.md"
const TOOLING_CONTRACT_PATH: String = "res://docs/dev/map_builder_tooling_spike_contract.md"
const WORKFLOW_CONTRACT_PATH: String = "res://docs/dev/map_editor_asset_workflow_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const ROUNDTRIP_PATH: String = "user://task_486_map_builder_import_roundtrip.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_486 Map Builder Tooling Spike ===")
	_test_docs()
	_test_recommendation_summary()
	_test_dictionary_authoring_import()
	_test_node_metadata_import()
	_test_grid_map_import()
	_test_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_486 task file exists")
	_assert(FileAccess.file_exists(TOOLING_CONTRACT_PATH), "Map builder tooling contract exists")
	_assert(_read_text(TASK_DOC_PATH).contains("Godot Asset Placer"), "Task documents the Asset Placer candidate")
	_assert(_read_text(TOOLING_CONTRACT_PATH).contains("GridMap"), "Tooling contract documents GridMap authoring")
	_assert(_read_text(WORKFLOW_CONTRACT_PATH).contains("Street and water plates"), "Existing workflow contract still documents road/water layering")
	_assert(_read_text(STATUS_PATH).contains("TASK_486 - Map Builder Tooling Spike"), "Implementation status tracks TASK_486")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_486 - Map Builder Tooling Spike"), "Roadmap lists TASK_486")


func _test_recommendation_summary() -> void:
	var importer = IMPORTER_SCRIPT.new()
	var recommendation: Dictionary = Dictionary(importer.call("summarize_tooling_recommendation"))
	_assert(String(recommendation.get("recommended_path", "")).contains("gridmap"), "Recommendation keeps GridMap in the main path")
	_assert(String(recommendation.get("prop_authoring", "")).contains("Asset-Placer"), "Recommendation keeps Asset-Placer-style prop authoring")
	_assert(String(recommendation.get("gameplay_truth", "")).contains("TerrainMapData"), "Recommendation keeps TerrainMapData as gameplay truth")


func _test_dictionary_authoring_import() -> void:
	var importer = IMPORTER_SCRIPT.new()
	var result: Dictionary = Dictionary(importer.call("build_map_from_authoring", {
		"map_name": "task_486_dictionary",
		"grid_size": Vector2i(5, 3),
		"terrain_visual_theme_id": "ground_mission_mixed_v1",
		"placements": [
			{"type_id": "spacekit_terrain_road_straight", "grid_position": Vector2i(0, 0), "rotation_degrees": 90.0},
			{"type_id": "spacekit_terrain_road_straight", "grid_position": Vector2i(1, 1), "rotation_degrees": 90.0},
			{"type_id": "factory_building_a", "grid_position": Vector2i(1, 1), "rotation_degrees": 180.0, "object_scale": 1.6},
			{"type_id": "nature_ground_dirt_river_tile", "grid_position": Vector2i(2, 1)},
			{"type_id": "factory_building_b", "grid_position": Vector2i(2, 1), "object_scale": 1.25},
			{"type_id": "modular_wall", "grid_position": Vector2i(3, 1), "rotation_degrees": 270.0, "object_scale": 1.2},
		],
	}))
	_assert(bool(result.get("ok", false)), "Dictionary authoring import succeeds")
	_assert(Array(result.get("issues", [])).is_empty(), "Dictionary import has no issues")
	_assert(Array(result.get("warnings", [])).size() >= 1, "Layered transforms produce an explicit warning")
	var map_data = result.get("map_data", null)
	_assert(map_data != null, "Dictionary import returns TerrainMapData")
	if map_data == null:
		return
	_assert(String(map_data.call("get_terrain_visual_theme_id")) == "ground_mission_mixed_v1", "Importer preserves terrain visual theme")
	var road_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	_assert(String(road_tile.type_id) == "spacekit_terrain_road_straight", "Road plate writes base type_id")
	_assert(String(road_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Road plate writes road surface")
	_assert(absf(float(road_tile.object_rotation_degrees) - 90.0) <= 0.001, "Standalone road keeps its authored rotation")
	var building_on_road = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	_assert(String(building_on_road.type_id) == "spacekit_terrain_road_straight", "Road under building remains the base type")
	_assert(String(building_on_road.object_type_id) == "factory_building_a", "Building imports onto object layer")
	_assert(String(building_on_road.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Building does not reset road surface")
	_assert(absf(float(building_on_road.object_rotation_degrees) - 180.0) <= 0.001, "Top object transform wins on layered tile")
	_assert(absf(float(building_on_road.object_scale) - 1.6) <= 0.001, "Object scale imports from authoring data")
	var building_on_water = map_data.call("get_tile_at_grid", Vector2i(2, 1))
	_assert(String(building_on_water.type_id) == "nature_ground_dirt_river_tile", "Water tile remains the base type under object")
	_assert(String(building_on_water.object_type_id) == "factory_building_b", "Building imports over water")
	_assert(String(building_on_water.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER, "Object does not reset water surface")
	var wall_tile = map_data.call("get_tile_at_grid", Vector2i(3, 1))
	_assert(String(wall_tile.type_id) == "modular_wall", "Structure-like modular wall imports as base type")
	_assert(absf(float(wall_tile.object_rotation_degrees) - 270.0) <= 0.001, "Modular wall rotation imports")
	_assert(absf(float(wall_tile.object_scale) - 1.2) <= 0.001, "Modular wall scale imports")


func _test_node_metadata_import() -> void:
	var root := Node3D.new()
	var road := Node3D.new()
	road.set_meta("sb_type_id", "spacekit_terrain_road_corner")
	road.set_meta("sb_grid_position", Vector2i(0, 1))
	road.rotation_degrees.y = 90.0
	root.add_child(road)
	var prop := Node3D.new()
	prop.set_meta("sb_type_id", "factory_building_c")
	prop.set_meta("sb_grid_position", Vector2i(0, 1))
	prop.rotation_degrees.y = 45.0
	prop.scale = Vector3(1.4, 1.4, 1.4)
	root.add_child(prop)
	var importer = IMPORTER_SCRIPT.new()
	var result: Dictionary = Dictionary(importer.call("build_map_from_nodes", root, {"map_name": "task_486_nodes", "grid_size": Vector2i(2, 2)}))
	_assert(bool(result.get("ok", false)), "Node metadata import succeeds")
	var map_data = result.get("map_data", null)
	var tile = map_data.call("get_tile_at_grid", Vector2i(0, 1)) if map_data != null else null
	_assert(tile != null, "Node import target tile exists")
	if tile != null:
		_assert(String(tile.type_id) == "spacekit_terrain_road_corner", "Node road writes base type")
		_assert(String(tile.object_type_id) == "factory_building_c", "Node prop writes object layer")
		_assert(String(tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Node prop preserves road surface")
		_assert(absf(float(tile.object_rotation_degrees) - 45.0) <= 0.001, "Node transform rotation imports")
		_assert(absf(float(tile.object_scale) - 1.4) <= 0.001, "Node transform scale imports")
	root.queue_free()


func _test_grid_map_import() -> void:
	var grid_map := GridMap.new()
	grid_map.set_cell_item(Vector3i(0, 0, 0), 10)
	grid_map.set_cell_item(Vector3i(1, 1, 0), 20)
	var importer = IMPORTER_SCRIPT.new()
	var result: Dictionary = Dictionary(importer.call("build_map_from_grid_map", grid_map, {
		10: {"type_id": "spacekit_terrain_road_split", "rotation_degrees": 180.0},
		20: "nature_ground_dirt_river_tile",
	}, {"map_name": "task_486_gridmap"}))
	_assert(bool(result.get("ok", false)), "GridMap import succeeds")
	var stats: Dictionary = Dictionary(result.get("stats", {}))
	_assert(int(stats.get("applied_count", 0)) == 2, "GridMap import applies all mapped cells")
	var map_data = result.get("map_data", null)
	_assert(map_data != null and Vector2i(map_data.call("get_grid_size")) == Vector2i(2, 1), "GridMap import infers x/z map size")
	if map_data != null:
		var road_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
		var water_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
		_assert(String(road_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "GridMap road item writes road surface")
		_assert(absf(float(road_tile.object_rotation_degrees) - 180.0) <= 0.001, "GridMap item mapping can provide rotation")
		_assert(String(water_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER, "GridMap water item writes water surface")
		_assert(int(water_tile.height_level) == 1, "GridMap cell y can author height level")
	grid_map.queue_free()


func _test_roundtrip() -> void:
	var importer = IMPORTER_SCRIPT.new()
	var result: Dictionary = Dictionary(importer.call("build_map_from_authoring", {
		"map_name": "task_486_roundtrip",
		"grid_size": Vector2i(2, 2),
		"placements": [
			{"type_id": "spacekit_terrain_road_end", "grid_position": Vector2i(0, 0), "rotation_degrees": 90.0},
			{"type_id": "factory_building_d", "grid_position": Vector2i(0, 0), "object_scale": 1.35},
			{"type_id": "nature_ground_dirt_river_tile", "grid_position": Vector2i(1, 0)},
		],
	}))
	var map_data = result.get("map_data", null)
	_assert(bool(result.get("ok", false)) and map_data != null, "Roundtrip fixture import succeeds")
	if map_data == null:
		return
	_assert(map_data.call("save_to_file", ROUNDTRIP_PATH) == OK, "Imported map saves")
	var loaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", ROUNDTRIP_PATH)
	var road_tile = loaded.call("get_tile_at_grid", Vector2i(0, 0)) if loaded != null else null
	var water_tile = loaded.call("get_tile_at_grid", Vector2i(1, 0)) if loaded != null else null
	_assert(road_tile != null and String(road_tile.object_type_id) == "factory_building_d", "Roundtrip preserves imported object layer")
	_assert(road_tile != null and String(road_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROAD, "Roundtrip preserves imported road surface")
	_assert(road_tile != null and absf(float(road_tile.object_scale) - 1.35) <= 0.001, "Roundtrip preserves imported scale")
	_assert(water_tile != null and String(water_tile.surface_type) == TERRAIN_TILE_DATA_SCRIPT.SURFACE_WATER, "Roundtrip preserves imported water surface")


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
