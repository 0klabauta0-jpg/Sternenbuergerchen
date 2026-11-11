extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
class FlowFixture extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	var _last_mission_result := {}
class PilotFixture extends Node:
	var aboard := true
	func is_pilot_aboard(_id: String) -> bool: return aboard

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"planet_orbit"}, "inbound").ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._space_route_requested = true
	assert(sim.configure_departure_adapter(adapter).ok)
	assert(_arrive(sim, adapter))
	var flight = fleet.get_flight_state("ship")
	assert(fleet.get_craft_snapshot("ship").phase == "orbit" and flight.get_snapshot().motion_mode == "tactical" and flight.get_snapshot().space_area_id == "orbit_approach:planet")
	var wing: String = sim.get("_space_wing_state").get_craft_wing("ship", "singleplayer")
	assert(not wing.is_empty())
	sim.tick_counter = flight.get_snapshot().tick
	var before: Dictionary = flight.get_snapshot(); pilot.aboard = false
	assert(not adapter._request_space_operation("space_start_quantum", {"craft_id":"ship", "target_orbit_id":"moon_orbit"}, "denied").ok and flight.get_snapshot() == before)
	pilot.aboard = true
	assert(not adapter._request_space_operation("space_start_quantum", {"craft_id":"ship", "target_orbit_id":"unknown"}, "wrong-target").ok and flight.get_snapshot() == before and fleet.get_craft_snapshot("ship").phase == "orbit")
	var departure: Dictionary = adapter._request_space_operation("space_start_quantum", {"craft_id":"ship", "target_orbit_id":"moon_orbit"}, "outbound")
	assert(departure.ok and fleet.get_craft_snapshot("ship").phase == "quantum" and flight.get_snapshot().coordinate_frame == "strategic" and sim.get_space_actor("ship") == null)
	assert(adapter._request_space_operation("space_start_quantum", {"craft_id":"ship", "target_orbit_id":"moon_orbit"}, "outbound").replayed)
	assert(sim.get("_space_wing_state").get_craft_wing("ship", "singleplayer") == wing)
	sim.tick_counter = flight.get_snapshot().tick
	assert(_arrive(sim, adapter))
	assert(fleet.get_craft_snapshot("ship").phase == "orbit" and flight.get_snapshot().space_area_id == "orbit_approach:moon" and flight.get_snapshot().motion_mode == "tactical")
	for cell: Vector2i in sim.get("_space_combat_state").get_indexed_actor_cells("ship"): assert(LAYOUT.ENTRY_BAND.has_point(GRID.to_offset(cell)))
	assert(sim.get("_space_wing_state").get_craft_wing("ship", "singleplayer") == wing)
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("SPACE_WARP_PRODUCT_CYCLE passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})

func _arrive(sim: Node, adapter: Node) -> bool:
	for _attempt in 65:
		var result: Dictionary = sim.advance_singleplayer_warp_entry(adapter, "ship", 3.0)
		if not result.get("ok", false): return false
		if result.get("status") == "complete": return true
	return false
