extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

class Pilot extends Node:
	func is_pilot_aboard(_id: String) -> bool: return true

func _initialize() -> void:
	var sim = ROOT.new(); var fleet = FLEET.new(); assert(fleet.configure().ok)
	var id := "space_fixture_transit"; fleet.register_craft(id)
	assert(fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":id}, "request_id":"launch"}, {"runtime_authorized":true}).ok)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":id, "model_id":"cutlass"}]).ok)
	var pilot = Pilot.new(); var adapter = ADAPTER.new()
	sim.configure_singleplayer_owners(null, null, null, fleet); sim.configure_ship_equipment(equipment); sim.configure_base_personnel(pilot)
	assert(sim.configure_departure_adapter(adapter).ok)
	var flight: RefCounted = fleet.get_flight_state(id)
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "mass":equipment.get_space_flight_profile(id).mass}, flight.get_snapshot().tick + 1).ok)
	var start: Vector2i = GRID.from_offset(Vector2i(256, 240))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "position_plane":GRID.HEX.axial_to_plane(Vector2(start)), "motion_mode":"tactical"}, flight.get_snapshot().tick + 1).ok)
	var combat: RefCounted = sim.get("_space_combat_state")
	assert(combat.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":start, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer", [id], [id], {id:"pilot"}).ok)
	assert(not sim.start_singleplayer_orbit_transit(adapter, id, "polisa", "inbound", "invalid").ok)
	var result: Dictionary = sim.start_singleplayer_orbit_transit(adapter, id, "homebase", "inbound", "transit")
	if not result.get("ok", false): print("ORBIT_AUTO_TRANSIT_START ", result)
	assert(result.ok and GRID.to_offset(result.target_hex).y < 10)
	var before: Vector2 = flight.get_snapshot().position_plane
	sim._advance_space_flights(0.1, flight.get_snapshot().tick)
	assert(flight.get_snapshot().position_plane == before and combat.get_flight_controls().has(id))
	sim._advance_space_flights(0.1, flight.get_snapshot().tick + 1)
	assert(flight.get_snapshot().position_plane != before)
	assert(sim.stop_singleplayer_orbit_transit(adapter, id).ok)
	for step in range(200):
		sim._advance_space_flights(0.1, flight.get_snapshot().tick + 1)
		if sim.get_space_flight_status(id).get("reason") == "interrupted": break
	assert(sim.get_space_flight_status(id).get("reason") == "interrupted")
	assert(flight.get_snapshot().velocity_plane.length() < 0.02)
	assert(sim.start_singleplayer_orbit_transit(adapter, id, "homebase", "inbound", "restart").ok)
	var current: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(flight.get_snapshot().position_plane))
	var enemy_cell := current + Vector2i(3, 0)
	var enemy = FLIGHT.new()
	assert(enemy.configure("space_fixture_enemy", {"position_plane":GRID.HEX.axial_to_plane(Vector2(enemy_cell)), "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "motion_mode":"tactical"}).ok)
	assert(combat.admit_actor({"craft_id":"space_fixture_enemy", "faction_id":"enemy", "control_domain":"enemy", "start_hex":enemy_cell, "footprint_hexes":[Vector2i.ZERO]}, enemy, true).ok)
	for step in range(200):
		sim._advance_space_flights(0.1, flight.get_snapshot().tick + 1)
		if sim.get_space_flight_status(id).get("reason") == "interrupted": break
	assert(sim.get_space_flight_status(id).get("reason") == "interrupted")
	assert(flight.get_snapshot().velocity_plane.length() < 0.02)
	adapter.free(); pilot.free(); sim.free()
	print("ORBIT_AUTO_TRANSIT_OWNER passed")
	quit()
