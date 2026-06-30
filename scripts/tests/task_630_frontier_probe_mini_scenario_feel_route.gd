extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const TASK_PATH: String = "res://docs/tasks/TASK_630_frontier_probe_mini_scenario_feel_route.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const HANDBOOK_PATH: String = "res://docs/reports/project_status_handbook_2026_06_29.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const MANIFEST_PATH: String = "res://tmp/frontier_probe_mini_scenario_feel_route.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_630 Frontier Probe Mini Scenario Feel Route ===")
	_test_docs_and_reports()
	await _test_frontier_probe_route_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_630: FAILED")
		quit(1)
		return
	print("TASK_630: ALL PASSED")
	quit(0)


func _test_docs_and_reports() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_630 task file exists")
	_assert(task_text.contains("Frontier Probe Mini Scenario Feel Route"), "TASK_630 task names mini scenario route")
	_assert(status_text.contains("TASK_630 - Frontier Probe Mini Scenario Feel Route"), "Implementation status tracks TASK_630")
	_assert(roadmap_text.contains("TASK_630 - Frontier Probe Mini Scenario Feel Route (implementiert)"), "Roadmap marks TASK_630 implemented")
	_assert(contract_text.contains("Frontier-Probe-Mini-Scenario-Feel-Route"), "Mission feedback contract documents TASK_630")
	_assert(controller_text.contains("get_frontier_probe_mini_scenario_feel_route_snapshot"), "Tactical controller exposes TASK_630 snapshot")
	_assert(report_text.contains("TASK_630 Frontier Probe Mini Scenario Feel Route"), "Rolling report tracks TASK_630")
	_assert(report_text.contains('latest_completed_task: "TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish"'), "Rolling report marks TASK_630 latest completed")
	_assert(handbook_text.contains("TASK_630 - Frontier Probe Mini Scenario Feel Route"), "Status handbook tracks TASK_630")
	_assert(handbook_text.contains('current_task: "TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish"'), "Status handbook current task is TASK_630")
	var required_export_keys: Array[String] = [
		"frontier_probe_mini_scenario_feel_route.task_id",
		"frontier_probe_mini_scenario_feel_route.manifest_path",
		"frontier_probe_mini_scenario_feel_route.route_id",
		"frontier_probe_mini_scenario_feel_route.route_beats",
		"frontier_probe_mini_scenario_feel_route.play_modes",
		"frontier_probe_mini_scenario_feel_route.aa_gate",
		"frontier_probe_mini_scenario_feel_route.computer_hold",
		"frontier_probe_mini_scenario_feel_route.cargo_gate",
		"frontier_probe_mini_scenario_feel_route.mission_control_line",
		"frontier_probe_mini_scenario_feel_route.manual_review_required",
		"frontier_probe_mini_scenario_feel_route.manual_review_done",
		"frontier_probe_mini_scenario_feel_route.read_only",
		"frontier_probe_mini_scenario_feel_route.recommended_next_task",
		"frontier_probe_mini_scenario_feel_route.notes",
	]
	for export_key in required_export_keys:
		_assert(report_text.contains('data-export-key="%s"' % export_key), "Rolling report exports %s" % export_key)
	_assert(report_text.contains('data-note-key="notes.frontier_probe_mini_scenario_feel_route"'), "Rolling report exports TASK_630 free note")
	_assert(handbook_text.contains('data-export-key="status.task_630_done"'), "Status handbook exports TASK_630 checkbox")


func _test_frontier_probe_route_snapshot() -> void:
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
	var snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_mini_scenario_feel_route_snapshot"))
	_write_manifest(snapshot)
	_assert(String(snapshot.get("schema", "")) == "sternenbuergerchen.frontier_probe_mini_scenario_feel_route.v1", "TASK_630 snapshot schema is stable")
	_assert(String(snapshot.get("task_id", "")) == "TASK_630", "Snapshot records TASK_630")
	_assert(String(snapshot.get("gate", "")) == "pass", "Mini scenario feel route gate passes")
	_assert(int(snapshot.get("route_beat_count", 0)) >= 4, "Route exposes approach, AA, computer and cargo beats")
	_assert(_check_passed(snapshot, "scenario_data_present"), "Scenario data present check passes")
	_assert(_check_passed(snapshot, "play_modes_cover_solo_coop_pvp"), "Solo/coop/PvP play modes check passes")
	_assert(_check_passed(snapshot, "route_beats_cover_mission_loop"), "Route beat check passes")
	_assert(_check_passed(snapshot, "alpha_bravo_roles_readable"), "Team role readability check passes")
	_assert(_check_passed(snapshot, "aa_threat_blocks_cargo"), "AA threat block check passes")
	_assert(_check_passed(snapshot, "computer_hold_has_playable_timer"), "Computer hold timer check passes")
	_assert(_check_passed(snapshot, "cargo_returns_to_alpha_lz"), "Cargo Alpha LZ check passes")
	_assert(_check_passed(snapshot, "integrated_objective_and_cargo_green"), "Integrated objective/cargo gate check passes")
	_assert(_check_passed(snapshot, "mission_control_names_route_outcome"), "Mission Control route line check passes")
	_assert(_check_passed(snapshot, "read_only"), "Read-only check passes")
	_assert(bool(snapshot.get("manual_review_required", false)), "Snapshot requires manual playfeel review")
	_assert(not bool(snapshot.get("manual_review_done", true)), "Snapshot does not claim manual review done")
	_assert(bool(snapshot.get("read_only", false)), "Snapshot remains read-only")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Snapshot does not set gameplay truth")
	_assert(String(snapshot.get("recommended_next_task", "")) == "TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish", "Snapshot recommends TASK_631")
	_assert(FileAccess.file_exists(MANIFEST_PATH), "TASK_630 manifest is written")

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
		_assert(false, "Can open TASK_630 manifest for writing")
		return
	file.store_string(JSON.stringify(snapshot, "\t"))
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
