extends SceneTree

const NAVIGATION_BENCHMARK_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/navigation_benchmark_harness.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_410 HPA Profile Visibility and Registry Revision ===")
	_test_runtime_hpa_snapshot_tracks_cache_and_registry_revision()
	_test_navigation_benchmark_exposes_large_map_hpa_build_stats()
	_test_map_editor_has_no_hpa_full_rebuild_path()
	_test_performance_report_documents_hpa_build_stats()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_runtime_hpa_snapshot_tracks_cache_and_registry_revision() -> void:
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	var registry = _make_registry(Vector2i(8, 8))

	var first_graph = simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var first_hpa: Dictionary = _hpa_snapshot(simulation_root)
	_assert(first_graph != null, "SimulationRoot builds an HPA graph for runtime terrain")
	_assert(bool(first_hpa.get("has_graph", false)), "Navigation snapshot exposes that an HPA graph exists")
	_assert(int(first_hpa.get("build_count", 0)) == 1, "Navigation snapshot counts the first HPA build")
	_assert(int(first_hpa.get("cache_hit_count", -1)) == 0, "Navigation snapshot starts with no HPA cache hits")
	_assert(int(first_hpa.get("tile_count", 0)) == 64, "Navigation snapshot exposes HPA tile count")
	_assert(int(first_hpa.get("registry_revision", -1)) == int(registry.call("get_revision")), "Navigation snapshot exposes the registry revision used for HPA")

	var second_graph = simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var second_hpa: Dictionary = _hpa_snapshot(simulation_root)
	_assert(second_graph == first_graph, "Unchanged registry reuses the cached HPA graph")
	_assert(int(second_hpa.get("build_count", 0)) == 1, "Unchanged registry does not rebuild HPA")
	_assert(int(second_hpa.get("cache_hit_count", 0)) >= 1, "Unchanged registry increments HPA cache hit diagnostics")

	registry.register_tile(_make_tile(registry, Vector2i(0, 0), "replacement_0_0", false))
	var third_graph = simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var third_hpa: Dictionary = _hpa_snapshot(simulation_root)
	var third_build_stats: Dictionary = Dictionary(third_hpa.get("last_build_stats", {}))
	_assert(third_graph != null and third_graph == first_graph, "Same-size registry changes update the cached HPA graph via dirty-cluster rebuild")
	_assert(int(third_hpa.get("build_count", 0)) == 2, "Registry revision change triggers a second HPA build")
	_assert(int(third_hpa.get("tile_count", 0)) == 64, "Same-size HPA rebuild keeps the same tile count")
	_assert(int(third_build_stats.get("registry_revision", -1)) == int(registry.call("get_revision")), "HPA build stats record the invalidating registry revision")
	_assert(bool(third_build_stats.get("incremental", false)), "Same-size HPA rebuild uses incremental dirty-cluster stats")

	var changed_tile = registry.call("get_tile_at_grid", Vector2i(1, 1))
	changed_tile.walkable = false
	registry.call("notify_tile_data_changed")
	simulation_root.call("_ensure_hpa_navigation_graph", registry)
	var changed_hpa: Dictionary = _hpa_snapshot(simulation_root)
	_assert(int(changed_hpa.get("build_count", 0)) == 3, "Explicit in-place tile change notification invalidates HPA")

	registry.free()
	simulation_root.free()


func _test_navigation_benchmark_exposes_large_map_hpa_build_stats() -> void:
	var harness = NAVIGATION_BENCHMARK_HARNESS_SCRIPT.new()
	var result: Dictionary = Dictionary(harness.call("run_all", null))
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var open_stats: Dictionary = Dictionary(Dictionary(scenarios.get("open_64x64_queries", {})).get("hpa_graph_build_stats", {}))
	var chokepoint_stats: Dictionary = Dictionary(Dictionary(scenarios.get("chokepoint_cover_64x64_queries", {})).get("hpa_graph_build_stats", {}))
	_assert(bool(summary.get("has_hpa_build_stats", false)), "Navigation benchmark summary marks HPA build stats as present")
	_assert(int(open_stats.get("tile_count", 0)) == 4096, "Open 64x64 benchmark reports 4096 HPA build tiles")
	_assert(int(open_stats.get("cluster_count", 0)) == 64, "Open 64x64 benchmark reports 64 HPA clusters")
	_assert(int(chokepoint_stats.get("tile_count", 0)) == 4096, "Chokepoint 64x64 benchmark reports 4096 HPA build tiles")
	_assert(int(chokepoint_stats.get("cluster_count", 0)) == 64, "Chokepoint 64x64 benchmark reports 64 HPA clusters")
	_assert(int(open_stats.get("elapsed_usec", -1)) >= 0 and int(chokepoint_stats.get("elapsed_usec", -1)) >= 0, "Large-map HPA build stats include timings")


func _test_map_editor_has_no_hpa_full_rebuild_path() -> void:
	var editor_source: String = _read_text("res://scripts/editor/map_editor.gd")
	_assert(not editor_source.is_empty(), "MapEditor source is available for HPA audit")
	_assert(not editor_source.contains("HPA_NAVIGATION_GRAPH_SCRIPT") and not editor_source.contains("build_from_registry("), "MapEditor does not own an HPA full-rebuild path")


func _test_performance_report_documents_hpa_build_stats() -> void:
	var report: String = _read_text("res://docs/performance/navigation_pathfinding_los_profile_report.md")
	_assert(report.contains("HPA-Build-Diagnose"), "Navigation performance report documents HPA build diagnostics")
	_assert(report.contains("registry_revision") and report.contains("cache_hit_count"), "Navigation performance report documents runtime HPA cache diagnostics")
	_assert(report.contains("4096 Tiles") and report.contains("64 Cluster"), "Navigation performance report documents expected 64x64 HPA build shape")


func _hpa_snapshot(simulation_root) -> Dictionary:
	return Dictionary(Dictionary(simulation_root.call("get_navigation_debug_snapshot")).get("hpa_navigation", {}))


func _make_registry(size: Vector2i):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(0, size.x):
		for y in range(0, size.y):
			registry.register_tile(_make_tile(registry, Vector2i(x, y), "%d_%d" % [x, y]))
	return registry


func _make_tile(registry, grid_position: Vector2i, tile_id: String, walkable: bool = true):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": tile_id,
		"type_id": "ground_flat" if walkable else "rock_large",
		"grid_position": grid_position,
		"world_position": registry.grid_to_world(grid_position),
		"walkable": walkable,
		"surface_type": "ground" if walkable else "rock",
		"edge_type": "none",
	})


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
