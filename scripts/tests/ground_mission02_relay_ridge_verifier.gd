extends SceneTree
## Rebuilt Ground Mission 02 "Relay Ridge": data checks for maps/Ground_Mission02_128x128.json. Headless.
## Uses the game's own tile rules (allows_step), not the generator's copy.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const PATH := "res://maps/Ground_Mission02_128x128.json"
const SCENARIO := "res://data/mission_scenarios/ground_mission02_128x128.json"
var passed := 0
var failed := 0


func _initialize() -> void:
	call_deferred("run")


func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print(("PASS " if value else "FAIL ") + label)


func run() -> void:
	var map = MAP.load_from_file(PATH)
	check(map != null and not map.has_load_issue(), "map loads without a load issue")
	var tiles: Array = map.get_tiles()
	check(tiles.size() == 128 * 128 and map.get_grid_size() == Vector2i(128, 128), "all 16384 cells of the 128 x 128 grid are valid tiles")
	check(String(map.get_terrain_visual_theme_id()) == "frontier_illustrated_v1", "frontier look instead of the old mixed theme")
	check(map.get_grid_topology() == "hex_axial_v1" and map.get_tactical_grid_rules() == "hex_tactical_v1", "hex topology and tactical rules")
	check(map.get_terrain_height_rules() == TILE.EXPLICIT_HEIGHT_RULES and is_equal_approx(map.get_regional_height_step(), 0.75), "explicit ramp height rules, 0.75 step")
	var by_cell: Dictionary = {}
	var ramps := 0
	var solids := 0
	var station_block := 0
	for tile in tiles:
		by_cell[tile.grid_position] = tile
		if TILE.is_explicit_ramp(tile): ramps += 1
		if String(tile.object_type_id) == "frontier_scene_solid": solids += 1
		if String(tile.type_id).begins_with("station_set") or String(tile.type_id).begins_with("modular_") or String(tile.object_type_id).begins_with("station_set"): station_block += 1
	check(ramps == 24, "four ramps with 24 ramp cells")
	check(solids > 40, "buildings and large props reserve blocked cells")
	check(station_block == 0, "the old station-floor block is gone")
	for marker_id in ["spawn_alpha", "spawn_bravo", "objective_point", "objective_ridge_aa", "spawn_enemy_defense", "spawn_enemy_patrol", "spawn_enemy_air_defense"]:
		check(map.has_marker(marker_id), "marker present: " + marker_id)

	# Flood from the landing field with the game's step rule.
	var start = _tile_at_world(map, by_cell, map.get_marker_position("spawn_alpha"))
	var seen: Dictionary = {}
	if start != null:
		seen[start.grid_position] = true
		var queue: Array = [start]
		while not queue.is_empty():
			var current = queue.pop_back()
			for direction: Vector2i in HEX.DIRECTIONS:
				var next = by_cell.get(current.grid_position + direction)
				if next == null or seen.has(next.grid_position) or not next.walkable:
					continue
				if TILE.allows_step(current, next):
					seen[next.grid_position] = true
					queue.append(next)
	check(seen.size() > 4000, "most of the map is one connected walkable area (%d cells)" % seen.size())
	for marker_id: String in map.get_marker_ids():
		var tile = _tile_at_world(map, by_cell, map.get_marker_position(marker_id))
		check(tile != null and tile.walkable and seen.has(tile.grid_position), "marker reachable from the landing field: " + marker_id)
	for route_id: String in map.get_patrol_paths():
		var reachable := true
		for point in map.get_patrol_path(route_id):
			var tile = _tile_at_world(map, by_cell, Vector2(point.x, point.y) if point is Dictionary else point)
			reachable = reachable and tile != null and seen.has(tile.grid_position)
		check(reachable, "patrol route stays on reachable cells: " + route_id)
	var levels: Dictionary = {}
	for marker_id in ["spawn_alpha", "spawn_enemy_defense", "objective_point"]:
		levels[marker_id] = int(_tile_at_world(map, by_cell, map.get_marker_position(marker_id)).height_level)
	check(levels.spawn_alpha == 0 and levels.spawn_enemy_defense == 2 and levels.objective_point == 2, "landing field on low ground, defenders and relay objective on the plateau")
	check(by_cell.get(Vector2i(16, 104)) != null and by_cell[Vector2i(16, 104)].walkable and by_cell[Vector2i(109, 34)].walkable and by_cell[Vector2i(84, 82)].walkable, "spawn and objective cells of the old map stay walkable")

	var presentation: Dictionary = map.get_place_presentation()
	var missing: Array = []
	var kit := 0
	var existing := 0
	for prop: Dictionary in presentation.get("props", []):
		var path := String(prop.get("path", ""))
		if not ResourceLoader.exists(path): missing.append(path)
		if path.contains("windbruch_kit_20261114"): kit += 1
		else: existing += 1
	check(missing.is_empty(), "every placed model exists (%s)" % str(missing))
	check(kit > 20 and existing >= 1, "kit pieces plus existing project models (%d / %d)" % [kit, existing])
	check(Array(presentation.get("pads", [])).size() == 2, "two landing pads")
	for pad: Dictionary in presentation.get("pads", []):
		var flat := true
		for tile in tiles:
			var plane: Vector2 = HEX.axial_to_plane(Vector2(tile.grid_position))
			if absf(plane.x - float(pad.center[0])) < float(pad.size[0]) * 0.5 and absf(plane.y - float(pad.center[1])) < float(pad.size[1]) * 0.5:
				flat = flat and int(tile.height_level) == 0 and not TILE.is_explicit_ramp(tile)
		check(flat, "pad stands on flat level-0 ground: " + String(pad.name))
	# The unchanged scenario validates against the rebuilt map with the project's own validator.
	var scenario = load("res://scripts/mission/mission_scenario_data.gd").load_from_file(SCENARIO)
	check(scenario != null and String(scenario.map_file_path) == PATH, "ground_mission02_128x128 points at this map")
	var report: Dictionary = scenario.validate(map) if scenario != null else {}
	check(bool(report.get("ok", report.get("valid", false))) or Array(report.get("errors", ["?"])).is_empty(), "scenario validates against the map: " + str(report).left(300))
	check(PackedStringArray(scenario.call("get_enemy_ids")).size() == 12 and Array(scenario.enemy_groups).size() == 3, "twelve enemies in three groups")
	print("GROUND_MISSION02_RELAY_RIDGE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _tile_at_world(map, by_cell: Dictionary, world: Vector2):
	# Inverse of TerrainMapData._grid_to_world for the hex topology.
	var origin: Vector2 = map.get_grid_origin()
	var size: Dictionary = map.get_tile_size()
	var a: float = (world.x - origin.x) / float(size.half_width)
	var b: float = (world.y - origin.y) / float(size.half_height)
	var plane := Vector2((a + b) * 0.5, (b - a) * 0.5)
	return by_cell.get(HEX.round_axial(HEX.plane_to_axial(plane)))
