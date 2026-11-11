extends SceneTree

const SIM = preload("res://scripts/core/simulation_root.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")

var _failures := 0
var _checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var registry := REGISTRY.new()
	registry.name = "TerrainRegistry"
	root.add_child(registry)
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, "hex_axial_v1")
	for q in range(16):
		for r in range(5):
			registry.register_tile(TILE.new({
				"tile_id": "%d:%d" % [q, r], "grid_position": Vector2i(q, r),
				"walkable": q != 7 or r == 2,
			}))
	var start := Vector2i(0, 2)
	var goal := Vector2i(15, 2)
	var planner := PATHFINDER.new()
	var search := PATHFINDER.RegionalHexSearch.new(start, goal, registry.get_revision(), {}, registry)
	_check(search.advance(planner, registry, 3) == 3 and not search.finished, "Work stops after expansion limit")
	var sim := SIM.new()
	sim.terrain_registry_path = NodePath("../TerrainRegistry")
	root.add_child(sim)
	var move := {"command_type": "move_to_position", "command_token": "stage", "unit_id": "test",
		"target_position": registry.grid_to_world(goal), "_regional_navigation_search": search}
	sim.enqueue_command(move)
	var repeated := move.duplicate()
	repeated.erase("_regional_navigation_search")
	sim.enqueue_command(repeated)
	_check(sim.command_queue.size() == 1 and sim.command_queue[0].get("_regional_navigation_search") == search, "Same stage retains pending search")
	var changed_cost := repeated.duplicate()
	changed_cost["navigation_cover_weight"] = 0.7
	sim.enqueue_command(changed_cost)
	_check(not sim.command_queue[0].has("_regional_navigation_search"), "Changed costs discard pending search")
	sim.command_queue.clear()
	sim.enqueue_command(move)
	var retargeted := repeated.duplicate()
	retargeted.target_position = registry.grid_to_world(Vector2i(10, 3))
	sim.enqueue_command(retargeted)
	_check(not sim.command_queue[0].has("_regional_navigation_search"), "Changed goal discards pending search")
	sim.command_queue.clear()
	while not search.finished:
		search.advance(planner, registry, 3)
	_check(search.path.front() == start and search.path.back() == goal and search.path.has(Vector2i(7, 2)), "Real route crosses only opening")
	var baseline := planner.find_path(start, goal, registry)
	_check(is_equal_approx(planner.score_path(baseline, registry).path_cost, planner.score_path(search.path, registry).path_cost), "Exact route cost matches existing A*")
	registry.set_runtime_tile_overrides([{"grid_position": Vector2i(7, 2), "walkable_override": false}])
	_check(search.revision != registry.get_revision(), "Runtime door changes revision")
	var closed := PATHFINDER.RegionalHexSearch.new(start, goal, registry.get_revision(), {}, registry)
	while not closed.finished:
		closed.advance(planner, registry, 3)
	_check(closed.path.back() == Vector2i(6, 2) and not closed.path.has(Vector2i(7, 2)), "Unreachable target uses nearest connected cell")
	var slope_grid := Vector2i(3, 2)
	registry.get_tile_at_grid(slope_grid).height_level = 1
	registry.get_tile_at_grid(slope_grid).regional_grade = true
	for direction: Vector2i in preload("res://scripts/terrain/hex_grid.gd").DIRECTIONS:
		var neighbor := slope_grid + direction
		registry.get_tile_at_grid(neighbor).regional_grade = true
		_check(planner.can_traverse_step(slope_grid, neighbor, registry) and planner.can_traverse_step(neighbor, slope_grid, registry), "One-step ramp remains bidirectional " + str(direction))
	sim.free()
	registry.free()
	print("Regional navigation: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
