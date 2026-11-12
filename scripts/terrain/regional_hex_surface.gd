extends RefCounted
## A regional ramp cap shares its edge midpoints and corners with adjoining cells.
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
static var ring: PackedVector2Array = _make_ring()


static func _make_ring() -> PackedVector2Array:
	var corners := HEX.corners()
	var result := PackedVector2Array()
	for edge in range(6):
		result.append(corners[edge])
		result.append(corners[edge].lerp(corners[(edge + 1) % 6], 0.5))
	return result


static func neighbor_cell(cell: Vector2i, edge: int) -> Vector2i:
	return cell + HEX.DIRECTIONS[(11 - edge) % 6]


static func profile(tile, tiles: Dictionary) -> PackedFloat32Array:
	if tile.explicit_hex_ramps:
		return _explicit_profile(tile, tiles)
	if not tile.regional_grade or not tile.walkable or tile.object_type_id == "glut_bridge_deck":
		return PackedFloat32Array()
	var neighbors: Array = []
	var height := int(tile.height_level)
	var has_step := false
	for edge in range(6):
		var neighbor = tiles.get(neighbor_cell(tile.grid_position, edge))
		neighbors.append(neighbor)
		if _is_ground(neighbor) and absi(int(neighbor.height_level) - height) == 1:
			has_step = true
	if not has_step:
		return PackedFloat32Array()
	var result := PackedFloat32Array()
	result.resize(12)
	var changed := false
	for edge in range(6):
		var a = neighbors[edge]
		var b = neighbors[(edge + 5) % 6]
		if _is_ground(a):
			var difference := int(a.height_level) - height
			if absi(difference) == 1:
				result[edge * 2 + 1] = float(difference) * 0.5
				changed = true
		if not _is_ground(a) or not _is_ground(b):
			continue
		# Resolve each shared corner from the same three levels. A single
		# step joins halfway between the two centers. Three levels join at
		# the middle while the two-level wall stays at the edge midpoint.
		var a_height := int(a.height_level)
		var b_height := int(b.height_level)
		var lowest := mini(height, mini(a_height, b_height))
		var highest := maxi(height, maxi(a_height, b_height))
		var grade := 0.0
		if highest - lowest == 1:
			grade = float(lowest - height) + 0.5
		elif highest - lowest == 2 and a_height != b_height and a_height != height and b_height != height:
			grade = float(lowest + 1 - height)
		result[edge * 2] = grade
		changed = changed or grade != 0
	return result if changed else PackedFloat32Array()


static func _valid_ramp(tile) -> bool:
	return tile != null and tile.explicit_hex_ramps and tile.walkable and tile.ramp_direction >= 0 and tile.ramp_direction < 6 and tile.height_level < 8


static func _nominal_height(tile, world_corner: Vector2) -> float:
	var axis: Vector2 = HEX.axial_to_plane(Vector2(HEX.DIRECTIONS[tile.ramp_direction])).normalized()
	return float(tile.height_level) + 0.5 + clampf((world_corner - HEX.axial_to_plane(Vector2(tile.grid_position))).dot(axis), -0.5, 0.5)


static func _explicit_profile(tile, tiles: Dictionary) -> PackedFloat32Array:
	if not _valid_ramp(tile): return PackedFloat32Array()
	var center := HEX.axial_to_plane(Vector2(tile.grid_position))
	var base := float(tile.height_level)
	var result := PackedFloat32Array()
	for point: Vector2 in ring:
		result.append(_nominal_height(tile, center + point) - base - 0.5)
	for edge in range(6):
		var neighbor = tiles.get(neighbor_cell(tile.grid_position, edge))
		if _valid_ramp(neighbor) and neighbor.height_level == tile.height_level:
			# Both sides read the same quarter-step midpoint. Shared caps form a
			# broad bank instead of independent sloping ribs with vertical seams.
			var midpoint := center + ring[edge * 2 + 1]
			var my_end: float = TILE.endpoint_height(tile, neighbor.grid_position)
			var their_end: float = TILE.endpoint_height(neighbor, tile.grid_position)
			if is_equal_approx(my_end, their_end):
				result[edge * 2 + 1] = my_end - base - 0.5
			else:
				result[edge * 2 + 1] = snappedf((_nominal_height(tile, midpoint) + _nominal_height(neighbor, midpoint)) * 0.5 - base - 0.5, 0.25)
		var previous = tiles.get(neighbor_cell(tile.grid_position, (edge + 5) % 6))
		var corner_tiles: Array = [tile]
		for adjacent in [neighbor, previous]:
			if _valid_ramp(adjacent) and adjacent.height_level == tile.height_level:
				corner_tiles.append(adjacent)
		if corner_tiles.size() < 2: continue
		var corner := center + ring[edge * 2]
		var plateau_height := INF
		for adjacent in [neighbor, previous]:
			if adjacent != null and adjacent.explicit_hex_ramps and adjacent.ramp_direction == -1 and adjacent.height_level in [tile.height_level, tile.height_level + 1]:
				plateau_height = float(adjacent.height_level)
		if is_finite(plateau_height):
			result[edge * 2] = plateau_height - base - 0.5
		else:
			corner_tiles.sort_custom(func(a, b): return a.grid_position.x < b.grid_position.x or (a.grid_position.x == b.grid_position.x and a.grid_position.y < b.grid_position.y))
			var height := 0.0
			for ramp in corner_tiles: height += _nominal_height(ramp, corner)
			result[edge * 2] = snappedf(height / corner_tiles.size() - base - 0.5, 0.25)
	return result


static func _is_ground(tile) -> bool:
	return tile != null and tile.regional_grade and tile.walkable and tile.object_type_id != "glut_bridge_deck"


static func rise_at(position: Vector2, heights: PackedFloat32Array) -> float:
	if position.is_zero_approx():
		return 0.0
	for index in range(12):
		var next := (index + 1) % 12
		var a := ring[index]
		var b := ring[next]
		var area := a.cross(b)
		var weight_a := position.cross(b) / area
		var weight_b := a.cross(position) / area
		if weight_a >= -0.00001 and weight_b >= -0.00001:
			return clampf(weight_a * heights[index] + weight_b * heights[next], -1.0, 1.0)
	return 0.0
