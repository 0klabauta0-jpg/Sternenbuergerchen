extends SceneTree
const ARMOR=preload("res://output/native_glut_maps/personnel_armor_visual_r07.gd")
var passed:=0
var failed:=0
func _init():call_deferred("run")
func check(ok:bool,label:String):
	if ok:passed+=1
	else:failed+=1;push_error(label)
func run():
	for invalid in [null,[],{}, {"revision":"kenney_body_r07","rows":[]},{"revision":"kenney_body_r07","rows":[[0,1,1],[0,1,1]]}]:check(not ARMOR._valid_body_profile(invalid),"Invalid body profiles rejected")
	var unsupported:=Node3D.new();var missing:=Skeleton3D.new();unsupported.add_child(missing);root.add_child(unsupported)
	var rejected:=ARMOR.apply_to_model(unsupported,"light")
	check(not rejected.ok and String(rejected.reason).begins_with("armor_bone_missing"),"Missing bones retain existing graceful armor error")
	check(not unsupported.has_meta("body_shape_revision"),"Unsupported skeleton never marked as converted")
	unsupported.free()
	var evidence:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/armor_kenney_r07_20261111/body_vertices.json"))
	var before:Array[Vector3]=[];var after:Array[Vector3]=[]
	for v:Array in evidence.before:before.append(Vector3(v[0],v[1],v[2])/float(evidence.width))
	for v:Array in evidence.after:after.append(Vector3(v[0],v[1],v[2])/float(evidence.width))
	var view=load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var unit=load("res://scripts/npc/test_unit.gd").new();unit.unit_id="r07_body_test";unit.armor_id="suit"
	var report:Array=[]
	for rig in ["base","mission"]:
		var model:Node3D=load("res://Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb").instantiate() if rig=="base" else view.call("_create_unit_proxy",unit)
		root.add_child(model)
		var sk:Skeleton3D=model.find_children("*","Skeleton3D",true,false)[0]
		var rests:Array=[]
		for bone in sk.get_bone_count():rests.append(sk.get_bone_global_rest(bone))
		var hips:=sk.get_bone_global_rest(sk.find_bone("Hips")).origin
		var up:Vector3=(sk.get_bone_global_rest(sk.find_bone("Head")).origin-hips).normalized()
		var l:=sk.get_bone_global_rest(sk.find_bone("LeftArm")).origin;var r:=sk.get_bone_global_rest(sk.find_bone("RightArm")).origin
		var x:Vector3=(l-r).normalized();x=(x-up*x.dot(up)).normalized()
		var axes:=Basis(x,up,x.cross(up).normalized());var width:=l.distance_to(r)
		var body:MeshInstance3D
		for candidate:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			if String(candidate.name).to_lower().contains("character"):body=candidate;break
		var original:Mesh=body.get_meta("armor_source_body_mesh",body.get_meta("r06_source_body_mesh",body.get_meta("armor_original_body_mesh",body.mesh)))
		var original_arrays:Array=original.surface_get_arrays(0).duplicate(true)
		var legacy:Array=[]
		for helmet:Node3D in model.find_children("HelmetVisual_*","Node3D",true,false):legacy.append([helmet,helmet.transform])
		ARMOR.apply_to_model(model,"suit")
		var derived:=body.mesh
		check(derived!=original,"Derived body uses its own immutable Mesh")
		check(body.get_meta("r07_source_body_mesh")==original,"Original source mesh retained")
		check(body.get_meta("armor_source_body_mesh")==original,"Stable generic original source retained across revisions")
		for item:Array in legacy:
			var helmet:Node3D=item[0];var source:Transform3D=item[1]
			check(helmet.get_meta("armor_source_transform")==source,"Space helmet immutable source transform retained")
			check(absf(helmet.transform.basis.determinant()/source.basis.determinant()-.95*.92*.95)<.0001,"Space helmet follows intended head scale")
			item.append(helmet.transform)
		check(String(model.get_meta("body_shape_revision"))=="kenney_body_r07","Body revision recorded")
		var bone:=body.skin.get_bind_bone(0)
		if not String(body.skin.get_bind_name(0)).is_empty():bone=sk.find_bone(body.skin.get_bind_name(0))
		var canonical:=Transform3D(axes.inverse(),-(axes.inverse()*hips))*sk.get_bone_global_rest(bone)*body.skin.get_bind_pose(0)
		var envelope:=AABB();var reference:=AABB(before[0],Vector3.ZERO);var first:=true
		for point in before:reference=reference.expand(point)
		for point:Vector3 in original_arrays[Mesh.ARRAY_VERTEX]:
			var p:=canonical*point/width
			envelope=AABB(p,Vector3.ZERO) if first else envelope.expand(p);first=false
		var alignment:=reference.get_center()-envelope.get_center()
		canonical.origin+=alignment*width
		var max_source:=0.0;var max_after:=0.0;var changed:=0;var max_head:=0.0;var max_extremity:=0.0
		var da:Array=derived.surface_get_arrays(0)
		for index in original_arrays[Mesh.ARRAY_VERTEX].size():
			var p:Vector3=(canonical*original_arrays[Mesh.ARRAY_VERTEX][index])/width
			var q:Vector3=(canonical*da[Mesh.ARRAY_VERTEX][index])/width
			var closest:=0;var distance:=INF
			for j in before.size():
				var d:=p.distance_squared_to(before[j])
				if d<distance:distance=d;closest=j
			max_source=maxf(max_source,sqrt(distance));max_after=maxf(max_after,q.distance_to(after[closest]))
			if p.distance_to(q)>.000001:changed+=1
			if p.y/((l-hips).dot(up)/width)>1.28:max_head=maxf(max_head,p.distance_to(q))
			for influence in range(4):
				var bind:int=original_arrays[Mesh.ARRAY_BONES][index*4+influence]
				if original_arrays[Mesh.ARRAY_WEIGHTS][index*4+influence]<.45:continue
				var name:=String(body.skin.get_bind_name(bind))
				if name.is_empty():name=sk.get_bone_name(body.skin.get_bind_bone(bind))
				for part in ["Hand","Foot","Toes","Thumb","Index","Middle","Ring","Pinky"]:
					if name.contains(part):max_extremity=maxf(max_extremity,p.distance_to(q))
		check(max_source<.001,"Original body matches Blender canonical source")
		check(max_after<.001,"Native body positions match actual Blender-derived vertices")
		check(changed>200,"Visible body contour changes are real vertices")
		check(max_head>.01 and max_head<.20,"Intentional modest head contour change matches Blender")
		check(max_extremity<.00001,"Hands fingers feet and toes preserve original positions")
		for slot in [Mesh.ARRAY_TEX_UV,Mesh.ARRAY_COLOR,Mesh.ARRAY_INDEX,Mesh.ARRAY_BONES,Mesh.ARRAY_WEIGHTS]:check(da[slot]==original_arrays[slot],"Body UV/color/topology/skin preserved")
		for armor in ["heavy","medium","suit","light","suit"]:
			ARMOR.apply_to_model(model,armor)
			check(body.get_meta("armor_original_body_mesh")==derived,"Body cache stable across equipment change")
			if armor!="heavy":check(body.mesh==derived,"New body persists when armor removed / face restored")
			for item:Array in legacy:check(item[0].transform==item[2],"Space helmet scale never accumulates through equipment changes")
		check(original.surface_get_arrays(0)==original_arrays,"Original mesh arrays never mutated")
		for j in sk.get_bone_count():check(sk.get_bone_global_rest(j)==rests[j],"Existing skeleton rest unchanged")
		report.append({"rig":rig,"vertices":original_arrays[Mesh.ARRAY_VERTEX].size(),"changed_exported_vertices":changed,"original_bind_origin_alignment_in_shoulder_widths":str(alignment),"blender_original_max_error_in_shoulder_widths":max_source,"blender_derived_max_error_in_shoulder_widths":max_after,"head_max_displacement":max_head,"hands_feet_max_displacement":max_extremity})
		model.free()
	view.free();unit.free()
	FileAccess.open("res://art/armor_kenney_r07_20261111/body_projection_qa.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failed":failed,"rigs":report},"\t"))
	print("R07_BODY_PROJECTION ",passed," passed, ",failed," failed ",JSON.stringify(report));quit(0 if failed==0 else 1)
