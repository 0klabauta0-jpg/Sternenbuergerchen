extends SceneTree

const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const FIXTURE_SCENARIO_PATH: String = "res://data/mission_scenarios/task_157_editor_mvp.json"
const FIXTURE_MAP_PATH: String = "res://maps/task_157_editor_mvp_map.json"
const SAVED_SCENARIO_PATH: String = "user://task_157_editor_saved.json"
const LIVE_SCENARIO_PATH: String = "user://task_157_live_scenario.json"
const MISSION_SCENARIO_DATA_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_157 Tactical Mission Editor MVP Verifier ===")
	await _test_editor_load_edit_save()
	await _test_live_start_uses_saved_scenario()
	_cleanup_user_file(SAVED_SCENARIO_PATH)
	_cleanup_user_file(LIVE_SCENARIO_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_editor_load_edit_save() -> void:
	var editor: Node = await _create_editor()
	if editor == null:
		_assert(false, "Map editor scene instantiates")
		return

	var loaded: bool = bool(editor.call("load_mission_scenario_for_editor", FIXTURE_SCENARIO_PATH))
	await _wait_frames(5)
	_assert(loaded, "Editor loads a mission scenario file")
	var current_data: Dictionary = Dictionary(editor.call("get_current_mission_scenario_dict"))
	_assert(String(current_data.get("map_file_path", "")) == FIXTURE_MAP_PATH, "Editor references the scenario map file")
	_assert(not _has_key_recursive(current_data, "lz") and not _has_key_recursive(current_data, "landing_zone"), "Editor scenario data exposes no stored LZ fields")

	var edited_data: Dictionary = current_data.duplicate(true)
	edited_data["scenario_id"] = "task_157_editor_saved"
	edited_data["display_name"] = "TASK 157 Saved Scenario"
	edited_data["time_limit_seconds"] = 600.0
	edited_data["objective"] = {
		"marker_id": "objective_point",
		"capture_radius": 123.0,
	}
	edited_data["enemy_groups"] = [
		{
			"group_id": "red_saved_group",
			"display_name": "Saved Contacts",
			"team_id": "team_bravo",
			"spawn_position": {
				"x": 520.0,
				"y": 250.0,
			},
			"enemy_ids": ["enemy_delta", "enemy_echo"],
		},
	]
	edited_data["wave_config"] = {
		"wave_count": 1,
		"units_per_wave": 2,
		"first_wave_delay_seconds": 0.0,
		"wave_delay_seconds": 17.0,
	}
	edited_data["patrol_bindings"] = [
		{
			"target_id": "enemy_delta",
			"patrol_path_id": "enemy_delta",
			"mode": "pre_contact",
		},
	]
	editor.call("set_mission_scenario_authoring_fields", edited_data)
	var save_error: Error = editor.call("save_mission_scenario_from_editor", SAVED_SCENARIO_PATH)
	_assert(save_error == OK, "Editor saves edited mission scenario JSON")

	var saved_scenario = MISSION_SCENARIO_DATA_SCRIPT.call("load_from_file", SAVED_SCENARIO_PATH)
	var validation: Dictionary = Dictionary(saved_scenario.call("validate"))
	if not bool(validation.get("valid", false)):
		print("TASK_157 saved scenario validation errors: %s" % "; ".join(PackedStringArray(validation.get("errors", PackedStringArray()))))
	_assert(bool(validation.get("valid", false)), "Saved editor scenario validates against the data contract")
	var saved_data: Dictionary = Dictionary(saved_scenario.call("to_dict"))
	_assert(float(Dictionary(saved_data.get("objective", {})).get("capture_radius", 0.0)) == 123.0, "Edited objective capture radius roundtrips")
	_assert(float(Dictionary(saved_data.get("wave_config", {})).get("wave_delay_seconds", 0.0)) == 17.0, "Edited wave delay roundtrips")
	var saved_group: Dictionary = Dictionary(Array(saved_data.get("enemy_groups", []))[0])
	_assert(saved_group.has("spawn_position") and not saved_group.has("spawn_marker_id"), "Editor saves enemy spawn positions when marker mode is not used")
	_assert(not _has_key_recursive(saved_data, "lz") and not _has_key_recursive(saved_data, "landing_zone"), "Saved scenario still contains no LZ fields")

	editor.queue_free()
	await _wait_frames(2)


func _test_live_start_uses_saved_scenario() -> void:
	var editor: Node = await _create_editor()
	if editor == null:
		_assert(false, "Map editor scene instantiates for live start")
		return

	_assert(bool(editor.call("load_mission_scenario_for_editor", FIXTURE_SCENARIO_PATH)), "Editor loads scenario before live test")
	await _wait_frames(5)
	_assert(editor.call("save_mission_scenario_from_editor", LIVE_SCENARIO_PATH) == OK, "Editor writes live-test scenario scratch file")
	var live_scene := editor.call("create_live_test_scene_from_current_scenario") as Node
	_assert(live_scene != null, "Editor creates a live mission scene from the scenario")
	editor.queue_free()
	await _wait_frames(2)
	if live_scene == null:
		return

	root.add_child(live_scene)
	await _wait_frames(15)

	var mission_setup := live_scene.get_node_or_null("MissionSetup")
	_assert(mission_setup != null and String(mission_setup.get("scenario_file_path")) == LIVE_SCENARIO_PATH, "Live mission receives the editor scenario path")
	var simulation_root := live_scene.get_node_or_null("SimulationRoot")
	var objective_status = simulation_root.call("get_objective_status") if simulation_root != null and simulation_root.has_method("get_objective_status") else null
	_assert(objective_status != null and absf(float(objective_status.capture_radius) - 96.0) <= 0.01, "Scenario objective capture radius reaches SimulationRoot")
	_assert(objective_status != null and _coerce_vector2(objective_status.position, Vector2.ZERO).distance_to(Vector2(448.0, 285.0)) <= 0.5, "Scenario objective position reaches SimulationRoot")

	var wave_controller := live_scene.get_node_or_null("EnemyWaveController")
	_assert(wave_controller != null and int(wave_controller.get("wave_count")) == 1 and int(wave_controller.get("units_per_wave")) == 2, "Scenario wave parameters reach EnemyWaveController")
	_assert(wave_controller != null and absf(float(wave_controller.get("wave_delay_seconds")) - 42.0) <= 0.01, "Scenario wave delay reaches EnemyWaveController")
	var delta_patrol: Array = Array(wave_controller.call("get_patrol_path_for_unit", "enemy_delta")) if wave_controller != null and wave_controller.has_method("get_patrol_path_for_unit") else []
	var echo_patrol: Array = Array(wave_controller.call("get_patrol_path_for_unit", "enemy_echo")) if wave_controller != null and wave_controller.has_method("get_patrol_path_for_unit") else []
	_assert(delta_patrol.size() == 2 and _coerce_vector2(delta_patrol[0], Vector2.ZERO).distance_to(Vector2(512.0, 221.0)) <= 0.5, "Delta patrol binding reaches EnemyWaveController")
	_assert(echo_patrol.size() == 2 and _coerce_vector2(echo_patrol[1], Vector2.ZERO).distance_to(Vector2(464.0, 245.0)) <= 0.5, "Echo patrol binding reaches EnemyWaveController")
	_assert(_scene_has_no_player_lz(live_scene), "Live mission starts without a stored or visible player LZ")

	live_scene.queue_free()
	await _wait_frames(2)


func _create_editor() -> Node:
	var packed_scene: PackedScene = load(MAP_EDITOR_SCENE_PATH)
	if packed_scene == null:
		return null
	var editor := packed_scene.instantiate()
	root.add_child(editor)
	await _wait_frames(5)
	return editor


func _wait_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _scene_has_no_player_lz(scene: Node) -> bool:
	var lz_marker := scene.get_node_or_null("LZMarker") as CanvasItem
	var dropship_marker := scene.get_node_or_null("DropshipPlanMarker") as CanvasItem
	if lz_marker != null and lz_marker.visible:
		return false
	if dropship_marker != null and dropship_marker.visible:
		return false
	var controller := scene.get_node_or_null("TacticalController")
	if controller == null or not controller.has_method("get_planning_state"):
		return true
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	return not bool(planning_state.get("has_lz_position", false))


func _has_key_recursive(value: Variant, key_needle: String) -> bool:
	var normalized_needle: String = key_needle.strip_edges().to_lower()
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		for key_variant in value_dict.keys():
			var key_text: String = String(key_variant).strip_edges().to_lower()
			if key_text == normalized_needle or key_text.contains(normalized_needle):
				return true
			if _has_key_recursive(value_dict.get(key_variant), normalized_needle):
				return true
	elif typeof(value) == TYPE_ARRAY:
		for item_variant in Array(value):
			if _has_key_recursive(item_variant, normalized_needle):
				return true
	return false


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = Dictionary(value)
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback


func _cleanup_user_file(path: String) -> void:
	if path.is_empty():
		return
	var absolute_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
