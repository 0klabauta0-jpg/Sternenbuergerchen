class_name TacticalStanceController
extends RefCounted

const STANCE_CAUTIOUS: String = "cautious"
const STANCE_NORMAL: String = "normal"
const STANCE_AGGRESSIVE: String = "aggressive"
const ALLOWED_STANCES: PackedStringArray = [
	STANCE_CAUTIOUS,
	STANCE_NORMAL,
	STANCE_AGGRESSIVE,
]

var _stance_by_fireteam: Dictionary = {}


func set_requested_stance(fireteam_id: String, next_stance: String) -> String:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return STANCE_NORMAL

	var normalized_stance: String = _normalize_stance(next_stance)
	if normalized_stance == STANCE_NORMAL:
		_stance_by_fireteam.erase(normalized_fireteam_id)
	else:
		_stance_by_fireteam[normalized_fireteam_id] = normalized_stance
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
		set_requested_stance(fireteam_id, normalized_stance)
		applied_count += 1
	return applied_count


func reset_fireteams(fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	if fireteam_ids.is_empty():
		_stance_by_fireteam.clear()
		return
	for fireteam_id_variant in fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		_stance_by_fireteam.erase(fireteam_id)


func get_stance_snapshot() -> Dictionary:
	return _stance_by_fireteam.duplicate(true)


func load_stance_snapshot(snapshot: Dictionary, available_fireteam_ids: PackedStringArray = PackedStringArray()) -> void:
	_stance_by_fireteam.clear()
	if snapshot.is_empty():
		return

	var available_lookup: Dictionary = {}
	for fireteam_id_variant in available_fireteam_ids:
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		available_lookup[fireteam_id] = true

	for fireteam_id_variant in snapshot.keys():
		var fireteam_id: String = String(fireteam_id_variant).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		if not available_lookup.is_empty() and not available_lookup.has(fireteam_id):
			continue
		set_requested_stance(fireteam_id, String(snapshot.get(fireteam_id_variant, STANCE_NORMAL)))


func _normalize_stance(value: String) -> String:
	var normalized_value: String = value.strip_edges().to_lower()
	if ALLOWED_STANCES.has(normalized_value):
		return normalized_value
	return STANCE_NORMAL
