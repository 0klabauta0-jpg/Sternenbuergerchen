extends SceneTree
## Authored data audit -> actual MapData/TerrainRegistry, no visual substitute.
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PATHFINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const AUDIT := "res://docs/qa/review_completion_20261113/station_nature_clusters.json"
var passed := 0
var failed := 0

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ", label)

func point(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func facts_match(tile, expected: Dictionary) -> bool:
	return tile != null and tile.type_id == expected.type_id and tile.surface_type == expected.surface_type \
		and tile.height_level == int(expected.height_level) and tile.edge_type == expected.edge_type \
		and tile.walkable == bool(expected.walkable) and tile.blocks_los == bool(expected.blocks_los) \
		and tile.cover_value == int(expected.cover_value) and tile.object_height == int(expected.object_height) \
		and tile.object_type_id == String(expected.get("object_type_id", "")) \
		and tile.object_rotation_degrees == float(expected.get("object_rotation_degrees", 0.0)) \
		and tile.object_scale == float(expected.get("object_scale", 1.0))

func _run() -> void:
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AUDIT))
	check(audit.get("schema") == "station_nature_clusters_v1" and audit.get("maps", []).size() == 2, "exact bounded two-map nature migration is recorded")
	for record: Dictionary in audit.get("maps", []):
		verify_map(record)
		await process_frame
	print("STATION_NATURE_CLUSTERS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func verify_map(record: Dictionary) -> void:
	var path: String = record.map
	var label: String = path.get_file()
	check(FileAccess.get_file_as_string(path).sha256_text() == record.after_sha256, label + " actual map bytes match audited revision")
	var map = MAP.load_from_file(path)
	var registry = REGISTRY.new()
	root.add_child(registry)
	registry.configure_iso_grid(map.get_grid_origin(), map.get_tile_size().half_width, map.get_tile_size().half_height, map.get_grid_topology())
	var nature_count := 0
	for tile in map.get_tiles():
		registry.register_tile(tile)
		if tile.object_type_id in ["nature_rock_cover", "nature_tree_blocker"]: nature_count += 1
	check(map.get_grid_topology() == "hex_axial_v1" and nature_count == int(record.nature_count), label + " actual map preserves topology and every existing nature object")
	var protected: Dictionary = {}
	for grid: Array in record.protected_cells: protected[point(grid)] = true
	var forbidden_pipes: Dictionary = {}
	for grid: Array in record.original_and_relocated_pipe_cells: forbidden_pipes[point(grid)] = true
	var disjoint: Dictionary = {}
	var complete_facts := true
	var real_blockers := true
	var safe_cells := true
	var bounded := true
	for move: Dictionary in record.moves:
		var origin := point(move.from)
		var target := point(move.to)
		var old_tile = registry.get_tile_at_grid(origin)
		var new_tile = registry.get_tile_at_grid(target)
		complete_facts = complete_facts and facts_match(old_tile, move.target_before) and facts_match(new_tile, move.source_before)
		real_blockers = real_blockers and registry.is_walkable(origin) and not registry.blocks_los_at_grid(origin) and registry.get_cover_at(origin) == 0 \
			and not registry.is_walkable(target) and registry.blocks_los_at_grid(target) and registry.get_cover_at(target) == int(move.source_before.cover_value)
		safe_cells = safe_cells and not protected.has(origin) and not protected.has(target) and not forbidden_pipes.has(origin) and not forbidden_pipes.has(target) \
			and not disjoint.has(origin) and not disjoint.has(target) and old_tile.edge_type == "none" and new_tile.edge_type == "none" \
			and old_tile.ramp_direction == -1 and new_tile.ramp_direction == -1 and old_tile.type_id == new_tile.type_id and old_tile.height_level == new_tile.height_level
		disjoint[origin] = true
		disjoint[target] = true
		bounded = bounded and HEX.distance(origin, target) > 0 and HEX.distance(origin, target) <= int(record.max_hex_distance)
	check(complete_facts, label + " exact object identity rotation scale height cover and LOS move with each real tile")
	check(real_blockers, label + " every old cell is truly free and every new cell is truly blocked in TerrainRegistry")
	check(safe_cells and bounded and record.moves.size() == int(record.moved_count) and not record.moves.is_empty(), label + " disjoint bounded moves avoid protected terrain and all removed-pipe provenance cells")
	# Ask the actual pathfinder, rather than inferring navigation from a visual.
	var pathfinder = PATHFINDER.new()
	var reached_source := false
	var rejected_target := false
	for move: Dictionary in record.moves:
		var origin := point(move.from)
		for neighbor: Vector2i in HEX.neighbors(origin):
			if not registry.is_walkable(neighbor): continue
			var route: Array = pathfinder.find_path(neighbor, origin, registry)
			if not route.is_empty() and route.back() == origin:
				reached_source = true
				rejected_target = pathfinder.find_path(neighbor, point(move.to), registry).is_empty()
				break
		if reached_source: break
	check(reached_source, label + " actual Hex navigation enters a vacated source cell")
	check(rejected_target, label + " actual Hex navigation rejects the relocated blocker target")
	registry.free()
