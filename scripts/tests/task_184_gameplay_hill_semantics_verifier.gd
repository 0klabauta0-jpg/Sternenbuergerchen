extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const LINE_OF_SIGHT_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_184 Gameplay Hill Semantics Verifier ===")
	_test_slope_cliff_and_surface_step_costs()
	_test_a_star_and_hpa_share_hill_blockades()
	_test_diagonal_movement_does_not_cut_hard_corners()
	_test_los_uses_effective_blocker_height()
	_test_combat_uses_terrain_height_and_tile_cover()
	_test_fallbacks_without_terrain_registry_stay_usable()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_slope_cliff_and_surface_step_costs() -> void:
	var registry = _make_registry([
		_tile_spec(Vector2i(0, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 0), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(2, 0), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(0, 1), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(0, 2), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 1), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_SLOPE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_SAND),
	])
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var ground_slope_cost: float = float(pathfinder.call("get_step_cost", Vector2i(0, 0), Vector2i(1, 0), registry))
	var flat_ground_cost: float = float(pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, 0), registry))
	var sand_slope_cost: float = float(pathfinder.call("get_step_cost", Vector2i(0, 0), Vector2i(1, 1), registry))
	var cliff_cost: float = float(pathfinder.call("get_step_cost", Vector2i(0, 0), Vector2i(0, 1), registry))
	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(1, 0), registry)), "Slope allows height transition up")
	_assert(bool(pathfinder.call("can_traverse_step", Vector2i(1, 0), Vector2i(0, 0), registry)), "Slope allows height transition down")
	_assert(ground_slope_cost > flat_ground_cost, "Slope path costs more than flat ground")
	_assert(sand_slope_cost > ground_slope_cost, "Sand slope costs more than ground slope")
	_assert(float(registry.call("get_surface_speed_factor_at_world", registry.call("grid_to_world", Vector2i(1, 1)))) < 1.0, "Sand height tile keeps slower surface speed")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(0, 1), registry)), "Cliff blocks height transition")
	_assert(is_inf(cliff_cost), "Blocked cliff step reports infinite path cost")
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(0, 2), registry)), "Edge none does not become a free height transition")
	registry.free()


func _test_a_star_and_hpa_share_hill_blockades() -> void:
	var registry = _make_registry(_make_rect_specs(Vector2i(0, 0), Vector2i(3, 1), {
		Vector2i(1, 0): _tile_override(1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, true),
	}))
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var a_star_path: Array = pathfinder.call("find_path", Vector2i(0, 0), Vector2i(3, 0), registry)
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	var graph_built: bool = bool(graph.call("build_from_registry", registry, 2))
	var hpa_pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var hpa_query: Dictionary = Dictionary(hpa_pathfinder.call("find_path_with_status", Vector2i(0, 0), Vector2i(3, 0), registry, graph, {}))
	var hpa_path: Array = Array(hpa_query.get("path", []))
	_assert(graph_built, "HPA graph builds for hill blockade map")
	_assert(not a_star_path.is_empty(), "A* finds route around cliff blockade")
	_assert(not hpa_path.is_empty(), "HPA finds route around cliff blockade")
	_assert(_path_is_valid(a_star_path, registry, pathfinder), "A* route uses only legal hill steps")
	_assert(_path_is_valid(hpa_path, registry, pathfinder), "HPA route uses only legal hill steps")
	_assert(not _path_contains_step(a_star_path, Vector2i(0, 0), Vector2i(1, 0)), "A* does not step through direct cliff transition")
	_assert(not _path_contains_step(hpa_path, Vector2i(0, 0), Vector2i(1, 0)), "HPA does not step through direct cliff transition")
	registry.free()

	var blocked_registry = _make_registry([
		_tile_spec(Vector2i(0, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 0), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
	])
	var blocked_graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	blocked_graph.call("build_from_registry", blocked_registry, 4)
	var blocked_a_star: Array = pathfinder.call("find_path", Vector2i(0, 0), Vector2i(1, 0), blocked_registry)
	var blocked_hpa_query: Dictionary = Dictionary(hpa_pathfinder.call("find_path_with_status", Vector2i(0, 0), Vector2i(1, 0), blocked_registry, blocked_graph, {}))
	_assert(blocked_a_star.is_empty(), "A* reports no path across isolated cliff height transition")
	_assert(Array(blocked_hpa_query.get("path", [])).is_empty(), "HPA reports no path across isolated cliff height transition")
	blocked_registry.free()


func _test_diagonal_movement_does_not_cut_hard_corners() -> void:
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var cliff_corner_registry = _make_registry([
		_tile_spec(Vector2i(0, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 0), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_CLIFF, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(0, 1), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 1), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
	])
	var cliff_corner_path: Array = pathfinder.call("find_path", Vector2i(0, 0), Vector2i(1, 1), cliff_corner_registry)
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(1, 1), cliff_corner_registry)), "Diagonal step cannot cut a cliff-blocked orthogonal corner")
	_assert(not _is_direct_diagonal_path(cliff_corner_path, Vector2i(0, 0), Vector2i(1, 1)), "A* routes around cliff corner instead of direct diagonal")
	cliff_corner_registry.free()

	var wall_corner_registry = _make_registry([
		_tile_spec(Vector2i(0, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, false),
		_tile_spec(Vector2i(0, 1), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 1), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
	])
	var wall_corner_path: Array = pathfinder.call("find_path", Vector2i(0, 0), Vector2i(1, 1), wall_corner_registry)
	_assert(not bool(pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(1, 1), wall_corner_registry)), "Diagonal step cannot cut a wall-blocked orthogonal corner")
	_assert(not _is_direct_diagonal_path(wall_corner_path, Vector2i(0, 0), Vector2i(1, 1)), "A* routes around wall corner instead of direct diagonal")
	wall_corner_registry.free()


func _test_los_uses_effective_blocker_height() -> void:
	var los_system = LINE_OF_SIGHT_SCRIPT.new()
	var blocking_registry = _make_registry([
		_tile_spec(Vector2i(0, 0), 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 0), 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, true, true, 0, 1),
		_tile_spec(Vector2i(2, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
	])
	_assert(not bool(los_system.call(
		"has_line_of_sight_with_terrain",
		blocking_registry.call("grid_to_world", Vector2i(0, 0)),
		blocking_registry.call("grid_to_world", Vector2i(2, 0)),
		blocking_registry,
		1000.0
	)), "Wall on H=2 blocks LOS with height_level plus object_height")
	blocking_registry.free()

	var overlook_registry = _make_registry([
		_tile_spec(Vector2i(0, 0), 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
		_tile_spec(Vector2i(1, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, true, true, 0, 1),
		_tile_spec(Vector2i(2, 0), 2, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND),
	])
	_assert(bool(los_system.call(
		"has_line_of_sight_with_terrain",
		overlook_registry.call("grid_to_world", Vector2i(0, 0)),
		overlook_registry.call("grid_to_world", Vector2i(2, 0)),
		overlook_registry,
		1000.0
	)), "Higher units can see over lower object blockers")
	overlook_registry.free()


func _test_combat_uses_terrain_height_and_tile_cover() -> void:
	var context: Dictionary = _make_simulation_context([
		_tile_spec(Vector2i(0, 0), 1, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, true, false, 0, 3),
		_tile_spec(Vector2i(1, 0), 0, TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE, TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND, true, false, 30, 3),
	])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var attacker := Node2D.new()
	var target := Node2D.new()
	attacker.global_position = registry.call("grid_to_world", Vector2i(0, 0))
	target.global_position = registry.call("grid_to_world", Vector2i(1, 0))
	context["scene"].add_child(attacker)
	context["scene"].add_child(target)
	_assert(is_equal_approx(float(simulation_root.call("_extract_height_accuracy_modifier", attacker, target)), 0.1), "Combat height bonus reads terrain height, not object height")
	_assert(is_equal_approx(float(simulation_root.call("_extract_height_accuracy_modifier", target, attacker)), -0.05), "Combat height penalty mirrors terrain height difference")
	_assert(is_equal_approx(float(simulation_root.call("_extract_effective_cover_score", target)), 30.0), "Combat cover reads tile cover from TerrainRegistry")
	_cleanup_context(context)


func _test_fallbacks_without_terrain_registry_stay_usable() -> void:
	var los_system = LINE_OF_SIGHT_SCRIPT.new()
	_assert(bool(los_system.call("has_line_of_sight_between_points", Vector2.ZERO, Vector2(96.0, 0.0), 320.0, null)), "LOS fallback without TerrainRegistry stays distance-based")

	var scene := Node.new()
	root.add_child(scene)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	scene.add_child(simulation_root)
	var attacker := Node2D.new()
	var target := Node2D.new()
	scene.add_child(attacker)
	scene.add_child(target)
	_assert(is_equal_approx(float(simulation_root.call("_extract_height_accuracy_modifier", attacker, target)), 0.0), "Combat height fallback without TerrainRegistry is neutral")
	_assert(is_equal_approx(float(simulation_root.call("_extract_effective_cover_score", target)), 0.0), "Combat cover fallback without TerrainRegistry is neutral")
	scene.queue_free()

	var movement_scene := Node.new()
	root.add_child(movement_scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	movement_scene.add_child(unit_registry)
	var movement_root = SIMULATION_ROOT_SCRIPT.new()
	movement_root.name = "SimulationRoot"
	movement_root.unit_registry_path = NodePath("../UnitRegistry")
	movement_scene.add_child(movement_root)
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = "task_184_fallback_unit"
	unit.team_id = "team_alpha"
	unit.global_position = Vector2.ZERO
	movement_scene.add_child(unit)
	unit_registry.call("register_unit", unit.get_unit_id(), unit)
	movement_root.call("enqueue_command", {
		"command_type": "move_to_position",
		"unit_id": unit.get_unit_id(),
		"team_id": "team_alpha",
		"target_position": Vector2(64.0, 0.0),
		"move_speed_factor": 1.0,
	})
	movement_root.call("_physics_process", 0.1)
	_assert(unit.global_position.x > 0.0, "Movement fallback without TerrainRegistry still advances directly")
	movement_scene.queue_free()


func _make_simulation_context(tile_specs: Array) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var terrain_registry = _make_registry(tile_specs)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	return {
		"scene": scene,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
	}


func _make_registry(tile_specs: Array):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for spec_variant in tile_specs:
		var spec: Dictionary = Dictionary(spec_variant)
		var grid_position: Vector2i = Vector2i(spec.get("grid_position", Vector2i.ZERO))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": String(spec.get("type_id", "ground_flat")),
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": bool(spec.get("walkable", true)),
			"blocks_los": bool(spec.get("blocks_los", false)),
			"cover_value": int(spec.get("cover_value", 0)),
			"height_level": int(spec.get("height_level", 0)),
			"object_height": int(spec.get("object_height", 0)),
			"surface_type": String(spec.get("surface_type", TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)),
			"edge_type": String(spec.get("edge_type", TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE)),
		}))
	return registry


func _make_rect_specs(min_grid: Vector2i, max_grid: Vector2i, overrides_by_grid: Dictionary = {}) -> Array:
	var result: Array = []
	for x in range(min_grid.x, max_grid.x + 1):
		for y in range(min_grid.y, max_grid.y + 1):
			var grid_position := Vector2i(x, y)
			var override: Dictionary = Dictionary(overrides_by_grid.get(grid_position, {}))
			result.append(_tile_spec(
				grid_position,
				int(override.get("height_level", 0)),
				String(override.get("edge_type", TERRAIN_TILE_DATA_SCRIPT.EDGE_NONE)),
				String(override.get("surface_type", TERRAIN_TILE_DATA_SCRIPT.SURFACE_GROUND)),
				bool(override.get("walkable", true)),
				bool(override.get("blocks_los", false)),
				int(override.get("cover_value", 0)),
				int(override.get("object_height", 0))
			))
	return result


func _tile_override(height_level: int, edge_type: String, surface_type: String, walkable: bool = true) -> Dictionary:
	return {
		"height_level": height_level,
		"edge_type": edge_type,
		"surface_type": surface_type,
		"walkable": walkable,
	}


func _tile_spec(
	grid_position: Vector2i,
	height_level: int,
	edge_type: String,
	surface_type: String,
	walkable: bool = true,
	blocks_los: bool = false,
	cover_value: int = 0,
	object_height: int = 0
) -> Dictionary:
	return {
		"grid_position": grid_position,
		"height_level": height_level,
		"edge_type": edge_type,
		"surface_type": surface_type,
		"walkable": walkable,
		"blocks_los": blocks_los,
		"cover_value": cover_value,
		"object_height": object_height,
		"type_id": "ground_flat" if walkable else "wall_blocker",
	}


func _path_is_valid(path: Array, registry, pathfinder) -> bool:
	if path.is_empty():
		return false
	for index in range(1, path.size()):
		if not bool(pathfinder.call("can_traverse_step", Vector2i(path[index - 1]), Vector2i(path[index]), registry)):
			return false
	return true


func _path_contains_step(path: Array, a_grid: Vector2i, b_grid: Vector2i) -> bool:
	for index in range(1, path.size()):
		var previous_grid: Vector2i = Vector2i(path[index - 1])
		var current_grid: Vector2i = Vector2i(path[index])
		if previous_grid == a_grid and current_grid == b_grid:
			return true
	return false


func _is_direct_diagonal_path(path: Array, a_grid: Vector2i, b_grid: Vector2i) -> bool:
	return path.size() == 2 and Vector2i(path[0]) == a_grid and Vector2i(path[1]) == b_grid


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
