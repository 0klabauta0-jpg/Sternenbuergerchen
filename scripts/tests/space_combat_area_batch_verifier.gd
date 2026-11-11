extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var sim = ROOT.new()
	var state: RefCounted = sim.get("_space_combat_state")
	var start: Vector2i = GRID.from_offset(Vector2i(400,100))
	var end: Vector2i = GRID.from_offset(Vector2i(401,100))
	var a = _add(state, "space_fixture_a", "orbit_approach:moon", start)
	var b = _add(state, "space_fixture_b", "orbit_approach:planet", end)
	var world := {"coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}
	var proposal: Array[Dictionary] = [{"craft_id":"space_fixture_a", "position_plane":GRID.HEX.axial_to_plane(Vector2(end)), "expected_revision":a.get_snapshot().revision}]
	var result: Dictionary = sim.commit_space_fleet_motion(proposal, 1, world, {"runtime_authorized":true, "fixture":true})
	var failed := 0
	if not result.get("ok", false) or result.accepted != ["space_fixture_a"]: failed += 1
	var end_cells: Array[Vector2i] = [end]
	if state.query_cells(end_cells, "orbit_approach:moon") != ["space_fixture_a"] or state.query_cells(end_cells, "orbit_approach:planet") != ["space_fixture_b"]: failed += 1
	if b.get_snapshot().revision != 0: failed += 1
	var foreign_world := {"coordinate_frame":"local", "space_area_id":"orbit_approach:other"}
	proposal[0].expected_revision = a.get_snapshot().revision
	if sim.commit_space_fleet_motion(proposal, 2, foreign_world, {"runtime_authorized":true, "fixture":true}).get("reason") != "area_mismatch": failed += 1
	if sim.commit_space_fleet_motion(proposal, 2, world, {"runtime_authorized":true}).get("reason") != "local_area_not_ready": failed += 1
	sim.free()
	var body_sim = ROOT.new()
	var body_state: RefCounted = body_sim.get("_space_combat_state")
	var body_start: Vector2i = GRID.from_offset(Vector2i(256,6))
	var body_target: Vector2i = GRID.from_offset(Vector2i(256,2))
	var mover = _add(body_state, "space_fixture_body", "orbit_approach:moon", body_start)
	var body_move: Array[Dictionary] = [{"craft_id":"space_fixture_body", "position_plane":GRID.HEX.axial_to_plane(Vector2(body_target)), "expected_revision":mover.get_snapshot().revision}]
	var body_result: Dictionary = body_sim.commit_space_fleet_motion(body_move, 1, world, {"runtime_authorized":true, "fixture":true})
	if not body_result.get("ok", false) or body_result.rejected.get("space_fixture_body") != "blocked": failed += 1
	body_sim.free()
	var claim_sim = ROOT.new()
	var claim_state: RefCounted = claim_sim.get("_space_combat_state")
	var claim_a = _add(claim_state, "space_fixture_claim_a", "orbit_approach:moon", start)
	_add(claim_state, "space_fixture_claim_b", "orbit_approach:moon", GRID.from_offset(Vector2i(410,100)))
	var claim_cells: Array[Vector2i] = [end]
	claim_state.record_navigation_claim("space_fixture_claim_b", "orbit_approach:moon", claim_cells)
	var claim_move: Array[Dictionary] = [{"craft_id":"space_fixture_claim_a", "position_plane":GRID.HEX.axial_to_plane(Vector2(end)), "expected_revision":claim_a.get_snapshot().revision}]
	var claimed: Dictionary = claim_sim.commit_space_fleet_motion(claim_move, 1, world, {"runtime_authorized":true, "fixture":true})
	if not claimed.get("ok", false) or claimed.rejected.get("space_fixture_claim_a") != "navigation_claimed": failed += 1
	claim_sim.free()
	print("SPACE_COMBAT_AREA_BATCH passed=", 7 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _add(state: RefCounted, id: String, area: String, cell: Vector2i) -> RefCounted:
	var flight = FLIGHT.new()
	flight.configure(id, {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical", "coordinate_frame":"local", "space_area_id":area})
	state.admit_actor({"craft_id":id, "faction_id":"enemy", "control_domain":"enemy", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true)
	return flight
