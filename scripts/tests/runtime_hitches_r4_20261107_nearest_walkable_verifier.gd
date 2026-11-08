extends SceneTree
## Source-local parity/work verifier. No scene, actors, renderer or ms budget.
const TILE_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP_PATH := "res://maps/Ground_Mission01_32x32.json"

class CountingRegistry extends "res://scripts/terrain/terrain_registry.gd":
	var walkability_reads: int = 0
	func is_walkable(grid_pos: Vector2i) -> bool:
		walkability_reads += 1
		return super.is_walkable(grid_pos)

class ExhaustiveOracle extends "res://scripts/terrain/terrain_registry.gd":
	# Frozen original methods from Registry SHA256 4699ae88...5c55f.
	# Bodies, insertion order and squared-distance epsilon are unchanged.
	func get_nearest_walkable_grid(world_pos: Vector2) -> Variant:
		var nearest_grid: Variant = null
		var nearest_distance: float = INF
		for tile_data in _tiles.values():
			var grid_position: Vector2i = Vector2i(tile_data.grid_position)
			if not is_walkable(grid_position):
				continue
			var distance_to_tile: float = world_pos.distance_squared_to(tile_data.world_position)
			if not _is_nearest_candidate_better(distance_to_tile, grid_position, nearest_distance, nearest_grid):
				continue

			nearest_distance = distance_to_tile
			nearest_grid = grid_position

		return nearest_grid

	func _is_grid_before(a: Vector2i, b: Vector2i) -> bool:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x

	func _is_nearest_candidate_better(distance_to_tile: float, grid_position: Vector2i, nearest_distance: float, nearest_grid: Variant) -> bool:
		if typeof(nearest_grid) != TYPE_VECTOR2I:
			return true
		if distance_to_tile < nearest_distance - 0.001:
			return true
		if absf(distance_to_tile - nearest_distance) <= 0.001:
			return _is_grid_before(grid_position, Vector2i(nearest_grid))
		return false

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		_test_counter_red(topology)
		_test_empty_blocked_and_live_changes(topology)
		_test_ties(topology)
		_test_small_query_set(topology)
	_test_authored_gm01()
	print("R4_NEAREST_WALKABLE_RESULTS ", JSON.stringify({"passed": passed, "failed": failed, "timing_thresholds": false}))
	if failed == 0:
		print("R4_NEAREST_WALKABLE_PASS")
	quit(0 if failed == 0 else 1)


func _context(topology: String) -> Dictionary:
	var probe := CountingRegistry.new()
	var oracle := ExhaustiveOracle.new()
	for registry in [probe, oracle]:
		registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, topology)
	return {"probe": probe, "oracle": oracle, "topology": topology}


func _tile(context: Dictionary, grid: Vector2i, walkable: bool = true, world: Variant = null):
	var position: Vector2 = context.probe.grid_to_world(grid) if world == null else Vector2(world)
	var tile = TILE_SCRIPT.new({"tile_id": "tile_%d_%d" % [grid.x, grid.y], "grid_position": grid, "world_position": position, "walkable": walkable, "surface_type": "ground", "type_id": "ground_flat"})
	context.probe.register_tile(tile)
	context.oracle.register_tile(tile)
	return tile


func _free(context: Dictionary) -> void:
	context.probe.free()
	context.oracle.free()


func _fingerprint(registry) -> PackedByteArray:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(var_to_bytes([registry.get_revision(), registry.get_dirty_grid_positions()]))
	for tile in registry.get_all_tiles():
		hash.update(var_to_bytes([tile.to_dict(), registry.get_runtime_tile_override(tile.grid_position)]))
	return hash.finish()


func _queries(context: Dictionary, points: Array, label: String) -> void:
	var before: PackedByteArray = _fingerprint(context.probe)
	var mismatches: Array = []
	for index in range(points.size()):
		var point: Vector2 = Vector2(points[index])
		var actual: Variant = context.probe.get_nearest_walkable_grid(point)
		var expected: Variant = context.oracle.get_nearest_walkable_grid(point)
		if actual != expected:
			mismatches.append({"query": index, "point": str(point), "actual": str(actual), "expected": str(expected)})
		var resolution: Dictionary = context.probe.resolve_walkable_target(point)
		var original_resolution: Dictionary = context.oracle.resolve_walkable_target(point)
		if var_to_bytes(resolution) != var_to_bytes(original_resolution):
			mismatches.append({"resolution_query": index, "point": str(point)})
	check(mismatches.is_empty(), "%s nearest and complete resolution content match original oracle (%d queries)" % [label, points.size()])
	if not mismatches.is_empty():
		print("R4_NEAREST_WALKABLE_MISMATCH ", JSON.stringify(mismatches))
	check(_fingerprint(context.probe) == before, "%s querys preserve tiles, overrides, revision and dirty grids" % label)


func _test_counter_red(topology: String) -> void:
	var context := _context(topology)
	_tile(context, Vector2i.ZERO, true, Vector2(1.0, 0.0))
	_tile(context, Vector2i(1, 0), false, Vector2.ZERO)
	for index in range(256):
		_tile(context, Vector2i(index + 2, 0), index % 3 != 0, Vector2(1000.0 + index * 64.0, 500.0))
	context.probe.walkability_reads = 0
	var actual: Variant = context.probe.get_nearest_walkable_grid(Vector2.ZERO)
	var calls: int = context.probe.walkability_reads
	var expected: Variant = context.oracle.get_nearest_walkable_grid(Vector2.ZERO)
	check(actual == expected and actual == Vector2i.ZERO, "%s counter fixture keeps the near walkable winner despite a closer blocker" % topology)
	check(calls <= 4, "%s distance guard rejects distant candidates before live walkability reads (actual %d / %d tiles)" % [topology, calls, context.probe.get_tile_count()])
	print("R4_NEAREST_WALKABLE_COUNTS ", JSON.stringify({"topology": topology, "tiles": context.probe.get_tile_count(), "live_walkability_reads": calls, "expected_max_reads": 4, "same_selection": actual == expected}))
	_free(context)


func _test_empty_blocked_and_live_changes(topology: String) -> void:
	var context := _context(topology)
	_queries(context, [Vector2.ZERO, Vector2(-512.0, 937.0)], topology + " empty")
	check(context.probe.get_nearest_walkable_grid(Vector2.ZERO) == null, topology + " empty nearest is null")
	var a = _tile(context, Vector2i.ZERO, false, Vector2.ZERO)
	var b = _tile(context, Vector2i(1, 0), false, Vector2(100.0, 0.0))
	var c = _tile(context, Vector2i(2, 0), false, Vector2(200.0, 0.0))
	_queries(context, [Vector2.ZERO, Vector2(25.0, 0.0)], topology + " all blocked")
	check(context.probe.get_nearest_walkable_grid(Vector2.ZERO) == null, topology + " all-blocked nearest is null")
	var revision: int = context.probe.get_revision()
	a.walkable = true
	b.walkable = true
	c.walkable = true
	_queries(context, [Vector2(25.0, 0.0)], topology + " direct walkable true without notify")
	a.walkable = false
	_queries(context, [Vector2(25.0, 0.0)], topology + " direct walkable false without notify")
	check(context.probe.get_nearest_walkable_grid(Vector2(25.0, 0.0)) == Vector2i(1, 0), topology + " direct walkability changes selection immediately")
	b.world_position = Vector2(1000.0, 0.0)
	_queries(context, [Vector2(25.0, 0.0), Vector2(999.0, 0.0)], topology + " direct world position without notify")
	check(context.probe.get_nearest_walkable_grid(Vector2(25.0, 0.0)) == Vector2i(2, 0), topology + " direct world position changes nearest immediately")
	b.grid_position = Vector2i(99, 99)
	_queries(context, [Vector2(999.0, 0.0)], topology + " direct grid position preserves original lookup semantics")
	check(context.probe.get_revision() == revision, topology + " direct in-place fixtures genuinely have no revision bump")
	b.grid_position = Vector2i(1, 0)
	for registry in [context.probe, context.oracle]:
		registry.set_runtime_tile_overrides([{"grid_position": Vector2i(2, 0), "walkable_override": false}, {"grid_position": Vector2i.ZERO, "walkable_override": true}])
	_queries(context, [Vector2.ZERO, Vector2(200.0, 0.0), Vector2(1000.0, 0.0)], topology + " runtime overrides")
	for registry in [context.probe, context.oracle]:
		registry.clear_runtime_tile_overrides()
	_queries(context, [Vector2.ZERO, Vector2(200.0, 0.0)], topology + " cleared overrides")
	_tile(context, Vector2i(2, 0), false, Vector2(5.0, 0.0))
	_queries(context, [Vector2.ZERO, Vector2(200.0, 0.0)], topology + " reregister replaces tile")
	for registry in [context.probe, context.oracle]:
		registry.clear_tiles()
	_queries(context, [Vector2.ZERO], topology + " clear after populated queries")
	_tile(context, Vector2i(-4, 3), true, Vector2(17.0, -31.0))
	_queries(context, [Vector2.ZERO], topology + " registration after clear")
	_free(context)


func _test_ties(topology: String) -> void:
	# These are squared-distance deltas; 0.001 is the ORIGINAL epsilon.
	for item in [[1.0, true, "exact"], [1.0005, true, "inside epsilon"], [1.002, false, "outside epsilon"]]:
		var context := _context(topology)
		_tile(context, Vector2i(5, 5), true, Vector2(1.0, 0.0))
		_tile(context, Vector2i(-5, -5), true, Vector2(sqrt(float(item[0])), 0.0))
		_queries(context, [Vector2.ZERO], topology + " " + String(item[2]))
		var expected: Vector2i = Vector2i(-5, -5) if bool(item[1]) else Vector2i(5, 5)
		check(context.probe.get_nearest_walkable_grid(Vector2.ZERO) == expected, topology + " explicit " + String(item[2]) + " tie expectation")
		_free(context)
	var context := _context(topology)
	_tile(context, Vector2i(0, 5), true, Vector2(1.0, 0.0))
	_tile(context, Vector2i(0, -5), true, Vector2(-1.0, 0.0))
	_queries(context, [Vector2.ZERO], topology + " grid Y tie")
	check(context.probe.get_nearest_walkable_grid(Vector2.ZERO) == Vector2i(0, -5), topology + " equal X ties use lower grid Y")
	_free(context)
	context = _context(topology)
	_tile(context, Vector2i(-5, -5), true, Vector2(1.0, 0.0))
	_tile(context, Vector2i(5, 5), true, Vector2(sqrt(0.9995), 0.0))
	_queries(context, [Vector2.ZERO], topology + " nearer within epsilon keeps lower grid")
	check(context.probe.get_nearest_walkable_grid(Vector2.ZERO) == Vector2i(-5, -5), topology + " tiny distance gain does not bypass original tie rule")
	_free(context)
	context = _context(topology)
	_tile(context, Vector2i(5, 5), true, Vector2(10.0, 0.0))
	_tile(context, Vector2i.ZERO, false, Vector2.ZERO)
	_tile(context, Vector2i(1, 1), true, Vector2(1.0, 0.0))
	_queries(context, [Vector2.ZERO], topology + " blocked candidate cannot lower best distance")
	check(context.probe.get_nearest_walkable_grid(Vector2.ZERO) == Vector2i(1, 1), topology + " later nearer walkable beats earlier farther winner after blocker")
	_free(context)


func _test_small_query_set(topology: String) -> void:
	var context := _context(topology)
	for x in range(-8, 9):
		for y in range(-6, 7):
			_tile(context, Vector2i(x, y), posmod(x * 7 + y * 11, 6) != 0)
	var points: Array = [Vector2.ZERO, Vector2(-8192.0, -8192.0), Vector2(8192.0, 8192.0)]
	for index in range(20):
		points.append(context.probe.grid_to_world(Vector2i(posmod(index * 37, 29) - 14, posmod(index * 19, 23) - 11)) + Vector2(index % 3 * 0.37, index % 5 * -0.29))
	_queries(context, points, topology + " deterministic broad small map")
	_free(context)


func _test_authored_gm01() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
	if not check(raw is Dictionary, "Authored GM01 JSON loads"):
		return
	var context := _context(String(raw.get("grid_topology", "square8")))
	var points: Array = [Vector2(-190.3526, 424.1103), Vector2(-265.7278, 473.1773), Vector2.ZERO, Vector2(-10000.0, -10000.0), Vector2(10000.0, 10000.0)]
	var blocked_points: Array = []
	for data in Array(raw.get("tiles", [])):
		var grid_data: Dictionary = Dictionary(data.get("grid_position", {}))
		var grid := Vector2i(int(grid_data.get("x", 0)), int(grid_data.get("y", 0)))
		var tile = _tile(context, grid, bool(data.get("walkable", true)))
		if not tile.walkable and blocked_points.size() < 4:
			blocked_points.append(tile.world_position)
	check(context.probe.get_tile_count() == 9408, "Representative authored GM01 retains all 9408 tiles")
	check(blocked_points.size() == 4, "Representative GM01 querys include four actual blocked tile centers")
	points.append_array(blocked_points)
	for index in range(7):
		points.append(context.probe.grid_to_world(Vector2i(posmod(index * 47, 173) - 70, posmod(index * 31, 151) - 45)) + Vector2(13.25, -7.75))
	_queries(context, points, "GM01 actual tile positions and deterministic broad queries")
	for point in blocked_points:
		var resolution: Dictionary = context.probe.resolve_walkable_target(point)
		check(not bool(resolution.get("target_walkable", true)) and typeof(resolution.get("replacement_grid")) == TYPE_VECTOR2I, "Actual GM01 blocked target recovers to a walkable grid")
	_free(context)


func check(condition: bool, message: String) -> bool:
	if condition:
		passed += 1
		print("PASS: ", message)
	else:
		failed += 1
		push_error("FAIL: " + message)
	return condition
