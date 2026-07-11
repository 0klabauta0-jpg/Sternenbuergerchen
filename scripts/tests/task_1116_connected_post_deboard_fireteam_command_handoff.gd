extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const ENET_PORT_START := 19800
const ENET_PORT_END := 19810

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1116 Connected Post-Deboard Fireteam Command Handoff ===")
	var fixture: Dictionary = await _create_connected_triple()
	_assert(bool(fixture.get("connected", false)), "Host and two clients connect for post-Deboard command handoff")
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
	for mission_variant in missions:
		var controller: Node = (mission_variant as Node).get_node("TacticalController")
		var blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
		var gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
		controller.call("set_planning_state", _build_deboarded_state(controller, blue_ids, gold_ids))
		controller.call("_apply_drop_presence_state_to_units")
	for simulation_variant in [host_simulation, blue_simulation, gold_simulation]:
		(simulation_variant as Node).set("is_server_authoritative", true)
	_configure_peer(host_simulation, 1, ["blue", "gold"], "host")
	_configure_peer(host_simulation, blue_peer_id, ["blue"], "commander")
	_configure_peer(host_simulation, gold_peer_id, ["gold"], "commander")
	blue_controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	gold_controller.call("_set_selected_fireteams", PackedStringArray(["gold"]), false)
	await _poll_all(apis, 12)
	_assert(bool(blue_controller.call("_is_fireteam_runtime_active", "blue")) and bool(gold_controller.call("_is_fireteam_runtime_active", "gold")), "Both clients see their Fireteams runtime-active after Deboarding")

	var blue_unit := _first_unit_for_fireteam(blue_controller, "blue") as Node2D
	var gold_unit := _first_unit_for_fireteam(gold_controller, "gold") as Node2D
	var blue_position_before: Vector2 = blue_unit.global_position if blue_unit != null else Vector2.ZERO
	var gold_position_before: Vector2 = gold_unit.global_position if gold_unit != null else Vector2.ZERO
	var blue_positions_before: Dictionary = _fireteam_positions(blue_controller, "blue")
	var gold_positions_before: Dictionary = _fireteam_positions(gold_controller, "gold")
	var blue_target: Vector2 = _resolve_walkable_target(missions[0] as Node, blue_position_before + Vector2(512.0, 160.0))
	var gold_target: Vector2 = _resolve_walkable_target(missions[0] as Node, gold_position_before + Vector2(-512.0, 160.0))
	_set_move_tile(blue_controller, blue_target)
	_set_move_tile(gold_controller, gold_target)
	_assert(bool(blue_controller.call("issue_move")), "Blue client plans a Move from its ground Fireteam")
	_assert(bool(gold_controller.call("issue_move")), "Gold client plans a Move from its ground Fireteam")
	var accepted_before: int = int(Dictionary(host_simulation.call("get_network_command_contract_snapshot")).get("accepted_count", 0))
	var blue_commands_before: int = Array(blue_simulation.get("command_queue")).size()
	var gold_commands_before: int = Array(gold_simulation.get("command_queue")).size()
	var blue_effects_before: int = Array(blue_simulation.get("effects_queue")).size()
	var gold_effects_before: int = Array(gold_simulation.get("effects_queue")).size()
	_assert(bool(blue_controller.call("execute_selected_fireteam_orders")), "Blue GO submits its planned Fireteam Intent")
	_assert(bool(gold_controller.call("execute_selected_fireteam_orders")), "Gold GO submits its planned Fireteam Intent")
	_assert(not bool(blue_controller.call("execute_selected_fireteam_orders")), "Blue double-GO is blocked while Host result is pending")
	await _poll_all(apis, 18)
	var accepted_after: int = int(Dictionary(host_simulation.call("get_network_command_contract_snapshot")).get("accepted_count", 0))
	_assert(accepted_after == accepted_before + 2, "Host accepts exactly one Blue and one Gold Fireteam Intent")
	_assert(Array(blue_simulation.get("command_queue")).size() == blue_commands_before and Array(gold_simulation.get("command_queue")).size() == gold_commands_before, "Client GO creates no local Gameplay commands")
	var movement_traces: Dictionary = Dictionary(host_controller.get("_recent_movement_trace_by_fireteam"))
	_assert(movement_traces.has("blue") and movement_traces.has("gold"), "Host starts both existing Fireteam movement paths")
	_assert(_any_fireteam_unit_moved(blue_controller, "blue", blue_positions_before), "Blue client receives moved ground position through Host snapshots")
	_assert(_any_fireteam_unit_moved(gold_controller, "gold", gold_positions_before), "Gold client receives moved ground position through Host snapshots")
	_assert(Array(blue_simulation.get("effects_queue")).size() == blue_effects_before and Array(gold_simulation.get("effects_queue")).size() == gold_effects_before, "Movement snapshots create no client Gameplay effects")
	var blue_feedback: Dictionary = Dictionary(blue_controller.call("get_network_fireteam_command_feedback_snapshot"))
	var gold_feedback: Dictionary = Dictionary(gold_controller.call("get_network_fireteam_command_feedback_snapshot"))
	_assert(String(blue_feedback.get("status", "")) == "accepted" and String(gold_feedback.get("status", "")) == "accepted", "Both clients receive readable Host-OK Fireteam feedback")

	var foreign_sent: bool = bool(blue_controller.call("request_network_authoritative_fireteam_intent", "gold", "defend", gold_target, 0))
	_assert(foreign_sent, "Blue client may send a foreign-ownership probe for Host validation")
	await _poll_all(apis, 14)
	var foreign_feedback: Dictionary = Dictionary(blue_controller.call("get_network_fireteam_command_feedback_snapshot"))
	_assert(String(foreign_feedback.get("status", "")) == "blocked" and String(foreign_feedback.get("compact_line", "")).contains("BLOCKIERT"), "Host rejects Blue command of Gold with readable feedback")

	_cleanup(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _set_move_tile(controller: Node, target: Vector2) -> void:
	controller.set("_has_selected_tile", true)
	controller.set("_selected_tile_world_position", target)


func _build_deboarded_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "to_fob"
	state["embarked_unit_ids"] = []
	state["deployed_unit_ids"] = blue_ids + gold_ids
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [_card("dropship_blue", "blue"), _card("dropship_gold", "gold")]
	return state


func _card(craft_id: String, fireteam_id: String) -> Dictionary:
	return {"craft_id": craft_id, "display_name": craft_id.replace("_", " ").capitalize(), "state": "to_fob", "progress": 100.0, "passenger_count": 0, "embarked_unit_ids": [], "boarded_fireteam_ids": [fireteam_id], "has_lz_position": true, "lz_position": Vector2(320.0, 200.0), "approach_angle": "NW"}


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _first_unit_for_fireteam(controller: Node, fireteam_id: String) -> Node:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		if unit is Node2D:
			return unit
	return null


func _resolve_walkable_target(mission: Node, requested: Vector2) -> Vector2:
	var terrain_registry := mission.get_node_or_null("TerrainRegistry")
	if terrain_registry != null and terrain_registry.has_method("resolve_walkable_target"):
		var result: Dictionary = Dictionary(terrain_registry.call("resolve_walkable_target", requested))
		return Vector2(result.get("replacement_position", requested))
	return requested


func _fireteam_positions(controller: Node, fireteam_id: String) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit != null and unit.has_method("get_unit_id"):
			result[String(unit.call("get_unit_id"))] = unit.global_position
	return result


func _any_fireteam_unit_moved(controller: Node, fireteam_id: String, before: Dictionary) -> bool:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node2D
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		if before.has(unit_id) and unit.global_position.distance_to(Vector2(before[unit_id])) > 1.0:
			return true
	return false


func _configure_peer(simulation: Node, peer_id: int, fireteams: Array, role: String) -> void:
	simulation.call("set_peer_team", peer_id, "team_alpha")
	simulation.call("set_peer_role", peer_id, role)
	simulation.call("set_peer_fireteams", peer_id, fireteams)


func _create_connected_triple() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var missions: Array = []
		for index in range(3):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1116Peer%d" % index
			root.add_child(local_root)
			set_multiplayer(api, local_root.get_path())
			var mission: Node = MISSION_SCENE.instantiate()
			mission.name = "Mission"
			local_root.add_child(mission)
			roots.append(local_root); apis.append(api); missions.append(mission)
		await _poll_all(apis, 4)
		var host_peer := ENetMultiplayerPeer.new()
		if host_peer.create_server(port, 3) != OK:
			_cleanup({"roots": roots, "apis": apis}); continue
		(apis[0] as MultiplayerAPI).multiplayer_peer = host_peer
		var connected := true
		for client_index in [1, 2]:
			var client_peer := ENetMultiplayerPeer.new()
			if client_peer.create_client("127.0.0.1", port) != OK:
				connected = false; break
			(apis[client_index] as MultiplayerAPI).multiplayer_peer = client_peer
		if not connected:
			_cleanup({"roots": roots, "apis": apis}); continue
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
		_passed += 1; print("PASS: %s" % message)
	else:
		_failed += 1; push_error("FAIL: %s" % message)
