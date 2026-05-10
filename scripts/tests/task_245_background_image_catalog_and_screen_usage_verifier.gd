extends SceneTree

const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const CATALOG_PATH: String = "res://data/background_image_catalog.json"
const DOC_PATH: String = "res://docs/assets/background_image_catalog.md"
const MANUAL_CHECK_PATH: String = "res://docs/manual_checks/background_screen_readability_checklist.md"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const MULTIPLAYER_LOBBY_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"

const REQUIRED_BACKGROUNDS: Dictionary = {
	"multiplayer_lobby_hangar": "res://Assets/used/backgrounds/ai_generated/bg_hangar_shiphall.png",
	"mission_select_desert_outpost": "res://Assets/used/backgrounds/ai_generated/bg_desert_outpost.png",
	"loading_asteroid_flight": "res://Assets/used/backgrounds/ai_generated/bg_asteroid_flight.png",
	"debrief_desert_explosion_base": "res://Assets/used/backgrounds/ai_generated/bg_desert_explosion_base.jpg",
}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_245 Background Image Catalog and Screen Usage Verifier ===")
	_test_imported_background_files()
	_test_background_catalog()
	await _test_main_menu_catalog_usage()
	await _test_multiplayer_lobby_background_usage()
	_test_documentation_and_local_path_gate()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_imported_background_files() -> void:
	for background_id in REQUIRED_BACKGROUNDS.keys():
		var path: String = String(REQUIRED_BACKGROUNDS[background_id])
		_assert(FileAccess.file_exists(path), "Background file exists: %s" % background_id)
		_assert(FileAccess.file_exists(path + ".import"), "Background import metadata exists: %s" % background_id)
		_assert(path.begins_with("res://Assets/used/backgrounds/ai_generated/"), "Background is under used/ai_generated: %s" % background_id)
		_assert(not path.contains(" "), "Background path uses stable ASCII filename: %s" % background_id)
		var texture := ResourceLoader.load(path) as Texture2D
		_assert(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "Background loads as Texture2D: %s" % background_id)
		if texture != null:
			_assert(texture.get_width() <= 2048 and texture.get_height() <= 2048, "Background fits UI texture budget: %s" % background_id)


func _test_background_catalog() -> void:
	_assert(FileAccess.file_exists(CATALOG_PATH), "Background catalog JSON exists")
	var loaded: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("load_catalog"))
	var backgrounds: Dictionary = Dictionary(loaded.get("backgrounds", {}))
	_assert(int(loaded.get("schema_version", 0)) == 1, "Background catalog schema is versioned")
	_assert(backgrounds.size() >= 5, "Background catalog includes new images and existing main menu image")
	_assert(PackedStringArray(loaded.get("diagnostics", PackedStringArray())).is_empty(), "Background catalog has no diagnostics")
	for background_id in REQUIRED_BACKGROUNDS.keys():
		var entry: Dictionary = Dictionary(backgrounds.get(background_id, {}))
		_assert(not entry.is_empty(), "Catalog has stable ID: %s" % background_id)
		_assert(String(entry.get("res_path", "")) == String(REQUIRED_BACKGROUNDS[background_id]), "Catalog path matches copied project asset: %s" % background_id)
		_assert(float(entry.get("dim_strength", 0.0)) >= 0.45, "Catalog defines readable dim strength: %s" % background_id)
		_assert(Array(entry.get("screen_hint", [])).size() > 0, "Catalog defines screen hints: %s" % background_id)
	var screen_snapshot: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("build_screen_assignment_snapshot"))
	var assignments: Dictionary = Dictionary(screen_snapshot.get("screen_assignments", {}))
	_assert(bool(screen_snapshot.get("res_only_no_local_user_paths", false)), "Catalog paths are res:// only")
	_assert(Array(assignments.get("multiplayer_lobby", [])).has("multiplayer_lobby_hangar"), "Catalog maps hangar background to multiplayer lobby")
	_assert(Array(assignments.get("debrief", [])).has("debrief_desert_explosion_base"), "Catalog maps explosion background to debrief")


func _test_main_menu_catalog_usage() -> void:
	var packed_scene := ResourceLoader.load(MAIN_MENU_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Main menu scene loads for background catalog verifier")
	if packed_scene == null:
		return
	var main_menu := packed_scene.instantiate()
	root.add_child(main_menu)
	await process_frame
	var catalog_snapshot: Dictionary = Dictionary(main_menu.call("get_background_catalog_snapshot"))
	var background := main_menu.get_node_or_null("Background") as TextureRect
	_assert(String(catalog_snapshot.get("background_id", "")) == "main_menu_shell", "Main menu exposes catalog background ID")
	_assert(String(catalog_snapshot.get("path", "")) == "res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg", "Main menu keeps TASK_199 preferred background")
	_assert(bool(catalog_snapshot.get("uses_catalog", false)), "Main menu uses background catalog")
	_assert(background != null and background.texture != null, "Main menu background TextureRect has a texture")
	main_menu.queue_free()
	await process_frame


func _test_multiplayer_lobby_background_usage() -> void:
	var packed_scene := ResourceLoader.load(MULTIPLAYER_LOBBY_SCENE_PATH) as PackedScene
	_assert(packed_scene != null, "Multiplayer lobby scene loads for background catalog verifier")
	if packed_scene == null:
		return
	var lobby := packed_scene.instantiate()
	root.add_child(lobby)
	await process_frame
	var ui_snapshot: Dictionary = Dictionary(lobby.call("get_lobby_ui_snapshot"))
	var background_snapshot: Dictionary = Dictionary(ui_snapshot.get("background", {}))
	var background := lobby.get_node_or_null("Background") as TextureRect
	var shade := lobby.get_node_or_null("BackgroundShade") as ColorRect
	_assert(String(background_snapshot.get("background_id", "")) == "multiplayer_lobby_hangar", "Lobby exposes hangar background ID")
	_assert(String(background_snapshot.get("path", "")) == String(REQUIRED_BACKGROUNDS["multiplayer_lobby_hangar"]), "Lobby background path comes from catalog")
	_assert(bool(background_snapshot.get("uses_catalog", false)), "Lobby uses background catalog")
	_assert(bool(background_snapshot.get("has_texture", false)), "Lobby background texture is loaded")
	_assert(background != null and background.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Lobby background uses covered crop")
	_assert(shade != null and shade.color.a >= 0.5, "Lobby applies dim overlay for readability")
	_assert(lobby.find_child("SimulationRoot", true, false) == null, "Lobby background does not create gameplay simulation state")
	lobby.queue_free()
	await process_frame


func _test_documentation_and_local_path_gate() -> void:
	_assert(FileAccess.file_exists(DOC_PATH), "Background catalog documentation exists")
	_assert(FileAccess.file_exists(MANUAL_CHECK_PATH), "Background readability manual checklist exists")
	var doc_text: String = _read_text(DOC_PATH)
	_assert(doc_text.contains("multiplayer_lobby_hangar"), "Background docs include lobby hangar ID")
	_assert(doc_text.contains("Readability Rules"), "Background docs include readability rules")
	var forbidden_patterns: PackedStringArray = PackedStringArray([
		"C:" + "\\" + "Users" + "\\",
		"C:" + "/" + "Users" + "/",
		"file:///" + "C:" + "/" + "Users" + "/",
	])
	var scan_paths: PackedStringArray = PackedStringArray([
		CATALOG_PATH,
		DOC_PATH,
		"res://scripts/assets/background_image_catalog.gd",
		"res://scripts/ui/main_menu_screen.gd",
		"res://scripts/ui/multiplayer_lobby_screen.gd",
	])
	var offenders: PackedStringArray = PackedStringArray()
	for path in scan_paths:
		var text: String = _read_text(path)
		for pattern in forbidden_patterns:
			if text.contains(pattern):
				offenders.append("%s contains %s" % [path, pattern])
	_assert(offenders.is_empty(), "Background runtime files do not reference local user image paths")


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
