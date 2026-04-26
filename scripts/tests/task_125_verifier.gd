extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_125 Terrain Blocker Debug + Walkability Verifier ===")
	_test_non_walkable_rock_target_resolves_stably()
	_test_open_terrain_uses_diagonal_path_steps()
	_test_diagonal_path_does_not_cut_blocked_corners()
	_test_path_around_rock_does_not_step_through_blocker()
	_test_unreachable_walkable_target_does_not_fall_back_to_direct_line()
	await _test_tactical_controller_exposes_terrain_move_debug_text()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_non_walkable_rock_target_resolves_stably() -> void:
	var registry = _make_registry([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], {Vector2i(1, 0): false})
	var rock_world: Vector2 = registry.grid_to_world(Vector2i(1, 0))
	var first: Dictionary = Dictionary(registry.call("resolve_walkable_target", rock_world))
	var second: Dictionary = Dictionary(registry.call("resolve_walkable_target", rock_world))
	_assert(not bool(first.get("target_walkable", true)), "Rock target is reported as non-walkable")
	_assert(String(first.get("blocker_reason", "")) == "target_not_walkable", "Rock target debug names the blocker reason")
	_assert(first.get("replacement_grid", null) == second.get("replacement_grid", null), "Rock replacement target is stable across repeated resolution")
	_assert(typeof(first.get("replacement_grid", null)) == TYPE_VECTOR2I and bool(registry.call("is_walkable", first.get("replacement_grid"))), "Rock target replacement points to a walkable grid")
	registry.free()


func _test_open_terrain_uses_diagonal_path_steps() -> void:
	var context: Dictionary = _make_simulation_context(
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
			Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
		],
		{},
		Vector2i(0, 0)
	)
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 2))
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", _build_move_command(unit.get_unit_id(), target_position), unit, unit.global_position, target_position, registry)
	var path_grids: Array = _world_path_to_grids(path, registry)
	_assert(path_grids.size() <= 2 and path_grids.has(Vector2i(1, 1)) and path_grids.has(Vector2i(2, 2)), "Open terrain path uses diagonal steps instead of axis-first doglegs")
	_cleanup_context(context)


func _test_diagonal_path_does_not_cut_blocked_corners() -> void:
	var registry = _make_registry(
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
		{Vector2i(1, 0): false}
	)
	var pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
	var path: Array = pathfinder.call("find_path", Vector2i(0, 0), Vector2i(1, 1), registry)
	var cuts_blocked_corner: bool = path.size() == 2 and Vector2i(path[0]) == Vector2i(0, 0) and Vector2i(path[1]) == Vector2i(1, 1)
	_assert(not cuts_blocked_corner and path.has(Vector2i(0, 1)), "Diagonal pathing routes around blocked tile corners instead of cutting through them")
	registry.free()


func _test_path_around_rock_does_not_step_through_blocker() -> void:
	var context: Dictionary = _make_simulation_context(
		[
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
			Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
		],
		{Vector2i(1, 0): false},
		Vector2i(0, 0)
	)
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	_assert(not path.is_empty(), "Pathfinder returns a path around a rock blocker")
	for waypoint_variant in path:
		var waypoint_grid: Vector2i = registry.call("world_to_grid", Vector2(waypoint_variant))
		_assert(waypoint_grid != Vector2i(1, 0), "Path waypoint never targets the rock blocker")
	simulation_root.call("enqueue_command", _build_move_command(unit.get_unit_id(), target_position))
	for _tick in range(40):
		simulation_root.call("_physics_process", 0.1)
		var current_grid: Vector2i = registry.call("world_to_grid", unit.global_position)
		_assert(current_grid != Vector2i(1, 0), "Unit movement never enters the rock blocker tile")
		if unit.global_position.distance_to(target_position) <= 1.0:
			break
	_assert(unit.global_position.distance_to(target_position) <= 1.0, "Unit reaches a walkable target by moving around the blocker")
	_cleanup_context(context)


func _test_unreachable_walkable_target_does_not_fall_back_to_direct_line() -> void:
	var context: Dictionary = _make_simulation_context(
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
		{Vector2i(1, 0): false},
		Vector2i(0, 0)
	)
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = context["unit"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	simulation_root.call("set_terrain_move_debug_enabled", true)
	simulation_root.call("enqueue_command", _build_move_command(unit.get_unit_id(), target_position))
	for _tick in range(10):
		simulation_root.call("_physics_process", 0.1)
		var current_grid: Vector2i = registry.call("world_to_grid", unit.global_position)
		_assert(current_grid != Vector2i(1, 0), "Unreachable movement never tunnels through a rock blocker")
	_assert(unit.global_position.distance_to(registry.grid_to_world(Vector2i(0, 0))) <= 1.0, "Unreachable target keeps the unit at a stable reachable fallback")
	var debug_snapshot: Dictionary = Dictionary(simulation_root.call("get_terrain_move_debug_snapshot", unit.get_unit_id()))
	_assert(String(debug_snapshot.get("blocker_reason", "")) == "no_reachable_path", "Terrain move debug reports no reachable path")
	_assert(Vector2i(debug_snapshot.get("final_waypoint_grid", Vector2i.ZERO)) == Vector2i(0, 0), "Terrain move debug exposes the stable fallback grid")
	_cleanup_context(context)


func _test_tactical_controller_exposes_terrain_move_debug_text() -> void:
	var scene = await _load_scene()
	var controller = scene.get_node("TacticalController")
	controller.call("set_terrain_move_debug_enabled", true)
	var simulation_root = scene.get_node("SimulationRoot")
	var terrain_registry = scene.get_node("TerrainRegistry")
	var units: Array = controller.call("_get_fireteam_units", "blue", true)
	var unit = units[0] if not units.is_empty() else null
	if unit == null:
		_assert(false, "Mission scene exposes a blue unit for terrain debug")
		scene.queue_free()
		await process_frame
		return
	var debug_target: Vector2 = terrain_registry.call("grid_to_world", Vector2i(1, 0))
	simulation_root.call("_extract_or_build_path_world_points", _build_move_command(unit.get_unit_id(), debug_target), unit, unit.global_position, debug_target, terrain_registry)
	var text: String = String(controller.call("build_terrain_move_debug_text", unit.get_unit_id()))
	_assert(text.contains("MOVE DEBUG"), "Tactical controller exposes a readable terrain debug line")
	_assert(text.contains("Ziel") and text.contains("Ersatz") and text.contains("Grund"), "Terrain debug line names original target, replacement and reason")
	scene.queue_free()
	await process_frame


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
	unit.unit_id = "terrain_debug_unit"
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


func _world_path_to_grids(path: Array, registry) -> Array:
	var result: Array = []
	for waypoint_variant in path:
		result.append(registry.call("world_to_grid", Vector2(waypoint_variant)))
	return result


func _load_scene() -> Node:
	var scene = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	root.add_child(scene)
	for _index in range(10):
		await process_frame
	return scene


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
