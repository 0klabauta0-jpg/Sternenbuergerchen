class_name TerrainTruthAudit
extends RefCounted

const TERRAIN_AUTHORITY: String = "TerrainRegistry"
const WALL_LOS_POLICY: String = "edge_segment_blockers"
const SEQUENCE_EXPORT_POLICY: String = "documentation_json_first"
const WALL_CORNER_TOUCH_TOLERANCE: float = 0.001
const DEV_UI_FIELDS: PackedStringArray = [
	"tile_id",
	"type_id",
	"object_type_id",
	"surface_type",
	"height_level",
	"object_height",
	"walkable",
	"blocks_los",
	"cover_value",
	"object_rotation_degrees",
	"object_scale",
	"blocker_type",
	"wall_segment_count",
]


static func get_dev_ui_fields() -> PackedStringArray:
	return DEV_UI_FIELDS.duplicate()


static func build_policy_snapshot() -> Dictionary:
	return {
		"terrain_authority": TERRAIN_AUTHORITY,
		"terrain3d_role": "visual_authoring_candidate",
		"wall_los_policy": WALL_LOS_POLICY,
		"sequence_export_policy": SEQUENCE_EXPORT_POLICY,
		"corner_touch_tolerance": WALL_CORNER_TOUCH_TOLERANCE,
		"combat_los_uses_segment_policy": true,
		"combat_los_policy_source": "LineOfSightSystem",
		"dev_ui_fields": get_dev_ui_fields(),
	}


static func build_tile_truth_entry(tile_data, tile_catalog = null) -> Dictionary:
	if tile_data == null:
		return {}
	var type_id: String = _get_tile_type_id(tile_data)
	var object_type_id: String = _get_tile_object_type_id(tile_data)
	var wall_segments: Array = get_wall_segments_for_tile(tile_data)
	var issues: PackedStringArray = PackedStringArray()
	var has_object_layer: bool = not object_type_id.is_empty()
	var ground_layer_state: String = "ground_present" if _is_ground_type_id(type_id) else "structure_or_surface"
	var object_layer_state: String = "none"
	if has_object_layer:
		object_layer_state = "object_on_ground" if _is_ground_type_id(type_id) else "object_on_non_ground"
		if not _is_ground_type_id(type_id):
			issues.append("object_layer_without_ground_base")
	elif tile_catalog != null and tile_catalog.has_method("is_object_layer_type") and bool(tile_catalog.call("is_object_layer_type", type_id)):
		object_layer_state = "object_replaces_ground"
		issues.append("object_layer_type_in_base_type_id")
	var blocker_type: String = resolve_blocker_type(tile_data)
	return {
		"tile_id": String(tile_data.tile_id),
		"type_id": type_id,
		"object_type_id": object_type_id,
		"surface_type": String(tile_data.surface_type),
		"height_level": int(tile_data.height_level),
		"object_height": int(tile_data.object_height),
		"walkable": bool(tile_data.walkable),
		"blocks_los": bool(tile_data.blocks_los),
		"cover_value": int(tile_data.cover_value),
		"object_rotation_degrees": float(tile_data.object_rotation_degrees),
		"object_scale": float(tile_data.object_scale),
		"ground_layer_state": ground_layer_state,
		"object_layer_state": object_layer_state,
		"has_object_layer": has_object_layer,
		"blocker_type": blocker_type,
		"is_wall_type": is_wall_type_id(type_id) or is_wall_type_id(object_type_id),
		"wall_segment_count": wall_segments.size(),
		"wall_segments": wall_segments,
		"issues": issues,
	}


static func build_map_truth_snapshot(terrain_map_data, tile_catalog = null) -> Dictionary:
	var snapshot: Dictionary = build_policy_snapshot()
	var tile_count: int = 0
	var object_layer_count: int = 0
	var ground_under_object_count: int = 0
	var object_without_ground_count: int = 0
	var whole_tile_los_blocker_count: int = 0
	var wall_type_count: int = 0
	var wall_segment_candidate_count: int = 0
	var wall_without_segment_count: int = 0
	var issue_count: int = 0
	var blocker_types: Dictionary = {}
	var sample_entries: Array = []
	if terrain_map_data != null and terrain_map_data.has_method("get_tiles"):
		for tile_data in Array(terrain_map_data.call("get_tiles")):
			if tile_data == null:
				continue
			tile_count += 1
			var entry: Dictionary = build_tile_truth_entry(tile_data, tile_catalog)
			var blocker_type: String = String(entry.get("blocker_type", "none"))
			blocker_types[blocker_type] = int(blocker_types.get(blocker_type, 0)) + 1
			if bool(entry.get("has_object_layer", false)):
				object_layer_count += 1
			if String(entry.get("object_layer_state", "")) == "object_on_ground":
				ground_under_object_count += 1
			if String(entry.get("object_layer_state", "")) == "object_on_non_ground" or String(entry.get("object_layer_state", "")) == "object_replaces_ground":
				object_without_ground_count += 1
			if bool(entry.get("blocks_los", false)):
				whole_tile_los_blocker_count += 1
			if bool(entry.get("is_wall_type", false)):
				wall_type_count += 1
				if int(entry.get("wall_segment_count", 0)) > 0:
					wall_segment_candidate_count += 1
				else:
					wall_without_segment_count += 1
			issue_count += PackedStringArray(entry.get("issues", PackedStringArray())).size()
			if sample_entries.size() < 12 and (blocker_type != "none" or bool(entry.get("has_object_layer", false)) or not PackedStringArray(entry.get("issues", PackedStringArray())).is_empty()):
				sample_entries.append(entry)
	snapshot["tile_count"] = tile_count
	snapshot["object_layer_count"] = object_layer_count
	snapshot["ground_under_object_count"] = ground_under_object_count
	snapshot["object_without_ground_count"] = object_without_ground_count
	snapshot["whole_tile_los_blocker_count"] = whole_tile_los_blocker_count
	snapshot["wall_type_count"] = wall_type_count
	snapshot["wall_segment_candidate_count"] = wall_segment_candidate_count
	snapshot["wall_without_segment_count"] = wall_without_segment_count
	snapshot["issue_count"] = issue_count
	snapshot["blocker_types"] = blocker_types
	snapshot["sample_entries"] = sample_entries
	snapshot["visual_only"] = true
	snapshot["ui_sets_gameplay_truth"] = false
	return snapshot


static func resolve_blocker_type(tile_data) -> String:
	if tile_data == null:
		return "none"
	var type_id: String = _get_tile_type_id(tile_data)
	var object_type_id: String = _get_tile_object_type_id(tile_data)
	if is_wall_type_id(type_id) or is_wall_type_id(object_type_id):
		return "wall_segment_candidate" if not get_wall_segments_for_tile(tile_data).is_empty() else "wall_whole_tile_candidate"
	if bool(tile_data.blocks_los):
		return "tile_los_blocker"
	if int(tile_data.object_height) > 0:
		return "object_height"
	if int(tile_data.cover_value) > 0:
		return "cover"
	return "none"


static func is_wall_type_id(type_id: String) -> bool:
	var normalized: String = type_id.strip_edges().to_lower()
	return normalized.begins_with("wall_") or normalized == "station_wall" or normalized == "station_wall_door"


static func get_wall_segments_for_tile(tile_data) -> Array:
	if tile_data == null:
		return []
	var type_id: String = _get_tile_object_type_id(tile_data)
	if type_id.is_empty():
		type_id = _get_tile_type_id(tile_data)
	var normalized: String = type_id.strip_edges().to_lower()
	var grid_position: Vector2i = Vector2i(tile_data.grid_position)
	var edges: PackedStringArray = PackedStringArray()
	match normalized:
		"wall_straight_nw":
			edges.append("nw")
		"wall_straight_ne":
			edges.append("ne")
		"wall_straight_se":
			edges.append("se")
		"wall_straight_sw":
			edges.append("sw")
		"wall_corner_nw":
			edges.append("nw")
			edges.append("sw")
		"wall_corner_ne":
			edges.append("nw")
			edges.append("ne")
		"wall_corner_se":
			edges.append("se")
			edges.append("ne")
		"wall_corner_sw":
			edges.append("se")
			edges.append("sw")
	var segments: Array = []
	for edge_id in edges:
		segments.append(_build_edge_segment(grid_position, String(edge_id), normalized))
	return segments


static func does_tile_wall_block_los(tile_data, source_grid_position: Vector2, target_grid_position: Vector2, tolerance: float = WALL_CORNER_TOUCH_TOLERANCE) -> bool:
	if tile_data == null:
		return false
	for segment in get_wall_segments_for_tile(tile_data):
		if does_wall_segment_block_los(source_grid_position, target_grid_position, Dictionary(segment), tolerance):
			return true
	return false


static func does_wall_segment_block_los(source_grid_position: Vector2, target_grid_position: Vector2, segment: Dictionary, tolerance: float = WALL_CORNER_TOUCH_TOLERANCE) -> bool:
	var segment_start: Vector2 = Vector2(segment.get("segment_start", Vector2.ZERO))
	var segment_end: Vector2 = Vector2(segment.get("segment_end", Vector2.ZERO))
	var ray: Vector2 = target_grid_position - source_grid_position
	var wall: Vector2 = segment_end - segment_start
	if ray.length_squared() <= tolerance or wall.length_squared() <= tolerance:
		return false
	var denominator: float = ray.cross(wall)
	if absf(denominator) <= tolerance:
		return false
	var offset: Vector2 = segment_start - source_grid_position
	var ray_t: float = offset.cross(wall) / denominator
	var wall_t: float = offset.cross(ray) / denominator
	return ray_t > tolerance and ray_t < 1.0 - tolerance and wall_t > tolerance and wall_t < 1.0 - tolerance


static func _build_edge_segment(grid_position: Vector2i, edge_id: String, wall_type_id: String) -> Dictionary:
	var center := Vector2(float(grid_position.x), float(grid_position.y))
	var segment_start: Vector2 = center
	var segment_end: Vector2 = center
	match edge_id:
		"nw":
			segment_start = center + Vector2(-0.5, -0.5)
			segment_end = center + Vector2(0.5, -0.5)
		"ne":
			segment_start = center + Vector2(0.5, -0.5)
			segment_end = center + Vector2(0.5, 0.5)
		"se":
			segment_start = center + Vector2(-0.5, 0.5)
			segment_end = center + Vector2(0.5, 0.5)
		"sw":
			segment_start = center + Vector2(-0.5, -0.5)
			segment_end = center + Vector2(-0.5, 0.5)
	return {
		"edge_id": edge_id,
		"wall_type_id": wall_type_id,
		"grid_position": grid_position,
		"segment_start": segment_start,
		"segment_end": segment_end,
		"policy": WALL_LOS_POLICY,
	}


static func _get_tile_type_id(tile_data) -> String:
	if tile_data == null:
		return ""
	return String(tile_data.type_id).strip_edges().to_lower()


static func _get_tile_object_type_id(tile_data) -> String:
	if tile_data == null:
		return ""
	return String(tile_data.object_type_id).strip_edges().to_lower()


static func _is_ground_type_id(type_id: String) -> bool:
	var normalized: String = type_id.strip_edges().to_lower()
	return normalized.is_empty() or normalized == "ground_flat" or normalized.begins_with("ground_") or normalized.begins_with("nature_ground_")
