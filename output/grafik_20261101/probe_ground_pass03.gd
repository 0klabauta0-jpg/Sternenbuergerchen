extends SceneTree
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const GEO = preload("res://scripts/terrain/frontier_art_geology.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600,900)
	var world := Node3D.new()
	root.add_child(world)
	var profile = PROFILE.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	profile.apply_environment(environment)
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	world.add_child(world_environment)
	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	profile.apply_light(light)
	world.add_child(light)
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(120,100)
	plane.mesh = mesh
	plane.position = Vector3(12,0.0015,6)
	var painted = profile.material_for(profile.surface_color("ground"))
	plane.material_override = painted
	world.add_child(plane)
	var geology = GEO.new()
	world.add_child(geology)
	geology.build(profile,Vector2(12,5))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23
	camera.far = 100
	var target := Vector3(12,0.2,5.6)
	var pitch := deg_to_rad(46.0)
	var yaw := deg_to_rad(24.0)
	camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*18.0
	world.add_child(camera)
	camera.look_at(target,Vector3.UP)
	var flat := painted.duplicate() as ShaderMaterial
	var shader := Shader.new()
	shader.code = painted.shader.code.replace("ALBEDO = pigment * value;","ALBEDO = base_color.rgb;")
	flat.shader = shader
	for mode in ["painted","flat","no_ssao","no_shadows"]:
		plane.material_override = flat if mode=="flat" else painted
		environment.ssao_enabled = mode!="no_ssao"
		light.shadow_enabled = mode!="no_shadows"
		for index in range(30): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/grafik_20261101/pass03_ground_probe_"+mode+".png")
	print("PASS03_GROUND_PROBE_COMPLETE")
	quit()
