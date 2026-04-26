extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_127 HPA Pathfinder Integration Verifier ===")
	_test_same_cluster_uses_local_path()
	_test_multi_cluster_path_uses_portals()
	_test_disconnected_components_fail_early()
	_test_simulation_root_executes_hpa_path()
	_test_simulation_root_simplifies_collinear_hpa_path()
	_test_simulation_root_unreachable_target_uses_local_fallback()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_same_cluster_uses_local_path() -> void:
	var registry = _make_registry(_make_rect_positions(Vector2i(0, 0), Vector2i(3, 3)), {})
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 8)
	var pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var result: Dictionary = Dictionary(pathfinder.call("find_path_with_status", Vector2i(0, 0), Vector2i(3, 3), registry, graph))
	var path: Array = Array(result.get("path", []))
	_assert(String(result.get("status", "")) == HPA_PATHFINDER_SCRIPT.STATUS_SAME_COMPONENT, "Same-cluster path uses local path status")
	_assert(not path.is_empty() and Vector2i(path[0]) == Vector2i(0, 0) and Vector2i(path[-1]) == Vector2i(3, 3), "Same-cluster HPA path preserves start and target")
	registry.free()


func _test_multi_cluster_path_uses_portals() -> void:
	var registry = _make_registry(_make_rect_positions(Vector2i(0, 0), Vector2i(5, 1)), {})
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 2)
	var pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var result: Dictionary = Dictionary(pathfinder.call("find_path_with_status", Vector2i(0, 0), Vector2i(5, 1), registry, graph))
	var path: Array = Array(result.get("path", []))
	_assert(String(result.get("status", "")) == HPA_PATHFINDER_SCRIPT.STATUS_HPA, "Multi-cluster path uses HPA status")
	_assert(_path_starts_and_ends(path, Vector2i(0, 0), Vector2i(5, 1)), "Multi-cluster HPA path preserves start and target")
	_assert(_path_steps_are_traversable(path, registry), "Multi-cluster HPA path uses traversable grid steps")
	registry.free()


func _test_disconnected_components_fail_early() -> void:
	var registry = _make_registry([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], {Vector2i(1, 0): false})
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 1)
	var pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var result: Dictionary = Dictionary(pathfinder.call("find_path_with_status", Vector2i(0, 0), Vector2i(2, 0), registry, graph))
	_assert(String(result.get("status", "")) == HPA_PATHFINDER_SCRIPT.STATUS_NO_ABSTRACT_ROUTE, "Disconnected HPA components fail before a global fallback search")
	_assert(Array(result.get("path", [])).is_empty(), "Disconnected HPA query returns no direct path")
	registry.free()


func _test_simulation_root_executes_hpa_path() -> void:
	var context: Dictionary = _make_simulation_context(_make_rect_positions(Vector2i(0, 0), Vector2i(9, 1)), {}, Vector2i(0, 0))
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(9, 1))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	_assert(not path.is_empty() and registry.call("world_to_grid", Vector2(path[-1])) == Vector2i(9, 1), "SimulationRoot builds a multi-cluster HPA-compatible world path")
	simulation_root.call("enqueue_command", _build_move_command(unit.get_unit_id(), target_position))
	for _tick in range(80):
		simulation_root.call("_physics_process", 0.1)
		if unit.global_position.distance_to(target_position) <= 1.0:
			break
	_assert(unit.global_position.distance_to(target_position) <= 1.0, "SimulationRoot executes the HPA path to the target")
	_cleanup_context(context)


func _test_simulation_root_simplifies_collinear_hpa_path() -> void:
	var context: Dictionary = _make_simulation_context(_make_rect_positions(Vector2i(0, 0), Vector2i(9, 0)), {}, Vector2i(0, 0))
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(9, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	_assert(path.size() <= 2 and not path.is_empty() and registry.call("world_to_grid", Vector2(path[-1])) == Vector2i(9, 0), "SimulationRoot simplifies straight HPA path segments")
	_cleanup_context(context)


func _test_simulation_root_unreachable_target_uses_local_fallback() -> void:
	var context: Dictionary = _make_simulation_context([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], {Vector2i(1, 0): false}, Vector2i(0, 0))
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	_assert(not path.is_empty() and registry.call("world_to_grid", Vector2(path[-1])) == Vector2i(0, 0), "SimulationRoot uses a local HPA fallback for unreachable components")
	_cleanup_context(context)


func _make_simulation_context(grid_positions: Array, blocked_by_grid: Dictionary, unit_grid: Vector2i) -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = _make_registry(grid_positions, blocked_by_grid)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = "hpa_test_unit"
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = terrain_registry.grid_to_world(unit_grid)
	scene.add_child(unit)
	unit_registry.register_unit(unit.get_unit_id(), unit)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"unit": unit,
	}


func _make_rect_positions(min_grid: Vector2i, max_grid: Vector2i) -> Array:
	var result: Array = []
	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			result.append(Vector2i(x, y))
	return result


func _make_registry(grid_positions: Array, blocked_by_grid: Dictionary):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for grid_variant in grid_positions:
		var grid_position: Vector2i = Vector2i(grid_variant)
		var walkable: bool = bool(blocked_by_grid.get(grid_position, true))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": "ground_flat" if walkable else "rock_large",
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": walkable,
			"surface_type": "ground" if walkable else "rock",
		}))
	return registry


func _build_move_command(unit_id: String, target_position: Vector2) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
	}


func _path_starts_and_ends(path: Array, start_grid: Vector2i, target_grid: Vector2i) -> bool:
	return not path.is_empty() and Vector2i(path[0]) == start_grid and Vector2i(path[-1]) == target_grid


func _path_steps_are_traversable(path: Array, registry) -> bool:
	for index in range(1, path.size()):
		if not bool(_terrain_pathfinder.call("can_traverse_step", Vector2i(path[index - 1]), Vector2i(path[index]), registry)):
			return false
	return true


func _cleanup_context(context: Dictionary) -> void:
	var scene = context.get("scene", null)
	if scene != null:
		scene.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
