extends SceneTree
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ADAPTER = preload("res://scripts/meta/singleplayer_runtime_adapter.gd")
const FLEET = preload("res://scripts/core/singleplayer_fleet_travel_state.gd")
const GRID = preload("res://scripts/core/strategic_hex_grid.gd")
const FLIGHT_RESOLVER = preload("res://scripts/tactical/space_flight_resolver.gd")

func _initialize() -> void:
	var failed := 0
	var fleet = FLEET.new()
	fleet.configure()
	fleet.register_craft("a")
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"a"}, "request_id":"l"}, {"runtime_authorized":true})
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"a", "target_orbit_id":"planet_orbit"}, "request_id":"j"})
	var root = ROOT.new()
	root.configure_singleplayer_owners(null, null, null, fleet)
	var wing_context := {"authorized":true, "actor_id":"player", "phase":"grounded", "owned_crafts":["a"], "craft_pilots":{"a":"pilot"}}
	var wing_create := {"contract_category":"space_combat", "operation":"wing_create", "request_id":"wc", "expected_revision":0, "payload":{"wing_id":"w"}}
	if not root.request_singleplayer_command(wing_create, wing_context).get("ok", false): failed += 1
	var wing_assign := {"contract_category":"space_combat", "operation":"wing_assign", "request_id":"wa", "expected_revision":1, "payload":{"wing_id":"w", "craft_id":"a"}}
	if not root.request_singleplayer_command(wing_assign, wing_context).get("ok", false): failed += 1
	if root.get_space_wing_snapshot().wings.w.craft_ids != ["a"]: failed += 1
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
	var npc_flight: RefCounted = root.get_space_actor("npc1")
	var npc_snapshot: Dictionary = npc_flight.get_snapshot()
	var new_cell := Vector2i(4, 3)
	var proposal := {"expected_revision":npc_snapshot.revision, "position_plane":GRID.HEX.axial_to_plane(Vector2(new_cell))}
	if root.commit_space_actor_motion("npc1", proposal, 1, {}).get("reason") != "runtime_authority_required": failed += 1
	if not root.commit_space_actor_motion("npc1", proposal, 1, {"runtime_authorized":true}).get("ok", false): failed += 1
	var check_cell: Array[Vector2i] = [new_cell]
	if root.get_space_actors_at(check_cell) != ["npc1"]: failed += 1
	if root.commit_space_actor_motion("npc1", proposal, 1, {"runtime_authorized":true}).get("reason") != "stale_tick": failed += 1
	var before_flight: Dictionary = npc_flight.get_snapshot()
	var hull := {"main_thrust":2.0, "reverse_thrust":2.0, "side_thrust":2.0, "turn_acceleration":1.0}
	var thrust_proposal: Dictionary = FLIGHT_RESOLVER.step(before_flight, {"forward":1.0, "assist_mode":"decoupled"}, hull, {}, 0.25)
	if not root.commit_space_actor_motion("npc1", thrust_proposal, 2, {"runtime_authorized":true}).get("ok", false): failed += 1
	if npc_flight.get_snapshot().position_plane == before_flight.position_plane: failed += 1
	var player := {"craft_id":"a", "faction_id":"player", "control_domain":"player", "start_hex":GRID.cell_at(GRID.pair(snap.position))}
	if root.admit_space_actor(player, {"runtime_authorized":true}).get("reason") != "travel_active": failed += 1
	for i in range(121): root._physics_process(1.0 / 60.0)
	snap = fleet.get_snapshot("a")
	player.start_hex = GRID.cell_at(GRID.pair(snap.position))
	if not root.admit_space_actor(player, {"runtime_authorized":true}).get("ok", false): failed += 1
	if root.get_space_actor("a") != fleet.get_flight_state("a"): failed += 1
	fleet.register_craft("b")
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"b"}, "request_id":"lb"}, {"runtime_authorized":true})
	var b_snapshot: Dictionary = fleet.get_snapshot("b")
	var b_player := {"craft_id":"b", "faction_id":"player", "control_domain":"player", "start_hex":GRID.cell_at(GRID.pair(b_snapshot.position))}
	if not root.admit_space_actor(b_player, {"runtime_authorized":true}).get("ok", false): failed += 1
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"b", "target_orbit_id":"planet_orbit"}, "request_id":"jb"})
	if root.enter_space_tactical("b", 1, {"runtime_authorized":true}).get("reason") != "travel_active": failed += 1
	root._physics_process(1.0)
	var b_moved: Vector2i = GRID.cell_at(GRID.pair(fleet.get_snapshot("b").position))
	var b_cells: Array[Vector2i] = [b_moved]
	if not root.get_space_actors_at(b_cells).has("b"): failed += 1
	var b_old_cells: Array[Vector2i] = [b_player.start_hex]
	if b_moved == b_player.start_hex or root.get_space_actors_at(b_old_cells).has("b"): failed += 1
	var player_flight: RefCounted = fleet.get_flight_state("a")
	var flight_snap: Dictionary = player_flight.get_snapshot()
	if root.enter_space_tactical("a", 1, {}).get("reason") != "runtime_authority_required": failed += 1
	if not root.enter_space_tactical("a", 1, {"runtime_authorized":true}).get("ok", false): failed += 1
	if player_flight.get_snapshot().velocity_plane != flight_snap.velocity_plane: failed += 1
	var reject_travel: Dictionary = fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"a", "target_orbit_id":"moon_orbit"}, "request_id":"new"})
	if reject_travel.get("reason") != "combat_active": failed += 1
	var spoof := {"craft_id":"a", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(4,4)}
	if root.admit_space_actor(spoof, {"runtime_authorized":true}).get("reason") != "craft_identity_conflict": failed += 1
	var invalid := {"craft_id":"npc2", "faction_id":"enemy", "control_domain":"enemy", "start_hex":Vector2i(9999,9999)}
	if root.admit_space_actor(invalid, {"runtime_authorized":true}).get("reason") != "invalid_actor_cell": failed += 1
	var at_30 := _simulate_frames(30)
	if not is_equal_approx(at_30, _simulate_frames(60)) or not is_equal_approx(at_30, _simulate_frames(144)): failed += 1
	root.free()
	adapter.free()
	print("SPACE_COMBAT_AP01_TICK passed=", 30 - failed, " failed=", failed)
	quit(1 if failed else 0)

func _simulate_frames(frame_count: int) -> float:
	var fleet = FLEET.new()
	fleet.configure()
	fleet.register_craft("a")
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"launch_to_orbit", "payload":{"craft_id":"a"}, "request_id":"l"}, {"runtime_authorized":true})
	fleet.apply_command({"contract_category":"singleplayer_space_travel", "operation":"start_quantum", "payload":{"craft_id":"a", "target_orbit_id":"planet_orbit"}, "request_id":"j"})
	var sim = ROOT.new()
	sim.configure_singleplayer_owners(null, null, null, fleet)
	var adapter = ADAPTER.new()
	adapter.set("_travel", fleet)
	adapter.set("_simulation", sim)
	sim.configure_space_runtime_tick(Callable(adapter, "advance_space_travel"))
	var done := 0
	for frame in frame_count:
		sim._process(1.0 / frame_count)
		var target := floori(float(frame + 1) * 60.0 / frame_count)
		while done < target:
			sim._physics_process(1.0 / 60.0)
			done += 1
	var progress := float(fleet.get_snapshot("a").progress)
	sim.free()
	adapter.free()
	return progress
