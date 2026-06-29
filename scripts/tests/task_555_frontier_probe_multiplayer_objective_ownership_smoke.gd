extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_520_TEST_PATH: String = "res://scripts/tests/task_520_multiplayer_team_ownership_smoke.gd"
const TASK_526_TEST_PATH: String = "res://scripts/tests/task_526_mission_hud_team_chip_polish.gd"
const TASK_554_TEST_PATH: String = "res://scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_555 Frontier Probe Multiplayer Objective Ownership Smoke ===")
	_test_docs_and_wiring()
	await _test_multiplayer_objective_ownership()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_555: FAILED")
		quit(1)
		return
	print("TASK_555: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_555 task file exists")
	_assert(_read_text(TASK_PATH).contains("Frontier Probe Multiplayer Objective Ownership Smoke"), "TASK_555 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke"), "Implementation status tracks TASK_555")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke (implementiert)"), "Roadmap marks TASK_555 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_555 - Frontier Probe Multiplayer Objective Ownership Smoke"), "Review workbench tracks TASK_555")
	_assert(_read_text(CONTRACT_PATH).contains("Frontier-Probe-Multiplayer-Objective-Ownership"), "Mission feedback contract documents TASK_555")
	_assert(_read_text(CONTROLLER_PATH).contains("get_frontier_probe_multiplayer_objective_ownership_snapshot"), "TacticalController exposes TASK_555 ownership snapshot")
	_assert(FileAccess.file_exists(TASK_520_TEST_PATH), "TASK_520 ownership verifier remains available")
	_assert(FileAccess.file_exists(TASK_526_TEST_PATH), "TASK_526 team chip verifier remains available")
	_assert(FileAccess.file_exists(TASK_554_TEST_PATH), "TASK_554 integrated objective verifier remains available")


func _test_multiplayer_objective_ownership() -> void:
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
	var primary_3d_view: Node = scene.get_node_or_null("Primary3DView")
	_assert(controller != null and combat_driver != null and simulation_root != null and primary_3d_view != null, "Mission scene exposes Controller, CombatDriver, SimulationRoot and Primary3DView")
	if controller == null or combat_driver == null or simulation_root == null or primary_3d_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes Alpha units for ownership smoke")
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
	controller.call("select_tile_from_world_position_for_test", objective_status.position)
	controller.call("_refresh_button_state")
	controller.call("_sync_primary_3d_mission_status_visuals")

	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("_refresh_world_overlays")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(8)
	controller.call("_update_ui")
	var ownership_snapshot: Dictionary = Dictionary(controller.call("get_frontier_probe_multiplayer_objective_ownership_snapshot"))
	_assert(String(ownership_snapshot.get("gate", "")) == "pass", "TASK_555 ownership snapshot passes")
	_assert(_check_passed(ownership_snapshot, "integrated_objective_gate_passes"), "Integrated TASK_554 gate remains green")
	_assert(_check_passed(ownership_snapshot, "team_slots_expose_alpha_bravo"), "Alpha and Bravo team slots are visible")
	_assert(_check_passed(ownership_snapshot, "alpha_is_player_assignable_attacker"), "Alpha is player-assignable attacker")
	_assert(_check_passed(ownership_snapshot, "bravo_is_npc_defender_but_pvp_assignable"), "Bravo is NPC defender and PvP assignable")
	_assert(_check_passed(ownership_snapshot, "pvp_assigns_alpha_host_and_bravo_peer"), "PvP resolves Alpha host and Bravo peer ownership")
	_assert(_check_passed(ownership_snapshot, "singleplayer_keeps_bravo_npc"), "Singleplayer keeps Bravo scenario-owned")
	_assert(_check_passed(ownership_snapshot, "mission_team_chip_names_both_owners"), "Mission team chip names both owners and spawns")
	_assert(_check_passed(ownership_snapshot, "objective_and_flow_steps_belong_to_alpha_path"), "Objective and cargo path belong to Alpha")
	_assert(_check_passed(ownership_snapshot, "bravo_air_defense_group_owns_aa_threat"), "Bravo owns AA threat group")
	_assert(_check_passed(ownership_snapshot, "read_only"), "TASK_555 ownership snapshot remains read-only")

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
