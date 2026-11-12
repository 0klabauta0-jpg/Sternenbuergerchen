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
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
class FlowFixture extends Node:
	var _space_approaches := {}
	var _transfer_sequence := 0
	var _selected_mission_id := ""
	var _last_mission_result := {}
	var _assigned_aircraft_pilot_by_craft := {"space_fixture_polisa_transaction":"pilot"}
	var home_landings := 0
	var adapter: Node
	func _find_homebase_aircraft_definition(id: String) -> Dictionary: return {"craft_id":id}
	func _finish_space_home_landing(_id: String) -> void: home_landings += 1
	func _begin_space_approach(id: String, departure: Dictionary) -> void:
		_space_approaches[id] = {"identity":{"craft_id":id, "location_id":departure.destination_location_id, "departure_token":adapter._departure_token_by_craft[id]}}
class PilotFixture extends Node:
	var aboard := false
	func is_pilot_aboard(_id: String) -> bool: return aboard
class AdapterFixture extends "res://scripts/meta/singleplayer_runtime_adapter.gd":
	var gate := {}
	var emit_progress := false
	func observe_campaign_progress() -> void:
		if emit_progress: _simulation.singleplayer_command_committed.emit({"operation":"onboarding_fixture"}, {})
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
	var supply = SUPPLY.new(); supply.configure([id]); supply.configure_inventory([], [id], false)
	var campaign = CAMPAIGN.new(); assert(campaign.configure({}, {}, false).ok)
	
	assert(campaign.apply_command(COMMANDS.build_select_destination_command("polisa", "", "select")).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(campaign, supply, null, fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":id,"model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	var flight = fleet.get_flight_state(id)
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = AdapterFixture.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._campaign = campaign; flow.adapter = adapter
	adapter._space_route_requested = true; pilot.aboard = true
	assert(not adapter._local_warp_arrival_enabled); adapter._local_warp_arrival_enabled = true
	adapter._pad_by_craft[id] = "homebase_pad_01"
	sim.configure_base_personnel(pilot)
	assert(sim.configure_departure_adapter(adapter).ok)
	for attempt in 65:
		adapter.advance_space_travel(3.0)
		if sim.get_space_actor(id) != null: break
	assert(sim.get_space_actor(id) == flight and flight.get_snapshot().space_area_id == "orbit_approach:glut_2")
	var state = sim.get("_space_combat_state")
	var gate: Vector2i = GRID.from_offset(Vector2i(256,133))
	# Limit this owner probe to the final movement leg; no whole-map soak.
	var start: Vector2i = GRID.from_offset(Vector2i(256,140))
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision,"position_plane":GRID.HEX.axial_to_plane(Vector2(start)),"velocity_plane":Vector2.ZERO},flight.get_snapshot().tick+1).ok)
	assert(state.update_actor_cell(id,start))
	sim.tick_counter = flight.get_snapshot().tick
	assert(adapter.request_operation("space_move", {"craft_id":id,"target_hex":gate,"request_id":"dock-gate"}).ok)
	for step in 1500:
		sim.tick_counter += 1; sim._advance_space_flights(1.0/60.0,sim.tick_counter)
		if state.get_flight_controls().is_empty(): break
	assert(sim.get_space_flight_status(id).get("reason") == "arrived")
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
	sim.tick_counter = flight.get_snapshot().tick
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
	sim.tick_counter = flight.get_snapshot().tick
	var back: Dictionary = adapter._request_space_operation("space_start_quantum", {"craft_id":id,"target_orbit_id":"moon_orbit"}, "polisa-home-warp")
	assert(back.ok and fleet.get_craft_snapshot(id).phase == "quantum" and sim.get_space_actor(id) == null)
	sim.tick_counter = flight.get_snapshot().tick
	var home := {}
	for attempt in 65:
		home = sim.advance_singleplayer_warp_entry(adapter,id,3.0)
		if home.get("status") == "complete": break
	assert(home.get("ok",false) and home.get("status") == "complete" and flight.get_snapshot().space_area_id == "orbit_approach:moon")
	var home_layout: Dictionary = LAYOUT.build("moon")
	var home_gate: Vector2i = GRID.from_offset(home_layout.gate_cells[128])
	var home_start: Vector2i = GRID.from_offset(GRID.to_offset(home_gate) + Vector2i(0,6))
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision,"position_plane":GRID.HEX.axial_to_plane(Vector2(home_start)),"velocity_plane":Vector2.ZERO},flight.get_snapshot().tick+1).ok)
	assert(state.update_actor_cell(id,home_start)); sim.tick_counter = flight.get_snapshot().tick
	assert(adapter.request_operation("space_move", {"craft_id":id,"target_hex":home_gate,"request_id":"home-gate"}).ok)
	for step in 1200:
		sim.tick_counter += 1; sim._advance_space_flights(1.0/60.0,sim.tick_counter)
		if state.get_flight_controls().is_empty(): break
	assert(sim.get_space_flight_status(id).get("reason") == "arrived")
	assert(adapter._request_space_operation("space_land_homebase", {"craft_id":id}, "land-home").ok)
	assert(fleet.get_craft_snapshot(id).phase == "grounded" and flow.home_landings == 1)
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("SPACE_POLISA_OWNER_CYCLE passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
