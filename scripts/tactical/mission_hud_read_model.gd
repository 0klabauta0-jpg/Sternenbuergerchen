class_name MissionHudReadModel
extends Node

## Read-only revision tracker and synchronous projection pass for HUD surfaces.
##
## Values remain in their existing controller/runtime owners. Derived snapshots
## are shared only until the explicit outer pass ends, a revision changes, or
## the engineframe advances. This node never processes or commits gameplay.

var _light_state: Dictionary = {}
var _light_revision: int = 0
var _heavy_revision: int = 0
var _fireteam_heavy_revisions: Dictionary = {}
var _projection_values: Dictionary = {}
var _projection_scope_depth: int = 0
var _projection_engine_frame: int = -1
var _projection_generation: int = 0
var _projection_producer_depth: int = 0
var _projection_pass_count: int = 0
var _projection_build_count: int = 0
var _projection_hit_count: int = 0
var _projection_invalidation_count: int = 0
var _projection_leaked_scope_count: int = 0
var _projection_recursive_bypass_count: int = 0
var _projection_direct_read_count: int = 0


func set_light_state(surface_id: String, value: Variant) -> bool:
	var normalized_surface_id: String = surface_id.strip_edges()
	if normalized_surface_id.is_empty():
		return false
	if _light_state.has(normalized_surface_id) and _light_state[normalized_surface_id] == value:
		return false
	_light_state[normalized_surface_id] = value
	_light_revision += 1
	_invalidate_projection_values()
	return true


func mark_heavy_state_changed() -> void:
	_heavy_revision += 1
	_invalidate_projection_values()


func mark_fireteam_heavy_state_changed(fireteam_id: String) -> void:
	var normalized_fireteam_id: String = fireteam_id.strip_edges().to_lower()
	if normalized_fireteam_id.is_empty():
		return
	_fireteam_heavy_revisions[normalized_fireteam_id] = int(_fireteam_heavy_revisions.get(normalized_fireteam_id, 0)) + 1
	_heavy_revision += 1
	_invalidate_projection_values()


func begin_projection_pass() -> void:
	_expire_projection_pass()
	if _projection_scope_depth == 0:
		_projection_values.clear()
		_projection_generation += 1
		_projection_engine_frame = Engine.get_process_frames()
		_projection_pass_count += 1
	_projection_scope_depth += 1


func end_projection_pass() -> void:
	_expire_projection_pass()
	if _projection_scope_depth == 0:
		return
	_projection_scope_depth -= 1
	if _projection_scope_depth == 0:
		_invalidate_projection_values()
		_projection_engine_frame = -1


func is_projection_pass_active() -> bool:
	_expire_projection_pass()
	return _projection_scope_depth > 0


func project(key: String, producer: Callable) -> Variant:
	_expire_projection_pass()
	if _projection_scope_depth == 0:
		_projection_direct_read_count += 1
		return producer.call()
	# Nested builders can enter context-dependent recursion fallbacks. They must
	# neither read nor replace any cached top-level result, even for another key.
	if _projection_producer_depth > 0:
		_projection_recursive_bypass_count += 1
		return producer.call()
	if _projection_values.has(key):
		_projection_hit_count += 1
		return _copy_projection_value(_projection_values[key])
	var generation: int = _projection_generation
	_projection_build_count += 1
	_projection_producer_depth += 1
	var result: Variant = producer.call()
	_projection_producer_depth -= 1
	_expire_projection_pass()
	# A producer may synchronously advance a read revision or close its scope.
	# Such a result must not refill the cache after that invalidation barrier.
	if _projection_scope_depth > 0 and generation == _projection_generation:
		_projection_values[key] = _copy_projection_value(result)
	return _copy_projection_value(result)


func _expire_projection_pass() -> void:
	if _projection_scope_depth == 0 or _projection_engine_frame == Engine.get_process_frames():
		return
	_projection_leaked_scope_count += 1
	_projection_scope_depth = 0
	_projection_engine_frame = -1
	_invalidate_projection_values()


func _invalidate_projection_values() -> void:
	_projection_values.clear()
	_projection_generation += 1
	_projection_invalidation_count += 1


func _copy_projection_value(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func get_light_revision() -> int:
	return _light_revision


func get_heavy_revision() -> int:
	return _heavy_revision


func get_fireteam_heavy_revision(fireteam_id: String) -> int:
	return int(_fireteam_heavy_revisions.get(fireteam_id.strip_edges().to_lower(), 0))


func get_diagnostics_snapshot() -> Dictionary:
	_expire_projection_pass()
	return {
		"light_revision": _light_revision,
		"heavy_revision": _heavy_revision,
		"fireteam_heavy_revisions": _fireteam_heavy_revisions.duplicate(),
		"read_only": true,
		"hud_read_model_owns_gameplay_truth": false,
		"projection_scope_depth": _projection_scope_depth,
		"projection_cached_entries": _projection_values.size(),
		"projection_pass_count": _projection_pass_count,
		"projection_build_count": _projection_build_count,
		"projection_hit_count": _projection_hit_count,
		"projection_invalidation_count": _projection_invalidation_count,
		"projection_leaked_scope_count": _projection_leaked_scope_count,
		"projection_recursive_bypass_count": _projection_recursive_bypass_count,
		"projection_direct_read_count": _projection_direct_read_count,
	}
