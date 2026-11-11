extends SceneTree
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const NAV = preload("res://scripts/tactical/space_navigation_resolver.gd")
const STATE = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

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
	var space = STATE.new()
	var big = FLIGHT.new()
	big.configure("big", {"position_plane":plane(Vector2i(10,10)), "motion_mode":"tactical"})
	var admitted: Dictionary = space.admit_actor({"craft_id":"big","faction_id":"friendly","control_domain":"player","start_hex":Vector2i(10,10),"footprint_hexes":[Vector2i.ZERO, Vector2i(1,0)]}, big)
	if not admitted.get("ok", false): failed += 1
	var turn: Dictionary = big.commit_motion({"expected_revision":0,"heading_rad":PI / 6.0}, 1)
	if not turn.get("ok", false) or not space.update_actor_cell("big", Vector2i(10,10)): failed += 1
	var occupied := 0
	for q in range(8,14):
		for r in range(8,14):
			var cells: Array[Vector2i] = [Vector2i(q,r)]
			if space.query_cells(cells).has("big"): occupied += 1
	if occupied < 3: failed += 1
	var small_space = STATE.new()
	var small = FLIGHT.new()
	small.configure("small", {"position_plane":plane(Vector2i(10,10)), "motion_mode":"tactical", "heading_rad":PI / 6.0})
	small_space.admit_actor({"craft_id":"small","faction_id":"friendly","control_domain":"player","start_hex":Vector2i(10,10),"footprint_hexes":[Vector2i.ZERO]}, small)
	var small_occupied := 0
	for q in range(8,13):
		for r in range(8,13):
			var cells: Array[Vector2i] = [Vector2i(q,r)]
			if small_space.query_cells(cells).has("small"): small_occupied += 1
	if small_occupied != 1: failed += 1
	print("SPACE_COMBAT_AP03 passed=", 11 - failed, " failed=", failed)
	quit(1 if failed else 0)
