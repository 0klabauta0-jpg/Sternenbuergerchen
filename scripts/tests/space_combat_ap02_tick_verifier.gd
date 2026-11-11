extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")

func _initialize() -> void:
	var sim = ROOT.new()
	sim.configure_space_runtime_tick(Callable(self, "_tick"))
	var actor := {"craft_id":"space_fixture_1", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(10,10), "footprint_hexes":[Vector2i.ZERO]}
	var auth := {"runtime_authorized":true}
	var intent := {"forward":1.0, "assist_mode":"decoupled"}
	var hull := {"main_thrust":2.0, "reverse_thrust":2.0, "side_thrust":2.0, "turn_acceleration":1.0}
	var failed := 0
	if not sim.admit_space_actor(actor, auth).get("ok", false): failed += 1
	if sim.set_space_flight_control(actor.craft_id, intent, hull, {}, {}).get("reason") != "runtime_authority_required": failed += 1
	if sim.set_space_flight_control("real_ship", intent, hull, {}, auth).get("reason") != "fixture_only": failed += 1
	var flight: RefCounted = sim.get_space_actor(actor.craft_id)
	var start: Dictionary = flight.get_snapshot()
	if not sim.set_space_flight_control(actor.craft_id, intent, hull, {}, auth).get("ok", false): failed += 1
	for i in range(60): sim._physics_process(1.0 / 60.0)
	var end: Dictionary = flight.get_snapshot()
	if not is_equal_approx(end.velocity_plane.x, 2.0): failed += 1
	if not is_equal_approx(end.position_plane.x - start.position_plane.x, 1.0): failed += 1
	if not sim.get_space_flight_status(actor.craft_id).get("ok", false): failed += 1
	if sim.tick_counter != 60: failed += 1
	sim.free()
	print("SPACE_COMBAT_AP02_TICK passed=", 8 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _tick(_delta: float) -> void:
	pass
