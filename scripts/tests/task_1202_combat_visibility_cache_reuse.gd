extends SceneTree

const CACHE_SCRIPT: GDScript = preload("res://scripts/mission/combat_visibility_cache.gd")

class RegistryDouble extends Node:
	var revision: int = 1
	var compute_count: int = 0
	var result: bool = true

	func compute_visibility() -> bool:
		compute_count += 1
		return result

	func get_revision() -> int:
		return revision

	func world_to_grid(position_value: Vector2) -> Vector2i:
		return Vector2i(roundi(position_value.x), roundi(position_value.y))

	func get_height_at_world(_position_value: Vector2) -> int:
		return 0


var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1202 Combat Visibility Cache Reuse ===")
	var cache: Node = CACHE_SCRIPT.new()
	root.add_child(cache)
	cache.call("set_debug_profiling_enabled", true)
	cache.call("set_debug_profile_scope_active", true)
	var registry := RegistryDouble.new()
	root.add_child(registry)
	var source_position := Vector2(5.0, 5.0)
	var target_position := Vector2(9.0, 5.0)
	var compute := Callable(registry, "compute_visibility")
	cache.call("begin_tick", 7)
	var results: Array[bool] = []
	for _index in range(5):
		results.append(bool(cache.call("has_line_of_sight_between_points", source_position, target_position, -1.0, registry, "source", "target", compute)))
	var audit: Dictionary = Dictionary(cache.call("get_audit_snapshot"))
	var profile: Dictionary = Dictionary(cache.call("get_debug_profile_snapshot"))
	_assert(results == [true, true, true, true, true], "Repeated ordered point pair keeps the same result")
	_assert(registry.compute_count == 1, "Repeated ordered point pair computes terrain once")
	_assert(int(audit.get("asked_pair_count", -1)) == 5 and int(audit.get("actual_los_check_count", -1)) == 1 and int(audit.get("cache_hit_count", -1)) == 4, "Audit reports five asks, one LOS check and four cache hits")
	_assert(int(profile.get("counts", {}).get("cache_key_build", -1)) == 1, "Profile builds one cache key for the repeated pair")
	_assert(int(profile.get("counts", {}).get("los_cache_lookup", -1)) == 5, "Profile performs five cache lookups")

	cache.call("has_line_of_sight_between_points", source_position + Vector2(1.0, 0.0), target_position, -1.0, registry, "source", "target", compute)
	_assert(registry.compute_count == 2, "Source position change computes once")
	cache.call("has_line_of_sight_between_points", source_position, target_position + Vector2(1.0, 0.0), -1.0, registry, "source", "target", compute)
	_assert(registry.compute_count == 3, "Target position change computes once")
	registry.revision = 2
	cache.call("has_line_of_sight_between_points", source_position, target_position, -1.0, registry, "source", "target", compute)
	_assert(registry.compute_count == 4, "Terrain revision change computes once")
	var other_registry := RegistryDouble.new()
	other_registry.revision = 1
	other_registry.result = false
	root.add_child(other_registry)
	cache.call("has_line_of_sight_between_points", source_position, target_position, -1.0, other_registry, "source", "target", Callable(other_registry, "compute_visibility"))
	_assert(int(Dictionary(cache.call("get_audit_snapshot")).get("actual_los_check_count", -1)) == 5 and other_registry.compute_count == 1 and not bool(cache.call("has_line_of_sight_between_points", source_position, target_position, -1.0, other_registry, "source", "target", Callable(other_registry, "compute_visibility"))), "Registry identity change computes once and preserves distinct result")
	cache.call("has_line_of_sight_between_points", target_position, source_position, -1.0, other_registry, "target", "source", Callable(other_registry, "compute_visibility"))
	_assert(int(Dictionary(cache.call("get_audit_snapshot")).get("actual_los_check_count", -1)) == 6, "Reverse direction computes once")
	cache.call("begin_tick", 8)
	cache.call("has_line_of_sight_between_points", source_position, target_position, -1.0, other_registry, "source", "target", Callable(other_registry, "compute_visibility"))
	_assert(int(Dictionary(cache.call("get_audit_snapshot")).get("actual_los_check_count", -1)) == 1 and other_registry.compute_count == 3, "Next tick computes once")
	cache.call("set_cache_key_optimization_enabled", false)
	cache.call("set_debug_profiling_enabled", true)
	cache.call("set_debug_profile_scope_active", true)
	cache.call("begin_tick", 9)
	for _index in range(3):
		cache.call("has_line_of_sight_between_points", source_position, target_position, -1.0, other_registry, "source", "target", Callable(other_registry, "compute_visibility"))
	var toggle_off_audit: Dictionary = Dictionary(cache.call("get_audit_snapshot"))
	var toggle_off_profile: Dictionary = Dictionary(cache.call("get_debug_profile_snapshot"))
	_assert(int(toggle_off_profile.get("counts", {}).get("cache_key_build", -1)) == 3 and int(toggle_off_profile.get("counts", {}).get("los_cache_lookup", -1)) == 3 and int(toggle_off_audit.get("actual_los_check_count", -1)) == 1, "Optimization off builds and looks up every key while computing once")
	var final_profile: Dictionary = Dictionary(cache.call("get_debug_profile_snapshot"))
	_assert(bool(final_profile.get("read_only", false)) and not bool(final_profile.get("snapshot_serialized", true)), "Cache profile remains derived read-only and non-serialized")
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	cache.queue_free()
	quit(1 if _failed > 0 else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
