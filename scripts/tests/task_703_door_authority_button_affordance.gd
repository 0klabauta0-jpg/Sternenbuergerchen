extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_703_door_authority_button_affordance.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const CONTROLLER_PATH: String = "res://scripts/tests/mission_tactical_sandbox_controller.gd"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_703_door_authority_button_affordance_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_authority_button_affordance.json"
const DOOR_INTERACTION_ID: String = "station_door_affordance_probe"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_703 Door Authority Button Affordance ===")
	_test_docs()
	await _test_affordance_helper()
	await _test_mission_button_affordance()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_703: FAILED")
		quit(1)
		return
	print("TASK_703: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	var controller_text: String = _read_text(CONTROLLER_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_703 task file exists")
	_assert(task_text.contains("Door Authority Button Affordance"), "Task documents Door button affordance")
	_assert(contract_text.contains("Door Authority Button Affordance"), "Interaction contract documents Door button affordance")
	_assert(status_text.contains("TASK_703 - Door Authority Button Affordance"), "Implementation status tracks TASK_703")
	_assert(roadmap_text.contains("TASK_703 - Door Authority Button Affordance (implementiert)"), "Roadmap marks TASK_703 implemented")
	_assert(handbook_text.contains("TASK_703 - Door Authority Button Affordance"), "Current handbook references TASK_703")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_authority_button_affordance.manifest_path"'), "Current handbook exports TASK_703 manifest path")
	_assert(controller_text.contains("_apply_door_authority_button_affordance"), "Controller contains affordance helper")
	_assert(controller_text.contains("door_authority_affordance_style_id"), "Controller exports affordance style id")
	_assert(controller_text.contains("door_authority_affordance_visual_weight"), "Controller exports affordance visual weight")


func _test_affordance_helper() -> void:
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	root.add_child(scene)
	await _wait_frames(2)
	var controller: Node = scene.get_node_or_null("TacticalController")
	_assert(controller != null, "Mission scene exposes TacticalController for affordance helper")
	if controller == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var button := Button.new()
	scene.add_child(button)
	controller.call("_apply_door_authority_button_affordance", button, "action")
	_assert(String(button.get_meta("door_authority_affordance_style_id", "")) == "door_authority_ready_action_v1", "Action severity uses ready action style")
	_assert(String(button.get_meta("door_authority_affordance_tone", "")) == "action", "Action severity sets action tone")
	_assert(float(button.get_meta("door_authority_affordance_visual_weight", 0.0)) >= 1.0, "Action severity has visible weight")
	_assert(button.self_modulate != Color(1, 1, 1, 1), "Action severity tints button")

	controller.call("_apply_door_authority_button_affordance", button, "success")
	_assert(String(button.get_meta("door_authority_affordance_style_id", "")) == "door_authority_open_success_v1", "Success severity uses open success style")
	_assert(String(button.get_meta("door_authority_affordance_tone", "")) == "success", "Success severity sets success tone")
	_assert(float(button.get_meta("door_authority_affordance_visual_weight", 0.0)) > 1.0, "Success severity has strong visible weight")

	controller.call("_apply_door_authority_button_affordance", button, "warning")
	_assert(String(button.get_meta("door_authority_affordance_style_id", "")) == "door_authority_blocked_warning_v1", "Warning severity uses blocked warning style")
	_assert(String(button.get_meta("door_authority_affordance_tone", "")) == "warning", "Warning severity sets warning tone")
	_assert(float(button.get_meta("door_authority_affordance_visual_weight", 0.0)) >= 1.0, "Warning severity has visible weight")

	controller.call("_apply_door_authority_button_affordance", button, "")
	_assert(String(button.get_meta("door_authority_affordance_style_id", "")) == "door_authority_neutral_v1", "Empty severity uses neutral style")
	_assert(String(button.get_meta("door_authority_affordance_tone", "")) == "neutral", "Empty severity sets neutral tone")
	_assert(float(button.get_meta("door_authority_affordance_visual_weight", -1.0)) == 0.0, "Empty severity has no extra visible weight")
	_assert(button.self_modulate == Color(1, 1, 1, 1), "Empty severity restores neutral tint")

	scene.queue_free()
	await _wait_frames(2)


func _test_mission_button_affordance() -> void:
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
	_assert(controller != null and combat_driver != null and mission_setup != null, "Mission scene exposes controller, driver and setup")
	if controller == null or combat_driver == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var door_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, door_position)
	controller.call("_update_ui")
	await _wait_frames(2)

	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var button_snapshot: Dictionary = Dictionary(Dictionary(command_feedback.get("command_buttons", {})).get("breach_door", {}))
	_assert(String(button_snapshot.get("door_authority_ui_severity", "")) == "action", "Ready Door button keeps action severity")
	_assert(String(button_snapshot.get("door_authority_affordance_style_id", "")) == "door_authority_ready_action_v1", "Ready Door button exports action style id")
	_assert(String(button_snapshot.get("door_authority_affordance_tone", "")) == "action", "Ready Door button exports action tone")
	_assert(float(button_snapshot.get("door_authority_affordance_visual_weight", 0.0)) >= 1.0, "Ready Door button exports visible weight")
	_assert(bool(button_snapshot.get("door_authority_ui_read_only", false)), "Door button affordance remains read-only")

	_write_manifest({
		"schema": "sternenbuergerchen.door_authority_button_affordance_manifest.v1",
		"task_id": "TASK_703",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"style_id": String(button_snapshot.get("door_authority_affordance_style_id", "")),
		"tone": String(button_snapshot.get("door_authority_affordance_tone", "")),
		"visual_weight": float(button_snapshot.get("door_authority_affordance_visual_weight", 0.0)),
		"read_only": bool(button_snapshot.get("door_authority_ui_read_only", false)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_703 manifest is written")

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
			"display_name": "Station Door Affordance Probe",
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
		_assert(false, "Can open TASK_703 temp scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_703 temp scenario is written")


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


func _write_manifest(manifest: Dictionary) -> void:
	var file := FileAccess.open(OUTPUT_MANIFEST_PATH, FileAccess.WRITE)
	if file == null:
		_assert(false, "Can open TASK_703 manifest for writing")
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
