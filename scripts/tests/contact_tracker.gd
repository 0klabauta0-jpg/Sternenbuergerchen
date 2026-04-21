class_name ContactTracker
extends RefCounted

const STATE_UNKNOWN: String = "unknown"
const STATE_SUSPECTED: String = "suspected"
const STATE_SPOTTED: String = "spotted"
const STATE_CONFIRMED: String = "confirmed"
const STATE_LOST: String = "lost"

const CONFIRM_AFTER_LOS_TICKS: int = 2
const MAX_RELAY_DELAY_SECONDS: float = 3.0

var _entries_by_key: Dictionary = {}
var _relay_queue_by_key: Dictionary = {}


func reset_all() -> void:
	_entries_by_key.clear()
	_relay_queue_by_key.clear()


func get_contact_state(fireteam_id: String, enemy_unit_id: String) -> Dictionary:
	var key: String = _make_entry_key(fireteam_id, enemy_unit_id)
	if key.is_empty():
		return {}
	return _build_public_entry(Dictionary(_entries_by_key.get(key, {})))


func get_fireteam_contacts(fireteam_id: String) -> Array:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return []
	var result: Array = []
	var keys: Array = _entries_by_key.keys()
	keys.sort()
	for key_variant in keys:
		var entry: Dictionary = Dictionary(_entries_by_key.get(String(key_variant), {}))
		if String(entry.get("fireteam_id", "")) != normalized_fireteam_id:
			continue
		var public_entry: Dictionary = _build_public_entry(entry)
		if public_entry.is_empty():
			continue
		result.append(public_entry)
	return result


func get_contact_snapshot() -> Array:
	var result: Array = []
	var keys: Array = _entries_by_key.keys()
	keys.sort()
	for key_variant in keys:
		var public_entry: Dictionary = _build_public_entry(Dictionary(_entries_by_key.get(String(key_variant), {})))
		if public_entry.is_empty():
			continue
		result.append(public_entry)
	return result


func update(current_tick: int, contact_observations: Array, known_fireteam_ids: Array, leadership_by_fireteam: Dictionary = {}) -> bool:
	var changed: bool = false
	var observed_keys: Dictionary = {}
	for observation_variant in contact_observations:
		if typeof(observation_variant) != TYPE_DICTIONARY:
			continue
		var observation: Dictionary = Dictionary(observation_variant)
		var fireteam_id: String = String(observation.get("fireteam_id", "")).strip_edges().to_lower()
		var enemy_unit_id: String = String(observation.get("unit_id", observation.get("enemy_unit_id", ""))).strip_edges()
		if fireteam_id.is_empty() or enemy_unit_id.is_empty():
			continue
		var key: String = _make_entry_key(fireteam_id, enemy_unit_id)
		if key.is_empty():
			continue
		observed_keys[key] = true
		if _apply_observation(current_tick, observation, known_fireteam_ids, leadership_by_fireteam):
			changed = true
	if _mark_stale_visual_contacts_lost(current_tick, observed_keys):
		changed = true
	if _deliver_due_relays(current_tick):
		changed = true
	return changed


func _apply_observation(current_tick: int, observation: Dictionary, known_fireteam_ids: Array, leadership_by_fireteam: Dictionary) -> bool:
	var fireteam_id: String = String(observation.get("fireteam_id", "")).strip_edges().to_lower()
	var enemy_unit_id: String = String(observation.get("unit_id", observation.get("enemy_unit_id", ""))).strip_edges()
	var entry_key: String = _make_entry_key(fireteam_id, enemy_unit_id)
	if entry_key.is_empty():
		return false
	var previous_public: String = JSON.stringify(_build_public_entry(Dictionary(_entries_by_key.get(entry_key, {}))))
	var entry: Dictionary = Dictionary(_entries_by_key.get(entry_key, {})).duplicate(true)
	var last_seen_tick: int = int(entry.get("last_seen_tick", -999999))
	var los_ticks: int = 1
	if last_seen_tick == current_tick - 1:
		los_ticks = int(entry.get("los_ticks", 0)) + 1
	var position: Vector2 = _coerce_vector2(observation.get("last_known_position", observation.get("position", Vector2.ZERO)), Vector2.ZERO)
	var next_state: String = STATE_SPOTTED
	if bool(observation.get("detection_complete", false)) and los_ticks >= CONFIRM_AFTER_LOS_TICKS:
		next_state = STATE_CONFIRMED
	entry["fireteam_id"] = fireteam_id
	entry["unit_id"] = enemy_unit_id
	entry["team_id"] = String(observation.get("team_id", observation.get("enemy_team_id", ""))).strip_edges()
	entry["last_known_position"] = position
	entry["detection_state"] = next_state
	entry["detected_by"] = _merge_detected_by(Array(entry.get("detected_by", [])), [fireteam_id])
	entry["last_updated_tick"] = current_tick
	entry["last_seen_tick"] = current_tick
	entry["los_ticks"] = los_ticks
	_entries_by_key[entry_key] = entry
	if next_state == STATE_CONFIRMED:
		_schedule_confirmed_relays(current_tick, fireteam_id, enemy_unit_id, entry, known_fireteam_ids, leadership_by_fireteam)
	var next_public: String = JSON.stringify(_build_public_entry(entry))
	return previous_public != next_public


func _mark_stale_visual_contacts_lost(current_tick: int, observed_keys: Dictionary) -> bool:
	var changed: bool = false
	for key_variant in _entries_by_key.keys():
		var key: String = String(key_variant)
		if observed_keys.has(key):
			continue
		var entry: Dictionary = Dictionary(_entries_by_key.get(key, {})).duplicate(true)
		var state: String = String(entry.get("detection_state", STATE_UNKNOWN))
		if state != STATE_SPOTTED and state != STATE_CONFIRMED:
			continue
		entry["detection_state"] = STATE_LOST
		entry["los_ticks"] = 0
		entry["last_updated_tick"] = current_tick
		_entries_by_key[key] = entry
		changed = true
	return changed


func _schedule_confirmed_relays(current_tick: int, source_fireteam_id: String, enemy_unit_id: String, entry: Dictionary, known_fireteam_ids: Array, leadership_by_fireteam: Dictionary) -> void:
	var delay_ticks: int = _build_relay_delay_ticks(float(leadership_by_fireteam.get(source_fireteam_id, 0.0)))
	for receiver_variant in known_fireteam_ids:
		var receiver_fireteam_id: String = String(receiver_variant).strip_edges().to_lower()
		if receiver_fireteam_id.is_empty() or receiver_fireteam_id == source_fireteam_id:
			continue
		var relay_key: String = _make_relay_key(source_fireteam_id, receiver_fireteam_id, enemy_unit_id)
		_relay_queue_by_key[relay_key] = {
			"source_fireteam_id": source_fireteam_id,
			"receiver_fireteam_id": receiver_fireteam_id,
			"unit_id": enemy_unit_id,
			"team_id": String(entry.get("team_id", "")),
			"last_known_position": Vector2(entry.get("last_known_position", Vector2.ZERO)),
			"detected_by": Array(entry.get("detected_by", [])).duplicate(true),
			"due_tick": current_tick + delay_ticks,
		}


func _deliver_due_relays(current_tick: int) -> bool:
	var changed: bool = false
	var delivered_keys: Array = []
	for relay_key_variant in _relay_queue_by_key.keys():
		var relay_key: String = String(relay_key_variant)
		var relay: Dictionary = Dictionary(_relay_queue_by_key.get(relay_key, {}))
		if relay.is_empty() or int(relay.get("due_tick", current_tick + 1)) > current_tick:
			continue
		delivered_keys.append(relay_key)
		var receiver_fireteam_id: String = String(relay.get("receiver_fireteam_id", "")).strip_edges().to_lower()
		var enemy_unit_id: String = String(relay.get("unit_id", "")).strip_edges()
		var entry_key: String = _make_entry_key(receiver_fireteam_id, enemy_unit_id)
		if entry_key.is_empty():
			continue
		var previous_public: String = JSON.stringify(_build_public_entry(Dictionary(_entries_by_key.get(entry_key, {}))))
		var entry: Dictionary = Dictionary(_entries_by_key.get(entry_key, {})).duplicate(true)
		var current_state: String = String(entry.get("detection_state", STATE_UNKNOWN))
		if current_state != STATE_SPOTTED and current_state != STATE_CONFIRMED:
			entry["detection_state"] = STATE_SUSPECTED
		entry["fireteam_id"] = receiver_fireteam_id
		entry["unit_id"] = enemy_unit_id
		entry["team_id"] = String(relay.get("team_id", ""))
		entry["last_known_position"] = Vector2(relay.get("last_known_position", Vector2.ZERO))
		entry["detected_by"] = _merge_detected_by(Array(entry.get("detected_by", [])), Array(relay.get("detected_by", [])) + [receiver_fireteam_id])
		entry["last_updated_tick"] = current_tick
		entry["los_ticks"] = 0
		_entries_by_key[entry_key] = entry
		var next_public: String = JSON.stringify(_build_public_entry(entry))
		if previous_public != next_public:
			changed = true
	for relay_key in delivered_keys:
		_relay_queue_by_key.erase(String(relay_key))
	return changed


func _build_relay_delay_ticks(source_leadership: float) -> int:
	var scaled_leadership: float = clampf(source_leadership, 0.0, 1.0) * 100.0
	var delay_seconds: float = maxf(0.0, MAX_RELAY_DELAY_SECONDS - (scaled_leadership / 30.0))
	return int(ceil(delay_seconds * float(Engine.physics_ticks_per_second)))


func _merge_detected_by(existing: Array, additions: Array) -> Array:
	var merged: Dictionary = {}
	for fireteam_id_variant in existing + additions:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		merged[fireteam_id] = true
	var result: Array = merged.keys()
	result.sort()
	return result


func _build_public_entry(entry: Dictionary) -> Dictionary:
	if entry.is_empty():
		return {}
	var state: String = String(entry.get("detection_state", STATE_UNKNOWN))
	if state == STATE_UNKNOWN:
		return {}
	return {
		"fireteam_id": String(entry.get("fireteam_id", "")),
		"unit_id": String(entry.get("unit_id", "")),
		"team_id": String(entry.get("team_id", "")),
		"last_known_position": Vector2(entry.get("last_known_position", Vector2.ZERO)),
		"detection_state": state,
		"detected_by": Array(entry.get("detected_by", [])).duplicate(true),
		"last_updated_tick": int(entry.get("last_updated_tick", -1)),
	}


func _make_entry_key(fireteam_id: String, enemy_unit_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	var normalized_enemy_unit_id: String = enemy_unit_id.strip_edges()
	if normalized_fireteam_id.is_empty() or normalized_enemy_unit_id.is_empty():
		return ""
	return "%s:%s" % [normalized_fireteam_id, normalized_enemy_unit_id]


func _make_relay_key(source_fireteam_id: String, receiver_fireteam_id: String, enemy_unit_id: String) -> String:
	return "%s:%s:%s" % [source_fireteam_id.strip_edges().to_lower(), receiver_fireteam_id.strip_edges().to_lower(), enemy_unit_id.strip_edges()]


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Vector2i:
		return Vector2(value.x, value.y)
	if typeof(value) == TYPE_DICTIONARY:
		var value_dict: Dictionary = value
		return Vector2(float(value_dict.get("x", fallback.x)), float(value_dict.get("y", fallback.y)))
	return fallback
