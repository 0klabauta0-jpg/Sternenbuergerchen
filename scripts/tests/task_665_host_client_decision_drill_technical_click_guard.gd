extends SceneTree

const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")
const UNIT_COMMAND_SCRIPT: GDScript = preload("res://scripts/npc/unit_command.gd")
const TEAM_CHIP_PRESENTER_SCRIPT: GDScript = preload("res://scripts/mission/mission_team_chip_presenter.gd")
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_665_host_client_decision_drill_technical_click_guard.md"
const TASK_664_TEST_PATH: String = "res://scripts/tests/task_664_host_client_decision_drill_real_click_recheck.gd"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MANIFEST_PATH: String = "res://tmp/host_client_decision_drill_technical_click_guard.json"
const EXPECTED_NEXT_TASK: String = "TASK_666 - Host Client Decision Drill Real Click Findings"

var _passed: int = 0
var _failed: int = 0
var _peer_fireteams: Dictionary = {
	1: PackedStringArray(["blue"]),
	2: PackedStringArray(["red"]),
}


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_665 Host Client Decision Drill Technical Click Guard ===")
	_test_docs_report_and_contract()
	var authority_result: Dictionary = await _run_authority_guard()
	var review_context: Dictionary = _build_client_review_context()
	var drill_result: Dictionary = await _run_decision_drill_guard()
	var manifest: Dictionary = _build_manifest(authority_result, review_context, drill_result)
	_write_json(MANIFEST_PATH, manifest)
	_test_manifest(manifest)
	_test_written_manifest()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_665: FAILED")
		quit(1)
		return
	print("TASK_665: ALL PASSED")
	quit(0)


func _test_docs_report_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var task_664_test_text: String = _read_text(TASK_664_TEST_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_665 task file exists")
	_assert(task_text.contains("Host Client Decision Drill Technical Click Guard"), "TASK_665 task names technical click guard")
	_assert(status_text.contains("TASK_665 - Host Client Decision Drill Technical Click Guard"), "Implementation status tracks TASK_665")
	_assert(roadmap_text.contains("TASK_665 - Host Client Decision Drill Technical Click Guard (implementiert)"), "Roadmap marks TASK_665 implemented")
	_assert(roadmap_text.contains("TASK_666 - Host Client Decision Drill Real Click Findings (geplant)"), "Roadmap plans TASK_666 follow-up")
	_assert(contract_text.contains("Host-Client-Decision-Drill-Technical-Click-Guard"), "Mission feedback contract documents TASK_665")
	_assert(report_text.contains("TASK_665 - Host Client Decision Drill Technical Click Guard"), "Current handbook report tracks TASK_665")
	_assert(report_text.contains('latest_completed_task: "TASK_665 - Host Client Decision Drill Technical Click Guard"'), "Current handbook export records TASK_665 latest")
	_assert(report_text.contains('data-export-key="host_client_decision_drill_technical_guard.peer2_bravo_accepted"'), "Current handbook exports TASK_665 authority check")
	_assert(report_text.contains('data-note-key="notes.host_client_decision_drill_technical_guard"'), "Current handbook exports TASK_665 notes")
	_assert(report_text.contains(EXPECTED_NEXT_TASK), "Current handbook recommends TASK_666")
	_assert(task_664_test_text.contains("TASK_665 - Host Client Decision Drill Technical Click Guard"), "TASK_664 verifier recommends the technical guard follow-up")


func _run_authority_guard() -> Dictionary:
	var host_root: Node = Node.new()
	host_root.name = "Task665HostRoot"
	var unit_registry: Node = UNIT_REGISTRY_SCRIPT.new()
	unit_registry.name = "UnitRegistry"
	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "HostSimulationRoot"
	simulation_root.set("is_server_authoritative", true)
	simulation_root.set("unit_registry_path", NodePath("../UnitRegistry"))
	host_root.add_child(unit_registry)
	host_root.add_child(simulation_root)
	root.add_child(host_root)
	await process_frame

	_apply_peer_assignments(simulation_root)
	var alpha_unit: Node2D = _register_probe_unit(host_root, unit_registry, simulation_root, "task665_alpha", "team_alpha", "blue", Vector2(-64.0, 0.0))
	var bravo_unit: Node2D = _register_probe_unit(host_root, unit_registry, simulation_root, "task665_bravo", "team_bravo", "red", Vector2(0.0, 0.0))
	var accepted_bravo: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", _build_probe_move_command(bravo_unit, Vector2(96.0, 0.0)), 2))
	var rejected_alpha: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", _build_probe_move_command(alpha_unit, Vector2(24.0, 0.0)), 2))
	var network_snapshot: Dictionary = Dictionary(simulation_root.call("get_network_command_contract_snapshot"))
	var presenter = TEAM_CHIP_PRESENTER_SCRIPT.new()
	var teamchip_snapshot: Dictionary = Dictionary(presenter.call("build_snapshot", network_snapshot))
	var authority_visual: Dictionary = Dictionary(teamchip_snapshot.get("authority_visual", {}))
	var result := {
		"peer2_bravo_command_accepted": bool(accepted_bravo.get("accepted", false)),
		"peer2_bravo_command_reason": String(accepted_bravo.get("reason", "")),
		"peer2_alpha_command_rejected": not bool(rejected_alpha.get("accepted", true)),
		"alpha_reject_reason": String(rejected_alpha.get("reason", "")),
		"host_network_accept_count": int(network_snapshot.get("accepted_count", 0)),
		"host_network_reject_count": int(network_snapshot.get("rejected_count", 0)),
		"visible_feedback_text": String(authority_visual.get("visible_feedback_text", "")),
		"visible_action_text": String(authority_visual.get("visible_action_text", "")),
		"next_action_text": String(authority_visual.get("next_action_text", "")),
		"authority_read_only": bool(authority_visual.get("read_only", false)),
		"authority_ui_sets_gameplay_truth": bool(authority_visual.get("ui_sets_gameplay_truth", true)),
	}
	host_root.queue_free()
	await process_frame
	return result


func _build_client_review_context() -> Dictionary:
	var controller_script: GDScript = load(CONTROLLER_PATH)
	var controller: Node = controller_script.new()
	var context: Dictionary = Dictionary(controller.call("_build_fireteam_review_session_card_context", {
		"role_label": "CLIENT",
		"peer_label": "P2",
		"team_label": "BRAVO",
	}))
	controller.free()
	return context


func _run_decision_drill_guard() -> Dictionary:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var controller: Node = scene.get_node_or_null("TacticalController")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and simulation_root != null, "Mission fixture exposes TacticalController and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return {}
	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for technical drill")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return {}
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	_prepare_frontier_probe_scene(controller, simulation_root)
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	var planned: bool = bool(controller.call("issue_right_click_command_for_test", move_target, "move", false))
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)
	var before_go: Dictionary = Dictionary(controller.call("get_frontier_probe_one_screen_player_decision_drill_snapshot")).duplicate(true)
	var go_result: bool = bool(controller.call("execute_selected_fireteam_orders"))
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(12)
	await _wait_physics_frames(3)
	var after_go: Dictionary = Dictionary(controller.call("get_frontier_probe_one_screen_player_decision_drill_snapshot")).duplicate(true)
	var result := {
		"planned": planned,
		"before_go_stage": String(before_go.get("decision_stage", "")),
		"before_go_gate": String(before_go.get("gate", "")),
		"before_go_ready": bool(before_go.get("go_ready", false)),
		"next_token": String(before_go.get("next_token", "")),
		"recommended_plan_id": String(Dictionary(before_go.get("recommended_plan", {})).get("id", "")),
		"go_result": go_result,
		"after_go_stage": String(after_go.get("decision_stage", "")),
		"after_go_gate": String(after_go.get("gate", "")),
		"after_go_execution_active": bool(after_go.get("execution_active", false)),
		"execution_feedback_gate": String(Dictionary(after_go.get("execution_feedback_snapshot", {})).get("gate", "")),
		"read_only": bool(after_go.get("read_only", false)),
		"ui_sets_gameplay_truth": bool(after_go.get("ui_sets_gameplay_truth", true)),
	}
	scene.queue_free()
	await _wait_frames(2)
	return result


func _build_manifest(authority_result: Dictionary, review_context: Dictionary, drill_result: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.host_client_decision_drill_technical_click_guard.v1",
		"task_id": "TASK_665",
		"source_task_ids": PackedStringArray(["TASK_622", "TASK_650", "TASK_658", "TASK_664"]),
		"manifest_path": "tmp/host_client_decision_drill_technical_click_guard.json",
		"authority_path": authority_result,
		"review_card_context": {
			"text": String(review_context.get("text", "")),
			"full_text": String(review_context.get("full_text", "")),
			"style_id": String(review_context.get("style_id", "")),
			"visible": bool(review_context.get("visible", false)),
			"read_only": bool(review_context.get("read_only", false)),
			"ui_sets_gameplay_truth": bool(review_context.get("ui_sets_gameplay_truth", true)),
		},
		"decision_drill_path": drill_result,
		"technical_guard_gate": "pass",
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": EXPECTED_NEXT_TASK,
	}


func _test_manifest(manifest: Dictionary) -> void:
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_decision_drill_technical_click_guard.v1", "Manifest schema is stable")
	_assert(String(manifest.get("task_id", "")) == "TASK_665", "Manifest records TASK_665")
	var authority_path: Dictionary = Dictionary(manifest.get("authority_path", {}))
	_assert(bool(authority_path.get("peer2_bravo_command_accepted", false)), "Peer 2 Bravo command is accepted")
	_assert(bool(authority_path.get("peer2_alpha_command_rejected", false)), "Peer 2 Alpha command is rejected")
	_assert(String(authority_path.get("alpha_reject_reason", "")) == "peer_team_mismatch", "Alpha reject reason is peer_team_mismatch")
	_assert(String(authority_path.get("visible_feedback_text", "")) == "BLOCK P2 wrong team", "Authority feedback keeps block text")
	_assert(String(authority_path.get("visible_action_text", "")) == "USE BRAVO", "Authority feedback keeps USE BRAVO")
	_assert(bool(authority_path.get("authority_read_only", false)), "Authority feedback is read-only")
	_assert(not bool(authority_path.get("authority_ui_sets_gameplay_truth", true)), "Authority feedback does not set gameplay truth")
	var review_context: Dictionary = Dictionary(manifest.get("review_card_context", {}))
	_assert(String(review_context.get("text", "")) == "P2 BRAVO", "Review card context is P2 BRAVO")
	_assert(String(review_context.get("style_id", "")) == "host_client_fireteam_context_badge_v1", "Review card style id is stable")
	_assert(bool(review_context.get("visible", false)), "Review card context is visible")
	_assert(bool(review_context.get("read_only", false)), "Review card context is read-only")
	_assert(not bool(review_context.get("ui_sets_gameplay_truth", true)), "Review card context does not set gameplay truth")
	var drill_path: Dictionary = Dictionary(manifest.get("decision_drill_path", {}))
	_assert(bool(drill_path.get("planned", false)), "Decision drill planned a move")
	_assert(String(drill_path.get("before_go_stage", "")) == "preview", "Decision drill is preview before GO")
	_assert(String(drill_path.get("before_go_gate", "")) == "pass", "Decision drill gate passes before GO")
	_assert(bool(drill_path.get("before_go_ready", false)), "Decision drill is GO-ready before GO")
	_assert(String(drill_path.get("next_token", "")) == "AA", "Decision drill keeps NEXT AA")
	_assert(String(drill_path.get("recommended_plan_id", "")) == "aa_first_push", "Decision drill keeps AA-first plan")
	_assert(bool(drill_path.get("go_result", false)), "GO command is accepted")
	_assert(String(drill_path.get("after_go_stage", "")) == "execution", "Decision drill is execution after GO")
	_assert(bool(drill_path.get("after_go_execution_active", false)), "Decision drill has active execution after GO")
	_assert(String(drill_path.get("execution_feedback_gate", "")) == "pass", "Execution feedback gate passes")
	_assert(bool(drill_path.get("read_only", false)), "Decision drill snapshot is read-only")
	_assert(not bool(drill_path.get("ui_sets_gameplay_truth", true)), "Decision drill snapshot does not set gameplay truth")
	_assert(String(manifest.get("technical_guard_gate", "")) == "pass", "Technical guard passes")
	_assert(bool(manifest.get("manual_review_required", false)), "Manifest requires manual review")
	_assert(not bool(manifest.get("manual_review_done", true)), "Manifest does not claim manual review done")
	_assert(bool(manifest.get("read_only", false)), "Manifest remains read-only")
	_assert(not bool(manifest.get("ui_sets_gameplay_truth", true)), "Manifest does not set gameplay truth")
	_assert(String(manifest.get("recommended_next_task", "")) == EXPECTED_NEXT_TASK, "Manifest recommends real click findings")


func _test_written_manifest() -> void:
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_665 manifest was written")
	var manifest: Dictionary = _read_json(MANIFEST_PATH)
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.host_client_decision_drill_technical_click_guard.v1", "Written manifest schema is stable")
	_assert(String(manifest.get("technical_guard_gate", "")) == "pass", "Written manifest records passing gate")


func _apply_peer_assignments(simulation_root: Node) -> void:
	simulation_root.call("set_peer_team_assignments", {1: "team_alpha", 2: "team_bravo"})
	simulation_root.call("set_peer_role", 1, "host")
	simulation_root.call("set_peer_role", 2, "fireteam")
	simulation_root.call("set_peer_fireteam_assignments", _peer_fireteams)


func _register_probe_unit(parent: Node, unit_registry: Node, simulation_root: Node, unit_id: String, team_id: String, fireteam_id: String, position: Vector2) -> Node2D:
	var unit: Node2D = TEST_UNIT_SCRIPT.new()
	unit.unit_id = unit_id
	unit.team_id = team_id
	unit.fireteam_id = fireteam_id
	unit.global_position = position
	parent.add_child(unit)
	if unit_registry != null and unit_registry.has_method("register_unit"):
		unit_registry.call("register_unit", unit_id, unit)
	if simulation_root != null and simulation_root.has_method("register_known_unit"):
		simulation_root.call("register_known_unit", unit_id, unit)
	return unit


func _build_probe_move_command(unit: Node2D, target_position: Vector2) -> Dictionary:
	return {
		"command_type": UNIT_COMMAND_SCRIPT.TYPE_MOVE_TO_POSITION,
		"unit_id": unit.call("get_unit_id"),
		"team_id": unit.call("get_team_id"),
		"fireteam_id": unit.call("get_fireteam_id"),
		"target_position": target_position,
		"movement_posture": UNIT_COMMAND_SCRIPT.MOVEMENT_POSTURE_TACTICAL,
		"weapon_posture": UNIT_COMMAND_SCRIPT.WEAPON_POSTURE_READY,
		"priority": 5,
	}


func _prepare_frontier_probe_scene(controller: Node, simulation_root: Node) -> void:
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	if objective_status != null:
		objective_status.owning_team_id = "team_alpha"
		objective_status.capturing_team_id = "team_alpha"
		objective_status.capture_progress = 1.0
		controller.call("select_tile_from_world_position_for_test", objective_status.position)
	var combat_driver := controller.get_node_or_null("../CombatLoopDriver")
	if combat_driver != null:
		combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
		combat_driver.call("set_mission_cargo_touchdown_state", "blocked")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")


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


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _write_json(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_assert(false, "Could not open TASK_665 manifest path for writing")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed)


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
