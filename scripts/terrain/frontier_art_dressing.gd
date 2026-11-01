extends Node3D
## One-time authored visual groups. The preview applies returned blocking facts.
var _materials: Dictionary = {}
var _footprints: Array[Rect2] = []

func build(profile) -> Array[Rect2]:
	_path([Vector2(5.9,10.65),Vector2(7.0,10.65),Vector2(8.2,9.95),Vector2(12.3,9.95),Vector2(16.7,9.95),Vector2(17.5,8.9)],0.72)
	_path([Vector2(8.3,9.95),Vector2(8.3,7.8)],0.66)
	_path([Vector2(13.2,9.95),Vector2(13.2,7.55)],0.82)
	_path([Vector2(16.5,9.95),Vector2(16.1,8.95)],0.56)
	for center in [Vector2(4.6,5.0),Vector2(6.0,6.5),Vector2(6.9,12.6),Vector2(18.7,6.7),Vector2(20.0,10.8),Vector2(11.0,2.3),Vector2(19.4,2.6)]:
		_rock_group(center,profile)
	for center in [Vector2(7.2,7.0),Vector2(8.9,7.8),Vector2(11.9,6.7),Vector2(14.8,7.4),Vector2(17.2,7.2),Vector2(8.5,12.2),Vector2(16.1,12.0),Vector2(5.0,6.0),Vector2(19.0,9.4),Vector2(14.0,3.5)]:
		_plant_group(center)
	for spec in [Vector3(9.45,7.9,0.0),Vector3(14.8,7.6,0.3),Vector3(15.6,7.6,-0.2)]:
		_crate(Vector2(spec.x,spec.y),spec.z)
	for p in [Vector2(7.3,10.65),Vector2(10.4,10.4),Vector2(15.8,10.4),Vector2(13.8,7.7)]:
		_bollard(p)
	return _footprints.duplicate()

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
