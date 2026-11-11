extends SceneTree
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var map = MAP.load_from_file("res://maps/satellite_crash_site.json")
	var view := VIEW.new()
	root.add_child(view)
	await process_frame
	view.configure_from_map(map)
	view.call("focus_world_position", map.get_marker_position("spawn_alpha"))
	for frame in range(180):
		await process_frame
		if view.get("_regional_pending_chunks").is_empty() and not view.get("_visual_streaming_refresh_queued"):
			break
	var origin: Dictionary = view.get("_visual_streaming_active_chunks").duplicate()
	var chunk_count: int = view.get("_regional_chunk_build_count")
	view.focus_world_position(view.grid_to_world_position(Vector2i(171, 90)))
	view.call("_refresh_visual_streaming_chunks")
	var queued: bool = not view.get("_regional_pending_chunks").is_empty()
	view.focus_world_position(map.get_marker_position("spawn_alpha"))
	view.call("_refresh_visual_streaming_chunks")
	var valid: bool = queued and not origin.is_empty() and view.get("_regional_pending_chunks").is_empty()
	valid = valid and view.get("_visual_streaming_active_chunks") == origin
	valid = valid and view.get("_regional_chunk_build_count") == chunk_count
	print("REGIONAL_CAMERA_REVERSAL ", "PASS" if valid else "FAIL", " active=", origin.size())
	var home: Vector2 = map.get_marker_position("spawn_alpha")
	var nearby_cell: Vector2i = view.world_to_grid_position(home) + Vector2i(12, 0)
	view.focus_world_position(view.grid_to_world_position(nearby_cell))
	await _settle(view)
	var warm_build_count: int = view.get("_regional_chunk_build_count")
	var retained: Dictionary = view.get("_regional_retained_chunks")
	var retained_count := retained.size()
	view.focus_world_position(home)
	await _settle(view)
	var reuse: bool = retained_count > 0 and retained_count <= 64
	reuse = reuse and view.get("_visual_streaming_active_chunks") == origin
	reuse = reuse and view.get("_regional_chunk_build_count") == warm_build_count
	print("REGIONAL_CAMERA_CACHE ", "PASS" if reuse else "FAIL", " retained=", retained_count)
	var viewport: SubViewport = view.get("_subviewport")
	view.hide()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	view.call("_request_viewport_redraw")
	var hidden: bool = viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED
	view.show()
	view.call("_request_viewport_redraw")
	hidden = hidden and viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED
	print("REGIONAL_HIDDEN_VIEWPORT ", "PASS" if hidden else "FAIL")
	valid = valid and reuse and hidden
	view.queue_free()
	await process_frame
	quit(0 if valid else 1)


func _settle(view: Node) -> void:
	for index in range(180):
		await process_frame
		if view.get("_regional_pending_chunks").is_empty() and not view.get("_visual_streaming_refresh_queued"):
			return
