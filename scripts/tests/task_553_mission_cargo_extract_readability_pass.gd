extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const LARGE_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const TASK_PATH: String = "res://docs/tasks/TASK_553_mission_cargo_extract_readability_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const CONTRACT_PATH: String = "res://docs/dev/mission_command_feedback_contract.md"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const TASK_522_TEST_PATH: String = "res://scripts/tests/task_522_cargo_touchdown_visual_polish.gd"
const TASK_552_TEST_PATH: String = "res://scripts/tests/task_552_mission_objective_interaction_readability_pass.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_553 Mission Cargo Extract Readability Pass ===")
	_test_docs_and_wiring()
	await _test_cargo_extract_readability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_553: FAILED")
		quit(1)
		return
	print("TASK_553: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_553 task file exists")
	_assert(_read_text(TASK_PATH).contains("Mission Cargo Extract Readability Pass"), "TASK_553 task file names the task")
	_assert(_read_text(STATUS_PATH).contains("TASK_553 - Mission Cargo Extract Readability Pass"), "Implementation status tracks TASK_553")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_553 - Mission Cargo Extract Readability Pass (implementiert)"), "Roadmap marks TASK_553 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_553 - Mission Cargo Extract Readability Pass"), "Review workbench tracks TASK_553")
	_assert(_read_text(CONTRACT_PATH).contains("Mission-Cargo-Extract-Readability"), "Mission feedback contract documents TASK_553")
	_assert(_read_text(CONTROLLER_PATH).contains("get_mission_cargo_extract_readability_snapshot"), "TacticalController exposes TASK_553 readability snapshot")
	_assert(FileAccess.file_exists(TASK_522_TEST_PATH), "TASK_522 cargo visual verifier remains available")
	_assert(FileAccess.file_exists(TASK_552_TEST_PATH), "TASK_552 objective interaction verifier remains available")


func _test_cargo_extract_readability() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	var primary_3d_view: Node = scene.get_node_or_null("Primary3DView")
	_assert(controller != null and combat_driver != null and simulation_root != null and primary_3d_view != null, "Mission scene exposes Controller, CombatDriver, SimulationRoot and Primary3DView")
	if controller == null or combat_driver == null or simulation_root == null or primary_3d_view == null:
		scene.queue_free()
		await _wait_frames(2)
		return

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

	combat_driver.call("set_mission_cargo_touchdown_state", "landed", 12.0)
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)
	controller.call("_update_ui")
	var ready_snapshot: Dictionary = Dictionary(controller.call("get_mission_cargo_extract_readability_snapshot"))
	_assert(String(ready_snapshot.get("gate", "")) == "pass", "TASK_553 landed/ready snapshot gate passes")
	_assert(String(ready_snapshot.get("cargo_extract_line", "")).contains("CARGO READY"), "Mission Control cargo line reports ready state")
	_assert(_check_passed(ready_snapshot, "cargo_bridge_configured"), "Cargo bridge is configured")
	_assert(_check_passed(ready_snapshot, "cargo_gate_readable"), "Cargo gate is readable")
	_assert(_check_passed(ready_snapshot, "cargo_state_readable"), "Cargo state is readable")
	_assert(_check_passed(ready_snapshot, "cargo_hold_progress_readable"), "Cargo hold progress is readable")
	_assert(_check_passed(ready_snapshot, "mission_control_names_cargo_extract"), "Mission Control displays cargo extract line")
	_assert(_check_passed(ready_snapshot, "primary_cargo_visual_matches_runtime"), "Primary 3D cargo visual mirrors landed state")
	_assert(_check_passed(ready_snapshot, "cargo_completion_gate_consistent"), "Ready state does not complete the cargo gate early")
	_assert(_check_passed(ready_snapshot, "read_only"), "Ready snapshot remains read-only")

	combat_driver.call("set_mission_cargo_touchdown_state", "departed")
	controller.call("_refresh_world_overlays")
	controller.call("_update_ui")
	await _wait_frames(8)
	controller.call("_update_ui")
	var departed_snapshot: Dictionary = Dictionary(controller.call("get_mission_cargo_extract_readability_snapshot"))
	_assert(String(departed_snapshot.get("gate", "")) == "pass", "TASK_553 departed snapshot gate passes")
	_assert(String(departed_snapshot.get("cargo_extract_line", "")).contains("CARGO DEPARTED"), "Mission Control cargo line reports departed state")
	_assert(_check_passed(departed_snapshot, "primary_cargo_visual_matches_runtime"), "Departed cargo removes active Primary 3D cargo visual")
	_assert(_check_passed(departed_snapshot, "cargo_completion_gate_consistent"), "Departed cargo completes bridge and scenario gates")
	_assert(bool(Dictionary(departed_snapshot.get("scenario_gate_snapshot", {})).get("all_gates_complete", false)), "Scenario gates report all complete after cargo departure")

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
