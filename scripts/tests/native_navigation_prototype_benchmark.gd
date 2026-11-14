extends SceneTree
## Paired, balanced subsystem timings. Validation is outside each timed call.
const FIX = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")
const NATIVE = preload("res://scripts/terrain/native_navigation_prototype.gd")
var rows: Array = []
var preparation: Array = []
var failures: Array = []
var warm_count := 24
var cold_count := 3

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ClassDB.class_exists("NativeNavigationKernel"):
		push_error("Native extension missing; benchmark refuses fallback-only timing")
		quit(1)
		return
	warm_count = maxi(1, int(FIX.argument("--samples", "24")))
	cold_count = maxi(1, int(FIX.argument("--cold-samples", "3")))
	var selected: PackedStringArray = FIX.argument("--fixtures", "square24,hex24,gm01").split(",")
	for name in selected:
		var registry
		match name:
			"square24": registry = FIX.synthetic("square8", 24, 24, Vector2i(-4, -3), true)
			"hex24": registry = FIX.synthetic("hex_axial_v1", 24, 24, Vector2i(-4, -3), true)
			"gm01": registry = FIX.real_map()
			_: failures.append("Unknown fixture " + name); continue
		print("BENCH_FIXTURE_BEGIN ", name, " cells=", registry.get_all_tiles().size())
		_benchmark_fixture(name, registry)
		registry.free()
		print("BENCH_FIXTURE_END ", name)
	var result := {
		"schema": "native_navigation_paired_benchmark.v1", "unit": "usec",
		"context": {"engine": Engine.get_version_info(), "os": OS.get_name(), "cpu": OS.get_processor_name(),
			"processor_count": OS.get_processor_count(), "renderer": "headless", "gpu_time": "unavailable",
			"seed": 0, "pair_selection": "deterministic sorted walkable indices; formulas in fixtures",
			"warm_samples_per_algorithm": warm_count, "cold_samples_per_algorithm": cold_count,
			"timed_boundary": "public call including data materialization, native transfer and path conversion; cold HPA also fresh graph build",
			"ordering": "GDS first on even samples; native first on odd samples", "quality_changes": false,
			"scope": "Navigation subsystem only. Cold means fresh solver/snapshot/graph in an already running process; excludes process startup/import/map JSON parse. No FPS/GPU or release claim."},
		"preparation": preparation, "pairs": rows, "failures": failures,
		"pair_count": rows.size(), "passed": failures.is_empty(),
		"summaries": _summaries(),
	}
	var output := FIX.argument("--output", "user://native_navigation_benchmark.json")
	if not FIX.write_json(output, result): failures.append("Evidence write failed")
	print("NATIVE_NAVIGATION_BENCHMARK pairs=", rows.size(), " failures=", failures.size(), " output=", output)
	quit(0 if failures.is_empty() else 1)

func _benchmark_fixture(name: String, registry) -> void:
	var pairs: Array = FIX.query_pairs(registry, maxi(warm_count, cold_count) + 1)
	for algorithm in ["astar", "hpa"]:
		for sample in range(cold_count):
			var arms: Dictionary = {}
			for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
				var solver = NATIVE.new() if backend == "native" else (HPA.new() if algorithm == "hpa" else PATH.new())
				var started: int = Time.get_ticks_usec()
				var graph = FIX.graph_for(registry) if algorithm == "hpa" else null
				var graph_usec: int = Time.get_ticks_usec() - started
				var value: Variant = _call(solver, algorithm, pairs[sample], registry, graph)
				var elapsed: int = Time.get_ticks_usec() - started
				arms[backend] = {"value": value, "usec": elapsed, "graph_build_usec": graph_usec,
					"debug": solver.get_debug_snapshot() if backend == "native" else {}}
			_record(name, algorithm, "cold_end_to_end", sample, pairs[sample], arms, registry)
		# One revision/options snapshot reused across distinct requests. Graph
		# creation and native preparation are reported separately, never hidden.
		var graph_started: int = Time.get_ticks_usec()
		var graph = FIX.graph_for(registry) if algorithm == "hpa" else null
		var graph_usec: int = Time.get_ticks_usec() - graph_started
		var baseline = HPA.new() if algorithm == "hpa" else PATH.new()
		var native = NATIVE.new()
		var prepare_started: int = Time.get_ticks_usec()
		var prepared: bool = native.prepare(registry, {}, graph)
		var prepare_usec: int = Time.get_ticks_usec() - prepare_started
		preparation.append({"fixture": name, "algorithm": algorithm, "shared_graph_build_usec": graph_usec,
			"native_snapshot_and_transfer_usec": prepare_usec, "prepared": prepared, "debug": native.get_debug_snapshot()})
		if not prepared: failures.append(name + " " + algorithm + " preparation failed")
		# Untimed one-call warmup for both arms, not included in sample array.
		_call(baseline, algorithm, pairs[-1], registry, graph)
		_call(native, algorithm, pairs[-1], registry, graph)
		for sample in range(warm_count):
			if algorithm == "hpa":
				baseline.get("_result_cache").clear()
				baseline.get("_result_cache_fifo").clear()
				native.clear_result_cache()
			var arms: Dictionary = {}
			for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
				var solver = native if backend == "native" else baseline
				var started: int = Time.get_ticks_usec()
				var value: Variant = _call(solver, algorithm, pairs[sample], registry, graph)
				arms[backend] = {"value": value, "usec": Time.get_ticks_usec() - started,
					"debug": solver.get_debug_snapshot() if backend == "native" else {}}
			_record(name, algorithm, "warm_new_query", sample, pairs[sample], arms, registry)
		if algorithm == "hpa":
			# Pick a successful route so both implementations actually hit a cache.
			var cache_pair: Array = []
			for pair in pairs:
				var value: Dictionary = _call(baseline, algorithm, pair, registry, graph)
				if value.get("status", "") in ["hpa", "same_component"] and not value.get("path", []).is_empty():
					cache_pair = pair
					break
			if cache_pair.is_empty():
				failures.append(name + " has no successful HPA cache fixture")
			else:
				_call(baseline, algorithm, cache_pair, registry, graph)
				_call(native, algorithm, cache_pair, registry, graph)
				for sample in range(warm_count):
					var arms: Dictionary = {}
					for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
						var solver = native if backend == "native" else baseline
						var started: int = Time.get_ticks_usec()
						var value: Variant = _call(solver, algorithm, cache_pair, registry, graph)
						arms[backend] = {"value": value, "usec": Time.get_ticks_usec() - started,
							"debug": solver.get_debug_snapshot() if backend == "native" else baseline.get_last_query_debug_snapshot()}
					_record(name, algorithm, "result_cache_hit", sample, cache_pair, arms, registry)
			# Effective terrain change invalidates snapshots and result caches;
			# graph rebuild time is included equally in both arms.
			for sample in range(cold_count):
				registry.set_runtime_tile_overrides([{"grid_position": pairs[sample][1], "cover_value_override": 20 + sample}])
				var arms: Dictionary = {}
				for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
					var solver = native if backend == "native" else baseline
					var started: int = Time.get_ticks_usec()
					var changed_graph = FIX.graph_for(registry)
					var value: Variant = _call(solver, algorithm, pairs[sample], registry, changed_graph)
					arms[backend] = {"value": value, "usec": Time.get_ticks_usec() - started,
						"debug": solver.get_debug_snapshot() if backend == "native" else {}}
				_record(name, algorithm, "revision_rebuild", sample, pairs[sample], arms, registry)
			registry.clear_runtime_tile_overrides()

func _call(solver, algorithm: String, pair: Array, registry, graph) -> Variant:
	if algorithm == "hpa": return solver.find_path_with_status(pair[0], pair[1], registry, graph, {})
	return solver.find_path_with_options(pair[0], pair[1], registry, {})

func _record(name: String, algorithm: String, mode: String, sample: int, pair: Array, arms: Dictionary, registry) -> void:
	var expected: Variant = arms.gdscript.value
	var actual: Variant = arms.native.value
	var equal: bool = expected == actual
	var expected_path: Array = expected.get("path", []) if algorithm == "hpa" else expected
	var actual_path: Array = actual.get("path", []) if algorithm == "hpa" else actual
	var score_equal: bool = PATH.new().score_path(expected_path, registry) == PATH.new().score_path(actual_path, registry)
	var native_used: bool = arms.native.debug.get("last_backend", "") == "native"
	var caches_correct: bool = mode != "result_cache_hit" or (arms.native.debug.get("result_cache_hit", false) and arms.gdscript.debug.get("result_cache_hit", false))
	if not equal or not score_equal or not native_used or not caches_correct:
		var failure := "%s %s %s sample%d parity=%s score=%s native=%s cache=%s" % [name, algorithm, mode, sample, equal, score_equal, native_used, caches_correct]
		failures.append(failure)
		push_error(failure)
	rows.append({"fixture": name, "algorithm": algorithm, "mode": mode, "sample": sample,
		"from": [pair[0].x, pair[0].y], "to": [pair[1].x, pair[1].y],
		"gdscript_usec": arms.gdscript.usec, "native_usec": arms.native.usec,
		"ordered_path_and_status_equal": equal, "score_equal": score_equal, "native_used": native_used,
		"path_length": actual_path.size(), "status": actual.get("status", "") if algorithm == "hpa" else "astar",
		"path_sha256": var_to_bytes(actual_path).hex_encode().sha256_text(),
		"native_debug": arms.native.debug, "both_result_caches_hit": caches_correct if mode == "result_cache_hit" else false,
		"gdscript_graph_build_usec": arms.gdscript.get("graph_build_usec", 0), "native_graph_build_usec": arms.native.get("graph_build_usec", 0)})

func _summaries() -> Dictionary:
	var groups: Dictionary = {}
	for row in rows:
		var key: String = row.fixture + "/" + row.algorithm + "/" + row.mode
		if not groups.has(key): groups[key] = {"gdscript": [], "native": []}
		groups[key].gdscript.append(row.gdscript_usec)
		groups[key].native.append(row.native_usec)
	var output: Dictionary = {}
	for key in groups:
		var gd: Dictionary = _stats(groups[key].gdscript)
		var cpp: Dictionary = _stats(groups[key].native)
		output[key] = {"gdscript": gd, "native": cpp, "median_speedup": gd.median / maxf(cpp.median, 1.0),
			"small_sample_warning": gd.count < 20}
	return output

func _stats(values: Array) -> Dictionary:
	var sorted: Array = values.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value in sorted: total += value
	var count: int = sorted.size()
	return {"count": count, "mean": total / count, "median": float(sorted[int(count / 2)]) if count % 2 == 1 else (float(sorted[int(count / 2) - 1]) + float(sorted[int(count / 2)])) / 2.0,
		"p95": sorted[maxi(0, int(ceil(count * 0.95)) - 1)], "max": sorted[-1], "sum": total}
