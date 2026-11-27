extends SceneTree

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const BACKGROUND_PATH: String = "res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg"
const README_PATH: String = "res://Assets/curated/main_menu/README.md"
const MAIN_MENU_SCRIPT_PATH: String = "res://scripts/ui/main_menu_screen.gd"
const PROJECT_PATH: String = "res://project.godot"
const EXPECTED_ROUTES: Dictionary = {
	"singleplayer": "res://scenes/meta/meta_layer_test.tscn",
	"multiplayer": "res://scenes/ui/multiplayer_lobby.tscn",
	"editor": "res://scenes/editor/map_editor.tscn",
	"settings": "local_settings_panel",
}
const BUTTON_PATHS: Dictionary = {
	"singleplayer": "MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton",
	"multiplayer": "MenuRail/MenuMargin/MenuVBox/MenuButtons/FreePlaySubMenu/MultiplayerButton",
	"editor": "MenuRail/MenuMargin/MenuVBox/MenuButtons/EditorButton",
	"settings": "MenuRail/MenuMargin/MenuVBox/MenuButtons/SettingsButton",
}
const BUTTON_TEXTS: Dictionary = {
	"singleplayer": "Gefecht",
	"multiplayer": "Mehrspieler",
	"editor": "Editor",
	"settings": "Einstellungen",
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_199 Main Menu Shell Background Image Verifier ===")
	_test_background_asset()
	await _test_main_menu_scene_and_buttons()
	_test_project_main_scene()
	_test_no_local_image_path_in_runtime_files()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_background_asset() -> void:
	_assert(FileAccess.file_exists(BACKGROUND_PATH), "Main menu background asset exists in project")
	_assert(FileAccess.file_exists(BACKGROUND_PATH + ".import"), "Main menu background has Godot import metadata")
	_assert(FileAccess.file_exists(README_PATH), "Main menu background README exists")
	var texture := ResourceLoader.load(BACKGROUND_PATH)
	_assert(texture is Texture2D, "Main menu background loads as Texture2D")
	_assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Main menu background has dimensions")
	_assert(not BACKGROUND_PATH.contains(" "), "Main menu background path uses stable ASCII-style filename")


func _test_main_menu_scene_and_buttons() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene is loadable")
	if packed_scene == null:
		return
	var screen := packed_scene.instantiate() as Control
	_assert(screen != null, "Main menu scene instantiates as Control")
	if screen == null:
		return
	get_root().add_child(screen)
	await process_frame
	_assert(bool(screen.get_meta("main_menu_shell", false)), "Main menu marks itself as app shell")
	_assert(screen.custom_minimum_size == Vector2(1920, 1080), "Main menu targets a fixed FullHD first layout")
	var background := screen.get_node_or_null("Background") as TextureRect
	_assert(background != null and background.texture != null, "Main menu has a textured background node")
	_assert(background != null and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Background uses covered aspect crop")
	_assert(String(screen.call("get_background_path")) == BACKGROUND_PATH, "Main menu exposes the project background path")
	var routes: Dictionary = Dictionary(screen.call("get_route_snapshot"))
	for route_id in EXPECTED_ROUTES.keys():
		_assert(String(routes.get(route_id, "")) == String(EXPECTED_ROUTES[route_id]), "Route '%s' points to the expected target" % String(route_id))
		var button := screen.get_node_or_null(String(BUTTON_PATHS[route_id])) as Button
		_assert(button != null, "Menu button '%s' exists" % String(route_id))
		if button != null:
			_assert(button.visible, "Menu button '%s' is visible" % String(route_id))
			_assert(button.text == String(BUTTON_TEXTS[route_id]), "Menu button '%s' has expected label" % String(route_id))
			_assert(button.pressed.get_connections().size() > 0, "Menu button '%s' is clickable" % String(route_id))
			_assert(String(button.get_meta("route", "")) == String(EXPECTED_ROUTES[route_id]), "Menu button '%s' carries route metadata" % String(route_id))
	for route_id in ["singleplayer", "multiplayer", "editor"]:
		var scene_path: String = String(routes.get(route_id, ""))
		_assert(ResourceLoader.exists(scene_path), "Route scene exists for '%s'" % route_id)
		_assert(ResourceLoader.load(scene_path) is PackedScene, "Route scene loads as PackedScene for '%s'" % route_id)
	_assert(bool(routes.get("multiplayer_lobby", false)), "Multiplayer route is explicitly marked as product lobby flow")
	_assert(not bool(screen.call("is_settings_panel_visible")), "Settings panel starts closed")
	screen.call("open_settings_panel")
	await process_frame
	_assert(bool(screen.call("is_settings_panel_visible")), "Settings panel opens locally")
	screen.call("close_settings_panel")
	await process_frame
	_assert(not bool(screen.call("is_settings_panel_visible")), "Settings panel closes locally")
	_assert(screen.find_child("SimulationRoot", true, false) == null, "Main menu does not create gameplay simulation state")
	screen.queue_free()


func _test_project_main_scene() -> void:
	var project_text: String = _read_text_file(PROJECT_PATH)
	_assert(project_text.contains('run/main_scene="%s"' % MAIN_MENU_SCENE_PATH), "project.godot starts at the main menu scene")


func _test_no_local_image_path_in_runtime_files() -> void:
	var files_to_scan: PackedStringArray = [
		MAIN_MENU_SCRIPT_PATH,
		MAIN_MENU_SCENE_PATH,
		PROJECT_PATH,
		README_PATH,
	]
	var forbidden_patterns: PackedStringArray = [
		"C:" + "\\" + "Users" + "\\",
		"C:" + "/" + "Users" + "/",
		"file:///" + "C:" + "/" + "Users" + "/",
	]
	var offenders: PackedStringArray = PackedStringArray()
	for file_path in files_to_scan:
		var text: String = _read_text_file(file_path)
		for pattern in forbidden_patterns:
			if text.contains(pattern):
				offenders.append(file_path)
				break
	_assert(offenders.is_empty(), "Main menu runtime files do not reference the local image source")


func _read_text_file(path: String) -> String:
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
