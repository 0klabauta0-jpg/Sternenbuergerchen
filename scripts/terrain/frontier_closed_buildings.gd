extends Node3D
## Optional authored exterior shells over the cutaway GLBs. Display only.
var _materials: Dictionary = {}

func build(bounds: AABB, hall: bool) -> void:
	position = Vector3(bounds.get_center().x,0.0,bounds.get_center().z)
	var width := bounds.size.x+0.045
	var depth := bounds.size.z+0.045
	var height := bounds.end.y+0.055
	var body_size := Vector2(width,depth)
	_chamfered("ExteriorShell",body_size,0.03,height-0.09,0.07,"ddd7bf")
	_chamfered("DustSkirt",body_size+Vector2.ONE*0.015,0.025,0.12,0.07,"5c6961")
	_chamfered("OrangeBelt",body_size+Vector2.ONE*0.024,0.16,0.065,0.075,"c88a43")
	_chamfered("SlopingRoofShoulder",body_size+Vector2.ONE*0.08,height-0.06,0.08,0.12,"b9bcaa",0.12)
	_chamfered("RoofDeck",body_size-Vector2.ONE*0.20,height+0.01,0.025,0.07,"727d73")
	# Broad roof panels, seams and a compact ventilation group.
	for side in [-1.0,1.0]:
		var roof_panel := _box("RoofPanel",Vector3(width*0.39,0.014,depth*0.66),Vector3(side*width*0.22,height+0.044,0.0),"a9af9e" if side<0.0 else "b8bba7")
		roof_panel.rotation.y = 0.0
	_chamfered("VentHousing",Vector2(width*0.23,depth*0.27),height+0.04,0.13,0.045,"626f66",0.035,Vector2(-width*0.19,-depth*0.20))
	for z in [-0.07,0.0,0.07]:
		_box("VentSlat",Vector3(width*0.18,0.012,0.022),Vector3(-width*0.19,height+0.177,-depth*0.20+z),"c4c6ae")
	# Front closure is a shutter/door panel, not a second gameplay door state.
	var front := depth*0.5+0.014
	var opening_width := width*(0.60 if hall else 0.25)
	var opening_height := height*(0.66 if hall else 0.70)
	_chamfered("EntranceStep",Vector2(opening_width+0.22,0.30),0.012,0.045,0.035,"a3aa97",0.0,Vector2(0.0,front+0.10))
	_box("DoorFrame",Vector3(opening_width+0.14,opening_height+0.08,0.045),Vector3(0.0,opening_height*0.5+0.075,front),"627169")
	_box("ClosedDoor",Vector3(opening_width,opening_height,0.025),Vector3(0.0,opening_height*0.5+0.06,front+0.032),"a0a794" if hall else "c8c7ad")
	if hall:
		for fraction in [0.20,0.40,0.60,0.80]:
			_box("ShutterJoint",Vector3(opening_width-0.04,0.012,0.008),Vector3(0.0,0.06+opening_height*fraction,front+0.048),"7d8b7b")
		_box("ShutterSafetyStripe",Vector3(opening_width-0.04,0.042,0.008),Vector3(0.0,opening_height*0.25,front+0.050),"d3a65c")
	else:
		_box("DoorSplit",Vector3(0.015,opening_height-0.06,0.008),Vector3(0.0,opening_height*0.5+0.06,front+0.048),"6d7b70")
		for x in [-0.10,0.10]:
			_box("DoorGlass",Vector3(0.055,opening_height*0.42,0.012),Vector3(x,opening_height*0.64,front+0.05),"407c83")
	# Large dark teal windows and shallow sloping brow/edge strips.
	for side in [-1.0,1.0]:
		var x: float = side*width*0.33
		_box("FrontWindowFrame",Vector3(width*0.19,height*0.25,0.035),Vector3(x,height*0.59,front),"64746b")
		_box("FrontWindow",Vector3(width*0.16,height*0.19,0.013),Vector3(x,height*0.59,front+0.024),"3c6971")
		var brow := _box("WindowBrow",Vector3(width*0.22,0.045,0.08),Vector3(x,height*0.75,front+0.018),"c9cbb5")
		brow.rotation.x = -0.25
		_box("CornerArmor",Vector3(0.065,height*0.59,0.055),Vector3(side*(width*0.5-0.065),height*0.53,front-0.018),"c1c4ad")
		for y in [height*0.30,height*0.72]:
			_rivet(Vector3(side*(width*0.5-0.065),y,front+0.018))
		for z in [-depth*0.30,depth*0.28]:
			_box("SidePanelSeam",Vector3(0.008,height*0.52,0.014),Vector3(side*(width*0.5+0.005),height*0.49,z),"aaaf99")
		for z in [-depth*0.34,0.0,depth*0.34]:
			_rivet(Vector3(side*width*0.34,height+0.057,z),true)
	var sign_label := Label3D.new()
	sign_label.name = "ExteriorIdentification"
	sign_label.text = "FREIHAFEN" if hall else "ROSTGRENZE  01"
	sign_label.font_size = 48
	sign_label.pixel_size = width*0.00043
	sign_label.outline_size = 0
	sign_label.modulate = Color("4b655e")
	sign_label.position = Vector3(0.0,height*0.87,front+0.020)
	add_child(sign_label)

func _chamfered(label: String,size: Vector2,bottom: float,height: float,corner: float,color: String,roof_inset: float = 0.0,offset: Vector2 = Vector2.ZERO) -> void:
	var half := size*0.5
	var outline := PackedVector2Array([Vector2(-half.x+corner,-half.y),Vector2(half.x-corner,-half.y),Vector2(half.x,-half.y+corner),Vector2(half.x,half.y-corner),Vector2(half.x-corner,half.y),Vector2(-half.x+corner,half.y),Vector2(-half.x,half.y-corner),Vector2(-half.x,-half.y+corner)])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for index in range(outline.size()):
		var a := outline[index]
		var b := outline[(index+1)%outline.size()]
		var top_a := a.normalized()*maxf(a.length()-roof_inset,0.0)
		var top_b := b.normalized()*maxf(b.length()-roof_inset,0.0)
		for v in [Vector3(a.x,bottom,a.y),Vector3(b.x,bottom,b.y),Vector3(top_b.x,bottom+height,top_b.y),Vector3(a.x,bottom,a.y),Vector3(top_b.x,bottom+height,top_b.y),Vector3(top_a.x,bottom+height,top_a.y),Vector3(0.0,bottom+height,0.0),Vector3(top_a.x,bottom+height,top_a.y),Vector3(top_b.x,bottom+height,top_b.y)]:
			surface.add_vertex(v+Vector3(offset.x,0.0,offset.y))
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = surface.commit()
	instance.material_override = _material(color)
	add_child(instance)

func _rivet(center: Vector3,top: bool = false) -> void:
	var instance := MeshInstance3D.new()
	instance.name = "PanelRivet"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.013
	mesh.bottom_radius = 0.015
	mesh.height = 0.009
	mesh.radial_segments = 8
	instance.mesh = mesh
	instance.position = center
	if not top: instance.rotation.x = PI*0.5
	instance.material_override = _material("6e7c70")
	add_child(instance)

func _box(label: String,size: Vector3,center: Vector3,color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = center
	instance.material_override = _material(color)
	add_child(instance)
	return instance

func _material(color: String) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.90
		_materials[color] = material
	return _materials[color]
