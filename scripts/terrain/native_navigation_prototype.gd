class_name NativeNavigationPrototype
extends RefCounted

## Opt-in differential prototype. Registry and HPA graph remain authoritative.
## Preparation deliberately retains the original GDScript cost calculations.
## Measure preparation plus query for cold comparisons, not just the C++ call.
const PATH_SCRIPT = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA_SCRIPT = preload("res://scripts/terrain/hpa_pathfinder.gd")
const RESULT_CACHE_LIMIT: int = 64
var _oracle = PATH_SCRIPT.new()
var _fallback_hpa = HPA_SCRIPT.new()
var _kernel: Object
var _prepared_registry_ref: WeakRef
var _prepared_graph_ref: WeakRef
var _prepared_registry_revision: int = -1
var _prepared_graph_revision: int = -1
var _prepared_options: String = ""
var _graph_data: Dictionary = {}
var _snapshot_build_count: int = 0
var _result_cache: Dictionary = {}
var _result_fifo: Array[String] = []
var _cache_registry_ref: WeakRef
var _cache_graph_ref: WeakRef
var _cache_registry_revision: int = -1
var _cache_graph_revision: int = -1
var _debug: Dictionary = {}


func _init() -> void:
	if ClassDB.class_exists("NativeNavigationKernel"):
		_kernel = ClassDB.instantiate("NativeNavigationKernel")
	_reset_debug()


func _reset_debug() -> void:
	_debug = {"last_backend": "none", "fallback_reason": "", "result_cache_hit": false,
		"snapshot_prepare_usec": 0, "native_query_usec": 0, "snapshot_reused": false}


func get_debug_snapshot() -> Dictionary:
	var result: Dictionary = _debug.duplicate(true)
	result["snapshot_build_count"] = _snapshot_build_count
	result["result_cache_entry_count"] = _result_cache.size()
	result["result_cache_limit"] = RESULT_CACHE_LIMIT
	result["native_available"] = is_instance_valid(_kernel)
	return result


func clear_result_cache() -> void:
	_result_cache.clear()
	_result_fifo.clear()


func _reject(reason: String) -> bool:
	_debug["fallback_reason"] = reason
	_prepared_registry_ref = null
	_prepared_graph_ref = null
	_prepared_options = ""
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
	var started: int = Time.get_ticks_usec()
	var prepared: bool = _prepare_snapshot(registry, options, graph)
	_debug["snapshot_prepare_usec"] = Time.get_ticks_usec() - started
	return prepared


func _prepare_snapshot(registry, options: Dictionary, graph) -> bool:
	_debug["fallback_reason"] = ""
	if typeof(options.get("diagnostics")) == TYPE_DICTIONARY:
		return _reject("diagnostics_require_gdscript")
	if not is_instance_valid(_kernel):
		return _reject("native_extension_unavailable")
	if not _valid_registry(registry):
		return _reject("unsupported_registry")
	if graph != null and not _valid_graph(graph):
		return _reject("unsupported_graph")
	var normalized: Dictionary = _normalized_options(options)
	if not bool(_fallback_hpa.call("_is_result_cache_value_supported", normalized)):
		return _reject("unsupported_or_nonfinite_options")
	var options_key: String = var_to_bytes(normalized).hex_encode()
	var registry_revision: int = int(registry.call("get_revision"))
	var graph_revision: int = int(graph.call("get_revision")) if graph != null else -1
	if _referent(_prepared_registry_ref) == registry and _referent(_prepared_graph_ref) == graph and _prepared_registry_revision == registry_revision and _prepared_graph_revision == graph_revision and _prepared_options == options_key:
		_debug["snapshot_reused"] = true
		return true
	_debug["snapshot_reused"] = false
	var tiles: Array = registry.call("get_all_tiles")
	var grid_ids: Dictionary = {}
	var coords := PackedInt32Array()
	var walkable := PackedByteArray()
	for tile in tiles:
		var grid: Vector2i = Vector2i(tile.grid_position)
		if absi(grid.x) > 1000000 or absi(grid.y) > 1000000:
			return _reject("coordinate_outside_prototype_range")
		grid_ids[grid] = grid_ids.size()
		coords.append(grid.x)
		coords.append(grid.y)
		walkable.append(1 if bool(registry.call("is_walkable", grid)) else 0)
	var offsets := PackedInt32Array()
	var neighbors := PackedInt32Array()
	var costs := PackedFloat64Array()
	var directions: Array = _oracle.get_neighbor_directions(registry)
	var query_options: Dictionary = normalized.duplicate(false)
	query_options[PATH_SCRIPT.STEP_COST_CONTEXT_OPTION] = PATH_SCRIPT.StepCostContext.new(registry)
	for tile in tiles:
		offsets.append(neighbors.size())
		var grid: Vector2i = Vector2i(tile.grid_position)
		for direction in directions:
			var target: Vector2i = grid + Vector2i(direction)
			if not grid_ids.has(target):
				continue
			var cost: float = _oracle.get_step_cost(grid, target, registry, query_options)
			if is_nan(cost) or cost < 0.0:
				return _reject("unsupported_edge_cost")
			if is_inf(cost):
				continue
			neighbors.append(int(grid_ids[target]))
			costs.append(cost)
	offsets.append(neighbors.size())
	var hex_mode: bool = registry.has_method("get_grid_topology") and String(registry.call("get_grid_topology")) == "hex_axial_v1"
	var heuristic_min: float = 0.7
	if bool(normalized.get("cover_aware_enabled", false)):
		heuristic_min = 0.05 if hex_mode else maxf(0.05, 0.7 - maxf(float(normalized.get("cover_weight", 0.0)), 0.0))
	var graph_data: Dictionary = {}
	if graph != null:
		var component_by_grid: Dictionary = {}
		var component_tiles: Dictionary = {}
		for grid in grid_ids:
			var key: String = String(graph.call("get_component_key_for_grid", grid))
			component_by_grid[grid] = key
			if not key.is_empty() and not component_tiles.has(key):
				component_tiles[key] = graph.call("get_component_tiles", key)
		var adjacency: Dictionary = _fallback_hpa.call("_build_portal_adjacency", graph)
		for key in adjacency:
			Array(adjacency[key]).sort_custom(Callable(_fallback_hpa, "_sort_edges"))
		graph_data = {"component_by_grid": component_by_grid, "component_tiles": component_tiles,
			"adjacency": adjacency, "portals": graph.call("get_portals_snapshot"),
			"minimum_step_cost": _fallback_hpa.call("_minimum_local_step_cost", normalized)}
	if int(registry.call("get_revision")) != registry_revision or (graph != null and int(graph.call("get_revision")) != graph_revision):
		return _reject("revision_changed_during_snapshot")
	if not bool(_kernel.call("load_snapshot", {"coords": coords, "offsets": offsets, "neighbors": neighbors,
		"costs": costs, "walkable": walkable, "hex": hex_mode, "heuristic_min": heuristic_min})):
		return _reject("native_snapshot_rejected")
	_prepared_registry_ref = weakref(registry)
	_prepared_graph_ref = weakref(graph) if graph != null else null
	_prepared_registry_revision = registry_revision
	_prepared_graph_revision = graph_revision
	_prepared_options = options_key
	_graph_data = graph_data
	_snapshot_build_count += 1
	return true


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
