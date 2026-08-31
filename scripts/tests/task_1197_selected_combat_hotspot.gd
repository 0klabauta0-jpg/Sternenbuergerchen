extends SceneTree
const HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var harness = HARNESS_SCRIPT.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1197", 16, 12, 4, true)
	await process_frame
	var fixture_scene: Node = context.get("scene")
	var cache_for_contract = fixture_scene.get_node_or_null("CombatVisibilityCache") if fixture_scene != null else null
	_assert(cache_for_contract != null, "combat visibility cache present")
	_assert(cache_for_contract.has_method("set_cache_key_optimization_enabled"), "P02 cache-key optimization toggle exists")
	if cache_for_contract != null and cache_for_contract.has_method("set_cache_key_optimization_enabled"):
		_test_direct_cache_invalidation(cache_for_contract, context.get("terrain_registry"))
		await _test_four_way_oracle()
	harness.call("_prime_state", context, true)
	var driver: Node = context.get("combat_driver")
	var simulation_root: Node = context.get("simulation_root")
	driver.call("set_combat_tick_budget_debug_enabled", false)
	simulation_root.call("_physics_process", 0.1)
	var disabled := Dictionary(driver.call("get_combat_hotspot_debug_snapshot"))
	_assert(not bool(disabled.get("enabled", true)), "profiling disabled")
	_assert(Dictionary(disabled.get("counts", {})).is_empty(), "disabled counters empty")
	_assert(not bool(Dictionary(disabled.get("visibility_cache", {})).get("enabled", true)), "disabled cache profiling")
	_assert(not bool(Dictionary(disabled.get("visibility_cache", {})).get("scope_active", true)), "disabled cache scope")
	driver.call("set_combat_tick_budget_debug_enabled", true)
	for _i in range(600): simulation_root.call("_physics_process", 0.1)
	var enabled := Dictionary(driver.call("get_combat_hotspot_debug_snapshot"))
	print("TASK1197_DEBUG=" + JSON.stringify(enabled))
	var counts := Dictionary(enabled.get("counts", {}))
	for key in ["candidate_filter", "range_attackability"]: _assert(int(counts.get(key, 0)) > 0, key + " counted")
	var cache := Dictionary(enabled.get("visibility_cache", {}))
	var cache_counts := Dictionary(cache.get("counts", {}))
	_assert(bool(cache.get("enabled", false)), "cache profiling enabled")
	_assert(not bool(cache.get("scope_active", true)), "cache scope closed")
	for key in ["cache_key_build", "los_cache_lookup", "terrain_los_evaluation"]: _assert(int(cache_counts.get(key, 0)) > 0, key + " counted")
	_assert(int(cache_counts.get("cache_key_build", 0)) <= int(counts.get("range_attackability", 0)), "cache keys bounded by attackability")
	_assert(int(cache_counts.get("los_cache_lookup", 0)) == int(cache_counts.get("cache_key_build", 0)), "lookup matches keys")
	_assert(int(cache_counts.get("terrain_los_evaluation", 0)) <= int(cache_counts.get("los_cache_lookup", 0)), "terrain bounded by lookup")
	_assert(bool(enabled.get("derived_only", false)), "derived")
	_assert(bool(enabled.get("read_only", false)), "read-only")
	_assert(not bool(enabled.get("snapshot_serialized", true)), "not serialized")
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_direct_cache_invalidation(cache: Node, terrain_registry: Node) -> void:
	var source := Node2D.new()
	var target := Node2D.new()
	source.global_position = Vector2(10.0, 20.0)
	target.global_position = Vector2(40.0, 20.0)
	cache.call("set_cache_key_optimization_enabled", true)
	cache.call("begin_tick", 11)
	var calls := {"count": 0}
	var compute := func() -> bool:
		calls["count"] = int(calls["count"]) + 1
		return true
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	_assert(int(calls["count"]) == 1, "same ordered pair reuses key and geometry")
	cache.call("has_line_of_sight_between_points", target.global_position, source.global_position, -1.0, terrain_registry, "bravo", "alpha", compute)
	_assert(int(calls["count"]) == 2, "reverse direction remains isolated")
	source.global_position += Vector2(1.0, 0.0)
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	_assert(int(calls["count"]) == 3, "same-tick position invalidates reuse")
	if terrain_registry != null and terrain_registry.has_method("_bump_revision"):
		terrain_registry.call("_bump_revision")
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	_assert(int(calls["count"]) == 4, "same-tick terrain revision invalidates reuse")
	cache.call("begin_tick", 12)
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	_assert(int(calls["count"]) == 5, "next tick invalidates reuse")
	cache.call("begin_tick", 14)
	cache.call("set_cache_key_optimization_enabled", false)
	var off_result = cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	cache.call("set_cache_key_optimization_enabled", true)
	cache.call("begin_tick", 15)
	var on_result = cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "alpha", "bravo", compute)
	_assert(bool(off_result) == bool(on_result), "optimization off and on return identical geometry")
	cache.call("begin_tick", 16)
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "a|b", "c", compute)
	cache.call("has_line_of_sight_between_points", source.global_position, target.global_position, -1.0, terrain_registry, "a", "b|c", compute)
	_assert(int(calls["count"]) == 9, "structured pair identity prevents delimiter collisions")
	source.free()
	target.free()

func _test_four_way_oracle() -> void:
	var snapshots: Dictionary = {}
	for index_enabled in [false, true]:
		for optimization_enabled in [false, true]:
			var key := "p01_%s_p02_%s" % ["on" if index_enabled else "off", "on" if optimization_enabled else "off"]
			snapshots[key] = await _run_oracle_fixture(index_enabled, optimization_enabled)
	var baseline: Dictionary = snapshots.get("p01_off_p02_off", {})
	for key in snapshots.keys():
		_assert(String(Dictionary(snapshots[key]).get("canonical", "")) == String(baseline.get("canonical", "")), "four-way gameplay bit-exact: %s" % key)
	for index_key in ["off", "on"]:
		var off_audit: Dictionary = Dictionary(snapshots.get("p01_%s_p02_off" % index_key, {}).get("audit", {}))
		var on_audit: Dictionary = Dictionary(snapshots.get("p01_%s_p02_on" % index_key, {}).get("audit", {}))
		_assert(off_audit == on_audit, "unchanged cache audit equal for P01 %s" % index_key)
	var diagnostic_off: Dictionary = Dictionary(snapshots["p01_off_p02_off"].get("diagnostic", {}))
	var diagnostic_on: Dictionary = Dictionary(snapshots["p01_off_p02_on"].get("diagnostic", {}))
	_assert(Dictionary(diagnostic_off.get("counts", {})) == Dictionary(diagnostic_on.get("counts", {})), "same-seed diagnostic counts equal P02 off/on")
	print("TASK1197_DIAGNOSTIC_OFF=" + JSON.stringify(diagnostic_off))
	print("TASK1197_DIAGNOSTIC_ON=" + JSON.stringify(diagnostic_on))

func _run_oracle_fixture(index_enabled: bool, optimization_enabled: bool) -> Dictionary:
	seed(1197)
	var harness = HARNESS_SCRIPT.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1197_oracle", 16, 12, 4, true)
	await process_frame
	var scene: Node = context.get("scene")
	var driver: Node = context.get("combat_driver")
	var simulation_root: Node = context.get("simulation_root")
	var cache: Node = scene.get_node_or_null("CombatVisibilityCache") if scene != null else null
	if driver == null or simulation_root == null or cache == null:
		return {"canonical": "missing_fixture", "audit": {}, "diagnostic": {}}
	driver.call("set_use_observed_fire_candidate_index", index_enabled)
	cache.call("set_cache_key_optimization_enabled", optimization_enabled)
	simulation_root.call("set_unit_minimum_spacing_enabled", false)
	harness.call("_prime_state", context, true)
	for _tick in range(600):
		simulation_root.call("_physics_process", 0.1)
	var unit_states: Array = []
	for unit_variant in Array(context.get("friendly_units", [])) + Array(context.get("enemy_units", [])):
		var unit = unit_variant as Node
		unit_states.append({"id": String(unit.call("get_unit_id")), "health": int(unit.call("get_health")) if unit.has_method("get_health") else 0, "vital": String(unit.call("get_vital_state")), "position": (unit as Node2D).global_position})
	unit_states.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["id"]) < String(b["id"]))
	var snapshot := JSON.stringify({"contacts": driver.call("get_contact_snapshot"), "detection": driver.get("_detection_progress"), "fire_events": driver.call("get_fire_event_snapshot"), "enemy_security": driver.call("get_enemy_security_snapshot"), "enemy_tactics": driver.call("get_enemy_team_tactics_snapshot"), "mission_result": driver.call("get_mission_result"), "unit_states": unit_states})
	var audit: Dictionary = Dictionary(cache.call("get_audit_snapshot"))
	var diagnostic: Dictionary = Dictionary(driver.call("get_combat_hotspot_debug_snapshot"))
	scene.queue_free()
	await process_frame
	return {"canonical": snapshot, "audit": audit, "diagnostic": diagnostic}
func _assert(condition: bool, message: String) -> void:
	if condition: passed += 1; print("PASS: %s" % message)
	else: failed += 1; print("FAIL: %s" % message)
