extends SceneTree

const MAP_EDITOR_SCENE: PackedScene = preload("res://scenes/editor/map_editor.tscn")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

const TEMP_MAP_PATH: String = "user://task_229_editor_authoring_map.json"
const TEMP_SCENARIO_PATH: String = "user://task_229_editor_authoring_scenario.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_229 Map Editor Usability Authoring Pass ===")
	await _test_usability_snapshot_and_status_panel()
	await _test_authoring_validation_manifest_and_live_test()
	await _test_validation_diagnostics_for_missing_scenario_fields()
	await _test_roundtrip_and_action_contract()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_usability_snapshot_and_status_panel() -> void:
	var editor = await _make_editor()
	_assert(editor != null, "Map editor scene instantiates")
	if editor == null:
		return
	_assert(bool(editor.call("set_authoring_tool", "height")), "Editor can switch to height authoring tool")
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(1, 1))), "Editor can select a grid for authoring")
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot"))
	_assert(String(snapshot.get("active_tool", "")) == "height", "Usability snapshot exposes active tool")
	_assert(int(snapshot.get("brush_radius", -1)) >= 0, "Usability snapshot exposes brush radius")
	_assert(Vector2i(snapshot.get("selected_grid", Vector2i.ZERO)) == Vector2i(1, 1), "Usability snapshot exposes selected tile")
	_assert(Dictionary(snapshot.get("height_tool", {})).get("edge_type", "") != "", "Usability snapshot exposes height edge mode")
	var status_label := editor.get_node_or_null("UI/PropertyPanel/Margin/VBox/AuthoringStatusPanel/AuthoringToolStatusLabel") as Label
	_assert(status_label != null and status_label.text.contains("Tool:"), "Editor shows compact authoring status in property panel")
	editor.queue_free()
	await _wait_frames(2)


func _test_authoring_validation_manifest_and_live_test() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	_prepare_valid_authoring_fixture(editor)
	var validation: Dictionary = Dictionary(editor.call("get_authoring_validation_snapshot", false))
	_assert(bool(validation.get("valid", false)), "Valid editor authoring fixture has no validation errors")
	var sections: Dictionary = Dictionary(validation.get("sections", {}))
	_assert(int(Dictionary(sections.get("markers", {})).get("marker_count", 0)) >= 3, "Validation reports authored markers")
	_assert(int(Dictionary(sections.get("patrols", {})).get("waypoint_count", 0)) >= 2, "Validation reports patrol waypoints")
	_assert(int(Dictionary(sections.get("fow", {})).get("los_blocker_count", 0)) >= 1, "Validation reports FoW-relevant LOS blockers")
	var manifest: Dictionary = Dictionary(editor.call("build_multiplayer_map_manifest_preview"))
	_assert(bool(manifest.get("ready", false)), "Editor can prepare multiplayer map manifest preview")
	_assert(String(Dictionary(manifest.get("manifest", {})).get("map_hash", "")).length() == 64, "Manifest preview exposes map hash")
	var snapshot: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot"))
	_assert(bool(Dictionary(snapshot.get("live_test", {})).get("ready", false)), "Usability snapshot reports live-test readiness")
	var live_scene = editor.call("create_live_test_scene_from_current_scenario")
	_assert(live_scene != null, "Editor can create live-test scene from current scenario")
	if live_scene != null:
		live_scene.free()
	editor.queue_free()
	await _wait_frames(2)


func _test_validation_diagnostics_for_missing_scenario_fields() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	_prepare_valid_authoring_fixture(editor)
	editor.call(
		"set_mission_scenario_authoring_fields",
		{
			"version": 1,
			"scenario_id": "task_229_invalid",
			"display_name": "TASK 229 Invalid",
			"map_file_path": TEMP_MAP_PATH,
			"time_limit_seconds": 120.0,
			"objective": {"marker_id": "missing_objective", "capture_radius": 64.0},
			"enemy_groups": [],
			"wave_config": {"wave_count": 1, "units_per_wave": 1},
		}
	)
	var validation: Dictionary = Dictionary(editor.call("get_authoring_validation_snapshot", false))
	_assert(not bool(validation.get("valid", true)), "Invalid scenario fields produce authoring validation errors")
	_assert(_messages_contain(PackedStringArray(validation.get("errors", PackedStringArray())), "objective marker does not exist"), "Validation names missing objective marker")
	_assert(_messages_contain(PackedStringArray(validation.get("errors", PackedStringArray())), "enemy_groups needs at least one group"), "Validation names missing enemy groups")
	editor.queue_free()
	await _wait_frames(2)


func _test_roundtrip_and_action_contract() -> void:
	var editor = await _make_editor()
	if editor == null:
		return
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "Editor exposes TerrainMapData for authoring roundtrip")
	if map_data == null:
		editor.queue_free()
		await _wait_frames(2)
		return
	var hill_tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
	_assert(hill_tile != null, "Roundtrip fixture can edit a hill tile")
	if hill_tile != null:
		hill_tile.height_level = 2
		hill_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF")
		hill_tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND")
		hill_tile.type_id = "wall_straight_se"
		hill_tile.object_height = 2
		hill_tile.walkable = false
		hill_tile.blocks_los = true
		hill_tile.cover_value = 55
	editor.set("_current_map_path", TEMP_MAP_PATH)
	_assert(map_data.call("save_to_file", TEMP_MAP_PATH) == OK, "Editor-authored map saves for roundtrip")
	var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", TEMP_MAP_PATH)
	var reloaded_tile = reloaded.call("get_tile_at_grid", Vector2i(2, 2)) if reloaded != null else null
	_assert(reloaded_tile != null and int(reloaded_tile.height_level) == 2, "Roundtrip preserves height")
	_assert(reloaded_tile != null and String(reloaded_tile.edge_type) == TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF"), "Roundtrip preserves edge")
	_assert(reloaded_tile != null and String(reloaded_tile.type_id) == "wall_straight_se", "Roundtrip preserves object/catalog type")
	var action_contract: Dictionary = Dictionary(editor.call("get_authoring_action_contract_snapshot"))
	_assert(String(action_contract.get("undo_redo_scope", "")) == "single_tile_patch_v1", "Action contract documents current undo scope")
	_assert(PackedStringArray(action_contract.get("tile_patch_fields", PackedStringArray())).has("height_level"), "Action contract documents tile patch fields")
	editor.queue_free()
	await _wait_frames(2)


func _prepare_valid_authoring_fixture(editor) -> void:
	var map_data = editor.get("_terrain_map_data")
	editor.set("_current_map_path", TEMP_MAP_PATH)
	var spawn_alpha = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	var spawn_bravo = map_data.call("get_tile_at_grid", Vector2i(4, 4))
	var objective = map_data.call("get_tile_at_grid", Vector2i(6, 4))
	var patrol_a = map_data.call("get_tile_at_grid", Vector2i(5, 5))
	var patrol_b = map_data.call("get_tile_at_grid", Vector2i(6, 5))
	var cover_tile = map_data.call("get_tile_at_grid", Vector2i(3, 3))
	map_data.call("set_marker_position", "spawn_alpha", Vector2(spawn_alpha.world_position))
	map_data.call("set_marker_position", "spawn_bravo", Vector2(spawn_bravo.world_position))
	map_data.call("set_marker_position", "objective_point", Vector2(objective.world_position))
	map_data.call("set_patrol_path", "enemy_delta", [Vector2(patrol_a.world_position), Vector2(patrol_b.world_position)])
	cover_tile.cover_value = 45
	cover_tile.blocks_los = true
	cover_tile.object_height = 1
	_assert(map_data.call("save_to_file", TEMP_MAP_PATH) == OK, "Valid authoring map fixture saves")
	editor.set("_dirty", false)
	editor.call(
		"set_mission_scenario_authoring_fields",
		{
			"version": 1,
			"scenario_id": "task_229_authoring",
			"display_name": "TASK 229 Authoring",
			"map_file_path": TEMP_MAP_PATH,
			"time_limit_seconds": 180.0,
			"mission_slot_count_override": 3,
			"objective": {"marker_id": "objective_point", "capture_radius": 64.0},
			"enemy_groups": [
				{
					"group_id": "red_test_group",
					"display_name": "Test Contacts",
					"team_id": "team_bravo",
					"enemy_ids": ["enemy_delta"],
					"spawn_marker_id": "spawn_bravo",
					"tactics": ENEMY_TEAM_TACTICS_PROFILE_SCRIPT.call("serialize_config", {"profile_id": "patrol_probe"}, map_data.call("get_grid_size")),
				},
			],
			"wave_config": {"wave_count": 1, "units_per_wave": 1, "first_wave_delay_seconds": 0.0, "wave_delay_seconds": 30.0},
			"patrol_bindings": [{"binding_id": "enemy_delta_patrol", "target_id": "enemy_delta", "patrol_path_id": "enemy_delta", "mode": "pre_contact"}],
		}
	)
	_assert(editor.call("save_mission_scenario_from_editor", TEMP_SCENARIO_PATH) == OK, "Valid authoring scenario fixture saves")


func _make_editor():
	var editor = MAP_EDITOR_SCENE.instantiate()
	root.add_child(editor)
	await _wait_frames(12)
	return editor


func _messages_contain(messages: PackedStringArray, needle: String) -> bool:
	for message in messages:
		if String(message).contains(needle):
			return true
	return false


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
