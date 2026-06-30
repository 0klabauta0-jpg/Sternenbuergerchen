extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_655_frontier_probe_one_screen_visual_tuning_findings.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CURRENT_REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/frontier_probe_one_screen_visual_tuning_findings.json"
const EXPECTED_ONE_SCREEN_LINE: String = "PLAN LZ -> AA -> COM 18s -> CARGO | NEXT AA"
const REDUNDANT_NEXT_LINE: String = "NEXT AA ausschalten | Cargo blockiert"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_655 Frontier Probe One-Screen Visual Tuning Findings ===")
	_test_docs_and_report()
	await _test_visual_tuning_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_655: FAILED")
		quit(1)
		return
	print("TASK_655: ALL PASSED")
	quit(0)


func _test_docs_and_report() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(CURRENT_REPORT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_655 task file exists")
	_assert(task_text.contains("Frontier Probe One-Screen Visual Tuning Findings"), "TASK_655 task names visual tuning findings")
	_assert(status_text.contains("TASK_655 - Frontier Probe One-Screen Visual Tuning Findings"), "Implementation status tracks TASK_655")
	_assert(roadmap_text.contains("TASK_655 - Frontier Probe One-Screen Visual Tuning Findings (implementiert)"), "Roadmap marks TASK_655 implemented")
	_assert(contract_text.contains("Frontier-Probe-One-Screen-Visual-Tuning-Findings"), "Mission feedback contract documents TASK_655")
	_assert(report_text.contains("TASK_655 - Frontier Probe One-Screen Visual Tuning Findings"), "Current handbook report tracks TASK_655")
	_assert(report_text.contains("latest_completed_task:"), "Current handbook export records latest task")
	_assert(report_text.contains("recommended_next_task:"), "Current handbook recommends a follow-up task")
	_assert(report_text.contains('data-export-key="status.task_655_done"'), "Current handbook exports TASK_655 done status")
	_assert(report_text.contains('data-export-key="one_screen_visual_tuning.duplicate_next_line_suppressed"'), "Current handbook exports duplicate NEXT check")
	_assert(report_text.contains('data-note-key="notes.one_screen_visual_tuning"'), "Current handbook exports TASK_655 notes")
	_assert(controller_text.contains("get_frontier_probe_one_screen_visual_tuning_snapshot"), "Controller exposes TASK_655 snapshot")


func _test_visual_tuning_snapshot() -> void:
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
	var snapshot: Dictionary = await _capture_visual_tuning_snapshot(controller)
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var mission_control_text: String = String(snapshot.get("mission_control_status_text", ""))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_visual_tuning.v1", "TASK_655 snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_655", "Snapshot records TASK_655")
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_655 visual tuning gate passes")
	_assert(mission_control_text.contains(EXPECTED_ONE_SCREEN_LINE), "Mission Control keeps one-screen line visible")
	_assert(not mission_control_text.contains(REDUNDANT_NEXT_LINE), "Mission Control suppresses redundant NEXT detail line")
	_assert(String(command_feedback.get("frontier_probe_next_interaction_line", "")) == REDUNDANT_NEXT_LINE, "Command feedback still exports NEXT detail line")
	_assert(bool(snapshot.get("duplicate_next_should_be_suppressed", false)), "Snapshot expects duplicate NEXT suppression")
	_assert(bool(snapshot.get("duplicate_next_line_suppressed", false)), "Snapshot reports duplicate NEXT suppressed")
	_assert(bool(snapshot.get("command_feedback_keeps_next_contract", false)), "Snapshot preserves NEXT command feedback contract")
	_assert(bool(snapshot.get("line_within_limit", false)), "Snapshot reports one-screen line within limit")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not set gameplay truth")
	var manifest: Dictionary = _build_manifest(snapshot, command_feedback)
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_655 manifest is written")
	_assert(String(manifest.get("schema", "")) == "sternenbuergerchen.frontier_probe_one_screen_visual_tuning_findings.v1", "Manifest uses TASK_655 schema")
	_assert(bool(manifest.get("duplicate_next_line_suppressed", false)), "Manifest records duplicate NEXT suppression")
	_assert(bool(manifest.get("command_feedback_keeps_next_contract", false)), "Manifest records preserved NEXT export")
	_assert(bool(manifest.get("one_screen_line_within_limit", false)), "Manifest records corrected one-screen line budget")
	_assert(String(manifest.get("recommended_next_task", "")) == "TASK_656 - Frontier Probe Real F6 Visual Review", "Manifest recommends TASK_656")

	scene.queue_free()
	await _wait_frames(2)


func _capture_visual_tuning_snapshot(controller: Node) -> Dictionary:
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(4)
	return Dictionary(controller.call("get_frontier_probe_one_screen_visual_tuning_snapshot")).duplicate(true)


func _build_manifest(snapshot: Dictionary, command_feedback: Dictionary) -> Dictionary:
	return {
		"schema": "sternenbuergerchen.frontier_probe_one_screen_visual_tuning_findings.v1",
		"task_id": "TASK_655",
		"source_task_ids": PackedStringArray(["TASK_653", "TASK_654"]),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
		"one_screen_line": String(snapshot.get("one_screen_line", "")),
		"next_interaction_line": String(snapshot.get("next_interaction_line", "")),
		"mission_control_contains_one_screen_line": String(snapshot.get("mission_control_status_text", "")).contains(EXPECTED_ONE_SCREEN_LINE),
		"mission_control_contains_redundant_next_line": String(snapshot.get("mission_control_status_text", "")).contains(REDUNDANT_NEXT_LINE),
		"duplicate_next_should_be_suppressed": bool(snapshot.get("duplicate_next_should_be_suppressed", false)),
		"duplicate_next_line_suppressed": bool(snapshot.get("duplicate_next_line_suppressed", false)),
		"command_feedback_keeps_next_contract": bool(snapshot.get("command_feedback_keeps_next_contract", false)),
		"command_feedback_next_line": String(command_feedback.get("frontier_probe_next_interaction_line", "")),
		"one_screen_line_within_limit": bool(snapshot.get("line_within_limit", false)),
		"one_screen_line_char_count": int(snapshot.get("line_char_count", 0)),
		"one_screen_line_char_limit": int(snapshot.get("line_char_limit", 0)),
		"checks": Array(snapshot.get("checks", [])),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_review_required": true,
		"manual_review_done": false,
		"recommended_next_task": "TASK_656 - Frontier Probe Real F6 Visual Review",
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


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_655 manifest for writing")
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
