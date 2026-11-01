extends Node3D
## Pass05 authored fractured geology. One-time visual build; fixture owns facts.
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
		_add_block(group,"FracturedSpire",center,Vector3(width*0.72,size.y,depth*0.70),seed_value,4)
		_add_block(group,"SpireShoulder",center+Vector2(width*0.22,depth*0.17),Vector3(width*0.39,size.y*0.30,depth*0.48),seed_value+13,1)
		return
	var handed := -1.0 if _noise(seed_value,2)<0.5 else 1.0
	var form := seed_value%4
	var crown_width := width*(0.79+_noise(seed_value,3)*0.06)
	var crown_depth := depth*(0.72+_noise(seed_value,4)*0.08)
	if form==0:
		_add_block(group,"BrokenWall",center+Vector2(width*0.015,-depth*0.11),Vector3(width*0.88,size.y,depth*0.67),seed_value,6)
		_add_block(group,"BroadTerrace",center+Vector2(-width*0.08,depth*0.20),Vector3(width*0.70,size.y*(0.31+_noise(seed_value,5)*0.16),depth*0.44),seed_value+29,2)
	elif form==3:
		_add_block(group,"BrokenWall",center+Vector2(-width*0.12,-depth*0.08),Vector3(width*0.64,size.y,depth*0.76),seed_value,6)
		_add_block(group,"OffsetCrown",center+Vector2(width*0.23,-depth*0.12),Vector3(width*0.48,size.y*0.77,depth*0.54),seed_value+31,4)
		_add_block(group,"ErodedFoot",center+Vector2(width*0.12,depth*0.26),Vector3(width*0.60,size.y*0.28,depth*0.36),seed_value+53,1)
	else:
		_add_block(group,"BrokenWall",center+Vector2(handed*width*0.055,-depth*0.05),Vector3(crown_width,size.y,crown_depth),seed_value,6)
		# Unequal adjoining shoulders make a wall mass rather than a tapered cylinder.
		var shoulder_height := 0.70 if form==2 else 0.51
		_add_block(group,"LowerButtress",center+Vector2(-handed*width*0.245,depth*0.205),Vector3(width*0.46,size.y*(shoulder_height+_noise(seed_value,5)*0.10),depth*0.47),seed_value+29,2)
		_add_block(group,"BrokenApron",center+Vector2(handed*width*0.285,depth*0.27),Vector3(width*0.32,size.y*(0.23+_noise(seed_value,6)*0.12),depth*0.32),seed_value+53,1)
	# A one-sided graded runout follows the broken face, not a two-stone necklace.
	var fragment_count: int = [1,3,0,2,1,2,4,1,3,2][posmod(floori(float(seed_value)/83.0),10)]
	for index in range(fragment_count):
		var t := float(index)/maxf(float(fragment_count-1),1.0)
		var x := handed*(-0.29+t*0.51)*width
		var z := (0.33+0.095*t+_noise(seed_value,index+81)*0.015)*depth
		var fragment_size := Vector3(width*lerpf(0.20,0.075,t),minf(size.y*lerpf(0.15,0.055,t),0.58),depth*lerpf(0.20,0.09,t))
		_add_block(group,"Talus_%d"%index,center+Vector2(x,z),fragment_size,seed_value+91+index*17,1)

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
	var outline := _block_outline(seed_value,12 if tiers==1 else 18)
	var levels: Array[float] = [0.0,0.43,1.0]
	if tiers>=5:
		var profiles := [[0.0,0.11,0.20,0.27,0.51,0.60,0.80,1.0],[0.0,0.18,0.32,0.39,0.69,0.75,0.90,1.0],[0.0,0.10,0.26,0.31,0.56,0.67,0.74,0.93,1.0]]
		levels.assign(profiles[seed_value%3])
	elif tiers>=3:
		levels = [0.0,0.21,0.38,0.66,0.80,1.0]
	elif tiers==2:
		levels = [0.0,0.24,0.37,0.71,1.0]
	if tiers>=3:
		levels.insert(levels.size()-1,0.96)
	var rings: Array[PackedVector3Array] = []
	var cut_face := _fracture_face(outline,seed_value)
	var lean := Vector2(cos(float(seed_value)*0.73),sin(float(seed_value)*0.73))*0.055
	var fracture_depths: Array[float] = [0.0,0.11,0.03,0.22,0.07,0.25,0.12,0.17,0.16]
	if seed_value%3==0: fracture_depths = [0.0,0.05,0.16,0.03,0.24,0.08,0.19,0.13,0.16]
	elif seed_value%3==2: fracture_depths = [0.0,0.03,0.17,0.06,0.23,0.04,0.14,0.21,0.16]
	for level in range(levels.size()):
		var height: float = levels[level]
		var ring := PackedVector3Array()
		for vertex in range(outline.size()):
			var distance := mini(posmod(vertex-cut_face,outline.size()),posmod(cut_face-vertex,outline.size()))
			var fracture_weight := maxf(0.0,1.0-float(distance)/3.3)
			var other_face := posmod(cut_face+5+seed_value%3,outline.size())
			var other_distance := mini(posmod(vertex-other_face,outline.size()),posmod(other_face-vertex,outline.size()))
			var secondary_weight := maxf(0.0,1.0-float(other_distance)/2.5)
			# Only a local broken face alternately retreats and overhangs. The broad
			# adjacent wall stays quiet; no periodic lip goes around the whole body.
			var retreat := fracture_depths[mini(level,fracture_depths.size()-1)]*fracture_weight if tiers>1 else 0.0
			if tiers>1: retreat += fracture_depths[posmod(level+3,fracture_depths.size())]*secondary_weight*0.48*height
			var taper := (0.42 if label=="FracturedSpire" else 0.46 if label.begins_with("Talus_") else 0.12)*height
			if tiers>=3 and level==levels.size()-1:
				# One broken crown bevel, with unequal chips, replaces the machined
				# right-angle prism edge. It is not another repeated strata ring.
				taper += 0.035+_noise(seed_value,vertex+221)*0.075
			var point := outline[vertex]*(1.0-taper-retreat)+lean*height
			var fracture_height := height
			if level>0 and level<levels.size()-1:
				fracture_height += (_noise(seed_value+11,vertex)-0.5)*0.065*sin(PI*height)
			ring.append(Vector3(point.x*size.x*0.5,fracture_height*size.y,point.y*size.z*0.5))
		rings.append(ring)
	var mesh := ArrayMesh.new()
	var walls: Array[SurfaceTool] = []
	var counts: Array[int] = [0,0,0]
	var surface_materials: Array[int] = []
	for index in range(3):
		var wall := SurfaceTool.new()
		wall.begin(Mesh.PRIMITIVE_TRIANGLES)
		wall.set_smooth_group(-1)
		walls.append(wall)
	for level in range(rings.size()-1):
		for vertex in range(outline.size()):
			var next := (vertex+1)%outline.size()
			var distance := mini(posmod(vertex-cut_face,outline.size()),posmod(cut_face-vertex,outline.size()))
			var color_index := 0 if distance<=1 else 1
			if level>=rings.size()-3 and distance<=3: color_index = 2
			_quad(walls[color_index],rings[level][vertex],rings[level+1][vertex],rings[level+1][next],rings[level][next])
			counts[color_index] += 6
	for index in range(walls.size()):
		if counts[index]==0: continue
		walls[index].generate_normals()
		walls[index].commit(mesh)
		surface_materials.append(index+1)
	var top := SurfaceTool.new()
	top.begin(Mesh.PRIMITIVE_TRIANGLES)
	top.set_smooth_group(-1)
	var last: PackedVector3Array = rings.back()
	for vertex in range(outline.size()):
		_triangle(top,Vector3(0.0,size.y,0.0),last[(vertex+1)%outline.size()],last[vertex])
	top.generate_normals()
	top.commit(mesh)
	surface_materials.append(4)
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.position = Vector3(center.x,0.0,center.y)
	instance.mesh = mesh
	for surface in range(mesh.get_surface_count()):
		instance.set_surface_override_material(surface,_materials[surface_materials[surface]])
	group.add_child(instance)

func _block_outline(seed_value: int,count: int) -> PackedVector2Array:
	var outline := PackedVector2Array()
	var phase := _noise(seed_value,109)*TAU
	var exponent: float = [0.61,0.82,1.0,0.72][seed_value%4]
	var maximum := Vector2.ZERO
	for index in range(count):
		var angle := phase+TAU*float(index)/float(count)+(_noise(seed_value,index+115)-0.5)*0.085
		var x := cos(angle)
		var z := sin(angle)
		var radius := 0.81+_noise(seed_value,index+141)*0.18
		var distance := mini(posmod(index-seed_value%count,count),posmod(seed_value%count-index,count))
		if distance<=1: radius *= 0.82
		var point := Vector2(signf(x)*pow(absf(x),exponent),signf(z)*pow(absf(z),exponent))*radius
		outline.append(point)
		maximum = maximum.max(point.abs())
	for index in range(outline.size()):
		outline[index] = outline[index]/maximum*0.95
	# A narrow vertical fissure interrupts the plateau edge at a visible broken
	# shoulder; it remains star-shaped, so fan caps do not bridge empty space.
	if count>=18:
		var fissure := posmod(_fracture_face(outline,seed_value)+2+seed_value%2,count)
		outline[fissure] *= 0.70
		outline[posmod(fissure+1,count)] *= 0.94
	return outline

func _fracture_face(outline: PackedVector2Array,seed_value: int) -> int:
	var angle := 0.35+(_noise(seed_value,181)-0.5)*0.70
	var exposed := Vector2(sin(angle),cos(angle))
	var best := -INF
	var result := 0
	for index in range(outline.size()):
		var score := outline[index].normalized().dot(exposed)
		if score>best:
			best = score
			result = index
	return result

func _triangle(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(b)

func _quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3) -> void:
	_triangle(surface,a,b,c)
	_triangle(surface,a,c,d)
