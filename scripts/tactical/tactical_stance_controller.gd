class_name TacticalStanceController
extends RefCounted

const STANCE_SYNC_VERSION: int = 1
const STANCE_CAUTIOUS: String = "cautious"
const STANCE_NORMAL: String = "normal"
const STANCE_AGGRESSIVE: String = "aggressive"
const ALLOWED_STANCES: PackedStringArray = [
	STANCE_CAUTIOUS,
	STANCE_NORMAL,
	STANCE_AGGRESSIVE,
]

var _stance_by_fireteam: Dictionary = {}
var _sync_revision: int = 0


func set_requested_stance(fireteam_id: String, next_stance: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return STANCE_NORMAL

	var normalized_stance: String = _normalize_stance(next_stance)
	_set_requested_stance_internal(normalized_fireteam_id, normalized_stance)
	return normalized_stance


func get_requested_stance(fireteam_id: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return STANCE_NORMAL
	return _normalize_stance(String(_stance_by_fireteam.get(normalized_fireteam_id, STANCE_NORMAL)))


func apply_to_fireteams(fireteam_ids: PackedStringArray, next_stance: String) -> int:
	var normalized_stance: String = _normalize_stance(next_stance)
	var applied_count: int = 0
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		_set_requested_stance_internal(fireteam_id, normalized_stance)
		applied_count += 1
	return applied_count


func reset_fireteams(fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	if fireteam_ids.is_empty():
		var had_entries: bool = not _stance_by_fireteam.is_empty()
		_stance_by_fireteam.clear()
		if had_entries:
			_touch_sync_revision()
		return

	var changed: bool = false
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty() or not _stance_by_fireteam.has(fireteam_id):
			continue
		_stance_by_fireteam.erase(fireteam_id)
		changed = true
	if changed:
		_touch_sync_revision()


func get_stance_snapshot() -> Dictionary:
	return _stance_by_fireteam.duplicate(true)


func get_sync_state() -> Dictionary:
	return {
		"version": STANCE_SYNC_VERSION,
		"revision": _sync_revision,
		"stances": get_stance_snapshot(),
	}


func get_sync_revision() -> int:
	return _sync_revision


func load_stance_snapshot(snapshot: Dictionary, available_fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	_replace_snapshot(snapshot, available_fireteam_ids)


func load_sync_state(sync_state: Dictionary, available_fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	var snapshot_variant: Variant = sync_state.get("stances", sync_state.get("tactical_stances", {}))
	var snapshot: Dictionary = Dictionary(snapshot_variant) if typeof(snapshot_variant) == TYPE_DICTIONARY else {}
	var revision: int = maxi(int(sync_state.get("revision", sync_state.get("stance_revision", _sync_revision))), 0)
	_replace_snapshot(snapshot, available_fireteam_ids, revision)


func _normalize_stance(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if ALLOWED_STANCES.has(normalized_value):
		return normalized_value
	return STANCE_NORMAL


func _set_requested_stance_internal(fireteam_id: String, normalized_stance: String) -> bool:
	var previous_stance: String = get_requested_stance(fireteam_id)
	if previous_stance == normalized_stance:
		return false
	if normalized_stance == STANCE_NORMAL:
		_stance_by_fireteam.erase(fireteam_id)
	else:
		_stance_by_fireteam[fireteam_id] = normalized_stance
	_touch_sync_revision()
	return true


func _replace_snapshot(snapshot: Dictionary, available_fireteam_ids: PackedStringArray, incoming_revision: int = -1) -> void:
	if incoming_revision >= 0 and incoming_revision < _sync_revision:
		return
	var sanitized_snapshot: Dictionary = _sanitize_snapshot(snapshot, available_fireteam_ids)
	var changed: bool = not _snapshots_match(_stance_by_fireteam, sanitized_snapshot)
	_stance_by_fireteam = sanitized_snapshot
	if incoming_revision >= 0:
		_sync_revision = incoming_revision
	elif changed:
		_touch_sync_revision()


func _sanitize_snapshot(snapshot: Dictionary, available_fireteam_ids: PackedStringArray) -> Dictionary:
	var sanitized_snapshot: Dictionary = {}
	var available_lookup: Dictionary = {}
	for fireteam_id_variant in available_fireteam_ids:
		var available_fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if available_fireteam_id.is_empty():
			continue
		available_lookup[available_fireteam_id] = true

	var fireteam_ids: Array = snapshot.keys()
	fireteam_ids.sort()
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		if not available_lookup.is_empty() and not available_lookup.has(fireteam_id):
			continue
		var normalized_stance: String = _normalize_stance(String(snapshot.get(fireteam_id_variant, STANCE_NORMAL)))
		if normalized_stance == STANCE_NORMAL:
			continue
		sanitized_snapshot[fireteam_id] = normalized_stance
	return sanitized_snapshot


func _snapshots_match(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size():
		return false
	for fireteam_id in left.keys():
		if String(left.get(fireteam_id, STANCE_NORMAL)) != String(right.get(fireteam_id, STANCE_NORMAL)):
			return false
	return true


func _touch_sync_revision() -> void:
	_sync_revision += 1
