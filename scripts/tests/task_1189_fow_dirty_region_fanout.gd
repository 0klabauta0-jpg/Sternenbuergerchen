extends SceneTree

const FOW_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/fog_of_war_system.gd")
const LOS_SYSTEM_SCRIPT: GDScript = preload("res://scripts/core/los_system.gd")
const TERRAIN_REGISTRY_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_registry.gd")
const TERRAIN_TILE_DATA_SCRIPT: GDScript = preload("res://scripts/terrain/terrain_tile_data.gd")

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("=== TASK_1189 FOW Dirty Region Fan-out ===")
	_test_atomic_incremental_visibility_matches_full_scan_oracle()
	_test_dirty_region_preserves_los_visibility_truth()
	_test_large_map_work_is_bounded_to_dirty_candidates()
	_test_large_map_dirty_work_stays_within_frame_and_staleness_budgets()
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _test_atomic_incremental_visibility_matches_full_scan_oracle() -> void:
	var registry: Node = _make_registry(Vector2i(32, 32))
	var observer := _make_observer(registry, Vector2i(12, 12))
	var incremental = FOW_SYSTEM_SCRIPT.new()
	incremental.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	incremental.call("update_tile_visibility_for_team", "team_alpha", [observer], registry, null, 128.0)
	var before: Dictionary = Dictionary(incremental.call("build_team_state_snapshot", "team_alpha"))

	observer.global_position = registry.call("grid_to_world", Vector2i(13, 12))
	var request: Dictionary = Dictionary(incremental.call(
		"request_tile_visibility_update_for_team",
		"team_alpha",
		[observer],
		registry,
		null,
		128.0,
		{"work_budget_tiles": 8, "dirty_chunk_size": 8}
	))
	_assert(not bool(request.get("full_scan", true)), "One-cell observer movement creates a dirty-region request")
	_assert(int(request.get("candidate_tile_count", 1024)) < 1024, "Dirty region is smaller than the full 32x32 map")
	_assert(int(request.get("dirty_chunk_count", 0)) > 0, "Dirty-region request reports affected chunks")

	var first_slice: Dictionary = Dictionary(incremental.call("process_pending_tile_visibility_work", "team_alpha", 8))
	_assert(not bool(first_slice.get("completed", true)), "Incomplete dirty work is not published early")
	var during: Dictionary = Dictionary(incremental.call("build_team_state_snapshot", "team_alpha"))
	_assert(PackedStringArray(Dictionary(during.get("terrain_knowledge", {})).get("visible_tile_ids", PackedStringArray())) == PackedStringArray(Dictionary(before.get("terrain_knowledge", {})).get("visible_tile_ids", PackedStringArray())), "Published visibility remains atomic during partial work")
	var update: Dictionary = first_slice
	while not bool(update.get("completed", false)):
		update = Dictionary(incremental.call("process_pending_tile_visibility_work", "team_alpha", 8))
	_assert(int(update.get("visibility_revision", 0)) > 0, "Completed dirty work publishes a visibility revision")
	_assert(int(Array(update.get("changed_tiles", [])).size()) > 0, "Completed revision reports changed tile deltas")
	var completed_state: Dictionary = Dictionary(incremental.call("build_team_state_snapshot", "team_alpha"))
	_assert(int(completed_state.get("visibility_revision", 0)) > 0, "Published snapshot retains the visibility revision")
	_assert(not Dictionary(completed_state.get("visibility_delta", {})).is_empty(), "Published snapshot retains the visibility delta")

	var oracle = FOW_SYSTEM_SCRIPT.new()
	oracle.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	var oracle_observer := _make_observer(registry, Vector2i(12, 12))
	oracle.call("update_tile_visibility_for_team", "team_alpha", [oracle_observer], registry, null, 128.0)
	oracle_observer.global_position = registry.call("grid_to_world", Vector2i(13, 12))
	oracle.call("update_tile_visibility_for_team", "team_alpha", [oracle_observer], registry, null, 128.0)
	var actual_state: Dictionary = Dictionary(incremental.call("build_team_state_snapshot", "team_alpha"))
	var oracle_state: Dictionary = Dictionary(oracle.call("build_team_state_snapshot", "team_alpha"))
	_assert(PackedStringArray(Dictionary(actual_state.get("terrain_knowledge", {})).get("visible_tile_ids", PackedStringArray())) == PackedStringArray(Dictionary(oracle_state.get("terrain_knowledge", {})).get("visible_tile_ids", PackedStringArray())), "Dirty-region result equals the full-scan visibility oracle")
	_assert(PackedStringArray(Dictionary(actual_state.get("terrain_knowledge", {})).get("explored_tile_ids", PackedStringArray())) == PackedStringArray(Dictionary(oracle_state.get("terrain_knowledge", {})).get("explored_tile_ids", PackedStringArray())), "Dirty-region result preserves explored-tile truth")
	observer.free()
	oracle_observer.free()
	registry.free()


func _test_dirty_region_preserves_los_visibility_truth() -> void:
	var registry: Node = _make_registry(Vector2i(32, 32))
	var blocker = registry.call("get_tile_at_grid", Vector2i(15, 12))
	blocker.blocks_los = true
	blocker.object_height = 2
	var los_system = LOS_SYSTEM_SCRIPT.new()
	var observer := _make_observer(registry, Vector2i(12, 12))
	var incremental = FOW_SYSTEM_SCRIPT.new()
	incremental.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	incremental.call("update_tile_visibility_for_team", "team_alpha", [observer], registry, los_system, 96.0)
	observer.global_position = registry.call("grid_to_world", Vector2i(13, 12))
	var request: Dictionary = Dictionary(incremental.call(
		"request_tile_visibility_update_for_team",
		"team_alpha",
		[observer],
		registry,
		los_system,
		96.0,
		{"work_budget_tiles": 16, "dirty_chunk_size": 8}
	))
	while not bool(Dictionary(incremental.call("process_pending_tile_visibility_work", "team_alpha", 16)).get("completed", false)):
		pass
	var oracle = FOW_SYSTEM_SCRIPT.new()
	oracle.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	var oracle_observer := _make_observer(registry, Vector2i(12, 12))
	oracle.call("update_tile_visibility_for_team", "team_alpha", [oracle_observer], registry, los_system, 96.0)
	oracle_observer.global_position = registry.call("grid_to_world", Vector2i(13, 12))
	oracle.call("update_tile_visibility_for_team", "team_alpha", [oracle_observer], registry, los_system, 96.0)
	var incremental_visible: PackedStringArray = PackedStringArray(Dictionary(Dictionary(incremental.call("build_team_state_snapshot", "team_alpha")).get("terrain_knowledge", {})).get("visible_tile_ids", PackedStringArray()))
	var oracle_visible: PackedStringArray = PackedStringArray(Dictionary(Dictionary(oracle.call("build_team_state_snapshot", "team_alpha")).get("terrain_knowledge", {})).get("visible_tile_ids", PackedStringArray()))
	_assert(not bool(request.get("full_scan", true)), "LOS movement still uses a dirty region")
	_assert(incremental_visible == oracle_visible, "Dirty-region visibility equals the LOS full-scan oracle")
	_assert(not incremental_visible.has("tile_18_12"), "LOS blocker remains hidden after dirty-region movement")
	observer.free()
	oracle_observer.free()
	registry.free()


func _test_large_map_work_is_bounded_to_dirty_candidates() -> void:
	var registry: Node = _make_registry(Vector2i(128, 128))
	var observer := _make_observer(registry, Vector2i(64, 64))
	var fow = FOW_SYSTEM_SCRIPT.new()
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	fow.call("update_tile_visibility_for_team", "team_alpha", [observer], registry, null, 256.0)
	observer.global_position = registry.call("grid_to_world", Vector2i(65, 64))
	var request: Dictionary = Dictionary(fow.call(
		"request_tile_visibility_update_for_team",
		"team_alpha",
		[observer],
		registry,
		null,
		256.0,
		{"work_budget_tiles": 64, "dirty_chunk_size": 8}
	))
	_assert(int(request.get("candidate_tile_count", 16384)) < 16384, "128x128 movement avoids a full-map candidate scan")
	var slice: Dictionary = Dictionary(fow.call("process_pending_tile_visibility_work", "team_alpha", 64))
	_assert(int(slice.get("processed_tile_count", 65)) <= 64, "One visibility slice honors its tile-work budget")
	_assert(not bool(slice.get("completed", true)), "Large-map visibility remains incremental after one bounded slice")
	observer.free()
	registry.free()


func _test_large_map_dirty_work_stays_within_frame_and_staleness_budgets() -> void:
	_verify_dirty_work_scale(Vector2i(128, 128), 16.7)
	_verify_dirty_work_scale(Vector2i(256, 256), 33.3)


func _verify_dirty_work_scale(size: Vector2i, max_slice_msec: float) -> void:
	const WORK_BUDGET_TILES: int = 512
	const UPDATE_INTERVAL_MSEC: float = 100.0
	const FRAME_MSEC: float = 1000.0 / 60.0
	var registry: Node = _make_registry(size)
	var center: Vector2i = Vector2i(size.x / 2, size.y / 2)
	var observer := _make_observer(registry, center)
	var fow = FOW_SYSTEM_SCRIPT.new()
	fow.call("set_mode_for_team", "team_alpha", "unexplored_blackout")
	fow.call("request_tile_visibility_update_for_team", "team_alpha", [observer], registry, null, 640.0, {"work_budget_tiles": 4096})
	while not bool(Dictionary(fow.call("process_pending_tile_visibility_work", "team_alpha", 4096)).get("completed", false)):
		pass
	observer.global_position = registry.call("grid_to_world", center + Vector2i(1, 0))
	var request_started_usec: int = Time.get_ticks_usec()
	var request: Dictionary = Dictionary(fow.call(
		"request_tile_visibility_update_for_team",
		"team_alpha",
		[observer],
		registry,
		null,
		640.0,
		{"work_budget_tiles": WORK_BUDGET_TILES, "dirty_chunk_size": 8}
	))
	var request_msec: float = float(Time.get_ticks_usec() - request_started_usec) / 1000.0
	var max_slice_observed_msec: float = 0.0
	var slice_count: int = 0
	var update: Dictionary = {}
	while not bool(update.get("completed", false)):
		var slice_started_usec: int = Time.get_ticks_usec()
		update = Dictionary(fow.call("process_pending_tile_visibility_work", "team_alpha", WORK_BUDGET_TILES))
		max_slice_observed_msec = maxf(max_slice_observed_msec, float(Time.get_ticks_usec() - slice_started_usec) / 1000.0)
		slice_count += 1
	var estimated_staleness_msec: float = UPDATE_INTERVAL_MSEC + (float(slice_count) * FRAME_MSEC)
	var scale_label: String = "%dx%d" % [size.x, size.y]
	_assert(not bool(request.get("full_scan", true)), "%s movement remains a dirty-region request" % scale_label)
	_assert(request_msec <= max_slice_msec, "%s dirty-region request stays within its frame budget (%.2f ms)" % [scale_label, request_msec])
	_assert(max_slice_observed_msec <= max_slice_msec, "%s bounded visibility slices stay within their frame budget (%.2f ms)" % [scale_label, max_slice_observed_msec])
	_assert(estimated_staleness_msec <= 350.0, "%s dirty visibility publishes within the 350 ms staleness limit (%.2f ms)" % [scale_label, estimated_staleness_msec])
	observer.free()
	registry.free()


func _make_registry(size: Vector2i) -> Node:
	var registry: Node = TERRAIN_REGISTRY_SCRIPT.new()
	registry.call("configure_iso_grid", Vector2.ZERO, 16.0, 8.0)
	for x in range(size.x):
		for y in range(size.y):
			var grid := Vector2i(x, y)
			registry.call("register_tile", TERRAIN_TILE_DATA_SCRIPT.call("from_dict", {
				"tile_id": "tile_%d_%d" % [x, y],
				"type_id": "ground_flat",
				"grid_position": grid,
				"world_position": registry.call("grid_to_world", grid),
				"walkable": true,
				"blocks_los": false,
				"cover_value": 0,
				"height_level": 0,
				"object_height": 0,
				"surface_type": "ground",
				"edge_type": "none",
			}))
	return registry


func _make_observer(registry: Node, grid_position: Vector2i) -> Node2D:
	var observer := Node2D.new()
	observer.global_position = registry.call("grid_to_world", grid_position)
	return observer


func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
