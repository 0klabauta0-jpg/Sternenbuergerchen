extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const ENET_PORT_START: int = 19428
const ENET_PORT_END: int = 19438

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1083 Two-Instance ROE Ownership Playtest ===")
	await _test_real_rpc_roe_commit_replication_and_reject_feedback()
	await _test_unordered_chunk_reassembly()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_real_rpc_roe_commit_replication_and_reject_feedback() -> void:
	var pair: Dictionary = await _create_multiplayer_api_pair()
	_assert(bool(pair.get("connected", false)), "Local ENet pair connects for the ROE playtest")
	if not bool(pair.get("connected", false)):
		return
	var host_api: MultiplayerAPI = pair["host_api"]
	var client_api: MultiplayerAPI = pair["client_api"]
	var client_peer_id: int = client_api.get_unique_id()
	var host_peer: ENetMultiplayerPeer = pair["host_peer"]
	var client_peer: ENetMultiplayerPeer = pair["client_peer"]

	var host_root := Node.new()
	host_root.name = "Task1083Host"
	root.add_child(host_root)
	var client_root := Node.new()
	client_root.name = "Task1083Client"
	root.add_child(client_root)
	set_multiplayer(host_api, host_root.get_path())
	set_multiplayer(client_api, client_root.get_path())

	var host_scene: Node = MISSION_TEST_SCENE.instantiate()
	host_scene.name = "Mission"
	var client_scene: Node = MISSION_TEST_SCENE.instantiate()
	client_scene.name = "Mission"
	host_root.add_child(host_scene)
	client_root.add_child(client_scene)
	await _poll_pair(host_api, client_api, 12)

	var host_simulation := host_scene.get_node_or_null("SimulationRoot")
	var client_simulation := client_scene.get_node_or_null("SimulationRoot")
	var host_controller := host_scene.get_node_or_null("TacticalController")
	var client_controller := client_scene.get_node_or_null("TacticalController")
	_assert(host_simulation != null and client_simulation != null and host_controller != null and client_controller != null, "Both network mission instances expose SimulationRoot and controller")
	if host_simulation == null or client_simulation == null or host_controller == null or client_controller == null:
		_close_pair(host_peer, client_peer)
		return

	_configure_authority(host_simulation, client_peer_id)
	_configure_authority(client_simulation, client_peer_id)
	var host_accept_before: int = int(Dictionary(host_simulation.call("get_network_command_contract_snapshot")).get("accepted_count", 0))
	var request_started: bool = bool(client_controller.call("set_fireteams_fire_rule", PackedStringArray(["red"]), "return"))
	_assert(request_started, "Client Fire-Rule setter sends the assigned Fireteam request")
	_assert(String(client_controller.call("get_fireteam_fire_rule", "red")) != "return", "Client does not mutate ROE before host commit")
	await _poll_pair(host_api, client_api, 20)
	var host_accept_after_rpc: int = int(Dictionary(host_simulation.call("get_network_command_contract_snapshot")).get("accepted_count", 0))
	_assert(host_accept_after_rpc > host_accept_before, "Real client RPC reaches host validation and command processing")
	host_simulation.call("_physics_process", 0.016)
	await _poll_pair(host_api, client_api, 24)
	var host_state: Dictionary = Dictionary(host_simulation.call("get_authoritative_fire_rule_state", "red"))
	var client_sync: Dictionary = Dictionary(client_controller.call("get_fire_rule_authority_sync_snapshot"))
	var host_transport: Dictionary = Dictionary(host_simulation.call("get_snapshot_transport_debug_snapshot"))
	var client_transport: Dictionary = Dictionary(client_simulation.call("get_snapshot_transport_debug_snapshot"))
	var accepted_feedback: Dictionary = Dictionary(client_controller.call("get_fire_rule_authority_feedback_snapshot"))
	print("TASK_1083 transport: raw=%d wire=%d chunks=%d pack=%dus reassembly=%dus" % [
		int(host_transport.get("last_raw_bytes", 0)),
		int(host_transport.get("last_wire_bytes", 0)),
		int(host_transport.get("last_chunk_count", 0)),
		int(host_transport.get("last_pack_usec", 0)),
		int(client_transport.get("last_reassembly_usec", 0)),
	])
	_assert(String(host_state.get("fire_rule", "")) == "return" and int(host_state.get("revision", 0)) == 1, "Host tick commits the requested ROE revision")
	_assert(String(client_controller.call("get_fireteam_fire_rule", "red")) == "return", "Client mirrors the committed host ROE")
	_assert(int(Dictionary(client_sync.get("revisions", {})).get("red", 0)) == 1, "Client mirrors the host ROE revision")
	_assert(Array(client_simulation.get("command_queue")).is_empty(), "Client snapshot apply creates no gameplay command")
	_assert(int(host_transport.get("last_max_chunk_payload_bytes", 999999)) <= 1000, "Host keeps each unreliable snapshot chunk below the transport payload budget")
	_assert(int(host_transport.get("last_chunk_count", 0)) > 1, "Large mission snapshot is packetized instead of sent as one oversized unreliable RPC")
	_assert(int(client_transport.get("reassembled_snapshot_count", 0)) >= 1, "Client reassembles and applies the packetized host snapshot")
	_assert(int(client_transport.get("reassembly_failure_count", 1)) == 0, "Client packetized snapshot path reports no reassembly failure")
	_assert(int(host_transport.get("last_wire_bytes", 999999)) < int(host_transport.get("last_raw_bytes", 0)), "Snapshot transport compresses the full mission state before chunking")
	_assert(int(host_transport.get("last_pack_usec", 999999)) < 50000, "Snapshot compression and packetization stay below the broad 50 ms hotpath guard")
	_assert(int(client_transport.get("last_reassembly_usec", 999999)) < 50000, "Snapshot reassembly and decode stay below the broad 50 ms client guard")
	_assert(String(accepted_feedback.get("status", "")) == "accepted" and String(accepted_feedback.get("compact_line", "")).contains("HOST OK"), "Client receives compact host acceptance feedback")

	var rejected_request_started: bool = bool(client_controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), "free"))
	_assert(rejected_request_started, "Client can send a request that still needs host ownership validation")
	await _poll_pair(host_api, client_api, 24)
	var result_snapshot: Dictionary = Dictionary(client_simulation.call("get_last_network_command_result"))
	var feedback: Dictionary = Dictionary(client_controller.call("get_fire_rule_authority_feedback_snapshot"))
	_assert(not bool(result_snapshot.get("accepted", true)) and String(result_snapshot.get("reason", "")) == "fireteam_not_assigned_to_peer", "Wrong-Fireteam request returns the host rejection to the client")
	_assert(String(feedback.get("status", "")) == "blocked" and String(feedback.get("compact_line", "")).contains("ROE BLOCKED"), "Client controller exposes compact ROE ownership feedback")
	_assert(String(host_simulation.call("get_authoritative_fire_rule_state", "blue").get("fire_rule", "")) == "", "Rejected request creates no host ROE state")

	_close_pair(host_peer, client_peer)
	host_root.queue_free()
	client_root.queue_free()
	await process_frame


func _configure_authority(simulation_root: Node, client_peer_id: int) -> void:
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team_assignments", {1: "team_alpha", client_peer_id: "team_alpha"})
	simulation_root.call("set_peer_role", 1, "host")
	simulation_root.call("set_peer_role", client_peer_id, "fireteam")
	simulation_root.call("set_peer_fireteam_assignments", {
		1: PackedStringArray(["blue"]),
		client_peer_id: PackedStringArray(["red"]),
	})


func _test_unordered_chunk_reassembly() -> void:
	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "Task1083UnorderedClient"
	root.add_child(simulation_root)
	var snapshot: Dictionary = {
		"schema_version": 1,
		"snapshot_type": "state",
		"transfer_mode": "unreliable",
		"tick": 91,
		"units": [],
		"contacts": [{"fireteam_id": "red", "unit_id": "enemy_1", "team_id": "team_bravo", "detection_state": "spotted"}],
	}
	var raw_bytes: PackedByteArray = var_to_bytes(snapshot)
	var compressed_bytes: PackedByteArray = raw_bytes.compress(FileAccess.COMPRESSION_ZSTD)
	var use_compression: bool = compressed_bytes.size() < raw_bytes.size()
	var wire_bytes: PackedByteArray = compressed_bytes if use_compression else raw_bytes
	var chunk_size: int = 40
	var chunk_count: int = maxi(ceili(float(wire_bytes.size()) / float(chunk_size)), 1)
	for chunk_index in range(chunk_count - 1, -1, -1):
		var start_offset: int = chunk_index * chunk_size
		var end_offset: int = mini(start_offset + chunk_size, wire_bytes.size())
		simulation_root.call("_receive_tick_state_chunk", 91, chunk_index, chunk_count, raw_bytes.size(), use_compression, wire_bytes.slice(start_offset, end_offset))
	var transport: Dictionary = Dictionary(simulation_root.call("get_snapshot_transport_debug_snapshot"))
	var last_state: Dictionary = Dictionary(simulation_root.call("get_last_server_state"))
	_assert(int(last_state.get("tick", -1)) == 91, "Client reassembles deliberately reversed snapshot chunks")
	_assert(int(transport.get("reassembled_snapshot_count", 0)) == 1 and int(transport.get("reassembly_failure_count", 1)) == 0, "Unordered chunk delivery completes without transport failure")
	_assert(int(transport.get("pending_tick_count", 1)) == 0, "Completed unordered tick leaves no pending chunk buffer")
	simulation_root.queue_free()
	await process_frame


func _create_multiplayer_api_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 2) != OK:
			host_peer.close()
			continue
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
			client_peer.close()
			host_peer.close()
			continue
		var host_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		host_api.multiplayer_peer = host_peer
		client_api.multiplayer_peer = client_peer
		for _index in range(180):
			host_api.poll()
			client_api.poll()
			if client_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {
					"connected": true,
					"port": port,
					"host_api": host_api,
					"client_api": client_api,
					"host_peer": host_peer,
					"client_peer": client_peer,
				}
			await process_frame
		client_peer.close()
		host_peer.close()
	return {"connected": false}


func _poll_pair(host_api: MultiplayerAPI, client_api: MultiplayerAPI, frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		host_api.poll()
		client_api.poll()
		await process_frame


func _close_pair(host_peer: ENetMultiplayerPeer, client_peer: ENetMultiplayerPeer) -> void:
	client_peer.close()
	host_peer.close()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
