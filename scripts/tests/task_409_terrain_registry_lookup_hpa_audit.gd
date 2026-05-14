extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_409 TerrainRegistry Lookup and HPA Audit Verifier ===")
	_test_tile_id_lookup_handles_reregister_and_in_place_changes()
	_test_nearest_walkable_grid_stays_deterministic_without_stale_walkability()
	_test_sorted_tile_cache_returns_stable_copies()
	_test_hpa_build_stats_capture_large_map_shape()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_tile_id_lookup_handles_reregister_and_in_place_changes() -> void:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	var alpha = _make_tile(registry, Vector2i(0, 0), "alpha")
	var beta = _make_tile(registry, Vector2i(1, 0), "beta")
	registry.register_tile(alpha)
	registry.register_tile(beta)

	_assert(registry.call("get_tile_by_id", " alpha ") == alpha, "Tile-ID lookup resolves indexed tile IDs with query whitespace")
	alpha.tile_id = "alpha_renamed"
	_assert(registry.call("get_tile_by_id", "alpha") == null, "Tile-ID lookup drops stale index entries after in-place tile ID changes")
	_assert(registry.call("get_tile_by_id", "alpha_renamed") == alpha, "Tile-ID lookup refreshes from the live registry after in-place tile ID changes")

	var gamma = _make_tile(registry, Vector2i(0, 0), "gamma")
	registry.register_tile(gamma)
	_assert(registry.call("get_tile_by_id", "alpha_renamed") == null, "Re-registering a grid removes the replaced tile ID from lookup")
	_assert(registry.call("get_tile_by_id", "gamma") == gamma, "Re-registering a grid indexes the replacement tile")
	_assert(registry.call("get_tile_by_id", "beta") == beta, "Re-registering one grid keeps unrelated tile IDs indexed")
	registry.free()


func _test_nearest_walkable_grid_stays_deterministic_without_stale_walkability() -> void:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	var blocked_center = _make_tile(registry, Vector2i(0, 0), "center", false)
	var west = _make_tile(registry, Vector2i(-1, 0), "west")
	var north = _make_tile(registry, Vector2i(0, -1), "north")
	var far = _make_tile(registry, Vector2i(2, 2), "far")
	for tile_data in [blocked_center, north, far, west]:
		registry.register_tile(tile_data)

	_assert(Vector2i(registry.call("get_nearest_walkable_grid", Vector2.ZERO)) == Vector2i(-1, 0), "Nearest walkable tie-breaks by grid coordinate without sorting caller-visible data")
	west.walkable = false
	_assert(Vector2i(registry.call("get_nearest_walkable_grid", Vector2.ZERO)) == Vector2i(0, -1), "Nearest walkable reads current walkability after in-place tile updates")
	north.walkable = false
	far.walkable = false
	_assert(registry.call("get_nearest_walkable_grid", Vector2.ZERO) == null, "Nearest walkable reports null when no current walkable tile remains")
	registry.free()


func _test_sorted_tile_cache_returns_stable_copies() -> void:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	registry.register_tile(_make_tile(registry, Vector2i(2, 0), "two_zero"))
	registry.register_tile(_make_tile(registry, Vector2i(0, 1), "zero_one"))
	registry.register_tile(_make_tile(registry, Vector2i(0, 0), "zero_zero"))

	var sorted_once: Array = registry.call("get_sorted_tiles")
	_assert(Vector2i(sorted_once[0].grid_position) == Vector2i(0, 0), "Sorted tile cache orders by grid X then Y")
	sorted_once.clear()
	var sorted_twice: Array = registry.call("get_sorted_tiles")
	_assert(sorted_twice.size() == 3 and Vector2i(sorted_twice[0].grid_position) == Vector2i(0, 0), "Sorted tile cache is not mutated by caller array changes")

	registry.register_tile(_make_tile(registry, Vector2i(1, 0), "one_zero"))
	var sorted_after_register: Array = registry.call("get_sorted_tiles")
	_assert(sorted_after_register.size() == 4 and Vector2i(sorted_after_register[2].grid_position) == Vector2i(1, 0), "Sorted tile cache invalidates after registering a new tile")
	registry.free()


func _test_hpa_build_stats_capture_large_map_shape() -> void:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(0, 64):
		for y in range(0, 64):
			registry.register_tile(_make_tile(registry, Vector2i(x, y), "%d_%d" % [x, y]))

	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	var built: bool = bool(graph.call("build_from_registry", registry, 8))
	var stats: Dictionary = Dictionary(graph.call("get_last_build_stats"))
	_assert(built and bool(stats.get("built", false)), "HPA graph builds and marks the last build as successful")
	_assert(int(stats.get("tile_count", 0)) == 4096, "HPA build stats report all 64x64 terrain tiles")
	_assert(int(stats.get("cluster_count", 0)) == 64, "HPA build stats report 64 clusters for 64x64 terrain with 8x8 clusters")
	_assert(int(stats.get("component_count", 0)) == 64, "HPA build stats report one open component per cluster on open 64x64 terrain")
	_assert(int(stats.get("portal_count", 0)) > 0, "HPA build stats report generated portals")
	_assert(int(stats.get("elapsed_usec", -1)) >= 0, "HPA build stats include non-negative elapsed time")
	registry.free()


func _make_tile(registry, grid_position: Vector2i, tile_id: String, walkable: bool = true):
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": tile_id,
		"type_id": "ground_flat" if walkable else "rock_large",
		"grid_position": grid_position,
		"world_position": registry.grid_to_world(grid_position),
		"walkable": walkable,
		"surface_type": TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND,
	})


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
