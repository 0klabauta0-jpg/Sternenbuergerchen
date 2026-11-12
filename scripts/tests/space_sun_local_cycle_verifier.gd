extends SceneTree
## Private project copy only: replaces its copied V2 catalog with V3 product data.
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const CATALOG = preload("res://scripts/mission/orbit_destination_catalog.gd")
const PATH := "res://data/singleplayer/star_system.json"
class FlowFixture extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	var _selected_mission_id := ""
	var _last_mission_result := {}
class PilotFixture extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true

func _initialize() -> void:
	if not ProjectSettings.get_setting("space_reader_probe/isolated", false):
		push_error("This verifier requires a private project copy"); quit(1); return
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	var compiled: Dictionary = CATALOG.build_v3_product(legacy); assert(compiled.ok)
	var file := FileAccess.open(PATH, FileAccess.WRITE); assert(file != null)
	file.store_string(JSON.stringify(compiled.definition)); file.close()
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet,"launch_to_orbit",{"craft_id":"ship"}).ok)
	assert(_travel(fleet,"start_quantum",{"craft_id":"ship","target_orbit_id":"sun_orbit"}).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null,null,null,fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship","model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._space_route_requested = true
	assert(sim.configure_departure_adapter(adapter).ok)
	var result := {}
	for attempt in 65:
		result = sim.advance_singleplayer_warp_entry(adapter,"ship",3.0)
		if result.get("status") == "complete": break
	var flight: RefCounted = fleet.get_flight_state("ship")
	assert(result.get("ok",false) and result.get("status") == "complete" and flight.get_snapshot().space_area_id == "orbit_approach:sun")
	assert(not _travel(fleet,"begin_approach",{"craft_id":"ship","location_id":"sun"}).ok)
	sim.tick_counter = flight.get_snapshot().tick
	assert(adapter._request_space_operation("space_start_quantum",{"craft_id":"ship","target_orbit_id":"moon_orbit"},"sun-exit").ok)
	assert(fleet.get_craft_snapshot("ship").phase == "quantum" and sim.get_space_actor("ship") == null)
	adapter.free(); pilot.free(); flow.free(); sim.free(); print("Sun local V3 arrival and exit passed"); quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":operation,"payload":payload},{"runtime_authorized":true})
