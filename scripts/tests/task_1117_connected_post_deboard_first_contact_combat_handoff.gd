extends SceneTree

const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const ENET_PORT_START := 19820
const ENET_PORT_END := 19830

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== TASK_1117 Connected Post-Deboard First Contact Combat Handoff ===")
	var fixture: Dictionary = await _create_connected_triple()
	_assert(bool(fixture.get("connected", false)), "Host and two clients connect for first-contact handoff")
	if not bool(fixture.get("connected", false)):
		quit(1)
		return
	var apis: Array = fixture["apis"]
	var missions: Array = fixture["missions"]
	var host_simulation: Node = (missions[0] as Node).get_node("SimulationRoot")
	var blue_simulation: Node = (missions[1] as Node).get_node("SimulationRoot")
	var gold_simulation: Node = (missions[2] as Node).get_node("SimulationRoot")
	var blue_controller: Node = (missions[1] as Node).get_node("TacticalController")
	var gold_controller: Node = (missions[2] as Node).get_node("TacticalController")
	var blue_driver: Node = (missions[1] as Node).get_node("CombatLoopDriver")
	var gold_driver: Node = (missions[2] as Node).get_node("CombatLoopDriver")
	var host_driver: Node = (missions[0] as Node).get_node("CombatLoopDriver")
	var host_controller: Node = (missions[0] as Node).get_node("TacticalController")
	for simulation_variant in [host_simulation, blue_simulation, gold_simulation]:
		(simulation_variant as Node).set("is_server_authoritative", true)
	for mission_variant in missions:
		var controller: Node = (mission_variant as Node).get_node("TacticalController")
		var blue_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "blue", true)))
		var gold_ids: Array = _unit_ids(Array(controller.call("_get_fireteam_units", "gold", true)))
		controller.call("set_planning_state", _build_deboarded_state(controller, blue_ids, gold_ids))
		controller.call("_apply_drop_presence_state_to_units")
	_prepare_parallel_live_contacts(host_controller)
	host_controller.call("_apply_fireteams_fire_rule_locally", PackedStringArray(["blue", "gold"]), "free", true)
	_assert(bool(host_controller.call("_apply_default_fireteam_behavior", "blue", 1)), "Host activates Blue contact behavior")
	_assert(bool(host_controller.call("_apply_default_fireteam_behavior", "gold", 1)), "Host activates Gold contact behavior")
	for simulation_variant in [host_simulation, blue_simulation, gold_simulation]:
		(simulation_variant as Node).process_mode = Node.PROCESS_MODE_INHERIT
	for _index in range(240):
		await _poll_all(apis, 1)
		if _has_fireteam_contact(Array(host_driver.call("get_contact_snapshot")), "blue") and _has_fireteam_contact(Array(host_driver.call("get_contact_snapshot")), "gold") and not Array(host_driver.call("get_fire_event_snapshot")).is_empty():
			break
	var authority_debug: Dictionary = {
		"blue_runs": bool(blue_driver.get("_runs_local_authority")),
		"gold_runs": bool(gold_driver.get("_runs_local_authority")),
		"blue_peer": blue_driver.multiplayer.get_unique_id(),
		"gold_peer": gold_driver.multiplayer.get_unique_id(),
		"blue_connected": blue_driver.multiplayer.multiplayer_peer.get_connection_status() if blue_driver.multiplayer.multiplayer_peer != null else -1,
		"gold_connected": gold_driver.multiplayer.multiplayer_peer.get_connection_status() if gold_driver.multiplayer.multiplayer_peer != null else -1,
	}
	_assert(not bool(blue_driver.get("_runs_local_authority")) and not bool(gold_driver.get("_runs_local_authority")), "Connected clients do not run local combat: %s" % JSON.stringify(authority_debug))
	var live_host_contacts: Array = Array(host_driver.call("get_contact_snapshot"))
	var live_host_events: Array = Array(host_driver.call("get_fire_event_snapshot"))
	var live_blue_events: Array = Array(blue_controller.call("get_fire_event_snapshot"))
	var live_gold_events: Array = Array(gold_controller.call("get_fire_event_snapshot"))
	_assert(_has_fireteam_contact(live_host_contacts, "blue") and _has_fireteam_contact(live_host_contacts, "gold"), "Host detects real post-Deboard contacts for Blue and Gold")
	_assert(not live_host_events.is_empty(), "Host produces a real first-fire event")
	var live_event_id: String = String(Dictionary(live_host_events[0]).get("event_id", "")) if not live_host_events.is_empty() else ""
	_assert(not live_event_id.is_empty() and _has_event(live_blue_events, live_event_id) and _has_event(live_gold_events, live_event_id), "Both clients receive the Host's real first-fire event")
	var live_target_id: String = String(Dictionary(live_host_events[0]).get("target_unit_id", "")) if not live_host_events.is_empty() else ""
	var host_target: Node = _find_unit(missions[0] as Node, live_target_id)
	var blue_target: Node = _find_unit(missions[1] as Node, live_target_id)
	var gold_target: Node = _find_unit(missions[2] as Node, live_target_id)
	for _index in range(90):
		if host_target != null and blue_target != null and gold_target != null and _health(host_target) == _health(blue_target) and _health(host_target) == _health(gold_target):
			break
		await _poll_all(apis, 1)
	var vital_debug: Dictionary = {
		"host": _health(host_target),
		"blue": _health(blue_target),
		"gold": _health(gold_target),
		"blue_wire": _snapshot_health(Dictionary(blue_simulation.get("_last_server_state")), live_target_id),
		"gold_wire": _snapshot_health(Dictionary(gold_simulation.get("_last_server_state")), live_target_id),
		"target": live_target_id,
	}
	_assert(host_target != null and blue_target != null and gold_target != null and _health(host_target) == _health(blue_target) and _health(host_target) == _health(gold_target), "Real combat target Vitalstatus agrees on Host, Blue and Gold: %s" % JSON.stringify(vital_debug))

	var contacts: Array = [
		_contact("blue", "enemy_alpha", Vector2(960.0, 540.0)),
		_contact("gold", "enemy_alpha", Vector2(960.0, 540.0)),
	]
	var fire_event: Dictionary = {
		"event_id": "task1117:first_fire:1",
		"attacker_unit_id": "blue_lead",
		"attacker_fireteam_id": "blue",
		"target_unit_id": "enemy_alpha",
		"attacker_team_id": "team_alpha",
		"target_team_id": "team_enemy",
		"result": "hit",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}
	var blue_commands_before: int = Array(blue_simulation.get("command_queue")).size()
	var gold_commands_before: int = Array(gold_simulation.get("command_queue")).size()
	var blue_effects_before: int = Array(blue_simulation.get("effects_queue")).size()
	var gold_effects_before: int = Array(gold_simulation.get("effects_queue")).size()
	var host_tick_callback := Callable(host_driver, "_on_tick_processed")
	if host_simulation.is_connected("tick_processed", host_tick_callback):
		host_simulation.disconnect("tick_processed", host_tick_callback)
	host_simulation.call("set_multiplayer_snapshot_context", {"contacts": contacts, "fire_events": [fire_event]})
	await _poll_all(apis, 30)
	var snapshot_debug: Dictionary = {
		"host_tick": int(host_simulation.get("tick_counter")),
		"blue_tick": int(blue_simulation.get("tick_counter")),
		"gold_tick": int(gold_simulation.get("tick_counter")),
		"blue_snapshot": blue_simulation.call("get_multiplayer_snapshot_debug_snapshot"),
		"gold_snapshot": gold_simulation.call("get_multiplayer_snapshot_debug_snapshot"),
	}
	_assert(int(Dictionary(snapshot_debug.get("blue_snapshot", {})).get("apply_count", 0)) > 0 and int(Dictionary(snapshot_debug.get("gold_snapshot", {})).get("apply_count", 0)) > 0 and int(Dictionary(snapshot_debug.get("blue_snapshot", {})).get("missing_unit_count", 1)) == 0 and int(Dictionary(snapshot_debug.get("gold_snapshot", {})).get("missing_unit_count", 1)) == 0, "Both clients apply complete combat snapshots without missing units")

	var blue_contacts: Array = Array(blue_controller.call("get_fireteam_contact_snapshot", "blue"))
	var gold_contacts: Array = Array(gold_controller.call("get_fireteam_contact_snapshot", "gold"))
	var blue_events: Array = Array(blue_controller.call("get_fire_event_snapshot"))
	var gold_events: Array = Array(gold_controller.call("get_fire_event_snapshot"))
	var blue_diagnostics: Dictionary = Dictionary(blue_controller.call("get_contact_decision_diagnostics_snapshot"))
	var gold_diagnostics: Dictionary = Dictionary(gold_controller.call("get_contact_decision_diagnostics_snapshot"))
	_assert(blue_contacts.size() == 1 and String(Dictionary(blue_contacts[0]).get("unit_id", "")) == "enemy_alpha", "Blue reads its Host contact from the normal snapshot")
	_assert(gold_contacts.size() == 1 and String(Dictionary(gold_contacts[0]).get("unit_id", "")) == "enemy_alpha", "Gold reads its Host contact from the normal snapshot")
	_assert(_has_event(blue_events, "task1117:first_fire:1") and _has_event(gold_events, "task1117:first_fire:1"), "Both clients read the same authoritative first-fire event")
	_assert(String(blue_diagnostics.get("fire_event_id", "")) == "task1117:first_fire:1" and String(gold_diagnostics.get("fire_event_id", "")) == "task1117:first_fire:1" and bool(blue_diagnostics.get("read_only", false)) and bool(gold_diagnostics.get("read_only", false)), "Client combat diagnostics are rebuilt from authoritative read-only First Fire")
	_assert(Array(blue_simulation.get("command_queue")).size() == blue_commands_before and Array(gold_simulation.get("command_queue")).size() == gold_commands_before, "Combat snapshot creates no client commands")
	_assert(Array(blue_simulation.get("effects_queue")).size() == blue_effects_before and Array(gold_simulation.get("effects_queue")).size() == gold_effects_before, "Combat snapshot creates no client effects")

	_cleanup(fixture)
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _contact(fireteam_id: String, unit_id: String, position: Vector2) -> Dictionary:
	return {
		"fireteam_id": fireteam_id,
		"unit_id": unit_id,
		"team_id": "team_enemy",
		"enemy_type": "rifleman",
		"last_known_position": position,
		"approximate_position": position,
		"detection_state": "confirmed",
		"report_state": "current",
		"confidence": 0.92,
		"detected_by": [fireteam_id],
		"last_seen_tick": 1,
		"report_text": "1 contact, rifleman, last seen now, 92% conf",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_deboarded_state(controller: Node, blue_ids: Array, gold_ids: Array) -> Dictionary:
	var state: Dictionary = Dictionary(controller.call("get_planning_state"))
	state["mission_drop_craft_id"] = "dropship_blue"
	state["mission_drop_state"] = "to_fob"
	state["embarked_unit_ids"] = []
	state["deployed_unit_ids"] = blue_ids + gold_ids
	state["selected_fireteams"] = ["blue"]
	state["mission_drop_cards"] = [
		{"craft_id": "dropship_blue", "state": "to_fob", "embarked_unit_ids": [], "boarded_fireteam_ids": ["blue"]},
		{"craft_id": "dropship_gold", "state": "to_fob", "embarked_unit_ids": [], "boarded_fireteam_ids": ["gold"]},
	]
	return state


func _unit_ids(units: Array) -> Array:
	var result: Array = []
	for unit in units:
		if unit != null and unit.has_method("get_unit_id"):
			result.append(String(unit.call("get_unit_id")))
	return result


func _prepare_parallel_live_contacts(controller: Node) -> void:
	var enemies: Array = Array(controller.call("_get_all_enemy_units", true))
	if enemies.size() < 2:
		return
	var blue_center := Vector2(120.0, 130.0)
	var gold_center := Vector2(120.0, 212.0)
	_place_fireteam(controller, "blue", blue_center)
	_place_fireteam(controller, "gold", gold_center)
	(enemies[0] as Node2D).global_position = Vector2(220.0, 130.0)
	(enemies[1] as Node2D).global_position = Vector2(228.0, 212.0)


func _place_fireteam(controller: Node, fireteam_id: String, center: Vector2) -> void:
	var units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(0.0, 32.0), Vector2(-32.0, 0.0), Vector2(-32.0, 32.0)]
	for index in range(mini(units.size(), offsets.size())):
		if units[index] is Node2D:
			(units[index] as Node2D).global_position = center + offsets[index]


func _has_event(events: Array, event_id: String) -> bool:
	for event_variant in events:
		if typeof(event_variant) == TYPE_DICTIONARY and String(Dictionary(event_variant).get("event_id", "")) == event_id:
			return true
	return false


func _has_fireteam_contact(contacts: Array, fireteam_id: String) -> bool:
	for contact_variant in contacts:
		if typeof(contact_variant) == TYPE_DICTIONARY and String(Dictionary(contact_variant).get("fireteam_id", "")).strip_edges().to_lower() == fireteam_id:
			return true
	return false


func _find_unit(mission: Node, unit_id: String) -> Node:
	if unit_id.is_empty():
		return null
	for child in mission.get_children():
		if child != null and child.has_method("get_unit_id") and String(child.call("get_unit_id")) == unit_id:
			return child
	return null


func _health(unit: Node) -> int:
	return int(unit.call("get_health")) if unit != null and unit.has_method("get_health") else -1


func _snapshot_health(snapshot: Dictionary, unit_id: String) -> int:
	for unit_variant in Array(snapshot.get("units", [])):
		if typeof(unit_variant) == TYPE_DICTIONARY and String(Dictionary(unit_variant).get("unit_id", "")) == unit_id:
			return int(Dictionary(unit_variant).get("health", -1))
	return -1


func _create_connected_triple() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var roots: Array = []
		var apis: Array = []
		var missions: Array = []
		for index in range(3):
			var api := MultiplayerAPI.create_default_interface()
			var local_root := Node.new()
			local_root.name = "Task1117Peer%d" % index
			root.add_child(local_root)
			set_multiplayer(api, local_root.get_path())
			var mission: Node = MISSION_SCENE.instantiate()
			mission.name = "Mission"
			local_root.add_child(mission)
			mission.get_node("SimulationRoot").process_mode = Node.PROCESS_MODE_DISABLED
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
