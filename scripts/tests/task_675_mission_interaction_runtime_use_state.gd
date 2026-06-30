extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const INTERACTION_BINDING_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const INTERACTION_USE_STATE_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_runtime_use_state.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_675_mission_interaction_runtime_use_state.md"
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
	print("=== TASK_675 Mission Interaction Runtime Use State ===")
	_test_docs()
	_test_runtime_use_state_helper()
	await _test_controller_runtime_use_state_snapshot()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_675: FAILED")
		quit(1)
		return
	print("TASK_675: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_675 task file exists")
	_assert(task_text.contains("Mission Interaction Runtime Use State"), "Task documents runtime use state")
	_assert(contract_text.contains("Runtime Use State"), "Interaction contract documents Runtime Use State")
	_assert(contract_text.contains("MissionInteractionRuntimeUseState"), "Interaction contract names runtime use state helper")
	_assert(_read_text(STATUS_PATH).contains("TASK_675 - Mission Interaction Runtime Use State"), "Implementation status tracks TASK_675")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_675 - Mission Interaction Runtime Use State"), "Roadmap lists TASK_675")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_675 - Mission Interaction Runtime Use State"), "Current handbook references TASK_675")


func _test_runtime_use_state_helper() -> void:
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	_assert(terrain_map_data != null and not bool(terrain_map_data.call("has_load_issue")), "Frontier Probe terrain map loads")
	_assert(not scenario.is_empty(), "Frontier Probe scenario loads")
	if terrain_map_data == null or scenario.is_empty():
		return

	var blocked_gate_snapshot: Dictionary = {
		"completed_step_ids": [],
		"gates": [
			{"step_id": "disable_air_defense", "status": "pending", "complete": false},
			{"step_id": "occupy_station_computer", "status": "pending", "complete": false},
			{"step_id": "cargo_touchdown_extract", "status": "blocked", "complete": false},
		],
	}
	var binding_snapshot: Dictionary = Dictionary(INTERACTION_BINDING_SCRIPT.call("build_snapshot", scenario, terrain_map_data, {"scenario_gate_snapshot": blocked_gate_snapshot}))
	var spawn_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	var blocked_snapshot: Dictionary = Dictionary(INTERACTION_USE_STATE_SCRIPT.call("build_snapshot", binding_snapshot, terrain_map_data, {
		"current_team_id": "team_alpha",
		"fireteam_positions": [
			{"fireteam_id": "ft1", "team_id": "team_alpha", "position": spawn_position, "active": true},
		],
	}))
	_assert(String(blocked_snapshot.get("schema", "")) == INTERACTION_USE_STATE_SCRIPT.SNAPSHOT_SCHEMA, "Runtime use state schema is stable")
	_assert(not bool(blocked_snapshot.get("ui_sets_gameplay_truth", true)), "Runtime use state does not set gameplay truth")
	_assert(int(blocked_snapshot.get("interaction_count", 0)) == 3, "Runtime use state carries three interactions")
	_assert(String(_find_interaction(blocked_snapshot, "cargo_landing_hold").get("runtime_use_status", "")) == "blocked", "Cargo hold remains blocked before AA is disabled")
	_assert(String(_find_interaction(blocked_snapshot, "station_computer").get("runtime_use_status", "")) == "out_of_range", "Station computer is out of range from spawn")

	var unblocked_gate_snapshot: Dictionary = {
		"completed_step_ids": ["disable_air_defense"],
		"gates": [
			{"step_id": "disable_air_defense", "status": "complete", "complete": true},
			{"step_id": "occupy_station_computer", "status": "pending", "complete": false},
			{"step_id": "cargo_touchdown_extract", "status": "pending", "complete": false},
		],
	}
	var unblocked_binding_snapshot: Dictionary = Dictionary(INTERACTION_BINDING_SCRIPT.call("build_snapshot", scenario, terrain_map_data, {"scenario_gate_snapshot": unblocked_gate_snapshot}))
	var unblocked_snapshot: Dictionary = Dictionary(INTERACTION_USE_STATE_SCRIPT.call("build_snapshot", unblocked_binding_snapshot, terrain_map_data, {
		"current_team_id": "team_alpha",
		"fireteam_positions": [
			{"fireteam_id": "ft1", "team_id": "team_alpha", "position": spawn_position, "active": true},
		],
	}))
	_assert(String(_find_interaction(unblocked_snapshot, "cargo_landing_hold").get("runtime_use_status", "")) == "usable", "Cargo hold becomes usable when AA is complete and FT is in range")
	_assert(String(unblocked_snapshot.get("next_usable_interaction_id", "")) == "cargo_landing_hold", "Cargo hold is the next usable interaction near spawn")

	var objective_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var in_progress_snapshot: Dictionary = Dictionary(INTERACTION_USE_STATE_SCRIPT.call("build_snapshot", unblocked_binding_snapshot, terrain_map_data, {
		"current_team_id": "team_alpha",
		"fireteam_positions": [
			{"fireteam_id": "ft1", "team_id": "team_alpha", "position": objective_position, "active": true},
		],
		"interaction_states": {
			"station_computer": {"state": "operating", "hold_seconds": 9.0, "progress": 0.5, "team_id": "team_alpha"},
		},
	}))
	var station_entry: Dictionary = _find_interaction(in_progress_snapshot, "station_computer")
	_assert(String(station_entry.get("runtime_use_status", "")) == "in_progress", "Station computer reports in-progress when runtime state is operating")
	_assert(float(station_entry.get("progress", 0.0)) == 0.5, "Station computer preserves runtime progress")

	var complete_gate_snapshot: Dictionary = {
		"completed_step_ids": ["disable_air_defense", "occupy_station_computer", "cargo_touchdown_extract"],
		"gates": [
			{"step_id": "disable_air_defense", "status": "complete", "complete": true},
			{"step_id": "occupy_station_computer", "status": "complete", "complete": true},
			{"step_id": "cargo_touchdown_extract", "status": "complete", "complete": true},
		],
	}
	var complete_binding_snapshot: Dictionary = Dictionary(INTERACTION_BINDING_SCRIPT.call("build_snapshot", scenario, terrain_map_data, {"scenario_gate_snapshot": complete_gate_snapshot}))
	var complete_snapshot: Dictionary = Dictionary(INTERACTION_USE_STATE_SCRIPT.call("build_snapshot", complete_binding_snapshot, terrain_map_data, {
		"current_team_id": "team_alpha",
		"fireteam_positions": [{"fireteam_id": "ft1", "team_id": "team_alpha", "position": objective_position, "active": true}],
	}))
	_assert(int(complete_snapshot.get("complete_count", 0)) == 3, "Completed gates mark all interactions complete in use state")


func _test_controller_runtime_use_state_snapshot() -> void:
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
	var snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_runtime_use_state_snapshot"))
	_assert(String(snapshot.get("schema", "")) == INTERACTION_USE_STATE_SCRIPT.SNAPSHOT_SCHEMA, "Controller exposes TASK_675 runtime use state snapshot")
	_assert(int(snapshot.get("interaction_count", 0)) == 3, "Controller runtime use state sees three interactions")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Controller runtime use state is read-only")
	_assert(int(snapshot.get("fireteam_position_count", 0)) >= 1, "Controller runtime use state reads at least one active fireteam position")

	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", SCENARIO_PATH)
		mission_setup.set("defer_friendly_runtime_activation", false)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _find_interaction(snapshot: Dictionary, interaction_id: String) -> Dictionary:
	for interaction_variant in Array(snapshot.get("interactions", [])):
		var interaction: Dictionary = Dictionary(interaction_variant)
		if String(interaction.get("interaction_id", "")).strip_edges() == interaction_id:
			return interaction
	return {}


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
