extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")

# Measures the hidden O(map area) allocation before the real graph cache return.
# The registry, graph, dirty rebuild and pathfinder remain production code.
class CountedRegistry extends "res://scripts/terrain/terrain_registry.gd":
	var all_tiles_calls: int = 0
	var materialized_tiles: int = 0
	func get_all_tiles() -> Array:
		var tiles: Array = super.get_all_tiles()
		all_tiles_calls += 1
		materialized_tiles += tiles.size()
		return tiles

	func reset_counts() -> void:
		all_tiles_calls = 0
		materialized_tiles = 0


# Older lookup adapters only expose these original methods. Delegate to the
# actual registry without inheriting its new optional count API.
class LegacyRegistry extends Node:
	var source
	func _init(source_registry):
		source = source_registry
	func get_all_tiles() -> Array:
		return source.get_all_tiles()
	func get_tile_at_grid(grid_position: Vector2i):
		return source.get_tile_at_grid(grid_position)


var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	_test_cache_work_is_independent_of_map_area()
	_test_dirty_revision_rebuilds_once()
	_test_map_identity_and_empty_boundaries()
	_test_legacy_registry_without_count_api()
	print("REVIEW46_HPA_CACHE_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_cache_work_is_independent_of_map_area() -> void:
	for side in [128, 256]:
		var registry := CountedRegistry.new()
		registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
		# Dense registered data exercises the allocation. Only a short real corridor
		# is walkable, avoiding an unrelated large portal-search benchmark.
		for x in range(side):
			for y in range(side):
				_register_tile(registry, Vector2i(x, y), y == 0 and x <= 16)
		var simulation = SIMULATION.new()
		var first_graph = simulation.call("_ensure_hpa_navigation_graph", registry)
		_check(first_graph != null, "%d dense registry builds a real HPA graph" % side)
		var expected: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), registry)
		var expected_path: Array = Array(expected.get("path", []))
		_check(_is_corridor_path(expected_path, 16), "%d warm HPA returns the exact 17-cell corridor" % side)
		var before: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
		registry.reset_counts()
		var all_same_graph: bool = true
		var all_same_path: bool = true
		for _repeat in range(4):
			var cached_graph = simulation.call("_ensure_hpa_navigation_graph", registry)
			all_same_graph = all_same_graph and cached_graph == first_graph
			var query: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), registry)
			all_same_path = all_same_path and Array(query.get("path", [])) == expected_path
		var after: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
		_check(all_same_graph and int(after.get("build_count", -1)) == int(before.get("build_count", -2)), "%d repeated requests retain graph identity without rebuilding" % side)
		_check(int(after.get("cache_hit_count", 0)) - int(before.get("cache_hit_count", 0)) == 8, "%d explicit lookups and real path queries hit the existing graph eight times" % side)
		_check(all_same_path, "%d repeated real HPA queries preserve every path cell" % side)
		_check(registry.all_tiles_calls == 0 and registry.materialized_tiles == 0, "%d warm cache requests do not enumerate the map, got %d calls / %d materialized tiles" % [side, registry.all_tiles_calls, registry.materialized_tiles])
		print("HPA_CACHE_OPERATIONS ", JSON.stringify({"side": side, "tiles": side * side, "cache_requests": 8, "get_all_tiles_calls": registry.all_tiles_calls, "materialized_tiles": registry.materialized_tiles, "path_cells": expected_path.size()}))
		simulation.free()
		registry.free()


func _test_dirty_revision_rebuilds_once() -> void:
	var registry := _make_corridor()
	var simulation = SIMULATION.new()
	var initial: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), registry)
	_check(_is_corridor_path(Array(initial.get("path", [])), 16), "Initial corridor crosses the future runtime door")
	var original_graph = simulation.call("_ensure_hpa_navigation_graph", registry)
	var before: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(8, 0), "walkable_override": false}])
	var closed: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), registry)
	var closed_stats: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	_check(Array(closed.get("path", [])).is_empty(), "Same-sized runtime revision closes the actual HPA route")
	_check(int(closed_stats.get("build_count", 0)) == int(before.get("build_count", 0)) + 1, "Door closure rebuilds exactly once")
	_check(String(Dictionary(closed_stats.get("last_build_stats", {})).get("runtime_rebuild_mode", "")) == "incremental", "Door revision preserves the dirty-cluster rebuild path")
	_check(simulation.call("_ensure_hpa_navigation_graph", registry) == original_graph, "Dirty rebuild retains graph identity")
	registry.reset_counts()
	var closed_again: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), registry)
	var repeated: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	_check(Array(closed_again.get("path", [])).is_empty() and int(repeated.get("build_count", 0)) == int(closed_stats.get("build_count", -1)), "Unchanged closed route stays closed without another rebuild")
	_check(registry.all_tiles_calls == 0, "Post-revision cache hit does not enumerate unchanged tiles")
	registry.clear_runtime_tile_overrides()
	var reopened: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), registry)
	var reopen_stats: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	_check(_is_corridor_path(Array(reopened.get("path", [])), 16), "Clearing the override restores the exact current corridor")
	_check(int(reopen_stats.get("build_count", 0)) == int(closed_stats.get("build_count", 0)) + 1, "Door reopening rebuilds exactly once")
	simulation.free()
	registry.free()


func _test_map_identity_and_empty_boundaries() -> void:
	var first := _make_corridor()
	var second := _make_corridor(8)
	_check(first.get_revision() == second.get_revision(), "Map-swap fixture has equal revisions and tile counts")
	var simulation = SIMULATION.new()
	var first_graph = simulation.call("_ensure_hpa_navigation_graph", first)
	var before: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	var blocked: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), second)
	var second_graph = simulation.call("_ensure_hpa_navigation_graph", second)
	var swapped: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	_check(second_graph != null and second_graph != first_graph, "Equal-sized replacement registry gets its own graph")
	_check(Array(blocked.get("path", [])).is_empty(), "Replacement graph uses the replacement map's blocker")
	_check(int(swapped.get("build_count", 0)) == int(before.get("build_count", 0)) + 1, "Registry replacement causes exactly one full build")
	_check(String(Dictionary(swapped.get("last_build_stats", {})).get("runtime_rebuild_mode", "")) == "full", "Map identity replacement preserves full-build selection")
	second.clear_tiles()
	_check(simulation.call("_ensure_hpa_navigation_graph", second) == null, "Cleared registry releases the old graph and reports no graph")
	var empty_query: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(16, 0), second)
	_check(Array(empty_query.get("path", [])).is_empty(), "Empty map cannot reuse the previous corridor")
	_register_tile(second, Vector2i.ZERO, true)
	var singleton: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i.ZERO, second)
	_check(Array(singleton.get("path", [])) == [Vector2i.ZERO], "One-cell map recovers after empty-map invalidation")
	var outside: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(1, 0), second)
	_check(Array(outside.get("path", [])).is_empty(), "One-cell map rejects a destination outside registered bounds")
	_register_tile(second, Vector2i.ZERO, false)
	var replaced: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i.ZERO, second)
	_check(Array(replaced.get("path", [])).is_empty(), "Replacing a tile at unchanged count still invalidates its walkability")
	_check(simulation.call("_ensure_hpa_navigation_graph", null) == null, "Null registry remains a supported no-graph boundary")
	simulation.free()
	first.free()
	second.free()


func _test_legacy_registry_without_count_api() -> void:
	var backing := CountedRegistry.new()
	backing.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(3):
		_register_tile(backing, Vector2i(x, 0), true)
	var legacy := LegacyRegistry.new(backing)
	var simulation = SIMULATION.new()
	_check(not legacy.has_method("get_tile_count") and not legacy.has_method("get_revision"), "Legacy adapter genuinely lacks the optional count and revision APIs")
	var initial: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(2, 0), legacy)
	var first_graph = simulation.call("_ensure_hpa_navigation_graph", legacy)
	_check(_is_corridor_path(Array(initial.get("path", [])), 2), "Legacy adapter still builds and queries the real HPA corridor")
	backing.reset_counts()
	var repeated: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(2, 0), legacy)
	_check(Array(repeated.get("path", [])) == Array(initial.get("path", [])) and backing.all_tiles_calls == 1, "Legacy cache hit preserves its original one-call enumeration fallback")
	_check(simulation.call("_ensure_hpa_navigation_graph", legacy) == first_graph, "Legacy unchanged tile count preserves graph identity")
	var before: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	_register_tile(backing, Vector2i(0, 1), true)
	var expanded: Dictionary = simulation.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(0, 1), legacy)
	var after: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
	_check(Array(expanded.get("path", [])) == [Vector2i.ZERO, Vector2i(0, 1)], "Legacy tile-count change rebuilds a route to the added tile")
	_check(int(after.get("build_count", 0)) == int(before.get("build_count", 0)) + 1, "Legacy adapter count invalidation performs exactly one rebuild")
	simulation.free()
	legacy.free()
	backing.free()


func _make_corridor(blocked_x: int = -1) -> CountedRegistry:
	var registry := CountedRegistry.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(17):
		_register_tile(registry, Vector2i(x, 0), x != blocked_x)
	return registry


func _register_tile(registry, grid_position: Vector2i, walkable: bool) -> void:
	registry.register_tile(TILE.new({
		"tile_id": "hpa_cache_%d_%d" % [grid_position.x, grid_position.y],
		"type_id": "ground_flat",
		"grid_position": grid_position,
		"world_position": registry.grid_to_world(grid_position),
		"walkable": walkable,
		"edge_type": "none",
	}))


func _is_corridor_path(path: Array, last_x: int) -> bool:
	if path.size() != last_x + 1:
		return false
	for index in range(path.size()):
		if Vector2i(path[index]) != Vector2i(index, 0):
			return false
	return true


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
