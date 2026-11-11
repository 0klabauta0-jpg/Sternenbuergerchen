extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var fleet = FLEET.new()
	fleet.configure()
	var id := "space_fixture_real"
	fleet.register_craft(id)
	var auth := {"runtime_authorized":true}
	var failed := 0
	if not _travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch", auth).get("ok", false): failed += 1
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var flight: RefCounted = fleet.get_flight_state(id)
	var cell: Vector2i = GRID.cell_at(flight.get_snapshot().position_plane / GRID.EXTENT)
	if not sim.admit_space_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, auth).get("ok", false): failed += 1
	if not _travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"planet_orbit"}, "warp", auth).get("ok", false): failed += 1
	var before: Dictionary = flight.get_snapshot()
	var travel_before: Dictionary = fleet.get_snapshot(id)
	var context := {"runtime_authorized":true, "fixture":true, "actor_id":"player", "owned_crafts":[id], "craft_pilots":{id:"pilot"}, "request_id":"complete", "operation":"advance", "payload":{"craft_id":id, "delta_seconds":3.0}}
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(200,230)))), "heading_rad":0.0}
	var cancel_context := context.duplicate(true)
	cancel_context.request_id = "cancel"
	var canceled: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel_before.revision, cancel_context)
	if not canceled.get("ok", false) or not sim.release_space_area_transition(String(canceled.get("token", "")), cancel_context).get("ok", false) or not fleet.get("_space_area_contexts").is_empty(): failed += 1
	var collision_context := context.duplicate(true)
	collision_context.request_id = "noop-collision"
	var collision: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel_before.revision, collision_context)
	if not _travel(fleet, "advance", {"craft_id":id, "delta_seconds":0.0}, collision_context.request_id, auth).get("ok", false): failed += 1
	if sim.commit_space_area_transition(String(collision.get("token", "")), collision_context).get("reason") != "travel_validation_failed" or flight.get_snapshot() != before or not fleet.get("_space_area_contexts").is_empty(): failed += 1
	travel_before = fleet.get_snapshot(id)
	var prepared: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel_before.revision, context)
	if not prepared.get("ok", false): failed += 1
	var altered := context.duplicate(true)
	altered.payload.delta_seconds = 4.0
	if sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel_before.revision, altered).get("reason") != "request_id_conflict": failed += 1
	if flight.get_snapshot() != before or fleet.get_snapshot(id) != travel_before or not sim.get_space_wing_snapshot().wings.is_empty(): failed += 1
	var result: Dictionary = sim.commit_space_area_transition(String(prepared.get("token", "")), context)
	if not result.get("ok", false): failed += 1
	var after: Dictionary = flight.get_snapshot()
	if after.space_area_id != "orbit_approach:planet" or after.position_plane != target.position_plane: failed += 1
	if fleet.get_snapshot(id).phase != "orbit" or fleet.get_snapshot(id).orbit_id != "planet_orbit": failed += 1
	if sim.get_space_wing_snapshot().wings.size() != 1: failed += 1
	if not sim.commit_space_area_transition(String(prepared.get("token", "")), context).get("replayed", false): failed += 1
	sim.free()
	print("SPACE_COMBAT_AREA_REAL_TRAVEL passed=", 14 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String, context: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, context)
