extends SceneTree
const SEARCH = preload("res://scripts/tactical/space_orbit_entry_search.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const STATE = preload("res://scripts/core/space_combat_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var a = FLIGHT.new()
	var b = FLIGHT.new()
	a.configure("a", {"position_plane":Vector2.ZERO})
	b.configure("b", {"position_plane":Vector2.ZERO})
	var state = STATE.new()
	var requests: Array[Dictionary] = [{"craft_id":"a", "flight":a, "footprint_hexes":[Vector2i.ZERO]}, {"craft_id":"b", "flight":b, "footprint_hexes":[Vector2i.ZERO]}]
	var search = SEARCH.new()
	var failed := 0
	if not search.begin("moon", requests, state).get("ok", false): failed += 1
	if search.advance(1).get("status") != "pending": failed += 1
	var result := {}
	for i in range(20):
		result = search.advance(1)
		if result.get("status") != "pending": break
	if result.get("status") != "complete" or result.allocations.size() != 2: failed += 1
	var stale = SEARCH.new()
	stale.begin("moon", requests, state)
	stale.advance(1)
	a.commit_motion({"expected_revision":0, "position_plane":Vector2(1,0)}, 1)
	if stale.advance(1).get("reason") != "stale_flight": failed += 1
	if search.advance(0).get("reason") != "invalid_budget": failed += 1
	var changing = SEARCH.new()
	changing.begin("moon", requests, state)
	changing.advance(1)
	var first: Dictionary = changing.get("_allocations").a
	var intruder = FLIGHT.new()
	intruder.configure("intruder", {"position_plane":first.position_plane, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	var registry: RefCounted = state.get("_registry")
	registry.register_actor("intruder", intruder)
	var occupied: Array[Vector2i] = []
	occupied.assign(first.cells)
	registry.update_actor_cells("intruder", occupied)
	var changed := {}
	for i in range(20):
		changed = changing.advance(1)
		if changed.get("status") != "pending": break
	if changed.get("reason") != "occupancy_changed": failed += 1
	registry.unregister_actor("intruder")
	var claimed = SEARCH.new()
	claimed.begin("moon", requests, state)
	claimed.advance(1)
	var selected: Dictionary = claimed.get("_allocations").a
	var claimant = FLIGHT.new()
	claimant.configure("space_fixture_claimant", {"position_plane":Vector2(200,100), "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	var claimant_cell := Vector2i(150,110)
	claimant.commit_motion({"expected_revision":0, "position_plane":GRID.HEX.axial_to_plane(Vector2(claimant_cell))}, 1)
	state.admit_actor({"craft_id":"space_fixture_claimant", "faction_id":"enemy", "control_domain":"enemy", "start_hex":claimant_cell, "footprint_hexes":[Vector2i.ZERO]}, claimant, true)
	var claim_cells: Array[Vector2i] = []
	claim_cells.assign(selected.cells)
	state.record_navigation_claim("space_fixture_claimant", "orbit_approach:moon", claim_cells)
	var claim_result := {}
	for i in range(20):
		claim_result = claimed.advance(1)
		if claim_result.get("status") != "pending": break
	if claim_result.get("reason") != "occupancy_changed": failed += 1
	print("SPACE_ORBIT_ENTRY_SEARCH passed=", 7 - failed, " failed=", failed)
	quit(1 if failed else 0)
