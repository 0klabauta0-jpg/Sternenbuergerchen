extends SceneTree

const CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_roster_contract.gd")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const SNAPSHOT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")

const LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const DOC_PATH: String = "res://docs/dev/multiplayer_player_roster_ownership_contract.md"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_240 Multiplayer Player Roster Ownership Contract ===")
	await _test_contract_modes_and_documentation()
	await _test_session_peer_roster_ownership_modes()
	await _test_public_roster_preview_strips_private_fields()
	await _test_snapshot_units_keep_ownership_not_private_profile()
	await _test_lobby_structurally_exposes_roster_mode()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_contract_modes_and_documentation() -> void:
	_assert(bool(CONTRACT_SCRIPT.call("is_valid_roster_mode", "host_roster")), "host_roster mode is valid")
	_assert(bool(CONTRACT_SCRIPT.call("is_valid_roster_mode", "player_rosters")), "player_rosters mode is valid")
	_assert(bool(CONTRACT_SCRIPT.call("is_valid_roster_mode", "scenario_roster")), "scenario_roster mode is valid")
	_assert(String(CONTRACT_SCRIPT.call("normalize_roster_mode", "bad_mode")) == "host_roster", "Invalid roster mode falls back to host_roster")
	_assert(FileAccess.file_exists(DOC_PATH), "Roster ownership contract document exists")
	var file := FileAccess.open(DOC_PATH, FileAccess.READ)
	var text: String = file.get_as_text() if file != null else ""
	if file != null:
		file.close()
	_assert(text.contains("owner_peer_id") and text.contains("private") and text.contains("host_server"), "Contract doc covers ownership, privacy and host authority")


func _test_session_peer_roster_ownership_modes() -> void:
	var session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	root.add_child(session)
	session.call("configure_host_state_for_test", [1, 2])
	var snapshot: Dictionary = Dictionary(session.call("get_session_snapshot"))
	var default_rosters: Dictionary = Dictionary(Dictionary(snapshot.get("assignments", {})).get("peer_rosters", {}))
	var peer_two_default: Dictionary = Dictionary(default_rosters.get(2, {}))
	_assert(String(Dictionary(snapshot.get("roster", {})).get("roster_mode", "")) == "host_roster", "Session defaults to host_roster")
	_assert(int(peer_two_default.get("owner_peer_id", 0)) == 1, "Client units belong to host in host_roster mode")
	_assert(String(peer_two_default.get("roster_source", "")) == "host", "Client roster source is host in host_roster mode")

	_assert(bool(session.call("set_roster_mode", "player_rosters")), "Host can switch to player_rosters before mission start")
	snapshot = Dictionary(session.call("get_session_snapshot"))
	var player_rosters: Dictionary = Dictionary(Dictionary(snapshot.get("assignments", {})).get("peer_rosters", {}))
	var peer_two_player: Dictionary = Dictionary(player_rosters.get(2, {}))
	_assert(int(peer_two_player.get("owner_peer_id", 0)) == 2, "Client owns its roster in player_rosters mode")
	_assert(String(peer_two_player.get("roster_source", "")) == "player", "Client roster source is player in player_rosters mode")
	_assert(bool(peer_two_player.get("uses_local_roster", false)), "Client local roster flag is true in player_rosters mode")
	_assert(PackedStringArray(peer_two_player.get("fireteam_ids", PackedStringArray())).has("red"), "Client keeps assigned fireteam while owning roster")

	_assert(bool(session.call("set_roster_mode", "scenario_roster")), "Host can switch to scenario_roster before mission start")
	snapshot = Dictionary(session.call("get_session_snapshot"))
	var scenario_rosters: Dictionary = Dictionary(Dictionary(snapshot.get("assignments", {})).get("peer_rosters", {}))
	var peer_two_scenario: Dictionary = Dictionary(scenario_rosters.get(2, {}))
	_assert(int(peer_two_scenario.get("owner_peer_id", -1)) == 0, "Scenario roster owner is scenario id 0")
	_assert(String(peer_two_scenario.get("roster_source", "")) == "scenario", "Scenario roster source is explicit")
	_assert(not bool(session.call("set_roster_mode", "invalid")), "Invalid roster mode is rejected by session")
	session.queue_free()
	await process_frame


func _test_public_roster_preview_strips_private_fields() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task_240_public_preview", 24, "task_240_owner"))
	var preview: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("build_public_roster_preview", roster, 2, "player", "player_rosters"))
	_assert(bool(preview.get("valid", false)), "PlayerRosterStore builds a valid public roster preview")
	_assert(int(preview.get("owner_peer_id", 0)) == 2, "Public preview carries owner peer")
	_assert(Array(preview.get("public_units", [])).size() == 24, "Public preview carries one public entry per unit")
	_assert(not bool(CONTRACT_SCRIPT.call("has_private_roster_fields", preview)), "Public preview contains no private roster fields")
	var first_unit: Dictionary = Dictionary(Array(preview.get("public_units", []))[0])
	_assert(first_unit.has("display_name") and first_unit.has("portrait_id") and first_unit.has("rank_badges"), "Public unit keeps identity, portrait id and coarse badges")
	_assert(not first_unit.has("skill_values") and not first_unit.has("relationship_links") and not first_unit.has("portrait_path"), "Public unit strips skill, relationship and asset path fields")


func _test_snapshot_units_keep_ownership_not_private_profile() -> void:
	var snapshot_contract: RefCounted = SNAPSHOT_CONTRACT_SCRIPT.new()
	var snapshot: Dictionary = snapshot_contract.call(
		"build_state_snapshot",
		{
			"tick": 7,
			"units": [
				{
					"unit_id": "player_two_alpha",
					"position": Vector2(10.0, 20.0),
					"owner_peer_id": 2,
					"roster_source": "player",
					"roster_mode": "player_rosters",
					"fireteam_id": "red",
					"progression": {"xp": 99},
					"relationship_links": [{"unit_id": "other"}],
					"skill_values": {"leadership": 0.99},
					"portrait_path": "res://private/path.png",
				},
			],
		}
	)
	var unit_snapshot: Dictionary = Dictionary(Array(snapshot.get("units", []))[0])
	_assert(int(unit_snapshot.get("owner_peer_id", 0)) == 2, "Snapshot keeps owner_peer_id")
	_assert(String(unit_snapshot.get("roster_source", "")) == "player", "Snapshot keeps roster_source")
	_assert(String(unit_snapshot.get("roster_mode", "")) == "player_rosters", "Snapshot keeps roster_mode")
	_assert(String(unit_snapshot.get("character_gameplay_authority", "")) == "host_server", "Snapshot marks character gameplay as host-authoritative")
	_assert(not bool(CONTRACT_SCRIPT.call("has_private_roster_fields", unit_snapshot)), "Snapshot unit contains no private roster fields")
	_assert(not unit_snapshot.has("progression") and not unit_snapshot.has("relationship_links") and not unit_snapshot.has("skill_values"), "Snapshot ignores private profile fields even if provided")


func _test_lobby_structurally_exposes_roster_mode() -> void:
	var packed_scene: PackedScene = ResourceLoader.load(LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads")
	if packed_scene == null:
		return
	var lobby: Node = packed_scene.instantiate()
	root.add_child(lobby)
	await process_frame
	lobby.call("configure_host_state_for_test", [1, 2])
	await process_frame
	_assert(bool(lobby.call("set_roster_mode", "player_rosters")), "Lobby can choose roster mode through MultiplayerSession")
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	_assert(String(ui_snapshot.get("roster_mode_selected", "")) == "player_rosters", "Lobby UI exposes selected roster mode")
	_assert(String(ui_snapshot.get("roster_mode_text", "")).contains("Player rosters"), "Lobby UI displays roster mode summary")
	_assert(not bool(ui_snapshot.get("roster_mode_disabled", true)), "Host lobby can edit roster mode before mission start")
	lobby.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
