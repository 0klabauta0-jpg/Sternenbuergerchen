extends SceneTree

const COMBAT_VISIBILITY_CACHE_SCRIPT: GDScript = preload("res://scripts/mission/combat_visibility_cache.gd")
const COMBAT_FIXTURE_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
const DRIVER_SOURCE_PATH: String = "res://scripts/tests/mission_combat_loop_driver.gd"
const DETERMINISTIC_TICKS: int = 600

var _passed: int = 0
var _failed: int = 0


class TerrainStub:
	var revision: int = 1

	func world_to_grid(world_position: Vector2) -> Vector2i:
		return Vector2i(roundi(world_position.x / 32.0), roundi(world_position.y / 32.0))

	func get_height_at_world(_world_position: Vector2) -> int:
		return 0

	func get_revision() -> int:
		return revision


class VisibilityUnit extends Node2D:
	var unit_id: String

	func _init(next_unit_id: String, next_position: Vector2) -> void:
		unit_id = next_unit_id
		global_position = next_position

	func get_unit_id() -> String:
		return unit_id


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1191 Shared Combat Visibility Cache ===")
	_test_contract_is_present()
	_test_same_tick_query_is_evaluated_once()
	_test_order_revision_position_and_tick_are_isolated()
	await _test_16v12_cache_on_off_is_deterministic()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_contract_is_present() -> void:
	var source: String = FileAccess.get_file_as_string(DRIVER_SOURCE_PATH)
	_assert(source.contains("COMBAT_VISIBILITY_CACHE_SCRIPT"), "Combat driver loads the shared visibility cache")
	_assert(source.contains("combat_visibility_cache_path"), "Combat driver wires a derived cache node")
	_assert(source.contains("contact_tracking_los_cache_status"), "Combat hotpath audit exposes cache status")


func _test_same_tick_query_is_evaluated_once() -> void:
	var cache: Node = COMBAT_VISIBILITY_CACHE_SCRIPT.new()
	var terrain := TerrainStub.new()
	var source := VisibilityUnit.new("friendly_alpha", Vector2(32.0, 32.0))
	var target := VisibilityUnit.new("enemy_bravo", Vector2(96.0, 32.0))
	var counter: Dictionary = {"occlusion_calls": 0}
	cache.call("begin_tick", 41)
	var clear_once: bool = bool(cache.call("has_line_of_sight_between_nodes", source, target, 160.0, terrain, func() -> bool:
		counter["occlusion_calls"] = int(counter.get("occlusion_calls", 0)) + 1
		return true
	))
	var clear_twice: bool = bool(cache.call("has_line_of_sight_between_nodes", source, target, 160.0, terrain, func() -> bool:
		counter["occlusion_calls"] = int(counter.get("occlusion_calls", 0)) + 1
		return true
	))
	var audit: Dictionary = Dictionary(cache.call("get_audit_snapshot"))
	_assert(clear_once and clear_twice and int(counter.get("occlusion_calls", 0)) == 1, "Equal ordered node queries share one terrain occlusion")
	_assert(int(audit.get("asked_pair_count", 0)) == 2 and int(audit.get("actual_los_check_count", 0)) == 1 and int(audit.get("cache_hit_count", 0)) == 1, "Audit separates asks, terrain checks and cache hits")
	source.free()
	target.free()
	cache.free()


func _test_order_revision_position_and_tick_are_isolated() -> void:
	var cache: Node = COMBAT_VISIBILITY_CACHE_SCRIPT.new()
	var terrain := TerrainStub.new()
	var source := VisibilityUnit.new("friendly_alpha", Vector2(32.0, 32.0))
	var target := VisibilityUnit.new("enemy_bravo", Vector2(96.0, 32.0))
	var counter: Dictionary = {"occlusion_calls": 0}
	cache.call("begin_tick", 51)
	for query in [
		{"source": source, "target": target},
		{"source": target, "target": source},
	]:
		cache.call("has_line_of_sight_between_nodes", query.source, query.target, 160.0, terrain, func() -> bool:
			counter["occlusion_calls"] = int(counter.get("occlusion_calls", 0)) + 1
			return true
		)
	terrain.revision += 1
	cache.call("has_line_of_sight_between_nodes", source, target, 160.0, terrain, func() -> bool:
		counter["occlusion_calls"] = int(counter.get("occlusion_calls", 0)) + 1
		return true
	)
	source.global_position += Vector2(2.0, 0.0)
	cache.call("has_line_of_sight_between_nodes", source, target, 160.0, terrain, func() -> bool:
		counter["occlusion_calls"] = int(counter.get("occlusion_calls", 0)) + 1
		return true
	)
	cache.call("begin_tick", 52)
	cache.call("has_line_of_sight_between_nodes", source, target, 160.0, terrain, func() -> bool:
		counter["occlusion_calls"] = int(counter.get("occlusion_calls", 0)) + 1
		return true
	)
	_assert(int(counter.get("occlusion_calls", 0)) == 5, "Direction, revision, in-cell position and tick do not reuse stale geometry")
	source.free()
	target.free()
	cache.free()


func _test_16v12_cache_on_off_is_deterministic() -> void:
	var without_cache: Dictionary = await _run_16v12_fixture(false)
	var with_cache: Dictionary = await _run_16v12_fixture(true)
	_assert(String(without_cache.get("canonical_snapshot", "")) == String(with_cache.get("canonical_snapshot", "")), "16v12 cache on/off keeps 600 ticks bit-exact for contacts, detection, fire, hits and mission result")
	var cache_audit: Dictionary = Dictionary(with_cache.get("visibility_cache_audit", {}))
	_assert(int(cache_audit.get("cache_hit_count", 0)) > 0, "16v12 fixture records shared visibility cache hits")
	_assert(int(cache_audit.get("actual_los_check_count", 0)) <= int(cache_audit.get("asked_pair_count", 0)), "16v12 cache never performs more terrain LOS checks than visibility asks")
	_assert(int(with_cache.get("tactics_rebuild_count", 0)) >= 1, "16v12 fixture reports enemy tactics rebuilds alongside visibility metrics")
	_assert(bool(with_cache.get("units_moved", false)), "16v12 fixture exercises active combat movement during the cache comparison")


func _run_16v12_fixture(cache_enabled: bool) -> Dictionary:
	seed(1191)
	var harness = COMBAT_FIXTURE_HARNESS_SCRIPT.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1191_%s" % ("cache_on" if cache_enabled else "cache_off"), 16, 12, 4, true)
	var scene: Node = context.get("scene", null)
	var driver: Node = context.get("combat_driver", null)
	var simulation_root: Node = context.get("simulation_root", null)
	if scene == null or driver == null or simulation_root == null:
		return {}
	# The cache comparison holds the same command and combat sequence on both
	# sides. Minimum-spacing is covered by the dedicated Task 1187 fixture and
	# would otherwise only dominate this 600-tick visibility regression.
	simulation_root.call("set_unit_minimum_spacing_enabled", false)
	if cache_enabled:
		var cache: Node = COMBAT_VISIBILITY_CACHE_SCRIPT.new()
		cache.name = "CombatVisibilityCache"
		scene.add_child(cache)
		driver.set("combat_visibility_cache_path", NodePath("../CombatVisibilityCache"))
	else:
		driver.set("combat_visibility_cache_path", NodePath("../MissingCombatVisibilityCache"))
	await process_frame
	harness.call("_prime_state", context, true)
	var initial_positions_by_unit_id: Dictionary = _capture_unit_positions(context)
	var cumulative_cache_audit: Dictionary = {
		"asked_pair_count": 0,
		"actual_los_check_count": 0,
		"cache_hit_count": 0,
	}
	for _tick_index in range(DETERMINISTIC_TICKS):
		simulation_root.call("_physics_process", 0.1)
		var hotpath_audit: Dictionary = Dictionary(driver.call("get_combat_hotpath_audit_snapshot"))
		var visibility_cache_audit: Dictionary = Dictionary(hotpath_audit.get("visibility_cache", {}))
		for metric_name in cumulative_cache_audit.keys():
			cumulative_cache_audit[metric_name] = int(cumulative_cache_audit.get(metric_name, 0)) + int(visibility_cache_audit.get(metric_name, 0))
	var result: Dictionary = {
		"canonical_snapshot": _build_canonical_fixture_snapshot(driver, context),
		"visibility_cache_audit": cumulative_cache_audit,
		"tactics_rebuild_count": int(Dictionary(driver.call("get_enemy_team_tactics_runtime_guard_snapshot")).get("rebuild_count", 0)),
		"units_moved": _units_moved_from_positions(context, initial_positions_by_unit_id),
	}
	scene.queue_free()
	await process_frame
	return result


func _build_canonical_fixture_snapshot(driver: Node, context: Dictionary) -> String:
	var unit_states: Array = []
	for unit_variant in Array(context.get("friendly_units", [])) + Array(context.get("enemy_units", [])):
		var unit = unit_variant as Node
		if unit == null:
			continue
		unit_states.append({
			"unit_id": String(unit.call("get_unit_id")) if unit.has_method("get_unit_id") else "",
			"vital_state": String(unit.call("get_vital_state")) if unit.has_method("get_vital_state") else "",
			"health": int(unit.call("get_health")) if unit.has_method("get_health") else int(unit.get("health")),
			"position": (unit as Node2D).global_position if unit is Node2D else Vector2.ZERO,
		})
	unit_states.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.get("unit_id", "")) < String(b.get("unit_id", "")))
	return JSON.stringify({
		"contacts": driver.call("get_contact_snapshot"),
		"detection_progress": driver.get("_detection_progress"),
		"fire_events": driver.call("get_fire_event_snapshot"),
		"mission_result": driver.call("get_mission_result"),
		"enemy_security": driver.call("get_enemy_security_snapshot"),
		"enemy_team_tactics": driver.call("get_enemy_team_tactics_snapshot"),
		"unit_states": unit_states,
	})


func _capture_unit_positions(context: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for unit_variant in Array(context.get("friendly_units", [])) + Array(context.get("enemy_units", [])):
		var unit = unit_variant as Node2D
		if unit != null and unit.has_method("get_unit_id"):
			result[String(unit.call("get_unit_id"))] = unit.global_position
	return result


func _units_moved_from_positions(context: Dictionary, initial_positions_by_unit_id: Dictionary) -> bool:
	for unit_variant in Array(context.get("friendly_units", [])) + Array(context.get("enemy_units", [])):
		var unit = unit_variant as Node2D
		if unit == null or not unit.has_method("get_unit_id"):
			continue
		var unit_id: String = String(unit.call("get_unit_id"))
		var initial_position: Variant = initial_positions_by_unit_id.get(unit_id, null)
		if typeof(initial_position) == TYPE_VECTOR2 and unit.global_position.distance_squared_to(Vector2(initial_position)) > 0.001:
			return true
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
