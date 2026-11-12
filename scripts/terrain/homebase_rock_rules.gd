extends RefCounted
## Authored campaign-base formations. The same coarse cells drive the visual
## projection and the authoritative fine base terrain; no scene nodes own LOS.
const HEX := preload("res://scripts/terrain/hex_grid.gd")
const FINE_SCALE := 4
const CENTERS: Array[Vector2i] = [Vector2i(10, -7), Vector2i(12, -8), Vector2i(16, -8)]
const SIDE_OFFSETS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0)]
const PARTIAL_COVER := 60

static func formations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for center in CENTERS:
		var sides: Array[Vector2i] = []
		for offset in SIDE_OFFSETS: sides.append(center + offset)
		result.append({"center": center, "sides": sides})
	return result

static func apply_coarse(map) -> void:
	map.set_meta("homebase_rock_rules", true)
	for group in formations():
		_apply_high(map.get_tile_at_grid(group.center))
		for side in group.sides: _apply_low(map.get_tile_at_grid(side))

static func visual_height_at(grid: Vector2i) -> float:
	for group in formations():
		if grid == group.center: return 0.84
		if grid in group.sides: return 0.32
	return 0.0

static func apply_fine(map) -> void:
	# Only a bounded region is touched, once before registry registration.
	# Cube-rounding uses the same axial metric as the visible coarse map.
	for group in formations():
		var coarse_cells: Array[Vector2i] = [group.center]
		coarse_cells.append_array(group.sides)
		for coarse in coarse_cells:
			var fine_center: Vector2i = coarse * FINE_SCALE
			for x in range(fine_center.x - 3, fine_center.x + 4):
				for y in range(fine_center.y - 3, fine_center.y + 4):
					var fine := Vector2i(x, y)
					if HEX.round_axial(Vector2(fine) / float(FINE_SCALE)) != coarse: continue
					var tile = map.get_tile_at_grid(fine)
					if coarse == group.center: _apply_high(tile)
					else: _apply_low(tile)

static func _apply_high(tile) -> void:
	if tile == null: return
	tile.walkable = false
	tile.blocks_los = true
	tile.object_height = 2

static func _apply_low(tile) -> void:
	# Preserve authored blockers: partial cover is for reachable ground only.
	if tile == null or not tile.walkable or tile.blocks_los: return
	tile.cover_value = maxi(int(tile.cover_value), PARTIAL_COVER)
	tile.object_height = 1
