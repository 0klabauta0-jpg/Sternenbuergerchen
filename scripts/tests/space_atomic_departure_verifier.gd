extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")

class FlowFixture extends Node:
	var _transfer_sequence := 0

class AdapterFixture extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	var gate := {}
	func preview_departure(_craft_id: String) -> Dictionary: return gate.duplicate(true)
	func _built_home_pad_ids() -> Array: return ["homebase_pad_01"]

func _initialize() -> void:
	var sim = ROOT.new()
	var supply = SUPPLY.new(); supply.configure(["ship"]); supply.configure_inventory([], ["ship"], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	assert(campaign.apply_command(COMMANDS.build_accept_job_command("satellite_recovery", "accept")).ok)
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("satellite_crash", "satellite_recovery", "select")).ok)
	sim.configure_singleplayer_owners(campaign, supply)
	var adapter = AdapterFixture.new(); var flow = FlowFixture.new()
	adapter._simulation = sim; adapter._flow = flow
	var departure := {"craft_id":"ship", "origin_location_id":"homebase", "destination_location_id":"satellite_crash", "landing_pad_id":"homebase_pad_01", "job_id":"satellite_recovery"}
	adapter.gate = {"ok":true, "departure":departure.duplicate(true)}
	var initial: String = _fingerprint(supply, campaign)
	adapter.gate.departure.job_id = "unknown"
	assert(not adapter.authorize_departure("ship").ok and _fingerprint(supply, campaign) == initial)
	adapter.gate.departure.job_id = "satellite_recovery"
	var observed := []
	sim.singleplayer_command_committed.connect(func(_command: Dictionary, _result: Dictionary): observed.append(campaign.get_campaign_snapshot().jobs.satellite_recovery.status))
	var result: Dictionary = adapter.authorize_departure("ship")
	assert(result.ok and result.departure == departure and campaign.get_campaign_snapshot().jobs.satellite_recovery.status == "active")
	assert(observed == ["active", "active", "active"])
	var after := _fingerprint(supply, campaign)
	assert(after != initial and adapter.authorize_departure("ship").replayed and _fingerprint(supply, campaign) == after)
	assert(observed.size() == 3)
	var foreign = AdapterFixture.new()
	assert(sim.commit_singleplayer_departure(foreign, "ship", "foreign").reason == "adapter_required")
	foreign.free(); adapter.free(); flow.free(); sim.free()
	_verify_strategic_approach()
	_verify_local_approach()
	print("SPACE_ATOMIC_DEPARTURE passed")
	quit(0)

func _verify_strategic_approach() -> void:
	var sim = ROOT.new()
	var supply = SUPPLY.new(); supply.configure(["ship"]); supply.configure_inventory([], ["ship"], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	assert(campaign.apply_command(COMMANDS.build_accept_job_command("satellite_recovery", "accept")).ok)
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("satellite_crash", "satellite_recovery", "select")).ok)
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}, "launch").ok)
	sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	var adapter = AdapterFixture.new(); var flow = FlowFixture.new()
	adapter._simulation = sim; adapter._flow = flow
	adapter.gate = {"ok":true, "departure":{"craft_id":"ship", "origin_location_id":"homebase", "destination_location_id":"satellite_crash", "landing_pad_id":"homebase_pad_01", "job_id":"satellite_recovery"}}
	var before := _fingerprint(supply, campaign)
	assert(not adapter.authorize_departure("ship", "approach").ok and _fingerprint(supply, campaign) == before and fleet.get_snapshot("ship").phase == "orbit")
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"glut_1a_orbit"}, "warp").ok)
	assert(_travel(fleet, "advance", {"craft_id":"ship", "delta_seconds":3.0}, "advance").ok)
	var observed := []
	sim.singleplayer_command_committed.connect(func(_command: Dictionary, _result: Dictionary):
		var replay: Dictionary = adapter.authorize_departure("ship", "approach")
		observed.append(adapter._departure_token_by_craft.has("ship") and adapter._space_operation_requests.has("outer") and replay.get("replayed", false) and replay.get("travel_result", {}).get("replayed", false)))
	var result: Dictionary = adapter.authorize_departure("ship", "approach")
	assert(result.ok and result.travel_result.ok and fleet.get_snapshot("ship").phase == "approach")
	assert(observed.is_empty() and adapter._departure_token_by_craft.has("ship"))
	adapter._space_operation_requests["outer"] = {"signature":"fixture", "result":result.travel_result.duplicate(true)}
	sim.publish_singleplayer_departure_events(adapter, adapter._departure_token_by_craft.ship)
	assert(observed == [true, true, true, true])
	sim.publish_singleplayer_departure_events(adapter, adapter._departure_token_by_craft.ship)
	assert(observed.size() == 4)
	assert(campaign.get_campaign_snapshot().jobs.satellite_recovery.status == "active")
	var after := _fingerprint(supply, campaign)
	assert(adapter.authorize_departure("ship", "approach").replayed and _fingerprint(supply, campaign) == after)
	var same_flight: RefCounted = fleet.get_flight_state("ship")
	assert(fleet._owners.ship.configure("ship").ok and fleet.get_flight_state("ship") == same_flight)
	assert(not adapter.authorize_departure("ship", "approach").get("ok", false) and _fingerprint(supply, campaign) == after)
	adapter.free(); flow.free(); sim.free()

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})

func _verify_local_approach() -> void:
	var id := "space_fixture_local_transaction"
	var sim = ROOT.new()
	var supply = SUPPLY.new(); supply.configure([id]); supply.configure_inventory([], [id], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	assert(campaign.apply_command(COMMANDS.build_accept_job_command("satellite_recovery", "accept")).ok)
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("satellite_crash", "satellite_recovery", "select")).ok)
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"glut_1a_orbit"}, "warp").ok)
	assert(_travel(fleet, "advance", {"craft_id":id, "delta_seconds":3.0}, "advance").ok)
	sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	var flight = fleet.get_flight_state(id)
	var gate: Vector2i = GRID.from_offset(LAYOUT.build("glut_1a").gate_cells[128])
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:glut_1a", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate)), "motion_mode":"tactical"}, 1).ok)
	var state = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer", [id], [id], {id:"pilot"}).ok)
	sim.tick_counter = 1
	var adapter = AdapterFixture.new(); var flow = FlowFixture.new()
	adapter._simulation = sim; adapter._flow = flow
	adapter.gate = {"ok":true, "departure":{"craft_id":id, "origin_location_id":"homebase", "destination_location_id":"satellite_crash", "landing_pad_id":"homebase_pad_01", "job_id":"satellite_recovery"}}
	var result: Dictionary = adapter.authorize_departure(id, "local-approach")
	assert(result.ok and result.travel_result.ok and flight.get_snapshot().motion_mode == "inactive" and state.get_inactive_actor(id) == flight)
	assert(fleet.get_snapshot(id).phase == "approach" and campaign.get_campaign_snapshot().jobs.satellite_recovery.status == "active")
	adapter.free(); flow.free(); sim.free()

func _fingerprint(supply: RefCounted, campaign: RefCounted) -> String:
	return var_to_str([supply.export_state(), campaign.get_campaign_snapshot()])
