extends SceneTree

const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")
const INTERACTION_COMMAND := preload("res://scripts/mission/mission_interaction_multiplayer_command.gd")
const MULTIPLAYER_SESSION := preload("res://scripts/multiplayer/multiplayer_session.gd")
const ENET_PORT_START := 19692
const ENET_PORT_END := 19702

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1104 Product Lobby Multi-Client Parallel Interaction Playtest ===")
	var fixture: Dictionary = await _create_lobby_triple()
	_assert(bool(fixture.get("connected", false)), "Host and two clients connect through product lobbies")
	if not bool(fixture.get("connected", false)):
		quit(1)
		return
	var host_lobby: Node = fixture["lobbies"][0]
	var client_a_lobby: Node = fixture["lobbies"][1]
	var client_b_lobby: Node = fixture["lobbies"][2]
	var apis: Array = fixture["apis"]
	var client_a_peer_id: int = (apis[1] as MultiplayerAPI).get_unique_id()
	var client_b_peer_id: int = (apis[2] as MultiplayerAPI).get_unique_id()
	host_lobby.get_node("MultiplayerSession").call("set_lobby_player_setup", {"team_play_mode": "coop", "team_slot": "team_alpha"})
	await _poll_all(apis, 24)
	client_a_lobby.get_node("MultiplayerSession").call("set_lobby_player_setup", {"team_slot": "team_bravo", "player_name": "Coop Spoof Probe"})
	await _poll_all(apis, 20)
	var assignments: Dictionary = Dictionary(Dictionary(host_lobby.call("get_session_snapshot")).get("assignments", {}))
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	var host_fireteams: PackedStringArray = PackedStringArray(peer_fireteams.get(1, PackedStringArray()))
	var client_a_fireteams: PackedStringArray = PackedStringArray(peer_fireteams.get(client_a_peer_id, PackedStringArray()))
	var client_b_fireteams: PackedStringArray = PackedStringArray(peer_fireteams.get(client_b_peer_id, PackedStringArray()))
	_assert(host_fireteams.size() == 1 and client_a_fireteams.size() == 1 and client_b_fireteams.is_empty(), "Three-player Coop lobby allocates two active Fireteams and one Spectator")
	var assigned_tokens := PackedStringArray()
	for ids in [host_fireteams, client_a_fireteams, client_b_fireteams]:
		if not ids.is_empty():
			assigned_tokens.append(String(ids[0]).strip_edges().to_lower())
	_assert(assigned_tokens.size() == 2 and _unique_strings(assigned_tokens).size() == 2, "Three-player Coop lobby does not duplicate active Fireteams")
	_assert(assigned_tokens.has("blue") and assigned_tokens.has("gold"), "Product Coop allocation uses the two mission Fireteams")
	_assert(String(Dictionary(assignments.get("peer_roles", {})).get(client_b_peer_id, "")) == "spectator", "Third peer receives explicit Spectator role")
	_assert(String(Dictionary(assignments.get("peer_teams", {})).get(client_a_peer_id, "")) == "team_alpha", "Client setup cannot overwrite authoritative Coop team normalization")

	_assert(bool(host_lobby.call("set_ready", true)), "Host marks ready")
	_assert(bool(client_a_lobby.call("set_ready", true)), "Client A marks ready")
	_assert(bool(client_b_lobby.call("set_ready", true)), "Client B marks ready")
	await _poll_all(apis, 36)
	_assert(bool(host_lobby.call("start_mission")), "Host starts three-player product mission")
	await _poll_all(apis, 40)
	_assert(bool(host_lobby.call("has_active_mission")) and bool(client_a_lobby.call("has_active_mission")) and bool(client_b_lobby.call("has_active_mission")), "All three product lobbies launch mission instances")

	var host_mission: Node = host_lobby.get("_active_mission")
	var client_a_mission: Node = client_a_lobby.get("_active_mission")
	var client_b_mission: Node = client_b_lobby.get("_active_mission")
	var host_sim: Node = host_mission.get_node("SimulationRoot")
	var client_a_sim: Node = client_a_mission.get_node("SimulationRoot")
	var client_b_sim: Node = client_b_mission.get_node("SimulationRoot")
	var host_driver: Node = host_mission.get_node("CombatLoopDriver")
	var client_a_driver: Node = client_a_mission.get_node("CombatLoopDriver")
	var client_b_driver: Node = client_b_mission.get_node("CombatLoopDriver")
	var client_a_controller: Node = client_a_mission.get_node("TacticalController")
	var client_b_controller: Node = client_b_mission.get_node("TacticalController")
	var host_fireteam: String = String(host_fireteams[0]).strip_edges().to_lower()
	var client_a_fireteam: String = String(client_a_fireteams[0]).strip_edges().to_lower()
	var host_unit: Node2D = _find_unit(host_mission, host_fireteam)
	var client_a_unit: Node2D = _find_unit(host_mission, client_a_fireteam)
	_assert(host_unit != null and client_a_unit != null, "Both assigned Coop Fireteams resolve authoritative mission units")
	if host_unit == null or client_a_unit == null:
		_cleanup(fixture)
		quit(1)
		return
	var team_by_peer: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	var target_a := Vector2(160.0, 160.0)
	var target_b := Vector2(320.0, 160.0)
	var command_a: Dictionary = _build_command("station_computer_alpha", "computer", "take", host_fireteam, String(host_unit.call("get_unit_id")), String(team_by_peer.get(1, "team_alpha")), target_a)
	var command_b: Dictionary = _build_command("cargo_landing_hold", "hold_zone", "defend", client_a_fireteam, String(client_a_unit.call("get_unit_id")), String(team_by_peer.get(client_a_peer_id, "team_alpha")), target_b)
	var conflict: Dictionary = _build_command("station_computer_alpha", "computer", "take", client_a_fireteam, String(client_a_unit.call("get_unit_id")), String(team_by_peer.get(client_a_peer_id, "team_alpha")), target_a)
	var host_result: Dictionary = Dictionary(host_sim.call("submit_network_command_for_peer", command_a, 1))
	client_a_sim.rpc_id(1, "request_command", command_b)
	await _poll_all(apis, 20)
	client_a_controller.set("_network_mission_interaction_feedback", {"display_token": "COM", "fireteam_id": client_a_fireteam})
	client_a_sim.rpc_id(1, "request_command", conflict)
	await _poll_all(apis, 24)
	_assert(bool(host_result.get("accepted", false)), "Host Fireteam starts first Interaction")
	var pending: Dictionary = Dictionary(host_driver.call("get_pending_network_mission_interaction_snapshot"))
	_assert(int(pending.get("pending_count", 0)) == 2, "Host owns two parallel pending Interactions")
	_assert(_pending_owner(pending, "station_computer_alpha") == host_fireteam and _pending_owner(pending, "cargo_landing_hold") == client_a_fireteam, "Parallel pending Interactions keep distinct product assignments")
	var conflict_feedback: Dictionary = Dictionary(client_a_controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(not bool(conflict_feedback.get("accepted", true)) and String(conflict_feedback.get("reason_label", "")) == "ANDERES FIRETEAM AKTIV", "Active client receives human reservation feedback")
	_assert(String(conflict_feedback.get("compact_line", "")).contains(client_a_fireteam.to_upper()) and not String(conflict_feedback.get("compact_line", "")).contains("interaction_reserved"), "Active client feedback names Fireteam without technical reason")
	client_b_controller.set("_network_mission_interaction_feedback", {"display_token": "COM", "fireteam_id": host_fireteam})
	client_b_sim.rpc_id(1, "request_command", command_a)
	await _poll_all(apis, 20)
	var spectator_feedback: Dictionary = Dictionary(client_b_controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(not bool(spectator_feedback.get("accepted", true)) and String(spectator_feedback.get("reason_label", "")) == "ZUSCHAUER KANN NICHT BEFEHLEN", "Spectator cannot issue a known Fireteam command")
	_assert(String(spectator_feedback.get("compact_line", "")).contains("BLOCKIERT") and not String(spectator_feedback.get("compact_line", "")).contains("fireteam_not_assigned"), "Spectator rejection remains human-readable")

	host_unit.global_position = target_a
	client_a_unit.global_position = target_b
	host_sim.call("_physics_process", 2.0)
	host_sim.call("_physics_process", 0.016)
	await _poll_all(apis, 32)
	var host_states: Dictionary = Dictionary(host_driver.call("get_mission_interaction_runtime_states"))
	var client_a_states: Dictionary = Dictionary(client_a_driver.call("get_mission_interaction_runtime_states"))
	var client_b_states: Dictionary = Dictionary(client_b_driver.call("get_mission_interaction_runtime_states"))
	_assert(_has_progress(host_states, "station_computer_alpha", host_fireteam) and _has_progress(host_states, "cargo_landing_hold", client_a_fireteam), "Host advances two product Fireteams in parallel")
	_assert(_same_two_states(host_states, client_a_states) and _same_two_states(host_states, client_b_states), "Both clients converge on the same parallel Interaction owners")
	var client_a_line: String = String(Dictionary(client_a_controller.call("get_network_mission_interaction_feedback_snapshot")).get("compact_line", ""))
	var client_b_line: String = String(Dictionary(client_b_controller.call("get_network_mission_interaction_feedback_snapshot")).get("compact_line", ""))
	_assert(client_a_line.contains(host_fireteam.to_upper()) and client_a_line.contains(client_a_fireteam.to_upper()) and client_a_line.contains(" | "), "Client A HUD shows both parallel owners")
	_assert(client_b_line.contains(host_fireteam.to_upper()) and client_b_line.contains(client_a_fireteam.to_upper()) and client_b_line.contains(" | "), "Client B HUD shows both parallel owners after reject")
	_assert(Array(client_a_sim.get("command_queue")).is_empty() and Array(client_a_sim.get("effects_queue")).is_empty() and Array(client_b_sim.get("command_queue")).is_empty() and Array(client_b_sim.get("effects_queue")).is_empty(), "Three-player snapshot recovery creates no client commands or effects")

	_cleanup(fixture)
	await process_frame
	await _test_assignment_policy_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_assignment_policy_contract() -> void:
	var versus_session: Node = MULTIPLAYER_SESSION.new()
	root.add_child(versus_session)
	versus_session.call("configure_host_state_for_test", [2])
	var versus_fireteams: Dictionary = Dictionary(Dictionary(versus_session.call("build_session_assignments")).get("peer_fireteams", {}))
	_assert(PackedStringArray(versus_fireteams.get(1, PackedStringArray())) == PackedStringArray(["blue", "gold"]) and PackedStringArray(versus_fireteams.get(2, PackedStringArray())) == PackedStringArray(["red"]), "Default two-player Versus allocation remains unchanged")
	versus_session.queue_free()
	await process_frame

	var coop_session: Node = MULTIPLAYER_SESSION.new()
	root.add_child(coop_session)
	coop_session.set("max_players", 3)
	coop_session.call("configure_host_state_for_test", [2, 3])
	coop_session.call("set_lobby_player_setup", {"team_play_mode": "coop", "team_slot": "team_alpha"})
	var initial_assignments: Dictionary = Dictionary(coop_session.call("build_session_assignments"))
	_assert(PackedStringArray(Dictionary(initial_assignments.get("peer_fireteams", {})).get(3, PackedStringArray())).is_empty() and String(Dictionary(initial_assignments.get("peer_roles", {})).get(3, "")) == "spectator", "Excess Coop peer starts as Spectator")
	var coop_teams: Dictionary = Dictionary(initial_assignments.get("peer_teams", {}))
	_assert(String(coop_teams.get(1, "")) == "team_alpha" and String(coop_teams.get(2, "")) == "team_alpha" and String(coop_teams.get(3, "")) == "team_alpha", "Coop rebalance normalizes every peer onto host team")
	coop_session.call("set_lobby_player_setup", {"team_play_mode": "versus", "team_slot": "team_alpha"})
	var restored_assignments: Dictionary = Dictionary(coop_session.call("build_session_assignments"))
	var restored_fireteams: Dictionary = Dictionary(restored_assignments.get("peer_fireteams", {}))
	var restored_roles: Dictionary = Dictionary(restored_assignments.get("peer_roles", {}))
	var restored_teams: Dictionary = Dictionary(restored_assignments.get("peer_teams", {}))
	_assert(PackedStringArray(restored_fireteams.get(1, PackedStringArray())) == PackedStringArray(["blue", "gold"]) and PackedStringArray(restored_fireteams.get(2, PackedStringArray())) == PackedStringArray(["red"]), "Coop to Versus restores host and first-client Fireteams")
	_assert(PackedStringArray(restored_fireteams.get(3, PackedStringArray())).is_empty() and String(restored_roles.get(3, "")) == "spectator", "Extra Versus peer remains Spectator without duplicate red assignment")
	_assert(String(restored_teams.get(2, "")) == "team_bravo" and String(restored_teams.get(3, "")) == "team_bravo", "Coop to Versus restores client team ownership")
	coop_session.call("set_lobby_player_setup", {"team_play_mode": "coop", "team_slot": "team_alpha"})
	coop_session.call("_on_peer_disconnected", 2)
	var promoted_assignments: Dictionary = Dictionary(coop_session.call("build_session_assignments"))
	_assert(PackedStringArray(Dictionary(promoted_assignments.get("peer_fireteams", {})).get(3, PackedStringArray())) == PackedStringArray(["gold"]) and String(Dictionary(promoted_assignments.get("peer_roles", {})).get(3, "")) == "commander", "Premission disconnect promotes waiting Spectator into free Coop Fireteam")
	coop_session.queue_free()
	await process_frame


func _create_lobby_triple() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var lobbies: Array = []
		for index in range(3):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1104Peer%d" % index
			root.add_child(local_root)
			set_multiplayer(api, local_root.get_path())
			var lobby: Node = LOBBY_SCENE.instantiate()
			lobby.name = "Lobby"
			local_root.add_child(lobby)
			lobby.get_node("MultiplayerSession").set("max_players", 3)
			roots.append(local_root)
			apis.append(api)
			lobbies.append(lobby)
		await process_frame
		if not bool(lobbies[0].call("host_game", port)):
			_free_roots(roots)
			continue
		if not bool(lobbies[1].call("join_game", "127.0.0.1", port)) or not bool(lobbies[2].call("join_game", "127.0.0.1", port)):
			_free_roots(roots)
			continue
		for _index in range(240):
			await _poll_all(apis, 1)
			if int(Dictionary(lobbies[0].call("get_session_snapshot")).get("connected_count", 0)) == 3:
				return {"connected": true, "port": port, "roots": roots, "apis": apis, "lobbies": lobbies}
		_free_roots(roots)
		await process_frame
	return {"connected": false}


func _build_command(interaction_id: String, interaction_type: String, command_type: String, fireteam_id: String, unit_id: String, team_id: String, target: Vector2) -> Dictionary:
	return Dictionary(INTERACTION_COMMAND.build_network_command({
		"accepted": true,
		"interaction_id": interaction_id,
		"interaction_type": interaction_type,
		"command_type": command_type,
		"required_order": command_type,
		"duration_seconds": 120.0,
		"interaction_radius_world": 72.0,
		"fireteam_id": fireteam_id,
		"target_position": target,
		"step_id": interaction_id,
		"gate_id": interaction_id,
		"required_state": interaction_id + "_complete",
	}, unit_id, team_id, target))


func _find_unit(scene: Node, fireteam_id: String) -> Node2D:
	for child in scene.get_children():
		if child is Node2D and child.has_method("get_unit_id") and child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges().to_lower() == fireteam_id:
			return child as Node2D
	return null


func _pending_owner(snapshot: Dictionary, interaction_id: String) -> String:
	return String(Dictionary(Dictionary(snapshot.get("entries", {})).get(interaction_id, {})).get("fireteam_id", "")).strip_edges().to_lower()


func _has_progress(states: Dictionary, interaction_id: String, fireteam_id: String) -> bool:
	var state: Dictionary = Dictionary(states.get(interaction_id, {}))
	return String(state.get("fireteam_id", "")) == fireteam_id and float(state.get("progress", 0.0)) > 0.0


func _same_two_states(host_states: Dictionary, client_states: Dictionary) -> bool:
	for interaction_id in ["station_computer_alpha", "cargo_landing_hold"]:
		var host_state: Dictionary = Dictionary(host_states.get(interaction_id, {}))
		var client_state: Dictionary = Dictionary(client_states.get(interaction_id, {}))
		if String(host_state.get("fireteam_id", "")) != String(client_state.get("fireteam_id", "")) or absf(float(host_state.get("progress", 0.0)) - float(client_state.get("progress", 0.0))) > 0.02:
			return false
	return true


func _unique_strings(values: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for value in values:
		if not result.has(value):
			result.append(value)
	return result


func _poll_all(apis: Array, frames: int) -> void:
	for _index in range(frames):
		for api_variant in apis:
			(api_variant as MultiplayerAPI).poll()
		await process_frame


func _cleanup(fixture: Dictionary) -> void:
	for lobby_variant in fixture.get("lobbies", []):
		(lobby_variant as Node).call("disconnect_game")
	_free_roots(Array(fixture.get("roots", [])))


func _free_roots(roots: Array) -> void:
	for root_variant in roots:
		(root_variant as Node).queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
