extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const SIMULATION_ROOT_SCRIPT: GDScript = preload("res://scripts/core/simulation_root.gd")
const UNIT_REGISTRY_SCRIPT: GDScript = preload("res://scripts/registries/unit_registry.gd")
const TEST_UNIT_SCRIPT: GDScript = preload("res://scripts/npc/test_unit.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_714_station_route_multiplayer_scenario_guard.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_714_station_route_multiplayer_scenario_guard_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_multiplayer_scenario_guard.json"
const DOOR_INTERACTION_ID: String = "station_route_multiplayer_guard_door"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_714 Station Route Multiplayer Scenario Guard ===")
	_test_docs()
	await _test_station_route_multiplayer_guard()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_714: FAILED")
		quit(1)
		return
	print("TASK_714: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_714 task file exists")
	_assert(task_text.contains("Station Route Multiplayer Scenario Guard"), "Task documents Station Route Multiplayer Scenario Guard")
	_assert(contract_text.contains("Station Route Multiplayer Scenario Guard"), "Interaction contract documents TASK_714")
	_assert(status_text.contains("TASK_714 - Station Route Multiplayer Scenario Guard"), "Implementation status tracks TASK_714")
	_assert(roadmap_text.contains("TASK_714 - Station Route Multiplayer Scenario Guard (implementiert)"), "Roadmap marks TASK_714 implemented")
	_assert(report_text.contains("TASK_714 - Station Route Multiplayer Scenario Guard"), "Current report references TASK_714")
	_assert(report_text.contains('data-export-key="station_route_multiplayer_scenario_guard.manifest_path"'), "Current report exports TASK_714 manifest path")


func _test_station_route_multiplayer_guard() -> void:
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

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)), "Combat driver configures TASK_714 scenario")
	_configure_host_authority(simulation_root)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var cargo_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	var door_grid: Vector2i = Vector2i(terrain_registry.call("world_to_grid", station_position))
	_move_fireteam_units(scene, fireteam_id, station_position)
	var unit_id: String = _register_first_fireteam_unit(scene, simulation_root, fireteam_id)
	_assert(not unit_id.is_empty(), "Verifier registers a known Alpha unit")
	await _wait_frames(2)

	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	var before_door_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(before_door_gate.get("next_step_id", "")) == "occupy_station_computer", "AA complete points to station computer before Door")

	var hook: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_door_use_breach_command_hook", DOOR_INTERACTION_ID))
	_assert(bool(hook.get("accepted", false)), "Door hook is accepted for selected Alpha fireteam")
	var projected_command: Dictionary = Dictionary(controller.call(
		"build_mission_interaction_door_multiplayer_network_command",
		unit_id,
		"team_alpha",
		station_position
	))
	_assert(String(projected_command.get("source_context", "")) == "mission_interaction_door_breach_command", "Door command records source context")
	var host_submission: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", projected_command, 1))
	var wrong_team_submission: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", projected_command.duplicate(true), 2))
	var mutation_command: Dictionary = projected_command.duplicate(true)
	mutation_command["runtime_state"] = "door_open"
	var mutation_submission: Dictionary = Dictionary(simulation_root.call("submit_network_command_for_peer", mutation_command, 1))
	_assert(bool(host_submission.get("accepted", false)), "Peer 1 Alpha door command is accepted")
	_assert(not bool(wrong_team_submission.get("accepted", true)), "Peer 2 Bravo is rejected for Alpha door command")
	_assert(String(wrong_team_submission.get("reason", "")) == "peer_team_mismatch" or String(wrong_team_submission.get("reason", "")) == "unit_team_mismatch", "Wrong-team reject names a team mismatch")
	_assert(not bool(mutation_submission.get("accepted", true)), "Runtime-state mutation command is rejected")
	_assert(String(mutation_submission.get("reason", "")).begins_with("state_mutation_key:"), "Runtime-state mutation reject names forbidden key")

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
	var door_runtime_snapshot: Dictionary = Dictionary(controller.call("apply_mission_interaction_door_runtime_collision_los_snapshot"))
	var open_override: Dictionary = Dictionary(terrain_registry.call("get_runtime_tile_override", door_grid))
	_assert(bool(door_runtime_snapshot.get("producer_applied", false)), "Door runtime producer applies station route state")
	_assert(bool(open_override.get("walkable_override", false)), "Door runtime opens walkability")
	_assert(not bool(open_override.get("blocks_los_override", true)), "Door runtime opens LOS")
	var after_door_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(after_door_gate.get("next_step_id", "")) == "occupy_station_computer", "Door open does not skip station computer")

	combat_driver.call("update_mission_interaction_runtime_progress", {
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
	})
	_move_fireteam_units(scene, fireteam_id, cargo_position)
	await _wait_frames(2)
	var cargo_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(cargo_gate.get("next_step_id", "")) == "cargo_touchdown_extract", "Computer control advances to cargo gate")
	_assert(String(cargo_gate.get("next_interaction_id", "")) == "cargo_landing_hold", "Cargo gate maps to cargo hold")

	combat_driver.call("update_mission_interaction_runtime_progress", {
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
	})
	await _wait_frames(2)
	var complete_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(bool(complete_gate.get("all_gates_complete", false)), "Cargo departed completes Station Route gates")

	var client_root: Node = _build_client_root_from_scene(scene, fireteam_id)
	root.add_child(client_root)
	await _wait_frames(1)
	simulation_root.call(
		"set_multiplayer_snapshot_context",
		{
			"mission_result": {
				"result": "in_progress",
				"friendly_team_id": "team_alpha",
				"winning_team_id": "",
				"win_condition_type": "task714_station_route_guard",
				"objective_captured": bool(complete_gate.get("all_gates_complete", false)),
				"duration_seconds": 44.0,
			},
		}
	)
	var server_snapshot: Dictionary = Dictionary(simulation_root.call("build_multiplayer_snapshot"))
	var client_simulation: Node = client_root.get_node_or_null("ClientSimulationRoot")
	var client_apply_result: Dictionary = Dictionary(client_simulation.call("apply_multiplayer_snapshot", server_snapshot)) if client_simulation != null else {}
	var client_last_state: Dictionary = Dictionary(client_simulation.call("get_last_server_state")) if client_simulation != null else {}
	_assert(String(server_snapshot.get("snapshot_type", "")) == "state", "Server snapshot is built")
	_assert(bool(client_apply_result.get("accepted", false)), "Client accepts station route server snapshot")
	_assert(int(client_apply_result.get("missing_unit_count", -1)) == 0, "Client snapshot apply has no missing units")
	_assert(_snapshot_has_unit(client_last_state, unit_id), "Client receives Alpha unit state")

	var network_snapshot: Dictionary = Dictionary(simulation_root.call("get_network_command_contract_snapshot"))
	_write_manifest({
		"schema": "sternenbuergerchen.station_route_multiplayer_scenario_guard.v1",
		"task_id": "TASK_714",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"door_interaction_id": DOOR_INTERACTION_ID,
		"fireteam_id": fireteam_id,
		"unit_id": unit_id,
		"host_command_accepted": bool(host_submission.get("accepted", false)),
		"wrong_team_rejected": not bool(wrong_team_submission.get("accepted", true)),
		"wrong_team_reject_reason": String(wrong_team_submission.get("reason", "")),
		"state_mutation_rejected": not bool(mutation_submission.get("accepted", true)),
		"door_runtime_open_walkability": bool(open_override.get("walkable_override", false)),
		"door_runtime_open_los": not bool(open_override.get("blocks_los_override", true)),
		"after_door_next_step": String(after_door_gate.get("next_step_id", "")),
		"after_computer_next_step": String(cargo_gate.get("next_step_id", "")),
		"all_gates_complete": bool(complete_gate.get("all_gates_complete", false)),
		"network_accepted_count": int(network_snapshot.get("accepted_count", 0)),
		"network_rejected_count": int(network_snapshot.get("rejected_count", 0)),
		"server_snapshot_built": String(server_snapshot.get("snapshot_type", "")) == "state",
		"client_snapshot_apply_accepted": bool(client_apply_result.get("accepted", false)),
		"client_snapshot_apply_missing_unit_count": int(client_apply_result.get("missing_unit_count", -1)),
		"client_received_alpha_unit": _snapshot_has_unit(client_last_state, unit_id),
		"manual_review_required": true,
		"manual_review_done": false,
		"recommended_next_task": "TASK_715 - Station Route Real Two-Window Playtest or Visual Polish",
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_714 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_714", "Manifest records TASK_714")
	_assert(bool(parsed.get("host_command_accepted", false)), "Manifest records host accept")
	_assert(bool(parsed.get("wrong_team_rejected", false)), "Manifest records wrong-team reject")
	_assert(bool(parsed.get("client_snapshot_apply_accepted", false)), "Manifest records client snapshot apply")
	_assert(bool(parsed.get("read_only", false)) and not bool(parsed.get("ui_sets_gameplay_truth", true)), "Manifest remains read-only")

	client_root.queue_free()
	scene.queue_free()
	await _wait_frames(2)


func _write_test_scenario() -> void:
	_ensure_output_dir()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_SCENARIO_PATH))
	var scenario: Dictionary = Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	var interactions: Array = Array(vertical_slice.get("interaction_points", [])).duplicate(true)
	interactions.insert(1, {
		"interaction_id": DOOR_INTERACTION_ID,
		"display_name": "Station Route Multiplayer Door",
		"interaction_type": "door",
		"marker_id": "objective_point",
		"required_order": "breach",
		"duration_seconds": 2.0,
		"radius_world": 128.0,
		"required_team": "team_alpha",
		"step_id": "open_station_door",
		"gate_id": "open_station_door",
		"required_state": "door_open",
		"asset_hint": "station_set_door_single_closed",
	})
	vertical_slice["interaction_points"] = interactions
	scenario["vertical_slice"] = vertical_slice
	var file := FileAccess.open(TEST_SCENARIO_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_714 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_714 temp scenario is written")


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


func _configure_host_authority(simulation_root: Node) -> void:
	simulation_root.set("is_server_authoritative", true)
	simulation_root.call("set_peer_team_assignments", {
		1: "team_alpha",
		2: "team_bravo",
	})
	simulation_root.call("set_peer_role", 1, "host")
	simulation_root.call("set_peer_role", 2, "commander")
	simulation_root.call("set_peer_fireteam_assignments", {
		1: ["ft1"],
		2: ["bravo"],
	})


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
		if "team_id" in child:
			child.set("team_id", "team_alpha")
		if simulation_root != null and simulation_root.has_method("register_known_unit"):
			simulation_root.call("register_known_unit", unit_id, child)
		return unit_id
	return ""


func _build_client_root_from_scene(scene: Node, _fireteam_id: String) -> Node:
	var client_root: Node = Node.new()
	client_root.name = "Task714ClientRoot"
	var client_registry: Node = UNIT_REGISTRY_SCRIPT.new()
	client_registry.name = "ClientUnitRegistry"
	var client_simulation: Node = SIMULATION_ROOT_SCRIPT.new()
	client_simulation.name = "ClientSimulationRoot"
	client_simulation.set("is_server_authoritative", false)
	client_simulation.set("unit_registry_path", NodePath("../ClientUnitRegistry"))
	client_root.add_child(client_registry)
	client_root.add_child(client_simulation)
	for child in scene.get_children():
		if not (child is Node2D):
			continue
		if not child.has_method("get_unit_id"):
			continue
		var unit_id: String = String(child.call("get_unit_id")).strip_edges()
		if unit_id.is_empty():
			unit_id = child.name
		var unit: Node2D = TEST_UNIT_SCRIPT.new()
		unit.unit_id = unit_id
		unit.team_id = String(child.call("get_team_id")).strip_edges() if child.has_method("get_team_id") else "team_alpha"
		unit.fireteam_id = String(child.call("get_fireteam_id")).strip_edges().to_lower() if child.has_method("get_fireteam_id") else ""
		unit.global_position = (child as Node2D).global_position
		client_root.add_child(unit)
		if client_registry.has_method("register_unit"):
			client_registry.call("register_unit", unit_id, unit)
		if client_simulation.has_method("register_known_unit"):
			client_simulation.call("register_known_unit", unit_id, unit)
	return client_root


func _snapshot_has_unit(snapshot: Dictionary, unit_id: String) -> bool:
	for unit_variant in Array(snapshot.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_snapshot: Dictionary = Dictionary(unit_variant)
		if String(unit_snapshot.get("unit_id", "")).strip_edges() == unit_id:
			return true
	return false


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_714 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _wait_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await process_frame


func _wait_physics_frames(count: int) -> void:
	for _index in range(maxi(count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
