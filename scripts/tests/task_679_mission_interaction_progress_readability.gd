extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_679_mission_interaction_progress_readability.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/mission_interaction_progress_readability.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_679 Mission Interaction Progress Readability ===")
	_test_docs()
	await _test_interaction_progress_readability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_679: FAILED")
		quit(1)
		return
	print("TASK_679: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_679 task file exists")
	_assert(task_text.contains("Mission Interaction Progress Readability"), "Task documents progress readability")
	_assert(contract_text.contains("Progress Readability"), "Interaction contract documents progress readability")
	_assert(contract_text.contains("get_mission_interaction_progress_readability_snapshot"), "Interaction contract names readability snapshot")
	_assert(status_text.contains("TASK_679 - Mission Interaction Progress Readability"), "Implementation status tracks TASK_679")
	_assert(roadmap_text.contains("TASK_679 - Mission Interaction Progress Readability"), "Roadmap lists TASK_679")
	_assert(handbook_text.contains("TASK_679 - Mission Interaction Progress Readability"), "Current handbook references TASK_679")


func _test_interaction_progress_readability() -> void:
	_ensure_output_dir()
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
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	_assert(not fireteam_id.is_empty(), "Verifier selects a fireteam")

	var station_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, station_position)
	await _wait_frames(2)
	var station_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "station_computer"))
	_assert(bool(station_intent.get("accepted", false)), "Station computer use intent can be created")
	combat_driver.call("update_mission_interaction_runtime_progress", {
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
	})
	await _wait_frames(2)
	var station_readability: Dictionary = Dictionary(controller.call("get_mission_interaction_progress_readability_snapshot"))
	_assert(_progress_line_is_readable(station_readability, "COM"), "Station progress line is compact and readable")
	_assert(String(station_readability.get("display_line", "")).contains("9/18s"), "Station progress line carries hold time")
	var station_command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(station_command_feedback.get("mission_interaction_progress_line", "")) == String(station_readability.get("display_line", "")), "Command feedback exports station progress line")
	_assert(bool(station_command_feedback.get("mission_interaction_progress_line_within_limit", false)), "Command feedback keeps station progress within limit")
	_assert(String(station_command_feedback.get("mission_hud_interaction_line", "")).contains(String(station_readability.get("display_line", ""))), "Mission HUD ACT line includes station progress")

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
	var cargo_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "spawn_alpha", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, cargo_position)
	await _wait_frames(2)
	var cargo_intent: Dictionary = Dictionary(controller.call("create_selected_mission_interaction_use_intent", "cargo_landing_hold"))
	_assert(bool(cargo_intent.get("accepted", false)), "Cargo hold use intent can be created")
	combat_driver.call("update_mission_interaction_runtime_progress", {
		"interaction_id": "cargo_landing_hold",
		"state": "holding",
		"hold_seconds": 6.0,
		"duration_seconds": 12.0,
		"progress": 0.5,
		"fireteam_id": fireteam_id,
		"team_id": "team_alpha",
		"step_id": "cargo_touchdown_extract",
		"required_state": "cargo_departed",
		"interaction_type": "hold_zone",
		"command_type": "defend",
	})
	await _wait_frames(2)
	var cargo_readability: Dictionary = Dictionary(controller.call("get_mission_interaction_progress_readability_snapshot"))
	_assert(_progress_line_is_readable(cargo_readability, "CARGO"), "Cargo progress line is compact and readable")
	_assert(String(cargo_readability.get("display_line", "")).contains("6/12s"), "Cargo progress line carries hold time")
	var cargo_command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(String(cargo_command_feedback.get("mission_hud_interaction_line", "")).contains(String(cargo_readability.get("display_line", ""))), "Mission HUD ACT line includes cargo progress")

	var manifest: Dictionary = {
		"schema": "sternenbuergerchen.mission_interaction_progress_readability_manifest.v1",
		"task_id": "TASK_679",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"manual_fullhd_review_required": true,
		"manual_fullhd_review_done": false,
		"station_progress_line": String(station_readability.get("display_line", "")),
		"cargo_progress_line": String(cargo_readability.get("display_line", "")),
		"station_line_within_limit": bool(station_readability.get("line_within_limit", false)),
		"cargo_line_within_limit": bool(cargo_readability.get("line_within_limit", false)),
		"mission_hud_interaction_line": String(cargo_command_feedback.get("mission_hud_interaction_line", "")),
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	}
	_write_manifest(manifest)
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "Readability manifest is written")
	var parsed: Dictionary = _read_json(OUTPUT_MANIFEST_PATH)
	_assert(String(parsed.get("task_id", "")) == "TASK_679", "Manifest records TASK_679")
	_assert(bool(parsed.get("manual_fullhd_review_required", false)) and not bool(parsed.get("manual_fullhd_review_done", true)), "Manifest keeps manual FullHD review open")

	scene.queue_free()
	await _wait_frames(2)


func _progress_line_is_readable(snapshot: Dictionary, expected_token: String) -> bool:
	var line: String = String(snapshot.get("display_line", "")).strip_edges()
	return String(snapshot.get("schema", "")) == "sternenbuergerchen.mission_interaction_progress_readability.v1" \
		and bool(snapshot.get("read_only", false)) \
		and not bool(snapshot.get("ui_sets_gameplay_truth", true)) \
		and bool(snapshot.get("active", false)) \
		and String(snapshot.get("status", "")) == "in_progress" \
		and line.contains(expected_token) \
		and line.contains("50%") \
		and bool(snapshot.get("contains_progress_percent", false)) \
		and bool(snapshot.get("contains_hold_time", false)) \
		and bool(snapshot.get("contains_action_token", false)) \
		and bool(snapshot.get("contains_fireteam_token", false)) \
		and bool(snapshot.get("line_within_limit", false)) \
		and int(snapshot.get("line_length", 999)) <= int(snapshot.get("line_char_limit", 0)) \
		and bool(snapshot.get("manual_fullhd_review_required", false)) \
		and not bool(snapshot.get("manual_fullhd_review_done", true))


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


func _ensure_output_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
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
