class_name MissionCargoTouchdownBridge
extends RefCounted

const OBJECTIVE_TYPE_CARGO_TOUCHDOWN_EXTRACT: String = "cargo_touchdown_extract"

const STATE_UNCONFIGURED: String = "unconfigured"
const STATE_PENDING: String = "pending"
const STATE_BLOCKED: String = "blocked"
const STATE_INBOUND: String = "inbound"
const STATE_LANDED: String = "landed"
const STATE_DEPARTING: String = "departing"
const STATE_DEPARTED: String = "departed"

var _configured: bool = false
var _config: Dictionary = {}
var _runtime_state: String = ""
var _runtime_hold_seconds: float = 0.0
var _runtime_progress: float = -1.0
var _last_snapshot: Dictionary = {}


func configure(config: Dictionary) -> void:
	_config = _normalize_config(config)
	_configured = not String(_config.get("gate_step_id", "")).is_empty()
	_runtime_state = ""
	_runtime_hold_seconds = 0.0
	_runtime_progress = -1.0
	_last_snapshot = _build_snapshot(STATE_PENDING if _configured else STATE_UNCONFIGURED, 0.0, 0.0, "")


func configure_from_slice(slice: Dictionary) -> void:
	configure(_build_config_from_slice(slice))


func configure_from_file(path: String) -> void:
	var loaded_slice: Dictionary = {}
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) == TYPE_DICTIONARY:
			loaded_slice = Dictionary(parsed)
	configure_from_slice(loaded_slice)


func is_configured() -> bool:
	return _configured


func reset_runtime_state() -> void:
	_runtime_state = ""
	_runtime_hold_seconds = 0.0
	_runtime_progress = -1.0
	_last_snapshot = _build_snapshot(STATE_PENDING if _configured else STATE_UNCONFIGURED, 0.0, 0.0, "")


func set_runtime_state(state: String, hold_seconds: float = 0.0, progress: float = -1.0) -> void:
	_runtime_state = _normalize_state(state)
	_runtime_hold_seconds = maxf(hold_seconds, 0.0)
	_runtime_progress = progress


func update(context: Dictionary) -> Dictionary:
	if not _configured:
		_last_snapshot = _build_snapshot(STATE_UNCONFIGURED, 0.0, 0.0, "")
		return get_snapshot()

	var blocked_by_step_id: String = _get_blocking_step_id(context)
	if not blocked_by_step_id.is_empty():
		_last_snapshot = _build_snapshot(STATE_BLOCKED, 0.0, 0.0, blocked_by_step_id)
		return get_snapshot()

	var next_state: String = _resolve_state(context)
	var hold_seconds: float = maxf(float(context.get("cargo_hold_seconds", _runtime_hold_seconds)), _runtime_hold_seconds)
	var required_hold_seconds: float = maxf(float(_config.get("required_hold_seconds", 0.0)), 0.0)
	var progress: float = _resolve_progress(context, next_state, hold_seconds, required_hold_seconds)
	_last_snapshot = _build_snapshot(next_state, hold_seconds, progress, "")
	return get_snapshot()


func get_snapshot() -> Dictionary:
	return _last_snapshot.duplicate(true)


func _build_config_from_slice(slice: Dictionary) -> Dictionary:
	var root_slice: Dictionary = Dictionary(slice.get("vertical_slice", slice))
	for step_variant in Array(root_slice.get("flow_steps", [])):
		var step: Dictionary = Dictionary(step_variant)
		if String(step.get("objective_type", "")).strip_edges() != OBJECTIVE_TYPE_CARGO_TOUCHDOWN_EXTRACT:
			continue
		return {
			"gate_step_id": String(step.get("step_id", "")).strip_edges(),
			"requires_step_id": String(step.get("requires_step_id", "")).strip_edges(),
			"target_marker_id": String(step.get("target_marker_id", "")).strip_edges(),
			"required_hold_seconds": maxf(float(step.get("min_hold_seconds", 0.0)), 0.0),
			"required_state": String(step.get("required_state", "cargo_departed")).strip_edges(),
		}
	return {}


func _normalize_config(config: Dictionary) -> Dictionary:
	var result: Dictionary = config.duplicate(true)
	result["gate_step_id"] = String(result.get("gate_step_id", result.get("step_id", ""))).strip_edges()
	result["requires_step_id"] = String(result.get("requires_step_id", "")).strip_edges()
	result["target_marker_id"] = String(result.get("target_marker_id", "")).strip_edges()
	result["required_state"] = String(result.get("required_state", "cargo_departed")).strip_edges()
	result["required_hold_seconds"] = maxf(float(result.get("required_hold_seconds", result.get("min_hold_seconds", 0.0))), 0.0)
	result["asset_id"] = String(result.get("asset_id", "frontier_cargo_freighter")).strip_edges()
	result["asset_type"] = String(result.get("asset_type", "cargo_freighter")).strip_edges()
	result["display_name"] = String(result.get("display_name", "Cargo Freighter")).strip_edges()
	result["cargo_id"] = String(result.get("cargo_id", "mission_cargo")).strip_edges()
	result["cargo_display_name"] = String(result.get("cargo_display_name", "Mission Cargo")).strip_edges()
	return result


func _resolve_state(context: Dictionary) -> String:
	var context_state: String = _normalize_state(String(context.get("cargo_state", "")).strip_edges())
	if not context_state.is_empty():
		return context_state
	if not _runtime_state.is_empty():
		return _runtime_state
	return STATE_PENDING


func _normalize_state(state: String) -> String:
	var normalized: String = state.strip_edges().to_lower()
	match normalized:
		"", "none":
			return ""
		"to_mission", "approach", "approaching", "enroute", "en_route":
			return STATE_INBOUND
		"waiting", "touchdown", "on_ground", "hold", "holding":
			return STATE_LANDED
		"to_fob", "to_homebase", "returning", "outbound":
			return STATE_DEPARTING
		"cargo_departed", "extracted", "complete", "completed":
			return STATE_DEPARTED
		_:
			return normalized


func _resolve_progress(context: Dictionary, state: String, hold_seconds: float, required_hold_seconds: float) -> float:
	var context_progress: float = float(context.get("cargo_progress", _runtime_progress))
	if context_progress >= 0.0:
		if context_progress > 1.0:
			return clampf(context_progress / 100.0, 0.0, 1.0)
		return clampf(context_progress, 0.0, 1.0)
	if _runtime_progress >= 0.0:
		return clampf(_runtime_progress, 0.0, 1.0)
	if state == STATE_DEPARTED:
		return 1.0
	if state == STATE_LANDED and required_hold_seconds > 0.0:
		return clampf(hold_seconds / required_hold_seconds, 0.0, 1.0)
	if state == STATE_INBOUND or state == STATE_DEPARTING:
		return 0.5
	return 0.0


func _get_blocking_step_id(context: Dictionary) -> String:
	var requires_step_id: String = String(_config.get("requires_step_id", "")).strip_edges()
	if requires_step_id.is_empty():
		return ""
	var gate_snapshot: Dictionary = Dictionary(context.get("scenario_gate_snapshot", {}))
	var completed_step_ids: Array = Array(gate_snapshot.get("completed_step_ids", []))
	if completed_step_ids.has(requires_step_id):
		return ""
	for gate_variant in Array(gate_snapshot.get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")).strip_edges() == requires_step_id and bool(gate.get("complete", false)):
			return ""
	return requires_step_id


func _build_snapshot(state: String, hold_seconds: float, progress: float, blocked_by_step_id: String) -> Dictionary:
	var normalized_state: String = state.strip_edges().to_lower()
	var required_hold_seconds: float = maxf(float(_config.get("required_hold_seconds", 0.0)), 0.0)
	var is_complete: bool = normalized_state == STATE_DEPARTED
	return {
		"configured": _configured,
		"runtime_authority": "MissionCargoTouchdownBridge",
		"ui_sets_gameplay_truth": false,
		"asset_id": String(_config.get("asset_id", "")).strip_edges(),
		"asset_type": String(_config.get("asset_type", "")).strip_edges(),
		"display_name": String(_config.get("display_name", "")).strip_edges(),
		"cargo_id": String(_config.get("cargo_id", "")).strip_edges(),
		"cargo_display_name": String(_config.get("cargo_display_name", "")).strip_edges(),
		"gate_step_id": String(_config.get("gate_step_id", "")).strip_edges(),
		"requires_step_id": String(_config.get("requires_step_id", "")).strip_edges(),
		"target_marker_id": String(_config.get("target_marker_id", "")).strip_edges(),
		"required_state": String(_config.get("required_state", "")).strip_edges(),
		"cargo_state": normalized_state,
		"state": normalized_state,
		"blocked_by_step_id": blocked_by_step_id.strip_edges(),
		"blocked": not blocked_by_step_id.strip_edges().is_empty(),
		"hold_seconds": maxf(hold_seconds, 0.0),
		"required_hold_seconds": required_hold_seconds,
		"progress": clampf(progress, 0.0, 1.0),
		"ready_to_depart": normalized_state == STATE_LANDED and (required_hold_seconds <= 0.0 or hold_seconds >= required_hold_seconds),
		"complete": is_complete,
	}
