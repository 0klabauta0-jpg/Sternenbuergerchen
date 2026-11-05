extends SceneTree
## Exact old-query oracle plus observable bounded world-position reads.
const REGISTRY := preload("res://scripts/terrain/terrain_registry.gd")
var _passed := 0
var _failed := 0


class CountingTile:
	extends RefCounted
	var tile_id := ""
	var grid_position := Vector2i.ZERO
	var stored_world := Vector2.ZERO
	var world_reads := 0
	var world_position: Vector2:
		get:
			world_reads += 1
			return stored_world
	var walkable := true
	var cover_value := 50
	func is_valid() -> bool:
		return not tile_id.is_empty()


class LegacyRegistry extends "res://scripts/terrain/terrain_registry.gd":
	func get_walkable_cover_tiles_in_radius(center: Vector2, radius: float) -> Array:
		var result: Array = []
		for tile in _tiles.values():
			if center.distance_squared_to(tile.world_position) > radius * radius:
				continue
			if not is_walkable(tile.grid_position) or get_cover_at(tile.grid_position) <= 0:
				continue
			result.append(tile)
		return result


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		_test_world_index(topology)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("PLAYTEST_COVER_QUERY_SPATIAL_ALL_PASS" if _failed == 0 else "PLAYTEST_COVER_QUERY_SPATIAL_FAILED")
	quit(0 if _failed == 0 else 1)


func _check(ok: bool, label: String) -> void:
	if ok:
		_passed += 1
		print("PASS: ", label)
	else:
		_failed += 1
		print("FAIL: ", label)


func _tile(index: int, world: Vector2) -> CountingTile:
	var tile := CountingTile.new()
	tile.tile_id = "tile_%d" % index
	# Intentionally unrelated to stored world positions: no affine-grid shortcut.
	tile.grid_position = Vector2i(index * 7 - 44, -index * 3 + 19)
	tile.stored_world = world
	return tile


func _test_world_index(topology: String) -> void:
	var registry = REGISTRY.new()
	var legacy := LegacyRegistry.new()
	var tiles: Array = []
	for item in [registry, legacy]:
		item.configure_iso_grid(Vector2(111, -37), 64.0, 32.0, topology)
	for index in range(3000):
		var position := Vector2(index * 331.0, (index % 11) * 373.0)
		if index < 7:
			position = Vector2(index * 4.0 - 12.0, 0.0)
		var tile := _tile(index, position)
		tiles.append(tile)
		registry.register_tile(tile)
		legacy.register_tile(tile)
	var expected: Array = legacy.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0)
	_check(registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0) == expected, topology + ": exact radius, same objects and insertion order")
	for tile in tiles:
		tile.world_reads = 0
	var actual: Array = registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0)
	var reads := 0
	for tile in tiles:
		reads += tile.world_reads
	_check(actual == expected, topology + ": repeated query preserves exact result")
	_check(reads <= 32, topology + ": warm local query reads nearby world positions, not all 3000 tiles (actual %d)" % reads)
	tiles[2].walkable = false
	tiles[4].cover_value = 0
	_check(registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0) == legacy.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0), topology + ": live eligibility is read even without a revision change")
	for item in [registry, legacy]:
		item.set_runtime_tile_overrides([{"grid_position": tiles[2].grid_position, "walkable_override": true}, {"grid_position": tiles[4].grid_position, "cover_value_override": 80}])
	_check(registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0) == legacy.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0), topology + ": runtime override eligibility stays exact")
	tiles[1000].stored_world = Vector2(0, 1)
	for item in [registry, legacy]:
		item.notify_tile_data_changed([tiles[1000].grid_position])
	_check(registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0) == legacy.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0), topology + ": notified in-place world relocation rebuilds the derived index")
	var replacement := _tile(0, Vector2(0, 2))
	for item in [registry, legacy]:
		item.register_tile(replacement)
	var replaced: Array = registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0)
	_check(replaced == legacy.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0) and replaced[0] == replacement, topology + ": replacement retains dictionary insertion priority")
	var added := _tile(9000, Vector2(1, 1))
	for item in [registry, legacy]:
		item.register_tile(added)
	_check(registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, -12.0) == legacy.get_walkable_cover_tiles_in_radius(Vector2.ZERO, -12.0), topology + ": added cells and negative radius semantics remain exact")
	for item in [registry, legacy]:
		item.clear_tiles()
		item.register_tile(added)
	_check(registry.get_walkable_cover_tiles_in_radius(Vector2.ZERO, 12.0) == [added], topology + ": clear and re-register releases obsolete index entries")
	registry.free()
	legacy.free()
