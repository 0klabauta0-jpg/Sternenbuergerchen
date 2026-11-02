extends SceneTree
## Exact query/order equivalence and paired warm CPU samples, no mission runtime.
const REGISTRY = preload("res://scripts/terrain/terrain_registry.gd")
const TILE = preload("res://scripts/terrain/terrain_tile_data.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const SETUP = preload("res://scripts/tests/mission_test_setup.gd")
const MAP_PATH := "res://maps/Ground_Mission01_32x32.json"
const SCENARIO_PATH := "res://data/mission_scenarios/ground_mission01_default.json"
const REPORT_DIR := "res://docs/qa/gm01_frontier_20261102"
const QUERY_RADIUS := 220.0
const WARMUP_PAIRS := 6
const SAMPLE_PAIRS := 32
var passed := 0
var failed := 0
var checks: Array = []
var benchmark: Dictionary = {}


class LegacyRegistry extends "res://scripts/terrain/terrain_registry.gd":
	# Exact pre-change method body. Same inherited internal lookup/override calls,
	# not an external helper with a different dispatch or sorting cost.
	func get_walkable_cover_tiles_in_radius(world_center: Vector2, radius: float) -> Array:
		var radius_sq: float = radius * radius
		var result: Array = []
		for tile_data in _tiles.values():
			var grid_position: Vector2i = Vector2i(tile_data.grid_position)
			if not is_walkable(grid_position):
				continue
			if get_cover_at(grid_position) <= 0:
				continue
			if world_center.distance_squared_to(tile_data.world_position) > radius_sq:
				continue
			result.append(tile_data)
		return result


func _initialize() -> void:
	call_deferred("_run")


func _check(ok: bool, label: String) -> void:
	checks.append({"ok": ok, "label": label})
	if ok:
		passed += 1
		print("PASS: ", label)
	else:
		failed += 1
		push_error("FAIL: " + label)


func _tile(id: String, grid: Vector2i, world: Vector2, cover: int, walkable: bool = true):
	return TILE.from_dict({"tile_id": id, "grid_position": grid, "world_position": world,
		"type_id": "ground_flat", "surface_type": "ground", "walkable": walkable, "cover_value": cover})


func _pair(tiles: Array, topology: String, origin: Vector2 = Vector2.ZERO) -> Array:
	var before := LegacyRegistry.new()
	var after = REGISTRY.new()
	for registry in [before, after]:
		registry.configure_iso_grid(origin, 16.0, 8.0, topology)
		for tile in tiles:
			registry.register_tile(tile)
	return [before, after]


func _same_result(before: Array, after: Array) -> bool:
	if before.size() != after.size():
		return false
	for index in range(before.size()):
		if before[index] != after[index]:
			return false
	return true


func _ids(tiles: Array) -> Array:
	var result: Array = []
	for tile in tiles:
		result.append(tile.tile_id)
	return result


func _compare(pair: Array, label: String, centers: Array, radii: Array) -> void:
	var equivalent := true
	var count := 0
	for center in centers:
		for radius in radii:
			var before: Array = pair[0].get_walkable_cover_tiles_in_radius(center, radius)
			var after: Array = pair[1].get_walkable_cover_tiles_in_radius(center, radius)
			equivalent = equivalent and _same_result(before, after)
			count += 1
	_check(equivalent, "%s: same tile objects and insertion order for all %d queries" % [label, count])


func _run() -> void:
	for topology in ["square8", "hex_axial_v1"]:
		_test_fixture(topology)
	_test_actual_map_and_benchmark()
	_write_report()
	print("=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	if failed == 0:
		print("GM01_FRONTIER_COVER_RADIUS_ALL_PASS")
	quit(0 if failed == 0 else 1)


func _test_fixture(topology: String) -> void:
	# Deliberately sparse, unsorted grid coordinates and independently authored
	# world positions prove this query continues to use actual stored world data.
	var tiles: Array = [
		_tile("edge", Vector2i(-4, 2), Vector2(3.0, 4.0), 80),
		_tile("far_custom", Vector2i(1, 1), Vector2(1000.0, 1000.0), 100),
		_tile("origin", Vector2i(7, 9), Vector2.ZERO, 40),
		_tile("no_cover", Vector2i(9, -3), Vector2(2.0, 2.0), 0),
		_tile("blocked", Vector2i(-2, 5), Vector2.ONE, 60, false),
		_tile("negative_edge", Vector2i(12, 12), Vector2(-3.0, -4.0), 20),
		_tile("outside", Vector2i(0, 0), Vector2(5.0001, 0.0), 50),
	]
	var pair := _pair(tiles, topology, Vector2(111.0, -37.0))
	var centers := [Vector2.ZERO, Vector2(1000.0, 1000.0), Vector2(111.0, -37.0), Vector2(-100.0, 100.0)]
	var radii := [0.0, 4.99999, 5.0, -5.0, 6.0, 220.0, 2000.0]
	_compare(pair, topology + " sparse/custom/negative grid", centers, radii)
	var exact: Array = pair[1].get_walkable_cover_tiles_in_radius(Vector2.ZERO, 5.0)
	_check(_ids(exact) == ["edge", "origin", "negative_edge"], topology + ": inclusive exact radius boundary retains unsorted insertion order")
	_check(_same_result(exact, pair[1].get_walkable_cover_tiles_in_radius(Vector2.ZERO, -5.0)), topology + ": negative radius preserves the existing radius-squared semantics")
	_check(_ids(pair[1].get_walkable_cover_tiles_in_radius(Vector2.ZERO, 0.0)) == ["origin"], topology + ": zero radius includes exactly coincident eligible cells")
	var overrides := [
		{"grid_position": Vector2i(9, -3), "cover_value_override": 85},
		{"grid_position": Vector2i(-2, 5), "walkable_override": true, "cover_value_override": 95},
		{"grid_position": Vector2i(7, 9), "walkable_override": false},
		{"grid_position": Vector2i(12, 12), "cover_value_override": 0},
		{"grid_position": Vector2i(999, 999), "walkable_override": true, "cover_value_override": 100},
	]
	for registry in pair:
		registry.set_runtime_tile_overrides(overrides)
	_compare(pair, topology + " runtime walkability/cover overrides", centers, radii)
	_check(_ids(pair[1].get_walkable_cover_tiles_in_radius(Vector2.ZERO, 5.0)) == ["edge", "no_cover", "blocked"], topology + ": effective runtime values still determine eligibility")
	for registry in pair:
		registry.clear_runtime_tile_overrides()
	_compare(pair, topology + " cleared overrides", centers, radii)
	var replacement = _tile("replacement", Vector2i(-4, 2), Vector2(0.0, 1.0), 10)
	var added = _tile("added", Vector2i(18, -5), Vector2(4.0, 0.0), 22)
	for registry in pair:
		registry.register_tile(replacement)
		registry.register_tile(added)
	_compare(pair, topology + " replace/register", centers, radii)
	_check(_ids(pair[1].get_walkable_cover_tiles_in_radius(Vector2.ZERO, 5.0)) == ["replacement", "origin", "negative_edge", "added"], topology + ": replacement preserves key position and registration appends")
	# Registry has no removal API. Its public clear/re-register lifecycle removes
	# a cell without adding a new gameplay mutator or reaching into private state.
	for registry in pair:
		registry.clear_tiles()
		for tile in tiles:
			if tile.tile_id != "edge":
				registry.register_tile(tile)
	_compare(pair, topology + " remove through clear/reregister", centers, radii)
	for registry in pair:
		registry.configure_iso_grid(Vector2(-555.0, 777.0), 64.0, 32.0,
			"hex_axial_v1" if topology == "square8" else "square8")
	_compare(pair, topology + " origin/scale/topology reconfiguration", centers, radii)
	for registry in pair:
		registry.clear_tiles()
	_compare(pair, topology + " empty after clear", centers, radii)
	for registry in pair:
		registry.free()


func _test_actual_map_and_benchmark() -> void:
	var map_sha := FileAccess.get_sha256(MAP_PATH)
	var data = MAP.load_from_file(MAP_PATH)
	_check(data != null and not data.has_load_issue() and data.get_tiles().size() == 2304 and data.get_grid_topology() == "hex_axial_v1", "Benchmark source is the actual 2304-cell saved Hex GM01")
	if data == null or data.get_tiles().size() != 2304:
		return
	var pair := _pair(data.get_tiles(), data.get_grid_topology(), data.get_grid_origin())
	var size: Dictionary = data.get_tile_size()
	for registry in pair:
		registry.configure_iso_grid(data.get_grid_origin(), float(size["half_width"]), float(size["half_height"]), data.get_grid_topology())
	var centers: Array = []
	var setup = SETUP.new()
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO_PATH))
	var enemy_index := 0
	for group in Array(scenario.get("enemy_groups", [])):
		var marker: Vector2 = data.get_marker_position(String(group.get("spawn_marker_id", "")))
		for _enemy_id in Array(group.get("enemy_ids", [])):
			centers.append(marker + Vector2(setup.call("_get_enemy_spawn_offset", enemy_index)))
			enemy_index += 1
	setup.free()
	_check(centers.size() == 8, "Both benchmark variants use the exact same eight real enemy spawn centers")
	_compare(pair, "actual saved map", centers, [0.0, 96.0, 140.0, QUERY_RADIUS, -QUERY_RADIUS, 100000.0])
	var before_revision: int = pair[0].get_revision()
	var after_revision: int = pair[1].get_revision()
	for _warmup in range(WARMUP_PAIRS):
		_measure_batch(pair[0], centers)
		_measure_batch(pair[1], centers)
	var raw: Array = []
	var before_samples: Array = []
	var after_samples: Array = []
	var counts_match := true
	for index in range(SAMPLE_PAIRS):
		var before_sample: Dictionary
		var after_sample: Dictionary
		if index % 2 == 0:
			before_sample = _measure_batch(pair[0], centers)
			after_sample = _measure_batch(pair[1], centers)
		else:
			after_sample = _measure_batch(pair[1], centers)
			before_sample = _measure_batch(pair[0], centers)
		counts_match = counts_match and before_sample["result_count"] == after_sample["result_count"]
		before_samples.append(before_sample["usec"])
		after_samples.append(after_sample["usec"])
		raw.append({"pair": index, "first": "before" if index % 2 == 0 else "after",
			"before_usec": before_sample["usec"], "after_usec": after_sample["usec"],
			"result_count": after_sample["result_count"]})
	_check(raw.size() >= 20 and counts_match, "At least twenty alternating warm paired raw samples retain identical result counts")
	_check(pair[0].get_revision() == before_revision and pair[1].get_revision() == after_revision and FileAccess.get_sha256(MAP_PATH) == map_sha, "Equivalence queries and benchmark mutate neither Registry revisions nor saved map")
	var center_records: Array = []
	for center in centers:
		center_records.append({"x": center.x, "y": center.y})
	benchmark = {"metric": "warm_headless_cpu_registry_query_batch", "unit": "microseconds_per_eight_queries",
		"scope": "Radius filtering only; excludes AI scoring, candidate sorting, physics, rendering and normal-game FPS.",
		"before": "Exact pre-change filter order in LegacyRegistry subclass; same internal lookup methods.",
		"after": "Current TerrainRegistry; distance rejection before walkability and cover lookups.",
		"map_path": MAP_PATH, "map_sha256": map_sha, "tile_count": data.get_tiles().size(),
		"grid_topology": data.get_grid_topology(), "centers": center_records, "radius_world": QUERY_RADIUS,
		"warmup_pairs": WARMUP_PAIRS, "sample_pairs": SAMPLE_PAIRS, "raw_pairs": raw,
		"before_summary_usec": _summary(before_samples), "after_summary_usec": _summary(after_samples)}
	for registry in pair:
		registry.free()


func _measure_batch(registry: Node, centers: Array) -> Dictionary:
	var count := 0
	var started := Time.get_ticks_usec()
	for center in centers:
		var result: Array = registry.call("get_walkable_cover_tiles_in_radius", center, QUERY_RADIUS)
		count += result.size()
	return {"usec": Time.get_ticks_usec() - started, "result_count": count}


func _summary(samples: Array) -> Dictionary:
	var ordered := samples.duplicate()
	ordered.sort()
	var total := 0
	for sample in samples:
		total += int(sample)
	var middle: int = ordered.size() / 2
	return {"min": ordered[0], "median": (float(ordered[middle - 1]) + float(ordered[middle])) * 0.5,
		"p95": ordered[ceili(float(ordered.size()) * 0.95) - 1], "max": ordered.back(),
		"mean": float(total) / float(samples.size())}


func _write_report() -> void:
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	var report_path := REPORT_DIR + "/cover_radius_query_pairs_" + stamp + "-pid" + str(OS.get_process_id()) + ".json"
	var report := {"schema": "gm01.cover_radius_query_pairs.v1", "utc": Time.get_datetime_string_from_system(true),
		"engine": Engine.get_version_info(), "platform": OS.get_name(), "cpu": OS.get_processor_name(),
		"logical_processors": OS.get_processor_count(), "display": DisplayServer.get_name(),
		"command_line": OS.get_cmdline_args(), "passed": passed, "failed": failed, "checks": checks,
		"registry_sha256": FileAccess.get_sha256("res://scripts/terrain/terrain_registry.gd"),
		"verifier_sha256": FileAccess.get_sha256("res://scripts/tests/gm01_frontier_cover_radius_verifier.gd"),
		"benchmark": benchmark}
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		_check(false, "Write QA benchmark JSON: " + report_path)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	print("GM01_COVER_RADIUS_QUERY_REPORT=", ProjectSettings.globalize_path(report_path))
