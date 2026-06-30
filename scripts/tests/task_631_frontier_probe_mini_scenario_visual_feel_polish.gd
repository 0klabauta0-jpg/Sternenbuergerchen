extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_631_frontier_probe_mini_scenario_visual_feel_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TERRAIN_VIEW_PATH: String = "res://scripts/terrain/terrain_map_3d_view.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MANIFEST_PATH: String = "res://tmp/frontier_probe_mini_scenario_visual_feel_polish.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_631 Frontier Probe Mini Scenario Visual Feel Polish ===")
	_test_docs_and_reports()
	await _test_visual_feel_polish_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_631: FAILED")
		quit(1)
		return
	print("TASK_631: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var terrain_view_text: String = _read_text(TERRAIN_VIEW_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_631 task file exists")
	_assert(task_text.contains("Frontier Probe Mini Scenario Visual Feel Polish"), "TASK_631 task names visual feel polish")
	_assert(status_text.contains("TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish"), "Implementation status tracks TASK_631")
	_assert(roadmap_text.contains("TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish (implementiert)"), "Roadmap marks TASK_631 implemented")
	_assert(contract_text.contains("Frontier-Probe-Mini-Scenario-Visual-Feel-Polish"), "Mission feedback contract documents TASK_631")
	_assert(controller_text.contains("get_frontier_probe_mini_scenario_visual_feel_polish_snapshot"), "Controller exposes TASK_631 snapshot")
	_assert(terrain_view_text.contains("route_callout_visual_count"), "Primary3D exposes route callout counters")
	_assert(report_text.contains("TASK_631 Frontier Probe Mini Scenario Visual Feel Polish"), "Rolling report tracks TASK_631")
	_assert(report_text.contains('latest_completed_task: "TASK_632 - Frontier Probe Mini Scenario F6 Visual Review"'), "Rolling report advances latest completed beyond TASK_631")
	_assert(handbook_text.contains("TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish"), "Status handbook tracks TASK_631")
	_assert(handbook_text.contains('current_task: "TASK_632 - Frontier Probe Mini Scenario F6 Visual Review"'), "Status handbook current task advances beyond TASK_631")
	var required_export_keys: Array[String] = [
		"frontier_probe_mini_scenario_visual_feel_polish.task_id",
		"frontier_probe_mini_scenario_visual_feel_polish.manifest_path",
		"frontier_probe_mini_scenario_visual_feel_polish.route_callouts",
		"frontier_probe_mini_scenario_visual_feel_polish.route_summary",
		"frontier_probe_mini_scenario_visual_feel_polish.primary_3d_count",
		"frontier_probe_mini_scenario_visual_feel_polish.tone_counts",
		"frontier_probe_mini_scenario_visual_feel_polish.mission_control_line",
		"frontier_probe_mini_scenario_visual_feel_polish.manual_review_required",
		"frontier_probe_mini_scenario_visual_feel_polish.manual_review_done",
		"frontier_probe_mini_scenario_visual_feel_polish.read_only",
		"frontier_probe_mini_scenario_visual_feel_polish.recommended_next_task",
		"frontier_probe_mini_scenario_visual_feel_polish.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_mini_scenario_visual_feel_polish"'), "Rolling report exports TASK_631 free note")
	_assert(handbook_text.contains('data-export-key="status.task_631_done"'), "Status handbook exports TASK_631 checkbox")


func _test_visual_feel_polish_snapshot() -> void:
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

	_prepare_completed_route(scene, controller, combat_driver, simulation_root)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_mini_scenario_visual_feel_polish_snapshot"))
	_write_manifest(snapshot)
	var primary_3d: Dictionary = Dictionary(snapshot.get("primary_3d", {}))
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_mini_scenario_visual_feel_polish.v1", "TASK_631 snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_631", "Snapshot records TASK_631")
	_assert(String(snapshot.get("gate", "")) == "pass", "Visual feel polish gate passes")
	_assert(int(snapshot.get("route_callout_count", 0)) >= 4, "Snapshot exposes four route callouts")
	_assert(_check_passed(snapshot, "route_callouts_cover_all_beats"), "Callout coverage check passes")
	_assert(_check_passed(snapshot, "callout_tones_are_distinct"), "Tone distinction check passes")
	_assert(_check_passed(snapshot, "primary_3d_receives_route_callouts"), "Primary3D route callout check passes")
	_assert(_check_passed(snapshot, "mission_control_route_summary_is_compact"), "Mission Control compact route check passes")
	_assert(_check_passed(snapshot, "visual_polish_read_only"), "Read-only visual polish check passes")
	_assert(_has_callout(snapshot, "LZ", "safe", "spawn_alpha"), "LZ callout is safe and targets Alpha spawn")
	_assert(_has_callout(snapshot, "AA", "danger", "factory_danger_zone"), "AA callout is danger and targets factory danger zone")
	_assert(_has_callout(snapshot, "COM 18s", "objective", "objective_point"), "Computer callout names 18 second hold")
	_assert(_has_callout(snapshot, "CARGO", "cargo", "spawn_alpha"), "Cargo callout returns to Alpha LZ")
	_assert(int(primary_3d.get("route_callout_visual_count", 0)) >= 4, "Primary3D render snapshot counts route callout visuals")
	_assert(String(primary_3d.get("route_callout_summary", "")).contains("LZ -> AA -> COM 18s -> CARGO"), "Primary3D render snapshot exposes route summary")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_631 snapshot does not set gameplay truth")
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_631 manifest is written")

	scene.queue_free()
	await _wait_frames(2)


func _prepare_completed_route(scene: Node, controller: Node, combat_driver: Node, simulation_root: Node) -> void:
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


func _write_manifest(snapshot: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_631 manifest for writing")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
	file.close()


func _has_callout(snapshot: Dictionary, short_label: String, tone: String, marker_id: String) -> bool:
	for callout_variant in Array(snapshot.get("route_callouts", [])):
		var callout: Dictionary = Dictionary(callout_variant)
		if String(callout.get("short_label", "")).strip_edges() == short_label:
			return String(callout.get("tone", "")).strip_edges() == tone and String(callout.get("target_marker_id", "")).strip_edges() == marker_id
	return false


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
