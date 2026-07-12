extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const ENET_PORT_START := 19780
const ENET_PORT_END := 19790

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1115 Connected Parallel Dropship Drop Deboard Return Playthrough ===")
	var fixture: Dictionary = await _create_connected_triple()
	_assert(bool(fixture.get("connected", false)), "Host and two clients connect for full parallel Dropship playthrough")
	if not bool(fixture.get("connected", false)):
		quit(1)
		return
	var apis: Array = fixture["apis"]
	var missions: Array = fixture["missions"]
	var host_controller: Node = (missions[0] as Node).get_node("TacticalController")
	var blue_controller: Node = (missions[1] as Node).get_node("TacticalController")
	var gold_controller: Node = (missions[2] as Node).get_node("TacticalController")
	var host_simulation: Node = (missions[0] as Node).get_node("SimulationRoot")
	var blue_simulation: Node = (missions[1] as Node).get_node("SimulationRoot")
	var gold_simulation: Node = (missions[2] as Node).get_node("SimulationRoot")
	var blue_peer_id: int = (apis[1] as MultiplayerAPI).get_unique_id()
	var gold_peer_id: int = (apis[2] as MultiplayerAPI).get_unique_id()
	var blue_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "blue", true)))
	var gold_ids: Array = _unit_ids(Array(host_controller.call("_get_fireteam_units", "gold", true)))
	_assert(not blue_ids.is_empty() and not gold_ids.is_empty(), "Fixture exposes separate Blue and Gold payloads")
	for mission_variant in missions:
		var mission: Node = mission_variant as Node
		var controller: Node = mission.get_node("TacticalController")
		var local_blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
		var local_gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
		controller.call("set_planning_state", _build_two_craft_state(controller, local_blue_ids, local_gold_ids))
		controller.call("_refresh_world_overlays")
	var simulations: Array = [host_simulation, blue_simulation, gold_simulation]
	for simulation_variant in simulations:
		(simulation_variant as Node).set("is_server_authoritative", true)
	_configure_peer(host_simulation, 1, ["blue", "gold"], "host")
	_configure_peer(host_simulation, blue_peer_id, ["blue"], "commander")
	_configure_peer(host_simulation, gold_peer_id, ["gold"], "commander")
	blue_controller.call("_select_mission_dropship_craft", "dropship_blue", false)
	blue_controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	gold_controller.call("_select_mission_dropship_craft", "dropship_gold", false)
	gold_controller.call("_set_selected_fireteams", PackedStringArray(["gold"]), false)
	await _poll_all(apis, 10)
	var blue_effects_before: int = Array(blue_simulation.get("effects_queue")).size()
	var gold_effects_before: int = Array(gold_simulation.get("effects_queue")).size()

	var blue_lz := Vector2(384.0, 224.0)
	var gold_lz := Vector2(704.0, 384.0)
	_assert(bool(blue_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_blue", "blue", {"lz_position": blue_lz, "approach_angle": "NW"})), "Blue client sends its LZ")
	_assert(bool(gold_controller.call("request_network_authoritative_dropship_command", "set_lz", "dropship_gold", "gold", {"lz_position": gold_lz, "approach_angle": "SE"})), "Gold client sends its LZ")
	await _poll_all(apis, 24)
	_assert(_card_has_lz(host_controller, "dropship_blue", blue_lz) and _card_has_lz(host_controller, "dropship_gold", gold_lz), "Host commits both independent LZs")
	_assert(int(Dictionary(blue_controller.call("get_network_dropship_pending_debug_snapshot")).get("pending_count", -1)) == 0 and int(Dictionary(gold_controller.call("get_network_dropship_pending_debug_snapshot")).get("pending_count", -1)) == 0, "Both clients clear LZ Pending through authoritative snapshots")

	_assert(bool(blue_controller.call("request_network_authoritative_dropship_command", "call_dropship", "dropship_blue", "blue")), "Blue client requests its Drop")
	_assert(bool(gold_controller.call("request_network_authoritative_dropship_command", "call_dropship", "dropship_gold", "gold")), "Gold client requests its Drop")
	await _poll_all(apis, 24)
	var blue_started: Dictionary = _card_by_id(host_controller, "dropship_blue")
	var gold_started: Dictionary = _card_by_id(host_controller, "dropship_gold")
	_assert(_is_live_drop_state(String(blue_started.get("state", ""))) and _is_live_drop_state(String(gold_started.get("state", ""))), "Host starts two independent live Drop sequences")

	for _step in range(8):
		host_controller.call("_update_drop_sequence", 20.0)
		await _poll_all(apis, 1)
		var state: Dictionary = Dictionary(host_controller.call("get_planning_state"))
		if Array(state.get("embarked_unit_ids", [])).is_empty() and _both_cards_rtb(host_controller):
			break
	await _poll_all(apis, 24)

	var expected_deployed: Array = blue_ids + gold_ids
	expected_deployed.sort()
	for index in range(3):
		var controller: Node = (missions[index] as Node).get_node("TacticalController")
		var state: Dictionary = Dictionary(controller.call("get_planning_state"))
		var deployed: Array = Array(state.get("deployed_unit_ids", []))
		deployed.sort()
		_assert(Array(state.get("embarked_unit_ids", [])).is_empty(), "Peer %d sees no stale embarked payload after Deboarding" % index)
		_assert(deployed == expected_deployed, "Peer %d converges on all Blue and Gold deployed units" % index)
		_assert(_card_payload_empty(controller, "dropship_blue") and _card_payload_empty(controller, "dropship_gold"), "Peer %d keeps both craft payloads empty after separate unload" % index)
		_assert(_both_cards_rtb(controller), "Peer %d sees both Dropships independently returning to FOB" % index)

	_assert(String(Dictionary(blue_controller.call("get_planning_state")).get("mission_drop_craft_id", "")) == "dropship_blue" and Array(Dictionary(blue_controller.call("get_planning_state")).get("selected_fireteams", [])).has("blue"), "Blue client keeps local Blue craft and Fireteam focus")
	_assert(String(Dictionary(gold_controller.call("get_planning_state")).get("mission_drop_craft_id", "")) == "dropship_gold" and Array(Dictionary(gold_controller.call("get_planning_state")).get("selected_fireteams", [])).has("gold"), "Gold client keeps local Gold craft and Fireteam focus")
	_assert(Array(blue_simulation.get("command_queue")).is_empty() and Array(gold_simulation.get("command_queue")).is_empty(), "Client snapshot application leaves no local command queue work")
	_assert(Array(blue_simulation.get("effects_queue")).size() == blue_effects_before and Array(gold_simulation.get("effects_queue")).size() == gold_effects_before, "Client snapshot application creates no additional local effect queue work")

	_cleanup(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _configure_peer(simulation: Node, peer_id: int, fireteams: Array, role: String) -> void:
	simulation.call("set_peer_team", peer_id, "team_alpha")
	simulation.call("set_peer_role", peer_id, role)
	simulation.call("set_peer_fireteams", peer_id, fireteams)


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


func _card_by_id(controller: Node, craft_id: String) -> Dictionary:
	for card_variant in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if typeof(card_variant) == TYPE_DICTIONARY and String(Dictionary(card_variant).get("craft_id", "")) == craft_id:
			return Dictionary(card_variant).duplicate(true)
	return {}


func _card_has_lz(controller: Node, craft_id: String, position: Vector2) -> bool:
	var card: Dictionary = _card_by_id(controller, craft_id)
	return bool(card.get("has_lz_position", false)) and Vector2(card.get("lz_position", Vector2.ZERO)).is_equal_approx(position)


func _card_payload_empty(controller: Node, craft_id: String) -> bool:
	return Array(_card_by_id(controller, craft_id).get("embarked_unit_ids", [])).is_empty()


func _both_cards_rtb(controller: Node) -> bool:
	return String(_card_by_id(controller, "dropship_blue").get("state", "")).begins_with("to_") and String(_card_by_id(controller, "dropship_gold").get("state", "")).begins_with("to_")


func _is_live_drop_state(state: String) -> bool:
	return ["inbound", "landed", "unloading", "complete", "outbound"].has(state.strip_edges().to_lower())


func _create_connected_triple() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var missions: Array = []
		for index in range(3):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1115Peer%d" % index
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
