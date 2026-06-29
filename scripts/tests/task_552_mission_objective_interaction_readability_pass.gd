extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TASK_PATH: String = "res://docs/tasks/TASK_552_mission_objective_interaction_readability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const TASK_518_TEST_PATH: String = "res://scripts/tests/task_518_mission_scenario_runtime_gates.gd"
const TASK_551_TEST_PATH: String = "res://scripts/tests/task_551_combat_hud_tooltip_style_polish.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_552 Mission Objective Interaction Readability Pass ===")
	_test_docs_and_wiring()
	await _test_objective_interaction_readability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_552: FAILED")
		quit(1)
		return
	print("TASK_552: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_552 task file exists")
	_assert(_read_text(TASK_PATH).contains("Mission Objective Interaction Readability Pass"), "TASK_552 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_552 - Mission Objective Interaction Readability Pass"), "Implementation status tracks TASK_552")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_552 - Mission Objective Interaction Readability Pass (implementiert)"), "Roadmap marks TASK_552 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_552 - Mission Objective Interaction Readability Pass"), "Review workbench tracks TASK_552")
	_assert(_read_text(CONTRACT_PATH).contains("Mission-Objective-Interaction-Readability"), "Mission feedback contract documents TASK_552")
	_assert(_read_text(CONTROLLER_PATH).contains("get_mission_objective_interaction_readability_snapshot"), "TacticalController exposes TASK_552 readability snapshot")
	_assert(FileAccess.file_exists(TASK_518_TEST_PATH), "TASK_518 runtime gate verifier remains available")
	_assert(FileAccess.file_exists(TASK_551_TEST_PATH), "TASK_551 combat HUD tooltip verifier remains available")


func _test_objective_interaction_readability() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(10)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	var primary_3d_view: Node = scene.get_node_or_null("Primary3DView")
	_assert(controller != null and combat_driver != null and simulation_root != null and primary_3d_view != null, "Mission scene exposes Controller, CombatDriver, SimulationRoot and Primary3DView")
	if controller == null or combat_driver == null or simulation_root == null or primary_3d_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var friendly_units: Array = _collect_team_units(scene, "team_alpha")
	_assert(friendly_units.size() >= 2, "Mission scene exposes at least two Alpha units")
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

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures frontier probe runtime gates")
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var gate_snapshot: Dictionary = Dictionary(combat_driver.call("get_mission_scenario_runtime_gate_snapshot"))
	_assert(_gate_status(gate_snapshot, "occupy_station_computer") == "active", "Computer hold gate becomes active when Alpha owns the objective")

	var selected_tile: Dictionary = Dictionary(controller.call("select_tile_from_world_position_for_test", objective_status.position))
	_assert(bool(selected_tile.get("has_selected_tile", false)), "Verifier can select the objective tile")

	controller.call("_refresh_button_state")
	controller.call("_sync_primary_3d_mission_status_visuals")
	controller.call("_update_ui")
	await _wait_frames(8)
	controller.call("_update_ui")

	var snapshot: Dictionary = Dictionary(controller.call("get_mission_objective_interaction_readability_snapshot"))
	_assert(String(snapshot.get("gate", "")) == "pass", "TASK_552 snapshot gate passes")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "TASK_552 snapshot is read-only")
	_assert(String(snapshot.get("objective_interaction_line", "")).contains("COM") and String(snapshot.get("objective_interaction_line", "")).contains("OBJ"), "Objective interaction line names COM and OBJ")
	_assert(_check_passed(snapshot, "take_control_visible"), "Take control is visible")
	_assert(_check_passed(snapshot, "selected_tile_targets_objective"), "Selected tile targets the objective")
	_assert(_check_passed(snapshot, "objective_state_available"), "Objective state is available")
	_assert(_check_passed(snapshot, "scenario_gates_visible"), "Scenario gates are visible")
	_assert(_check_passed(snapshot, "computer_gate_readable"), "Computer gate is readable")
	_assert(_check_passed(snapshot, "mission_control_names_objective_interaction"), "Mission Control displays objective interaction line")
	_assert(_check_passed(snapshot, "primary_objective_visual_visible"), "Primary 3D objective visual is visible")
	_assert(_check_passed(snapshot, "read_only"), "Runtime gate snapshot stays read-only")

	scene.queue_free()
	await _wait_frames(2)


func _gate_status(snapshot: Dictionary, step_id: String) -> String:
	for gate_variant in Array(snapshot.get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")) == step_id:
			return String(gate.get("status", ""))
	return ""


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
	for _index in range(frame_count):
		await process_frame


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
