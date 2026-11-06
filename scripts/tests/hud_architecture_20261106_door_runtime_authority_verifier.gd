extends SceneTree

# Synthetic component contract only: no actors, native playthrough, or timing claim.
const DRIVER_SCRIPT := preload("res://scripts/tests/mission_combat_loop_driver.gd")
const SETUP_SCRIPT := preload("res://scripts/tests/mission_test_setup.gd")
const SIMULATION_SCRIPT := preload("res://scripts/core/simulation_root.gd")
const OBJECTIVE_SCRIPT := preload("res://scripts/core/objective_status.gd")
const REGISTRY_SCRIPT := preload("res://scripts/terrain/terrain_registry.gd")
const MAP_SCRIPT := preload("res://scripts/terrain/terrain_map_data.gd")
const TILE_SCRIPT := preload("res://scripts/terrain/terrain_tile_data.gd")
const PATHFINDER_SCRIPT := preload("res://scripts/terrain/terrain_pathfinder.gd")
const LOS_SCRIPT := preload("res://scripts/core/los_system.gd")
const REACTION_SCRIPT := preload("res://scripts/mission/mission_interaction_object_reaction.gd")
const DOOR_ID := "synthetic_door"
const DOOR_GRID := Vector2i(1, 0)

class RuntimeMapCarrier:
	extends Node
	var _loaded_terrain_map_data = null

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== HUD Door Runtime Authority: synthetic component contract ===")
	_test_progress_owns_effective_navigation_without_hud()
	_test_snapshot_reads_do_not_advance_runtime()
	_test_registry_lifecycle_and_remote_apply()
	_test_applied_receipt_visuals_and_stale_read_guards()
	_test_missing_marker_is_fail_closed()
	await _test_startup_grace_updates_owner_countdown()
	await _test_client_and_authority_transition_in_grace()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("HUD_DOOR_RUNTIME_AUTHORITY_VERIFY_PASS")
	quit(1 if _failed > 0 else 0)


func _test_progress_owns_effective_navigation_without_hud() -> void:
	var fixture := _build_fixture()
	var driver: Node = fixture.get_node("CombatLoopDriver")
	var registry: TerrainRegistry = fixture.get_node("TerrainRegistry")
	_assert(fixture.get_node_or_null("TacticalController") == null and fixture.get_node_or_null("Primary3DView") == null, "Fixture has no HUD/controller/Primary3DView")
	_assert(registry.has_runtime_tile_override(DOOR_GRID), "Runtime configure publishes the closed door index without a HUD refresh")
	_assert_door_access(registry, false, "Configured")
	var closed_tile = registry.get_tile_at_grid(DOOR_GRID)
	var static_before: Dictionary = closed_tile.to_dict().duplicate(true)
	for sample in [{"progress": 0.5, "open": false, "visual": "half"}, {"progress": 0.84, "open": false, "visual": "half"}, {"progress": 0.85, "open": true, "visual": "open"}]:
		driver.call("update_mission_interaction_runtime_progress", _progress_payload(float(sample.progress)))
		_assert_door_access(registry, bool(sample.open), "%d percent runtime" % int(round(float(sample.progress) * 100.0)))
		var visual: Dictionary = REACTION_SCRIPT.build_snapshot({"entries": [{"interaction_id": DOOR_ID, "interaction_type": "door", "status": "in_progress", "progress": sample.progress, "world_position": registry.grid_to_world(DOOR_GRID)}]})
		_assert(String(Dictionary(Array(visual.get("entries", []))[0]).get("runtime_visual_state", "")) == String(sample.visual), "Visual and effective runtime retain the same opening boundary")
	var interrupted := _progress_payload(0.85)
	interrupted["state"] = "interrupted"
	driver.call("update_mission_interaction_runtime_progress", interrupted)
	_assert_door_access(registry, false, "Interrupted unfinished")
	driver.call("update_mission_interaction_runtime_progress", _progress_payload(1.0))
	_assert_door_access(registry, true, "Completed")
	_assert(closed_tile.to_dict() == static_before, "Runtime door index leaves every static tile field unchanged")
	_assert_no_commands_or_effects(fixture, "Progress projection")
	_assert_door_snapshot_receipt(driver, registry)
	fixture.free()


func _test_snapshot_reads_do_not_advance_runtime() -> void:
	var fixture := _build_fixture()
	var driver: Node = fixture.get_node("CombatLoopDriver")
	var registry: TerrainRegistry = fixture.get_node("TerrainRegistry")
	var simulation: Node = fixture.get_node("SimulationRoot")
	var objective = simulation.call("get_objective_status")
	var gates = driver.get("_mission_scenario_runtime_gates")
	var owner_before := _owner_read_signature(driver, objective, gates)
	var registry_revision := registry.get_revision()
	for _index in range(6):
		driver.call("get_playability_snapshot")
		driver.call("get_objective_countdown_snapshot")
		driver.call("get_mission_scenario_runtime_gate_snapshot")
		driver.call("get_mission_cargo_touchdown_snapshot")
		if driver.has_method("get_mission_interaction_door_runtime_collision_los_snapshot"):
			driver.call("get_mission_interaction_door_runtime_collision_los_snapshot")
	_assert(_owner_read_signature(driver, objective, gates) == owner_before, "Repeated HUD-facing getters do not change gate clocks/completion, interaction state, cargo or objective countdown")
	_assert(registry.get_revision() == registry_revision, "Repeated snapshot reads do not dirty terrain")
	_assert_no_commands_or_effects(fixture, "Repeated read")
	fixture.free()


func _test_registry_lifecycle_and_remote_apply() -> void:
	var fixture := _build_fixture()
	var driver: Node = fixture.get_node("CombatLoopDriver")
	var registry: TerrainRegistry = fixture.get_node("TerrainRegistry")
	driver.call("update_mission_interaction_runtime_progress", _progress_payload(1.0))
	var opened_revision := registry.get_revision()
	driver.call("_on_tick_processed", 1)
	driver.call("_on_tick_processed", 2)
	_assert(registry.get_revision() == opened_revision, "Stable runtime ticks do not cause self-revision loops")
	registry.clear_tiles()
	_register_door_line(registry)
	_assert(not registry.is_walkable(DOOR_GRID), "Rebuilt registry genuinely lost the old runtime override")
	driver.call("_on_tick_processed", 3)
	_assert_door_access(registry, true, "Same-fingerprint registry rebuild")
	var rebuilt_revision := registry.get_revision()
	driver.call("_on_tick_processed", 4)
	_assert(registry.get_revision() == rebuilt_revision, "Reapply stores its resulting revision and then remains stable")
	fixture.remove_child(registry)
	registry.free()
	registry = REGISTRY_SCRIPT.new()
	registry.name = "TerrainRegistry"
	_register_door_line(registry)
	fixture.add_child(registry)
	driver.call("_on_tick_processed", 5)
	_assert_door_access(registry, true, "Replacement registry identity")
	var remote_state: Dictionary = Dictionary(driver.call("get_mission_interaction_runtime_states"))
	driver.call("apply_multiplayer_interaction_snapshot", {"interaction_states": {}})
	_assert_door_access(registry, false, "Empty remote state")
	driver.call("apply_multiplayer_interaction_snapshot", {"interaction_states": remote_state})
	_assert_door_access(registry, true, "Completed remote state")
	var remote_revision := registry.get_revision()
	driver.call("apply_multiplayer_interaction_snapshot", {"interaction_states": remote_state})
	_assert(registry.get_revision() == remote_revision, "Duplicate remote state does not dirty terrain")
	_assert_no_commands_or_effects(fixture, "Remote index projection")
	fixture.free()


func _test_missing_marker_is_fail_closed() -> void:
	var fixture := _build_fixture(false)
	var driver: Node = fixture.get_node("CombatLoopDriver")
	var registry: TerrainRegistry = fixture.get_node("TerrainRegistry")
	driver.call("update_mission_interaction_runtime_progress", _progress_payload(1.0))
	_assert(not registry.has_runtime_tile_override(Vector2i.ZERO), "Missing runtime marker never creates a fabricated origin override")
	_assert(not registry.has_runtime_tile_override(DOOR_GRID), "Missing runtime marker is not guessed from unrelated terrain")
	fixture.free()


func _test_applied_receipt_visuals_and_stale_read_guards() -> void:
	var fixture := _build_fixture()
	var driver: Node = fixture.get_node("CombatLoopDriver")
	var registry: TerrainRegistry = fixture.get_node("TerrainRegistry")
	if not driver.has_method("get_mission_interaction_door_runtime_collision_los_snapshot"):
		_assert(false, "Runtime receipt is available for the pure visual consumer")
		fixture.free()
		return
	driver.call("update_mission_interaction_runtime_progress", _progress_payload(0.85))
	var receipt: Dictionary = Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot"))
	var visual_source := {"entries": [{"interaction_id": DOOR_ID, "interaction_type": "door", "status": "out_of_range", "progress": 0.85, "world_position": registry.grid_to_world(DOOR_GRID)}]}
	var reaction: Dictionary = REACTION_SCRIPT.build_snapshot(visual_source, receipt)
	var reaction_entry: Dictionary = Dictionary(Array(reaction.get("entries", []))[0])
	_assert(String(reaction_entry.get("runtime_visual_state", "")) == "open" and String(reaction_entry.get("visual_asset_type_id", "")) == "station_set_door_single", "Applied runtime receipt owns the visible door asset despite local out-of-range feedback")
	_assert(float(reaction_entry.get("door_leaf_gap_fraction", 0.0)) == 1.0 and String(reaction_entry.get("visual_state_label", "")) == "DOOR OPEN", "Applied runtime receipt owns door gap and label")
	var receipt_revision := registry.get_revision()
	Array(receipt.get("entries", []))[0]["runtime_visual_state"] = "closed"
	Array(receipt.get("overrides", []))[0]["walkable_override"] = false
	var unchanged: Dictionary = Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot"))
	_assert(String(Dictionary(Array(unchanged.get("entries", []))[0]).get("runtime_visual_state", "")) == "open" and bool(Dictionary(Array(unchanged.get("overrides", []))[0]).get("walkable_override", false)), "Nested receipt mutation cannot poison runtime entries or overrides")
	_assert(registry.get_revision() == receipt_revision and registry.is_walkable(DOOR_GRID), "Mutating visual receipt copies cannot change the applied terrain index")
	registry.clear_runtime_tile_overrides()
	var cleared_revision := registry.get_revision()
	var stale: Dictionary = Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot"))
	_assert(not bool(stale.get("producer_index_current", true)) and registry.get_revision() == cleared_revision, "A pure receipt read marks an externally cleared registry stale without repairing it")
	var stale_visual: Dictionary = REACTION_SCRIPT.build_snapshot(visual_source, stale)
	_assert(String(Dictionary(Array(stale_visual.get("entries", []))[0]).get("runtime_visual_state", "")) == "closed", "Visual consumer does not admit a stale applied receipt")
	driver.call("_on_tick_processed", 6)
	_assert(registry.is_walkable(DOOR_GRID) and bool(Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot")).get("producer_index_current", false)), "Runtime tick repairs the cleared index and publishes a current receipt")
	var terrain_map = fixture.get_node("MissionSetup").get("_loaded_terrain_map_data")
	terrain_map.set_marker_position("door_marker", registry.grid_to_world(Vector2i(2, 0)))
	var before_map_read := registry.get_revision()
	_assert(not bool(Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot")).get("producer_index_current", true)) and registry.get_revision() == before_map_read, "In-place marker changes invalidate only the returned receipt until a runtime update")
	driver.call("_on_tick_processed", 7)
	var moved: Dictionary = Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot"))
	_assert(bool(moved.get("producer_index_current", false)) and registry.has_runtime_tile_override(Vector2i(2, 0)) and not registry.has_runtime_tile_override(DOOR_GRID), "Runtime tick follows the real changed marker and removes the old derived index entry")
	_assert_no_commands_or_effects(fixture, "Receipt/visual projection")
	fixture.free()


func _test_startup_grace_updates_owner_countdown() -> void:
	var fixture := _build_fixture()
	var driver: Node = fixture.get_node("CombatLoopDriver")
	driver.call("set_combat_startup_grace_ticks", 1000)
	var before: Dictionary = Dictionary(driver.call("get_objective_countdown_snapshot"))
	var hold_before: float = _synthetic_hold_elapsed(driver)
	var started_msec := Time.get_ticks_msec()
	# Real normal-time passage; no actor, timer-origin or clock mutation.
	await _wait_real_wall_msec(50)
	driver.call("_on_tick_processed", 1)
	var elapsed_seconds := float(Time.get_ticks_msec() - started_msec) / 1000.0
	var after: Dictionary = Dictionary(driver.call("get_objective_countdown_snapshot"))
	var countdown_delta := float(before.get("countdown_seconds", -1.0)) - float(after.get("countdown_seconds", -1.0))
	print("GRACE_TIMING_DIAG %s" % JSON.stringify({"wall_elapsed_seconds": elapsed_seconds, "hold_before": hold_before, "hold_after": _synthetic_hold_elapsed(driver), "countdown_before": before.get("countdown_seconds", -1.0), "countdown_after": after.get("countdown_seconds", -1.0), "time_scale": Engine.time_scale}))
	_assert(Engine.time_scale == 1.0, "Grace timing check keeps normal 1x engine time")
	_assert(elapsed_seconds >= 0.05, "Grace timing fixture observes at least 50 milliseconds of actual wall time")
	_assert(_synthetic_hold_elapsed(driver) > hold_before + 0.025, "Authoritative grace tick advances the existing scenario hold without a HUD read side effect")
	_assert(countdown_delta > 0.025 and absf(countdown_delta - elapsed_seconds) < 0.03, "Authoritative grace tick publishes countdown progress at the existing wall-clock rate")
	_assert(not bool(driver.call("is_combat_finished")) and int(driver.get("_current_tick")) < int(driver.get("_combat_startup_grace_ticks")), "Grace tick preserves staging instead of running zero-roster combat resolution")
	_assert_no_commands_or_effects(fixture, "Startup grace")
	fixture.free()


func _test_client_and_authority_transition_in_grace() -> void:
	var pair: Dictionary = await _create_local_authority_pair()
	_assert(bool(pair.get("connected", false)), "Local ENet connection supplies real client/server authority contexts")
	if not bool(pair.get("connected", false)):
		return
	var client_api: MultiplayerAPI = pair.client_api
	var host_api: MultiplayerAPI = pair.host_api
	var fixture := _build_fixture()
	fixture.name = "GraceAuthorityFixture"
	# Only the map-carrier boundary is substituted to avoid starting an entire
	# MissionSetup scene. Driver, SimulationRoot, map, gates and ENet are real.
	var original_setup: Node = fixture.get_node("MissionSetup")
	var map_data = original_setup.get("_loaded_terrain_map_data")
	fixture.remove_child(original_setup)
	original_setup.free()
	var carrier := RuntimeMapCarrier.new()
	carrier.name = "MissionSetup"
	carrier._loaded_terrain_map_data = map_data
	fixture.add_child(carrier)
	var driver: Node = fixture.get_node("CombatLoopDriver")
	var simulation: Node = fixture.get_node("SimulationRoot")
	simulation.set("is_server_authoritative", true)
	# The harness dispatches exact runtime callbacks; it must not also receive
	# unrelated automatic physics callbacks while waiting for real wall time.
	simulation.set_physics_process(false)
	driver.call("set_preview_mode", true)
	driver.call("set_combat_startup_grace_ticks", 1000)
	var network_scope := Node.new()
	network_scope.name = "DoorGraceAuthorityScope"
	root.add_child(network_scope)
	set_multiplayer(client_api, network_scope.get_path())
	network_scope.add_child(fixture)
	var client_before: Dictionary = _owner_read_signature(driver, simulation.call("get_objective_status"), driver.get("_mission_scenario_runtime_gates"))
	await _wait_real_wall_msec(50)
	driver.call("_on_tick_processed", 1)
	_assert(not bool(driver.get("_runs_local_authority")) and not client_api.is_server(), "Real client authority branch declines local execution")
	_assert(_owner_read_signature(driver, simulation.call("get_objective_status"), driver.get("_mission_scenario_runtime_gates")) == client_before, "Client runtime callback does not advance local hold/completion/countdown")
	set_multiplayer(host_api, network_scope.get_path())
	var before_transition: Dictionary = Dictionary(driver.call("get_objective_countdown_snapshot"))
	await _wait_real_wall_msec(50)
	driver.call("_on_tick_processed", 2)
	var after_transition: Dictionary = Dictionary(driver.call("get_objective_countdown_snapshot"))
	_assert(bool(driver.get("_runs_local_authority")) and host_api.is_server(), "The next real runtime callback adopts host authority")
	_assert(float(after_transition.get("countdown_seconds", -1.0)) < float(before_transition.get("countdown_seconds", -1.0)) - 0.025, "Authority transition refreshes the preserved countdown during startup grace")
	_assert(not bool(driver.call("is_combat_finished")), "Authority transition retains startup grace without starting combat resolution")
	_assert_no_commands_or_effects(fixture, "Client/host grace transition")
	network_scope.queue_free()
	var client_peer: ENetMultiplayerPeer = pair.client_peer
	var host_peer: ENetMultiplayerPeer = pair.host_peer
	client_peer.close()
	host_peer.close()
	await process_frame


func _synthetic_hold_elapsed(driver: Node) -> float:
	var snapshot: Dictionary = Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot"))
	for gate_variant in Array(snapshot.get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")) == "synthetic_hold":
			return float(gate.get("hold_elapsed_seconds", 0.0))
	return -1.0


func _wait_real_wall_msec(duration_msec: int) -> void:
	var deadline_msec := Time.get_ticks_msec() + duration_msec
	while Time.get_ticks_msec() < deadline_msec:
		# A newly created SceneTreeTimer can consume the current frame's delta,
		# including synchronous work done before its creation. Verify real time.
		await create_timer(0.01).timeout


func _create_local_authority_pair() -> Dictionary:
	for port in range(19519, 19530):
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 2) != OK:
			host_peer.close()
			continue
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
			client_peer.close()
			host_peer.close()
			continue
		var host_api := MultiplayerAPI.create_default_interface()
		var client_api := MultiplayerAPI.create_default_interface()
		host_api.multiplayer_peer = host_peer
		client_api.multiplayer_peer = client_peer
		for _index in range(180):
			host_api.poll()
			client_api.poll()
			if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {"connected": true, "host_api": host_api, "client_api": client_api, "host_peer": host_peer, "client_peer": client_peer}
			await process_frame
		client_peer.close()
		host_peer.close()
	return {"connected": false}


func _build_fixture(with_marker: bool = true) -> Node:
	# Real runtime components, deliberately not attached to a running mission.
	var fixture := Node.new()
	fixture.name = "SyntheticDoorAuthorityFixture"
	var registry: TerrainRegistry = REGISTRY_SCRIPT.new()
	registry.name = "TerrainRegistry"
	_register_door_line(registry)
	fixture.add_child(registry)
	var terrain_map = MAP_SCRIPT.new()
	if with_marker:
		terrain_map.set_marker_position("door_marker", registry.grid_to_world(DOOR_GRID))
	var setup: Node = SETUP_SCRIPT.new()
	setup.name = "MissionSetup"
	setup.set("_loaded_terrain_map_data", terrain_map)
	fixture.add_child(setup)
	var simulation: Node = SIMULATION_SCRIPT.new()
	simulation.name = "SimulationRoot"
	simulation.set("terrain_registry_path", NodePath("../TerrainRegistry"))
	var objective = OBJECTIVE_SCRIPT.new()
	objective.objective_id = "synthetic_hold"
	objective.owning_team_id = "team_alpha"
	objective.capture_progress = 1.0
	simulation.call("set_objective_status", objective)
	fixture.add_child(simulation)
	var driver: Node = DRIVER_SCRIPT.new()
	driver.name = "CombatLoopDriver"
	driver.set("simulation_root_path", NodePath("../SimulationRoot"))
	driver.set("terrain_registry_path", NodePath("../TerrainRegistry"))
	driver.call("set_combat_startup_grace_ticks", 1000)
	fixture.add_child(driver)
	driver.call("configure_scenario_runtime_gates", {"flow_steps": [{"step_id": "synthetic_hold", "objective_type": "computer_hold", "operator_team_id": "team_alpha", "min_hold_seconds": 10.0}], "interaction_points": [{"interaction_id": DOOR_ID, "interaction_type": "door", "marker_id": "door_marker", "step_id": "open_door", "required_order": "breach", "duration_seconds": 2.0, "radius_world": 72.0}]})
	return fixture


func _register_door_line(registry: TerrainRegistry) -> void:
	registry.configure_iso_grid(Vector2.ZERO, 64.0, 32.0)
	for x in range(3):
		var grid := Vector2i(x, 0)
		registry.register_tile(TILE_SCRIPT.new({"tile_id": "door_line_%d" % x, "type_id": "station_floor", "grid_position": grid, "world_position": registry.grid_to_world(grid), "walkable": x != 1, "blocks_los": x == 1, "object_height": 1 if x == 1 else 0, "cover_value": 20 if x == 1 else 0, "height_level": 0, "surface_type": "ground", "edge_type": "none"}))


func _progress_payload(progress: float) -> Dictionary:
	return {"interaction_id": DOOR_ID, "state": "operating", "complete": progress >= 1.0, "hold_seconds": progress * 2.0, "duration_seconds": 2.0, "fireteam_id": "synthetic_ft", "team_id": "team_alpha", "step_id": "open_door", "required_state": "door_open", "interaction_type": "door", "command_type": "breach"}


func _assert_door_access(registry: TerrainRegistry, expected_open: bool, label: String) -> void:
	_assert(registry.is_walkable(DOOR_GRID) == expected_open and registry.blocks_los_at_grid(DOOR_GRID) != expected_open, "%s effective movement and LOS agree" % label)
	_assert(registry.get_object_height_at_grid(DOOR_GRID) == (0 if expected_open else 1) and registry.get_cover_at(DOOR_GRID) == (0 if expected_open else 20), "%s effective height and cover agree" % label)
	var pathfinder = PATHFINDER_SCRIPT.new()
	var los = LOS_SCRIPT.new()
	_assert(not pathfinder.find_path(Vector2i.ZERO, Vector2i(2, 0), registry).is_empty() == expected_open, "%s actual pathfinder follows runtime index" % label)
	_assert(bool(los.has_line_of_sight_with_terrain(registry.grid_to_world(Vector2i.ZERO), registry.grid_to_world(Vector2i(2, 0)), registry, 9999.0)) == expected_open, "%s actual LOS follows runtime index" % label)


func _owner_read_signature(driver: Node, objective, gates) -> Dictionary:
	return {"runtime": Dictionary(driver.call("get_mission_interaction_runtime_states")).duplicate(true), "gate_snapshot": Dictionary(gates.call("get_snapshot")).duplicate(true), "gate_holds": Dictionary(gates.get("_hold_started_msec_by_step_id")).duplicate(true), "gate_completions": Dictionary(gates.get("_completed_step_ids")).duplicate(true), "cargo": Dictionary(driver.get("_mission_cargo_touchdown_snapshot")).duplicate(true), "objective": Dictionary(objective.call("to_dict")).duplicate(true)}


func _assert_no_commands_or_effects(fixture: Node, label: String) -> void:
	var simulation: Node = fixture.get_node("SimulationRoot")
	_assert(Array(simulation.get("command_queue")).is_empty() and Array(simulation.get("effects_queue")).is_empty(), "%s emits no commands or effects" % label)


func _assert_door_snapshot_receipt(driver: Node, registry: TerrainRegistry) -> void:
	if not driver.has_method("get_mission_interaction_door_runtime_collision_los_snapshot"):
		_assert(false, "Runtime owner exposes its read-only door receipt")
		return
	var snapshot: Dictionary = Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot"))
	_assert(String(snapshot.get("producer_source", "")) == "MissionCombatLoopDriver" and bool(snapshot.get("producer_reads_runtime_truth", false)), "Door receipt identifies the real runtime producer")
	_assert(String(snapshot.get("producer_applied_semantics", "")) == "last_runtime_producer_pass" and bool(snapshot.get("producer_index_current", false)), "Receipt distinguishes the last producer pass from current read admission")
	_assert(bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true)) and not bool(snapshot.get("terrain_map_data_mutated", true)), "Door receipt preserves read-only and static-data guarantees")
	_assert(int(snapshot.get("terrain_registry_revision", -1)) == registry.get_revision() and int(snapshot.get("override_count", 0)) == 1, "Door receipt records the applied terrain revision and override count")
	snapshot["entries"] = []
	_assert(Array(Dictionary(driver.call("get_mission_interaction_door_runtime_collision_los_snapshot")).get("entries", [])).size() == 1, "Receipt output cannot mutate the runtime index")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		print("FAIL: %s" % message)
