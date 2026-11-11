extends SceneTree
## Exercise generated ridge, approach and bridge facts through the shared registry.
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const FINDER = preload("res://scripts/terrain/terrain_pathfinder.gd")
const GRAPH = preload("res://scripts/terrain/hpa_navigation_graph.gd")
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")
const LOS = preload("res://scripts/core/los_system.gd")
const SURFACE = preload("res://scripts/terrain/regional_hex_surface.gd")
const BUILDING = preload("res://scripts/editor/building_layout_authoring.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	print("PASS " if value else "FAIL ", label)
	if not value:
		failures += 1

func _offset(column: int, row: int) -> Vector2i:
	return Vector2i(column - floori(row * 0.5), row)

func _run() -> void:
	for name in ["satellite_crash_site", "trade_outpost", "fortified_outpost"]:
		var path := "res://maps/%s.json" % name
		var map = MAP.load_from_file(path)
		var registry = REGISTRY.new()
		registry.configure_iso_grid(map.get_grid_origin(), 64.0, 32.0, map.get_grid_topology())
		var heights := {}
		for tile in map.get_tiles():
			registry.register_tile(tile)
			heights[tile.height_level] = heights.get(tile.height_level, 0) + 1
		_check(_verify_ramp_edges(map, registry), name + " regional one-step ramps are reciprocal and agree with their continuous cap")
		_check(heights.get(7, 0) + heights.get(8, 0) > 1000, name + " has broad high ground")
		for cell in [_offset(-170, -108), _offset(341, -108), _offset(-170, 147), _offset(341, 147)]:
			_check(registry.world_to_grid(registry.grid_to_world(cell)) == cell and registry.get_tile_at_grid(cell) != null,
				"%s boundary projects both ways: %s" % [name, cell])
		var start: Vector2i = registry.world_to_grid(map.get_marker_position("spawn_alpha"))
		var goal: Vector2i = registry.world_to_grid(map.get_marker_position("objective_point"))
		var direct_start := Time.get_ticks_msec()
		var direct: Array = FINDER.new().find_path(start, goal, registry)
		_check(_valid_route(direct, start, goal, registry), name + " legal direct A* path to objective")
		print("REGIONAL_DIRECT ", name, " query_ms=", Time.get_ticks_msec() - direct_start, " path_cells=", direct.size())
		var graph = GRAPH.new()
		var before := Time.get_ticks_msec()
		_check(graph.build_from_registry(registry, 8), name + " HPA graph builds")
		var graph_ms := Time.get_ticks_msec() - before
		before = Time.get_ticks_msec()
		var route: Array = HPA.new().find_path(start, goal, registry, graph)
		var query_ms := Time.get_ticks_msec() - before
		_check(_valid_route(route, start, goal, registry), name + " legal HPA route to main objective")
		print("REGIONAL_NAV ", name, " graph_ms=", graph_ms, " query_ms=", query_ms, " path_cells=", route.size())
		if name == "fortified_outpost":
			_check(int(registry.get_tile_at_grid(goal).height_level) == 4, "Chip site lies on the eastern H4 shelf")
			_check(_verify_elevated_building(map), "Editor places a building flush with the regional high ground")
			_check(_crosses_deck_without_other_crossing(registry, start, goal, false), "main crossing reaches Chip site without the flank deck")
			_check(_crosses_deck_without_other_crossing(registry, start, goal, true), "flank crossing reaches Chip site without the main deck")
		_check(_has_real_cliff_occlusion(map, registry), name + " an authored escarpment blocks LOS between lower hexes")
		registry.free()
	quit(1 if failures else 0)

func _valid_route(route: Array, start: Vector2i, goal: Vector2i, registry) -> bool:
	if route.size() < 2 or route[0] != start or route[-1] != goal:
		return false
	var finder = FINDER.new()
	for i in range(1, route.size()):
		if not HEX.are_neighbors(route[i - 1], route[i]) or not finder.can_traverse_step(route[i - 1], route[i], registry):
			return false
	return true

func _crosses_deck_without_other_crossing(registry, start: Vector2i, goal: Vector2i, flank: bool) -> bool:
	# Search both halves separated by the fissure using one deck only.
	var finder = FINDER.new()
	var visited := {start: true}
	var came_from := {}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var here := queue[index]
		index += 1
		if here == goal:
			var used_deck := false
			while here != start:
				var tile = registry.get_tile_at_grid(here)
				used_deck = used_deck or tile.object_type_id == "glut_bridge_deck"
				here = came_from[here]
			return used_deck
		for other in HEX.neighbors(here):
			if visited.has(other) or not finder.can_traverse_step(here, other, registry):
				continue
			var tile = registry.get_tile_at_grid(other)
			if tile.object_type_id == "glut_bridge_deck" and (other.y < 20) != flank:
				continue
			visited[other] = true
			came_from[other] = here
			queue.append(other)
	return false


func _has_real_cliff_occlusion(map, registry) -> bool:
	var los = LOS.new()
	for tile in map.get_tiles():
		if not tile.blocks_los or not String(tile.object_type_id).is_empty() or tile.height_level <= 2:
			continue
		for direction in HEX.DIRECTIONS:
			var first: Vector2i = tile.grid_position - direction
			var last: Vector2i = tile.grid_position + direction
			var a = registry.get_tile_at_grid(first)
			var b = registry.get_tile_at_grid(last)
			if a == null or b == null or a.height_level >= tile.height_level or b.height_level >= tile.height_level:
				continue
			if los.find_first_blocker_grid(first, last, registry) == tile.grid_position:
				return true
	return false


func _verify_elevated_building(map) -> bool:
	for row in range(-93, -70):
		for column in range(-130, -107):
			var cell := _offset(column, row)
			var tile = map.get_tile_at_grid(cell)
			if tile.height_level < 4:
				continue
			var plan: Dictionary = BUILDING.plan(map, "place", {"grid": cell, "asset_id": "frontier_habitat_exterior"})
			if plan.get("ok", false):
				return is_equal_approx(float(plan.after.props[-1].elevation), float(tile.height_level) * 0.75)
	return false


func _verify_ramp_edges(map, registry) -> bool:
	var all := {}
	var finder = FINDER.new()
	var valid_directions := {}
	var blocked_cliff := false
	for tile in map.get_tiles():
		all[tile.grid_position] = tile
	for tile in all.values():
		if not tile.walkable or tile.object_type_id == "glut_bridge_deck":
			continue
		var cell: Vector2i = tile.grid_position
		for edge in range(6):
			var neighbor = all.get(SURFACE.neighbor_cell(cell, edge))
			if neighbor == null or not neighbor.walkable or neighbor.object_type_id == "glut_bridge_deck":
				continue
			var difference := int(neighbor.height_level) - int(tile.height_level)
			if difference > 1 and not blocked_cliff:
				blocked_cliff = not finder.can_traverse_step(cell, neighbor.grid_position, registry)
			if difference != 1 or valid_directions.has(edge):
				continue
			var profile := SURFACE.profile(tile, all)
			if profile.is_empty() or not finder.can_traverse_step(cell, neighbor.grid_position, registry) \
					or not finder.can_traverse_step(neighbor.grid_position, cell, registry):
				return false
			var midpoint: Vector2 = SURFACE.ring[2 * edge + 1]
			if not is_equal_approx(SURFACE.rise_at(midpoint * 0.5, profile), 0.25) \
					or not is_equal_approx(SURFACE.rise_at(midpoint, profile), 0.5):
				return false
			valid_directions[edge] = true
		if blocked_cliff and valid_directions.size() == 6:
			return true
	return false
