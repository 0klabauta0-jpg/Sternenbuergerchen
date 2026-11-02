extends SceneTree
## Read-only native diagnosis. Restores a private P06 dressing snapshot in memory.
const PREVIEW = preload("res://scenes/tests/frontier_art_preview.tscn")
const DRESSING = preload("res://output/grafik_20261101/probe_pass07_shadow_dressing_snapshot.gd")
const PREFIX := "res://output/grafik_20261101/pass07_shadow_"
var preview
var view
var dressing: Node3D
var environment: Environment
var ground: MeshInstance3D
var ground_shadow: int
var lights: Array = []
var light_shadows: Array = []
var meshes: Array = []
var mesh_shadows: Array = []
var mesh_visibility: Array = []
var path_meshes: Array = []
var original_path_meshes: Array = []
var report := {"diagnostic_only":true,"captures":[],"layers":[]}

func _initialize() -> void:
	call_deferred("run")

func capture(id: String) -> void:
	view.call("_request_viewport_redraw",true,60000)
	for index in range(12): await process_frame
	await RenderingServer.frame_post_draw
	var camera: Camera3D = view.get_node("ViewportContainer/SubViewport/WorldRoot/Camera3D")
	var path := PREFIX+id+".png"
	var error := root.get_texture().get_image().save_png(path)
	report["captures"].append({"id":id,"path":path,"error":error,"camera_transform":str(camera.global_transform),"camera_size":camera.size,"ssao":environment.ssao_enabled,"ground_cast_shadow":ground.cast_shadow})

func restore() -> void:
	environment.ssao_enabled = true
	ground.cast_shadow = ground_shadow
	for index in range(meshes.size()):
		meshes[index].cast_shadow = mesh_shadows[index]
		meshes[index].visible = mesh_visibility[index]
	for index in range(lights.size()): lights[index].shadow_enabled = light_shadows[index]
	for index in range(path_meshes.size()): path_meshes[index].mesh = original_path_meshes[index]

func replace_path_normals(mode: String) -> void:
	for path_index in range(path_meshes.size()):
		var arrays: Array = original_path_meshes[path_index].surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if mode=="flat_generated":
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface.set_smooth_group(-1)
			for vertex in vertices: surface.add_vertex(vertex)
			surface.generate_normals()
			path_meshes[path_index].mesh = surface.commit()
		else:
			if mode=="up_and_winding":
				for index in range(0,vertices.size(),3):
					if (vertices[index+2]-vertices[index]).cross(vertices[index+1]-vertices[index]).y<0.0:
						var swap := vertices[index+1]
						vertices[index+1] = vertices[index+2]
						vertices[index+2] = swap
				arrays[Mesh.ARRAY_VERTEX] = vertices
			var normals := PackedVector3Array()
			normals.resize(vertices.size())
			normals.fill(Vector3.UP)
			arrays[Mesh.ARRAY_NORMAL] = normals
			var mesh := ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			path_meshes[path_index].mesh = mesh

func path_height(mesh: MeshInstance3D) -> float:
	var bounds := mesh.get_aabb()
	if mesh.mesh is ArrayMesh and bounds.size.y<0.00001:
		for height in [0.007,0.010,0.012]:
			if is_equal_approx(bounds.position.y,height): return height
	return -1.0

func run() -> void:
	preview = PREVIEW.instantiate()
	root.add_child(preview)
	for index in range(2): await process_frame
	preview.set_process(false)
	preview.get("_sim").set_physics_process(false)
	view = preview.get("_view")
	view.set_process(false)
	view.get_node("ViewportContainer/SubViewport").render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for entry in preview.get("_crew"):
		if entry["player"]: entry["player"].pause()
	var stage: Node3D = preview.get("_stage")
	ground = stage.get_node("DistantGroundVisualOnly")
	ground_shadow = ground.cast_shadow
	stage.get_node("FrontierWorkingGround").free()
	dressing = DRESSING.new()
	dressing.name = "P06DressingDiagnosticOnly"
	stage.add_child(dressing)
	dressing.build(preview.get("_profile"))
	preview.call("_set_buildings_closed",false)
	preview.call("_camera_view","crew")
	var world: Node3D = view.get_node("ViewportContainer/SubViewport/WorldRoot")
	environment = world.find_children("*","WorldEnvironment",true,false)[0].environment
	lights = world.find_children("*","DirectionalLight3D",true,false)
	for light in lights: light_shadows.append(light.shadow_enabled)
	meshes = dressing.find_children("*","MeshInstance3D",true,false)
	for mesh in meshes:
		mesh_shadows.append(mesh.cast_shadow)
		mesh_visibility.append(mesh.visible)
		if path_height(mesh)>0.0:
			path_meshes.append(mesh)
			original_path_meshes.append(mesh.mesh)
			var arrays: Array = mesh.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var min_y := INF
			var max_y := -INF
			var min_ny := INF
			var max_ny := -INF
			var up := 0
			var down := 0
			var down_bounds := AABB()
			var first_down := true
			var finite := true
			var inverted_triangles := 0
			var tiny_triangles := 0
			var inverted_area := 0.0
			var inverted_details: Array = []
			for vertex in vertices:
				min_y = minf(min_y,vertex.y)
				max_y = maxf(max_y,vertex.y)
				finite = finite and vertex.is_finite()
			for index in range(normals.size()):
				var normal := normals[index]
				min_ny = minf(min_ny,normal.y)
				max_ny = maxf(max_ny,normal.y)
				finite = finite and normal.is_finite()
				if normal.y>0.95: up += 1
				if normal.y< -0.95:
					down += 1
					down_bounds = AABB(vertices[index],Vector3.ZERO) if first_down else down_bounds.expand(vertices[index])
					first_down = false
			for index in range(0,vertices.size(),3):
				var a := vertices[index]
				var b := vertices[index+1]
				var c := vertices[index+2]
				var signed_twice_area := (c-a).cross(b-a).y
				if absf(signed_twice_area)<0.00000001: tiny_triangles += 1
				if signed_twice_area< -0.00000001:
					inverted_triangles += 1
					inverted_area += absf(signed_twice_area)*0.5
					inverted_details.append({"a":str(a),"b":str(b),"c":str(c),"area":absf(signed_twice_area)*0.5})
			report["layers"].append({"name":str(mesh.name),"vertices":vertices.size(),"min_y":min_y,"max_y":max_y,"min_normal_y":min_ny,"max_normal_y":max_ny,"up_vertices":up,"down_vertices":down,"down_bounds":str(down_bounds),"finite":finite,"cast_shadow":mesh.cast_shadow,"inverted_triangles":inverted_triangles,"tiny_triangles":tiny_triangles,"inverted_area":inverted_area,"inverted_details":inverted_details})
	report["source_sha256"] = FileAccess.get_sha256("res://output/grafik_20261101/probe_pass07_shadow_dressing_snapshot.gd")
	report["engine"] = Engine.get_version_info()
	report["renderer"] = {"method":RenderingServer.get_current_rendering_method(),"driver":RenderingServer.get_current_rendering_driver_name(),"adapter":RenderingServer.get_video_adapter_name()}
	report["environment_initial"] = {"ssao":environment.ssao_enabled,"ssao_radius":environment.ssao_radius,"ssao_intensity":environment.ssao_intensity}
	await capture("baseline")
	environment.ssao_enabled = false
	await capture("no_ssao")
	restore()
	for light in lights: light.shadow_enabled = false
	await capture("no_global_shadows")
	environment.ssao_enabled = false
	await capture("no_ssao_no_global_shadows")
	restore()
	for mesh in meshes:
		if path_height(mesh)>0.0: mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_paving_cast")
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_paving_or_ground_cast")
	restore()
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_ground_cast")
	restore()
	for mesh in meshes: mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_dressing_cast")
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_dressing_or_ground_cast")
	restore()
	for mesh in meshes:
		if String(mesh.name).begins_with("PathEdgeGuide") or String(mesh.name).begins_with("ServiceLaneGuide"):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	await capture("no_marking_cast")
	for height in [0.007,0.010,0.012]:
		restore()
		for mesh in meshes:
			if is_equal_approx(path_height(mesh),height): mesh.visible = false
		await capture("hide_layer_"+str(roundi(height*1000.0)))
	for height in [0.007,0.010,0.012]:
		restore()
		for mesh in meshes:
			if is_equal_approx(path_height(mesh),height): mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		await capture("no_cast_layer_"+str(roundi(height*1000.0)))
	for mode in ["up_only","flat_generated","up_and_winding"]:
		restore()
		replace_path_normals(mode)
		await capture(mode)
	restore()
	var file := FileAccess.open(PREFIX+"report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	preview.free()
	await process_frame
	print("FRONTIER_PASS07_SHADOW_DIAG ",JSON.stringify({"captures":report["captures"].size(),"layers":report["layers"]}))
	quit()
