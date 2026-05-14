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
	scenarios["open_32x32_queries"] = _run_profile_query_scenario("32x32_open", _make_profile_registry(32, 32, "open"), _make_corner_queries(32, 32), {}, {})
	scenarios["hill_cover_32x32_queries"] = _run_profile_query_scenario("32x32_hill_cover", _make_profile_registry(32, 32, "hill_cover"), _make_corner_queries(32, 32), _make_cover_options([Vector2i(16, 16)], 0.8, 0.45), _make_cover_options([Vector2i(16, 16)], 0.8, 0.45))
	scenarios["open_64x64_queries"] = _run_profile_query_scenario("64x64_open", _make_profile_registry(64, 64, "open"), _make_corner_queries(64, 64), {}, {})
	scenarios["chokepoint_cover_64x64_queries"] = _run_profile_query_scenario("64x64_chokepoint_cover", _make_profile_registry(64, 64, "chokepoint_cover"), _make_corner_queries(64, 64), _make_cover_options([Vector2i(31, 31), Vector2i(32, 32)], 0.9, 0.6), _make_cover_options([Vector2i(31, 31), Vector2i(32, 32)], 0.9, 0.6))
	scenarios["los_cover_probe"] = _run_los_cover_probe()
	if scene_parent != null:
		scenarios["budget_delays"] = _run_budget_delay_probe(scene_parent)
		scenarios["avoidance_execution"] = _run_avoidance_execution_probe(scene_parent)
		scenarios["query_flood_staggering"] = _run_query_flood_staggering_probe(scene_parent)
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
		"hpa_graph_build_stats": _get_hpa_graph_build_stats(graph),
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
		"hpa_graph_build_stats": _get_hpa_graph_build_stats(graph),
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
		"hpa_graph_build_stats": _get_hpa_graph_build_stats(graph),
		"hpa_plain": _run_path_batch(registry, graph, queries, {}, metric_options, true),
		"hpa_cover_aware": _run_path_batch(registry, graph, queries, cover_options, metric_options, true),
	}
	registry.free()
	return result


func _run_profile_query_scenario(scenario_name: String, registry, queries: Array, path_options: Dictionary, scoring_options: Dictionary) -> Dictionary:
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 8)
	var result: Dictionary = {
		"map": scenario_name,
		"grid_size": _registry_size_hint(registry),
		"hpa_graph_build_stats": _get_hpa_graph_build_stats(graph),
		"terrain_a_star": _run_path_batch(registry, graph, queries, path_options, scoring_options, false),
		"hpa": _run_path_batch(registry, graph, queries, path_options, scoring_options, true),
	}
	registry.free()
	return result


func _run_los_cover_probe() -> Dictionary:
	var registry = _make_profile_registry(32, 32, "chokepoint_cover")
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var diagnostics: Dictionary = {}
	var options: Dictionary = _make_cover_options([Vector2i(15, 15), Vector2i(16, 16)], 1.0, 0.5)
	options["diagnostics"] = diagnostics
	var sample_grids: Array = []
	for x in range(10, 23, 2):
		sample_grids.append(Vector2i(x, 14))
		sample_grids.append(Vector2i(x, 18))
	var start_usec: int = Time.get_ticks_usec()
	var exposure_sum: float = 0.0
	for grid_variant in sample_grids:
		exposure_sum += float(pathfinder.call("get_exposure_score", Vector2i(grid_variant), registry, options))
	var cover_probe_path: Array = [
		Vector2i(14, 14),
		Vector2i(15, 15),
		Vector2i(16, 16),
		Vector2i(17, 17),
		Vector2i(18, 18),
	]
	var cover_score: Dictionary = Dictionary(pathfinder.call("score_path", cover_probe_path, registry, options))
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec
	registry.free()
	return {
		"sample_count": sample_grids.size(),
		"elapsed_usec": elapsed_usec,
		"avg_usec": float(elapsed_usec) / maxf(float(sample_grids.size()), 1.0),
		"exposure_sum": exposure_sum,
		"cover_sum": float(cover_score.get("cover_sum", 0.0)),
		"los_check_count": int(diagnostics.get("los_check_count", 0)),
		"cover_check_count": int(diagnostics.get("cover_check_count", 0)),
		"exposure_score_calls": int(diagnostics.get("exposure_score_calls", 0)),
	}


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


func _run_query_flood_staggering_probe(scene_parent: Node) -> Dictionary:
	var context: Dictionary = _make_terrain_context(scene_parent, _make_rect_registry(Vector2i(0, 0), Vector2i(15, 7), {}))
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_max_new_path_queries_per_tick", 2)
	var units: Array = []
	for index in range(8):
		units.append(_add_unit(context, "flood_%d" % index, Vector2i(0, index % 4)))
	for index in range(units.size()):
		var unit = units[index]
		var target_grid := Vector2i(15, index % 4)
		simulation_root.call("enqueue_command", _build_move_command(unit.get_unit_id(), registry.grid_to_world(target_grid)))
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_navigation_debug_snapshot"))
	_cleanup_context(context)
	return {
		"command_count": units.size(),
		"budget_limit": 2,
		"new_path_queries_this_tick": int(snapshot.get("new_path_queries_this_tick", 0)),
		"delayed_this_tick": int(snapshot.get("delayed_this_tick", 0)),
		"pending_query_count": int(snapshot.get("pending_query_count", 0)),
		"last_delay_reason": String(snapshot.get("last_delay_reason", "")),
		"staggering_policy": "budgeted_event_queries_not_per_frame",
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
	var start_usec: int = Time.get_ticks_usec()
	var delta: float = 0.1
	var max_speed: float = 80.0
	var alpha_target := Vector2(40.0, 0.0)
	var bravo_target := Vector2(-40.0, 0.0)
	for _tick in range(2):
		if bool(simulation_root.local_avoidance_enabled):
			simulation_root.call("_prepare_local_avoidance_tick")
		_apply_direct_crossing_step(simulation_root, alpha, alpha_target, max_speed, delta)
		_apply_direct_crossing_step(simulation_root, bravo, bravo_target, max_speed, delta)
		min_distance = minf(min_distance, alpha.global_position.distance_to(bravo.global_position))
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec
	return {
		"movement_time_usec": elapsed_usec,
		"min_distance": min_distance,
		"final_distance": alpha.global_position.distance_to(bravo.global_position),
	}


func _apply_direct_crossing_step(simulation_root, unit: Node2D, target_position: Vector2, max_speed: float, delta: float) -> void:
	var current_position: Vector2 = unit.global_position
	var to_target: Vector2 = target_position - current_position
	if to_target.is_zero_approx():
		return
	var desired_step_distance: float = minf(max_speed * delta, to_target.length())
	var desired_velocity: Vector2 = to_target.normalized() * (desired_step_distance / maxf(delta, 0.0001))
	var cmd: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": unit.call("get_unit_id") if unit.has_method("get_unit_id") else "",
		"local_avoidance_enabled": bool(simulation_root.local_avoidance_enabled),
	}
	var safe_velocity: Vector2 = simulation_root.call("_resolve_local_avoidance_velocity", cmd, unit, current_position, desired_velocity, max_speed, delta, null)
	var displacement: Vector2 = safe_velocity * delta
	if displacement.length() > desired_step_distance:
		displacement = displacement.normalized() * desired_step_distance
	unit.global_position = current_position + displacement
	simulation_root.call("_update_local_avoidance_agent_position", String(cmd.get("unit_id", "")), unit.global_position)


func _run_path_batch(registry, graph, queries: Array, path_options: Dictionary, scoring_options: Dictionary, use_hpa: bool) -> Dictionary:
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var status_counts: Dictionary = {}
	var total_path_length: float = 0.0
	var total_path_cost: float = 0.0
	var total_exposure: float = 0.0
	var total_cover: float = 0.0
	var successful_queries: int = 0
	var query_times: Array = []
	var path_lengths: Array = []
	var diagnostics: Dictionary = {}
	var start_usec: int = Time.get_ticks_usec()
	for query_variant in queries:
		var query: Dictionary = Dictionary(query_variant)
		var from_grid: Vector2i = Vector2i(query.get("from", Vector2i.ZERO))
		var to_grid: Vector2i = Vector2i(query.get("to", Vector2i.ZERO))
		var path: Array = []
		var status: String = "terrain_a_star"
		var query_options: Dictionary = path_options.duplicate(true)
		query_options["diagnostics"] = diagnostics
		var query_started_usec: int = Time.get_ticks_usec()
		if use_hpa:
			var hpa_result: Dictionary = Dictionary(hpa_pathfinder.call("find_path_with_status", from_grid, to_grid, registry, graph, query_options))
			path = Array(hpa_result.get("path", []))
			status = String(hpa_result.get("status", "unknown"))
		else:
			path = pathfinder.call("find_path_with_options", from_grid, to_grid, registry, query_options)
		status_counts[status] = int(status_counts.get(status, 0)) + 1
		if path.is_empty():
			query_times.append(Time.get_ticks_usec() - query_started_usec)
			continue
		successful_queries += 1
		var score_options: Dictionary = scoring_options.duplicate(true) if not scoring_options.is_empty() else query_options
		score_options["diagnostics"] = diagnostics
		var score: Dictionary = Dictionary(pathfinder.call("score_path", path, registry, score_options))
		total_path_length += float(score.get("path_length_grid", 0.0))
		total_path_cost += float(score.get("path_cost", 0.0))
		total_exposure += float(score.get("exposure_sum", 0.0))
		total_cover += float(score.get("cover_sum", 0.0))
		path_lengths.append(float(score.get("path_length_grid", 0.0)))
		query_times.append(Time.get_ticks_usec() - query_started_usec)
	var elapsed_usec: int = Time.get_ticks_usec() - start_usec
	var divisor: float = maxf(float(successful_queries), 1.0)
	return {
		"query_count": queries.size(),
		"successful_queries": successful_queries,
		"total_query_time_usec": elapsed_usec,
		"avg_query_time_usec": float(elapsed_usec) / maxf(float(queries.size()), 1.0),
		"query_time_usec": _stats_from_values(query_times),
		"path_length_stats": _stats_from_values(path_lengths),
		"avg_path_length_grid": total_path_length / divisor,
		"avg_path_cost": total_path_cost / divisor,
		"exposure_sum": total_exposure,
		"cover_sum": total_cover,
		"status_counts": status_counts,
		"los_check_count": int(diagnostics.get("los_check_count", 0)),
		"cover_check_count": int(diagnostics.get("cover_check_count", 0)),
		"cache_diagnostics": _build_cache_diagnostics(queries.size()),
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
		"has_large_map_metrics": scenarios.has("open_64x64_queries") and scenarios.has("chokepoint_cover_64x64_queries"),
		"has_hill_metrics": scenarios.has("hill_cover_32x32_queries"),
		"has_query_percentiles": _scenario_has_query_stats(scenarios.get("open_64x64_queries", {})) and _scenario_has_query_stats(scenarios.get("chokepoint_cover_64x64_queries", {})),
		"has_los_cover_diagnostics": _los_cover_probe_is_populated(Dictionary(scenarios.get("los_cover_probe", {}))),
		"has_cache_diagnostics": _scenario_has_cache_diagnostics(scenarios.get("open_64x64_queries", {})),
		"has_hpa_build_stats": _scenario_has_hpa_build_stats(scenarios.get("open_64x64_queries", {})) and _scenario_has_hpa_build_stats(scenarios.get("chokepoint_cover_64x64_queries", {})),
		"has_query_flood_staggering": scenarios.has("query_flood_staggering"),
	}


func _scenario_has_query_stats(scenario_variant: Variant) -> bool:
	if typeof(scenario_variant) != TYPE_DICTIONARY:
		return false
	var scenario: Dictionary = Dictionary(scenario_variant)
	for value_variant in scenario.values():
		if typeof(value_variant) != TYPE_DICTIONARY:
			continue
		var value: Dictionary = Dictionary(value_variant)
		var stats: Dictionary = Dictionary(value.get("query_time_usec", {}))
		if int(stats.get("count", 0)) > 0 and stats.has("median") and stats.has("p95") and stats.has("p99"):
			return true
	return false


func _scenario_has_cache_diagnostics(scenario_variant: Variant) -> bool:
	if typeof(scenario_variant) != TYPE_DICTIONARY:
		return false
	var scenario: Dictionary = Dictionary(scenario_variant)
	for value_variant in scenario.values():
		if typeof(value_variant) != TYPE_DICTIONARY:
			continue
		var value: Dictionary = Dictionary(value_variant)
		if value.has("cache_diagnostics") and typeof(value.get("cache_diagnostics", {})) == TYPE_DICTIONARY:
			return true
	return false


func _scenario_has_hpa_build_stats(scenario_variant: Variant) -> bool:
	if typeof(scenario_variant) != TYPE_DICTIONARY:
		return false
	var stats: Dictionary = Dictionary(Dictionary(scenario_variant).get("hpa_graph_build_stats", {}))
	return bool(stats.get("built", false)) \
		and int(stats.get("tile_count", 0)) > 0 \
		and int(stats.get("cluster_count", 0)) > 0 \
		and int(stats.get("elapsed_usec", -1)) >= 0


func _los_cover_probe_is_populated(probe: Dictionary) -> bool:
	return int(probe.get("sample_count", 0)) > 0 \
		and int(probe.get("los_check_count", 0)) > 0 \
		and int(probe.get("cover_check_count", 0)) >= 0


func _make_profile_registry(width: int, height: int, profile_id: String):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	var center_x: int = int(width / 2)
	var center_y: int = int(height / 2)
	for x in range(0, width):
		for y in range(0, height):
			var grid_position := Vector2i(x, y)
			var tile_config: Dictionary = {
				"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
				"type_id": "ground_flat",
				"grid_position": grid_position,
				"world_position": registry.grid_to_world(grid_position),
				"walkable": true,
				"blocks_los": false,
				"cover_value": 0,
				"height_level": 0,
				"object_height": 0,
				"surface_type": "ground",
				"edge_type": "none",
			}
			if profile_id == "hill_cover":
				_apply_hill_cover_profile(tile_config, grid_position, width, height)
			elif profile_id == "chokepoint_cover":
				_apply_chokepoint_cover_profile(tile_config, grid_position, center_x, center_y, height)
			registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new(tile_config))
	return registry


func _apply_hill_cover_profile(tile_config: Dictionary, grid_position: Vector2i, width: int, height: int) -> void:
	var hill_min_x: int = int(width / 3)
	var hill_max_x: int = width - hill_min_x - 1
	var hill_min_y: int = int(height / 3)
	var hill_max_y: int = height - hill_min_y - 1
	var on_hill: bool = grid_position.x >= hill_min_x and grid_position.x <= hill_max_x and grid_position.y >= hill_min_y and grid_position.y <= hill_max_y
	var on_hill_edge: bool = on_hill and (grid_position.x == hill_min_x or grid_position.x == hill_max_x or grid_position.y == hill_min_y or grid_position.y == hill_max_y)
	if on_hill:
		tile_config["height_level"] = 1
		tile_config["edge_type"] = "slope"
		tile_config["surface_type"] = "sand" if (grid_position.x + grid_position.y) % 3 == 0 else "ground"
		tile_config["cover_value"] = 55 if (grid_position.x + (grid_position.y * 2)) % 7 == 0 else 10
		tile_config["blocks_los"] = not on_hill_edge and int(tile_config.get("cover_value", 0)) >= 55
		tile_config["object_height"] = 1 if bool(tile_config.get("blocks_los", false)) else 0
	elif grid_position.x >= hill_min_x - 2 and grid_position.x <= hill_max_x + 2 and grid_position.y >= hill_min_y - 2 and grid_position.y <= hill_max_y + 2:
		tile_config["surface_type"] = "sand"
		tile_config["cover_value"] = 20


func _apply_chokepoint_cover_profile(tile_config: Dictionary, grid_position: Vector2i, center_x: int, center_y: int, height: int) -> void:
	var gap_centers: Array = [int(height / 4), center_y, int((height * 3) / 4)]
	var is_gap: bool = false
	for gap_center_variant in gap_centers:
		if absi(grid_position.y - int(gap_center_variant)) <= 2:
			is_gap = true
			break
	if grid_position.x == center_x and not is_gap:
		tile_config["walkable"] = false
		tile_config["type_id"] = "rock_large"
		tile_config["surface_type"] = "rock"
		tile_config["blocks_los"] = true
		tile_config["cover_value"] = 100
		tile_config["object_height"] = 2
	elif absi(grid_position.x - center_x) <= 2:
		tile_config["surface_type"] = "sand"
		tile_config["cover_value"] = 75 if not is_gap else 35
		tile_config["blocks_los"] = not is_gap and grid_position.x != center_x
		tile_config["object_height"] = 1 if bool(tile_config.get("blocks_los", false)) else 0


func _make_corner_queries(width: int, height: int) -> Array:
	return [
		{"from": Vector2i(0, 0), "to": Vector2i(width - 1, height - 1)},
		{"from": Vector2i(0, height - 1), "to": Vector2i(width - 1, 0)},
		{"from": Vector2i(int(width / 4), int(height / 4)), "to": Vector2i(int((width * 3) / 4), int((height * 3) / 4))},
		{"from": Vector2i(int(width / 4), int((height * 3) / 4)), "to": Vector2i(int((width * 3) / 4), int(height / 4))},
	]


func _registry_size_hint(registry) -> Dictionary:
	if registry == null or not registry.has_method("get_all_tiles"):
		return {}
	var tiles: Array = Array(registry.call("get_all_tiles"))
	if tiles.is_empty():
		return {}
	var min_grid: Vector2i = tiles[0].grid_position
	var max_grid: Vector2i = tiles[0].grid_position
	for tile_data in tiles:
		var grid_position: Vector2i = tile_data.grid_position
		min_grid.x = mini(min_grid.x, grid_position.x)
		min_grid.y = mini(min_grid.y, grid_position.y)
		max_grid.x = maxi(max_grid.x, grid_position.x)
		max_grid.y = maxi(max_grid.y, grid_position.y)
	return {
		"min": min_grid,
		"max": max_grid,
		"width": max_grid.x - min_grid.x + 1,
		"height": max_grid.y - min_grid.y + 1,
		"tile_count": tiles.size(),
	}


func _stats_from_values(values: Array) -> Dictionary:
	if values.is_empty():
		return {
			"count": 0,
			"min": 0.0,
			"max": 0.0,
			"avg": 0.0,
			"median": 0.0,
			"p95": 0.0,
			"p99": 0.0,
		}
	var sorted_values: Array = values.duplicate()
	sorted_values.sort()
	var sum: float = 0.0
	for value_variant in sorted_values:
		sum += float(value_variant)
	return {
		"count": sorted_values.size(),
		"min": float(sorted_values.front()),
		"max": float(sorted_values.back()),
		"avg": sum / float(sorted_values.size()),
		"median": _percentile_from_sorted_values(sorted_values, 0.5),
		"p95": _percentile_from_sorted_values(sorted_values, 0.95),
		"p99": _percentile_from_sorted_values(sorted_values, 0.99),
	}


func _percentile_from_sorted_values(sorted_values: Array, percentile: float) -> float:
	if sorted_values.is_empty():
		return 0.0
	var clamped_percentile: float = clampf(percentile, 0.0, 1.0)
	var index: int = clampi(ceili((float(sorted_values.size()) * clamped_percentile)) - 1, 0, sorted_values.size() - 1)
	return float(sorted_values[index])


func _build_cache_diagnostics(query_count: int) -> Dictionary:
	return {
		"path_cache_supported": false,
		"hit_count": 0,
		"miss_count": max(query_count, 0),
		"invalidation_count": 0,
		"diagnostic": "no_path_cache_layer_in_navigation_harness",
	}


func _get_hpa_graph_build_stats(graph) -> Dictionary:
	if graph != null and graph.has_method("get_last_build_stats"):
		return Dictionary(graph.call("get_last_build_stats")).duplicate(true)
	return {}


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
