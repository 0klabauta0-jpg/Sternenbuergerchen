extends Node3D
## Display-only exterior family: parent visibility keeps the closed/cutaway switch.
## Geometry remains within original XZ bounds+0.22m and original height+0.20m.
const WEAR_SHADER = preload("res://shaders/terrain/frontier_building_wear.gdshader")
var _materials: Dictionary = {}
var _wear_height := 1.0
var _wear_seed := 3.2

func build(bounds: AABB, hall: bool) -> void:
	position = Vector3(bounds.get_center().x,0.0,bounds.get_center().z)
	var size := Vector2(bounds.size.x,bounds.size.z)
	var height := bounds.end.y
	_wear_height = height
	_wear_seed = 17.7 if hall else 3.2
	if hall: _build_hall(size,height)
	else: _build_habitat(size,height)
	_chamfered("DustSkirt",size+Vector2.ONE*0.035,0.0,0.127,0.10,"65695b")
	_chamfered("InsetFoundationBand",size+Vector2.ONE*0.045,0.095,0.075,0.10,"3d5556")
	_add_front(size,height,hall)
	_add_side_modules(size,height,hall)
	set_meta("visual_family","freihafen_industrial" if hall else "rostgrenze_habitat")
	set_meta("original_world_bounds",bounds)
	set_meta("permitted_margin_xz",0.22)
	set_meta("maximum_height",height+0.20)
	set_meta("material_revision","pass06_selective_painterly_wear")

func _build_habitat(size: Vector2,height: float) -> void:
	var wall_top := height*0.89
	_chamfered("ExteriorShell",size-Vector2.ONE*0.045,0.025,wall_top-0.025,0.12,"cfc8ae")
	_chamfered("HabitatUpperCornice",size+Vector2.ONE*0.065,wall_top-0.07,0.13,0.14,"dcd4bb",0.075)
	_chamfered("HabitatRoofWell",size-Vector2.ONE*0.16,wall_top+0.018,0.035,0.10,"344e52")
	# Three sloping roof masses surround the lower life-support channel.
	_chamfered("HabitatWestRoof",Vector2(size.x*0.35,size.y*0.80),wall_top+0.045,0.105,0.09,"557174",0.045,Vector2(-size.x*0.265,-size.y*0.025))
	_chamfered("HabitatRearRoof",Vector2(size.x*0.43,size.y*0.39),wall_top+0.045,0.09,0.08,"697b78",0.035,Vector2(size.x*0.21,-size.y*0.225))
	_chamfered("HabitatFrontRoof",Vector2(size.x*0.43,size.y*0.32),wall_top+0.045,0.065,0.075,"506a6d",0.035,Vector2(size.x*0.21,size.y*0.185))
	_box("RecessedServiceChannel",Vector3(0.12,0.028,size.y*0.69),Vector3(-size.x*0.025,wall_top+0.067,-size.y*0.03),"2e484c")
	_beveled_box("ChannelEndManifold",Vector3(0.23,0.075,0.20),Vector3(-size.x*0.025,wall_top+0.105,size.y*0.30),"88958b",0.018)
	var hvac_bottom := wall_top+0.13
	var hvac_offset := Vector2(size.x*0.22,-size.y*0.225)
	_chamfered("HabitatLifeSupportBase",Vector2(size.x*0.29,size.y*0.225),hvac_bottom,0.115,0.05,"b4b59f",0.025,hvac_offset)
	_chamfered("HabitatLifeSupportInset",Vector2(size.x*0.23,size.y*0.15),hvac_bottom+0.107,0.015,0.035,"344f53",0.0,hvac_offset)
	for index in range(4):
		_beveled_box("LifeSupportLouver",Vector3(size.x*0.18,0.017,0.035),Vector3(hvac_offset.x,hvac_bottom+0.128,hvac_offset.y-0.12+index*0.08),"86958b",0.006)
	_beveled_box("HabitatRoofServicePlate",Vector3(size.x*0.23,0.025,0.22),Vector3(-size.x*0.26,wall_top+0.157,size.y*0.21),"929c8b",0.02)

func _build_hall(size: Vector2,height: float) -> void:
	var half := size.x*0.5
	var bay_top := height*0.94
	var office_top := height*0.79
	# Actual asymmetric hull: high warehouse bay and lower attached office.
	var profile := PackedVector2Array([
		Vector2(-half,0.025),Vector2(half,0.025),
		Vector2(half,office_top-0.07),Vector2(half-0.08,office_top),
		Vector2(size.x*0.285,office_top),Vector2(size.x*0.285,bay_top-0.08),
		Vector2(size.x*0.235,bay_top),Vector2(-half+0.11,bay_top),Vector2(-half,bay_top-0.12)])
	_profile_prism("ExteriorShell",profile,-size.y*0.5+0.025,size.y*0.5-0.025,"c8c2a8")
	_chamfered("IndustrialBayRoof",Vector2(size.x*0.735,size.y+0.06),bay_top-0.018,0.105,0.11,"5b7272",0.07,Vector2(-size.x*0.116,0.0))
	_chamfered("OfficeRoofShoulder",Vector2(size.x*0.235,size.y+0.015),office_top-0.025,0.10,0.075,"ddd2b7",0.04,Vector2(size.x*0.375,0.0))
	_chamfered("OfficeRoofField",Vector2(size.x*0.18,size.y*0.77),office_top+0.06,0.02,0.045,"6d817b",0.0,Vector2(size.x*0.375,-0.01))
	var monitor_bottom := bay_top+0.07
	_chamfered("HallRoofMonitorBase",Vector2(size.x*0.22,size.y*0.67),monitor_bottom,0.105,0.055,"384f53",0.02,Vector2(-size.x*0.08,-size.y*0.04))
	_chamfered("HallRoofMonitorCap",Vector2(size.x*0.24,size.y*0.69),monitor_bottom+0.10,0.065,0.06,"b5b7a2",0.045,Vector2(-size.x*0.08,-size.y*0.04))
	_beveled_box("MonitorClerestory",Vector3(size.x*0.17,0.034,0.040),Vector3(-size.x*0.08,monitor_bottom+0.075,size.y*0.295),"be8b4b",0.006).material_override = _emissive("b99058",0.20)
	_chamfered("HallExhaustManifold",Vector2(size.x*0.25,size.y*0.19),bay_top+0.082,0.11,0.045,"8b978b",0.025,Vector2(-size.x*0.31,-size.y*0.29))
	for index in range(4):
		_box("HallExhaustLouver",Vector3(size.x*0.19,0.014,0.028),Vector3(-size.x*0.31,bay_top+0.198,-size.y*0.29-0.105+index*0.07),"3d5658")
	for z in [-size.y*0.33,size.y*0.33]:
		_beveled_box("HallRoofCrossRib",Vector3(size.x*0.72,0.042,0.105),Vector3(-size.x*0.116,bay_top+0.098,z),"839087",0.012)
	_beveled_box("OfficeHVAC",Vector3(size.x*0.15,0.105,size.y*0.19),Vector3(size.x*0.375,office_top+0.125,-size.y*0.26),"9ca58f",0.023)

func _add_front(size: Vector2,height: float,hall: bool) -> void:
	var front := size.y*0.5
	var door_x: float = -size.x*0.10 if hall else 0.0
	var opening_width: float = size.x*(0.54 if hall else 0.25)
	var opening_height: float = height*(0.65 if hall else 0.69)
	var door_y := opening_height*0.5+0.07
	var frame_z := front+0.045
	# Backing/names preserve the existing BoxMesh door/window spacing regression.
	_box("DoorFrame",Vector3(opening_width+0.18,opening_height+0.13,0.14),Vector3(door_x,door_y,frame_z),"344e53")
	_box("ClosedDoor",Vector3(opening_width,opening_height,0.035),Vector3(door_x,door_y,front+0.125),"667b78" if hall else "bebca2")
	for side in [-1.0,1.0]:
		_beveled_box("PortalCastJamb",Vector3(0.11,opening_height+0.20,0.20),Vector3(door_x+side*(opening_width*0.5+0.075),door_y+0.035,front+0.055),"d5ccb3" if hall else "557073",0.022)
	_beveled_box("PortalLintel",Vector3(opening_width+0.31,0.145,0.22),Vector3(door_x,opening_height+0.125,front+0.055),"d5ccb3" if hall else "557073",0.03)
	_chamfered("EntranceStep",Vector2(opening_width+0.23,0.27),0.012,0.045,0.035,"989c85",0.0,Vector2(door_x,front+0.063))
	if hall:
		for fraction in [0.25,0.50,0.75]:
			_box("ShutterJoint",Vector3(opening_width-0.03,0.018,0.009),Vector3(door_x,0.07+opening_height*fraction,front+0.147),"425e61")
		_box("ShutterSafetyStripe",Vector3(opening_width-0.04,0.055,0.010),Vector3(door_x,opening_height*0.24,front+0.148),"c68e43")
		_beveled_box("BayStormHood",Vector3(opening_width+0.37,0.12,0.39),Vector3(door_x,opening_height+0.225,front+0.018),"3d5b60",0.03)
		for side in [-1.0,1.0]:
			_beveled_box("BayButtress",Vector3(0.18,height*0.70,0.20),Vector3(door_x+side*(opening_width*0.5+0.19),height*0.40,front+0.025),"687c77",0.035)
		_beveled_box("BayStatusStrip",Vector3(0.23,0.028,0.018),Vector3(door_x+opening_width*0.38,opening_height+0.13,front+0.174),"d3a35c",0.006).material_override = _emissive("d3a35c",0.25)
	else:
		_box("DoorSplit",Vector3(0.015,opening_height-0.055,0.009),Vector3(door_x,door_y,front+0.143),"4b686a")
		for side in [-1.0,1.0]:
			_box("DoorGlass",Vector3(0.065,opening_height*0.40,0.012),Vector3(side*0.115,opening_height*0.64,front+0.145),"376b76")
			_beveled_box("EntranceWarmFrame",Vector3(0.025,opening_height*0.60,0.016),Vector3(side*(opening_width*0.5+0.012),door_y+0.015,front+0.153),"dcab61",0.006).material_override = _emissive("dcab61",0.32)
		_chamfered("HabitatEntranceCanopy",Vector2(opening_width+0.34,0.39),opening_height+0.17,0.075,0.06,"36565b",0.035,Vector2(0.0,front+0.015))
		_beveled_box("CanopyWarmUnderside",Vector3(opening_width*0.68,0.016,0.055),Vector3(0.0,opening_height+0.167,front+0.12),"dcb476",0.005).material_override = _emissive("dcb476",0.23)
	for index in range(2):
		var side: float = -1.0 if index==0 else 1.0
		var x_fraction: float = (0.455 if index==0 else 0.405) if hall else 0.335
		var x: float = side*size.x*x_fraction
		var window_fraction: float = (0.08 if index==0 else 0.14) if hall else 0.18
		var window_width: float = size.x*window_fraction
		var window_height: float = height*(0.19 if hall else 0.25)
		var window_y: float = height*(0.53 if hall else 0.52)
		var label: String = "FrontWindowFrame" if index==0 else "FrontWindowFrameRight"
		_box(label,Vector3(window_width+0.07,window_height+0.07,0.14),Vector3(x,window_y,frame_z),"3a565c")
		_beveled_box("WindowDeepBrow",Vector3(window_width+0.13,0.08,0.19),Vector3(x,window_y+window_height*0.5+0.06,front+0.053),"c4c2a7",0.018)
		_beveled_box("WindowDeepSill",Vector3(window_width+0.10,0.075,0.17),Vector3(x,window_y-window_height*0.5-0.055,front+0.035),"607875",0.015)
		_box("FrontWindow",Vector3(window_width,window_height,0.018),Vector3(x,window_y,front+0.114),"335e68")
		if index==1:
			_box("WarmOccupiedWindow",Vector3(window_width*0.48,window_height*0.82,0.012),Vector3(x+window_width*0.23,window_y,front+0.126),"ba955f").material_override = _emissive("c39e69",0.16)
	var sign_label := Label3D.new()
	sign_label.name = "ExteriorIdentification"
	sign_label.text = "FREIHAFEN  03" if hall else "ROSTGRENZE  01"
	sign_label.font_size = 48
	sign_label.pixel_size = size.x*0.00040
	sign_label.outline_size = 0
	sign_label.modulate = Color("465e5e" if hall else "dfd3b6")
	sign_label.position = Vector3(door_x,height*0.91 if hall else opening_height+0.205,front+0.095 if hall else front+0.218)
	add_child(sign_label)

func _add_side_modules(size: Vector2,height: float,hall: bool) -> void:
	for side in [-1.0,1.0]:
		for index in range(3):
			var z: float = size.y*(-0.32+index*0.32)
			var panel_height: float = height*(0.46 if hall else 0.48)
			var center := Vector3(side*(size.x*0.5-0.005),height*0.49,z)
			_beveled_box("InsetFacadeCassette",Vector3(0.075,panel_height,size.y*0.27),center,["c9c3a9","b9bba2","d5cbb0"][index],0.014)
			_beveled_box("StructuralFacadeRib",Vector3(0.12,height*0.64,0.10),Vector3(side*(size.x*0.5+0.025),height*0.43,z-size.y*0.145),"536f70" if hall else "8f9c8e",0.019)
		_beveled_box("ServiceAccessPlate",Vector3(0.09,height*0.19,size.y*0.22),Vector3(side*(size.x*0.5+0.015),height*0.30,-size.y*0.19),"537175",0.018)
		_box("ServiceAccessMarker",Vector3(0.012,0.033,size.y*0.13),Vector3(side*(size.x*0.5+0.067),height*0.31,-size.y*0.19),"c99c57")
		_beveled_box("FoundationRepairPanel",Vector3(0.095,0.095,size.y*0.25),Vector3(side*(size.x*0.5+0.012),0.092,size.y*0.23),"7c8170",0.016)

func _ring(size: Vector2,y: float,corner: float,inset: float,offset: Vector2) -> PackedVector3Array:
	var half := size*0.5-Vector2.ONE*inset
	var c := minf(corner,minf(half.x,half.y)*0.7)
	var outline := PackedVector2Array([Vector2(-half.x+c,-half.y),Vector2(half.x-c,-half.y),Vector2(half.x,-half.y+c),Vector2(half.x,half.y-c),Vector2(half.x-c,half.y),Vector2(-half.x+c,half.y),Vector2(-half.x,half.y-c),Vector2(-half.x,-half.y+c)])
	var points := PackedVector3Array()
	for point in outline: points.append(Vector3(point.x+offset.x,y,point.y+offset.y))
	return points

func _triangle(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,outward: Vector3) -> void:
	# Godot clockwise winding; explicit finite normals on every cap and side.
	var normal := (c-a).cross(b-a).normalized()
	if normal.dot(outward)<0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	surface.set_normal(normal)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

func _quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,outward: Vector3) -> void:
	_triangle(surface,a,b,c,outward)
	_triangle(surface,a,c,d,outward)

func _rings_mesh(label: String,rings: Array[PackedVector3Array],color: String) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in range(rings.size()-1):
		var lower := rings[ring_index]
		var upper := rings[ring_index+1]
		var center := Vector3.ZERO
		for point in lower: center += point
		center /= lower.size()
		for index in range(lower.size()):
			var following := (index+1)%lower.size()
			var outward := (lower[index]+lower[following])*0.5-center
			_quad(surface,lower[index],lower[following],upper[following],upper[index],outward)
	for end_index in [0,rings.size()-1]:
		var ring := rings[end_index]
		var center := Vector3.ZERO
		for point in ring: center += point
		center /= ring.size()
		for index in range(ring.size()):
			_triangle(surface,center,ring[index],ring[(index+1)%ring.size()],Vector3.DOWN if end_index==0 else Vector3.UP)
	return _mesh(label,surface,color)

func _chamfered(label: String,size: Vector2,bottom: float,height: float,corner: float,color: String,roof_inset: float = 0.0,offset: Vector2 = Vector2.ZERO) -> MeshInstance3D:
	var rings: Array[PackedVector3Array] = [_ring(size,bottom,corner,0.0,offset),_ring(size,bottom+height,corner,roof_inset,offset)]
	return _rings_mesh(label,rings,color)

func _beveled_box(label: String,size: Vector3,center: Vector3,color: String,bevel: float) -> MeshInstance3D:
	var b := minf(bevel,minf(size.x,minf(size.y,size.z))*0.24)
	var plan := Vector2(size.x,size.z)
	var offset := Vector2(center.x,center.z)
	var bottom := center.y-size.y*0.5
	var rings: Array[PackedVector3Array] = [_ring(plan,bottom,b,b,offset),_ring(plan,bottom+b,b,0.0,offset),_ring(plan,bottom+size.y-b,b,0.0,offset),_ring(plan,bottom+size.y,b,b,offset)]
	return _rings_mesh(label,rings,color)

func _profile_prism(label: String,profile: PackedVector2Array,back: float,front: float,color: String) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(profile)
	for offset in range(0,indices.size(),3):
		var a := profile[indices[offset]]
		var b := profile[indices[offset+1]]
		var c := profile[indices[offset+2]]
		_triangle(surface,Vector3(a.x,a.y,front),Vector3(b.x,b.y,front),Vector3(c.x,c.y,front),Vector3.BACK)
		_triangle(surface,Vector3(a.x,a.y,back),Vector3(b.x,b.y,back),Vector3(c.x,c.y,back),Vector3.FORWARD)
	for index in range(profile.size()):
		var a := profile[index]
		var b := profile[(index+1)%profile.size()]
		var outward := Vector3(b.y-a.y,a.x-b.x,0.0)
		_quad(surface,Vector3(a.x,a.y,back),Vector3(b.x,b.y,back),Vector3(b.x,b.y,front),Vector3(a.x,a.y,front),outward)
	return _mesh(label,surface,color)

func _mesh(label: String,surface: SurfaceTool,color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = surface.commit()
	_route_material(instance,label,color)
	add_child(instance)
	return instance

func _box(label: String,size: Vector3,center: Vector3,color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = center
	_route_material(instance,label,color)
	add_child(instance)
	return instance

func _emissive(color: String,energy: float) -> StandardMaterial3D:
	var key := color+":emission:"+str(energy)
	if not _materials.has(key):
		var material := _material(color).duplicate() as StandardMaterial3D
		material.emission_enabled = true
		material.emission = Color(color)
		material.emission_energy_multiplier = energy
		_materials[key] = material
	return _materials[key]

func _route_material(instance: MeshInstance3D,label: String,color: String) -> void:
	instance.set_meta("surface_role_label",label)
	# Glass, light surfaces, narrow graphic marks and deep voids keep the P05 route.
	var clean_labels := ["FrontWindow","DoorGlass","WarmOccupiedWindow","MonitorClerestory","BayStatusStrip","EntranceWarmFrame","CanopyWarmUnderside","ShutterJoint","DoorSplit","ShutterSafetyStripe","ServiceAccessMarker","RecessedServiceChannel","HabitatLifeSupportInset","HallExhaustLouver"]
	if label in clean_labels:
		instance.material_override = _material(color)
		instance.set_meta("material_route","standard_or_emissive_preserved")
		return
	var role := "paint"
	if label in ["DustSkirt","InsetFoundationBand","FoundationRepairPanel","EntranceStep"]:
		role = "base"
	elif "Roof" in label or "LifeSupportBase" in label or "MonitorCap" in label or "HVAC" in label:
		role = "roof"
	elif "Portal" in label or "Buttress" in label or "Rib" in label or "Frame" in label or "Brow" in label or "Sill" in label:
		role = "structure"
	var key := "wear:"+color+":"+role
	if not _materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = WEAR_SHADER
		material.set_shader_parameter("base_color",Color(color))
		material.set_shader_parameter("building_origin",global_position)
		material.set_shader_parameter("building_height",_wear_height)
		material.set_shader_parameter("pattern_seed",_wear_seed)
		var strengths := {"paint":Vector4(0.60,0.40,0.70,0.28),"roof":Vector4(0.38,0.90,0.15,0.30),"structure":Vector4(0.46,0.40,0.32,0.58),"base":Vector4(0.95,0.12,0.30,0.28)}
		material.set_shader_parameter("role_strength",strengths[role])
		_materials[key] = material
	instance.material_override = _materials[key]
	var bounds := instance.get_aabb()
	instance.set_instance_shader_parameter("wear_part_min",bounds.position)
	instance.set_instance_shader_parameter("wear_part_max",bounds.end)
	instance.set_meta("material_route","painterly_wear:"+role)

func _material(color: String) -> StandardMaterial3D:
	if not _materials.has(color):
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.92
		_materials[color] = material
	return _materials[color]
