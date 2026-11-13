extends SceneTree
## Product Session -> WorldRuntime -> actual mission scenes on two shipped maps.
const SESSION = preload("res://scripts/multiplayer/multiplayer_session.gd")
const WORLD = preload("res://scripts/multiplayer/multiplayer_world_runtime.gd")
const TERRAIN_FOG = preload("res://scripts/multiplayer/multiplayer_terrain_fog_projection.gd")
const MANIFEST = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const PRIMARY := "res://maps/fireteam_command_drill_24x24.json"
const SECONDARY := "res://maps/frontier_workyard_24x20.json"
var passed := 0
var failed := 0
var peers: Array = []
var results: Array = []
var accepted: Array = []
var initial_client_fog: Array = []

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func check(condition: bool, label: String) -> void:
	if condition: passed += 1
	else: failed += 1
	print("PASS " if condition else "FAIL ", label)

func fixture(label: String, team: String) -> Dictionary:
	var scope := Node.new()
	scope.name = label
	root.add_child(scope)
	var api := SceneMultiplayer.new()
	set_multiplayer(api, scope.get_path())
	var session = SESSION.new()
	session.name = "Session"
	scope.add_child(session)
	session.set_lobby_player_setup({"player_name":label, "team_slot":team, "team_play_mode":"coop_versus", "map_path":PRIMARY, "max_players":8})
	var host := Node.new()
	host.name = "MissionHost"
	scope.add_child(host)
	var world = WORLD.new()
	world.name = "MultiplayerWorldRuntime"
	scope.add_child(world)
	world.configure(session, host)
	world.local_location_changed.connect(func(_id: String, mission: Node):
		if not is_instance_valid(mission) or api.multiplayer_peer == null: return
		if api.is_server(): return
		var setup: Node = mission.get_node("MissionSetup")
		if setup.get("_fog_replica_terrain").is_empty():
			initial_client_fog.append({"state":setup.call("get_fog_of_war_runtime_snapshot"),"has_local_owner":setup.get("_fog_of_war_system") != null}))
	session.mission_start_requested.connect(func(assignments: Dictionary):
		check(world.start_world(assignments, PRIMARY), label + " starts verified world through actual Session signal"))
	session.mission_assignments_changed.connect(world.update_assignments)
	session.mission_rejoin_peer_block_changed.connect(world.on_peer_block_changed)
	session.session_disconnected.connect(func(_reason: String): world.clear_world())
	world.world_completed.connect(session.complete_mission)
	var value: Dictionary = {"scope":scope, "api":api, "session":session, "world":world}
	peers.append(value)
	return value

func until(predicate: Callable, seconds: float = 12.0) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return true
		await create_timer(0.02).timeout
	return bool(predicate.call())

func instance(peer: Dictionary, id: String) -> Node:
	return peer.world.get_location_instance(id)

func stop_clock(mission: Node) -> void:
	# Observe/advance production owners explicitly after their real map setup.
	mission.get_node("SimulationRoot").set_physics_process(false)
	mission.get_node("CombatLoopDriver").set_physics_process(false)

func local_view_state(mission: Node) -> Dictionary:
	var controller: Node = mission.get_node("TacticalController")
	var view: Node = mission.get_node("Primary3DView")
	return {"selection":controller.call("get_selected_fireteam_ids"), "focus":view.call("get_camera_focus_grid_position"), "yaw":view.call("get_camera_yaw_degrees"), "size":view.call("get_camera_size")}

func choose_local_view(mission: Node, fireteam_id: String, world_position: Vector2) -> Dictionary:
	var controller: Node = mission.get_node("TacticalController")
	if fireteam_id.is_empty(): controller.call("_clear_selection")
	else: controller.call("_on_fireteam_group_pressed", fireteam_id)
	mission.get_node("Primary3DView").call("focus_world_position", world_position)
	return local_view_state(mission)

func has_lifecycle_counts(peer: Dictionary, expected: int) -> bool:
	var registry: RefCounted = peer.world.get("_registry")
	return Dictionary(peer.world.get("_presentations")).size() == expected and Dictionary(registry.get("_instances")).size() == expected

func check_permission_selection(host: Dictionary, first: String, second: String) -> void:
	# Exercise the real coordinator/Root assignment boundary with an explicit
	# permission delta; Session itself intentionally disallows mid-mission setup edits.
	var assignments: Dictionary = host.session.build_session_assignments()
	var allowed := PackedStringArray(assignments.peer_fireteams[1])
	var controller: Node = instance(host, first).get_node("TacticalController")
	controller.call("_set_selected_fireteams", allowed, false)
	var selected: PackedStringArray = controller.call("get_selected_fireteam_ids")
	check(not selected.is_empty(), "permission regression starts with actual selectable own fireteams")
	if selected.is_empty(): return
	var retained := PackedStringArray([selected[0]])
	var before: Dictionary = local_view_state(instance(host, first))
	var background: Dictionary = choose_local_view(instance(host, second), "", Vector2(960, 720))
	var reduced: Dictionary = assignments.duplicate(true)
	reduced.peer_fireteams[1] = retained
	host.world.update_assignments(reduced)
	check(instance(host, first).get_node("SimulationRoot").get_peer_fireteams(1) == retained and controller.call("get_selected_fireteam_ids") == retained, "actual Root permission reduction retains only already selected permitted fireteams")
	var expected: Dictionary = before.duplicate(true)
	expected.selection = retained
	check(local_view_state(instance(host, first)) == expected and local_view_state(instance(host, second)) == background, "permission reduction preserves camera and empty background selection")
	host.world.update_assignments(assignments)
	check(local_view_state(instance(host, first)) == expected and local_view_state(instance(host, second)) == background, "restored permissions do not auto-select newly allowed fireteams or refocus either map")
	var revoked: Dictionary = assignments.duplicate(true)
	revoked.peer_fireteams[1] = PackedStringArray()
	host.world.update_assignments(revoked)
	expected.selection = PackedStringArray()
	check(instance(host, first).get_node("SimulationRoot").get_peer_fireteams(1).is_empty() and local_view_state(instance(host, first)) == expected, "revoking all own fireteam rights clears selection without changing camera")
	host.world.update_assignments(assignments)
	check(local_view_state(instance(host, first)) == expected, "restoring rights after full revocation preserves explicit empty selection")

func check_repeated_retirement(host: Dictionary, alpha: Dictionary, bravo: Dictionary, remaining: String) -> void:
	var remaining_instance: Node = instance(host, remaining)
	var remaining_id: int = remaining_instance.get_instance_id()
	var remaining_view: Dictionary = local_view_state(remaining_instance)
	for cycle in range(2):
		var opened: Dictionary = host.world.open_location(PRIMARY)
		check(opened.get("ok", false) and not opened.get("existing", true), "retirement cycle %d opens another actual mission" % cycle)
		if not opened.get("ok", false): return
		var id: String = opened.location_id
		var ready: bool = await until(func(): return instance(alpha, id) != null and instance(bravo, id) != null and host.world.is_peer_ready(id, alpha.api.get_unique_id()) and host.world.is_peer_ready(id, bravo.api.get_unique_id()))
		check(ready, "retirement cycle %d creates actual replicas with location READY" % cycle)
		if not ready: return
		for peer: Dictionary in peers: stop_clock(instance(peer, id))
		var retired_id: int = instance(host, id).get_instance_id()
		var retired_reference: WeakRef = weakref(instance(host, id))
		var registry: RefCounted = host.world.get("_registry")
		check(not registry.call("unregister_location", remaining, retired_id) and instance(host, remaining) == remaining_instance, "retirement identity guard cannot unregister another active mission")
		check(host.world.finish_location(id), "retirement cycle %d finishes only the temporary location" % cycle)
		check(await until(func(): return has_lifecycle_counts(host, 1) and has_lifecycle_counts(alpha, 1) and has_lifecycle_counts(bravo, 0) and retired_reference.get_ref() == null), "retirement cycle %d releases real scene, registry and presentation after drain" % cycle)
		check(instance(host, remaining).get_instance_id() == remaining_id and local_view_state(remaining_instance) == remaining_view and host.world.get_selected_location_id() == remaining and host.session.get_session_snapshot().mission_started, "retirement cycle %d preserves remaining owner, local view and active Session" % cycle)

func _run() -> void:
	var host := fixture("Host", "team_alpha")
	var alpha := fixture("Alpha", "team_alpha")
	var bravo := fixture("Bravo", "team_bravo")
	check(host.session.start_host(0), "real localhost host starts with spare capacity")
	var port: int = host.api.multiplayer_peer.host.get_local_port()
	check(alpha.session.join_session("127.0.0.1", port) and bravo.session.join_session("127.0.0.1", port), "two real clients connect only to localhost")
	var joined: bool = await until(func(): return host.session.get_session_snapshot().connected_count == 3 and alpha.session.get_session_snapshot().connection_state == "joined" and bravo.session.get_session_snapshot().connection_state == "joined")
	check(joined, "all actual Sessions finish ENet handshake")
	if not joined:
		await finish()
		return
	host.session.set_host_map_manifest(MANIFEST.build_manifest_for_map(PRIMARY))
	await until(func(): return alpha.session.get_session_snapshot().map_transfer.get("can_start_client", false) and bravo.session.get_session_snapshot().map_transfer.get("can_start_client", false))
	for peer: Dictionary in peers: peer.session.set_local_ready(true)
	check(await until(func(): return host.session.can_start_mission()), "three ready peers start without filling eight places")
	check(host.session.request_start_mission(), "real Session starts primary mission")
	var context: Dictionary = host.session.get_multiplayer_runtime_context()
	var first: String = String(context.get("runtime_token", ""))
	check(await until(func(): return instance(alpha, first) != null and instance(bravo, first) != null), "primary actual mission exists on both clients")
	if instance(alpha, first) == null or instance(bravo, first) == null:
		await finish()
		return
	for peer: Dictionary in peers: stop_clock(instance(peer, first))
	var alpha_id: int = alpha.api.get_unique_id()
	var bravo_id: int = bravo.api.get_unique_id()
	check(await until(func(): return host.world.is_peer_ready(first, alpha_id) and host.world.is_peer_ready(first, bravo_id)), "each primary Root receives location-specific READY")
	var assignments: Dictionary = host.session.build_session_assignments()
	check(assignments.peer_fireteams[1] == assignments.peer_fireteams[alpha_id] and assignments.peer_teams[alpha_id] != assignments.peer_teams[bravo_id], "same-team peers share all fireteams while opposing side remains distinct")
	var opened: Dictionary = host.world.open_location(SECONDARY, PackedStringArray(["team_alpha"]))
	check(opened.get("ok", false), "host opens second actual product map for its team")
	if not opened.get("ok", false):
		await finish()
		return
	var second: String = opened.location_id
	check(await until(func(): return instance(alpha, second) != null and host.world.is_peer_ready(second, alpha_id)), "second location manifest and token pass real READY handshake")
	if instance(alpha, second) == null:
		await finish()
		return
	stop_clock(instance(host, second))
	stop_clock(instance(alpha, second))
	check(instance(bravo, second) == null and bravo.world.get_location_rows().size() == 1, "enemy client never receives restricted location catalog or scene")
	var root_a: Node = instance(host, first).get_node("SimulationRoot")
	var root_b: Node = instance(host, second).get_node("SimulationRoot")
	var client_a: Node = instance(alpha, first).get_node("SimulationRoot")
	var client_b: Node = instance(alpha, second).get_node("SimulationRoot")
	var context_b: Dictionary = root_b.get_multiplayer_runtime_context()
	check(context == root_a.get_multiplayer_runtime_context() and context != context_b and context_b.map_hash == MANIFEST.build_manifest_for_map(SECONDARY).map_hash, "Roots retain independent immutable verified map identities")
	check(host.session.get_multiplayer_runtime_context() == context, "opening another map does not rebind primary Session identity")
	check(host.world.open_location(SECONDARY).get("existing", false) and host.world.get_location_rows().size() == 2, "opening same map again does not duplicate its units")
	# Capacity branch only: existing real maps stay selectable even with a full
	# metadata index. Extra records are never instantiated or called gameplay.
	var index: Dictionary = host.world.get("_entries")
	var fake_keys := PackedStringArray()
	for number in range(WORLD.MAX_LOCATIONS):
		var key: String = "capacity_probe_" + str(number)
		var record: Dictionary = index[first].duplicate(true)
		record.id = key
		record.manifest.map_hash = str(number).sha256_text()
		index[key] = record
		fake_keys.append(key)
	check(host.world.open_location(SECONDARY).get("existing", false), "full active index still deduplicates an already open real map before capacity guard")
	check(host.world.open_location("res://maps/test_mission.json").get("reason", "") == "location_capacity", "new runtime remains bounded at active capacity")
	for key: String in fake_keys: index.erase(key)
	var registry_a: Node = instance(host, first).get_node("UnitRegistry")
	var registry_b: Node = instance(host, second).get_node("UnitRegistry")
	var own_id := ""
	for unit: Node in registry_a.get_all_units():
		if unit.call("get_team_id") == "team_alpha" and registry_b.get_unit(unit.call("get_unit_id")) != null:
			own_id = String(unit.call("get_unit_id"))
			break
	check(not own_id.is_empty() and registry_a != registry_b, "same actual unit IDs are owned by distinct per-map registries")
	var selected_before: String = alpha.world.get_selected_location_id()
	var closed_layer := CanvasLayer.new()
	closed_layer.name = "ClosedLocalModalRegression"
	closed_layer.visible = false
	instance(alpha, first).add_child(closed_layer)
	check(await until(func(): return instance(alpha, second).get_node_or_null("Primary3DView/ViewportContainer/SubViewport") != null), "deferred actual terrain viewport is present")
	check(root_a.is_hex_ground_runtime_active() and root_b.is_hex_ground_runtime_active(), "both actual map runtimes use authoritative Hex Ground")
	var state_before: Dictionary = root_a.get_hex_ground_planning_snapshot()
	check(host.world.select_location(second) and alpha.world.get_selected_location_id() == selected_before, "host view switch leaves teammate view unchanged")
	check(alpha.world.select_location(first) and host.world.get_selected_location_id() == second, "same-team players simultaneously select different real maps")
	check(not instance(alpha, second).get_node("TacticalController").is_processing_unhandled_input() and instance(alpha, first).get_node("TacticalController").is_processing_unhandled_input(), "only locally selected map accepts tactical input")
	check(not instance(alpha, second).get_node("TacticalUI").visible and instance(alpha, first).get_node("TacticalUI").visible, "only selected map displays tactical HUD")
	var background_view: Node = instance(alpha, second).get_node_or_null("Primary3DView")
	var background_viewport: SubViewport = instance(alpha, second).get_node_or_null("Primary3DView/ViewportContainer/SubViewport")
	check(background_view != null and background_view.process_mode == Node.PROCESS_MODE_DISABLED and background_viewport != null and background_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED and background_viewport.gui_disable_input, "background viewport disables GPU updates and GUI input while mission remains live")
	check(instance(alpha, second).get_node("TacticalController").is_processing() and not instance(alpha, second).get_node("TacticalController").get("_tactical_ui_visible"), "background tactical execution continues with periodic HUD projection suspended")
	alpha.world.select_location(second)
	alpha.world.select_location(first)
	check(not closed_layer.visible and not instance(alpha, first).get_node("TacticalUI/CharacterOverlay").visible, "closed local CanvasLayer and character modal remain closed after map roundtrip")
	var late_layer := CanvasLayer.new()
	late_layer.name = "LateLocalLayerRegression"
	instance(alpha, second).add_child(late_layer)
	await process_frame
	check(not late_layer.visible, "late background CanvasLayer is suspended through child event without frame scans")
	check(instance(alpha, first).get_node("MissionSetup").get_fog_of_war_runtime_snapshot().mode == "unexplored_blackout" and instance(alpha, second).get_node("MissionSetup").get_fog_of_war_runtime_snapshot().mode == "unexplored_blackout", "both real map views preserve authoritative unexplored blackout")
	check(initial_client_fog.size() >= 2 and initial_client_fog.all(func(row: Dictionary): return not row.has_local_owner and row.state.mode == "unexplored_blackout" and row.state.terrain_knowledge.explored_tile_ids.is_empty() and row.state.terrain_knowledge.visible_tile_ids.is_empty()), "actual client scene begins black before READY without a second local sight owner")
	check(instance(alpha, first).get_node("Primary3DView").get_inspection_blackout_snapshot().mode == "unexplored_blackout" and instance(alpha, second).get_node("Primary3DView").get_inspection_blackout_snapshot().mode == "unexplored_blackout", "both actual client terrain renderers are black before host terrain publication")
	check(state_before == root_a.get_hex_ground_planning_snapshot(), "view switch leaves actual Ground state unchanged")
	root_a.network_command_accepted.connect(func(command: Dictionary, _peer: int): accepted.append({"id":first, "command":command}))
	root_b.network_command_accepted.connect(func(command: Dictionary, _peer: int): accepted.append({"id":second, "command":command}))
	client_a.network_command_result_received.connect(func(result: Dictionary): results.append(result))
	client_b.network_command_result_received.connect(func(result: Dictionary): results.append(result))
	if not own_id.is_empty():
		var own: Node = registry_a.get_unit(own_id)
		var command: Dictionary = {"command_type":"hold_position", "unit_id":own_id, "team_id":"team_alpha", "fireteam_id":own.call("get_fireteam_id")}
		client_a.submit_multiplayer_command(command)
		check(await until(func(): return accepted.size() == 1), "same-team client command reaches actual primary Root")
		check(accepted.size() == 1 and accepted[0].id == first and root_b.command_queue.is_empty(), "equal unit ID on second map receives no primary command")
		client_b.submit_multiplayer_command(command)
		check(await until(func(): return accepted.size() == 2), "same peer can command its own units on second Root")
		check(accepted.size() == 2 and accepted[1].id == second, "second command routes to second location only")
		client_b.rpc_id(1, "request_command", command, context)
		await create_timer(0.1).timeout
		check(accepted.size() == 2, "other location token cannot submit a command to this Root")
		var enemy: Dictionary = command.duplicate(true)
		enemy.team_id = "team_bravo"
		client_a.submit_multiplayer_command(enemy)
		await create_timer(0.1).timeout
		check(accepted.size() == 2 and not client_a.get_last_network_command_result().get("accepted", true), "wrong team command is rejected by unchanged production contract")
	# Rejoin block cannot be lifted by a primary-only Session READY.
	host.world.on_peer_block_changed(alpha_id, true)
	alpha.session.rpc_id(1, "notify_mission_runtime_ready", context)
	alpha.world.rpc_id(1, "notify_location_ready", first, second, context)
	bravo.world.rpc_id(1, "notify_location_ready", first, second, context_b)
	await create_timer(0.1).timeout
	check(not host.world.is_peer_ready(first, alpha_id) and not host.world.is_peer_ready(second, alpha_id) and not host.world.is_peer_ready(second, bravo_id), "legacy READY, wrong location token and enemy READY cannot unblock any new map")
	alpha.world.rpc_id(1, "notify_location_ready", first, second, context_b)
	check(await until(func(): return host.world.is_peer_ready(second, alpha_id)), "exact second-location READY restores that location")
	check(not host.world.is_peer_ready(first, alpha_id), "second READY does not restore primary snapshots")
	alpha.world.rpc_id(1, "notify_location_ready", first, first, context)
	await until(func(): return host.world.is_peer_ready(first, alpha_id))
	var snap_a: Array = []
	var snap_b: Array = []
	client_a.multiplayer_snapshot_applied.connect(func(snapshot: Dictionary): snap_a.append(snapshot))
	client_b.multiplayer_snapshot_applied.connect(func(snapshot: Dictionary): snap_b.append(snapshot))
	root_a.call("_physics_process", 0.1)
	root_b.call("_physics_process", 0.1)
	check(await until(func(): return not snap_a.is_empty() and not snap_b.is_empty()), "real team-projected snapshots reach both correct client Roots")
	await check_terrain_publication(host,alpha,bravo,first,second,alpha_id,bravo_id)

	var before_a: int = snap_a.size()
	var before_b: int = snap_b.size()
	root_a.rpc_id(alpha_id, "_receive_bound_tick_state_chunk", 999999, 0, 1, 1, false, PackedByteArray([0]), second)
	await create_timer(0.1).timeout
	check(snap_a.size() == before_a and snap_b.size() == before_b, "foreign-map snapshot token cannot mutate either replica")
	var root_id: int = root_b.get_instance_id()
	var unit_count: int = registry_b.get_all_units().size()
	host.world.publish_locations()
	alpha.world.start_world(alpha.session.build_session_assignments(), PRIMARY)
	await create_timer(0.15).timeout
	check(root_b.get_instance_id() == root_id and registry_b.get_all_units().size() == unit_count and host.world.get_selected_location_id() == second, "catalog replay/start replay preserves host runtime, units and independent view")
	check(not alpha.world.open_location(PRIMARY).get("ok", true), "client cannot open a new host location")
	var views_ready: bool = await until(func(): return instance(host, first).get_node_or_null("Primary3DView") != null and instance(host, second).get_node_or_null("Primary3DView") != null and instance(bravo, first).get_node_or_null("Primary3DView") != null)
	check(views_ready, "actual foreground and background camera owners are ready for perspective regression")
	if not views_ready:
		await finish()
		return
	check_permission_selection(host, first, second)
	var host_fireteams := PackedStringArray(host.session.build_session_assignments().peer_fireteams[1])
	var host_first_view: Dictionary = choose_local_view(instance(host, first), host_fireteams[0], Vector2(672, 384))
	var host_second_view: Dictionary = choose_local_view(instance(host, second), "", Vector2(864, 624))
	var bravo_view: Dictionary = choose_local_view(instance(bravo, first), "", Vector2(1056, 768))
	host.world.update_assignments(host.session.build_session_assignments())
	bravo.world.update_assignments(bravo.session.build_session_assignments())
	check(local_view_state(instance(host, first)) == host_first_view and local_view_state(instance(host, second)) == host_second_view and local_view_state(instance(bravo, first)) == bravo_view, "identical assignment replay preserves each actual selection and camera")
	var reordered: Dictionary = host.session.build_session_assignments()
	var reordered_fireteams := PackedStringArray(reordered.peer_fireteams[1])
	reordered_fireteams.reverse()
	reordered.peer_fireteams[1] = reordered_fireteams
	host.world.update_assignments(reordered)
	check(local_view_state(instance(host, first)) == host_first_view and local_view_state(instance(host, second)) == host_second_view, "permission order alone does not change either local selection or camera")
	alpha.session.disconnect_session()
	check(await until(func(): return host.session.get_session_snapshot().connected_count == 2), "real client disconnect removes only its Session presence")
	check(host.world.get_selected_location_id() == second and root_b.get_instance_id() == root_id, "disconnect preserves other player's view and second Root")
	check(await until(func(): return bravo.session.get_session_snapshot().connected_count == 2), "remaining client receives real peer-disconnect assignment publication")
	check(local_view_state(instance(host, first)) == host_first_view and local_view_state(instance(host, second)) == host_second_view and local_view_state(instance(bravo, first)) == bravo_view, "foreign disconnect preserves foreground and background fireteam selections and cameras")
	check(alpha.session.join_session("127.0.0.1", port), "same client reconnects over actual localhost transport")
	check(await until(func(): return instance(alpha, first) != null and instance(alpha, second) != null and host.world.is_peer_ready(second, alpha.api.get_unique_id()), 20.0), "authenticated rejoin restores both existing locations with fresh READY")
	check(root_b.get_instance_id() == root_id and registry_b.get_all_units().size() == unit_count and host.world.get_selected_location_id() == second, "real rejoin creates no host runtime/unit duplicates or foreign view reset")
	check(await until(func(): return bravo.session.get_session_snapshot().connected_count == 3), "remaining client receives actual authenticated rejoin publication")
	check(local_view_state(instance(host, first)) == host_first_view and local_view_state(instance(host, second)) == host_second_view and local_view_state(instance(bravo, first)) == bravo_view, "foreign authenticated rejoin preserves each other player's actual selection and camera")
	if instance(alpha, second) != null: stop_clock(instance(alpha, second))
	check(host.world.finish_location(first), "primary location can finish independently")
	check(root_a.get_parent().process_mode == Node.PROCESS_MODE_DISABLED and root_b.get_parent().process_mode != Node.PROCESS_MODE_DISABLED, "retired network-drain tree stops gameplay while other location stays active")
	await create_timer(0.15).timeout
	check(host.session.get_session_snapshot().mission_started and is_instance_valid(root_b) and alpha.world.get_selected_location_id() == second, "primary result keeps second mission running and selects remaining local map")
	check(host.session.get_multiplayer_runtime_context() == context, "primary result retains stable Session epoch until all locations finish")
	check(host.world.get_location_rows().size() == 1, "finished location releases index capacity and its catalog entry")
	check(await until(func(): return has_lifecycle_counts(host, 1) and has_lifecycle_counts(alpha, 1) and has_lifecycle_counts(bravo, 0)), "completed primary releases registry and per-node presentation records on every peer")
	await check_repeated_retirement(host, alpha, bravo, second)
	check(host.world.finish_location(second) and not host.session.get_session_snapshot().mission_started, "last location completion ends Session mission exactly then")
	var lobby_scene: PackedScene = load("res://scenes/ui/multiplayer_lobby.tscn")
	var lobby: Node = lobby_scene.instantiate()
	root.add_child(lobby)
	lobby.call("_on_session_mission_start_requested", {})
	check(String(lobby.get("_status_label").text).begins_with("Kartenstart abgelehnt") and not lobby.has_active_mission(), "real Lobby preserves launch rejection instead of claiming Mission running")
	check(not lobby.get("_world_bar").visible, "failed launch does not expose an empty gameplay location bar")
	lobby.queue_free()
	await finish()

func fog_state(peer: Dictionary, id: String) -> Dictionary:
	return instance(peer,id).get_node("MissionSetup").get_fog_of_war_runtime_snapshot()

func host_terrain(peer: Dictionary, id: String, team: String) -> Dictionary:
	return instance(peer,id).get_node("MissionSetup").get_multiplayer_terrain_fog_snapshot(team)

func terrain_equal(peer: Dictionary, id: String, owner: Dictionary) -> bool:
	return not owner.is_empty() and fog_state(peer,id).get("terrain_knowledge",{}) == owner.terrain_knowledge

func check_terrain_publication(host: Dictionary, alpha: Dictionary, bravo: Dictionary, first: String, second: String, alpha_id: int, bravo_id: int) -> void:
	var host_a: Node = instance(host,first).get_node("SimulationRoot")
	var host_b: Node = instance(host,second).get_node("SimulationRoot")
	var client_a: Node = instance(alpha,first).get_node("SimulationRoot")
	var complete: bool = await until(func():
		var a: Dictionary = host_terrain(host,first,"team_alpha")
		var b: Dictionary = host_terrain(host,first,"team_bravo")
		var c: Dictionary = host_terrain(host,second,"team_alpha")
		return not a.is_empty() and not b.is_empty() and not c.is_empty() and not a.terrain_knowledge.visible_tile_ids.is_empty() and not b.terrain_knowledge.visible_tile_ids.is_empty() and not c.terrain_knowledge.visible_tile_ids.is_empty())
	check(complete,"actual host FogOfWarSystem completes separate Alpha and Bravo terrain sight jobs on both maps")
	if not complete: return
	var a: Dictionary = host_terrain(host,first,"team_alpha")
	var b: Dictionary = host_terrain(host,first,"team_bravo")
	var c: Dictionary = host_terrain(host,second,"team_alpha")
	check(a.team_id == "team_alpha" and b.team_id == "team_bravo" and a.terrain_knowledge != b.terrain_knowledge,"opposing teams have genuinely different host terrain knowledge")
	var deadline: int = Time.get_ticks_msec()+4000
	while Time.get_ticks_msec()<deadline and not (terrain_equal(alpha,first,a) and terrain_equal(bravo,first,b) and terrain_equal(alpha,second,c)):
		host_a.call("_physics_process",0.1)
		host_b.call("_physics_process",0.1)
		await create_timer(0.1).timeout
	check(terrain_equal(alpha,first,a) and terrain_equal(bravo,first,b) and terrain_equal(alpha,second,c),"actual ENet snapshots deliver only each recipient team's authoritative terrain knowledge")
	check(fog_state(host,first).terrain_knowledge == fog_state(alpha,first).terrain_knowledge,"same-team host and client share identical explored and visible terrain")
	var before_a: Dictionary = fog_state(alpha,first)
	var before_b: Dictionary = fog_state(alpha,second)
	alpha.world.select_location(second)
	alpha.world.select_location(first)
	check(fog_state(alpha,first) == before_a and fog_state(alpha,second) == before_b,"switching actual maps preserves each independent accepted terrain projection")
	for pair: Array in [[alpha,first,a],[bravo,first,b],[alpha,second,c]]:
		var rendered: Dictionary = instance(pair[0],pair[1]).get_node("Primary3DView").get_inspection_blackout_snapshot()
		check(rendered.mode == "unexplored_blackout" and rendered.terrain_knowledge.visible_tile_ids == pair[2].terrain_knowledge.visible_tile_ids and rendered.terrain_knowledge.explored_tile_ids == pair[2].terrain_knowledge.explored_tile_ids,"actual rendered unknown/revealed terrain is exactly its host team projection: "+String(pair[1])+"/"+String(pair[2].team_id))
	var renderer: Node = instance(alpha,first).get_node("Primary3DView")
	var overlay_ready: bool = await until(func(): return renderer.get("_fow_overlay_multimesh") != null and not renderer.get("_fow_overlay_slot_by_tile_id").is_empty())
	check(overlay_ready,"actual client renderer has completed its terrain overlay for revision-gap checks")
	if overlay_ready:
		var next: Dictionary = a.duplicate(true)
		next.visibility_revision = int(renderer.get("_fow_overlay_visibility_revision"))+1
		next.delta_complete = true
		next.changed_tile_ids = PackedStringArray()
		var adjacent: Dictionary = TERRAIN_FOG.for_view(next,PackedStringArray())
		check(renderer.call("_can_apply_fow_overlay_delta",adjacent),"adjacent transported revision uses the actual renderer's existing delta route")
		next.visibility_revision += 1
		var skipped: Dictionary = TERRAIN_FOG.for_view(next,PackedStringArray())
		check(not renderer.call("_can_apply_fow_overlay_delta",skipped) and skipped.terrain_knowledge == a.terrain_knowledge,"skipped transported revision refuses partial delta and retains complete authoritative terrain knowledge")
	var envelope: Dictionary = host_a.project_multiplayer_state_for_peer(alpha_id)
	check_full_terrain_payload(envelope,host_a)
	check(envelope.get("terrain_fog",{}) == a and host_a.project_multiplayer_state_for_peer(bravo_id).get("terrain_fog",{}) == b,"Root read projection selects recipient terrain without mutating either owner")
	var throttled: Dictionary = {}
	host_a.call("_attach_multiplayer_terrain_fog",throttled,"team_alpha",true)
	var immediate: Dictionary = {}
	host_a.call("_attach_multiplayer_terrain_fog",immediate,"team_alpha",true)
	check(not immediate.has("terrain_fog"),"unchanged terrain revision does not copy full tile-ID lists into every Root tick")
	var stable: Dictionary = fog_state(alpha,first)
	var rejected: Dictionary = envelope.duplicate(true)
	rejected.tick += 1
	rejected.snapshot.tick = rejected.tick
	rejected.terrain_fog = b
	check(not client_a.call("_apply_remote_state",rejected).get("accepted",true) and fog_state(alpha,first) == stable,"foreign-team terrain is rejected before any replica or renderer mutation")
	rejected = envelope.duplicate(true)
	rejected.tick += 1
	rejected.snapshot.tick = rejected.tick
	rejected.terrain_fog.terrain_knowledge.known_all = true
	check(not client_a.call("_apply_remote_state",rejected).get("accepted",true) and fog_state(alpha,first) == stable,"forged known-all terrain conflicts with blackout mode and is rejected atomically")
	rejected = envelope.duplicate(true)
	rejected.tick += 1
	rejected.snapshot.tick = rejected.tick
	rejected.runtime_context = host_b.get_multiplayer_runtime_context()
	check(not client_a.call("_apply_remote_state",rejected).get("accepted",true) and fog_state(alpha,first) == stable,"other location terrain cannot cross the existing Root runtime-token guard")
	check(not client_a.call("_apply_remote_state",envelope).get("accepted",true) and fog_state(alpha,first) == stable,"stale full snapshot cannot rewind client terrain knowledge")
	var original_context: Dictionary = client_a.get_multiplayer_runtime_context()
	check(client_a.bind_multiplayer_runtime_context(original_context,"team_bravo").ok and fog_state(alpha,first).team_id == "team_bravo" and fog_state(alpha,first).terrain_knowledge.explored_tile_ids.is_empty(),"actual same-instance team rebind clears prior team knowledge to black")
	check(instance(alpha,first).get_node("Primary3DView").get_inspection_blackout_snapshot().terrain_knowledge.explored_tile_ids.is_empty(),"team rebind also clears the actual renderer immediately")
	client_a.clear_multiplayer_runtime_context()
	check(client_a.get("_multiplayer_terrain_fog_sent").is_empty() and fog_state(alpha,first).terrain_knowledge.explored_tile_ids.is_empty(),"clearing actual Root binding clears terrain send history and replica knowledge")
	check(client_a.bind_multiplayer_runtime_context(original_context,"team_alpha").ok,"same actual client restores its Session team binding after reset probe")
	deadline = Time.get_ticks_msec()+4000
	while Time.get_ticks_msec()<deadline and not terrain_equal(alpha,first,a):
		host_a.call("_physics_process",0.1)
		await create_timer(0.1).timeout
	check(terrain_equal(alpha,first,a),"unchanged host revision repairs a cleared/rejoined client over actual ENet without new discovery")

func check_full_terrain_payload(base: Dictionary, host_root: Node) -> void:
	# Synthetic worst-known terrain lists, encoded by the actual Variant/ZSTD
	# transport. No synthetic knowledge is ever applied to a live owner/view.
	var ids := PackedStringArray()
	for x in 512:
		for y in 256: ids.append("tile_%d_%d" % [x,y])
	ids.sort()
	var delta_owner: Dictionary = {"team_id":"team_alpha","mode":"unexplored_blackout","visibility_revision":2,"terrain_knowledge":{"known_all":false,"unknown_policy":"unseen_tiles_black","explored_tile_ids":PackedStringArray(["tile_1_1"]),"visible_tile_ids":PackedStringArray(["tile_1_1"])},"visibility_delta":{"full_scan":false,"changed_tiles":[{"tile_id":"tile_1_1","visible":true,"explored":true}]}}
	var delta: Dictionary = TERRAIN_FOG.project(delta_owner)
	check(TERRAIN_FOG.validate(delta,"team_alpha") and TERRAIN_FOG.for_view(delta,PackedStringArray()).visibility_delta.changed_tiles == [{"tile_id":"tile_1_1"}],"bounded owner delta survives transport projection into existing renderer delta shape")
	delta_owner.visibility_delta.full_scan = true
	check(not TERRAIN_FOG.project(delta_owner).delta_complete and TERRAIN_FOG.project(delta_owner).changed_tile_ids.is_empty(),"full scans do not duplicate large dictionary-per-tile deltas on the wire")
	var full: Dictionary = base.duplicate(true)
	full.terrain_fog.terrain_knowledge.explored_tile_ids = ids
	full.terrain_fog.terrain_knowledge.visible_tile_ids = ids
	var raw: PackedByteArray = var_to_bytes(full)
	var compressed: PackedByteArray = raw.compress(host_root.SNAPSHOT_COMPRESSION_MODE)
	var wire: PackedByteArray = compressed if not compressed.is_empty() and compressed.size() < raw.size() else raw
	var chunks: int = ceili(float(wire.size()) / float(host_root.SNAPSHOT_CHUNK_PAYLOAD_BYTES))
	print("WORLD_FULL_TERRAIN raw_bytes=%d wire_bytes=%d chunks=%d tile_ids=%d" % [raw.size(),wire.size(),chunks,ids.size()])
	check(raw.size() <= host_root.SNAPSHOT_MAX_RAW_BYTES and chunks <= host_root.SNAPSHOT_MAX_CHUNK_COUNT,"actual encoded 512x256 fully known terrain fits unchanged Root raw/chunk limits")
	var decoded: Dictionary = bytes_to_var(compressed.decompress(raw.size(),host_root.SNAPSHOT_COMPRESSION_MODE))
	check(decoded == full and decoded.terrain_fog.terrain_knowledge.visible_tile_ids is PackedStringArray,"actual transport codec preserves PackedStringArray terrain knowledge exactly")

func finish() -> void:
	for peer: Dictionary in peers:
		peer.world.clear_world()
		peer.session.disconnect_session()
	for _frame in range(6): await process_frame
	for peer: Dictionary in peers: peer.scope.queue_free()
	for _frame in range(4): await process_frame
	print("SHARED_TEAM_MULTIMAP passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
