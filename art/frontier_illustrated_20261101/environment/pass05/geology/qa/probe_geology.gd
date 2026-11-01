extends SceneTree
## Isolated visual comparison: no map, ships, editor import or gameplay mutation.
const GEO = preload("res://scripts/terrain/frontier_art_geology.gd")
const BEFORE = preload("res://art/frontier_illustrated_20261101/environment/pass05/geology/source/frontier_art_geology_pass04.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const OUTPUT := "res://art/frontier_illustrated_20261101/environment/pass05/geology/qa/"

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
	var before = BEFORE.new()
	var geology = GEO.new()
	stage.add_child(before)
	stage.add_child(geology)
	before.build(profile,Vector2(12,5))
	geology.build(profile,Vector2(12,5))
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.far = 100.0
	stage.add_child(camera)
	camera.current = true
	var captures: Array = []
	var error := OK
	for view in [{"id":"landscape","target":Vector3(12,0.2,5.6),"size":23.0,"yaw":24.0,"pitch":46.0},{"id":"wall_detail","target":Vector3(12.8,2.2,-3.8),"size":9.8,"yaw":24.0,"pitch":34.0},{"id":"near_detail","target":Vector3(2.35,1.0,7.0),"size":5.2,"yaw":24.0,"pitch":38.0},{"id":"rear_detail","target":Vector3(12.8,2.2,-3.8),"size":9.8,"yaw":204.0,"pitch":34.0}]:
		camera.size = float(view["size"])
		var target: Vector3 = view["target"]
		var pitch := deg_to_rad(float(view["pitch"]))
		var yaw := deg_to_rad(float(view["yaw"]))
		camera.position = target+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*18.0
		camera.look_at(target,Vector3.UP)
		for revision in ["before","after"]:
			before.visible = revision=="before"
			geology.visible = revision=="after"
			for index in range(12): await process_frame
			await RenderingServer.frame_post_draw
			var path: String = OUTPUT+String(view["id"])+"_"+revision+".png"
			var result := root.get_texture().get_image().save_png(path)
			error = maxi(error,result)
			captures.append({"view":view["id"],"revision":revision,"path":path,"camera_transform":str(camera.global_transform),"camera_size":camera.size,"error":result})
	var result := {"pass":error==OK,"engine":Engine.get_version_info(),"renderer":RenderingServer.get_current_rendering_method()+" / "+RenderingServer.get_current_rendering_driver_name(),"isolated_geology_only":true,"captures":captures,"light_transform":str(light.global_transform),"light_energy":light.light_energy,"light_color":str(light.light_color),"no_gpu_exclusivity_claim":true,"source_sha256":FileAccess.get_sha256("res://scripts/terrain/frontier_art_geology.gd"),"ground_shader_sha256":FileAccess.get_sha256("res://shaders/terrain/frontier_ground.gdshader"),"profile_sha256":FileAccess.get_sha256("res://scripts/terrain/frontier_art_profile.gd")}
	var file := FileAccess.open(OUTPUT+"native_probe.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	stage.free()
	await process_frame
	print("FRONTIER_PASS05_GEOLOGY_PREVIEW ",JSON.stringify(result))
	quit(0 if error==OK else 1)
