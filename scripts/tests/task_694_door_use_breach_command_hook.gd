extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_694_door_use_breach_command_hook.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_694_door_use_breach_command_hook_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_use_breach_command_hook.json"
const DOOR_INTERACTION_ID: String = "station_door_breach_probe"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_694 Door Use/Breach Command Hook ===")
	_test_docs()
	await _test_door_use_breach_hook()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_694: FAILED")
		quit(1)
		return
	print("TASK_694: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_694 task file exists")
	_assert(task_text.contains("Door Use/Breach Command Hook"), "Task documents door use/breach hook")
	_assert(contract_text.contains("Door Use/Breach Command Hook"), "Interaction contract documents door use/breach hook")
	_assert(status_text.contains("TASK_694 - Door Use/Breach Command Hook"), "Implementation status tracks TASK_694")
	_assert(roadmap_text.contains("TASK_694 - Door Use/Breach Command Hook (implementiert)"), "Roadmap marks TASK_694 implemented")
	_assert(handbook_text.contains("TASK_694 - Door Use/Breach Command Hook"), "Current handbook references TASK_694")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_use_breach_command_hook.manifest_path"'), "Current handbook exports TASK_694 manifest path")


func _test_door_use_breach_hook() -> void:
	_ensure_output_dir()
	_write_test_scenario()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	var terrain_registry: Node = scene.get_node_or_null("TerrainRegistry")
	_assert(controller != null and combat_driver != null and mission_setup != null and terrain_registry != null, "Mission scene exposes controller, driver, setup and terrain registry")
	if controller == null or combat_driver == null or mission_setup == null or terrain_registry == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var door_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var door_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", door_position))
	_move_fireteam_units(scene, fireteam_id, door_position)
	await _wait_frames(2)

	var hook: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_door_use_breach_command_hook", DOOR_INTERACTION_ID))
	_assert(bool(hook.get("accepted", false)), "Door breach hook is accepted")
	_assert(bool(hook.get("requires_go", false)), "Door breach hook still requires GO")
	_assert(String(hook.get("interaction_id", "")) == DOOR_INTERACTION_ID, "Door breach hook targets interaction")
	_assert(String(hook.get("command_type", "")) == "take", "Door breach hook maps breach to take waypoint command")
	_assert(String(hook.get("required_order", "")) == "breach", "Door breach hook keeps required order")
	_assert(String(hook.get("door_runtime_state_target", "")) == "door_open", "Door breach hook targets door_open runtime state")
	_assert(String(hook.get("last_command_text", "")).contains("BREACH"), "Door breach hook writes readable command text")

	var waypoint: Dictionary = _find_waypoint_for_interaction(controller, fireteam_id, DOOR_INTERACTION_ID)
	var metadata: Dictionary = Dictionary(waypoint.get("metadata", {}))
	_assert(not waypoint.is_empty(), "Door breach hook creates waypoint")
	_assert(bool(metadata.get("door_runtime_hook", false)), "Waypoint metadata marks door runtime hook")
	_assert(String(metadata.get("door_runtime_state_target", "")) == "door_open", "Waypoint metadata carries door target state")
	_assert(String(metadata.get("door_runtime_producer", "")) == "MissionInteractionDoorRuntimeCollisionLOS", "Waypoint metadata names door producer")
	_assert(absf(float(waypoint.get("hold_duration_seconds", 0.0)) - 2.0) < 0.001, "Door waypoint carries breach duration")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(bool(command_feedback.get("mission_interaction_door_use_breach_command_hook_accepted", false)), "Command feedback exports accepted door hook")
	_assert(String(command_feedback.get("mission_interaction_door_use_breach_command_hook_line", "")).contains("BREACH"), "Command feedback exports breach line")

	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": DOOR_INTERACTION_ID,
		"state": "operating",
		"complete": true,
		"hold_seconds": float(metadata.get("duration_seconds", waypoint.get("hold_duration_seconds", 0.0))),
		"duration_seconds": float(metadata.get("duration_seconds", waypoint.get("hold_duration_seconds", 0.0))),
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": String(metadata.get("step_id", "")),
		"required_state": String(metadata.get("required_state", "door_open")),
		"interaction_type": String(metadata.get("interaction_type", "door")),
		"command_type": String(waypoint.get("command_type", "take")),
	})
	var open_snapshot: Dictionary = Dictionary(controller.call("apply_mission_interaction_door_runtime_collision_los_snapshot"))
	var open_override: Dictionary = Dictionary(terrain_registry.call("get_runtime_tile_override", door_grid))
	_assert(bool(open_snapshot.get("producer_applied", false)), "Door hook metadata can drive runtime producer")
	_assert(String(open_override.get("source_runtime_visual_state", "")) == "open", "Door hook opens runtime visual state")
	_assert(bool(open_override.get("walkable_override", false)), "Door hook opens effective walkability")
	_assert(not bool(open_override.get("blocks_los_override", true)), "Door hook opens effective LOS")

	_write_manifest({
		"schema": "sternenbuergerchen.door_use_breach_command_hook_manifest.v1",
		"task_id": "TASK_694",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"hook_accepted": bool(hook.get("accepted", false)),
		"requires_go": bool(hook.get("requires_go", false)),
		"waypoint_id": String(hook.get("waypoint_id", "")),
		"door_runtime_state_target": String(hook.get("door_runtime_state_target", "")),
		"open_walkable_override": bool(open_override.get("walkable_override", false)),
		"open_blocks_los_override": bool(open_override.get("blocks_los_override", true)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_694 manifest is written")

	scene.queue_free()
	await _wait_frames(2)


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	vertical_slice["interaction_points"] = [
		{
			"interaction_id": DOOR_INTERACTION_ID,
			"display_name": "Station Door Breach Probe",
			"interaction_type": "door",
			"marker_id": "objective_point",
			"required_order": "breach",
			"duration_seconds": 2.0,
			"radius_world": 128.0,
			"step_id": "open_station_door",
			"gate_id": "open_station_door",
			"required_state": "door_open",
			"required_team": "team_alpha",
			"asset_hint": "station_set_door_single_closed"
		}
	]
	scenario["vertical_slice"] = vertical_slice
	var file := FileAccess.open(TEST_SCENARIO_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_694 test scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_694 temp scenario is written")


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
		mission_setup.set("scenario_file_path", TEST_SCENARIO_PATH)
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


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_694 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


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
