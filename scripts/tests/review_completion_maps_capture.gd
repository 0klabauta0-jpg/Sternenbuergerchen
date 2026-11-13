extends "res://scripts/tests/review_completion_graphics_capture.gd"
## Active authored map families, same source/renderer/camera before and after.
func run() -> void:
	output = OS.get_environment("SB_REVIEW_COMPLETION_CAPTURE_DIR")
	if output.is_empty() or OS.get_environment("SB_REVIEW2_USER_DIR").is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	check(OS.get_user_data_dir().replace("\\", "/") == OS.get_environment("SB_REVIEW2_USER_DIR").replace("\\", "/"), "private profile")
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	for map_id: String in ["satellite_crash_site", "trade_outpost", "fortified_outpost", "polisa_station", "Ground_Mission02_128x128", "station_outpost_64x64"]:
		var path: String = "res://maps/" + map_id + ".json"
		var terrain = MAP.load_from_file(path)
		check(terrain != null and not terrain.get_tiles().is_empty(), map_id + " actual terrain")
		var view = VIEW.new()
		root.add_child(view)
		var marker := "station_camera_focus" if map_id == "polisa_station" else "objective_point"
		var focus: Vector2 = terrain.get_marker_position(marker, terrain.get_marker_position("spawn_alpha"))
		var camera_size := 62.0 if map_id == "polisa_station" else 26.0
		view.configure_from_map(terrain, focus, camera_size)
		view.set_authoring_markers_visible(false)
		await settle_map(view)
		check(int(view.get_render_snapshot().get("tile_count", 0)) > 0, map_id + " rendered terrain")
		await capture(map_id + "_objective", {"source": path, "sha256": FileAccess.get_sha256(path), "focus_marker": marker, "camera_size": camera_size, "render": view.get_render_snapshot()})
		if map_id in ["satellite_crash_site", "trade_outpost", "fortified_outpost"]:
			view.set("_camera_size", 30.0)
			view.focus_world_position(terrain.get_marker_position("spawn_alpha"))
			view.call("_update_camera_transform")
			await settle_map(view)
			await capture(map_id + "_arrival", {"source": path, "focus_marker": "spawn_alpha", "camera_size": 30.0, "render": view.get_render_snapshot()})
		view.queue_free()
		await frames()
	var file := FileAccess.open(output.path_join("capture_manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()
	print("REVIEW_MAPS_CAPTURE passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)

func settle_map(view: Node) -> void:
	await frames(8)
	for index in 600:
		if Array(view.get("_regional_pending_chunks")).is_empty(): break
		await process_frame
	check(Array(view.get("_regional_pending_chunks")).is_empty(), "regional camera chunks fully built")
	view.call("_request_viewport_redraw", true)
	await frames(4)
