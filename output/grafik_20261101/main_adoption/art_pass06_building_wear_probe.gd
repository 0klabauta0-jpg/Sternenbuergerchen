extends SceneTree
## Read-only runtime geometry/look probe; output remains in this task package.
const AFTER = preload("res://scripts/terrain/frontier_closed_buildings.gd")
const BEFORE = preload("res://art/frontier_illustrated_20261101/environment/pass06/buildings/source/frontier_closed_buildings_before.gd")
const PROFILE = preload("res://scripts/terrain/frontier_art_profile.gd")
const OUT := "res://output/grafik_20261101/main_adoption/building_geometry/"
const HAB := AABB(Vector3(-1.2075,0.0,-1.2425),Vector3(2.415,1.05175,2.485))
const HALL := AABB(Vector3(-1.8375,0.0,-1.21625),Vector3(3.675,1.47,2.4325))
var _failed := 0
var _passed := 0
var _diagnostics: Array = []
var _material_diagnostics: Array = []
var _stage: Node3D
var _camera: Camera3D

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool,label: String) -> void:
	if value: _passed += 1
	else:
		_failed += 1
		print("FAIL: ",label)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for hall in [false,true]:
		var shell := AFTER.new()
		root.add_child(shell)
		var original: AABB = HALL if hall else HAB
		shell.build(original,hall)
		await process_frame
		_audit(shell,original,"hall" if hall else "habitat")
		_material_audit(shell,original,hall)
		shell.free()
	await process_frame
	_check(_diagnostics.size()==2,"both nonempty building audits completed")
	var report := {"passed":_passed,"failed":_failed,"engine":Engine.get_version_info(),"builder_sha256":FileAccess.get_sha256("res://scripts/terrain/frontier_closed_buildings.gd"),"diagnostics":_diagnostics,"material_diagnostics":_material_diagnostics,"shader_sha256":FileAccess.get_sha256("res://shaders/terrain/frontier_building_wear.gdshader"),"scope":"Full generated vertices/normals/triangle areas, clockwise normal consistency, closed welded topology per mesh, XZ/height envelopes, hierarchy and conservative component-AABB connectivity. Not a general geometry intersection/zfight oracle.","source_original_bounds":"output/grafik_20261101/pass04_after_capture.json models structures_pass04 at scale0.35"}
	var file := FileAccess.open(OUT+"geometry_raw.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	if OS.get_cmdline_user_args().has("--render") and _failed==0:
		_setup_world()
		await _capture_views()
	print("BUILDING_PASS06_QA ",JSON.stringify(report))
	quit(1 if _failed else 0)

func _point_key(v: Vector3) -> String:
	return "%d,%d,%d" % [roundi(v.x*100000.0),roundi(v.y*100000.0),roundi(v.z*100000.0)]

func _geometry_fingerprint(shell: Node3D) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for item in shell.find_children("*","MeshInstance3D",true,false):
		context.update(var_to_bytes(item.transform))
		for surface in range(item.mesh.get_surface_count()):
			context.update(var_to_bytes(item.mesh.surface_get_arrays(surface)))
	return context.finish().hex_encode()

func _material_audit(shell: Node3D,original: AABB,hall: bool) -> void:
	var id := "hall" if hall else "habitat"
	var baseline := BEFORE.new()
	root.add_child(baseline)
	baseline.build(original,hall)
	var old_signature := _geometry_fingerprint(baseline)
	var signature := _geometry_fingerprint(shell)
	_check(signature==old_signature,id+" all geometry arrays/transforms identical to P05")
	var old_meshes := baseline.find_children("*","MeshInstance3D",true,false)
	var meshes := shell.find_children("*","MeshInstance3D",true,false)
	_check(old_meshes.size()==meshes.size(),id+" mesh count unchanged")
	var shared := {}
	var worn := 0
	var glass := 0
	var emissive := 0
	var standard := 0
	var bound_parameters := true
	var material_sharing := true
	var origins := true
	var exempt_preserved := true
	var role_counts := {}
	for index in range(meshes.size()):
		var mesh := meshes[index] as MeshInstance3D
		var material := mesh.material_override
		var label := String(mesh.get_meta("surface_role_label",""))
		var previous := old_meshes[index].material_override as StandardMaterial3D
		if material is ShaderMaterial:
			worn += 1
			var bounds := mesh.get_aabb()
			bound_parameters = bound_parameters and mesh.get_instance_shader_parameter("wear_part_min")==bounds.position and mesh.get_instance_shader_parameter("wear_part_max")==bounds.end
			origins = origins and material.get_shader_parameter("building_origin")==shell.global_position and is_equal_approx(float(material.get_shader_parameter("building_height")),original.end.y)
			var key := str(material.get_shader_parameter("base_color"))+":"+str(material.get_shader_parameter("role_strength"))
			if shared.has(key): material_sharing = material_sharing and shared[key]==material.get_instance_id()
			else: shared[key] = material.get_instance_id()
			var role := String(mesh.get_meta("material_route",""))
			role_counts[role] = int(role_counts.get(role,0))+1
		else:
			standard += 1
			exempt_preserved = exempt_preserved and material is StandardMaterial3D
		if label in ["FrontWindow","DoorGlass"]:
			glass += 1
			exempt_preserved = exempt_preserved and material is StandardMaterial3D and material.albedo_color==previous.albedo_color and not material.emission_enabled
		if previous.emission_enabled:
			emissive += 1
			exempt_preserved = exempt_preserved and material is StandardMaterial3D and material.emission_enabled and material.emission==previous.emission and material.albedo_color==previous.albedo_color and material.emission_energy_multiplier==previous.emission_energy_multiplier
	_check(worn>meshes.size()/2 and standard>=4,id+" selective wear route and clean exceptions both populated")
	_check(glass>=2 and emissive>=2 and exempt_preserved,id+" original glass/emissive colors and energies preserved")
	_check(bound_parameters,id+" every worn part binds its own actual local AABB")
	_check(origins,id+" building-relative origin/height parameters correct")
	_check(material_sharing and shared.size()<worn,id+" matching color/role surfaces share a material resource")
	_check(role_counts.size()==4,id+" all four distinct wear roles exercised")
	var translated := AFTER.new()
	root.add_child(translated)
	translated.build(AABB(original.position+Vector3(8.3,0.0,6.2),original.size),hall)
	var translation_correct := true
	for item in translated.find_children("*","MeshInstance3D",true,false):
		if item.material_override is ShaderMaterial:
			translation_correct = translation_correct and item.material_override.get_shader_parameter("building_origin")==translated.global_position
	_check(translation_correct,id+" nonzero production-style placement binds correct shader origin")
	_material_diagnostics.append({"id":id,"p05_geometry_sha256":old_signature,"p06_geometry_sha256":signature,"geometry_identical":signature==old_signature,"wear_meshes":worn,"preserved_standard_or_emissive_meshes":standard,"glass_meshes":glass,"emissive_meshes":emissive,"shared_wear_materials":shared.size(),"roles":role_counts,"per_part_bounds_valid":bound_parameters,"exempt_materials_preserved":exempt_preserved,"translated_origin_valid":translation_correct})
	translated.free()
	baseline.free()

func _audit(shell: Node3D,original: AABB,id: String) -> void:
	var meshes := shell.find_children("*","MeshInstance3D",true,false)
	var combined := AABB()
	var first := true
	var triangles := 0
	var finite := true
	var degenerate := 0
	var normal_errors := 0
	var open_edges := 0
	var boxes: Array[AABB] = []
	var names: Array[String] = []
	for item in meshes:
		var mesh := item as MeshInstance3D
		var box: AABB = shell.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
		boxes.append(box)
		names.append(String(mesh.name))
		for s in range(mesh.mesh.get_surface_count()):
			var arrays: Array = mesh.mesh.surface_get_arrays(s)
			var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var ns: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array else PackedInt32Array()
			var order: Array[int] = []
			for index in (indices.size() if not indices.is_empty() else vs.size()): order.append(indices[index] if not indices.is_empty() else index)
			finite = finite and mesh.transform.is_finite() and ns.size()==vs.size()
			var edges := {}
			for v in vs: finite = finite and v.is_finite()
			for n in ns: finite = finite and n.is_finite() and n.length_squared()>0.9
			for offset in range(0,order.size(),3):
				triangles += 1
				var a := vs[order[offset]]
				var b := vs[order[offset+1]]
				var c := vs[order[offset+2]]
				var cross := (c-a).cross(b-a)
				if cross.length_squared()<1e-16: degenerate += 1
				elif cross.normalized().dot(ns[order[offset]])<0.999: normal_errors += 1
				var keys := [_point_key(a),_point_key(b),_point_key(c)]
				for edge in range(3):
					var pair: Array = [keys[edge],keys[(edge+1)%3]]
					pair.sort()
					var key := String(pair[0])+"/"+String(pair[1])
					edges[key] = int(edges.get(key,0))+1
			for count in edges.values():
				if count!=2: open_edges += 1
	# Signs are visual geometry too, though they are excluded from the mesh budget.
	for item in shell.find_children("*","Label3D",true,false):
		var label_box: AABB = shell.global_transform.affine_inverse()*item.global_transform*item.get_aabb()
		combined = combined.merge(label_box)
	var connected := {0:true}
	for pass_index in meshes.size():
		for index in meshes.size():
			if connected.has(index): continue
			for other in connected.keys():
				if boxes[index].grow(0.001).intersects(boxes[other]):
					connected[index] = true
					break
	var detached: Array = []
	for index in meshes.size():
		if not connected.has(index): detached.append(names[index])
	_check(finite and triangles>0,id+" finite vertices and normals")
	_check(degenerate==0,id+" nondegenerate triangles")
	_check(normal_errors==0,id+" outward clockwise triangle normals")
	_check(open_edges==0,id+" each mesh has closed welded topology")
	_check(combined.position.x>=-original.size.x*0.5-0.22 and combined.end.x<=original.size.x*0.5+0.22 and combined.position.z>=-original.size.z*0.5-0.22 and combined.end.z<=original.size.z*0.5+0.22,id+" XZ inside original+0.22m")
	_check(combined.end.y<=original.end.y+0.2001 and combined.position.y>=0.0,id+" Y within original height+0.20m and above ground")
	_check(detached.is_empty(),id+" conservative assembly AABBs are connected")
	_check(shell.find_children("*","Light3D",true,false).is_empty() and shell.find_children("*","CollisionObject3D",true,false).is_empty() and shell.find_children("*","NavigationRegion3D",true,false).is_empty(),id+" display-only hierarchy")
	var door := shell.get_node("DoorFrame") as MeshInstance3D
	var door_box := door.transform*door.get_aabb()
	var clear := true
	for window in meshes:
		if String(window.name).begins_with("FrontWindowFrame"):
			var window_box: AABB = window.transform*window.get_aabb()
			clear = clear and (window_box.end.x<door_box.position.x or window_box.position.x>door_box.end.x)
	_check(clear,id+" window frames clear complete DoorFrame")
	shell.visible = false
	_check(not shell.visible,id+" all shell parts follow one visibility root")
	_diagnostics.append({"id":id,"mesh_count":meshes.size(),"triangles":triangles,"finite":finite,"degenerate_triangles":degenerate,"clockwise_normal_errors":normal_errors,"nonpaired_welded_edges":open_edges,"conservative_detached_candidates":detached,"combined_bounds_local":str(combined),"bounds_min":[combined.position.x,combined.position.y,combined.position.z],"bounds_max":[combined.end.x,combined.end.y,combined.end.z],"xz_extensions":[-original.size.x*0.5-combined.position.x,combined.end.x-original.size.x*0.5,-original.size.z*0.5-combined.position.z,combined.end.z-original.size.z*0.5],"height_extension":combined.end.y-original.end.y,"includes_label_bounds":true,"original_bounds_local":str(original),"window_frames_clear":clear,"roof_parts":names.filter(func(n: String)->bool:return "Roof" in n or "Monitor" in n or "LifeSupport" in n)})

func _setup_world() -> void:
	root.size = Vector2i(1280,900)
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	var profile := PROFILE.new()
	profile.apply_environment(environment.environment)
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	profile.apply_light(light)
	light.shadow_enabled = true
	world.add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100,100)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("a65c40")
	ground_material.roughness = 0.95
	ground.material_override = ground_material
	ground.position.y = -0.001
	world.add_child(ground)
	_stage = Node3D.new()
	world.add_child(_stage)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	world.add_child(_camera)

func _clear_stage() -> void:
	for child in _stage.get_children(): child.free()

func _capture_views() -> void:
	var metadata: Array = []
	for revision in ["before","wear_disabled","after"]:
		for id in ["habitat","hall","ensemble"]:
			_clear_stage()
			for hall in ([false,true] if id=="ensemble" else [id=="hall"]):
				var shell := Node3D.new()
				shell.set_script(BEFORE if revision=="before" else AFTER)
				_stage.add_child(shell)
				var placed_bounds: AABB = HALL if hall else HAB
				if id=="ensemble": placed_bounds.position.x += 2.15 if hall else -2.15
				shell.call("build",placed_bounds,hall)
				if revision=="wear_disabled":
					for mesh in shell.find_children("*","MeshInstance3D",true,false):
						if mesh.material_override is ShaderMaterial: mesh.material_override.set_shader_parameter("wear_strength",0.0)
			for view in (["front","rear"] if id!="ensemble" else ["game"]):
				var direction := Vector3(1.2,1.30,1.7) if view!="rear" else Vector3(-1.2,1.30,-1.7)
				var target := Vector3(0.0,0.55 if id=="habitat" else 0.75,0.0)
				_camera.size = 9.5 if id=="ensemble" else (4.0 if id=="habitat" else 4.9)
				_camera.position = target+direction.normalized()*14
				_camera.look_at(target)
				for frame in range(8): await process_frame
				await RenderingServer.frame_post_draw
				var file: String = OUT+"native_"+revision+"_"+id+"_"+view+".png"
				var err := root.get_texture().get_image().save_png(file)
				_check(err==OK,"capture "+file)
				metadata.append({"revision":revision,"building":id,"view":view,"path":file,"camera":str(_camera.transform),"size":_camera.size,"resolution":str(root.size),"light":"unchanged FrontierArtProfile","renderer":RenderingServer.get_current_rendering_method()+"/"+RenderingServer.get_current_rendering_driver_name()})
	var out := FileAccess.open(OUT+"native_views.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(metadata,"  "))
	out.close()
