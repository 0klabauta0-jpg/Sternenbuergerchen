extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

func _initialize() -> void:
	var fleet = FLEET.new()
	fleet.configure()
	var id := "space_fixture_return"
	fleet.register_craft(id)
	var auth := {"runtime_authorized":true}
	var failed := 0
	if not _travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch", auth).get("ok", false): failed += 1
	if not _travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"planet_orbit"}, "warp", auth).get("ok", false): failed += 1
	if not _travel(fleet, "advance", {"craft_id":id, "delta_seconds":3.0}, "advance", auth).get("ok", false): failed += 1
	var flight: RefCounted = fleet.get_flight_state(id)
	var gate_offset: Vector2i = LAYOUT.build("planet").gate_cells[128]
	var gate: Vector2i = GRID.from_offset(gate_offset)
	flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:planet", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate)), "motion_mode":"tactical"}, 1)
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var state: RefCounted = sim.get("_space_combat_state")
	if not state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, flight, true).get("ok", false): failed += 1
	var wings: RefCounted = sim.get("_space_wing_state")
	wings.ensure_flying_wings("player", [id], [id], {id:"pilot"})
	# Stage the real local approach against the same Flight object before publishing.
	var approach_payload := {"craft_id":id, "location_id":"fortified_outpost"}
	var approach_context := {"request_id":"approach", "request_signature":JSON.stringify({"operation":"begin_approach", "payload":approach_payload}, "", true), "operation":"begin_approach", "payload":approach_payload, "source_area_id":"orbit_approach:planet", "target_area_id":"orbit_approach:planet", "expected_travel_revision":fleet.get_snapshot(id).revision, "expected_phase":"orbit", "context_id":"fixture-approach"}
	assert(fleet.configure_space_area_transition_authority(sim).get("ok", false))
	assert(fleet.bind_space_area_transition_context(approach_context, sim).get("ok", false))
	var candidate: Dictionary = fleet.prepare_space_area_transition(id, approach_context.expected_travel_revision, approach_context.source_area_id, approach_context.target_area_id, approach_context)
	var travel_validation: Dictionary = fleet.validate_prepared_space_area_transition(candidate, approach_context)
	var flight_validation: Dictionary = flight.validate_space_activity_transition({"expected_revision":flight.get_snapshot().revision, "motion_mode":"inactive"}, 2)
	var combat_validation: Dictionary = state.validate_deactivation(id, flight.get_snapshot().revision, state.get_area_revision("orbit_approach:planet"))
	assert(travel_validation.get("ok", false) and flight_validation.get("ok", false) and combat_validation.get("ok", false))
	flight._publish_space_activity_transition(flight_validation)
	state._publish_deactivation(combat_validation)
	fleet._publish_prepared_space_area_transition(candidate, travel_validation)
	if not _travel(fleet, "finish_approach", {"craft_id":id}, "land", auth).get("ok", false): failed += 1
	sim.tick_counter = 2
	var before: Dictionary = flight.get_snapshot()
	var travel: Dictionary = fleet.get_snapshot(id)
	var context := {"runtime_authorized":true, "fixture":true, "actor_id":"player", "owned_crafts":[id], "craft_pilots":{id:"pilot"}, "request_id":"return", "operation":"enter_orbit", "payload":{"craft_id":id}}
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}
	var cancel_context := context.duplicate(true)
	cancel_context.request_id = "cancel-return"
	var canceled: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel.revision, cancel_context)
	if not canceled.get("ok", false) or not sim.release_space_area_transition(String(canceled.get("token", "")), cancel_context).get("ok", false) or not fleet.get("_space_area_contexts").is_empty(): failed += 1
	var blocked_context := context.duplicate(true)
	blocked_context.request_id = "blocked-return"
	var blocked: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel.revision, blocked_context)
	var obstacle = FLIGHT.new()
	obstacle.configure("space_fixture_blocker", {"position_plane":target.position_plane, "coordinate_frame":"local", "space_area_id":"orbit_approach:planet"})
	state.admit_actor({"craft_id":"space_fixture_blocker", "faction_id":"enemy", "control_domain":"enemy", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, obstacle, true)
	if sim.commit_space_area_transition(String(blocked.get("token", "")), blocked_context).get("reason") != "stale_area_revision" or flight.get_snapshot() != before or fleet.get_snapshot(id).phase != "surface": failed += 1
	state.remove_actor("space_fixture_blocker")
	if not fleet.get("_space_area_contexts").is_empty(): failed += 1
	var prepared: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel.revision, context)
	if not prepared.get("ok", false): failed += 1
	if flight.get_snapshot() != before or state.get_actor(id) != null: failed += 1
	var result: Dictionary = sim.commit_space_area_transition(String(prepared.get("token", "")), context)
	if not result.get("ok", false): failed += 1
	if state.get_actor(id) != flight or state.get_inactive_actor(id) != null or flight.get_snapshot().motion_mode != "tactical": failed += 1
	if fleet.get_snapshot(id).phase != "orbit" or fleet.get_snapshot(id).orbit_id != "planet_orbit" or wings.get_snapshot().wings.size() != 1: failed += 1
	if not sim.commit_space_area_transition(String(prepared.get("token", "")), context).get("replayed", false): failed += 1
	if not fleet._owners[id].configure(id).get("ok", false) or fleet.get_flight_state(id) != flight: failed += 1
	if sim.commit_space_area_transition(String(prepared.get("token", "")), context).get("reason") != "owner_changed": failed += 1
	sim.free()
	print("SPACE_SURFACE_REAL_REACTIVATION passed=", 17 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String, context: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, context)
