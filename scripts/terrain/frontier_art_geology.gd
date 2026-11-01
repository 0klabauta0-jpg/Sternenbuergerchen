extends Node3D
## Pass03 authored geology. One-time visual build; fixture still owns terrain facts.
var _footprints: Array[Rect2] = []
var _materials: Array[Material] = []

func build(profile, _center: Vector2) -> Array[Rect2]:
	_footprints.clear()
	_materials.clear()
	for child in get_children():
		child.free()
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
	var group := Node3D.new()
	group.name = label
	group.position = Vector3(plane.x,-0.10,plane.y)
	add_child(group)
	# Preserve the pass02 navigation envelope to float precision. All new bodies, including
	# talus, fit inside it; this change does not silently move the playable border.
	var envelope := _pass02_envelope(size,seed_value)
	_footprints.append(Rect2(plane+envelope.position,envelope.size).grow(0.18))
	var width := envelope.size.x
	var depth := envelope.size.y
	var center := envelope.get_center()
	if size.x<3.0:
		_add_block(group,"FracturedSpire",center,Vector3(width*0.72,size.y,depth*0.70),seed_value,2)
		_add_block(group,"SpireShoulder",center+Vector2(width*0.22,depth*0.17),Vector3(width*0.39,size.y*0.30,depth*0.48),seed_value+13,1)
		return
	var handed := -1.0 if _noise(seed_value,2)<0.5 else 1.0
	var form := seed_value%3
	var crown_width := width*(0.79+_noise(seed_value,3)*0.06)
	var crown_depth := depth*(0.72+_noise(seed_value,4)*0.08)
	if form==0:
		_add_block(group,"BrokenWall",center+Vector2(width*0.015,-depth*0.11),Vector3(width*0.88,size.y,depth*0.67),seed_value,3)
		_add_block(group,"BroadTerrace",center+Vector2(0.0,depth*0.20),Vector3(width*0.80,size.y*(0.38+_noise(seed_value,5)*0.12),depth*0.42),seed_value+29,2)
	else:
		_add_block(group,"BrokenWall",center+Vector2(handed*width*0.055,-depth*0.05),Vector3(crown_width,size.y,crown_depth),seed_value,3)
		# Unequal adjoining shoulders make a wall mass rather than a tapered cylinder.
		var shoulder_height := 0.70 if form==2 else 0.51
		_add_block(group,"LowerButtress",center+Vector2(-handed*width*0.245,depth*0.205),Vector3(width*0.46,size.y*(shoulder_height+_noise(seed_value,5)*0.10),depth*0.47),seed_value+29,2)
		_add_block(group,"BrokenApron",center+Vector2(handed*width*0.285,depth*0.27),Vector3(width*0.32,size.y*(0.23+_noise(seed_value,6)*0.12),depth*0.32),seed_value+53,1)
	for index in range(2):
		var x := (-0.25 if index==0 else 0.21)*width
		var fragment_size := Vector3(width*(0.12+_noise(seed_value,70+index)*0.025),minf(size.y*0.11,0.40),depth*0.13)
		_add_block(group,"Talus_%d"%index,center+Vector2(x,depth*0.405),fragment_size,seed_value+91+index*17,1)

func _pass02_envelope(size: Vector3,seed_value: int) -> Rect2:
	# Compatibility calculation only: no old ring geometry is constructed.
	var radii := [1.0,0.98,0.88,0.90,0.75,0.78,0.65,0.68,0.52,0.54,0.42,0.36]
	if size.x>3.0:
		radii = [1.0,0.98,0.93,0.95,0.87,0.90,0.82,0.84,0.76,0.78,0.72,0.74]
	var low := Vector2(INF,INF)
	var high := Vector2(-INF,-INF)
	for level in range(radii.size()):
		var offset := Vector2(sin(float(level)*0.69+float(seed_value))*0.08,cos(float(level)*0.47+float(seed_value))*0.08)
		for sector in range(14):
			var angle := TAU*float(sector)/14.0
			var fracture := 0.86+_noise(seed_value,sector)*0.24
			var ledge := 0.97+_noise(seed_value+floori(float(level)/2.0),sector)*0.07
			var radius: float = radii[level]*fracture*ledge
			var point := Vector2((cos(angle)*radius+offset.x)*size.x*0.5,(sin(angle)*radius+offset.y)*size.z*0.5)
			low = low.min(point)
			high = high.max(point)
	return Rect2(low,high-low)

func _add_block(group: Node3D,label: String,center: Vector2,size: Vector3,seed_value: int,tiers: int) -> void:
	# Broad chamfered wall segments, with irregular break points rather than equal
	# angular sectors. The stable outline stays star-shaped around its local origin.
	var outline := PackedVector2Array([Vector2(-0.98,-0.54),Vector2(-0.83,-0.91),Vector2(-0.24,-0.92),Vector2(-0.10,-0.80),Vector2(0.20,-0.81),Vector2(0.32,-0.95),Vector2(0.88,-0.90),Vector2(0.98,-0.62),Vector2(0.94,0.20),Vector2(0.81,0.30),Vector2(0.93,0.65),Vector2(0.56,0.93),Vector2(-0.20,0.91),Vector2(-0.42,0.78),Vector2(-0.92,0.82),Vector2(-0.99,0.26)])
	for index in range(outline.size()):
		outline[index] *= 0.94+_noise(seed_value,index)*0.055
	var rings: Array[PackedVector3Array] = []
	var cut_face := seed_value%outline.size()
	for level in range(tiers*2):
		var tier := floori(float(level)/2.0)
		var height: float
		if level==0:
			height = 0.0
		elif level==tiers*2-1:
			height = 1.0
		else:
			var boundary_index := ceili(float(level)/2.0)
			var boundary := float(boundary_index)/float(tiers)
			height = boundary+(_noise(seed_value,20+boundary_index)-0.5)*0.07+(0.025 if level%2==0 else -0.025)
		var ring := PackedVector3Array()
		for vertex in range(outline.size()):
			var distance := mini(posmod(vertex-cut_face,outline.size()),posmod(cut_face-vertex,outline.size()))
			# Only one fractured face retreats strongly at a terrace. Other long walls
			# stay almost vertical, so bands do not make complete concentric pancakes.
			var retreat := (0.13 if distance<=2 else 0.018)*float(tier)
			var point := outline[vertex]*(1.0-retreat)
			var fracture_height := height
			if level>0 and level<tiers*2-1:
				fracture_height += (_noise(seed_value+ceili(float(level)/2.0)*11,vertex)-0.5)*0.055
			ring.append(Vector3(point.x*size.x*0.5,fracture_height*size.y,point.y*size.z*0.5))
		rings.append(ring)
	var mesh := ArrayMesh.new()
	for level in range(rings.size()-1):
		var wall := SurfaceTool.new()
		wall.begin(Mesh.PRIMITIVE_TRIANGLES)
		wall.set_smooth_group(-1)
		for vertex in range(outline.size()):
			var next := (vertex+1)%outline.size()
			_quad(wall,rings[level][vertex],rings[level+1][vertex],rings[level+1][next],rings[level][next])
		wall.generate_normals()
		wall.commit(mesh)
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	top.set_smooth_group(-1)
	var last: PackedVector3Array = rings.back()
	for vertex in range(outline.size()):
		_triangle(top,Vector3(0.0,size.y,0.0),last[(vertex+1)%outline.size()],last[vertex])
	top.generate_normals()
	top.commit(mesh)
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.position = Vector3(center.x,0.0,center.y)
	instance.mesh = mesh
	for surface in range(mesh.get_surface_count()):
		var color_index := mini(1+floori(float(surface)/2.0),_materials.size()-1)
		instance.set_surface_override_material(surface,_materials[color_index])
	group.add_child(instance)

func _triangle(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)

func _quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	_triangle(surface,a,b,c)
	_triangle(surface,a,c,d)
