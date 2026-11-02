extends SceneTree
const PAD = preload("res://scripts/terrain/frontier_outpost_pad.gd")
const BEFORE = preload("res://output/grafik_20261101/probe_pass07_pad_before.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
var captures: Array = []

func _initialize() -> void: call_deferred("run")

func capture(id: String,camera: Camera3D) -> void:
	for index in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var path := "res://output/grafik_20261101/pass07_pad_rails_"+id+".png"
	var error := root.get_texture().get_image().save_png(path)
	captures.append({"id":id,"path":path,"error":error,"camera_transform":str(camera.global_transform),"camera_size":camera.size})

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var profile := PROFILE.new()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	profile.apply_environment(environment.environment)
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	world.add_child(light)
	profile.apply_light(light)
	light.shadow_enabled = true
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30.0,30.0)
	ground.mesh = plane
	ground.position.y = 0.0015
	ground.material_override = profile.material_for(profile.surface_color("ground"))
	world.add_child(ground)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.01
	camera.far = 100.0
	world.add_child(camera)
	camera.current = true
	for spec in [{"id":"east","size":Vector2(5.0,4.4),"side":1.0},{"id":"west","size":Vector2(4.2,4.1),"side":-1.0}]:
		var old := BEFORE.new()
		var current := PAD.new()
		world.add_child(old)
		world.add_child(current)
		old.build(Vector2.ZERO,spec["size"],"01",spec["side"])
		current.build(Vector2.ZERO,spec["size"],"01",spec["side"])
		for view_id in ["join","game"]:
			var side: float = spec["side"]
			var edge: float = spec["size"].x*0.5*side
			if view_id=="join":
				camera.size = 1.45
				camera.position = Vector3(edge+1.55*side,1.05,1.65)
				camera.look_at(Vector3(edge+0.27*side,0.13,0.0))
			else:
				camera.size = 6.4
				camera.position = Vector3(6.0*side,4.7,6.4)
				camera.look_at(Vector3(0.55*side,0.10,0.0))
			current.hide()
			old.show()
			await capture(str(spec["id"])+"_"+view_id+"_before",camera)
			old.hide()
			current.show()
			await capture(str(spec["id"])+"_"+view_id+"_after",camera)
		old.free()
		current.free()
	var report := {"diagnostic_only":true,"renderer":{"driver":RenderingServer.get_current_rendering_driver_name(),"method":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name()},"engine":Engine.get_version_info(),"source_sha256":FileAccess.get_sha256("res://scripts/terrain/frontier_outpost_pad.gd"),"before_source_sha256":FileAccess.get_sha256("res://output/grafik_20261101/probe_pass07_pad_before.gd"),"captures":captures,"scope":"Isolated pad rail endpoint correction; same camera/light/material between each pair; no preview/runtime/campaign acceptance."}
	var file := FileAccess.open("res://output/grafik_20261101/pass07_pad_rails_native.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	world.free()
	await process_frame
	print("FRONTIER_PASS07_PAD_RAILS_NATIVE ",JSON.stringify({"captures":captures.size()}))
	quit()
