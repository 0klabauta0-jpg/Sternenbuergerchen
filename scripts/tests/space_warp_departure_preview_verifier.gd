extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var fleet = FLEET.new()
	fleet.configure()
	var id := "space_fixture_depart"
	fleet.register_craft(id)
	var auth := {"runtime_authorized":true, "actor_id":"player"}
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "request_id":"launch", "payload":{"craft_id":id}}, auth)
	var flight: RefCounted = fleet.get_flight_state(id)
	var cell: Vector2i = GRID.from_offset(Vector2i(200,230))
	flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical"}, 1)
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var state: RefCounted = sim.get("_space_combat_state")
	state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true)
	var wings: RefCounted = sim.get("_space_wing_state")
	wings.ensure_flying_wings("player", [id], [id], {id:"pilot"})
	sim.tick_counter = 1
	var before: Dictionary = flight.get_snapshot()
	var travel: Dictionary = fleet.get_snapshot(id)
	var area_rev: int = state.get_area_revision(before.space_area_id)
	var wing_rev: int = wings.get_snapshot().revision
	var failed := 0
	var result: Dictionary = sim.preview_warp_departure(id, "planet_orbit", before.revision, travel.revision, area_rev, wing_rev, auth)
	if not result.get("ok", false) or result.get("area_proposal", {}).get("coordinate_frame") != "strategic" or result.area_proposal.motion_mode != "travel": failed += 1
	if flight.get_snapshot() != before or fleet.get_snapshot(id) != travel: failed += 1
	if sim.preview_warp_departure(id, "moon_orbit", before.revision, travel.revision, area_rev, wing_rev, auth).get("reason") != "already_in_orbit": failed += 1
	if sim.preview_warp_departure(id, "missing", before.revision, travel.revision, area_rev, wing_rev, auth).get("reason") != "unknown_orbit": failed += 1
	if sim.preview_warp_departure(id, "planet_orbit", before.revision, travel.revision, area_rev - 1, wing_rev, auth).get("reason") != "stale_area_revision": failed += 1
	if sim.preview_warp_departure(id, "planet_orbit", before.revision, travel.revision, area_rev, wing_rev, {}).get("reason") != "runtime_authority_required": failed += 1
	sim.free()
	print("SPACE_WARP_DEPARTURE_PREVIEW passed=", 6 - failed, " failed=", failed)
	quit(1 if failed else 0)
