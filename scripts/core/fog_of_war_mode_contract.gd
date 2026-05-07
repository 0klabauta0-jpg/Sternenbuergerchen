class_name FogOfWarModeContract
extends RefCounted

const MODE_OFF: String = "off"
const MODE_KNOWN_TERRAIN: String = "known_terrain"
const MODE_UNEXPLORED_BLACKOUT: String = "unexplored_blackout"
const DEFAULT_MODE: String = MODE_KNOWN_TERRAIN
const VALID_MODES: PackedStringArray = [MODE_OFF, MODE_KNOWN_TERRAIN, MODE_UNEXPLORED_BLACKOUT]

const TERRAIN_STATE_VISIBLE: String = "visible"
const TERRAIN_STATE_EXPLORED: String = "explored"
const TERRAIN_STATE_KNOWN: String = "known"
const TERRAIN_STATE_UNKNOWN: String = "unknown"


static func normalize_mode(mode: String) -> String:
	var normalized_mode: String = mode.strip_edges().to_lower()
	if VALID_MODES.has(normalized_mode):
		return normalized_mode
	return DEFAULT_MODE


static func is_valid_mode(mode: String) -> bool:
	return VALID_MODES.has(mode.strip_edges().to_lower())


static func get_default_settings() -> Dictionary:
	return {
		"fog_of_war_mode": DEFAULT_MODE,
		"fog_of_war_enabled": true,
	}


static func normalize_settings(settings: Dictionary = {}) -> Dictionary:
	var result: Dictionary = get_default_settings()
	result.merge(settings, true)
	result["fog_of_war_mode"] = normalize_mode(String(result.get("fog_of_war_mode", DEFAULT_MODE)))
	result["fog_of_war_enabled"] = String(result.get("fog_of_war_mode", DEFAULT_MODE)) != MODE_OFF
	return result


static func normalize_team_state(state: Dictionary = {}) -> Dictionary:
	var mode: String = normalize_mode(String(state.get("mode", DEFAULT_MODE)))
	var team_id: String = String(state.get("team_id", "")).strip_edges()
	var peer_id: int = maxi(int(state.get("peer_id", 0)), 0)
	return {
		"schema_version": 1,
		"team_id": team_id,
		"peer_id": peer_id,
		"mode": mode,
		"terrain_knowledge": {
			"known_all": mode == MODE_OFF or mode == MODE_KNOWN_TERRAIN,
			"explored_tile_ids": _normalize_string_array(state.get("explored_tile_ids", [])),
			"visible_tile_ids": _normalize_string_array(state.get("visible_tile_ids", [])),
			"unknown_policy": _unknown_policy_for_mode(mode),
		},
		"current_visibility": {
			"visible_target_ids": _normalize_string_array(state.get("visible_target_ids", [])),
			"visible_event_ids": _normalize_string_array(state.get("visible_event_ids", [])),
		},
		"last_known_contacts": _normalize_last_known_contacts(state.get("last_known_contacts", [])),
		"authority_boundary": "server_or_singleplayer_simulation_updates_visibility_ui_reads_only",
	}


static func get_contract_snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"default_mode": DEFAULT_MODE,
		"valid_modes": VALID_MODES,
		"modes": {
			MODE_OFF: {
				"terrain": "all_visible",
				"dynamic_visibility": "normal_debug_or_gameplay_rules",
				"unknown_tiles": "none",
			},
			MODE_KNOWN_TERRAIN: {
				"terrain": "all_known_readable",
				"dynamic_visibility": "current_sight_or_last_known_contacts",
				"unknown_tiles": "none",
			},
			MODE_UNEXPLORED_BLACKOUT: {
				"terrain": "current_visible_or_explored_memory",
				"dynamic_visibility": "current_sight_or_last_known_contacts",
				"unknown_tiles": "blackout",
			},
		},
		"separated_state": PackedStringArray(["terrain_knowledge", "current_visibility", "last_known_contacts"]),
		"settings_key": "fog_of_war_mode",
		"multiplayer_boundary": "team_or_peer_scoped_server_authoritative_visibility_no_hidden_enemy_reconstruction",
	}


static func _unknown_policy_for_mode(mode: String) -> String:
	match mode:
		MODE_OFF:
			return "no_unknown_tiles"
		MODE_KNOWN_TERRAIN:
			return "terrain_known_dynamic_hidden"
		MODE_UNEXPLORED_BLACKOUT:
			return "unseen_tiles_black"
		_:
			return "terrain_known_dynamic_hidden"


static func _normalize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if value is PackedStringArray:
		result = PackedStringArray(value)
	elif value is Array:
		for entry_variant in Array(value):
			var entry: String = String(entry_variant).strip_edges()
			if not entry.is_empty():
				result.append(entry)
	result.sort()
	return result


static func _normalize_last_known_contacts(value: Variant) -> Array:
	var result: Array = []
	if not (value is Array):
		return result
	for contact_variant in Array(value):
		if typeof(contact_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(contact_variant)
		var target_id: String = String(source.get("target_id", source.get("unit_id", ""))).strip_edges()
		if target_id.is_empty():
			continue
		var contact: Dictionary = {
			"target_id": target_id,
			"team_id": String(source.get("team_id", "")).strip_edges(),
			"last_seen_tick": maxi(int(source.get("last_seen_tick", 0)), 0),
		}
		var position: Variant = _coerce_position(source.get("last_known_position", source.get("position", null)))
		if position != null:
			contact["last_known_position"] = position
		result.append(contact)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("target_id", "")) < String(b.get("target_id", ""))
	)
	return result


static func _coerce_position(value: Variant) -> Variant:
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null
