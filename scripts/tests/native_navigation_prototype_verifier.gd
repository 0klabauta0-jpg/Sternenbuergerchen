extends SceneTree
const FIX = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")
const NATIVE = preload("res://scripts/terrain/native_navigation_prototype.gd")
var passed := 0
var failed := 0
var failures: Array = []
var native_astar_queries := 0
var native_hpa_queries := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		failures.append(label)
		push_error(label)

func _same_path(expected: Array, actual: Array, registry, options: Dictionary, label: String) -> void:
	_check(expected == actual, label + " ordered path")
	var oracle = PATH.new()
	_check(oracle.score_path(expected, registry, options) == oracle.score_path(actual, registry, options), label + " exact score fields")
	var legal: bool = true
	for index in range(1, actual.size()):
		legal = legal and oracle.can_traverse_step(actual[index - 1], actual[index], registry)
	_check(legal, label + " traversable edges")

func _compare(candidate, registry, graph, from_grid: Vector2i, to_grid: Vector2i, options: Dictionary, label: String, expect_native: bool = true) -> void:
	var options_before: PackedByteArray = var_to_bytes(options)
	var expected: Array = PATH.new().find_path_with_options(from_grid, to_grid, registry, options)
	var actual: Array = candidate.find_path_with_options(from_grid, to_grid, registry, options)
	_same_path(expected, actual, registry, options, label + " A*")
	if expect_native:
		_check(candidate.get_debug_snapshot().get("last_backend", "") == "native", label + " native A* used")
		native_astar_queries += 1
	var expected_hpa: Dictionary = HPA.new().find_path_with_status(from_grid, to_grid, registry, graph, options)
	var actual_hpa: Dictionary = candidate.find_path_with_status(from_grid, to_grid, registry, graph, options)
	_check(expected_hpa.get("status") == actual_hpa.get("status"), label + " HPA status")
	_same_path(expected_hpa.get("path", []), actual_hpa.get("path", []), registry, options, label + " HPA")
	if expect_native:
		_check(candidate.get_debug_snapshot().get("last_backend", "") == "native", label + " native HPA used")
		native_hpa_queries += 1
	_check(var_to_bytes(options) == options_before, label + " caller options unchanged")

func _run() -> void:
	_check(ClassDB.class_exists("NativeNavigationKernel"), "GDExtension registered real NativeNavigationKernel")
	if failed == 0:
		_test_kernel_validation()
		_test_dynamic_kernel_validation()
		for topology in ["square8", "hex_axial_v1"]:
			_test_topology(topology)
			_test_dynamic_costs(topology)
			_test_lazy_short_query(topology)
		_test_cache_and_identity()
		_test_extreme_coordinate_fallback()
		_test_real_map()
	var evidence := {"engine": Engine.get_version_info(), "passed": passed, "failed": failed,
		"failures": failures, "native_astar_queries": native_astar_queries, "native_hpa_queries": native_hpa_queries,
		"scope": "Differential navigation-only tests; original GDScript is oracle; exact ordered paths/status/scores; no gameplay/FPS claim."}
	var output := FIX.argument("--output", "user://native_navigation_parity.json")
	if not FIX.write_json(output, evidence):
		failed += 1
	print("NATIVE_NAVIGATION_PARITY ", passed, "/", failed, " native_astar=", native_astar_queries, " native_hpa=", native_hpa_queries)
	quit(0 if failed == 0 else 1)

func _test_topology(topology: String) -> void:
	var registry = FIX.synthetic(topology)
	var graph = FIX.graph_for(registry, 4)
	var candidate = NATIVE.new()
	var option_sets: Array = FIX.option_sets()
	for index in range(option_sets.size()):
		_compare(candidate, registry, graph, Vector2i(-3, -2), Vector2i(12, 11), option_sets[index], "%s options%d forward" % [topology, index])
		_compare(candidate, registry, graph, Vector2i(12, 11), Vector2i(-3, -2), option_sets[index], "%s options%d reverse" % [topology, index])
		var prepared: bool = candidate.prepare(registry, option_sets[index], graph)
		_check(prepared, "%s options%d Dijkstra preparation" % [topology, index])
		if prepared:
			var all_grids: Array = []
			for tile in registry.get_all_tiles(): all_grids.append(tile.grid_position)
			var edge_costs_equal: bool = true
			for source in [Vector2i(-3, -2), Vector2i(4, -1), Vector2i(8, 4), Vector2i(10, 8)]:
				for direction in PATH.new().get_neighbor_directions(registry):
					var expected_cost: float = PATH.new().get_step_cost(source, source + direction, registry, option_sets[index])
					var actual_cost: float = candidate.get("_kernel").step_cost(source, source + direction)
					edge_costs_equal = edge_costs_equal and actual_cost == expected_cost
			_check(edge_costs_equal, "%s options%d exact directed edge costs" % [topology, index])
			for reverse_steps in [false, true]:
				var expected_costs: Dictionary = PATH.new().build_local_cost_map(Vector2i(-3, -2), all_grids, registry, option_sets[index], reverse_steps)
				var actual_costs: Dictionary = candidate.get("_kernel").build_local_cost_map(Vector2i(-3, -2), all_grids, reverse_steps)
				_check(actual_costs == expected_costs, "%s options%d exact Dijkstra costs reverse=%s" % [topology, index, reverse_steps])
	for pair in FIX.query_pairs(registry, 12):
		_compare(candidate, registry, graph, pair[0], pair[1], {}, topology + " varied pair " + str(pair))
	for pair in [[Vector2i(-3, -2), Vector2i(-3, -2)], [Vector2i(5, 0), Vector2i(5, 0)],
		[Vector2i(-99, 100), Vector2i(-3, -2)], [Vector2i(-3, -2), Vector2i(5, 0)]]:
		_compare(candidate, registry, graph, pair[0], pair[1], {}, topology + " endpoint edge " + str(pair))
	# Block the two openings in the wall to produce a genuinely unreachable half.
	registry.set_runtime_tile_overrides([
		{"grid_position": Vector2i(5, -1), "walkable_override": false},
		{"grid_position": Vector2i(5, 10), "walkable_override": false}])
	graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions())
	_compare(candidate, registry, graph, Vector2i(-3, -2), Vector2i(12, 11), {}, topology + " closed runtime doors")
	registry.clear_runtime_tile_overrides()
	graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions())
	_compare(candidate, registry, graph, Vector2i(-3, -2), Vector2i(12, 11), {}, topology + " reopened doors")
	# Safe unsupported fields are ignored by the oracle and must visibly fallback.
	for options in [{"unused_float": NAN}, {"unused_float": INF}]:
		var expected: Array = PATH.new().find_path_with_options(Vector2i(-3, -2), Vector2i(1, 2), registry, options)
		var actual: Array = candidate.find_path_with_options(Vector2i(-3, -2), Vector2i(1, 2), registry, options)
		_check(expected == actual, topology + " nonfinite unused option fallback exact")
		_check(candidate.get_debug_snapshot().get("last_backend", "") == "gdscript_fallback", topology + " unsupported input not counted native")
	# Diagnostics are mutable output counters, so the prototype explicitly uses
	# the original path. Compare cold requests with identical cache histories.
	for use_hpa in [false, true]:
		var gd_options := {"diagnostics": {}, "cover_aware_enabled": true, "cover_weight": 0.2}
		var native_options: Dictionary = gd_options.duplicate(true)
		var diagnostic_candidate = NATIVE.new()
		var expected: Variant = HPA.new().find_path_with_status(Vector2i(-3, -2), Vector2i(1, 2), registry, graph, gd_options) if use_hpa else PATH.new().find_path_with_options(Vector2i(-3, -2), Vector2i(1, 2), registry, gd_options)
		var actual: Variant = diagnostic_candidate.find_path_with_status(Vector2i(-3, -2), Vector2i(1, 2), registry, graph, native_options) if use_hpa else diagnostic_candidate.find_path_with_options(Vector2i(-3, -2), Vector2i(1, 2), registry, native_options)
		_check(actual == expected and native_options.diagnostics == gd_options.diagnostics, topology + " diagnostic fallback exact result and counters hpa=" + str(use_hpa))
		_check(diagnostic_candidate.get_debug_snapshot().get("fallback_reason", "") == "diagnostics_require_gdscript", topology + " mutable diagnostics use explicit fallback")
	registry.free()
	# Independent 2x2 corner-cut fixture.
	var corner = FIX.synthetic(topology, 2, 2, Vector2i.ZERO, false)
	corner.set_runtime_tile_overrides([{"grid_position": Vector2i(1, 0), "walkable_override": false}, {"grid_position": Vector2i(0, 1), "walkable_override": false}])
	_compare(NATIVE.new(), corner, FIX.graph_for(corner, 1), Vector2i.ZERO, Vector2i(1, 1), {}, topology + " corner cut")
	corner.free()

func _test_cache_and_identity() -> void:
	var registry = FIX.synthetic("square8", 12, 12, Vector2i.ZERO, false)
	var graph = FIX.graph_for(registry, 4)
	var candidate = NATIVE.new()
	var oracle = HPA.new()
	var first: Dictionary = candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), registry, graph)
	var original: Dictionary = first.duplicate(true)
	first["path"].clear()
	first["status"] = "mutated_by_consumer"
	var second: Dictionary = candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), registry, graph)
	_check(second == original, "HPA cache defensive return survives consumer mutation")
	_check(candidate.get_debug_snapshot().get("result_cache_hit", false), "HPA actual result cache hit")
	var builds_before: int = candidate.get_debug_snapshot().get("snapshot_build_count", -1)
	for index in range(70):
		var target := Vector2i(index % 12, int(index / 12))
		var expected: Dictionary = oracle.find_path_with_status(Vector2i(11, 11), target, registry, graph)
		var actual: Dictionary = candidate.find_path_with_status(Vector2i(11, 11), target, registry, graph)
		_check(actual == expected, "HPA FIFO result parity %d" % index)
	_check(candidate.get_debug_snapshot().get("result_cache_entry_count", -1) == 64, "HPA result cache bounded to64")
	candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), registry, graph)
	_check(not candidate.get_debug_snapshot().get("result_cache_hit", true), "HPA oldest result evicted FIFO")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", -2) == builds_before, "New targets reuse one unchanged native snapshot")
	var other_registry = FIX.synthetic("square8", 12, 12, Vector2i.ZERO, false)
	# Construct different input geometry with the same registration count/revision.
	# This mutation is fixture setup, before building or exposing its graph.
	other_registry.get_tile_at_grid(Vector2i(5, 5)).walkable = false
	var other_graph = FIX.graph_for(other_registry, 4)
	_check(other_registry.get_revision() == registry.get_revision() and other_graph.get_revision() == graph.get_revision(), "Identity fixture has equal numeric revisions")
	var identity_result: Dictionary = candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph)
	_check(identity_result == HPA.new().find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph), "Same-revision different registry produces its own path")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", 0) > builds_before, "Registry/graph identity change rebuilds snapshot")
	var before_graph: int = candidate.get_debug_snapshot().get("snapshot_build_count", -1)
	var graph_builds_before: int = candidate.get_debug_snapshot().get("graph_build_count", -1)
	other_graph.build_from_registry(other_registry, 3)
	var graph_result: Dictionary = candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph)
	_check(graph_result == HPA.new().find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph), "Changed graph revision exact result")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", -2) == before_graph, "Graph revision retains unchanged terrain snapshot")
	_check(candidate.get_debug_snapshot().get("graph_build_count", -1) == graph_builds_before + 1, "Graph revision invalidates graph snapshot")
	var before_registry: int = candidate.get_debug_snapshot().get("snapshot_build_count", -1)
	other_registry.set_runtime_tile_overrides([{"grid_position": Vector2i(6, 6), "walkable_override": false}])
	other_graph.rebuild_dirty_clusters_from_registry(other_registry, other_registry.get_dirty_grid_positions())
	var revision_result: Dictionary = candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph)
	_check(revision_result == HPA.new().find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph), "Changed runtime door revision exact result")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", 0) > before_registry, "Registry revision invalidation without intervening calls")
	var before_options: int = candidate.get_debug_snapshot().get("snapshot_build_count", -1)
	var option_graphs_before: int = candidate.get_debug_snapshot().get("graph_build_count", -1)
	var option_prepares_before: int = candidate.get_debug_snapshot().get("option_prepare_count", -1)
	var changed_options := {"cover_aware_enabled": true, "cover_weight": 0.2, "lane_enabled": true, "lane_weight": 0.3,
		"lane_offset_grid": 2.0, "corridor_from_grid": Vector2i.ZERO, "corridor_to_grid": Vector2i(11, 11)}
	var option_result: Dictionary = candidate.find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph, changed_options)
	_check(option_result == HPA.new().find_path_with_status(Vector2i.ZERO, Vector2i(11, 11), other_registry, other_graph, changed_options), "Changed cost options exact result")
	_check(candidate.get_debug_snapshot().get("snapshot_build_count", -2) == before_options, "Changed cost options retain terrain snapshot")
	_check(candidate.get_debug_snapshot().get("graph_build_count", -2) == option_graphs_before, "Changed cost options retain graph snapshot")
	_check(candidate.get_debug_snapshot().get("option_prepare_count", -2) == option_prepares_before + 1, "Changed cost options refresh query context")
	registry.free()
	other_registry.free()

func _test_real_map() -> void:
	var registry = FIX.real_map()
	_check(registry.get_all_tiles().size() == 9408, "Actual GM01 contains9408 cells")
	var graph = FIX.graph_for(registry)
	var candidate = NATIVE.new()
	for pair in FIX.query_pairs(registry, 8):
		_compare(candidate, registry, graph, pair[0], pair[1], {}, "GM01 " + str(pair))
	registry.free()

func _test_extreme_coordinate_fallback() -> void:
	var origin := Vector2i(1000001, -1000002)
	var registry = FIX.synthetic("square8", 2, 2, origin, false)
	var candidate = NATIVE.new()
	var expected: Array = PATH.new().find_path_with_options(origin, origin + Vector2i.ONE, registry)
	var actual: Array = candidate.find_path_with_options(origin, origin + Vector2i.ONE, registry)
	_check(actual == expected, "Extreme coordinate fallback preserves oracle path")
	_check(candidate.get_debug_snapshot().get("last_backend", "") == "gdscript_fallback", "Extreme coordinate fallback is explicit")
	_check(candidate.get_debug_snapshot().get("fallback_reason", "") == "coordinate_outside_prototype_range", "Extreme coordinate documented guard")
	registry.free()

func _test_kernel_validation() -> void:
	var kernel = ClassDB.instantiate("NativeNavigationKernel")
	var valid := {"coords": PackedInt32Array([0, 0, 1, 0]), "offsets": PackedInt32Array([0, 1, 2]),
		"neighbors": PackedInt32Array([1, 0]), "costs": PackedFloat64Array([1.0, 1.0]),
		"walkable": PackedByteArray([1, 1]), "hex": false, "heuristic_min": 0.7}
	_check(kernel.load_snapshot(valid), "Native accepts valid two-cell snapshot")
	_check(kernel.find_path(Vector2i.ZERO, Vector2i.RIGHT) == [Vector2i.ZERO, Vector2i.RIGHT], "Native two-cell direct path")
	var mutations := [
		{"coords": PackedInt32Array([0, 0, 0, 0])},
		{"offsets": PackedInt32Array([0, 3, 2])},
		{"neighbors": PackedInt32Array([9, 0])},
		{"costs": PackedFloat64Array([NAN, 1.0])},
		{"costs": PackedFloat64Array([-1.0, 1.0])},
		{"heuristic_min": INF},
	]
	for index in range(mutations.size()):
		_check(kernel.load_snapshot(valid), "Restore valid kernel before malformed %d" % index)
		var malformed: Dictionary = valid.duplicate(true)
		malformed.merge(mutations[index], true)
		_check(not kernel.load_snapshot(malformed), "Reject malformed native snapshot %d" % index)
		_check(kernel.find_path(Vector2i.ZERO, Vector2i.RIGHT).is_empty(), "Rejected snapshot cannot return stale path %d" % index)


func _test_dynamic_kernel_validation() -> void:
	var kernel = ClassDB.instantiate("NativeNavigationKernel")
	var valid := {"coords": PackedInt32Array([0, 0, 1, 0]), "offsets": PackedInt32Array([0, 1, 2]),
		"neighbors": PackedInt32Array([1, 0]), "costs": PackedFloat64Array([1.0, 1.0]),
		"walkable": PackedByteArray([1, 1]), "cover": PackedFloat64Array([0.0, 0.5]),
		"blocks_los": PackedByteArray([0, 0]), "height": PackedInt32Array([0, 0]),
		"object_height": PackedInt32Array([0, 0]), "hex": false}
	_check(kernel.load_terrain(valid), "Native accepts dynamic terrain snapshot")
	_check(not kernel.is_ready(), "Dynamic terrain waits for valid query options")
	_check(kernel.find_path(Vector2i.ZERO, Vector2i.RIGHT).is_empty(), "Unprepared dynamic terrain cannot search")
	_check(kernel.begin_query({"cover_aware_enabled": true, "cover_weight": 0.4}), "Dynamic query starts")
	_check(kernel.step_cost(Vector2i.ZERO, Vector2i.RIGHT) == 1.0 - 0.4 * 0.5, "Dynamic query evaluates exact cover cost")
	_check(kernel.begin_query({}), "Dynamic query can reset to plain costs")
	_check(kernel.step_cost(Vector2i.ZERO, Vector2i.RIGHT) == 1.0, "New query cannot reuse old edge cost")
	_check(not kernel.begin_query({"cover_weight": NAN}), "Nonfinite dynamic query rejected")
	_check(not kernel.is_ready() and kernel.find_path(Vector2i.ZERO, Vector2i.RIGHT).is_empty(), "Rejected query cannot search stale costs")
	_check(is_inf(kernel.step_cost(Vector2i.ZERO, Vector2i.RIGHT)), "Rejected query cannot expose stale edge costs")
	_check(kernel.begin_query({}), "Valid query restores prepared terrain")
	var malformed: Dictionary = valid.duplicate(true)
	malformed["cover"] = PackedFloat64Array([0.0])
	_check(not kernel.load_terrain(malformed), "Malformed dynamic attributes rejected")
	_check(kernel.find_path(Vector2i.ZERO, Vector2i.RIGHT).is_empty(), "Rejected dynamic snapshot cannot search old terrain")


func _test_dynamic_costs(topology: String) -> void:
	var registry = FIX.synthetic(topology, 10, 8, Vector2i(-4, -3), true)
	var graph = FIX.graph_for(registry, 3)
	var candidate = NATIVE.new()
	var start := Vector2i(-3, -2)
	var goal := Vector2i(4, 3)
	var option_sets: Array = [
		{"cover_aware_enabled": true, "cover_weight": 0.56, "exposure_weight": 1.3,
			"hazard_grids": [Vector2i(-4, -2), Vector2i(4, 3)], "exposure_max_grid_distance": 7.0},
		{"cover_aware_enabled": true, "cover_weight": 0.56, "exposure_weight": 2.1,
			"hazard_grids": [Vector2i(4, -2), Vector2i(-3, 3)],
			"exposure_by_grid": {Vector2i(-2, -2): 2.0, Vector2i(-1, -2): -0.5}},
		{"corridor_enabled": true, "corridor_weight": 0.8, "lane_enabled": true, "lane_weight": 0.4, "lane_offset_grid": -0.75},
		{"corridor_enabled": true, "corridor_weight": 0.8, "corridor_from_grid": start,
			"lane_enabled": true, "lane_weight": 0.4, "lane_offset_grid": 0.75},
		{"corridor_enabled": true, "corridor_weight": 0.8, "corridor_to_grid": goal,
			"lane_enabled": true, "lane_weight": 0.4, "lane_offset_grid": 0.75},
		{"corridor_enabled": true, "corridor_weight": 0.8, "corridor_from_grid": goal, "corridor_to_grid": goal,
			"lane_enabled": true, "lane_weight": 0.4, "lane_offset_grid": 0.75},
	]
	for radius in [1, 2, 3]:
		option_sets.append({"blocker_clearance_weight": 0.392, "blocker_clearance_radius": radius,
			"cover_aware_enabled": true, "cover_weight": 0.56, "exposure_weight": 0.72,
			"hazard_grids": [Vector2i(-4, 0), Vector2i(4, 3)], "exposure_max_grid_distance": 8.0,
			"corridor_enabled": true, "corridor_weight": 0.62, "corridor_half_width_grid": 1.3,
			"corridor_from_grid": start, "corridor_to_grid": goal,
			"lane_enabled": true, "lane_weight": 0.88, "lane_offset_grid": float(radius - 2) * 0.75})
	# Return to earlier inputs after other queries; no per-query cache may leak.
	option_sets.append(option_sets[0].duplicate(true))
	option_sets.append({})
	for index in range(option_sets.size()):
		candidate.clear_result_cache()
		_compare(candidate, registry, graph, start, goal, option_sets[index], topology + " successive dynamic options %d" % index)
		_check(candidate.get_debug_snapshot().get("snapshot_build_count", -1) == 1, topology + " options preserve one terrain snapshot %d" % index)
		_check(candidate.get_debug_snapshot().get("graph_build_count", -1) == 1, topology + " options preserve one graph snapshot %d" % index)
		var prepared: bool = candidate.prepare(registry, option_sets[index], graph)
		_check(prepared, topology + " direct dynamic costs prepared %d" % index)
		if prepared:
			_check_all_edge_costs(candidate, registry, option_sets[index], topology + " full directed cost grid %d" % index)
	# Override only terrain facts read by dynamic costs. The same adapter must
	# discard old cover/LOS/height/traversability inputs at the registry revision.
	var changes: Array = [
		{"grid_position": Vector2i(-2, -2), "cover_value_override": 100},
		{"grid_position": Vector2i(-2, -2), "blocks_los_override": true, "object_height_override": 3},
		{"grid_position": Vector2i(-2, -2), "blocks_los_override": true, "object_height_override": 0},
		{"grid_position": Vector2i(-2, -2), "walkable_override": false},
	]
	for index in range(changes.size()):
		var before: int = candidate.get_debug_snapshot().get("snapshot_build_count", -1)
		registry.set_runtime_tile_overrides([changes[index]])
		graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions())
		candidate.clear_result_cache()
		_compare(candidate, registry, graph, start, goal, option_sets[8], topology + " dynamic registry override %d" % index)
		_check(candidate.get_debug_snapshot().get("snapshot_build_count", -1) == before + 1, topology + " override rebuilds exactly one terrain snapshot %d" % index)
		_check_all_edge_costs(candidate, registry, option_sets[8], topology + " override exact directed costs %d" % index)
	registry.clear_runtime_tile_overrides()
	graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions())
	candidate.clear_result_cache()
	_compare(candidate, registry, graph, start, goal, option_sets[0], topology + " cleared dynamic registry overrides")
	registry.free()


func _check_all_edge_costs(candidate, registry, options: Dictionary, label: String) -> void:
	var oracle = PATH.new()
	var same: bool = true
	var first_mismatch: String = ""
	for tile in registry.get_all_tiles():
		var source: Vector2i = tile.grid_position
		for direction in oracle.get_neighbor_directions(registry):
			var target: Vector2i = source + Vector2i(direction)
			var expected: float = oracle.get_step_cost(source, target, registry, options)
			var actual: float = candidate.get("_kernel").step_cost(source, target)
			if expected != actual:
				same = false
				if first_mismatch.is_empty(): first_mismatch = " %s -> %s expected=%.17f actual=%.17f" % [source, target, expected, actual]
	_check(same, label + first_mismatch)


func _test_lazy_short_query(topology: String) -> void:
	var registry = FIX.synthetic(topology, 32, 32, Vector2i(-8, -8), false)
	var candidate = NATIVE.new()
	var options := {"cover_aware_enabled": true, "cover_weight": 0.2, "exposure_weight": 0.7,
		"hazard_grids": [Vector2i(-5, 0)], "exposure_max_grid_distance": 8.0,
		"blocker_clearance_weight": 0.3, "blocker_clearance_radius": 2}
	var expected: Array = PATH.new().find_path_with_options(Vector2i.ZERO, Vector2i.RIGHT, registry, options)
	var actual: Array = candidate.find_path_with_options(Vector2i.ZERO, Vector2i.RIGHT, registry, options)
	_same_path(expected, actual, registry, options, topology + " lazy short query")
	var debug: Dictionary = candidate.get_debug_snapshot()
	_check(debug.get("last_backend", "") == "native", topology + " lazy query uses native backend")
	var targets: int = int(debug.get("target_cost_compute_count", -1))
	var edges: int = int(debug.get("edge_cost_compute_count", -1))
	_check(targets > 0 and targets < 64, topology + " short query computes fewer than64 of1024 target costs")
	_check(edges > 0 and edges < 128, topology + " short query computes only visited directed edges")
	_check(candidate.prepare(registry, options), topology + " lazy query reset prepared")
	var kernel = candidate.get("_kernel")
	var cost: float = kernel.step_cost(Vector2i.ZERO, Vector2i.RIGHT)
	var first: Dictionary = kernel.get_query_debug()
	_check(kernel.step_cost(Vector2i.ZERO, Vector2i.RIGHT) == cost, topology + " repeated lazy edge exact")
	var second: Dictionary = kernel.get_query_debug()
	_check(first.get("edge_cost_compute_count", -1) == 1 and second.get("edge_cost_compute_count", -2) == 1, topology + " repeated edge evaluated once within query")
	_check(first.get("target_cost_compute_count", -1) == 1 and second.get("target_cost_compute_count", -2) == 1, topology + " repeated target evaluated once within query")
	registry.free()
