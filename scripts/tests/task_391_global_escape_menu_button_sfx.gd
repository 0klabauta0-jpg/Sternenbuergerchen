extends SceneTree

const GLOBAL_ESCAPE_MENU_SCRIPT: GDScript = preload("res://scripts/ui/global_escape_menu.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const TEST_MISSION_SCENE_PATH: String = "res://scenes/meta/meta_layer_test.tscn"
const TEST_SAVE_PATH: String = "user://task_391_mission_shell_slot.cfg"
const TEST_SETTINGS_PATH: String = "user://task_391_escape_settings.cfg"

var _passed: int = 0
var _failed: int = 0
var _shell = null


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_391 Global Escape Menu Button SFX ===")
	_shell = await _ensure_shell()
	_test_shell_contract()
	await _test_escape_toggle()
	await _test_global_button_sfx_for_dynamic_buttons()
	_test_settings_roundtrip()
	await _test_mission_shell_save_load_contract()
	await _test_main_menu_mission_slot_controls()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _ensure_shell():
	var existing = root.get_node_or_null("GlobalEscapeMenu")
	if existing != null:
		existing.call("set_test_mode", true)
		existing.call("set_save_path_for_tests", TEST_SAVE_PATH)
		existing.call("set_settings_path_for_tests", TEST_SETTINGS_PATH)
		return existing
	var shell = GLOBAL_ESCAPE_MENU_SCRIPT.new()
	root.add_child(shell)
	await process_frame
	shell.call("set_test_mode", true)
	shell.call("set_save_path_for_tests", TEST_SAVE_PATH)
	shell.call("set_settings_path_for_tests", TEST_SETTINGS_PATH)
	return shell


func _test_shell_contract() -> void:
	var snapshot: Dictionary = Dictionary(_shell.call("get_shell_snapshot"))
	_assert(bool(snapshot.get("autoload", false)), "Global escape shell exposes its diagnostic contract")
	_assert(bool(snapshot.get("has_resume", false)), "Escape menu has Resume")
	_assert(bool(snapshot.get("has_settings", false)), "Escape menu has Settings")
	_assert(bool(snapshot.get("has_save", false)), "Escape menu has Mission Save")
	_assert(bool(snapshot.get("has_load", false)), "Escape menu has Mission Load")
	_assert(bool(snapshot.get("has_main_menu", false)), "Escape menu has Main Menu")
	_assert(bool(snapshot.get("has_quit", false)), "Escape menu has Quit")


func _test_escape_toggle() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	_shell.call("_input", event)
	await process_frame
	_assert(bool(_shell.call("is_menu_visible")), "Escape opens the global pause menu")
	_shell.call("_input", event)
	await process_frame
	_assert(not bool(_shell.call("is_menu_visible")), "Escape closes the global pause menu")


func _test_global_button_sfx_for_dynamic_buttons() -> void:
	var host := Control.new()
	host.name = "Task391DynamicButtonHost"
	root.add_child(host)
	var button := Button.new()
	button.name = "Task391DynamicButton"
	button.text = "Probe"
	host.add_child(button)
	await process_frame
	_assert(bool(_shell.call("is_button_sfx_installed", button)), "Global shell installs SFX on dynamic buttons")
	var before: Dictionary = Dictionary(_shell.call("get_audio_sfx_debug_snapshot"))
	var before_count: int = int(before.get("played_count", 0))
	button.pressed.emit()
	await process_frame
	var after: Dictionary = Dictionary(_shell.call("get_audio_sfx_debug_snapshot"))
	_assert(int(after.get("played_count", 0)) > before_count, "Dynamic button press emits UI SFX through the global shell")
	host.queue_free()
	await process_frame


func _test_settings_roundtrip() -> void:
	_shell.call("open_settings")
	_shell.call("set_draft_audio_settings", 33.0, 44.0, 55.0)
	var result: Dictionary = Dictionary(_shell.call("apply_settings_from_overlay"))
	_assert(bool(result.get("ok", false)), "Escape settings overlay saves through GameSettingsContract")
	var loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	_assert(is_equal_approx(float(loaded.get("master_volume", 0.0)), 33.0), "Escape settings persist master volume")
	_assert(is_equal_approx(float(loaded.get("sfx_volume", 0.0)), 44.0), "Escape settings persist SFX volume")
	_assert(is_equal_approx(float(loaded.get("ui_volume", 0.0)), 55.0), "Escape settings persist UI volume")
	_shell.call("close_menu")


func _test_mission_shell_save_load_contract() -> void:
	var packed_scene := ResourceLoader.load(TEST_MISSION_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Mission test scene loads for shell save contract")
	if packed_scene == null:
		return
	var previous_scene := current_scene
	var mission_scene := packed_scene.instantiate()
	mission_scene.name = "Task391MissionScene"
	root.add_child(mission_scene)
	current_scene = mission_scene
	await process_frame
	var save_result: Dictionary = Dictionary(_shell.call("save_current_mission_slot"))
	_assert(bool(save_result.get("ok", false)), "Global shell saves current mission scene path")
	var slot: Dictionary = Dictionary(_shell.call("get_save_slot_snapshot"))
	_assert(bool(slot.get("exists", false)) and String(slot.get("scene_path", "")) == TEST_MISSION_SCENE_PATH, "Mission shell slot records the active scene path")
	var load_result: Dictionary = Dictionary(_shell.call("load_mission_slot", false))
	_assert(bool(load_result.get("ok", false)) and String(load_result.get("scene_path", "")) == TEST_MISSION_SCENE_PATH, "Global shell can load the saved scene path in test mode")
	var quit_result: Dictionary = Dictionary(_shell.call("request_quit_game"))
	_assert(bool(quit_result.get("ok", false)) and bool(_shell.call("was_quit_requested_for_tests")), "Quit action is routed through the global shell contract")
	current_scene = previous_scene
	mission_scene.queue_free()
	await process_frame


func _test_main_menu_mission_slot_controls() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads for mission slot controls")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(main_menu.call("get_settings_ui_snapshot"))
	var route_snapshot: Dictionary = Dictionary(main_menu.call("get_route_snapshot"))
	_assert(bool(ui_snapshot.get("mission_save_button_visible", false)), "Main menu exposes Mission speichern")
	_assert(bool(ui_snapshot.get("mission_load_button_visible", false)), "Main menu exposes Mission laden")
	_assert(String(route_snapshot.get("mission_save", "")) == "global_shell_slot", "Main menu save is wired to the global shell slot")
	_assert(String(route_snapshot.get("mission_load", "")) == "global_shell_slot", "Main menu load is wired to the global shell slot")
	main_menu.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
