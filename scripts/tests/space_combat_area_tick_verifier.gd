extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const FLIGHT = preload("res://scripts/core/space_flight_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var sim = ROOT.new()
	sim.configure_space_runtime_tick(Callable(self, "_tick"))
	var state: RefCounted = sim.get("_space_combat_state")
	var cell: Vector2i = GRID.from_offset(Vector2i(400,100))
	var local = FLIGHT.new()
	local.configure("space_fixture_local", {"position_plane":GRID.HEX.axial_to_plane(Vector2(cell)), "motion_mode":"tactical", "coordinate_frame":"local", "space_area_id":"orbit_approach:moon"})
	var failed := 0
	if not state.admit_actor({"craft_id":"space_fixture_local", "faction_id":"enemy", "control_domain":"enemy", "start_hex":cell, "footprint_hexes":[Vector2i.ZERO]}, local, true).get("ok", false): failed += 1
	var enemy := {"craft_id":"space_fixture_global", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(10,10), "footprint_hexes":[Vector2i.ZERO]}
	if not sim.admit_space_actor(enemy, {"runtime_authorized":true}).get("ok", false): failed += 1
	var global: RefCounted = sim.get_space_actor(enemy.craft_id)
	var local_start: Vector2 = local.get_snapshot().position_plane
	var global_start: Vector2 = global.get_snapshot().position_plane
	var hull := {"main_thrust":2.0, "reverse_thrust":2.0, "side_thrust":2.0, "turn_acceleration":1.0}
	for id in ["space_fixture_local", "space_fixture_global"]:
		if not sim.set_space_flight_control(id, {"forward":1.0, "assist_mode":"decoupled"}, hull, {}, {"runtime_authorized":true}).get("ok", false): failed += 1
	for i in range(30): sim._physics_process(1.0 / 60.0)
	if local.get_snapshot().position_plane.x <= local_start.x or global.get_snapshot().position_plane.x <= global_start.x: failed += 1
	if not sim.get_space_flight_status("space_fixture_local").get("ok", false): failed += 1
	sim.free()
	print("SPACE_COMBAT_AREA_TICK passed=", 6 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _tick(_delta: float) -> void:
	pass
