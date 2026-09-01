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

func _task1206_paired_runner_contract_is_present() -> bool:
	var runner_path := "res://scripts/tests/run_task_1187_tactical_map_frame_budget.ps1"
	var harness_path := "res://scripts/tests/tactical_map_frame_budget_harness.gd"
	if not FileAccess.file_exists(runner_path) or not FileAccess.file_exists(harness_path):
		return false
	var source := FileAccess.get_file_as_string(runner_path) + "\n" + FileAccess.get_file_as_string(harness_path)
	var required_tokens := [
		"Task1206Variant",
		"Task1206Paired",
		"QuietWindowSeconds",
		"STERNENBUERGERCHEN_TASK1206_VARIANT",
		"STERNENBUERGERCHEN_TASK1206_ENABLED",
		"STERNENBUERGERCHEN_TASK1206_TOPOLOGY",
		"TASK_1206_VISIBILITY_AB_JSON=",
		"sternenbuergerchen.task1206.visibility_ab.v1",
		"pair_count = 8",
		"off,on,on,off,on,off,off,on,off,on,on,off,on,off,off,on",
		"scopes.\"combat.total_tick_usec\".p99",
		"scopes.\"combat_scope.combat_fire_decision_usec\".p99",
		"scopes.\"combat_scope.fire_find_contact_pair_usec\".p99",
		"scopes.\"combat.contact_tracking_usec\".p99",
		"scopes.\"combat_scope.enemy_team_tactics_usec\".p99",
		"scopes.\"simulation.total_tick_usec\".p99",
		"scopes.\"simulation_scope.command_queue_usec\".p99",
	]
	for token in required_tokens:
		if not source.contains(token):
			return false
	return true

func _compute_visibility() -> bool:
	_terrain_calls += 1
	return true

func _run() -> void:
	if OS.get_cmdline_user_args().has("--task1206-variant-a-evidence"):
		await _run_variant_a_evidence()
		return
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
	driver.call("set_task1206_analysis_configuration", "shared_tick_result_contract", true, false)
	cache.call("begin_tick", 40)
	# Variant-A direct contract: the shared tick result is directed, exact-validity,
	# tick-local and exposes no gameplay/snapshot surface.
	if not cache.has_method("_task1206_get_shared_tick_result"):
		print("TASK1206_VARIANT_A_MISSING")
		driver.free()
		quit(1)
		return
	_terrain_calls = 0
	var range_rejected := bool(cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(200, 10), 5.0, registry, "range_source", "range_target", compute, "other_combat"))
	_assert(not range_rejected and _terrain_calls == 0, "Variant A range rejection precedes result access")
	var first_clear := bool(cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking"))
	var store: Dictionary = cache.get("_shared_tick_results")
	var result_a: Dictionary = Dictionary(store.get("alpha", {})).get("bravo", {})
	var exact_fields := ["clear", "derived_only", "read_only", "registry_identity", "snapshot_serialized", "source_id", "source_position", "target_id", "target_position", "terrain_revision", "tick"]
	var actual_fields: Array = result_a.keys()
	actual_fields.sort()
	_assert(actual_fields == exact_fields, "Variant A result exposes exactly the frozen fields")
	_assert(first_clear and _terrain_calls == 1, "Variant A first exact call materializes one terrain result")
	_assert(result_a.is_read_only(), "Variant A stored result is immutable")
	_assert(result_a.tick == 40 and result_a.source_id == "alpha" and result_a.target_id == "bravo", "Variant A directed identity values")
	_assert(result_a.source_position == Vector2(10, 10) and result_a.target_position == Vector2(20, 10), "Variant A position values")
	_assert(result_a.registry_identity == registry.get_instance_id() and result_a.terrain_revision == 7 and result_a.clear, "Variant A validity values")
	_assert(bool(result_a.derived_only) and bool(result_a.read_only) and result_a.snapshot_serialized == false, "Variant A result architecture flags")
	var second_clear := bool(cache.call("has_line_of_sight_between_points", Vector2(10, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "fire_pair_search"))
	_assert(second_clear and _terrain_calls == 1, "Variant A second exact call reuses without terrain work")
	cache.call("has_line_of_sight_between_points", Vector2(20, 10), Vector2(10, 10), -1.0, registry, "bravo", "alpha", compute, "enemy_security")
	_assert(_terrain_calls == 2, "Variant A reverse direction cannot reuse")
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(20, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	_assert(_terrain_calls == 3, "Variant A source-position change cannot reuse")
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(21, 10), -1.0, registry, "alpha", "bravo", compute, "contact_tracking")
	_assert(_terrain_calls == 4, "Variant A target-position change cannot reuse")
	var a_registry_same_revision := RegistryDouble.new()
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(21, 10), -1.0, a_registry_same_revision, "alpha", "bravo", compute, "contact_tracking")
	_assert(_terrain_calls == 5, "Variant A registry identity cannot reuse at equal revision")
	a_registry_same_revision.revision = 8
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(21, 10), -1.0, a_registry_same_revision, "alpha", "bravo", compute, "contact_tracking")
	_assert(_terrain_calls == 6, "Variant A terrain revision change cannot reuse")
	cache.call("begin_tick", 41)
	_assert(Dictionary(cache.get("_shared_tick_results")).is_empty(), "Variant A result store clears at tick boundary")
	cache.call("has_line_of_sight_between_points", Vector2(11, 10), Vector2(21, 10), -1.0, a_registry_same_revision, "alpha", "bravo", compute, "contact_tracking")
	_assert(_terrain_calls == 7, "Variant A tick change cannot reuse")
	var a_diag: Dictionary = cache.call("get_task1206_analysis_snapshot")
	var a_dump: Dictionary = cache.call("get_task1206_analysis_snapshot", true)
	_assert(int(a_diag.get("result_materialization_count", 0)) == 7 and int(a_diag.get("shared_result_reuse_count", 0)) == 1, "Variant A counts exact materializations and reuse")
	_assert(int(a_diag.get("result_materialization_usec", -1)) >= 0, "Variant A exposes non-negative materialization cost")
	_assert(not a_diag.has("shared_tick_results") and not a_diag.has("result") and not a_dump.has("shared_tick_results") and not a_dump.has("result"), "Variant A result is absent from diagnostic snapshots")
	# Keep the historical topology assertions on their unchanged P02 contract.
	driver.call("set_task1206_analysis_configuration", "off", false, true)
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
	if not _task1206_paired_runner_contract_is_present():
		print("TASK1206_PAIRED_RUNNER_CONTRACT_MISSING")
		driver.free()
		quit(1)
		return
	print("TASK1206_PAIRED_RUNNER_CONTRACT_OK")

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

func _run_variant_a_evidence() -> void:
	var sha := OS.get_environment("STERNENBUERGERCHEN_GIT_SHA")
	if sha.is_empty():
		push_error("STERNENBUERGERCHEN_GIT_SHA is required")
		quit(1)
		return
	var harness_script: GDScript = preload("res://scripts/tests/simulation_combat_ai_tick_budget_harness.gd")
	seed(1206)
	var control: Dictionary = await _run_topology_fixture(harness_script, false)
	seed(1206)
	var topology: Dictionary = await _run_topology_fixture(harness_script, true)
	seed(1206)
	var variant: Dictionary = await _run_topology_fixture(harness_script, false, "shared_tick_result_contract", true)
	if not bool(control.get("ok", false)) or not bool(topology.get("ok", false)) or not bool(variant.get("ok", false)):
		push_error("TASK1206 Variant A fixture failed")
		quit(1)
		return
	var control_oracle := String(control.get("oracle_hash", ""))
	var topology_oracle := String(topology.get("oracle_hash", ""))
	var variant_oracle := String(variant.get("oracle_hash", ""))
	if control_oracle != topology_oracle or control_oracle != variant_oracle:
		push_error("TASK1206 Variant A oracle mismatch")
		quit(1)
		return
	var topology_snapshot: Dictionary = topology.get("topology", {})
	var variant_snapshot: Dictionary = variant.get("topology", {})
	if (
		String(variant_snapshot.get("variant", "")) != "shared_tick_result_contract"
		or not bool(variant_snapshot.get("enabled", false))
		or bool(variant_snapshot.get("topology_enabled", true))
		or variant_snapshot.has("shared_tick_results")
		or variant_snapshot.has("result")
	):
		push_error("TASK1206 Variant A snapshot contract mismatch")
		quit(1)
		return
	var topology_costs: Dictionary = topology_snapshot.get("costs", {})
	var signature_cost: Dictionary = topology_costs.get("signature_key_build", {})
	var terrain_cost: Dictionary = topology_costs.get("terrain_los", {})
	var signature_count := int(signature_cost.get("count", 0))
	var terrain_count := int(terrain_cost.get("count", 0))
	var terrain_usec := int(terrain_cost.get("usec", 0))
	var reuse_count := int(variant_snapshot.get("shared_result_reuse_count", 0))
	var estimated_saved_terrain_usec := 0
	if terrain_count > 0:
		estimated_saved_terrain_usec = roundi(float(terrain_usec) * float(reuse_count) / float(terrain_count))
	var saved_signature_key_usec := int(signature_cost.get("usec", 0))
	var result_materialization_usec := int(variant_snapshot.get("result_materialization_usec", 0))
	var cost_gate_rhs_usec := saved_signature_key_usec + estimated_saved_terrain_usec
	var evidence := {
		"schema": "sternenbuergerchen.task1206.variant_a_cost.v1",
		"git_sha": sha,
		"ticks": 600,
		"variant": "shared_tick_result_contract",
		"control_gameplay_oracle_sha256": control_oracle,
		"topology_gameplay_oracle_sha256": topology_oracle,
		"variant_gameplay_oracle_sha256": variant_oracle,
		"oracle_match": true,
		"topology": topology_snapshot,
		"variant_snapshot": variant_snapshot,
		"baseline_signature_key_count": signature_count,
		"baseline_terrain_los_count": terrain_count,
		"saved_terrain_los_call_count": maxi(0, signature_count - terrain_count),
		"saved_signature_key_usec": saved_signature_key_usec,
		"estimated_saved_terrain_los_usec": estimated_saved_terrain_usec,
		"result_materialization_usec": result_materialization_usec,
		"cost_gate_rhs_usec": cost_gate_rhs_usec,
		"cost_gate_pass": result_materialization_usec < cost_gate_rhs_usec,
	}
	print("TASK1206_VARIANT_A_JSON=" + JSON.stringify(evidence))
	quit(0)

func _run_topology_fixture(harness_script: GDScript, topology_enabled: bool, variant: String = "off", variant_enabled: bool = false) -> Dictionary:
	var harness = harness_script.new()
	var context: Dictionary = harness.call("_make_combat_context", root, "task1206_topology", 16, 12, 4, true)
	await process_frame
	var driver: Node = context.get("combat_driver")
	var simulation_root: Node = context.get("simulation_root")
	var scene: Node = context.get("scene")
	if driver == null or simulation_root == null or scene == null:
		return {"ok": false, "oracle_hash": ""}
	driver.call("set_task1206_analysis_configuration", variant, variant_enabled, topology_enabled)
	simulation_root.call("set_unit_minimum_spacing_enabled", false)
	harness.call("_prime_state", context, true)
	for _tick in range(600):
		simulation_root.call("_physics_process", 0.1)
	var canonical := JSON.stringify({"contacts": driver.call("get_contact_snapshot"), "detection": driver.get("_detection_progress"), "fire_events": driver.call("get_fire_event_snapshot"), "enemy_security": driver.call("get_enemy_security_snapshot"), "enemy_tactics": driver.call("get_enemy_team_tactics_snapshot"), "mission_result": driver.call("get_mission_result")})
	var hash_ctx := HashingContext.new()
	hash_ctx.start(HashingContext.HASH_SHA256)
	hash_ctx.update(canonical.to_utf8_buffer())
	var result := {"ok": true, "oracle_hash": hash_ctx.finish().hex_encode()}
	if topology_enabled or variant_enabled:
		result["topology"] = Dictionary(driver.call("get_task1206_visibility_analysis_snapshot", true))
	scene.free()
	return result
