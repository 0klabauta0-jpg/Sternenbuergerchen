extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const CAMPAIGN = preload("res://scripts/core/singleplayer_campaign_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")

class Flow extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	var _last_mission_result := {}
	var _selected_mission_id := ""
	func _find_homebase_aircraft_definition(id: String) -> Dictionary: return {"craft_id":id}
class Pilot extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true

func _initialize() -> void:
	var trade := "--trade" in OS.get_cmdline_user_args()
	var location_id := "trade_outpost" if trade else "satellite_crash"
	var target_orbit := "glut_1b_orbit" if trade else "glut_1a_orbit"
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"ship"}, "request_id":"launch"}, {"runtime_authorized":true}).ok)
	var campaign = CAMPAIGN.new(); assert(campaign.configure().ok)
	assert(campaign.apply_command({"contract_category":"singleplayer_campaign", "operation":"select_destination", "payload":{"location_id":location_id}, "request_id":"select"}, {}).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(campaign, null, null, fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	var flight: RefCounted = fleet.get_flight_state("ship")
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "mass":equipment.get_space_flight_profile("ship").mass}, flight.get_snapshot().tick + 1).ok)
	sim.tick_counter = flight.get_snapshot().tick
	var flow = Flow.new(); var pilot = Pilot.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._campaign = campaign; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._space_route_requested = true
	sim.configure_base_personnel(pilot); assert(sim.configure_departure_adapter(adapter).ok)
	assert(not adapter._surface_orbit_path_enabled)
	adapter._record_surface_orbit_intent("ship", target_orbit)
	assert(adapter._surface_orbit_intents.is_empty())
	adapter._surface_orbit_path_enabled = true
	var start: Dictionary = adapter._request_space_operation("space_start_quantum", {"craft_id":"ship", "target_orbit_id":target_orbit}, "warp")
	if not start.get("ok", false): print("ADAPTER_WARP_START ", start)
	assert(start.ok and adapter._surface_orbit_intents.ship.location_id == location_id)
	for step in range(65):
		adapter.advance_space_travel(3.0)
		if fleet.get_craft_snapshot("ship").phase == "orbit" and sim.get_space_actor("ship") != null: break
	assert(fleet.get_craft_snapshot("ship").phase == "orbit" and adapter._surface_orbit_intents.ship.status == "flying")
	for step in range(10):
		sim.tick_counter = flight.get_snapshot().tick + 1
		sim._advance_space_flights(0.1, sim.tick_counter)
	assert(adapter.request_operation("space_set_orbit_automatic", {"craft_id":"ship", "enabled":false}).ok)
	for step in range(200):
		sim.tick_counter = flight.get_snapshot().tick + 1
		sim._advance_space_flights(0.1, sim.tick_counter); adapter.advance_space_travel(0.0)
		if adapter._surface_orbit_intents.ship.status == "manual": break
	assert(adapter._surface_orbit_intents.ship.status == "manual" and flight.get_snapshot().velocity_plane.length() < 0.02)
	assert(adapter.request_operation("space_set_orbit_automatic", {"craft_id":"ship", "enabled":true}).ok)
	assert(adapter._surface_orbit_intents.ship.status == "flying")
	for step in range(5000):
		sim.tick_counter = flight.get_snapshot().tick + 1
		sim._advance_space_flights(0.1, sim.tick_counter)
		adapter.advance_space_travel(0.0)
		if adapter._surface_orbit_intents.ship.status == "arrived":
			print("ORBIT_AUTO_TRAVEL_SECONDS ", float(step + 1) * 0.1)
			break
	assert(adapter._surface_orbit_intents.ship.status == "arrived")
	# Exercise the narrow callback window between real local-return publication
	# and its deferred outbound control without altering the Flight object.
	adapter._surface_orbit_intents.ship.direction = "outbound"
	adapter._surface_orbit_intents.ship.status = "starting"
	var request := {"craft_id":"ship", "target_orbit_id":"moon_orbit"}
	assert(adapter._request_space_operation("space_start_quantum", request, "queued").get("pending", false))
	assert(adapter._request_space_operation("space_start_quantum", request, "queued").get("pending", false))
	var changed := request.duplicate(); changed["target_orbit_marker_id"] = "orbit_2"
	assert(adapter._request_space_operation("space_start_quantum", changed, "queued").get("reason") == "request_id_conflict")
	assert(adapter.request_operation("space_set_orbit_automatic", {"craft_id":"ship", "enabled":false}).ok)
	assert(not adapter.get_space_travel_snapshot("ship").orbit_transit_automatic)
	assert(campaign.apply_command({"contract_category":"singleplayer_campaign", "operation":"select_destination", "payload":{"location_id":"polisa"}, "request_id":"select-polisa"}, {}).ok)
	adapter._record_surface_orbit_intent("ship", "polisa_orbit")
	assert(not adapter._surface_orbit_intents.has("ship"))
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("ORBIT_AUTO_TRANSIT_ADAPTER passed")
	quit()
