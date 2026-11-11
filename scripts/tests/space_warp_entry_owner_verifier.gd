extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
class FlowFixture extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
class PilotFixture extends Node:
	var aboard := false
	func is_pilot_aboard(_craft_id: String) -> bool: return aboard

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"planet_orbit"}, "warp").ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot
	assert(sim.configure_departure_adapter(adapter).ok)
	var flight = fleet.get_flight_state("ship"); var before: Dictionary = flight.get_snapshot()
	assert(sim.advance_singleplayer_warp_entry(adapter, "ship", 3.0).reason == "pilot_not_aboard" and flight.get_snapshot() == before and fleet.get_snapshot("ship").phase == "quantum")
	pilot.aboard = true
	var state = sim.get("_space_combat_state")
	var blocker = FLIGHT.new(); var blocker_cell: Vector2i = GRID.from_offset(Vector2i(5, 100))
	assert(blocker.configure("space_fixture_entry_blocker", {"position_plane":GRID.HEX.axial_to_plane(Vector2(blocker_cell)), "coordinate_frame":"local", "space_area_id":"orbit_approach:planet", "motion_mode":"tactical"}).ok)
	assert(state.admit_actor({"craft_id":"space_fixture_entry_blocker", "faction_id":"enemy", "control_domain":"enemy", "start_hex":blocker_cell, "footprint_hexes":[Vector2i.ZERO]}, blocker, true).ok)
	var claims: Array[Vector2i] = []
	for x in 256: claims.append(GRID.from_offset(Vector2i(x, 255)))
	assert(state.record_navigation_claim("space_fixture_entry_blocker", "orbit_approach:planet", claims).ok)
	var result: Dictionary = sim.advance_singleplayer_warp_entry(adapter, "ship", 3.0)
	assert(result.ok and result.status == "pending" and fleet.get_craft_snapshot("ship").phase == "quantum")
	for _attempt in 65:
		result = sim.advance_singleplayer_warp_entry(adapter, "ship", 0.01)
		assert(result.ok)
		if result.status == "complete": break
	assert(result.status == "complete" and fleet.get_snapshot("ship").phase == "orbit")
	assert(flight.get_snapshot().motion_mode == "tactical" and flight.get_snapshot().space_area_id == "orbit_approach:planet" and sim.get_space_actor("ship") == flight)
	for cell: Vector2i in state.get_indexed_actor_cells("ship"): assert(LAYOUT.ENTRY_BAND.has_point(GRID.to_offset(cell)))
	assert(state.get_metadata("ship").footprint_hexes == [Vector2i.ZERO, Vector2i(1, 0)])
	assert(not sim.get("_space_wing_state").get_craft_wing("ship", "singleplayer").is_empty())
	pilot.aboard = false
	var arrived: Dictionary = flight.get_snapshot()
	var repeated: Dictionary = sim.advance_singleplayer_warp_entry(adapter, "ship", 3.0)
	assert(repeated.replayed and repeated.travel_result.replayed and flight.get_snapshot() == arrived)
	var observed := []
	sim.singleplayer_command_committed.connect(func(_command: Dictionary, _result: Dictionary): observed.append(sim.advance_singleplayer_warp_entry(adapter, "ship", 3.0).get("replayed", false)))
	sim.publish_singleplayer_warp_entry_event(adapter, result.receipt_id)
	sim.publish_singleplayer_warp_entry_event(adapter, result.receipt_id)
	assert(observed == [true] and flight.get_snapshot() == arrived)
	assert(state.remove_actor("space_fixture_entry_blocker"))
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("SPACE_WARP_ENTRY_OWNER passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
