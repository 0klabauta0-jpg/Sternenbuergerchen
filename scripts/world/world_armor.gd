extends RefCounted
## Three simple armor pieces follow the existing Kenney rig, without replacing it.
const Geo = preload("res://scripts/world/world_geometry.gd")

static func attach(model: Node3D, accent: Color = Color("76aaa4")) -> Array[Node3D]:
	var parts: Array[Node3D]=[]
	var rigs:=model.find_children("*","Skeleton3D",true,false)
	if rigs.is_empty(): return parts
	var rig:=rigs[0] as Skeleton3D
	for spec in [{"bone":"Chest","size":Vector3(0.58,0.46,0.32),"offset":Vector3(0,0.07,0)}, {"bone":"LeftArm","size":Vector3(0.25,0.25,0.31),"offset":Vector3(0,-0.01,0)}, {"bone":"RightArm","size":Vector3(0.25,0.25,0.31),"offset":Vector3(0,-0.01,0)}]:
		var index:=rig.find_bone(str(spec.bone))
		if index<0: continue
		var socket:=BoneAttachment3D.new()
		socket.name="Armor_"+str(spec.bone)
		socket.bone_name=str(spec.bone)
		rig.add_child(socket)
		var frame:=Node3D.new()
		socket.add_child(frame)
		# Author in meter-sized model space, then remove the initial bone rotation.
		# Future animation poses move each piece through the real bone attachment.
		var model_to_rig:=rig.global_transform.affine_inverse()*model.global_transform
		var pose:=rig.get_bone_global_pose(index)
		var bone_in_model:=model.global_transform.affine_inverse()*rig.global_transform*pose.origin
		frame.transform=pose.affine_inverse()*model_to_rig*Transform3D(Basis.IDENTITY,bone_in_model+(spec.offset as Vector3))
		Geo.box(frame,Vector3.ZERO,spec.size,Color("d7e1dc"),0.15)
		var size: Vector3=spec.size
		Geo.box(frame,Vector3(0,0,size.z*0.52),Vector3(size.x*0.78,size.y*0.72,0.035),accent,0.1)
		Geo.box(frame,Vector3(0,0,-size.z*0.52),Vector3(size.x*0.78,size.y*0.60,0.035),Color("536e70"))
		parts.append(socket)
	return parts

static func show(parts: Array, equipped: bool) -> void:
	for part: Node3D in parts:
		part.visible=equipped
