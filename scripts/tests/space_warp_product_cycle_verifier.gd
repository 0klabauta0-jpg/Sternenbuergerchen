extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const LAYOUT = preload("res://scripts/mission/orbit_approach_layout.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const COMPONENTS = preload("res://scripts/mission/space_component_catalog.gd")
const ENCOUNTER = preload("res://scripts/core/campaign_space_encounter.gd")
class FlowFixture extends Node:
	var _assigned_aircraft_pilot_by_craft := {"ship":"pilot"}
	var _last_mission_result := {}
	var _selected_mission_id := ""
	var home_landings := 0
	func _find_homebase_aircraft_definition(id: String) -> Dictionary: return {"craft_id":id}
	func _finish_space_home_landing(_id: String) -> void: home_landings += 1
class PilotFixture extends Node:
	var aboard := true
	func is_pilot_aboard(_id: String) -> bool: return aboard

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok); fleet.register_craft("ship")
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":"ship"}, "launch").ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":"ship", "target_orbit_id":"planet_orbit"}, "inbound").ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null, null, null, fleet)
	var equipment = EQUIPMENT.new(); assert(equipment.configure([{"craft_id":"ship", "model_id":"cutlass"}]).ok); sim.configure_ship_equipment(equipment)
	# This fixture bypasses Root launch; reproduce the already-authorized
	# launch mass before testing the actual warp-entry guard.
	var fixture_flight = fleet.get_flight_state("ship")
	assert(fixture_flight.commit_motion({"expected_revision":fixture_flight.get_snapshot().revision,"mass":equipment.get_space_flight_profile("ship").mass},fixture_flight.get_snapshot().tick+1).ok)
	sim.tick_counter = fixture_flight.get_snapshot().tick
	var flow = FlowFixture.new(); var pilot = PilotFixture.new(); var adapter = ADAPTER.new()
	adapter._simulation = sim; adapter._travel = fleet; adapter._flow = flow; adapter._base_personnel = pilot; adapter._space_route_requested = true
	sim.configure_base_personnel(pilot)
	assert(not adapter._local_warp_arrival_enabled)
	adapter._local_warp_arrival_enabled = true
	adapter._pad_by_craft["ship"] = "homebase_pad_01"
	assert(sim.configure_departure_adapter(adapter).ok)
	pilot.aboard = false
	adapter.advance_space_travel(3.0)
	assert(fleet.get_craft_snapshot("ship").phase == "quantum" and adapter._warp_arrival_feedback.ship.reason == "pilot_not_aboard")
	var blocked_travel: Dictionary = fleet.get_craft_snapshot("ship")
	var blocked_pose: Dictionary = fleet.get_flight_state("ship").get_snapshot()
	adapter.advance_space_travel(0.01)
	assert(fleet.get_craft_snapshot("ship") == blocked_travel and fleet.get_flight_state("ship").get_snapshot() == blocked_pose)
	pilot.aboard = true
	assert(_arrive(sim, adapter))
	var flight = fleet.get_flight_state("ship")
	var systems: Dictionary = sim.get("_space_combat_state").get_ship_systems("ship")
	assert(not systems.is_empty() and systems.state.shield == equipment.get_space_combat_stats("ship").shield.capacity)
	var source_cell: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(flight.get_snapshot().position_plane))
	var enemy_cell := source_cell + Vector2i(3,0)
	var enemy = FLIGHT.new(); assert(enemy.configure("space_fixture_enemy", {"coordinate_frame":"local", "space_area_id":flight.get_snapshot().space_area_id, "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(enemy_cell))}).ok)
	var combat: RefCounted = sim.get("_space_combat_state")
	assert(combat.admit_actor({"craft_id":"space_fixture_enemy", "faction_id":"enemy", "control_domain":"enemy", "start_hex":enemy_cell, "footprint_hexes":[Vector2i.ZERO]}, enemy, true).ok)
	assert(combat.bind_ship_systems("space_fixture_enemy", COMPONENTS.effective_stats("buccaneer", COMPONENTS.default_loadout("buccaneer")), 100.0).ok)
	var wing_owner: RefCounted = sim.get("_space_wing_state")
	var own_wing: String = wing_owner.get_craft_wing("ship", "singleplayer")
	var fire := {"request_id":"fixture-shot", "craft_id":"ship", "target_id":"space_fixture_enemy", "weapon_slot":"weapon_1"}
	assert(not sim.request_singleplayer_space_fire(fire, {}).ok)
	assert(adapter.request_operation("space_fire", fire).reason == "attack_order_required")
	var order := {"contract_category":"space_combat", "operation":"order_issue", "request_id":"fixture-order", "expected_revision":wing_owner.get_snapshot().revision, "payload":{"wing_ids":[own_wing], "verb":"attack_target", "target_id":"space_fixture_enemy", "fire_rule":"free"}}
	assert(wing_owner.apply_command(order, {"authorized":true, "actor_id":"singleplayer", "phase":"tactical", "owned_crafts":["ship"], "craft_pilots":{"ship":"pilot"}, "known_targets":["space_fixture_enemy"], "coordinate_frame":"local", "space_area_id":flight.get_snapshot().space_area_id}).ok)
	pilot.aboard = false
	assert(adapter.request_operation("space_fire", fire).reason == "pilot_not_aboard")
	pilot.aboard = true
	var shot: Dictionary = adapter.request_operation("space_fire", fire)
	if not shot.get("ok", false): print("FIRE_DIAGNOSTIC: ", shot)
	assert(shot.ok and shot.impact.shield_damage == 4.0 and combat.get_ship_systems("space_fixture_enemy").state.shield == 20.0)
	assert(adapter.request_operation("space_fire", fire).replayed and combat.get_ship_systems("space_fixture_enemy").state.shield == 20.0)
	var conflict := fire.duplicate(); conflict.weapon_slot = "weapon_2"
	assert(adapter.request_operation("space_fire", conflict).reason == "request_id_conflict")
	var rapid := fire.duplicate(); rapid.request_id = "rapid-shot"
	assert(not adapter.request_operation("space_fire", rapid).ok and combat.get_ship_systems("space_fixture_enemy").state.shield == 20.0)
	assert(combat.remove_actor("space_fixture_enemy"))
	var encounter = ENCOUNTER.new(); assert(encounter.start_encounter("ship").ok)
	sim.configure_space_encounter(encounter)
	assert(not sim.admit_campaign_space_contacts("ship", {}).ok)
	assert(sim.admit_campaign_space_contacts("ship", {"runtime_authorized":true}).ok)
	assert(combat.get_actor("hostile_cutlass") != null and combat.get_actor("neutral_buccaneer") != null)
	assert(not sim.admit_campaign_space_contacts("ship", {"runtime_authorized":true}).ok)
	adapter._space_encounter = encounter
	assert(not adapter.request_operation("campaign_space_engage", {"target_id":"buccaneer"}).ok)
	assert(adapter.request_operation("campaign_space_engage", {}).ok)
	var before_shield: float = combat.get_ship_systems("hostile_cutlass").state.shield
	sim.tick_counter += 1
	adapter.advance_space_travel(0.1)
	assert(combat.get_ship_systems("hostile_cutlass").state.shield < before_shield)
	assert(encounter.apply_command({"contract_category":"campaign_space", "operation":"advance", "payload":{"delta_seconds":1.0}}, {"runtime_authorized":true}).ok)
	assert(encounter.get_snapshot().cutlass_hull == combat.get_ship_systems("hostile_cutlass").state.hull)
	for step in range(40):
		if encounter.get_snapshot().phase != "combat": break
		assert(combat.advance_ship_systems(0.5).ok)
		sim.tick_counter += 1
		adapter.advance_space_travel(0.5)
	assert(encounter.get_snapshot().phase == "rescue_ready" and combat.get_ship_systems("neutral_buccaneer").state.hull > 0.0)
	assert(combat.remove_actor("hostile_cutlass") and combat.remove_actor("neutral_buccaneer"))
	# Fixture injury: verify an actual warp transition cannot silently repair it.
	sim.get("_space_combat_state").get("_ship_systems").ship.state.hull = 77.0
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
	assert(sim.get("_space_combat_state").get_ship_systems("ship").state.hull == 77.0)
	assert(is_zero_approx(flight.get_snapshot().heading_rad))
	for cell: Vector2i in sim.get("_space_combat_state").get_indexed_actor_cells("ship"): assert(LAYOUT.ENTRY_BAND.has_point(GRID.to_offset(cell)))
	assert(sim.get("_space_wing_state").get_craft_wing("ship", "singleplayer") == wing)
	assert(adapter._request_space_operation("space_land_homebase", {"craft_id":"ship"}, "home-too-early").get("reason") == "not_at_home_gate")
	var state = sim.get("_space_combat_state")
	var layout: Dictionary = LAYOUT.build("moon")
	var body := {}; var gates := {}
	for cell in layout.body_cells: body[cell] = true
	for cell in layout.gate_cells: gates[cell] = true
	var target := Vector2.INF
	for offset in layout.gate_cells:
		var point: Vector2 = GRID.HEX.axial_to_plane(Vector2(GRID.from_offset(offset)))
		var cells: Array[Vector2i] = state.preview_actor_cells("ship", {"position_plane":point})
		var valid := not cells.is_empty(); var at_gate := false
		for cell in cells:
			if body.has(GRID.to_offset(cell)): valid = false
			if gates.has(GRID.to_offset(cell)): at_gate = true
		if valid and at_gate: target = point; break
	assert(target.is_finite())
	var target_hex: Vector2i = GRID.HEX.round_axial(GRID.HEX.plane_to_axial(target))
	# Place the fixture several cells before the gate, then use the real command
	# and 60 Hz flight tick for the final approach (no whole-map soak).
	var start_hex: Vector2i = GRID.from_offset(GRID.to_offset(target_hex) + Vector2i(0, 6))
	var start_position: Vector2 = GRID.HEX.axial_to_plane(Vector2(start_hex))
	assert(flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "position_plane":start_position, "velocity_plane":Vector2.ZERO}, flight.get_snapshot().tick + 1).ok)
	assert(state.update_actor_cell("ship", start_hex))
	var move: Dictionary = adapter.request_operation("space_move", {"craft_id":"ship", "target_hex":target_hex, "request_id":"to-home-gate"})
	if not move.get("ok", false): print("HOME_GATE_MOVE_REJECT: ", move, " target=", target_hex)
	assert(move.ok)
	sim.tick_counter = flight.get_snapshot().tick
	for _step in 1200:
		sim.tick_counter += 1
		sim._advance_space_flights(1.0 / 60.0, sim.tick_counter)
		if state.get_flight_controls().is_empty(): break
	if sim.get_space_flight_status("ship").get("reason") != "arrived": print("HOME_GATE_MOVE_STATUS: ", sim.get_space_flight_status("ship"), " pose=", flight.get_snapshot(), " target=", target, " control=", state.get_flight_controls())
	assert(sim.get_space_flight_status("ship").get("reason") == "arrived")
	pilot.aboard = false
	assert(adapter._request_space_operation("space_land_homebase", {"craft_id":"ship"}, "home-no-pilot").get("reason") == "pilot_not_aboard")
	pilot.aboard = true
	assert(adapter._request_space_operation("space_land_homebase", {"craft_id":"ship"}, "home").ok)
	assert(fleet.get_craft_snapshot("ship").phase == "grounded" and flight.get_snapshot().motion_mode == "grounded" and sim.get_space_actor("ship") == null and flow.home_landings == 1)
	assert(adapter._request_space_operation("space_land_homebase", {"craft_id":"ship"}, "home").replayed and flow.home_landings == 1)
	var landed_pose: Dictionary = flight.get_snapshot()
	assert(sim.commit_singleplayer_space_launch(adapter, "ship", "space-operation:home").get("reason") == "request_id_conflict" and flight.get_snapshot() == landed_pose)
	adapter.free(); pilot.free(); flow.free(); sim.free()
	print("SPACE_WARP_PRODUCT_CYCLE passed")
	quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary, request_id: String) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":operation, "payload":payload, "request_id":request_id}, {"runtime_authorized":true})

func _arrive(sim: Node, adapter: Node) -> bool:
	for _attempt in 65:
		adapter.advance_space_travel(3.0)
		if adapter._travel.get_craft_snapshot("ship").phase == "orbit" and sim.get_space_actor("ship") != null: return true
	return false
