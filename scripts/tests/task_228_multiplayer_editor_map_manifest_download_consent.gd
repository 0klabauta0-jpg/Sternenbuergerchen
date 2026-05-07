extends SceneTree

const MAP_MANIFEST_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_map_manifest.gd")
const TERRAIN_MAP_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const MAP_PATH: String = "user://task_228_host_map.json"
const DIFFERENT_MAP_PATH: String = "user://task_228_host_map_different.json"
const CACHE_ROOT: String = "user://task_228_downloaded_maps"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_228 Multiplayer Editor Map Manifest Download Consent ===")
	_test_manifest_known_unknown_hash_and_security()
	await _test_lobby_consent_flow()
	await _test_session_snapshot_boundary()
	_test_contract_doc()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_manifest_known_unknown_hash_and_security() -> void:
	var map_text: String = _write_fixture_map(MAP_PATH, "task_228_host_map", 3)
	var manifest: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", MAP_PATH))
	_assert(bool(manifest.get("valid", false)), "Host can build a valid editor-map manifest")
	_assert(String(manifest.get("map_id", "")) == "task_228_host_map", "Manifest carries safe map id")
	_assert(String(manifest.get("map_hash", "")).length() == 64, "Manifest carries SHA-256 map hash")
	_assert(int(manifest.get("map_size_bytes", 0)) == map_text.to_utf8_buffer().size(), "Manifest carries map payload size")

	var known: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("check_local_map", manifest, [MAP_PATH]))
	_assert(String(known.get("state", "")) == "known" and not bool(known.get("requires_consent", true)), "Known map with matching hash needs no prompt")
	var missing: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("check_local_map", manifest, []))
	_assert(String(missing.get("state", "")) == "missing" and bool(missing.get("requires_consent", false)), "Unknown map requires consent")

	_write_fixture_map(DIFFERENT_MAP_PATH, "task_228_host_map", 4)
	var mismatch: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("check_local_map", manifest, [DIFFERENT_MAP_PATH]))
	_assert(String(mismatch.get("state", "")) == "hash_mismatch" and bool(mismatch.get("requires_consent", false)), "Same map id with different hash requires consent")

	var unsafe_manifest: Dictionary = manifest.duplicate(true)
	unsafe_manifest["map_id"] = "../evil"
	var unsafe_check: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("verify_manifest", unsafe_manifest))
	_assert(not bool(unsafe_check.get("valid", true)), "Path traversal map id is rejected")

	var bad_payload_result: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("accept_download", manifest, map_text + "\n ", CACHE_ROOT))
	_assert(not bool(bad_payload_result.get("accepted", true)) and String(bad_payload_result.get("state", "")) == "hash_mismatch", "Hash mismatch payload is rejected before cache write")


func _test_lobby_consent_flow() -> void:
	var map_text: String = _read_text(MAP_PATH)
	var manifest: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", MAP_PATH))
	var packed_scene := ResourceLoader.load(LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads for map consent")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate()
	root.add_child(lobby)
	await process_frame
	var missing_state: Dictionary = Dictionary(lobby.call("set_host_map_manifest", manifest, []))
	_assert(String(missing_state.get("state", "")) == "missing", "Lobby detects unknown host map")
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(bool(ui_snapshot.get("map_consent_visible", false)), "Unknown map shows download consent prompt")
	_assert(String(ui_snapshot.get("map_consent_text", "")).contains("task_228_host_map"), "Consent prompt names the offered map")

	var reject_result: Dictionary = Dictionary(lobby.call("reject_pending_map_download"))
	_assert(String(reject_result.get("state", "")) == "rejected" and not bool(reject_result.get("can_start_client", true)), "Reject keeps client from starting with unknown map")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(not bool(ui_snapshot.get("map_consent_visible", true)), "Reject hides consent prompt without accepting")

	lobby.call("set_host_map_manifest", manifest, [])
	var accept_result: Dictionary = Dictionary(lobby.call("accept_pending_map_download", map_text, CACHE_ROOT))
	_assert(bool(accept_result.get("accepted", false)), "Accept validates and caches the host map")
	var cache_path: String = String(accept_result.get("cache_path", ""))
	_assert(cache_path.begins_with(CACHE_ROOT) and FileAccess.file_exists(cache_path), "Accepted map is written under safe user cache root")
	var cached_manifest: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", cache_path))
	_assert(String(cached_manifest.get("map_hash", "")) == String(manifest.get("map_hash", "")), "Cached map hash matches host manifest")
	ui_snapshot = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(not bool(ui_snapshot.get("map_consent_visible", true)), "Accepted map hides consent prompt")
	lobby.queue_free()
	await process_frame


func _test_session_snapshot_boundary() -> void:
	var map_text: String = _read_text(MAP_PATH)
	var manifest: Dictionary = Dictionary(MAP_MANIFEST_SCRIPT.call("build_manifest_for_map", MAP_PATH))
	var session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	root.add_child(session)
	await process_frame
	var transfer: Dictionary = Dictionary(session.call("evaluate_client_map_manifest", manifest, []))
	_assert(bool(transfer.get("requires_consent", false)), "Session marks unknown map as consent-gated")
	var snapshot: Dictionary = Dictionary(session.call("get_session_snapshot"))
	_assert(Dictionary(snapshot.get("map_manifest", {})).has("map_hash"), "Session snapshot carries manifest metadata")
	_assert(not snapshot.has("map_json_text") and not snapshot.has("map_payload"), "Session snapshot does not carry full map payload")
	session.call("accept_map_download", manifest, map_text, CACHE_ROOT)
	snapshot = Dictionary(session.call("get_session_snapshot"))
	_assert(String(Dictionary(snapshot.get("map_transfer", {})).get("state", "")) == "accepted", "Session records accepted map transfer state")
	session.queue_free()


func _test_contract_doc() -> void:
	var doc: String = _read_text("res://docs/dev/multiplayer_editor_map_transfer_contract.md")
	_assert(doc.contains("Manifest") and doc.contains("Consent"), "Map transfer contract doc covers manifest and consent")
	_assert(doc.contains("user://downloaded_maps") and doc.contains("Pfad-Traversal"), "Map transfer contract doc covers safe cache and traversal boundary")


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


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
