extends SceneTree
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}).ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"polisa_orbit"}).ok)
	assert(_travel(fleet, "advance", {"delta_seconds":60.0}).ok)
	var flight: RefCounted = fleet.get_flight_state("ship")
	var gate: Vector2i = GRID.from_offset(Vector2i(256,133))
	assert(flight.configure("ship", {"coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2", "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}).ok)
	var authority := RefCounted.new()
	assert(fleet.configure_space_area_transition_authority(authority).ok)
	var payload := {"craft_id":"ship", "location_id":"polisa", "target_id":"polisa_station_dock", "layout_revision":"polisa_glut2_dock_v1"}
	var context := _context("begin_station_dock", "station-dock:1", "orbit", fleet.get_craft_snapshot("ship").revision, payload)
	var bad: Dictionary = context.duplicate(true); bad.payload.layout_revision = "old"
	assert(not fleet.bind_space_area_transition_context(bad, authority).ok)
	assert(fleet.bind_space_area_transition_context(context, authority).ok)
	assert(flight.configure("other", {"coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2", "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}).ok)
	assert(not fleet.prepare_space_area_transition("ship", context.expected_travel_revision, context.source_area_id, context.target_area_id, context).ok)
	assert(flight.configure("ship", {"coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2", "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}).ok)
	var candidate: Dictionary = fleet.prepare_space_area_transition("ship", context.expected_travel_revision, context.source_area_id, context.target_area_id, context)
	assert(candidate.ok and fleet.validate_prepared_space_area_transition(candidate, context).ok)
	assert(fleet.commit_prepared_space_area_transition(candidate, context).ok)
	assert(fleet.get_craft_snapshot("ship").phase == "approach")
	assert(fleet.validate_prepared_space_area_transition(candidate, context).replayed)
	assert(flight.configure("ship", {"coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2", "motion_mode":"inactive", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}).ok)
	context = _context("undock_station", "station-undock:1", "approach", fleet.get_craft_snapshot("ship").revision, payload)
	assert(fleet.bind_space_area_transition_context(context, authority).ok)
	candidate = fleet.prepare_space_area_transition("ship", context.expected_travel_revision, context.source_area_id, context.target_area_id, context)
	assert(candidate.ok and fleet.commit_prepared_space_area_transition(candidate, context).ok)
	assert(fleet.get_craft_snapshot("ship").orbit_id == "polisa_orbit")
	print("Polisa Fleet dock and undock staged operations passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload}, {"runtime_authorized":true})

func _context(operation: String, request_id: String, phase: String, revision: int, payload: Dictionary) -> Dictionary:
	return {"request_id":request_id, "request_signature":JSON.stringify({"operation":operation,"payload":payload}, "", true), "operation":operation, "payload":payload.duplicate(true), "source_area_id":"orbit_approach:glut_2", "target_area_id":"orbit_approach:glut_2", "expected_travel_revision":revision, "expected_phase":phase, "context_id":request_id}
