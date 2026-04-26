class_name HPANavigationGraph
extends RefCounted

const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")

const DEFAULT_CLUSTER_SIZE: int = 8

var cluster_size: int = DEFAULT_CLUSTER_SIZE
var _clusters_by_id: Dictionary = {}
var _component_key_by_grid: Dictionary = {}
var _portals: Array = []
var _portal_ids_seen: Dictionary = {}
var _portals_by_cluster: Dictionary = {}
var _abstract_neighbors_by_component: Dictionary = {}
var _pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()


func clear() -> void:
	_clusters_by_id.clear()
	_component_key_by_grid.clear()
	_portals.clear()
	_portal_ids_seen.clear()
	_portals_by_cluster.clear()
	_abstract_neighbors_by_component.clear()


func build_from_registry(registry, next_cluster_size: int = DEFAULT_CLUSTER_SIZE) -> bool:
	clear()
	if registry == null or not registry.has_method("get_all_tiles") or not registry.has_method("get_tile_at_grid"):
		return false

	cluster_size = maxi(next_cluster_size, 1)
	var tiles: Array = Array(registry.call("get_all_tiles"))
	tiles.sort_custom(_sort_tiles_by_grid)
	for tile_data in tiles:
		if tile_data == null:
			continue
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		var cluster_id: Vector2i = get_cluster_id_for_grid(grid_position)
		var cluster: Dictionary = _get_or_create_cluster(cluster_id)
		var tile_positions: Array = Array(cluster.get("tile_positions", []))
		tile_positions.append(grid_position)
		cluster["tile_positions"] = tile_positions
		_update_cluster_bounds(cluster, grid_position)
		if bool(tile_data.walkable):
			var walkable_tiles: Array = Array(cluster.get("walkable_tiles", []))
			walkable_tiles.append(grid_position)
			cluster["walkable_tiles"] = walkable_tiles

	var cluster_ids: Array = get_cluster_ids()
	for cluster_id_variant in cluster_ids:
		_build_cluster_components(Vector2i(cluster_id_variant), registry)

	_build_portals(registry)
	return not _clusters_by_id.is_empty()


func get_cluster_id_for_grid(grid_position: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(grid_position.x) / float(cluster_size)),
		floori(float(grid_position.y) / float(cluster_size))
	)


func get_cluster_ids() -> Array:
	var cluster_ids: Array = _clusters_by_id.keys()
	cluster_ids.sort_custom(_sort_vector2i)
	return cluster_ids


func get_cluster_snapshot(cluster_id: Vector2i) -> Dictionary:
	if not _clusters_by_id.has(cluster_id):
		return {}
	return Dictionary(_clusters_by_id[cluster_id]).duplicate(true)


func get_neighbor_cluster_ids(cluster_id: Vector2i) -> Array:
	var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
	var neighbor_ids: Array = Array(cluster.get("neighbor_cluster_ids", [])).duplicate()
	neighbor_ids.sort_custom(_sort_vector2i)
	return neighbor_ids


func get_portals_snapshot() -> Array:
	return _portals.duplicate(true)


func get_portals_for_cluster(cluster_id: Vector2i) -> Array:
	return Array(_portals_by_cluster.get(cluster_id, [])).duplicate(true)


func get_component_key_for_grid(grid_position: Vector2i) -> String:
	return String(_component_key_by_grid.get(grid_position, ""))


func are_grids_in_same_component(a_grid: Vector2i, b_grid: Vector2i) -> bool:
	var a_key: String = get_component_key_for_grid(a_grid)
	if a_key.is_empty():
		return false
	return a_key == get_component_key_for_grid(b_grid)


func get_abstract_neighbors(component_key: String) -> Array:
	var neighbors: Array = Array(_abstract_neighbors_by_component.get(component_key, [])).duplicate()
	neighbors.sort()
	return neighbors


func get_component_count() -> int:
	var keys: Array = _component_key_by_grid.values()
	var seen: Dictionary = {}
	for key_variant in keys:
		seen[String(key_variant)] = true
	return seen.size()


func _get_or_create_cluster(cluster_id: Vector2i) -> Dictionary:
	if _clusters_by_id.has(cluster_id):
		return _clusters_by_id[cluster_id]

	var cluster: Dictionary = {
		"cluster_id": cluster_id,
		"min_grid": Vector2i(cluster_id.x * cluster_size, cluster_id.y * cluster_size),
		"max_grid": Vector2i(cluster_id.x * cluster_size, cluster_id.y * cluster_size),
		"tile_positions": [],
		"walkable_tiles": [],
		"components": [],
		"component_by_grid": {},
		"neighbor_cluster_ids": [],
	}
	_clusters_by_id[cluster_id] = cluster
	return cluster


func _update_cluster_bounds(cluster: Dictionary, grid_position: Vector2i) -> void:
	var min_grid: Vector2i = Vector2i(cluster.get("min_grid", grid_position))
	var max_grid: Vector2i = Vector2i(cluster.get("max_grid", grid_position))
	cluster["min_grid"] = Vector2i(mini(min_grid.x, grid_position.x), mini(min_grid.y, grid_position.y))
	cluster["max_grid"] = Vector2i(maxi(max_grid.x, grid_position.x), maxi(max_grid.y, grid_position.y))


func _build_cluster_components(cluster_id: Vector2i, registry) -> void:
	var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
	if cluster.is_empty():
		return

	var walkable_tiles: Array = Array(cluster.get("walkable_tiles", [])).duplicate()
	walkable_tiles.sort_custom(_sort_vector2i)
	var walkable_set: Dictionary = {}
	for grid_variant in walkable_tiles:
		walkable_set[Vector2i(grid_variant)] = true

	var visited: Dictionary = {}
	var components: Array = []
	var component_by_grid: Dictionary = {}
	var component_index: int = 0
	for grid_variant in walkable_tiles:
		var start_grid: Vector2i = Vector2i(grid_variant)
		if visited.has(start_grid):
			continue

		var component_tiles: Array = _collect_component_tiles(start_grid, cluster_id, walkable_set, visited, registry)
		component_tiles.sort_custom(_sort_vector2i)
		var component_key: String = _build_component_key(cluster_id, component_index)
		for component_grid_variant in component_tiles:
			var component_grid: Vector2i = Vector2i(component_grid_variant)
			component_by_grid[component_grid] = component_key
			_component_key_by_grid[component_grid] = component_key
		components.append({
			"component_id": component_index,
			"component_key": component_key,
			"cluster_id": cluster_id,
			"tile_positions": component_tiles,
		})
		component_index += 1

	cluster["components"] = components
	cluster["component_by_grid"] = component_by_grid
	_clusters_by_id[cluster_id] = cluster


func _collect_component_tiles(start_grid: Vector2i, cluster_id: Vector2i, walkable_set: Dictionary, visited: Dictionary, registry) -> Array:
	var result: Array = []
	var queue: Array = [start_grid]
	visited[start_grid] = true
	var directions: Array = _pathfinder.call("get_neighbor_directions")
	while not queue.is_empty():
		var current: Vector2i = Vector2i(queue.pop_front())
		result.append(current)
		for direction_variant in directions:
			var neighbor: Vector2i = current + Vector2i(direction_variant)
			if visited.has(neighbor) or not walkable_set.has(neighbor):
				continue
			if get_cluster_id_for_grid(neighbor) != cluster_id:
				continue
			if not bool(_pathfinder.call("can_traverse_step", current, neighbor, registry)):
				continue
			visited[neighbor] = true
			queue.append(neighbor)
	return result


func _build_portals(registry) -> void:
	var cluster_ids: Array = get_cluster_ids()
	var directions: Array = _pathfinder.call("get_neighbor_directions")
	for cluster_id_variant in cluster_ids:
		var cluster_id: Vector2i = Vector2i(cluster_id_variant)
		var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
		var walkable_tiles: Array = Array(cluster.get("walkable_tiles", [])).duplicate()
		walkable_tiles.sort_custom(_sort_vector2i)
		for grid_variant in walkable_tiles:
			var from_grid: Vector2i = Vector2i(grid_variant)
			for direction_variant in directions:
				var to_grid: Vector2i = from_grid + Vector2i(direction_variant)
				var to_cluster_id: Vector2i = get_cluster_id_for_grid(to_grid)
				if to_cluster_id == cluster_id:
					continue
				if not _component_key_by_grid.has(to_grid):
					continue
				if not bool(_pathfinder.call("can_traverse_step", from_grid, to_grid, registry)):
					continue
				_add_portal(from_grid, to_grid, cluster_id, to_cluster_id)


func _add_portal(from_grid: Vector2i, to_grid: Vector2i, from_cluster_id: Vector2i, to_cluster_id: Vector2i) -> void:
	var canonical_from: Vector2i = from_grid
	var canonical_to: Vector2i = to_grid
	var canonical_from_cluster: Vector2i = from_cluster_id
	var canonical_to_cluster: Vector2i = to_cluster_id
	if _compare_vector2i(canonical_to_cluster, canonical_from_cluster) < 0 or (canonical_to_cluster == canonical_from_cluster and _compare_vector2i(canonical_to, canonical_from) < 0):
		canonical_from = to_grid
		canonical_to = from_grid
		canonical_from_cluster = to_cluster_id
		canonical_to_cluster = from_cluster_id

	var portal_id: String = _build_portal_id(canonical_from, canonical_to)
	if _portal_ids_seen.has(portal_id):
		return
	_portal_ids_seen[portal_id] = true

	var from_component: String = get_component_key_for_grid(canonical_from)
	var to_component: String = get_component_key_for_grid(canonical_to)
	var portal: Dictionary = {
		"portal_id": portal_id,
		"from_cluster": canonical_from_cluster,
		"to_cluster": canonical_to_cluster,
		"from_grid": canonical_from,
		"to_grid": canonical_to,
		"from_component": from_component,
		"to_component": to_component,
	}
	_portals.append(portal)
	_portals.sort_custom(_sort_portals)
	_append_unique_to_array(_portals_by_cluster, canonical_from_cluster, portal)
	_append_unique_to_array(_portals_by_cluster, canonical_to_cluster, portal)
	_append_unique_to_cluster_neighbors(canonical_from_cluster, canonical_to_cluster)
	_append_unique_to_cluster_neighbors(canonical_to_cluster, canonical_from_cluster)
	_append_unique_string_neighbor(from_component, to_component)
	_append_unique_string_neighbor(to_component, from_component)


func _append_unique_to_array(target: Dictionary, key: Variant, value: Variant) -> void:
	var values: Array = Array(target.get(key, []))
	if not values.has(value):
		values.append(value)
	target[key] = values


func _append_unique_to_cluster_neighbors(cluster_id: Vector2i, neighbor_cluster_id: Vector2i) -> void:
	var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
	if cluster.is_empty():
		return
	var neighbors: Array = Array(cluster.get("neighbor_cluster_ids", []))
	if not neighbors.has(neighbor_cluster_id):
		neighbors.append(neighbor_cluster_id)
	neighbors.sort_custom(_sort_vector2i)
	cluster["neighbor_cluster_ids"] = neighbors
	_clusters_by_id[cluster_id] = cluster


func _append_unique_string_neighbor(component_key: String, neighbor_component_key: String) -> void:
	if component_key.is_empty() or neighbor_component_key.is_empty():
		return
	var neighbors: Array = Array(_abstract_neighbors_by_component.get(component_key, []))
	if not neighbors.has(neighbor_component_key):
		neighbors.append(neighbor_component_key)
	neighbors.sort()
	_abstract_neighbors_by_component[component_key] = neighbors


func _build_component_key(cluster_id: Vector2i, component_index: int) -> String:
	return "%d,%d:%d" % [cluster_id.x, cluster_id.y, component_index]


func _build_portal_id(from_grid: Vector2i, to_grid: Vector2i) -> String:
	return "%d,%d>%d,%d" % [from_grid.x, from_grid.y, to_grid.x, to_grid.y]


func _sort_tiles_by_grid(a, b) -> bool:
	return _sort_vector2i(Vector2i(a.grid_position), Vector2i(b.grid_position))


func _sort_vector2i(a, b) -> bool:
	var grid_a: Vector2i = Vector2i(a)
	var grid_b: Vector2i = Vector2i(b)
	if grid_a.x == grid_b.x:
		return grid_a.y < grid_b.y
	return grid_a.x < grid_b.x


func _sort_portals(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("portal_id", "")) < String(b.get("portal_id", ""))


func _compare_vector2i(a: Vector2i, b: Vector2i) -> int:
	if a.x < b.x:
		return -1
	if a.x > b.x:
		return 1
	if a.y < b.y:
		return -1
	if a.y > b.y:
		return 1
	return 0
