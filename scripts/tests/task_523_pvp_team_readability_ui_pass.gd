extends SceneTree

const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")
const MULTIPLAYER_SESSION_SCRIPT: GDScript = preload("res://scripts/multiplayer/multiplayer_session.gd")
const LOBBY_TEST_SCENE: PackedScene = preload("res://scenes/tests/lobby_test.tscn")
const MULTIPLAYER_LOBBY_SCENE: PackedScene = preload("res://scenes/ui/multiplayer_lobby.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TASK_PATH: String = "res://docs/tasks/TASK_523_pvp_team_readability_ui_pass.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const TEAM_OWNERSHIP_PATH: String = "res://scripts/mission/mission_multiplayer_team_ownership_contract.gd"
const MULTIPLAYER_SESSION_PATH: String = "res://scripts/multiplayer/multiplayer_session.gd"
const LOBBY_SCREEN_PATH: String = "res://scripts/ui/multiplayer_lobby_screen.gd"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_523 PvP Team Readability UI Pass ===")
	_test_docs_and_wiring()
	_test_contract_adds_readability_without_ui_truth()
	await _test_session_readability_for_pvp_and_coop()
	await _test_lobby_test_screen_displays_readability()
	await _test_productive_lobby_displays_readability()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_523: FAILED")
		quit(1)
		return
	print("TASK_523: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_523 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_523 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_523 - PvP Team Readability UI Pass"), "Implementation status tracks TASK_523")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_523 - PvP Team Readability UI Pass"), "Roadmap lists TASK_523")
	_assert(_read_text(REPORT_PATH).contains("TASK_523 - PvP Team Readability UI Pass"), "Review workbench tracks TASK_523")
	_assert(_read_text(TEAM_OWNERSHIP_PATH).contains("team_readability_summary"), "Ownership contract exposes readability summary")
	_assert(_read_text(MULTIPLAYER_SESSION_PATH).contains("get_team_readability_snapshot"), "MultiplayerSession exposes team readability snapshot")
	_assert(_read_text(LOBBY_SCREEN_PATH).contains("team_readability_text"), "Productive lobby exposes readability text in UI snapshot")


func _test_contract_adds_readability_without_ui_truth() -> void:
	var snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_team_ownership_snapshot", _load_slice(), {}, "singleplayer"))
	var summary: String = String(snapshot.get("team_readability_summary", ""))
	var entries: Array = Array(snapshot.get("team_readability", []))
	var alpha: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("get_team_entry", snapshot, "team_alpha"))
	var bravo: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("get_team_entry", snapshot, "team_bravo"))
	_assert(bool(snapshot.get("valid", false)), "Singleplayer ownership snapshot remains valid")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Ownership snapshot remains read-only for UI")
	_assert(summary.contains("Singleplayer"), "Readability summary names singleplayer mode")
	_assert(summary.contains("Alpha") and summary.contains("Host Peer 1"), "Readability summary names Alpha host ownership")
	_assert(summary.contains("Bravo") and summary.contains("NPC / Scenario"), "Readability summary names Bravo NPC ownership")
	_assert(not entries.is_empty(), "Readability entries are present")
	_assert(String(alpha.get("team_color_hex", "")) == "#5fb7ff", "Alpha entry carries stable team color")
	_assert(String(bravo.get("team_color_hex", "")) == "#ff9b5e", "Bravo entry carries stable team color")
	_assert(String(bravo.get("readability_tone", "")) == "npc", "NPC Bravo is marked with NPC readability tone")


func _test_session_readability_for_pvp_and_coop() -> void:
	var pvp_session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	root.add_child(pvp_session)
	pvp_session.call("configure_host_state_for_test", [2])
	var pvp_snapshot: Dictionary = Dictionary(pvp_session.call("get_session_snapshot"))
	var pvp_readability: Dictionary = Dictionary(pvp_snapshot.get("team_readability", {}))
	var pvp_summary: String = String(pvp_snapshot.get("team_readability_summary", ""))
	_assert(bool(pvp_readability.get("valid", false)), "PvP session readability snapshot is valid")
	_assert(not bool(pvp_readability.get("ui_sets_gameplay_truth", true)), "PvP readability is UI read-only")
	_assert(pvp_summary.contains("PvP"), "PvP session summary names PvP mode")
	_assert(pvp_summary.contains("Alpha -> Host Peer 1"), "PvP session summary names host Alpha")
	_assert(pvp_summary.contains("Bravo -> Peer 2"), "PvP session summary names Peer2 Bravo")
	pvp_session.queue_free()

	var coop_session: Node = MULTIPLAYER_SESSION_SCRIPT.new()
	root.add_child(coop_session)
	coop_session.call("set_lobby_player_setup", {"team_play_mode": "coop"})
	coop_session.call("configure_host_state_for_test", [2])
	var coop_snapshot: Dictionary = Dictionary(coop_session.call("get_session_snapshot"))
	var coop_summary: String = String(coop_snapshot.get("team_readability_summary", ""))
	_assert(coop_summary.contains("Coop"), "Coop session summary names coop mode")
	_assert(coop_summary.contains("Alpha -> Host Peer 1 + Peer 2"), "Coop session summary groups peers on Alpha")
	_assert(coop_summary.contains("Bravo -> NPC / Scenario"), "Coop session keeps Bravo NPC controlled")
	coop_session.queue_free()
	await process_frame


func _test_lobby_test_screen_displays_readability() -> void:
	var lobby: Node = LOBBY_TEST_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	var session: Node = lobby.get_node("MultiplayerSession")
	session.call("configure_host_state_for_test", [2])
	await process_frame
	var text: String = String(lobby.call("get_team_readability_text"))
	_assert(text.contains("PvP"), "Test lobby displays PvP readability mode")
	_assert(text.contains("Alpha -> Host Peer 1"), "Test lobby displays Alpha owner")
	_assert(text.contains("Bravo -> Peer 2"), "Test lobby displays Bravo owner")
	lobby.queue_free()
	await process_frame


func _test_productive_lobby_displays_readability() -> void:
	var lobby: Node = MULTIPLAYER_LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	lobby.call("set_team_play_mode_for_tests", "versus")
	var session: Node = lobby.get_node("MultiplayerSession")
	session.call("configure_host_state_for_test", [2])
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var text: String = String(ui_snapshot.get("team_readability_text", ""))
	_assert(text.contains("PvP"), "Productive lobby displays PvP readability mode")
	_assert(text.contains("Alpha -> Host Peer 1"), "Productive lobby displays Alpha owner")
	_assert(text.contains("Bravo -> Peer 2"), "Productive lobby displays Bravo owner")
	_assert(not bool(Dictionary(Dictionary(ui_snapshot.get("session", {})).get("team_readability", {})).get("ui_sets_gameplay_truth", true)), "Productive lobby session keeps readability read-only")
	lobby.queue_free()
	await process_frame


func _load_slice() -> Dictionary:
	return Dictionary(VERTICAL_SLICE_CONTRACT_SCRIPT.call("load_slice_from_file", SCENARIO_PATH))


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
