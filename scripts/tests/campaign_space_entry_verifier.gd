extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const SUPPLY = preload("res://scripts/core/singleplayer_supply_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const ENCOUNTER = preload("res://scripts/core/campaign_space_encounter.gd")
class Pilot extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true
class Flow extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}).ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"planet_orbit"}).ok)
	assert(_travel(fleet, "advance", {"craft_id":"ship", "delta_seconds":3.0}).ok)
	assert(_travel(fleet, "begin_approach", {"craft_id":"ship", "location_id":"distress_orbit"}).ok)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok)
	var supply = SUPPLY.new(); assert(supply.configure(["ship"]).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, supply, null, fleet); sim.configure_ship_equipment(equipment)
	var flight: RefCounted = fleet.get_flight_state("ship")
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "mass":equipment.get_space_flight_profile("ship").mass}, 0).ok)
	var original_pose: Dictionary = flight.get_snapshot()
	var pilot = Pilot.new(); sim.configure_base_personnel(pilot)
	var flow = Flow.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot
	assert(sim.configure_departure_adapter(adapter).ok)
	adapter._departure_token_by_craft.ship = "fixture-departure"
	sim.get("_departure_group_receipts")["fixture-departure"] = {"craft_id":"ship", "supply":supply, "supply_epoch":supply.get("_route_prepare_epoch"), "fleet":fleet, "flight":flight, "result":{"departure":{"destination_location_id":"distress_orbit"}}}
	var encounter = ENCOUNTER.new(); assert(encounter.start_encounter("ship", true).ok)
	adapter._space_encounter = encounter; sim.configure_space_encounter(encounter)
	assert(not sim.advance_campaign_space_entry(adapter, "other").ok)
	assert(sim.cancel_campaign_space_entry(adapter, "ship").ok)
	assert(encounter.apply_command({"contract_category":"campaign_space", "operation":"retreat", "payload":{}}, {}).ok)
	assert(encounter.start_encounter("ship", true).ok)
	for step in range(100):
		if encounter.get_snapshot().phase == "combat": break
		sim.tick_counter += 1
		adapter.advance_space_travel(0.3)
	assert(encounter.get_snapshot().phase == "combat")
	assert(sim.get_space_actor("ship") == flight and flight.get_snapshot().coordinate_frame == "local")
	assert(sim.get_space_actor("hostile_cutlass") != null and sim.get_space_actor("neutral_buccaneer") != null)
	assert(adapter.request_operation("campaign_space_engage", {}).ok)
	var before: float = sim.get("_space_combat_state").get_ship_systems("hostile_cutlass").state.shield
	sim.tick_counter += 1; adapter.advance_space_travel(0.1)
	assert(sim.get("_space_combat_state").get_ship_systems("hostile_cutlass").state.shield < before)
	# Reproduce a contact-admission failure after player publication to check
	# the recovery tail without depending on chance placement conflicts.
	var combat: RefCounted = sim.get("_space_combat_state")
	assert(combat.remove_actor("hostile_cutlass") and combat.remove_actor("neutral_buccaneer"))
	encounter.set("_combat_owner", null); encounter.get("_state").phase = "entering"
	sim.get("_campaign_space_entry_origins")["ship"] = {"flight":flight, "position":original_pose.position_plane, "heading":original_pose.heading_rad}
	assert(sim.cancel_campaign_space_entry(adapter, "ship").ok)
	assert(flight.get_snapshot().coordinate_frame == "strategic" and flight.get_snapshot().position_plane == original_pose.position_plane and sim.get_space_actor("ship") == null)
	adapter.free(); flow.free(); pilot.free(); sim.free()
	print("CAMPAIGN_SPACE_ENTRY passed")
	quit()

func _travel(fleet: RefCounted, operation: String, payload: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":"fixture-" + operation}, {"runtime_authorized":true})
