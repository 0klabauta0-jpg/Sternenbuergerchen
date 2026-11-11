extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
class ClientRoot extends "res://scripts/core/simulation_root.gd":
	func _should_skip_local_tick_processing() -> bool: return true
var calls := 0

func _initialize() -> void:
	var sim := ClientRoot.new()
	sim.configure_space_runtime_tick(Callable(self, "_tick"))
	var actor := {"craft_id":"space_fixture_client", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(10,10), "footprint_hexes":[Vector2i.ZERO]}
	var failed := 0
	if sim.admit_space_actor(actor, {"runtime_authorized":true}).get("reason") != "not_authority": failed += 1
	var fixture = FLIGHT.new()
	fixture.configure(actor.craft_id, {"position_plane":GRID.HEX.axial_to_plane(Vector2(actor.start_hex)), "motion_mode":"tactical"})
	if not sim.get("_space_combat_state").admit_actor(actor, fixture).get("ok", false): failed += 1
	var flight: RefCounted = sim.get_space_actor(actor.craft_id)
	var auth := {"runtime_authorized":true, "fixture":true}
	var before: Dictionary = flight.get_snapshot()
	if sim.prepare_space_area_transition(actor.craft_id, "orbit_approach:moon", {}, 0, 0, auth).get("reason") != "not_authority": failed += 1
	if sim.commit_space_area_transition("missing", auth).get("reason") != "not_authority" or sim.release_space_area_transition("missing", auth).get("reason") != "not_authority": failed += 1
	if sim.commit_fixture_surface_group({}, {}).get("reason") != "not_authority": failed += 1
	if sim.commit_singleplayer_departure(null, "ship", "request").get("reason") != "not_authority": failed += 1
	if sim.commit_singleplayer_local_return(null, "ship").get("reason") != "not_authority" or sim.preview_singleplayer_local_return_fuel(null, "ship").get("reason") != "not_authority": failed += 1
	if sim.commit_singleplayer_warp_departure(null, {}).get("reason") != "not_authority" or sim.advance_singleplayer_warp_entry(null, "ship", 1.0).get("reason") != "not_authority": failed += 1
	if sim.commit_singleplayer_space_launch(null, "ship", "request").get("reason") != "not_authority" or sim.commit_singleplayer_station_orbit(null, "ship", "request").get("reason") != "not_authority": failed += 1
	if sim.request_singleplayer_space_move({}).get("reason") != "not_authority" or sim.set_space_flight_control(actor.craft_id, {}, {}, {}, auth).get("reason") != "not_authority": failed += 1
	if sim.enter_space_tactical(actor.craft_id, 1, auth).get("reason") != "not_authority" or sim.commit_space_actor_motion(actor.craft_id, {}, 1, auth).get("reason") != "not_authority": failed += 1
	var proposals: Array[Dictionary] = []
	if sim.commit_space_fleet_motion(proposals, 1, {}, auth).get("reason") != "not_authority" or sim.request_singleplayer_command({"contract_category":"space_combat"}, {}).get("reason") != "not_authority": failed += 1
	if flight.get_snapshot() != before or not sim.get("_fixture_area_tokens").is_empty(): failed += 1
	var new_cell := Vector2i(11,10)
	flight.commit_motion({"expected_revision":flight.get_snapshot().revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(new_cell))}, 1)
	sim._physics_process(1.0 / 60.0)
	if calls != 0 or sim.tick_counter != 0: failed += 1
	var old_cells: Array[Vector2i] = [Vector2i(10,10)]
	var new_cells: Array[Vector2i] = [new_cell]
	if sim.get_space_actors_at(old_cells) != [actor.craft_id] or not sim.get_space_actors_at(new_cells).is_empty(): failed += 1
	sim.free()
	var host = ROOT.new()
	host.configure_space_runtime_tick(Callable(self, "_tick"))
	host._physics_process(1.0 / 60.0)
	if calls != 1 or host.tick_counter != 1: failed += 1
	host.free()
	print("SPACE_COMBAT_AUTHORITY_TICK failures=", failed)
	quit(1 if failed else 0)

func _tick(_delta: float) -> void:
	calls += 1
