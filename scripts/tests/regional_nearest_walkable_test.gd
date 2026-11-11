extends SceneTree

const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")

var _checks := 0
var _failures := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var map = MAP.load_from_file("res://maps/trade_outpost.json")
	var registry := REGISTRY.new()
	var size: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), size.half_width, size.half_height, map.get_grid_topology())
	for tile in map.get_tiles():
		registry.register_tile(tile)
	registry.prepare_spatial_queries()
	var random := RandomNumberGenerator.new()
	random.seed = 11493
	var tiles: Array = registry.get_all_tiles()
	for index in range(48):
		var tile = tiles[random.randi_range(0, tiles.size() - 1)]
		var target: Vector2 = tile.world_position + Vector2(random.randf_range(-90, 90), random.randf_range(-90, 90))
		var expected: Variant = registry.call("_nearest_walkable_in_tiles", target, tiles)
		_check(registry.get_nearest_walkable_grid(target) == expected, "Indexed nearest matches exhaustive target %d" % index)
	var grid: Vector2i = tiles[tiles.size() / 2].grid_position
	registry.set_runtime_tile_overrides([{"grid_position": grid, "walkable_override": false}])
	var position: Vector2 = registry.grid_to_world(grid)
	_check(registry.get_nearest_walkable_grid(position) == registry.call("_nearest_walkable_in_tiles", position, tiles), "Door override is live in spatial query")
	var outside := Vector2(1000000, -1000000)
	_check(registry.get_nearest_walkable_grid(outside) == registry.call("_nearest_walkable_in_tiles", outside, tiles), "Distant query retains exhaustive fallback")
	registry.free()
	print("Regional nearest: %d checks, %d failures" % [_checks, _failures])
	quit(1 if _failures else 0)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
