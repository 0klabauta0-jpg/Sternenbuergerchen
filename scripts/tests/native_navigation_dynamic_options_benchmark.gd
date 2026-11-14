extends SceneTree
## A successive-command counterexample to amortizing one fixed-cost snapshot.
## Does not modify the frozen static-option benchmark or product scripts.
const FIX = preload("res://scripts/tests/native_navigation_prototype_fixtures.gd")
const PATH = preload("res://scripts/terrain/terrain_pathfinder.gd")
const HPA = preload("res://scripts/terrain/hpa_pathfinder.gd")
const NATIVE = preload("res://scripts/terrain/native_navigation_prototype.gd")
var rows: Array = []
var failures: Array = []
var summaries: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ClassDB.class_exists("NativeNavigationKernel"):
		push_error("Dynamic benchmark refuses absent native extension")
		quit(1)
		return
	var samples: int = maxi(1, int(FIX.argument("--samples", "8")))
	var selected: PackedStringArray = FIX.argument("--fixtures", "hex24,gm01").split(",")
	for name in selected:
		var registry
		match name:
			"hex24": registry = FIX.synthetic("hex_axial_v1", 24, 24, Vector2i(-4, -3), true)
			"gm01": registry = FIX.real_map()
			_: failures.append("Unknown fixture " + name); continue
		print("DYNAMIC_OPTIONS_BEGIN ", name)
		_run_fixture(name, registry, samples)
		registry.free()
		print("DYNAMIC_OPTIONS_END ", name)
	var evidence := {
		"schema": "native_navigation_dynamic_options.v1", "unit": "usec",
		"context": {"engine": Engine.get_version_info(), "os": OS.get_name(), "cpu": OS.get_processor_name(),
			"processor_count": OS.get_processor_count(), "renderer": "headless", "gpu_time": "unavailable",
			"samples_per_fixture": samples, "small_sample_warning": samples < 20, "seed": 0,
			"ordering": "GDS first on even samples, native first on odd samples",
			"timed_boundary": "public HPA call including full option-dependent snapshot preparation, native transfer, query and return conversion",
			"cost_profile": "Derived balanced Move with default cover_priority0.4, no hazard cells; runtime-style changing corridor endpoints and lane offsets",
			"profile_sources": ["scripts/tactical/fireteam_movement_controller.gd:_resolve_stage_navigation_weights", "scripts/core/simulation_root.gd:_append_navigation_corridor_options"],
			"scope": "Successive navigation queries on same registry, graph and solver. No actor replay, FPS, GPU or release claim. Graph construction reported separately and excluded equally from request timings."},
		"rows": rows, "summaries": summaries, "failures": failures, "passed": failures.is_empty(), "pair_count": rows.size(),
	}
	var output: String = FIX.argument("--output", "user://native_navigation_dynamic_options.json")
	if not FIX.write_json(output, evidence): failures.append("Evidence write failed")
	print("NATIVE_NAVIGATION_DYNAMIC_OPTIONS pairs=", rows.size(), " failures=", failures.size(), " output=", output)
	quit(0 if failures.is_empty() else 1)

func _run_fixture(name: String, registry, samples: int) -> void:
	var graph_started: int = Time.get_ticks_usec()
	var graph = FIX.graph_for(registry)
	var graph_usec: int = Time.get_ticks_usec() - graph_started
	var baseline = HPA.new()
	var native = NATIVE.new()
	var pairs: Array = FIX.query_pairs(registry, samples)
	var gd_times: Array = []
	var cpp_times: Array = []
	var snapshot_times: Array = []
	var search_times: Array = []
	var registry_revision: int = registry.get_revision()
	var graph_revision: int = graph.get_revision()
	for sample in range(samples):
		var pair: Array = pairs[sample]
		var options: Dictionary = _command_options(pair, sample, registry)
		var options_bytes: PackedByteArray = var_to_bytes(options)
		var previous_builds: int = native.get_debug_snapshot().get("snapshot_build_count", 0)
		var arms: Dictionary = {}
		for backend in (["gdscript", "native"] if sample % 2 == 0 else ["native", "gdscript"]):
			var solver = native if backend == "native" else baseline
			var started: int = Time.get_ticks_usec()
			var value: Dictionary = solver.find_path_with_status(pair[0], pair[1], registry, graph, options)
			var elapsed: int = Time.get_ticks_usec() - started
			arms[backend] = {"value": value, "usec": elapsed,
				"debug": solver.get_debug_snapshot() if backend == "native" else solver.get_last_query_debug_snapshot()}
		var oracle = PATH.new()
		var gd_score: Dictionary = oracle.score_path(arms.gdscript.value.get("path", []), registry, options)
		var cpp_score: Dictionary = oracle.score_path(arms.native.value.get("path", []), registry, options)
		var exact: bool = arms.gdscript.value == arms.native.value and gd_score == cpp_score
		var used_native: bool = arms.native.debug.get("last_backend", "") == "native"
		var rebuilt: bool = arms.native.debug.get("snapshot_build_count", 0) == previous_builds + 1 and not arms.native.debug.get("snapshot_reused", true)
		var no_cache_hit: bool = not arms.native.debug.get("result_cache_hit", true) and not arms.gdscript.debug.get("result_cache_hit", true)
		var immutable_inputs: bool = options_bytes == var_to_bytes(options) and registry.get_revision() == registry_revision and graph.get_revision() == graph_revision
		if not exact or not used_native or not rebuilt or not no_cache_hit or not immutable_inputs:
			var message := "%s sample%d exact=%s native=%s rebuild=%s misses=%s inputs=%s" % [name, sample, exact, used_native, rebuilt, no_cache_hit, immutable_inputs]
			failures.append(message)
			push_error(message)
		gd_times.append(arms.gdscript.usec)
		cpp_times.append(arms.native.usec)
		snapshot_times.append(arms.native.debug.get("snapshot_prepare_usec", 0))
		search_times.append(arms.native.debug.get("native_query_usec", 0))
		rows.append({"fixture": name, "sample": sample, "from": [pair[0].x, pair[0].y], "to": [pair[1].x, pair[1].y],
			"gdscript_usec": arms.gdscript.usec, "native_usec": arms.native.usec,
			"ordered_path_status_score_equal": exact, "native_used": used_native, "new_option_snapshot_built": rebuilt,
			"both_result_cache_misses": no_cache_hit, "inputs_unchanged": immutable_inputs,
			"options": options, "options_variant_hex": options_bytes.hex_encode(),
			"status": arms.native.value.get("status", ""), "path_length": arms.native.value.get("path", []).size(),
			"score": cpp_score, "path_sha256": var_to_bytes(arms.native.value.get("path", [])).hex_encode().sha256_text(),
			"native_debug": arms.native.debug})
		print("DYNAMIC_OPTIONS_PAIR ", name, " ", sample, " gd_usec=", arms.gdscript.usec, " native_usec=", arms.native.usec, " parity=", exact)
	var gd: Dictionary = _stats(gd_times)
	var cpp: Dictionary = _stats(cpp_times)
	summaries[name] = {"graph_build_usec_excluded_from_both": graph_usec, "tile_count": registry.get_all_tiles().size(),
		"gdscript": gd, "native": cpp, "native_snapshot_prepare": _stats(snapshot_times), "native_query": _stats(search_times),
		"cumulative_speedup": gd.sum / maxf(cpp.sum, 1.0), "median_speedup": gd.median / maxf(cpp.median, 1.0),
		"small_sample_warning": samples < 20}

func _command_options(pair: Array, sample: int, registry) -> Dictionary:
	var origin_world: Vector2 = registry.grid_to_world(Vector2i.ZERO)
	var x_world: Vector2 = registry.grid_to_world(Vector2i.RIGHT)
	var y_world: Vector2 = registry.grid_to_world(Vector2i.DOWN)
	var projected_tile_distance: float = maxf((x_world - origin_world).length(), (y_world - origin_world).length())
	var cover_factor: float = 0.4
	return {"cover_aware_enabled": true, "exposure_weight": 0.62 + cover_factor * 0.25,
		"cover_weight": 0.42 + cover_factor * 0.35, "exposure_max_grid_distance": 8.0, "hazard_grids": [],
		"corridor_enabled": true, "corridor_from_grid": pair[0], "corridor_to_grid": pair[1],
		"corridor_weight": 0.62, "corridor_half_width_grid": 96.0 / projected_tile_distance,
		"lane_enabled": true, "lane_weight": 0.78 + 0.10, "lane_offset_grid": float(sample % 3 - 1) * 0.75,
		"blocker_clearance_weight": 0.32 + (1.0 - cover_factor) * 0.12, "blocker_clearance_radius": 1}

func _stats(values: Array) -> Dictionary:
	var sorted: Array = values.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value in sorted: total += value
	var count: int = sorted.size()
	return {"count": count, "sum": total, "mean": total / count,
		"median": float(sorted[int(count / 2)]) if count % 2 == 1 else (float(sorted[int(count / 2) - 1]) + float(sorted[int(count / 2)])) / 2.0,
		"p95": sorted[maxi(0, int(ceil(count * 0.95)) - 1)], "max": sorted[-1]}
