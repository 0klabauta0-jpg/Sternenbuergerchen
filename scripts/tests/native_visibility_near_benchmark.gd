extends SceneTree
## Bounded admitted combat reads at 4..8 Hex range, with the current cache intact.
## Separate evidence variant: does not modify the frozen long-ray/FoW benchmark.
const FIX = preload("res://scripts/tests/native_visibility_fixtures.gd")
const HEX = preload("res://scripts/terrain/hex_grid.gd")
const CACHE = preload("res://scripts/mission/combat_visibility_cache.gd")
var failures: Array = []
var rows: Array = []

func _init() -> void: call_deferred("_run")

func _run() -> void:
	var samples := maxi(int(FIX.argument("--samples", "20")), 1)
	var backends: Array[String] = ["gdscript"]
	if FIX.argument("--backend", "paired") == "paired":
		if not ClassDB.class_exists("NativeVisibilityKernel"):
			failures.append("Paired benchmark requires NativeVisibilityKernel")
		else:
			backends.append("native")
	var load_started := Time.get_ticks_usec()
	var registry: Node = FIX.gm01()
	var load_usec := Time.get_ticks_usec() - load_started
	var pairs: Array = _near_pairs(registry)
	if pairs.size() != 64:
		failures.append("Need exactly64 distinct admitted near pairs")
	var distances: Array[int] = []
	var half_height_endpoints := 0
	for pair: Dictionary in pairs:
		distances.append(int(pair.distance_hex))
		half_height_endpoints += posmod(int(pair.observer.stand_height_steps2), 2) + posmod(int(pair.target.stand_height_steps2), 2)
	var reference_signature := ""
	var revision: int = registry.call("get_revision")
	for sample in range(samples + 3):
		var order: Array = backends.duplicate()
		if sample % 2: order.reverse()
		for backend: String in order:
			var row: Dictionary = _sample(registry, pairs, backend == "native", sample)
			if reference_signature.is_empty(): reference_signature = String(row.signature)
			elif row.signature != reference_signature: failures.append("Near visibility result changed for sample%d/%s" % [sample, backend])
			if backend == "native" and int(row.audit.get("native_calls", 0)) != 64:
				failures.append("Near native row must execute exactly64 native rays")
			if backend == "gdscript" and int(row.audit.get("native_calls", 0)) != 0:
				failures.append("GDScript reference unexpectedly executed native work")
			if sample >= 3:
				row["sample"] = sample - 3
				row["backend"] = backend
				rows.append(row)
	if registry.call("get_revision") != revision: failures.append("Benchmark mutated terrain revision")
	var report := {"schema": "native_visibility_near_cached_queries.v1", "passed": failures.is_empty(), "failures": failures,
		"rows": rows, "pairs": pairs, "context": {"engine": Engine.get_version_info(), "cpu": OS.get_processor_name(), "os": OS.get_name(),
			"renderer": "headless", "gpu_timing": "unavailable", "map": "Ground_Mission01_32x32.json", "tiles": registry.call("get_tile_count"),
			"fixture_load_usec": load_usec, "samples_per_backend": samples, "warmup": 3, "pair_count": pairs.size(),
			"query_distances_hex": distances, "half_height_endpoints": half_height_endpoints,
			"profile": {"range_hex": 8, "arc_degrees": 120.0},
			"metric": "64 distinct ordered real-map walkable source/target pairs at4..8hex on six axes; facing aligned to each target; four reads each and fresh begin_tick per sample;64 misses/192 hits on current CombatVisibilityCache",
			"ordering": "GDScript first on even samples, native first on odd samples",
			"scope": "Complete admitted cached Hex visibility query CPU including native boundary/result transfer, first native kernel creation and outputs; excludes fixture/load/setup/hash/audit. No full fight, FoW, FPS, rendering or multiplayer claim."}}
	if not FIX.write_json(FIX.argument("--output", "user://native_visibility_near_benchmark.json"), report): failures.append("Evidence write failed")
	registry.free()
	print("NATIVE_VISIBILITY_NEAR_BENCHMARK rows=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _near_pairs(registry: Node) -> Array:
	var tiles: Array = registry.call("get_sorted_tiles")
	var result: Array = []
	var used := {}
	for attempt in range(tiles.size()):
		var source: Vector2i = tiles[(attempt * 47 + 13) % tiles.size()].grid_position
		var facing: int = attempt % 6
		var distance: int = 4 + attempt % 5
		var target: Vector2i = source + HEX.DIRECTIONS[facing] * distance
		if not registry.call("is_walkable", source) or not registry.call("is_walkable", target): continue
		var key := "%d,%d:%d,%d" % [source.x, source.y, target.x, target.y]
		if used.has(key): continue
		used[key] = true
		result.append({"distance_hex": HEX.distance(source, target),
			"observer": {"grid": source, "facing_dir": facing, "stand_height_steps2": roundi(float(registry.call("get_stand_height_at", source)) * 2.0)},
			"target": {"grid": target, "stand_height_steps2": roundi(float(registry.call("get_stand_height_at", target)) * 2.0)}})
		if result.size() == 64: break
	return result

func _sample(registry: Node, pairs: Array, native_enabled: bool, sample: int) -> Dictionary:
	var cache = CACHE.new()
	var reader = FIX.los(native_enabled)
	cache.set("_los_system", reader)
	cache.begin_tick(sample + 1)
	var profile := {"range_hex": 8, "arc_degrees": 120.0}
	var outputs: Array = []
	var started := Time.get_ticks_usec()
	for repeat in range(4):
		for pair: Dictionary in pairs:
			outputs.append(cache.query_hex_visibility(pair.observer, pair.target, registry, profile))
	var elapsed := Time.get_ticks_usec() - started
	var audit: Dictionary = cache.get_audit_snapshot()
	if audit.hex_actual_los_check_count != 64 or audit.cache_hit_count != 192 or audit.range_rejected_count != 0:
		failures.append("Near fixture must exercise64 misses/192 hits with all range/arc filters admitted")
	var blocked := 0
	for index in range(pairs.size()):
		if not bool(outputs[index].terrain_checked): failures.append("Near pair was rejected before terrain")
		if not bool(outputs[index].terrain_clear): blocked += 1
	var result := {"usec": elapsed, "signature": var_to_bytes(outputs).hex_encode().sha256_text(), "cache": audit,
		"blocked_pairs": blocked, "clear_pairs": pairs.size() - blocked, "audit": FIX.audit(reader)}
	cache.free()
	return result
