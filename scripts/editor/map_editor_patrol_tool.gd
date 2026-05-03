class_name MapEditorPatrolTool
extends RefCounted


static func find_waypoint_index_at(terrain_map_data, spawn_id: String, world_position: Vector2, pick_radius: float) -> int:
	if terrain_map_data == null or spawn_id.strip_edges().is_empty():
		return -1
	var patrol_path: Array = Array(terrain_map_data.call("get_patrol_path", spawn_id.strip_edges()))
	var best_index: int = -1
	var best_dist_sq: float = pick_radius * pick_radius
	for index in range(patrol_path.size()):
		var waypoint_position: Vector2 = Vector2(patrol_path[index])
		var dist_sq: float = waypoint_position.distance_squared_to(world_position)
		if dist_sq > best_dist_sq:
			continue
		best_dist_sq = dist_sq
		best_index = index
	return best_index


static func add_waypoint(terrain_map_data, spawn_id: String, world_position: Vector2) -> bool:
	if terrain_map_data == null or spawn_id.strip_edges().is_empty():
		return false
	var patrol_path: Array = Array(terrain_map_data.call("get_patrol_path", spawn_id.strip_edges()))
	patrol_path.append(world_position)
	terrain_map_data.call("set_patrol_path", spawn_id.strip_edges(), patrol_path)
	return true


static func move_waypoint(terrain_map_data, spawn_id: String, index: int, world_position: Vector2) -> bool:
	if terrain_map_data == null or spawn_id.strip_edges().is_empty():
		return false
	var patrol_path: Array = Array(terrain_map_data.call("get_patrol_path", spawn_id.strip_edges()))
	if index < 0 or index >= patrol_path.size():
		return false
	patrol_path[index] = world_position
	terrain_map_data.call("set_patrol_path", spawn_id.strip_edges(), patrol_path)
	return true


static func remove_waypoint(terrain_map_data, spawn_id: String, index: int) -> bool:
	if terrain_map_data == null or spawn_id.strip_edges().is_empty():
		return false
	var patrol_path: Array = Array(terrain_map_data.call("get_patrol_path", spawn_id.strip_edges()))
	if index < 0 or index >= patrol_path.size():
		return false
	patrol_path.remove_at(index)
	terrain_map_data.call("set_patrol_path", spawn_id.strip_edges(), patrol_path)
	return true
