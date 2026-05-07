extends SceneTree

const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/playability/playability_test_harness.gd")
const UNIT_ROSTER_PRESETS_SCRIPT: GDScript = preload("res://scripts/npc/unit_roster_presets.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const MISSION_PROGRESSION_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/mission_progression_resolver.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const SINGLEPLAYER_SCENE_PATH: String = "res://scenes/meta/meta_layer_test.tscn"
const HOMEBASE_SCENE_PATH: String = "res://scenes/meta/homebase_test_screen.tscn"
const FOB_SCENE_PATH: String = "res://scenes/meta/fob_test_screen.tscn"
const MISSION_SCENE_PATH: String = "res://scenes/tests/mission_reactivity_test.tscn"
const DEBRIEF_SCENE_PATH: String = "res://scenes/meta/debrief_test_screen.tscn"

const REPORT_PATH: String = "res://docs/reports/playability_cross_screen_state_loss_report.md"
const TEMP_SETTINGS_PATH: String = "user://task_261_cross_screen_settings.cfg"
const TEMP_EDITOR_MAP_PATH: String = "user://task_261_editor_roundtrip_map.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_261 Cross Screen State Loss Playability Smoke ===")
	_remove_user_file(TEMP_SETTINGS_PATH)
	var context: Dictionary = _build_flow_context()
	await _test_main_menu_settings_state(context)
	await _test_homebase_fob_mission_debrief_homebase_state(context)
	await _test_editor_flow_does_not_touch_app_state(context)
	await _test_multiplayer_preparation_roundtrip(context)
	_test_report_exists()
	_remove_user_file(TEMP_SETTINGS_PATH)
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _build_flow_context() -> Dictionary:
	var units: Array = UNIT_ROSTER_PRESETS_SCRIPT.call("get_homebase_roster")
	var selected_unit_ids := PackedStringArray(["unit_alpha", "unit_bravo"])
	var selected_fireteam_ids := PackedStringArray(["ft1", "ft1"])
	var context: Dictionary = {
		"units": units,
		"initial_unit_id_set": _unit_id_set(units),
		"selected_unit_ids": selected_unit_ids,
		"selected_fireteam_ids": selected_fireteam_ids,
		"fireteam_definitions": [_build_fireteam_definition("ft1", "unit_alpha")],
		"settings_expected": {
			"resolution_preset": "1600x900",
			"window_mode": "borderless",
			"fog_of_war_mode": "unexplored_blackout",
			"comic_bubble_mode": "minimal",
			"master_volume": 61.0,
			"music_volume": 42.0,
			"sfx_volume": 37.0,
		},
	}
	_assert(units.size() >= 8, "Cross-screen fixture starts with enough preset operators")
	_assert(_unit_id_set(units).has("unit_alpha") and _unit_id_set(units).has("unit_bravo"), "Cross-screen fixture has stable mission-compatible unit IDs")
	return context


func _test_main_menu_settings_state(context: Dictionary) -> void:
	root.size = Vector2i(1920, 1080)
	var main_menu: Node = HARNESS_SCRIPT.instantiate_scene(MAIN_MENU_SCENE_PATH, root)
	_assert(main_menu != null, "Main menu instantiates for cross-screen flow")
	if main_menu == null:
		return
	await _wait_frames(2)
	main_menu.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	var route_snapshot: Dictionary = Dictionary(main_menu.call("get_route_snapshot"))
	_assert(String(route_snapshot.get("singleplayer", "")) == SINGLEPLAYER_SCENE_PATH, "Main menu singleplayer route stays wired")
	_assert(String(route_snapshot.get("multiplayer", "")) == MULTIPLAYER_LOBBY_SCENE_PATH, "Main menu multiplayer route stays wired")
	_assert(String(route_snapshot.get("editor", "")) == MAP_EDITOR_SCENE_PATH, "Main menu editor route stays wired")
	for route_path in [SINGLEPLAYER_SCENE_PATH, MULTIPLAYER_LOBBY_SCENE_PATH, MAP_EDITOR_SCENE_PATH]:
		_assert(ResourceLoader.exists(route_path), "Main menu route target exists: %s" % route_path)

	main_menu.call("open_settings_panel")
	await _wait_frames(2)
	var ui_snapshot: Dictionary = Dictionary(main_menu.call("get_settings_ui_snapshot"))
	_assert(bool(ui_snapshot.get("display_section_visible", false)), "Settings Display section opens")
	_assert(bool(ui_snapshot.get("audio_section_visible", false)), "Settings Audio section opens")
	_assert(bool(ui_snapshot.get("gameplay_section_visible", false)), "Settings Gameplay section opens")
	var expected: Dictionary = Dictionary(context.get("settings_expected", {}))
	main_menu.call("set_draft_display_settings", String(expected.get("resolution_preset", "")), String(expected.get("window_mode", "")), false)
	main_menu.call("set_draft_audio_settings", float(expected.get("master_volume", 0.0)), float(expected.get("music_volume", 0.0)), float(expected.get("sfx_volume", 0.0)))
	main_menu.call("set_draft_fog_of_war_mode", String(expected.get("fog_of_war_mode", "")))
	main_menu.call("set_draft_comic_bubble_mode", String(expected.get("comic_bubble_mode", "")))
	_assert(int(main_menu.call("apply_settings")) == OK, "Settings apply persists the cross-screen draft")
	_assert(_settings_match_expected(expected), "Applied settings match the expected persisted values")
	var before_audio: Dictionary = Dictionary(main_menu.call("get_audio_sfx_debug_snapshot")) if main_menu.has_method("get_audio_sfx_debug_snapshot") else {}
	await _wait_frames(5)
	var after_audio: Dictionary = Dictionary(main_menu.call("get_audio_sfx_debug_snapshot")) if main_menu.has_method("get_audio_sfx_debug_snapshot") else {}
	_assert(int(after_audio.get("played_count", 0)) == int(before_audio.get("played_count", 0)), "Main menu idle screen switch does not duplicate UI audio")
	_assert(main_menu.find_child("SimulationRoot", true, false) == null, "Main menu/settings keep gameplay state uncreated")
	main_menu.queue_free()
	await _wait_frames(2)


func _test_homebase_fob_mission_debrief_homebase_state(context: Dictionary) -> void:
	var units: Array = Array(context.get("units", []))
	var selected_unit_ids := PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var selected_fireteam_ids := PackedStringArray(context.get("selected_fireteam_ids", PackedStringArray()))
	var fireteam_definitions: Array = Array(context.get("fireteam_definitions", []))

	var homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(homebase != null, "Homebase instantiates after main menu")
	if homebase == null:
		return
	await _wait_frames(3)
	homebase.call("setup_roster", units, selected_unit_ids)
	homebase.call("set_fireteam_context", selected_fireteam_ids)
	await _wait_frames(2)
	var roster_card := _find_npc_card(homebase, "unit_delta", "roster")
	_assert(roster_card != null and _open_npc_card(roster_card), "Homebase roster card opens before transfer")
	await _wait_frames(2)
	_assert(_labels_contain(_collect_label_texts(homebase), "Darius Holt"), "Homebase character card follows selected roster operator")
	homebase.call("_on_team_drop_panel_unit_dropped", "unit_delta")
	await _wait_frames(2)
	selected_unit_ids = PackedStringArray(homebase.call("get_selected_unit_ids"))
	selected_fireteam_ids = PackedStringArray(["ft1", "ft1", "ft2"])
	fireteam_definitions = [
		_build_fireteam_definition("ft1", "unit_alpha"),
		_build_fireteam_definition("ft2", "unit_delta"),
	]
	_assert(selected_unit_ids.has("unit_delta") and selected_unit_ids.size() == 3, "Homebase transfer adds unit_delta once")
	_assert(_visible_homebase_unit_count(homebase) == units.size(), "Homebase roster plus staged team keep the full unit set visible")
	homebase.queue_free()
	await _wait_frames(2)

	var fob: Node = HARNESS_SCRIPT.instantiate_scene(FOB_SCENE_PATH, root)
	_assert(fob != null, "FOB instantiates after Homebase")
	if fob == null:
		return
	await _wait_frames(3)
	fob.call("set_available_units", units)
	fob.call("configure_transfer", selected_unit_ids, selected_fireteam_ids, fireteam_definitions)
	fob.call("_on_staging_fireteam_dropped", "ft1", "loadout")
	await _wait_frames(2)
	fob.call("_set_member_loadout", "ft1", "unit_alpha", "heavy", "rocket_launcher", "none")
	await _wait_frames(2)
	var fob_defs: Array = Array(fob.call("get_fireteam_definitions"))
	var fob_selected_ids := PackedStringArray(fob.call("get_team"))
	var fob_selected_fireteams := PackedStringArray(fob.call("get_selected_fireteam_ids"))
	_assert(_same_string_array(fob_selected_ids, selected_unit_ids), "FOB keeps selected unit order from Homebase")
	_assert(_same_string_array(fob_selected_fireteams, selected_fireteam_ids), "FOB keeps fireteam assignment order from Homebase")
	fob.call("_open_character_overlay", "unit_alpha")
	await _wait_frames(2)
	var fob_overlay_texts: PackedStringArray = _collect_label_texts(fob.get_node_or_null("CharacterOverlay"))
	_assert(_labels_contain(fob_overlay_texts, "Weight 9.0"), "FOB character overlay keeps Rocket/None weight")
	fob.call("_open_character_overlay", "unit_bravo")
	await _wait_frames(2)
	fob_overlay_texts = _collect_label_texts(fob.get_node_or_null("CharacterOverlay"))
	_assert(_labels_contain(fob_overlay_texts, "Milo Saren"), "FOB character overlay switches to the next operator without stale identity")
	var member_loadouts: Dictionary = _extract_member_loadouts(fob_defs)
	fob.queue_free()
	await _wait_frames(2)

	var mission_scene := ResourceLoader.load(MISSION_SCENE_PATH) as PackedScene
	var mission: Node = mission_scene.instantiate() if mission_scene != null else null
	_assert(mission != null, "Mission scene instantiates after FOB")
	if mission == null:
		return
	_configure_mission_scene(mission, selected_unit_ids, selected_fireteam_ids, fob_defs, member_loadouts)
	root.add_child(mission)
	await _wait_frames(16)
	await _wait_physics_frames(4)
	var registry_ids: PackedStringArray = _get_registry_unit_ids(mission.get_node_or_null("UnitRegistry"))
	_assert(_contains_all(registry_ids, selected_unit_ids), "Mission registry contains all selected Homebase/FOB units")
	var mission_setup := mission.get_node_or_null("MissionSetup")
	var alpha_modifiers: Dictionary = Dictionary(mission_setup.call("get_unit_loadout_modifiers_dict", "unit_alpha")) if mission_setup != null else {}
	_assert(float(alpha_modifiers.get("loadout_weight", 0.0)) == 9.0, "Mission setup receives the FOB Rocket/None loadout weight")
	var primary_view := mission.get_node_or_null("Primary3DView")
	if primary_view != null and primary_view.has_method("get_render_snapshot"):
		var visual_snapshot: Dictionary = Dictionary(primary_view.call("get_render_snapshot"))
		_assert(_contains_all(PackedStringArray(visual_snapshot.get("unit_proxy_ids", PackedStringArray())), selected_unit_ids), "Mission visual proxy snapshot keeps selected unit IDs")
	var mission_result: Dictionary = _build_mission_result(units, selected_unit_ids, selected_fireteam_ids)
	mission.queue_free()
	await _wait_frames(2)

	var progression: Dictionary = Dictionary(MISSION_PROGRESSION_RESOLVER_SCRIPT.call("apply_mission_result", _build_roster_payload(units), mission_result))
	var updated_roster: Dictionary = Dictionary(progression.get("updated_roster", {}))
	var updated_units: Array = Array(updated_roster.get("units", units))
	mission_result["character_events"] = Array(progression.get("character_events", []))
	mission_result["progression_summary"] = Dictionary(progression.get("summary", {}))
	_assert(_same_unordered_strings(PackedStringArray(context.get("initial_unit_id_set", PackedStringArray())), _unit_id_set(updated_units)), "Mission progression keeps the roster ID set intact")

	var debrief: Node = HARNESS_SCRIPT.instantiate_scene(DEBRIEF_SCENE_PATH, root)
	_assert(debrief != null, "Debrief instantiates after mission")
	if debrief != null:
		debrief.call("set_mission_result", mission_result)
		await _wait_frames(2)
		var debrief_labels: PackedStringArray = _collect_label_texts(debrief)
		_assert(_labels_contain(debrief_labels, "Character updates:"), "Debrief shows character progression after mission")
		_assert(_labels_contain(debrief_labels, "Anja Voss"), "Debrief keeps the progressed unit identity visible")
		debrief.queue_free()
		await _wait_frames(2)

	var returned_homebase: Node = HARNESS_SCRIPT.instantiate_scene(HOMEBASE_SCENE_PATH, root)
	_assert(returned_homebase != null, "Homebase reinstantiates after Debrief return")
	if returned_homebase != null:
		returned_homebase.call("setup_roster", updated_units, selected_unit_ids)
		returned_homebase.call("set_fireteam_context", selected_fireteam_ids)
		await _wait_frames(2)
		_assert(PackedStringArray(returned_homebase.call("get_selected_unit_ids")).size() == selected_unit_ids.size(), "Returned Homebase keeps selected team size")
		var staged_card := _find_npc_card(returned_homebase, "unit_alpha", "staged")
		_assert(staged_card != null and _open_npc_card(staged_card), "Returned Homebase character card opens for progressed unit")
		await _wait_frames(2)
		_assert(_labels_contain(_collect_label_texts(returned_homebase), "Anja Voss"), "Returned Homebase card keeps unit identity")
		returned_homebase.queue_free()
		await _wait_frames(2)

	context["selected_unit_ids"] = selected_unit_ids
	context["selected_fireteam_ids"] = selected_fireteam_ids
	context["fireteam_definitions"] = fireteam_definitions
	context["updated_units"] = updated_units


func _test_editor_flow_does_not_touch_app_state(context: Dictionary) -> void:
	var selected_before := PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var settings_expected: Dictionary = Dictionary(context.get("settings_expected", {}))
	var editor: Node = HARNESS_SCRIPT.instantiate_scene(MAP_EDITOR_SCENE_PATH, root)
	_assert(editor != null, "Map editor instantiates for cross-screen flow")
	if editor == null:
		return
	await _wait_frames(12)
	_assert(bool(editor.call("set_authoring_tool", "height")), "Editor height tool remains reachable")
	_assert(bool(editor.call("select_grid_for_authoring", Vector2i(2, 2))), "Editor tile selection works after app flow")
	var map_data = editor.get("_terrain_map_data")
	_assert(map_data != null, "Editor exposes map data for roundtrip")
	if map_data != null:
		var tile = map_data.call("get_tile_at_grid", Vector2i(2, 2))
		if tile != null:
			tile.height_level = 2
			tile.edge_type = TERRAIN_TILE_DATA_SCRIPT.get("EDGE_CLIFF")
			tile.surface_type = TERRAIN_TILE_DATA_SCRIPT.get("SURFACE_SAND")
			tile.object_height = 1
			tile.blocks_los = true
		_assert(map_data.call("save_to_file", TEMP_EDITOR_MAP_PATH) == OK, "Editor-authored map saves")
		var reloaded = TERRAIN_MAP_DATA_SCRIPT.call("load_from_file", TEMP_EDITOR_MAP_PATH)
		var reloaded_tile = reloaded.call("get_tile_at_grid", Vector2i(2, 2)) if reloaded != null else null
		_assert(reloaded_tile != null and int(reloaded_tile.height_level) == 2, "Editor roundtrip preserves authored height")
	var usability: Dictionary = Dictionary(editor.call("get_map_editor_usability_snapshot"))
	_assert(String(usability.get("active_tool", "")) == "height", "Editor usability snapshot keeps active tool")
	_assert(editor.find_child("SimulationRoot", true, false) == null, "Editor authoring flow does not keep gameplay SimulationRoot")
	editor.queue_free()
	await _wait_frames(2)
	_assert(_same_string_array(selected_before, PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))), "Editor flow does not mutate selected unit state")
	_assert(_settings_match_expected(settings_expected), "Editor flow does not mutate persisted settings")


func _test_multiplayer_preparation_roundtrip(context: Dictionary) -> void:
	var selected_before := PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))
	var lobby: Node = HARNESS_SCRIPT.instantiate_scene(MULTIPLAYER_LOBBY_SCENE_PATH, root)
	_assert(lobby != null, "Multiplayer lobby instantiates after editor flow")
	if lobby == null:
		return
	await _wait_frames(2)
	lobby.call("set_settings_path_for_tests", TEMP_SETTINGS_PATH)
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(bool(ui_snapshot.get("host_controls_visible", false)), "Lobby exposes host controls")
	_assert(bool(ui_snapshot.get("join_controls_visible", false)), "Lobby exposes join controls")
	_assert(String(ui_snapshot.get("settings_text", "")).contains("unexplored_blackout"), "Lobby reads persisted FoW setting")
	var idle_audio: Dictionary = Dictionary(ui_snapshot.get("audio_sfx", {}))
	await _wait_frames(4)
	var still_idle_audio: Dictionary = Dictionary(lobby.call("get_audio_sfx_debug_snapshot")) if lobby.has_method("get_audio_sfx_debug_snapshot") else {}
	_assert(int(still_idle_audio.get("played_count", 0)) == int(idle_audio.get("played_count", 0)), "Lobby idle state does not duplicate audio events")
	lobby.call("configure_host_state_for_test", [1, 2])
	lobby.call("set_peer_ready_for_test", 1, true)
	lobby.call("set_peer_ready_for_test", 2, true)
	await _wait_frames(2)
	_assert(bool(lobby.call("start_mission")), "Host-ready multiplayer preparation can request one mission start")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(int(ui_snapshot.get("mission_start_request_count", 0)) == 1, "Multiplayer preparation records exactly one mission start request")
	lobby.call("configure_client_state_for_test", [1, 2])
	await _wait_frames(1)
	_assert(not bool(lobby.call("start_mission")), "Client preparation cannot start mission directly")
	lobby.call("disconnect_game")
	await _wait_frames(1)
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(String(Dictionary(ui_snapshot.get("session", {})).get("connection_state", "")) == "idle", "Disconnect returns multiplayer lobby to idle")
	_assert(lobby.find_child("SimulationRoot", true, false) == null, "Multiplayer preparation does not create gameplay SimulationRoot")
	lobby.queue_free()
	await _wait_frames(2)
	_assert(_same_string_array(selected_before, PackedStringArray(context.get("selected_unit_ids", PackedStringArray()))), "Multiplayer preparation does not mutate selected unit state")
	_assert(_settings_match_expected(Dictionary(context.get("settings_expected", {}))), "Multiplayer preparation keeps persisted settings")


func _test_report_exists() -> void:
	_assert(FileAccess.file_exists(REPORT_PATH), "Cross-screen state-loss report exists")
	var report_text: String = _read_text(REPORT_PATH)
	for required_text in ["Summary", "Main Flow", "Editor Flow", "Multiplayer Preparation", "State Invariants", "Open Items"]:
		_assert(report_text.contains(required_text), "Cross-screen report covers %s" % required_text)


func _configure_mission_scene(mission: Node, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray, fireteam_definitions: Array, member_loadouts: Dictionary) -> void:
	var mission_setup := mission.get_node_or_null("MissionSetup")
	if mission_setup == null:
		return
	mission_setup.set("selected_team_unit_ids", selected_unit_ids)
	mission_setup.set("selected_team_fireteam_ids", selected_fireteam_ids)
	mission_setup.set("selected_fireteam_definitions", fireteam_definitions)
	mission_setup.set("member_loadouts", member_loadouts)
	mission_setup.set("defer_friendly_runtime_activation", false)
	mission_setup.set("allow_full_roster_when_selection_empty", false)


func _build_mission_result(units: Array, selected_unit_ids: PackedStringArray, selected_fireteam_ids: PackedStringArray) -> Dictionary:
	var team_states: Array = []
	for index in range(selected_unit_ids.size()):
		var unit_id: String = String(selected_unit_ids[index])
		var unit: Dictionary = _find_unit(units, unit_id)
		team_states.append({
			"unit_id": unit_id,
			"display_name": String(unit.get("display_name", unit_id)),
			"fireteam_id": String(selected_fireteam_ids[index]) if index < selected_fireteam_ids.size() else "",
			"vital_state": "fit",
			"health_points": 100,
		})
	return {
		"mission_id": "task_261_cross_screen",
		"winning_team_id": "team_alpha",
		"mission_outcome": "success",
		"result": "success",
		"win_condition_type": "smoke",
		"objective_captured": true,
		"duration_seconds": 12.0,
		"selected_unit_ids": selected_unit_ids.duplicate(),
		"selected_fireteam_ids": selected_fireteam_ids.duplicate(),
		"team_states": team_states,
	}


func _build_roster_payload(units: Array) -> Dictionary:
	return {
		"schema_version": 1,
		"generator_id": "task_261_cross_screen_fixture",
		"seed": "unit_roster_presets",
		"player_profile_id": "task_261_cross_screen",
		"units": units.duplicate(true),
		"roster_size": units.size(),
		"relationship_pairs": [],
		"fireteam_suggestions": [],
		"multiplayer_boundary": {"ownership_scope": "test_fixture"},
	}


func _extract_member_loadouts(fireteam_definitions: Array) -> Dictionary:
	var result: Dictionary = {}
	for definition_variant in fireteam_definitions:
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var member_loadouts: Dictionary = Dictionary(definition.get("member_loadouts", {}))
		for unit_id_variant in member_loadouts.keys():
			result[String(unit_id_variant)] = Dictionary(member_loadouts.get(unit_id_variant, {})).duplicate(true)
	return result


func _build_fireteam_definition(fireteam_id: String, lead_unit_id: String) -> Dictionary:
	return {
		"id": fireteam_id,
		"label": fireteam_id.to_upper(),
		"lead_unit_id": lead_unit_id,
		"loadout": "medium",
		"respawn_enabled": false,
	}


func _visible_homebase_unit_count(homebase: Node) -> int:
	var roster_list := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/RosterPanel/RosterMargin/RosterVBox/RosterScroll/RosterList") as VBoxContainer
	var team_list := homebase.get_node_or_null("Panel/Margin/VBox/ContentRow/TeamPanel/TeamMargin/TeamVBox/TeamDropPanel/DropMargin/DropVBox/SelectedTeamScroll/SelectedTeamList") as VBoxContainer
	if roster_list == null or team_list == null:
		return -1
	return roster_list.get_child_count() + team_list.get_child_count()


func _open_npc_card(card: Node) -> bool:
	if card == null or not card.has_signal("card_open_requested") or not card.has_method("get_unit_id") or not card.has_method("get_profile"):
		return false
	if not bool(HARNESS_SCRIPT.call("has_signal_connection", card, "card_open_requested")):
		return false
	var unit_id: String = String(card.call("get_unit_id"))
	var source_context: String = String(card.call("get_source_context")) if card.has_method("get_source_context") else ""
	card.emit_signal("card_open_requested", unit_id, card.call("get_profile"), source_context)
	return true


func _find_npc_card(root_node: Node, unit_id: String, source_context: String = "") -> Node:
	for node in _collect_nodes(root_node):
		if not node.has_method("get_unit_id"):
			continue
		if String(node.call("get_unit_id")) != unit_id:
			continue
		if not source_context.is_empty() and (not node.has_method("get_source_context") or String(node.call("get_source_context")) != source_context):
			continue
		return node
	return null


func _collect_nodes(node: Node) -> Array:
	var result: Array = []
	if node == null:
		return result
	result.append(node)
	for child in node.get_children():
		result.append_array(_collect_nodes(child))
	return result


func _collect_label_texts(node: Node) -> PackedStringArray:
	var result := PackedStringArray()
	if node == null:
		return result
	if node is Label:
		var text: String = String((node as Label).text).strip_edges()
		if not text.is_empty():
			result.append(text)
	for child in node.get_children():
		result.append_array(_collect_label_texts(child))
	return result


func _labels_contain(labels: PackedStringArray, needle: String) -> bool:
	for label in labels:
		if String(label).contains(needle):
			return true
	return false


func _get_registry_unit_ids(registry: Node) -> PackedStringArray:
	var result := PackedStringArray()
	if registry == null or not registry.has_method("get_all_units"):
		return result
	for unit in Array(registry.call("get_all_units")):
		if unit != null and unit.has_method("get_unit_id"):
			var unit_id: String = String(unit.call("get_unit_id")).strip_edges()
			if not unit_id.is_empty():
				result.append(unit_id)
	result.sort()
	return result


func _contains_all(haystack: PackedStringArray, needles: PackedStringArray) -> bool:
	for needle in needles:
		if not haystack.has(String(needle)):
			return false
	return true


func _unit_id_set(units: Array) -> PackedStringArray:
	var ids := PackedStringArray()
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit_id: String = String(Dictionary(unit_variant).get("unit_id", "")).strip_edges()
		if not unit_id.is_empty() and not ids.has(unit_id):
			ids.append(unit_id)
	ids.sort()
	return ids


func _find_unit(units: Array, unit_id: String) -> Dictionary:
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges() == unit_id:
			return unit
	return {}


func _same_string_array(a: PackedStringArray, b: PackedStringArray) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if String(a[index]) != String(b[index]):
			return false
	return true


func _same_unordered_strings(a: PackedStringArray, b: PackedStringArray) -> bool:
	var left := PackedStringArray(a)
	var right := PackedStringArray(b)
	left.sort()
	right.sort()
	return _same_string_array(left, right)


func _settings_match_expected(expected: Dictionary) -> bool:
	var gameplay_loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	var bubble_loaded: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("load_settings", TEMP_SETTINGS_PATH))
	return String(gameplay_loaded.get("resolution_preset", "")) == String(expected.get("resolution_preset", "")) \
		and String(gameplay_loaded.get("window_mode", "")) == String(expected.get("window_mode", "")) \
		and String(gameplay_loaded.get("fog_of_war_mode", "")) == String(expected.get("fog_of_war_mode", "")) \
		and String(bubble_loaded.get("mode", "")) == String(expected.get("comic_bubble_mode", "")) \
		and is_equal_approx(float(gameplay_loaded.get("master_volume", 0.0)), float(expected.get("master_volume", 0.0))) \
		and is_equal_approx(float(gameplay_loaded.get("music_volume", 0.0)), float(expected.get("music_volume", 0.0))) \
		and is_equal_approx(float(gameplay_loaded.get("sfx_volume", 0.0)), float(expected.get("sfx_volume", 0.0)))


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _wait_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await process_frame


func _wait_physics_frames(frame_count: int) -> void:
	for _index in range(frame_count):
		await physics_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
