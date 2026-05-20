extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const MAP_PATH: String = "res://maps/station_outpost_64x64.json"
const GENERATOR_PATH: String = "res://scripts/tools/generate_station_outpost_64x64.gd"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_494_station_outpost_64_map.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_494 Station Outpost 64x64 Map ===")
	_test_docs()
	_test_map_authoring()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_494 task file exists")
	_assert(FileAccess.file_exists(GENERATOR_PATH), "Station outpost generator exists")
	_assert(_read_text(TASK_DOC_PATH).contains("64x64"), "Task documents the 64x64 map goal")
	_assert(_read_text(STATUS_PATH).contains("TASK_494 - Station Outpost 64x64 Map"), "Implementation status tracks TASK_494")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_494 - Station Outpost 64x64 Map"), "Roadmap lists TASK_494")


func _test_map_authoring() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(map_data != null, "Station outpost map loads")
	if map_data == null:
		return
	_assert(not bool(map_data.call("has_load_issue")), "Station outpost map has no load issue")
	_assert(Vector2i(map_data.call("get_grid_size")) == Vector2i(64, 64), "Station outpost map is exactly 64x64")
	_assert(Array(map_data.call("get_tiles")).size() == 4096, "Station outpost map contains 4096 tiles")
	_assert(int(map_data.call("get_mission_slot_count")) == 8, "Station outpost map exposes eight mission slots")
	_assert(String(map_data.call("get_terrain_visual_theme_id")) == "ground_mission_mixed_v1", "Station outpost uses the mixed ground visual theme")
	for marker_id in [
		"spawn_alpha",
		"spawn_bravo",
		"objective_point",
		"rally_southwest",
		"factory_danger_zone",
		"ridge_recon_note",
	]:
		_assert(bool(map_data.call("has_marker", marker_id)), "Station outpost has marker %s" % marker_id)
	_assert(Array(map_data.call("get_patrol_path", "factory_watch_route")).size() >= 4, "Factory watch route is authored")
	_assert(Array(map_data.call("get_patrol_path", "station_loop_route")).size() >= 4, "Station loop route is authored")

	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain tile catalog loads for map validation")
	if catalog == null:
		return
	var counts: Dictionary = _count_map_features(map_data, catalog)
	_assert(int(counts.get("missing_catalog_ids", 0)) == 0, "All map type ids exist in the terrain catalog")
	_assert(int(counts.get("station_floor_tiles", 0)) >= 250, "Map has a large station floor footprint")
	_assert(int(counts.get("station_objects", 0)) >= 55, "Map has station walls, doors and interior assets")
	_assert(int(counts.get("station_door_assets", 0)) >= 6, "Map has multiple station door states/assets")
	_assert(int(counts.get("factory_objects", 0)) >= 7, "Map has a small factory yard")
	_assert(int(counts.get("pipe_objects", 0)) >= 18, "Map has pipe runs between station and factory")
	_assert(int(counts.get("height_tiles", 0)) >= 550, "Map has hills and raised terrain")
	_assert(int(counts.get("height_two_tiles", 0)) >= 60, "Map has level-two ridge tops")
	_assert(int(counts.get("cliff_tiles", 0)) >= 30, "Map has explicit cliff assets")
	_assert(int(counts.get("nature_cover_objects", 0)) >= 35, "Map has natural cover outside the outpost")


func _count_map_features(map_data, catalog) -> Dictionary:
	var counts: Dictionary = {
		"station_floor_tiles": 0,
		"station_objects": 0,
		"station_door_assets": 0,
		"factory_objects": 0,
		"pipe_objects": 0,
		"height_tiles": 0,
		"height_two_tiles": 0,
		"cliff_tiles": 0,
		"nature_cover_objects": 0,
		"missing_catalog_ids": 0,
	}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var type_id: String = String(tile_data.type_id).strip_edges().to_lower()
		var object_type_id: String = String(tile_data.object_type_id).strip_edges().to_lower()
		if type_id.is_empty() or not bool(catalog.call("has_type", type_id)):
			counts["missing_catalog_ids"] = int(counts["missing_catalog_ids"]) + 1
		if not object_type_id.is_empty() and not bool(catalog.call("has_type", object_type_id)):
			counts["missing_catalog_ids"] = int(counts["missing_catalog_ids"]) + 1
		if type_id.begins_with("station_set_floor"):
			counts["station_floor_tiles"] = int(counts["station_floor_tiles"]) + 1
		if object_type_id.begins_with("station_set_"):
			counts["station_objects"] = int(counts["station_objects"]) + 1
		if object_type_id.contains("door"):
			counts["station_door_assets"] = int(counts["station_door_assets"]) + 1
		if object_type_id.begins_with("factory_"):
			counts["factory_objects"] = int(counts["factory_objects"]) + 1
		if object_type_id.begins_with("spacekit_pipe"):
			counts["pipe_objects"] = int(counts["pipe_objects"]) + 1
		if int(tile_data.height_level) > 0:
			counts["height_tiles"] = int(counts["height_tiles"]) + 1
		if int(tile_data.height_level) >= 2:
			counts["height_two_tiles"] = int(counts["height_two_tiles"]) + 1
		if type_id.begins_with("cliff_"):
			counts["cliff_tiles"] = int(counts["cliff_tiles"]) + 1
		if object_type_id.begins_with("nature_") or object_type_id.begins_with("rock_"):
			counts["nature_cover_objects"] = int(counts["nature_cover_objects"]) + 1
	return counts


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
