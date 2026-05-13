class_name ComicBubbleRuntimeGate
extends RefCounted

const SETTINGS_SCRIPT: GDScript = preload("res://scripts/ui/comic_bubble_settings.gd")

var _settings: Dictionary = Dictionary(SETTINGS_SCRIPT.call("get_default_settings"))
var _last_emit_msec_by_key: Dictionary = {}
var _thought_peek_override_enabled: bool = false
var _thought_peek_override_value: bool = false


func load_settings(config_path: String = "") -> void:
	if config_path.strip_edges().is_empty():
		_settings = SETTINGS_SCRIPT.call("load_settings")
	else:
		_settings = SETTINGS_SCRIPT.call("load_settings", config_path)


func set_settings(settings: Dictionary) -> void:
	_settings = SETTINGS_SCRIPT.call("normalize_settings", settings)


func get_settings() -> Dictionary:
	return _settings.duplicate(true)


func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = Dictionary(SETTINGS_SCRIPT.call("build_snapshot", _settings))
	snapshot["thought_peek_active"] = is_thought_peek_active()
	snapshot["cooldown_keys"] = _last_emit_msec_by_key.keys()
	return snapshot


func build_filter_performance_snapshot(payloads: Array, category: String = "", now_msec: int = -1) -> Dictionary:
	var previous_emit_times: Dictionary = _last_emit_msec_by_key.duplicate(true)
	var started_usec: int = Time.get_ticks_usec()
	var filtered_payloads: Array = filter_payloads(payloads, category, now_msec)
	var elapsed_usec: int = Time.get_ticks_usec() - started_usec
	var after_emit_count: int = _last_emit_msec_by_key.size()
	_last_emit_msec_by_key = previous_emit_times
	var settings_snapshot: Dictionary = get_snapshot()
	return {
		"mode": String(settings_snapshot.get("mode", "normal")),
		"enabled": bool(settings_snapshot.get("enabled", true)),
		"category": category,
		"input_count": payloads.size(),
		"emitted_count": filtered_payloads.size(),
		"rejected_count": maxi(payloads.size() - filtered_payloads.size(), 0),
		"max_active_bubbles_total": int(settings_snapshot.get("max_active_bubbles_total", 0)),
		"cooldown_key_count_before": previous_emit_times.size(),
		"cooldown_key_count_after_probe": after_emit_count,
		"cooldown_key_count_restored": _last_emit_msec_by_key.size(),
		"elapsed_usec": elapsed_usec,
		"thought_peek_active": bool(settings_snapshot.get("thought_peek_active", false)),
	}


func reset_runtime_state() -> void:
	_last_emit_msec_by_key.clear()


func set_thought_peek_override(active: bool) -> void:
	_thought_peek_override_enabled = true
	_thought_peek_override_value = active


func clear_thought_peek_override() -> void:
	_thought_peek_override_enabled = false
	_thought_peek_override_value = false


func is_thought_peek_active() -> bool:
	var normalized_settings: Dictionary = Dictionary(SETTINGS_SCRIPT.call("normalize_settings", _settings))
	if String(normalized_settings.get("mode", "normal")) == "off" or not bool(normalized_settings.get("npc_thought_peek_enabled", true)):
		return false
	if _thought_peek_override_enabled:
		return _thought_peek_override_value
	var hold_action: String = String(normalized_settings.get("thought_peek_hold_action", SETTINGS_SCRIPT.INPUT_SHOW_NPC_THOUGHTS))
	SETTINGS_SCRIPT.call("ensure_input_map_actions")
	return InputMap.has_action(hold_action) and Input.is_action_pressed(hold_action)


func should_emit_payload(payload: Dictionary, category: String = "", now_msec: int = -1) -> bool:
	var resolved_category: String = _resolve_category(payload, category)
	var normalized_settings: Dictionary = Dictionary(SETTINGS_SCRIPT.call("normalize_settings", _settings))
	if not bool(SETTINGS_SCRIPT.call("is_category_allowed", normalized_settings, resolved_category, payload, is_thought_peek_active())):
		return false
	if int(normalized_settings.get("max_active_bubbles_total", 0)) <= 0:
		return false
	var timestamp_msec: int = Time.get_ticks_msec() if now_msec < 0 else now_msec
	if not _cooldown_allows(payload, resolved_category, normalized_settings, timestamp_msec):
		return false
	_register_emit(payload, resolved_category, timestamp_msec)
	return true


func filter_payloads(payloads: Array, category: String = "", now_msec: int = -1) -> Array:
	var sorted_payloads: Array = []
	for payload_variant in payloads:
		if typeof(payload_variant) == TYPE_DICTIONARY:
			sorted_payloads.append(Dictionary(payload_variant).duplicate(true))
	sorted_payloads.sort_custom(Callable(self, "_sort_payload_priority_desc"))
	var result: Array = []
	var normalized_settings: Dictionary = Dictionary(SETTINGS_SCRIPT.call("normalize_settings", _settings))
	var max_total: int = maxi(int(normalized_settings.get("max_active_bubbles_total", 0)), 0)
	for payload_variant in sorted_payloads:
		if max_total > 0 and result.size() >= max_total:
			break
		var payload: Dictionary = Dictionary(payload_variant)
		if should_emit_payload(payload, category, now_msec):
			result.append(payload)
	return result


func _cooldown_allows(payload: Dictionary, category: String, settings: Dictionary, now_msec: int) -> bool:
	var cooldown_msec: int = _get_cooldown_msec(category, settings)
	if cooldown_msec <= 0:
		return true
	var key: String = _build_cooldown_key(payload, category)
	if not _last_emit_msec_by_key.has(key):
		return true
	return now_msec - int(_last_emit_msec_by_key.get(key, 0)) >= cooldown_msec


func _register_emit(payload: Dictionary, category: String, now_msec: int) -> void:
	_last_emit_msec_by_key[_build_cooldown_key(payload, category)] = now_msec


func _get_cooldown_msec(category: String, settings: Dictionary) -> int:
	match category:
		SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK:
			return int(settings.get("command_feedback_cooldown_msec", SETTINGS_SCRIPT.DEFAULT_COMMAND_FEEDBACK_COOLDOWN_MSEC))
		SETTINGS_SCRIPT.CATEGORY_FTL_STATUS_FEEDBACK:
			return int(settings.get("status_feedback_cooldown_msec", SETTINGS_SCRIPT.DEFAULT_STATUS_FEEDBACK_COOLDOWN_MSEC))
		SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK:
			return int(settings.get("thought_feedback_cooldown_msec", SETTINGS_SCRIPT.DEFAULT_THOUGHT_FEEDBACK_COOLDOWN_MSEC))
		_:
			return 0


func _build_cooldown_key(payload: Dictionary, category: String) -> String:
	var unit_id: String = String(payload.get("unit_id", "")).strip_edges()
	var fireteam_id: String = String(payload.get("fireteam_id", "")).strip_edges().to_lower()
	var identity: String = unit_id if not unit_id.is_empty() else fireteam_id
	if identity.is_empty():
		identity = String(payload.get("bubble_id", "global")).strip_edges()
	var validation_key: String = String(payload.get("validation_key", "")).strip_edges().to_lower()
	var action_key: String = String(payload.get("feedback_action", payload.get("purpose", ""))).strip_edges()
	if not validation_key.is_empty():
		action_key = "%s:%s" % [action_key, validation_key]
	return "%s:%s:%s" % [category, identity, action_key]


func _resolve_category(payload: Dictionary, fallback_category: String = "") -> String:
	var category: String = fallback_category.strip_edges().to_lower()
	if not category.is_empty():
		return category
	var source: String = String(payload.get("source", "")).strip_edges().to_lower()
	if source == "fireteamleader_command_feedback":
		return SETTINGS_SCRIPT.CATEGORY_FTL_COMMAND_FEEDBACK
	var purpose: String = String(payload.get("purpose", "")).strip_edges().to_lower()
	if purpose == "npc_thought":
		return SETTINGS_SCRIPT.CATEGORY_NPC_THOUGHT_PEEK
	if source == "debug" or purpose == "debug":
		return SETTINGS_SCRIPT.CATEGORY_DEBUG
	return SETTINGS_SCRIPT.CATEGORY_FTL_STATUS_FEEDBACK


func _payload_priority(payload: Dictionary) -> int:
	if payload.has("priority"):
		return int(payload.get("priority", 0))
	var state: String = String(payload.get("feedback_state", "")).strip_edges().to_lower()
	if state == "blocked" and not String(payload.get("validation_key", "")).strip_edges().is_empty():
		return 120
	match state:
		"blocked", "contact":
			return 100
		"done", "cover":
			return 80
		"running":
			return 50
		_:
			return 20


func _sort_payload_priority_desc(a: Dictionary, b: Dictionary) -> bool:
	var a_priority: int = _payload_priority(a)
	var b_priority: int = _payload_priority(b)
	if a_priority != b_priority:
		return a_priority > b_priority
	return String(a.get("bubble_id", "")) < String(b.get("bubble_id", ""))
