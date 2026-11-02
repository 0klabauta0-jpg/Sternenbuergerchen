class_name HPAPathfinder
extends RefCounted

const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")

const STATUS_INVALID: String = "invalid"
const STATUS_SAME_COMPONENT: String = "same_component"
const STATUS_HPA: String = "hpa"
const STATUS_NO_COMPONENT: String = "no_component"
const STATUS_NO_ABSTRACT_ROUTE: String = "no_abstract_route"
const STATUS_LOCAL_PATH_FAILED: String = "local_path_failed"
const RESULT_CACHE_LIMIT: int = 64

var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
var _cached_adjacency_graph = null
var _cached_adjacency_revision: int = -1
var _cached_portal_adjacency: Dictionary = {}
var _portal_adjacency_build_count: int = 0
var _portal_adjacency_hit_count: int = 0
var _last_query_debug_snapshot: Dictionary = {}
var _result_cache: Dictionary = {}
var _result_cache_fifo: Array[String] = []
var _result_cache_registry_ref: WeakRef
var _result_cache_graph_ref: WeakRef
var _result_cache_registry_revision: int = -1
var _result_cache_graph_revision: int = -1


func find_path(from_grid: Vector2i, to_grid: Vector2i, registry, graph) -> Array:
	return Array(find_path_with_status(from_grid, to_grid, registry, graph).get("path", []))


func find_path_with_status(from_grid: Vector2i, to_grid: Vector2i, registry, graph, options: Dictionary = {}) -> Dictionary:
	var cache_eligible: bool = _prepare_result_cache_scope(registry, graph)
	var cache_key: String = _result_cache_key(from_grid, to_grid, options) if cache_eligible else ""
	cache_eligible = cache_eligible and not cache_key.is_empty()
	if cache_eligible and _result_cache.has(cache_key):
		_reset_query_debug_snapshot()
		_last_query_debug_snapshot["result_cache_hit"] = true
		_last_query_debug_snapshot["result_cache_eligible"] = true
		_last_query_debug_snapshot["result_cache_entry_count"] = _result_cache.size()
		return Dictionary(_result_cache[cache_key]).duplicate(true)
	var registry_revision_before: int = _result_cache_registry_revision
	var graph_revision_before: int = _result_cache_graph_revision
	# Every local A* and score_path call below sees exactly this query's costs.
	# The caller's dictionary is untouched, including any old private context.
	var query_options: Dictionary = options.duplicate(false)
	var cost_context := TERRAIN_PATHFINDER_SCRIPT.StepCostContext.new(registry)
	query_options[TERRAIN_PATHFINDER_SCRIPT.STEP_COST_CONTEXT_OPTION] = cost_context
	var result: Dictionary = _find_path_with_status_scoped(from_grid, to_grid, registry, graph, query_options)
	_last_query_debug_snapshot["step_cost_compute_count"] = cost_context.compute_count
	_last_query_debug_snapshot["step_cost_cache_hit_count"] = cost_context.hit_count
	_last_query_debug_snapshot["step_cost_cache_invalidation_count"] = cost_context.invalidation_count
	_last_query_debug_snapshot["traversability_compute_count"] = cost_context.traversability_compute_count
	_last_query_debug_snapshot["traversability_cache_hit_count"] = cost_context.traversability_hit_count
	_last_query_debug_snapshot["target_cell_compute_count"] = cost_context.target_cell_compute_count
	_last_query_debug_snapshot["target_cell_cache_hit_count"] = cost_context.target_cell_hit_count
	# Even an unusual synchronous registry getter that changes its revision must
	# not publish a result under a later revision than the one the query began on.
	if cache_eligible:
		cache_eligible = _prepare_result_cache_scope(registry, graph) and _result_cache_registry_revision == registry_revision_before and _result_cache_graph_revision == graph_revision_before
	if cache_eligible and String(result.get("status", "")) in [STATUS_HPA, STATUS_SAME_COMPONENT] and typeof(result.get("path")) == TYPE_ARRAY and not Array(result.get("path", [])).is_empty():
		if not _result_cache.has(cache_key):
			while _result_cache_fifo.size() >= RESULT_CACHE_LIMIT:
				_result_cache.erase(_result_cache_fifo.pop_front())
			_result_cache_fifo.append(cache_key)
		_result_cache[cache_key] = result.duplicate(true)
	_last_query_debug_snapshot["result_cache_hit"] = false
	_last_query_debug_snapshot["result_cache_eligible"] = cache_eligible
	_last_query_debug_snapshot["result_cache_entry_count"] = _result_cache.size()
	return result.duplicate(true)


func _reset_query_debug_snapshot() -> void:
	_last_query_debug_snapshot = {
		"portal_candidate_count": 0,
		"local_astar_evaluation_count": 0,
		"lower_bound_pruned_count": 0,
		"minimum_local_step_cost": -1.0,
		"step_cost_compute_count": 0,
		"step_cost_cache_hit_count": 0,
		"step_cost_cache_invalidation_count": 0,
		"traversability_compute_count": 0,
		"traversability_cache_hit_count": 0,
		"target_cell_compute_count": 0,
		"target_cell_cache_hit_count": 0,
		"derived_only": true,
	}


func _prepare_result_cache_scope(registry, graph) -> bool:
	if typeof(registry) != TYPE_OBJECT or typeof(graph) != TYPE_OBJECT or not is_instance_valid(registry) or not is_instance_valid(graph) or not registry.has_method("get_revision") or not graph.has_method("get_revision"):
		_clear_result_cache_scope()
		return false
	var registry_revision: Variant = registry.call("get_revision")
	var graph_revision: Variant = graph.call("get_revision")
	if typeof(registry_revision) != TYPE_INT or typeof(graph_revision) != TYPE_INT:
		_clear_result_cache_scope()
		return false
	var previous_registry = _result_cache_registry_ref.get_ref() if _result_cache_registry_ref != null else null
	var previous_graph = _result_cache_graph_ref.get_ref() if _result_cache_graph_ref != null else null
	if previous_registry != registry or previous_graph != graph or _result_cache_registry_revision != int(registry_revision) or _result_cache_graph_revision != int(graph_revision):
		_clear_result_cache_scope()
		_result_cache_registry_ref = weakref(registry)
		_result_cache_graph_ref = weakref(graph)
		_result_cache_registry_revision = int(registry_revision)
		_result_cache_graph_revision = int(graph_revision)
	return true


func _clear_result_cache_scope() -> void:
	_result_cache.clear()
	_result_cache_fifo.clear()
	_result_cache_registry_ref = null
	_result_cache_graph_ref = null
	_result_cache_registry_revision = -1
	_result_cache_graph_revision = -1


func _result_cache_key(from_grid: Vector2i, to_grid: Vector2i, options: Dictionary) -> String:
	var cost_options: Dictionary = options.duplicate(false)
	cost_options.erase("diagnostics")
	cost_options.erase(TERRAIN_PATHFINDER_SCRIPT.STEP_COST_CONTEXT_OPTION)
	if not _is_result_cache_value_supported(cost_options):
		return ""
	# No float formatting, hashing or sorting: exact builtin Variant bytes retain
	# all option fields/types and Array order. Dictionary order may cause a safe
	# extra miss. Hex encoding is lossless and produces a Dictionary-safe key.
	return var_to_bytes([from_grid, to_grid, cost_options]).hex_encode()


func _is_result_cache_value_supported(value: Variant, depth: int = 0) -> bool:
	if depth > 32:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2I:
			return true
		TYPE_FLOAT:
			return is_finite(float(value))
		TYPE_VECTOR2:
			return is_finite(float(value.x)) and is_finite(float(value.y))
		TYPE_ARRAY:
			for item in value:
				if not _is_result_cache_value_supported(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not _is_result_cache_value_supported(key, depth + 1) or not _is_result_cache_value_supported(value[key], depth + 1):
					return false
			return true
	return false


func _find_path_with_status_scoped(from_grid: Vector2i, to_grid: Vector2i, registry, graph, options: Dictionary) -> Dictionary:
	_reset_query_debug_snapshot()
	if registry == null or graph == null:
		return {"path": [], "status": STATUS_INVALID}

	var from_component: String = String(graph.call("get_component_key_for_grid", from_grid))
	var to_component: String = String(graph.call("get_component_key_for_grid", to_grid))
	if from_component.is_empty() or to_component.is_empty():
		return {"path": [], "status": STATUS_NO_COMPONENT}

	if from_component == to_component:
		var same_component_path: Array = _find_local_path(from_grid, to_grid, registry, options)
		return {
			"path": same_component_path,
			"status": STATUS_SAME_COMPONENT if not same_component_path.is_empty() else STATUS_LOCAL_PATH_FAILED,
		}

	var portal_route: Array = _find_portal_route(from_component, to_component, to_grid, graph, registry, options, from_grid)
	if portal_route.is_empty():
		return {"path": [], "status": STATUS_NO_ABSTRACT_ROUTE}

	var assembled_path: Array = _assemble_grid_path(from_grid, to_grid, portal_route, registry, options)
	return {
		"path": assembled_path,
		"status": STATUS_HPA if not assembled_path.is_empty() else STATUS_LOCAL_PATH_FAILED,
	}


func _find_portal_route(from_component: String, to_component: String, to_grid: Vector2i, graph, registry, options: Dictionary = {}, from_grid: Vector2i = Vector2i.ZERO) -> Array:
	var adjacency: Dictionary = _get_portal_adjacency(graph)
	var open_set: Array = [from_component]
	var came_from_edge: Dictionary = {}
	var g_score: Dictionary = {from_component: 0.0}
	var f_score: Dictionary = {from_component: 0.0}
	var visited: Dictionary = {}
	var hex_mode: bool = registry.has_method("get_grid_topology") and String(registry.call("get_grid_topology")) == HEX_GRID_SCRIPT.TOPOLOGY_ID
	var entered_grid_by_component: Dictionary = {from_component: from_grid}
	var minimum_local_step_cost: float = _minimum_local_step_cost(options) if hex_mode else -1.0
	_last_query_debug_snapshot["minimum_local_step_cost"] = minimum_local_step_cost

	while not open_set.is_empty():
		var current_component: String = _pop_lowest_score_component(open_set, f_score)
		if current_component == to_component:
			return _reconstruct_portal_route(came_from_edge, current_component, from_component)
		if visited.has(current_component):
			continue
		visited[current_component] = true

		var edges: Array = Array(adjacency.get(current_component, []))
		edges.sort_custom(_sort_edges)
		for edge_variant in edges:
			_last_query_debug_snapshot["portal_candidate_count"] = int(_last_query_debug_snapshot.get("portal_candidate_count", 0)) + 1
			var edge: Dictionary = Dictionary(edge_variant)
			var neighbor_component: String = String(edge.get("to_component", ""))
			if neighbor_component.is_empty():
				continue
			var edge_cost: float = _get_portal_edge_cost(edge, registry, options)
			if hex_mode:
				# Hex routes account for actual local travel to each selected portal.
				# The legacy component scoring remains untouched for old maps.
				var entry_grid: Vector2i = Vector2i(entered_grid_by_component.get(current_component, from_grid))
				var portal_grid: Vector2i = Vector2i(edge.get("from_grid", entry_grid))
				if _cannot_improve_from_lower_bound(
					float(g_score.get(current_component, INF)), edge_cost,
					float(g_score.get(neighbor_component, INF)), entry_grid, portal_grid,
					Vector2i(edge.get("to_grid", to_grid)), to_grid,
					neighbor_component == to_component, minimum_local_step_cost
				):
					_last_query_debug_snapshot["lower_bound_pruned_count"] = int(_last_query_debug_snapshot.get("lower_bound_pruned_count", 0)) + 1
					continue
				var entry_path: Array = _find_local_path(entry_grid, portal_grid, registry, options)
				if entry_path.is_empty():
					continue
				var entry_score: Dictionary = Dictionary(_terrain_pathfinder.call("score_path", entry_path, registry, options))
				edge_cost += float(entry_score.get("path_cost", 0.0))
				if neighbor_component == to_component:
					var exit_path: Array = _find_local_path(Vector2i(edge.get("to_grid", to_grid)), to_grid, registry, options)
					if exit_path.is_empty():
						continue
					var exit_score: Dictionary = Dictionary(_terrain_pathfinder.call("score_path", exit_path, registry, options))
					edge_cost += float(exit_score.get("path_cost", 0.0))
			var tentative_g_score: float = float(g_score.get(current_component, INF)) + edge_cost
			var previous_score: float = float(g_score.get(neighbor_component, INF))
			if tentative_g_score > previous_score:
				continue
			if tentative_g_score == previous_score:
				if not hex_mode:
					continue
				var old_entry: Vector2i = Vector2i(entered_grid_by_component.get(neighbor_component, to_grid))
				var new_entry: Vector2i = Vector2i(edge.get("to_grid", to_grid))
				if HEX_GRID_SCRIPT.distance(new_entry, to_grid) >= HEX_GRID_SCRIPT.distance(old_entry, to_grid):
					continue
			came_from_edge[neighbor_component] = edge
			g_score[neighbor_component] = tentative_g_score
			var neighbor_grid: Vector2i = Vector2i(edge.get("to_grid", Vector2i.ZERO))
			entered_grid_by_component[neighbor_component] = neighbor_grid
			var heuristic: float = Vector2(neighbor_grid).distance_to(Vector2(to_grid))
			if hex_mode:
				heuristic = 0.0 if neighbor_component == to_component else float(HEX_GRID_SCRIPT.distance(neighbor_grid, to_grid)) * TERRAIN_PATHFINDER_SCRIPT.MIN_SURFACE_PATH_COST
			f_score[neighbor_component] = tentative_g_score + heuristic
			if not open_set.has(neighbor_component):
				open_set.append(neighbor_component)

	return []


func get_last_query_debug_snapshot() -> Dictionary:
	return _last_query_debug_snapshot.duplicate(true)


func _find_local_path(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary) -> Array:
	_last_query_debug_snapshot["local_astar_evaluation_count"] = int(_last_query_debug_snapshot.get("local_astar_evaluation_count", 0)) + 1
	return Array(_terrain_pathfinder.call("find_path_with_options", from_grid, to_grid, registry, options))


func _minimum_local_step_cost(options: Dictionary) -> float:
	# TerrainPathfinder clamps all penalty weights to >= 0. Cover-aware costs
	# can subtract at most max(cover_weight, 0) because cover is clamped to [0,1],
	# and are clamped to 0.05 before the other nonnegative penalties.
	# Negative finite custom weights therefore retain the same proven floor.
	# Nonfinite cost input keeps the original evaluation path without pruning.
	for key in ["exposure_weight", "cover_weight", "corridor_weight", "corridor_half_width_grid", "lane_weight", "lane_offset_grid", "blocker_clearance_weight", "exposure_max_grid_distance"]:
		if options.has(key):
			if typeof(options[key]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(options[key])):
				return -1.0
	if bool(options.get("cover_aware_enabled", false)):
		if typeof(options.get("exposure_by_grid", {})) != TYPE_DICTIONARY:
			return -1.0
		for value in Dictionary(options.get("exposure_by_grid", {})).values():
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
				return -1.0
		var cover_weight: float = maxf(float(options.get("cover_weight", 0.0)), 0.0)
		return maxf(TERRAIN_PATHFINDER_SCRIPT.MIN_COVER_AWARE_STEP_COST, TERRAIN_PATHFINDER_SCRIPT.MIN_SURFACE_PATH_COST - cover_weight)
	return TERRAIN_PATHFINDER_SCRIPT.MIN_SURFACE_PATH_COST


func _cannot_improve_from_lower_bound(current_score: float, base_edge_cost: float, previous_score: float, entry_grid: Vector2i, portal_grid: Vector2i, exit_grid: Vector2i, to_grid: Vector2i, includes_exit: bool, minimum_step_cost: float) -> bool:
	if minimum_step_cost < 0.0 or not is_finite(current_score) or not is_finite(base_edge_cost) or not is_finite(previous_score):
		return false
	# Any six-neighbor hex path contains at least Hex.distance steps. Keep the
	# existing addition order: base edge + local entry + optional local exit.
	var edge_lower_bound: float = base_edge_cost + float(HEX_GRID_SCRIPT.distance(entry_grid, portal_grid)) * minimum_step_cost
	if includes_exit:
		edge_lower_bound += float(HEX_GRID_SCRIPT.distance(exit_grid, to_grid)) * minimum_step_cost
	var lower_bound: float = current_score + edge_lower_bound
	if not is_finite(lower_bound):
		return false
	# A conservative margin absorbs multiplication/summation rounding. Equality
	# and near equality always run the original A* and unchanged entry-distance
	# tie rule below; no candidate is rejected merely for matching the bound.
	var rounding_margin: float = 0.000000001 * maxf(1.0, maxf(absf(lower_bound), absf(previous_score)))
	return lower_bound > previous_score + rounding_margin


func _build_portal_adjacency(graph) -> Dictionary:
	var adjacency: Dictionary = {}
	for portal_variant in Array(graph.call("get_portals_snapshot")):
		var portal: Dictionary = Dictionary(portal_variant)
		var forward_edge: Dictionary = {
			"portal_id": String(portal.get("portal_id", "")),
			"from_component": String(portal.get("from_component", "")),
			"to_component": String(portal.get("to_component", "")),
			"from_grid": Vector2i(portal.get("from_grid", Vector2i.ZERO)),
			"to_grid": Vector2i(portal.get("to_grid", Vector2i.ZERO)),
			"mean_cover": float(portal.get("mean_cover", 0.0)),
			"min_cover": float(portal.get("min_cover", 0.0)),
		}
		var reverse_edge: Dictionary = {
			"portal_id": String(portal.get("portal_id", "")),
			"from_component": String(portal.get("to_component", "")),
			"to_component": String(portal.get("from_component", "")),
			"from_grid": Vector2i(portal.get("to_grid", Vector2i.ZERO)),
			"to_grid": Vector2i(portal.get("from_grid", Vector2i.ZERO)),
			"mean_cover": float(portal.get("mean_cover", 0.0)),
			"min_cover": float(portal.get("min_cover", 0.0)),
		}
		_append_edge(adjacency, forward_edge)
		_append_edge(adjacency, reverse_edge)
	return adjacency


func _get_portal_adjacency(graph) -> Dictionary:
	var revision: int = int(graph.call("get_revision")) if graph != null and graph.has_method("get_revision") else -1
	if graph == _cached_adjacency_graph and revision == _cached_adjacency_revision and not _cached_portal_adjacency.is_empty():
		_portal_adjacency_hit_count += 1
		return _cached_portal_adjacency
	_cached_portal_adjacency = _build_portal_adjacency(graph)
	_cached_adjacency_graph = graph
	_cached_adjacency_revision = revision
	_portal_adjacency_build_count += 1
	return _cached_portal_adjacency


func get_portal_adjacency_cache_snapshot() -> Dictionary:
	return {
		"build_count": _portal_adjacency_build_count,
		"hit_count": _portal_adjacency_hit_count,
		"graph_revision": _cached_adjacency_revision,
	}


func _append_edge(adjacency: Dictionary, edge: Dictionary) -> void:
	var from_component: String = String(edge.get("from_component", ""))
	var to_component: String = String(edge.get("to_component", ""))
	if from_component.is_empty() or to_component.is_empty():
		return
	var edges: Array = Array(adjacency.get(from_component, []))
	edges.append(edge)
	adjacency[from_component] = edges


func _pop_lowest_score_component(open_set: Array, f_score: Dictionary) -> String:
	var best_index: int = 0
	var best_score: float = float(f_score.get(open_set[0], INF))
	var best_component: String = String(open_set[0])
	for index in range(1, open_set.size()):
		var candidate_component: String = String(open_set[index])
		var candidate_score: float = float(f_score.get(candidate_component, INF))
		if candidate_score > best_score:
			continue
		if absf(candidate_score - best_score) <= 0.0001 and candidate_component >= best_component:
			continue
		best_index = index
		best_score = candidate_score
		best_component = candidate_component
	open_set.remove_at(best_index)
	return best_component


func _reconstruct_portal_route(came_from_edge: Dictionary, current_component: String, from_component: String) -> Array:
	var route: Array = []
	while current_component != from_component:
		if not came_from_edge.has(current_component):
			return []
		var edge: Dictionary = Dictionary(came_from_edge[current_component])
		route.push_front(edge)
		current_component = String(edge.get("from_component", ""))
	return route


func _assemble_grid_path(from_grid: Vector2i, to_grid: Vector2i, portal_route: Array, registry, options: Dictionary = {}) -> Array:
	var result: Array = [from_grid]
	var current_grid: Vector2i = from_grid
	for edge_variant in portal_route:
		var edge: Dictionary = Dictionary(edge_variant)
		var portal_from_grid: Vector2i = Vector2i(edge.get("from_grid", current_grid))
		var portal_to_grid: Vector2i = Vector2i(edge.get("to_grid", portal_from_grid))
		if not _append_local_path(result, current_grid, portal_from_grid, registry, options):
			return []
		_append_unique_grid(result, portal_to_grid)
		current_grid = portal_to_grid
	if not _append_local_path(result, current_grid, to_grid, registry, options):
		return []
	return result


func _append_local_path(result: Array, from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> bool:
	if from_grid == to_grid:
		_append_unique_grid(result, to_grid)
		return true
	var local_path: Array = _find_local_path(from_grid, to_grid, registry, options)
	if local_path.is_empty():
		return false
	for grid_variant in local_path:
		_append_unique_grid(result, Vector2i(grid_variant))
	return true


func _append_unique_grid(result: Array, grid_position: Vector2i) -> void:
	if result.is_empty() or Vector2i(result[-1]) != grid_position:
		result.append(grid_position)


func _sort_edges(a: Dictionary, b: Dictionary) -> bool:
	var portal_a: String = String(a.get("portal_id", ""))
	var portal_b: String = String(b.get("portal_id", ""))
	if portal_a == portal_b:
		return String(a.get("to_component", "")) < String(b.get("to_component", ""))
	return portal_a < portal_b


func _get_portal_edge_cost(edge: Dictionary, registry, options: Dictionary = {}) -> float:
	var from_grid: Vector2i = Vector2i(edge.get("from_grid", Vector2i.ZERO))
	var to_grid: Vector2i = Vector2i(edge.get("to_grid", Vector2i.ZERO))
	var step_cost: float = float(_terrain_pathfinder.call("get_step_cost", from_grid, to_grid, registry, options))
	if is_inf(step_cost):
		if registry != null and registry.has_method("get_grid_topology") and String(registry.call("get_grid_topology")) == HEX_GRID_SCRIPT.TOPOLOGY_ID:
			step_cost = float(HEX_GRID_SCRIPT.distance(from_grid, to_grid)) + 1.0
		else:
			step_cost = Vector2(from_grid).distance_to(Vector2(to_grid)) + 1.0
	return maxf(step_cost, 0.001)
