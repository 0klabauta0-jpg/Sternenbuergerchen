extends SceneTree

const CACHE_SCRIPT: GDScript = preload("res://scripts/mission/combat_visibility_cache.gd")
const DRIVER_SCRIPT: GDScript = preload("res://scripts/tests/mission_combat_loop_driver.gd")

class RegistryDouble extends RefCounted:
	var revision: int = 7
	func get_revision() -> int: return revision
	func world_to_grid(position: Vector2) -> Vector2i: return Vector2i(roundi(position.x), roundi(position.y))
	func get_height_at_world(_position: Vector2) -> int: return 0

var _passed: int = 0
var _failed: int = 0
var _terrain_calls: int = 0

func _init() -> void:
	call_deferred("_run")

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)

func _compute_visibility() -> bool:
	_terrain_calls += 1
	return true

func _run() -> void:
	var cache = CACHE_SCRIPT.new()
	var cache_api := [
		"configure_task1206_analysis",
		"get_task1206_analysis_snapshot",
	]
	for method_name in cache_api:
		if not cache.has_method(method_name):
			print("TASK1206_API_MISSING: %s" % method_name)
			cache.free()
			quit(1)
			return
	var driver = DRIVER_SCRIPT.new()
	for method_name in ["set_task1206_analysis_configuration", "get_task1206_visibility_analysis_snapshot"]:
		if not driver.has_method(method_name):
			print("TASK1206_API_MISSING: %s" % method_name)
			cache.free()
			driver.free()
			quit(1)
			return
	cache.name = "CombatVisibilityCache"
	driver.add_child(cache)
	driver.combat_visibility_cache_path = NodePath("CombatVisibilityCache")

	var registry := RegistryDouble.new()
	var compute := Callable(self, "_compute_visibility")
	var initial_snapshot: Dictionary = cache.call("get_task1206_analysis_snapshot")
	var initial_driver_snapshot: Dictionary = driver.call("get_task1206_visibility_analysis_snapshot")
	_assert(String(initial_snapshot.get("variant", "")) == "off", "initial default variant is off")
	_assert(not bool(initial_snapshot.get("enabled", true)), "initial analysis is disabled")
	_assert(not bool(initial_snapshot.get("topology_enabled", true)), "initial topology is disabled")
	_assert(bool(initial_snapshot.get("derived_only", false)), "analysis is derived-only")
	_assert(bool(initial_snapshot.get("read_only", false)), "analysis is read-only")
	_assert(initial_snapshot.get("snapshot_serialized", true) == false, "analysis snapshot is not serialized")
	_assert(initial_driver_snapshot == initial_snapshot, "driver bridge matches initial cache snapshot")
	_assert(String(initial_driver_snapshot.get("variant", "")) == "off" and not bool(initial_driver_snapshot.get("enabled", true)), "driver bridge is initially default-off")
	cache.call("begin_tick", 41)
	driver.call("set_task1206_analysis_configuration", "shared_tick_result_contract", true, true)
	cache.call("begin_tick", 41)
	_terrain_calls = 0
	cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "fire_pair_search")
	cache.call("has_line_of_sight_between_points", Vector2(20, 10), Vector2(10, 10), -1.0, registry, "bravo", "alpha", compute, "enemy_security")
	cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(200, 10), 5.0, registry, "alpha", "far", compute, "other_combat")
	var topology: Dictionary = driver.call("get_task1206_visibility_analysis_snapshot")
	var cache_topology: Dictionary = cache.call("get_task1206_analysis_snapshot")
	_assert(topology == cache_topology, "driver bridge matches configured cache snapshot")
	var consumers: Dictionary = topology.get("consumers", {})
	var overlap: Dictionary = topology.get("overlap", {})
	var costs: Dictionary = topology.get("costs", {})
	var expected_costs := ["cache_lookup", "entry_write", "signature_key_build", "terrain_los"]
	var actual_costs: Array = costs.keys()
	actual_costs.sort()
	_assert(actual_costs == expected_costs, "cost groups are exactly the frozen four")
	_assert(consumers.get("contact_tracking", {}) is Dictionary and int(consumers["contact_tracking"].get("request_count", 0)) == 1, "contact_tracking exact A->B consumer")
	_assert(consumers.get("fire_pair_search", {}) is Dictionary and int(consumers["fire_pair_search"].get("request_count", 0)) == 1, "fire_pair_search exact A->B consumer")
	_assert(int(overlap.get("reverse_pair_opportunity_count", 0)) == 1, "reverse pair is offered without reuse")
	for cost_name in ["signature_key_build", "cache_lookup", "entry_write", "terrain_los"]:
		var cost_group: Dictionary = costs.get(cost_name, {})
		_assert(cost_group.has("count") and cost_group.has("usec"), "cost group exposes count/usec: %s" % cost_name)
	_assert(int(costs.get("terrain_los", {}).get("count", 0)) == 2 and _terrain_calls == 2, "exact pair and reverse evaluate terrain once each")
	_assert(int(topology.get("range_rejected_count", overlap.get("range_rejected_count", 0))) == 1 and _terrain_calls == 2, "range reject avoids terrain call")
	_assert(int(overlap.get("exact_cross_consumer_hit_count", 0)) == 1, "exact cross-consumer hit is counted")
	var expected_tags := ["contact_tracking", "enemy_security", "enemy_team_tactics", "fire_pair_search", "other_combat"]
	var actual_tags: Array = consumers.keys()
	actual_tags.sort()
	_assert(actual_tags == expected_tags, "consumer tags are exactly the frozen five")
	for tag in expected_tags:
		var aggregate: Dictionary = consumers[tag]
		_assert(aggregate.has("request_count") and aggregate.has("unique_ordered_pair_count") and aggregate.has("same_consumer_repeat_count"), "consumer aggregate fields: %s" % tag)
	_assert(bool(topology.get("derived_only", false)), "snapshot is derived-only")
	_assert(bool(topology.get("read_only", false)), "snapshot is read-only")
	_assert(topology.get("snapshot_serialized", true) == false, "snapshot is not serialized")
	_assert(not topology.has("architecture_flags"), "no unplanned nested architecture flags")

	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	registry.revision = 8
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	cache.call("begin_tick", 42)
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	var bounded_dump: Dictionary = cache.call("get_task1206_analysis_snapshot", true)
	var pair_dump = bounded_dump.get("pair_dump", [])
	_assert(_terrain_calls == 5, "source position, registry revision and tick invalidate reuse")
	_assert(cache.call("get_task1206_analysis_snapshot").get("pair_dump", null) == null, "normal snapshot has no pair dump")
	_assert(pair_dump is Array and pair_dump.size() <= 32, "explicit pair dump is bounded to 32")

	print("TASK1206_RESULT: %d passed, %d failed" % [_passed, _failed])
	driver.free()
	quit(1 if _failed > 0 else 0)
