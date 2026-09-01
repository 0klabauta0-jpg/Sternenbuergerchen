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
	if OS.get_cmdline_user_args().has("--task1206-topology-evidence"):
		await _run_topology_evidence()
		return
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
	driver.call("set_task1206_analysis_configuration", "shared_tick_result_contract", false, true)
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
	var frozen_cost_tags := ["contact_tracking", "enemy_security", "enemy_team_tactics", "fire_pair_search", "other_combat"]
	var expected_cost_consumer_counts := {
		"signature_key_build": {"contact_tracking": 1, "enemy_security": 1, "enemy_team_tactics": 0, "fire_pair_search": 1, "other_combat": 0},
		"cache_lookup": {"contact_tracking": 1, "enemy_security": 1, "enemy_team_tactics": 0, "fire_pair_search": 1, "other_combat": 0},
		"entry_write": {"contact_tracking": 1, "enemy_security": 1, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
		"terrain_los": {"contact_tracking": 1, "enemy_security": 1, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
	}
	var expected_cost_totals := {"signature_key_build": 3, "cache_lookup": 3, "entry_write": 2, "terrain_los": 2}
	var actual_costs: Array = costs.keys()
	actual_costs.sort()
	_assert(actual_costs == expected_costs, "cost groups are exactly the frozen four")
	_assert(consumers.get("contact_tracking", {}) is Dictionary and int(consumers["contact_tracking"].get("request_count", 0)) == 1, "contact_tracking exact A->B consumer")
	_assert(consumers.get("fire_pair_search", {}) is Dictionary and int(consumers["fire_pair_search"].get("request_count", 0)) == 1, "fire_pair_search exact A->B consumer")
	_assert(int(overlap.get("reverse_pair_opportunity_count", 0)) == 1, "reverse pair is offered without reuse")
	for cost_name in ["signature_key_build", "cache_lookup", "entry_write", "terrain_los"]:
		var cost_group: Dictionary = costs.get(cost_name, {})
		_assert(cost_group.has("count") and cost_group.has("usec"), "cost group exposes count/usec: %s" % cost_name)
		_assert(int(cost_group.get("count", -1)) == int(expected_cost_totals[cost_name]), "exact global cost count: %s" % cost_name)
	_assert(int(costs.get("terrain_los", {}).get("count", 0)) == 2 and _terrain_calls == 2, "exact pair and reverse evaluate terrain once each")
	_assert(int(topology.get("range_rejected_count", overlap.get("range_rejected_count", 0))) == 1 and _terrain_calls == 2, "range reject avoids terrain call")
	_assert(int(overlap.get("exact_cross_consumer_hit_count", 0)) == 1, "exact cross-consumer hit is counted")
	_assert(int(overlap.get("exact_contact_producer_fire_probe_count", 0)) == 1, "contact producer fire probe is counted")
	_assert(int(overlap.get("missing_producer_count", 0)) == 0, "producer attribution is complete")
	cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(21, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	for cost_name in expected_costs:
		var nested: Dictionary = costs[cost_name].get("consumers", {})
		var nested_tags: Array = nested.keys(); nested_tags.sort()
		_assert(nested_tags == frozen_cost_tags, "cost consumer tags: %s" % cost_name)
		for tag in frozen_cost_tags:
			_assert(nested[tag] is Dictionary and nested[tag].has("count") and nested[tag].has("usec"), "cost consumer count/usec: %s/%s" % [cost_name, tag])
			_assert(int(nested[tag]["count"]) == int(expected_cost_consumer_counts[cost_name][tag]), "exact consumer cost count: %s/%s" % [cost_name, tag])
		var count_sum := 0; var usec_sum := 0
		for tag in frozen_cost_tags: count_sum += int(nested[tag]["count"]); usec_sum += int(nested[tag]["usec"])
		_assert(count_sum == int(costs[cost_name]["count"]) and usec_sum == int(costs[cost_name]["usec"]), "cost totals reconcile: %s" % cost_name)
	var registry_same_revision := RegistryDouble.new()
	cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry_same_revision, "alpha", "bravo", compute, "contact_tracking")
	_assert(_terrain_calls == 4, "registry identity invalidates same-revision reuse")
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
	var validity: Dictionary = bounded_dump.get("validity", {})
	var frozen_validity_metrics := ["direction", "registry_identity", "registry_revision", "source_position", "target_position", "tick"]
	var actual_validity_metrics: Array = validity.keys()
	actual_validity_metrics.sort()
	_assert(actual_validity_metrics == frozen_validity_metrics, "validity metrics are exactly the frozen six")
	var expected_validity_counts := {
		"direction": 1,
		"registry_identity": 2,
		"registry_revision": 1,
		"source_position": 1,
		"target_position": 2,
		"tick": 1,
	}
	var expected_validity_consumer_counts := {
		"direction": {"contact_tracking": 0, "enemy_security": 1, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
		"registry_identity": {"contact_tracking": 2, "enemy_security": 0, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
		"registry_revision": {"contact_tracking": 1, "enemy_security": 0, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
		"source_position": {"contact_tracking": 1, "enemy_security": 0, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
		"target_position": {"contact_tracking": 2, "enemy_security": 0, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
		"tick": {"contact_tracking": 1, "enemy_security": 0, "enemy_team_tactics": 0, "fire_pair_search": 0, "other_combat": 0},
	}
	for metric in frozen_validity_metrics:
		var validity_group: Dictionary = validity.get(metric, {})
		_assert(int(validity_group.get("count", -1)) == int(expected_validity_counts[metric]), "exact validity count: %s" % metric)
		var validity_consumers: Dictionary = validity_group.get("consumers", {})
		var actual_validity_tags: Array = validity_consumers.keys()
		actual_validity_tags.sort()
		_assert(actual_validity_tags == frozen_cost_tags, "validity consumer tags: %s" % metric)
		for tag in frozen_cost_tags:
			_assert(int(validity_consumers.get(tag, -1)) == int(expected_validity_consumer_counts[metric][tag]), "exact validity consumer count: %s/%s" % [metric, tag])
	_assert(_terrain_calls == 7, "source position, registry revision and tick invalidate reuse")
	_assert(cache.call("get_task1206_analysis_snapshot").get("pair_dump", null) == null, "normal snapshot has no pair dump")
	_assert(pair_dump is Array and pair_dump.size() <= 32, "explicit pair dump is bounded to 32")
	cache.call("configure_task1206_analysis", "off", false, false)
	cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(200, 10), 5.0, registry, "off_source", "off_target", compute, "contact_tracking")
	var off_snapshot: Dictionary = cache.call("get_task1206_analysis_snapshot")
	var off_consumers: Dictionary = off_snapshot.get("consumers", {})
	var off_costs: Dictionary = off_snapshot.get("costs", {})
	_assert(int(off_snapshot.get("overlap", {}).get("range_rejected_count", 0)) == 0, "default-off overlap diagnostics stay inert")
	_assert(int(off_consumers.get("contact_tracking", {}).get("request_count", 0)) == 0, "default-off consumer diagnostics stay inert")
	_assert(int(off_costs.get("cache_lookup", {}).get("count", 0)) == 0 and int(off_costs.get("terrain_los", {}).get("count", 0)) == 0, "default-off costs stay inert")
	print("TASK1206_TOPOLOGY_CONTRACT_OK")

	print("TASK1206_RESULT: %d passed, %d failed" % [_passed, _failed])
	driver.free()
	quit(1 if _failed > 0 else 0)

func _run_topology_evidence() -> void:
	var sha := OS.get_environment("STERNENBUERGERCHEN_GIT_SHA")
	if sha.is_empty():
		push_error("STERNENBUERGERCHEN_GIT_SHA is required")
		quit(1)
		return
	var harness_script: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
	seed(1206)
	var control: Dictionary = await _run_topology_fixture(harness_script, false)
	seed(1206)
	var measured: Dictionary = await _run_topology_fixture(harness_script, true)
	if not bool(control.get("ok", false)) or not bool(measured.get("ok", false)):
		push_error("TASK1206 topology fixture failed")
		quit(1)
		return
	if String(control.get("oracle_hash", "")) != String(measured.get("oracle_hash", "")):
		push_error("TASK1206 topology/control oracle mismatch")
		quit(1)
		return
	var topology: Dictionary = Dictionary(measured.get("topology", {}))
	var consumers: Dictionary = Dictionary(topology.get("consumers", {}))
	var expected_consumers := ["contact_tracking", "fire_pair_search", "enemy_security", "enemy_team_tactics", "other_combat"]
	var actual_consumers: Array = consumers.keys(); actual_consumers.sort()
	var sorted_expected := expected_consumers.duplicate(); sorted_expected.sort()
	if actual_consumers != sorted_expected:
		push_error("TASK1206 consumer schema mismatch")
		quit(1)
		return
	var pair_dump_size := Array(topology.get("pair_dump", [])).size()
	if pair_dump_size > 32:
		push_error("TASK1206 pair dump exceeds 32")
		quit(1)
		return
	var evidence := {
		"schema": "sternenbuergerchen.task1206.visibility_topology.v1",
		"git_sha": sha,
		"ticks": 600,
		"aggregates": topology,
		"pair_dump_size": pair_dump_size,
		"canonical_gameplay_oracle_sha256": measured.get("oracle_hash", ""),
		"control_gameplay_oracle_sha256": control.get("oracle_hash", ""),
		"oracle_match": true
	}
	print("TASK1206_TOPOLOGY_JSON=" + JSON.stringify(evidence))
	quit(0)

func _run_topology_fixture(harness_script: GDScript, topology_enabled: bool) -> Dictionary:
	var harness = harness_script.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1206_topology", 16, 12, 4, true)
	await process_frame
	var driver: Node = context.get("combat_driver")
	var simulation_root: Node = context.get("simulation_root")
	var scene: Node = context.get("scene")
	if driver == null or simulation_root == null or scene == null:
		return {"ok": false, "oracle_hash": ""}
	driver.call("set_task1206_analysis_configuration", "off", false, topology_enabled)
	simulation_root.call("set_unit_minimum_spacing_enabled", false)
	harness.call("_prime_state", context, true)
	for _tick in range(600):
		simulation_root.call("_physics_process", 0.1)
	var canonical := JSON.stringify({"contacts": driver.call("get_contact_snapshot"), "detection": driver.get("_detection_progress"), "fire_events": driver.call("get_fire_event_snapshot"), "enemy_security": driver.call("get_enemy_security_snapshot"), "enemy_tactics": driver.call("get_enemy_team_tactics_snapshot"), "mission_result": driver.call("get_mission_result")})
	var hash_ctx := HashingContext.new()
	hash_ctx.start(HashingContext.HASH_SHA256)
	hash_ctx.update(canonical.to_utf8_buffer())
	var result := {"ok": true, "oracle_hash": hash_ctx.finish().hex_encode()}
	if topology_enabled:
		result["topology"] = Dictionary(driver.call("get_task1206_visibility_analysis_snapshot", true))
	scene.free()
	return result
