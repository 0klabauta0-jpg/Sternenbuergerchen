extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")

class TravelStub extends RefCounted:
	var flight: RefCounted
	func get_flight_state(_id: String) -> RefCounted: return flight
	func get_snapshot(_id: String) -> Dictionary:
		return {"phase":"surface", "revision":3, "location_id":"homebase", "location_orbits":{"homebase":"moon_orbit"}, "orbits":{"moon_orbit":{"body_id":"moon"}}, "bodies":{"moon":{"id":"moon", "surface_location_id":"homebase"}}}

func _initialize() -> void:
	var id := "space_fixture_reactivate"
	var area := "orbit_approach:moon"
	var gate_offset: Vector2i = LAYOUT.build("moon").gate_cells[128]
	var gate: Vector2i = GRID.from_offset(gate_offset)
	var flight = FLIGHT.new()
	flight.configure(id, {"position_plane":GRID.HEX.axial_to_plane(Vector2(gate)), "motion_mode":"tactical", "coordinate_frame":"local", "space_area_id":area})
	var sim = ROOT.new()
	var travel := TravelStub.new()
	travel.flight = flight
	sim.configure_singleplayer_owners(null, null, null, travel)
	var state: RefCounted = sim.get("_space_combat_state")
	state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO,Vector2i(0,1)]}, flight, true)
	var wings: RefCounted = sim.get("_space_wing_state")
	wings.ensure_flying_wings("player", [id], [id], {id:"pilot"})
	flight.commit_space_activity_transition({"expected_revision":0, "motion_mode":"inactive"}, 1)
	state.deactivate_actor(id)
	sim.tick_counter = 1
	var rev: int = flight.get_snapshot().revision
	var area_rev: int = state.get_area_revision(area)
	var wing_rev: int = wings.get_snapshot().revision
	var auth := {"runtime_authorized":true, "actor_id":"player"}
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}
	var before: Dictionary = flight.get_snapshot()
	var failed := 0
	var preview: Dictionary = sim.preview_surface_reactivation(id, "homebase", target, rev, 3, area_rev, wing_rev, auth)
	if not preview.get("ok", false) or preview.get("activity_proposal", {}).get("motion_mode") != "tactical": failed += 1
	if flight.get_snapshot() != before or state.get_actor(id) != null or state.get_inactive_actor(id) != flight: failed += 1
	if sim.preview_surface_reactivation(id, "homebase", target, rev - 1, 3, area_rev, wing_rev, auth).get("reason") != "stale_flight_revision": failed += 1
	if sim.preview_surface_reactivation(id, "homebase", target, rev, 3, area_rev - 1, wing_rev, auth).get("reason") != "stale_area_revision": failed += 1
	if sim.preview_surface_reactivation(id, "other", target, rev, 3, area_rev, wing_rev, auth).get("reason") != "location_mismatch": failed += 1
	var away := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(gate_offset + Vector2i(0,3))))}
	if sim.preview_surface_reactivation(id, "homebase", away, rev, 3, area_rev, wing_rev, auth).get("reason") != "not_at_approach_gate": failed += 1
	var body := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(gate_offset + Vector2i(0,-1))))}
	if sim.preview_surface_reactivation(id, "homebase", body, rev, 3, area_rev, wing_rev, auth).get("reason") != "body_blocked": failed += 1
	var blocker = FLIGHT.new()
	blocker.configure("space_fixture_blocker", {"position_plane":target.position_plane, "coordinate_frame":"local", "space_area_id":area})
	state.admit_actor({"craft_id":"space_fixture_blocker", "faction_id":"enemy", "control_domain":"enemy", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, blocker, true)
	area_rev = state.get_area_revision(area)
	if sim.preview_surface_reactivation(id, "homebase", target, rev, 3, area_rev, wing_rev, auth).get("reason") != "occupied": failed += 1
	sim.free()
	print("SPACE_SURFACE_REACTIVATION_PREVIEW passed=", 8 - failed, " failed=", failed)
	quit(1 if failed else 0)
