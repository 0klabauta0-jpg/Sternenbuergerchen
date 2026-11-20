class_name GameSettingsContract
extends RefCounted

const FOW_CONTRACT_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_mode_contract.gd")

const CONFIG_PATH: String = "user://sternenbuergerchen_settings.cfg"
const DISPLAY_SECTION: String = "display"
const AUDIO_SECTION: String = "audio"
const INPUT_SECTION: String = "input"
const GAMEPLAY_SECTION: String = "gameplay"
const KEY_RESOLUTION_PRESET: String = "resolution_preset"
const KEY_WINDOW_MODE: String = "window_mode"
const KEY_VSYNC_ENABLED: String = "vsync_enabled"
const KEY_MASTER_VOLUME: String = "master_volume"
const KEY_MUSIC_VOLUME: String = "music_volume"
const KEY_SFX_VOLUME: String = "sfx_volume"
const KEY_UI_VOLUME: String = "ui_volume"
const KEY_COMBAT_VOLUME: String = "combat_volume"
const KEY_MOVEMENT_VOLUME: String = "movement_volume"
const KEY_AMBIENT_VOLUME: String = "ambient_volume"
const KEY_FOG_OF_WAR_MODE: String = "fog_of_war_mode"
const KEY_CONTEXTUAL_HELP_MODE: String = "contextual_help_mode"
const KEY_CAMPAIGN_RESPAWN_LIMIT: String = "campaign_respawn_limit"
const DEFAULT_CAMPAIGN_RESPAWN_LIMIT: int = 3
const MIN_CAMPAIGN_RESPAWN_LIMIT: int = 0
## Upper bound of the setting. scripts/core/campaign_casualty_rules.gd keeps its own copy (no ui <-> core coupling);
## campaign_respawn_rules_verifier checks that both are equal.
const MAX_CAMPAIGN_RESPAWN_LIMIT: int = 9
const WINDOW_MODE_WINDOWED: String = "windowed"
const WINDOW_MODE_BORDERLESS: String = "borderless"
const WINDOW_MODE_FULLSCREEN: String = "fullscreen"
const CONTEXTUAL_HELP_MODE_OFF: String = "off"
const CONTEXTUAL_HELP_MODE_COMPACT: String = "compact"
const CONTEXTUAL_HELP_MODE_EXPANDED: String = "expanded"
const VALID_WINDOW_MODES: PackedStringArray = [WINDOW_MODE_WINDOWED, WINDOW_MODE_BORDERLESS, WINDOW_MODE_FULLSCREEN]
const RESOLUTION_PRESETS: PackedStringArray = ["1280x720", "1600x900", "1920x1080", "2560x1440"]
const VALID_CONTEXTUAL_HELP_MODES: PackedStringArray = [CONTEXTUAL_HELP_MODE_OFF, CONTEXTUAL_HELP_MODE_COMPACT, CONTEXTUAL_HELP_MODE_EXPANDED]


static func get_default_settings() -> Dictionary:
	return {
		KEY_RESOLUTION_PRESET: "1920x1080",
		KEY_WINDOW_MODE: WINDOW_MODE_WINDOWED,
		KEY_VSYNC_ENABLED: true,
		KEY_MASTER_VOLUME: 80.0,
		KEY_MUSIC_VOLUME: 80.0,
		KEY_SFX_VOLUME: 80.0,
		KEY_UI_VOLUME: 100.0,
		KEY_COMBAT_VOLUME: 100.0,
		KEY_MOVEMENT_VOLUME: 100.0,
		KEY_AMBIENT_VOLUME: 100.0,
		KEY_FOG_OF_WAR_MODE: FOW_CONTRACT_SCRIPT.DEFAULT_MODE,
		KEY_CONTEXTUAL_HELP_MODE: CONTEXTUAL_HELP_MODE_COMPACT,
		KEY_CAMPAIGN_RESPAWN_LIMIT: DEFAULT_CAMPAIGN_RESPAWN_LIMIT,
	}


static func normalize_settings(raw_settings: Dictionary = {}) -> Dictionary:
	var result: Dictionary = get_default_settings()
	for key_variant in result.keys():
		var key: String = String(key_variant)
		if raw_settings.has(key):
			result[key] = raw_settings[key]
	result[KEY_RESOLUTION_PRESET] = normalize_resolution_preset(String(result.get(KEY_RESOLUTION_PRESET, "1920x1080")))
	result[KEY_WINDOW_MODE] = normalize_window_mode(String(result.get(KEY_WINDOW_MODE, WINDOW_MODE_WINDOWED)))
	result[KEY_VSYNC_ENABLED] = bool(result.get(KEY_VSYNC_ENABLED, true))
	result[KEY_MASTER_VOLUME] = clampf(float(result.get(KEY_MASTER_VOLUME, 80.0)), 0.0, 100.0)
	result[KEY_MUSIC_VOLUME] = clampf(float(result.get(KEY_MUSIC_VOLUME, 80.0)), 0.0, 100.0)
	result[KEY_SFX_VOLUME] = clampf(float(result.get(KEY_SFX_VOLUME, 80.0)), 0.0, 100.0)
	result[KEY_UI_VOLUME] = clampf(float(result.get(KEY_UI_VOLUME, 100.0)), 0.0, 100.0)
	result[KEY_COMBAT_VOLUME] = clampf(float(result.get(KEY_COMBAT_VOLUME, 100.0)), 0.0, 100.0)
	result[KEY_MOVEMENT_VOLUME] = clampf(float(result.get(KEY_MOVEMENT_VOLUME, 100.0)), 0.0, 100.0)
	result[KEY_AMBIENT_VOLUME] = clampf(float(result.get(KEY_AMBIENT_VOLUME, 100.0)), 0.0, 100.0)
	result[KEY_FOG_OF_WAR_MODE] = FOW_CONTRACT_SCRIPT.call("normalize_mode", String(result.get(KEY_FOG_OF_WAR_MODE, FOW_CONTRACT_SCRIPT.DEFAULT_MODE)))
	result[KEY_CONTEXTUAL_HELP_MODE] = normalize_contextual_help_mode(String(result.get(KEY_CONTEXTUAL_HELP_MODE, CONTEXTUAL_HELP_MODE_COMPACT)))
	result[KEY_CAMPAIGN_RESPAWN_LIMIT] = normalize_campaign_respawn_limit(result.get(KEY_CAMPAIGN_RESPAWN_LIMIT, DEFAULT_CAMPAIGN_RESPAWN_LIMIT))
	result["fog_of_war_enabled"] = String(result.get(KEY_FOG_OF_WAR_MODE, FOW_CONTRACT_SCRIPT.DEFAULT_MODE)) != FOW_CONTRACT_SCRIPT.MODE_OFF
	return result


## Whole number 0..9. Floats are rounded; anything that is not a finite number (text, null, bool, array, INF, NAN) gives the default.
static func normalize_campaign_respawn_limit(value: Variant) -> int:
	if typeof(value) == TYPE_INT:
		return clampi(int(value), MIN_CAMPAIGN_RESPAWN_LIMIT, MAX_CAMPAIGN_RESPAWN_LIMIT)
	if typeof(value) == TYPE_FLOAT and is_finite(float(value)):
		return roundi(clampf(float(value), float(MIN_CAMPAIGN_RESPAWN_LIMIT), float(MAX_CAMPAIGN_RESPAWN_LIMIT)))
	return DEFAULT_CAMPAIGN_RESPAWN_LIMIT


## Pure reader for game code: the limit inside an already loaded settings dictionary.
static func get_campaign_respawn_limit(settings: Dictionary) -> int:
	return normalize_campaign_respawn_limit(settings.get(KEY_CAMPAIGN_RESPAWN_LIMIT, DEFAULT_CAMPAIGN_RESPAWN_LIMIT))


## Loads the saved settings file and returns the limit (3 for a missing file, missing key or broken value).
static func load_campaign_respawn_limit() -> int:
	return get_campaign_respawn_limit(load_settings())


static func normalize_window_mode(window_mode: String) -> String:
	var normalized_mode: String = window_mode.strip_edges().to_lower()
	if VALID_WINDOW_MODES.has(normalized_mode):
		return normalized_mode
	return WINDOW_MODE_WINDOWED


static func normalize_resolution_preset(resolution_preset: String) -> String:
	var normalized_resolution: String = resolution_preset.strip_edges().to_lower()
	if RESOLUTION_PRESETS.has(normalized_resolution):
		return normalized_resolution
	return "1920x1080"


static func normalize_contextual_help_mode(mode: String) -> String:
	var normalized_mode: String = mode.strip_edges().to_lower()
	if VALID_CONTEXTUAL_HELP_MODES.has(normalized_mode):
		return normalized_mode
	return CONTEXTUAL_HELP_MODE_COMPACT


static func load_settings(config_path: String = CONFIG_PATH) -> Dictionary:
	var settings: Dictionary = get_default_settings()
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return normalize_settings(settings)
	for key_variant in settings.keys():
		var key: String = String(key_variant)
		settings[key] = config.get_value(_section_for_key(key), key, settings[key])
	return normalize_settings(settings)


static func save_settings(settings: Dictionary, config_path: String = CONFIG_PATH) -> Error:
	var normalized_settings: Dictionary = normalize_settings(settings)
	var config := ConfigFile.new()
	var load_error: Error = config.load(config_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error
	for key_variant in normalized_settings.keys():
		var key: String = String(key_variant)
		if key == "fog_of_war_enabled":
			continue
		config.set_value(_section_for_key(key), key, normalized_settings[key])
	return config.save(config_path)


static func build_snapshot(settings: Dictionary = {}) -> Dictionary:
	var normalized_settings: Dictionary = normalize_settings(settings)
	return {
		KEY_RESOLUTION_PRESET: String(normalized_settings.get(KEY_RESOLUTION_PRESET, "1920x1080")),
		KEY_WINDOW_MODE: String(normalized_settings.get(KEY_WINDOW_MODE, WINDOW_MODE_WINDOWED)),
		KEY_VSYNC_ENABLED: bool(normalized_settings.get(KEY_VSYNC_ENABLED, true)),
		KEY_MASTER_VOLUME: float(normalized_settings.get(KEY_MASTER_VOLUME, 80.0)),
		KEY_MUSIC_VOLUME: float(normalized_settings.get(KEY_MUSIC_VOLUME, 80.0)),
		KEY_SFX_VOLUME: float(normalized_settings.get(KEY_SFX_VOLUME, 80.0)),
		KEY_UI_VOLUME: float(normalized_settings.get(KEY_UI_VOLUME, 100.0)),
		KEY_COMBAT_VOLUME: float(normalized_settings.get(KEY_COMBAT_VOLUME, 100.0)),
		KEY_MOVEMENT_VOLUME: float(normalized_settings.get(KEY_MOVEMENT_VOLUME, 100.0)),
		KEY_AMBIENT_VOLUME: float(normalized_settings.get(KEY_AMBIENT_VOLUME, 100.0)),
		KEY_FOG_OF_WAR_MODE: String(normalized_settings.get(KEY_FOG_OF_WAR_MODE, FOW_CONTRACT_SCRIPT.DEFAULT_MODE)),
		KEY_CONTEXTUAL_HELP_MODE: String(normalized_settings.get(KEY_CONTEXTUAL_HELP_MODE, CONTEXTUAL_HELP_MODE_COMPACT)),
		KEY_CAMPAIGN_RESPAWN_LIMIT: int(normalized_settings.get(KEY_CAMPAIGN_RESPAWN_LIMIT, DEFAULT_CAMPAIGN_RESPAWN_LIMIT)),
		"fog_of_war_enabled": bool(normalized_settings.get("fog_of_war_enabled", true)),
		"display": {
			KEY_RESOLUTION_PRESET: String(normalized_settings.get(KEY_RESOLUTION_PRESET, "1920x1080")),
			KEY_WINDOW_MODE: String(normalized_settings.get(KEY_WINDOW_MODE, WINDOW_MODE_WINDOWED)),
			KEY_VSYNC_ENABLED: bool(normalized_settings.get(KEY_VSYNC_ENABLED, true)),
			"resolution_presets": RESOLUTION_PRESETS,
			"valid_window_modes": VALID_WINDOW_MODES,
		},
		"audio": {
			KEY_MASTER_VOLUME: float(normalized_settings.get(KEY_MASTER_VOLUME, 80.0)),
			KEY_MUSIC_VOLUME: float(normalized_settings.get(KEY_MUSIC_VOLUME, 80.0)),
			KEY_SFX_VOLUME: float(normalized_settings.get(KEY_SFX_VOLUME, 80.0)),
			KEY_UI_VOLUME: float(normalized_settings.get(KEY_UI_VOLUME, 100.0)),
			KEY_COMBAT_VOLUME: float(normalized_settings.get(KEY_COMBAT_VOLUME, 100.0)),
			KEY_MOVEMENT_VOLUME: float(normalized_settings.get(KEY_MOVEMENT_VOLUME, 100.0)),
			KEY_AMBIENT_VOLUME: float(normalized_settings.get(KEY_AMBIENT_VOLUME, 100.0)),
		},
		"input": {
			"rebindable": true,
			"actions": get_input_action_descriptors(),
		},
		"gameplay": {
			KEY_FOG_OF_WAR_MODE: String(normalized_settings.get(KEY_FOG_OF_WAR_MODE, FOW_CONTRACT_SCRIPT.DEFAULT_MODE)),
			"fog_of_war_enabled": bool(normalized_settings.get("fog_of_war_enabled", true)),
			"valid_fog_of_war_modes": FOW_CONTRACT_SCRIPT.VALID_MODES,
			"default_fog_of_war_mode": FOW_CONTRACT_SCRIPT.DEFAULT_MODE,
			KEY_CONTEXTUAL_HELP_MODE: String(normalized_settings.get(KEY_CONTEXTUAL_HELP_MODE, CONTEXTUAL_HELP_MODE_COMPACT)),
			"valid_contextual_help_modes": VALID_CONTEXTUAL_HELP_MODES,
			"default_contextual_help_mode": CONTEXTUAL_HELP_MODE_COMPACT,
			KEY_CAMPAIGN_RESPAWN_LIMIT: int(normalized_settings.get(KEY_CAMPAIGN_RESPAWN_LIMIT, DEFAULT_CAMPAIGN_RESPAWN_LIMIT)),
		},
		"valid_fog_of_war_modes": FOW_CONTRACT_SCRIPT.VALID_MODES,
		"default_fog_of_war_mode": FOW_CONTRACT_SCRIPT.DEFAULT_MODE,
		"valid_contextual_help_modes": VALID_CONTEXTUAL_HELP_MODES,
		"default_contextual_help_mode": CONTEXTUAL_HELP_MODE_COMPACT,
	}


static func get_input_action_descriptors() -> Array:
	return [
		{"action": "tactical_camera_pan_up", "label": "Kamera hoch", "prompt": "W / Pfeil hoch"},
		{"action": "tactical_camera_pan_down", "label": "Kamera runter", "prompt": "S / Pfeil runter"},
		{"action": "tactical_camera_pan_left", "label": "Kamera links", "prompt": "A / Pfeil links"},
		{"action": "tactical_camera_pan_right", "label": "Kamera rechts", "prompt": "D / Pfeil rechts"},
		{"action": "tactical_camera_rotate_left", "label": "Kamera drehen links", "prompt": "Q"},
		{"action": "tactical_camera_rotate_right", "label": "Kamera drehen rechts", "prompt": "E"},
		{"action": "tactical_camera_rotate_drag", "label": "Kamera drehen", "prompt": "MMB ziehen"},
		{"action": "tactical_camera_zoom_in", "label": "Kamera zoomen", "prompt": "Mausrad hoch"},
		{"action": "tactical_camera_zoom_out", "label": "Kamera herauszoomen", "prompt": "Mausrad runter"},
		{"action": "tactical_select", "label": "Auswahl", "prompt": "Linksklick / ziehen"},
		{"action": "tactical_select_additive", "label": "Auswahl erweitern", "prompt": "Ctrl + Linksklick"},
		{"action": "tactical_order", "label": "Befehl", "prompt": "Rechtsklick / ziehen"},
		{"action": "tactical_order_append", "label": "Befehl anhaengen", "prompt": "Shift + Rechtsklick"},
		{"action": "tactical_cycle_fireteam_next", "label": "Naechstes Fireteam", "prompt": "Tab"},
		{"action": "tactical_cycle_fireteam_previous", "label": "Vorheriges Fireteam", "prompt": "Shift + Tab"},
		{"action": "tactical_execute_orders", "label": "Orders ausfuehren", "prompt": "G"},
		{"action": "tactical_delete_order", "label": "Order loeschen", "prompt": "Entf"},
		{"action": "tactical_issue_move", "label": "Move", "prompt": "1"},
		{"action": "tactical_issue_defend", "label": "Defend", "prompt": "2"},
		{"action": "tactical_issue_flank", "label": "Flank", "prompt": "3"},
		{"action": "tactical_issue_take", "label": "Take", "prompt": "4"},
		{"action": "tactical_issue_breach", "label": "Breach", "prompt": "B"},
		{"action": "tactical_toggle_fire_sector", "label": "Fire Arc", "prompt": "C"},
		{"action": "tactical_toggle_los", "label": "LOS", "prompt": "L"},
		{"action": "tactical_sort_fireteam", "label": "Fireteam sortieren", "prompt": "T"},
		{"action": "show_npc_thoughts", "label": "Gedanken halten", "prompt": "V halten"},
		{"action": "ui_cancel", "label": "Zurueck", "prompt": "Escape"},
	]


static func _section_for_key(key: String) -> String:
	match key:
		KEY_RESOLUTION_PRESET, KEY_WINDOW_MODE, KEY_VSYNC_ENABLED:
			return DISPLAY_SECTION
		KEY_MASTER_VOLUME, KEY_MUSIC_VOLUME, KEY_SFX_VOLUME, KEY_UI_VOLUME, KEY_COMBAT_VOLUME, KEY_MOVEMENT_VOLUME, KEY_AMBIENT_VOLUME:
			return AUDIO_SECTION
		KEY_FOG_OF_WAR_MODE, KEY_CONTEXTUAL_HELP_MODE, KEY_CAMPAIGN_RESPAWN_LIMIT:
			return GAMEPLAY_SECTION
		_:
			return GAMEPLAY_SECTION
