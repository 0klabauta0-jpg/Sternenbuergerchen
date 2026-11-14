extends "res://scripts/terrain/native_navigation.gd"
## Test-only frozen Main _load_terrain algorithm; only three phase timers added.
## Source: a982a0b5d2265678bc796a5da77fe7a0e13e397c, UTF-8 function body SHA256.
const BASE_BODY_SHA256 := "263f4473b0b19f36d876413060f361e1022f21ba3f96455a3ccf1055aa1a765e"
var phases: Dictionary = {}

func _load_terrain(registry) -> bool:
	var phase_started: int = Time.get_ticks_usec()
	var tiles: Array = registry.call("get_all_tiles")
	var grid_ids: Dictionary = {}
	var coords := PackedInt32Array()
	var walkable := PackedByteArray()
	var cover := PackedFloat64Array()
	var blocks_los := PackedByteArray()
	var heights := PackedInt32Array()
	var stand_heights := PackedFloat64Array()
	var object_heights := PackedInt32Array()
	var surface_costs := PackedFloat64Array()
	_terrain_grids.clear()
	for tile in tiles:
		var grid: Vector2i = Vector2i(tile.grid_position)
		if absi(grid.x) > 1000000 or absi(grid.y) > 1000000:
			return _reject("coordinate_outside_prototype_range")
		grid_ids[grid] = grid_ids.size()
		_terrain_grids.append(grid)
		coords.append(grid.x)
		coords.append(grid.y)
		walkable.append(1 if bool(registry.call("is_walkable", grid)) else 0)
		cover.append(_oracle._get_cover_score(grid, registry))
		blocks_los.append(1 if (bool(registry.call("blocks_los_at_grid", grid)) if registry.has_method("blocks_los_at_grid") else bool(tile.blocks_los)) else 0)
		var height: int = int(tile.height_level)
		var object_height: int = int(registry.call("get_object_height_at_grid", grid)) if registry.has_method("get_object_height_at_grid") else int(tile.object_height)
		if absi(height) > 1000000 or absi(object_height) > 1000000:
			return _reject("height_outside_prototype_range")
		heights.append(height)
		stand_heights.append(PATH_SCRIPT.TERRAIN_TILE_DATA_SCRIPT.stand_height(tile))
		object_heights.append(object_height)
		surface_costs.append(PATH_SCRIPT.TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(String(tile.surface_type)))
	phases["extract_usec"] = Time.get_ticks_usec() - phase_started
	phase_started = Time.get_ticks_usec()
	var offsets := PackedInt32Array()
	var neighbors := PackedInt32Array()
	var costs := PackedFloat64Array()
	var directions: Array = _oracle.get_neighbor_directions(registry)
	for source_id in range(_terrain_grids.size()):
		offsets.append(neighbors.size())
		var grid: Vector2i = _terrain_grids[source_id]
		for direction in directions:
			var target: Vector2i = grid + Vector2i(direction)
			if not grid_ids.has(target) or not _oracle.can_traverse_step(grid, target, registry):
				continue
			var target_id: int = int(grid_ids[target])
			# Match Main's canonical ramp midpoint heights. Retain the unmultiplied
			# base; dividing a previous diagonal cost would change float rounding.
			var cost: float = surface_costs[target_id]
			var height_difference: float = absf(stand_heights[target_id] - stand_heights[source_id])
			if height_difference > 0:
				cost += height_difference
			neighbors.append(target_id)
			costs.append(cost)
	offsets.append(neighbors.size())
	var hex_mode: bool = registry.has_method("get_grid_topology") and String(registry.call("get_grid_topology")) == "hex_axial_v1"
	phases["edges_usec"] = Time.get_ticks_usec() - phase_started
	phase_started = Time.get_ticks_usec()
	if not bool(_kernel.call("load_terrain", {"coords": coords, "offsets": offsets, "neighbors": neighbors,
		"costs": costs, "walkable": walkable, "cover": cover, "blocks_los": blocks_los,
		"height": heights, "object_height": object_heights, "hex": hex_mode, "heuristic_min": 0.7})):
		return _reject("native_snapshot_rejected")
	phases["load_usec"] = Time.get_ticks_usec() - phase_started
	return true
