extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TACTICAL_COMMAND_RULES_SCRIPT: GDScript = preload("res://scripts/tactical/tactical_command_rules.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_604_core_loop_host_client_feel_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_556_TEST_PATH: String = "res://scripts/tests/task_556_frontier_probe_host_client_objective_handoff_smoke.gd"
const TASK_557_TEST_PATH: String = "res://scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd"
const TASK_603_TEST_PATH: String = "res://scripts/tests/task_603_mission_hud_density_interaction_polish.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_604 Core Loop Host Client Feel Smoke ===")
	_test_docs_and_wiring()
	await _test_core_loop_host_client_feel_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_604: FAILED")
		quit(1)
		return
	print("TASK_604: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_604 task file exists")
	_assert(task_text.contains("Core Loop Host Client Feel Smoke"), "TASK_604 task file names the task")
	_assert(status_text.contains("TASK_604 - Core Loop Host Client Feel Smoke"), "Implementation status tracks TASK_604")
	_assert(roadmap_text.contains("TASK_604 - Core Loop Host Client Feel Smoke (implementiert)"), "Roadmap marks TASK_604 implemented")
	_assert(report_text.contains("TASK_604 - Core Loop Host Client Feel Smoke"), "Review workbench tracks TASK_604")
	_assert(report_text.contains("TASK_605 - Host Client F6 Visual Review Pass"), "Review workbench names TASK_605 follow-up")
	_assert(contract_text.contains("Core-Loop-Host-Client-Feel-Smoke"), "Mission feedback contract documents TASK_604")
	_assert(controller_text.contains("get_core_loop_host_client_feel_snapshot"), "TacticalController exposes TASK_604 snapshot")
	_assert(FileAccess.file_exists(TASK_556_TEST_PATH), "TASK_556 host/client handoff verifier remains available")
	_assert(FileAccess.file_exists(TASK_557_TEST_PATH), "TASK_557 MP F6 readability verifier remains available")
	_assert(FileAccess.file_exists(TASK_603_TEST_PATH), "TASK_603 HUD density verifier remains available")


func _test_core_loop_host_client_feel_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
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
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission fixture exposes TacticalController, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for host/client feel smoke")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return

	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("set_fireteams_fire_rule", PackedStringArray(["blue"]), TACTICAL_COMMAND_RULES_SCRIPT.FIRE_RULE_SUPPRESS)
	_prepare_objective_and_cargo_context(controller, combat_driver, simulation_root)
	await _wait_frames(4)

	var contact_setup: Dictionary = _position_first_enemy_near_fireteam(controller, "blue")
	_assert(not contact_setup.is_empty(), "Enemy can be positioned for combined host/client feel context")
	if contact_setup.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	var target_position: Vector2 = Vector2(contact_setup.get("enemy_position", Vector2.ZERO))
	_assign_suppress_fire_commands(controller, "blue", target_position)
	_force_detection_complete(controller, combat_driver, "blue", contact_setup)
	_update_contact_tracking(combat_driver)
	_force_first_engagement_decision(controller, combat_driver, simulation_root, "blue", contact_setup)
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var queue_count_before: int = _get_simulation_command_queue_count(simulation_root)
	var snapshot: Dictionary = Dictionary(controller.call("get_core_loop_host_client_feel_snapshot"))
	var queue_count_after: int = _get_simulation_command_queue_count(simulation_root)
	var act_line: String = String(snapshot.get("mission_hud_interaction_line", "")).strip_edges()
	var mission_text: String = String(snapshot.get("mission_control_status_text", "")).strip_edges()
	var team_context: String = String(snapshot.get("mission_team_chip_context_text", "")).strip_edges()
	_assert(queue_count_before == queue_count_after, "Reading TASK_604 snapshot does not enqueue commands")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_604 snapshot is read-only")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_604 combined host/client feel gate passes")
	_assert(_check_passed(snapshot, "mp_f6_readability_gate_passes"), "MP F6 readability stays green")
	_assert(_check_passed(snapshot, "mission_hud_density_gate_passes"), "Mission HUD density stays green")
	_assert(_check_passed(snapshot, "host_client_team_context_visible"), "Host and client ownership context is visible")
	_assert(_check_passed(snapshot, "mission_control_keeps_act_line"), "Mission Control keeps ACT line visible")
	_assert(_check_passed(snapshot, "objective_cargo_roe_context_visible"), "Objective, Cargo and ROE context stay visible")
	_assert(_check_passed(snapshot, "selected_fireteam_context_visible"), "Selected Fireteam context stays visible")
	_assert(_check_passed(snapshot, "command_feedback_exports_density"), "Command feedback exports HUD density data")
	_assert(_check_passed(snapshot, "read_only"), "Combined TASK_604 snapshot remains read-only")
	_assert(act_line.begins_with("ACT "), "TASK_604 ACT line starts with ACT")
	_assert(mission_text.contains("OBJ") and mission_text.contains("CARGO") and mission_text.contains("ROE"), "Mission Control text contains OBJ/CARGO/ROE")
	_assert(team_context.contains("Host Peer 1") and team_context.contains("Peer 2"), "Team context names Host Peer 1 and Peer 2")

	scene.queue_free()
	await _wait_frames(2)


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


func _assign_suppress_fire_commands(controller: Node, fireteam_id: String, target_position: Vector2) -> void:
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
			unit.call(
				"set_runtime_status",
				"holding",
				"hold_position",
				30,
				"fire_at_will",
				"defend",
				1.0,
				0.0,
				0.0,
				1,
				target_position,
				"engage",
				"aimed",
				"task604_host_client_feel",
				1.0,
				75.0
			)


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
	combat_driver.set("_next_attack_tick", 0)
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
