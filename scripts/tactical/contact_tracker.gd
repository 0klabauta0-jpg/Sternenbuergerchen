class_name ContactTracker
extends RefCounted

const STATE_UNKNOWN: String = "unknown"
const STATE_SUSPECTED: String = "suspected"
const STATE_SPOTTED: String = "spotted"
const STATE_CONFIRMED: String = "confirmed"
const STATE_LOST: String = "lost"

const CONFIRM_AFTER_LOS_TICKS: int = 2
const MAX_RELAY_DELAY_SECONDS: float = 3.0
const APPROXIMATE_POSITION_GRID_SIZE: float = 64.0
const STALE_REPORT_AFTER_SECONDS: float = 8.0

var _entries_by_key: Dictionary = {}
var _keys_by_fireteam: Dictionary = {}
var _relay_queue_by_key: Dictionary = {}


func reset_all() -> void:
	_entries_by_key.clear()
	_keys_by_fireteam.clear()
	_relay_queue_by_key.clear()


func get_contact_state(fireteam_id: String, enemy_unit_id: String, current_tick: int = -1) -> Dictionary:
	var key: String = _make_entry_key(fireteam_id, enemy_unit_id)
	if key.is_empty():
		return {}
	return _build_public_entry(Dictionary(_entries_by_key.get(key, {})), current_tick)


func get_fireteam_contacts(fireteam_id: String, current_tick: int = -1) -> Array:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return []
	var result: Array = []
	var keys: Array = Array(_keys_by_fireteam.get(normalized_fireteam_id, [])).duplicate()
	keys.sort()
	for key_variant in keys:
		var entry: Dictionary = Dictionary(_entries_by_key.get(String(key_variant), {}))
		var public_entry: Dictionary = _build_public_entry(entry, current_tick)
		if public_entry.is_empty():
			continue
		result.append(public_entry)
	return result


func get_contact_snapshot(current_tick: int = -1) -> Array:
	var result: Array = []
	var keys: Array = _entries_by_key.keys()
	keys.sort()
	for key_variant in keys:
		var public_entry: Dictionary = _build_public_entry(Dictionary(_entries_by_key.get(String(key_variant), {})), current_tick)
		if public_entry.is_empty():
			continue
		result.append(public_entry)
	return result


func update(current_tick: int, contact_observations: Array, known_fireteam_ids: Array, leadership_by_fireteam: Dictionary = {}) -> bool:
	var changed: bool = false
	var observed_keys: Dictionary = {}
	var observations_by_key: Dictionary = {}
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
		var aggregated: Dictionary = observation.duplicate(true)
		if observations_by_key.has(key):
			var previous: Dictionary = observations_by_key[key]
			aggregated["detection_complete"] = bool(previous.get("detection_complete", false)) or bool(observation.get("detection_complete", false))
			if previous.has("contact_report_confidence") or previous.has("confidence") or observation.has("contact_report_confidence") or observation.has("confidence"):
				aggregated["contact_report_confidence"] = maxf(float(previous.get("contact_report_confidence", previous.get("confidence", 0.0))), float(observation.get("contact_report_confidence", observation.get("confidence", 0.0))))
		observations_by_key[key] = aggregated
	var ordered_keys: Array = observations_by_key.keys()
	ordered_keys.sort()
	for key in ordered_keys:
		var observation: Dictionary = observations_by_key[key]
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
	var previous_public: String = JSON.stringify(_build_public_entry(Dictionary(_entries_by_key.get(entry_key, {})), current_tick))
	var entry: Dictionary = Dictionary(_entries_by_key.get(entry_key, {})).duplicate(true)
	var last_seen_tick: int = int(entry.get("last_seen_tick", -999999))
	var los_ticks: int = 1
	var detection_complete: bool = bool(observation.get("detection_complete", false))
	if last_seen_tick == current_tick:
		los_ticks = int(entry.get("los_ticks", 1))
		detection_complete = detection_complete or bool(entry.get("detection_complete_this_tick", false))
	elif last_seen_tick == current_tick - 1:
		los_ticks = int(entry.get("los_ticks", 0)) + 1
	var position: Vector2 = _coerce_vector2(observation.get("last_known_position", observation.get("position", Vector2.ZERO)), Vector2.ZERO)
	var next_state: String = STATE_SPOTTED
	if detection_complete and los_ticks >= CONFIRM_AFTER_LOS_TICKS:
		next_state = STATE_CONFIRMED
	entry["fireteam_id"] = fireteam_id
	entry["unit_id"] = enemy_unit_id
	entry["team_id"] = String(observation.get("team_id", observation.get("enemy_team_id", ""))).strip_edges()
	entry["enemy_type"] = _normalize_enemy_type(String(observation.get("enemy_type", observation.get("role_id", observation.get("enemy_profile_label", "")))))
	entry["last_known_position"] = position
	entry["detection_state"] = next_state
	entry["detected_by"] = _merge_detected_by(Array(entry.get("detected_by", [])), [fireteam_id])
	entry["last_updated_tick"] = current_tick
	entry["last_seen_tick"] = current_tick
	entry["los_ticks"] = los_ticks
	entry["detection_complete_this_tick"] = detection_complete
	if observation.has("confidence") or observation.has("contact_report_confidence"):
		entry["contact_report_confidence_hint"] = clampf(float(observation.get("contact_report_confidence", observation.get("confidence", 0.0))), 0.0, 1.0)
	_store_entry(entry_key, entry)
	if next_state == STATE_CONFIRMED:
		_schedule_confirmed_relays(current_tick, fireteam_id, enemy_unit_id, entry, known_fireteam_ids, leadership_by_fireteam)
	var next_public: String = JSON.stringify(_build_public_entry(entry, current_tick))
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
		_store_entry(key, entry)
		changed = true
	return changed


func _schedule_confirmed_relays(current_tick: int, source_fireteam_id: String, enemy_unit_id: String, entry: Dictionary, known_fireteam_ids: Array, leadership_by_fireteam: Dictionary) -> void:
	var delay_ticks: int = _build_relay_delay_ticks(float(leadership_by_fireteam.get(source_fireteam_id, 0.0)))
	for receiver_variant in known_fireteam_ids:
		var receiver_fireteam_id: String = String(receiver_variant).strip_edges().to_lower()
		if receiver_fireteam_id.is_empty() or receiver_fireteam_id == source_fireteam_id:
			continue
		var relay_key: String = _make_relay_key(source_fireteam_id, receiver_fireteam_id, enemy_unit_id)
		var due_tick: int = current_tick + delay_ticks
		if _relay_queue_by_key.has(relay_key):
			due_tick = mini(due_tick, int(Dictionary(_relay_queue_by_key[relay_key]).get("due_tick", due_tick)))
		_relay_queue_by_key[relay_key] = {
			"source_fireteam_id": source_fireteam_id,
			"receiver_fireteam_id": receiver_fireteam_id,
			"unit_id": enemy_unit_id,
			"team_id": String(entry.get("team_id", "")),
			"enemy_type": _normalize_enemy_type(String(entry.get("enemy_type", ""))),
			"last_known_position": Vector2(entry.get("last_known_position", Vector2.ZERO)),
			"detected_by": Array(entry.get("detected_by", [])).duplicate(true),
			"last_seen_tick": int(entry.get("last_seen_tick", current_tick)),
			"contact_report_confidence_hint": float(entry.get("contact_report_confidence_hint", -1.0)),
			"due_tick": due_tick,
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
		var previous_public: String = JSON.stringify(_build_public_entry(Dictionary(_entries_by_key.get(entry_key, {})), current_tick))
		var entry: Dictionary = Dictionary(_entries_by_key.get(entry_key, {})).duplicate(true)
		var current_state: String = String(entry.get("detection_state", STATE_UNKNOWN))
		if current_state == STATE_SPOTTED or current_state == STATE_CONFIRMED:
			# Direct observations were applied for this tick before relay delivery.
			# Merge provenance without replacing their fresher LOS/position state.
			entry["detected_by"] = _merge_detected_by(Array(entry.get("detected_by", [])), Array(relay.get("detected_by", [])) + [receiver_fireteam_id])
			_store_entry(entry_key, entry)
			if previous_public != JSON.stringify(_build_public_entry(entry, current_tick)):
				changed = true
			continue
		if current_state != STATE_SPOTTED and current_state != STATE_CONFIRMED:
			entry["detection_state"] = STATE_SUSPECTED
		entry["fireteam_id"] = receiver_fireteam_id
		entry["unit_id"] = enemy_unit_id
		entry["team_id"] = String(relay.get("team_id", ""))
		entry["enemy_type"] = _normalize_enemy_type(String(relay.get("enemy_type", "")))
		entry["last_known_position"] = Vector2(relay.get("last_known_position", Vector2.ZERO))
		entry["detected_by"] = _merge_detected_by(Array(entry.get("detected_by", [])), Array(relay.get("detected_by", [])) + [receiver_fireteam_id])
		entry["last_updated_tick"] = current_tick
		entry["last_seen_tick"] = int(relay.get("last_seen_tick", current_tick))
		entry["los_ticks"] = 0
		if float(relay.get("contact_report_confidence_hint", -1.0)) >= 0.0:
			entry["contact_report_confidence_hint"] = clampf(float(relay.get("contact_report_confidence_hint", 0.0)), 0.0, 1.0)
		_store_entry(entry_key, entry)
		var next_public: String = JSON.stringify(_build_public_entry(entry, current_tick))
		if previous_public != next_public:
			changed = true
	for relay_key in delivered_keys:
		_relay_queue_by_key.erase(String(relay_key))
	return changed


func _store_entry(entry_key: String, entry: Dictionary) -> void:
	if entry_key.is_empty():
		return
	var normalized_fireteam_id: String = String(entry.get("fireteam_id", "")).strip_edges().to_lower()
	var previous_entry: Dictionary = Dictionary(_entries_by_key.get(entry_key, {}))
	var previous_fireteam_id: String = String(previous_entry.get("fireteam_id", "")).strip_edges().to_lower()
	if not previous_fireteam_id.is_empty() and previous_fireteam_id != normalized_fireteam_id:
		_remove_fireteam_index_key(previous_fireteam_id, entry_key)
	_entries_by_key[entry_key] = entry
	if normalized_fireteam_id.is_empty():
		return
	var keys: Array = Array(_keys_by_fireteam.get(normalized_fireteam_id, []))
	if not keys.has(entry_key):
		keys.append(entry_key)
		_keys_by_fireteam[normalized_fireteam_id] = keys


func _remove_fireteam_index_key(fireteam_id: String, entry_key: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty() or not _keys_by_fireteam.has(normalized_fireteam_id):
		return
	var keys: Array = Array(_keys_by_fireteam.get(normalized_fireteam_id, []))
	var index: int = keys.find(entry_key)
	if index >= 0:
		keys.remove_at(index)
	if keys.is_empty():
		_keys_by_fireteam.erase(normalized_fireteam_id)
	else:
		_keys_by_fireteam[normalized_fireteam_id] = keys


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


func _build_public_entry(entry: Dictionary, current_tick: int = -1) -> Dictionary:
	if entry.is_empty():
		return {}
	var state: String = String(entry.get("detection_state", STATE_UNKNOWN))
	if state == STATE_UNKNOWN:
		return {}
	var snapshot_tick: int = current_tick
	if snapshot_tick < 0:
		snapshot_tick = int(entry.get("last_updated_tick", entry.get("last_seen_tick", 0)))
	var last_seen_tick: int = int(entry.get("last_seen_tick", entry.get("last_updated_tick", snapshot_tick)))
	var age_ticks: int = maxi(snapshot_tick - last_seen_tick, 0)
	var age_seconds: float = float(age_ticks) / maxf(float(Engine.physics_ticks_per_second), 1.0)
	var enemy_type: String = _normalize_enemy_type(String(entry.get("enemy_type", "")))
	var confidence: float = _build_report_confidence(entry, state, age_seconds)
	var approximate_position: Vector2 = _build_approximate_position(Vector2(entry.get("last_known_position", Vector2.ZERO)), confidence)
	var report_state: String = _build_report_state(state, age_seconds)
	var uncertainty_world: float = _build_position_uncertainty_world(confidence, age_seconds)
	return {
		"fireteam_id": String(entry.get("fireteam_id", "")),
		"unit_id": String(entry.get("unit_id", "")),
		"team_id": String(entry.get("team_id", "")),
		"enemy_type": enemy_type,
		"last_known_position": Vector2(entry.get("last_known_position", Vector2.ZERO)),
		"approximate_position": approximate_position,
		"position_uncertainty_world": uncertainty_world,
		"detection_state": state,
		"report_state": report_state,
		"confidence": confidence,
		"confidence_level": _build_confidence_level(confidence),
		"detected_by": Array(entry.get("detected_by", [])).duplicate(true),
		"last_updated_tick": int(entry.get("last_updated_tick", -1)),
		"last_seen_tick": last_seen_tick,
		"last_seen_age_ticks": age_ticks,
		"last_seen_age_seconds": age_seconds,
		"report_text": _build_report_text(enemy_type, age_seconds, confidence),
		"fow_last_known": report_state != "current",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}


func _build_report_confidence(entry: Dictionary, state: String, age_seconds: float) -> float:
	if float(entry.get("contact_report_confidence_hint", -1.0)) >= 0.0:
		return clampf(float(entry.get("contact_report_confidence_hint", 0.0)) - minf(age_seconds / 30.0, 0.35), 0.05, 1.0)
	var confidence: float = 0.12
	match state.strip_edges().to_lower():
		STATE_CONFIRMED:
			confidence = 0.92
		STATE_SPOTTED:
			confidence = 0.74
		STATE_SUSPECTED:
			confidence = 0.55
		STATE_LOST:
			confidence = 0.48
		_:
			confidence = 0.2
	confidence += minf(float(entry.get("los_ticks", 0)) * 0.025, 0.08)
	confidence -= minf(age_seconds / 24.0, 0.35)
	return clampf(confidence, 0.05, 0.98)


func _build_report_state(state: String, age_seconds: float) -> String:
	var normalized_state: String = state.strip_edges().to_lower()
	if (normalized_state == STATE_SPOTTED or normalized_state == STATE_CONFIRMED) and age_seconds <= 0.25:
		return "current"
	if age_seconds >= STALE_REPORT_AFTER_SECONDS:
		return "stale"
	return "last_known"


func _build_confidence_level(confidence: float) -> String:
	if confidence >= 0.75:
		return "high"
	if confidence >= 0.45:
		return "medium"
	return "low"


func _build_position_uncertainty_world(confidence: float, age_seconds: float) -> float:
	var confidence_penalty: float = lerpf(96.0, 16.0, clampf(confidence, 0.0, 1.0))
	var age_penalty: float = minf(age_seconds * 6.0, 96.0)
	return maxf(12.0, confidence_penalty + age_penalty)


func _build_approximate_position(position: Vector2, confidence: float) -> Vector2:
	if confidence >= 0.75:
		return position
	var grid_size: float = APPROXIMATE_POSITION_GRID_SIZE
	return Vector2(round(position.x / grid_size) * grid_size, round(position.y / grid_size) * grid_size)


func _build_report_text(enemy_type: String, age_seconds: float, confidence: float) -> String:
	return "1 contact, %s, last seen %s, %d%% conf" % [
		enemy_type,
		_format_age_label(age_seconds),
		int(round(clampf(confidence, 0.0, 1.0) * 100.0)),
	]


func _format_age_label(age_seconds: float) -> String:
	if age_seconds < 0.75:
		return "now"
	if age_seconds < 1.5:
		return "1s ago"
	return "%ds ago" % int(round(age_seconds))


func _normalize_enemy_type(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	if normalized.is_empty():
		return "unknown"
	return normalized.replace("_", " ")


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
