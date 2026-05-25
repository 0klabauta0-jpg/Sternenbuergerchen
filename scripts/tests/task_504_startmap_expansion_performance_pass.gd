extends SceneTree

const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")

const SOURCE_MAP_PATH: String = "res://maps/station_outpost_64x64.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const GENERATOR_PATH: String = "res://scripts/tools/generate_station_outpost_192x192.gd"
const TASK_DOC_PATH: String = "res://docs/tasks/TASK_504_startmap_expansion_performance_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const META_FLOW_PATH: String = "res://scripts/meta/meta_layer_flow.gd"

const SOURCE_SIZE: Vector2i = Vector2i(64, 64)
const LARGE_SIZE: Vector2i = Vector2i(192, 192)
const CENTER_OFFSET: Vector2i = Vector2i(64, 64)

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_504 Startmap Expansion Performance Pass ===")
	_test_docs_and_catalog_reference()
	_test_large_map_authoring()
	await _test_large_map_visual_streaming()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_docs_and_catalog_reference() -> void:
	_assert(FileAccess.file_exists(TASK_DOC_PATH), "TASK_504 task file exists")
	_assert(FileAccess.file_exists(GENERATOR_PATH), "192x192 startmap generator exists")
	_assert(_read_text(TASK_DOC_PATH).contains("192x192"), "Task documents the 192x192 target")
	_assert(_read_text(STATUS_PATH).contains("TASK_504 - Startmap Expansion Performance Pass"), "Implementation status tracks TASK_504")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_504 - Startmap Expansion Performance Pass"), "Roadmap lists TASK_504")
	var meta_source: String = _read_text(META_FLOW_PATH)
	_assert(meta_source.contains('"mission_id": "frontier_probe"'), "Homebase catalog still contains frontier_probe")
	_assert(meta_source.contains('"map_file_path": "res://maps/station_outpost_192x192.json"'), "frontier_probe uses the expanded startmap")


func _test_large_map_authoring() -> void:
	var load_started_usec: int = Time.get_ticks_usec()
	var source_map = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", SOURCE_MAP_PATH)
	var large_map = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", LARGE_MAP_PATH)
	var load_elapsed_msec: int = int((Time.get_ticks_usec() - load_started_usec) / 1000)
	_assert(source_map != null, "Source 64x64 map loads")
	_assert(large_map != null, "Expanded 192x192 map loads")
	if source_map == null or large_map == null:
		return
	_assert(not bool(large_map.call("has_load_issue")), "Expanded map has no load issue")
	_assert(Vector2i(large_map.call("get_grid_size")) == LARGE_SIZE, "Expanded map is exactly 192x192")
	_assert(Array(large_map.call("get_tiles")).size() == 36864, "Expanded map contains 36,864 tiles")
	_assert(load_elapsed_msec < 2500, "Expanded map JSON load stays under a local smoke budget (%d ms)" % load_elapsed_msec)
	_assert(String(large_map.call("get_terrain_visual_theme_id")) == String(source_map.call("get_terrain_visual_theme_id")), "Expanded map keeps the source visual theme")
	_assert(int(large_map.call("get_mission_slot_count")) == int(source_map.call("get_mission_slot_count")), "Expanded map keeps mission slot count")
	_assert(_center_sector_matches_source(source_map, large_map), "Center 64x64 sector preserves the original startmap tile truth")
	_assert(_markers_shifted_to_center(source_map, large_map), "Mission markers are shifted once into the center sector")
	_assert(Array(large_map.call("get_marker_ids")).size() == Array(source_map.call("get_marker_ids")).size(), "Expanded map does not duplicate mission markers")
	_assert(Array(large_map.call("get_patrol_path", "factory_watch_route")).size() >= 4, "Factory patrol route survives in the center sector")
	_assert(Array(large_map.call("get_patrol_path", "station_loop_route")).size() >= 4, "Station patrol route survives in the center sector")

	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain catalog loads for expanded map validation")
	if catalog == null:
		return
	var counts: Dictionary = _count_map_features(large_map, catalog)
	_assert(int(counts.get("missing_catalog_ids", 0)) == 0, "All expanded map type ids exist in the terrain catalog")
	_assert(int(counts.get("station_floor_tiles", 0)) >= 2200, "Expanded map has station floor content in multiple sectors")
	_assert(int(counts.get("station_objects", 0)) >= 450, "Expanded map has repeated station walls, doors and interiors")
	_assert(int(counts.get("factory_objects", 0)) >= 60, "Expanded map has repeated factory content")
	_assert(int(counts.get("pipe_objects", 0)) >= 160, "Expanded map has repeated pipe runs")
	_assert(int(counts.get("height_tiles", 0)) >= 4900, "Expanded map has hills across sectors")
	_assert(_all_sectors_have_content(large_map), "All nine 64x64 sectors contain visible map content")


func _test_large_map_visual_streaming() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", LARGE_MAP_PATH)
	_assert(map_data != null, "Expanded map loads for render streaming")
	if map_data == null:
		return
	root.size = Vector2i(1920, 1080)
	var view = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(4)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(int(snapshot.get("total_tile_count", 0)) == 36864, "3D view sees the full expanded tile count")
	_assert(bool(snapshot.get("visual_streaming_active", false)), "3D view activates visual streaming above 4096 tiles")
	_assert(int(snapshot.get("rendered_tile_count", 0)) < int(snapshot.get("total_tile_count", 0)), "3D view renders only active chunks")
	_assert(int(snapshot.get("visual_streaming_skipped_tile_count", 0)) > 0, "3D view skips off-camera chunks")
	_assert(int(snapshot.get("rendered_tile_count", 0)) <= 9000, "Initial render stays inside the active chunk smoke budget")
	_assert(int(snapshot.get("map_render_duration_msec", -1)) >= 0, "3D view records render duration")
	view.queue_free()
	await _wait_frames(2)


func _center_sector_matches_source(source_map, large_map) -> bool:
	var source_lookup: Dictionary = _build_tile_lookup(source_map)
	var large_lookup: Dictionary = _build_tile_lookup(large_map)
	for source_grid in source_lookup.keys():
		var target_grid: Vector2i = Vector2i(source_grid) + CENTER_OFFSET
		if not large_lookup.has(target_grid):
			return false
		if not _tiles_match(source_lookup[source_grid], large_lookup[target_grid]):
			return false
	return true


func _tiles_match(source_tile, target_tile) -> bool:
	return (
		String(source_tile.type_id) == String(target_tile.type_id)
		and String(source_tile.object_type_id) == String(target_tile.object_type_id)
		and bool(source_tile.walkable) == bool(target_tile.walkable)
		and bool(source_tile.blocks_los) == bool(target_tile.blocks_los)
		and int(source_tile.cover_value) == int(target_tile.cover_value)
		and int(source_tile.height_level) == int(target_tile.height_level)
		and int(source_tile.object_height) == int(target_tile.object_height)
		and absf(float(source_tile.object_rotation_degrees) - float(target_tile.object_rotation_degrees)) <= 0.001
		and absf(float(source_tile.object_scale) - float(target_tile.object_scale)) <= 0.001
		and String(source_tile.surface_type) == String(target_tile.surface_type)
		and String(source_tile.edge_type) == String(target_tile.edge_type)
	)


func _markers_shifted_to_center(source_map, large_map) -> bool:
	for marker_id in PackedStringArray(source_map.call("get_marker_ids")):
		if not bool(large_map.call("has_marker", marker_id)):
			return false
		var source_position: Vector2 = Vector2(source_map.call("get_marker_position", marker_id, Vector2.ZERO))
		var source_grid: Vector2i = _world_to_grid(source_map, source_position)
		var large_position: Vector2 = Vector2(large_map.call("get_marker_position", marker_id, Vector2.ZERO))
		var large_grid: Vector2i = _world_to_grid(large_map, large_position)
		if large_grid != source_grid + CENTER_OFFSET:
			return false
	return true


func _all_sectors_have_content(map_data) -> bool:
	var sector_counts: Dictionary = {}
	for x in range(3):
		for y in range(3):
			sector_counts[Vector2i(x, y)] = 0
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		var sector := Vector2i(grid.x / SOURCE_SIZE.x, grid.y / SOURCE_SIZE.y)
		if String(tile_data.type_id) != "ground_flat" or not String(tile_data.object_type_id).is_empty() or int(tile_data.height_level) > 0:
			sector_counts[sector] = int(sector_counts.get(sector, 0)) + 1
	for sector in sector_counts.keys():
		if int(sector_counts.get(sector, 0)) < 500:
			return false
	return true


func _count_map_features(map_data, catalog) -> Dictionary:
	var counts: Dictionary = {
		"station_floor_tiles": 0,
		"station_objects": 0,
		"factory_objects": 0,
		"pipe_objects": 0,
		"height_tiles": 0,
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
		if object_type_id.begins_with("factory_"):
			counts["factory_objects"] = int(counts["factory_objects"]) + 1
		if object_type_id.begins_with("spacekit_pipe"):
			counts["pipe_objects"] = int(counts["pipe_objects"]) + 1
		if int(tile_data.height_level) > 0:
			counts["height_tiles"] = int(counts["height_tiles"]) + 1
	return counts


func _build_tile_lookup(map_data) -> Dictionary:
	var result: Dictionary = {}
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data != null:
			result[Vector2i(tile_data.grid_position)] = tile_data
	return result


func _world_to_grid(map_data, world_position: Vector2) -> Vector2i:
	var tile_size: Dictionary = Dictionary(map_data.call("get_tile_size"))
	var half_width: float = maxf(float(tile_size.get("half_width", 64.0)), 0.001)
	var half_height: float = maxf(float(tile_size.get("half_height", 32.0)), 0.001)
	var delta: Vector2 = world_position - Vector2(map_data.call("get_grid_origin"))
	var grid_x: float = ((delta.y / half_height) + (delta.x / half_width)) * 0.5
	var grid_y: float = ((delta.y / half_height) - (delta.x / half_width)) * 0.5
	return Vector2i(roundi(grid_x), roundi(grid_y))


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


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
