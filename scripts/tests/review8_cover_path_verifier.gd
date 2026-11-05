extends SceneTree

const PATHFINDER: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_GRAPH: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const REGISTRY: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const HISTORICAL_PATHFINDER: String = "res://docs/qa/mission_a5_kartenrand_20261102/before/terrain_pathfinder_before.gd.txt"
const HISTORICAL_SHA: String = "190b34a0789734a967c28a57ee7b978973d2614849e50c5b476bc043ef701131"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== REVIEW8 cover-aware square8 A* oracle ===")
	_test_historical_cover_bug()
	_test_cover_route()
	_test_plain_route()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW8_COVER_PATH_PASS")
	quit(1 if _failed > 0 else 0)


func _test_historical_cover_bug() -> void:
	_assert(FileAccess.get_sha256(HISTORICAL_PATHFINDER) == HISTORICAL_SHA, "Historical TerrainPathfinder remains byte-pinned")
	var historical_script := GDScript.new()
	# Remove only the global class declaration; do not correct its policy.
	historical_script.source_code = FileAccess.get_file_as_string(HISTORICAL_PATHFINDER).replace("class_name TerrainPathfinder\n", "").replace("class_name TerrainPathfinder\r\n", "")
	var error: Error = historical_script.reload()
	_assert(error == OK, "Uninstrumented historical linear search compiles separately")
	if error != OK:
		return
	var historical = historical_script.new()
	var registry = _make_registry()
	var options: Dictionary = {"cover_aware_enabled": true, "cover_weight": 2.0, "exposure_weight": 0.0}
	var path: Array = historical.find_path_with_options(Vector2i(0, 4), Vector2i(8, 4), registry, options)
	var cost: float = float(historical.score_path(path, registry, options).get("path_cost", INF))
	_assert(is_equal_approx(cost, 8.0) and not _visits_cover_row(path), "Historical version retains the diagnosed suboptimal open route at cost eight")
	_assert(FileAccess.get_sha256(HISTORICAL_PATHFINDER) == HISTORICAL_SHA, "Characterizing historical bug leaves baseline bytes unchanged")
	registry.free()


func _test_cover_route() -> void:
	var registry = _make_registry()
	var pathfinder = PATHFINDER.new()
	var options: Dictionary = {"cover_aware_enabled": true, "cover_weight": 2.0, "exposure_weight": 0.0}
	var start := Vector2i(0, 4)
	var goal := Vector2i(8, 4)
	var path: Array = pathfinder.find_path_with_options(start, goal, registry, options)
	var cost: float = float(pathfinder.score_path(path, registry, options).get("path_cost", INF))
	var optimum: float = _dijkstra_cost(start, goal, registry, pathfinder, options)
	# Three uncovered vertical steps, a diagonal entering cover, seven cheap
	# cover steps and four uncovered return steps: 7 + sqrt(2)*.05 + 7*.05.
	var hand_checked_cost: float = 7.420710678118655
	_assert(is_equal_approx(optimum, hand_checked_cost), "Independent Dijkstra confirms hand-checked fixture cost")
	_assert(not path.is_empty() and Vector2i(path[0]) == start and Vector2i(path[-1]) == goal, "Cover path retains source and destination")
	_assert(_is_legal(path, registry, pathfinder), "Cover path obeys real traversal and corner rules")
	_assert(_visits_cover_row(path), "Cover-aware search discovers cheaper covered detour")
	_assert(cost < 8.0, "Cover-aware path costs less than the open eight-step line")
	_assert(is_equal_approx(cost, optimum), "Cover-aware A* cost equals independent Dijkstra oracle")
	print("REVIEW8_COVER_POLICY_CHANGE ", JSON.stringify({"historical_cost": 8.0, "corrected_cost": cost, "independent_dijkstra_cost": optimum, "hand_checked_cost": hand_checked_cost}))
	# A single component uses this same A* path in the production HPA pipeline.
	var graph = HPA_GRAPH.new()
	_assert(graph.build_from_registry(registry, 16), "Fixture builds a real HPA component")
	var hpa = HPA.new()
	var result: Dictionary = hpa.find_path_with_status(start, goal, registry, graph, options)
	var hpa_path: Array = Array(result.get("path", []))
	var hpa_cost: float = float(pathfinder.score_path(hpa_path, registry, options).get("path_cost", INF))
	_assert(String(result.get("status", "")) == HPA.STATUS_SAME_COMPONENT and _is_legal(hpa_path, registry, pathfinder), "HPA uses legal local cover-aware route")
	_assert(is_equal_approx(hpa_cost, optimum), "Real HPA local query retains optimal cover-aware cost")
	registry.free()


func _test_plain_route() -> void:
	var registry = _make_registry()
	var pathfinder = PATHFINDER.new()
	var start := Vector2i(0, 4)
	var goal := Vector2i(8, 4)
	for options in [{}, {"cover_aware_enabled": false, "cover_weight": 2.0}, {"cover_aware_enabled": true, "cover_weight": 0.0}]:
		var path: Array = pathfinder.find_path_with_options(start, goal, registry, options)
		var cost: float = float(pathfinder.score_path(path, registry, options).get("path_cost", INF))
		_assert(is_equal_approx(cost, 8.0) and path.size() == 9 and _is_legal(path, registry, pathfinder), "Neutral or disabled cover keeps shortest open route")
	registry.free()


func _make_registry():
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(9):
		for y in range(9):
			var grid := Vector2i(x, y)
			registry.register_tile(TILE.new({
				"tile_id": "tile_%d_%d" % [x, y],
				"type_id": "ground_flat",
				"grid_position": grid,
				"world_position": registry.grid_to_world(grid),
				"walkable": true,
				"blocks_los": false,
				"cover_value": 100 if y == 0 else 0,
				"surface_type": "ground",
			}))
	return registry


func _dijkstra_cost(start: Vector2i, goal: Vector2i, registry, pathfinder, options: Dictionary) -> float:
	# No A* heuristic/frontier/route helper is used by this small independent
	# exhaustive oracle. Production still owns the terrain step-cost contract.
	var unsettled: Array = [start]
	var settled: Dictionary = {}
	var costs: Dictionary = {start: 0.0}
	while not unsettled.is_empty():
		var best: int = 0
		for index in range(1, unsettled.size()):
			if float(costs[unsettled[index]]) < float(costs[unsettled[best]]):
				best = index
		var current: Vector2i = Vector2i(unsettled.pop_at(best))
		if current == goal:
			return float(costs[current])
		settled[current] = true
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var neighbor := current + Vector2i(dx, dy)
				if settled.has(neighbor) or not pathfinder.can_traverse_step(current, neighbor, registry):
					continue
				var candidate: float = float(costs[current]) + float(pathfinder.get_step_cost(current, neighbor, registry, options))
				if candidate >= float(costs.get(neighbor, INF)):
					continue
				costs[neighbor] = candidate
				if not unsettled.has(neighbor):
					unsettled.append(neighbor)
	return INF


func _is_legal(path: Array, registry, pathfinder) -> bool:
	if path.is_empty():
		return false
	for index in range(1, path.size()):
		if not pathfinder.can_traverse_step(Vector2i(path[index - 1]), Vector2i(path[index]), registry):
			return false
	return true


func _visits_cover_row(path: Array) -> bool:
	for grid_variant in path:
		if Vector2i(grid_variant).y == 0:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
