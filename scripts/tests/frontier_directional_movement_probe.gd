extends SceneTree

## Synthetic diagnostic only. Exercises the existing authoritative movement
## integrator on fixture nodes; never changes production navigation or maps.

const MAP_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const SIMULATION_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")

const OUTPUT_PATH: String = "res://output/grafik_20261101/directional_movement_probe.json"
const STEP_DELTA: float = 1.0 / 60.0
const MAX_STEPS: int = 600
const START_GRID: Vector2i = Vector2i(3, 3)
const HALF_WIDTH: float = 64.0
const HALF_HEIGHT: float = 32.0
const CELL_SIZE_3D: float = 1.0

var _passed: int = 0
var _failed: int = 0
var _checks: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run_probe")


func _run_probe() -> void:
	print("=== Frontier Directional Movement Probe (SYNTHETIC) ===")
	var source_hashes_before: Dictionary = _source_hashes()
	var node_count_before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var fixture := Node.new()
	fixture.name = "SyntheticDirectionalMovementFixture"
	root.add_child(fixture)

	var registry = REGISTRY_SCRIPT.new()
	registry.name = "TerrainRegistry"
	fixture.add_child(registry)
	registry.call("configure_iso_grid", Vector2.ZERO, HALF_WIDTH, HALF_HEIGHT)
	var map_data = MAP_SCRIPT.call("create_empty", "synthetic_directional_8x8", Vector2i(8, 8), Vector2.ZERO, HALF_WIDTH, HALF_HEIGHT)
	for tile_data in Array(map_data.call("get_tiles")):
		registry.call("register_tile", tile_data)
	_check(Array(registry.call("get_all_tiles")).size() == 64, "Fixture registers 64 flat ground tiles")

	var simulation = SIMULATION_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.set("terrain_registry_path", NodePath("../TerrainRegistry"))
	simulation.set("unit_minimum_spacing_enabled", false)
	simulation.set("local_avoidance_enabled", false)
	simulation.set("bottleneck_reservation_enabled", false)
	simulation.set_process(false)
	simulation.set_physics_process(false)
	fixture.add_child(simulation)
	simulation.set_process(false)
	simulation.set_physics_process(false)
	_check(not simulation.is_physics_processing(), "Automatic physics tick is disabled; fixture advances explicit fixed deltas only")
	_check(not bool(simulation.get("unit_minimum_spacing_enabled")) and not bool(simulation.get("local_avoidance_enabled")), "Unit spacing and local avoidance are explicitly disabled in fixture")
	_check(simulation.call("_get_terrain_registry") == registry, "Movement integrator resolves the actual fixture TerrainRegistry")

	var pathfinder = PATHFINDER_SCRIPT.new()
	var trials: Array[Dictionary] = []
	trials.append(_measure("grid_positive_diagonal", Vector2i(5, 5), fixture, registry, pathfinder, simulation))
	trials.append(_measure("grid_mixed_diagonal", Vector2i(5, 1), fixture, registry, pathfinder, simulation))
	var first: Dictionary = trials[0]
	var second: Dictionary = trials[1]
	_check(is_equal_approx(float(first.get("path_cost", 0.0)), float(second.get("path_cost", 0.0))), "Actual pathfinder gives both two-diagonal routes equal cost")
	_check(is_equal_approx(float(first.get("visible_3d_ground_length", 0.0)), float(second.get("visible_3d_ground_length", 0.0))), "Routes have the same ground-plane length under existing square-cell 3D transform")
	_check(Array(simulation.get("command_queue")).is_empty() and Array(simulation.get("effects_queue")).is_empty(), "Private integrator probe enqueues no commands or effects")
	_check(int(simulation.get("tick_counter")) == 0, "No automatic SimulationRoot ticks or gameplay loop were run")

	fixture.free()
	map_data = null
	registry = null
	simulation = null
	var node_count_after: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_check(node_count_after == node_count_before, "All synthetic fixture Nodes are freed")
	var source_hashes_after: Dictionary = _source_hashes()
	_check(source_hashes_before == source_hashes_after, "Measured production source files remain byte-identical during probe")

	var time_first: float = float(first.get("simulated_seconds", 0.0))
	var time_second: float = float(second.get("simulated_seconds", 0.0))
	var result: Dictionary = {
		"schema": "sternenbuergerchen.synthetic_directional_movement_probe.v1",
		"created_at_utc": Time.get_datetime_string_from_system(true) + "Z",
		"synthetic_fixture": true,
		"diagnostic_only": true,
		"engine": Engine.get_version_info(),
		"fixture": {
			"map_size": [8, 8],
			"tiles": 64,
			"surface": "ground",
			"height_level": 0,
			"blockers": 0,
			"iso_half_width": HALF_WIDTH,
			"iso_half_height": HALF_HEIGHT,
			"visible_3d_cell_size": CELL_SIZE_3D,
			"fixed_delta_seconds": STEP_DELTA,
			"integrator": "SimulationRoot._apply_move_command_with_terrain",
			"invocation": "direct private method on isolated fixture Nodes with actual pathfinder world waypoints",
			"automatic_physics": false,
			"unit_spacing": false,
			"local_avoidance": false,
			"requeue_until_target": false,
			"node_class": "Node2D (no UI, combat, registry membership or unit speed modifier)",
			"production_renderer_instantiated": false,
			"visible_3d_length_definition": "sqrt(grid_delta.x^2 + grid_delta.y^2) * cell_size, matching TerrainMap3DView._grid_to_3d_position; no rendered capture",
		},
		"trials": trials,
		"observed": {
			"equal_path_cost": is_equal_approx(float(first.get("path_cost", 0.0)), float(second.get("path_cost", 0.0))),
			"equal_visible_3d_length": is_equal_approx(float(first.get("visible_3d_ground_length", 0.0)), float(second.get("visible_3d_ground_length", 0.0))),
			"mixed_over_positive_time_ratio": time_second / time_first if time_first > 0.0 else 0.0,
			"directional_time_difference_seconds": time_second - time_first,
			"interpretation": "Measured fixture result only. Passing probe validates the measurement, not directional fairness or release readiness.",
		},
		"source_sha256": source_hashes_before,
		"checks": _checks,
		"passed_checks": _passed,
		"failed_checks": _failed,
		"all_checks_pass": _failed == 0,
		"limits": [
			"Synthetic empty map and explicit path injection; not a normal command/RPC/end-to-end gameplay path.",
			"Simulated seconds are tick count times fixed delta, not wallclock performance or FPS.",
			"No combat, terrain height, cover, blockers, unit crowding, avoidance or multiplayer load.",
			"No navigation fix, no hex implementation, no production state mutation.",
		],
	}
	var output_file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	if output_file == null:
		print("FAIL: Could not write diagnostic JSON: %s" % OUTPUT_PATH)
		_failed += 1
	else:
		output_file.store_string(JSON.stringify(result, "\t") + "\n")
		output_file.close()
	print("OBSERVED: ticks=%d/%d simulated_seconds=%.6f/%.6f ratio=%.6f" % [int(first.get("ticks", 0)), int(second.get("ticks", 0)), time_first, time_second, time_second / time_first if time_first > 0.0 else 0.0])
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("FRONTIER_DIRECTIONAL_MOVEMENT_PROBE_ALL_PASS" if _failed == 0 else "FRONTIER_DIRECTIONAL_MOVEMENT_PROBE_FAILED")
	quit(0 if _failed == 0 else 1)


func _measure(label: String, target_grid: Vector2i, fixture: Node, registry, pathfinder, simulation) -> Dictionary:
	var unit := Node2D.new()
	unit.name = label
	fixture.add_child(unit)
	unit.global_position = Vector2(registry.call("grid_to_world", START_GRID))
	var start_world: Vector2 = unit.global_position
	var target_world: Vector2 = Vector2(registry.call("grid_to_world", target_grid))
	var grid_path: Array = Array(pathfinder.call("find_path", START_GRID, target_grid, registry))
	_check(grid_path.size() == 3 and Vector2i(grid_path[0]) == START_GRID and Vector2i(grid_path[-1]) == target_grid, "%s: actual A* returns two diagonal steps with correct endpoints" % label)
	var world_path: Array = []
	var serialized_grid_path: Array = []
	var projected_path_length: float = 0.0
	var previous_world: Vector2 = start_world
	for index in range(grid_path.size()):
		var grid: Vector2i = Vector2i(grid_path[index])
		serialized_grid_path.append([grid.x, grid.y])
		if index == 0:
			continue
		var waypoint: Vector2 = Vector2(registry.call("grid_to_world", grid))
		world_path.append(waypoint)
		projected_path_length += previous_world.distance_to(waypoint)
		previous_world = waypoint
	var score: Dictionary = Dictionary(pathfinder.call("score_path", grid_path, registry))
	var command: Dictionary = {
		"type": "move_to_position",
		"unit_id": "synthetic_" + label,
		"target_position": target_world,
		"path": world_path,
		"requeue_until_target": false,
		"local_avoidance_enabled": false,
	}
	var ticks: int = 0
	var actual_distance_moved: float = 0.0
	while ticks < MAX_STEPS and not Array(command.get("path", [])).is_empty():
		previous_world = unit.global_position
		simulation.call("_apply_move_command_with_terrain", command, unit, target_world, 1.0, STEP_DELTA, registry)
		actual_distance_moved += previous_world.distance_to(unit.global_position)
		ticks += 1
	var target_error: float = unit.global_position.distance_to(target_world)
	_check(ticks > 0 and ticks < MAX_STEPS and target_error <= 0.001 and Array(command.get("path", [])).is_empty(), "%s: actual terrain integrator reaches target and consumes path" % label)
	var sample: Dictionary = {
		"id": label,
		"from_grid": [START_GRID.x, START_GRID.y],
		"to_grid": [target_grid.x, target_grid.y],
		"grid_path": serialized_grid_path,
		"path_cost": float(score.get("path_cost", 0.0)),
		"visible_3d_ground_length": Vector2(target_grid - START_GRID).length() * CELL_SIZE_3D,
		"from_projected_world": [start_world.x, start_world.y],
		"to_projected_world": [target_world.x, target_world.y],
		"projected_path_length": projected_path_length,
		"actual_distance_moved_projected_world": actual_distance_moved,
		"ticks": ticks,
		"simulated_seconds": float(ticks) * STEP_DELTA,
		"nominal_move_speed_projected_world_per_second": SIMULATION_SCRIPT.MOVE_SPEED_PER_SECOND,
		"target_error_projected_world": target_error,
	}
	unit.free()
	return sample


func _source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path in ["res://scripts/core/simulation_root.gd", "res://scripts/terrain/terrain_registry.gd", "res://scripts/terrain/terrain_pathfinder.gd", "res://scripts/terrain/terrain_map_data.gd"]:
		result[path] = FileAccess.get_sha256(path)
	return result


func _check(condition: bool, description: String) -> void:
	_checks.append({"pass": condition, "description": description})
	if condition:
		_passed += 1
		print("PASS: %s" % description)
	else:
		_failed += 1
		print("FAIL: %s" % description)
