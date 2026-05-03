class_name MapEditorMarkerTool
extends RefCounted


static func find_marker_id_at_world_position(terrain_map_data, world_position: Vector2, pick_radius: float) -> String:
	if terrain_map_data == null:
		return ""
	var best_marker_id: String = ""
	var best_distance_sq: float = pick_radius * pick_radius
	for marker_id in PackedStringArray(terrain_map_data.call("get_marker_ids")):
		var marker_position: Vector2 = terrain_map_data.call("get_marker_position", marker_id, Vector2.ZERO)
		var distance_sq: float = marker_position.distance_squared_to(world_position)
		if distance_sq > best_distance_sq:
			continue
		best_distance_sq = distance_sq
		best_marker_id = String(marker_id)
	return best_marker_id


static func can_place_marker_at_world_position(terrain_map_data, marker_id: String, world_position: Vector2) -> bool:
	if terrain_map_data == null:
		return false
	for other_marker_id in PackedStringArray(terrain_map_data.call("get_marker_ids")):
		if String(other_marker_id) == marker_id:
			continue
		if marker_positions_equal(world_position, Vector2(terrain_map_data.call("get_marker_position", other_marker_id, Vector2.ZERO))):
			return false
	return true


static func find_first_available_marker_world_position(terrain_map_data, preferred_tile_position, ignore_marker_id: String = ""):
	if preferred_tile_position != null and can_place_marker_at_world_position(terrain_map_data, ignore_marker_id, Vector2(preferred_tile_position)):
		return Vector2(preferred_tile_position)
	if terrain_map_data == null:
		return null
	for tile_data in terrain_map_data.call("get_tiles"):
		if tile_data == null:
			continue
		if can_place_marker_at_world_position(terrain_map_data, ignore_marker_id, Vector2(tile_data.world_position)):
			return Vector2(tile_data.world_position)
	return null


static func marker_positions_equal(a: Vector2, b: Vector2) -> bool:
	return a.distance_squared_to(b) <= 1.0
