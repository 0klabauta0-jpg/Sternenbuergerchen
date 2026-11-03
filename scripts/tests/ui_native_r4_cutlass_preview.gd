extends SceneTree

# Offline native render of the exact already-adopted model. No game actors or
# simulation state, no AI reinterpretation or replacement mesh/materials.
const MODEL := "res://Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb"
const EXPECTED_SHA := "21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf"
const OUTPUT := "res://Assets/curated/ui_native_r4/cutlass_ref03_preview.png"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless" or FileAccess.get_sha256(MODEL) != EXPECTED_SHA:
		push_error("Cutlass preview requires a renderer and the exact adopted Ref03 bytes.")
		quit(1)
		return
	root.size = Vector2i(768, 512)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(768, 512)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var packed := load(MODEL) as PackedScene
	var ship := packed.instantiate() as Node3D
	world.add_child(ship)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d3e1ec")
	environment.environment.ambient_light_energy = 0.65
	world.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -30, 0)
	key.light_energy = 1.5
	world.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 135, 0)
	fill.light_energy = 0.55
	world.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	var bounds := AABB(Vector3(-6.0391693, 0, -8), Vector3(12.0783386, 5.7466326, 16))
	var center := bounds.get_center()
	world.add_child(camera)
	camera.position = center + Vector3(1.1, 0.8, 1.3).normalized() * 40.0
	camera.look_at(center)
	var x_min := INF
	var x_max := -INF
	var y_min := INF
	var y_max := -INF
	for index in range(8):
		var projected: Vector3 = camera.global_transform.affine_inverse() * bounds.get_endpoint(index)
		x_min = minf(x_min, projected.x)
		x_max = maxf(x_max, projected.x)
		y_min = minf(y_min, projected.y)
		y_max = maxf(y_max, projected.y)
	camera.size = maxf(y_max - y_min, (x_max - x_min) / 1.5) * 1.08
	camera.current = true
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var rendered := viewport.get_texture().get_image()
	var save_error := rendered.save_png(OUTPUT)
	var metadata := {"kind": "native_exact_model_ui_preview", "visual_only": true, "asset_id": "cutlass_01", "display_name": "Cutlass", "source_model": MODEL, "source_sha256": FileAccess.get_sha256(MODEL), "image_sha256": FileAccess.get_sha256(OUTPUT), "size": [rendered.get_width(), rendered.get_height()], "transparent_background": rendered.detect_alpha() != Image.ALPHA_NONE, "geometry_material_override": false, "renderer": RenderingServer.get_current_rendering_method(), "save_error": save_error}
	var file := FileAccess.open(OUTPUT.get_basename() + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(metadata, "\t") + "\n")
	file.close()
	print("CUTLASS_PREVIEW: " + JSON.stringify(metadata))
	viewport.queue_free()
	await process_frame
	await process_frame
	quit(0 if save_error == OK and bool(metadata.transparent_background) else 1)
