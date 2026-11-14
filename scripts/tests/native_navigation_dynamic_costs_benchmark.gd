extends SceneTree
## Same successive-command workload as the original dynamic-options benchmark.
## Includes cold setup once, then separately measures explicitly prepared calls.
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
		push_error("Dynamic-cost benchmark refuses absent native extension")
		quit(1)
		return
	var samples: int = maxi(2, int(FIX.argument("--samples", "8")))
	var selected: PackedStringArray = FIX.argument("--fixtures", "hex24,gm01").split(",")
	for name in selected:
		var registry
		match name:
			"hex24": registry = FIX.synthetic("hex_axial_v1", 24, 24, Vector2i(-4, -3), true)
			"gm01": registry = FIX.real_map()
			_: failures.append("Unknown fixture " + name); continue
		print("DYNAMIC_COSTS_BEGIN ", name)
		_run_fixture(name, registry, samples)
		registry.free()
		print("DYNAMIC_COSTS_END ", name)
	var evidence := {
		"schema": "native_navigation_dynamic_costs.v1", "unit": "usec",
		"context": {"engine": Engine.get_version_info(), "os": OS.get_name(), "cpu": OS.get_processor_name(),
			"processor_count": OS.get_processor_count(), "renderer": "headless", "gpu_time": "unavailable",
			"samples_per_fixture_per_phase": samples, "small_sample_warning": samples < 20, "seed": 0,
			"ordering": "GDS first on even samples, native first on odd samples",
			"timed_boundary": "Public HPA call including all per-request checks, query-cost setup, native search and return conversion. Successive phase includes cold snapshot preparation in sample0; prepared phase records setup separately and also reports amortized total.",
			"cost_profile": "Exactly the original dynamic_options workload: derived balanced Move cover_priority0.4, empty hazards, changing corridor endpoints and lane offsets",
			"comparison_reference": "docs/qa/native_navigation_20261114/dynamic_options/result.json",
			"profile_sources": ["scripts/tactical/fireteam_movement_controller.gd:_resolve_stage_navigation_weights", "scripts/core/simulation_root.gd:_append_navigation_corridor_options"],
			"scope": "Navigation subsystem only. Same registry, graph and solver within each phase. Existing HPA graph build is excluded from both arms and recorded separately. No actor replay, FPS, GPU or release claim."},
		"rows": rows, "summaries": summaries, "failures": failures, "passed": failures.is_empty(), "pair_count": rows.size(),
	}
	var output: String = FIX.argument("--output", "user://native_navigation_dynamic_costs.json")
	if not FIX.write_json(output, evidence): failures.append("Evidence write failed")
	print("NATIVE_NAVIGATION_DYNAMIC_COSTS pairs=", rows.size(), " failures=", failures.size(), " output=", output)
	quit(0 if failures.is_empty() else 1)

func _run_fixture(name: String, registry, samples: int) -> void:
	var graph_started: int = Time.get_ticks_usec()
	var graph = FIX.graph_for(registry)
	var graph_usec: int = Time.get_ticks_usec() - graph_started
	var pairs: Array = FIX.query_pairs(registry, samples)
	var registry_revision: int = registry.get_revision()
	var graph_revision: int = graph.get_revision()
	for phase in ["successive_commands", "prepared_commands"]:
		var baseline = HPA.new()
		var native = NATIVE.new()
		var preparation_usec: int = 0
		if phase == "prepared_commands":
			var preparation_started: int = Time.get_ticks_usec()
			var prepared: bool = native.prepare(registry, {}, graph)
			preparation_usec = Time.get_ticks_usec() - preparation_started
			if not prepared: failures.append(name + " native prewarm failed")
		var gd_times: Array = []
		var cpp_times: Array = []
		var setup_times: Array = []
		var search_times: Array = []
		for sample in range(samples):
			var pair: Array = pairs[sample]
			var options: Dictionary = _command_options(pair, sample, registry)
			var options_bytes: PackedByteArray = var_to_bytes(options)
			var previous_options: int = native.get_debug_snapshot().get("option_prepare_count", 0)
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
			var terrain_reused: bool = arms.native.debug.get("snapshot_build_count", 0) == 1
			var graph_reused: bool = arms.native.debug.get("graph_build_count", 0) == 1
			var fresh_query: bool = arms.native.debug.get("option_prepare_count", -1) == previous_options + 1
			var no_cache_hit: bool = not arms.native.debug.get("result_cache_hit", true) and not arms.gdscript.debug.get("result_cache_hit", true)
			var immutable_inputs: bool = options_bytes == var_to_bytes(options) and registry.get_revision() == registry_revision and graph.get_revision() == graph_revision
			var nonempty: bool = not Array(arms.native.value.get("path", [])).is_empty()
			if not exact or not used_native or not terrain_reused or not graph_reused or not fresh_query or not no_cache_hit or not immutable_inputs or not nonempty:
				var message := "%s/%s sample%d exact=%s native=%s terrain=%s graph=%s query=%s misses=%s inputs=%s nonempty=%s" % [name, phase, sample, exact, used_native, terrain_reused, graph_reused, fresh_query, no_cache_hit, immutable_inputs, nonempty]
				failures.append(message)
				push_error(message)
			gd_times.append(arms.gdscript.usec)
			cpp_times.append(arms.native.usec)
			setup_times.append(arms.native.debug.get("snapshot_prepare_usec", 0))
			search_times.append(arms.native.debug.get("native_query_usec", 0))
			rows.append({"fixture": name, "phase": phase, "sample": sample, "cold_first_call": phase == "successive_commands" and sample == 0,
				"from": [pair[0].x, pair[0].y], "to": [pair[1].x, pair[1].y],
				"gdscript_usec": arms.gdscript.usec, "native_usec": arms.native.usec,
				"ordered_path_status_score_equal": exact, "native_used": used_native, "one_terrain_snapshot": terrain_reused,
				"one_hpa_snapshot": graph_reused, "new_query_context": fresh_query,
				"both_result_cache_misses": no_cache_hit, "inputs_unchanged": immutable_inputs,
				"options": options, "options_variant_hex": options_bytes.hex_encode(),
				"status": arms.native.value.get("status", ""), "path_length": arms.native.value.get("path", []).size(),
				"score": cpp_score, "path_sha256": var_to_bytes(arms.native.value.get("path", [])).hex_encode().sha256_text(),
				"native_debug": arms.native.debug})
			print("DYNAMIC_COSTS_PAIR ", name, " ", phase, " ", sample, " gd_usec=", arms.gdscript.usec, " native_usec=", arms.native.usec, " parity=", exact)
		var gd: Dictionary = _stats(gd_times)
		var cpp: Dictionary = _stats(cpp_times)
		var phase_summary := {"graph_build_usec_excluded_from_both": graph_usec, "tile_count": registry.get_all_tiles().size(),
			"native_preparation_usec_excluded_from_queries": preparation_usec,
			"gdscript": gd, "native": cpp, "native_request_setup": _stats(setup_times), "native_query": _stats(search_times),
			"native_total_including_preparation_usec": cpp.sum + preparation_usec,
			"cumulative_speedup_including_preparation": gd.sum / maxf(cpp.sum + preparation_usec, 1.0),
			"median_query_speedup": gd.median / maxf(cpp.median, 1.0), "small_sample_warning": samples < 20}
		if phase == "successive_commands":
			phase_summary["first_cold_request"] = {"gdscript_usec": gd_times[0], "native_usec": cpp_times[0]}
			phase_summary["following_requests"] = {"gdscript": _stats(gd_times.slice(1)), "native": _stats(cpp_times.slice(1))}
		summaries[name + "/" + phase] = phase_summary

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
