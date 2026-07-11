extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const ENET_PORT_START := 19760
const ENET_PORT_END := 19770

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1113 Connected Dropship Pending Feedback and Double-Submit Guard ===")
	var fixture: Dictionary = await _create_connected_pair()
	_assert(bool(fixture.get("connected", false)), "Host and client connect for per-Craft Pending guard")
	if not bool(fixture.get("connected", false)):
		quit(1)
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
	for mission_variant in missions:
		var controller: Node = (mission_variant as Node).get_node("TacticalController")
		var blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
		var gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
		controller.call("set_planning_state", _build_two_craft_state(controller, blue_ids, gold_ids))
	host_controller.call("_refresh_world_overlays")
	host_simulation.set("is_server_authoritative", true)
	client_simulation.set("is_server_authoritative", true)
	host_simulation.call("set_peer_team", 1, "team_alpha")
	host_simulation.call("set_peer_role", 1, "host")
	host_simulation.call("set_peer_fireteams", 1, [])
	host_simulation.call("set_peer_team", client_peer_id, "team_alpha")
	host_simulation.call("set_peer_role", client_peer_id, "commander")
	host_simulation.call("set_peer_fireteams", client_peer_id, ["blue", "gold"])
	await _poll_all(apis, 8)

	_assert(client_controller.has_method("get_network_dropship_pending_debug_snapshot"), "Controller exposes read-only per-Craft Pending diagnostics")
	var blue_first: bool = bool(client_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_blue", "blue", {"lz_position": Vector2(400.0, 200.0), "approach_angle": "NW"}))
	var pending_after_first: Dictionary = _pending_debug(client_controller)
	_assert(blue_first and int(pending_after_first.get("pending_count", 0)) == 1, "First Blue request creates one Pending entry")
	var blue_command_id: String = String(Dictionary(pending_after_first.get("entries", {})).get("dropship_blue", {}).get("command_id", ""))
	var blue_second: bool = bool(client_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_blue", "blue", {"lz_position": Vector2(420.0, 210.0), "approach_angle": "NE"}))
	var pending_after_second: Dictionary = _pending_debug(client_controller)
	_assert(not blue_second, "Second Blue request is blocked before another RPC")
	_assert(String(Dictionary(pending_after_second.get("entries", {})).get("dropship_blue", {}).get("command_id", "")) == blue_command_id, "Blocked double-submit preserves original Command ID")
	_assert(_all_card_commands_disabled(client_controller, "dropship_blue"), "Blue card commands are disabled while Blue is Pending")
	_assert(not _all_card_commands_disabled(client_controller, "dropship_gold"), "Gold card remains independently operable")

	var gold_sent: bool = bool(client_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_gold", "gold", {"lz_position": Vector2(720.0, 360.0), "approach_angle": "SE"}))
	_assert(gold_sent and int(_pending_debug(client_controller).get("pending_count", 0)) == 2, "Gold request may run parallel to Blue Pending")
	await _poll_all(apis, 36)
	_assert(int(_pending_debug(client_controller).get("pending_count", -1)) == 0, "Matching authoritative snapshots clear both accepted Pending entries")
	_assert(_card_has_lz(client_controller, "dropship_blue", Vector2(400.0, 200.0)) and _card_has_lz(client_controller, "dropship_gold", Vector2(720.0, 360.0)), "Client cards show both committed LZ results")

	host_simulation.call("set_peer_fireteams", client_peer_id, ["blue"])
	var rejected_sent: bool = bool(client_controller.call("request_network_authoritative_dropship_command", "set_dropship_approach", "dropship_gold", "gold", {"approach_angle": "SW"}))
	_assert(rejected_sent and int(_pending_debug(client_controller).get("pending_count", 0)) == 1, "Rejected Gold request starts Pending until host answer")
	await _poll_all(apis, 18)
	_assert(int(_pending_debug(client_controller).get("pending_count", -1)) == 0, "Host reject releases Gold Pending immediately")
	_assert(String(client_controller.get("_last_command_text")).contains("BLOCKIERT"), "Reject leaves readable blocked feedback")

	var timeout_sent: bool = bool(client_controller.call("request_network_authoritative_dropship_command", "set_dropship_approach", "dropship_blue", "blue", {"approach_angle": "SW"}))
	_assert(timeout_sent, "Blue timeout probe starts Pending")
	client_controller.call("_advance_network_dropship_pending", 20.0)
	_assert(int(_pending_debug(client_controller).get("pending_count", -1)) == 0, "Pending timeout releases craft without host poll")
	_assert(String(client_controller.get("_last_command_text")).contains("HOST TIMEOUT"), "Timeout leaves readable host-timeout feedback")

	_cleanup(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _pending_debug(controller: Node) -> Dictionary:
	if not controller.has_method("get_network_dropship_pending_debug_snapshot"):
		return {}
	return Dictionary(controller.call("get_network_dropship_pending_debug_snapshot"))


func _all_card_commands_disabled(controller: Node, craft_id: String) -> bool:
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_dropship_card_ui_snapshot", craft_id))
	var commands: Dictionary = Dictionary(snapshot.get("commands", {}))
	if commands.is_empty():
		return false
	for command_variant in commands.values():
		if not bool(Dictionary(command_variant).get("disabled", false)):
			return false
	return true


func _card_has_lz(controller: Node, craft_id: String, expected_position: Vector2) -> bool:
	for card_variant in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if typeof(card_variant) != TYPE_DICTIONARY:
			continue
		var card: Dictionary = Dictionary(card_variant)
		if String(card.get("craft_id", "")) == craft_id:
			return bool(card.get("has_lz_position", false)) and Vector2(card.get("lz_position", Vector2.ZERO)) == expected_position
	return false


func _build_two_craft_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "waiting"
	state["has_lz_position"] = false
	state["embarked_unit_ids"] = blue_ids + gold_ids
	state["deployed_unit_ids"] = []
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [_card("dropship_blue", "blue", blue_ids), _card("dropship_gold", "gold", gold_ids)]
	return state


func _card(craft_id: String, fireteam_id: String, payload: Array) -> Dictionary:
	return {"craft_id": craft_id, "display_name": craft_id.replace("_", " ").capitalize(), "state": "waiting", "progress": 0.0, "passenger_count": payload.size(), "embarked_unit_ids": payload.duplicate(), "boarded_fireteam_ids": [fireteam_id], "has_lz_position": false, "approach_angle": "NW"}


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _create_connected_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var missions: Array = []
		for index in range(2):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1113Peer%d" % index
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
			_cleanup({"roots": roots, "apis": apis})
			continue
		(apis[0] as MultiplayerAPI).multiplayer_peer = host_peer
		var client_peer := ENetMultiplayerPeer.new()
		if client_peer.create_client("127.0.0.1", port) != OK:
			_cleanup({"roots": roots, "apis": apis})
			continue
		(apis[1] as MultiplayerAPI).multiplayer_peer = client_peer
		for _index in range(180):
			await _poll_all(apis, 1)
			if (apis[1] as MultiplayerAPI).multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
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
