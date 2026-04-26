extends SceneTree

const NAVIGATION_BENCHMARK_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/navigation_benchmark_harness.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_131 Navigation Benchmark Harness Verifier ===")
	var harness = NAVIGATION_BENCHMARK_HARNESS_SCRIPT.new()
	var result: Dictionary = Dictionary(harness.call("run_all", root))
	_test_summary(result)
	_test_query_scenarios(result)
	_test_cover_metrics(result)
	_test_budget_metrics(result)
	_test_avoidance_metrics(result)
	print("Benchmark summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
	else:
		print("ALL TESTS PASSED")
	quit()


func _test_summary(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(int(summary.get("scenario_count", 0)) >= 3, "Benchmark produces at least three reproducible scenarios")
	_assert(bool(summary.get("has_query_metrics", false)), "Benchmark summary marks query metrics as present")
	_assert(bool(summary.get("has_cover_metrics", false)), "Benchmark summary marks cover metrics as present")
	_assert(bool(summary.get("has_delay_metrics", false)), "Benchmark summary marks delay metrics as present")
	_assert(bool(summary.get("has_avoidance_metrics", false)), "Benchmark summary marks avoidance metrics as present")


func _test_query_scenarios(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var open_field: Dictionary = Dictionary(scenarios.get("open_field_queries", {}))
	var corridor: Dictionary = Dictionary(scenarios.get("corridor_queries", {}))
	var open_hpa: Dictionary = Dictionary(open_field.get("hpa", {}))
	var open_astar: Dictionary = Dictionary(open_field.get("terrain_a_star", {}))
	var corridor_hpa: Dictionary = Dictionary(corridor.get("hpa", {}))
	_assert(int(open_astar.get("successful_queries", 0)) == int(open_astar.get("query_count", -1)), "Open-field A* benchmark resolves every query")
	_assert(int(open_hpa.get("successful_queries", 0)) == int(open_hpa.get("query_count", -1)), "Open-field HPA benchmark resolves every query")
	_assert(float(open_hpa.get("avg_query_time_usec", -1.0)) >= 0.0 and float(open_hpa.get("avg_path_length_grid", 0.0)) > 0.0, "Open-field HPA reports query time and path length")
	_assert(int(corridor_hpa.get("successful_queries", 0)) == int(corridor_hpa.get("query_count", -1)), "Corridor HPA benchmark resolves every bottleneck query")
	_assert(float(corridor_hpa.get("avg_path_length_grid", 0.0)) > float(open_hpa.get("avg_path_length_grid", 0.0)) * 0.5, "Corridor benchmark reports non-trivial path lengths")


func _test_cover_metrics(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var cover: Dictionary = Dictionary(scenarios.get("cover_exposure_queries", {}))
	var plain: Dictionary = Dictionary(cover.get("hpa_plain", {}))
	var cover_aware: Dictionary = Dictionary(cover.get("hpa_cover_aware", {}))
	_assert(int(cover_aware.get("successful_queries", 0)) == int(cover_aware.get("query_count", -1)), "Cover-aware HPA benchmark resolves every cover query")
	_assert(float(cover_aware.get("exposure_sum", 99.0)) < float(plain.get("exposure_sum", 0.0)), "Cover-aware HPA benchmark lowers exposure against plain HPA")
	_assert(float(cover_aware.get("cover_sum", 0.0)) > float(plain.get("cover_sum", 99.0)), "Cover-aware HPA benchmark increases cover use against plain HPA")


func _test_budget_metrics(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var budget: Dictionary = Dictionary(scenarios.get("budget_delays", {}))
	_assert(int(budget.get("new_path_queries_this_tick", 0)) == 1, "Benchmark captures configured navigation query budget")
	_assert(int(budget.get("delayed_this_tick", 0)) > 0, "Benchmark captures delayed commands")
	_assert(int(budget.get("pending_query_count", 0)) > 0, "Benchmark captures pending navigation requests")
	_assert(String(budget.get("last_delay_reason", "")) == "budget_exhausted", "Benchmark captures the delay reason")


func _test_avoidance_metrics(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	var avoidance: Dictionary = Dictionary(scenarios.get("avoidance_execution", {}))
	var plain: Dictionary = Dictionary(avoidance.get("plain", {}))
	var resolved: Dictionary = Dictionary(avoidance.get("avoidance", {}))
	_assert(float(resolved.get("final_distance", 0.0)) > float(plain.get("final_distance", 0.0)) + 0.5, "Benchmark shows local avoidance keeps crossing units farther apart")
	_assert(int(avoidance.get("neighbor_count", 0)) > 0, "Benchmark captures local avoidance neighbor count")
	_assert(float(avoidance.get("stuck_time_seconds", 0.0)) >= 0.5, "Benchmark captures stuck time from deadlock probe")
	_assert(bool(avoidance.get("deadlock_marked", false)), "Benchmark captures deadlock marking")


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
