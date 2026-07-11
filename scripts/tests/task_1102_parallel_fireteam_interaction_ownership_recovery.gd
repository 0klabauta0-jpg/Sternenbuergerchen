extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const INTERACTION_COMMAND := preload("res://scripts/mission/mission_interaction_multiplayer_command.gd")
const ENET_PORT_START := 19681
const ENET_PORT_END := 19691

var _passed := 0
var _failed := 0
var _client_results: Array = []
var _host_accepted_commands: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1102 Parallel Fireteam Interaction Ownership Recovery ===")
	await _test_parallel_ownership_and_rebind()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_parallel_ownership_and_rebind() -> void:
	var pair: Dictionary = await _create_pair()
	_assert(bool(pair.get("connected", false)), "Host and client connect over ENet")
	if not bool(pair.get("connected", false)):
		return
	var host_api: MultiplayerAPI = pair["host_api"]
	var client_api: MultiplayerAPI = pair["client_api"]
	var host_root := Node.new()
	var client_root := Node.new()
	host_root.name = "Task1102Host"
	client_root.name = "Task1102Client"
	root.add_child(host_root)
	root.add_child(client_root)
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(client_api, client_root.get_path())
	var host_scene: Node = MISSION_SCENE.instantiate()
	var client_scene: Node = MISSION_SCENE.instantiate()
	host_scene.name = "Mission"
	client_scene.name = "Mission"
	host_root.add_child(host_scene)
	client_root.add_child(client_scene)
	await _poll(host_api, client_api, 16)

	var host_sim: Node = host_scene.get_node("SimulationRoot")
	var client_sim: Node = client_scene.get_node("SimulationRoot")
	var host_driver: Node = host_scene.get_node("CombatLoopDriver")
	var client_driver: Node = client_scene.get_node("CombatLoopDriver")
	var fireteams: PackedStringArray = PackedStringArray(host_scene.get_node("TacticalController").call("_get_available_fireteam_ids"))
	_assert(fireteams.size() >= 2, "Mission fixture exposes two Fireteams")
	if fireteams.size() < 2:
		_cleanup(pair, host_root, client_root)
		return
	var host_fireteam: String = String(fireteams[0]).strip_edges().to_lower()
	var client_fireteam: String = String(fireteams[1]).strip_edges().to_lower()
	var host_unit: Node2D = _find_unit(host_scene, host_fireteam)
	var client_unit: Node2D = _find_unit(host_scene, client_fireteam)
	_assert(host_unit != null and client_unit != null, "Both Fireteams resolve to authoritative units")
	if host_unit == null or client_unit == null:
		_cleanup(pair, host_root, client_root)
		return
	var client_peer_id: int = client_api.get_unique_id()
	_configure_assignments(host_sim, client_peer_id, host_fireteam, client_fireteam)
	_configure_assignments(client_sim, client_peer_id, host_fireteam, client_fireteam)
	client_sim.network_command_result_received.connect(_on_client_result)
	host_sim.network_command_accepted.connect(_on_host_command_accepted)

	var target_a := Vector2(160.0, 160.0)
	var target_b := Vector2(320.0, 160.0)
	var host_command: Dictionary = _build_command("parallel_terminal_alpha", host_fireteam, String(host_unit.call("get_unit_id")), target_a, 120.0)
	var client_command: Dictionary = _build_command("parallel_terminal_bravo", client_fireteam, String(client_unit.call("get_unit_id")), target_b, 120.0)
	var host_result: Dictionary = Dictionary(host_sim.call("submit_network_command_for_peer", host_command, 1))
	client_sim.rpc_id(1, "request_command", client_command)
	await _poll(host_api, client_api, 20)
	_assert(bool(host_result.get("accepted", false)), "Host Fireteam starts its Interaction")
	var pending: Dictionary = Dictionary(host_driver.call("get_pending_network_mission_interaction_snapshot"))
	_assert(int(pending.get("pending_count", 0)) == 2, "Different Fireteams own two parallel Interactions")
	_assert(_pending_owner(pending, "parallel_terminal_alpha") == host_fireteam, "First Interaction keeps host Fireteam ownership")
	_assert(_pending_owner(pending, "parallel_terminal_bravo") == client_fireteam, "Second Interaction keeps client Fireteam ownership")

	var conflicting_command: Dictionary = _build_command("parallel_terminal_alpha", client_fireteam, String(client_unit.call("get_unit_id")), target_a, 120.0)
	client_sim.rpc_id(1, "request_command", conflicting_command)
	await _poll(host_api, client_api, 20)
	var conflict_result: Dictionary = _last_result_for("parallel_terminal_alpha")
	pending = Dictionary(host_driver.call("get_pending_network_mission_interaction_snapshot"))
	_assert(not bool(conflict_result.get("accepted", true)) and String(conflict_result.get("reason", "")) == "interaction_reserved_by_other_fireteam", "Foreign Fireteam receives explicit Interaction reservation reject")
	_assert(_pending_owner(pending, "parallel_terminal_alpha") == host_fireteam, "Rejected command cannot replace Interaction owner")
	_assert(Vector2(Dictionary(Dictionary(pending.get("entries", {})).get("parallel_terminal_alpha", {})).get("target_position", Vector2.ZERO)).is_equal_approx(target_a), "Rejected command cannot rewrite Interaction target")

	host_unit.global_position = target_a
	client_unit.global_position = target_b
	host_sim.call("_physics_process", 2.0)
	host_sim.call("_physics_process", 0.016)
	await _poll(host_api, client_api, 20)
	var host_states: Dictionary = Dictionary(host_driver.call("get_mission_interaction_runtime_states"))
	var client_states: Dictionary = Dictionary(client_driver.call("get_mission_interaction_runtime_states"))
	_assert(_has_partial_progress(host_states, "parallel_terminal_alpha", host_fireteam), "Host Fireteam advances its own Interaction")
	_assert(_has_partial_progress(host_states, "parallel_terminal_bravo", client_fireteam), "Client Fireteam advances its own Interaction in parallel")
	_assert(_has_partial_progress(client_states, "parallel_terminal_alpha", host_fireteam) and _has_partial_progress(client_states, "parallel_terminal_bravo", client_fireteam), "Client snapshot mirrors both parallel owners and progress values")
	_assert(Array(client_sim.get("command_queue")).is_empty() and Array(client_sim.get("effects_queue")).is_empty(), "Parallel snapshot apply creates no client commands or effects")
	var same_owner_spoof: Dictionary = client_command.duplicate(true)
	same_owner_spoof["command_type"] = "defend"
	same_owner_spoof["target_position"] = Vector2(777.0, 777.0)
	same_owner_spoof["duration_seconds"] = 0.0
	client_sim.rpc_id(1, "request_command", same_owner_spoof)
	await _poll(host_api, client_api, 20)
	var canonical_client_result: Dictionary = _last_result_for("parallel_terminal_bravo")
	_assert(bool(canonical_client_result.get("accepted", false)) and String(canonical_client_result.get("command_type", "")) == "take", "Client result confirms canonical command type instead of spoofed Same-Fireteam payload")

	var rebound_peer_id: int = client_peer_id + 100
	var hold_before_rebind: float = float(Dictionary(Dictionary(Dictionary(host_driver.call("get_pending_network_mission_interaction_snapshot")).get("entries", {})).get("parallel_terminal_bravo", {})).get("hold_seconds", 0.0))
	host_sim.call("set_peer_team_assignments", {1: "team_alpha", rebound_peer_id: "team_alpha"})
	host_sim.call("set_peer_role_assignments", {1: "host", rebound_peer_id: "commander"})
	host_sim.call("set_peer_fireteam_assignments", {1: [host_fireteam], rebound_peer_id: [client_fireteam]})
	var rebound_command: Dictionary = client_command.duplicate(true)
	rebound_command["target_position"] = Vector2(999.0, 999.0)
	rebound_command["duration_seconds"] = 0.0
	rebound_command["interaction_radius_world"] = 9999.0
	var rebound_result: Dictionary = Dictionary(host_sim.call("submit_network_command_for_peer", rebound_command, rebound_peer_id))
	pending = Dictionary(host_driver.call("get_pending_network_mission_interaction_snapshot"))
	_assert(bool(rebound_result.get("accepted", false)), "Rebound peer may continue the same Fireteam Interaction")
	_assert(_pending_owner(pending, "parallel_terminal_bravo") == client_fireteam, "Peer-ID rebind preserves Fireteam-based Interaction ownership")
	var hold_after_rebind: float = float(Dictionary(Dictionary(pending.get("entries", {})).get("parallel_terminal_bravo", {})).get("hold_seconds", 0.0))
	_assert(hold_after_rebind + 0.001 >= hold_before_rebind, "Peer-ID rebind does not reset existing Interaction hold progress")
	var rebound_pending: Dictionary = Dictionary(Dictionary(pending.get("entries", {})).get("parallel_terminal_bravo", {}))
	_assert(Vector2(rebound_pending.get("target_position", Vector2.ZERO)).is_equal_approx(target_b), "Same-Fireteam resend cannot rewrite accepted Interaction target")
	_assert(is_equal_approx(float(rebound_pending.get("duration_seconds", 0.0)), 120.0) and is_equal_approx(float(rebound_pending.get("radius_world", 0.0)), 72.0), "Same-Fireteam resend cannot rewrite accepted duration or radius")
	var accepted_rebound_command: Dictionary = _last_host_accepted_for("parallel_terminal_bravo")
	_assert(Vector2(accepted_rebound_command.get("target_position", Vector2.ZERO)).is_equal_approx(target_b), "Accepted signal exposes canonical Same-Fireteam target")
	_assert(is_equal_approx(float(accepted_rebound_command.get("duration_seconds", 0.0)), 120.0) and is_equal_approx(float(accepted_rebound_command.get("interaction_radius_world", 0.0)), 72.0), "Accepted signal exposes canonical Same-Fireteam duration and radius")
	var queued_rebound_command: Dictionary = _last_queued_for(host_sim, "parallel_terminal_bravo")
	_assert(Vector2(queued_rebound_command.get("target_position", Vector2.ZERO)).is_equal_approx(target_b) and is_equal_approx(float(queued_rebound_command.get("duration_seconds", 0.0)), 120.0), "Command queue receives canonical Same-Fireteam payload")

	var non_interaction_probe: Dictionary = host_command.duplicate(true)
	non_interaction_probe["source_context"] = "task_1102_non_interaction_probe"
	var validation_started_usec: int = Time.get_ticks_usec()
	var normal_validation_count: int = 0
	for _index in range(2000):
		if bool(Dictionary(host_sim.call("validate_network_command_for_peer", non_interaction_probe, 1)).get("accepted", false)):
			normal_validation_count += 1
	var validation_elapsed_usec: int = Time.get_ticks_usec() - validation_started_usec
	_assert(normal_validation_count == 2000, "Preflight leaves unrelated valid network commands unchanged")
	_assert(validation_elapsed_usec < 250000, "Preflight keeps 2000 unrelated command validations below 250 ms")
	host_sim.call("clear_network_command_preflight_validator")
	_assert(bool(Dictionary(host_sim.call("validate_network_command_for_peer", non_interaction_probe, 1)).get("accepted", false)), "SimulationRoot preserves base validation when no preflight is registered")

	_cleanup(pair, host_root, client_root)
	await process_frame


func _build_command(interaction_id: String, fireteam_id: String, unit_id: String, target: Vector2, duration: float) -> Dictionary:
	return Dictionary(INTERACTION_COMMAND.build_network_command({
		"accepted": true,
		"interaction_id": interaction_id,
		"interaction_type": "computer",
		"command_type": "take",
		"required_order": "take",
		"duration_seconds": duration,
		"interaction_radius_world": 72.0,
		"fireteam_id": fireteam_id,
		"target_position": target,
		"step_id": interaction_id,
		"gate_id": interaction_id,
		"required_state": interaction_id + "_complete",
	}, unit_id, "team_alpha", target))


func _configure_assignments(simulation: Node, client_peer_id: int, host_fireteam: String, client_fireteam: String) -> void:
	simulation.set("is_server_authoritative", true)
	simulation.call("set_peer_team_assignments", {1: "team_alpha", client_peer_id: "team_alpha"})
	simulation.call("set_peer_role_assignments", {1: "host", client_peer_id: "commander"})
	simulation.call("set_peer_fireteam_assignments", {1: [host_fireteam], client_peer_id: [client_fireteam]})


func _find_unit(scene: Node, fireteam_id: String) -> Node2D:
	for child in scene.get_children():
		if child is Node2D and child.has_method("get_unit_id") and child.has_method("get_fireteam_id") and String(child.call("get_fireteam_id")).strip_edges().to_lower() == fireteam_id:
			return child as Node2D
	return null


func _pending_owner(snapshot: Dictionary, interaction_id: String) -> String:
	return String(Dictionary(Dictionary(snapshot.get("entries", {})).get(interaction_id, {})).get("fireteam_id", "")).strip_edges().to_lower()


func _has_partial_progress(states: Dictionary, interaction_id: String, fireteam_id: String) -> bool:
	var state: Dictionary = Dictionary(states.get(interaction_id, {}))
	return String(state.get("fireteam_id", "")) == fireteam_id and float(state.get("progress", 0.0)) > 0.0 and float(state.get("progress", 0.0)) < 1.0


func _on_client_result(result: Dictionary) -> void:
	_client_results.append(result.duplicate(true))


func _on_host_command_accepted(command: Dictionary, _peer_id: int) -> void:
	_host_accepted_commands.append(command.duplicate(true))


func _last_result_for(interaction_id: String) -> Dictionary:
	for index in range(_client_results.size() - 1, -1, -1):
		var result: Dictionary = Dictionary(_client_results[index])
		if String(result.get("interaction_id", "")) == interaction_id:
			return result
	return {}


func _last_host_accepted_for(interaction_id: String) -> Dictionary:
	for index in range(_host_accepted_commands.size() - 1, -1, -1):
		var command: Dictionary = Dictionary(_host_accepted_commands[index])
		if String(command.get("interaction_id", "")) == interaction_id:
			return command
	return {}


func _last_queued_for(simulation: Node, interaction_id: String) -> Dictionary:
	var queue: Array = Array(simulation.get("command_queue"))
	for index in range(queue.size() - 1, -1, -1):
		var command: Dictionary = Dictionary(queue[index])
		if String(command.get("interaction_id", "")) == interaction_id:
			return command
	return {}


func _create_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 2) != OK:
			continue
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
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


func _poll(host_api: MultiplayerAPI, client_api: MultiplayerAPI, count: int) -> void:
	for _index in range(count):
		host_api.poll()
		client_api.poll()
		await process_frame


func _cleanup(pair: Dictionary, host_root: Node, client_root: Node) -> void:
	client_root.queue_free()
	host_root.queue_free()
	(pair["client_peer"] as ENetMultiplayerPeer).close()
	(pair["host_peer"] as ENetMultiplayerPeer).close()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
