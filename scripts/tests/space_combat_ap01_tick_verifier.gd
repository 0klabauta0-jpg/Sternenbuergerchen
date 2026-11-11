extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")

func _initialize() -> void:
	var failed := 0
	var fleet = FLEET.new()
	fleet.configure()
	fleet.register_craft("a")
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"a"}, "request_id":"l"}, {"runtime_authorized":true})
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"a", "target_orbit_id":"planet_orbit"}, "request_id":"j"})
	var root = ROOT.new()
	root.configure_singleplayer_owners(null, null, null, fleet)
	var adapter = ADAPTER.new()
	adapter.set("_travel", fleet)
	adapter.set("_simulation", root)
	root.configure_space_runtime_tick(Callable(adapter, "advance_space_travel"))
	for i in range(60): root._physics_process(1.0 / 60.0)
	var snap: Dictionary = fleet.get_snapshot("a")
	if not is_equal_approx(float(snap.elapsed_seconds), 1.0): failed += 1
	if root.tick_counter != 60: failed += 1
	if not is_equal_approx(float(snap.progress), 1.0 / 3.0): failed += 1
	var enemy := {"craft_id":"npc1", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(3, 3)}
	if root.admit_space_actor(enemy, {}).get("reason") != "runtime_authority_required": failed += 1
	if not root.admit_space_actor(enemy, {"runtime_authorized":true}).get("ok", false): failed += 1
	if fleet.get_flight_state("npc1") != null or root.get_space_actor("npc1") == null: failed += 1
	if root.admit_space_actor(enemy, {"runtime_authorized":true}).get("ok", false): failed += 1
	var player := {"craft_id":"a", "faction_id":"player", "control_domain":"player", "start_hex":GRID.cell_at(GRID.pair(snap.position))}
	if not root.admit_space_actor(player, {"runtime_authorized":true}).get("ok", false): failed += 1
	if root.get_space_actor("a") != fleet.get_flight_state("a"): failed += 1
	var invalid := {"craft_id":"npc2", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(9999,9999)}
	if root.admit_space_actor(invalid, {"runtime_authorized":true}).get("reason") != "invalid_actor_cell": failed += 1
	root.free()
	adapter.free()
	print("SPACE_COMBAT_AP01_TICK passed=", 10 - failed, " failed=", failed)
	quit(1 if failed else 0)
