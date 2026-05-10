extends SceneTree

const TEAM_NAME_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/team_name_generator.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")

const TEMP_SAVE_PATH: String = "user://task_299_roster_v1.json"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_299 Team Identity Name Generation Userology ===")
	_test_generator()
	_test_roster_persistence()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_generator() -> void:
	var a: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("generate_team_name", "task299_seed", "player_a", 0))
	var b: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("generate_team_name", "task299_seed", "player_a", 0))
	var c: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("generate_team_name", "task299_seed", "player_a", 1))
	_assert(String(a.get("team_name", "")).strip_edges().length() > 4, "Generator produces non-empty atmospheric team name")
	_assert(String(a.get("team_name", "")) == String(b.get("team_name", "")), "Generator is stable for same seed/profile/index")
	_assert(String(a.get("team_name", "")) != "Team 1", "Generator avoids boring Team 1 placeholder")
	_assert(String(c.get("team_name", "")).strip_edges().length() > 4, "Suggestion reroll produces a usable name")


func _test_roster_persistence() -> void:
	var roster: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("generate_start_roster", "task299_roster", 20, "task299_profile"))
	var identity: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("build_team_identity_snapshot", roster))
	_assert(bool(identity.get("has_team_name", false)), "Generated roster has team name")
	_assert(String(identity.get("ownership_scope", "")) == "player_roster_profile", "Team name belongs to roster/player profile scope")
	var renamed: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("rename_team", roster, "Nova Kuriere Iona", "task299_profile", TEMP_SAVE_PATH))
	_assert(bool(renamed.get("ok", false)), "Edited team name saves")
	var loaded: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", "task299_profile", TEMP_SAVE_PATH))
	_assert(bool(loaded.get("ok", false)), "Edited team name loads")
	_assert(String(Dictionary(loaded.get("roster", {})).get("team_name", "")) == "Nova Kuriere Iona", "Edited team name persists after load")
	var reset: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("reset_roster", "task299_reset", 20, "task299_profile", TEMP_SAVE_PATH, false))
	_assert(bool(reset.get("ok", false)), "Reset creates a new named roster")
	_assert(String(Dictionary(reset.get("roster", {})).get("team_name", "")).strip_edges().length() > 4, "Reset roster gets a team name")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
