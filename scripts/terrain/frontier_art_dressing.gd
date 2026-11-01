extends Node3D
## One-time authored visual groups. The preview applies returned blocking facts.
var _materials: Dictionary = {}
var _footprints: Array[Rect2] = []
var _path_layers: Dictionary = {}
const GROUND_SHADER = preload("res://shaders/terrain/frontier_ground.gdshader")

func build(profile) -> Array[Rect2]:
	# A wide service spine with short building connections; clear turning space.
	_path([Vector2(9.96,10.9),Vector2(10.5,10.9),Vector2(11.2,10.45),Vector2(15.0,10.45),Vector2(15.9,11.8),Vector2(16.14,11.8)],1.04,true)
	_path([Vector2(8.3,7.42),Vector2(8.3,8.0),Vector2(9.8,8.7),Vector2(10.55,10.7)],0.68)
	_path([Vector2(13.2,10.45),Vector2(13.2,8.48)],0.84)
	_path([Vector2(15.0,10.45),Vector2(16.1,9.15),Vector2(16.1,8.73)],0.64)
	for center in [Vector2(4.6,5.0),Vector2(5.8,6.5),Vector2(6.5,14.5),Vector2(18.7,6.7),Vector2(21.8,9.0),Vector2(11.0,2.3),Vector2(19.4,2.6)]:
		_rock_group(center,profile)
	for center in [Vector2(6.5,7.2),Vector2(9.5,7.3),Vector2(10.7,7.5),Vector2(15.4,7.0),Vector2(18.0,7.6),Vector2(9.8,13.5),Vector2(17.0,13.8),Vector2(5.0,6.0),Vector2(20.7,8.7),Vector2(14.0,3.5)]:
		_plant_group(center)
	for spec in [Vector3(9.45,7.9,0.0),Vector3(14.8,7.6,0.3),Vector3(15.6,7.6,-0.2)]:
		_crate(Vector2(spec.x,spec.y),spec.z)
	for p in [Vector2(10.5,11.45),Vector2(11.6,9.85),Vector2(15.1,11.2),Vector2(13.8,8.6)]:
		_bollard(p)
	_finish_paths()
	_loading_yard()
	_radio_mast(Vector2(10.7,3.25))
	return _footprints.duplicate()

func _loading_yard() -> void:
	# Flat authored apron: decoration does not introduce a second floor height.
	var apron := _box(self,"LoadingApron",Vector3(4.35,0.012,1.20),Vector3(13.7,0.0,7.98),"858b7c")
	apron.material_override = _paving_material("858b7c")
	for x in [12.0,12.7,13.4,14.1,14.8,15.5]:
		_box(self,"ApronBayStripe",Vector3(0.026,0.004,0.32),Vector3(x,0.009,8.32),"e0d2a0")
	for center in [Vector2(15.8,5.0),Vector2(16.7,5.6),Vector2(15.8,6.25)]:
		_container(center,2 if center.y<5.5 else 1)

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

func _paving_material(color: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GROUND_SHADER
	material.set_shader_parameter("base_color",Color(color))
	material.set_shader_parameter("paved_surface",true)
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

func _path(points: Array,width: float,service_lane: bool = false) -> void:
	var curve := Curve2D.new()
	curve.bake_interval = 0.10
	for index in range(points.size()):
		var tangent: Vector2 = (points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)])*0.12
		curve.add_point(points[index],-tangent,tangent)
	var samples := curve.get_baked_points()
	# Warm dusty shoulders merge with the red soil; the deck stays matte and low.
	_ribbon(samples,width+0.14,0.007,"b47b53")
	_ribbon(samples,width,0.010,"686f63")
	_ribbon(samples,width-0.10,0.012,"747c6c")
	for index in range(3,samples.size()-3,7):
		var a: Vector2 = samples[index]
		var direction: Vector2 = (samples[index+1]-samples[index-1]).normalized()
		var normal := Vector2(-direction.y,direction.x)
		for side in [-1.0,1.0]:
			var marker := _box(self,"PathEdgeGuide",Vector3(0.024,0.003,0.24),Vector3(a.x+normal.x*(width*0.5-0.06)*side,0.017,a.y+normal.y*(width*0.5-0.06)*side),"cbc6a5")
			marker.rotation.y = atan2(direction.x,direction.y)
		if service_lane and index%2==1:
			var center_mark := _box(self,"ServiceLaneGuide",Vector3(0.022,0.003,0.20),Vector3(a.x,0.018,a.y),"d4af67")
			center_mark.rotation.y = atan2(direction.x,direction.y)

func _ribbon(points: PackedVector2Array,width: float,height: float,color: String) -> void:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(points.size()):
		var tangent := points[mini(index+1,points.size()-1)]-points[maxi(index-1,0)]
		var normal := Vector2(-tangent.y,tangent.x).normalized()*width*0.5
		left.append(points[index]-normal)
		right.append(points[index]+normal)
	right.reverse()
	left.append_array(right)
	if not _path_layers.has(color):
		_path_layers[color] = {"height":height,"polygons":[]}
	var polygons: Array = _path_layers[color]["polygons"]
	# Union every connected lane before meshing. Crossing coplanar ribbons flicker.
	var pending := left
	var index := 0
	while index<polygons.size():
		var merged := Geometry2D.merge_polygons(pending,polygons[index])
		if merged.size()==1:
			pending = merged[0]
			polygons.remove_at(index)
			index = 0
		else:
			index += 1
	polygons.append(pending)

func _finish_paths() -> void:
	for color in _path_layers:
		var layer: Dictionary = _path_layers[color]
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for polygon in layer["polygons"]:
			var indices := Geometry2D.triangulate_polygon(polygon)
			for index in indices:
				var point: Vector2 = polygon[index]
				surface.add_vertex(Vector3(point.x,float(layer["height"]),point.y))
		surface.generate_normals()
		var instance := MeshInstance3D.new()
		instance.name = "JoinedServicePaths"
		instance.mesh = surface.commit()
		instance.material_override = _paving_material(color)
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
		var mesh := _boulder_mesh(scale_value,index+int(center.x*31.0))
		rock.mesh = mesh
		rock.position = Vector3(cos(phase)*radius,0.0,sin(phase)*radius)
		rock.rotation.y = phase
		rock.scale.z = 0.7+float(index%3)*0.18
		rock.material_override = profile.material_for(Color("bd6b47").lightened(float(index%3)*0.04),true)
		root.add_child(rock)
	_footprints.append(Rect2(center-Vector2.ONE*0.85,Vector2.ONE*1.7))
	_plant_group(center+Vector2(0.62,0.25))

func _boulder_mesh(radius: float,seed_value: int) -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for level in range(4):
		var ring := PackedVector3Array()
		var level_radius: float = [0.67,1.0,0.82,0.46][level]
		var y: float = [0.0,0.20,0.72,0.93][level]*radius
		for sector in range(7):
			var angle := TAU*float(sector)/7.0+float(seed_value)*0.51
			var fracture := 0.88+0.11*sin(float(sector*17+seed_value)*2.7)
			ring.append(Vector3(cos(angle)*radius*level_radius*fracture,y,sin(angle)*radius*level_radius*fracture))
		rings.append(ring)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for level in range(3):
		for sector in range(7):
			var next := (sector+1)%7
			for v in [rings[level][sector],rings[level][next],rings[level+1][next],rings[level][sector],rings[level+1][next],rings[level+1][sector]]:
				surface.add_vertex(v)
	for sector in range(7):
		for v in [Vector3(0.0,radius*0.93,0.0),rings[3][sector],rings[3][(sector+1)%7]]:
			surface.add_vertex(v)
	surface.generate_normals()
	return surface.commit()

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
