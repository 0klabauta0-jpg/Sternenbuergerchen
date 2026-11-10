extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	print("GPU_REPRO device=", RenderingServer.get_video_adapter_name(), " method=", RenderingServer.get_current_rendering_method())
	var viewport := SubViewport.new()
	viewport.size = Vector2i(32, 32)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ssao_enabled = true
	viewport.add_child(environment)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 0, 3)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	viewport.add_child(mesh)
	for frame in range(5):
		await process_frame
		RenderingServer.force_draw(false)
	print("GPU_REPRO completed")
	quit()
