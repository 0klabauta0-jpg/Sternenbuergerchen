extends SceneTree

const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")

const TASK_PATH: String = "res://docs/tasks/TASK_695_door_interaction_hud_button_shortcut.md"
const CONTRACT_PATH: String = "res://docs/dev/mission_interaction_point_contract.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const HANDBOOK_PATH: String = "res://docs/reports/project_current_state_handbook_2026_06_30.html"
const SOURCE_SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TEST_SCENARIO_PATH: String = "res://tmp/task_695_door_interaction_hud_button_shortcut_scenario.json"
const MAP_PATH: String = "res://maps/station_outpost_192x192.json"
const OUTPUT_DIR: String = "res://tmp"
const OUTPUT_MANIFEST_PATH: String = "res://tmp/door_interaction_hud_button_shortcut.json"
const DOOR_INTERACTION_ID: String = "station_door_hud_probe"
const DOOR_BUTTON_PATH: String = "../TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel/CommandMargin/CommandScroll/CommandVBox/CommandGrid/DoorBreachButton"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_695 Door Interaction HUD Button/Shortcut ===")
	_test_docs()
	await _test_door_hud_button_and_shortcut()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_695: FAILED")
		quit(1)
		return
	print("TASK_695: ALL PASSED")
	quit(0)


func _test_docs() -> void:
	var task_text: String = _read_text(TASK_PATH)
	var contract_text: String = _read_text(CONTRACT_PATH)
	var status_text: String = _read_text(STATUS_PATH)
	var roadmap_text: String = _read_text(ROADMAP_PATH)
	var handbook_text: String = _read_text(HANDBOOK_PATH)
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_695 task file exists")
	_assert(task_text.contains("Door Interaction HUD Button/Shortcut"), "Task documents door HUD button shortcut")
	_assert(contract_text.contains("Door Interaction HUD Button/Shortcut"), "Interaction contract documents door HUD button shortcut")
	_assert(status_text.contains("TASK_695 - Door Interaction HUD Button/Shortcut"), "Implementation status tracks TASK_695")
	_assert(roadmap_text.contains("TASK_695 - Door Interaction HUD Button/Shortcut (implementiert)"), "Roadmap marks TASK_695 implemented")
	_assert(handbook_text.contains("TASK_695 - Door Interaction HUD Button/Shortcut"), "Current handbook references TASK_695")
	_assert(handbook_text.contains('data-export-key="mission_interaction_door_hud_button_shortcut.manifest_path"'), "Current handbook exports TASK_695 manifest path")


func _test_door_hud_button_and_shortcut() -> void:
	_ensure_output_dir()
	_write_test_scenario()
	root.size = Vector2i(1920, 1080)
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene(scene)
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)

	var controller: Node = scene.get_node_or_null("TacticalController")
	var mission_setup: Node = scene.get_node_or_null("MissionSetup")
	_assert(controller != null and mission_setup != null, "Mission scene exposes controller and setup")
	if controller == null or mission_setup == null:
		scene.queue_free()
		await _wait_frames(2)
		return

	var combat_driver: Node = scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.call("configure_scenario_runtime_gates_from_file", TEST_SCENARIO_PATH)
	var fireteam_id: String = _select_first_available_fireteam(controller, mission_setup)
	controller.call("_update_ui")
	await _wait_frames(2)
	var initial_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var initial_button: Dictionary = Dictionary(Dictionary(initial_feedback.get("command_buttons", {})).get("breach_door", {}))
	_assert(bool(initial_button.get("exists", false)), "Breach door button exists before door is usable")
	_assert(bool(initial_button.get("visible", false)), "Breach door button stays visible before door is usable")
	_assert(bool(initial_button.get("disabled", false)), "Breach door button is blocked before door is usable")
	var terrain_map_data = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", MAP_PATH)
	var door_position: Vector2 = Vector2(terrain_map_data.call("get_marker_position", "objective_point", Vector2.ZERO))
	_move_fireteam_units(scene, fireteam_id, door_position)
	await _wait_frames(2)
	controller.call("_update_ui")
	await _wait_frames(2)

	var button := controller.get_node_or_null(DOOR_BUTTON_PATH) as Button
	_assert(button != null, "Door breach button exists in command grid")
	var command_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	var command_buttons: Dictionary = Dictionary(command_feedback.get("command_buttons", {}))
	var button_snapshot: Dictionary = Dictionary(command_buttons.get("breach_door", {}))
	_assert(bool(button_snapshot.get("exists", false)), "Command feedback exports breach door button")
	_assert(bool(button_snapshot.get("visible", false)), "Breach door button is visible")
	_assert(not bool(button_snapshot.get("disabled", true)), "Breach door button is enabled for usable door")
	_assert(String(button_snapshot.get("text", "")) == "B->GO", "Breach door button keeps its compact GO cue")
	_assert(String(button_snapshot.get("command_matrix_slot_id", "")) == "16.8", "Breach door button occupies command slot 16.8")
	_assert(String(button_snapshot.get("door_interaction_shortcut", "")) == "B", "Breach door button advertises B shortcut")
	_assert(String(button_snapshot.get("door_interaction_id", "")) == DOOR_INTERACTION_ID, "Breach door button targets usable door")
	var tactical_connection_count: int = _count_tactical_button_connections(button, controller, "_on_door_breach_button_pressed")
	_assert(tactical_connection_count == 1, "Breach door button has one tactical pressed connection (%d)" % tactical_connection_count)
	var hierarchy: Dictionary = Dictionary(command_feedback.get("command_hierarchy", {}))
	var breach_action: Dictionary = Dictionary(Dictionary(hierarchy.get("actions_by_id", {})).get("breach_door", {}))
	_assert(not breach_action.is_empty(), "Command hierarchy exposes breach_door action")
	_assert(bool(breach_action.get("implemented", false)), "Command hierarchy marks breach_door implemented")
	_assert(bool(breach_action.get("active", false)), "Command hierarchy marks breach_door active")

	var key_event := InputEventKey.new()
	key_event.pressed = true
	key_event.physical_keycode = KEY_B
	controller.call("_unhandled_input", key_event)
	await _wait_frames(2)
	var shortcut_hook: Dictionary = Dictionary(controller.call("get_mission_interaction_door_use_breach_command_hook_snapshot"))
	_assert(bool(shortcut_hook.get("accepted", false)), "B shortcut triggers accepted door hook")
	_assert(bool(shortcut_hook.get("requires_go", false)), "B shortcut hook still requires GO")
	_assert(String(shortcut_hook.get("interaction_id", "")) == DOOR_INTERACTION_ID, "B shortcut hook targets door interaction")

	if button != null:
		button.emit_signal("pressed")
	await _wait_frames(2)
	var button_hook: Dictionary = Dictionary(controller.call("get_mission_interaction_door_use_breach_command_hook_snapshot"))
	_assert(bool(button_hook.get("accepted", false)), "Button press triggers accepted door hook")
	_assert(String(button_hook.get("last_command_text", "")).contains("BREACH"), "Button press writes breach command line")
	var after_feedback: Dictionary = Dictionary(controller.call("get_command_feedback_snapshot"))
	_assert(bool(after_feedback.get("mission_interaction_door_use_breach_command_hook_accepted", false)), "Command feedback exports accepted hook after button")
	_assert(String(after_feedback.get("mission_interaction_door_use_breach_command_hook_line", "")).contains("BREACH"), "Command feedback exports breach line after button")

	_write_manifest({
		"schema": "sternenbuergerchen.door_interaction_hud_button_shortcut_manifest.v1",
		"task_id": "TASK_695",
		"door_interaction_id": DOOR_INTERACTION_ID,
		"button_exists": bool(button_snapshot.get("exists", false)),
		"button_visible": bool(button_snapshot.get("visible", false)),
		"button_enabled": not bool(button_snapshot.get("disabled", true)),
		"button_slot": String(button_snapshot.get("command_matrix_slot_id", "")),
		"shortcut": "B",
		"shortcut_hook_accepted": bool(shortcut_hook.get("accepted", false)),
		"button_hook_accepted": bool(button_hook.get("accepted", false)),
		"requires_go": bool(button_hook.get("requires_go", false)),
		"ui_sets_gameplay_truth": false,
		"manifest_path": ProjectSettings.globalize_path(OUTPUT_MANIFEST_PATH),
	})
	_assert(FileAccess.file_exists(OUTPUT_MANIFEST_PATH), "TASK_695 manifest is written")

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
			"display_name": "Station Door HUD Probe",
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
		_assert(false, "Can open TASK_695 test scenario for writing")
		return
	file.store_string(JSON.stringify(scenario, "\t"))
	file.close()
	_assert(FileAccess.file_exists(TEST_SCENARIO_PATH), "TASK_695 temp scenario is written")


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
		_assert(false, "Can open TASK_695 manifest for writing")
		return
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


func _count_tactical_button_connections(button: Button, controller: Node, method_name: String) -> int:
	if button == null or controller == null:
		return 0
	var count: int = 0
	for connection_variant in button.pressed.get_connections():
		var connection: Dictionary = Dictionary(connection_variant)
		var callable: Callable = connection.get("callable", Callable())
		if callable.get_object() == controller and callable.get_method() == method_name:
			count += 1
	return count


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
