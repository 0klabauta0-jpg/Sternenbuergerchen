extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var sim = ROOT.new()
	var fleet = FLEET.new()
	fleet.configure()
	var state = sim.get("_space_combat_state")
	var wings = sim.get("_space_wing_state")
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var ids := ["space_fixture_read_a", "space_fixture_read_b"]
	for index in ids.size():
		var id: String = ids[index]
		fleet.register_craft(id)
		var flight = fleet.get_flight_state(id)
		var cell := Vector2i(index * 4, 2)
		assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision, "coordinate_frame":"local", "space_area_id":"orbit_approach:planet" if index == 0 else "orbit_approach:moon", "position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical"}, 1).ok)
		assert(state.admit_actor({"craft_id":id, "faction_id":"player", "control_domain":"player", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(wings.ensure_flying_wings("singleplayer", ids, ids, {ids[0]:"pilot_a", ids[1]:"pilot_b"}).ok)
	var before: Dictionary = fleet.get_flight_state(ids[0]).get_snapshot()
	var result: Dictionary = sim.get_space_area_snapshot("orbit_approach:planet", "singleplayer")
	assert(result.ok and result.actors.size() == 1 and result.actors[0].craft_id == ids[0])
	assert(result.actors[0].footprint_cells.size() == 1 and result.actors[0].wing_id == "solo:" + ids[0])
	result.actors[0].footprint_cells.clear()
	assert(sim.get_space_area_snapshot("orbit_approach:planet", "singleplayer").actors[0].footprint_cells.size() == 1)
	assert(not sim.get_space_area_snapshot("orbit_approach:planet", "foreign").ok)
	assert(fleet.get_flight_state(ids[0]).get_snapshot() == before)
	assert(state.remove_actor(ids[0]))
	assert(sim.get_space_area_snapshot("orbit_approach:planet", "singleplayer").actors.is_empty())
	sim.free()
	print("SPACE_AREA_SNAPSHOT passed")
	quit(0)
