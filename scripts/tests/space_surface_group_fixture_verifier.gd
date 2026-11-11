extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")

class PilotFixture extends Node:
	func is_pilot_aboard(_craft_id: String) -> bool: return true

func _initialize() -> void:
	var sim = ROOT.new()
	var fleet = FLEET.new(); assert(fleet.configure().ok)
	var id := "space_fixture_group"
	fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"glut_1a_orbit"}, "warp").ok)
	assert(_travel(fleet, "advance", {"craft_id":id, "delta_seconds":3.0}, "advance").ok)
	var supply = SUPPLY.new(); supply.configure([id]); supply.configure_inventory([], [id], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	assert(campaign.apply_command(COMMANDS.build_accept_job_command("satellite_recovery", "accept")).ok)
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("satellite_crash", "satellite_recovery", "select")).ok)
	sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	var flight = fleet.get_flight_state(id)
	var gate: Vector2i = GRID.from_offset(LAYOUT.build("glut_1a").gate_cells[128])
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:glut_1a", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate)), "motion_mode":"tactical"}, 1).ok)
	var state = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer", [id], [id], {id:"pilot"}).ok)
	sim.tick_counter = 1
	var fuel := {"contract_category":"singleplayer_supply", "operation":"consume_route_fuel", "payload":{"craft_id":id, "origin_location_id":"homebase", "destination_location_id":"satellite_crash"}, "request_id":"fuel"}
	var bind := COMMANDS.build_command("bind_departure", {"craft_id":id, "origin_location_id":"homebase", "destination_location_id":"satellite_crash", "landing_pad_id":"homebase_pad_01", "job_id":"satellite_recovery"}, "bind")
	var activation := COMMANDS.build_command("activate_job", {"craft_id":id, "job_id":"satellite_recovery"}, "activate")
	var bundle := {"request_id":"group", "craft_id":id, "location_id":"satellite_crash", "fuel_command":fuel, "binding_command":bind, "activation_command":activation}
	var context := {"runtime_authorized":true, "fixture":true, "actor_id":"singleplayer", "built_home_pad_ids":["homebase_pad_01"]}
	var before: String = _fingerprint(sim, fleet, supply, campaign, id)
	var invalid := bundle.duplicate(true); invalid.fuel_command.payload.destination_location_id = "polisa"
	assert(sim.commit_fixture_surface_group(invalid, context).reason == "bundle_mismatch")
	assert(_fingerprint(sim, fleet, supply, campaign, id) == before)
	var fuel_before: float = supply._fuel_by_craft_id[id]
	supply._fuel_by_craft_id[id] = 0.0
	var empty_before := _fingerprint(sim, fleet, supply, campaign, id)
	assert(not sim.commit_fixture_surface_group(bundle, context).ok)
	assert(_fingerprint(sim, fleet, supply, campaign, id) == empty_before and fleet.get("_space_area_contexts").is_empty())
	supply._fuel_by_craft_id[id] = fuel_before
	var result: Dictionary = sim.commit_fixture_surface_group(bundle, context)
	assert(result.ok and not result.replayed)
	assert(fleet.get_snapshot(id).phase == "approach" and flight.get_snapshot().motion_mode == "inactive" and state.get_inactive_actor(id) == flight)
	assert(campaign.get_campaign_snapshot().jobs.satellite_recovery.status == "active")
	var after := _fingerprint(sim, fleet, supply, campaign, id)
	assert(after != before and sim.commit_fixture_surface_group(bundle, context).replayed and _fingerprint(sim, fleet, supply, campaign, id) == after)
	assert(_travel(fleet, "finish_approach", {"craft_id":id}, "land").ok)
	assert(fleet.get_snapshot(id).phase == "surface" and state.get_inactive_actor(id) == flight)
	sim.tick_counter = 2
	var return_context := {"runtime_authorized":true, "fixture":true, "actor_id":"singleplayer", "owned_crafts":[id], "craft_pilots":{id:"pilot"}, "request_id":"return", "operation":"enter_orbit", "payload":{"craft_id":id}}
	var return_pose := {"position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}
	var returning: Dictionary = sim.prepare_space_area_transition(id, "orbit_approach:glut_1a", return_pose, flight.get_snapshot().revision, fleet.get_snapshot(id).revision, return_context)
	assert(returning.get("ok", false) and sim.commit_space_area_transition(returning.token, return_context).get("ok", false))
	assert(fleet.get_snapshot(id).phase == "orbit" and state.get_actor(id) == flight and flight.get_snapshot().motion_mode == "tactical")
	assert(sim.commit_fixture_surface_group(bundle, context).replayed)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":id, "model_id":"cutlass"}]).ok)
	var pilot = PilotFixture.new()
	sim.configure_ship_equipment(equipment); sim.configure_base_personnel(pilot)
	var target: Vector2i = GRID.from_offset(GRID.to_offset(gate) + Vector2i(0, 5))
	assert(sim.request_singleplayer_space_move({"craft_id":id, "target_hex":target, "request_id":"move_after_return"}).ok)
	var old_position: Vector2 = flight.get_snapshot().position_plane
	sim._advance_space_flights(0.1, flight.get_snapshot().tick + 1)
	assert(flight.get_snapshot().position_plane != old_position)
	pilot.free()
	var changed := bundle.duplicate(true); changed.fuel_command.request_id = "other"
	assert(sim.commit_fixture_surface_group(changed, context).reason == "request_id_conflict")
	fleet.unregister_craft(id); fleet.register_craft(id)
	assert(sim.commit_fixture_surface_group(bundle, context).reason == "owner_changed")
	sim.free()
	print("SPACE_SURFACE_GROUP_FIXTURE passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})

func _fingerprint(sim: Node, fleet: RefCounted, supply: RefCounted, campaign: RefCounted, id: String) -> String:
	return var_to_str([fleet.get_snapshot(id), fleet.get_flight_state(id).get_snapshot(), supply.export_state(), campaign.get_campaign_snapshot(), sim.get_space_wing_snapshot()])
