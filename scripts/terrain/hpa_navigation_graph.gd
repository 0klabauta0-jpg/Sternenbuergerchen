class_name HPANavigationGraph
extends RefCounted

const TERRAIN_PATHFINDER_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HEX_GRID_SCRIPT: GDScript = preload("res://scripts/terrain/hex_grid.gd")

const DEFAULT_CLUSTER_SIZE: int = 8

var cluster_size: int = DEFAULT_CLUSTER_SIZE
var _clusters_by_id: Dictionary = {}
var _component_key_by_grid: Dictionary = {}
var _component_tiles_by_key: Dictionary = {}
var _portals: Array = []
var _portal_ids_seen: Dictionary = {}
var _portals_by_cluster: Dictionary = {}
var _abstract_neighbors_by_component: Dictionary = {}
var _last_build_stats: Dictionary = {}
var _revision: int = 0
var _pathfinder = TERRAIN_PATHFINDER_SCRIPT.new()
var _grid_topology: String = "square8"


func clear() -> void:
	_clusters_by_id.clear()
	_component_key_by_grid.clear()
	_component_tiles_by_key.clear()
	_portals.clear()
	_portal_ids_seen.clear()
	_portals_by_cluster.clear()
	_abstract_neighbors_by_component.clear()
	_last_build_stats.clear()


func build_from_registry(registry, next_cluster_size: int = DEFAULT_CLUSTER_SIZE) -> bool:
	var started_usec: int = Time.get_ticks_usec()
	clear()
	if registry == null or not registry.has_method("get_all_tiles") or not registry.has_method("get_tile_at_grid"):
		_store_build_stats(false, maxi(next_cluster_size, 1), 0, Time.get_ticks_usec() - started_usec, {"incremental": false})
		return false

	cluster_size = maxi(next_cluster_size, 1)
	_grid_topology = String(registry.call("get_grid_topology")) if registry.has_method("get_grid_topology") else "square8"
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
		var walkable: bool = bool(registry.call("is_walkable", grid_position)) if registry.has_method("is_walkable") else bool(tile_data.walkable)
		if walkable:
			var walkable_tiles: Array = Array(cluster.get("walkable_tiles", []))
			walkable_tiles.append(grid_position)
			cluster["walkable_tiles"] = walkable_tiles

	var cluster_ids: Array = get_cluster_ids()
	for cluster_id_variant in cluster_ids:
		_build_cluster_components(Vector2i(cluster_id_variant), registry)

	_build_portals(registry)
	var built: bool = not _clusters_by_id.is_empty()
	_store_build_stats(built, cluster_size, tiles.size(), Time.get_ticks_usec() - started_usec, {"incremental": false})
	if built:
		_revision += 1
	return built


func rebuild_dirty_clusters_from_registry(registry, dirty_grids: Array, next_cluster_size: int = -1) -> bool:
	var started_usec: int = Time.get_ticks_usec()
	if registry == null or not registry.has_method("get_all_tiles") or not registry.has_method("get_tile_at_grid"):
		_store_build_stats(false, cluster_size, 0, Time.get_ticks_usec() - started_usec, {
			"incremental": true,
			"fallback_reason": "invalid_registry",
		})
		return false

	var effective_cluster_size: int = cluster_size
	if next_cluster_size > 0:
		effective_cluster_size = maxi(next_cluster_size, 1)
	var next_topology: String = String(registry.call("get_grid_topology")) if registry.has_method("get_grid_topology") else "square8"
	if _clusters_by_id.is_empty() or effective_cluster_size != cluster_size or next_topology != _grid_topology:
		return build_from_registry(registry, effective_cluster_size)

	var tiles: Array = Array(registry.call("get_all_tiles"))
	var dirty_cluster_lookup: Dictionary = _collect_dirty_cluster_lookup(dirty_grids)
	if dirty_cluster_lookup.is_empty():
		_store_build_stats(true, cluster_size, tiles.size(), Time.get_ticks_usec() - started_usec, {
			"incremental": true,
			"dirty_grid_count": 0,
			"dirty_cluster_count": 0,
			"rebuilt_cluster_count": 0,
		})
		return true

	var rebuild_cluster_lookup: Dictionary = _expand_dirty_cluster_lookup_for_portals(dirty_cluster_lookup)
	_rebuild_clusters_from_registry(registry, rebuild_cluster_lookup)
	_remove_portals_touching_clusters(rebuild_cluster_lookup)
	_build_portals_for_clusters(registry, rebuild_cluster_lookup.keys())
	_portals.sort_custom(_sort_portals)
	_sort_portal_buckets()
	_store_build_stats(true, cluster_size, tiles.size(), Time.get_ticks_usec() - started_usec, {
		"incremental": true,
		"dirty_grid_count": dirty_grids.size(),
		"dirty_cluster_count": dirty_cluster_lookup.size(),
		"rebuilt_cluster_count": rebuild_cluster_lookup.size(),
	})
	_revision += 1
	return true


func get_last_build_stats() -> Dictionary:
	return _last_build_stats.duplicate(true)


func get_revision() -> int:
	return _revision


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


func get_component_tiles(component_key: String) -> Array:
	return Array(_component_tiles_by_key.get(component_key, [])).duplicate()


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
		_component_tiles_by_key[component_key] = component_tiles.duplicate()
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
	var directions: Array = _pathfinder.call("get_neighbor_directions", registry)
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
	_build_portals_for_clusters(registry, cluster_ids)
	_portals.sort_custom(_sort_portals)
	_sort_portal_buckets()


func _build_portals_for_clusters(registry, cluster_ids: Array) -> void:
	var directions: Array = _pathfinder.call("get_neighbor_directions", registry)
	for cluster_id_variant in cluster_ids:
		var cluster_id: Vector2i = Vector2i(cluster_id_variant)
		var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
		var walkable_tiles: Array = Array(cluster.get("walkable_tiles", [])).duplicate()
		walkable_tiles.sort_custom(_sort_vector2i)
		# A one-hex step cannot leave the cluster from its interior.
		var interior := Rect2i(cluster_id * cluster_size + Vector2i.ONE, Vector2i.ONE * maxi(cluster_size - 2, 0))
		for grid_variant in walkable_tiles:
			var from_grid: Vector2i = Vector2i(grid_variant)
			if interior.has_point(from_grid):
				continue
			for direction_variant in directions:
				var to_grid: Vector2i = from_grid + Vector2i(direction_variant)
				var to_cluster_id: Vector2i = get_cluster_id_for_grid(to_grid)
				if to_cluster_id == cluster_id:
					continue
				if not _component_key_by_grid.has(to_grid):
					continue
				if not bool(_pathfinder.call("can_traverse_step", from_grid, to_grid, registry)):
					continue
				_add_portal(from_grid, to_grid, cluster_id, to_cluster_id, registry)


func _add_portal(from_grid: Vector2i, to_grid: Vector2i, from_cluster_id: Vector2i, to_cluster_id: Vector2i, registry) -> void:
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
	var cover_values: PackedFloat32Array = _get_portal_cover_values(canonical_from, canonical_to, registry)
	var portal: Dictionary = {
		"portal_id": portal_id,
		"from_cluster": canonical_from_cluster,
		"to_cluster": canonical_to_cluster,
		"from_grid": canonical_from,
		"to_grid": canonical_to,
		"from_component": from_component,
		"to_component": to_component,
		"mean_cover": float(cover_values[0]),
		"min_cover": float(cover_values[1]),
	}
	_portals.append(portal)
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


func _sort_portal_buckets() -> void:
	for cluster_id in _portals_by_cluster.keys():
		var portals: Array = Array(_portals_by_cluster.get(cluster_id, []))
		portals.sort_custom(_sort_portals)
		_portals_by_cluster[cluster_id] = portals


func _collect_dirty_cluster_lookup(dirty_grids: Array) -> Dictionary:
	var result: Dictionary = {}
	for grid_variant in dirty_grids:
		var grid_position: Variant = _coerce_grid_position(grid_variant)
		if typeof(grid_position) != TYPE_VECTOR2I:
			continue
		var cluster_id: Vector2i = get_cluster_id_for_grid(Vector2i(grid_position))
		result[cluster_id] = true
	return result


func _expand_dirty_cluster_lookup_for_portals(dirty_cluster_lookup: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for cluster_variant in dirty_cluster_lookup.keys():
		var cluster_id: Vector2i = Vector2i(cluster_variant)
		if _clusters_by_id.has(cluster_id):
			result[cluster_id] = true
		var offsets: Array = HEX_GRID_SCRIPT.neighbor_directions() if _grid_topology == HEX_GRID_SCRIPT.TOPOLOGY_ID else [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for offset in offsets:
			var neighbor_cluster_id: Vector2i = cluster_id + offset
			if _clusters_by_id.has(neighbor_cluster_id):
				result[neighbor_cluster_id] = true
		for neighbor_variant in get_neighbor_cluster_ids(cluster_id):
			var neighbor_id: Vector2i = Vector2i(neighbor_variant)
			if _clusters_by_id.has(neighbor_id):
				result[neighbor_id] = true
	return result


func _rebuild_clusters_from_registry(registry, rebuild_cluster_lookup: Dictionary) -> void:
	if rebuild_cluster_lookup.is_empty():
		return
	var tiles_by_cluster: Dictionary = {}
	for cluster_id in rebuild_cluster_lookup.keys():
		tiles_by_cluster[Vector2i(cluster_id)] = []
	for tile_data in Array(registry.call("get_all_tiles")):
		if tile_data == null:
			continue
		var grid_position: Vector2i = Vector2i(tile_data.grid_position)
		var cluster_id: Vector2i = get_cluster_id_for_grid(grid_position)
		if not rebuild_cluster_lookup.has(cluster_id):
			continue
		var cluster_tiles: Array = Array(tiles_by_cluster.get(cluster_id, []))
		cluster_tiles.append(tile_data)
		tiles_by_cluster[cluster_id] = cluster_tiles

	for cluster_variant in rebuild_cluster_lookup.keys():
		var cluster_id: Vector2i = Vector2i(cluster_variant)
		_remove_cluster_component_indices(cluster_id)
		var cluster_tiles: Array = Array(tiles_by_cluster.get(cluster_id, []))
		if cluster_tiles.is_empty():
			_clusters_by_id.erase(cluster_id)
			continue
		cluster_tiles.sort_custom(_sort_tiles_by_grid)
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
		for tile_data in cluster_tiles:
			var grid_position: Vector2i = Vector2i(tile_data.grid_position)
			var tile_positions: Array = Array(cluster.get("tile_positions", []))
			tile_positions.append(grid_position)
			cluster["tile_positions"] = tile_positions
			_update_cluster_bounds(cluster, grid_position)
			var walkable: bool = bool(registry.call("is_walkable", grid_position)) if registry.has_method("is_walkable") else bool(tile_data.walkable)
			if walkable:
				var walkable_tiles: Array = Array(cluster.get("walkable_tiles", []))
				walkable_tiles.append(grid_position)
				cluster["walkable_tiles"] = walkable_tiles
		_clusters_by_id[cluster_id] = cluster
		_build_cluster_components(cluster_id, registry)


func _remove_cluster_component_indices(cluster_id: Vector2i) -> void:
	var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
	if cluster.is_empty():
		return
	var component_by_grid: Dictionary = Dictionary(cluster.get("component_by_grid", {}))
	for grid_variant in component_by_grid.keys():
		_component_key_by_grid.erase(Vector2i(grid_variant))
	for component_variant in Array(cluster.get("components", [])):
		var component: Dictionary = Dictionary(component_variant)
		var component_key: String = String(component.get("component_key", ""))
		if not component_key.is_empty():
			_component_tiles_by_key.erase(component_key)


func _remove_portals_touching_clusters(cluster_lookup: Dictionary) -> void:
	if cluster_lookup.is_empty():
		return
	var retained_portals: Array = []
	for portal_variant in _portals:
		var portal: Dictionary = Dictionary(portal_variant)
		var from_cluster: Vector2i = Vector2i(portal.get("from_cluster", Vector2i.ZERO))
		var to_cluster: Vector2i = Vector2i(portal.get("to_cluster", Vector2i.ZERO))
		if cluster_lookup.has(from_cluster) or cluster_lookup.has(to_cluster):
			continue
		retained_portals.append(portal)
	_portals = retained_portals
	_reindex_portals()


func _reindex_portals() -> void:
	_portal_ids_seen.clear()
	_portals_by_cluster.clear()
	_abstract_neighbors_by_component.clear()
	for cluster_variant in _clusters_by_id.keys():
		var cluster_id: Vector2i = Vector2i(cluster_variant)
		var cluster: Dictionary = Dictionary(_clusters_by_id.get(cluster_id, {}))
		cluster["neighbor_cluster_ids"] = []
		_clusters_by_id[cluster_id] = cluster
	for portal_variant in _portals:
		var portal: Dictionary = Dictionary(portal_variant)
		var portal_id: String = String(portal.get("portal_id", ""))
		if not portal_id.is_empty():
			_portal_ids_seen[portal_id] = true
		var from_cluster: Vector2i = Vector2i(portal.get("from_cluster", Vector2i.ZERO))
		var to_cluster: Vector2i = Vector2i(portal.get("to_cluster", Vector2i.ZERO))
		var from_component: String = String(portal.get("from_component", ""))
		var to_component: String = String(portal.get("to_component", ""))
		_append_unique_to_array(_portals_by_cluster, from_cluster, portal)
		_append_unique_to_array(_portals_by_cluster, to_cluster, portal)
		_append_unique_to_cluster_neighbors(from_cluster, to_cluster)
		_append_unique_to_cluster_neighbors(to_cluster, from_cluster)
		_append_unique_string_neighbor(from_component, to_component)
		_append_unique_string_neighbor(to_component, from_component)


func _coerce_grid_position(value: Variant) -> Variant:
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2i(value)
	if typeof(value) == TYPE_VECTOR2:
		var vector_value: Vector2 = Vector2(value)
		return Vector2i(roundi(vector_value.x), roundi(vector_value.y))
	return null


func _build_component_key(cluster_id: Vector2i, component_index: int) -> String:
	return "%d,%d:%d" % [cluster_id.x, cluster_id.y, component_index]


func _build_portal_id(from_grid: Vector2i, to_grid: Vector2i) -> String:
	return "%d,%d>%d,%d" % [from_grid.x, from_grid.y, to_grid.x, to_grid.y]


func _get_portal_cover_values(from_grid: Vector2i, to_grid: Vector2i, registry) -> PackedFloat32Array:
	var from_cover: float = _get_tile_cover_score(from_grid, registry)
	var to_cover: float = _get_tile_cover_score(to_grid, registry)
	return PackedFloat32Array([(from_cover + to_cover) * 0.5, minf(from_cover, to_cover)])


func _get_tile_cover_score(grid_position: Vector2i, registry) -> float:
	if registry == null or not registry.has_method("get_tile_at_grid"):
		return 0.0
	var tile_data = registry.call("get_tile_at_grid", grid_position)
	if tile_data == null:
		return 0.0
	return clampf(float(tile_data.cover_value) / 100.0, 0.0, 1.0)


func _store_build_stats(built: bool, stats_cluster_size: int, tile_count: int, elapsed_usec: int, extra_stats: Dictionary = {}) -> void:
	_last_build_stats = {
		"built": built,
		"cluster_size": stats_cluster_size,
		"tile_count": tile_count,
		"cluster_count": _clusters_by_id.size(),
		"component_count": get_component_count(),
		"portal_count": _portals.size(),
		"elapsed_usec": maxi(elapsed_usec, 0),
	}
	for key in extra_stats.keys():
		_last_build_stats[key] = extra_stats[key]


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
