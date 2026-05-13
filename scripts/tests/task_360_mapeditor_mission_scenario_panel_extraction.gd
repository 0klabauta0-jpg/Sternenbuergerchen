extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TEMP_SCENARIO_PATH: String = "user://task_360_scenario_panel_extraction.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_360 MapEditor Mission Scenario Panel Extraction ===")
	await _test_panel_controller_owns_controls_and_sync()
	await _test_scenario_contract_and_live_test_still_flow_through_editor()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("TASK_360: ALL PASSED")
		quit(0)


func _test_panel_controller_owns_controls_and_sync() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var debug: Dictionary = Dictionary(editor.call("get_mission_scenario_panel_debug_snapshot"))
	_assert(String(debug.get("script_path", "")).ends_with("map_editor_mission_scenario_panel.gd"), "Scenario panel is backed by extracted controller script")
	_assert(bool(debug.get("panel_exists", false)), "Scenario panel still exists in the MapEditor UI")
	_assert(bool(debug.get("owns_control_setup", false)) and bool(debug.get("owns_signal_connections", false)), "Controller owns scenario control setup and signal wiring")
	_assert(bool(debug.get("owns_refresh", false)) and bool(debug.get("owns_sync", false)), "Controller owns scenario refresh and sync")

	var id_line_edit := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioPanel/ScenarioIdRow/ScenarioIdLineEdit") as LineEdit
	var enemy_line_edit := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioPanel/ScenarioEnemyIdsRow/ScenarioEnemyIdsLineEdit") as LineEdit
	var radius_spinbox := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/MissionScenarioPanel/ScenarioCaptureRadiusRow/ScenarioCaptureRadiusSpinBox") as SpinBox
	_assert(id_line_edit != null and enemy_line_edit != null and radius_spinbox != null, "Extracted panel exposes existing scenario control node paths")
	if id_line_edit != null:
		id_line_edit.text = "task_360_ui_sync"
		id_line_edit.text_changed.emit(id_line_edit.text)
	if enemy_line_edit != null:
		enemy_line_edit.text = "enemy_delta, enemy_echo, enemy_foxtrot"
		enemy_line_edit.text_changed.emit(enemy_line_edit.text)
	if radius_spinbox != null:
		radius_spinbox.value = 96.0
		radius_spinbox.value_changed.emit(radius_spinbox.value)
	await _wait_frames(2)

	var scenario: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	_assert(String(scenario.get("scenario_id", "")) == "task_360_ui_sync", "Controller sync writes edited scenario ID")
	_assert(PackedStringArray(scenario.get("enemy_ids", PackedStringArray())).is_empty(), "Scenario root does not gain a legacy enemy_ids field")
	var enemy_groups: Array = Array(scenario.get("enemy_groups", []))
	var group: Dictionary = Dictionary(enemy_groups[0]) if not enemy_groups.is_empty() else {}
	_assert(PackedStringArray(group.get("enemy_ids", PackedStringArray())).has("enemy_foxtrot"), "Controller sync preserves enemy group ID editing")
	_assert(is_equal_approx(float(Dictionary(scenario.get("objective", {})).get("capture_radius", 0.0)), 96.0), "Controller sync preserves objective radius editing")
	_assert(bool(editor.get("_scenario_dirty")), "Controller signal marks scenario dirty through MapEditor dirty state")

	editor.queue_free()
	await _wait_frames(2)


func _test_scenario_contract_and_live_test_still_flow_through_editor() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	editor.call(
		"set_mission_scenario_authoring_fields",
		{
			"version": 1,
			"scenario_id": "task_360_contract",
			"display_name": "TASK 360 Contract",
			"map_file_path": "res://maps/test_mission.json",
			"time_limit_seconds": 180.0,
			"mission_slot_count_override": 3,
			"objective": {"position": Vector2(128.0, 128.0), "capture_radius": 64.0},
			"enemy_groups": [
				{
					"group_id": "red_test_group",
					"display_name": "Test Contacts",
					"team_id": "team_bravo",
					"enemy_ids": ["enemy_delta"],
					"spawn_position": Vector2(256.0, 256.0),
				},
			],
			"wave_config": {"wave_count": 1, "units_per_wave": 1, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
			"patrol_bindings": [{"binding_id": "enemy_delta_patrol", "target_id": "enemy_delta", "patrol_path_id": "enemy_delta", "mode": "pre_contact"}],
		}
	)
	var save_error: Error = editor.call("save_mission_scenario_from_editor", TEMP_SCENARIO_PATH)
	_assert(save_error == OK, "Scenario save still flows through MapEditor coordinator")
	var saved_text: String = _read_text(TEMP_SCENARIO_PATH)
	_assert(saved_text.contains("\"scenario_id\": \"task_360_contract\""), "Saved scenario JSON keeps the existing scenario_id contract")
	_assert(saved_text.contains("\"enemy_groups\""), "Saved scenario JSON keeps enemy_groups contract")

	var live_scene = editor.call("create_live_test_scene_from_current_scenario")
	_assert(live_scene != null, "Live-test scene creation still works through MapEditor")
	if live_scene != null:
		var mission_setup: Node = live_scene.get_node_or_null("MissionSetup")
		_assert(mission_setup != null and String(mission_setup.get("scenario_file_path")) == TEMP_SCENARIO_PATH, "Live-test MissionSetup receives saved scenario path")
		live_scene.free()

	editor.queue_free()
	await _wait_frames(2)


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(14)
	return editor


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
