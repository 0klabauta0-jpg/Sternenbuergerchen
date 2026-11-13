extends SceneTree
## Six real localhost peers: production Session RPCs and command ownership.
const SESSION = preload("res://scripts/multiplayer/multiplayer_session.gd")
const CONTRACT = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
const GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")
var passed: int = 0
var failed: int = 0
var scopes: Array[Node] = []
var clients: Array[Node] = []
var host: Node

func _init() -> void:
	if GUARD.require_isolated_user_data(): call_deferred("_run")

func check(value: bool, label: String) -> void:
	if value: passed += 1
	else: failed += 1
	print("PASS " if value else "FAIL ", label)

func wait_for(condition: Callable, label: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 8000
	while not bool(condition.call()) and Time.get_ticks_msec() < deadline:
		await create_timer(0.01).timeout
	var ok: bool = bool(condition.call())
	check(ok, label)
	return ok

func make_session(scope_name: String) -> Node:
	var scope := Node.new()
	scope.name = scope_name
	root.add_child(scope)
	set_multiplayer(SceneMultiplayer.new(), scope.get_path())
	var session: Node = SESSION.new()
	session.name = "Session"
	scope.add_child(session)
	scopes.append(scope)
	return session

func assignments() -> Dictionary:
	return host.call("build_session_assignments")

func all_ready() -> void:
	host.call("set_local_ready", true)
	for client in clients: client.call("set_local_ready", true)
	await wait_for(func(): return int(host.call("get_session_snapshot").ready_count) == clients.size() + 1, "all connected peers ready through actual RPC")

func shared_side(side: String, expected_count: int, expected_fireteams: PackedStringArray) -> bool:
	var value: Dictionary = assignments()
	var count: int = 0
	for peer_id in value.peer_teams:
		if value.peer_teams[peer_id] != side: continue
		count += 1
		if value.peer_roles[peer_id] == "spectator" or value.peer_fireteams[peer_id] != expected_fireteams: return false
	return count == expected_count

func check_command_rights() -> void:
	var value: Dictionary = assignments()
	var contract = CONTRACT.new()
	for client in clients:
		var peer_id: int = client.multiplayer.get_unique_id()
		var side: String = value.peer_teams[peer_id]
		var fireteams: PackedStringArray = value.peer_fireteams[peer_id]
		var context: Dictionary = {"peer_role":value.peer_roles[peer_id], "peer_team_id":side, "peer_fireteam_ids":fireteams, "unit_team_id":side, "unit_fireteam_id":fireteams[0]}
		var command: Dictionary = {"command_type":"hold_position", "unit_id":"same_team_unit", "team_id":side, "fireteam_id":fireteams[0]}
		check(bool(contract.validate(command, context).accepted), "each real peer assignment authorizes own shared unit")
		context.unit_team_id = "team_bravo" if side == "team_alpha" else "team_alpha"
		check(not bool(contract.validate(command, context).accepted), "each peer assignment rejects actual enemy unit despite forged own-team hint")
		context.unit_team_id = side
		command["health"] = 999
		var mutation_result: Dictionary = contract.validate(command, context)
		check(not bool(mutation_result.accepted) and String(mutation_result.reason) == "state_mutation_key:health", "shared control never permits state mutation")

func _run() -> void:
	host = make_session("Host")
	host.call("set_lobby_player_setup", {"team_play_mode":"coop", "team_slot":"team_alpha", "max_players":16})
	check(bool(host.call("start_host", 0)), "production host binds localhost with spare capacity")
	var server: ENetMultiplayerPeer = host.multiplayer.multiplayer_peer
	var port: int = server.host.get_local_port()
	for index in range(5):
		var client: Node = make_session("Client%d" % index)
		client.call("set_lobby_player_setup", {"player_name":"Player%d" % index, "team_slot":"team_alpha"})
		clients.append(client)
		check(bool(client.call("join_session", "127.0.0.1", port)), "real client %d connects" % index)
	if not await wait_for(func(): return shared_side("team_alpha", 6, PackedStringArray(["blue", "gold"])), "six coop peers share both fireteams, no forced spectators"):
		await finish()
		return
	await wait_for(func():
		for client in clients:
			if client.call("get_session_snapshot").connected_count != 6: return false
		return true, "all six roster snapshots converge")
	check(not bool(host.call("can_start_mission")), "not ready cannot start")
	await all_ready()
	check(bool(host.call("can_start_mission")), "six ready players may start with ten unused places")
	check_command_rights()

	host.call("set_lobby_player_setup", {"team_play_mode":"coop_versus"})
	check(not bool(host.call("can_start_mission")), "mode change clears readiness and needs opposing side")
	for index in range(clients.size()):
		clients[index].call("set_lobby_player_setup", {"team_slot":"team_alpha" if index < 2 else "team_bravo"})
	await wait_for(func(): return shared_side("team_alpha", 3, PackedStringArray(["blue", "gold"])) and shared_side("team_bravo", 3, PackedStringArray(["red"])), "actual RPC gives three active players on each side")
	await all_ready()
	check(bool(host.call("can_start_mission")), "three versus three coop-PvP may start")
	check_command_rights()
	var before: Dictionary = assignments().duplicate(true)
	clients[0].call("set_lobby_player_setup", {"team_play_mode":"coop", "max_players":2})
	await create_timer(0.1).timeout
	check(assignments().team_play_mode == "coop_versus" and host.max_players == 16 and assignments().peer_teams == before.peer_teams, "client cannot change host mode or capacity")

	# One player's departure must not disconnect the four remaining clients.
	var departing: Node = clients.back()
	var departed_id: int = departing.multiplayer.get_unique_id()
	departing.call("disconnect_session")
	await wait_for(func(): return int(host.call("get_session_snapshot").connected_count) == 5, "one peer leaves, five remain")
	for index in range(4):
		check(bool(clients[index].call("get_session_snapshot").has_active_peer), "other client remains connected after teammate leaves")
	check(not assignments().peer_teams.has(departed_id), "departed assignment is removed")
	check(bool(departing.call("join_session", "127.0.0.1", port)), "same player reconnects")
	await wait_for(func(): return shared_side("team_bravo", 3, PackedStringArray(["red"])), "rejoined peer restores shared side")
	await all_ready()
	check(bool(host.call("request_start_mission")), "host starts six-peer session once ready")
	await wait_for(func():
		for client in clients:
			if not bool(client.call("get_session_snapshot").mission_started): return false
		return true, "start reaches all five clients")
	departing = clients[0] # Same-side rejoin must retain the requested Alpha side too.
	var old_team: String = assignments().peer_teams[departing.multiplayer.get_unique_id()]
	departing.call("disconnect_session")
	await wait_for(func(): return int(host.call("get_session_snapshot").connected_count) == 5, "running session survives disconnect")
	check(bool(departing.call("join_session", "127.0.0.1", port)), "running session rejoin uses retained token")
	await wait_for(func(): return bool(departing.call("get_session_snapshot").mission_started), "reconnect restores running mission")
	var new_id: int = departing.multiplayer.get_unique_id()
	check(assignments().peer_teams.get(new_id, "") == old_team and assignments().peer_roles.get(new_id, "") == "commander", "rejoin preserves team and active role")
	check(not bool(departing.call("set_lobby_player_setup", {"team_slot":"team_alpha"})), "running peer cannot switch teams")
	host.call("complete_mission")
	await wait_for(func(): return not bool(departing.call("get_session_snapshot").mission_started), "completion returns rejoined peer to lobby")
	host.call("set_lobby_player_setup", {"player_name":"Host renamed"})
	check(assignments().peer_teams.get(new_id, "") == "team_alpha" and assignments().peer_fireteams.get(new_id, PackedStringArray()) == PackedStringArray(["blue", "gold"]), "post-rejoin lobby rebalance preserves requested same-side team")
	await finish()

func finish() -> void:
	for client in clients: client.call("disconnect_session")
	host.call("disconnect_session")
	await process_frame
	for scope in scopes: scope.free()
	await process_frame
	print("SHARED_TEAM_SESSION passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
