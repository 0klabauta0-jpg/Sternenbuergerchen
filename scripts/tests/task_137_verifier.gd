extends SceneTree

const HPA_NAVIGATION_GRAPH_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/hpa_pathfinder.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")

var _passed: int = 0
var _failed: int = 0
var _terrain_pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_137 2.5D Height-Aware Navigation Verifier ===")
	_test_same_height_path_remains_stable()
	_test_unmarked_height_jump_is_blocked()
	_test_ramp_transition_is_used_with_extra_cost()
	_test_stairs_transition_is_allowed()
	_test_large_step_is_blocked_even_with_transition()
	_test_hpa_uses_same_height_transition_rules()
	_test_simulation_root_routes_via_transition()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_same_height_path_remains_stable() -> void:
	var registry = _make_registry([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 0.0},
		{"grid": Vector2i(2, 0), "height": 0.0},
		{"grid": Vector2i(3, 0), "height": 0.0},
	])
	var path: Array = _terrain_pathfinder.call("find_path", Vector2i(0, 0), Vector2i(3, 0), registry)
	var snapshot: Dictionary = Dictionary(_terrain_pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 0), Vector2i(1, 0), registry))
	_assert(not path.is_empty() and Vector2i(path[0]) == Vector2i(0, 0) and Vector2i(path[-1]) == Vector2i(3, 0), "Same-height path still resolves")
	_assert(bool(snapshot.get("traversable", false)) and String(snapshot.get("reason", "")) == "same_height", "Same-height step snapshot stays explicit")
	registry.free()


func _test_unmarked_height_jump_is_blocked() -> void:
	var registry = _make_registry([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 1.0},
	])
	var snapshot: Dictionary = Dictionary(_terrain_pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 0), Vector2i(1, 0), registry))
	var path: Array = _terrain_pathfinder.call("find_path", Vector2i(0, 0), Vector2i(1, 0), registry)
	_assert(not bool(_terrain_pathfinder.call("can_traverse_step", Vector2i(0, 0), Vector2i(1, 0), registry)), "Unmarked one-level height jump is blocked")
	_assert(String(snapshot.get("reason", "")) == "height_transition_missing", "Blocked jump reports missing transition")
	_assert(path.is_empty(), "Direct path cannot cross unmarked height jump")
	registry.free()


func _test_ramp_transition_is_used_with_extra_cost() -> void:
	var registry = _make_registry([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 1.0, "transition": "ramp"},
		{"grid": Vector2i(2, 0), "height": 1.0},
	])
	var path: Array = _terrain_pathfinder.call("find_path", Vector2i(0, 0), Vector2i(2, 0), registry)
	var snapshot: Dictionary = Dictionary(_terrain_pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 0), Vector2i(1, 0), registry))
	var flat_cost: float = float(_terrain_pathfinder.call("get_step_cost", Vector2i(1, 0), Vector2i(2, 0), registry))
	var ramp_cost: float = float(_terrain_pathfinder.call("get_step_cost", Vector2i(0, 0), Vector2i(1, 0), registry))
	_assert(_path_has_grid(path, Vector2i(1, 0)) and Vector2i(path[-1]) == Vector2i(2, 0), "Ramp transition is used in path")
	_assert(bool(snapshot.get("traversable", false)) and String(snapshot.get("reason", "")) == "height_transition_ramp", "Ramp step reports transition type")
	_assert(ramp_cost > flat_cost, "Ramp transition costs more than flat movement")
	registry.free()


func _test_stairs_transition_is_allowed() -> void:
	var registry = _make_registry([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 1.0, "transition": "stairs"},
	])
	var snapshot: Dictionary = Dictionary(_terrain_pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 0), Vector2i(1, 0), registry))
	_assert(bool(snapshot.get("traversable", false)), "Stairs transition allows a one-level height step")
	_assert(String(snapshot.get("height_transition_type", "")) == "stairs", "Stairs transition appears in debug snapshot")
	registry.free()


func _test_large_step_is_blocked_even_with_transition() -> void:
	var registry = _make_registry([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 2.0, "transition": "ramp"},
	])
	var snapshot: Dictionary = Dictionary(_terrain_pathfinder.call("get_step_traversal_snapshot", Vector2i(0, 0), Vector2i(1, 0), registry))
	_assert(not bool(snapshot.get("traversable", true)), "Large height step is blocked even when marked as ramp")
	_assert(String(snapshot.get("reason", "")) == "height_step_too_large", "Large height step reports explicit debug reason")
	registry.free()


func _test_hpa_uses_same_height_transition_rules() -> void:
	var registry = _make_registry([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 1.0},
		{"grid": Vector2i(0, 1), "height": 0.0},
		{"grid": Vector2i(1, 1), "height": 1.0, "transition": "ramp"},
		{"grid": Vector2i(2, 1), "height": 1.0},
	])
	var graph = HPA_NAVIGATION_GRAPH_SCRIPT.new()
	graph.call("build_from_registry", registry, 1)
	var portals: Array = Array(graph.call("get_portals_snapshot"))
	var pathfinder = HPA_PATHFINDER_SCRIPT.new()
	var query: Dictionary = Dictionary(pathfinder.call("find_path_with_status", Vector2i(0, 1), Vector2i(2, 1), registry, graph))
	var blocked_portal_present: bool = _portals_have_step(portals, Vector2i(0, 0), Vector2i(1, 0))
	var ramp_portal_present: bool = _portals_have_step(portals, Vector2i(0, 1), Vector2i(1, 1))
	var path: Array = Array(query.get("path", []))
	_assert(not blocked_portal_present, "HPA does not create a portal across an unmarked height jump")
	_assert(ramp_portal_present, "HPA creates a portal for a marked ramp transition")
	_assert(String(query.get("status", "")) == HPA_PATHFINDER_SCRIPT.STATUS_HPA and _path_has_grid(path, Vector2i(1, 1)), "HPA path uses marked ramp transition")
	registry.free()


func _test_simulation_root_routes_via_transition() -> void:
	var context: Dictionary = _make_simulation_context([
		{"grid": Vector2i(0, 0), "height": 0.0},
		{"grid": Vector2i(1, 0), "height": 1.0},
		{"grid": Vector2i(2, 0), "height": 1.0},
		{"grid": Vector2i(0, 1), "height": 0.0},
		{"grid": Vector2i(1, 1), "height": 1.0, "transition": "ramp"},
		{"grid": Vector2i(2, 1), "height": 1.0},
	], Vector2i(0, 0))
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var path_grids: Array = _world_path_to_grids(path, registry)
	_assert(_path_has_grid(path_grids, Vector2i(1, 1)), "SimulationRoot routes through ramp instead of direct height jump")
	_assert(_world_path_steps_are_traversable(path, unit.global_position, registry), "SimulationRoot world path only contains traversable height-aware steps")
	_cleanup_context(context)


func _make_simulation_context(tile_specs: Array, unit_grid: Vector2i) -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = _make_registry(tile_specs)
	terrain_registry.name = "TerrainRegistry"
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	scene.add_child(simulation_root)
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = "height_nav_unit"
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


func _make_registry(tile_specs: Array):
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for spec_variant in tile_specs:
		var spec: Dictionary = Dictionary(spec_variant)
		var grid_position: Vector2i = Vector2i(spec.get("grid", Vector2i.ZERO))
		var height: float = float(spec.get("height", 0.0))
		registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
			"tile_id": "%d_%d" % [grid_position.x, grid_position.y],
			"type_id": "ground_flat",
			"grid_position": grid_position,
			"world_position": registry.grid_to_world(grid_position),
			"walkable": bool(spec.get("walkable", true)),
			"height_level": int(roundf(height)),
			"floor_height": height,
			"is_elevated_surface": height > 0.0,
			"surface_type": "ground",
			"edge_type": String(spec.get("edge_type", "cliff")),
			"height_transition_type": String(spec.get("transition", "")),
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


func _path_has_grid(path: Array, expected_grid: Vector2i) -> bool:
	for grid_variant in path:
		if Vector2i(grid_variant) == expected_grid:
			return true
	return false


func _portals_have_step(portals: Array, a_grid: Vector2i, b_grid: Vector2i) -> bool:
	for portal_variant in portals:
		var portal: Dictionary = Dictionary(portal_variant)
		var from_grid: Vector2i = Vector2i(portal.get("from_grid", Vector2i.ZERO))
		var to_grid: Vector2i = Vector2i(portal.get("to_grid", Vector2i.ZERO))
		if (from_grid == a_grid and to_grid == b_grid) or (from_grid == b_grid and to_grid == a_grid):
			return true
	return false


func _world_path_to_grids(path: Array, registry) -> Array:
	var result: Array = []
	for point_variant in path:
		result.append(registry.call("world_to_grid", Vector2(point_variant)))
	return result


func _world_path_steps_are_traversable(path: Array, start_position: Vector2, registry) -> bool:
	var previous_grid: Vector2i = registry.call("world_to_grid", start_position)
	for point_variant in path:
		var next_grid: Vector2i = registry.call("world_to_grid", Vector2(point_variant))
		if previous_grid == next_grid:
			continue
		if not bool(_terrain_pathfinder.call("can_traverse_step", previous_grid, next_grid, registry)):
			return false
		previous_grid = next_grid
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
