class_name MissionRuntimeIdentity
extends RefCounted

const HANDOFF_SCHEMA := "sternenbuergerchen.mission_runtime_identity_handoff.v1"

var _data: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	_data = _normalize(data)


static func from_selected_mission_definition(definition: Dictionary) -> MissionRuntimeIdentity:
	var mission_id := String(definition.get("mission_id", "")).strip_edges()
	var map_path := String(definition.get("map_file_path", "")).strip_edges().replace("\\", "/")
	var scenario_path := String(definition.get("scenario_file_path", "")).strip_edges().replace("\\", "/")
	if mission_id.is_empty() or map_path.is_empty() or scenario_path.is_empty():
		return MissionRuntimeIdentity.new()
	var scenario = MissionScenarioData.load_from_file(scenario_path)
	var terrain = TerrainMapData.load_from_file(map_path)
	if scenario == null or terrain == null or not scenario.is_valid() or String(scenario.map_file_path).strip_edges().replace("\\", "/") != map_path:
		return MissionRuntimeIdentity.new()
	var objective: Dictionary = Dictionary(scenario.objective)
	var marker_id := String(objective.get("marker_id", "")).strip_edges()
	var radius := float(objective.get("capture_radius", 0.0))
	var position: Vector2 = scenario.get_objective_position(terrain)
	if marker_id.is_empty() or radius <= 0.0 or position == Vector2.ZERO:
		return MissionRuntimeIdentity.new()
	return MissionRuntimeIdentity.new({
		"source": "meta_layer_selected_mission_definition",
		"mission_id": mission_id,
		"map_path": map_path,
		"scenario_path": scenario_path,
		"objective_marker_id": marker_id,
		"capture_radius": radius,
		"objective_world_position": position,
	})


static func from_snapshot(snapshot: Dictionary) -> MissionRuntimeIdentity:
	return MissionRuntimeIdentity.new(snapshot)


func is_valid() -> bool:
	return not String(_data.get("mission_id", "")).is_empty() \
		and not String(_data.get("map_path", "")).is_empty() \
		and not String(_data.get("scenario_path", "")).is_empty() \
		and not String(_data.get("objective_marker_id", "")).is_empty() \
		and float(_data.get("capture_radius", 0.0)) > 0.0 \
		and _data.get("objective_world_position", Vector2.ZERO) is Vector2


func snapshot() -> Dictionary:
	return _data.duplicate(true)


func build_pre_tree_handoff_receipt() -> Dictionary:
	if not is_valid():
		return {}
	return {
		"schema": HANDOFF_SCHEMA,
		"phase": "enter_tree",
		"received_before_enter_tree": true,
		"source": String(_data.get("source", "")),
		"mission_id": String(_data.get("mission_id", "")),
		"map_path": String(_data.get("map_path", "")),
		"scenario_path": String(_data.get("scenario_path", "")),
		"objective_marker_id": String(_data.get("objective_marker_id", "")),
		"capture_radius": float(_data.get("capture_radius", 0.0)),
		"objective_world_position": _serialize_position(Vector2(_data.get("objective_world_position", Vector2.ZERO))),
		"identity_fingerprint": String(_data.get("identity_fingerprint", "")),
	}


func _normalize(input: Dictionary) -> Dictionary:
	var position: Vector2 = _coerce_position(input.get("objective_world_position", Vector2.ZERO))
	var normalized := {
		"source": String(input.get("source", "")).strip_edges(),
		"mission_id": String(input.get("mission_id", "")).strip_edges(),
		"map_path": String(input.get("map_path", input.get("map_file_path", ""))).strip_edges().replace("\\", "/"),
		"scenario_path": String(input.get("scenario_path", input.get("scenario_file_path", ""))).strip_edges().replace("\\", "/"),
		"objective_marker_id": String(input.get("objective_marker_id", "")).strip_edges(),
		"capture_radius": float(input.get("capture_radius", 0.0)),
		"objective_world_position": position,
	}
	var fingerprint_source := "%s|%s|%s|%s|%s|%.3f|%.3f|%.3f" % [String(normalized.get("source", "")), String(normalized.get("mission_id", "")), String(normalized.get("map_path", "")), String(normalized.get("scenario_path", "")), String(normalized.get("objective_marker_id", "")), float(normalized.get("capture_radius", 0.0)), position.x, position.y]
	normalized["identity_fingerprint"] = fingerprint_source.sha256_text()
	return normalized


func _coerce_position(value: Variant) -> Vector2:
	if value is Vector2:
		return Vector2(value)
	if value is Dictionary:
		var dict: Dictionary = value
		return Vector2(float(dict.get("x", 0.0)), float(dict.get("y", 0.0)))
	return Vector2.ZERO


func _serialize_position(position: Vector2) -> Dictionary:
	return {"x": position.x, "y": position.y}
