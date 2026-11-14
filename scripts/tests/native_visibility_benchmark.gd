extends SceneTree
## Current cached combat reader and actual FoW jobs. No cache-disabled baseline.
const FIX = preload("res://scripts/tests/native_visibility_fixtures.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
const FOW = preload("res://scripts/core/fog_of_war_system.gd")
var failures: Array = []
var rows: Array = []
var samples: int = 10
var backends: Array = ["gdscript"]

func _init() -> void: call_deferred("_run")

func _run() -> void:
	samples = maxi(int(FIX.argument("--samples", "10")), 1)
	if FIX.argument("--backend", "gdscript") == "paired":
		if not ClassDB.class_exists("NativeVisibilityKernel"):
			failures.append("Paired benchmark requires NativeVisibilityKernel")
		else: backends = ["gdscript", "native"]
	var load_started: int = Time.get_ticks_usec()
	var registry: Node = FIX.gm01()
	var load_usec: int = Time.get_ticks_usec() - load_started
	root.add_child(registry)
	var query_pairs: Array = FIX.pairs(registry, 64)
	var reference: Dictionary = {}
	for sample in range(samples + 3):
		var order: Array = backends.duplicate()
		if sample % 2: order.reverse()
		for backend: String in order:
			var line: Dictionary = _line(registry, query_pairs, backend == "native")
			var combat: Dictionary = _combat(registry, query_pairs, backend == "native", sample)
			var fow: Dictionary = _fow(registry, query_pairs, backend == "native")
			# Results are independently canonicalized outside each timing scope.
			var outputs := {"line": line.get("signature"), "combat": combat.get("signature"), "full_fow": fow.get("full_signature"), "dirty_fow": fow.get("dirty_signature")}
			if reference.is_empty(): reference = outputs
			elif outputs != reference: failures.append("Behavior changed: sample %d backend %s" % [sample, backend])
			if backend == "native" and (int(combat.audit.get("native_calls", 0)) == 0 or int(fow.audit.get("native_calls", 0)) == 0):
				failures.append("Native benchmark fell back without real native work")
			if sample >= 3: rows.append({"sample": sample - 3, "backend": backend, "line": line, "combat": combat, "fow": fow})
	var result := {"schema": "native_visibility_paths.v1", "passed": failures.is_empty(), "failures": failures, "rows": rows,
		"context": {"engine": Engine.get_version_info(), "cpu": OS.get_processor_name(), "os": OS.get_name(), "renderer": "headless",
			"gpu_timing": "unavailable", "map": "Ground_Mission01_32x32.json", "tiles": registry.call("get_tile_count"),
			"fixture_load_usec": load_usec, "samples_per_backend": samples, "warmup": 3,
			"combat": "64 distinct ordered pairs, four reads each, begin_tick each sample; current cache remains enabled; 360-degree unbounded profile for terrain admission",
			"fow": "Four observers; current full then dirty-movement owner jobs, 256-tile slices, physical sight range 8 cells, complete request+slice CPU times; source registry unchanged",
			"line": "Diagnostic share only: canonical line construction for same 64 pairs; not added to combat/FoW timings",
			"scope": "End-to-end synchronous CPU calls including native boundary and result transfer; no FPS, render, network or full-combat simulation claim"}}
	if not FIX.write_json(FIX.argument("--output", "user://native_visibility_benchmark.json"), result): failures.append("Evidence write failed")
	registry.free()
	print("NATIVE_VISIBILITY_BENCHMARK rows=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _line(registry: Node, query_pairs: Array, native_enabled: bool) -> Dictionary:
	var reader = FIX.los(native_enabled)
	var lines: Array = []
	var buffer: Array[Vector2i] = []
	var started: int = Time.get_ticks_usec()
	for pair: Array in query_pairs:
		reader.call("_build_grid_line_into", pair[0], pair[1], buffer, registry)
		lines.append(buffer.duplicate())
	var usec: int = Time.get_ticks_usec() - started
	return {"usec": usec, "signature": var_to_bytes(lines).hex_encode().sha256_text(), "audit": FIX.audit(reader)}

func _combat(registry: Node, query_pairs: Array, native_enabled: bool, sample: int) -> Dictionary:
	var cache = CACHE.new()
	var reader = FIX.los(native_enabled)
	cache.set("_los_system", reader)
	cache.begin_tick(sample + 1)
	var observers: Array = []
	var targets: Array = []
	var half_height_endpoints := 0
	for pair: Array in query_pairs:
		var source_steps2 := roundi(float(registry.call("get_stand_height_at", pair[0])) * 2.0)
		var target_steps2 := roundi(float(registry.call("get_stand_height_at", pair[1])) * 2.0)
		half_height_endpoints += posmod(source_steps2, 2) + posmod(target_steps2, 2)
		observers.append({"grid": pair[0], "facing_dir": 0, "stand_height_steps2": source_steps2})
		targets.append({"grid": pair[1], "stand_height_steps2": target_steps2})
	var outputs: Array = []
	var started: int = Time.get_ticks_usec()
	for repeat in range(4):
		for index in range(query_pairs.size()):
			outputs.append(cache.query_hex_visibility(observers[index], targets[index], registry, {"range_hex": -1, "arc_degrees": 360.0}))
	var usec: int = Time.get_ticks_usec() - started
	var cache_audit: Dictionary = cache.get_audit_snapshot()
	if cache_audit.hex_actual_los_check_count != 64 or cache_audit.cache_hit_count != 192:
		failures.append("Combat fixture failed to exercise exact 64 misses/192 cache hits")
	var result := {"usec": usec, "signature": var_to_bytes(outputs).hex_encode().sha256_text(), "cache": cache_audit, "audit": FIX.audit(reader), "half_height_endpoints": half_height_endpoints}
	cache.free()
	return result

func _fow(registry: Node, query_pairs: Array, native_enabled: bool) -> Dictionary:
	var system = FOW.new()
	var reader = FIX.los(native_enabled)
	var observers: Array = []
	for index in range(4):
		var observer := Node2D.new()
		observer.position = registry.call("grid_to_world", query_pairs[index * 11][0])
		observers.append(observer)
	system.set_mode_for_team("probe", "unexplored_blackout")
	var full: Dictionary = _fow_job(system, observers, registry, reader)
	var full_state: Dictionary = system.build_team_state_snapshot("probe")
	for index in range(observers.size()):
		observers[index].position = registry.call("grid_to_world", query_pairs[index * 11][0] + Vector2i(1, 0))
	var dirty: Dictionary = _fow_job(system, observers, registry, reader)
	var dirty_state: Dictionary = system.build_team_state_snapshot("probe")
	if not full.completed or not dirty.completed or not full.full_scan or dirty.full_scan:
		failures.append("FoW fixture must finish one full and one dirty job")
	for observer: Node in observers: observer.free()
	return {"full": full, "dirty": dirty, "full_signature": var_to_bytes(full_state).hex_encode().sha256_text(),
		"dirty_signature": var_to_bytes(dirty_state).hex_encode().sha256_text(), "audit": FIX.audit(reader)}

func _fow_job(system, observers: Array, registry: Node, reader) -> Dictionary:
	var started: int = Time.get_ticks_usec()
	var state: Dictionary = system.request_tile_visibility_update_for_team("probe", observers, registry, reader, sqrt(64.0 * 64.0 + 32.0 * 32.0) * 8.0, {"work_budget_tiles": 256})
	var slices: Array = []
	while not state.get("completed", false) and slices.size() < 2048:
		var slice_started: int = Time.get_ticks_usec()
		state = system.process_pending_tile_visibility_work("probe", 256)
		slices.append(Time.get_ticks_usec() - slice_started)
	var usec: int = Time.get_ticks_usec() - started
	return {"usec": usec, "slices_usec": slices, "completed": state.get("completed", false), "full_scan": state.get("full_scan", false),
		"processed_tile_count": state.get("processed_tile_count", 0), "candidate_tile_count": state.get("candidate_tile_count", 0)}
