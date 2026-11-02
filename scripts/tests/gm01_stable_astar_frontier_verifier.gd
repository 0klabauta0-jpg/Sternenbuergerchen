extends SceneTree
## Exact old/new A* routes plus an independent replay of the old open-list
## selection. Only local data fixtures; no actors, clocks or saves are patched.
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MOVEMENT = preload("res://scripts/tactical/fireteam_movement_controller.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const BASELINE := "res://docs/qa/mission_a5_kartenrand_20261102/before/terrain_pathfinder_before.gd.txt"
const BASELINE_SHA := "190b34a0789734a967c28a57ee7b978973d2614849e50c5b476bc043ef701131"
const MAP_PATH := "res://maps/Ground_Mission01_32x32.json"

class RegistryWithoutRevision:
	extends RefCounted
	func get_tile_at_grid(_grid: Vector2i):
		return null

var _baseline_script: GDScript
var _old
var _candidate
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		push_error("FAIL: " + label)


func _run() -> void:
	_check(FileAccess.get_sha256(BASELINE) == BASELINE_SHA, "Linear-frontier TerrainPathfinder baseline is byte-pinned")
	_baseline_script = GDScript.new()
	_baseline_script.source_code = FileAccess.get_file_as_string(BASELINE).replace("class_name TerrainPathfinder\n", "").replace("class_name TerrainPathfinder\r\n", "")
	var error := _baseline_script.reload()
	_check(error == OK, "Old A* compiles after removing only its global class_name")
	if error == OK:
		_old = _baseline_script.new()
		_candidate = PATHFINDER.new()
		_test_frontier_order()
		_test_real_map()
		_test_local_routes()
		_test_nonfinite_routes()
		_test_step_cost_context()
		_test_traversability_context()
		_test_target_component_context()
	print("Stable A* frontier: %d passed, %d failed" % [_passed, _failed])
	if _failed == 0:
		print("GM01_STABLE_ASTAR_FRONTIER_ALL_PASS")
	quit(0 if _failed == 0 else 1)


func _offer_both(queue, order: Array, scores: Dictionary, grid: Vector2i, score: float) -> void:
	if not order.has(grid):
		order.append(grid)
	scores[grid] = score
	queue.offer(grid, score)


func _pop_matches(queue, order: Array, scores: Dictionary) -> bool:
	var expected: Vector2i = _old._pop_lowest_f_score(order, scores)
	var actual: Vector2i = queue.pop_lowest()
	return actual == expected


func _test_frontier_order() -> void:
	var queue = PATHFINDER.StablePathFrontier.new()
	var order: Array = []
	var scores: Dictionary = {}
	_offer_both(queue, order, scores, Vector2i(0, 0), 5.0)
	_offer_both(queue, order, scores, Vector2i(1, 0), 3.0)
	_offer_both(queue, order, scores, Vector2i(2, 0), 3.0)
	_offer_both(queue, order, scores, Vector2i(3, 0), 8.0)
	_offer_both(queue, order, scores, Vector2i(0, 0), 3.0)
	_check(_pop_matches(queue, order, scores), "Decrease-key retains original ordinal ahead of equally ranked later entries")
	_offer_both(queue, order, scores, Vector2i(0, 0), 3.0)
	_check(_pop_matches(queue, order, scores), "Popped and reopened node receives a new ordinal behind existing equal entries")
	_offer_both(queue, order, scores, Vector2i(2, 0), 2.0)
	var exact := _pop_matches(queue, order, scores)
	_offer_both(queue, order, scores, Vector2i(3, 0), 3.0)
	while not order.is_empty():
		exact = _pop_matches(queue, order, scores) and exact
	_check(exact and queue.is_empty(), "Further decreases and complete draining match the original insertion scan")
	for index in range(256):
		_offer_both(queue, order, scores, Vector2i(index, 1), float((index * 31) % 17) * 0.1)
	for index in range(640):
		var grid := Vector2i((index * 43) % 256, 1)
		_offer_both(queue, order, scores, grid, float((index * 19) % 23) * 0.1)
		if index % 2 == 0:
			exact = _pop_matches(queue, order, scores) and exact
	while not order.is_empty():
		exact = _pop_matches(queue, order, scores) and exact
	_check(exact and queue.is_empty(), "Large deterministic replay preserves every pop under equal scores, key changes and repeated reopenings")
	for entry in [[Vector2i(0, 2), 0.0], [Vector2i(1, 2), -0.0], [Vector2i(2, 2), INF], [Vector2i(3, 2), -INF]]:
		_offer_both(queue, order, scores, entry[0], entry[1])
	while not order.is_empty():
		exact = _pop_matches(queue, order, scores) and exact
	_check(exact, "Signed zero and both infinities preserve old tie ordering")
	# Force a heap layout unlike insertion order, then update an existing entry
	# to NaN before its next pop. The old comparison has no total-order shortcut.
	for index in range(13):
		_offer_both(queue, order, scores, Vector2i(index, 3), float(20 - index))
	_offer_both(queue, order, scores, Vector2i(5, 3), NAN)
	_check(queue.is_linear_mode(), "NaN switches before selection and reconstructs the current old insertion list")
	_offer_both(queue, order, scores, Vector2i(13, 3), NAN)
	while not order.is_empty():
		exact = _pop_matches(queue, order, scores) and exact
	_check(exact and queue.is_empty(), "Every NaN fallback pop matches the original >= scan exactly")


func _compare(label: String, registry, from_grid: Vector2i, to_grid: Vector2i, options: Dictionary = {}) -> void:
	var revision: int = int(registry.get_revision()) if registry != null else -1
	var started := Time.get_ticks_usec()
	var old_path: Array = _old.find_path_with_options(from_grid, to_grid, registry, options.duplicate(true))
	var old_usec := Time.get_ticks_usec() - started
	started = Time.get_ticks_usec()
	var new_path: Array = _candidate.find_path_with_options(from_grid, to_grid, registry, options.duplicate(true))
	var new_usec := Time.get_ticks_usec() - started
	_check(new_path == old_path, label + ": exact ordered path array")
	_check(_same_score(Dictionary(_old.score_path(old_path, registry, options)), Dictionary(_candidate.score_path(new_path, registry, options))), label + ": exact scoring floats")
	if registry != null:
		_check(int(registry.get_revision()) == revision, label + ": no terrain-authority mutation")
	print("STABLE_ASTAR_QUERY ", JSON.stringify({"case": label, "old_usec": old_usec, "new_usec": new_usec, "path_size": new_path.size(), "exact": new_path == old_path}))


func _test_real_map() -> void:
	var hash_before := FileAccess.get_sha256(MAP_PATH)
	var data = MAP.load_from_file(MAP_PATH)
	_check(data != null and not data.has_load_issue() and data.get_tiles().size() == 9408, "Real saved GM01 remains the 9408-cell comparison source")
	if data == null or data.has_load_issue():
		return
	var registry := REGISTRY.new()
	var size: Dictionary = data.get_tile_size()
	registry.configure_iso_grid(data.get_grid_origin(), float(size.half_width), float(size.half_height), data.get_grid_topology())
	for tile in data.get_tiles():
		registry.register_tile(tile)
	var from_grid := Vector2i(0, 13)
	var to_grid := Vector2i(4, 19)
	_compare("GM01 exact measured endpoints", registry, from_grid, to_grid)
	_compare("GM01 actual western cells", registry, from_grid, Vector2i(-8, 12))
	# Build the same cost options through the existing movement and simulation
	# helpers, with explicit normal-MOVE fixture inputs; no command is enqueued.
	var from_world: Vector2 = registry.grid_to_world(from_grid)
	var to_world: Vector2 = registry.grid_to_world(to_grid)
	var movement := MOVEMENT.new()
	var command: Dictionary = movement._build_stage_navigation_context({"command_type": "move", "tactical_stance": "normal", "cover_priority": 0.4, "origin_anchor_position": from_world, "current_anchor_target_position": to_world, "final_target_position": to_world}, "fixture_member", from_world, to_world, registry)
	var simulation := SIMULATION.new()
	var options: Dictionary = simulation._build_navigation_cost_options(command, registry)
	simulation.free()
	_check(bool(options.get("cover_aware_enabled", false)) and bool(options.get("corridor_enabled", false)) and bool(options.get("lane_enabled", false)) and float(options.get("blocker_clearance_weight", 0.0)) > 0.0, "Production option builders include cover, corridor, lane and blocker-clearance costs together")
	_compare("GM01 production normal MOVE options", registry, from_grid, to_grid, options)
	_check(FileAccess.get_sha256(MAP_PATH) == hash_before, "A* comparisons never write the saved map")
	registry.free()


func _same_score(expected: Dictionary, actual: Dictionary) -> bool:
	if expected.keys() != actual.keys():
		return false
	for key in expected:
		if typeof(expected[key]) == TYPE_FLOAT and is_nan(float(expected[key])):
			if typeof(actual[key]) != TYPE_FLOAT or not is_nan(float(actual[key])):
				return false
		elif actual[key] != expected[key]:
			return false
	return true


func _test_step_cost_context() -> void:
	var registry = _make_registry(true)
	var from_grid := Vector2i(-1, 0)
	var to_grid := Vector2i.ZERO
	registry.get_tile_at_grid(from_grid).surface_type = "road"
	registry.get_tile_at_grid(to_grid).surface_type = "water"
	registry.get_tile_at_grid(to_grid).cover_value = 0
	registry.notify_tile_data_changed([from_grid, to_grid])
	var options := {"cover_aware_enabled": true, "cover_weight": 0.5, "corridor_enabled": true, "corridor_weight": 0.2, "corridor_from_grid": from_grid, "corridor_to_grid": Vector2i(2, 1), "lane_enabled": true, "lane_weight": 0.3, "lane_offset_grid": -0.4, "blocker_clearance_weight": 0.2}
	var scoped: Dictionary = options.duplicate(false)
	var context = PATHFINDER.StepCostContext.new(registry)
	scoped[PATHFINDER.STEP_COST_CONTEXT_OPTION] = context
	var expected_forward: float = _old.get_step_cost(from_grid, to_grid, registry, options)
	var expected_reverse: float = _old.get_step_cost(to_grid, from_grid, registry, options)
	var actual_forward: float = _candidate.get_step_cost(from_grid, to_grid, registry, scoped)
	var actual_reverse: float = _candidate.get_step_cost(to_grid, from_grid, registry, scoped)
	_check(actual_forward == expected_forward and actual_reverse == expected_reverse and actual_forward != actual_reverse and context.compute_count == 2, "Directed memo retains different target-surface costs in both directions")
	var path: Array = [from_grid, to_grid, from_grid, to_grid]
	var expected_score: Dictionary = _old.score_path(path, registry, options)
	var actual_score: Dictionary = _candidate.score_path(path, registry, scoped)
	_check(_same_score(expected_score, actual_score) and context.compute_count == 2 and context.hit_count == 3, "Memoized repeated-edge scoring preserves every float while avoiding actual recomputation")
	registry.set_runtime_tile_overrides([{"grid_position": to_grid, "cover_value_override": 100}])
	var changed_expected: float = _old.get_step_cost(from_grid, to_grid, registry, options)
	var changed_actual: float = _candidate.get_step_cost(from_grid, to_grid, registry, scoped)
	_check(changed_actual == changed_expected and changed_actual != expected_forward and context.invalidation_count == 1 and context.compute_count == 3, "Registry revision invalidates existing context before reusing a changed runtime-override cost")
	var other = _make_registry(true)
	var other_expected: float = _old.get_step_cost(from_grid, to_grid, other, options)
	_check(_candidate.get_step_cost(from_grid, to_grid, other, scoped) == other_expected, "A context for another registry falls back to the original computation")
	other.free()
	var unsupported := RegistryWithoutRevision.new()
	var unsupported_context = PATHFINDER.StepCostContext.new(unsupported)
	var unsupported_options: Dictionary = options.duplicate(false)
	unsupported_options[PATHFINDER.STEP_COST_CONTEXT_OPTION] = unsupported_context
	_check(not unsupported_context.prepare_for(unsupported) and is_inf(_candidate.get_step_cost(from_grid, to_grid, unsupported, unsupported_options)), "Registries without revision support bypass memoization")
	var untyped: Dictionary = options.duplicate(false)
	untyped[PATHFINDER.STEP_COST_CONTEXT_OPTION] = {"spoofed": true}
	_check(_candidate.get_step_cost(from_grid, to_grid, registry, untyped) == changed_expected, "An untyped caller value cannot activate the private cost context")
	_check(not options.has(PATHFINDER.STEP_COST_CONTEXT_OPTION), "Cost-context test leaves caller-owned cost options untouched")
	registry.free()


func _make_registry(hex: bool):
	var registry := REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, HEX.TOPOLOGY_ID if hex else "square8")
	for x in range(-5, 6):
		for y in range(-4, 5):
			var grid := Vector2i(x, y)
			registry.register_tile(TILE.new({"tile_id": "astar_%d_%d" % [x, y], "type_id": "ground_flat", "grid_position": grid, "world_position": registry.grid_to_world(grid), "walkable": true, "surface_type": "road" if (x + y) % 3 == 0 else "ground", "cover_value": 100 if (x + y) % 2 == 0 else 0, "edge_type": "none"}))
	return registry


func _test_traversability_context() -> void:
	var registry = _make_registry(true)
	var from_grid := Vector2i(-1, 0)
	var to_grid := Vector2i.ZERO
	var context = PATHFINDER.StepCostContext.new(registry)
	var options := {PATHFINDER.STEP_COST_CONTEXT_OPTION: context, "lane_weight": NAN}
	var expected: bool = _old.can_traverse_step(from_grid, to_grid, registry)
	var actual: bool = _candidate._is_neighbor_walkable_scoped(from_grid, to_grid, registry, options)
	var repeated: bool = _candidate._is_neighbor_walkable_scoped(from_grid, to_grid, registry, options)
	_check(expected and actual == expected and repeated == expected and context.traversability_compute_count == 1 and context.traversability_hit_count == 1, "Scoped traversability caches exact true results even with irrelevant nonfinite cost options")
	_check(_candidate._is_neighbor_walkable_scoped(to_grid, from_grid, registry, options) == _old.can_traverse_step(to_grid, from_grid, registry) and context.traversability_compute_count == 2, "Reverse traversability uses its own directed cache key")
	var outside := Vector2i(22, 22)
	_check(not _candidate._is_neighbor_walkable_scoped(from_grid, outside, registry, options) and not _candidate._is_neighbor_walkable_scoped(from_grid, outside, registry, options) and context.traversability_compute_count == 3 and context.traversability_hit_count == 2, "False non-neighbor/outside results are cached without inventing playable terrain")
	var cost_before: float = _candidate.get_step_cost(from_grid, to_grid, registry, options)
	_check(not context.costs_by_from_grid.is_empty() and _candidate.can_traverse_step(from_grid, to_grid, registry), "Public can_traverse_step retains the original rule independently of the private memo")
	registry.set_runtime_tile_overrides([{"grid_position": to_grid, "walkable_override": false}])
	var blocked: bool = _candidate._is_neighbor_walkable_scoped(from_grid, to_grid, registry, options)
	_check(not blocked and blocked == _old.can_traverse_step(from_grid, to_grid, registry) and context.invalidation_count == 1 and context.costs_by_from_grid.is_empty(), "Revision change drops both caches before returning newly blocked truth")
	var blocked_cost: float = _candidate.get_step_cost(from_grid, to_grid, registry, options)
	_check(is_inf(blocked_cost) and blocked_cost == _old.get_step_cost(from_grid, to_grid, registry, options) and context.traversability_hit_count >= 3, "Cost computation reuses the same blocked traversal result and retains INF")
	registry.clear_runtime_tile_overrides()
	_check(_candidate._is_neighbor_walkable_scoped(from_grid, to_grid, registry, options) and context.invalidation_count == 2 and context.costs_by_from_grid.is_empty() and _candidate.get_step_cost(from_grid, to_grid, registry, options) == cost_before, "Removing the runtime blocker invalidates both caches and restores the exact original cost")
	var unsupported := RegistryWithoutRevision.new()
	var unsupported_context = PATHFINDER.StepCostContext.new(unsupported)
	var unsupported_options := {PATHFINDER.STEP_COST_CONTEXT_OPTION: unsupported_context}
	_check(_candidate._is_neighbor_walkable_scoped(from_grid, to_grid, unsupported, unsupported_options) == _old.can_traverse_step(from_grid, to_grid, unsupported) and unsupported_context.traversability_compute_count == 0 and unsupported_context.traversability_hit_count == 0, "Unsupported registries retain original traversability without memo reuse")
	registry.free()


func _test_local_routes() -> void:
	for hex in [true, false]:
		var registry = _make_registry(hex)
		var prefix := "Hex" if hex else "legacy square"
		for pair in [[Vector2i(-4, -3), Vector2i(4, 3)], [Vector2i(4, 3), Vector2i(-4, -3)], [Vector2i(-2, 1), Vector2i(2, -1)], [Vector2i(-1, -1), Vector2i(-1, -1)], [Vector2i.ZERO, Vector2i(30, 30)]]:
			_compare(prefix + " %s to %s" % pair, registry, pair[0], pair[1])
		_compare(prefix + " cover and road ties", registry, Vector2i(-4, -3), Vector2i(4, 3), {"cover_aware_enabled": true, "cover_weight": 10.0, "exposure_weight": 0.7, "hazard_grids": [Vector2i(1, 0)], "exposure_max_grid_distance": 4.0})
		_compare(prefix + " negative custom weights", registry, Vector2i(-4, -3), Vector2i(4, 3), {"cover_aware_enabled": true, "cover_weight": -4.0, "exposure_weight": -3.0, "corridor_enabled": true, "corridor_weight": -1.0, "lane_enabled": true, "lane_weight": -2.0, "lane_offset_grid": -2.0, "blocker_clearance_weight": -3.0})
		for y in range(-4, 5):
			registry.get_tile_at_grid(Vector2i(0, y)).walkable = false
		registry.notify_tile_data_changed()
		_compare(prefix + " disconnected barrier", registry, Vector2i(-3, -2), Vector2i(3, 2))
		_compare(prefix + " blocked endpoint", registry, Vector2i(-3, -2), Vector2i.ZERO)
		registry.free()
	_compare("invalid null registry", null, Vector2i.ZERO, Vector2i.RIGHT)


func _test_target_component_context() -> void:
	for hex in [true, false]:
		var registry = _make_registry(hex)
		var from_a := Vector2i(-1, 0)
		var from_b := Vector2i(-1, 1)
		var target := Vector2i.ZERO
		registry.get_tile_at_grid(target).height_level = 1
		registry.get_tile_at_grid(target).edge_type = TILE.EDGE_SLOPE
		registry.get_tile_at_grid(target).surface_type = "sand"
		registry.get_tile_at_grid(target).cover_value = 35
		registry.get_tile_at_grid(from_b).height_level = 1
		registry.get_tile_at_grid(from_b).edge_type = TILE.EDGE_SLOPE
		registry.notify_tile_data_changed([target, from_b])
		var options := {"cover_aware_enabled": true, "exposure_weight": 0.8, "cover_weight": 0.3, "hazard_grids": [Vector2i(2, 0)], "exposure_max_grid_distance": 6.0, "corridor_enabled": true, "corridor_from_grid": Vector2i(-4, -2), "corridor_to_grid": Vector2i(4, 2), "corridor_half_width_grid": 0.2, "corridor_weight": 0.4, "lane_enabled": true, "lane_offset_grid": -1.0, "lane_weight": 0.5, "blocker_clearance_weight": 0.3}
		var context = PATHFINDER.StepCostContext.new(registry)
		var scoped: Dictionary = options.duplicate(false)
		scoped[PATHFINDER.STEP_COST_CONTEXT_OPTION] = context
		var expected_a: float = _old.get_step_cost(from_a, target, registry, options)
		var expected_b: float = _old.get_step_cost(from_b, target, registry, options)
		var actual_a: float = _candidate.get_step_cost(from_a, target, registry, scoped)
		var actual_b: float = _candidate.get_step_cost(from_b, target, registry, scoped)
		var prefix := "Hex" if hex else "legacy diagonal"
		_check(is_finite(expected_a) and is_finite(expected_b) and expected_a != expected_b and actual_a == expected_a and actual_b == expected_b, prefix + ": mixed-height/diagonal directed costs keep exact old float math")
		_check(context.compute_count == 2 and context.target_cell_compute_count == 1 and context.target_cell_hit_count == 1, prefix + ": two incoming edges compute the same target components only once")
		var path: Array = [from_a, target, from_b, target]
		_check(_same_score(_old.score_path(path, registry, options), _candidate.score_path(path, registry, scoped)) and context.target_cell_compute_count == 3, prefix + ": scoring reuses target inputs while preserving every original sum and mean")
		registry.set_runtime_tile_overrides([{"grid_position": target, "cover_value_override": 100}])
		var changed: Dictionary = _candidate._get_target_cost_components(target, registry, scoped)
		_check(float(changed.get("cover_score", -1.0)) == _old._get_cover_score(target, registry, options) and float(changed.cover_score) == 1.0 and context.invalidation_count == 1 and context.costs_by_from_grid.is_empty() and context.traversability_by_from_grid.is_empty(), prefix + ": a revision atomically clears edge/traversal/cell caches before reading new cover truth")
		registry.clear_runtime_tile_overrides()
		var nonfinite := {"lane_enabled": true, "lane_weight": NAN, "lane_offset_grid": 1.0, "corridor_from_grid": Vector2i.ZERO, "corridor_to_grid": Vector2i.RIGHT}
		var nonfinite_context = PATHFINDER.StepCostContext.new(registry)
		var nonfinite_scoped: Dictionary = nonfinite.duplicate(false)
		nonfinite_scoped[PATHFINDER.STEP_COST_CONTEXT_OPTION] = nonfinite_context
		var expected_components := {"exposure_score": _old.get_exposure_score(target, registry, nonfinite), "cover_score": _old._get_cover_score(target, registry, nonfinite), "corridor_penalty": _old._get_corridor_penalty(target, nonfinite, registry), "lane_penalty": _old._get_lane_penalty(target, nonfinite, registry), "blocker_clearance_penalty": _old._get_blocker_clearance_penalty(target, registry, nonfinite)}
		var first: Dictionary = _candidate._get_target_cost_components(target, registry, nonfinite_scoped)
		var second: Dictionary = _candidate._get_target_cost_components(target, registry, nonfinite_scoped)
		_check(_same_score(expected_components, first) and _same_score(first, second) and nonfinite_context.target_cell_compute_count == 1 and nonfinite_context.target_cell_hit_count == 1, prefix + ": nonfinite component floats retain original semantics on cache hits")
		_check(_same_score(_old.score_path([from_a, target], registry, nonfinite), _candidate.score_path([from_a, target], registry, nonfinite_scoped)), prefix + ": nonfinite memo scoring remains exactly equal to old scoring")
		registry.free()
	var unsupported := RegistryWithoutRevision.new()
	var unsupported_context = PATHFINDER.StepCostContext.new(unsupported)
	_check(_candidate._get_target_cost_components(Vector2i.ZERO, unsupported, {PATHFINDER.STEP_COST_CONTEXT_OPTION: unsupported_context}).is_empty() and unsupported_context.target_cell_compute_count == 0, "Unsupported registries keep original component helper execution without cell memoization")


func _test_nonfinite_routes() -> void:
	var registry := REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, HEX.TOPOLOGY_ID)
	for grid in [Vector2i.ZERO, Vector2i.RIGHT]:
		registry.register_tile(TILE.new({"tile_id": "finite_%d" % grid.x, "type_id": "ground_flat", "grid_position": grid, "world_position": registry.grid_to_world(grid), "walkable": true, "surface_type": "ground", "cover_value": 0, "edge_type": "none"}))
	_compare("infinite clearance cost", registry, Vector2i.ZERO, Vector2i.RIGHT, {"blocker_clearance_weight": INF})
	_compare("NaN custom lane cost", registry, Vector2i.ZERO, Vector2i.RIGHT, {"lane_enabled": true, "lane_weight": NAN, "lane_offset_grid": 1.0, "corridor_from_grid": Vector2i.ZERO, "corridor_to_grid": Vector2i.RIGHT})
	_compare("NaN custom exposure", registry, Vector2i.ZERO, Vector2i.RIGHT, {"cover_aware_enabled": true, "exposure_weight": 1.0, "exposure_by_grid": {Vector2i.RIGHT: NAN}})
	registry.free()
