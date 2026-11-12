extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const COMMANDS = preload("res://scripts/mission/singleplayer_campaign_command_contract.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
class FlowFixture extends Node:
	var _space_approaches := {}
	var _transfer_sequence := 0
	var _selected_mission_id := ""
	var _last_mission_result := {}
	var adapter: Node
	func _begin_space_approach(id: String, departure: Dictionary) -> void:
		_space_approaches[id] = {"identity":{"craft_id":id, "location_id":departure.destination_location_id, "departure_token":adapter._departure_token_by_craft[id]}}
class PilotFixture extends Node:
	var aboard := false
	func is_pilot_aboard(_id: String) -> bool: return aboard
class AdapterFixture extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	var gate := {}
	func preview_departure(_id: String) -> Dictionary: return gate.duplicate(true)
	func preview_reapproach(_id: String) -> Dictionary: return gate.duplicate(true)
	func _built_home_pad_ids() -> Array: return ["homebase_pad_01"]
	func preview_local_surface_return(id: String) -> Dictionary:
		if not _base_personnel.aboard: return {"ok":false,"reason":"pilot_not_aboard"}
		return {"ok":true,"route":{"craft_id":id,"origin_location_id":"polisa","destination_location_id":"homebase"},"outward_token":_departure_token_by_craft[id]}

func _initialize() -> void:
	var id := "space_fixture_polisa_transaction"
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id, "target_orbit_id":"polisa_orbit"}, "warp").ok)
	assert(_travel(fleet, "advance", {"craft_id":id, "delta_seconds":3.0}, "advance").ok)
	var supply = SUPPLY.new(); supply.configure([id]); supply.configure_inventory([], [id], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("polisa", "", "select")).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	var flight = fleet.get_flight_state(id)
	var gate: Vector2i = GRID.from_offset(Vector2i(256, 133))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate)), "motion_mode":"tactical"}, 1).ok)
	var state = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer", [id], [id], {id:"pilot"}).ok)
	sim.tick_counter = 1
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = AdapterFixture.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._campaign = campaign; flow.adapter = adapter
	adapter.gate = {"ok":true, "departure":{"craft_id":id, "origin_location_id":"homebase", "destination_location_id":"polisa", "landing_pad_id":"homebase_pad_01", "job_id":""}}
	var events: Array = []
	var observed: Array = []
	sim.singleplayer_command_committed.connect(func(command: Dictionary, _result: Dictionary):
		events.append(command.operation)
		if command.operation == "begin_station_dock": observed.append(adapter.preview_local_approach_cancel(id).get("ok", false)))
	pilot.aboard = true
	assert(adapter.request_operation("space_begin_station_dock", {"craft_id":id,"location_id":"polisa","target_id":"polisa_station_dock","layout_revision":"polisa_glut2_dock_v1","request_id":"first-dock"}).ok)
	var token: String = adapter._departure_token_by_craft[id]
	sim.publish_singleplayer_departure_events(adapter, token); var event_count := events.size()
	sim.publish_singleplayer_departure_events(adapter, token)
	assert(events.size() == event_count and "begin_station_dock" in events and observed == [true])
	assert(sim.get_space_area_snapshot("orbit_approach:glut_2", "singleplayer").dock_targets == [{"target_id":"polisa_station_dock","revision":"polisa_glut2_dock_v1"}])
	sim.tick_counter = 2
	var fuel_before: Dictionary = supply.export_state()
	pilot.aboard = false
	assert(not adapter.enter_space_orbit(id).ok and state.get_inactive_actor(id) == flight and supply.export_state() == fuel_before)
	pilot.aboard = true
	var result: Dictionary = adapter.enter_space_orbit(id)
	assert(result.ok and state.get_actor(id) == flight and fleet.get_snapshot(id).phase == "orbit" and supply.export_state() == fuel_before)
	flow._space_approaches.clear()
	assert(adapter.enter_space_orbit(id).get("replayed", false) and supply.export_state() == fuel_before)
	sim.tick_counter = flight.get_snapshot().tick
	flow._transfer_sequence += 1 # An unrelated craft moved after this ship cancelled.
	var campaign_before: Dictionary = campaign.get_campaign_snapshot()
	assert(adapter.authorize_departure(id, "station-dock:approach-again", true).ok)
	assert(state.get_inactive_actor(id) == flight and fleet.get_snapshot(id).phase == "approach" and supply.export_state() == fuel_before and campaign.get_campaign_snapshot() == campaign_before)
	flow._space_approaches[id] = {"identity":{"craft_id":id, "location_id":"polisa", "departure_token":adapter._departure_token_by_craft[id]}}
	sim.tick_counter = flight.get_snapshot().tick
	assert(adapter.enter_space_orbit(id).ok and supply.export_state() == fuel_before)
	flow._space_approaches.clear()
	sim.tick_counter = flight.get_snapshot().tick
	assert(adapter.authorize_departure(id, "station-dock:approach-final", true).ok)
	assert(_travel(fleet, "finish_approach", {"craft_id":id}, "finish").ok)
	sim.tick_counter = flight.get_snapshot().tick
	pilot.aboard = false
	assert(not adapter.enter_space_orbit(id).ok and supply.export_state() == fuel_before)
	pilot.aboard = true
	var blocker = FLIGHT.new(); assert(blocker.configure("space_fixture_dock_blocker", {"coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2", "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}).ok)
	assert(state.admit_actor({"craft_id":"space_fixture_dock_blocker", "faction_id":"enemy", "control_domain":"enemy", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, blocker, true).ok)
	assert(not adapter.enter_space_orbit(id).ok and supply.export_state() == fuel_before and state.get_inactive_actor(id) == flight)
	assert(state.remove_actor("space_fixture_dock_blocker"))
	var undock: Dictionary = adapter.enter_space_orbit(id)
	assert(undock.ok and state.get_actor(id) == flight and fleet.get_craft_snapshot(id).phase == "orbit")
	sim.publish_singleplayer_local_return_events(adapter, undock.receipt_id); event_count = events.size()
	sim.publish_singleplayer_local_return_events(adapter, undock.receipt_id)
	assert(events.size() == event_count and "undock_station" in events)
	var returned_fuel: Dictionary = supply.export_state()
	assert(returned_fuel != fuel_before and adapter.enter_space_orbit(id).get("replayed", false) and supply.export_state() == returned_fuel)
	adapter.free(); pilot.free(); flow.free(); sim.free()
	_verify_reentrant_finish()
	print("SPACE_POLISA_ATOMIC_CANCEL passed")
	quit(0)

func _verify_reentrant_finish() -> void:
	var id := "space_fixture_polisa_reentry"
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id,"target_orbit_id":"polisa_orbit"}, "warp").ok)
	assert(_travel(fleet, "advance", {"craft_id":id,"delta_seconds":3.0}, "advance").ok)
	var supply = SUPPLY.new(); supply.configure([id]); supply.configure_inventory([], [id], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("polisa", "", "select")).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(campaign,supply,null,fleet)
	var flight: RefCounted = fleet.get_flight_state(id); var gate: Vector2i = GRID.from_offset(Vector2i(256,133))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:glut_2","position_plane":GRID.HEX.axial_to_plane(Vector2(gate)),"motion_mode":"tactical"},1).ok)
	var state: RefCounted = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id,"faction_id":"player","control_domain":"player","start_hex":gate,"footprint_hexes":[Vector2i.ZERO]},flight,true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer",[id],[id],{id:"pilot"}).ok); sim.tick_counter = 1
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = AdapterFixture.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._campaign = campaign; flow.adapter = adapter
	adapter.gate = {"ok":true,"departure":{"craft_id":id,"origin_location_id":"homebase","destination_location_id":"polisa","landing_pad_id":"homebase_pad_01","job_id":""}}
	var observed: Array = []
	sim.singleplayer_command_committed.connect(func(command: Dictionary, _result: Dictionary):
		if command.operation == "begin_station_dock":
			observed.append(flow._space_approaches.has(id))
			assert(adapter.finish_space_approach(id).ok)
			flow._space_approaches.erase(id))
	assert(adapter.request_operation("space_begin_station_dock", {"craft_id":id,"location_id":"polisa","target_id":"polisa_station_dock","layout_revision":"polisa_glut2_dock_v1","request_id":"reentrant"}).ok)
	assert(observed == [true] and fleet.get_craft_snapshot(id).phase == "surface" and not flow._space_approaches.has(id))
	adapter.free(); pilot.free(); flow.free(); sim.free()

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
