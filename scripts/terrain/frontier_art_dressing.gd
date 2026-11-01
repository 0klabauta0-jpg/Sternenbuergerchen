extends Node3D
## One-time authored visual groups. The preview applies returned blocking facts.
var _materials: Dictionary = {}
var _footprints: Array[Rect2] = []

func build(profile) -> Array[Rect2]:
	_path([Vector2(5.9,10.65),Vector2(7.0,10.65),Vector2(8.2,9.95),Vector2(12.3,9.95),Vector2(16.7,9.95),Vector2(17.5,8.9)],0.72)
	_path([Vector2(8.3,9.95),Vector2(8.3,7.42)],0.66)
	_path([Vector2(13.2,9.95),Vector2(13.2,7.55)],0.82)
	_path([Vector2(16.5,9.95),Vector2(16.1,8.73)],0.56)
	for center in [Vector2(4.6,5.0),Vector2(5.8,6.5),Vector2(6.9,12.6),Vector2(18.7,6.7),Vector2(20.0,10.8),Vector2(11.0,2.3),Vector2(19.4,2.6)]:
		_rock_group(center,profile)
	for center in [Vector2(6.5,7.2),Vector2(8.9,7.8),Vector2(10.7,7.5),Vector2(15.4,7.0),Vector2(18.0,7.6),Vector2(8.5,12.2),Vector2(16.1,12.0),Vector2(5.0,6.0),Vector2(19.0,9.4),Vector2(14.0,3.5)]:
		_plant_group(center)
	for spec in [Vector3(9.45,7.9,0.0),Vector3(14.8,7.6,0.3),Vector3(15.6,7.6,-0.2)]:
		_crate(Vector2(spec.x,spec.y),spec.z)
	for p in [Vector2(7.3,10.65),Vector2(10.4,10.4),Vector2(15.8,10.4),Vector2(13.8,7.7)]:
		_bollard(p)
	_loading_yard()
	_radio_mast(Vector2(10.7,3.25))
	return _footprints.duplicate()

func _loading_yard() -> void:
	# Flat authored apron: decoration does not introduce a second floor height.
	_box(self,"LoadingApron",Vector3(4.35,0.012,1.20),Vector3(13.7,0.0,7.98),"969485")
	for x in [12.0,12.7,13.4,14.1,14.8,15.5]:
		_box(self,"ApronBayStripe",Vector3(0.026,0.004,0.32),Vector3(x,0.009,8.32),"e0d2a0")
	for center in [Vector2(15.8,5.0),Vector2(16.7,5.6),Vector2(15.8,6.25)]:
		_container(center,2 if center.y<5.5 else 1)
	_loader(Vector2(16.8,6.95))

func _container(center: Vector2,levels: int) -> void:
	var group := Node3D.new()
	group.name = "FreihafenContainerGroup"
	group.position = Vector3(center.x,0.0,center.y)
	add_child(group)
	for level in range(levels):
		var floor_y := float(level)*0.43
		_box(group,"ContainerBody",Vector3(0.78,0.40,0.44),Vector3(0.0,floor_y+0.20,0.0),"aaa99a" if level==0 else "d2c5a2")
		_box(group,"OrangeHeader",Vector3(0.76,0.035,0.454),Vector3(0.0,floor_y+0.365,0.0),"c78b3e")
		for x in [-0.35,0.35]:
			_box(group,"CornerPost",Vector3(0.04,0.41,0.46),Vector3(x,floor_y+0.205,0.0),"53605b")
		_box(group,"DoorSeam",Vector3(0.02,0.28,0.015),Vector3(0.0,floor_y+0.16,0.23),"53605b")
	_footprints.append(Rect2(center-Vector2(0.48,0.32),Vector2(0.96,0.64)))

func _loader(center: Vector2) -> void:
	var group := Node3D.new()
	group.name = "StaticYardLoaderVisualOnly"
	group.position = Vector3(center.x,0.0,center.y)
	add_child(group)
	_box(group,"LoaderBody",Vector3(0.43,0.20,0.57),Vector3(0.0,0.18,0.0),"c78b3e")
	_box(group,"CabRoof",Vector3(0.39,0.035,0.34),Vector3(0.0,0.52,-0.10),"d8d0b7")
	for x in [-0.15,0.15]:
		for z in [-0.23,0.03]:
			_box(group,"CabPost",Vector3(0.025,0.27,0.025),Vector3(x,0.37,z),"52615c")
		_box(group,"Fork",Vector3(0.035,0.03,0.29),Vector3(x,0.045,0.39),"53605b")
		for z in [-0.18,0.18]:
			var wheel := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.radial_segments = 10
			mesh.top_radius = 0.085
			mesh.bottom_radius = 0.085
			mesh.height = 0.055
			wheel.mesh = mesh
			wheel.position = Vector3(x*1.48,0.085,z)
			wheel.rotation.z = PI*0.5
			wheel.material_override = _material("414d48")
			group.add_child(wheel)
	_footprints.append(Rect2(center-Vector2(0.36,0.35),Vector2(0.72,0.95)))

func _radio_mast(center: Vector2) -> void:
	var group := Node3D.new()
	group.name = "OutpostCommunicationsVisualOnly"
	group.position = Vector3(center.x,0.0,center.y)
	add_child(group)
	_box(group,"MastFoot",Vector3(0.5,0.08,0.5),Vector3(0.0,0.04,0.0),"9b9783")
	for x in [-0.13,0.13]:
		for z in [-0.10,0.10]:
			_box(group,"MastFrame",Vector3(0.027,1.10,0.027),Vector3(x,0.63,z),"747e71")
	for y in [0.28,0.58,0.88]:
		_box(group,"CrossFrame",Vector3(0.30,0.025,0.23),Vector3(0.0,y,0.0),"747e71")
	_box(group,"Antenna",Vector3(0.03,0.48,0.03),Vector3(-0.12,1.26,-0.10),"c78b3e")
	_box(group,"AntennaCap",Vector3(0.05,0.055,0.05),Vector3(-0.12,1.51,-0.10),"86bec0")
	var dish_root := Node3D.new()
	dish_root.name = "SatelliteDish"
	dish_root.position = Vector3(0.0,1.15,0.04)
	dish_root.rotation = Vector3(-0.30,0.35,0.0)
	group.add_child(dish_root)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(16):
		var a := TAU*float(index)/16.0
		var b := TAU*float(index+1)/16.0
		for vertex in [Vector3(0.0,0.0,-0.045),Vector3(cos(b)*0.26,sin(b)*0.26,0.0),Vector3(cos(a)*0.26,sin(a)*0.26,0.0)]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	var dish := MeshInstance3D.new()
	dish.mesh = surface.commit()
	var material := _material("d5d1ba")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	dish.material_override = material
	dish_root.add_child(dish)
	_box(dish_root,"Feed",Vector3(0.022,0.022,0.14),Vector3(0.0,0.0,0.04),"52615c")
	_footprints.append(Rect2(center-Vector2.ONE*0.42,Vector2.ONE*0.84))

func _material(color: String) -> StandardMaterial3D:
	if _materials.has(color): return _materials[color]
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color)
	material.roughness = 0.94
	_materials[color] = material
	return material

func _box(parent: Node3D,label: String,size: Vector3,position: Vector3,color: String) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _material(color)
	parent.add_child(instance)
	return instance

func _path(points: Array,width: float) -> void:
	var curve := Curve2D.new()
	curve.bake_interval = 0.12
	for index in range(points.size()):
		var tangent: Vector2 = (points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)])*0.18
		curve.add_point(points[index],-tangent,tangent)
	var samples := curve.get_baked_points()
	_ribbon(samples,width,0.008,"504f48")
	_ribbon(samples,width-0.07,0.010,"77776c")
	# Sparse orange guide strips give structure without a glowing continuous border.
	for index in range(2,samples.size()-2,8):
		var a: Vector2 = samples[index]
		var direction: Vector2 = (samples[index+1]-samples[index-1]).normalized()
		var normal := Vector2(-direction.y,direction.x)
		var marker := _box(self,"PathGuide",Vector3(0.018,0.004,0.18),Vector3(a.x+normal.x*(width*0.5-0.045),0.014,a.y+normal.y*(width*0.5-0.045)),"d5a34d")
		marker.rotation.y = atan2(direction.x,direction.y)

func _ribbon(points: PackedVector2Array,width: float,height: float,color: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(points.size()-1):
		var a := points[index]
		var b := points[index+1]
		var tangent_a := points[index+1]-points[maxi(index-1,0)]
		var tangent_b := points[mini(index+2,points.size()-1)]-points[index]
		var normal_a := Vector2(-tangent_a.y,tangent_a.x).normalized()*width*0.5
		var normal_b := Vector2(-tangent_b.y,tangent_b.x).normalized()*width*0.5
		var vertices := [Vector3(a.x-normal_a.x,height,a.y-normal_a.y),Vector3(a.x+normal_a.x,height,a.y+normal_a.y),Vector3(b.x+normal_b.x,height,b.y+normal_b.y),Vector3(b.x-normal_b.x,height,b.y-normal_b.y)]
		for v in [0,2,1,0,3,2]: surface.add_vertex(vertices[v])
	surface.generate_normals()
	var instance := MeshInstance3D.new()
	instance.name = "BuiltPath"
	instance.mesh = surface.commit()
	instance.material_override = _material(color)
	add_child(instance)

func _rock_group(center: Vector2,profile) -> void:
	var root := Node3D.new()
	root.name = "GroundRockGroup_%d"%get_child_count()
	root.position = Vector3(center.x,0.0,center.y)
	add_child(root)
	for index in range(6):
		var phase := float(index)*2.39996+center.x
		var radius := 0.25+float(index)*0.065
		var scale_value := 0.25 if index>2 else 0.50-float(index)*0.065
		var rock := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.radial_segments = 6
		mesh.rings = 1
		mesh.bottom_radius = scale_value
		mesh.top_radius = scale_value*0.62
		mesh.height = scale_value*0.85
		rock.mesh = mesh
		rock.position = Vector3(cos(phase)*radius,mesh.height*0.5,sin(phase)*radius)
		rock.rotation.y = phase
		rock.scale.z = 0.7+float(index%3)*0.18
		rock.material_override = profile.material_for(Color("bd6b47").lightened(float(index%3)*0.04),true)
		root.add_child(rock)
	_footprints.append(Rect2(center-Vector2.ONE*0.85,Vector2.ONE*1.7))
	_plant_group(center+Vector2(0.62,0.25))

func _plant_group(center: Vector2) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(9):
		var angle := float(index)*2.39996
		var length := 0.18+0.05*float(index%3)
		var direction := Vector2(cos(angle),sin(angle))
		var side := Vector2(-direction.y,direction.x)*0.045
		var base := Vector3(center.x,0.006,center.y)
		var tip := base+Vector3(direction.x*length,0.15+length*0.55,direction.y*length)
		var left := base+Vector3(side.x,0.0,side.y)
		var right := base-Vector3(side.x,0.0,side.y)
		for vertex in [left,tip,right,right,tip,left]: surface.add_vertex(vertex)
	surface.generate_normals()
	var plant := MeshInstance3D.new()
	plant.name = "DryAgave"
	plant.mesh = surface.commit()
	plant.material_override = _material("6d7950")
	add_child(plant)
	for index in range(3):
		var bush := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radial_segments = 7
		mesh.rings = 3
		mesh.radius = 0.12
		mesh.height = 0.19
		bush.mesh = mesh
		bush.position = Vector3(center.x+0.22+float(index)*0.10,0.075,center.y-0.10+float(index%2)*0.1)
		bush.material_override = _material("85815a" if index%2==0 else "66704b")
		add_child(bush)

func _crate(center: Vector2,angle: float) -> void:
	var root := Node3D.new()
	root.name = "SupplyCrate"
	root.position = Vector3(center.x,0.0,center.y)
	root.rotation.y = angle
	add_child(root)
	_box(root,"Body",Vector3(0.38,0.29,0.31),Vector3(0.0,0.145,0.0),"b39359")
	_box(root,"Lid",Vector3(0.40,0.035,0.33),Vector3(0.0,0.30,0.0),"cec7aa")
	for x in [-0.135,0.135]:
		_box(root,"Strap",Vector3(0.025,0.30,0.322),Vector3(x,0.15,0.0),"525b55")
	_footprints.append(Rect2(center-Vector2(0.30,0.28),Vector2(0.6,0.56)))

func _bollard(center: Vector2) -> void:
	_box(self,"PathLight",Vector3(0.065,0.28,0.065),Vector3(center.x,0.14,center.y),"525951")
	_box(self,"LightCap",Vector3(0.082,0.055,0.082),Vector3(center.x,0.29,center.y),"e8ddab")
