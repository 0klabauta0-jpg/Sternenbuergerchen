extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_658_frontier_probe_one_screen_player_decision_drill.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_one_screen_player_decision_drill.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_658 Frontier Probe One-Screen Player Decision Drill ===")
	_test_docs_and_report()
	await _test_player_decision_drill()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_658: FAILED")
		quit(1)
		return
	print("TASK_658: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_658 task file exists")
	_assert(task_text.contains("Frontier Probe One-Screen Player Decision Drill"), "TASK_658 task names player decision drill")
	_assert(status_text.contains("TASK_658 - Frontier Probe One-Screen Player Decision Drill"), "Implementation status tracks TASK_658")
	_assert(roadmap_text.contains("TASK_658 - Frontier Probe One-Screen Player Decision Drill (implementiert)"), "Roadmap marks TASK_658 implemented")
	_assert(contract_text.contains("Frontier-Probe-One-Screen-Player-Decision-Drill"), "Mission feedback contract documents TASK_658")
	_assert(report_text.contains("TASK_658 - Frontier Probe One-Screen Player Decision Drill"), "Current handbook report tracks TASK_658")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook export records a latest task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook recommends a follow-up task")
	_assert(report_text.contains('data-export-key="status.task_658_done"'), "Current handbook exports TASK_658 done status")
	_assert(report_text.contains('data-export-key="decision_drill.next_aa_visible"'), "Current handbook exports decision drill next check")
	_assert(report_text.contains('data-note-key="notes.decision_drill"'), "Current handbook exports TASK_658 notes")
	_assert(controller_text.contains("get_frontier_probe_one_screen_player_decision_drill_snapshot"), "Controller exposes TASK_658 snapshot")


func _test_player_decision_drill() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var primary_view: Node = scene.get_node_or_null("Primary3DView")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and primary_view != null and simulation_root != null, "Mission fixture exposes TacticalController, Primary3DView and SimulationRoot")
	if controller == null or primary_view == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for the decision drill")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	_prepare_frontier_probe_scene(controller, simulation_root)
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Player drill can plan the first Move through the existing right-click path")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)

	var before_go: Dictionary = Dictionary(controller.call("get_frontier_probe_one_screen_player_decision_drill_snapshot")).duplicate(true)
	_assert(String(before_go.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_player_decision_drill.v1", "TASK_658 snapshot schema is stable")
	_assert(String(before_go.get("task_id", "")) == "TASK_658", "Snapshot records TASK_658")
	_assert(String(before_go.get("gate", "")) == "pass", "Decision drill gate passes before GO")
	_assert(String(before_go.get("decision_stage", "")) == "preview", "Before GO snapshot is in preview stage")
	_assert(String(before_go.get("next_token", "")) == "AA", "Decision drill exposes NEXT AA")
	_assert(bool(before_go.get("go_ready", false)), "Decision drill reports GO ready before execution")
	_assert(_check_passed(before_go, "one_screen_route_readable"), "One-screen route remains readable")
	_assert(_check_passed(before_go, "next_aa_decision_cue_visible"), "NEXT AA decision cue is visible")
	_assert(_check_passed(before_go, "plan_has_actionable_steps"), "Recommended plan has actionable steps")
	_assert(_check_passed(before_go, "move_preview_before_go_readable"), "Move and risk preview are readable before GO")
	var before_plan: Dictionary = Dictionary(before_go.get("recommended_plan", {}))
	_assert(String(before_plan.get("id", "")) == "aa_first_push", "Recommended plan points to AA first")
	_assert(Array(before_plan.get("steps", [])).size() >= 4, "Recommended plan has a short step list")
	var queue_before: int = _get_simulation_command_queue_count(simulation_root)
	_assert(bool(controller.call("execute_selected_fireteam_orders")), "Player drill can confirm the planned move with GO")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(12)
	await _wait_physics_frames(3)

	var after_go: Dictionary = Dictionary(controller.call("get_frontier_probe_one_screen_player_decision_drill_snapshot")).duplicate(true)
	var execution_feedback: Dictionary = Dictionary(after_go.get("execution_feedback_snapshot", {}))
	_assert(String(after_go.get("gate", "")) == "pass", "Decision drill gate passes after GO")
	_assert(String(after_go.get("decision_stage", "")) == "execution", "After GO snapshot is in execution stage")
	_assert(bool(after_go.get("execution_active", false)), "Decision drill reports active execution after GO")
	_assert(String(execution_feedback.get("gate", "")) == "pass", "Existing first-move execution feedback gate passes")
	_assert(_check_passed(after_go, "execution_feedback_visible_after_go"), "Execution feedback is visible after GO")
	_assert(_check_passed(after_go, "read_only"), "Decision drill snapshot remains read-only")
	_assert(not bool(after_go.get("ui_sets_gameplay_truth", true)), "Decision drill snapshot does not set gameplay truth")
	var queue_after: int = _get_simulation_command_queue_count(simulation_root)
	_assert(queue_after >= queue_before, "GO path does not corrupt the SimulationRoot command queue")
	var manifest: Dictionary = _build_manifest(before_go, after_go)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_658 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_player_decision_drill_manifest.v1", "Manifest uses TASK_658 schema")
	_assert(bool(manifest.get("before_go_ready", false)), "Manifest records pre-GO readiness")
	_assert(bool(manifest.get("after_go_execution_active", false)), "Manifest records post-GO execution")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_659 - Frontier Probe Decision Drill F6 Evidence", "Manifest recommends TASK_659")

	scene.queue_free()
	await _wait_frames(2)


func _build_manifest(before_go: Dictionary, after_go: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_one_screen_player_decision_drill_manifest.v1",
		"task_id": "TASK_658",
		"source_task_ids": PackedStringArray(["TASK_540", "TASK_541", "TASK_567", "TASK_657"]),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"before_go_stage": String(before_go.get("decision_stage", "")),
		"after_go_stage": String(after_go.get("decision_stage", "")),
		"next_token": String(before_go.get("next_token", "")),
		"recommended_plan": Dictionary(before_go.get("recommended_plan", {})),
		"before_go_ready": bool(before_go.get("go_ready", false)),
		"after_go_execution_active": bool(after_go.get("execution_active", false)),
		"before_checks": Array(before_go.get("checks", [])),
		"after_checks": Array(after_go.get("checks", [])),
		"manual_review_required": true,
		"manual_review_done": false,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"recommended_next_task": "TASK_659 - Frontier Probe Decision Drill F6 Evidence",
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


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")).strip_edges() == check_id:
			return bool(check.get("passed", false))
	return false


func _get_simulation_command_queue_count(simulation_root: Node) -> int:
	if simulation_root == null:
		return 0
	var command_queue_variant: Variant = simulation_root.get("command_queue")
	if typeof(command_queue_variant) == TYPE_ARRAY:
		return Array(command_queue_variant).size()
	return 0


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_658 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


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
