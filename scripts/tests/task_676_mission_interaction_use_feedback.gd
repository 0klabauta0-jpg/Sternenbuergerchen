extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const INTERACTION_BINDING_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_point_binding.gd")
const INTERACTION_USE_STATE_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_runtime_use_state.gd")
const INTERACTION_USE_FEEDBACK_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_use_feedback.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_676_mission_interaction_use_feedback.md"
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
	print("=== TASK_676 Mission Interaction Use Feedback ===")
	_test_docs()
	_test_use_feedback_helper()
	await _test_controller_and_command_feedback_export()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_676: FAILED")
		quit(1)
		return
	print("TASK_676: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_676 task file exists")
	_assert(task_text.contains("Mission Interaction Use Feedback"), "Task documents use feedback")
	_assert(contract_text.contains("Use Feedback"), "Interaction contract documents Use Feedback")
	_assert(contract_text.contains("MissionInteractionUseFeedback"), "Interaction contract names use feedback helper")
	_assert(_read_text(STATUS_PATH).contains("TASK_676 - Mission Interaction Use Feedback"), "Implementation status tracks TASK_676")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_676 - Mission Interaction Use Feedback"), "Roadmap lists TASK_676")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_676 - Mission Interaction Use Feedback"), "Current handbook references TASK_676")


func _test_use_feedback_helper() -> void:
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var scenario: Dictionary = _load_json_dict(SCENARIO_PATH)
	_assert(terrain_map_data != null and not bool(terrain_map_data.call("has_load_issue")), "Frontier Probe terrain map loads")
	_assert(not scenario.is_empty(), "Frontier Probe scenario loads")
	if terrain_map_data == null or scenario.is_empty():
		return
	var spawn_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	var objective_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))

	var blocked_feedback: Dictionary = _build_feedback_snapshot(scenario, terrain_map_data, _blocked_gate_snapshot(), spawn_position)
	_assert(String(blocked_feedback.get("schema", "")) == INTERACTION_USE_FEEDBACK_SCRIPT.SNAPSHOT_SCHEMA, "Use feedback schema is stable")
	_assert(not bool(blocked_feedback.get("ui_sets_gameplay_truth", true)), "Use feedback does not set gameplay truth")
	_assert(String(blocked_feedback.get("primary_interaction_id", "")) == "cargo_landing_hold", "Blocked cargo hold becomes primary near spawn")
	_assert(String(blocked_feedback.get("primary_status", "")) == "blocked", "Blocked cargo hold reports blocked status")
	_assert(String(blocked_feedback.get("feedback_line", "")).contains("CARGO blockiert"), "Blocked cargo line explains block")
	_assert(String(blocked_feedback.get("feedback_line", "")).contains("disable_air_defense"), "Blocked cargo line names AA blocker")

	var usable_feedback: Dictionary = _build_feedback_snapshot(scenario, terrain_map_data, _aa_complete_gate_snapshot(), spawn_position)
	_assert(String(usable_feedback.get("primary_interaction_id", "")) == "cargo_landing_hold", "Cargo hold becomes primary usable interaction")
	_assert(String(usable_feedback.get("primary_status", "")) == "usable", "Cargo hold reports usable status")
	_assert(String(usable_feedback.get("feedback_line", "")).contains("CARGO bereit"), "Cargo usable line reads as ready")
	_assert(String(usable_feedback.get("action_label", "")) == "DEFEND", "Cargo usable line exports required order action")
	_assert(bool(usable_feedback.get("can_prompt_use", false)), "Usable cargo can prompt use")

	var in_progress_feedback: Dictionary = _build_feedback_snapshot(
		scenario,
		terrain_map_data,
		_aa_complete_gate_snapshot(),
		objective_position,
		{"station_computer": {"state": "operating", "hold_seconds": 9.0, "progress": 0.5, "team_id": "team_alpha"}}
	)
	_assert(String(in_progress_feedback.get("primary_interaction_id", "")) == "station_computer", "Operating station computer becomes primary")
	_assert(String(in_progress_feedback.get("primary_status", "")) == "in_progress", "Station computer reports in-progress feedback")
	_assert(String(in_progress_feedback.get("feedback_line", "")).contains("COM laeuft 50%"), "Station computer line shows compact progress")
	_assert(String(in_progress_feedback.get("action_label", "")) == "HALTEN", "In-progress feedback exports hold action")


func _test_controller_and_command_feedback_export() -> void:
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
	var feedback: Dictionary = Dictionary(controller.call("get_mission_interaction_use_feedback_snapshot"))
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var exported_feedback: Dictionary = Dictionary(command_feedback.get("mission_interaction_use_feedback", {}))
	_assert(String(feedback.get("schema", "")) == INTERACTION_USE_FEEDBACK_SCRIPT.SNAPSHOT_SCHEMA, "Controller exposes TASK_676 use feedback snapshot")
	_assert(not String(feedback.get("feedback_line", "")).strip_edges().is_empty(), "Controller use feedback line is not empty")
	_assert(not bool(feedback.get("ui_sets_gameplay_truth", true)), "Controller use feedback remains read-only")
	_assert(String(exported_feedback.get("schema", "")) == INTERACTION_USE_FEEDBACK_SCRIPT.SNAPSHOT_SCHEMA, "Command feedback exports use feedback snapshot")
	_assert(String(command_feedback.get("mission_interaction_use_feedback_line", "")) == String(exported_feedback.get("feedback_line", "")), "Command feedback exports the same feedback line")
	_assert(String(command_feedback.get("mission_interaction_use_feedback_action", "")) == String(exported_feedback.get("action_label", "")), "Command feedback exports the same action label")

	scene.queue_free()
	await _wait_frames(2)


func _build_feedback_snapshot(scenario: Dictionary, terrain_map_data, gate_snapshot: Dictionary, fireteam_position: Vector2, interaction_states: Dictionary = {}) -> Dictionary:
	var binding_snapshot: Dictionary = Dictionary(INTERACTION_BINDING_SCRIPT.call("build_snapshot", scenario, terrain_map_data, {"scenario_gate_snapshot": gate_snapshot}))
	var use_state: Dictionary = Dictionary(INTERACTION_USE_STATE_SCRIPT.call("build_snapshot", binding_snapshot, terrain_map_data, {
		"current_team_id": "team_alpha",
		"fireteam_positions": [{"fireteam_id": "ft1", "team_id": "team_alpha", "position": fireteam_position, "active": true}],
		"interaction_states": interaction_states,
	}))
	return Dictionary(INTERACTION_USE_FEEDBACK_SCRIPT.call("build_snapshot", use_state, {"selected_fireteam_ids": ["ft1"]}))


func _blocked_gate_snapshot() -> Dictionary:
	return {
		"completed_step_ids": [],
		"gates": [
			{"step_id": "disable_air_defense", "status": "pending", "complete": false},
			{"step_id": "occupy_station_computer", "status": "pending", "complete": false},
			{"step_id": "cargo_touchdown_extract", "status": "blocked", "complete": false},
		],
	}


func _aa_complete_gate_snapshot() -> Dictionary:
	return {
		"completed_step_ids": ["disable_air_defense"],
		"gates": [
			{"step_id": "disable_air_defense", "status": "complete", "complete": true},
			{"step_id": "occupy_station_computer", "status": "pending", "complete": false},
			{"step_id": "cargo_touchdown_extract", "status": "pending", "complete": false},
		],
	}


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
