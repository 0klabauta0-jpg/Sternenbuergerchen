extends CanvasLayer

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const SETTINGS_SCREEN_SCRIPT: GDScript = preload("res://scripts/ui/settings_screen.gd")

const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/main_menu.tscn"
const DEFAULT_SAVE_PATH: String = "user://sternenbuergerchen_mission_shell_slot.cfg"
const MANUAL_SFX_SCENE_SCRIPTS: PackedStringArray = [
	"res://scripts/ui/main_menu_screen.gd",
	"res://scripts/ui/multiplayer_lobby_screen.gd",
]

var _settings_config_path: String = GAME_SETTINGS_CONTRACT_SCRIPT.CONFIG_PATH
var _mission_save_path: String = DEFAULT_SAVE_PATH
var _audio_event_bus = null
var _overlay_root: Control = null
var _menu_panel: PanelContainer = null
var _settings_panel: PanelContainer = null
var _status_label: Label = null
var _save_button: Button = null
var _load_button: Button = null
var _main_menu_button: Button = null
var _quit_button: Button = null
var _draft_settings: Dictionary = {}
var _slider_value_labels: Dictionary = {}
var _window_mode_option: OptionButton = null
var _test_mode: bool = false
var _quit_requested_for_tests: bool = false
var _last_loaded_scene_path: String = ""


func _ready() -> void:
	name = "GlobalEscapeMenu"
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_event_bus()
	_build_overlay()
	var tree := get_tree()
	if tree != null:
		if not tree.node_added.is_connected(_on_tree_node_added):
			tree.node_added.connect(_on_tree_node_added)
		call_deferred("_install_button_sfx_recursive", tree.root)


func _input(event: InputEvent) -> void:
	_handle_escape_input(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_escape_input(event)


func _handle_escape_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ESCAPE:
		return
	if is_settings_visible():
		_show_menu_panel()
	else:
		toggle_menu()
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func set_test_mode(enabled: bool) -> void:
	_test_mode = enabled
	_quit_requested_for_tests = false


func set_save_path_for_tests(path: String) -> void:
	var normalized_path: String = path.strip_edges()
	if not normalized_path.is_empty():
		_mission_save_path = normalized_path


func set_settings_path_for_tests(path: String) -> void:
	var normalized_path: String = path.strip_edges()
	if not normalized_path.is_empty():
		_settings_config_path = normalized_path


func open_menu(status_text: String = "") -> void:
	_ensure_overlay()
	_show_menu_panel()
	_refresh_action_buttons()
	_overlay_root.visible = true
	if not status_text.strip_edges().is_empty():
		_set_status(status_text)
	_play_ui_sfx("click", "escape_menu_open")


func close_menu() -> void:
	_ensure_overlay()
	_overlay_root.visible = false
	_play_ui_sfx("cancel", "escape_menu_close")


func toggle_menu() -> void:
	if is_menu_visible():
		close_menu()
	else:
		open_menu()


func is_menu_visible() -> bool:
	return _overlay_root != null and _overlay_root.visible and _menu_panel != null and _menu_panel.visible


func is_settings_visible() -> bool:
	return _overlay_root != null and _overlay_root.visible and _settings_panel != null and _settings_panel.visible


func open_settings() -> void:
	_ensure_overlay()
	_draft_settings = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path)).duplicate(true)
	_refresh_settings_controls()
	_menu_panel.visible = false
	_settings_panel.visible = true
	_overlay_root.visible = true
	_set_status("Einstellungen")
	_play_ui_sfx("click", "escape_settings_open")


func apply_settings_from_overlay() -> Dictionary:
	_draft_settings = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", _draft_settings))
	var save_error: int = int(GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", _draft_settings, _settings_config_path))
	if save_error != OK:
		_set_status("Settings failed")
		_play_ui_sfx("warning", "escape_settings_failed")
		return {"ok": false, "error": save_error}
	_apply_runtime_settings(_draft_settings)
	_set_status("Settings saved")
	_play_ui_sfx("confirm", "escape_settings_apply")
	return {"ok": true, "settings": _draft_settings.duplicate(true)}


func set_draft_audio_settings(master_volume: float, sfx_volume: float, ui_volume: float) -> void:
	_ensure_settings_draft()
	_draft_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_MASTER_VOLUME] = clampf(master_volume, 0.0, 100.0)
	_draft_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_SFX_VOLUME] = clampf(sfx_volume, 0.0, 100.0)
	_draft_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_UI_VOLUME] = clampf(ui_volume, 0.0, 100.0)
	_refresh_settings_controls()


func save_current_mission_slot() -> Dictionary:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	if current_scene == null:
		return _save_result(false, "no_current_scene")
	var scene_path: String = String(current_scene.scene_file_path).strip_edges()
	if scene_path.is_empty():
		return _save_result(false, "scene_path_missing")
	if scene_path == MAIN_MENU_SCENE_PATH:
		return _save_result(false, "main_menu_has_no_active_mission")
	var config := ConfigFile.new()
	config.set_value("mission_shell_slot", "scene_path", scene_path)
	config.set_value("mission_shell_slot", "scene_name", current_scene.name)
	config.set_value("mission_shell_slot", "saved_at_unix", Time.get_unix_time_from_system())
	config.set_value("mission_shell_slot", "save_kind", "scene_path_v1")
	var error: Error = config.save(_mission_save_path)
	if error != OK:
		return _save_result(false, "save_failed", error)
	_set_status("Mission slot saved")
	_refresh_action_buttons()
	return _save_result(true, "saved", OK, scene_path)


func load_mission_slot(change_scene: bool = true) -> Dictionary:
	var slot: Dictionary = get_save_slot_snapshot()
	if not bool(slot.get("exists", false)):
		return _load_result(false, "missing_save")
	var scene_path: String = String(slot.get("scene_path", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return _load_result(false, "missing_scene", scene_path)
	_last_loaded_scene_path = scene_path
	_set_status("Loading mission slot")
	_play_ui_sfx("confirm", "load_mission_slot")
	if change_scene and not _test_mode:
		var tree := get_tree()
		if tree != null:
			var error: Error = tree.change_scene_to_file(scene_path)
			if error != OK:
				return _load_result(false, "change_scene_failed", scene_path, error)
			_overlay_root.visible = false
	return _load_result(true, "loaded", scene_path)


func return_to_main_menu(change_scene: bool = true) -> Dictionary:
	_play_ui_sfx("cancel", "return_to_main_menu")
	if change_scene and not _test_mode:
		var tree := get_tree()
		if tree != null:
			var error: Error = tree.change_scene_to_file(MAIN_MENU_SCENE_PATH)
			if error != OK:
				return {"ok": false, "reason": "change_scene_failed", "error": error}
			_overlay_root.visible = false
	return {"ok": true, "target_scene": MAIN_MENU_SCENE_PATH}


func request_quit_game() -> Dictionary:
	_play_ui_sfx("cancel", "quit_game")
	if _test_mode:
		_quit_requested_for_tests = true
		_set_status("Quit requested")
		return {"ok": true, "test_mode": true}
	var tree := get_tree()
	if tree != null:
		tree.quit()
	return {"ok": true, "test_mode": false}


func was_quit_requested_for_tests() -> bool:
	return _quit_requested_for_tests


func get_save_slot_snapshot() -> Dictionary:
	var config := ConfigFile.new()
	var load_error: Error = config.load(_mission_save_path)
	if load_error != OK:
		return {"exists": false, "path": _mission_save_path, "load_error": load_error}
	return {
		"exists": true,
		"path": _mission_save_path,
		"scene_path": String(config.get_value("mission_shell_slot", "scene_path", "")).strip_edges(),
		"scene_name": String(config.get_value("mission_shell_slot", "scene_name", "")).strip_edges(),
		"saved_at_unix": int(config.get_value("mission_shell_slot", "saved_at_unix", 0)),
		"save_kind": String(config.get_value("mission_shell_slot", "save_kind", "")).strip_edges(),
	}


func get_shell_snapshot() -> Dictionary:
	return {
		"autoload": true,
		"menu_visible": is_menu_visible(),
		"settings_visible": is_settings_visible(),
		"has_resume": _has_button("ResumeButton"),
		"has_settings": _has_button("SettingsButton"),
		"has_save": _has_button("SaveMissionButton"),
		"has_load": _has_button("LoadMissionButton"),
		"has_main_menu": _has_button("MainMenuButton"),
		"has_quit": _has_button("QuitButton"),
		"save_slot": get_save_slot_snapshot(),
		"last_loaded_scene_path": _last_loaded_scene_path,
		"quit_requested_for_tests": _quit_requested_for_tests,
		"save_button_disabled": _save_button.disabled if _save_button != null else true,
		"load_button_disabled": _load_button.disabled if _load_button != null else true,
	}


func get_audio_sfx_debug_snapshot() -> Dictionary:
	var bus = _ensure_audio_event_bus()
	if bus != null and bus.has_method("get_diagnostic_snapshot"):
		return Dictionary(bus.call("get_diagnostic_snapshot")).duplicate(true)
	return {}


func is_button_sfx_installed(button: BaseButton) -> bool:
	return button != null and bool(button.get_meta("global_button_sfx_installed", false))


func _build_overlay() -> void:
	if _overlay_root != null:
		return
	_overlay_root = Control.new()
	_overlay_root.name = "GlobalEscapeOverlay"
	TACTICAL_UI_THEME_SCRIPT.apply_screen(_overlay_root)
	_overlay_root.set_meta("native_ui_screen_family", "escape_settings")
	_overlay_root.visible = false
	_overlay_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay_root)

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.014, 0.018, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay_root.add_child(shade)

	_menu_panel = _build_menu_panel()
	_overlay_root.add_child(_menu_panel)
	_settings_panel = _build_settings_panel()
	_settings_panel.visible = false
	_overlay_root.add_child(_settings_panel)
	_refresh_action_buttons()


func _build_menu_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "EscapeMenuPanel"
	panel.custom_minimum_size = Vector2(360.0, 430.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -180.0
	panel.offset_top = -215.0
	panel.offset_right = 180.0
	panel.offset_bottom = 215.0

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Spielmenü"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	_status_label = Label.new()
	_status_label.name = "StatusLabel"
	_status_label.text = "Escape · Einsätze laufen weiter"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_status_label)

	_add_menu_button(vbox, "ResumeButton", "Weiter", close_menu)
	_add_menu_button(vbox, "SettingsButton", "Einstellungen", open_settings)
	_save_button = _add_menu_button(vbox, "SaveMissionButton", "Mission speichern", _on_save_pressed)
	_load_button = _add_menu_button(vbox, "LoadMissionButton", "Mission laden", _on_load_pressed)
	_main_menu_button = _add_menu_button(vbox, "MainMenuButton", "Hauptmenue", _on_main_menu_pressed)
	_quit_button = _add_menu_button(vbox, "QuitButton", "Spiel beenden", request_quit_game)
	return panel


func _build_settings_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "EscapeSettingsPanel"
	panel.custom_minimum_size = Vector2(420.0, 390.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -210.0
	panel.offset_top = -195.0
	panel.offset_right = 210.0
	panel.offset_bottom = 195.0

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "SettingsVBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "SettingsTitleLabel"
	title.text = "Einstellungen"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_add_slider_row(vbox, GAME_SETTINGS_CONTRACT_SCRIPT.KEY_MASTER_VOLUME, "Master")
	_add_slider_row(vbox, GAME_SETTINGS_CONTRACT_SCRIPT.KEY_SFX_VOLUME, "SFX")
	_add_slider_row(vbox, GAME_SETTINGS_CONTRACT_SCRIPT.KEY_UI_VOLUME, "UI")

	var mode_label := Label.new()
	mode_label.text = "Fenstermodus"
	mode_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(mode_label)
	_window_mode_option = OptionButton.new()
	_window_mode_option.name = "WindowModeOptionButton"
	_window_mode_option.custom_minimum_size = Vector2(360.0, 36.0)
	vbox.add_child(_window_mode_option)
	if not _window_mode_option.item_selected.is_connected(_on_window_mode_selected):
		_window_mode_option.item_selected.connect(_on_window_mode_selected)

	var row := HBoxContainer.new()
	row.name = "SettingsActionRow"
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	_add_menu_button(row, "SettingsApplyButton", "Anwenden", _on_settings_apply_pressed, Vector2(136.0, 42.0))
	_add_menu_button(row, "SettingsBackButton", "Zurueck", _show_menu_panel, Vector2(136.0, 42.0))
	return panel


func _add_slider_row(parent: VBoxContainer, key: String, label_text: String) -> void:
	var row := HBoxContainer.new()
	row.name = "%sRow" % key.capitalize()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(74.0, 0.0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "%sSlider" % key.capitalize()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := Label.new()
	value_label.name = "%sValueLabel" % key.capitalize()
	value_label.custom_minimum_size = Vector2(42.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	_slider_value_labels[key] = value_label
	if not slider.value_changed.is_connected(_on_settings_slider_changed.bind(key)):
		slider.value_changed.connect(_on_settings_slider_changed.bind(key))


func _add_menu_button(parent: Control, button_name: String, text: String, callback: Callable, minimum_size: Vector2 = Vector2(320.0, 46.0)) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("global_button_sfx_force", true)
	parent.add_child(button)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	return button


func _show_menu_panel() -> void:
	_menu_panel.visible = true
	_settings_panel.visible = false
	_refresh_action_buttons()
	_set_status("Escape · Einsätze laufen weiter")


func _ensure_overlay() -> void:
	if _overlay_root == null:
		_build_overlay()


func _refresh_action_buttons() -> void:
	if _save_button != null:
		_save_button.disabled = not _can_save_current_scene()
		_save_button.tooltip_text = "" if not _save_button.disabled else "Im Hauptmenue gibt es noch keine laufende Mission zum Speichern."
	if _load_button != null:
		_load_button.disabled = not bool(get_save_slot_snapshot().get("exists", false))
	if _main_menu_button != null:
		_main_menu_button.disabled = _is_current_scene_main_menu()


func _refresh_settings_controls() -> void:
	_ensure_settings_draft()
	for key in [GAME_SETTINGS_CONTRACT_SCRIPT.KEY_MASTER_VOLUME, GAME_SETTINGS_CONTRACT_SCRIPT.KEY_SFX_VOLUME, GAME_SETTINGS_CONTRACT_SCRIPT.KEY_UI_VOLUME]:
		var slider := _settings_panel.find_child("%sSlider" % String(key).capitalize(), true, false) as HSlider
		var value: float = float(_draft_settings.get(key, 100.0))
		if slider != null:
			slider.set_value_no_signal(value)
		var value_label := _slider_value_labels.get(key, null) as Label
		if value_label != null:
			value_label.text = "%d" % int(round(value))
	if _window_mode_option != null:
		SETTINGS_SCREEN_SCRIPT.call(
			"configure_option_button",
			_window_mode_option,
			GAME_SETTINGS_CONTRACT_SCRIPT.VALID_WINDOW_MODES,
			String(_draft_settings.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_WINDOW_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_WINDOWED)),
			{
				GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_WINDOWED: "Fenster",
				GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_BORDERLESS: "Randlos",
				GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_FULLSCREEN: "Vollbild",
			}
		)


func _ensure_settings_draft() -> void:
	if _draft_settings.is_empty():
		_draft_settings = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path)).duplicate(true)


func _on_settings_slider_changed(value: float, key: String) -> void:
	_ensure_settings_draft()
	_draft_settings[key] = clampf(value, 0.0, 100.0)
	var value_label := _slider_value_labels.get(key, null) as Label
	if value_label != null:
		value_label.text = "%d" % int(round(value))
	_set_status("Settings changed")


func _on_window_mode_selected(index: int) -> void:
	if _window_mode_option == null or index < 0 or index >= _window_mode_option.item_count:
		return
	_ensure_settings_draft()
	_draft_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_WINDOW_MODE] = String(_window_mode_option.get_item_metadata(index))
	_set_status("Settings changed")


func _on_settings_apply_pressed() -> void:
	apply_settings_from_overlay()


func _on_save_pressed() -> void:
	var result: Dictionary = save_current_mission_slot()
	_play_ui_sfx("confirm" if bool(result.get("ok", false)) else "warning", "save_mission_slot")
	_set_status("Mission saved" if bool(result.get("ok", false)) else "Save not available")


func _on_load_pressed() -> void:
	var result: Dictionary = load_mission_slot()
	if not bool(result.get("ok", false)):
		_play_ui_sfx("warning", "load_mission_slot_failed")
		_set_status("Load not available")


func _on_main_menu_pressed() -> void:
	return_to_main_menu()


func _can_save_current_scene() -> bool:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	if current_scene == null:
		return false
	var scene_path: String = String(current_scene.scene_file_path).strip_edges()
	return not scene_path.is_empty() and scene_path != MAIN_MENU_SCENE_PATH


func _is_current_scene_main_menu() -> bool:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	return current_scene != null and String(current_scene.scene_file_path).strip_edges() == MAIN_MENU_SCENE_PATH


func _save_result(ok: bool, reason: String, error: int = OK, scene_path: String = "") -> Dictionary:
	return {"ok": ok, "reason": reason, "error": error, "scene_path": scene_path, "path": _mission_save_path}


func _load_result(ok: bool, reason: String, scene_path: String = "", error: int = OK) -> Dictionary:
	return {"ok": ok, "reason": reason, "error": error, "scene_path": scene_path, "path": _mission_save_path}


func _apply_runtime_settings(settings: Dictionary) -> void:
	var normalized_settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", settings))
	var bus = _ensure_audio_event_bus()
	if bus != null and bus.has_method("apply_settings"):
		bus.call("apply_settings", normalized_settings)
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(normalized_settings.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_VSYNC_ENABLED, true)) else DisplayServer.VSYNC_DISABLED)
	var window_mode: String = String(normalized_settings.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_WINDOW_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_WINDOWED))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, window_mode == GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_BORDERLESS)
	if window_mode == GAME_SETTINGS_CONTRACT_SCRIPT.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var resolution: Vector2i = _parse_resolution_preset(String(normalized_settings.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_RESOLUTION_PRESET, "1920x1080")))
		if resolution.x > 0 and resolution.y > 0:
			DisplayServer.window_set_size(resolution)


func _parse_resolution_preset(resolution_preset: String) -> Vector2i:
	var parts: PackedStringArray = resolution_preset.split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(maxi(int(parts[0]), 0), maxi(int(parts[1]), 0))


func _install_button_sfx_recursive(node: Node) -> void:
	if node == null:
		return
	var button := node as BaseButton
	if button != null:
		_install_button_sfx(button)
	for child in node.get_children():
		_install_button_sfx_recursive(child)


func _on_tree_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button != null:
		_install_button_sfx(button)


func _install_button_sfx(button: BaseButton) -> void:
	if button == null or bool(button.get_meta("global_button_sfx_installed", false)):
		return
	if not bool(button.get_meta("global_button_sfx_force", false)) and _is_button_inside_manual_sfx_scene(button):
		return
	button.set_meta("global_button_sfx_installed", true)
	button.pressed.connect(_on_global_button_pressed.bind(button))


func _on_global_button_pressed(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	var action_id: String = String(button.get_meta("ui_sfx_action_id", button.name)).strip_edges()
	if action_id.is_empty():
		action_id = "button"
	_play_ui_sfx("click", "global:%s" % action_id)


func _is_button_inside_manual_sfx_scene(button: BaseButton) -> bool:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	if current_scene == null:
		return false
	if button != current_scene and not current_scene.is_ancestor_of(button):
		return false
	var script := current_scene.get_script() as Script
	var script_path: String = script.resource_path if script != null else ""
	return MANUAL_SFX_SCENE_SCRIPTS.has(script_path)


func _ensure_audio_event_bus():
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus):
		return _audio_event_bus
	var tree := get_tree()
	if tree != null:
		var root_bus := tree.root.find_child("AudioEventBus", true, false)
		if root_bus != null and root_bus.has_method("emit_ui_action"):
			_audio_event_bus = root_bus
			return _audio_event_bus
	_audio_event_bus = AUDIO_EVENT_BUS_SCRIPT.new()
	_audio_event_bus.name = "AudioEventBus"
	add_child(_audio_event_bus)
	if _audio_event_bus.has_method("initialize"):
		_audio_event_bus.call("initialize", "res://data/audio_sfx_catalog.json", GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path))
	return _audio_event_bus


func _play_ui_sfx(action_type: String, action_id: String) -> void:
	var bus = _ensure_audio_event_bus()
	if bus == null or not bus.has_method("emit_ui_action"):
		return
	bus.call("emit_ui_action", action_type, {
		"action_id": action_id,
		"unit_id": "global_escape_menu",
		"dedupe_key": "global_escape_menu:%s" % action_id,
		"dedupe_window_msec": 40,
		"cooldown_msec": 0,
		"polyphony_limit": 4,
	})


func _set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text


func _has_button(button_name: String) -> bool:
	return _overlay_root != null and _overlay_root.find_child(button_name, true, false) != null
