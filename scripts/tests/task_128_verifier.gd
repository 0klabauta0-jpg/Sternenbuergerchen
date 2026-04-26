extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_128 Navigation Budgeting und Debug Verifier ===")
	_test_navigation_snapshot_counts_path_queries()
	_test_navigation_budget_delays_commands_deterministically()
	_test_contact_recompute_respects_budget()
	_test_unreachable_targets_are_marked_in_debug()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_navigation_snapshot_counts_path_queries() -> void:
	var context: Dictionary = _make_simulation_context(_make_rect_positions(Vector2i(0, 0), Vector2i(9, 1)), {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = _add_unit(context, "alpha", Vector2i(0, 0))
	simulation_root.call("set_navigation_debug_enabled", true)
	var target_position: Vector2 = registry.grid_to_world(Vector2i(9, 1))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var snapshot: Dictionary = simulation_root.call("get_navigation_debug_snapshot")
	_assert(not path.is_empty(), "SimulationRoot still builds a path while navigation debug is active")
	_assert(int(snapshot.get("new_path_queries_this_tick", 0)) == 1, "Navigation snapshot counts new path requests")
	_assert(int(snapshot.get("path_queries_this_tick", 0)) >= 1, "Navigation snapshot counts concrete pathfinder queries")
	_assert(_has_query_for_unit(Array(snapshot.get("last_queries", [])), "alpha"), "Navigation snapshot includes the querying unit id")
	_cleanup_context(context)


func _test_navigation_budget_delays_commands_deterministically() -> void:
	var context: Dictionary = _make_simulation_context(_make_rect_positions(Vector2i(0, 0), Vector2i(9, 3)), {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var alpha = _add_unit(context, "alpha", Vector2i(0, 0))
	var bravo = _add_unit(context, "bravo", Vector2i(0, 1))
	var charlie = _add_unit(context, "charlie", Vector2i(0, 2))
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_max_new_path_queries_per_tick", 1)
	simulation_root.call("enqueue_command", _build_move_command(alpha.get_unit_id(), registry.grid_to_world(Vector2i(9, 0)), 0))
	simulation_root.call("enqueue_command", _build_move_command(bravo.get_unit_id(), registry.grid_to_world(Vector2i(9, 1)), 10))
	simulation_root.call("enqueue_command", _build_move_command(charlie.get_unit_id(), registry.grid_to_world(Vector2i(9, 2)), 0))
	simulation_root.call("_physics_process", 0.1)
	var first_snapshot: Dictionary = simulation_root.call("get_navigation_debug_snapshot")
	_assert(int(first_snapshot.get("new_path_queries_this_tick", 0)) == 1, "Navigation budget allows only one new path request in the first tick")
	_assert(int(first_snapshot.get("pending_query_count", 0)) == 2, "Navigation budget leaves two pending path requests")
	_assert(_first_primary_query_unit(Array(first_snapshot.get("last_queries", []))) == "bravo", "Navigation budget preserves priority before enqueue order")
	simulation_root.call("_physics_process", 0.1)
	var second_snapshot: Dictionary = simulation_root.call("get_navigation_debug_snapshot")
	_assert(int(second_snapshot.get("new_path_queries_this_tick", 0)) == 1, "Second tick processes the next delayed path request")
	_assert(_first_primary_query_unit(Array(second_snapshot.get("last_queries", []))) == "alpha", "Delayed same-priority commands keep enqueue order")
	simulation_root.call("_physics_process", 0.1)
	var third_snapshot: Dictionary = simulation_root.call("get_navigation_debug_snapshot")
	_assert(_first_primary_query_unit(Array(third_snapshot.get("last_queries", []))) == "charlie", "Remaining delayed path request is processed deterministically")
	_cleanup_context(context)


func _test_contact_recompute_respects_budget() -> void:
	var context: Dictionary = _make_simulation_context(_make_rect_positions(Vector2i(0, 0), Vector2i(9, 2)), {}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var alpha = _add_unit(context, "contact_alpha", Vector2i(0, 0))
	var bravo = _add_unit(context, "contact_bravo", Vector2i(0, 1))
	alpha.call("set_contact_state", true, "enemy")
	bravo.call("set_contact_state", true, "enemy")
	simulation_root.call("set_navigation_debug_enabled", true)
	simulation_root.call("set_navigation_max_new_path_queries_per_tick", 1)
	var alpha_cmd: Dictionary = _build_move_command(alpha.get_unit_id(), registry.grid_to_world(Vector2i(9, 0)), 0)
	alpha_cmd["path"] = [registry.grid_to_world(Vector2i(1, 2))]
	var bravo_cmd: Dictionary = _build_move_command(bravo.get_unit_id(), registry.grid_to_world(Vector2i(9, 1)), 0)
	bravo_cmd["path"] = [registry.grid_to_world(Vector2i(1, 2))]
	simulation_root.call("enqueue_command", alpha_cmd)
	simulation_root.call("enqueue_command", bravo_cmd)
	simulation_root.call("_physics_process", 0.1)
	var snapshot: Dictionary = simulation_root.call("get_navigation_debug_snapshot")
	_assert(int(snapshot.get("new_path_queries_this_tick", 0)) == 1, "Contact recompute is limited by the navigation budget")
	_assert(int(snapshot.get("pending_query_count", 0)) == 1, "Contact recompute staggers remaining units into later ticks")
	_cleanup_context(context)


func _test_unreachable_targets_are_marked_in_debug() -> void:
	var context: Dictionary = _make_simulation_context([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], {Vector2i(1, 0): false}, [])
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var unit = _add_unit(context, "blocked_alpha", Vector2i(0, 0))
	simulation_root.call("set_navigation_debug_enabled", true)
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 0))
	var cmd: Dictionary = _build_move_command(unit.get_unit_id(), target_position)
	var path: Array = simulation_root.call("_extract_or_build_path_world_points", cmd, unit, unit.global_position, target_position, registry)
	var snapshot: Dictionary = simulation_root.call("get_navigation_debug_snapshot")
	_assert(not path.is_empty() and registry.call("world_to_grid", Vector2(path[-1])) == Vector2i(0, 0), "Unreachable path still uses the existing safe local fallback")
	_assert(int(snapshot.get("unreachable_queries_this_tick", 0)) >= 1, "Navigation debug marks unreachable query attempts")
	_assert(_has_unreachable_query(Array(snapshot.get("last_queries", []))), "Navigation debug snapshot exposes unreachable status per query")
	_cleanup_context(context)


func _make_simulation_context(grid_positions: Array, blocked_by_grid: Dictionary, units: Array) -> Dictionary:
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
	var context: Dictionary = {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"units": {},
	}
	for unit_config in units:
		_add_unit(context, String(unit_config.get("unit_id", "")), Vector2i(unit_config.get("grid", Vector2i.ZERO)))
	return context


func _add_unit(context: Dictionary, unit_id: String, unit_grid: Vector2i):
	var scene = context["scene"]
	var unit_registry = context["unit_registry"]
	var terrain_registry = context["terrain_registry"]
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = terrain_registry.grid_to_world(unit_grid)
	scene.add_child(unit)
	unit_registry.register_unit(unit.get_unit_id(), unit)
	Dictionary(context["units"])[unit_id] = unit
	return unit


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


func _build_move_command(unit_id: String, target_position: Vector2, priority: int = 0) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
		"priority": priority,
	}


func _has_query_for_unit(queries: Array, unit_id: String) -> bool:
	for query in queries:
		if typeof(query) == TYPE_DICTIONARY and String(Dictionary(query).get("unit_id", "")) == unit_id:
			return true
	return false


func _first_primary_query_unit(queries: Array) -> String:
	for query in queries:
		if typeof(query) != TYPE_DICTIONARY:
			continue
		var query_dict: Dictionary = query
		if String(query_dict.get("query_kind", "")) == "primary":
			return String(query_dict.get("unit_id", ""))
	return ""


func _has_unreachable_query(queries: Array) -> bool:
	for query in queries:
		if typeof(query) == TYPE_DICTIONARY and bool(Dictionary(query).get("unreachable", false)):
			return true
	return false


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
