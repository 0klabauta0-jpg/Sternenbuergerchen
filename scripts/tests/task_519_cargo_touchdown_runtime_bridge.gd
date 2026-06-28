extends SceneTree

const OBJECTIVE_STATUS_SCRIPT: GDScript = preload("res://scripts/core/objective_status.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const CARGO_TOUCHDOWN_BRIDGE_SCRIPT: GDScript = preload("res://scripts/mission/mission_cargo_touchdown_bridge.gd")
const COMBAT_DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TASK_PATH: String = "res://docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const DRIVER_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_519 Cargo Touchdown Runtime Bridge ===")
	_test_docs_and_wiring()
	_test_cargo_touchdown_bridge_service()
	await _test_combat_driver_cargo_bridge()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_519: FAILED")
		quit(1)
		return
	print("TASK_519: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_519 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_519 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_519 - Cargo Touchdown Visual/Runtime Bridge"), "Implementation status tracks TASK_519")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_519 - Cargo Touchdown Visual/Runtime Bridge"), "Roadmap lists TASK_519")
	_assert(_read_text(REPORT_PATH).contains("TASK_519 - Cargo Touchdown Visual/Runtime Bridge"), "Review workbench tracks TASK_519")
	var driver_source: String = _read_text(DRIVER_PATH)
	_assert(driver_source.contains("MISSION_CARGO_TOUCHDOWN_BRIDGE_SCRIPT"), "Combat driver preloads cargo touchdown bridge")
	_assert(driver_source.contains("get_mission_cargo_touchdown_snapshot"), "Combat driver exposes cargo touchdown snapshot")
	_assert(driver_source.contains("mission_cargo_touchdown"), "Playability snapshot includes cargo touchdown data")


func _test_cargo_touchdown_bridge_service() -> void:
	var bridge = CARGO_TOUCHDOWN_BRIDGE_SCRIPT.new()
	bridge.call("configure_from_file", SCENARIO_PATH)
	_assert(bool(bridge.call("is_configured")), "Cargo bridge configures from scenario file")

	var snapshot: Dictionary = Dictionary(bridge.call("update", {
		"scenario_gate_snapshot": {
			"completed_step_ids": [],
			"gates": [],
		},
		"cargo_state": "inbound",
	}))
	_assert(String(snapshot.get("cargo_state", "")) == "blocked", "Cargo bridge blocks inbound cargo before AA shutdown")
	_assert(String(snapshot.get("blocked_by_step_id", "")) == "disable_air_defense", "Cargo bridge reports AA blocker")

	var aa_complete_gate_snapshot: Dictionary = {
		"completed_step_ids": ["disable_air_defense"],
		"gates": [
			{"step_id": "disable_air_defense", "complete": true},
		],
	}
	bridge.call("set_runtime_state", "to_mission", 0.0, 0.25)
	snapshot = Dictionary(bridge.call("update", {"scenario_gate_snapshot": aa_complete_gate_snapshot}))
	_assert(String(snapshot.get("cargo_state", "")) == "inbound", "Cargo bridge normalizes to_mission to inbound")
	_assert(float(snapshot.get("progress", 0.0)) == 0.25, "Cargo bridge keeps explicit inbound progress")

	bridge.call("set_runtime_state", "landed", 6.0)
	snapshot = Dictionary(bridge.call("update", {"scenario_gate_snapshot": aa_complete_gate_snapshot}))
	_assert(String(snapshot.get("cargo_state", "")) == "landed", "Cargo bridge exposes landed state")
	_assert(float(snapshot.get("progress", 0.0)) == 0.5, "Cargo bridge derives hold progress")
	_assert(not bool(snapshot.get("ready_to_depart", true)), "Cargo bridge waits for required hold")

	bridge.call("set_runtime_state", "landed", 12.0)
	snapshot = Dictionary(bridge.call("update", {"scenario_gate_snapshot": aa_complete_gate_snapshot}))
	_assert(bool(snapshot.get("ready_to_depart", false)), "Cargo bridge reports ready_to_depart after hold")

	bridge.call("set_runtime_state", "departed")
	snapshot = Dictionary(bridge.call("update", {"scenario_gate_snapshot": aa_complete_gate_snapshot}))
	_assert(String(snapshot.get("cargo_state", "")) == "departed", "Cargo bridge exposes departed state")
	_assert(bool(snapshot.get("complete", false)), "Cargo bridge completes on departed")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Cargo bridge marks UI as read-only")


func _test_combat_driver_cargo_bridge() -> void:
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

	_assert(bool(driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures scenario gates and cargo bridge")
	var cargo_snapshot: Dictionary = Dictionary(driver.call("get_mission_cargo_touchdown_snapshot"))
	_assert(String(cargo_snapshot.get("cargo_state", "")) == "blocked", "Driver cargo snapshot starts blocked by AA")
	_assert(not bool(driver.call("_is_victory_condition_met")), "Driver does not win before cargo bridge completes")

	driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	driver.call("set_mission_scenario_runtime_step_state", "occupy_station_computer", "computer_controlled")
	driver.call("set_mission_cargo_touchdown_state", "landed", 6.0)
	var partial_gate_snapshot: Dictionary = Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot"))
	cargo_snapshot = Dictionary(driver.call("get_mission_cargo_touchdown_snapshot"))
	_assert(String(cargo_snapshot.get("cargo_state", "")) == "landed", "Driver cargo snapshot exposes landed state after AA")
	_assert(_gate_status(partial_gate_snapshot, "cargo_touchdown_extract") == "active", "Scenario cargo gate is active while landed")
	_assert(not bool(driver.call("_is_victory_condition_met")), "Driver waits for cargo departure before victory")

	driver.call("set_mission_cargo_touchdown_state", "departed")
	var final_gate_snapshot: Dictionary = Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot"))
	cargo_snapshot = Dictionary(driver.call("get_mission_cargo_touchdown_snapshot"))
	var playability_snapshot: Dictionary = Dictionary(driver.call("get_playability_snapshot"))
	_assert(bool(cargo_snapshot.get("complete", false)), "Driver cargo snapshot completes on departure")
	_assert(bool(final_gate_snapshot.get("all_gates_complete", false)), "Runtime gates complete after cargo departure")
	_assert(bool(Dictionary(playability_snapshot.get("mission_cargo_touchdown", {})).get("complete", false)), "Playability snapshot includes complete cargo bridge")
	_assert(bool(driver.call("_is_victory_condition_met")), "Driver wins after cargo bridge completes all gates")

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
