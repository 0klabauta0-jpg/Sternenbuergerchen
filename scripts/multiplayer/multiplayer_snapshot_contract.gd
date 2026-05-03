class_name MultiplayerSnapshotContract
extends RefCounted

const SCHEMA_VERSION: int = 1
const SNAPSHOT_TYPE_STATE: String = "state"
const TRANSFER_STATE_SNAPSHOT: String = "unreliable_ordered"
const TRANSFER_VITAL_DELTA: String = "reliable"
const TRANSFER_MISSION_RESULT: String = "reliable"
const TRANSFER_START_LOAD: String = "reliable"


func build_state_snapshot(data: Dictionary) -> Dictionary:
	var snapshot: Dictionary = {
		"schema_version": SCHEMA_VERSION,
		"snapshot_type": SNAPSHOT_TYPE_STATE,
		"transfer_mode": TRANSFER_STATE_SNAPSHOT,
		"tick": maxi(int(data.get("tick", 0)), 0),
		"units": _normalize_unit_snapshots(data.get("units", [])),
		"vital_updates": _normalize_vital_updates(data.get("vital_updates", [])),
		"objective": _normalize_objective(data.get("objective", {})),
		"dropship": _normalize_dropship(data.get("dropship", {})),
		"contacts": _normalize_contacts(data.get("contacts", [])),
		"mission_result": _normalize_mission_result(data.get("mission_result", {})),
	}
	return snapshot


func validate_for_apply(snapshot: Dictionary, last_applied_tick: int) -> Dictionary:
	if typeof(snapshot) != TYPE_DICTIONARY:
		return _reject("snapshot_not_dictionary")

	var normalized_snapshot: Dictionary = build_state_snapshot(snapshot)
	var tick: int = int(normalized_snapshot.get("tick", 0))
	if tick <= last_applied_tick:
		return {
			"accepted": false,
			"reason": "out_of_order_snapshot",
			"tick": tick,
			"last_applied_tick": last_applied_tick,
		}

	return {
		"accepted": true,
		"reason": "",
		"tick": tick,
		"snapshot": normalized_snapshot,
	}


func normalize_display_context(context: Dictionary) -> Dictionary:
	return {
		"dropship": _normalize_dropship(context.get("dropship", {})),
		"contacts": _normalize_contacts(context.get("contacts", [])),
		"mission_result": _normalize_mission_result(context.get("mission_result", {})),
	}


func get_transfer_contract() -> Dictionary:
	return {
		"state_snapshot": {
			"rpc": "_receive_tick_state",
			"mode": TRANSFER_STATE_SNAPSHOT,
			"purpose": "frequent unit/runtime/objective display state",
		},
		"vital_delta": {
			"rpc": "_receive_vital_state_updates",
			"mode": TRANSFER_VITAL_DELTA,
			"purpose": "reliable vital special cases",
		},
		"mission_result": {
			"mode": TRANSFER_MISSION_RESULT,
			"purpose": "mission end/debrief state",
		},
		"start_load": {
			"mode": TRANSFER_START_LOAD,
			"purpose": "mission start and load handoff",
		},
	}


func _normalize_unit_snapshots(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		var unit_snapshot: Dictionary = {
			"unit_id": unit_id,
			"visible": bool(entry.get("visible", true)),
		}
		var position: Variant = _coerce_position(entry.get("position", null))
		if position != null:
			unit_snapshot["position"] = position
		_copy_string_if_present(entry, unit_snapshot, "runtime_state")
		_copy_string_if_present(entry, unit_snapshot, "fire_mode")
		_copy_string_if_present(entry, unit_snapshot, "vital_state")
		_copy_string_if_present(entry, unit_snapshot, "tactical_stance")
		_copy_string_if_present(entry, unit_snapshot, "fireteam_id")
		_copy_int_if_present(entry, unit_snapshot, "health")
		_copy_int_if_present(entry, unit_snapshot, "bleedout_ticks")
		_copy_int_if_present(entry, unit_snapshot, "tactical_stance_revision")
		result.append(unit_snapshot)
	return result


func _normalize_vital_updates(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		var unit_id: String = String(entry.get("unit_id", "")).strip_edges()
		if unit_id.is_empty():
			continue
		var vital_update: Dictionary = {
			"unit_id": unit_id,
			"vital_state": String(entry.get("vital_state", "")).strip_edges(),
			"health": maxi(int(entry.get("health", 0)), 0),
			"bleedout_ticks": maxi(int(entry.get("bleedout_ticks", 0)), 0),
		}
		result.append(vital_update)
	return result


func _normalize_objective(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = Dictionary(value)
	if source.is_empty():
		return {}
	var objective: Dictionary = {
		"owning_team_id": String(source.get("owning_team_id", "")).strip_edges(),
		"capture_progress": clampf(float(source.get("capture_progress", 0.0)), 0.0, 1.0),
		"capturing_team_id": String(source.get("capturing_team_id", "")).strip_edges(),
		"contested": bool(source.get("contested", false)),
	}
	_copy_string_if_present(source, objective, "objective_id")
	var position: Variant = _coerce_position(source.get("position", null))
	if position != null:
		objective["position"] = position
	if source.has("capture_radius"):
		objective["capture_radius"] = maxf(float(source.get("capture_radius", 0.0)), 0.0)
	return objective


func _normalize_dropship(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = Dictionary(value)
	if source.is_empty():
		return {}
	var dropship: Dictionary = {
		"visible": bool(source.get("visible", source.get("dropship_visible", false))),
		"state": String(source.get("state", source.get("deploy_state", ""))).strip_edges().to_lower(),
		"has_lz": bool(source.get("has_lz", source.get("has_lz_position", false))),
	}
	var position: Variant = _coerce_position(source.get("position", source.get("dropship_position", null)))
	if position != null:
		dropship["position"] = position
	var target_position: Variant = _coerce_position(source.get("target_position", source.get("dropship_target_position", null)))
	if target_position != null:
		dropship["target_position"] = target_position
	var lz_position: Variant = _coerce_position(source.get("lz_position", null))
	if lz_position != null:
		dropship["lz_position"] = lz_position
	_copy_float_if_present(source, dropship, "progress")
	_copy_string_if_present(source, dropship, "team_id")
	return dropship


func _normalize_contacts(value: Variant) -> Array:
	var result: Array = []
	for entry_variant in _variant_to_array(value):
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = Dictionary(entry_variant)
		var contact: Dictionary = {}
		_copy_string_if_present(source, contact, "fireteam_id")
		_copy_string_if_present(source, contact, "unit_id")
		_copy_string_if_present(source, contact, "team_id")
		_copy_string_if_present(source, contact, "detection_state")
		_copy_int_if_present(source, contact, "last_seen_tick")
		var last_known_position: Variant = _coerce_position(source.get("last_known_position", null))
		if last_known_position != null:
			contact["last_known_position"] = last_known_position
		if not contact.is_empty():
			result.append(contact)
	return result


func _normalize_mission_result(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source: Dictionary = Dictionary(value)
	if source.is_empty():
		return {}
	var mission_result: Dictionary = {}
	_copy_string_if_present(source, mission_result, "result")
	_copy_string_if_present(source, mission_result, "winning_team_id")
	_copy_string_if_present(source, mission_result, "friendly_team_id")
	_copy_string_if_present(source, mission_result, "win_condition_type")
	_copy_string_if_present(source, mission_result, "result_condition")
	_copy_float_if_present(source, mission_result, "duration_seconds")
	if source.has("objective_captured"):
		mission_result["objective_captured"] = bool(source.get("objective_captured", false))
	if source.has("team_states"):
		mission_result["team_states"] = _variant_to_array(source.get("team_states", [])).duplicate(true)
	return mission_result


func _variant_to_array(value: Variant) -> Array:
	if value is Array:
		return Array(value)
	return []


func _coerce_position(value: Variant) -> Variant:
	var value_type: int = typeof(value)
	if value_type == TYPE_VECTOR2 or value_type == TYPE_VECTOR3:
		return value
	if value_type == TYPE_VECTOR2I:
		return Vector2(value.x, value.y)
	if value_type == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		if dict.has("z"):
			return Vector3(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)), float(dict.get("z", 0.0)))
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null


func _copy_string_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = String(source.get(key, "")).strip_edges()


func _copy_int_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = int(source.get(key, 0))


func _copy_float_if_present(source: Dictionary, target: Dictionary, key: String) -> void:
	if not source.has(key):
		return
	target[key] = float(source.get(key, 0.0))


func _reject(reason: String) -> Dictionary:
	return {
		"accepted": false,
		"reason": reason,
	}
