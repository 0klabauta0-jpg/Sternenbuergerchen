extends SceneTree

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const SINGLEPLAYER_SCENE_PATH: String = "res://scenes/meta/meta_layer_test.tscn"
const REVIEW_DOC_PATH: String = "res://docs/reviews/app_shell_game_setup_open_items_review.md"
const MANUAL_CHECKLIST_PATH: String = "res://docs/manual_checks/app_shell_full_flow_checklist.md"
const PROJECT_PATH: String = "res://project.godot"
const TEMP_SETTINGS_PATH: String = "user://task_231_app_shell_settings.cfg"
const TEMP_MAP_PATH: String = "user://task_231_host_map.json"
const TEMP_EDITOR_MAP_PATH: String = "user://task_231_editor_map.json"
const TEMP_EDITOR_SCENARIO_PATH: String = "user://task_231_editor_scenario.json"
const TEMP_CACHE_ROOT: String = "user://task_231_downloaded_maps"

const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const TACTICAL_CONTROLLER_SCRIPT: GDScript = preload("res://scripts/mission/mission_tactical_sandbox_controller.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const ENEMY_TEAM_TACTICS_PROFILE_SCRIPT: GDScript = preload("res://scripts/tactical/enemy_team_tactics_profile.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_231 App Shell Game Setup Integration and Open Items Review ===")
	_remove_user_file(TEMP_SETTINGS_PATH)
	_test_review_docs()
	await _test_main_menu_paths_settings_and_runtime_boundaries()
	await _test_multiplayer_lobby_map_consent_and_start_smoke()
	await _test_editor_map_preparation_and_live_test()
	await _test_fow_air_layer_integration_smoke()
	_remove_user_file(TEMP_SETTINGS_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_review_docs() -> void:
	var review_text: String = _read_text(REVIEW_DOC_PATH)
	var checklist_text: String = _read_text(MANUAL_CHECKLIST_PATH)
	_assert(not review_text.is_empty(), "App-shell open-items review doc exists")
	_assert(not checklist_text.is_empty(), "App-shell manual full-flow checklist exists")
	for required_text in ["Singleplayer", "Multiplayer", "Editor", "Settings", "FoW", "mission_air", "Consent", "offene Punkte"]:
		_assert(review_text.contains(required_text), "Review doc covers %s" % required_text)
	for required_text in ["Hauptmenue", "Einzelspieler", "Multiplayer", "Editor", "FoW", "Air", "Abnahme"]:
		_assert(checklist_text.contains(required_text), "Manual checklist covers %s" % required_text)


func _test_main_menu_paths_settings_and_runtime_boundaries() -> void:
	var project_text: String = _read_text(PROJECT_PATH)
	_assert(project_text.contains('run/main_scene="%s"' % MAIN_MENU_SCENE_PATH), "Project starts at main menu")
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await _wait_frames(2)
	var routes: Dictionary = Dictionary(main_menu.call("get_route_snapshot"))
	_assert(String(routes.get("singleplayer", "")) == SINGLEPLAYER_SCENE_PATH, "Singleplayer route is wired")
	_assert(String(routes.get("multiplayer", "")) == MULTIPLAYER_LOBBY_SCENE_PATH, "Multiplayer route is wired")
	_assert(String(routes.get("editor", "")) == MAP_EDITOR_SCENE_PATH, "Editor route is wired")
	_assert(String(routes.get("settings", "")) == "local_settings_panel", "Settings route stays local")
	for scene_path in [SINGLEPLAYER_SCENE_PATH, MULTIPLAYER_LOBBY_SCENE_PATH, MAP_EDITOR_SCENE_PATH]:
		_assert(ResourceLoader.exists(scene_path), "Route scene exists: %s" % scene_path)
		_assert(ResourceLoader.load(scene_path) is PackedScene, "Route scene loads: %s" % scene_path)

	main_menu.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	main_menu.call("open_settings_panel")
	await _wait_frames(2)
	var ui_snapshot: Dictionary = Dictionary(main_menu.call("get_settings_ui_snapshot"))
	_assert(bool(ui_snapshot.get("display_section_visible", false)), "Settings exposes Display section")
	_assert(bool(ui_snapshot.get("audio_section_visible", false)), "Settings exposes Audio section")
	_assert(bool(ui_snapshot.get("input_section_visible", false)), "Settings exposes Input section")
	_assert(bool(ui_snapshot.get("gameplay_section_visible", false)), "Settings exposes Gameplay section")
	var settings_sections: Dictionary = Dictionary(ui_snapshot.get("sections", {}))
	_assert(Dictionary(settings_sections.get("gameplay", {})).has("comic_bubbles"), "Settings exposes Bubble gameplay section")

	main_menu.call("set_draft_fog_of_war_mode", "unexplored_blackout")
	main_menu.call("set_draft_comic_bubble_mode", "minimal")
	_assert(int(main_menu.call("apply_settings")) == OK, "Settings apply persists gameplay choices")
	var gameplay_loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	var bubble_loaded: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	_assert(String(gameplay_loaded.get("fog_of_war_mode", "")) == "unexplored_blackout", "FoW setting persists from app shell")
	_assert(String(bubble_loaded.get("mode", "")) == "minimal", "Bubble setting persists from app shell")

	main_menu.call("set_draft_display_settings", "1600x900", "borderless", false)
	main_menu.call("set_draft_audio_settings", 52.0, 41.0, 35.0)
	_assert(int(main_menu.call("apply_settings")) == OK, "Display and audio settings apply")
	gameplay_loaded = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	bubble_loaded = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	_assert(String(gameplay_loaded.get("resolution_preset", "")) == "1600x900", "Display setting persists")
	_assert(is_equal_approx(float(gameplay_loaded.get("master_volume", 0.0)), 52.0), "Audio setting persists")
	_assert(String(gameplay_loaded.get("fog_of_war_mode", "")) == "unexplored_blackout", "Display/audio apply does not mutate FoW gameplay setting")
	_assert(String(bubble_loaded.get("mode", "")) == "minimal", "Display/audio apply does not mutate Bubble gameplay setting")
	_assert(main_menu.find_child("SimulationRoot", true, false) == null, "Main menu/settings do not create SimulationRoot")

	var tactical_controller: Node = TACTICAL_CONTROLLER_SCRIPT.new()
	tactical_controller.call("set_comic_bubble_settings", bubble_loaded)
	var bubble_snapshot: Dictionary = Dictionary(tactical_controller.call("get_comic_bubble_settings_snapshot"))
	_assert(String(bubble_snapshot.get("mode", "")) == "minimal", "Mission tactical bubble gate accepts app-shell bubble setting")
	tactical_controller.free()
	main_menu.queue_free()
	await _wait_frames(2)


func _test_multiplayer_lobby_map_consent_and_start_smoke() -> void:
	var map_text: String = _write_fixture_map(TEMP_MAP_PATH, "task_231_host_map", 4)
	var manifest: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", TEMP_MAP_PATH))
	_assert(bool(manifest.get("valid", false)), "Editor-style host map manifest is valid")
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate()
	root.add_child(lobby)
	await _wait_frames(2)
	lobby.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(String(ui_snapshot.get("settings_text", "")).contains("unexplored_blackout"), "Lobby reads app-shell FoW setting summary")

	var known_state: Dictionary = Dictionary(lobby.call("set_host_map_manifest", manifest, [TEMP_MAP_PATH]))
	_assert(String(known_state.get("state", "")) == "known", "Client with matching local editor map needs no consent")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(not bool(ui_snapshot.get("map_consent_visible", true)), "Known map keeps consent prompt hidden")

	var missing_state: Dictionary = Dictionary(lobby.call("set_host_map_manifest", manifest, []))
	_assert(String(missing_state.get("state", "")) == "missing", "Unknown host map requires client consent")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(bool(ui_snapshot.get("map_consent_visible", false)), "Unknown map shows consent prompt")
	var reject_result: Dictionary = Dictionary(lobby.call("reject_pending_map_download"))
	_assert(String(reject_result.get("state", "")) == "rejected" and not bool(reject_result.get("can_start_client", true)), "Reject blocks unknown-map client start")
	lobby.call("set_host_map_manifest", manifest, [])
	var accept_result: Dictionary = Dictionary(lobby.call("accept_pending_map_download", map_text, TEMP_CACHE_ROOT))
	_assert(bool(accept_result.get("accepted", false)), "Accept validates and caches unknown host map")
	_assert(FileAccess.file_exists(String(accept_result.get("cache_path", ""))), "Accepted host map exists in safe user cache")

	lobby.call("configure_host_state_for_test", [1, 2])
	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	await _wait_frames(2)
	_assert(bool(lobby.call("start_mission")), "Host can request mission start after peers are ready")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(int(ui_snapshot.get("mission_start_request_count", 0)) == 1, "Mission start request is routed through lobby/session")
	lobby.call("configure_client_state_for_test", [1, 2])
	await _wait_frames(2)
	_assert(not bool(lobby.call("start_mission")), "Client cannot start mission directly")
	_assert(lobby.find_child("SimulationRoot", true, false) == null, "Lobby does not create gameplay SimulationRoot")
	lobby.queue_free()
	await _wait_frames(2)


func _test_editor_map_preparation_and_live_test() -> void:
	var packed_scene := ResourceLoader.load(MAP_EDITOR_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Map editor scene loads")
	if packed_scene == null:
		return
	var editor := packed_scene.instantiate()
	root.add_child(editor)
	await _wait_frames(12)
	_assert(bool(editor.call("set_authoring_tool", "height")), "Editor height authoring tool is reachable")
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(1, 1))), "Editor can select tile for authoring")
	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot"))
	_assert(String(usability.get("active_tool", "")) == "height", "Editor usability snapshot exposes active tool")
	_assert(Dictionary(usability.get("action_contract", {})).has("undo_redo_scope"), "Editor exposes authoring action contract")
	_prepare_valid_editor_fixture(editor)
	var validation: Dictionary = Dictionary(editor.call("get_authoring_validation_snapshot", false))
	_assert(bool(validation.get("valid", false)), "Editor-prepared map/scenario validates")
	var sections: Dictionary = Dictionary(validation.get("sections", {}))
	_assert(Dictionary(sections.get("markers", {})).has("marker_count"), "Editor validation includes markers")
	_assert(Dictionary(sections.get("fow", {})).has("los_blocker_count"), "Editor validation includes FoW authoring diagnostics")
	var manifest: Dictionary = Dictionary(editor.call("build_multiplayer_map_manifest_preview"))
	_assert(bool(manifest.get("ready", false)), "Editor can prepare multiplayer manifest preview")
	usability = Dictionary(editor.call("get_map_editor_usability_snapshot"))
	_assert(bool(Dictionary(usability.get("live_test", {})).get("ready", false)), "Editor reports live-test readiness")
	var live_scene = editor.call("create_live_test_scene_from_current_scenario")
	_assert(live_scene != null, "Editor can create live-test scene")
	if live_scene != null:
		live_scene.free()
	_assert(editor.find_child("SimulationRoot", true, false) == null, "Editor authoring path does not keep gameplay SimulationRoot")
	editor.queue_free()
	await _wait_frames(2)


func _test_fow_air_layer_integration_smoke() -> void:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "task_231_air_map", Vector2i(4, 4), Vector2.ZERO)
	var hidden_tile = map_data.call("get_tile_at_grid", Vector2i(3, 3))
	hidden_tile.height_level = 2
	hidden_tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF")
	hidden_tile.object_height = 2
	hidden_tile.blocks_los = true
	var hidden_world: Vector2 = hidden_tile.world_position
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	var settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	view.call(
		"set_fog_of_war_state",
		{
			"mode": String(settings.get("fog_of_war_mode", "unexplored_blackout")),
			"team_id": "team_alpha",
			"terrain_knowledge": {
				"visible_tile_ids": PackedStringArray(["tile_0_0"]),
				"explored_tile_ids": PackedStringArray(["tile_0_0"]),
			},
			"current_visibility": {
				"visible_target_ids": PackedStringArray(),
				"visible_event_ids": PackedStringArray(),
			},
		}
	)
	view.call(
		"set_mission_drop_visual_state",
		{
			"dropship_visible": true,
			"dropship_position": hidden_world,
			"has_lz_position": true,
			"lz_position": hidden_world,
			"team_id": "team_alpha",
		}
	)
	await _wait_frames(8)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	_assert(String(snapshot.get("fog_of_war_mode", "")) == "unexplored_blackout", "App-shell FoW mode reaches 2.5D map state")
	_assert(String(snapshot.get("flight_altitude_layer", "")) == "mission_air", "Dropship uses mission_air layer")
	_assert(bool(snapshot.get("dropship_model_visible", false)) or bool(snapshot.get("dropship_texture_visible", false)), "Friendly dropship remains visible under FoW")
	_assert(bool(snapshot.get("dropship_above_terrain", false)), "Dropship stays above terrain height")
	_assert(int(snapshot.get("lz_tile_marker_count", -1)) == 0, "Hidden LZ marker does not reveal unknown terrain")
	_assert(int(snapshot.get("air_unknown_terrain_reveal_block_count", 0)) >= 1, "Air layer records blocked unknown-terrain reveal")
	_assert(not view.has_method("submit_command") and not view.has_method("enqueue_effect"), "FoW/Air visual smoke exposes no gameplay mutation API")
	view.queue_free()
	await _wait_frames(2)


func _prepare_valid_editor_fixture(editor: Node) -> void:
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "Editor exposes TerrainMapData for integration fixture")
	if map_data == null:
		return
	editor.set("_current_map_path", TEMP_EDITOR_MAP_PATH)
	var spawn_alpha = map_data.call("get_tile_at_grid", Vector2i(1, 1))
	var spawn_bravo = map_data.call("get_tile_at_grid", Vector2i(4, 4))
	var objective = map_data.call("get_tile_at_grid", Vector2i(6, 4))
	var patrol_a = map_data.call("get_tile_at_grid", Vector2i(5, 5))
	var patrol_b = map_data.call("get_tile_at_grid", Vector2i(6, 5))
	var cover_tile = map_data.call("get_tile_at_grid", Vector2i(3, 3))
	_assert(spawn_alpha != null and spawn_bravo != null and objective != null and patrol_a != null and patrol_b != null and cover_tile != null, "Editor fixture tiles exist")
	if spawn_alpha == null or spawn_bravo == null or objective == null or patrol_a == null or patrol_b == null or cover_tile == null:
		return
	map_data.call("set_marker_position", "spawn_alpha", Vector2(spawn_alpha.world_position))
	map_data.call("set_marker_position", "spawn_bravo", Vector2(spawn_bravo.world_position))
	map_data.call("set_marker_position", "objective_point", Vector2(objective.world_position))
	map_data.call("set_patrol_path", "enemy_delta", [Vector2(patrol_a.world_position), Vector2(patrol_b.world_position)])
	cover_tile.cover_value = 45
	cover_tile.blocks_los = true
	cover_tile.object_height = 1
	_assert(map_data.call("save_to_file", TEMP_EDITOR_MAP_PATH) == OK, "Editor integration map saves")
	editor.set("_dirty", false)
	editor.call(
		"set_mission_scenario_authoring_fields",
		{
			"version": 1,
			"scenario_id": "task_231_app_shell",
			"display_name": "TASK 231 App Shell",
			"map_file_path": TEMP_EDITOR_MAP_PATH,
			"time_limit_seconds": 180.0,
			"mission_slot_count_override": 3,
			"objective": {"marker_id": "objective_point", "capture_radius": 64.0},
			"enemy_groups": [
				{
					"group_id": "task_231_red_group",
					"display_name": "Task 231 Contacts",
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
	_assert(editor.call("save_mission_scenario_from_editor", TEMP_EDITOR_SCENARIO_PATH) == OK, "Editor integration scenario saves")


func _write_fixture_map(path: String, map_name: String, size: int) -> String:
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", map_name, Vector2i(size, size), Vector2.ZERO, 64.0, 32.0, 3)
	var save_error: Error = map_data.call("save_to_file", path)
	_assert(save_error == OK, "Fixture map saves: %s" % path)
	return _read_text(path)


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


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
