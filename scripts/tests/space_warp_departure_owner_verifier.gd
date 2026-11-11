extends SceneTree
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const STATE = preload("res://scripts/core/space_combat_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var id := "space_fixture_departure"
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"planet_orbit"}, "inbound").ok)
	assert(_travel(fleet, "advance", {"craft_id":id, "delta_seconds":3.0}, "arrive").ok)
	var flight = fleet.get_flight_state(id)
	var cell: Vector2i = GRID.from_offset(Vector2i(200, 230))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:planet", "position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical"}, 1).ok)
	var state = STATE.new()
	assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	var authority := RefCounted.new(); assert(fleet.configure_space_area_transition_authority(authority).ok)
	var travel: Dictionary = fleet.get_craft_snapshot(id)
	var payload := {"craft_id":id, "target_orbit_id":"moon_orbit"}
	var context := {"request_id":"outbound", "request_signature":JSON.stringify({"operation":"start_quantum", "payload":payload}, "", true), "operation":"start_quantum", "payload":payload, "source_area_id":"orbit_approach:planet", "target_area_id":"", "expected_travel_revision":travel.revision, "expected_phase":"orbit", "context_id":"warp-context", "origin_position":travel.bodies.planet.position, "warp_multiplier":0.75}
	var forged := context.duplicate(true); forged.payload.untrusted_power = 1.0
	assert(not fleet.bind_space_area_transition_context(forged, authority).ok)
	assert(fleet.bind_space_area_transition_context(context, authority).ok)
	var before: Dictionary = flight.get_snapshot()
	var candidate: Dictionary = fleet.prepare_space_area_transition(id, travel.revision, context.source_area_id, "", context)
	assert(candidate.ok and flight.get_snapshot() == before and fleet.get_craft_snapshot(id).phase == "orbit")
	var tv: Dictionary = fleet.validate_prepared_space_area_transition(candidate, context)
	var proposal := {"expected_revision":before.revision, "coordinate_frame":"strategic", "space_area_id":"", "position_plane":GRID.pair(context.origin_position) * GRID.EXTENT, "motion_mode":"travel", "velocity_plane":Vector2.ZERO, "angular_velocity":0.0, "heading_rad":candidate.state.warp.heading}
	var fv: Dictionary = flight.validate_area_transition(proposal, 2)
	var sv: Dictionary = state.validate_local_departure(id, proposal, 2, state.get_area_revision(context.source_area_id))
	assert(tv.ok and fv.ok and sv.ok)
	flight._publish_area_transition(fv); state._publish_local_departure(sv)
	assert(fleet._publish_prepared_space_area_transition(candidate, tv).ok)
	assert(fleet.get_craft_snapshot(id).phase == "quantum" and flight.get_snapshot().coordinate_frame == "strategic" and state.get_actor(id) == null)
	assert(is_equal_approx(fleet.get_craft_snapshot(id).duration_seconds, 2.25) and not fleet.get_craft_snapshot(id).route_hexes.is_empty())
	assert(_travel(fleet, "advance", {"craft_id":id, "delta_seconds":2.25}, "complete").ok and fleet.get_craft_snapshot(id).orbit_id == "moon_orbit")
	print("SPACE_WARP_DEPARTURE_OWNER passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
