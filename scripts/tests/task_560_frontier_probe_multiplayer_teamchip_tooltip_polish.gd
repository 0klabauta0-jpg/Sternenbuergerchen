extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_557_TEST_PATH: String = "res://scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_560 Frontier Probe Multiplayer Teamchip Tooltip Polish ===")
	_test_docs_and_wiring()
	await _test_frontier_probe_multiplayer_teamchip_tooltip()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_560: FAILED")
		quit(1)
		return
	print("TASK_560: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_560 task file exists")
	_assert(_read_text(TASK_PATH).contains("Frontier Probe Multiplayer Teamchip Tooltip Polish"), "TASK_560 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish"), "Implementation status tracks TASK_560")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish (implementiert)"), "Roadmap marks TASK_560 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_560 - Frontier Probe Multiplayer Teamchip Tooltip Polish"), "Review workbench tracks TASK_560")
	_assert(_read_text(CONTRACT_PATH).contains("Frontier-Probe-Multiplayer-Teamchip-Tooltip-Polish"), "Mission feedback contract documents TASK_560")
	_assert(_read_text(CONTROLLER_PATH).contains("get_frontier_probe_multiplayer_teamchip_tooltip_snapshot"), "TacticalController exposes TASK_560 tooltip snapshot")
	_assert(_read_text(CONTROLLER_PATH).contains("mission_team_chip_tooltip_hint_v1"), "TacticalController tags the teamchip tooltip style")
	_assert(FileAccess.file_exists(TASK_557_TEST_PATH), "TASK_557 F6 readability verifier remains available")


func _test_frontier_probe_multiplayer_teamchip_tooltip() -> void:
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
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for tooltip smoke")
	if friendly_units.size() < 2:
		scene.queue_free()
		await _wait_frames(2)
		return
	_assign_fireteam_ids(friendly_units.slice(0, 2), "blue")
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
	await _wait_frames(8)
	controller.call("_update_ui")

	var tooltip_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_multiplayer_teamchip_tooltip_snapshot"))
	_assert(String(tooltip_snapshot.get("gate", "")) == "pass", "TASK_560 teamchip tooltip snapshot passes")
	_assert(_check_passed(tooltip_snapshot, "f6_readability_gate_passes"), "TASK_557 F6 readability remains green inside TASK_560")
	_assert(_check_passed(tooltip_snapshot, "mission_team_chip_tooltip_hoverable"), "Mission team chip is hoverable")
	_assert(_check_passed(tooltip_snapshot, "mission_team_chip_tooltip_names_multiplayer_context"), "Mission team chip tooltip names Host/Peer and spawns")
	_assert(_check_passed(tooltip_snapshot, "mission_team_chip_visible_text_stays_compact"), "Mission team chip visible text stays compact")
	_assert(_check_passed(tooltip_snapshot, "mission_team_chip_tooltip_style_tagged"), "Mission team chip tooltip style is tagged")
	_assert(_check_passed(tooltip_snapshot, "read_only"), "TASK_560 tooltip snapshot remains read-only")

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
