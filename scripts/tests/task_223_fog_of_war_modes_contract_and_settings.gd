extends SceneTree

const FOW_MODE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")
const FOW_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const CONTRACT_DOC_PATH: String = "res://docs/dev/fog_of_war_modes_contract.md"
const TEST_SETTINGS_PATH: String = "user://task_223_game_settings.cfg"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_223 Fog of War Modes Contract and Settings ===")
	_test_mode_contract()
	_test_game_settings_roundtrip()
	_test_fog_system_adapter()
	await _test_main_menu_settings_snapshot()
	_test_docs()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_mode_contract() -> void:
	var contract: Dictionary = Dictionary(FOW_MODE_CONTRACT_SCRIPT.call("get_contract_snapshot"))
	var valid_modes: PackedStringArray = PackedStringArray(contract.get("valid_modes", PackedStringArray()))
	_assert(valid_modes == PackedStringArray(["off", "known_terrain", "unexplored_blackout"]), "FoW contract exposes stable mode IDs")
	_assert(String(contract.get("default_mode", "")) == "known_terrain", "FoW default mode is known_terrain")
	_assert(FOW_MODE_CONTRACT_SCRIPT.call("normalize_mode", "OFF") == "off", "FoW mode normalization is case-insensitive")
	_assert(FOW_MODE_CONTRACT_SCRIPT.call("normalize_mode", "bad_mode") == "known_terrain", "FoW invalid mode falls back to default")
	_assert(PackedStringArray(contract.get("separated_state", PackedStringArray())).has("terrain_knowledge"), "Contract separates terrain knowledge")
	_assert(PackedStringArray(contract.get("separated_state", PackedStringArray())).has("current_visibility"), "Contract separates current visibility")
	_assert(PackedStringArray(contract.get("separated_state", PackedStringArray())).has("last_known_contacts"), "Contract separates last known contacts")
	_assert(String(contract.get("multiplayer_boundary", "")).contains("team_or_peer_scoped"), "Contract documents team/peer multiplayer boundary")


func _test_game_settings_roundtrip() -> void:
	var defaults: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("get_default_settings"))
	_assert(String(defaults.get("fog_of_war_mode", "")) == "known_terrain", "Game settings default FoW mode is known_terrain")
	var normalized: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", {"fog_of_war_mode": "unexplored_blackout"}))
	_assert(String(normalized.get("fog_of_war_mode", "")) == "unexplored_blackout", "Game settings accepts unexplored_blackout")
	_assert(bool(normalized.get("fog_of_war_enabled", false)), "Game settings marks unexplored_blackout as enabled")
	var off_settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", {"fog_of_war_mode": "off"}))
	_assert(not bool(off_settings.get("fog_of_war_enabled", true)), "Game settings marks off mode as disabled")
	var save_error: Error = GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", normalized, TEST_SETTINGS_PATH)
	_assert(save_error == OK, "Game settings save FoW mode to ConfigFile")
	var loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	_assert(String(loaded.get("fog_of_war_mode", "")) == "unexplored_blackout", "Game settings roundtrip preserves FoW mode")
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", loaded))
	_assert(PackedStringArray(snapshot.get("valid_fog_of_war_modes", PackedStringArray())).has("known_terrain"), "Game settings snapshot exposes valid FoW modes")


func _test_fog_system_adapter() -> void:
	var fow = FOW_SYSTEM_SCRIPT.new()
	_assert(String(fow.call("get_mode_for_team", "team_alpha")) == "known_terrain", "FogOfWarSystem defaults team mode to known_terrain")
	fow.call("set_visible", "team_alpha", "enemy_1", true)
	_assert(bool(fow.call("is_visible", "team_alpha", "enemy_1")), "Legacy target visibility remains compatible")
	fow.call("set_visible", "team_alpha", "enemy_1", false)
	_assert(not bool(fow.call("is_visible", "team_alpha", "enemy_1")), "Legacy target visibility can still be hidden")
	fow.call("set_mode_for_team", "team_alpha", "known_terrain")
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_99")) == "known", "known_terrain keeps unseen terrain readable")
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_99")) == "unknown", "unexplored_blackout keeps never-seen tile unknown")
	fow.call("mark_tile_visible", "team_alpha", "tile_01", true)
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_01")) == "visible", "Current visible tile is visible")
	fow.call("mark_tile_visible", "team_alpha", "tile_01", false)
	_assert(String(fow.call("get_terrain_visibility_state", "team_alpha", "tile_01")) == "explored", "Previously visible tile stays explored in blackout mode")
	fow.call("set_event_visible", "team_alpha", "event_1", true)
	fow.call("record_last_known_contact", "team_alpha", {"target_id": "enemy_1", "last_known_position": Vector2(40.0, 20.0), "last_seen_tick": 12})
	var snapshot: Dictionary = Dictionary(fow.call("build_team_state_snapshot", "team_alpha", 0))
	_assert(Dictionary(snapshot.get("terrain_knowledge", {})).has("visible_tile_ids"), "FoW snapshot separates terrain knowledge")
	_assert(PackedStringArray(Dictionary(snapshot.get("terrain_knowledge", {})).get("explored_tile_ids", PackedStringArray())).has("tile_01"), "FoW snapshot carries explored tile IDs")
	_assert(PackedStringArray(Dictionary(snapshot.get("current_visibility", {})).get("visible_event_ids", PackedStringArray())).has("event_1"), "FoW snapshot carries current visible event IDs")
	_assert(Array(snapshot.get("last_known_contacts", [])).size() == 1, "FoW snapshot carries last known contacts separately")
	fow.call("set_mode_for_team", "team_alpha", "off")
	_assert(bool(fow.call("should_show_dynamic_target", "team_alpha", "hidden_enemy")), "FoW off mode allows dynamic target display")
	fow.call("set_peer_team", 2, "team_alpha")
	var peer_snapshot: Dictionary = Dictionary(fow.call("build_peer_state_snapshot", 2))
	_assert(int(peer_snapshot.get("peer_id", 0)) == 2 and String(peer_snapshot.get("team_id", "")) == "team_alpha", "FoW peer snapshot is scoped to peer team")


func _test_main_menu_settings_snapshot() -> void:
	var packed_scene := load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene exists for settings snapshot")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	var snapshot: Dictionary = Dictionary(main_menu.call("get_settings_snapshot"))
	var gameplay: Dictionary = Dictionary(snapshot.get("gameplay", {}))
	_assert(String(gameplay.get("fog_of_war_mode", "")) == "known_terrain" or FOW_MODE_CONTRACT_SCRIPT.call("is_valid_mode", String(gameplay.get("fog_of_war_mode", ""))), "Main menu settings snapshot includes valid FoW mode")
	_assert(PackedStringArray(gameplay.get("valid_fog_of_war_modes", PackedStringArray())).has("unexplored_blackout"), "Main menu settings snapshot exposes FoW mode list")
	main_menu.queue_free()
	await process_frame


func _test_docs() -> void:
	var text: String = _read_text(CONTRACT_DOC_PATH)
	_assert(not text.is_empty(), "FoW mode contract doc exists")
	for required_text in ["off", "known_terrain", "unexplored_blackout", "Terrainwissen", "aktuelle Sicht", "letzte bekannte Kontakte", "Multiplayer"]:
		_assert(text.contains(required_text), "FoW doc covers '%s'" % required_text)


func has_line_of_sight_to_position(_observer: Node2D, target_position: Vector2, max_range: float) -> bool:
	return target_position.length() <= max_range


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
