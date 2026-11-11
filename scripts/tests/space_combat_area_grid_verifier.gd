extends SceneTree
const AREA = preload("res://scripts/core/space_area_grid.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var failed := 0
	var local := {"coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}
	var strategic := {"coordinate_frame":"strategic", "space_area_id":""}
	if not AREA.contains(GRID.from_offset(Vector2i(511,255)), local): failed += 1
	if AREA.contains(GRID.from_offset(Vector2i(512,255)), local): failed += 1
	if AREA.contains(GRID.from_offset(Vector2i(-1,0)), local): failed += 1
	if AREA.contains(GRID.from_offset(Vector2i(1,256)), local): failed += 1
	if not AREA.contains(GRID.from_offset(Vector2i(255,255)), strategic): failed += 1
	if AREA.contains(GRID.from_offset(Vector2i(256,0)), strategic): failed += 1
	if AREA.contains(Vector2i.ZERO, {"coordinate_frame":"local", "space_area_id":""}): failed += 1
	if AREA.contains(Vector2i.ZERO, {"coordinate_frame":"wrong", "space_area_id":"orbit_approach:moon"}): failed += 1
	print("SPACE_COMBAT_AREA_GRID passed=", 8 - failed, " failed=", failed)
	quit(1 if failed else 0)
