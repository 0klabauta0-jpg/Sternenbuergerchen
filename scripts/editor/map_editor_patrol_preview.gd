class_name MapEditorPatrolPreview
extends RefCounted


static func build_preview_snapshot_for_reference(terrain_map_data, mission_scenario, reference_id: String, source_type: String = "manual") -> Dictionary:
	var resolved: Dictionary = resolve_route_reference(terrain_map_data, mission_scenario, reference_id)
	if resolved.is_empty():
		return _empty_snapshot(reference_id, source_type)
	return build_preview_snapshot(
		terrain_map_data,
		String(resolved.get("patrol_path_id", "")),
		String(resolved.get("source_id", reference_id)),
		String(resolved.get("source_type", source_type))
	)


static func build_preview_snapshot(terrain_map_data, patrol_path_id: String, source_id: String = "", source_type: String = "manual") -> Dictionary:
	var normalized_path_id: String = patrol_path_id.strip_edges()
	if terrain_map_data == null or normalized_path_id.is_empty() or not terrain_map_data.has_method("get_patrol_path"):
		return _empty_snapshot(source_id if not source_id.strip_edges().is_empty() else normalized_path_id, source_type)
	var path_points: Array = Array(terrain_map_data.call("get_patrol_path", normalized_path_id))
	if path_points.is_empty():
		return _empty_snapshot(source_id if not source_id.strip_edges().is_empty() else normalized_path_id, source_type)

	var waypoints: Array = []
	for waypoint_index in range(path_points.size()):
		waypoints.append({
			"index": waypoint_index + 1,
			"position": Vector2(path_points[waypoint_index]),
		})

	var segments: Array = []
	var total_length: float = 0.0
	for segment_index in range(1, path_points.size()):
		var start_position: Vector2 = Vector2(path_points[segment_index - 1])
		var end_position: Vector2 = Vector2(path_points[segment_index])
		var direction: Vector2 = end_position - start_position
		var length: float = direction.length()
		if length > 0.001:
			direction /= length
		else:
			direction = Vector2.RIGHT
		total_length += length
		segments.append({
			"index": segment_index,
			"from": start_position,
			"to": end_position,
			"direction": direction,
			"length": length,
			"heading_degrees": rad_to_deg(direction.angle()),
		})

	return {
		"active": true,
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"read_source": "TerrainMapData.get_patrol_path",
		"patrol_path_id": normalized_path_id,
		"source_id": source_id.strip_edges() if not source_id.strip_edges().is_empty() else normalized_path_id,
		"source_type": source_type.strip_edges() if not source_type.strip_edges().is_empty() else "manual",
		"waypoint_count": waypoints.size(),
		"segment_count": segments.size(),
		"total_length": total_length,
		"waypoints": waypoints,
		"segments": segments,
	}


static func resolve_route_reference(terrain_map_data, mission_scenario, reference_id: String) -> Dictionary:
	var normalized_reference_id: String = reference_id.strip_edges()
	if normalized_reference_id.is_empty():
		return {}
	if terrain_map_data != null and terrain_map_data.has_method("get_patrol_paths"):
		var patrol_paths: Dictionary = Dictionary(terrain_map_data.call("get_patrol_paths"))
		if patrol_paths.has(normalized_reference_id):
			return {
				"patrol_path_id": normalized_reference_id,
				"source_id": normalized_reference_id,
				"source_type": "patrol_path_id",
			}

	if mission_scenario == null:
		return {}
	var patrol_bindings: Array = Array(mission_scenario.get("patrol_bindings"))
	for binding_variant in patrol_bindings:
		if not (binding_variant is Dictionary):
			continue
		var binding: Dictionary = Dictionary(binding_variant)
		var binding_id: String = String(binding.get("binding_id", "")).strip_edges()
		var target_id: String = String(binding.get("target_id", "")).strip_edges()
		var patrol_path_id: String = String(binding.get("patrol_path_id", "")).strip_edges()
		if patrol_path_id.is_empty():
			continue
		if normalized_reference_id == binding_id:
			return {
				"patrol_path_id": patrol_path_id,
				"source_id": binding_id,
				"source_type": "binding_id",
			}
		if normalized_reference_id == target_id:
			return {
				"patrol_path_id": patrol_path_id,
				"source_id": target_id,
				"source_type": "target_id",
			}
		if normalized_reference_id == patrol_path_id:
			return {
				"patrol_path_id": patrol_path_id,
				"source_id": patrol_path_id,
				"source_type": "patrol_path_id",
			}
	return {}


static func find_route_reference_near_world_position(terrain_map_data, world_position: Vector2, waypoint_pick_radius: float, segment_pick_radius: float) -> Dictionary:
	if terrain_map_data == null or not terrain_map_data.has_method("get_patrol_paths"):
		return {}
	var patrol_paths: Dictionary = Dictionary(terrain_map_data.call("get_patrol_paths"))
	var best_result: Dictionary = {}
	var best_distance_sq: float = waypoint_pick_radius * waypoint_pick_radius
	for path_id_variant in patrol_paths.keys():
		var path_id: String = String(path_id_variant).strip_edges()
		if path_id.is_empty():
			continue
		var points: Array = Array(terrain_map_data.call("get_patrol_path", path_id))
		for waypoint_index in range(points.size()):
			var point_position: Vector2 = Vector2(points[waypoint_index])
			var distance_sq: float = point_position.distance_squared_to(world_position)
			if distance_sq > best_distance_sq:
				continue
			best_distance_sq = distance_sq
			best_result = {
				"patrol_path_id": path_id,
				"source_id": path_id,
				"source_type": "waypoint_hover",
				"waypoint_index": waypoint_index,
				"distance_sq": distance_sq,
			}
	if not best_result.is_empty():
		return best_result

	best_distance_sq = segment_pick_radius * segment_pick_radius
	for path_id_variant in patrol_paths.keys():
		var path_id: String = String(path_id_variant).strip_edges()
		if path_id.is_empty():
			continue
		var points: Array = Array(terrain_map_data.call("get_patrol_path", path_id))
		for segment_index in range(1, points.size()):
			var start_position: Vector2 = Vector2(points[segment_index - 1])
			var end_position: Vector2 = Vector2(points[segment_index])
			var distance_sq: float = _distance_squared_to_segment(world_position, start_position, end_position)
			if distance_sq > best_distance_sq:
				continue
			best_distance_sq = distance_sq
			best_result = {
				"patrol_path_id": path_id,
				"source_id": path_id,
				"source_type": "segment_hover",
				"segment_index": segment_index,
				"distance_sq": distance_sq,
			}
	return best_result


static func _distance_squared_to_segment(point: Vector2, start_position: Vector2, end_position: Vector2) -> float:
	var segment: Vector2 = end_position - start_position
	var length_sq: float = segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_squared_to(start_position)
	var ratio: float = clampf((point - start_position).dot(segment) / length_sq, 0.0, 1.0)
	var closest: Vector2 = start_position + segment * ratio
	return point.distance_squared_to(closest)


static func _empty_snapshot(source_id: String = "", source_type: String = "") -> Dictionary:
	return {
		"active": false,
		"visual_only": true,
		"ui_sets_gameplay_truth": false,
		"read_source": "TerrainMapData.get_patrol_path",
		"patrol_path_id": "",
		"source_id": source_id.strip_edges(),
		"source_type": source_type.strip_edges(),
		"waypoint_count": 0,
		"segment_count": 0,
		"total_length": 0.0,
		"waypoints": [],
		"segments": [],
	}
