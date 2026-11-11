extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"polisa_orbit"}, "warp").ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var adapter = ADAPTER.new(); adapter._simulation = sim; adapter._travel = fleet; adapter._local_warp_arrival_enabled = true
	adapter.advance_space_travel(3.0)
	assert(fleet.get_craft_snapshot("ship").phase == "orbit" and fleet.get_craft_snapshot("ship").orbit_id == "polisa_orbit")
	assert(fleet.get_flight_state("ship").get_snapshot().coordinate_frame == "strategic" and sim.get_space_actor("ship") == null)
	assert(_travel(fleet, "begin_approach", {"craft_id":"ship", "location_id":"polisa"}, "station-approach").ok)
	assert(_travel(fleet, "finish_approach", {"craft_id":"ship"}, "station-finish").ok)
	assert(_travel(fleet, "enter_orbit", {"craft_id":"ship"}, "station-return").ok and fleet.get_craft_snapshot("ship").orbit_id == "polisa_orbit")
	adapter.free(); sim.free()
	print("SPACE_WARP_POLISA_COMPAT passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})
