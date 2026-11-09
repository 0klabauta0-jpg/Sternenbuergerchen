extends SceneTree

const SCENARIO := "res://data/mission_scenarios/satellite_recovery.json"
var passed: int = 0
var failed: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var mission: Node = load("res://scenes/tests/mission_reactivity_test.tscn").instantiate()
	mission.set_meta("singleplayer_mission_identity", {"craft_id": "actual_ship", "job_id": "satellite_recovery", "scenario_id": "satellite_recovery"})
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", "res://maps/satellite_crash_site.json")
	setup.set("scenario_file_path", SCENARIO)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	var driver: Node = mission.get_node("CombatLoopDriver")
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/satellite_crash_site.json")
	var pad: Vector2 = map.get_marker_position("ship_return")
	var remote: Vector2 = map.get_marker_position("satellite_data")
	_check(pad.distance_to(remote) > 96.0, "Fixture distinguishes authored return pad from remote crash site")
	var result: Dictionary = driver.call("update_mission_interaction_runtime_progress", _return_progress())
	_check(not bool(result.get("complete", false)) and not _return_complete(driver), "Return progress rejects absent actual job craft")
	driver.call("configure_scenario_runtime_gates_from_file", SCENARIO)
	var state: Dictionary = controller.call("get_planning_state")
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "actual_ship", "mission_drop_state": "waiting", "drop_ship_staged": true, "embarked_unit_ids": ["unit_alpha", "unit_bravo"], "deployed_unit_ids": [], "has_lz_position": false, "selected_fireteams": ["ft1"], "mission_drop_cards": [{"craft_id": "actual_ship", "display_name": "Actual Ship", "state": "waiting", "payload_source": "homebase_direct", "passenger_count": 1, "embarked_unit_ids": ["unit_alpha"], "boarded_fireteam_ids": ["ft1"], "has_lz_position": false, "approach_angle": "NW"}, {"craft_id": "waiting_ship", "display_name": "Waiting Ship", "state": "waiting", "payload_source": "homebase_direct", "passenger_count": 1, "embarked_unit_ids": ["unit_bravo"], "boarded_fireteam_ids": ["ft2"], "has_lz_position": true, "lz_position": pad, "approach_angle": "NW"}]}, true)
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "actual_ship", false)
	controller.call("_set_selected_fireteams", PackedStringArray(["ft1"]), false)
	var remote_screen: Vector2 = mission.get_node("Primary3DView").call("world_to_screen_position", remote)
	_check(not bool(controller.call("_place_lz_from_screen_position", remote_screen)), "Normal screen LZ choice rejects a tile away from authored pad")
	_check(not String(controller.get("_last_command_text")).is_empty(), "Rejected LZ leaves concrete player feedback")
	var pad_screen: Vector2 = mission.get_node("Primary3DView").call("world_to_screen_position", pad)
	_check(bool(controller.call("_place_lz_from_screen_position", pad_screen)), "Normal screen LZ choice accepts authored landing pad")
	_check(Vector2(controller.get("_lz_position")).is_equal_approx(pad), "Accepted LZ snaps to saved real return pad center")
	controller.set("_lz_position", remote)
	controller.set("_has_lz_position", true)
	_check(not bool(controller.call("_try_start_drop_sequence", true)), "Runtime drop gate also rejects injected remote LZ")
	controller.set("_lz_position", pad)
	controller.set("_has_lz_position", true)
	_check(bool(controller.call("_try_start_drop_sequence", true)), "Real job craft starts flight to authored pad")
	for tick in range(7):
		controller.call("_update_drop_sequence", 30.0)
		await physics_frame
	_check(String(controller.get("_drop_sequence_phase")) == "complete" and Vector2(controller.get("_drop_sequence_position")).is_equal_approx(pad), "Actual matching job craft is physically parked at real return pad")
	mission.set_meta("singleplayer_mission_identity", {"craft_id": "wrong_ship", "job_id": "satellite_recovery", "scenario_id": "satellite_recovery"})
	result = driver.call("update_mission_interaction_runtime_progress", _return_progress())
	_check(not bool(result.get("complete", false)) and not _return_complete(driver), "Another parked ship cannot satisfy immutable job craft binding")
	driver.call("configure_scenario_runtime_gates_from_file", SCENARIO)
	mission.set_meta("singleplayer_mission_identity", {"craft_id": "actual_ship", "job_id": "satellite_recovery", "scenario_id": "satellite_recovery"})
	controller.set("_drop_sequence_position", remote)
	controller.set("_drop_sequence_lz_position", remote)
	result = driver.call("update_mission_interaction_runtime_progress", _return_progress())
	_check(not bool(result.get("complete", false)) and not _return_complete(driver), "Physically parked matching craft at wrong pad cannot complete return")
	driver.call("configure_scenario_runtime_gates_from_file", SCENARIO)
	controller.set("_drop_sequence_position", pad)
	controller.set("_drop_sequence_lz_position", pad)
	result = driver.call("update_mission_interaction_runtime_progress", _return_progress())
	_check(bool(result.get("complete", false)) and _return_complete(driver), "Runtime return completion accepts only actual matching parked craft at authored pad")
	driver.call("configure_scenario_runtime_gates_from_file", SCENARIO)
	controller.call("_select_mission_dropship_craft", "waiting_ship", false)
	controller.call("_set_selected_fireteams", PackedStringArray(["ft2"]), false)
	_check(not bool(controller.call("_try_start_drop_sequence", true)), "Second craft waits while the single authored remote pad is occupied")
	_check(bool(controller.call("_apply_selected_mission_dropship_return", "actual_ship")), "Matching parked craft starts real outbound")
	result = driver.call("update_mission_interaction_runtime_progress", _return_progress())
	_check(not bool(result.get("complete", false)) and not _return_complete(driver), "Already outbound craft cannot satisfy stale return Use")
	controller.call("_update_drop_sequence", 30.0)
	controller.call("_select_mission_dropship_craft", "waiting_ship", false)
	controller.call("_set_selected_fireteams", PackedStringArray(["ft2"]), false)
	_check(bool(controller.call("_try_start_drop_sequence", true)), "Independent waiting craft can land once the first outbound clears the pad")
	mission.queue_free()
	await process_frame
	print("ACTUAL_CRAFT_RETURN_BINDING_RESULTS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _return_progress() -> Dictionary:
	return {"interaction_id": "ship_return", "step_id": "return_to_ship", "required_state": "crew_returned", "interaction_type": "computer", "command_type": "take", "fireteam_id": "ft1", "team_id": "team_alpha", "hold_seconds": 2.0, "duration_seconds": 2.0, "complete": true}

func _return_complete(driver: Node) -> bool:
	return bool(Dictionary(Dictionary(driver.call("get_mission_interaction_runtime_state_snapshot")).get("interaction_states", {})).get("ship_return", {}).get("complete", false))

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		printerr("FAIL: " + label)
