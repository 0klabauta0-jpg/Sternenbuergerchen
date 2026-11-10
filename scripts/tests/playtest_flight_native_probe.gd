extends SceneTree
## Native fixed-camera fixture; no gameplay truth. Before capture prerequisite:
## git show HEAD:scripts/terrain/mission_flight_visual.gd > output/flight_polish_20261110/before_flight_visual.gd
## Renderer used for reviewed capture: --rendering-method gl_compatibility.
## Omit baseline file for after-only capture.
const MODEL = preload("res://Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb")
const FLIGHT = preload("res://scripts/terrain/mission_flight_visual.gd")
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1100, 760)
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	var sky := Environment.new()
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.10,0.13,0.17)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.76,0.83,0.92)
	sky.ambient_light_energy = 0.65
	env.environment = sky
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	sun.light_energy = 1.4
	world.add_child(sun)
	var pad := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(8,0.12,9)
	pad.mesh = box
	pad.position.y = -0.1
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.24,0.30,0.33)
	pad.material_override = material
	world.add_child(pad)
	var craft := Node3D.new()
	craft.scale = Vector3.ONE * 0.22
	world.add_child(craft)
	craft.add_child(MODEL.instantiate())
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	camera.position = Vector3(10,8,-13)
	world.add_child(camera)
	camera.look_at(Vector3(0,1.8,-0.5))
	camera.current = true
	DirAccess.make_dir_recursive_absolute("res://output/flight_polish_20261110")
	var versions: Array[String] = ["after"]
	if FileAccess.file_exists("res://output/flight_polish_20261110/before_flight_visual.gd"):
		versions.push_front("before")
	for version in versions:
		var script: GDScript = load("res://output/flight_polish_20261110/before_flight_visual.gd") if version == "before" else FLIGHT
		var visual: Node3D = script.new()
		craft.add_child(visual)
		visual.configure_cutlass_ref03()
		for pose in ["landing","hover","cruise"]:
			craft.position = Vector3(0,0.03 if pose=="landing" else (1.3 if pose=="hover" else 3.0),0)
			visual.set_flight_phase("landed" if pose=="landing" else "inbound")
			visual.advance_visual(0.1)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://output/flight_polish_20261110/%s_%s.png" % [version,pose])
		craft.remove_child(visual)
		visual.free()
	print("FLIGHT_NATIVE_CAPTURE_COMPLETE")
	quit()
