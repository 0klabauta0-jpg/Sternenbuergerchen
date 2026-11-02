extends SceneTree

const REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const SIMULATION_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const DOOR: Vector2i = Vector2i(8, 0)
const TARGET: Vector2i = Vector2i(16, 0)
var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for stored_walkable in [false, true]:
		_test_runtime_door(stored_walkable)
	print("REVIEW_20261102_P1_NAVIGATION_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


# Reverting either graph membership read to tile_data.walkable breaks this test:
# runtime-open doors disappear and runtime-closed doors retain a component.
func _test_runtime_door(stored_walkable: bool) -> void:
	var registry = REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(17):
		registry.register_tile(TILE_SCRIPT.new({
			"tile_id": "door_corridor_%d" % x,
			"type_id": "station_floor",
			"grid_position": Vector2i(x, 0),
			"world_position": registry.grid_to_world(Vector2i(x, 0)),
			"walkable": x != DOOR.x or stored_walkable,
			"blocks_los": x == DOOR.x and not stored_walkable,
			"height_level": 0,
			"edge_type": "none",
		}))
	var graph = GRAPH_SCRIPT.new()
	_check(graph.build_from_registry(registry, 8), "Initial graph builds")
	var simulation = SIMULATION_SCRIPT.new()
	_check_simulation_endpoint(simulation, registry, stored_walkable, "Initial full")
	for effective_open in [not stored_walkable, stored_walkable]:
		registry.clear_dirty_grid_positions()
		registry.set_runtime_tile_overrides([{
			"grid_position": DOOR,
			"walkable_override": effective_open,
			"blocks_los_override": not effective_open,
		}])
		var label: String = "stored=%s effective=%s" % [stored_walkable, effective_open]
		_check(registry.get_tile_at_grid(DOOR).walkable == stored_walkable, label + " preserves stored tile data")
		_check(registry.is_walkable(DOOR) == effective_open, label + " registry exposes effective walkability")
		_check(graph.rebuild_dirty_clusters_from_registry(registry, registry.get_dirty_grid_positions(), 8), label + " dirty build succeeds")
		_check(bool(graph.get_last_build_stats().get("incremental", false)), label + " uses dirty build")
		_check_graph_paths(registry, graph, effective_open, label + " dirty")
		var full_graph = GRAPH_SCRIPT.new()
		_check(full_graph.build_from_registry(registry, 8), label + " full build succeeds")
		_check_graph_paths(registry, full_graph, effective_open, label + " full")
		_check_simulation_endpoint(simulation, registry, effective_open, label + " cached simulation")
		var cached_stats: Dictionary = simulation.call("_get_hpa_navigation_debug_snapshot")
		_check(String(Dictionary(cached_stats.get("last_build_stats", {})).get("runtime_rebuild_mode", "")) == "incremental", label + " simulation invalidates cached graph incrementally")
		var fresh_simulation = SIMULATION_SCRIPT.new()
		_check_simulation_endpoint(fresh_simulation, registry, effective_open, label + " fresh simulation")
		fresh_simulation.free()
	simulation.free()
	registry.free()


func _check_graph_paths(registry, graph, effective_open: bool, label: String) -> void:
	_check(not graph.get_component_key_for_grid(DOOR).is_empty() == effective_open, label + " component membership matches effective door")
	var cluster: Dictionary = graph.get_cluster_snapshot(Vector2i(1, 0))
	_check(Array(cluster.get("walkable_tiles", [])).has(DOOR) == effective_open, label + " walkable membership matches effective door")
	var direct_path: Array = PATHFINDER_SCRIPT.new().find_path(Vector2i.ZERO, TARGET, registry)
	_check(direct_path.size() == (17 if effective_open else 0), label + " direct A* confirms corridor reachability")
	var result: Dictionary = HPA_SCRIPT.new().find_path_with_status(Vector2i.ZERO, TARGET, registry, graph)
	var path: Array = Array(result.get("path", []))
	_check(path.size() == (17 if effective_open else 0), label + " HPA matches corridor reachability")
	if effective_open:
		var legal: bool = not path.is_empty() and Vector2i(path[0]) == Vector2i.ZERO and Vector2i(path[-1]) == TARGET
		for index in range(path.size()):
			legal = legal and registry.is_walkable(Vector2i(path[index]))
			if index > 0:
				legal = legal and Vector2i(path[index]) - Vector2i(path[index - 1]) == Vector2i(1, 0)
		_check(legal, label + " crosses open door with legal corridor steps")


func _check_simulation_endpoint(simulation, registry, effective_open: bool, label: String) -> void:
	var path: Array = simulation.call("_build_path_world_points", registry.grid_to_world(Vector2i.ZERO), registry.grid_to_world(TARGET), registry)
	var expected_grid: Vector2i = TARGET if effective_open else Vector2i(7, 0)
	_check(not path.is_empty() and registry.world_to_grid(Vector2(path[-1])) == expected_grid, label + " SimulationRoot endpoint is %s" % str(expected_grid))


func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + label)
	else:
		_failed += 1
		print("FAIL: " + label)
