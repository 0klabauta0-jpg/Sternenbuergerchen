extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const EQUIPMENT = preload("res://scripts/core/singleplayer_ship_equipment_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

class PilotOwner extends Node:
	var aboard := true
	func is_pilot_aboard(_id: String) -> bool: return aboard

func _initialize() -> void:
	var sim = ROOT.new()
	var fleet = FLEET.new()
	assert(fleet.configure().ok)
	var id := "space_fixture_move"
	fleet.register_craft(id)
	var cmd := {"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":id}, "request_id":"launch"}
	assert(fleet.apply_command(cmd, {"runtime_authorized":true}).ok)
	var equipment = EQUIPMENT.new()
	assert(equipment.configure([{"craft_id":id, "model_id":"cutlass"}]).ok)
	var pilot = PilotOwner.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	sim.configure_ship_equipment(equipment)
	sim.configure_base_personnel(pilot)
	var flight = fleet.get_flight_state(id)
	var cell: Vector2i = GRID.from_offset(Vector2i(200, 100))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical"}, 1).ok)
	var state = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(sim.get("_space_wing_state").ensure_flying_wings("singleplayer", [id], [id], {id:"pilot"}).ok)
	var target := cell + Vector2i(4, 0)
	var request := {"craft_id":id, "target_hex":target, "request_id":"move"}
	var forged := request.duplicate(); forged["hull"] = {"main_thrust":999.0}
	assert(sim.request_singleplayer_space_move(forged).reason == "invalid_command")
	var outsider := request.duplicate(); outsider.craft_id = "unowned"
	assert(sim.request_singleplayer_space_move(outsider).reason == "not_owned")
	var obstacle = FLIGHT.new()
	obstacle.configure("space_fixture_obstacle", {"position_plane":GRID.HEX.axial_to_plane(Vector2(target)), "coordinate_frame":"local", "space_area_id":"orbit_approach:moon", "motion_mode":"tactical"})
	assert(state.admit_actor({"craft_id":"space_fixture_obstacle", "faction_id":"enemy", "control_domain":"enemy", "start_hex":target, "footprint_hexes":[Vector2i.ZERO]}, obstacle, true).ok)
	assert(sim.request_singleplayer_space_move(request).reason == "occupied")
	assert(state.remove_actor("space_fixture_obstacle"))
	pilot.aboard = false
	assert(sim.request_singleplayer_space_move(request).reason == "pilot_not_aboard")
	pilot.aboard = true
	assert(sim.request_singleplayer_space_move(request).ok)
	assert(sim.request_singleplayer_space_move(request).replayed)
	var altered := request.duplicate(); altered.target_hex += Vector2i(1,0)
	assert(sim.request_singleplayer_space_move(altered).reason == "request_id_conflict")
	var before: Vector2 = flight.get_snapshot().position_plane
	sim._advance_space_flights(0.1, 2)
	assert(flight.get_snapshot().position_plane != before)
	pilot.aboard = false
	var after: Dictionary = flight.get_snapshot()
	sim._advance_space_flights(0.1, 3)
	assert(flight.get_snapshot() == after and sim.get_space_flight_status(id).reason == "movement_context_changed")
	var claimed: Array[Vector2i] = [target]
	assert(state.query_navigation_claims(claimed, "orbit_approach:moon").is_empty())
	pilot.aboard = true
	var next_request := request.duplicate(); next_request.request_id = "move_after_pilot"
	assert(sim.request_singleplayer_space_move(next_request).ok)
	assert(equipment.configure([{"craft_id":id, "model_id":"unsupported"}]).ok)
	var stale_pose: Dictionary = flight.get_snapshot()
	sim._advance_space_flights(0.1, 4)
	assert(flight.get_snapshot() == stale_pose and sim.get_space_flight_status(id).reason == "movement_context_changed")
	assert(state.query_navigation_claims(claimed, "orbit_approach:moon").is_empty())
	pilot.free()
	sim.free()
	print("SPACE_SINGLEPLAYER_MOVE passed")
	quit(0)
