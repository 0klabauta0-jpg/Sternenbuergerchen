extends RefCounted
## Broad open Mars valleys, layered mesas and batched small rocks.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const Space = preload("res://scripts/world/world_space.gd")

static func build(parent: Node3D, region: String) -> void:
	if region in ["station","space"]:
		Space.build(parent,region)
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 812 if region == "base" else 901
	var half := Catalog.bounds(region)
	_ground(parent,rng,half)
	var clear_radius := 49.0 if region == "base" else 25.0
	var points: Array = Catalog.landmarks(region).values()
	# Geography is authored independently of hidden contact positions.
	# Keep wide valleys between the mesa groups; low stones are visual only.
	var mesa_count := 34 if region == "base" else 66
	for i in range(mesa_count):
		var point := Vector2(rng.randf_range(-half*0.92,half*0.92),rng.randf_range(-half*0.92,half*0.92))
		if region == "base" and point.length() < clear_radius: continue
		var blocked := false
		for landmark: Array in points:
			if point.distance_to(Vector2(landmark[0],landmark[1])) < 31: blocked=true
		if blocked: continue
		var radius := rng.randf_range(8,20) if region == "base" else rng.randf_range(11,29)
		var height := radius*rng.randf_range(0.65,1.5)
		_mesa(parent,point,radius,height,rng)
	# Surrounding escarpments reinforce scale from every camera bearing.
	for i in range(18):
		var angle := TAU*i/18.0
		var point := Vector2(cos(angle),sin(angle))*half*0.99
		_mesa(parent,point,rng.randf_range(22,42),rng.randf_range(26,48),rng,true)
	if region == "base":
		for data in [Vector4(-45,-28,14,13),Vector4(-53,22,13,11),Vector4(46,-42,17,18),Vector4(16,-62,21,24)]:
			_mesa(parent,Vector2(data.x,data.y),data.z,data.w,rng)
	_scatter(parent,rng,half,region)

static func _ground(parent: Node3D, rng: RandomNumberGenerator, half: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand := Color("98694f")
	var step := 12
	for z in range(-int(half),int(half),step):
		for x in range(-int(half),int(half),step):
			var end_x := minf(x+step,half)
			var end_z := minf(z+step,half)
			var valley := sin(x*0.020+sin(z*0.009)*2.2)
			var tint := sand.lerp(Color("b9825a"),maxf(0,valley)*0.18).lightened(rng.randf_range(-0.015,0.015))
			for v in [Vector3(x,0,z),Vector3(end_x,0,z),Vector3(x,0,end_z),Vector3(end_x,0,z),Vector3(end_x,0,end_z),Vector3(x,0,end_z)]:
				st.set_color(tint)
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	var mat := Geo.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	node.material_override = mat
	parent.add_child(node)
	Geo.collider(parent,"ground","ground",Vector3(half*2,0.2,half*2),Vector3(0,-0.2,0))

static func _scatter(parent: Node3D, rng: RandomNumberGenerator, half: float, region: String) -> void:
	var transforms: Array[Transform3D] = []
	for i in range(650 if region == "base" else 1800):
		var point := Vector2(rng.randf_range(-half,half),rng.randf_range(-half,half))
		if region == "base" and point.length() < 43: continue
		var scale := rng.randf_range(0.25,1.7)
		var basis := Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3(scale,scale*rng.randf_range(0.3,0.7),scale*0.7))
		transforms.append(Transform3D(basis,Vector3(point.x,scale*0.18,point.y)))
	var mesh := CylinderMesh.new()
	mesh.top_radius=0.5
	mesh.bottom_radius=1.0
	mesh.height=1.0
	mesh.radial_segments=5
	var batch := MultiMesh.new()
	batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.mesh=mesh
	batch.instance_count=transforms.size()
	for i in range(transforms.size()): batch.set_instance_transform(i,transforms[i])
	var node := MultiMeshInstance3D.new()
	node.multimesh=batch
	node.material_override=Geo.material(Color("b8845f"))
	parent.add_child(node)

static func _mesa(parent: Node3D, point: Vector2, radius: float, height: float, rng: RandomNumberGenerator, distant: bool = false) -> void:
	var count := 9
	var angles: Array[float] = []
	var jitter: Array[float] = []
	for i in range(count):
		angles.append(TAU * i / count + rng.randf_range(-0.09,0.09))
		jitter.append(rng.randf_range(0.83,1.12))
	var scales := [1.0,1.04,0.86,0.9,0.77,0.79,0.61,0.60]
	var heights := [0.0,0.10,0.27,0.32,0.53,0.58,0.95,1.0]
	var colors := [Color("885643"),Color("ae7355"),Color("ce9366"),Color("a66b50"),Color("c28a61"),Color("a56d55"),Color("daa979")]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(scales.size()-1):
		var color: Color = colors[layer]
		if distant:
			color = color.lerp(Color("7a9298"),0.27)
		for i in range(count):
			var j := (i+1)%count
			var a := _vertex(angles[i],jitter[i],radius*scales[layer],height*heights[layer],point)
			var b := _vertex(angles[j],jitter[j],radius*scales[layer],height*heights[layer],point)
			var c := _vertex(angles[i],jitter[i],radius*scales[layer+1],height*heights[layer+1],point)
			var d := _vertex(angles[j],jitter[j],radius*scales[layer+1],height*heights[layer+1],point)
			for vertex in [a,b,c,b,d,c]:
				st.set_color(color.lightened(0.035 * sin(angles[i]*2)))
				st.add_vertex(vertex)
	for i in range(count):
		for vertex in [Vector3(point.x,height,point.y),_vertex(angles[i],jitter[i],radius*0.6,height,point),_vertex(angles[(i+1)%count],jitter[(i+1)%count],radius*0.6,height,point)]:
			st.set_color(Color("d3a273") if not distant else Color("a49b83"))
			st.add_vertex(vertex)
	st.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = st.commit()
	var mat := Geo.material(Color.WHITE)
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = mat
	parent.add_child(instance)

static func _vertex(angle: float, jitter: float, radius: float, y: float, point: Vector2) -> Vector3:
	return Vector3(point.x+cos(angle)*radius*jitter,y,point.y+sin(angle)*radius*jitter*0.72)
