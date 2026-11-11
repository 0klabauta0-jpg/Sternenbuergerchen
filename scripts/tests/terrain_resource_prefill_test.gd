extends SceneTree
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
var passed := 0
var failed := 0
func _init() -> void: call_deferred("_run")
func _check(ok: bool, label: String) -> void:
	passed += int(ok)
	failed += int(not ok)
	print("PASS: " if ok else "FAIL: ", label)
func _run() -> void:
	var loader := VIEW.new()
	if not loader.has_method("configure_terrain_resource_prefill"):
		_check(false, "Whole-map resource prefill API exists")
		loader.free()
		_finish()
		return
	loader.hide()
	root.add_child(loader)
	await process_frame
	var map_name := String(OS.get_cmdline_user_args()[0]) if not OS.get_cmdline_user_args().is_empty() else "trade_outpost"
	var map = MAP.load_from_file("res://maps/" + map_name + ".json")
	loader.call("configure_terrain_resource_prefill", map, 256 * 1024 * 1024)
	var first: Dictionary = loader.call("get_terrain_resource_preparation_snapshot")
	_check(not first.ready and first.expected_chunks == 2161, "Whole-map expected set is declared before readiness")
	_check(loader.get("_unit_nodes").is_empty(), "Visual preloader has no actors or simulation")
	var snapshot := first
	for frame in range(12000):
		await process_frame
		snapshot = loader.call("get_terrain_resource_preparation_snapshot")
		if snapshot.ready or snapshot.status == "failed": break
		if frame % 250 == 0: print("PREFILL_PROGRESS ", snapshot.prepared_chunks, "/", snapshot.expected_chunks)
	_check(snapshot.ready and snapshot.prepared_chunks == 2161, "Every actual map chunk is prepared before ready")
	_check(snapshot.retained_payload_bytes > 0 and snapshot.retained_payload_bytes <= snapshot.max_payload_bytes, "Full map resource payload remains within its explicit bound")
	_check(loader.get("_regional_chunk_nodes").is_empty() and loader.get("_map_root").get_child_count() == 0, "Prefill retains resources without all-map scene nodes")
	if not snapshot.ready:
		print("PREFILL_FAILURE ", snapshot)
		loader.free()
		_finish()
		return
	var cache = loader.call("get_prepared_terrain_resource_cache")
	var before_resources: int = cache.get_debug_snapshot().geometry_resource_count
	var visual := VIEW.new()
	root.add_child(visual)
	await process_frame
	visual.call("set_prepared_terrain_resource_cache", cache)
	visual.configure_from_map(map, map.get_marker_position("spawn_alpha"), 22.0)
	_check(int(visual.get("_regional_chunk_build_count")) == 0, "Initial visible map reuses prepared resources without geometry construction")
	_check(int(visual.get("_terrain_resource_restore_count")) > 0, "Initial chunk nodes are newly instantiated from cached resources")
	for target in [Vector2i(190, 75), Vector2i(-110, -65), visual.world_to_grid_position(map.get_marker_position("spawn_alpha"))]:
		visual.focus_world_position(visual.grid_to_world_position(target))
		visual.call("_refresh_visual_streaming_chunks")
		for frame in range(300):
			await process_frame
			if visual.get("_regional_pending_chunks").is_empty() and not visual.get("_visual_streaming_refresh_queued"): break
		_check(int(visual.get("_regional_chunk_build_count")) == 0, "Distant camera travel does not rebuild SurfaceTool or instance buffers")
		_check(visual.get("_regional_chunk_nodes").size() <= visual.get("_visual_streaming_active_chunks").size() + 64, "Active and retained chunk-node count stays bounded")
	_check(cache.get_debug_snapshot().geometry_resource_count == before_resources, "Camera travel creates no replacement geometry resources")
	print("PREFILL_FULL_MAP_SNAPSHOT ", JSON.stringify(snapshot))
	var mismatched := VIEW.new()
	root.add_child(mismatched)
	await process_frame
	mismatched.set_hex_grid_visible(false)
	mismatched.set_prepared_terrain_resource_cache(cache)
	mismatched.configure_from_map(map)
	var invalid_handoff: Dictionary = mismatched.get_terrain_resource_preparation_snapshot()
	_check(not invalid_handoff.ready and invalid_handoff.reason == "prepared_cache_context_mismatch" and int(mismatched.get("_regional_chunk_build_count")) == 0, "Profile/grid mismatch fails closed instead of synchronous partial rebuild")
	mismatched.free()
	loader.free()
	visual.free()
	var small := VIEW.new()
	small.hide()
	root.add_child(small)
	await process_frame
	small.call("configure_terrain_resource_prefill", map, 1)
	for frame in range(10): await process_frame
	var rejected: Dictionary = small.call("get_terrain_resource_preparation_snapshot")
	_check(rejected.status == "failed" and not rejected.ready, "Insufficient budget produces explicit failure, never partial-ready")
	_check(small.get("_regional_chunk_nodes").is_empty(), "Budget failure leaves no full-map chunk nodes")
	small.free()
	var cancelled := VIEW.new()
	cancelled.hide()
	root.add_child(cancelled)
	await process_frame
	cancelled.call("configure_terrain_resource_prefill", map, 256 * 1024 * 1024)
	cancelled.call("cancel_terrain_resource_prefill")
	_check(cancelled.call("get_terrain_resource_preparation_snapshot").status == "cancelled" and not cancelled.call("get_terrain_resource_preparation_snapshot").ready, "Cancelled preload never becomes ready")
	cancelled.free()
	await process_frame
	_finish()
func _finish() -> void:
	print("TERRAIN_RESOURCE_PREFILL %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
