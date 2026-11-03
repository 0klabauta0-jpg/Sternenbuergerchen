extends SceneTree

const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SIMULATION = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY = preload("res://scripts/registries/unit_registry.gd")
const TERRAIN = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const UNIT = preload("res://scripts/npc/test_unit.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not GUARD.require_isolated_user_data():
		return
	call_deferred("_run")


func _run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		for height in [1, 2]:
			for descending in [false, true]:
				for edge in ["cliff", "none"]:
					_test_half_correction(String(topology), height, descending, String(edge), false)
					_test_full_correction(String(topology), height, descending, String(edge), false)
				_test_half_correction(String(topology), height, descending, "slope", true)
				_test_full_correction(String(topology), height, descending, "slope", true)
		_test_half_correction(String(topology), 0, false, "none", true)
		_test_full_correction(String(topology), 0, false, "none", true)
		_test_intermediate_hole(String(topology))
	_test_square_diagonal(false)
	_test_square_diagonal(true)
	_test_offset_square_segment()
	_test_terrainless()
	print("REVIEW7_SPACING_RESULT passed=%d failed=%d" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_half_correction(topology: String, height: int, descending: bool, edge: String, legal: bool) -> void:
	var context: Dictionary = _context(topology, 64.0, 32.0)
	var terrain: Node = context["terrain"]
	_tile(terrain, Vector2i.ZERO, height if descending else 0, edge if descending else "none")
	_tile(terrain, Vector2i.RIGHT, 0 if descending else height, "none" if descending else edge)
	var direction: Vector2 = Vector2(terrain.grid_to_world(Vector2i.RIGHT)).normalized()
	var boundary: float = Vector2(terrain.grid_to_world(Vector2i.RIGHT)).length() * 0.5
	var before_a: Vector2 = direction * (boundary - 3.0)
	var before_b: Vector2 = direction * (boundary - 1.0)
	_add_units(context, before_a, before_b)
	var label: String = "%s half H%d %s %s" % [topology, height, "down" if descending else "up", edge]
	_assert(PATHFINDER.new().can_traverse_step(Vector2i.ZERO, Vector2i.RIGHT, terrain) == legal, label + " fixture agrees with authoritative traversal")
	_tick(context, label)
	var alpha: Node2D = context["alpha"]
	var bravo: Node2D = context["bravo"]
	if legal:
		_assert(alpha.position.is_equal_approx(before_a - direction * 17.0) and bravo.position.is_equal_approx(before_b + direction * 17.0), label + " preserves balanced legal half pushes")
		_assert(terrain.world_to_grid(bravo.position) == Vector2i.RIGHT, label + " crosses the permitted edge")
	else:
		_assert(bravo.position.is_equal_approx(before_b), label + " rejects the half push across the forbidden edge")
		_assert(alpha.position.is_equal_approx(before_a - direction * 34.0), label + " retains the legal opposite full fallback")
	_assert(is_equal_approx(alpha.position.distance_to(bravo.position), 36.0), label + " resolves spacing without an illegal crossing")
	context["scene"].free()


func _test_full_correction(topology: String, height: int, descending: bool, edge: String, legal: bool) -> void:
	# The negative side is absent; both half pushes cannot be committed. The
	# positive full push crosses TWO transitions, including the tested edge.
	var context: Dictionary = _context(topology, 16.0, 8.0)
	var terrain: Node = context["terrain"]
	for grid in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0)]:
		var source: bool = grid != Vector2i(2, 0)
		_tile(terrain, grid, (height if source else 0) if descending else (0 if source else height), (edge if source else "none") if descending else ("none" if source else edge))
	var direction: Vector2 = Vector2(terrain.grid_to_world(Vector2i.RIGHT)).normalized()
	var before_b: Vector2 = direction * 2.0
	_add_units(context, Vector2.ZERO, before_b)
	var label: String = "%s full H%d %s %s" % [topology, height, "down" if descending else "up", edge]
	_assert(terrain.world_to_grid(direction * 36.0) == Vector2i(2, 0), label + " full correction spans two cells")
	_assert(PATHFINDER.new().can_traverse_step(Vector2i.RIGHT, Vector2i(2, 0), terrain) == legal, label + " fixture edge agrees with authoritative traversal")
	_tick(context, label)
	_assert(context["alpha"].position.is_equal_approx(Vector2.ZERO), label + " absent negative terrain blocks alpha")
	if legal:
		_assert(context["bravo"].position.is_equal_approx(direction * 36.0), label + " retains the legal multi-cell full fallback")
	else:
		_assert(context["bravo"].position.is_equal_approx(before_b), label + " rejects the forbidden full fallback")
		_assert(int(context["simulation"].get_unit_minimum_spacing_debug_snapshot().get("blocked_pair_count", 0)) == 1, label + " reports the unresolved blocked pair")
	context["scene"].free()


func _test_intermediate_hole(topology: String) -> void:
	var context: Dictionary = _context(topology, 16.0, 8.0)
	var terrain: Node = context["terrain"]
	_tile(terrain, Vector2i.ZERO)
	_tile(terrain, Vector2i(2, 0))
	var direction: Vector2 = Vector2(terrain.grid_to_world(Vector2i.RIGHT)).normalized()
	_add_units(context, Vector2.ZERO, direction * 2.0)
	var label: String = topology + " missing intermediate tile"
	_assert(terrain.is_walkable(terrain.world_to_grid(direction * 36.0)), label + " destination itself is walkable")
	_tick(context, label)
	_assert(context["alpha"].position == Vector2.ZERO and context["bravo"].position.is_equal_approx(direction * 2.0), label + " cannot teleport to the disconnected walkable destination")
	context["scene"].free()


func _test_square_diagonal(legal: bool) -> void:
	var context: Dictionary = _context("square8", 16.0, 8.0)
	var terrain: Node = context["terrain"]
	for x in range(3):
		for y in range(3):
			_tile(terrain, Vector2i(x, y), 0, "none", legal or x == y)
	_add_units(context, Vector2.ZERO, Vector2(0.0, 2.0))
	var label: String = "square diagonal " + ("legal" if legal else "forbidden corner")
	_assert(PATHFINDER.new().can_traverse_step(Vector2i.ZERO, Vector2i.ONE, terrain) == legal, label + " fixture agrees with pathfinder corner rule")
	_tick(context, label)
	_assert(context["bravo"].position.is_equal_approx(Vector2(0.0, 36.0) if legal else Vector2(0.0, 2.0)), label + " full push respects both intermediate diagonal steps")
	context["scene"].free()


func _test_offset_square_segment() -> void:
	var context: Dictionary = _context("square8", 8.0, 4.0)
	var terrain: Node = context["terrain"]
	for x in range(4):
		for y in range(-1, 2):
			_tile(terrain, Vector2i(x, y), 0, "none", Vector2i(x, y) != Vector2i(3, 0))
	var start: Vector2 = _world_at(terrain, Vector2(0.49, -0.49))
	var finish: Vector2 = _world_at(terrain, Vector2(3.49, 0.51))
	var direction: Vector2 = (finish - start).normalized()
	_add_units(context, start - direction * 2.0, start)
	context["simulation"].unit_minimum_spacing_distance = start.distance_to(finish) + 2.0
	var center_line: Array = terrain.get_grid_line(terrain.world_to_grid(start), terrain.world_to_grid(finish))
	var center_line_legal: bool = true
	for index in range(1, center_line.size()):
		center_line_legal = center_line_legal and PATHFINDER.new().can_traverse_step(center_line[index - 1], center_line[index], terrain)
	_assert(center_line_legal, "Offset fixture center-to-center path incorrectly misses the touched blocked tile")
	_assert(terrain.world_to_grid(start.lerp(finish, 0.9)) == Vector2i(3, 0), "Offset actual segment enters the blocked intermediate tile")
	_tick(context, "offset square segment")
	_assert(context["bravo"].position.is_equal_approx(start), "Actual correction segment cannot cross a blocker omitted by the cell-center line")
	context["scene"].free()


func _test_terrainless() -> void:
	var context: Dictionary = _context("square8", 64.0, 32.0, false)
	_add_units(context, Vector2.ZERO, Vector2(2.0, 0.0))
	_tick(context, "terrainless")
	_assert(context["alpha"].position.is_equal_approx(Vector2(-17.0, 0.0)) and context["bravo"].position.is_equal_approx(Vector2(19.0, 0.0)), "Terrainless authority keeps the existing balanced spacing behavior")
	context["scene"].free()


func _context(topology: String, half_width: float, half_height: float, with_terrain: bool = true) -> Dictionary:
	var scene := Node.new()
	root.add_child(scene)
	var registry = UNIT_REGISTRY.new()
	registry.name = "UnitRegistry"
	scene.add_child(registry)
	var terrain = TERRAIN.new()
	terrain.name = "TerrainRegistry"
	terrain.configure_iso_grid(Vector2.ZERO, half_width, half_height, topology)
	scene.add_child(terrain)
	var simulation = SIMULATION.new()
	simulation.name = "SimulationRoot"
	simulation.unit_registry_path = NodePath("../UnitRegistry")
	simulation.terrain_registry_path = NodePath("../TerrainRegistry") if with_terrain else NodePath()
	simulation.unit_minimum_spacing_debug_enabled = true
	simulation.unit_minimum_spacing_solver_iterations = 1
	scene.add_child(simulation)
	simulation.set_physics_process(false)
	return {"scene": scene, "registry": registry, "terrain": terrain, "simulation": simulation}


func _tile(terrain: Node, grid: Vector2i, height: int = 0, edge: String = "none", walkable: bool = true) -> void:
	terrain.register_tile(TILE.new({"tile_id": str(grid), "grid_position": grid, "world_position": terrain.grid_to_world(grid), "height_level": height, "edge_type": edge, "walkable": walkable, "surface_type": "ground"}))


func _add_units(context: Dictionary, position_a: Vector2, position_b: Vector2) -> void:
	for id in ["alpha", "bravo"]:
		var unit = UNIT.new()
		unit.unit_id = id
		unit.team_id = "team_alpha"
		unit.fireteam_id = "blue"
		unit.position = position_a if id == "alpha" else position_b
		context["scene"].add_child(unit)
		context["registry"].register_unit(id, unit)
		context[id] = unit


func _world_at(terrain: Node, grid: Vector2) -> Vector2:
	var origin: Vector2 = terrain.grid_to_world(Vector2i.ZERO)
	return origin + (Vector2(terrain.grid_to_world(Vector2i.RIGHT)) - origin) * grid.x + (Vector2(terrain.grid_to_world(Vector2i.DOWN)) - origin) * grid.y


func _tick(context: Dictionary, label: String) -> void:
	var simulation: Node = context["simulation"]
	simulation.call("_physics_process", 1.0 / 60.0)
	_assert(simulation.get_tick() == 1, label + " executes a real authoritative tick")
	_assert(simulation.command_queue.is_empty() and simulation.effects_queue.is_empty(), label + " spacing does not invent commands or effects")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: " + message)
	else:
		_failed += 1
		print("FAIL: " + message)
