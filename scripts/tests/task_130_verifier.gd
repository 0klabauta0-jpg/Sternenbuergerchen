extends SceneTree

const LOCAL_AVOIDANCE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/tactical/local_avoidance_resolver.gd")
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
	print("=== TASK_130 Local Avoidance ORCA/RVO-Light Verifier ===")
	_test_resolver_generates_deterministic_avoidance_velocity()
	_test_simulation_root_crossing_units_keep_more_distance()
	_test_avoidance_discards_non_walkable_correction()
	_test_deadlock_debug_marks_stuck_unit()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_resolver_generates_deterministic_avoidance_velocity() -> void:
	var scene = Node.new()
	root.add_child(scene)
	var alpha = _make_unit("alpha", Vector2.ZERO)
	var bravo = _make_unit("bravo", Vector2(24.0, 0.0))
	scene.add_child(alpha)
	scene.add_child(bravo)
	var resolver = LOCAL_AVOIDANCE_RESOLVER_SCRIPT.new()
	resolver.call("build_from_units", [alpha, bravo], 18.0, 64.0)
	var first_result: Dictionary = Dictionary(resolver.call("solve_velocity", "alpha", alpha.global_position, Vector2(80.0, 0.0), 80.0, 64.0, 8))
	var second_result: Dictionary = Dictionary(resolver.call("solve_velocity", "alpha", alpha.global_position, Vector2(80.0, 0.0), 80.0, 64.0, 8))
	var safe_velocity: Vector2 = Vector2(first_result.get("safe_velocity", Vector2.ZERO))
	_assert(int(first_result.get("neighbor_count", 0)) == 1, "Resolver finds nearby registered neighbor")
	_assert(safe_velocity.distance_to(Vector2(80.0, 0.0)) > 0.1, "Resolver clips desired velocity when another unit is too close")
	_assert(safe_velocity == Vector2(second_result.get("safe_velocity", Vector2.ZERO)), "Resolver result is deterministic for stable inputs")
	scene.queue_free()


func _test_simulation_root_crossing_units_keep_more_distance() -> void:
	var plain_context: Dictionary = _make_simulation_context(false, false)
	var avoid_context: Dictionary = _make_simulation_context(true, true)
	var plain_distance: float = _run_crossing_pair(plain_context)
	var avoid_distance: float = _run_crossing_pair(avoid_context)
	_assert(avoid_distance > plain_distance + 0.5, "Local avoidance keeps crossing units farther apart than plain movement")
	var snapshot: Dictionary = Dictionary(avoid_context["simulation_root"].call("get_local_avoidance_debug_snapshot", "alpha"))
	_assert(int(snapshot.get("neighbor_count", 0)) > 0 and snapshot.has("avoidance_velocity"), "Avoidance debug snapshot exposes neighbor count and safe velocity")
	_cleanup_context(plain_context)
	_cleanup_context(avoid_context)


func _test_avoidance_discards_non_walkable_correction() -> void:
	var context: Dictionary = _make_terrain_context()
	var simulation_root = context["simulation_root"]
	var registry = context["terrain_registry"]
	var alpha = context["alpha"]
	var target_position: Vector2 = registry.grid_to_world(Vector2i(2, 1))
	simulation_root.local_avoidance_enabled = true
	simulation_root.local_avoidance_debug_enabled = true
	simulation_root.local_avoidance_agent_radius = 80.0
	simulation_root.local_avoidance_neighbor_radius = 90.0
	var cmd: Dictionary = _build_move_command("alpha", target_position)
	simulation_root.call("_prepare_local_avoidance_tick")
	var safe_velocity: Vector2 = simulation_root.call("_resolve_local_avoidance_velocity", cmd, alpha, alpha.global_position, Vector2(0.0, -120.0), 120.0, 0.5, registry)
	alpha.global_position += safe_velocity * 0.5
	var alpha_grid: Vector2i = registry.world_to_grid(alpha.global_position)
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_local_avoidance_debug_snapshot", "alpha"))
	_assert(bool(registry.call("is_walkable", alpha_grid)), "Avoidance does not move a unit onto a non-walkable tile")
	_assert(bool(snapshot.get("discarded_correction", false)), "Avoidance debug marks a correction discarded by terrain safety")
	_cleanup_context(context)


func _test_deadlock_debug_marks_stuck_unit() -> void:
	var context: Dictionary = _make_terrain_context()
	var simulation_root = context["simulation_root"]
	var alpha = context["alpha"]
	simulation_root.local_avoidance_enabled = true
	simulation_root.local_avoidance_debug_enabled = true
	simulation_root.local_avoidance_agent_radius = 80.0
	simulation_root.local_avoidance_neighbor_radius = 90.0
	simulation_root.local_avoidance_stuck_threshold_seconds = 0.5
	simulation_root.local_avoidance_stuck_speed_threshold = 5.0
	var cmd: Dictionary = _build_move_command("alpha", Vector2(200.0, 0.0))
	for _index in range(2):
		simulation_root.call("_prepare_local_avoidance_tick")
		simulation_root.call("_resolve_local_avoidance_velocity", cmd, alpha, alpha.global_position, Vector2(0.0, -120.0), 120.0, 0.4, context["terrain_registry"])
	var snapshot: Dictionary = Dictionary(simulation_root.call("get_local_avoidance_debug_snapshot", "alpha"))
	_assert(float(snapshot.get("stuck_time_seconds", 0.0)) >= 0.5, "Avoidance debug accumulates stuck time for blocked local movement")
	_assert(bool(snapshot.get("deadlock_marked", false)) and bool(cmd.get("local_avoidance_repath_requested", false)), "Avoidance deadlock watcher marks the command for a later repath")
	_cleanup_context(context)


func _run_crossing_pair(context: Dictionary) -> float:
	var simulation_root = context["simulation_root"]
	simulation_root.call("enqueue_command", _build_move_command("alpha", Vector2(40.0, 0.0)))
	simulation_root.call("enqueue_command", _build_move_command("bravo", Vector2(-40.0, 0.0)))
	for _tick in range(2):
		simulation_root.call("_physics_process", 0.1)
	var alpha = context["alpha"]
	var bravo = context["bravo"]
	return alpha.global_position.distance_to(bravo.global_position)


func _make_simulation_context(enable_avoidance: bool, enable_debug: bool) -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.unit_minimum_spacing_enabled = false
	simulation_root.local_avoidance_enabled = enable_avoidance
	simulation_root.local_avoidance_debug_enabled = enable_debug
	simulation_root.local_avoidance_neighbor_radius = 72.0
	scene.add_child(simulation_root)
	var alpha = _make_unit("alpha", Vector2(-20.0, 0.0))
	var bravo = _make_unit("bravo", Vector2(20.0, 0.0))
	scene.add_child(alpha)
	scene.add_child(bravo)
	unit_registry.register_unit(alpha.get_unit_id(), alpha)
	unit_registry.register_unit(bravo.get_unit_id(), bravo)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
		"alpha": alpha,
		"bravo": bravo,
	}


func _make_terrain_context() -> Dictionary:
	var scene = Node.new()
	root.add_child(scene)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	scene.add_child(unit_registry)
	var terrain_registry = TERRAIN_REGISTRY_SCRIPT.new()
	terrain_registry.name = "TerrainRegistry"
	terrain_registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(0, 3):
		for y in range(0, 3):
			var grid := Vector2i(x, y)
			var walkable: bool = y == 1
			terrain_registry.register_tile(TERRAIN_TILE_DATA_SCRIPT.new({
				"tile_id": "%d_%d" % [grid.x, grid.y],
				"type_id": "ground_flat" if walkable else "rock_large",
				"grid_position": grid,
				"world_position": terrain_registry.grid_to_world(grid),
				"walkable": walkable,
				"surface_type": "ground" if walkable else "rock",
			}))
	scene.add_child(terrain_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	simulation_root.terrain_registry_path = NodePath("../TerrainRegistry")
	simulation_root.unit_minimum_spacing_enabled = false
	scene.add_child(simulation_root)
	var alpha = _make_unit("alpha", terrain_registry.grid_to_world(Vector2i(1, 1)))
	var bravo = _make_unit("bravo", terrain_registry.grid_to_world(Vector2i(1, 1)))
	scene.add_child(alpha)
	scene.add_child(bravo)
	unit_registry.register_unit(alpha.get_unit_id(), alpha)
	unit_registry.register_unit(bravo.get_unit_id(), bravo)
	return {
		"scene": scene,
		"unit_registry": unit_registry,
		"terrain_registry": terrain_registry,
		"simulation_root": simulation_root,
		"alpha": alpha,
		"bravo": bravo,
	}


func _make_unit(unit_id: String, position: Vector2):
	var unit = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = "team_alpha"
	unit.fireteam_id = "blue"
	unit.global_position = position
	return unit


func _build_move_command(unit_id: String, target_position: Vector2) -> Dictionary:
	return {
		"command_type": "move_to_position",
		"unit_id": unit_id,
		"team_id": "team_alpha",
		"target_position": target_position,
		"move_speed_factor": 1.0,
		"requeue_until_target": true,
	}


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
