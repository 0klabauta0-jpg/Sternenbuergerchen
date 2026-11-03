extends SceneTree

const ISOLATION_GUARD: GDScript = preload("res://scripts/tests/review2_isolated_user_guard.gd")
const SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const MAP_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const TERRAIN_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MAP_PATH: String = "user://review7_session_map.json"
const CACHE_ROOT: String = "user://review7_session_downloads"
const ASSIGNMENTS: Dictionary = {"peer_teams": {1: "team_alpha", 2: "team_bravo"}, "peer_roles": {1: "host", 2: "commander"}, "peer_fireteams": {1: ["blue", "gold"], 2: ["red"]}}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	if not ISOLATION_GUARD.require_isolated_user_data():
		return
	call_deferred("_run_tests")


func _run_tests() -> void:
	var map_data = TERRAIN_SCRIPT.call("create_empty", "review7_session_map", Vector2i(3, 3), Vector2.ZERO, 64.0, 32.0, 3)
	_assert(map_data.call("save_to_file", MAP_PATH) == OK, "Map fixture saves only in isolated user data")
	var map_text: String = FileAccess.get_file_as_string(MAP_PATH)
	var manifest: Dictionary = Dictionary(MAP_SCRIPT.call("build_manifest_for_map", MAP_PATH))
	_assert(bool(manifest.get("valid", false)), "Map fixture has a valid manifest")
	await _test_empty_compatibility()
	await _test_missing_and_rejected(manifest)
	await _test_invalid_manifest(manifest)
	await _test_accepted_and_replacement(manifest, map_text)
	await _test_stale_offer_actions(manifest, map_text)
	await _test_local_host_setter_cannot_replace_offer(manifest)
	await _test_known_map(manifest)
	print("=== REVIEW7 SESSION MAP RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW7_SESSION_MAP_ALL_PASSED")
	quit(1 if _failed > 0 else 0)


func _test_empty_compatibility() -> void:
	var client: Node = _make_client()
	var starts: Array = _capture_starts(client)
	client.call("_receive_session_snapshot", _snapshot({}))
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.size() == 1 and _mission_started(client), "Sessions without editor-map manifests retain mission start compatibility")
	client.queue_free()
	await process_frame


func _test_missing_and_rejected(manifest: Dictionary) -> void:
	var client: Node = _make_client()
	var starts: Array = _capture_starts(client)
	client.call("_receive_session_snapshot", _snapshot(manifest))
	_assert(_transfer_state(client) == "missing", "Incoming host manifest is checked against local maps")
	_assert(not _can_start_client(client), "Missing map requires local consent even if host publishes an allowed transfer state")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.is_empty() and not _mission_started(client), "Missing map blocks the incoming mission-start RPC")
	client.call("reject_map_download", manifest)
	client.call("_receive_session_snapshot", _snapshot(manifest, true))
	_assert(_transfer_state(client) == "rejected" and not _can_start_client(client), "Repeated host manifest preserves the client's rejection")
	_assert(not _mission_started(client), "Host mission snapshot cannot bypass client rejection")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.is_empty() and not _mission_started(client), "Rejected download leaves client in lobby without start events")
	_assert(String(Dictionary(client.call("get_session_snapshot")).get("connection_state", "")) == "joined", "Blocked mission remains a joined lobby session")
	client.queue_free()
	await process_frame


func _test_invalid_manifest(manifest: Dictionary) -> void:
	for invalid in [manifest.merged({"map_id": "../review7_session_map"}, true), manifest.merged({"map_hash": "wrong"}, true), {"map_manifest_is_malformed": true}]:
		var client: Node = _make_client()
		var starts: Array = _capture_starts(client)
		client.call("_receive_session_snapshot", _snapshot(invalid, true))
		_assert(_transfer_state(client) == "invalid_manifest" and not _can_start_client(client), "Malformed or unsafe inbound manifest is rejected before normalization")
		client.call("_receive_start_mission", ASSIGNMENTS)
		_assert(starts.is_empty() and not _mission_started(client), "Invalid manifest never starts a client mission")
		client.queue_free()
		await process_frame


func _test_accepted_and_replacement(manifest: Dictionary, map_text: String) -> void:
	var client: Node = _make_client()
	var starts: Array = _capture_starts(client)
	client.call("_receive_session_snapshot", _snapshot(manifest))
	var accepted: Dictionary = Dictionary(client.call("accept_map_download", manifest, map_text, CACHE_ROOT))
	_assert(bool(accepted.get("accepted", false)) and FileAccess.file_exists(String(accepted.get("cache_path", ""))), "Explicit download acceptance validates and caches the map")
	client.call("_receive_session_snapshot", _snapshot(manifest))
	_assert(_transfer_state(client) == "accepted" and _can_start_client(client), "Duplicate incoming manifest retains accepted consent")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.size() == 1 and _mission_started(client), "Accepted map allows the mission-start RPC")
	client.call("complete_mission")
	var replacement: Dictionary = manifest.merged({"map_hash": "b".repeat(64)}, true)
	client.call("_receive_session_snapshot", _snapshot(replacement, true))
	_assert(not _can_start_client(client), "Host replacement hash invalidates approval for the previous map")
	_assert(String(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_manifest", {})).get("map_hash", "")) == "b".repeat(64), "Client records the replacement manifest as the active offer")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.size() == 1 and not _mission_started(client), "Previous acceptance cannot start a replaced map")
	client.call("reject_map_download", replacement)
	client.call("_receive_session_snapshot", _snapshot(replacement))
	_assert(_transfer_state(client) == "rejected", "Duplicate replacement manifest preserves its rejection")
	client.queue_free()
	await process_frame


func _test_known_map(manifest: Dictionary) -> void:
	var client: Node = _make_client()
	var starts: Array = _capture_starts(client)
	client.call("set_lobby_player_setup", {"map_path": MAP_PATH})
	client.call("_receive_session_snapshot", _snapshot(manifest))
	_assert(_transfer_state(client) == "known" and _can_start_client(client), "Incoming manifest recognizes the client's selected local map with matching hash")
	client.call("_receive_session_snapshot", _snapshot(manifest))
	_assert(_transfer_state(client) == "known" and _can_start_client(client), "Duplicate known manifest stays ready without a new prompt")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.size() == 1 and _mission_started(client), "Known map starts without download consent")
	client.call("complete_mission")
	var replacement: Dictionary = manifest.merged({"map_hash": "c".repeat(64)}, true)
	client.call("_receive_session_snapshot", _snapshot(replacement))
	_assert(_transfer_state(client) == "hash_mismatch" and not _can_start_client(client), "Same local map ID with changed host content requires fresh consent")
	client.queue_free()
	await process_frame


func _test_stale_offer_actions(manifest: Dictionary, map_text: String) -> void:
	var client: Node = _make_client()
	var starts: Array = _capture_starts(client)
	client.call("_receive_session_snapshot", _snapshot(manifest))
	client.call("accept_map_download", manifest, map_text, CACHE_ROOT)
	var replacement: Dictionary = manifest.merged({"map_hash": "d".repeat(64)}, true)
	client.call("_receive_session_snapshot", _snapshot(replacement))
	var stale_cache_root: String = "user://review7_stale_downloads"
	var stale_result: Dictionary = Dictionary(client.call("accept_map_download", manifest, map_text, stale_cache_root))
	_assert(not bool(stale_result.get("accepted", true)), "Delayed acceptance for old offer A is refused after host selects B")
	_assert(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(stale_cache_root)), "Stale acceptance does not create a download directory or write the old payload")
	_assert(String(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_manifest", {})).get("map_hash", "")) == "d".repeat(64) and not _can_start_client(client), "Stale acceptance cannot replace active B or authorize its mission")
	client.call("reject_map_download", manifest)
	_assert(String(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_manifest", {})).get("map_hash", "")) == "d".repeat(64) and _transfer_state(client) == "hash_mismatch", "Delayed rejection for A leaves B's pending mismatch state unchanged")
	client.call("reject_map_download", replacement)
	client.call("evaluate_client_map_manifest", manifest, [MAP_PATH])
	_assert(String(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_manifest", {})).get("map_hash", "")) == "d".repeat(64) and _transfer_state(client) == "rejected" and not _can_start_client(client), "Delayed local evaluation of known A cannot replace or reset rejected B")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.is_empty() and not _mission_started(client), "Stale local actions never authorize a mission for the current host offer")
	client.queue_free()
	await process_frame


func _test_local_host_setter_cannot_replace_offer(manifest: Dictionary) -> void:
	var client: Node = _make_client()
	var starts: Array = _capture_starts(client)
	var replacement: Dictionary = manifest.merged({"map_hash": "e".repeat(64)}, true)
	client.call("_receive_session_snapshot", _snapshot(replacement))
	client.call("set_host_map_manifest", manifest)
	_assert(String(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_manifest", {})).get("map_hash", "")) == "e".repeat(64) and not _can_start_client(client), "Client setup host-setter cannot overwrite the authoritative offer with a local map")
	client.call("set_host_map_manifest", replacement)
	_assert(not _can_start_client(client), "Client host-setter cannot authorize the current unknown host map without consent")
	client.call("_receive_start_mission", ASSIGNMENTS)
	_assert(starts.is_empty() and not _mission_started(client), "Local setup host-setter cannot bypass client mission consent")
	client.queue_free()
	await process_frame


func _make_client() -> Node:
	var client: Node = SESSION_SCRIPT.new()
	root.add_child(client)
	client.call("configure_client_state_for_test", [1, 2])
	return client


func _capture_starts(client: Node) -> Array:
	var starts: Array = []
	client.connect("mission_start_requested", func(assignments: Dictionary) -> void: starts.append(assignments.duplicate(true)))
	return starts


func _snapshot(manifest: Dictionary, running: bool = false) -> Dictionary:
	return {"mission_started": running, "map_manifest": manifest, "map_transfer": {"can_start_client": true, "state": "host_manifest_ready"}, "assignments": ASSIGNMENTS, "peers": [{"peer_id": 1, "is_host": true, "team_id": "team_alpha", "fireteam_ids": ["blue", "gold"]}, {"peer_id": 2, "is_host": false, "team_id": "team_bravo", "fireteam_ids": ["red"]}]}


func _transfer_state(client: Node) -> String:
	return String(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_transfer", {})).get("state", ""))


func _can_start_client(client: Node) -> bool:
	return bool(Dictionary(Dictionary(client.call("get_session_snapshot")).get("map_transfer", {})).get("can_start_client", false))


func _mission_started(client: Node) -> bool:
	return bool(Dictionary(client.call("get_session_snapshot")).get("mission_started", false))


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
