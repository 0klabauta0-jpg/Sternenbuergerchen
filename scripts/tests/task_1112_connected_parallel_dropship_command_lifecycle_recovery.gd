extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const ENET_PORT_START := 19740
const ENET_PORT_END := 19750

var _passed := 0
var _failed := 0
var _committed_command_ids := PackedStringArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1112 Connected Parallel Dropship Command Lifecycle and Recovery ===")
	var fixture: Dictionary = await _create_connected_triple()
	_assert(bool(fixture.get("connected", false)), "Host and two clients connect for parallel Dropship lifecycle")
	if not bool(fixture.get("connected", false)):
		quit(1)
		return
	var apis: Array = fixture["apis"]
	var missions: Array = fixture["missions"]
	var host_mission: Node = missions[0]
	var blue_mission: Node = missions[1]
	var gold_mission: Node = missions[2]
	var host_controller: Node = host_mission.get_node("TacticalController")
	var blue_controller: Node = blue_mission.get_node("TacticalController")
	var gold_controller: Node = gold_mission.get_node("TacticalController")
	var host_simulation: Node = host_mission.get_node("SimulationRoot")
	var blue_simulation: Node = blue_mission.get_node("SimulationRoot")
	var gold_simulation: Node = gold_mission.get_node("SimulationRoot")
	var blue_peer_id: int = (apis[1] as MultiplayerAPI).get_unique_id()
	var gold_peer_id: int = (apis[2] as MultiplayerAPI).get_unique_id()

	for index in range(missions.size()):
		var controller: Node = (missions[index] as Node).get_node("TacticalController")
		var blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
		var gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
		controller.call("set_planning_state", _build_two_craft_state(controller, blue_ids, gold_ids))
	host_controller.call("_refresh_world_overlays")
	host_simulation.set("is_server_authoritative", true)
	blue_simulation.set("is_server_authoritative", true)
	gold_simulation.set("is_server_authoritative", true)
	host_simulation.call("set_peer_team", 1, "team_alpha")
	host_simulation.call("set_peer_role", 1, "host")
	host_simulation.call("set_peer_fireteams", 1, [])
	_configure_peer(host_simulation, blue_peer_id, "blue")
	_configure_peer(host_simulation, gold_peer_id, "gold")
	if host_simulation.has_signal("dropship_command_committed"):
		host_simulation.connect("dropship_command_committed", Callable(self, "_on_dropship_command_committed"))
	await _poll_all(apis, 10)

	var blue_command: Dictionary = _command("parallel-blue-lz", "dropship_blue", "blue", Vector2(384.0, 192.0), "NW")
	var gold_command: Dictionary = _command("parallel-gold-lz", "dropship_gold", "gold", Vector2(704.0, 352.0), "SE")
	blue_simulation.rpc_id(1, "request_command", blue_command)
	gold_simulation.rpc_id(1, "request_command", gold_command)
	await _poll_all(apis, 40)
	_assert(_card_has_lz(host_controller, "dropship_blue", Vector2(384.0, 192.0)), "Host commits Blue parallel LZ")
	_assert(_card_has_lz(host_controller, "dropship_gold", Vector2(704.0, 352.0)), "Host commits Gold parallel LZ")
	_assert(_card_has_lz(blue_controller, "dropship_blue", Vector2(384.0, 192.0)) and _card_has_lz(blue_controller, "dropship_gold", Vector2(704.0, 352.0)), "Blue client converges on both parallel craft states")
	_assert(_card_has_lz(gold_controller, "dropship_blue", Vector2(384.0, 192.0)) and _card_has_lz(gold_controller, "dropship_gold", Vector2(704.0, 352.0)), "Gold client converges on both parallel craft states")

	var duplicate_command: Dictionary = _command("duplicate-blue-lz", "dropship_blue", "blue", Vector2(448.0, 224.0), "NE")
	blue_simulation.rpc_id(1, "request_command", duplicate_command)
	blue_simulation.rpc_id(1, "request_command", duplicate_command)
	await _poll_all(apis, 24)
	_assert(_committed_command_ids.count("duplicate-blue-lz") == 1, "Duplicate Dropship command ID commits exactly once")
	_assert(host_simulation.has_method("get_network_command_dedupe_debug_snapshot"), "SimulationRoot exposes bounded command dedupe diagnostics")
	if host_simulation.has_method("get_network_command_dedupe_debug_snapshot"):
		var dedupe_debug: Dictionary = Dictionary(host_simulation.call("get_network_command_dedupe_debug_snapshot"))
		_assert(int(dedupe_debug.get("dedupe_hit_count", 0)) >= 1, "Duplicate request records a dedupe hit")
		_assert(int(dedupe_debug.get("cached_id_count", 99999)) <= int(dedupe_debug.get("max_cached_ids", 0)), "Command dedupe cache remains bounded")

	var gold_before_disconnect: Dictionary = _card_by_id(host_controller, "dropship_gold")
	(apis[2] as MultiplayerAPI).multiplayer_peer.close()
	await _poll_all([apis[0], apis[1]], 18)
	_assert(_card_by_id(host_controller, "dropship_gold") == gold_before_disconnect, "Gold craft state survives Gold peer disconnect")
	host_simulation.call("set_peer_fireteams", blue_peer_id, ["blue", "gold"])
	var blue_before_rebind: Dictionary = _card_by_id(host_controller, "dropship_blue")
	var rebound_gold_command: Dictionary = _command("rebound-gold-approach", "dropship_gold", "gold", Vector2.ZERO, "SW", "set_dropship_approach")
	blue_simulation.rpc_id(1, "request_command", rebound_gold_command)
	await _poll_all([apis[0], apis[1]], 20)
	_assert(String(_card_by_id(host_controller, "dropship_gold").get("approach_angle", "")) == "SW", "Rebound client may continue Gold craft commands")
	_assert(_card_by_id(host_controller, "dropship_blue") == blue_before_rebind, "Gold recovery command leaves Blue craft unchanged")
	for index in range(2100):
		host_simulation.call("_register_accepted_network_dropship_command_id", "bounded-probe-%d" % index)
	var bounded_debug: Dictionary = Dictionary(host_simulation.call("get_network_command_dedupe_debug_snapshot"))
	_assert(int(bounded_debug.get("cached_id_count", 0)) == int(bounded_debug.get("max_cached_ids", -1)), "Dedupe cache evicts old IDs at its hard limit")

	_cleanup(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _on_dropship_command_committed(command: Dictionary) -> void:
	var command_id: String = String(command.get("command_id", "")).strip_edges()
	if not command_id.is_empty():
		_committed_command_ids.append(command_id)


func _configure_peer(simulation: Node, peer_id: int, fireteam_id: String) -> void:
	simulation.call("set_peer_team", peer_id, "team_alpha")
	simulation.call("set_peer_role", peer_id, "commander")
	simulation.call("set_peer_fireteams", peer_id, [fireteam_id])


func _command(command_id: String, craft_id: String, fireteam_id: String, lz_position: Vector2, approach: String, command_type: String = "set_lz") -> Dictionary:
	var command: Dictionary = {
		"contract_category": "dropship_command",
		"command_type": command_type,
		"command_id": command_id,
		"team_id": "team_alpha",
		"fireteam_id": fireteam_id,
		"craft_id": craft_id,
		"source_context": "mission_dropship_ui",
		"approach_angle": approach,
	}
	if command_type == "set_lz":
		command["lz_position"] = lz_position
	return command


func _build_two_craft_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "waiting"
	state["has_lz_position"] = false
	state["embarked_unit_ids"] = blue_ids + gold_ids
	state["deployed_unit_ids"] = []
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		_card("dropship_blue", "blue", blue_ids),
		_card("dropship_gold", "gold", gold_ids),
	]
	return state


func _card(craft_id: String, fireteam_id: String, payload: Array) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": craft_id.replace("_", " ").capitalize(),
		"state": "waiting",
		"progress": 0.0,
		"passenger_count": payload.size(),
		"embarked_unit_ids": payload.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"has_lz_position": false,
		"approach_angle": "NW",
	}


func _card_has_lz(controller: Node, craft_id: String, expected_position: Vector2) -> bool:
	var card: Dictionary = _card_by_id(controller, craft_id)
	return bool(card.get("has_lz_position", false)) and Vector2(card.get("lz_position", Vector2.ZERO)) == expected_position


func _card_by_id(controller: Node, craft_id: String) -> Dictionary:
	for card_variant in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if typeof(card_variant) == TYPE_DICTIONARY and String(Dictionary(card_variant).get("craft_id", "")) == craft_id:
			return Dictionary(card_variant).duplicate(true)
	return {}


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _create_connected_triple() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var missions: Array = []
		for index in range(3):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1112Peer%d" % index
			root.add_child(local_root)
			set_multiplayer(api, local_root.get_path())
			var mission: Node = MISSION_SCENE.instantiate()
			mission.name = "Mission"
			local_root.add_child(mission)
			roots.append(local_root)
			apis.append(api)
			missions.append(mission)
		await _poll_all(apis, 4)
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 3) != OK:
			_cleanup({"roots": roots, "apis": apis})
			continue
		(apis[0] as MultiplayerAPI).multiplayer_peer = host_peer
		var connected := true
		for client_index in [1, 2]:
			var client_peer := ENetMultiplayerPeer.new()
			if client_peer.create_client("127.0.0.1", port) != OK:
				connected = false
				break
			(apis[client_index] as MultiplayerAPI).multiplayer_peer = client_peer
		if not connected:
			_cleanup({"roots": roots, "apis": apis})
			continue
		for _index in range(240):
			await _poll_all(apis, 1)
			if (apis[1] as MultiplayerAPI).multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and (apis[2] as MultiplayerAPI).multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {"connected": true, "roots": roots, "apis": apis, "missions": missions}
		_cleanup({"roots": roots, "apis": apis})
	return {"connected": false}


func _poll_all(apis: Array, frames: int) -> void:
	for _index in range(frames):
		for api_variant in apis:
			(api_variant as MultiplayerAPI).poll()
		await process_frame


func _cleanup(fixture: Dictionary) -> void:
	for api_variant in Array(fixture.get("apis", [])):
		var api := api_variant as MultiplayerAPI
		if api != null and api.multiplayer_peer != null:
			api.multiplayer_peer.close()
	for root_variant in Array(fixture.get("roots", [])):
		var local_root := root_variant as Node
		if local_root != null and is_instance_valid(local_root):
			local_root.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
