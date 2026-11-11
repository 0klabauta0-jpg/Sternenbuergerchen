extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var fleet = FLEET.new()
	fleet.configure()
	var id := "space_fixture_first"
	fleet.register_craft(id)
	var auth := {"runtime_authorized":true}
	var failed := 0
	if not _travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch", auth).get("ok", false): failed += 1
	if not _travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"planet_orbit"}, "warp", auth).get("ok", false): failed += 1
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var flight: RefCounted = fleet.get_flight_state(id)
	var before: Dictionary = flight.get_snapshot()
	var travel: Dictionary = fleet.get_snapshot(id)
	var context := {"runtime_authorized":true, "fixture":true, "actor_id":"player", "owned_crafts":[id], "craft_pilots":{id:"pilot"}, "request_id":"first", "operation":"advance", "payload":{"craft_id":id, "delta_seconds":3.0}, "fixture_footprint":[Vector2i.ZERO]}
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(200,230)))), "heading_rad":0.0}
	var prepared: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, travel.revision, context)
	if not prepared.get("ok", false): failed += 1
	if sim.get_space_actor(id) != null or flight.get_snapshot() != before or not sim.get_space_wing_snapshot().wings.is_empty(): failed += 1
	var result: Dictionary = sim.commit_space_area_transition(String(prepared.get("token", "")), context)
	if not result.get("ok", false): failed += 1
	if sim.get_space_actor(id) != flight or flight.get_snapshot().space_area_id != "orbit_approach:planet" or flight.get_snapshot().motion_mode != "tactical": failed += 1
	var cells: Array[Vector2i] = [GRID.from_offset(Vector2i(200,230))]
	if sim.get("_space_combat_state").query_cells(cells, "orbit_approach:planet") != [id]: failed += 1
	if sim.get_space_wing_snapshot().wings.size() != 1 or fleet.get_snapshot(id).phase != "orbit": failed += 1
	sim.free()
	if not _reject_intervening_admission(): failed += 1
	print("SPACE_COMBAT_AREA_REAL_FIRST_ENTRY passed=", 9 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String, context: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, context)

func _reject_intervening_admission() -> bool:
	var fleet = FLEET.new()
	fleet.configure()
	var id := "space_fixture_race"
	fleet.register_craft(id)
	var auth := {"runtime_authorized":true}
	_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch", auth)
	_travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"planet_orbit"}, "warp", auth)
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var flight: RefCounted = fleet.get_flight_state(id)
	var before: Dictionary = flight.get_snapshot()
	var context := {"runtime_authorized":true, "fixture":true, "actor_id":"player", "owned_crafts":[id], "craft_pilots":{id:"pilot"}, "request_id":"race", "operation":"advance", "payload":{"craft_id":id, "delta_seconds":3.0}, "fixture_footprint":[Vector2i.ZERO]}
	var target := {"position_plane":GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(Vector2i(200,230)))), "heading_rad":0.0}
	var prepared: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:planet", target, before.revision, fleet.get_snapshot(id).revision, context)
	var cell: Vector2i = GRID.cell_at(before.position_plane / GRID.EXTENT)
	var state: RefCounted = sim.get("_space_combat_state")
	var admitted: Dictionary = state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight)
	var result: Dictionary = sim.commit_space_area_transition(String(prepared.get("token", "")), context)
	var ok: bool = admitted.get("ok", false) and result.get("reason") == "actor_changed" and flight.get_snapshot() == before and sim.get_space_wing_snapshot().wings.is_empty() and fleet.get_snapshot(id).phase == "quantum"
	sim.free()
	return ok
