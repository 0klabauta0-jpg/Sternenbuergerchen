class_name HPAPathfinder
extends RefCounted

const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")

const STATUS_INVALID: String = "invalid"
const STATUS_SAME_COMPONENT: String = "same_component"
const STATUS_HPA: String = "hpa"
const STATUS_NO_COMPONENT: String = "no_component"
const STATUS_NO_ABSTRACT_ROUTE: String = "no_abstract_route"
const STATUS_LOCAL_PATH_FAILED: String = "local_path_failed"

var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func find_path(from_grid: Vector2i, to_grid: Vector2i, registry, graph) -> Array:
	return Array(find_path_with_status(from_grid, to_grid, registry, graph).get("path", []))


func find_path_with_status(from_grid: Vector2i, to_grid: Vector2i, registry, graph) -> Dictionary:
	if registry == null or graph == null:
		return {"path": [], "status": STATUS_INVALID}

	var from_component: String = String(graph.call("get_component_key_for_grid", from_grid))
	var to_component: String = String(graph.call("get_component_key_for_grid", to_grid))
	if from_component.is_empty() or to_component.is_empty():
		return {"path": [], "status": STATUS_NO_COMPONENT}

	if from_component == to_component:
		var same_component_path: Array = _terrain_pathfinder.find_path(from_grid, to_grid, registry)
		return {
			"path": same_component_path,
			"status": STATUS_SAME_COMPONENT if not same_component_path.is_empty() else STATUS_LOCAL_PATH_FAILED,
		}

	var portal_route: Array = _find_portal_route(from_component, to_component, to_grid, graph)
	if portal_route.is_empty():
		return {"path": [], "status": STATUS_NO_ABSTRACT_ROUTE}

	var assembled_path: Array = _assemble_grid_path(from_grid, to_grid, portal_route, registry)
	return {
		"path": assembled_path,
		"status": STATUS_HPA if not assembled_path.is_empty() else STATUS_LOCAL_PATH_FAILED,
	}


func _find_portal_route(from_component: String, to_component: String, to_grid: Vector2i, graph) -> Array:
	var adjacency: Dictionary = _build_portal_adjacency(graph)
	var open_set: Array = [from_component]
	var came_from_edge: Dictionary = {}
	var g_score: Dictionary = {from_component: 0.0}
	var f_score: Dictionary = {from_component: 0.0}
	var visited: Dictionary = {}

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
			var edge: Dictionary = Dictionary(edge_variant)
			var neighbor_component: String = String(edge.get("to_component", ""))
			if neighbor_component.is_empty():
				continue
			var edge_cost: float = Vector2(Vector2i(edge.get("from_grid", Vector2i.ZERO))).distance_to(Vector2(Vector2i(edge.get("to_grid", Vector2i.ZERO)))) + 1.0
			var tentative_g_score: float = float(g_score.get(current_component, INF)) + edge_cost
			if tentative_g_score >= float(g_score.get(neighbor_component, INF)):
				continue
			came_from_edge[neighbor_component] = edge
			g_score[neighbor_component] = tentative_g_score
			var neighbor_grid: Vector2i = Vector2i(edge.get("to_grid", Vector2i.ZERO))
			f_score[neighbor_component] = tentative_g_score + Vector2(neighbor_grid).distance_to(Vector2(to_grid))
			if not open_set.has(neighbor_component):
				open_set.append(neighbor_component)

	return []


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
		}
		var reverse_edge: Dictionary = {
			"portal_id": String(portal.get("portal_id", "")),
			"from_component": String(portal.get("to_component", "")),
			"to_component": String(portal.get("from_component", "")),
			"from_grid": Vector2i(portal.get("to_grid", Vector2i.ZERO)),
			"to_grid": Vector2i(portal.get("from_grid", Vector2i.ZERO)),
		}
		_append_edge(adjacency, forward_edge)
		_append_edge(adjacency, reverse_edge)
	return adjacency


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


func _assemble_grid_path(from_grid: Vector2i, to_grid: Vector2i, portal_route: Array, registry) -> Array:
	var result: Array = [from_grid]
	var current_grid: Vector2i = from_grid
	for edge_variant in portal_route:
		var edge: Dictionary = Dictionary(edge_variant)
		var portal_from_grid: Vector2i = Vector2i(edge.get("from_grid", current_grid))
		var portal_to_grid: Vector2i = Vector2i(edge.get("to_grid", portal_from_grid))
		if not _append_local_path(result, current_grid, portal_from_grid, registry):
			return []
		_append_unique_grid(result, portal_to_grid)
		current_grid = portal_to_grid
	if not _append_local_path(result, current_grid, to_grid, registry):
		return []
	return result


func _append_local_path(result: Array, from_grid: Vector2i, to_grid: Vector2i, registry) -> bool:
	if from_grid == to_grid:
		_append_unique_grid(result, to_grid)
		return true
	var local_path: Array = _terrain_pathfinder.find_path(from_grid, to_grid, registry)
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
