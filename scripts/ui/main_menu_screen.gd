extends Control

const BACKGROUND_PATH: String = "res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg"
const SINGLEPLAYER_SCENE_PATH: String = "res://scenes/meta/meta_layer_test.tscn"
const MULTIPLAYER_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const SETTINGS_SCREEN_SCRIPT: GDScript = preload("res://scripts/ui/settings_screen.gd")
const CONTEXTUAL_HELP_SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const CONTEXTUAL_HELP_POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const TEAM_NAME_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/team_name_generator.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const BACKGROUND_ID: String = "main_menu_shell"
const TEAM_EDITOR_POINT_DELTA: int = 1

@onready var _background: TextureRect = get_node("Background")
@onready var _singleplayer_button: Button = get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SingleplayerButton")
@onready var _multiplayer_button: Button = get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/MultiplayerButton")
@onready var _editor_button: Button = get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/EditorButton")
@onready var _settings_button: Button = get_node("MenuRail/MenuMargin/MenuVBox/MenuButtons/SettingsButton")
@onready var _settings_panel: Control = get_node("SettingsPanel")
@onready var _settings_vbox: VBoxContainer = get_node("SettingsPanel/SettingsMargin/SettingsVBox")
@onready var _settings_back_button: Button = get_node("SettingsPanel/SettingsMargin/SettingsVBox/SettingsBackButton")
@onready var _master_volume_slider: HSlider = get_node("SettingsPanel/SettingsMargin/SettingsVBox/MasterVolumeSlider")
@onready var _fullscreen_check: CheckButton = get_node("SettingsPanel/SettingsMargin/SettingsVBox/FullscreenCheckButton")
@onready var _bubble_mode_option: OptionButton = get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/BubbleModeOptionButton") as OptionButton
@onready var _thought_hold_label: Label = get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/ThoughtHoldLabel") as Label
@onready var _status_label: Label = get_node("MenuRail/MenuMargin/MenuVBox/StatusLabel")

var _settings_config_path: String = COMIC_BUBBLE_SETTINGS_SCRIPT.CONFIG_PATH
var _comic_bubble_settings: Dictionary = {}
var _gameplay_settings: Dictionary = {}
var _draft_comic_bubble_settings: Dictionary = {}
var _draft_gameplay_settings: Dictionary = {}
var _display_section_label: Label = null
var _audio_section_label: Label = null
var _input_section_label: Label = null
var _gameplay_section_label: Label = null
var _resolution_option: OptionButton = null
var _window_mode_option: OptionButton = null
var _vsync_check: CheckButton = null
var _music_volume_slider: HSlider = null
var _sfx_volume_slider: HSlider = null
var _fog_of_war_option: OptionButton = null
var _contextual_help_mode_label: Label = null
var _contextual_help_option: OptionButton = null
var _input_actions_label: Label = null
var _settings_apply_button: Button = null
var _settings_reset_button: Button = null
var _team_name_edit: LineEdit = null
var _team_name_suggest_button: Button = null
var _new_roster_button: Button = null
var _team_editor_toggle_button: Button = null
var _team_library_panel: PanelContainer = null
var _team_library_list: VBoxContainer = null
var _team_library_status_label: Label = null
var _team_library_activate_button: Button = null
var _team_library_delete_button: Button = null
var _team_library_entries: Array = []
var _selected_roster_entry_path: String = ""
var _team_editor_panel: PanelContainer = null
var _team_editor_open: bool = false
var _team_editor_emblem_option: OptionButton = null
var _team_editor_emblem_preview: TextureRect = null
var _team_editor_budget_label: Label = null
var _team_editor_stats_vbox: VBoxContainer = null
var _team_editor_stat_rows: Dictionary = {}
var _start_roster: Dictionary = {}
var _start_roster_seed: String = START_ROSTER_GENERATOR_SCRIPT.DEFAULT_SEED
var _start_roster_size: int = START_ROSTER_GENERATOR_SCRIPT.DEFAULT_ROSTER_SIZE
var _start_roster_generation_index: int = 0
var _start_roster_reset_confirmation_pending: bool = false
var _last_start_roster_created: bool = false
var _last_start_roster_loaded_from_save: bool = false
var _start_roster_profile_id: String = PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID
var _start_roster_save_path: String = PLAYER_ROSTER_STORE_SCRIPT.get_save_path(PLAYER_ROSTER_STORE_SCRIPT.DEFAULT_PROFILE_ID)
var _last_start_roster_store_result: Dictionary = {}
var _audio_event_bus = null
var _help_service = null
var _contextual_help_popup: Control = null
var _global_help_button: Button = null
var _active_help_control: Control = null
var _active_help_id: String = ""
var _help_hover_token: int = 0


func _ready() -> void:
	set_meta("main_menu_shell", true)
	_apply_background_texture()
	_load_comic_bubble_settings()
	_ensure_audio_event_bus()
	_ensure_settings_screen_nodes()
	_ensure_start_roster_button()
	_ensure_contextual_help_ui()
	ensure_start_roster_exists()
	_refresh_settings_controls_from_current()
	_configure_routes()
	_connect_signals()
	close_settings_panel()


func get_background_path() -> String:
	var catalog_path: String = String(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_path", BACKGROUND_ID))
	return catalog_path if not catalog_path.is_empty() else BACKGROUND_PATH


func get_background_catalog_snapshot() -> Dictionary:
	var entry: Dictionary = Dictionary(BACKGROUND_IMAGE_CATALOG_SCRIPT.call("get_entry", BACKGROUND_ID))
	return {
		"background_id": BACKGROUND_ID,
		"path": get_background_path(),
		"entry": entry,
		"uses_catalog": not entry.is_empty(),
	}


func get_route_snapshot() -> Dictionary:
	return {
		"singleplayer": SINGLEPLAYER_SCENE_PATH,
		"multiplayer": MULTIPLAYER_SCENE_PATH,
		"editor": EDITOR_SCENE_PATH,
		"settings": "local_settings_panel",
		"multiplayer_lobby": true,
	}


func is_settings_panel_visible() -> bool:
	return _settings_panel.visible


func get_settings_snapshot() -> Dictionary:
	return {
		"comic_bubbles": COMIC_BUBBLE_SETTINGS_SCRIPT.call("build_snapshot", _comic_bubble_settings),
		"gameplay": GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", _gameplay_settings),
		"sections": SETTINGS_SCREEN_SCRIPT.call("build_section_snapshot", _gameplay_settings, _comic_bubble_settings),
		"settings_config_path": _settings_config_path,
	}


func get_contextual_help_snapshot() -> Dictionary:
	return {
		"service": _help_service.call("get_diagnostic_snapshot") if _help_service != null else {},
		"global_button_visible": _global_help_button != null and _global_help_button.visible,
		"global_button_help_id": String(_global_help_button.get_meta("help_id", "")) if _global_help_button != null else "",
		"global_button_size": _global_help_button.size if _global_help_button != null else Vector2.ZERO,
		"popup": _contextual_help_popup.call("get_diagnostic_snapshot") if _contextual_help_popup != null and _contextual_help_popup.has_method("get_diagnostic_snapshot") else {},
		"settings_mode": String(_gameplay_settings.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.CONTEXTUAL_HELP_MODE_COMPACT)),
	}


func get_settings_ui_snapshot() -> Dictionary:
	var section_snapshot: Dictionary = Dictionary(SETTINGS_SCREEN_SCRIPT.call("build_section_snapshot", _draft_gameplay_settings if not _draft_gameplay_settings.is_empty() else _gameplay_settings, _draft_comic_bubble_settings if not _draft_comic_bubble_settings.is_empty() else _comic_bubble_settings))
	return {
		"panel_visible": _settings_panel.visible,
		"sections": section_snapshot,
		"display_section_visible": _display_section_label != null and _display_section_label.visible,
		"audio_section_visible": _audio_section_label != null and _audio_section_label.visible,
		"input_section_visible": _input_section_label != null and _input_section_label.visible,
		"gameplay_section_visible": _gameplay_section_label != null and _gameplay_section_label.visible,
		"apply_button_visible": _settings_apply_button != null and _settings_apply_button.visible,
		"reset_button_visible": _settings_reset_button != null and _settings_reset_button.visible,
		"cancel_button_visible": _settings_back_button != null and _settings_back_button.visible,
	}


func get_audio_sfx_debug_snapshot() -> Dictionary:
	var bus = _ensure_audio_event_bus()
	if bus != null and bus.has_method("get_diagnostic_snapshot"):
		return Dictionary(bus.call("get_diagnostic_snapshot")).duplicate(true)
	return {}


func get_start_roster_snapshot() -> Dictionary:
	var summary: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", _start_roster))
	summary["has_roster"] = bool(summary.get("valid", false))
	summary["team_identity"] = TEAM_NAME_GENERATOR_SCRIPT.call("build_team_identity_snapshot", _start_roster)
	summary["team_name_edit_visible"] = _team_name_edit != null and _team_name_edit.visible
	summary["team_name_suggest_button_visible"] = _team_name_suggest_button != null and _team_name_suggest_button.visible
	summary["created_on_first_start"] = _last_start_roster_created
	summary["loaded_from_save"] = _last_start_roster_loaded_from_save
	summary["reset_confirmation_pending"] = _start_roster_reset_confirmation_pending
	summary["new_roster_button_visible"] = _new_roster_button != null and _new_roster_button.visible
	summary["new_roster_button_text"] = _new_roster_button.text if _new_roster_button != null else ""
	summary["profile_id"] = _start_roster_profile_id
	summary["store_path"] = _start_roster_save_path
	summary["save_exists"] = FileAccess.file_exists(_start_roster_save_path)
	summary["last_store_reason"] = String(_last_start_roster_store_result.get("reason", ""))
	summary["last_archive_path"] = String(_last_start_roster_store_result.get("archive_path", ""))
	summary["last_store_ok"] = bool(_last_start_roster_store_result.get("ok", false))
	return summary


func get_team_library_snapshot() -> Dictionary:
	var selected_entry: Dictionary = _find_team_library_entry(_selected_roster_entry_path)
	var active_entry: Dictionary = {}
	for entry_variant in _team_library_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if bool(entry.get("active", false)):
			active_entry = entry
			break
	return {
		"visible": _team_library_panel != null and _team_library_panel.visible,
		"entry_count": _team_library_entries.size(),
		"entries": _team_library_entries.duplicate(true),
		"selected_path": _selected_roster_entry_path,
		"selected_team_name": String(selected_entry.get("team_name", "")),
		"selected_is_active": bool(selected_entry.get("active", false)),
		"active_path": String(active_entry.get("path", _start_roster_save_path)),
		"active_team_name": String(active_entry.get("team_name", "")),
		"activate_enabled": _team_library_activate_button != null and not _team_library_activate_button.disabled,
		"delete_enabled": _team_library_delete_button != null and not _team_library_delete_button.disabled,
	}


func get_team_editor_snapshot() -> Dictionary:
	var editor: Dictionary = _get_normalized_team_editor(false)
	return {
		"visible": _team_editor_panel != null and _team_editor_panel.visible,
		"toggle_visible": _team_editor_toggle_button != null and _team_editor_toggle_button.visible,
		"toggle_text": _team_editor_toggle_button.text if _team_editor_toggle_button != null else "",
		"budget_max": int(editor.get("point_budget_max", 0)),
		"budget_used": int(editor.get("point_budget_used", 0)),
		"budget_available": int(editor.get("point_budget_available", 0)),
		"allocations": Dictionary(editor.get("stat_allocations", {})).duplicate(true),
		"stat_definitions": Array(editor.get("stat_definitions", [])).duplicate(true),
		"emblem_id": String(editor.get("emblem_id", "")),
		"emblem_path": String(editor.get("emblem_path", "")),
		"emblem_option_count": _team_editor_emblem_option.item_count if _team_editor_emblem_option != null else 0,
		"has_emblem_texture": _team_editor_emblem_preview != null and _team_editor_emblem_preview.texture != null,
	}


func select_team_library_entry_for_tests(entry_path: String) -> void:
	_selected_roster_entry_path = entry_path.strip_edges()
	_refresh_team_library()


func activate_selected_team_entry_for_tests() -> Dictionary:
	return _activate_selected_team_entry(false)


func delete_selected_team_entry_for_tests() -> Dictionary:
	return _delete_selected_team_entry(false)


func adjust_team_editor_stat_for_tests(stat_id: String, delta: int) -> Dictionary:
	return _adjust_team_editor_stat(stat_id, delta, false)


func set_team_editor_stat_for_tests(stat_id: String, value: int) -> Dictionary:
	return _set_team_editor_stat(stat_id, value, false)


func set_team_editor_emblem_for_tests(emblem_id: String) -> Dictionary:
	return _set_team_editor_emblem(emblem_id, false)


func open_team_editor() -> void:
	_set_team_editor_open(true)


func close_team_editor() -> void:
	_set_team_editor_open(false)


func toggle_team_editor() -> void:
	_set_team_editor_open(not _team_editor_open)


func ensure_start_roster_exists(seed: String = "", roster_size: int = -1) -> Dictionary:
	if not seed.strip_edges().is_empty():
		_start_roster_seed = seed.strip_edges()
	if roster_size > 0:
		_start_roster_size = clampi(roster_size, START_ROSTER_GENERATOR_SCRIPT.MIN_ROSTER_SIZE, START_ROSTER_GENERATOR_SCRIPT.MAX_ROSTER_SIZE)
	var first_start: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("ensure_roster", _start_roster_seed, _start_roster_size, _start_roster_profile_id, _start_roster_save_path))
	_start_roster = Dictionary(first_start.get("roster", {})).duplicate(true)
	_normalize_start_team_editor(true)
	_last_start_roster_created = bool(first_start.get("created", false))
	_last_start_roster_loaded_from_save = bool(first_start.get("loaded", false))
	_last_start_roster_store_result = first_start.duplicate(true)
	_start_roster_reset_confirmation_pending = false
	_refresh_start_roster_button()
	_refresh_team_name_controls()
	_selected_roster_entry_path = _start_roster_save_path
	_refresh_team_library()
	_refresh_team_editor()
	_status_label.text = "Roster ready" if bool(Dictionary(first_start.get("summary", {})).get("valid", false)) else "Roster invalid"
	return first_start


func set_start_roster_seed_for_tests(seed: String, roster_size: int = -1) -> void:
	_start_roster_seed = seed.strip_edges() if not seed.strip_edges().is_empty() else START_ROSTER_GENERATOR_SCRIPT.DEFAULT_SEED
	if roster_size > 0:
		_start_roster_size = clampi(roster_size, START_ROSTER_GENERATOR_SCRIPT.MIN_ROSTER_SIZE, START_ROSTER_GENERATOR_SCRIPT.MAX_ROSTER_SIZE)
	var safe_seed: String = _sanitize_test_profile_fragment(_start_roster_seed)
	_start_roster_profile_id = "test_%s" % safe_seed
	_start_roster_save_path = PLAYER_ROSTER_STORE_SCRIPT.call("get_save_path", _start_roster_profile_id)
	PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", _start_roster_profile_id, _start_roster_save_path)
	_start_roster_generation_index = 0
	_start_roster.clear()
	ensure_start_roster_exists(_start_roster_seed, _start_roster_size)


func set_start_roster_store_path_for_tests(save_path: String, profile_id: String = "test_player", delete_existing: bool = true) -> void:
	_start_roster_profile_id = profile_id.strip_edges() if not profile_id.strip_edges().is_empty() else "test_player"
	_start_roster_save_path = save_path.strip_edges()
	if _start_roster_save_path.is_empty():
		_start_roster_save_path = PLAYER_ROSTER_STORE_SCRIPT.call("get_save_path", _start_roster_profile_id)
	if delete_existing:
		PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_for_tests", _start_roster_profile_id, _start_roster_save_path)
	_start_roster_generation_index = 0
	_start_roster_reset_confirmation_pending = false
	_last_start_roster_store_result = {}
	_last_start_roster_loaded_from_save = false
	_selected_roster_entry_path = _start_roster_save_path
	_start_roster.clear()
	_refresh_team_library()
	_refresh_team_editor()


func request_new_start_roster() -> Dictionary:
	var current_summary: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", _start_roster))
	var has_existing_roster: bool = bool(current_summary.get("valid", false))
	var prompt: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("build_generation_prompt", has_existing_roster))
	if has_existing_roster:
		_start_roster_reset_confirmation_pending = true
		_refresh_start_roster_button()
		_status_label.text = "Neues Team: bestaetigen"
		return prompt
	return confirm_new_start_roster()


func confirm_new_start_roster() -> Dictionary:
	_start_roster_generation_index += 1
	var next_seed: String = "%s_reset_%02d" % [_start_roster_seed, _start_roster_generation_index]
	var reset_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("reset_roster", next_seed, _start_roster_size, _start_roster_profile_id, _start_roster_save_path, true))
	_start_roster = Dictionary(reset_result.get("roster", {})).duplicate(true)
	_normalize_start_team_editor(true)
	_last_start_roster_created = true
	_last_start_roster_loaded_from_save = false
	_last_start_roster_store_result = reset_result.duplicate(true)
	_start_roster_reset_confirmation_pending = false
	_refresh_start_roster_button()
	_refresh_team_name_controls()
	_selected_roster_entry_path = _start_roster_save_path
	_refresh_team_library()
	_refresh_team_editor()
	_status_label.text = "Neues Team bereit" if bool(reset_result.get("ok", false)) else "Roster save failed"
	return {
		"created": true,
		"reason": "confirmed_new_roster",
		"roster": _start_roster.duplicate(true),
		"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", _start_roster),
		"store": reset_result,
	}


func cancel_new_start_roster() -> void:
	_start_roster_reset_confirmation_pending = false
	_refresh_start_roster_button()
	_status_label.text = "Roster ready"


func set_start_team_name(next_team_name: String) -> Dictionary:
	var renamed: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("rename_team", _start_roster, next_team_name, _start_roster_profile_id, _start_roster_save_path))
	_start_roster = Dictionary(renamed.get("roster", _start_roster)).duplicate(true)
	_normalize_start_team_editor(false)
	_last_start_roster_store_result = Dictionary(renamed.get("save", {})).duplicate(true)
	_refresh_team_name_controls()
	_selected_roster_entry_path = _start_roster_save_path
	_refresh_team_library()
	_refresh_team_editor()
	_status_label.text = "Team name saved" if bool(renamed.get("ok", false)) else "Team name save failed"
	return renamed


func request_start_team_name_suggestion() -> Dictionary:
	_start_roster_generation_index += 1
	var generated: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("generate_team_name", _start_roster_seed, _start_roster_profile_id, _start_roster_generation_index))
	set_start_team_name(String(generated.get("team_name", "")))
	return generated


func set_settings_path_for_tests(config_path: String) -> void:
	_settings_config_path = config_path
	_load_comic_bubble_settings()
	_refresh_settings_controls_from_current()


func set_comic_bubble_mode(mode: String) -> int:
	_comic_bubble_settings["mode"] = COMIC_BUBBLE_SETTINGS_SCRIPT.call("normalize_mode", mode)
	var error: int = int(COMIC_BUBBLE_SETTINGS_SCRIPT.call("save_settings", _comic_bubble_settings, _settings_config_path))
	_load_comic_bubble_settings()
	_refresh_settings_controls_from_current()
	_status_label.text = "Bubbles: %s" % _mode_label(String(_comic_bubble_settings.get("mode", "normal")))
	return error


func set_fog_of_war_mode(mode: String) -> int:
	_gameplay_settings["fog_of_war_mode"] = mode
	var error: int = int(GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", _gameplay_settings, _settings_config_path))
	_load_comic_bubble_settings()
	_refresh_settings_controls_from_current()
	_status_label.text = "FoW: %s" % _mode_label(String(_gameplay_settings.get("fog_of_war_mode", "known_terrain")))
	return error


func set_contextual_help_mode(mode: String) -> int:
	_gameplay_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE] = GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_contextual_help_mode", mode)
	var error: int = int(GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", _gameplay_settings, _settings_config_path))
	_load_comic_bubble_settings()
	_refresh_settings_controls_from_current()
	_status_label.text = "Help: %s" % _mode_label(String(_gameplay_settings.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.CONTEXTUAL_HELP_MODE_COMPACT)))
	return error


func set_draft_fog_of_war_mode(mode: String) -> void:
	_draft_gameplay_settings["fog_of_war_mode"] = mode
	_refresh_settings_controls_from_draft()


func set_draft_contextual_help_mode(mode: String) -> void:
	_draft_gameplay_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE] = GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_contextual_help_mode", mode)
	_refresh_settings_controls_from_draft()


func set_draft_comic_bubble_mode(mode: String) -> void:
	_draft_comic_bubble_settings["mode"] = COMIC_BUBBLE_SETTINGS_SCRIPT.call("normalize_mode", mode)
	_refresh_settings_controls_from_draft()


func set_draft_display_settings(resolution_preset: String, window_mode: String, vsync_enabled: bool) -> void:
	_draft_gameplay_settings["resolution_preset"] = resolution_preset
	_draft_gameplay_settings["window_mode"] = GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_window_mode", window_mode)
	_draft_gameplay_settings["vsync_enabled"] = vsync_enabled
	_refresh_settings_controls_from_draft()


func set_draft_audio_settings(master_volume: float, music_volume: float, sfx_volume: float) -> void:
	_draft_gameplay_settings["master_volume"] = clampf(master_volume, 0.0, 100.0)
	_draft_gameplay_settings["music_volume"] = clampf(music_volume, 0.0, 100.0)
	_draft_gameplay_settings["sfx_volume"] = clampf(sfx_volume, 0.0, 100.0)
	_refresh_settings_controls_from_draft()


func apply_settings() -> int:
	if _draft_gameplay_settings.is_empty():
		_draft_gameplay_settings = _gameplay_settings.duplicate(true)
	if _draft_comic_bubble_settings.is_empty():
		_draft_comic_bubble_settings = _comic_bubble_settings.duplicate(true)
	var gameplay_error: int = int(GAME_SETTINGS_CONTRACT_SCRIPT.call("save_settings", _draft_gameplay_settings, _settings_config_path))
	if gameplay_error != OK:
		_status_label.text = "Settings failed"
		_play_ui_sfx("warning", "settings_apply_failed")
		return gameplay_error
	var bubble_error: int = int(COMIC_BUBBLE_SETTINGS_SCRIPT.call("save_settings", _draft_comic_bubble_settings, _settings_config_path))
	if bubble_error != OK:
		_status_label.text = "Settings failed"
		_play_ui_sfx("warning", "settings_bubbles_failed")
		return bubble_error
	_apply_runtime_settings(_draft_gameplay_settings)
	_load_comic_bubble_settings()
	_refresh_settings_controls_from_current()
	_status_label.text = "Settings saved"
	_play_ui_sfx("confirm", "settings_apply")
	return OK


func reset_settings_defaults() -> void:
	_draft_gameplay_settings = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("get_default_settings"))
	_draft_comic_bubble_settings = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("get_default_settings"))
	_refresh_settings_controls_from_draft()
	_status_label.text = "Defaults ready"
	_play_ui_sfx("switch", "settings_defaults")


func cancel_settings_changes() -> void:
	_draft_gameplay_settings = _gameplay_settings.duplicate(true)
	_draft_comic_bubble_settings = _comic_bubble_settings.duplicate(true)
	_refresh_settings_controls_from_current()
	close_settings_panel()
	_play_ui_sfx("cancel", "settings_cancel")


func open_settings_panel() -> void:
	_draft_gameplay_settings = _gameplay_settings.duplicate(true)
	_draft_comic_bubble_settings = _comic_bubble_settings.duplicate(true)
	_refresh_settings_controls_from_draft()
	_settings_panel.visible = true
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_back_button.grab_focus()
	_status_label.text = "Settings"
	_play_ui_sfx("click", "settings_open")


func close_settings_panel() -> void:
	_settings_panel.visible = false
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status_label.text = "Ready"


func _apply_background_texture() -> void:
	var texture := BACKGROUND_IMAGE_CATALOG_SCRIPT.call("load_texture", BACKGROUND_ID) as Texture2D
	if texture == null:
		texture = ResourceLoader.load(BACKGROUND_PATH) as Texture2D
	if texture is Texture2D:
		_background.texture = texture


func _configure_routes() -> void:
	_singleplayer_button.set_meta("route", SINGLEPLAYER_SCENE_PATH)
	_multiplayer_button.set_meta("route", MULTIPLAYER_SCENE_PATH)
	_multiplayer_button.set_meta("route_adapter", "multiplayer_lobby_screen")
	_editor_button.set_meta("route", EDITOR_SCENE_PATH)
	_settings_button.set_meta("route", "local_settings_panel")


func _connect_signals() -> void:
	_singleplayer_button.pressed.connect(_on_singleplayer_pressed)
	_multiplayer_button.pressed.connect(_on_multiplayer_pressed)
	_editor_button.pressed.connect(_on_editor_pressed)
	_settings_button.pressed.connect(open_settings_panel)
	if _new_roster_button != null and not _new_roster_button.pressed.is_connected(_on_new_roster_pressed):
		_new_roster_button.pressed.connect(_on_new_roster_pressed)
	_settings_back_button.pressed.connect(cancel_settings_changes)
	_master_volume_slider.value_changed.connect(_on_master_volume_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if _bubble_mode_option != null:
		_bubble_mode_option.item_selected.connect(_on_bubble_mode_selected)
	if _resolution_option != null:
		_resolution_option.item_selected.connect(_on_resolution_selected)
	if _window_mode_option != null:
		_window_mode_option.item_selected.connect(_on_window_mode_selected)
	if _vsync_check != null:
		_vsync_check.toggled.connect(_on_vsync_toggled)
	if _music_volume_slider != null:
		_music_volume_slider.value_changed.connect(_on_music_volume_changed)
	if _sfx_volume_slider != null:
		_sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	if _fog_of_war_option != null:
		_fog_of_war_option.item_selected.connect(_on_fog_of_war_mode_selected)
	if _contextual_help_option != null:
		_contextual_help_option.item_selected.connect(_on_contextual_help_mode_selected)
	if _settings_apply_button != null:
		_settings_apply_button.pressed.connect(apply_settings)
	if _settings_reset_button != null:
		_settings_reset_button.pressed.connect(reset_settings_defaults)


func _ensure_settings_screen_nodes() -> void:
	_settings_panel.offset_left = -760.0
	_settings_panel.offset_top = -420.0
	_settings_panel.offset_right = -80.0
	_settings_panel.offset_bottom = 420.0
	_settings_vbox.add_theme_constant_override("separation", 12)

	_display_section_label = _ensure_settings_label("DisplaySectionLabel", "Anzeige", 18)
	_resolution_option = _ensure_settings_option("ResolutionOptionButton", Vector2(360.0, 38.0))
	_window_mode_option = _ensure_settings_option("WindowModeOptionButton", Vector2(360.0, 38.0))
	_vsync_check = _ensure_settings_check("VsyncCheckButton", "VSync")

	_audio_section_label = get_node_or_null("SettingsPanel/SettingsMargin/SettingsVBox/AudioLabel") as Label
	if _audio_section_label == null:
		_audio_section_label = _ensure_settings_label("AudioLabel", "Audio", 18)
	else:
		_audio_section_label.text = "Audio"
		_audio_section_label.add_theme_font_size_override("font_size", 18)
	_master_volume_slider.custom_minimum_size = Vector2(360.0, 30.0)
	_music_volume_slider = _ensure_settings_slider("MusicVolumeSlider")
	_sfx_volume_slider = _ensure_settings_slider("SfxVolumeSlider")

	_input_section_label = _ensure_settings_label("InputSectionLabel", "Eingabe", 18)
	_input_actions_label = _ensure_settings_label("InputActionsLabel", _build_input_actions_text(), 13)
	_input_actions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_gameplay_section_label = _ensure_settings_label("GameplaySectionLabel", "Gameplay", 18)
	_fog_of_war_option = _ensure_settings_option("FogOfWarModeOptionButton", Vector2(360.0, 38.0))
	_contextual_help_mode_label = _ensure_settings_label("ContextualHelpModeLabel", "Kontext-Hilfe", 14)
	_contextual_help_option = _ensure_settings_option("ContextualHelpModeOptionButton", Vector2(360.0, 38.0))
	if _bubble_mode_option != null:
		_bubble_mode_option.custom_minimum_size = Vector2(360.0, 38.0)

	var action_row := _settings_vbox.get_node_or_null("SettingsActionRow") as HBoxContainer
	if action_row == null:
		action_row = HBoxContainer.new()
		action_row.name = "SettingsActionRow"
		action_row.add_theme_constant_override("separation", 12)
		_settings_vbox.add_child(action_row)
		_settings_vbox.move_child(action_row, maxi(_settings_vbox.get_child_count() - 2, 0))
	_settings_apply_button = action_row.get_node_or_null("SettingsApplyButton") as Button
	if _settings_apply_button == null:
		_settings_apply_button = Button.new()
		_settings_apply_button.name = "SettingsApplyButton"
		_settings_apply_button.text = "Anwenden"
		_settings_apply_button.custom_minimum_size = Vector2(132.0, 44.0)
		action_row.add_child(_settings_apply_button)
	_settings_reset_button = action_row.get_node_or_null("SettingsResetButton") as Button
	if _settings_reset_button == null:
		_settings_reset_button = Button.new()
		_settings_reset_button.name = "SettingsResetButton"
		_settings_reset_button.text = "Defaults"
		_settings_reset_button.custom_minimum_size = Vector2(132.0, 44.0)
		action_row.add_child(_settings_reset_button)
	_settings_back_button.text = "Abbrechen"
	_order_settings_nodes(action_row)


func _ensure_start_roster_button() -> void:
	var menu_buttons := get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons") as VBoxContainer
	if menu_buttons == null:
		return
	var team_name_row := menu_buttons.get_node_or_null("TeamNameRow") as HBoxContainer
	if team_name_row == null:
		team_name_row = HBoxContainer.new()
		team_name_row.name = "TeamNameRow"
		team_name_row.add_theme_constant_override("separation", 8)
		menu_buttons.add_child(team_name_row)
	_team_name_edit = team_name_row.get_node_or_null("TeamNameEdit") as LineEdit
	if _team_name_edit == null:
		_team_name_edit = LineEdit.new()
		_team_name_edit.name = "TeamNameEdit"
		_team_name_edit.custom_minimum_size = Vector2(276.0, 42.0)
		_team_name_edit.placeholder_text = "Teamname"
		_team_name_edit.focus_mode = Control.FOCUS_ALL
		team_name_row.add_child(_team_name_edit)
	if not _team_name_edit.text_submitted.is_connected(_on_team_name_edit_submitted):
		_team_name_edit.text_submitted.connect(_on_team_name_edit_submitted)
	if not _team_name_edit.focus_exited.is_connected(_on_team_name_edit_focus_exited):
		_team_name_edit.focus_exited.connect(_on_team_name_edit_focus_exited)
	_team_name_suggest_button = team_name_row.get_node_or_null("TeamNameSuggestButton") as Button
	if _team_name_suggest_button == null:
		_team_name_suggest_button = Button.new()
		_team_name_suggest_button.name = "TeamNameSuggestButton"
		_team_name_suggest_button.text = "Neu"
		_team_name_suggest_button.custom_minimum_size = Vector2(76.0, 42.0)
		team_name_row.add_child(_team_name_suggest_button)
	if not _team_name_suggest_button.pressed.is_connected(_on_team_name_suggest_pressed):
		_team_name_suggest_button.pressed.connect(_on_team_name_suggest_pressed)
	_new_roster_button = menu_buttons.get_node_or_null("NewRosterButton") as Button
	if _new_roster_button == null:
		_new_roster_button = Button.new()
		_new_roster_button.name = "NewRosterButton"
		_new_roster_button.custom_minimum_size = Vector2(360.0, 58.0)
		_new_roster_button.focus_mode = Control.FOCUS_ALL
		menu_buttons.add_child(_new_roster_button)
	_new_roster_button.set_meta("roster_action", "new_start_roster")
	_new_roster_button.set_meta("requires_confirmation", true)
	_team_editor_toggle_button = menu_buttons.get_node_or_null("TeamEditorToggleButton") as Button
	if _team_editor_toggle_button == null:
		_team_editor_toggle_button = Button.new()
		_team_editor_toggle_button.name = "TeamEditorToggleButton"
		_team_editor_toggle_button.custom_minimum_size = Vector2(360.0, 48.0)
		_team_editor_toggle_button.focus_mode = Control.FOCUS_ALL
		menu_buttons.add_child(_team_editor_toggle_button)
	_team_editor_toggle_button.set_meta("roster_action", "toggle_team_editor")
	_team_editor_toggle_button.tooltip_text = "Eigenes Rookie-Team mit Bild und Startpunkten bearbeiten."
	if not _team_editor_toggle_button.pressed.is_connected(_on_team_editor_toggle_pressed):
		_team_editor_toggle_button.pressed.connect(_on_team_editor_toggle_pressed)
	_ensure_team_library_panel(menu_buttons)
	_ensure_team_editor_panel(menu_buttons)
	_refresh_start_roster_button()
	_refresh_team_editor_toggle()
	_refresh_team_name_controls()
	_refresh_team_library()
	_refresh_team_editor()


func _ensure_team_library_panel(menu_buttons: VBoxContainer) -> void:
	_team_library_panel = menu_buttons.get_node_or_null("TeamLibraryPanel") as PanelContainer
	if _team_library_panel == null:
		_team_library_panel = PanelContainer.new()
		_team_library_panel.name = "TeamLibraryPanel"
		menu_buttons.add_child(_team_library_panel)
	_team_library_panel.custom_minimum_size = Vector2(360.0, 154.0)
	_team_library_panel.visible = not _team_editor_open
	var margin := _team_library_panel.get_node_or_null("TeamLibraryMargin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "TeamLibraryMargin"
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		_team_library_panel.add_child(margin)
	var vbox := margin.get_node_or_null("TeamLibraryVBox") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "TeamLibraryVBox"
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)
	var header_row := vbox.get_node_or_null("TeamLibraryHeaderRow") as HBoxContainer
	if header_row == null:
		header_row = HBoxContainer.new()
		header_row.name = "TeamLibraryHeaderRow"
		header_row.add_theme_constant_override("separation", 8)
		vbox.add_child(header_row)
	var header_label := header_row.get_node_or_null("TeamLibraryHeaderLabel") as Label
	if header_label == null:
		header_label = Label.new()
		header_label.name = "TeamLibraryHeaderLabel"
		header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(header_label)
	header_label.text = "Erstellte Teams"
	header_label.add_theme_font_size_override("font_size", 13)
	_team_library_activate_button = header_row.get_node_or_null("TeamLibraryActivateButton") as Button
	if _team_library_activate_button == null:
		_team_library_activate_button = Button.new()
		_team_library_activate_button.name = "TeamLibraryActivateButton"
		_team_library_activate_button.text = "Aktiv"
		_team_library_activate_button.custom_minimum_size = Vector2(72.0, 32.0)
		header_row.add_child(_team_library_activate_button)
	if not _team_library_activate_button.pressed.is_connected(_on_team_library_activate_pressed):
		_team_library_activate_button.pressed.connect(_on_team_library_activate_pressed)
	_team_library_delete_button = header_row.get_node_or_null("TeamLibraryDeleteButton") as Button
	if _team_library_delete_button == null:
		_team_library_delete_button = Button.new()
		_team_library_delete_button.name = "TeamLibraryDeleteButton"
		_team_library_delete_button.text = "Loeschen"
		_team_library_delete_button.custom_minimum_size = Vector2(82.0, 32.0)
		header_row.add_child(_team_library_delete_button)
	if not _team_library_delete_button.pressed.is_connected(_on_team_library_delete_pressed):
		_team_library_delete_button.pressed.connect(_on_team_library_delete_pressed)
	_team_library_status_label = vbox.get_node_or_null("TeamLibraryStatusLabel") as Label
	if _team_library_status_label == null:
		_team_library_status_label = Label.new()
		_team_library_status_label.name = "TeamLibraryStatusLabel"
		_team_library_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(_team_library_status_label)
	_team_library_status_label.add_theme_font_size_override("font_size", 11)
	var scroll := vbox.get_node_or_null("TeamLibraryScroll") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		scroll.name = "TeamLibraryScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vbox.add_child(scroll)
	scroll.custom_minimum_size = Vector2(340.0, 74.0)
	_team_library_list = scroll.get_node_or_null("TeamLibraryList") as VBoxContainer
	if _team_library_list == null:
		_team_library_list = VBoxContainer.new()
		_team_library_list.name = "TeamLibraryList"
		_team_library_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_library_list.add_theme_constant_override("separation", 4)
		scroll.add_child(_team_library_list)


func _ensure_team_editor_panel(menu_buttons: VBoxContainer) -> void:
	_team_editor_panel = menu_buttons.get_node_or_null("TeamEditorPanel") as PanelContainer
	if _team_editor_panel == null:
		_team_editor_panel = PanelContainer.new()
		_team_editor_panel.name = "TeamEditorPanel"
		menu_buttons.add_child(_team_editor_panel)
	_team_editor_panel.custom_minimum_size = Vector2(360.0, 242.0)
	_team_editor_panel.visible = _team_editor_open
	_team_editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP if _team_editor_open else Control.MOUSE_FILTER_IGNORE
	var margin := _team_editor_panel.get_node_or_null("TeamEditorMargin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "TeamEditorMargin"
		margin.add_theme_constant_override("margin_left", 10)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 10)
		margin.add_theme_constant_override("margin_bottom", 8)
		_team_editor_panel.add_child(margin)
	var vbox := margin.get_node_or_null("TeamEditorVBox") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "TeamEditorVBox"
		vbox.add_theme_constant_override("separation", 6)
		margin.add_child(vbox)
	var header_label := vbox.get_node_or_null("TeamEditorHeaderLabel") as Label
	if header_label == null:
		header_label = Label.new()
		header_label.name = "TeamEditorHeaderLabel"
		vbox.add_child(header_label)
	header_label.text = "Team selbst erstellen"
	header_label.add_theme_font_size_override("font_size", 13)
	header_label.tooltip_text = "Rookie-Teams haben maximal 30 Startpunkte. Fortschritt soll spaeter spuerbar bleiben."
	var emblem_row := vbox.get_node_or_null("TeamEditorEmblemRow") as HBoxContainer
	if emblem_row == null:
		emblem_row = HBoxContainer.new()
		emblem_row.name = "TeamEditorEmblemRow"
		emblem_row.add_theme_constant_override("separation", 8)
		vbox.add_child(emblem_row)
	_team_editor_emblem_preview = emblem_row.get_node_or_null("TeamEditorEmblemPreview") as TextureRect
	if _team_editor_emblem_preview == null:
		_team_editor_emblem_preview = TextureRect.new()
		_team_editor_emblem_preview.name = "TeamEditorEmblemPreview"
		_team_editor_emblem_preview.custom_minimum_size = Vector2(34.0, 34.0)
		_team_editor_emblem_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_team_editor_emblem_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		emblem_row.add_child(_team_editor_emblem_preview)
	_team_editor_emblem_option = emblem_row.get_node_or_null("TeamEditorEmblemOption") as OptionButton
	if _team_editor_emblem_option == null:
		_team_editor_emblem_option = OptionButton.new()
		_team_editor_emblem_option.name = "TeamEditorEmblemOption"
		_team_editor_emblem_option.custom_minimum_size = Vector2(290.0, 34.0)
		_team_editor_emblem_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		emblem_row.add_child(_team_editor_emblem_option)
	_team_editor_emblem_option.tooltip_text = "Team-Bild aus vorhandenen Portrait-Assets."
	if not _team_editor_emblem_option.item_selected.is_connected(_on_team_editor_emblem_selected):
		_team_editor_emblem_option.item_selected.connect(_on_team_editor_emblem_selected)
	_team_editor_budget_label = vbox.get_node_or_null("TeamEditorBudgetLabel") as Label
	if _team_editor_budget_label == null:
		_team_editor_budget_label = Label.new()
		_team_editor_budget_label.name = "TeamEditorBudgetLabel"
		vbox.add_child(_team_editor_budget_label)
	_team_editor_budget_label.add_theme_font_size_override("font_size", 11)
	_team_editor_budget_label.tooltip_text = "Punkte koennen frei verteilt werden, aber nie ueber das Rookie-Limit hinaus."
	var scroll := vbox.get_node_or_null("TeamEditorStatsScroll") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		scroll.name = "TeamEditorStatsScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		vbox.add_child(scroll)
	scroll.custom_minimum_size = Vector2(340.0, 136.0)
	_team_editor_stats_vbox = scroll.get_node_or_null("TeamEditorStatsVBox") as VBoxContainer
	if _team_editor_stats_vbox == null:
		_team_editor_stats_vbox = VBoxContainer.new()
		_team_editor_stats_vbox.name = "TeamEditorStatsVBox"
		_team_editor_stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_editor_stats_vbox.add_theme_constant_override("separation", 4)
		scroll.add_child(_team_editor_stats_vbox)


func _refresh_start_roster_button() -> void:
	if _new_roster_button == null:
		return
	_new_roster_button.text = "Team neu bestaetigen" if _start_roster_reset_confirmation_pending else "Neues Team generieren"
	_new_roster_button.tooltip_text = "Ersetzt das Startteam erst nach Bestaetigung." if _start_roster_reset_confirmation_pending else "Automatisch ein neues Startteam generieren."


func _refresh_team_editor_toggle() -> void:
	if _team_editor_toggle_button == null:
		return
	_team_editor_toggle_button.text = "Team-Editor schliessen" if _team_editor_open else "Team selbst erstellen"
	_team_editor_toggle_button.tooltip_text = "Team-Editor einklappen." if _team_editor_open else "Eigenes Rookie-Team mit Bild und Startpunkten bearbeiten."


func _set_team_editor_open(open: bool) -> void:
	_team_editor_open = open
	if _team_editor_panel != null:
		_team_editor_panel.visible = _team_editor_open
		_team_editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP if _team_editor_open else Control.MOUSE_FILTER_IGNORE
	if _team_library_panel != null:
		_team_library_panel.visible = not _team_editor_open
		_team_library_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE if _team_editor_open else Control.MOUSE_FILTER_STOP
	_refresh_team_editor_toggle()


func _refresh_team_name_controls() -> void:
	if _team_name_edit == null:
		return
	var snapshot: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("build_team_identity_snapshot", _start_roster))
	_team_name_edit.text = String(snapshot.get("team_name", ""))
	_team_name_edit.tooltip_text = "Teamname fuer Roster/Homebase/FOB."
	if _team_name_suggest_button != null:
		_team_name_suggest_button.tooltip_text = "Neuen Teamnamen vorschlagen."


func _refresh_team_library() -> void:
	if _team_library_list == null:
		return
	var library: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("list_roster_entries", _start_roster_profile_id, _start_roster_save_path))
	_team_library_entries = Array(library.get("entries", [])).duplicate(true)
	var active_path: String = String(library.get("active_path", _start_roster_save_path))
	if _selected_roster_entry_path.strip_edges().is_empty() or _find_team_library_entry(_selected_roster_entry_path).is_empty():
		_selected_roster_entry_path = active_path
	_clear_children(_team_library_list)
	for entry_variant in _team_library_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var row := Button.new()
		row.name = "TeamLibraryEntryButton"
		row.toggle_mode = true
		row.focus_mode = Control.FOCUS_ALL
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(320.0, 30.0)
		row.clip_text = true
		row.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.text = _format_team_library_entry(entry)
		row.tooltip_text = String(entry.get("path", ""))
		row.set_meta("roster_entry_path", String(entry.get("path", "")))
		row.set_meta("team_name", String(entry.get("team_name", "")))
		row.set_meta("active_roster", bool(entry.get("active", false)))
		row.set_meta("archived_roster", bool(entry.get("archived", false)))
		row.set_pressed_no_signal(String(entry.get("path", "")) == _selected_roster_entry_path)
		row.pressed.connect(_on_team_library_row_pressed.bind(String(entry.get("path", ""))))
		_team_library_list.add_child(row)
	_refresh_team_library_status()


func _refresh_team_library_status() -> void:
	var selected_entry: Dictionary = _find_team_library_entry(_selected_roster_entry_path)
	var selected_name: String = String(selected_entry.get("team_name", "")).strip_edges()
	if selected_name.is_empty():
		selected_name = "kein Team"
	var selected_active: bool = bool(selected_entry.get("active", false))
	if _team_library_status_label != null:
		var prefix: String = "Ausgewaehlt"
		if selected_active:
			prefix = "Ausgewaehlt aktiv"
		elif bool(selected_entry.get("archived", false)):
			prefix = "Ausgewaehlt Archiv"
		_team_library_status_label.text = "%s: %s" % [prefix, selected_name]
	if _team_library_delete_button != null:
		var can_delete: bool = not selected_entry.is_empty() and bool(selected_entry.get("can_delete", false)) and not selected_active
		_team_library_delete_button.disabled = not can_delete
		_team_library_delete_button.tooltip_text = "Archiv-Team loeschen." if can_delete else "Aktives Team bleibt geschuetzt."
	if _team_library_activate_button != null:
		var can_activate: bool = not selected_entry.is_empty() and not selected_active and bool(selected_entry.get("valid", false))
		_team_library_activate_button.disabled = not can_activate
		_team_library_activate_button.tooltip_text = "Archiv-Team als aktives Startteam verwenden." if can_activate else "Aktives Team ist bereits ausgewaehlt."


func _format_team_library_entry(entry: Dictionary) -> String:
	var team_name: String = String(entry.get("team_name", "")).strip_edges()
	if team_name.is_empty():
		team_name = "Unbenanntes Team"
	var marker: String = "AKTIV" if bool(entry.get("active", false)) else "ARCHIV"
	var roster_size: int = int(entry.get("roster_size", 0))
	return "%s  %s  (%d)" % [marker, team_name, roster_size]


func _find_team_library_entry(entry_path: String) -> Dictionary:
	var normalized_path: String = entry_path.strip_edges()
	for entry_variant in _team_library_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if String(entry.get("path", "")) == normalized_path:
			return entry
	return {}


func _delete_selected_team_entry(play_sound: bool = true) -> Dictionary:
	var selected_entry: Dictionary = _find_team_library_entry(_selected_roster_entry_path)
	if selected_entry.is_empty():
		return {"ok": false, "reason": "missing_selection"}
	var result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("delete_roster_entry", _selected_roster_entry_path, _start_roster_profile_id, _start_roster_save_path))
	if bool(result.get("ok", false)):
		_selected_roster_entry_path = _start_roster_save_path
		_status_label.text = "Team geloescht"
		if play_sound:
			_play_ui_sfx("confirm", "delete_roster_entry")
	else:
		_status_label.text = "Team bleibt aktiv" if String(result.get("reason", "")) == "active_roster_protected" else "Loeschen fehlgeschlagen"
		if play_sound:
			_play_ui_sfx("warning", "delete_roster_entry_failed")
	_refresh_team_library()
	return result


func _activate_selected_team_entry(play_sound: bool = true) -> Dictionary:
	var selected_entry: Dictionary = _find_team_library_entry(_selected_roster_entry_path)
	if selected_entry.is_empty():
		return {"ok": false, "reason": "missing_selection"}
	var result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("activate_roster_entry", _selected_roster_entry_path, _start_roster_profile_id, _start_roster_save_path))
	if bool(result.get("ok", false)):
		_start_roster = Dictionary(result.get("roster", {})).duplicate(true)
		_normalize_start_team_editor(true)
		_selected_roster_entry_path = _start_roster_save_path
		_last_start_roster_store_result = Dictionary(result.get("save", result)).duplicate(true)
		_refresh_team_name_controls()
		_status_label.text = "Team aktiviert"
		if play_sound:
			_play_ui_sfx("confirm", "activate_roster_entry")
	else:
		_status_label.text = "Aktivieren fehlgeschlagen"
		if play_sound:
			_play_ui_sfx("warning", "activate_roster_entry_failed")
	_refresh_team_library()
	_refresh_team_editor()
	return result


func _get_normalized_team_editor(save_if_changed: bool) -> Dictionary:
	if _start_roster.is_empty():
		return Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", {}, _start_roster_seed, _start_roster_profile_id))
	return _normalize_start_team_editor(save_if_changed)


func _normalize_start_team_editor(save_if_changed: bool) -> Dictionary:
	var current_editor: Dictionary = Dictionary(_start_roster.get("team_editor", {})).duplicate(true)
	var normalized: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", current_editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id))
	if _start_roster.is_empty():
		return normalized
	if current_editor != normalized:
		_start_roster["team_editor"] = normalized
		if save_if_changed:
			_save_start_roster_state("team_editor_normalized")
	return normalized


func _refresh_team_editor() -> void:
	if _team_editor_panel == null or _team_editor_stats_vbox == null:
		return
	var editor: Dictionary = _get_normalized_team_editor(false)
	_refresh_team_editor_emblems(editor)
	var budget_used: int = int(editor.get("point_budget_used", 0))
	var budget_max: int = int(editor.get("point_budget_max", 0))
	var budget_available: int = int(editor.get("point_budget_available", 0))
	if _team_editor_budget_label != null:
		_team_editor_budget_label.text = "Rookie-Punkte %d/%d | frei %d" % [budget_used, budget_max, budget_available]
	_clear_children(_team_editor_stats_vbox)
	_team_editor_stat_rows.clear()
	var allocations: Dictionary = Dictionary(editor.get("stat_allocations", {}))
	for definition_variant in Array(editor.get("stat_definitions", [])):
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var stat_id: String = String(definition.get("id", "")).strip_edges()
		if stat_id.is_empty():
			continue
		var row := _build_team_editor_stat_row(definition, int(allocations.get(stat_id, 0)), budget_available)
		_team_editor_stats_vbox.add_child(row)


func _refresh_team_editor_emblems(editor: Dictionary) -> void:
	if _team_editor_emblem_option == null:
		return
	var selected_emblem_id: String = String(editor.get("emblem_id", "")).strip_edges()
	_team_editor_emblem_option.clear()
	var options: Array = _build_team_editor_emblem_options(editor)
	for option_variant in options:
		var option: Dictionary = Dictionary(option_variant)
		var emblem_id: String = String(option.get("id", "")).strip_edges()
		_team_editor_emblem_option.add_item(String(option.get("label", emblem_id)))
		var item_index: int = _team_editor_emblem_option.item_count - 1
		_team_editor_emblem_option.set_item_metadata(item_index, option)
		if emblem_id == selected_emblem_id:
			_team_editor_emblem_option.select(item_index)
	if _team_editor_emblem_option.selected < 0 and _team_editor_emblem_option.item_count > 0:
		_team_editor_emblem_option.select(0)
	if _team_editor_emblem_preview != null:
		_team_editor_emblem_preview.texture = _load_res_texture(String(editor.get("emblem_path", "")))
		_team_editor_emblem_preview.modulate = Color(1.0, 1.0, 1.0, 1.0) if _team_editor_emblem_preview.texture != null else Color(0.38, 0.44, 0.48, 0.85)


func _build_team_editor_stat_row(definition: Dictionary, value: int, budget_available: int) -> HBoxContainer:
	var stat_id: String = String(definition.get("id", "")).strip_edges()
	var row := HBoxContainer.new()
	row.name = "TeamEditorStat_%s" % stat_id
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	row.tooltip_text = String(definition.get("description", ""))
	var label := Label.new()
	label.name = "TeamEditorStatLabel_%s" % stat_id
	label.text = String(definition.get("label", stat_id.capitalize()))
	label.custom_minimum_size = Vector2(90.0, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.tooltip_text = row.tooltip_text
	label.add_theme_font_size_override("font_size", 10)
	row.add_child(label)
	var minus_button := Button.new()
	minus_button.name = "TeamEditorMinus_%s" % stat_id
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(24.0, 24.0)
	minus_button.disabled = value <= 0
	minus_button.tooltip_text = "Punkt abziehen: %s" % String(definition.get("description", ""))
	minus_button.pressed.connect(_on_team_editor_stat_delta_pressed.bind(stat_id, -TEAM_EDITOR_POINT_DELTA))
	row.add_child(minus_button)
	var value_bar := ProgressBar.new()
	value_bar.name = "TeamEditorValue_%s" % stat_id
	value_bar.min_value = 0.0
	value_bar.max_value = float(START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_POINT_BUDGET_MAX)
	value_bar.value = float(value)
	value_bar.show_percentage = false
	value_bar.custom_minimum_size = Vector2(54.0, 18.0)
	value_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_bar.tooltip_text = row.tooltip_text
	row.add_child(value_bar)
	var value_label := Label.new()
	value_label.name = "TeamEditorValueLabel_%s" % stat_id
	value_label.text = "%02d" % value
	value_label.custom_minimum_size = Vector2(28.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.add_theme_font_size_override("font_size", 10)
	row.add_child(value_label)
	var plus_button := Button.new()
	plus_button.name = "TeamEditorPlus_%s" % stat_id
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(24.0, 24.0)
	plus_button.disabled = budget_available <= 0
	plus_button.tooltip_text = "Punkt vergeben: %s" % String(definition.get("description", ""))
	plus_button.pressed.connect(_on_team_editor_stat_delta_pressed.bind(stat_id, TEAM_EDITOR_POINT_DELTA))
	row.add_child(plus_button)
	_team_editor_stat_rows[stat_id] = {
		"row": row,
		"minus": minus_button,
		"plus": plus_button,
		"value": value_label,
		"bar": value_bar,
	}
	return row


func _adjust_team_editor_stat(stat_id: String, delta: int, play_sound: bool = true) -> Dictionary:
	var editor: Dictionary = _get_normalized_team_editor(false)
	var allocations: Dictionary = Dictionary(editor.get("stat_allocations", {})).duplicate(true)
	var normalized_stat_id: String = stat_id.strip_edges()
	if normalized_stat_id.is_empty() or not allocations.has(normalized_stat_id):
		return {"ok": false, "reason": "unknown_stat", "stat_id": stat_id}
	var current_value: int = int(allocations.get(normalized_stat_id, 0))
	var target_value: int = current_value + delta
	return _set_team_editor_stat(normalized_stat_id, target_value, play_sound)


func _set_team_editor_stat(stat_id: String, target_value: int, play_sound: bool = true) -> Dictionary:
	var editor: Dictionary = _get_normalized_team_editor(false)
	var allocations: Dictionary = Dictionary(editor.get("stat_allocations", {})).duplicate(true)
	var normalized_stat_id: String = stat_id.strip_edges()
	if normalized_stat_id.is_empty() or not allocations.has(normalized_stat_id):
		return {"ok": false, "reason": "unknown_stat", "stat_id": stat_id}
	var current_value: int = int(allocations.get(normalized_stat_id, 0))
	var other_used: int = int(editor.get("point_budget_used", 0)) - current_value
	var budget_max: int = int(editor.get("point_budget_max", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_POINT_BUDGET_MAX))
	var next_value: int = clampi(target_value, 0, maxi(budget_max - other_used, 0))
	allocations[normalized_stat_id] = next_value
	editor["stat_allocations"] = allocations
	_start_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
	var save_result: Dictionary = _save_start_roster_state("team_editor_stat")
	_refresh_team_editor()
	if play_sound:
		_play_ui_sfx("switch" if next_value != current_value else "warning", "team_editor_stat")
	return {
		"ok": bool(save_result.get("ok", false)),
		"changed": next_value != current_value,
		"stat_id": normalized_stat_id,
		"value": next_value,
		"save": save_result,
	}


func _set_team_editor_emblem(emblem_id: String, play_sound: bool = true) -> Dictionary:
	var normalized_id: String = emblem_id.strip_edges()
	var options: Array = _build_team_editor_emblem_options(_get_normalized_team_editor(false))
	for option_variant in options:
		var option: Dictionary = Dictionary(option_variant)
		if String(option.get("id", "")) != normalized_id:
			continue
		var editor: Dictionary = _get_normalized_team_editor(false)
		editor["emblem_id"] = normalized_id
		editor["emblem_path"] = String(option.get("path", ""))
		_start_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		var save_result: Dictionary = _save_start_roster_state("team_editor_emblem")
		_refresh_team_editor()
		if play_sound:
			_play_ui_sfx("switch", "team_editor_emblem")
		return {"ok": bool(save_result.get("ok", false)), "emblem_id": normalized_id, "save": save_result}
	return {"ok": false, "reason": "unknown_emblem", "emblem_id": emblem_id}


func _save_start_roster_state(_reason: String) -> Dictionary:
	if _start_roster.is_empty():
		return {"ok": false, "reason": "missing_roster"}
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", _start_roster, _start_roster_profile_id, _start_roster_save_path))
	_last_start_roster_store_result = save_result.duplicate(true)
	return save_result


func _build_team_editor_emblem_options(editor: Dictionary) -> Array:
	var result: Array = []
	var seen_ids: Dictionary = {}
	var current_id: String = String(editor.get("emblem_id", "")).strip_edges()
	var current_path: String = String(editor.get("emblem_path", "")).strip_edges()
	if not current_id.is_empty():
		result.append({"id": current_id, "path": current_path, "label": _format_emblem_label(current_id)})
		seen_ids[current_id] = true
	for entry_variant in Array(PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("get_candidate_entries")):
		if result.size() >= 12:
			break
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_id: String = String(entry.get("id", "")).strip_edges()
		if entry_id.is_empty() or seen_ids.has(entry_id):
			continue
		result.append({"id": entry_id, "path": String(entry.get("path", "")), "label": _format_emblem_label(entry_id)})
		seen_ids[entry_id] = true
	return result


func _format_emblem_label(emblem_id: String) -> String:
	var normalized: String = emblem_id.replace("char_portrait_", "Portrait ").replace("_", " ")
	return normalized.capitalize()


func _load_res_texture(path: String) -> Texture2D:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty() or not ResourceLoader.exists(normalized_path):
		return null
	return load(normalized_path) as Texture2D


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _ensure_contextual_help_ui() -> void:
	if _help_service == null:
		_help_service = CONTEXTUAL_HELP_SERVICE_SCRIPT.new()
		_help_service.call("load_catalog")
	_apply_contextual_help_mode_to_service(_gameplay_settings)
	_global_help_button = get_node_or_null("GlobalHelpButton") as Button
	if _global_help_button == null:
		_global_help_button = Button.new()
		_global_help_button.name = "GlobalHelpButton"
		_global_help_button.text = "?"
		_global_help_button.custom_minimum_size = Vector2(44.0, 44.0)
		_global_help_button.focus_mode = Control.FOCUS_ALL
		add_child(_global_help_button)
	_global_help_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_global_help_button.offset_left = -64.0
	_global_help_button.offset_top = 24.0
	_global_help_button.offset_right = -20.0
	_global_help_button.offset_bottom = 68.0
	_global_help_button.set_meta("help_id", "shell.global_help_button")
	_global_help_button.set_meta("global_help_button", true)
	if not _global_help_button.pressed.is_connected(_on_global_help_pressed):
		_global_help_button.pressed.connect(_on_global_help_pressed)
	_contextual_help_popup = get_node_or_null("ContextualHelpPopup") as Control
	if _contextual_help_popup == null:
		_contextual_help_popup = CONTEXTUAL_HELP_POPUP_SCRIPT.new()
		_contextual_help_popup.name = "ContextualHelpPopup"
		_contextual_help_popup.z_index = 90
		add_child(_contextual_help_popup)
	_register_main_menu_help_ids()


func _register_main_menu_help_ids() -> void:
	_connect_help_control(_singleplayer_button, "main_menu.primary_routes")
	_connect_help_control(_multiplayer_button, "main_menu.primary_routes")
	_connect_help_control(_editor_button, "main_menu.primary_routes")
	_connect_help_control(_settings_button, "main_menu.primary_routes")
	_connect_help_control(_new_roster_button, "main_menu.primary_routes")
	_connect_help_control(_team_editor_toggle_button, "main_menu.primary_routes")
	_connect_help_control(_team_library_activate_button, "main_menu.primary_routes")
	_connect_help_control(_team_library_delete_button, "main_menu.primary_routes")
	_connect_help_control(_team_editor_emblem_option, "main_menu.primary_routes")
	_connect_help_control(_global_help_button, "shell.global_help_button")
	_connect_help_control(_display_section_label, "settings.display")
	_connect_help_control(_resolution_option, "settings.display")
	_connect_help_control(_window_mode_option, "settings.display")
	_connect_help_control(_fullscreen_check, "settings.display")
	_connect_help_control(_vsync_check, "settings.display")
	_connect_help_control(_audio_section_label, "settings.audio")
	_connect_help_control(_master_volume_slider, "settings.audio")
	_connect_help_control(_music_volume_slider, "settings.audio")
	_connect_help_control(_sfx_volume_slider, "settings.audio")
	_connect_help_control(_input_section_label, "settings.input")
	_connect_help_control(_input_actions_label, "settings.input")
	_connect_help_control(_gameplay_section_label, "settings.gameplay")
	_connect_help_control(_fog_of_war_option, "settings.fog_of_war_mode")
	_connect_help_control(_contextual_help_option, "settings.contextual_help_mode")
	_connect_help_control(_bubble_mode_option, "settings.gameplay")


func _connect_help_control(control: Control, help_id: String) -> void:
	if control == null:
		return
	if _help_service != null:
		_help_service.call("register_control", control, help_id)
	var enter_callable := Callable(self, "_on_help_target_entered").bind(control, help_id)
	var exit_callable := Callable(self, "_on_help_target_exited").bind(control)
	if not control.mouse_entered.is_connected(enter_callable):
		control.mouse_entered.connect(enter_callable)
	if not control.focus_entered.is_connected(enter_callable):
		control.focus_entered.connect(enter_callable)
	if not control.mouse_exited.is_connected(exit_callable):
		control.mouse_exited.connect(exit_callable)
	if not control.focus_exited.is_connected(exit_callable):
		control.focus_exited.connect(exit_callable)


func _order_settings_nodes(action_row: HBoxContainer) -> void:
	var ordered_nodes: Array = [
		_settings_vbox.get_node_or_null("SettingsTitleLabel"),
		_display_section_label,
		_resolution_option,
		_window_mode_option,
		_fullscreen_check,
		_vsync_check,
		_audio_section_label,
		_master_volume_slider,
		_music_volume_slider,
		_sfx_volume_slider,
		_input_section_label,
		_input_actions_label,
		_gameplay_section_label,
		_fog_of_war_option,
		_contextual_help_mode_label,
		_contextual_help_option,
		_settings_vbox.get_node_or_null("BubbleModeLabel"),
		_bubble_mode_option,
		_thought_hold_label,
		_settings_vbox.get_node_or_null("SettingsNoteLabel"),
		action_row,
		_settings_back_button,
	]
	var target_index: int = 0
	for node in ordered_nodes:
		if node == null or node.get_parent() != _settings_vbox:
			continue
		_settings_vbox.move_child(node, target_index)
		target_index += 1


func _ensure_settings_label(node_name: String, text: String, font_size: int) -> Label:
	var label := _settings_vbox.get_node_or_null(node_name) as Label
	if label == null:
		label = Label.new()
		label.name = node_name
		_settings_vbox.add_child(label)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _ensure_settings_option(node_name: String, min_size: Vector2) -> OptionButton:
	var option := _settings_vbox.get_node_or_null(node_name) as OptionButton
	if option == null:
		option = OptionButton.new()
		option.name = node_name
		_settings_vbox.add_child(option)
	option.custom_minimum_size = min_size
	return option


func _ensure_settings_check(node_name: String, text: String) -> CheckButton:
	var check := _settings_vbox.get_node_or_null(node_name) as CheckButton
	if check == null:
		check = CheckButton.new()
		check.name = node_name
		_settings_vbox.add_child(check)
	check.text = text
	return check


func _ensure_settings_slider(node_name: String) -> HSlider:
	var slider := _settings_vbox.get_node_or_null(node_name) as HSlider
	if slider == null:
		slider = HSlider.new()
		slider.name = node_name
		_settings_vbox.add_child(slider)
	slider.custom_minimum_size = Vector2(360.0, 30.0)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	return slider


func _refresh_settings_controls_from_current() -> void:
	_draft_gameplay_settings = _gameplay_settings.duplicate(true)
	_draft_comic_bubble_settings = _comic_bubble_settings.duplicate(true)
	_refresh_settings_controls(_gameplay_settings, _comic_bubble_settings)


func _refresh_settings_controls_from_draft() -> void:
	_refresh_settings_controls(_draft_gameplay_settings, _draft_comic_bubble_settings)


func _refresh_settings_controls(gameplay_settings: Dictionary, comic_settings: Dictionary) -> void:
	var gameplay: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", gameplay_settings))
	var comic: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("normalize_settings", comic_settings))
	if _resolution_option != null:
		SETTINGS_SCREEN_SCRIPT.call("configure_option_button", _resolution_option, GAME_SETTINGS_CONTRACT_SCRIPT.RESOLUTION_PRESETS, String(gameplay.get("resolution_preset", "1920x1080")))
	if _window_mode_option != null:
		SETTINGS_SCREEN_SCRIPT.call(
			"configure_option_button",
			_window_mode_option,
			GAME_SETTINGS_CONTRACT_SCRIPT.VALID_WINDOW_MODES,
			String(gameplay.get("window_mode", "windowed")),
			{
				"windowed": "Fenster",
				"borderless": "Randlos",
				"fullscreen": "Vollbild",
			}
		)
	if _vsync_check != null:
		_vsync_check.set_pressed_no_signal(bool(gameplay.get("vsync_enabled", true)))
	_master_volume_slider.set_value_no_signal(float(gameplay.get("master_volume", 80.0)))
	if _music_volume_slider != null:
		_music_volume_slider.set_value_no_signal(float(gameplay.get("music_volume", 80.0)))
	if _sfx_volume_slider != null:
		_sfx_volume_slider.set_value_no_signal(float(gameplay.get("sfx_volume", 80.0)))
	_fullscreen_check.set_pressed_no_signal(String(gameplay.get("window_mode", "windowed")) == "fullscreen")
	_configure_bubble_mode_option(comic)
	if _fog_of_war_option != null:
		var gameplay_snapshot: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("build_snapshot", gameplay))
		SETTINGS_SCREEN_SCRIPT.call(
			"configure_option_button",
			_fog_of_war_option,
			PackedStringArray(gameplay_snapshot.get("valid_fog_of_war_modes", PackedStringArray())),
			String(gameplay.get("fog_of_war_mode", "known_terrain")),
			{
				"off": "Aus",
				"known_terrain": "Bekanntes Terrain",
				"unexplored_blackout": "Blackout",
			}
		)
	if _contextual_help_option != null:
		SETTINGS_SCREEN_SCRIPT.call(
			"configure_option_button",
			_contextual_help_option,
			GAME_SETTINGS_CONTRACT_SCRIPT.VALID_CONTEXTUAL_HELP_MODES,
			String(gameplay.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.CONTEXTUAL_HELP_MODE_COMPACT)),
			{
				"off": "Aus",
				"compact": "Kompakt",
				"expanded": "Erweitert",
			}
		)
	_apply_contextual_help_mode_to_service(gameplay)
	_refresh_thought_hold_label(comic)
	if _input_actions_label != null:
		_input_actions_label.text = _build_input_actions_text()


func _build_input_actions_text() -> String:
	var actions: Array = Array(GAME_SETTINGS_CONTRACT_SCRIPT.call("get_input_action_descriptors"))
	var lines: PackedStringArray = PackedStringArray()
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = Dictionary(action_variant)
		lines.append("%s: %s" % [String(action.get("label", "")), String(action.get("prompt", ""))])
	return "\n".join(lines)


func _load_comic_bubble_settings() -> void:
	_comic_bubble_settings = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("load_settings", _settings_config_path))
	_gameplay_settings = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("load_settings", _settings_config_path))
	_configure_bubble_mode_option(_comic_bubble_settings)
	_refresh_thought_hold_label(_comic_bubble_settings)
	_apply_contextual_help_mode_to_service(_gameplay_settings)


func _configure_bubble_mode_option(settings: Dictionary = {}) -> void:
	if _bubble_mode_option == null:
		return
	_bubble_mode_option.clear()
	for mode in ["off", "minimal", "normal"]:
		_bubble_mode_option.add_item(_mode_label(mode))
		var item_index: int = _bubble_mode_option.item_count - 1
		_bubble_mode_option.set_item_metadata(item_index, mode)
	var active_mode: String = String(settings.get("mode", _comic_bubble_settings.get("mode", "normal")))
	for index in range(_bubble_mode_option.item_count):
		if String(_bubble_mode_option.get_item_metadata(index)) == active_mode:
			_bubble_mode_option.select(index)
			return
	_bubble_mode_option.select(2)


func _refresh_thought_hold_label(settings: Dictionary = {}) -> void:
	if _thought_hold_label == null:
		return
	var source_settings: Dictionary = settings if not settings.is_empty() else _comic_bubble_settings
	var snapshot: Dictionary = Dictionary(COMIC_BUBBLE_SETTINGS_SCRIPT.call("build_snapshot", source_settings))
	_thought_hold_label.text = "NPC-Gedanken: halten %s" % String(snapshot.get("thought_peek_hold_prompt", "T"))


func _apply_contextual_help_mode_to_service(settings: Dictionary) -> void:
	if _help_service == null:
		return
	var normalized: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", settings))
	_help_service.call("set_help_mode", String(normalized.get(GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE, GAME_SETTINGS_CONTRACT_SCRIPT.CONTEXTUAL_HELP_MODE_COMPACT)))
	if _contextual_help_popup != null and not bool(_help_service.call("is_help_enabled")):
		_contextual_help_popup.call("hide_help")


func _on_help_target_entered(control: Control, help_id: String) -> void:
	if control == null or _help_service == null:
		return
	_help_hover_token += 1
	var token: int = _help_hover_token
	_active_help_control = control
	_active_help_id = help_id
	_schedule_help_popup(token, help_id, control)


func _on_help_target_exited(control: Control) -> void:
	if control == null or control != _active_help_control:
		return
	_help_hover_token += 1
	_active_help_control = null
	_active_help_id = ""
	_hide_help_after_delay(_help_hover_token)


func _schedule_help_popup(token: int, help_id: String, control: Control) -> void:
	var compact_delay: float = 0.0 if bool(_help_service.call("is_global_help_active")) else CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_COMPACT_DELAY_SECONDS
	if compact_delay > 0.0:
		await get_tree().create_timer(compact_delay).timeout
	if not _help_hover_is_current(token, help_id, control):
		return
	_show_contextual_help_for(help_id, control, false)
	if String(_help_service.call("get_help_mode")) != CONTEXTUAL_HELP_SERVICE_SCRIPT.MODE_EXPANDED:
		return
	var detail_delay: float = maxf(0.0, CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_DETAIL_DELAY_SECONDS - compact_delay)
	if detail_delay > 0.0:
		await get_tree().create_timer(detail_delay).timeout
	if _help_hover_is_current(token, help_id, control):
		_show_contextual_help_for(help_id, control, true)


func _hide_help_after_delay(token: int) -> void:
	await get_tree().create_timer(0.15).timeout
	if token == _help_hover_token and _contextual_help_popup != null:
		_contextual_help_popup.call("hide_help")


func _help_hover_is_current(token: int, help_id: String, control: Control) -> bool:
	return token == _help_hover_token and control != null and control == _active_help_control and help_id == _active_help_id and is_instance_valid(control)


func _show_contextual_help_for(help_id: String, control: Control, pinned: bool = false) -> void:
	if _help_service == null or _contextual_help_popup == null or control == null:
		return
	var hover_seconds: float = CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_DETAIL_DELAY_SECONDS if pinned else CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_COMPACT_DELAY_SECONDS
	var payload: Dictionary = Dictionary(_help_service.call("request_help", help_id, hover_seconds, pinned))
	if String(payload.get("level", CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_NONE)) == CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_NONE or payload.is_empty():
		_contextual_help_popup.call("hide_help")
		return
	var target_rect: Rect2 = Rect2(control.global_position, control.size)
	var viewport_size: Vector2 = get_viewport_rect().size
	_contextual_help_popup.call("show_help", payload, target_rect, viewport_size, String(payload.get("level", "")) == CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_DETAIL)


func _mode_label(mode: String) -> String:
	match mode.strip_edges().to_lower():
		"off":
			return "Aus"
		"minimal":
			return "Minimal"
		"debug":
			return "Debug"
		"compact":
			return "Kompakt"
		"expanded":
			return "Erweitert"
		_:
			return "Normal"


func _ensure_audio_event_bus():
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus):
		return _audio_event_bus
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	if tree != null:
		var current_scene := tree.current_scene
		if current_scene != null:
			var scene_bus := current_scene.find_child("AudioEventBus", true, false)
			if scene_bus != null and scene_bus.has_method("emit_ui_action"):
				_audio_event_bus = scene_bus
				if _audio_event_bus.has_method("apply_settings"):
					_audio_event_bus.call("apply_settings", _gameplay_settings)
				return _audio_event_bus
		var root_bus := tree.root.find_child("AudioEventBus", true, false)
		if root_bus != null and root_bus.has_method("emit_ui_action"):
			_audio_event_bus = root_bus
			if _audio_event_bus.has_method("apply_settings"):
				_audio_event_bus.call("apply_settings", _gameplay_settings)
			return _audio_event_bus
	_audio_event_bus = AUDIO_EVENT_BUS_SCRIPT.new()
	_audio_event_bus.name = "AudioEventBus"
	var parent: Node = self
	if tree != null and tree.current_scene != null:
		parent = tree.current_scene
	parent.add_child(_audio_event_bus)
	if _audio_event_bus.has_method("initialize"):
		_audio_event_bus.call("initialize", "res://data/audio_sfx_catalog.json", _gameplay_settings)
	return _audio_event_bus


func _play_ui_sfx(action_type: String, action_id: String) -> void:
	var bus = _ensure_audio_event_bus()
	if bus == null or not bus.has_method("emit_ui_action"):
		return
	bus.call("emit_ui_action", action_type, {
		"action_id": action_id,
		"unit_id": "main_menu",
		"dedupe_key": "main_menu:%s" % action_id,
		"dedupe_window_msec": 40,
	})


func _on_singleplayer_pressed() -> void:
	_play_ui_sfx("confirm", "singleplayer")
	_change_scene(SINGLEPLAYER_SCENE_PATH)


func _on_multiplayer_pressed() -> void:
	_play_ui_sfx("confirm", "multiplayer")
	_change_scene(MULTIPLAYER_SCENE_PATH)


func _on_editor_pressed() -> void:
	_play_ui_sfx("confirm", "editor")
	_change_scene(EDITOR_SCENE_PATH)


func _on_new_roster_pressed() -> void:
	_play_ui_sfx("confirm" if _start_roster_reset_confirmation_pending else "click", "new_roster")
	if _start_roster_reset_confirmation_pending:
		confirm_new_start_roster()
	else:
		request_new_start_roster()


func _on_team_editor_toggle_pressed() -> void:
	toggle_team_editor()
	_status_label.text = "Team-Editor" if _team_editor_open else "Ready"
	_play_ui_sfx("switch", "team_editor_toggle")


func _on_team_name_edit_submitted(next_text: String) -> void:
	set_start_team_name(next_text)


func _on_team_name_edit_focus_exited() -> void:
	if _team_name_edit != null:
		set_start_team_name(_team_name_edit.text)


func _on_team_name_suggest_pressed() -> void:
	request_start_team_name_suggestion()


func _on_team_library_row_pressed(entry_path: String) -> void:
	_selected_roster_entry_path = entry_path.strip_edges()
	_refresh_team_library()
	_play_ui_sfx("switch", "team_library_select")


func _on_team_library_activate_pressed() -> void:
	_activate_selected_team_entry(true)


func _on_team_library_delete_pressed() -> void:
	_delete_selected_team_entry(true)


func _on_team_editor_emblem_selected(index: int) -> void:
	if _team_editor_emblem_option == null or index < 0 or index >= _team_editor_emblem_option.item_count:
		return
	var option: Dictionary = Dictionary(_team_editor_emblem_option.get_item_metadata(index))
	_set_team_editor_emblem(String(option.get("id", "")), true)


func _on_team_editor_stat_delta_pressed(stat_id: String, delta: int) -> void:
	_adjust_team_editor_stat(stat_id, delta, true)


func _on_global_help_pressed() -> void:
	if _help_service == null:
		return
	var active: bool = bool(_help_service.call("toggle_global_help_active"))
	if active:
		_show_contextual_help_for("shell.global_help_button", _global_help_button, true)
		_status_label.text = "Help mode"
	else:
		if _contextual_help_popup != null:
			_contextual_help_popup.call("hide_help")
		_status_label.text = "Ready"
	_play_ui_sfx("switch", "contextual_help")


func _change_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		_status_label.text = "Missing"
		_play_ui_sfx("warning", "missing_scene")
		push_warning("Main menu route missing: %s" % scene_path)
		return
	var error: Error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		_status_label.text = "Failed"
		_play_ui_sfx("warning", "scene_change_failed")
		push_warning("Main menu route failed: %s (%d)" % [scene_path, error])


func _apply_runtime_settings(settings: Dictionary) -> void:
	var normalized_settings: Dictionary = Dictionary(GAME_SETTINGS_CONTRACT_SCRIPT.call("normalize_settings", settings))
	_apply_audio_bus_volume("Master", float(normalized_settings.get("master_volume", 80.0)))
	_apply_audio_bus_volume("Music", float(normalized_settings.get("music_volume", 80.0)))
	_apply_audio_bus_volume("SFX", float(normalized_settings.get("sfx_volume", 80.0)))
	_apply_audio_bus_volume("UI", float(normalized_settings.get("ui_volume", 100.0)))
	_apply_audio_bus_volume("Combat", float(normalized_settings.get("combat_volume", 100.0)))
	_apply_audio_bus_volume("Movement", float(normalized_settings.get("movement_volume", 100.0)))
	_apply_audio_bus_volume("Ambient", float(normalized_settings.get("ambient_volume", 100.0)))
	_apply_contextual_help_mode_to_service(normalized_settings)
	if _audio_event_bus != null and is_instance_valid(_audio_event_bus) and _audio_event_bus.has_method("apply_settings"):
		_audio_event_bus.call("apply_settings", normalized_settings)
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(normalized_settings.get("vsync_enabled", true)) else DisplayServer.VSYNC_DISABLED)
	var window_mode: String = String(normalized_settings.get("window_mode", "windowed"))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, window_mode == "borderless")
	if window_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var resolution: Vector2i = _parse_resolution_preset(String(normalized_settings.get("resolution_preset", "1920x1080")))
		if resolution.x > 0 and resolution.y > 0:
			DisplayServer.window_set_size(resolution)


func _apply_audio_bus_volume(bus_name: String, value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var linear_value: float = clampf(value / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(max(linear_value, 0.001)))


func _parse_resolution_preset(resolution_preset: String) -> Vector2i:
	var parts: PackedStringArray = resolution_preset.split("x")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(maxi(int(parts[0]), 0), maxi(int(parts[1]), 0))


func _on_master_volume_changed(value: float) -> void:
	_draft_gameplay_settings["master_volume"] = clampf(value, 0.0, 100.0)
	_status_label.text = "Settings changed"


func _on_fullscreen_toggled(enabled: bool) -> void:
	_draft_gameplay_settings["window_mode"] = "fullscreen" if enabled else "windowed"
	if _window_mode_option != null:
		SETTINGS_SCREEN_SCRIPT.call("select_option_metadata", _window_mode_option, String(_draft_gameplay_settings.get("window_mode", "windowed")))
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "fullscreen")


func _on_bubble_mode_selected(index: int) -> void:
	if _bubble_mode_option == null or index < 0 or index >= _bubble_mode_option.item_count:
		return
	var mode: String = String(_bubble_mode_option.get_item_metadata(index))
	_draft_comic_bubble_settings["mode"] = COMIC_BUBBLE_SETTINGS_SCRIPT.call("normalize_mode", mode)
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "bubble_mode")


func _on_resolution_selected(index: int) -> void:
	if _resolution_option == null or index < 0 or index >= _resolution_option.item_count:
		return
	_draft_gameplay_settings["resolution_preset"] = String(_resolution_option.get_item_metadata(index))
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "resolution")


func _on_window_mode_selected(index: int) -> void:
	if _window_mode_option == null or index < 0 or index >= _window_mode_option.item_count:
		return
	var window_mode: String = String(_window_mode_option.get_item_metadata(index))
	_draft_gameplay_settings["window_mode"] = window_mode
	_fullscreen_check.set_pressed_no_signal(window_mode == "fullscreen")
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "window_mode")


func _on_vsync_toggled(enabled: bool) -> void:
	_draft_gameplay_settings["vsync_enabled"] = enabled
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "vsync")


func _on_music_volume_changed(value: float) -> void:
	_draft_gameplay_settings["music_volume"] = clampf(value, 0.0, 100.0)
	_status_label.text = "Settings changed"


func _on_sfx_volume_changed(value: float) -> void:
	_draft_gameplay_settings["sfx_volume"] = clampf(value, 0.0, 100.0)
	_status_label.text = "Settings changed"


func _on_fog_of_war_mode_selected(index: int) -> void:
	if _fog_of_war_option == null or index < 0 or index >= _fog_of_war_option.item_count:
		return
	_draft_gameplay_settings["fog_of_war_mode"] = String(_fog_of_war_option.get_item_metadata(index))
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "fog_of_war_mode")


func _on_contextual_help_mode_selected(index: int) -> void:
	if _contextual_help_option == null or index < 0 or index >= _contextual_help_option.item_count:
		return
	_draft_gameplay_settings[GAME_SETTINGS_CONTRACT_SCRIPT.KEY_CONTEXTUAL_HELP_MODE] = String(_contextual_help_option.get_item_metadata(index))
	_apply_contextual_help_mode_to_service(_draft_gameplay_settings)
	_status_label.text = "Settings changed"
	_play_ui_sfx("switch", "contextual_help_mode")


func _sanitize_test_profile_fragment(text: String) -> String:
	var normalized: String = text.strip_edges().to_lower()
	var result: String = ""
	for index in range(normalized.length()):
		var character: String = normalized.substr(index, 1)
		if (character >= "a" and character <= "z") or (character >= "0" and character <= "9"):
			result += character
		elif character == "_" or character == "-":
			result += character
	if result.is_empty():
		result = "start_roster"
	return result.substr(0, 36)
