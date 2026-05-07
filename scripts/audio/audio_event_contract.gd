class_name AudioEventContract
extends RefCounted

const CATALOG_PATH: String = "res://data/audio_sfx_catalog.json"

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"
const BUS_COMBAT: String = "Combat"
const BUS_MOVEMENT: String = "Movement"
const BUS_AMBIENT: String = "Ambient"

const CATEGORY_UI: String = "ui"
const CATEGORY_COMBAT: String = "combat"
const CATEGORY_MOVEMENT: String = "movement"
const CATEGORY_IMPACT: String = "impact"
const CATEGORY_EXPLOSION: String = "explosion"
const CATEGORY_AMBIENT_SHORT: String = "ambient_short"

const KEY_MASTER_VOLUME: String = "master_volume"
const KEY_MUSIC_VOLUME: String = "music_volume"
const KEY_SFX_VOLUME: String = "sfx_volume"
const KEY_UI_VOLUME: String = "ui_volume"
const KEY_COMBAT_VOLUME: String = "combat_volume"
const KEY_MOVEMENT_VOLUME: String = "movement_volume"
const KEY_AMBIENT_VOLUME: String = "ambient_volume"
const KEY_UI_AUDIO_ENABLED: String = "ui_audio_enabled"
const KEY_UI_CLICKS_ENABLED: String = "ui_clicks_enabled"
const KEY_COMBAT_AUDIO_ENABLED: String = "combat_audio_enabled"
const KEY_MOVEMENT_AUDIO_ENABLED: String = "movement_audio_enabled"
const KEY_AMBIENT_AUDIO_ENABLED: String = "ambient_audio_enabled"
const KEY_BUBBLE_AUDIO_ENABLED: String = "bubble_audio_enabled"
const KEY_THOUGHT_AUDIO_ENABLED: String = "thought_audio_enabled"

const REQUIRED_EVENT_IDS: PackedStringArray = [
	"ui_click",
	"ui_hover",
	"ui_switch",
	"ui_confirm",
	"ui_cancel",
	"ui_warning",
	"combat_blaster",
	"combat_smg_burst",
	"combat_heavy_weapon",
	"combat_sniper_shot",
	"movement_footstep_neutral",
	"movement_footstep_sand_soft",
	"movement_footstep_rock",
	"impact_generic_light",
	"impact_metal_light",
	"explosion_small",
	"explosion_large",
]

var _catalog_path: String = CATALOG_PATH
var _catalog: Dictionary = {}
var _entries_by_audio_id: Dictionary = {}
var _event_audio_ids: Dictionary = {}
var _stream_cache: Dictionary = {}
var _missing_file_ids: PackedStringArray = PackedStringArray()
var _missing_resource_ids: PackedStringArray = PackedStringArray()
var _load_error: String = ""


func load_catalog(path: String = CATALOG_PATH) -> Dictionary:
	_catalog_path = path
	_catalog = {}
	_entries_by_audio_id.clear()
	_event_audio_ids.clear()
	_stream_cache.clear()
	_missing_file_ids.clear()
	_missing_resource_ids.clear()
	_load_error = ""

	var text: String = _read_text(path)
	if text.is_empty():
		_load_error = "catalog_missing_or_empty"
		return build_contract_snapshot()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_load_error = "catalog_invalid_json"
		return build_contract_snapshot()

	_catalog = Dictionary(parsed)
	for entry_variant in Array(_catalog.get("entries", [])):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = _normalize_catalog_entry(Dictionary(entry_variant))
		var audio_id: String = String(entry.get("audio_id", "")).strip_edges()
		var event_id: String = String(entry.get("planned_event", "")).strip_edges()
		if audio_id.is_empty() or event_id.is_empty():
			continue
		_entries_by_audio_id[audio_id] = entry
		var event_ids: Array = Array(_event_audio_ids.get(event_id, []))
		event_ids.append(audio_id)
		_event_audio_ids[event_id] = event_ids
		var path_value: String = String(entry.get("path", ""))
		if not FileAccess.file_exists(path_value):
			_missing_file_ids.append(audio_id)
		if not ResourceLoader.exists(path_value):
			_missing_resource_ids.append(audio_id)
	return build_contract_snapshot()


func has_loaded_catalog() -> bool:
	return not _catalog.is_empty() and _load_error.is_empty()


func get_entry(audio_id: String) -> Dictionary:
	var normalized_id: String = audio_id.strip_edges()
	if not _entries_by_audio_id.has(normalized_id):
		return {}
	return Dictionary(_entries_by_audio_id[normalized_id]).duplicate(true)


func has_audio_id(audio_id: String) -> bool:
	return _entries_by_audio_id.has(audio_id.strip_edges())


func get_audio_ids_for_event(event_id: String) -> Array:
	return Array(_event_audio_ids.get(event_id.strip_edges(), [])).duplicate()


func get_event_ids() -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for event_id_variant in _event_audio_ids.keys():
		ids.append(String(event_id_variant))
	ids.sort()
	return ids


func get_entries() -> Array:
	var entries: Array = []
	for entry_variant in _entries_by_audio_id.values():
		entries.append(Dictionary(entry_variant).duplicate(true))
	return entries


func get_required_bus_names() -> PackedStringArray:
	return PackedStringArray([BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_UI, BUS_COMBAT, BUS_MOVEMENT, BUS_AMBIENT])


func get_bus_parent_name(bus_name: String) -> String:
	match bus_name:
		BUS_UI, BUS_COMBAT, BUS_MOVEMENT, BUS_AMBIENT:
			return BUS_SFX
		BUS_MUSIC, BUS_SFX:
			return BUS_MASTER
		_:
			return ""


func get_bus_for_category(category: String, planned_event: String = "") -> String:
	match normalize_category(category):
		CATEGORY_UI:
			return BUS_UI
		CATEGORY_COMBAT, CATEGORY_IMPACT, CATEGORY_EXPLOSION:
			return BUS_COMBAT
		CATEGORY_MOVEMENT:
			return BUS_MOVEMENT
		CATEGORY_AMBIENT_SHORT:
			return BUS_UI if planned_event.strip_edges().begins_with("ui_") else BUS_AMBIENT
		_:
			return BUS_SFX


func normalize_category(category: String) -> String:
	var normalized: String = category.strip_edges().to_lower()
	match normalized:
		CATEGORY_UI, CATEGORY_COMBAT, CATEGORY_MOVEMENT, CATEGORY_IMPACT, CATEGORY_EXPLOSION, CATEGORY_AMBIENT_SHORT:
			return normalized
		_:
			return CATEGORY_COMBAT


func get_stream(audio_id: String) -> AudioStream:
	var normalized_id: String = audio_id.strip_edges()
	if _stream_cache.has(normalized_id):
		return _stream_cache[normalized_id] as AudioStream
	var entry: Dictionary = get_entry(normalized_id)
	if entry.is_empty():
		return null
	var path: String = String(entry.get("path", ""))
	var stream := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStream
	if stream == null:
		if not _missing_resource_ids.has(normalized_id):
			_missing_resource_ids.append(normalized_id)
		return null
	_stream_cache[normalized_id] = stream
	return stream


func clear_stream_cache_for_tests() -> void:
	_stream_cache.clear()


func normalize_event_context(context: Dictionary = {}) -> Dictionary:
	var result: Dictionary = context.duplicate(true)
	result["read_only_audio_event"] = true
	result["audio_sets_gameplay_state"] = false
	result["mutates_simulation_state"] = false
	result["from_multiplayer_snapshot"] = bool(result.get("from_multiplayer_snapshot", false))
	result["visible_to_local"] = bool(result.get("visible_to_local", result.get("audible_to_local", true)))
	result["team_id"] = String(result.get("team_id", ""))
	result["unit_id"] = String(result.get("unit_id", ""))
	result["visibility_context"] = String(result.get("visibility_context", "local"))
	return result


func build_multiplayer_audio_payload(event_id: String, context: Dictionary = {}) -> Dictionary:
	var payload: Dictionary = normalize_event_context(context)
	payload["event_id"] = event_id.strip_edges()
	payload["from_multiplayer_snapshot"] = true
	payload["network_read_only"] = true
	return payload


func is_event_visible_to_local(context: Dictionary = {}) -> bool:
	var normalized: Dictionary = normalize_event_context(context)
	if not bool(normalized.get("visible_to_local", true)):
		return false
	var visibility_context: String = String(normalized.get("visibility_context", "local")).strip_edges().to_lower()
	return visibility_context != "hidden" and visibility_context != "unseen" and visibility_context != "fog_hidden"


func normalize_audio_settings(settings: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		KEY_MASTER_VOLUME: 80.0,
		KEY_MUSIC_VOLUME: 80.0,
		KEY_SFX_VOLUME: 80.0,
		KEY_UI_VOLUME: 100.0,
		KEY_COMBAT_VOLUME: 100.0,
		KEY_MOVEMENT_VOLUME: 100.0,
		KEY_AMBIENT_VOLUME: 100.0,
		KEY_UI_AUDIO_ENABLED: true,
		KEY_UI_CLICKS_ENABLED: true,
		KEY_COMBAT_AUDIO_ENABLED: true,
		KEY_MOVEMENT_AUDIO_ENABLED: true,
		KEY_AMBIENT_AUDIO_ENABLED: true,
		KEY_BUBBLE_AUDIO_ENABLED: true,
		KEY_THOUGHT_AUDIO_ENABLED: true,
	}
	result.merge(settings, true)
	for key in [KEY_MASTER_VOLUME, KEY_MUSIC_VOLUME, KEY_SFX_VOLUME, KEY_UI_VOLUME, KEY_COMBAT_VOLUME, KEY_MOVEMENT_VOLUME, KEY_AMBIENT_VOLUME]:
		result[key] = clampf(float(result.get(key, 100.0)), 0.0, 100.0)
	for key in [KEY_UI_AUDIO_ENABLED, KEY_UI_CLICKS_ENABLED, KEY_COMBAT_AUDIO_ENABLED, KEY_MOVEMENT_AUDIO_ENABLED, KEY_AMBIENT_AUDIO_ENABLED, KEY_BUBBLE_AUDIO_ENABLED, KEY_THOUGHT_AUDIO_ENABLED]:
		result[key] = bool(result.get(key, true))
	return result


func is_allowed_by_settings(entry: Dictionary, settings: Dictionary = {}, context: Dictionary = {}) -> bool:
	var normalized_settings: Dictionary = normalize_audio_settings(settings)
	if float(normalized_settings.get(KEY_MASTER_VOLUME, 80.0)) <= 0.0:
		return false
	if float(normalized_settings.get(KEY_SFX_VOLUME, 80.0)) <= 0.0:
		return false
	var category: String = normalize_category(String(entry.get("category", "")))
	var event_id: String = String(entry.get("planned_event", ""))
	match category:
		CATEGORY_UI:
			if not bool(normalized_settings.get(KEY_UI_AUDIO_ENABLED, true)):
				return false
			if event_id == "ui_click" and not bool(normalized_settings.get(KEY_UI_CLICKS_ENABLED, true)):
				return false
		CATEGORY_COMBAT, CATEGORY_IMPACT, CATEGORY_EXPLOSION:
			if not bool(normalized_settings.get(KEY_COMBAT_AUDIO_ENABLED, true)):
				return false
		CATEGORY_MOVEMENT:
			if not bool(normalized_settings.get(KEY_MOVEMENT_AUDIO_ENABLED, true)):
				return false
		CATEGORY_AMBIENT_SHORT:
			if not bool(normalized_settings.get(KEY_AMBIENT_AUDIO_ENABLED, true)):
				return false
	var feedback_category: String = String(context.get("feedback_category", "")).strip_edges().to_lower()
	if feedback_category == "comic_bubble" and not bool(normalized_settings.get(KEY_BUBBLE_AUDIO_ENABLED, true)):
		return false
	if feedback_category == "thought_bubble" and not bool(normalized_settings.get(KEY_THOUGHT_AUDIO_ENABLED, true)):
		return false
	return true


func get_bus_volume_percent(bus_name: String, settings: Dictionary = {}) -> float:
	var normalized_settings: Dictionary = normalize_audio_settings(settings)
	match bus_name:
		BUS_MASTER:
			return float(normalized_settings.get(KEY_MASTER_VOLUME, 80.0))
		BUS_MUSIC:
			return float(normalized_settings.get(KEY_MUSIC_VOLUME, 80.0))
		BUS_SFX:
			return float(normalized_settings.get(KEY_SFX_VOLUME, 80.0))
		BUS_UI:
			return float(normalized_settings.get(KEY_UI_VOLUME, 100.0))
		BUS_COMBAT:
			return float(normalized_settings.get(KEY_COMBAT_VOLUME, 100.0))
		BUS_MOVEMENT:
			return float(normalized_settings.get(KEY_MOVEMENT_VOLUME, 100.0))
		BUS_AMBIENT:
			return float(normalized_settings.get(KEY_AMBIENT_VOLUME, 100.0))
		_:
			return 100.0


static func volume_percent_to_db(value: float) -> float:
	var linear_value: float = clampf(value / 100.0, 0.0, 1.0)
	return linear_to_db(max(linear_value, 0.001))


func build_contract_snapshot() -> Dictionary:
	var category_counts: Dictionary = {}
	for entry_variant in _entries_by_audio_id.values():
		var entry: Dictionary = Dictionary(entry_variant)
		var category: String = String(entry.get("category", ""))
		category_counts[category] = int(category_counts.get(category, 0)) + 1
	var required_event_coverage: Dictionary = {}
	for event_id in REQUIRED_EVENT_IDS:
		required_event_coverage[event_id] = _event_audio_ids.has(event_id)
	return {
		"catalog_path": _catalog_path,
		"catalog_id": String(_catalog.get("catalog_id", "")),
		"schema_version": int(_catalog.get("schema_version", 0)),
		"loaded": has_loaded_catalog(),
		"load_error": _load_error,
		"entry_count": _entries_by_audio_id.size(),
		"event_count": _event_audio_ids.size(),
		"event_ids": get_event_ids(),
		"category_counts": category_counts,
		"required_event_coverage": required_event_coverage,
		"missing_file_ids": Array(_missing_file_ids),
		"missing_resource_ids": Array(_missing_resource_ids),
		"required_buses": Array(get_required_bus_names()),
		"read_only_audio_events": true,
		"audio_sets_gameplay_state": false,
	}


func _normalize_catalog_entry(entry: Dictionary) -> Dictionary:
	var result: Dictionary = entry.duplicate(true)
	var category: String = normalize_category(String(result.get("category", "")))
	var planned_event: String = String(result.get("planned_event", "")).strip_edges()
	result["category"] = category
	result["planned_event"] = planned_event
	result["event_id"] = planned_event
	result["bus_name"] = String(result.get("bus_name", get_bus_for_category(category, planned_event)))
	result["spatial"] = bool(result.get("spatial", _default_spatial(category, planned_event)))
	result["ui_only"] = category == CATEGORY_UI or planned_event.begins_with("ui_")
	result["one_shot"] = not bool(result.get("loop", false))
	result["cooldown_msec"] = maxi(int(result.get("cooldown_msec", _default_cooldown_msec(category, planned_event))), 0)
	result["polyphony_limit"] = maxi(int(result.get("polyphony_limit", _default_polyphony_limit(category, planned_event))), 1)
	result["duration_seconds"] = maxf(float(result.get("duration_seconds", 0.0)), 0.0)
	result["default_volume_db"] = clampf(float(result.get("default_volume_db", 0.0)), -60.0, 12.0)
	var pitch_range: Array = Array(result.get("random_pitch_range", [1.0, 1.0]))
	if pitch_range.size() != 2:
		pitch_range = [1.0, 1.0]
	var pitch_min: float = clampf(float(pitch_range[0]), 0.25, 4.0)
	var pitch_max: float = clampf(float(pitch_range[1]), 0.25, 4.0)
	if pitch_min > pitch_max:
		var temp: float = pitch_min
		pitch_min = pitch_max
		pitch_max = temp
	result["random_pitch_range"] = [pitch_min, pitch_max]
	return result


func _default_spatial(category: String, planned_event: String) -> bool:
	if category == CATEGORY_UI or planned_event.begins_with("ui_"):
		return false
	return category != CATEGORY_AMBIENT_SHORT or planned_event.begins_with("dropship_") or planned_event.begins_with("mission_")


func _default_cooldown_msec(category: String, _planned_event: String) -> int:
	match category:
		CATEGORY_UI:
			return 45
		CATEGORY_MOVEMENT:
			return 95
		CATEGORY_EXPLOSION:
			return 220
		CATEGORY_AMBIENT_SHORT:
			return 500
		_:
			return 65


func _default_polyphony_limit(category: String, _planned_event: String) -> int:
	match category:
		CATEGORY_UI:
			return 6
		CATEGORY_MOVEMENT:
			return 8
		CATEGORY_EXPLOSION:
			return 3
		CATEGORY_AMBIENT_SHORT:
			return 2
		_:
			return 10


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text
