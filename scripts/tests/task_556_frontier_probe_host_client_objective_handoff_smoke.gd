extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const HANDOFF_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/frontier_probe_host_client_handoff_contract.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_556_frontier_probe_host_client_objective_handoff_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const HANDOFF_CONTRACT_PATH: String = "res://scripts/mission/frontier_probe_host_client_handoff_contract.gd"
const TASK_169_TEST_PATH: String = "res://scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd"
const TASK_555_TEST_PATH: String = "res://scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_556 Frontier Probe Host Client Objective Handoff Smoke ===")
	_test_docs_and_wiring()
	await _test_frontier_probe_host_client_handoff()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_556: FAILED")
		quit(1)
		return
	print("TASK_556: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_556 task file exists")
	_assert(_read_text(TASK_PATH).contains("Frontier Probe Host Client Objective Handoff Smoke"), "TASK_556 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_556 - Frontier Probe Host Client Objective Handoff Smoke"), "Implementation status tracks TASK_556")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_556 - Frontier Probe Host Client Objective Handoff Smoke (implementiert)"), "Roadmap marks TASK_556 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_556 - Frontier Probe Host Client Objective Handoff Smoke"), "Review workbench tracks TASK_556")
	_assert(_read_text(CONTRACT_PATH).contains("Frontier-Probe-Host-Client-Objective-Handoff"), "Mission feedback contract documents TASK_556")
	_assert(FileAccess.file_exists(HANDOFF_CONTRACT_PATH), "TASK_556 handoff contract helper exists")
	_assert(_read_text(HANDOFF_CONTRACT_PATH).contains("FrontierProbeHostClientHandoffContract"), "TASK_556 contract helper names its authority")
	_assert(FileAccess.file_exists(TASK_169_TEST_PATH), "TASK_169 multiplayer playability smoke remains available")
	_assert(FileAccess.file_exists(TASK_555_TEST_PATH), "TASK_555 ownership verifier remains available")


func _test_frontier_probe_host_client_handoff() -> void:
	var ownership_snapshot: Dictionary = await _build_task_555_ownership_snapshot()
	_assert(String(ownership_snapshot.get("gate", "")) == "pass", "TASK_555 ownership snapshot is green before host/client handoff")

	var session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	session.name = "Task556Session"
	root.add_child(session)
	session.call("configure_host_state_for_test", [2])
	session.call("set_peer_ready_for_test", 1, true)
	session.call("set_peer_ready_for_test", 2, true)
	var pre_session_snapshot: Dictionary = Dictionary(session.call("get_session_snapshot"))
	_assert(bool(pre_session_snapshot.get("can_start_mission", false)), "Host/client session can start before handoff")
	var start_result: bool = bool(session.call("request_start_mission"))
	var post_session_snapshot: Dictionary = Dictionary(session.call("get_session_snapshot"))
	var assignments: Dictionary = Dictionary(session.call("build_session_assignments"))

	var host_context: Dictionary = _make_simulation_context("Task556Host")
	var client_context: Dictionary = _make_simulation_context("Task556Client")
	var host_simulation: Node = host_context["simulation_root"]
	var client_simulation: Node = client_context["simulation_root"]
	host_simulation.set("is_server_authoritative", true)
	client_simulation.set("is_server_authoritative", true)
	_apply_session_assignments(host_simulation, assignments)
	_apply_session_assignments(client_simulation, assignments)

	var host_bravo: Node2D = _register_unit(host_context, "unit_bravo_frontier", "team_bravo", "red", Vector2.ZERO)
	var client_bravo: Node2D = _register_unit(client_context, "unit_bravo_frontier", "team_bravo", "red", Vector2.ZERO)
	_register_unit(host_context, "unit_alpha_frontier", "team_alpha", "blue", Vector2(-64.0, 0.0))
	_register_unit(client_context, "unit_alpha_frontier", "team_alpha", "blue", Vector2(-64.0, 0.0))

	var bravo_move_command: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": "unit_bravo_frontier",
		"team_id": "team_bravo",
		"fireteam_id": "red",
		"target_position": Vector2(96.0, 0.0),
		"priority": 5,
	}
	var accepted_bravo_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", bravo_move_command, 2))
	var alpha_move_command: Dictionary = {
		"command_type": "move_to_position",
		"unit_id": "unit_alpha_frontier",
		"team_id": "team_alpha",
		"fireteam_id": "blue",
		"target_position": Vector2(24.0, 0.0),
		"priority": 5,
	}
	var rejected_alpha_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", alpha_move_command, 2))
	var forbidden_state_command: Dictionary = bravo_move_command.duplicate(true)
	forbidden_state_command["damage"] = 99
	var rejected_state_mutation_command: Dictionary = Dictionary(host_simulation.call("submit_network_command_for_peer", forbidden_state_command, 2))
	host_simulation.call("_physics_process", 0.5)

	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "frontier_probe_objective"
	objective_status.position = Vector2(96.0, 0.0)
	objective_status.capture_radius = 64.0
	objective_status.owning_team_id = "team_alpha"
	objective_status.capturing_team_id = "team_alpha"
	objective_status.capture_progress = 1.0
	host_simulation.call("set_objective_status", objective_status)
	host_simulation.call(
		"set_multiplayer_snapshot_context",
		{
			"dropship": {
				"visible": false,
				"state": "departed",
				"team_id": "team_alpha",
			},
			"mission_result": {
				"result": "victory",
				"winning_team_id": "team_alpha",
				"friendly_team_id": "team_alpha",
				"win_condition_type": "frontier_probe_objective_complete",
				"objective_captured": true,
				"duration_seconds": 42.0,
			},
		}
	)

	var server_snapshot: Dictionary = Dictionary(host_simulation.call("build_multiplayer_snapshot"))
	var client_apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", server_snapshot))
	var client_debug: Dictionary = Dictionary(client_simulation.call("get_multiplayer_snapshot_debug_snapshot"))
	var client_last_server_state: Dictionary = Dictionary(client_simulation.call("get_last_server_state"))
	var host_network_snapshot: Dictionary = Dictionary(host_simulation.call("get_network_command_contract_snapshot"))
	var handoff_snapshot: Dictionary = Dictionary(HANDOFF_CONTRACT_SCRIPT.call("build_snapshot", {
		"ownership_snapshot": ownership_snapshot,
		"pre_session_snapshot": pre_session_snapshot,
		"post_session_snapshot": post_session_snapshot,
		"start_result": start_result,
		"assignments": assignments,
		"host_network_snapshot": host_network_snapshot,
		"accepted_bravo_command": accepted_bravo_command,
		"rejected_alpha_command": rejected_alpha_command,
		"rejected_state_mutation_command": rejected_state_mutation_command,
		"server_snapshot": server_snapshot,
		"client_apply_result": client_apply_result,
		"client_debug": client_debug,
		"client_last_server_state": client_last_server_state,
		"host_bravo_position": host_bravo.global_position,
		"client_bravo_position": client_bravo.global_position,
	}))
	_assert(String(handoff_snapshot.get("gate", "")) == "pass", "TASK_556 host/client handoff snapshot passes")
	_assert(_check_passed(handoff_snapshot, "ownership_gate_passes"), "TASK_555 ownership remains green inside TASK_556")
	_assert(_check_passed(handoff_snapshot, "session_ready_before_start"), "Session is ready before mission start")
	_assert(_check_passed(handoff_snapshot, "mission_start_handoff_requested"), "Mission start handoff is requested")
	_assert(_check_passed(handoff_snapshot, "assignments_include_alpha_host_and_bravo_client"), "Assignments include Alpha host and Bravo client")
	_assert(_check_passed(handoff_snapshot, "simulation_root_received_session_assignments"), "SimulationRoot receives session assignments")
	_assert(_check_passed(handoff_snapshot, "bravo_client_command_accepted"), "Bravo client command is accepted and processed")
	_assert(_check_passed(handoff_snapshot, "alpha_foreign_team_command_rejected"), "Alpha command from Bravo peer is rejected")
	_assert(_check_passed(handoff_snapshot, "state_mutation_command_rejected"), "Forbidden state mutation command is rejected")
	_assert(_check_passed(handoff_snapshot, "server_snapshot_contains_frontier_objective_result"), "Server snapshot contains objective result")
	_assert(_check_passed(handoff_snapshot, "client_accepts_server_snapshot"), "Client accepts server snapshot")
	_assert(_check_passed(handoff_snapshot, "client_receives_objective_and_result"), "Client receives objective and result")
	_assert(_check_passed(handoff_snapshot, "read_only"), "TASK_556 handoff contract remains read-only")

	_cleanup_context(host_context)
	_cleanup_context(client_context)
	session.queue_free()
	await _wait_frames(2)


func _build_task_555_ownership_snapshot() -> Dictionary:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_mission_scene(scene)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	if simulation_root != null and simulation_root.has_method("set_peer_team_assignments"):
		simulation_root.call("set_peer_team_assignments", {
			1: "team_alpha",
			2: "team_bravo",
		})
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return {}
	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assign_fireteam_ids(friendly_units.slice(0, mini(2, friendly_units.size())), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(8)
	var ownership_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_multiplayer_objective_ownership_snapshot"))
	scene.queue_free()
	await _wait_frames(2)
	return ownership_snapshot


func _configure_mission_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", LARGE_MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", true)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _make_simulation_context(context_name: String) -> Dictionary:
	var context_root := Node.new()
	context_root.name = context_name
	root.add_child(context_root)
	var unit_registry = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	context_root.add_child(unit_registry)
	var simulation_root = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	simulation_root.unit_registry_path = NodePath("../UnitRegistry")
	context_root.add_child(simulation_root)
	return {
		"root": context_root,
		"unit_registry": unit_registry,
		"simulation_root": simulation_root,
	}


func _register_unit(context: Dictionary, unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var context_root: Node = context["root"]
	var unit_registry: Node = context["unit_registry"]
	var simulation_root: Node = context["simulation_root"]
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	context_root.add_child(unit)
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


func _assign_fireteam_ids(units: Array, fireteam_id: String) -> void:
	for unit_variant in units:
		var unit := unit_variant as Node
		if unit != null and unit.has_method("set_fireteam_id"):
			unit.call("set_fireteam_id", fireteam_id)


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


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _cleanup_context(context: Dictionary) -> void:
	var context_root: Node = context.get("root", null)
	if context_root != null:
		context_root.queue_free()


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
