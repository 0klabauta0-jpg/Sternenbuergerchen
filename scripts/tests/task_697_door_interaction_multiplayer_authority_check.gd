extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MISSION_INTERACTION_DOOR_MULTIPLAYER_AUTHORITY_SCRIPT: GDScript = preload("res://scripts/mission/mission_interaction_door_multiplayer_authority.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_697_door_interaction_multiplayer_authority_check.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_697_door_interaction_multiplayer_authority_check_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_interaction_multiplayer_authority_check.json"
const DOOR_INTERACTION_ID: String = "station_door_authority_probe"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_697 Door Interaction Multiplayer Authority Check ===")
	_test_docs()
	_test_contract_projection()
	await _test_door_authority_path()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_697: FAILED")
		quit(1)
		return
	print("TASK_697: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_697 task file exists")
	_assert(task_text.contains("Door Interaction Multiplayer Authority Check"), "Task documents door multiplayer authority check")
	_assert(contract_text.contains("Door Interaction Multiplayer Authority Check"), "Interaction contract documents door multiplayer authority check")
	_assert(status_text.contains("TASK_697 - Door Interaction Multiplayer Authority Check"), "Implementation status tracks TASK_697")
	_assert(roadmap_text.contains("TASK_697 - Door Interaction Multiplayer Authority Check (implementiert)"), "Roadmap marks TASK_697 implemented")
	_assert(handbook_text.contains("TASK_697 - Door Interaction Multiplayer Authority Check"), "Current handbook references TASK_697")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_multiplayer_authority.manifest_path"'), "Current handbook exports TASK_697 manifest path")


func _test_contract_projection() -> void:
	var hook: Dictionary = {
		"accepted": true,
		"requires_go": true,
		"interaction_id": "door_projection_probe",
		"interaction_type": "door",
		"fireteam_id": "blue",
		"command_type": "take",
		"phase": 1,
		"required_order": "breach",
		"duration_seconds": 2.0,
		"door_runtime_state_target": "door_open",
		"door_runtime_producer": "MissionInteractionDoorRuntimeCollisionLOS",
	}
	var command: Dictionary = Dictionary(MISSION_INTERACTION_DOOR_MULTIPLAYER_AUTHORITY_SCRIPT.call(
		"build_network_command_from_hook",
		hook,
		"unit_alpha",
		"team_alpha",
		Vector2(24.0, 32.0)
	))
	_assert(String(command.get("contract_category", "")) == "commander_command", "Door hook projects to commander command category")
	_assert(String(command.get("command_type", "")) == "take", "Door hook projects breach to take command")
	_assert(String(command.get("unit_id", "")) == "unit_alpha", "Door command carries unit id")
	_assert(String(command.get("team_id", "")) == "team_alpha", "Door command carries team id")
	_assert(String(command.get("interaction_id", "")) == "door_projection_probe", "Door command carries interaction id")
	_assert(bool(command.get("door_runtime_hook", false)), "Door command carries runtime hook metadata")
	_assert(String(command.get("door_runtime_state_target", "")) == "door_open", "Door command carries requested runtime target as metadata")
	_assert(not command.has("runtime_state"), "Door command does not carry forbidden runtime_state mutation")
	_assert(bool(command.get("requires_go", false)), "Door command still records GO requirement")


func _test_door_authority_path() -> void:
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
	var simulation_root: Node = scene.get_node_or_null("SimulationRoot")
	_assert(controller != null and combat_driver != null and mission_setup != null and terrain_registry != null and simulation_root != null, "Mission scene exposes controller, driver, setup, terrain registry and simulation root")
	if controller == null or combat_driver == null or mission_setup == null or terrain_registry == null or simulation_root == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team_assignments", {
		1: "team_alpha",
		2: "team_bravo",
	})
	simulation_root.call("set_peer_role", 1, "host")
	simulation_root.call("set_peer_role", 2, "commander")

	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	var door_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var door_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", door_position))
	_move_fireteam_units(scene, fireteam_id, door_position)
	var unit_id: String = _register_first_fireteam_unit(scene, simulation_root, fireteam_id)
	_assert(not unit_id.is_empty(), "Door authority test registers a known fireteam unit")
	await _wait_frames(2)

	var hook: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_door_use_breach_command_hook", DOOR_INTERACTION_ID))
	_assert(bool(hook.get("accepted", false)), "Door authority hook is accepted")
	var projected_command: Dictionary = Dictionary(controller.call(
		"build_mission_interaction_door_multiplayer_network_command",
		unit_id,
		"team_alpha",
		door_position
	))
	_assert(not projected_command.is_empty(), "Door authority command projection is not empty")
	_assert(String(projected_command.get("contract_category", "")) == "commander_command", "Door authority command uses commander contract category")
	_assert(String(projected_command.get("source_context", "")) == "mission_interaction_door_breach_command", "Door authority command records source context")

	var host_submission: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", projected_command, 1))
	_assert(bool(host_submission.get("accepted", false)), "Authority accepts own-team door command")
	var foreign_submission: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", projected_command.duplicate(true), 2))
	_assert(not bool(foreign_submission.get("accepted", true)), "Wrong-team peer is rejected for door command")
	_assert(["peer_team_mismatch", "unit_team_mismatch"].has(String(foreign_submission.get("reason", ""))), "Wrong-team rejection names team mismatch")
	var mutation_command: Dictionary = projected_command.duplicate(true)
	mutation_command["runtime_state"] = "door_open"
	var state_mutation_submission: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", mutation_command, 1))
	_assert(not bool(state_mutation_submission.get("accepted", true)), "Door runtime state mutation payload is rejected")
	_assert(String(state_mutation_submission.get("reason", "")).begins_with("state_mutation_key:"), "Door runtime state rejection names forbidden key")

	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": DOOR_INTERACTION_ID,
		"state": "operating",
		"complete": true,
		"hold_seconds": 2.0,
		"duration_seconds": 2.0,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "open_station_door",
		"required_state": "door_open",
		"interaction_type": "door",
		"command_type": "breach",
	})
	var open_snapshot: Dictionary = Dictionary(controller.call("apply_mission_interaction_door_runtime_collision_los_snapshot"))
	var open_override: Dictionary = Dictionary(terrain_registry.call("get_runtime_tile_override", door_grid))
	_assert(bool(open_snapshot.get("producer_applied", false)), "Runtime producer applies door authority state")
	_assert(String(open_override.get("source_runtime_visual_state", "")) == "open", "Door authority path opens runtime visual state")
	_assert(bool(open_override.get("walkable_override", false)), "Door authority path opens walkability")
	_assert(not bool(open_override.get("blocks_los_override", true)), "Door authority path opens LOS")

	var authority_results: Dictionary = {
		"projected_command": projected_command,
		"host_submission": host_submission,
		"foreign_submission": foreign_submission,
		"state_mutation_submission": state_mutation_submission,
	}
	var authority_snapshot: Dictionary = Dictionary(controller.call("get_mission_interaction_door_multiplayer_authority_snapshot", authority_results))
	_assert(String(authority_snapshot.get("gate", "")) == "pass", "Door multiplayer authority snapshot passes")
	_assert(bool(authority_snapshot.get("host_command_accepted", false)), "Authority snapshot records host accept")
	_assert(bool(authority_snapshot.get("foreign_team_rejected", false)), "Authority snapshot records wrong-team reject")
	_assert(bool(authority_snapshot.get("state_mutation_rejected", false)), "Authority snapshot records state mutation reject")
	_assert(bool(authority_snapshot.get("door_runtime_open_override", false)), "Authority snapshot records open door runtime override")
	_assert(bool(authority_snapshot.get("read_only", false)), "Authority snapshot is read-only")
	_assert(not bool(authority_snapshot.get("ui_sets_gameplay_truth", true)), "Authority snapshot does not set gameplay truth")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(command_feedback.has("mission_interaction_door_multiplayer_authority"), "Command feedback exports door authority snapshot")
	_assert(String(command_feedback.get("mission_interaction_door_multiplayer_authority_summary", "")).contains("Door authority"), "Command feedback exports door authority summary")

	_write_manifest({
		"schema": "sternenbuergerchen.door_interaction_multiplayer_authority_manifest.v1",
		"task_id": "TASK_697",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"projected_command_category": String(projected_command.get("contract_category", "")),
		"projected_command_source_context": String(projected_command.get("source_context", "")),
		"host_command_accepted": bool(host_submission.get("accepted", false)),
		"foreign_team_rejected": not bool(foreign_submission.get("accepted", true)),
		"foreign_team_reject_reason": String(foreign_submission.get("reason", "")),
		"state_mutation_rejected": not bool(state_mutation_submission.get("accepted", true)),
		"state_mutation_reject_reason": String(state_mutation_submission.get("reason", "")),
		"door_runtime_open_override": bool(authority_snapshot.get("door_runtime_open_override", false)),
		"authority_gate": String(authority_snapshot.get("gate", "")),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_697 manifest is written")

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
			"display_name": "Station Door Authority Probe",
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
		_assert(false, "Can open TASK_697 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_697 temp scenario is written")


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


func _register_first_fireteam_unit(scene: Node, simulation_root: Node, fireteam_id: String) -> String:
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_fireteam_id"):
			continue
		if String(child.call("get_fireteam_id")).strip_edges().to_lower() != fireteam_id:
			continue
		var unit_id: String = child.name
		if child.has_method("get_unit_id"):
			unit_id = String(child.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			unit_id = child.name
		if child.has_method("set_team_id"):
			child.call("set_team_id", "team_alpha")
		elif "team_id" in child:
			child.set("team_id", "team_alpha")
		if simulation_root != null and simulation_root.has_method("register_known_unit"):
			simulation_root.call("register_known_unit", unit_id, child)
		return unit_id
	return ""


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_697 manifest for writing")
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
