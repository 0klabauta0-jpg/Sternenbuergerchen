extends SceneTree
## Production owner and real command queue; no renderer, actor assets or save data.
const SIM = preload("res://scripts/core/simulation_root.gd")
const UNITS = preload("res://scripts/registries/unit_registry.gd")
const FIX = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
var passed: int = 0
var failed: int = 0
var failures: Array = []
var evidence: Array = []
var expect_native: bool = true

class ProbeUnit:
	extends Node2D
	var unit_id: String = "runtime_native_probe"
	func get_unit_id() -> String:
		return unit_id
	func get_team_id() -> String:
		return "team_alpha"
	func get_vital_state() -> String:
		return "fit"

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		failures.append(label)
		push_error(label)

func _run() -> void:
	expect_native = FIX.argument("--expect-native", "true") != "false"
	_check(ClassDB.class_exists("NativeNavigationKernel") == expect_native, "Process has exactly the requested native availability")
	if failed == 0:
		for topology in ["square8", "hex_axial_v1"]:
			_test_first_command(topology)
			_test_options_and_revisions(topology)
		_test_registry_identity()
		_test_disabled_and_no_terrain()
	var result := {"passed": passed, "failed": failed, "failures": failures,
		"expected_native": expect_native, "engine": Engine.get_version_info(), "samples": evidence,
		"scope": "Actual SimulationRoot and UnitRegistry command processing with synthetic map data. No renderer, save access, actor playthrough or FPS claim."}
	if not FIX.write_json(FIX.argument("--output", "user://native_navigation_runtime.json"), result):
		failed += 1
	print("NATIVE_NAVIGATION_RUNTIME ", passed, "/", failed, " expect_native=", expect_native)
	quit(0 if failed == 0 else 1)

func _context(registry, native_enabled: bool = true) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var units = UNITS.new()
	units.name = "Units"
	scene.add_child(units)
	registry.name = "Terrain"
	scene.add_child(registry)
	var simulation = SIM.new()
	_check(simulation.native_navigation_enabled, "SimulationRoot enables native navigation by default")
	simulation.native_navigation_enabled = native_enabled
	simulation.name = "Simulation"
	simulation.unit_registry_path = NodePath("../Units")
	simulation.terrain_registry_path = NodePath("../Terrain")
	simulation.unit_minimum_spacing_enabled = false
	simulation.local_avoidance_enabled = false
	simulation.bottleneck_reservation_enabled = false
	scene.add_child(simulation)
	simulation.set_physics_process(false)
	simulation.set_process(false)
	var unit := ProbeUnit.new()
	scene.add_child(unit)
	units.register_unit(unit.unit_id, unit)
	return {"scene": scene, "simulation": simulation, "terrain": registry, "unit": unit}

func _command(unit_id: String, target: Vector2) -> Dictionary:
	return {"command_type": "move_to_position", "unit_id": unit_id, "team_id": "team_alpha",
		"target_position": target, "move_speed_factor": 1.0, "requeue_until_target": true,
		"command_token": "native_runtime_command"}

func _backend(simulation) -> Dictionary:
	return simulation.get_navigation_backend_debug_snapshot()

func _assert_backend(simulation, label: String, native_expected: bool = true) -> void:
	var debug: Dictionary = _backend(simulation)
	if expect_native and native_expected:
		_check(debug.get("last_backend", "") == "native", label + " uses native backend")
	else:
		_check(not String(debug.get("last_backend", "")).is_empty() and debug.get("last_backend", "") != "native", label + " uses explicit GDScript backend")

func _test_first_command(topology: String) -> void:
	var candidate: Dictionary = _context(FIX.synthetic(topology, 12, 4, Vector2i.ZERO, false))
	var baseline: Dictionary = _context(FIX.synthetic(topology, 12, 4, Vector2i.ZERO, false), false)
	var sim = candidate.simulation
	var terrain = candidate.terrain
	var started: int = Time.get_ticks_usec()
	var prepared: Dictionary = sim.prewarm_navigation()
	var preparation_usec: int = Time.get_ticks_usec() - started
	baseline.simulation.prewarm_navigation()
	var before: Dictionary = _backend(sim)
	_check(prepared.get("ready", false), topology + " bound terrain is prepared during explicit loading phase")
	_check(prepared.get("native_prepared", false) == expect_native, topology + " preparation truth matches native availability")
	_check(bool(sim.get_navigation_debug_snapshot().hpa_navigation.has_graph), topology + " HPA graph exists before first command")
	if expect_native:
		_check(before.get("snapshot_build_count", 0) == 1 and before.get("graph_build_count", 0) == 1, topology + " prewarm creates exactly one native terrain/HPA snapshot")
	var target: Vector2 = terrain.grid_to_world(Vector2i(11, 0))
	for context in [candidate, baseline]:
		context.unit.position = context.terrain.grid_to_world(Vector2i.ZERO)
		context.simulation.enqueue_command(_command(context.unit.unit_id, target))
	started = Time.get_ticks_usec()
	sim._physics_process(0.1)
	var first_move_usec: int = Time.get_ticks_usec() - started
	baseline.simulation._physics_process(0.1)
	_check(not sim.command_queue.is_empty() and candidate.unit.position != Vector2.ZERO, topology + " normal queued movement starts")
	_check(candidate.unit.position == baseline.unit.position, topology + " first movement displacement exactly matches GDScript")
	if not sim.command_queue.is_empty() and not baseline.simulation.command_queue.is_empty():
		_check(Array(sim.command_queue[0].get("path", [])) == Array(baseline.simulation.command_queue[0].get("path", [])), topology + " queued world route exactly matches GDScript")
	_assert_backend(sim, topology + " first normal move")
	var after: Dictionary = _backend(sim)
	_check(after.get("snapshot_build_count", 0) == before.get("snapshot_build_count", 0), topology + " first normal command does not rebuild terrain")
	_check(after.get("graph_build_count", 0) == before.get("graph_build_count", 0), topology + " first normal command does not rebuild native HPA data")
	_check(int(sim.get_navigation_debug_snapshot().hpa_navigation.build_count) == 1, topology + " first command reuses prebuilt owner HPA graph")
	for tick in range(250):
		if sim.command_queue.is_empty(): break
		sim._physics_process(0.1)
	_check(sim.command_queue.is_empty() and candidate.unit.position.is_equal_approx(target), topology + " ordinary command reaches destination and drains")
	evidence.append({"case": topology + "/first_command", "preparation_usec": preparation_usec,
		"first_move_tick_usec": first_move_usec, "prewarm": prepared, "backend_after_first_move": after})
	candidate.scene.free()
	baseline.scene.free()

func _compare_grid(simulation, oracle, terrain, start: Vector2i, target: Vector2i, options: Dictionary, label: String) -> Dictionary:
	var expected: Dictionary = oracle.call("_find_navigation_grid_path", start, target, terrain, options)
	var actual: Dictionary = simulation.call("_find_navigation_grid_path", start, target, terrain, options)
	_check(actual.get("path", []) == expected.get("path", []), label + " complete ordered grid path")
	_check(actual.get("status", "") == expected.get("status", ""), label + " status")
	var scorer = PATH.new()
	_check(scorer.score_path(actual.get("path", []), terrain, options) == scorer.score_path(expected.get("path", []), terrain, options), label + " exact path score")
	_assert_backend(simulation, label)
	return actual

func _test_options_and_revisions(topology: String) -> void:
	var context: Dictionary = _context(FIX.synthetic(topology))
	var sim = context.simulation
	var terrain = context.terrain
	var oracle = SIM.new()
	oracle.native_navigation_enabled = false
	sim.prewarm_navigation()
	var before: Dictionary = _backend(sim)
	for index in range(FIX.option_sets().size()):
		_compare_grid(sim, oracle, terrain, Vector2i(-3, -2), Vector2i(12, 11), FIX.option_sets()[index], topology + "/options%d" % index)
		_check(_backend(sim).get("snapshot_build_count", 0) == before.get("snapshot_build_count", 0), topology + " options do not rebuild terrain %d" % index)
		_check(_backend(sim).get("graph_build_count", 0) == before.get("graph_build_count", 0), topology + " options do not rebuild HPA snapshot %d" % index)
	var plain: Dictionary = _compare_grid(sim, oracle, terrain, Vector2i(-3, -2), Vector2i(12, 11), {}, topology + "/before_override")
	var path: Array = plain.get("path", [])
	_check(path.size() > 3, topology + " override fixture has an interior route cell")
	if path.size() > 3:
		var door: Vector2i = Vector2i(path[int(path.size() / 2)])
		terrain.set_runtime_tile_overrides([{"grid_position": door, "walkable_override": false, "blocks_los_override": true}])
		var changed: Dictionary = _compare_grid(sim, oracle, terrain, Vector2i(-3, -2), Vector2i(12, 11), {}, topology + "/closed_door")
		_check(not Array(changed.get("path", [])).has(door), topology + " revised route never contains closed runtime door")
		if expect_native:
			_check(_backend(sim).get("snapshot_build_count", 0) > before.get("snapshot_build_count", 0), topology + " terrain revision invalidates native snapshot")
		terrain.clear_runtime_tile_overrides()
		var reopened: Dictionary = _compare_grid(sim, oracle, terrain, Vector2i(-3, -2), Vector2i(12, 11), {}, topology + "/reopened_door")
		_check(reopened.get("path", []) == plain.get("path", []), topology + " reopened terrain restores original route")
		terrain.set_runtime_tile_overrides([{"grid_position": door, "cover_value_override": 100, "blocks_los_override": true, "object_height_override": 3}])
		_compare_grid(sim, oracle, terrain, Vector2i(-3, -2), Vector2i(12, 11), {"cover_aware_enabled": true, "cover_weight": 1.2, "exposure_weight": 2.0, "hazard_grids": [Vector2i(-3, -2)]}, topology + "/cover_los_override")
	context.scene.free()
	oracle.free()

func _test_registry_identity() -> void:
	var first = FIX.synthetic("square8", 12, 4, Vector2i.ZERO, false)
	var context: Dictionary = _context(first)
	var sim = context.simulation
	sim.prewarm_navigation()
	var original: Dictionary = sim.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(11, 0), first)
	var second = FIX.synthetic("square8", 12, 4, Vector2i.ZERO, false)
	second.get_tile_at_grid(Vector2i(5, 0)).walkable = false
	_check(second.get_revision() == first.get_revision(), "Map switch fixture has equal numeric revisions")
	second.name = "TerrainB"
	context.scene.add_child(second)
	sim.terrain_registry_path = NodePath("../TerrainB")
	var prepared: Dictionary = sim.prewarm_navigation()
	_check(prepared.get("ready", false) and prepared.get("native_prepared", false) == expect_native, "Map-switch loading prepares newly bound registry")
	var before: Dictionary = _backend(sim)
	var oracle = SIM.new()
	oracle.native_navigation_enabled = false
	var changed: Dictionary = _compare_grid(sim, oracle, second, Vector2i.ZERO, Vector2i(11, 0), {}, "same_revision_map_switch")
	_check(changed.get("path", []) != original.get("path", []) and not Array(changed.get("path", [])).has(Vector2i(5, 0)), "Map switch cannot reuse first map's route")
	_check(_backend(sim).get("snapshot_build_count", 0) == before.get("snapshot_build_count", 0), "First new-map query reuses loading snapshot")
	oracle.free()
	context.scene.free()

func _test_disabled_and_no_terrain() -> void:
	var context: Dictionary = _context(FIX.synthetic("square8", 4, 2, Vector2i.ZERO, false), false)
	var sim = context.simulation
	var prepared: Dictionary = sim.prewarm_navigation()
	_check(prepared.get("ready", false) and not prepared.get("native_prepared", true), "Explicit native disable retains prepared GDScript navigation")
	var path: Dictionary = sim.call("_find_navigation_grid_path", Vector2i.ZERO, Vector2i(3, 0), context.terrain)
	_check(not Array(path.get("path", [])).is_empty(), "Explicitly disabled backend still returns route")
	_assert_backend(sim, "disabled native", false)
	sim.terrain_registry_path = NodePath()
	var empty: Dictionary = sim.prewarm_navigation()
	_check(not empty.get("ready", true) and not empty.get("native_prepared", true), "Missing bound terrain produces explicit unprepared state")
	_check(not bool(sim.get_navigation_debug_snapshot().hpa_navigation.has_graph), "Missing terrain clears retained owner graph")
	var target := Vector2(64.0, 32.0)
	_check(sim.call("_build_path_world_points", Vector2.ZERO, target, null) == [target], "No-terrain direct movement fallback is preserved")
	sim.enqueue_command(_command(context.unit.unit_id, target))
	sim._physics_process(0.1)
	_check(context.unit.position != Vector2.ZERO and context.unit.position.distance_to(target) < target.length(), "Normal command still moves without a terrain registry")
	context.scene.free()
