extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const LARGE_RENDER_SIZE: Vector2i = Vector2i(128, 128)
const HPA_TEST_SIZE: Vector2i = Vector2i(32, 32)
const CLUSTER_SIZE: int = 8

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_412 Large Map Streaming and Incremental HPA ===")
	await _test_large_map_visual_streaming_window()
	_test_hpa_dirty_cluster_rebuild()
	_test_simulation_root_uses_incremental_hpa_rebuild()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_large_map_visual_streaming_window() -> void:
	var map_data = _make_map_data(LARGE_RENDER_SIZE)
	var primary_view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(primary_view)
	var started_usec: int = Time.get_ticks_usec()
	primary_view.call("configure_from_map", map_data)
	await process_frame
	var first_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var render_duration_usec: int = Time.get_ticks_usec() - started_usec
	var total_tile_count: int = LARGE_RENDER_SIZE.x * LARGE_RENDER_SIZE.y
	_assert(bool(first_snapshot.get("visual_streaming_active", false)), "Large 128x128 map enables visual streaming")
	_assert(int(first_snapshot.get("total_tile_count", 0)) == total_tile_count, "Streaming snapshot keeps the logical total tile count")
	_assert(int(first_snapshot.get("rendered_tile_count", 0)) < total_tile_count, "Streaming renders fewer tiles than the full map")
	_assert(int(first_snapshot.get("visual_streaming_skipped_tile_count", 0)) > 0, "Streaming reports skipped off-window tiles")
	_assert(int(first_snapshot.get("visual_streaming_active_chunk_count", 0)) > 0, "Streaming reports active visual chunks")
	_assert(int(first_snapshot.get("ground_multimesh_tile_count", 0)) >= int(first_snapshot.get("rendered_tile_count", 0)), "Rendered streaming tiles stay in MultiMesh ground batches")
	_assert(int(first_snapshot.get("missing_map_asset_mapping_count", 99)) == 0, "Streaming fixture has no missing map asset mappings")
	_assert(render_duration_usec < 240000000, "Streaming render stays under the broad headless profile budget")

	var first_chunks: Array = Array(first_snapshot.get("visual_streaming_active_chunks", []))
	var far_tile = map_data.call("get_tile_at_grid", Vector2i(112, 112))
	primary_view.call("focus_world_position", Vector2(far_tile.world_position))
	await process_frame
	await process_frame
	var moved_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	var moved_chunks: Array = Array(moved_snapshot.get("visual_streaming_active_chunks", []))
	_assert(int(moved_snapshot.get("visual_streaming_refresh_count", 0)) >= 1, "Cross-chunk camera focus queues a visual streaming refresh")
	_assert(_chunk_entries_signature(first_chunks) != _chunk_entries_signature(moved_chunks), "Camera focus changes the active visual chunk window")
	_assert(int(moved_snapshot.get("rendered_tile_count", 0)) < total_tile_count, "Moved streaming window still avoids full-map rendering")
	primary_view.queue_free()


func _test_hpa_dirty_cluster_rebuild() -> void:
	var registry = _make_registry(HPA_TEST_SIZE)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	_assert(bool(graph.call("build_from_registry", registry, CLUSTER_SIZE)), "HPA full graph builds before incremental test")
	registry.call("clear_dirty_grid_positions")
	var dirty_grid := Vector2i(12, 12)
	var dirty_tile = registry.call("get_tile_at_grid", dirty_grid)
	dirty_tile.walkable = false
	registry.call("notify_tile_data_changed", [dirty_grid])
	var rebuilt: bool = bool(graph.call("rebuild_dirty_clusters_from_registry", registry, registry.call("get_dirty_grid_positions"), CLUSTER_SIZE))
	var stats: Dictionary = Dictionary(graph.call("get_last_build_stats"))
	_assert(rebuilt, "HPA dirty cluster rebuild succeeds")
	_assert(bool(stats.get("incremental", false)), "HPA dirty rebuild stats mark incremental mode")
	_assert(int(stats.get("dirty_cluster_count", 0)) == 1, "HPA dirty rebuild identifies one dirty cluster")
	_assert(int(stats.get("rebuilt_cluster_count", 0)) > 1 and int(stats.get("rebuilt_cluster_count", 0)) < int(stats.get("cluster_count", 99)), "HPA dirty rebuild touches neighbors without rebuilding every cluster")
	_assert(String(graph.call("get_component_key_for_grid", dirty_grid)).is_empty(), "Dirty blocked grid is removed from HPA components")
	_assert(int(stats.get("portal_count", 0)) > 0, "HPA dirty rebuild reindexes portals")
	registry.free()


func _test_simulation_root_uses_incremental_hpa_rebuild() -> void:
	var registry = _make_registry(HPA_TEST_SIZE)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var first_graph = simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var first_snapshot: Dictionary = _hpa_snapshot(simulation_root)
	_assert(first_graph != null and int(first_snapshot.get("build_count", 0)) == 1, "SimulationRoot builds the first HPA graph")
	_assert(Array(registry.call("get_dirty_grid_positions")).size() == 0, "SimulationRoot clears registry dirty grids after the full HPA build")

	var dirty_grid := Vector2i(12, 12)
	var dirty_tile = registry.call("get_tile_at_grid", dirty_grid)
	dirty_tile.walkable = false
	registry.call("notify_tile_data_changed", [dirty_grid])
	var second_graph = simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var second_snapshot: Dictionary = _hpa_snapshot(simulation_root)
	var second_stats: Dictionary = Dictionary(second_snapshot.get("last_build_stats", {}))
	_assert(second_graph == first_graph, "SimulationRoot reuses the existing HPA graph for dirty-cluster rebuilds")
	_assert(int(second_snapshot.get("build_count", 0)) == 2, "SimulationRoot counts the incremental HPA rebuild")
	_assert(bool(second_stats.get("incremental", false)), "SimulationRoot exposes incremental HPA rebuild stats")
	_assert(String(second_stats.get("runtime_rebuild_mode", "")) == "incremental", "SimulationRoot marks the runtime HPA rebuild mode")
	_assert(Array(registry.call("get_dirty_grid_positions")).size() == 0, "SimulationRoot clears registry dirty grids after incremental HPA rebuild")

	var third_graph = simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var third_snapshot: Dictionary = _hpa_snapshot(simulation_root)
	_assert(third_graph == first_graph, "Unchanged registry keeps using the same HPA graph")
	_assert(int(third_snapshot.get("cache_hit_count", 0)) >= 1, "Unchanged registry still records HPA cache hits")
	registry.free()
	simulation_root.free()


func _make_map_data(size: Vector2i):
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_412_streaming_%dx%d" % [size.x, size.y], size, Vector2(512.0, 256.0), 64.0, 32.0, 3)
	for tile_data in Array(map_data.call("get_tiles")):
		if tile_data == null:
			continue
		var grid: Vector2i = Vector2i(tile_data.grid_position)
		tile_data.type_id = "ground_flat"
		tile_data.object_type_id = ""
		tile_data.walkable = true
		tile_data.blocks_los = false
		tile_data.cover_value = 0
		tile_data.object_height = 0
		tile_data.height_level = 1 if (grid.x - 44) * (grid.x - 44) + (grid.y - 52) * (grid.y - 52) < 160 else 0
		tile_data.edge_type = TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE if int(tile_data.height_level) > 0 else TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE
		var surface_selector: int = posmod((grid.x * 5) + (grid.y * 3), 13)
		tile_data.surface_type = TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND if surface_selector == 0 else TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND
	return map_data


func _make_registry(size: Vector2i):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 64.0, 32.0)
	for x in range(size.x):
		for y in range(size.y):
			var grid_position := Vector2i(x, y)
			registry.call("register_tile", _make_tile(registry, grid_position, "%d_%d" % [x, y]))
	return registry


func _make_tile(registry, grid_position: Vector2i, tile_id: String, walkable: bool = true):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": tile_id,
		"type_id": "ground_flat" if walkable else "rock_large",
		"grid_position": grid_position,
		"world_position": registry.call("grid_to_world", grid_position),
		"walkable": walkable,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND if walkable else TERRAIN_TILE_DATA_SCRIPT.SURFACE_ROCK,
		"edge_type": TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE,
	})


func _hpa_snapshot(simulation_root) -> Dictionary:
	return Dictionary(Dictionary(simulation_root.call("get_navigation_debug_snapshot")).get("hpa_navigation", {}))


func _chunk_entries_signature(entries: Array) -> String:
	var parts := PackedStringArray()
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		var chunk_position: Vector2i = Vector2i(entry.get("chunk_position", Vector2i.ZERO))
		parts.append("%d,%d" % [chunk_position.x, chunk_position.y])
	return ",".join(parts)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
