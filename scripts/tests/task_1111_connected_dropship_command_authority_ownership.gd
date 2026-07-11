extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const ENET_PORT_START := 19720
const ENET_PORT_END := 19730

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1111 Connected Dropship Command Authority and Ownership ===")
	var mission: Node = MISSION_SCENE.instantiate()
	root.add_child(mission)
	await _wait_frames(6)
	var controller: Node = mission.get_node("TacticalController")
	var simulation: Node = mission.get_node("SimulationRoot")
	var blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
	var gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
	controller.call("set_planning_state", _build_two_craft_state(controller, blue_ids, gold_ids))
	controller.call("_refresh_world_overlays")
	await _wait_frames(4)

	simulation.set("is_server_authoritative", true)
	simulation.call("set_peer_team", 2, "team_alpha")
	simulation.call("set_peer_role", 2, "commander")
	simulation.call("set_peer_fireteams", 2, ["blue"])
	simulation.call("set_peer_team", 3, "team_alpha")
	simulation.call("set_peer_role", 3, "spectator")

	var missing_craft: Dictionary = Dictionary(simulation.call("validate_network_command_for_peer", _command("call_dropship", "", "blue"), 2))
	var missing_fireteam: Dictionary = Dictionary(simulation.call("validate_network_command_for_peer", _command("call_dropship", "dropship_blue", ""), 2))
	var foreign_craft: Dictionary = Dictionary(simulation.call("validate_network_command_for_peer", _command("call_dropship", "dropship_gold", "blue"), 2))
	var spectator: Dictionary = Dictionary(simulation.call("validate_network_command_for_peer", _command("call_dropship", "dropship_blue", "blue"), 3))
	var invalid_approach: Dictionary = Dictionary(simulation.call("validate_network_command_for_peer", _command("set_dropship_approach", "dropship_blue", "blue", {"approach_angle": "SIDEWAYS"}), 2))
	_assert(String(missing_craft.get("reason", "")) == "dropship_command_missing_craft", "Dropship command requires a craft ID")
	_assert(String(missing_fireteam.get("reason", "")) == "dropship_command_missing_fireteam", "Dropship command requires a Fireteam ID")
	_assert(String(foreign_craft.get("reason", "")) == "dropship_not_assigned_to_fireteam", "Blue peer cannot command Gold craft")
	_assert(String(spectator.get("reason", "")) == "spectator_cannot_command", "Spectator cannot command a Dropship")
	_assert(String(invalid_approach.get("reason", "")) == "dropship_approach_invalid", "Unknown Dropship approach is rejected")

	var initial_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	var set_lz_command: Dictionary = _command("set_lz", "dropship_blue", "blue")
	set_lz_command["lz_position"] = Vector2(416.0, 224.0)
	set_lz_command["approach_angle"] = "SE"
	var set_lz_result: Dictionary = Dictionary(simulation.call("submit_network_command_for_peer", set_lz_command, 2))
	_assert(bool(set_lz_result.get("accepted", false)), "Owning Blue peer may submit Blue LZ command")
	_assert(not bool(Dictionary(controller.call("get_planning_state")).get("has_lz_position", false)), "Accepted request does not mutate LZ before authority tick")
	_assert(simulation.has_signal("dropship_command_committed"), "SimulationRoot exposes authoritative Dropship commit signal")
	if simulation.has_signal("dropship_command_committed"):
		simulation.call("_process_commands", [Dictionary(set_lz_result.get("command", set_lz_command))], 0.016)
		await _wait_frames(4)
		var lz_state: Dictionary = Dictionary(controller.call("get_planning_state"))
		_assert(bool(lz_state.get("has_lz_position", false)) and Vector2(lz_state.get("lz_position", Vector2.ZERO)) == Vector2(416.0, 224.0), "Committed LZ command mutates authoritative Blue craft")
		_assert(String(lz_state.get("approach_angle", "")) == "SE", "Committed LZ command carries approach angle")

	var approach_result: Dictionary = Dictionary(simulation.call("submit_network_command_for_peer", _command("set_dropship_approach", "dropship_blue", "blue", {"approach_angle": "NE"}), 2))
	_assert(bool(approach_result.get("accepted", false)), "Owning peer may submit approach command")
	_assert(String(Dictionary(controller.call("get_planning_state")).get("approach_angle", "")) == "SE", "Approach request does not mutate before authority commit")
	simulation.call("_process_commands", [Dictionary(approach_result.get("command", {}))], 0.016)
	await _wait_frames(2)
	_assert(String(Dictionary(controller.call("get_planning_state")).get("approach_angle", "")) == "NE", "Committed approach command updates authoritative craft")
	var clear_result: Dictionary = Dictionary(simulation.call("submit_network_command_for_peer", _command("clear_lz", "dropship_blue", "blue"), 2))
	_assert(bool(clear_result.get("accepted", false)), "Owning peer may submit Clear LZ command")
	simulation.call("_process_commands", [Dictionary(clear_result.get("command", {}))], 0.016)
	await _wait_frames(2)
	_assert(not bool(Dictionary(controller.call("get_planning_state")).get("has_lz_position", true)), "Committed Clear LZ command removes authoritative LZ")

	var return_result: Dictionary = Dictionary(simulation.call("submit_network_command_for_peer", _command("return_dropship", "dropship_blue", "blue"), 2))
	_assert(bool(return_result.get("accepted", false)), "Return Dropship command is whitelisted for owner")
	_assert(String(Dictionary(controller.call("get_planning_state")).get("mission_drop_state", "")) == "waiting", "Return request does not mutate before authority commit")
	simulation.call("_process_commands", [Dictionary(return_result.get("command", {}))], 0.016)
	await _wait_frames(2)
	_assert(String(Dictionary(controller.call("get_planning_state")).get("mission_drop_state", "")).begins_with("to_"), "Committed Return command sends authoritative craft back")

	var call_state: Dictionary = _build_two_craft_state(controller, blue_ids, gold_ids)
	call_state["has_lz_position"] = true
	call_state["lz_position"] = Vector2(416.0, 224.0)
	call_state["mission_drop_cards"][0]["has_lz_position"] = true
	call_state["mission_drop_cards"][0]["lz_position"] = Vector2(416.0, 224.0)
	controller.call("set_planning_state", call_state)
	controller.call("_refresh_world_overlays")
	var call_result: Dictionary = Dictionary(simulation.call("submit_network_command_for_peer", _command("call_dropship", "dropship_blue", "blue"), 2))
	_assert(bool(call_result.get("accepted", false)), "Owning peer may submit Drop command")
	_assert(not bool(Dictionary(controller.call("get_planning_state")).get("drop_ship_requested", false)), "Drop request does not start local sequence before authority commit")
	simulation.call("_process_commands", [Dictionary(call_result.get("command", {}))], 0.016)
	await _wait_frames(3)
	_assert(bool(Dictionary(controller.call("get_planning_state")).get("drop_ship_requested", false)), "Committed Drop command starts authoritative sequence")
	_assert(controller.has_method("request_network_authoritative_dropship_command"), "Mission controller exposes one network Dropship request path")
	_assert(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", []) == initial_state.get("mission_drop_cards", []) or not Array(controller.call("get_planning_state").get("mission_drop_cards", [])).is_empty(), "Authority setup keeps Dropship cards available")

	mission.queue_free()
	await process_frame
	await _test_connected_client_request_roundtrip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_connected_client_request_roundtrip() -> void:
	var fixture: Dictionary = await _create_connected_pair()
	_assert(bool(fixture.get("connected", false)), "Host and client connect for Dropship command roundtrip")
	if not bool(fixture.get("connected", false)):
		return
	var apis: Array = fixture["apis"]
	var missions: Array = fixture["missions"]
	var host_mission: Node = missions[0]
	var client_mission: Node = missions[1]
	var host_controller: Node = host_mission.get_node("TacticalController")
	var client_controller: Node = client_mission.get_node("TacticalController")
	var host_simulation: Node = host_mission.get_node("SimulationRoot")
	var client_simulation: Node = client_mission.get_node("SimulationRoot")
	var client_peer_id: int = (apis[1] as MultiplayerAPI).get_unique_id()
	var host_blue_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "blue", true)))
	var host_gold_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "gold", true)))
	var client_blue_ids: Array = _unit_ids(Array(client_controller.call("_get_fireteam_units", "blue", true)))
	var client_gold_ids: Array = _unit_ids(Array(client_controller.call("_get_fireteam_units", "gold", true)))
	host_controller.call("set_planning_state", _build_two_craft_state(host_controller, host_blue_ids, host_gold_ids))
	client_controller.call("set_planning_state", _build_two_craft_state(client_controller, client_blue_ids, client_gold_ids))
	host_controller.call("_refresh_world_overlays")
	host_simulation.set("is_server_authoritative", true)
	client_simulation.set("is_server_authoritative", true)
	host_simulation.call("set_peer_team", 1, "team_alpha")
	host_simulation.call("set_peer_role", 1, "host")
	host_simulation.call("set_peer_fireteams", 1, ["gold"])
	host_simulation.call("set_peer_team", client_peer_id, "team_alpha")
	host_simulation.call("set_peer_role", client_peer_id, "commander")
	host_simulation.call("set_peer_fireteams", client_peer_id, ["blue"])
	await _poll_all(apis, 8)

	var request_sent: bool = bool(client_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_blue", "blue", {"lz_position": Vector2(512.0, 256.0), "approach_angle": "SW"}))
	_assert(request_sent, "Connected client sends Blue LZ request to host")
	_assert(not bool(Dictionary(client_controller.call("get_planning_state")).get("has_lz_position", false)), "Connected client does not mutate LZ before host roundtrip")
	await _poll_all(apis, 36)
	var host_state: Dictionary = Dictionary(host_controller.call("get_planning_state"))
	var client_state: Dictionary = Dictionary(client_controller.call("get_planning_state"))
	_assert(bool(host_state.get("has_lz_position", false)) and Vector2(host_state.get("lz_position", Vector2.ZERO)) == Vector2(512.0, 256.0), "Host commits connected client LZ request")
	_assert(bool(client_state.get("has_lz_position", false)) and Vector2(client_state.get("lz_position", Vector2.ZERO)) == Vector2(512.0, 256.0), "Client converges on committed LZ through snapshot")

	var gold_before: Dictionary = _card_by_id(Array(host_state.get("mission_drop_cards", [])), "dropship_gold")
	client_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_gold", "blue", {"lz_position": Vector2(900.0, 900.0)})
	await _poll_all(apis, 18)
	var gold_after: Dictionary = _card_by_id(Array(Dictionary(host_controller.call("get_planning_state")).get("mission_drop_cards", [])), "dropship_gold")
	_assert(gold_after == gold_before, "Host rejects Blue peer mutation of Gold craft")
	_assert(String(client_controller.get("_last_command_text")).contains("BLOCKIERT"), "Client receives readable blocked Dropship feedback")
	_cleanup_connected_pair(fixture)
	await process_frame


func _create_connected_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var missions: Array = []
		for index in range(2):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1111Peer%d" % index
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
		if host_peer.create_server(port, 2) != OK:
			_cleanup_connected_pair({"roots": roots, "apis": apis})
			continue
		(apis[0] as MultiplayerAPI).multiplayer_peer = host_peer
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
			_cleanup_connected_pair({"roots": roots, "apis": apis})
			continue
		(apis[1] as MultiplayerAPI).multiplayer_peer = client_peer
		for _index in range(180):
			await _poll_all(apis, 1)
			if (apis[1] as MultiplayerAPI).multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				return {"connected": true, "roots": roots, "apis": apis, "missions": missions}
		_cleanup_connected_pair({"roots": roots, "apis": apis})
	return {"connected": false}


func _poll_all(apis: Array, frames: int) -> void:
	for _index in range(frames):
		for api_variant in apis:
			(api_variant as MultiplayerAPI).poll()
		await process_frame


func _cleanup_connected_pair(fixture: Dictionary) -> void:
	for api_variant in Array(fixture.get("apis", [])):
		var api := api_variant as MultiplayerAPI
		if api != null and api.multiplayer_peer != null:
			api.multiplayer_peer.close()
	for root_variant in Array(fixture.get("roots", [])):
		var local_root := root_variant as Node
		if local_root != null and is_instance_valid(local_root):
			local_root.queue_free()


func _card_by_id(cards: Array, craft_id: String) -> Dictionary:
	for card_variant in cards:
		if typeof(card_variant) == TYPE_DICTIONARY and String(Dictionary(card_variant).get("craft_id", "")) == craft_id:
			return Dictionary(card_variant).duplicate(true)
	return {}


func _build_two_craft_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "waiting"
	state["has_lz_position"] = false
	state["embarked_unit_ids"] = blue_ids + gold_ids
	state["deployed_unit_ids"] = []
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		_card("dropship_blue", "Blue Lift", "blue", blue_ids),
		_card("dropship_gold", "Gold Lift", "gold", gold_ids),
	]
	return state


func _card(craft_id: String, display_name: String, fireteam_id: String, payload: Array) -> Dictionary:
	return {
		"craft_id": craft_id,
		"display_name": display_name,
		"state": "waiting",
		"progress": 0.0,
		"passenger_count": payload.size(),
		"embarked_unit_ids": payload.duplicate(),
		"boarded_fireteam_ids": [fireteam_id],
		"has_lz_position": false,
		"approach_angle": "NW",
	}


func _command(command_type: String, craft_id: String, fireteam_id: String, extra: Dictionary = {}) -> Dictionary:
	var command: Dictionary = {
		"contract_category": "dropship_command",
		"command_type": command_type,
		"team_id": "team_alpha",
		"fireteam_id": fireteam_id,
		"craft_id": craft_id,
		"source_context": "mission_dropship_ui",
	}
	command.merge(extra, true)
	return command


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
