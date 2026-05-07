extends SceneTree

const SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const SETTINGS_SCREEN_SCRIPT: GDScript = preload("res://scripts/ui/settings_screen.gd")
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

const SERVICE_PATH: String = "res://scripts/ui/contextual_help_service.gd"
const POPUP_PATH: String = "res://scripts/ui/contextual_help_popup.gd"
const CATALOG_PATH: String = "res://data/contextual_help_catalog.json"
const TASK_PATH: String = "res://docs/tasks/TASK_264_contextual_help_popup_component_settings_toggle.md"
const SETTINGS_TEST_PATH: String = "user://task_264_contextual_help_settings.cfg"
const MAIN_MENU_SETTINGS_TEST_PATH: String = "user://task_264_main_menu_settings.cfg"

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_264 Contextual Help Popup Component Settings Toggle ===")
	_test_files_exist()
	_test_settings_contract()
	_test_service_catalog_and_timing()
	await _test_popup_layout_and_wrapping()
	await _test_main_menu_settings_and_global_button()
	_test_task_status()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_files_exist() -> void:
	_assert(FileAccess.file_exists(SERVICE_PATH), "ContextualHelpService script exists")
	_assert(FileAccess.file_exists(POPUP_PATH), "ContextualHelpPopup script exists")
	_assert(FileAccess.file_exists(CATALOG_PATH), "Contextual help catalog exists")


func _test_settings_contract() -> void:
	var defaults: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("get_default_settings"))
	_assert(String(defaults.get("contextual_help_mode", "")) == "compact", "Default contextual help mode is compact")
	var normalized: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", {
		"contextual_help_mode": "expanded",
	}))
	_assert(String(normalized.get("contextual_help_mode", "")) == "expanded", "Expanded contextual help mode normalizes")
	normalized = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", {
		"contextual_help_mode": "nervous",
	}))
	_assert(String(normalized.get("contextual_help_mode", "")) == "compact", "Invalid contextual help mode falls back to compact")
	var save_error: int = int(GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", {
		"contextual_help_mode": "off",
	}, SETTINGS_TEST_PATH))
	_assert(save_error == OK, "Contextual help setting saves")
	var loaded: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", SETTINGS_TEST_PATH))
	_assert(String(loaded.get("contextual_help_mode", "")) == "off", "Contextual help setting loads")
	var snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", loaded))
	var gameplay_snapshot: Dictionary = Dictionary(snapshot.get("gameplay", {}))
	_assert(Array(snapshot.get("valid_contextual_help_modes", [])).has("expanded"), "Settings snapshot lists contextual help modes")
	_assert(String(gameplay_snapshot.get("contextual_help_mode", "")) == "off", "Gameplay snapshot exposes contextual help mode")
	var section_snapshot: Dictionary = Dictionary(SETTINGS_SCREEN_SCRIPT.call("build_section_snapshot", loaded, COMIC_BUBBLE_SETTINGS_SCRIPT.call("get_default_settings")))
	var gameplay_section: Dictionary = Dictionary(section_snapshot.get("gameplay", {}))
	var help_section: Dictionary = Dictionary(gameplay_section.get("contextual_help", {}))
	_assert(String(help_section.get("mode", "")) == "off", "Settings screen section exposes contextual help mode")
	_assert(Array(help_section.get("valid_modes", [])).has("compact"), "Settings screen section lists contextual help modes")


func _test_service_catalog_and_timing() -> void:
	var service = SERVICE_SCRIPT.new()
	_assert(int(service.call("load_catalog", CATALOG_PATH)) == OK, "Service loads catalog")
	var diagnostic: Dictionary = Dictionary(service.call("get_diagnostic_snapshot"))
	_assert(bool(diagnostic.get("catalog_loaded", false)), "Service diagnostic marks catalog loaded")
	_assert(int(diagnostic.get("entry_count", 0)) >= 16, "Service indexed catalog entries")
	service.call("set_help_mode", "compact")
	_assert(String(service.call("resolve_help_level", 0.2, false)) == "none", "Compact help waits before opening")
	_assert(String(service.call("resolve_help_level", 0.45, false)) == "compact", "Compact help opens after short delay")
	_assert(String(service.call("resolve_help_level", 3.5, false)) == "compact", "Compact mode does not auto-expand detail")
	service.call("set_help_mode", "expanded")
	_assert(String(service.call("resolve_help_level", 3.5, false)) == "detail", "Expanded mode opens detail after long delay")
	_assert(String(service.call("resolve_help_level", 0.0, true)) == "detail", "Pinned help opens detail immediately")
	service.call("set_global_help_active", true)
	_assert(String(service.call("resolve_help_level", 0.0, false)) == "compact", "Global help mode opens compact help immediately")
	var payload: Dictionary = Dictionary(service.call("request_help", "loadout.weight", 4.0, false))
	_assert(String(payload.get("level", "")) == "detail", "Service returns detail payload in expanded mode")
	_assert(Array(payload.get("compact_lines", [])).size() >= 1, "Service returns compact lines")
	_assert(Array(payload.get("detail_lines", [])).size() >= 1, "Service returns detail lines separately")
	service.call("request_help", "missing.help_id", 4.0, false)
	diagnostic = Dictionary(service.call("get_diagnostic_snapshot"))
	_assert(int(diagnostic.get("missing_id_count", 0)) >= 1, "Service diagnoses missing help IDs")
	service.call("set_help_mode", "off")
	payload = Dictionary(service.call("request_help", "loadout.weight", 4.0, false))
	_assert(String(payload.get("level", "")) == "none" and bool(payload.get("disabled", false)), "Service respects off mode")


func _test_popup_layout_and_wrapping() -> void:
	var service = SERVICE_SCRIPT.new()
	service.call("load_catalog", CATALOG_PATH)
	service.call("set_help_mode", "expanded")
	var popup: Control = POPUP_SCRIPT.new()
	root.add_child(popup)
	await process_frame
	var detail_payload: Dictionary = Dictionary(service.call("request_help", "mission_hud.command_matrix", 4.0, false))
	popup.call("show_help", detail_payload, Rect2(1840.0, 1000.0, 48.0, 48.0), Vector2(1920.0, 1080.0), true)
	var detail_snapshot: Dictionary = Dictionary(popup.call("get_diagnostic_snapshot"))
	_assert(bool(detail_snapshot.get("visible", false)), "Popup becomes visible with valid payload")
	_assert(String(detail_snapshot.get("help_id", "")) == "mission_hud.command_matrix", "Popup stores active help ID")
	_assert(bool(detail_snapshot.get("detail_visible", false)), "Popup can show detail area")
	_assert(_rect_inside_viewport(Rect2(popup.position, popup.size), Vector2(1920.0, 1080.0)), "Detail popup stays inside viewport")
	_assert(popup.size.x <= 460.0, "Detail popup respects max width")
	_assert(popup.size.y <= 1080.0 * 0.45, "Detail popup respects max viewport height")
	_assert(int(detail_snapshot.get("compact_autowrap", 0)) == TextServer.AUTOWRAP_WORD_SMART, "Compact label wraps text")
	service.call("set_help_mode", "compact")
	var compact_payload: Dictionary = Dictionary(service.call("request_help", "shell.global_help_button", 1.0, false))
	popup.call("show_help", compact_payload, Rect2(24.0, 24.0, 44.0, 44.0), Vector2(1280.0, 720.0), false)
	_assert(popup.size.x <= 360.0, "Compact popup respects max width")
	_assert(_rect_inside_viewport(Rect2(popup.position, popup.size), Vector2(1280.0, 720.0)), "Compact popup stays inside viewport")
	popup.call("hide_help")
	_assert(not popup.visible, "Popup hides without leaving stale help visible")
	popup.queue_free()


func _test_main_menu_settings_and_global_button() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	root.add_child(menu)
	await process_frame
	menu.call("set_settings_path_for_tests", MAIN_MENU_SETTINGS_TEST_PATH)
	menu.call("set_contextual_help_mode", "expanded")
	await process_frame
	var help_snapshot: Dictionary = Dictionary(menu.call("get_contextual_help_snapshot"))
	var service_snapshot: Dictionary = Dictionary(help_snapshot.get("service", {}))
	_assert(bool(service_snapshot.get("catalog_loaded", false)), "Main menu help service loads catalog")
	_assert(String(service_snapshot.get("help_mode", "")) == "expanded", "Main menu service follows setting")
	_assert(bool(help_snapshot.get("global_button_visible", false)), "Global help button is visible")
	_assert(String(help_snapshot.get("global_button_help_id", "")) == "shell.global_help_button", "Global help button has help_id")
	var global_button := menu.get_node_or_null("GlobalHelpButton") as Button
	_assert(global_button != null and global_button.pressed.get_connections().size() >= 1, "Global help button has pressed callback")
	var contextual_option := menu.get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/ContextualHelpModeOptionButton") as OptionButton
	_assert(contextual_option != null and contextual_option.item_count == 3, "Settings UI exposes three contextual help modes")
	_assert(String(contextual_option.get_meta("help_id", "")) == "settings.contextual_help_mode", "Contextual help option has help_id")
	var fog_option := menu.get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/FogOfWarModeOptionButton") as OptionButton
	_assert(String(fog_option.get_meta("help_id", "")) == "settings.fog_of_war_mode", "Fog of war option has help_id")
	if global_button != null:
		global_button.pressed.emit()
		await process_frame
	help_snapshot = Dictionary(menu.call("get_contextual_help_snapshot"))
	var popup_snapshot: Dictionary = Dictionary(help_snapshot.get("popup", {}))
	_assert(bool(popup_snapshot.get("visible", false)), "Global help button can open popup")
	_assert(String(popup_snapshot.get("help_id", "")) == "shell.global_help_button", "Global help popup uses shell help ID")
	menu.call("set_contextual_help_mode", "off")
	await process_frame
	help_snapshot = Dictionary(menu.call("get_contextual_help_snapshot"))
	service_snapshot = Dictionary(help_snapshot.get("service", {}))
	_assert(not bool(service_snapshot.get("help_enabled", true)), "Off mode disables contextual help service")
	menu.queue_free()


func _test_task_status() -> void:
	var task_text: String = _read_text(TASK_PATH)
	_assert(task_text.contains("## Status: IMPLEMENTIERT"), "TASK_264 is marked implemented")
	_assert(not task_text.contains("- [ ]"), "TASK_264 checklist is complete")


func _rect_inside_viewport(rect: Rect2, viewport_size: Vector2) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  PASS: %s" % message)
	else:
		_failed += 1
		print("  FAIL: %s" % message)
