class_name MissionInteractionPointBinding
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_point_bindings.v1"
const TYPE_DOOR: String = "door"
const TYPE_COMPUTER: String = "computer"
const TYPE_HOLD_ZONE: String = "hold_zone"
const ALLOWED_TYPES: PackedStringArray = [TYPE_DOOR, TYPE_COMPUTER, TYPE_HOLD_ZONE]
const ALLOWED_ORDERS: PackedStringArray = ["take", "hold", "defend", "operate", "breach"]
const DOOR_FOOTPRINT = preload("res://scripts/mission/mission_door_footprint.gd")

# Only the parse of identical file contents is reusable. Runtime context and
# map validation are always rebuilt below, and the file is still read each time.
const SCENARIO_PARSE_TEXT_LIMIT: int = 1048576
static var _scenario_parse_text: String = ""
static var _scenario_parse_data: Dictionary = {}
static var _scenario_parse_has_entry: bool = false
static var _scenario_parse_retained_bytes: int = 0
static var _scenario_parse_count: int = 0
static var _scenario_parse_hit_count: int = 0

const OBJECTIVE_TYPE_TO_INTERACTION_TYPE: Dictionary = {
	"air_defense_shutdown": TYPE_HOLD_ZONE,
	"computer_hold": TYPE_COMPUTER,
	"cargo_touchdown_extract": TYPE_HOLD_ZONE,
}
const OBJECTIVE_TYPE_TO_REQUIRED_ORDER: Dictionary = {
	"air_defense_shutdown": "take",
	"computer_hold": "take",
	"cargo_touchdown_extract": "defend",
}


static func load_snapshot_from_file(path: String, terrain_map_data = null, runtime_context: Dictionary = {}) -> Dictionary:
	var scenario: Dictionary = {}
	var normalized_path: String = path.strip_edges()
	if not normalized_path.is_empty() and FileAccess.file_exists(normalized_path):
		var parsed: Variant = _parse_scenario_text(FileAccess.get_file_as_string(normalized_path))
		if typeof(parsed) == TYPE_DICTIONARY:
			scenario = Dictionary(parsed)
	var snapshot: Dictionary = build_snapshot(scenario, terrain_map_data, runtime_context)
	snapshot["source_path"] = normalized_path
	return snapshot


static func _parse_scenario_text(text: String) -> Variant:
	if _scenario_parse_has_entry and text == _scenario_parse_text:
		_scenario_parse_hit_count += 1
		return _scenario_parse_data
	_scenario_parse_count += 1
	var parsed: Variant = JSON.parse_string(text)
	# Never retain malformed/non-object input: repeated errors keep their former
	# behavior. A single entry replaces the previous one; no path-keyed growth.
	_scenario_parse_has_entry = false
	_scenario_parse_text = ""
	_scenario_parse_data = {}
	_scenario_parse_retained_bytes = 0
	if parsed is Dictionary and text.length() <= SCENARIO_PARSE_TEXT_LIMIT:
		var bytes: int = text.to_utf8_buffer().size()
		if bytes <= SCENARIO_PARSE_TEXT_LIMIT:
			_scenario_parse_text = text
			_scenario_parse_data = parsed
			_scenario_parse_has_entry = true
			_scenario_parse_retained_bytes = bytes
	return parsed


static func get_scenario_parse_cache_diagnostics() -> Dictionary:
	return {"parse_count": _scenario_parse_count, "hit_count": _scenario_parse_hit_count,
		"entry_count": 1 if _scenario_parse_has_entry else 0,
		"retained_text_bytes": _scenario_parse_retained_bytes,
		"text_limit_bytes": SCENARIO_PARSE_TEXT_LIMIT, "read_only": true,
		"caches_runtime_snapshots": false, "skips_file_reads": false}


static func build_snapshot(scenario: Dictionary, terrain_map_data = null, runtime_context: Dictionary = {}) -> Dictionary:
	var bindings: Array = normalize_scenario_bindings(scenario)
	var validation: Dictionary = validate_bindings(bindings, terrain_map_data)
	var binding_snapshots: Array = []
	var status_counts: Dictionary = {}
	for binding_variant in bindings:
		var binding: Dictionary = Dictionary(binding_variant)
		var entry: Dictionary = _build_binding_runtime_snapshot(binding, runtime_context)
		var status: String = String(entry.get("status", "unknown")).strip_edges().to_lower()
		status_counts[status] = int(status_counts.get(status, 0)) + 1
		binding_snapshots.append(entry)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"runtime_authority": "SimulationRoot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"scenario_id": String(scenario.get("scenario_id", "")).strip_edges(),
		"binding_count": bindings.size(),
		"bindings": binding_snapshots,
		"status_counts": status_counts,
		"validation": validation,
		"valid": bool(validation.get("valid", false)),
		"errors": PackedStringArray(validation.get("errors", PackedStringArray())),
		"complete_count": int(status_counts.get("complete", 0)),
		"blocked_count": int(status_counts.get("blocked", 0)),
		"available_count": int(status_counts.get("available", 0)),
		"in_progress_count": int(status_counts.get("in_progress", 0)),
	}


static func normalize_scenario_bindings(scenario: Dictionary) -> Array:
	var explicit_bindings: Array = _extract_explicit_bindings(scenario)
	if not explicit_bindings.is_empty():
		return _normalize_bindings(explicit_bindings, "explicit")
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	return _normalize_flow_steps_as_bindings(Array(vertical_slice.get("flow_steps", [])))


static func validate_bindings(bindings: Array, terrain_map_data = null) -> Dictionary:
	var errors: PackedStringArray = PackedStringArray()
	var seen_ids: Dictionary = {}
	for index in range(bindings.size()):
		var binding: Dictionary = Dictionary(bindings[index])
		var interaction_id: String = String(binding.get("interaction_id", "")).strip_edges()
		if interaction_id.is_empty():
			errors.append("interaction_points[%d].interaction_id is required" % index)
		elif seen_ids.has(interaction_id):
			errors.append("interaction_points[%d].interaction_id is duplicated: %s" % [index, interaction_id])
		else:
			seen_ids[interaction_id] = true
		var interaction_type: String = String(binding.get("interaction_type", "")).strip_edges().to_lower()
		if not ALLOWED_TYPES.has(interaction_type):
			errors.append("interaction_points[%d].interaction_type is not allowed: %s" % [index, interaction_type])
		var marker_id: String = String(binding.get("marker_id", "")).strip_edges()
		if marker_id.is_empty():
			errors.append("interaction_points[%d].marker_id is required" % index)
		elif terrain_map_data != null and terrain_map_data.has_method("has_marker") and not bool(terrain_map_data.call("has_marker", marker_id)):
			errors.append("interaction_points[%d].marker_id does not exist in map: %s" % [index, marker_id])
		var required_order: String = String(binding.get("required_order", "")).strip_edges().to_lower()
		if not required_order.is_empty() and not ALLOWED_ORDERS.has(required_order):
			errors.append("interaction_points[%d].required_order is not allowed: %s" % [index, required_order])
		if float(binding.get("duration_seconds", 0.0)) < 0.0:
			errors.append("interaction_points[%d].duration_seconds must be >= 0" % index)
		if float(binding.get("radius_world", 0.0)) <= 0.0:
			errors.append("interaction_points[%d].radius_world must be > 0" % index)
		var footprint := DOOR_FOOTPRINT.validate_binding(binding, terrain_map_data)
		if not footprint.ok:
			errors.append("interaction_points[%d].%s" % [index, String(footprint.reason)])
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"binding_count": bindings.size(),
	}


static func _extract_explicit_bindings(scenario: Dictionary) -> Array:
	if scenario.has("interaction_points"):
		return Array(scenario.get("interaction_points", []))
	var vertical_slice: Dictionary = Dictionary(scenario.get("vertical_slice", {}))
	return Array(vertical_slice.get("interaction_points", []))


static func _normalize_bindings(value: Array, source: String) -> Array:
	var result: Array = []
	for index in range(value.size()):
		var raw: Dictionary = Dictionary(value[index])
		var interaction_type: String = _normalize_interaction_type(String(raw.get("interaction_type", raw.get("objective_type", ""))))
		var objective_type: String = String(raw.get("objective_type", "")).strip_edges()
		var step_id: String = String(raw.get("step_id", raw.get("gate_step_id", raw.get("gate_id", "")))).strip_edges()
		var interaction_id: String = String(raw.get("interaction_id", raw.get("id", ""))).strip_edges()
		if interaction_id.is_empty():
			interaction_id = step_id if not step_id.is_empty() else "interaction_%02d" % (index + 1)
		var required_order: String = _normalize_required_order(String(raw.get("required_order", "")), objective_type)
		var marker_id: String = String(raw.get("marker_id", raw.get("target_marker_id", ""))).strip_edges()
		var duration_seconds: float = maxf(float(raw.get("duration_seconds", raw.get("required_hold_seconds", raw.get("min_hold_seconds", 0.0)))), 0.0)
		var radius_world: float = _normalize_radius(raw, interaction_type)
		var normalized: Dictionary = {
			"interaction_id": interaction_id,
			"display_name": String(raw.get("display_name", interaction_id.capitalize())).strip_edges(),
			"interaction_type": interaction_type,
			"marker_id": marker_id,
			"required_order": required_order,
			"duration_seconds": duration_seconds,
			"radius_world": radius_world,
			"step_id": step_id,
			"gate_id": String(raw.get("gate_id", step_id)).strip_edges(),
			"required_state": String(raw.get("required_state", "")).strip_edges(),
			"required_team": String(raw.get("required_team", raw.get("required_team_id", raw.get("operator_team_id", "")))).strip_edges(),
			"requires_step_id": String(raw.get("requires_step_id", "")).strip_edges(),
			"asset_hint": String(raw.get("asset_hint", raw.get("asset_id", ""))).strip_edges(),
			"source": source,
		}
		if not objective_type.is_empty():
			normalized["objective_type"] = objective_type
		if raw.has("door_cells"):
			# Preserve malformed authored values for validation; never silently
			# discard them and fall back to a single unvalidated marker.
			normalized["door_cells"] = raw.door_cells.duplicate(true) if raw.door_cells is Array or raw.door_cells is Dictionary else raw.door_cells
		result.append(normalized)
	return result


static func _normalize_flow_steps_as_bindings(flow_steps: Array) -> Array:
	var bindings: Array = []
	for step_variant in flow_steps:
		var step: Dictionary = Dictionary(step_variant).duplicate(true)
		var objective_type: String = String(step.get("objective_type", "")).strip_edges()
		if not OBJECTIVE_TYPE_TO_INTERACTION_TYPE.has(objective_type):
			continue
		step["interaction_id"] = String(step.get("step_id", "")).strip_edges()
		step["interaction_type"] = OBJECTIVE_TYPE_TO_INTERACTION_TYPE.get(objective_type, TYPE_HOLD_ZONE)
		step["marker_id"] = String(step.get("target_marker_id", "")).strip_edges()
		step["required_order"] = OBJECTIVE_TYPE_TO_REQUIRED_ORDER.get(objective_type, "take")
		step["duration_seconds"] = float(step.get("min_hold_seconds", 0.0))
		step["radius_world"] = _default_radius_for_type(String(step.get("interaction_type", "")))
		if step.has("operator_team_id"):
			step["required_team"] = step.get("operator_team_id")
		bindings.append(step)
	return _normalize_bindings(bindings, "vertical_slice_flow_step")


static func _normalize_interaction_type(raw_type: String) -> String:
	var normalized: String = raw_type.strip_edges().to_lower()
	if OBJECTIVE_TYPE_TO_INTERACTION_TYPE.has(normalized):
		return String(OBJECTIVE_TYPE_TO_INTERACTION_TYPE.get(normalized))
	match normalized:
		"interaction_door", "door", "gate":
			return TYPE_DOOR
		"interaction_computer", "computer", "terminal", "console":
			return TYPE_COMPUTER
		"interaction_hold_zone", "hold", "hold_zone", "capture", "capture_zone", "area":
			return TYPE_HOLD_ZONE
		_:
			return normalized


static func _normalize_required_order(raw_order: String, objective_type: String) -> String:
	var normalized: String = raw_order.strip_edges().to_lower()
	match normalized:
		"", "none":
			return String(OBJECTIVE_TYPE_TO_REQUIRED_ORDER.get(objective_type, "take"))
		"secure":
			return "take"
		"def":
			return "defend"
		"use", "hack":
			return "operate"
		_:
			return normalized


static func _normalize_radius(raw: Dictionary, interaction_type: String) -> float:
	var value: float = float(raw.get("radius_world", raw.get("radius", raw.get("capture_radius", -1.0))))
	if value <= 0.0:
		value = _default_radius_for_type(interaction_type)
	return maxf(value, 1.0)


static func _default_radius_for_type(interaction_type: String) -> float:
	match interaction_type.strip_edges().to_lower():
		TYPE_DOOR:
			return 72.0
		TYPE_COMPUTER:
			return 96.0
		_:
			return 128.0


static func _build_binding_runtime_snapshot(binding: Dictionary, runtime_context: Dictionary) -> Dictionary:
	var interaction_id: String = String(binding.get("interaction_id", "")).strip_edges()
	var step_id: String = String(binding.get("step_id", "")).strip_edges()
	var interaction_states: Dictionary = Dictionary(runtime_context.get("interaction_states", {}))
	var state: Dictionary = Dictionary(interaction_states.get(interaction_id, {}))
	var gate_snapshot: Dictionary = Dictionary(runtime_context.get("scenario_gate_snapshot", {}))
	var gate_state: Dictionary = _find_gate_state(gate_snapshot, step_id)
	var complete: bool = bool(state.get("complete", false)) or bool(gate_state.get("complete", false))
	var requires_step_id: String = String(binding.get("requires_step_id", "")).strip_edges()
	var blocked_by_step_id: String = ""
	if not requires_step_id.is_empty() and not _is_step_complete(gate_snapshot, requires_step_id):
		blocked_by_step_id = requires_step_id
	var raw_state: String = String(state.get("state", gate_state.get("status", ""))).strip_edges().to_lower()
	var status: String = "complete" if complete else "available"
	if not blocked_by_step_id.is_empty() and not complete:
		status = "blocked"
	elif ["active", "in_progress", "holding", "operating"].has(raw_state):
		status = "in_progress"
	var progress: float = _normalize_progress(state.get("progress", gate_state.get("progress", 1.0 if complete else 0.0)), complete)
	var result: Dictionary = binding.duplicate(true)
	result.merge({
		"runtime_authority": "SimulationRoot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"status": status,
		"complete": complete,
		"blocked": status == "blocked",
		"blocked_by_step_id": blocked_by_step_id,
		"in_progress": status == "in_progress",
		"interactable": status == "available" or status == "in_progress",
		"progress": progress,
		"active_team_id": String(state.get("active_team_id", state.get("team_id", ""))).strip_edges(),
		"hold_seconds": maxf(float(state.get("hold_seconds", gate_state.get("hold_elapsed_seconds", 0.0))), 0.0),
	}, true)
	return result


static func _normalize_progress(value: Variant, complete: bool) -> float:
	var progress: float = float(value)
	if complete:
		return 1.0
	if progress > 1.0:
		progress /= 100.0
	return clampf(progress, 0.0, 1.0)


static func _find_gate_state(gate_snapshot: Dictionary, step_id: String) -> Dictionary:
	var normalized_step_id: String = step_id.strip_edges()
	if normalized_step_id.is_empty():
		return {}
	for gate_variant in Array(gate_snapshot.get("gates", [])):
		var gate: Dictionary = Dictionary(gate_variant)
		if String(gate.get("step_id", "")).strip_edges() == normalized_step_id:
			return gate
	return {}


static func _is_step_complete(gate_snapshot: Dictionary, step_id: String) -> bool:
	var normalized_step_id: String = step_id.strip_edges()
	if normalized_step_id.is_empty():
		return false
	for completed_variant in Array(gate_snapshot.get("completed_step_ids", [])):
		if String(completed_variant).strip_edges() == normalized_step_id:
			return true
	var gate: Dictionary = _find_gate_state(gate_snapshot, normalized_step_id)
	return bool(gate.get("complete", false))
