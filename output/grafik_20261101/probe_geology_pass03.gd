extends SceneTree
## Isolated native look probe; no game data, imports or missing building assets.
const GEO = preload("res://scripts/terrain/frontier_art_geology.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1600,900)
	var stage := Node3D.new()
	root.add_child(stage)
	var profile = PROFILE.new()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.adjustment_enabled = true
	profile.apply_environment(environment.environment)
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	profile.apply_light(light)
	stage.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120,100)
	ground.mesh = plane
	ground.position = Vector3(12,0.0015,6)
	ground.material_override = profile.material_for(profile.surface_color("ground"))
	stage.add_child(ground)
	var geology = GEO.new()
	stage.add_child(geology)
	geology.build(profile,Vector2(12,5))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.0
	camera.far = 100.0
	stage.add_child(camera)
	var pitch := deg_to_rad(46.0)
	var yaw := deg_to_rad(24.0)
	var target := Vector3(12,0.2,5.6)
	camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*18.0
	camera.look_at(target,Vector3.UP)
	camera.current = true
	for index in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	var output := "res://output/grafik_20261101/pass03_geology_probe.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.get_base_dir()))
	var error := root.get_texture().get_image().save_png(output)
	print("FRONTIER_PASS03_GEOLOGY_PREVIEW ",JSON.stringify({"error":error,"path":output,"renderer":RenderingServer.get_current_rendering_method()+" / "+RenderingServer.get_current_rendering_driver_name(),"isolated_geology_only":true}))
	quit(0 if error==OK else 1)
