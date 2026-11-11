extends RefCounted
## A regional ramp cap shares its edge midpoints and corners with adjoining cells.
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
