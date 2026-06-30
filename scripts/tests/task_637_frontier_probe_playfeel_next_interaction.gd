extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_637_frontier_probe_playfeel_next_interaction.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_playfeel_next_interaction.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_637 Frontier Probe Playfeel Next Interaction ===")
	_test_docs_and_reports()
	await _test_next_interaction_sequence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_637: FAILED")
		quit(1)
		return
	print("TASK_637: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_637 task file exists")
	_assert(task_text.contains("Frontier Probe Playfeel Next Interaction"), "TASK_637 task names playfeel next interaction")
	_assert(status_text.contains("TASK_637 - Frontier Probe Playfeel Next Interaction"), "Implementation status tracks TASK_637")
	_assert(roadmap_text.contains("TASK_637 - Frontier Probe Playfeel Next Interaction (implementiert)"), "Roadmap marks TASK_637 implemented")
	_assert(contract_text.contains("Frontier-Probe-Playfeel-Next-Interaction"), "Mission feedback contract documents TASK_637")
	_assert(controller_text.contains("get_frontier_probe_playfeel_next_interaction_snapshot"), "Controller exposes TASK_637 snapshot")
	_assert(report_text.contains("TASK_637 Frontier Probe Playfeel Next Interaction"), "Rolling report tracks TASK_637")
	_assert(report_text.contains("latest_completed_task:") and not report_text.contains('latest_completed_task: "TASK_637'), "Rolling report advances latest completed beyond TASK_637")
	_assert(handbook_text.contains("TASK_637 - Frontier Probe Playfeel Next Interaction"), "Status handbook tracks TASK_637")
	_assert(handbook_text.contains("current_task:") and not handbook_text.contains('current_task: "TASK_637'), "Status handbook current task advances beyond TASK_637")
	var required_export_keys: Array[String] = [
		"frontier_probe_playfeel_next_interaction.task_id",
		"frontier_probe_playfeel_next_interaction.manifest_path",
		"frontier_probe_playfeel_next_interaction.next_interaction_line",
		"frontier_probe_playfeel_next_interaction.next_interaction_id",
		"frontier_probe_playfeel_next_interaction.mission_control_contains_next",
		"frontier_probe_playfeel_next_interaction.sequence_ids",
		"frontier_probe_playfeel_next_interaction.read_only",
		"frontier_probe_playfeel_next_interaction.recommended_next_task",
		"frontier_probe_playfeel_next_interaction.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_playfeel_next_interaction"'), "Rolling report exports TASK_637 free note")
	_assert(handbook_text.contains('data-export-key="status.task_637_done"'), "Status handbook exports TASK_637 checkbox")


func _test_next_interaction_sequence() -> void:
	_ensure_output_dir()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes controller, combat driver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	_prepare_frontier_probe_scene(scene, controller, combat_driver, simulation_root)
	var snapshots: Array = []
	snapshots.append(await _capture_next_snapshot(controller, "aa_open"))
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	snapshots.append(await _capture_next_snapshot(controller, "aa_disabled"))
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_cargo_touchdown_state", "landed", 4.0)
	snapshots.append(await _capture_next_snapshot(controller, "computer_controlled"))
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	snapshots.append(await _capture_next_snapshot(controller, "cargo_departed"))

	var sequence_ids: PackedStringArray = PackedStringArray()
	for snapshot_variant in snapshots:
		var snapshot: Dictionary = Dictionary(snapshot_variant)
		var next_interaction: Dictionary = Dictionary(snapshot.get("next_interaction", {}))
		sequence_ids.append(String(next_interaction.get("next_interaction_id", "")))
	_assert(sequence_ids == PackedStringArray(["disable_air_defense", "hold_station_computer", "secure_cargo_touchdown", "open_debrief"]), "Next interaction follows AA, COM, CARGO, Debrief sequence")
	var final_snapshot: Dictionary = Dictionary(snapshots.back())
	var final_next: Dictionary = Dictionary(final_snapshot.get("next_interaction", {}))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(final_snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_playfeel_next_interaction.v1", "TASK_637 snapshot schema is stable")
	_assert(String(final_snapshot.get("gate", "")) == "pass", "TASK_637 final gate passes")
	_assert(String(final_next.get("next_interaction_line", "")).contains("NEXT Debrief"), "Completed route points to Debrief")
	_assert(String(final_snapshot.get("mission_control_status_text", "")).contains(String(final_next.get("next_interaction_line", ""))), "Mission Control includes NEXT line")
	_assert(String(command_feedback.get("frontier_probe_next_interaction_line", "")).contains("NEXT Debrief"), "Command feedback exports NEXT line")
	_assert(bool(final_next.get("line_within_limit", false)), "NEXT line stays compact")
	_assert(bool(final_snapshot.get("read_only", false)), "TASK_637 snapshot is read-only")
	_assert(not bool(final_snapshot.get("ui_sets_gameplay_truth", true)), "TASK_637 snapshot does not set gameplay truth")
	var manifest: Dictionary = _build_manifest(snapshots, sequence_ids)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_637 manifest is written")
	_assert(String(manifest.get("sequence_ids", "")) == "disable_air_defense -> hold_station_computer -> secure_cargo_touchdown -> open_debrief", "Manifest records full NEXT sequence")

	scene.queue_free()
	await _wait_frames(2)


func _capture_next_snapshot(controller: Node, stage_id: String) -> Dictionary:
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(3)
	var snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_playfeel_next_interaction_snapshot")).duplicate(true)
	snapshot["stage_id"] = stage_id
	return snapshot


func _build_manifest(snapshots: Array, sequence_ids: PackedStringArray) -> Dictionary:
	var final_snapshot: Dictionary = Dictionary(snapshots.back())
	var final_next: Dictionary = Dictionary(final_snapshot.get("next_interaction", {}))
	return {
		"schema": "sternenbuergerchen.frontier_probe_playfeel_next_interaction_manifest.v1",
		"task_id": "TASK_637",
		"snapshot_schema": String(final_snapshot.get("schema", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"sequence_ids": " -> ".join(sequence_ids),
		"next_interaction_id": String(final_next.get("next_interaction_id", "")),
		"next_interaction_line": String(final_next.get("next_interaction_line", "")),
		"mission_control_contains_next": String(final_snapshot.get("mission_control_status_text", "")).contains(String(final_next.get("next_interaction_line", ""))),
		"route_complete": bool(final_next.get("route_complete", false)),
		"playfeel_complete": bool(final_next.get("playfeel_complete", false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": false,
		"recommended_next_task": "TASK_638 - Frontier Probe Debrief Handoff Feel",
	}


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


func _ensure_output_dir() -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(OUTPUT_DIR)):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_637 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
