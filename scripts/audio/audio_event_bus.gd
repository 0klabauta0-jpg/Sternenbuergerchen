class_name AudioEventBus
extends Node

const AUDIO_EVENT_CONTRACT_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_contract.gd")
const AUDIO_EVENT_PLAYER_POOL_SCRIPT: GDScript = preload("res://scripts/audio/audio_event_player_pool.gd")
const DEFAULT_CATALOG_PATH: String = "res://data/audio_sfx_catalog.json"
const BUS_MASTER: String = "Master"
const BUS_SFX: String = "SFX"
const DEFAULT_DEDUPE_WINDOW_MSEC: int = 650

var contract = AUDIO_EVENT_CONTRACT_SCRIPT.new()
var player_pool = null

var _initialized: bool = false
var _settings: Dictionary = {}
var _last_event_msec: Dictionary = {}
var _last_dedupe_msec: Dictionary = {}
var _round_robin_index_by_event: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _played_count: int = 0
var _played_count_by_category: Dictionary = {}
var _played_count_by_event: Dictionary = {}
var _missing_id_count: int = 0
var _missing_resource_count: int = 0
var _suppressed_cooldown_count: int = 0
var _suppressed_polyphony_count: int = 0
var _suppressed_settings_count: int = 0
var _suppressed_visibility_count: int = 0
var _suppressed_dedupe_count: int = 0
var _suppressed_count_by_reason: Dictionary = {}
var _last_result: Dictionary = {}
var _missing_audio_ids: PackedStringArray = PackedStringArray()


func _ready() -> void:
	if not _initialized:
		initialize()


func initialize(catalog_path: String = DEFAULT_CATALOG_PATH, settings: Dictionary = {}) -> Dictionary:
	_rng.randomize()
	if player_pool == null:
		player_pool = AUDIO_EVENT_PLAYER_POOL_SCRIPT.new()
		player_pool.name = "AudioEventPlayerPool"
		add_child(player_pool)
	contract.load_catalog(catalog_path)
	setup_audio_buses()
	apply_settings(settings)
	_initialized = true
	return get_diagnostic_snapshot()


func setup_audio_buses() -> Dictionary:
	var created_buses: PackedStringArray = PackedStringArray()
	for bus_name in contract.get_required_bus_names():
		if bus_name == BUS_MASTER:
			continue
		if AudioServer.get_bus_index(bus_name) < 0:
			var insert_index: int = AudioServer.get_bus_count()
			AudioServer.add_bus(insert_index)
			AudioServer.set_bus_name(insert_index, bus_name)
			created_buses.append(bus_name)
	for bus_name in contract.get_required_bus_names():
		var parent_name: String = contract.get_bus_parent_name(bus_name)
		if parent_name.is_empty():
			continue
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		if bus_index >= 0 and AudioServer.get_bus_index(parent_name) >= 0:
			AudioServer.set_bus_send(bus_index, parent_name)
	return {
		"created_buses": Array(created_buses),
		"bus_snapshot": _build_bus_snapshot(),
	}


func apply_settings(settings: Dictionary = {}) -> Dictionary:
	_settings = contract.normalize_audio_settings(settings)
	for bus_name in contract.get_required_bus_names():
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var percent: float = contract.get_bus_volume_percent(bus_name, _settings)
		AudioServer.set_bus_volume_db(bus_index, _volume_percent_to_db(percent))
		AudioServer.set_bus_mute(bus_index, percent <= 0.0)
	return _settings.duplicate(true)


func emit_audio_event(event_id: String, context: Dictionary = {}) -> Dictionary:
	if not _initialized:
		initialize()
	var normalized_context: Dictionary = contract.normalize_event_context(context)
	var entry: Dictionary = _resolve_entry(event_id, normalized_context)
	if entry.is_empty():
		return _record_missing_id(event_id, normalized_context)
	if not contract.is_event_visible_to_local(normalized_context):
		return _record_suppressed("visibility", entry, normalized_context)
	if not contract.is_allowed_by_settings(entry, _settings, normalized_context):
		return _record_suppressed("settings", entry, normalized_context)

	var now_msec: int = int(normalized_context.get("now_msec", Time.get_ticks_msec()))
	var event_key: String = String(entry.get("planned_event", event_id))
	var dedupe_key: String = _build_dedupe_key(event_key, normalized_context)
	if not dedupe_key.is_empty():
		var dedupe_window_msec: int = maxi(int(normalized_context.get("dedupe_window_msec", DEFAULT_DEDUPE_WINDOW_MSEC)), 0)
		var last_dedupe_msec: int = int(_last_dedupe_msec.get(dedupe_key, -100000000))
		if dedupe_window_msec > 0 and now_msec - last_dedupe_msec < dedupe_window_msec:
			return _record_suppressed("dedupe", entry, normalized_context)

	var cooldown_msec: int = int(normalized_context.get("cooldown_msec", entry.get("cooldown_msec", 0)))
	var last_msec: int = int(_last_event_msec.get(event_key, -100000000))
	if cooldown_msec > 0 and now_msec - last_msec < cooldown_msec:
		return _record_suppressed("cooldown", entry, normalized_context)

	var polyphony_limit: int = int(normalized_context.get("polyphony_limit", entry.get("polyphony_limit", 1)))
	if player_pool != null and player_pool.get_active_voice_count(event_key) >= polyphony_limit:
		return _record_suppressed("polyphony", entry, normalized_context)

	var audio_id: String = String(entry.get("audio_id", ""))
	var stream: AudioStream = contract.get_stream(audio_id)
	if stream == null:
		return _record_missing_resource(entry, normalized_context)

	var bus_name: String = String(normalized_context.get("bus_name", entry.get("bus_name", BUS_SFX)))
	var volume_db: float = float(entry.get("default_volume_db", 0.0)) + float(normalized_context.get("volume_modifier_db", 0.0))
	var pitch_scale: float = _resolve_pitch_scale(entry, normalized_context)
	var position: Vector3 = _resolve_position(normalized_context)
	var play_result: Dictionary = player_pool.play_stream(stream, entry, bus_name, volume_db, pitch_scale, position)
	if not bool(play_result.get("played", false)):
		return _record_suppressed(String(play_result.get("reason", "pool_limit")), entry, normalized_context)

	_last_event_msec[event_key] = now_msec
	if not dedupe_key.is_empty():
		_last_dedupe_msec[dedupe_key] = now_msec
	_played_count += 1
	var category: String = String(entry.get("category", ""))
	_played_count_by_category[category] = int(_played_count_by_category.get(category, 0)) + 1
	_played_count_by_event[event_key] = int(_played_count_by_event.get(event_key, 0)) + 1
	_last_result = _build_result(true, "played", entry, normalized_context)
	_last_result["bus_name"] = bus_name
	_last_result["volume_db"] = volume_db
	_last_result["pitch_scale"] = pitch_scale
	_last_result["spatial"] = bool(entry.get("spatial", false))
	_last_result["position"] = position
	return _last_result.duplicate(true)


func emit_multiplayer_snapshot_audio_event(snapshot_event: Dictionary) -> Dictionary:
	var context: Dictionary = contract.build_multiplayer_audio_payload(String(snapshot_event.get("event_id", snapshot_event.get("planned_event", ""))), snapshot_event)
	return emit_audio_event(String(context.get("event_id", "")), context)


func emit_ui_action(action_type: String, context: Dictionary = {}) -> Dictionary:
	var normalized_action: String = action_type.strip_edges().to_lower()
	var event_id: String = "ui_click"
	match normalized_action:
		"hover", "focus":
			event_id = "ui_hover"
		"switch", "toggle", "option":
			event_id = "ui_switch"
		"confirm", "apply", "start", "accept", "success":
			event_id = "ui_confirm"
		"cancel", "back", "disconnect", "reject":
			event_id = "ui_cancel"
		"warning", "disabled", "error", "missing":
			event_id = "ui_warning"
		_:
			event_id = "ui_click"
	return emit_audio_event(event_id, _with_event_context_defaults(context, event_id, "ui"))


func emit_weapon_fire(weapon_id: String, context: Dictionary = {}) -> Dictionary:
	var event_id: String = _weapon_id_to_event_id(weapon_id)
	var next_context: Dictionary = _with_event_context_defaults(context, event_id, "combat")
	next_context["weapon_id"] = _normalize_weapon_id(weapon_id)
	return emit_audio_event(event_id, next_context)


func emit_impact(impact_type: String = "", context: Dictionary = {}) -> Dictionary:
	var event_id: String = _impact_type_to_event_id(impact_type)
	return emit_audio_event(event_id, _with_event_context_defaults(context, event_id, "impact"))


func emit_explosion(size: String = "small", context: Dictionary = {}) -> Dictionary:
	var event_id: String = _explosion_size_to_event_id(size)
	return emit_audio_event(event_id, _with_event_context_defaults(context, event_id, "explosion"))


func emit_movement_step(surface_type: String = "", context: Dictionary = {}) -> Dictionary:
	var event_id: String = _surface_type_to_movement_event_id(surface_type)
	var next_context: Dictionary = _with_event_context_defaults(context, event_id, "movement")
	next_context["surface_type"] = surface_type.strip_edges().to_lower()
	return emit_audio_event(event_id, next_context)


func get_diagnostic_snapshot() -> Dictionary:
	var contract_snapshot: Dictionary = contract.build_contract_snapshot()
	var pool_snapshot: Dictionary = player_pool.get_pool_snapshot() if player_pool != null else {}
	return {
		"initialized": _initialized,
		"catalog": contract_snapshot,
		"settings": _settings.duplicate(true),
		"buses": _build_bus_snapshot(),
		"pool": pool_snapshot,
		"played_count": _played_count,
		"played_count_by_category": _played_count_by_category.duplicate(true),
		"played_count_by_event": _played_count_by_event.duplicate(true),
		"missing_id_count": _missing_id_count,
		"missing_resource_count": _missing_resource_count,
		"suppressed_cooldown_count": _suppressed_cooldown_count,
		"suppressed_polyphony_count": _suppressed_polyphony_count,
		"suppressed_settings_count": _suppressed_settings_count,
		"suppressed_visibility_count": _suppressed_visibility_count,
		"suppressed_dedupe_count": _suppressed_dedupe_count,
		"suppressed_count_by_reason": _suppressed_count_by_reason.duplicate(true),
		"missing_audio_ids": Array(_missing_audio_ids),
		"last_result": _last_result.duplicate(true),
		"read_only_audio_events": true,
		"audio_sets_gameplay_state": false,
	}


func stop_all_for_tests() -> void:
	if player_pool != null:
		player_pool.stop_all_for_tests()


func shutdown_for_tests() -> void:
	stop_all_for_tests()
	if contract != null and contract.has_method("clear_stream_cache_for_tests"):
		contract.call("clear_stream_cache_for_tests")


func _resolve_entry(event_id: String, context: Dictionary) -> Dictionary:
	var explicit_audio_id: String = String(context.get("audio_id", "")).strip_edges()
	if not explicit_audio_id.is_empty():
		return contract.get_entry(explicit_audio_id)
	var normalized_event_id: String = event_id.strip_edges()
	if contract.has_audio_id(normalized_event_id):
		return contract.get_entry(normalized_event_id)
	var audio_ids: Array = contract.get_audio_ids_for_event(normalized_event_id)
	if audio_ids.is_empty():
		return {}
	var index: int = int(_round_robin_index_by_event.get(normalized_event_id, 0))
	var audio_id: String = String(audio_ids[index % audio_ids.size()])
	_round_robin_index_by_event[normalized_event_id] = index + 1
	return contract.get_entry(audio_id)


func _resolve_pitch_scale(entry: Dictionary, context: Dictionary) -> float:
	if context.has("pitch_scale"):
		return clampf(float(context.get("pitch_scale", 1.0)), 0.25, 4.0)
	var pitch_range: Array = Array(entry.get("random_pitch_range", [1.0, 1.0]))
	if pitch_range.size() != 2:
		return 1.0
	var pitch_min: float = float(pitch_range[0])
	var pitch_max: float = float(pitch_range[1])
	if is_equal_approx(pitch_min, pitch_max):
		return pitch_min
	return _rng.randf_range(pitch_min, pitch_max)


func _resolve_position(context: Dictionary) -> Vector3:
	var position_variant: Variant = context.get("position", context.get("world_position", Vector3.ZERO))
	if position_variant is Vector3:
		return position_variant
	if position_variant is Vector2:
		var position_2d := position_variant as Vector2
		return Vector3(position_2d.x, 0.0, position_2d.y)
	if typeof(position_variant) == TYPE_DICTIONARY:
		var position_dict: Dictionary = Dictionary(position_variant)
		return Vector3(
			float(position_dict.get("x", 0.0)),
			float(position_dict.get("y", 0.0)),
			float(position_dict.get("z", 0.0))
		)
	return Vector3.ZERO


func _record_missing_id(event_id: String, context: Dictionary) -> Dictionary:
	_missing_id_count += 1
	var normalized_id: String = String(context.get("audio_id", event_id)).strip_edges()
	if not _missing_audio_ids.has(normalized_id):
		_missing_audio_ids.append(normalized_id)
	_last_result = {
		"played": false,
		"reason": "missing_audio_id",
		"event_id": event_id,
		"audio_id": normalized_id,
		"read_only_audio_event": true,
		"mutates_simulation_state": false,
	}
	return _last_result.duplicate(true)


func _record_missing_resource(entry: Dictionary, _context: Dictionary) -> Dictionary:
	_missing_resource_count += 1
	_last_result = _build_result(false, "missing_resource", entry, _context)
	return _last_result.duplicate(true)


func _record_suppressed(reason: String, entry: Dictionary, context: Dictionary) -> Dictionary:
	_suppressed_count_by_reason[reason] = int(_suppressed_count_by_reason.get(reason, 0)) + 1
	match reason:
		"cooldown":
			_suppressed_cooldown_count += 1
		"polyphony", "pool_limit":
			_suppressed_polyphony_count += 1
		"settings":
			_suppressed_settings_count += 1
		"visibility":
			_suppressed_visibility_count += 1
		"dedupe":
			_suppressed_dedupe_count += 1
		_:
			_suppressed_polyphony_count += 1
	_last_result = _build_result(false, "suppressed_%s" % reason, entry, context)
	return _last_result.duplicate(true)


func _build_result(played: bool, reason: String, entry: Dictionary, context: Dictionary) -> Dictionary:
	return {
		"played": played,
		"reason": reason,
		"event_id": String(entry.get("planned_event", context.get("event_id", ""))),
		"audio_id": String(entry.get("audio_id", "")),
		"category": String(entry.get("category", "")),
		"read_only_audio_event": true,
		"audio_sets_gameplay_state": false,
		"mutates_simulation_state": false,
		"from_multiplayer_snapshot": bool(context.get("from_multiplayer_snapshot", false)),
		"team_id": String(context.get("team_id", "")),
		"unit_id": String(context.get("unit_id", "")),
		"dedupe_key": String(context.get("dedupe_key", "")),
	}


func _build_bus_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for bus_name in contract.get_required_bus_names():
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		snapshot[bus_name] = {
			"exists": bus_index >= 0,
			"index": bus_index,
			"send": AudioServer.get_bus_send(bus_index) if bus_index >= 0 else "",
			"volume_db": AudioServer.get_bus_volume_db(bus_index) if bus_index >= 0 else 0.0,
			"muted": AudioServer.is_bus_mute(bus_index) if bus_index >= 0 else false,
		}
	return snapshot


func _volume_percent_to_db(value: float) -> float:
	var linear_value: float = clampf(value / 100.0, 0.0, 1.0)
	return linear_to_db(max(linear_value, 0.001))


func _with_event_context_defaults(context: Dictionary, event_id: String, category: String) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	result["event_id"] = event_id
	result["audio_category"] = category
	return result


func _build_dedupe_key(event_key: String, context: Dictionary) -> String:
	var explicit_key: String = String(context.get("dedupe_key", "")).strip_edges()
	if explicit_key.is_empty():
		return ""
	return "%s:%s" % [event_key, explicit_key]


func _weapon_id_to_event_id(weapon_id: String) -> String:
	match _normalize_weapon_id(weapon_id):
		"smg":
			return "combat_smg_burst"
		"sniper":
			return "combat_sniper_shot"
		"rail_gun", "rocket_launcher", "lmg", "support_lmg":
			return "combat_heavy_weapon"
		_:
			return "combat_blaster"


func _impact_type_to_event_id(impact_type: String) -> String:
	var normalized: String = impact_type.strip_edges().to_lower()
	match normalized:
		"metal_light", "metal":
			return "impact_metal_light"
		"metal_medium":
			return "impact_metal_medium"
		"metal_heavy", "heavy":
			return "impact_metal_heavy"
		_:
			return "impact_generic_light"


func _explosion_size_to_event_id(size: String) -> String:
	match size.strip_edges().to_lower():
		"large", "heavy", "rocket", "rocket_launcher":
			return "explosion_large"
		_:
			return "explosion_small"


func _surface_type_to_movement_event_id(surface_type: String) -> String:
	match surface_type.strip_edges().to_lower():
		"sand", "soft", "snow":
			return "movement_footstep_sand_soft"
		"rock", "stone", "cliff":
			return "movement_footstep_rock"
		_:
			return "movement_footstep_neutral"


func _normalize_weapon_id(weapon_id: String) -> String:
	var normalized: String = weapon_id.strip_edges().to_lower()
	match normalized:
		"special", "sonderwaffe", "lmg", "support_lmg":
			return "rail_gun"
		"panzerfaust", "raketenwerfer":
			return "rocket_launcher"
		"sniper_rifle":
			return "sniper"
		_:
			return normalized
