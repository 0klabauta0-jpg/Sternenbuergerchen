extends SceneTree

const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const TERRAIN_TILE_CATALOG_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_catalog.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const TERRAIN_MAP_3D_VIEW_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== BUGFIX Multiplayer Lobby Setup and Asset Catalog Followup ===")
	await _test_lobby_exposes_player_roster_map_team_and_direct_ip_hint()
	_test_imported_kit_assets_are_sorted_into_existing_palette_groups()
	await _test_station_and_nature_floors_render_as_flush_ground_surfaces()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_lobby_exposes_player_roster_map_team_and_direct_ip_hint() -> void:
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate()
	root.add_child(lobby)
	await _wait_frames(3)
	var initial_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(String(initial_snapshot.get("roster_mode_selected", "")) == "player_rosters", "Multiplayer defaults to each player's local roster")
	var initial_session: Dictionary = Dictionary(initial_snapshot.get("session", {}))
	var initial_assignments: Dictionary = Dictionary(initial_session.get("assignments", {}))
	_assert(String(initial_assignments.get("roster_mode", "")) == "player_rosters", "Session assignment default uses player rosters")
	lobby.call("set_player_name_for_tests", "Sternenbuerger Test")
	lobby.call("set_player_team_for_tests", "team_bravo")
	lobby.call("set_team_play_mode_for_tests", "versus")
	lobby.call("set_lobby_map_for_tests", "res://maps/Ground_Mission01_32x32.json")
	lobby.call("set_connection_mode_for_tests", "direct_wan")
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var setup: Dictionary = Dictionary(ui_snapshot.get("setup", {}))
	_assert(String(setup.get("player_name", "")) == "Sternenbuerger Test", "Lobby setup stores player name")
	_assert(String(setup.get("team_slot", "")) == "team_bravo", "Lobby setup stores selected team side")
	_assert(String(setup.get("team_play_mode", "")) == "versus", "Lobby setup stores team mode")
	_assert(String(setup.get("map_path", "")).ends_with("Ground_Mission01_32x32.json"), "Lobby setup stores selected map")
	_assert(String(setup.get("connection_mode", "")) == "direct_wan", "Lobby setup stores direct internet mode")
	_assert(String(ui_snapshot.get("network_hint_text", "")).contains("UDP-Port"), "Direct IP hint explains UDP port forwarding")
	lobby.call("set_connection_mode_for_tests", "upnp")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	setup = Dictionary(ui_snapshot.get("setup", {}))
	_assert(String(setup.get("connection_mode", "")) == "upnp", "Lobby setup exposes UPnP internet mode")
	_assert(String(ui_snapshot.get("network_hint_text", "")).contains("UPnP"), "UPnP hint explains automatic router port mapping")
	var session: Dictionary = Dictionary(ui_snapshot.get("session", {}))
	var session_setup: Dictionary = Dictionary(session.get("lobby_setup", {}))
	_assert(String(session_setup.get("player_name", "")) == "Sternenbuerger Test", "Session snapshot receives lobby setup")
	lobby.call("configure_host_state_for_test", [1, 2])
	await _wait_frames(2)
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(String(ui_snapshot.get("peer_text", "")).contains("Sternenbuerger Test"), "Peer list shows configured player name")
	_assert(String(ui_snapshot.get("assignment_text", "")).contains("versus"), "Assignments expose team mode")
	lobby.queue_free()
	await _wait_frames(2)


func _test_imported_kit_assets_are_sorted_into_existing_palette_groups() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	_assert(catalog != null, "Terrain tile catalog loads")
	if catalog == null:
		return
	_assert(String(Dictionary(catalog.call("get_type", "modular_wall")).get("palette_group", "")) == "waende", "Modular wall is sorted into Waende")
	_assert(String(Dictionary(catalog.call("get_type", "station_set_wall")).get("palette_group", "")) == "waende", "Station-set wall is sorted into Waende")
	_assert(String(Dictionary(catalog.call("get_type", "spacekit_crater")).get("palette_group", "")) == "crater", "Space Kit crater is sorted into Crater")
	_assert(String(Dictionary(catalog.call("get_type", "spacekit_meteor")).get("palette_group", "")) == "felsen", "Space Kit meteor is sorted into Felsen")
	var floor_entry: Dictionary = Dictionary(catalog.call("get_type", "station_set_floor_panel"))
	_assert(String(floor_entry.get("palette_group", "")) == "space_station", "Station set floor is sorted into Space Station")
	_assert(String(floor_entry.get("placement_layer", "")) == "terrain", "Station set floor paints as terrain")
	_assert(bool(floor_entry.get("visual_surface_variant", false)), "Station set floor is a visual surface variant")


func _test_station_and_nature_floors_render_as_flush_ground_surfaces() -> void:
	var catalog = TERRAIN_TILE_CATALOG_SCRIPT.call("load_from_file")
	var map_data = TERRAIN_MAP_DATA_SCRIPT.call("create_empty", "bugfix_floor_flush_followup", Vector2i(3, 1), Vector2.ZERO)
	var station_tile = map_data.call("get_tile_at_grid", Vector2i(0, 0))
	var nature_tile = map_data.call("get_tile_at_grid", Vector2i(1, 0))
	var station_set_tile = map_data.call("get_tile_at_grid", Vector2i(2, 0))
	_assert(catalog.call("apply_type_to_tile", station_tile, "station_floor_panel"), "Station floor can be painted")
	_assert(catalog.call("apply_type_to_tile", nature_tile, "nature_ground_dirt"), "Nature ground can be painted")
	_assert(catalog.call("apply_type_to_tile", station_set_tile, "station_set_floor_panel"), "Station-set floor can be painted")
	var view: Node = TERRAIN_MAP_3D_VIEW_SCRIPT.new()
	root.add_child(view)
	view.call("configure_from_map", map_data)
	await _wait_frames(10)
	var snapshot: Dictionary = Dictionary(view.call("get_render_snapshot"))
	var entries: Array = Array(snapshot.get("surface_visual_entries", []))
	_assert(int(snapshot.get("surface_detail_visual_count", -1)) == 0, "Nature and station floors do not stack raised detail surfaces")
	_assert(_entry_top_is_not_above_surface(entries, "station_floor_panel"), "Station floor top is not above gameplay floor")
	_assert(_entry_top_is_not_above_surface(entries, "nature_ground_dirt"), "Nature ground top is not above gameplay floor")
	_assert(_entry_top_is_not_above_surface(entries, "station_set_floor_panel"), "Station-set floor top is not above gameplay floor")
	view.queue_free()
	await _wait_frames(2)


func _entry_top_is_not_above_surface(entries: Array, model_key: String) -> bool:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("model_key", "")) != model_key:
			continue
		return float(entry.get("visual_top_y", 999.0)) <= float(entry.get("surface_y", 0.0)) + 0.002
	return false


func _wait_frames(count: int) -> void:
	for _index in range(count):
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
