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
	result["fog_of_war_enabled"] = String(result.get(KEY_FOG_OF_WAR_MODE, FOW_CONTRACT_SCRIPT.DEFAULT_MODE)) != FOW_CONTRACT_SCRIPT.MODE_OFF
	return result


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
			"rebindable": false,
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
		},
		"valid_fog_of_war_modes": FOW_CONTRACT_SCRIPT.VALID_MODES,
		"default_fog_of_war_mode": FOW_CONTRACT_SCRIPT.DEFAULT_MODE,
		"valid_contextual_help_modes": VALID_CONTEXTUAL_HELP_MODES,
		"default_contextual_help_mode": CONTEXTUAL_HELP_MODE_COMPACT,
	}


static func get_input_action_descriptors() -> Array:
	return [
		{"action": "camera_pan", "label": "Kamera", "prompt": "WASD / Pfeile"},
		{"action": "select", "label": "Auswahl", "prompt": "Linksklick"},
		{"action": "command", "label": "Befehl", "prompt": "Rechtsklick / Buttons"},
		{"action": "show_npc_thoughts", "label": "Thought-Hold", "prompt": "T"},
		{"action": "ui_cancel", "label": "Zurueck", "prompt": "Escape"},
	]


static func _section_for_key(key: String) -> String:
	match key:
		KEY_RESOLUTION_PRESET, KEY_WINDOW_MODE, KEY_VSYNC_ENABLED:
			return DISPLAY_SECTION
		KEY_MASTER_VOLUME, KEY_MUSIC_VOLUME, KEY_SFX_VOLUME, KEY_UI_VOLUME, KEY_COMBAT_VOLUME, KEY_MOVEMENT_VOLUME, KEY_AMBIENT_VOLUME:
			return AUDIO_SECTION
		KEY_FOG_OF_WAR_MODE, KEY_CONTEXTUAL_HELP_MODE:
			return GAMEPLAY_SECTION
		_:
			return GAMEPLAY_SECTION
