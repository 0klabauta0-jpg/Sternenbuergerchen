extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_653_frontier_probe_one_screen_playability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MANIFEST_PATH: String = "res://tmp/frontier_probe_one_screen_playability_pass.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_653 Frontier Probe One-Screen Playability Pass ===")
	_test_docs_and_contract()
	await _test_start_state_one_screen_playability()
	await _test_completed_state_points_to_debrief()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_653: FAILED")
		quit(1)
		return
	print("TASK_653: ALL PASSED")
	quit(0)


func _test_docs_and_contract() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_653 task file exists")
	_assert(task_text.contains("Frontier Probe One-Screen Playability Pass"), "TASK_653 task names one-screen playability")
	_assert(status_text.contains("TASK_653 - Frontier Probe One-Screen Playability Pass"), "Implementation status tracks TASK_653")
	_assert(roadmap_text.contains("TASK_653 - Frontier Probe One-Screen Playability Pass (implementiert)"), "Roadmap marks TASK_653 implemented")
	_assert(contract_text.contains("Frontier-Probe-One-Screen-Playability-Pass"), "Mission feedback contract documents TASK_653")
	_assert(report_text.contains("TASK_653 - Frontier Probe One-Screen Playability Pass"), "Current handbook report tracks TASK_653")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook export records latest task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook recommends a follow-up task")
	_assert(controller_text.contains("get_frontier_probe_one_screen_playability_snapshot"), "Controller exposes TASK_653 snapshot")
	_assert(controller_text.contains("frontier_probe_one_screen_line"), "Command feedback exports TASK_653 line")


func _test_start_state_one_screen_playability() -> void:
	var scene: Node = await _build_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Start scene exposes controller, combat driver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_frontier_probe_scene(scene, controller, combat_driver, simulation_root)
	var snapshot: Dictionary = await _capture_one_screen_snapshot(controller)
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var readout: Dictionary = Dictionary(snapshot.get("readout", {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_playability.v1", "TASK_653 snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_653", "Snapshot records TASK_653")
	_assert(String(snapshot.get("gate", "")) == "pass", "Start one-screen playability gate passes")
	_assert(String(readout.get("next_token", "")) == "AA", "Start state points to AA first")
	_assert(String(snapshot.get("one_screen_line", "")).contains("PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA"), "Start one-screen line is compact")
	_assert(String(snapshot.get("mission_control_status_text", "")).contains(String(snapshot.get("one_screen_line", ""))), "Mission Control contains one-screen line")
	_assert(String(command_feedback.get("frontier_probe_one_screen_line", "")) == String(snapshot.get("one_screen_line", "")), "Command feedback exports one-screen line")
	_assert(int(snapshot.get("valid_plan_count", 0)) >= 2, "Start state exposes at least two valid plan options")
	_assert(_check_passed(snapshot, "mission_control_plan_line_visible"), "Mission Control plan line check passes")
	_assert(_check_passed(snapshot, "two_valid_plans_available"), "Two-plan check passes")
	_assert(_check_passed(snapshot, "read_only"), "Read-only check passes")
	_assert(bool(snapshot.get("manual_review_required", false)), "Snapshot requires manual playtest review")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Snapshot does not claim manual review done")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not set gameplay truth")
	_write_manifest({"start_state": snapshot})

	scene.queue_free()
	await _wait_frames(2)


func _test_completed_state_points_to_debrief() -> void:
	var scene: Node = await _build_scene()
	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Completed scene exposes controller, combat driver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_frontier_probe_scene(scene, controller, combat_driver, simulation_root)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "cargo_touchdown_extract", "cargo_departed")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	var snapshot: Dictionary = await _capture_one_screen_snapshot(controller)
	var readout: Dictionary = Dictionary(snapshot.get("readout", {}))
	var handoff: Dictionary = Dictionary(snapshot.get("handoff", {}))
	_assert(String(snapshot.get("gate", "")) == "pass", "Completed one-screen playability gate passes")
	_assert(String(readout.get("next_token", "")) == "DEBRIEF", "Completed state points to Debrief")
	_assert(String(snapshot.get("one_screen_line", "")).contains("Debrief ready"), "Completed one-screen line names Debrief")
	_assert(bool(handoff.get("handoff_ready", false)), "Completed state keeps handoff ready")
	_assert(_check_passed(snapshot, "complete_route_points_to_debrief"), "Completed route points to Debrief check passes")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_654 - Frontier Probe One-Screen F6 Playtest Notes", "Snapshot recommends TASK_654")
	_write_manifest({"completed_state": snapshot})
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_653 manifest is written")

	scene.queue_free()
	await _wait_frames(2)


func _build_scene() -> Node:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	return scene


func _prepare_frontier_probe_scene(scene: Node, controller: Node, combat_driver: Node, simulation_root: Node) -> void:
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
	combat_driver.call("set_mission_cargo_touchdown_state", "blocked")
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")


func _capture_one_screen_snapshot(controller: Node) -> Dictionary:
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(4)
	return Dictionary(controller.call("get_frontier_probe_one_screen_playability_snapshot")).duplicate(true)


func _configure_scene(scene: Node) -> void:
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


func _write_manifest(partial: Dictionary) -> void:
	var manifest: Dictionary = {}
	if FileAccess.file_exists(MANIFEST_PATH):
		manifest = _read_json(MANIFEST_PATH)
	for key in partial.keys():
		manifest[key] = partial[key]
	manifest["schema"] = "sternenbuergerchen.frontier_probe_one_screen_playability_pass_manifest.v1"
	manifest["task_id"] = "TASK_653"
	manifest["manifest_path"] = ProjectSettings.globalize_path(MANIFEST_PATH)
	manifest["read_only"] = true
	manifest["ui_sets_gameplay_truth"] = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_653 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


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
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame
