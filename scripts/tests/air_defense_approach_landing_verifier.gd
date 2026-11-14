extends SceneTree
## Integration: the real mission controller on GM02 rolls the air defence at the
## landing commit point (_try_start_drop_sequence).
## Task: docs/tasks/FLUGABWEHR_ANSCHLUSS_2026_11_14.md
const MISSION = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MAP_PATH := "res://maps/Ground_Mission02_128x128.json"
const SCENARIO_PATH := "res://data/mission_scenarios/ground_mission02_128x128.json"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var mission: Node = MISSION.instantiate()
	var setup: Node = mission.get_node("MissionSetup")
	setup.set("map_file_path", MAP_PATH)
	setup.set("scenario_file_path", SCENARIO_PATH)
	setup.set("selected_team_unit_ids", PackedStringArray(["unit_alpha", "unit_bravo"]))
	setup.set("selected_team_fireteam_ids", PackedStringArray(["ft1", "ft2"]))
	setup.set("defer_friendly_runtime_activation", true)
	root.add_child(mission)
	for _frame in range(3):
		await process_frame
	var controller: Node = mission.get_node("TacticalController")
	controller.set_process(false)
	var driver: Node = controller.call("_get_combat_loop_driver")
	var fit: Dictionary = driver.call("get_enemy_group_fit_counts") if driver != null else {}
	print("fit counts: ", fit)
	check(int(fit.get("red_air_defense", 0)) > 0, "the scenario's air-defence group is known and crewed when the first craft lands")
	var teams: PackedStringArray = controller.call("_get_available_fireteam_ids")
	check(teams.size() >= 2, "scenario exposes two fireteams")
	if teams.size() < 2:
		_finish(mission)
		return
	var first_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[0]), true))
	var second_ids: Array = _unit_ids(controller.call("_get_fireteam_units", String(teams[1]), true))
	var registry: Node = controller.call("_get_terrain_registry")
	var hot_lz: Vector2 = registry.call("grid_to_world", Vector2i(90, 85)) # flat open ground 7 cells from the Hagel
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file(MAP_PATH)
	var quiet_lz: Vector2 = map.get_marker_position("spawn_alpha")
	var state: Dictionary = controller.call("get_planning_state")
	state.merge({"mission_drop_source": "homebase_direct", "mission_drop_craft_id": "craft_a", "mission_drop_state": "waiting", "drop_ship_staged": true,
		"embarked_unit_ids": first_ids + second_ids, "deployed_unit_ids": [], "has_lz_position": true, "lz_position": hot_lz, "selected_fireteams": [teams[0]],
		"mission_drop_cards": [_card("craft_a", String(teams[0]), first_ids, hot_lz), _card("craft_b", String(teams[1]), second_ids, quiet_lz)]}, true)
	controller.call("set_planning_state", state)
	controller.call("_select_mission_dropship_craft", "craft_a", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[0]]), false)
	var started: bool = bool(controller.call("_try_start_drop_sequence", true))
	var text: String = String(controller.get("_last_command_text"))
	print("hot approach: started=", started, " text=", text)
	check(not started and text.begins_with("Flugabwehr: Anflug abgebrochen") and text.ends_with(" %"), "an approach beside the battery is broken off with a German message: " + text)
	check(String(controller.get("_drop_sequence_phase")) != "inbound", "the broken-off craft does not start its inbound flight")
	check(String(_find_card(controller, "craft_a").get("card_feedback_text", "")) == text, "the craft card shows the same one-line message")
	check(String(_find_card(controller, "craft_a").get("state", "")) == "waiting", "the craft stays available for another attempt")
	for _frame in range(3):
		await physics_frame
	var simulation_root: Node = mission.get_node("SimulationRoot")
	var status: Dictionary = simulation_root.call("get_air_asset_status_snapshot", "craft_a")
	print("stored status: ", status.get("state"), " integrity=", status.get("integrity"))
	check(not status.is_empty() and str(int(status.get("integrity", -1))) + " %" == text.get_slice("Rumpf ", 1), "SimulationRoot stores the hull as the craft's air asset integrity")
	var retried: bool = bool(controller.call("_try_start_drop_sequence", true))
	var retry_text: String = String(controller.get("_last_command_text"))
	print("retry: started=", retried, " text=", retry_text)
	check(not retried and retry_text.begins_with("Flugabwehr:") and int(retry_text.get_slice("Rumpf ", 1).to_int()) <= int(status.get("integrity", 100)), "a second attempt starts from the stored hull, not from a fresh ship: " + retry_text)
	controller.call("_select_mission_dropship_craft", "craft_b", false)
	controller.call("_set_selected_fireteams", PackedStringArray([teams[1]]), false)
	var quiet_started: bool = bool(controller.call("_try_start_drop_sequence", true))
	var quiet_text: String = String(controller.get("_last_command_text"))
	print("quiet approach: started=", quiet_started, " text=", quiet_text)
	check(quiet_started and String(controller.get("_air_defense_feedback_text")).is_empty() and not quiet_text.begins_with("Flugabwehr"), "an approach to the west landing field starts exactly as before, without air-defence message")
	check(simulation_root.call("get_air_asset_status_snapshot", "craft_b").is_empty(), "no air asset status is written for an approach no vehicle could track")
	_finish(mission)

func _finish(mission: Node) -> void:
	mission.queue_free()
	await process_frame
	print("AIR_DEFENSE_APPROACH_LANDING passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _card(id: String, team: String, units: Array, lz: Vector2) -> Dictionary:
	return {"craft_id": id, "model_id": "cutlass", "display_name": id, "payload_source": "homebase_direct", "state": "waiting", "progress": 0.0, "passenger_count": units.size(), "embarked_unit_ids": units, "boarded_fireteam_ids": [team], "has_lz_position": true, "lz_position": lz, "approach_angle": "NW"}

func _find_card(controller: Node, id: String) -> Dictionary:
	for card in Array(Dictionary(controller.call("get_planning_state")).get("mission_drop_cards", [])):
		if String(card.get("craft_id", "")) == id:
			return card
	return {}

func _unit_ids(units: Array) -> Array:
	var ids: Array = []
	for unit in units:
		ids.append(String(unit.call("get_unit_id")))
	return ids
