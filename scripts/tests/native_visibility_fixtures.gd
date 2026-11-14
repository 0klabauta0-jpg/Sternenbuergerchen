extends RefCounted
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REG = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const LOS = preload("res://scripts/core/los_system.gd")

static func gm01() -> Node:
	var map = MAP.load_from_file("res://maps/Ground_Mission01_32x32.json")
	var registry = REG.new()
	var size: Dictionary = map.get_tile_size()
	registry.configure_iso_grid(map.get_grid_origin(), size.half_width, size.half_height, map.get_grid_topology())
	for tile in map.get_tiles(): registry.register_tile(tile)
	registry.prepare_spatial_queries()
	return registry

static func synthetic(topology: String = "hex_axial_v1") -> Node:
	var registry = REG.new()
	registry.configure_iso_grid(Vector2.ZERO, 16.0, 8.0, topology)
	for q in range(-12, 25):
		for r in range(-12, 25):
			var grid := Vector2i(q, r)
			var blocked: bool = (q * 7 + r * 13) % 23 == 0
			registry.register_tile(TILE.from_dict({"tile_id": "tile_%d_%d" % [q, r], "type_id": "ground_flat",
				"grid_position": grid, "world_position": registry.grid_to_world(grid), "height_level": posmod(q + r, 3),
				"blocks_los": blocked, "object_height": 2 if blocked else 0, "walkable": not blocked}))
	return registry

static func pairs(registry: Node, count: int) -> Array:
	var tiles: Array = registry.call("get_sorted_tiles")
	var result: Array = []
	for index in range(count):
		var source: int = (index * 47 + 13) % tiles.size()
		var target: int = (source + 127 + index * 29) % tiles.size()
		if source == target: target = (target + 1) % tiles.size()
		result.append([tiles[source].grid_position, tiles[target].grid_position])
	return result

static func los(native_enabled: bool):
	var result = LOS.new()
	if result.has_method("set_native_visibility_enabled"):
		result.call("set_native_visibility_enabled", native_enabled)
	return result

static func audit(reader) -> Dictionary:
	return reader.call("get_native_visibility_snapshot") if reader.has_method("get_native_visibility_snapshot") else {"native_calls": 0, "available": false}

static func argument(name: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(name + "="): return arg.substr(name.length() + 1)
	return fallback

static func write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(data, "\t", true))
	return true
