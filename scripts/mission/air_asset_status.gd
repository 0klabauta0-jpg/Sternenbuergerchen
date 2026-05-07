class_name AirAssetStatus
extends RefCounted

const RUNTIME_AUTHORITY: String = "SimulationRoot"
const TYPE_DROPSHIP: String = "dropship"
const TYPE_FREIGHTER: String = "freighter"

const STATE_INTACT: String = "intact"
const STATE_THREATENED: String = "threatened"
const STATE_LOCKED: String = "locked"
const STATE_HIT: String = "hit"
const STATE_DAMAGED: String = "damaged"
const STATE_DESTROYED: String = "destroyed"
const STATE_CRASHED: String = "crashed"
const STATE_RECOVERING: String = "recovering"
const STATE_UNAVAILABLE: String = "unavailable"

const DEFAULT_MAX_INTEGRITY: int = 100

var asset_id: String = "mission_dropship"
var asset_type: String = TYPE_DROPSHIP
var display_name: String = "Dropship"
var state: String = STATE_INTACT
var integrity: int = DEFAULT_MAX_INTEGRITY
var max_integrity: int = DEFAULT_MAX_INTEGRITY
var risk: float = 0.0
var lz_secure_level: float = 0.0
var enemy_at_pressure: float = 0.0
var locked_by_unit_id: String = ""
var threat_weapon_id: String = ""
var last_event_id: String = ""
var last_reason: String = ""
var warning_visible: bool = false
var destroyed: bool = false
var crashed: bool = false
var recovering: bool = false
var unavailable: bool = false
var position = null
var vfx_events: Array = []
var sfx_events: Array = []
var metadata: Dictionary = {}
var normalization_warnings: PackedStringArray = PackedStringArray()


static func from_dict(data: Dictionary):
	var status = load("res://scripts/mission/air_asset_status.gd").new()
	status.asset_id = str(data.get("asset_id", status.asset_id)).strip_edges()
	if status.asset_id.is_empty():
		status.asset_id = "mission_dropship"
	status.asset_type = normalize_asset_type(str(data.get("asset_type", status.asset_type)))
	status.display_name = str(data.get("display_name", status.display_name)).strip_edges()
	if status.display_name.is_empty():
		status.display_name = "Freighter" if status.asset_type == TYPE_FREIGHTER else "Dropship"
	var source_metadata: Dictionary = Dictionary(data.get("metadata", {})).duplicate(true)
	status.metadata = source_metadata
	status.normalization_warnings = _sanitize_string_array(data.get("normalization_warnings", source_metadata.get("normalization_warnings", [])))
	var raw_state: String = str(data.get("state", status.state))
	status.state = normalize_state(raw_state)
	status._append_unknown_state_warning(raw_state, status.state)
	status.max_integrity = maxi(int(data.get("max_integrity", DEFAULT_MAX_INTEGRITY)), 1)
	status.integrity = clampi(int(data.get("integrity", status.max_integrity)), 0, status.max_integrity)
	status.risk = clampf(float(data.get("risk", 0.0)), 0.0, 1.0)
	status.lz_secure_level = clampf(float(data.get("lz_secure_level", 0.0)), 0.0, 1.0)
	status.enemy_at_pressure = clampf(float(data.get("enemy_at_pressure", 0.0)), 0.0, 1.0)
	status.locked_by_unit_id = str(data.get("locked_by_unit_id", "")).strip_edges()
	status.threat_weapon_id = str(data.get("threat_weapon_id", "")).strip_edges().to_lower()
	status.last_event_id = str(data.get("last_event_id", "")).strip_edges()
	status.last_reason = str(data.get("last_reason", "")).strip_edges()
	status.warning_visible = bool(data.get("warning_visible", is_warning_state(status.state)))
	status.destroyed = bool(data.get("destroyed", is_terminal_state(status.state)))
	status.crashed = bool(data.get("crashed", status.state == STATE_CRASHED))
	status.recovering = bool(data.get("recovering", status.state == STATE_RECOVERING))
	status.unavailable = bool(data.get("unavailable", status.state == STATE_UNAVAILABLE))
	status.position = _coerce_vector2_or_null(data.get("position", null))
	status.vfx_events = Array(data.get("vfx_events", [])).duplicate(true)
	status.sfx_events = Array(data.get("sfx_events", [])).duplicate(true)
	status._sync_normalization_warnings_metadata()
	return status


static func normalize_asset_type(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"freighter", "frachter", "transport_freighter":
			return TYPE_FREIGHTER
		_:
			return TYPE_DROPSHIP


static func normalize_state(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	match normalized:
		"", "ok", "ready", "available":
			return STATE_INTACT
		"threat", "warning":
			return STATE_THREATENED
		"lock", "locked_on":
			return STATE_LOCKED
		"damage":
			return STATE_DAMAGED
		"destroy", "lost":
			return STATE_DESTROYED
		"crash":
			return STATE_CRASHED
		"recover":
			return STATE_RECOVERING
		"offline":
			return STATE_UNAVAILABLE
		_:
			if [
				STATE_INTACT,
				STATE_THREATENED,
				STATE_LOCKED,
				STATE_HIT,
				STATE_DAMAGED,
				STATE_DESTROYED,
				STATE_CRASHED,
				STATE_RECOVERING,
				STATE_UNAVAILABLE,
			].has(normalized):
				return normalized
	return STATE_INTACT


static func is_warning_state(value: String) -> bool:
	return [STATE_THREATENED, STATE_LOCKED].has(normalize_state(value))


static func is_damage_state(value: String) -> bool:
	return [STATE_HIT, STATE_DAMAGED].has(normalize_state(value))


static func is_terminal_state(value: String) -> bool:
	return [STATE_DESTROYED, STATE_CRASHED].has(normalize_state(value))


func apply_threat(threat: Dictionary) -> void:
	var raw_state: String = str(threat.get("next_state", threat.get("state", state)))
	state = normalize_state(raw_state)
	_append_unknown_state_warning(raw_state, state)
	risk = clampf(float(threat.get("risk", risk)), 0.0, 1.0)
	lz_secure_level = clampf(float(threat.get("lz_secure_level", lz_secure_level)), 0.0, 1.0)
	enemy_at_pressure = clampf(float(threat.get("enemy_at_pressure", enemy_at_pressure)), 0.0, 1.0)
	locked_by_unit_id = str(threat.get("attacker_unit_id", locked_by_unit_id)).strip_edges()
	threat_weapon_id = str(threat.get("weapon_id", threat_weapon_id)).strip_edges().to_lower()
	last_event_id = str(threat.get("event_id", last_event_id)).strip_edges()
	last_reason = str(threat.get("reason", threat.get("blocked_reason", last_reason))).strip_edges()
	warning_visible = bool(threat.get("warning_visible", warning_visible or is_warning_state(state)))
	destroyed = is_terminal_state(state) or bool(threat.get("destroyed", destroyed))
	crashed = state == STATE_CRASHED or bool(threat.get("crashed", crashed))
	recovering = state == STATE_RECOVERING
	unavailable = state == STATE_UNAVAILABLE
	vfx_events = Array(threat.get("vfx_events", vfx_events)).duplicate(true)
	sfx_events = Array(threat.get("sfx_events", sfx_events)).duplicate(true)
	var threat_position = _coerce_vector2_or_null(threat.get("asset_position", threat.get("position", null)))
	if threat_position != null:
		position = threat_position
	metadata = Dictionary(threat.get("metadata", metadata)).duplicate(true)
	_sync_normalization_warnings_metadata()


func apply_damage(amount: int, context: Dictionary = {}) -> void:
	var damage: int = maxi(amount, 0)
	if damage <= 0:
		return
	integrity = clampi(integrity - damage, 0, max_integrity)
	if integrity <= 0:
		var raw_terminal_state: String = str(context.get("terminal_state", STATE_CRASHED))
		state = normalize_state(raw_terminal_state)
		_append_unknown_state_warning(raw_terminal_state, state)
		destroyed = true
		crashed = state == STATE_CRASHED
		warning_visible = true
	elif integrity <= int(ceil(float(max_integrity) * 0.55)):
		state = STATE_DAMAGED
	else:
		state = STATE_HIT
	recovering = false
	unavailable = false
	_sync_normalization_warnings_metadata()


func mark_recovering(reason: String = "") -> void:
	state = STATE_RECOVERING
	recovering = true
	unavailable = false
	destroyed = false
	crashed = false
	last_reason = reason.strip_edges()


func to_dict() -> Dictionary:
	var result: Dictionary = {
		"asset_id": asset_id,
		"asset_type": asset_type,
		"display_name": display_name,
		"state": state,
		"integrity": integrity,
		"max_integrity": max_integrity,
		"risk": risk,
		"lz_secure_level": lz_secure_level,
		"enemy_at_pressure": enemy_at_pressure,
		"locked_by_unit_id": locked_by_unit_id,
		"threat_weapon_id": threat_weapon_id,
		"last_event_id": last_event_id,
		"last_reason": last_reason,
		"warning_visible": warning_visible,
		"destroyed": destroyed,
		"crashed": crashed,
		"recovering": recovering,
		"unavailable": unavailable,
		"vfx_events": vfx_events.duplicate(true),
		"sfx_events": sfx_events.duplicate(true),
		"metadata": metadata.duplicate(true),
	}
	if not normalization_warnings.is_empty():
		result["normalization_warnings"] = PackedStringArray(normalization_warnings)
	if typeof(position) == TYPE_VECTOR2:
		result["position"] = Vector2(position)
	return result


func to_snapshot() -> Dictionary:
	var snapshot: Dictionary = to_dict()
	snapshot["runtime_authority"] = RUNTIME_AUTHORITY
	snapshot["ui_sets_gameplay_truth"] = false
	snapshot["warning_state"] = is_warning_state(state)
	snapshot["damage_state"] = is_damage_state(state)
	snapshot["terminal_state"] = is_terminal_state(state)
	snapshot["integrity_ratio"] = clampf(float(integrity) / float(max_integrity), 0.0, 1.0)
	return snapshot


func is_valid() -> bool:
	return not asset_id.strip_edges().is_empty() and max_integrity > 0 and integrity >= 0


func _append_unknown_state_warning(raw_value: String, normalized_value: String) -> void:
	var raw_normalized: String = raw_value.strip_edges().to_lower()
	if raw_normalized.is_empty() or _is_known_state_or_alias(raw_normalized):
		return
	var warning: String = "unknown_state:%s:fallback_%s" % [raw_normalized, normalized_value]
	if not normalization_warnings.has(warning):
		normalization_warnings.append(warning)


func _sync_normalization_warnings_metadata() -> void:
	if normalization_warnings.is_empty():
		metadata.erase("normalization_warnings")
		return
	metadata["normalization_warnings"] = PackedStringArray(normalization_warnings)


static func _is_known_state_or_alias(normalized_value: String) -> bool:
	return [
		"",
		"ok",
		"ready",
		"available",
		"threat",
		"warning",
		"lock",
		"locked_on",
		"damage",
		"destroy",
		"lost",
		"crash",
		"recover",
		"offline",
		STATE_INTACT,
		STATE_THREATENED,
		STATE_LOCKED,
		STATE_HIT,
		STATE_DAMAGED,
		STATE_DESTROYED,
		STATE_CRASHED,
		STATE_RECOVERING,
		STATE_UNAVAILABLE,
	].has(normalized_value)


static func _coerce_vector2_or_null(value):
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	if typeof(value) == TYPE_VECTOR2I:
		var grid := Vector2i(value)
		return Vector2(grid.x, grid.y)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return null


static func _sanitize_string_array(value: Variant) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for entry_variant in Array(value):
		var entry: String = String(entry_variant).strip_edges()
		if entry.is_empty() or result.has(entry):
			continue
		result.append(entry)
	return result
