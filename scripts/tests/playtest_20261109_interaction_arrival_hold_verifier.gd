extends SceneTree

var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", "res://maps/satellite_crash_site.json")
	setup.set("scenario_file_path", "res://data/mission_scenarios/satellite_recovery.json")
	setup.set("defer_friendly_runtime_activation", false)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo", "unit_charlie"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft1", "ft1"]))
	root.add_child(mission)
	await process_frame
	await physics_frame
	var controller: Node = mission.get_node("TacticalController")
	var driver: Node = mission.get_node("CombatLoopDriver")
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/satellite_crash_site.json")
	var target: Vector2 = map.get_marker_position("satellite_data")
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	controller.call("_create_waypoints_for_selected_fireteams", target, true)
	_check(bool(controller.call("execute_selected_fireteam_orders")), "Actual formed three-person team begins move/GO to computer")
	var deadline: int = Time.get_ticks_msec() + 22000
	var usable: bool = false
	while Time.get_ticks_msec() < deadline:
		for interaction in Array(Dictionary(controller.call("get_mission_interaction_runtime_use_state_snapshot")).get("interactions", [])):
			if String(interaction.get("interaction_id", "")) == "satellite_data" and bool(interaction.get("can_use_now", false)):
				usable = true
		if usable:
			break
		await process_frame
	_check(usable, "Real Use becomes available within authored radius")
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent", "satellite_data")
	_check(bool(intent.get("accepted", false)) and bool(controller.call("execute_selected_fireteam_orders")), "Real three-person Use and GO start")
	deadline = Time.get_ticks_msec() + 30000
	var completed: bool = false
	var captured: Dictionary = {}
	while Time.get_ticks_msec() < deadline:
		var execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam")).get("ft1", {})
		if execution.has("interaction_arrival_receipt") and captured.is_empty():
			captured = execution.duplicate(true)
		if PackedStringArray(Dictionary(driver.call("get_mission_scenario_runtime_gate_snapshot")).get("completed_step_ids", [])).has("secure_satellite"):
			completed = true
			break
		await process_frame
	_check(completed, "Timed Use completes after genuine arrival even when movement execution retires")
	if not completed:
		print("ARRIVAL_HOLD_DIAGNOSTIC:", var_to_str({"execution": controller.get("_phase_execution_by_fireteam"), "interaction": driver.call("get_mission_interaction_runtime_state_snapshot"), "movement": controller.call("get_fireteam_movement_snapshot")}))
	_check(not captured.is_empty(), "Same-waypoint hold retains genuine movement arrival receipt")
	if not captured.is_empty():
		controller.set_process(false)
		mission.get_node("SimulationRoot").set_physics_process(false)
		var receipt_target: Vector2 = captured.resolved_target_position
		_check(bool(controller.call("_is_phase_waypoint_target_reached", "ft1", receipt_target, {}, captured, false)), "Receipt continues only the original arrived Use")
		_check(not bool(controller.call("_is_phase_waypoint_target_reached", "ft1", receipt_target + Vector2(300, 0), {}, captured, false)), "Another target cannot reuse arrival")
		var another_waypoint: Dictionary = captured.duplicate(true)
		another_waypoint.interaction_waypoint_id = "another-waypoint"
		_check(not bool(controller.call("_is_phase_waypoint_target_reached", "ft1", receipt_target, {}, another_waypoint, false)), "Another waypoint at the same target cannot inherit receipt")
		var interrupted: Dictionary = captured.duplicate(true)
		interrupted.contact_halt_active = true
		_check(not bool(controller.call("_is_phase_waypoint_target_reached", "ft1", receipt_target, {"contact_halt": true}, interrupted, false)), "Contact interruption cannot consume receipt")
		for unit in Array(controller.call("_get_fireteam_units", "ft1", true)):
			(unit as Node2D).global_position += Vector2(400, 400)
		_check(not bool(controller.call("_is_phase_waypoint_target_reached", "ft1", receipt_target, {}, captured, false)), "Moved out-of-range crew cannot complete using stale receipt")
	mission.queue_free()
	await process_frame
	print("INTERACTION_ARRIVAL_HOLD_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)
