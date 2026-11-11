extends SceneTree
## Native terrain-only camera and load probe. Pass a map name and output prefix.
const VIEW = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP = preload("res://scripts/terrain/terrain_map_data.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() not in [2, 4]:
		quit(2)
		return
	var start := Time.get_ticks_msec()
	var map_path := args[0] if args[0].ends_with(".json") else "res://maps/%s.json" % args[0]
	var map = MAP.load_from_file(map_path)
	var parse_ms := Time.get_ticks_msec() - start
	var view = VIEW.new()
	root.add_child(view)
	await process_frame
	view.set_frontier_art_enabled(true)
	start = Time.get_ticks_msec()
	view.configure_from_map(map)
	view.set_hex_grid_visible(true)
	var render_ms := Time.get_ticks_msec() - start
	var spawn: Vector2 = map.get_marker_position("spawn_alpha")
	if args.size() == 4:
		spawn = view.grid_to_world_position(Vector2i(int(args[2]), int(args[3])))
	var first := true
	var failed := false
	for camera_size: float in [44.0, 18.0, 540.0]:
		view.set("_camera_size", camera_size)
		view.set("_camera_yaw_degrees", 24.0)
		view.set("_camera_pitch_degrees", 50.0)
		if camera_size < 100:
			view.focus_world_position(spawn)
		else:
			view.focus_map_center()
		view.call("_request_viewport_redraw", true, 60000)
		for frame in range(12):
			await process_frame
		for frame in range(240):
			if Array(view.get("_regional_pending_chunks")).is_empty() and not bool(view.get("_visual_streaming_refresh_queued")):
				break
			await process_frame
		await RenderingServer.frame_post_draw
		var target := "%s_%d.png" % [args[1], int(camera_size)]
		var picture := root.get_texture().get_image()
		var error := picture.save_png(target)
		failed = failed or error != OK
		if first:
			print("NATIVE_MAP parse_ms=%d initial_render_ms=%d static_bytes=%d video_bytes=%d" % [
				parse_ms, render_ms, OS.get_static_memory_usage(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)])
			first = false
		print("NATIVE_MAP capture=", target, " size=", picture.get_size(), " error=", error)
	view.queue_free()
	await process_frame
	quit(1 if failed else 0)
