extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH := "res://docs/tasks/TASK_1171_first_move_execution_feedback_release_recapture.md"
const STATUS_PATH := "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH := "res://docs/TASK_ROADMAP.md"
const COMMAND_CONTRACT_PATH := "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH := "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH := "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH := "res://maps/station_outpost_192x192.json"
const SCHEMA := "sternenbuergerchen.mission_first_move_execution_feedback_release_recapture.v1"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1171 First Move Execution Feedback Release Recapture ===")
	_test_docs_and_static_hooks()
	await _test_first_move_execution_release_recapture_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_1171: FAILED")
		quit(1)
		return
	print("TASK_1171: ALL PASSED")
	quit(0)


func _test_docs_and_static_hooks() -> void:
	var task_text := _read_text(TASK_PATH)
	var status_text := _read_text(STATUS_PATH)
	var roadmap_text := _read_text(ROADMAP_PATH)
	var contract_text := _read_text(COMMAND_CONTRACT_PATH)
	var controller_text := _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK 1171 task document exists")
	_assert(task_text.contains("First Move Execution Feedback Release Recapture"), "Task document names TASK 1171")
	_assert(task_text.contains("get_mission_first_move_execution_feedback_release_recapture_snapshot"), "Task document names snapshot contract")
	_assert(status_text.contains("TASK_1171 - First Move Execution Feedback Release Recapture"), "Implementation status tracks TASK 1171")
	_assert(roadmap_text.contains("TASK_1171 - First Move Execution Feedback Release Recapture"), "Roadmap tracks TASK 1171")
	_assert(contract_text.contains("get_mission_first_move_execution_feedback_release_recapture_snapshot"), "Mission feedback contract documents TASK 1171")
	_assert(controller_text.contains("get_mission_first_move_execution_feedback_release_recapture_snapshot"), "Controller exposes TASK 1171 snapshot")


func _test_first_move_execution_release_recapture_snapshot() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null and simulation_root != null, "Mission fixture exposes TacticalController and SimulationRoot")
	if controller == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(controller.has_method("get_mission_first_move_execution_feedback_release_recapture_snapshot"), "Controller has TASK 1171 public snapshot method")
	if not controller.has_method("get_mission_first_move_execution_feedback_release_recapture_snapshot"):
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 3, "Mission fixture exposes Alpha units for execution recapture")
	if friendly_units.size() < 3:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	_mark_units_deployed(controller, friendly_units.slice(0, 5))
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)

	var move_target := Vector2(544.0, 288.0)
	_assert(bool(controller.call("issue_right_click_command_for_test", move_target, "move", false)), "Move order can be planned through existing preview path")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_frames(8)
	var preview_snapshot: Dictionary = Dictionary(controller.call("get_mission_first_move_decision_preview_release_recapture_snapshot"))
	_assert(String(preview_snapshot.get("status", "")) == "recaptured", "TASK 1170 preview recapture is green before GO")

	_assert(bool(controller.call("execute_selected_fireteam_orders")), "GO executes the planned first move order")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_order_visuals")
	controller.call("_refresh_button_state")
	controller.call("_update_ui")
	await _wait_physics_frames(2)
	await _wait_frames(4)

	var command_count_before := Array(simulation_root.get("command_queue")).size()
	var effect_count_before := Array(simulation_root.get("effects_queue")).size()
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_first_move_execution_feedback_release_recapture_snapshot"))
	_assert(String(snapshot.get("schema", "")) == SCHEMA, "Snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_1171", "Snapshot identifies TASK 1171")
	_assert(String(snapshot.get("source_task_id", "")) == "TASK_1170", "Snapshot links TASK 1170")
	_assert(String(snapshot.get("status", "")) == "recaptured", "Snapshot recaptures first-move execution")
	_assert(bool(snapshot.get("ready_for_first_contact_recapture", false)), "Snapshot opens first-contact recapture")
	_assert(_snapshot_is_read_only(snapshot), "TASK 1171 snapshot remains read-only")
	_assert(Array(simulation_root.get("command_queue")).size() == command_count_before, "TASK 1171 snapshot enqueues no extra command")
	_assert(Array(simulation_root.get("effects_queue")).size() == effect_count_before, "TASK 1171 snapshot enqueues no effect")

	var execution: Dictionary = Dictionary(snapshot.get("execution_feedback", {}))
	var preview_handoff: Dictionary = Dictionary(snapshot.get("preview_recapture", {}))
	var release: Dictionary = Dictionary(snapshot.get("release_provenance", {}))
	var capture: Dictionary = Dictionary(snapshot.get("capture_manifest", {}))
	_assert(String(preview_handoff.get("task_id", "")) == "TASK_1170", "TASK 1170 preview handoff source is read")
	_assert(bool(snapshot.get("preview_handoff_read", false)), "TASK 1171 links the TASK 1170 handoff")
	_assert(String(execution.get("gate", "")) == "pass", "TASK 541 execution feedback gate passes")
	_assert(bool(snapshot.get("go_executed_before_snapshot", false)), "GO happened before the read-only snapshot")
	_assert(bool(snapshot.get("movement_state_visible", false)), "Movement state is visible after GO")
	_assert(bool(snapshot.get("movement_target_visible", false)), "Movement target/progress data is visible after GO")
	_assert(bool(snapshot.get("running_feedback_visible", false)), "GO/running feedback is visible after GO")
	_assert(bool(snapshot.get("order_trace_visible", false)), "Order trace remains visible after GO")
	_assert(bool(release.get("matches_git_head", false)), "Release provenance matches Git HEAD")
	_assert(bool(capture.get("gate_passed", false)) and bool(capture.get("deployment_converged", false)), "Capture manifest proves deployed release context")
	_assert(Array(snapshot.get("accepted_surfaces", [])).has("first_move_execution_after_go"), "Accepted surfaces include execution after GO")
	_assert(String(snapshot.get("recommended_next_task", "")).begins_with("TASK_1172"), "Snapshot recommends TASK 1172")

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


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and not bool(snapshot.get("creates_command", true)) \
		and not bool(snapshot.get("creates_effect", true)) \
		and not bool(snapshot.get("creates_fire_event", true)) \
		and not bool(snapshot.get("creates_damage_event", true)) \
		and not bool(snapshot.get("sets_multiplayer_truth", true))


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
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
