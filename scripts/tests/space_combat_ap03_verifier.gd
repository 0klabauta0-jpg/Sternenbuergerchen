extends SceneTree
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const NAV = preload("res://scripts/tactical/space_navigation_resolver.gd")

func plane(cell: Vector2i) -> Vector2:
	return GRID.HEX.axial_to_plane(Vector2(cell))

func actor(id: String, cell: Vector2i, offsets: Array = [Vector2i.ZERO]) -> Dictionary:
	return {"craft_id":id, "position_plane":plane(cell), "heading_rad":0.0, "footprint_hexes":offsets}

func _initialize() -> void:
	var failed := 0
	var actors: Array[Dictionary] = [actor("a", Vector2i(10,10)), actor("b", Vector2i(12,10))]
	var swap: Array[Dictionary] = [{"craft_id":"a", "position_plane":plane(Vector2i(12,10))}, {"craft_id":"b", "position_plane":plane(Vector2i(10,10))}]
	var result: Dictionary = NAV.resolve_motion(actors, swap, {})
	if not result.ok or result.rejected.size() != 2: failed += 1
	actors = [actor("a", Vector2i(10,10))]
	var move: Array[Dictionary] = [{"craft_id":"a", "position_plane":plane(Vector2i(13,10))}]
	result = NAV.resolve_motion(actors, move, {"blocked_cells":[Vector2i(12,10)]})
	if result.rejected.get("a") != "blocked": failed += 1
	result = NAV.resolve_motion(actors, move, {})
	if not result.accepted.has("a"): failed += 1
	actors = [actor("a", Vector2i(10,10)), actor("b", Vector2i(11,9))]
	var crossing: Array[Dictionary] = [{"craft_id":"a","position_plane":plane(Vector2i(12,10))}, {"craft_id":"b","position_plane":plane(Vector2i(11,11))}]
	result = NAV.resolve_motion(actors, crossing, {})
	if result.accepted.size() != 1 or result.rejected.size() != 1: failed += 1
	actors = [actor("large", Vector2i(10,10), [Vector2i.ZERO, Vector2i(2,0)])]
	var rotate: Array[Dictionary] = [{"craft_id":"large","position_plane":plane(Vector2i(10,10)), "heading_rad":PI}]
	result = NAV.resolve_motion(actors, rotate, {"blocked_cells":[Vector2i(9,12),Vector2i(11,8)]})
	if result.rejected.get("large") != "blocked": failed += 1
	var edge_center := plane(Vector2i(11,10))
	var cover: Array[Vector2i] = NAV._supercover(edge_center + Vector2(-0.5,-0.2), edge_center + Vector2(-0.5,0.2), 0.00001)
	if not cover.has(Vector2i(10,10)) or not cover.has(Vector2i(11,10)): failed += 1
	actors = [actor("a", Vector2i(10,10))]
	var long_move: Array[Dictionary] = [{"craft_id":"a","position_plane":plane(Vector2i(80,10))}]
	result = NAV.resolve_motion(actors, long_move, {})
	if result.rejected.get("a") != "sweep_limit": failed += 1
	print("SPACE_COMBAT_AP03 passed=", 7 - failed, " failed=", failed)
	quit(1 if failed else 0)
