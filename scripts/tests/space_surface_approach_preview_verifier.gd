extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

func _initialize() -> void:
	var fleet = FLEET.new()
	fleet.configure()
	var id := "space_fixture_gate"
	fleet.register_craft(id)
	var auth := {"runtime_authorized":true, "actor_id":"player"}
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "request_id":"launch", "payload":{"craft_id":id}}, auth)
	var flight: RefCounted = fleet.get_flight_state(id)
	var gate_offset: Vector2i = LAYOUT.build("moon").gate_cells[128]
	var gate: Vector2i = GRID.from_offset(gate_offset)
	flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}, 1)
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var state: RefCounted = sim.get("_space_combat_state")
	var footprint := [Vector2i.ZERO, Vector2i(0,1)]
	var failed := 0
	if not state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":footprint}, flight, true).get("ok", false): failed += 1
	var wings: RefCounted = sim.get("_space_wing_state")
	wings.ensure_flying_wings("player", [id], [id], {id:"pilot"})
	var flight_rev: int = flight.get_snapshot().revision
	var travel_rev: int = fleet.get_snapshot(id).revision
	var area_rev: int = state.get_area_revision("orbit_approach:moon")
	var wing_rev: int = wings.get_snapshot().revision
	var before: Dictionary = flight.get_snapshot()
	var preview: Dictionary = sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, auth)
	if not preview.get("ok", false) or preview.get("space_area_id") != "orbit_approach:moon": failed += 1
	if flight.get_snapshot() != before: failed += 1
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, {}).get("reason") != "runtime_authority_required": failed += 1
	if sim.preview_surface_approach(id, "fortified_outpost", flight_rev, travel_rev, area_rev, wing_rev, auth).get("reason") != "location_orbit_mismatch": failed += 1
	var travel_owner: RefCounted = fleet.get("_owners")[id]
	travel_owner.get("_definition").location_orbits["fixture_station"] = "moon_orbit"
	if sim.preview_surface_approach(id, "fixture_station", flight_rev, travel_rev, area_rev, wing_rev, auth).get("reason") != "not_surface_destination": failed += 1
	if sim.preview_surface_approach(id, "homebase", flight_rev - 1, travel_rev, area_rev, wing_rev, auth).get("reason") != "stale_flight_revision": failed += 1
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev - 1, wing_rev, auth).get("reason") != "stale_area_revision": failed += 1
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev - 1, auth).get("reason") != "stale_wing_revision": failed += 1
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, {"runtime_authorized":true, "actor_id":"other"}).get("reason") != "wing_required": failed += 1
	var intruder = FLIGHT.new()
	intruder.configure("intruder", {"position_plane":before.position_plane, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	var registry: RefCounted = state.get("_registry")
	registry.register_actor("intruder", intruder)
	var overlap: Array[Vector2i] = [gate]
	registry.update_actor_cells("intruder", overlap)
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, auth).get("reason") != "stale_area_revision": failed += 1
	area_rev = state.get_area_revision("orbit_approach:moon")
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, auth).get("reason") != "occupied": failed += 1
	registry.unregister_actor("intruder")
	area_rev = state.get_area_revision("orbit_approach:moon")
	var claimant = FLIGHT.new()
	var claimant_cell: Vector2i = GRID.from_offset(gate_offset + Vector2i(20,4))
	claimant.configure("space_fixture_claimant", {"position_plane":GRID.HEX.axial_to_plane(Vector2(claimant_cell)), "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	state.admit_actor({"craft_id":"space_fixture_claimant", "faction_id":"enemy", "control_domain":"enemy", "start_hex":claimant_cell, "footprint_hexes":[Vector2i.ZERO]}, claimant, true)
	area_rev = state.get_area_revision("orbit_approach:moon")
	var claim: Array[Vector2i] = [gate]
	state.record_navigation_claim("space_fixture_claimant", "orbit_approach:moon", claim)
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, auth).get("reason") != "stale_area_revision": failed += 1
	area_rev = state.get_area_revision("orbit_approach:moon")
	if sim.preview_surface_approach(id, "homebase", flight_rev, travel_rev, area_rev, wing_rev, auth).get("reason") != "navigation_claimed": failed += 1
	state.release_navigation_claim("space_fixture_claimant")
	area_rev = state.get_area_revision("orbit_approach:moon")
	var away: Vector2i = GRID.from_offset(gate_offset + Vector2i(0,3))
	flight.commit_motion({"expected_revision":flight_rev, "position_plane":GRID.HEX.axial_to_plane(Vector2(away))}, 2)
	if sim.preview_surface_approach(id, "homebase", flight.get_snapshot().revision, travel_rev, area_rev, wing_rev, auth).get("reason") != "stale_spatial_index": failed += 1
	state.sync_moved_actors()
	if sim.preview_surface_approach(id, "homebase", flight.get_snapshot().revision, travel_rev, state.get_area_revision("orbit_approach:moon"), wing_rev, auth).get("reason") != "not_at_approach_gate": failed += 1
	flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}, 3)
	state.get("_metadata")[id].footprint_hexes = [Vector2i.ZERO, Vector2i(0,-1)]
	state.sync_moved_actors()
	if sim.preview_surface_approach(id, "homebase", flight.get_snapshot().revision, travel_rev, state.get_area_revision("orbit_approach:moon"), wing_rev, auth).get("reason") != "body_blocked": failed += 1
	sim.free()
	print("SPACE_SURFACE_APPROACH_PREVIEW passed=", 17 - failed, " failed=", failed)
	quit(1 if failed else 0)
