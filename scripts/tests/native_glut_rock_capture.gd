extends SceneTree
## Native same-camera scale and material comparison of the two curated rocks.
const PACKED = preload("res://Assets/curated/glut_regional/sandstone_04.glb")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		quit(2)
		return
	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	if gltf.append_from_file(args[0], state) != OK:
		quit(1)
		return
	var sandstone := PACKED.instantiate() as Node3D
	var fbx_study := gltf.generate_scene(state) as Node3D
	root.add_child(sandstone)
	root.add_child(fbx_study)
	sandstone.position.x = -0.64
	fbx_study.position.x = 0.64
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("32313c")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("c7d5ed")
	world.environment.ambient_light_energy = 0.42
	root.add_child(world)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.scale = Vector3(5, 1, 5)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("6f4d3e")
	floor_mesh.material_override = floor_material
	root.add_child(floor_mesh)
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-38, -42, 0)
	light.light_energy = 1.65
	light.shadow_enabled = true
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.05
	camera.look_at_from_position(Vector3(0.8, 2.7, 3.3), Vector3(0, 0.22, 0))
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(args[1])
	print("ROCK_NATIVE_CAPTURE ", error)
	quit(0 if error == OK else 1)
