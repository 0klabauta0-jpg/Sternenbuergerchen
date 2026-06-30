extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const INTERACTION_BINDING_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_674_mission_interaction_point_bindings.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_674 Mission Interaction Point Bindings ===")
	_test_docs()
	_test_scenario_bindings()
	await _test_controller_runtime_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_674: FAILED")
		quit(1)
		return
	print("TASK_674: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_674 task file exists")
	_assert(task_text.contains("Mission Interaction Point Bindings"), "Task documents interaction point bindings")
	_assert(contract_text.contains("Scenario Binding"), "Interaction contract documents Scenario Binding")
	_assert(contract_text.contains("MissionInteractionPointBinding"), "Interaction contract names binding helper")
	_assert(_read_text(STATUS_PATH).contains("TASK_674 - Mission Interaction Point Bindings"), "Implementation status tracks TASK_674")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_674 - Mission Interaction Point Bindings"), "Roadmap lists TASK_674")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_674 - Mission Interaction Point Bindings"), "Current handbook references TASK_674")


func _test_scenario_bindings() -> void:
	var raw_scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	_assert(not raw_scenario.is_empty(), "Frontier Probe scenario JSON loads")
	_assert(terrain_map_data != null and not bool(terrain_map_data.call("has_load_issue")), "Frontier Probe map loads for binding validation")
	if raw_scenario.is_empty() or terrain_map_data == null:
		return

	var scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SCENARIO_PATH)
	var validation: Dictionary = Dictionary(scenario.call("validate"))
	if not bool(validation.get("valid", false)):
		print("TASK_674 scenario validation errors: %s" % "; ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_assert(bool(validation.get("valid", false)), "ScenarioData validates explicit interaction bindings")
	_assert(Array(Dictionary(scenario.call("get_vertical_slice")).get("interaction_points", [])).size() == 3, "ScenarioData preserves vertical_slice interaction points")
	_assert(Array(scenario.call("get_interaction_points")).size() == 3, "ScenarioData exposes normalized interaction points")
	_assert(Dictionary(scenario.call("to_dict")).has("vertical_slice"), "Scenario serialization preserves vertical_slice")

	var slice: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", SCENARIO_PATH))
	var slice_validation: Dictionary = Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("validate_slice", slice, terrain_map_data))
	if not bool(slice_validation.get("valid", false)):
		print("TASK_674 slice validation errors: %s" % "; ".join(PackedStringArray(slice_validation.get("errors", PackedStringArray()))))
	_assert(bool(slice_validation.get("valid", false)), "Vertical slice contract validates interaction points")
	_assert(Array(slice.get("interaction_points", [])).size() == 3, "Vertical slice exposes three normalized interaction points")

	var empty_gate_snapshot: Dictionary = {
		"completed_step_ids": [],
		"gates": [
			{"step_id": "disable_air_defense", "status": "pending", "complete": false},
			{"step_id": "occupy_station_computer", "status": "pending", "complete": false},
			{"step_id": "cargo_touchdown_extract", "status": "blocked", "complete": false},
		],
	}
	var snapshot: Dictionary = Dictionary(INTERACTION_BINDING_SCRIPT.call("build_snapshot", raw_scenario, terrain_map_data, {"scenario_gate_snapshot": empty_gate_snapshot}))
	_assert(String(snapshot.get("schema", "")) == INTERACTION_BINDING_SCRIPT.SNAPSHOT_SCHEMA, "Binding snapshot schema is stable")
	_assert(bool(snapshot.get("valid", false)), "Binding snapshot validates")
	_assert(int(snapshot.get("binding_count", 0)) == 3, "Binding snapshot carries three interactions")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Binding snapshot does not set gameplay truth")
	_assert(String(_find_binding(snapshot, "aa_shutdown_zone").get("interaction_type", "")) == "hold_zone", "AA binding is a hold-zone interaction")
	_assert(String(_find_binding(snapshot, "station_computer").get("interaction_type", "")) == "computer", "Station computer binding is computer interaction")
	_assert(float(_find_binding(snapshot, "station_computer").get("duration_seconds", 0.0)) >= 18.0, "Station computer keeps 18 second hold")
	_assert(bool(_find_binding(snapshot, "cargo_landing_hold").get("blocked", false)), "Cargo hold is blocked before AA is disabled")
	_assert(String(_find_binding(snapshot, "cargo_landing_hold").get("blocked_by_step_id", "")) == "disable_air_defense", "Cargo hold names AA blocker")

	var completed_gate_snapshot: Dictionary = {
		"completed_step_ids": ["disable_air_defense", "occupy_station_computer", "cargo_touchdown_extract"],
		"gates": [
			{"step_id": "disable_air_defense", "status": "complete", "complete": true},
			{"step_id": "occupy_station_computer", "status": "complete", "complete": true},
			{"step_id": "cargo_touchdown_extract", "status": "complete", "complete": true},
		],
	}
	var completed_snapshot: Dictionary = Dictionary(INTERACTION_BINDING_SCRIPT.call("build_snapshot", raw_scenario, terrain_map_data, {"scenario_gate_snapshot": completed_gate_snapshot}))
	_assert(int(completed_snapshot.get("complete_count", 0)) == 3, "Completed gates mark all three interactions complete")
	_assert(float(_find_binding(completed_snapshot, "station_computer").get("progress", 0.0)) == 1.0, "Completed computer reports full progress")


func _test_controller_runtime_snapshot() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	_assert(controller != null and combat_driver != null, "Mission scene exposes controller and combat driver")
	if controller == null or combat_driver == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_point_binding_snapshot"))
	_assert(String(snapshot.get("schema", "")) == INTERACTION_BINDING_SCRIPT.SNAPSHOT_SCHEMA, "Controller exposes TASK_674 binding snapshot")
	_assert(int(snapshot.get("binding_count", 0)) == 3, "Controller snapshot sees three bindings")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Controller binding snapshot is read-only")
	_assert(not bool(_find_binding(snapshot, "cargo_landing_hold").get("blocked", true)), "Controller snapshot unblocks cargo after AA runtime gate")

	scene.queue_free()
	await _wait_frames(2)


func _find_binding(snapshot: Dictionary, interaction_id: String) -> Dictionary:
	for binding_variant in Array(snapshot.get("bindings", [])):
		var binding: Dictionary = Dictionary(binding_variant)
		if String(binding.get("interaction_id", "")).strip_edges() == interaction_id:
			return binding
	return {}


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", true)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
