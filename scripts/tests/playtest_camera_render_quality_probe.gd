extends SceneTree
## Same-frame-style GPU comparison: original AA off and bounded 2x MSAA.
## Capture directory and profile are explicitly supplied by the caller.
var output := ""
var baseline_shader := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("output="):
			output = arg.trim_prefix("output=")
		if arg.begins_with("baseline_shader="):
			baseline_shader = arg.trim_prefix("baseline_shader=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		push_error("Supply output=<absolute directory> and use a native renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1920, 1080)
	var base: Control = load("res://scenes/meta/explorable_homebase.tscn").instantiate()
	root.add_child(base)
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.call("set_transport_snapshot", {"mode": "campaign"})
	base.call("set_active", true)
	for index in range(12): await process_frame
	base.set_process(false)
	base.set_physics_process(false)
	base.process_mode = Node.PROCESS_MODE_DISABLED
	var view: Node = base.get("_view")
	view.set("_camera_size", 60.0)
	view.call("focus_map_center")
	var viewport: SubViewport = view.get("_subviewport")
	var container: SubViewportContainer = view.get("_viewport_container")
	var metadata := {
		"renderer": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"display_server": DisplayServer.get_name(),
		"root_size": str(root.size), "base_host_size": str(base.get("_host").size),
		"base_viewport_size": str(base.get("_viewport").size),
		"render_container_size": str(container.size), "render_viewport_size": str(viewport.size),
		"stretch_shrink": container.stretch_shrink, "original_msaa_3d": viewport.msaa_3d,
		"scaling_3d_scale": viewport.scaling_3d_scale, "screen_space_aa": viewport.screen_space_aa,
		"taa": viewport.use_taa, "camera_size": view.get_camera_size(),
		"camera_pitch": view.get("_camera_pitch_degrees"),
		"gpu_name": RenderingServer.get_video_adapter_name(),
		"captures": [],
	}
	var shader: Shader = load("res://shaders/terrain/frontier_ground.gdshader")
	var candidate_code := shader.code
	var versions := ["candidate"] if baseline_shader.is_empty() else ["baseline", "candidate"]
	metadata["candidate_shader_sha256"] = FileAccess.get_sha256("res://shaders/terrain/frontier_ground.gdshader")
	metadata["baseline_shader_path"] = baseline_shader
	metadata["baseline_shader_sha256"] = FileAccess.get_sha256(baseline_shader) if not baseline_shader.is_empty() else ""
	for version in versions:
		shader.code = FileAccess.get_file_as_string(baseline_shader) if version == "baseline" else candidate_code
		for camera_size in [60.0, 16.0]:
			view.set("_camera_size", camera_size)
			view.call("focus_map_center")
			for aa in [Viewport.MSAA_DISABLED, Viewport.MSAA_2X]:
				viewport.msaa_3d = aa
				view.call("_request_viewport_redraw", true, 5000)
				for index in range(18): await process_frame
				await RenderingServer.frame_post_draw
				var name: String = "%s_size%d_%s" % [version, int(camera_size), "aa_off" if aa == Viewport.MSAA_DISABLED else "msaa_2x"]
				var path: String = output.path_join(name + ".png")
				var error: int = viewport.get_texture().get_image().save_png(path)
				var frames: Array[float] = []
				var previous := Time.get_ticks_usec()
				for index in range(90):
					await process_frame
					var now := Time.get_ticks_usec()
					frames.append(float(now - previous) / 1000.0)
					previous = now
				frames.sort()
				metadata.captures.append({"path": path, "sha256": FileAccess.get_sha256(path), "save_error": error,
					"shader_version": version, "camera_size": camera_size,
					"msaa_3d": viewport.msaa_3d, "frame_p50_ms": frames[45], "frame_p95_ms": frames[85]})
	shader.code = candidate_code
	var file := FileAccess.open(output.path_join("metadata.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t"))
	print("CAMERA_RENDER_QUALITY ", JSON.stringify(metadata))
	base.free()
	quit()
