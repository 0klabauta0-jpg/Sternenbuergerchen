extends SceneTree
## A cramped three-person arrangement is a setup fixture, not a completed objective.
## Use, GO, timed progress and command cancellation use the actual runtime.
var checks := 0
var failures := 0
func _init() -> void: call_deferred("_run")
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; printerr("FAIL: ",label)
func _run() -> void:
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	var setup := mission.get_node("MissionSetup")
	setup.set("map_file_path","res://maps/satellite_crash_site.json")
	setup.set("scenario_file_path","res://data/mission_scenarios/satellite_recovery.json")
	setup.set("defer_friendly_runtime_activation",false)
	setup.set("selected_team_unit_ids",PackedStringArray(["unit_alpha","unit_bravo","unit_charlie"]))
	setup.set("selected_team_fireteam_ids",PackedStringArray(["ft1","ft1","ft1"]))
	root.add_child(mission)
	await process_frame
	await physics_frame
	var controller := mission.get_node("TacticalController")
	var driver := mission.get_node("CombatLoopDriver")
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/satellite_crash_site.json")
	var target: Vector2 = map.get_marker_position("satellite_data")
	controller.call("_set_selected_fireteams",PackedStringArray(["ft1"]),false)
	var positions: Dictionary = {}
	var offsets := [Vector2(-15,-79),Vector2(42,22),Vector2(-23,44)]
	var index := 0
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true):
		unit.global_position = target + offsets[index]
		positions[String(unit.call("get_unit_id"))] = unit.global_position
		index += 1
	check(index == 3,"three actual fit runtime members in cramped arrangement")
	controller.call("_create_waypoints_for_selected_fireteams",target,true)
	check(bool(controller.call("execute_selected_fireteam_orders")),"actual approach MOVE remains active while object is already usable")
	var intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent","satellite_data")
	check(bool(intent.get("accepted",false)),"already in-range Use accepted")
	var queued_execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam")).get("ft1",{})
	check(not queued_execution.has("interaction_waypoint_id"),"creating Use intent leaves current approach running until explicit GO")
	check(bool(controller.call("execute_selected_fireteam_orders")),"real GO accepted")
	var execution: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam")).get("ft1",{}).duplicate(true)
	var elapsed := 0.0
	var maximum_displacement := 0.0
	var completed := false
	while elapsed < 8.0:
		await physics_frame
		elapsed += 1.0/Engine.physics_ticks_per_second
		for unit: Node2D in controller.call("_get_fireteam_units","ft1",true):
			maximum_displacement = maxf(maximum_displacement,unit.global_position.distance_to(positions[String(unit.call("get_unit_id"))]))
		completed = Array(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids",[])).has("secure_satellite")
		if completed: break
	check(completed,"actual timed Use completes without another formation maneuver")
	check(elapsed >= 2.9,"Use still waits authored three-second hold")
	check(maximum_displacement < 12.0,"usable object does not send a buddy team around the structure")
	controller.set_process(false)
	mission.get_node("SimulationRoot").set_physics_process(false)
	var receipt_target: Vector2 = execution.get("resolved_target_position",target)
	check(bool(controller.call("_is_interaction_arrival_receipt_valid","ft1",receipt_target,execution)),"stationary receipt binds actual unchanged residents")
	var interrupted := execution.duplicate(true)
	interrupted["contact_halt_active"] = true
	check(not bool(controller.call("_is_interaction_arrival_receipt_valid","ft1",receipt_target,interrupted)),"contact interruption rejects stationary hold")
	var other := execution.duplicate(true)
	other["interaction_waypoint_id"] = "another-command"
	check(not bool(controller.call("_is_interaction_arrival_receipt_valid","ft1",receipt_target,other)),"replacement command cannot inherit the receipt")
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): unit.global_position += Vector2(400,400)
	check(not bool(controller.call("_is_interaction_arrival_receipt_valid","ft1",receipt_target,execution)),"residents leaving radius invalidate stationary use")
	# Parked craft and crew placement are fixtures; the return gate remains
	# locked until the real satellite Use above, and gathering uses real moves.
	mission.set_meta("campaign_ground_pilot_id","unit_bravo")
	mission.set_meta("singleplayer_mission_identity",{"craft_id":"return_fixture","job_id":"satellite_recovery","scenario_id":"satellite_recovery"})
	var ship: Vector2 = map.get_marker_position("ship_return")
	controller.set("_parallel_drop_sequences_by_craft",{"return_fixture":{"phase":"complete","position":ship,"lz_position":ship}})
	var return_offsets := [Vector2(45,100),Vector2(137,15),Vector2(35,66)]
	index = 0
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true):
		unit.global_position = ship + return_offsets[index]
		index += 1
	controller.set_process(true)
	mission.get_node("SimulationRoot").set_physics_process(true)
	controller.call("_create_waypoints_for_selected_fireteams",ship,true)
	check(bool(controller.call("execute_selected_fireteam_orders")),"return approach starts with third crew outside boarding radius")
	var return_intent: Dictionary = controller.call("create_selected_mission_interaction_use_intent","ship_return")
	check(bool(return_intent.get("accepted",false)) and bool(controller.call("execute_selected_fireteam_orders")),"actual return Use and explicit GO accepted")
	var return_done := false
	var premature_hold := false
	var return_elapsed := 0.0
	while return_elapsed < 12.0:
		await physics_frame
		return_elapsed += 1.0/Engine.physics_ticks_per_second
		var all_near := true
		for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): all_near = all_near and unit.global_position.distance_to(ship) <= 128.0
		var state: Dictionary = Dictionary(controller.get("_phase_execution_by_fireteam")).get("ft1",{})
		premature_hold = premature_hold or (float(state.get("hold_elapsed",0)) > 0 and not all_near)
		return_done = Array(driver.call("get_mission_scenario_runtime_gate_snapshot").get("completed_step_ids",[])).has("return_to_ship")
		if return_done: break
	check(not premature_hold,"return timer waits for every real crew member within boarding range")
	check(return_done,"third crew physically gathers before timed ship-return completes")
	if not return_done:
		for unit: Node2D in controller.call("_get_fireteam_units","ft1",true):
			var command: Variant = unit.call("get_current_unit_command")
			print("RETURN_UNIT ",unit.call("get_unit_id")," position=",unit.global_position," distance=",unit.global_position.distance_to(ship)," command=",command.to_dict() if command != null and command.has_method("to_dict") else str(command))
		print("RETURN_GATHER_DIAGNOSTIC ",var_to_str({"execution":controller.get("_phase_execution_by_fireteam"),"return_position":controller.call("_campaign_return_context").get("position",Vector2.ZERO),"interactions":controller.call("get_mission_interaction_runtime_use_state_snapshot"),"progress":driver.call("get_mission_interaction_runtime_states")}))
	var all_boardable := true
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): all_boardable = all_boardable and unit.global_position.distance_to(ship) <= 128.0
	check(all_boardable,"completed return leaves all three physically inside boarding range")
	controller.set_process(false)
	mission.get_node("SimulationRoot").set_physics_process(false)
	var casualty: Node2D = controller.call("_get_fireteam_units","ft1",true)[0]
	casualty.call("apply_damage",10000)
	casualty.global_position = ship + Vector2(500,0)
	check(bool(controller.call("_campaign_return_crew_near",controller.call("_campaign_return_context"),128.0)),"terminal casualty does not demand an impossible gathering walk")
	var embarked_before: Dictionary = Dictionary(controller.get("_embarked_unit_ids")).duplicate(true)
	var failed_boarding: Dictionary = controller.call("request_campaign_crew_boarding","return_fixture")
	check(String(failed_boarding.get("reason","")) == "crew_unavailable","authoritative boarding retains terminal casualty failure")
	check(Dictionary(controller.get("_embarked_unit_ids")) == embarked_before,"terminal casualty never produces ghost boarding")
	for unit: Node2D in controller.call("_get_fireteam_units","ft1",true): unit.call("apply_damage",10000)
	check(not bool(controller.call("_campaign_return_crew_near",controller.call("_campaign_return_context"),128.0)),"all-unavailable crew cannot establish a living return hold")
	print("STATIONARY_USE checks=",checks," failures=",failures," displacement=",maximum_displacement," elapsed=",elapsed)
	mission.queue_free()
	await process_frame
	quit(1 if failures else 0)
