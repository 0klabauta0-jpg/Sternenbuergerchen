class_name HexCorridorTopologyCache
extends RefCounted

## Derived terrain data only. No occupancy, NPC identity, clocks or promises.
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const MAX_NEW_NODES:int = 64
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")

var _registry_ref:WeakRef
var _registry_id:int = 0
var _terrain_revision:int = -1
var _neighbors:Dictionary = {}
var _resolved:Dictionary = {}
var _walkable:Dictionary = {}
var _incoming:Dictionary = {}
var _corridor_by_grid:Dictionary = {}
var _corridors:Dictionary = {}
var _pending_origins:Dictionary = {}
var _origin_queue:Array = []
var _origin_cursor:int = 0
var _job:Dictionary = {}
var _next_component_id:int = 0


func query(registry:Node, grid_points:Array, node_budget:int=64)->Dictionary:
	# Validate before changing the previous valid cache/context.
	if not is_instance_valid(registry): return _failure("invalid_registry")
	for method in ["get_grid_topology", "get_revision", "is_walkable"]:
		if not registry.has_method(method): return _failure("missing_registry_api")
	if not registry.has_method("get_legal_hex_neighbors") and not registry.has_method("get_tile_at_grid"): return _failure("missing_registry_api")
	if registry.call("get_grid_topology") != HEX.TOPOLOGY_ID: return _failure("invalid_topology")
	var revision:Variant = registry.call("get_revision")
	if not revision is int or revision < 0: return _failure("invalid_revision")
	for grid in grid_points:
		if not grid is Vector2i: return _failure("invalid_grid")
	var identity:int = registry.get_instance_id()
	if _registry_ref == null or _registry_ref.get_ref() != registry or _terrain_revision != revision:
		_reset()
		_registry_ref = weakref(registry)
		_registry_id = identity
		_terrain_revision = revision
	for grid in grid_points:
		if not _resolved.has(grid) and not _pending_origins.has(grid):
			_pending_origins[grid] = true
			_origin_queue.append(grid)
	var budget:int = clampi(node_budget, 0, MAX_NEW_NODES)
	var processed:int = 0
	var completed:Array = []
	while true:
		if _job.is_empty() and not _start_next_job(): break
		if int(_job.cursor) >= _job.queue.size():
			var component_id:int = _finish_job()
			if component_id >= 0: completed.append(component_id)
			continue
		var current:Vector2i = _job.queue[_job.cursor]
		if not _neighbors.has(current):
			if processed >= budget: break
			var walkable:Variant = registry.call("is_walkable", current)
			if not walkable is bool:
				_reset()
				return _failure("invalid_walkability", processed)
			var legal:Variant = _read_legal_neighbors(registry,current) if walkable else []
			processed += 1
			if not _valid_neighbors(current, legal):
				_reset()
				return _failure("invalid_neighbors", processed)
			_neighbors[current] = legal.duplicate()
			_walkable[current] = walkable
			for neighbor in legal:
				if not _incoming.has(neighbor): _incoming[neighbor] = []
				_incoming[neighbor].append(current)
		# No partial component is ever placed in _resolved or _corridors.
		_job.cursor += 1
		var neighbors:Array = _neighbors[current]
		if not _walkable[current] or neighbors.size() > 2:
			_resolved[current] = true
			_pending_origins.erase(current)
			continue
		_job.members[current] = true
		for neighbor in neighbors:
			if not _job.queued.has(neighbor):
				_job.queued[neighbor] = true
				_job.queue.append(neighbor)
	# A mutation during a callback invalidates every partial/finished derived fact.
	if not is_instance_valid(registry) or registry.get_instance_id() != identity or registry.call("get_revision") != revision:
		_reset()
		return _failure("registry_changed", processed)
	var result_ids:Dictionary = {}
	for component_id in completed: result_ids[component_id] = true
	for grid in grid_points:
		if _corridor_by_grid.has(grid): result_ids[_corridor_by_grid[grid]] = true
	var result:Array = []
	for component_id in result_ids:
		result.append(_corridors[component_id].duplicate(true))
	return {"ok":true, "complete":_pending_origins.is_empty() and _job.is_empty(),
		"registry_id":_registry_id, "terrain_revision":_terrain_revision,
		"corridors":result, "pending_grid_points":_pending_origins.keys().duplicate(),
		"processed_nodes":processed}


func _start_next_job()->bool:
	while _origin_cursor < _origin_queue.size():
		var origin:Vector2i = _origin_queue[_origin_cursor]
		_origin_cursor += 1
		if not _pending_origins.has(origin): continue
		_job = {"origin":origin, "queue":[origin], "queued":{origin:true}, "cursor":0, "members":{}}
		return true
	# Retain only unfinished origins rather than an ever-growing consumed queue.
	_origin_queue.clear()
	_origin_cursor = 0
	return false


func _finish_job()->int:
	var members:Dictionary = _job.members
	if members.is_empty():
		_pending_origins.erase(_job.origin)
		_job.clear()
		return -1
	var endpoints:Array = []
	for grid in members:
		var internal_degree:int = 0
		for neighbor in _neighbors[grid]:
			if members.has(neighbor): internal_degree += 1
		if internal_degree < 2: endpoints.append(grid)
	endpoints.sort_custom(_grid_less)
	var is_cycle:bool = endpoints.is_empty()
	var ordered:Array = []
	var visited:Dictionary = {}
	var all_cells:Array = members.keys()
	all_cells.sort_custom(_grid_less)
	var current:Vector2i = all_cells[0] if is_cycle else endpoints[0]
	while not visited.has(current):
		ordered.append(current)
		visited[current] = true
		var available:Array = []
		for neighbor in _neighbors[current]:
			if members.has(neighbor) and not visited.has(neighbor): available.append(neighbor)
		if available.is_empty(): break
		available.sort_custom(_grid_less)
		current = available[0]
	var component_id:int = _next_component_id
	_next_component_id += 1
	_corridors[component_id] = {"cells":ordered, "endpoints":endpoints,
		"is_cycle":is_cycle, "directed":not is_cycle and ordered.size()>1}
	for grid in members:
		_resolved[grid] = true
		_corridor_by_grid[grid] = component_id
		_pending_origins.erase(grid)
	_job.clear()
	return component_id


func _valid_neighbors(origin:Vector2i, values:Variant)->bool:
	if not values is Array or values.size() > 6: return false
	var seen:Dictionary = {}
	for grid in values:
		if not grid is Vector2i or not HEX.are_neighbors(origin,grid) or seen.has(grid): return false
		seen[grid] = true
		if _neighbors.has(grid) and not _neighbors[grid].has(origin): return false
	for source in _incoming.get(origin,[]):
		if not seen.has(source): return false
	return true


func _reset()->void:
	_registry_ref = null
	_registry_id = 0
	_terrain_revision = -1
	_neighbors.clear()
	_walkable.clear()
	_incoming.clear()
	_resolved.clear()
	_corridor_by_grid.clear()
	_corridors.clear()
	_pending_origins.clear()
	_origin_queue.clear()
	_origin_cursor = 0
	_job.clear()
	_next_component_id = 0


func _failure(reason:String,processed:int=0)->Dictionary:
	return {"ok":false, "complete":false, "reason":reason, "registry_id":_registry_id,
		"terrain_revision":_terrain_revision, "corridors":[],
		"pending_grid_points":[], "processed_nodes":processed}


static func _grid_less(a:Vector2i,b:Vector2i)->bool:
	return a.x < b.x or (a.x == b.x and a.y < b.y)


func _read_legal_neighbors(registry:Node,grid:Vector2i)->Variant:
	if registry.has_method("get_legal_hex_neighbors"):
		return registry.call("get_legal_hex_neighbors",grid)
	var result:Array[Vector2i] = []
	var from = registry.call("get_tile_at_grid",grid)
	for direction in HEX.DIRECTIONS:
		var next:Vector2i = grid+direction
		if not registry.call("is_walkable",next): continue
		var to = registry.call("get_tile_at_grid",next)
		if TILE.allows_registry_step(from,to,true,true) and TILE.allows_registry_step(to,from,true,true): result.append(next)
	return result
