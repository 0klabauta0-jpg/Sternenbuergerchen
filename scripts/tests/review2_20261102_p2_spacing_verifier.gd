extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const RESOLVER = preload("res://scripts/tactical/local_avoidance_resolver.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")

class SpacingUnit extends Node2D:
	var unit_id: String = ""
	func get_unit_id() -> String:
		return unit_id

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	print("=== Review 2 P2 spacing broad phase ===")
	_test_idle_authority_does_not_compare_all_pairs_or_measure_global_minimum()
	_test_overlap_and_negative_cells_are_order_independent()
	_test_correction_refreshes_future_spatial_candidates()
	_test_terrain_one_sided_and_blocked_fallbacks()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_idle_authority_does_not_compare_all_pairs_or_measure_global_minimum() -> void:
	# Count actual distance evaluations in an otherwise unchanged in-memory copy.
	# This also measures the pre-fix code, without requiring new telemetry to exist.
	var counted_script: GDScript = _counted_resolver_script()
	if counted_script == null:
		return
	var scene := Node.new()
	root.add_child(scene)
	var registry = REGISTRY.new()
	registry.name = "UnitRegistry"
	scene.add_child(registry)
	var simulation = SIMULATION.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	simulation.unit_minimum_spacing_debug_enabled = false
	simulation.local_avoidance_enabled = false
	scene.add_child(simulation)
	simulation.set_physics_process(false)
	var resolver = counted_script.new()
	simulation.set("_local_avoidance_resolver", resolver)
	for index in range(96):
		var unit := _unit("idle_%03d" % index, Vector2(index * 100.0, 0.0))
		scene.add_child(unit)
		registry.register_unit(unit.unit_id, unit)
	for tick in range(10):
		simulation.call("_physics_process", 1.0 / 60.0)
	var solver_pairs: int = int(resolver.get("review_solver_pairs"))
	var diagnostic_pairs: int = int(resolver.get("review_diagnostic_pairs"))
	print("REVIEW2_SPACING_IDLE ", JSON.stringify({"units": 96, "ticks": 10, "solver_pairs": solver_pairs, "diagnostic_pairs": diagnostic_pairs}))
	_assert(solver_pairs < 5700, "96 separated idle units avoid the old 45,600 all-pair solver checks over ten authority ticks")
	_assert(diagnostic_pairs == 0, "Normal authority ticks do not run the global minimum-distance diagnostic")
	var idle_snapshot: Dictionary = simulation.get_unit_minimum_spacing_debug_snapshot()
	_assert(Array(idle_snapshot.get("moved_unit_ids", [])).is_empty(), "Idle broad phase preserves all stationary authority positions")
	_assert(not bool(idle_snapshot.get("minimum_distance_measured", true)), "Idle snapshot explicitly marks the global minimum as unmeasured")
	_assert(simulation.command_queue.is_empty(), "Spacing does not invent gameplay commands")
	simulation.unit_minimum_spacing_debug_enabled = true
	simulation.call("_physics_process", 1.0 / 60.0)
	var debug: Dictionary = simulation.get_unit_minimum_spacing_debug_snapshot()
	_assert(bool(debug.get("minimum_distance_measured", false)), "Explicit debug snapshot identifies its global minimum as measured")
	_assert(is_equal_approx(float(debug.get("minimum_distance_after", INF)), 100.0), "Explicit debug measurement still returns the exact global minimum")
	_assert(int(resolver.get("review_diagnostic_pairs")) - diagnostic_pairs == 4560, "Explicit debug mode measures the 4,560 unique diagnostic pairs once")
	scene.free()


func _test_overlap_and_negative_cells_are_order_independent() -> void:
	var units: Array = [_unit("alpha", Vector2(-0.1, 0.0)), _unit("bravo", Vector2(0.1, 0.0))]
	for unit in units:
		root.add_child(unit)
	var resolver = RESOLVER.new()
	var forward: Dictionary = resolver.resolve_minimum_spacing_positions(units, 36.0, null, 4)
	units.reverse()
	var reversed: Dictionary = resolver.resolve_minimum_spacing_positions(units, 36.0, null, 4)
	var positions: Dictionary = forward.get("positions_by_unit_id", {})
	_assert(Vector2(positions.get("alpha", Vector2.ZERO)).is_equal_approx(Vector2(-18.0, 0.0)), "Nearby pair across the negative/positive cell boundary separates alpha to the expected position")
	_assert(Vector2(positions.get("bravo", Vector2.ZERO)).is_equal_approx(Vector2(18.0, 0.0)), "Nearby pair across the cell boundary separates bravo to the expected position")
	_assert(positions == Dictionary(reversed.get("positions_by_unit_id", {})), "Shuffled registration order preserves deterministic pair resolution")
	for unit in units:
		unit.global_position = Vector2.ZERO
	var coincident: Dictionary = resolver.resolve_minimum_spacing_positions(units, 36.0, null, 4)
	var coincident_positions: Dictionary = coincident.get("positions_by_unit_id", {})
	_assert(Vector2(coincident_positions["alpha"]).distance_to(Vector2(coincident_positions["bravo"])) >= 35.999, "Coincident spawn pair retains deterministic nonzero separation")
	for unit in units:
		unit.free()


func _test_terrain_one_sided_and_blocked_fallbacks() -> void:
	var terrain = TERRAIN.new()
	terrain.configure_iso_grid(Vector2.ZERO, 1.0, 1.0)
	for grid in [Vector2i.ZERO, Vector2i(5, -5), Vector2i(18, -18)]:
		terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid, "world_position": terrain.grid_to_world(grid), "walkable": true}))
	var units: Array = [_unit("alpha", Vector2.ZERO), _unit("bravo", Vector2(10.0, 0.0))]
	for unit in units:
		root.add_child(unit)
	var resolver = RESOLVER.new()
	var result: Dictionary = resolver.resolve_minimum_spacing_positions(units, 36.0, terrain, 1)
	var positions: Dictionary = result.get("positions_by_unit_id", {})
	_assert(Vector2(positions["alpha"]) == Vector2.ZERO and Vector2(positions["bravo"]) == Vector2(36.0, 0.0), "Blocked half correction retains the legal full correction on the other unit")
	_assert(terrain.is_walkable(terrain.world_to_grid(Vector2(positions["alpha"]))) and terrain.is_walkable(terrain.world_to_grid(Vector2(positions["bravo"]))), "Broad-phase separation retains terrain safety")
	terrain.clear_tiles()
	for grid in [Vector2i.ZERO, Vector2i(5, -5)]:
		terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid, "world_position": terrain.grid_to_world(grid), "walkable": true}))
	var blocked: Dictionary = resolver.resolve_minimum_spacing_positions(units, 36.0, terrain, 1)
	_assert(int(blocked.get("blocked_pair_count", 0)) == 1 and Array(blocked.get("moved_unit_ids", [])).is_empty(), "Fully blocked pair reports the conflict without moving units onto blocked terrain")
	for unit in units:
		unit.free()
	terrain.free()


func _test_correction_refreshes_future_spatial_candidates() -> void:
	# Alpha's first correction crosses a cell boundary and brings charlie into
	# range. A broad phase frozen at iteration start would miss the next pair.
	var units: Array = [_unit("alpha", Vector2(35.0, 0.0)), _unit("bravo", Vector2(34.0, 0.0)), _unit("charlie", Vector2(87.0, 0.0))]
	for unit in units:
		root.add_child(unit)
	var resolver = RESOLVER.new()
	var result: Dictionary = resolver.resolve_minimum_spacing_positions(units, 36.0, null, 1)
	var positions: Dictionary = result.get("positions_by_unit_id", {})
	_assert(Vector2(positions["alpha"]).is_equal_approx(Vector2(51.75, 0.0)), "Correction refresh finds a future neighbor across the new cell boundary in the same iteration")
	_assert(Vector2(positions["bravo"]).is_equal_approx(Vector2(16.5, 0.0)) and Vector2(positions["charlie"]).is_equal_approx(Vector2(87.75, 0.0)), "Refreshed candidates preserve the original sorted pair-resolution order")
	for unit in units:
		unit.free()


func _counted_resolver_script() -> GDScript:
	var source: String = FileAccess.get_file_as_string("res://scripts/tactical/local_avoidance_resolver.gd").replace("\r\n", "\n")
	source = source.replace("class_name LocalAvoidanceResolver\n", "")
	source = source.replace("extends RefCounted\n", "extends RefCounted\n\nvar review_solver_pairs: int = 0\nvar review_diagnostic_pairs: int = 0\n")
	var lines := PackedStringArray()
	var solver_sites: int = 0
	var diagnostic_sites: int = 0
	for line in source.split("\n"):
		var stripped: String = line.strip_edges()
		var indent: String = line.substr(0, line.length() - line.strip_edges(true, false).length())
		if stripped == "var distance: float = delta.length()":
			lines.append(indent + "review_solver_pairs += 1")
			solver_sites += 1
		if stripped.begins_with("minimum_distance = minf(minimum_distance, position_a.distance_to(position_b))"):
			lines.append(indent + "review_diagnostic_pairs += 1")
			diagnostic_sites += 1
		lines.append(line)
	_assert(solver_sites == 1 and diagnostic_sites == 1, "Operation probe instruments the real solver and global diagnostic distance evaluations")
	if solver_sites != 1 or diagnostic_sites != 1:
		return null
	var script := GDScript.new()
	script.source_code = "\n".join(lines)
	var error: int = script.reload()
	_assert(error == OK, "Counted real resolver compiles for the authority-path operation probe")
	return script if error == OK else null


func _unit(unit_id: String, position_value: Vector2) -> SpacingUnit:
	var unit := SpacingUnit.new()
	unit.unit_id = unit_id
	unit.position = position_value
	return unit


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		print("FAIL: ", message)
