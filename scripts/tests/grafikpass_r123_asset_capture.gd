extends SceneTree
## Import audit and isolated studio view of the supplied kit; needs real rendering.
const MANIFEST := "res://Assets/curated/windbruch_kit_20261114/kit_manifest.json"
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1600, 1000)
	root.content_scale_size = root.size
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.22, 0.24, 0.28)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(0.8, 0.85, 1.0)
	environment.environment.ambient_light_energy = 0.65
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	stage.add_child(light)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 32)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(11, -0.025, 9)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.4, 0.43, 0.46)
	finish.roughness = 1.0
	floor_mesh.material_override = finish
	stage.add_child(floor_mesh)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 33.0
	camera.position = Vector3(30, 30, 39)
	camera.look_at(Vector3(11, 0, 9))
	camera.current = true
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var rows: Array = []
	for id: String in catalog.assets:
		var path: String = MANIFEST.get_base_dir() + "/" + String(catalog.assets[id].file)
		var scene: PackedScene = load(path)
		if scene == null:
			failed += 1
			continue
		var model: Node3D = scene.instantiate()
		stage.add_child(model)
		var bounds := AABB()
		var found := false
		var mesh_count := 0
		for mesh: Node in model.find_children("*", "MeshInstance3D", true, false):
			var local: AABB = (model.global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
			bounds = bounds.merge(local) if found else local
			found = true
			mesh_count += 1
		if not found or not bounds.position.is_finite() or not bounds.size.is_finite() or bounds.size.length_squared() <= 0.0:
			failed += 1
		rows.append({"id":id,"path":path,"meshes":mesh_count,"bounds_position":str(bounds.position),"bounds_size":str(bounds.size)})
		var index: int = rows.size() - 1
		model.position = Vector3((index % 4) * 7.5, 0, (index / 4) * 6.0)
	if rows.size() != 13: failed += 1
	for frame in range(16): await process_frame
	await RenderingServer.frame_post_draw
	var output: String = OS.get_environment("CAP_DIR")
	if root.get_texture().get_image().save_png(output.path_join("kit_studio.png")) != OK: failed += 1
	var report := FileAccess.open(output.path_join("kit_import.json"), FileAccess.WRITE)
	if report == null: failed += 1
	else:
		report.store_string(JSON.stringify({"engine":Engine.get_version_info(),"models":rows,"failed":failed}, "\t"))
		report.close()
	stage.free()
	print("GRAFIKPASS_R123_ASSETS imported=", rows.size(), " failed=", failed)
	quit(0 if failed == 0 else 1)
