extends SceneTree

const META_LAYER_TEST_SCENE: PackedScene = preload("res://scenes/meta/meta_layer_test.tscn")

const STATION_MISSION_ID: String = "station_route_one_screen_multiplayer_drill"
const STATION_MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const STATION_SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1063 First Objective Scenario ===")
	await _test_station_route_enters_from_real_homebase_flow()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_station_route_enters_from_real_homebase_flow() -> void:
	root.size = Vector2i(1920, 1080)
	var flow: Node = META_LAYER_TEST_SCENE.instantiate()
	root.add_child(flow)
	await _wait_frames(8)
	var homebase := flow.get_node_or_null("HomebaseScreen") as Control
	_assert(homebase != null, "Meta fixture exposes the real Homebase screen")
	if homebase == null:
		await _cleanup(flow)
		return

	var catalog: Array = Array(flow.get("_mission_catalog"))
	var station_definition: Dictionary = _find_mission_definition(catalog, STATION_MISSION_ID)
	_assert(not station_definition.is_empty(), "Homebase catalog exposes the Station Route scenario")
	if station_definition.is_empty():
		await _cleanup(flow)
		return
	_assert(String(station_definition.get("map_file_path", "")) == STATION_MAP_PATH, "Station Route uses the station outpost map")
	_assert(String(station_definition.get("scenario_file_path", "")) == STATION_SCENARIO_PATH, "Station Route uses the AA-Door-Computer-Cargo scenario")
	_assert(int(station_definition.get("slot_count", 0)) == 8, "Station Route preserves the eight-slot mission contract")

	flow.call("_on_homebase_mission_selection_changed", STATION_MISSION_ID)
	_assert(String(flow.get("_selected_mission_id")) == STATION_MISSION_ID, "Homebase selection keeps Station Route as active mission")
	_assert(bool(homebase.call("can_request_mission_start")), "Bootstrap Homebase remains startable after selecting Station Route")
	homebase.call("request_mission_start")
	await _wait_frames(12)
	var mission: Node = flow.call("get_active_mission")
	var mission_setup: Node = mission.get_node_or_null("MissionSetup") if mission != null else null
	var combat_driver: Node = mission.get_node_or_null("CombatLoopDriver") if mission != null else null
	var controller: Node = mission.get_node_or_null("TacticalController") if mission != null else null
	_assert(mission != null and mission_setup != null and combat_driver != null and controller != null, "Station Route starts a real mission with setup, combat runtime and tactical controller")
	if mission == null or mission_setup == null or combat_driver == null or controller == null:
		await _cleanup(flow)
		return
	_assert(String(mission_setup.get("map_file_path")) == STATION_MAP_PATH, "MissionSetup receives the selected Station Route map")
	_assert(String(mission_setup.get("scenario_file_path")) == STATION_SCENARIO_PATH, "MissionSetup receives the selected Station Route scenario")
	var gates: Dictionary = Dictionary(combat_driver.call("get_mission_scenario_runtime_gate_snapshot"))
	_assert(bool(gates.get("configured", false)), "Combat runtime configures Station Route gates from MissionSetup scenario")
	_assert(Array(gates.get("gates", [])).size() == 4, "Combat runtime exposes all four Station Route gates")
	var objective_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(objective_gate.get("next_step_id", "")) == "disable_air_defense", "First visible Station Route objective is AA shutdown")
	_assert(String(flow.get("_current_meta_view")) == "mission", "Real Homebase start reaches the mission view")
	await _cleanup(flow)


func _find_mission_definition(catalog: Array, mission_id: String) -> Dictionary:
	for definition_variant in catalog:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		if String(definition.get("mission_id", "")).strip_edges() == mission_id:
			return definition.duplicate(true)
	return {}


func _cleanup(flow: Node) -> void:
	if is_instance_valid(flow):
		flow.queue_free()
	await _wait_frames(2)


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
