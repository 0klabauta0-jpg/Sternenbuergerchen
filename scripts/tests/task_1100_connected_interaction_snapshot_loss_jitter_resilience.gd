extends SceneTree

const MISSION_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const INTERACTION_ID: String = "station_computer"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1100 Connected Interaction Snapshot Loss/Jitter Resilience ===")
	var scene: Node = MISSION_SCENE.instantiate()
	root.add_child(scene)
	await process_frame
	var simulation_root: Node = scene.get_node("SimulationRoot")
	var controller: Node = scene.get_node("TacticalController")
	var combat_driver: Node = scene.get_node("CombatLoopDriver")
	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Station Route gate contract loads for jitter checks")
	controller.set("_network_mission_interaction_feedback", {"interaction_id": INTERACTION_ID})

	var tick_10: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(10, 0.2, 4.0, false)))
	var feedback_10: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(bool(tick_10.get("accepted", false)), "Tick 10 is accepted")
	_assert(String(feedback_10.get("compact_line", "")) == "COM 20% | 4/20s FT2", "Tick 10 surfaces 20 percent")
	_assert(int(feedback_10.get("source_tick", -1)) == 10, "Feedback exposes accepted source tick 10")

	var tick_13: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(13, 0.8, 16.0, false)))
	var feedback_13: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	var updates_after_13: int = int(feedback_13.get("progress_update_count", -1))
	var gate_after_13: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(tick_13.get("accepted", false)), "Tick 13 converges despite skipped intermediate snapshots")
	_assert(String(feedback_13.get("compact_line", "")) == "COM 80% | 16/20s FT2", "Latest accepted snapshot surfaces 80 percent")
	_assert(int(feedback_13.get("source_tick", -1)) == 13, "Feedback advances to source tick 13")

	var stale_11: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(11, 0.4, 8.0, false)))
	var feedback_after_stale: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	var runtime_after_stale: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_states"))
	_assert(not bool(stale_11.get("accepted", true)) and String(stale_11.get("reason", "")) == "out_of_order_snapshot", "Late tick 11 is rejected as out of order")
	_assert(String(feedback_after_stale.get("compact_line", "")) == "COM 80% | 16/20s FT2", "Late tick cannot regress visible progress")
	_assert(int(feedback_after_stale.get("source_tick", -1)) == 13, "Late tick cannot regress visible source tick")
	_assert(int(feedback_after_stale.get("progress_update_count", -1)) == updates_after_13, "Late tick causes no label update")
	_assert(is_equal_approx(float(Dictionary(runtime_after_stale.get(INTERACTION_ID, {})).get("progress", -1.0)), 0.8), "Late tick cannot regress replicated runtime state")
	_assert(Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot")) == gate_after_13, "Late tick cannot mutate replicated gate state")

	var reset_14: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(14, 0.0, 0.0, false)))
	var feedback_14: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(bool(reset_14.get("accepted", false)), "Strictly newer authoritative hold reset is accepted")
	_assert(String(feedback_14.get("compact_line", "")) == "COM 0% | 0/20s FT2", "Newer authoritative hold reset reaches the HUD")
	_assert(is_zero_approx(float(Dictionary(combat_driver.call("get_mission_interaction_runtime_states")).get(INTERACTION_ID, {}).get("progress", -1.0))), "Newer authoritative hold reset reaches replicated runtime state")

	var duration_15: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(15, 0.0, 0.0, false, 25.0)))
	var feedback_15: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(bool(duration_15.get("accepted", false)), "Newer duration correction is accepted")
	_assert(String(feedback_15.get("compact_line", "")) == "COM 0% | 0/25s FT2", "Rendered duration correction is not hidden by fingerprint dedupe")
	_assert(int(feedback_15.get("progress_update_count", -1)) == int(feedback_14.get("progress_update_count", -1)) + 1, "Rendered duration correction performs exactly one label update")

	var complete_20: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(20, 1.0, 20.0, true)))
	var feedback_20: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	var updates_after_complete: int = int(feedback_20.get("progress_update_count", -1))
	var gate_after_complete: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(complete_20.get("accepted", false)), "Completion tick 20 is accepted")
	_assert(String(feedback_20.get("compact_line", "")) == "COM FERTIG FT2", "Completion is visible")
	_assert(bool(Dictionary(combat_driver.call("get_mission_interaction_runtime_states")).get(INTERACTION_ID, {}).get("complete", false)), "Completion reaches replicated runtime state")

	var stale_19: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(19, 0.9, 18.0, false)))
	_assert(not bool(stale_19.get("accepted", true)), "Late pre-completion tick 19 is rejected")
	_assert(String(Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot")).get("compact_line", "")) == "COM FERTIG FT2", "Late pre-completion tick cannot reopen completed feedback")
	_assert(bool(Dictionary(combat_driver.call("get_mission_interaction_runtime_states")).get(INTERACTION_ID, {}).get("complete", false)), "Late pre-completion tick cannot reopen replicated runtime state")
	_assert(Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot")) == gate_after_complete, "Late pre-completion tick cannot reopen replicated gate state")

	var duplicate_21: Dictionary = Dictionary(simulation_root.call("apply_multiplayer_snapshot", _snapshot(21, 1.0, 20.0, true)))
	var feedback_21: Dictionary = Dictionary(controller.call("get_network_mission_interaction_feedback_snapshot"))
	_assert(bool(duplicate_21.get("accepted", false)), "Newer semantically identical completion tick is accepted")
	_assert(int(feedback_21.get("source_tick", -1)) == 21, "Read-only feedback tracks the newest accepted source tick")
	_assert(int(feedback_21.get("progress_update_count", -1)) == updates_after_complete, "Identical completion creates no extra label update")
	_assert(Array(simulation_root.get("command_queue")).is_empty() and Array(simulation_root.get("effects_queue")).is_empty(), "Snapshot jitter path creates no gameplay commands or effects")
	var debug: Dictionary = Dictionary(simulation_root.call("get_multiplayer_snapshot_debug_snapshot"))
	_assert(int(debug.get("out_of_order_count", 0)) == 2, "Snapshot diagnostics count both stale packets")

	scene.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _snapshot(tick: int, progress: float, hold_seconds: float, complete: bool, duration_seconds: float = 20.0) -> Dictionary:
	return {
		"tick": tick,
		"mission_interactions": {
			"interaction_states": {
				INTERACTION_ID: {
					"state": "complete" if complete else "operating",
					"complete": complete,
					"progress": progress,
					"hold_seconds": hold_seconds,
					"duration_seconds": duration_seconds,
					"fireteam_id": "ft2",
					"team_id": "team_alpha",
					"step_id": "occupy_station_computer",
					"gate_id": "computer_controlled",
					"required_state": "computer_controlled",
					"interaction_type": "computer",
					"command_type": "take",
				}
			},
		},
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
