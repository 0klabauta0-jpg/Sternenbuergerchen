extends SceneTree

const SIMULATION_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== Review 2026-11-02 P2 fallback completion ===")
	for avoidance in [false, true]:
		_test_fallback_completes(avoidance, true)
		_test_fallback_completes(avoidance, false)
		_test_blocked_target_replacement_completes(avoidance)
		_test_reachable_move_reuses_its_path(avoidance)
		_test_pending_fallback_replans_after_terrain_change(avoidance)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_fallback_completes(avoidance: bool, stationary: bool) -> void:
	var context: Dictionary = _make_context(avoidance, 2 if stationary else 5, 1 if stationary else 3)
	var simulation = context["simulation"]
	var terrain = context["terrain"]
	var unit = context["unit"]
	var label := "avoidance=%s stationary=%s" % [avoidance, stationary]
	var expected_position: Vector2 = terrain.grid_to_world(Vector2i(0 if stationary else 2, 0))
	simulation.enqueue_command(_command(unit.unit_id, terrain.grid_to_world(Vector2i(2 if stationary else 5, 0))))
	var result: Dictionary = _run_until_idle(context)
	_assert(unit.global_position.is_equal_approx(expected_position), "%s reaches the hand-checked reachable fallback" % label)
	_assert(bool(result["walkable"]), "%s never enters the separating blocker" % label)
	_assert(simulation.command_queue.is_empty(), "%s drains its command at fallback arrival" % label)
	_assert(int(result["queries"]) == 2, "%s uses one failed primary query and one fallback query" % label)
	var idle_queries: int = _step(context, 8)
	_assert(idle_queries == 0 and unit.global_position.is_equal_approx(expected_position), "%s has no idle replans after terminal arrival" % label)
	context["scene"].free()


func _test_blocked_target_replacement_completes(avoidance: bool) -> void:
	var context: Dictionary = _make_context(avoidance, 3, 3)
	var simulation = context["simulation"]
	var terrain = context["terrain"]
	var unit = context["unit"]
	var target: Vector2 = terrain.grid_to_world(Vector2i(3, 0))
	simulation.enqueue_command(_command(unit.unit_id, target))
	var result: Dictionary = _run_until_idle(context)
	_assert(unit.global_position.is_equal_approx(terrain.grid_to_world(Vector2i(2, 0))) and bool(result["walkable"]), "avoidance=%s reaches the stable walkable replacement of a blocked target" % avoidance)
	_assert(simulation.command_queue.is_empty() and int(result["queries"]) == 1, "avoidance=%s completes the blocked-target route without an extra path query" % avoidance)
	_assert(_step(context, 8) == 0, "avoidance=%s blocked-target completion stays idle" % avoidance)
	context["scene"].free()


func _test_reachable_move_reuses_its_path(avoidance: bool) -> void:
	var context: Dictionary = _make_context(avoidance, 5, -1)
	var simulation = context["simulation"]
	var terrain = context["terrain"]
	var unit = context["unit"]
	var target: Vector2 = terrain.grid_to_world(Vector2i(5, 0))
	simulation.enqueue_command(_command(unit.unit_id, target))
	var first_queries: int = _step(context, 1)
	var first_position: Vector2 = unit.global_position
	_assert(first_queries == 1 and not first_position.is_zero_approx() and not simulation.command_queue.is_empty(), "avoidance=%s ordinary movement starts and remains pending" % avoidance)
	_assert(_step(context, 4) == 0 and unit.global_position.distance_to(target) < first_position.distance_to(target), "avoidance=%s ongoing movement reuses its full cached path" % avoidance)
	var result: Dictionary = _run_until_idle(context)
	_assert(unit.global_position.is_equal_approx(target) and simulation.command_queue.is_empty() and bool(result["walkable"]), "avoidance=%s ordinary movement reaches the original target and drains" % avoidance)
	_assert(int(result["queries"]) == 0 and _step(context, 4) == 0, "avoidance=%s cached ordinary route needs no additional query" % avoidance)
	context["scene"].free()


func _test_pending_fallback_replans_after_terrain_change(avoidance: bool) -> void:
	var context: Dictionary = _make_context(avoidance, 5, 3)
	var simulation = context["simulation"]
	var terrain = context["terrain"]
	var unit = context["unit"]
	var target: Vector2 = terrain.grid_to_world(Vector2i(5, 0))
	simulation.enqueue_command(_command(unit.unit_id, target))
	_assert(_step(context, 1) == 2 and not simulation.command_queue.is_empty(), "avoidance=%s terrain-change fixture is still approaching its fallback" % avoidance)
	_register_tile(terrain, 3, true)
	_assert(_step(context, 1) == 1 and not simulation.command_queue.is_empty(), "avoidance=%s actual terrain revision replans a still-pending fallback" % avoidance)
	var result: Dictionary = _run_until_idle(context)
	_assert(unit.global_position.is_equal_approx(target) and simulation.command_queue.is_empty() and bool(result["walkable"]), "avoidance=%s opened terrain lets the pending order reach its original target" % avoidance)
	_assert(int(result["queries"]) == 0 and _step(context, 4) == 0, "avoidance=%s replacement route is cached and completion stays idle" % avoidance)
	context["scene"].free()


func _make_context(avoidance: bool, last_x: int, blocked_x: int) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var registry = UNIT_REGISTRY_SCRIPT.new()
	registry.name = "Units"
	scene.add_child(registry)
	var terrain = TERRAIN_REGISTRY_SCRIPT.new()
	terrain.name = "Terrain"
	terrain.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(last_x + 1):
		_register_tile(terrain, x, x != blocked_x)
	scene.add_child(terrain)
	var simulation = SIMULATION_SCRIPT.new()
	simulation.unit_registry_path = NodePath("../Units")
	simulation.terrain_registry_path = NodePath("../Terrain")
	simulation.unit_minimum_spacing_enabled = false
	simulation.local_avoidance_enabled = avoidance
	scene.add_child(simulation)
	simulation.set_physics_process(false)
	var unit = UNIT_SCRIPT.new()
	unit.unit_id = "fallback_unit"
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	scene.add_child(unit)
	unit.set_process(false)
	unit.global_position = terrain.grid_to_world(Vector2i.ZERO)
	registry.register_unit(unit.unit_id, unit)
	return {"scene": scene, "simulation": simulation, "terrain": terrain, "unit": unit}


func _register_tile(terrain, x: int, walkable: bool) -> void:
	var grid := Vector2i(x, 0)
	terrain.register_tile(TILE_SCRIPT.new({
		"tile_id": "corridor_%d" % x,
		"type_id": "ground_flat",
		"grid_position": grid,
		"world_position": terrain.grid_to_world(grid),
		"walkable": walkable,
	}))


func _command(unit_id: String, target: Vector2) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
		"command_token": "fallback_order",
	}


func _step(context: Dictionary, ticks: int) -> int:
	var queries: int = 0
	for tick in range(ticks):
		context["simulation"]._physics_process(0.1)
		queries += int(context["simulation"].get_navigation_debug_snapshot().get("path_queries_this_tick", 0))
	return queries


func _run_until_idle(context: Dictionary) -> Dictionary:
	var queries: int = 0
	var walkable: bool = true
	for tick in range(120):
		queries += _step(context, 1)
		walkable = walkable and context["terrain"].is_walkable(context["terrain"].world_to_grid(context["unit"].global_position))
		if context["simulation"].command_queue.is_empty():
			break
	return {"queries": queries, "walkable": walkable}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)
