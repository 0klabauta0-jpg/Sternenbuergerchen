extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_607_two_instance_host_client_runtime_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_556_TEST_PATH: String = "res://scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd"
const TASK_604_TEST_PATH: String = "res://scripts/tests/task_604_core_loop_host_client_feel_smoke.gd"
const TASK_606_TEST_PATH: String = "res://scripts/tests/task_606_host_client_f6_visual_polish_findings.gd"
const ENET_PORT_START: int = 19407
const ENET_PORT_END: int = 19417

const PEER_TEAMS: Dictionary = {
	1: "team_alpha",
	2: "team_bravo",
}
const PEER_ROLES: Dictionary = {
	1: "host",
	2: "fireteam",
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_607 Two Instance Host Client Runtime Smoke ===")
	_test_docs_and_wiring()
	await _test_two_instance_host_client_runtime_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_607: FAILED")
		quit(1)
		return
	print("TASK_607: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_607 task file exists")
	_assert(task_text.contains("Two Instance Host Client Runtime Smoke"), "TASK_607 task file names the task")
	_assert(status_text.contains("TASK_607 - Two Instance Host Client Runtime Smoke"), "Implementation status tracks TASK_607")
	_assert(roadmap_text.contains("TASK_607 - Two Instance Host Client Runtime Smoke (implementiert)"), "Roadmap marks TASK_607 implemented")
	_assert(roadmap_text.contains("TASK_608 - Host Client Runtime Visual Capture"), "Roadmap names TASK_608 follow-up")
	_assert(report_text.contains("TASK_607 Two Instance Host Client Runtime Smoke"), "Review workbench tracks TASK_607")
	_assert(report_text.contains("TASK_608 - Host Client Runtime Visual Capture"), "Review workbench names TASK_608 follow-up")
	_assert(report_text.contains("host_client_runtime.local_enet_connected"), "Review workbench exports local ENet result")
	_assert(report_text.contains("host_client_runtime.client_snapshot_apply"), "Review workbench exports client snapshot apply result")
	_assert(contract_text.contains("Two-Instance-Host-Client-Runtime-Smoke"), "Mission feedback contract documents TASK_607")
	_assert(FileAccess.file_exists(TASK_556_TEST_PATH), "TASK_556 handoff verifier remains available")
	_assert(FileAccess.file_exists(TASK_604_TEST_PATH), "TASK_604 host/client feel verifier remains available")
	_assert(FileAccess.file_exists(TASK_606_TEST_PATH), "TASK_606 F6 polish verifier remains available")


func _test_two_instance_host_client_runtime_smoke() -> void:
	var enet_result: Dictionary = await _connect_local_enet_pair()
	_assert(bool(enet_result.get("connected", false)), "Local ENet server/client pair connects for TASK_607")
	_assert(int(enet_result.get("port", 0)) >= ENET_PORT_START, "TASK_607 records the local ENet port")

	root.size = Vector2i(1920, 1080)
	var host_scene: Node = MISSION_TEST_SCENE.instantiate()
	host_scene.name = "Task607HostMission"
	var client_scene: Node = MISSION_TEST_SCENE.instantiate()
	client_scene.name = "Task607ClientMission"
	_configure_scene(host_scene)
	_configure_scene(client_scene)
	root.add_child(host_scene)
	root.add_child(client_scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var host_context: Dictionary = await _prepare_mission_instance(host_scene, "host")
	var client_context: Dictionary = await _prepare_mission_instance(client_scene, "client")
	_assert(not host_context.is_empty(), "TASK_607 host mission instance is prepared")
	_assert(not client_context.is_empty(), "TASK_607 client mission instance is prepared")
	if host_context.is_empty() or client_context.is_empty():
		host_scene.queue_free()
		client_scene.queue_free()
		await _wait_frames(2)
		return

	var host_simulation: Node = host_context["simulation_root"]
	var client_simulation: Node = client_context["simulation_root"]
	var host_controller: Node = host_context["controller"]
	var client_controller: Node = client_context["controller"]
	_register_runtime_probe_units(host_scene, host_simulation, "host")
	_register_runtime_probe_units(client_scene, client_simulation, "client")

	var accepted_bravo_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", _build_probe_move_command("task607_host_bravo", "team_bravo", "red", Vector2(96.0, 0.0)), 2))
	var rejected_alpha_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", _build_probe_move_command("task607_host_alpha", "team_alpha", "blue", Vector2(24.0, 0.0)), 2))
	var forbidden_state_command: Dictionary = _build_probe_move_command("task607_host_bravo", "team_bravo", "red", Vector2(128.0, 0.0))
	forbidden_state_command["damage"] = 99
	var rejected_state_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", forbidden_state_command, 2))
	var queue_after_accept: int = _get_simulation_command_queue_count(host_simulation)
	host_simulation.call("_physics_process", 0.35)
	var queue_after_process: int = _get_simulation_command_queue_count(host_simulation)

	host_simulation.call(
		"set_multiplayer_snapshot_context",
		{
			"dropship": {
				"visible": false,
				"state": "departed",
				"team_id": "team_alpha",
			},
			"mission_result": {
				"result": "in_progress",
				"winning_team_id": "",
				"friendly_team_id": "team_alpha",
				"win_condition_type": "frontier_probe_runtime_smoke",
				"objective_captured": false,
				"duration_seconds": 12.0,
			},
		}
	)
	var server_snapshot: Dictionary = Dictionary(host_simulation.call("build_multiplayer_snapshot"))
	var client_apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", server_snapshot))
	var client_last_server_state: Dictionary = Dictionary(client_simulation.call("get_last_server_state"))
	var host_network_snapshot: Dictionary = Dictionary(host_simulation.call("get_network_command_contract_snapshot"))

	var host_queue_before_read: int = _get_simulation_command_queue_count(host_simulation)
	var client_queue_before_read: int = _get_simulation_command_queue_count(client_simulation)
	var host_f6_snapshot: Dictionary = Dictionary(host_controller.call("get_core_loop_host_client_feel_snapshot"))
	var client_f6_snapshot: Dictionary = Dictionary(client_controller.call("get_core_loop_host_client_feel_snapshot"))
	var host_queue_after_read: int = _get_simulation_command_queue_count(host_simulation)
	var client_queue_after_read: int = _get_simulation_command_queue_count(client_simulation)

	_assert(bool(accepted_bravo_command.get("accepted", false)), "Peer 2 can submit a Bravo fireteam command on the host authority")
	_assert(String(rejected_alpha_command.get("reason", "")) == "peer_team_mismatch", "Peer 2 cannot command Alpha on the host authority")
	_assert(String(rejected_state_command.get("reason", "")).begins_with("state_mutation_key:damage"), "Peer 2 cannot smuggle state mutation into host command")
	_assert(queue_after_accept >= 1, "Accepted peer command reaches the host command queue")
	_assert(queue_after_process <= queue_after_accept, "Host processes the accepted peer command without growing the queue")
	_assert(int(host_network_snapshot.get("accepted_count", 0)) >= 1, "Host network command snapshot records accepted command")
	_assert(int(host_network_snapshot.get("rejected_count", 0)) >= 2, "Host network command snapshot records rejected commands")
	_assert(String(server_snapshot.get("snapshot_type", "")) == "state", "Host builds a state snapshot for the client")
	_assert(_snapshot_has_unit(server_snapshot, "task607_host_bravo"), "Host snapshot contains the Bravo probe unit")
	_assert(bool(client_apply_result.get("accepted", false)), "Client accepts the host state snapshot")
	_assert(_snapshot_has_unit(client_last_server_state, "task607_host_bravo"), "Client stores the host Bravo unit state")
	_assert(Dictionary(client_last_server_state.get("mission_result", {})).has("result"), "Client receives mission-result display state")
	_assert(String(host_f6_snapshot.get("gate", "")) == "pass", "Host mission instance keeps TASK_606 F6 gate green")
	_assert(String(client_f6_snapshot.get("gate", "")) == "pass", "Client mission instance keeps TASK_606 F6 gate green")
	_assert(_check_passed(host_f6_snapshot, "host_client_act_line_compacted"), "Host F6 snapshot keeps compact ACT line")
	_assert(_check_passed(client_f6_snapshot, "host_client_act_line_compacted"), "Client F6 snapshot keeps compact ACT line")
	_assert(_check_passed(host_f6_snapshot, "selected_fireteam_context_deduped"), "Host F6 snapshot keeps selected fireteam deduped")
	_assert(_check_passed(client_f6_snapshot, "selected_fireteam_context_deduped"), "Client F6 snapshot keeps selected fireteam deduped")
	_assert(String(host_f6_snapshot.get("mission_team_chip_context_text", "")).contains("Host Peer 1"), "Host F6 snapshot names Host Peer 1")
	_assert(String(client_f6_snapshot.get("mission_team_chip_context_text", "")).contains("Peer 2"), "Client F6 snapshot names Peer 2")
	_assert(host_queue_before_read == host_queue_after_read, "Reading host F6 snapshot does not enqueue commands")
	_assert(client_queue_before_read == client_queue_after_read, "Reading client F6 snapshot does not enqueue commands")
	_assert(not bool(host_f6_snapshot.get("ui_sets_gameplay_truth", true)), "Host F6 snapshot remains read-only")
	_assert(not bool(client_f6_snapshot.get("ui_sets_gameplay_truth", true)), "Client F6 snapshot remains read-only")

	host_scene.queue_free()
	client_scene.queue_free()
	await _wait_frames(2)


func _connect_local_enet_pair() -> Dictionary:
	for port in range(ENET_PORT_START, ENET_PORT_END + 1):
		var server := ENetMultiplayerPeer.new()
		var server_error: int = server.create_server(port, 2)
		if server_error != OK:
			server.close()
			continue
		var client := ENetMultiplayerPeer.new()
		var client_error: int = client.create_client("127.0.0.1", port)
		if client_error != OK:
			client.close()
			server.close()
			continue
		var connected: bool = false
		for _index in range(180):
			server.poll()
			client.poll()
			if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				connected = true
				break
			await process_frame
		var result: Dictionary = {
			"port": port,
			"connected": connected,
			"server_status": int(server.get_connection_status()),
			"client_status": int(client.get_connection_status()),
		}
		client.close()
		server.close()
		if connected:
			return result
	return {
		"port": 0,
		"connected": false,
		"server_status": -1,
		"client_status": -1,
	}


func _prepare_mission_instance(scene: Node, instance_role: String) -> Dictionary:
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	if simulation_root == null or controller == null or combat_driver == null:
		return {}
	simulation_root.set("is_server_authoritative", true)
	_apply_peer_assignments(simulation_root)
	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	if friendly_units.size() < 3:
		return {}
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS)
	_prepare_objective_and_cargo_context(controller, combat_driver, simulation_root)
	await _wait_frames(4)
	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, "blue")
	if contact_setup.is_empty():
		return {}
	var target_position: Vector2 = Vector2(contact_setup.get("enemy_position", Vector2.ZERO))
	_assign_suppress_fire_commands(controller, "blue", target_position, "task607_%s_f6" % instance_role)
	_force_detection_complete(controller, combat_driver, "blue", contact_setup)
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, "blue", contact_setup)
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)
	return {
		"simulation_root": simulation_root,
		"controller": controller,
		"combat_driver": combat_driver,
	}


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _prepare_objective_and_cargo_context(controller: Node, combat_driver: Node, simulation_root: Node) -> void:
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	if combat_driver.has_method("configure_scenario_runtime_gates_from_file"):
		combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	if combat_driver.has_method("set_mission_scenario_runtime_step_state"):
		combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
		combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	if combat_driver.has_method("set_mission_cargo_touchdown_state"):
		combat_driver.call("set_mission_cargo_touchdown_state", "landed", 12.0)
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")


func _apply_peer_assignments(simulation_root: Node) -> void:
	simulation_root.call("set_peer_team_assignments", PEER_TEAMS)
	for peer_id_variant in PEER_ROLES.keys():
		simulation_root.call("set_peer_role", int(peer_id_variant), String(PEER_ROLES[peer_id_variant]))
	simulation_root.call("set_peer_fireteam_assignments", {
		1: PackedStringArray(["blue"]),
		2: PackedStringArray(["red"]),
	})


func _register_runtime_probe_units(scene: Node, simulation_root: Node, suffix: String) -> void:
	_register_runtime_probe_unit(scene, simulation_root, "task607_%s_alpha" % suffix, "team_alpha", "blue", Vector2(-64.0, 0.0))
	_register_runtime_probe_unit(scene, simulation_root, "task607_%s_bravo" % suffix, "team_bravo", "red", Vector2(0.0, 0.0))


func _register_runtime_probe_unit(scene: Node, simulation_root: Node, unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	scene.add_child(unit)
	var unit_registry: Node = scene.get_node_or_null("UnitRegistry")
	if unit_registry != null and unit_registry.has_method("register_unit"):
		unit_registry.call("register_unit", unit_id, unit)
	if simulation_root != null and simulation_root.has_method("register_known_unit"):
		simulation_root.call("register_known_unit", unit_id, unit)
	return unit


func _build_probe_move_command(unit_id: String, team_id: String, fireteam_id: String, target_position: Vector2) -> Dictionary:
	return {
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": unit_id,
		"team_id": team_id,
		"fireteam_id": fireteam_id,
		"target_position": target_position,
		"priority": 5,
	}


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


func _mark_units_deployed(controller: Node, units: Array) -> void:
	var deployed_ids: Dictionary = {}
	var deployed_positions: Dictionary = {}
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			continue
		deployed_ids[unit_id] = true
		if unit is Node2D:
			deployed_positions[unit_id] = (unit as Node2D).global_position
	controller.set("_deployed_unit_ids", deployed_ids)
	controller.set("_deployed_unit_positions", deployed_positions)


func _assign_suppress_fire_commands(controller: Node, fireteam_id: String, target_position: Vector2, debug_source: String) -> void:
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var command = UNIT_COMMAND_SCRIPT.new()
		command.command_type = UNIT_COMMAND_SCRIPT.TYPE_HOLD_POSITION
		command.priority = 30
		command.unit_id = _get_unit_id(unit)
		command.team_id = String(unit.call("get_team_id")) if unit.has_method("get_team_id") else "team_alpha"
		command.target_position = target_position
		command.source_command_type = "defend"
		command.fire_rule = TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS
		command.fire_status = UNIT_COMMAND_SCRIPT.FIRE_STATUS_FIRE_AT_WILL
		if unit.has_method("assign_unit_command"):
			unit.call("assign_unit_command", command)
		if unit.has_method("set_runtime_status"):
			unit.call("set_runtime_status", "holding", "hold_position", 30, "fire_at_will", "defend", 1.0, 0.0, 0.0, 1, target_position, "engage", "aimed", debug_source, 1.0, 75.0)


func _position_first_enemy_near_fireteam(controller: Node, fireteam_id: String) -> Dictionary:
	var friendly_units: Array = Array(controller.call("_get_fireteam_units", fireteam_id, true))
	var enemy_units: Array = Array(controller.call("_get_all_enemy_units", false))
	if enemy_units.is_empty():
		enemy_units = Array(controller.call("_get_all_enemy_units", true))
	if friendly_units.is_empty() or enemy_units.is_empty():
		return {}
	var friendly := friendly_units[0] as Node2D
	var enemy := enemy_units[0] as Node2D
	if friendly == null or enemy == null:
		return {}
	enemy.global_position = friendly.global_position + Vector2(54.0, 0.0)
	if enemy is CanvasItem:
		(enemy as CanvasItem).visible = true
	return {
		"fireteam_id": fireteam_id,
		"friendly_unit_id": _get_unit_id(friendly),
		"enemy_unit_id": _get_unit_id(enemy),
		"friendly_position": friendly.global_position,
		"enemy_position": enemy.global_position,
	}


func _force_detection_complete(controller: Node, combat_driver: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	var enemy_id: String = String(contact_setup.get("enemy_unit_id", "")).strip_edges()
	var detection_progress: Dictionary = Dictionary(combat_driver.get("_detection_progress")).duplicate(true)
	for unit_variant in Array(controller.call("_get_fireteam_units", fireteam_id, true)):
		var unit := unit_variant as Node
		var friendly_id: String = _get_unit_id(unit)
		if friendly_id.is_empty() or enemy_id.is_empty():
			continue
		detection_progress["%s:%s" % [friendly_id, enemy_id]] = 0
		detection_progress["%s:%s" % [enemy_id, friendly_id]] = 0
	combat_driver.set("_detection_progress", detection_progress)


func _update_contact_tracking(combat_driver: Node) -> void:
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")
	if combat_driver.has_method("_advance_detection_timers"):
		combat_driver.call("_advance_detection_timers")
	if combat_driver.has_method("_update_contact_tracking"):
		combat_driver.call("_update_contact_tracking")


func _force_first_engagement_decision(controller: Node, combat_driver: Node, simulation_root: Node, fireteam_id: String, contact_setup: Dictionary) -> void:
	_force_detection_complete(controller, combat_driver, fireteam_id, contact_setup)
	combat_driver.set("_current_tick", 120)
	combat_driver.call("align_to_common_decision_step_for_test")
	if combat_driver.has_method("_try_enqueue_attacks"):
		combat_driver.call("_try_enqueue_attacks", simulation_root)


func _collect_team_units(root_node: Node, team_id: String) -> Array:
	var result: Array = []
	for node in _collect_nodes(root_node):
		if not node.has_method("get_team_id") or not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_team_id")).strip_edges() == team_id:
			result.append(node)
	return result


func _collect_nodes(root_node: Node) -> Array:
	var result: Array = []
	if root_node == null:
		return result
	result.append(root_node)
	for child in root_node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _get_unit_id(unit: Node) -> String:
	if unit != null and unit.has_method("get_unit_id"):
		return String(unit.call("get_unit_id")).strip_edges()
	return unit.name if unit != null else ""


func _get_simulation_command_queue_count(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var command_queue_variant: Variant = simulation_root.get("command_queue")
	if typeof(command_queue_variant) != TYPE_ARRAY:
		return 0
	return Array(command_queue_variant).size()


func _snapshot_has_unit(snapshot: Dictionary, unit_id: String) -> bool:
	for unit_variant in Array(snapshot.get("units", [])):
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges() == unit_id:
			return true
	return false


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
