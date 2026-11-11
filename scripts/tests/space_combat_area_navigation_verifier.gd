extends SceneTree
const NAV = preload("res://scripts/tactical/space_navigation_resolver.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var failed := 0
	var start: Vector2i = GRID.from_offset(Vector2i(400,100))
	var end: Vector2i = GRID.from_offset(Vector2i(401,100))
	var actor := {"craft_id":"a", "position_plane":GRID.HEX.axial_to_plane(Vector2(start)), "heading_rad":0.0, "footprint_hexes":[Vector2i.ZERO], "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}
	var proposal := {"craft_id":"a", "position_plane":GRID.HEX.axial_to_plane(Vector2(end)), "heading_rad":0.0}
	var actors: Array[Dictionary] = [actor]
	var proposals: Array[Dictionary] = [proposal]
	var world := {"coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}
	var accepted: Dictionary = NAV.resolve_motion(actors, proposals, world)
	if not accepted.get("ok", false) or not accepted.accepted.has("a"): failed += 1
	world.blocked_cells = [end]
	var blocked: Dictionary = NAV.resolve_motion(actors, proposals, world)
	if not blocked.get("ok", false) or blocked.rejected.get("a") != "blocked": failed += 1
	world.erase("blocked_cells")
	world.space_area_id = "orbit_approach:other"
	if NAV.resolve_motion(actors, proposals, world).get("reason") != "area_mismatch": failed += 1
	var edge: Vector2i = GRID.from_offset(Vector2i(511,100))
	actor.position_plane = GRID.HEX.axial_to_plane(Vector2(edge))
	proposal.position_plane = GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(512,100))))
	world.space_area_id = "orbit_approach:moon"
	if NAV.resolve_motion(actors, proposals, world).rejected.get("a") != "map_edge": failed += 1
	print("SPACE_COMBAT_AREA_NAVIGATION passed=", 4 - failed, " failed=", failed)
	quit(1 if failed else 0)
