extends SceneTree

const ISOLATION_GUARD: GDScript = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const LOBBY_SCENE: PackedScene = preload("res://scenes/ui/multiplayer_lobby.tscn")
const MAP_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const TERRAIN_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const FIRST_PATH: String = "user://review7_lobby_first_map.json"
const SECOND_PATH: String = "user://review7_lobby_second_map.json"
const PORT_START: int = 19810
const PORT_END: int = 19820

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not ISOLATION_GUARD.require_isolated_user_data():
		return
	call_deferred("_run_tests")


func _run_tests() -> void:
	_write_map(FIRST_PATH, "review7_lobby_first_map")
	_write_map(SECOND_PATH, "review7_lobby_second_map")
	var first_manifest: Dictionary = Dictionary(MAP_SCRIPT.call("build_manifest_for_map", FIRST_PATH))
	var second_manifest: Dictionary = Dictionary(MAP_SCRIPT.call("build_manifest_for_map", SECOND_PATH))
	var fixture: Dictionary = await _create_lobby_pair(first_manifest)
	_assert(bool(fixture.get("connected", false)), "Real product lobbies connect over ENet for map consent")
	if not bool(fixture.get("connected", false)):
		_finish()
		return
	var host: Node = fixture["host"]
	var client: Node = fixture["client"]
	var host_session: Node = host.get_node("MultiplayerSession")
	var client_session: Node = client.get_node("MultiplayerSession")
	var host_api: MultiplayerAPI = fixture["host_api"]
	var client_api: MultiplayerAPI = fixture["client_api"]
	var first_ui: Dictionary = Dictionary(client.call("get_lobby_ui_snapshot"))
	_assert(bool(first_ui.get("map_consent_visible", false)) and String(first_ui.get("map_consent_text", "")).contains("review7_lobby_first_map"), "Incoming host snapshot opens a consent prompt naming the current offered map")
	_assert(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://downloaded_maps")), "Receiving an unknown map manifest never downloads or writes a cache")
	_assert(bool(first_ui.get("ready_disabled", false)), "Unknown map keeps client Ready disabled until explicit consent")
	var reject_button: Button = client.get_node("Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentRow/MapRejectButton")
	reject_button.pressed.emit()
	await _poll_pair(host_api, client_api, 10)
	var rejected_ui: Dictionary = Dictionary(client.call("get_lobby_ui_snapshot"))
	_assert(String(Dictionary(rejected_ui.get("map_consent_state", {})).get("state", "")) == "rejected" and not bool(rejected_ui.get("map_consent_visible", true)), "Real Reject button rejects the network offer and closes the prompt")
	_assert(not bool(client.call("has_active_mission")) and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://downloaded_maps")), "Rejected network offer creates neither mission nor downloaded files")
	host_session.call("set_local_ready", false)
	await _poll_pair(host_api, client_api, 10)
	_assert(not bool(Dictionary(client.call("get_lobby_ui_snapshot")).get("map_consent_visible", true)), "Repeated snapshot does not reopen a rejected current offer")
	host_session.call("set_lobby_player_setup", {"map_path": SECOND_PATH})
	host_session.call("set_host_map_manifest", second_manifest)
	host_session.call("set_local_ready", false)
	await _poll_pair(host_api, client_api, 25)
	var replacement_ui: Dictionary = Dictionary(client.call("get_lobby_ui_snapshot"))
	_assert(bool(replacement_ui.get("map_consent_visible", false)) and String(replacement_ui.get("map_consent_text", "")).contains("review7_lobby_second_map"), "Replacement host offer opens a fresh prompt for B after rejecting A")
	var accept_button: Button = client.get_node("Panel/Margin/VBox/MapConsentPanel/Margin/VBox/MapConsentRow/MapAcceptButton")
	accept_button.pressed.emit()
	await _poll_pair(host_api, client_api, 10)
	_assert(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://downloaded_maps")), "V1 Accept button waits for an explicit payload and never downloads automatically")
	# TASK228 explicitly leaves network payload transport outside V1; use its existing payload API.
	client.call("accept_pending_map_download", FileAccess.get_file_as_string(SECOND_PATH))
	var accepted_snapshot: Dictionary = Dictionary(client_session.call("get_session_snapshot"))
	var transfer: Dictionary = Dictionary(accepted_snapshot.get("map_transfer", {}))
	var cache_path: String = String(transfer.get("cache_path", ""))
	var accepted: bool = String(transfer.get("state", "")) == "accepted" and bool(transfer.get("can_start_client", false))
	_assert(accepted, "Existing explicit payload API accepts the current network offer after consent")
	_assert(cache_path.begins_with("user://downloaded_maps/") and FileAccess.file_exists(cache_path), "Consented network map is cached only under the client download root")
	if not cache_path.is_empty() and FileAccess.file_exists(cache_path):
		_assert(FileAccess.get_file_as_string(cache_path).sha256_text() == String(second_manifest.get("map_hash", "")), "Received map cache contains exactly the current host B payload")
	_assert(not bool(Dictionary(client.call("get_lobby_ui_snapshot")).get("map_consent_visible", true)), "Successful explicit acceptance closes the current network prompt")
	if accepted:
		_assert(bool(host.call("set_ready", true)) and bool(client.call("set_ready", true)), "Both peers can Ready normally after map acceptance")
		await _poll_pair(host_api, client_api, 20)
		_assert(bool(host.call("start_mission")), "Host starts the consented map through normal product Start")
		await _poll_pair(host_api, client_api, 25)
		_assert(bool(host.call("has_active_mission")) and bool(client.call("has_active_mission")), "Consented host and client instantiate their real mission scenes")
		_assert_loaded_map(host, SECOND_PATH, "Host")
		_assert_loaded_map(client, cache_path, "Client")
	await _cleanup_pair(fixture)
	await _test_known_map_mission(first_manifest)
	_finish()


func _test_known_map_mission(manifest: Dictionary) -> void:
	var fixture: Dictionary = await _create_lobby_pair(manifest, true)
	_assert(bool(fixture.get("connected", false)), "Known-map product lobbies connect over ENet without a download")
	if not bool(fixture.get("connected", false)):
		return
	var host: Node = fixture["host"]
	var client: Node = fixture["client"]
	var host_api: MultiplayerAPI = fixture["host_api"]
	var client_api: MultiplayerAPI = fixture["client_api"]
	_assert(not bool(Dictionary(client.call("get_lobby_ui_snapshot")).get("map_consent_visible", true)), "Known matching local map needs no consent prompt")
	_assert(bool(host.call("set_ready", true)) and bool(client.call("set_ready", true)), "Known-map peers submit normal Ready commands")
	await _poll_pair(host_api, client_api, 20)
	_assert(bool(host.call("start_mission")), "Known-map host starts normally")
	await _poll_pair(host_api, client_api, 25)
	_assert_loaded_map(host, FIRST_PATH, "Known Host", "review7_lobby_first_map")
	_assert_loaded_map(client, FIRST_PATH, "Known Client", "review7_lobby_first_map")
	await _cleanup_pair(fixture)


func _assert_loaded_map(lobby: Node, expected_path: String, label: String, expected_name: String = "review7_lobby_second_map") -> void:
	var mission: Node = lobby.get("_active_mission")
	if mission == null:
		_assert(false, "%s mission loads the current consented 3x3 map" % label)
		return
	var setup: Node = mission.get_node("MissionSetup")
	_assert(String(setup.get("map_file_path")) == expected_path, "%s MissionSetup uses its host-selected or locally verified map path" % label)
	var data = setup.get("_loaded_terrain_map_data")
	_assert(data != null and Vector2i(data.call("get_grid_size")) == Vector2i(3, 3) and String(data.call("get_map_name")) == expected_name, "%s actually loaded current offered terrain instead of the default map" % label)
	_assert(int(mission.get_node("TerrainRegistry").call("get_tile_count")) == 9, "%s runtime terrain registry contains exactly the nine consented map cells" % label)


func _write_map(path: String, map_name: String) -> void:
	var data = TERRAIN_SCRIPT.call("create_empty", map_name, Vector2i(3, 3), Vector2.ZERO, 64.0, 32.0, 3)
	_assert(data.call("save_to_file", path) == OK, "3x3 map fixture saves under isolated user data")


func _create_lobby_pair(manifest: Dictionary, client_knows_map: bool = false) -> Dictionary:
	for port in range(PORT_START, PORT_END + 1):
		var host_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var client_api: MultiplayerAPI = MultiplayerAPI.create_default_interface()
		var host_root := Node.new()
		var client_root := Node.new()
		host_root.name = "Review7MapHost"
		client_root.name = "Review7MapClient"
		root.add_child(host_root)
		root.add_child(client_root)
		set_multiplayer(host_api, host_root.get_path())
		set_multiplayer(client_api, client_root.get_path())
		var host: Node = LOBBY_SCENE.instantiate()
		var client: Node = LOBBY_SCENE.instantiate()
		host.name = "Lobby"
		client.name = "Lobby"
		host_root.add_child(host)
		client_root.add_child(client)
		await process_frame
		var fixture: Dictionary = {"host_api": host_api, "client_api": client_api, "host_root": host_root, "client_root": client_root, "host": host, "client": client, "port": port}
		if not bool(host.call("host_game", port)):
			await _cleanup_pair(fixture)
			continue
		var host_session: Node = host.get_node("MultiplayerSession")
		host_session.call("set_lobby_player_setup", {"map_path": FIRST_PATH})
		host_session.call("set_host_map_manifest", manifest)
		if not bool(client.call("join_game", "127.0.0.1", port)):
			await _cleanup_pair(fixture)
			continue
		if client_knows_map:
			client.get_node("MultiplayerSession").call("set_lobby_player_setup", {"map_path": FIRST_PATH})
		for _index in range(180):
			await _poll_pair(host_api, client_api, 1)
			var client_snapshot: Dictionary = Dictionary(client.call("get_session_snapshot"))
			var expected_state: String = "known" if client_knows_map else "missing"
			if int(Dictionary(host.call("get_session_snapshot")).get("connected_count", 0)) == 2 and String(Dictionary(client_snapshot.get("map_transfer", {})).get("state", "")) == expected_state:
				fixture["connected"] = true
				return fixture
		await _cleanup_pair(fixture)
	return {"connected": false}


func _poll_pair(host_api: MultiplayerAPI, client_api: MultiplayerAPI, frames: int) -> void:
	for _index in range(frames):
		host_api.poll()
		client_api.poll()
		await create_timer(0.01).timeout


func _cleanup_pair(fixture: Dictionary) -> void:
	var host: Node = fixture.get("host", null)
	var client: Node = fixture.get("client", null)
	if host != null:
		host.call("disconnect_game")
	if client != null:
		client.call("disconnect_game")
	var host_root: Node = fixture.get("host_root", null)
	var client_root: Node = fixture.get("client_root", null)
	if host_root != null:
		host_root.queue_free()
	if client_root != null:
		client_root.queue_free()
	await process_frame


func _finish() -> void:
	print("=== REVIEW7 LOBBY MAP RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW7_LOBBY_MAP_ALL_PASSED")
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
