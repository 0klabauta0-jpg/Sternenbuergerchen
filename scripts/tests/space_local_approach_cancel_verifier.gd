extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
class FlowFixture extends Node:
	var _space_approaches := {}
	var _transfer_sequence := 0
class PilotFixture extends Node:
	var aboard := false
	func is_pilot_aboard(_id: String) -> bool: return aboard
class AdapterFixture extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	var gate := {}
	func preview_departure(_id: String) -> Dictionary: return gate.duplicate(true)
	func preview_reapproach(_id: String) -> Dictionary: return gate.duplicate(true)
	func _built_home_pad_ids() -> Array: return ["homebase_pad_01"]

func _initialize() -> void:
	var id := "space_fixture_cancel"
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"glut_1a_orbit"}, "warp").ok)
	assert(_travel(fleet, "advance", {"craft_id":id, "delta_seconds":3.0}, "advance").ok)
	var supply = SUPPLY.new(); supply.configure([id]); supply.configure_inventory([], [id], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	assert(campaign.apply_command(COMMANDS.build_accept_job_command("satellite_recovery", "accept")).ok)
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("satellite_crash", "satellite_recovery", "select")).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	var flight = fleet.get_flight_state(id)
	var gate: Vector2i = GRID.from_offset(LAYOUT.build("glut_1a").gate_cells[128])
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:glut_1a", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate)), "motion_mode":"tactical"}, 1).ok)
	var state = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer", [id], [id], {id:"pilot"}).ok)
	sim.tick_counter = 1
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = AdapterFixture.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot
	adapter.gate = {"ok":true, "departure":{"craft_id":id, "origin_location_id":"homebase", "destination_location_id":"satellite_crash", "landing_pad_id":"homebase_pad_01", "job_id":"satellite_recovery"}}
	assert(adapter.authorize_departure(id, "approach").ok)
	flow._space_approaches[id] = {"identity":{"craft_id":id, "location_id":"satellite_crash", "departure_token":adapter._departure_token_by_craft[id]}}
	sim.tick_counter = 2
	var fuel_before: Dictionary = supply.export_state()
	assert(not adapter.enter_space_orbit(id).ok and state.get_inactive_actor(id) == flight and supply.export_state() == fuel_before)
	pilot.aboard = true
	var result: Dictionary = adapter.enter_space_orbit(id)
	assert(result.ok and state.get_actor(id) == flight and fleet.get_snapshot(id).phase == "orbit" and supply.export_state() == fuel_before)
	flow._space_approaches.clear()
	assert(adapter.enter_space_orbit(id).get("replayed", false) and supply.export_state() == fuel_before)
	sim.tick_counter = flight.get_snapshot().tick
	flow._transfer_sequence += 1 # An unrelated craft moved after this ship cancelled.
	var campaign_before: Dictionary = campaign.get_campaign_snapshot()
	assert(adapter.authorize_departure(id, "approach-again").ok)
	assert(state.get_inactive_actor(id) == flight and fleet.get_snapshot(id).phase == "approach" and supply.export_state() == fuel_before and campaign.get_campaign_snapshot() == campaign_before)
	flow._space_approaches[id] = {"identity":{"craft_id":id, "location_id":"satellite_crash", "departure_token":adapter._departure_token_by_craft[id]}}
	sim.tick_counter = flight.get_snapshot().tick
	assert(adapter.enter_space_orbit(id).ok and supply.export_state() == fuel_before)
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("SPACE_LOCAL_APPROACH_CANCEL passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
