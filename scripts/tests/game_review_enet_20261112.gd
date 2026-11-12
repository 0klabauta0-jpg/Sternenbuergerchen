extends "res://scripts/tests/game_review_combat_20261112_parity.gd"

var host_damage_signals: int = 0
var client_damage_signals: int = 0

func _run() -> void:
	var host: Dictionary = _context("EnetHost", true)
	var client: Dictionary = _context("EnetClient", true)
	var host_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
	var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
	set_multiplayer(host_api, host.owner.get_path())
	set_multiplayer(client_api, client.owner.get_path())
	var server_peer := ENetMultiplayerPeer.new()
	var client_peer := ENetMultiplayerPeer.new()
	var port_used: int = -1
	for port in range(19930, 19940):
		if server_peer.create_server(port, 2) == OK:
			port_used = port
			break
	check(port_used >= 0, "Real ENet server binds an available local fixture port")
	if port_used >= 0:
		host_api.multiplayer_peer = server_peer
		var connection_error: Error = client_peer.create_client("127.0.0.1", port_used)
		check(connection_error == OK, "Real ENet client accepts local connection")
		if connection_error == OK:
			client_api.multiplayer_peer = client_peer
			for _index in range(200):
				await _poll_apis(host_api, client_api)
				if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and host_api.get_peers().size() == 1:
					break
			var connected: bool = client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and host_api.get_peers().size() == 1
			check(connected and not client_api.is_server(), "Subtrees have a genuinely connected Host and non-authority Client")
			if connected:
				await _exercise_pair(host, client, host_api, client_api)
	client_peer.close()
	server_peer.close()
	host.owner.free()
	client.owner.free()
	await process_frame
	print("GAME_REVIEW_ENET: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _exercise_pair(host: Dictionary, client: Dictionary, host_api: MultiplayerAPI, client_api: MultiplayerAPI) -> void:
	host.target.damage_applied.connect(func(_amount, _health, _context): host_damage_signals += 1)
	client.target.damage_applied.connect(func(_amount, _health, _context): client_damage_signals += 1)
	var initial_health: int = client.target.get_health()
	var effect: Dictionary = {
		"effect_type": "damage", "unit_id": "target", "attacker_unit_id": "attacker",
		"attacker_team_id": "team_alpha", "damage": 3, "hit_chance": 0.95,
		"weapon_id": "rifle", "target_cover_override": 0.0,
	}
	# Even an accidentally queued local effect must not run on a connected client.
	client.sim.call("enqueue_effect", effect.duplicate(true))
	client.sim.call("_physics_process", 0.016)
	check(int(client.sim.call("get_tick")) == 0 and client.target.get_health() == initial_health, "Connected client skips local tick and accidentally queued damage")
	for shot in range(8):
		var shot_effect: Dictionary = effect.duplicate(true)
		shot_effect["fire_event_id"] = "enet_review_%d" % shot
		host.sim.call("enqueue_effect", shot_effect)
		host.sim.call("_physics_process", 0.016)
		var expected_tick: int = int(host.sim.call("get_tick"))
		var received_tick: int = -1
		for _frame in range(200):
			await _poll_apis(host_api, client_api)
			received_tick = int(Dictionary(client.sim.call("get_last_server_state")).get("tick", -1))
			if received_tick == expected_tick:
				break
		check(received_tick == expected_tick, "Host tick %d travels through real SimulationRoot chunk RPC and client reassembly" % expected_tick)
		check(client.target.get_health() == host.target.get_health(), "RPC snapshot %d mirrors authoritative health" % expected_tick)
		client.sim.call("_physics_process", 0.016)
		check(int(client.sim.call("get_tick")) == 0 and client.target.get_health() == host.target.get_health(), "Client tick attempt %d cannot commit or double-apply damage" % expected_tick)
	check(host_damage_signals > 0 and client_damage_signals == 0, "Only Host executed apply_damage; Client used remote vital projection")
	check(client.sim.command_queue.is_empty() and client.sim.effects_queue.size() == 1, "RPC snapshots added no client commands/effects and local effect stayed unprocessed")
	var reference_rng := RandomNumberGenerator.new()
	reference_rng.seed = 1729
	check(float(client.sim.call("get_next_combat_roll")) == reference_rng.randf(), "Connected client tick attempts and RPC snapshots consumed no combat RNG")

func _poll_apis(host_api: MultiplayerAPI, client_api: MultiplayerAPI) -> void:
	host_api.poll()
	client_api.poll()
	await create_timer(0.005).timeout
