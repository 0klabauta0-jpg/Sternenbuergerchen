extends SceneTree

const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_169 Multiplayer Two-Client Playability Smoke ===")
	await _test_two_client_authority_snapshot_smoke()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_two_client_authority_snapshot_smoke() -> void:
	var session: Node = _make_session()
	session.call("configure_host_state_for_test", [2])
	session.call("set_peer_ready_for_test", 1, true)
	session.call("set_peer_ready_for_test", 2, true)
	var session_snapshot: Dictionary = session.call("get_session_snapshot")
	_assert(bool(session_snapshot.get("can_start_mission", false)), "Session can start once host and client are ready")
	var assignments: Dictionary = session.call("build_session_assignments")
	var peer_ids: Array = Dictionary(assignments.get("peer_teams", {})).keys()
	peer_ids.sort()
	_assert(peer_ids == [1, 2], "Smoke captures host/client peer ids")
	_assert(String(Dictionary(assignments.get("peer_roles", {})).get(2, "")) == "commander", "Client peer receives commander role for the playability smoke")

	var host_context: Dictionary = _make_simulation_context("Task169Host")
	var client_context: Dictionary = _make_simulation_context("Task169Client")
	var host_simulation: Node = host_context["simulation_root"]
	var client_simulation: Node = client_context["simulation_root"]
	host_simulation.set("is_server_authoritative", true)
	client_simulation.set("is_server_authoritative", true)
	_apply_session_assignments(host_simulation, assignments)
	_apply_session_assignments(client_simulation, assignments)

	var host_unit: Node2D = _register_unit(host_context, "unit_bravo_1", "team_bravo", "red", Vector2.ZERO)
	var client_unit: Node2D = _register_unit(client_context, "unit_bravo_1", "team_bravo", "red", Vector2.ZERO)
	_register_unit(host_context, "unit_alpha_1", "team_alpha", "blue", Vector2(-64.0, 0.0))
	_register_unit(client_context, "unit_alpha_1", "team_alpha", "blue", Vector2(-64.0, 0.0))

	var client_move_command: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": "unit_bravo_1",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"target_position": Vector2(80.0, 0.0),
		"priority": 5,
	}
	var accepted_command: Dictionary = host_simulation.call("submit_network_command_for_peer", client_move_command, 2)
	_assert(bool(accepted_command.get("accepted", false)), "Server accepts a valid client commander move")
	_assert(host_simulation.command_queue.size() == 1, "Accepted client command is queued server-side")

	var invalid_command: Dictionary = client_move_command.duplicate(true)
	invalid_command["damage"] = 99
	var rejected_command: Dictionary = host_simulation.call("submit_network_command_for_peer", invalid_command, 2)
	_assert(not bool(rejected_command.get("accepted", true)), "Server rejects an invalid client state-mutation command")
	_assert(String(rejected_command.get("reason", "")).begins_with("state_mutation_key"), "Invalid command rejection reason is visible")

	var contract_debug: Dictionary = host_simulation.call("get_network_command_contract_snapshot")
	_assert(int(contract_debug.get("accepted_count", 0)) == 1, "Command debug counts accepted client commands")
	_assert(int(contract_debug.get("rejected_count", 0)) == 1, "Command debug counts rejected client commands")

	host_simulation.call("_physics_process", 0.5)
	_assert(host_unit.global_position.x > 0.0, "Server processes the accepted client command")

	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "obj_task_169"
	objective_status.position = Vector2(80.0, 0.0)
	objective_status.capture_radius = 48.0
	objective_status.owning_team_id = "team_bravo"
	objective_status.capturing_team_id = "team_bravo"
	objective_status.capture_progress = 1.0
	host_simulation.call("set_objective_status", objective_status)
	host_simulation.call(
		"set_multiplayer_snapshot_context",
		{
			"contacts": [
				{
					"fireteam_id": "red",
					"unit_id": "unit_alpha_1",
					"team_id": "team_alpha",
					"detection_state": "spotted",
					"last_known_position": Vector2(-64.0, 0.0),
					"last_seen_tick": int(host_simulation.call("get_tick")),
				},
			],
			"mission_result": {
				"result": "victory",
				"winning_team_id": "team_bravo",
				"win_condition_type": "objective_capture",
				"duration_seconds": 12.0,
			},
		}
	)

	var server_snapshot: Dictionary = host_simulation.call("build_multiplayer_snapshot")
	var apply_result: Dictionary = client_simulation.call("apply_multiplayer_snapshot", server_snapshot)
	var client_debug: Dictionary = client_simulation.call("get_multiplayer_snapshot_debug_snapshot")
	_assert(bool(apply_result.get("accepted", false)), "Client accepts the server snapshot")
	_assert(int(client_debug.get("last_applied_tick", -1)) == int(server_snapshot.get("tick", -2)), "Client debug records the last server tick")
	_assert(int(client_debug.get("missing_unit_count", 0)) == 0, "Client snapshot apply has no missing units")
	_assert(client_unit.global_position.x > 0.0, "Client sees replicated unit movement through snapshot interpolation")
	_assert(String(Dictionary(client_simulation.call("get_last_server_state")).get("mission_result", {}).get("result", "")) == "victory", "Mission result is mirrored in the client snapshot")

	_cleanup_context(host_context)
	_cleanup_context(client_context)
	session.queue_free()
	await process_frame


func _make_session() -> Node:
	var session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	session.name = "Task169Session"
	get_root().add_child(session)
	return session


func _make_simulation_context(context_name: String) -> Dictionary:
	var root := Node.new()
	root.name = context_name
	get_root().add_child(root)

	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	root.add_child(unit_registry)

	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	root.add_child(simulation_root)

	return {
		"root": root,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
	}


func _register_unit(context: Dictionary, unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var root: Node = context["root"]
	var unit_registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	root.add_child(unit)
	unit_registry.call("register_unit", unit_id, unit)
	simulation_root.call("register_known_unit", unit_id, unit)
	return unit


func _apply_session_assignments(simulation_root: Node, assignments: Dictionary) -> void:
	var peer_teams: Dictionary = Dictionary(assignments.get("peer_teams", {}))
	var peer_roles: Dictionary = Dictionary(assignments.get("peer_roles", {}))
	var peer_fireteams: Dictionary = Dictionary(assignments.get("peer_fireteams", {}))
	simulation_root.call("set_peer_team_assignments", peer_teams)
	for peer_id_variant in peer_roles.keys():
		simulation_root.call("set_peer_role", int(peer_id_variant), String(peer_roles[peer_id_variant]))
	simulation_root.call("set_peer_fireteam_assignments", peer_fireteams)


func _cleanup_context(context: Dictionary) -> void:
	var root: Node = context.get("root", null)
	if root != null:
		root.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
