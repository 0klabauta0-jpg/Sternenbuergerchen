class_name ComicBubbleSettings
extends RefCounted

const CONFIG_PATH: String = "user://sternenbuergerchen_settings.cfg"
const CONFIG_SECTION: String = "comic_bubbles"

const MODE_OFF: String = "off"
const MODE_MINIMAL: String = "minimal"
const MODE_NORMAL: String = "normal"
const MODE_DEBUG: String = "debug"
const VALID_MODES: PackedStringArray = [MODE_OFF, MODE_MINIMAL, MODE_NORMAL, MODE_DEBUG]

const CATEGORY_FTL_COMMAND_FEEDBACK: String = "ftl_command_feedback"
const CATEGORY_FTL_STATUS_FEEDBACK: String = "ftl_status_feedback"
const CATEGORY_NPC_THOUGHT_PEEK: String = "npc_thought_peek"
const CATEGORY_DEBUG: String = "debug"

const INPUT_SHOW_NPC_THOUGHTS: String = "show_npc_thoughts"
const DEFAULT_COMMAND_FEEDBACK_COOLDOWN_MSEC: int = 650
const DEFAULT_STATUS_FEEDBACK_COOLDOWN_MSEC: int = 1100
const DEFAULT_THOUGHT_FEEDBACK_COOLDOWN_MSEC: int = 250
const DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL: int = 4
const DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT: int = 1
const DEFAULT_MAX_THOUGHT_BUBBLES_TOTAL: int = 4


static func get_default_settings() -> Dictionary:
	return {
		"mode": MODE_NORMAL,
		"enabled": true,
		"ftl_command_feedback_enabled": true,
		"ftl_status_feedback_enabled": true,
		"npc_thought_peek_enabled": true,
		"debug_bubbles_enabled": false,
		"max_active_bubbles_total": DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL,
		"max_active_bubbles_per_unit": DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT,
		"max_thought_bubbles_total": DEFAULT_MAX_THOUGHT_BUBBLES_TOTAL,
		"command_feedback_cooldown_msec": DEFAULT_COMMAND_FEEDBACK_COOLDOWN_MSEC,
		"status_feedback_cooldown_msec": DEFAULT_STATUS_FEEDBACK_COOLDOWN_MSEC,
		"thought_feedback_cooldown_msec": DEFAULT_THOUGHT_FEEDBACK_COOLDOWN_MSEC,
		"thought_peek_hold_action": INPUT_SHOW_NPC_THOUGHTS,
	}


static func normalize_mode(mode: String) -> String:
	var normalized_mode: String = mode.strip_edges().to_lower()
	if VALID_MODES.has(normalized_mode):
		return normalized_mode
	return MODE_NORMAL


static func normalize_settings(raw_settings: Dictionary = {}) -> Dictionary:
	var result: Dictionary = get_default_settings()
	result.merge(raw_settings, true)
	result["mode"] = normalize_mode(String(result.get("mode", MODE_NORMAL)))
	result["enabled"] = String(result.get("mode", MODE_NORMAL)) != MODE_OFF
	result["ftl_command_feedback_enabled"] = bool(result.get("ftl_command_feedback_enabled", true))
	result["ftl_status_feedback_enabled"] = bool(result.get("ftl_status_feedback_enabled", true))
	result["npc_thought_peek_enabled"] = bool(result.get("npc_thought_peek_enabled", true))
	result["debug_bubbles_enabled"] = bool(result.get("debug_bubbles_enabled", false))
	result["max_active_bubbles_total"] = maxi(int(result.get("max_active_bubbles_total", DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL)), 0)
	result["max_active_bubbles_per_unit"] = maxi(int(result.get("max_active_bubbles_per_unit", DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT)), 0)
	result["max_thought_bubbles_total"] = maxi(int(result.get("max_thought_bubbles_total", DEFAULT_MAX_THOUGHT_BUBBLES_TOTAL)), 0)
	result["command_feedback_cooldown_msec"] = maxi(int(result.get("command_feedback_cooldown_msec", DEFAULT_COMMAND_FEEDBACK_COOLDOWN_MSEC)), 0)
	result["status_feedback_cooldown_msec"] = maxi(int(result.get("status_feedback_cooldown_msec", DEFAULT_STATUS_FEEDBACK_COOLDOWN_MSEC)), 0)
	result["thought_feedback_cooldown_msec"] = maxi(int(result.get("thought_feedback_cooldown_msec", DEFAULT_THOUGHT_FEEDBACK_COOLDOWN_MSEC)), 0)
	var hold_action: String = String(result.get("thought_peek_hold_action", INPUT_SHOW_NPC_THOUGHTS)).strip_edges()
	result["thought_peek_hold_action"] = INPUT_SHOW_NPC_THOUGHTS if hold_action.is_empty() else hold_action
	return result


static func load_settings(config_path: String = CONFIG_PATH) -> Dictionary:
	ensure_input_map_actions()
	var settings: Dictionary = get_default_settings()
	var config := ConfigFile.new()
	if config.load(config_path) != OK:
		return normalize_settings(settings)
	for key_variant in settings.keys():
		var key: String = String(key_variant)
		settings[key] = config.get_value(CONFIG_SECTION, key, settings[key])
	return normalize_settings(settings)


static func save_settings(settings: Dictionary, config_path: String = CONFIG_PATH) -> Error:
	ensure_input_map_actions()
	var normalized_settings: Dictionary = normalize_settings(settings)
	var config := ConfigFile.new()
	var load_error: Error = config.load(config_path)
	if load_error != OK and load_error != ERR_FILE_NOT_FOUND:
		return load_error
	for key_variant in normalized_settings.keys():
		var key: String = String(key_variant)
		config.set_value(CONFIG_SECTION, key, normalized_settings[key])
	return config.save(config_path)


static func build_snapshot(settings: Dictionary = {}) -> Dictionary:
	var normalized_settings: Dictionary = normalize_settings(settings)
	return {
		"mode": String(normalized_settings.get("mode", MODE_NORMAL)),
		"enabled": bool(normalized_settings.get("enabled", true)),
		"ftl_command_feedback_enabled": bool(normalized_settings.get("ftl_command_feedback_enabled", true)),
		"ftl_status_feedback_enabled": bool(normalized_settings.get("ftl_status_feedback_enabled", true)),
		"npc_thought_peek_enabled": bool(normalized_settings.get("npc_thought_peek_enabled", true)),
		"debug_bubbles_enabled": bool(normalized_settings.get("debug_bubbles_enabled", false)),
		"max_active_bubbles_total": int(normalized_settings.get("max_active_bubbles_total", DEFAULT_MAX_ACTIVE_BUBBLES_TOTAL)),
		"max_active_bubbles_per_unit": int(normalized_settings.get("max_active_bubbles_per_unit", DEFAULT_MAX_ACTIVE_BUBBLES_PER_UNIT)),
		"max_thought_bubbles_total": int(normalized_settings.get("max_thought_bubbles_total", DEFAULT_MAX_THOUGHT_BUBBLES_TOTAL)),
		"command_feedback_cooldown_msec": int(normalized_settings.get("command_feedback_cooldown_msec", DEFAULT_COMMAND_FEEDBACK_COOLDOWN_MSEC)),
		"thought_peek_hold_action": String(normalized_settings.get("thought_peek_hold_action", INPUT_SHOW_NPC_THOUGHTS)),
		"thought_peek_hold_prompt": get_input_prompt_label(String(normalized_settings.get("thought_peek_hold_action", INPUT_SHOW_NPC_THOUGHTS))),
	}


static func ensure_input_map_actions() -> void:
	if not InputMap.has_action(INPUT_SHOW_NPC_THOUGHTS):
		InputMap.add_action(INPUT_SHOW_NPC_THOUGHTS, 0.2)
	if InputMap.action_get_events(INPUT_SHOW_NPC_THOUGHTS).is_empty():
		var event := InputEventKey.new()
		event.keycode = KEY_V
		InputMap.action_add_event(INPUT_SHOW_NPC_THOUGHTS, event)


static func get_input_prompt_label(action_name: String = INPUT_SHOW_NPC_THOUGHTS) -> String:
	ensure_input_map_actions()
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			return OS.get_keycode_string((event as InputEventKey).keycode)
	return "T"


static func is_important_feedback(payload: Dictionary) -> bool:
	var state: String = String(payload.get("feedback_state", "")).strip_edges().to_lower()
	if ["blocked", "contact", "done", "cover"].has(state):
		return true
	var purpose: String = String(payload.get("purpose", "")).strip_edges().to_lower()
	return purpose == "warning"


static func is_category_allowed(settings: Dictionary, category: String, payload: Dictionary = {}, thought_peek_active: bool = false) -> bool:
	var normalized_settings: Dictionary = normalize_settings(settings)
	var mode: String = String(normalized_settings.get("mode", MODE_NORMAL))
	if mode == MODE_OFF:
		return false
	match category.strip_edges().to_lower():
		CATEGORY_FTL_COMMAND_FEEDBACK:
			if not bool(normalized_settings.get("ftl_command_feedback_enabled", true)):
				return false
			return mode != MODE_MINIMAL or is_important_feedback(payload)
		CATEGORY_FTL_STATUS_FEEDBACK:
			if not bool(normalized_settings.get("ftl_status_feedback_enabled", true)):
				return false
			return mode == MODE_NORMAL or mode == MODE_DEBUG or is_important_feedback(payload)
		CATEGORY_NPC_THOUGHT_PEEK:
			return bool(normalized_settings.get("npc_thought_peek_enabled", true)) and thought_peek_active and (mode == MODE_NORMAL or mode == MODE_DEBUG or mode == MODE_MINIMAL)
		CATEGORY_DEBUG:
			return mode == MODE_DEBUG and bool(normalized_settings.get("debug_bubbles_enabled", false))
		_:
			return mode == MODE_DEBUG
