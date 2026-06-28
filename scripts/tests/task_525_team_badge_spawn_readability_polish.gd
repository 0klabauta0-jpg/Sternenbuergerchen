extends SceneTree

const VERTICAL_SLICE_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_scenario_vertical_slice_contract.gd")
const TEAM_OWNERSHIP_CONTRACT_SCRIPT: GDScript = preload("res://scripts/mission/mission_multiplayer_team_ownership_contract.gd")
const MULTIPLAYER_LOBBY_SCENE: PackedScene = preload("res://scenes/ui/multiplayer_lobby.tscn")

const SCENARIO_PATH: String = "res://data/mission_scenarios/frontier_probe_vertical_slice.json"
const TASK_PATH: String = "res://docs/tasks/TASK_525_team_badge_spawn_readability_polish.md"
const STATUS_PATH: String = "res://docs/IMPLEMENTATION_STATUS.md"
const ROADMAP_PATH: String = "res://docs/TASK_ROADMAP.md"
const REPORT_PATH: String = "res://docs/reports/project_review_status_2026_06_28.html"
const TEAM_OWNERSHIP_PATH: String = "res://scripts/mission/mission_multiplayer_team_ownership_contract.gd"
const LOBBY_SCREEN_PATH: String = "res://scripts/ui/multiplayer_lobby_screen.gd"
const LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_525 Team Badge / Spawn Readability Polish ===")
	_test_docs_and_wiring()
	_test_contract_exports_badge_and_spawn_data()
	await _test_productive_lobby_renders_team_badges()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("TASK_525: FAILED")
		quit(1)
		return
	print("TASK_525: ALL PASSED")
	quit(0)


func _test_docs_and_wiring() -> void:
	_assert(FileAccess.file_exists(TASK_PATH), "TASK_525 task file exists")
	_assert(_read_text(TASK_PATH).contains("## Status: IMPLEMENTIERT"), "TASK_525 task file marks implementation")
	_assert(_read_text(STATUS_PATH).contains("TASK_525 - Team Badge / Spawn Readability Polish"), "Implementation status tracks TASK_525")
	_assert(_read_text(ROADMAP_PATH).contains("TASK_525 - Team Badge / Spawn Readability Polish (implementiert)"), "Roadmap marks TASK_525 implemented")
	_assert(_read_text(REPORT_PATH).contains("TASK_525 - Team Badge / Spawn Readability Polish"), "Review workbench tracks TASK_525")
	_assert(_read_text(TEAM_OWNERSHIP_PATH).contains("badge_text"), "Ownership contract exports badge text")
	_assert(_read_text(LOBBY_SCREEN_PATH).contains("_refresh_team_badges"), "Productive lobby refreshes team badges")
	_assert(_read_text(LOBBY_SCENE_PATH).contains("TeamBadgeRow"), "Productive lobby scene contains badge row")


func _test_contract_exports_badge_and_spawn_data() -> void:
	var assignments: Dictionary = {
		"peer_teams": {
			1: "team_alpha",
			2: "team_bravo",
		},
	}
	var snapshot: Dictionary = Dictionary(TEAM_OWNERSHIP_CONTRACT_SCRIPT.call("build_team_ownership_snapshot", _load_slice(), assignments, "multiplayer_pvp"))
	var entries: Array = Array(snapshot.get("team_readability", []))
	_assert(bool(snapshot.get("valid", false)), "PvP ownership snapshot remains valid")
	_assert(not bool(snapshot.get("ui_sets_gameplay_truth", true)), "Ownership snapshot remains read-only")
	_assert(entries.size() >= 2, "Readability exposes team entries for badges")
	var alpha: Dictionary = _find_entry(entries, "team_alpha")
	var bravo: Dictionary = _find_entry(entries, "team_bravo")
	_assert(String(alpha.get("badge_text", "")).contains("Alpha") and String(alpha.get("badge_text", "")).contains("Host Peer 1"), "Alpha badge names host owner")
	_assert(String(alpha.get("badge_text", "")).contains("spawn_alpha"), "Alpha badge names spawn marker")
	_assert(String(alpha.get("spawn_chip_text", "")).contains("Spawn spawn_alpha"), "Alpha spawn chip names spawn")
	_assert(String(alpha.get("team_color_hex", "")) == "#5fb7ff", "Alpha badge keeps blue team color")
	_assert(String(bravo.get("badge_text", "")).contains("Bravo") and String(bravo.get("badge_text", "")).contains("Peer 2"), "Bravo badge names peer owner")
	_assert(String(bravo.get("badge_text", "")).contains("spawn_bravo"), "Bravo badge names spawn marker")
	_assert(String(bravo.get("spawn_chip_text", "")).contains("Spawn spawn_bravo"), "Bravo spawn chip names spawn")
	_assert(String(bravo.get("team_color_hex", "")) == "#ff9b5e", "Bravo badge keeps orange team color")


func _test_productive_lobby_renders_team_badges() -> void:
	var lobby: Node = MULTIPLAYER_LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	lobby.call("set_team_play_mode_for_tests", "versus")
	var session: Node = lobby.get_node("MultiplayerSession")
	session.call("configure_host_state_for_test", [2])
	await process_frame
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var badge_text: String = String(ui_snapshot.get("team_badge_text", ""))
	var badges: Array = Array(ui_snapshot.get("team_badges", []))
	_assert(int(ui_snapshot.get("team_badge_count", 0)) >= 2, "Productive lobby renders at least two team badge controls")
	_assert(badges.size() >= 2, "Productive lobby exposes badge data")
	_assert(badge_text.contains("Alpha") and badge_text.contains("Host Peer 1"), "Lobby badge text names Alpha host")
	_assert(badge_text.contains("Bravo") and badge_text.contains("Peer 2"), "Lobby badge text names Bravo peer")
	_assert(badge_text.contains("spawn_alpha") and badge_text.contains("spawn_bravo"), "Lobby badge text names both spawn markers")
	_assert(not bool(Dictionary(Dictionary(ui_snapshot.get("session", {})).get("team_readability", {})).get("ui_sets_gameplay_truth", true)), "Lobby badge source remains read-only")
	lobby.queue_free()
	await process_frame


func _find_entry(entries: Array, team_id: String) -> Dictionary:
	for entry_variant in entries:
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("team_id", "")) == team_id:
			return entry
	return {}


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
