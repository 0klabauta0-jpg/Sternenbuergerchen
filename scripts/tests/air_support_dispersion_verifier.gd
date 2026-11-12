extends SceneTree

const DISPERSION = preload("res://scripts/mission/air_support_dispersion.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")

func _initialize() -> void:
	var target := Vector2i(40, 50)
	var expert: Dictionary = DISPERSION.preview(target, 1.0)
	assert(expert.ok and expert.cells.size() == 7)
	for cell: Vector2i in expert.cells: assert(HEX.distance(target, cell) <= 1)
	var novice: Dictionary = DISPERSION.preview(target, 0.0)
	assert(novice.ok and novice.radius == 10 and novice.cells.size() == 331)
	assert(DISPERSION.preview(target, 0.5).radius > expert.radius)
	assert(not DISPERSION.preview(target, NAN).ok and not DISPERSION.preview(target, 1.1).ok)
	var first: Dictionary = DISPERSION.resolve(target, 1.0, 12345)
	assert(first == DISPERSION.resolve(target, 1.0, 12345))
	var seen := {}
	for seed in range(100): seen[DISPERSION.resolve(target, 1.0, seed).impact_hex] = true
	assert(seen.size() == 7 and seen.has(target))
	print("AIR_SUPPORT_DISPERSION passed")
	quit()
