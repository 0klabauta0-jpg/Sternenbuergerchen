extends SceneTree

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const TEST_SETTINGS_PATH: String = "user://task_226_settings_roundtrip.cfg"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_226 Main Menu Settings Shell Display Audio Input Gameplay ===")
	_test_game_settings_contract_roundtrip()
	await _test_main_menu_settings_shell()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_game_settings_contract_roundtrip() -> void:
	var settings: Dictionary = {
		"resolution_preset": "1600x900",
		"window_mode": "borderless",
		"vsync_enabled": false,
		"master_volume": 55.0,
		"music_volume": 44.0,
		"sfx_volume": 33.0,
		"fog_of_war_mode": "unexplored_blackout",
	}
	var save_error: int = int(GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", settings, TEST_SETTINGS_PATH))
	_assert(save_error == OK, "Game settings contract saves display, audio and gameplay values")
	var loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	_assert(String(loaded.get("resolution_preset", "")) == "1600x900", "Resolution preset roundtrips")
	_assert(String(loaded.get("window_mode", "")) == "borderless", "Window mode roundtrips")
	_assert(not bool(loaded.get("vsync_enabled", true)), "VSync flag roundtrips")
	_assert(is_equal_approx(float(loaded.get("master_volume", 0.0)), 55.0), "Master volume roundtrips")
	_assert(is_equal_approx(float(loaded.get("music_volume", 0.0)), 44.0), "Music volume roundtrips")
	_assert(is_equal_approx(float(loaded.get("sfx_volume", 0.0)), 33.0), "SFX volume roundtrips")
	_assert(String(loaded.get("fog_of_war_mode", "")) == "unexplored_blackout", "FoW mode roundtrips through central settings contract")
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", loaded))
	_assert(Dictionary(snapshot.get("display", {})).has("valid_window_modes"), "Display snapshot exposes window-mode choices")
	_assert(Dictionary(snapshot.get("audio", {})).has("music_volume"), "Audio snapshot exposes music volume")
	_assert(Array(Dictionary(snapshot.get("input", {})).get("actions", [])).size() >= 5, "Input snapshot exposes core action list")
	_assert(String(Dictionary(snapshot.get("gameplay", {})).get("fog_of_war_mode", "")) == "unexplored_blackout", "Gameplay snapshot carries FoW mode")


func _test_main_menu_settings_shell() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads for settings verifier")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	main_menu.call("set_settings_path_for_tests", TEST_SETTINGS_PATH)
	await process_frame
	main_menu.call("open_settings_panel")
	await process_frame
	_assert(bool(main_menu.call("is_settings_panel_visible")), "Settings panel opens from main menu")
	var ui_snapshot: Dictionary = Dictionary(main_menu.call("get_settings_ui_snapshot"))
	_assert(bool(ui_snapshot.get("display_section_visible", false)), "Settings UI exposes Display section")
	_assert(bool(ui_snapshot.get("audio_section_visible", false)), "Settings UI exposes Audio section")
	_assert(bool(ui_snapshot.get("input_section_visible", false)), "Settings UI exposes Input section")
	_assert(bool(ui_snapshot.get("gameplay_section_visible", false)), "Settings UI exposes Gameplay section")
	_assert(bool(ui_snapshot.get("apply_button_visible", false)) and bool(ui_snapshot.get("reset_button_visible", false)) and bool(ui_snapshot.get("cancel_button_visible", false)), "Settings UI exposes Apply, Reset and Cancel controls")
	var sections: Dictionary = Dictionary(ui_snapshot.get("sections", {}))
	_assert(Dictionary(sections.get("gameplay", {})).has("comic_bubbles"), "Settings UI includes comic bubble mode section")
	_assert(Dictionary(Dictionary(sections.get("gameplay", {})).get("fog_of_war", {})).has("valid_fog_of_war_modes"), "Settings UI includes FoW mode section")

	main_menu.call("set_draft_display_settings", "1600x900", "borderless", false)
	main_menu.call("set_draft_audio_settings", 55.0, 44.0, 33.0)
	main_menu.call("set_draft_fog_of_war_mode", "unexplored_blackout")
	main_menu.call("set_draft_comic_bubble_mode", "minimal")
	var apply_error: int = int(main_menu.call("apply_settings"))
	_assert(apply_error == OK, "Apply saves draft settings")
	var gameplay_loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	var bubble_loaded: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	_assert(String(gameplay_loaded.get("window_mode", "")) == "borderless", "Applied window mode is persisted")
	_assert(String(gameplay_loaded.get("fog_of_war_mode", "")) == "unexplored_blackout", "Applied FoW mode is persisted")
	_assert(String(bubble_loaded.get("mode", "")) == "minimal", "Applied comic bubble mode is persisted")

	main_menu.call("reset_settings_defaults")
	apply_error = int(main_menu.call("apply_settings"))
	_assert(apply_error == OK, "Reset Defaults can be applied")
	gameplay_loaded = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	bubble_loaded = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	_assert(String(gameplay_loaded.get("fog_of_war_mode", "")) == "known_terrain", "Reset restores default FoW mode")
	_assert(String(bubble_loaded.get("mode", "")) == "normal", "Reset restores default comic bubble mode")

	main_menu.call("open_settings_panel")
	main_menu.call("set_draft_fog_of_war_mode", "off")
	main_menu.call("cancel_settings_changes")
	await process_frame
	_assert(not bool(main_menu.call("is_settings_panel_visible")), "Cancel closes settings panel")
	gameplay_loaded = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", TEST_SETTINGS_PATH))
	_assert(String(gameplay_loaded.get("fog_of_war_mode", "")) == "known_terrain", "Cancel does not persist draft gameplay settings")
	_assert(main_menu.find_child("SimulationRoot", true, false) == null, "Opening settings does not create gameplay simulation state")
	main_menu.queue_free()
	await process_frame


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
