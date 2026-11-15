extends RefCounted
## Shared read-only validation; the existing transport owner commits the result.
const ACCURACY = preload("res://scripts/mission/dropship_lz_accuracy_contract.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

static func validate(registry: Node, grid: Vector2i, occupied_positions: Array) -> Dictionary:
	if registry == null: return {"ok":false, "reason":"terrain_unavailable"}
	var tile = registry.call("get_tile_at_grid", grid)
	if tile == null: return {"ok":false, "reason":"outside_map"}
	var cells: Array[Vector2i] = [grid]
	if registry.call("get_grid_topology") == "hex_axial_v1":
		cells.append_array(HEX.neighbors(grid))
	else:
		for x in range(-1,2):
			for y in range(-1,2): cells.append(grid + Vector2i(x,y))
	for cell in cells:
		var part = registry.call("get_tile_at_grid", cell)
		if part == null or not bool(registry.call("is_walkable",cell)) or int(part.height_level) != int(tile.height_level) or int(part.object_height) > 0 or TILE.is_explicit_ramp(part):
			return {"ok":false, "reason":"footprint_blocked", "message":"Landezone braucht freie ebene Flaeche und erreichbaren Ausstieg"}
	var position: Vector2 = registry.call("grid_to_world",grid)
	for other in occupied_positions:
		if typeof(other) == TYPE_VECTOR2 and position.distance_to(other) < 256.0:
			return {"ok":false, "reason":"occupied", "message":"Landezone ist durch ein anderes Schiff belegt"}
	return {"ok":true, "position":position}

static func resolve(registry: Node, requested: Vector2, seed: String, pilot_skill: float, team_skill: float, occupied: Array, radius_factor: float = 1.0) -> Dictionary:
	var checked := validate(registry, registry.call("world_to_grid", requested), occupied)
	if not bool(checked.ok): return checked
	var result: Dictionary = ACCURACY.resolve_lz_command(requested, seed, pilot_skill, team_skill, true, radius_factor)
	var resolved_grid: Vector2i = registry.call("world_to_grid", result.resolved_lz_position)
	var actual := validate(registry, resolved_grid, occupied)
	# Deviation never permits landing in a blocker. The requested safe footprint
	# remains the bounded fallback, with no search or teleport to a distant site.
	result.resolved_lz_position = actual.position if bool(actual.ok) else checked.position
	result.actual_landing_position = result.resolved_lz_position
	result.landing_deviation = requested.distance_to(result.resolved_lz_position)
	result.ok = true
	return result

static func validate_cells(registry: Node, cells: Array) -> Dictionary:
	if registry == null or cells.is_empty(): return {"ok":false,"reason":"footprint_unavailable"}
	var first = registry.call("get_tile_at_grid", cells[0])
	if first == null: return {"ok":false,"reason":"outside_map"}
	for grid in cells:
		var tile = registry.call("get_tile_at_grid", grid)
		if tile == null or not bool(registry.call("is_walkable",grid)) or int(tile.height_level) != int(first.height_level) or int(tile.object_height) > 0 or TILE.is_explicit_ramp(tile):
			return {"ok":false,"reason":"footprint_blocked","message":"Die gesamte Schiffsfläche muss frei, eben und tragfähig sein"}
	return {"ok":true,"height_level":int(first.height_level)}
