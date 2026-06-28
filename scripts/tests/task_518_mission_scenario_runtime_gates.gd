extends SceneTree

const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const RUNTIME_GATES_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_runtime_gates.gd")
const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TASK_PATH: String = "res://docs/tasks/TASK_518_mission_scenario_runtime_gates.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const SETUP_PATH: String = "res://scripts/tests/mission_test_setup.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_518 Mission Scenario Runtime Gates ===")
	_test_docs_and_wiring()
	_test_runtime_gate_service()
	await _test_combat_driver_bridge()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_518: FAILED")
		quit(1)
		return
	print("TASK_518: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_518 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_518 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_518 - Mission Scenario Runtime Gates"), "Implementation status tracks TASK_518")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_518 - Mission Scenario Runtime Gates"), "Roadmap lists TASK_518")
	_assert(_read_text(REPORT_PATH).contains("TASK_518 - Mission Scenario Runtime Gates"), "Review workbench recommends TASK_518 as completed/next context")
	var driver_source: String = _read_text(DRIVER_PATH)
	var setup_source: String = _read_text(SETUP_PATH)
	_assert(driver_source.contains("MISSION_SCENARIO_RUNTIME_GATES_SCRIPT"), "Combat driver preloads runtime gate service")
	_assert(driver_source.contains("get_mission_scenario_runtime_gate_snapshot"), "Combat driver exposes runtime gate snapshot")
	_assert(driver_source.contains("are_all_gates_complete"), "Combat driver gates victory through runtime gate completion")
	_assert(setup_source.contains("configure_scenario_runtime_gates_from_file"), "MissionTestSetup wires scenario file into combat driver runtime gates")


func _test_runtime_gate_service() -> void:
	var gates = RUNTIME_GATES_SCRIPT.new()
	var slice: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", SCENARIO_PATH))
	gates.call("configure_from_slice", slice)
	_assert(bool(gates.call("is_configured")), "Runtime gates configure from vertical slice")

	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.owning_team_id = ""
	var snapshot: Dictionary = Dictionary(gates.call("update", {
		"now_msec": 1000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 4},
		"friendly_team_id": "team_alpha",
	}))
	_assert(_gate_status(snapshot, "disable_air_defense") == "active", "AA gate is active while AA group is alive")
	_assert(_gate_status(snapshot, "cargo_touchdown_extract") == "blocked", "Cargo gate is blocked before AA shutdown")
	_assert(not bool(snapshot.get("all_gates_complete", true)), "Initial slice is not complete")

	snapshot = Dictionary(gates.call("update", {
		"now_msec": 1000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 0},
		"friendly_team_id": "team_alpha",
	}))
	_assert(_gate_status(snapshot, "disable_air_defense") == "complete", "AA gate completes when AA group is neutralized")
	_assert(_gate_status(snapshot, "occupy_station_computer") == "pending", "Computer gate waits for Alpha ownership")

	objective_status.owning_team_id = "team_alpha"
	snapshot = Dictionary(gates.call("update", {
		"now_msec": 2000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 0},
		"friendly_team_id": "team_alpha",
	}))
	_assert(_gate_status(snapshot, "occupy_station_computer") == "active", "Computer gate becomes active while Alpha holds it")
	_assert(String(Dictionary(snapshot.get("countdown", {})).get("timer_source", "")) == "scenario_computer_hold", "Computer hold exposes a scenario countdown")

	snapshot = Dictionary(gates.call("update", {
		"now_msec": 20000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 0},
		"friendly_team_id": "team_alpha",
	}))
	_assert(_gate_status(snapshot, "occupy_station_computer") == "complete", "Computer gate completes after the hold duration")
	_assert(_gate_status(snapshot, "cargo_touchdown_extract") == "pending", "Cargo gate is unblocked but pending before cargo state")

	snapshot = Dictionary(gates.call("update", {
		"now_msec": 21000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 0},
		"friendly_team_id": "team_alpha",
		"cargo_state": "departed",
	}))
	_assert(_gate_status(snapshot, "cargo_touchdown_extract") == "complete", "Cargo gate completes on departed state")
	_assert(bool(snapshot.get("all_gates_complete", false)), "All scenario gates complete together")

	var reset_gates = RUNTIME_GATES_SCRIPT.new()
	reset_gates.call("configure_from_slice", slice)
	objective_status.owning_team_id = "team_alpha"
	reset_gates.call("update", {
		"now_msec": 1000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 0},
		"friendly_team_id": "team_alpha",
	})
	objective_status.owning_team_id = "team_bravo"
	var reset_snapshot: Dictionary = Dictionary(reset_gates.call("update", {
		"now_msec": 8000,
		"objective_status": objective_status,
		"enemy_group_fit_counts": {"bravo_air_defense": 0},
		"friendly_team_id": "team_alpha",
	}))
	_assert(_gate_status(reset_snapshot, "occupy_station_computer") == "pending", "Computer hold resets when Alpha loses ownership")


func _test_combat_driver_bridge() -> void:
	var simulation_root: Node = SIMULATION_ROOT_SCRIPT.new()
	simulation_root.name = "SimulationRoot"
	root.add_child(simulation_root)
	var objective_status = OBJECTIVE_STATUS_SCRIPT.new()
	objective_status.objective_id = "objective_point"
	objective_status.owning_team_id = "team_alpha"
	objective_status.capture_progress = 1.0
	simulation_root.call("set_objective_status", objective_status)

	var driver: Node = COMBAT_DRIVER_SCRIPT.new()
	driver.name = "CombatDriver"
	driver.set("simulation_root_path", NodePath("../SimulationRoot"))
	root.add_child(driver)
	await process_frame

	_assert(bool(driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures runtime gates from scenario file")
	_assert(not bool(driver.call("_is_victory_condition_met")), "Scenario-gated driver does not win on objective capture alone")
	driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	var partial_snapshot: Dictionary = Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot"))
	_assert(_gate_status(partial_snapshot, "cargo_touchdown_extract") == "pending", "Driver keeps cargo pending after AA and computer")
	_assert(not bool(driver.call("_is_victory_condition_met")), "Scenario-gated driver waits for cargo before victory")
	driver.call("set_mission_scenario_cargo_state", "departed")
	var final_snapshot: Dictionary = Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot"))
	_assert(bool(final_snapshot.get("all_gates_complete", false)), "Driver snapshot reports all gates complete")
	_assert(bool(driver.call("_is_victory_condition_met")), "Scenario-gated driver wins after all runtime gates complete")

	driver.queue_free()
	simulation_root.queue_free()
	await process_frame


func _gate_status(snapshot: Dictionary, step_id: String) -> String:
	for gate_variant in Array(snapshot.get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")) == step_id:
			return String(gate.get("status", ""))
	return ""


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
