extends CanvasLayer

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const HELP_SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
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
var _controls_panel: PanelContainer = null
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
var _modal_open: bool = false
var _previous_focus: WeakRef = null
var _suspended_input: Dictionary = {}
var _panel_focus_controls: Array[Control] = []
var _resume_label: Label
var _exit_panel: PanelContainer
var _exit_label: Label
var _exit_save: Button
var _exit_confirm: Button
var _exit_action := ""
var _exit_change_scene := true
var _quit_tree: SceneTree
var _quit_window: Window
var _owns_window_close := false
var _previous_auto_accept_quit := true


func _ready() -> void:
	name = "GlobalEscapeMenu"
	layer = 1000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_quick_save_action()
	_install_window_close_guard()
	_ensure_audio_event_bus()
	_build_overlay()
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)
	var tree := get_tree()
	if tree != null:
		if not tree.node_added.is_connected(_on_tree_node_added):
			tree.node_added.connect(_on_tree_node_added)
		call_deferred("_install_button_sfx_recursive", tree.root)


func _install_window_close_guard() -> void:
	var tree := get_tree()
	# Only the actual autoload owns the main window. Standalone UI fixtures or
	# embedded menu instances must not replace the application's quit policy.
	if _owns_window_close or tree == null or tree.root.get_node_or_null("GlobalEscapeMenu") != self:
		return
	_quit_tree = tree
	_quit_window = tree.root
	_previous_auto_accept_quit = tree.auto_accept_quit
	tree.auto_accept_quit = false
	_quit_window.close_requested.connect(_on_window_close_requested)
	_owns_window_close = true


func _on_window_close_requested() -> void:
	request_quit_game()


func _exit_tree() -> void:
	if not _owns_window_close:
		return
	if is_instance_valid(_quit_window) and _quit_window.close_requested.is_connected(_on_window_close_requested):
		_quit_window.close_requested.disconnect(_on_window_close_requested)
	# Restore our prior option only while our installed value remains in force.
	if is_instance_valid(_quit_tree) and not _quit_tree.auto_accept_quit:
		_quit_tree.auto_accept_quit = _previous_auto_accept_quit
	_owns_window_close = false
	_quit_tree = null
	_quit_window = null


const QUICK_SAVE_ACTION := "campaign_quick_save"

## Speichern, erster Teil / 21.11. (S3): neue Eingabeaktion, Standardtaste F5. Sie steht in der Tastenliste (Kartensteuerung).
func _ensure_quick_save_action() -> void:
	if not InputMap.has_action(QUICK_SAVE_ACTION):
		InputMap.add_action(QUICK_SAVE_ACTION, 0.2)
	if InputMap.action_get_events(QUICK_SAVE_ACTION).is_empty():
		var event := InputEventKey.new()
		event.keycode = KEY_F5
		event.physical_keycode = KEY_F5
		InputMap.action_add_event(QUICK_SAVE_ACTION, event)


## Taste F5 speichert die Kampagne wie der Menuepunkt "Kampagne speichern" (dieselbe Funktion _on_save_pressed, also auch
## "vorgemerkt", wenn es gerade nicht geht). Nur in der Kampagne, nicht in einer Texteingabe, nicht in der Nachfrage beim Beenden,
## nicht bei Tastenwiederholung. Gibt wahr zurueck, wenn die Taste verbraucht wurde.
func _handle_quick_save_input(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	if not key_event.is_action_pressed(QUICK_SAVE_ACTION, false):
		return false
	if _is_scene_loading():
		# Waehrend eines Szenenwechsels wird nichts gespeichert (die Szene wird gerade ersetzt).
		var loading_viewport := get_viewport()
		if loading_viewport != null:
			loading_viewport.set_input_as_handled()
		return true
	if not _is_campaign_context():
		return false
	var viewport := get_viewport()
	var focus: Control = viewport.gui_get_focus_owner() if viewport != null else null
	if focus is LineEdit or focus is TextEdit:
		return false
	if _exit_panel != null and _exit_panel.is_visible_in_tree():
		return false
	_on_save_pressed()
	if viewport != null:
		viewport.set_input_as_handled()
	return true


func _input(event: InputEvent) -> void:
	if _handle_quick_save_input(event):
		return
	_handle_escape_input(event)
	if not _modal_open or not event is InputEventKey:
		return
	if event.pressed and event.keycode == KEY_TAB and not _panel_focus_controls.is_empty():
		var index := _panel_focus_controls.find(get_viewport().gui_get_focus_owner())
		index = posmod(index + (-1 if event.shift_pressed else 1), _panel_focus_controls.size())
		_panel_focus_controls[index].grab_focus()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	_handle_escape_input(event)


func _handle_escape_input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_ESCAPE:
		return
	if _is_scene_loading():
		# Das Spielmenue soll nicht ueber dem Ladebild aufgehen.
		var loading_viewport := get_viewport()
		if loading_viewport != null:
			loading_viewport.set_input_as_handled()
		return
	if _exit_panel != null and _exit_panel.is_visible_in_tree():
		_cancel_exit()
	elif is_settings_visible() or is_controls_visible():
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


## Laeuft gerade ein Szenenwechsel ueber den Ladedienst (Hintergrundladen, Ladebild oder Nachlauf)?
func _is_scene_loading() -> bool:
	var tree := get_tree()
	var service: Node = tree.root.get_node_or_null("SceneLoadingService") if tree != null and tree.root != null else null
	if service == null or not service.has_method("is_loading"):
		return false
	return bool(service.call("is_loading")) or (service.has_method("is_external_wait") and bool(service.call("is_external_wait")))


func open_menu(status_text: String = "") -> void:
	if _is_scene_loading():
		return
	_ensure_overlay()
	_begin_modal_input()
	_overlay_root.visible = true
	_show_menu_panel()
	if not status_text.strip_edges().is_empty():
		_set_status(status_text)
	_play_ui_sfx("click", "escape_menu_open")


func close_menu() -> void:
	_ensure_overlay()
	_exit_action = ""
	_end_modal_input(true)
	_overlay_root.visible = false
	_play_ui_sfx("cancel", "escape_menu_close")


func toggle_menu() -> void:
	if is_menu_visible():
		close_menu()
	else:
		open_menu()


## Abschnitt P: Ist irgendein Feld des Menues (Menue, Einstellungen, Tastenbelegung) offen?
func is_overlay_open() -> bool:
	return _overlay_root != null and _overlay_root.visible


func is_menu_visible() -> bool:
	return _overlay_root != null and _overlay_root.visible and _menu_panel != null and _menu_panel.visible


func is_settings_visible() -> bool:
	return _overlay_root != null and _overlay_root.visible and _settings_panel != null and _settings_panel.visible


func is_controls_visible() -> bool:
	return _overlay_root != null and _overlay_root.visible and _controls_panel != null and _controls_panel.visible


func open_controls() -> void:
	_ensure_overlay()
	_begin_modal_input()
	_menu_panel.hide()
	_settings_panel.hide()
	_controls_panel.show()
	_overlay_root.show()
	_focus_panel(_controls_panel)
	_play_ui_sfx("click", "escape_controls_open")


func open_settings() -> void:
	_ensure_overlay()
	_begin_modal_input()
	_draft_settings = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path)).duplicate(true)
	_refresh_settings_controls()
	_menu_panel.visible = false
	_controls_panel.visible = false
	_settings_panel.visible = true
	_overlay_root.visible = true
	_focus_panel(_settings_panel)
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


## defer_if_blocked: Speichern von Hand (Menuepunkt, Taste F5). Geht es gerade nicht aus einem Uebergangsgrund, wird der Wunsch vorgemerkt
## (request_player_save des Flows). Beim Beenden bleibt es bei request_campaign_save mit der Nachfrage, ohne Warten.
func save_current_mission_slot(defer_if_blocked: bool = false) -> Dictionary:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	if current_scene == null:
		return _save_result(false, "no_current_scene")
	if current_scene.has_method("is_campaign_start") and current_scene.call("is_campaign_start") and current_scene.has_method("request_campaign_save"):
		if defer_if_blocked and current_scene.has_method("request_player_save"):
			return current_scene.call("request_player_save")
		return current_scene.call("request_campaign_save")
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
	_set_status("Szenenstart gemerkt. Fortschritt wird nicht gespeichert.")
	_refresh_action_buttons()
	return _save_result(true, "saved", OK, scene_path)


func load_mission_slot(change_scene: bool = true) -> Dictionary:
	if _is_campaign_context(): return {"ok":false,"reason":"campaign_continue_from_main_menu","message":"Kampagne im Hauptmenü über Fortsetzen laden."}
	var slot: Dictionary = get_save_slot_snapshot()
	if not bool(slot.get("exists", false)):
		return _load_result(false, "missing_save")
	var scene_path: String = String(slot.get("scene_path", "")).strip_edges()
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return _load_result(false, "missing_scene", scene_path)
	_last_loaded_scene_path = scene_path
	_set_status("Gemerkte Szene wird neu gestartet.")
	_play_ui_sfx("confirm", "load_mission_slot")
	if change_scene and not _test_mode:
		var tree := get_tree()
		if tree != null:
			var error: Error = _change_scene_via_service(tree, scene_path, "campaign")
			if error != OK:
				return _load_result(false, "change_scene_failed", scene_path, error)
			_end_modal_input(false)
			_overlay_root.visible = false
	return _load_result(true, "loaded", scene_path)


func return_to_main_menu(change_scene: bool = true, confirmed: bool = false) -> Dictionary:
	if not confirmed and _confirm_exit_if_needed("main_menu", change_scene, _save_campaign_before_exit()):
		return {"ok":false,"reason":"confirmation_required"}
	_play_ui_sfx("cancel", "return_to_main_menu")
	if change_scene and not _test_mode:
		var tree := get_tree()
		if tree != null:
			var error: Error = _change_scene_via_service(tree, MAIN_MENU_SCENE_PATH, "main_menu")
			if error != OK:
				return {"ok": false, "reason": "change_scene_failed", "error": error}
			_end_modal_input(false)
			_overlay_root.visible = false
	return {"ok": true, "target_scene": MAIN_MENU_SCENE_PATH}


func request_quit_game(confirmed: bool = false) -> Dictionary:
	if not confirmed and _confirm_exit_if_needed("quit", true, _save_campaign_before_exit()):
		return {"ok":false,"reason":"confirmation_required"}
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
	_controls_panel = _build_controls_panel()
	_controls_panel.hide()
	_overlay_root.add_child(_controls_panel)
	_exit_panel = _build_exit_panel()
	_exit_panel.hide()
	_overlay_root.add_child(_exit_panel)
	_refresh_action_buttons()


func _build_menu_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "EscapeMenuPanel"
	panel.custom_minimum_size = Vector2(460.0, 610.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -230.0
	panel.offset_top = -305.0
	panel.offset_right = 230.0
	panel.offset_bottom = 305.0

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "MenuVBox"
	vbox.add_theme_constant_override("separation", 6)
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
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_label)
	_resume_label = Label.new()
	_resume_label.name = "ResumableProgress"
	_resume_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_resume_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_resume_label)

	_add_menu_button(vbox, "ResumeButton", "Weiter", close_menu)
	_add_menu_button(vbox, "SettingsButton", "Einstellungen", open_settings)
	var controls_button := _add_menu_button(vbox, "ControlsButton", "Kartensteuerung", open_controls)
	controls_button.set_meta("help_id", "shell.map_controls")
	_save_button = _add_menu_button(vbox, "SaveMissionButton", "Mission speichern", _on_save_pressed)
	_load_button = _add_menu_button(vbox, "LoadMissionButton", "Mission laden", _on_load_pressed)
	_main_menu_button = _add_menu_button(vbox, "MainMenuButton", "Hauptmenue", _on_main_menu_pressed)
	_quit_button = _add_menu_button(vbox, "QuitButton", "Spiel beenden", request_quit_game)
	return panel


func _build_exit_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "UnsavedProgressConfirmation"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -270
	panel.offset_right = 270
	panel.offset_top = -200
	panel.offset_bottom = 200
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	_exit_label = Label.new()
	_exit_label.name = "ExitProgressDescription"
	_exit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_exit_label)
	_add_menu_button(column, "CancelExitButton", "Zurück zum Spielmenü", _cancel_exit)
	_exit_save = _add_menu_button(column, "SaveAndExitButton", "Speichern und verlassen", _save_and_exit)
	_exit_confirm = _add_menu_button(column, "ConfirmExitButton", "Ohne Speichern verlassen", _confirm_exit)
	return panel


func _campaign_save_projection() -> Dictionary:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("get_exit_progress_projection"):
		return scene.get_exit_progress_projection()
	return scene.get_campaign_save_projection() if _is_campaign_context() and scene.has_method("get_campaign_save_projection") else {}


## Ein Speicherversuch je Beenden-Vorgang (Spiel beenden oder Hauptmenue), vor der Nachfrage. Nur im ersten, unbestaetigten Aufruf;
## der bestaetigte Aufruf speichert nicht noch einmal. Ausserhalb der Kampagne passiert nichts. Auch im Testmodus.
func _save_campaign_before_exit() -> Dictionary:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	if not _is_campaign_context() or not current_scene.has_method("request_campaign_save"): return {}
	return current_scene.call("request_campaign_save")


func _confirm_exit_if_needed(action: String, change_scene: bool = true, save_result: Dictionary = {}) -> bool:
	var projection := _campaign_save_projection()
	if projection.is_empty() or not projection.get("has_unsaved_progress", false): return false
	_ensure_overlay()
	_begin_modal_input()
	_exit_action = action
	_exit_change_scene = change_scene
	_overlay_root.show()
	_menu_panel.hide()
	_settings_panel.hide()
	_controls_panel.hide()
	_exit_panel.show()
	_exit_label.text = "Ungespeicherter Fortschritt\n\nBei Fortsetzen wird geladen:\n" + String(projection.get("summary", "Kein gültiger Stand vorhanden."))
	var blocked := String(projection.get("save_blocked_text", ""))
	if not blocked.is_empty(): _exit_label.text += "\n\n" + blocked
	var refused := String(save_result.get("message", "")) if not bool(save_result.get("ok", true)) else ""
	if not refused.is_empty() and not _exit_label.text.contains(refused): _exit_label.text += "\n\n" + refused
	_exit_label.text += "\n\nEinsätze laufen auch während dieser Rückfrage weiter."
	_exit_save.disabled = not projection.get("can_save", false)
	_exit_save.text = "Speichern und beenden" if action == "quit" else "Speichern und zum Hauptmenü"
	_exit_confirm.text = "Ohne Speichern beenden" if action == "quit" else "Ohne Speichern zum Hauptmenü"
	_focus_panel(_exit_panel)
	return true


func _cancel_exit() -> void:
	_exit_action = ""
	_exit_panel.hide()
	_show_menu_panel()


func _confirm_exit() -> void:
	var action := _exit_action
	_exit_action = ""
	if action == "quit": request_quit_game(true)
	elif action == "main_menu": return_to_main_menu(_exit_change_scene, true)


func _save_and_exit() -> void:
	var result := save_current_mission_slot()
	if result.get("ok", false): _confirm_exit()
	else:
		_exit_label.text = String(result.get("message", "Speichern fehlgeschlagen. Der bisherige Stand bleibt erhalten.")) + "\n\n" + String(_campaign_save_projection().get("summary", ""))
		_focus_panel(_exit_panel, true)


func _build_controls_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "EscapeControlsPanel"
	panel.set_meta("help_id", "shell.map_controls")
	panel.custom_minimum_size = Vector2(560.0, 510.0)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280.0
	panel.offset_top = -255.0
	panel.offset_right = 280.0
	panel.offset_bottom = 255.0
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	# The existing catalog remains the only text source. Build once, no runtime
	# input interception or gameplay state is added by this reference page.
	var help = HELP_SERVICE_SCRIPT.new()
	help.load_catalog()
	var entry: Dictionary = help.get_entry("shell.map_controls")
	var heading := Label.new()
	heading.text = String(entry.get("title", "Kartensteuerung"))
	heading.add_theme_font_size_override("font_size", 22)
	column.add_child(heading)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	for line: String in entry.get("detail_lines", []):
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 16)
		content.add_child(label)
	_add_menu_button(column, "ControlsBackButton", "Zurück zum Spielmenü", _show_menu_panel)
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
	if _exit_panel != null: _exit_panel.hide()
	_menu_panel.visible = true
	_settings_panel.visible = false
	_controls_panel.visible = false
	_refresh_action_buttons()
	_set_status("Escape · Einsätze laufen weiter")
	if _modal_open:
		_focus_panel(_menu_panel)


func _begin_modal_input() -> void:
	if _modal_open:
		return
	var focused := get_viewport().gui_get_focus_owner()
	_previous_focus = weakref(focused) if focused != null else null
	_modal_open = true
	var scene := get_tree().current_scene
	if scene != null:
		_suspend_scene_input_recursive(scene)


func _suspend_scene_input_recursive(node: Node) -> void:
	_suspend_scene_input(node)
	for child in node.get_children():
		_suspend_scene_input_recursive(child)


func _suspend_scene_input(node: Node) -> void:
	if not _modal_open or not is_instance_valid(node) or not node.is_inside_tree():
		return
	var scene := get_tree().current_scene
	if scene == null or (node != scene and not scene.is_ancestor_of(node)):
		return
	var id := node.get_instance_id()
	if _suspended_input.has(id):
		return
	# A release can occur while callbacks are suspended. Cancel only unfinished
	# UI gestures; never synthesize a release that could commit an order.
	if node.has_method("cancel_modal_input"):
		node.call("cancel_modal_input")
	# One bounded traversal on opening; simulation/physics processing is untouched.
	var flags := [node.is_processing_input(), node.is_processing_shortcut_input(), node.is_processing_unhandled_key_input(), node.is_processing_unhandled_input()]
	if not flags.has(true):
		return
	_suspended_input[id] = [weakref(node)] + flags
	node.set_process_input(false)
	node.set_process_shortcut_input(false)
	node.set_process_unhandled_key_input(false)
	node.set_process_unhandled_input(false)


func _end_modal_input(restore_focus: bool) -> void:
	_modal_open = false
	_panel_focus_controls.clear()
	for entry: Array in _suspended_input.values():
		var node: Node = entry[0].get_ref()
		if is_instance_valid(node):
			node.set_process_input(entry[1])
			node.set_process_shortcut_input(entry[2])
			node.set_process_unhandled_key_input(entry[3])
			node.set_process_unhandled_input(entry[4])
	_suspended_input.clear()
	var focused: Control = _previous_focus.get_ref() if _previous_focus != null else null
	_previous_focus = null
	if restore_focus and is_instance_valid(focused) and focused.is_visible_in_tree() and focused.focus_mode != Control.FOCUS_NONE and (not focused is BaseButton or not focused.disabled):
		focused.grab_focus()


func _focus_panel(panel: Control, preserve_current: bool = false) -> void:
	var focused := get_viewport().gui_get_focus_owner()
	_panel_focus_controls.clear()
	for child in panel.find_children("*", "Control", true, false):
		if child.focus_mode == Control.FOCUS_ALL and child.is_visible_in_tree() and (not child is BaseButton or not child.disabled):
			_panel_focus_controls.append(child)
	if _panel_focus_controls.is_empty():
		return
	for index in _panel_focus_controls.size():
		var control := _panel_focus_controls[index]
		var previous := control.get_path_to(_panel_focus_controls[posmod(index - 1, _panel_focus_controls.size())])
		var next := control.get_path_to(_panel_focus_controls[(index + 1) % _panel_focus_controls.size()])
		control.focus_previous = previous
		control.focus_next = next
		control.focus_neighbor_top = previous
		control.focus_neighbor_bottom = next
	if preserve_current and _panel_focus_controls.has(focused):
		focused.grab_focus()
	else:
		_panel_focus_controls[0].grab_focus()


func _on_gui_focus_changed(control: Control) -> void:
	if _modal_open and control != null and not _overlay_root.is_ancestor_of(control) and not _panel_focus_controls.is_empty():
		_panel_focus_controls[0].grab_focus()


func _ensure_overlay() -> void:
	if _overlay_root == null:
		_build_overlay()


func _refresh_action_buttons() -> void:
	var campaign := _is_campaign_context()
	if _resume_label != null:
		var projection := _campaign_save_projection()
		_resume_label.visible = not projection.is_empty()
		if _resume_label.visible:
			_resume_label.text = "Fortsetzen: " + String(projection.get("summary", "Kampagne wird vorbereitet."))
			if not String(projection.get("save_blocked_text", "")).is_empty(): _resume_label.text += "\n" + String(projection.save_blocked_text)
	if _save_button != null:
		_save_button.disabled = not _can_save_current_scene()
		_save_button.text = "Kampagne speichern" if campaign else "Szenenstart merken"
		_save_button.tooltip_text = "Speichert den Kampagnenstand über den vorhandenen Kampagnenowner, sobald der Zustand sicher speicherbar ist." if campaign else "Merkt nur die Szene. Fortschritt, Positionen und Kampfzustand werden nicht gespeichert."
		if _save_button.disabled: _save_button.tooltip_text = "Im Hauptmenü gibt es keine laufende Szene zum Merken."
	if _load_button != null:
		_load_button.disabled = campaign or not bool(get_save_slot_snapshot().get("exists", false))
		_load_button.text = "Im Hauptmenü fortsetzen" if campaign else "Gemerkte Szene neu starten"
		_load_button.tooltip_text = "Kampagne im Hauptmenü über Fortsetzen laden." if campaign else "Startet die gemerkte Szene von vorn. Kein gespeicherter Spielfortschritt."
	if _main_menu_button != null:
		_main_menu_button.disabled = _is_current_scene_main_menu()
	if _modal_open and is_menu_visible():
		_focus_panel(_menu_panel, true)


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
	var result: Dictionary = save_current_mission_slot(true)
	_refresh_action_buttons()
	_play_ui_sfx("confirm" if bool(result.get("ok", false)) else ("click" if bool(result.get("pending", false)) else "warning"), "save_mission_slot")
	var saved_text := "Kampagne gespeichert." if _is_campaign_context() else "Szenenstart gemerkt. Fortschritt wird nicht gespeichert."
	_set_status(String(result.get("message", saved_text if bool(result.get("ok", false)) else "Speichern ist hier nicht verfügbar.")))


func _on_load_pressed() -> void:
	var result: Dictionary = load_mission_slot()
	if not bool(result.get("ok", false)):
		_play_ui_sfx("warning", "load_mission_slot_failed")
		_set_status(String(result.get("message", "Kein Szenenstart gemerkt.")))


func _on_main_menu_pressed() -> void:
	return_to_main_menu()


func _can_save_current_scene() -> bool:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	if current_scene == null:
		return false
	var scene_path: String = String(current_scene.scene_file_path).strip_edges()
	return not scene_path.is_empty() and scene_path != MAIN_MENU_SCENE_PATH


func _is_campaign_context() -> bool:
	var tree := get_tree()
	var current_scene := tree.current_scene if tree != null else null
	return current_scene != null and current_scene.has_method("is_campaign_start") and bool(current_scene.call("is_campaign_start"))


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
	if _modal_open:
		# Run after _ready, which can enable a newly added node's input callbacks.
		_suspend_new_scene_input.call_deferred(weakref(node))
	var button := node as BaseButton
	if button != null:
		_install_button_sfx(button)


func _suspend_new_scene_input(node_ref: WeakRef) -> void:
	var node: Node = node_ref.get_ref()
	if is_instance_valid(node):
		_suspend_scene_input(node)


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


## Szenenwechsel ueber den zentralen Ladedienst (Paket Z); ohne Dienst der alte Weg.
func _change_scene_via_service(tree: SceneTree, scene_path: String, tip_context: String = "") -> Error:
	var service: Node = tree.root.get_node_or_null("SceneLoadingService") if tree != null and tree.root != null else null
	if service != null and service.has_method("change_scene"):
		return int(service.call("change_scene", scene_path, {"tip_context": tip_context})) as Error
	return tree.change_scene_to_file(scene_path)
