class_name NativeNavigation
extends RefCounted

## Runtime navigation backend. Registry and HPA graph remain authoritative.
## Terrain and graph snapshots survive option changes. Query-dependent costs
## are evaluated lazily by C++; unchanged GDScript is the differential oracle.
const PATH_SCRIPT = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_SCRIPT = preload("res://scripts/terrain/hpa_pathfinder.gd")
const REGISTRY_SCRIPT = preload("res://scripts/terrain/terrain_registry.gd")
const RESULT_CACHE_LIMIT: int = 64
var _oracle = PATH_SCRIPT.new()
var _fallback_hpa = HPA_SCRIPT.new()
var _kernel: Object
var _terrain_builder: Object
var native_terrain_builder_enabled: bool = true
var _prepared_registry_ref: WeakRef
var _prepared_graph_ref: WeakRef
var _prepared_registry_revision: int = -1
var _prepared_graph_revision: int = -1
var _graph_registry_ref: WeakRef
var _graph_registry_revision: int = -1
var _terrain_grids: Array = []
var _graph_data: Dictionary = {}
var _snapshot_build_count: int = 0
var _graph_build_count: int = 0
var _option_prepare_count: int = 0
var _result_cache: Dictionary = {}
var _result_fifo: Array[String] = []
var _cache_registry_ref: WeakRef
var _cache_graph_ref: WeakRef
var _cache_registry_revision: int = -1
var _cache_graph_revision: int = -1
var _debug: Dictionary = {}


class RegionalSearch:
	extends RefCounted
	var source: Vector2i
	var goal: Vector2i
	var revision: int
	var registry_id: int
	var options: Dictionary
	var cost_options: Dictionary
	var finished: bool = false
	var invalidated: bool = false
	var path: Array = []
	var expanded_count: int = 0
	var started_usec: int = Time.get_ticks_usec()
	var last_slice_usec: int = 0
	var work_usec: int = 0
	var max_slice_usec: int = 0
	var backend: String = "native"
	var fallback_reason: String = ""
	var _native_search: Object
	var _last_native_debug: Dictionary = {}

	func _init(native_search: Object, start: Vector2i, target: Vector2i, registry, query_options: Dictionary) -> void:
		_native_search = native_search
		source = start
		goal = target
		revision = int(registry.call("get_revision"))
		registry_id = registry.get_instance_id()
		options = query_options.duplicate(true)
		cost_options = query_options.duplicate(true)

	func advance(_pathfinder, registry, expansion_limit: int) -> int:
		if not is_instance_valid(registry) or registry.get_instance_id() != registry_id or int(registry.call("get_revision")) != revision:
			finished = true
			invalidated = true
			path.clear()
			fallback_reason = "regional_registry_changed"
			return 0
		_last_native_debug = _native_search.call("advance", expansion_limit)
		finished = bool(_last_native_debug.finished)
		invalidated = bool(_last_native_debug.invalidated)
		expanded_count = int(_last_native_debug.expanded_count)
		path = Array(_last_native_debug.path).duplicate()
		if invalidated:
			fallback_reason = "regional_snapshot_changed"
		return int(_last_native_debug.used)

	func get_debug_snapshot() -> Dictionary:
		var result: Dictionary = _last_native_debug.duplicate(true)
		result["backend"] = backend
		result["fallback_reason"] = fallback_reason
		return result


func _init() -> void:
	if ClassDB.class_exists("NativeNavigationKernel"):
		_kernel = ClassDB.instantiate("NativeNavigationKernel")
	if ClassDB.class_exists("NativeTerrainBuilder"):
		_terrain_builder = ClassDB.instantiate("NativeTerrainBuilder")
	_reset_debug()


func _reset_debug() -> void:
	_debug = {"last_backend": "none", "fallback_reason": "", "result_cache_hit": false,
		"snapshot_prepare_usec": 0, "native_query_usec": 0, "snapshot_reused": false,
		"terrain_prepare_usec": 0, "graph_prepare_usec": 0, "options_prepare_usec": 0,
		"graph_reused": false, "terrain_builder": "reused", "terrain_extract_usec": 0,
		"terrain_edges_usec": 0, "terrain_load_usec": 0}


func get_debug_snapshot() -> Dictionary:
	var result: Dictionary = _debug.duplicate(true)
	result["snapshot_build_count"] = _snapshot_build_count
	result["graph_build_count"] = _graph_build_count
	result["option_prepare_count"] = _option_prepare_count
	if is_instance_valid(_kernel) and _kernel.has_method("get_query_debug"):
		result.merge(_kernel.call("get_query_debug"), false)
	if bool(result.get("result_cache_hit", false)) or result.get("last_backend") == "gdscript_fallback":
		result["target_cost_compute_count"] = 0
		result["edge_cost_compute_count"] = 0
	result["result_cache_entry_count"] = _result_cache.size()
	result["result_cache_limit"] = RESULT_CACHE_LIMIT
	result["native_available"] = is_instance_valid(_kernel)
	return result


func clear_result_cache() -> void:
	_result_cache.clear()
	_result_fifo.clear()


func clear_prepared_data() -> void:
	clear_result_cache()
	_prepared_registry_ref = null
	_prepared_graph_ref = null
	_graph_registry_ref = null
	_cache_registry_ref = null
	_cache_graph_ref = null
	_prepared_registry_revision = -1
	_prepared_graph_revision = -1
	_graph_registry_revision = -1
	_cache_registry_revision = -1
	_cache_graph_revision = -1
	_terrain_grids.clear()
	_graph_data.clear()
	if is_instance_valid(_kernel):
		# Rejected empty load deliberately releases the previous native snapshot.
		_kernel.call("load_snapshot", {})
	_reset_debug()


func _reject(reason: String, clear_snapshot: bool = true) -> bool:
	_debug["fallback_reason"] = reason
	if clear_snapshot:
		_prepared_registry_ref = null
		_prepared_graph_ref = null
		_graph_registry_ref = null
		_terrain_grids.clear()
		_graph_data.clear()
	return false


func _valid_registry(registry) -> bool:
	return is_instance_valid(registry) and registry.has_method("get_revision") and typeof(registry.call("get_revision")) == TYPE_INT and registry.has_method("get_all_tiles") and registry.has_method("get_tile_at_grid") and registry.has_method("is_walkable")


func _valid_graph(graph) -> bool:
	return is_instance_valid(graph) and graph.has_method("get_revision") and typeof(graph.call("get_revision")) == TYPE_INT and graph.has_method("get_component_tiles") and graph.has_method("get_component_key_for_grid") and graph.has_method("get_portals_snapshot")


func _referent(reference: WeakRef):
	return reference.get_ref() if reference != null else null


func _normalized_options(options: Dictionary) -> Dictionary:
	var normalized: Dictionary = options.duplicate(false)
	normalized.erase("diagnostics")
	normalized.erase(PATH_SCRIPT.STEP_COST_CONTEXT_OPTION)
	return normalized


func prepare(registry, options: Dictionary = {}, graph = null) -> bool:
	_reset_debug()
	var started: int = Time.get_ticks_usec()
	var prepared: bool = _prepare_snapshot(registry, options, graph)
	_debug["snapshot_prepare_usec"] = Time.get_ticks_usec() - started
	return prepared


func _prepare_snapshot(registry, options: Dictionary, graph) -> bool:
	_debug["fallback_reason"] = ""
	if typeof(options.get("diagnostics")) == TYPE_DICTIONARY:
		return _reject("diagnostics_require_gdscript", false)
	if not is_instance_valid(_kernel):
		return _reject("native_extension_unavailable")
	if not _kernel.has_method("load_terrain") or not _kernel.has_method("begin_query"):
		return _reject("native_extension_api_mismatch")
	if not _valid_registry(registry):
		return _reject("unsupported_registry")
	if graph != null and not _valid_graph(graph):
		return _reject("unsupported_graph")
	var normalized: Dictionary = _normalized_options(options)
	if not bool(_fallback_hpa.call("_is_result_cache_value_supported", normalized)):
		return _reject("unsupported_or_nonfinite_options", false)
	var registry_revision: int = int(registry.call("get_revision"))
	var graph_revision: int = int(graph.call("get_revision")) if graph != null else -1
	var terrain_reused: bool = _referent(_prepared_registry_ref) == registry and _prepared_registry_revision == registry_revision
	_debug["snapshot_reused"] = terrain_reused
	if not terrain_reused:
		var terrain_started: int = Time.get_ticks_usec()
		if not _load_terrain(registry):
			return false
		_debug["terrain_prepare_usec"] = Time.get_ticks_usec() - terrain_started
		_prepared_registry_ref = weakref(registry)
		_prepared_registry_revision = registry_revision
		_snapshot_build_count += 1
	if graph != null:
		var graph_reused: bool = _referent(_prepared_graph_ref) == graph and _prepared_graph_revision == graph_revision and _referent(_graph_registry_ref) == registry and _graph_registry_revision == registry_revision
		_debug["graph_reused"] = graph_reused
		if not graph_reused:
			var graph_started: int = Time.get_ticks_usec()
			var component_by_grid: Dictionary = {}
			var component_tiles: Dictionary = {}
			for grid in _terrain_grids:
				var key: String = String(graph.call("get_component_key_for_grid", grid))
				component_by_grid[grid] = key
				if not key.is_empty() and not component_tiles.has(key):
					component_tiles[key] = graph.call("get_component_tiles", key)
			var adjacency: Dictionary = _fallback_hpa.call("_build_portal_adjacency", graph)
			for key in adjacency:
				Array(adjacency[key]).sort_custom(Callable(_fallback_hpa, "_sort_edges"))
			_graph_data = {"component_by_grid": component_by_grid, "component_tiles": component_tiles,
				"adjacency": adjacency, "portals": graph.call("get_portals_snapshot")}
			_prepared_graph_ref = weakref(graph)
			_prepared_graph_revision = graph_revision
			_graph_registry_ref = weakref(registry)
			_graph_registry_revision = registry_revision
			_graph_build_count += 1
			_debug["graph_prepare_usec"] = Time.get_ticks_usec() - graph_started
		# Pruning remains query-dependent even though geometry is retained.
		_graph_data["minimum_step_cost"] = _fallback_hpa.call("_minimum_local_step_cost", normalized)
	if int(registry.call("get_revision")) != registry_revision or (graph != null and int(graph.call("get_revision")) != graph_revision):
		return _reject("revision_changed_during_snapshot")
	var options_started: int = Time.get_ticks_usec()
	if not bool(_kernel.call("begin_query", normalized)):
		return _reject("native_query_options_rejected", false)
	_option_prepare_count += 1
	_debug["options_prepare_usec"] = Time.get_ticks_usec() - options_started
	return true


func _load_terrain(registry) -> bool:
	var phase_started: int = Time.get_ticks_usec()
	var tiles: Array = registry.call("get_all_tiles")
	var grid_ids: Dictionary = {}
	var coords := PackedInt32Array()
	var walkable := PackedByteArray()
	var cover := PackedFloat64Array()
	var blocks_los := PackedByteArray()
	var heights := PackedInt32Array()
	var stand_heights := PackedFloat64Array()
	var object_heights := PackedInt32Array()
	var surface_costs := PackedFloat64Array()
	var traits := PackedByteArray()
	var ramp_directions := PackedInt32Array()
	# Duck readers and derived registries may supply different effective geometry
	# through get_tile_at_grid than through enumeration. Keep their original calls.
	var builder_supported: bool = native_terrain_builder_enabled and is_instance_valid(_terrain_builder) \
		and _terrain_builder.has_method("build_edges") and registry.get_script() == REGISTRY_SCRIPT
	_terrain_grids.clear()
	for tile in tiles:
		var grid: Vector2i = Vector2i(tile.grid_position)
		if absi(grid.x) > 1000000 or absi(grid.y) > 1000000:
			return _reject("coordinate_outside_prototype_range")
		grid_ids[grid] = grid_ids.size()
		_terrain_grids.append(grid)
		coords.append(grid.x)
		coords.append(grid.y)
		walkable.append(1 if bool(registry.call("is_walkable", grid)) else 0)
		cover.append(_oracle._get_cover_score(grid, registry))
		blocks_los.append(1 if (bool(registry.call("blocks_los_at_grid", grid)) if registry.has_method("blocks_los_at_grid") else bool(tile.blocks_los)) else 0)
		var height: int = int(tile.height_level)
		var object_height: int = int(registry.call("get_object_height_at_grid", grid)) if registry.has_method("get_object_height_at_grid") else int(tile.object_height)
		if absi(height) > 1000000 or absi(object_height) > 1000000:
			return _reject("height_outside_prototype_range")
		heights.append(height)
		stand_heights.append(PATH_SCRIPT.TERRAIN_TILE_DATA_SCRIPT.stand_height(tile))
		object_heights.append(object_height)
		surface_costs.append(PATH_SCRIPT.TERRAIN_TILE_DATA_SCRIPT.get_surface_path_cost(String(tile.surface_type)))
		if builder_supported:
			var ramp: int = int(tile.ramp_direction)
			if height < 0 or height > PATH_SCRIPT.TERRAIN_TILE_DATA_SCRIPT.MAX_HEIGHT_LEVEL or ramp < -1 or ramp >= 6:
				builder_supported = false
			else:
				ramp_directions.append(ramp)
				traits.append((1 if tile.explicit_hex_ramps else 0) | (2 if tile.regional_grade else 0)
					| (4 if String(tile.edge_type) == "slope" else 0) | (8 if String(tile.object_type_id) == "glut_bridge_deck" else 0))
	_debug["terrain_extract_usec"] = Time.get_ticks_usec() - phase_started
	phase_started = Time.get_ticks_usec()
	var hex_mode: bool = registry.has_method("get_grid_topology") and String(registry.call("get_grid_topology")) == "hex_axial_v1"
	var built_edges: Dictionary = {}
	if builder_supported:
		built_edges = _terrain_builder.call("build_edges", {"coords": coords, "height": heights, "walkable": walkable,
			"traits": traits, "ramp_direction": ramp_directions, "stand_height": stand_heights, "surface_cost": surface_costs, "hex": hex_mode})
	var offsets := PackedInt32Array()
	var neighbors := PackedInt32Array()
	var costs := PackedFloat64Array()
	if not built_edges.is_empty():
		offsets = built_edges.offsets
		neighbors = built_edges.neighbors
		costs = built_edges.costs
		_debug["terrain_builder"] = "native"
	else:
		# Original edge traversal remains the fallback for older DLLs, unsupported
		# authored values and the developer comparison switch.
		_debug["terrain_builder"] = "gdscript"
		var directions: Array = _oracle.get_neighbor_directions(registry)
		for source_id in range(_terrain_grids.size()):
			offsets.append(neighbors.size())
			var grid: Vector2i = _terrain_grids[source_id]
			for direction in directions:
				var target: Vector2i = grid + Vector2i(direction)
				if not grid_ids.has(target) or not _oracle.can_traverse_step(grid, target, registry):
					continue
				var target_id: int = int(grid_ids[target])
				# Match Main's canonical ramp midpoint heights. Retain the unmultiplied
				# base; dividing a previous diagonal cost would change float rounding.
				var cost: float = surface_costs[target_id]
				var height_difference: float = absf(stand_heights[target_id] - stand_heights[source_id])
				if height_difference > 0:
					cost += height_difference
				neighbors.append(target_id)
				costs.append(cost)
		offsets.append(neighbors.size())
	_debug["terrain_edges_usec"] = Time.get_ticks_usec() - phase_started
	phase_started = Time.get_ticks_usec()
	if not bool(_kernel.call("load_terrain", {"coords": coords, "offsets": offsets, "neighbors": neighbors,
		"costs": costs, "walkable": walkable, "cover": cover, "blocks_los": blocks_los,
		"height": heights, "object_height": object_heights, "hex": hex_mode, "heuristic_min": 0.7})):
		return _reject("native_snapshot_rejected")
	_debug["terrain_load_usec"] = Time.get_ticks_usec() - phase_started
	return true


func create_regional_search(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}):
	_reset_debug()
	if prepare(registry, options):
		if _kernel.has_method("create_regional_search"):
			var native_search: Object = _kernel.call("create_regional_search", from_grid, to_grid, _normalized_options(options))
			if is_instance_valid(native_search):
				_debug["last_backend"] = "native"
				return RegionalSearch.new(native_search, from_grid, to_grid, registry, options)
			_debug["fallback_reason"] = "regional_input_not_supported"
		else:
			_debug["fallback_reason"] = "native_regional_api_unavailable"
	_debug["last_backend"] = "gdscript_fallback"
	return PATH_SCRIPT.RegionalHexSearch.new(from_grid, to_grid, int(registry.call("get_revision")), options, registry)


func find_path_with_options(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> Array:
	_reset_debug()
	if not prepare(registry, options):
		_debug["last_backend"] = "gdscript_fallback"
		return _oracle.find_path_with_options(from_grid, to_grid, registry, options)
	var started: int = Time.get_ticks_usec()
	var result: Array = _kernel.call("find_path", from_grid, to_grid)
	_debug["native_query_usec"] = Time.get_ticks_usec() - started
	_debug["last_backend"] = "native"
	return result


func find_path(from_grid: Vector2i, to_grid: Vector2i, registry, options: Dictionary = {}) -> Array:
	return find_path_with_options(from_grid, to_grid, registry, options)


func _prepare_result_scope(registry, graph) -> bool:
	if not _valid_registry(registry) or not _valid_graph(graph):
		clear_result_cache()
		return false
	var registry_revision: int = int(registry.call("get_revision"))
	var graph_revision: int = int(graph.call("get_revision"))
	if _referent(_cache_registry_ref) != registry or _referent(_cache_graph_ref) != graph or _cache_registry_revision != registry_revision or _cache_graph_revision != graph_revision:
		clear_result_cache()
		_cache_registry_ref = weakref(registry)
		_cache_graph_ref = weakref(graph)
		_cache_registry_revision = registry_revision
		_cache_graph_revision = graph_revision
	return true


func find_path_with_status(from_grid: Vector2i, to_grid: Vector2i, registry, graph, options: Dictionary = {}) -> Dictionary:
	_reset_debug()
	# Diagnostic counters describe the oracle's invocation work, not a prepared
	# native snapshot. Delegate before the native cache lookup, even for empty {}.
	if typeof(options.get("diagnostics")) == TYPE_DICTIONARY:
		_debug["last_backend"] = "gdscript_fallback"
		_debug["fallback_reason"] = "diagnostics_require_gdscript"
		return _fallback_hpa.find_path_with_status(from_grid, to_grid, registry, graph, options)
	if graph == null:
		_debug["last_backend"] = "gdscript_fallback"
		_debug["fallback_reason"] = "missing_graph"
		clear_result_cache()
		return _fallback_hpa.find_path_with_status(from_grid, to_grid, registry, graph, options)
	var eligible: bool = is_instance_valid(_kernel) and _prepare_result_scope(registry, graph)
	var cache_key: String = String(_fallback_hpa.call("_result_cache_key", from_grid, to_grid, options)) if eligible else ""
	if not cache_key.is_empty() and _result_cache.has(cache_key):
		_debug["result_cache_hit"] = true
		_debug["last_backend"] = "native"
		return Dictionary(_result_cache[cache_key]).duplicate(true)
	if not prepare(registry, options, graph):
		_debug["last_backend"] = "gdscript_fallback"
		return _fallback_hpa.find_path_with_status(from_grid, to_grid, registry, graph, options)
	var started: int = Time.get_ticks_usec()
	var result: Dictionary = _kernel.call("find_hpa", from_grid, to_grid, _graph_data)
	_debug["native_query_usec"] = Time.get_ticks_usec() - started
	_debug["last_backend"] = "native"
	if not cache_key.is_empty() and String(result.get("status", "")) in ["hpa", "same_component"] and not Array(result.get("path", [])).is_empty():
		if not _result_cache.has(cache_key):
			while _result_fifo.size() >= RESULT_CACHE_LIMIT:
				_result_cache.erase(_result_fifo.pop_front())
			_result_fifo.append(cache_key)
		_result_cache[cache_key] = result.duplicate(true)
	return result.duplicate(true)
