class_name MissionInteractionRuntimeUseState
extends RefCounted

const SNAPSHOT_SCHEMA: String = "sternenbuergerchen.mission_interaction_runtime_use_state.v1"
const STATUS_COMPLETE: String = "complete"
const STATUS_BLOCKED: String = "blocked"
const STATUS_IN_PROGRESS: String = "in_progress"
const STATUS_USABLE: String = "usable"
const STATUS_OUT_OF_RANGE: String = "out_of_range"
const STATUS_INTERRUPTED: String = "interrupted"
const STATUS_UNKNOWN: String = "unknown"


static func build_snapshot(binding_snapshot: Dictionary, terrain_map_data = null, runtime_context: Dictionary = {}) -> Dictionary:
	var binding_entries: Array = Array(binding_snapshot.get("bindings", []))
	var current_team_id: String = String(runtime_context.get("current_team_id", "")).strip_edges().to_lower()
	var fireteam_positions: Array = _normalize_fireteam_positions(runtime_context.get("fireteam_positions", []), current_team_id)
	var interaction_states: Dictionary = Dictionary(runtime_context.get("interaction_states", {}))
	var entries: Array = []
	var status_counts: Dictionary = {}
	var next_usable_interaction_id: String = ""
	for binding_variant in binding_entries:
		if typeof(binding_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = _build_interaction_entry(Dictionary(binding_variant), terrain_map_data, fireteam_positions, current_team_id, interaction_states)
		var status: String = String(entry.get("runtime_use_status", STATUS_UNKNOWN)).strip_edges().to_lower()
		status_counts[status] = int(status_counts.get(status, 0)) + 1
		if next_usable_interaction_id.is_empty() and bool(entry.get("can_use_now", false)):
			next_usable_interaction_id = String(entry.get("interaction_id", "")).strip_edges()
		entries.append(entry)
	return {
		"schema": SNAPSHOT_SCHEMA,
		"source_binding_schema": String(binding_snapshot.get("schema", "")).strip_edges(),
		"runtime_authority": "SimulationRoot",
		"read_only": true,
		"ui_sets_gameplay_truth": false,
		"scenario_id": String(binding_snapshot.get("scenario_id", "")).strip_edges(),
		"interaction_count": entries.size(),
		"interactions": entries,
		"status_counts": status_counts,
		"next_usable_interaction_id": next_usable_interaction_id,
		"fireteam_position_count": fireteam_positions.size(),
		"complete_count": int(status_counts.get(STATUS_COMPLETE, 0)),
		"blocked_count": int(status_counts.get(STATUS_BLOCKED, 0)),
		"in_progress_count": int(status_counts.get(STATUS_IN_PROGRESS, 0)),
		"usable_count": int(status_counts.get(STATUS_USABLE, 0)),
		"out_of_range_count": int(status_counts.get(STATUS_OUT_OF_RANGE, 0)),
		"interrupted_count": int(status_counts.get(STATUS_INTERRUPTED, 0)),
		"unknown_count": int(status_counts.get(STATUS_UNKNOWN, 0)),
	}


static func _build_interaction_entry(binding: Dictionary, terrain_map_data, fireteam_positions: Array, current_team_id: String, interaction_states: Dictionary) -> Dictionary:
	var interaction_id: String = String(binding.get("interaction_id", "")).strip_edges()
	var marker_data: Dictionary = _resolve_marker_position(binding, terrain_map_data)
	var marker_position: Vector2 = Vector2(marker_data.get("position", Vector2.ZERO))
	var radius_world: float = maxf(float(binding.get("radius_world", 0.0)), 1.0)
	var required_team: String = String(binding.get("required_team", "")).strip_edges().to_lower()
	var state: Dictionary = Dictionary(interaction_states.get(interaction_id, {}))
	var nearest: Dictionary = _find_nearest_fireteam(marker_position, radius_world, fireteam_positions, required_team, current_team_id) if bool(marker_data.get("has_position", false)) else {}
	var distance_world: float = float(nearest.get("distance_world", -1.0))
	var in_range: bool = distance_world >= 0.0 and distance_world <= radius_world
	var status: String = _derive_runtime_use_status(binding, state, bool(marker_data.get("has_position", false)), fireteam_positions.size(), in_range)
	var progress: float = clampf(float(state.get("progress", binding.get("progress", 0.0))), 0.0, 1.0)
	if bool(binding.get("complete", false)):
		progress = 1.0
	var result: Dictionary = binding.duplicate(true)
	result.merge({
		"runtime_use_status": status,
		"runtime_use_reason": _build_status_reason(status, binding, bool(marker_data.get("has_position", false)), fireteam_positions.size(), distance_world, radius_world),
		"can_use_now": status == STATUS_USABLE or status == STATUS_IN_PROGRESS,
		"in_range": in_range,
		"distance_world": distance_world,
		"radius_world": radius_world,
		"marker_position": marker_position,
		"has_marker_position": bool(marker_data.get("has_position", false)),
		"nearest_fireteam_id": String(nearest.get("fireteam_id", "")).strip_edges().to_lower(),
		"nearest_fireteam_team_id": String(nearest.get("team_id", "")).strip_edges().to_lower(),
		"current_team_id": current_team_id,
		"required_team": required_team,
		"progress": progress,
		"hold_seconds": maxf(float(state.get("hold_seconds", binding.get("hold_seconds", 0.0))), 0.0),
		"duration_seconds": maxf(float(binding.get("duration_seconds", 0.0)), 0.0),
		"read_only": true,
		"ui_sets_gameplay_truth": false,
	}, true)
	return result


static func _derive_runtime_use_status(binding: Dictionary, state: Dictionary, has_marker_position: bool, fireteam_position_count: int, in_range: bool) -> String:
	var binding_status: String = String(binding.get("status", "")).strip_edges().to_lower()
	var explicit_state: String = String(state.get("state", "")).strip_edges().to_lower()
	if bool(binding.get("complete", false)) or binding_status == STATUS_COMPLETE or explicit_state == STATUS_COMPLETE:
		return STATUS_COMPLETE
	if bool(binding.get("blocked", false)) or binding_status == STATUS_BLOCKED:
		return STATUS_BLOCKED
	if explicit_state == STATUS_INTERRUPTED or binding_status == STATUS_INTERRUPTED:
		return STATUS_INTERRUPTED
	if not has_marker_position or fireteam_position_count <= 0:
		return STATUS_UNKNOWN
	if not in_range:
		return STATUS_OUT_OF_RANGE
	if bool(binding.get("in_progress", false)) or binding_status == STATUS_IN_PROGRESS or ["active", "holding", "operating"].has(explicit_state):
		return STATUS_IN_PROGRESS
	return STATUS_USABLE


static func _build_status_reason(status: String, binding: Dictionary, has_marker_position: bool, fireteam_position_count: int, distance_world: float, radius_world: float) -> String:
	match status:
		STATUS_COMPLETE:
			return "interaction_complete"
		STATUS_BLOCKED:
			var blocked_by_step_id: String = String(binding.get("blocked_by_step_id", "")).strip_edges()
			return "blocked_by_%s" % blocked_by_step_id if not blocked_by_step_id.is_empty() else "blocked"
		STATUS_INTERRUPTED:
			return "runtime_interrupted"
		STATUS_OUT_OF_RANGE:
			return "nearest_fireteam_%.0f_over_radius_%.0f" % [distance_world, radius_world]
		STATUS_USABLE:
			return "nearest_fireteam_in_radius"
		STATUS_IN_PROGRESS:
			return "runtime_progress_in_radius"
		_:
			if not has_marker_position:
				return "missing_marker_position"
			if fireteam_position_count <= 0:
				return "no_runtime_fireteam_position"
			return "unknown"


static func _resolve_marker_position(binding: Dictionary, terrain_map_data) -> Dictionary:
	var marker_id: String = String(binding.get("marker_id", "")).strip_edges()
	if terrain_map_data != null and not marker_id.is_empty() and terrain_map_data.has_method("has_marker") and bool(terrain_map_data.call("has_marker", marker_id)):
		return {
			"has_position": true,
			"position": Vector2(terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)),
		}
	if typeof(binding.get("marker_position", null)) == TYPE_VECTOR2:
		return {
			"has_position": true,
			"position": Vector2(binding.get("marker_position", Vector2.ZERO)),
		}
	return {
		"has_position": false,
		"position": Vector2.ZERO,
	}


static func _find_nearest_fireteam(marker_position: Vector2, radius_world: float, fireteam_positions: Array, required_team: String, current_team_id: String) -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance: float = INF
	for fireteam_variant in fireteam_positions:
		if typeof(fireteam_variant) != TYPE_DICTIONARY:
			continue
		var fireteam: Dictionary = Dictionary(fireteam_variant)
		var team_id: String = String(fireteam.get("team_id", current_team_id)).strip_edges().to_lower()
		if not _team_is_allowed(required_team, current_team_id, team_id):
			continue
		var position: Vector2 = Vector2(fireteam.get("position", Vector2.ZERO))
		var distance: float = marker_position.distance_to(position)
		if distance >= nearest_distance:
			continue
		nearest_distance = distance
		nearest = fireteam.duplicate(true)
		nearest["distance_world"] = distance
		nearest["in_range"] = distance <= radius_world
	return nearest


static func _team_is_allowed(required_team: String, current_team_id: String, fireteam_team_id: String) -> bool:
	var normalized_required: String = required_team.strip_edges().to_lower()
	if normalized_required.is_empty() or normalized_required == "any":
		return true
	if normalized_required == "player":
		return fireteam_team_id == current_team_id or current_team_id.is_empty()
	return fireteam_team_id == normalized_required


static func _normalize_fireteam_positions(value: Variant, fallback_team_id: String) -> Array:
	var raw_entries: Array = []
	if typeof(value) == TYPE_DICTIONARY:
		for fireteam_id_variant in Dictionary(value).keys():
			raw_entries.append({
				"fireteam_id": String(fireteam_id_variant).strip_edges().to_lower(),
				"position": Dictionary(value).get(fireteam_id_variant, Vector2.ZERO),
			})
	elif typeof(value) == TYPE_ARRAY:
		raw_entries = Array(value)
	var result: Array = []
	for entry_variant in raw_entries:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = Dictionary(entry_variant)
		if entry.has("active") and not bool(entry.get("active", true)):
			continue
		var fireteam_id: String = String(entry.get("fireteam_id", entry.get("id", ""))).strip_edges().to_lower()
		if fireteam_id.is_empty():
			continue
		var position_variant: Variant = entry.get("position", entry.get("world_position", Vector2.ZERO))
		var position: Vector2 = _coerce_vector2(position_variant)
		result.append({
			"fireteam_id": fireteam_id,
			"team_id": String(entry.get("team_id", fallback_team_id)).strip_edges().to_lower(),
			"position": position,
			"active": true,
		})
	result.sort_custom(Callable(MissionInteractionRuntimeUseState, "_sort_fireteam_position_entries"))
	return result


static func _sort_fireteam_position_entries(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("fireteam_id", "")) < String(b.get("fireteam_id", ""))


static func _coerce_vector2(value: Variant) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return Vector2(value)
	if typeof(value) == TYPE_DICTIONARY:
		var dict: Dictionary = Dictionary(value)
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return Vector2.ZERO
