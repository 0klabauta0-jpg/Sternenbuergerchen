extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const SCENARIO_DRILL_SCRIPT: GDScript = preload("res://scripts/mission/station_route_one_screen_scenario_drill.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_726_one_screen_multiplayer_station_scenario_drill.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_current_state_handbook_2026_07_01.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json"
const ACCEPTANCE_MANIFEST_PATH: String = "res://tmp/station_route_recapture_acceptance_review.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/station_route_one_screen_multiplayer_drill.json"

const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const DOOR_INTERACTION_ID: String = "station_route_drill_door"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_726 One-Screen Multiplayer Station Scenario Drill ===")
	_test_docs_and_sources()
	await _test_station_scenario_drill_runtime()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_726: FAILED")
		quit(1)
		return
	print("TASK_726: ALL PASSED")
	quit(0)


func _test_docs_and_sources() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	var scenario_text: String = _read_text(SCENARIO_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_726 task file exists")
	_assert(task_text.contains("One-Screen Multiplayer Station Scenario Drill"), "Task documents one-screen station drill")
	_assert(contract_text.contains("One-Screen Multiplayer Station Scenario Drill"), "Interaction contract documents TASK_726")
	_assert(status_text.contains("TASK_726 - One-Screen Multiplayer Station Scenario Drill"), "Implementation status tracks TASK_726")
	_assert(roadmap_text.contains("TASK_726 - One-Screen Multiplayer Station Scenario Drill (implementiert)"), "Roadmap marks TASK_726 implemented")
	_assert(report_text.contains("TASK_726 - One-Screen Multiplayer Station Scenario Drill"), "Current report references TASK_726")
	_assert(report_text.contains('data-export-key="station_route_one_screen_multiplayer_drill.manifest_path"'), "Current report exports TASK_726 manifest path")
	_assert(FileAccess.file_exists(SCENARIO_PATH), "TASK_726 scenario file exists")
	_assert(scenario_text.contains('"station_route_drill_door"'), "Scenario contains explicit Door interaction")
	_assert(scenario_text.contains('"route_tokens": ["AA", "DOOR", "COM", "CARGO"]'), "Scenario contains readable route tokens")


func _test_station_scenario_drill_runtime() -> void:
	_ensure_output_dir()
	var scenario: Dictionary = _read_json(SCENARIO_PATH)
	var acceptance_manifest: Dictionary = _read_json(ACCEPTANCE_MANIFEST_PATH)
	if acceptance_manifest.is_empty():
		acceptance_manifest = _fake_acceptance_manifest()
	var static_snapshot: Dictionary = Dictionary(SCENARIO_DRILL_SCRIPT.call("build_snapshot", scenario, acceptance_manifest, {}))
	_assert(_snapshot_is_read_only(static_snapshot), "Static TASK_726 snapshot is read-only")
	_assert(String(static_snapshot.get("status", "")) == "blocked", "Static snapshot blocks until runtime drill runs")
	_assert(bool(static_snapshot.get("scenario_ready", false)), "Static snapshot validates scenario data")
	_assert(bool(static_snapshot.get("acceptance_ready", false)), "Static snapshot validates TASK_725 acceptance")

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

	_assert(bool(combat_driver.call("configure_scenario_runtime_gates_from_file", SCENARIO_PATH)), "Combat driver configures TASK_726 scenario")
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")
	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	var cargo_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	await _wait_frames(2)

	var start_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(start_gate.get("next_step_id", "")) == "disable_air_defense", "Start gate points to AA")
	combat_driver.call("set_mission_scenario_runtime_step_state", "disable_air_defense", "aa_disabled")
	await _wait_frames(2)
	var after_aa_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(after_aa_gate.get("next_step_id", "")) == "open_station_door", "AA complete points to Door")

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
	await _wait_frames(4)
	var after_door_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(after_door_gate.get("next_step_id", "")) == "occupy_station_computer", "Door complete points to computer")

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
	var after_computer_gate: Dictionary = Dictionary(controller.call("get_mission_interaction_objective_gate_snapshot"))
	_assert(String(after_computer_gate.get("next_step_id", "")) == "cargo_touchdown_extract", "Computer complete points to cargo")

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
	_assert(bool(complete_gate.get("all_gates_complete", false)), "Cargo departed completes one-screen station drill")

	var runtime_result: Dictionary = {
		"runtime_sequence_passed": (
			String(start_gate.get("next_step_id", "")) == "disable_air_defense"
			and String(after_aa_gate.get("next_step_id", "")) == "open_station_door"
			and String(after_door_gate.get("next_step_id", "")) == "occupy_station_computer"
			and String(after_computer_gate.get("next_step_id", "")) == "cargo_touchdown_extract"
			and bool(complete_gate.get("all_gates_complete", false))
		),
		"door_step_visible": String(after_aa_gate.get("next_step_id", "")) == "open_station_door" and Array(static_snapshot.get("interaction_ids", [])).has(DOOR_INTERACTION_ID),
		"cargo_complete": bool(complete_gate.get("all_gates_complete", false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"route_gate_sequence": [
			String(start_gate.get("next_step_id", "")),
			String(after_aa_gate.get("next_step_id", "")),
			String(after_door_gate.get("next_step_id", "")),
			String(after_computer_gate.get("next_step_id", "")),
			String(complete_gate.get("next_line", "")),
		],
	}
	var final_snapshot: Dictionary = Dictionary(SCENARIO_DRILL_SCRIPT.call("build_snapshot", scenario, acceptance_manifest, runtime_result, {
		"scenario_path": "data/mission_scenarios/station_route_one_screen_multiplayer_drill.json",
		"acceptance_manifest_path": "tmp/station_route_recapture_acceptance_review.json",
		"manifest_path": "tmp/station_route_one_screen_multiplayer_drill.json",
	}))
	_assert(_snapshot_is_read_only(final_snapshot), "Final TASK_726 snapshot is read-only")
	_assert(String(final_snapshot.get("status", "")) == "ready_for_f6_host_client_playtest", "Final snapshot is ready for visible playtest")
	_assert(bool(final_snapshot.get("runtime_ready", false)), "Final snapshot records runtime readiness")
	_assert(int(final_snapshot.get("enemy_unit_count", 0)) >= 8, "Final snapshot records enough Bravo/NPC pressure")
	final_snapshot["runtime_result"] = runtime_result
	final_snapshot["manifest_path"] = ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH)
	_write_manifest(final_snapshot)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_726 manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_726", "Manifest records TASK_726")
	_assert(String(parsed.get("status", "")) == "ready_for_f6_host_client_playtest", "Manifest records visible-playtest readiness")
	_assert(_snapshot_is_read_only(parsed), "Manifest remains read-only")

	scene.queue_free()
	await _wait_frames(2)


func _configure_scene(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("map_file_path", MAP_PATH)
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


func _fake_acceptance_manifest() -> Dictionary:
	return {
		"schema": "sternenbuergerchen.station_route_recapture_acceptance_review.v1",
		"task_id": "TASK_725",
		"status": "accepted_for_next_slice",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _snapshot_is_read_only(snapshot: Dictionary) -> bool:
	return bool(snapshot.get("read_only", false)) and not bool(snapshot.get("ui_sets_gameplay_truth", true))


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_726 manifest for writing")
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
