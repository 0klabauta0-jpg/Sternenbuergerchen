extends SceneTree
const STATE = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var state = STATE.new()
	var id := "space_fixture_claimant"
	var area := "orbit_approach:moon"
	var cell: Vector2i = GRID.from_offset(Vector2i(200,100))
	var flight = FLIGHT.new()
	flight.configure(id, {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "coordinate_frame":"local", "space_area_id":area})
	state.admit_actor({"craft_id":id, "faction_id":"enemy", "control_domain":"enemy", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true)
	var before: int = state.get_area_revision(area)
	var cells: Array[Vector2i] = [cell + Vector2i(1,0)]
	var failed := 0
	if not state.record_navigation_claim(id, area, cells).get("ok", false): failed += 1
	var revision: int = state.get_area_revision(area)
	if revision <= before or state.query_navigation_claims(cells, area) != [id]: failed += 1
	if not state.query_navigation_claims(cells, "orbit_approach:planet").is_empty(): failed += 1
	if not state.record_navigation_claim(id, area, cells).get("ok", false) or state.get_area_revision(area) != revision: failed += 1
	if state.record_navigation_claim(id, "orbit_approach:planet", cells).get("ok", false) or state.get_area_revision(area) != revision: failed += 1
	if not state.release_navigation_claim(id).get("ok", false) or state.get_area_revision(area) <= revision or not state.query_navigation_claims(cells, area).is_empty(): failed += 1
	print("SPACE_COMBAT_AREA_CLAIMS passed=", 6 - failed, " failed=", failed)
	quit(1 if failed else 0)
