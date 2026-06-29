extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_566_frontier_probe_multiplayer_f6_hover_panel_polish_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const PRESENTER_PATH: String = "res://scripts/mission/mission_team_chip_presenter.gd"
const TASK_557_TEST_PATH: String = "res://scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd"
const TASK_560_TEST_PATH: String = "res://scripts/tests/task_560_frontier_probe_multiplayer_teamchip_tooltip_polish.gd"
const TASK_565_TEST_PATH: String = "res://scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_566 Frontier Probe Multiplayer F6 Hover And Panel Polish Pass ===")
	_test_docs_and_wiring()
	await _test_hover_panel_polish_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_566: FAILED")
		quit(1)
		return
	print("TASK_566: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	var presenter_text: String = _read_text(PRESENTER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_566 task file exists")
	_assert(task_text.contains("Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "TASK_566 task file names the task")
	_assert(status_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Implementation status tracks TASK_566")
	_assert(roadmap_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass (implementiert)"), "Roadmap marks TASK_566 implemented")
	_assert(roadmap_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Roadmap names TASK_567 follow-up")
	_assert(contract_text.contains("Frontier-Probe-Multiplayer-F6-Hover-Panel-Polish"), "Mission feedback contract documents TASK_566")
	_assert(report_text.contains("TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass"), "Review workbench tracks TASK_566")
	_assert(report_text.contains("TASK_567 - Frontier Probe First Move Threat Preview Readability Pass"), "Review workbench names TASK_567 follow-up")
	_assert(controller_text.contains("get_frontier_probe_multiplayer_f6_hover_panel_polish_snapshot"), "TacticalController exposes TASK_566 snapshot")
	_assert(controller_text.contains("mission_team_chip_panel_polish_task"), "TacticalController tags Teamchip panel polish")
	_assert(presenter_text.contains("_compact_owner_label"), "MissionTeamChipPresenter keeps compact owner labels")
	_assert(FileAccess.file_exists(TASK_557_TEST_PATH), "TASK_557 readability verifier remains available")
	_assert(FileAccess.file_exists(TASK_560_TEST_PATH), "TASK_560 teamchip tooltip verifier remains available")
	_assert(FileAccess.file_exists(TASK_565_TEST_PATH), "TASK_565 real screenshot verifier remains available")


func _test_hover_panel_polish_snapshot() -> void:
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
	_assert(controller != null and combat_driver != null and simulation_root != null, "Mission scene exposes Controller, CombatDriver and SimulationRoot")
	if controller == null or combat_driver == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for hover/panel polish")
	if friendly_units.size() < 2:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 5), "blue")
	controller.call("_set_selected_fireteams", PackedStringArray(["blue"]), false)

	var objective_status = simulation_root.call("get_objective_status") if simulation_root.has_method("get_objective_status") else null
	_assert(objective_status != null, "SimulationRoot exposes ObjectiveStatus")
	if objective_status == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	objective_status.owning_team_id = "team_alpha"
	objective_status.capturing_team_id = "team_alpha"
	objective_status.capture_progress = 1.0

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures frontier probe scenario gates")
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	combat_driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("select_tile_from_world_position_for_test", objective_status.position)
	controller.call("_refresh_button_state")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(12)
	controller.call("_update_ui")
	await _wait_frames(4)

	_assert(controller.has_method("get_frontier_probe_multiplayer_f6_hover_panel_polish_snapshot"), "Controller exposes TASK_566 runtime snapshot")
	var snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_multiplayer_f6_hover_panel_polish_snapshot"))
	var compact_text: String = String(snapshot.get("mission_team_chip_text", "")).strip_edges()
	var tooltip_text: String = String(snapshot.get("mission_team_chip_tooltip_text", "")).strip_edges()
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_566 hover/panel polish snapshot passes")
	_assert(_check_passed(snapshot, "teamchip_tooltip_gate_passes"), "TASK_560 tooltip gate remains green inside TASK_566")
	_assert(_check_passed(snapshot, "visible_teamchip_line_is_short"), "Visible Teamchip line is compact")
	_assert(_check_passed(snapshot, "tooltip_keeps_full_multiplayer_context"), "Teamchip tooltip keeps full MP context")
	_assert(_check_passed(snapshot, "teamchip_single_line_panel_fit"), "Teamchip is configured as a one-line panel hint")
	_assert(_check_passed(snapshot, "bottom_panels_leave_world_readable"), "Bottom panels leave the tactical world readable")
	_assert(_check_passed(snapshot, "critical_panel_bounds_stay_green"), "Critical F6 panel bounds remain green")
	_assert(_check_passed(snapshot, "task566_style_tagged"), "Teamchip carries TASK_566 panel polish tag")
	_assert(_check_passed(snapshot, "read_only"), "TASK_566 snapshot remains read-only")
	_assert(compact_text.contains("Host") and compact_text.contains("P2") and not compact_text.contains("Host Peer 1"), "Visible Teamchip uses compact owner labels")
	_assert(tooltip_text.contains("Host Peer 1") and tooltip_text.contains("Peer 2"), "Tooltip keeps full owner labels")
	_assert(float(snapshot.get("bottom_hud_occlusion_ratio", 1.0)) <= 0.30, "Bottom HUD occlusion ratio stays under budget")

	scene.queue_free()
	await _wait_frames(2)


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


func _check_passed(snapshot: Dictionary, check_id: String) -> bool:
	for check_variant in Array(snapshot.get("checks", [])):
		var check: Dictionary = Dictionary(check_variant)
		if String(check.get("id", "")) == check_id:
			return bool(check.get("passed", false))
	return false


func _wait_frames(count: int) -> void:
	for _i in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _i in range(count):
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
