extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var fleet = FLEET.new(); assert(fleet.configure().ok)
	var id := "space_fixture_polisa_gate"; fleet.register_craft(id)
	assert(_travel(fleet, "launch_to_orbit", {"craft_id":id}).ok)
	assert(_travel(fleet, "start_quantum", {"craft_id":id,"target_orbit_id":"polisa_orbit"}).ok)
	assert(_travel(fleet, "advance", {"delta_seconds":60.0}).ok)
	var flight: RefCounted = fleet.get_flight_state(id)
	var gate: Vector2i = GRID.from_offset(Vector2i(256,133))
	assert(flight.commit_area_transition({"expected_revision":flight.get_snapshot().revision,"coordinate_frame":"local","space_area_id":"orbit_approach:glut_2","position_plane":GRID.HEX.axial_to_plane(Vector2(gate)),"motion_mode":"tactical"},1).ok)
	var sim = ROOT.new(); sim.configure_singleplayer_owners(null,null,null,fleet)
	var state: RefCounted = sim.get("_space_combat_state")
	assert(state.admit_actor({"craft_id":id,"faction_id":"player","control_domain":"player","start_hex":gate,"footprint_hexes":[Vector2i.ZERO]},flight,true).ok)
	var wings: RefCounted = sim.get("_space_wing_state"); assert(wings.ensure_flying_wings("player",[id],[id],{id:"pilot"}).ok)
	var auth := {"runtime_authorized":true,"actor_id":"player"}
	var f: int = flight.get_snapshot().revision; var t: int = fleet.get_craft_snapshot(id).revision
	var a: int = state.get_area_revision("orbit_approach:glut_2"); var w: int = wings.get_snapshot().revision
	var before: Dictionary = flight.get_snapshot()
	assert(sim.preview_station_dock(id,"polisa_station_dock","polisa_glut2_dock_v1",f,t,a,w,auth).ok)
	assert(flight.get_snapshot() == before)
	assert(sim.preview_station_dock(id,"polisa_station_dock","old",f,t,a,w,auth).reason == "station_layout_changed")
	assert(sim.preview_station_dock(id,"polisa_station_dock","polisa_glut2_dock_v1",f,t,a-1,w,auth).reason == "stale_area_revision")
	var away: Vector2i = GRID.from_offset(Vector2i(256,140))
	assert(flight.commit_motion({"expected_revision":f,"position_plane":GRID.HEX.axial_to_plane(Vector2(away))},2).ok)
	state.sync_moved_actors(); f = flight.get_snapshot().revision; a = state.get_area_revision("orbit_approach:glut_2")
	assert(sim.preview_station_dock(id,"polisa_station_dock","polisa_glut2_dock_v1",f,t,a,w,auth).reason == "not_at_station_gate")
	sim.free(); print("Polisa station gate preview passed"); quit(0)

func _travel(fleet: RefCounted, operation: String, payload: Dictionary) -> Dictionary:
	return fleet.apply_command({"contract_category":"singleplayer_space_travel","operation":operation,"payload":payload}, {"runtime_authorized":true})
