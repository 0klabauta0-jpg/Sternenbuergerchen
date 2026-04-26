class_name NavigationBenchmarkHarness
extends RefCounted

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")


func run_all(scene_parent: Node = null) -> Dictionary:
	var scenarios: Dictionary = {}
	scenarios["open_field_queries"] = _run_open_field_queries()
	scenarios["corridor_queries"] = _run_corridor_queries()
	scenarios["cover_exposure_queries"] = _run_cover_exposure_queries()
	if scene_parent != null:
		scenarios["budget_delays"] = _run_budget_delay_probe(scene_parent)
		scenarios["avoidance_execution"] = _run_avoidance_execution_probe(scene_parent)
	return {
		"scenarios": scenarios,
		"summary": _build_summary(scenarios),
	}


func _run_open_field_queries() -> Dictionary:
	var registry = _make_rect_registry(Vector2i(0, 0), Vector2i(17, 7), {})
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 4)
	var queries: Array = [
		{"from": Vector2i(0, 0), "to": Vector2i(17, 7)},
		{"from": Vector2i(0, 7), "to": Vector2i(17, 0)},
		{"from": Vector2i(2, 1), "to": Vector2i(15, 6)},
		{"from": Vector2i(3, 6), "to": Vector2i(16, 1)},
	]
	var result: Dictionary = {
		"map": "18x8_open",
		"terrain_a_star": _run_path_batch(registry, graph, queries, {}, {}, false),
		"hpa": _run_path_batch(registry, graph, queries, {}, {}, true),
	}
	registry.free()
	return result


func _run_corridor_queries() -> Dictionary:
	var blocked_by_grid: Dictionary = {}
	for x in range(0, 18):
		for y in range(0, 7):
			var grid := Vector2i(x, y)
			blocked_by_grid[grid] = y == 3 or x <= 1 or x >= 16
	var registry = _make_rect_registry(Vector2i(0, 0), Vector2i(17, 6), blocked_by_grid)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 4)
	var queries: Array = [
		{"from": Vector2i(0, 3), "to": Vector2i(17, 3)},
		{"from": Vector2i(1, 2), "to": Vector2i(16, 4)},
		{"from": Vector2i(1, 4), "to": Vector2i(16, 2)},
	]
	var result: Dictionary = {
		"map": "18x7_bottleneck_corridor",
		"terrain_a_star": _run_path_batch(registry, graph, queries, {}, {}, false),
		"hpa": _run_path_batch(registry, graph, queries, {}, {}, true),
	}
	registry.free()
	return result


func _run_cover_exposure_queries() -> Dictionary:
	var registry = _make_cover_test_registry(9)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 3)
	var queries: Array = [
		{"from": Vector2i(0, 1), "to": Vector2i(9, 1)},
	]
	var metric_options: Dictionary = _make_cover_options([Vector2i(4, 1)], 0.0, 0.0)
	var cover_options: Dictionary = _make_cover_options([Vector2i(4, 1)], 4.0, 2.0)
	var result: Dictionary = {
		"map": "cover_exposure_strip",
		"hpa_plain": _run_path_batch(registry, graph, queries, {}, metric_options, true),
		"hpa_cover_aware": _run_path_batch(registry, graph, queries, cover_options, metric_options, true),
	}
	registry.free()
	return result


func _run_budget_delay_probe(scene_parent: Node) -> Dictionary:
	var context: Dictionary = _make_terrain_context(scene_parent, _make_rect_registry(Vector2i(0, 0), Vector2i(9, 3), {}))
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var units: Array = [
		_add_unit(context, "budget_alpha", Vector2i(0, 0)),
		_add_unit(context, "budget_bravo", Vector2i(0, 1)),
		_add_unit(context, "budget_charlie", Vector2i(0, 2)),
	]
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_max_new_path_queries_per_tick", 1)
	for index in range(units.size()):
		var unit = units[index]
		simulation_root.call("enqueue_command", _build_move_command(unit.get_unit_id(), registry.grid_to_world(Vector2i(9, index))))
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	_cleanup_context(context)
	return {
		"command_count": units.size(),
		"budget_limit": 1,
		"new_path_queries_this_tick": int(snapshot.get("new_path_queries_this_tick", 0)),
		"delayed_this_tick": int(snapshot.get("delayed_this_tick", 0)),
		"pending_query_count": int(snapshot.get("pending_query_count", 0)),
		"last_delay_reason": String(snapshot.get("last_delay_reason", "")),
	}


func _run_avoidance_execution_probe(scene_parent: Node) -> Dictionary:
	var plain_context: Dictionary = _make_crossing_context(scene_parent, false, false)
	var avoid_context: Dictionary = _make_crossing_context(scene_parent, true, true)
	var plain_metrics: Dictionary = _run_crossing_pair(plain_context)
	var avoid_metrics: Dictionary = _run_crossing_pair(avoid_context)
	var avoid_snapshot: Dictionary = Dictionary(avoid_context["simulation_root"].call("get_local_avoidance_debug_snapshot", "avoid_alpha"))
	var deadlock_metrics: Dictionary = _run_deadlock_probe(scene_parent)
	_cleanup_context(plain_context)
	_cleanup_context(avoid_context)
	return {
		"plain": plain_metrics,
		"avoidance": avoid_metrics,
		"neighbor_count": int(avoid_snapshot.get("neighbor_count", 0)),
		"stuck_time_seconds": float(deadlock_metrics.get("stuck_time_seconds", 0.0)),
		"deadlock_marked": bool(deadlock_metrics.get("deadlock_marked", false)),
		"discarded_correction": bool(deadlock_metrics.get("discarded_correction", false)),
	}


func _run_deadlock_probe(scene_parent: Node) -> Dictionary:
	var context: Dictionary = _make_terrain_context(scene_parent, _make_one_lane_registry())
	var simulation_root = context["simulation_root"]
	var alpha = _add_unit(context, "deadlock_alpha", Vector2i(1, 1))
	_add_unit(context, "deadlock_bravo", Vector2i(1, 1))
	simulation_root.local_avoidance_enabled = true
	simulation_root.local_avoidance_debug_enabled = true
	simulation_root.local_avoidance_agent_radius = 80.0
	simulation_root.local_avoidance_neighbor_radius = 90.0
	simulation_root.local_avoidance_stuck_threshold_seconds = 0.5
	simulation_root.local_avoidance_stuck_speed_threshold = 5.0
	var cmd: Dictionary = _build_move_command("deadlock_alpha", Vector2(200.0, 0.0))
	for _index in range(2):
		simulation_root.call("_prepare_local_avoidance_tick")
		simulation_root.call("_resolve_local_avoidance_velocity", cmd, alpha, alpha.global_position, Vector2(0.0, -120.0), 120.0, 0.4, context["terrain_registry"])
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_local_avoidance_debug_snapshot", "deadlock_alpha"))
	_cleanup_context(context)
	return {
		"stuck_time_seconds": float(snapshot.get("stuck_time_seconds", 0.0)),
		"deadlock_marked": bool(snapshot.get("deadlock_marked", false)),
		"discarded_correction": bool(snapshot.get("discarded_correction", false)),
	}


func _run_crossing_pair(context: Dictionary) -> Dictionary:
	var simulation_root = context["simulation_root"]
	var alpha = context["alpha"]
	var bravo = context["bravo"]
	var min_distance: float = alpha.global_position.distance_to(bravo.global_position)
	simulation_root.call("enqueue_command", _build_move_command(alpha.get_unit_id(), Vector2(40.0, 0.0)))
	simulation_root.call("enqueue_command", _build_move_command(bravo.get_unit_id(), Vector2(-40.0, 0.0)))
	var start_usec: int = Time.get_ticks_usec()
	for _tick in range(2):
		simulation_root.call("_physics_process", 0.1)
		min_distance = minf(min_distance, alpha.global_position.distance_to(bravo.global_position))
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec
	return {
		"movement_time_usec": elapsed_usec,
		"min_distance": min_distance,
		"final_distance": alpha.global_position.distance_to(bravo.global_position),
	}


func _run_path_batch(registry, graph, queries: Array, path_options: Dictionary, scoring_options: Dictionary, use_hpa: bool) -> Dictionary:
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var status_counts: Dictionary = {}
	var total_path_length: float = 0.0
	var total_path_cost: float = 0.0
	var total_exposure: float = 0.0
	var total_cover: float = 0.0
	var successful_queries: int = 0
	var start_usec: int = Time.get_ticks_usec()
	for query_variant in queries:
		var query: Dictionary = Dictionary(query_variant)
		var from_grid: Vector2i = Vector2i(query.get("from", Vector2i.ZERO))
		var to_grid: Vector2i = Vector2i(query.get("to", Vector2i.ZERO))
		var path: Array = []
		var status: String = "terrain_a_star"
		if use_hpa:
			var hpa_result: Dictionary = Dictionary(hpa_pathfinder.call("find_path_with_status", from_grid, to_grid, registry, graph, path_options))
			path = Array(hpa_result.get("path", []))
			status = String(hpa_result.get("status", "unknown"))
		else:
			path = pathfinder.call("find_path_with_options", from_grid, to_grid, registry, path_options)
		status_counts[status] = int(status_counts.get(status, 0)) + 1
		if path.is_empty():
			continue
		successful_queries += 1
		var score_options: Dictionary = scoring_options if not scoring_options.is_empty() else path_options
		var score: Dictionary = Dictionary(pathfinder.call("score_path", path, registry, score_options))
		total_path_length += float(score.get("path_length_grid", 0.0))
		total_path_cost += float(score.get("path_cost", 0.0))
		total_exposure += float(score.get("exposure_sum", 0.0))
		total_cover += float(score.get("cover_sum", 0.0))
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec
	var divisor: float = maxf(float(successful_queries), 1.0)
	return {
		"query_count": queries.size(),
		"successful_queries": successful_queries,
		"total_query_time_usec": elapsed_usec,
		"avg_query_time_usec": float(elapsed_usec) / maxf(float(queries.size()), 1.0),
		"avg_path_length_grid": total_path_length / divisor,
		"avg_path_cost": total_path_cost / divisor,
		"exposure_sum": total_exposure,
		"cover_sum": total_cover,
		"status_counts": status_counts,
	}


func _build_summary(scenarios: Dictionary) -> Dictionary:
	var scenario_count: int = scenarios.size()
	var variant_count: int = 0
	for scenario_variant in scenarios.values():
		if typeof(scenario_variant) != TYPE_DICTIONARY:
			continue
		for value in Dictionary(scenario_variant).values():
			if typeof(value) == TYPE_DICTIONARY:
				variant_count += 1
	return {
		"scenario_count": scenario_count,
		"variant_count": variant_count,
		"has_query_metrics": scenarios.has("open_field_queries") and scenarios.has("corridor_queries"),
		"has_cover_metrics": scenarios.has("cover_exposure_queries"),
		"has_delay_metrics": scenarios.has("budget_delays"),
		"has_avoidance_metrics": scenarios.has("avoidance_execution"),
	}


func _make_cover_options(hazard_grids: Array, exposure_weight: float, cover_weight: float) -> Dictionary:
	return {
		"cover_aware_enabled": true,
		"hazard_grids": hazard_grids,
		"exposure_weight": exposure_weight,
		"cover_weight": cover_weight,
		"exposure_max_grid_distance": 4.0,
	}


func _make_rect_registry(min_grid: Vector2i, max_grid: Vector2i, walkable_by_grid: Dictionary):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			var grid_position := Vector2i(x, y)
			var walkable: bool = bool(walkable_by_grid.get(grid_position, true))
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
				"type_id": "ground_flat" if walkable else "rock_large",
				"grid_position": grid_position,
				"world_position": registry.grid_to_world(grid_position),
				"walkable": walkable,
				"surface_type": "ground" if walkable else "rock",
			}))
	return registry


func _make_cover_test_registry(max_x: int):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(0, max_x + 1):
		for y in range(0, 3):
			var grid_position := Vector2i(x, y)
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
				"type_id": "ground_flat",
				"grid_position": grid_position,
				"world_position": registry.grid_to_world(grid_position),
				"walkable": true,
				"blocks_los": y == 0 and x > 0 and x < max_x,
				"cover_value": 90 if y == 0 and x > 0 and x < max_x else 0,
				"surface_type": "ground",
			}))
	return registry


func _make_one_lane_registry():
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(0, 3):
		for y in range(0, 3):
			var grid := Vector2i(x, y)
			var walkable: bool = y == 1
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [grid.x, grid.y],
				"type_id": "ground_flat" if walkable else "rock_large",
				"grid_position": grid,
				"world_position": registry.grid_to_world(grid),
				"walkable": walkable,
				"surface_type": "ground" if walkable else "rock",
			}))
	return registry


func _make_terrain_context(scene_parent: Node, terrain_registry) -> Dictionary:
	var scene = Node.new()
	scene_parent.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"units": {},
	}


func _make_crossing_context(scene_parent: Node, enable_avoidance: bool, enable_debug: bool) -> Dictionary:
	var scene = Node.new()
	scene_parent.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.local_avoidance_enabled = enable_avoidance
	simulation_root.local_avoidance_debug_enabled = enable_debug
	simulation_root.local_avoidance_neighbor_radius = 72.0
	scene.add_child(simulation_root)
	var alpha = _make_unit("avoid_alpha", Vector2(-20.0, 0.0))
	var bravo = _make_unit("avoid_bravo", Vector2(20.0, 0.0))
	scene.add_child(alpha)
	scene.add_child(bravo)
	unit_registry.register_unit(alpha.get_unit_id(), alpha)
	unit_registry.register_unit(bravo.get_unit_id(), bravo)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
		"alpha": alpha,
		"bravo": bravo,
	}


func _add_unit(context: Dictionary, unit_id: String, unit_grid: Vector2i):
	var unit = _make_unit(unit_id, context["terrain_registry"].grid_to_world(unit_grid))
	context["scene"].add_child(unit)
	context["unit_registry"].register_unit(unit.get_unit_id(), unit)
	Dictionary(context["units"])[unit_id] = unit
	return unit


func _make_unit(unit_id: String, position: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = position
	return unit


func _build_move_command(unit_id: String, target_position: Vector2) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
	}


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()
