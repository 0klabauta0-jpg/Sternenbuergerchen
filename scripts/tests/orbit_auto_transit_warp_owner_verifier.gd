extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")

class Flow extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	var _last_mission_result := {}
	var _selected_mission_id := ""
	func _find_homebase_aircraft_definition(id: String) -> Dictionary: return {"craft_id":id}
class Pilot extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"glut_1a_orbit"}, "warp").ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	# The fixture begins after launch; publish the same equipment-derived mass
	# the real launch path would have already bound.
	var flight = fleet.get_flight_state("ship")
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "mass":equipment.get_space_flight_profile("ship").mass}, flight.get_snapshot().tick + 1).ok)
	sim.tick_counter = flight.get_snapshot().tick
	var flow = Flow.new(); var pilot = Pilot.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._space_route_requested = true; adapter._local_warp_arrival_enabled = true
	sim.configure_base_personnel(pilot); assert(sim.configure_departure_adapter(adapter).ok)
	for step in range(65):
		adapter.advance_space_travel(3.0)
		if fleet.get_craft_snapshot("ship").phase == "orbit" and sim.get_space_actor("ship") != null: break
	assert(fleet.get_craft_snapshot("ship").phase == "orbit" and sim.get_space_actor("ship") != null)
	var result: Dictionary = sim.start_singleplayer_orbit_transit(adapter, "ship", "satellite_crash", "inbound", "real-cutlass-transit")
	print("CUTLASS_TRANSIT_RESULT ", result)
	assert(result.ok)
	for step in range(5000):
		sim.tick_counter = flight.get_snapshot().tick + 1
		sim._advance_space_flights(0.1, sim.tick_counter)
		if sim.get_space_flight_status("ship").get("reason") == "arrived": break
	var status: Dictionary = sim.get_space_flight_status("ship")
	if status.get("reason") != "arrived": print("CUTLASS_TRANSIT_FAILURE ", status, " pose=", flight.get_snapshot())
	assert(status.get("reason") == "arrived")
	var combat: RefCounted = sim.get("_space_combat_state")
	var wings: RefCounted = sim.get("_space_wing_state")
	var gate: Dictionary = sim.preview_surface_approach("ship", "satellite_crash", flight.get_snapshot().revision, fleet.get_craft_snapshot("ship").revision, combat.get_area_revision(flight.get_snapshot().space_area_id), wings.get_snapshot().revision, {"runtime_authorized":true, "actor_id":"singleplayer"})
	if not gate.get("ok", false): print("CUTLASS_GATE_FAILURE ", gate)
	assert(gate.ok)
	adapter._surface_orbit_path_enabled = true
	adapter._surface_orbit_intents["ship"] = {"location_id":"satellite_crash", "direction":"outbound", "status":"arrived"}
	var premature: Dictionary = sim.commit_singleplayer_warp_departure(adapter, {"craft_id":"ship", "target_orbit_id":"moon_orbit", "request_id":"before-exit"})
	assert(premature.get("reason") == "space_exit_band_required" and fleet.get_craft_snapshot("ship").phase == "orbit")
	assert(sim.start_singleplayer_orbit_transit(adapter, "ship", "satellite_crash", "outbound", "real-cutlass-return").ok)
	for step in range(5000):
		sim.tick_counter = flight.get_snapshot().tick + 1
		sim._advance_space_flights(0.1, sim.tick_counter)
		if sim.get_space_flight_status("ship").get("reason") == "arrived": break
	assert(sim.get_space_flight_status("ship").get("reason") == "arrived")
	var warp: Dictionary = sim.preview_warp_departure("ship", "moon_orbit", flight.get_snapshot().revision, fleet.get_craft_snapshot("ship").revision, combat.get_area_revision(flight.get_snapshot().space_area_id), wings.get_snapshot().revision, {"runtime_authorized":true, "actor_id":"singleplayer"})
	if not warp.get("ok", false): print("CUTLASS_WARP_GATE_FAILURE ", warp)
	assert(warp.ok)
	assert(sim.commit_singleplayer_warp_departure(adapter, {"craft_id":"ship", "target_orbit_id":"moon_orbit", "request_id":"after-exit"}).ok)
	assert(fleet.get_craft_snapshot("ship").phase == "quantum")
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("ORBIT_AUTO_TRANSIT_WARP_OWNER passed")
	quit()

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
