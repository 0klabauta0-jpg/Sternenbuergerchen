class_name CombatVisibilityCache
extends Node

## Derived, tick-local terrain visibility reuse for combat readers.
##
## This node intentionally caches only the terrain-occlusion half of a line of
## sight query. Callers retain range, firing arc, posture, weapon and command
## decisions so it never becomes gameplay truth.

const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")

var _los_system = LOS_SYSTEM_SCRIPT.new()
var _current_tick: int = -1
var _results_by_key: Dictionary = {}
var _asked_pair_count: int = 0
var _actual_los_check_count: int = 0
var _cache_hit_count: int = 0
var _range_rejected_count: int = 0
var _cache_key_optimization_enabled: bool = true
var _cache_key_reuse_by_pair: Dictionary = {}
var _profile_enabled: bool = false
var _profile_scope_active: bool = false
var _profile_usec: Dictionary = {}
var _profile_counts: Dictionary = {}

func set_debug_profiling_enabled(enabled: bool) -> void:
	_profile_enabled = enabled
	_profile_scope_active = false
	_profile_usec.clear()
	_profile_counts.clear()

func set_debug_profile_scope_active(active: bool) -> void:
	_profile_scope_active = active and _profile_enabled

func set_cache_key_optimization_enabled(enabled: bool) -> void:
	_cache_key_optimization_enabled = enabled
	_cache_key_reuse_by_pair.clear()

func is_cache_key_optimization_enabled() -> bool:
	return _cache_key_optimization_enabled

func get_debug_profile_snapshot() -> Dictionary:
	return {"enabled": _profile_enabled, "scope_active": _profile_scope_active, "counts": _profile_counts.duplicate(true), "usec": _profile_usec.duplicate(true), "derived_only": true, "read_only": true, "snapshot_serialized": false}


func begin_tick(simulation_tick: int) -> void:
	if simulation_tick == _current_tick:
		return
	_current_tick = simulation_tick
	_results_by_key.clear()
	_cache_key_reuse_by_pair.clear()
	_asked_pair_count = 0
	_actual_los_check_count = 0
	_cache_hit_count = 0
	_range_rejected_count = 0


func has_line_of_sight_between_nodes(
	source: Node2D,
	target: Node2D,
	max_range: float = -1.0,
	terrain_registry = null,
	occlusion_compute: Callable = Callable()
) -> bool:
	if source == null or target == null:
		return false
	_asked_pair_count += 1
	if max_range >= 0.0 and source.global_position.distance_to(target.global_position) > max_range:
		_range_rejected_count += 1
		return false
	return _resolve_terrain_occlusion(
		_resolve_node_id(source),
		_resolve_node_id(target),
		source.global_position,
		target.global_position,
		terrain_registry,
		occlusion_compute
	)


func has_line_of_sight_between_points(
	source_position: Vector2,
	target_position: Vector2,
	max_range: float = -1.0,
	terrain_registry = null,
	source_id: String = "",
	target_id: String = "",
	occlusion_compute: Callable = Callable()
) -> bool:
	_asked_pair_count += 1
	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		_range_rejected_count += 1
		return false
	var normalized_source_id: String = source_id.strip_edges()
	var normalized_target_id: String = target_id.strip_edges()
	if normalized_source_id.is_empty():
		normalized_source_id = "point:%s" % str(source_position)
	if normalized_target_id.is_empty():
		normalized_target_id = "point:%s" % str(target_position)
	return _resolve_terrain_occlusion(
		normalized_source_id,
		normalized_target_id,
		source_position,
		target_position,
		terrain_registry,
		occlusion_compute
	)


func get_audit_snapshot() -> Dictionary:
	return {
		"cache_status": "active",
		"derived_only": true,
		"current_tick": _current_tick,
		"entry_count": _results_by_key.size(),
		"asked_pair_count": _asked_pair_count,
		"actual_los_check_count": _actual_los_check_count,
		"cache_hit_count": _cache_hit_count,
		"range_rejected_count": _range_rejected_count,
		"key_ordered_by_source_target": true,
		"snapshot_serialized": false,
	}


func _resolve_terrain_occlusion(
	source_id: String,
	target_id: String,
	source_position: Vector2,
	target_position: Vector2,
	terrain_registry,
	occlusion_compute: Callable
) -> bool:
	var profile_active: bool = _profile_enabled and _profile_scope_active
	var structured_lookup_started_usec: int = Time.get_ticks_usec() if profile_active else 0
	var registry_identity: int = _resolve_registry_identity(terrain_registry)
	var revision: int = _resolve_terrain_revision(terrain_registry)
	var by_target: Dictionary = _cache_key_reuse_by_pair.get(source_id, {})
	var entry = by_target.get(target_id, null)
	if _cache_key_optimization_enabled and entry is Dictionary and bool(entry.get("result_ready", false)) and entry.get("source_position", Vector2.INF) == source_position and entry.get("target_position", Vector2.INF) == target_position and int(entry.get("registry_identity", -2)) == registry_identity and int(entry.get("revision", -2)) == revision:
		_cache_hit_count += 1
		if profile_active: _record_profile("los_cache_lookup", structured_lookup_started_usec)
		return bool(entry.get("result", false))
	var started_usec: int = Time.get_ticks_usec() if profile_active else 0
	var key: String = _build_cache_key(source_id, target_id, source_position, target_position, terrain_registry, registry_identity, revision)
	if profile_active: _record_profile("cache_key_build", started_usec)
	var lookup_started_usec: int = Time.get_ticks_usec() if profile_active else 0
	if _results_by_key.has(key):
		_cache_hit_count += 1
		if profile_active: _record_profile("los_cache_lookup", lookup_started_usec)
		if _cache_key_optimization_enabled:
			by_target[target_id] = {"source_position": source_position, "target_position": target_position, "registry_identity": registry_identity, "revision": revision, "result": bool(_results_by_key[key]), "result_ready": true, "key": key}
			_cache_key_reuse_by_pair[source_id] = by_target
		return bool(_results_by_key[key])
	if profile_active: _record_profile("los_cache_lookup", lookup_started_usec)
	var terrain_started_usec: int = Time.get_ticks_usec() if profile_active else 0
	_actual_los_check_count += 1
	var has_clear_geometry: bool = bool(occlusion_compute.call()) if occlusion_compute.is_valid() else _los_system.has_line_of_sight_between_points(source_position, target_position, -1.0, terrain_registry)
	if profile_active: _record_profile("terrain_los_evaluation", terrain_started_usec)
	_results_by_key[key] = has_clear_geometry
	if _cache_key_optimization_enabled:
		by_target[target_id] = {"source_position": source_position, "target_position": target_position, "registry_identity": registry_identity, "revision": revision, "result": has_clear_geometry, "result_ready": true, "key": key}
		_cache_key_reuse_by_pair[source_id] = by_target
	return has_clear_geometry

func _record_profile(name: String, started_usec: int) -> void:
	if not (_profile_enabled and _profile_scope_active): return
	_profile_counts[name] = int(_profile_counts.get(name, 0)) + 1
	_profile_usec[name] = int(_profile_usec.get(name, 0)) + maxi(0, Time.get_ticks_usec() - started_usec)


func _build_cache_key(source_id: String, target_id: String, source_position: Vector2, target_position: Vector2, terrain_registry, registry_identity: int = -1, revision: int = -1) -> String:
	if _cache_key_optimization_enabled:
		var by_target: Dictionary = _cache_key_reuse_by_pair.get(source_id, {})
		var cached_variant = by_target.get(target_id, null)
		if cached_variant is Dictionary and cached_variant.get("source_position", Vector2.INF) == source_position and cached_variant.get("target_position", Vector2.INF) == target_position and int(cached_variant.get("registry_identity", -2)) == registry_identity and int(cached_variant.get("revision", -2)) == revision:
			return String(cached_variant.get("key", ""))
		var key: String = _format_cache_key(source_id, target_id, source_position, target_position, terrain_registry, registry_identity, revision)
		by_target[target_id] = {"source_position": source_position, "target_position": target_position, "registry_identity": registry_identity, "revision": revision, "result_ready": false, "key": key}
		_cache_key_reuse_by_pair[source_id] = by_target
		return key
	return _format_cache_key(source_id, target_id, source_position, target_position, terrain_registry, registry_identity, revision)

func _format_cache_key(source_id: String, target_id: String, source_position: Vector2, target_position: Vector2, terrain_registry, registry_identity: int, revision: int) -> String:
	var source_grid: Vector2i = _world_to_grid(terrain_registry, source_position)
	var target_grid: Vector2i = _world_to_grid(terrain_registry, target_position)
	var source_height_class: int = _height_at_world(terrain_registry, source_position)
	var target_height_class: int = _height_at_world(terrain_registry, target_position)
	return "tick:%d|registry:%d|source:%s|target:%s|source_grid:%d,%d|target_grid:%d,%d|source_height:%d|target_height:%d|terrain_revision:%d|cover_revision:%d|navigation_revision:%d|source_position:%s|target_position:%s" % [
		_current_tick,
		registry_identity,
		source_id,
		target_id,
		source_grid.x,
		source_grid.y,
		target_grid.x,
		target_grid.y,
		source_height_class,
		target_height_class,
		revision,
		revision,
		revision,
		str(source_position),
		str(target_position),
	]

func _resolve_registry_identity(terrain_registry) -> int:
	if terrain_registry is Object:
		return int(terrain_registry.get_instance_id())
	return -1


func _resolve_node_id(node: Node2D) -> String:
	if node.has_method("get_unit_id"):
		var unit_id: String = String(node.call("get_unit_id")).strip_edges()
		if not unit_id.is_empty():
			return unit_id
	return node.get_path()


func _world_to_grid(terrain_registry, world_position: Vector2) -> Vector2i:
	if terrain_registry != null and terrain_registry.has_method("world_to_grid"):
		return Vector2i(terrain_registry.call("world_to_grid", world_position))
	return Vector2i(roundi(world_position.x), roundi(world_position.y))


func _height_at_world(terrain_registry, world_position: Vector2) -> int:
	if terrain_registry != null and terrain_registry.has_method("get_height_at_world"):
		return int(terrain_registry.call("get_height_at_world", world_position))
	return 0


func _resolve_terrain_revision(terrain_registry) -> int:
	var revision: int = -1
	if terrain_registry != null and terrain_registry.has_method("get_revision"):
		revision = int(terrain_registry.call("get_revision"))
	return revision
