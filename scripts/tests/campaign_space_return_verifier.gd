extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const ENCOUNTER = preload("res://scripts/core/campaign_space_encounter.gd")
const COMPONENTS = preload("res://scripts/mission/space_component_catalog.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
class Pilot extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true

func _initialize() -> void:
	var id := "space_fixture_return"
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}).ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id,"target_orbit_id":"planet_orbit"}).ok)
	assert(_travel(fleet, "advance", {"craft_id":id,"delta_seconds":3.0}).ok)
	assert(_travel(fleet, "begin_approach", {"craft_id":id,"location_id":"distress_orbit"}).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var pilot = Pilot.new(); sim.configure_base_personnel(pilot)
	var adapter = ADAPTER.new(); assert(sim.configure_departure_adapter(adapter).ok)
	var flight: RefCounted = fleet.get_flight_state(id)
	var cell := Vector2i(20, 20)
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:planet","position_plane":GRID.HEX.axial_to_plane(Vector2(cell)),"motion_mode":"tactical"}, 1).ok)
	var combat: RefCounted = sim.get("_space_combat_state")
	assert(combat.admit_actor({"craft_id":id,"faction_id":"player","control_domain":"player","start_hex":cell,"footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(combat.bind_ship_systems(id, COMPONENTS.effective_stats("cutlass", COMPONENTS.default_loadout("cutlass")), 100.0).ok)
	sim.tick_counter = 1
	var encounter = ENCOUNTER.new(); assert(encounter.start_encounter(id).ok); sim.configure_space_encounter(encounter)
	assert(sim.admit_campaign_space_contacts(id, {"runtime_authorized":true}).ok)
	assert(not sim.commit_campaign_space_return(adapter, id, "return-1").ok)
	assert(encounter.apply_command({"contract_category":"campaign_space","operation":"retreat","payload":{}}, {}).ok)
	var result: Dictionary = sim.commit_campaign_space_return(adapter, id, "return-1")
	assert(result.ok and fleet.get_craft_snapshot(id).phase == "orbit" and combat.get_actor(id) == flight)
	assert(combat.get_actor("hostile_cutlass") == null and combat.get_actor("neutral_buccaneer") == null)
	assert(sim.commit_campaign_space_return(adapter, id, "return-1").replayed)
	assert(sim.commit_campaign_space_return(adapter, "other", "return-1").reason == "request_id_conflict")
	adapter.free(); pilot.free(); sim.free()
	print("CAMPAIGN_SPACE_RETURN passed")
	quit()

func _travel(fleet: RefCounted, operation: String, payload: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":operation,"payload":payload,"request_id":"fixture-" + operation}, {"runtime_authorized":true})
