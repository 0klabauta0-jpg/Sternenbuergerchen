extends SceneTree
const AREA = preload("res://scripts/core/space_area_grid.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const STATE = preload("res://scripts/core/space_combat_state.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")

func _initialize() -> void:
	var pose := {"coordinate_frame":"local", "space_area_id":"orbit_approach:glut_2"}
	var blocked: Vector2i = GRID.from_offset(Vector2i(256,124))
	var gate: Vector2i = GRID.from_offset(Vector2i(256,133))
	assert(not AREA.contains(blocked, pose) and AREA.contains(gate, pose))
	assert(AREA.contains(blocked, {"coordinate_frame":"local", "space_area_id":"orbit_approach:moon"}))
	var targets: Array = AREA.dock_targets(pose.space_area_id)
	assert(targets.size() == 1 and targets[0].revision == "polisa_glut2_dock_v1")
	targets[0].revision = "tampered"
	assert(AREA.dock_targets(pose.space_area_id)[0].revision == "polisa_glut2_dock_v1")
	var flight = FLIGHT.new()
	assert(flight.configure("space_fixture_dock", {"coordinate_frame":"local", "space_area_id":pose.space_area_id, "motion_mode":"tactical", "position_plane":GRID.HEX.axial_to_plane(Vector2(gate))}).ok)
	var state = STATE.new()
	assert(state.admit_actor({"craft_id":"space_fixture_dock", "faction_id":"player", "control_domain":"player", "start_hex":gate, "footprint_hexes":[Vector2i.ZERO]}, flight, true).ok)
	assert(not state.record_navigation_claim("space_fixture_dock", pose.space_area_id, [blocked]).ok)
	assert(state.record_navigation_claim("space_fixture_dock", pose.space_area_id, [gate]).ok)
	print("Polisa static mask, isolation and claims checks passed")
	quit(0)
