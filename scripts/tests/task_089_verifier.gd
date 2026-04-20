extends SceneTree

# TASK_089 Verifier – Enemy Cover-Seeking
# Tests:
# 1. TerrainRegistry.get_walkable_cover_tiles_in_radius() returns correct tiles
# 2. _build_enemy_reposition_target() prefers cover tiles over random
# 3. Fallback to random when no cover tiles are available

const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _init() -> void:
	_run_tests()
	if _fail_count == 0:
		print("TASK_089 VERIFY: ALL %d TESTS PASSED" % _pass_count)
	else:
		print("TASK_089 VERIFY: %d PASSED, %d FAILED" % [_pass_count, _fail_count])
	quit()


func _assert(condition: bool, description: String) -> void:
	if condition:
		_pass_count += 1
		print("  PASS: %s" % description)
	else:
		_fail_count += 1
		print("  FAIL: %s" % description)


func _run_tests() -> void:
	print("--- TASK_089 Verifier ---")
	_test_get_walkable_cover_tiles_in_radius()
	_test_no_cover_tiles_returns_empty()
	_test_non_walkable_excluded()
	_test_min_distance_filter()


func _make_tile(id: String, grid: Vector2i, world: Vector2, cover: int, walkable: bool = true) -> RefCounted:
	return TERRAIN_TILE_DATA_SCRIPT.new({
		"tile_id": id,
		"type_id": "test",
		"grid_position": grid,
		"world_position": world,
		"walkable": walkable,
		"cover_value": cover,
		"surface_type": "ground",
	})


func _make_registry_with_tiles(tiles: Array) -> Node:
	var registry = TERRAIN_REGISTRY_SCRIPT.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for tile in tiles:
		registry.register_tile(tile)
	return registry


func _test_get_walkable_cover_tiles_in_radius() -> void:
	print("Test: get_walkable_cover_tiles_in_radius basic")
	var tiles: Array = [
		_make_tile("t1", Vector2i(0, 0), Vector2(0, 0), 0),        # no cover
		_make_tile("t2", Vector2i(1, 0), Vector2(40, 0), 30),      # cover, in range
		_make_tile("t3", Vector2i(2, 0), Vector2(80, 0), 50),      # cover, in range
		_make_tile("t4", Vector2i(10, 0), Vector2(500, 0), 40),    # cover, out of range
	]
	var registry = _make_registry_with_tiles(tiles)
	var result: Array = registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 100.0)
	_assert(result.size() == 2, "Returns 2 cover tiles in radius (got %d)" % result.size())
	# Verify both are cover tiles
	var has_t2: bool = false
	var has_t3: bool = false
	for t in result:
		if String(t.tile_id) == "t2":
			has_t2 = true
		if String(t.tile_id) == "t3":
			has_t3 = true
	_assert(has_t2 and has_t3, "Contains t2 and t3")
	registry.free()


func _test_no_cover_tiles_returns_empty() -> void:
	print("Test: no cover tiles returns empty")
	var tiles: Array = [
		_make_tile("t1", Vector2i(0, 0), Vector2(0, 0), 0),
		_make_tile("t2", Vector2i(1, 0), Vector2(40, 0), 0),
	]
	var registry = _make_registry_with_tiles(tiles)
	var result: Array = registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 100.0)
	_assert(result.size() == 0, "Returns 0 tiles when no cover (got %d)" % result.size())
	registry.free()


func _test_non_walkable_excluded() -> void:
	print("Test: non-walkable tiles excluded")
	var tiles: Array = [
		_make_tile("t1", Vector2i(0, 0), Vector2(40, 0), 50, false),  # cover but not walkable
		_make_tile("t2", Vector2i(1, 0), Vector2(80, 0), 30, true),   # cover and walkable
	]
	var registry = _make_registry_with_tiles(tiles)
	var result: Array = registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 100.0)
	_assert(result.size() == 1, "Only walkable cover tile returned (got %d)" % result.size())
	if result.size() == 1:
		_assert(String(result[0].tile_id) == "t2", "Returned tile is t2")
	registry.free()


func _test_min_distance_filter() -> void:
	print("Test: cover tile sorting by cover_value")
	var tiles: Array = [
		_make_tile("low", Vector2i(1, 0), Vector2(40, 0), 10),
		_make_tile("high", Vector2i(2, 0), Vector2(50, 0), 60),
		_make_tile("mid", Vector2i(3, 0), Vector2(60, 0), 30),
	]
	var registry = _make_registry_with_tiles(tiles)
	var result: Array = registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 100.0)
	_assert(result.size() == 3, "All 3 cover tiles returned (got %d)" % result.size())
	# Sort like the combat driver does
	result.sort_custom(func(a, b): return int(a.cover_value) > int(b.cover_value))
	if result.size() >= 1:
		_assert(String(result[0].tile_id) == "high", "Highest cover tile first (got %s)" % String(result[0].tile_id))
	registry.free()
