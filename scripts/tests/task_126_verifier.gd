extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_126 HPA Navigation Foundation Verifier ===")
	_test_graph_builds_deterministic_clusters()
	_test_blockers_split_local_components()
	_test_portals_follow_walkability_and_abstract_neighbors()
	_test_diagonal_portals_allow_open_steps_without_corner_cutting()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_graph_builds_deterministic_clusters() -> void:
	var registry = _make_registry(_make_rect_positions(Vector2i(0, 0), Vector2i(3, 3)), {})
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	var built: bool = bool(graph.call("build_from_registry", registry, 2))
	var cluster_ids: Array = graph.call("get_cluster_ids")
	_assert(built, "HPA graph builds from TerrainRegistry")
	_assert(cluster_ids.size() == 4, "HPA graph splits a 4x4 map into four 2x2 clusters")
	_assert(Vector2i(graph.call("get_cluster_id_for_grid", Vector2i(2, 1))) == Vector2i(1, 0), "Cluster assignment is deterministic")
	var cluster: Dictionary = Dictionary(graph.call("get_cluster_snapshot", Vector2i(0, 0)))
	_assert(Array(cluster.get("walkable_tiles", [])).size() == 4, "Cluster snapshot exposes walkable tiles")
	registry.free()


func _test_blockers_split_local_components() -> void:
	var blocked: Dictionary = {
		Vector2i(1, 0): false,
		Vector2i(1, 1): false,
		Vector2i(1, 2): false,
	}
	var registry = _make_registry(_make_rect_positions(Vector2i(0, 0), Vector2i(2, 2)), blocked)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 4)
	var cluster: Dictionary = Dictionary(graph.call("get_cluster_snapshot", Vector2i(0, 0)))
	_assert(Array(cluster.get("components", [])).size() == 2, "Blocker wall splits one cluster into two local components")
	_assert(bool(graph.call("are_grids_in_same_component", Vector2i(0, 0), Vector2i(0, 2))), "Tiles on the same side of a blocker wall stay connected")
	_assert(not bool(graph.call("are_grids_in_same_component", Vector2i(0, 1), Vector2i(2, 1))), "Tiles separated by a blocker wall are not in the same component")
	registry.free()


func _test_portals_follow_walkability_and_abstract_neighbors() -> void:
	var blocked: Dictionary = {
		Vector2i(2, 0): false,
	}
	var registry = _make_registry(_make_rect_positions(Vector2i(0, 0), Vector2i(3, 1)), blocked)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 2)
	var portals: Array = graph.call("get_portals_snapshot")
	var has_walkable_boundary_portal: bool = _has_portal_between(portals, Vector2i(1, 1), Vector2i(2, 1))
	var has_blocked_boundary_portal: bool = _has_portal_between(portals, Vector2i(1, 0), Vector2i(2, 0))
	_assert(has_walkable_boundary_portal, "HPA graph creates portals across walkable cluster boundaries")
	_assert(not has_blocked_boundary_portal, "HPA graph does not create portals into blocked boundary tiles")
	var from_component: String = String(graph.call("get_component_key_for_grid", Vector2i(1, 1)))
	var to_component: String = String(graph.call("get_component_key_for_grid", Vector2i(2, 1)))
	var abstract_neighbors: Array = graph.call("get_abstract_neighbors", from_component)
	_assert(not from_component.is_empty() and abstract_neighbors.has(to_component), "Portal endpoints are connected in the abstract graph")
	_assert(Array(graph.call("get_neighbor_cluster_ids", Vector2i(0, 0))).has(Vector2i(1, 0)), "Cluster snapshot tracks neighboring clusters")
	registry.free()


func _test_diagonal_portals_allow_open_steps_without_corner_cutting() -> void:
	var open_registry = _make_registry(_make_rect_positions(Vector2i(0, 0), Vector2i(1, 1)), {})
	var open_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	open_graph.call("build_from_registry", open_registry, 1)
	var open_portals: Array = open_graph.call("get_portals_snapshot")
	_assert(_has_portal_between(open_portals, Vector2i(0, 0), Vector2i(1, 1)), "HPA portals allow diagonal movement on open terrain")
	open_registry.free()

	var blocked_registry = _make_registry(
		_make_rect_positions(Vector2i(0, 0), Vector2i(1, 1)),
		{Vector2i(1, 0): false}
	)
	var blocked_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	blocked_graph.call("build_from_registry", blocked_registry, 1)
	var blocked_portals: Array = blocked_graph.call("get_portals_snapshot")
	_assert(not _has_portal_between(blocked_portals, Vector2i(0, 0), Vector2i(1, 1)), "HPA portals do not cut diagonally through blocked corners")
	blocked_registry.free()


func _make_rect_positions(min_grid: Vector2i, max_grid: Vector2i) -> Array:
	var result: Array = []
	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			result.append(Vector2i(x, y))
	return result


func _make_registry(grid_positions: Array, walkable_by_grid: Dictionary):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid_variant in grid_positions:
		var grid_position: Vector2i = Vector2i(grid_variant)
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


func _has_portal_between(portals: Array, a_grid: Vector2i, b_grid: Vector2i) -> bool:
	for portal_variant in portals:
		var portal: Dictionary = Dictionary(portal_variant)
		var from_grid: Vector2i = Vector2i(portal.get("from_grid", Vector2i.ZERO))
		var to_grid: Vector2i = Vector2i(portal.get("to_grid", Vector2i.ZERO))
		if (from_grid == a_grid and to_grid == b_grid) or (from_grid == b_grid and to_grid == a_grid):
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
