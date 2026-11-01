extends Node3D
## Seeded visual geology. Returns conservative footprints; the fixture owns facts.
var _footprints: Array[Rect2] = []
var _materials: Array[Material] = []

func build(profile, _center: Vector2) -> Array[Rect2]:
	_footprints.clear()
	for color in ["aa583d","ae5c3e","b46141","bb6846","c1724d"]:
		_materials.append(profile.material_for(Color(color),true))
	var groups := [
		[Vector2(-0.7,1.0),Vector3(6.8,4.6,4.5)],
		[Vector2(5.1,-3.1),Vector3(6.5,3.8,4.5)],
		[Vector2(12.8,-3.8),Vector3(8.2,5.8,5.3)],
		[Vector2(21.2,-1.2),Vector3(7.2,4.8,4.9)],
		[Vector2(26.0,5.2),Vector3(4.7,3.4,5.0)],
		[Vector2(1.5,14.0),Vector3(4.1,2.3,3.4)],
		[Vector2(23.0,16.1),Vector3(4.6,2.7,3.6)],
		[Vector2(10.8,0.8),Vector3(6.0,3.4,2.8)],
		[Vector2(19.4,2.4),Vector3(4.2,2.8,2.7)],
		[Vector2(2.35,7.0),Vector3(3.2,2.6,3.8)],
	]
	for index in range(groups.size()):
		_add_mesa("MesaCluster_%d"%index,groups[index][0],groups[index][1],index*83+17)
	for spec in [Vector3(2.4,-0.3,2.5),Vector3(18.3,0.3,2.8),Vector3(24.7,10.8,2.1),Vector3(4.2,13.4,1.5)]:
		_add_mesa("MesaCluster_Spire_%d"%get_child_count(),Vector2(spec.x,spec.y),Vector3(1.35,spec.z,1.15),get_child_count()*31)
	return _footprints.duplicate()

func _noise(seed_value: int, index: int) -> float:
	return fposmod(sin(float(seed_value*17+index*73)*12.9898)*43758.5453,1.0)

func _add_mesa(label: String, plane: Vector2, size: Vector3, seed_value: int) -> void:
	var root := Node3D.new()
	root.name = label
	root.position = Vector3(plane.x,-0.10,plane.y)
	add_child(root)
	var sectors := 14
	# Stepped ledges and staggered centers avoid regular concentric cones.
	var heights := [0.0,0.16,0.19,0.33,0.35,0.51,0.54,0.69,0.72,0.87,0.91,1.0]
	var radii := [1.0,0.98,0.88,0.90,0.75,0.78,0.65,0.68,0.52,0.54,0.42,0.36]
	if size.x>3.0:
		radii = [1.0,0.98,0.93,0.95,0.87,0.90,0.82,0.84,0.76,0.78,0.72,0.74]
	var rings: Array[PackedVector3Array] = []
	for level in range(heights.size()):
		var ring := PackedVector3Array()
		var offset := Vector2(sin(float(level)*0.69+float(seed_value))*0.08,cos(float(level)*0.47+float(seed_value))*0.08)
		for sector in range(sectors):
			var angle := TAU*float(sector)/float(sectors)
			var fracture := 0.86+_noise(seed_value,sector)*0.24
			var ledge := 0.97+_noise(seed_value+floori(float(level)/2.0),sector)*0.07
			var radius: float = radii[level]*fracture*ledge
			var broken_height: float = heights[level]+((_noise(seed_value+level/2,sector)-0.5)*0.03 if level>0 and level<heights.size()-1 else 0.0)
			ring.append(Vector3((cos(angle)*radius+offset.x)*size.x*0.5,broken_height*size.y,(sin(angle)*radius+offset.y)*size.z*0.5))
		rings.append(ring)
	var mesh := ArrayMesh.new()
	for level in range(rings.size()-1):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for sector in range(sectors):
			var next := (sector+1)%sectors
			_quad(surface,rings[level][sector],rings[level+1][sector],rings[level+1][next],rings[level][next])
		surface.generate_normals()
		surface.commit(mesh)
	var cap := SurfaceTool.new()
	cap.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: PackedVector3Array = rings.back()
	var center := Vector3(0.0,size.y,0.0)
	for sector in range(sectors):
		_triangle(cap,center,top[(sector+1)%sectors],top[sector])
	cap.generate_normals()
	cap.commit(mesh)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.name = "BrokenStrata"
	for surface in range(mesh.get_surface_count()):
		instance.set_surface_override_material(surface,_materials[mini(surface/3,_materials.size()-1)])
	root.add_child(instance)
	var bounds: AABB = instance.get_aabb()
	_footprints.append(Rect2(plane+Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)).grow(0.18))

func _triangle(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)

func _quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	_triangle(surface,a,b,c)
	_triangle(surface,a,c,d)
