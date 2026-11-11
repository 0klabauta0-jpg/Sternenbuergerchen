extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

class FixtureFleet extends RefCounted:
	var flight = FLIGHT.new()
	var revision := 3
	func _init() -> void:
		flight.configure("space_fixture_player", {"position_plane":GRID.HEX.axial_to_plane(Vector2(Vector2i(10,10)))})
	func is_space_area_transition_fixture() -> bool: return true
	func get_flight_state(id: String) -> RefCounted: return flight if id == "space_fixture_player" else null
	func get_snapshot(_id: String = "") -> Dictionary:
		return {"phase":"orbit", "revision":revision, "orbit_id":"moon_orbit", "orbits":{"moon_orbit":{"body_id":"moon"}}}
	func prepare_space_area_transition(_id: String, expected: int, _source: String, _target: String, _context: Dictionary) -> Dictionary:
		return {"ok":expected == revision, "revision":revision}
	func validate_prepared_space_area_transition(candidate: Dictionary, _context: Dictionary) -> Dictionary:
		return {"ok":candidate.revision == revision}
	func commit_prepared_space_area_transition(_candidate: Dictionary, _context: Dictionary) -> Dictionary:
		revision += 1
		return {"ok":true}

func _initialize() -> void:
	var sim = ROOT.new()
	var fleet := FixtureFleet.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var auth := {"runtime_authorized":true, "fixture":true, "actor_id":"player", "owned_crafts":["space_fixture_player"], "craft_pilots":{"space_fixture_player":"pilot"}, "request_id":"r1"}
	var actor := {"craft_id":"space_fixture_player", "faction_id":"player", "control_domain":"player", "start_hex":Vector2i(10,10), "footprint_hexes":[Vector2i.ZERO]}
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(200,230)))), "heading_rad":0.0}
	var failed := 0
	if not sim.admit_space_actor(actor, auth).get("ok", false): failed += 1
	var before: Dictionary = fleet.flight.get_snapshot()
	if sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, {}).get("reason") != "runtime_authority_required": failed += 1
	if sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 2, auth).get("reason") != "stale_travel_revision": failed += 1
	if sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:planet", target, 0, 3, auth).get("reason") != "wrong_orbit": failed += 1
	var prepared: Dictionary = sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, auth)
	if not prepared.get("ok", false) or String(prepared.get("token", "")).is_empty(): failed += 1
	var duplicate: Dictionary = sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, auth)
	if duplicate.get("token") != prepared.get("token"): failed += 1
	var changed_target := target.duplicate(true)
	changed_target.heading_rad = 1.0
	if sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", changed_target, 0, 3, auth).get("reason") != "request_id_conflict": failed += 1
	if fleet.flight.get_snapshot() != before or not sim.get_space_wing_snapshot().wings.is_empty(): failed += 1
	var cancel_context := auth.duplicate(true)
	cancel_context.request_id = "cancel-test"
	var cancel: Dictionary = sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, cancel_context)
	if not sim.release_space_area_transition(cancel.token, cancel_context).get("ok", false) or sim.commit_space_area_transition(cancel.token, cancel_context).get("reason") != "unknown_token": failed += 1
	var stale_context := auth.duplicate(true)
	stale_context.request_id = "stale-test"
	var stale: Dictionary = sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, stale_context)
	fleet.revision = 4
	if sim.commit_space_area_transition(stale.token, stale_context).get("reason") != "stale_travel_revision" or fleet.flight.get_snapshot() != before or not sim.get_space_wing_snapshot().wings.is_empty(): failed += 1
	fleet.revision = 3
	var expire_context := auth.duplicate(true)
	expire_context.request_id = "expiry-test"
	var expired: Dictionary = sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, expire_context)
	sim.get("_fixture_area_tokens")[expired.token]["expires_usec"] = 0
	if sim.commit_space_area_transition(expired.token, expire_context).get("reason") != "unknown_token": failed += 1
	var occupied_context := auth.duplicate(true)
	occupied_context.request_id = "occupied-test"
	var occupied: Dictionary = sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", target, 0, 3, occupied_context)
	var obstacle = FLIGHT.new()
	obstacle.configure("obstacle", {"position_plane":target.position_plane, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	var registry: RefCounted = sim.get("_space_combat_state").get("_registry")
	registry.register_actor("obstacle", obstacle)
	var occupied_cells: Array[Vector2i] = [GRID.from_offset(Vector2i(200,230))]
	registry.update_actor_cells("obstacle", occupied_cells)
	if sim.commit_space_area_transition(occupied.token, occupied_context).get("reason") != "occupied" or fleet.flight.get_snapshot() != before or not sim.get_space_wing_snapshot().wings.is_empty(): failed += 1
	registry.unregister_actor("obstacle")
	var committed: Dictionary = sim.commit_space_area_transition(String(prepared.get("token", "")), auth)
	if not committed.get("ok", false): failed += 1
	if fleet.flight.get_snapshot().space_area_id != "orbit_approach:moon" or sim.get_space_wing_snapshot().wings.size() != 1: failed += 1
	var destination: Array[Vector2i] = [GRID.from_offset(Vector2i(200,230))]
	if sim.get("_space_combat_state").query_cells(destination, "orbit_approach:moon") != [actor.craft_id]: failed += 1
	var local_snap: Dictionary = fleet.flight.get_snapshot()
	var ordinary := {"expected_revision":local_snap.revision, "position_plane":local_snap.position_plane}
	if sim.commit_space_actor_motion(actor.craft_id, ordinary, 1, auth).get("reason") != "local_area_not_ready": failed += 1
	if not sim.commit_space_area_transition(String(prepared.get("token", "")), auth).get("replayed", false) or fleet.revision != 4: failed += 1
	if sim.release_space_area_transition(prepared.token, auth).get("reason") != "already_committed": failed += 1
	sim.free()
	print("SPACE_COMBAT_AREA_ROOT_PREPARE passed=", 18 - failed, " failed=", failed)
	quit(1 if failed else 0)
