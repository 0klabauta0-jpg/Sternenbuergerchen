extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_678_mission_interaction_runtime_progress.md"
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
	print("=== TASK_678 Mission Interaction Runtime Progress ===")
	_test_docs()
	await _test_controller_intent_duration_and_runtime_progress()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_678: FAILED")
		quit(1)
		return
	print("TASK_678: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_678 task file exists")
	_assert(task_text.contains("Mission Interaction Runtime Progress"), "Task documents runtime progress")
	_assert(contract_text.contains("Runtime Progress"), "Interaction contract documents runtime progress")
	_assert(contract_text.contains("update_mission_interaction_runtime_progress"), "Interaction contract names runtime progress driver method")
	_assert(_read_text(STATUS_PATH).contains("TASK_678 - Mission Interaction Runtime Progress"), "Implementation status tracks TASK_678")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_678 - Mission Interaction Runtime Progress"), "Roadmap lists TASK_678")
	_assert(_read_text(HANDBOOK_PATH).contains("TASK_678 - Mission Interaction Runtime Progress"), "Current handbook references TASK_678")


func _test_controller_intent_duration_and_runtime_progress() -> void:
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, combat driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return
	combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var objective_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, objective_position)
	await _wait_frames(2)
	_assert(not fireteam_id.is_empty() and PackedStringArray(controller.call("get_selected_fireteam_ids")).has(fireteam_id), "Verifier selects a fireteam for runtime progress")

	var station_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "station_computer"))
	_assert(bool(station_intent.get("accepted", false)), "Station computer use intent can be created")
	var station_waypoint: Dictionary = _find_waypoint_for_interaction(controller, fireteam_id, "station_computer")
	_assert(String(station_waypoint.get("command_type", "")) == "take", "Station computer intent keeps take command")
	_assert(absf(float(station_waypoint.get("hold_duration_seconds", 0.0)) - 18.0) < 0.001, "Station computer waypoint carries 18s hold duration")
	var station_metadata: Dictionary = Dictionary(station_waypoint.get("metadata", {}))
	_assert(String(station_metadata.get("step_id", "")) == "occupy_station_computer", "Station waypoint metadata carries step id")
	_assert(String(station_metadata.get("required_state", "")) == "computer_controlled", "Station waypoint metadata carries required state")

	var progress_state: Dictionary = Dictionary(combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "station_computer",
		"state": "operating",
		"hold_seconds": 9.0,
		"duration_seconds": 18.0,
		"progress": 0.5,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "occupy_station_computer",
		"required_state": "computer_controlled",
		"interaction_type": "computer",
		"command_type": "take",
	}))
	_assert(String(progress_state.get("state", "")) == "operating", "Runtime progress driver records operating state")
	_assert(absf(float(progress_state.get("progress", 0.0)) - 0.5) < 0.001, "Runtime progress driver records progress")
	var in_progress_entry: Dictionary = _find_interaction(Dictionary(controller.call("get_mission_interaction_runtime_use_state_snapshot")), "station_computer")
	_assert(String(in_progress_entry.get("runtime_use_status", "")) == "in_progress", "Controller use state reads station computer in progress")
	_assert(absf(float(in_progress_entry.get("progress", 0.0)) - 0.5) < 0.001, "Controller use state preserves station progress")

	var complete_state: Dictionary = Dictionary(combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "station_computer",
		"state": "operating",
		"complete": true,
		"hold_seconds": 18.0,
		"duration_seconds": 18.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "occupy_station_computer",
		"required_state": "computer_controlled",
		"interaction_type": "computer",
		"command_type": "take",
	}))
	_assert(bool(complete_state.get("complete", false)), "Runtime progress driver completes station computer")
	var gate_snapshot: Dictionary = Dictionary(combat_driver.call("get_mission_scenario_runtime_gate_snapshot"))
	_assert(_gate_complete(gate_snapshot, "occupy_station_computer"), "Station computer completion sets scenario gate")
	var complete_entry: Dictionary = _find_interaction(Dictionary(controller.call("get_mission_interaction_runtime_use_state_snapshot")), "station_computer")
	_assert(String(complete_entry.get("runtime_use_status", "")) == "complete", "Controller use state reads station computer complete")

	_move_fireteam_units(scene, fireteam_id, Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO)))
	await _wait_frames(2)
	var cargo_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "cargo_landing_hold"))
	_assert(bool(cargo_intent.get("accepted", false)), "Cargo use intent can be created after AA complete")
	var cargo_waypoint: Dictionary = _find_waypoint_for_interaction(controller, fireteam_id, "cargo_landing_hold")
	_assert(String(cargo_waypoint.get("command_type", "")) == "defend", "Cargo intent keeps defend command")
	_assert(absf(float(cargo_waypoint.get("hold_duration_seconds", 0.0)) - 12.0) < 0.001, "Cargo waypoint carries 12s hold duration")
	var cargo_state: Dictionary = Dictionary(combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "cargo_landing_hold",
		"state": "holding",
		"complete": true,
		"hold_seconds": 12.0,
		"duration_seconds": 12.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "cargo_touchdown_extract",
		"required_state": "cargo_departed",
		"interaction_type": "hold_zone",
		"command_type": "defend",
	}))
	_assert(bool(cargo_state.get("complete", false)), "Runtime progress driver completes cargo hold")
	gate_snapshot = Dictionary(combat_driver.call("get_mission_scenario_runtime_gate_snapshot"))
	_assert(_gate_complete(gate_snapshot, "cargo_touchdown_extract"), "Cargo completion sets scenario gate")
	var runtime_snapshot: Dictionary = Dictionary(combat_driver.call("get_mission_interaction_runtime_state_snapshot"))
	_assert(int(runtime_snapshot.get("complete_count", 0)) >= 2, "Runtime progress snapshot counts completed interactions")
	_assert(not bool(runtime_snapshot.get("ui_sets_gameplay_truth", true)), "Runtime progress snapshot does not claim UI truth")

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


func _select_first_available_fireteam(controller: Node, mission_setup: Node) -> String:
	var available_ids: PackedStringArray = PackedStringArray(controller.call("_get_available_fireteam_ids"))
	var candidate_id: String = ""
	if not available_ids.is_empty():
		candidate_id = String(available_ids[0]).strip_edges().to_lower()
	else:
		var configured_ids: PackedStringArray = PackedStringArray(mission_setup.get("selected_team_fireteam_ids"))
		if not configured_ids.is_empty():
			candidate_id = String(configured_ids[0]).strip_edges().to_lower()
	if candidate_id.is_empty():
		candidate_id = "ft1"
	controller.call("_set_selected_fireteams", PackedStringArray([candidate_id]), false)
	var selected_ids: PackedStringArray = PackedStringArray(controller.call("get_selected_fireteam_ids"))
	return String(selected_ids[0]).strip_edges().to_lower() if not selected_ids.is_empty() else ""


func _find_waypoint_for_interaction(controller: Node, fireteam_id: String, interaction_id: String) -> Dictionary:
	for plan_variant in Array(controller.call("_serialize_order_plans")):
		var plan: Dictionary = Dictionary(plan_variant)
		if String(plan.get("fireteam_id", "")).strip_edges().to_lower() != fireteam_id:
			continue
		for waypoint_variant in Array(plan.get("waypoints", [])):
			var waypoint: Dictionary = Dictionary(waypoint_variant)
			if String(Dictionary(waypoint.get("metadata", {})).get("interaction_id", "")) == interaction_id:
				return waypoint
	return {}


func _move_fireteam_units(scene: Node, fireteam_id: String, center_position: Vector2) -> void:
	var offset_index: int = 0
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var offset: Vector2 = Vector2(float(offset_index % 2) * 10.0, float(int(offset_index / 2)) * 10.0)
		(child as Node2D).global_position = center_position + offset
		offset_index += 1


func _find_interaction(snapshot: Dictionary, interaction_id: String) -> Dictionary:
	for interaction_variant in Array(snapshot.get("interactions", [])):
		var interaction: Dictionary = Dictionary(interaction_variant)
		if String(interaction.get("interaction_id", "")).strip_edges() == interaction_id:
			return interaction
	return {}


func _gate_complete(snapshot: Dictionary, step_id: String) -> bool:
	for gate_variant in Array(snapshot.get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")).strip_edges() == step_id:
			return bool(gate.get("complete", false))
	return false


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
