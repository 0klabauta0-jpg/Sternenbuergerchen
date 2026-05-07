extends SceneTree

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const SINGLEPLAYER_SCENE_PATH: String = "res://scenes/meta/meta_layer_test.tscn"
const MISSION_TEST_SCENE: PackedScene = preload("res://scenes/tests/mission_reactivity_test.tscn")

const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/drop_light_layout_contract.gd")

const BACKGROUND_CATALOG_PATH: String = "res://data/background_image_catalog.json"
const REPORT_PATH: String = "res://docs/reports/asset_audio_background_playability_smoke.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/asset_audio_background_playability_checklist.md"
const TEMP_SETTINGS_PATH: String = "user://task_250_settings.cfg"

const BLUE_UNIT_IDS: Array = ["unit_alpha", "unit_bravo", "unit_delta", "unit_hotel"]
const INITIAL_ENEMY_IDS: Array = ["enemy_delta"]

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_250 Asset Audio Background Playability Smoke ===")
	_remove_user_file(TEMP_SETTINGS_PATH)
	_test_documentation_contract()
	_test_background_catalog_locality_and_budget()
	await _test_main_menu_settings_routes_audio_backgrounds()
	await _test_multiplayer_lobby_playability_audio_backgrounds()
	await _test_mission_audio_visual_background_alignment_smoke()
	_remove_user_file(TEMP_SETTINGS_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_documentation_contract() -> void:
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Manual audio/background playability checklist exists")
	_assert(FileAccess.file_exists(REPORT_PATH), "Audio/background playability report exists")
	var checklist_text: String = _read_text(MANUAL_CHECK_PATH)
	var report_text: String = _read_text(REPORT_PATH)
	for required_text in ["Hauptmenue", "Settings", "Multiplayer", "Mission", "Audio", "Background", "FoW", "TASK_247", "TASK_249"]:
		_assert(checklist_text.contains(required_text), "Manual checklist covers %s" % required_text)
	for required_text in ["Main menu", "Multiplayer", "Mission", "Button sounds", "Movement", "Impact", "Explosion", "TASK_247", "TASK_249"]:
		_assert(report_text.contains(required_text), "Smoke report documents %s" % required_text)


func _test_background_catalog_locality_and_budget() -> void:
	var catalog: Dictionary = _load_json(BACKGROUND_CATALOG_PATH)
	var runtime_contract: Dictionary = Dictionary(catalog.get("runtime_contract", {}))
	var backgrounds: Array = Array(catalog.get("backgrounds", []))
	_assert(String(runtime_contract.get("paths", "")) == "res_only_no_local_user_paths", "Background catalog declares res-only runtime paths")
	_assert(String(runtime_contract.get("load_policy", "")) == "screen_on_demand", "Background catalog keeps screen-on-demand loading")
	_assert(bool(runtime_contract.get("visual_only", false)) and bool(runtime_contract.get("no_gameplay_state", false)), "Background catalog is visual-only")
	_assert(backgrounds.size() >= 5, "Background catalog has all audio/visual series backgrounds")
	for entry_variant in backgrounds:
		var entry: Dictionary = Dictionary(entry_variant)
		var background_id: String = String(entry.get("background_id", ""))
		var path: String = String(entry.get("res_path", ""))
		_assert(_is_project_resource(path), "Background is project-local: %s" % background_id)
		var texture := ResourceLoader.load(path) as Texture2D
		_assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Background texture loads: %s" % background_id)
		_assert(int(entry.get("width", 0)) <= 2048 and int(entry.get("height", 0)) <= 2048, "Background dimensions fit UI budget: %s" % background_id)
		_assert(not String(entry.get("crop_anchor", "")).is_empty(), "Background has crop anchor: %s" % background_id)
		_assert(float(entry.get("dim_strength", 0.0)) >= 0.30, "Background has readable dim strength: %s" % background_id)


func _test_main_menu_settings_routes_audio_backgrounds() -> void:
	root.size = Vector2i(1920, 1080)
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate() as Control
	root.add_child(main_menu)
	await _wait_frames(2)
	main_menu.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	var route_snapshot: Dictionary = Dictionary(main_menu.call("get_route_snapshot"))
	_assert(String(route_snapshot.get("singleplayer", "")) == SINGLEPLAYER_SCENE_PATH, "Singleplayer route remains wired")
	_assert(String(route_snapshot.get("multiplayer", "")) == MULTIPLAYER_LOBBY_SCENE_PATH, "Multiplayer route remains wired")
	_assert(String(route_snapshot.get("editor", "")) == MAP_EDITOR_SCENE_PATH, "Editor route remains wired")
	for route_path in [SINGLEPLAYER_SCENE_PATH, MULTIPLAYER_LOBBY_SCENE_PATH, MAP_EDITOR_SCENE_PATH]:
		_assert(ResourceLoader.exists(route_path), "Route target exists: %s" % route_path)
	var background_snapshot: Dictionary = Dictionary(main_menu.call("get_background_catalog_snapshot"))
	var background := main_menu.get_node_or_null("Background") as TextureRect
	var rail := main_menu.get_node_or_null("MenuRail") as Control
	_assert(String(background_snapshot.get("background_id", "")) == "main_menu_shell", "Main menu exposes catalog background")
	_assert(background != null and background.texture != null and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Main menu background is visible and covered")
	_assert(main_menu.custom_minimum_size == Vector2(1920.0, 1080.0), "Main menu keeps fixed Full-HD minimum size")
	_assert(rail != null and is_equal_approx(rail.size.x, 520.0), "Main menu rail keeps fixed width")

	main_menu.call("open_settings_panel")
	await _wait_frames(2)
	var ui_snapshot: Dictionary = Dictionary(main_menu.call("get_settings_ui_snapshot"))
	_assert(bool(ui_snapshot.get("panel_visible", false)), "Settings panel opens")
	_assert(bool(ui_snapshot.get("audio_section_visible", false)), "Settings exposes audio section")
	main_menu.call("set_draft_audio_settings", 72.0, 61.0, 44.0)
	var apply_error: int = int(main_menu.call("apply_settings"))
	_assert(apply_error == OK, "Settings audio values apply")
	var loaded_settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	_assert(is_equal_approx(float(loaded_settings.get("master_volume", 0.0)), 72.0), "Master volume persists")
	_assert(is_equal_approx(float(loaded_settings.get("sfx_volume", 0.0)), 44.0), "SFX volume persists")
	var audio_snapshot: Dictionary = Dictionary(main_menu.call("get_audio_sfx_debug_snapshot"))
	var event_counts: Dictionary = Dictionary(audio_snapshot.get("played_count_by_event", {}))
	_assert(int(event_counts.get("ui_click", 0)) >= 1, "Settings open plays UI click")
	_assert(int(event_counts.get("ui_confirm", 0)) >= 1, "Settings apply plays UI confirm")
	_assert(int(audio_snapshot.get("missing_id_count", 0)) == 0 and int(audio_snapshot.get("missing_resource_count", 0)) == 0, "Main menu UI audio has no missing diagnostics")
	_assert(main_menu.find_child("SimulationRoot", true, false) == null, "Main menu/settings do not create gameplay state")
	main_menu.queue_free()
	await _wait_frames(2)


func _test_multiplayer_lobby_playability_audio_backgrounds() -> void:
	root.size = Vector2i(1280, 720)
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate() as Control
	root.add_child(lobby)
	await _wait_frames(2)
	lobby.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var background_snapshot: Dictionary = Dictionary(ui_snapshot.get("background", {}))
	_assert(bool(ui_snapshot.get("host_controls_visible", false)), "Lobby exposes host controls")
	_assert(bool(ui_snapshot.get("join_controls_visible", false)), "Lobby exposes join controls")
	_assert(String(background_snapshot.get("background_id", "")) == "multiplayer_lobby_hangar", "Lobby exposes hangar background")
	_assert(bool(background_snapshot.get("has_texture", false)), "Lobby background texture is loaded")
	_assert(lobby.custom_minimum_size == Vector2(1280.0, 720.0), "Lobby keeps fixed minimum size")
	var panel := lobby.get_node_or_null("Panel") as Control
	_assert(panel != null and is_equal_approx(panel.size.x, 720.0) and is_equal_approx(panel.size.y, 560.0), "Lobby panel keeps fixed size")
	var idle_audio: Dictionary = Dictionary(ui_snapshot.get("audio_sfx", {}))
	await _wait_frames(4)
	var still_idle_audio: Dictionary = Dictionary(lobby.call("get_audio_sfx_debug_snapshot"))
	_assert(int(still_idle_audio.get("played_count", 0)) == int(idle_audio.get("played_count", 0)), "Lobby does not duplicate audio events while idle")

	lobby.call("configure_host_state_for_test", [1, 2])
	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	await _wait_frames(2)
	_assert(bool(lobby.call("start_mission")), "Host-ready lobby can request mission start")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(int(ui_snapshot.get("mission_start_request_count", 0)) == 1, "Lobby records exactly one mission start request")
	var audio_snapshot: Dictionary = Dictionary(ui_snapshot.get("audio_sfx", {}))
	var event_counts: Dictionary = Dictionary(audio_snapshot.get("played_count_by_event", {}))
	_assert(int(event_counts.get("ui_confirm", 0)) >= 1, "Lobby mission start plays confirm UI audio")
	_assert(int(audio_snapshot.get("missing_id_count", 0)) == 0 and int(audio_snapshot.get("missing_resource_count", 0)) == 0, "Lobby UI audio has no missing diagnostics")
	lobby.call("configure_client_state_for_test", [1, 2])
	await _wait_frames(1)
	_assert(not bool(lobby.call("start_mission")), "Client lobby cannot start mission directly")
	_assert(lobby.find_child("SimulationRoot", true, false) == null, "Lobby does not create gameplay SimulationRoot")
	lobby.queue_free()
	await _wait_frames(2)


func _test_mission_audio_visual_background_alignment_smoke() -> void:
	root.size = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.get("TARGET_VIEWPORT")
	var scene: Node = MISSION_TEST_SCENE.instantiate()
	_configure_scene_for_blue_drop(scene)
	_stage_waiting_dropship(scene.get_node("TacticalController"))
	root.add_child(scene)
	await _wait_frames(18)
	await _wait_physics_frames(4)
	var context: Dictionary = _get_mission_context(scene)
	_assert(not context.is_empty(), "Mission exposes controller, combat, SimulationRoot, registries and Primary3DView")
	if context.is_empty():
		scene.queue_free()
		await _wait_frames(2)
		return
	_assert(_arrays_equal(_get_registry_unit_ids(context["unit_registry"]), INITIAL_ENEMY_IDS), "Mission starts with authored enemy active before drop")
	_assert(_mission_hud_fixed_windows_match(scene), "Mission HUD fixed windows remain aligned")
	await _deploy_blue_fireteam(context)
	_set_probe_weapon_loadouts(context)
	_sync_primary_view_units(context)
	await _wait_frames(12)
	var expected_active: Array = BLUE_UNIT_IDS + INITIAL_ENEMY_IDS
	_assert(_arrays_equal(_get_registry_unit_ids(context["unit_registry"]), expected_active), "Friendly drop plus enemy are active in the registry")
	var primary_view: Node = context["primary_view"]
	var visual_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(_unit_proxy_ids_are_unique(visual_snapshot), "Mission unit proxy IDs stay unique")
	_assert(_arrays_equal(_active_visual_ids(visual_snapshot, expected_active), expected_active), "Friendly and enemy units have visible proxies or explicit diagnostics")
	_assert(int(visual_snapshot.get("unit_visual_loadout_count", 0)) > 0, "Mission exposes visual weapon loadouts")
	_assert(int(visual_snapshot.get("unit_blaster_attachment_count", 0)) > 0, "Mission exposes weapon attachments")
	_assert(int(visual_snapshot.get("unit_visual_loadout_error_count", 0)) == 0 and int(visual_snapshot.get("unit_blaster_error_count", 0)) == 0, "Mission visual loadouts and weapon attachments are clean")

	var simulation_root: Node = context["simulation_root"]
	var before_command_count: int = _array_property_size(simulation_root, "command_queue")
	var before_effect_count: int = _array_property_size(simulation_root, "effects_queue")
	_apply_fow_fire_event_probe(primary_view)
	await _wait_frames(8)
	var fire_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
	_assert(int(fire_snapshot.get("weapon_fire_vfx_visual_count", 0)) == 1, "FoW allows only the visible weapon-fire VFX")
	_assert(int(fire_snapshot.get("weapon_fire_sfx_count", 0)) >= 1, "Visible weapon-fire VFX emits combat SFX")
	_assert(int(fire_snapshot.get("fow_hidden_order_visual_count", 0)) >= 1, "FoW hides the non-visible weapon-fire event")
	var movement_result: Dictionary = Dictionary(primary_view.call("emit_movement_step_sfx_for_tests", "unit_alpha", "sand", true, true, 25000))
	_assert(bool(movement_result.get("played", false)), "Mission movement step SFX plays")
	var combat_driver: Node = context["combat_driver"]
	var impact_result: Dictionary = Dictionary(combat_driver.call("emit_impact_sfx_for_tests", {
		"weapon_id": "rocket_launcher",
		"unit_id": "enemy_delta",
		"fire_event_id": "task250_visible_fire",
		"attacker_team_id": "team_alpha",
		"visible_to_local": true,
	}, null))
	var driver_audio: Dictionary = Dictionary(combat_driver.call("get_audio_sfx_debug_snapshot"))
	var driver_counts: Dictionary = Dictionary(driver_audio.get("played_count_by_event", {}))
	_assert(String(impact_result.get("event_id", "")) == "impact_metal_heavy", "Rocket impact SFX maps to heavy impact")
	_assert(int(driver_counts.get("explosion_large", 0)) >= 1, "Rocket impact emits explosion SFX")
	_assert(_array_property_size(simulation_root, "command_queue") == before_command_count, "Audio/visual smoke does not enqueue gameplay commands")
	_assert(_array_property_size(simulation_root, "effects_queue") == before_effect_count, "Audio/visual smoke does not enqueue gameplay effects")
	scene.queue_free()
	await _wait_frames(2)


func _configure_scene_for_blue_drop(scene: Node) -> void:
	var mission_setup := scene.get_node_or_null("MissionSetup")
	if mission_setup != null:
		mission_setup.set("defer_friendly_runtime_activation", true)
		mission_setup.set("allow_full_roster_when_selection_empty", false)
		mission_setup.set("selected_team_unit_ids", PackedStringArray(BLUE_UNIT_IDS))
		mission_setup.set("selected_team_fireteam_ids", PackedStringArray(["blue", "blue", "blue", "blue"]))
		mission_setup.set(
			"selected_fireteam_definitions",
			[
				{
					"id": "blue",
					"label": "BLUE",
					"lead_unit_id": "unit_alpha",
					"respawn_enabled": false,
					"loadout": "medium",
				}
			]
		)
	var combat_driver := scene.get_node_or_null("CombatLoopDriver")
	if combat_driver != null:
		combat_driver.set("enemy_advance_enabled", false)
		combat_driver.set("enemy_reposition_enabled", false)
		combat_driver.set("base_hit_chance", 0.0)
		combat_driver.set("damage_per_hit", 0)


func _stage_waiting_dropship(controller: Node) -> void:
	if controller == null:
		return
	var planning_state: Dictionary = Dictionary(controller.call("get_planning_state"))
	planning_state["mission_drop_state"] = "waiting"
	planning_state["mission_drop_craft_id"] = "task_250_dropship"
	planning_state["mission_drop_display_name"] = "TASK 250 Dropship"
	planning_state["mission_drop_title_text"] = "TASK 250 Dropship"
	planning_state["mission_drop_texture_path"] = "res://Assets/kenney_space-kit/Side/craft_speederB.png"
	planning_state["mission_drop_status_line"] = "Holding on mission map"
	planning_state["mission_drop_progress"] = 100.0
	planning_state["mission_drop_passenger_count"] = BLUE_UNIT_IDS.size()
	planning_state["selected_fireteam"] = "BLUE"
	planning_state["selected_fireteams"] = ["blue"]
	planning_state["embarked_unit_ids"] = BLUE_UNIT_IDS.duplicate()
	planning_state["deployed_unit_ids"] = []
	planning_state["drop_ship_requested"] = false
	planning_state["drop_ship_staged"] = false
	planning_state["has_lz_position"] = false
	controller.call("set_planning_state", planning_state)


func _get_mission_context(scene: Node) -> Dictionary:
	var context: Dictionary = {
		"controller": scene.get_node_or_null("TacticalController"),
		"combat_driver": scene.get_node_or_null("CombatLoopDriver"),
		"simulation_root": scene.get_node_or_null("SimulationRoot"),
		"unit_registry": scene.get_node_or_null("UnitRegistry"),
		"terrain_registry": scene.get_node_or_null("TerrainRegistry"),
		"primary_view": scene.get_node_or_null("Primary3DView"),
	}
	for value in context.values():
		if value == null:
			return {}
	return context


func _deploy_blue_fireteam(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var primary_view: Node = context["primary_view"]
	var simulation_root: Node = context["simulation_root"]
	var objective_position: Vector2 = _get_objective_position(simulation_root, Vector2(448.0, 285.0))
	_assert(_place_lz_via_player_path(controller, primary_view, objective_position), "Player path places LZ for audio/visual smoke")
	controller.call("_on_call_dropship_pressed")
	await _wait_frames(2)
	await _drive_drop_until_outbound(controller)
	await _wait_physics_frames(8)
	await _wait_frames(8)
	_assert(String(controller.get("_drop_sequence_phase")) == "outbound", "Dropship deploy reaches outbound phase")


func _place_lz_via_player_path(controller: Node, primary_view: Node, world_position: Vector2) -> bool:
	controller.call("_on_set_lz_pressed")
	var screen_position: Vector2 = primary_view.call("world_to_screen_position", world_position) if primary_view != null and primary_view.has_method("world_to_screen_position") else controller.get_viewport().get_canvas_transform() * world_position
	return bool(controller.call("_place_lz_from_screen_position", screen_position))


func _drive_drop_until_outbound(controller: Node) -> void:
	for _step in range(96):
		controller.call("_update_drop_sequence", 0.25)
		await physics_frame
		await process_frame
		if String(controller.get("_drop_sequence_phase")) == "outbound":
			return


func _set_probe_weapon_loadouts(context: Dictionary) -> void:
	var controller: Node = context["controller"]
	var sniper = _find_friendly_unit(controller, "unit_alpha")
	var rocket = _find_friendly_unit(controller, "unit_delta")
	if sniper != null:
		sniper.set("weapon_1_id", "sniper")
		sniper.set("weapon_2_id", "smg")
	if rocket != null:
		rocket.set("weapon_1_id", "rocket_launcher")
		rocket.set("weapon_2_id", "smg")


func _sync_primary_view_units(context: Dictionary) -> void:
	var primary_view: Node = context["primary_view"]
	var unit_registry: Node = context["unit_registry"]
	if primary_view != null and unit_registry != null and primary_view.has_method("set_unit_nodes"):
		primary_view.call("set_unit_nodes", Array(unit_registry.call("get_all_units")))


func _apply_fow_fire_event_probe(primary_view: Node) -> void:
	primary_view.call("set_fog_of_war_state", {
		"mode": "unexplored_blackout",
		"team_id": "team_alpha",
		"terrain_knowledge": {
			"visible_tile_ids": PackedStringArray(),
			"explored_tile_ids": PackedStringArray(),
		},
		"current_visibility": {
			"visible_target_ids": PackedStringArray(BLUE_UNIT_IDS),
			"visible_event_ids": PackedStringArray(["task250_visible_fire"]),
		},
	})
	primary_view.call("set_order_visual_payload", {
		"phase_index": 1,
		"fire_event_dicts": [
			_build_fire_event("task250_visible_fire", "rocket_launcher", Vector2(384.0, 256.0), Vector2(512.0, 256.0), "unit_alpha", "enemy_delta"),
			_build_fire_event("task250_hidden_fire", "rocket_launcher", Vector2(9000.0, 9000.0), Vector2(9200.0, 9000.0), "hidden_attacker", "hidden_target"),
		],
	})


func _build_fire_event(event_id: String, weapon_id: String, attacker_position: Vector2, target_position: Vector2, attacker_unit_id: String, target_unit_id: String) -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": "weapon_fire",
		"source": "task_250_playability_smoke",
		"tick": 250,
		"sequence": 1,
		"attacker_unit_id": attacker_unit_id,
		"attacker_team_id": "team_alpha",
		"target_unit_id": target_unit_id,
		"target_team_id": "team_bravo",
		"weapon_id": weapon_id,
		"weapon_tile_range": 25,
		"weapon_range_world": 1800.0,
		"attacker_position": attacker_position,
		"target_position": target_position,
	}


func _mission_hud_fixed_windows_match(scene: Node) -> bool:
	var layout: Dictionary = DROP_LIGHT_LAYOUT_CONTRACT_SCRIPT.call("get_mission_hud_layout")
	var paths: Dictionary = {
		"command_matrix": "TacticalUI/BottomDock/BottomMargin/BottomRow/CommandPanel",
		"selected_fireteam": "TacticalUI/BottomDock/BottomMargin/BottomRow/FireteamPanel",
		"mission_control": "TacticalUI/BottomDock/BottomMargin/BottomRow/StrategicPanel",
	}
	for key_variant in paths.keys():
		var control := scene.get_node_or_null(String(paths[key_variant])) as Control
		if not _control_matches_rect(control, layout.get(String(key_variant))):
			return false
	return true


func _control_matches_rect(control: Control, rect_variant: Variant) -> bool:
	if control == null or typeof(rect_variant) != TYPE_RECT2I:
		return false
	var rect: Rect2i = rect_variant
	return absf(control.global_position.x - float(rect.position.x)) <= 0.5 \
		and absf(control.global_position.y - float(rect.position.y)) <= 0.5 \
		and absf(control.size.x - float(rect.size.x)) <= 0.5 \
		and absf(control.size.y - float(rect.size.y)) <= 0.5


func _find_friendly_unit(controller: Node, unit_id: String):
	for unit in Array(controller.call("_get_all_friendly_units", false)):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		if String(unit.call("get_unit_id")) == unit_id:
			return unit
	return null


func _get_objective_position(simulation_root: Node, fallback: Vector2) -> Vector2:
	if simulation_root == null or not simulation_root.has_method("get_objective_status"):
		return fallback
	var objective_status = simulation_root.call("get_objective_status")
	if objective_status == null:
		return fallback
	if typeof(objective_status.get("position")) == TYPE_VECTOR2:
		return Vector2(objective_status.get("position"))
	return fallback


func _get_registry_unit_ids(unit_registry: Node) -> Array:
	var unit_ids: Array = []
	if unit_registry == null:
		return unit_ids
	for unit in Array(unit_registry.call("get_all_units")):
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			unit_ids.append(unit_id)
	unit_ids.sort()
	return unit_ids


func _active_visual_ids(primary_snapshot: Dictionary, expected_active: Array) -> Array:
	var visual_ids: Array = _array_union(Array(primary_snapshot.get("visible_unit_proxy_ids", [])), Array(primary_snapshot.get("missing_unit_model_ids", [])))
	return _array_intersection(visual_ids, expected_active)


func _unit_proxy_ids_are_unique(primary_snapshot: Dictionary) -> bool:
	var proxy_ids: Array = Array(primary_snapshot.get("unit_proxy_ids", []))
	return proxy_ids.size() == _unique_strings(proxy_ids).size()


func _array_property_size(node: Node, property_name: String) -> int:
	if node == null:
		return -1
	var value: Variant = node.get(property_name)
	return Array(value).size() if typeof(value) == TYPE_ARRAY else -1


func _is_project_resource(path: String) -> bool:
	var normalized_path: String = path.strip_edges()
	return normalized_path.begins_with("res://") \
		and not normalized_path.contains("C:/") \
		and not normalized_path.contains("C:" + "\\") \
		and ResourceLoader.exists(normalized_path)


func _array_union(a: Array, b: Array) -> Array:
	var result: Array = _sorted_strings(a)
	for value in b:
		var item: String = String(value).strip_edges()
		if not item.is_empty() and not result.has(item):
			result.append(item)
	result.sort()
	return result


func _array_intersection(a: Array, b: Array) -> Array:
	var b_lookup: Dictionary = {}
	for value in b:
		var item: String = String(value).strip_edges()
		if not item.is_empty():
			b_lookup[item] = true
	var result: Array = []
	for value in a:
		var item: String = String(value).strip_edges()
		if not item.is_empty() and b_lookup.has(item):
			result.append(item)
	result.sort()
	return result


func _unique_strings(values: Array) -> Array:
	var lookup: Dictionary = {}
	for value in values:
		var item: String = String(value).strip_edges()
		if not item.is_empty():
			lookup[item] = true
	var result: Array = lookup.keys()
	result.sort()
	return result


func _sorted_strings(values: Array) -> Array:
	var result: Array = []
	for value in values:
		var item: String = String(value).strip_edges()
		if not item.is_empty():
			result.append(item)
	result.sort()
	return result


func _arrays_equal(a: Array, b: Array) -> bool:
	var left: Array = _sorted_strings(a)
	var right: Array = _sorted_strings(b)
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if String(left[index]) != String(right[index]):
			return false
	return true


func _load_json(path: String) -> Dictionary:
	var text: String = _read_text(path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


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
	for _index in range(maxi(frame_count, 0)):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(maxi(frame_count, 0)):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
		return
	_failed += 1
	print("  FAIL: %s" % message)
