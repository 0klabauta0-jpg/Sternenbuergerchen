extends RefCounted
## Deterministic navigation-only fixtures. No actors, scene tree or save writes.
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const GRAPH = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const GM01 = "res://maps/Ground_Mission01_32x32.json"

static func synthetic(topology: String, width: int = 18, height: int = 16, offset := Vector2i(-4, -3), varied: bool = true):
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0, topology)
	var surfaces := ["ground", "road", "sand", "rock", "water"]
	for x in range(width):
		for y in range(height):
			var grid := offset + Vector2i(x, y)
			var blocked: bool = varied and x == int(width / 2) and y not in [2, height - 3]
			var high: bool = varied and x >= width - 5
			var data := {
				"tile_id": "native_fixture_%d_%d" % [grid.x, grid.y],
				"grid_position": grid, "world_position": registry.grid_to_world(grid),
				"walkable": not blocked, "blocks_los": blocked,
				"object_height": 2 if blocked else 0,
				"surface_type": surfaces[(x + y * 3) % surfaces.size()] if varied else "ground",
				"height_level": 1 if high else 0,
				"edge_type": "slope" if high and y % 3 == 1 else "cliff",
				"cover_value": (x * 13 + y * 7) % 101 if varied else 0,
			}
			registry.register_tile(TILE.new(data))
	return registry

static func real_map():
	# Decode the saved fields into the same TerrainTileData used by runtime.
	# GM01 contains no legacy-wall entries requiring editor migration.
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(GM01))
	var origin: Dictionary = raw.get("grid_origin", {})
	var tile_size: Dictionary = raw.get("tile_size", {})
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2(origin.get("x", 0.0), origin.get("y", 0.0)),
		float(tile_size.get("half_width", 64.0)), float(tile_size.get("half_height", 32.0)), String(raw.get("grid_topology", "square8")))
	for entry in raw.get("tiles", []):
		var data: Dictionary = entry.duplicate(true)
		var position: Dictionary = data["grid_position"]
		var grid := Vector2i(int(position["x"]), int(position["y"]))
		data["grid_position"] = grid
		data["tile_id"] = "tile_%d_%d" % [grid.x, grid.y]
		data["world_position"] = registry.grid_to_world(grid)
		registry.register_tile(TILE.new(data))
	return registry

static func graph_for(registry, cluster_size: int = 8):
	var graph = GRAPH.new()
	graph.build_from_registry(registry, cluster_size)
	return graph

static func query_pairs(registry, count: int) -> Array:
	var walkable: Array = []
	for tile in registry.get_all_tiles():
		if registry.is_walkable(tile.grid_position):
			walkable.append(tile.grid_position)
	var pairs: Array = []
	for index in range(count):
		var source: int = (index * 47 + 13) % walkable.size()
		var target: int = (source + int(walkable.size() / 2) + index * 31 + 17) % walkable.size()
		pairs.append([walkable[source], walkable[target]])
	return pairs

static func option_sets() -> Array:
	return [
		{},
		{"cover_aware_enabled": true, "cover_weight": 0.9, "exposure_weight": 1.7,
			"hazard_grids": [Vector2i(-2, 0), Vector2i(11, 10)]},
		{"cover_aware_enabled": true, "cover_weight": 0.4, "exposure_weight": 2.1,
			"exposure_by_grid": {Vector2i(1, 1): 0.75, Vector2i(2, 1): 0.25}},
		{"corridor_enabled": true, "corridor_weight": 0.8, "corridor_half_width_grid": 1.2,
			"corridor_from_grid": Vector2i(-3, -2), "corridor_to_grid": Vector2i(12, 11)},
		{"lane_enabled": true, "lane_weight": 0.7, "lane_offset_grid": -1.5,
			"corridor_from_grid": Vector2i(-3, -2), "corridor_to_grid": Vector2i(12, 11)},
		{"blocker_clearance_weight": 0.8, "blocker_clearance_radius": 2},
		{"cover_aware_enabled": true, "cover_weight": -2.0, "exposure_weight": -1.0,
			"corridor_enabled": true, "corridor_weight": -1.0, "lane_enabled": true, "lane_weight": -2.0},
	]

static func argument(name: String, default_value: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(name + "="):
			return arg.substr(name.length() + 1)
	return default_value

static func write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write evidence: " + path)
		return false
	file.store_string(JSON.stringify(data, "\t", true))
	return true
