extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")

func _initialize() -> void:
	var sim = ROOT.new()
	sim.configure_space_runtime_tick(Callable(self, "_tick"))
	var auth := {"runtime_authorized":true}
	var id := "space_fixture_guided"
	var actor := {"craft_id":id, "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(10,10), "footprint_hexes":[Vector2i.ZERO]}
	var hull := {"main_thrust":2.0, "reverse_thrust":2.0, "side_thrust":2.0, "turn_acceleration":1.0}
	var failed := 0
	if not sim.admit_space_actor(actor, auth).get("ok", false): failed += 1
	var flight: RefCounted = sim.get_space_actor(id)
	var target: Vector2 = flight.get_snapshot().position_plane + Vector2(2, 0)
	var goal := {"target_plane":target, "arrival_radius":0.25}
	if sim.set_space_fixture_goal(id, goal, hull, {}, {}).get("reason") != "runtime_authority_required": failed += 1
	if sim.set_space_fixture_goal("real_ship", goal, hull, {}, auth).get("reason") != "fixture_only": failed += 1
	if not sim.set_space_fixture_goal(id, goal, hull, {}, auth).get("ok", false): failed += 1
	for i in range(900): sim._physics_process(1.0 / 60.0)
	var snapshot: Dictionary = flight.get_snapshot()
	if snapshot.position_plane.distance_to(target) > 0.25 or snapshot.velocity_plane.length() > 0.1: failed += 1
	if not sim.get_space_flight_status(id).get("ok", false): failed += 1
	sim.free()
	var blocked_sim = ROOT.new()
	blocked_sim.configure_space_runtime_tick(Callable(self, "_tick"))
	if not blocked_sim.admit_space_actor(actor, auth).get("ok", false): failed += 1
	var obstacle := {"craft_id":"blocker", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(12,10), "footprint_hexes":[Vector2i.ZERO]}
	if not blocked_sim.admit_space_actor(obstacle, auth).get("ok", false): failed += 1
	var blocked_flight: RefCounted = blocked_sim.get_space_actor(id)
	var obstacle_flight: RefCounted = blocked_sim.get_space_actor("blocker")
	var blocked_goal := {"target_plane":obstacle_flight.get_snapshot().position_plane, "arrival_radius":0.25}
	if not blocked_sim.set_space_fixture_goal(id, blocked_goal, hull, {}, auth).get("ok", false): failed += 1
	for i in range(400): blocked_sim._physics_process(1.0 / 60.0)
	var blocked_status: Dictionary = blocked_sim.get_space_flight_status(id)
	if blocked_status.get("ok", true) or blocked_status.get("reason") not in ["occupied", "blocked"]: failed += 1
	if blocked_flight.get_snapshot().position_plane == obstacle_flight.get_snapshot().position_plane: failed += 1
	blocked_sim.free()
	print("SPACE_COMBAT_AP06_ROOT_GUIDANCE passed=", 11 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _tick(_delta: float) -> void:
	pass
