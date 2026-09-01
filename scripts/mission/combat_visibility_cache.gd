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
const TASK1206_VARIANTS: Array[String] = ["off", "shared_tick_result_contract", "cache_internal_structured_reuse", "contact_derived_read_model"]
const TASK1206_CONSUMERS: Array[String] = ["contact_tracking", "fire_pair_search", "enemy_security", "enemy_team_tactics", "other_combat"]
const TASK1206_PAIR_DUMP_LIMIT: int = 32
var _task1206_variant: String = "off"
var _task1206_enabled: bool = false
var _task1206_topology_enabled: bool = false
var _task1206_consumers: Dictionary = {}
var _task1206_overlap: Dictionary = {}
var _task1206_costs: Dictionary = {}
var _task1206_pairs: Array = []
var _task1206_pair_consumers: Dictionary = {}
var _task1206_producers: Dictionary = {}
var _task1206_validity: Dictionary = {}
var _task1206_producer_meta: Dictionary = {}
var _shared_tick_results: Dictionary = {}
var _result_materialization_count: int = 0
var _result_materialization_usec: int = 0
var _shared_result_reuse_count: int = 0

func _task1206_signature(source_id: String, target_id: String, source_position: Vector2, target_position: Vector2, terrain_registry) -> String:
	return "tick:%d|source:%s|target:%s|sp:%s|tp:%s|registry:%d|revisions:%s" % [_current_tick, source_id, target_id, str(source_position), str(target_position), _resolve_registry_identity(terrain_registry), str(_resolve_terrain_revisions(terrain_registry))]

func _task1206_record_request(signature: String, source_id: String, target_id: String, source_position: Vector2, target_position: Vector2, terrain_registry, normalized_tag: String) -> void:
	var prior: Dictionary = _task1206_pair_consumers.get(signature, {})
	prior[normalized_tag] = true; _task1206_pair_consumers[signature] = prior
	var aggregate: Dictionary = _task1206_consumers[normalized_tag]; var seen: Dictionary = aggregate["_pairs"]
	aggregate["request_count"] += 1
	if seen.has(signature): aggregate["same_consumer_repeat_count"] += 1
	else: seen[signature] = true; aggregate["unique_ordered_pair_count"] += 1
	aggregate["_pairs"] = seen; _task1206_consumers[normalized_tag] = aggregate
	if _task1206_pairs.size() < TASK1206_PAIR_DUMP_LIMIT: _task1206_pairs.append({"signature": signature, "source_id": source_id, "target_id": target_id, "source_position": source_position, "target_position": target_position, "consumer_tag": normalized_tag})

func configure_task1206_analysis(variant: String, enabled: bool, topology_enabled: bool) -> void:
	var normalized := variant.strip_edges().to_lower()
	_task1206_variant = normalized if TASK1206_VARIANTS.has(normalized) else "off"
	_task1206_enabled = enabled and _task1206_variant != "off"
	_task1206_topology_enabled = topology_enabled and not _task1206_enabled
	_reset_task1206_diagnostics()

func get_task1206_analysis_snapshot(include_pair_dump: bool = false) -> Dictionary:
	var consumer_snapshot := _task1206_consumers.duplicate(true)
	for tag in consumer_snapshot: consumer_snapshot[tag].erase("_pairs")
	var result := {"variant": _task1206_variant, "enabled": _task1206_enabled, "topology_enabled": _task1206_topology_enabled, "derived_only": true, "read_only": true, "snapshot_serialized": false, "consumers": consumer_snapshot, "overlap": _task1206_overlap.duplicate(true), "validity": _task1206_validity.duplicate(true), "costs": _task1206_costs.duplicate(true), "range_rejected_count": _range_rejected_count, "result_materialization_count": _result_materialization_count, "result_materialization_usec": _result_materialization_usec, "shared_result_reuse_count": _shared_result_reuse_count}
	if include_pair_dump:
		result["pair_dump"] = _task1206_pairs.slice(0, TASK1206_PAIR_DUMP_LIMIT)
	return result

func _reset_task1206_diagnostics() -> void:
	_task1206_consumers.clear(); _task1206_overlap = {"exact_cross_consumer_hit_count": 0, "exact_contact_producer_fire_probe_count": 0, "missing_producer_count": 0, "reverse_pair_opportunity_count": 0, "range_rejected_count": 0}; _task1206_costs = {}
	for tag in TASK1206_CONSUMERS: _task1206_consumers[tag] = {"request_count": 0, "unique_ordered_pair_count": 0, "same_consumer_repeat_count": 0, "_pairs": {}}
	for name in ["signature_key_build", "cache_lookup", "entry_write", "terrain_los"]:
		var nested := {}; for tag in TASK1206_CONSUMERS: nested[tag] = {"count": 0, "usec": 0}
		_task1206_costs[name] = {"count": 0, "usec": 0, "consumers": nested}
	_task1206_pairs.clear()
	_task1206_pair_consumers.clear()
	_task1206_producers.clear()
	_task1206_producer_meta.clear()
	_task1206_validity.clear()
	_shared_tick_results.clear(); _result_materialization_count = 0; _result_materialization_usec = 0; _shared_result_reuse_count = 0
	for name in ["direction", "tick", "source_position", "target_position", "registry_identity", "registry_revision"]: _task1206_validity[name] = {"count": 0, "consumers": {"contact_tracking": 0, "fire_pair_search": 0, "enemy_security": 0, "enemy_team_tactics": 0, "other_combat": 0}}

func _task1206_record_cost(name: String, elapsed: int, consumer_tag: String = "other_combat") -> void:
	if not _task1206_topology_enabled: return
	var item: Dictionary = _task1206_costs.get(name, {"count": 0, "usec": 0})
	item["count"] = int(item.get("count", 0)) + 1; item["usec"] = int(item.get("usec", 0)) + maxi(0, elapsed)
	var consumers: Dictionary = item.get("consumers", {}); var c: Dictionary = consumers.get(consumer_tag, {"count": 0, "usec": 0}); c["count"] += 1; c["usec"] += maxi(0, elapsed); consumers[consumer_tag] = c; item["consumers"] = consumers; _task1206_costs[name] = item

func _task1206_meta(source_id: String, target_id: String) -> Dictionary:
	return Dictionary(_task1206_producer_meta.get(source_id, {}).get(target_id, {}))

func _task1206_set_meta(source_id: String, target_id: String, meta: Dictionary) -> void:
	var by_target: Dictionary = _task1206_producer_meta.get(source_id, {}); by_target[target_id] = meta.duplicate(true); _task1206_producer_meta[source_id] = by_target

func _task1206_validity_hit(name: String, tag: String) -> void:
	var item: Dictionary = _task1206_validity[name]; item["count"] += 1; var consumers: Dictionary = item["consumers"]; consumers[tag] = int(consumers.get(tag, 0)) + 1; item["consumers"] = consumers; _task1206_validity[name] = item

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
	_shared_tick_results.clear()

func is_cache_key_optimization_enabled() -> bool:
	return _cache_key_optimization_enabled

func get_debug_profile_snapshot() -> Dictionary:
	return {"enabled": _profile_enabled, "scope_active": _profile_scope_active, "counts": _profile_counts.duplicate(true), "usec": _profile_usec.duplicate(true), "derived_only": true, "read_only": true, "snapshot_serialized": false}


func begin_tick(simulation_tick: int) -> void:
	if simulation_tick == _current_tick:
		return
	_current_tick = simulation_tick
	_results_by_key.clear()
	_shared_tick_results.clear()
	_cache_key_reuse_by_pair.clear()
	_asked_pair_count = 0
	_actual_los_check_count = 0
	_cache_hit_count = 0
	_range_rejected_count = 0

func _task1206_get_shared_tick_result(source_position: Vector2, target_position: Vector2, terrain_registry, source_id: String, target_id: String, occlusion_compute: Callable = Callable()) -> Dictionary:
	if _task1206_variant != "shared_tick_result_contract" or not _task1206_enabled:
		return {}
	var registry_identity := _resolve_registry_identity(terrain_registry)
	var terrain_revision := int(_resolve_terrain_revisions(terrain_registry).get("terrain_revision", -1))
	var by_target: Dictionary = _shared_tick_results.get(source_id, {})
	var candidate_variant = by_target.get(target_id, null)
	if candidate_variant is Dictionary:
		var candidate: Dictionary = candidate_variant
		var exact_match: bool = (
			int(candidate.get("tick", -2)) == _current_tick
			and String(candidate.get("source_id", "")) == source_id
			and String(candidate.get("target_id", "")) == target_id
			and candidate.get("source_position", Vector2.INF) == source_position
			and candidate.get("target_position", Vector2.INF) == target_position
			and int(candidate.get("registry_identity", -2)) == registry_identity
			and int(candidate.get("terrain_revision", -2)) == terrain_revision
		)
		if exact_match:
			_cache_hit_count += 1
			_shared_result_reuse_count += 1
			return candidate
	_actual_los_check_count += 1
	var clear: bool = bool(occlusion_compute.call()) if occlusion_compute.is_valid() else _los_system.has_line_of_sight_between_points(source_position, target_position, -1.0, terrain_registry)
	var started := Time.get_ticks_usec()
	var result := {
		"tick": _current_tick,
		"source_id": source_id,
		"target_id": target_id,
		"source_position": source_position,
		"target_position": target_position,
		"registry_identity": registry_identity,
		"terrain_revision": terrain_revision,
		"clear": clear,
		"derived_only": true,
		"read_only": true,
		"snapshot_serialized": false,
	}
	result.make_read_only()
	by_target[target_id] = result
	_shared_tick_results[source_id] = by_target
	_result_materialization_count += 1
	_result_materialization_usec += maxi(0, Time.get_ticks_usec() - started)
	return result


func has_line_of_sight_between_nodes(
	source: Node2D,
	target: Node2D,
	max_range: float = -1.0,
	terrain_registry = null,
	occlusion_compute: Callable = Callable(),
	consumer_tag: String = "other_combat"
) -> bool:
	if source == null or target == null:
		return false
	_asked_pair_count += 1
	if max_range >= 0.0 and source.global_position.distance_to(target.global_position) > max_range:
		_range_rejected_count += 1
		if _task1206_topology_enabled:
			_task1206_overlap["range_rejected_count"] += 1
			_task1206_record_request(_task1206_signature(_resolve_node_id(source), _resolve_node_id(target), source.global_position, target.global_position, terrain_registry), _resolve_node_id(source), _resolve_node_id(target), source.global_position, target.global_position, terrain_registry, consumer_tag if TASK1206_CONSUMERS.has(consumer_tag) else "other_combat")
		return false
	return _resolve_terrain_occlusion(
		_resolve_node_id(source),
		_resolve_node_id(target),
		source.global_position,
		target.global_position,
		terrain_registry,
		occlusion_compute, consumer_tag
	)


func has_line_of_sight_between_points(
	source_position: Vector2,
	target_position: Vector2,
	max_range: float = -1.0,
	terrain_registry = null,
	source_id: String = "",
	target_id: String = "",
	occlusion_compute: Callable = Callable(),
	consumer_tag: String = "other_combat"
) -> bool:
	_asked_pair_count += 1
	if max_range >= 0.0 and source_position.distance_to(target_position) > max_range:
		_range_rejected_count += 1
		if _task1206_topology_enabled:
			_task1206_overlap["range_rejected_count"] += 1
			_task1206_record_request(_task1206_signature(source_id, target_id, source_position, target_position, terrain_registry), source_id, target_id, source_position, target_position, terrain_registry, consumer_tag if TASK1206_CONSUMERS.has(consumer_tag) else "other_combat")
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
		occlusion_compute, consumer_tag
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
	occlusion_compute: Callable,
	consumer_tag: String = "other_combat"
) -> bool:
	if _task1206_variant == "shared_tick_result_contract" and _task1206_enabled:
		var shared_result := _task1206_get_shared_tick_result(source_position, target_position, terrain_registry, source_id, target_id, occlusion_compute)
		return bool(shared_result.get("clear", false))
	var topology_active := _task1206_topology_enabled
	var normalized_tag := consumer_tag if TASK1206_CONSUMERS.has(consumer_tag) else "other_combat"
	var pair_id := _task1206_signature(source_id, target_id, source_position, target_position, terrain_registry)
	if topology_active:
		_task1206_record_request(pair_id, source_id, target_id, source_position, target_position, terrain_registry, normalized_tag)
		var prior_meta := _task1206_meta(source_id, target_id)
		if not prior_meta.is_empty():
			if int(prior_meta.get("tick", -2)) != _current_tick: _task1206_validity_hit("tick", normalized_tag)
			if prior_meta.get("source_position", Vector2.INF) != source_position: _task1206_validity_hit("source_position", normalized_tag)
			if prior_meta.get("target_position", Vector2.INF) != target_position: _task1206_validity_hit("target_position", normalized_tag)
			if int(prior_meta.get("registry_identity", -2)) != _resolve_registry_identity(terrain_registry): _task1206_validity_hit("registry_identity", normalized_tag)
			if prior_meta.get("revisions", {}) != _resolve_terrain_revisions(terrain_registry): _task1206_validity_hit("registry_revision", normalized_tag)
		else:
			var reverse_meta := _task1206_meta(target_id, source_id)
			if not reverse_meta.is_empty(): _task1206_validity_hit("direction", normalized_tag); _task1206_overlap["reverse_pair_opportunity_count"] += 1
	var profile_active: bool = _profile_enabled and _profile_scope_active
	var started_usec: int = Time.get_ticks_usec() if profile_active else 0
	var topology_signature_started_usec: int = Time.get_ticks_usec() if topology_active else 0
	var key: String = _build_cache_key(source_id, target_id, source_position, target_position, terrain_registry)
	if topology_active: _task1206_record_cost("signature_key_build", maxi(0, Time.get_ticks_usec() - topology_signature_started_usec), normalized_tag)
	if profile_active: _record_profile("cache_key_build", started_usec)
	var lookup_started_usec: int = Time.get_ticks_usec() if profile_active else 0
	var topology_lookup_started_usec: int = Time.get_ticks_usec() if topology_active else 0
	if _results_by_key.has(key):
		_cache_hit_count += 1
		if topology_active: _task1206_record_cost("cache_lookup", Time.get_ticks_usec() - topology_lookup_started_usec, normalized_tag)
		if topology_active:
			var producer := String(_task1206_producers.get(pair_id, ""));
			if producer.is_empty(): _task1206_overlap["missing_producer_count"] += 1
			elif producer != normalized_tag: _task1206_overlap["exact_cross_consumer_hit_count"] += 1; if producer == "contact_tracking" and normalized_tag == "fire_pair_search": _task1206_overlap["exact_contact_producer_fire_probe_count"] += 1
		if profile_active: _record_profile("los_cache_lookup", lookup_started_usec)
		return bool(_results_by_key[key])
	if profile_active: _record_profile("los_cache_lookup", lookup_started_usec)
	if topology_active: _task1206_record_cost("cache_lookup", Time.get_ticks_usec() - topology_lookup_started_usec, normalized_tag)
	var terrain_started_usec: int = Time.get_ticks_usec() if profile_active else 0
	var topology_terrain_started_usec: int = Time.get_ticks_usec() if topology_active else 0
	_actual_los_check_count += 1
	var has_clear_geometry: bool = bool(occlusion_compute.call()) if occlusion_compute.is_valid() else _los_system.has_line_of_sight_between_points(source_position, target_position, -1.0, terrain_registry)
	if topology_active: _task1206_record_cost("terrain_los", maxi(0, Time.get_ticks_usec() - topology_terrain_started_usec), normalized_tag)
	if profile_active: _record_profile("terrain_los_evaluation", terrain_started_usec)
	var write_started_usec := Time.get_ticks_usec() if topology_active else 0
	_results_by_key[key] = has_clear_geometry
	if topology_active:
		_task1206_record_cost("entry_write", Time.get_ticks_usec() - write_started_usec, normalized_tag)
		_task1206_producers[pair_id] = normalized_tag
		_task1206_set_meta(source_id, target_id, {"tick": _current_tick, "source_position": source_position, "target_position": target_position, "registry_identity": _resolve_registry_identity(terrain_registry), "revisions": _resolve_terrain_revisions(terrain_registry), "producer": normalized_tag})
	return has_clear_geometry

func _record_profile(name: String, started_usec: int) -> void:
	if not (_profile_enabled and _profile_scope_active): return
	_profile_counts[name] = int(_profile_counts.get(name, 0)) + 1
	_profile_usec[name] = int(_profile_usec.get(name, 0)) + maxi(0, Time.get_ticks_usec() - started_usec)


func _build_cache_key(source_id: String, target_id: String, source_position: Vector2, target_position: Vector2, terrain_registry) -> String:
	if _cache_key_optimization_enabled:
		var registry_identity: int = _resolve_registry_identity(terrain_registry)
		var revisions: Dictionary = _resolve_terrain_revisions(terrain_registry)
		var by_target: Dictionary = _cache_key_reuse_by_pair.get(source_id, {})
		var cached_variant = by_target.get(target_id, null)
		if cached_variant is Dictionary and cached_variant.get("source_position", Vector2.INF) == source_position and cached_variant.get("target_position", Vector2.INF) == target_position and int(cached_variant.get("registry_identity", -2)) == registry_identity and cached_variant.get("revisions", {}) == revisions:
			return String(cached_variant.get("key", ""))
		var key: String = _format_cache_key(source_id, target_id, source_position, target_position, terrain_registry, revisions)
		by_target[target_id] = {"source_position": source_position, "target_position": target_position, "registry_identity": registry_identity, "revisions": revisions.duplicate(), "key": key}
		_cache_key_reuse_by_pair[source_id] = by_target
		return key
	return _format_cache_key(source_id, target_id, source_position, target_position, terrain_registry, _resolve_terrain_revisions(terrain_registry))

func _format_cache_key(source_id: String, target_id: String, source_position: Vector2, target_position: Vector2, terrain_registry, revisions: Dictionary) -> String:
	var source_grid: Vector2i = _world_to_grid(terrain_registry, source_position)
	var target_grid: Vector2i = _world_to_grid(terrain_registry, target_position)
	var source_height_class: int = _height_at_world(terrain_registry, source_position)
	var target_height_class: int = _height_at_world(terrain_registry, target_position)
	return "tick:%d|source:%s|target:%s|registry:%d|source_grid:%d,%d|target_grid:%d,%d|source_height:%d|target_height:%d|terrain_revision:%d|cover_revision:%d|navigation_revision:%d|source_position:%s|target_position:%s" % [
		_current_tick,
		source_id,
		target_id,
		_resolve_registry_identity(terrain_registry),
		source_grid.x,
		source_grid.y,
		target_grid.x,
		target_grid.y,
		source_height_class,
		target_height_class,
		int(revisions.get("terrain_revision", -1)),
		int(revisions.get("cover_revision", -1)),
		int(revisions.get("navigation_revision", -1)),
		str(source_position),
		str(target_position),
	]

func _resolve_registry_identity(terrain_registry) -> int:
	if terrain_registry != null and terrain_registry.has_method("get_instance_id"):
		return int(terrain_registry.call("get_instance_id"))
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


func _resolve_terrain_revisions(terrain_registry) -> Dictionary:
	var revision: int = -1
	if terrain_registry != null and terrain_registry.has_method("get_revision"):
		revision = int(terrain_registry.call("get_revision"))
	# TerrainRegistry currently exposes one authoritative terrain revision. It
	# already advances for terrain and runtime cover changes; navigation rebuilds
	# consume that revision. Keep all three explicit in the key for a future
	# split without widening cache validity today.
	return {
		"terrain_revision": revision,
		"cover_revision": revision,
		"navigation_revision": revision,
	}
