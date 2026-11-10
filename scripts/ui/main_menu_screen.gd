extends Control

const GAME_START_CONTRACT_SCRIPT: GDScript = preload("res://scripts/meta/game_start_contract.gd")
const CAMPAIGN_CHECKPOINT_STORE_PATH: String = "res://scripts/meta/campaign_checkpoint_store.gd"

const TACTICAL_UI_THEME_SCRIPT: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

const BACKGROUND_PATH: String = "res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg"
const SINGLEPLAYER_SCENE_PATH: String = "res://scenes/meta/meta_layer_test.tscn"
const MULTIPLAYER_SCENE_PATH: String = "res://scenes/ui/multiplayer_lobby.tscn"
const EDITOR_SCENE_PATH: String = "res://scenes/editor/map_editor.tscn"
const COMIC_BUBBLE_SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")
const GAME_SETTINGS_CONTRACT_SCRIPT: GDScript = preload("res://scripts/ui/game_settings_contract.gd")
const SETTINGS_SCREEN_SCRIPT: GDScript = preload("res://scripts/ui/settings_screen.gd")
const CONTEXTUAL_HELP_SERVICE_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_service.gd")
const CONTEXTUAL_HELP_POPUP_SCRIPT: GDScript = preload("res://scripts/ui/contextual_help_popup.gd")
const HOVER_SCROLL_BEHAVIOR_SCRIPT: GDScript = preload("res://scripts/ui/hover_scroll_behavior.gd")
const START_ROSTER_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/start_roster_generator.gd")
const PLAYER_ROSTER_STORE_SCRIPT: GDScript = preload("res://scripts/meta/player_roster_store.gd")
const TEAM_NAME_GENERATOR_SCRIPT: GDScript = preload("res://scripts/meta/team_name_generator.gd")
const PORTRAIT_IDENTITY_CATALOG_SCRIPT: GDScript = preload("res://scripts/meta/portrait_identity_catalog.gd")
const META_UNIT_PROFILE_SCRIPT: GDScript = preload("res://scripts/meta/meta_unit_profile.gd")
const CHARACTER_SHEET_VIEW_SCRIPT: GDScript = preload("res://scripts/meta/character_sheet_view.gd")
const NPC_RANK_BADGE_RESOLVER_SCRIPT: GDScript = preload("res://scripts/meta/npc_rank_badge_resolver.gd")
const UNIT_PROFILE_MATH_SCRIPT: GDScript = preload("res://scripts/npc/unit_profile_math.gd")
const AUDIO_EVENT_BUS_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_bus.gd")
const BACKGROUND_IMAGE_CATALOG_SCRIPT: GDScript = preload("res://scripts/assets/background_image_catalog.gd")
const BACKGROUND_ID: String = "main_menu_shell"
const GLOBAL_ESCAPE_MENU_NODE_PATH: String = "/root/GlobalEscapeMenu"
const RELEASE_FIRST_PLAY_STYLE_ID: String = "task_823_release_singleplayer_first_play_cta_v1"
const RELEASE_SINGLEPLAYER_DEEPLINK_ARG: String = "--release-singleplayer"
const RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG: String = "--release-singleplayer-start-mission"
const RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG: String = "--release-singleplayer-lz-drop-preview"
const RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG: String = "--release-singleplayer-first-go-firefight"
const RELEASE_MULTIPLAYER_HOST_DEEPLINK_ARG: String = "--release-multiplayer-host"
const RELEASE_MULTIPLAYER_JOIN_DEEPLINK_ARG: String = "--release-multiplayer-join"
const TEAM_EDITOR_POINT_DELTA: int = 1
const TEAM_EDITOR_VIEW_SIX: String = "six"
const TEAM_EDITOR_VIEW_NINE: String = "nine"
const TEAM_EDITOR_VIEW_SHEET: String = "sheet"
const TEAM_EDITOR_METRIC_POINTS_PER_VALUE: int = 20
const TEAM_EDITOR_METRIC_GROUP_CONFIG: Dictionary = {
	"progression": {"label": "Statuswerte", "help_id": "character_sheet.progression", "row_count": 2, "points_per_row": 10},
	"skill_values": {"label": "Kernwerte", "help_id": "character_sheet.core_values", "row_count": 8, "points_per_row": 12},
	"communication_values": {"label": "Kommunikation", "help_id": "character_sheet.communication", "row_count": 2, "points_per_row": 12},
	"platform_values": {"label": "Plattform", "help_id": "character_sheet.platform_skills", "row_count": 4, "points_per_row": 10},
	"behavior_axes": {"label": "Verhalten", "help_id": "character_sheet.behavior_profile", "row_count": 5, "points_per_row": 12},
}

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

var _campaign_button: Button
var _campaign_dialog: ConfirmationDialog
var _campaign_continue_button: Button
var _campaign_replace_dialog: ConfirmationDialog
var _skirmish_dialog: AcceptDialog

var _settings_config_path: String = COMIC_BUBBLE_SETTINGS_SCRIPT.CONFIG_PATH
var _comic_bubble_settings: Dictionary = {}
var _gameplay_settings: Dictionary = {}
var _draft_comic_bubble_settings: Dictionary = {}
var _draft_gameplay_settings: Dictionary = {}
var _display_section_label: Label = null
var _audio_section_label: Label = null
var _audio_value_labels: Dictionary = {}
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
var _mission_save_button: Button = null
var _mission_load_button: Button = null
var _team_editor_toggle_button: Button = null
var _team_library_panel: Panel = null
var _team_library_list: VBoxContainer = null
var _team_library_status_label: Label = null
var _team_library_activate_button: Button = null
var _team_library_edit_button: Button = null
var _team_library_delete_button: Button = null
var _team_library_entries: Array = []
var _selected_roster_entry_path: String = ""
var _team_editor_panel: Panel = null
var _team_editor_open: bool = false
var _team_editor_roster_path: String = ""
var _team_editor_roster: Dictionary = {}
var _team_editor_view_mode: String = TEAM_EDITOR_VIEW_SHEET
var _team_editor_selected_unit_id: String = ""
var _team_editor_title_label: Label = null
var _team_editor_name_edit: LineEdit = null
var _team_editor_summary_label: Label = null
var _team_editor_emblem_option: OptionButton = null
var _team_editor_emblem_preview: TextureRect = null
var _team_editor_budget_label: Label = null
var _team_editor_stats_vbox: VBoxContainer = null
var _team_editor_stat_rows: Dictionary = {}
var _team_editor_metric_locks: Dictionary = {}
var _team_editor_metric_group_budgets: Dictionary = {}
var _team_editor_card_grid: GridContainer = null
var _team_editor_cards_scroll: ScrollContainer = null
var _team_editor_sheet_scroll: ScrollContainer = null
var _team_editor_sheet_host: VBoxContainer = null
var _team_editor_unit_name_edit: LineEdit = null
var _team_editor_unit_portrait_preview: TextureRect = null
var _team_editor_unit_portrait_option: OptionButton = null
var _team_editor_view_buttons: Dictionary = {}
var _team_editor_save_button: Button = null
var _team_editor_close_button: Button = null
var _team_editor_refresh_queued: bool = false
var _team_editor_metric_save_queued: bool = false
var _team_editor_metric_save_reason: String = ""
var _team_editor_metric_save_timer: Timer = null
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
var _help_compact_timer: Timer = null
var _help_detail_timer: Timer = null
var _help_hide_timer: Timer = null
var _release_singleplayer_deeplink_requested: bool = false
var _release_singleplayer_deeplink_applied: bool = false
var _release_singleplayer_deeplink_target: String = ""


func _ready() -> void:
	TACTICAL_UI_THEME_SCRIPT.apply_screen(self)
	set_meta("native_ui_screen_family", "main_menu")
	set_meta("main_menu_shell", true)
	_ensure_owned_ui_timers()
	_apply_background_texture()
	var menu_rail := get_node_or_null("MenuRail") as ColorRect
	if menu_rail != null:
		menu_rail.color = TACTICAL_UI_THEME_SCRIPT.COLOR_PANEL
	_load_comic_bubble_settings()
	_ensure_audio_event_bus()
	_ensure_settings_screen_nodes()
	_ensure_start_roster_button()
	_ensure_mission_save_load_buttons()
	_apply_release_first_play_polish()
	_ensure_campaign_entry()
	_ensure_skirmish_entry()
	_ensure_contextual_help_ui()
	ensure_start_roster_exists()
	HOVER_SCROLL_BEHAVIOR_SCRIPT.call("install", self)
	_refresh_settings_controls_from_current()
	_configure_routes()
	_connect_signals()
	close_settings_panel()
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_layout_native_shell_windows):
		viewport.size_changed.connect(_layout_native_shell_windows)
	_layout_native_shell_windows()
	if get_tree().root.has_meta("campaign_start_error"):
		_status_label.text = String(get_tree().root.get_meta("campaign_start_error"))
		get_tree().root.remove_meta("campaign_start_error")
	call_deferred("_apply_release_deeplink")


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
		"mission_save": "global_shell_slot",
		"mission_load": "global_shell_slot",
		"multiplayer_lobby": true,
		"release_first_play_primary": true,
	}


func get_release_singleplayer_visible_findings_polish_snapshot() -> Dictionary:
	var singleplayer_font_size: int = int(_singleplayer_button.get_theme_font_size("font_size")) if _singleplayer_button != null else 0
	var multiplayer_font_size: int = int(_multiplayer_button.get_theme_font_size("font_size")) if _multiplayer_button != null else 0
	return {
		"schema": "sternenbuergerchen.release_singleplayer_visible_findings_polish.v1",
		"task_id": "TASK_823",
		"style_id": RELEASE_FIRST_PLAY_STYLE_ID,
		"singleplayer_text": _singleplayer_button.text if _singleplayer_button != null else "",
		"singleplayer_min_height": _singleplayer_button.custom_minimum_size.y if _singleplayer_button != null else 0.0,
		"singleplayer_font_size": singleplayer_font_size,
		"singleplayer_tooltip": _singleplayer_button.tooltip_text if _singleplayer_button != null else "",
		"singleplayer_action_hint": String(_singleplayer_button.get_meta("release_action_hint", "")) if _singleplayer_button != null else "",
		"singleplayer_priority": String(_singleplayer_button.get_meta("release_priority", "")) if _singleplayer_button != null else "",
		"singleplayer_style_id": String(_singleplayer_button.get_meta("release_first_play_style_id", "")) if _singleplayer_button != null else "",
		"singleplayer_route": String(_singleplayer_button.get_meta("route", "")) if _singleplayer_button != null else "",
		"secondary_font_size": multiplayer_font_size,
		"multiplayer_priority": String(_multiplayer_button.get_meta("release_priority", "")) if _multiplayer_button != null else "",
		"editor_priority": String(_editor_button.get_meta("release_priority", "")) if _editor_button != null else "",
		"settings_priority": String(_settings_button.get_meta("release_priority", "")) if _settings_button != null else "",
		"mission_save_priority": String(_mission_save_button.get_meta("release_priority", "")) if _mission_save_button != null else "",
		"mission_load_priority": String(_mission_load_button.get_meta("release_priority", "")) if _mission_load_button != null else "",
		"singleplayer_focus_mode": _singleplayer_button.focus_mode if _singleplayer_button != null else Control.FOCUS_NONE,
		"main_menu_shell": bool(get_meta("main_menu_shell", false)),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"creates_simulation_root": find_child("SimulationRoot", true, false) != null,
	}


func get_release_singleplayer_deeplink_snapshot(user_args: PackedStringArray = PackedStringArray()) -> Dictionary:
	var args: PackedStringArray = user_args if user_args.size() > 0 else _get_release_cmdline_user_args()
	var requested: bool = _has_release_singleplayer_deeplink_arg(args)
	return {
		"schema": "sternenbuergerchen.release_singleplayer_deeplink_evidence.v1",
		"task_id": "TASK_829",
		"arg": RELEASE_SINGLEPLAYER_DEEPLINK_ARG,
		"start_mission_arg": RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG,
		"lz_drop_preview_arg": RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG,
		"first_go_firefight_arg": RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG,
		"args": Array(args),
		"requested": requested,
		"applied": _release_singleplayer_deeplink_applied,
		"would_route_to": SINGLEPLAYER_SCENE_PATH if requested else "",
		"target": _release_singleplayer_deeplink_target,
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _get_release_cmdline_user_args() -> PackedStringArray:
	var normalized := PackedStringArray()
	for arg in OS.get_cmdline_args():
		var text: String = String(arg).strip_edges()
		if not text.is_empty() and not normalized.has(text):
			normalized.append(text)
	for arg in OS.get_cmdline_user_args():
		var text: String = String(arg).strip_edges()
		if not text.is_empty() and not normalized.has(text):
			normalized.append(text)
	return normalized


func _has_release_singleplayer_deeplink_arg(args: PackedStringArray) -> bool:
	for arg in args:
		var normalized_arg: String = String(arg).strip_edges()
		if normalized_arg == RELEASE_SINGLEPLAYER_DEEPLINK_ARG \
			or normalized_arg == RELEASE_SINGLEPLAYER_START_MISSION_DEEPLINK_ARG \
			or normalized_arg == RELEASE_SINGLEPLAYER_LZ_DROP_PREVIEW_DEEPLINK_ARG \
			or normalized_arg == RELEASE_SINGLEPLAYER_FIRST_GO_FIREFIGHT_DEEPLINK_ARG:
			return true
	return false


func _apply_release_singleplayer_deeplink() -> void:
	var args: PackedStringArray = _get_release_cmdline_user_args()
	if not _has_release_singleplayer_deeplink_arg(args):
		return
	_release_singleplayer_deeplink_requested = true
	_release_singleplayer_deeplink_applied = true
	_release_singleplayer_deeplink_target = SINGLEPLAYER_SCENE_PATH
	set_meta("release_singleplayer_deeplink_requested", true)
	set_meta("release_singleplayer_deeplink_target", SINGLEPLAYER_SCENE_PATH)
	_status_label.text = "Singleplayer wird gestartet"
	_start_skirmish("")


func _apply_release_deeplink() -> void:
	var args: PackedStringArray = _get_release_cmdline_user_args()
	if args.has(RELEASE_MULTIPLAYER_HOST_DEEPLINK_ARG) or args.has(RELEASE_MULTIPLAYER_JOIN_DEEPLINK_ARG):
		_status_label.text = "Multiplayer-Lobby wird gestartet"
		_on_multiplayer_pressed()
		return
	_apply_release_singleplayer_deeplink()


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
		"mission_save_button_visible": _mission_save_button != null and _mission_save_button.visible,
		"mission_load_button_visible": _mission_load_button != null and _mission_load_button.visible,
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
		"edit_enabled": _team_library_edit_button != null and not _team_library_edit_button.disabled,
		"delete_enabled": _team_library_delete_button != null and not _team_library_delete_button.disabled,
	}


func get_team_editor_snapshot() -> Dictionary:
	var editor: Dictionary = _get_normalized_team_editor(false)
	var roster: Dictionary = _get_team_editor_roster_source()
	var units: Array = Array(roster.get("units", []))
	var selected_unit: Dictionary = _find_team_editor_unit(roster, _team_editor_selected_unit_id)
	var panel_rect: Rect2 = Rect2(_team_editor_panel.global_position, _team_editor_panel.size) if _team_editor_panel != null else Rect2()
	return {
		"visible": _team_editor_panel != null and _team_editor_panel.visible,
		"toggle_visible": _team_editor_toggle_button != null and _team_editor_toggle_button.visible,
		"toggle_text": _team_editor_toggle_button.text if _team_editor_toggle_button != null else "",
		"window_mode": "fullscreen_team_editor",
		"parent_is_root": _team_editor_panel != null and _team_editor_panel.get_parent() == self,
		"view_mode": _team_editor_view_mode,
		"panel_position": panel_rect.position,
		"panel_size": panel_rect.size,
		"team_name": String(roster.get("team_name", "")),
		"edited_path": _team_editor_roster_path,
		"unit_count": units.size(),
		"card_count": _team_editor_card_grid.get_child_count() if _team_editor_card_grid != null else 0,
		"sheet_visible": _team_editor_sheet_scroll != null and _team_editor_sheet_scroll.visible,
		"selected_unit_id": _team_editor_selected_unit_id,
		"budget_max": int(editor.get("point_budget_max", 0)),
		"budget_used": int(editor.get("point_budget_used", 0)),
		"budget_available": int(editor.get("point_budget_available", 0)),
		"budget_explanation": "Team-Fokus fuer Generator/Balancing; einzelne NPC-Werte werden rechts separat editiert.",
		"point_budget_policy": Dictionary(editor.get("point_budget_policy", {})).duplicate(true),
		"team_size_policy": Dictionary(editor.get("team_size_policy", START_ROSTER_GENERATOR_SCRIPT.call("build_team_size_policy"))).duplicate(true),
		"allocations": Dictionary(editor.get("stat_allocations", {})).duplicate(true),
		"stat_locks": Dictionary(editor.get("stat_locks", {})).duplicate(true),
		"metric_locks": Dictionary(editor.get("metric_locks", {})).duplicate(true),
		"stat_definitions": Array(editor.get("stat_definitions", [])).duplicate(true),
		"selected_metric_group_budgets": _build_team_editor_metric_group_budgets(selected_unit),
		"selected_metric_locks": _get_team_editor_metric_locks_for_unit(_team_editor_selected_unit_id),
		"emblem_id": String(editor.get("emblem_id", "")),
		"emblem_path": String(editor.get("emblem_path", "")),
		"emblem_option_count": _team_editor_emblem_option.item_count if _team_editor_emblem_option != null else 0,
		"has_emblem_texture": _team_editor_emblem_preview != null and _team_editor_emblem_preview.texture != null,
		"character_name_edit_visible": _team_editor_unit_name_edit != null and _team_editor_unit_name_edit.visible,
		"character_portrait_option_count": _team_editor_unit_portrait_option.item_count if _team_editor_unit_portrait_option != null else 0,
		"character_portrait_option_icon_count": _option_button_icon_count(_team_editor_unit_portrait_option),
		"character_has_portrait_preview": _team_editor_unit_portrait_preview != null and _team_editor_unit_portrait_preview.texture != null,
		"selected_unit_method_summary": String(selected_unit.get("method_summary_text", "")),
		"selected_unit_function_summary": String(selected_unit.get("function_summary_text", "")),
		"selected_unit_primary_specialty": String(selected_unit.get("primary_specialty", "")),
		"short_description_section_visible": _team_editor_sheet_has_label_text("KURZBESCHREIBUNG:"),
		"last_loadout_section_index": _team_editor_sheet_child_index_for_name("LastLoadoutDropdownSection"),
	}


func _team_editor_sheet_has_label_text(label_text: String) -> bool:
	if _team_editor_sheet_host == null:
		return false
	return _node_tree_has_label_text(_team_editor_sheet_host, label_text)


func _node_tree_has_label_text(node: Node, label_text: String) -> bool:
	if node is Label and String((node as Label).text) == label_text:
		return true
	for child in node.get_children():
		if _node_tree_has_label_text(child, label_text):
			return true
	return false


func _team_editor_sheet_child_index_for_name(node_name: String) -> int:
	if _team_editor_sheet_host == null:
		return -1
	var target := _team_editor_sheet_host.find_child(node_name, true, false)
	if target == null:
		return -1
	var parent := target.get_parent()
	if parent == null:
		return -1
	return target.get_index()


func _option_button_icon_count(option_button: OptionButton) -> int:
	if option_button == null:
		return 0
	var count: int = 0
	for index in range(option_button.item_count):
		if option_button.get_item_icon(index) != null:
			count += 1
	return count


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


func set_team_editor_stat_lock_for_tests(stat_id: String, locked: bool) -> Dictionary:
	return _set_team_editor_stat_lock(stat_id, locked, false)


func set_team_editor_metric_lock_for_tests(unit_id: String, value_group: String, value_key: String, locked: bool) -> Dictionary:
	var row_data: Dictionary = {
		"value_group": value_group,
		"value_key": value_key,
	}
	var result: Dictionary = _set_team_editor_metric_lock(unit_id, row_data, locked)
	result["unit_id"] = unit_id
	return result


func set_team_editor_metric_group_budget_for_tests(unit_id: String, value_group: String, max_points: int) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	var normalized_group: String = value_group.strip_edges()
	if normalized_unit_id.is_empty() or normalized_group.is_empty():
		return {"ok": false, "reason": "missing_budget_key"}
	var budget_key: String = "%s|%s" % [normalized_unit_id, normalized_group]
	_team_editor_metric_group_budgets[budget_key] = maxi(max_points, 0)
	_refresh_team_editor()
	return {
		"ok": true,
		"budget_key": budget_key,
		"max_points": int(_team_editor_metric_group_budgets.get(budget_key, 0)),
	}


func set_team_editor_emblem_for_tests(emblem_id: String) -> Dictionary:
	return _set_team_editor_emblem(emblem_id, false)


func set_team_editor_unit_name_for_tests(unit_id: String, display_name: String) -> Dictionary:
	return _set_team_editor_unit_name(unit_id, display_name, false)


func set_team_editor_unit_portrait_for_tests(unit_id: String, portrait_id: String) -> Dictionary:
	var option: Dictionary = _find_portrait_option(portrait_id)
	return _set_team_editor_unit_portrait(unit_id, String(option.get("id", portrait_id)), String(option.get("path", "")), false)


func open_team_editor(entry_path: String = "") -> void:
	_open_team_editor_for_path(entry_path)


func close_team_editor() -> void:
	_set_team_editor_open(false)


func toggle_team_editor() -> void:
	if _team_editor_open:
		close_team_editor()
	else:
		open_team_editor()


func set_team_editor_view_mode_for_tests(view_mode: String) -> void:
	_set_team_editor_view_mode(view_mode)


func open_selected_team_entry_for_tests(entry_path: String = "") -> void:
	open_team_editor(entry_path)


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
	if _team_editor_open:
		_team_editor_roster_path = _start_roster_save_path
		_team_editor_roster = _start_roster.duplicate(true)
		_team_editor_selected_unit_id = _resolve_team_editor_selected_unit_id("")
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
	var next_generation_index: int = _start_roster_generation_index + 1
	var next_seed: String = "%s_reset_%02d" % [_start_roster_seed, next_generation_index]
	var reset_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("reset_roster", next_seed, _start_roster_size, _start_roster_profile_id, _start_roster_save_path, true))
	_last_start_roster_store_result = reset_result.duplicate(true)
	if not bool(reset_result.get("ok", false)):
		_status_label.text = "Roster save failed"
		return {
			"created": false,
			"reason": String(reset_result.get("reason", "roster_reset_failed")),
			"roster": _start_roster.duplicate(true),
			"summary": START_ROSTER_GENERATOR_SCRIPT.call("build_summary_snapshot", _start_roster),
			"store": reset_result,
		}
	_start_roster_generation_index = next_generation_index
	_start_roster = Dictionary(reset_result.get("roster", {})).duplicate(true)
	_normalize_start_team_editor(true)
	_last_start_roster_created = true
	_last_start_roster_loaded_from_save = false
	_start_roster_reset_confirmation_pending = false
	_refresh_start_roster_button()
	_refresh_team_name_controls()
	_selected_roster_entry_path = _start_roster_save_path
	if _team_editor_open:
		_team_editor_roster_path = _start_roster_save_path
		_team_editor_roster = _start_roster.duplicate(true)
		_team_editor_selected_unit_id = _resolve_team_editor_selected_unit_id("")
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
	_layout_native_shell_windows()
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
	if _mission_save_button != null and not _mission_save_button.pressed.is_connected(_on_mission_save_pressed):
		_mission_save_button.pressed.connect(_on_mission_save_pressed)
	if _mission_load_button != null and not _mission_load_button.pressed.is_connected(_on_mission_load_pressed):
		_mission_load_button.pressed.connect(_on_mission_load_pressed)
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
	for channel in ["Master", "Music", "Sfx"]:
		_audio_value_labels[channel] = _ensure_settings_label(channel + "VolumeCaption", "", 13)

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
	_configure_native_settings_window(action_row)


func _configure_native_settings_window(action_row: HBoxContainer) -> void:
	# Keep the existing Control instances and callback references. Only their
	# presentation hosts change: a bounded body scrolls below the fixed title,
	# while the existing action buttons form an always reachable footer.
	if _settings_vbox.get_node_or_null("SettingsBodyScroll") != null:
		return
	if _settings_panel is PanelContainer:
		var old_frame := _settings_panel
		var frame := Panel.new()
		var parent := old_frame.get_parent()
		var child_index := old_frame.get_index()
		parent.remove_child(old_frame)
		frame.name = "SettingsPanel"
		parent.add_child(frame)
		parent.move_child(frame, child_index)
		for child in old_frame.get_children():
			child.reparent(frame, false)
		_settings_panel = frame
		old_frame.free()
		var margin := _settings_panel.get_node("SettingsMargin") as MarginContainer
		margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_settings_panel.grow_vertical = Control.GROW_DIRECTION_END
	_settings_panel.z_index = 60
	_settings_panel.clip_contents = true
	_settings_panel.custom_minimum_size = Vector2.ZERO
	var title := _settings_vbox.get_node_or_null("SettingsTitleLabel") as Label
	var scroll := ScrollContainer.new()
	scroll.name = "SettingsBodyScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(0.0, 96.0)
	var content := VBoxContainer.new()
	content.name = "SettingsContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	for child in _settings_vbox.get_children():
		if child == title or child == action_row or child == _settings_back_button:
			continue
		child.reparent(content)
	_settings_vbox.add_child(scroll)
	_settings_vbox.move_child(scroll, 1 if title != null else 0)
	_settings_back_button.reparent(action_row)
	_settings_back_button.custom_minimum_size = Vector2(132.0, 44.0)
	_settings_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for button in [_settings_apply_button, _settings_reset_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	TACTICAL_UI_THEME_SCRIPT.style_command_button(_settings_apply_button, "accent")
	_settings_vbox.move_child(action_row, _settings_vbox.get_child_count() - 1)
	_settings_panel.set_meta("native_ui_bounded_scroll", true)


func _layout_native_shell_windows() -> void:
	var viewport_size := get_viewport_rect().size
	if _settings_panel != null:
		var settings_size := Vector2(minf(680.0, viewport_size.x - 64.0), maxf(280.0, minf(900.0, viewport_size.y - 96.0)))
		_settings_panel.set_as_top_level(true)
		_settings_panel.anchor_left = 0.0
		_settings_panel.anchor_top = 0.0
		_settings_panel.anchor_right = 0.0
		_settings_panel.anchor_bottom = 0.0
		_settings_panel.position = Vector2(maxf(32.0, viewport_size.x - settings_size.x - 48.0), 48.0)
		_settings_panel.size = settings_size
	if _team_library_panel != null:
		var library_size := Vector2(minf(640.0, maxf(480.0, viewport_size.x - 600.0)), minf(320.0, viewport_size.y - 160.0))
		_team_library_panel.position = Vector2(maxf(544.0, viewport_size.x - library_size.x - 32.0), maxf(80.0, viewport_size.y - library_size.y - 64.0))
		_team_library_panel.size = library_size
	if _team_editor_panel != null:
		_team_editor_panel.set_as_top_level(true)
		_team_editor_panel.anchor_left = 0.0
		_team_editor_panel.anchor_top = 0.0
		_team_editor_panel.anchor_right = 0.0
		_team_editor_panel.anchor_bottom = 0.0
		_team_editor_panel.position = Vector2(32.0, 32.0)
		_team_editor_panel.size = Vector2(maxf(600.0, viewport_size.x - 64.0), maxf(360.0, viewport_size.y - 64.0))


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


func _ensure_mission_save_load_buttons() -> void:
	var menu_buttons := get_node_or_null("MenuRail/MenuMargin/MenuVBox/MenuButtons") as VBoxContainer
	if menu_buttons == null:
		return
	var row := menu_buttons.get_node_or_null("MissionSlotRow") as HBoxContainer
	if row == null:
		row = HBoxContainer.new()
		row.name = "MissionSlotRow"
		row.add_theme_constant_override("separation", 8)
		menu_buttons.add_child(row)
		var reference := menu_buttons.get_node_or_null("NewRosterButton")
		if reference != null:
			menu_buttons.move_child(row, reference.get_index())
	_mission_save_button = row.get_node_or_null("MissionSaveButton") as Button
	if _mission_save_button == null:
		_mission_save_button = Button.new()
		_mission_save_button.name = "MissionSaveButton"
		_mission_save_button.text = "Mission speichern"
		_mission_save_button.custom_minimum_size = Vector2(176.0, 42.0)
		_mission_save_button.focus_mode = Control.FOCUS_ALL
		row.add_child(_mission_save_button)
	_mission_load_button = row.get_node_or_null("MissionLoadButton") as Button
	if _mission_load_button == null:
		_mission_load_button = Button.new()
		_mission_load_button.name = "MissionLoadButton"
		_mission_load_button.text = "Mission laden"
		_mission_load_button.custom_minimum_size = Vector2(176.0, 42.0)
		_mission_load_button.focus_mode = Control.FOCUS_ALL
		row.add_child(_mission_load_button)
	_refresh_mission_save_load_buttons()


func _apply_release_first_play_polish() -> void:
	if _singleplayer_button == null:
		return
	_singleplayer_button.custom_minimum_size = Vector2(360.0, 76.0)
	_singleplayer_button.focus_mode = Control.FOCUS_ALL
	_singleplayer_button.text = "Skirmish"
	_singleplayer_button.tooltip_text = "Freier Einzelspieler: Sortie mit deinem Skirmish-Team vorbereiten."
	_singleplayer_button.set_meta("release_first_play_style_id", RELEASE_FIRST_PLAY_STYLE_ID)
	_singleplayer_button.set_meta("release_priority", "primary")
	_singleplayer_button.set_meta("release_action_hint", "Freier Einzelspieler: Sortie mit deinem Skirmish-Team vorbereiten.")
	TACTICAL_UI_THEME_SCRIPT.style_command_button(_singleplayer_button, "accent")
	_singleplayer_button.add_theme_font_size_override("font_size", 20)
	_singleplayer_button.call_deferred("grab_focus")
	_apply_release_secondary_button_polish(_multiplayer_button, "secondary", "Host/Join-Lobby fuer Testteams.")
	_apply_release_secondary_button_polish(_editor_button, "secondary", "Map-Editor oeffnen.")
	_apply_release_secondary_button_polish(_settings_button, "secondary", "Anzeige, Audio und Eingabe anpassen.")
	_apply_release_secondary_button_polish(_new_roster_button, "support", "Optional: neues Startteam erzeugen.")
	_apply_release_secondary_button_polish(_team_editor_toggle_button, "support", "Optional: aktives Team bearbeiten.")
	_apply_release_secondary_button_polish(_mission_save_button, "support", "Optionaler Mission-Slot, wenn eine Shell-Mission aktiv ist.")
	_apply_release_secondary_button_polish(_mission_load_button, "support", "Optionaler Mission-Slot, wenn ein Save vorhanden ist.")


func _apply_release_secondary_button_polish(button: Button, priority: String, tooltip: String) -> void:
	if button == null:
		return
	button.set_meta("release_priority", priority)
	if button.tooltip_text.strip_edges().is_empty():
		button.tooltip_text = tooltip
	TACTICAL_UI_THEME_SCRIPT.style_command_button(button)
	button.add_theme_font_size_override("font_size", 15 if priority == "secondary" else 13)
	if priority == "secondary":
		button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 360.0), 50.0)
	else:
		button.custom_minimum_size = Vector2(button.custom_minimum_size.x, minf(button.custom_minimum_size.y, 44.0))
	button.add_theme_color_override("font_color", TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", TACTICAL_UI_THEME_SCRIPT.COLOR_TEXT)


func _build_release_first_play_button_style(background: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _refresh_mission_save_load_buttons() -> void:
	var shell = _get_global_escape_shell()
	var has_shell: bool = shell != null
	var has_save_slot: bool = false
	if has_shell:
		var slot: Dictionary = Dictionary(shell.call("get_save_slot_snapshot"))
		has_save_slot = bool(slot.get("exists", false))
	if _mission_save_button != null:
		_mission_save_button.visible = true
		_mission_save_button.disabled = not has_shell
		_mission_save_button.tooltip_text = "Speichert den aktuellen Mission-Shell-Slot." if has_shell else "Globales Shell-Menue ist nicht bereit."
	if _mission_load_button != null:
		_mission_load_button.visible = true
		_mission_load_button.disabled = not has_shell or not has_save_slot
		_mission_load_button.tooltip_text = "Laedt den gespeicherten Mission-Shell-Slot." if has_save_slot else "Noch kein Mission-Shell-Slot vorhanden."


func _ensure_team_library_panel(menu_buttons: VBoxContainer) -> void:
	_team_library_panel = menu_buttons.get_node_or_null("TeamLibraryPanel") as Panel
	if _team_library_panel == null:
		_team_library_panel = Panel.new()
		_team_library_panel.name = "TeamLibraryPanel"
		menu_buttons.add_child(_team_library_panel)
	_team_library_panel.set_as_top_level(true)
	_team_library_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_team_library_panel.custom_minimum_size = Vector2(480.0, 240.0)
	_team_library_panel.clip_contents = true
	_team_library_panel.grow_vertical = Control.GROW_DIRECTION_END
	_team_library_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_team_library_panel.z_index = 10
	_team_library_panel.set_meta("native_ui_detached_library", true)
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
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	header_label.text = "Skirmish-Teambibliothek"
	header_label.add_theme_font_size_override("font_size", 20)
	_team_library_activate_button = header_row.get_node_or_null("TeamLibraryActivateButton") as Button
	if _team_library_activate_button == null:
		_team_library_activate_button = Button.new()
		_team_library_activate_button.name = "TeamLibraryActivateButton"
		_team_library_activate_button.text = "Aktiv"
		_team_library_activate_button.custom_minimum_size = Vector2(72.0, 32.0)
		header_row.add_child(_team_library_activate_button)
	if not _team_library_activate_button.pressed.is_connected(_on_team_library_activate_pressed):
		_team_library_activate_button.pressed.connect(_on_team_library_activate_pressed)
	_team_library_edit_button = header_row.get_node_or_null("TeamLibraryEditButton") as Button
	if _team_library_edit_button == null:
		_team_library_edit_button = Button.new()
		_team_library_edit_button.name = "TeamLibraryEditButton"
		_team_library_edit_button.text = "Bearbeiten"
		_team_library_edit_button.custom_minimum_size = Vector2(104.0, 32.0)
		header_row.add_child(_team_library_edit_button)
	if not _team_library_edit_button.pressed.is_connected(_on_team_library_edit_pressed):
		_team_library_edit_button.pressed.connect(_on_team_library_edit_pressed)
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
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_team_library_list = scroll.get_node_or_null("TeamLibraryList") as VBoxContainer
	if _team_library_list == null:
		_team_library_list = VBoxContainer.new()
		_team_library_list.name = "TeamLibraryList"
		_team_library_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_library_list.add_theme_constant_override("separation", 4)
		scroll.add_child(_team_library_list)


func _ensure_team_editor_panel(_menu_buttons: VBoxContainer) -> void:
	_team_editor_panel = get_node_or_null("TeamEditorPanel") as Panel
	if _team_editor_panel == null:
		_team_editor_panel = Panel.new()
		_team_editor_panel.name = "TeamEditorPanel"
		add_child(_team_editor_panel)
	_team_editor_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_team_editor_panel.offset_left = 56.0
	_team_editor_panel.offset_top = 56.0
	_team_editor_panel.offset_right = -56.0
	_team_editor_panel.offset_bottom = -56.0
	_team_editor_panel.z_index = 70
	_team_editor_panel.set_meta("team_editor_window", true)
	_team_editor_panel.custom_minimum_size = Vector2.ZERO
	_team_editor_panel.clip_contents = true
	_team_editor_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_team_editor_panel.grow_vertical = Control.GROW_DIRECTION_END
	_team_editor_panel.visible = _team_editor_open
	_team_editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP if _team_editor_open else Control.MOUSE_FILTER_IGNORE
	var margin := _team_editor_panel.get_node_or_null("TeamEditorMargin") as MarginContainer
	if margin == null:
		margin = MarginContainer.new()
		margin.name = "TeamEditorMargin"
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 22)
		margin.add_theme_constant_override("margin_top", 18)
		margin.add_theme_constant_override("margin_right", 22)
		margin.add_theme_constant_override("margin_bottom", 18)
		_team_editor_panel.add_child(margin)
	var vbox := margin.get_node_or_null("TeamEditorVBox") as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "TeamEditorVBox"
		vbox.add_theme_constant_override("separation", 14)
		margin.add_child(vbox)

	var header_row := vbox.get_node_or_null("TeamEditorHeaderRow") as HBoxContainer
	if header_row == null:
		header_row = HBoxContainer.new()
		header_row.name = "TeamEditorHeaderRow"
		header_row.add_theme_constant_override("separation", 12)
		vbox.add_child(header_row)
	_team_editor_title_label = header_row.get_node_or_null("TeamEditorHeaderLabel") as Label
	if _team_editor_title_label == null:
		_team_editor_title_label = Label.new()
		_team_editor_title_label.name = "TeamEditorHeaderLabel"
		_team_editor_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_row.add_child(_team_editor_title_label)
	_team_editor_title_label.text = "Skirmish-Team-Editor"
	_team_editor_title_label.add_theme_font_size_override("font_size", 26)
	_team_editor_title_label.clip_text = true
	_team_editor_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_team_editor_title_label.tooltip_text = "Eigene Ansicht fuer Teamname, Team-Bild, Rookie-Punkte und NPC-Karten."

	var view_row := header_row.get_node_or_null("TeamEditorViewModeRow") as HBoxContainer
	if view_row == null:
		view_row = HBoxContainer.new()
		view_row.name = "TeamEditorViewModeRow"
		view_row.add_theme_constant_override("separation", 8)
		header_row.add_child(view_row)
	_configure_team_editor_sheet_only_view_row(view_row)

	_team_editor_save_button = header_row.get_node_or_null("TeamEditorSaveButton") as Button
	if _team_editor_save_button == null:
		_team_editor_save_button = Button.new()
		_team_editor_save_button.name = "TeamEditorSaveButton"
		_team_editor_save_button.text = "Speichern"
		_team_editor_save_button.custom_minimum_size = Vector2(120.0, 44.0)
		header_row.add_child(_team_editor_save_button)
	_team_editor_save_button.tooltip_text = "Teamnamen, Icon und Punkte in diesem Roster-Save sichern."
	if not _team_editor_save_button.pressed.is_connected(_on_team_editor_save_pressed):
		_team_editor_save_button.pressed.connect(_on_team_editor_save_pressed)

	_team_editor_close_button = header_row.get_node_or_null("TeamEditorCloseButton") as Button
	if _team_editor_close_button == null:
		_team_editor_close_button = Button.new()
		_team_editor_close_button.name = "TeamEditorCloseButton"
		_team_editor_close_button.text = "Schliessen"
		_team_editor_close_button.custom_minimum_size = Vector2(120.0, 44.0)
		header_row.add_child(_team_editor_close_button)
	_team_editor_close_button.tooltip_text = "Zurueck zum Hauptmenue."
	if not _team_editor_close_button.pressed.is_connected(_on_team_editor_close_pressed):
		_team_editor_close_button.pressed.connect(_on_team_editor_close_pressed)

	var body_row := vbox.get_node_or_null("TeamEditorBodyRow") as HBoxContainer
	if body_row == null:
		body_row = HBoxContainer.new()
		body_row.name = "TeamEditorBodyRow"
		body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_row.add_theme_constant_override("separation", 16)
		vbox.add_child(body_row)

	var side_panel := body_row.get_node_or_null("TeamEditorSidePanel") as PanelContainer
	if side_panel == null:
		side_panel = PanelContainer.new()
		side_panel.name = "TeamEditorSidePanel"
		side_panel.custom_minimum_size = Vector2(380.0, 0.0)
		body_row.add_child(side_panel)
	var side_margin := side_panel.get_node_or_null("TeamEditorSideMargin") as MarginContainer
	if side_margin == null:
		side_margin = MarginContainer.new()
		side_margin.name = "TeamEditorSideMargin"
		side_margin.add_theme_constant_override("margin_left", 14)
		side_margin.add_theme_constant_override("margin_top", 14)
		side_margin.add_theme_constant_override("margin_right", 14)
		side_margin.add_theme_constant_override("margin_bottom", 14)
		side_panel.add_child(side_margin)
	var side_vbox := side_margin.get_node_or_null("TeamEditorSideVBox") as VBoxContainer
	if side_vbox == null:
		side_vbox = VBoxContainer.new()
		side_vbox.name = "TeamEditorSideVBox"
		side_vbox.add_theme_constant_override("separation", 10)
		side_margin.add_child(side_vbox)

	var name_label := side_vbox.get_node_or_null("TeamEditorNameLabel") as Label
	if name_label == null:
		name_label = Label.new()
		name_label.name = "TeamEditorNameLabel"
		side_vbox.add_child(name_label)
	name_label.text = "Teamname"
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.tooltip_text = "Dieser Name gehoert zum lokalen Spieler-Roster und ist keine Missionswahrheit."
	name_label.set_meta("help_id", "team_editor.team_name")
	_team_editor_name_edit = side_vbox.get_node_or_null("TeamEditorNameEdit") as LineEdit
	if _team_editor_name_edit == null:
		_team_editor_name_edit = LineEdit.new()
		_team_editor_name_edit.name = "TeamEditorNameEdit"
		_team_editor_name_edit.custom_minimum_size = Vector2(338.0, 42.0)
		side_vbox.add_child(_team_editor_name_edit)
	_team_editor_name_edit.placeholder_text = "Teamname"
	_team_editor_name_edit.tooltip_text = "Enter oder Fokusverlust speichert den Teamnamen."
	_team_editor_name_edit.set_meta("help_id", "team_editor.team_name")
	if not _team_editor_name_edit.text_submitted.is_connected(_on_team_editor_name_submitted):
		_team_editor_name_edit.text_submitted.connect(_on_team_editor_name_submitted)
	if not _team_editor_name_edit.focus_exited.is_connected(_on_team_editor_name_focus_exited):
		_team_editor_name_edit.focus_exited.connect(_on_team_editor_name_focus_exited)

	var emblem_row := side_vbox.get_node_or_null("TeamEditorEmblemRow") as HBoxContainer
	if emblem_row == null:
		emblem_row = HBoxContainer.new()
		emblem_row.name = "TeamEditorEmblemRow"
		emblem_row.add_theme_constant_override("separation", 8)
		side_vbox.add_child(emblem_row)
	_team_editor_emblem_preview = emblem_row.get_node_or_null("TeamEditorEmblemPreview") as TextureRect
	if _team_editor_emblem_preview == null:
		_team_editor_emblem_preview = TextureRect.new()
		_team_editor_emblem_preview.name = "TeamEditorEmblemPreview"
		emblem_row.add_child(_team_editor_emblem_preview)
	_team_editor_emblem_preview.custom_minimum_size = Vector2(44.0, 44.0)
	_team_editor_emblem_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_team_editor_emblem_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_team_editor_emblem_preview.tooltip_text = "Team-Symbol aus bestehenden Projektbildern."
	_team_editor_emblem_preview.set_meta("help_id", "team_editor.symbol")
	_team_editor_emblem_option = emblem_row.get_node_or_null("TeamEditorEmblemOption") as OptionButton
	if _team_editor_emblem_option == null:
		_team_editor_emblem_option = OptionButton.new()
		_team_editor_emblem_option.name = "TeamEditorEmblemOption"
		_team_editor_emblem_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		emblem_row.add_child(_team_editor_emblem_option)
	_team_editor_emblem_option.custom_minimum_size = Vector2(270.0, 42.0)
	_team_editor_emblem_option.tooltip_text = "Team-Bild aus vorhandenen Portrait-Assets."
	_team_editor_emblem_option.set_meta("help_id", "team_editor.symbol")
	if not _team_editor_emblem_option.item_selected.is_connected(_on_team_editor_emblem_selected):
		_team_editor_emblem_option.item_selected.connect(_on_team_editor_emblem_selected)
	_team_editor_summary_label = side_vbox.get_node_or_null("TeamEditorSummaryLabel") as Label
	if _team_editor_summary_label == null:
		_team_editor_summary_label = Label.new()
		_team_editor_summary_label.name = "TeamEditorSummaryLabel"
		_team_editor_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		side_vbox.add_child(_team_editor_summary_label)
	_team_editor_summary_label.add_theme_font_size_override("font_size", 12)
	_team_editor_summary_label.tooltip_text = "Zusammenfassung des geoeffneten Teams und des aktuellen Ansichtmodus."
	_team_editor_summary_label.visible = false
	_team_editor_budget_label = side_vbox.get_node_or_null("TeamEditorBudgetLabel") as Label
	if _team_editor_budget_label == null:
		_team_editor_budget_label = Label.new()
		_team_editor_budget_label.name = "TeamEditorBudgetLabel"
		side_vbox.add_child(_team_editor_budget_label)
	_team_editor_budget_label.add_theme_font_size_override("font_size", 13)
	_team_editor_budget_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_team_editor_budget_label.tooltip_text = "Team-Fokus: Generator-/Balancing-Vorgabe. Einzelne NPC-Werte werden rechts im Charakterblatt geaendert."
	var scroll := side_vbox.get_node_or_null("TeamEditorStatsScroll") as ScrollContainer
	if scroll == null:
		scroll = ScrollContainer.new()
		scroll.name = "TeamEditorStatsScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		side_vbox.add_child(scroll)
	scroll.custom_minimum_size = Vector2(340.0, 230.0)
	_team_editor_stats_vbox = scroll.get_node_or_null("TeamEditorStatsVBox") as VBoxContainer
	if _team_editor_stats_vbox == null:
		_team_editor_stats_vbox = VBoxContainer.new()
		_team_editor_stats_vbox.name = "TeamEditorStatsVBox"
		_team_editor_stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_editor_stats_vbox.add_theme_constant_override("separation", 4)
		scroll.add_child(_team_editor_stats_vbox)

	var content_panel := body_row.get_node_or_null("TeamEditorContentPanel") as PanelContainer
	if content_panel == null:
		content_panel = PanelContainer.new()
		content_panel.name = "TeamEditorContentPanel"
		content_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_row.add_child(content_panel)
	var content_margin := content_panel.get_node_or_null("TeamEditorContentMargin") as MarginContainer
	if content_margin == null:
		content_margin = MarginContainer.new()
		content_margin.name = "TeamEditorContentMargin"
		content_margin.add_theme_constant_override("margin_left", 14)
		content_margin.add_theme_constant_override("margin_top", 14)
		content_margin.add_theme_constant_override("margin_right", 14)
		content_margin.add_theme_constant_override("margin_bottom", 14)
		content_panel.add_child(content_margin)
	var content_row := content_margin.get_node_or_null("TeamEditorContentRow") as HBoxContainer
	if content_row == null:
		content_row = HBoxContainer.new()
		content_row.name = "TeamEditorContentRow"
		content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_row.add_theme_constant_override("separation", 14)
		content_margin.add_child(content_row)
	_team_editor_cards_scroll = content_row.get_node_or_null("TeamEditorCardsScroll") as ScrollContainer
	if _team_editor_cards_scroll == null:
		_team_editor_cards_scroll = ScrollContainer.new()
		_team_editor_cards_scroll.name = "TeamEditorCardsScroll"
		_team_editor_cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_team_editor_cards_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_editor_cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_row.add_child(_team_editor_cards_scroll)
	_team_editor_card_grid = _team_editor_cards_scroll.get_node_or_null("TeamEditorCardGrid") as GridContainer
	if _team_editor_card_grid == null:
		_team_editor_card_grid = GridContainer.new()
		_team_editor_card_grid.name = "TeamEditorCardGrid"
		_team_editor_card_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_editor_card_grid.add_theme_constant_override("h_separation", 12)
		_team_editor_card_grid.add_theme_constant_override("v_separation", 12)
		_team_editor_cards_scroll.add_child(_team_editor_card_grid)
	_team_editor_sheet_scroll = content_row.get_node_or_null("TeamEditorSheetScroll") as ScrollContainer
	if _team_editor_sheet_scroll == null:
		_team_editor_sheet_scroll = ScrollContainer.new()
		_team_editor_sheet_scroll.name = "TeamEditorSheetScroll"
		_team_editor_sheet_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		_team_editor_sheet_scroll.custom_minimum_size = Vector2(760.0, 0.0)
		_team_editor_sheet_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_editor_sheet_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content_row.add_child(_team_editor_sheet_scroll)
	_team_editor_sheet_scroll.custom_minimum_size = Vector2(760.0, 0.0)
	_team_editor_sheet_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_team_editor_sheet_host = _team_editor_sheet_scroll.get_node_or_null("TeamEditorSheetHost") as VBoxContainer
	if _team_editor_sheet_host == null:
		_team_editor_sheet_host = VBoxContainer.new()
		_team_editor_sheet_host.name = "TeamEditorSheetHost"
		_team_editor_sheet_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_team_editor_sheet_host.add_theme_constant_override("separation", 8)
		_team_editor_sheet_scroll.add_child(_team_editor_sheet_host)
	_team_editor_sheet_host.custom_minimum_size = Vector2(760.0, 0.0)
	_ensure_native_team_editor_body_scroll(vbox, body_row)


func _ensure_native_team_editor_body_scroll(vbox: VBoxContainer, body_row: HBoxContainer) -> void:
	if vbox.get_node_or_null("TeamEditorBodyScroll") != null:
		return
	var scroll := ScrollContainer.new()
	scroll.name = "TeamEditorBodyScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0.0, 96.0)
	vbox.add_child(scroll)
	body_row.reparent(scroll)
	_team_editor_panel.set_meta("native_ui_bounded_scroll", true)


func _configure_team_editor_sheet_only_view_row(view_row: HBoxContainer) -> void:
	_team_editor_view_mode = TEAM_EDITOR_VIEW_SHEET
	_team_editor_view_buttons.clear()
	if view_row == null:
		return
	_clear_children(view_row)
	view_row.visible = false
	view_row.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ensure_team_editor_view_button(parent: HBoxContainer, view_mode: String, label: String, tooltip: String) -> void:
	if parent == null:
		return
	var button_name: String = "TeamEditorView%sButton" % view_mode.capitalize()
	var button := parent.get_node_or_null(button_name) as Button
	if button == null:
		button = Button.new()
		button.name = button_name
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(72.0, 44.0)
		parent.add_child(button)
	button.text = label
	button.tooltip_text = tooltip
	button.set_meta("team_editor_view_mode", view_mode)
	button.set_pressed_no_signal(view_mode == _team_editor_view_mode)
	_team_editor_view_buttons[view_mode] = button
	var pressed_callable := Callable(self, "_on_team_editor_view_mode_pressed").bind(view_mode)
	if not button.pressed.is_connected(pressed_callable):
		button.pressed.connect(pressed_callable)


func _refresh_start_roster_button() -> void:
	if _new_roster_button == null:
		return
	_new_roster_button.text = "Team neu bestaetigen" if _start_roster_reset_confirmation_pending else "Neues Skirmish-Team"
	_new_roster_button.tooltip_text = "Ersetzt das Startteam erst nach Bestaetigung." if _start_roster_reset_confirmation_pending else "Automatisch ein neues Startteam generieren."


func _refresh_team_editor_toggle() -> void:
	if _team_editor_toggle_button == null:
		return
	_team_editor_toggle_button.text = "Skirmish-Team-Editor" if _team_editor_open else "Skirmish-Team erstellen"
	_team_editor_toggle_button.tooltip_text = "Geoeffnetes Team-Editor-Fenster anzeigen." if _team_editor_open else "Eigenes Rookie-Team im grossen Team-Editor bearbeiten."


func _open_team_editor_for_path(entry_path: String = "") -> void:
	var path: String = entry_path.strip_edges()
	if path.is_empty():
		path = _selected_roster_entry_path.strip_edges()
	if path.is_empty():
		path = _start_roster_save_path
	var load_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("load_roster", _start_roster_profile_id, path))
	var roster: Dictionary = Dictionary(load_result.get("roster", {})).duplicate(true)
	if not bool(load_result.get("ok", false)) and path == _start_roster_save_path and not _start_roster.is_empty():
		roster = _start_roster.duplicate(true)
	if roster.is_empty():
		_status_label.text = "Team fehlt"
		_play_ui_sfx("warning", "team_editor_missing_roster")
		return
	_team_editor_roster_path = path
	_team_editor_roster = roster.duplicate(true)
	_normalize_team_editor_roster(true)
	_selected_roster_entry_path = path
	_team_editor_selected_unit_id = _resolve_team_editor_selected_unit_id(_team_editor_selected_unit_id)
	_set_team_editor_open(true)
	_refresh_team_library()
	_refresh_team_editor()
	_status_label.text = "Skirmish-Team-Editor"
	_play_ui_sfx("click", "team_editor_open")


func _set_team_editor_open(open: bool) -> void:
	if not open and _team_editor_metric_save_queued:
		_flush_team_editor_metric_save()
	_team_editor_open = open
	if _team_editor_panel != null:
		_layout_native_shell_windows()
		_team_editor_panel.visible = _team_editor_open
		_team_editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP if _team_editor_open else Control.MOUSE_FILTER_IGNORE
	if _team_library_panel != null:
		_team_library_panel.visible = not _team_editor_open
		_team_library_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE if _team_editor_open else Control.MOUSE_FILTER_STOP
	_refresh_team_editor_toggle()
	if not _team_editor_open:
		_status_label.text = "Ready"


func _set_team_editor_view_mode(view_mode: String) -> void:
	var _ignored_view_mode: String = view_mode.strip_edges().to_lower()
	_team_editor_view_mode = TEAM_EDITOR_VIEW_SHEET
	for mode_variant in _team_editor_view_buttons.keys():
		var mode: String = String(mode_variant)
		var button := _team_editor_view_buttons.get(mode) as Button
		if button != null:
			button.set_pressed_no_signal(mode == _team_editor_view_mode)
	_refresh_team_editor()


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
	var focused_row := get_viewport().gui_get_focus_owner() as Button
	var restore_focus := focused_row != null and focused_row.get_parent() == _team_library_list
	var focused_path := String(focused_row.get_meta("roster_entry_path", "")) if restore_focus else ""
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
		var selected: bool = String(entry.get("path", "")) == _selected_roster_entry_path
		row.set_pressed_no_signal(selected)
		TACTICAL_UI_THEME_SCRIPT.style_command_button(row, "selected" if selected else "neutral")
		row.add_theme_font_size_override("font_size", 14)
		row.pressed.connect(_on_team_library_row_pressed.bind(String(entry.get("path", ""))))
		var row_input_callable := Callable(self, "_on_team_library_row_gui_input").bind(String(entry.get("path", "")))
		if not row.gui_input.is_connected(row_input_callable):
			row.gui_input.connect(row_input_callable)
		_team_library_list.add_child(row)
		if restore_focus and String(entry.get("path", "")) == focused_path:
			row.call_deferred("grab_focus")
	_refresh_team_library_status()


func _select_team_library_row(entry_path: String) -> void:
	_selected_roster_entry_path = entry_path.strip_edges()
	# Selection changes presentation only. Keep the actual buttons, keyboard
	# focus and double-click target alive instead of rebuilding the whole list.
	if _team_library_list != null:
		for child in _team_library_list.get_children():
			var row := child as Button
			if row == null:
				continue
			var selected := String(row.get_meta("roster_entry_path", "")) == _selected_roster_entry_path
			row.set_pressed_no_signal(selected)
			TACTICAL_UI_THEME_SCRIPT.style_command_button(row, "selected" if selected else "neutral")
			row.add_theme_font_size_override("font_size", 14)
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
		_team_library_status_label.text = "%s: %s | Bearbeiten oder Doppelklick oeffnet den Team-Editor." % [prefix, selected_name]
	if _team_library_delete_button != null:
		var can_delete: bool = not selected_entry.is_empty() and bool(selected_entry.get("can_delete", false)) and not selected_active
		_team_library_delete_button.disabled = not can_delete
		_team_library_delete_button.tooltip_text = "Archiv-Team loeschen." if can_delete else "Aktives Team bleibt geschuetzt."
	if _team_library_activate_button != null:
		var can_activate: bool = not selected_entry.is_empty() and not selected_active and bool(selected_entry.get("valid", false))
		_team_library_activate_button.disabled = not can_activate
		_team_library_activate_button.tooltip_text = "Archiv-Team als aktives Startteam verwenden." if can_activate else "Aktives Team ist bereits ausgewaehlt."
	if _team_library_edit_button != null:
		var can_edit: bool = not selected_entry.is_empty() and bool(selected_entry.get("valid", false))
		_team_library_edit_button.disabled = not can_edit
		_team_library_edit_button.tooltip_text = "Ausgewaehltes Team mit Name, Portraits, Karten und Rookie-Punkten bearbeiten." if can_edit else "Erst ein gueltiges Team auswaehlen."


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
	if _team_editor_open and not _team_editor_roster.is_empty():
		return _normalize_team_editor_roster(save_if_changed)
	if _start_roster.is_empty():
		return Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", {}, _start_roster_seed, _start_roster_profile_id))
	return _normalize_start_team_editor(save_if_changed)


func _get_team_editor_roster_source() -> Dictionary:
	if _team_editor_open and not _team_editor_roster.is_empty():
		return _team_editor_roster
	return _start_roster


func _editing_team_editor_roster() -> bool:
	return _team_editor_open and not _team_editor_roster.is_empty()


func _normalize_team_editor_roster(save_if_changed: bool) -> Dictionary:
	var current_editor: Dictionary = Dictionary(_team_editor_roster.get("team_editor", {})).duplicate(true)
	var normalized: Dictionary = Dictionary(START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", current_editor, String(_team_editor_roster.get("seed", _start_roster_seed)), _start_roster_profile_id))
	if _team_editor_roster.is_empty():
		return normalized
	if current_editor != normalized:
		_team_editor_roster["team_editor"] = normalized
		if save_if_changed:
			_save_team_editor_roster_state("team_editor_normalized")
	return normalized


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


func _save_team_editor_roster_state(_reason: String, refresh_library: bool = true) -> Dictionary:
	if _team_editor_roster.is_empty():
		return {"ok": false, "reason": "missing_roster"}
	var path: String = _team_editor_roster_path if not _team_editor_roster_path.strip_edges().is_empty() else _start_roster_save_path
	var save_result: Dictionary = Dictionary(PLAYER_ROSTER_STORE_SCRIPT.call("save_roster", _team_editor_roster, _start_roster_profile_id, path))
	_last_start_roster_store_result = save_result.duplicate(true)
	if bool(save_result.get("ok", false)) and path == _start_roster_save_path:
		_start_roster = _team_editor_roster.duplicate(true)
		_refresh_team_name_controls()
	if refresh_library:
		_refresh_team_library()
	return save_result


func _queue_team_editor_metric_save(save_reason: String) -> Dictionary:
	_team_editor_metric_save_reason = save_reason.strip_edges() if not save_reason.strip_edges().is_empty() else "team_editor_unit_metric"
	if not _team_editor_metric_save_queued:
		_team_editor_metric_save_queued = true
		if is_inside_tree():
			_team_editor_metric_save_timer.start(0.12)
		else:
			call_deferred("_flush_team_editor_metric_save")
	return {
		"ok": true,
		"reason": "queued",
		"deferred": true,
	}


func _flush_team_editor_metric_save() -> Dictionary:
	if _team_editor_metric_save_timer != null and is_instance_valid(_team_editor_metric_save_timer) and not _team_editor_metric_save_timer.is_stopped():
		_team_editor_metric_save_timer.stop()
	if not _team_editor_metric_save_queued and _team_editor_metric_save_reason.strip_edges().is_empty():
		return {}
	_team_editor_metric_save_queued = false
	var save_reason: String = _team_editor_metric_save_reason.strip_edges()
	if save_reason.is_empty():
		save_reason = "team_editor_unit_metric"
	_team_editor_metric_save_reason = ""
	var save_result: Dictionary = {}
	if _editing_team_editor_roster():
		save_result = _save_team_editor_roster_state(save_reason, false)
	else:
		save_result = _save_start_roster_state(save_reason)
	_last_start_roster_store_result = save_result.duplicate(true)
	return save_result


func _refresh_team_editor() -> void:
	_team_editor_refresh_queued = false
	if _team_editor_panel == null or _team_editor_stats_vbox == null:
		return
	var roster: Dictionary = _get_team_editor_roster_source()
	var editor: Dictionary = _get_normalized_team_editor(false)
	var identity: Dictionary = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("build_team_identity_snapshot", roster))
	if _team_editor_title_label != null:
		_team_editor_title_label.text = "Skirmish-Team-Editor | %s" % String(identity.get("team_name", "Team"))
	if _team_editor_name_edit != null:
		_team_editor_name_edit.text = String(identity.get("team_name", ""))
	if _team_editor_summary_label != null:
		_team_editor_summary_label.text = ""
		_team_editor_summary_label.visible = false
	_refresh_team_editor_emblems(editor)
	_refresh_team_editor_focus_controls(editor)
	_refresh_team_editor_view_buttons()
	_refresh_team_editor_cards(roster)
	_refresh_team_editor_sheet(roster)


func _refresh_team_editor_focus_controls(editor: Dictionary = {}) -> void:
	if _team_editor_stats_vbox == null:
		return
	var normalized_editor: Dictionary = editor if not editor.is_empty() else _get_normalized_team_editor(false)
	var budget_used: int = int(normalized_editor.get("point_budget_used", 0))
	var budget_max: int = int(normalized_editor.get("point_budget_max", 0))
	var budget_available: int = int(normalized_editor.get("point_budget_available", 0))
	if _team_editor_budget_label != null:
		var policy: Dictionary = Dictionary(normalized_editor.get("point_budget_policy", {}))
		_team_editor_budget_label.text = "Team-Fokus %d/%d | frei %d | NPC-Werte rechts separat | je Fokus %d-%d" % [
			budget_used,
			budget_max,
			budget_available,
			int(policy.get("min_per_stat", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MIN)),
			int(policy.get("max_per_stat", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MAX)),
		]
	_clear_children(_team_editor_stats_vbox)
	_team_editor_stat_rows.clear()
	var allocations: Dictionary = Dictionary(normalized_editor.get("stat_allocations", {}))
	var stat_locks: Dictionary = Dictionary(normalized_editor.get("stat_locks", {}))
	for definition_variant in Array(normalized_editor.get("stat_definitions", [])):
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var stat_id: String = String(definition.get("id", "")).strip_edges()
		if stat_id.is_empty():
			continue
		var row := _build_team_editor_stat_row(normalized_editor, definition, int(allocations.get(stat_id, 0)), bool(stat_locks.get(stat_id, false)))
		_team_editor_stats_vbox.add_child(row)
	_connect_help_controls_in_tree(_team_editor_stats_vbox)


func _queue_team_editor_refresh() -> void:
	if _team_editor_refresh_queued:
		return
	_team_editor_refresh_queued = true
	call_deferred("_refresh_team_editor")


func _build_team_editor_summary_text(roster: Dictionary) -> String:
	var units: Array = Array(roster.get("units", []))
	var fireteams: Array = Array(roster.get("fireteam_suggestions", []))
	var source_label: String = "Aktives Team" if _team_editor_roster_path == _start_roster_save_path else "Archiv-Team"
	var view_label: String = "Charakterblatt"
	var size_policy: Dictionary = Dictionary(roster.get("team_size_policy", START_ROSTER_GENERATOR_SCRIPT.call("build_team_size_policy")))
	var multiplayer_cap: int = int(size_policy.get("multiplayer_side_cap", START_ROSTER_GENERATOR_SCRIPT.MULTIPLAYER_SIDE_CAP))
	return "%s | %d NPCs | %d Fireteams | Ansicht: %s | Start %d-%d, MP max %d/Seite" % [
		source_label,
		units.size(),
		fireteams.size(),
		view_label,
		START_ROSTER_GENERATOR_SCRIPT.MIN_ROSTER_SIZE,
		START_ROSTER_GENERATOR_SCRIPT.MAX_ROSTER_SIZE,
		multiplayer_cap,
	]


func _refresh_team_editor_view_buttons() -> void:
	for mode_variant in _team_editor_view_buttons.keys():
		var mode: String = String(mode_variant)
		var button := _team_editor_view_buttons.get(mode) as Button
		if button != null:
			button.set_pressed_no_signal(mode == _team_editor_view_mode)


func _refresh_team_editor_cards(roster: Dictionary) -> void:
	if _team_editor_card_grid == null or _team_editor_cards_scroll == null:
		return
	_clear_children(_team_editor_card_grid)
	_team_editor_selected_unit_id = _resolve_team_editor_selected_unit_id(_team_editor_selected_unit_id)
	var units: Array = Array(roster.get("units", []))
	var card_size: Vector2 = Vector2(326.0, 110.0)
	_team_editor_card_grid.columns = 1
	_team_editor_cards_scroll.custom_minimum_size = Vector2(352.0, 0.0)
	_team_editor_cards_scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for unit_variant in units:
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var card := _build_team_editor_unit_card(unit, card_size, true)
		_team_editor_card_grid.add_child(card)
		_connect_help_controls_in_tree(card)


func _refresh_team_editor_sheet(roster: Dictionary) -> void:
	if _team_editor_sheet_scroll == null or _team_editor_sheet_host == null:
		return
	_team_editor_sheet_scroll.visible = _team_editor_view_mode == TEAM_EDITOR_VIEW_SHEET
	_clear_children(_team_editor_sheet_host)
	_team_editor_unit_name_edit = null
	_team_editor_unit_portrait_preview = null
	_team_editor_unit_portrait_option = null
	if _team_editor_view_mode != TEAM_EDITOR_VIEW_SHEET:
		return
	var unit: Dictionary = _find_team_editor_unit(roster, _team_editor_selected_unit_id)
	if unit.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Keine NPC-Karte ausgewaehlt."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_team_editor_sheet_host.add_child(empty_label)
		return
	var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
	_add_team_editor_character_edit_controls(_team_editor_sheet_host, unit)
	_connect_help_controls_in_tree(_team_editor_sheet_host)
	var unit_id: String = String(unit.get("unit_id", ""))
	var render_options: Dictionary = {
		"on_value_changed": Callable(self, "_on_team_editor_profile_metric_changed").bind(unit_id),
		"on_metric_lock_changed": Callable(self, "_on_team_editor_profile_metric_lock_changed").bind(unit_id),
		"metric_group_budgets": _build_team_editor_metric_group_budgets(unit),
		"metric_locks": _get_team_editor_metric_locks_for_unit(unit_id),
		"group_editable_metrics": true,
		"two_column_layout": true,
		"show_badge_progress": true,
		"hide_short_description": true,
		"move_last_loadout_to_bottom": true,
		"show_all_platform_rows": true,
	}
	var sheet_body := VBoxContainer.new()
	sheet_body.name = "TeamEditorCharacterSheetBody"
	sheet_body.custom_minimum_size = Vector2(760.0, 0.0)
	sheet_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_team_editor_sheet_host.add_child(sheet_body)
	CHARACTER_SHEET_VIEW_SCRIPT.call("render", sheet_body, profile, render_options)
	_connect_help_controls_in_tree(sheet_body)


func _add_team_editor_character_edit_controls(host: VBoxContainer, unit: Dictionary) -> void:
	if host == null:
		return
	var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
	var panel := PanelContainer.new()
	panel.name = "TeamEditorCharacterEditPanel"
	panel.set_meta("character_editor_controls", true)
	panel.set_meta("help_id", "character_sheet.identity")
	panel.tooltip_text = "Name und Portrait werden direkt im geoeffneten Roster gespeichert."
	host.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	var title := Label.new()
	title.text = "Charakter bearbeiten"
	title.add_theme_font_size_override("font_size", 13)
	title.tooltip_text = "Alle sichtbaren Plus/Minus-Werte im Blatt speichern sofort im Roster."
	title.set_meta("help_id", "character_sheet.identity")
	vbox.add_child(title)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	vbox.add_child(name_row)
	var name_label := Label.new()
	name_label.text = "Name"
	name_label.custom_minimum_size = Vector2(62.0, 0.0)
	name_label.tooltip_text = "Anzeigename dieses NPCs im aktuellen Roster."
	name_label.set_meta("help_id", "character_sheet.name")
	name_row.add_child(name_label)
	_team_editor_unit_name_edit = LineEdit.new()
	_team_editor_unit_name_edit.name = "TeamEditorUnitNameEdit"
	_team_editor_unit_name_edit.text = String(unit.get("display_name", ""))
	_team_editor_unit_name_edit.placeholder_text = "Operator-Name"
	_team_editor_unit_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_team_editor_unit_name_edit.tooltip_text = "Enter oder Fokusverlust speichert den Namen sofort."
	_team_editor_unit_name_edit.set_meta("help_id", "character_sheet.name")
	_team_editor_unit_name_edit.text_submitted.connect(_on_team_editor_unit_name_submitted.bind(unit_id))
	_team_editor_unit_name_edit.focus_exited.connect(_on_team_editor_unit_name_focus_exited.bind(unit_id, _team_editor_unit_name_edit))
	name_row.add_child(_team_editor_unit_name_edit)
	var portrait_row := HBoxContainer.new()
	portrait_row.add_theme_constant_override("separation", 8)
	vbox.add_child(portrait_row)
	_team_editor_unit_portrait_preview = TextureRect.new()
	_team_editor_unit_portrait_preview.name = "TeamEditorUnitPortraitPreview"
	_team_editor_unit_portrait_preview.custom_minimum_size = Vector2(42.0, 42.0)
	_team_editor_unit_portrait_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_team_editor_unit_portrait_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_team_editor_unit_portrait_preview.texture = PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("load_texture", String(unit.get("portrait_id", "")), String(unit.get("portrait_path", ""))) as Texture2D
	_team_editor_unit_portrait_preview.tooltip_text = "Aktuelles Portrait: %s" % String(unit.get("portrait_id", ""))
	_team_editor_unit_portrait_preview.set_meta("help_id", "character_sheet.portrait")
	portrait_row.add_child(_team_editor_unit_portrait_preview)
	_team_editor_unit_portrait_option = OptionButton.new()
	_team_editor_unit_portrait_option.name = "TeamEditorUnitPortraitOption"
	_team_editor_unit_portrait_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_team_editor_unit_portrait_option.custom_minimum_size = Vector2(220.0, 34.0)
	_team_editor_unit_portrait_option.tooltip_text = "Portrait aus dem vorhandenen Portrait-Katalog auswaehlen. Die Vorschau links aendert sich sofort."
	_team_editor_unit_portrait_option.set_meta("help_id", "character_sheet.portrait")
	_populate_team_editor_unit_portrait_options(_team_editor_unit_portrait_option, String(unit.get("portrait_id", "")), String(unit.get("portrait_path", "")))
	_team_editor_unit_portrait_option.item_selected.connect(_on_team_editor_unit_portrait_selected.bind(unit_id, _team_editor_unit_portrait_option))
	portrait_row.add_child(_team_editor_unit_portrait_option)
	_connect_help_control(name_label, "character_sheet.name")
	_connect_help_control(_team_editor_unit_name_edit, "character_sheet.name")
	_connect_help_control(_team_editor_unit_portrait_preview, "character_sheet.portrait")
	_connect_help_control(_team_editor_unit_portrait_option, "character_sheet.portrait")


func _build_team_editor_unit_card(unit: Dictionary, card_size: Vector2, compact: bool) -> PanelContainer:
	var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
	var card := PanelContainer.new()
	card.name = "TeamEditorUnitCard_%s" % unit_id
	card.custom_minimum_size = card_size
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.tooltip_text = _build_team_editor_unit_tooltip(unit)
	card.set_meta("team_editor_unit_card", true)
	card.set_meta("unit_id", unit_id)
	card.set_meta("help_id", "character_sheet.identity")
	if unit_id == _team_editor_selected_unit_id:
		card.self_modulate = Color(0.80, 1.0, 0.92, 1.0)
	var input_callable := Callable(self, "_on_team_editor_unit_card_gui_input").bind(unit_id)
	if not card.gui_input.is_connected(input_callable):
		card.gui_input.connect(input_callable)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "TeamEditorUnitPortrait"
	portrait.custom_minimum_size = Vector2(58.0, 58.0) if compact else Vector2(74.0, 74.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("load_texture", String(unit.get("portrait_id", "")), String(unit.get("portrait_path", ""))) as Texture2D
	portrait.tooltip_text = "Portrait: %s" % String(unit.get("portrait_id", ""))
	portrait.set_meta("help_id", "character_sheet.portrait")
	row.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)
	var name_label := Label.new()
	name_label.text = String(unit.get("display_name", "Unbenannter NPC"))
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 14 if compact else 16)
	name_label.tooltip_text = "Anzeigename dieses NPCs im aktuellen Roster."
	name_label.set_meta("help_id", "character_sheet.name")
	info.add_child(name_label)
	var role_label := Label.new()
	role_label.text = "%s | %s" % [_build_team_editor_role_fit_label(unit), String(unit.get("fireteam_id", "reserve")).to_upper()]
	role_label.clip_text = true
	role_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	role_label.add_theme_font_size_override("font_size", 11)
	role_label.tooltip_text = _build_team_editor_role_fit_tooltip(unit)
	role_label.set_meta("help_id", "character_sheet.role")
	info.add_child(role_label)
	_add_team_editor_badge_row(info, unit)
	if compact:
		var compact_stats := Label.new()
		compact_stats.text = "A %.2f  S %.2f  L %.2f  T %.2f\nDS %.2f  FR %.2f  FG %.2f" % [
			_unit_skill_value(unit, "accuracy"),
			_unit_skill_value(unit, "speed"),
			_unit_skill_value(unit, "leadership"),
			_unit_skill_value(unit, "toughness"),
			_unit_skill_value(unit, "dropship_piloting"),
			_unit_skill_value(unit, "freighter_piloting"),
			_unit_skill_value(unit, "fighter_piloting"),
		]
		compact_stats.add_theme_font_size_override("font_size", 10)
		compact_stats.tooltip_text = "Accuracy, Speed, Leadership, Toughness sowie Dropship/Frachter/Fighter-Piloting."
		compact_stats.set_meta("help_id", "character_sheet.core_values")
		info.add_child(compact_stats)
	else:
		for stat_id in ["accuracy", "speed", "leadership", "toughness"]:
			info.add_child(_build_team_editor_unit_stat_row(unit, stat_id))
		var flight_stats := Label.new()
		flight_stats.text = "Flug: DS %.2f | FR %.2f | FG %.2f" % [
			_unit_skill_value(unit, "dropship_piloting"),
			_unit_skill_value(unit, "freighter_piloting"),
			_unit_skill_value(unit, "fighter_piloting"),
		]
		flight_stats.add_theme_font_size_override("font_size", 10)
		flight_stats.tooltip_text = "Drei Plattformwerte fuer Dropship-, Frachter- und Fighter-Piloten."
		flight_stats.set_meta("help_id", "character_sheet.platform_skills")
		info.add_child(flight_stats)
		var action_row := HBoxContainer.new()
		action_row.name = "TeamEditorCardActionRow"
		action_row.add_theme_constant_override("separation", 6)
		info.add_child(action_row)
		var open_sheet_button := Button.new()
		open_sheet_button.name = "TeamEditorOpenSheet_%s" % unit_id
		open_sheet_button.text = "Blatt"
		open_sheet_button.custom_minimum_size = Vector2(68.0, 24.0)
		open_sheet_button.tooltip_text = "Diesen NPC im voll editierbaren Charakterblatt oeffnen."
		open_sheet_button.set_meta("help_id", "character_sheet.identity")
		open_sheet_button.pressed.connect(_on_team_editor_unit_sheet_button_pressed.bind(unit_id))
		action_row.add_child(open_sheet_button)
	return card


func _add_team_editor_badge_row(host: VBoxContainer, unit: Dictionary) -> void:
	var badge_grid := GridContainer.new()
	badge_grid.name = "TeamEditorBadgeGrid"
	badge_grid.columns = 3
	badge_grid.add_theme_constant_override("h_separation", 7)
	badge_grid.add_theme_constant_override("v_separation", 3)
	badge_grid.set_meta("help_id", "character_sheet.rank_badges")
	host.add_child(badge_grid)
	var profile = META_UNIT_PROFILE_SCRIPT.new(unit)
	var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", profile, 0, false))
	for badge_variant in progress:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("badge_key", "")).strip_edges() == "enemy":
			continue
		var badge_key: String = String(badge.get("badge_key", badge.get("badge_id", "unknown"))).strip_edges()
		var badge_cell := VBoxContainer.new()
		badge_cell.name = "TeamEditorBadgeCell_%s" % badge_key
		badge_cell.custom_minimum_size = Vector2(46.0, 0.0)
		badge_cell.add_theme_constant_override("separation", 1)
		badge_cell.set_meta("help_id", "character_sheet.rank_badges")
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_cell, badge)
		var icon_holder := CenterContainer.new()
		icon_holder.name = "TeamEditorBadgeIconHolder_%s" % badge_key
		badge_cell.add_child(icon_holder)
		var badge_rect := TextureRect.new()
		badge_rect.name = "TeamEditorRankBadge_%s" % badge_key
		badge_rect.custom_minimum_size = Vector2(18.0, 18.0)
		badge_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge_rect.set_meta("rank_badge_progress_candidate", true)
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_rect, badge)
		var path: String = String(badge.get("path", "")).strip_edges()
		if not path.is_empty() and ResourceLoader.exists(path):
			badge_rect.texture = load(path) as Texture2D
		if not bool(badge.get("achieved", false)):
			badge_rect.modulate = Color(0.42, 0.45, 0.48, 0.52)
			badge_rect.set_meta("rank_badge_locked", true)
		if badge_rect.texture == null:
			badge_rect.modulate = Color(1.0, 0.45, 0.35, 0.95) if bool(badge.get("achieved", false)) else Color(0.50, 0.34, 0.32, 0.64)
			badge_rect.set_meta("missing_rank_badge_asset", true)
		icon_holder.add_child(badge_rect)
		var badge_label := Label.new()
		badge_label.name = "TeamEditorRankBadgeLabel_%s" % badge_key
		badge_label.text = String(badge.get("label", "Badge")).strip_edges()
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		badge_label.max_lines_visible = 2
		badge_label.custom_minimum_size = Vector2(46.0, 0.0)
		badge_label.add_theme_font_size_override("font_size", 8)
		badge_label.modulate = Color(0.78, 0.86, 0.90, 0.94) if bool(badge.get("achieved", false)) else Color(0.52, 0.58, 0.62, 0.72)
		badge_label.set_meta("help_id", "character_sheet.rank_badges")
		NPC_RANK_BADGE_RESOLVER_SCRIPT.call("apply_badge_help_metadata", badge_label, badge)
		badge_cell.add_child(badge_label)
		badge_grid.add_child(badge_cell)
	if badge_grid.get_child_count() == 0:
		var no_badge := Label.new()
		no_badge.text = "Rookie"
		no_badge.add_theme_font_size_override("font_size", 10)
		no_badge.tooltip_text = "Noch keine starke abgeleitete Spezialisierung."
		no_badge.set_meta("help_id", "character_sheet.rank_badges")
		badge_grid.add_child(no_badge)


func _build_team_editor_role_fit_label(unit: Dictionary) -> String:
	var achieved_parts: PackedStringArray = PackedStringArray()
	var next_parts: PackedStringArray = PackedStringArray()
	var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", META_UNIT_PROFILE_SCRIPT.new(unit), 0, false))
	for badge_variant in progress:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("badge_key", "")).strip_edges() == "enemy":
			continue
		var label: String = "%s %.2f" % [String(badge.get("label", "Badge")), float(badge.get("score", 0.0))]
		if bool(badge.get("achieved", false)):
			achieved_parts.append(label)
		elif next_parts.size() < 1:
			next_parts.append(label)
	if not achieved_parts.is_empty():
		return "Fit %s" % " / ".join(achieved_parts.slice(0, mini(2, achieved_parts.size())))
	if not next_parts.is_empty():
		return "Fit offen -> %s" % String(next_parts[0])
	return "Fit offen"


func _build_team_editor_role_fit_tooltip(unit: Dictionary) -> String:
	var stored_role: String = String(unit.get("role_name", unit.get("role_id", ""))).strip_edges()
	var progress: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badge_progress_for_profile", META_UNIT_PROFILE_SCRIPT.new(unit), 0, false))
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Rollen-Fit aus Kernwerten, Kommunikation, Verhalten, Plattformwerten und Loadout-Kontext.")
	if not stored_role.is_empty():
		lines.append("Gespeicherter Starttext: %s" % stored_role)
	for badge_variant in progress:
		if typeof(badge_variant) != TYPE_DICTIONARY:
			continue
		var badge: Dictionary = Dictionary(badge_variant)
		if String(badge.get("badge_key", "")).strip_edges() == "enemy":
			continue
		lines.append("%s %.2f - %s" % [
			String(badge.get("label", "Badge")),
			float(badge.get("score", 0.0)),
			String(badge.get("requirement_text", "")),
		])
	return "\n".join(lines)


func _build_team_editor_unit_stat_row(unit: Dictionary, stat_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var help_id: String = _team_editor_unit_stat_help_id(stat_id)
	row.set_meta("help_id", help_id)
	row.tooltip_text = _team_editor_unit_stat_tooltip(stat_id)
	var label := Label.new()
	label.text = stat_id.substr(0, 1).to_upper()
	label.custom_minimum_size = Vector2(14.0, 0.0)
	label.add_theme_font_size_override("font_size", 10)
	label.tooltip_text = _team_editor_unit_stat_tooltip(stat_id)
	label.set_meta("help_id", help_id)
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = _unit_skill_value(unit, stat_id)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120.0, 12.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.tooltip_text = label.tooltip_text
	bar.set_meta("help_id", help_id)
	row.add_child(bar)
	var value_label := Label.new()
	value_label.text = "%.2f" % _unit_skill_value(unit, stat_id)
	value_label.custom_minimum_size = Vector2(38.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.tooltip_text = label.tooltip_text
	value_label.set_meta("help_id", help_id)
	row.add_child(value_label)
	return row


func _build_team_editor_unit_tooltip(unit: Dictionary) -> String:
	var traits: PackedStringArray = PackedStringArray(unit.get("trait_ids", PackedStringArray()))
	var badges: Array = Array(NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", META_UNIT_PROFILE_SCRIPT.new(unit)))
	var badge_parts: PackedStringArray = PackedStringArray()
	for badge_variant in badges:
		if typeof(badge_variant) == TYPE_DICTIONARY:
			var badge: Dictionary = Dictionary(badge_variant)
			badge_parts.append("%s (%s)" % [String(badge.get("label", "")), String(badge.get("reason", ""))])
	return "%s\nRolle: %s\nLoadout: %s\nTraits: %s\nAbgeleitet: %s" % [
		String(unit.get("display_name", "")),
		String(unit.get("role_name", unit.get("role_id", ""))),
		String(unit.get("loadout_summary", "")),
		", ".join(traits),
		", ".join(badge_parts),
	]


func _team_editor_unit_stat_tooltip(stat_id: String) -> String:
	match stat_id:
		"accuracy":
			return "Accuracy: bestimmt Trefferchance und abgeleitete Shooter-/Meisterschuetze-Tendenz."
		"speed":
			return "Speed: beeinflusst Bewegung, Reaktionszeit und Scout-/Pilotengefuehl."
		"leadership":
			return "Leadership: wichtig fuer FTL, Befehlsruhe und Leader-Badges."
		"toughness":
			return "Toughness: haelt Druck, Verletzungen und Frustspitzen besser aus."
		"dropship_piloting":
			return "Dropship Piloting: wichtig fuer LZ-Anflug, Touchdown und Rueckflug."
		"freighter_piloting":
			return "Freighter Piloting: wichtig fuer schwere Transporte und Cargo-Routen."
		"fighter_piloting":
			return "Fighter Piloting: wichtig fuer Begleitschutz, Abfangen und Strike-Rollen."
		_:
			return stat_id.capitalize()


func _team_editor_unit_stat_help_id(stat_id: String) -> String:
	match stat_id:
		"accuracy", "speed", "toughness", "awareness", "recognition", "stealth", "discipline", "leadership":
			return "character_sheet.core.%s" % stat_id
		"dropship_piloting", "freighter_piloting", "fighter_piloting", "ground_vehicle_handling":
			return "character_sheet.platform.%s" % stat_id
		"speech_quality", "speech_quantity":
			return "character_sheet.%s" % stat_id
		"initiative", "order_fidelity", "signature_control", "contact_stability", "autonomy":
			return "character_sheet.%s" % stat_id
		_:
			return "character_sheet.core_values"


func _unit_skill_value(unit: Dictionary, stat_id: String) -> float:
	var values: Dictionary = Dictionary(unit.get("skill_values", {}))
	if values.has(stat_id):
		return clampf(float(values.get(stat_id, 0.0)), 0.0, 1.0)
	var platform_values: Dictionary = Dictionary(unit.get("platform_values", {}))
	if platform_values.has(stat_id):
		return clampf(float(platform_values.get(stat_id, 0.0)), 0.0, 1.0)
	var communication_values: Dictionary = Dictionary(unit.get("communication_values", {}))
	if communication_values.has(stat_id):
		return clampf(float(communication_values.get(stat_id, 0.0)), 0.0, 1.0)
	var behavior_axes: Dictionary = Dictionary(unit.get("behavior_axes", {}))
	if behavior_axes.has(stat_id):
		return clampf(float(behavior_axes.get(stat_id, 0.0)), 0.0, 1.0)
	return clampf(float(unit.get("skill_%s" % stat_id, 0.0)), 0.0, 1.0)


func _build_team_editor_metric_group_budgets(unit: Dictionary) -> Dictionary:
	if unit.is_empty():
		return {}
	var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
	if unit_id.is_empty():
		return {}
	var result: Dictionary = {}
	for group_variant in TEAM_EDITOR_METRIC_GROUP_CONFIG.keys():
		var group_id: String = String(group_variant)
		var config: Dictionary = Dictionary(TEAM_EDITOR_METRIC_GROUP_CONFIG.get(group_id, {}))
		var budget_key: String = "%s|%s" % [unit_id, group_id]
		var used_points: int = _team_editor_metric_group_used_points(unit, group_id)
		if not _team_editor_metric_group_budgets.has(budget_key):
			var default_cap: int = int(config.get("row_count", 1)) * int(config.get("points_per_row", 12))
			_team_editor_metric_group_budgets[budget_key] = maxi(default_cap, used_points + 2)
		result[group_id] = {
			"label": String(config.get("label", group_id.capitalize())),
			"help_id": String(config.get("help_id", "character_sheet.skill_group_budget")),
			"max_points": int(_team_editor_metric_group_budgets.get(budget_key, used_points)),
			"points_per_value": TEAM_EDITOR_METRIC_POINTS_PER_VALUE,
		}
	return result


func _team_editor_metric_group_used_points(unit: Dictionary, group_id: String) -> int:
	var total: int = 0
	var source: Dictionary = Dictionary(unit.get(group_id, {}))
	for key in _team_editor_metric_group_keys(group_id):
		total += roundi(clampf(float(source.get(key, 0.0)), 0.0, 1.0) * float(TEAM_EDITOR_METRIC_POINTS_PER_VALUE))
	return total


func _team_editor_metric_group_keys(group_id: String) -> PackedStringArray:
	match group_id:
		"progression":
			return PackedStringArray(["morale", "frustration"])
		"skill_values":
			return PackedStringArray(["accuracy", "speed", "toughness", "awareness", "recognition", "stealth", "discipline", "leadership"])
		"communication_values":
			return PackedStringArray(["speech_quality", "speech_quantity"])
		"platform_values":
			return PackedStringArray(["ground_vehicle_handling", "dropship_piloting", "freighter_piloting", "fighter_piloting"])
		"behavior_axes":
			return PackedStringArray(["initiative", "order_fidelity", "signature_control", "contact_stability", "autonomy"])
		_:
			return PackedStringArray()


func _get_team_editor_metric_locks_for_unit(unit_id: String) -> Dictionary:
	var normalized_unit_id: String = unit_id.strip_edges()
	if normalized_unit_id.is_empty():
		return {}
	var prefix: String = "%s|" % normalized_unit_id
	var result: Dictionary = {}
	var editor: Dictionary = _get_normalized_team_editor(false)
	var persistent_locks: Dictionary = Dictionary(editor.get("metric_locks", {}))
	for key_variant in persistent_locks.keys():
		var full_key: String = String(key_variant)
		if not full_key.begins_with(prefix):
			continue
		result[full_key.substr(prefix.length())] = bool(persistent_locks.get(full_key, false))
	for key_variant in _team_editor_metric_locks.keys():
		var session_key: String = String(key_variant)
		if not session_key.begins_with(prefix):
			continue
		result[session_key.substr(prefix.length())] = bool(_team_editor_metric_locks.get(session_key, false))
	return result


func _team_editor_metric_lock_key(unit_id: String, row_data: Dictionary) -> String:
	var value_group: String = String(row_data.get("value_group", "")).strip_edges()
	var value_key: String = String(row_data.get("value_key", "")).strip_edges()
	if value_group.is_empty() or value_key.is_empty():
		return ""
	return "%s|%s.%s" % [unit_id.strip_edges(), value_group, value_key]


func _set_team_editor_metric_lock(unit_id: String, row_data: Dictionary, locked: bool) -> Dictionary:
	var lock_key: String = _team_editor_metric_lock_key(unit_id, row_data)
	if lock_key.is_empty():
		return {"ok": false, "reason": "missing_lock_key"}
	if locked:
		_team_editor_metric_locks[lock_key] = true
	else:
		_team_editor_metric_locks.erase(lock_key)
	var editor: Dictionary = _get_normalized_team_editor(false)
	var metric_locks: Dictionary = Dictionary(editor.get("metric_locks", {})).duplicate(true)
	if locked:
		metric_locks[lock_key] = true
	else:
		metric_locks.erase(lock_key)
	editor["metric_locks"] = metric_locks
	var save_result: Dictionary = {}
	if _editing_team_editor_roster():
		_team_editor_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_team_editor_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		save_result = _save_team_editor_roster_state("team_editor_metric_lock")
	else:
		_start_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		save_result = _save_start_roster_state("team_editor_metric_lock")
	_queue_team_editor_refresh()
	return {
		"ok": bool(save_result.get("ok", false)),
		"lock_key": lock_key,
		"locked": locked,
		"save": save_result,
	}


func _resolve_team_editor_selected_unit_id(candidate_unit_id: String) -> String:
	var candidate: String = candidate_unit_id.strip_edges()
	for unit_variant in Array(_get_team_editor_roster_source().get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		var unit_id: String = String(unit.get("unit_id", "")).strip_edges()
		if unit_id == candidate:
			return candidate
	for unit_variant in Array(_get_team_editor_roster_source().get("units", [])):
		if typeof(unit_variant) == TYPE_DICTIONARY:
			return String(Dictionary(unit_variant).get("unit_id", "")).strip_edges()
	return ""


func _find_team_editor_unit(roster: Dictionary, unit_id: String) -> Dictionary:
	var normalized_id: String = unit_id.strip_edges()
	for unit_variant in Array(roster.get("units", [])):
		if typeof(unit_variant) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(unit_variant)
		if String(unit.get("unit_id", "")).strip_edges() == normalized_id:
			return unit
	return {}


func _set_team_editor_unit_name(unit_id: String, next_name: String, play_sound: bool = true) -> Dictionary:
	var normalized_name: String = next_name.strip_edges()
	if normalized_name.is_empty():
		return {"ok": false, "reason": "empty_name", "unit_id": unit_id}
	return _update_team_editor_unit(unit_id, {"display_name": normalized_name}, "team_editor_unit_name", play_sound)


func _set_team_editor_unit_portrait(unit_id: String, portrait_id: String, portrait_path: String, play_sound: bool = true) -> Dictionary:
	var normalized_id: String = portrait_id.strip_edges()
	var normalized_path: String = portrait_path.strip_edges()
	if normalized_id.is_empty():
		return {"ok": false, "reason": "empty_portrait", "unit_id": unit_id}
	if normalized_path.is_empty():
		normalized_path = String(PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("resolve_path", normalized_id, ""))
	return _update_team_editor_unit(unit_id, {"portrait_id": normalized_id, "portrait_path": normalized_path}, "team_editor_unit_portrait", play_sound)


func _replace_team_editor_unit_from_profile(unit_id: String, profile, row_data: Dictionary = {}) -> Dictionary:
	if profile == null or not profile.has_method("to_dict"):
		return {"ok": false, "reason": "invalid_profile", "unit_id": unit_id}
	var profile_data: Dictionary = Dictionary(profile.call("to_dict"))
	profile_data = _rebuild_team_editor_profile_derived_values(profile_data, row_data)
	return _update_team_editor_unit(unit_id, profile_data, "team_editor_unit_metric", false, true)


func _rebuild_team_editor_profile_derived_values(profile_data: Dictionary, row_data: Dictionary = {}) -> Dictionary:
	var result: Dictionary = profile_data.duplicate(true)
	var edited_group: String = String(row_data.get("value_group", "")).strip_edges()
	var original_behavior_axes: Dictionary = Dictionary(result.get("behavior_axes", {})).duplicate(true)
	var math_input: Dictionary = result.duplicate(true)
	for key_variant in Dictionary(result.get("skill_values", {})).keys():
		var key: String = String(key_variant)
		math_input[key] = float(Dictionary(result.get("skill_values", {})).get(key, 0.0))
	for key_variant in Dictionary(result.get("communication_values", {})).keys():
		var key: String = String(key_variant)
		math_input[key] = float(Dictionary(result.get("communication_values", {})).get(key, 0.0))
	if edited_group != "platform_values":
		math_input.erase("platform_values")
	else:
		for key_variant in Dictionary(result.get("platform_values", {})).keys():
			var key: String = String(key_variant)
			math_input[key] = float(Dictionary(result.get("platform_values", {})).get(key, UNIT_PROFILE_MATH_SCRIPT.NOT_APPLICABLE))
	var bundle: Dictionary = Dictionary(UNIT_PROFILE_MATH_SCRIPT.call("build_character_bundle", math_input))
	result["role_id"] = String(bundle.get("role_id", result.get("role_id", "")))
	result["skill_values"] = Dictionary(bundle.get("core_values", result.get("skill_values", {}))).duplicate(true)
	result["communication_values"] = Dictionary(bundle.get("communication_values", result.get("communication_values", {}))).duplicate(true)
	result["platform_values"] = Dictionary(bundle.get("platform_values", result.get("platform_values", {}))).duplicate(true)
	result["behavior_axes"] = original_behavior_axes if edited_group == "behavior_axes" else Dictionary(bundle.get("behavior_axes", result.get("behavior_axes", {}))).duplicate(true)
	result["method_scores"] = Dictionary(bundle.get("method_scores", result.get("method_scores", {}))).duplicate(true)
	result["function_scores"] = Dictionary(bundle.get("function_scores", result.get("function_scores", {}))).duplicate(true)
	result["method_summary_text"] = String(bundle.get("method_summary", result.get("method_summary_text", ""))).strip_edges()
	result["function_summary_text"] = String(bundle.get("function_summary", result.get("function_summary_text", ""))).strip_edges()
	var skills: Dictionary = Dictionary(result.get("skill_values", {}))
	result["skill_summary_text"] = "A:%.1f S:%.1f L:%.1f T:%.1f" % [
		float(skills.get("accuracy", 0.0)),
		float(skills.get("speed", 0.0)),
		float(skills.get("leadership", 0.0)),
		float(skills.get("toughness", 0.0)),
	]
	result["primary_specialty"] = String(bundle.get("primary_specialty", result.get("primary_specialty", ""))).strip_edges()
	result["secondary_specialty"] = String(bundle.get("secondary_specialty", result.get("secondary_specialty", ""))).strip_edges()
	result["specialty_text"] = String(result.get("primary_specialty", result.get("specialty_text", ""))).strip_edges()
	result["combat_effect_summary_text"] = String(bundle.get("combat_effect_summary", result.get("combat_effect_summary_text", ""))).strip_edges()
	return result


func _update_team_editor_unit(unit_id: String, patch: Dictionary, save_reason: String, play_sound: bool = true, replace_full_profile: bool = false) -> Dictionary:
	var normalized_id: String = unit_id.strip_edges()
	if normalized_id.is_empty():
		return {"ok": false, "reason": "missing_unit_id"}
	var target_roster: Dictionary = _get_team_editor_roster_source().duplicate(true)
	var units: Array = Array(target_roster.get("units", [])).duplicate(true)
	var changed: bool = false
	for index in range(units.size()):
		if typeof(units[index]) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = Dictionary(units[index]).duplicate(true)
		if String(unit.get("unit_id", "")).strip_edges() != normalized_id:
			continue
		if replace_full_profile:
			for key_variant in patch.keys():
				unit[key_variant] = patch.get(key_variant)
			unit["unit_id"] = normalized_id
		else:
			for key_variant in patch.keys():
				unit[key_variant] = patch.get(key_variant)
		unit["rank_badges"] = NPC_RANK_BADGE_RESOLVER_SCRIPT.call("get_badges_for_profile", META_UNIT_PROFILE_SCRIPT.new(unit))
		units[index] = unit
		changed = true
		break
	if not changed:
		return {"ok": false, "reason": "unit_not_found", "unit_id": normalized_id}
	target_roster["units"] = units
	var save_result: Dictionary = {}
	if _editing_team_editor_roster():
		_team_editor_roster = target_roster
		if _team_editor_roster_path == _start_roster_save_path:
			_start_roster = target_roster.duplicate(true)
		save_result = _queue_team_editor_metric_save(save_reason) if replace_full_profile else _save_team_editor_roster_state(save_reason)
	else:
		_start_roster = target_roster
		save_result = _queue_team_editor_metric_save(save_reason) if replace_full_profile else _save_start_roster_state(save_reason)
	if replace_full_profile:
		pass
	else:
		_refresh_team_editor()
	if play_sound:
		_play_ui_sfx("confirm" if bool(save_result.get("ok", false)) else "warning", save_reason)
	return {
		"ok": bool(save_result.get("ok", false)),
		"changed": changed,
		"unit_id": normalized_id,
		"save": save_result,
	}


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


func _team_editor_stat_ids(editor: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	for definition_variant in Array(editor.get("stat_definitions", [])):
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		var stat_id: String = String(definition.get("id", "")).strip_edges()
		if not stat_id.is_empty():
			result.append(stat_id)
	return result


func _team_editor_stat_min(editor: Dictionary, stat_id: String) -> int:
	var definition: Dictionary = _get_team_editor_stat_definition(editor, stat_id)
	return int(definition.get("min_value", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MIN))


func _team_editor_stat_max(editor: Dictionary, stat_id: String) -> int:
	var definition: Dictionary = _get_team_editor_stat_definition(editor, stat_id)
	return int(definition.get("max_value", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MAX))


func _team_editor_stat_total(editor: Dictionary, allocations: Dictionary) -> int:
	var total: int = 0
	for stat_id in _team_editor_stat_ids(editor):
		total += int(allocations.get(stat_id, 0))
	return total


func _team_editor_stat_raise_capacity(editor: Dictionary, allocations: Dictionary, stat_locks: Dictionary, active_stat_id: String) -> int:
	if bool(stat_locks.get(active_stat_id, false)):
		return 0
	var current_value: int = int(allocations.get(active_stat_id, 0))
	var row_capacity: int = maxi(_team_editor_stat_max(editor, active_stat_id) - current_value, 0)
	if row_capacity <= 0:
		return 0
	var budget_max: int = int(editor.get("point_budget_max", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_POINT_BUDGET_MAX))
	var free_points: int = maxi(budget_max - _team_editor_stat_total(editor, allocations), 0)
	var movable_points: int = 0
	for stat_id in _team_editor_stat_ids(editor):
		if stat_id == active_stat_id or bool(stat_locks.get(stat_id, false)):
			continue
		movable_points += maxi(int(allocations.get(stat_id, 0)) - _team_editor_stat_min(editor, stat_id), 0)
	return mini(row_capacity, free_points + movable_points)


func _team_editor_focus_candidate_order(editor: Dictionary, allocations: Dictionary, stat_locks: Dictionary, active_stat_id: String, direction: int) -> Array:
	var candidates: Array = []
	var order: int = 0
	for stat_id in _team_editor_stat_ids(editor):
		if stat_id == active_stat_id or bool(stat_locks.get(stat_id, false)):
			order += 1
			continue
		var value: int = int(allocations.get(stat_id, 0))
		if direction < 0 and value <= _team_editor_stat_min(editor, stat_id):
			order += 1
			continue
		if direction > 0 and value >= _team_editor_stat_max(editor, stat_id):
			order += 1
			continue
		candidates.append({"id": stat_id, "value": value, "order": order})
		order += 1
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var value_a: int = int(a.get("value", 0))
		var value_b: int = int(b.get("value", 0))
		if value_a == value_b:
			return int(a.get("order", 0)) < int(b.get("order", 0))
		return value_a > value_b if direction < 0 else value_a < value_b
	)
	return candidates


func _redistribute_team_editor_focus_points(allocations: Dictionary, editor: Dictionary, stat_locks: Dictionary, active_stat_id: String, requested_points: int, direction: int) -> int:
	var remaining_points: int = maxi(requested_points, 0)
	while remaining_points > 0:
		var changed_this_pass: bool = false
		for candidate_variant in _team_editor_focus_candidate_order(editor, allocations, stat_locks, active_stat_id, direction):
			if remaining_points <= 0:
				break
			var candidate: Dictionary = Dictionary(candidate_variant)
			var stat_id: String = String(candidate.get("id", "")).strip_edges()
			if stat_id.is_empty():
				continue
			var current_value: int = int(allocations.get(stat_id, 0))
			if direction < 0:
				if current_value <= _team_editor_stat_min(editor, stat_id):
					continue
				allocations[stat_id] = current_value - 1
			else:
				if current_value >= _team_editor_stat_max(editor, stat_id):
					continue
				allocations[stat_id] = current_value + 1
			remaining_points -= 1
			changed_this_pass = true
		if not changed_this_pass:
			break
	return maxi(requested_points, 0) - remaining_points


func _build_team_editor_focus_allocation_change(editor: Dictionary, allocations: Dictionary, stat_locks: Dictionary, stat_id: String, target_value: int) -> Dictionary:
	var normalized_stat_id: String = stat_id.strip_edges()
	var next_allocations: Dictionary = allocations.duplicate(true)
	var current_value: int = int(next_allocations.get(normalized_stat_id, 0))
	var stat_min: int = _team_editor_stat_min(editor, normalized_stat_id)
	var stat_max: int = _team_editor_stat_max(editor, normalized_stat_id)
	var requested_target: int = clampi(target_value, stat_min, stat_max)
	var requested_delta: int = requested_target - current_value
	var applied_delta: int = 0
	var redistributed_points: int = 0
	if requested_delta > 0:
		var budget_max: int = int(editor.get("point_budget_max", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_POINT_BUDGET_MAX))
		var free_points: int = maxi(budget_max - _team_editor_stat_total(editor, next_allocations), 0)
		var free_used: int = mini(requested_delta, free_points)
		var points_to_take: int = requested_delta - free_used
		redistributed_points = _redistribute_team_editor_focus_points(next_allocations, editor, stat_locks, normalized_stat_id, points_to_take, -1)
		applied_delta = free_used + redistributed_points
	elif requested_delta < 0:
		applied_delta = requested_delta
		redistributed_points = _redistribute_team_editor_focus_points(next_allocations, editor, stat_locks, normalized_stat_id, -requested_delta, 1)
	next_allocations[normalized_stat_id] = current_value + applied_delta
	return {
		"allocations": next_allocations,
		"value": int(next_allocations.get(normalized_stat_id, current_value)),
		"changed": applied_delta != 0,
		"requested_delta": requested_delta,
		"applied_delta": applied_delta,
		"redistributed_points": redistributed_points,
	}


func _build_team_editor_stat_row(editor: Dictionary, definition: Dictionary, value: int, locked: bool = false) -> Control:
	var stat_id: String = String(definition.get("id", "")).strip_edges()
	var stat_min: int = int(definition.get("min_value", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MIN))
	var stat_max: int = int(definition.get("max_value", START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MAX))
	var allocations: Dictionary = Dictionary(editor.get("stat_allocations", {}))
	var stat_locks: Dictionary = Dictionary(editor.get("stat_locks", {}))
	var raise_capacity: int = _team_editor_stat_raise_capacity(editor, allocations, stat_locks, stat_id)
	var description: String = String(definition.get("description", ""))
	var effect_text: String = String(definition.get("effect_text", "")).strip_edges()
	var help_id: String = String(definition.get("help_id", "team_editor.stat.%s" % stat_id)).strip_edges()
	var lock_text: String = "Gesperrt: Wert bleibt unveraendert." if locked else "Entsperrt: Erhoehen zieht Punkte gleichmaessig aus anderen entsperrten Teamfokus-Werten."
	var tooltip: String = "%s\nWirkung: %s\nBereich: %d-%d\n%s" % [description, effect_text, stat_min, stat_max, lock_text]
	var outer := VBoxContainer.new()
	outer.name = "TeamEditorStat_%s" % stat_id
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 2)
	outer.tooltip_text = tooltip
	outer.set_meta("help_id", help_id)
	var row := HBoxContainer.new()
	row.name = "TeamEditorStatMain_%s" % stat_id
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	row.tooltip_text = tooltip
	row.set_meta("help_id", help_id)
	outer.add_child(row)
	var label := Label.new()
	label.name = "TeamEditorStatLabel_%s" % stat_id
	label.text = String(definition.get("label", stat_id.capitalize()))
	label.custom_minimum_size = Vector2(90.0, 0.0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	label.tooltip_text = tooltip
	label.set_meta("help_id", help_id)
	label.add_theme_font_size_override("font_size", 10)
	row.add_child(label)
	var minus_button := Button.new()
	minus_button.name = "TeamEditorMinus_%s" % stat_id
	minus_button.text = "-"
	minus_button.custom_minimum_size = Vector2(24.0, 24.0)
	minus_button.disabled = locked or value <= stat_min
	minus_button.tooltip_text = "Punkt abziehen.\n%s" % tooltip
	minus_button.set_meta("help_id", help_id)
	minus_button.pressed.connect(_on_team_editor_stat_delta_pressed.bind(stat_id, -TEAM_EDITOR_POINT_DELTA))
	row.add_child(minus_button)
	var value_slider := HSlider.new()
	value_slider.name = "TeamEditorValue_%s" % stat_id
	value_slider.min_value = float(stat_min)
	value_slider.max_value = float(stat_max)
	value_slider.step = 1.0
	value_slider.rounded = true
	value_slider.value = float(value)
	value_slider.editable = not locked
	value_slider.custom_minimum_size = Vector2(54.0, 24.0)
	value_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_slider.tooltip_text = tooltip
	value_slider.set_meta("help_id", help_id)
	value_slider.value_changed.connect(_on_team_editor_stat_slider_changed.bind(stat_id))
	row.add_child(value_slider)
	var value_label := Label.new()
	value_label.name = "TeamEditorValueLabel_%s" % stat_id
	value_label.text = "%02d/%02d" % [value, stat_max]
	value_label.custom_minimum_size = Vector2(42.0, 0.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.tooltip_text = tooltip
	value_label.set_meta("help_id", help_id)
	row.add_child(value_label)
	var plus_button := Button.new()
	plus_button.name = "TeamEditorPlus_%s" % stat_id
	plus_button.text = "+"
	plus_button.custom_minimum_size = Vector2(24.0, 24.0)
	plus_button.disabled = locked or value >= stat_max or raise_capacity <= 0
	plus_button.tooltip_text = "Punkt vergeben.\n%s" % tooltip
	plus_button.set_meta("help_id", help_id)
	plus_button.pressed.connect(_on_team_editor_stat_delta_pressed.bind(stat_id, TEAM_EDITOR_POINT_DELTA))
	row.add_child(plus_button)
	var lock_button := Button.new()
	lock_button.name = "TeamEditorLock_%s" % stat_id
	lock_button.toggle_mode = true
	lock_button.text = "L"
	lock_button.custom_minimum_size = Vector2(24.0, 24.0)
	lock_button.focus_mode = Control.FOCUS_ALL
	lock_button.set_pressed_no_signal(locked)
	lock_button.tooltip_text = "Diesen Teamfokus sperren, damit Budget-Aenderungen ihn nicht versehentlich veraendern."
	lock_button.set_meta("help_id", "team_editor.stat.lock")
	lock_button.toggled.connect(_on_team_editor_stat_lock_toggled.bind(stat_id))
	row.add_child(lock_button)
	if not effect_text.is_empty():
		var effect_label := Label.new()
		effect_label.name = "TeamEditorStatEffect_%s" % stat_id
		effect_label.text = effect_text
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect_label.modulate = Color(0.72, 0.82, 0.86, 0.92)
		effect_label.add_theme_font_size_override("font_size", 9)
		effect_label.tooltip_text = tooltip
		effect_label.set_meta("help_id", help_id)
		outer.add_child(effect_label)
	_connect_help_controls_in_tree(outer)
	_team_editor_stat_rows[stat_id] = {
		"row": outer,
		"minus": minus_button,
		"plus": plus_button,
		"value": value_label,
		"bar": value_slider,
		"lock": lock_button,
	}
	return outer


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
	var stat_locks: Dictionary = Dictionary(editor.get("stat_locks", {})).duplicate(true)
	var normalized_stat_id: String = stat_id.strip_edges()
	if normalized_stat_id.is_empty() or not allocations.has(normalized_stat_id):
		return {"ok": false, "reason": "unknown_stat", "stat_id": stat_id}
	var current_value: int = int(allocations.get(normalized_stat_id, 0))
	if bool(stat_locks.get(normalized_stat_id, false)) and target_value != current_value:
		if play_sound:
			_play_ui_sfx("warning", "team_editor_stat_locked")
		_refresh_team_editor_focus_controls(editor)
		return {
			"ok": false,
			"changed": false,
			"reason": "locked",
			"stat_id": normalized_stat_id,
			"value": current_value,
		}
	var change: Dictionary = _build_team_editor_focus_allocation_change(editor, allocations, stat_locks, normalized_stat_id, target_value)
	var next_value: int = int(change.get("value", current_value))
	allocations = Dictionary(change.get("allocations", allocations)).duplicate(true)
	editor["stat_allocations"] = allocations
	var save_result: Dictionary = {}
	if _editing_team_editor_roster():
		_team_editor_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_team_editor_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		save_result = _save_team_editor_roster_state("team_editor_stat")
	else:
		_start_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		save_result = _save_start_roster_state("team_editor_stat")
	_refresh_team_editor_focus_controls()
	if play_sound:
		_play_ui_sfx("switch" if next_value != current_value else "warning", "team_editor_stat")
	return {
		"ok": bool(save_result.get("ok", false)),
		"changed": next_value != current_value,
		"stat_id": normalized_stat_id,
		"value": next_value,
		"requested_delta": int(change.get("requested_delta", 0)),
		"applied_delta": int(change.get("applied_delta", 0)),
		"redistributed_points": int(change.get("redistributed_points", 0)),
		"save": save_result,
	}


func _set_team_editor_stat_lock(stat_id: String, locked: bool, play_sound: bool = true) -> Dictionary:
	var editor: Dictionary = _get_normalized_team_editor(false)
	var allocations: Dictionary = Dictionary(editor.get("stat_allocations", {}))
	var normalized_stat_id: String = stat_id.strip_edges()
	if normalized_stat_id.is_empty() or not allocations.has(normalized_stat_id):
		return {"ok": false, "reason": "unknown_stat", "stat_id": stat_id}
	var stat_locks: Dictionary = Dictionary(editor.get("stat_locks", {})).duplicate(true)
	var previous_locked: bool = bool(stat_locks.get(normalized_stat_id, false))
	stat_locks[normalized_stat_id] = locked
	editor["stat_locks"] = stat_locks
	var save_result: Dictionary = {}
	if _editing_team_editor_roster():
		_team_editor_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_team_editor_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		save_result = _save_team_editor_roster_state("team_editor_stat_lock")
	else:
		_start_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
		save_result = _save_start_roster_state("team_editor_stat_lock")
	_refresh_team_editor_focus_controls()
	if play_sound:
		_play_ui_sfx("switch" if previous_locked != locked else "warning", "team_editor_stat_lock")
	return {
		"ok": bool(save_result.get("ok", false)),
		"changed": previous_locked != locked,
		"stat_id": normalized_stat_id,
		"locked": locked,
		"save": save_result,
	}


func _get_team_editor_stat_definition(editor: Dictionary, stat_id: String) -> Dictionary:
	for definition_variant in Array(editor.get("stat_definitions", [])):
		if typeof(definition_variant) != TYPE_DICTIONARY:
			continue
		var definition: Dictionary = Dictionary(definition_variant)
		if String(definition.get("id", "")).strip_edges() == stat_id.strip_edges():
			return definition
	return {
		"id": stat_id,
		"min_value": START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MIN,
		"max_value": START_ROSTER_GENERATOR_SCRIPT.TEAM_EDITOR_STAT_MAX,
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
		var save_result: Dictionary = {}
		if _editing_team_editor_roster():
			_team_editor_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_team_editor_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
			save_result = _save_team_editor_roster_state("team_editor_emblem")
		else:
			_start_roster["team_editor"] = START_ROSTER_GENERATOR_SCRIPT.call("normalize_team_editor", editor, String(_start_roster.get("seed", _start_roster_seed)), _start_roster_profile_id)
			save_result = _save_start_roster_state("team_editor_emblem")
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


func _populate_team_editor_unit_portrait_options(option_button: OptionButton, current_id: String, current_path: String) -> void:
	if option_button == null:
		return
	option_button.clear()
	option_button.add_theme_constant_override("h_separation", 8)
	option_button.add_theme_constant_override("icon_max_width", 30)
	var popup := option_button.get_popup()
	if popup != null:
		popup.add_theme_constant_override("icon_max_width", 30)
	var selected_index: int = -1
	var options: Array = _build_portrait_options(current_id, current_path)
	for option_variant in options:
		var option: Dictionary = Dictionary(option_variant)
		var portrait_id: String = String(option.get("id", "")).strip_edges()
		var portrait_path: String = String(option.get("path", "")).strip_edges()
		var icon: Texture2D = PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("load_texture", portrait_id, portrait_path) as Texture2D
		if icon != null:
			option_button.add_icon_item(icon, String(option.get("label", portrait_id)))
		else:
			option_button.add_item(String(option.get("label", portrait_id)))
		var item_index: int = option_button.item_count - 1
		option_button.set_item_metadata(item_index, option)
		if portrait_id == current_id.strip_edges():
			selected_index = item_index
	if selected_index < 0 and option_button.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		option_button.select(selected_index)


func _build_portrait_options(current_id: String = "", current_path: String = "") -> Array:
	var result: Array = []
	var seen_ids: Dictionary = {}
	var normalized_current_id: String = current_id.strip_edges()
	var normalized_current_path: String = current_path.strip_edges()
	if not normalized_current_id.is_empty():
		result.append({"id": normalized_current_id, "path": normalized_current_path, "label": _format_emblem_label(normalized_current_id)})
		seen_ids[normalized_current_id] = true
	for entry_variant in Array(PORTRAIT_IDENTITY_CATALOG_SCRIPT.call("get_candidate_entries")):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var entry_id: String = String(entry.get("id", "")).strip_edges()
		if entry_id.is_empty() or seen_ids.has(entry_id):
			continue
		result.append({"id": entry_id, "path": String(entry.get("path", "")), "label": _format_emblem_label(entry_id)})
		seen_ids[entry_id] = true
	return result


func _find_portrait_option(portrait_id: String) -> Dictionary:
	var normalized_id: String = portrait_id.strip_edges()
	for option_variant in _build_portrait_options():
		var option: Dictionary = Dictionary(option_variant)
		if String(option.get("id", "")) == normalized_id:
			return option
	return {}


func _format_emblem_label(emblem_id: String) -> String:
	var normalized: String = emblem_id.replace("char_portrait_", "Portrait ").replace("_", " ")
	return normalized.capitalize()


func _load_res_texture(path: String) -> Texture2D:
	var normalized_path: String = path.strip_edges()
	if normalized_path.is_empty():
		return null
	normalized_path = PORTRAIT_IDENTITY_CATALOG_SCRIPT.resolve_legacy_path(normalized_path)
	if not ResourceLoader.exists(normalized_path):
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
	_connect_help_control(_campaign_button, "main_menu.campaign")
	_connect_help_control(_singleplayer_button, "main_menu.primary_routes")
	_connect_help_control(_multiplayer_button, "main_menu.primary_routes")
	_connect_help_control(_editor_button, "main_menu.primary_routes")
	_connect_help_control(_settings_button, "main_menu.primary_routes")
	_connect_help_control(_new_roster_button, "main_menu.primary_routes")
	_connect_help_control(_team_editor_toggle_button, "main_menu.primary_routes")
	_connect_help_control(_team_library_activate_button, "main_menu.primary_routes")
	_connect_help_control(_team_library_edit_button, "main_menu.primary_routes")
	_connect_help_control(_team_library_delete_button, "main_menu.primary_routes")
	_connect_help_control(_team_editor_name_edit, "team_editor.team_name")
	_connect_help_control(_team_editor_emblem_preview, "team_editor.symbol")
	_connect_help_control(_team_editor_emblem_option, "team_editor.symbol")
	_connect_help_control(_team_editor_budget_label, "team_editor.budget")
	_connect_help_control(_team_editor_stats_vbox, "team_editor.budget")
	_connect_help_control(_team_editor_unit_name_edit, "character_sheet.name")
	_connect_help_control(_team_editor_unit_portrait_preview, "character_sheet.portrait")
	_connect_help_control(_team_editor_unit_portrait_option, "character_sheet.portrait")
	_connect_help_control(_team_editor_save_button, "main_menu.primary_routes")
	_connect_help_control(_team_editor_close_button, "main_menu.primary_routes")
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


func _connect_help_controls_in_tree(root_node: Node) -> void:
	if root_node == null:
		return
	if root_node is Control and root_node.has_meta("help_id"):
		var help_id: String = String(root_node.get_meta("help_id", "")).strip_edges()
		if not help_id.is_empty():
			_connect_help_control(root_node as Control, help_id)
	for child in root_node.get_children():
		_connect_help_controls_in_tree(child)


func _order_settings_nodes(action_row: HBoxContainer) -> void:
	var ordered_nodes: Array = [
		_settings_vbox.get_node_or_null("SettingsTitleLabel"),
		_display_section_label,
		_resolution_option,
		_window_mode_option,
		_fullscreen_check,
		_vsync_check,
		_audio_section_label,
		_audio_value_labels.get("Master"),
		_master_volume_slider,
		_audio_value_labels.get("Music"),
		_music_volume_slider,
		_audio_value_labels.get("Sfx"),
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
	_refresh_audio_value_labels(gameplay)
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


func _refresh_audio_value_labels(settings: Dictionary) -> void:
	var channels := {"Master": ["Gesamtlautstärke", "master_volume"], "Music": ["Musik", "music_volume"], "Sfx": ["Effekte", "sfx_volume"]}
	for channel in channels:
		var label := _audio_value_labels.get(channel) as Label
		if label != null:
			var definition: Array = channels[channel]
			label.text = "%s · %d %%" % [definition[0], roundi(float(settings.get(definition[1], 80.0)))]


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
	_stop_help_delay_timers()
	if not _help_hover_is_current(token, help_id, control):
		return
	var compact_delay: float = 0.0 if bool(_help_service.call("is_global_help_active")) else CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_COMPACT_DELAY_SECONDS
	if compact_delay > 0.0:
		if _help_compact_timer != null and _help_compact_timer.is_inside_tree():
			_help_compact_timer.start(compact_delay)
		return
	_show_contextual_help_for(help_id, control, false)
	_start_help_detail_timer(0.0)


func _on_help_compact_timer_timeout() -> void:
	if not _help_hover_is_current(_help_hover_token, _active_help_id, _active_help_control):
		return
	_show_contextual_help_for(_active_help_id, _active_help_control, false)
	_start_help_detail_timer(CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_COMPACT_DELAY_SECONDS)


func _start_help_detail_timer(elapsed_delay: float) -> void:
	if String(_help_service.call("get_help_mode")) != CONTEXTUAL_HELP_SERVICE_SCRIPT.MODE_EXPANDED:
		return
	var detail_delay: float = maxf(0.0, CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_DETAIL_DELAY_SECONDS - elapsed_delay)
	if detail_delay > 0.0:
		if _help_detail_timer != null and _help_detail_timer.is_inside_tree():
			_help_detail_timer.start(detail_delay)


func _on_help_detail_timer_timeout() -> void:
	if _help_hover_is_current(_help_hover_token, _active_help_id, _active_help_control):
		_show_contextual_help_for(_active_help_id, _active_help_control, true)


func _hide_help_after_delay(token: int) -> void:
	_stop_help_delay_timers()
	if _help_hide_timer == null or not _help_hide_timer.is_inside_tree():
		return
	_help_hide_timer.set_meta("help_hover_token", token)
	_help_hide_timer.start(0.15)


func _on_help_hide_timer_timeout() -> void:
	if int(_help_hide_timer.get_meta("help_hover_token", -1)) == _help_hover_token and _contextual_help_popup != null:
		_contextual_help_popup.call("hide_help")


func _stop_help_delay_timers() -> void:
	for timer in [_help_compact_timer, _help_detail_timer, _help_hide_timer]:
		if timer != null and not timer.is_stopped():
			timer.stop()


func _ensure_owned_ui_timers() -> void:
	_team_editor_metric_save_timer = _create_owned_ui_timer("TeamEditorMetricSaveTimer", Callable(self, "_flush_team_editor_metric_save"))
	_help_compact_timer = _create_owned_ui_timer("HelpCompactTimer", Callable(self, "_on_help_compact_timer_timeout"))
	_help_detail_timer = _create_owned_ui_timer("HelpDetailTimer", Callable(self, "_on_help_detail_timer_timeout"))
	_help_hide_timer = _create_owned_ui_timer("HelpHideTimer", Callable(self, "_on_help_hide_timer_timeout"))


func _create_owned_ui_timer(timer_name: String, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.name = timer_name
	timer.one_shot = true
	timer.timeout.connect(callback)
	add_child(timer)
	return timer


func _help_hover_is_current(token: int, help_id: String, control) -> bool:
	if token != _help_hover_token or help_id != _active_help_id:
		return false
	if control == null or not is_instance_valid(control):
		return false
	if _active_help_control == null or not is_instance_valid(_active_help_control):
		_active_help_control = null
		_active_help_id = ""
		return false
	return control == _active_help_control


func _show_contextual_help_for(help_id: String, control: Control, pinned: bool = false) -> void:
	if _help_service == null or _contextual_help_popup == null or control == null:
		return
	var hover_seconds: float = CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_DETAIL_DELAY_SECONDS if pinned else CONTEXTUAL_HELP_SERVICE_SCRIPT.DEFAULT_COMPACT_DELAY_SECONDS
	var payload: Dictionary = Dictionary(_help_service.call("request_help", help_id, hover_seconds, pinned))
	if String(payload.get("level", CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_NONE)) == CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_NONE or payload.is_empty():
		_contextual_help_popup.call("hide_help")
		return
	payload = _merge_control_dynamic_help_payload(payload, control, String(payload.get("level", "")) == CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_DETAIL)
	var target_rect: Rect2 = Rect2(control.global_position, control.size)
	var viewport_size: Vector2 = get_viewport_rect().size
	_contextual_help_popup.call("show_help", payload, target_rect, viewport_size, String(payload.get("level", "")) == CONTEXTUAL_HELP_SERVICE_SCRIPT.LEVEL_DETAIL)


func _merge_control_dynamic_help_payload(payload: Dictionary, control: Control, include_detail: bool) -> Dictionary:
	if control == null:
		return payload
	var result: Dictionary = payload.duplicate(true)
	var control_help_id: String = String(control.get_meta("help_id", "")).strip_edges()
	if String(result.get("help_id", "")).strip_edges().is_empty() and not control_help_id.is_empty():
		result["help_id"] = control_help_id
	var dynamic_title: String = String(control.get_meta("help_dynamic_title", "")).strip_edges()
	if not dynamic_title.is_empty():
		result["title"] = dynamic_title
	var compact_lines: Array = Array(result.get("compact_lines", []))
	for line in _string_array_from_meta(control.get_meta("help_compact_lines", [])):
		if not compact_lines.has(line):
			compact_lines.append(line)
	result["compact_lines"] = compact_lines
	if include_detail:
		var detail_lines: Array = Array(result.get("detail_lines", []))
		for line in _string_array_from_meta(control.get_meta("help_detail_lines", [])):
			if not detail_lines.has(line):
				detail_lines.append(line)
		result["detail_lines"] = detail_lines
	return result


func _string_array_from_meta(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		for entry in value:
			var text: String = String(entry).strip_edges()
			if not text.is_empty():
				result.append(text)
	elif value is Array:
		for entry in Array(value):
			var text: String = String(entry).strip_edges()
			if not text.is_empty():
				result.append(text)
	elif typeof(value) == TYPE_STRING:
		var text: String = String(value).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


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


func _get_global_escape_shell():
	return get_node_or_null(GLOBAL_ESCAPE_MENU_NODE_PATH)


func _on_mission_save_pressed() -> void:
	var shell = _get_global_escape_shell()
	if shell == null or not shell.has_method("save_current_mission_slot"):
		_status_label.text = "Mission save unavailable"
		_play_ui_sfx("warning", "mission_save_unavailable")
		return
	var result: Dictionary = Dictionary(shell.call("save_current_mission_slot"))
	var ok: bool = bool(result.get("ok", false))
	_status_label.text = "Mission gespeichert" if ok else "Keine laufende Mission"
	_play_ui_sfx("confirm" if ok else "warning", "mission_save")
	_refresh_mission_save_load_buttons()


func _on_mission_load_pressed() -> void:
	var shell = _get_global_escape_shell()
	if shell == null or not shell.has_method("load_mission_slot"):
		_status_label.text = "Mission load unavailable"
		_play_ui_sfx("warning", "mission_load_unavailable")
		return
	var result: Dictionary = Dictionary(shell.call("load_mission_slot"))
	if bool(result.get("ok", false)):
		_status_label.text = "Mission laden"
		_play_ui_sfx("confirm", "mission_load")
	else:
		_status_label.text = "Keine Mission gespeichert"
		_play_ui_sfx("warning", "mission_load_missing")
	_refresh_mission_save_load_buttons()


func _ensure_campaign_entry() -> void:
	var menu_buttons: VBoxContainer = _singleplayer_button.get_parent() as VBoxContainer
	_campaign_button = Button.new()
	_campaign_button.name = "CampaignButton"
	_campaign_button.text = "Kampagne"
	_campaign_button.custom_minimum_size = Vector2(360.0, 60.0)
	_campaign_button.tooltip_text = "Einfuehrung mit zwei NPCs und eigenem Kampagnenstand."
	_campaign_button.set_meta("help_id", "main_menu.campaign")
	TACTICAL_UI_THEME_SCRIPT.style_command_button(_campaign_button, "accent")
	menu_buttons.add_child(_campaign_button)
	menu_buttons.move_child(_campaign_button, _singleplayer_button.get_index())
	_campaign_button.pressed.connect(_on_campaign_pressed)
	_campaign_dialog = ConfirmationDialog.new()
	_campaign_dialog.name = "CampaignStartDialog"
	_campaign_dialog.title = "Kampagne"
	_campaign_dialog.dialog_text = "Einfuehrung mit Pilot und einem Leader.\nFortsetzen laedt den letzten sicheren Basis-Meilenstein.\nUnterbrochene Ausfluege werden von dort erneut begonnen."
	_campaign_dialog.ok_button_text = "Neue Kampagne"
	_campaign_dialog.cancel_button_text = "Zurueck"
	add_child(_campaign_dialog)
	_campaign_continue_button = _campaign_dialog.add_button("Fortsetzen", false, "continue")
	_campaign_continue_button.name = "CampaignContinueButton"
	_campaign_dialog.custom_action.connect(_on_campaign_dialog_action)
	_campaign_dialog.confirmed.connect(_on_campaign_new_pressed)
	_campaign_replace_dialog = ConfirmationDialog.new()
	_campaign_replace_dialog.name = "CampaignReplaceDialog"
	_campaign_replace_dialog.title = "Kampagne ersetzen?"
	_campaign_replace_dialog.dialog_text = "Der vorhandene Kampagnenstand wird durch eine neue Kampagne ersetzt."
	_campaign_replace_dialog.ok_button_text = "Kampagne ersetzen"
	_campaign_replace_dialog.cancel_button_text = "Abbrechen"
	add_child(_campaign_replace_dialog)
	_campaign_replace_dialog.confirmed.connect(_start_campaign.bind("new"))


func _load_campaign_checkpoint() -> Dictionary:
	if not ResourceLoader.exists(CAMPAIGN_CHECKPOINT_STORE_PATH):
		return {"ok": false, "reason": "checkpoint_store_unavailable"}
	var store: GDScript = load(CAMPAIGN_CHECKPOINT_STORE_PATH)
	return store.load_checkpoint()


func _campaign_checkpoint_exists() -> bool:
	# Even an invalid existing file must not be replaced without consent.
	return FileAccess.file_exists("user://campaigns/introduction/checkpoint_v1.json") or bool(_load_campaign_checkpoint().get("ok", false))


func _on_campaign_pressed() -> void:
	_campaign_continue_button.disabled = not bool(_load_campaign_checkpoint().get("ok", false))
	_campaign_dialog.popup_centered(Vector2i(620, 240))


func _on_campaign_dialog_action(action: StringName) -> void:
	if action == &"continue":
		_on_campaign_continue_pressed()


func _on_campaign_continue_pressed() -> void:
	# Revalidate on activation: the file may have changed while the dialog was open.
	if not bool(_load_campaign_checkpoint().get("ok", false)):
		_campaign_continue_button.disabled = true
		_status_label.text = "Kein gueltiger Kampagnenstand vorhanden"
		return
	_campaign_dialog.hide()
	_start_campaign("continue")


func _on_campaign_new_pressed() -> void:
	_campaign_dialog.hide()
	if _campaign_checkpoint_exists():
		_campaign_replace_dialog.popup_centered(Vector2i(560, 180))
		return
	_start_campaign("new")


func _start_campaign(action: String) -> void:
	_campaign_dialog.hide()
	_campaign_replace_dialog.hide()
	GAME_START_CONTRACT_SCRIPT.request_start(get_tree(), "campaign", action)
	_play_ui_sfx("confirm", "campaign")
	_change_scene(SINGLEPLAYER_SCENE_PATH)


func _on_singleplayer_pressed() -> void:
	_skirmish_dialog.popup_centered(Vector2i(680, 520))


func _ensure_skirmish_entry() -> void:
	_skirmish_dialog = AcceptDialog.new()
	_skirmish_dialog.name = "SkirmishStartDialog"
	_skirmish_dialog.title = "Skirmish — vorbereiteten Start laden"
	_skirmish_dialog.ok_button_text = "Zurück"
	add_child(_skirmish_dialog)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	_skirmish_dialog.add_child(content)
	var heading := Label.new()
	heading.text = "Offene Ortswahl ohne Kampagnenführung. Jeder Start beginnt frisch."
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size.x = 620
	content.add_child(heading)
	var presets: Dictionary = load("res://scripts/meta/skirmish_start_configuration.gd").get_presets()
	for id: String in ["early", "mid", "late"]:
		var data: Dictionary = presets.get(id, {})
		var button := Button.new()
		button.name = "SkirmishPreset_" + id
		button.text = String(data.get("title", id))
		button.custom_minimum_size.y = 42
		button.tooltip_text = String(data.get("description", ""))
		TACTICAL_UI_THEME_SCRIPT.style_command_button(button, "accent" if id == "early" else "default")
		content.add_child(button)
		button.pressed.connect(_start_skirmish.bind(id))
		var description := Label.new()
		description.text = String(data.get("description", ""))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(description)
	var own := Button.new()
	own.name = "SkirmishOwnTeam"
	own.text = "Mit eigenem gespeicherten Team starten"
	own.custom_minimum_size.y = 42
	content.add_child(own)
	own.pressed.connect(_start_skirmish.bind(""))
	var note := Label.new()
	note.text = "Gespeicherte Teams bleiben erhalten. Fahrzeugtransport, Trägerhangar, Wiederbewaffnung und Medic Bed sind vorgemerkt; derzeit nicht bedienbar."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)


func _start_skirmish(preset_id: String = "") -> void:
	var result: Dictionary = GAME_START_CONTRACT_SCRIPT.request_start(get_tree(), "skirmish", "new", preset_id)
	if not result.get("ok", false): return
	if _skirmish_dialog != null: _skirmish_dialog.hide()
	_play_ui_sfx("confirm", "singleplayer")
	_change_scene(SINGLEPLAYER_SCENE_PATH)


func _on_multiplayer_pressed() -> void:
	GAME_START_CONTRACT_SCRIPT.clear_start(get_tree())
	_play_ui_sfx("confirm", "multiplayer")
	_change_scene(MULTIPLAYER_SCENE_PATH)


func _on_editor_pressed() -> void:
	GAME_START_CONTRACT_SCRIPT.clear_start(get_tree())
	_play_ui_sfx("confirm", "editor")
	_change_scene(EDITOR_SCENE_PATH)


func _on_new_roster_pressed() -> void:
	_play_ui_sfx("confirm" if _start_roster_reset_confirmation_pending else "click", "new_roster")
	if _start_roster_reset_confirmation_pending:
		var result: Dictionary = confirm_new_start_roster()
		if bool(result.get("created", false)):
			open_team_editor(_start_roster_save_path)
	else:
		var result: Dictionary = Dictionary(request_new_start_roster())
		if bool(result.get("created", false)):
			open_team_editor(_start_roster_save_path)


func _on_team_editor_toggle_pressed() -> void:
	toggle_team_editor()
	_status_label.text = "Skirmish-Team-Editor" if _team_editor_open else "Ready"
	_play_ui_sfx("switch", "team_editor_toggle")


func _on_team_editor_close_pressed() -> void:
	close_team_editor()
	_play_ui_sfx("cancel", "team_editor_close")


func _on_team_editor_save_pressed() -> void:
	if _team_editor_metric_save_queued:
		_flush_team_editor_metric_save()
	var save_result: Dictionary = _save_team_editor_roster_state("team_editor_manual_save") if _editing_team_editor_roster() else _save_start_roster_state("team_editor_manual_save")
	_status_label.text = "Team gespeichert" if bool(save_result.get("ok", false)) else "Team speichern fehlgeschlagen"
	_play_ui_sfx("confirm" if bool(save_result.get("ok", false)) else "warning", "team_editor_save")


func _on_team_editor_name_submitted(next_text: String) -> void:
	_set_team_editor_team_name(next_text, true)


func _on_team_editor_name_focus_exited() -> void:
	if _team_editor_name_edit != null:
		_set_team_editor_team_name(_team_editor_name_edit.text, false)


func _set_team_editor_team_name(next_team_name: String, play_sound: bool = true) -> Dictionary:
	if _editing_team_editor_roster():
		_team_editor_roster = Dictionary(TEAM_NAME_GENERATOR_SCRIPT.call("apply_team_name", _team_editor_roster, next_team_name, String(_team_editor_roster.get("seed", "")), int(Dictionary(_team_editor_roster.get("team_identity", {})).get("name_generation_index", 0))))
		var save_result: Dictionary = _save_team_editor_roster_state("team_editor_name")
		_refresh_team_editor()
		if play_sound:
			_play_ui_sfx("confirm" if bool(save_result.get("ok", false)) else "warning", "team_editor_name")
		return {"ok": bool(save_result.get("ok", false)), "roster": _team_editor_roster.duplicate(true), "save": save_result}
	return set_start_team_name(next_team_name)


func _on_team_editor_view_mode_pressed(view_mode: String) -> void:
	_set_team_editor_view_mode(view_mode)
	_play_ui_sfx("switch", "team_editor_view_mode")


func _on_team_editor_unit_card_gui_input(event: InputEvent, unit_id: String) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_team_editor_selected_unit_id = unit_id.strip_edges()
	if mouse_event.double_click:
		_set_team_editor_view_mode(TEAM_EDITOR_VIEW_SHEET)
	else:
		_refresh_team_editor()
	_play_ui_sfx("switch", "team_editor_unit_select")


func _on_team_editor_unit_sheet_button_pressed(unit_id: String) -> void:
	_team_editor_selected_unit_id = unit_id.strip_edges()
	_set_team_editor_view_mode(TEAM_EDITOR_VIEW_SHEET)
	_play_ui_sfx("switch", "team_editor_unit_sheet")


func _on_team_name_edit_submitted(next_text: String) -> void:
	set_start_team_name(next_text)


func _on_team_name_edit_focus_exited() -> void:
	if _team_name_edit != null:
		set_start_team_name(_team_name_edit.text)


func _on_team_name_suggest_pressed() -> void:
	request_start_team_name_suggestion()


func _on_team_library_row_pressed(entry_path: String) -> void:
	_select_team_library_row(entry_path)
	_play_ui_sfx("switch", "team_library_select")


func _on_team_library_row_gui_input(event: InputEvent, entry_path: String) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_select_team_library_row(entry_path)
	if mouse_event.double_click:
		open_team_editor(entry_path)


func _on_team_library_activate_pressed() -> void:
	_activate_selected_team_entry(true)


func _on_team_library_edit_pressed() -> void:
	var selected_entry: Dictionary = _find_team_library_entry(_selected_roster_entry_path)
	if selected_entry.is_empty():
		_play_ui_sfx("warning", "team_library_edit_missing")
		return
	open_team_editor(_selected_roster_entry_path)
	_play_ui_sfx("switch", "team_library_edit")


func _on_team_library_delete_pressed() -> void:
	_delete_selected_team_entry(true)


func _on_team_editor_emblem_selected(index: int) -> void:
	if _team_editor_emblem_option == null or index < 0 or index >= _team_editor_emblem_option.item_count:
		return
	var option: Dictionary = Dictionary(_team_editor_emblem_option.get_item_metadata(index))
	_set_team_editor_emblem(String(option.get("id", "")), true)


func _on_team_editor_stat_delta_pressed(stat_id: String, delta: int) -> void:
	_adjust_team_editor_stat(stat_id, delta, true)


func _on_team_editor_stat_slider_changed(next_value: float, stat_id: String) -> void:
	_set_team_editor_stat(stat_id, roundi(next_value), true)


func _on_team_editor_stat_lock_toggled(locked: bool, stat_id: String) -> void:
	_set_team_editor_stat_lock(stat_id, locked, true)


func _on_team_editor_unit_name_submitted(next_text: String, unit_id: String) -> void:
	_set_team_editor_unit_name(unit_id, next_text, true)


func _on_team_editor_unit_name_focus_exited(unit_id: String, line_edit: LineEdit) -> void:
	if line_edit == null:
		return
	_set_team_editor_unit_name(unit_id, line_edit.text, false)


func _on_team_editor_unit_portrait_selected(index: int, unit_id: String, option_button: OptionButton) -> void:
	if option_button == null or index < 0 or index >= option_button.item_count:
		return
	var option: Dictionary = Dictionary(option_button.get_item_metadata(index))
	_set_team_editor_unit_portrait(unit_id, String(option.get("id", "")), String(option.get("path", "")), true)


func _on_team_editor_profile_metric_changed(profile, row_data: Dictionary, _next_value: float, unit_id: String) -> void:
	_replace_team_editor_unit_from_profile(unit_id, profile, row_data)


func _on_team_editor_profile_metric_lock_changed(row_data: Dictionary, locked: bool, unit_id: String) -> void:
	_set_team_editor_metric_lock(unit_id, row_data, locked)


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
	_refresh_audio_value_labels(_draft_gameplay_settings)
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
	_refresh_audio_value_labels(_draft_gameplay_settings)
	_status_label.text = "Settings changed"


func _on_sfx_volume_changed(value: float) -> void:
	_draft_gameplay_settings["sfx_volume"] = clampf(value, 0.0, 100.0)
	_refresh_audio_value_labels(_draft_gameplay_settings)
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
