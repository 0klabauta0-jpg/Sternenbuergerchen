extends SceneTree

const FOW: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const REGISTRY: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TILE: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")
const WORK_BUDGET: int = 256

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== REVIEW8 square8 FoW projection oracle ===")
	# The first case is the existing TASK1189 large-map scale and sight range.
	for fixture in [
		{"name": "task1189_scale", "half_width": 16.0, "half_height": 8.0, "range": 640.0},
		{"name": "regular_iso", "half_width": 64.0, "half_height": 32.0, "range": 640.0},
		{"name": "wide_iso", "half_width": 64.0, "half_height": 8.0, "range": 640.0},
		{"name": "tall_iso", "half_width": 8.0, "half_height": 32.0, "range": 480.0},
	]:
		_test_projection(Dictionary(fixture))
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	if _failed == 0:
		print("REVIEW8_FOW_PROJECTION_PASS")
	quit(1 if _failed > 0 else 0)


func _test_projection(fixture: Dictionary) -> void:
	var label: String = String(fixture.name)
	var registry = REGISTRY.new()
	registry.configure_iso_grid(Vector2(-321.0, 777.0), float(fixture.half_width), float(fixture.half_height))
	for x in range(128):
		for y in range(128):
			var grid := Vector2i(x, y)
			registry.register_tile(TILE.new({
				"tile_id": "tile_%d_%d" % [x, y],
				"type_id": "ground_flat",
				"grid_position": grid,
				"world_position": registry.grid_to_world(grid),
				"walkable": true,
				"blocks_los": false,
				"surface_type": "ground",
			}))
	var observer := Node2D.new()
	root.add_child(observer)
	observer.global_position = registry.grid_to_world(Vector2i(64, 64))
	var incremental = FOW.new()
	var oracle = FOW.new()
	for fow in [incremental, oracle]:
		fow.set_mode_for_team("alpha", "unexplored_blackout")
		fow.update_tile_visibility_for_team("alpha", [observer], registry, null, float(fixture.range))
	if label == "task1189_scale":
		_assert(incremental.is_tile_currently_visible("alpha", "tile_20_32"), "Hand-checked old fringe tile starts visible")
	var axis_x: Vector2 = registry.grid_to_world(Vector2i.RIGHT) - registry.grid_to_world(Vector2i.ZERO)
	var axis_y: Vector2 = registry.grid_to_world(Vector2i.DOWN) - registry.grid_to_world(Vector2i.ZERO)
	for step in [
		{"grid": Vector2i(65, 64), "offset": Vector2.ZERO},
		{"grid": Vector2i(66, 65), "offset": Vector2.ZERO},
		{"grid": Vector2i(66, 65), "offset": Vector2(0.49, -0.49)},
		{"grid": Vector2i(64, 64), "offset": Vector2(-0.49, 0.49)},
		{"grid": Vector2i(64, 64), "offset": Vector2.ZERO},
		{"grid": Vector2i(2, 2), "offset": Vector2(-0.49, -0.49)},
	]:
		var destination: Vector2i = Vector2i(step.grid)
		var offset: Vector2 = Vector2(step.offset)
		var sample_label: String = "%s + %s" % [destination, offset]
		var before: Dictionary = incremental.build_team_state_snapshot("alpha")
		observer.global_position = registry.grid_to_world(destination) + axis_x * offset.x + axis_y * offset.y
		var request: Dictionary = incremental.request_tile_visibility_update_for_team("alpha", [observer], registry, null, float(fixture.range), {"work_budget_tiles": WORK_BUDGET})
		_assert(not bool(request.get("full_scan", true)), "%s %s uses dirty work" % [label, sample_label])
		var first_slice: Dictionary = incremental.process_pending_tile_visibility_work("alpha", WORK_BUDGET)
		if not bool(first_slice.get("completed", false)):
			_assert(_knowledge(incremental) == Dictionary(before.get("terrain_knowledge", {})), "%s %s publishes no partial terrain revision" % [label, sample_label])
		var completion: Dictionary = _finish(incremental, first_slice)
		_assert(bool(completion.get("completed", false)), "%s %s dirty work terminates within bounded slices" % [label, sample_label])
		oracle.update_tile_visibility_for_team("alpha", [observer], registry, null, float(fixture.range))
		_assert(_knowledge(incremental) == _knowledge(oracle), "%s %s visible and explored tiles equal full-scan oracle" % [label, sample_label])
		if label == "task1189_scale" and destination == Vector2i(65, 64):
			# World distances are 637.595 before, 650.169 after the move, range 640.
			_assert(not incremental.is_tile_currently_visible("alpha", "tile_20_32"), "Hand-checked old fringe tile loses current visibility")
		if destination == Vector2i(65, 64):
			print("REVIEW8_FOW_PROJECTION_WORKLOAD ", JSON.stringify({
				"projection": label,
				"sight_range_world": fixture.range,
				"estimated_grid_lookups": request.get("candidate_tile_count", 0),
				"actual_grid_lookups": completion.get("test_candidate_scan_processed", 0),
				"evaluated_tiles": completion.get("tile_count", 0),
				"slice_count": completion.get("test_slice_count", 0),
				"work_budget_tiles": WORK_BUDGET,
			}))
	# The last published footprint must also disappear when its observer leaves.
	incremental.request_tile_visibility_update_for_team("alpha", [], registry, null, float(fixture.range))
	var removed: Dictionary = _finish(incremental, {})
	oracle.update_tile_visibility_for_team("alpha", [], registry, null, float(fixture.range))
	_assert(bool(removed.get("completed", false)) and _knowledge(incremental) == _knowledge(oracle), "%s observer removal clears all current sight and retains explored history" % label)
	observer.free()
	registry.free()


func _finish(fow, first_slice: Dictionary) -> Dictionary:
	var update: Dictionary = first_slice
	var slices: int = 0 if first_slice.is_empty() else 1
	var scanned_tiles: int = int(update.get("candidate_scan_processed", 0))
	var within_budget: bool = int(update.get("processed_in_slice", 0)) <= WORK_BUDGET
	while not bool(update.get("completed", false)) and slices < 4096:
		update = fow.process_pending_tile_visibility_work("alpha", WORK_BUDGET)
		within_budget = within_budget and int(update.get("processed_in_slice", 0)) <= WORK_BUDGET
		scanned_tiles = maxi(scanned_tiles, int(update.get("candidate_scan_processed", 0)))
		slices += 1
	_assert(within_budget, "Every visibility evaluation slice honors its tile budget")
	update["test_slice_count"] = slices
	update["test_candidate_scan_processed"] = scanned_tiles
	return update


func _knowledge(fow) -> Dictionary:
	return Dictionary(fow.build_team_state_snapshot("alpha").get("terrain_knowledge", {}))


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
