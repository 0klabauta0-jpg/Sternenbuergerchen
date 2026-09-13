extends RefCounted
## Rig-bound visible equipment; item ownership and bonuses remain in the core.
const Geo = preload("res://scripts/world/world_geometry.gd")

static func present(unit: Node3D, equipment: Dictionary) -> void:
	if not unit.has_meta("visible_equipment"):_attach(unit)
	var parts: Dictionary=unit.get_meta("visible_equipment",{})
	if parts.is_empty():return
	(parts.backpack as Node3D).visible=not str(equipment.get("backpack","")).is_empty()
	var tool:=str(equipment.get("tool",""))
	(parts.tool as Node3D).visible=not tool.is_empty()
	var color:=Color("80948f")
	if tool=="medgun":color=Color("d695ad")
	elif str(equipment.get("attachment",""))=="mining_attachment":color=Color("72c9cc")
	elif str(equipment.get("attachment",""))=="salvage_attachment":color=Color("d8ad70")
	var tip:=parts.tip as MeshInstance3D
	var material:=tip.material_override as StandardMaterial3D
	material.albedo_color=color

static func _attach(unit: Node3D) -> void:
	unit.set_meta("visible_equipment",{})
	var model:=unit.get_node_or_null("Model") as Node3D
	if model==null:return
	var rigs:=model.find_children("*","Skeleton3D",true,false)
	if rigs.is_empty():return
	var rig:=rigs[0] as Skeleton3D
	var backpack:=_socket(model,rig,"Chest",Vector3(0,0.08,-0.30),"Backpack")
	var tool:=_socket(model,rig,"RightHand",Vector3(0,0,0.10),"Tool")
	if backpack==null or tool==null:return
	Geo.box(backpack,Vector3.ZERO,Vector3(0.46,0.52,0.26),Color("728c87"))
	Geo.box(backpack,Vector3(0,0,-0.145),Vector3(0.35,0.39,0.035),Color("d5ddd1"))
	for x in [-0.14,0.14]:Geo.box(backpack,Vector3(x,0,-0.17),Vector3(0.035,0.45,0.025),Color("455e67"))
	Geo.box(tool,Vector3(0,-0.02,0.06),Vector3(0.13,0.15,0.33),Color("c5d4cc"))
	Geo.box(tool,Vector3(0,-0.10,0),Vector3(0.09,0.17,0.10),Color("455b64"))
	var tip:=Geo.box(tool,Vector3(0,-0.02,0.25),Vector3(0.15,0.16,0.11),Color("79c6c2"))
	unit.set_meta("visible_equipment",{"backpack":backpack,"tool":tool,"tip":tip})

static func _socket(model: Node3D, rig: Skeleton3D, bone: String, offset: Vector3, name: String) -> Node3D:
	var index:=rig.find_bone(bone)
	if index<0:return null
	var socket:=BoneAttachment3D.new();socket.name="Equipment_"+name;socket.bone_name=bone;rig.add_child(socket)
	var frame:=Node3D.new();socket.add_child(frame)
	var model_to_rig:=rig.global_transform.affine_inverse()*model.global_transform
	var pose:=rig.get_bone_global_pose(index)
	var bone_in_model:=model.global_transform.affine_inverse()*rig.global_transform*pose.origin
	frame.transform=pose.affine_inverse()*model_to_rig*Transform3D(Basis.IDENTITY,bone_in_model+offset)
	return frame
