extends SceneTree
## Executes the real mission loader with rendering/roster side effects disabled.
## JSON decoding, terrain registration, load ordering and SimulationRoot are real.
const FIX = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const UNIT_REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")

class MissionLoadProbe:
	extends "res://scripts/tests/mission_test_setup.gd"
	var gate_revision_before: int = -1
	var gate_revision_after: int = -1
	var final_loading_revision: int = -1
	var override_grid := Vector2i.ZERO
	var override_applied: bool = false
	var rendering_suppressed: bool = false

	func _ready() -> void:
		# Invoke the inherited finish method explicitly after wiring the fixture.
		pass

	func _build_runtime_unit_paths() -> Array:
		return []

	func _build_unit_loadout_modifiers() -> void:
		pass

	func _setup_objective_status(_simulation_root: Node, _objective_marker: Marker2D) -> void:
		pass

	func _setup_respawn_manager(_spawn_alpha: Marker2D, _spawn_bravo: Marker2D) -> void:
		pass

	func _setup_enemy_waves(_enemy_units: Array) -> void:
		pass

	func _apply_scenario_timer_to_combat_driver() -> void:
		# Real scenarios can publish door/cover overrides at this late load stage.
		# A prewarm immediately after terrain registration would now be stale.
		var registry = get_node(terrain_registry_path)
		gate_revision_before = registry.get_revision()
		for tile in registry.get_all_tiles():
			if registry.is_walkable(tile.grid_position):
				override_grid = tile.grid_position
				registry.set_runtime_tile_overrides([{
					"grid_position": override_grid, "cover_value_override": 83,
					"blocks_los_override": true, "object_height_override": 2,
				}])
				override_applied = true
				break
		gate_revision_after = registry.get_revision()

	func _ensure_primary_3d_view(_unit_nodes: Array) -> void:
		rendering_suppressed = true

	func _initialize_fog_of_war(_unit_nodes: Array, registry) -> void:
		final_loading_revision = registry.get_revision()


var passed: int = 0
var failed: int = 0
var failures: Array = []
var evidence: Dictionary = {}


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		failures.append(label)
		push_error(label)


func _run() -> void:
	var expect_native: bool = FIX.argument("--expect-native", "true") == "true"
	_check(ClassDB.class_exists("NativeNavigationKernel") == expect_native, "Extension availability matches explicit expectation")
	if failed > 0:
		_finish(expect_native)
		return
	var fixture := Node.new()
	fixture.name = "NavigationLoadFixture"
	root.add_child(fixture)
	var registry = REGISTRY.new()
	registry.name = "TerrainRegistry"
	fixture.add_child(registry)
	var units = UNIT_REGISTRY.new()
	units.name = "UnitRegistry"
	fixture.add_child(units)
	var simulation = SIMULATION.new()
	simulation.name = "SimulationRoot"
	simulation.terrain_registry_path = NodePath("../TerrainRegistry")
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	fixture.add_child(simulation)
	simulation.set_physics_process(false)
	simulation.set_process(false)
	var setup := MissionLoadProbe.new()
	setup.name = "MissionSetup"
	setup.terrain_registry_path = NodePath("../TerrainRegistry")
	setup.simulation_root_path = NodePath("../SimulationRoot")
	setup.map_file_path = "res://maps/Ground_Mission01_32x32.json"
	setup.defer_friendly_runtime_activation = true
	fixture.add_child(setup)
	setup.set_process(false)
	var leader := Node.new()
	fixture.add_child(leader)
	var leaders := Node.new()
	fixture.add_child(leaders)
	_check(bool(simulation.get("native_navigation_enabled")), "Normal SimulationRoot defaults to native navigation")
	var load_started: int = Time.get_ticks_usec()
	setup.call("_finish_ready_after_scenario_loaded", leader, units, leaders, simulation)
	var load_usec: int = Time.get_ticks_usec() - load_started
	var prepared: Dictionary = simulation.call("get_navigation_backend_debug_snapshot")
	_check(bool(setup.get("_is_initialized")), "Inherited mission load path completes initialization")
	_check(registry.get_tile_count() == 9408, "Real GM01 JSON loader registered all 9408 cells")
	_check(setup.get("_loaded_terrain_map_data") != null, "Actual TerrainMapData JSON load ran")
	_check(setup.rendering_suppressed, "Rendering isolated without replacing terrain load")
	_check(setup.override_applied and setup.gate_revision_after > setup.gate_revision_before, "Late scenario stage publishes a real terrain revision")
	_check(setup.final_loading_revision == registry.get_revision(), "Final load stage observes the current terrain revision")
	_check(int(simulation.get("_hpa_navigation_registry_revision")) == registry.get_revision(), "Load prewarm uses final revision after initial scenario overrides")
	var prewarm: Dictionary = prepared.get("prewarm", {})
	_check(bool(prewarm.get("ready", false)), "Load hook records a ready navigation backend")
	_check(int(prewarm.get("registry_revision", -1)) == registry.get_revision(), "Public prewarm report records the final terrain revision")
	_check(bool(prewarm.get("native_prepared", false)) == expect_native, "Public prewarm report identifies real native availability")
	_check(simulation.get("_hpa_navigation_graph") != null, "HPA graph exists before the first navigation query")
	_check(int(simulation.get("_hpa_navigation_build_count")) == 1, "Mission loading builds HPA graph exactly once")
	if expect_native:
		_check(int(prepared.get("snapshot_build_count", 0)) == 1, "Mission loading prepares exactly one native terrain snapshot")
		_check(int(prepared.get("graph_build_count", 0)) == 1, "Mission loading prepares exactly one native HPA snapshot")
	else:
		_check(int(prepared.get("snapshot_build_count", -1)) == 0, "DLL-free loading does not claim a native snapshot")
	var pair: Array = FIX.query_pairs(registry, 1)[0]
	var options := {"cover_aware_enabled": true, "cover_weight": 0.4,
		"exposure_weight": 0.8, "hazard_grids": [setup.override_grid]}
	var graph = simulation.get("_hpa_navigation_graph")
	var expected: Dictionary = HPA.new().find_path_with_status(pair[0], pair[1], registry, graph, options)
	var query_started: int = Time.get_ticks_usec()
	var actual: Dictionary = simulation.call("_find_navigation_grid_path", pair[0], pair[1], registry, options)
	var query_usec: int = Time.get_ticks_usec() - query_started
	var after_query: Dictionary = simulation.call("get_navigation_backend_debug_snapshot")
	_check(not Array(actual.get("path", [])).is_empty(), "First loaded-map query returns a nonempty route")
	_check(actual.get("path", []) == expected.get("path", []) and actual.get("status", "") == expected.get("status", ""), "First loaded-map query has exact GDScript path and status")
	var oracle = PATH.new()
	_check(oracle.score_path(actual.get("path", []), registry, options) == oracle.score_path(expected.get("path", []), registry, options), "First loaded-map query has exact score fields")
	_check(int(simulation.get("_hpa_navigation_build_count")) == 1, "First query does not rebuild the load-prepared HPA graph")
	_check(int(after_query.get("snapshot_build_count", -1)) == int(prepared.get("snapshot_build_count", -2)), "First query does not rebuild the load-prepared native terrain")
	_check(int(after_query.get("graph_build_count", -1)) == int(prepared.get("graph_build_count", -2)), "First query does not rebuild the load-prepared native HPA snapshot")
	_check(String(after_query.get("last_backend", "")) == ("native" if expect_native else "gdscript_fallback"), "First normal query uses the expected backend")
	# Re-entering an already initialized loader must not prepare anything again.
	setup.call("_finish_ready_after_scenario_loaded", leader, units, leaders, simulation)
	var repeated: Dictionary = simulation.call("get_navigation_backend_debug_snapshot")
	_check(repeated == after_query, "Repeated load finish is idempotent after initialization")
	evidence = {"map": setup.map_file_path, "tile_count": registry.get_tile_count(),
		"load_usec": load_usec, "first_query_usec": query_usec,
		"initial_override_grid": [setup.override_grid.x, setup.override_grid.y],
		"revision_before_initial_override": setup.gate_revision_before,
		"final_registry_revision": registry.get_revision(), "prepared": prepared,
		"after_first_query": after_query, "path_length": Array(actual.get("path", [])).size()}
	fixture.free()
	_finish(expect_native)


func _finish(expect_native: bool) -> void:
	evidence.merge({"engine": Engine.get_version_info(), "passed": passed, "failed": failed,
		"failures": failures, "expect_native": expect_native,
		"scope": "Actual MissionTestSetup finish/JSON load with roster/render/FOW side effects isolated; real SimulationRoot and late terrain override. No rendered scene or actor playthrough claim."})
	if not FIX.write_json(FIX.argument("--output", "user://native_navigation_load.json"), evidence):
		failed += 1
	print("NATIVE_NAVIGATION_LOAD ", passed, "/", failed, " expect_native=", expect_native)
	quit(0 if failed == 0 else 1)
