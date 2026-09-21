extends RefCounted
## Broad open Mars valleys, layered mesas and batched small rocks.
const Geo = preload("res://scripts/world/world_geometry.gd")
const Regions=preload("res://scripts/core/regions.gd")
const Catalog = preload("res://scripts/core/catalog.gd")
const Layout = preload("res://scripts/core/world_layout.gd")
const Space = preload("res://scripts/world/world_space.gd")

static func build(parent: Node3D, region: String) -> void:
	if region in ["station","space","orbit"]:
		Space.build(parent,region)
		return
	if Regions.underground(region):
		Geo.collider(parent,"ground","ground",Vector3(Catalog.bounds(region)*2,0.2,Catalog.bounds(region)*2),Vector3(0,-0.2,0))
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = {"base":812,"rust":901,"bunker_surface":972,"distribution":1048,"tradepost":1135}.get(region,901)
	var half := Catalog.bounds(region)
	_ground(parent,rng,half)
	for spec: Dictionary in Layout.rocks(region):
		if str(spec.kind)!="mesa":continue
		var rock_rng:=RandomNumberGenerator.new();rock_rng.seed=int(spec.seed)
		_mesa(parent,Vector2(spec.center[0],spec.center[1]),float(spec.radius),float(spec.height),rock_rng)
	_scatter(parent,region)
	if region=="base":_home_scree(parent)

static func _ground(parent: Node3D, rng: RandomNumberGenerator, half: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sand := Color("833f28")
	var step := 12
	for z in range(-int(half),int(half),step):
		for x in range(-int(half),int(half),step):
			var end_x := minf(x+step,half)
			var end_z := minf(z+step,half)
			var valley := sin(x*0.020+sin(z*0.009)*2.2)
			var tint := sand.lerp(Color("ac5c34"),maxf(0,valley)*0.18).lightened(rng.randf_range(-0.015,0.015))
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

static func _scatter(parent: Node3D, region: String) -> void:
	var transforms: Array[Transform3D]=[]
	for spec: Dictionary in Layout.rocks(region):
		if str(spec.kind)!="stone":continue
		var dimensions:=Vector3(spec.size[0],spec.height,spec.size[1])
		transforms.append(Transform3D(Basis.IDENTITY.scaled(dimensions),Vector3(spec.center[0],spec.height/2,spec.center[1])))
	var mesh:=CylinderMesh.new();mesh.top_radius=0.30;mesh.bottom_radius=0.5;mesh.height=1.0;mesh.radial_segments=6
	var batch:=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.mesh=mesh;batch.instance_count=transforms.size()
	for i in range(transforms.size()):batch.set_instance_transform(i,transforms[i])
	var node:=MultiMeshInstance3D.new();node.multimesh=batch;node.material_override=Geo.material(Color("b8845f"));parent.add_child(node)

static func _mesa(parent: Node3D, point: Vector2, radius: float, height: float, rng: RandomNumberGenerator, distant: bool = false) -> void:
	var count := 16
	var angles: Array[float] = []
	var jitter: Array[float] = []
	for i in range(count):
		angles.append(TAU * i / count + rng.randf_range(-0.09,0.09))
		jitter.append(rng.randf_range(0.83,1.12))
	var scales := [1.0,0.98,0.93,0.93,0.88,0.86,0.79,0.79,0.74,0.72,0.65,0.65,0.60,0.58,0.48,0.48,0.42,0.34]
	var heights := [0.0,0.07,0.07,0.16,0.18,0.28,0.28,0.38,0.40,0.51,0.51,0.62,0.64,0.74,0.74,0.84,0.86,1.0]
	var colors := [Color("713c2a"),Color("925032"),Color("86442c"),Color("82432e"),Color("9a5636"),Color("884831"),Color("80432e")]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer in range(scales.size()-1):
		var color: Color = colors[layer % colors.size()]
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
		for vertex in [Vector3(point.x,height,point.y),_vertex(angles[i],jitter[i],radius*0.34,height,point),_vertex(angles[(i+1)%count],jitter[(i+1)%count],radius*0.34,height,point)]:
			st.set_color(Color("a45e3b") if not distant else Color("a49b83"))
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

static func _home_scree(parent: Node3D) -> void:
	# Tiny surface rubble, below boot height. Large rocks remain core obstacles.
	var rng:=RandomNumberGenerator.new();rng.seed=41203
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 4200:
		var at:=Vector2(rng.randf_range(-80,80),rng.randf_range(-75,70))
		if Rect2(-19,-20,55,32).has_point(at) or at.distance_to(Vector2(25,22))<13:continue
		if absf(at.y-(at.x*0.55+11))<3.5 and at.x>=-3 and at.x<=28:continue
		# Bands create coherent rubble beds with quiet open lanes between them.
		var field:=sin(at.x*0.14+sin(at.y*0.18)*2.0)
		if field<0.1:continue
		var r:=rng.randf_range(0.08,0.48)
		var height:=rng.randf_range(0.035,0.13)
		var shade:=Color("955137").lightened(rng.randf_range(-0.10,0.06))
		for j in 5:
			var a:=Vector2.from_angle(j*TAU/5)*r+at
			var b:=Vector2.from_angle((j+1)*TAU/5)*r+at
			for v in [Vector3(a.x,0.008,a.y),Vector3(b.x,0.008,b.y),Vector3(at.x,height,at.y)]:
				st.set_color(shade);st.add_vertex(v)
	st.generate_normals()
	var node:=MeshInstance3D.new();node.mesh=st.commit()
	var mat:=Geo.material(Color.WHITE);mat.vertex_color_use_as_albedo=true;mat.vertex_color_is_srgb=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	node.material_override=mat;parent.add_child(node)
