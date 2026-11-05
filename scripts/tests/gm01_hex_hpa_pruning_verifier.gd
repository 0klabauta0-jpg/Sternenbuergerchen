extends SceneTree
## Exact old/new route comparison against the byte-pinned pre-change source.
## REVIEW8 gives the compiled old linear A* the same corrected square8 cover
## heuristic, keeping this a pruning/memo comparison rather than a bug oracle.
## The stored historical source and its SHA remain unchanged; REVIEW8's cover
## verifier separately characterizes that uninstrumented historical bug.
## No actors, simulation clocks, map files or authority settings are changed.
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")
const GRAPH = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const MOVEMENT = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const BASELINE := "res://docs/qa/mission_a5_kartenrand_20261102/before/hpa_pathfinder_before.gd.txt"
const BASELINE_SHA := "34f12f351167c2f0c2358da6b427411faa4fb52dcfab1503a84669cecbc87eda"
const TERRAIN_BASELINE := "res://docs/qa/mission_a5_kartenrand_20261102/before/terrain_pathfinder_before.gd.txt"
const TERRAIN_BASELINE_SHA := "190b34a0789734a967c28a57ee7b978973d2614849e50c5b476bc043ef701131"
const MAP_PATH := "res://maps/Ground_Mission01_32x32.json"

class CountingPathfinder:
	extends RefCounted
	var evaluations := 0
	var wrapped
	func find_path_with_options(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> Array:
		evaluations += 1
		return Array(wrapped.find_path_with_options(from_grid, to_grid, registry, options))
	func score_path(path: Array, registry, options: Dictionary = {}) -> Dictionary:
		return Dictionary(wrapped.score_path(path, registry, options))
	func get_step_cost(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> float:
		return float(wrapped.get_step_cost(from_grid, to_grid, registry, options))
	func build_local_cost_map(from_grid: Vector2i, component_grids: Array, registry, options: Dictionary = {}, reverse_steps: bool = false) -> Dictionary:
		return Dictionary(wrapped.build_local_cost_map(from_grid, component_grids, registry, options, reverse_steps))


class TieGraph:
	extends RefCounted
	var portals: Array = []
	var revision := 1
	func get_component_key_for_grid(grid: Vector2i) -> String:
		return "source" if grid == Vector2i.ZERO else "goal"
	func get_portals_snapshot() -> Array:
		return portals
	func get_revision() -> int:
		return revision

class GraphWithoutRevision:
	extends RefCounted
	var wrapped
	func get_component_key_for_grid(grid: Vector2i) -> String:
		return String(wrapped.get_component_key_for_grid(grid))
	func get_portals_snapshot() -> Array:
		return Array(wrapped.get_portals_snapshot())

class RegistryWithoutRevision:
	extends RefCounted
	var wrapped
	func get_grid_topology() -> String:
		return String(wrapped.get_grid_topology())
	func get_tile_at_grid(grid: Vector2i):
		return wrapped.get_tile_at_grid(grid)
	func is_walkable(grid: Vector2i) -> bool:
		return bool(wrapped.is_walkable(grid))
	func get_cover_at(grid: Vector2i) -> int:
		return int(wrapped.get_cover_at(grid))
	func blocks_los_at_grid(grid: Vector2i) -> bool:
		return bool(wrapped.blocks_los_at_grid(grid))
	func get_object_height_at_grid(grid: Vector2i) -> int:
		return int(wrapped.get_object_height_at_grid(grid))

var _baseline_script: GDScript
var _baseline_terrain_script: GDScript
var _baseline_runner
var _candidate_runner
var _passed := 0
var _failed := 0
var _pruned := 0
var _old_evaluations := 0
var _new_evaluations := 0
var _memo_hits := 0
var _traversability_hits := 0
var _target_cell_hits := 0


func _init() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		push_error("FAIL: " + label)


func _run() -> void:
	_check(FileAccess.get_sha256(BASELINE) == BASELINE_SHA, "Old HPA source remains byte-identical to the measured baseline")
	_baseline_script = GDScript.new()
	_baseline_script.source_code = FileAccess.get_file_as_string(BASELINE).replace("class_name HPAPathfinder\n", "").replace("class_name HPAPathfinder\r\n", "")
	var error := _baseline_script.reload()
	_check(error == OK, "Pinned old implementation compiles after removing only its global class_name")
	if error != OK:
		_finish()
		return
	_check(FileAccess.get_sha256(TERRAIN_BASELINE) == TERRAIN_BASELINE_SHA, "Old TerrainPathfinder source remains byte-identical and independently pinned")
	_baseline_terrain_script = GDScript.new()
	var terrain_source: String = FileAccess.get_file_as_string(TERRAIN_BASELINE).replace("class_name TerrainPathfinder\n", "").replace("class_name TerrainPathfinder\r\n", "")
	var old_square_estimate: String = "\treturn (straight_steps + (diagonal_steps * DIAGONAL_COST_MULTIPLIER)) * MIN_SURFACE_PATH_COST"
	_check(terrain_source.count(old_square_estimate) == 1, "Pinned old source has one square8 heuristic to align for the pruning comparison")
	if terrain_source.count(old_square_estimate) != 1:
		_finish()
		return
	var corrected_square_estimate: String = "\n".join([
		"\tvar minimum_cost: float = MIN_SURFACE_PATH_COST",
		"\tif bool(options.get(\"cover_aware_enabled\", false)):",
		"\t\tminimum_cost = maxf(MIN_COVER_AWARE_STEP_COST, MIN_SURFACE_PATH_COST - maxf(float(options.get(\"cover_weight\", 0.0)), 0.0))",
		"\treturn (straight_steps + (diagonal_steps * DIAGONAL_COST_MULTIPLIER)) * minimum_cost",
	])
	_baseline_terrain_script.source_code = terrain_source.replace(old_square_estimate, corrected_square_estimate)
	var terrain_error := _baseline_terrain_script.reload()
	_check(terrain_error == OK, "Old HPA uses a separate linear frontier with the same corrected square8 cover policy, not the new heap")
	if terrain_error != OK:
		_finish()
		return
	_baseline_runner = _baseline_script.new()
	_candidate_runner = HPA.new()
	_test_bound_safety()
	_test_real_map()
	_test_small_hex()
	_test_ties()
	_test_legacy()
	_test_memo_query_freshness()
	_test_result_cache_contract()
	_check(_pruned > 0 and _new_evaluations < _old_evaluations, "Exact comparisons include real pruning and fewer local A* evaluations")
	_check(_memo_hits > 0, "Actual local A* and scoring calls reuse directed costs within their HPA query")
	_check(_traversability_hits > 0, "Actual local A* neighbor and cost checks reuse directed traversability within their HPA query")
	_check(_target_cell_hits > 0, "Actual local A* and scoring calls reuse goal-independent target-cell components")
	_finish()


func _finish() -> void:
	print("HPA_PRUNING_TOTALS ", JSON.stringify({"checks": _passed + _failed, "failed": _failed, "pruned": _pruned, "old_astar": _old_evaluations, "new_astar": _new_evaluations, "memo_hits": _memo_hits, "traversability_hits": _traversability_hits, "target_cell_hits": _target_cell_hits}))
	if _failed == 0:
		print("GM01_HEX_HPA_PRUNING_ALL_PASS")
	quit(0 if _failed == 0 else 1)


func _compare(label: String, registry, graph, from_grid: Vector2i, to_grid: Vector2i, options: Dictionary = {}, expect_pruning: bool = false) -> Dictionary:
	var old = _baseline_runner
	var candidate = _candidate_runner
	var old_counter := CountingPathfinder.new()
	var new_counter := CountingPathfinder.new()
	old_counter.wrapped = _baseline_terrain_script.new()
	new_counter.wrapped = PATHFINDER.new()
	var options_before: Dictionary = options.duplicate(true)
	old.set("_terrain_pathfinder", old_counter)
	candidate.set("_terrain_pathfinder", new_counter)
	var revision_before: int = int(registry.get_revision())
	var started := Time.get_ticks_usec()
	var expected: Dictionary = old.find_path_with_status(from_grid, to_grid, registry, graph, options.duplicate(true))
	var old_usec := Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	var actual: Dictionary = candidate.find_path_with_status(from_grid, to_grid, registry, graph, options.duplicate(true))
	var new_usec := Time.get_ticks_usec() - started
	_check(String(actual.get("status", "")) == String(expected.get("status", "")), label + ": exact status")
	_check(Array(actual.get("path", [])) == Array(expected.get("path", [])), label + ": exact ordered path array including all tie choices")
	_check(actual.keys() == expected.keys(), label + ": result contains no private context or new gameplay fields")
	var score_options: Dictionary = options.duplicate(false)
	score_options.erase(PATHFINDER.STEP_COST_CONTEXT_OPTION)
	_check(Dictionary(old_counter.wrapped.score_path(Array(expected.get("path", [])), registry, score_options)) == Dictionary(new_counter.wrapped.score_path(Array(actual.get("path", [])), registry, score_options)), label + ": exact scoring floats against the separately pinned old TerrainPathfinder")
	_check(options == options_before, label + ": public HPA query leaves caller-owned options unchanged")
	_check(int(registry.get_revision()) == revision_before, label + ": query leaves terrain authority unchanged")
	var debug: Dictionary = candidate.get_last_query_debug_snapshot()
	_check(int(debug.get("local_astar_evaluation_count", -1)) == new_counter.evaluations, label + ": diagnostic counter equals actual local A* calls")
	_check(new_counter.evaluations <= old_counter.evaluations, label + ": no extra A* evaluation")
	if expect_pruning:
		_check(int(debug.get("lower_bound_pruned_count", 0)) > 0 and new_counter.evaluations < old_counter.evaluations, label + ": measured query actually avoids losing candidates")
	_pruned += int(debug.get("lower_bound_pruned_count", 0))
	_old_evaluations += old_counter.evaluations
	_new_evaluations += new_counter.evaluations
	_memo_hits += int(debug.get("step_cost_cache_hit_count", 0))
	_traversability_hits += int(debug.get("traversability_cache_hit_count", 0))
	_target_cell_hits += int(debug.get("target_cell_cache_hit_count", 0))
	print("HPA_PRUNING_QUERY ", JSON.stringify({"case": label, "old_usec": old_usec, "new_usec": new_usec, "old_astar": old_counter.evaluations, "new_astar": new_counter.evaluations, "debug": debug, "status": actual.get("status"), "path_size": Array(actual.get("path", [])).size()}))
	return actual


func _test_bound_safety() -> void:
	var candidate = HPA.new()
	_check(candidate._minimum_local_step_cost({}) == 0.7, "Ordinary paths use the real minimum surface cost")
	_check(candidate._minimum_local_step_cost({"cover_aware_enabled": true, "cover_weight": 9.0}) == 0.05, "Cover bonuses use the lower clamped cover-aware floor")
	_check(is_equal_approx(candidate._minimum_local_step_cost({"cover_aware_enabled": true, "cover_weight": 0.25}), 0.45), "Finite cover weight gives the tighter surface-minus-maximum-bonus floor")
	_check(candidate._minimum_local_step_cost({"cover_aware_enabled": true, "cover_weight": -9.0, "corridor_weight": -2.0, "lane_weight": -3.0, "blocker_clearance_weight": -4.0}) == 0.7, "Finite negative custom penalties remain valid under the existing clamps")
	_check(candidate._minimum_local_step_cost({"lane_weight": INF}) < 0.0, "Nonfinite custom costs keep the complete old evaluation path")
	_check(candidate._minimum_local_step_cost({"cover_aware_enabled": true, "exposure_by_grid": {Vector2i.ZERO: NAN}}) < 0.0, "Nonfinite custom exposure disables the lower bound")
	_check(not candidate._cannot_improve_from_lower_bound(0.0, 1.0, 1.7, Vector2i.ZERO, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, false, 0.7), "Equality is evaluated by the unchanged original tie rule")
	_check(not candidate._cannot_improve_from_lower_bound(0.0, 1.0, 1.7 - 0.0000000001, Vector2i.ZERO, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, false, 0.7), "Near equality stays on the original path despite summation rounding")
	_check(candidate._cannot_improve_from_lower_bound(0.0, 1.0, 1.6, Vector2i.ZERO, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, false, 0.7), "A strictly losing finite candidate is rejected before A*")


func _test_real_map() -> void:
	var hash_before := FileAccess.get_sha256(MAP_PATH)
	var map_data = MAP.load_from_file(MAP_PATH)
	_check(map_data != null and not map_data.has_load_issue() and map_data.get_tiles().size() == 9408, "Actual saved 9408-cell GM01 is the comparison fixture")
	if map_data == null or map_data.has_load_issue():
		return
	var registry := REGISTRY.new()
	var tile_size: Dictionary = map_data.get_tile_size()
	registry.configure_iso_grid(map_data.get_grid_origin(), float(tile_size.half_width), float(tile_size.half_height), map_data.get_grid_topology())
	for tile in map_data.get_tiles():
		registry.register_tile(tile)
	var graph := GRAPH.new()
	_check(graph.build_from_registry(registry, 8), "Actual GM01 builds the same full HPA graph")
	_compare("gm01 measured GO pair", registry, graph, Vector2i(0, 13), Vector2i(4, 19), {}, true)
	_compare("gm01 new western cells", registry, graph, Vector2i(0, 13), Vector2i(-8, 12), {}, true)
	_compare("gm01 weighted GO pair", registry, graph, Vector2i(0, 13), Vector2i(4, 19), {"cover_aware_enabled": true, "cover_weight": 0.25, "exposure_weight": 0.8}, true)
	_compare("gm01 production movement options", registry, graph, Vector2i(0, 13), Vector2i(4, 19), _production_move_options(registry, Vector2i(0, 13), Vector2i(4, 19)), true)
	_check(FileAccess.get_sha256(MAP_PATH) == hash_before, "Exact real-map comparisons never rewrite the saved map")
	registry.free()


func _production_move_options(registry, from_grid: Vector2i, to_grid: Vector2i) -> Dictionary:
	var from_world: Vector2 = registry.grid_to_world(from_grid)
	var to_world: Vector2 = registry.grid_to_world(to_grid)
	var movement := MOVEMENT.new()
	var command: Dictionary = movement._build_stage_navigation_context({"command_type": "move", "tactical_stance": "normal", "cover_priority": 0.4, "origin_anchor_position": from_world, "current_anchor_target_position": to_world, "final_target_position": to_world}, "fixture_member", from_world, to_world, registry)
	var simulation := SIMULATION.new()
	var options: Dictionary = simulation._build_navigation_cost_options(command, registry)
	simulation.free()
	return options


func _make_registry(hex: bool = true, surface: String = "ground"):
	var registry := REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, HEX.TOPOLOGY_ID if hex else "square8")
	for x in range(-5, 6):
		for y in range(-4, 5):
			var grid := Vector2i(x, y)
			registry.register_tile(TILE.new({"tile_id": "probe_%d_%d" % [x, y], "type_id": "ground_flat", "grid_position": grid, "world_position": registry.grid_to_world(grid), "walkable": true, "surface_type": surface, "cover_value": 100 if (x + y) % 3 == 0 else 0, "edge_type": "none"}))
	return registry


func _test_small_hex() -> void:
	var registry = _make_registry()
	var graph := GRAPH.new()
	_check(graph.build_from_registry(registry, 3), "Small negative-coordinate fixture builds")
	registry.clear_dirty_grid_positions()
	for pair in [[Vector2i(-4, -3), Vector2i(4, 3)], [Vector2i(4, 3), Vector2i(-4, -3)], [Vector2i(-2, 1), Vector2i(2, -1)], [Vector2i(-1, -1), Vector2i(-1, -1)]]:
		_compare("negative hex %s to %s" % pair, registry, graph, pair[0], pair[1])
	var weighted := {"cover_aware_enabled": true, "exposure_weight": 1.1, "cover_weight": 0.8, "hazard_grids": [Vector2i(2, 0)], "exposure_max_grid_distance": 4.0, "corridor_enabled": true, "corridor_from_grid": Vector2i(-3, -2), "corridor_to_grid": Vector2i(3, 2), "corridor_half_width_grid": 1.2, "corridor_weight": 0.4, "lane_enabled": true, "lane_weight": 0.5, "lane_offset_grid": -1.0, "blocker_clearance_weight": 0.3, "blocker_clearance_radius": 1}
	_compare("all weighted penalties and signed lane", registry, graph, Vector2i(-3, -2), Vector2i(3, 2), weighted)
	_compare("negative custom weights", registry, graph, Vector2i(-3, -2), Vector2i(3, 2), {"cover_aware_enabled": true, "exposure_weight": -3.0, "cover_weight": -4.0, "corridor_enabled": true, "corridor_weight": -2.0, "lane_enabled": true, "lane_weight": -2.0, "lane_offset_grid": -2.0, "blocker_clearance_weight": -1.0})
	_compare("cover bonus clamps below surface floor", registry, graph, Vector2i(-3, -2), Vector2i(3, 2), {"cover_aware_enabled": true, "cover_weight": 12.0})
	registry.get_tile_at_grid(Vector2i(1, 1)).height_level = 1
	registry.get_tile_at_grid(Vector2i(1, 1)).edge_type = TILE.EDGE_SLOPE
	registry.notify_tile_data_changed([Vector2i(1, 1)])
	_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 3), "Mixed-height Hex fixture updates its actual slope connectivity")
	_compare("mixed-height weighted Hex exact", registry, graph, Vector2i(-3, -2), Vector2i(3, 2), weighted)
	_compare("missing destination", registry, graph, Vector2i.ZERO, Vector2i(30, 30))
	# Same graph identity, changed revision and dirty-cluster portals: both
	# pathfinders must consume the rebuilt graph rather than a cached old route.
	for y in range(-4, 5):
		registry.get_tile_at_grid(Vector2i(0, y)).walkable = false
	registry.notify_tile_data_changed([Vector2i(0, -4), Vector2i(0, -3), Vector2i(0, -2), Vector2i(0, -1), Vector2i.ZERO, Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)])
	_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 3), "Blocked barrier rebuilds dirty clusters on the same graph")
	_compare("blocked disconnected graph", registry, graph, Vector2i(-3, -2), Vector2i(3, 2))
	_compare("blocked source", registry, graph, Vector2i.ZERO, Vector2i(3, 2))
	registry.free()
	var roads = _make_registry(true, "road")
	var road_graph := GRAPH.new()
	_check(road_graph.build_from_registry(roads, 3), "Minimum-surface-cost fixture builds")
	_compare("road summation and equal routes", roads, road_graph, Vector2i(-4, -3), Vector2i(4, 3))
	roads.free()


func _test_ties() -> void:
	var registry = _make_registry()
	var graph := TieGraph.new()
	var farther := {"portal_id": "a", "from_component": "source", "to_component": "goal", "from_grid": Vector2i.ZERO, "to_grid": Vector2i(1, 0)}
	var nearer := {"portal_id": "b", "from_component": "source", "to_component": "goal", "from_grid": Vector2i(0, 1), "to_grid": Vector2i(1, 1)}
	graph.portals = [farther, nearer]
	var result := _compare("equal-cost closer-entry tie improves", registry, graph, Vector2i.ZERO, Vector2i(2, 1))
	_check(Array(result.get("path", [])).has(Vector2i(0, 1)), "Tie fixture actually selects the later, closer entry")
	farther["portal_id"] = "b"
	nearer["portal_id"] = "a"
	graph.portals = [farther, nearer]
	graph.revision += 1
	_compare("equal-cost farther-entry tie rejected", registry, graph, Vector2i.ZERO, Vector2i(2, 1))
	registry.free()


func _test_legacy() -> void:
	var registry = _make_registry(false)
	var graph := GRAPH.new()
	_check(graph.build_from_registry(registry, 3), "Legacy square fixture builds")
	_compare("legacy square unchanged", registry, graph, Vector2i(-4, -3), Vector2i(4, 3))
	_compare("legacy weighted exact with corrected cover heuristic", registry, graph, Vector2i(-4, -3), Vector2i(4, 3), {"cover_aware_enabled": true, "cover_weight": 0.8, "exposure_weight": 0.2})
	registry.get_tile_at_grid(Vector2i(1, 1)).height_level = 1
	registry.get_tile_at_grid(Vector2i(1, 1)).edge_type = TILE.EDGE_SLOPE
	registry.notify_tile_data_changed([Vector2i(1, 1)])
	_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 3), "Legacy mixed-height fixture updates slope connectivity")
	_compare("legacy diagonal mixed-height weighted exact", registry, graph, Vector2i(-4, -3), Vector2i(4, 3), {"cover_aware_enabled": true, "cover_weight": 0.8, "exposure_weight": 0.2, "lane_enabled": true, "lane_weight": 0.3, "blocker_clearance_weight": 0.2})
	registry.free()


func _test_memo_query_freshness() -> void:
	var registry = _make_registry()
	var graph := GRAPH.new()
	_check(graph.build_from_registry(registry, 3), "Memo freshness fixture builds its own small graph")
	registry.clear_dirty_grid_positions()
	var from_grid := Vector2i(-3, -2)
	var to_grid := Vector2i(3, 2)
	var options := {"cover_aware_enabled": true, "cover_weight": 0.3, "exposure_weight": 0.4}
	_compare("fresh cost query first", registry, graph, from_grid, to_grid, options)
	var first: Dictionary = _candidate_runner.get_last_query_debug_snapshot()
	_compare("fresh cost query repeated", registry, graph, from_grid, to_grid, options)
	var second: Dictionary = _candidate_runner.get_last_query_debug_snapshot()
	_check(not bool(first.get("result_cache_hit", true)) and int(first.get("step_cost_compute_count", 0)) > 0 and _is_zero_work_hit(second), "Identical repeated public query returns its exact successful result with zero new query work")
	var supplied_context = PATHFINDER.StepCostContext.new(registry)
	var supplied_options: Dictionary = options.duplicate(false)
	supplied_options[PATHFINDER.STEP_COST_CONTEXT_OPTION] = supplied_context
	_compare("caller-supplied old context replaced", registry, graph, from_grid, to_grid, supplied_options)
	_check(supplied_context.compute_count == 0 and supplied_context.hit_count == 0 and _is_zero_work_hit(_candidate_runner.get_last_query_debug_snapshot()), "Supplied private context is excluded from the result key and stays untouched on a hit")
	_check(supplied_context.traversability_compute_count == 0 and supplied_context.traversability_hit_count == 0, "Caller-supplied traversal cache is never borrowed or mutated")
	options["cover_weight"] = 8.0
	_compare("new query changed cover options", registry, graph, from_grid, to_grid, options)
	_check(not bool(_candidate_runner.get_last_query_debug_snapshot().get("result_cache_hit", true)) and int(_candidate_runner.get_last_query_debug_snapshot().get("step_cost_compute_count", 0)) > 0, "Changed cost options require a fresh complete query and memo context")
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(1, 1), "cover_value_override": 100}, {"grid_position": Vector2i(2, 1), "cover_value_override": 0}])
	_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 3), "Changed runtime overrides update the same fixture graph")
	_compare("new query after runtime override revision", registry, graph, from_grid, to_grid, options)
	registry.clear_runtime_tile_overrides()
	registry.get_tile_at_grid(Vector2i(1, 1)).surface_type = "water"
	registry.notify_tile_data_changed([Vector2i(1, 1)])
	_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 3), "Changed source surface updates the same fixture graph")
	_compare("new query after source terrain revision", registry, graph, from_grid, to_grid, options)
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i.ZERO, "walkable_override": false}])
	_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 3), "Changed runtime traversability updates the same fixture graph")
	_compare("new query after runtime blocker revision", registry, graph, from_grid, to_grid, options)
	registry.free()


func _is_zero_work_hit(snapshot: Dictionary) -> bool:
	if not bool(snapshot.get("result_cache_hit", false)):
		return false
	for key in ["local_astar_evaluation_count", "portal_candidate_count", "step_cost_compute_count", "step_cost_cache_hit_count", "traversability_compute_count", "traversability_cache_hit_count", "target_cell_compute_count", "target_cell_cache_hit_count"]:
		if int(snapshot.get(key, -1)) != 0:
			return false
	return true


func _test_result_cache_contract() -> void:
	var registry = _make_registry()
	var graph := GRAPH.new()
	_check(graph.build_from_registry(registry, 3), "Result-cache fixture uses a normal real registry and HPA graph")
	registry.clear_dirty_grid_positions()
	var runner := HPA.new()
	var old = _baseline_script.new()
	old.set("_terrain_pathfinder", _baseline_terrain_script.new())
	var from_grid := Vector2i(-1, 0)
	var to_grid := Vector2i.ZERO
	var expected: Dictionary = old.find_path_with_status(from_grid, to_grid, registry, graph, {})
	var miss: Dictionary = runner.find_path_with_status(from_grid, to_grid, registry, graph, {})
	_check(miss == expected and not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "First result-cache miss exactly matches the independently pinned old route")
	miss["status"] = "caller_tampered"
	var miss_path: Array = miss["path"]
	miss_path[0] = Vector2i(900, 900)
	var hit: Dictionary = runner.find_path_with_status(from_grid, to_grid, registry, graph, {})
	_check(hit == expected and _is_zero_work_hit(runner.get_last_query_debug_snapshot()), "Mutating a miss result cannot mutate the stored deep copy")
	var hit_path: Array = hit["path"]
	hit_path.clear()
	hit["extra"] = {"mutable": []}
	_check(runner.find_path_with_status(from_grid, to_grid, registry, graph, {}) == expected and _is_zero_work_hit(runner.get_last_query_debug_snapshot()), "Mutating a hit path/dictionary cannot alias the next returned result")
	# Entire option payload, field types and Array order form the byte key.
	for options in [{"opaque_probe": 1}, {"opaque_probe": 1.0}, {"opaque_probe": [1, 2]}, {"opaque_probe": [2, 1]}, {"opaque_probe": {Vector2i(-1, 0): 0.00000000001}}]:
		var before: Dictionary = options.duplicate(true)
		var actual: Dictionary = runner.find_path_with_status(from_grid, to_grid, registry, graph, options)
		_check(actual == expected and options == before and not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Exact key retains every ignored field, type, fine float and Array-order difference: %s" % options)
		runner.find_path_with_status(from_grid, to_grid, registry, graph, options)
		_check(_is_zero_work_hit(runner.get_last_query_debug_snapshot()), "Identical exact option bytes produce a zero-work hit")
	var diagnostic_options := {"diagnostics": {"different_derived_counter": 42}}
	_check(runner.find_path_with_status(from_grid, to_grid, registry, graph, diagnostic_options) == expected and _is_zero_work_hit(runner.get_last_query_debug_snapshot()), "Only diagnostics is ignored without changing the cost/result")
	_test_exact_cache_keys(registry, graph, from_grid, to_grid)
	var uncacheable: Array = [{"unused_object": RefCounted.new()}, {"unused_callable": Callable(self, "_run")}, {"unused_float": NAN}, {"unused_float": INF}, {"unused_vector": Vector2(INF, 0)}, {"unused_packed": PackedStringArray(["unknown"])}]
	var cyclic: Array = []
	cyclic.append(cyclic)
	uncacheable.append({"unused_cycle": cyclic})
	for options in uncacheable:
		var entries_before: int = int(runner.get_last_query_debug_snapshot().get("result_cache_entry_count", -1))
		var first: Dictionary = runner.find_path_with_status(from_grid, to_grid, registry, graph, options)
		var second: Dictionary = runner.find_path_with_status(from_grid, to_grid, registry, graph, options)
		var debug: Dictionary = runner.get_last_query_debug_snapshot()
		_check(first == expected and second == expected and not bool(debug.get("result_cache_hit", true)) and not bool(debug.get("result_cache_eligible", true)) and int(debug.get("result_cache_entry_count", -2)) == entries_before, "Unknown/object/callable/nonfinite/cyclic options safely bypass result caching")
	cyclic.clear()
	var entries_before_failure: int = int(runner.get_last_query_debug_snapshot().get("result_cache_entry_count", -1))
	for repeat in range(2):
		var failure: Dictionary = runner.find_path_with_status(Vector2i(99, 99), to_grid, registry, graph, {})
		_check(String(failure.get("status", "")) == "no_component" and Array(failure.get("path", [])).is_empty() and not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)) and int(runner.get_last_query_debug_snapshot().get("result_cache_entry_count", -2)) == entries_before_failure, "Unsuccessful/empty result is never stored or reused")
	# Each identity/revision is independently significant, even unchanged truth.
	registry.notify_tile_data_changed([from_grid])
	runner.find_path_with_status(from_grid, to_grid, registry, graph, {})
	_check(not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Registry revision alone invalidates successful stored results")
	_check(graph.build_from_registry(registry, 3), "Same graph can rebuild at unchanged registry revision")
	runner.find_path_with_status(from_grid, to_grid, registry, graph, {})
	_check(not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Graph revision alone invalidates successful stored results")
	var other_graph := GRAPH.new()
	_check(other_graph.build_from_registry(registry, 3), "Equivalent second graph builds")
	while other_graph.get_revision() < graph.get_revision():
		other_graph.build_from_registry(registry, 3)
	_check(other_graph.get_revision() == graph.get_revision(), "Different graph fixture deliberately has the same revision number")
	runner.find_path_with_status(from_grid, to_grid, registry, other_graph, {})
	_check(not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Different graph identity cannot borrow an old result")
	var other_registry = _make_registry()
	var other_expected: Dictionary = old.find_path_with_status(from_grid, to_grid, other_registry, other_graph, {})
	_check(runner.find_path_with_status(from_grid, to_grid, other_registry, other_graph, {}) == other_expected and not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Different registry identity cannot borrow results despite equivalent cells")
	_check(runner.find_path_with_status(from_grid, to_grid, registry, graph, {}) == expected and not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Returning to the earlier registry and key starts a fresh valid scope")
	runner.find_path_with_status(from_grid, to_grid, registry, graph, {})
	_check(_is_zero_work_hit(runner.get_last_query_debug_snapshot()), "Returned registry scope can then reuse its newly computed exact result")
	var no_revision_graph := GraphWithoutRevision.new()
	no_revision_graph.wrapped = other_graph
	runner.find_path_with_status(from_grid, to_grid, other_registry, no_revision_graph, {})
	runner.find_path_with_status(from_grid, to_grid, other_registry, no_revision_graph, {})
	_check(not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)) and not bool(runner.get_last_query_debug_snapshot().get("result_cache_eligible", true)), "Graphs without integer revision support use the uncached original route")
	var no_revision_registry := RegistryWithoutRevision.new()
	no_revision_registry.wrapped = other_registry
	runner.find_path_with_status(from_grid, to_grid, no_revision_registry, other_graph, {})
	runner.find_path_with_status(from_grid, to_grid, no_revision_registry, other_graph, {})
	_check(not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)) and not bool(runner.get_last_query_debug_snapshot().get("result_cache_eligible", true)), "Registries without revision support use the uncached original route")
	# New runner isolates FIFO order. Hits deliberately do not promote entries.
	var fifo := HPA.new()
	var fifo_exact := true
	for index in range(64):
		fifo_exact = fifo.find_path_with_status(from_grid, to_grid, registry, graph, {"fifo_probe": index}) == expected and fifo_exact
	_check(fifo_exact and int(fifo.get_last_query_debug_snapshot().get("result_cache_entry_count", -1)) == 64, "Exactly 64 independent successful option payloads fit the bounded FIFO")
	fifo.find_path_with_status(from_grid, to_grid, registry, graph, {"fifo_probe": 64})
	_check(int(fifo.get_last_query_debug_snapshot().get("result_cache_entry_count", -1)) == 64, "The 65th result never expands the cache past 64")
	fifo.find_path_with_status(from_grid, to_grid, registry, graph, {"fifo_probe": 1})
	_check(_is_zero_work_hit(fifo.get_last_query_debug_snapshot()), "FIFO retains the second-oldest entry after evicting entry zero")
	fifo.find_path_with_status(from_grid, to_grid, registry, graph, {"fifo_probe": 0})
	_check(not bool(fifo.get_last_query_debug_snapshot().get("result_cache_hit", true)), "The oldest successful entry is actually evicted")
	fifo.find_path_with_status(from_grid, to_grid, registry, graph, {"fifo_probe": 1})
	_check(not bool(fifo.get_last_query_debug_snapshot().get("result_cache_hit", true)), "A prior cache hit does not alter FIFO insertion order")
	other_registry.free()
	registry.free()


func _test_exact_cache_keys(registry, graph, from_grid: Vector2i, to_grid: Vector2i) -> void:
	var old = _baseline_script.new()
	var old_terrain = _baseline_terrain_script.new()
	old.set("_terrain_pathfinder", old_terrain)
	var current_terrain := PATHFINDER.new()
	var pairs: Array = [
		[{"cover_aware_enabled": true, "cover_weight": 0.25}, {"cover_aware_enabled": true, "cover_weight": 0.2500000000000001}],
		[{"cover_aware_enabled": true, "exposure_weight": 0.4, "exposure_by_grid": {Vector2i.ZERO: 0.25, Vector2i(-1, 0): 0.75}}, {"cover_aware_enabled": true, "exposure_weight": 0.4, "exposure_by_grid": {Vector2i.ZERO: 0.2500000000000001, Vector2i(-1, 0): 0.75}}],
		[{"cover_aware_enabled": true, "exposure_weight": 0.4, "hazard_grids": [Vector2i(2, 0), Vector2i(1, 2)]}, {"cover_aware_enabled": true, "exposure_weight": 0.4, "hazard_grids": [Vector2i(1, 2), Vector2i(2, 0)]}],
		[{"nested_probe": {"exposure_by_grid": {Vector2i.ZERO: 0.25}, "deeper": {"ordered": [{Vector2i(-1, 0): 0.125}, {Vector2i(2, 1): 0.75}]}}}, {"nested_probe": {"exposure_by_grid": {Vector2i.ZERO: 0.25}, "deeper": {"ordered": [{Vector2i(-1, 0): 0.1250000000000001}, {Vector2i(2, 1): 0.75}]}}}],
	]
	for pair_index in range(pairs.size()):
		var runner := HPA.new()
		var pair: Array = pairs[pair_index]
		var first_key: String = runner._result_cache_key(from_grid, to_grid, pair[0])
		var second_key: String = runner._result_cache_key(from_grid, to_grid, pair[1])
		_check(not first_key.is_empty() and not second_key.is_empty() and first_key != second_key, "Lossless Variant key distinguishes near-float/nested-exposure/hazard-order pair %d" % pair_index)
		for options in pair:
			var expected: Dictionary = old.find_path_with_status(from_grid, to_grid, registry, graph, options)
			var actual: Dictionary = runner.find_path_with_status(from_grid, to_grid, registry, graph, options)
			_check(actual == expected and not bool(runner.get_last_query_debug_snapshot().get("result_cache_hit", true)), "Exact-byte pair %d produces no false API cache hit and retains the old route" % pair_index)
			_check(old_terrain.score_path(Array(expected.get("path", [])), registry, options) == current_terrain.score_path(Array(actual.get("path", [])), registry, options), "Exact-byte pair %d retains every scoring float" % pair_index)
			runner.find_path_with_status(from_grid, to_grid, registry, graph, options)
			_check(_is_zero_work_hit(runner.get_last_query_debug_snapshot()), "Exact-byte pair %d repeats as a valid zero-work hit" % pair_index)
