extends SceneTree

const APP_SHELL_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/app_shell_return_navigation_contract.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_300 App Shell Return To Main Menu Navigation ===")
	var snapshot: Dictionary = Dictionary(APP_SHELL_CONTRACT_SCRIPT.call("build_shell_snapshot", {
		"multiplayer": {"active_session": true},
		"editor": {"dirty": true},
		"settings": {"has_draft_changes": true},
	}))
	var validation: Dictionary = Dictionary(APP_SHELL_CONTRACT_SCRIPT.call("validate_shell_snapshot", snapshot))
	_assert(bool(snapshot.get("all_primary_areas_covered", false)), "Singleplayer/multiplayer/editor/settings are covered")
	_assert(bool(validation.get("valid", false)), "Return navigation contract validates")
	var areas: Dictionary = Dictionary(snapshot.get("areas", {}))
	_assert(bool(Dictionary(areas.get("multiplayer", {})).get("requires_confirmation", false)), "Multiplayer active session requests confirmation")
	_assert(bool(Dictionary(areas.get("editor", {})).get("requires_confirmation", false)), "Editor dirty state requests confirmation")
	_assert(bool(Dictionary(areas.get("settings", {})).get("requires_confirmation", false)), "Settings draft state requests confirmation")
	_assert(String(Dictionary(areas.get("singleplayer", {})).get("target_scene", "")) == APP_SHELL_CONTRACT_SCRIPT.get("MAIN_MENU_SCENE_PATH"), "Singleplayer return targets main menu")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
