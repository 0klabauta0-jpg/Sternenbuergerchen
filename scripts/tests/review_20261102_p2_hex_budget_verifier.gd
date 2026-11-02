extends SceneTree

const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
var _passed: int = 0
var _failed: int = 0


class CountingPathfinder:
	extends "res://scripts/terrain/terrain_pathfinder.gd"
	var path_calls: int = 0
	var step_cost_calls: int = 0
	func find_path_with_options(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> Array:
		path_calls += 1
		return super.find_path_with_options(from_grid, to_grid, registry, options)
	func _get_step_cost(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> float:
		step_cost_calls += 1
		return super._get_step_cost(from_grid, to_grid, registry, options)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_hex_search_budget()
	_test_options_and_terrain_changes()
	_test_directed_local_costs()
	print("REVIEW_20261102_P2_HEX_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# Restoring a per-portal A* call exceeds this structural operation budget.
func _test_hex_search_budget() -> void:
	var registry = _make_registry(Vector2i(24, 20))
	var graph = GRAPH_SCRIPT.new()
	graph.build_from_registry(registry, 8)
	var counter = CountingPathfinder.new()
	var hpa = HPA_SCRIPT.new()
	hpa.set("_terrain_pathfinder", counter)
	var result: Dictionary = hpa.find_path_with_status(Vector2i.ZERO, Vector2i(23, 19), registry, graph)
	var path: Array = Array(result.get("path", []))
	print("HEX_OPERATION_COUNTS ", JSON.stringify({"map": "24x20", "a_star_calls": counter.path_calls, "step_cost_calls": counter.step_cost_calls, "path_size": path.size()}))
	_check(counter.path_calls <= 12, "24x20 query needs at most 12 assembly A* calls, not one per portal")
	_check(counter.step_cost_calls <= 4000, "24x20 local traversals stay within component-sized step budget")
	_check(_legal_path(path, Vector2i.ZERO, Vector2i(23, 19), registry), "24x20 HPA returns a legal endpoint-preserving hex path")
	_check(path.size() == 43, "Open 24x20 route retains 42 unit-cost steps")
	var repeated: Array = hpa.find_path(Vector2i.ZERO, Vector2i(23, 19), registry, graph)
	_check(path == repeated, "Repeated query is deterministic")
	_check(counter.path_calls <= 24, "Repeated query retains bounded A* assembly work")
	registry.free()


func _test_options_and_terrain_changes() -> void:
	var registry = _make_registry(Vector2i(17, 9))
	var graph = GRAPH_SCRIPT.new()
	graph.build_from_registry(registry, 8)
	var hpa = HPA_SCRIPT.new()
	var start: Vector2i = Vector2i(0, 4)
	var target: Vector2i = Vector2i(16, 4)
	var plain: Array = hpa.find_path(start, target, registry, graph)
	_check(_legal_path(plain, start, target, registry) and plain.size() == 17, "Plain hex route takes straight shortest corridor")
	var exposure: Dictionary = {}
	for x in range(17):
		exposure[Vector2i(x, 4)] = 1.0
	var options: Dictionary = {"cover_aware_enabled": true, "exposure_weight": 30.0, "exposure_by_grid": exposure}
	var weighted: Array = Array(hpa.find_path_with_status(start, target, registry, graph, options).get("path", []))
	var scorer = PATHFINDER_SCRIPT.new()
	_check(_legal_path(weighted, start, target, registry), "Exposure-weighted route remains legal")
	_check(float(scorer.score_path(weighted, registry, options).path_cost) < float(scorer.score_path(plain, registry, options).path_cost), "Changed options avoid expensive exposure on same graph")
	options["exposure_weight"] = 0.0
	var unweighted: Array = Array(hpa.find_path_with_status(start, target, registry, graph, options).get("path", []))
	_check(unweighted == plain, "Mutating same options dictionary cannot reuse stale exposure distances")
	var blocker: Vector2i = Vector2i(8, 4)
	registry.set_runtime_tile_overrides([{"grid_position": blocker, "walkable_override": false}])
	graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 8)
	var blocked: Array = hpa.find_path(start, target, registry, graph)
	_check(_legal_path(blocked, start, target, registry) and not blocked.has(blocker), "Revision plus dirty rebuild respects effective blocked hex")
	registry.clear_dirty_grid_positions()
	registry.clear_runtime_tile_overrides()
	graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 8)
	_check(hpa.find_path(start, target, registry, graph) == plain, "Reopening terrain restores deterministic original route")
	var changed: Array = []
	for x in range(3, 14):
		var grid: Vector2i = Vector2i(x, 4)
		registry.get_tile_at_grid(grid).surface_type = "water"
		changed.append(grid)
	registry.notify_tile_data_changed(changed)
	graph.rebuild_dirty_clusters_from_registry(registry, changed, 8)
	var surface_path: Array = hpa.find_path(start, target, registry, graph)
	_check(_legal_path(surface_path, start, target, registry), "Changed surface route remains legal")
	_check(float(scorer.score_path(surface_path, registry).path_cost) < float(scorer.score_path(plain, registry).path_cost), "Terrain cost changes do not reuse stale local distances")
	registry.free()


func _test_directed_local_costs() -> void:
	var pathfinder = PATHFINDER_SCRIPT.new()
	_check(pathfinder.has_method("build_local_cost_map"), "Shared component cost traversal exists")
	if not pathfinder.has_method("build_local_cost_map"):
		return
	var registry = _make_registry(Vector2i(3, 1))
	var grids: Array = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0)]
	var road = registry.get_tile_at_grid(Vector2i(1, 0))
	road.surface_type = "road"
	road.height_level = 1
	road.edge_type = "slope"
	road.cover_value = 100
	var sand = registry.get_tile_at_grid(Vector2i(2, 0))
	sand.surface_type = "sand"
	sand.height_level = 1
	sand.edge_type = "slope"
	var forward: Dictionary = pathfinder.call("build_local_cost_map", Vector2i.ZERO, grids, registry)
	var backward: Dictionary = pathfinder.call("build_local_cost_map", Vector2i(2, 0), grids, registry, {}, true)
	_check(is_equal_approx(float(forward.get(Vector2i(2, 0), INF)), 3.2), "Local costs include destination surface and ramp: 1.7 + 1.5")
	_check(is_equal_approx(float(backward.get(Vector2i.ZERO, INF)), 3.2), "Reverse goal map uses forward directed costs")
	var reverse_root: Dictionary = pathfinder.call("build_local_cost_map", Vector2i.ZERO, grids, registry, {}, true)
	_check(is_equal_approx(float(reverse_root.get(Vector2i(2, 0), INF)), 2.7), "Opposite travel preserves asymmetric road/sand costs: 0.7 + 2.0")
	var option_cases: Array = [
		{"cover_aware_enabled": true, "cover_weight": 2.0, "exposure_weight": 3.0, "exposure_by_grid": {Vector2i(1, 0): 1.0}},
		{"cover_aware_enabled": true, "exposure_weight": 3.0, "hazard_grids": [Vector2i.ZERO]},
		{"corridor_enabled": true, "corridor_weight": 2.0, "corridor_from_grid": Vector2i(0, 1), "corridor_to_grid": Vector2i(2, 1)},
		{"lane_enabled": true, "lane_weight": 3.0, "lane_offset_grid": 1.0, "corridor_from_grid": Vector2i.ZERO, "corridor_to_grid": Vector2i(2, 0)},
		{"blocker_clearance_weight": 4.0, "blocker_clearance_radius": 1},
	]
	for index in range(option_cases.size()):
		var options: Dictionary = option_cases[index]
		var direct: Array = pathfinder.find_path_with_options(Vector2i.ZERO, Vector2i(2, 0), registry, options)
		var expected: float = float(pathfinder.score_path(direct, registry, options).path_cost)
		var costs: Dictionary = pathfinder.call("build_local_cost_map", Vector2i.ZERO, grids, registry, options)
		var reverse_costs: Dictionary = pathfinder.call("build_local_cost_map", Vector2i(2, 0), grids, registry, options, true)
		_check(is_equal_approx(float(costs.get(Vector2i(2, 0), INF)), expected) and is_equal_approx(float(reverse_costs.get(Vector2i.ZERO, INF)), expected), "Forward/reverse local costs preserve option case %d" % index)
	var limited: Dictionary = pathfinder.call("build_local_cost_map", Vector2i.ZERO, [Vector2i.ZERO], registry)
	_check(limited.size() == 1 and not limited.has(Vector2i(1, 0)), "Local traversal never leaves supplied component")
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(1, 0), "walkable_override": false}])
	var closed: Dictionary = pathfinder.call("build_local_cost_map", Vector2i.ZERO, grids, registry)
	_check(not closed.has(Vector2i(2, 0)), "Local cost traversal respects runtime blocked door")
	var reverse_closed: Dictionary = pathfinder.call("build_local_cost_map", Vector2i(2, 0), grids, registry, {}, true)
	_check(not reverse_closed.has(Vector2i(1, 0)) and not reverse_closed.has(Vector2i.ZERO), "Reverse cost traversal excludes effectively blocked source hexes")
	registry.free()


func _make_registry(size: Vector2i):
	var registry = REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	var map_data = MAP_SCRIPT.create_empty("hex_budget", size, Vector2.ZERO, 64.0, 32.0, 3, "hex_axial_v1")
	for tile in map_data.get_tiles():
		registry.register_tile(tile)
	return registry


func _legal_path(path: Array, start: Vector2i, target: Vector2i, registry) -> bool:
	if path.is_empty() or Vector2i(path[0]) != start or Vector2i(path[-1]) != target:
		return false
	var pathfinder = PATHFINDER_SCRIPT.new()
	for index in range(path.size()):
		if not registry.is_walkable(Vector2i(path[index])):
			return false
		if index > 0 and not pathfinder.can_traverse_step(Vector2i(path[index - 1]), Vector2i(path[index]), registry):
			return false
	return true


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		print("FAIL: " + label)
