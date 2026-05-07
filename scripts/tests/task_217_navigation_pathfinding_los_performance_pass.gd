extends SceneTree

const NAVIGATION_BENCHMARK_HARNESS_SCRIPT: GDScript = preload("res://scripts/tests/navigation_benchmark_harness.gd")
const REPORT_PATH: String = "res://docs/performance/navigation_pathfinding_los_profile_report.md"
const MAX_BROAD_QUERY_P99_USEC: float = 1000000.0

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_217 Navigation Pathfinding LOS Performance Pass ===")
	var harness = NAVIGATION_BENCHMARK_HARNESS_SCRIPT.new()
	var result: Dictionary = Dictionary(harness.call("run_all", root))
	_test_summary(result)
	_test_profile_query_scenarios(result)
	_test_los_cover_diagnostics(result)
	_test_query_flood_staggering(result)
	_test_report_exists()
	print("TASK_217 benchmark summary: %s" % JSON.stringify(result.get("summary", {})))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed > 0:
		print("FAIL")
		quit(1)
	else:
		print("ALL TESTS PASSED")
		quit(0)


func _test_summary(result: Dictionary) -> void:
	var summary: Dictionary = Dictionary(result.get("summary", {}))
	_assert(int(summary.get("scenario_count", 0)) >= 9, "Benchmark includes legacy and TASK_217 scenarios")
	_assert(bool(summary.get("has_large_map_metrics", false)), "Summary marks 64x64 metrics as present")
	_assert(bool(summary.get("has_hill_metrics", false)), "Summary marks hill metrics as present")
	_assert(bool(summary.get("has_query_percentiles", false)), "Summary marks query Median/P95/P99 as present")
	_assert(bool(summary.get("has_los_cover_diagnostics", false)), "Summary marks LOS/Cover diagnostics as present")
	_assert(bool(summary.get("has_cache_diagnostics", false)), "Summary marks cache diagnostics as present")
	_assert(bool(summary.get("has_query_flood_staggering", false)), "Summary marks query-flood staggering as present")


func _test_profile_query_scenarios(result: Dictionary) -> void:
	var scenarios: Dictionary = Dictionary(result.get("scenarios", {}))
	for scenario_id in ["open_32x32_queries", "hill_cover_32x32_queries", "open_64x64_queries", "chokepoint_cover_64x64_queries"]:
		_assert(scenarios.has(scenario_id), "%s scenario exists" % scenario_id)
		var scenario: Dictionary = Dictionary(scenarios.get(scenario_id, {}))
		var hpa: Dictionary = Dictionary(scenario.get("hpa", {}))
		var terrain_a_star: Dictionary = Dictionary(scenario.get("terrain_a_star", {}))
		_assert(_variant_resolves_every_query(hpa), "%s HPA resolves every query" % scenario_id)
		_assert(_variant_resolves_every_query(terrain_a_star), "%s terrain A* resolves every query" % scenario_id)
		_assert(_variant_has_percentiles(hpa), "%s HPA exposes query percentiles" % scenario_id)
		_assert(_variant_has_percentiles(terrain_a_star), "%s terrain A* exposes query percentiles" % scenario_id)
		_assert(_variant_has_cache_diagnostics(hpa), "%s HPA exposes cache diagnostics" % scenario_id)
		_assert(float(Dictionary(hpa.get("query_time_usec", {})).get("p99", MAX_BROAD_QUERY_P99_USEC + 1.0)) < MAX_BROAD_QUERY_P99_USEC, "%s HPA p99 stays under broad local budget" % scenario_id)
	var hill_hpa: Dictionary = Dictionary(Dictionary(scenarios.get("hill_cover_32x32_queries", {})).get("hpa", {}))
	var chokepoint_hpa: Dictionary = Dictionary(Dictionary(scenarios.get("chokepoint_cover_64x64_queries", {})).get("hpa", {}))
	_assert(int(hill_hpa.get("los_check_count", 0)) > 0, "Hill/Cover HPA counts LOS checks")
	_assert(int(hill_hpa.get("cover_check_count", 0)) > 0, "Hill/Cover HPA counts cover checks")
	_assert(int(chokepoint_hpa.get("los_check_count", 0)) > 0, "Chokepoint HPA counts LOS checks")
	_assert(int(chokepoint_hpa.get("cover_check_count", 0)) > 0, "Chokepoint HPA counts cover checks")


func _test_los_cover_diagnostics(result: Dictionary) -> void:
	var probe: Dictionary = Dictionary(Dictionary(result.get("scenarios", {})).get("los_cover_probe", {}))
	_assert(int(probe.get("sample_count", 0)) > 0, "LOS/Cover probe samples grid positions")
	_assert(int(probe.get("los_check_count", 0)) > 0, "LOS/Cover probe counts LOS checks")
	_assert(int(probe.get("cover_check_count", 0)) > 0, "LOS/Cover probe counts cover checks")
	_assert(float(probe.get("avg_usec", -1.0)) >= 0.0, "LOS/Cover probe reports average timing")


func _test_query_flood_staggering(result: Dictionary) -> void:
	var flood: Dictionary = Dictionary(Dictionary(result.get("scenarios", {})).get("query_flood_staggering", {}))
	_assert(int(flood.get("command_count", 0)) >= 8, "Query-flood probe submits multiple movement commands")
	_assert(int(flood.get("new_path_queries_this_tick", 99)) <= int(flood.get("budget_limit", 0)), "Query-flood probe respects per-tick path budget")
	_assert(int(flood.get("delayed_this_tick", 0)) > 0, "Query-flood probe delays excess path queries")
	_assert(int(flood.get("pending_query_count", 0)) > 0, "Query-flood probe keeps pending path queries visible")


func _test_report_exists() -> void:
	var report: String = _read_text(REPORT_PATH)
	_assert(not report.is_empty(), "Navigation pathfinding LOS profile report exists")
	_assert(report.contains("TASK_217") and report.contains("32x32") and report.contains("64x64"), "Report documents TASK_217 32x32/64x64 matrix")
	_assert(report.contains("Median") and report.contains("P95") and report.contains("P99"), "Report documents query percentile fields")
	_assert(report.contains("LOS") and report.contains("Cover") and report.contains("Cache") and report.contains("Avoidance"), "Report documents LOS/Cover/Cache/Avoidance diagnostics")


func _variant_resolves_every_query(variant: Dictionary) -> bool:
	var query_count: int = int(variant.get("query_count", -1))
	return query_count > 0 and int(variant.get("successful_queries", -2)) == query_count


func _variant_has_percentiles(variant: Dictionary) -> bool:
	var stats: Dictionary = Dictionary(variant.get("query_time_usec", {}))
	return int(stats.get("count", 0)) == int(variant.get("query_count", -1)) \
		and float(stats.get("median", -1.0)) >= 0.0 \
		and float(stats.get("p95", -1.0)) >= float(stats.get("median", 0.0)) \
		and float(stats.get("p99", -1.0)) >= float(stats.get("median", 0.0))


func _variant_has_cache_diagnostics(variant: Dictionary) -> bool:
	var cache: Dictionary = Dictionary(variant.get("cache_diagnostics", {}))
	return cache.has("path_cache_supported") \
		and int(cache.get("miss_count", -1)) == int(variant.get("query_count", -2)) \
		and int(cache.get("hit_count", -1)) >= 0 \
		and int(cache.get("invalidation_count", -1)) >= 0


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text: String = file.get_as_text()
	file.close()
	return text


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
